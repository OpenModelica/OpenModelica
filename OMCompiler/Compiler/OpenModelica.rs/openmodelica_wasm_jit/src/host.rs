//! Host builtins (`rt_assert`, `rt_assert_warning`, the session clock/cancel
//! hooks) and the thread-local assert state they record, shared by both engines.

use metamodelica::Result;

/// A failing assertion recorded by `rt_assert`. `msg`/`file` are handles into the
/// shared linear memory, decoded by the caller after the trap.
pub struct PendingAssert {
    pub msg: i32,
    pub file: i32,
    pub sline: i32,
    pub scol: i32,
    pub eline: i32,
    pub ecol: i32,
    pub read_only: bool,
}

thread_local! {
    static PENDING_ASSERT: std::cell::RefCell<Option<PendingAssert>> = const { std::cell::RefCell::new(None) };
    /// `rt_assert_warning` records `[cond, msg, file, sline, scol, eline, ecol, read_only]`.
    static PENDING_WARNINGS: std::cell::RefCell<Vec<[i32; 8]>> = const { std::cell::RefCell::new(Vec::new()) };
}

/// Clear any stale pending assertion before a call.
pub fn clear_pending_assert() {
    PENDING_ASSERT.with(|p| *p.borrow_mut() = None);
}

/// Take the raw pending assertion (for the function-eval path's `report_pending_assert`).
pub fn take_pending_assert_raw() -> Option<PendingAssert> {
    PENDING_ASSERT.with(|p| p.borrow_mut().take())
}

/// Take the pending assertion as `[msg, file, sline, scol, eline, ecol, read_only]`
/// (for the simulation drivers surfacing a failed `assert()` after a trap).
pub fn take_pending_assert() -> Option<[i32; 7]> {
    take_pending_assert_raw().map(|pa| [pa.msg, pa.file, pa.sline, pa.scol, pa.eline, pa.ecol, pa.read_only as i32])
}

/// Take (and clear) the warning-level assertion violations recorded since the last call.
pub fn take_pending_warnings() -> Vec<[i32; 8]> {
    PENDING_WARNINGS.with(|p| core::mem::take(&mut *p.borrow_mut()))
}

fn record_assert(msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32) {
    PENDING_ASSERT.with(|p| {
        *p.borrow_mut() = Some(PendingAssert { msg, file, sline, scol, eline, ecol, read_only: read_only != 0 });
    });
}

fn record_warning(rec: [i32; 8]) {
    PENDING_WARNINGS.with(|p| p.borrow_mut().push(rec));
}

// `rt_assert`/`rt_assert_warning` register under `rt` (not `env`) so the merged
// wasip1 export needs no `env` namespace; `rt_host_*` feed the in-wasm session
// driver the host clock/cancel source.
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
pub fn add_host_builtins(linker: &mut wasmtime::Linker<()>) -> Result<()> {
    let wt = |r: std::result::Result<&mut wasmtime::Linker<()>, wasmtime::Error>| r.map(|_| ()).map_err(|_| "CodegenWasmJit: wasm engine error");
    wt(linker.func_wrap("rt", "rt_assert", |msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32| {
        record_assert(msg, file, sline, scol, eline, ecol, read_only);
    }))?;
    wt(linker.func_wrap("rt", "rt_assert_warning", |cond: i32, msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32| {
        record_warning([cond, msg, file, sline, scol, eline, ecol, read_only]);
    }))?;
    wt(linker.func_wrap("env", "rt_host_now_ms", || -> f64 { openmodelica_sim_meta::driver::now_ms_host() }))?;
    wt(linker.func_wrap("env", "rt_host_cancel", || -> i32 { metamodelica::cancel::check_cancel() as i32 }))?;
    Ok(())
}

#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
pub fn add_host_builtins(store: &mut wasmer::Store, imports: &mut wasmer::Imports) -> Result<()> {
    use wasmer::Function;
    imports.define("rt", "rt_assert", Function::new_typed(store,
        |msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32| {
            record_assert(msg, file, sline, scol, eline, ecol, read_only);
        }));
    imports.define("rt", "rt_assert_warning", Function::new_typed(store,
        |cond: i32, msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32| {
            record_warning([cond, msg, file, sline, scol, eline, ecol, read_only]);
        }));
    imports.define("env", "rt_host_now_ms", Function::new_typed(store, || -> f64 { openmodelica_sim_meta::driver::now_ms_host() }));
    imports.define("env", "rt_host_cancel", Function::new_typed(store, || -> i32 { metamodelica::cancel::check_cancel() as i32 }));
    Ok(())
}
