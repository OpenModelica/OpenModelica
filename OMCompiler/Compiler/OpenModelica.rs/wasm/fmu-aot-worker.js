// The FMU native-platform compiler: `openmodelica_fmi_ls_wasm_aot.wasm`, a
// wasm32-wasip1 build of wasmtime's compiler half, run here so the omc worker
// stays free to keep building the model while this one downloads and compiles.
//
// One wasm instance per job: a 10 MB `.cwasm` is not held past its export, and a
// cranelift panic cannot poison the next job.

const STATE = { pending: 0, ok: 1, error: 2 };
const ERRNO = { success: 0, badf: 8, noent: 44 };
const WASM = new URL('./fmu-aot.wasm', import.meta.url).href;

let modulePromise = null;

function load() {
  modulePromise ||= fetch(WASM)
    .then((r) => {
      if (!r.ok) throw new Error(`${WASM}: HTTP ${r.status}`);
      return r.arrayBuffer();
    })
    .then((b) => WebAssembly.compile(b));
  return modulePromise;
}

// Just enough `wasi_snapshot_preview1` for the compiler: a clock (cranelift's pass
// timing), randomness, stdio, and enough fd/path calls to say "no filesystem".
function wasi(mem) {
  const view = () => new DataView(mem().buffer);
  const out = {};
  const decoder = new TextDecoder();
  return {
    random_get(ptr, len) {
      crypto.getRandomValues(new Uint8Array(mem().buffer, ptr, len));
      return ERRNO.success;
    },
    environ_sizes_get(countPtr, sizePtr) {
      const v = view();
      v.setUint32(countPtr, 0, true);
      v.setUint32(sizePtr, 0, true);
      return ERRNO.success;
    },
    environ_get: () => ERRNO.success,
    clock_time_get(id, _precision, resultPtr) {
      const ms = id === 0 ? Date.now() : performance.now();
      view().setBigUint64(resultPtr, BigInt(Math.round(ms * 1e6)), true);
      return ERRNO.success;
    },
    fd_close: () => ERRNO.success,
    fd_fdstat_get(fd, ptr) {
      if (fd > 2) return ERRNO.badf;
      const v = view();
      v.setUint8(ptr, 2); // character device
      v.setUint16(ptr + 2, 0, true);
      v.setBigUint64(ptr + 8, 0n, true);
      v.setBigUint64(ptr + 16, 0n, true);
      return ERRNO.success;
    },
    fd_prestat_get: () => ERRNO.badf, // no preopens: std stops scanning at the first
    fd_prestat_dir_name: () => ERRNO.badf,
    fd_write(fd, iovs, iovsLen, nwrittenPtr) {
      const v = view();
      let written = 0;
      let text = '';
      for (let i = 0; i < iovsLen; i++) {
        const buf = v.getUint32(iovs + i * 8, true);
        const len = v.getUint32(iovs + i * 8 + 4, true);
        text += decoder.decode(new Uint8Array(mem().buffer, buf, len));
        written += len;
      }
      v.setUint32(nwrittenPtr, written, true);
      out[fd] = (out[fd] || '') + text;
      for (let nl; (nl = out[fd].indexOf('\n')) >= 0; out[fd] = out[fd].slice(nl + 1)) {
        const line = 'fmu-aot: ' + out[fd].slice(0, nl);
        if (fd === 2) console.error(line); else console.log(line);
      }
      return ERRNO.success;
    },
    path_open: () => ERRNO.noent,
    proc_exit(code) {
      throw new Error('the FMU compiler exited with status ' + code);
    },
  };
}

function compile(module, component, triple) {
  let instance;
  instance = new WebAssembly.Instance(module, { wasi_snapshot_preview1: wasi(() => instance.exports.memory) });
  const { aot_alloc, aot_compile, aot_result_ptr, aot_result_len, memory } = instance.exports;

  const componentPtr = aot_alloc(component.length);
  new Uint8Array(memory.buffer, componentPtr, component.length).set(component);
  const tripleBytes = new TextEncoder().encode(triple);
  const triplePtr = aot_alloc(tripleBytes.length);
  new Uint8Array(memory.buffer, triplePtr, tripleBytes.length).set(tripleBytes);

  const failed = aot_compile(componentPtr, component.length, triplePtr, tripleBytes.length);
  // Copy out before the instance (and its memory) goes away.
  const result = new Uint8Array(memory.buffer, aot_result_ptr(), aot_result_len()).slice();
  return { failed: failed !== 0, result };
}

function answer(ctl, state, len) {
  Atomics.store(ctl, 1, len);
  Atomics.store(ctl, 0, state);
  Atomics.notify(ctl, 0);
}

// A parked caller (an omc worker) answers through the control block it sent and
// takes the bytes in a second round trip, since it cannot allocate the shared
// buffer while parked; `pending` holds them meanwhile. A page gets them in the reply.
const pending = new Map();

async function job(caller, m) {
  if (m.type === 'load') {
    load().catch((err) => console.error('fmu-aot: ' + (err && err.message || err)));
    return;
  }
  if (m.type === 'take') {
    const staged = pending.get(caller);
    new Uint8Array(m.buf).set(staged.subarray(0, m.buf.byteLength));
    pending.delete(caller);
    answer(m.ctl, STATE.ok, m.buf.byteLength);
    return;
  }
  if (m.type !== 'compile') return;
  let failed = false;
  let result;
  try {
    ({ failed, result } = compile(await load(), m.component, m.triple));
  } catch (err) {
    failed = true;
    result = new TextEncoder().encode('' + (err && err.message || err));
  }
  if (m.ctl) {
    pending.set(caller, result);
    answer(m.ctl, failed ? STATE.error : STATE.ok, result.length);
  } else if (failed) {
    caller.postMessage({ type: 'done', id: m.id, error: new TextDecoder().decode(result) });
  } else {
    caller.postMessage({ type: 'done', id: m.id, result }, [result.buffer]);
  }
}

// `{ port }` connects an omc worker; anything else is a job posted by the page.
onmessage = (e) => {
  if (e.data.port) {
    const port = e.data.port;
    port.onmessage = (m) => job(port, m.data);
  } else {
    job(self, e.data);
  }
};
