//! Host-side wasm-jit execution engine for OpenModelica.

pub mod blobs;
pub use blobs::*;

/// Whether the wasip1 runtimes in [`blobs`] have the real SUNDIALS/KLU linked in
/// (the build script cross-compiled the archives), so `-lss=klu` can be served.
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
pub mod result_sink;
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
