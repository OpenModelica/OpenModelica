//! Hooks the embedding installs (web API): `SimStatus`, cancel, clock,
//! FMU AOT/loader sources, and the no-engine stubs of the session API.

use super::*;

/// Status of a resumable simulation session.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum SimStatus {
    /// More rows remain; call `sim_advance` again.
    Running,
    /// Reached `stopTime`; results captured, `.mat` written, session freed.
    Done,
    /// `terminate()` ended it early; results captured, session freed.
    Terminated,
    /// Cancelled; externals freed, session dropped, no results captured.
    Cancelled,
}

/// Request cancellation of the running simulation (native, cross-thread).
#[cfg(feature = "jit")]
pub fn request_cancel() {
    sim_driver::request_cancel();
}

#[cfg(not(feature = "jit"))]
pub fn request_cancel() {}

/// Install the wasm wall-clock (`performance.now`) for the chunk budget; wasm-only.
#[cfg(all(feature = "jit", target_arch = "wasm32"))]
pub fn set_clock(f: fn() -> f64) {
    sim_driver::set_clock(f);
}

/// Install a host cancel poll (a cross-thread `SharedArrayBuffer` flag read) so a
/// blocking wasm `simulate()` can be cancelled from another thread — OMEdit-wasm.
#[cfg(all(feature = "jit", target_arch = "wasm32"))]
pub fn set_cancel_poll(f: fn() -> bool) {
    sim_driver::set_cancel_poll(f);
}

/// Install the host's compiler for an FMU's native platforms, for an omc that
/// cannot link wasmtime in. `preload` is called as soon as an export is known to
/// need one, `compile` once the component is built.
#[cfg(any(not(feature = "fmu-native"), target_arch = "wasm32"))]
pub fn set_fmu_aot(
    compile: fn(&[u8], &str) -> core::result::Result<Vec<u8>, String>,
    preload: fn(),
) {
    native_fmu::set_aot_compiler(compile, preload);
}

/// Install the host's source for the FMU loader libraries, which a wasm omc does
/// not carry (they are files in the web bundle).
#[cfg(target_arch = "wasm32")]
pub fn set_fmu_loaders(fetch: fn(&str) -> Option<Vec<u8>>, platforms: Vec<String>) {
    native_fmu::set_loader_source(fetch, platforms);
}

#[cfg(not(feature = "jit"))]
pub fn sim_start(_prefix: &str, _result_file: &str, _simflags: &str) -> Result<()> {
    return Err("CodegenWasmJit: the wasm JIT engine is not built in (enable the `jit` feature)")
}

#[cfg(not(feature = "jit"))]
pub fn sim_advance(_budget_ms: f64) -> Result<SimStatus> {
    return Err("CodegenWasmJit: the wasm JIT engine is not built in (enable the `jit` feature)")
}

#[cfg(not(feature = "jit"))]
pub fn sim_free() {}

#[cfg(not(feature = "jit"))]
pub fn last_sim_log() -> String {
    String::new()
}
