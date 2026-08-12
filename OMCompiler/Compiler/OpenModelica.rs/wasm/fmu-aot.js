// Client side of the FMU native-platform compiler (see fmu-aot-worker.js).
//
// omc asks for machine code from inside one synchronous `omc_eval`, so the answer
// cannot arrive as a message — that thread is parked. It comes back through a
// SharedArrayBuffer, which needs the page cross-origin isolated (COOP/COEP; see
// scripts/coi_server.py).
//
// ⚠️ The compiler worker must be a *sibling* of the omc worker, hence the page
// half below: Chrome pumps a nested worker's messages through its parent, so an
// omc worker that spawned its own would park before the child could ever run.

// ── page side ────────────────────────────────────────────────────────────────

let aot = null;

// Give `omcWorker` a port to the one shared compiler worker. Call it right after
// creating the omc worker: messages are ordered, so the port is installed before
// its `init`. False when the page is not cross-origin isolated.
export function attachFmuAot(omcWorker) {
  if (typeof SharedArrayBuffer === 'undefined') return false;
  const channel = new MessageChannel();
  compiler().postMessage({ port: channel.port1 }, [channel.port1]);
  omcWorker.postMessage({ cmd: 'fmuAotPort', port: channel.port2 }, [channel.port2]);
  return true;
}

function compiler() {
  aot ||= new Worker(new URL('./fmu-aot-worker.js', import.meta.url), { type: 'module' });
  return aot;
}

// Compile `component` for `triple`, for a caller with a live event loop — a page,
// which may not park in `Atomics.wait` and so needs no shared memory.
let jobId = 0;
export function compileForPlatform(component, triple) {
  const w = compiler();
  const id = ++jobId;
  const bytes = component.slice();
  return new Promise((resolve, reject) => {
    const on = (e) => {
      if (e.data.type !== 'done' || e.data.id !== id) return;
      w.removeEventListener('message', on);
      e.data.error ? reject(new Error(e.data.error)) : resolve(e.data.result);
    };
    w.addEventListener('message', on);
    w.postMessage({ type: 'compile', component: bytes, triple, id }, [bytes.buffer]);
  });
}

// ── the loader libraries ─────────────────────────────────────────────────────
//
// A wasm omc does not carry them (~4 MB of native library per platform); they are
// bundle files with an index, read synchronously for omc and with fetch for a page.

const LOADERS = new URL('./fmu-loaders/', import.meta.url).href;

function readSync(url, type) {
  const xhr = new XMLHttpRequest();
  xhr.open('GET', url, false);
  if (type) xhr.responseType = type;
  try {
    xhr.send();
  } catch {
    return null;
  }
  return xhr.status === 200 || xhr.status === 0 ? xhr.response : null;
}

function syncLoaderIndex() {
  const text = readSync(LOADERS + 'index.json');
  try {
    return text ? JSON.parse(text) : [];
  } catch {
    return [];
  }
}

function syncLoader(platform) {
  const entry = syncLoaderIndex().find((e) => e.platform === platform);
  const buf = entry && readSync(LOADERS + entry.file, 'arraybuffer');
  return buf ? new Uint8Array(buf) : null;
}

// [{ platform, triple, file, ext }] — what an FMU can be given a native binary for.
export async function loaderIndex() {
  const r = await fetch(LOADERS + 'index.json').catch(() => null);
  return r && r.ok ? r.json() : [];
}

export async function loaderBytes(entry) {
  const r = await fetch(LOADERS + entry.file);
  if (!r.ok) throw new Error(`${entry.file}: HTTP ${r.status}`);
  return new Uint8Array(await r.arrayBuffer());
}

// ── omc-worker side ──────────────────────────────────────────────────────────

const STATE = { pending: 0, ok: 1, error: 2 };
// Park in slices, so the export stays cancellable and a compiler that died (out
// of memory on a large model) is reported instead of hanging omc for good.
const SLICE_MS = 250;
const GIVE_UP_MS = 15 * 60 * 1000;

function park(ctl) {
  for (let waited = 0; waited < GIVE_UP_MS; waited += SLICE_MS) {
    if (Atomics.wait(ctl, 0, STATE.pending, SLICE_MS) !== 'timed-out') return;
    if (globalThis.__omcPollCancel?.()) throw new Error('cancelled');
  }
  throw new Error('the FMU compiler did not answer; it may have run out of memory');
}

// The bytes the compiler staged for us: its length first, then a shared buffer of
// exactly that size for it to copy into (we are parked, so it cannot hand us one).
function take(port, ctl) {
  park(ctl);
  const state = Atomics.load(ctl, 0);
  const buf = new SharedArrayBuffer(Atomics.load(ctl, 1));
  Atomics.store(ctl, 0, STATE.pending);
  port.postMessage({ type: 'take', buf, ctl });
  park(ctl);
  const bytes = new Uint8Array(buf.byteLength);
  bytes.set(new Uint8Array(buf));
  if (state === STATE.error) throw new Error(new TextDecoder().decode(bytes));
  return bytes;
}

// Define the globals `omc_enable_fmu_aot()` binds. A fresh control block per job,
// so an answer to a job we gave up on lands in an orphan, not in the next one.
export function installFmuAot(port) {
  globalThis.__omcFmuPlatforms = () => syncLoaderIndex().map((e) => e.platform);
  globalThis.__omcFmuLoader = syncLoader;
  globalThis.__omcAotPreload = () => port.postMessage({ type: 'load' });
  globalThis.__omcAotCompile = (component, triple) => {
    // `&[u8]` reaches JS as a view into omc's linear memory; posting that would
    // clone the whole memory.
    const bytes = component.slice();
    const ctl = new Int32Array(new SharedArrayBuffer(8)); // [0] state, [1] length
    port.postMessage({ type: 'compile', component: bytes, triple, ctl }, [bytes.buffer]);
    return take(port, ctl);
  };
}
