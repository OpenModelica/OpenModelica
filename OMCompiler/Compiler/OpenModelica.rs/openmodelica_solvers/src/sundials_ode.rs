//! `-s=cvode` and `-s=ida` for anything that can be an [`Ode`], the way
//! [`crate::dassl`] drives DASKR: IDA gets the ODE as the residual
//! `y' - f(t, y)`, and the zero-crossings are both integrators' own root
//! functions, so an event is located by SUNDIALS rather than bisected after it.
//!
//! Neither can be built before the first step, which is where the initial point
//! is known; the model is reached from the callbacks through a `user_data`
//! context parked on the stack for the length of one.

use alloc::vec;
use alloc::vec::Vec;
use core::ffi::{c_int, c_void};

use crate::sundials::{
    self, Counters, Cvode, Ida, IdaLs, IdaOptions, NVector, Stop, nv_data,
};
use crate::{Ode, Result};

/// How far one step got.
pub enum SunStep {
    /// `target` reached.
    Reached,
    /// A root was located at this time; the states are the ones there.
    Root(f64),
}

/// Resumes allowed after the work quota runs out, which only allows more work
/// on the same trajectory.
const WORK_RETRIES: u32 = 10_000;

struct Ctx<'a> {
    ode: &'a mut dyn Ode,
    n: usize,
    n_zc: usize,
    /// `f(t, y)`, which IDA's residual subtracts from `y'`.
    f: &'a mut [f64],
    failed: Option<&'static str>,
}

unsafe extern "C" fn rhs(t: f64, y: NVector, ydot: NVector, user: *mut c_void) -> c_int {
    let c = unsafe { &mut *(user as *mut Ctx) };
    let n = c.n;
    let (y, f) = unsafe {
        (core::slice::from_raw_parts(nv_data(y), n), core::slice::from_raw_parts_mut(nv_data(ydot), n))
    };
    let r = c.ode.eval(t, y, f);
    fail(c, r)
}

unsafe extern "C" fn roots(t: f64, y: NVector, gout: *mut f64, user: *mut c_void) -> c_int {
    let c = unsafe { &mut *(user as *mut Ctx) };
    let (n, n_zc) = (c.n, c.n_zc);
    let (y, g) = unsafe {
        (core::slice::from_raw_parts(nv_data(y), n), core::slice::from_raw_parts_mut(gout, n_zc))
    };
    let r = c.ode.eval_zc(t, y, g);
    fail(c, r)
}

unsafe extern "C" fn ida_res(
    t: f64,
    yy: NVector,
    yp: NVector,
    rr: NVector,
    user: *mut c_void,
) -> c_int {
    let c = unsafe { &mut *(user as *mut Ctx) };
    let n = c.n;
    let (y, yp, r) = unsafe {
        (
            core::slice::from_raw_parts(nv_data(yy), n),
            core::slice::from_raw_parts(nv_data(yp), n),
            core::slice::from_raw_parts_mut(nv_data(rr), n),
        )
    };
    if let Err(e) = c.ode.eval(t, y, c.f) {
        c.failed = Some(e);
        return -1;
    }
    for i in 0..n {
        r[i] = yp[i] - c.f[i];
    }
    0
}

unsafe extern "C" fn ida_roots(
    t: f64,
    yy: NVector,
    _yp: NVector,
    gout: *mut f64,
    user: *mut c_void,
) -> c_int {
    unsafe { roots(t, yy, gout, user) }
}

fn fail(c: &mut Ctx, r: Result<()>) -> c_int {
    match r {
        Ok(()) => 0,
        Err(e) => {
            c.failed = Some(e);
            -1
        }
    }
}

/// C's `dasslTolerances`: the per-state nominal scales the absolute tolerance.
fn abs_tolerances(tolerance: f64, n: usize, nominals: &[f64]) -> Vec<f64> {
    (0..n)
        .map(|i| tolerance * nominals.get(i).copied().unwrap_or(1.0).abs().max(1e-32))
        .collect()
}

fn add(a: Counters, b: Counters) -> Counters {
    Counters {
        steps: a.steps + b.steps,
        rhs_evals: a.rhs_evals + b.rhs_evals,
        jac_evals: a.jac_evals + b.jac_evals,
        err_test_fails: a.err_test_fails + b.err_test_fails,
        conv_test_fails: a.conv_test_fails + b.conv_test_fails,
    }
}

/// What the next step owes the integrator, both settled in `prepare`.
#[derive(Clone, Copy, PartialEq, Eq)]
enum Pending {
    None,
    /// The states moved behind SUNDIALS' back.
    Reinit,
    /// New nominals, and the tolerance vector is set only at construction.
    Rebuild,
}

/// `-s=cvode`: CVODE with its own root finding, over an [`Ode`].
pub struct CvodeOde {
    cv: Option<Cvode>,
    n: usize,
    n_zc: usize,
    tolerance: f64,
    nominals: Vec<f64>,
    pending: Pending,
    /// Counters from the memory blocks a rebuild dropped.
    past: Counters,
}

impl CvodeOde {
    pub fn new(n: usize, n_zc: usize, tolerance: f64, nominals: &[f64]) -> CvodeOde {
        CvodeOde {
            cv: None,
            n,
            n_zc,
            tolerance,
            nominals: nominals.to_vec(),
            pending: Pending::Rebuild,
            past: Counters::default(),
        }
    }

    pub fn restart(&mut self) {
        if self.pending == Pending::None {
            self.pending = Pending::Reinit;
        }
    }

    pub fn set_nominals(&mut self, nominals: &[f64]) {
        if self.nominals != nominals {
            self.nominals = nominals.to_vec();
            self.pending = Pending::Rebuild;
        }
    }

    pub fn counters(&self) -> Counters {
        match self.cv.as_ref() {
            Some(cv) => add(self.past, cv.counters()),
            None => self.past,
        }
    }

    /// Integrate from `(t, y)` toward `target`.
    pub fn step(
        &mut self,
        ode: &mut dyn Ode,
        target: f64,
        t: &mut f64,
        y: &mut [f64],
    ) -> Result<SunStep> {
        if y.is_empty() {
            *t = target;
            return Ok(SunStep::Reached);
        }
        self.prepare(*t, y)?;
        let (n, n_zc) = (self.n, self.n_zc);
        let cv = self.cv.as_mut().expect("prepare built it");
        let mut ctx = Ctx { ode, n, n_zc, f: &mut [], failed: None };
        if !cv.set_user_data(&mut ctx as *mut Ctx as *mut c_void) {
            return Err("cvode: the context could not be bound");
        }
        let mut retries = 0;
        let stop = loop {
            match cv.step(t, target) {
                Stop::Failed(sundials::CV_TOO_MUCH_WORK) if retries < WORK_RETRIES => retries += 1,
                other => break other,
            }
        };
        if let Some(e) = ctx.failed {
            return Err(e);
        }
        y.copy_from_slice(cv.y());
        match stop {
            Stop::Reached | Stop::Stepped => Ok(SunStep::Reached),
            Stop::Root => Ok(SunStep::Root(*t)),
            Stop::Failed(flag) => Err(cvode_failure(flag)),
        }
    }

    fn prepare(&mut self, t: f64, y: &[f64]) -> Result<()> {
        match core::mem::replace(&mut self.pending, Pending::None) {
            Pending::None => Ok(()),
            Pending::Reinit => {
                let cv = self.cv.as_mut().expect("Reinit follows a build");
                cv.y_mut().copy_from_slice(y);
                match cv.reinit(t) {
                    true => Ok(()),
                    false => Err("cvode: the integrator could not be restarted"),
                }
            }
            Pending::Rebuild => {
                if let Some(cv) = self.cv.take() {
                    self.past = add(self.past, cv.counters());
                }
                let atol = abs_tolerances(self.tolerance, self.n, &self.nominals);
                let root = (self.n_zc > 0).then_some(roots as sundials::RootFn);
                let config = crate::simflags::with_flags(crate::simflags::cvode_config);
                self.cv = Some(
                    Cvode::new(t, y, self.tolerance, &atol, self.n_zc, rhs, root, config)
                        .ok_or("cvode: the integrator could not be created")?,
                );
                Ok(())
            }
        }
    }
}

/// `-s=ida`: IDA over the residual `y' - f(t, y)`, with its own root finding.
pub struct IdaOde {
    ida: Option<Ida>,
    n: usize,
    n_zc: usize,
    tolerance: f64,
    nominals: Vec<f64>,
    /// The residual's scratch for `f(t, y)`.
    f: Vec<f64>,
    pending: Pending,
    past: Counters,
}

impl IdaOde {
    pub fn new(n: usize, n_zc: usize, tolerance: f64, nominals: &[f64]) -> IdaOde {
        IdaOde {
            ida: None,
            n,
            n_zc,
            tolerance,
            nominals: nominals.to_vec(),
            f: vec![0.0; n],
            pending: Pending::Rebuild,
            past: Counters::default(),
        }
    }

    pub fn restart(&mut self) {
        if self.pending == Pending::None {
            self.pending = Pending::Reinit;
        }
    }

    pub fn set_nominals(&mut self, nominals: &[f64]) {
        if self.nominals != nominals {
            self.nominals = nominals.to_vec();
            self.pending = Pending::Rebuild;
        }
    }

    pub fn counters(&self) -> Counters {
        match self.ida.as_ref() {
            Some(ida) => add(self.past, ida.counters()),
            None => self.past,
        }
    }

    pub fn step(
        &mut self,
        ode: &mut dyn Ode,
        target: f64,
        t: &mut f64,
        y: &mut [f64],
    ) -> Result<SunStep> {
        if y.is_empty() {
            *t = target;
            return Ok(SunStep::Reached);
        }
        self.prepare(ode, *t, y)?;
        let (n, n_zc) = (self.n, self.n_zc);
        let ida = self.ida.as_mut().expect("prepare built it");
        let mut ctx = Ctx { ode, n, n_zc, f: &mut self.f, failed: None };
        if !ida.set_user_data(&mut ctx as *mut Ctx as *mut c_void) {
            return Err("ida: the context could not be bound");
        }
        let mut retries = 0;
        let stop = loop {
            match ida.step(t, target, false) {
                Stop::Failed(sundials::IDA_TOO_MUCH_WORK) if retries < WORK_RETRIES => retries += 1,
                other => break other,
            }
        };
        if let Some(e) = ctx.failed {
            return Err(e);
        }
        y.copy_from_slice(ida.y());
        match stop {
            Stop::Reached | Stop::Stepped => Ok(SunStep::Reached),
            Stop::Root => Ok(SunStep::Root(*t)),
            Stop::Failed(flag) => Err(ida_failure(flag)),
        }
    }

    /// IDA wants a consistent `y'` at every start, which for an ODE is `f(t, y)`.
    fn prepare(&mut self, ode: &mut dyn Ode, t: f64, y: &[f64]) -> Result<()> {
        let pending = core::mem::replace(&mut self.pending, Pending::None);
        if pending == Pending::None {
            return Ok(());
        }
        let mut yp = vec![0.0; self.n];
        ode.eval(t, y, &mut yp)?;
        if pending == Pending::Reinit {
            let ida = self.ida.as_mut().expect("Reinit follows a build");
            ida.y_mut().copy_from_slice(y);
            ida.yp_mut().copy_from_slice(&yp);
            return match ida.reinit(t) {
                true => Ok(()),
                false => Err("ida: the integrator could not be restarted"),
            };
        }
        if let Some(ida) = self.ida.take() {
            self.past = add(self.past, ida.counters());
        }
        let atol = abs_tolerances(self.tolerance, self.n, &self.nominals);
        let root = (self.n_zc > 0).then_some(ida_roots as sundials::IdaRootFn);
        // Always dense: `-idaLS=klu` wants a sparsity pattern, which an ODE handed
        // over as a residual does not have.
        let opts = IdaOptions {
            max_order: crate::simflags::with_flags(|f| f.max_order),
            ..IdaOptions::default()
        };
        self.ida = Some(
            Ida::new(
                t, y, &yp, self.tolerance, &atol, self.n_zc, ida_res, root, IdaLs::Dense, 0, None,
                &opts,
            )
            .ok_or("ida: the integrator could not be created")?,
        );
        Ok(())
    }
}

/// `cvode_solver.c`'s messages for the flags a run can end on.
fn cvode_failure(flag: c_int) -> &'static str {
    match flag {
        sundials::CV_TOO_MUCH_WORK => "cvode: the solver took the maximum number of steps before reaching the output point",
        -2 => "cvode: the error tolerances are too small",
        -3 => "cvode: the error test failed repeatedly, or with |h| = hmin",
        -4 => "cvode: the corrector could not converge",
        -5 => "cvode: the linear solver setup failed",
        -6 => "cvode: the linear solver failed to solve",
        -9 => "cvode: the right-hand side failed on the first call",
        -10 => "cvode: the right-hand side failed repeatedly",
        sundials::CV_RTFUNC_FAIL => "cvode: the zero-crossing functions failed",
        _ => "cvode: the integrator failed",
    }
}

/// `ida_solver.c`'s messages for the flags a run can end on.
fn ida_failure(flag: c_int) -> &'static str {
    match flag {
        sundials::IDA_TOO_MUCH_WORK => "ida: the solver took the maximum number of steps before reaching the output point",
        -2 => "ida: the error tolerances are too small",
        sundials::IDA_ERR_FAIL => "ida: the error test failed repeatedly, or with |h| = hmin",
        sundials::IDA_CONV_FAIL => "ida: the corrector could not converge",
        -5 => "ida: the linear solver initialization failed",
        sundials::IDA_LSETUP_FAIL => "ida: the linear solver setup failed",
        -7 => "ida: the linear solver failed to solve",
        -8 => "ida: the residual function failed in an unrecoverable way",
        -9 => "ida: the residual function failed on the first call",
        -10 => "ida: the residual function failed repeatedly",
        sundials::IDA_RTFUNC_FAIL => "ida: the zero-crossing functions failed",
        _ => "ida: the integrator failed",
    }
}
