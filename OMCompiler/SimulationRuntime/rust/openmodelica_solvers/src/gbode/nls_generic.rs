//! The generic gbode nonlinear solvers (`-gbnls=newton`/`kinsol`), C's
//! `gbode_nls.c` residuals under `solveNLS_gb`. The stage systems are the same
//! ones the internal solver iterates on; the difference is the solver: C hands
//! them to the runtime's NLS machinery (dense damped Newton, or KINSOL over KLU),
//! which solves to the tight `newtonFTol` instead of the internal solver's
//! integrator-scaled target, evaluates `f` at the accepted iterate rather than
//! reconstructing `k`, and retries from other start points on failure.
//!
//! Both `-gbnls` values run the damped Newton here over [`super::linsol`]
//! (sparse past its threshold, as KINSOL runs over KLU); KINSOL's own iteration
//! details are a difference in path, not in results.

use alloc::vec;
use alloc::vec::Vec;

use super::Solved;
use super::tableau::Tableau;
use crate::gbode::math::{abs, pow, sqrt};
use crate::{Ode, Result};

/// C's `newtonFTol` (`model_help.c`).
const NEWTON_FTOL_DEFAULT: f64 = 1e-12;
/// C's `DEFAULT_FLAG_NEWTON_MAX_STEPS`.
const NEWTON_MAX_STEPS: u32 = 20;

/// One residual evaluation: fill `res` at the iterate `x`, leaving the stage
/// derivatives wherever the caller wants them.
pub(super) trait GbResidual {
    fn eval(&mut self, ode: &mut dyn Ode, x: &[f64], res: &mut [f64]) -> Result<()>;
    /// Assemble the residual's Jacobian into `jac` (column-major `size*size`)
    /// from the ODE Jacobian `j` (column-major `n_states*n_states`).
    fn assemble(&self, j: &[f64], n_states: usize, jac: &mut [f64]);
}

/// `res = res_const - c_scale*x + fac*f(stage_time, x)`: a DIRK stage
/// (`residual_DIRK`, `c_scale` 1) or the multi-step corrector (`residual_MS`,
/// `c_scale` the last `c`).
pub(super) struct StageResidual<'a> {
    pub stage_time: f64,
    pub fac: f64,
    pub c_scale: f64,
    pub res_const: &'a [f64],
}

impl GbResidual for StageResidual<'_> {
    fn eval(&mut self, ode: &mut dyn Ode, x: &[f64], res: &mut [f64]) -> Result<()> {
        let n = x.len();
        let mut f = vec![0.0; n];
        ode.eval(self.stage_time, x, &mut f)?;
        for i in 0..n {
            res[i] = self.res_const[i] - self.c_scale * x[i] + self.fac * f[i];
        }
        Ok(())
    }

    fn assemble(&self, j: &[f64], n: usize, jac: &mut [f64]) {
        for c in 0..n {
            for r in 0..n {
                jac[c * n + r] = self.fac * j[c * n + r];
            }
            jac[c * n + c] -= self.c_scale;
        }
    }
}

/// `residual_IRK`: all stages coupled, `res_i = yOld - Z_i + h*sum_j a_ij*f_j`.
/// The stage derivatives land in `k` as the iteration evaluates them.
pub(super) struct IrkResidual<'a> {
    pub t: &'a Tableau,
    pub time: f64,
    pub step_size: f64,
    pub y_old: &'a [f64],
    pub k_left: &'a [f64],
    pub k: &'a mut [f64],
}

impl GbResidual for IrkResidual<'_> {
    fn eval(&mut self, ode: &mut dyn Ode, x: &[f64], res: &mut [f64]) -> Result<()> {
        let n = self.y_old.len();
        let s = self.t.n_stages;
        for stage in 0..s {
            if self.t.k_left && stage == 0 {
                self.k[..n].copy_from_slice(&self.k_left[..n]);
                continue;
            }
            let st = self.time + self.t.c[stage] * self.step_size;
            let mut f = vec![0.0; n];
            ode.eval(st, &x[stage * n..(stage + 1) * n], &mut f)?;
            self.k[stage * n..(stage + 1) * n].copy_from_slice(&f);
        }
        for stage in 0..s {
            for i in 0..n {
                let mut r = self.y_old[i] - x[stage * n + i];
                for j in 0..s {
                    r += self.step_size * self.t.a_at(stage, j) * self.k[j * n + i];
                }
                res[stage * n + i] = r;
            }
        }
        Ok(())
    }

    fn assemble(&self, j: &[f64], n: usize, jac: &mut [f64]) {
        let s = self.t.n_stages;
        let size = s * n;
        jac.iter_mut().for_each(|v| *v = 0.0);
        for bi in 0..s {
            for bj in 0..s {
                let f = self.step_size * self.t.a_at(bi, bj);
                if f == 0.0 {
                    continue;
                }
                for c in 0..n {
                    for r in 0..n {
                        jac[(bj * n + c) * size + bi * n + r] += f * j[c * n + r];
                    }
                }
            }
        }
        for i in 0..size {
            jac[i * size + i] -= 1.0;
        }
    }
}

/// C's `DATA_NEWTON` + `solveNewton` state, sized once per run.
pub(super) struct GbNlsGeneric {
    n_states: usize,
    pub size: usize,
    ftol: f64,
    sym_jac: bool,
    /// The ODE Jacobian at the current iterate, column-major.
    j: Vec<f64>,
    jac: Vec<f64>,
    factored: Option<super::linsol::GbLu>,
    fbase: Vec<f64>,
    pub n_jac_evals: u64,
}

impl GbNlsGeneric {
    pub(super) fn new(t: &Tableau, n_states: usize, sym_jac: bool) -> Self {
        let size = match t.gm_type {
            super::tableau::GmType::Implicit => t.n_stages * n_states,
            _ => n_states,
        };
        let ftol =
            crate::simflags::with_flags(|f| f.newton_ftol).unwrap_or(NEWTON_FTOL_DEFAULT);
        GbNlsGeneric {
            n_states,
            size,
            ftol,
            sym_jac,
            j: vec![0.0; n_states * n_states],
            jac: vec![0.0; size * size],
            factored: None,
            fbase: vec![0.0; n_states],
            n_jac_evals: 0,
        }
    }

    /// The ODE Jacobian at `(time, y)` — the same colored symbolic / colored FD
    /// evaluation the internal solver uses, at the iterate instead of `yOld`.
    fn eval_ode_jacobian(&mut self, ode: &mut dyn Ode, time: f64, y: &[f64]) -> Result<()> {
        let n = self.n_states;
        self.n_jac_evals += 1;
        let colors: Vec<Vec<u32>> = match ode.jac_colors() {
            [] => (0..n as u32).map(|c| vec![c]).collect(),
            c => c.to_vec(),
        };
        let rows_by_col: Vec<Vec<u32>> = match ode.jac_rows_by_col() {
            [] => (0..n).map(|_| (0..n as u32).collect()).collect(),
            r => r.to_vec(),
        };
        if self.sym_jac && ode.has_jacobian_vector() {
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
        // C's `wrapper_fvec_der` FD step: `delta_h * max(delta_h, |x|, |f|)`.
        ode.set_context_jacobian();
        let run = (|| -> Result<()> {
            ode.eval(time, y, &mut self.fbase)?;
            let mut probe = y.to_vec();
            for group in &colors {
                let mut inv_del = vec![0.0; n];
                for &col in group {
                    let c = col as usize;
                    let mut del =
                        DELTA_H * DELTA_H.max(abs(y[c])).max(abs(self.fbase[c]));
                    del = y[c] + del - y[c];
                    if del == 0.0 {
                        del = DELTA_H;
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

    /// Where the residual sees the ODE Jacobian: the base point for a coupled
    /// system, the stage point for a scalar one — both are the iterate here, which
    /// full Newton evaluates at.
    fn factor_at(
        &mut self,
        ode: &mut dyn Ode,
        res: &mut dyn GbResidual,
        jac_time: f64,
        jac_y: &[f64],
    ) -> Result<()> {
        self.eval_ode_jacobian(ode, jac_time, jac_y)?;
        let mut jac = core::mem::take(&mut self.jac);
        res.assemble(&self.j, self.n_states, &mut jac);
        self.jac = jac;
        self.factored = Some(super::linsol::factor(&self.jac, self.size)?);
        Ok(())
    }

    /// C's `solveNewton` around `_omc_newton`: damped Newton to `newtonFTol`, with
    /// the retry ladder over start vectors and, at the end, a relaxed tolerance.
    /// `jac_time` is the point the ODE Jacobian is taken at (the stage time for a
    /// scalar system, the interval's left end for a coupled one).
    pub(super) fn solve(
        &mut self,
        ode: &mut dyn Ode,
        res: &mut dyn GbResidual,
        jac_time: f64,
        starts: &[&[f64]],
        nominals: &[f64],
        x: &mut [f64],
    ) -> Result<Solved> {
        let size = self.size;
        let n = self.n_states;
        let mut r = vec![0.0; size];
        let mut r_new = vec![0.0; size];
        let mut x_try = vec![0.0; size];
        // C's retries: the start vectors, then +1% nominal, then the nominals.
        let mut attempts: Vec<Vec<f64>> = starts.iter().map(|s| s.to_vec()).collect();
        if let Some(base) = starts.last() {
            let mut v = base.to_vec();
            for i in 0..size {
                v[i] += nominals[i % n] * 0.01;
            }
            attempts.push(v);
            attempts.push((0..size).map(|i| nominals[i % n]).collect());
        }
        // C's `retries2`: relax the tolerance tenfold, up to four times.
        for relax in 0..5 {
            let tol = self.ftol * pow(10.0, relax as f64);
            for start in &attempts {
                x.copy_from_slice(start);
                if res.eval(ode, x, &mut r).is_err() {
                    continue;
                }
                let mut nrm = enorm(&r);
                if !nrm.is_finite() {
                    continue;
                }
                if self.factor_at(ode, res, jac_time, &x[..n.min(size)]).is_err() {
                    continue;
                }
                let mut converged = nrm <= tol || self.scaled_norm(&r) <= tol;
                let mut stale = false;
                'newton: for _ in 0..NEWTON_MAX_STEPS {
                    if converged {
                        break;
                    }
                    // C recomputes the Jacobian only when the iteration struggles.
                    if stale && self.factor_at(ode, res, jac_time, &x[..n.min(size)]).is_err() {
                        break 'newton;
                    }
                    stale = false;
                    let mut dx = r.clone();
                    self.factored.as_mut().expect("solve before factor").solve(&mut dx);
                    // The Newton step is `x - jac⁻¹·res` with this Jacobian's sign
                    // convention (as the internal solver's); damp it while the
                    // residual grows.
                    let mut lambda = 1.0;
                    loop {
                        for i in 0..size {
                            x_try[i] = x[i] - lambda * dx[i];
                        }
                        let ok = res.eval(ode, &x_try, &mut r_new).is_ok();
                        let nrm_new = if ok { enorm(&r_new) } else { f64::INFINITY };
                        if nrm_new.is_finite() && (nrm_new < nrm || lambda <= 1.0 / 1024.0) {
                            x.copy_from_slice(&x_try);
                            r.copy_from_slice(&r_new);
                            nrm = nrm_new;
                            break;
                        }
                        lambda /= 2.0;
                        stale = true;
                        if lambda < 1e-10 {
                            break 'newton;
                        }
                    }
                    converged = nrm <= tol || self.scaled_norm(&r) <= tol;
                }
                if converged {
                    return Ok(Solved::Ok);
                }
            }
        }
        Ok(Solved::Failed)
    }

    /// C's `fvecScaled`: the residual against the Jacobian's row maxima.
    fn scaled_norm(&self, r: &[f64]) -> f64 {
        let size = self.size;
        let mut sum = 0.0;
        for i in 0..size {
            let mut row_max = 0.0f64;
            for c in 0..size {
                row_max = row_max.max(abs(self.jac[c * size + i]));
            }
            let v = if row_max > 0.0 { r[i] / row_max } else { r[i] };
            sum += v * v;
        }
        sqrt(sum)
    }
}

/// MINPACK's `enorm`, unscaled.
fn enorm(v: &[f64]) -> f64 {
    let mut sum = 0.0;
    for &x in v {
        sum += x * x;
    }
    sqrt(sum)
}

/// C's `DELTA_H` in `newtonIteration.c` (`sqrt(DBL_EPSILON)`).
const DELTA_H: f64 = 1.4901161193847656e-8;
