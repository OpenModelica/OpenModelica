//! C's per-system solver statistics: `LINEAR_SYSTEM_DATA` / `NONLINEAR_SYSTEM_DATA`'s
//! `numberOfCall`, `totalTime`, `jacobianTime` (and the nonlinear iteration /
//! evaluation counts), which `LOG_STATS_V` renders as its "linear systems" and
//! "non-linear systems" sections.
//!
//! The systems are solved in-wasm whichever driver owns the run, so this is where
//! they are measured; the host reads the table back through
//! [`rt_sys_stats_ptr`]/[`rt_sys_stats_len`] and formats it. Off unless the host
//! turned it on (`rt_stats_start`) — every bracket costs two clock reads, which on
//! a host-driven run are calls out of wasm.

use alloc::vec::Vec;
use openmodelica_sim_meta::sysstat::{SysStat, WORDS};

use core::cell::UnsafeCell;

/// A system entered and not yet left. C counts the iterations and evaluations of a
/// *nested* system (a medium inversion inside a flow residual) against that system
/// alone, so a frame remembers what its children took and the parent subtracts it.
/// The clocks are wall time and do nest, as C's do.
struct Open {
    slot: usize,
    start: f64,
    jac: f64,
    child: [u64; 3],
}

struct Table {
    on: bool,
    sys: Vec<SysStat>,
    open: Vec<Open>,
    /// Flattened [`SysStat::to_words`], kept alive for the host to read out of
    /// linear memory.
    words: Vec<f64>,
}

struct Store(UnsafeCell<Table>);
unsafe impl Sync for Store {}
static TABLE: Store =
    Store(UnsafeCell::new(Table { on: false, sys: Vec::new(), open: Vec::new(), words: Vec::new() }));

#[inline]
fn table() -> &'static mut Table {
    unsafe { &mut *TABLE.0.get() }
}

#[inline]
fn now_ms() -> f64 {
    openmodelica_sim_meta::driver::now_ms_host()
}

/// Start measuring (or stop, and forget what the last run recorded).
pub fn enable(on: bool) {
    let t = table();
    t.on = on;
    t.sys.clear();
    t.open.clear();
    t.words.clear();
}

#[inline]
pub fn enabled() -> bool {
    table().on
}

fn slot(eq_index: i32, nonlinear: bool, size: u32, nnz: u32) -> usize {
    let t = table();
    if let Some(i) = t.sys.iter().position(|s| s.eq_index == eq_index && s.nonlinear == nonlinear) {
        return i;
    }
    t.sys.push(SysStat { eq_index, nonlinear, size, nnz, ..SysStat::default() });
    t.sys.len() - 1
}

/// Enter a system — C's `rt_ext_tp_tick(&linsys->totalTimeClock)` at the top of
/// `solve_linear_system` / `solve_nonlinear_system`.
pub fn begin(eq_index: i32, nonlinear: bool, size: u32, nnz: u32) {
    if !enabled() {
        return;
    }
    let i = slot(eq_index, nonlinear, size, nnz);
    table().open.push(Open { slot: i, start: now_ms(), jac: 0.0, child: [0; 3] });
}

/// A linear system's `A` and `b` are assembled by the generated code ahead of the
/// solve, so the solve entry points are where C's `jacobianTime` ends. First mark
/// wins: a rejected step re-enters the solver within the same call.
pub fn mark_assembly_done() {
    if !enabled() {
        return;
    }
    let t = table();
    let Some(f) = t.open.last_mut() else { return };
    if f.jac == 0.0 && !t.sys[f.slot].nonlinear {
        f.jac = now_ms() - f.start;
    }
}

/// Add a nonlinear system's Jacobian time — C's `nlsData->jacobianTimeClock`, which
/// brackets each assembly rather than ending at the solve.
pub fn add_jacobian_time(ms: f64) {
    if !enabled() {
        return;
    }
    if let Some(f) = table().open.last_mut() {
        f.jac += ms;
    }
}

/// Leave the innermost system, charging it the elapsed time and one call. The
/// counts are C's `numberOfIterations` / `numberOfFEval` / `numberOfJEval` as run
/// totals since [`begin`]; what a nested system took is moved to it.
pub fn end(counts: [u64; 3]) {
    if !enabled() {
        return;
    }
    let t = table();
    let Some(f) = t.open.pop() else { return };
    let s = &mut t.sys[f.slot];
    s.calls += 1;
    s.total += (now_ms() - f.start) / 1000.0;
    s.jac += f.jac / 1000.0;
    s.iters += counts[0] - f.child[0];
    s.res_evals += counts[1] - f.child[1];
    s.jac_evals += counts[2] - f.child[2];
    if let Some(p) = t.open.last_mut() {
        for k in 0..3 {
            p.child[k] += counts[k];
        }
    }
}

/// A clock read while measuring, for a bracket that times a sub-region itself.
#[inline]
pub fn tick() -> f64 {
    if enabled() { now_ms() } else { 0.0 }
}

/// Flatten the table for the host and return its address; valid until the next
/// call. Paired with [`rt_sys_stats_len`].
#[unsafe(no_mangle)]
pub extern "C" fn rt_sys_stats_ptr() -> u32 {
    let t = table();
    t.words.clear();
    for s in &t.sys {
        t.words.extend_from_slice(&s.to_words());
    }
    t.words.as_ptr() as u32
}

/// Number of `f64` words [`rt_sys_stats_ptr`] published (`WORDS` per system).
#[unsafe(no_mangle)]
pub extern "C" fn rt_sys_stats_len() -> u32 {
    (table().sys.len() * WORDS) as u32
}
