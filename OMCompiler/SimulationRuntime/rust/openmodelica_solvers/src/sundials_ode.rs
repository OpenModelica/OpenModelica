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
use crate::{Dae, Ode, Result};

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
    // A root function has no recoverable answer.
    match c.ode.eval_zc(t, y, g) {
        Ok(()) => 0,
        Err(e) => {
            c.ode.take_discard();
            c.failed = Some(e);
            -1
        }
    }
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
    let evaluated = c.ode.eval(t, y, c.f);
    if evaluated.is_err() {
        return fail(c, evaluated);
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

/// SUNDIALS' right-hand-side convention: 0 success, positive a point to retry from,
/// negative a failure that ends the run.
fn fail(c: &mut Ctx, r: Result<()>) -> c_int {
    match r {
        Ok(()) => 0,
        Err(e) => {
            if c.ode.take_discard() {
                return 1;
            }
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

// ── IDA over a residual form ─────────────────────────────────────────────────

struct DaeCtx<'a> {
    dae: &'a mut dyn Dae,
    n: usize,
    n_zc: usize,
    failed: Option<&'static str>,
    /// KLU only: the CSC pattern and the scratch [`dae_jac`] assembles through.
    jac: Option<&'a mut DaeJac>,
    /// For the difference-quotient step, which scales with the last step's `y'`.
    mem: *mut c_void,
    tol: f64,
    nominals: &'a [f64],
}

/// The residual Jacobian as KLU wants it: the CSC arrays IDA's sparse matrix is
/// filled from, where each column's difference quotients go, and the buffers the
/// assembly perturbs through.
struct DaeJac {
    colptr: Vec<sundials::SunIndex>,
    rowidx: Vec<sundials::SunIndex>,
    /// `slots[col][k]` is the value index of `rows_by_col[col][k]`.
    slots: Vec<Vec<usize>>,
    colors: Vec<Vec<u32>>,
    rows_by_col: Vec<Vec<u32>>,
    ysave: Vec<f64>,
    ypsave: Vec<f64>,
    del: Vec<f64>,
    gp: Vec<f64>,
}

impl DaeJac {
    /// `None` when the pattern does not describe an `n`-column system, or when its
    /// colours do not partition the columns — a column no colour perturbs would
    /// leave that column of the Jacobian zero, and the factorization singular.
    /// A caller bug rather than a reason to fail the run: IDA's own dense
    /// difference-quotient Jacobian still solves it.
    fn new(sp: &crate::DaeSparsity, n: usize) -> Option<DaeJac> {
        if sp.rows_by_col.len() != n || sp.rows_by_col.iter().flatten().any(|&r| r as usize >= n) {
            return None;
        }
        let mut seen = vec![false; n];
        for &col in sp.colors.iter().flatten() {
            match seen.get_mut(col as usize) {
                Some(s) if !*s => *s = true,
                _ => return None, // out of range, or coloured twice
            }
        }
        if seen.iter().any(|s| !s) {
            return None;
        }
        let mut j = DaeJac {
            colptr: Vec::with_capacity(n + 1),
            rowidx: Vec::new(),
            slots: Vec::with_capacity(n),
            colors: sp.colors.clone(),
            rows_by_col: sp.rows_by_col.clone(),
            ysave: vec![0.0; n],
            ypsave: vec![0.0; n],
            del: vec![0.0; n],
            gp: vec![0.0; n],
        };
        j.colptr.push(0);
        for rows in &sp.rows_by_col {
            let base = j.rowidx.len();
            let mut sorted = rows.clone();
            sorted.sort_unstable();
            sorted.dedup();
            j.slots.push(
                rows.iter()
                    .map(|r| base + sorted.binary_search(r).expect("row is in the column"))
                    .collect(),
            );
            j.rowidx.extend(sorted.iter().map(|&r| r as sundials::SunIndex));
            j.colptr.push(j.rowidx.len() as sundials::SunIndex);
        }
        Some(j)
    }

    fn nnz(&self) -> usize {
        self.rowidx.len()
    }
}

/// The finite-difference increment for a column, C's `numericalJacobianStep`
/// (`model_help.h`): a relative step off the larger of the point and the last
/// step's derivative, floored by the nominal where the unknown is inside its own
/// absolute tolerance and so carries no scale to difference over.
fn fd_step(yi: f64, hyp: f64, tol: f64, nominal: f64) -> f64 {
    const DELTA_X_SOLVER: f64 = 1.4901161193847656e-8;
    let scale = yi.abs().max(hyp.abs());
    let ewt_inv = tol * (yi.abs() + nominal);
    let step = if scale > ewt_inv { scale } else { ewt_inv.max(nominal) };
    let mag = DELTA_X_SOLVER * step;
    // The step takes the sign of h*y', as both runtimes do.
    if hyp >= 0.0 { mag } else { -mag }
}

/// `∂F/∂y + cj·∂F/∂y'`, differenced one colour at a time: perturbing `y[j]` by
/// `del` and `y'[j]` by `cj*del` together makes one residual evaluation carry
/// both terms of column `j`, so there is no `-cj·I` diagonal to add afterwards.
unsafe extern "C" fn dae_jac(
    t: f64,
    cj: f64,
    yy: NVector,
    yp: NVector,
    rr: NVector,
    j: sundials::SunMatrix,
    user: *mut c_void,
    _t1: NVector,
    _t2: NVector,
    _t3: NVector,
) -> c_int {
    // Split the context so the residual and the pattern are borrowed apart.
    let DaeCtx { dae, n, failed, jac, mem, tol, nominals, .. } = unsafe { &mut *(user as *mut DaeCtx) };
    let n = *n;
    let Some(jac) = jac.as_deref_mut() else { return -1 };
    let (y, ypv, base) = (nv_data(yy), nv_data(yp), nv_data(rr));
    let h = sundials::ida_current_step(*mem);
    let nnz = jac.nnz();
    let vals = unsafe {
        let (data, colptr, rowidx) = sundials::sparse_arrays(j);
        core::ptr::copy_nonoverlapping(jac.colptr.as_ptr(), colptr, n + 1);
        core::ptr::copy_nonoverlapping(jac.rowidx.as_ptr(), rowidx, nnz);
        core::slice::from_raw_parts_mut(data, nnz)
    };
    vals.fill(0.0);
    for c in 0..jac.colors.len() {
        for k in 0..jac.colors[c].len() {
            let ci = jac.colors[c][k] as usize;
            let yi = unsafe { *y.add(ci) };
            let ypi = unsafe { *ypv.add(ci) };
            let nom = nominals.get(ci).copied().unwrap_or(1.0);
            let mut del = fd_step(yi, h * ypi, *tol, nom);
            del = yi + del - yi; // floating-point rounding, as in the C runtime
            if del == 0.0 {
                del = fd_step(0.0, 0.0, *tol, nom);
            }
            jac.ysave[ci] = yi;
            jac.ypsave[ci] = ypi;
            jac.del[ci] = del;
            unsafe {
                *y.add(ci) = yi + del;
                *ypv.add(ci) = ypi + cj * del;
            }
        }
        let mut gp = core::mem::take(&mut jac.gp);
        dae.note_call();
        let r = {
            let (ys, yps) =
                unsafe { (core::slice::from_raw_parts(y, n), core::slice::from_raw_parts(ypv, n)) };
            dae.residual(t, ys, yps, &mut gp)
        };
        jac.gp = gp;
        for &col in &jac.colors[c] {
            let ci = col as usize;
            unsafe {
                *y.add(ci) = jac.ysave[ci];
                *ypv.add(ci) = jac.ypsave[ci];
            }
        }
        if let Err(e) = r {
            if dae.take_discard() {
                return 1;
            }
            *failed = Some(e);
            return -1;
        }
        for k in 0..jac.colors[c].len() {
            let ci = jac.colors[c][k] as usize;
            let del = jac.del[ci];
            for (slot, &row) in jac.slots[ci].iter().zip(&jac.rows_by_col[ci]) {
                vals[*slot] = (jac.gp[row as usize] - unsafe { *base.add(row as usize) }) / del;
            }
        }
    }
    0
}

unsafe extern "C" fn dae_res(t: f64, yy: NVector, yp: NVector, rr: NVector, user: *mut c_void) -> c_int {
    let c = unsafe { &mut *(user as *mut DaeCtx) };
    let n = c.n;
    let (y, yp, r) = unsafe {
        (
            core::slice::from_raw_parts(nv_data(yy), n),
            core::slice::from_raw_parts(nv_data(yp), n),
            core::slice::from_raw_parts_mut(nv_data(rr), n),
        )
    };
    c.dae.note_call();
    match c.dae.residual(t, y, yp, r) {
        Ok(()) => 0,
        Err(e) => {
            if c.dae.take_discard() {
                return 1;
            }
            c.failed = Some(e);
            -1
        }
    }
}

unsafe extern "C" fn dae_roots(t: f64, yy: NVector, yp: NVector, gout: *mut f64, user: *mut c_void) -> c_int {
    let c = unsafe { &mut *(user as *mut DaeCtx) };
    let (n, n_zc) = (c.n, c.n_zc);
    let (y, yp, g) = unsafe {
        (
            core::slice::from_raw_parts(nv_data(yy), n),
            core::slice::from_raw_parts(nv_data(yp), n),
            core::slice::from_raw_parts_mut(gout, n_zc),
        )
    };
    match c.dae.eval_zc(t, y, yp, g) {
        Ok(()) => 0,
        Err(e) => {
            c.dae.take_discard();
            c.failed = Some(e);
            -1
        }
    }
}

/// IDA over a [`Dae`]: `y = [states | algebraic unknowns]`, `IDASetId` telling the
/// two apart, and `IDACalcIC` making `(y, y')` consistent wherever the integration
/// (re)starts — at the first step and after every event, as `ida_event_update`
/// does for a `--daeMode` model.
pub struct IdaDae {
    ida: Option<Ida>,
    n_states: usize,
    n: usize,
    n_zc: usize,
    tolerance: f64,
    nominals: Vec<f64>,
    pending: Pending,
    past: Counters,
    /// Present once the [`Dae`] has been asked for a sparsity pattern and gave
    /// one; then the linear solver is KLU rather than a dense LU.
    jac: Option<DaeJac>,
    asked_sparsity: bool,
}

impl IdaDae {
    pub fn new(n_states: usize, n_alg: usize, n_zc: usize, tolerance: f64, nominals: &[f64]) -> IdaDae {
        IdaDae {
            ida: None,
            n_states,
            n: n_states + n_alg,
            n_zc,
            tolerance,
            nominals: nominals.to_vec(),
            pending: Pending::Rebuild,
            past: Counters::default(),
            jac: None,
            asked_sparsity: false,
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

    /// Integrate toward `target`; `y` and `yp` hold the point reached, a root
    /// included.
    pub fn step(
        &mut self,
        dae: &mut dyn Dae,
        target: f64,
        t: &mut f64,
        y: &mut [f64],
        yp: &mut [f64],
    ) -> Result<SunStep> {
        if y.is_empty() {
            *t = target;
            return Ok(SunStep::Reached);
        }
        self.prepare(dae, *t, y, yp)?;
        let (n, n_zc, tol) = (self.n, self.n_zc, self.tolerance);
        // Split so the Jacobian's pattern and scratch are borrowed apart from the
        // integrator itself.
        let IdaDae { ida, jac, nominals, .. } = self;
        let ida = ida.as_mut().expect("prepare built it");
        let mem = ida.mem_ptr();
        let mut ctx =
            DaeCtx { dae, n, n_zc, failed: None, jac: jac.as_mut(), mem, tol, nominals };
        if !ida.set_user_data(&mut ctx as *mut DaeCtx as *mut c_void) {
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
        yp.copy_from_slice(ida.yp());
        match stop {
            Stop::Reached | Stop::Stepped => Ok(SunStep::Reached),
            Stop::Root => Ok(SunStep::Root(*t)),
            Stop::Failed(flag) => Err(ida_failure(flag)),
        }
    }

    /// Make `(y, y')` consistent at `t` now — `IDACalcIC` over the algebraic
    /// unknowns and the derivatives — rather than at the next step, so the caller
    /// can report the consistent point.
    pub fn make_consistent(&mut self, dae: &mut dyn Dae, t: f64, y: &mut [f64], yp: &mut [f64]) -> Result<()> {
        if y.is_empty() {
            return Ok(());
        }
        if self.pending == Pending::None {
            self.pending = Pending::Reinit;
        }
        self.prepare(dae, t, y, yp)?;
        let ida = self.ida.as_ref().expect("prepare built it");
        y.copy_from_slice(ida.y());
        yp.copy_from_slice(ida.yp());
        Ok(())
    }

    fn prepare(&mut self, dae: &mut dyn Dae, t: f64, y: &[f64], yp: &[f64]) -> Result<()> {
        let pending = core::mem::replace(&mut self.pending, Pending::None);
        if pending == Pending::None {
            return Ok(());
        }
        if pending == Pending::Rebuild {
            if let Some(ida) = self.ida.take() {
                self.past = add(self.past, ida.counters());
            }
            // Once: the pattern is the model's structure, which does not change
            // across a restart, and asking again would rebuild the colouring.
            if !self.asked_sparsity {
                self.asked_sparsity = true;
                self.jac = dae.sparsity().and_then(|sp| DaeJac::new(sp, self.n));
            }
            let atol = abs_tolerances(self.tolerance, self.n, &self.nominals);
            let root = (self.n_zc > 0).then_some(dae_roots as sundials::IdaRootFn);
            let opts = IdaOptions {
                max_order: crate::simflags::with_flags(|f| f.max_order),
                ..IdaOptions::default()
            };
            // KLU needs a Jacobian of its own: IDA's internal difference-quotient
            // one only fills a dense matrix.
            let (ls, nnz, jac_fn) = match self.jac.as_ref() {
                Some(j) => (IdaLs::Klu, j.nnz(), Some(dae_jac as sundials::IdaJacFn)),
                None => (IdaLs::Dense, 0, None),
            };
            let mut ida = Ida::new(
                t, y, yp, self.tolerance, &atol, self.n_zc, dae_res, root, ls, nnz, jac_fn, &opts,
            )
            .ok_or("ida: the integrator could not be created")?;
            let mut id = vec![1.0; self.n_states];
            id.resize(self.n, 0.0);
            if !ida.set_id(&id, crate::simflags::with_flags(|f| f.ida_no_suppress_alg)) {
                return Err("ida: IDASetId failed");
            }
            self.ida = Some(ida);
        }
        let (n, n_zc, tol) = (self.n, self.n_zc, self.tolerance);
        let IdaDae { ida, jac, nominals, .. } = self;
        let ida = ida.as_mut().expect("built above");
        if pending == Pending::Reinit {
            ida.y_mut().copy_from_slice(y);
            ida.yp_mut().copy_from_slice(yp);
            if !ida.reinit(t) {
                return Err("ida: the integrator could not be restarted");
            }
        }
        let mem = ida.mem_ptr();
        let mut ctx =
            DaeCtx { dae, n, n_zc, failed: None, jac: jac.as_mut(), mem, tol, nominals };
        if !ida.set_user_data(&mut ctx as *mut DaeCtx as *mut c_void) {
            return Err("ida: the context could not be bound");
        }
        let ok = ida.calc_ic_at(t, tol);
        if let Some(e) = ctx.failed {
            return Err(e);
        }
        if !ok {
            return Err("ida: no consistent initial conditions were found (IDACalcIC)");
        }
        Ok(())
    }
}
