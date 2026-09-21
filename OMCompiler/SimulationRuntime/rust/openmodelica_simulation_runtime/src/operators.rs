//! `delay(...)`: the C entry points over the shared ring buffers
//! ([`openmodelica_solvers::delay`], the port of `simulation/solver/delay.c`).
//!
//! C keeps one `RINGBUFFER` per expression in `simulationInfo->delayStructure`;
//! this runtime keeps the same buffers in the shared `DelayState` instead, so
//! both targets interpolate and search for events with one implementation and
//! `delayStructure` stays null. The generated code only ever reaches the buffers
//! through these three functions.

use core::cell::UnsafeCell;
use core::ffi::{c_int, c_long, c_uint};

use openmodelica_sim_meta::delay::DelayState;

use crate::abi::*;

struct DelayCell(UnsafeCell<Option<DelayState>>);
// One model per process, driven from one thread, as C's own file-scope state.
unsafe impl Sync for DelayCell {}
static DELAY: DelayCell = DelayCell(UnsafeCell::new(None));

struct TdCell(UnsafeCell<*mut threadData_t>);
unsafe impl Sync for TdCell {}
/// The `threadData` of the call in progress. The shared buffers report a bad
/// argument through a hook that takes only the message, and C throws out of the
/// model there, so the jump buffer has to be reachable from one.
static TD: TdCell = TdCell(UnsafeCell::new(core::ptr::null_mut()));

/// C's `initDelay`: empty buffers for a fresh run, anchored at its start time.
pub fn init(n_delays: usize, start_time: f64) {
    openmodelica_sim_meta::delay::set_throw_hook(report);
    unsafe { *DELAY.0.get() = Some(DelayState::new(n_delays, start_time)) };
}

/// The buffers' `throwStreamPrint`, on the `threadData` the entry point below
/// recorded. Does not return, so the caller's value never stands in.
fn report(msg: &str) {
    crate::throw(unsafe { *TD.0.get() }, msg)
}

fn state(threadData: *mut threadData_t) -> &'static mut DelayState {
    unsafe { *TD.0.get() = threadData };
    match unsafe { (*DELAY.0.get()).as_mut() } {
        Some(s) => s,
        None => crate::throw(threadData, "a delay() was evaluated before the buffers were allocated"),
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn storeDelayedExpression(
    data: *mut DATA,
    threadData: *mut threadData_t,
    exprNumber: c_int,
    exprValue: f64,
    delayTime: f64,
    delayMax: f64,
) {
    let n = unsafe { (*(*data).modelData).nDelayExpressions };
    if exprNumber < 0 || exprNumber as c_long >= n {
        crate::throw(
            threadData,
            &format!("storeDelayedExpression: invalid expression number {exprNumber}"),
        );
    }
    let time = unsafe { (**(*data).localData).timeValue };
    let _ = delayMax;
    state(threadData).store(exprNumber as usize, time, exprValue, delayTime);
}

#[unsafe(no_mangle)]
pub extern "C" fn delayImpl(
    data: *mut DATA,
    threadData: *mut threadData_t,
    exprNumber: c_int,
    exprValue: f64,
    delayTime: f64,
    delayMax: f64,
) -> f64 {
    let n = unsafe { (*(*data).modelData).nDelayExpressions };
    if exprNumber < 0 || exprNumber as c_long >= n {
        crate::throw(threadData, &format!("invalid exprNumber = {exprNumber}"));
    }
    let time = unsafe { (**(*data).localData).timeValue };
    state(threadData).eval(exprNumber as usize, time, exprValue, delayTime, delayMax)
}

#[unsafe(no_mangle)]
pub extern "C" fn delayZeroCrossing(
    data: *mut DATA,
    threadData: *mut threadData_t,
    exprNumber: c_uint,
    relationIndex: c_uint,
    delayTime: f64,
) -> f64 {
    let si = unsafe { &*(*data).simulationInfo };
    let zc_pre = unsafe { *si.zeroCrossingsPre.add(relationIndex as usize) };
    let time = unsafe { (**(*data).localData).timeValue };
    state(threadData).zc(exprNumber as usize, time, delayTime, zc_pre)
}
