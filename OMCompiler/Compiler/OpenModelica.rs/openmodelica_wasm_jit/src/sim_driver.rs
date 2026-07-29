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
pub fn init_host_hooks() {
    set_cancel_hook(metamodelica::cancel::check_cancel);
    set_assert_reporter(report_assert);
}
