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

use crate::{Result, MINIMAL_STEP_SIZE};
use crate::Ode;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum FixedKind {
    Euler,
    RungeKutta,
}

/// How far one [`FixedStep::step`] got.
pub enum FixedProgress {
    Reached,
    /// An event was located at this time; the states are the bracket's right end.
    Root(f64),
}

/// C's `RK4_DATA` plus the event bracket the root search needs.
pub struct FixedStep {
    kind: FixedKind,
    n_states: usize,
    /// Stage derivatives, `b.len()` blocks of `n_states`.
    k: Vec<f64>,
    b: &'static [f64],
    c: &'static [f64],
    /// The bracket the bisection narrows, and the crossing values at its ends.
    y_left: Vec<f64>,
    y_right: Vec<f64>,
    zc: Vec<f64>,
    zc_pre: Vec<f64>,
    zc_backup: Vec<f64>,
    event_ids: Vec<usize>,
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
            y_left: vec![0.0; n_states],
            y_right: vec![0.0; n_states],
            zc: vec![0.0; n_zc],
            zc_pre: vec![0.0; n_zc],
            zc_backup: vec![0.0; n_zc],
            event_ids: Vec::new(),
            steps: 0,
        }
    }

    pub fn kind(&self) -> FixedKind {
        self.kind
    }

    pub fn root_index(&self) -> usize {
        self.event_ids.first().copied().unwrap_or(0)
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
    ) -> Result<FixedProgress> {
        let n = self.n_states;
        let h = target - *t;
        let t_left = *t;
        self.y_left.copy_from_slice(&y[..n]);
        // The comparison base for the event search below.
        if !self.zc.is_empty() {
            ode.eval_zc(t_left, &self.y_left, &mut self.zc)?;
        }

        // C computes k[0] from the derivative it already has and evaluates the
        // remaining stages, each off the previous stage's derivative only.
        self.k[..n].copy_from_slice(&yp[..n]);
        let mut stage_y = vec![0.0; n];
        for j in 1..self.b.len() {
            for i in 0..n {
                stage_y[i] = self.y_left[i] + h * self.c[j] * self.k[(j - 1) * n + i];
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
            self.y_right[i] = self.y_left[i] + h * sum;
        }
        self.steps += 1;

        if !self.zc.is_empty() {
            self.zc_pre.copy_from_slice(&self.zc);
            ode.eval_zc(target, &self.y_right, &mut self.zc)?;
            self.event_ids = (0..self.zc.len())
                .filter(|&i| sign(self.zc[i]) != sign(self.zc_pre[i]))
                .collect();
            if !self.event_ids.is_empty() {
                let troot = if no_root_finding() {
                    target
                } else {
                    self.find_root(ode, t_left, target)?
                };
                *t = troot;
                y[..n].copy_from_slice(&self.y_right);
                ode.eval(troot, &self.y_right, yp)?;
                return Ok(FixedProgress::Root(troot));
            }
        }
        *t = target;
        y[..n].copy_from_slice(&self.y_right);
        ode.eval(target, &self.y_right, yp)?;
        Ok(FixedProgress::Reached)
    }

    /// C's `findRoot`/`bisection`: halve the bracket in state space until it is
    /// narrower than `MINIMAL_STEP_SIZE`, keeping the half the crossing flips in.
    /// `y_left`/`y_right` end up as the bracket's ends and the right one is the
    /// reported event state.
    fn find_root(&mut self, ode: &mut dyn Ode, mut a: f64, mut b: f64) -> Result<f64> {
        let n = self.n_states;
        let ttol = MINIMAL_STEP_SIZE + MINIMAL_STEP_SIZE * abs(b - a);
        let mut iters = crate::bisection_iterations(b - a, ttol);
        self.zc_backup.copy_from_slice(&self.zc);
        let mut mid = vec![0.0; n];
        while abs(b - a) > MINIMAL_STEP_SIZE && iters > 0 {
            iters -= 1;
            let c = 0.5 * (a + b);
            for i in 0..n {
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
                self.zc_pre.copy_from_slice(&self.zc);
                self.zc.copy_from_slice(&self.zc_backup);
            }
        }
        Ok(b)
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
        omclog::warning(
            omclog::STDOUT,
            false,
            &alloc::format!(
                "Integration method '{method}' is deprecated and will be removed in a future \
                 version of OpenModelica."
            ),
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
