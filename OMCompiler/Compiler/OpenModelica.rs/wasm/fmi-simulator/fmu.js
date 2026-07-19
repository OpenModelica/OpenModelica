// Loading of FMI-LS-WASM FMUs: ZIP extraction, modelDescription.xml parsing and
// instantiation of the wasm component. The component is transpiled to JS in the
// browser by jco's js-component-bindgen (vendor/), then instantiated with the
// host imports the fmi:fmi3 worlds require.

async function inflateRaw(bytes) {
  const s = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('deflate-raw'));
  return new Uint8Array(await new Response(s).arrayBuffer());
}

// Minimal ZIP reader over the central directory. Stored and deflated entries only.
export async function readZip(buf) {
  const dv = new DataView(buf), u8 = new Uint8Array(buf), dec = new TextDecoder();
  let eocd = -1;
  for (let i = buf.byteLength - 22; i >= 0 && i > buf.byteLength - 22 - 65536; i--) {
    if (dv.getUint32(i, true) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error('not a ZIP archive: no end-of-central-directory record');
  const count = dv.getUint16(eocd + 10, true);
  let p = dv.getUint32(eocd + 16, true);
  const files = new Map();
  for (let i = 0; i < count; i++) {
    if (dv.getUint32(p, true) !== 0x02014b50) throw new Error('corrupt ZIP central directory');
    const method = dv.getUint16(p + 10, true);
    const csize = dv.getUint32(p + 20, true);
    const nameLen = dv.getUint16(p + 28, true);
    const extraLen = dv.getUint16(p + 30, true);
    const cmtLen = dv.getUint16(p + 32, true);
    const lho = dv.getUint32(p + 42, true);
    const name = dec.decode(u8.subarray(p + 46, p + 46 + nameLen));
    if (csize === 0xffffffff || lho === 0xffffffff) throw new Error(`ZIP64 entry not supported: ${name}`);
    const start = lho + 30 + dv.getUint16(lho + 26, true) + dv.getUint16(lho + 28, true);
    const raw = u8.subarray(start, start + csize);
    if (!name.endsWith('/')) {
      if (method !== 0 && method !== 8) throw new Error(`unsupported ZIP compression method ${method}: ${name}`);
      files.set(name, method === 8 ? await inflateRaw(raw) : raw.slice());
    }
    p += 46 + nameLen + extraLen + cmtLen;
  }
  return files;
}

// FMI 3.0 variable element name -> the get/set suffix used by the WIT methods.
// Enumeration is an Int64 in FMI 3.0.
const TYPES = {
  Float32: 'Float32', Float64: 'Float64',
  Int8: 'Int8', Int16: 'Int16', Int32: 'Int32', Int64: 'Int64',
  UInt8: 'UInt8', UInt16: 'UInt16', UInt32: 'UInt32', UInt64: 'UInt64',
  Boolean: 'Boolean', String: 'String', Binary: 'Binary',
  Enumeration: 'Int64', Clock: 'Clock',
};
const NUMERIC = new Set(['Float32', 'Float64', 'Int8', 'Int16', 'Int32', 'Int64',
  'UInt8', 'UInt16', 'UInt32', 'UInt64', 'Boolean', 'Enumeration']);

const attr = (e, n) => (e && e.hasAttribute(n) ? e.getAttribute(n) : null);
const numAttr = (e, n) => { const v = attr(e, n); return v == null || v === '' ? null : parseFloat(v); };
const boolAttr = (e, n) => { const v = attr(e, n); return v == null ? null : v === 'true' || v === '1'; };

function iface(e) {
  if (!e) return null;
  return {
    modelIdentifier: attr(e, 'modelIdentifier') || '',
    needsExecutionTool: boolAttr(e, 'needsExecutionTool') === true,
    hasEventMode: boolAttr(e, 'hasEventMode') === true,
    canHandleVariableCommunicationStepSize: boolAttr(e, 'canHandleVariableCommunicationStepSize') !== false,
    fixedInternalStepSize: numAttr(e, 'fixedInternalStepSize'),
    providesDirectionalDerivatives: boolAttr(e, 'providesDirectionalDerivatives') === true,
  };
}

// The OpenModelica <Figures> vendor annotation. Absent / unknown-version /
// malformed degrades to []: such an FMU is plotted the ordinary way, never rejected.
function parseFigures(root) {
  const viz = root.querySelector(':scope > Annotations > Tool[name="OpenModelica"] > Figures');
  if (!viz) return [];
  const version = attr(viz, 'version');
  if (version != null && version !== '1') return [];   // unknown schema: ignore, don't guess
  const axis = (plot, role) => {
    const a = plot.querySelector(`:scope > Axis[role="${role}"]`);
    if (!a) return null;
    return {
      label: attr(a, 'label') || '', unit: attr(a, 'unit') || '',
      min: numAttr(a, 'min'), max: numAttr(a, 'max'),
      log: (attr(a, 'scale') || 'Linear') === 'Log',
    };
  };
  const figures = [];
  for (const f of viz.querySelectorAll(':scope > Figure')) {
    const plots = [];
    for (const p of f.querySelectorAll(':scope > Plot')) {
      const curves = [];
      for (const c of p.querySelectorAll(':scope > Curve')) {
        const y = attr(c, 'y'); if (!y) continue;
        curves.push({ x: attr(c, 'x') || '', y, legend: attr(c, 'legend') || '' });
      }
      const tr = p.querySelector(':scope > TerminalRef');
      if (!curves.length) continue;   // TerminalRef-only plot: skip, we render explicit curves
      plots.push({
        title: attr(p, 'title') || '', preferred: boolAttr(p, 'preferred') === true,
        terminal: tr ? attr(tr, 'terminal') : null, curves,
        x: axis(p, 'x'), y: axis(p, 'y'), y2: axis(p, 'y2'),
      });
    }
    if (!plots.length) continue;
    const cap = f.querySelector(':scope > Caption');
    figures.push({
      title: attr(f, 'title') || '', group: attr(f, 'group') || '',
      preferred: boolAttr(f, 'preferred') === true,
      caption: cap ? cap.textContent : '', plots,
    });
  }
  return figures;
}

export function parseModelDescription(xml) {
  const doc = new DOMParser().parseFromString(xml, 'application/xml');
  const perr = doc.querySelector('parsererror');
  if (perr) throw new Error('modelDescription.xml is not well-formed: ' + perr.textContent.trim());
  const root = doc.documentElement;
  if (root.tagName !== 'fmiModelDescription') throw new Error('modelDescription.xml: root element is not fmiModelDescription');
  const fmiVersion = attr(root, 'fmiVersion') || '';
  if (!fmiVersion.startsWith('3.')) throw new Error(`FMI version ${fmiVersion || '?'} is not supported; this simulator requires FMI 3.0`);

  const variables = [];
  const mv = root.querySelector('ModelVariables');
  for (const e of mv ? Array.from(mv.children) : []) {
    const type = TYPES[e.tagName];
    if (!type) continue;
    const start = attr(e, 'start');
    variables.push({
      name: attr(e, 'name') || '',
      vr: parseInt(attr(e, 'valueReference'), 10),
      tag: e.tagName,
      type,
      numeric: NUMERIC.has(e.tagName),
      causality: attr(e, 'causality') || 'local',
      variability: attr(e, 'variability') || (e.tagName.startsWith('Float') ? 'continuous' : 'discrete'),
      start: start == null ? null : start.trim().split(/\s+/)[0],
      initial: attr(e, 'initial'),
      unit: attr(e, 'unit') || attr(e, 'displayUnit') || '',
      description: attr(e, 'description') || '',
      derivative: attr(e, 'derivative'),
    });
  }

  const de = root.querySelector('DefaultExperiment');
  const ms = root.querySelector('ModelStructure');
  return {
    modelName: attr(root, 'modelName') || '',
    fmiVersion,
    instantiationToken: attr(root, 'instantiationToken') || '',
    description: attr(root, 'description') || '',
    generationTool: attr(root, 'generationTool') || '',
    version: attr(root, 'version') || '',
    me: iface(root.querySelector('ModelExchange')),
    cs: iface(root.querySelector('CoSimulation')),
    se: iface(root.querySelector('ScheduledExecution')),
    defaultExperiment: {
      startTime: de ? numAttr(de, 'startTime') : null,
      stopTime: de ? numAttr(de, 'stopTime') : null,
      stepSize: de ? numAttr(de, 'stepSize') : null,
      tolerance: de ? numAttr(de, 'tolerance') : null,
    },
    variables,
    nStates: ms ? ms.querySelectorAll(':scope > ContinuousStateDerivative').length : 0,
    nEventIndicators: ms ? ms.querySelectorAll(':scope > EventIndicator').length : 0,
    figures: parseFigures(root),
  };
}

// The wasm component lives at binaries/wasm32-wasip2/<modelIdentifier>.wasm; fall
// back to the single .wasm in that directory when the identifier does not match.
export function findComponent(files, md) {
  const dir = 'binaries/wasm32-wasip2/';
  const ids = [md.cs, md.me, md.se].filter(Boolean).map((i) => i.modelIdentifier);
  for (const id of ids) {
    const bytes = files.get(`${dir}${id}.wasm`);
    if (bytes) return bytes;
  }
  const candidates = [...files.keys()].filter((n) => n.startsWith(dir) && n.endsWith('.wasm'));
  if (candidates.length === 1) return files.get(candidates[0]);
  if (!candidates.length) throw new Error(`no wasm component found in ${dir} (is this an FMI-LS-WASM FMU?)`);
  throw new Error(`no component matching modelIdentifier ${ids.join('/')} in ${dir}`);
}

let bindgen = null;
async function loadBindgen() {
  if (!bindgen) {
    const m = await import('./vendor/js-component-bindgen-component.js');
    await m.$init;
    bindgen = m;
  }
  return bindgen;
}

// The FMU's resources/ directory, mounted read-only for the guest's WASI filesystem.
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

async function wasiImports(files, onLog) {
  const [cli, io, clocks, random, filesystem] = await Promise.all([
    import('@bytecodealliance/preview2-shim/cli'),
    import('@bytecodealliance/preview2-shim/io'),
    import('@bytecodealliance/preview2-shim/clocks'),
    import('@bytecodealliance/preview2-shim/random'),
    import('@bytecodealliance/preview2-shim/filesystem'),
  ]);
  const dec = new TextDecoder();
  const sink = (tag) => ({
    write: (c) => onLog(tag, dec.decode(c).replace(/\n$/, '')),
    blockingFlush() {}, blockingWriteAndFlush: (c) => onLog(tag, dec.decode(c).replace(/\n$/, '')),
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
      'wasi:clocks/monotonic-clock': clocks.monotonicClock, 'wasi:clocks/wall-clock': clocks.wallClock,
      'wasi:filesystem/preopens': filesystem.preopens, 'wasi:filesystem/types': filesystem.types,
      'wasi:io/error': io.error, 'wasi:io/poll': io.poll, 'wasi:io/streams': io.streams,
      'wasi:random/random': random.random, 'wasi:random/insecure': random.insecure,
      'wasi:random/insecure-seed': random.insecureSeed,
    },
  };
}

const find = (exports, prefix, camel) =>
  exports[Object.keys(exports).find((k) => k.startsWith(prefix))] ?? exports[camel];

export async function loadFmu(buf, { onLog }) {
  const files = await readZip(buf);
  const mdFile = files.get('modelDescription.xml');
  if (!mdFile) throw new Error('modelDescription.xml is missing from the archive');
  const md = parseModelDescription(new TextDecoder().decode(mdFile));
  const component = findComponent(files, md);

  const { generate } = await loadBindgen();
  const gen = generate(new Uint8Array(component), {
    name: 'fmu', map: [], instantiation: { tag: 'async' },
    validLiftingOptimization: false, tracing: false, noNodejsCompat: true,
    noTypescript: true, tlaCompat: false, base64Cutoff: 0,
    noNamespacedExports: false, multiMemory: false,
  });

  const cores = new Map(gen.files.filter(([n]) => n.endsWith('.wasm')));
  const jsFile = gen.files.find(([n]) => n.endsWith('.js'));
  const url = URL.createObjectURL(new Blob([jsFile[1]], { type: 'text/javascript' }));
  let instantiate;
  try { ({ instantiate } = await import(url)); } finally { URL.revokeObjectURL(url); }

  const { imports, resourcePath } = await wasiImports(files, onLog);
  const callbacks = {
    logMessage: (instanceName, status, category, message) =>
      onLog(status, `[${instanceName}] ${category ? category + ': ' : ''}${message}`),
    clockUpdate() {}, lockPreemption() {}, unlockPreemption() {},
  };
  imports['fmi:fmi3/callbacks'] = callbacks;
  imports['fmi:fmi3/intermediate-update-callbacks'] = {
    intermediateUpdate: () => ({ earlyReturnRequested: false, earlyReturnTime: 0 }),
  };

  const missing = gen.imports.filter((n) => !imports[n]);
  if (missing.length) throw new Error(`FMU needs imports this host does not provide: ${missing.join(', ')}`);

  // Each instantiation gets its own wasm memory, so every run starts from a
  // clean FMU rather than inheriting whatever the previous one left behind.
  const modules = new Map();
  const compile = async (n) => {
    if (!modules.has(n)) modules.set(n, await WebAssembly.compile(cores.get(n)));
    return modules.get(n);
  };
  const instance = async () => {
    const exports = await instantiate(compile, imports);
    return {
      md, resourcePath, exports,
      common: find(exports, 'fmi:fmi3/common', 'common'),
      cs: find(exports, 'fmi:fmi3/co-simulation', 'coSimulation'),
      me: find(exports, 'fmi:fmi3/model-exchange', 'modelExchange'),
    };
  };
  return { md, files, instance };
}
