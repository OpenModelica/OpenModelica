//! Reaching [`openmodelica_sim_meta::omclog`] from inside the runtime module.
//!
//! The nonlinear solver runs in wasm whichever driver owns the run, so its lines
//! have to leave it: with `host_log`, `rt_host_log` hands them to the host, which
//! writes them to the stdout the model's `print` and the driver's own lines share,
//! keeping call order. The standalone module has no host and writes its own stdout.
//! A build with neither installs no sink of its own — the FMI3 adapter has a host
//! logger but no `env` to import from, and sets [`driver::set_log_sink`] itself.
//!
//! The per-stream indentation stays module-local. That is exact as long as no line
//! from outside lands inside a block, which holds: a `rt_solve_nls` call closes
//! every block it opens and the host driver does not print during it.

pub use openmodelica_sim_meta::omclog::*;

#[cfg(all(target_arch = "wasm32", feature = "host_log", not(feature = "standalone")))]
#[link(wasm_import_module = "env")]
unsafe extern "C" {
    /// The host's stdout: `len` bytes of UTF-8 at `ptr` in this module's memory.
    fn rt_host_log(ptr: u32, len: u32);
}

#[cfg(all(target_arch = "wasm32", feature = "host_log", not(feature = "standalone")))]
pub(crate) fn sink(_stream: Stream, _ty: LogType, s: &str) {
    unsafe { rt_host_log(s.as_ptr() as u32, s.len() as u32) };
}

#[cfg(all(target_arch = "wasm32", not(feature = "host_log"), not(feature = "standalone")))]
pub(crate) fn sink(_stream: Stream, _ty: LogType, _s: &str) {}

#[cfg(all(target_arch = "wasm32", feature = "standalone"))]
pub(crate) fn sink(_stream: Stream, _ty: LogType, s: &str) {
    use std::io::Write;
    let mut out = std::io::stdout();
    let _ = out.write_all(s.as_bytes());
    let _ = out.flush();
}

/// Install the run's active streams and route the module's log lines out: the
/// counterpart of `rt_set_solvers`, since this build has no flag store of its own.
/// The in-wasm session sets the mask from its own argv and calls this for the sink.
#[cfg(target_arch = "wasm32")]
#[unsafe(no_mangle)]
pub extern "C" fn rt_set_log_streams(lo: u32, hi: u32) {
    openmodelica_sim_meta::driver::set_log_sink(sink);
    set_mask(((hi as Mask) << 32) | lo as Mask);
}
