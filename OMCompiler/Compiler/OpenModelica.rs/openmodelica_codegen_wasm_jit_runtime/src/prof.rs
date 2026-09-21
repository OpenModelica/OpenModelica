//! C's `rtclock` clocks from `SIM_TIMER_FIRST_FUNCTION` on — one per profiled
//! function and equation block (`SIM_PROF_TICK_FN/EQ`, `SIM_PROF_ACC_*`,
//! `SIM_PROF_ADD_NCALL_EQ`) — kept in the module, where the instrumented code
//! runs. The driver reads a row per step and the run's totals at the end, and
//! clears them between steps as C's `clear_rt_step` does.

use alloc::vec::Vec;
use core::cell::UnsafeCell;

#[derive(Clone, Copy, Default)]
struct Clock {
    tick: f64,
    /// Since the last clear (C's `acc_tp`, `rt_clock_ncall`).
    acc: f64,
    ncall: u32,
    /// Over the run (C's `total_tp`, `max_tp`, `rt_clock_ncall_{total,min,max}`).
    total: f64,
    max: f64,
    ncall_total: u32,
    ncall_min: u32,
    ncall_max: u32,
}

struct Store(UnsafeCell<Vec<Clock>>);
unsafe impl Sync for Store {}
static CLOCKS: Store = Store(UnsafeCell::new(Vec::new()));
struct Buf(UnsafeCell<Vec<u8>>);
unsafe impl Sync for Buf {}
static BUF: Buf = Buf(UnsafeCell::new(Vec::new()));

/// Bytes per clock in [`rt_prof_dump`]'s record.
pub const DUMP_RECORD: usize = 40;

fn clocks() -> &'static mut Vec<Clock> {
    unsafe { &mut *CLOCKS.0.get() }
}

fn now() -> f64 {
    openmodelica_sim_meta::driver::now_ms_host() / 1000.0
}

/// `n` clocks, all zero: C's `rt_init`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_prof_init(n: u32) {
    let c = clocks();
    c.clear();
    c.resize(n as usize, Clock::default());
    let b = unsafe { &mut *BUF.0.get() };
    b.clear();
    b.resize(n as usize * DUMP_RECORD, 0);
}

/// C's `rt_tick`: open the clock and count the call.
#[unsafe(no_mangle)]
pub extern "C" fn rt_prof_tick(ix: u32) {
    if let Some(c) = clocks().get_mut(ix as usize) {
        c.tick = now();
        c.ncall += 1;
    }
}

/// C's `rt_accumulate`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_prof_acc(ix: u32) {
    if let Some(c) = clocks().get_mut(ix as usize) {
        c.acc += now() - c.tick;
    }
}

/// C's `rt_add_ncall`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_prof_add_ncall(ix: u32, n: i32) {
    if let Some(c) = clocks().get_mut(ix as usize) {
        c.ncall = c.ncall.wrapping_add_signed(n);
    }
}

/// C's `rt_clear` over every clock — `clear_rt_step`: the step's share joins the
/// run's totals and the extremes.
#[unsafe(no_mangle)]
pub extern "C" fn rt_prof_clear(_unused: u32) {
    for c in clocks().iter_mut() {
        c.total += c.acc;
        c.ncall_total += c.ncall;
        if c.acc > c.max {
            c.max = c.acc;
        }
        if c.ncall != 0 {
            c.ncall_min = if c.ncall_min != 0 && c.ncall_min < c.ncall { c.ncall_min } else { c.ncall };
            c.ncall_max = c.ncall_max.max(c.ncall);
        }
        c.acc = 0.0;
        c.ncall = 0;
    }
}

/// The step row C's `fmtEmitStep` writes for the clocks: `n` u32 call counts,
/// then `n` f64 seconds, little-endian at the returned address.
#[unsafe(no_mangle)]
pub extern "C" fn rt_prof_row() -> u32 {
    let c = clocks();
    let b = unsafe { &mut *BUF.0.get() };
    let n = c.len();
    for (i, k) in c.iter().enumerate() {
        b[4 * i..4 * i + 4].copy_from_slice(&k.ncall.to_le_bytes());
    }
    for (i, k) in c.iter().enumerate() {
        let o = 4 * n + 8 * i;
        b[o..o + 8].copy_from_slice(&k.acc.to_le_bytes());
    }
    b.as_ptr() as u32
}

/// Every clock's run totals at the returned address, [`DUMP_RECORD`] bytes each:
/// `total`, `max`, `acc` (f64) then `ncall_total`, `ncall_min`, `ncall_max`,
/// `ncall` (u32).
#[unsafe(no_mangle)]
pub extern "C" fn rt_prof_dump() -> u32 {
    let c = clocks();
    let b = unsafe { &mut *BUF.0.get() };
    for (i, k) in c.iter().enumerate() {
        let o = DUMP_RECORD * i;
        b[o..o + 8].copy_from_slice(&k.total.to_le_bytes());
        b[o + 8..o + 16].copy_from_slice(&k.max.to_le_bytes());
        b[o + 16..o + 24].copy_from_slice(&k.acc.to_le_bytes());
        b[o + 24..o + 28].copy_from_slice(&k.ncall_total.to_le_bytes());
        b[o + 28..o + 32].copy_from_slice(&k.ncall_min.to_le_bytes());
        b[o + 32..o + 36].copy_from_slice(&k.ncall_max.to_le_bytes());
        b[o + 36..o + 40].copy_from_slice(&k.ncall.to_le_bytes());
    }
    b.as_ptr() as u32
}
