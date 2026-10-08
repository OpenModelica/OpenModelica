//! gbode's own nonlinear solver (`-gbnls=internal`), a port of the single-rate
//! part of C's `gbode_internal_nls.c`.
//!
//! Two systems appear, both solved by a simplified Newton iteration over
//! factorizations built from the ODE Jacobian `J = df/dy`:
//!
//! * DIRK, one stage at a time, `0 = res_const - x + h*a_ii*f(t_i, x)`, whose
//!   simplified Jacobian is `h*a_ii*J - I` (C's `jacobian_DIRK_assemble`).
//! * FIRK, all stages coupled, decoupled by the tableau's T-transformation
//!   (`gbInternalSolveNls_T_Transform`): one `gamma/h*I - J` per distinct real
//!   eigenvalue of `A^-1`, one complex `(alpha+i*beta)/h*I - J` per conjugate
//!   pair, with forward substitution through `L`.
//!
//! As in C, `J` lives in the model's sparsity pattern and every system in
//! `struct(I + J)`, all sharing one symbolic factorization ([`GbLinSys`]).
//!
//! The birate mode's inner integration solves the same systems packed over its
//! fast states ([`Fast`], C's `multirate`), with the pattern reduced to them.

use alloc::vec;
use alloc::vec::Vec;

use super::linsol::{GbLinSys, NlsPattern, OdePattern};
use super::tableau::{TTransform, Tableau};
use crate::gbode::math::{abs, pow, sqrt};
use crate::{eval_caught, eval_caught_fast, Ode, Result};

/// C's `DBL_ABSORPTION`.
const DBL_ABSORPTION: f64 = 10.0 * f64::EPSILON;

#[derive(PartialEq, Eq, Debug)]
pub enum Solved {
    Ok,
    Failed,
}

/// The packed systems of the inner integration: the fast states, and the full
/// state vectors their values are scattered into for an evaluation, whose slow
/// entries the caller sets (C's `slowStateCache_overwrite_*`).
pub(super) struct Fast {
    idx: Vec<usize>,
    /// At the interval's left end, then one per stage.
    left: Vec<f64>,
    stages: Vec<Vec<f64>>,
    f: Vec<f64>,
    fbase: Vec<f64>,
    probe: Vec<f64>,
    seed: Vec<f64>,
    /// C's `new_fast_states`: rebuild the pattern before the next solve.
    changed: bool,
}

/// Where a packed evaluation takes its slow states from.
#[derive(Clone, Copy)]
enum At {
    Left,
    Stage(usize),
}

/// `f(t, x)` for the system's unknowns: directly, or scattered into the full
/// state vector at `at` with the fast entries read back.
fn eval_at(fast: &mut Option<Fast>, ode: &mut dyn Ode, t: f64, at: At, x: &[f64], f: &mut [f64]) -> Result<bool> {
    let Some(m) = fast.as_mut() else { return eval_caught(ode, t, x, f) };
    let full = match at {
        At::Left => &mut m.left,
        At::Stage(j) => &mut m.stages[j],
    };
    for (i, &k) in m.idx.iter().enumerate() {
        full[k] = x[i];
    }
    let ok = eval_caught_fast(ode, t, full, &mut m.f)?;
    for (i, &k) in m.idx.iter().enumerate() {
        f[i] = m.f[k];
    }
    Ok(ok)
}

/// C's `GB_INTERNAL_NLS_DATA`.
pub(super) struct GbNls {
    /// The system's size: all states, or the fast ones.
    n: usize,
    n_full: usize,
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
    /// ... or as a whole, through the adjoint or both directions.
    whole_jac: Option<crate::simflags::JacobianMethod>,
    call_jac: bool,
    n_real: usize,
    n_cmplx: usize,
    /// The ODE Jacobian's pattern (reduced to the fast states in the birate
    /// mode, whose full one is `full_pat`) and values (C's `jacobian_callback`).
    ode_pat: Option<OdePattern>,
    full_pat: Option<OdePattern>,
    fast: Option<Fast>,
    jac: Vec<f64>,
    maxs: Vec<f64>,
    sys: Option<GbLinSys>,
    real_jacs: Vec<Vec<f64>>,
    /// Interleaved `re, im` per pattern entry.
    cmplx_jacs: Vec<Vec<f64>>,
    scal: Vec<f64>,
    stage_time_0: f64,
    res: Vec<f64>,
    f: Vec<f64>,
    fbase: Vec<f64>,
    probe: Vec<f64>,
    inv_del: Vec<f64>,
    tz: Vec<f64>,
    w: Vec<f64>,
    fw: Vec<f64>,
    k1: Vec<f64>,
    cres: Vec<f64>,
    pub n_iters: u64,
    pub n_jac_evals: u64,
    /// Model evaluations of finite-difference Jacobians, which C does not count
    /// as `functionODE` calls.
    pub uncounted_calls: u64,
}

impl GbNls {
    /// C's `gbInternalNlsAllocate` for the single-rate case.
    pub(super) fn new(
        t: &Tableau,
        n_states: usize,
        tol: f64,
        jac_colors: usize,
        sym_jac: bool,
        whole_jac: Option<crate::simflags::JacobianMethod>,
    ) -> Self {
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
        let tr = t.t_transform.as_ref();
        let max_newton_it = tr.map_or(5, |tr| 4 + 2 * tr.size as u32);
        let (n_real, n_cmplx) = tr.map_or((1, 0), |tr| (tr.n_real_eigenvalues, tr.n_complex_eigenpairs));
        let tsize = tr.map_or(1, |tr| tr.size);
        GbNls {
            n: n_states,
            n_full: n_states,
            integrator_tol: tol,
            fnewt,
            eta_initial_damping,
            theta_keep,
            theta_divergence: 0.99,
            max_newton_it,
            etas: vec![f64::MAX; t.n_stages],
            sym_jac,
            whole_jac,
            call_jac: true,
            n_real,
            n_cmplx,
            ode_pat: None,
            full_pat: None,
            fast: None,
            jac: Vec::new(),
            maxs: Vec::new(),
            sys: None,
            real_jacs: Vec::new(),
            cmplx_jacs: Vec::new(),
            scal: vec![0.0; n_states],
            stage_time_0: 0.0,
            res: vec![0.0; tsize * n_states],
            f: vec![0.0; n_states],
            fbase: vec![0.0; n_states],
            probe: vec![0.0; n_states],
            inv_del: vec![0.0; n_states],
            tz: vec![0.0; tsize * n_states],
            w: vec![0.0; tsize * n_states],
            fw: vec![0.0; tsize * n_states],
            k1: vec![0.0; n_states],
            cres: vec![0.0; 2 * n_states],
            n_iters: 0,
            n_jac_evals: 0,
            uncounted_calls: 0,
        }
    }

    /// The inner integration's solver: packed over the fast states
    /// [`GbNls::set_fast`] names.
    pub(super) fn with_fast(mut self, n_stages: usize) -> Self {
        let n = self.n_full;
        self.fast = Some(Fast {
            idx: Vec::new(),
            left: vec![0.0; n],
            stages: vec![vec![0.0; n]; n_stages],
            f: vec![0.0; n],
            fbase: vec![0.0; n],
            probe: vec![0.0; n],
            seed: vec![0.0; n],
            changed: true,
        });
        self
    }

    /// C's `gbInternalScheduleFastStatesUpdate`, with the new fast states.
    pub(super) fn set_fast(&mut self, idx: &[usize]) {
        let m = self.fast.as_mut().expect("fast states for a single-rate solver");
        m.idx.clear();
        m.idx.extend_from_slice(idx);
        m.changed = true;
        self.n = idx.len();
    }

    /// The full state vector at the interval's left end, or at `stage`, whose
    /// slow entries the evaluations use.
    pub(super) fn fast_left_mut(&mut self) -> &mut [f64] {
        &mut self.fast.as_mut().expect("single-rate solver").left
    }

    pub(super) fn fast_stage_mut(&mut self, stage: usize) -> &mut [f64] {
        &mut self.fast.as_mut().expect("single-rate solver").stages[stage]
    }

    /// Called after an event or a restart.
    pub(super) fn invalidate(&mut self) {
        self.call_jac = true;
        for e in &mut self.etas {
            *e = f64::MAX;
        }
    }

    /// The patterns and the symbolic analysis, on first use: C's
    /// `gbodeMapSparsePattern` + `gbInternal_KLU_analyze`. In the birate mode
    /// also after a fast-state change, C's `updateFastStates` with
    /// `updateSparsePattern_GBODEF`.
    fn ensure_systems(&mut self, ode: &dyn Ode) {
        let changed = self.fast.as_ref().is_some_and(|m| m.changed);
        if self.sys.is_some() && !changed {
            return;
        }
        let n = self.n;
        let full = OdePattern::new(self.n_full, ode.jac_rows_by_col(), ode.jac_colors());
        let ode_pat = match self.fast.as_mut() {
            None => full,
            Some(m) => {
                m.changed = false;
                let reduced = full.reduce(&m.idx, self.n_full);
                self.full_pat = Some(full);
                self.call_jac = true;
                for e in &mut self.etas {
                    *e = f64::MAX;
                }
                reduced
            }
        };
        let pat = NlsPattern::new(n, &ode_pat);
        let nnz = pat.nnz();
        self.jac = vec![0.0; ode_pat.nnz()];
        self.maxs = ode.maxs().to_vec();
        self.real_jacs = (0..self.n_real).map(|_| vec![0.0; nnz]).collect();
        self.cmplx_jacs = (0..self.n_cmplx).map(|_| vec![0.0; 2 * nnz]).collect();
        self.sys = Some(GbLinSys::new(pat, self.n_real, self.n_cmplx));
        self.ode_pat = Some(ode_pat);
    }

    /// C's `createGbScales`.
    fn make_scales(&mut self, nominals: &[f64], y1: &[f64], y2: &[f64]) {
        let tol = self.integrator_tol;
        for i in 0..self.n {
            let nom = match self.fast.as_ref() {
                Some(m) => nominals[m.idx[i]],
                None => nominals[i],
            };
            self.scal[i] = 1.0 / (tol * nom + abs(y1[i]).max(abs(y2[i])) * tol);
        }
    }

    /// C's `gbScalesNorm` over `stack` blocks of `n`.
    fn scaled_norm(&self, v: &[f64], stack: usize) -> f64 {
        let n = self.n;
        let mut sum = 0.0;
        for j in 0..stack {
            for i in 0..n {
                let t = v[j * n + i] * self.scal[i];
                sum += t * t;
            }
        }
        sqrt(sum / (n as f64 * stack as f64))
    }

    /// C's `gbInternal_evalJacobian` at `(time, y)`, with `f(time, y)` already in
    /// `fbase`: the colored symbolic Jacobian when the model carries one, else
    /// colored finite differences (`gbInternal_evalNumericalJacobian`), whose
    /// evaluations swallow their own model errors. `false`: the symbolic one threw.
    fn eval_jacobian(&mut self, ode: &mut dyn Ode, time: f64, y: &[f64], nominals: &[f64]) -> Result<bool> {
        self.n_jac_evals += 1;
        if self.sym_jac && ode.has_jacobian_vector() {
            let c = ode.catch_begin();
            let run = match self.fast.is_some() {
                true => self.eval_sym_jacobian_fast(ode, time),
                false => self.eval_sym_jacobian(ode, time, y),
            };
            let threw = ode.catch_end(c);
            return run.map(|()| !threw);
        }
        match self.fast.is_some() {
            true => self.eval_num_jacobian_fast(ode, time, nominals)?,
            false => self.eval_num_jacobian(ode, time, y, nominals)?,
        }
        Ok(true)
    }

    /// C's `gbInternal_evalJacobianMR`: the fast columns seeded colour by colour
    /// at the left end, the reduced pattern's rows read back.
    fn eval_sym_jacobian_fast(&mut self, ode: &mut dyn Ode, time: f64) -> Result<()> {
        let pat = self.ode_pat.as_ref().expect("Jacobian before the pattern");
        let m = self.fast.as_mut().expect("fast Jacobian without fast states");
        m.seed.fill(0.0);
        for group in &pat.colors {
            for &c in group {
                m.seed[m.idx[c as usize]] = 1.0;
            }
            if !ode.jacobian_vector(time, &m.left, &m.seed, &mut m.probe) {
                return Err("##GBODE## the model could not multiply by its Jacobian");
            }
            for &c in group {
                let c = c as usize;
                m.seed[m.idx[c]] = 0.0;
                for nz in pat.ap[c] as usize..pat.ap[c + 1] as usize {
                    self.jac[nz] = m.probe[m.idx[pat.ai[nz] as usize]];
                }
            }
        }
        Ok(())
    }

    /// `gbInternal_evalNumericalJacobian` with the fast state map, about the left
    /// end, whose full derivative the evaluation before left in `Fast::f`.
    fn eval_num_jacobian_fast(&mut self, ode: &mut dyn Ode, time: f64, nominals: &[f64]) -> Result<()> {
        let pat = self.ode_pat.as_ref().expect("Jacobian before the pattern");
        let m = self.fast.as_mut().expect("fast Jacobian without fast states");
        let tol = self.integrator_tol;
        let delta_h = crate::simflags::with_flags(crate::simflags::delta_x_solver);
        m.fbase.copy_from_slice(&m.f);
        m.probe.copy_from_slice(&m.left);
        for group in &pat.colors {
            for &col in group {
                let c = m.idx[col as usize];
                let x = m.left[c];
                let delta_hhh = delta_h * m.fbase[c];
                let raw_weight = tol * nominals[c] + tol * abs(x);
                let mut del = delta_h * abs(x).max(1e-3).max(abs(delta_hhh)).max(abs(raw_weight));
                del = x + del - x;
                if self.maxs.get(c).is_some_and(|&mx| x + del >= mx) {
                    del = -del;
                }
                m.probe[c] = x + del;
                self.inv_del[col as usize] = 1.0 / del;
            }
            eval_caught_fast(ode, time, &m.probe, &mut m.f)?;
            self.uncounted_calls += 1;
            for &col in group {
                let col = col as usize;
                for nz in pat.ap[col] as usize..pat.ap[col + 1] as usize {
                    let r = m.idx[pat.ai[nz] as usize];
                    self.jac[nz] = (m.f[r] - m.fbase[r]) * self.inv_del[col];
                }
                m.probe[m.idx[col]] = m.left[m.idx[col]];
            }
        }
        Ok(())
    }

    fn eval_sym_jacobian(&mut self, ode: &mut dyn Ode, time: f64, y: &[f64]) -> Result<()> {
        let pat = self.ode_pat.as_ref().expect("Jacobian before the pattern");
        let method = self.whole_jac.unwrap_or(crate::simflags::JacobianMethod::ColoredSymJac);
        if ode.jacobian_matrix(time, y, method, &mut self.jac) {
            return Ok(());
        }
        if self.whole_jac.is_some() {
            return Err("##GBODE## the model could not evaluate its Jacobian");
        }
        let (seed, out) = (&mut self.probe, &mut self.f);
        seed.fill(0.0);
        for group in &pat.colors {
            for &c in group {
                seed[c as usize] = 1.0;
            }
            if !ode.jacobian_vector(time, y, seed, out) {
                return Err("##GBODE## the model could not multiply by its Jacobian");
            }
            for &c in group {
                let c = c as usize;
                seed[c] = 0.0;
                for nz in pat.ap[c] as usize..pat.ap[c + 1] as usize {
                    self.jac[nz] = out[pat.ai[nz] as usize];
                }
            }
        }
        Ok(())
    }

    fn eval_num_jacobian(&mut self, ode: &mut dyn Ode, time: f64, y: &[f64], nominals: &[f64]) -> Result<()> {
        let n = self.n;
        let pat = self.ode_pat.as_ref().expect("Jacobian before the pattern");
        let tol = self.integrator_tol;
        let delta_h = crate::simflags::with_flags(crate::simflags::delta_x_solver);
        self.probe[..n].copy_from_slice(&y[..n]);
        for group in &pat.colors {
            for &col in group {
                let c = col as usize;
                // C's step, a la the DASSL interface:
                // h_i = delta_h * max(|x_i|, 1e-3, |delta_h*f_i|, atol*nom + rtol*|x_i|).
                let delta_hhh = delta_h * self.fbase[c];
                let raw_weight = tol * nominals[c] + tol * abs(y[c]);
                let mut del = delta_h * abs(y[c]).max(1e-3).max(abs(delta_hhh)).max(abs(raw_weight));
                del = y[c] + del - y[c];
                if self.maxs.get(c).is_some_and(|&mx| y[c] + del >= mx) {
                    del = -del;
                }
                self.probe[c] = y[c] + del;
                self.inv_del[c] = 1.0 / del;
            }
            eval_caught(ode, time, &self.probe, &mut self.f)?;
            self.uncounted_calls += 1;
            for &col in group {
                let c = col as usize;
                for nz in pat.ap[c] as usize..pat.ap[c + 1] as usize {
                    let r = pat.ai[nz] as usize;
                    self.jac[nz] = (self.f[r] - self.fbase[r]) * self.inv_del[c];
                }
                self.probe[c] = y[c];
            }
        }
        Ok(())
    }

    /// C's `jacobian_DIRK_assemble` (`fac*J - I`) into system 0, factorized.
    fn factor_dirk(&mut self, fac: f64) -> i32 {
        let sys = self.sys.as_mut().expect("factor before the pattern");
        let ax = &mut self.real_jacs[0];
        ax.fill(0.0);
        for (nz, &to) in sys.pat.ode_to_nls.iter().enumerate() {
            ax[to as usize] = fac * self.jac[nz];
        }
        for &d in &sys.pat.diag {
            ax[d as usize] -= 1.0;
        }
        sys.factor_real(0, ax)
    }

    /// C's `jacobian_real_assemble` (`weight*I - J`) and
    /// `jacobian_cmplx_assemble` (`(wr + i*wi)*I - J`), each factorized.
    fn factor_transformed(&mut self, tr: &TTransform, inv_h: f64) -> i32 {
        let sys = self.sys.as_mut().expect("factor before the pattern");
        for e in 0..tr.n_real_eigenvalues {
            let weight = inv_h * tr.gamma[e];
            let ax = &mut self.real_jacs[e];
            ax.fill(0.0);
            for (nz, &to) in sys.pat.ode_to_nls.iter().enumerate() {
                ax[to as usize] = -self.jac[nz];
            }
            for &d in &sys.pat.diag {
                ax[d as usize] += weight;
            }
            let ret = sys.factor_real(e, ax);
            if ret < 0 {
                return ret;
            }
        }
        for e in 0..tr.n_complex_eigenpairs {
            let (wr, wi) = (inv_h * tr.alpha[e], inv_h * tr.beta[e]);
            let ax = &mut self.cmplx_jacs[e];
            ax.fill(0.0);
            for (nz, &to) in sys.pat.ode_to_nls.iter().enumerate() {
                ax[2 * to as usize] = -self.jac[nz];
            }
            for &d in &sys.pat.diag {
                ax[2 * d as usize] += wr;
                ax[2 * d as usize + 1] += wi;
            }
            let ret = sys.factor_cmplx(e, ax);
            if ret < 0 {
                return ret;
            }
        }
        0
    }

    /// C's `gbInternalSolveNls_DIRK`: solve stage `stage` of a DIRK method. `x`
    /// starts at the predicted stage value and holds the solution on return.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn solve_dirk(
        &mut self,
        ode: &mut dyn Ode,
        t: &Tableau,
        stage: usize,
        time: f64,
        step_size: f64,
        last_step_size: f64,
        y_old: &[f64],
        res_const: &[f64],
        x: &mut [f64],
        event_happened: bool,
        nominals: &[f64],
    ) -> Result<Solved> {
        self.ensure_systems(ode);
        self.make_scales(nominals, y_old, x);
        let is_esdirk = t.a_at(0, 0) == 0.0;
        let first_implicit = (stage == 0 && !is_esdirk) || (stage == 1 && is_esdirk);
        if first_implicit {
            let mut jac_called = false;
            if self.call_jac || event_happened {
                // C's `gbInternalEvaluateSimplifiedJacobian`.
                if !eval_at(&mut self.fast, ode, time, At::Left, y_old, &mut self.fbase)?
                    || !self.eval_jacobian(ode, time, y_old, nominals)?
                {
                    return Ok(Solved::Failed);
                }
                jac_called = true;
            }
            if (jac_called || step_size != last_step_size)
                && self.factor_dirk(step_size * t.a_at(stage, stage)) < 0
            {
                return Ok(Solved::Failed);
            }
        }
        if event_happened {
            self.etas[stage] = f64::MAX;
        }
        let stage_time = time + t.c[stage] * step_size;
        let fac = step_size * t.a_at(stage, stage);
        self.newton_scalar(ode, stage, At::Stage(stage), stage_time, fac, 1.0, res_const, x)
    }

    /// The `adams` corrector, residual `res_const - c[s-1]*x + h*b[s-1]*f(t + h, x)`,
    /// through the DIRK machinery. C assembles it from the all-zero `A` and so never
    /// factorizes; this assembles `h*b[s-1]*J - I` instead.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn solve_multistep(
        &mut self,
        ode: &mut dyn Ode,
        t: &Tableau,
        stage_time: f64,
        step_size: f64,
        last_step_size: f64,
        y_old: &[f64],
        res_const: &[f64],
        x: &mut [f64],
        event_happened: bool,
        nominals: &[f64],
    ) -> Result<Solved> {
        self.ensure_systems(ode);
        let last = t.n_stages - 1;
        self.make_scales(nominals, x, x);
        let gamma = t.b[last];
        let mut jac_called = false;
        if self.call_jac || event_happened {
            let t0 = stage_time - step_size;
            if !eval_at(&mut self.fast, ode, t0, At::Left, y_old, &mut self.fbase)?
                || !self.eval_jacobian(ode, t0, y_old, nominals)?
            {
                return Ok(Solved::Failed);
            }
            jac_called = true;
        }
        if (jac_called || step_size != last_step_size) && self.factor_dirk(step_size * gamma) < 0 {
            return Ok(Solved::Failed);
        }
        if event_happened {
            self.etas[0] = f64::MAX;
        }
        self.newton_scalar(ode, 0, At::Stage(0), stage_time, step_size * gamma, t.c[last], res_const, x)
    }

    /// The simplified Newton iteration of `gbInternalSolveNls_DIRK`, over the
    /// residual `res_const - c_scale*x + fac*f(stage_time, x)`.
    #[allow(clippy::too_many_arguments)]
    fn newton_scalar(
        &mut self,
        ode: &mut dyn Ode,
        stage: usize,
        at: At,
        stage_time: f64,
        fac: f64,
        c_scale: f64,
        res_const: &[f64],
        x: &mut [f64],
    ) -> Result<Solved> {
        let n = self.n;
        let mut nrm_delta = 0.0;
        let mut theta = 0.0;
        let mut newt_it = 1;
        loop {
            // C's `residual_DIRK`/`residual_MS` ignore `gbode_fODE`'s verdict.
            eval_at(&mut self.fast, ode, stage_time, at, x, &mut self.f)?;
            for i in 0..n {
                self.res[i] = res_const[i] - c_scale * x[i] + fac * self.f[i];
            }
            self.sys.as_mut().expect("solve before factor").solve_real(0, &mut self.res[..n]);
            for i in 0..n {
                x[i] -= self.res[i];
            }
            self.n_iters += 1;
            let nrm_delta_prev = f64::EPSILON.max(nrm_delta);
            nrm_delta = self.scaled_norm(&self.res, 1);
            let nrm_x = self.scaled_norm(x, 1);
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

    /// C's `gbInternalSolveNls_T_Transform`: the FIRK system decoupled by the
    /// tableau's T-transformation. `z` holds the stage values (`n_stages` blocks
    /// of the system's size), starting at the prediction; `k` receives the stage
    /// derivatives.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn solve_firk(
        &mut self,
        ode: &mut dyn Ode,
        t: &Tableau,
        time: f64,
        step_size: f64,
        last_step_size: f64,
        y_old: &[f64],
        z: &mut [f64],
        k: &mut [f64],
        event_happened: bool,
        nominals: &[f64],
    ) -> Result<Solved> {
        let Some(tr) = t.t_transform.as_ref() else {
            return Err("##GBODE## the internal solver needs the method's T-transformation");
        };
        self.ensure_systems(ode);
        let n = self.n;
        let inv_h = 1.0 / step_size;
        let tsize = tr.size;
        let off = usize::from(tr.first_row_zero);
        self.stage_time_0 = time;
        // C's scales: `nlsx` is `yOld`, `nlsxOld` the prediction.
        self.make_scales(nominals, y_old, &z[..n]);
        let mut jac_called = false;
        if self.call_jac || tr.first_row_zero || event_happened {
            if !eval_at(&mut self.fast, ode, time, At::Left, y_old, &mut self.fbase)? {
                return Ok(Solved::Failed);
            }
            if tr.first_row_zero {
                k[..n].copy_from_slice(&self.fbase);
            }
            if self.call_jac || event_happened {
                if !self.eval_jacobian(ode, time, y_old, nominals)? {
                    return Ok(Solved::Failed);
                }
                jac_called = true;
            }
        }
        if (jac_called || step_size != last_step_size) && self.factor_transformed(tr, inv_h) < 0 {
            return Ok(Solved::Failed);
        }
        // Z_j = X_start_j - yOld (C copies the guesses without the explicit-row
        // offset), W = (T^-1 otimes I) Z.
        for j in 0..tsize {
            for i in 0..n {
                self.tz[j * n + i] = z[j * n + i] - y_old[i];
            }
        }
        kron_vec(&tr.t_inv, tsize, n, &self.tz, &mut self.w);
        if tr.first_row_zero {
            self.k1.copy_from_slice(&k[..n]);
        }
        if event_happened {
            self.etas[0] = f64::MAX;
        }
        let mut nrm_delta = 0.0;
        let mut theta = 0.0;
        let mut newt_it = 1;
        loop {
            // F at the stage values yOld + Z_j.
            for j in 0..tsize {
                let st = time + t.c[j + off] * step_size;
                for i in 0..n {
                    self.probe[i] = y_old[i] + self.tz[j * n + i];
                }
                let at = At::Stage(j + off);
                if !eval_at(&mut self.fast, ode, st, at, &self.probe, &mut self.fw[j * n..(j + 1) * n])? {
                    return Ok(Solved::Failed);
                }
            }
            // res = (T^-1 otimes I)*F - 1/h*((Lambda+L) otimes I)*W (+ phi*k_1).
            kron_vec(&tr.t_inv, tsize, n, &self.fw, &mut self.res);
            scaled_transform_matvec(tr, n, -inv_h, &self.w, &mut self.res);
            if tr.first_row_zero {
                let phi = tr.phi.as_ref().expect("explicit first row without phi");
                for j in 0..tsize {
                    for i in 0..n {
                        self.res[j * n + i] += phi[j] * self.k1[i];
                    }
                }
            }
            self.forward_substitute(tr, inv_h);
            for i in 0..tsize * n {
                self.w[i] += self.res[i];
            }
            kron_vec(&tr.t, tsize, n, &self.w, &mut self.tz);
            self.n_iters += 1;
            let nrm_delta_prev = f64::EPSILON.max(nrm_delta);
            nrm_delta = self.scaled_norm(&self.res, tsize);
            let nrm_x = {
                let mut sum = 0.0;
                for j in 0..tsize {
                    for i in 0..n {
                        let v = (y_old[i] + self.tz[j * n + i]) * self.scal[i];
                        sum += v * v;
                    }
                }
                sqrt(sum / (n as f64 * tsize as f64))
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
                return self.finish_firk(ode, t, tr, step_size, y_old, z, k);
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

    /// The block-forward substitution of the transformed Newton step: each solved
    /// row feeds the `L` coupling of the ones below it.
    fn forward_substitute(&mut self, tr: &TTransform, inv_h: f64) {
        let n = self.n;
        let sys = self.sys.as_mut().expect("solve before factor");
        let res = &mut self.res;
        for row in 0..tr.n_real_blocks {
            if tr.has_l[row] {
                for col in 0..row {
                    add_l_coupling(res, n, row, col, -inv_h * tr.l[l_index(row, col)]);
                }
            }
            sys.solve_real(tr.real_eigenvalue_index[row], &mut res[row * n..(row + 1) * n]);
        }
        let mut cmplx_row = tr.n_real_blocks;
        for block in 0..tr.n_complex_blocks {
            for row in [cmplx_row, cmplx_row + 1] {
                if tr.has_l[row] {
                    for col in 0..cmplx_row {
                        add_l_coupling(res, n, row, col, -inv_h * tr.l[l_index(row, col)]);
                    }
                }
            }
            for i in 0..n {
                self.cres[2 * i] = res[cmplx_row * n + i];
                self.cres[2 * i + 1] = res[(cmplx_row + 1) * n + i];
            }
            sys.solve_cmplx(tr.complex_eigenpair_index[block], &mut self.cres);
            for i in 0..n {
                res[cmplx_row * n + i] = self.cres[2 * i];
                res[(cmplx_row + 1) * n + i] = self.cres[2 * i + 1];
            }
            cmplx_row += 2;
        }
    }

    /// The converged transformed solve: `X_j = yOld + Z_j` and
    /// `K = 1/h*(A_part^-1 otimes I)*Z (+ rho*k_1)`, rebuilt from the stage values
    /// rather than kept from the last iterate's `f(Z)` — that would carry the
    /// Newton residual amplified by `h*b^T*J`, an error the step size controller
    /// cannot shrink. An explicit last stage (Lobatto IIIB) is evaluated off the
    /// others.
    #[allow(clippy::too_many_arguments)]
    fn finish_firk(
        &mut self,
        ode: &mut dyn Ode,
        t: &Tableau,
        tr: &TTransform,
        step_size: f64,
        y_old: &[f64],
        z: &mut [f64],
        k: &mut [f64],
    ) -> Result<Solved> {
        let n = self.n;
        let tsize = tr.size;
        let off = usize::from(tr.first_row_zero);
        let inv_h = 1.0 / step_size;
        for j in 0..tsize {
            for i in 0..n {
                z[(j + off) * n + i] = self.tz[j * n + i] + y_old[i];
            }
        }
        kron_vec(&tr.a_part_inv, tsize, n, &self.tz, &mut k[off * n..(off + tsize) * n]);
        for v in &mut k[off * n..(off + tsize) * n] {
            *v *= inv_h;
        }
        if tr.first_row_zero {
            let rho = tr.rho.as_ref().expect("explicit first row without rho");
            for j in 0..tsize {
                for i in 0..n {
                    k[(off + j) * n + i] += rho[j] * self.k1[i];
                }
            }
            z[..n].copy_from_slice(y_old);
        }
        if tr.last_column_zero {
            let last = t.n_stages - 1;
            for i in 0..n {
                let mut v = y_old[i];
                for j in 0..last {
                    v += step_size * t.a_at(last, j) * k[j * n + i];
                }
                self.probe[i] = v;
            }
            let st = self.stage_time_0 + t.c[last] * step_size;
            if !eval_at(&mut self.fast, ode, st, At::Stage(last), &self.probe, &mut self.f)? {
                return Ok(Solved::Failed);
            }
            z[last * n..(last + 1) * n].copy_from_slice(&self.probe);
            k[last * n..(last + 1) * n].copy_from_slice(&self.f);
        }
        Ok(Solved::Ok)
    }

    /// C's `gbInternalContractiveDefect`: `err = (gamma/h*I - J)^-1 * (f(t_n, y_n) -
    /// d(0)^T*A*K)`, contracting with the first real system of the Newton solve.
    #[allow(clippy::too_many_arguments)]
    pub(super) fn contractive_defect(
        &mut self,
        ode: &mut dyn Ode,
        t: &Tableau,
        time: f64,
        y_old: &[f64],
        k: &[f64],
        f_left: Option<&[f64]>,
        err: &mut [f64],
    ) -> Result<()> {
        let n = self.n;
        let dt_a = t.contractive_dt_a.as_ref().expect("contractive defect without dT_A");
        for i in 0..n {
            let mut acc = 0.0;
            for (stage, &d) in dt_a.iter().enumerate().take(t.n_stages) {
                acc += k[stage * n + i] * d;
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
                eval_at(&mut self.fast, ode, time, At::Left, y_old, &mut self.f)?;
                for i in 0..n {
                    err[i] += self.f[i];
                }
            }
        }
        if let Some(sys) = self.sys.as_mut() {
            sys.solve_real(0, &mut err[..n]);
        }
        Ok(())
    }

    /// C's `gbInternalContractiveFilterError`: contract the embedded estimate in
    /// `err` with system 0 — `h*gamma*J - I` for a DIRK method, which is already
    /// the filter up to sign, `gamma/h*I - J` for a transformed one, scaled back
    /// by `gamma/h`.
    pub(super) fn contractive_filter(&mut self, t: &Tableau, step_size: f64, err: &mut [f64]) {
        let n = self.n;
        if let Some(sys) = self.sys.as_mut() {
            sys.solve_real(0, &mut err[..n]);
        }
        if let Some(tr) = t.t_transform.as_ref() {
            let scale = tr.gamma[0] / step_size;
            if scale != 1.0 {
                for v in &mut err[..n] {
                    *v *= scale;
                }
            }
        }
    }
}

/// C's `GBODE_L_INDEX`: `L` packed by row, strictly lower.
fn l_index(row: usize, col: usize) -> usize {
    row * (row - 1) / 2 + col
}

fn add_l_coupling(res: &mut [f64], n: usize, row: usize, col: usize, a: f64) {
    if a == 0.0 {
        return;
    }
    let (head, tail) = res.split_at_mut(row * n);
    for (r, c) in tail[..n].iter_mut().zip(&head[col * n..(col + 1) * n]) {
        *r += a * c;
    }
}

/// C's `dense_kron_id_vec`, `(M otimes I) * v` for `stack` blocks of `n`:
/// `out_j = sum_l M[j,l] * v_l`, with `M` row-major.
fn kron_vec(m: &[f64], stack: usize, n: usize, v: &[f64], out: &mut [f64]) {
    for j in 0..stack {
        let o = &mut out[j * n..(j + 1) * n];
        o.fill(0.0);
        for l in 0..stack {
            let a = m[j * stack + l];
            for (o, v) in o.iter_mut().zip(&v[l * n..(l + 1) * n]) {
                *o += a * v;
            }
        }
    }
}

/// C's `scaled_transform_matvec`: `out += factor * ((Lambda + L) otimes I) * v`,
/// with the 1x1 real rows, the 2x2 conjugate-pair blocks, and the strictly lower
/// couplings (rows without one skipped via `has_l`).
fn scaled_transform_matvec(tr: &TTransform, n: usize, factor: f64, v: &[f64], out: &mut [f64]) {
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
        let mb = -b;
        for i in 0..n {
            let (v0, v1) = (v[row * n + i], v[(row + 1) * n + i]);
            let o0 = out[row * n + i] + a * v0;
            out[row * n + i] = o0 + mb * v1;
            let o1 = out[(row + 1) * n + i] + a * v1;
            out[(row + 1) * n + i] = o1 + b * v0;
        }
        row += 2;
    }
    for row in 1..tr.size {
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
            add_l_coupling(out, n, row, col, factor * tr.l[l_index(row, col)]);
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
