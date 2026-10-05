// The FMU runs here, off the page's thread.
//
// A run is one call into the driver's wasm and does not return until the
// simulation ends, so it cannot share a thread with the user interface. The
// worker owns the driver, the FMU and the result file; the page sends it an
// archive and a set of options and gets back samples to plot.

import { Driver } from './driver.js';

let driver = null;

const post = (message, transfer) => self.postMessage(message, transfer || []);

self.onmessage = async (e) => {
  const { id, kind, ...rest } = e.data;
  try {
    post({ id, ok: true, result: await handle(kind, rest) });
  } catch (error) {
    post({ id, ok: false, error: error && error.message ? error.message : String(error) });
  }
};

async function handle(kind, args) {
  switch (kind) {
    case 'load': {
      driver = new Driver({
        onLog: (tag, text) => post({ event: 'log', tag, text }),
        onProgress: (time) => post({ event: 'progress', time }),
        onSamples: (batch) => post({ event: 'samples', ...batch }, [batch.values.buffer]),
      });
      // The page writes 1 into this to stop a run; without it (no
      // SharedArrayBuffer) cancelling means dropping the worker.
      if (args.cancelFlag) driver.cancelFlag = new Int32Array(args.cancelFlag);
      await driver.init(args.wasmUrl ?? './openmodelica_fmi_web.wasm');
      return driver.load(args.archive);
    }
    case 'warm': {
      if (!driver) throw new Error('no FMU is loaded');
      return driver.warm(args.kind);
    }
    case 'file': {
      if (!driver) throw new Error('no FMU is loaded');
      return driver.file(args.name);
    }
    case 'run': {
      if (!driver) throw new Error('no FMU is loaded');
      const result = await driver.run(args.options);
      // The samples are the bulk of the message; hand the buffer over rather
      // than copying it.
      const values = result.values;
      delete result.values;
      return { ...result, values };
    }
    case 'result': {
      if (!driver) throw new Error('no FMU is loaded');
      return driver.writeResult(args.path);
    }
    default:
      throw new Error(`the worker does not know how to ${kind}`);
  }
}
