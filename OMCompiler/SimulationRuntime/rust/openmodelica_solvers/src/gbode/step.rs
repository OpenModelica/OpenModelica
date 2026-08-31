//! One Runge-Kutta step (C's `gbode_step.c`) and the loop around it that accepts,
//! rejects and resizes steps (C's `gbode_main`).

use alloc::format;
use alloc::vec;

use super::conf::CtrlMethod;
use super::tableau::{GmType, SvpType};
use super::{ctrl, interp, Gbode, GbStep, Ode, GB_MINIMAL_STEP_SIZE};
use crate::Result;
use crate::gbode::math::{abs, pow, sqrt};
use crate::omclog;

impl Gbode {
    /// C's `expl_diag_impl_RK`: stage by stage, explicitly where the diagonal
    /// entry of `A` is zero and through the nonlinear solver where it is not.
    fn step_expl_diag_impl(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        let n = self.n_states;
        let n_stages = self.n_stages();
        for stage in 0..n_stages {
            self.act_stage = stage;
            // res_const = yOld + h*sum(A[stage,j]*k[j], j < stage)
            for i in 0..n {
                let mut v = self.y_old[i];
                for j in 0..stage {
                    v += self.step_size * self.tableau.a_at(stage, j) * self.k[j * n + i];
                }
                self.res_const[i] = v;
            }
            let stage_time = self.time + self.tableau.c[stage] * self.step_size;
            if self.tableau.a_at(stage, stage) == 0.0 {
                self.x[stage * n..(stage + 1) * n].copy_from_slice(&self.res_const);
                let mut f = vec![0.0; n];
                if self.tableau.k_left && stage == 0 && !self.did_fast_step {
                    f.copy_from_slice(&self.k_left);
                } else {
                    ode.eval(stage_time, &self.res_const, &mut f)?;
                }
                self.k[stage * n..(stage + 1) * n].copy_from_slice(&f);
                continue;
            }
            let mut guess = vec![0.0; n];
            self.stage_guess(stage, stage_time, &mut guess);
            let svp_linear = self.tableau.svp.as_ref().is_some_and(|svp| {
                svp.types[stage] == SvpType::LinearCombination
            });
            if self.multi_rate && self.n_fast > 0 && !svp_linear {
                for fi in 0..self.n_fast {
                    let i = self.fast_states_idx[fi];
                    guess[i] = self.y_old[i];
                }
            }
            let (time, step_size, event_happened) = (self.time, self.step_size, self.event_happened);
            let res_const = self.res_const.clone();
            let y_old = self.y_old.clone();
            let nominals = self.nominals.clone();
            if let Some(nls) = self.nls.as_mut() {
                let solved = nls.solve_dirk(
                    ode,
                    &self.tableau,
                    stage,
                    time,
                    step_size,
                    &y_old,
                    &res_const,
                    &mut guess,
                    event_happened,
                    &nominals,
                )?;
                if solved != super::Solved::Ok {
                    omclog::info(
                        omclog::SOLVER,
                        false,
                        &format!(
                            "gbode error: Failed to solve NLS in expl_diag_impl_RK in stage {} at time t={}",
                            stage + 1,
                            omclog::g(stage_time, 0, 6)
                        ),
                    );
                    return Ok(false);
                }
                self.x[stage * n..(stage + 1) * n].copy_from_slice(&guess);
                // Reconstruct k from the solution instead of calling functionODE again
                // (C does the same for every implicit stage of the internal solver).
                let ifac = 1.0 / (self.step_size * self.tableau.a_at(stage, stage));
                for i in 0..n {
                    self.k[stage * n + i] = ifac * (guess[i] - self.res_const[i]);
                }
            } else {
                // C's generic path: Newton starts from `yOld` and falls back to the
                // predicted stage value, and `k` is `f` at the accepted iterate.
                let fac = step_size * self.tableau.a_at(stage, stage);
                let mut resid = super::nls_generic::StageResidual {
                    stage_time,
                    fac,
                    c_scale: 1.0,
                    res_const: &res_const,
                };
                let mut x = vec![0.0; n];
                let gnls = self.gnls.as_mut().expect("implicit stage without an NLS");
                let solved = gnls.solve(
                    ode,
                    &mut resid,
                    stage_time,
                    &[&y_old, &guess],
                    &nominals,
                    &mut x,
                )?;
                if solved != super::Solved::Ok {
                    omclog::info(
                        omclog::SOLVER,
                        false,
                        &format!(
                            "gbode error: Failed to solve NLS in expl_diag_impl_RK in stage {} at time t={}",
                            stage + 1,
                            omclog::g(stage_time, 0, 6)
                        ),
                    );
                    return Ok(false);
                }
                self.x[stage * n..(stage + 1) * n].copy_from_slice(&x);
                let mut f = vec![0.0; n];
                ode.eval(stage_time, &x, &mut f)?;
                self.k[stage * n..(stage + 1) * n].copy_from_slice(&f);
            }
        }
        // y = yOld + h*sum(b[stage]*k[stage])
        for i in 0..n {
            let mut v = self.y_old[i];
            for stage in 0..n_stages {
                v += self.step_size * self.tableau.b[stage] * self.k[stage * n + i];
            }
            self.y[i] = v;
        }
        Ok(true)
    }

    /// The initial guess for the implicit stage `stage`, in C's priority order:
    /// a stage-value predictor, then dense output off the last step (internal
    /// solver only, as in C), then Hermite between the two previous stages, then
    /// the ring-buffer extrapolation.
    fn stage_guess(&mut self, stage: usize, stage_time: f64, guess: &mut [f64]) {
        let n = self.n_states;
        let dense_output_valid = self.time != self.start_time
            && !self.event_happened
            && self.nls.is_some()
            && self.extrapolation_base_time != f64::INFINITY;
        let svp_type = self.tableau.svp.as_ref().map(|s| s.types[stage]);
        match svp_type {
            Some(SvpType::LinearCombination) => {
                // C's `gbInternalLinearCombinationSVP`.
                let svp = self.tableau.svp.as_ref().unwrap();
                for i in 0..n {
                    let mut v = self.y_old[i];
                    for j in 0..stage {
                        v += self.step_size
                            * svp.a_predictor[stage * self.tableau.n_stages + j]
                            * self.k[j * n + i];
                    }
                    guess[i] = v;
                }
                return;
            }
            Some(SvpType::DenseOutput) if dense_output_valid => {
                let svp = self.tableau.svp.as_ref().unwrap();
                if let Some(f) = svp.dense_output_predictor {
                    let theta =
                        (stage_time - self.extrapolation_base_time) / self.extrapolation_step_size;
                    f(&mut self.b_dt, theta);
                    let scale = theta * self.extrapolation_step_size;
                    for i in 0..n {
                        let mut acc = 0.0;
                        for s in 0..self.tableau.n_stages {
                            acc += self.b_dt[s] * self.k_last[s * n + i];
                        }
                        guess[i] = self.y_last[i] + scale * acc;
                    }
                    return;
                }
            }
            _ => {}
        }
        if dense_output_valid && self.tableau.with_dense_output {
            let theta = (stage_time - self.extrapolation_base_time) / self.extrapolation_step_size;
            let (y_last, k_last) = (self.y_last.clone(), self.k_last.clone());
            self.tableau.dense_out(
                &mut self.b_dt,
                &y_last,
                &k_last,
                theta,
                self.extrapolation_step_size,
                guess,
                None,
                n,
            );
        } else if stage > 1 {
            let t0 = self.time + self.tableau.c[stage - 2] * self.step_size;
            let t1 = self.time + self.tableau.c[stage - 1] * self.step_size;
            interp::hermite(
                t0,
                &self.x[(stage - 2) * n..(stage - 1) * n],
                &self.k[(stage - 2) * n..(stage - 1) * n],
                t1,
                &self.x[(stage - 1) * n..stage * n],
                &self.k[(stage - 1) * n..stage * n],
                stage_time,
                guess,
                None,
                n,
            );
        } else {
            self.extrapolate(guess, stage_time);
        }
    }

    /// C's `full_implicit_RK`: all stages coupled in one nonlinear system.
    fn step_full_implicit(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        let n = self.n_states;
        let n_stages = self.n_stages();
        let mut z = vec![0.0; n * n_stages];
        // C's start values: the ring-buffer extrapolation, replaced by the dense
        // output off the last step where that is valid.
        let dense_output_valid = self.time != self.start_time
            && !self.event_happened
            && self.tableau.with_dense_output
            && self.nls.is_some()
            && self.extrapolation_base_time != f64::INFINITY;
        for stage in 0..n_stages {
            let stage_time = self.time + self.tableau.c[stage] * self.step_size;
            if dense_output_valid {
                let theta =
                    (stage_time - self.extrapolation_base_time) / self.extrapolation_step_size;
                let (y_last, k_last) = (self.y_last.clone(), self.k_last.clone());
                self.tableau.dense_out(
                    &mut self.b_dt,
                    &y_last,
                    &k_last,
                    theta,
                    self.extrapolation_step_size,
                    &mut z[stage * n..(stage + 1) * n],
                    None,
                    n,
                );
            } else {
                // C's `full_implicit_RK` starts the internal solver from `yOld`
                // when there is no valid dense output to extrapolate from.
                z[stage * n..(stage + 1) * n].copy_from_slice(&self.y_old);
            }
            // Zero-order hold for the fast states (C's `full_implicit_RK` with
            // multirate): extrapolation off slow data is a poor start for them.
            if self.multi_rate && self.n_fast > 0 {
                for fi in 0..self.n_fast {
                    let i = self.fast_states_idx[fi];
                    z[stage * n + i] = self.y_old[i];
                }
            }
        }
        let (time, step_size, event_happened) = (self.time, self.step_size, self.event_happened);
        let y_old = self.y_old.clone();
        let k_left = self.k_left.clone();
        let nominals = self.nominals.clone();
        let mut k = core::mem::take(&mut self.k);
        let solved = if let Some(nls) = self.nls.as_mut() {
            nls.solve_firk(
                ode,
                &self.tableau,
                time,
                step_size,
                &y_old,
                &k_left,
                &mut z,
                &mut k,
                event_happened,
                &nominals,
            )
        } else {
            // C's generic path: the primary start is the ring-buffer extrapolation
            // per stage (`nlsxExtrapolation`), the retry `yOld` everywhere.
            let mut z0 = vec![0.0; n * n_stages];
            for stage in 0..n_stages {
                let stage_time = time + self.tableau.c[stage] * step_size;
                let mut v = vec![0.0; n];
                self.extrapolate(&mut v, stage_time);
                z0[stage * n..(stage + 1) * n].copy_from_slice(&v);
            }
            let mut z1 = vec![0.0; n * n_stages];
            for stage in 0..n_stages {
                z1[stage * n..(stage + 1) * n].copy_from_slice(&y_old);
            }
            let mut resid = super::nls_generic::IrkResidual {
                t: &self.tableau,
                time,
                step_size,
                y_old: &y_old,
                k_left: &k_left,
                k: &mut k,
            };
            let gnls = self.gnls.as_mut().expect("implicit method without an NLS");
            gnls.solve(ode, &mut resid, time, &[&z0, &z1], &nominals, &mut z)
        };
        self.k = k;
        if solved? != super::Solved::Ok {
            omclog::info(
                omclog::SOLVER,
                false,
                &format!(
                    "gbode error: Failed to solve NLS in full_implicit_RK at time t={}",
                    omclog::g(self.time, 0, 6)
                ),
            );
            return Ok(false);
        }
        for i in 0..n {
            let mut v = self.y_old[i];
            for stage in 0..n_stages {
                v += self.step_size * self.tableau.b[stage] * self.k[stage * n + i];
            }
            self.y[i] = v;
        }
        self.x.copy_from_slice(&z);
        Ok(true)
    }

    /// C's `full_implicit_MS`: the `adams` multi-step method, predictor + one
    /// implicit corrector solve. The signed error estimate lands in `yt`.
    fn step_full_implicit_ms(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        let n = self.n_states;
        let n_stages = self.n_stages();
        let last = n_stages - 1;
        let bt = self.tableau.bt.clone().expect("adams tableau without bt");
        for i in 0..n {
            let mut v = 0.0;
            for stage in 0..last {
                v += -self.yv[stage * n + i] * self.tableau.c[stage]
                    + self.kv[stage * n + i] * bt[stage] * self.step_size;
            }
            v += self.kv[last * n + i] * bt[last] * self.step_size;
            self.yt[i] = v / self.tableau.c[last];
        }
        for i in 0..n {
            let mut v = 0.0;
            for stage in 0..last {
                v += -self.yv[stage * n + i] * self.tableau.c[stage]
                    + self.kv[stage * n + i] * self.tableau.b[stage] * self.step_size;
            }
            self.res_const[i] = v;
        }
        // 0 = res_const - c[last]*x + h*b[last]*f(t + h, x), i.e. the DIRK residual
        // scaled by c[last].
        let mut guess = self.yt.clone();
        let (time, step_size, event_happened) = (self.time, self.step_size, self.event_happened);
        let res_const = self.res_const.clone();
        let y_old = self.y_old.clone();
        let nominals = self.nominals.clone();
        let solved = if let Some(nls) = self.nls.as_mut() {
            nls.solve_multistep(
                ode,
                &self.tableau,
                time + step_size,
                step_size,
                &y_old,
                &res_const,
                &mut guess,
                event_happened,
                &nominals,
            )?
        } else {
            // C's generic path: every start vector is the predictor.
            let start = guess.clone();
            let mut resid = super::nls_generic::StageResidual {
                stage_time: time + step_size,
                fac: step_size * self.tableau.b[last],
                c_scale: self.tableau.c[last],
                res_const: &res_const,
            };
            let gnls = self.gnls.as_mut().expect("multi-step method without an NLS");
            gnls.solve(ode, &mut resid, time + step_size, &[&start], &nominals, &mut guess)?
        };
        if solved != super::Solved::Ok {
            omclog::info(
                omclog::SOLVER,
                false,
                &format!(
                    "gbode error: Failed to solve NLS in full_implicit_MS at time t={}",
                    omclog::g(self.time, 0, 6)
                ),
            );
            return Ok(false);
        }
        let mut f = vec![0.0; n];
        ode.eval(time + step_size, &guess, &mut f)?;
        self.kv[last * n..(last + 1) * n].copy_from_slice(&f);
        for i in 0..n {
            let mut v = 0.0;
            for stage in 0..last {
                v += -self.yv[stage * n + i] * self.tableau.c[stage]
                    + self.kv[stage * n + i] * self.tableau.b[stage] * self.step_size;
            }
            v += self.kv[last * n + i] * self.tableau.b[last] * self.step_size;
            self.y[i] = v / self.tableau.c[last];
            self.yt[i] = self.y[i] - self.yt[i];
        }
        Ok(true)
    }

    /// C's `gbode_richardson`: two half steps and one full step, extrapolated to
    /// the signed error estimate in `yt`.
    fn step_richardson(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        let n = self.n_states;
        let time_value = self.time;
        let step_size = self.step_size;
        let last_step_size = self.last_step_size;
        let p = self.tableau.order_b;
        if !self.is_explicit {
            self.tr[..2].copy_from_slice(&self.tv[..2]);
            self.yr[..2 * n].copy_from_slice(&self.yv[..2 * n]);
            self.kr[..2 * n].copy_from_slice(&self.kv[..2 * n]);
        }
        let mut outcome = false;
        self.step_size = step_size / 2.0;
        if self.dispatch_step(ode)? {
            self.time += self.step_size;
            self.last_step_size = self.step_size;
            self.y_old.copy_from_slice(&self.y);
            if !self.is_explicit {
                self.rotate_ring_for_richardson(ode, self.time)?;
            }
            if self.dispatch_step(ode)? {
                self.y1.copy_from_slice(&self.y);
                if !self.is_explicit {
                    let t = self.time + self.step_size;
                    self.tv[0] = self.time;
                    let mut f = vec![0.0; n];
                    let y = self.y.clone();
                    ode.eval(t, &y, &mut f)?;
                    self.yv[..n].copy_from_slice(&self.y);
                    self.kv[..n].copy_from_slice(&f);
                }
                self.time = time_value;
                self.step_size = step_size;
                self.last_step_size = last_step_size;
                self.y_old.copy_from_slice(&self.y_left);
                outcome = self.dispatch_step(ode)?;
            }
        }
        self.time = time_value;
        self.step_size = step_size;
        self.last_step_size = last_step_size;
        self.y_old.copy_from_slice(&self.y_left);
        if !self.is_explicit {
            self.tv[..2].copy_from_slice(&self.tr[..2]);
            self.yv[..2 * n].copy_from_slice(&self.yr[..2 * n]);
            self.kv[..2 * n].copy_from_slice(&self.kr[..2 * n]);
        }
        if outcome {
            let factor = pow(2.0, p as f64);
            for i in 0..n {
                let y_extrapolated = (factor * self.y1[i] - self.y[i]) / (factor - 1.0);
                self.yt[i] = self.y[i] - y_extrapolated;
            }
        }
        Ok(outcome)
    }

    /// The ring-buffer push C's Richardson step does between the two half steps.
    fn rotate_ring_for_richardson(&mut self, ode: &mut dyn Ode, t: f64) -> Result<()> {
        let n = self.n_states;
        let mut f = vec![0.0; n];
        let y = self.y.clone();
        ode.eval(t, &y, &mut f)?;
        self.tv[1] = self.tv[0];
        let (front, rest) = self.yv.split_at_mut(n);
        rest[..n].copy_from_slice(front);
        let (front, rest) = self.kv.split_at_mut(n);
        rest[..n].copy_from_slice(front);
        self.tv[0] = t;
        self.yv[..n].copy_from_slice(&self.y);
        self.kv[..n].copy_from_slice(&f);
        Ok(())
    }

    /// C's `gbData->step_fun`.
    fn dispatch_step(&mut self, ode: &mut dyn Ode) -> Result<bool> {
        match self.tableau.gm_type {
            GmType::Explicit | GmType::Dirk => self.step_expl_diag_impl(ode),
            GmType::Implicit => self.step_full_implicit(ode),
            GmType::MultiStep => self.step_full_implicit_ms(ode),
        }
    }

    /// Interpolate the last accepted step onto `t`, C's `gb_interpolation` with the
    /// solver's configured method.
    pub(super) fn interpolate_step(&mut self, t: f64, out: &mut [f64]) {
        self.interpolate_step_idx(t, out, None);
    }

    pub(super) fn interpolate_step_idx(&mut self, t: f64, out: &mut [f64], idx: Option<&[usize]>) {
        let n = self.n_states;
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
            t,
            out,
            idx,
            n,
            &self.tableau,
            &mut self.b_dt,
            &self.k,
        );
    }

    /// C's `gbode_main` for the single-rate case: integrate from wherever the
    /// solver is toward `target`, not stepping past `limit` (the next time event),
    /// and leave `(t, y)` either interpolated onto `target` or at the event found.
    #[allow(clippy::too_many_arguments)]
    pub fn step(
        &mut self,
        ode: &mut dyn Ode,
        target: f64,
        limit: f64,
        t: &mut f64,
        y: &mut [f64],
    ) -> Result<GbStep> {
        let n = self.n_states;
        let stop_time = self.stop_time;
        let mut target = target;
        let no_grid = crate::simflags::with_flags(|f| f.no_equidistant_grid);
        let const_step = self.conf.ctrl_method == CtrlMethod::Const;
        let int_with_err_ctrl = !const_step && self.conf.interpolation.is_err_ctrl();
        let calls_before = ode.calls();

        // C's `targetTime = fmin(gbData->eventTime, targetTime)`: an event located in
        // an earlier step but still ahead of the grid caps this call, so the run stops
        // on it instead of stepping on from the un-updated event state.
        if !no_grid {
            target = target.min(self.event_time);
        }

        // C's `saveZeroCrossings` in `simulationUpdate`: the crossing values at the
        // point the caller last emitted are the base this call compares against.
        self.latch_crossings_at(ode, *t, y)?;
        self.event_happened = self.did_event_step || self.is_first_step;
        if self.did_event_step || self.is_first_step {
            if self.no_restart && !self.is_first_step {
                self.time = self.time_right;
                self.step_size = self.opt_step_size;
            } else {
                let desired = self.desired_step_size;
                self.init_step_size(ode, *t, y, desired)?;
                self.init(ode)?;
            }
            self.is_first_step = false;
            self.did_event_step = false;
            if let Some(gbf) = self.gbf.as_mut() {
                gbf.did_event_step = true;
            }
        }
        if const_step {
            self.step_size = self.desired_step_size;
        }
        let mut retries = 0u32;

        // C's continuation block: an output point interrupted the inner (fast)
        // integration mid-interval, so finish it before stepping on.
        if self.multi_rate {
            let resume = {
                let gbf = self.gbf.as_ref().expect("multirate without gbf");
                self.n_fast > 0 && gbf.time < self.time_right && !gbf.did_event_step
            };
            if resume {
                match self.gbodef_main(ode, target)? {
                    super::multirate::InnerStep::Event(te) => {
                        *t = te;
                        y[..n].copy_from_slice(&self.y_old);
                        self.stats.calls_ode += ode.calls() - calls_before;
                        return Ok(GbStep::Root(te));
                    }
                    super::multirate::InnerStep::Done => {}
                }
                let synced = {
                    let gbf = self.gbf.as_ref().expect("multirate without gbf");
                    abs(self.time_right - gbf.time_right) < GB_MINIMAL_STEP_SIZE
                };
                if synced {
                    self.time = self.time_right;
                    let (gy, gyr, gkr, gerr) = {
                        let gbf = self.gbf.as_ref().expect("multirate without gbf");
                        (gbf.y.clone(), gbf.y_right.clone(), gbf.k_right.clone(), gbf.err.clone())
                    };
                    self.y.copy_from_slice(&gy);
                    self.y_old.copy_from_slice(&gy);
                    self.y_right.copy_from_slice(&gyr);
                    self.k_right.copy_from_slice(&gkr);
                    self.err.copy_from_slice(&gerr);
                    // The rest of the ring was already rotated for this step.
                    self.tv[0] = self.time_right;
                    self.yv[..n].copy_from_slice(&self.y_right);
                    self.kv[..n].copy_from_slice(&self.k_right);
                }
            }
        }

        while self.time < target {
            self.step_size = self.step_size.min(limit - self.time);
            self.step_size = self.step_size.min(stop_time - self.time);
            self.time_left = self.time_right;
            self.y_left.copy_from_slice(&self.y_right);
            self.k_left.copy_from_slice(&self.k_right);

            let mut err;
            loop {
                let stepped = if self.tableau.richardson {
                    self.step_richardson(ode)?
                } else {
                    self.dispatch_step(ode)?
                };
                if !stepped {
                    self.stats.convergence_test_failures += 1;
                    omclog::info(
                        omclog::SOLVER,
                        false,
                        &format!(
                            "gbode_main: Failed to calculate step at time = {} with step size h = {}.",
                            omclog::g(self.time, 0, 6),
                            omclog::g(self.step_size, 0, 6)
                        ),
                    );
                    if const_step {
                        return Err(GBODE_CONST_STEP_FAILED);
                    }
                    self.step_size *= if self.event_happened { 0.1 } else { 0.5 };
                    if self.step_size < GB_MINIMAL_STEP_SIZE {
                        return Err(GBODE_MIN_STEP_ERROR);
                    }
                    continue;
                }

                let est_order = self.estimate_error(ode)?;
                if est_order.is_none() {
                    self.stats.convergence_test_failures += 1;
                    if const_step {
                        return Err(GBODE_CONST_STEP_FAILED);
                    }
                    self.step_size *= 0.5;
                    if self.step_size < GB_MINIMAL_STEP_SIZE {
                        return Err(GBODE_MIN_STEP_ERROR);
                    }
                    continue;
                }
                let tol = self.scaled_error_tolerance();
                err = 0.0;
                for i in 0..n {
                    self.errtol[i] = tol * self.nominals[i]
                        + abs(self.y_old[i]).max(abs(self.y[i])) * tol;
                    if self.tableau.richardson || self.tableau.gm_type == GmType::MultiStep {
                        self.errest[i] = abs(self.yt[i]);
                    }
                    self.err[i] = self.tableau.fac * self.errest[i] / self.errtol[i];
                    err += self.err[i] * self.err[i];
                }
                err = sqrt(err / n as f64);

                if self.multi_rate {
                    // The error threshold splits the states into slow and fast.
                    err = self.error_threshold();
                    self.n_fast = 0;
                    self.n_slow = 0;
                    self.err_slow = 0.0;
                    self.err_fast = 0.0;
                    self.err_int = 0.0;
                    for i in 0..n {
                        if self.err[i] >= 1.0 {
                            self.fast_states_idx[self.n_fast] = i;
                            self.n_fast += 1;
                            self.err_fast = self.err_fast.max(self.err[i]);
                        } else {
                            self.slow_states_idx[self.n_slow] = i;
                            self.n_slow += 1;
                            self.err_slow = self.err_slow.max(self.err[i]);
                        }
                    }
                }

                if err > 1.0 && !const_step {
                    omclog::info(
                        omclog::SOLVER,
                        false,
                        &format!(
                            "Reject step from {} to {}, error {}, new stepsize {}",
                            omclog::g(self.time, 0, 16),
                            omclog::g(self.time + self.step_size, 0, 16),
                            omclog::g(err, 0, 16),
                            omclog::g(self.step_size * 0.5, 0, 16)
                        ),
                    );
                    self.stats.err_test_failures += 1;
                    self.step_size *= if self.event_happened { 0.1 } else { 0.5 };
                    continue;
                }

                self.time_right = self.time + self.step_size;
                self.y_right.copy_from_slice(&self.y);
                if !self.tableau.k_right {
                    let mut f = vec![0.0; n];
                    let yr = self.y_right.clone();
                    ode.eval(self.time_right, &yr, &mut f)?;
                    self.k_right.copy_from_slice(&f);
                } else {
                    let s = self.n_stages() - 1;
                    self.k_right.copy_from_slice(&self.k[s * n..(s + 1) * n]);
                }

                if int_with_err_ctrl {
                    let idx = (self.multi_rate && self.n_fast > 0)
                        .then(|| self.slow_states_idx[..self.n_slow].to_vec());
                    self.err_int = self.error_interpolation(tol, idx.as_deref());
                    if self.err_int > 1.0 {
                        retries += 1;
                        self.stats.err_test_failures += 1;
                        self.step_size *= 0.5;
                        if self.step_size < GB_MINIMAL_STEP_SIZE {
                            return Err(GBODE_MIN_INTERP_ERROR);
                        }
                        omclog::info(
                            omclog::SOLVER,
                            false,
                            &format!(
                                "Reject step from {} to {}, error {}, interpolation error {}, new stepsize {}",
                                omclog::g(self.time, 0, 16),
                                omclog::g(self.time + self.step_size, 0, 16),
                                omclog::g(err, 0, 16),
                                omclog::g(self.err_int, 0, 16),
                                omclog::g(self.step_size, 0, 16)
                            ),
                        );
                        continue;
                    }
                    retries = 0;
                } else {
                    let _ = retries;
                }

                // Accepted.
                self.extrapolation_base_time = self.time;
                self.extrapolation_step_size = self.step_size;
                self.event_happened = false;
                self.did_fast_step = false;
                self.k_last.copy_from_slice(&self.k);
                self.y_last.copy_from_slice(&self.y_old);
                for i in (1..self.ring_buffer_size).rev() {
                    self.err_values[i] = self.err_values[i - 1];
                    self.step_size_values[i] = self.step_size_values[i - 1];
                }
                self.err_values[0] = err;
                self.step_size_values[0] = self.step_size;
                self.last_step_size = self.step_size;
                self.step_size *= ctrl::generic_controller(
                    &self.err_values,
                    &self.step_size_values,
                    self.current_error_order,
                    &self.conf,
                );
                if self.max_step_size > 0.0 && self.max_step_size < self.step_size {
                    self.step_size = self.max_step_size;
                }
                self.opt_step_size = self.step_size;
                if self.multi_rate && self.n_fast > 0 {
                    match self.gbodef_main(ode, target)? {
                        super::multirate::InnerStep::Event(te) => {
                            *t = te;
                            y[..n].copy_from_slice(&self.y_old);
                            self.stats.calls_ode += ode.calls() - calls_before;
                            return Ok(GbStep::Root(te));
                        }
                        super::multirate::InnerStep::Done => {}
                    }
                    let synced = {
                        let gbf = self.gbf.as_ref().expect("multirate without gbf");
                        abs(self.time_right - gbf.time_right) < GB_MINIMAL_STEP_SIZE
                    };
                    if synced {
                        let (gy, gyr, gerr) = {
                            let gbf = self.gbf.as_ref().expect("multirate without gbf");
                            (gbf.y.clone(), gbf.y_right.clone(), gbf.err.clone())
                        };
                        self.y.copy_from_slice(&gy);
                        self.y_right.copy_from_slice(&gyr);
                        self.err.copy_from_slice(&gerr);
                        let mut f = vec![0.0; n];
                        let yr = self.y_right.clone();
                        ode.eval(self.time_right, &yr, &mut f)?;
                        self.k_right.copy_from_slice(&f);
                    }
                }
                break;
            }

            self.stats.steps += 1;

            let check_events = !self.multi_rate
                || self.gbf.as_ref().expect("multirate without gbf").time < self.time;
            if check_events
                && let Some(event_time) = self.check_for_events(ode)? {
                self.time = event_time;
                self.event_happened = true;
                let mut y_ev = vec![0.0; n];
                self.interpolate_step(event_time, &mut y_ev);
                self.y_old.copy_from_slice(&y_ev);
                self.event_time = event_time;
                target = target.min(event_time);
                break;
            }

            omclog::info(
                omclog::SOLVER,
                false,
                &format!(
                    "Accept step from {} to {}, error {} interpolation error {}, new stepsize {}",
                    omclog::g(self.time_left, 0, 16),
                    omclog::g(self.time_right, 0, 16),
                    omclog::g(err, 0, 16),
                    omclog::g(self.err_int, 0, 16),
                    omclog::g(self.step_size, 0, 16)
                ),
            );
            self.time = self.time_right;
            self.y_old.copy_from_slice(&self.y_right);
            for i in (1..self.ring_buffer_size).rev() {
                self.tv[i] = self.tv[i - 1];
                let (dst, src) = (i * n, (i - 1) * n);
                self.yv.copy_within(src..src + n, dst);
                self.kv.copy_within(src..src + n, dst);
            }
            self.tv[0] = self.time_right;
            self.yv[..n].copy_from_slice(&self.y_right);
            self.kv[..n].copy_from_slice(&self.k_right);

            if no_grid {
                *t = self.time;
                y[..n].copy_from_slice(&self.y);
                self.stats.calls_ode += ode.calls() - calls_before;
                return Ok(GbStep::Stepped);
            }
            if stop_time - self.time < GB_MINIMAL_STEP_SIZE {
                self.time = stop_time;
                break;
            }
        }

        // An event landed on the target: hand the states at the event to the caller
        // for the discrete update.
        if self.event_time == target {
            *t = self.time;
            y[..n].copy_from_slice(&self.y_old);
            let event_time = self.event_time;
            self.event_time = f64::MAX;
            self.stats.calls_ode += ode.calls() - calls_before;
            if self.no_restart {
                self.time_right = self.time;
                self.y_right.copy_from_slice(&self.y_old);
                let mut f = vec![0.0; n];
                let yr = self.y_right.clone();
                ode.eval(self.time, &yr, &mut f)?;
                self.k_right.copy_from_slice(&f);
            }
            return Ok(GbStep::Root(event_time));
        }

        // C names the method in the statistics block, on the run's last output step.
        if !no_grid && abs(target - stop_time) < GB_MINIMAL_STEP_SIZE {
            if self.multi_rate {
                let fast = self.gbf.as_ref().expect("multirate without gbf").conf.method_name();
                omclog::info(
                    omclog::STATS,
                    false,
                    &format!(
                        "gbode (birate integration): slow: {} / fast: {}",
                        self.conf.method_name(),
                        fast
                    ),
                );
            } else {
                omclog::info(
                    omclog::STATS,
                    false,
                    &format!("gbode (single-rate integration): {}", self.conf.method_name()),
                );
            }
        }
        let out_time = target.min(stop_time);
        let mut out = vec![0.0; n];
        if self.multi_rate
            && self.gbf.as_ref().expect("multirate without gbf").time >= out_time
        {
            // Slow states from the outer interval, fast states from the inner one.
            let slow = self.slow_states_idx[..self.n_slow].to_vec();
            self.interpolate_step_idx(out_time, &mut out, Some(&slow));
            let fast = self.fast_states_idx[..self.n_fast].to_vec();
            self.interpolate_gbf_idx(out_time, &mut out, Some(&fast));
        } else {
            self.interpolate_step(out_time, &mut out);
        }
        *t = out_time;
        y[..n].copy_from_slice(&out);
        self.stats.calls_ode += ode.calls() - calls_before;
        Ok(GbStep::Reached)
    }
}

const GBODE_CONST_STEP_FAILED: &str = "CodegenWasmJit: gbode is running with a fixed step size and \
                                       the step calculation failed";
pub(super) const GBODE_MIN_STEP_ERROR: &str =
    "CodegenWasmJit: gbode reached the minimum step size, but the error is still too large";
const GBODE_MIN_INTERP_ERROR: &str = "CodegenWasmJit: gbode reached the minimum step size, but the \
                                      interpolation error is still too large";

#[cfg(test)]
mod tests {
    use super::*;

    /// A bouncing ball as the two functions gbode calls.
    struct Ball {
        calls: u64,
        nominals: [f64; 2],
    }

    const G: f64 = 9.81;

    impl Ode for Ball {
        fn eval(&mut self, _t: f64, y: &[f64], f: &mut [f64]) -> Result<()> {
            self.calls += 1;
            f[0] = y[1];
            f[1] = -G;
            Ok(())
        }
        fn eval_zc(&mut self, _t: f64, y: &[f64], zc: &mut [f64]) -> Result<()> {
            // The codegen emits crossings as ±1, not the relation expression.
            zc[0] = if y[0] > 0.0 { 1.0 } else { -1.0 };
            Ok(())
        }
        fn nominals(&self) -> &[f64] {
            &self.nominals
        }
        fn calls(&self) -> u64 {
            self.calls
        }
    }

    /// An event located inside an already-taken step must be reported once the grid
    /// reaches it. Without the cap the run steps on from the event state with no
    /// discrete update, which here wedges the interpolation-error control.
    #[test]
    fn pending_event_is_reported_when_the_grid_reaches_it() {
        let dt = 2e-3;
        let mut gb = Gbode::new(2, 1e-6, 1, 0, false).expect("allocate");
        gb.set_experiment(0.0, 1.0, dt);
        gb.set_nominals(&[1.0, 1.0]);
        let mut e = Ball { calls: 0, nominals: [1.0, 1.0] };
        let mut y = [1.0, 0.0]; // h = 1, v = 0
        let mut t = 0.0;
        let mut events = alloc::vec::Vec::new();
        for k in 1..=500 {
            let target = k as f64 * dt;
            while t < target - 1e-12 {
                match gb.step(&mut e, target, f64::INFINITY, &mut t, &mut y).expect("step") {
                    GbStep::Root(te) => {
                        events.push(te);
                        y[1] = -0.7 * y[1]; // the model's reinit at the bounce
                        gb.restart();
                    }
                    GbStep::Reached | GbStep::Stepped => break,
                }
            }
        }
        // First bounce of a ball dropped from h=1: t = sqrt(2/g).
        assert!(!events.is_empty(), "no event located");
        assert!(
            (events[0] - (2.0 / G).sqrt()).abs() < 1e-9,
            "first bounce at {} not sqrt(2/g)",
            events[0]
        );
        assert!(t >= 1.0 - dt, "run stopped early at {t}");
    }
}
