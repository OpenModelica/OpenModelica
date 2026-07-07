//! `libOpenModelicaCompiler.so` — the C ABI OMEdit links against to drive the
//! Rust omc in-process.
//!
//! This exposes the same interactive command/response protocol used over
//! ZeroMQ, but through direct function calls: initialise the runtime once with
//! [`omc_compiler_init`], then evaluate command strings with
//! [`omc_compiler_eval`]. The implementation is a thin C wrapper over the safe
//! [`openmodelica_backend_main::capi`] embedding API.
//!
//! ## Contract
//! * Call [`omc_compiler_init`] exactly once, before any [`omc_compiler_eval`].
//! * All calls must come from the **same thread** (the compiler keeps
//!   per-thread state), and that thread should have a large stack (several MiB)
//!   — see the note in [`openmodelica_backend_main::capi`].
//! * Strings returned by [`omc_compiler_eval`] are owned by the caller and must
//!   be released with [`omc_compiler_free_string`].
//! * No Rust panic is allowed to cross the FFI boundary; every entry point
//!   traps unwinding and reports failure instead.
//!
//! The typed `OMCInterface` (generated `OpenModelicaScriptingAPIQt.cpp`) that
//! OMEdit also uses is a future layer built on top of this string interface;
//! see the design notes accompanying this crate.

use arcstr::ArcStr;
use openmodelica_backend_main::capi;
use std::ffi::{CStr, CString, c_char, c_int};
use std::panic::{AssertUnwindSafe, catch_unwind};

// MetaModelica-ABI compatibility shims (`omc_Main_init` / `omc_Main_handleCommand`
// / GC + Windows no-ops) OMEdit links against. Implemented over the embedding ABI
// below; the `#[no_mangle]` entry points are exported from this cdylib directly.
// OMEdit is a native C++ host (malloc/free/strdup/FILE), so these shims and the
// SimulationRuntime C ABI below are native-only; a wasm build of this cdylib
// targets a JS host and exposes the init/eval entry points instead.
#[cfg(not(target_arch = "wasm32"))]
mod mmc_compat;

// JavaScript (wasm-bindgen) bindings: the string-to-string command interface a
// browser/Node host calls instead of the native C ABI above.
#[cfg(target_arch = "wasm32")]
mod wasm_api;

// Renders `plot(...)` output as an SVG chart (charton) into the page; registered
// with the System plot-callback registry at init.
#[cfg(target_arch = "wasm32")]
mod wasm_plot;

// SimulationRuntime metadata tables OMEdit reads (FLAG_*, *_METHOD_*,
// OMC_LOG_STREAM_*); generated from the C runtime by gen/gen-sim-tables.sh so
// OMEdit needs no OpenModelica C runtime library for them.
mod sim_metadata;

// The rest of the SimulationRuntime C ABI OMEdit uses (result-file readers, the
// realtime clock, ryu number formatting), backed by the Rust port so OMEdit
// needs no OpenModelica C runtime library. The `#[no_mangle]` symbols are
// exported from this cdylib directly.
#[cfg(not(target_arch = "wasm32"))]
mod omedit_runtime;

// Re-export the generated typed OMEdit interface ABI (the `extern "C"` wrappers
// behind OpenModelicaScriptingAPIQt, in the `openmodelica_scripting_qt` crate).
// The `pub use` makes the `#[no_mangle]` symbols reachable from this cdylib's
// crate root so the linker keeps them in `libOpenModelicaCompiler.so` (an rlib's
// `#[no_mangle]` items are otherwise liable to be dropped if nothing references
// them). OMEdit-specific, so native-only and behind the `scripting_api` feature
// (the generated OMEdit ABI crate is dropped from builds that don't ship it).
#[cfg(all(not(target_arch = "wasm32"), feature = "scripting_api"))]
pub use openmodelica_scripting_qt::scripting_api_qt::*;

// Re-export the plot/loadModel callback registration entry points (implemented
// in `openmodelica_util::System`) for the same reason — OMEdit registers its
// callbacks through these so omc can drive plot windows / model loading.
pub use openmodelica_util::System::{omc_set_loadmodel_callback, omc_set_plot_callback};

// Re-export the in-memory model-instance reference C ABI (issue #15219):
// `ModelInstanceReference_get`/`_release` plus the `omc_json_*` walker that
// OMEdit uses to read a model instance's boxed JSON value directly in-process,
// avoiding JSON string (de)serialisation. Same `pub use` rationale as above —
// keep the `#[no_mangle]` symbols in `libOpenModelicaCompiler.so`.
pub use openmodelica_backend_main::ModelInstanceReference::*;

/// Run the standalone `omc` command-line interface and return its process exit
/// code (`0` on success, `1` on a failed MetaModelica execution or a panic).
///
/// This is the entry point the thin `openmodelica` launcher binary calls: the
/// launcher dynamically links `libOpenModelicaCompiler.so` and forwards its
/// argv here instead of statically linking the whole compiler, so the compiler
/// code lives in exactly one place — this shared library — shared by both the
/// CLI and OMEdit (which previously meant two ~400 MB copies of identical code).
///
/// `argv`/`argc` are the raw process arguments *including* `argv[0]`; the
/// program name is skipped here, matching `std::env::args().skip(1)` in a normal
/// `main`. The caller must run this on a thread with a large stack (several MiB)
/// — the launcher does, see the threading note in [`mod@capi`]. Null entries are
/// skipped; a null `argv` (with `argc > 0`) is treated as no arguments.
#[cfg(not(target_arch = "wasm32"))]
#[unsafe(no_mangle)]
pub extern "C" fn omc_cli_run(argc: c_int, argv: *const *const c_char) -> c_int {
    use std::io::Write;
    let args: Vec<ArcStr> = if argv.is_null() || argc <= 0 {
        Vec::new()
    } else {
        // Skip argv[0] (the program name), mirroring `args().skip(1)`.
        (1..argc as isize)
            .filter_map(|i| {
                // SAFETY: caller guarantees `argv` holds `argc` valid (or null)
                // NUL-terminated C strings.
                let p = unsafe { *argv.offset(i) };
                if p.is_null() {
                    None
                } else {
                    let bytes = unsafe { CStr::from_ptr(p) }.to_bytes();
                    Some(ArcStr::from(String::from_utf8_lossy(bytes)))
                }
            })
            .collect()
    };
    let arglist = std::sync::Arc::new(args.into_iter().collect());
    match catch_unwind(AssertUnwindSafe(|| openmodelica_backend_main::Main::main(arglist))) {
        Ok(Ok(())) => 0,
        // Mirror the launcher's old inline `run()`: flush stdout, report on
        // stderr and exit 1. The MetaModelica exception carries no payload worth
        // printing — diagnostics were already emitted via the Error buffer.
        Ok(Err(_)) | Err(_) => {
            let _ = std::io::stdout().flush();
            eprintln!("Execution failed!");
            1
        }
    }
}

/// Initialise the compiler runtime on the calling thread.
///
/// Returns `0` on success and `-1` on failure (initialisation error or a
/// panic). The installation directory is taken from the `OPENMODELICAHOME`
/// environment variable, as in a normal omc startup. No command-line flags are
/// passed; use [`omc_compiler_init_args`] to forward flags (e.g. `+locale=…`).
#[unsafe(no_mangle)]
pub extern "C" fn omc_compiler_init() -> c_int {
    match catch_unwind(|| capi::init(&[])) {
        Ok(Ok(())) => 0,
        Ok(Err(_)) | Err(_) => -1,
    }
}

/// Like [`omc_compiler_init`] but forwarding the command-line arguments the
/// embedder wants applied (`argv[0..argc]`, without the executable name), the
/// same list `omc_Main_init` receives in a normal startup — e.g. `+locale=sv_SE`.
/// Returns `0` on success, `-1` on failure or panic. Null/`argc <= 0` behaves
/// like [`omc_compiler_init`].
#[unsafe(no_mangle)]
pub extern "C" fn omc_compiler_init_args(argv: *const *const c_char, argc: c_int) -> c_int {
    let args: Vec<ArcStr> = if argv.is_null() || argc <= 0 {
        Vec::new()
    } else {
        (0..argc as isize)
            .filter_map(|i| {
                // SAFETY: caller guarantees `argv` holds `argc` valid (or null)
                // NUL-terminated C strings.
                let p = unsafe { *argv.offset(i) };
                if p.is_null() {
                    None
                } else {
                    let bytes = unsafe { CStr::from_ptr(p) }.to_bytes();
                    Some(ArcStr::from(String::from_utf8_lossy(bytes)))
                }
            })
            .collect()
    };
    match catch_unwind(AssertUnwindSafe(|| capi::init(&args))) {
        Ok(Ok(())) => 0,
        Ok(Err(_)) | Err(_) => -1,
    }
}

/// Evaluate one interactive command string and return its reply.
///
/// `command` must be a non-null, NUL-terminated UTF-8 string. The returned
/// pointer is a newly-allocated NUL-terminated C string owned by the caller
/// (free it with [`omc_compiler_free_string`]). Returns null only if `command`
/// is null or evaluation traps; a normal evaluation error is reported through
/// the reply string itself (the same way the interactive server does).
#[unsafe(no_mangle)]
pub extern "C" fn omc_compiler_eval(command: *const c_char) -> *mut c_char {
    omc_compiler_eval_keep(command, std::ptr::null_mut())
}

/// Like [`omc_compiler_eval`] but also reports whether the session should keep
/// running: `*keep_running` is set to 0 after `quit()` and 1 otherwise (mirroring
/// `omc_Main_handleCommand`'s boolean result). `keep_running` may be null.
#[unsafe(no_mangle)]
pub extern "C" fn omc_compiler_eval_keep(
    command: *const c_char,
    keep_running: *mut c_int,
) -> *mut c_char {
    if !keep_running.is_null() {
        unsafe { *keep_running = 1 };
    }
    if command.is_null() {
        return std::ptr::null_mut();
    }
    // SAFETY: the contract requires a valid NUL-terminated string.
    let cmd_bytes = unsafe { CStr::from_ptr(command) }.to_bytes();
    let cmd = ArcStr::from(String::from_utf8_lossy(cmd_bytes));

    let (keep, reply) = match catch_unwind(AssertUnwindSafe(|| capi::eval(cmd))) {
        Ok(Ok((keep, reply))) => (keep, reply),
        // Evaluation failure: surface the error text rather than a bare null so
        // the embedder gets a diagnostic, matching omc's interactive behaviour.
        Ok(Err(e)) => (true, ArcStr::from(format!("Error: {e}"))),
        Err(_) => return std::ptr::null_mut(),
    };
    if !keep_running.is_null() {
        unsafe { *keep_running = if keep { 1 } else { 0 } };
    }

    // NUL bytes cannot appear in a C string; replace any (there should be none
    // in a textual reply) so construction cannot fail.
    match CString::new(reply.as_bytes()) {
        Ok(c) => c.into_raw(),
        Err(_) => {
            let sanitized: Vec<u8> = reply.as_bytes().iter().copied().filter(|&b| b != 0).collect();
            CString::new(sanitized).unwrap().into_raw()
        }
    }
}

/// Free a string previously returned by [`omc_compiler_eval`].
#[unsafe(no_mangle)]
pub extern "C" fn omc_compiler_free_string(s: *mut c_char) {
    if !s.is_null() {
        // SAFETY: `s` was produced by `CString::into_raw` in this module.
        unsafe {
            drop(CString::from_raw(s));
        }
    }
}
