// Bridge between the omshell_omc wasm backend and the omc wasm module.
//
// The compiler is a *separate* wasm module (built from libopenmodelica_compiler
// by OpenModelica.rs/wasm/build.sh, `web` target). That module exports
// `omc_init()`/`omc_eval()` (see libopenmodelica_compiler/src/wasm_api.rs) but
// must be instantiated asynchronously, which cannot happen inside this
// synchronous backend. The host page therefore initialises the omc module once
// and publishes its exports on `globalThis.__omc` before starting the GUI:
//
//   import init, { omc_init, omc_eval, omc_set_env }
//     from "./pkg-web/OpenModelicaCompiler.js";
//   await init();
//   globalThis.__omc = { omc_init, omc_eval, omc_set_env };
//   // ... then start the OMShell GUI (trunk-built omshell_egui) ...
//
// These thin wrappers forward to that global, keeping the Rust↔JS boundary
// purely synchronous string-in/string-out.

export function omc_init() {
  return globalThis.__omc.omc_init();
}

export function omc_eval(command) {
  return globalThis.__omc.omc_eval(command);
}
