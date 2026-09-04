// The OpenModelica FMI driver as the page uses it.
//
// `openmodelica_fmi_web.wasm` holds the masters, the solvers and the result
// writer; this module gives it the FMU (through `fmu-core.js`, straight to the
// component's core exports) and a filesystem (through `wasi.js`), and hands the
// page back what the run produced.

import { HOST_FAILED, loadComponent } from './fmu-core.js';
import { Wasi } from './wasi.js';

const KIND = { me: 0, cs: 1 };

// How often a run pushes the samples it has so far to the page.
const SAMPLE_INTERVAL_MS = 250;

export class Driver {
  constructor({ onLog = () => {}, onProgress = () => {}, onSamples = () => {} } = {}) {
    this.onLog = onLog;
    this.onProgress = onProgress;
    this.onSamples = onSamples;
    // Set from outside (a SharedArrayBuffer the page writes to) to stop a run.
    this.cancelFlag = null;
    this.lastSamplePush = 0;
    this.wasi = new Wasi({ onOutput: (stream, text) => onLog(stream, text) });
    this.exports = null;
    this.component = null;
    this.fmu = null;
    this.kind = null;
    this.held = new Map();
    this.decoder = new TextDecoder();
    this.encoder = new TextEncoder();
    // Set to a `Map` to have every FMI call counted and timed into it, which is
    // how a slow run is traced to the call it spends itself in.
    this.stats = null;
    // Reused across calls so a step never allocates.
    this.discrete = {};
    this.completed = {};
    this.step = {};
  }

  // Compile and instantiate the driver module, from a URL or from bytes.
  async init(wasm = './openmodelica_fmi_web.wasm') {
    let bytes = wasm;
    if (typeof wasm === 'string') {
      const source = await fetch(wasm);
      if (!source.ok) throw new Error(`cannot load ${wasm}: ${source.status} ${source.statusText}`);
      bytes = await source.arrayBuffer();
    }
    const { instance } = await WebAssembly.instantiate(bytes, {
      wasi_snapshot_preview1: this.wasi.imports(),
      fmu: this.fmuImports(),
      host: {
        host_progress: (time, ptr, len, stride) => this.progress(time, ptr, len, stride),
        host_columns: () => {
          this.runColumns = this.out();
          this.lastSamplePush = 0;
        },
        host_cancelled: () => (this.cancelFlag && Atomics.load(this.cancelFlag, 0) ? 1 : 0),
      },
    });
    this.exports = instance.exports;
    this.wasi.bind(this.exports.memory);
    this.exports._initialize?.();
    return this;
  }

  memory() {
    return this.exports.memory.buffer;
  }

  // One output point: the time always, the samples themselves at most every
  // `SAMPLE_INTERVAL_MS` — a plot cannot use more, and each push copies them.
  progress(time, ptr, len, stride) {
    this.onProgress(time);
    const now = performance.now();
    if (!this.runColumns || now - this.lastSamplePush < SAMPLE_INTERVAL_MS) return;
    this.lastSamplePush = now;
    const values = new Float64Array(this.memory(), ptr, len).slice();
    this.onSamples({ ...this.runColumns, rows: len / stride, values, time });
  }

  f64(ptr, len) {
    return new Float64Array(this.memory(), ptr, len);
  }

  u32(ptr, len) {
    return new Uint32Array(this.memory(), ptr, len);
  }

  text(ptrFn, lenFn) {
    const ptr = this.exports[ptrFn]();
    const len = this.exports[lenFn]();
    return this.decoder.decode(new Uint8Array(this.memory(), ptr, len));
  }

  lastError() {
    return this.text('om_fmi_error_ptr', 'om_fmi_error_len') || 'the driver reported no reason';
  }

  out() {
    return JSON.parse(this.text('om_fmi_out_ptr', 'om_fmi_out_len'));
  }

  // Copy `bytes` into the driver's memory and keep the pointer for the caller.
  pass(bytes) {
    const ptr = this.exports.om_fmi_alloc(bytes.length);
    new Uint8Array(this.memory(), ptr, bytes.length).set(bytes);
    return ptr;
  }

  // Read the FMU archive: the driver unpacks it, and hands back the wasm
  // component and the resources this side needs to instantiate it.
  async load(archive) {
    const bytes = new Uint8Array(archive);
    const ptr = this.pass(bytes);
    const ok = this.exports.om_fmi_load(ptr, bytes.length);
    this.exports.om_fmi_free(ptr, bytes.length);
    if (!ok) throw new Error(this.lastError());
    if (!this.exports.om_fmi_info()) throw new Error(this.lastError());
    this.info = this.out();

    const kind = this.info.coSimulation ? 1 : 0;
    if (!this.exports.om_fmi_select_component(kind)) throw new Error(this.lastError());
    const component = this.binary();
    if (!this.exports.om_fmi_resource_names()) throw new Error(this.lastError());
    const files = new Map();
    for (const name of this.out()) {
      const path = this.encoder.encode(name);
      const p = this.pass(path);
      const got = this.exports.om_fmi_select_file(p, path.length);
      this.exports.om_fmi_free(p, path.length);
      if (got) files.set(name, this.binary());
    }
    this.resources = files;
    this.info.icon = this.icon();
    this.info.documentation = this.documentation();
    this.component = await loadComponent(component, { files, onLog: this.onLog });
    // Wire the component up now rather than when Simulate is pressed: wiring
    // the modules is the expensive half, and every later run reuses this
    // instance through `fmi3Reset`.
    await this.warm(this.info.coSimulation ? 'cs' : 'me');
    return this.info;
  }

  // One file out of the archive, or null. The page never unpacks the FMU itself:
  // the driver already has it open.
  file(name) {
    const path = this.encoder.encode(name);
    const p = this.pass(path);
    const got = this.exports.om_fmi_select_file(p, path.length);
    this.exports.om_fmi_free(p, path.length);
    return got ? this.binary() : null;
  }

  // The FMU icon (terminalsAndIcons/icon.svg, else icon.png), or null.
  icon() {
    if (!this.exports.om_fmi_icon()) return null;
    return { name: this.out().name, bytes: this.binary() };
  }

  // The documentation entry point and the files beside it, or null. Small enough
  // to hand over whole — it is a page and the images it shows.
  documentation() {
    if (!this.exports.om_fmi_documentation()) return null;
    const { entry, files } = this.out();
    const map = new Map();
    // The icons too: the generated page puts the FMU icon in its heading, which
    // is a relative reference out of documentation/.
    for (const name of [...files, 'terminalsAndIcons/icon.svg', 'terminalsAndIcons/icon.png']) {
      const bytes = this.file(name);
      if (bytes) map.set(name, bytes);
    }
    return { entry, files: map };
  }

  // Instantiate an interface before it is run, so pressing Simulate does not
  // wait for the component to be wired up.
  async warm(kind) {
    const iface = kind === 'cs' ? this.info.coSimulation : this.info.modelExchange;
    if (!iface) return false;
    await this.instance(kind, {
      name: this.info.modelName,
      token: this.info.instantiationToken,
      loggingOn: false,
      eventMode: kind === 'cs' && !!iface.hasEventMode,
      earlyReturn: kind === 'cs',
    });
    return true;
  }

  // The FMU to run, reusing the one from the last run where the FMU can reset
  // itself: instantiating the component again costs far more than a reset, and
  // a reset instance is in exactly the state a fresh one is.
  async instance(kind, options) {
    // One live instance per interface: switching between Model Exchange and
    // Co-Simulation is then as cheap as running the same one again.
    const held = this.held.get(kind);
    if (held && held.options.loggingOn === options.loggingOn
        && held.options.eventMode === options.eventMode) {
      held.fmu.begin();
      let ok;
      try {
        ok = held.fmu.reset() <= 1;
      } catch (e) {
        ok = false;
      } finally {
        held.fmu.end();
      }
      if (ok) return held.fmu;
      this.onLog('info', 'the FMU cannot reset itself; instantiating it again');
    }
    const fmu = await this.component.instantiate(kind, options);
    this.held.set(kind, { fmu, options });
    return fmu;
  }

  // A copy of whatever `om_fmi_select_*` last took out of the archive.
  binary() {
    const ptr = this.exports.om_fmi_binary_ptr();
    const len = this.exports.om_fmi_binary_len();
    return new Uint8Array(this.memory(), ptr, len).slice();
  }

  // Simulate. `options` is what `om_fmi_run` documents; the interface is
  // resolved here so the FMU can be instantiated before the run starts — the
  // driver's world is synchronous, and instantiating a component is not.
  async run(options) {
    const kind = options.interface
      ?? (this.info.coSimulation ? 'cs' : 'me');
    const iface = kind === 'cs' ? this.info.coSimulation : this.info.modelExchange;
    if (!iface) throw new Error(`the FMU has no ${kind === 'cs' ? 'Co-Simulation' : 'Model Exchange'} interface`);
    const eventMode = kind === 'cs' && (options.eventMode ?? true) && !!iface.hasEventMode;
    const tInstantiate = performance.now();
    this.fmu = await this.instance(kind, {
      name: this.info.modelName,
      token: this.info.instantiationToken,
      loggingOn: !!options.loggingOn,
      eventMode,
      earlyReturn: kind === 'cs',
    });
    this.kind = KIND[kind];
    this.lastInstantiateMs = performance.now() - tInstantiate;
    this.lastFmuTiming = this.fmu.timing;

    const text = this.encoder.encode(JSON.stringify({ ...options, interface: kind }));
    const ptr = this.pass(text);
    const fmu = this.fmu;
    let ok;
    const tRun = performance.now();
    fmu.begin();
    try {
      ok = this.exports.om_fmi_run(ptr, text.length);
    } finally {
      fmu.end();
    }
    this.lastRunMs = performance.now() - tRun;
    this.exports.om_fmi_free(ptr, text.length);
    if (!ok) throw new Error(this.lastError());
    const tResult = performance.now();
    if (!this.exports.om_fmi_result()) throw new Error(this.lastError());
    const result = this.out();
    const rows = new Float64Array(
      this.memory(), this.exports.om_fmi_rows_ptr(), this.exports.om_fmi_rows_len());
    // Copied out: the next run's allocations may move the driver's memory.
    result.values = rows.slice();
    this.lastResultMs = performance.now() - tResult;
    return result;
  }

  // Write the result file through WASI, and hand back what landed there.
  writeMat(path) {
    const bytes = this.encoder.encode(path);
    const ptr = this.pass(bytes);
    const ok = this.exports.om_fmi_write_mat(ptr, bytes.length);
    this.exports.om_fmi_free(ptr, bytes.length);
    if (!ok) throw new Error(this.lastError());
    return this.wasi.read(path);
  }

  // The FMI calls, bound to whatever FMU the current run instantiated. A call
  // that throws is reported as a host failure, named, so the driver's error
  // says which one.
  fmuImports() {
    const guard = (name, f) => (...args) => {
      const inst = this.fmu;
      if (!inst) return HOST_FAILED;
      const stats = this.stats;
      const t0 = stats ? performance.now() : 0;
      try {
        return f(inst, ...args);
      } catch (e) {
        this.onLog('error', `${name}: ${e && e.message ? e.message : e}`);
        return HOST_FAILED;
      } finally {
        if (stats) {
          const s = stats.get(name) || { calls: 0, ms: 0 };
          s.calls++;
          s.ms += performance.now() - t0;
          stats.set(name, s);
        }
      }
    };
    const view = () => new DataView(this.memory());
    return {
      fmu_instantiate: (kind) => (this.fmu && this.kind === kind ? 1 : 0),
      // The masters drop their instance at the end of a run; the component
      // stays instantiated for the next one (see `instance`).
      fmu_free_instance: () => {
        this.fmu = null;
      },
      fmu_enter_initialization_mode: guard('fmu_enter_initialization_mode', (inst, tolDefined, tol, start, stopDefined, stop) =>
        inst.enterInitializationMode(tolDefined, tol, start, stopDefined, stop)),
      fmu_exit_initialization_mode: guard('fmu_exit_initialization_mode', (inst) => inst.exitInitializationMode()),
      fmu_enter_event_mode: guard('fmu_enter_event_mode', (inst) => inst.enterEventMode()),
      fmu_enter_configuration_mode: guard('fmu_enter_configuration_mode', (inst) => inst.enterConfigurationMode()),
      fmu_exit_configuration_mode: guard('fmu_exit_configuration_mode', (inst) => inst.exitConfigurationMode()),
      fmu_enter_continuous_time_mode: guard('fmu_enter_continuous_time_mode', (inst) => inst.enterContinuousTimeMode()),
      fmu_enter_step_mode: guard('fmu_enter_step_mode', (inst) => inst.enterStepMode()),
      fmu_terminate: guard('fmu_terminate', (inst) => inst.terminate()),
      fmu_update_discrete_states: guard('fmu_update_discrete_states', (inst, out) => {
        const status = inst.updateDiscreteStates(this.discrete);
        if (status > 1) return status;
        const d = view();
        d.setUint32(out + 0, this.discrete.needUpdate, true);
        d.setUint32(out + 4, this.discrete.terminate, true);
        d.setUint32(out + 8, this.discrete.nominalsChanged, true);
        d.setUint32(out + 12, this.discrete.statesChanged, true);
        d.setUint32(out + 16, this.discrete.nextEventTimeDefined, true);
        d.setFloat64(out + 24, this.discrete.nextEventTime, true);
        return status;
      }),
      fmu_set_time: guard('fmu_set_time', (inst, time) => inst.setTime(time)),
      fmu_set_continuous_states: guard('fmu_set_continuous_states', (inst, ptr, n) =>
        inst.setContinuousStates(this.f64(ptr, n))),
      fmu_get_continuous_states: guard('fmu_get_continuous_states', (inst, ptr, n) =>
        inst.getContinuousStates(this.f64(ptr, n))),
      fmu_get_continuous_state_derivatives: guard('fmu_get_continuous_state_derivatives', (inst, ptr, n) =>
        inst.getDerivatives(this.f64(ptr, n))),
      fmu_get_event_indicators: guard('fmu_get_event_indicators', (inst, ptr, n) =>
        inst.getEventIndicators(this.f64(ptr, n))),
      fmu_get_nominals_of_continuous_states: guard('fmu_get_nominals_of_continuous_states', (inst, ptr, n) =>
        inst.getNominals(this.f64(ptr, n))),
      fmu_completed_integrator_step: guard('fmu_completed_integrator_step', (inst, noSetPrior, out) => {
        const status = inst.completedIntegratorStep(noSetPrior, this.completed);
        if (status > 1) return status;
        const d = view();
        d.setUint32(out + 0, this.completed.enterEventMode, true);
        d.setUint32(out + 4, this.completed.terminate, true);
        return status;
      }),
      fmu_do_step: guard('fmu_do_step', (inst, t, h, noSetPrior, out) => {
        const status = inst.doStep(t, h, noSetPrior, this.step);
        if (status > 1) return status;
        const d = view();
        d.setUint32(out + 0, this.step.eventHandlingNeeded, true);
        d.setUint32(out + 4, this.step.terminate, true);
        d.setUint32(out + 8, this.step.earlyReturn, true);
        d.setFloat64(out + 16, this.step.lastSuccessfulTime, true);
        return status;
      }),
      fmu_get_numeric: guard('fmu_get_numeric', (inst, type, vrsPtr, nVrs, valuesPtr, nValues) =>
        inst.getNumeric(type, this.u32(vrsPtr, nVrs), this.f64(valuesPtr, nValues))),
      fmu_set_numeric: guard('fmu_set_numeric', (inst, type, vrsPtr, nVrs, valuesPtr, nValues) =>
        inst.setNumeric(type, this.u32(vrsPtr, nVrs), this.f64(valuesPtr, nValues))),
      fmu_get_directional_derivative: guard('fmu_get_directional_derivative',
        (inst, unknownsPtr, nUnknowns, knownsPtr, nKnowns, seedPtr, nSeed, outPtr, nOut) =>
          inst.getDirectionalDerivative(
            this.u32(unknownsPtr, nUnknowns),
            this.u32(knownsPtr, nKnowns),
            this.f64(seedPtr, nSeed),
            this.f64(outPtr, nOut))),
      fmu_number_of_continuous_states: () => (this.fmu ? this.fmu.numberOfContinuousStates() : -1),
      fmu_number_of_event_indicators: () => (this.fmu ? this.fmu.numberOfEventIndicators() : -1),
    };
  }
}
