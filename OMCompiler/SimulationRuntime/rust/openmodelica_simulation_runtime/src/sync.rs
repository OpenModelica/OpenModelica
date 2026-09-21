//! Clocked partitions' C half: `BASECLOCK_DATA`/`SUBCLOCK_DATA` behind the flat
//! blocks the driver addresses, and the `handleBaseClock` an event clock's
//! `when`-body calls.

use core::ffi::{c_int, c_long};

use openmodelica_sim_meta::{BaseClockMeta, SubClockMeta};

use crate::abi::*;
use crate::model_data::cstr;

/// C's `handleBaseClock` fires the partition and schedules the next tick itself.
/// The shared driver owns that list and a wasm model cannot call back into it, so
/// `$_clkfire` raises a flag the driver turns into a timer; a C model reaches the
/// same flag through this array.
static FIRE: core::sync::atomic::AtomicPtr<c_int> =
    core::sync::atomic::AtomicPtr::new(core::ptr::null_mut());

/// The fired flags, for the region map. Allocated here because C has no such field.
pub fn fire_flags(md: &MODEL_DATA) -> *mut c_int {
    let p = FIRE.load(core::sync::atomic::Ordering::Relaxed);
    if !p.is_null() || md.nBaseClocks <= 0 {
        return p;
    }
    let p: *mut c_int = crate::model_data::calloc(md.nBaseClocks as usize);
    FIRE.store(p, core::sync::atomic::Ordering::Relaxed);
    p
}

/// The `$_clkfire` of a C model. C's returns whether the first sub-clock is the
/// base clock; the generated call is a `noReturnCall`, so nothing reads it.
#[unsafe(no_mangle)]
pub extern "C" fn handleBaseClock(
    _data: *mut DATA,
    _thread_data: *mut threadData_t,
    idx: c_long,
    _cur_time: f64,
) -> modelica_boolean {
    let p = FIRE.load(core::sync::atomic::Ordering::Relaxed);
    if !p.is_null() && idx >= 0 {
        unsafe { *p.add(idx as usize) = 1 };
    }
    0
}

fn clocks(data: *mut DATA) -> &'static [BASECLOCK_DATA] {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &*(*data).simulationInfo };
    if md.nBaseClocks <= 0 || si.baseClocks.is_null() {
        return &[];
    }
    unsafe { core::slice::from_raw_parts(si.baseClocks, md.nBaseClocks as usize) }
}

/// Whether the clocks are as [`init_clocks`] just left them.
///
/// The driver asks for `function_initSynchronous` at the head of every run, where
/// C's `initSynchronous` calls it. This runtime has to run it earlier -- only the
/// model knows how many sub-clocks a base clock has and [`Layout::n_sub_clocks`]
/// is the total -- so the first request reuses that run: nothing has touched a
/// clock since, and the generated function logs an inferred clock, which C warns
/// about once.
static FRESH: core::sync::atomic::AtomicBool = core::sync::atomic::AtomicBool::new(false);

pub fn take_fresh() -> bool {
    FRESH.swap(false, core::sync::atomic::Ordering::Relaxed)
}

/// C's generated `function_initSynchronous`: allocate `baseClocks` and each
/// clock's `subClocks`, and reset every `CLOCK_STATS`. The previous allocation is
/// released first, so a repeat leaks nothing -- but it moves the arrays, so the
/// caller must re-point the region map.
pub fn init_clocks(data: *mut DATA, thread_data: *mut threadData_t) {
    let md = unsafe { &*(*data).modelData };
    if md.nBaseClocks <= 0 {
        return;
    }
    let si = unsafe { &mut *(*data).simulationInfo };
    if !si.baseClocks.is_null() {
        for c in clocks(data) {
            if !c.subClocks.is_null() {
                unsafe { libc::free(c.subClocks as *mut libc::c_void) };
            }
        }
        unsafe { libc::free(si.baseClocks as *mut libc::c_void) };
        si.baseClocks = core::ptr::null_mut();
    }
    if let Some(f) = unsafe { (*(*data).callback).function_initSynchronous } {
        unsafe { f(data, thread_data) };
    }
    fire_flags(md);
}

/// Say that [`init_clocks`] has just run, so the driver's first request for it is
/// a repeat.
pub fn mark_fresh() {
    FRESH.store(true, core::sync::atomic::Ordering::Relaxed);
}

pub fn n_sub_clocks(data: *mut DATA) -> u32 {
    clocks(data).iter().map(|c| c.nSubClocks.max(0) as u32).sum()
}

/// [`SimMeta::clocks`]. `inferred` stays false: the generated
/// `function_initSynchronous` prints that warning itself.
pub fn describe(data: *mut DATA) -> Vec<BaseClockMeta> {
    let mut sub_base = 0u32;
    clocks(data)
        .iter()
        .map(|c| {
            let n = c.nSubClocks.max(0) as usize;
            let sub = (0..n)
                .map(|j| {
                    let s = unsafe { &*c.subClocks.add(j) };
                    SubClockMeta {
                        shift_num: s.shift.num as i64,
                        shift_den: s.shift.den as i64,
                        factor_num: s.factor.num as i64,
                        factor_den: s.factor.den as i64,
                        hold_events: s.holdEvents != 0,
                        external_solver: cstr(s.solverMethod) == "External",
                    }
                })
                .collect();
            let base = sub_base;
            sub_base += n as u32;
            BaseClockMeta {
                is_event_clock: c.isEventClock != 0,
                inferred: false,
                sub_base: base,
                sub,
            }
        })
        .collect()
}

/// The `(base_idx, sub_idx)` C's `function_equationsSynchronous` takes, from the
/// flat sub-clock index the driver names a partition by.
pub fn split(data: *mut DATA, flat: u32) -> (c_long, c_long) {
    let mut at = 0u32;
    for (i, c) in clocks(data).iter().enumerate() {
        let n = c.nSubClocks.max(0) as u32;
        if flat < at + n {
            return (i as c_long, (flat - at) as c_long);
        }
        at += n;
    }
    (0, 0)
}

/// One region for the base clocks, then one per base clock for its own
/// `subClocks` allocation.
pub fn regions(data: *mut DATA, l: &openmodelica_sim_meta::Layout) -> Vec<(u32, u32, *mut BASECLOCK_DATA, *mut SUBCLOCK_DATA)> {
    let cs = clocks(data);
    if cs.is_empty() {
        return Vec::new();
    }
    let si = unsafe { &*(*data).simulationInfo };
    let mut out = vec![(
        l.clock_off,
        l.n_base_clocks * openmodelica_sim_meta::BASECLOCK_BYTES,
        si.baseClocks,
        core::ptr::null_mut(),
    )];
    let mut base = 0u32;
    for c in cs {
        let n = c.nSubClocks.max(0) as u32;
        if n > 0 {
            out.push((
                l.sub_clock_off(base),
                n * openmodelica_sim_meta::SUBCLOCK_BYTES,
                core::ptr::null_mut(),
                c.subClocks,
            ));
        }
        base += n;
    }
    out
}
