//! gbode's own nonlinear solver (`-gbnls=internal`), a port of the single-rate
//! part of C's `gbode_internal_nls.c`.
//!
//! Two systems appear, both solved by a simplified Newton iteration over one
//! factorization of a matrix built from the ODE Jacobian `J = df/dy`:
//!
//! * DIRK, one stage at a time, `0 = res_const - x + h*a_ii*f(t_i, x)`, whose
//!   simplified Jacobian is `h*a_ii*J - I` (C's `jacobian_DIRK_assemble`).
//! * FIRK, all stages coupled, `0 = yOld - Z_i + h*sum_j a_ij*f(t_j, Z_j)`, whose
//!   simplified Jacobian is `h*(A kron J) - I`.
//!
//! C decouples the FIRK system with the tableau's T-transformation, turning one
//! `(s*N)^3` factorization into a few `N^3` ones. That is a performance
//! optimization on top of the same iteration: this port does the coupled solve, so
//! the converged stage values (and everything derived from them) agree, but a
//! many-stage FIRK method costs more per step here than in C.
//!
//! The convergence test, the `eta`/`theta` bookkeeping that decides when to reuse
//! the factorization, and the scaled norms are C's, so a step converges after the
//! same number of iterations.

use alloc::vec;
use alloc::vec::Vec;

use super::tableau::{GmType, Tableau};
use crate::gbode::math::{abs, pow, sqrt};
use crate::JacAInfo;
use crate::driver::{Result, SimEngine};

/// C's `DBL_ABSORPTION`.
const DBL_ABSORPTION: f64 = 10.0 * f64::EPSILON;

#[derive(PartialEq, Eq, Debug)]
pub enum Solved {
    Ok,
    Failed,
}

/// C's `GB_INTERNAL_NLS_DATA`, single-rate.
pub(super) struct GbNls {
    /// `n_states` for DIRK, `n_stages * n_states` for FIRK.
    pub size: usize,
    n_states: usize,
    n_stages: usize,
    integrator_tol: f64,
    fnewt: f64,
    eta_initial_damping: f64,
    theta_keep: f64,
    theta_divergence: f64,
    max_newton_it: u32,
    /// Per-stage convergence-rate estimate carried between steps.
    etas: Vec<f64>,
    /// The factorization is stale and `J` must be recomputed.
    call_jac: bool,
    scal: Vec<f64>,
    /// The ODE Jacobian, column-major `n_states * n_states`.
    j: Vec<f64>,
    /// LU of the simplified NLS matrix (column-major `size * size`) + its pivots.
    lu: Vec<f64>,
    ipvt: Vec<i32>,
    /// The step size the current factorization was built for.
    lu_step_size: f64,
    /// LU of `gamma/h*I - J` for the contractive-defect estimator, and the `h`
    /// it was built for.
    defect_lu: Vec<f64>,
    defect_ipvt: Vec<i32>,
    defect_step_size: f64,
    /// The current step's base time, for the explicit stages `reconstruct_k`
    /// evaluates outside the Newton loop.
    stage_time_0: f64,
    /// Scratch: residual, saved states, base derivative.
    res: Vec<f64>,
    ysave: Vec<f64>,
    fbase: Vec<f64>,
    /// Newton iterations and Jacobian evaluations, for the solver statistics.
    pub n_iters: u64,
    pub n_jac_evals: u64,
}

/// What the residual needs from the integrator to evaluate one candidate.
pub struct Ode<'a> {
    pub e: &'a mut (dyn SimEngine + 'static),
    pub sim_data: u32,
    pub states_base: u32,
    pub ders_base: u32,
    pub nls_fail_off: u32,
    pub ctx_addr: u32,
    /// Sparsity + coloring for the finite-difference Jacobian; `None` ⇒ dense
    /// column-by-column differencing.
    pub jac_a: Option<&'a JacAInfo>,
    pub nominals: &'a [f64],
    pub nominal_factor: f64,
    /// Base of the zero-crossing value region.
    pub zc_off: u32,
    /// `functionODE` calls made through this handle, for the solver statistics.
    pub calls: u64,
}

impl Ode<'_> {
    pub fn eval(&mut self, t: f64, y: &[f64], f: &mut [f64]) -> Result<()> {
        crate::driver::write_time(self.e, self.sim_data, t)?;
        let mut bytes = vec![0u8; y.len() * 8];
        for (i, v) in y.iter().enumerate() {
            bytes[i * 8..i * 8 + 8].copy_from_slice(&v.to_le_bytes());
        }
        self.e.write_bytes(self.states_base, &bytes)?;
        self.e.call1("functionODE", self.sim_data)?;
        self.calls += 1;
        self.e.read_bytes(self.ders_base, &mut bytes)?;
        for (i, v) in f.iter_mut().enumerate() {
            *v = f64::from_le_bytes(bytes[i * 8..i * 8 + 8].try_into().unwrap());
        }
        Ok(())
    }

    /// Evaluate the zero-crossing functions at `(t, y)`. Like the driver's DASKR
    /// root callback: the continuous equations first, so any algebraic a crossing
    /// depends on is current. A nonlinear system that fails at this probe must not
    /// leak into the next checked evaluation, so the flag is cleared around it.
    pub fn eval_zc(&mut self, t: f64, y: &[f64], zc: &mut [f64]) -> Result<()> {
        if zc.is_empty() {
            return Ok(());
        }
        crate::driver::write_i32(self.e, self.sim_data + self.nls_fail_off, 0)?;
        let mut f = vec![0.0; y.len()];
        crate::driver::set_context_events(self.e, self.ctx_addr);
        let run = (|| -> Result<()> {
            self.eval(t, y, &mut f)?;
            self.e.call2(crate::driver::MODEL_FN_ZC, self.sim_data, self.sim_data + self.zc_off)?;
            let mut bytes = vec![0u8; zc.len() * 8];
            self.e.read_bytes(self.sim_data + self.zc_off, &mut bytes)?;
            for (i, v) in zc.iter_mut().enumerate() {
                *v = f64::from_le_bytes(bytes[i * 8..i * 8 + 8].try_into().unwrap());
            }
            Ok(())
        })();
        crate::driver::set_context_algebraic(self.e, self.ctx_addr);
        run
    }
}

impl GbNls {
    /// C's `gbInternalNlsAllocate` for the single-rate case.
    pub(super) fn new(t: &Tableau, n_states: usize, tol: f64, jac_colors: usize) -> Self {
        let size = if t.gm_type == GmType::Implicit { t.n_stages * n_states } else { n_states };
        // C's Newton convergence target `fnewt`.
        let alpha_default: f64 = 3e-2;
        let alpha_maximal: f64 = 5e-2;
        let safety_newt: f64 = 0.1;
        let mut target_alpha = alpha_default;
        if !t.richardson && t.error_order < t.order_b && t.order_b - t.error_order != 1 {
            let order_quot = (t.error_order as f64 + 1.0) / (t.order_b as f64 + 1.0);
            target_alpha = pow(safety_newt, 1.0 / order_quot);
        }
        let fnewt = (DBL_ABSORPTION / tol).max(alpha_maximal.min(target_alpha));
        let eta_initial_damping =
            gb_number("gbnls_internal_damping", 0.8, |v| (0.0..=1.0).contains(&v));
        let theta_keep = gb_number("gbnls_internal_jackeep", -1.0, |v| v > 0.0);
        let theta_keep = if theta_keep > 0.0 {
            theta_keep
        } else if n_states > 8 {
            pow(
                10.0,
                -3.0 + 1.75 * crate::gbode::math::ln(1.0 + jac_colors as f64)
                    / crate::gbode::math::ln(1.0 + n_states as f64),
            )
        } else {
            1e-3
        };
        // C: 5 Newton iterations per (E)SDIRK stage, more for a coupled FIRK system.
        let max_newton_it =
            if t.gm_type == GmType::Implicit { 4 + 2 * t.n_stages as u32 } else { 5 };
        GbNls {
            size,
            n_states,
            n_stages: t.n_stages,
            integrator_tol: tol,
            fnewt,
            eta_initial_damping,
            theta_keep,
            theta_divergence: 0.99,
            max_newton_it,
            etas: vec![f64::MAX; t.n_stages],
            call_jac: true,
            scal: vec![0.0; size],
            j: vec![0.0; n_states * n_states],
            lu: vec![0.0; size * size],
            ipvt: vec![0; size],
            lu_step_size: 0.0,
            defect_lu: vec![0.0; n_states * n_states],
            defect_ipvt: vec![0; n_states],
            defect_step_size: 0.0,
            stage_time_0: 0.0,
            res: vec![0.0; size],
            ysave: vec![0.0; n_states],
            fbase: vec![0.0; n_states],
            n_iters: 0,
            n_jac_evals: 0,
        }
    }

    /// Called after an event or a restart.
    pub(super) fn invalidate(&mut self) {
        self.call_jac = true;
        self.lu_step_size = 0.0;
        self.defect_step_size = 0.0;
        for e in &mut self.etas {
            *e = f64::MAX;
        }
    }

    /// C's `createGbScales`: the reciprocal tolerance weights the Newton norms use.
    fn make_scales(&mut self, nominals: &[f64], y1: &[f64], y2: &[f64]) {
        let tol = self.integrator_tol;
        for i in 0..self.size {
            let nom = nominals[i % self.n_states];
            self.scal[i] = 1.0 / (tol * nom + abs(y1[i]).max(abs(y2[i])) * tol);
        }
    }

    /// C's `gbScalesNorm`.
    fn scaled_norm(&self, v: &[f64]) -> f64 {
        let mut sum = 0.0;
        for i in 0..self.size {
            let t = v[i] * self.scal[i];
            sum += t * t;
        }
        sqrt(sum / self.size as f64)
    }

    /// The ODE Jacobian at `(time, y)` by (colored) finite differences — C's
    /// `gbInternal_evalNumericalJacobian`, which is `-jacobian=coloredNumerical`.
    /// Stored column-major so it can feed `dgefa` directly.
    fn eval_jacobian(&mut self, ode: &mut Ode, time: f64, y: &[f64]) -> Result<()> {
        let n = self.n_states;
        self.n_jac_evals += 1;
        // Anything factorized from the old `J` is now stale, whatever the step size.
        self.lu_step_size = 0.0;
        self.defect_step_size = 0.0;
        crate::driver::set_context_jacobian(ode.e, ode.ctx_addr);
        let run = (|| -> Result<()> {
            ode.eval(time, y, &mut self.fbase)?;
            self.ysave.copy_from_slice(y);
            let mut probe = self.ysave.clone();
            let dense: Vec<Vec<u32>> = (0..n as u32).map(|c| vec![c]).collect();
            let colors: &[Vec<u32>] = match ode.jac_a {
                Some(j) => &j.colors,
                None => &dense,
            };
            for ci in 0..colors.len() {
                let mut inv_del = vec![0.0; n];
                for &col in &colors[ci] {
                    let c = col as usize;
                    // C's `numericalDifferentiationDeltaXsolver` step, floored at the
                    // scaled nominal so a zero state still gets a usable difference.
                    let mag = DELTA_X_SOLVER
                        * abs(y[c]).max(ode.nominal_factor * abs(ode.nominals[c]));
                    let mut del = if mag > 0.0 { mag } else { DELTA_X_SOLVER };
                    del = y[c] + del - y[c];
                    if del == 0.0 {
                        del = DELTA_X_SOLVER;
                    }
                    inv_del[c] = 1.0 / del;
                    probe[c] = y[c] + del;
                }
                let mut fp = vec![0.0; n];
                ode.eval(time, &probe, &mut fp)?;
                for &col in &colors[ci] {
                    let c = col as usize;
                    let rows: Vec<u32> = match ode.jac_a {
                        Some(j) => j.rows_by_col[c].clone(),
                        None => (0..n as u32).collect(),
                    };
                    for r in rows {
                        let r = r as usize;
                        self.j[c * n + r] = (fp[r] - self.fbase[r]) * inv_del[c];
                    }
                    probe[c] = y[c];
                }
            }
            // Leave SimData holding the base point again.
            ode.eval(time, y, &mut self.fbase)?;
            Ok(())
        })();
        crate::driver::set_context_algebraic(ode.e, ode.ctx_addr);
        run
    }

    /// C's `jacobian_DIRK_assemble`: `h*gamma*J - I`, factorized.
    fn factor_dirk(&mut self, step_size: f64, gamma: f64) -> Result<()> {
        let n = self.n_states;
        let hg = step_size * gamma;
        for c in 0..n {
            for r in 0..n {
                self.lu[c * n + r] = hg * self.j[c * n + r];
            }
            self.lu[c * n + c] -= 1.0;
        }
        factor(&mut self.lu, n, &mut self.ipvt)
    }

    /// `h*(A kron J) - I`, factorized: the simplified Jacobian of the coupled FIRK
    /// residual. Block `(i, j)` is `h*a_ij*J`, minus the identity on the diagonal.
    fn factor_firk(&mut self, t: &Tableau, step_size: f64) -> Result<()> {
        let n = self.n_states;
        let s = self.n_stages;
        let size = self.size;
        self.lu.iter_mut().for_each(|v| *v = 0.0);
        for bi in 0..s {
            for bj in 0..s {
                let f = step_size * t.a_at(bi, bj);
                if f == 0.0 {
                    continue;
                }
                for c in 0..n {
                    for r in 0..n {
                        self.lu[(bj * n + c) * size + bi * n + r] += f * self.j[c * n + r];
                    }
                }
            }
        }
        for i in 0..size {
            self.lu[i * size + i] -= 1.0;
        }
        factor(&mut self.lu, size, &mut self.ipvt)
    }

    /// C's `gbInternalSolveNls_DIRK`: solve stage `stage` of a DIRK method.
    /// `x` starts at the predicted stage value and holds the solution on return.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn solve_dirk(
        &mut self,
        ode: &mut Ode,
        t: &Tableau,
        stage: usize,
        time: f64,
        step_size: f64,
        y_old: &[f64],
        res_const: &[f64],
        x: &mut [f64],
        event_happened: bool,
        nominals: &[f64],
    ) -> Result<Solved> {
        let x_start: Vec<f64> = x.to_vec();
        self.make_scales(nominals, x, &x_start);
        let is_esdirk = t.a_at(0, 0) == 0.0;
        let first_implicit = (stage == 0 && !is_esdirk) || (stage == 1 && is_esdirk);
        if first_implicit {
            let mut jac_called = false;
            if self.call_jac || event_happened {
                self.eval_jacobian(ode, time, y_old)?;
                jac_called = true;
            }
            if jac_called || step_size != self.lu_step_size {
                self.factor_dirk(step_size, t.a_at(stage, stage))?;
                self.lu_step_size = step_size;
            }
        }
        if event_happened {
            self.etas[stage] = f64::MAX;
        }
        let stage_time = time + t.c[stage] * step_size;
        let fac = step_size * t.a_at(stage, stage);
        self.newton_scalar(ode, stage, stage_time, fac, 1.0, res_const, x)
    }

    /// C's `gbInternalSolveNls_DIRK` for the `adams` multi-step system, whose
    /// residual is `res_const - c[s-1]*x + h*b[s-1]*f(t + h, x)`.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn solve_multistep(
        &mut self,
        ode: &mut Ode,
        t: &Tableau,
        stage_time: f64,
        step_size: f64,
        y_old: &[f64],
        res_const: &[f64],
        x: &mut [f64],
        event_happened: bool,
        nominals: &[f64],
    ) -> Result<Solved> {
        let last = t.n_stages - 1;
        let x_start: Vec<f64> = x.to_vec();
        self.make_scales(nominals, x, &x_start);
        let gamma = t.b[last];
        let mut jac_called = false;
        if self.call_jac || event_happened {
            self.eval_jacobian(ode, stage_time - step_size, y_old)?;
            jac_called = true;
        }
        if jac_called || step_size != self.lu_step_size {
            self.factor_dirk(step_size, gamma)?;
            self.lu_step_size = step_size;
        }
        if event_happened {
            self.etas[0] = f64::MAX;
        }
        self.newton_scalar(ode, 0, stage_time, step_size * gamma, t.c[last], res_const, x)
    }

    /// The scalar (single-`n_states`) simplified Newton iteration both the DIRK
    /// stages and the multi-step corrector run, over the residual
    /// `res_const - c_scale*x + fac*f(stage_time, x)`.
    #[allow(clippy::too_many_arguments)]
    fn newton_scalar(
        &mut self,
        ode: &mut Ode,
        stage: usize,
        stage_time: f64,
        fac: f64,
        c_scale: f64,
        res_const: &[f64],
        x: &mut [f64],
    ) -> Result<Solved> {
        let n = self.n_states;
        let mut nrm_delta = 0.0;
        let mut theta = 0.0;
        let mut newt_it = 1;
        loop {
            let mut f = vec![0.0; n];
            ode.eval(stage_time, x, &mut f)?;
            for i in 0..n {
                self.res[i] = res_const[i] - c_scale * x[i] + fac * f[i];
            }
            solve(&self.lu, n, &self.ipvt, &mut self.res[..n]);
            for i in 0..n {
                x[i] -= self.res[i];
            }
            self.n_iters += 1;
            let nrm_delta_prev = f64::EPSILON.max(nrm_delta);
            nrm_delta = self.scaled_norm(&self.res);
            let nrm_x = self.scaled_norm(x);
            let absorption = nrm_delta <= DBL_ABSORPTION * nrm_x;
            if newt_it > 1 {
                theta = nrm_delta / nrm_delta_prev;
                if theta >= self.theta_divergence && !absorption {
                    break;
                }
                self.etas[stage] = theta / (1.0 - theta);
            } else {
                self.etas[stage] =
                    pow(self.etas[stage].max(f64::EPSILON), self.eta_initial_damping);
            }
            if !self.etas[stage].is_finite() || !nrm_delta.is_finite() {
                return Ok(Solved::Failed);
            }
            if self.etas[stage] * nrm_delta < self.fnewt || absorption {
                self.call_jac = theta >= self.theta_keep;
                return Ok(Solved::Ok);
            }
            if newt_it == self.max_newton_it
                || (pow(theta, (self.max_newton_it - newt_it) as f64) / (1.0 - theta) * nrm_delta
                    > self.fnewt)
            {
                break;
            }
            newt_it += 1;
        }
        self.call_jac = true;
        Ok(Solved::Failed)
    }

    /// The coupled FIRK solve. `z` holds the stage values (`n_stages` blocks of
    /// `n_states`), starting at the prediction; `k` receives the stage derivatives.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn solve_firk(
        &mut self,
        ode: &mut Ode,
        t: &Tableau,
        time: f64,
        step_size: f64,
        y_old: &[f64],
        k_left: &[f64],
        z: &mut [f64],
        k: &mut [f64],
        event_happened: bool,
        nominals: &[f64],
    ) -> Result<Solved> {
        let n = self.n_states;
        let s = self.n_stages;
        let size = self.size;
        let z_start: Vec<f64> = z.to_vec();
        self.make_scales(nominals, z, &z_start);
        self.stage_time_0 = time;
        let mut jac_called = false;
        if self.call_jac || event_happened {
            self.eval_jacobian(ode, time, y_old)?;
            jac_called = true;
        }
        if jac_called || step_size != self.lu_step_size {
            self.factor_firk(t, step_size)?;
            self.lu_step_size = step_size;
        }
        if event_happened {
            for e in &mut self.etas {
                *e = f64::MAX;
            }
        }
        let mut nrm_delta = 0.0;
        let mut theta = 0.0;
        let mut newt_it = 1;
        loop {
            // K_i = f(t + c_i*h, Z_i) for every stage, except that a tableau with
            // `isKLeftAvailable` reuses the derivative at the interval's left end
            // for stage 1 rather than evaluating it (C's `residual_IRK`).
            for stage in 0..s {
                if t.k_left && stage == 0 {
                    k[..n].copy_from_slice(&k_left[..n]);
                    continue;
                }
                let st = time + t.c[stage] * step_size;
                let mut f = vec![0.0; n];
                ode.eval(st, &z[stage * n..(stage + 1) * n], &mut f)?;
                k[stage * n..(stage + 1) * n].copy_from_slice(&f);
            }
            for stage in 0..s {
                for i in 0..n {
                    let mut r = y_old[i] - z[stage * n + i];
                    for j in 0..s {
                        r += step_size * t.a_at(stage, j) * k[j * n + i];
                    }
                    self.res[stage * n + i] = r;
                }
            }
            solve(&self.lu, size, &self.ipvt, &mut self.res);
            for i in 0..size {
                z[i] -= self.res[i];
            }
            self.n_iters += 1;
            let nrm_delta_prev = f64::EPSILON.max(nrm_delta);
            nrm_delta = self.scaled_norm(&self.res);
            let nrm_z = self.scaled_norm(z);
            let absorption = nrm_delta <= DBL_ABSORPTION * nrm_z;
            if newt_it > 1 {
                theta = nrm_delta / nrm_delta_prev;
                if theta >= self.theta_divergence && !absorption {
                    break;
                }
                self.etas[0] = theta / (1.0 - theta);
            } else {
                self.etas[0] = pow(self.etas[0].max(f64::EPSILON), self.eta_initial_damping);
            }
            if !self.etas[0].is_finite() || !nrm_delta.is_finite() {
                return Ok(Solved::Failed);
            }
            if self.etas[0] * nrm_delta < self.fnewt || absorption {
                self.call_jac = theta >= self.theta_keep;
                self.reconstruct_k(t, step_size, y_old, z, k, ode)?;
                return Ok(Solved::Ok);
            }
            if newt_it == self.max_newton_it
                || (pow(theta, (self.max_newton_it - newt_it) as f64) / (1.0 - theta) * nrm_delta
                    > self.fnewt)
            {
                break;
            }
            newt_it += 1;
        }
        self.call_jac = true;
        Ok(Solved::Failed)
    }

    /// C's `K = 1/h * (A_part^-1 otimes I) * Z (+ rho * k_1)`: rebuild the stage
    /// derivatives from the *converged* stage values instead of keeping `f(Z)` from
    /// the last Newton iterate.
    ///
    /// This is not an optimization. `y = yOld + h*b^T*K` off the iterate's `f(Z)`
    /// carries the Newton residual amplified by `h*b^T*J`, an error that does not
    /// shrink with the step size — so the step size controller cannot buy accuracy
    /// back. Reconstructed from `Z`, `y` is the collocation polynomial's end value
    /// (for a stiffly accurate method like Radau IIA, exactly `Z_s`).
    fn reconstruct_k(
        &mut self,
        t: &Tableau,
        step_size: f64,
        y_old: &[f64],
        z: &mut [f64],
        k: &mut [f64],
        ode: &mut Ode,
    ) -> Result<()> {
        let n = self.n_states;
        let s = self.n_stages;
        // Without the tableau's `A_part^-1` there is nothing to invert with, so the
        // iterate's `f(Z)` has to do. Every FIRK method in `tableau_data` has one.
        let Some(tr) = t.t_transform.as_ref() else { return Ok(()) };
        let sr = tr.size;
        let off = usize::from(tr.first_row_zero);
        // An explicit first stage is `Z_1 = yOld`, `k_1 = f(t, yOld)`.
        if tr.first_row_zero {
            z[..n].copy_from_slice(y_old);
            let mut f = vec![0.0; n];
            ode.eval(self.stage_time_0, y_old, &mut f)?;
            k[..n].copy_from_slice(&f);
        }
        let inv_h = 1.0 / step_size;
        let k1 = k[..n].to_vec();
        let mut out = vec![0.0; sr * n];
        for j in 0..sr {
            for i in 0..n {
                let mut acc = 0.0;
                for l in 0..sr {
                    acc += tr.a_part_inv[j * sr + l] * (z[(off + l) * n + i] - y_old[i]);
                }
                out[j * n + i] = acc * inv_h;
                if tr.first_row_zero {
                    // `rho = -A_part^-1 * A_{r,1}` folds the explicit stage back in.
                    out[j * n + i] += tr.rho.as_ref().map_or(0.0, |r| r[j]) * k1[i];
                }
            }
        }
        k[off * n..(off + sr) * n].copy_from_slice(&out);
        // An explicit last stage (Lobatto IIIB) is evaluated from the ones before it.
        if tr.last_column_zero {
            let last = s - 1;
            let mut x_last = y_old.to_vec();
            for i in 0..n {
                for j in 0..last {
                    x_last[i] += step_size * t.a_at(last, j) * k[j * n + i];
                }
            }
            let mut f = vec![0.0; n];
            ode.eval(self.stage_time_0 + t.c[last] * step_size, &x_last, &mut f)?;
            k[last * n..(last + 1) * n].copy_from_slice(&f);
            z[last * n..(last + 1) * n].copy_from_slice(&x_last);
        }
        Ok(())
    }

    /// C's `gbInternalContractiveDefect`: `err = (gamma/h*I - J)^-1 * (f(t_n, y_n) -
    /// d(0)^T*A*K)`. C reuses the T-transform's factorization of the same matrix;
    /// the coupled solve here has no such block, so it is factorized separately
    /// (one extra `N^3` per step size change).
    #[allow(clippy::too_many_arguments)]
    pub(super) fn contractive_defect(
        &mut self,
        ode: &mut Ode,
        t: &Tableau,
        time: f64,
        step_size: f64,
        y_old: &[f64],
        k: &[f64],
        f_left: Option<&[f64]>,
        err: &mut [f64],
    ) -> Result<()> {
        let n = self.n_states;
        let dt_a = t.contractive_dt_a.as_ref().expect("contractive defect without dT_A");
        let gamma = t.t_transform.as_ref().and_then(|tr| tr.gamma.first().copied()).unwrap_or(1.0);
        for i in 0..n {
            let mut acc = 0.0;
            for stage in 0..self.n_stages {
                acc += dt_a[stage] * k[stage * n + i];
            }
            err[i] = -acc;
        }
        match f_left {
            Some(f0) => {
                for i in 0..n {
                    err[i] += f0[i];
                }
            }
            None => {
                let mut f0 = vec![0.0; n];
                ode.eval(time, y_old, &mut f0)?;
                for i in 0..n {
                    err[i] += f0[i];
                }
            }
        }
        self.factor_defect(gamma, step_size)?;
        solve(&self.defect_lu, n, &self.defect_ipvt, &mut err[..n]);
        Ok(())
    }

    /// C's `gbInternalContractiveFilterError`: apply one contraction to the
    /// embedded estimate already in `err`.
    pub(super) fn contractive_filter(
        &mut self,
        t: &Tableau,
        step_size: f64,
        err: &mut [f64],
    ) -> Result<()> {
        let n = self.n_states;
        match t.t_transform.as_ref().and_then(|tr| tr.gamma.first().copied()) {
            // C contracts with the first real block of the T-transform,
            // `gamma/h*I - J`, then scales by `gamma/h`.
            Some(gamma) => {
                self.factor_defect(gamma, step_size)?;
                solve(&self.defect_lu, n, &self.defect_ipvt, &mut err[..n]);
                let scale = gamma / step_size;
                for v in &mut err[..n] {
                    *v *= scale;
                }
            }
            // Without one the system is the DIRK `h*gamma*J - I`, which already is
            // the filter up to sign.
            None => solve(&self.lu, n, &self.ipvt, &mut err[..n]),
        }
        Ok(())
    }

    /// Factorize `gamma/h*I - J`, which both contractive estimators contract with.
    fn factor_defect(&mut self, gamma: f64, step_size: f64) -> Result<()> {
        if step_size == self.defect_step_size {
            return Ok(());
        }
        let n = self.n_states;
        let g = gamma / step_size;
        for c in 0..n {
            for r in 0..n {
                self.defect_lu[c * n + r] = -self.j[c * n + r];
            }
            self.defect_lu[c * n + c] += g;
        }
        factor(&mut self.defect_lu, n, &mut self.defect_ipvt)?;
        self.defect_step_size = step_size;
        Ok(())
    }
}

/// C's `numericalDifferentiationDeltaXsolver`.
const DELTA_X_SOLVER: f64 = 1e-8;

/// LU-factorize a column-major `n*n` matrix in place (LINPACK `dgefa`).
fn factor(a: &mut [f64], n: usize, ipvt: &mut [i32]) -> Result<()> {
    let mut info = 0i32;
    daskr::linpack::dgefa(a, n as i32, n as i32, ipvt, &mut info);
    if info != 0 {
        return Err("CodegenWasmJit: gbode: singular Newton matrix");
    }
    Ok(())
}

/// Solve `A x = b` in place with the factorization from [`factor`] (`dgesl`).
fn solve(a: &[f64], n: usize, ipvt: &[i32], b: &mut [f64]) {
    daskr::linpack::dgesl(a, n as i32, n as i32, ipvt, b, 0);
}

/// Read a numeric `-gb*` flag, falling back to `default` when unset or out of range.
fn gb_number(name: &str, default: f64, ok: impl Fn(f64) -> bool) -> f64 {
    match crate::simflags::with_flags(|f| f.gb_flag(name)) {
        Some(v) => match v.parse::<f64>() {
            Ok(v) if ok(v) => v,
            _ => default,
        },
        None => default,
    }
}
