// The page's side of the worker: one FMU at a time, loaded and simulated there.
//
// Every request is a message with an id and gets one reply; the log lines and
// the progress the driver reports arrive in between, unnumbered.

export class Session {
  constructor({ onLog = () => {}, onProgress = () => {}, onSamples = () => {} } = {}) {
    this.onLog = onLog;
    this.onProgress = onProgress;
    this.onSamples = onSamples;
    this.worker = null;
    this.pending = new Map();
    this.nextId = 1;
    // A run is one call into wasm; the only way to stop it from here is a flag
    // the worker can read while it runs, which needs shared memory. Where the
    // page is not cross-origin isolated there is none, and cancelling drops the
    // worker instead.
    this.cancelFlag = typeof SharedArrayBuffer === 'function'
      ? new Int32Array(new SharedArrayBuffer(4)) : null;
  }

  start() {
    if (this.worker) return this.worker;
    this.worker = new Worker(new URL('./fmi-worker.js', import.meta.url), { type: 'module' });
    this.worker.onmessage = (e) => {
      const m = e.data;
      if (m.event === 'log') return this.onLog(m.tag, m.text);
      if (m.event === 'progress') return this.onProgress(m.time);
      if (m.event === 'samples') return this.onSamples(m);
      const waiting = this.pending.get(m.id);
      if (!waiting) return;
      this.pending.delete(m.id);
      if (m.ok) waiting.resolve(m.result);
      else waiting.reject(new Error(m.error));
    };
    this.worker.onerror = (e) => {
      const error = new Error(e.message || 'the simulation worker failed');
      for (const [, waiting] of this.pending) waiting.reject(error);
      this.pending.clear();
    };
    return this.worker;
  }

  send(kind, args, transfer) {
    this.start();
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.worker.postMessage({ id, kind, ...args }, transfer || []);
    });
  }

  // Hand the archive over (the buffer is transferred, not copied) and get back
  // what the driver read out of it.
  load(archive) {
    const flag = this.cancelFlag ? this.cancelFlag.buffer : null;
    return this.send('load', { archive, cancelFlag: flag }, [archive]);
  }

  file(name) {
    return this.send('file', { name });
  }

  run(options) {
    if (this.cancelFlag) Atomics.store(this.cancelFlag, 0, 0);
    return this.send('run', { options });
  }

  // Instantiate an interface ahead of the run that will use it.
  warm(kind) {
    return this.send('warm', { kind });
  }

  // Write the result file inside the driver's WASI filesystem and read it back;
  // the name's suffix picks the format.
  result(path) {
    return this.send('result', { path });
  }

  // Ask a running simulation to stop at its next output point, which keeps the
  // samples taken so far and the FMU loaded. Returns false where there is no
  // shared memory to ask through — the caller then has to drop the worker.
  cancel() {
    if (!this.cancelFlag) return false;
    Atomics.store(this.cancelFlag, 0, 1);
    return true;
  }

  // Drop the worker and everything in it, for a run that will not stop.
  terminate() {
    if (!this.worker) return;
    this.worker.terminate();
    this.worker = null;
    for (const [, waiting] of this.pending) waiting.reject(new Error('cancelled'));
    this.pending.clear();
  }
}
