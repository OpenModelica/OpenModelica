//! C's `symSolver` and `symSolverSsc` (`sym_solver_step` in `solver_main.c`,
//! `sym_solver_ssc.c`).
//!
//! A model translated with `--symSolver=impEuler|expEuler` carries its ODE a
//! second time, as explicit update equations `y = g(y$Old, time, __OMC_DT)` that
//! the backend derived symbolically (`symbolicInlineSystem`). A step is not an
//! integration of `der(y)` but one run of that system with `__OMC_DT` and `y$Old`
//! set. `symSolverSsc` adds step-size control by taking every step twice at half
//! the size and comparing the two orders.

use alloc::vec;
use alloc::vec::Vec;

use libm::{fabs, fmax, fmin, sqrt};

use crate::events::{Bracket, StepEnd};
use crate::{Ode, Result, format_e, omclog};

/// One `LOG_SOLVER` line, built only when the stream is on.
fn log(msg: impl FnOnce() -> alloc::string::String) {
    if omclog::active(omclog::SOLVER) {
        omclog::info(omclog::SOLVER, false, &msg());
    }
}

/// C's `compiledWithSymSolver`.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum SymKind {
    ImpEuler,
    ExpEuler,
}

impl SymKind {
    /// The `--symSolver` enum the model was translated with; `None` ⇒ no inline
    /// system was generated.
    pub fn from_code(c: u8) -> Option<SymKind> {
        match c {
            1 => Some(SymKind::ImpEuler),
            2 => Some(SymKind::ExpEuler),
            _ => None,
        }
    }
}

/// The inline system on top of what every solver needs. Fine-grained because
/// `sym_solver_ssc.c` sets these in combinations that deliberately reuse what the
/// previous evaluation left behind.
pub trait InlineOde: Ode {
    /// `inlineData->algOldVars`, the `y$Old` the inline equations step from.
    fn set_alg_old(&mut self, y: &[f64]) -> Result<()>;
    /// `localData[0]->realVars`: an implicit inline system's starting guess going
    /// in, its solution coming out.
    fn get_states(&mut self, y: &mut [f64]) -> Result<()>;
    fn set_states(&mut self, y: &[f64]) -> Result<()>;
    /// `externalInputUpdate` + `input_function` + `symbolicInlineSystems` at
    /// `time = t` with `inlineData->dt = dt`.
    fn inline_eval(&mut self, t: f64, dt: f64) -> Result<()>;
}

/// C's `DASSL_STEP_EPS` (`epsilon.h`), below which `sym_solver_step` interpolates
/// rather than stepping.
const DASSL_STEP_EPS: f64 = 1e-13;

/// The controller constants of `sym_solver_ssc_step`.
const FAC: f64 = 0.9;
const FACMAX: f64 = 3.5;
const FACMIN: f64 = 0.3;
/// The step size at which the controller gives up and interpolates linearly.
const MIN_STEP: f64 = 1e-13;

pub struct SymSolver {
    kind: SymKind,
    /// `-s=symSolverSsc`: the step-size-controlled variant.
    ssc: bool,
    n: usize,
    tol: f64,
    br: Bracket,
    /// The states one step produced, before the bracket takes them.
    y_new: Vec<f64>,
    /// `sym_solver_ssc.c`'s workspace: the half-step point, the two approximations
    /// of different order, and the inner integrator's own state.
    y05: Vec<f64>,
    y1: Vec<f64>,
    y2: Vec<f64>,
    radau_vars: Vec<f64>,
    radau_vars_old: Vec<f64>,
    der_x0: Vec<f64>,
    radau_time: f64,
    radau_time_old: f64,
    radau_h: f64,
    radau_h_old: f64,
    /// C's `firstStep`, which `didEventStep` also raises.
    first_step: bool,
    pub steps: u64,
    pub calls_ode: u64,
}

impl SymSolver {
    pub fn new(kind: SymKind, ssc: bool, n_states: usize, n_zc: usize, tol: f64) -> Self {
        SymSolver {
            kind,
            ssc,
            n: n_states,
            tol,
            br: Bracket::new(n_states, n_zc),
            y_new: vec![0.0; n_states],
            y05: vec![0.0; n_states],
            y1: vec![0.0; n_states],
            y2: vec![0.0; n_states],
            radau_vars: vec![0.0; n_states],
            radau_vars_old: vec![0.0; n_states],
            der_x0: vec![0.0; n_states],
            radau_time: 0.0,
            radau_time_old: 0.0,
            radau_h: 0.0,
            radau_h_old: 0.0,
            first_step: true,
            steps: 0,
            calls_ode: 0,
        }
    }

    /// C's `didEventStep`: the inner integrator restarts from the post-event state.
    pub fn restart(&mut self) {
        self.first_step = true;
    }

    pub fn root_index(&self) -> usize {
        self.br.root_index()
    }

    /// C's `time_left`/`states_left` for the root just located.
    pub fn event_left(&self) -> (f64, &[f64]) {
        self.br.left_end()
    }

    /// One output step from `t` to `target`. `yp` holds the derivative at `(t, y)`
    /// going in (C's `localData[1]` derivative slots) and at the reported point
    /// coming out.
    pub fn step(
        &mut self,
        ode: &mut dyn InlineOde,
        t: &mut f64,
        y: &mut [f64],
        yp: &mut [f64],
        target: f64,
    ) -> Result<StepEnd> {
        let t_left = *t;
        self.br.open(ode, t_left, &y[..self.n])?;
        if self.ssc {
            self.ssc_step(ode, t_left, y, yp, target)?;
        } else {
            self.plain_step(ode, t_left, y, yp, target)?;
        }
        let end = self.br.close(ode, t_left, target, &self.y_new)?;
        let reached = end.unwrap_or(target);
        *t = reached;
        y[..self.n].copy_from_slice(self.br.right());
        // C's `updateContinuousSystem` right after the step. Both solvers also
        // difference a derivative into `localData[1]`, but the ring buffer rotates
        // this one over that before anything reads it.
        ode.eval(reached, &y[..self.n], yp)?;
        Ok(match end {
            Some(troot) => StepEnd::Root(troot),
            None => StepEnd::Reached,
        })
    }

    /// `sym_solver_step`: one inline evaluation over the whole output interval.
    fn plain_step(
        &mut self,
        ode: &mut dyn InlineOde,
        t: f64,
        y: &[f64],
        yp: &[f64],
        target: f64,
    ) -> Result<()> {
        let h = target - t;
        if h < DASSL_STEP_EPS {
            log(|| "Desired step to small try next one".into());
            log(|| "Interpolate linear".into());
            for i in 0..self.n {
                self.y_new[i] = y[i] + yp[i] * h;
            }
            return Ok(());
        }
        ode.set_alg_old(&y[..self.n])?;
        ode.set_states(&y[..self.n])?;
        ode.inline_eval(target, h)?;
        ode.get_states(&mut self.y_new)?;
        self.steps += 1;
        self.calls_ode += 1;
        Ok(())
    }

    /// `sym_solver_ssc_step`: inner steps of a controlled size up to and past the
    /// output point, then linear interpolation back onto it.
    fn ssc_step(
        &mut self,
        ode: &mut dyn InlineOde,
        t: f64,
        y: &[f64],
        yp: &[f64],
        target: f64,
    ) -> Result<()> {
        let h = target - t;
        if self.first_step {
            self.begin(ode, t, y, h)?;
            self.radau_h_old = 0.0;
        }
        let atol = self.tol;
        let rtol = self.tol;
        log(|| alloc::format!("new step: time={}", format_e(self.radau_time)));
        while self.radau_time < target {
            loop {
                self.two_orders(ode)?;
                let mut err = 0.0;
                for i in 0..self.n {
                    let sc = atol + fmax(fabs(self.y2[i]), fabs(self.y1[i])) * rtol;
                    let diff = self.y2[i] - self.y1[i];
                    err += (diff * diff) / (sc * sc);
                }
                err /= self.n as f64;
                if omclog::active(omclog::SOLVER) {
                    for i in 0..self.n {
                        log(|| alloc::format!("y1[{i}]={}", format_e(self.y1[i])));
                        log(|| alloc::format!("y2[{i}]={}", format_e(self.y2[i])));
                    }
                    log(|| alloc::format!("err = {}", format_e(err)));
                    // C's own label says `sqrt`, its expression is the 4th power.
                    log(|| {
                        alloc::format!(
                            "min(facmax, max(facmin, fac*sqrt(1/err))) = {}",
                            format_e(fmin(FACMAX, fmax(FACMIN, FAC * libm::pow(1.0 / err, 4.0))))
                        )
                    });
                }
                self.steps += 1;
                self.radau_h_old = self.radau_h;
                self.radau_h *= fmin(FACMAX, fmax(FACMIN, FAC * sqrt(1.0 / err)));
                if self.radau_h.is_nan() || self.radau_h < MIN_STEP {
                    self.radau_h = MIN_STEP;
                    log(|| "Desired step to small try next one".into());
                    log(|| "Interpolate linear".into());
                    for i in 0..self.n {
                        self.y_new[i] = y[i] + yp[i] * h;
                    }
                    // As in C, the accepted point below is banked here too, so the
                    // inner clock advances one step further than the states do.
                    self.accept();
                    break;
                }
                // C's `while (err > 1.0)`, whose NaN leaves the loop rather than
                // repeating forever on it.
                if err.is_nan() || err <= 1.0 {
                    break;
                }
            }
            self.accept();
        }
        if self.radau_time - self.radau_time_old > MIN_STEP && self.radau_h_old > MIN_STEP {
            let span = self.radau_time - self.radau_time_old;
            log(|| alloc::format!("Time  {}", format_e(target)));
            for i in 0..self.n {
                self.y_new[i] = (self.radau_vars[i] * (target - self.radau_time_old)
                    + self.radau_vars_old[i] * (self.radau_time - target))
                    / span;
            }
        } else {
            log(|| "Desired step to small try next one".into());
            log(|| "Interpolate linear".into());
            // C also advances the *output* time by another step size here, which
            // would take the driver off its grid; the states are its Euler step.
            for i in 0..self.n {
                self.y_new[i] = y[i] + yp[i] * h;
            }
            self.accept();
        }
        log(|| {
            alloc::format!(
                "Step done to {} with step size = {}",
                crate::format_g(target, 6),
                format_e(self.radau_h_old)
            )
        });
        Ok(())
    }

    /// The inner integrator's accepted point: the clock moves by the step just
    /// taken and `y2` becomes the current state.
    fn accept(&mut self) {
        self.radau_time_old = self.radau_time;
        self.radau_time += self.radau_h_old;
        self.radau_vars_old.copy_from_slice(&self.radau_vars);
        self.radau_vars.copy_from_slice(&self.y2);
    }

    /// C's `first_step`: seed the inner integrator at the accepted point and pick
    /// its starting step size.
    fn begin(&mut self, ode: &mut dyn InlineOde, t: f64, y: &[f64], h: f64) -> Result<()> {
        // C reads `radauVars` out of `localData[0]` and `radauVarsOld` out of
        // `localData[1]`; the driver has just stored one over the other.
        self.radau_vars.copy_from_slice(&y[..self.n]);
        self.radau_vars_old.copy_from_slice(&y[..self.n]);
        self.radau_time = t;
        self.radau_time_old = t;
        self.first_step = false;
        if self.kind == SymKind::ImpEuler {
            self.radau_h = 0.5 * h;
            return Ok(());
        }
        // The explicit variant estimates the initial step from two probing
        // evaluations. Neither sets `algOldVars`, so the first of them steps from
        // whatever the last inner step left there (zeros before any).
        let (atol, rtol) = (self.tol, self.tol);
        let mut der = vec![0.0; self.n];
        ode.inline_eval(t, 1e-8)?;
        ode.get_states(&mut self.y_new)?;
        for i in 0..self.n {
            der[i] = (self.y_new[i] - y[i]) / 1e-8;
        }
        let (mut d0, mut d1) = (0.0, 0.0);
        for i in 0..self.n {
            let sc = atol + fabs(y[i]) * rtol;
            d0 += (y[i] * y[i]) / (sc * sc);
            d1 += (der[i] * der[i]) / (sc * sc);
        }
        d0 = sqrt(d0 / self.n as f64);
        d1 = sqrt(d1 / self.n as f64);
        self.der_x0.copy_from_slice(&der);
        let h0 = if d0 < 1e-5 || d1 < 1e-5 { 1e-6 } else { 0.01 * d0 / d1 };
        for i in 0..self.n {
            self.y_new[i] = self.radau_vars[i] + der[i] * h0;
        }
        ode.set_states(&self.y_new)?;
        ode.inline_eval(t + h0, h0)?;
        ode.get_states(&mut self.y_new)?;
        for i in 0..self.n {
            der[i] = (self.y_new[i] - y[i]) / h0;
        }
        let mut d2 = 0.0;
        for i in 0..self.n {
            let sc = atol + fabs(self.radau_vars[i]) * rtol;
            let dd = der[i] - self.der_x0[i];
            d2 += dd * dd / (sc * sc);
        }
        d2 = sqrt(d2) / h0;
        let d = fmax(d1, d2);
        let h1 = if d > 1e-15 { sqrt(0.01 / d) } else { fmax(1e-6, h0 * 1e-3) };
        self.radau_h = 0.5 * fmin(100.0 * h0, h1);
        Ok(())
    }

    /// `generateTwoApproximationsOfDifferentOrder`: two half steps give `y2`, and
    /// the first of them extrapolated gives the lower-order `y1`.
    fn two_orders(&mut self, ode: &mut dyn InlineOde) -> Result<()> {
        log(|| alloc::format!("radauStepSize = {}", format_e(self.radau_h)));
        self.radau_h /= 2.0;
        let half = self.radau_h;
        let t0 = self.radau_time;

        log(|| alloc::format!("first system time = {}", format_e(t0 + half)));
        ode.set_alg_old(&self.radau_vars)?;
        ode.inline_eval(t0 + half, half)?;
        ode.get_states(&mut self.y05)?;
        for i in 0..self.n {
            self.y1[i] = 2.0 * self.y05[i] - self.radau_vars[i];
        }

        log(|| alloc::format!("second system time = {}", format_e(t0 + 2.0 * half)));
        ode.set_alg_old(&self.y05)?;
        ode.inline_eval(t0 + 2.0 * half, half)?;
        ode.get_states(&mut self.y2)?;
        self.calls_ode += 2;

        if self.kind == SymKind::ExpEuler {
            // Richardson extrapolation onto the higher order.
            for i in 0..self.n {
                self.y1[i] = 2.0 * self.y2[i] - self.y1[i];
            }
        }
        self.radau_h *= 2.0;
        Ok(())
    }
}
