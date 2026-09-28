//! The generic gbode nonlinear solvers (`-gbnls=newton`/`kinsol`), C's
//! `gbode_nls.c` residuals under `solveNLS_gb`. The stage systems are the same
//! ones the internal solver iterates on; the difference is the solver: C hands
//! them to the runtime's NLS machinery (dense damped Newton, or KINSOL over KLU),
//! which solves to the tight `newtonFTol` instead of the internal solver's
//! integrator-scaled target, evaluates `f` at the accepted iterate rather than
//! reconstructing `k`, and retries from other start points on failure.
//!
//! A host that links the runtime's nonlinear solvers registers them
//! ([`super::nls_hook`]) and gets C's KINSOL and Newton; without one, both
//! `-gbnls` values run the damped Newton here over [`super::linsol`].

use alloc::vec;
use alloc::vec::Vec;

use super::Solved;
use super::nls_hook::{self, GbNlsHook, GbNlsRequest, KinsolParams, NlsMethod, NlsPattern};
use super::tableau::Tableau;
use crate::gbode::math::{abs, pow, sqrt};
use crate::{Ode, Result};

/// C's `newtonFTol` (`model_help.c`).
const NEWTON_FTOL_DEFAULT: f64 = 1e-12;
/// C's `DEFAULT_FLAG_NEWTON_MAX_STEPS`.
const NEWTON_MAX_STEPS: u32 = 20;

/// `-gbnls=kinsol`'s phases in C's `solveNLS_gb`: `-newtonMaxSteps` and the
/// `-newtonJacUpdates` refresh interval of each phase (0 skips it).
#[derive(Clone, Copy)]
pub(super) struct KinsolLadder {
    pub max_steps: u32,
    pub jac_updates: [u32; 4],
    /// `max(newtonFTol, newtonXTol)`.
    pub tol: f64,
}

impl KinsolLadder {
    pub(super) fn from_flags() -> Self {
        crate::simflags::with_flags(|f| {
            let (max_steps, jac_updates) = crate::simflags::gb_kinsol_tuning(f);
            let (ftol, xtol, _) = crate::simflags::newton_tuning(f);
            KinsolLadder { max_steps, jac_updates, tol: ftol.max(xtol) }
        })
    }
}

/// One residual evaluation: fill `res` at the iterate `x`, leaving the stage
/// derivatives wherever the caller wants them.
pub(super) trait GbResidual {
    fn eval(&mut self, ode: &mut dyn Ode, x: &[f64], res: &mut [f64]) -> Result<()>;
    /// Assemble the residual's Jacobian into `jac` (column-major `size*size`)
    /// from the ODE Jacobian `j` (column-major `n_states*n_states`).
    fn assemble(&self, j: &[f64], n_states: usize, jac: &mut [f64]);
    /// C's `sparsePattern_NLS` for this system.
    fn pattern(&self, rows_by_col: &[Vec<usize>], colors: &[Vec<u32>]) -> NlsPattern;
    /// C's symbolic `jacobian_*_column` into `pat`'s CSC values; `false` without one.
    fn csc_jacobian(&mut self, ode: &mut dyn Ode, x: &[f64], nlsx: &[f64], pat: &NlsPattern, vals: &mut [f64])
    -> bool;
}

/// C's `nlsxExtrapolation`, `nlsxOld` and `nlsx` for one solve.
pub(super) struct Starts<'a> {
    pub extrapolation: &'a [f64],
    pub old: &'a [f64],
    pub nlsx: &'a [f64],
}

/// `res = res_const - c_scale*x + fac*f(stage_time, x)`: a DIRK stage
/// (`residual_DIRK`, `c_scale` 1) or the multi-step corrector (`residual_MS`,
/// `c_scale` the last `c`).
pub(super) struct StageResidual<'a> {
    pub stage_time: f64,
    pub fac: f64,
    pub c_scale: f64,
    pub res_const: &'a [f64],
    /// `f` of the last evaluation, which is C's stage derivative (`fODE`).
    pub last_f: Vec<f64>,
}

impl GbResidual for StageResidual<'_> {
    fn eval(&mut self, ode: &mut dyn Ode, x: &[f64], res: &mut [f64]) -> Result<()> {
        let n = x.len();
        self.last_f.resize(n, 0.0);
        ode.eval(self.stage_time, x, &mut self.last_f)?;
        for i in 0..n {
            res[i] = self.res_const[i] - self.c_scale * x[i] + self.fac * self.last_f[i];
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

    fn pattern(&self, rows_by_col: &[Vec<usize>], colors: &[Vec<u32>]) -> NlsPattern {
        NlsPattern::with_diagonal(rows_by_col, colors)
    }

    /// C's `jacobian_SR_column`: `-I` also for the multi-step corrector.
    fn csc_jacobian(&mut self, ode: &mut dyn Ode, x: &[f64], _nlsx: &[f64], pat: &NlsPattern, vals: &mut [f64])
    -> bool {
        let n = x.len();
        let mut seed = vec![0.0; n];
        let mut out = vec![0.0; n];
        for group in &pat.groups {
            seed.fill(0.0);
            for &c in group {
                seed[c] = 1.0;
            }
            if !ode.jacobian_vector(self.stage_time, x, &seed, &mut out) {
                return false;
            }
            for &c in group {
                for k in pat.colptr[c] as usize..pat.colptr[c + 1] as usize {
                    let r = pat.rowidx[k] as usize;
                    vals[k] = self.fac * out[r] - seed[r];
                }
            }
        }
        true
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

    fn pattern(&self, rows_by_col: &[Vec<usize>], _colors: &[Vec<u32>]) -> NlsPattern {
        NlsPattern::irk(rows_by_col, self.t)
    }

    /// C's `jacobian_IRK_column`, which takes the ODE Jacobian of a colour's stage
    /// at that stage's `nlsx`, not at the iterate.
    fn csc_jacobian(&mut self, ode: &mut dyn Ode, _x: &[f64], nlsx: &[f64], pat: &NlsPattern, vals: &mut [f64])
    -> bool {
        let n = self.y_old.len();
        let s = self.t.n_stages;
        let mut seed = vec![0.0; n * s];
        let mut seed_ode = vec![0.0; n];
        let mut out = vec![0.0; n];
        for group in &pat.groups {
            let Some(&last) = group.iter().max() else { continue };
            let stage_ = last / n;
            seed.fill(0.0);
            seed_ode.fill(0.0);
            for &c in group {
                seed[c] = 1.0;
                seed_ode[c % n] = 1.0;
            }
            let t = self.time + self.t.c[stage_] * self.step_size;
            if !ode.jacobian_vector(t, &nlsx[stage_ * n..(stage_ + 1) * n], &seed_ode, &mut out) {
                return false;
            }
            for &c in group {
                for k in pat.colptr[c] as usize..pat.colptr[c + 1] as usize {
                    let r = pat.rowidx[k] as usize;
                    vals[k] = self.step_size * self.t.a_at(r / n, stage_) * out[r % n] - seed[r];
                }
            }
        }
        true
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
    method: NlsMethod,
    kinsol: Option<KinsolLadder>,
    pattern: Option<NlsPattern>,
}

impl GbNlsGeneric {
    pub(super) fn new(t: &Tableau, n_states: usize, sym_jac: bool, method: NlsMethod) -> Self {
        let kinsol =
            matches!(method, NlsMethod::Kinsol | NlsMethod::KinsolB).then(KinsolLadder::from_flags);
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
            method,
            kinsol,
            pattern: None,
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
        starts: &Starts,
        nominals: &[f64],
        x: &mut [f64],
    ) -> Result<Solved> {
        if let Some(hook) = nls_hook::nls_hook() {
            return Ok(self.solve_hooked(hook, ode, res, starts, nominals, x));
        }
        if let Some(ladder) = self.kinsol {
            return Ok(self.solve_kinsol(ode, res, jac_time, starts, x, ladder));
        }
        let size = self.size;
        let n = self.n_states;
        // C's retries: the start vectors, then +1% nominal, then the nominals.
        let mut attempts: Vec<Vec<f64>> = vec![starts.extrapolation.to_vec()];
        if starts.old != starts.extrapolation {
            attempts.push(starts.old.to_vec());
        }
        let mut v = starts.old.to_vec();
        for i in 0..size {
            v[i] += nominals[i % n] * 0.01;
        }
        attempts.push(v);
        attempts.push((0..size).map(|i| nominals[i % n]).collect());
        // C's `retries2`: relax the tolerance tenfold, up to four times.
        for relax in 0..5 {
            let tol = self.ftol * pow(10.0, relax as f64);
            for start in &attempts {
                x.copy_from_slice(start);
                if self.newton(ode, res, jac_time, x, tol, NEWTON_MAX_STEPS, u32::MAX, true) {
                    return Ok(Solved::Ok);
                }
            }
        }
        Ok(Solved::Failed)
    }

    fn solve_hooked(
        &mut self,
        hook: GbNlsHook,
        ode: &mut dyn Ode,
        res: &mut dyn GbResidual,
        starts: &Starts,
        nominals: &[f64],
        x: &mut [f64],
    ) -> Solved {
        let (size, n) = (self.size, self.n_states);
        if self.pattern.is_none() {
            let rows = nls_hook::ode_rows_by_col(ode.jac_rows_by_col(), n);
            self.pattern = Some(res.pattern(&rows, ode.jac_colors()));
        }
        let pat = self.pattern.as_ref().expect("built above");
        let per_state = |v: &[f64], fallback: f64| -> Vec<f64> {
            (0..size).map(|i| v.get(i % n).copied().unwrap_or(fallback)).collect()
        };
        let nominal = per_state(nominals, 1.0);
        let min = per_state(ode.mins(), -f64::MAX);
        let max = per_state(ode.maxs(), f64::MAX);
        let sym = self.sym_jac && ode.has_jacobian_vector();
        let jac_evals = core::cell::Cell::new(0u64);
        let solved = {
            let failed = core::cell::Cell::new(false);
            let cell = core::cell::RefCell::new((ode, res));
            let mut eval = |xs: &[f64], r: &mut [f64]| {
                if !failed.get() {
                    let (ode, res) = &mut *cell.borrow_mut();
                    failed.set(res.eval(&mut **ode, xs, r).is_err());
                }
                if failed.get() {
                    r.fill(f64::NAN);
                }
            };
            let mut jac = |xs: &[f64], vals: &mut [f64]| {
                let (ode, res) = &mut *cell.borrow_mut();
                if !res.csc_jacobian(&mut **ode, xs, starts.nlsx, pat, vals) {
                    failed.set(true);
                    vals.fill(f64::NAN);
                }
            };
            let method = self.method;
            let mut run = |start: &[f64], kinsol: KinsolParams, x: &mut [f64]| -> bool {
                failed.set(false);
                let mut req = GbNlsRequest {
                    method,
                    handle: 0,
                    n: size,
                    colptr: &pat.colptr,
                    rowidx: &pat.rowidx,
                    colors: &pat.colors,
                    nominal: &nominal,
                    min: &min,
                    max: &max,
                    start,
                    old: starts.old,
                    x,
                    kinsol,
                    time: 0.0,
                    eval: &mut eval,
                    jacobian: if sym { Some(&mut jac as &mut dyn FnMut(&[f64], &mut [f64])) } else { None },
                    jac_evals: 0,
                };
                let ok = hook(&mut req) && !failed.get();
                jac_evals.set(jac_evals.get() + req.jac_evals);
                ok
            };
            x.copy_from_slice(starts.nlsx);
            match self.kinsol {
                None => run(starts.extrapolation, kinsol_ladder_params(0, 0, 0.0, false), x),
                Some(ladder) => kinsol_ladder(&ladder, size, starts, x, &mut run),
            }
        };
        self.n_jac_evals += jac_evals.get();
        if solved { Solved::Ok } else { Solved::Failed }
    }

    /// The KINSOL phases with the damped Newton, for hosts without KINSOL.
    fn solve_kinsol(
        &mut self,
        ode: &mut dyn Ode,
        res: &mut dyn GbResidual,
        jac_time: f64,
        starts: &Starts,
        x: &mut [f64],
        ladder: KinsolLadder,
    ) -> Solved {
        let later_steps = ladder.max_steps.max(10 * self.size as u32);
        let phases: [(&[f64], u32, bool, f64); 4] = [
            (starts.extrapolation, ladder.max_steps, false, ladder.tol),
            (starts.extrapolation, later_steps, true, ladder.tol),
            (starts.old, later_steps, true, ladder.tol),
            (starts.nlsx, later_steps, true, 10.0 * ladder.tol),
        ];
        for (&(start, steps, fresh, tol), &every) in phases.iter().zip(ladder.jac_updates.iter()) {
            if every == 0 {
                continue;
            }
            x.copy_from_slice(start);
            if self.newton(ode, res, jac_time, x, tol, steps, every, fresh) {
                return Solved::Ok;
            }
        }
        Solved::Failed
    }

    /// Damped Newton from `x` to `tol`, refreshing the Jacobian at the start when
    /// `fresh`, after a damped step and every `refresh_every` iterations.
    #[allow(clippy::too_many_arguments)]
    fn newton(
        &mut self,
        ode: &mut dyn Ode,
        res: &mut dyn GbResidual,
        jac_time: f64,
        x: &mut [f64],
        tol: f64,
        max_steps: u32,
        refresh_every: u32,
        fresh: bool,
    ) -> bool {
        let size = self.size;
        let n = self.n_states;
        let mut r = vec![0.0; size];
        let mut r_new = vec![0.0; size];
        let mut x_try = vec![0.0; size];
        if res.eval(ode, x, &mut r).is_err() {
            return false;
        }
        let mut nrm = enorm(&r);
        if !nrm.is_finite() {
            return false;
        }
        if (fresh || self.factored.is_none())
            && self.factor_at(ode, res, jac_time, &x[..n.min(size)]).is_err()
        {
            return false;
        }
        let mut converged = nrm <= tol || self.scaled_norm(&r) <= tol;
        let mut stale = false;
        let mut since_refresh = 0u32;
        'newton: for _ in 0..max_steps {
            if converged {
                break;
            }
            // C recomputes the Jacobian only when the iteration struggles.
            if stale || since_refresh >= refresh_every {
                if self.factor_at(ode, res, jac_time, &x[..n.min(size)]).is_err() {
                    break 'newton;
                }
                since_refresh = 0;
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
            since_refresh += 1;
            converged = nrm <= tol || self.scaled_norm(&r) <= tol;
        }
        converged
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

fn kinsol_ladder_params(max_iters: u32, max_setup_calls: u32, fnorm_tol: f64, no_init_setup: bool) -> KinsolParams {
    KinsolParams { max_iters, no_init_setup, max_setup_calls, fnorm_tol }
}

/// C's `solveNLS_gb` phases for KINSOL: from the extrapolation reusing the last
/// Jacobian, with a fresh one, from `nlsxOld`, and from `nlsx` at a tenfold
/// tolerance. A phase whose `-newtonJacUpdates` entry is 0 is skipped.
pub(super) fn kinsol_ladder(
    ladder: &KinsolLadder,
    size: usize,
    starts: &Starts,
    x: &mut [f64],
    run: &mut dyn FnMut(&[f64], KinsolParams, &mut [f64]) -> bool,
) -> bool {
    use crate::omclog::{self, GBODE_NLS};
    let later = ladder.max_steps.max(10 * size as u32);
    let [u0, u1, u2, u3] = ladder.jac_updates;
    if u0 > 0 && run(starts.extrapolation, kinsol_ladder_params(ladder.max_steps, u0, ladder.tol, true), x) {
        return true;
    }
    if u1 > 0 {
        if u0 > 0 {
            omclog::info(GBODE_NLS, false, "GBODE: Solution of NLS failed. Try with updated Jacobian.");
        }
        if run(starts.extrapolation, kinsol_ladder_params(later, u1, ladder.tol, false), x) {
            return true;
        }
    }
    if u2 > 0 {
        omclog::info(GBODE_NLS, false, "GBODE: Solution of NLS failed, Try with extrapolated start value.");
        if run(starts.old, kinsol_ladder_params(later, u2, ladder.tol, false), x) {
            return true;
        }
    }
    if u3 > 0 {
        omclog::info(omclog::STDOUT, false, "GBODE: Solution of NLS failed, Try with less accuracy.");
        let nlsx = x.to_vec();
        if run(&nlsx, kinsol_ladder_params(later, u3, 10.0 * ladder.tol, false), x) {
            return true;
        }
    }
    false
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
