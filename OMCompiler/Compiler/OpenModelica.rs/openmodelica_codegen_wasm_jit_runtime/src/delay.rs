//! Port of `SimulationRuntime/c/simulation/solver/delay.c`: one `(time, value)`
//! ring buffer per `delay(...)` expression. State is a module global (single-
//! threaded wasm), reset by `rt_delay_init` each run.

use crate::omclog;
use alloc::collections::VecDeque;
use alloc::vec::Vec;
use core::cell::UnsafeCell;
use openmodelica_sim_meta::driver::{format_e, format_g};

/// C `DBL_EPSILON`.
const DBL_EPSILON: f64 = f64::EPSILON;

/// C's `DASSL_STEP_EPS` (`simulation/solver/epsilon.h`).
const DASSL_STEP_EPS: f64 = 1e-13;

/// C `printRingBuffer` with `printDelayBuffer`, minus the element addresses.
fn print_buffer(stream: omclog::Stream, buf: &VecDeque<Row>) {
    if !omclog::active(stream) {
        return;
    }
    omclog::info(stream, true, "Printing ring buffer:");
    for &(t, v) in buf {
        omclog::info(stream, false, &alloc::format!("({},{})", format_e(t), format_e(v)));
    }
    omclog::close(stream);
}

/// One `(time, value)` ring-buffer row.
type Row = (f64, f64);

/// Per-run delay state: one buffer per delay expression, plus the run start time.
pub struct DelayState {
    buffers: Vec<VecDeque<Row>>,
    start_time: f64,
}

/// Greatest row index whose time is `<= time` (C `findTime`). Caller guarantees a
/// non-empty buffer.
fn find_time(time: f64, buf: &VecDeque<Row>) -> usize {
    let end = buf.len();
    let mut pos = 0;
    if time < buf[0].0 {
        return 0;
    }
    while pos < end - 1 {
        pos += 1;
        if buf[pos].0 > time {
            pos -= 1;
            break;
        }
    }
    pos
}

/// Whether the buffer holds an event (two adjacent rows with equal time) at or
/// before `time` (C `searchEvent`).
fn search_event(time: f64, buf: &VecDeque<Row>) -> bool {
    let end = buf.len();
    if end == 0 {
        return false;
    }
    let mut cur = buf[0].0;
    if time < cur {
        return false;
    }
    let mut pos = 0;
    let mut found = false;
    while pos < end - 1 {
        pos += 1;
        let prev = cur;
        cur = buf[pos].0;
        if (prev - cur).abs() < 1e-12 {
            found = true;
            break;
        }
        if cur > time {
            break;
        }
    }
    if found {
        print_buffer(omclog::DEBUG, buf);
    }
    found
}

impl DelayState {
    fn new(n: usize, start_time: f64) -> Self {
        let mut buffers = Vec::with_capacity(n);
        for _ in 0..n {
            buffers.push(VecDeque::new());
        }
        DelayState { buffers, start_time }
    }

    /// C `storeDelayedExpression`: append `(time, value)`, dropping stale tail rows
    /// and dequeuing rows older than `time - delay_time` (unless an event sits on
    /// that boundary).
    fn store(&mut self, idx: usize, time: f64, value: f64, delay_time: f64) {
        let buf = &mut self.buffers[idx];
        let mut length = buf.len();
        while length > 0 && time < buf[length - 1].0 {
            buf.pop_back();
            length = buf.len();
        }
        if length > 0 {
            let last = buf[length - 1];
            if (last.0 - time).abs() < 1e-10 && (last.1 - value).abs() < 1e-10 {
                let row = find_time(time - delay_time + 1e-10, buf);
                for _ in 0..row {
                    buf.pop_front();
                }
                return;
            }
        }
        buf.push_back((time, value));
        let row = find_time(time - delay_time + DBL_EPSILON, buf);
        if row > 0 && !search_event(time - delay_time + DBL_EPSILON, buf) {
            for _ in 0..row {
                buf.pop_front();
            }
        }
        omclog::info(
            omclog::DELAY,
            false,
            &alloc::format!(
                "storeDelayed[{idx}] ({},{}) position={}",
                format_g(time, 6),
                format_g(value, 6),
                buf.len()
            ),
        );
        print_buffer(omclog::DELAY, buf);
    }

    /// C `delayImpl`: `expr(time - delay_time)` by linear interpolation, with the
    /// pre-start / empty / oldest-value special cases.
    fn eval(&self, idx: usize, time: f64, value: f64, delay_time: f64, delay_max: f64) -> f64 {
        let buf = &self.buffers[idx];
        let length = buf.len();
        omclog::info(
            omclog::DELAY,
            false,
            &alloc::format!(
                "delayImpl: exprNumber = {idx}, exprValue = {}, time = {}, delayTime = {}",
                format_g(value, 6),
                format_g(time, 6),
                format_g(delay_time, 6)
            ),
        );
        // C's `assertStreamPrint` guards, `DASSL_STEP_EPS` being 1e-13. Each one
        // throws in C, so at most one is reported and the caller's value stands in
        // for the interpolation the jump skipped.
        if delay_time < 0.0 {
            crate::nls::throw_stream(&alloc::format!(
                "Negative delay requested: delayTime = {}",
                format_g(delay_time, 6)
            ));
            return value;
        }
        if delay_time < DASSL_STEP_EPS {
            crate::nls::throw_stream(
                "delayImpl: delayTime is zero or too small.\nOpenModelica doesn't support delay operator with zero delay time.",
            );
            return value;
        }
        if delay_time > delay_max {
            crate::nls::throw_stream(&alloc::format!(
                "Too large delay requested: delayTime = {}, delayMax = {}",
                format_g(delay_time, 6),
                format_g(delay_max, 6)
            ));
            return value;
        }
        if time <= self.start_time {
            return value;
        }
        if length == 0 {
            omclog::info(
                omclog::EVENTS,
                false,
                &alloc::format!(
                    "delayImpl: Missing initial value, using argument value {} instead.",
                    format_g(value, 6)
                ),
            );
            return value;
        }
        if time <= self.start_time + delay_time {
            return buf[0].1;
        }
        let time_stamp = time - delay_time;
        let last = buf[length - 1];
        let (time0, value0, time1, value1);
        if time_stamp > last.0 {
            time0 = last.0;
            value0 = last.1;
            time1 = time;
            value1 = value;
        } else {
            let i = find_time(time_stamp, buf);
            time0 = buf[i].0;
            value0 = buf[i].1;
            if i + 1 == length {
                return value0;
            }
            time1 = buf[i + 1].0;
            value1 = buf[i + 1].1;
        }
        if time0 == time_stamp {
            return value0;
        }
        if time1 == time_stamp {
            return value1;
        }
        let timedif = time1 - time0;
        let dt1 = time_stamp - time0;
        value0 + (value1 - value0) * (dt1 / timedif)
    }

    /// C `delayZeroCrossing`: the wrapped relation's pre g-value, sign-flipped when
    /// a buffered event lies in the `(time - delay_time)` window.
    fn zc(&self, idx: usize, time: f64, delay_time: f64, zc_pre: f64) -> f64 {
        let buf = &self.buffers[idx];
        if buf.is_empty() {
            return zc_pre;
        }
        if search_event(time - delay_time, buf) {
            -zc_pre
        } else {
            zc_pre
        }
    }
}

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

#[cfg(test)]
mod tests {
    use super::*;

    fn buf(rows: &[Row]) -> VecDeque<Row> {
        rows.iter().copied().collect()
    }

    #[test]
    fn find_time_brackets() {
        let b = buf(&[(0.0, 1.0), (1.0, 2.0), (2.0, 3.0)]);
        assert_eq!(find_time(-1.0, &b), 0);
        assert_eq!(find_time(0.0, &b), 0);
        assert_eq!(find_time(1.5, &b), 1);
        assert_eq!(find_time(2.0, &b), 2);
        assert_eq!(find_time(9.0, &b), 2);
    }

    #[test]
    fn search_event_finds_duplicate_time() {
        let b = buf(&[(0.0, 1.0), (1.0, 2.0), (1.0, 5.0), (2.0, 6.0)]);
        assert!(!search_event(0.5, &b)); // before the event
        assert!(search_event(1.0, &b)); // at the event
        assert!(search_event(1.5, &b)); // after the event
        let clean = buf(&[(0.0, 1.0), (1.0, 2.0), (2.0, 3.0)]);
        assert!(!search_event(2.0, &clean));
    }

    #[test]
    fn eval_interpolates_linearly() {
        let mut s = DelayState::new(1, 0.0);
        s.store(0, 0.0, 0.0, 1.0);
        s.store(0, 1.0, 10.0, 1.0);
        s.store(0, 2.0, 20.0, 1.0);
        // at time 2, delay 1 -> value at t=1 == 10
        assert!((s.eval(0, 2.0, 20.0, 1.0, 1e60) - 10.0).abs() < 1e-9);
        // at time 1.5, delay 1 -> value at t=0.5 == 5 (interpolated 0..10)
        assert!((s.eval(0, 1.5, 15.0, 1.0, 1e60) - 5.0).abs() < 1e-9);
    }

    #[test]
    fn eval_pre_start_returns_arg() {
        let s = DelayState::new(1, 0.0);
        assert_eq!(s.eval(0, 0.0, 42.0, 1.0, 1e60), 42.0); // time <= start
        assert_eq!(s.eval(0, 0.5, 7.0, 1.0, 1e60), 7.0); // empty buffer
    }

    #[test]
    fn eval_before_delay_window_returns_oldest() {
        let mut s = DelayState::new(1, 0.0);
        s.store(0, 0.0, 3.0, 1.0);
        s.store(0, 0.5, 4.0, 1.0);
        // time 0.5 <= start(0) + delay(1) -> oldest value 3
        assert_eq!(s.eval(0, 0.5, 4.0, 1.0, 1e60), 3.0);
    }

    #[test]
    fn zc_flips_on_event() {
        let mut s = DelayState::new(1, 0.0);
        s.store(0, 0.0, 3.0, 0.001);
        // event at t=1: value jumps 3 -> 4 at the same time
        s.store(0, 1.0, 3.0, 0.001);
        s.store(0, 1.0, 4.0, 0.001);
        // no event in window (time-delay = 0.5 < 1): unchanged pre value
        assert_eq!(s.zc(0, 0.5, 0.001, 1.0), 1.0);
        // event now inside the window (time-delay = 1.002 - 0.001 > 1.0): flip
        assert_eq!(s.zc(0, 1.002, 0.001, 1.0), -1.0);
    }

    #[test]
    fn store_drops_future_rows() {
        let mut s = DelayState::new(1, 0.0);
        s.store(0, 0.0, 1.0, 10.0);
        s.store(0, 1.0, 2.0, 10.0);
        s.store(0, 2.0, 3.0, 10.0);
        // a step back in time (rejected step) pops the newer tail rows
        s.store(0, 0.5, 9.0, 10.0);
        let b = &s.buffers[0];
        assert_eq!(b.back().copied(), Some((0.5, 9.0)));
    }
}
