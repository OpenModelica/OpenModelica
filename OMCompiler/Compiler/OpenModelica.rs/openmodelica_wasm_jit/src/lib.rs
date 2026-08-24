//! Host-side wasm-jit execution engine for OpenModelica.

// Embedded wasm artifacts built by `build.rs`, used by this crate's engines and
// the codegen crate (standalone/FMU emission).
pub static RUNTIME_WASM: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/runtime.wasm"));
pub static RUNTIME_WASIP1: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/runtime_wasip1.wasm"));
/// The interactive `wasm32-wasip1` (std) runtime: exports `rt_*`+`memory`+table
/// like `RUNTIME_WASM`, but built with std so the sparse solver (`rsparse`) links
/// in; imports `wasi_snapshot_preview1` (satisfied by `wasi_shim`). Empty when the
/// wasip1 target was unavailable at build time (host then uses `RUNTIME_WASM`).
pub static RUNTIME_WASM_INTERACTIVE_WASIP1: &[u8] =
    include_bytes!(concat!(env!("OUT_DIR"), "/runtime_wasip1_interactive.wasm"));
pub static EXTERNAL_C_WASM: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/modelicaexternalc.wasm"));
pub static FMI3_ME_ADAPTER: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/fmi3_me_adapter.wasm"));
pub static FMI3_CS_ADAPTER: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/fmi3_cs_adapter.wasm"));
pub static FMI3_MECS_ADAPTER: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/fmi3_mecs_adapter.wasm"));

/// The same two worlds with CVODE/IDA in the embedded driver, for an FMU exported with
/// `method="cvode"`/`"ida"`; the calls are imports
/// `openmodelica_wasi_libc::SUNDIALS_DYLINK` resolves.
pub static FMI3_CS_SUNDIALS_ADAPTER: &[u8] =
    include_bytes!(concat!(env!("OUT_DIR"), "/fmi3_cs_sundials_adapter.wasm"));
pub static FMI3_MECS_SUNDIALS_ADAPTER: &[u8] =
    include_bytes!(concat!(env!("OUT_DIR"), "/fmi3_mecs_sundials_adapter.wasm"));

/// Whether the wasip1 runtimes above have the real SUNDIALS/KLU linked in (the
/// build script cross-compiled the archives), so a `-lss=klu` run can be served.
pub const SUNDIALS: bool = cfg!(sundials);

pub mod sig;
pub mod model;
pub mod dylink;

// A wasm trap collapses to the crate's `&'static str` error on the way out of the
// engine, losing the trap kind and the backtrace. The engine parks its message
// here for the caller that gives up on the run to add to the Error buffer.
std::thread_local! {
    static ENGINE_ERROR_DETAIL: std::cell::RefCell<Option<String>> =
        const { std::cell::RefCell::new(None) };
}

pub fn set_engine_error_detail(msg: String) {
    ENGINE_ERROR_DETAIL.with(|e| *e.borrow_mut() = Some(msg));
}

pub fn take_engine_error_detail() -> Option<String> {
    ENGINE_ERROR_DETAIL.with(|e| e.borrow_mut().take())
}

#[cfg(feature = "jit")]
pub mod host;

#[cfg(all(feature = "jit", not(target_arch = "wasm32")))]
mod engine_config;
#[cfg(all(feature = "jit", not(target_arch = "wasm32")))]
pub use engine_config::tune_memory;

/// Split the runtime's `-l` blob (`<file name>\0<content>`) into a [`LinFile`].
pub fn split_lin_blob(bytes: &[u8]) -> Option<openmodelica_sim_meta::linearize::LinFile> {
    let i = bytes.iter().position(|&b| b == 0)?;
    Some(openmodelica_sim_meta::linearize::LinFile {
        name: String::from_utf8_lossy(&bytes[..i]).into_owned(),
        content: String::from_utf8_lossy(&bytes[i + 1..]).into_owned(),
    })
}

// A thin facade over openmodelica_sim_meta::driver; present even in the no-jit
// stub build, which reads its result types.
pub mod sim_driver;
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
#[path = "sim_runtime_wasmtime.rs"]
pub mod sim_runtime;
#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
#[path = "sim_runtime_wasmer.rs"]
pub mod sim_runtime;
#[cfg(not(feature = "jit"))]
#[path = "sim_runtime_stub.rs"]
pub mod sim_runtime;
#[cfg(feature = "jit")]
#[path = "wasi_shim.rs"]
pub mod wasi_shim;
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
#[path = "dylink_wasmtime.rs"]
pub mod dylink_engine;
