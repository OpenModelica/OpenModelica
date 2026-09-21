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
//! As in C, a FIRK tableau that carries its T-transformation is decoupled by it
//! (`solve_firk_t`): one `n` system per distinct real eigenvalue of `A^-1`, one
//! per conjugate pair — solved as its real `2n` embedding where C uses complex
//! KLU — with forward substitution through `L`. A FIRK tableau without one falls
//! back to the coupled `s*n` solve; both go through [`super::linsol`], which is
//! sparse when the model carries a pattern.
//!
//! The convergence test, the `eta`/`theta` bookkeeping that decides when to reuse
//! the factorization, and the scaled norms are C's, so a step converges after the
//! same number of iterations.

use alloc::vec;
use alloc::vec::Vec;

use super::tableau::{GmType, Tableau};
use crate::gbode::math::{abs, pow, sqrt};
use crate::{Ode, Result};

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
    /// Evaluate `J` through the model's symbolic Jacobian (colored seeds).
    sym_jac: bool,
    /// The factorization is stale and `J` must be recomputed.
    call_jac: bool,
    scal: Vec<f64>,
    /// The ODE Jacobian, column-major `n_states * n_states`.
    j: Vec<f64>,
    /// Assembly scratch for the simplified NLS matrix (column-major `size * size`)
    /// and its factorization.
    lu: Vec<f64>,
    factored: Option<super::linsol::GbLu>,
    /// The step size the current factorization was built for.
    lu_step_size: f64,
    /// `gamma/h*I - J` for the contractive-defect estimator, and the `h` it was
    /// built for.
    defect_lu: Vec<f64>,
    defect_factored: Option<super::linsol::GbLu>,
    defect_step_size: f64,
    /// T-transform factorizations, one per distinct eigenvalue of `A^-1`:
    /// `gamma/h*I - J` for the real ones, `(alpha+i*beta)/h*I - J` for the
    /// conjugate pairs as their real `2n` embedding. Valid for `lu_step_size`.
    t_real: Vec<super::linsol::GbLu>,
    t_cmplx: Vec<super::linsol::GbLu>,
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

impl GbNls {
    /// C's `gbInternalNlsAllocate` for the single-rate case.
    pub(super) fn new(t: &Tableau, n_states: usize, tol: f64, jac_colors: usize, sym_jac: bool) -> Self {
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
        // C: 5 Newton iterations per (E)SDIRK stage, more for a FIRK system
        // (`4 + 2*transform->size`).
        let max_newton_it = if t.gm_type == GmType::Implicit {
            4 + 2 * t.t_transform.as_ref().map_or(t.n_stages, |tr| tr.size) as u32
        } else {
            5
        };
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
            sym_jac,
            call_jac: true,
            scal: vec![0.0; size],
            j: vec![0.0; n_states * n_states],
            lu: vec![0.0; size * size],
            factored: None,
            lu_step_size: 0.0,
            defect_lu: vec![0.0; n_states * n_states],
            defect_factored: None,
            defect_step_size: 0.0,
            t_real: Vec::new(),
            t_cmplx: Vec::new(),
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

    /// The ODE Jacobian at `(time, y)` — C's `gbInternal_evalJacobian`: the colored
    /// symbolic Jacobian when the model carries one, else colored finite
    /// differences (`gbInternal_evalNumericalJacobian`). Stored column-major so it
    /// can feed `dgefa` directly.
    fn eval_jacobian(&mut self, ode: &mut dyn Ode, time: f64, y: &[f64]) -> Result<()> {
        let n = self.n_states;
        self.n_jac_evals += 1;
        // Anything factorized from the old `J` is now stale, whatever the step size.
        self.lu_step_size = 0.0;
        self.defect_step_size = 0.0;
        // The colouring outlives the evaluations below, which borrow `ode`.
        let colors: Vec<Vec<u32>> = match ode.jac_colors() {
            [] => (0..n as u32).map(|c| vec![c]).collect(),
            c => c.to_vec(),
        };
        let rows_by_col: Vec<Vec<u32>> = match ode.jac_rows_by_col() {
            [] => (0..n).map(|_| (0..n as u32).collect()).collect(),
            r => r.to_vec(),
        };
        if self.sym_jac && ode.has_jacobian_vector() {
            // C evaluates the ODE at the base point before the column equations.
            ode.eval(time, y, &mut self.fbase)?;
            let mut seed = vec![0.0; n];
            let mut out = vec![0.0; n];
            for group in &colors {
                seed.fill(0.0);
                for &c in group {
                    seed[c as usize] = 1.0;
                }
                if !ode.jacobian_vector(time, y, &seed, &mut out) {
                    return Err(
                        "CodegenWasmJit: gbode: the model could not multiply by its Jacobian",
                    );
                }
                for &c in group {
                    let c = c as usize;
                    for &r in &rows_by_col[c] {
                        self.j[c * n + r as usize] = out[r as usize];
                    }
                }
            }
            return Ok(());
        }
        let nominals: Vec<f64> = ode.nominals().to_vec();
        let maxs: Vec<f64> = ode.maxs().to_vec();
        let tol = self.integrator_tol;
        ode.set_context_jacobian();
        let run = (|| -> Result<()> {
            ode.eval(time, y, &mut self.fbase)?;
            self.ysave.copy_from_slice(y);
            let mut probe = self.ysave.clone();
            for group in &colors {
                let mut inv_del = vec![0.0; n];
                for &col in group {
                    let c = col as usize;
                    // C's step choice, a la the DASSL interface:
                    // h_i = delta_h * max(|x_i|, 1e-3, |delta_h*f_i|, atol*nom + rtol*|x_i|).
                    let nominal = nominals.get(c).copied().unwrap_or(1.0);
                    let raw_weight = tol * nominal + tol * abs(y[c]);
                    let mut del = DELTA_X_SOLVER
                        * abs(y[c])
                            .max(1e-3)
                            .max(abs(DELTA_X_SOLVER * self.fbase[c]))
                            .max(abs(raw_weight));
                    del = y[c] + del - y[c];
                    if maxs.get(c).is_some_and(|&mx| y[c] + del >= mx) {
                        del = -del;
                    }
                    inv_del[c] = 1.0 / del;
                    probe[c] = y[c] + del;
                }
                let mut fp = vec![0.0; n];
                ode.eval(time, &probe, &mut fp)?;
                for &col in group {
                    let c = col as usize;
                    for &r in &rows_by_col[c] {
                        let r = r as usize;
                        self.j[c * n + r] = (fp[r] - self.fbase[r]) * inv_del[c];
                    }
                    probe[c] = y[c];
                }
            }
            Ok(())
        })();
        ode.set_context_algebraic();
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
        self.factored = Some(super::linsol::factor(&self.lu, n)?);
        Ok(())
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
        self.factored = Some(super::linsol::factor(&self.lu, size)?);
        Ok(())
    }

    /// C's `gbInternalSolveNls_DIRK`: solve stage `stage` of a DIRK method.
    /// `x` starts at the predicted stage value and holds the solution on return.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn solve_dirk(
        &mut self,
        ode: &mut dyn Ode,
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
        ode: &mut dyn Ode,
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
        ode: &mut dyn Ode,
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
            self.factored.as_mut().expect("solve before factor").solve(&mut self.res[..n]);
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

    /// The FIRK solve: the T-transformed iteration when the tableau carries a
    /// transform, else the coupled `s*n` system. `z` holds the stage values
    /// (`n_stages` blocks of `n_states`), starting at the prediction; `k` receives
    /// the stage derivatives.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn solve_firk(
        &mut self,
        ode: &mut dyn Ode,
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
        if t.t_transform.is_some() {
            return self.solve_firk_t(ode, t, time, step_size, y_old, z, k, event_happened, nominals);
        }
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
            self.factored.as_mut().expect("solve before factor").solve(&mut self.res);
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

    /// C's `gbInternalSolveNls_T_Transform`: the FIRK system decoupled by the
    /// tableau's T-transformation. `T^-1*A^-1*T = Lambda + L` block-triangularizes
    /// the Runge-Kutta matrix, so each Newton iteration solves one `n` system per
    /// distinct real eigenvalue of `A^-1` and one per conjugate pair — the latter
    /// as its real `2n` embedding `[[M_re, -M_im], [M_im, M_re]]`, where C uses
    /// KLU's complex factorization — with forward substitution through `L`.
    #[allow(clippy::too_many_arguments)]
    fn solve_firk_t(
        &mut self,
        ode: &mut dyn Ode,
        t: &Tableau,
        time: f64,
        step_size: f64,
        y_old: &[f64],
        z: &mut [f64],
        k: &mut [f64],
        event_happened: bool,
        nominals: &[f64],
    ) -> Result<Solved> {
        let n = self.n_states;
        let inv_h = 1.0 / step_size;
        let z_start: Vec<f64> = z.to_vec();
        // C's scales for the transformed solve run over `n` (the first stage's
        // start values), with the stacked norms below.
        self.make_scales_t(nominals, y_old, &z_start[..n]);
        let tr = t.t_transform.as_ref().expect("transformed solve without a transform");
        let tsize = tr.size;
        let off = usize::from(tr.first_row_zero);
        let mut jac_called = false;
        if self.call_jac || event_happened {
            self.eval_jacobian(ode, time, y_old)?;
            jac_called = true;
            if tr.first_row_zero {
                z[..n].copy_from_slice(y_old);
                k[..n].copy_from_slice(&self.fbase);
            }
        } else if tr.first_row_zero {
            // The explicit first stage's derivative, fresh each solve as in C.
            let mut f0 = vec![0.0; n];
            ode.eval(time, y_old, &mut f0)?;
            z[..n].copy_from_slice(y_old);
            k[..n].copy_from_slice(&f0);
            self.fbase.copy_from_slice(&f0);
        }
        if jac_called || step_size != self.lu_step_size {
            self.factor_transformed(t, inv_h)?;
            self.lu_step_size = step_size;
        }
        if event_happened {
            for e in &mut self.etas {
                *e = f64::MAX;
            }
        }
        let tr = t.t_transform.as_ref().unwrap();
        // Z_j = X_start_j - yOld (C copies the guesses without the explicit-row
        // offset), W = (T^-1 otimes I) Z.
        let mut tz = vec![0.0; tsize * n];
        for j in 0..tsize {
            for i in 0..n {
                tz[j * n + i] = z_start[j * n + i] - y_old[i];
            }
        }
        let mut w = vec![0.0; tsize * n];
        kron_vec(&tr.t_inv, tsize, n, &tz, &mut w);
        let k1: Vec<f64> = tr.first_row_zero.then(|| k[..n].to_vec()).unwrap_or_default();
        let mut fw = vec![0.0; tsize * n];
        let mut res = vec![0.0; tsize * n];
        let mut work_y = vec![0.0; n];
        let mut f = vec![0.0; n];
        let mut rhs2 = vec![0.0; 2 * n];
        let mut nrm_delta = 0.0;
        let mut theta = 0.0;
        let mut newt_it = 1;
        loop {
            // F at the current stage values yOld + Z_j.
            for j in 0..tsize {
                let st = time + t.c[j + off] * step_size;
                for i in 0..n {
                    work_y[i] = y_old[i] + tz[j * n + i];
                }
                ode.eval(st, &work_y, &mut f)?;
                fw[j * n..(j + 1) * n].copy_from_slice(&f);
            }
            // res = (T^-1 otimes I)*F - 1/h*((Lambda+L) otimes I)*W (+ phi*k_1).
            kron_vec(&tr.t_inv, tsize, n, &fw, &mut res);
            lambda_l_matvec(tr, n, -inv_h, &w, &mut res);
            if tr.first_row_zero {
                let phi = tr.phi.as_ref().expect("explicit first row without phi");
                for j in 0..tsize {
                    for i in 0..n {
                        res[j * n + i] += phi[j] * k1[i];
                    }
                }
            }
            // Block-forward substitution: each solved row feeds the `L` coupling
            // of the ones below it.
            for row in 0..tr.n_real_blocks {
                if tr.has_l[row] {
                    for col in 0..row {
                        let a = -inv_h * tr.l[row * (row - 1) / 2 + col];
                        if a != 0.0 {
                            for i in 0..n {
                                res[row * n + i] += a * res[col * n + i];
                            }
                        }
                    }
                }
                let sys = tr.real_eigenvalue_index[row];
                self.t_real[sys].solve(&mut res[row * n..(row + 1) * n]);
            }
            let mut cmplx_row = tr.n_real_blocks;
            for block in 0..tr.n_complex_blocks {
                for row in [cmplx_row, cmplx_row + 1] {
                    if !tr.has_l[row] {
                        continue;
                    }
                    for col in 0..cmplx_row {
                        let a = -inv_h * tr.l[row * (row - 1) / 2 + col];
                        if a != 0.0 {
                            for i in 0..n {
                                res[row * n + i] += a * res[col * n + i];
                            }
                        }
                    }
                }
                rhs2[..n].copy_from_slice(&res[cmplx_row * n..(cmplx_row + 1) * n]);
                rhs2[n..2 * n].copy_from_slice(&res[(cmplx_row + 1) * n..(cmplx_row + 2) * n]);
                let sys = tr.complex_eigenpair_index[block];
                self.t_cmplx[sys].solve(&mut rhs2);
                res[cmplx_row * n..(cmplx_row + 1) * n].copy_from_slice(&rhs2[..n]);
                res[(cmplx_row + 1) * n..(cmplx_row + 2) * n].copy_from_slice(&rhs2[n..2 * n]);
                cmplx_row += 2;
            }
            for i in 0..tsize * n {
                w[i] += res[i];
            }
            kron_vec(&tr.t, tsize, n, &w, &mut tz);
            self.n_iters += 1;
            let nrm_delta_prev = f64::EPSILON.max(nrm_delta);
            nrm_delta = self.scaled_norm_t(&res, tsize);
            let nrm_x = {
                let mut sum = 0.0;
                for j in 0..tsize {
                    for i in 0..n {
                        let v = (y_old[i] + tz[j * n + i]) * self.scal[i];
                        sum += v * v;
                    }
                }
                sqrt(sum / (n * tsize) as f64)
            };
            let absorption = nrm_delta <= DBL_ABSORPTION * nrm_x;
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
                // X_j = yOld + Z_j; K = 1/h*(A_part^-1 otimes I)*Z (+ rho*k_1).
                for j in 0..tsize {
                    for i in 0..n {
                        z[(j + off) * n + i] = y_old[i] + tz[j * n + i];
                    }
                }
                kron_vec(&tr.a_part_inv, tsize, n, &tz, &mut fw);
                for j in 0..tsize {
                    for i in 0..n {
                        let mut v = inv_h * fw[j * n + i];
                        if tr.first_row_zero {
                            v += tr.rho.as_ref().map_or(0.0, |r| r[j]) * k1[i];
                        }
                        k[(j + off) * n + i] = v;
                    }
                }
                // An explicit last stage (Lobatto IIIB) evaluates off the others.
                if tr.last_column_zero {
                    let last = t.n_stages - 1;
                    for i in 0..n {
                        let mut v = y_old[i];
                        for j in 0..last {
                            v += step_size * t.a_at(last, j) * k[j * n + i];
                        }
                        work_y[i] = v;
                    }
                    ode.eval(time + t.c[last] * step_size, &work_y, &mut f)?;
                    z[last * n..(last + 1) * n].copy_from_slice(&work_y);
                    k[last * n..(last + 1) * n].copy_from_slice(&f);
                }
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

    /// Factor the transformed systems from the current `J`: `gamma/h*I - J` per
    /// distinct real eigenvalue, the real `2n` embedding of
    /// `(alpha+i*beta)/h*I - J` per conjugate pair.
    fn factor_transformed(&mut self, t: &Tableau, inv_h: f64) -> Result<()> {
        let n = self.n_states;
        let tr = t.t_transform.as_ref().expect("transformed factor without a transform");
        self.t_real.clear();
        self.t_cmplx.clear();
        for e in 0..tr.n_real_eigenvalues {
            let g = tr.gamma[e] * inv_h;
            for c in 0..n {
                for r in 0..n {
                    self.lu[c * n + r] = -self.j[c * n + r];
                }
                self.lu[c * n + c] += g;
            }
            self.t_real.push(super::linsol::factor(&self.lu[..n * n], n)?);
        }
        let m = 2 * n;
        for e in 0..tr.n_complex_eigenpairs {
            let a = tr.alpha[e] * inv_h;
            let b = tr.beta[e] * inv_h;
            self.lu[..m * m].iter_mut().for_each(|v| *v = 0.0);
            for c in 0..n {
                for r in 0..n {
                    let v = -self.j[c * n + r];
                    self.lu[c * m + r] = v;
                    self.lu[(n + c) * m + n + r] = v;
                }
                self.lu[c * m + c] += a;
                self.lu[(n + c) * m + n + c] += a;
                self.lu[c * m + n + c] += b;
                self.lu[(n + c) * m + c] -= b;
            }
            self.t_cmplx.push(super::linsol::factor(&self.lu[..m * m], m)?);
        }
        Ok(())
    }

    /// `createGbScales` for the transformed solve: `n` weights, stacked norms.
    fn make_scales_t(&mut self, nominals: &[f64], y1: &[f64], y2: &[f64]) {
        let tol = self.integrator_tol;
        for i in 0..self.n_states {
            self.scal[i] = 1.0 / (tol * nominals[i] + abs(y1[i]).max(abs(y2[i])) * tol);
        }
    }

    /// `gbScalesNorm` over `stack` blocks of `n` against the `n` weights.
    fn scaled_norm_t(&self, v: &[f64], stack: usize) -> f64 {
        let n = self.n_states;
        let mut sum = 0.0;
        for j in 0..stack {
            for i in 0..n {
                let t = v[j * n + i] * self.scal[i];
                sum += t * t;
            }
        }
        sqrt(sum / (n * stack) as f64)
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
        ode: &mut dyn Ode,
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
    /// d(0)^T*A*K)`, contracting with the transformed solve's first real system
    /// when its factorization is current, else with a separate one.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn contractive_defect(
        &mut self,
        ode: &mut dyn Ode,
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
        // C contracts with the T-transform's first real system, whose
        // factorization the Newton iteration already holds for this step size.
        if step_size == self.lu_step_size && !self.t_real.is_empty() {
            self.t_real[0].solve(&mut err[..n]);
        } else {
            self.factor_defect(gamma, step_size)?;
            self.defect_factored.as_mut().expect("solve before factor").solve(&mut err[..n]);
        }
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
                if step_size == self.lu_step_size && !self.t_real.is_empty() {
                    self.t_real[0].solve(&mut err[..n]);
                } else {
                    self.factor_defect(gamma, step_size)?;
                    self.defect_factored
                        .as_mut()
                        .expect("solve before factor")
                        .solve(&mut err[..n]);
                }
                let scale = gamma / step_size;
                for v in &mut err[..n] {
                    *v *= scale;
                }
            }
            // Without one the system is the DIRK `h*gamma*J - I`, which already is
            // the filter up to sign.
            None => self.factored.as_mut().expect("solve before factor").solve(&mut err[..n]),
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
        self.defect_factored = Some(super::linsol::factor(&self.defect_lu, n)?);
        self.defect_step_size = step_size;
        Ok(())
    }
}

/// C's `numericalDifferentiationDeltaXsolver`, `sqrt(DBL_EPSILON)` at runtime.
const DELTA_X_SOLVER: f64 = 1.4901161193847656e-8;

/// `(M otimes I) * v` for `stack` blocks of `n`: `out_j = sum_l M[j,l] * v_l`,
/// with `M` in the tableau data's flat `j*stack + l` convention.
fn kron_vec(m: &[f64], stack: usize, n: usize, v: &[f64], out: &mut [f64]) {
    for j in 0..stack {
        for i in 0..n {
            let mut acc = 0.0;
            for l in 0..stack {
                acc += m[j * stack + l] * v[l * n + i];
            }
            out[j * n + i] = acc;
        }
    }
}

/// C's `scaled_transform_matvec`: `out += factor * ((Lambda + L) otimes I) * v`,
/// with the 1x1 real rows, the 2x2 conjugate-pair blocks, and the strictly lower
/// couplings (`L` packed by row, rows without one skipped via `has_l`).
fn lambda_l_matvec(
    tr: &super::tableau::TTransform,
    n: usize,
    factor: f64,
    v: &[f64],
    out: &mut [f64],
) {
    for row in 0..tr.n_real_blocks {
        let a = factor * tr.gamma[tr.real_eigenvalue_index[row]];
        for i in 0..n {
            out[row * n + i] += a * v[row * n + i];
        }
    }
    let mut row = tr.n_real_blocks;
    for block in 0..tr.n_complex_blocks {
        let sys = tr.complex_eigenpair_index[block];
        let a = factor * tr.alpha[sys];
        let b = factor * tr.beta[sys];
        for i in 0..n {
            let (v0, v1) = (v[row * n + i], v[(row + 1) * n + i]);
            out[row * n + i] += a * v0 - b * v1;
            out[(row + 1) * n + i] += b * v0 + a * v1;
        }
        row += 2;
    }
    let size = tr.size;
    for row in 1..size {
        if !tr.has_l[row] {
            continue;
        }
        // Complex rows couple only to columns before their own 2x2 block.
        let col_end = if row >= tr.n_real_blocks {
            tr.n_real_blocks + (row - tr.n_real_blocks) / 2 * 2
        } else {
            row
        };
        for col in 0..col_end {
            let a = factor * tr.l[row * (row - 1) / 2 + col];
            if a != 0.0 {
                for i in 0..n {
                    out[row * n + i] += a * v[col * n + i];
                }
            }
        }
    }
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
