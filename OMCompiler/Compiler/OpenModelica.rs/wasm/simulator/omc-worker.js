// Simulator omc Web Worker.
//
// Hosts the omc wasm module off the UI thread so compile/simulate never freezes
// the page. The simulator spawns two of these: a plain one that is ready fast
// (no library), and a second that installs the MSL in the background and takes
// over once ready (see index.html). Talks an id-correlated RPC:
//   page → { id, cmd, ... }         worker → { type:'reply', id, ok, result|error }
// plus unsolicited { type:'status', id, text } for download progress.
import init, {
  omc_set_env, omc_init, omc_eval, omc_simulate, omc_set_inwasm_driver,
  omc_sim_start, omc_sim_advance, omc_sim_free,
  omc_take_pending_downloads, wasi_write_file,
  wasi_path_open, wasi_fd_read, wasi_fd_close,
  omc_sim_info, omc_sim_series, omc_sim_time, omc_sim_column, omc_sim_parameters,
  omc_anim_scene, omc_anim_all_frames, omc_anim_stride, omc_dxf_mesh,
} from '../omc/OpenModelicaCompiler.js';

// Set by a {cmd:'cancelSim'} message; honored by `runResumable` between chunks, so a
// long sim is cancelled without killing the worker (which would drop the MSL + JIT).
let simCancel = false;

// `?driver=` override (0 host, 1 in-wasm), applied once the module is up.
let driverMode = null;
let inited = false;

const esc = (s) => s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\t/g, '\\t');
const unquote = (s) => { s = (s || '').trim(); return (s.startsWith('"') && s.endsWith('"')) ? s.slice(1, -1) : s; };

// --- profiling -------------------------------------------------------------
// Per-op/per-stage timings for diagnosing where the wall time goes. Off by
// default; the per-command total is logged regardless.
const PROF = false;
let _plog = () => {};
function prof(label, fn) {
  if (!PROF) return fn();
  const t = performance.now();
  try { return fn(); } finally { _plog('⏱ ' + label + ' ' + (performance.now() - t).toFixed(1) + 'ms'); }
}
// omc_eval, timed and labelled by the head of the command string.
function oeval(src) {
  return prof('eval ' + src.slice(0, 48).replace(/\n/g, ' '), () => omc_eval(src));
}

// Read a whole VFS file (WASI path_open → fd_read → fd_close). undefined if absent.
function wasiReadFile(path) {
  const fd = wasi_path_open(path);
  if (fd < 0) return undefined;
  try { return wasi_fd_read(fd) || undefined; } finally { wasi_fd_close(fd); }
}
function base64(bytes) {
  let s = ''; const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) s += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
  return btoa(s);
}

async function fetchToVfs(urls, filename) {
  for (const url of urls) {
    try { const r = await fetch(url); if (!r.ok) continue;
      wasi_write_file(filename, new Uint8Array(await r.arrayBuffer())); return true; } catch (_) {}
  }
  return false;
}

// Run `src`, satisfy any files it wanted, re-run until nothing new is needed.
async function evalWithDownloads(src, onStatus) {
  const attempted = new Set();
  for (;;) {
    const result = oeval(src);
    const pending = (omc_take_pending_downloads() || []).filter((p) => !attempted.has(p.filename));
    if (pending.length === 0) return result;
    omc_eval('getErrorString()');
    for (const item of pending) {
      attempted.add(item.filename);
      onStatus && onStatus('Downloading ' + (item.filename.split('/').pop() || item.filename) + '…');
      await fetchToVfs(item.urls, item.filename);
    }
  }
}

function lastClassName() {
  const inner = omc_eval('getClassNames()').trim().replace(/^\{|\}$/g, '').trim();
  if (!inner) return null;
  const names = inner.split(',').map((s) => s.trim()).filter(Boolean);
  return names[names.length - 1] || null;
}

// The settings simulate() actually used (from its returned SimulationResult),
// so the dialog reflects the run — no separate getSimulationOptions call.
function parseSimOptions(result) {
  const m = /simulationOptions = "([^"]*)"/.exec(result || '');
  if (!m) return null;
  const s = m[1], num = (k) => { const r = new RegExp(k + '\\s*=\\s*([0-9.eE+-]+)').exec(s); return r ? +r[1] : null; };
  return { stopTime: num('stopTime'), tolerance: num('tolerance'), intervals: num('numberOfIntervals') };
}
// simulate()'s internal stage timers (seconds) → log as ms so we can see which
// build stage dominates: front/back/simcode/templates/compile(JIT)/sim.
function logSimTimers(result) {
  if (!PROF) return;
  const g = (k) => { const r = new RegExp('time' + k + '\\s*=\\s*([0-9.eE+-]+)').exec(result || ''); return r ? (+r[1] * 1000).toFixed(1) : '?'; };
  _plog('⏱ sim internal: front=' + g('Frontend') + ' back=' + g('Backend') + ' simcode=' + g('SimCode')
    + ' tpl=' + g('Templates') + ' compile=' + g('Compile') + ' sim=' + g('Simulation') + ' total=' + g('Total') + ' (ms)');
}

// Run `fn` with API results dumped as JSON (so JSON.parse works), then restore.
function withJsonDump(fn) {
  oeval('setCommandLineOptions("--interactiveDumpFormat=json")');
  try { return fn(); } finally { oeval('setCommandLineOptions("--interactiveDumpFormat=default")'); }
}
function figuresFor(model) {
  try {
    const figs = JSON.parse(withJsonDump(() => oeval(`getModelFigures(${model})`)));
    return Array.isArray(figs) && figs.length ? figs : null;
  } catch (_) { return null; }
}
// getDocumentationAnnotation → {info, revision, infoHeader}; return the info HTML
// with any modelica:// image resolved through the VFS and inlined as a data URI.
function documentationFor(model) {
  try {
    const arr = JSON.parse(withJsonDump(() => oeval(`getDocumentationAnnotation(${model})`)));
    return inlineDocImages(Array.isArray(arr) ? (arr[0] || '') : '');
  } catch (_) { return ''; }
}
const MIME = { png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg', gif: 'image/gif', svg: 'image/svg+xml', bmp: 'image/bmp' };
function modelicaUriToDataUri(uri) {
  try {
    const path = unquote(omc_eval(`uriToFilename("${esc(uri)}")`));
    if (!path) return null;
    const bytes = wasiReadFile(path);
    if (!bytes) return null;
    return 'data:' + (MIME[(path.split('.').pop() || '').toLowerCase()] || 'application/octet-stream') + ';base64,' + base64(bytes);
  } catch (_) { return null; }
}
function inlineDocImages(html) {
  return html.replace(/(<img\b[^>]*\bsrc\s*=\s*")(modelica:\/\/[^"]+)(")/gi,
    (m, pre, uri, post) => { const d = modelicaUriToDataUri(uri); return d ? pre + d + post : m; });
}

// One transferable snapshot of the finished run: everything the charts need, so
// the page pulls the whole result across in a single message instead of many.
function snapshot() {
  const info = prof('sim_info', () => omc_sim_info());
  if (!info || !info.rows) return null;
  const parameters = prof('sim_parameters', () => omc_sim_parameters()) || [];
  const series = prof('sim_series', () => omc_sim_series()) || [];
  const cols = {};                       // name -> Float64Array
  const transfer = [];
  prof('sim_columns x' + series.length, () => {
    series.forEach((m, i) => { const c = omc_sim_column(i); if (c) { cols[m.name] = c; transfer.push(c.buffer); } });
  });
  const time = prof('sim_time', () => omc_sim_time()) || null;
  if (time) transfer.push(time.buffer);
  return { snap: { ok: true, info, parameters, series, cols, time }, transfer };
}

function simError(fallback) {
  return { ok: false, error: omc_eval('getErrorString()').trim() || fallback };
}

// Chunked, cancellable integration of a prepared model. Each `omc_sim_advance`
// runs ~BUDGET_MS of wall-clock (it times itself), then we yield to the message
// loop so a queued {cmd:'cancelSim'} can set `simCancel`. A run that finishes in
// one chunk never yields. Returns the status: 1 done, 2 terminated, 3 cancelled, <0 error.
async function runResumable(prefix, simflags, onStatus) {
  simCancel = false;   // discard a cancel that raced in after the previous run
  if (!omc_sim_start(prefix, prefix + '_res.mat', simflags)) return -1;
  onStatus && onStatus('Simulating…');
  const BUDGET_MS = 150;
  for (;;) {
    if (simCancel) { simCancel = false; omc_sim_free(); return 3; }
    const st = omc_sim_advance(BUDGET_MS);
    if (st !== 0) return st;
    await new Promise((r) => setTimeout(r, 0));   // let cancelSim land
  }
}

// The settings a run used, to seed the dialog: the explicit ones the page sent, or
// getSimulationOptions → (startTime, stopTime, tolerance, numberOfIntervals) for a
// fresh model driven by its `experiment` annotation.
function simOptions(name, a) {
  if (a.stopTime) return { stopTime: a.stopTime, tolerance: a.tolerance || null, intervals: a.intervals || null };
  const n = (omc_eval(`getSimulationOptions(${name})`).match(/-?[0-9][0-9.eE+-]*/g) || []).map(Number);
  return { stopTime: n[1] ?? null, tolerance: n[2] ?? null, intervals: n[3] ?? null };
}

self.onmessage = async (ev) => {
  const { id, cmd } = ev.data, a = ev.data;
  // Out-of-band: arrives while a simulate handler is parked at its inter-chunk
  // `await`, so it just raises the flag (no reply; the sim replies {cancelled:true}).
  if (cmd === 'cancelSim') { simCancel = true; return; }
  // May arrive before `init`: the export is unreachable until the module is up.
  if (cmd === 'setDriver') { driverMode = a.mode; if (inited) omc_set_inwasm_driver(a.mode); return; }
  const status = (text) => self.postMessage({ type: 'status', id, text });
  const wlog = (text) => self.postMessage({ type: 'log', id, text });
  _plog = wlog;
  const _t0 = performance.now();
  const reply = (result, transfer) => {
    wlog('⏱ ' + cmd + (a.name ? ' ' + a.name : '') + ' ' + (performance.now() - _t0).toFixed(1) + 'ms');
    self.postMessage({ type: 'reply', id, ok: true, result }, transfer || []);
  };
  if (PROF) wlog('cmd ' + cmd + (a.name ? ' ' + a.name : ''));
  try {
    switch (cmd) {
      case 'init': {
        await init();
        omc_set_env('OPENMODELICAHOME', '/usr');
        if (!omc_init()) throw new Error('omc_init() failed');
        inited = true;
        if (driverMode !== null) omc_set_inwasm_driver(driverMode);
        // Emit the MultiBody visualization scene (<model>_visual.xml) for every
        // simulation, so any model with animatable shapes shows a 3D view by
        // default. copyClass'd library examples carry no annotation of their own,
        // so this API call is how the option gets set (models may still opt in via
        // annotation(__OpenModelica_commandLineOptions="-d=visxml")).
        omc_eval('setCommandLineOptions("-d=visxml")');
        reply({ ok: true, version: omc_eval('getVersion()') });
        break;
      }
      case 'warmup': {
        // Tier up the engine's backend/codegen paths and compile the wasm-jit
        // runtime module once, off the critical path, by simulating a trivial
        // throwaway model. Makes this worker's first real simulate warm.
        oeval('loadString("model __Warmup Real x(start=0); equation der(x)=1; end __Warmup;")');
        oeval('simulate(__Warmup, stopTime=1.0)');
        oeval('deleteClass(__Warmup)');
        reply({ ok: true });
        break;
      }
      case 'installMSL': {
        await evalWithDownloads('installPackage(Modelica)', status);
        status('Loading Modelica library…');
        await evalWithDownloads('loadModel(Modelica)', status);   // into the symbol table (list/simulate by name)
        reply({ ok: true, message: omc_eval('getErrorString()').trim() });
        break;
      }
      case 'loadSource': {
        // Load model *text* via loadString (NOT the omc loadModel builtin, which
        // loads a library from disk). Never clear(): the MSL worker must keep its
        // library; loadString redefines a same-named class so edits don't accumulate.
        const loaded = (await evalWithDownloads(`loadString("${esc(a.text)}")`, status)).trim();
        if (PROF) wlog('loadString -> ' + loaded);
        if (loaded !== 'true') return reply(simError('Could not parse the model.'));
        const name = a.name || lastClassName();
        if (!name) return reply({ ok: false, error: 'No class found in the model text.' });
        if (PROF) wlog('model name = ' + name);
        // figures/doc are annotations — return them here so the page can show docs
        // before the (slower) simulation runs. Settings come from simulate itself.
        reply({ ok: true, name, figures: figuresFor(name), doc: documentationFor(name) });
        break;
      }
      case 'copyClass': {
        // A true, self-contained top-level copy of a library class (fully-qualified
        // refs) — editable without touching the library. It owns the copied
        // figures/doc annotations, so those come from the copy itself.
        if ((await evalWithDownloads(`copyClass(${a.from}, "${a.name}")`, status)).trim() !== 'true')
          return reply(simError('copyClass failed for ' + a.from));
        // Optionally curate the plots via a figures annotation the library class
        // lacks. addClassAnnotation replaces the whole Documentation annotation,
        // so re-inject the class's existing info alongside the figures to keep the
        // model's own documentation intact.
        if (a.figures) {
          let infoAttr = '';
          try {
            const arr = JSON.parse(withJsonDump(() => oeval(`getDocumentationAnnotation(${a.name})`)));
            const info = Array.isArray(arr) ? (arr[0] || '') : '';
            if (info) infoAttr = `info="${esc(info)}", `;
          } catch (_) {}
          const annotate = `Documentation(${infoAttr}figures={${a.figures}})`;
          if (omc_eval(`addClassAnnotation(${a.name}, annotate=${annotate})`).trim() !== 'true')
            wlog('addClassAnnotation failed: ' + omc_eval('getErrorString()').trim());
        }
        reply({ ok: true, name: a.name, source: omc_eval(`list(${a.name})`),
                figures: figuresFor(a.name), doc: documentationFor(a.name) });
        break;
      }
      case 'simulate': {
        // buildModel (translate + JIT, bakes the settings) then runResumable (a
        // cancellable chunked run + `.mat`). Omitted args use the experiment annotation.
        const opts = [];
        if (a.stopTime) opts.push(`stopTime=${a.stopTime}`);
        if (a.intervals) opts.push(`numberOfIntervals=${a.intervals}`);
        if (a.tolerance) opts.push(`tolerance=${a.tolerance}`);
        if (a.method) opts.push(`method="${a.method}"`);
        const _tb = performance.now();
        const built = (await evalWithDownloads(`buildModel(${a.name}${opts.length ? ',' + opts.join(',') : ''})`, status)).trim();
        const buildMs = performance.now() - _tb;
        // buildModel → {"<prefix>","<initfile>"}; an empty first element means it failed.
        if (!/^\{\s*"[^"]/.test(built)) return reply(simError('Build failed.'));
        const _ts = performance.now();
        const st = await runResumable(a.name, a.override || '', status);
        const simMs = performance.now() - _ts;
        if (st === 3) return reply({ ok: false, cancelled: true });
        if (st < 0) return reply(simError('Simulation failed.'));
        const s = snapshot();
        if (!s) return reply(simError('Simulation produced no result.'));
        s.snap.options = simOptions(a.name, a);  // settings actually used → seed the dialog
        s.snap.timing = { buildMs, simMs };
        reply(s.snap, s.transfer);               // figures/doc come from loadSource/copyClass
        break;
      }
      case 'resimulate': {
        // Re-run the already-built model (no rebuild) — same cancellable chunked path.
        const _ts = performance.now();
        const st = await runResumable(a.name, a.override || '', status);
        const simMs = performance.now() - _ts;
        if (st === 3) return reply({ ok: false, cancelled: true });
        if (st < 0) return reply(simError('Re-simulation failed.'));
        const s = snapshot();
        if (!s) return reply(simError('Re-simulation produced no result.'));
        s.snap.timing = { buildMs: 0, simMs };
        reply(s.snap, s.transfer);
        break;
      }
      case 'anim': {
        // MultiBody animation for the last run: the shape scene (present only if
        // the model enabled `-d=visxml`, e.g. via __OpenModelica_commandLineOptions)
        // plus the flat per-frame transform buffer the JS renderer plays back.
        const scene = omc_anim_scene();
        if (!scene || !scene.shapes || !scene.shapes.length) { reply({ available: false }); break; }
        const times = omc_sim_time();
        const data = omc_anim_all_frames();
        if (!times || !data) { reply({ available: false }); break; }
        const transfer = [times.buffer, data.buffer];
        // Load real geometry for CAD shapes (dxf): resolve the modelica:// URI to
        // a VFS file and parse it (in Rust) into a triangle mesh the client renders.
        for (const s of scene.shapes) {
          if (s.kind !== 9 || !/\.dxf$/i.test(s.type || '')) continue;   // 9 = ShapeKind::Cad
          try {
            const path = unquote(omc_eval(`uriToFilename("${esc(s.type)}")`));
            const bytes = path && wasiReadFile(path);
            if (!bytes) continue;
            const mesh = omc_dxf_mesh(new TextDecoder().decode(bytes));
            if (mesh && mesh.positions && mesh.positions.length) {
              s.mesh = mesh;
              transfer.push(mesh.positions.buffer, mesh.normals.buffer, mesh.colors.buffer);
            }
          } catch (e) { wlog('dxf load failed for ' + s.type + ': ' + e); }
        }
        reply({ available: true, scene, times, data, stride: omc_anim_stride() }, transfer);
        break;
      }
      case 'eval':
        reply(await evalWithDownloads(a.src, status));
        break;
      default:
        throw new Error('unknown command: ' + cmd);
    }
  } catch (e) {
    wlog('EXCEPTION in ' + cmd + ': ' + (e && e.message || e));
    self.postMessage({ type: 'reply', id, ok: false, error: '' + (e && e.message || e) });
  }
};
