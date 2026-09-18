// The wasm side modules omc does not carry, read out of wasm-blobs/ on the first
// call that needs one. Synchronous, as omc asks from inside `omc_eval` — the same
// XHR as the FMU loaders in fmu-aot.js. A page driving omc on the main thread may
// not set `responseType` there, hence the binary-string fallback.

const BLOBS = new URL('./wasm-blobs/', import.meta.url).href;

function readSync(url) {
  const xhr = new XMLHttpRequest();
  xhr.open('GET', url, false);
  let binaryString = false;
  try {
    xhr.responseType = 'arraybuffer';
  } catch {
    xhr.overrideMimeType('text/plain; charset=x-user-defined');
    binaryString = true;
  }
  try {
    xhr.send();
  } catch {
    return null;
  }
  if (xhr.status !== 200 && xhr.status !== 0) return null;
  if (!binaryString) return xhr.response ? new Uint8Array(xhr.response) : null;
  const s = xhr.responseText || '';
  const out = new Uint8Array(s.length);
  for (let i = 0; i < s.length; i++) out[i] = s.charCodeAt(i) & 0xff;
  return out;
}

export function installWasmBlobs() {
  globalThis.__omcWasmBlob = (file) => readSync(BLOBS + file);
}
