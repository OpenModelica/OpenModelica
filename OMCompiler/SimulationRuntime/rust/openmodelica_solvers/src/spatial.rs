//! Port of `SimulationRuntime/c/simulation/solver/spatialDistribution.c`: the
//! transported profile `z(xi, t)` behind each `spatialDistribution(...)` operator.
//!
//! The profile is the list of `(position, value)` nodes describing `z` in the
//! *material* coordinate `position = xi - x(t)`, so a node keeps its position for
//! as long as it stays in the domain and only the read/write edges move with `x`.
//! For a positive velocity the input edge is the front (`-x`) and the output edge
//! the back (`-x + 1`); for a negative velocity the two swap. Two adjacent nodes
//! at the same position are a discontinuity, tracked separately in `events` so the
//! zero-crossing function can announce it as it reaches an output.
//!
//! Where C uses two malloc-per-node doubly-linked lists, this keeps both in
//! `VecDeque`s: the operator only ever pushes at one end and pops at the other, so
//! a ring buffer fits it exactly. The next outgoing event is found at an end of
//! the event deque (see [`Spatial::zc`]).
//!
//! Only the operators; allocating the state and reporting a model error are the
//! runtime's business, as they are for [`crate::delay`].

use alloc::collections::VecDeque;
use alloc::format;
use alloc::vec::Vec;
use core::sync::atomic::{AtomicUsize, Ordering};

use crate::omclog;

static THROW_HOOK: AtomicUsize = AtomicUsize::new(0);

/// Install C's `throwStreamPrint` + `omc_throw_function` for an operator error.
/// Each runtime reports a model error its own way -- the in-wasm one traps, the
/// native one longjmps out of the model -- so the operators only say what
/// happened. Every message here is fatal in C, so the hook may not return.
pub fn set_throw_hook(f: fn(&str) -> !) {
    THROW_HOOK.store(f as usize, Ordering::Relaxed);
}

/// The relation evaluation modes [`SpatialState::value`] is handed (`SimLayout`'s
/// `rel_fresh`): continuous integration, an event update, the initial system.
const MODE_CONTINUOUS: u32 = 0;
#[cfg(test)]
const MODE_EVENT: u32 = 1;
const MODE_INITIAL: u32 = 2;

/// C `SPATIAL_EPS` (`epsilon.h`).
const SPATIAL_EPS: f64 = f64::EPSILON;
/// C `SPATIAL_ZERO_DELTA_X`: the `x` progress below which a step is standing still.
const SPATIAL_ZERO_DELTA_X: f64 = 1e-12;
/// C's `SPATIAL_EPS_ULPS`: positions and values are not absolute, so the epsilons
/// below scale with them (clamped at 1 so nothing gets tighter than unscaled).
const EPS_ULPS: f64 = 8.0;

fn scale(a: f64, b: f64) -> f64 {
    let s = if a.abs() > b.abs() { a.abs() } else { b.abs() };
    if s > 1.0 { s } else { 1.0 }
}

fn pos_eps(a: f64, b: f64) -> f64 {
    EPS_ULPS * SPATIAL_EPS * scale(a, b)
}

fn val_eps(a: f64, b: f64) -> f64 {
    EPS_ULPS * SPATIAL_EPS * scale(a, b)
}

/// Never below the resolution of the position coordinate.
fn zero_delta_x(a: f64, b: f64) -> f64 {
    let e = pos_eps(a, b);
    if SPATIAL_ZERO_DELTA_X > e {
        SPATIAL_ZERO_DELTA_X
    } else {
        e
    }
}

#[derive(Clone, Copy)]
struct Node {
    pos: f64,
    val: f64,
}

/// A discontinuity of `z`: two profile nodes sharing a position. `sign` alternates
/// along the list, so the zero-crossing value flips at every one it passes.
#[derive(Clone, Copy)]
struct Event {
    pos: f64,
    sign: f64,
}

/// A value for a log message, formatted only if the message is written: the
/// logging calls below run on every evaluation.
struct F(f64);

impl core::fmt::Display for F {
    fn fmt(&self, out: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(out, "{:.6}", self.0)
    }
}

struct E(f64);

impl core::fmt::Display for E {
    fn fmt(&self, out: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        out.write_str(&omclog::e(self.0, 0, 6))
    }
}

fn f(v: f64) -> F {
    F(v)
}

fn e(v: f64) -> E {
    E(v)
}

/// C's `errorStreamPrint(OMC_LOG_STDOUT, ...)` + `omc_throw_function`.
fn fatal(msg: &str) -> ! {
    omclog::error(omclog::STDOUT, false, msg);
    let p = THROW_HOOK.load(Ordering::Relaxed);
    if p == 0 {
        panic!("spatialDistribution: {msg}");
    }
    let f: fn(&str) -> ! = unsafe { core::mem::transmute(p) };
    f(msg)
}

fn interpolate(left: Node, right: Node, at: f64) -> f64 {
    let d = right.pos - left.pos;
    if !(d > 0.0) {
        fatal("interpolateTransportedQuantity: wrong order or same position!");
    }
    left.val * ((right.pos - at) / d) + right.val * ((at - left.pos) / d)
}

/// C's `warnStepSizeTooBig`: the warning and its subline, `-lvMaxWarn` times.
fn warn_step_size_too_big(n_displayed: &mut u64, what: &str, time: f64, index: u32, events: i32) {
    let max_displayed = crate::solverflags::max_warn_displays();
    *n_displayed += 1;
    if *n_displayed > max_displayed
        || !(omclog::active(omclog::STDOUT) || omclog::mask() & omclog::SHOW_ALL_WARNINGS != 0)
    {
        return;
    }
    omclog::warning(
        omclog::STDOUT,
        true,
        &format!("{what} more then one event from spatialDistribution. Step size to big!"),
    );
    omclog::warning!(
        omclog::STDOUT,
        false,
        "time: {}, spatialDistribution index: {index}, number of events: {events}",
        f(time),
    );
    omclog::close_warning(omclog::STDOUT);
    if *n_displayed == max_displayed {
        omclog::warning_limit_reached(omclog::STDOUT, max_displayed);
    }
}

/// What [`Spatial::read_output`] found at the output edge.
struct Read {
    out: f64,
    /// Value before the first pending discontinuity.
    event_pre: Option<f64>,
    /// Number of discontinuities between the stored output edge and the new one.
    events: i32,
}

/// One `spatialDistribution(...)` operator's state.
#[derive(Clone)]
struct Spatial {
    profile: VecDeque<Node>,
    events: VecDeque<Event>,
    initialized: bool,
    /// `x` at initialization. The operator only depends on the *change*
    /// of `x`, and the initial profile is stored assuming `x(t0) = 0`, so this is
    /// subtracted from every `x` (C's `startPosX`). Captured lazily: an operator
    /// inside an inactive `if`-branch must not start before the branch is taken.
    start_pos_x: Option<f64>,
    /// `x` at the last accepted step (C's `oldPosX`), shifted.
    old_pos_x: f64,
    /// `sign` of the last discontinuity that left the domain, so the alternation
    /// survives an event list that ran empty.
    last_event_sign: f64,
    /// Second output of the last [`Spatial::eval`], for [`SpatialState::out1`].
    out1: f64,
    n_warnings_removed_events: u64,
    n_warnings_output_events: u64,
    needs_history: bool,
    has_stored_inlet: bool,
}

impl Spatial {
    fn new() -> Self {
        Spatial {
            profile: VecDeque::new(),
            events: VecDeque::new(),
            initialized: false,
            start_pos_x: None,
            old_pos_x: 0.0,
            last_event_sign: 0.0,
            out1: 0.0,
            n_warnings_removed_events: 0,
            n_warnings_output_events: 0,
            needs_history: false,
            has_stored_inlet: false,
        }
    }

    /// C's `doubleEndedListPrint`, minus the node addresses.
    fn log_lists(&self) {
        if !omclog::active(omclog::SPATIALDISTR) {
            return;
        }
        for n in &self.profile {
            omclog::info!(omclog::SPATIALDISTR, false, "({},{})", e(n.pos), e(n.val));
        }
        omclog::info(omclog::SPATIALDISTR, false, "List of events");
        for ev in &self.events {
            omclog::info!(omclog::SPATIALDISTR, false, "({},{})", e(ev.pos), e(ev.sign));
        }
    }

    /// C `initSpatialDistribution`: the parameter profile becomes the initial one,
    /// with an event for every pair of `initialPoints` sharing a position.
    fn init_profile(&mut self, index: u32, points: &[f64], values: &[f64]) {
        omclog::info!(
            omclog::SPATIALDISTR,
            true,
            "Initializing spatial distributions (index={index})",
        );
        let n = points.len();
        if n < 2 || values.len() != n {
            fatal(
                "Initialization of spatial distribution failed: initialPoints and initialValues must have the same size >= 2.",
            );
        }
        if points[0].abs() > SPATIAL_EPS {
            omclog::error!(
                omclog::STDOUT,
                true,
                "Initialization of spatial distribution with index {index} failed.",
            );
            fatal(&format!("initialPoints[0] = {} is not zero.", e(points[0])));
        }
        if (points[n - 1] - 1.0).abs() > SPATIAL_EPS {
            omclog::error!(
                omclog::STDOUT,
                true,
                "Initialization of spatial distribution with index {index} failed.",
            );
            fatal(&format!("initialPoints[end] = {} is not one.", e(points[n - 1])));
        }
        if self.initialized {
            fatal("SpatialDistribution was allready allocated!");
        }
        let mut num_same = 0;
        let mut sign = -1.0;
        for i in 0..n - 1 {
            if points[i] > points[i + 1] {
                omclog::error!(
                    omclog::STDOUT,
                    true,
                    "Initialization of spatial distribution with index {index} failed.",
                );
                omclog::error!(omclog::STDOUT, false, "initialPoints[{i}] > initialPoints[{}]", i + 1,);
                fatal(&format!("{} > {}", f(points[i]), f(points[i + 1])));
            }
            self.profile.push_back(Node {
                pos: points[i],
                val: values[i],
            });
            if points[i] == points[i + 1] {
                num_same += 1;
                if num_same > 1 {
                    omclog::error!(
                        omclog::STDOUT,
                        true,
                        "Initialization of spatial distribution with index {index} failed.",
                    );
                    omclog::error!(
                        omclog::STDOUT,
                        false,
                        "initialPoints[{}] = initialPoints[{i}] = initialPoints[{}]",
                        i - 1,
                        i + 1,
                    );
                    fatal("Only events with one pre-value and one value are allowed.");
                }
                sign = -sign;
                self.events.push_back(Event { pos: points[i], sign });
            } else {
                num_same = 0;
            }
        }
        self.profile.push_back(Node {
            pos: points[n - 1],
            val: values[n - 1],
        });
        self.initialized = true;
        self.log_lists();
        omclog::close(omclog::SPATIALDISTR);
        omclog::info!(
            omclog::SPATIALDISTR,
            false,
            "Finished initializing spatial distribution (index={index})",
        );
    }

    fn shift(&mut self, pos_x: f64) -> f64 {
        pos_x - *self.start_pos_x.get_or_insert(pos_x)
    }

    fn front(&self) -> Node {
        self.profile[0]
    }

    fn back(&self) -> Node {
        self.profile[self.profile.len() - 1]
    }

    /// Material position the operator reads `z` at (`xi = 1` / `xi = 0`).
    fn out_pos(pos_x: f64, positive: bool) -> f64 {
        if positive { 1.0 - pos_x } else { -pos_x }
    }

    /// Material position the boundary condition enters at.
    fn in_pos(pos_x: f64, positive: bool) -> f64 {
        if positive { -pos_x } else { 1.0 - pos_x }
    }

    /// Direction `x` moved in since the last accepted step, and `|dx|`.
    fn progress(&self, pos_x: f64) -> (Option<bool>, f64) {
        let d = pos_x - self.old_pos_x;
        if d > 0.0 {
            (Some(true), d)
        } else if d < 0.0 {
            (Some(false), -d)
        } else {
            (None, 0.0)
        }
    }

    /// C `storeSpatialDistribution`: an accepted step, so the boundary condition
    /// becomes a new node at the input edge and whatever left the domain is dropped.
    fn store(&mut self, index: u32, time: f64, in0: f64, in1: f64, pos_x: f64, positive: bool, initial: bool) {
        let pos_x = self.shift(pos_x);
        omclog::info!(
            omclog::SPATIALDISTR,
            true,
            "Calling storeSpatialDistribution (index={index}, time={})",
            e(time),
        );
        omclog::info!(
            omclog::SPATIALDISTR,
            false,
            "spatialDistribution({}, {}, {}, {})",
            f(in0),
            f(in1),
            f(pos_x),
            if positive { "true" } else { "false" },
        );
        self.log_lists();

        // Standing still: only the inflowing boundary value changes. `old_pos_x` is
        // kept, so small moves add up until they count.
        let (moved, dx) = self.progress(pos_x);
        if dx <= zero_delta_x(self.old_pos_x, pos_x) {
            self.store_boundary(positive, if positive { in0 } else { in1 });
            if self.has_stored_inlet && !initial {
                self.prune(positive);
            }
            self.has_stored_inlet = true;
            omclog::close(omclog::SPATIALDISTR);
            return;
        }

        // The sign of the actual progress outranks the operator's argument: with
        // `positiveVelocity` inside a `noEvent` the argument can lag a reversal.
        let positive = moved.unwrap_or(positive);
        if self.read_output(pos_x, positive).events < 0 {
            omclog::close(omclog::SPATIALDISTR);
            return;
        }

        // A node at the input edge, or -- when the edge did not move -- a
        // discontinuity on top of the node already sitting there. Event nodes go
        // exactly onto the existing position: `prune` computes edge positions as
        // `edge +/- 1`, so the freshly computed edge can be an ulp off it.
        let edge = Self::in_pos(pos_x, positive);
        let old = if positive { self.front() } else { self.back() };
        let in_val = if positive { in0 } else { in1 };
        if (edge - old.pos).abs() < pos_eps(edge, old.pos) {
            if (old.val - in_val).abs() > val_eps(old.val, in_val) {
                self.add_node(positive, old.pos, in_val, true);
            }
        } else {
            self.add_node(positive, edge, in_val, false);
        }

        let walked = self.prune(positive);
        if walked > 1 {
            warn_step_size_too_big(&mut self.n_warnings_removed_events, "Removed", time, index, walked);
        }
        self.old_pos_x = pos_x;
        self.has_stored_inlet = true;
        omclog::close(omclog::SPATIALDISTR);
    }

    /// C `storeBoundarySpatialDistribution`: while `x` stands still a changed
    /// boundary value becomes an event at the input edge. If the edge already is
    /// one its value is overwritten: the values in between occupy no length.
    fn store_boundary(&mut self, front: bool, val: f64) {
        let n = self.profile.len();
        let (edge, neighbor) = if front { (0, 1) } else { (n - 1, n - 2) };
        let old = self.profile[edge];
        if (old.val - val).abs() <= val_eps(old.val, val) {
            return;
        }
        let other = self.profile[neighbor].pos;
        if (old.pos - other).abs() < pos_eps(old.pos, other) {
            omclog::info!(
                omclog::SPATIALDISTR,
                false,
                "Overwriting {} event value with {}.",
                if front { "front" } else { "back" },
                e(val),
            );
            self.profile[edge].val = val;
        } else {
            self.add_node(front, old.pos, val, true);
        }
    }

    /// C `removeStaleEventsSpatialDistribution`: drop events beyond the new
    /// input edge before adding its discontinuity.
    fn remove_stale_events(&mut self, front: bool, pos: f64) {
        loop {
            let ev = if front { self.events.front() } else { self.events.back() };
            let Some(&ev) = ev else { break };
            if if front { ev.pos >= pos } else { ev.pos <= pos } {
                break;
            }
            omclog::info!(
                omclog::SPATIALDISTR,
                false,
                "Removing stale event ({},{}).",
                e(ev.pos),
                e(ev.sign),
            );
            self.last_event_sign = ev.sign;
            if front {
                self.events.pop_front();
            } else {
                self.events.pop_back();
            }
        }
    }

    /// C `addNewNodeSpatialDistribution`: a new node at the front (positive
    /// velocity) or the back, plus its event when it is a discontinuity.
    fn add_node(&mut self, front: bool, pos: f64, val: f64, is_event: bool) {
        omclog::info!(
            omclog::SPATIALDISTR,
            false,
            "Adding ({},{}) at {}.",
            e(pos),
            e(val),
            if front { "front" } else { "back" },
        );
        if front {
            if pos > self.front().pos {
                fatal("New front position is not smaller then previous first node.");
            }
            self.profile.push_front(Node { pos, val });
        } else {
            if pos < self.back().pos {
                fatal("New end position is not bigger then previous last node.");
            }
            self.profile.push_back(Node { pos, val });
        }
        if !is_event {
            self.log_lists();
            return;
        }
        self.remove_stale_events(front, pos);
        // The alternation is along the position axis, so the sign comes from the
        // neighbour at the end the node is added to.
        let sign = if front {
            match self.events.front() {
                None if self.last_event_sign == 0.0 => 1.0,
                None => -self.last_event_sign,
                Some(ev) => {
                    if pos > ev.pos {
                        fatal("New front position is not smaller then previous first event node.");
                    }
                    -ev.sign
                }
            }
        } else {
            match self.events.back() {
                None if self.last_event_sign == 0.0 => 1.0,
                None => -self.last_event_sign,
                Some(ev) => {
                    if pos < ev.pos {
                        fatal("New end position is not bigger then previous last event node.");
                    }
                    -ev.sign
                }
            }
        };
        let ev = Event { pos, sign };
        if front {
            self.events.push_front(ev);
        } else {
            self.events.push_back(ev);
        }
        omclog::info!(
            omclog::SPATIALDISTR,
            false,
            "Adding event ({},{}) at {}.",
            e(ev.pos),
            e(ev.sign),
            if front { "front" } else { "back" },
        );
        self.log_lists();
    }

    /// C `pruneSpatialDistribution`: cut the profile back to length 1, moving the
    /// node that straddles the output edge onto it, and drop the events that left
    /// with it. Returns how many discontinuities were dropped.
    fn prune(&mut self, positive: bool) -> i32 {
        let n = self.profile.len();
        let edge = if positive { self.front() } else { self.back() };
        let mut i = if positive { n - 1 } else { 0 };
        if (self.profile[i].pos - edge.pos).abs() + pos_eps(self.profile[i].pos, edge.pos) < 1.0 {
            fatal(
                "Error for spatialDistribution in function pruneSpatialDistribution.\n\
                 This case should not be possible. Please open a bug report about it.",
            );
        }
        let mut prev = i;
        let mut walked = 0;
        let mut inside = false;
        while i != if positive { 0 } else { n - 1 } {
            i = if positive { i - 1 } else { i + 1 };
            if (self.profile[prev].pos - self.profile[i].pos).abs()
                < pos_eps(self.profile[prev].pos, self.profile[i].pos)
            {
                walked += 1;
            }
            let d = (self.profile[i].pos - edge.pos).abs();
            if d + pos_eps(self.profile[i].pos, edge.pos) < 1.0 {
                inside = true;
                break;
            }
            prev = i;
        }
        // `prev` is the first node still outside the domain: interpolate it onto
        // the output edge and drop everything past it.
        if inside {
            let target = if positive { edge.pos + 1.0 } else { edge.pos - 1.0 };
            let (left, right) = if positive {
                (self.profile[i], self.profile[prev])
            } else {
                (self.profile[prev], self.profile[i])
            };
            self.profile[prev] = Node {
                pos: target,
                val: interpolate(left, right, target),
            };
            omclog::info!(
                omclog::SPATIALDISTR,
                false,
                "Interpolate at {}",
                if positive { "end" } else { "front" },
            );
        }
        if positive {
            self.profile.truncate(prev + 1);
        } else {
            self.profile.drain(..prev);
        }

        for _ in 0..walked {
            let event = if positive {
                self.events.pop_back()
            } else {
                self.events.pop_front()
            };
            if let Some(event) = event {
                self.last_event_sign = event.sign;
            }
        }
        self.log_lists();
        walked
    }

    /// C `findOppositeEndSpatialDistribution`: `z` at the output edge for the `x`
    /// of this call, walking in from the stored output edge.
    fn read_output(&mut self, pos_x: f64, positive: bool) -> Read {
        self.needs_history = false;
        let n = self.profile.len();
        let first = self.front();
        let last = self.back();
        let read = Self::out_pos(pos_x, positive);

        if (positive && read < first.pos - pos_eps(read, first.pos))
            || (!positive && read > last.pos + pos_eps(read, last.pos))
        {
            self.needs_history = true;
            return Read {
                out: f64::NAN,
                event_pre: None,
                events: -1,
            };
        }

        // Clamped: `x` may have moved backwards since the last accepted step.
        let read = if positive {
            read.min(last.pos)
        } else {
            read.max(first.pos)
        };
        let edge_pos = if positive { first.pos } else { last.pos };
        let mut i = if positive { n - 1 } else { 0 };
        if (self.profile[i].pos - edge_pos).abs() + pos_eps(self.profile[i].pos, edge_pos) < 1.0 {
            fatal(
                "Error for spatialDistribution in function findOppositeEndSpatialDistribution.\n\
                 This case should not be possible. Please open a bug report about it.",
            );
        }
        let mut prev = i;
        let mut walked = 0;
        let mut event_pre = None;
        let mut passed = false;
        loop {
            if positive {
                if i == 0 {
                    break;
                }
                i -= 1;
            } else {
                if i + 1 == n {
                    break;
                }
                i += 1;
            }
            if (self.profile[prev].pos - self.profile[i].pos).abs()
                < pos_eps(self.profile[prev].pos, self.profile[i].pos)
            {
                event_pre.get_or_insert(self.profile[prev].val);
                walked += 1;
            }
            let beyond = if positive {
                self.profile[i].pos < read
            } else {
                self.profile[i].pos > read
            };
            if beyond && (self.profile[i].pos - read).abs() > pos_eps(self.profile[i].pos, read) {
                passed = true;
                break;
            }
            prev = i;
        }
        let out = if !passed {
            // The read position is at or beyond the far end of the stored profile.
            if positive { first.val } else { last.val }
        } else if positive {
            interpolate(self.profile[i], self.profile[prev], read)
        } else {
            interpolate(self.profile[prev], self.profile[i], read)
        };
        Read {
            out,
            event_pre,
            events: walked,
        }
    }

    /// C `spatialDistribution`: `(out0, out1)` for the `x` of this call, without
    /// storing anything — the step may still be rejected.
    fn value(&mut self, index: u32, time: f64, pos_x: f64, positive: bool, mode: u32) -> (f64, f64) {
        if mode == MODE_INITIAL {
            self.start_pos_x = Some(pos_x);
        }
        let pos_x = self.shift(pos_x);
        omclog::info!(
            omclog::SPATIALDISTR,
            true,
            "Calling spatialDistribution (index={index}, time={})",
            e(time),
        );
        self.log_lists();
        let discrete = mode != MODE_CONTINUOUS && mode != MODE_INITIAL;
        let (out0, out1) = {
            let read = self.read_output(pos_x, positive);
            if read.events < 0 {
                self.out1 = f64::NAN;
                omclog::close(omclog::SPATIALDISTR);
                return (f64::NAN, f64::NAN);
            }
            if read.events > 1 {
                warn_step_size_too_big(
                    &mut self.n_warnings_output_events,
                    "Need to output",
                    time,
                    index,
                    read.events,
                );
            }
            // A discontinuity reached the output edge: a continuous call reports the
            // value in front of it so the zero crossing has something to bracket; the
            // event call that follows reports the value behind it.
            let mut out = read.out;
            if read.events > 0 && !discrete {
                if let Some(pre) = read.event_pre {
                    omclog::info!(
                        omclog::SPATIALDISTR,
                        false,
                        "Found event in spatial distribution at time {}",
                        f(time),
                    );
                    out = pre;
                }
            }
            // MLS 3.7.4.2 uses the stored incoming value to avoid an algebraic loop.
            if positive {
                (self.front().val, out)
            } else {
                (out, self.back().val)
            }
        };
        omclog::info!(omclog::SPATIALDISTR, false, "(out0,out1) = ({}, {})", f(out0), f(out1));
        omclog::close(omclog::SPATIALDISTR);
        self.out1 = out1;
        (out0, out1)
    }

    /// Event indicator for the next discontinuity leaving the profile.
    fn zc(&self, pos_x: f64, positive: bool, zc_pre: f64) -> f64 {
        if self.events.is_empty() {
            let zc_pre = if self.last_event_sign != 0.0 {
                (if positive { 1.0 } else { -1.0 }) * self.last_event_sign
            } else {
                zc_pre
            };
            omclog::info!(
                omclog::SPATIALDISTR,
                false,
                "spatialDistributionZeroCrossing({}) = {} (no stored events, returning previous value)",
                e(pos_x),
                e(zc_pre),
            );
            return zc_pre;
        }
        // Deliberately *not* `shift`: the solver evaluates this unconditionally, also
        // while the operator is frozen inside an inactive `if`-branch, and capturing
        // the start position here would start it too early (#16099). Not started means
        // its zero point is still open, so report the value it will have at x = 0 —
        // else activating the branch flips the crossing for a discontinuity that has
        // not moved.
        let pos_x = match self.start_pos_x {
            Some(start) => pos_x - start,
            None => 0.0,
        };
        let event = if positive {
            self.events.back().unwrap()
        } else {
            self.events.front().unwrap()
        };
        let value = if positive {
            if 1.0 - pos_x >= event.pos - SPATIAL_EPS {
                -event.sign
            } else {
                event.sign
            }
        } else if -pos_x < event.pos {
            event.sign
        } else {
            -event.sign
        };
        omclog::info!(
            omclog::SPATIALDISTR,
            false,
            "List of events for spatialDistributionZeroCrossing({}) = {}",
            e(pos_x),
            e(value),
        );
        self.log_lists();
        value
    }
}

/// One `spatialDistribution(...)` operator per index, for one run.
pub struct SpatialState {
    ops: Vec<Spatial>,
    checkpoint: Vec<Spatial>,
}

#[derive(Clone, Copy)]
#[repr(u32)]
pub enum History {
    Needed = 1,
    Clear,
    Save,
    Restore,
}

impl SpatialState {
    /// The number of spatialDistribution operators.
    pub fn count(&self) -> usize {
        self.ops.len()
    }

    /// Every operator as flat words, for an FMU state.
    pub fn to_words(&self, out: &mut Vec<f64>) {
        out.push(self.ops.len() as f64);
        for s in &self.ops {
            out.push(s.profile.len() as f64);
            for n in &s.profile {
                out.extend([n.pos, n.val]);
            }
            out.push(s.events.len() as f64);
            for ev in &s.events {
                out.extend([ev.pos, ev.sign]);
            }
            out.extend([
                s.initialized as u8 as f64,
                s.start_pos_x.is_some() as u8 as f64,
                s.start_pos_x.unwrap_or(0.0),
                s.old_pos_x,
                s.last_event_sign,
                s.out1,
                s.n_warnings_removed_events as f64,
                s.n_warnings_output_events as f64,
                s.has_stored_inlet as u8 as f64,
            ]);
        }
    }

    /// [`SpatialState::to_words`]'s inverse.
    pub fn from_words(w: &mut dyn Iterator<Item = f64>) -> Option<Self> {
        let n = w.next()? as usize;
        let mut ops = Vec::with_capacity(n.min(w.size_hint().0));
        for _ in 0..n {
            let mut s = Spatial::new();
            for _ in 0..w.next()? as usize {
                s.profile.push_back(Node {
                    pos: w.next()?,
                    val: w.next()?,
                });
            }
            for _ in 0..w.next()? as usize {
                s.events.push_back(Event {
                    pos: w.next()?,
                    sign: w.next()?,
                });
            }
            s.initialized = w.next()? != 0.0;
            let has_start = w.next()? != 0.0;
            let start = w.next()?;
            s.start_pos_x = has_start.then_some(start);
            s.old_pos_x = w.next()?;
            s.last_event_sign = w.next()?;
            s.out1 = w.next()?;
            s.n_warnings_removed_events = w.next()? as u64;
            s.n_warnings_output_events = w.next()? as u64;
            s.has_stored_inlet = w.next()? != 0.0;
            ops.push(s);
        }
        Some(SpatialState {
            ops,
            checkpoint: Vec::new(),
        })
    }

    /// C `allocSpatialDistribution`: `n` uninitialized operators for a fresh run.
    pub fn new(n: usize) -> Self {
        omclog::info!(
            omclog::SPATIALDISTR,
            false,
            "Allocating memory for {n} spatial distribution(s).",
        );
        SpatialState {
            ops: (0..n).map(|_| Spatial::new()).collect(),
            checkpoint: Vec::new(),
        }
    }

    fn at(&mut self, index: u32) -> &mut Spatial {
        match self.ops.get_mut(index as usize) {
            Some(s) => s,
            None => fatal("spatialDistribution: operator index out of range"),
        }
    }

    /// [`Self::at`] for the calls that read the profile: an index the backend
    /// allocated but never handed an initial profile to would otherwise index an
    /// empty deque.
    fn at_ready(&mut self, index: u32) -> &mut Spatial {
        let s = self.at(index);
        if !s.initialized {
            fatal("spatialDistribution was evaluated before its initial profile was set.");
        }
        s
    }

    /// C `initSpatialDistribution`: fill operator `index` from its `initialPoints`
    /// / `initialValues` parameter arrays.
    pub fn init_profile(&mut self, index: u32, points: &[f64], values: &[f64]) {
        self.at(index).init_profile(index, points, values)
    }

    /// C `storeSpatialDistribution`: commit the boundary condition of an accepted step.
    pub fn store(&mut self, index: u32, time: f64, in0: f64, in1: f64, pos_x: f64, positive: bool, initial: bool) {
        self.at_ready(index)
            .store(index, time, in0, in1, pos_x, positive, initial)
    }

    pub fn value(&mut self, index: u32, time: f64, pos_x: f64, positive: bool, mode: u32) -> (f64, f64) {
        self.at_ready(index).value(index, time, pos_x, positive, mode)
    }

    pub fn needs_history(&mut self, reset: bool) -> bool {
        let needed = self.ops.iter().any(|s| s.needs_history);
        if reset {
            for s in &mut self.ops {
                s.needs_history = false;
            }
        }
        needed
    }

    pub fn history(&mut self, action: History) -> bool {
        match action {
            History::Needed => return self.needs_history(false),
            History::Clear => return self.needs_history(true),
            History::Save => self.checkpoint.clone_from(&self.ops),
            History::Restore => {
                self.ops.clone_from(&self.checkpoint);
                self.needs_history(true);
            }
        }
        !self.ops.is_empty()
    }

    /// The second output of the preceding [`Self::value`] of the same operator, for
    /// a host whose ABI returns one value per call.
    pub fn out1(&mut self, index: u32) -> f64 {
        self.at(index).out1
    }

    /// C `spatialDistributionZeroCrossing`.
    pub fn zc(&mut self, index: u32, pos_x: f64, positive: bool, zc_pre: f64) -> f64 {
        self.at(index).zc(pos_x, positive, zc_pre)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A belt initialized as `functionInitSpatialDistribution` does, then called
    /// once at `x = 0` as the driver's initialization does (that first call is what
    /// fixes the operator's zero point).
    fn belt(points: &[f64], values: &[f64]) -> Spatial {
        let mut s = Spatial::new();
        s.init_profile(0, points, values);
        s.value(0, 0.0, 0.0, true, MODE_CONTINUOUS);
        s.store(0, 0.0, values[0], values[values.len() - 1], 0.0, true, false);
        s
    }

    /// Transport at unit velocity in `n` steps of `h`: `(time, out0, out1)` per step,
    /// evaluated then stored as an accepted step, like the driver does.
    fn run(
        s: &mut Spatial,
        in0: impl Fn(f64) -> f64,
        in1: impl Fn(f64) -> f64,
        positive: bool,
        h: f64,
        n: usize,
    ) -> Vec<(f64, f64, f64)> {
        let mut out = Vec::new();
        for k in 1..=n {
            let t = k as f64 * h;
            let x = if positive { t } else { -t };
            let (o0, o1) = s.value(0, t, x, positive, MODE_CONTINUOUS);
            out.push((t, o0, o1));
            s.store(0, t, in0(t), in1(t), x, positive, false);
        }
        out
    }

    #[test]
    fn flat_profile_is_a_pure_delay() {
        let mut s = belt(&[0.0, 1.0], &[0.0, 0.0]);
        // Velocity 1 over a domain of length 1: out1(t) = in0(t - 1).
        for (t, _, o1) in run(&mut s, |t| t, |_| 0.0, true, 0.01, 200) {
            let want = if t < 1.0 { 0.0 } else { t - 1.0 };
            assert!((o1 - want).abs() < 1e-9, "t={t}: out1={o1}, want {want}");
        }
        assert_eq!(s.value(0, 2.5, 2.5, true, MODE_CONTINUOUS).0, 2.0);
        s.store(0, 2.5, 2.5, 0.0, 2.5, true, false);
        assert_eq!(s.value(0, 2.5, 2.5, true, MODE_CONTINUOUS).0, 2.5);
    }

    #[test]
    fn initial_profile_leaves_in_order() {
        // A ramp 1 -> 0 over the domain: the right edge sees 0, 0.05, 0.1, ...
        let mut s = belt(&[0.0, 1.0], &[1.0, 0.0]);
        for (t, _, o1) in run(&mut s, |_| 0.0, |_| 0.0, true, 0.05, 20) {
            assert!((o1 - t).abs() < 1e-9, "t={t}: out1={o1}");
        }
    }

    #[test]
    fn negative_velocity_transports_in1_to_out0() {
        let mut s = belt(&[0.0, 1.0], &[0.0, 0.0]);
        for (t, o0, _) in run(&mut s, |_| 0.0, |t| t, false, 0.01, 200) {
            let want = if t < 1.0 { 0.0 } else { t - 1.0 };
            assert!((o0 - want).abs() < 1e-9, "t={t}: out0={o0}, want {want}");
        }
        assert_eq!(s.value(0, 2.5, -2.5, false, MODE_CONTINUOUS).1, 2.0);
        s.store(0, 2.5, 0.0, 2.5, -2.5, false, false);
        assert_eq!(s.value(0, 2.5, -2.5, false, MODE_CONTINUOUS).1, 2.5);
    }

    #[test]
    fn zero_crossing_flips_when_a_discontinuity_reaches_the_output() {
        // Discontinuity at the middle of the domain: it reaches xi = 1 at x = 0.5.
        let s = belt(&[0.0, 0.5, 0.5, 1.0], &[2.0, 2.0, 1.0, 1.0]);
        let before = s.zc(0.0, true, 0.0);
        assert_eq!(s.zc(0.49, true, 0.0), before, "no flip before the event");
        assert_eq!(s.zc(0.51, true, 0.0), -before, "flip after the event");
        // And it stays flipped further along.
        assert_eq!(s.zc(0.9, true, 0.0), -before);
    }

    #[test]
    fn an_announced_crossing_leaves_the_list_only_in_prune() {
        // C removes a discontinuity in `pruneSpatialDistribution` alone; evaluating
        // the operator never touches the event list.
        let mut s = belt(&[0.0, 0.3, 0.3, 0.5, 0.5, 1.0], &[3.0, 3.0, 2.0, 2.0, 1.0, 1.0]);
        let before = s.zc(0.0, true, 0.0);
        assert_eq!(s.zc(0.5, true, 0.0), before, "not flipped yet at the root");
        s.value(0, 0.5, 0.5, true, MODE_CONTINUOUS);
        s.store(0, 0.5, 0.0, 0.0, 0.5, true, false);
        s.value(0, 0.5, 0.5, true, MODE_EVENT);
        assert_eq!(s.zc(0.5, true, before), -before, "pruning consumed the outgoing jump");
        assert_eq!(s.zc(0.5001, true, before), -before, "flipped once x is past it");
        let mut s = belt(&[0.0, 0.5, 0.5, 1.0], &[0.0, 0.0, 1.0, 1.0]);
        s.store(0, 0.75, 0.0, 1.0, -0.75, false, false);
        assert!(s.events.is_empty());
        let before = s.zc(-0.75, false, 0.0);
        s.store(0, 0.75, 0.0, 2.0, -0.75, false, false);
        assert_eq!(s.zc(-0.75, false, before), before);
    }

    #[test]
    fn zero_crossing_holds_its_previous_value_without_events() {
        let s = belt(&[0.0, 1.0], &[0.0, 0.0]);
        assert_eq!(s.zc(0.3, true, 1.0), 1.0);
        assert_eq!(s.zc(0.3, true, -1.0), -1.0);
    }

    #[test]
    fn continuous_call_reports_the_value_in_front_of_a_discontinuity() {
        let mut s = belt(&[0.0, 0.5, 0.5, 1.0], &[2.0, 2.0, 1.0, 1.0]);
        // A step that walks the discontinuity past the output edge: the continuous
        // call still reports the value in front of it, so the zero crossing has a
        // sign change to bracket; the event call that follows reports the one behind.
        let (_, pre) = s.value(0, 0.6, 0.6, true, MODE_CONTINUOUS);
        assert_eq!(pre, 1.0);
        // The driver stores the accepted point before running the discrete update,
        // so the event call sees the same `x` (a moved `x` there is an error).
        s.store(0, 0.6, 0.0, 0.0, 0.6, true, false);
        let (_, post) = s.value(0, 0.6, 0.6, true, MODE_EVENT);
        assert_eq!(post, 2.0);
    }

    #[test]
    fn discontinuity_count_survives_pruning() {
        // Two discontinuities inside one step: both are reported as walked over.
        let mut s = belt(&[0.0, 0.3, 0.3, 0.6, 0.6, 1.0], &[3.0, 3.0, 2.0, 2.0, 1.0, 1.0]);
        assert_eq!(s.read_output(0.75, true).events, 2);
    }

    #[test]
    fn standing_still_reports_the_stored_edges() {
        let mut s = belt(&[0.0, 1.0], &[7.0, 9.0]);
        let (o0, o1) = s.value(0, 0.0, 0.0, true, MODE_CONTINUOUS);
        assert_eq!((o0, o1), (7.0, 9.0));
    }

    #[test]
    fn nonzero_start_position_behaves_like_zero() {
        let mut a = belt(&[0.0, 1.0], &[0.0, 0.0]);
        let mut b = Spatial::new();
        b.init_profile(0, &[0.0, 1.0], &[0.0, 0.0]);
        // Same run, but x starts at 5 instead of 0.
        b.value(0, 0.0, 5.0, true, MODE_CONTINUOUS);
        b.store(0, 0.0, 0.0, 0.0, 5.0, true, false);
        for k in 1..=150 {
            let t = k as f64 * 0.01;
            let (_, ra) = a.value(0, t, t, true, MODE_CONTINUOUS);
            a.store(0, t, t, 0.0, t, true, false);
            let (_, rb) = b.value(0, t, 5.0 + t, true, MODE_CONTINUOUS);
            b.store(0, t, t, 0.0, 5.0 + t, true, false);
            assert!((ra - rb).abs() < 1e-12, "t={t}: {ra} vs {rb}");
        }
    }

    #[test]
    fn missing_history_requires_subdivision_in_both_directions() {
        for positive in [true, false] {
            let mut s = belt(&[0.0, 1.0], &[0.0, 0.0]);
            let x = if positive { 2.5 } else { -2.5 };
            let (a, b) = s.value(0, 0.5, x, positive, MODE_CONTINUOUS);
            assert!(a.is_nan() && b.is_nan());
            assert!(s.needs_history);
            let (a, b) = s.value(0, 0.1, x / 5.0, positive, MODE_CONTINUOUS);
            assert!(a.is_finite() && b.is_finite());
            assert!(!s.needs_history);
        }
    }

    #[test]
    fn profile_length_stays_bounded() {
        let mut s = belt(&[0.0, 1.0], &[0.0, 0.0]);
        run(&mut s, |t| t, |_| 0.0, true, 0.001, 5000);
        // One domain length of material at a 0.001 step is ~1000 nodes plus the
        // edges, not one per step.
        assert!(s.profile.len() < 1100, "profile grew to {}", s.profile.len());
    }

    #[test]
    fn standing_still_keeps_one_event_at_the_input_edge() {
        let mut s = belt(&[0.0, 1.0], &[0.0, 0.0]);
        for k in 1..=100 {
            let t = k as f64 * 0.01;
            s.store(0, t, t, 0.0, 0.0, true, false);
        }
        assert_eq!((s.profile.len(), s.events.len()), (3, 1));
        assert_eq!(s.front().val, 1.0);
        // Moving on transports the last boundary value.
        let (_, o1) = s.value(0, 2.0, 0.999, true, MODE_CONTINUOUS);
        assert!((o1 - 0.0).abs() < 1e-9, "out1={o1}");
    }

    #[test]
    fn reversal_drops_events_that_left_the_domain() {
        let mut s = belt(&[0.0, 1.0], &[0.0, 0.0]);
        s.store(0, 0.1, 1.0, 0.0, 0.0, true, false);
        s.store(0, 0.2, 1.0, 0.0, 2e-12, true, false);
        // Back by more than SPATIAL_ZERO_DELTA_X: the event at 0 is cut off the
        // profile but kept within the tolerance of the front edge.
        s.store(0, 0.3, 1.0, 0.0, -0.5e-12, false, false);
        s.store(0, 0.4, 2.0, 0.0, -0.5e-12, true, false);
        assert_eq!(s.events.len(), 1);
        assert_eq!(s.events[0].pos, s.front().pos);
    }

    #[test]
    fn reversal_transports_the_material_back_out() {
        let mut s = belt(&[0.0, 1.0], &[0.0, 0.0]);
        // Fill half the domain with 1.0 from the left, then reverse.
        for k in 1..=50 {
            let t = k as f64 * 0.01;
            s.value(0, t, t, true, MODE_CONTINUOUS);
            s.store(0, t, 1.0, 0.0, t, true, false);
        }
        let mut seen = 0.0f64;
        for k in 1..=40 {
            let t = 0.5 + k as f64 * 0.01;
            let x = 0.5 - k as f64 * 0.01;
            let (o0, _) = s.value(0, t, x, false, MODE_CONTINUOUS);
            s.store(0, t, 1.0, 0.0, x, false, false);
            seen = seen.max(o0);
        }
        // What went in on the left comes back out of the left.
        assert!((seen - 1.0).abs() < 1e-9, "out0 peaked at {seen}");
    }
}
