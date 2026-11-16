//! `spatialDistribution(...)`: the C entry points over the shared operators
//! ([`openmodelica_solvers::spatial`], the port of
//! `simulation/solver/spatialDistribution.c`).
//!
//! C keeps one `SPATIAL_DISTRIBUTION_DATA` per operator in
//! `simulationInfo->spatialDistributionData`; this runtime keeps the shared
//! `SpatialState` there instead, so both targets transport the profile with one
//! implementation. The generated code only ever reaches the operators through the
//! C entry points below.

use core::cell::Cell;
use core::ffi::{c_int, c_uint};

use openmodelica_sim_meta::spatial::SpatialState;

use crate::abi::*;

std::thread_local! {
    /// The `threadData` of the call in progress. The shared operators report a model
    /// error through a hook that takes only the message, and C throws out of the
    /// model there, so the jump buffer has to be reachable from one.
    static TD: Cell<*mut threadData_t> = const { Cell::new(core::ptr::null_mut()) };
}

/// C's `allocSpatialDistribution`: empty operators for a fresh run.
pub fn init(data: *mut DATA, n: usize) {
    openmodelica_sim_meta::spatial::set_throw_hook(report);
    free(data);
    let si = unsafe { &mut *(*data).simulationInfo };
    si.spatialDistributionData = Box::into_raw(Box::new(SpatialState::new(n))) as *mut SPATIAL_DISTRIBUTION_DATA;
}

pub fn free(data: *mut DATA) {
    let si = unsafe { &mut *(*data).simulationInfo };
    let p = core::mem::replace(&mut si.spatialDistributionData, core::ptr::null_mut());
    if !p.is_null() {
        drop(unsafe { Box::from_raw(p as *mut SpatialState) });
    }
}

#[cfg(feature = "fmi")]
/// The state as flat words for an FMU state, led by whether there is one.
pub fn to_words(data: *mut DATA, out: &mut Vec<f64>) {
    match unsafe { ((*(*data).simulationInfo).spatialDistributionData as *const SpatialState).as_ref() } {
        Some(s) => {
            out.push(1.0);
            s.to_words(out);
        }
        None => out.push(0.0),
    }
}

#[cfg(feature = "fmi")]
/// [`to_words`]' inverse, not applied yet: `None` for words it did not write or
/// that do not fit this model.
pub fn from_words(data: *mut DATA, w: &mut dyn Iterator<Item = f64>) -> Option<Option<SpatialState>> {
    if w.next()? == 0.0 {
        return Some(None);
    }
    let s = SpatialState::from_words(w)?;
    (s.count() == unsafe { (*(*data).modelData).nSpatialDistributions } as usize).then_some(Some(s))
}

#[cfg(feature = "fmi")]
/// Puts in place what [`from_words`] read.
pub fn restore(data: *mut DATA, state: Option<SpatialState>) {
    free(data);
    if let Some(s) = state {
        unsafe {
            (*(*data).simulationInfo).spatialDistributionData =
                Box::into_raw(Box::new(s)) as *mut SPATIAL_DISTRIBUTION_DATA
        };
    }
}

/// The operators' `throwStreamPrint`, on the `threadData` the entry point below
/// recorded. Does not return.
fn report(msg: &str) -> ! {
    crate::throw(TD.get(), msg)
}

fn state(data: *mut DATA, threadData: *mut threadData_t) -> &'static mut SpatialState {
    TD.set(threadData);
    match unsafe { ((*(*data).simulationInfo).spatialDistributionData as *mut SpatialState).as_mut() } {
        Some(s) => s,
        None => crate::throw(
            threadData,
            "a spatialDistribution() was evaluated before the operators were allocated",
        ),
    }
}

/// The `length` leading elements of a `real_array` parameter.
fn reals(a: *const real_array, length: usize) -> Vec<f64> {
    let a = unsafe { &*a };
    (0..length).map(|i| a.real_at(i, 0.0)).collect()
}

#[unsafe(no_mangle)]
pub extern "C" fn initSpatialDistribution(
    data: *mut DATA,
    threadData: *mut threadData_t,
    index: c_uint,
    initialPoints: *const real_array,
    initialValues: *const real_array,
    length: c_uint,
) {
    let n = length as usize;
    let (p, v) = (reals(initialPoints, n), reals(initialValues, n));
    state(data, threadData).init_profile(index, &p, &v);
}

#[unsafe(no_mangle)]
pub extern "C" fn storeSpatialDistribution(
    data: *mut DATA,
    threadData: *mut threadData_t,
    index: c_uint,
    in0: f64,
    in1: f64,
    posX: f64,
    isPositiveVelocity: c_int,
) {
    let time = unsafe { (*(*(*data).localData)).timeValue };
    let initial = unsafe { (*(*data).simulationInfo).initial != 0 };
    state(data, threadData).store(index, time, in0, in1, posX, isPositiveVelocity != 0, initial);
    if state(data, threadData).needs_history(false) {
        unsafe { crate::support::omc_error_raise(threadData) };
    }
}

pub(crate) fn history(data: *mut DATA, action: openmodelica_sim_meta::spatial::History) -> bool {
    unsafe { ((*(*data).simulationInfo).spatialDistributionData as *mut SpatialState).as_mut() }
        .is_some_and(|s| s.history(action))
}

#[unsafe(no_mangle)]
pub extern "C" fn spatialDistribution(
    data: *mut DATA,
    td: *mut threadData_t,
    index: c_uint,
    x: f64,
    positive: c_int,
    out1: *mut f64,
) -> f64 {
    let si = unsafe { &*(*data).simulationInfo };
    let mode = if si.initial != 0 {
        2
    } else {
        (si.discreteCall != 0) as u32
    };
    let s = state(data, td);
    let time = unsafe { (**(*data).localData).timeValue };
    let (a, b) = s.value(index, time, x, positive != 0, mode);
    if s.needs_history(false) {
        unsafe { crate::support::omc_error_raise(td) };
    }
    if !out1.is_null() {
        unsafe { *out1 = b };
    }
    a
}

#[unsafe(no_mangle)]
pub extern "C" fn spatialDistributionZeroCrossing(
    data: *mut DATA,
    threadData: *mut threadData_t,
    index: c_uint,
    relationIndex: c_uint,
    posX: f64,
    isPositiveVelocity: c_int,
) -> f64 {
    let si = unsafe { &*(*data).simulationInfo };
    let zc_pre = unsafe { *si.zeroCrossingsPre.add(relationIndex as usize) };
    state(data, threadData).zc(index, posX, isPositiveVelocity != 0, zc_pre)
}
