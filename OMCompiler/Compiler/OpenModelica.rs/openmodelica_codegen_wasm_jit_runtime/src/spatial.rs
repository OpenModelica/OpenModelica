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
//! a ring buffer fits it exactly, and the contiguous storage makes the
//! zero-crossing lookup a binary search instead of a walk (see [`Spatial::zc`]).
//! State is a module global (single-threaded wasm), reset by `rt_spatial_init`.

use alloc::collections::VecDeque;
use alloc::format;
use alloc::vec::Vec;
use core::cell::UnsafeCell;

use crate::omclog;

/// The relation evaluation modes `rt_spatial_eval` is handed (`SimLayout`'s
/// `rel_fresh`): continuous integration, an event update, the initial system.
const MODE_CONTINUOUS: u32 = 0;
#[cfg(test)]
const MODE_EVENT: u32 = 1;

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
    if SPATIAL_ZERO_DELTA_X > e { SPATIAL_ZERO_DELTA_X } else { e }
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

fn f(v: f64) -> alloc::string::String {
    format!("{v:.6}")
}

fn e(v: f64) -> alloc::string::String {
    omclog::e(v, 0, 6)
}

/// C's `errorStreamPrint(OMC_LOG_STDOUT, ...)` + `omc_throw_function`.
fn fatal(msg: &str) -> ! {
    omclog::error(omclog::STDOUT, false, msg);
    crate::trap()
}

fn interpolate(left: Node, right: Node, at: f64) -> f64 {
    let d = right.pos - left.pos;
    if !(d > 0.0) {
        fatal("interpolateTransportedQuantity: wrong order or same position!");
    }
    left.val * ((right.pos - at) / d) + right.val * ((at - left.pos) / d)
}

fn extrapolate(left: Node, right: Node, at: f64) -> f64 {
    let d = right.pos - left.pos;
    if !(d > 0.0) {
        fatal("extrapolateTransportedQuantity: wrong order or same position!");
    }
    left.val + (right.val - left.val) / d * (at - left.pos)
}

/// What [`Spatial::read_output`] found at the output edge.
struct Read {
    out: f64,
    /// Value in front of the last discontinuity walked over.
    event_pre: Option<f64>,
    /// Number of discontinuities between the stored output edge and the new one.
    events: i32,
}

/// One `spatialDistribution(...)` operator's state.
struct Spatial {
    profile: VecDeque<Node>,
    events: VecDeque<Event>,
    initialized: bool,
    /// `x` at the operator's first call. The operator only depends on the *change*
    /// of `x`, and the initial profile is stored assuming `x(t0) = 0`, so this is
    /// subtracted from every `x` (C's `startPosX`). Captured lazily: an operator
    /// inside an inactive `if`-branch must not start before the branch is taken.
    start_pos_x: Option<f64>,
    /// `x` at the last accepted step (C's `oldPosX`), shifted.
    old_pos_x: f64,
    /// `sign` of the last discontinuity that left the domain, so the alternation
    /// survives an event list that ran empty.
    last_event_sign: f64,
    /// Second output of the last [`Spatial::eval`], for [`rt_spatial_out1`].
    out1: f64,
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
        }
    }

    /// C's `doubleEndedListPrint`, minus the node addresses.
    fn log_lists(&self) {
        if !omclog::active(omclog::SPATIALDISTR) {
            return;
        }
        for n in &self.profile {
            omclog::info(omclog::SPATIALDISTR, false, &format!("({},{})", e(n.pos), e(n.val)));
        }
        omclog::info(omclog::SPATIALDISTR, false, "List of events");
        for ev in &self.events {
            omclog::info(omclog::SPATIALDISTR, false, &format!("({},{})", e(ev.pos), e(ev.sign)));
        }
    }

    /// C `initSpatialDistribution`: the parameter profile becomes the initial one,
    /// with an event for every pair of `initialPoints` sharing a position.
    fn init_profile(&mut self, index: u32, points: &[f64], values: &[f64]) {
        omclog::info(
            omclog::SPATIALDISTR,
            true,
            &format!("Initializing spatial distributions (index={index})"),
        );
        let n = points.len();
        if n < 2 || values.len() != n {
            fatal("Initialization of spatial distribution failed: initialPoints and initialValues must have the same size >= 2.");
        }
        if points[0].abs() > SPATIAL_EPS {
            omclog::error(
                omclog::STDOUT,
                true,
                &format!("Initialization of spatial distribution with index {index} failed."),
            );
            fatal(&format!("initialPoints[0] = {} is not zero.", e(points[0])));
        }
        if (points[n - 1] - 1.0).abs() > SPATIAL_EPS {
            omclog::error(
                omclog::STDOUT,
                true,
                &format!("Initialization of spatial distribution with index {index} failed."),
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
                omclog::error(
                    omclog::STDOUT,
                    true,
                    &format!("Initialization of spatial distribution with index {index} failed."),
                );
                omclog::error(
                    omclog::STDOUT,
                    false,
                    &format!("initialPoints[{i}] > initialPoints[{}]", i + 1),
                );
                fatal(&format!("{} > {}", f(points[i]), f(points[i + 1])));
            }
            self.profile.push_back(Node { pos: points[i], val: values[i] });
            if points[i] == points[i + 1] {
                num_same += 1;
                if num_same > 1 {
                    omclog::error(
                        omclog::STDOUT,
                        true,
                        &format!("Initialization of spatial distribution with index {index} failed."),
                    );
                    omclog::error(
                        omclog::STDOUT,
                        false,
                        &format!(
                            "initialPoints[{}] = initialPoints[{i}] = initialPoints[{}]",
                            i - 1,
                            i + 1
                        ),
                    );
                    fatal("Only events with one pre-value and one value are allowed.");
                }
                sign = -sign;
                self.events.push_back(Event { pos: points[i], sign });
            } else {
                num_same = 0;
            }
        }
        self.profile.push_back(Node { pos: points[n - 1], val: values[n - 1] });
        self.initialized = true;
        self.log_lists();
        omclog::close(omclog::SPATIALDISTR);
        omclog::info(
            omclog::SPATIALDISTR,
            false,
            &format!("Finished initializing spatial distribution (index={index})"),
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
    fn store(&mut self, index: u32, time: f64, in0: f64, in1: f64, pos_x: f64, positive: bool) {
        let pos_x = self.shift(pos_x);
        omclog::info(
            omclog::SPATIALDISTR,
            true,
            &format!("Calling storeSpatialDistribution (index={index}, time={})", e(time)),
        );
        omclog::info(
            omclog::SPATIALDISTR,
            false,
            &format!(
                "spatialDistribution({}, {}, {}, {})",
                f(in0),
                f(in1),
                f(pos_x),
                if positive { "true" } else { "false" }
            ),
        );
        self.log_lists();

        // The sign of the actual progress outranks the operator's argument: with
        // `positiveVelocity` inside a `noEvent` the argument can lag a reversal.
        let (moved, _) = self.progress(pos_x);
        let positive = moved.unwrap_or(positive);

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
            omclog::warning(
                omclog::STDOUT,
                true,
                "Removed more then one event from spatialDistribution. Step size to big!",
            );
            omclog::warning(
                omclog::STDOUT,
                false,
                &format!(
                    "time: {}, spatialDistribution index: {index}, number of events: {walked}",
                    f(time)
                ),
            );
            omclog::close_warning(omclog::STDOUT);
        }
        self.old_pos_x = pos_x;
        omclog::close(omclog::SPATIALDISTR);
    }

    /// C `addNewNodeSpatialDistribution`: a new node at the front (positive
    /// velocity) or the back, plus its event when it is a discontinuity.
    fn add_node(&mut self, front: bool, pos: f64, val: f64, is_event: bool) {
        omclog::info(
            omclog::SPATIALDISTR,
            false,
            &format!(
                "Adding ({},{}) at {}.",
                e(pos),
                e(val),
                if front { "front" } else { "back" }
            ),
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
                None => 1.0,
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
        omclog::info(
            omclog::SPATIALDISTR,
            false,
            &format!(
                "Adding event ({},{}) at {}.",
                e(ev.pos),
                e(ev.sign),
                if front { "front" } else { "back" }
            ),
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
            self.profile[prev] = Node { pos: target, val: interpolate(left, right, target) };
            omclog::info(
                omclog::SPATIALDISTR,
                false,
                &format!("Interpolate at {}", if positive { "end" } else { "front" }),
            );
        }
        if positive {
            self.profile.truncate(prev + 1);
        } else {
            self.profile.drain(..prev);
        }

        // Events outside [leftEdge - SPATIAL_ZERO_DELTA_X, rightEdge + SPATIAL_ZERO_DELTA_X].
        if positive {
            while let Some(ev) = self.events.back().copied() {
                if edge.pos + 1.0 + zero_delta_x(edge.pos, ev.pos) >= ev.pos {
                    break;
                }
                self.last_event_sign = ev.sign;
                self.events.pop_back();
            }
        } else {
            while let Some(ev) = self.events.front().copied() {
                if edge.pos - 1.0 - zero_delta_x(edge.pos, ev.pos) <= ev.pos {
                    break;
                }
                self.last_event_sign = ev.sign;
                self.events.pop_front();
            }
        }
        self.log_lists();
        walked
    }

    /// C `findOppositeEndSpatialDistribution`: `z` at the output edge for the `x`
    /// of this call, walking in from the stored output edge.
    fn read_output(&self, in0: f64, in1: f64, pos_x: f64, positive: bool) -> Read {
        let n = self.profile.len();
        let first = self.front();
        let last = self.back();
        let read = Self::out_pos(pos_x, positive);

        // More than one domain length since the last accepted step: the material at
        // the output edge entered after it, so only the boundary condition describes it.
        if positive && read < first.pos {
            let inject = Node { pos: -pos_x, val: in0 };
            let out = interpolate(inject, first, read);
            return Read { out, event_pre: Some(out), events: self.events.len() as i32 };
        }
        if !positive && read > last.pos {
            let inject = Node { pos: 1.0 - pos_x, val: in1 };
            let out = interpolate(last, inject, read);
            return Read { out, event_pre: Some(out), events: self.events.len() as i32 };
        }

        // Clamped: `x` may have moved backwards since the last accepted step.
        let read = if positive { read.min(last.pos) } else { read.max(first.pos) };
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
                event_pre = Some(self.profile[prev].val);
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
        Read { out, event_pre, events: walked }
    }

    /// C `spatialDistribution`: `(out0, out1)` for the `x` of this call, without
    /// storing anything — the step may still be rejected.
    fn eval(
        &mut self,
        index: u32,
        time: f64,
        in0: f64,
        in1: f64,
        pos_x: f64,
        positive: bool,
        // C's `discreteCall` is `mode != MODE_CONTINUOUS`.
        mode: u32,
    ) -> (f64, f64) {
        let pos_x = self.shift(pos_x);
        omclog::info(
            omclog::SPATIALDISTR,
            true,
            &format!("Calling spatialDistribution (index={index}, time={})", e(time)),
        );
        omclog::info(
            omclog::SPATIALDISTR,
            false,
            &format!(
                "(out0,out1) = spatialDistribution(in0={}, in1={}, x={}, isPositiveVelocity={})",
                f(in0),
                f(in1),
                f(pos_x),
                if positive { "true" } else { "false" }
            ),
        );
        self.log_lists();

        let discrete = mode != MODE_CONTINUOUS;
        let (moved, delta) = self.progress(pos_x);
        let zdx = zero_delta_x(self.old_pos_x, pos_x);
        // The argument disagrees with the direction `x` actually moved in. Trust
        // the movement, but remember that the velocity sign is in doubt.
        let jumped = delta > zdx && moved == Some(!positive);
        let positive = if jumped { !positive } else { positive };
        if delta > zdx && discrete {
            fatal(&format!(
                "x got reinitialized during an event at time {}. OpenModelica can't handle that.",
                f(time)
            ));
        }

        let (out0, out1) = if delta < pos_eps(self.old_pos_x, pos_x) {
            (self.front().val, self.back().val)
        } else {
            let read = self.read_output(in0, in1, pos_x, positive);
            if read.events > 1 {
                omclog::warning(
                    omclog::STDOUT,
                    true,
                    "Need to output more then one event from spatialDistribution. Step size to big!",
                );
                omclog::warning(
                    omclog::STDOUT,
                    false,
                    &format!(
                        "time: {}, spatialDistribution index: {index}, number of events: {}",
                        f(time),
                        read.events
                    ),
                );
                omclog::close_warning(omclog::STDOUT);
            }
            // A discontinuity reached the output edge: a continuous call reports the
            // value in front of it so the zero crossing has something to bracket; the
            // event call that follows reports the value behind it.
            let mut out = read.out;
            if read.events > 0 && !discrete {
                if let Some(pre) = read.event_pre {
                    omclog::info(
                        omclog::SPATIALDISTR,
                        false,
                        &format!("Found event in spatial distribution at time {}", f(time)),
                    );
                    out = pre;
                }
            }
            // The input-side output is extrapolated rather than taken straight from
            // `in0`/`in1`, which would close an algebraic loop through the operator.
            // Suppressed after a `jumped` step: which input feeds which end is
            // exactly what is in doubt there.
            let n = self.profile.len();
            let extrapolate_ok = !jumped && delta > pos_eps(self.old_pos_x, pos_x);
            if positive {
                let (a, b) = (self.profile[0], self.profile[1]);
                let out0 = if extrapolate_ok && (a.pos - b.pos).abs() > pos_eps(a.pos, b.pos) {
                    extrapolate(a, b, -pos_x)
                } else {
                    a.val
                };
                (out0, out)
            } else {
                let (a, b) = (self.profile[n - 2], self.profile[n - 1]);
                let out1 = if extrapolate_ok && (a.pos - b.pos).abs() > pos_eps(a.pos, b.pos) {
                    extrapolate(a, b, 1.0 - pos_x)
                } else {
                    b.val
                };
                (out, out1)
            }
        };
        omclog::info(
            omclog::SPATIALDISTR,
            false,
            &format!("(out0,out1) = ({}, {})", f(out0), f(out1)),
        );
        omclog::close(omclog::SPATIALDISTR);
        self.out1 = out1;
        (out0, out1)
    }

    /// C `spatialDistributionZeroCrossing`: flips sign every time a stored
    /// discontinuity passes the output edge, so the root finder can place the event.
    ///
    /// C spells this out as two mirrored walks over the event list; both come down to
    /// the negated sign of the nearest discontinuity at or below the read position
    /// (the signs alternate, so "the one above, not negated" is the same value).
    fn zc(&self, pos_x: f64, positive: bool, zc_pre: f64) -> f64 {
        if self.events.is_empty() {
            omclog::info(
                omclog::SPATIALDISTR,
                false,
                &format!(
                    "spatialDistributionZeroCrossing({}) = {} (no stored events, returning previous value)",
                    e(pos_x),
                    e(zc_pre)
                ),
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
        let read = Self::out_pos(pos_x, positive);
        // Rightmost discontinuity at or below the read position. The tolerance is the
        // absolute `SPATIAL_EPS`: a wider one flips the value before the discontinuity
        // is reached, leaving no sign change to find.
        let below = self.events.partition_point(|ev| ev.pos <= read + SPATIAL_EPS);
        let value = if below == 0 { self.events[0].sign } else { -self.events[below - 1].sign };
        omclog::info(
            omclog::SPATIALDISTR,
            false,
            &format!(
                "List of events for spatialDistributionZeroCrossing({}) = {}",
                e(pos_x),
                e(value)
            ),
        );
        self.log_lists();
        value
    }
}

struct SpatialCell(UnsafeCell<Vec<Spatial>>);
// Single-threaded wasm: no concurrent access to the operator state.
unsafe impl Sync for SpatialCell {}
static SPATIAL: SpatialCell = SpatialCell(UnsafeCell::new(Vec::new()));

fn at(index: u32) -> &'static mut Spatial {
    let all = unsafe { &mut *SPATIAL.0.get() };
    match all.get_mut(index as usize) {
        Some(s) => s,
        None => fatal("spatialDistribution: operator index out of range (rt_spatial_init not called?)"),
    }
}

/// [`at`] for the calls that read the profile: an index the backend allocated but
/// never handed an initial profile to would otherwise index an empty deque.
fn at_ready(index: u32) -> &'static mut Spatial {
    let s = at(index);
    if !s.initialized {
        fatal("spatialDistribution was evaluated before its initial profile was set.");
    }
    s
}

/// (Re)allocate `n` uninitialized operators for a fresh run.
#[unsafe(no_mangle)]
pub extern "C" fn rt_spatial_init(n: u32) {
    omclog::info(
        omclog::SPATIALDISTR,
        false,
        &format!("Allocating memory for {n} spatial distribution(s)."),
    );
    let all = unsafe { &mut *SPATIAL.0.get() };
    all.clear();
    all.reserve(n as usize);
    for _ in 0..n {
        all.push(Spatial::new());
    }
}

/// Fill operator `index` from its `initialPoints` / `initialValues` arrays (Real
/// array handles, borrowed).
#[unsafe(no_mangle)]
pub extern "C" fn rt_spatial_init_profile(index: u32, points: u32, values: u32) {
    let read = |handle: u32| -> Vec<f64> {
        let n = crate::rt_array_total(handle);
        (1..=n as i32)
            .map(|k| unsafe { crate::load_f64(crate::rt_array_elem_ptr(handle, k)) })
            .collect()
    };
    let (p, v) = (read(points), read(values));
    at(index).init_profile(index, &p, &v);
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
    at_ready(index).store(index, time, in0, in1, pos_x, positive != 0);
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
    at_ready(index).eval(index, time, in0, in1, pos_x, positive != 0, mode).0
}

/// The second output of the preceding [`rt_spatial_eval`] of the same operator.
/// The codegen emits the two back to back for one `spatialDistribution(...)` call,
/// which is C's `double* out1` out-parameter without the scratch address.
#[unsafe(no_mangle)]
pub extern "C" fn rt_spatial_out1(index: u32) -> f64 {
    at(index).out1
}

/// C `spatialDistributionZeroCrossing`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_spatial_zc(index: u32, pos_x: f64, positive: u32, zc_pre: f64) -> f64 {
    at(index).zc(pos_x, positive != 0, zc_pre)
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
        s.eval(0, 0.0, values[0], values[values.len() - 1], 0.0, true, MODE_CONTINUOUS);
        s.store(0, 0.0, values[0], values[values.len() - 1], 0.0, true);
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
            let (o0, o1) = s.eval(0, t, in0(t), in1(t), x, positive, MODE_CONTINUOUS);
            out.push((t, o0, o1));
            s.store(0, t, in0(t), in1(t), x, positive);
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
        s.eval(0, 0.5, 0.0, 0.0, 0.5, true, MODE_CONTINUOUS);
        s.store(0, 0.5, 0.0, 0.0, 0.5, true);
        s.eval(0, 0.5, 0.0, 0.0, 0.5, true, MODE_EVENT);
        assert_eq!(s.zc(0.5, true, before), before, "the event update left the list alone");
        assert_eq!(s.zc(0.5001, true, before), -before, "flipped once x is past it");
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
        let (_, pre) = s.eval(0, 0.6, 0.0, 0.0, 0.6, true, MODE_CONTINUOUS);
        assert_eq!(pre, 1.0);
        // The driver stores the accepted point before running the discrete update,
        // so the event call sees the same `x` (a moved `x` there is an error).
        s.store(0, 0.6, 0.0, 0.0, 0.6, true);
        let (_, post) = s.eval(0, 0.6, 0.0, 0.0, 0.6, true, MODE_EVENT);
        assert_eq!(post, 2.0);
    }

    #[test]
    fn discontinuity_count_survives_pruning() {
        // Two discontinuities inside one step: both are reported as walked over.
        let s = belt(&[0.0, 0.3, 0.3, 0.6, 0.6, 1.0], &[3.0, 3.0, 2.0, 2.0, 1.0, 1.0]);
        assert_eq!(s.read_output(0.0, 0.0, 0.75, true).events, 2);
    }

    #[test]
    fn standing_still_reports_the_stored_edges() {
        let mut s = belt(&[0.0, 1.0], &[7.0, 9.0]);
        let (o0, o1) = s.eval(0, 0.0, 1.0, 2.0, 0.0, true, MODE_CONTINUOUS);
        assert_eq!((o0, o1), (7.0, 9.0));
    }

    #[test]
    fn nonzero_start_position_behaves_like_zero() {
        let mut a = belt(&[0.0, 1.0], &[0.0, 0.0]);
        let mut b = Spatial::new();
        b.init_profile(0, &[0.0, 1.0], &[0.0, 0.0]);
        // Same run, but x starts at 5 instead of 0.
        b.eval(0, 0.0, 0.0, 0.0, 5.0, true, MODE_CONTINUOUS);
        b.store(0, 0.0, 0.0, 0.0, 5.0, true);
        for k in 1..=150 {
            let t = k as f64 * 0.01;
            let (_, ra) = a.eval(0, t, t, 0.0, t, true, MODE_CONTINUOUS);
            a.store(0, t, t, 0.0, t, true);
            let (_, rb) = b.eval(0, t, t, 0.0, 5.0 + t, true, MODE_CONTINUOUS);
            b.store(0, t, t, 0.0, 5.0 + t, true);
            assert!((ra - rb).abs() < 1e-12, "t={t}: {ra} vs {rb}");
        }
    }

    #[test]
    fn a_step_longer_than_the_domain_reads_the_boundary_condition() {
        // x advances 2.5 domain lengths in one step: the material at the output edge
        // entered after the last accepted step, so the only description of it is the
        // line from the profile's front (0, 0) to the boundary condition (-2.5, 42).
        let mut s = belt(&[0.0, 1.0], &[0.0, 0.0]);
        let (_, o1) = s.eval(0, 0.5, 42.0, 0.0, 2.5, true, MODE_CONTINUOUS);
        assert!((o1 - 42.0 * 1.5 / 2.5).abs() < 1e-12, "out1={o1}");
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
    fn reversal_transports_the_material_back_out() {
        let mut s = belt(&[0.0, 1.0], &[0.0, 0.0]);
        // Fill half the domain with 1.0 from the left, then reverse.
        for k in 1..=50 {
            let t = k as f64 * 0.01;
            s.eval(0, t, 1.0, 0.0, t, true, MODE_CONTINUOUS);
            s.store(0, t, 1.0, 0.0, t, true);
        }
        let mut seen = 0.0f64;
        for k in 1..=40 {
            let t = 0.5 + k as f64 * 0.01;
            let x = 0.5 - k as f64 * 0.01;
            let (o0, _) = s.eval(0, t, 1.0, 0.0, x, false, MODE_CONTINUOUS);
            s.store(0, t, 1.0, 0.0, x, false);
            seen = seen.max(o0);
        }
        // What went in on the left comes back out of the left.
        assert!((seen - 1.0).abs() < 1e-9, "out0 peaked at {seen}");
    }
}
