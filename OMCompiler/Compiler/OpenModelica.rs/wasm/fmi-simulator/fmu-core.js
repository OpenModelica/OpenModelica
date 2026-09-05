// Reaching an fmi-ls-wasm FMU's *core* exports, past the component glue.
//
// jco is still what instantiates the component — it wires the core modules, the
// WASI imports and the resource tables, which is work nobody should redo. But
// its generated wrappers cost ~4 µs a call: each one allocates the argument
// objects of its (disabled) debug logging, runs the task machinery, and copies
// list results out through `memory0.buffer.slice()`. Calling the lowered core
// exports directly costs ~130 ns, which is what a solver taking millions of
// steps needs.
//
// The generated module keeps everything in module-level variables, so it is
// patched at load time with one extra export handing them out. What each
// function's lowering looks like is read from jco's own wrappers rather than
// re-derived from the canonical ABI: the same source generates both, so they
// cannot drift.

const PACKAGE = 'fmi:fmi3';

// The FMI status codes, in the order the WIT enum declares them.
export const STATUS = { ok: 0, warning: 1, discard: 2, error: 3, fatal: 4 };
// The bridge's own "the call could not be made".
export const HOST_FAILED = 5;

let bindgen = null;

// jco's transpiler, itself a component transpiled to JS. It imports the WASI
// shim by bare specifier, which the page resolves with an import map — but a
// worker has no import map, so the specifiers are rewritten to URLs here and
// the rewritten source imported instead.
async function loadBindgen() {
  if (bindgen) return bindgen;
  const url = new URL('./vendor/js-component-bindgen-component.js', import.meta.url);
  const source = (await readText(url))
    .replace(/(['"])@bytecodealliance\/preview2-shim\/(\w+)\1/g, (_, q, name) =>
      JSON.stringify(new URL(`./vendor/preview2-shim/${name}.js`, import.meta.url).href))
    // The rewritten source is imported from a blob, which has no base for the
    // core modules it loads beside itself; point them at where it really lives.
    .replaceAll('import.meta.url', JSON.stringify(url.href));
  const m = await importSource(source);
  await m.$init;
  bindgen = m;
  return m;
}

// Read the lowering out of jco's own wrappers: which core export each method
// call ends up in, which post-return it pairs with, and which resource table
// holds the instance. Going by the wrappers rather than by the export names
// matters — where two FMI functions compile to the same code, the component
// exports one function under both names, and only the wrapper says which
// variable that is.
function readBindings(source) {
  const fn = new Map();
  const post = new Map();
  const table = new Map();
  const wrapper = /(\w+Instance)\.(?:prototype\.)?(\w+) = function \w+\([^)]*\) \{([\s\S]*?)\n\};/g;
  for (const m of source.matchAll(wrapper)) {
    const [, resource, method, body] = m;
    const handleTable = body.match(/(handleTable\d+)\[/);
    if (handleTable) table.set(resource, handleTable[1]);
    const called = body.match(/fn: \(\) => (\w+)\(/);
    if (!called) continue;
    const key = `${interfaceOf(resource)}.${kebab(method)}`;
    fn.set(key, called[1]);
    const postReturn = body.match(/(postReturn\d+)\(ret\)/);
    if (postReturn) post.set(key, postReturn[1]);
  }
  const memory = source.match(/^\s*(memory\d+) = exports\d+\.memory;/m);
  const realloc = source.match(/^\s*(realloc\d+) = exports\d+\.cabi_realloc;/m);
  return { fn, post, table, memory: memory && memory[1], realloc: realloc && realloc[1] };
}

const interfaceOf = (resource) =>
  resource === 'CoSimulationInstance' ? 'co-simulation' : 'model-exchange';

// `getContinuousStateDerivatives` → `get-continuous-state-derivatives`.
const kebab = (name) => name.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();

// Everything the fast path needs, by the names jco chose.
//
// In `instantiation: async` mode the whole generated module is one
// `instantiate()` function and its bindings are locals of it, so the collecting
// statement goes *inside*, right after the last one is assigned; only the box it
// fills is at module scope.
function patch(source, bindings) {
  const entries = [...bindings.fn].map(([key, variable]) => `${JSON.stringify(key)}: ${variable}`);
  const posts = [...bindings.post].map(([key, variable]) => `${JSON.stringify(key)}: ${variable}`);
  const tables = [...bindings.table].map(([r, t]) => `${JSON.stringify(r)}: ${t}`);
  const collect = `
__fastPathStore.current = {
  memory: ${bindings.memory},
  realloc: ${bindings.realloc},
  tFlag: T_FLAG,
  tables: { ${tables.join(', ')} },
  fn: { ${entries.join(', ')} },
  post: { ${posts.join(', ')} },
  // A guest calling back into the host — logging, WASI — goes through jco's
  // import lowering, which insists on a current task. The fast path opens one
  // for the whole run instead of one per call.
  createTask: createNewCurrentTask,
  setTaskMeta: _setGlobalCurrentTaskMeta,
  clearTaskMeta: _clearCurrentTask,
};
`;
  const bindingLines = [...source.matchAll(/^.*= exports\d+(?:\[|\.).*$/gm)];
  const last = bindingLines[bindingLines.length - 1];
  const at = last.index + last[0].length;
  const header = `export const __fastPathStore = { current: null };
export function __fastPath(instance) {
  const handle = instance && Object.getOwnPropertySymbols(instance)
    .map((s) => instance[s]).find((v) => typeof v === 'number');
  if (!__fastPathStore.current) throw new Error('the component did not expose its core exports');
  return { handle, ...__fastPathStore.current };
}
`;
  return header + source.slice(0, at) + collect + source.slice(at);
}

// The text at `url`. `fetch` cannot read a `file:` URL, which is how this runs
// outside a browser (the driver's own tests).
async function readText(url) {
  if (url.protocol === 'file:') {
    const { readFile } = await import('node:fs/promises');
    return readFile(url, 'utf8');
  }
  return (await fetch(url)).text();
}

// Import generated source as a module: a blob URL in the browser, a data URL
// where blob URLs are not importable (node). Neither keeps the base a relative
// import would need, so callers rewrite those to URLs first.
async function importSource(source) {
  if (typeof URL.createObjectURL === 'function' && typeof Blob !== 'undefined') {
    const url = URL.createObjectURL(new Blob([source], { type: 'text/javascript' }));
    try {
      return await import(url);
    } catch (e) {
      if (typeof process === 'undefined') throw e;
    } finally {
      URL.revokeObjectURL(url);
    }
  }
  return import(`data:text/javascript;base64,${btoa(unescape(encodeURIComponent(source)))}`);
}

// The FMU's `resources/` directory as the tree the WASI shim mounts.
function resourceTree(files) {
  const root = { dir: {} };
  let any = false;
  for (const [name, bytes] of files) {
    if (!name.startsWith('resources/')) continue;
    any = true;
    const parts = name.slice('resources/'.length).split('/');
    let node = root;
    for (const p of parts.slice(0, -1)) node = node.dir[p] = node.dir[p] || { dir: {} };
    node.dir[parts.at(-1)] = { source: bytes };
  }
  return any ? root : null;
}

async function wasiImports(files, onLog, shimBase) {
  const load = (name) => import(new URL(`${shimBase}/${name}.js`, import.meta.url).href);
  const [cli, io, clocks, random, filesystem] = await Promise.all(
    ['cli', 'io', 'clocks', 'random', 'filesystem'].map(load));
  const dec = new TextDecoder();
  const sink = (tag) => ({
    write: (c) => onLog(tag, dec.decode(c).replace(/\n$/, '')),
    blockingFlush() {},
    blockingWriteAndFlush: (c) => onLog(tag, dec.decode(c).replace(/\n$/, '')),
    [Symbol.dispose || Symbol.for('dispose')]() {},
  });
  cli._setStdout(sink('stdout'));
  cli._setStderr(sink('stderr'));

  const tree = resourceTree(files);
  let resourcePath = '';
  if (tree) {
    filesystem._setPreopens({ '/': tree });
    resourcePath = '/';
  }
  return {
    resourcePath,
    imports: {
      'wasi:cli/environment': cli.environment, 'wasi:cli/exit': cli.exit,
      'wasi:cli/stdin': cli.stdin, 'wasi:cli/stdout': cli.stdout, 'wasi:cli/stderr': cli.stderr,
      'wasi:cli/terminal-input': cli.terminalInput, 'wasi:cli/terminal-output': cli.terminalOutput,
      'wasi:cli/terminal-stdin': cli.terminalStdin, 'wasi:cli/terminal-stdout': cli.terminalStdout,
      'wasi:cli/terminal-stderr': cli.terminalStderr,
      'wasi:clocks/monotonic-clock': clocks.monotonicClock,
      'wasi:clocks/wall-clock': clocks.wallClock,
      'wasi:filesystem/preopens': filesystem.preopens, 'wasi:filesystem/types': filesystem.types,
      'wasi:io/error': io.error, 'wasi:io/poll': io.poll, 'wasi:io/streams': io.streams,
      'wasi:random/random': random.random, 'wasi:random/insecure': random.insecure,
      'wasi:random/insecure-seed': random.insecureSeed,
    },
  };
}

const find = (exports, prefix, camel) =>
  exports[Object.keys(exports).find((k) => k.startsWith(prefix))] ?? exports[camel];

// Transpile and instantiate the component. `files` is the FMU archive, whose
// `resources/` the guest sees as its filesystem.
export async function loadComponent(component, { files, onLog, shimBase = './vendor/preview2-shim' }) {
  const { generate } = await loadBindgen();
  const gen = generate(new Uint8Array(component), {
    name: 'fmu', map: [], instantiation: { tag: 'async' },
    validLiftingOptimization: false, tracing: false, noNodejsCompat: true,
    noTypescript: true, tlaCompat: false, base64Cutoff: 0,
    noNamespacedExports: false, multiMemory: false,
  });
  const cores = new Map(gen.files.filter(([n]) => n.endsWith('.wasm')));
  const source = new TextDecoder().decode(gen.files.find(([n]) => n.endsWith('.js'))[1]);
  const bindings = readBindings(source);
  const module = await importSource(patch(source, bindings));

  const { imports, resourcePath } = await wasiImports(files, onLog, shimBase);
  imports['fmi:fmi3/callbacks'] = {
    logMessage: (instanceName, status, category, message) =>
      onLog(status, `[${instanceName}] ${category ? category + ': ' : ''}${message}`),
    clockUpdate() {}, lockPreemption() {}, unlockPreemption() {},
  };
  imports['fmi:fmi3/intermediate-update-callbacks'] = {
    intermediateUpdate: () => ({ earlyReturnRequested: false, earlyReturnTime: 0 }),
  };
  // `external "C"` served from a platform library: nothing to serve it from here.
  for (const n of gen.imports.filter((n) => n.startsWith('om:ext/native'))) {
    imports[n] = {
      call: () => ({ tag: 'err', val: 'this FMU needs a native external "C" library, which a browser cannot load' }),
    };
  }
  const missing = gen.imports.filter((n) => !imports[n]);
  if (missing.length) {
    throw new Error(`the FMU needs imports this host does not provide: ${missing.join(', ')}`);
  }

  const modules = new Map();
  const compile = async (n) => {
    if (!modules.has(n)) modules.set(n, await WebAssembly.compile(cores.get(n)));
    return modules.get(n);
  };
  // Each run instantiates afresh, so a second run cannot inherit the first
  // one's state.
  const instantiate = async (kind, options) => {
    const t0 = performance.now();
    const exports = await module.instantiate(compile, imports);
    const t1 = performance.now();
    const instance = newInstance(module, exports, kind, { resourcePath, ...options });
    instance.timing = { modules: t1 - t0, instance: performance.now() - t1 };
    return instance;
  };
  // A plain jco instance, for asking an FMU what it offers before a run.
  const probe = async () => {
    const exports = await module.instantiate(compile, imports);
    return {
      resourcePath,
      exports,
      common: find(exports, `${PACKAGE}/common`, 'common'),
      cs: find(exports, `${PACKAGE}/co-simulation`, 'coSimulation'),
      me: find(exports, `${PACKAGE}/model-exchange`, 'modelExchange'),
    };
  };
  return { instantiate, probe, resourcePath, interfaces: interfacesOf(gen) };
}

function interfacesOf(gen) {
  const has = (name) => gen.exports.some(([n]) => n.startsWith(`${PACKAGE}/${name}`));
  return { me: has('model-exchange'), cs: has('co-simulation'), se: has('scheduled-execution') };
}

function newInstance(module, exports, kind, options) {
  const iface = kind === 'cs' ? 'co-simulation' : 'model-exchange';
  const api = find(exports, `${PACKAGE}/${iface}`, kind === 'cs' ? 'coSimulation' : 'modelExchange');
  if (!api) throw new Error(`the FMU has no ${iface} interface`);
  const cls = kind === 'cs' ? api.CoSimulationInstance : api.ModelExchangeInstance;
  const { name, token, loggingOn = false, eventMode = false, earlyReturn = false } = options;
  // Instantiation goes through jco: it happens once, and it is what puts the
  // resource in the table the fast path reads the representation out of.
  const instance = kind === 'cs'
    ? cls.instantiateCoSimulation(
      name, token, options.resourcePath, false, loggingOn, eventMode, earlyReturn, [])
    : cls.instantiateModelExchange(name, token, options.resourcePath, false, loggingOn);
  if (!instance) throw new Error(`instantiate-${iface} returned no instance`);
  return new FastFmu(module.__fastPath(instance), iface, instance);
}

// One FMU instance, called through its core exports. Every method returns an
// FMI status; values move through `Float64Array`s the caller owns (the driver's
// memory), copied in and out of the FMU's.
class FastFmu {
  constructor(fast, iface, instance) {
    this.fast = fast;
    this.iface = iface;
    this.instance = instance;
    // The methods take the resource's representation, which jco's own wrappers
    // look up in the table it keeps for that resource type.
    const table = fast.tables[
      iface === 'co-simulation' ? 'CoSimulationInstance' : 'ModelExchangeInstance'];
    this.handle = table ? (table[(fast.handle << 1) + 1] & ~fast.tFlag) : fast.handle;
    if (!this.handle) throw new Error('the FMU instance has no representation to call with');
    this.memory = typeof fast.memory === 'function' ? fast.memory() : fast.memory;
    this.realloc = fast.realloc;
    this.view = new DataView(this.memory.buffer);
    this.f64 = new Float64Array(this.memory.buffer);
    this.u32 = new Uint32Array(this.memory.buffer);
    this.task = null;
  }

  // jco's own wrapper, for the calls the fast path does not cover.
  slow() {
    return this.instance;
  }

  // Open the task the FMU's own calls back into the host need, for as long as
  // the run lasts.
  begin() {
    if (this.task) return;
    const [task] = this.fast.createTask({
      componentIdx: 0,
      isAsync: false,
      isManualAsync: false,
      entryFnName: 'openmodelica-fmi-driver',
      getCallbackFn: () => null,
      callbackFnName: null,
      errHandling: 'none',
      callingWasmExport: true,
    });
    task.enterSync();
    this.fast.setTaskMeta({ taskID: task.id(), componentIdx: 0 });
    this.task = task;
  }

  end() {
    if (!this.task) return;
    try {
      this.fast.clearTaskMeta({ componentIdx: 0, taskID: this.task.id() });
      // A task has to be resolved before it may exit, the way jco's own
      // wrappers resolve theirs with the call's result.
      this.task.resolve([0]);
      this.task.exit();
    } finally {
      this.task = null;
    }
  }

  // The memory grows as the FMU allocates, which detaches the views.
  refresh() {
    if (this.f64.buffer !== this.memory.buffer || this.f64.byteLength === 0) {
      this.view = new DataView(this.memory.buffer);
      this.f64 = new Float64Array(this.memory.buffer);
      this.u32 = new Uint32Array(this.memory.buffer);
    }
  }

  fn(method) {
    const f = this.fast.fn[`${this.iface}.${method}`];
    if (!f) throw new Error(`the FMU does not export ${this.iface} ${method}`);
    return f;
  }

  post(method) {
    return this.fast.post[`${this.iface}.${method}`];
  }

  // Memory in the FMU for one list argument. It cannot be reused: a list
  // passed to a guest export is *owned* by the guest, which frees it — a
  // second call with the same pointer hands the allocator memory it has
  // already released, and the FMU traps a few calls later.
  alloc(bytes) {
    const ptr = this.realloc(0, 0, 8, bytes);
    this.refresh();
    return ptr;
  }

  // Call a method whose result is a bare status.
  status(method, ...args) {
    return this.fn(method)(this.handle, ...args);
  }

  // Call a method returning `result<list<f64>, status>` and copy the values
  // into `out`.
  list(method, out, ...args) {
    const ret = this.fn(method)(this.handle, ...args);
    this.refresh();
    if (this.view.getUint8(ret + 0) !== 0) return this.view.getUint8(ret + 4);
    const ptr = this.view.getUint32(ret + 4, true);
    const len = this.view.getUint32(ret + 8, true);
    out.set(this.f64.subarray(ptr / 8, ptr / 8 + Math.min(len, out.length)));
    const post = this.post(method);
    if (post) post(ret);
    return STATUS.ok;
  }

  setTime(time) {
    return this.status('set-time', time);
  }

  setContinuousStates(values) {
    const ptr = this.alloc(values.length * 8);
    this.f64.set(values, ptr / 8);
    return this.status('set-continuous-states', ptr, values.length);
  }

  getContinuousStates(out) {
    return this.list('get-continuous-states', out);
  }

  getDerivatives(out) {
    return this.list('get-continuous-state-derivatives', out);
  }

  getEventIndicators(out) {
    return this.list('get-event-indicators', out);
  }

  getNominals(out) {
    return this.list('get-nominals-of-continuous-states', out);
  }

  enterInitializationMode(toleranceDefined, tolerance, startTime, stopTimeDefined, stopTime) {
    return this.status('enter-initialization-mode',
      toleranceDefined, tolerance, startTime, stopTimeDefined, stopTime);
  }

  exitInitializationMode() {
    return this.status('exit-initialization-mode');
  }

  enterEventMode() {
    return this.status('enter-event-mode');
  }

  // Where a structural parameter may be set — fmi-ls-dae's `_D_daeMode`, which
  // turns the ODE face of a `--daeMode` FMU into its residual one.
  enterConfigurationMode() {
    return this.status('enter-configuration-mode');
  }

  exitConfigurationMode() {
    return this.status('exit-configuration-mode');
  }

  enterContinuousTimeMode() {
    return this.status('enter-continuous-time-mode');
  }

  enterStepMode() {
    return this.status('enter-step-mode');
  }

  terminate() {
    return this.status('terminate');
  }

  // Back to the state a fresh instance is in, which is what the next run wants
  // — and an order of magnitude cheaper than instantiating the component again.
  reset() {
    return this.status('reset');
  }

  // `update-discrete-states` → the five flags and the next event time.
  updateDiscreteStates(out) {
    const ret = this.fn('update-discrete-states')(this.handle);
    this.refresh();
    if (this.view.getUint8(ret + 0) !== 0) return this.view.getUint8(ret + 8);
    out.needUpdate = this.view.getUint8(ret + 8);
    out.terminate = this.view.getUint8(ret + 9);
    out.nominalsChanged = this.view.getUint8(ret + 10);
    out.statesChanged = this.view.getUint8(ret + 11);
    out.nextEventTimeDefined = this.view.getUint8(ret + 12);
    out.nextEventTime = this.view.getFloat64(ret + 16, true);
    return STATUS.ok;
  }

  completedIntegratorStep(noSetStatePrior, out) {
    const ret = this.fn('completed-integrator-step')(this.handle, noSetStatePrior);
    this.refresh();
    if (this.view.getUint8(ret + 0) !== 0) return this.view.getUint8(ret + 1);
    out.enterEventMode = this.view.getUint8(ret + 1);
    out.terminate = this.view.getUint8(ret + 2);
    return STATUS.ok;
  }

  doStep(currentCommunicationPoint, communicationStepSize, noSetStatePrior, out) {
    const ret = this.fn('do-step')(
      this.handle, currentCommunicationPoint, communicationStepSize, noSetStatePrior);
    this.refresh();
    if (this.view.getUint8(ret + 0) !== 0) return this.view.getUint8(ret + 8);
    out.lastSuccessfulTime = this.view.getFloat64(ret + 8, true);
    out.eventHandlingNeeded = this.view.getUint8(ret + 16);
    out.terminate = this.view.getUint8(ret + 17);
    out.earlyReturn = this.view.getUint8(ret + 18);
    return STATUS.ok;
  }

  // `get-directional-derivative(unknowns, knowns, seed) -> list<f64>`: three
  // lists in, one out.
  getDirectionalDerivative(unknowns, knowns, seed, out) {
    const method = 'get-directional-derivative';
    const unknownsPtr = this.alloc(unknowns.length * 4);
    this.u32.set(unknowns, unknownsPtr / 4);
    const knownsPtr = this.alloc(knowns.length * 4);
    this.u32.set(knowns, knownsPtr / 4);
    const seedPtr = this.alloc(seed.length * 8);
    this.f64.set(seed, seedPtr / 8);
    return this.list(
      method, out, unknownsPtr, unknowns.length, knownsPtr, knowns.length, seedPtr, seed.length);
  }

  // `result<u64, status>`; `-1` when the FMU does not export the call.
  count(method) {
    const f = this.fast.fn[`${this.iface}.${method}`];
    if (!f) return -1;
    const ret = f(this.handle);
    this.refresh();
    if (this.view.getUint8(ret + 0) !== 0) return -1;
    return Number(this.view.getBigInt64(ret + 8, true));
  }

  numberOfContinuousStates() {
    return this.count('get-number-of-continuous-states');
  }

  numberOfEventIndicators() {
    return this.count('get-number-of-event-indicators');
  }

  // The typed `get`/`set` pairs, by the driver's type code.
  getNumeric(type, vrs, values) {
    const method = `get-${TYPE_METHOD[type]}`;
    const ptr = this.writeVrs(vrs);
    if (TYPE_IS_F64[type]) return this.list(method, values, ptr, vrs.length);
    const ret = this.fn(method)(this.handle, ptr, vrs.length);
    this.refresh();
    if (this.view.getUint8(ret + 0) !== 0) return this.view.getUint8(ret + 4);
    const dataPtr = this.view.getUint32(ret + 4, true);
    const len = Math.min(this.view.getUint32(ret + 8, true), values.length);
    const read = TYPE_READ[type];
    for (let i = 0; i < len; i++) values[i] = read(this.view, dataPtr + i * TYPE_SIZE[type]);
    const post = this.post(method);
    if (post) post(ret);
    return STATUS.ok;
  }

  setNumeric(type, vrs, values) {
    const method = `set-${TYPE_METHOD[type]}`;
    const ptr = this.writeVrs(vrs);
    const size = TYPE_SIZE[type];
    const valuesPtr = this.alloc(values.length * size);
    const write = TYPE_WRITE[type];
    for (let i = 0; i < values.length; i++) write(this.view, valuesPtr + i * size, values[i]);
    return this.status(method, ptr, vrs.length, valuesPtr, values.length);
  }

  writeVrs(vrs) {
    const ptr = this.alloc(vrs.length * 4);
    this.u32.set(vrs, ptr / 4);
    return ptr;
  }
}

// The driver's type codes (openmodelica_fmi_driver::wasm_host::type_code).
const TYPE_METHOD = [
  'float32', 'float64', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32',
  'int64', 'uint64', 'boolean', 'string', 'binary', 'clock',
];
const TYPE_SIZE = [4, 8, 1, 1, 2, 2, 4, 4, 8, 8, 1, 8, 8, 1];
const TYPE_IS_F64 = TYPE_METHOD.map((t) => t === 'float64');
const TYPE_READ = [
  (v, p) => v.getFloat32(p, true), (v, p) => v.getFloat64(p, true),
  (v, p) => v.getInt8(p), (v, p) => v.getUint8(p),
  (v, p) => v.getInt16(p, true), (v, p) => v.getUint16(p, true),
  (v, p) => v.getInt32(p, true), (v, p) => v.getUint32(p, true),
  (v, p) => Number(v.getBigInt64(p, true)), (v, p) => Number(v.getBigUint64(p, true)),
  (v, p) => v.getUint8(p), () => 0, () => 0, (v, p) => v.getUint8(p),
];
const TYPE_WRITE = [
  (v, p, x) => v.setFloat32(p, x, true), (v, p, x) => v.setFloat64(p, x, true),
  (v, p, x) => v.setInt8(p, Math.round(x)), (v, p, x) => v.setUint8(p, Math.round(x)),
  (v, p, x) => v.setInt16(p, Math.round(x), true), (v, p, x) => v.setUint16(p, Math.round(x), true),
  (v, p, x) => v.setInt32(p, Math.round(x), true), (v, p, x) => v.setUint32(p, Math.round(x), true),
  (v, p, x) => v.setBigInt64(p, BigInt(Math.round(x)), true),
  (v, p, x) => v.setBigUint64(p, BigInt(Math.max(0, Math.round(x))), true),
  (v, p, x) => v.setUint8(p, x ? 1 : 0), () => {}, () => {}, (v, p, x) => v.setUint8(p, x ? 1 : 0),
];
