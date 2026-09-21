//! One linear or nonlinear system's solver statistics, as C keeps them in
//! `LINEAR_SYSTEM_DATA` / `NONLINEAR_SYSTEM_DATA` and prints them under
//! `LOG_STATS_V`.
//!
//! Measured wherever the systems are solved: in the wasm runtime for `wasm-jit`,
//! in this process for the C runtime. A wasm-hosted run hands the table to its
//! host as a flat `f64` array, so the word order lives here with the struct.

/// `f64` words one system occupies in that array.
pub const WORDS: usize = 10;

#[derive(Clone, Copy, Default, PartialEq, Debug)]
pub struct SysStat {
    /// The system's equation index, which is how C names it in the log.
    pub eq_index: i32,
    pub nonlinear: bool,
    pub size: u32,
    pub nnz: u32,
    pub calls: u64,
    /// Nonlinear only: C's `numberOfIterations` / `numberOfFEval` / `numberOfJEval`.
    pub iters: u64,
    pub res_evals: u64,
    pub jac_evals: u64,
    /// Seconds in the system, and the share of that spent assembling its Jacobian.
    pub total: f64,
    pub jac: f64,
}

impl SysStat {
    pub fn to_words(&self) -> [f64; WORDS] {
        [
            self.eq_index as f64,
            self.nonlinear as u32 as f64,
            self.size as f64,
            self.nnz as f64,
            self.calls as f64,
            self.iters as f64,
            self.res_evals as f64,
            self.jac_evals as f64,
            self.total,
            self.jac,
        ]
    }

    pub fn from_words(w: &[f64]) -> Self {
        SysStat {
            eq_index: w[0] as i32,
            nonlinear: w[1] != 0.0,
            size: w[2] as u32,
            nnz: w[3] as u32,
            calls: w[4] as u64,
            iters: w[5] as u64,
            res_evals: w[6] as u64,
            jac_evals: w[7] as u64,
            total: w[8],
            jac: w[9],
        }
    }
}

/// Decode a whole published table.
pub fn decode(words: &[f64]) -> alloc::vec::Vec<SysStat> {
    words.chunks_exact(WORDS).map(SysStat::from_words).collect()
}

// ---------------------------------------------------------------------------
// The table, as C brackets each solve
// ---------------------------------------------------------------------------

// C's `numberOfCall`, `totalTime`, `jacobianTime` (and the nonlinear iteration /
// evaluation counts), which `LOG_STATS_V` renders as its "linear systems" and
// "non-linear systems" sections. Off unless a run turned it on (`enable`) --
// every bracket costs two clock reads, which on a host-driven wasm run are calls
// out of wasm.

use alloc::collections::BTreeMap;
use alloc::vec::Vec;
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
    /// `sys` is indexed by equation, not scanned: a model with one system per
    /// discretization volume solves O(n) of them per `functionODE`, so a scan
    /// would make the bracket itself quadratic in the model.
    index: BTreeMap<(i32, bool), usize>,
    open: Vec<Open>,
    /// Flattened [`SysStat::to_words`], kept alive for a wasm host to read out of
    /// linear memory.
    words: Vec<f64>,
}

struct Store(UnsafeCell<Table>);
unsafe impl Sync for Store {}
static TABLE: Store =
    Store(UnsafeCell::new(Table {
        on: false,
        sys: Vec::new(),
        index: BTreeMap::new(),
        open: Vec::new(),
        words: Vec::new(),
    }));

#[inline]
fn table() -> &'static mut Table {
    unsafe { &mut *TABLE.0.get() }
}

#[inline]
fn now_ms() -> f64 {
    crate::clock::now_ms()
}

/// Start measuring (or stop, and forget what the last run recorded).
pub fn enable(on: bool) {
    let t = table();
    t.on = on;
    t.sys.clear();
    t.index.clear();
    t.open.clear();
    t.words.clear();
}

#[inline]
pub fn enabled() -> bool {
    table().on
}

fn slot(eq_index: i32, nonlinear: bool, size: u32, nnz: u32) -> usize {
    let t = table();
    if let Some(&i) = t.index.get(&(eq_index, nonlinear)) {
        return i;
    }
    t.sys.push(SysStat { eq_index, nonlinear, size, nnz, ..SysStat::default() });
    let i = t.sys.len() - 1;
    t.index.insert((eq_index, nonlinear), i);
    i
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

/// The measured table.
pub fn systems() -> &'static [SysStat] {
    &table().sys
}

/// Flatten the table for a wasm host; valid until the next call.
pub fn publish_words() -> &'static [f64] {
    let t = table();
    t.words.clear();
    for s in &t.sys {
        t.words.extend_from_slice(&s.to_words());
    }
    &t.words
}
