//! `spatialDistribution(...)`: the C entry points over the shared operators
//! ([`openmodelica_solvers::spatial`], the port of
//! `simulation/solver/spatialDistribution.c`).
//!
//! C keeps one `SPATIAL_DISTRIBUTION_DATA` per operator in
//! `simulationInfo->spatialDistributionData`; this runtime keeps them in the
//! shared `SpatialState` instead, so both targets transport the profile with one
//! implementation and `spatialDistributionData` stays null. The generated code
//! only ever reaches the operators through the four functions below.

use core::cell::UnsafeCell;
use core::ffi::{c_int, c_uint};

use openmodelica_sim_meta::spatial::SpatialState;

use crate::abi::*;

struct SpatialCell(UnsafeCell<Option<SpatialState>>);
// One model per process, driven from one thread, as C's own file-scope state.
unsafe impl Sync for SpatialCell {}
static SPATIAL: SpatialCell = SpatialCell(UnsafeCell::new(None));

struct TdCell(UnsafeCell<*mut threadData_t>);
unsafe impl Sync for TdCell {}
/// The `threadData` of the call in progress. The shared operators report a model
/// error through a hook that takes only the message, and C throws out of the
/// model there, so the jump buffer has to be reachable from one.
static TD: TdCell = TdCell(UnsafeCell::new(core::ptr::null_mut()));

/// C's `allocSpatialDistribution`: empty operators for a fresh run.
pub fn init(n: usize) {
    openmodelica_sim_meta::spatial::set_throw_hook(report);
    unsafe { *SPATIAL.0.get() = Some(SpatialState::new(n)) };
}

/// The operators' `throwStreamPrint`, on the `threadData` the entry point below
/// recorded. Does not return.
fn report(msg: &str) -> ! {
    crate::throw(unsafe { *TD.0.get() }, msg)
}

fn state(threadData: *mut threadData_t) -> &'static mut SpatialState {
    unsafe { *TD.0.get() = threadData };
    match unsafe { (*SPATIAL.0.get()).as_mut() } {
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
    _data: *mut DATA,
    threadData: *mut threadData_t,
    index: c_uint,
    initialPoints: *const real_array,
    initialValues: *const real_array,
    length: c_uint,
) {
    let n = length as usize;
    let (p, v) = (reals(initialPoints, n), reals(initialValues, n));
    state(threadData).init_profile(index, &p, &v);
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
    state(threadData).store(index, time, in0, in1, posX, isPositiveVelocity != 0);
}

#[unsafe(no_mangle)]
pub extern "C" fn spatialDistribution(
    data: *mut DATA,
    threadData: *mut threadData_t,
    index: c_uint,
    in0: f64,
    in1: f64,
    posX: f64,
    isPositiveVelocity: c_int,
    out1: *mut f64,
) -> f64 {
    let si = unsafe { &*(*data).simulationInfo };
    let time = unsafe { (*(*(*data).localData)).timeValue };
    let mode = (si.discreteCall != 0) as u32;
    let (o0, o1) =
        state(threadData).eval(index, time, in0, in1, posX, isPositiveVelocity != 0, mode);
    if !out1.is_null() {
        unsafe { *out1 = o1 };
    }
    o0
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
    state(threadData).zc(index, posX, isPositiveVelocity != 0, zc_pre)
}
