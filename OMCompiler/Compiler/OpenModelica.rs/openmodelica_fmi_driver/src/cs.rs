//! The Co-Simulation master: the FMU integrates, the master feeds inputs and
//! handles events.
//!
//! `fmi3DoStep` is asked to advance to the next communication point, but an FMU
//! that declares `mightReturnEarlyFromDoStep` may stop at an internal event
//! instead. That is the whole point of driving it this way: the master takes
//! control back *at* the event, runs Event Mode there, and resumes from
//! `lastSuccessfulTime` — where a master that ignored early return would have
//! let the FMU step over the event and only learn about it afterwards. Every
//! stop is sampled, so the result carries the events as well as the grid.

use crate::api::{Fmi3, Fmi3CoSimulation};
use crate::common::{Inputs, event_iteration, initialize};
use crate::record::Recorder;
use crate::{Deadline, Error, Options, Result};
use openmodelica_fmi::{InterfaceKind, ModelDescription};

/// How a run ended.
pub struct Run {
    pub recorder: Recorder,
    /// The FMU asked to stop here; the rows up to it are a valid result.
    pub terminated_at: Option<f64>,
    /// The host asked for the run to stop; the samples up to here are kept.
    pub cancelled: bool,
    /// Communication steps taken.
    pub steps: u64,
    /// Events handled in Event Mode.
    pub events: u64,
    /// Steps the FMU ended before the communication point.
    pub early_returns: u64,
    /// When the events were handled, in order.
    pub event_times: Vec<f64>,
}

/// Drive a Co-Simulation FMU from `start_time` to `stop_time`.
pub fn simulate(
    inst: &mut dyn Fmi3CoSimulation,
    md: &ModelDescription,
    opts: &Options<'_>,
) -> Result<Run> {
    // Event Mode needs the FMU to have one; without it `fmi3EnterEventMode` is
    // not even callable and the FMU handles its events internally.
    let event_mode = opts.event_mode
        && md
            .interface(InterfaceKind::CoSimulation)
            .is_some_and(|i| i.has_event_mode);

    // An FMU with a fixed internal step size only advances in multiples of it,
    // so the communication points have to sit on that grid.
    let step = match md.interface(InterfaceKind::CoSimulation).and_then(|i| i.fixed_internal_step_size) {
        Some(dt) if dt > 0.0 => (opts.step_size / dt).round().max(1.0) * dt,
        _ => opts.step_size,
    };

    let mut inputs = Inputs::new(opts);
    let mut rec = Recorder::new(md, opts.keep);
    initialize(as_common(inst), &mut inputs, opts)?;

    let mut terminated_at = None;
    let (mut steps, mut events, mut early_returns) = (0, 0, 0);
    let mut stalled = 0;
    let mut event_times = Vec::new();
    let mut cancelled = false;
    if event_mode {
        let info = event_iteration(as_common(inst))?;
        if info.terminate {
            return Err(Error::TerminatedAtInit);
        }
        inst.enter_step_mode()?;
    }
    rec.snapshot_parameters(as_common(inst))?;
    rec.sample(as_common(inst), opts.start_time)?;

    let deadline = Deadline::arm(opts);
    let mut t = opts.start_time;
    let mut grid = opts.grid(step).skip(1);
    let mut next = grid.next();
    while let Some(target) = next {
        if deadline.expired() {
            return Err(Error::Alarm);
        }
        if inputs.is_time_varying() {
            inputs.apply(as_common(inst), opts, t)?;
        }
        let h = target - t;
        if h <= 0.0 {
            next = grid.next();
            continue;
        }
        let r = match inst.do_step(t, h, true) {
            Ok(r) => r,
            Err(Error::Status { call, status: crate::api::Status::Discard }) => {
                // Retrying needs `fmi3SetFMUState` to put the FMU back where the
                // step started; without it the master has nothing to retry from.
                return Err(Error::Status { call, status: crate::api::Status::Discard });
            }
            Err(e) => return Err(e),
        };
        steps += 1;
        // An FMU may return at the very time it started from when an event sits
        // there: the event is handled below and the step retaken. Only a run of
        // such steps with nothing in between is a stuck FMU.
        if r.last_successful_time > t {
            stalled = 0;
        } else {
            stalled += 1;
            if stalled > MAX_STALLED_STEPS || !(r.event_handling_needed || r.early_return) {
                return Err(Error::Solver("fmi3DoStep did not advance the time"));
            }
        }
        t = r.last_successful_time;
        rec.sample(as_common(inst), t)?;

        if r.event_handling_needed && event_mode {
            inst.enter_event_mode()?;
            let info = event_iteration(as_common(inst))?;
            inst.enter_step_mode()?;
            events += 1;
            event_times.push(t);
            // The event changed values at this very time: a second row at the
            // same time is what makes a discontinuity look like one.
            rec.sample(as_common(inst), t)?;
            if info.terminate {
                terminated_at = Some(t);
                break;
            }
        }
        if r.terminate {
            terminated_at = Some(t);
            break;
        }
        if (r.early_return || stalled > 0) && t < target - step_epsilon(opts) {
            // The FMU stopped inside the interval; the same communication point
            // is still ahead.
            early_returns += 1;
            continue;
        }
        next = grid.next();
        if let Some(report) = opts.progress {
            report(t, &rec);
        }
        if opts.cancelled.is_some_and(|stop| stop()) {
            cancelled = true;
            break;
        }
    }
    as_common(inst).terminate()?;
    Ok(Run { recorder: rec, terminated_at, cancelled, steps, events, early_returns, event_times })
}

/// How many `fmi3DoStep`s in a row may end where they started before the run is
/// called stuck.
const MAX_STALLED_STEPS: u32 = 100;

/// A time this close to the communication point counts as having reached it.
fn step_epsilon(opts: &Options<'_>) -> f64 {
    (opts.stop_time - opts.start_time).abs() * 1e-12
}

/// The common half of the interface, which the shared helpers take.
fn as_common<'a>(inst: &'a mut dyn Fmi3CoSimulation) -> &'a mut dyn Fmi3 {
    inst
}
