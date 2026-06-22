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
// This mirrors the omshell_omc native backend's orchestration (init_session /
// eval_with_errors in lib.rs); keep the two in step.
import init, { omc_init, omc_eval, omc_set_env } from "./omc/OpenModelicaCompiler.js";

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

function doInit() {
  if (!omc_init()) {
    return { kind: "ready", ok: false, error: "omc_init() failed" };
  }
  // The browser omc has no pre-installed library, so install the MSL to make the
  // shell immediately usable. Best-effort: a failure (e.g. no network) only
  // surfaces its diagnostics, it does not stop the shell from starting.
  omc_eval("installPackage(Modelica)");
  const message = cleanError(omc_eval("getErrorString()"));
  const version = unquote(trim(omc_eval("getVersion()")));
  return { kind: "ready", ok: true, version, message };
}

function doEval(src) {
  const result = trim(omc_eval(src));
  const error = cleanError(omc_eval("getErrorString()"));
  return { kind: "done", result, error, keep: src.trim() !== "quit()" };
}

self.onmessage = async (e) => {
  const msg = e.data;
  await ready;
  try {
    if (msg.cmd === "init") {
      self.postMessage(doInit());
    } else if (msg.cmd === "eval") {
      self.postMessage(doEval(msg.src));
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
