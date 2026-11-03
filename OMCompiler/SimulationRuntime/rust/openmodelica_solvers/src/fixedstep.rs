//! The fixed-step solver C keeps in `solver_main.c`: `euler` (explicit Euler). One
//! step spans a whole output interval, and the events the step passed over are
//! located afterwards by bisecting the step in state space — C's
//! `checkEvents`/`findRoot` (`events.c`), which is what `solverRootFinding = 0`
//! means.

use alloc::vec;
use alloc::vec::Vec;

use crate::Ode;
use crate::Result;
use crate::events::{Bracket, StepEnd};

/// The step's result plus the event bracket the root search needs.
pub struct FixedStep {
    n_states: usize,
    /// The step's result, before the bracket takes it.
    y_new: Vec<f64>,
    br: Bracket,
    pub steps: u64,
}

impl FixedStep {
    pub fn new(n_states: usize, n_zc: usize) -> Self {
        FixedStep {
            n_states,
            y_new: vec![0.0; n_states],
            br: Bracket::new(n_states, n_zc),
            steps: 0,
        }
    }

    pub fn root_index(&self) -> usize {
        self.br.root_index()
    }

    /// C's `time_left`/`states_left` for the root just located.
    pub fn event_left(&self) -> (f64, &[f64]) {
        self.br.left_end()
    }

    /// One step from `t` to `target`. `yp` is the derivative at `(t, y)`, which the
    /// caller already has (C reads it out of the previous step's `localData[1]`);
    /// on return it holds the derivative at the point reported.
    pub fn step(
        &mut self,
        ode: &mut dyn Ode,
        t: &mut f64,
        y: &mut [f64],
        yp: &mut [f64],
        target: f64,
    ) -> Result<StepEnd> {
        let n = self.n_states;
        let h = target - *t;
        let t_left = *t;
        self.br.open(ode, t_left, &y[..n])?;

        for i in 0..n {
            self.y_new[i] = self.br.left()[i] + h * yp[i];
        }
        self.steps += 1;

        let (end, accepted) = self.br.close(ode, t_left, target, &self.y_new, yp)?;
        let reached = end.unwrap_or(target);
        *t = reached;
        y[..n].copy_from_slice(self.br.right());
        if !accepted {
            ode.eval(reached, &y[..n], yp)?;
        }
        Ok(match end {
            Some(troot) => StepEnd::Root(troot),
            None => StepEnd::Reached,
        })
    }
}
