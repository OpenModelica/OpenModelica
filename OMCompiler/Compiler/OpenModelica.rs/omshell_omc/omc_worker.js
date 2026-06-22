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
// can show a real download bar), stages the bytes in the VFS (omc_vfs_put), and
// re-runs the command, which now finds them. This needs no SharedArrayBuffer /
// cross-origin isolation. See openmodelica_script_util/src/Curl_wasm.rs.
//
// The init/version orchestration mirrors the omshell_omc native backend
// (init_session / eval_with_errors in lib.rs); keep the two in step.
import init, {
  omc_init,
  omc_eval,
  omc_set_env,
  omc_vfs_put,
  omc_take_pending_downloads,
} from "./omc/OpenModelicaCompiler.js";

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
      omc_vfs_put(filename, bytes);
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
    for (const item of todo) {
      attempted.add(item.filename);
      await fetchToVfs(item.urls, item.filename);
    }
  }
}

async function doInit() {
  if (!omc_init()) {
    return { kind: "ready", ok: false, error: "omc_init() failed" };
  }
  // The browser omc has no pre-installed library, so install the MSL to make the
  // shell immediately usable. Best-effort: a failure (e.g. no network) only
  // surfaces its diagnostics, it does not stop the shell from starting.
  await evalWithDownloads("installPackage(Modelica)");
  const message = cleanError(omc_eval("getErrorString()"));
  const version = unquote(trim(omc_eval("getVersion()")));
  return { kind: "ready", ok: true, version, message };
}

async function doEval(src) {
  const result = trim(await evalWithDownloads(src));
  const error = cleanError(omc_eval("getErrorString()"));
  return { kind: "done", result, error, keep: src.trim() !== "quit()" };
}

self.onmessage = async (e) => {
  const msg = e.data;
  await ready;
  try {
    if (msg.cmd === "init") {
      self.postMessage(await doInit());
    } else if (msg.cmd === "eval") {
      self.postMessage(await doEval(msg.src));
    }
  } catch (err) {
    // A trap inside omc must not silently wedge the shell: report it on the
    // channel the GUI is waiting on so it clears `busy`.
    if (msg.cmd === "init") {
      self.postMessage({ kind: "ready", ok: false, error: String(err) });
    } else {
      self.postMessage({ kind: "done", result: "", error: String(err), keep: true });
    }
  }
};
