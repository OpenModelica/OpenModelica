// OMShell omc Web Worker.
//
// On wasm the omc compiler is a *separate* wasm module (built from
// libopenmodelica_compiler, `web` target) that exports omc_init/omc_eval/
// omc_set_env (see libopenmodelica_compiler/src/wasm_api.rs). Running it on the
// UI thread froze the page for the duration of every command, so it is hosted
// here instead: a dedicated module Worker that the GUI talks to via postMessage
// (see omshell_core::driver, wasm). The UI thread stays free, so the spinner
// animates and input keeps responding while omc works.
//
// The build stages this file at the web root next to the omc module, so the
// `./omc/` import below resolves regardless of which OMShell page loads it.
//
// Downloads: omc_eval is synchronous and cannot await a fetch, so a command that
// needs a file (installPackage, updatePackageIndex, ...) does not fetch it
// itself — Curl_wasm records the missing file as "pending" and the command fails.
// evalWithDownloads() drains that pending list (omc_take_pending_downloads),
// fetches each file here with a streaming reader (posting {progress} so the GUI
// can show a real download bar), stages the bytes in the store (wasi_write_file), and
// re-runs the command, which now finds them. This needs no SharedArrayBuffer /
// cross-origin isolation. See openmodelica_script_util/src/Curl_wasm.rs.
//
// The init/version orchestration mirrors the omshell_omc native backend
// (init_session / eval_with_errors in lib.rs); keep the two in step.
import init, {
  omc_init,
  omc_eval,
  omc_set_env,
  wasi_path_open,
  wasi_fd_read,
  wasi_fd_close,
  wasi_path_filestat_get,
  wasi_readdir,
  wasi_write_file,
  omc_take_pending_downloads,
  omc_take_plot_commands,
} from "./omc/OpenModelicaCompiler.js";
// omc_abi exists only when the omc module is built with `scripting_api` (the
// OMEdit web client). A named import of a missing export would break the worker
// for OMShell/OMNotebook, so reach it through the namespace and feature-detect it.
import * as OmcModule from "./omc/OpenModelicaCompiler.js";

// Self-ID so a page console shows which omc_worker.js loaded (cache diagnosis).
console.log("omc_worker.js loaded (WASI file surface)");

// Read a whole file from the worker store through the WASI preview1 flow
// (path_open → fd_read → fd_close). Returns a Uint8Array or undefined if absent.
function wasiReadFile(path) {
  const fd = wasi_path_open(path);
  if (fd < 0) return undefined;
  try {
    return wasi_fd_read(fd) || undefined;
  } finally {
    wasi_fd_close(fd);
  }
}

// Instantiate the omc wasm module once. omc_set_env mirrors the old host page:
// builtins resolve by basename, so OPENMODELICAHOME only needs to be non-empty.
const ready = (async () => {
  await init();
  omc_set_env("OPENMODELICAHOME", "/usr");
})();

const trim = (s) => (s ?? "").trim();
const unquote = (s) => s.replace(/^"+|"+$/g, "");

// Mirrors omshell_omc's trims: result is just trimmed; diagnostics and the
// version string also have their surrounding quotes stripped.
const cleanError = (s) => trim(unquote(trim(s)));

// Stream one URL into a Uint8Array, posting {progress} as bytes arrive. `total`
// is 0 when the server sends no Content-Length (indeterminate bar).
async function fetchWithProgress(url, label) {
  const resp = await fetch(url);
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
  const total = Number(resp.headers.get("content-length")) || 0;
  const reader = resp.body.getReader();
  const chunks = [];
  let received = 0;
  self.postMessage({ kind: "progress", file: label, done: 0, total });
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    received += value.length;
    self.postMessage({ kind: "progress", file: label, done: received, total });
  }
  const out = new Uint8Array(received);
  let off = 0;
  for (const c of chunks) {
    out.set(c, off);
    off += c.length;
  }
  return out;
}

// Fetch one pending file into the VFS, trying its mirrors in order. A file that
// no mirror serves is left absent: the command's re-run then reports the real
// download failure to the user.
async function fetchToVfs(urls, filename) {
  const label = filename.split("/").pop() || filename;
  for (const url of urls) {
    try {
      const bytes = await fetchWithProgress(url, label);
      wasi_write_file(filename, bytes);
      return;
    } catch (_) {
      // try the next mirror
    }
  }
}

// Run `src`, then satisfy any downloads it requested and run it again, until it
// needs nothing new. `attempted` stops an undownloadable file from looping
// forever (the file stays absent, so the final run surfaces omc's own error).
async function evalWithDownloads(src) {
  const attempted = new Set();
  for (;;) {
    const result = omc_eval(src);
    const pending = omc_take_pending_downloads() || [];
    const todo = pending.filter((p) => !attempted.has(p.filename));
    if (todo.length === 0) return result;
    omc_eval("getErrorString()"); // discard the aborted run's diagnostics
    omc_take_plot_commands(); // and any plots it recorded before aborting
    for (const item of todo) {
      attempted.add(item.filename);
      await fetchToVfs(item.urls, item.filename);
    }
  }
}

// One typed OMEdit ABI call (JSON request -> JSON reply), draining downloads the
// call triggers (installPackage, loadModel deps) and retrying, like evalWithDownloads.
async function abiWithDownloads(request) {
  const attempted = new Set();
  for (;;) {
    const response = OmcModule.omc_abi(request);
    const pending = omc_take_pending_downloads() || [];
    const todo = pending.filter((p) => !attempted.has(p.filename));
    if (todo.length === 0) return response;
    omc_eval("getErrorString()"); // discard the aborted call's diagnostics
    omc_take_plot_commands(); // and any plots it recorded before aborting
    for (const item of todo) {
      attempted.add(item.filename);
      await fetchToVfs(item.urls, item.filename);
    }
  }
}

async function doInit(installMsl) {
  if (!omc_init()) {
    return { kind: "ready", ok: false, error: "omc_init() failed" };
  }
  // The browser omc has no pre-installed library, so install the MSL to make the
  // shell immediately usable. Best-effort: a failure (e.g. no network) only
  // surfaces its diagnostics, it does not stop the shell from starting. A client
  // that wants its window up first (OMShell-qt) passes installMsl=false and runs
  // installPackage(Modelica) itself as an ordinary command after it is visible.
  let message = "";
  if (installMsl) {
    await evalWithDownloads("installPackage(Modelica)");
    message = cleanError(omc_eval("getErrorString()"));
  }
  const version = unquote(trim(omc_eval("getVersion()")));
  return { kind: "ready", ok: true, version, message };
}

// Plot commands the eval recorded, each with the bytes of its result file from
// the VFS, plus the transferable buffers for postMessage. `args` is the 18
// PlotCallback strings (result file at [0]). Clients that don't plot ignore it.
function collectPlots() {
  const cmds = omc_take_plot_commands() || [];
  const plots = [];
  const transfer = [];
  for (const args of cmds) {
    const file = args[0] || "";
    const bytes = file ? wasiReadFile(file) : undefined;
    plots.push({ args, file, bytes });
    if (bytes) transfer.push(bytes.buffer);
  }
  return { plots, transfer };
}

async function doEval(src) {
  const result = trim(await evalWithDownloads(src));
  const error = cleanError(omc_eval("getErrorString()"));
  const { plots, transfer } = collectPlots();
  return {
    msg: { kind: "done", result, error, plots, keep: src.trim() !== "quit()" },
    transfer,
  };
}

self.onmessage = async (e) => {
  const msg = e.data;
  await ready;
  try {
    if (msg.cmd === "init") {
      self.postMessage(await doInit(msg.installMsl !== false));
    } else if (msg.cmd === "eval") {
      const { msg: reply, transfer } = await doEval(msg.src);
      // Transfer the result-file buffers (zero-copy) rather than clone them.
      self.postMessage(reply, transfer);
    } else if (msg.cmd === "abi") {
      // Typed OMEdit call. `id` correlates the reply with the page-side promise
      // (Module.omcAbiCall). `response` is the JSON string omc_abi_dispatch made.
      const response =
        typeof OmcModule.omc_abi === "function"
          ? await abiWithDownloads(msg.request)
          : JSON.stringify({ error: "omc_abi unavailable (omc built without the scripting_api feature)" });
      self.postMessage({ kind: "abiResult", id: msg.id, response });
    } else if (msg.cmd === "vfsGet") {
      // OMEdit reads some files (library index, install manifests, visual.xml)
      // on the main thread; omc wrote them into this worker's store, so read them
      // back through the WASI surface and hand the bytes to the page's file engine.
      let bytes;
      try { bytes = wasiReadFile(msg.path); } catch (e) { bytes = undefined; }
      const transfer = bytes ? [bytes.buffer] : [];
      self.postMessage({ kind: "vfsResult", id: msg.id, bytes: bytes || null }, transfer);
    } else if (msg.cmd === "vfsList") {
      // Directory enumeration for the page's QDir over worker-owned paths
      // (WASI fd_readdir). Returns [{ name, isDir }]; [] for a missing/empty dir.
      let entries;
      try { entries = wasi_readdir(msg.path) || []; } catch (e) { entries = []; }
      self.postMessage({ kind: "vfsListResult", id: msg.id, entries });
    } else if (msg.cmd === "vfsStat") {
      // WASI path_filestat_get's size (-1 if absent), for the file engine's size().
      let size;
      try { size = wasi_path_filestat_get(msg.path); } catch (e) { size = -1; }
      self.postMessage({ kind: "vfsStatResult", id: msg.id, size });
    }
  } catch (err) {
    // A trap inside omc must not silently wedge the shell: report it on the
    // channel the GUI is waiting on so it clears `busy`.
    if (msg.cmd === "init") {
      self.postMessage({ kind: "ready", ok: false, error: String(err) });
    } else if (msg.cmd === "abi") {
      self.postMessage({ kind: "abiResult", id: msg.id, response: JSON.stringify({ error: String(err) }) });
    } else {
      self.postMessage({ kind: "done", result: "", error: String(err), keep: true });
    }
  }
};
