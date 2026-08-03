//! Locating the events an accepted gbode step stepped over, a port of C's
//! `gbode_events.c`. The interval's own interpolant is bisected, so no extra
//! integration is needed — this is why gbode sets `solverRootFinding` and the
//! driver leaves root finding to it.

use super::{Gbode, Ode, MINIMAL_STEP_SIZE};
use crate::driver::Result;
use crate::gbode::math::{abs, ceil, ln};

impl Gbode {
    fn zc_at(&mut self, ode: &mut Ode, t: f64) -> Result<()> {
        let n = self.n_states;
        let mut y = vec![0.0; n];
        self.interpolate_step(t, &mut y);
        ode.eval_zc(t, &y, &mut self.zc)?;
        self.y1.copy_from_slice(&y);
        Ok(())
    }

    /// C's `checkForStateEvent`: which crossings changed sign against `zc_pre`.
    fn changed_crossings(&self) -> Vec<usize> {
        (0..self.zc.len())
            .filter(|&i| sign(self.zc[i]) != sign(self.zc_pre[i]))
            .collect()
    }

    /// C's `checkZeroCrossings`: does one of the crossings we are hunting flip
    /// between `zc_pre` and `zc`? (i.e. is the root in the left half?)
    fn crossing_in_left(&self) -> bool {
        self.event_ids.iter().any(|&i| {
            (self.zc[i] == -1.0 && self.zc_pre[i] == 1.0)
                || (self.zc[i] == 1.0 && self.zc_pre[i] == -1.0)
        })
    }

    /// C's `bisection_gb` + `findRoot_gb`: narrow `[a, b]` down to the first event
    /// in the interval and return its time (C returns the right end of the final
    /// bracket, so the event is not missed).
    fn find_root(&mut self, ode: &mut Ode, mut a: f64, mut b: f64) -> Result<f64> {
        let ttol = MINIMAL_STEP_SIZE + MINIMAL_STEP_SIZE * abs(b - a);
        let mut n = 1 + ceil(ln(abs(b - a) / ttol) / ln(2.0)) as i64;
        self.zc_backup.copy_from_slice(&self.zc);
        while abs(b - a) > MINIMAL_STEP_SIZE && n > 0 {
            n -= 1;
            let c = 0.5 * (a + b);
            self.zc_at(ode, c)?;
            if self.crossing_in_left() {
                b = c;
                self.zc_backup.copy_from_slice(&self.zc);
            } else {
                a = c;
                self.zc_pre.copy_from_slice(&self.zc);
                self.zc.copy_from_slice(&self.zc_backup);
            }
        }
        Ok(b)
    }

    /// C's `checkForEvents`: evaluate the crossings at the right end of the
    /// accepted step and, if any flipped, bisect for the first one. Leaves
    /// `zc_pre` holding the values it was called with.
    pub(super) fn check_for_events(&mut self, ode: &mut Ode) -> Result<Option<f64>> {
        if self.zc.is_empty() {
            return Ok(None);
        }
        // C snapshots the left-hand values as the comparison base.
        self.zc_pre.copy_from_slice(&self.zc);
        let saved_pre = self.zc_pre.clone();
        let (t_right, y_right) = (self.time_right, self.y_right.clone());
        ode.eval_zc(t_right, &y_right, &mut self.zc)?;
        self.event_ids = self.changed_crossings();
        let found = !self.event_ids.is_empty();
        let event_time = if found {
            if no_root_finding() {
                Some(self.time_right)
            } else {
                let (l, r) = (self.time_left, self.time_right);
                Some(self.find_root(ode, l, r)?)
            }
        } else {
            None
        };
        // C restores the crossing values it started from, so the caller's next
        // comparison is against the same base.
        self.zc.copy_from_slice(&saved_pre);
        self.zc_pre.copy_from_slice(&saved_pre);
        Ok(event_time)
    }

    /// Latch the crossing values at `(t, y)` as the base later steps compare
    /// against, C's `saveZeroCrossings`.
    pub(super) fn latch_crossings_at(&mut self, ode: &mut Ode, t: f64, y: &[f64]) -> Result<()> {
        if self.zc.is_empty() {
            return Ok(());
        }
        self.zc_pre.copy_from_slice(&self.zc);
        ode.eval_zc(t, y, &mut self.zc)?;
        Ok(())
    }
}

/// C's `sign` for the zero-crossing comparison.
fn sign(v: f64) -> i32 {
    if v > 0.0 {
        1
    } else if v < 0.0 {
        -1
    } else {
        0
    }
}

/// C's `-noRootFinding`: take the right end of the step as the event time.
fn no_root_finding() -> bool {
    crate::simflags::with_flags(|f| f.no_root_finding)
}

use alloc::vec;
use alloc::vec::Vec;
