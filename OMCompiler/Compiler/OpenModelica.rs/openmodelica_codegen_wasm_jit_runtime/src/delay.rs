//! The wasm ABI over the shared `delay(...)` buffers
//! ([`openmodelica_solvers::delay`]): one state per module, reset by
//! `rt_delay_init` at the head of a run.

use core::cell::UnsafeCell;

use openmodelica_sim_meta::delay::DelayState;

struct DelayCell(UnsafeCell<Option<DelayState>>);
// Single-threaded wasm: no concurrent access to the delay state.
unsafe impl Sync for DelayCell {}
static DELAY: DelayCell = DelayCell(UnsafeCell::new(None));

#[inline]
fn state() -> &'static mut DelayState {
    unsafe { (*DELAY.0.get()).as_mut().expect("rt_delay_init not called") }
}

/// (Re)allocate `n_delays` empty buffers for a fresh run and record its start time.
#[unsafe(no_mangle)]
pub extern "C" fn rt_delay_init(n_delays: u32, start_time: f64) {
    openmodelica_sim_meta::delay::set_throw_hook(crate::nls::throw_stream);
    unsafe {
        *DELAY.0.get() = Some(DelayState::new(n_delays as usize, start_time));
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn rt_delay_store(idx: u32, time: f64, value: f64, delay_time: f64, _delay_max: f64) {
    state().store(idx as usize, time, value, delay_time);
}

#[unsafe(no_mangle)]
pub extern "C" fn rt_delay_eval(idx: u32, time: f64, value: f64, delay_time: f64, delay_max: f64) -> f64 {
    state().eval(idx as usize, time, value, delay_time, delay_max)
}

#[unsafe(no_mangle)]
pub extern "C" fn rt_delay_zc(idx: u32, time: f64, delay_time: f64, zc_pre: f64) -> f64 {
    state().zc(idx as usize, time, delay_time, zc_pre)
}

