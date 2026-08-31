//! The wasm ABI over the shared `spatialDistribution(...)` operators
//! ([`openmodelica_solvers::spatial`]): one state per module, reset by
//! `rt_spatial_init` at the head of a run.

use core::cell::UnsafeCell;

use openmodelica_sim_meta::spatial::SpatialState;

struct SpatialCell(UnsafeCell<Option<SpatialState>>);
// Single-threaded wasm: no concurrent access to the operator state.
unsafe impl Sync for SpatialCell {}
static SPATIAL: SpatialCell = SpatialCell(UnsafeCell::new(None));

fn state() -> &'static mut SpatialState {
    match unsafe { (*SPATIAL.0.get()).as_mut() } {
        Some(s) => s,
        None => {
            openmodelica_sim_meta::omclog::error(
                openmodelica_sim_meta::omclog::STDOUT,
                false,
                "spatialDistribution: rt_spatial_init was not called",
            );
            crate::trap()
        }
    }
}

/// (Re)allocate `n` uninitialized operators for a fresh run.
#[unsafe(no_mangle)]
pub extern "C" fn rt_spatial_init(n: u32) {
    openmodelica_sim_meta::spatial::set_throw_hook(fatal);
    unsafe { *SPATIAL.0.get() = Some(SpatialState::new(n as usize)) };
}

/// The operators' `throwStreamPrint`: the message is already on the log.
fn fatal(_msg: &str) -> ! {
    crate::trap()
}

/// Fill operator `index` from its `initialPoints` / `initialValues` arrays (Real
/// array handles, borrowed).
#[unsafe(no_mangle)]
pub extern "C" fn rt_spatial_init_profile(index: u32, points: u32, values: u32) {
    let read = |handle: u32| -> alloc::vec::Vec<f64> {
        let n = crate::rt_array_total(handle);
        (1..=n as i32)
            .map(|k| unsafe { crate::load_f64(crate::rt_array_elem_ptr(handle, k)) })
            .collect()
    };
    let (p, v) = (read(points), read(values));
    state().init_profile(index, &p, &v);
}

/// C `storeSpatialDistribution`: commit the boundary condition of an accepted step.
#[unsafe(no_mangle)]
pub extern "C" fn rt_spatial_store(
    index: u32,
    time: f64,
    in0: f64,
    in1: f64,
    pos_x: f64,
    positive: u32,
) {
    state().store(index, time, in0, in1, pos_x, positive != 0);
}

/// C `spatialDistribution`: returns `out0`; `out1` follows from
/// [`rt_spatial_out1`]. `mode` is the relation evaluation mode, of which C's
/// `simulationInfo->discreteCall` is `mode != 0`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_spatial_eval(
    index: u32,
    time: f64,
    in0: f64,
    in1: f64,
    pos_x: f64,
    positive: u32,
    mode: u32,
) -> f64 {
    state().eval(index, time, in0, in1, pos_x, positive != 0, mode).0
}

/// The second output of the preceding [`rt_spatial_eval`] of the same operator.
/// The codegen emits the two back to back for one `spatialDistribution(...)` call,
/// which is C's `double* out1` out-parameter without the scratch address.
#[unsafe(no_mangle)]
pub extern "C" fn rt_spatial_out1(index: u32) -> f64 {
    state().out1(index)
}

/// C `spatialDistributionZeroCrossing`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_spatial_zc(index: u32, pos_x: f64, positive: u32, zc_pre: f64) -> f64 {
    state().zc(index, pos_x, positive != 0, zc_pre)
}
