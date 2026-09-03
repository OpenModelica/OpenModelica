//! The fixed-step solvers C keeps in `solver_main.c`: `euler` (explicit Euler) and
//! `rungekutta` (classical RK4). One step spans a whole output interval, and the
//! events the step passed over are located afterwards by bisecting the step in
//! state space — C's `checkEvents`/`findRoot` (`events.c`), which is what
//! `solverRootFinding = 0` means.
//!
//! `rungekutta` is deprecated in C in favour of `gbode -gbm=rungekutta
//! -gbctrl=const`; it is here because a model can still be compiled with it.

use alloc::vec;
use alloc::vec::Vec;

use crate::Ode;
use crate::Result;
use crate::events::{Bracket, StepEnd};

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum FixedKind {
    Euler,
    RungeKutta,
}

/// C's `RK4_DATA` plus the event bracket the root search needs.
pub struct FixedStep {
    kind: FixedKind,
    n_states: usize,
    /// Stage derivatives, `b.len()` blocks of `n_states`.
    k: Vec<f64>,
    b: &'static [f64],
    c: &'static [f64],
    /// The step's result, before the bracket takes it.
    y_new: Vec<f64>,
    br: Bracket,
    pub steps: u64,
}

/// C's `rungekutta_b`/`rungekutta_c` (`solver_main.c`): classical RK4, whose only
/// nonzero sub-diagonal entries are `a[j][j-1] == c[j]`, which is why one stage
/// only ever needs the previous stage's derivative.
const RK4_B: &[f64] = &[1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 6.0];
const RK4_C: &[f64] = &[0.0, 0.5, 0.5, 1.0];

const EULER_B: &[f64] = &[1.0];
const EULER_C: &[f64] = &[0.0];

impl FixedStep {
    pub fn new(kind: FixedKind, n_states: usize, n_zc: usize) -> Self {
        let (b, c) = match kind {
            FixedKind::Euler => (EULER_B, EULER_C),
            FixedKind::RungeKutta => (RK4_B, RK4_C),
        };
        FixedStep {
            kind,
            n_states,
            k: vec![0.0; b.len() * n_states],
            b,
            c,
            y_new: vec![0.0; n_states],
            br: Bracket::new(n_states, n_zc),
            steps: 0,
        }
    }

    pub fn kind(&self) -> FixedKind {
        self.kind
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

        // C computes k[0] from the derivative it already has and evaluates the
        // remaining stages, each off the previous stage's derivative only.
        self.k[..n].copy_from_slice(&yp[..n]);
        let mut stage_y = vec![0.0; n];
        for j in 1..self.b.len() {
            for i in 0..n {
                stage_y[i] = self.br.left()[i] + h * self.c[j] * self.k[(j - 1) * n + i];
            }
            let mut f = vec![0.0; n];
            ode.eval(t_left + self.c[j] * h, &stage_y, &mut f)?;
            self.k[j * n..(j + 1) * n].copy_from_slice(&f);
        }
        for i in 0..n {
            let mut sum = 0.0;
            for j in 0..self.b.len() {
                sum += self.b[j] * self.k[j * n + i];
            }
            self.y_new[i] = self.br.left()[i] + h * sum;
        }
        self.steps += 1;

        let end = self.br.close(ode, t_left, target, &self.y_new)?;
        let reached = end.unwrap_or(target);
        *t = reached;
        y[..n].copy_from_slice(self.br.right());
        ode.eval(reached, &y[..n], yp)?;
        Ok(match end {
            Some(troot) => StepEnd::Root(troot),
            None => StepEnd::Reached,
        })
    }
}

/// C's `deprecationWarningGBODE` + `replacementString`, which
/// `simulation_runtime.cpp` runs while it resolves `-s=` — before the solver is
/// allocated and before the model is initialized.
pub fn deprecation_warning(method: &str) {
    use crate::omclog;
    // C also warns (one line, no replacement text) for `symSolver`, `symSolverSsc`
    // and `qss`.
    if matches!(method, "symSolver" | "symSolverSsc" | "qss") {
        omclog::warning!(
            omclog::STDOUT,
            false,
            "Integration method '{method}' is deprecated and will be removed in a future \
             version of OpenModelica.",
        );
        return;
    }
    if method != "rungekutta" {
        return;
    }
    omclog::warning(
        omclog::STDOUT,
        true,
        "Integration method 'rungekutta' is deprecated and will be removed in a future version \
         of OpenModelica.",
    );
    omclog::info(
        omclog::STDOUT,
        true,
        "Use integration method GBODE with method 'rungekutta' and constant step size instead:",
    );
    omclog::info(
        omclog::STDOUT,
        false,
        "Choose integration method 'gbode' in Simulation Setup->General and additional \
         simulation flags '-gbm=rungekutta -gbctrl=const' in Simulation Setup->Simulation Flags.",
    );
    omclog::info(omclog::STDOUT, false, "or");
    omclog::info(
        omclog::STDOUT,
        false,
        "Simulation flags '-s=gbode -gbm=rungekutta -gbctrl=const'.",
    );
    omclog::close(omclog::STDOUT);
    omclog::info(
        omclog::STDOUT,
        false,
        "See OpenModelica User's Guide section on GBODE for more details: \
         https://www.openmodelica.org/doc/OpenModelicaUsersGuide/latest/solving.html#gbode",
    );
    omclog::close(omclog::STDOUT);
}

