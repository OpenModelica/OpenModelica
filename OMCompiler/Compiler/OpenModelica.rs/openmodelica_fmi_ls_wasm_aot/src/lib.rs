//! AOT-compile an fmi-ls-wasm component for a native platform, from inside wasm.
//!
//! The host (a Web Worker; see `wasm/fmu-aot-worker.js`) drives one job per
//! instance: [`aot_alloc`] twice for the component and the target triple,
//! [`aot_compile`], then [`aot_result_ptr`]/[`aot_result_len`] for either the
//! `.cwasm` or, when the call reports failure, the error text.
//!
//! The engine configuration must be the FMU loader's
//! (`openmodelica_fmi_ls_wasm_to_native`) — a `.cwasm` records it and is rejected
//! at load time on any mismatch.

use std::cell::RefCell;

thread_local! {
    /// The last [`aot_alloc`]ation and the last result, kept alive for the host
    /// to read out of linear memory.
    static BUFS: RefCell<Vec<Vec<u8>>> = const { RefCell::new(Vec::new()) };
    static RESULT: RefCell<Vec<u8>> = const { RefCell::new(Vec::new()) };
}

/// A zeroed buffer of `len` bytes for the host to write into.
#[no_mangle]
pub extern "C" fn aot_alloc(len: usize) -> *mut u8 {
    BUFS.with(|b| {
        let mut b = b.borrow_mut();
        b.push(vec![0u8; len]);
        b.last_mut().expect("just pushed").as_mut_ptr()
    })
}

/// Compile `component` for `triple`. Returns 0 on success, 1 on failure; the
/// result buffer then holds the `.cwasm` or the error text respectively.
///
/// # Safety
/// Both pointers must name `aot_alloc`ed buffers of the given lengths.
#[no_mangle]
pub unsafe extern "C" fn aot_compile(
    component: *const u8,
    component_len: usize,
    triple: *const u8,
    triple_len: usize,
) -> i32 {
    let component = std::slice::from_raw_parts(component, component_len);
    let triple = String::from_utf8_lossy(std::slice::from_raw_parts(triple, triple_len)).into_owned();
    let (status, out) = match compile(component, &triple) {
        Ok(cwasm) => (0, cwasm),
        Err(e) => (1, e.into_bytes()),
    };
    BUFS.with(|b| b.borrow_mut().clear());
    RESULT.with(|r| *r.borrow_mut() = out);
    status
}

#[no_mangle]
pub extern "C" fn aot_result_ptr() -> *const u8 {
    RESULT.with(|r| r.borrow().as_ptr())
}

#[no_mangle]
pub extern "C" fn aot_result_len() -> usize {
    RESULT.with(|r| r.borrow().len())
}

fn compile(component: &[u8], triple: &str) -> Result<Vec<u8>, String> {
    let mut cfg = wasmtime::Config::new();
    cfg.wasm_component_model(true);
    // Must match the loader's engine (see openmodelica_fmi_ls_wasm_to_native).
    cfg.wasm_exceptions(true);
    cfg.target(triple).map_err(|e| format!("unknown target `{triple}`: {e}"))?;
    let engine = wasmtime::Engine::new(&cfg).map_err(|e| format!("engine: {e}"))?;
    engine.precompile_component(component).map_err(|e| format!("compiling for {triple}: {e}"))
}
