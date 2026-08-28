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
    pub initial: bool,
}

thread_local! {
    static PENDING_ASSERT: std::cell::RefCell<Option<PendingAssert>> = const { std::cell::RefCell::new(None) };
    /// Violations that did not throw: `[kind, cond, msg, file, sline, scol, eline,
    /// ecol, read_only, initial]`, `kind` per `driver::ASSERT_*`.
    static PENDING_WARNINGS: std::cell::RefCell<Vec<[i32; 10]>> = const { std::cell::RefCell::new(Vec::new()) };
    /// C's `noThrowAsserts`: the driver has the model on a provisional state, so
    /// `rt_assert` records instead of telling the caller to trap.
    static NO_THROW: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
    /// Executed `reinit`s, `(state SimData offset, value)`, for the driver's
    /// `LOG_EVENTS` block. Only filled while that stream is on.
    static PENDING_REINITS: std::cell::RefCell<Vec<(u32, f64)>> = const { std::cell::RefCell::new(Vec::new()) };
}

/// `rt_reinit_note`: record an executed `reinit` while `LOG_EVENTS` is on.
pub fn record_reinit(off: u32, value: f64) {
    if openmodelica_sim_meta::omclog::active(openmodelica_sim_meta::omclog::EVENTS) {
        PENDING_REINITS.with(|p| p.borrow_mut().push((off, value)));
    }
}

/// Take (and clear) the `reinit`s recorded since the last call.
pub fn take_pending_reinits() -> Vec<(u32, f64)> {
    PENDING_REINITS.with(|p| core::mem::take(&mut *p.borrow_mut()))
}

/// Serialise them for the in-wasm driver: `[off: u32][value: f64]` per record.
const REINIT_BYTES: usize = 16;

fn take_reinits_into(dst: &mut [u8], max: usize) -> u32 {
    let recs = PENDING_REINITS.with(|p| {
        let mut p = p.borrow_mut();
        let n = max.min(p.len()).min(dst.len() / REINIT_BYTES);
        p.drain(..n).collect::<Vec<_>>()
    });
    for (i, (off, v)) in recs.iter().enumerate() {
        let b = i * REINIT_BYTES;
        dst[b..b + 4].copy_from_slice(&off.to_le_bytes());
        dst[b + 8..b + 16].copy_from_slice(&v.to_le_bytes());
    }
    recs.len() as u32
}

/// Driver hook (`driver::set_no_throw_hook`). Opening drops the assertion a
/// previous phase suppressed, so `enrich_trap` reports the one that failed.
pub fn set_no_throw_asserts(v: bool) {
    if v {
        clear_pending_assert();
    }
    NO_THROW.with(|n| n.set(v));
}

pub fn no_throw_asserts() -> bool {
    NO_THROW.with(|n| n.get())
}

/// Re-record on this thread what a parmodauto worker thread's `rt_assert` left.
pub fn set_pending_assert_raw(pa: PendingAssert) {
    PENDING_ASSERT.with(|p| *p.borrow_mut() = Some(pa));
}

pub fn record_warnings(recs: Vec<[i32; 10]>) {
    PENDING_WARNINGS.with(|p| p.borrow_mut().extend(recs));
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
/// cond, initial]` (for the simulation drivers surfacing a failed `assert()` after
/// a trap).
pub fn take_pending_assert() -> Option<[i32; 9]> {
    take_pending_assert_raw().map(|pa| {
        [pa.msg, pa.file, pa.sline, pa.scol, pa.eline, pa.ecol, pa.read_only as i32, pa.cond, pa.initial as i32]
    })
}

/// Take (and clear) the warning-level assertion violations recorded since the last call.
pub fn take_pending_warnings() -> Vec<[i32; 10]> {
    PENDING_WARNINGS.with(|p| core::mem::take(&mut *p.borrow_mut()))
}

/// Take at most `max` of them, oldest first: `rt_host_take_warnings` hands them
/// to the in-wasm driver a bufferful at a time.
fn take_pending_warnings_upto(max: usize) -> Vec<[i32; 10]> {
    PENDING_WARNINGS.with(|p| {
        let mut p = p.borrow_mut();
        let n = max.min(p.len());
        p.drain(..n).collect()
    })
}

/// Serialise the records into `dst` (little-endian `[i32; 10]` each).
fn write_warnings(recs: &[[i32; 10]], dst: &mut [u8]) -> u32 {
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
const REC_BYTES: usize = 10 * 4;

/// `rt_uri_to_filename` on a host: `metamodelica`'s port of
/// `OpenModelica_uriToFilename_impl`, resolving `modelica://` against the class
/// directories `System.updateUriMapping` installed. A host run has no FMU
/// resources directory, so the `fmu` selector only matters inside an FMU.
///
/// Like the external "C" path, the run reports itself through its log alone, so
/// the message the `omc_assert` hook buffered is rolled back and returned.
#[cfg(feature = "jit")]
fn uri_to_filename(uri: &str) -> std::result::Result<String, String> {
    const CP: arcstr::ArcStr = arcstr::literal!("wasm-jit uriToFilename");
    openmodelica_error::ErrorExt::setCheckpoint(CP);
    match metamodelica::uriToFilename(arcstr::ArcStr::from(uri)) {
        Ok(path) => {
            openmodelica_error::ErrorExt::delCheckpoint(CP);
            Ok(path.to_string())
        }
        Err(_) => {
            let msg = openmodelica_error::ErrorExt::take_last_runtime_error();
            openmodelica_error::ErrorExt::rollBack(CP);
            let msg = msg.unwrap_or_else(|| format!("uriToFilename: cannot resolve {uri}"));
            crate::sim_driver::note_runtime_error(&msg);
            Err(msg)
        }
    }
}

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
    fn call1_raw(&mut self, _name: &str, _arg: u32) -> metamodelica::Result<()> {
        Err("wasm-jit: MemEngine cannot call the model")
    }
    fn call1_if_present_raw(&mut self, _name: &str, _arg: u32) -> metamodelica::Result<()> {
        Err("wasm-jit: MemEngine cannot call the model")
    }
    fn call2_raw(&mut self, _name: &str, _a: u32, _b: u32) -> metamodelica::Result<()> {
        Err("wasm-jit: MemEngine cannot call the model")
    }
    fn call_simulate(&mut self, _s: u32, _a: f64, _b: f64, _n: u32) -> metamodelica::Result<u32> {
        Err("wasm-jit: MemEngine cannot call the model")
    }
    /// Left to the engine that owns the run: taking it here would consume what
    /// `enrich_trap` reports if the loop goes on to trap.
    fn take_pending_assert(&mut self) -> Option<[i32; 9]> {
        None
    }
    fn take_pending_warnings(&mut self) -> Vec<[i32; 10]> {
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
    use std::cell::RefCell;
    thread_local! {
        static MEMORY: RefCell<Option<crate::simmem::SimMem>> = const { RefCell::new(None) };
    }
    pub fn set(m: crate::simmem::SimMem) {
        MEMORY.with(|c| *c.borrow_mut() = Some(m));
    }
    pub fn get() -> Option<crate::simmem::SimMem> {
        MEMORY.with(|c| c.borrow().clone())
    }
}

/// The run's `model_error` tag, and the libraries' shadow stack that a caught
/// throw leaves claimed. Both belong to the run's store, so they are registered
/// after the model module is instantiated and cleared when the next run starts.
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
mod model_error {
    use std::cell::RefCell;
    use wasmtime::{AsContextMut, ExnRef, ExnRefPre, ExnType, Global, Rooted, Tag, Val};

    thread_local! {
        static TAG: RefCell<Option<(Tag, ExnRefPre)>> = const { RefCell::new(None) };
        static STACK: RefCell<Option<Global>> = const { RefCell::new(None) };
    }

    /// `None` clears it — a store outlives neither the run nor its tag.
    pub fn set_tag(mut store: impl AsContextMut, tag: Option<Tag>) -> Result<(), wasmtime::Error> {
        let entry = match tag {
            Some(tag) => {
                let ty = ExnType::from_tag_type(&tag.ty(&store.as_context_mut()))?;
                Some((tag, ExnRefPre::new(&mut store, ty)))
            }
            None => None,
        };
        TAG.with(|t| *t.borrow_mut() = entry);
        Ok(())
    }

    pub fn set_shadow_stack(s: Option<Global>) {
        STACK.with(|c| *c.borrow_mut() = s);
    }

    /// A fresh exception object to throw, when this run catches them at all.
    pub fn exception(
        store: &mut impl AsContextMut,
    ) -> Result<Option<Rooted<ExnRef>>, wasmtime::Error> {
        TAG.with(|t| match t.borrow().as_ref() {
            Some((tag, pre)) => ExnRef::new(&mut *store, pre, tag, &[]).map(Some),
            None => Ok(None),
        })
    }

    /// `rt.rt_ext_stack_save`: the libraries' shadow stack, which the module's own
    /// (`__stack_pointer` in the runtime) is not — they are separate instances here.
    pub fn save_shadow_stack(mut store: impl AsContextMut) -> Result<i32, wasmtime::Error> {
        match STACK.with(|c| *c.borrow()) {
            Some(g) => Ok(g.get(&mut store).i32().unwrap_or(0)),
            None => Ok(0),
        }
    }

    /// `rt.rt_ext_stack_restore`.
    pub fn restore_shadow_stack(mut store: impl AsContextMut, sp: i32) -> Result<(), wasmtime::Error> {
        if let Some(g) = STACK.with(|c| *c.borrow()) {
            g.set(&mut store, Val::I32(sp))?;
        }
        Ok(())
    }
}

#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
pub use model_error::{
    exception as model_error_exception, restore_shadow_stack, save_shadow_stack, set_shadow_stack,
    set_tag as set_model_error_tag,
};

#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
pub use sim_memory::set as set_sim_memory;
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
pub use sim_memory::get as get_sim_memory;

fn record_assert(cond: i32, msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32, initial: i32) {
    PENDING_ASSERT.with(|p| {
        *p.borrow_mut() = Some(PendingAssert {
            cond, msg, file, sline, scol, eline, ecol,
            read_only: read_only != 0,
            initial: initial != 0,
        });
    });
}

fn record_warning(rec: [i32; 10]) {
    PENDING_WARNINGS.with(|p| p.borrow_mut().push(rec));
}

/// `rt_assert`: a failed `assert()`. Returns 1 when the caller must trap — a model
/// or runtime error (`cond == 0`) always does, a user assertion is recorded
/// instead while the driver has asserts suppressed.
fn assert_failed(cond: i32, msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32, initial: i32) -> i32 {
    if cond != 0 && NO_THROW.with(|n| n.get()) {
        record_warning([
            openmodelica_sim_meta::driver::ASSERT_SUPPRESSED,
            cond, msg, file, sline, scol, eline, ecol, read_only, initial,
        ]);
        // Also as a pending assertion: if the phase throws, this reports it — the
        // in-wasm driver's own reporter cannot reach the host's error buffer.
        record_assert(cond, msg, file, sline, scol, eline, ecol, read_only, initial);
        return 0;
    }
    record_assert(cond, msg, file, sline, scol, eline, ecol, read_only, initial);
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
    wt(linker.func_wrap("rt", "rt_assert", |msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32, cond: i32, initial: i32, _sim_data: i32| -> i32 {
        assert_failed(cond, msg, file, sline, scol, eline, ecol, read_only, initial)
    }))?;
    wt(linker.func_wrap("rt", "rt_ext_stack_save", |mut caller: wasmtime::Caller<'_, T>| -> std::result::Result<i32, wasmtime::Error> {
        save_shadow_stack(&mut caller)
    }))?;
    wt(linker.func_wrap("rt", "rt_ext_stack_restore", |mut caller: wasmtime::Caller<'_, T>, sp: i32| -> std::result::Result<(), wasmtime::Error> {
        restore_shadow_stack(&mut caller, sp)
    }))?;
    wt(linker.func_wrap("rt", "rt_assert_warning", |cond: i32, msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32, initial: i32| {
        record_warning([openmodelica_sim_meta::driver::ASSERT_WARNING, cond, msg, file, sline, scol, eline, ecol, read_only, initial]);
    }))?;
    // Where the runtime's `rt_ext_error` reports. Unused on this engine, whose
    // libraries import `ModelicaError` from the host, which throws for itself.
    wt(linker.func_wrap("env", "rt_host_ext_error", |caller: wasmtime::Caller<'_, T>, msg: u32| {
        let Some(memory) = sim_memory::get() else { return };
        let data = memory.data(&caller);
        let Some(rest) = data.get(msg as usize..) else { return };
        let len = rest.iter().position(|&b| b == 0).unwrap_or(0);
        openmodelica_sim_meta::driver::note_runtime_error(&String::from_utf8_lossy(&rest[..len]));
    }))?;
    wt(linker.func_wrap("rt", "rt_reinit_note", |off: i32, value: f64| record_reinit(off as u32, value)))?;
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
            let Some(mem) = caller.get_export("memory").and_then(crate::simmem::SimMem::from_extern) else { return };
            let off = ptr as usize;
            if let Some(b) = mem.data(&caller).get(off..off + len as usize) {
                openmodelica_wasi::wasi::stdout_write(b);
            }
        },
    ))?;
    wt(linker.func_wrap("env", "rt_host_now_ms", || -> f64 { openmodelica_sim_meta::driver::now_ms_host() }))?;
    // The runtime's `files::write_file`: a solver's side file (the homotopy path
    // CSV), written where C's executable writes it — the working directory.
    wt(linker.func_wrap(
        "env",
        "rt_host_write_file",
        |caller: wasmtime::Caller<'_, T>, name: u32, name_len: u32, data: u32, data_len: u32| {
            let Some(memory) = sim_memory::get() else { return };
            let bytes = memory.data(&caller);
            let (Some(name), Some(data)) = (
                bytes.get(name as usize..(name + name_len) as usize),
                bytes.get(data as usize..(data + data_len) as usize),
            ) else {
                return;
            };
            let _ = openmodelica_wasi::fs::write(String::from_utf8_lossy(name).as_ref(), data);
        },
    ))?;
    wt(linker.func_wrap("env", "rt_host_cancel", || -> i32 { metamodelica::cancel::check_cancel() as i32 }))?;
    wt(linker.func_wrap("env", "rt_host_init_done", || openmodelica_sim_meta::driver::signal_init_done()))?;
    wt(linker.func_wrap("env", "rt_host_set_no_throw", |v: i32| set_no_throw_asserts(v != 0)))?;
    wt(linker.func_wrap("env", "rt_host_runtime_error", || openmodelica_sim_meta::driver::note_runtime_error_flag()))?;
    // The external "C" libraries are the host's, so C's `RHSFinalFlag` is too.
    wt(linker.func_wrap("env", "rt_host_rhs_final", |v: i32| openmodelica_util::dynload::set_rhs_final_flag(v != 0)))?;
    // The model's violations land here even when the driver runs in-wasm; hand
    // them over so that driver can format the `LOG_ASSERT` block.
    wt(linker.func_wrap(
        "env",
        "rt_host_take_warnings",
        |mut caller: wasmtime::Caller<'_, T>, ptr: u32, max: u32| -> u32 {
            let Some(mem) = caller.get_export("memory").and_then(crate::simmem::SimMem::from_extern) else { return 0 };
            let recs = take_pending_warnings_upto(max as usize);
            let off = ptr as usize;
            let data = mem.data_mut(&mut caller);
            match data.get_mut(off..off + recs.len() * REC_BYTES) {
                Some(dst) => write_warnings(&recs, dst),
                None => 0,
            }
        },
    ))?;
    wt(linker.func_wrap(
        "env",
        "rt_host_take_reinits",
        |mut caller: wasmtime::Caller<'_, T>, ptr: u32, max: u32| -> u32 {
            let Some(mem) = caller.get_export("memory").and_then(crate::simmem::SimMem::from_extern) else { return 0 };
            let off = ptr as usize;
            let end = off + max as usize * REINIT_BYTES;
            let data = mem.data_mut(&mut caller);
            match data.get_mut(off..end) {
                Some(dst) => take_reinits_into(dst, max as usize),
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
            let Some(mem) = caller.get_export("memory").and_then(crate::simmem::SimMem::from_extern) else { return 1 };
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

/// `rt.rt_uri_to_filename`: the model's URI resolved into a fresh in-wasm String.
/// Per instance, not in [`add_host_builtins`]: it re-enters the string constructors.
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
pub fn define_uri_import<T: 'static>(
    linker: &mut wasmtime::Linker<T>,
    memory: crate::simmem::SimMem,
    str_new: wasmtime::TypedFunc<u32, u32>,
    str_data: wasmtime::TypedFunc<u32, u32>,
) -> Result<()> {
    linker
        .func_wrap(
            "rt",
            "rt_uri_to_filename",
            move |mut caller: wasmtime::Caller<'_, T>, handle: u32, _fmu: i32| -> std::result::Result<u32, wasmtime::Error> {
                let uri = read_wasm_string(&memory, &caller, handle);
                let path = uri_to_filename(&uri).map_err(wasmtime::Error::msg)?;
                let out = str_new.call(&mut caller, path.len() as u32)?;
                let at = str_data.call(&mut caller, out)? as usize;
                memory.data_mut(&mut caller)[at..at + path.len()].copy_from_slice(path.as_bytes());
                Ok(out)
            },
        )
        .map(|_| ())
        .map_err(|_| "CodegenWasmJit: wasm engine error")
}

/// The bytes of the String at `handle` (`[refcount:u32][len:u32][utf8…]`).
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
fn read_wasm_string<T>(memory: &crate::simmem::SimMem, caller: &wasmtime::Caller<'_, T>, handle: u32) -> String {
    if handle == 0 {
        return String::new();
    }
    let data = memory.data(caller);
    let h = handle as usize;
    let Some(lenb) = data.get(h + 4..h + 8) else { return String::new() };
    let len = u32::from_le_bytes(lenb.try_into().unwrap()) as usize;
    data.get(h + 8..h + 8 + len).map(|b| String::from_utf8_lossy(b).into_owned()).unwrap_or_default()
}

/// What the wasmer host builtins read, filled in once the instances exist (the
/// imports have to be defined before them).
#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
#[derive(Default)]
pub struct HostEnv {
    mem: Option<wasmer::Memory>,
    /// The external "C" side module's own memory and shadow stack.
    side_mem: Option<wasmer::Memory>,
    side_sp: Option<wasmer::Global>,
}

#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
pub struct HostMem(wasmer::FunctionEnv<HostEnv>);

#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
impl HostMem {
    pub fn set(&self, store: &mut wasmer::Store, memory: &wasmer::Memory) {
        self.0.as_mut(store).mem = Some(memory.clone());
    }
    /// The ModelicaExternalC side module, once instantiated.
    pub fn set_side(&self, store: &mut wasmer::Store, memory: &wasmer::Memory, sp: Option<wasmer::Global>) {
        let env = self.0.as_mut(store);
        env.side_mem = Some(memory.clone());
        env.side_sp = sp;
    }
}

#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
pub fn add_host_builtins(store: &mut wasmer::Store, imports: &mut wasmer::Imports) -> Result<HostMem> {
    use wasmer::Function;
    imports.define("rt", "rt_assert", Function::new_typed(store,
        |msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32, cond: i32, initial: i32, _sim_data: i32| -> i32 {
            assert_failed(cond, msg, file, sline, scol, eline, ecol, read_only, initial)
        }));
    imports.define("rt", "rt_assert_warning", Function::new_typed(store,
        |cond: i32, msg: i32, file: i32, sline: i32, scol: i32, eline: i32, ecol: i32, read_only: i32, initial: i32| {
            record_warning([openmodelica_sim_meta::driver::ASSERT_WARNING, cond, msg, file, sline, scol, eline, ecol, read_only, initial]);
        }));
    imports.define("rt", "rt_reinit_note", Function::new_typed(store,
        |off: i32, value: f64| record_reinit(off as u32, value)));
    // The imports reading an instance share one env, filled in by `HostMem`.
    let mem_env = wasmer::FunctionEnv::new(store, HostEnv::default());
    // The side module's shadow stack, which the frames a throw abandoned never
    // handed back.
    imports.define(
        "rt",
        "rt_ext_stack_save",
        Function::new_typed_with_env(store, &mem_env, |mut env: wasmer::FunctionEnvMut<HostEnv>| -> i32 {
            match env.data().side_sp.clone() {
                Some(g) => g.get(&mut env).i32().unwrap_or(0),
                None => 0,
            }
        }),
    );
    imports.define(
        "rt",
        "rt_ext_stack_restore",
        Function::new_typed_with_env(store, &mem_env, |mut env: wasmer::FunctionEnvMut<HostEnv>, sp: i32| {
            if let Some(g) = env.data().side_sp.clone() {
                let _ = g.set(&mut env, wasmer::Value::I32(sp));
            }
        }),
    );
    // A side-module `ModelicaError`: the runtime cannot read the message (other
    // memory), so it reports through here before throwing — C's
    // `throwStreamPrint`, into the run's log.
    imports.define(
        "env",
        "rt_host_ext_error",
        Function::new_typed_with_env(store, &mem_env, |env: wasmer::FunctionEnvMut<HostEnv>, msg: u32| {
            let Some(memory) = env.data().side_mem.clone() else { return };
            openmodelica_sim_meta::driver::note_runtime_error(&crate::sim_runtime::read_cstr(&memory, &env, msg));
        }),
    );
    imports.define(
        "rt",
        "rt_row_asserts",
        Function::new_typed_with_env(
            store,
            &mem_env,
            |env: wasmer::FunctionEnvMut<HostEnv>, sim_data: u32, warn: i32| -> i32 {
                let Some(memory) = env.data().mem.clone() else { return 1 };
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
            |env: wasmer::FunctionEnvMut<HostEnv>, ptr: u32, len: u32| {
                let Some(memory) = env.data().mem.clone() else { return };
                let mut buf = vec![0u8; len as usize];
                if memory.view(&env).read(ptr as u64, &mut buf).is_ok() {
                    openmodelica_wasi::wasi::stdout_write(&buf);
                }
            },
        ),
    );
    imports.define("env", "rt_host_now_ms", Function::new_typed(store, || -> f64 { openmodelica_sim_meta::driver::now_ms_host() }));
    // See the wasmtime counterpart.
    imports.define(
        "env",
        "rt_host_write_file",
        Function::new_typed_with_env(
            store,
            &mem_env,
            |env: wasmer::FunctionEnvMut<HostEnv>, name: u32, name_len: u32, data: u32, data_len: u32| {
                let Some(memory) = env.data().mem.clone() else { return };
                let mut nbuf = vec![0u8; name_len as usize];
                let mut dbuf = vec![0u8; data_len as usize];
                let view = memory.view(&env);
                if view.read(name as u64, &mut nbuf).is_ok() && view.read(data as u64, &mut dbuf).is_ok() {
                    let _ = openmodelica_wasi::fs::write(String::from_utf8_lossy(&nbuf).as_ref(), &dbuf);
                }
            },
        ),
    );
    imports.define("env", "rt_host_cancel", Function::new_typed(store, || -> i32 { metamodelica::cancel::check_cancel() as i32 }));
    imports.define("env", "rt_host_init_done", Function::new_typed(store, || openmodelica_sim_meta::driver::signal_init_done()));
    imports.define("env", "rt_host_set_no_throw", Function::new_typed(store, |v: i32| set_no_throw_asserts(v != 0)));
    imports.define("env", "rt_host_runtime_error", Function::new_typed(store, || openmodelica_sim_meta::driver::note_runtime_error_flag()));
    // The wasmer host has no external-library loader, so the flag has nowhere to go.
    imports.define("env", "rt_host_rhs_final", Function::new_typed(store, |_v: i32| {}));
    // See the wasmtime counterpart.
    imports.define(
        "env",
        "rt_host_take_warnings",
        Function::new_typed_with_env(
            store,
            &mem_env,
            |mut env: wasmer::FunctionEnvMut<HostEnv>, ptr: u32, max: u32| -> u32 {
                let (data, store) = env.data_and_store_mut();
                let Some(memory) = data.mem.clone() else { return 0 };
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
    imports.define(
        "env",
        "rt_host_take_reinits",
        Function::new_typed_with_env(
            store,
            &mem_env,
            |mut env: wasmer::FunctionEnvMut<HostEnv>, ptr: u32, max: u32| -> u32 {
                let (data, store) = env.data_and_store_mut();
                let Some(memory) = data.mem.clone() else { return 0 };
                let mut buf = vec![0u8; max as usize * REINIT_BYTES];
                let n = take_reinits_into(&mut buf, max as usize);
                match memory.view(&store).write(ptr as u64, &buf[..n as usize * REINIT_BYTES]) {
                    Ok(()) => n,
                    Err(_) => 0,
                }
            },
        ),
    );
    Ok(HostMem(mem_env))
}

/// The wasmer counterpart of [`define_uri_import`] (wasmtime): see there.
#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
pub fn define_uri_import(
    store: &mut wasmer::Store,
    imports: &mut wasmer::Imports,
    memory: &wasmer::Memory,
    str_new: &wasmer::TypedFunction<u32, u32>,
    str_data: &wasmer::TypedFunction<u32, u32>,
) {
    use wasmer::{Function, FunctionEnv, FunctionEnvMut, RuntimeError};
    struct Env {
        memory: wasmer::Memory,
        str_new: wasmer::TypedFunction<u32, u32>,
        str_data: wasmer::TypedFunction<u32, u32>,
    }
    let env = FunctionEnv::new(
        &mut *store,
        Env { memory: memory.clone(), str_new: str_new.clone(), str_data: str_data.clone() },
    );
    let f = Function::new_typed_with_env(
        &mut *store,
        &env,
        |mut env: FunctionEnvMut<Env>, handle: u32, _fmu: i32| -> std::result::Result<u32, RuntimeError> {
            let (data, mut store) = env.data_and_store_mut();
            let (memory, str_new, str_data) = (data.memory.clone(), data.str_new.clone(), data.str_data.clone());
            // String layout: [refcount:u32][len:u32][utf8].
            let view = memory.view(&store);
            let mut lenb = [0u8; 4];
            let mut uri = Vec::new();
            if handle != 0 && view.read(handle as u64 + 4, &mut lenb).is_ok() {
                uri = vec![0u8; u32::from_le_bytes(lenb) as usize];
                view.read(handle as u64 + 8, &mut uri).map_err(|e| RuntimeError::new(e.to_string()))?;
            }
            let path = uri_to_filename(&String::from_utf8_lossy(&uri)).map_err(RuntimeError::new)?;
            let out = str_new.call(&mut store, path.len() as u32)?;
            let at = str_data.call(&mut store, out)?;
            memory
                .view(&store)
                .write(at as u64, path.as_bytes())
                .map_err(|e| RuntimeError::new(e.to_string()))?;
            Ok(out)
        },
    );
    imports.define("rt", "rt_uri_to_filename", f);
}

/// libc's `stdout`, where a host `external "C"` prints, is a different buffer
/// from ours; flush both around a call so the two stay in order.
pub fn flush_stdio() {
    use std::io::Write;
    let _ = std::io::stdout().flush();
    #[cfg(not(target_arch = "wasm32"))]
    unsafe {
        libc::fflush(std::ptr::null_mut());
    }
}

/// Redirect the process's stdout/stderr into the run's log for one capture phase
/// (`openmodelica_wasi::wasi::set_native_capture`). A temp file, not a pipe, which
/// would deadlock on its buffer with nothing draining it; `fflush(NULL)` empties
/// libc's own buffers into it before each read.
#[cfg(not(target_arch = "wasm32"))]
pub mod native_stdout {
    use std::cell::RefCell;

    /// Raw CRT fds throughout: a `File` must not own the same one, or both close it.
    struct Redirect {
        fd: i32,
        saved_out: i32,
        saved_err: i32,
    }

    thread_local! {
        static ACTIVE: RefCell<Option<Redirect>> = const { RefCell::new(None) };
    }

    pub fn install() {
        openmodelica_wasi::wasi::set_native_capture(openmodelica_wasi::wasi::NativeCapture {
            begin,
            write,
            end,
        });
    }

    /// C's `messageText`: written whole and now, so our log lines and a `dlopen`ed
    /// external's own output reach the log in the order the two produced them.
    /// To the capture's own fd, which fds 1 and 2 are dups of: fd 1 may be
    /// redirected on top of ours, as the Ipopt solve pipes it.
    fn write(bytes: &[u8], _is_err: bool) -> bool {
        let Some(fd) = ACTIVE.with(|a| a.borrow().as_ref().map(|r| r.fd)) else {
            return false;
        };
        let mut rest = bytes;
        unsafe {
            // Whatever an external left in libc's buffers happened before this line.
            libc::fflush(std::ptr::null_mut());
            while !rest.is_empty() {
                let n = libc::write(fd, rest.as_ptr() as *const _, rest.len());
                if n <= 0 {
                    break;
                }
                rest = &rest[n as usize..];
            }
        }
        true
    }

    fn begin() {
        ACTIVE.with(|a| {
            let mut a = a.borrow_mut();
            if a.is_some() {
                return;
            }
            let Some(fd) = scratch_fd() else { return };
            unsafe {
                let (saved_out, saved_err) = (libc::dup(1), libc::dup(2));
                if saved_out < 0 || saved_err < 0 {
                    libc::close(fd);
                    return;
                }
                libc::fflush(std::ptr::null_mut());
                libc::dup2(fd, 1);
                libc::dup2(fd, 2);
                *a = Some(Redirect { fd, saved_out, saved_err });
            }
        });
    }

    fn end() -> Vec<u8> {
        ACTIVE.with(|a| {
            let Some(r) = a.borrow_mut().take() else { return Vec::new() };
            let mut out = Vec::new();
            unsafe {
                libc::fflush(std::ptr::null_mut());
                libc::dup2(r.saved_out, 1);
                libc::dup2(r.saved_err, 2);
                libc::close(r.saved_out);
                libc::close(r.saved_err);
                libc::lseek(r.fd, 0, libc::SEEK_SET);
                let mut buf = [0u8; 8192];
                loop {
                    let n = libc::read(r.fd, buf.as_mut_ptr() as *mut _, buf.len() as _);
                    if n <= 0 {
                        break;
                    }
                    out.extend_from_slice(&buf[..n as usize]);
                }
                libc::close(r.fd);
            }
            out
        })
    }

    /// A file only this redirect can reach: unlinked at once on unix, delete-on-close
    /// on Windows, where an open file cannot be unlinked.
    fn scratch_fd() -> Option<i32> {
        let path = std::env::temp_dir().join(format!("om-simout-{}", std::process::id()));
        let mut opts = std::fs::File::options();
        opts.read(true).write(true).create(true).truncate(true);
        #[cfg(windows)]
        {
            use std::os::windows::fs::OpenOptionsExt;
            const FILE_FLAG_DELETE_ON_CLOSE: u32 = 0x0400_0000;
            opts.custom_flags(FILE_FLAG_DELETE_ON_CLOSE);
        }
        let file = opts.open(&path).ok()?;
        #[cfg(unix)]
        {
            let _ = std::fs::remove_file(&path);
            Some(std::os::fd::IntoRawFd::into_raw_fd(file))
        }
        // `_open_osfhandle` takes the handle over, so `File` must give it up first.
        #[cfg(windows)]
        {
            let h = std::os::windows::io::IntoRawHandle::into_raw_handle(file);
            match unsafe { libc::open_osfhandle(h as isize, 0) } {
                fd if fd >= 0 => Some(fd),
                _ => None,
            }
        }
    }
}

/// The browser has no process stdout to redirect.
#[cfg(target_arch = "wasm32")]
pub mod native_stdout {
    pub fn install() {}
}

/// A guest path as the host sees it: the simulation's WASI cwd is the preopen
/// root, so a name a flag gave relative to omc's own working directory has to be
/// resolved before it crosses into the module.
pub fn absolute_path(path: &str) -> String {
    let p = std::path::Path::new(path);
    if p.is_absolute() {
        return path.to_string();
    }
    match std::env::current_dir() {
        Ok(dir) => dir.join(p).to_string_lossy().into_owned(),
        Err(_) => path.to_string(),
    }
}
