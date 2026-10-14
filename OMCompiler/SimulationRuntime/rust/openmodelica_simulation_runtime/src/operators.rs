//! `delay(...)`: the C entry points over the shared ring buffers
//! ([`openmodelica_solvers::delay`], the port of `simulation/solver/delay.c`).
//!
//! C keeps one `RINGBUFFER` per expression in `simulationInfo->delayStructure`;
//! this runtime keeps the shared `DelayState` there instead, so both targets
//! interpolate and search for events with one implementation. The generated code
//! only ever reaches the buffers through these three functions.

use core::cell::Cell;
use core::ffi::{c_int, c_long, c_uint};

use openmodelica_sim_meta::delay::DelayState;

use crate::abi::*;

std::thread_local! {
    /// The `threadData` of the call in progress. The shared buffers report a bad
    /// argument through a hook that takes only the message, and C throws out of the
    /// model there, so the jump buffer has to be reachable from one.
    static TD: Cell<*mut threadData_t> = const { Cell::new(core::ptr::null_mut()) };
}

/// C's `initDelay`: empty buffers for a fresh run, anchored at its start time.
pub fn init(data: *mut DATA, n_delays: usize, start_time: f64) {
    openmodelica_sim_meta::delay::set_throw_hook(report);
    free(data);
    let si = unsafe { &mut *(*data).simulationInfo };
    si.delayStructure = Box::into_raw(Box::new(DelayState::new(n_delays, start_time))) as *mut *mut core::ffi::c_void;
}

pub fn free(data: *mut DATA) {
    let si = unsafe { &mut *(*data).simulationInfo };
    let p = core::mem::replace(&mut si.delayStructure, core::ptr::null_mut());
    if !p.is_null() {
        drop(unsafe { Box::from_raw(p as *mut DelayState) });
    }
}

#[cfg(feature = "fmi")]
/// The state as flat words for an FMU state, led by whether there is one.
pub fn to_words(data: *mut DATA, out: &mut Vec<f64>) {
    match unsafe { ((*(*data).simulationInfo).delayStructure as *const DelayState).as_ref() } {
        Some(s) => {
            out.push(1.0);
            s.to_words(out);
        }
        None => out.push(0.0),
    }
}

#[cfg(feature = "fmi")]
/// [`to_words`]' inverse; `false` for words it did not write.
pub fn set_from_words(data: *mut DATA, w: &mut dyn Iterator<Item = f64>) -> bool {
    let state = match w.next() {
        Some(0.0) => None,
        Some(_) => match DelayState::from_words(w) {
            Some(s) => Some(s),
            None => return false,
        },
        None => return false,
    };
    free(data);
    if let Some(s) = state {
        unsafe { (*(*data).simulationInfo).delayStructure = Box::into_raw(Box::new(s)) as *mut *mut core::ffi::c_void };
    }
    true
}

/// The buffers' `raiseStreamPrint`, on the `threadData` the entry point below
/// recorded; the caller's value stands in.
fn report(msg: &str) {
    crate::support::raise_stream(TD.get(), msg)
}

fn state(data: *mut DATA, threadData: *mut threadData_t) -> &'static mut DelayState {
    TD.set(threadData);
    match unsafe { ((*(*data).simulationInfo).delayStructure as *mut DelayState).as_mut() } {
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
    state(data, threadData).store(exprNumber as usize, time, exprValue, delayTime);
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
    state(data, threadData).eval(exprNumber as usize, time, exprValue, delayTime, delayMax)
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
    state(data, threadData).zc(exprNumber as usize, time, delayTime, zc_pre)
}
