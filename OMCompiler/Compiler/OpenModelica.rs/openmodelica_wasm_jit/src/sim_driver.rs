//! Host-side facade over the engine-independent simulation driver.
//!
//! The driver itself now lives in `openmodelica_sim_meta::driver` so the exact
//! same code compiles into the in-wasm runtime (where the model's `functionODE`
//! etc. are reached via `call_indirect`, wasm→wasm). This module re-exports it and
//! wires the two host-only concerns the `no_std` driver can't own: the cancel
//! lifecycle (`metamodelica::cancel`) and routing a model `assert()` failure into
//! the compiler error buffer.

pub use openmodelica_sim_meta::driver::*;

// Cancel lifecycle stays with the shared `metamodelica::cancel` flag (the
// frontend/loader/backend flip the same one); the driver only polls it, via the
// hook installed in [`init_host_hooks`]. These re-exports keep the existing
// `CodegenWasmJit::{request_cancel,clear_cancel,set_cancel_poll}` callers working.
pub use metamodelica::cancel::{clear_cancel, request_cancel};
#[cfg(target_arch = "wasm32")]
pub use metamodelica::cancel::set_cancel_poll;

/// Route a model `assert()` failure (decoded by the driver) into the compiler
/// error buffer, matching the C target's `[file:l:c] Error: <msg>` so OMEdit
/// shows it.
fn report_assert(info: &AssertInfo) {
    let src = metamodelica::SourceInfo {
        fileName: arcstr::ArcStr::from(info.file.as_str()),
        isReadOnly: info.read_only,
        lineNumberStart: info.line_start,
        columnNumberStart: info.col_start,
        lineNumberEnd: info.line_end,
        columnNumberEnd: info.col_end,
        lastModification: metamodelica::OrderedFloat(0.0),
    };
    let _ = openmodelica_util::Error::addSourceMessage(
        openmodelica_util::Error::COMPILER_ERROR.clone(),
        metamodelica::cons(arcstr::ArcStr::from(info.msg.as_str()), metamodelica::nil()),
        src,
    );
}

/// Install the host hooks (cancel poll + assertion reporter) into the shared
/// driver. Idempotent; call before entering the driver.
/// The driver's log lines join the model's captured stdout, so the run's log has
/// them in the order they happened.
/// A real stdout takes the line as formatted; the stream and type are already in
/// its header columns.
fn log_to_stdout(
    _stream: openmodelica_sim_meta::omclog::Stream,
    _ty: openmodelica_sim_meta::omclog::LogType,
    s: &str,
) {
    openmodelica_wasi::wasi::stdout_write(s.as_bytes());
}

/// C's `OpenModelica_uriToFilename`, which `-reconcile`'s input files may use.
fn uri_to_filename(uri: &str) -> String {
    match metamodelica::uriToFilename(arcstr::ArcStr::from(uri)) {
        Ok(path) => path.to_string(),
        Err(_) => uri.to_string(),
    }
}

/// The files a run writes beside its result go where every other file the omc
/// build writes goes: real files natively, the in-memory store in the web build.
fn write_side_file(path: &str, bytes: &[u8]) -> bool {
    openmodelica_wasi::fs::write(path, bytes).is_ok()
}

/// C's `time(NULL)`, for the `+profiling` report's `<date>`. The same clock the
/// store stamps files with — `std::time::SystemTime::now()` panics in the web
/// build.
fn wall_clock_secs() -> i64 {
    (openmodelica_wasi::realtime_nanos() / 1_000_000_000) as i64
}

/// C's `simulationInfo->OPENMODELICAHOME`, which the `+profiling` report needs for
/// `default_profiling.xsl`: omc's own installation root, not the environment's.
fn openmodelica_home() -> Option<String> {
    openmodelica_util::Settings::getInstallationDirectoryPath().ok().map(|h| h.to_string())
}

pub fn init_host_hooks() {
    set_cancel_hook(metamodelica::cancel::check_cancel);
    openmodelica_sim_meta::files::set_writer(write_side_file);
    openmodelica_sim_meta::profiling::set_wall_clock(wall_clock_secs);
    openmodelica_sim_meta::profiling::set_home(openmodelica_home);
    openmodelica_sim_meta::driver::set_uri_resolver(uri_to_filename);
    openmodelica_sim_meta::driver::set_log_sink(log_to_stdout);
    set_assert_reporter(report_assert);
    // The host driver shares this process with `rt_assert`, so it sets the flag
    // directly; the in-wasm driver relays it over a host import.
    openmodelica_sim_meta::driver::set_no_throw_hook(crate::host::set_no_throw_asserts);
}
