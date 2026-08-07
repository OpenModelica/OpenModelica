//! Host builtins (`rt_assert`, `rt_assert_warning`, the session clock/cancel
//! hooks) and the thread-local assert state they record, shared by both engines.

use metamodelica::Result;

/// A failing assertion recorded by `rt_assert`. `msg`/`file` are handles into the
/// shared linear memory, decoded by the caller after the trap.
pub struct PendingAssert {
    /// The dumped condition, or 0 for a model/runtime error, which has none.
    pub cond: i32,
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
    /// Violations that did not throw: `[kind, cond, msg, file, sline, scol, eline,
    /// ecol, read_only]`, `kind` per `driver::ASSERT_*`.
    static PENDING_WARNINGS: std::cell::RefCell<Vec<[i32; 9]>> = const { std::cell::RefCell::new(Vec::new()) };
    /// C's `noThrowAsserts`: the driver has the model on a provisional state, so
    /// `rt_assert` records instead of telling the caller to trap.
    static NO_THROW: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
}

/// Driver hook (`driver::set_no_throw_hook`). Opening drops the assertion a
/// previous phase suppressed, so `enrich_trap` reports the one that failed.
pub fn set_no_throw_asserts(v: bool) {
    if v {
        clear_pending_assert();
    }
    NO_THROW.with(|n| n.set(v));
}

/// Clear any stale pending assertion before a call.
pub fn clear_pending_assert() {
    PENDING_ASSERT.with(|p| *p.borrow_mut() = None);
}

/// Take the raw pending assertion (for the function-eval path's `report_pending_assert`).
pub fn take_pending_assert_raw() -> Option<PendingAssert> {
    PENDING_ASSERT.with(|p| p.borrow_mut().take())
}

/// Take the pending assertion as `[msg, file, sline, scol, eline, ecol, read_only,
/// cond]` (for the simulation drivers surfacing a failed `assert()` after a trap).
pub fn take_pending_assert() -> Option<[i32; 8]> {
    take_pending_assert_raw()
        .map(|pa| [pa.msg, pa.file, pa.sline, pa.scol, pa.eline, pa.ecol, pa.read_only as i32, pa.cond])
}

/// Take (and clear) the warning-level assertion violations recorded since the last call.
pub fn take_pending_warnings() -> Vec<[i32; 9]> {
    PENDING_WARNINGS.with(|p| core::mem::take(&mut *p.borrow_mut()))
}

/// Take at most `max` of them, oldest first: `rt_host_take_warnings` hands them
/// to the in-wasm driver a bufferful at a time.
fn take_pending_warnings_upto(max: usize) -> Vec<[i32; 9]> {
    PENDING_WARNINGS.with(|p| {
        let mut p = p.borrow_mut();
        let n = max.min(p.len());
        p.drain(..n).collect()
    })
}

/// Serialise the records into `dst` (little-endian `[i32; 9]` each).
fn write_warnings(recs: &[[i32; 9]], dst: &mut [u8]) -> u32 {
    let n = recs.len().min(dst.len() / REC_BYTES);
    for (i, rec) in recs[..n].iter().enumerate() {
        for (k, v) in rec.iter().enumerate() {
            let off = i * REC_BYTES + k * 4;
            dst[off..off + 4].copy_from_slice(&v.to_le_bytes());
        }
    }
    n as u32
}

/// Wire size of one record, shared with the in-wasm reader.
const REC_BYTES: usize = 9 * 4;

/// A [`SimEngine`] over nothing but a read window into the shared linear memory:
/// formatting a `LOG_ASSERT` block reads the time and the String handles and never
/// calls back into the model. The reader is a closure so each engine can serve it
/// from what it has in the import — a `&[u8]` or a `MemoryView`.
#[cfg(feature = "jit")]
struct MemEngine<'a>(&'a dyn Fn(u32, &mut [u8]) -> bool);

#[cfg(feature = "jit")]
impl openmodelica_sim_meta::driver::SimEngine for MemEngine<'_> {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> metamodelica::Result<()> {
        if (self.0)(addr, buf) { Ok(()) } else { Err("wasm-jit: read outside linear memory") }
    }
    fn write_bytes(&mut self, _addr: u32, _buf: &[u8]) -> metamodelica::Result<()> {
        Err("wasm-jit: MemEngine is read-only")
    }
    fn call1(&mut self, _name: &str, _arg: u32) -> metamodelica::Result<()> {
        Err("wasm-jit: MemEngine cannot call the model")
    }
    fn call1_if_present(&mut self, _name: &str, _arg: u32) -> metamodelica::Result<()> {
        Err("wasm-jit: MemEngine cannot call the model")
    }
    fn call2(&mut self, _name: &str, _a: u32, _b: u32) -> metamodelica::Result<()> {
        Err("wasm-jit: MemEngine cannot call the model")
    }
    fn call_simulate(&mut self, _s: u32, _a: f64, _b: f64, _n: u32) -> metamodelica::Result<u32> {
        Err("wasm-jit: MemEngine cannot call the model")
    }
    /// Left to the engine that owns the run: taking it here would consume what
    /// `enrich_trap` reports if the loop goes on to trap.
    fn take_pending_assert(&mut self) -> Option<[i32; 8]> {
        None
    }
    fn take_pending_warnings(&mut self) -> Vec<[i32; 9]> {
        take_pending_warnings()
    }
}

#[cfg(feature = "jit")]
fn row_asserts(read: &dyn Fn(u32, &mut [u8]) -> bool, sim_data: u32, warn: i32) -> i32 {
    openmodelica_sim_meta::driver::row_asserts(&mut MemEngine(read), sim_data, warn)
}

/// The run's shared linear memory. `rt_row_asserts` is called by the *model*
/// module, which imports `memory` rather than exporting it, so `Caller::get_export`
/// cannot find it; the engine sets it here instead (wasmer has [`HostMem`]).
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
mod sim_memory {
    use std::cell::Cell;
    thread_local! {
        static MEMORY: Cell<Option<wasmtime::Memory>> = const { Cell::new(None) };
    }
    pub fn set(m: wasmtime::Memory) {
        MEMORY.with(|c| c.set(Some(m)));
    }
    pub fn get() -> Option<wasmtime::Memory> {
        MEMORY.with(|c| c.get())
    }
}

#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
pub use sim_memory::set as set_sim_memory;

fn record_assert(cond: i32, msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32) {
    PENDING_ASSERT.with(|p| {
        *p.borrow_mut() = Some(PendingAssert { cond, msg, file, sline, scol, eline, ecol, read_only: read_only != 0 });
    });
}

fn record_warning(rec: [i32; 9]) {
    PENDING_WARNINGS.with(|p| p.borrow_mut().push(rec));
}

/// `rt_assert`: a failed `assert()`. Returns 1 when the caller must trap — a model
/// or runtime error (`cond == 0`) always does, a user assertion is recorded
/// instead while the driver has asserts suppressed.
fn assert_failed(cond: i32, msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32) -> i32 {
    if cond != 0 && NO_THROW.with(|n| n.get()) {
        record_warning([
            openmodelica_sim_meta::driver::ASSERT_SUPPRESSED,
            cond, msg, file, sline, scol, eline, ecol, read_only,
        ]);
        // Also as a pending assertion: if the phase throws, this reports it — the
        // in-wasm driver's own reporter cannot reach the host's error buffer.
        record_assert(cond, msg, file, sline, scol, eline, ecol, read_only);
        return 0;
    }
    record_assert(cond, msg, file, sline, scol, eline, ecol, read_only);
    1
}

/// The runtime array object as both engines' external-"C" trampolines read it:
/// header `[refcount][elem kind][ndims][total][dim…]`, then the flat row-major
/// elements from the next 8-byte boundary on.
pub mod array_abi {
    use crate::sig::SigTy;

    /// Every heap handle is a 4-byte `i32`.
    pub fn elem_size(elem: &SigTy) -> usize {
        match elem {
            SigTy::Real => 8,
            _ => 4,
        }
    }

    /// The dimensions and element-area offset of the array object at `obj`.
    pub fn dims_and_data(mem: &[u8], obj: usize) -> Option<(Vec<usize>, usize)> {
        let word = |off: usize| -> Option<usize> {
            Some(u32::from_le_bytes(mem.get(off..off + 4)?.try_into().ok()?) as usize)
        };
        let ndims = word(obj + 8)?;
        let dims = (0..ndims).map(|k| word(obj + 16 + 4 * k)).collect::<Option<Vec<_>>>()?;
        Some((dims, (16 + ndims * 4 + 7) & !7))
    }

    /// Copy `src` to `dst` converting between row-major and column-major storage
    /// (C's `convert_alloc_*_{to,from}_f77`, without its 2-D-only restriction).
    pub fn reorder(src: &[u8], dst: &mut [u8], dims: &[usize], esz: usize, to_fortran: bool) {
        let total: usize = dims.iter().product();
        let mut idx = vec![0usize; dims.len()];
        for r in 0..total {
            let mut c = 0usize;
            let mut stride = 1usize;
            for k in 0..dims.len() {
                c += idx[k] * stride;
                stride *= dims[k];
            }
            let (from, to) = if to_fortran { (r, c) } else { (c, r) };
            dst[to * esz..(to + 1) * esz].copy_from_slice(&src[from * esz..(from + 1) * esz]);
            for k in (0..dims.len()).rev() {
                idx[k] += 1;
                if idx[k] < dims[k] {
                    break;
                }
                idx[k] = 0;
            }
        }
    }
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
    wt(linker.func_wrap("rt", "rt_assert", |msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32, cond: i32| -> i32 {
        assert_failed(cond, msg, file, sline, scol, eline, ecol, read_only)
    }))?;
    wt(linker.func_wrap("rt", "rt_assert_warning", |cond: i32, msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32| {
        record_warning([openmodelica_sim_meta::driver::ASSERT_WARNING, cond, msg, file, sline, scol, eline, ecol, read_only]);
    }))?;
    wt(linker.func_wrap(
        "rt",
        "rt_row_asserts",
        |caller: wasmtime::Caller<'_, T>, sim_data: u32, warn: i32| -> i32 {
            let Some(mem) = sim_memory::get() else { return 1 };
            let data = mem.data(&caller);
            row_asserts(
                &|addr: u32, buf: &mut [u8]| {
                    let off = addr as usize;
                    match data.get(off..off + buf.len()) {
                        Some(src) => {
                            buf.copy_from_slice(src);
                            true
                        }
                        None => false,
                    }
                },
                sim_data,
                warn,
            )
        },
    ))?;
    // The runtime module's `-lv` log lines (the nonlinear solver's), onto the same
    // stdout the model's `print` and the host driver's own lines use.
    wt(linker.func_wrap(
        "env",
        "rt_host_log",
        |mut caller: wasmtime::Caller<'_, T>, ptr: u32, len: u32| {
            let Some(wasmtime::Extern::Memory(mem)) = caller.get_export("memory") else { return };
            let off = ptr as usize;
            if let Some(b) = mem.data(&caller).get(off..off + len as usize) {
                openmodelica_wasi::wasi::stdout_write(b);
            }
        },
    ))?;
    wt(linker.func_wrap("env", "rt_host_now_ms", || -> f64 { openmodelica_sim_meta::driver::now_ms_host() }))?;
    wt(linker.func_wrap("env", "rt_host_cancel", || -> i32 { metamodelica::cancel::check_cancel() as i32 }))?;
    wt(linker.func_wrap("env", "rt_host_init_done", || openmodelica_sim_meta::driver::signal_init_done()))?;
    wt(linker.func_wrap("env", "rt_host_set_no_throw", |v: i32| set_no_throw_asserts(v != 0)))?;
    // The model's violations land here even when the driver runs in-wasm; hand
    // them over so that driver can format the `LOG_ASSERT` block.
    wt(linker.func_wrap(
        "env",
        "rt_host_take_warnings",
        |mut caller: wasmtime::Caller<'_, T>, ptr: u32, max: u32| -> u32 {
            let Some(wasmtime::Extern::Memory(mem)) = caller.get_export("memory") else { return 0 };
            let recs = take_pending_warnings_upto(max as usize);
            let off = ptr as usize;
            let data = mem.data_mut(&mut caller);
            match data.get_mut(off..off + recs.len() * REC_BYTES) {
                Some(dst) => write_warnings(&recs, dst),
                None => 0,
            }
        },
    ))?;
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

/// The runtime's memory, handed to the wasmer host builtins by [`HostMem::set`]
/// once the instance exists; the imports have to be defined before it.
#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
pub struct HostMem(wasmer::FunctionEnv<Option<wasmer::Memory>>);

#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
impl HostMem {
    pub fn set(&self, store: &mut wasmer::Store, memory: &wasmer::Memory) {
        *self.0.as_mut(store) = Some(memory.clone());
    }
}

#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
pub fn add_host_builtins(store: &mut wasmer::Store, imports: &mut wasmer::Imports) -> Result<HostMem> {
    use wasmer::Function;
    imports.define("rt", "rt_assert", Function::new_typed(store,
        |msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32, cond: i32| -> i32 {
            assert_failed(cond, msg, file, sline, scol, eline, ecol, read_only)
        }));
    imports.define("rt", "rt_assert_warning", Function::new_typed(store,
        |cond: i32, msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32| {
            record_warning([openmodelica_sim_meta::driver::ASSERT_WARNING, cond, msg, file, sline, scol, eline, ecol, read_only]);
        }));
    // Both memory-reading imports share one env, filled in by `HostMem::set`.
    let mem_env = wasmer::FunctionEnv::new(store, None);
    imports.define(
        "rt",
        "rt_row_asserts",
        Function::new_typed_with_env(
            store,
            &mem_env,
            |env: wasmer::FunctionEnvMut<Option<wasmer::Memory>>, sim_data: u32, warn: i32| -> i32 {
                let Some(memory) = env.data().clone() else { return 1 };
                let view = memory.view(&env);
                row_asserts(&|addr: u32, buf: &mut [u8]| view.read(addr as u64, buf).is_ok(), sim_data, warn)
            },
        ),
    );
    // See the wasmtime counterpart.
    imports.define(
        "env",
        "rt_host_log",
        Function::new_typed_with_env(
            store,
            &mem_env,
            |env: wasmer::FunctionEnvMut<Option<wasmer::Memory>>, ptr: u32, len: u32| {
                let Some(memory) = env.data().clone() else { return };
                let mut buf = vec![0u8; len as usize];
                if memory.view(&env).read(ptr as u64, &mut buf).is_ok() {
                    openmodelica_wasi::wasi::stdout_write(&buf);
                }
            },
        ),
    );
    imports.define("env", "rt_host_now_ms", Function::new_typed(store, || -> f64 { openmodelica_sim_meta::driver::now_ms_host() }));
    imports.define("env", "rt_host_cancel", Function::new_typed(store, || -> i32 { metamodelica::cancel::check_cancel() as i32 }));
    imports.define("env", "rt_host_init_done", Function::new_typed(store, || openmodelica_sim_meta::driver::signal_init_done()));
    imports.define("env", "rt_host_set_no_throw", Function::new_typed(store, |v: i32| set_no_throw_asserts(v != 0)));
    // See the wasmtime counterpart.
    imports.define(
        "env",
        "rt_host_take_warnings",
        Function::new_typed_with_env(
            store,
            &mem_env,
            |mut env: wasmer::FunctionEnvMut<Option<wasmer::Memory>>, ptr: u32, max: u32| -> u32 {
                let (data, store) = env.data_and_store_mut();
                let Some(memory) = data.clone() else { return 0 };
                let recs = take_pending_warnings_upto(max as usize);
                let mut buf = vec![0u8; recs.len() * REC_BYTES];
                let n = write_warnings(&recs, &mut buf);
                match memory.view(&store).write(ptr as u64, &buf) {
                    Ok(()) => n,
                    Err(_) => 0,
                }
            },
        ),
    );
    Ok(HostMem(mem_env))
}
