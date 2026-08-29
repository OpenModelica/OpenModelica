//! Diagnostic counters the nonlinear ladder keeps, read back by the wasm-jit
//! bench line (`OMC_WASM_SIM_BENCH`, `rt_stat`) and by [`crate::sysstat`], which
//! charges a system the iterations and evaluations made inside it.
//!
//! Indices are an ABI: a wasm host reads them by number.

use core::sync::atomic::{AtomicU64, Ordering};

/// The wasm-jit runtime's allocator, which owns these four and [`STAT_ELEM_PTR`].
pub const STAT_ALLOC: u32 = 0;
pub const STAT_ARRAY_NEW: u32 = 1;
pub const STAT_RECORD_NEW: u32 = 2;
pub const STAT_STR_NEW: u32 = 3;
pub const STAT_NLS_SOLVE: u32 = 4;
pub const STAT_NLS_RES: u32 = 5;
pub const STAT_NLS_JAC: u32 = 6;
pub const STAT_NLS_FAIL: u32 = 7;
pub const STAT_NLS_RETRY: u32 = 8;
pub const STAT_ELEM_PTR: u32 = 9;
pub const STAT_NLS_ITER: u32 = 10;
pub const STAT_NLS_NEWTON_FAIL: u32 = 11;
pub const STAT_NLS_GUESS_HIT: u32 = 12;
pub const STAT_NLS_ACCEPT: u32 = 13;
pub const STAT_NLS_STORE_BACK: u32 = 14;
pub const STAT_NLS_VARY_START: u32 = 15;
pub const STAT_NLS_STALE: u32 = 16;
/// Why `newton_c` (C's `newtonAlgorithm`) gave up, so a run can be compared against
/// C's own fallback count without a rebuild.
pub const STAT_NEWTON_IRREGULAR: u32 = 17;
pub const STAT_NEWTON_LAMBDA: u32 = 18;
pub const STAT_NEWTON_NEGSTEP: u32 = 19;
pub const STAT_NEWTON_MAXITER: u32 = 20;
pub const STAT_NEWTON_STUCK: u32 = 21;
pub const STAT_NEWTON_JAC: u32 = 22;
pub const STAT_NEWTON_SINGULAR: u32 = 23;
/// Not a diagnostic: C's `homotopySteps`, which the driver folds into the
/// initialization success line.
pub const STAT_HOMOTOPY_STEPS: u32 = 24;
pub const N_STATS: usize = 25;

static STATS: [AtomicU64; N_STATS] = [const { AtomicU64::new(0) }; N_STATS];

#[inline]
pub fn stat_inc(kind: u32) {
    STATS[kind as usize].fetch_add(1, Ordering::Relaxed);
}

#[inline]
pub fn stat_add(kind: u32, n: u64) {
    STATS[kind as usize].fetch_add(n, Ordering::Relaxed);
}

#[inline]
pub fn stat(kind: u32) -> u64 {
    match STATS.get(kind as usize) {
        Some(c) => c.load(Ordering::Relaxed),
        None => 0,
    }
}

/// Called per run, so the counters are per-run.
pub fn reset() {
    for c in STATS.iter() {
        c.store(0, Ordering::Relaxed);
    }
}
