//! The birate (`-gbratio`) mode: C's `DATA_GBODEF`, `gbodef_main` and the `*_MR`
//! step functions of `gbode_step.c`, plus the slow-state cache of `gbode_util.c`
//! and the fast-state selection of `gbode_ctrl.c`.
//!
//! The outer integrator steps all states; the states whose scaled error exceeds 1
//! are then re-integrated over the same interval with their own method and step
//! size control, interpolating the accepted slow states in between. The inner
//! nonlinear systems are the fast-packed versions of the single-rate ones,
//! iterated with the same internal simplified Newton or the same generic damped
//! Newton over the fast×fast block of the ODE Jacobian. The inner FIRK system
//! stays the coupled `s*nFast` solve — small by construction of the fast-state
//! selection — where C routes it through the T-transformation code it shares
//! with the single-rate solve ([`super::nls`] has that for the outer systems).

use alloc::format;
use alloc::string::String;
use alloc::vec;
use alloc::vec::Vec;

use super::conf::{CtrlMethod, GbfConf, Interpolation, NlsMethod};
use super::tableau::{Estimator, GmType, SvpType, Tableau};
use super::{ctrl, interp, Gbode, GB_MINIMAL_STEP_SIZE, Solved};
use crate::gbode::math::{abs, pow, sqrt};
use crate::omclog;
use crate::{Ode, Result};

/// C's `DBL_ABSORPTION`.
const DBL_ABSORPTION: f64 = 10.0 * f64::EPSILON;
/// C's `numericalDifferentiationDeltaXsolver` (`sqrt(DBL_EPSILON)`).
const DELTA_X_SOLVER: f64 = 1.4901161193847656e-8;
/// C's `newtonFTol` default.
const NEWTON_FTOL_DEFAULT: f64 = 1e-12;
const NEWTON_MAX_STEPS: u32 = 20;

/// How far one `gbodef_main` call got.
pub(super) enum InnerStep {
    /// The inner integration reached the outer interval's right end (or the target).
    Done,
    /// An event was located at this time; `gbf.y_old`/`gb.y_old` hold its states.
    Event(f64),
}

/// The slow-state interpolation cache, C's `SLOW_STATE_CACHE`: one slot per stage
/// node plus the interval boundaries, invalidated on step size changes and rotated
/// so the right boundary carries over as the next step's left.
pub(super) struct SlowCache {
    n_stages: usize,
    states: Vec<f64>,
    valid: Vec<bool>,
    offset: usize,
    left_stage: usize,
    right_stage: usize,
}

impl SlowCache {
    fn new(n_stages: usize, n_states: usize, c: &[f64]) -> Self {
        let mut left_stage = n_stages;
        let mut right_stage = n_stages + 1;
        for (i, &ci) in c.iter().enumerate() {
            if ci == 0.0 {
                left_stage = i;
            }
            if ci == 1.0 {
                right_stage = i;
            }
        }
        SlowCache {
            n_stages,
            states: vec![0.0; (n_stages + 2) * n_states],
            valid: vec![false; n_stages + 2],
            offset: 0,
            left_stage,
            right_stage,
        }
    }

    fn slot(&self, i: usize) -> usize {
        (self.offset + i) % (self.n_stages + 2)
    }

    fn invalidate(&mut self) {
        self.valid.iter_mut().for_each(|v| *v = false);
        self.offset = 0;
    }

    fn invalidate_keep_left(&mut self) {
        let carry = self.valid[self.slot(self.left_stage)];
        self.valid.iter_mut().for_each(|v| *v = false);
        let s = self.slot(self.left_stage);
        self.valid[s] = carry;
    }

    /// Map the logical right node onto the logical left, keeping its data.
    fn rotate(&mut self) {
        let carry = self.valid[self.slot(self.right_stage)];
        let divisor = self.n_stages + 2;
        self.offset = (self.offset + self.right_stage + divisor - self.left_stage) % divisor;
        self.valid.iter_mut().for_each(|v| *v = false);
        let s = self.slot(self.left_stage);
        self.valid[s] = carry;
    }
}

/// The inner nonlinear solver over the fast-packed stage systems: the internal
/// simplified Newton (`gbInternalSolveNls_*` with `multirate`), or the generic
/// damped Newton of [`super::nls_generic`] specialized to the fast subset.
pub(super) struct GbfNls {
    internal: bool,
    sym_jac: bool,
    integrator_tol: f64,
    fnewt: f64,
    eta_initial_damping: f64,
    theta_keep: f64,
    theta_divergence: f64,
    max_newton_it: u32,
    firk_size: usize,
    etas: Vec<f64>,
    call_jac: bool,
    n_fast: usize,
    /// The fast×fast block of the ODE Jacobian, column-major `n_fast * n_fast`.
    j: Vec<f64>,
    lu: Vec<f64>,
    factored: Option<super::linsol::GbLu>,
    lu_step_size: f64,
    /// Coloring of the reduced (fast×fast) pattern, rebuilt on fast-set changes.
    colors: Vec<Vec<usize>>,
    colors_stale: bool,
    scal: Vec<f64>,
    fbase: Vec<f64>,
    ftol: f64,
    pub n_jac_evals: u64,
}

impl GbfNls {
    fn new(t: &Tableau, tol: f64, sym_jac: bool, internal: bool) -> Self {
        // C's Newton convergence target, as in `gbInternalNlsAllocate`.
        let alpha_default: f64 = 3e-2;
        let alpha_maximal: f64 = 5e-2;
        let safety_newt: f64 = 0.1;
        let mut target_alpha = alpha_default;
        if !t.richardson && t.error_order < t.order_b && t.order_b - t.error_order != 1 {
            let order_quot = (t.error_order as f64 + 1.0) / (t.order_b as f64 + 1.0);
            target_alpha = pow(safety_newt, 1.0 / order_quot);
        }
        let fnewt = (DBL_ABSORPTION / tol).max(alpha_maximal.min(target_alpha));
        let firk = t.gm_type == GmType::Implicit;
        GbfNls {
            internal,
            sym_jac,
            integrator_tol: tol,
            fnewt,
            eta_initial_damping: 0.8,
            theta_keep: 1e-3,
            theta_divergence: 0.99,
            max_newton_it: if firk { 4 + 2 * t.n_stages as u32 } else { 5 },
            firk_size: if firk { t.n_stages } else { 1 },
            etas: vec![f64::MAX; t.n_stages],
            call_jac: true,
            n_fast: 0,
            j: Vec::new(),
            lu: Vec::new(),
            factored: None,
            lu_step_size: 0.0,
            colors: Vec::new(),
            colors_stale: true,
            scal: Vec::new(),
            fbase: Vec::new(),
            ftol: crate::simflags::with_flags(|f| f.newton_ftol).unwrap_or(NEWTON_FTOL_DEFAULT),
            n_jac_evals: 0,
        }
    }

    /// C's `updateFastStates`: size the packed system for the new fast set and
    /// schedule the reduced pattern's recoloring.
    fn resize(&mut self, n_fast: usize) {
        self.n_fast = n_fast;
        let size = self.firk_size * n_fast;
        self.j = vec![0.0; n_fast * n_fast];
        self.lu = vec![0.0; size * size];
        self.factored = None;
        self.scal = vec![0.0; size];
        self.lu_step_size = 0.0;
        self.call_jac = true;
        self.colors_stale = true;
        for e in &mut self.etas {
            *e = f64::MAX;
        }
    }

    /// The reduced pattern's greedy coloring (C's `updateSparsePattern_GBODEF` +
    /// `colorSparsePattern`), and the `theta_keep` heuristic that reads its
    /// color count.
    fn update_colors(&mut self, ode: &dyn Ode, fast_idx: &[usize], n_states: usize) {
        let nf = self.n_fast;
        let full = ode.jac_rows_by_col();
        self.colors = if full.is_empty() {
            (0..nf).map(|c| vec![c]).collect()
        } else {
            let mut fast_pos = vec![usize::MAX; n_states];
            for (fi, &i) in fast_idx.iter().enumerate() {
                fast_pos[i] = fi;
            }
            let reduced: Vec<Vec<usize>> = fast_idx
                .iter()
                .map(|&c| {
                    full[c]
                        .iter()
                        .filter_map(|&r| {
                            let p = fast_pos[r as usize];
                            (p != usize::MAX).then_some(p)
                        })
                        .collect()
                })
                .collect();
            super::linsol::color_columns(&reduced, nf)
        };
        self.theta_keep = if nf > 8 {
            pow(
                10.0,
                -3.0 + 1.75 * crate::gbode::math::ln(1.0 + self.colors.len() as f64)
                    / crate::gbode::math::ln(1.0 + nf as f64),
            )
        } else {
            1e-3
        };
        self.colors_stale = false;
    }

    pub(super) fn invalidate(&mut self) {
        self.call_jac = true;
        self.lu_step_size = 0.0;
        self.factored = None;
        for e in &mut self.etas {
            *e = f64::MAX;
        }
    }

    /// `gamma/h*I - J_ff` factorized, for the contractive estimators.
    fn contract_factor(&mut self, g: f64) -> Result<super::linsol::GbLu> {
        let nf = self.n_fast;
        for c in 0..nf {
            for r in 0..nf {
                self.lu[c * nf + r] = -self.j[c * nf + r];
            }
            self.lu[c * nf + c] += g;
        }
        super::linsol::factor(&self.lu[..nf * nf], nf)
    }

    /// The fast×fast ODE Jacobian at `(time, y_full)` — C's
    /// `gbInternal_evalJacobianMR` (symbolic seeds on the fast columns) /
    /// `gbInternal_evalNumericalJacobian` with the fast state map. Perturbs one
    /// fast column at a time; C colors the reduced pattern, which changes the
    /// evaluation count only.
    #[allow(clippy::too_many_arguments)]
    fn eval_jacobian(
        &mut self,
        ode: &mut dyn Ode,
        time: f64,
        y_full: &[f64],
        fast_idx: &[usize],
        nominals: &[f64],
    ) -> Result<()> {
        let nf = self.n_fast;
        let n = y_full.len();
        self.n_jac_evals += 1;
        self.lu_step_size = 0.0;
        self.fbase.resize(n, 0.0);
        if self.colors_stale {
            self.update_colors(ode, fast_idx, n);
        }
        let colors = self.colors.clone();
        if self.sym_jac && ode.has_jacobian_vector() {
            ode.eval(time, y_full, &mut self.fbase)?;
            let mut seed = vec![0.0; n];
            let mut out = vec![0.0; n];
            for group in &colors {
                seed.fill(0.0);
                for &cf in group {
                    seed[fast_idx[cf]] = 1.0;
                }
                if !ode.jacobian_vector(time, y_full, &seed, &mut out) {
                    return Err(
                        "CodegenWasmJit: gbode: the model could not multiply by its Jacobian",
                    );
                }
                for &cf in group {
                    for (rf, &r) in fast_idx.iter().enumerate() {
                        self.j[cf * nf + rf] = out[r];
                    }
                }
            }
            return Ok(());
        }
        let maxs: Vec<f64> = ode.maxs().to_vec();
        let tol = self.integrator_tol;
        ode.set_context_jacobian();
        let run = (|| -> Result<()> {
            ode.eval(time, y_full, &mut self.fbase)?;
            let mut probe = y_full.to_vec();
            let mut fp = vec![0.0; n];
            let mut inv_del = vec![0.0; nf];
            for group in &colors {
                for &cf in group {
                    let c = fast_idx[cf];
                    let nominal = nominals.get(c).copied().unwrap_or(1.0);
                    let raw_weight = tol * nominal + tol * abs(y_full[c]);
                    let mut del = DELTA_X_SOLVER
                        * abs(y_full[c])
                            .max(1e-3)
                            .max(abs(DELTA_X_SOLVER * self.fbase[c]))
                            .max(abs(raw_weight));
                    del = y_full[c] + del - y_full[c];
                    if maxs.get(c).is_some_and(|&mx| y_full[c] + del >= mx) {
                        del = -del;
                    }
                    inv_del[cf] = 1.0 / del;
                    probe[c] = y_full[c] + del;
                }
                ode.eval(time, &probe, &mut fp)?;
                for &cf in group {
                    let c = fast_idx[cf];
                    for (rf, &r) in fast_idx.iter().enumerate() {
                        self.j[cf * nf + rf] = (fp[r] - self.fbase[r]) * inv_del[cf];
                    }
                    probe[c] = y_full[c];
                }
            }
            Ok(())
        })();
        ode.set_context_algebraic();
        run
    }

    /// C's `createGbScales` over the fast subset.
    fn make_scales(&mut self, nominals: &[f64], fast_idx: &[usize], y1: &[f64], y2: &[f64]) {
        let tol = self.integrator_tol;
        let size = self.scal.len();
        for i in 0..size {
            let nom = nominals[fast_idx[i % self.n_fast]];
            self.scal[i] = 1.0 / (tol * nom + abs(y1[i]).max(abs(y2[i])) * tol);
        }
    }

    fn scaled_norm(&self, v: &[f64]) -> f64 {
        let mut sum = 0.0;
        for (i, x) in v.iter().enumerate() {
            let t = x * self.scal[i];
            sum += t * t;
        }
        sqrt(sum / v.len() as f64)
    }

}

/// One packed stage system: everything a solve over the fast states needs to
/// compose the full state vector the model evaluates on.
pub(super) struct MrStage<'a> {
    pub stage_time: f64,
    pub fac: f64,
    pub c_scale: f64,
    /// `res_const` over the full indices.
    pub res_const: &'a [f64],
    /// Full state vector with the slow states interpolated at `stage_time`.
    pub base_full: &'a mut [f64],
    pub fast_idx: &'a [usize],
}

impl MrStage<'_> {
    /// `res = res_const - c_scale*x + fac*f` over the fast entries; `f_full`
    /// receives the full derivative vector of the last evaluation.
    fn residual(
        &mut self,
        ode: &mut dyn Ode,
        x: &[f64],
        res: &mut [f64],
        f_full: &mut [f64],
    ) -> Result<()> {
        for (i, &fi) in self.fast_idx.iter().enumerate() {
            self.base_full[fi] = x[i];
        }
        ode.eval(self.stage_time, self.base_full, f_full)?;
        for (i, &fi) in self.fast_idx.iter().enumerate() {
            res[i] = self.res_const[fi] - self.c_scale * x[i] + self.fac * f_full[fi];
        }
        Ok(())
    }
}

impl GbfNls {
    /// Solve one packed DIRK stage (or the multi-step corrector): the internal
    /// simplified Newton over `fac*J_ff - c_scale*I`, or the generic damped
    /// Newton. `x` starts at the primary guess; `starts` are the retries the
    /// generic solver falls back to. `f_full` holds the derivatives at the
    /// accepted iterate on success.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn solve_stage(
        &mut self,
        ode: &mut dyn Ode,
        stage: usize,
        st: &mut MrStage<'_>,
        step_size: f64,
        jac_at: (f64, &[f64]),
        first_implicit: bool,
        event_happened: bool,
        nominals: &[f64],
        starts: &[&[f64]],
        x: &mut [f64],
        f_full: &mut [f64],
    ) -> Result<Solved> {
        let nf = self.n_fast;
        if !self.internal {
            return self.solve_stage_generic(ode, st, nominals, starts, x, f_full);
        }
        let x_start = x.to_vec();
        self.make_scales(nominals, st.fast_idx, x, &x_start);
        if first_implicit {
            let mut jac_called = false;
            if self.call_jac || event_happened {
                self.eval_jacobian(ode, jac_at.0, jac_at.1, st.fast_idx, nominals)?;
                jac_called = true;
            }
            if jac_called || step_size != self.lu_step_size {
                // `fac*J_ff - c_scale*I`, as the internal single-rate system.
                for c in 0..nf {
                    for r in 0..nf {
                        self.lu[c * nf + r] = st.fac * self.j[c * nf + r];
                    }
                    self.lu[c * nf + c] -= st.c_scale;
                }
                self.factored = Some(super::linsol::factor(&self.lu, nf)?);
                self.lu_step_size = step_size;
            }
        }
        if event_happened {
            self.etas[stage] = f64::MAX;
        }
        let mut res = vec![0.0; nf];
        let mut nrm_delta = 0.0;
        let mut theta = 0.0;
        let mut newt_it = 1;
        loop {
            st.residual(ode, x, &mut res, f_full)?;
            self.factored.as_mut().expect("solve before factor").solve(&mut res);
            for i in 0..nf {
                x[i] -= res[i];
            }
            let nrm_delta_prev = f64::EPSILON.max(nrm_delta);
            nrm_delta = self.scaled_norm(&res);
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

    /// The generic damped Newton over one packed stage, C's `solveNLS_gb` with
    /// `-gbnls=newton`/`kinsol` on `residual_DIRK_MR`/`residual_MS_MR`.
    fn solve_stage_generic(
        &mut self,
        ode: &mut dyn Ode,
        st: &mut MrStage<'_>,
        nominals: &[f64],
        starts: &[&[f64]],
        x: &mut [f64],
        f_full: &mut [f64],
    ) -> Result<Solved> {
        let nf = self.n_fast;
        let mut attempts: Vec<Vec<f64>> = starts.iter().map(|s| s.to_vec()).collect();
        if let Some(base) = starts.last() {
            let mut v = base.to_vec();
            for i in 0..nf {
                v[i] += nominals[st.fast_idx[i]] * 0.01;
            }
            attempts.push(v);
            attempts.push(st.fast_idx.iter().map(|&i| nominals[i]).collect());
        }
        let mut r = vec![0.0; nf];
        let mut r_new = vec![0.0; nf];
        let mut x_try = vec![0.0; nf];
        for relax in 0..5 {
            let tol = self.ftol * pow(10.0, relax as f64);
            for start in &attempts {
                x.copy_from_slice(start);
                if st.residual(ode, x, &mut r, f_full).is_err() {
                    continue;
                }
                let mut nrm = enorm(&r);
                if !nrm.is_finite() {
                    continue;
                }
                let mut factored = self
                    .assemble_generic(ode, st, nominals, x)
                    .is_ok();
                if !factored {
                    continue;
                }
                let mut converged = nrm <= tol;
                let mut stale = false;
                'newton: for _ in 0..NEWTON_MAX_STEPS {
                    if converged {
                        break;
                    }
                    if stale {
                        factored = self.assemble_generic(ode, st, nominals, x).is_ok();
                        if !factored {
                            break 'newton;
                        }
                        stale = false;
                    }
                    let mut dx = r.clone();
                    self.factored.as_mut().expect("solve before factor").solve(&mut dx);
                    let mut lambda = 1.0;
                    loop {
                        for i in 0..nf {
                            x_try[i] = x[i] - lambda * dx[i];
                        }
                        let ok = st.residual(ode, &x_try, &mut r_new, f_full).is_ok();
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
                    converged = nrm <= tol;
                }
                if converged {
                    // Leave `f_full` at the accepted iterate.
                    st.residual(ode, x, &mut r, f_full)?;
                    return Ok(Solved::Ok);
                }
            }
        }
        Ok(Solved::Failed)
    }

    fn assemble_generic(
        &mut self,
        ode: &mut dyn Ode,
        st: &mut MrStage<'_>,
        nominals: &[f64],
        x: &[f64],
    ) -> Result<()> {
        let nf = self.n_fast;
        for (i, &fi) in st.fast_idx.iter().enumerate() {
            st.base_full[fi] = x[i];
        }
        let base = st.base_full.to_vec();
        self.eval_jacobian(ode, st.stage_time, &base, st.fast_idx, nominals)?;
        for c in 0..nf {
            for r in 0..nf {
                self.lu[c * nf + r] = st.fac * self.j[c * nf + r];
            }
            self.lu[c * nf + c] -= st.c_scale;
        }
        self.factored = Some(super::linsol::factor(&self.lu, nf)?);
        Ok(())
    }

    /// The inner FIRK solve, one coupled `s*nFast` simplified Newton (C routes it
    /// through the T-transform code shared with the single-rate solve; the system
    /// here is small by construction of the fast-state selection). `stage_fulls`
    /// hold the full states per stage with the slow parts interpolated; `z`/`k`
    /// are fast-packed per stage.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn solve_firk(
        &mut self,
        ode: &mut dyn Ode,
        t: &Tableau,
        time: f64,
        step_size: f64,
        y_old_full: &[f64],
        y_old_packed: &[f64],
        fast_idx: &[usize],
        stage_fulls: &mut [Vec<f64>],
        z: &mut [f64],
        k: &mut [f64],
        event_happened: bool,
        nominals: &[f64],
    ) -> Result<Solved> {
        let nf = self.n_fast;
        let s = t.n_stages;
        let size = s * nf;
        let z_start: Vec<f64> = z.to_vec();
        self.make_scales(nominals, fast_idx, z, &z_start);
        let mut jac_called = false;
        if self.call_jac || event_happened {
            self.eval_jacobian(ode, time, y_old_full, fast_idx, nominals)?;
            jac_called = true;
        }
        if jac_called || step_size != self.lu_step_size {
            self.lu.iter_mut().for_each(|v| *v = 0.0);
            for bi in 0..s {
                for bj in 0..s {
                    let f = step_size * t.a_at(bi, bj);
                    if f == 0.0 {
                        continue;
                    }
                    for c in 0..nf {
                        for r in 0..nf {
                            self.lu[(bj * nf + c) * size + bi * nf + r] += f * self.j[c * nf + r];
                        }
                    }
                }
            }
            for i in 0..size {
                self.lu[i * size + i] -= 1.0;
            }
            self.factored = Some(super::linsol::factor(&self.lu, size)?);
            self.lu_step_size = step_size;
        }
        if event_happened {
            for e in &mut self.etas {
                *e = f64::MAX;
            }
        }
        let n = y_old_full.len();
        let mut res = vec![0.0; size];
        let mut f = vec![0.0; n];
        let mut nrm_delta = 0.0;
        let mut theta = 0.0;
        let mut newt_it = 1;
        loop {
            for stage in 0..s {
                let st = time + t.c[stage] * step_size;
                let full = &mut stage_fulls[stage];
                for (i, &fi) in fast_idx.iter().enumerate() {
                    full[fi] = z[stage * nf + i];
                }
                ode.eval(st, full, &mut f)?;
                for (i, &fi) in fast_idx.iter().enumerate() {
                    k[stage * nf + i] = f[fi];
                }
            }
            for stage in 0..s {
                for i in 0..nf {
                    let mut r = y_old_packed[i] - z[stage * nf + i];
                    for j in 0..s {
                        r += step_size * t.a_at(stage, j) * k[j * nf + i];
                    }
                    res[stage * nf + i] = r;
                }
            }
            self.factored.as_mut().expect("solve before factor").solve(&mut res);
            for i in 0..size {
                z[i] -= res[i];
            }
            let nrm_delta_prev = f64::EPSILON.max(nrm_delta);
            nrm_delta = self.scaled_norm(&res);
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
                self.reconstruct_k(t, step_size, y_old_packed, z, k);
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

    /// `K = 1/h * (A_part⁻¹ ⊗ I) * Z` over the packed vectors, as the single-rate
    /// solver rebuilds the derivatives from the converged stage values. A tableau
    /// with explicit first/last stages keeps the iterate's `f(Z)` instead.
    fn reconstruct_k(
        &mut self,
        t: &Tableau,
        step_size: f64,
        y_old_packed: &[f64],
        z: &[f64],
        k: &mut [f64],
    ) {
        let nf = self.n_fast;
        let Some(tr) = t.t_transform.as_ref() else { return };
        if tr.first_row_zero || tr.last_column_zero {
            return;
        }
        let sr = tr.size;
        let inv_h = 1.0 / step_size;
        let mut out = vec![0.0; sr * nf];
        for j in 0..sr {
            for i in 0..nf {
                let mut acc = 0.0;
                for l in 0..sr {
                    acc += tr.a_part_inv[j * sr + l] * (z[l * nf + i] - y_old_packed[i]);
                }
                out[j * nf + i] = acc * inv_h;
            }
        }
        k[..sr * nf].copy_from_slice(&out);
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

/// C's `DATA_GBODEF`: the fast-states (inner) integrator.
pub(super) struct GbodeF {
    pub conf: GbfConf,
    pub tableau: Tableau,
    pub two_step_fallback: Option<Estimator>,
    pub nls: Option<GbfNls>,
    pub is_explicit: bool,
    pub current_error_order: i32,

    pub time: f64,
    pub time_left: f64,
    pub time_right: f64,
    pub step_size: f64,
    pub last_step_size: f64,
    pub extrapolation_base_time: f64,
    pub extrapolation_step_size: f64,
    pub extrapolation_valid: bool,
    pub did_event_step: bool,

    pub y: Vec<f64>,
    pub y_old: Vec<f64>,
    pub yt: Vec<f64>,
    pub y_left: Vec<f64>,
    pub k_left: Vec<f64>,
    pub y_right: Vec<f64>,
    pub k_right: Vec<f64>,
    /// Fast-packed: `y_last` `nFast`, `k_last`/`k_curr_packed` `nStages * nFast`.
    pub y_last: Vec<f64>,
    pub k_last: Vec<f64>,
    pub y_old_packed: Vec<f64>,
    pub k_curr_packed: Vec<f64>,
    pub k: Vec<f64>,
    pub x: Vec<f64>,
    pub res_const: Vec<f64>,
    pub errest: Vec<f64>,
    pub errtol: Vec<f64>,
    pub err: Vec<f64>,
    pub err_values: Vec<f64>,
    pub step_size_values: Vec<f64>,
    pub tv: Vec<f64>,
    pub yv: Vec<f64>,
    pub kv: Vec<f64>,
    pub b_dt: Vec<f64>,
    pub cache: SlowCache,
    /// The fast-state set the NLS sizing was last built for.
    pub fast_states_old: Vec<usize>,

    pub steps: u64,
    pub err_test_failures: u64,
    pub convergence_test_failures: u64,
    pub fast_state_update_count: u64,
}

impl GbodeF {
    /// C's `gbodef_allocateData`.
    pub(super) fn new(
        gb_conf: &super::GbConf,
        n_states: usize,
        tol: f64,
        sym_jac: bool,
    ) -> core::result::Result<Self, String> {
        let conf = gb_conf.fast_conf(|m| {
            let (t, _) = super::tableau::init(m, super::tableau::ErrMethod::Default, 1);
            t.gm_type == GmType::Implicit
        })?;
        let (mut t, _size) = super::tableau::init(conf.method, conf.err_method, n_states);
        let is_explicit = t.gm_type == GmType::Explicit;
        if t.gm_type == GmType::Implicit && conf.nls_method != NlsMethod::Internal {
            return Err(String::from(
                "Unsupported configuration: fully implicit Runge-Kutta multirate integration is \
                 only available with -gbnls=internal.",
            ));
        }
        let internal = conf.nls_method == NlsMethod::Internal;
        let two_step_fallback =
            super::tableau::finalize_error(&mut t, internal).map_err(String::from)?;
        omclog::info(
            omclog::SOLVER,
            false,
            &format!("Step control factor is set to {}", omclog::g(t.fac, 0, 6)),
        );
        let nls = (!is_explicit).then(|| GbfNls::new(&t, tol, sym_jac, internal));
        // C demotes dense output to Hermite when the method has no formula.
        let interpolation = match (conf.interpolation, t.with_dense_output) {
            (Interpolation::DenseOutput, false) => Interpolation::Hermite,
            (other, _) => other,
        };
        omclog::info(
            omclog::SOLVER,
            false,
            match interpolation {
                Interpolation::Lin => "Linear interpolation is used for emitting results",
                Interpolation::DenseOutput | Interpolation::DenseOutputErrCtrl => {
                    "Dense output is used for emitting results"
                }
                _ => "Hermite interpolation is used for the slow states",
            },
        );
        let n_stages = t.n_stages;
        let ring = 4usize;
        let current_error_order = t.error_order;
        let cache = SlowCache::new(n_stages, n_states, &t.c);
        let mut conf = conf;
        conf.interpolation = interpolation;
        Ok(GbodeF {
            conf,
            two_step_fallback,
            nls,
            is_explicit,
            current_error_order,
            time: 0.0,
            time_left: 0.0,
            time_right: 0.0,
            step_size: 0.0,
            last_step_size: 0.0,
            extrapolation_base_time: f64::INFINITY,
            extrapolation_step_size: 0.0,
            extrapolation_valid: false,
            did_event_step: false,
            y: vec![0.0; n_states],
            y_old: vec![0.0; n_states],
            yt: vec![0.0; n_states],
            y_left: vec![0.0; n_states],
            k_left: vec![0.0; n_states],
            y_right: vec![0.0; n_states],
            k_right: vec![0.0; n_states],
            y_last: vec![0.0; n_states],
            k_last: vec![0.0; n_states * n_stages],
            y_old_packed: vec![0.0; n_states],
            k_curr_packed: vec![0.0; n_states * n_stages],
            k: vec![0.0; n_states * n_stages],
            x: vec![0.0; n_states * n_stages],
            res_const: vec![0.0; n_states],
            errest: vec![0.0; n_states],
            errtol: vec![0.0; n_states],
            err: vec![0.0; n_states],
            err_values: vec![0.0; ring],
            step_size_values: vec![0.0; ring],
            tv: vec![0.0; ring],
            yv: vec![0.0; n_states * ring],
            kv: vec![0.0; n_states * ring],
            b_dt: vec![0.0; n_stages],
            cache,
            // Empty so the first inner call always sizes the NLS for its fast set.
            fast_states_old: Vec::new(),
            steps: 0,
            err_test_failures: 0,
            convergence_test_failures: 0,
            fast_state_update_count: 0,
            tableau: t,
        })
    }
}

impl Gbode {
    /// C's `getErrorThreshold`: the `(1 - percentage)` quantile of the per-state
    /// errors by quickselect over `sorted_states_idx`.
    pub(super) fn error_threshold(&mut self) -> f64 {
        if self.percentage >= 1.0 {
            return -1.0;
        }
        let length = self.n_states;
        let last = length - 1;
        let mut target =
            last as isize - libm::round(length as f64 * self.percentage) as isize;
        if target < 0 {
            target = 0;
        }
        let target = (target as usize).min(last);
        let idx = &mut self.sorted_states_idx;
        let err = &self.err;
        let mut left = 0usize;
        let mut right = last;
        while left < right {
            let split = partition(idx, err, left, right);
            if target <= split {
                right = split;
            } else {
                left = split + 1;
            }
        }
        self.err[self.sorted_states_idx[target]]
    }

    /// C's `checkFastStatesChange`.
    fn fast_states_changed(&mut self) -> bool {
        let gbf = self.gbf.as_mut().expect("multirate without gbf");
        let changed = self.fast_states_idx[..self.n_fast] != gbf.fast_states_old[..];
        if changed {
            gbf.fast_states_old = self.fast_states_idx[..self.n_fast].to_vec();
        }
        changed
    }

    /// C's `slowStateCache_interpolate_slow_to_fast_node`: interpolate the slow
    /// states of the outer interval onto `time_value`, writing the slow entries of
    /// `out`.
    fn slow_interp_at(&mut self, time_value: f64, out: &mut [f64]) {
        let n = self.n_states;
        let gbf = self.gbf.as_ref().expect("multirate without gbf");
        interp::interpolate(
            gbf.conf.interpolation,
            self.time_left,
            &self.y_left,
            &self.k_left,
            self.time_right,
            &self.y_right,
            &self.k_right,
            time_value,
            out,
            Some(&self.slow_states_idx[..self.n_slow]),
            n,
            &self.tableau,
            &mut self.b_dt,
            &self.k,
        );
    }

    /// The cache lookup C's `slowStateCache_overwrite_*` / `merge_*` share: the
    /// interpolant for a node, computed at most once, with its slow entries
    /// written into `x` (the port always writes the slow subset, so overwrite and
    /// merge coincide).
    fn slow_cache_apply(&mut self, node: SlowNode, x: &mut [f64]) {
        let n = self.n_states;
        let (t, slot, valid) = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            let (logical, t) = match node {
                SlowNode::Left => (gbf.cache.left_stage, gbf.time),
                SlowNode::Right => (gbf.cache.right_stage, gbf.time + gbf.step_size),
                SlowNode::Stage(stage) => {
                    (stage, gbf.time + gbf.tableau.c[stage] * gbf.step_size)
                }
            };
            let slot = gbf.cache.slot(logical);
            (t, slot, gbf.cache.valid[slot])
        };
        if !valid {
            let mut buf = vec![0.0; n];
            self.slow_interp_at(t, &mut buf);
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            gbf.cache.states[slot * n..(slot + 1) * n].copy_from_slice(&buf);
            gbf.cache.valid[slot] = true;
        }
        let gbf = self.gbf.as_ref().expect("multirate without gbf");
        let interp = &gbf.cache.states[slot * n..(slot + 1) * n];
        for &i in &self.slow_states_idx[..self.n_slow] {
            x[i] = interp[i];
        }
    }

    /// C's `gbodef_init`.
    fn gbodef_init(&mut self) {
        let n = self.n_states;
        let err = [self.err_fast, 0.0];
        let steps = [self.step_size, 0.0];
        let factor = ctrl::generic_controller_with(
            &err,
            &steps,
            1,
            CtrlMethod::I,
            self.conf.ctrl_filter,
            self.conf.fhr,
        );
        let gbf = self.gbf.as_mut().expect("multirate without gbf");
        gbf.did_event_step = false;
        gbf.extrapolation_base_time = f64::INFINITY;
        gbf.extrapolation_valid = false;
        gbf.cache.invalidate();
        gbf.time = self.time;
        gbf.step_size = 0.1 * self.step_size * factor;
        gbf.y_old.copy_from_slice(&self.y_old);
        gbf.y.copy_from_slice(&self.y);
        gbf.time_right = self.time_left;
        gbf.y_right.copy_from_slice(&self.y_left);
        gbf.k_right.copy_from_slice(&self.k_left);
        for i in 0..self.ring_buffer_size {
            gbf.tv[i] = self.tv[i];
            gbf.yv[i * n..(i + 1) * n].copy_from_slice(&self.yv[i * n..(i + 1) * n]);
            gbf.kv[i * n..(i + 1) * n].copy_from_slice(&self.kv[i * n..(i + 1) * n]);
        }
    }

    /// C's `extrapolation_gbf`: the fast states' guess at `time` off the inner
    /// ring buffer.
    fn extrapolate_gbf(&mut self, out: &mut [f64], time: f64) {
        let n = self.n_states;
        let gbf = self.gbf.as_ref().expect("multirate without gbf");
        let fast = &self.fast_states_idx[..self.n_fast];
        if abs(gbf.tv[1] - gbf.tv[0]) <= interp::GBODE_EPSILON {
            let dt = time - gbf.tv[0];
            for &i in fast {
                out[i] = gbf.yv[i] + dt * gbf.kv[i];
            }
        } else {
            interp::hermite(
                gbf.tv[1],
                &gbf.yv[n..2 * n],
                &gbf.kv[n..2 * n],
                gbf.tv[0],
                &gbf.yv[..n],
                &gbf.kv[..n],
                time,
                out,
                Some(fast),
                n,
            );
        }
    }

    /// One inner (fast-states) integration burst — C's `gbodef_main`.
    pub(super) fn gbodef_main(
        &mut self,
        ode: &mut dyn Ode,
        target_time: f64,
    ) -> Result<InnerStep> {
        let n = self.n_states;
        let stop_time = self.stop_time;
        let inner_target = target_time.min(self.time_right);

        {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            if gbf.did_event_step || gbf.time_right < self.time_left {
                self.gbodef_init();
            }
        }
        let fast_changed = self.fast_states_changed();
        if fast_changed {
            let n_fast = self.n_fast;
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            gbf.extrapolation_valid = false;
            gbf.fast_state_update_count += 1;
            gbf.cache.invalidate();
            if let Some(nls) = gbf.nls.as_mut() {
                nls.resize(n_fast);
            }
        }

        loop {
            {
                let gbf = self.gbf.as_ref().expect("multirate without gbf");
                if gbf.time >= inner_target {
                    break;
                }
            }
            {
                let time_right = self.time_right;
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                if gbf.time + gbf.step_size > stop_time {
                    gbf.step_size = stop_time - gbf.time;
                }
                if gbf.time + gbf.step_size > time_right {
                    gbf.step_size = time_right - gbf.time;
                }
                gbf.time_left = gbf.time_right;
                let y_right = gbf.y_right.clone();
                let k_right = gbf.k_right.clone();
                gbf.y_left.copy_from_slice(&y_right);
                gbf.k_left.copy_from_slice(&k_right);
            }

            let mut err;
            loop {
                let stepped = self.gbodef_step(ode)?;
                if !stepped {
                    let gbf = self.gbf.as_mut().expect("multirate without gbf");
                    gbf.convergence_test_failures += 1;
                    gbf.step_size *= 0.5;
                    if gbf.step_size < GB_MINIMAL_STEP_SIZE {
                        return Err(super::step::GBODE_MIN_STEP_ERROR);
                    }
                    gbf.cache.invalidate_keep_left();
                    continue;
                }
                // The scaled 2-norm over the fast states only.
                let tol = self.scaled_error_tolerance_gbf();
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                err = 0.0;
                let richardson_like = gbf.tableau.richardson
                    || gbf.tableau.gm_type == GmType::MultiStep;
                for fi in 0..self.n_fast {
                    let i = self.fast_states_idx[fi];
                    gbf.errtol[i] = tol * self.nominals[i]
                        + abs(gbf.y_old[i]).max(abs(gbf.y[i])) * tol;
                    if richardson_like {
                        gbf.errest[i] = abs(gbf.yt[i]);
                    }
                    gbf.err[i] = gbf.tableau.fac * gbf.errest[i] / gbf.errtol[i];
                    err += gbf.err[i] * gbf.err[i];
                }
                err = sqrt(err / self.n_fast.max(1) as f64);
                if err > 1.0 {
                    gbf.err_test_failures += 1;
                    gbf.step_size *= 0.5;
                    if gbf.step_size < GB_MINIMAL_STEP_SIZE {
                        return Err(super::step::GBODE_MIN_STEP_ERROR);
                    }
                    gbf.cache.invalidate_keep_left();
                    omclog::info(
                        omclog::SOLVER,
                        false,
                        &format!(
                            "Reject step from {} to {}, error {}, new stepsize {}",
                            omclog::g(gbf.time, 0, 6),
                            omclog::g(gbf.time + gbf.last_step_size, 0, 6),
                            omclog::g(err, 0, 6),
                            omclog::g(gbf.step_size, 0, 6)
                        ),
                    );
                    continue;
                }
                break;
            }

            // Accepted: extrapolation data, packed history, boundaries, rings.
            {
                let n_fast = self.n_fast;
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                gbf.extrapolation_base_time = gbf.time;
                gbf.extrapolation_step_size = gbf.step_size;
                gbf.extrapolation_valid = true;
                for fi in 0..n_fast {
                    let i = self.fast_states_idx[fi];
                    gbf.y_last[fi] = gbf.y_old[i];
                }
                let n_stages = gbf.tableau.n_stages;
                for stage in 0..n_stages {
                    for fi in 0..n_fast {
                        let i = self.fast_states_idx[fi];
                        gbf.k_last[stage * n_fast + fi] = gbf.k[stage * n + i];
                    }
                }
                gbf.steps += 1;
            }
            self.did_fast_step = true;

            // Slow states of `yOld` and `y` from the cache (C's merges), then the
            // right-boundary bookkeeping.
            {
                let mut y_old = {
                    let gbf = self.gbf.as_ref().expect("multirate without gbf");
                    gbf.y_old.clone()
                };
                self.slow_cache_apply(SlowNode::Left, &mut y_old);
                let mut y = {
                    let gbf = self.gbf.as_ref().expect("multirate without gbf");
                    gbf.y.clone()
                };
                self.slow_cache_apply(SlowNode::Right, &mut y);
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                gbf.y_old.copy_from_slice(&y_old);
                gbf.y.copy_from_slice(&y);
                gbf.cache.rotate();
                gbf.time_right = gbf.time + gbf.step_size;
                let yy = gbf.y.clone();
                gbf.y_right.copy_from_slice(&yy);
            }
            {
                // kRight: the full derivative at the right boundary.
                let (t_right, y_right) = {
                    let gbf = self.gbf.as_ref().expect("multirate without gbf");
                    (gbf.time_right, gbf.y_right.clone())
                };
                let mut f = vec![0.0; n];
                ode.eval(t_right, &y_right, &mut f)?;
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                gbf.k_right.copy_from_slice(&f);
            }

            // Events over the inner step, bisected on the inner interpolant.
            if let Some(event_time) = self.check_for_events_gbf(ode)? {
                let mut y_ev = vec![0.0; n];
                self.interpolate_gbf_all(event_time, &mut y_ev);
                self.event_happened = true;
                self.time = event_time;
                self.y_old.copy_from_slice(&y_ev);
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                gbf.time = event_time;
                gbf.y_old.copy_from_slice(&y_ev);
                return Ok(InnerStep::Event(event_time));
            }

            {
                let err_now = err;
                self.err_fast = err_now;
                let ring = self.ring_buffer_size;
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                for i in (1..ring).rev() {
                    gbf.err_values[i] = gbf.err_values[i - 1];
                    gbf.step_size_values[i] = gbf.step_size_values[i - 1];
                }
                gbf.err_values[0] = err_now;
                gbf.step_size_values[0] = gbf.step_size;
                gbf.time += gbf.step_size;
                gbf.last_step_size = gbf.step_size;
                gbf.step_size *= ctrl::generic_controller_with(
                    &gbf.err_values,
                    &gbf.step_size_values,
                    gbf.current_error_order,
                    gbf.conf.ctrl_method,
                    self.conf.ctrl_filter,
                    self.conf.fhr,
                );
                for i in (1..ring).rev() {
                    gbf.tv[i] = gbf.tv[i - 1];
                    let (dst, src) = (i * n, (i - 1) * n);
                    gbf.yv.copy_within(src..src + n, dst);
                    gbf.kv.copy_within(src..src + n, dst);
                }
                gbf.tv[0] = gbf.time_right;
                let yr = gbf.y_right.clone();
                let kr = gbf.k_right.clone();
                gbf.yv[..n].copy_from_slice(&yr);
                gbf.kv[..n].copy_from_slice(&kr);
                let y = gbf.y.clone();
                gbf.y_old.copy_from_slice(&y);
                omclog::info(
                    omclog::SOLVER,
                    false,
                    &format!(
                        "Accept step from {} to {}, error {}, new stepsize {}",
                        omclog::g(gbf.time - gbf.last_step_size, 0, 6),
                        omclog::g(gbf.time, 0, 6),
                        omclog::g(err_now, 0, 6),
                        omclog::g(gbf.step_size, 0, 6)
                    ),
                );
            }

            let done = {
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                if (self.time_right - gbf.time) < GB_MINIMAL_STEP_SIZE
                    || self.step_size < GB_MINIMAL_STEP_SIZE
                {
                    gbf.time = self.time_right;
                    true
                } else {
                    false
                }
            };
            if done {
                break;
            }
        }

        // C refreshes the two newest ring entries' slow derivatives with full ODE
        // evaluations, so later extrapolations see current slow data.
        for i in 0..2 {
            let (t, y) = {
                let gbf = self.gbf.as_ref().expect("multirate without gbf");
                (gbf.tv[i], gbf.yv[i * n..(i + 1) * n].to_vec())
            };
            let mut f = vec![0.0; n];
            ode.eval(t, &y, &mut f)?;
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            for si in 0..self.n_slow {
                let j = self.slow_states_idx[si];
                gbf.kv[i * n + j] = f[j];
            }
        }
        Ok(InnerStep::Done)
    }

    /// `gbScaledErrorTolerance` with the inner method's orders.
    fn scaled_error_tolerance_gbf(&self) -> f64 {
        let gbf = self.gbf.as_ref().expect("multirate without gbf");
        let tol = self.tol;
        let (method_order, estimator_order) =
            (gbf.tableau.order_b, gbf.current_error_order);
        if gbf.tableau.richardson || estimator_order >= method_order {
            return tol;
        }
        let order_quot = (estimator_order as f64 + 1.0) / (method_order as f64 + 1.0);
        tol.max(super::GB_TOLERANCE_SCALING_SAFETY * pow(tol, order_quot))
    }

    /// One inner step attempt: C's `gbfData->step_fun` or `gbodef_richardson`.
    fn gbodef_step(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        let richardson = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            gbf.tableau.richardson
        };
        if richardson {
            self.gbodef_richardson(ode)
        } else {
            self.gbodef_dispatch(ode)
        }
    }

    fn gbodef_dispatch(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        let ty = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            gbf.tableau.gm_type
        };
        match ty {
            GmType::Explicit | GmType::Dirk => self.step_expl_diag_impl_mr(ode),
            GmType::Implicit => self.step_full_implicit_mr(ode),
            GmType::MultiStep => self.step_full_implicit_ms_mr(ode),
        }
    }

    /// C's `gbodef_richardson`.
    fn gbodef_richardson(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        let n = self.n_states;
        let (time_value, step_size, last_step_size, p, is_explicit) = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            (gbf.time, gbf.step_size, gbf.last_step_size, gbf.tableau.order_b, gbf.is_explicit)
        };
        let (mut tr, mut yr, mut kr) = ([0.0; 2], vec![0.0; 2 * n], vec![0.0; 2 * n]);
        if !is_explicit {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            tr.copy_from_slice(&gbf.tv[..2]);
            yr.copy_from_slice(&gbf.yv[..2 * n]);
            kr.copy_from_slice(&gbf.kv[..2 * n]);
        }
        let mut outcome = false;
        let mut y1 = vec![0.0; n];
        {
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            gbf.step_size = step_size / 2.0;
        }
        if self.gbodef_dispatch(ode)? {
            {
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                gbf.time += gbf.step_size;
                gbf.last_step_size = gbf.step_size;
                let y = gbf.y.clone();
                gbf.y_old.copy_from_slice(&y);
            }
            if !is_explicit {
                let (t, y) = {
                    let gbf = self.gbf.as_ref().expect("multirate without gbf");
                    (gbf.time, gbf.y.clone())
                };
                let mut f = vec![0.0; n];
                ode.eval(t, &y, &mut f)?;
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                gbf.tv[1] = gbf.tv[0];
                gbf.yv.copy_within(0..n, n);
                gbf.kv.copy_within(0..n, n);
                gbf.tv[0] = t;
                gbf.yv[..n].copy_from_slice(&y);
                gbf.kv[..n].copy_from_slice(&f);
            }
            if self.gbodef_dispatch(ode)? {
                {
                    let gbf = self.gbf.as_ref().expect("multirate without gbf");
                    y1.copy_from_slice(&gbf.y);
                }
                if !is_explicit {
                    let (t, y) = {
                        let gbf = self.gbf.as_ref().expect("multirate without gbf");
                        (gbf.time + gbf.step_size, gbf.y.clone())
                    };
                    let mut f = vec![0.0; n];
                    ode.eval(t, &y, &mut f)?;
                    let gbf = self.gbf.as_mut().expect("multirate without gbf");
                    gbf.tv[0] = gbf.time;
                    gbf.yv[..n].copy_from_slice(&y);
                    gbf.kv[..n].copy_from_slice(&f);
                }
                {
                    let gbf = self.gbf.as_mut().expect("multirate without gbf");
                    gbf.time = time_value;
                    gbf.step_size = step_size;
                    gbf.last_step_size = last_step_size;
                    let yl = gbf.y_left.clone();
                    gbf.y_old.copy_from_slice(&yl);
                }
                outcome = self.gbodef_dispatch(ode)?;
            }
        }
        let gbf = self.gbf.as_mut().expect("multirate without gbf");
        gbf.time = time_value;
        gbf.step_size = step_size;
        gbf.last_step_size = last_step_size;
        let yl = gbf.y_left.clone();
        gbf.y_old.copy_from_slice(&yl);
        if !is_explicit {
            gbf.tv[..2].copy_from_slice(&tr);
            gbf.yv[..2 * n].copy_from_slice(&yr);
            gbf.kv[..2 * n].copy_from_slice(&kr);
        }
        if outcome {
            let factor = pow(2.0, p as f64);
            for fi in 0..self.n_fast {
                let i = self.fast_states_idx[fi];
                let y_extrapolated = (factor * y1[i] - gbf.y[i]) / (factor - 1.0);
                gbf.yt[i] = gbf.y[i] - y_extrapolated;
            }
        }
        Ok(outcome)
    }
}

/// Which cached slow-interpolation node.
#[derive(Clone, Copy)]
pub(super) enum SlowNode {
    Left,
    Right,
    Stage(usize),
}

/// Hoare partition over an index array, C's `partition` (`gbode_ctrl.c`).
fn partition(idx: &mut [usize], value: &[f64], left: usize, right: usize) -> usize {
    let pivot = value[idx[(left + right) / 2]];
    let mut i = left as isize - 1;
    let mut j = right as isize + 1;
    loop {
        loop {
            i += 1;
            if value[idx[i as usize]] >= pivot {
                break;
            }
        }
        loop {
            j -= 1;
            if value[idx[j as usize]] <= pivot {
                break;
            }
        }
        if i >= j {
            return j as usize;
        }
        idx.swap(i as usize, j as usize);
    }
}

impl Gbode {
    /// C's `expl_diag_impl_RK_MR`.
    fn step_expl_diag_impl_mr(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        let n = self.n_states;
        let n_fast = self.n_fast;
        let n_stages = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            gbf.tableau.n_stages
        };
        // Slow states of `yOld` from the cache before the stages read it.
        {
            let mut y_old = {
                let gbf = self.gbf.as_ref().expect("multirate without gbf");
                gbf.y_old.clone()
            };
            self.slow_cache_apply(SlowNode::Left, &mut y_old);
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            gbf.y_old.copy_from_slice(&y_old);
            for fi in 0..n_fast {
                let i = self.fast_states_idx[fi];
                gbf.y_old_packed[fi] = y_old[i];
            }
        }
        for stage in 0..n_stages {
            let (a_ss, stage_time, step_size, k_left_reuse) = {
                let gbf = self.gbf.as_ref().expect("multirate without gbf");
                (
                    gbf.tableau.a_at(stage, stage),
                    gbf.time + gbf.tableau.c[stage] * gbf.step_size,
                    gbf.step_size,
                    gbf.tableau.k_left && stage == 0 && self.did_fast_step,
                )
            };
            if a_ss == 0.0 {
                // Explicit stage: the full res_const is propagated and evaluated.
                let (res_const, f_full) = {
                    let gbf = self.gbf.as_ref().expect("multirate without gbf");
                    let mut rc = gbf.y_old.clone();
                    for i in 0..n {
                        for s in 0..stage {
                            rc[i] += step_size * gbf.tableau.a_at(stage, s) * gbf.k[s * n + i];
                        }
                    }
                    (rc, gbf.k_left.clone())
                };
                let f = if k_left_reuse {
                    f_full
                } else {
                    let mut f = vec![0.0; n];
                    ode.eval(stage_time, &res_const, &mut f)?;
                    f
                };
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                gbf.res_const.copy_from_slice(&res_const);
                gbf.x[stage * n..(stage + 1) * n].copy_from_slice(&res_const);
                gbf.k[stage * n..(stage + 1) * n].copy_from_slice(&f);
                for fi in 0..n_fast {
                    let i = self.fast_states_idx[fi];
                    gbf.k_curr_packed[stage * n_fast + fi] = f[i];
                }
                continue;
            }
            // Implicit stage over the fast states only.
            let (res_const, y_old_full, internal, extrapolation_valid) = {
                let gbf = self.gbf.as_ref().expect("multirate without gbf");
                let mut rc = gbf.res_const.clone();
                for fi in 0..n_fast {
                    let i = self.fast_states_idx[fi];
                    rc[i] = gbf.y_old[i];
                    for s in 0..stage {
                        rc[i] += step_size * gbf.tableau.a_at(stage, s) * gbf.k[s * n + i];
                    }
                }
                (
                    rc,
                    gbf.y_old.clone(),
                    gbf.nls.as_ref().is_some_and(|nls| nls.internal),
                    gbf.extrapolation_valid,
                )
            };
            // The full evaluation point: slow states interpolated at the stage time.
            let mut base_full = y_old_full.clone();
            self.slow_cache_apply(SlowNode::Stage(stage), &mut base_full);
            // Start vectors: the packed `yOld` (C's nlsxOld), improved by the
            // stage-value predictors / dense output for the internal solver, and
            // the ring-buffer extrapolation (C's nlsxExtrapolation).
            let mut guess = vec![0.0; n_fast];
            for fi in 0..n_fast {
                guess[fi] = y_old_full[self.fast_states_idx[fi]];
            }
            {
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                let svp_lin = gbf.tableau.svp.as_ref().is_some_and(|svp| {
                    svp.types[stage] == SvpType::LinearCombination
                });
                let svp_dense = gbf.tableau.svp.as_ref().is_some_and(|svp| {
                    svp.types[stage] == SvpType::DenseOutput
                        && svp.dense_output_predictor.is_some()
                });
                let dense_valid = extrapolation_valid && internal;
                if svp_lin {
                    let svp = gbf.tableau.svp.as_ref().unwrap();
                    for fi in 0..n_fast {
                        let mut v = gbf.y_old_packed[fi];
                        for j in 0..stage {
                            v += step_size
                                * svp.a_predictor[stage * gbf.tableau.n_stages + j]
                                * gbf.k_curr_packed[j * n_fast + fi];
                        }
                        guess[fi] = v;
                    }
                } else if dense_valid && svp_dense {
                    let svp = gbf.tableau.svp.as_ref().unwrap();
                    let f = svp.dense_output_predictor.unwrap();
                    let theta =
                        (stage_time - gbf.extrapolation_base_time) / gbf.extrapolation_step_size;
                    f(&mut gbf.b_dt, theta);
                    let scale = theta * gbf.extrapolation_step_size;
                    for fi in 0..n_fast {
                        let mut acc = 0.0;
                        for s in 0..gbf.tableau.n_stages {
                            acc += gbf.b_dt[s] * gbf.k_last[s * n_fast + fi];
                        }
                        guess[fi] = gbf.y_last[fi] + scale * acc;
                    }
                } else if dense_valid && gbf.tableau.with_dense_output {
                    let theta =
                        (stage_time - gbf.extrapolation_base_time) / gbf.extrapolation_step_size;
                    let (y_last, k_last) = (gbf.y_last.clone(), gbf.k_last.clone());
                    gbf.tableau.dense_out(
                        &mut gbf.b_dt,
                        &y_last,
                        &k_last,
                        theta,
                        gbf.extrapolation_step_size,
                        &mut guess,
                        None,
                        n_fast,
                    );
                }
            }
            let mut extrap_full = base_full.clone();
            self.extrapolate_gbf(&mut extrap_full, stage_time);
            let mut extrap = vec![0.0; n_fast];
            for fi in 0..n_fast {
                extrap[fi] = extrap_full[self.fast_states_idx[fi]];
            }
            let mut x = guess.clone();
            let mut f_full = vec![0.0; n];
            let fac = step_size * a_ss;
            let event_happened = self.event_happened;
            let nominals = self.nominals.clone();
            let fast_idx = self.fast_states_idx[..n_fast].to_vec();
            let solved = {
                let gbf = self.gbf.as_mut().expect("multirate without gbf");
                let is_esdirk = gbf.tableau.a_at(0, 0) == 0.0;
                let first_implicit =
                    (stage == 0 && !is_esdirk) || (stage == 1 && is_esdirk);
                let time = gbf.time;
                let nls = gbf.nls.as_mut().expect("implicit stage without an NLS");
                let mut st = MrStage {
                    stage_time,
                    fac,
                    c_scale: 1.0,
                    res_const: &res_const,
                    base_full: &mut base_full,
                    fast_idx: &fast_idx,
                };
                nls.solve_stage(
                    ode,
                    stage,
                    &mut st,
                    step_size,
                    (time, &y_old_full),
                    first_implicit,
                    event_happened,
                    &nominals,
                    &[&extrap, &guess],
                    &mut x,
                    &mut f_full,
                )?
            };
            if solved != Solved::Ok {
                omclog::info(
                    omclog::SOLVER,
                    false,
                    &format!(
                        "gbodef error: Failed to solve NLS in expl_diag_impl_RK_MR in stage {} at time t={}",
                        stage + 1,
                        omclog::g(stage_time, 0, 6)
                    ),
                );
                return Ok(false);
            }
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            let internal_now = gbf.nls.as_ref().is_some_and(|nls| nls.internal);
            for fi in 0..n_fast {
                let i = self.fast_states_idx[fi];
                base_full[i] = x[fi];
                if internal_now {
                    // Reconstruct k from the solution, as the internal solver does.
                    f_full[i] = (x[fi] - res_const[i]) / fac;
                }
            }
            gbf.res_const.copy_from_slice(&res_const);
            gbf.x[stage * n..(stage + 1) * n].copy_from_slice(&base_full);
            gbf.k[stage * n..(stage + 1) * n].copy_from_slice(&f_full);
            for fi in 0..n_fast {
                let i = self.fast_states_idx[fi];
                gbf.k_curr_packed[stage * n_fast + fi] = f_full[i];
            }
        }
        // y = yOld + h*sum(b*k) for the fast states only.
        {
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            for fi in 0..n_fast {
                let i = self.fast_states_idx[fi];
                let mut v = gbf.y_old[i];
                for stage in 0..n_stages {
                    v += gbf.step_size * gbf.tableau.b[stage] * gbf.k[stage * n + i];
                }
                gbf.y[i] = v;
            }
        }
        self.gbf_estimate_error(ode)
    }

    /// C's `full_implicit_RK_MR` (`-gbnls=internal` only).
    fn step_full_implicit_mr(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        let n = self.n_states;
        let n_fast = self.n_fast;
        let (n_stages, step_size, time) = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            (gbf.tableau.n_stages, gbf.step_size, gbf.time)
        };
        let fast_idx = self.fast_states_idx[..n_fast].to_vec();
        let y_old_full = {
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            let y_old = gbf.y_old.clone();
            for fi in 0..n_fast {
                gbf.y_old_packed[fi] = y_old[fast_idx[fi]];
            }
            y_old
        };
        // Start values: yOld per stage, improved by dense output when valid.
        let mut z = vec![0.0; n_stages * n_fast];
        {
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            for stage in 0..n_stages {
                for fi in 0..n_fast {
                    z[stage * n_fast + fi] = gbf.y_old_packed[fi];
                }
            }
            if gbf.tableau.with_dense_output && gbf.extrapolation_valid {
                for stage in 0..n_stages {
                    let theta = (time + gbf.tableau.c[stage] * step_size
                        - gbf.extrapolation_base_time)
                        / gbf.extrapolation_step_size;
                    let (y_last, k_last) = (gbf.y_last.clone(), gbf.k_last.clone());
                    gbf.tableau.dense_out(
                        &mut gbf.b_dt,
                        &y_last,
                        &k_last,
                        theta,
                        gbf.extrapolation_step_size,
                        &mut z[stage * n_fast..(stage + 1) * n_fast],
                        None,
                        n_fast,
                    );
                }
            }
        }
        // Full evaluation points per stage: slow states interpolated.
        let mut stage_fulls: Vec<Vec<f64>> = Vec::with_capacity(n_stages);
        for stage in 0..n_stages {
            let mut full = y_old_full.clone();
            self.slow_cache_apply(SlowNode::Stage(stage), &mut full);
            stage_fulls.push(full);
        }
        let mut k_packed = vec![0.0; n_stages * n_fast];
        let event_happened = self.event_happened;
        let nominals = self.nominals.clone();
        let solved = {
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            let y_old_packed = gbf.y_old_packed[..n_fast].to_vec();
            let tableau = &gbf.tableau;
            let nls = gbf.nls.as_mut().expect("implicit method without an NLS");
            nls.solve_firk(
                ode,
                tableau,
                time,
                step_size,
                &y_old_full,
                &y_old_packed,
                &fast_idx,
                &mut stage_fulls,
                &mut z,
                &mut k_packed,
                event_happened,
                &nominals,
            )?
        };
        if solved != Solved::Ok {
            omclog::info(
                omclog::SOLVER,
                false,
                &format!(
                    "gbode error: Failed to solve NLS in full_implicit_RK_MR at time t={}",
                    omclog::g(time, 0, 6)
                ),
            );
            return Ok(false);
        }
        {
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            for fi in 0..n_fast {
                let i = fast_idx[fi];
                let mut v = gbf.y_old[i];
                for stage in 0..n_stages {
                    gbf.x[stage * n + i] = z[stage * n_fast + fi];
                    v += step_size * gbf.tableau.b[stage] * k_packed[stage * n_fast + fi];
                    gbf.k[stage * n + i] = k_packed[stage * n_fast + fi];
                }
                gbf.y[i] = v;
            }
            gbf.k_curr_packed[..n_stages * n_fast].copy_from_slice(&k_packed);
        }
        self.gbf_estimate_error(ode)
    }

    /// C's `full_implicit_MS_MR`.
    fn step_full_implicit_ms_mr(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        let n = self.n_states;
        let n_fast = self.n_fast;
        let fast_idx = self.fast_states_idx[..n_fast].to_vec();
        let (n_stages, step_size, time, bt) = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            (
                gbf.tableau.n_stages,
                gbf.step_size,
                gbf.time,
                gbf.tableau.bt.clone().expect("adams tableau without bt"),
            )
        };
        let last = n_stages - 1;
        // Predictor and constant part over the fast states.
        {
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            for &i in &fast_idx {
                let mut yt = 0.0;
                let mut rc = 0.0;
                for stage in 0..last {
                    yt += -gbf.yv[stage * n + i] * gbf.tableau.c[stage]
                        + gbf.kv[stage * n + i] * bt[stage] * step_size;
                    rc += -gbf.yv[stage * n + i] * gbf.tableau.c[stage]
                        + gbf.kv[stage * n + i] * gbf.tableau.b[stage] * step_size;
                }
                yt += gbf.kv[last * n + i] * bt[last] * step_size;
                gbf.yt[i] = yt / gbf.tableau.c[last];
                gbf.res_const[i] = rc;
            }
        }
        // The full evaluation point at t + h: slow states interpolated with the
        // outer method (C interpolates them directly here, not via the cache).
        let stage_time = time + step_size;
        let mut base_full = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            gbf.y_old.clone()
        };
        {
            let idx = self.slow_states_idx[..self.n_slow].to_vec();
            let (y_left, k_left) = (self.y_left.clone(), self.k_left.clone());
            let (y_right, k_right) = (self.y_right.clone(), self.k_right.clone());
            interp::interpolate(
                self.conf.interpolation,
                self.time_left,
                &y_left,
                &k_left,
                self.time_right,
                &y_right,
                &k_right,
                stage_time,
                &mut base_full,
                Some(&idx),
                n,
                &self.tableau,
                &mut self.b_dt,
                &self.k,
            );
        }
        let (res_const, y_old_full, guess) = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            let mut g = vec![0.0; n_fast];
            for fi in 0..n_fast {
                g[fi] = gbf.yt[fast_idx[fi]];
            }
            (gbf.res_const.clone(), gbf.y_old.clone(), g)
        };
        let mut x = guess.clone();
        let mut f_full = vec![0.0; n];
        let event_happened = self.event_happened;
        let nominals = self.nominals.clone();
        let solved = {
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            let c_last = gbf.tableau.c[last];
            let b_last = gbf.tableau.b[last];
            let nls = gbf.nls.as_mut().expect("multi-step method without an NLS");
            let mut st = MrStage {
                stage_time,
                fac: step_size * b_last,
                c_scale: c_last,
                res_const: &res_const,
                base_full: &mut base_full,
                fast_idx: &fast_idx,
            };
            let start = guess.clone();
            nls.solve_stage(
                ode,
                0,
                &mut st,
                step_size,
                (time, &y_old_full),
                true,
                event_happened,
                &nominals,
                &[&start],
                &mut x,
                &mut f_full,
            )?
        };
        if solved != Solved::Ok {
            omclog::info(
                omclog::SOLVER,
                false,
                &format!(
                    "gbodef error: Failed to solve NLS in full_implicit_MS_MR at time t={}",
                    omclog::g(time, 0, 6)
                ),
            );
            return Ok(false);
        }
        {
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            let internal_now = gbf.nls.as_ref().is_some_and(|nls| nls.internal);
            if internal_now {
                let c_last = gbf.tableau.c[last];
                let b_last = gbf.tableau.b[last];
                for fi in 0..n_fast {
                    let i = fast_idx[fi];
                    f_full[i] =
                        (c_last * x[fi] - res_const[i]) / (step_size * b_last);
                }
            }
            gbf.kv[last * n..(last + 1) * n].copy_from_slice(&f_full);
            for fi in 0..n_fast {
                let i = fast_idx[fi];
                let mut v = 0.0;
                for stage in 0..last {
                    v += -gbf.yv[stage * n + i] * gbf.tableau.c[stage]
                        + gbf.kv[stage * n + i] * gbf.tableau.b[stage] * step_size;
                }
                v += gbf.kv[last * n + i] * gbf.tableau.b[last] * step_size;
                gbf.y[i] = v / gbf.tableau.c[last];
                gbf.yt[i] = gbf.y[i] - gbf.yt[i];
            }
        }
        Ok(true)
    }

    /// C's `gbEstimateError` for the inner integrator: run the active estimator
    /// over the fast states, falling back like the single-rate one. `false` ⇒ the
    /// estimator failed and the step must be rejected.
    fn gbf_estimate_error(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        let active = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            gbf.tableau.active
        };
        let order = self.gbf_evaluate_error(ode, Some(active))?;
        if let Some(order) = order {
            let gbf = self.gbf.as_mut().expect("multirate without gbf");
            gbf.current_error_order = order;
            Ok(true)
        } else {
            Ok(false)
        }
    }

    fn gbf_evaluate_error(
        &mut self,
        ode: &mut dyn Ode,
        estimator: Option<Estimator>,
    ) -> Result<Option<i32>> {
        let Some(est) = estimator else { return Ok(None) };
        match est.kind {
            super::tableau::ErrMethod::Embedded => {
                let has_bt = {
                    let gbf = self.gbf.as_ref().expect("multirate without gbf");
                    gbf.tableau.bt.is_some()
                };
                if !has_bt {
                    return Ok(None);
                }
                self.gbf_embedded_estimate();
                Ok(Some(est.order))
            }
            super::tableau::ErrMethod::Richardson => Ok(Some(est.order)),
            super::tableau::ErrMethod::TwoStep => {
                if self.gbf_two_step_estimate(est.order) {
                    Ok(Some(est.order))
                } else {
                    let fallback = {
                        let gbf = self.gbf.as_ref().expect("multirate without gbf");
                        gbf.two_step_fallback
                    };
                    self.gbf_evaluate_error(ode, fallback)
                }
            }
            super::tableau::ErrMethod::Contractive => {
                self.gbf_contractive(ode, false)?;
                Ok(Some(est.order))
            }
            super::tableau::ErrMethod::Filter => {
                self.gbf_embedded_estimate();
                self.gbf_contractive(ode, true)?;
                Ok(Some(est.order))
            }
            super::tableau::ErrMethod::Default => Ok(None),
        }
    }

    /// The inner integrator's contractive estimators (`gbInternalContractiveDefect`
    /// / `gbInternalContractiveFilterError` with `multirate`): the defect
    /// `f(t_n, y_n) - d(0)^T*A*K` over the fast states — or, as the filter, the
    /// embedded estimate already in `errest` — contracted with `gamma/h*I - J_ff`
    /// and, for the filter, scaled back by `gamma/h`. Only reachable with the
    /// internal solver, whose Jacobian block is current.
    fn gbf_contractive(&mut self, ode: &mut dyn Ode, filter: bool) -> Result<()> {
        let n = self.n_states;
        let n_fast = self.n_fast;
        let fast_idx = self.fast_states_idx[..n_fast].to_vec();
        let mut err = vec![0.0; n_fast];
        if filter {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            for fi in 0..n_fast {
                err[fi] = gbf.errest[fast_idx[fi]];
            }
        } else {
            let (dt_a, n_stages, k_right, valid) = {
                let gbf = self.gbf.as_ref().expect("multirate without gbf");
                let dt_a = gbf
                    .tableau
                    .contractive_dt_a
                    .clone()
                    .ok_or("CodegenWasmJit: gbode: contractive defect without dT_A")?;
                (dt_a, gbf.tableau.n_stages, gbf.tableau.k_right, gbf.extrapolation_valid)
            };
            {
                let gbf = self.gbf.as_ref().expect("multirate without gbf");
                for fi in 0..n_fast {
                    let mut acc = 0.0;
                    for stage in 0..n_stages {
                        acc += dt_a[stage] * gbf.k_curr_packed[stage * n_fast + fi];
                    }
                    err[fi] = -acc;
                }
            }
            // `f(t_n, y_n)`: the previous step's collocated end derivative when the
            // method provides it, else a fresh evaluation at the interval's start.
            if k_right && self.did_fast_step && valid {
                let gbf = self.gbf.as_ref().expect("multirate without gbf");
                for fi in 0..n_fast {
                    err[fi] += gbf.k_last[(n_stages - 1) * n_fast + fi];
                }
            } else {
                let (time, mut base) = {
                    let gbf = self.gbf.as_ref().expect("multirate without gbf");
                    (gbf.time, gbf.y_old.clone())
                };
                self.slow_cache_apply(SlowNode::Left, &mut base);
                let mut f = vec![0.0; n];
                ode.eval(time, &base, &mut f)?;
                for fi in 0..n_fast {
                    err[fi] += f[fast_idx[fi]];
                }
            }
        }
        let gbf = self.gbf.as_mut().expect("multirate without gbf");
        let gamma = gbf
            .tableau
            .t_transform
            .as_ref()
            .and_then(|tr| tr.gamma.first().copied())
            .ok_or("CodegenWasmJit: gbode: contractive estimate without a real eigenvalue")?;
        let g = gamma / gbf.step_size;
        let nls = gbf.nls.as_mut().ok_or("CodegenWasmJit: gbode: contractive estimate without an internal NLS")?;
        let mut lu = nls.contract_factor(g)?;
        lu.solve(&mut err);
        if filter {
            for v in &mut err {
                *v *= g;
            }
        }
        for fi in 0..n_fast {
            gbf.errest[fast_idx[fi]] = abs(err[fi]);
        }
        Ok(())
    }

    /// C's `embeddedErrorEstimate_gbf` + `absErrorEstimate_gbf`.
    fn gbf_embedded_estimate(&mut self) {
        let n = self.n_states;
        let n_fast = self.n_fast;
        let gbf = self.gbf.as_mut().expect("multirate without gbf");
        let bt = gbf.tableau.bt.as_ref().expect("embedded estimate without bt");
        let n_stages = gbf.tableau.n_stages;
        for fi in 0..n_fast {
            let i = self.fast_states_idx[fi];
            let mut acc = 0.0;
            for stage in 0..n_stages {
                acc += gbf.step_size * (gbf.tableau.b[stage] - bt[stage])
                    * gbf.k[stage * n + i];
            }
            gbf.errest[i] = abs(acc);
        }
    }

    /// C's `twoStepEstimate_gbf`.
    fn gbf_two_step_estimate(&mut self, estimator_order: i32) -> bool {
        let n = self.n_states;
        let n_fast = self.n_fast;
        const MAX_GBODE_FIRK_STAGES: usize = 8;
        let (n_stages, valid) = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            (
                gbf.tableau.n_stages,
                !(gbf.tableau.n_stages > MAX_GBODE_FIRK_STAGES
                    || gbf.last_step_size <= 0.0
                    || !gbf.extrapolation_valid),
            )
        };
        if !valid {
            return false;
        }
        let (weights, r) = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            let Some(w) = gbf.tableau.two_step_weights else { return false };
            (w, gbf.step_size / gbf.last_step_size)
        };
        let mut d_old = vec![0.0; n_stages];
        let mut g_new = vec![0.0; n_stages];
        let mut mu = weights(r, &mut d_old, &mut g_new);
        if !self.gbf_scale_two_step_mu(estimator_order, &mut mu) {
            return false;
        }
        let gbf = self.gbf.as_mut().expect("multirate without gbf");
        let internal = gbf.nls.as_ref().is_some_and(|nls| nls.internal);
        for stage in 0..n_stages {
            d_old[stage] *= gbf.last_step_size;
            g_new[stage] *= gbf.step_size;
        }
        for fi in 0..n_fast {
            let i = self.fast_states_idx[fi];
            let mut y_emb = gbf.y_old[i];
            for stage in 0..n_stages {
                let k_new = if internal {
                    gbf.k_curr_packed[stage * n_fast + fi]
                } else {
                    gbf.k[stage * n + i]
                };
                y_emb += d_old[stage] * gbf.k_last[stage * n_fast + fi] + g_new[stage] * k_new;
            }
            gbf.errest[i] = abs(mu * (gbf.y[i] - y_emb));
        }
        true
    }

    fn gbf_scale_two_step_mu(&self, estimator_order: i32, mu: &mut f64) -> bool {
        let gbf = self.gbf.as_ref().expect("multirate without gbf");
        let method_order = gbf.tableau.order_b;
        let tol = self.tol;
        let scaled_tol = if gbf.tableau.richardson || estimator_order >= method_order {
            tol
        } else {
            let q = (estimator_order as f64 + 1.0) / (method_order as f64 + 1.0);
            tol.max(super::GB_TOLERANCE_SCALING_SAFETY * pow(tol, q))
        };
        let order_quot = (estimator_order as f64 + 1.0) / (method_order as f64 + 1.0);
        *mu *= scaled_tol / pow(tol, order_quot);
        mu.is_finite() && abs(*mu) >= 1e-6 && abs(*mu) <= 1e6
    }

    /// Interpolate the inner step onto `t` for every state, C's `bisection_gb`
    /// interpolation with `isInnerIntegration`.
    pub(super) fn interpolate_gbf_all(&mut self, t: f64, out: &mut [f64]) {
        self.interpolate_gbf_idx(t, out, None);
    }

    pub(super) fn interpolate_gbf_idx(&mut self, t: f64, out: &mut [f64], idx: Option<&[usize]>) {
        let n = self.n_states;
        let gbf = self.gbf.as_mut().expect("multirate without gbf");
        interp::interpolate(
            gbf.conf.interpolation,
            gbf.time_left,
            &gbf.y_left,
            &gbf.k_left,
            gbf.time_right,
            &gbf.y_right,
            &gbf.k_right,
            t,
            out,
            idx,
            n,
            &gbf.tableau,
            &mut gbf.b_dt,
            &gbf.k,
        );
    }

    /// C's `checkForEvents` with `isInnerIntegration`: the crossings at the inner
    /// step's right end against the latched base, bisected on the inner
    /// interpolant.
    fn check_for_events_gbf(&mut self, ode: &mut dyn Ode) -> Result<Option<f64>> {
        if self.zc.is_empty() {
            return Ok(None);
        }
        self.zc_pre.copy_from_slice(&self.zc);
        let saved_pre = self.zc_pre.clone();
        let (t_right, y_right) = {
            let gbf = self.gbf.as_ref().expect("multirate without gbf");
            (gbf.time_right, gbf.y_right.clone())
        };
        let mut zc = core::mem::take(&mut self.zc);
        ode.eval_zc(t_right, &y_right, &mut zc)?;
        self.zc = zc;
        self.event_ids = self.changed_crossings();
        let found = !self.event_ids.is_empty();
        let event_time = if found {
            if crate::simflags::with_flags(|f| f.no_root_finding) {
                Some(t_right)
            } else {
                let (l, r) = {
                    let gbf = self.gbf.as_ref().expect("multirate without gbf");
                    (gbf.time_left, gbf.time_right)
                };
                Some(self.find_root_gbf(ode, l, r)?)
            }
        } else {
            None
        };
        self.zc.copy_from_slice(&saved_pre);
        self.zc_pre.copy_from_slice(&saved_pre);
        Ok(event_time)
    }

    fn find_root_gbf(&mut self, ode: &mut dyn Ode, mut a: f64, mut b: f64) -> Result<f64> {
        let ttol = super::MINIMAL_STEP_SIZE + super::MINIMAL_STEP_SIZE * abs(b - a);
        let mut iters = crate::bisection_iterations(b - a, ttol);
        self.zc_backup.copy_from_slice(&self.zc);
        let n = self.n_states;
        while abs(b - a) > super::MINIMAL_STEP_SIZE && iters > 0 {
            iters -= 1;
            let c = 0.5 * (a + b);
            let mut y = vec![0.0; n];
            self.interpolate_gbf_all(c, &mut y);
            let mut zc = core::mem::take(&mut self.zc);
            ode.eval_zc(c, &y, &mut zc)?;
            self.zc = zc;
            if self.crossing_in_left() {
                b = c;
                self.zc_backup.copy_from_slice(&self.zc);
            } else {
                a = c;
                self.zc_pre.copy_from_slice(&self.zc);
                let backup = self.zc_backup.clone();
                self.zc.copy_from_slice(&backup);
            }
        }
        Ok(b)
    }
}
