//! C's `rtclock.c` simulation timers — the accumulators `LOG_STATS` renders.
//!
//! Clock indices and tick placement follow the C runtime one for one, so a
//! `-lv=LOG_STATS` block from either target splits the run the same way. As in C
//! the timers only run when the block will be printed (`measure_time_flag`, which
//! `LOG_STATS`/`-cpu` raise); [`enabled`] gates every tick site.
//!
//! `STEP` and `OVERHEAD` have no tick site in the C runtime either — they are
//! printed, and stay zero.

use crate::driver::now_ms_host;

pub const TOTAL: usize = 0;
pub const INIT: usize = 1;
pub const STEP: usize = 2;
pub const OUTPUT: usize = 3;
pub const EVENT: usize = 4;
pub const JACOBIAN: usize = 5;
pub const PREINIT: usize = 6;
pub const OVERHEAD: usize = 7;
pub const FUNCTION_ODE: usize = 8;
pub const RESIDUALS: usize = 9;
pub const ALGEBRAICS: usize = 10;
pub const ZC: usize = 11;
pub const SOLVER: usize = 12;
pub const INIT_XML: usize = 13;
pub const INFO_XML: usize = 14;
pub const DAE: usize = 15;
/// C keeps these two as `callStatistics` counters rather than clocks; they have no
/// time, only a call count, and `LOG_STATS_V` prints them beside the clocked ones.
pub const ZC_EQUATIONS: usize = 16;
pub const DISCRETE: usize = 17;
pub const N: usize = 18;

/// One run's clocks: seconds accumulated, the open tick, and the call count
/// [`accumulate`] closed.
#[derive(Clone, Copy)]
struct Clocks {
    on: bool,
    tick: [f64; N],
    acc: [f64; N],
    ncall: [u64; N],
    /// C's `total_tp` / `max_tp` / `rt_clock_ncall_total`, fed by [`clear`].
    total: [f64; N],
    max: [f64; N],
    ncall_total: [u64; N],
}

const EMPTY: Clocks =
    Clocks { on: false, tick: [0.0; N], acc: [0.0; N], ncall: [0; N], total: [0.0; N], max: [0.0; N], ncall_total: [0; N] };

// The driver is single-threaded per run (as is the in-wasm session), so a plain
// cell is enough and keeps `tick` off the atomics.
struct Store(core::cell::UnsafeCell<Clocks>);
unsafe impl Sync for Store {}
static CLOCKS: Store = Store(core::cell::UnsafeCell::new(EMPTY));

#[inline]
fn clocks() -> &'static mut Clocks {
    unsafe { &mut *CLOCKS.0.get() }
}

/// Start a run's measurement (C's `measure_time_flag` block in
/// `startNonInteractiveSimulation`), or leave every timer off and zero.
pub fn reset(on: bool) {
    *clocks() = Clocks { on, ..EMPTY };
}

#[inline]
pub fn enabled() -> bool {
    clocks().on
}

/// C's `rt_tick`: open the clock and count the call.
#[inline]
pub fn tick(ix: usize) {
    let c = clocks();
    if c.on {
        c.tick[ix] = now_ms_host();
        c.ncall[ix] += 1;
    }
}

/// C's `rt_accumulate`: close the clock opened by [`tick`].
#[inline]
pub fn accumulate(ix: usize) {
    let c = clocks();
    if c.on {
        c.acc[ix] += now_ms_host() - c.tick[ix];
    }
}

/// C's `rt_ncall`.
pub fn ncall(ix: usize) -> u64 {
    clocks().ncall[ix]
}

/// C's `rt_clear`: the clock's share since the last clear joins the run's total
/// and maximum, and it starts over.
pub fn clear(ix: usize) {
    let c = clocks();
    c.total[ix] += c.acc[ix];
    c.ncall_total[ix] += c.ncall[ix];
    if c.acc[ix] > c.max[ix] {
        c.max[ix] = c.acc[ix];
    }
    c.acc[ix] = 0.0;
    c.ncall[ix] = 0;
}

/// C's `rt_accumulated`, in seconds.
pub fn accumulated(ix: usize) -> f64 {
    clocks().acc[ix] / 1000.0
}

/// C's `rt_total`, in seconds.
pub fn total(ix: usize) -> f64 {
    clocks().total[ix] / 1000.0
}

/// C's `rt_max_accumulated`, in seconds.
pub fn max_accumulated(ix: usize) -> f64 {
    clocks().max[ix] / 1000.0
}

/// C's `rt_ncall_total`.
pub fn ncall_total(ix: usize) -> u64 {
    clocks().ncall_total[ix]
}

/// C's `solver_main` head: pre-initialization ends where initialization begins.
/// Idempotent, so a second initialization pass (a homotopy retry, an FMI reset)
/// does not charge the gap before the first one all over again.
pub fn enter_init() {
    if ncall(INIT) == 0 {
        accumulate(PREINIT);
    }
    tick(INIT);
}

/// Every clock as `(seconds, calls)`, for the snapshot that travels with
/// [`crate::SolveStats`] out of an in-wasm run.
pub fn snapshot() -> ([f64; N], [u64; N]) {
    let c = clocks();
    let mut secs = [0.0f64; N];
    for (s, a) in secs.iter_mut().zip(c.acc.iter()) {
        *s = a / 1000.0;
    }
    (secs, c.ncall)
}

/// `rt_sim_stat` slot holding clock `ix`'s seconds (as `f64::to_bits`), and the one
/// holding its call count. The in-wasm session has no other way out; the solver
/// counters occupy the slots below [`STAT_SLOT_BASE`].
pub const STAT_SLOT_BASE: u32 = 8;
const fn stat_slot_secs(ix: usize) -> u32 {
    STAT_SLOT_BASE + ix as u32
}
const fn stat_slot_calls(ix: usize) -> u32 {
    STAT_SLOT_BASE + N as u32 + ix as u32
}

/// Read a snapshot back out of an in-wasm session's `rt_sim_stat` — the host side
/// of [`stat_slot_secs`].
pub fn read_stat_slots<E>(
    stats: &mut crate::SolveStats,
    mut stat: impl FnMut(u32) -> Result<u64, E>,
) -> Result<(), E> {
    for ix in 0..N {
        stats.timers[ix] = f64::from_bits(stat(stat_slot_secs(ix))?);
        stats.tcalls[ix] = stat(stat_slot_calls(ix))?;
    }
    Ok(())
}

/// Move a region's time from `from` to `to` for the duration of a callback the
/// enclosing clock must not be charged for — C's `rt_accumulate(SOLVER)` +
/// `rt_tick(EVENT)` pairs around the DASKR callbacks.
pub struct Handover(usize, usize);

impl Handover {
    pub fn new(from: usize, to: usize) -> Self {
        accumulate(from);
        tick(to);
        Handover(from, to)
    }
}

impl Drop for Handover {
    fn drop(&mut self) {
        accumulate(self.1);
        tick(self.0);
    }
}
