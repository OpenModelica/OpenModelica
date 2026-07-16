//! In-wasm simulation session (`rt_sim_*` ABI), for the no_std JIT runtime
//! (`wasm32-unknown-unknown`).
//!
//! The host instantiates the runtime + model sharing one linear memory, appends
//! the model's equation-function exports to the shared `__indirect_function_table`
//! at a fixed slot order, and then drives the run entirely in-wasm through these
//! exports. The shared [`openmodelica_sim_meta::driver`] reaches the model via
//! `call_indirect` (wasm->wasm, no host boundary per residual) instead of the
//! host calling each `functionODE`/Jacobian column through the wasm engine.
//!
//! Rows/params are captured into `rt_alloc`'d buffers (no WASI, no `.mat` here);
//! the host reads them back via the accessor exports.

use alloc::boxed::Box;
use alloc::vec::Vec;
use core::cell::UnsafeCell;

use openmodelica_sim_meta::WTy;
use openmodelica_sim_meta::driver::{self, Advance, Driver, SimEngine};
use openmodelica_sim_meta::{SimMeta, SolveStats};

// Host imports for the per-chunk budget clock and the cooperative cancel poll.
// Polled O(steps) times (per output row / DASSL segment), not per residual, so
// these few host crossings are negligible next to the ~35k model calls they
// replace with wasm->wasm `call_indirect`s.
#[link(wasm_import_module = "env")]
unsafe extern "C" {
    fn rt_host_now_ms() -> f64;
    fn rt_host_cancel() -> i32;
}

fn now_ms_hook() -> f64 {
    unsafe { rt_host_now_ms() }
}
fn cancel_hook() -> bool {
    unsafe { rt_host_cancel() != 0 }
}

// Fixed table-slot order the host populates (relative to `fn_base`). The runtime
// reaches slot `s` via `call_indirect(fn_base + s)`. Absent exports (optional
// hooks, or functions a model without events/state-sets does not emit) get a
// cleared `present_mask` bit.
const SLOT_PARAMETERS: u32 = 0;
const SLOT_INIT_START: u32 = 1;
const SLOT_INIT_EQ: u32 = 2;
const SLOT_ODE: u32 = 3;
const SLOT_ALGEBRAICS: u32 = 4;
const SLOT_STATE_SET_JAC: u32 = 5;
const SLOT_ZERO_CROSSINGS: u32 = 6;
const SLOT_INIT_SAMPLE: u32 = 7;
const SLOT_SIMULATE: u32 = 8;
const SLOT_EXT_DESTRUCT: u32 = 9;
const SLOT_INIT_EQ_LAMBDA0: u32 = 10;
/// Number of table slots the host must populate (in the order above). The host
/// (a separate crate) mirrors this count and order in its table wiring.
#[allow(dead_code)]
pub const N_SLOTS: u32 = 11;

fn slot_of(name: &str) -> Option<u32> {
    Some(match name {
        "functionParameters" => SLOT_PARAMETERS,
        "functionInitStartValues" => SLOT_INIT_START,
        "functionInitialEquations" => SLOT_INIT_EQ,
        "functionInitialEquations_lambda0" => SLOT_INIT_EQ_LAMBDA0,
        "functionODE" => SLOT_ODE,
        "functionAlgebraics" => SLOT_ALGEBRAICS,
        "functionStateSetJacobians" => SLOT_STATE_SET_JAC,
        "functionZeroCrossings" => SLOT_ZERO_CROSSINGS,
        "initSample" => SLOT_INIT_SAMPLE,
        "callExternalObjectDestructors" => SLOT_EXT_DESTRUCT,
        _ => return None,
    })
}

/// In-wasm [`SimEngine`]: linear memory is directly addressable (the runtime *is*
/// in it), and model functions are reached by `call_indirect` over the shared
/// table. A fn-pointer value is its table index on wasm, so a `transmute` + call
/// lowers to `call_indirect` of the matching type (as `rt_call1_indirect` /
/// `rt_solve_nls` already do).
struct InWasmEngine {
    fn_base: u32,
    present_mask: u32,
}

impl InWasmEngine {
    fn present(&self, slot: u32) -> bool {
        self.present_mask & (1 << slot) != 0
    }
}

impl SimEngine for InWasmEngine {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> driver::Result<()> {
        let src = unsafe { core::slice::from_raw_parts(addr as *const u8, buf.len()) };
        buf.copy_from_slice(src);
        Ok(())
    }
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> driver::Result<()> {
        let dst = unsafe { core::slice::from_raw_parts_mut(addr as *mut u8, buf.len()) };
        dst.copy_from_slice(buf);
        Ok(())
    }
    fn call1(&mut self, name: &str, arg: u32) -> driver::Result<()> {
        let slot = slot_of(name).ok_or("in-wasm engine: unknown model function")?;
        if !self.present(slot) {
            return Err("in-wasm engine: required model function not exported");
        }
        let idx = self.fn_base + slot;
        let f: extern "C" fn(u32) = unsafe { core::mem::transmute(idx as usize) };
        f(arg);
        Ok(())
    }
    fn call1_if_present(&mut self, name: &str, arg: u32) -> driver::Result<()> {
        let slot = match slot_of(name) {
            Some(s) => s,
            None => return Ok(()),
        };
        if self.present(slot) {
            self.call1(name, arg)?;
        }
        Ok(())
    }
    fn call_simulate(&mut self, sim_data: u32, start: f64, stop: f64, n_steps: u32) -> driver::Result<u32> {
        if !self.present(SLOT_SIMULATE) {
            return Err("in-wasm engine: no `simulate` export");
        }
        let idx = self.fn_base + SLOT_SIMULATE;
        let f: extern "C" fn(u32, f64, f64, u32) -> u32 = unsafe { core::mem::transmute(idx as usize) };
        Ok(f(sim_data, start, stop, n_steps))
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 7]> {
        // The model imports `rt_assert` from the host; a failed assert traps and
        // unwinds out of `rt_sim_advance` to the host, which reports it. Nothing
        // to take in-wasm.
        None
    }
}

/// One resumable in-wasm run: engine, driver, decoded model view, and the result
/// buffers filled on completion. Single-threaded, so a plain `static` cell holds
/// it across the `rt_sim_advance` calls.
struct Session {
    engine: InWasmEngine,
    driver: Box<dyn Driver>,
    model: SimMeta,
    sim_data: u32,
    n_reals: u32,
    finished: bool,
    rows: Vec<f64>,
    params: Vec<f64>,
    stats: SolveStats,
}

struct SessionCell(UnsafeCell<Option<Session>>);
unsafe impl Sync for SessionCell {}
static SESSION: SessionCell = SessionCell(UnsafeCell::new(None));

fn session() -> &'static mut Option<Session> {
    unsafe { &mut *SESSION.0.get() }
}

/// Set the parameter/start overrides for the next [`rt_sim_start`]. The host's own
/// `set_param_overrides` cannot reach this module's copy of the store, so it must
/// hand them over: `n_params: u32`, that many `(off: u32, wty: u32, val: f64)`,
/// then `n_starts: u32` and the same again. `wty` is 0 = f64, 1 = i32.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_set_overrides(ptr: u32, len: u32) -> i32 {
    let bytes = unsafe { core::slice::from_raw_parts(ptr as *const u8, len as usize) };
    let mut p = 0usize;
    let mut u32_at = |p: &mut usize| -> Option<u32> {
        let v = bytes.get(*p..*p + 4)?;
        *p += 4;
        Some(u32::from_le_bytes(v.try_into().ok()?))
    };
    let mut group = |p: &mut usize| -> Option<Vec<(u32, WTy, f64)>> {
        let n = u32_at(p)? as usize;
        let mut out = Vec::with_capacity(n);
        for _ in 0..n {
            let off = u32_at(p)?;
            let wty = if u32_at(p)? == 0 { WTy::F64 } else { WTy::I32 };
            let raw = bytes.get(*p..*p + 8)?;
            *p += 8;
            out.push((off, wty, f64::from_le_bytes(raw.try_into().ok()?)));
        }
        Some(out)
    };
    match (group(&mut p), group(&mut p)) {
        (Some(params), Some(starts)) => {
            openmodelica_sim_meta::driver::set_param_overrides(params, starts);
            0
        }
        _ => -1,
    }
}

/// Start a resumable in-wasm run. `meta_ptr`/`meta_len` point at the model's
/// encoded [`SimMeta`] blob (its `om_meta` segment); `fn_base` is the first table
/// slot the host populated with the model's exports (in `N_SLOTS` order);
/// `present_mask` bit `s` is set iff slot `s` holds a real funcref. Returns 0 on
/// success, <0 on error.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_start(meta_ptr: u32, meta_len: u32, fn_base: u32, present_mask: u32) -> i32 {
    // Any prior session is dropped (frees its buffers) before starting a new one.
    *session() = None;

    let bytes = unsafe { core::slice::from_raw_parts(meta_ptr as *const u8, meta_len as usize) };
    let model = match openmodelica_sim_meta::decode(bytes) {
        Ok(m) => m,
        Err(_) => return -1,
    };

    driver::set_clock(now_ms_hook);
    driver::set_cancel_hook(cancel_hook);

    let mut engine = InWasmEngine { fn_base, present_mask };
    let sim_data = crate::rt_alloc(model.layout.total);
    let n_reals = model.layout.n_row_total();

    let method = model.method.clone();
    let driver = match driver::make_driver(&mut engine, &model, sim_data, method.as_str()) {
        Ok((d, _label)) => d,
        Err(_) => return -2,
    };

    *session() = Some(Session {
        engine,
        driver,
        model,
        sim_data,
        n_reals,
        finished: false,
        rows: Vec::new(),
        params: Vec::new(),
        stats: SolveStats::default(),
    });
    0
}

/// Integrate for about `budget_ms` of wall-clock (`+inf` runs to completion),
/// then return. Status: 0 running, 1 done, 2 terminated, 3 cancelled, <0 error.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_advance(budget_ms: f64) -> i32 {
    let Some(s) = session().as_mut() else {
        return -1;
    };
    if s.finished {
        return 1;
    }
    let adv = {
        let Session { engine, driver, model, .. } = &mut *s;
        driver.advance(engine, model, budget_ms)
    };
    match adv {
        Ok(Advance::Running) => 0,
        Ok(done @ (Advance::Done | Advance::Terminated)) => {
            finish(s);
            if matches!(done, Advance::Terminated) { 2 } else { 1 }
        }
        Ok(Advance::Cancelled) => {
            let _ = driver::finalize_run(&mut s.engine, &s.model, s.sim_data);
            3
        }
        Err(_) => -2,
    }
}

/// Capture rows, stats and parameter values after the run completes.
fn finish(s: &mut Session) {
    s.stats = SolveStats::default();
    s.driver.fill_stats(&s.model, &mut s.stats);
    s.rows = s.driver.take_rows();
    s.params = driver::finalize_run(&mut s.engine, &s.model, s.sim_data).unwrap_or_default();
    s.finished = true;
}

/// Drop the active session (frees its buffers). Safe with no session.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_free() {
    *session() = None;
}

// Result accessors — valid only once `rt_sim_advance` returned done/terminated
// and until `rt_sim_free`. Pointers are linear-memory offsets into `rt_alloc`'d
// buffers the host reads directly.

#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_rows_ptr() -> u32 {
    session().as_ref().map_or(0, |s| s.rows.as_ptr() as u32)
}
/// Number of `f64` elements in the rows buffer (`n_rows * n_reals`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_rows_len() -> u32 {
    session().as_ref().map_or(0, |s| s.rows.len() as u32)
}
/// Columns per row (`SimLayout::n_row_total`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_n_reals() -> u32 {
    session().as_ref().map_or(0, |s| s.n_reals)
}
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_params_ptr() -> u32 {
    session().as_ref().map_or(0, |s| s.params.as_ptr() as u32)
}
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_params_len() -> u32 {
    session().as_ref().map_or(0, |s| s.params.len() as u32)
}

// Solver statistics, for the host bench line (steps, evals, events).
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_stat(which: u32) -> u64 {
    session().as_ref().map_or(0, |s| match which {
        0 => s.stats.steps,
        1 => s.stats.res_evals,
        2 => s.stats.jac_evals,
        3 => s.stats.err_test_fails,
        4 => s.stats.conv_test_fails,
        5 => s.stats.state_events,
        6 => s.stats.time_events,
        _ => 0,
    })
}
