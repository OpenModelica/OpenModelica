//! CVODE and IDA bindings for the wasm-jit driver.
//!
//! Linked from `libsundials_cvode.a` / `libsundials_idas.a`: the wasm32-wasip1
//! cross-build for the in-wasm runtimes, the C runtime's own archives for the
//! native host-driven driver. Their `SUNDIALS_INDEX_SIZE` differs (32 vs 64), so
//! `build.rs` reports which one this build got — [`SunIndex`] follows it, and
//! IDA's sparse matrix is indexed with it.

use alloc::vec;
use alloc::vec::Vec;
use core::ffi::{c_int, c_long, c_void};

#[cfg(sundials_i64)]
pub type SunIndex = i64;
#[cfg(not(sundials_i64))]
pub type SunIndex = i32;

pub type NVector = *mut c_void;
pub type SunMatrix = *mut c_void;
type SunLinearSolver = *mut c_void;

/// `int f(realtype t, N_Vector y, N_Vector ydot, void *user_data)`.
pub type RhsFn = unsafe extern "C" fn(f64, NVector, NVector, *mut c_void) -> c_int;
/// `int g(realtype t, N_Vector y, realtype *gout, void *user_data)`.
pub type RootFn = unsafe extern "C" fn(f64, NVector, *mut f64, *mut c_void) -> c_int;

const CV_BDF: c_int = 2;
const CV_NORMAL: c_int = 1;

const CV_SUCCESS: c_int = 0;
const CV_TSTOP_RETURN: c_int = 1;
const CV_ROOT_RETURN: c_int = 2;
/// `mxstep` internal steps taken without reaching `tout`; resuming continues.
pub const CV_TOO_MUCH_WORK: c_int = -1;

unsafe extern "C" {
    fn N_VNew_Serial(vec_length: SunIndex) -> NVector;
    fn N_VDestroy(v: NVector);
    fn N_VGetArrayPointer(v: NVector) -> *mut f64;

    fn SUNDenseMatrix(m: SunIndex, n: SunIndex) -> SunMatrix;
    fn SUNDenseMatrix_Data(a: SunMatrix) -> *mut f64;
    fn SUNMatDestroy(a: SunMatrix);
    fn SUNLinSol_Dense(y: NVector, a: SunMatrix) -> SunLinearSolver;
    fn SUNLinSolFree(s: SunLinearSolver) -> c_int;

    fn SUNSparseMatrix(m: SunIndex, n: SunIndex, nnz: SunIndex, sparsetype: c_int) -> SunMatrix;
    fn SUNSparseMatrix_Data(a: SunMatrix) -> *mut f64;
    fn SUNSparseMatrix_IndexPointers(a: SunMatrix) -> *mut SunIndex;
    fn SUNSparseMatrix_IndexValues(a: SunMatrix) -> *mut SunIndex;
    fn SUNLinSol_KLU(y: NVector, a: SunMatrix) -> SunLinearSolver;

    fn SUNLinSol_SPGMR(y: NVector, pretype: c_int, maxl: c_int) -> SunLinearSolver;
    fn SUNLinSol_SPBCGS(y: NVector, pretype: c_int, maxl: c_int) -> SunLinearSolver;
    fn SUNLinSol_SPTFQMR(y: NVector, pretype: c_int, maxl: c_int) -> SunLinearSolver;

    fn CVodeCreate(lmm: c_int) -> *mut c_void;
    fn CVodeFree(mem: *mut *mut c_void);
    fn CVodeInit(mem: *mut c_void, f: RhsFn, t0: f64, y0: NVector) -> c_int;
    fn CVodeReInit(mem: *mut c_void, t0: f64, y0: NVector) -> c_int;
    fn CVodeSVtolerances(mem: *mut c_void, reltol: f64, abstol: NVector) -> c_int;
    fn CVodeSetUserData(mem: *mut c_void, user_data: *mut c_void) -> c_int;
    fn CVodeSetLinearSolver(mem: *mut c_void, ls: SunLinearSolver, a: SunMatrix) -> c_int;
    fn CVodeSetJacFn(mem: *mut c_void, jac: *const c_void) -> c_int;
    fn CVodeRootInit(mem: *mut c_void, nrtfn: c_int, g: RootFn) -> c_int;
    fn CVodeGetRootInfo(mem: *mut c_void, rootsfound: *mut c_int) -> c_int;
    fn CVodeSetMinStep(mem: *mut c_void, hmin: f64) -> c_int;
    fn CVodeSetMaxStep(mem: *mut c_void, hmax: f64) -> c_int;
    fn CVodeSetInitStep(mem: *mut c_void, hin: f64) -> c_int;
    fn CVodeSetMaxOrd(mem: *mut c_void, maxord: c_int) -> c_int;
    fn CVodeSetMaxConvFails(mem: *mut c_void, maxncf: c_int) -> c_int;
    fn CVodeSetMaxNonlinIters(mem: *mut c_void, maxcor: c_int) -> c_int;
    fn CVodeSetMaxErrTestFails(mem: *mut c_void, maxnef: c_int) -> c_int;
    fn CVodeSetMaxNumSteps(mem: *mut c_void, mxsteps: c_long) -> c_int;
    fn CVodeSetStabLimDet(mem: *mut c_void, stldet: c_int) -> c_int;
    fn CVodeSetStopTime(mem: *mut c_void, tstop: f64) -> c_int;
    fn CVode(mem: *mut c_void, tout: f64, yout: NVector, tret: *mut f64, itask: c_int) -> c_int;

    fn CVodeGetNumSteps(mem: *mut c_void, n: *mut c_long) -> c_int;
    fn CVodeGetNumRhsEvals(mem: *mut c_void, n: *mut c_long) -> c_int;
    fn CVodeGetNumJacEvals(mem: *mut c_void, n: *mut c_long) -> c_int;
    fn CVodeGetNumErrTestFails(mem: *mut c_void, n: *mut c_long) -> c_int;
    fn CVodeGetNumNonlinSolvConvFails(mem: *mut c_void, n: *mut c_long) -> c_int;
}

/// Where one [`Cvode::step`] stopped.
pub enum Stop {
    /// `tout` reached.
    Reached,
    /// One-step mode only: an internal step ended before `tout`.
    Stepped,
    /// A root function changed sign at the returned `t` (< `tout`).
    Root,
    Failed(c_int),
}

/// CVODE state for one model: BDF + Newton over a dense internal numerical
/// Jacobian, per-state nominal-scaled tolerances, and CVODE's own root finding
/// on the zero-crossings — the configuration `cvode_solver.c` builds.
pub struct Cvode {
    mem: *mut c_void,
    y: NVector,
    atol: NVector,
    /// Dense iteration matrix and its solver, owned for the lifetime of `mem`.
    jac: SunMatrix,
    lin_sol: SunLinearSolver,
    n: usize,
    n_roots: usize,
    roots: Vec<c_int>,
    /// Run totals; the `CVodeGet*` counters restart with every `CVodeReInit`.
    past: Counters,
}

#[derive(Default, Clone, Copy)]
pub struct Counters {
    pub steps: u64,
    pub rhs_evals: u64,
    pub jac_evals: u64,
    pub err_test_fails: u64,
    pub conv_test_fails: u64,
}

impl Cvode {
    /// Allocate and configure CVODE for `y0.len()` states with `n_roots`
    /// zero-crossings. The callbacks' `user_data` is bound separately, by
    /// [`set_user_data`]. `None` if any SUNDIALS allocation or setup call fails.
    ///
    /// [`set_user_data`]: Cvode::set_user_data
    pub fn new(
        t0: f64,
        y0: &[f64],
        rtol: f64,
        atol: &[f64],
        n_roots: usize,
        rhs: RhsFn,
        root: Option<RootFn>,
    ) -> Option<Cvode> {
        let n = y0.len();
        let mut cv = unsafe {
            let y = N_VNew_Serial(n as SunIndex);
            let atol_v = N_VNew_Serial(n as SunIndex);
            let jac = SUNDenseMatrix(n as SunIndex, n as SunIndex);
            if y.is_null() || atol_v.is_null() || jac.is_null() {
                return None;
            }
            let lin_sol = SUNLinSol_Dense(y, jac);
            let mem = CVodeCreate(CV_BDF);
            if lin_sol.is_null() || mem.is_null() {
                return None;
            }
            Cvode {
                mem,
                y,
                atol: atol_v,
                jac,
                lin_sol,
                n,
                n_roots,
                roots: vec![0; n_roots.max(1)],
                past: Counters::default(),
            }
        };
        cv.set_y(y0);
        unsafe {
            core::ptr::copy_nonoverlapping(atol.as_ptr(), N_VGetArrayPointer(cv.atol), n);
        }
        let ok = unsafe {
            CVodeInit(cv.mem, rhs, t0, cv.y) == CV_SUCCESS
                && CVodeSVtolerances(cv.mem, rtol, cv.atol) == CV_SUCCESS
                && CVodeSetLinearSolver(cv.mem, cv.lin_sol, cv.jac) == CV_SUCCESS
                // NULL: CVODE's internal difference-quotient dense Jacobian, as in C.
                && CVodeSetJacFn(cv.mem, core::ptr::null()) == CV_SUCCESS
                && match root {
                    Some(g) => CVodeRootInit(cv.mem, n_roots as c_int, g) == CV_SUCCESS,
                    None => true,
                }
                // The remaining settings are `cvodeGetConfig`'s defaults.
                && CVodeSetMinStep(cv.mem, 1e-12) == CV_SUCCESS
                && CVodeSetMaxStep(cv.mem, 0.0) == CV_SUCCESS
                && CVodeSetInitStep(cv.mem, 0.0) == CV_SUCCESS
                && CVodeSetMaxOrd(cv.mem, 5) == CV_SUCCESS
                && CVodeSetMaxConvFails(cv.mem, 10) == CV_SUCCESS
                && CVodeSetStabLimDet(cv.mem, 0) == CV_SUCCESS
                && CVodeSetMaxNonlinIters(cv.mem, 5) == CV_SUCCESS
                && CVodeSetMaxErrTestFails(cv.mem, 100) == CV_SUCCESS
                && CVodeSetMaxNumSteps(cv.mem, 1000) == CV_SUCCESS
        };
        ok.then_some(cv)
    }

    fn set_y(&mut self, y: &[f64]) {
        unsafe { core::ptr::copy_nonoverlapping(y.as_ptr(), N_VGetArrayPointer(self.y), self.n) };
    }

    pub fn y(&self) -> &[f64] {
        unsafe { core::slice::from_raw_parts(N_VGetArrayPointer(self.y), self.n) }
    }

    /// The state vector, to write a new starting point into before [`reinit`].
    ///
    /// [`reinit`]: Cvode::reinit
    pub fn y_mut(&mut self) -> &mut [f64] {
        unsafe { core::slice::from_raw_parts_mut(N_VGetArrayPointer(self.y), self.n) }
    }

    /// Restart the integrator at `t` from the current [`y_mut`] contents — after an
    /// event, a state-set switch, or anything else that moved a state behind
    /// CVODE's back. Banks the counters, which `CVodeReInit` resets.
    ///
    /// [`y_mut`]: Cvode::y_mut
    pub fn reinit(&mut self, t: f64) -> bool {
        self.bank();
        unsafe { CVodeReInit(self.mem, t, self.y) == CV_SUCCESS }
    }

    /// Rebind the pointer handed to the `rhs`/`root` callbacks. The driver's
    /// context lives on the stack of one `advance`, so it is set per chunk.
    pub fn set_user_data(&mut self, user_data: *mut c_void) -> bool {
        unsafe { CVodeSetUserData(self.mem, user_data) == CV_SUCCESS }
    }

    /// Integrate to `tout`, stopping early on a root. `t` is updated to where the
    /// integration actually stopped and `y()` holds the state there.
    pub fn step(&mut self, t: &mut f64, tout: f64) -> Stop {
        unsafe {
            let flag = CVodeSetStopTime(self.mem, tout);
            if flag != CV_SUCCESS {
                return Stop::Failed(flag);
            }
            match CVode(self.mem, tout, self.y, t, CV_NORMAL) {
                CV_SUCCESS | CV_TSTOP_RETURN => Stop::Reached,
                CV_ROOT_RETURN => {
                    CVodeGetRootInfo(self.mem, self.roots.as_mut_ptr());
                    Stop::Root
                }
                flag => Stop::Failed(flag),
            }
        }
    }

    /// Which root functions fired at the last [`Stop::Root`] (`CVodeGetRootInfo`).
    pub fn roots(&self) -> &[c_int] {
        &self.roots[..self.n_roots]
    }

    fn get(&self, f: unsafe extern "C" fn(*mut c_void, *mut c_long) -> c_int) -> u64 {
        let mut n: c_long = 0;
        unsafe { f(self.mem, &mut n) };
        n.max(0) as u64
    }

    /// Fold the current segment's counters into the run totals.
    fn bank(&mut self) {
        let c = self.segment();
        self.past.steps += c.steps;
        self.past.rhs_evals += c.rhs_evals;
        self.past.jac_evals += c.jac_evals;
        self.past.err_test_fails += c.err_test_fails;
        self.past.conv_test_fails += c.conv_test_fails;
    }

    fn segment(&self) -> Counters {
        Counters {
            steps: self.get(CVodeGetNumSteps),
            rhs_evals: self.get(CVodeGetNumRhsEvals),
            jac_evals: self.get(CVodeGetNumJacEvals),
            err_test_fails: self.get(CVodeGetNumErrTestFails),
            conv_test_fails: self.get(CVodeGetNumNonlinSolvConvFails),
        }
    }

    pub fn counters(&self) -> Counters {
        let c = self.segment();
        Counters {
            steps: self.past.steps + c.steps,
            rhs_evals: self.past.rhs_evals + c.rhs_evals,
            jac_evals: self.past.jac_evals + c.jac_evals,
            err_test_fails: self.past.err_test_fails + c.err_test_fails,
            conv_test_fails: self.past.conv_test_fails + c.conv_test_fails,
        }
    }
}

impl Drop for Cvode {
    fn drop(&mut self) {
        unsafe {
            CVodeFree(&mut self.mem);
            SUNLinSolFree(self.lin_sol);
            SUNMatDestroy(self.jac);
            N_VDestroy(self.atol);
            N_VDestroy(self.y);
        }
    }
}

/// An `N_Vector`'s data as a raw pointer, for the callbacks.
pub fn nv_data(v: NVector) -> *mut f64 {
    unsafe { N_VGetArrayPointer(v) }
}

/// `int F(realtype t, N_Vector yy, N_Vector yp, N_Vector rr, void *user_data)`.
pub type IdaResFn = unsafe extern "C" fn(f64, NVector, NVector, NVector, *mut c_void) -> c_int;
/// `int g(realtype t, N_Vector yy, N_Vector yp, realtype *gout, void *user_data)`.
pub type IdaRootFn = unsafe extern "C" fn(f64, NVector, NVector, *mut f64, *mut c_void) -> c_int;
/// `IDALsJacFn`: `J = ∂F/∂y + cj·∂F/∂y'`.
#[rustfmt::skip]
pub type IdaJacFn = unsafe extern "C" fn(
    f64, f64, NVector, NVector, NVector, SunMatrix, *mut c_void, NVector, NVector, NVector,
) -> c_int;

/// `mxstep` internal steps taken without reaching `tout`; resuming continues.
pub const IDA_TOO_MUCH_WORK: c_int = -1;

const IDA_NORMAL: c_int = 1;
const IDA_ONE_STEP: c_int = 2;
const IDA_SUCCESS: c_int = 0;
/// `IDACalcIC`'s `icopt`: solve for the algebraic components of `y` and all of `y'`.
const IDA_YA_YDP_INIT: c_int = 1;
const IDA_TSTOP_RETURN: c_int = 1;
const IDA_ROOT_RETURN: c_int = 2;
const CSC_MAT: c_int = 0;
/// The Krylov solvers run unpreconditioned, as `ida_solver.c` builds them.
const PREC_NONE: c_int = 0;

unsafe extern "C" {
    fn IDACreate() -> *mut c_void;
    fn IDAFree(mem: *mut *mut c_void);
    fn IDAInit(mem: *mut c_void, res: IdaResFn, t0: f64, yy0: NVector, yp0: NVector) -> c_int;
    fn IDAReInit(mem: *mut c_void, t0: f64, yy0: NVector, yp0: NVector) -> c_int;
    fn IDASVtolerances(mem: *mut c_void, reltol: f64, abstol: NVector) -> c_int;
    fn IDASetUserData(mem: *mut c_void, user_data: *mut c_void) -> c_int;
    fn IDASetLinearSolver(mem: *mut c_void, ls: SunLinearSolver, a: SunMatrix) -> c_int;
    fn IDASetJacFn(mem: *mut c_void, jac: Option<IdaJacFn>) -> c_int;
    fn IDARootInit(mem: *mut c_void, nrtfn: c_int, g: IdaRootFn) -> c_int;
    fn IDAGetRootInfo(mem: *mut c_void, rootsfound: *mut c_int) -> c_int;
    fn IDASetMaxOrd(mem: *mut c_void, maxord: c_int) -> c_int;
    fn IDASetMaxErrTestFails(mem: *mut c_void, maxnef: c_int) -> c_int;
    fn IDASetMaxNonlinIters(mem: *mut c_void, maxcor: c_int) -> c_int;
    fn IDASetMaxConvFails(mem: *mut c_void, maxncf: c_int) -> c_int;
    fn IDASetNonlinConvCoef(mem: *mut c_void, epcon: f64) -> c_int;
    fn IDASetInitStep(mem: *mut c_void, hin: f64) -> c_int;
    fn IDASolve(mem: *mut c_void, tout: f64, tret: *mut f64, yret: NVector, ypret: NVector, itask: c_int) -> c_int;
    fn IDAGetCurrentStep(mem: *mut c_void, hcur: *mut f64) -> c_int;

    fn IDAGetNumSteps(mem: *mut c_void, n: *mut c_long) -> c_int;
    fn IDAGetNumResEvals(mem: *mut c_void, n: *mut c_long) -> c_int;
    fn IDAGetNumJacEvals(mem: *mut c_void, n: *mut c_long) -> c_int;
    fn IDAGetNumErrTestFails(mem: *mut c_void, n: *mut c_long) -> c_int;
    fn IDAGetNumNonlinSolvConvFails(mem: *mut c_void, n: *mut c_long) -> c_int;
    // `--daeMode`: mark the algebraic unknowns and solve for consistent values.
    fn IDASetId(mem: *mut c_void, id: NVector) -> c_int;
    fn IDASetSuppressAlg(mem: *mut c_void, suppressalg: c_int) -> c_int;
    fn IDACalcIC(mem: *mut c_void, icopt: c_int, tout1: f64) -> c_int;
    fn IDAGetConsistentIC(mem: *mut c_void, yy0: NVector, yp0: NVector) -> c_int;
    fn IDAGetActualInitStep(mem: *mut c_void, hinused: *mut f64) -> c_int;
    fn IDASetLineSearchOffIC(mem: *mut c_void, lsoff: c_int) -> c_int;
    fn IDASetMaxNumStepsIC(mem: *mut c_void, maxnh: c_int) -> c_int;
    fn IDASetMaxNumJacsIC(mem: *mut c_void, maxnj: c_int) -> c_int;
    fn IDASetMaxNumItersIC(mem: *mut c_void, maxnit: c_int) -> c_int;

    fn N_VCloneVectorArray(count: c_int, w: NVector) -> *mut NVector;
    fn N_VDestroyVectorArray(vs: *mut NVector, count: c_int);
    fn N_VConst(c: f64, z: NVector);
    fn IDASensInit(mem: *mut c_void, ns: c_int, ism: c_int, res: *const c_void, ys0: *mut NVector, yps0: *mut NVector) -> c_int;
    fn IDASensReInit(mem: *mut c_void, ism: c_int, ys0: *mut NVector, yps0: *mut NVector) -> c_int;
    fn IDASetSensParams(mem: *mut c_void, p: *mut f64, pbar: *mut f64, plist: *mut c_int) -> c_int;
    fn IDASetSensDQMethod(mem: *mut c_void, dqtype: c_int, dqrhomax: f64) -> c_int;
    fn IDASensEEtolerances(mem: *mut c_void) -> c_int;
    fn IDAGetSens(mem: *mut c_void, tret: *mut f64, ys: *mut NVector) -> c_int;
}

const IDA_SIMULTANEOUS: c_int = 1;
const IDA_FORWARD: c_int = 2;

/// `-idaLS`. The Krylov ones are matrix-free: no `SUNMatrix`, no Jacobian, IDA's
/// own difference-quotient Jacobian-vector product instead.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum IdaLs {
    Dense,
    /// C's default. Needs the model's Jacobian sparsity pattern.
    Klu,
    Spgmr,
    Spbcg,
    Sptfqmr,
}

impl IdaLs {
    pub fn matrix_free(self) -> bool {
        matches!(self, IdaLs::Spgmr | IdaLs::Spbcg | IdaLs::Sptfqmr)
    }
}

/// The `IDASet*` tunables `ida_solver_initial` takes from simulation flags;
/// `None` leaves the default.
#[derive(Clone, Copy, Default)]
pub struct IdaOptions {
    pub max_order: Option<c_int>,
    pub max_err_test_fails: Option<c_int>,
    pub max_nonlin_iters: Option<c_int>,
    pub max_conv_fails: Option<c_int>,
    pub nonlin_conv_coef: Option<f64>,
    pub init_step: Option<f64>,
}

/// IDA state for one model: BDF over the residual `F(t, y, y')`, per-state
/// nominal-scaled tolerances, KLU or dense direct linear solver, and IDA's own
/// root finding on the zero-crossings — the configuration `ida_solver.c` builds.
pub struct Ida {
    mem: *mut c_void,
    y: NVector,
    yp: NVector,
    atol: NVector,
    /// Iteration matrix and its solver, owned for the lifetime of `mem`.
    jac: SunMatrix,
    lin_sol: SunLinearSolver,
    n: usize,
    n_roots: usize,
    roots: Vec<c_int>,
    /// Run totals; the `IDAGet*` counters restart with every `IDAReInit`.
    past: Counters,
    sens: Option<Sens>,
    /// Kept so [`set_user_data`](Ida::set_user_data) can re-arm it.
    jac_fn: Option<IdaJacFn>,
}

/// IDAS forward sensitivity state (`-idaSensitivity`). `p` is what IDAS perturbs
/// to difference `dF/dp`; `plist`/`pbar` are left at their defaults (identity,
/// 1), so it holds exactly the differentiated parameters in block order.
struct Sens {
    ns: usize,
    ys: *mut NVector,
    yps: *mut NVector,
    /// Where `IDAGetSens` deposits the result; `ys` stays the restart value.
    out: *mut NVector,
    p: Vec<f64>,
}

impl Ida {
    /// `nnz` is the sparse pattern's nonzero count ([`IdaLs::Klu`] only); `jac`
    /// is `None` for IDA's internal difference-quotient Jacobian. `user_data` is
    /// bound separately, by [`set_user_data`](Ida::set_user_data).
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        t0: f64,
        y0: &[f64],
        yp0: &[f64],
        rtol: f64,
        atol: &[f64],
        n_roots: usize,
        res: IdaResFn,
        root: Option<IdaRootFn>,
        ls: IdaLs,
        nnz: usize,
        jac: Option<IdaJacFn>,
        opts: &IdaOptions,
    ) -> Option<Ida> {
        let n = y0.len();
        let mut ida = unsafe {
            let y = N_VNew_Serial(n as SunIndex);
            let yp = N_VNew_Serial(n as SunIndex);
            let atol_v = N_VNew_Serial(n as SunIndex);
            let j = match ls {
                IdaLs::Dense => SUNDenseMatrix(n as SunIndex, n as SunIndex),
                IdaLs::Klu => SUNSparseMatrix(n as SunIndex, n as SunIndex, nnz as SunIndex, CSC_MAT),
                _ => core::ptr::null_mut(),
            };
            if [y, yp, atol_v].iter().any(|p| p.is_null()) || (j.is_null() && !ls.matrix_free()) {
                return None;
            }
            // Krylov `maxl` is the system size, as `ida_solver.c` passes it.
            let lin_sol = match ls {
                IdaLs::Dense => SUNLinSol_Dense(y, j),
                IdaLs::Klu => SUNLinSol_KLU(y, j),
                IdaLs::Spgmr => SUNLinSol_SPGMR(y, PREC_NONE, n as c_int),
                IdaLs::Spbcg => SUNLinSol_SPBCGS(y, PREC_NONE, n as c_int),
                IdaLs::Sptfqmr => SUNLinSol_SPTFQMR(y, PREC_NONE, n as c_int),
            };
            let mem = IDACreate();
            if lin_sol.is_null() || mem.is_null() {
                return None;
            }
            Ida {
                mem,
                y,
                yp,
                atol: atol_v,
                jac: j,
                lin_sol,
                n,
                n_roots,
                roots: vec![0; n_roots.max(1)],
                past: Counters::default(),
                sens: None,
                jac_fn: jac,
            }
        };
        ida.y_mut().copy_from_slice(y0);
        ida.yp_mut().copy_from_slice(yp0);
        unsafe {
            core::ptr::copy_nonoverlapping(atol.as_ptr(), N_VGetArrayPointer(ida.atol), n);
        }
        let ok = unsafe {
            IDAInit(ida.mem, res, t0, ida.y, ida.yp) == IDA_SUCCESS
                && IDASVtolerances(ida.mem, rtol, ida.atol) == IDA_SUCCESS
                && IDASetLinearSolver(ida.mem, ida.lin_sol, ida.jac) == IDA_SUCCESS
                && IDASetJacFn(ida.mem, jac) == IDA_SUCCESS
                && match root {
                    Some(g) => IDARootInit(ida.mem, n_roots as c_int, g) == IDA_SUCCESS,
                    None => true,
                }
        };
        let ok = ok && ida.apply(opts);
        ok.then_some(ida)
    }

    fn apply(&mut self, o: &IdaOptions) -> bool {
        let set = |flag: c_int| flag == IDA_SUCCESS;
        unsafe {
            o.max_order.is_none_or(|v| set(IDASetMaxOrd(self.mem, v)))
                && o.max_err_test_fails.is_none_or(|v| set(IDASetMaxErrTestFails(self.mem, v)))
                && o.max_nonlin_iters.is_none_or(|v| set(IDASetMaxNonlinIters(self.mem, v)))
                && o.max_conv_fails.is_none_or(|v| set(IDASetMaxConvFails(self.mem, v)))
                && o.nonlin_conv_coef.is_none_or(|v| set(IDASetNonlinConvCoef(self.mem, v)))
                && o.init_step.is_none_or(|v| set(IDASetInitStep(self.mem, v)))
        }
    }

    /// The IDA memory block, for the `IDAGet*` a callback needs.
    pub fn mem(&self) -> *mut c_void {
        self.mem
    }

    /// `--daeMode`: which unknowns are differential (`1`) and which algebraic (`0`),
    /// so `IDACalcIC` can solve for the latter and (with `suppress_alg`) the local
    /// error test can leave them out.
    pub fn set_id(&mut self, id: &[f64], suppress_alg: bool) -> bool {
        let v = unsafe { N_VNew_Serial(self.n as SunIndex) };
        if v.is_null() {
            return false;
        }
        unsafe {
            core::ptr::copy_nonoverlapping(id.as_ptr(), N_VGetArrayPointer(v), self.n);
            let ok = (!suppress_alg || IDASetSuppressAlg(self.mem, 1) == IDA_SUCCESS)
                && IDASetId(self.mem, v) == IDA_SUCCESS;
            // IDA keeps its own copy of `id`.
            N_VDestroy(v);
            ok
        }
    }

    /// The step IDA would take first; `IDACalcIC` needs a nonzero one.
    pub fn actual_init_step(&self) -> f64 {
        let mut h = 0.0;
        unsafe { IDAGetActualInitStep(self.mem, &mut h) };
        h
    }

    pub fn set_init_step(&mut self, h: f64) -> bool {
        unsafe { IDASetInitStep(self.mem, h) == IDA_SUCCESS }
    }

    /// `IDACalcIC(IDA_YA_YDP_INIT)`: solve for the algebraic unknowns and every
    /// derivative, `tout1` giving the direction. Raised iteration limits as in
    /// `ida_event_update`; `line_search` off is C's retry.
    pub fn calc_ic(&mut self, tout1: f64, line_search: bool) -> bool {
        unsafe {
            let lim = (2 * self.n * 10) as c_int;
            IDASetMaxNumStepsIC(self.mem, lim);
            IDASetMaxNumJacsIC(self.mem, lim);
            IDASetMaxNumItersIC(self.mem, lim);
            IDASetLineSearchOffIC(self.mem, !line_search as c_int);
            IDACalcIC(self.mem, IDA_YA_YDP_INIT, tout1) == IDA_SUCCESS
        }
    }

    /// Read what [`calc_ic`](Ida::calc_ic) settled on back into `y`/`yp`.
    pub fn consistent_ic(&mut self) -> bool {
        unsafe { IDAGetConsistentIC(self.mem, self.y, self.yp) == IDA_SUCCESS }
    }

    /// Start forward sensitivity analysis over `p0`, the differentiated
    /// parameters' current values, in `ida_solver_initial`'s configuration:
    /// sensitivities from zero, IDAS's own forward difference quotients.
    pub fn init_sensitivities(&mut self, p0: &[f64]) -> bool {
        let ns = p0.len();
        let mut sens = unsafe {
            Sens {
                ns,
                ys: N_VCloneVectorArray(ns as c_int, self.y),
                yps: N_VCloneVectorArray(ns as c_int, self.yp),
                out: N_VCloneVectorArray(ns as c_int, self.y),
                p: p0.to_vec(),
            }
        };
        if [sens.ys, sens.yps, sens.out].iter().any(|a| a.is_null()) {
            return false;
        }
        sens.zero();
        let ok = unsafe {
            IDASensInit(self.mem, ns as c_int, IDA_SIMULTANEOUS, core::ptr::null(), sens.ys, sens.yps)
                == IDA_SUCCESS
                && IDASetSensParams(self.mem, sens.p.as_mut_ptr(), core::ptr::null_mut(), core::ptr::null_mut())
                    == IDA_SUCCESS
                && IDASetSensDQMethod(self.mem, IDA_FORWARD, 0.0) == IDA_SUCCESS
                && IDASensEEtolerances(self.mem) == IDA_SUCCESS
        };
        self.sens = Some(sens);
        ok
    }

    /// The parameter values IDAS is currently differencing over; the residual
    /// writes them into the model, which is how a perturbation reaches `f`.
    pub fn sens_params(&self) -> Option<&[f64]> {
        self.sens.as_ref().map(|s| s.p.as_slice())
    }

    /// `d(state)/d(parameter)` at the last accepted point, parameter-major
    /// (`out.len() == ns * n`).
    pub fn sens_values(&mut self, out: &mut [f64]) -> bool {
        let Some(sens) = self.sens.as_ref() else { return false };
        let mut t = 0.0;
        if unsafe { IDAGetSens(self.mem, &mut t, sens.out) } != IDA_SUCCESS {
            return false;
        }
        for i in 0..sens.ns {
            let src = unsafe { core::slice::from_raw_parts(N_VGetArrayPointer(*sens.out.add(i)), self.n) };
            out[i * self.n..(i + 1) * self.n].copy_from_slice(src);
        }
        true
    }

    pub fn y(&self) -> &[f64] {
        unsafe { core::slice::from_raw_parts(N_VGetArrayPointer(self.y), self.n) }
    }

    pub fn yp(&self) -> &[f64] {
        unsafe { core::slice::from_raw_parts(N_VGetArrayPointer(self.yp), self.n) }
    }

    /// The state vector, to write a new starting point into before
    /// [`reinit`](Ida::reinit).
    pub fn y_mut(&mut self) -> &mut [f64] {
        unsafe { core::slice::from_raw_parts_mut(N_VGetArrayPointer(self.y), self.n) }
    }

    /// The derivative vector; IDA needs a consistent `y'` at every restart.
    pub fn yp_mut(&mut self) -> &mut [f64] {
        unsafe { core::slice::from_raw_parts_mut(N_VGetArrayPointer(self.yp), self.n) }
    }

    /// Restart at `t` from the current `y`/`y'` — after an event, a state-set
    /// switch, or anything else that moved a state behind IDA's back. Banks the
    /// counters, which `IDAReInit` resets.
    pub fn reinit(&mut self, t: f64) -> bool {
        self.bank();
        if unsafe { IDAReInit(self.mem, t, self.y, self.yp) } != IDA_SUCCESS {
            return false;
        }
        // C restarts the sensitivities from zero at every event too.
        match self.sens.as_ref() {
            None => true,
            Some(s) => {
                s.zero();
                unsafe { IDASensReInit(self.mem, IDA_SIMULTANEOUS, s.ys, s.yps) == IDA_SUCCESS }
            }
        }
    }

    /// Rebind the pointer handed to the `res`/`root`/`jac` callbacks. The
    /// driver's context lives on the stack of one `advance`, so it is set per
    /// chunk.
    /// Bind the callbacks' context, re-arming the Jacobian with it: the linear solver
    /// caches `user_data` as its `J_data` in `IDASetJacFn` (and in `idaLsInitialize`,
    /// which only runs on the first solve after an `IDAReInit`), so a plain
    /// `IDASetUserData` would leave the Jacobian callback on the previous context.
    pub fn set_user_data(&mut self, user_data: *mut c_void) -> bool {
        unsafe {
            IDASetUserData(self.mem, user_data) == IDA_SUCCESS
                && match self.jac_fn {
                    Some(f) => IDASetJacFn(self.mem, Some(f)) == IDA_SUCCESS,
                    None => true,
                }
        }
    }

    /// Integrate to `tout`, stopping early on a root. `t` is updated to where the
    /// integration actually stopped and `y()`/`yp()` hold the state there. No
    /// `IDASetStopTime`, as in `ida_solver.c`: IDA may step past `tout` internally
    /// and interpolate back to it. `one_step` is `ida_solver.c`'s `idaSmode` under
    /// `-noEquidistantTimeGrid`: return after each internal step.
    pub fn step(&mut self, t: &mut f64, tout: f64, one_step: bool) -> Stop {
        let mode = if one_step { IDA_ONE_STEP } else { IDA_NORMAL };
        unsafe {
            match IDASolve(self.mem, tout, t, self.y, self.yp, mode) {
                IDA_SUCCESS if one_step && *t < tout => Stop::Stepped,
                IDA_SUCCESS | IDA_TSTOP_RETURN => Stop::Reached,
                IDA_ROOT_RETURN => {
                    IDAGetRootInfo(self.mem, self.roots.as_mut_ptr());
                    Stop::Root
                }
                flag => Stop::Failed(flag),
            }
        }
    }

    /// Which root functions fired at the last [`Stop::Root`] (`IDAGetRootInfo`).
    pub fn roots(&self) -> &[c_int] {
        &self.roots[..self.n_roots]
    }

    fn get(&self, f: unsafe extern "C" fn(*mut c_void, *mut c_long) -> c_int) -> u64 {
        let mut n: c_long = 0;
        unsafe { f(self.mem, &mut n) };
        n.max(0) as u64
    }

    /// Fold the current segment's counters into the run totals.
    fn bank(&mut self) {
        let c = self.segment();
        self.past.steps += c.steps;
        self.past.rhs_evals += c.rhs_evals;
        self.past.jac_evals += c.jac_evals;
        self.past.err_test_fails += c.err_test_fails;
        self.past.conv_test_fails += c.conv_test_fails;
    }

    fn segment(&self) -> Counters {
        Counters {
            steps: self.get(IDAGetNumSteps),
            rhs_evals: self.get(IDAGetNumResEvals),
            jac_evals: self.get(IDAGetNumJacEvals),
            err_test_fails: self.get(IDAGetNumErrTestFails),
            conv_test_fails: self.get(IDAGetNumNonlinSolvConvFails),
        }
    }

    pub fn counters(&self) -> Counters {
        let c = self.segment();
        Counters {
            steps: self.past.steps + c.steps,
            rhs_evals: self.past.rhs_evals + c.rhs_evals,
            jac_evals: self.past.jac_evals + c.jac_evals,
            err_test_fails: self.past.err_test_fails + c.err_test_fails,
            conv_test_fails: self.past.conv_test_fails + c.conv_test_fails,
        }
    }
}

impl Sens {
    fn zero(&self) {
        for i in 0..self.ns {
            unsafe {
                N_VConst(0.0, *self.ys.add(i));
                N_VConst(0.0, *self.yps.add(i));
            }
        }
    }
}

impl Drop for Ida {
    fn drop(&mut self) {
        if let Some(s) = self.sens.take() {
            unsafe {
                for a in [s.ys, s.yps, s.out] {
                    N_VDestroyVectorArray(a, s.ns as c_int);
                }
            }
        }
        unsafe {
            IDAFree(&mut self.mem);
            SUNLinSolFree(self.lin_sol);
            SUNMatDestroy(self.jac);
            N_VDestroy(self.atol);
            N_VDestroy(self.yp);
            N_VDestroy(self.y);
        }
    }
}

/// The step size IDA is currently attempting, the scale `ida_solver.c`'s
/// difference quotient measures `y'` against.
pub fn ida_current_step(mem: *mut c_void) -> f64 {
    let mut h = 0.0;
    unsafe { IDAGetCurrentStep(mem, &mut h) };
    h
}

/// A dense `SUNMatrix`'s column-major data, `n*n` in length.
pub fn dense_data(a: SunMatrix) -> *mut f64 {
    unsafe { SUNDenseMatrix_Data(a) }
}

/// The three arrays of a CSC `SUNMatrix`, for a Jacobian callback to fill.
pub fn sparse_arrays(a: SunMatrix) -> (*mut f64, *mut SunIndex, *mut SunIndex) {
    unsafe {
        (SUNSparseMatrix_Data(a), SUNSparseMatrix_IndexPointers(a), SUNSparseMatrix_IndexValues(a))
    }
}
