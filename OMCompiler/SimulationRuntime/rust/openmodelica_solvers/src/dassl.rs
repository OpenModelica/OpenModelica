//! `-s=dassl` for anything that can be an [`Ode`]: DASKR's BDF integrator with
//! its own root finding, which is what a compiled OpenModelica model is
//! integrated with by default.
//!
//! The ODE `y' = f(t, y)` is handed to DASKR as the residual `y' - f(t, y)`, so
//! the iteration matrix is `cj*I - df/dy` and DASKR differences it itself
//! (`INFO(5) = 0`). The zero-crossing functions are DASKR's root functions, so
//! an event is located by the same code the C runtime uses rather than by
//! bisecting afterwards.
//!
//! Where the model reports its Jacobian sparsity ([`Ode::jac_colors`]), the
//! iteration matrix is assembled here instead (`INFO(5) = 1`), one residual
//! evaluation per *colour* rather than per state — for a 36-state robot that is
//! the difference between 36 evaluations per Jacobian and a handful.
//!
//! DASKR takes plain function pointers with no user-data argument of its own,
//! so the model being integrated is reached through a pointer parked for the
//! duration of one [`Dassl::step`] — the same arrangement the wasm-jit driver
//! uses.

use alloc::vec;
use alloc::vec::Vec;
#[cfg(not(feature = "std"))]
use core::sync::atomic::{AtomicUsize, Ordering};

use crate::{Ode, Result};

/// How far one [`Dassl::step`] got.
pub enum DasslStep {
    /// `target` reached.
    Reached,
    /// `-noEquidistantTimeGrid`: an internal step ended here.
    Stepped,
    /// A root was located at this time; the states are the ones there.
    Root(f64),
}

pub struct Dassl {
    info: [i32; 24],
    rtol: Vec<f64>,
    atol: Vec<f64>,
    rwork: Vec<f64>,
    iwork: Vec<i32>,
    rpar: [f64; 1],
    ipar: [i32; 1],
    jroot: Vec<i32>,
    n_zc: i32,
    idid: i32,
    /// The derivatives DASKR carries between calls.
    yp: Vec<f64>,
    /// Scratch for the coloured Jacobian: the perturbed residual, the saved
    /// states and the step taken in each.
    jac_residual: Vec<f64>,
    jac_saved: Vec<f64>,
    jac_step: Vec<f64>,
    tolerance: f64,
    nominals: Vec<f64>,
    /// `IDID = -1` means the work quota ran out, not a failure: the same target
    /// is resumed. Bounded so a model that never advances still ends.
    quota_retries: u32,
    pub steps: u64,
    /// Iteration matrices assembled, which is what a stiff run spends itself on.
    pub jacobians: u64,
}

/// C's `dassl_limits`: `-maxIntegrationOrder` and `-maxStepSize`.
fn limits(info: &mut [i32; 24], rwork: &mut [f64], iwork: &mut [i32]) {
    let (order, h_max, out_time) =
        crate::simflags::with_flags(|f| (f.max_order, f.max_step_size, f.no_equidistant_time));
    if let Some(n) = order {
        info[8] = 1;
        iwork[2] = n;
    }
    if let Some(h) = h_max.or(out_time) {
        info[6] = 1;
        rwork[1] = h;
    }
}

impl Dassl {
    pub fn new(n_states: usize, n_zc: usize, tolerance: f64, nominals: &[f64]) -> Dassl {
        let neq = n_states as i32;
        let nrt = n_zc as i32;
        let lrw = (60 + 9 * neq + neq * neq + 3 * nrt + 64) as usize;
        let liw = (40 + neq + 64) as usize;
        let mut info = [0i32; 24];
        if n_states > 0 {
            info[1] = 1; // INFO(2)=1: per-state (vector) rtol/atol
        }
        if crate::simflags::with_flags(|f| f.no_equidistant_grid) {
            info[2] = 1; // INFO(3)=1: return after every internal step
        }
        let mut rwork = vec![0.0f64; lrw];
        let mut iwork = vec![0i32; liw];
        limits(&mut info, &mut rwork, &mut iwork);
        // C's `dasslTolerances`: the per-state nominal scales the absolute
        // tolerance, so a state whose magnitude is large is not held to the
        // accuracy of one whose magnitude is one.
        let (rtol, atol) = (0..n_states)
            .map(|i| {
                let nominal = nominals.get(i).copied().unwrap_or(1.0).abs().max(1e-32);
                (tolerance, tolerance * nominal)
            })
            .unzip();
        Dassl {
            info,
            rtol,
            atol,
            rwork,
            iwork,
            rpar: [0.0],
            ipar: [0],
            jroot: vec![0i32; n_zc.max(1)],
            n_zc: nrt,
            idid: 0,
            yp: vec![0.0; n_states],
            jac_residual: vec![0.0; n_states],
            jac_saved: vec![0.0; n_states],
            jac_step: vec![0.0; n_states],
            tolerance,
            nominals: nominals.to_vec(),
            quota_retries: 0,
            steps: 0,
            jacobians: 0,
        }
    }

    /// The step history is invalid after an event changed the states: DASKR is
    /// restarted from the new ones (C's `INFO(1) = 0`). YPRIME stands, as in C's
    /// `dassl_step`.
    pub fn restart(&mut self) {
        self.info[0] = 0;
    }

    /// The derivatives at the point the next step starts from, which DASKR's
    /// first step is sized against (`0.001*(tout - t)` capped by `0.5/‖y'‖`).
    /// C's `solver_main` hands DASSL `realVars + nStates`.
    pub fn set_derivatives(&mut self, yp: &[f64]) {
        let n = self.yp.len().min(yp.len());
        self.yp[..n].copy_from_slice(&yp[..n]);
    }

    /// Integrate from `(t, y)` toward `target`.
    pub fn step(
        &mut self,
        ode: &mut dyn Ode,
        target: f64,
        t: &mut f64,
        y: &mut [f64],
    ) -> Result<DasslStep> {
        use daskr::solver;

        if y.is_empty() {
            // Nothing to integrate; the caller's events are all time events.
            *t = target;
            return Ok(DasslStep::Reached);
        }
        // A model that knows its sparsity gets the coloured assembly below;
        // without it DASKR differences the matrix itself, one state at a time.
        let coloured = !ode.jac_colors().is_empty();
        self.info[4] = coloured as i32; // INFO(5)=1: a dense user Jacobian routine
        let mut ctx = Context {
            ode,
            n_states: y.len(),
            n_zc: self.n_zc as usize,
            failed: None,
            jacobians: 0,
            tolerance: self.tolerance,
            nominals: &self.nominals,
            residual: &mut self.jac_residual,
            saved: &mut self.jac_saved,
            step: &mut self.jac_step,
        };
        let _guard = ContextGuard::install(&mut ctx);

        let neq = y.len() as i32;
        let (lrw, liw) = (self.rwork.len(), self.iwork.len());
        let rt: solver::RtFn = if self.n_zc > 0 { root } else { solver::dummy_rt };
        let jac: solver::JacFn = if coloured { jacobian } else { solver::dummy_jacd };
        let mut tout = target;
        loop {
            unsafe {
                solver::ddaskr(
                    residual,
                    neq,
                    t,
                    y.as_mut_ptr(),
                    self.yp.as_mut_ptr(),
                    &mut tout,
                    self.info.as_mut_ptr(),
                    self.rtol.as_mut_ptr(),
                    self.atol.as_mut_ptr(),
                    &mut self.idid,
                    self.rwork.as_mut_ptr(),
                    lrw as i32,
                    self.iwork.as_mut_ptr(),
                    liw as i32,
                    self.rpar.as_mut_ptr(),
                    self.ipar.as_mut_ptr(),
                    jac,
                    solver::dummy_jack,
                    solver::dummy_psol,
                    rt,
                    self.n_zc,
                    self.jroot.as_mut_ptr(),
                );
            }
            // The model reported a failure through the residual; its own message
            // is the one worth showing.
            if let Some(e) = ctx.failed.take() {
                return Err(e);
            }
            // IDID = -1: the work quota expended before TOUT — resume where it
            // stopped, which is what C's `INFO(1) = 1` retry does.
            if self.idid == -1 && self.quota_retries < 10_000 {
                self.info[0] = 1;
                self.quota_retries += 1;
                continue;
            }
            break;
        }
        self.quota_retries = 0;
        self.jacobians += ctx.jacobians;
        self.steps = self.iwork[10] as u64; // IWORK(11) = number of steps taken
        match self.idid {
            5 => Ok(DasslStep::Root(*t)),
            1 => Ok(DasslStep::Stepped),
            idid if idid < 0 => Err(failure(idid)),
            _ => Ok(DasslStep::Reached),
        }
    }

    /// Which zero-crossing DASKR stopped on, for the caller's event handling.
    pub fn root_index(&self) -> usize {
        self.jroot.iter().position(|&r| r != 0).unwrap_or(0)
    }
}

/// C's `dassl.c` messages for the IDID values a run can end on.
fn failure(idid: i32) -> &'static str {
    match idid {
        -1 => "dassl: the solver took the maximum number of steps before reaching the output point",
        -2 => "dassl: the error tolerances are too small",
        -3 => "dassl: the error test failed repeatedly, or with |h| = hmin",
        -6 => "dassl: repeated error test failures on the last step",
        -7 => "dassl: the corrector could not converge",
        -8 => "dassl: the iteration matrix is singular",
        -9 => "dassl: the corrector could not converge, and the error test failed repeatedly",
        -10 => "dassl: the corrector could not converge because the model kept reporting an error",
        -11 => "dassl: the model reported an unrecoverable error",
        -12 => "dassl: the initial conditions could not be solved",
        -33 => "dassl: the solver was called after a failure it cannot continue from",
        _ => "dassl: the integration failed",
    }
}

/// What the DASKR callbacks need, parked for the duration of one step. DASKR's
/// `rpar`/`ipar` are `f64`/`i32` arrays, so a pointer cannot travel in them.
struct Context<'a> {
    ode: &'a mut dyn Ode,
    n_states: usize,
    n_zc: usize,
    failed: Option<&'static str>,
    jacobians: u64,
    tolerance: f64,
    nominals: &'a [f64],
    residual: &'a mut [f64],
    saved: &'a mut [f64],
    step: &'a mut [f64],
}

// Per thread where there are threads (a host may drive several FMUs at once),
// and a plain static in the in-wasm runtime, which has one.
#[cfg(feature = "std")]
std::thread_local! {
    static CONTEXT: core::cell::Cell<usize> = const { core::cell::Cell::new(0) };
}
#[cfg(not(feature = "std"))]
static CONTEXT: AtomicUsize = AtomicUsize::new(0);

fn set_context(p: usize) {
    #[cfg(feature = "std")]
    CONTEXT.with(|c| c.set(p));
    #[cfg(not(feature = "std"))]
    CONTEXT.store(p, Ordering::Relaxed);
}

fn context<'a>() -> Option<&'a mut Context<'a>> {
    #[cfg(feature = "std")]
    let p = CONTEXT.with(|c| c.get());
    #[cfg(not(feature = "std"))]
    let p = CONTEXT.load(Ordering::Relaxed);
    (p != 0).then(|| unsafe { &mut *(p as *mut Context) })
}

struct ContextGuard;

impl ContextGuard {
    fn install(ctx: &mut Context) -> ContextGuard {
        set_context(ctx as *mut Context as usize);
        ContextGuard
    }
}

impl Drop for ContextGuard {
    fn drop(&mut self) {
        set_context(0);
    }
}

/// `delta := y' - f(t, y)`, the ODE as a DAE residual.
unsafe fn residual(
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    _cj: *mut f64,
    delta: *mut f64,
    ires: *mut i32,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
    let Some(ctx) = context() else {
        unsafe { *ires = -2 };
        return;
    };
    let n = ctx.n_states;
    let (y, yp, delta) = unsafe {
        (
            core::slice::from_raw_parts(y, n),
            core::slice::from_raw_parts(yprime, n),
            core::slice::from_raw_parts_mut(delta, n),
        )
    };
    match ctx.ode.eval(unsafe { *t }, y, delta) {
        Ok(()) => {
            for i in 0..n {
                delta[i] = yp[i] - delta[i];
            }
        }
        Err(e) => {
            // IRES = -1 asks DASKR to retry with a smaller step; a model that cannot
            // be evaluated at all is IRES = -2, reported once the call returns.
            if ctx.ode.take_discard() {
                unsafe { *ires = -1 };
            } else {
                ctx.failed.get_or_insert(e);
                unsafe { *ires = -2 };
            }
        }
    }
}

/// The zero-crossing functions as DASKR's root functions.
unsafe fn root(
    _neq: *mut i32,
    t: *mut f64,
    y: *mut f64,
    _yprime: *mut f64,
    _nrt: *mut i32,
    rval: *mut f64,
    _rpar: *mut f64,
    _ipar: *mut i32,
) -> i32 {
    let Some(ctx) = context() else { return 1 };
    let (y, zc) = unsafe {
        (
            core::slice::from_raw_parts(y, ctx.n_states),
            core::slice::from_raw_parts_mut(rval, ctx.n_zc),
        )
    };
    match ctx.ode.eval_zc(unsafe { *t }, y, zc) {
        Ok(()) => 0,
        Err(e) => {
            ctx.failed.get_or_insert(e);
            1
        }
    }
}

/// C's `numericalDifferentiationDeltaXsolver`: `sqrt(DBL_EPSILON)`.
const DELTA_X_SOLVER: f64 = 1.4901161193847656e-8;

/// C's difference step for the DASSL Jacobian: scaled by the state, its rate of
/// change and its nominal, and signed like `h*y'`.
fn difference_step(yi: f64, hyp: f64, tol: f64, nominal: f64) -> f64 {
    let scale = yi.abs().max(hyp.abs());
    let weight = tol * (yi.abs() + nominal);
    let step = if scale > weight { scale } else { weight.max(nominal) };
    let magnitude = DELTA_X_SOLVER * step;
    if hyp >= 0.0 { magnitude } else { -magnitude }
}

/// The iteration matrix `cj*I - df/dy`, by colours.
///
/// The residual is `G = y' - f`, so `dG/dy = -df/dy` and the differences below
/// carry that sign already; `cj*dG/dy' = cj*I` is the diagonal added at the end.
unsafe fn jacobian(
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    base: *mut f64,
    pd: *mut f64,
    cj: *mut f64,
    h: *mut f64,
    _wt: *mut f64,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
    let Some(ctx) = context() else { return };
    let n = ctx.n_states;
    let (cj, h, time) = unsafe { (*cj, *h, *t) };
    let y = unsafe { core::slice::from_raw_parts_mut(y, n) };
    let yprime = unsafe { core::slice::from_raw_parts(yprime, n) };
    let base = unsafe { core::slice::from_raw_parts(base, n) };
    let matrix = unsafe { core::slice::from_raw_parts_mut(pd, n * n) };

    ctx.jacobians += 1;
    let colors = ctx.ode.jac_colors().to_vec();
    let rows_by_col = ctx.ode.jac_rows_by_col().to_vec();
    // A model that can multiply by its own Jacobian gives a whole colour per
    // call, exactly and without moving the state.
    if ctx.ode.has_jacobian_vector() {
        let mut seed = vec![0.0; n];
        for group in &colors {
            seed.fill(0.0);
            for &col in group {
                seed[col as usize] = 1.0;
            }
            if !ctx.ode.jacobian_vector(time, y, &seed, ctx.residual) {
                ctx.failed.get_or_insert("the model could not multiply by its Jacobian");
                return;
            }
            for &col in group {
                let ci = col as usize;
                for &row in rows_by_col.get(ci).map(Vec::as_slice).unwrap_or(&[]) {
                    // G = y' - f, so dG/dy is the negative of what the model gave.
                    matrix[ci * n + row as usize] = -ctx.residual[row as usize];
                }
            }
        }
        for col in 0..n {
            matrix[col * n + col] += cj;
        }
        return;
    }
    ctx.ode.set_context_jacobian();
    for group in &colors {
        for &col in group {
            let ci = col as usize;
            let nominal = ctx.nominals.get(ci).copied().unwrap_or(1.0).abs().max(1e-32);
            let mut step = difference_step(y[ci], h * yprime[ci], ctx.tolerance, nominal);
            step = y[ci] + step - y[ci]; // the step the addition actually took
            if step == 0.0 {
                step = DELTA_X_SOLVER;
            }
            ctx.saved[ci] = y[ci];
            ctx.step[ci] = step;
            y[ci] += step;
        }
        let evaluated = ctx.ode.eval(time, y, ctx.residual);
        for &col in group {
            let ci = col as usize;
            if evaluated.is_ok() {
                for &row in rows_by_col.get(ci).map(Vec::as_slice).unwrap_or(&[]) {
                    let ri = row as usize;
                    // G at the perturbed point, less the base residual DASKR passed.
                    let g = yprime[ri] - ctx.residual[ri];
                    matrix[ci * n + ri] = (g - base[ri]) / ctx.step[ci];
                }
            }
            y[ci] = ctx.saved[ci];
        }
        // No IRES here: a discarded point leaves its columns as they stand, as C's
        // assembly does.
        if let Err(e) = evaluated
            && !ctx.ode.take_discard()
        {
            ctx.failed.get_or_insert(e);
            break;
        }
    }
    ctx.ode.set_context_algebraic();
    for col in 0..n {
        matrix[col * n + col] += cj;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// `der(x) = -x`, whose solution is `exp(-t)`, with a root at `x = 0.5`.
    struct Decay {
        calls: u64,
    }

    impl Ode for Decay {
        fn eval(&mut self, _t: f64, y: &[f64], f: &mut [f64]) -> Result<()> {
            self.calls += 1;
            f[0] = -y[0];
            Ok(())
        }
        fn eval_zc(&mut self, _t: f64, y: &[f64], zc: &mut [f64]) -> Result<()> {
            zc[0] = y[0] - 0.5;
            Ok(())
        }
        fn calls(&self) -> u64 {
            self.calls
        }
    }

    #[test]
    fn integrates_to_the_analytic_solution() {
        let mut d = Dassl::new(1, 0, 1e-10, &[1.0]);
        let mut ode = Decay { calls: 0 };
        let (mut t, mut y) = (0.0, [1.0]);
        for k in 1..=10 {
            let target = k as f64 * 0.5;
            d.step(&mut ode, target, &mut t, &mut y).expect("step");
            assert!((y[0] - (-t).exp()).abs() < 1e-8, "x({t}) = {}, not {}", y[0], (-t).exp());
        }
    }

    #[test]
    fn stops_on_the_root() {
        let mut d = Dassl::new(1, 1, 1e-10, &[1.0]);
        let mut ode = Decay { calls: 0 };
        let (mut t, mut y) = (0.0, [1.0]);
        let found = loop {
            match d.step(&mut ode, 5.0, &mut t, &mut y).expect("step") {
                DasslStep::Root(te) => break Some(te),
                DasslStep::Reached => break None,
                DasslStep::Stepped => {}
            }
        };
        // x = exp(-t) crosses 0.5 at ln 2.
        let te = found.expect("no root located");
        assert!((te - 2f64.ln()).abs() < 1e-7, "root at {te}, not ln 2");
        assert_eq!(d.root_index(), 0);
    }

    /// A caller that leaves the derivatives at zero gets a first step a
    /// thousandth of the distance to `tout`, whatever the model is doing.
    #[test]
    fn the_first_step_follows_the_derivatives() {
        struct Fast(Option<f64>);
        impl Ode for Fast {
            fn eval(&mut self, t: f64, _y: &[f64], f: &mut [f64]) -> Result<()> {
                self.0.get_or_insert(t);
                f[0] = 1e6;
                Ok(())
            }
            fn eval_zc(&mut self, _t: f64, _y: &[f64], _zc: &mut [f64]) -> Result<()> {
                Ok(())
            }
        }
        let first = |yp: Option<f64>| {
            let mut d = Dassl::new(1, 0, 1e-6, &[1.0]);
            if let Some(yp) = yp {
                d.set_derivatives(&[yp]);
            }
            let mut ode = Fast(None);
            let (mut t, mut y) = (0.0, [0.0]);
            d.step(&mut ode, 1000.0, &mut t, &mut y).expect("step");
            ode.0.expect("no evaluation")
        };
        assert!(first(None) >= 1.0, "{} is not a thousandth of 1000", first(None));
        assert!(first(Some(1e6)) < 1e-6, "first step of {} does not follow y'", first(Some(1e6)));
    }
}
