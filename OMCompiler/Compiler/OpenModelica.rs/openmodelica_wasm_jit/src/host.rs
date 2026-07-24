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

// Native rsparse solve behind the `env.rt_host_lin_solve` import, which the native
// interactive runtime calls from `rt_solve_lin_sparse_cached`. Symbolic analysis
// cached per system `handle`; `count()` feeds `stats.lin_solves`.
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
pub mod lin_solve {
    use std::cell::{Cell, RefCell};
    use std::collections::HashMap;

    struct Cached {
        a: rsparse::data::Sprs<f64>, // p/i fixed after seeding; x refreshed per solve
        s: rsparse::data::Symb,
        x: Vec<f64>,
    }
    thread_local! {
        static CACHE: RefCell<HashMap<u32, Cached>> = RefCell::new(HashMap::new());
        static COUNT: Cell<u64> = const { Cell::new(0) };
    }

    /// Drop the per-system cache and zero the counter; called once per run setup.
    pub fn reset() {
        CACHE.with(|c| c.borrow_mut().clear());
        COUNT.with(|c| c.set(0));
    }
    /// Linear solves performed host-side in the current run.
    pub fn count() -> u64 {
        COUNT.with(|c| c.get())
    }

    fn read_f64(mem: &[u8], off: usize, k: usize) -> Option<f64> {
        let s = off + k * 8;
        Some(f64::from_le_bytes(mem.get(s..s + 8)?.try_into().unwrap()))
    }
    fn read_i32(mem: &[u8], off: usize, k: usize) -> Option<i32> {
        let s = off + k * 4;
        Some(i32::from_le_bytes(mem.get(s..s + 4)?.try_into().unwrap()))
    }

    /// Solve `A x = b` (CSC in wasm `mem`) and return the solution to write back
    /// into `b`, or `None` if singular. Mirrors the runtime's cached path.
    pub fn solve(
        handle: u32, colptr: u32, rowidx: u32, values: u32, b_ptr: u32,
        n: usize, nnz: usize, mem: &[u8],
    ) -> Option<Vec<f64>> {
        let (colptr, rowidx, values, b_ptr) = (colptr as usize, rowidx as usize, values as usize, b_ptr as usize);
        let mut b: Vec<f64> = (0..n).map(|k| read_f64(mem, b_ptr, k)).collect::<Option<_>>()?;
        let vals: Vec<f64> = (0..nnz).map(|k| read_f64(mem, values, k)).collect::<Option<_>>()?;
        COUNT.with(|c| c.set(c.get() + 1));
        CACHE.with(|cell| {
            let mut cache = cell.borrow_mut();
            let entry = match cache.entry(handle) {
                std::collections::hash_map::Entry::Occupied(e) => e.into_mut(),
                std::collections::hash_map::Entry::Vacant(slot) => {
                    let p: Vec<isize> = (0..=n).map(|k| read_i32(mem, colptr, k).map(|x| x as isize)).collect::<Option<_>>()?;
                    let i: Vec<usize> = (0..nnz).map(|k| read_i32(mem, rowidx, k).map(|x| x as usize)).collect::<Option<_>>()?;
                    let a = rsparse::data::Sprs { nzmax: nnz, m: n, n, p, i, x: vals.clone() };
                    let s = rsparse::sqr(&a, 2, false); // AMD ordering + symbolic, once
                    slot.insert(Cached { a, s, x: vec![0.0f64; n] })
                }
            };
            entry.a.x.copy_from_slice(&vals);
            let Cached { a, s, x } = entry;
            let nm = rsparse::lu(a, s, 1.0).ok()?;
            // x = P*b, solve L/U, b = Q*x; rsparse's `ipvec` permute is private.
            match &nm.pinv {
                Some(p) => for k in 0..n { x[p[k] as usize] = b[k]; },
                None => x[..n].copy_from_slice(&b[..n]),
            }
            rsparse::lsolve(&nm.l, &mut x[..]);
            rsparse::usolve(&nm.u, &mut x[..]);
            match &s.q {
                Some(q) => for k in 0..n { b[q[k] as usize] = x[k]; },
                None => b[..n].copy_from_slice(&x[..n]),
            }
            Some(b)
        })
    }
}

// `rt_assert`/`rt_assert_warning` register under `rt` (not `env`) so the merged
// wasip1 export needs no `env` namespace; `rt_host_*` feed the in-wasm session
// driver the host clock/cancel source.
// Generic over the store data `T` (the closures never touch it), so both the sim
// path (`Store<WasiCtx>`) and the `-d=gen` function-eval path (`Store<()>`) reuse it.
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
pub fn add_host_builtins<T: 'static>(linker: &mut wasmtime::Linker<T>) -> Result<()> {
    let wt = |r: std::result::Result<&mut wasmtime::Linker<T>, wasmtime::Error>| r.map(|_| ()).map_err(|_| "CodegenWasmJit: wasm engine error");
    wt(linker.func_wrap("rt", "rt_assert", |msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32| {
        record_assert(msg, file, sline, scol, eline, ecol, read_only);
    }))?;
    wt(linker.func_wrap("rt", "rt_assert_warning", |cond: i32, msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32| {
        record_warning([cond, msg, file, sline, scol, eline, ecol, read_only]);
    }))?;
    wt(linker.func_wrap("env", "rt_host_now_ms", || -> f64 { openmodelica_sim_meta::driver::now_ms_host() }))?;
    wt(linker.func_wrap("env", "rt_host_cancel", || -> i32 { metamodelica::cancel::check_cancel() as i32 }))?;
    // Solve the CSC system in the caller's (the runtime's) shared memory; the
    // interactive runtime imports this. Returns 0 (solved, `b` overwritten) or 1.
    wt(linker.func_wrap(
        "env",
        "rt_host_lin_solve",
        |mut caller: wasmtime::Caller<'_, T>, handle: u32, colptr: u32, rowidx: u32, values: u32, b_ptr: u32, n: u32, nnz: u32| -> i32 {
            let Some(wasmtime::Extern::Memory(mem)) = caller.get_export("memory") else { return 1 };
            let x = lin_solve::solve(handle, colptr, rowidx, values, b_ptr, n as usize, nnz as usize, mem.data(&caller));
            match x {
                Some(x) => {
                    let off = b_ptr as usize;
                    let data = mem.data_mut(&mut caller);
                    for (k, v) in x.iter().enumerate() {
                        data[off + k * 8..off + k * 8 + 8].copy_from_slice(&v.to_le_bytes());
                    }
                    0
                }
                None => 1,
            }
        },
    ))?;
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
