//! `-s=gbode`, the generic Runge-Kutta ODE solver — a port of the single-rate part
//! of C's `gbode_main.c`, `gbode_step.c`, `gbode_err.c` and `gbode_events.c`.
//!
//! gbode takes its own steps, controls their size from an error estimate, locates
//! the events it steps over by bisecting its own interpolant, and interpolates the
//! result onto the output grid. [`Gbode::step`] is one `gbode_main` call: integrate
//! from wherever the solver is toward `target`, then either interpolate onto
//! `target` or report the event found on the way — which is how the C runtime's main
//! loop drives it, so [`crate::driver`]'s event handling takes over from there
//! unchanged.
//!
//! The birate (`-gbratio`) mode lives in [`multirate`], the generic
//! (`-gbnls=newton`/`kinsol`) solvers in [`nls_generic`], and the FIRK
//! T-transformation decoupling in [`nls`].

mod conf;
mod ctrl;
mod interp;
mod linsol;
mod math;
mod multirate;
mod nls;
mod nls_generic;
mod tableau;
mod tableau_data;

use alloc::format;
use alloc::string::String;
use alloc::vec;
use alloc::vec::Vec;

pub use conf::GbConf;
use conf::{Interpolation, NlsMethod};
pub use crate::Ode;
pub(crate) use nls::Solved;
use nls::GbNls;
use nls_generic::GbNlsGeneric;
use tableau::{Estimator, GmType, Tableau};

pub(crate) use crate::MINIMAL_STEP_SIZE;
use crate::Result;
use crate::omclog;
use math::{abs, pow, sqrt};


/// C's `GB_MINIMAL_STEP_SIZE` (`epsilon.h`).
const GB_MINIMAL_STEP_SIZE: f64 = 1e-20;
/// C's `GB_TOLERANCE_SCALING_SAFETY` (`gbode_err.h`).
const GB_TOLERANCE_SCALING_SAFETY: f64 = 0.2;

/// How far one [`Gbode::step`] got.
pub enum GbStep {
    /// `target` reached; the states were interpolated onto it.
    Reached,
    /// `-noEquidistantTimeGrid`: one integrator step ended at the reported time.
    Stepped,
    /// An event was located at this time; the states are the interpolant there.
    Root(f64),
}

/// Solver statistics, in C's `SOLVERSTATS` fields.
#[derive(Default, Clone, Copy)]
pub struct GbStats {
    pub steps: u64,
    pub calls_ode: u64,
    pub calls_jacobian: u64,
    pub err_test_failures: u64,
    pub convergence_test_failures: u64,
}

/// C's `DATA_GBODE`, single-rate.
pub struct Gbode {
    conf: GbConf,
    tableau: Tableau,
    nls: Option<GbNls>,
    gnls: Option<GbNlsGeneric>,
    /// The estimator the two-step one falls back to without a valid history.
    two_step_fallback: Option<Estimator>,
    n_states: usize,
    tol: f64,

    y: Vec<f64>,
    yt: Vec<f64>,
    y1: Vec<f64>,
    y2: Vec<f64>,
    y_left: Vec<f64>,
    k_left: Vec<f64>,
    y_right: Vec<f64>,
    k_right: Vec<f64>,
    y_old: Vec<f64>,
    f: Vec<f64>,
    y_last: Vec<f64>,
    k_last: Vec<f64>,
    /// Stage derivatives, `n_stages` blocks of `n_states`:
    /// `k_i = f(t_n + c_i*h, y_n + h*sum_j a_ij*k_j)`, `i = 1..s`.
    k: Vec<f64>,
    /// The stage values those derivatives were taken at, same layout.
    x: Vec<f64>,
    /// Ring buffers of the last accepted points — states, their derivatives and
    /// their times — which the implicit stages extrapolate their guess from.
    yv: Vec<f64>,
    kv: Vec<f64>,
    tv: Vec<f64>,
    /// Richardson's backup of the first two ring-buffer entries.
    yr: Vec<f64>,
    kr: Vec<f64>,
    tr: Vec<f64>,
    /// The part of the implicit stage residual that does not depend on the unknown.
    res_const: Vec<f64>,
    /// Per state: the absolute error estimate, the tolerance it is judged against,
    /// and their ratio `err = errest/errtol`.
    errest: Vec<f64>,
    errtol: Vec<f64>,
    err: Vec<f64>,
    /// Ring buffers the step size controller reads its history from.
    err_values: Vec<f64>,
    step_size_values: Vec<f64>,
    nominals: Vec<f64>,
    /// Scratch for the dense-output weights.
    b_dt: Vec<f64>,
    zc: Vec<f64>,
    zc_pre: Vec<f64>,
    zc_backup: Vec<f64>,
    /// The crossings that changed sign over the accepted step (C's `eventLst`).
    event_ids: Vec<usize>,
    /// C's `findRoot_gb` `time_left`/`states_left`, which the driver evaluates at.
    ev_left_time: f64,
    ev_left_y: Vec<f64>,

    start_time: f64,
    stop_time: f64,
    /// The output step size the caller wants, C's `solverInfo->currentStepSize`;
    /// the constant-step-size mode uses it directly.
    desired_step_size: f64,
    time: f64,
    time_left: f64,
    time_right: f64,
    event_time: f64,
    err_int: f64,
    extrapolation_base_time: f64,
    extrapolation_step_size: f64,
    step_size: f64,
    last_step_size: f64,
    opt_step_size: f64,
    max_step_size: f64,
    initial_step_size: f64,
    no_restart: bool,
    act_stage: usize,
    current_error_order: i32,
    ring_buffer_size: usize,
    is_explicit: bool,
    initial_failures: i32,
    is_first_step: bool,
    did_event_step: bool,
    event_happened: bool,
    /// The birate mode (`-gbratio` in (0,1)) and its fast-states integrator.
    multi_rate: bool,
    percentage: f64,
    n_fast: usize,
    n_slow: usize,
    fast_states_idx: Vec<usize>,
    slow_states_idx: Vec<usize>,
    sorted_states_idx: Vec<usize>,
    err_slow: f64,
    err_fast: f64,
    did_fast_step: bool,
    gbf: Option<alloc::boxed::Box<multirate::GbodeF>>,
    stats: GbStats,
}

impl Gbode {
    /// C's `gbode_allocateData`: read the flags, build the tableau, size the work
    /// arrays. `jac_colors` is the ODE Jacobian's color count (0 without a pattern);
    /// `sym_jac_available` whether the model answers [`Ode::jacobian_vector`].
    pub fn new(
        n_states: usize,
        tolerance: f64,
        n_zc: usize,
        jac_colors: usize,
        sym_jac_available: bool,
    ) -> core::result::Result<Self, String> {
        let conf = GbConf::from_flags()?;
        let tol = if tolerance > 0.0 { tolerance } else { 1e-6 };
        // C's `gbode_allocateData` logging, in its order (`getGB_method` first, then
        // `initButcherTableau` and `analyseButcherTableau`).
        omclog::info!(omclog::SOLVER, false, "Chosen gbode method: {}", conf.method_name());
        let (mut t, _nls_size) = tableau::init(conf.method, conf.err_method, n_states);
        if t.richardson {
            omclog::info(
                omclog::SOLVER,
                false,
                "Richardson extrapolation is used for step size control",
            );
        }
        omclog::info(
            omclog::SOLVER,
            false,
            match t.gm_type {
                GmType::Explicit => "Chosen RK method is explicit",
                GmType::Dirk => "Chosen RK method diagonally implicit",
                _ => "Chosen RK method is fully implicit",
            },
        );
        let is_explicit = t.gm_type == GmType::Explicit;
        if !is_explicit {
            omclog::info!(
                omclog::SOLVER,
                false,
                "Chosen gbode NLS method: {}",
                conf.nls_method_name(),
            );
        }
        omclog::info!(
            omclog::SOLVER,
            false,
            "Chosen gbode step size control: {}",
            conf.ctrl_method_name(),
        );
        let internal_nls = !is_explicit && conf.nls_method == NlsMethod::Internal;
        let two_step_fallback = tableau::finalize_error(&mut t, internal_nls).map_err(String::from)?;
        // C's `setJacobianMethod` against what the model carries, then gbode's own
        // downgrades: colored evaluation is the only kind it implements. The
        // warning is emitted below, where C prints it.
        let (sym_jac, jac_warning) = if is_explicit {
            (false, None)
        } else {
            use crate::simflags::JacobianMethod as M;
            let requested = crate::simflags::with_flags(|f| f.jacobian);
            let sym_avail = sym_jac_available && requested != Some(M::ColoredSymJacAdj);
            let method = if sym_avail {
                requested.unwrap_or(M::ColoredSymJac)
            } else if jac_colors > 0 {
                match requested {
                    Some(M::ColoredSymJac) | Some(M::BicoloredSymJac) => M::ColoredNumJac,
                    Some(M::SymJac) => M::NumJac,
                    None => M::ColoredNumJac,
                    Some(m) => m,
                }
            } else {
                M::InternalNumJac
            };
            match method {
                M::SymJac => (
                    true,
                    Some(
                        "Symbolic Jacobians without coloring are currently not supported by \
                         GBODE. Colored symbolical Jacobian will be used.",
                    ),
                ),
                M::NumJac | M::ColoredNumJac | M::InternalNumJac => (
                    false,
                    Some(
                        "Numerical Jacobians without coloring are currently not supported by \
                         GBODE. Colored numerical Jacobian will be used.",
                    ),
                ),
                _ => (sym_avail, None),
            }
        };
        let nls = internal_nls.then(|| GbNls::new(&t, n_states, tol, jac_colors, sym_jac));
        let gnls =
            (!is_explicit && !internal_nls).then(|| GbNlsGeneric::new(&t, n_states, sym_jac));
        let multi_rate = conf.ratio > 0.0 && conf.ratio < 1.0;
        // With the birate mode and no explicit `-gbint`, C defaults to dense output.
        let base_interpolation =
            if multi_rate && crate::simflags::with_flags(|f| f.gb_flag("gbint")).is_none() {
                Interpolation::DenseOutput
            } else {
                conf.interpolation
            };
        // C's `gbode_allocateData` demotes dense output to Hermite when the method
        // has no formula for it.
        let interpolation = match (base_interpolation, t.with_dense_output) {
            (Interpolation::DenseOutput, false) => Interpolation::Hermite,
            (Interpolation::DenseOutputErrCtrl, false) => Interpolation::HermiteErrCtrl,
            (other, _) => other,
        };
        let (max_step_size, initial_step_size, no_restart) = crate::simflags::with_flags(|f| {
            (f.max_step_size.unwrap_or(-1.0), f.initial_step_size.unwrap_or(-1.0), f.no_restart)
        });
        omclog::info(
            omclog::SOLVER,
            false,
            &if max_step_size > 0.0 {
                format!("maximum step size {}", omclog::g(max_step_size, 0, 6))
            } else {
                String::from("maximum step size not set")
            },
        );
        omclog::info(
            omclog::SOLVER,
            false,
            &if initial_step_size > 0.0 {
                format!("initial step size {}", omclog::g(initial_step_size, 0, 6))
            } else {
                String::from("initial step size not set")
            },
        );
        omclog::info!(
            omclog::SOLVER,
            false,
            "gbode performs a restart after an event occurs {}",
            if no_restart { "NO" } else { "YES" },
        );
        if let Some(msg) = jac_warning {
            omclog::warning(omclog::STDOUT, false, msg);
        }
        omclog::info!(
            omclog::SOLVER,
            false,
            "Chosen gbode interpolation method: {}",
            conf.interpolation_name(),
        );
        omclog::info(
            omclog::SOLVER,
            false,
            match interpolation {
                Interpolation::Lin => "Linear interpolation is used for emitting results ",
                Interpolation::DenseOutput | Interpolation::DenseOutputErrCtrl => {
                    "Dense output is used for emitting results "
                }
                _ => "Hermite interpolation is used for emitting results ",
            },
        );
        let mut conf = conf;
        conf.interpolation = interpolation;
        let percentage = conf.ratio;
        let gbf = if multi_rate {
            let gbf = multirate::GbodeF::new(&conf, n_states, tol, sym_jac)?;
            // C: the outer step's last stage is not reused with a fast integration
            // in between.
            t.k_right = false;
            let i = (libm::round(n_states as f64 * conf.ratio).max(1.0) as usize)
                .min(n_states.saturating_sub(1));
            omclog::info!(
                omclog::SOLVER,
                false,
                "Number of states {} ({} slow states, {} fast states)",
                n_states,
                n_states - i,
                i,
            );
            Some(alloc::boxed::Box::new(gbf))
        } else {
            None
        };
        let n_stages = t.n_stages;
        let ring = 4usize;
        let current_error_order = t.error_order;
        Ok(Gbode {
            conf,
            tableau: t,
            nls,
            gnls,
            two_step_fallback,
            n_states,
            tol,
            y: vec![0.0; n_states],
            yt: vec![0.0; n_states],
            y1: vec![0.0; n_states],
            y2: vec![0.0; n_states],
            y_left: vec![0.0; n_states],
            k_left: vec![0.0; n_states],
            y_right: vec![0.0; n_states],
            k_right: vec![0.0; n_states],
            y_old: vec![0.0; n_states],
            f: vec![0.0; n_states],
            y_last: vec![0.0; n_states],
            k_last: vec![0.0; n_states * n_stages],
            k: vec![0.0; n_states * n_stages],
            x: vec![0.0; n_states * n_stages],
            yv: vec![0.0; n_states * ring],
            kv: vec![0.0; n_states * ring],
            tv: vec![0.0; ring],
            yr: vec![0.0; n_states * 2],
            kr: vec![0.0; n_states * 2],
            tr: vec![0.0; 2],
            res_const: vec![0.0; n_states],
            errest: vec![0.0; n_states],
            errtol: vec![0.0; n_states],
            err: vec![0.0; n_states],
            err_values: vec![0.0; ring],
            step_size_values: vec![0.0; ring],
            nominals: vec![1.0; n_states],
            b_dt: vec![0.0; n_stages],
            zc: vec![0.0; n_zc],
            zc_pre: vec![0.0; n_zc],
            zc_backup: vec![0.0; n_zc],
            event_ids: Vec::new(),
            ev_left_time: 0.0,
            ev_left_y: vec![0.0; n_states],
            start_time: 0.0,
            stop_time: f64::MAX,
            desired_step_size: 0.0,
            time: 0.0,
            time_left: 0.0,
            time_right: 0.0,
            event_time: f64::MAX,
            err_int: 0.0,
            extrapolation_base_time: f64::INFINITY,
            extrapolation_step_size: 0.0,
            step_size: 0.0,
            last_step_size: 0.0,
            opt_step_size: 0.0,
            max_step_size,
            initial_step_size,
            no_restart,
            act_stage: 0,
            current_error_order,
            ring_buffer_size: ring,
            is_explicit,
            initial_failures: -1,
            is_first_step: true,
            did_event_step: false,
            event_happened: false,
            multi_rate,
            percentage,
            n_fast: 0,
            n_slow: n_states,
            fast_states_idx: (0..n_states).collect(),
            slow_states_idx: (0..n_states).collect(),
            sorted_states_idx: (0..n_states).collect(),
            err_slow: 0.0,
            err_fast: 0.0,
            did_fast_step: false,
            gbf,
            stats: GbStats::default(),
        })
    }

    /// The experiment window and the output step size, which C reads out of
    /// `simulationInfo`/`solverInfo` whenever it needs them.
    pub fn set_experiment(&mut self, start_time: f64, stop_time: f64, step_size: f64) {
        self.start_time = start_time;
        self.stop_time = stop_time;
        self.desired_step_size = step_size;
    }

    pub fn set_nominals(&mut self, nominals: &[f64]) {
        for (i, n) in nominals.iter().enumerate() {
            self.nominals[i] = abs(*n).max(1e-32);
        }
    }

    pub fn stats(&self) -> GbStats {
        let mut s = self.stats;
        if let Some(nls) = self.nls.as_ref() {
            s.calls_jacobian = nls.n_jac_evals;
        }
        if let Some(gnls) = self.gnls.as_ref() {
            s.calls_jacobian = gnls.n_jac_evals;
        }
        s
    }

    /// The solver must re-initialize at the caller's `(t, y)`: C's `didEventStep`.
    pub fn restart(&mut self) {
        self.did_event_step = true;
        if let Some(nls) = self.nls.as_mut() {
            nls.invalidate();
        }
        if let Some(gbf) = self.gbf.as_mut() {
            gbf.did_event_step = true;
            if let Some(nls) = gbf.nls.as_mut() {
                nls.invalidate();
            }
        }
    }

    /// The first crossing that fired at the last located event, for the
    /// chattering message.
    pub fn root_index(&self) -> usize {
        self.event_ids.first().copied().unwrap_or(0)
    }

    fn n_stages(&self) -> usize {
        self.tableau.n_stages
    }

    /// C's `getInitStepSize`, called at the start of the simulation and after an
    /// event. See Hairer, Nørsett & Wanner, "Solving Ordinary Differential
    /// Equations I, Nonstiff Problems", p. 169.
    fn init_step_size(&mut self, ode: &mut dyn Ode, time: f64, y: &[f64], step_size: f64) -> Result<()> {
        let n = self.n_states;
        let old_step = self.step_size;
        self.initial_failures += 1;
        self.time = time;
        self.y_old.copy_from_slice(&y[..n]);
        let mut f0 = vec![0.0; n];
        ode.eval(self.time, &self.y_old, &mut f0)?;
        if self.initial_step_size < 0.0 {
            self.f.copy_from_slice(&f0);
            let (d0, d1) = ctrl::init_step_norms(&self.y_old, &f0, self.tol);
            let safety = 0.01;
            let mut h0 = if d0 < 1e-5 || d1 < 1e-5 { 1e-6 } else { safety * d0 / d1 };
            if self.initial_failures > 0 {
                h0 /= pow(10.0, self.initial_failures as f64);
            }
            h0 = h0.min(0.1 * step_size);
            let mut y1 = vec![0.0; n];
            for i in 0..n {
                y1[i] = self.y_old[i] + f0[i] * h0;
            }
            let mut f1 = vec![0.0; n];
            ode.eval(self.time + h0, &y1, &mut f1)?;
            let mut d2 = 0.0;
            for i in 0..n {
                let sc = self.tol + abs(self.y_old[i]) * self.tol;
                let diff = f1[i] - self.f[i];
                d2 += (diff * diff) / (sc * sc);
            }
            d2 = sqrt(d2 / n as f64) / h0;
            let d = d1.max(d2);
            let h1 = if d > 1e-15 { sqrt(safety / d) } else { (1e-6f64).max(h0 * 1e-3) };
            self.step_size = (100.0 * h0).min(h1);
            self.opt_step_size = self.step_size;
            self.last_step_size = 0.0;
            // Leave the model at the base point again, as C restores it.
            ode.eval(self.time, &self.y_old, &mut f0)?;
        } else {
            self.step_size = self.initial_step_size;
            self.last_step_size = 0.0;
        }
        if self.did_event_step && !self.conf.evnt_reinit {
            self.step_size = (old_step * 1e-1).max(self.step_size);
        }
        omclog::info!(
            omclog::SOLVER,
            false,
            "Initial step size = {} at time {}",
            omclog::g(self.step_size, 0, 6),
            omclog::g(self.time, 0, 6),
        );
        self.initial_failures = -1;
        Ok(())
    }

    /// C's `gbode_init`: reset the ring buffers and statistics at a (re)start. The
    /// model must be at `(time, y_old)` with the derivative evaluated.
    fn init(&mut self, ode: &mut dyn Ode) -> Result<()> {
        let n = self.n_states;
        for i in 0..self.ring_buffer_size {
            self.err_values[i] = 0.0;
            self.step_size_values[i] = 0.0;
        }
        self.time_right = self.time;
        self.y_right.copy_from_slice(&self.y_old);
        let mut f0 = vec![0.0; n];
        ode.eval(self.time, &self.y_old, &mut f0)?;
        self.k_right.copy_from_slice(&f0);
        for i in 0..self.ring_buffer_size {
            self.tv[i] = self.time_right;
            self.yv[i * n..(i + 1) * n].copy_from_slice(&self.y_right);
            self.kv[i * n..(i + 1) * n].copy_from_slice(&self.k_right);
        }
        self.event_time = f64::MAX;
        Ok(())
    }

    /// C's `extrapolation_gb`: the initial guess for an implicit stage at `time`.
    fn extrapolate(&self, out: &mut [f64], time: f64) {
        let n = self.n_states;
        if abs(self.tv[1] - self.tv[0]) <= interp::GBODE_EPSILON {
            // C's `addSmultVec_gb`: a first-order step off the newest point.
            let dt = time - self.tv[0];
            for i in 0..n {
                out[i] = self.yv[i] + dt * self.kv[i];
            }
        } else {
            interp::hermite(
                self.tv[1],
                &self.yv[n..2 * n],
                &self.kv[n..2 * n],
                self.tv[0],
                &self.yv[..n],
                &self.kv[..n],
                time,
                out,
                None,
                n,
            );
        }
    }

    /// C's `error_interpolation_gb`: how far the cheap interpolant is from the
    /// Hermite one at the interval midpoint, as a tolerance-scaled error — over
    /// `idx` when given (the slow states, in the birate mode).
    fn error_interpolation(&mut self, tol: f64, idx: Option<&[usize]>) -> f64 {
        let n = self.n_states;
        let mid = (self.time_left + self.time_right) / 2.0;
        let (y1, y2) = (&mut self.y1, &mut self.y2);
        if matches!(
            self.conf.interpolation,
            Interpolation::DenseOutput | Interpolation::DenseOutputErrCtrl
        ) {
            interp::interpolate(
                self.conf.interpolation,
                self.time_left,
                &self.y_left,
                &self.k_left,
                self.time_right,
                &self.y_right,
                &self.k_right,
                mid,
                y1,
                idx,
                n,
                &self.tableau,
                &mut self.b_dt,
                &self.k,
            );
        } else {
            interp::hermite_a(
                self.time_left,
                &self.y_left,
                &self.k_left,
                self.time_right,
                &self.y_right,
                mid,
                y1,
                idx,
                n,
            );
        }
        interp::hermite(
            self.time_left,
            &self.y_left,
            &self.k_left,
            self.time_right,
            &self.y_right,
            &self.k_right,
            mid,
            y2,
            idx,
            n,
        );
        let mut errint: f64 = 0.0;
        let all: Vec<usize>;
        let ix: &[usize] = match idx {
            Some(ix) => ix,
            None => {
                all = (0..n).collect();
                &all
            }
        };
        for &i in ix {
            let errtol = tol * abs(self.y_left[i]).max(abs(self.y_right[i])) + tol;
            self.errest[i] = abs(self.y2[i] - self.y1[i]) / errtol;
            errint = errint.max(self.errest[i]);
        }
        errint
    }

    /// C's `gbScaledErrorTolerance`.
    fn scaled_error_tolerance(&self) -> f64 {
        let tol = self.tol;
        let (method_order, estimator_order) = (self.tableau.order_b, self.current_error_order);
        if self.tableau.richardson || estimator_order >= method_order {
            return tol;
        }
        let order_quot = (estimator_order as f64 + 1.0) / (method_order as f64 + 1.0);
        tol.max(GB_TOLERANCE_SCALING_SAFETY * pow(tol, order_quot))
    }
}

mod err;
mod events;
mod step;
