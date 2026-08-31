//! C's `checkEvents`/`findRoot` (`events.c`) for a solver that does not locate its
//! own roots (`solverRootFinding = 0`): compare the crossing functions at the two
//! ends of a step and, when one flipped, bisect the step *in state space* — the
//! bracket's midpoint is the average of the two state vectors, not a re-integrated
//! point.

use alloc::vec;
use alloc::vec::Vec;

use crate::{MINIMAL_STEP_SIZE, Ode, Result};

/// How far one step of a solver that brackets its own events got.
pub enum StepEnd {
    Reached,
    /// An event was located at this time; the states are the bracket's right end.
    Root(f64),
}

/// One step's event bracket: the states at both ends and the crossing values there.
pub struct Bracket {
    t_left: f64,
    y_left: Vec<f64>,
    y_right: Vec<f64>,
    zc: Vec<f64>,
    zc_pre: Vec<f64>,
    zc_backup: Vec<f64>,
    event_ids: Vec<usize>,
}

impl Bracket {
    pub fn new(n_states: usize, n_zc: usize) -> Self {
        Bracket {
            t_left: 0.0,
            y_left: vec![0.0; n_states],
            y_right: vec![0.0; n_states],
            zc: vec![0.0; n_zc],
            zc_pre: vec![0.0; n_zc],
            zc_backup: vec![0.0; n_zc],
            event_ids: Vec::new(),
        }
    }

    /// The step's left end: the states it starts from and the crossing values
    /// there, which are the comparison base for [`Bracket::close`].
    pub fn open(&mut self, ode: &mut dyn Ode, t: f64, y: &[f64]) -> Result<()> {
        self.t_left = t;
        self.y_left.copy_from_slice(y);
        if !self.zc.is_empty() {
            ode.eval_zc(t, &self.y_left, &mut self.zc)?;
        }
        Ok(())
    }

    /// The states [`Bracket::open`] took, which a stage evaluation works off.
    pub fn left(&self) -> &[f64] {
        &self.y_left
    }

    /// The step's right end, `y` being the states it reached. `Some(t)` = an
    /// indicator flipped and this is where; [`Bracket::right`] then holds the
    /// states at the located point.
    pub fn close(
        &mut self,
        ode: &mut dyn Ode,
        t_left: f64,
        t_right: f64,
        y: &[f64],
    ) -> Result<Option<f64>> {
        self.y_right.copy_from_slice(y);
        if self.zc.is_empty() {
            return Ok(None);
        }
        self.zc_pre.copy_from_slice(&self.zc);
        ode.eval_zc(t_right, &self.y_right, &mut self.zc)?;
        self.event_ids =
            (0..self.zc.len()).filter(|&i| sign(self.zc[i]) != sign(self.zc_pre[i])).collect();
        if self.event_ids.is_empty() {
            return Ok(None);
        }
        if no_root_finding() {
            // No bracket: the pre-event history belongs at the root itself.
            self.t_left = t_right;
            self.y_left.copy_from_slice(&self.y_right);
            return Ok(Some(t_right));
        }
        Ok(Some(self.find_root(ode, t_left, t_right)?))
    }

    pub fn right(&self) -> &[f64] {
        &self.y_right
    }

    /// The final bracket's left end, C's `time_left`/`states_left`.
    pub fn left_end(&self) -> (f64, &[f64]) {
        (self.t_left, &self.y_left)
    }

    pub fn root_index(&self) -> usize {
        self.event_ids.first().copied().unwrap_or(0)
    }

    /// C's `findRoot`/`bisection`: halve the bracket in state space until it is
    /// narrower than `MINIMAL_STEP_SIZE`, keeping the half the crossing flips in.
    fn find_root(&mut self, ode: &mut dyn Ode, mut a: f64, mut b: f64) -> Result<f64> {
        let ttol = MINIMAL_STEP_SIZE + MINIMAL_STEP_SIZE * abs(b - a);
        let mut iters = crate::bisection_iterations(b - a, ttol);
        self.zc_backup.copy_from_slice(&self.zc);
        let mut mid = vec![0.0; self.y_left.len()];
        while abs(b - a) > MINIMAL_STEP_SIZE && iters > 0 {
            iters -= 1;
            let c = 0.5 * (a + b);
            for i in 0..mid.len() {
                mid[i] = 0.5 * (self.y_left[i] + self.y_right[i]);
            }
            ode.eval_zc(c, &mid, &mut self.zc)?;
            let in_left = self.event_ids.iter().any(|&i| {
                let (a, b) = (sign(self.zc[i]), sign(self.zc_pre[i]));
                (a == -1 && b == 1) || (a == 1 && b == -1)
            });
            if in_left {
                self.y_right.copy_from_slice(&mid);
                b = c;
                self.zc_backup.copy_from_slice(&self.zc);
            } else {
                self.y_left.copy_from_slice(&mid);
                a = c;
                self.t_left = c;
                self.zc_pre.copy_from_slice(&self.zc);
                self.zc.copy_from_slice(&self.zc_backup);
            }
        }
        Ok(b)
    }
}

fn sign(v: f64) -> i32 {
    if v > 0.0 {
        1
    } else if v < 0.0 {
        -1
    } else {
        0
    }
}

fn no_root_finding() -> bool {
    crate::simflags::with_flags(|f| f.no_root_finding)
}

use libm::fabs as abs;
