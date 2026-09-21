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
type SunNonlinearSolver = *mut c_void;
type SunContext = *mut c_void;
type SunLogger = *mut c_void;
type SunErrHandlerFn = unsafe extern "C" fn(
    c_int,
    *const core::ffi::c_char,
    *const core::ffi::c_char,
    *const core::ffi::c_char,
    c_int,
    *mut c_void,
    SunContext,
);

/// `int f(realtype t, N_Vector y, N_Vector ydot, void *user_data)`.
pub type RhsFn = unsafe extern "C" fn(f64, NVector, NVector, *mut c_void) -> c_int;
/// `int g(realtype t, N_Vector y, realtype *gout, void *user_data)`.
pub type RootFn = unsafe extern "C" fn(f64, NVector, *mut f64, *mut c_void) -> c_int;

const CV_ADAMS: c_int = 1;
const CV_BDF: c_int = 2;
const CV_NORMAL: c_int = 1;

const SUN_SUCCESS: c_int = 0;
const SUN_COMM_NULL: c_int = 0;

const CV_SUCCESS: c_int = 0;
const CV_TSTOP_RETURN: c_int = 1;
const CV_ROOT_RETURN: c_int = 2;

/// A fresh `SUNContext`, or null. One per solver: they carry the last error and
/// the logger, so sharing one across solvers would share that state too.
fn sun_context() -> SunContext {
    let mut ctx: SunContext = core::ptr::null_mut();
    if unsafe { SUNContext_Create(SUN_COMM_NULL, &mut ctx) } != SUN_SUCCESS {
        return core::ptr::null_mut();
    }
    silence_logger(ctx);
    unsafe { SUNContext_PushErrHandler(ctx, err_handler, core::ptr::null_mut()) };
    ctx
}

/// C's `sundialsSilenceLogger`. An empty filename disables a stream.
fn silence_logger(ctx: SunContext) {
    let mut logger: SunLogger = core::ptr::null_mut();
    if unsafe { SUNContext_GetLogger(ctx, &mut logger) } != SUN_SUCCESS || logger.is_null() {
        return;
    }
    let empty = c"".as_ptr();
    unsafe {
        SUNLogger_SetErrorFilename(logger, empty);
        SUNLogger_SetWarningFilename(logger, empty);
        SUNLogger_SetInfoFilename(logger, empty);
        SUNLogger_SetDebugFilename(logger, empty);
    }
}

/// C's `sundialsErrorHandlerFunction`: the muted diagnostics, on `LOG_SOLVER`.
unsafe extern "C" fn err_handler(
    line: c_int,
    func: *const core::ffi::c_char,
    file: *const core::ffi::c_char,
    msg: *const core::ffi::c_char,
    err_code: c_int,
    _user_data: *mut c_void,
    _ctx: SunContext,
) {
    if !crate::omclog::active(crate::omclog::SOLVER) {
        return;
    }
    let text = |p: *const core::ffi::c_char| match p.is_null() {
        true => alloc::string::String::new(),
        false => unsafe { core::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned(),
    };
    crate::omclog::info(crate::omclog::SOLVER, true, "#### SUNDIALS error message #####");
    crate::omclog::info!(
        crate::omclog::SOLVER,
        false,
        " -> error code {err_code}\n -> function {}\n -> at {}:{line}",
        text(func),
        text(file),
    );
    crate::omclog::info!(crate::omclog::SOLVER, false, " Message: {}", text(msg));
    crate::omclog::close(crate::omclog::SOLVER);
}
/// `mxstep` internal steps taken without reaching `tout`; resuming continues.
pub const CV_TOO_MUCH_WORK: c_int = -1;
pub const CV_RTFUNC_FAIL: c_int = -12;

unsafe extern "C" {
    /// `SUNComm` is a plain `int` without MPI, and `SUN_COMM_NULL` is 0.
    fn SUNContext_Create(comm: c_int, ctx: *mut SunContext) -> c_int;
    fn SUNContext_Free(ctx: *mut SunContext) -> c_int;
    fn SUNContext_GetLogger(ctx: SunContext, logger: *mut SunLogger) -> c_int;
    fn SUNContext_PushErrHandler(ctx: SunContext, handler: SunErrHandlerFn, data: *mut c_void) -> c_int;
    fn SUNLogger_SetErrorFilename(logger: SunLogger, name: *const core::ffi::c_char) -> c_int;
    fn SUNLogger_SetWarningFilename(logger: SunLogger, name: *const core::ffi::c_char) -> c_int;
    fn SUNLogger_SetInfoFilename(logger: SunLogger, name: *const core::ffi::c_char) -> c_int;
    fn SUNLogger_SetDebugFilename(logger: SunLogger, name: *const core::ffi::c_char) -> c_int;

    fn N_VNew_Serial(vec_length: SunIndex, ctx: SunContext) -> NVector;
    fn N_VDestroy(v: NVector);
    fn N_VGetArrayPointer(v: NVector) -> *mut f64;

    fn SUNDenseMatrix(m: SunIndex, n: SunIndex, ctx: SunContext) -> SunMatrix;
    fn SUNDenseMatrix_Data(a: SunMatrix) -> *mut f64;
    fn SUNMatDestroy(a: SunMatrix);
    fn SUNLinSol_Dense(y: NVector, a: SunMatrix, ctx: SunContext) -> SunLinearSolver;
    fn SUNLinSolFree(s: SunLinearSolver) -> c_int;

    fn SUNSparseMatrix(m: SunIndex, n: SunIndex, nnz: SunIndex, sparsetype: c_int, ctx: SunContext) -> SunMatrix;
    fn SUNSparseMatrix_Data(a: SunMatrix) -> *mut f64;
    fn SUNSparseMatrix_IndexPointers(a: SunMatrix) -> *mut SunIndex;
    fn SUNSparseMatrix_IndexValues(a: SunMatrix) -> *mut SunIndex;
    fn SUNLinSol_KLU(y: NVector, a: SunMatrix, ctx: SunContext) -> SunLinearSolver;

    fn SUNLinSol_SPGMR(y: NVector, pretype: c_int, maxl: c_int, ctx: SunContext) -> SunLinearSolver;
    fn SUNLinSol_SPBCGS(y: NVector, pretype: c_int, maxl: c_int, ctx: SunContext) -> SunLinearSolver;
    fn SUNLinSol_SPTFQMR(y: NVector, pretype: c_int, maxl: c_int, ctx: SunContext) -> SunLinearSolver;

    fn SUNNonlinSol_FixedPoint(y: NVector, m: c_int, ctx: SunContext) -> SunNonlinearSolver;
    fn SUNNonlinSolFree(s: SunNonlinearSolver) -> c_int;

    fn CVodeCreate(lmm: c_int, ctx: SunContext) -> *mut c_void;
    fn CVodeSetNonlinearSolver(mem: *mut c_void, nls: SunNonlinearSolver) -> c_int;
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
    /// Outlives every object below it; freed last.
    ctx: SunContext,
    mem: *mut c_void,
    y: NVector,
    atol: NVector,
    /// Dense iteration matrix and its solver, owned for the lifetime of `mem`.
    jac: SunMatrix,
    lin_sol: SunLinearSolver,
    /// `CV_ITER_FIXED_POINT` only: the fixed-point module and its work vector.
    /// Null under CVODE's built-in Newton.
    nonlin_sol: SunNonlinearSolver,
    y_nonlin: NVector,
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
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        t0: f64,
        y0: &[f64],
        rtol: f64,
        atol: &[f64],
        n_roots: usize,
        rhs: RhsFn,
        root: Option<RootFn>,
        config: (crate::simflags::CvodeLmm, crate::simflags::CvodeIter),
    ) -> Option<Cvode> {
        use crate::simflags::{CvodeIter, CvodeLmm};
        let (lmm, iter) = config;
        let n = y0.len();
        let ctx = sun_context();
        if ctx.is_null() {
            return None;
        }
        // Owned from here on: each handle is stored as soon as it exists, so a
        // failure below drops `cv` and frees whatever was allocated already.
        // The SUNDIALS free functions all ignore a null handle.
        let mut cv = Cvode {
            ctx,
            mem: core::ptr::null_mut(),
            y: core::ptr::null_mut(),
            atol: core::ptr::null_mut(),
            jac: core::ptr::null_mut(),
            lin_sol: core::ptr::null_mut(),
            nonlin_sol: core::ptr::null_mut(),
            y_nonlin: core::ptr::null_mut(),
            n,
            n_roots,
            roots: vec![0; n_roots.max(1)],
            past: Counters::default(),
        };
        unsafe {
            cv.y = N_VNew_Serial(n as SunIndex, ctx);
            cv.atol = N_VNew_Serial(n as SunIndex, ctx);
            cv.jac = SUNDenseMatrix(n as SunIndex, n as SunIndex, ctx);
            if cv.y.is_null() || cv.atol.is_null() || cv.jac.is_null() {
                return None;
            }
            cv.lin_sol = SUNLinSol_Dense(cv.y, cv.jac, ctx);
            cv.mem = CVodeCreate(
                match lmm {
                    CvodeLmm::Adams => CV_ADAMS,
                    CvodeLmm::Bdf => CV_BDF,
                },
                ctx,
            );
            if cv.lin_sol.is_null() || cv.mem.is_null() {
                return None;
            }
            // Anderson acceleration over as many vectors as the system has states,
            // as `cvode_solver.c` sizes it.
            if iter == CvodeIter::FixedPoint {
                cv.y_nonlin = N_VNew_Serial(n as SunIndex, ctx);
                if cv.y_nonlin.is_null() {
                    return None;
                }
                cv.nonlin_sol = SUNNonlinSol_FixedPoint(cv.y_nonlin, n as c_int, ctx);
                if cv.nonlin_sol.is_null() {
                    return None;
                }
            }
        }
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
                && (cv.nonlin_sol.is_null()
                    || CVodeSetNonlinearSolver(cv.mem, cv.nonlin_sol) == CV_SUCCESS)
                && match root {
                    Some(g) => CVodeRootInit(cv.mem, n_roots as c_int, g) == CV_SUCCESS,
                    None => true,
                }
                // The remaining settings are `cvodeGetConfig`'s defaults.
                && CVodeSetMinStep(cv.mem, 1e-12) == CV_SUCCESS
                && CVodeSetMaxStep(cv.mem, 0.0) == CV_SUCCESS
                && CVodeSetInitStep(cv.mem, 0.0) == CV_SUCCESS
                && CVodeSetMaxOrd(cv.mem, lmm.max_order()) == CV_SUCCESS
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
            SUNNonlinSolFree(self.nonlin_sol);
            N_VDestroy(self.y_nonlin);
            SUNLinSolFree(self.lin_sol);
            SUNMatDestroy(self.jac);
            N_VDestroy(self.atol);
            N_VDestroy(self.y);
            // Last: everything above was created with it.
            SUNContext_Free(&mut self.ctx);
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
pub const IDA_RTFUNC_FAIL: c_int = -12;
/// Error test failures on one step, corrector convergence failures, and a failed
/// linear-solver setup — what `ida_solver_step` restarts from.
pub const IDA_ERR_FAIL: c_int = -3;
pub const IDA_CONV_FAIL: c_int = -4;
pub const IDA_LSETUP_FAIL: c_int = -6;

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
    fn IDACreate(ctx: SunContext) -> *mut c_void;
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
    fn IDASetMaxStep(mem: *mut c_void, hmax: f64) -> c_int;
    fn IDASolve(mem: *mut c_void, tout: f64, tret: *mut f64, yret: NVector, ypret: NVector, itask: c_int) -> c_int;
    fn IDAGetCurrentStep(mem: *mut c_void, hcur: *mut f64) -> c_int;

    fn IDAGetNumSteps(mem: *mut c_void, n: *mut c_long) -> c_int;
    fn IDAGetNumNonlinSolvIters(mem: *mut c_void, n: *mut c_long) -> c_int;
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
    /// Outlives every object below it; freed last.
    ctx: SunContext,
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
    /// The `IDA` handle, for a callback that has to ask IDA something the callback
    /// signature does not carry — [`ida_current_step`], which a difference-quotient
    /// Jacobian's increment scales with, and which changes step by step.
    pub fn mem_ptr(&self) -> *mut c_void {
        self.mem
    }

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
        let ctx = sun_context();
        if ctx.is_null() {
            return None;
        }
        // Owned from here on: each handle is stored as soon as it exists, so a
        // failure below drops `ida` and frees whatever was allocated already.
        // The SUNDIALS free functions all ignore a null handle.
        let mut ida = Ida {
            ctx,
            mem: core::ptr::null_mut(),
            y: core::ptr::null_mut(),
            yp: core::ptr::null_mut(),
            atol: core::ptr::null_mut(),
            jac: core::ptr::null_mut(),
            lin_sol: core::ptr::null_mut(),
            n,
            n_roots,
            roots: vec![0; n_roots.max(1)],
            past: Counters::default(),
            sens: None,
            jac_fn: jac,
        };
        unsafe {
            ida.y = N_VNew_Serial(n as SunIndex, ctx);
            ida.yp = N_VNew_Serial(n as SunIndex, ctx);
            ida.atol = N_VNew_Serial(n as SunIndex, ctx);
            // Matrix-free Krylov keeps `jac` null; every other failure is fatal.
            ida.jac = match ls {
                IdaLs::Dense => SUNDenseMatrix(n as SunIndex, n as SunIndex, ctx),
                IdaLs::Klu => SUNSparseMatrix(n as SunIndex, n as SunIndex, nnz as SunIndex, CSC_MAT, ctx),
                _ => core::ptr::null_mut(),
            };
            if [ida.y, ida.yp, ida.atol].iter().any(|p| p.is_null())
                || (ida.jac.is_null() && !ls.matrix_free())
            {
                return None;
            }
            // Krylov `maxl` is the system size, as `ida_solver.c` passes it.
            ida.lin_sol = match ls {
                IdaLs::Dense => SUNLinSol_Dense(ida.y, ida.jac, ctx),
                IdaLs::Klu => SUNLinSol_KLU(ida.y, ida.jac, ctx),
                IdaLs::Spgmr => SUNLinSol_SPGMR(ida.y, PREC_NONE, n as c_int, ctx),
                IdaLs::Spbcg => SUNLinSol_SPBCGS(ida.y, PREC_NONE, n as c_int, ctx),
                IdaLs::Sptfqmr => SUNLinSol_SPTFQMR(ida.y, PREC_NONE, n as c_int, ctx),
            };
            ida.mem = IDACreate(ctx);
            if ida.lin_sol.is_null() || ida.mem.is_null() {
                return None;
            }
        }
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
        let v = unsafe { N_VNew_Serial(self.n as SunIndex, self.ctx) };
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

    /// C's `IDAflagIsSuccess`: a root return counts, a warning does not.
    fn flag_is_success(flag: c_int) -> bool {
        matches!(flag, IDA_SUCCESS | IDA_TSTOP_RETURN | IDA_ROOT_RETURN)
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

    /// `IDASetMaxStep`; 0 lifts the cap.
    pub fn set_max_step(&mut self, h: f64) -> bool {
        unsafe { IDASetMaxStep(self.mem, h) == IDA_SUCCESS }
    }

    /// `IDACalcIC(IDA_YA_YDP_INIT)`: solve for the algebraic unknowns and every
    /// derivative, `tout1` giving the direction, with `ida_event_update`'s raised
    /// iteration limits.
    fn calc_ic(&mut self, tout1: f64) -> c_int {
        unsafe {
            let lim = (2 * self.n * 10) as c_int;
            IDASetMaxNumStepsIC(self.mem, lim);
            IDASetMaxNumJacsIC(self.mem, lim);
            IDASetMaxNumItersIC(self.mem, lim);
            IDACalcIC(self.mem, IDA_YA_YDP_INIT, tout1)
        }
    }

    fn nonlin_iters(&self) -> c_long {
        let mut n = 0;
        unsafe { IDAGetNumNonlinSolvIters(self.mem, &mut n) };
        n
    }

    fn log_calc_ic(&self, flag: c_int) {
        crate::omclog::info!(
            crate::omclog::SOLVER,
            false,
            "##IDA## IDACalcIC run status {flag}.\nIterations : {}\n",
            self.nonlin_iters(),
        );
    }

    /// Read what `IDACalcIC` settled on back into `y`/`yp`.
    pub fn consistent_ic(&mut self) -> bool {
        unsafe { IDAGetConsistentIC(self.mem, self.y, self.yp) == IDA_SUCCESS }
    }

    /// C's `updateSolverNominals`: the tolerances again, once the nominals the block
    /// was built with are final. `IDASVtolerances` clears `ida_edata` for
    /// `IDAInitialSetup` to put back, which `IDACalcIC` has already run — hence the
    /// re-initialize.
    pub fn set_tolerances(&mut self, t: f64, rtol: f64, atol: &[f64]) -> bool {
        unsafe {
            core::ptr::copy_nonoverlapping(atol.as_ptr(), N_VGetArrayPointer(self.atol), atol.len());
            if IDASVtolerances(self.mem, rtol, self.atol) != IDA_SUCCESS {
                return false;
            }
        }
        self.reinit(t)
    }

    /// C's `ida_event_update`: `IDACalcIC` over the algebraic unknowns and every
    /// derivative at `t`, directed by the step IDA would take next (floored, so a
    /// zero step still gives a direction), retried at `t + tol` with the line search
    /// off — which C leaves off for the rest of the run — and read back into `y`/`yp`.
    pub fn calc_ic_at(&mut self, t: f64, tol: f64) -> bool {
        let mut h = self.actual_init_step();
        if h < f64::EPSILON {
            h = f64::EPSILON;
            self.set_init_step(h);
            crate::omclog::info!(
                crate::omclog::SOLVER,
                false,
                "##IDA## corrected step-size at {}",
                crate::omclog::g(h, 0, 15),
            );
        }
        let mut flag = self.calc_ic(t + h);
        self.log_calc_ic(flag);
        if !Self::flag_is_success(flag) {
            crate::omclog::info(
                crate::omclog::SOLVER,
                false,
                "##IDA## first event iteration failed. Start next try without line search!",
            );
            unsafe { IDASetLineSearchOffIC(self.mem, 1) };
            flag = self.calc_ic(t + tol);
            self.log_calc_ic(flag);
        }
        let ok = Self::flag_is_success(flag) && self.consistent_ic();
        self.set_init_step(0.0);
        ok
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
        // `sens` owns whatever cloned: dropping it here releases a partial set.
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

impl Drop for Sens {
    fn drop(&mut self) {
        unsafe {
            for a in [self.ys, self.yps, self.out] {
                N_VDestroyVectorArray(a, self.ns as c_int);
            }
        }
    }
}

impl Drop for Ida {
    fn drop(&mut self) {
        // Before the block below: the vectors were cloned from `y`/`yp` and made
        // with `ctx`, both freed there.
        drop(self.sens.take());
        unsafe {
            IDAFree(&mut self.mem);
            SUNLinSolFree(self.lin_sol);
            SUNMatDestroy(self.jac);
            N_VDestroy(self.atol);
            N_VDestroy(self.yp);
            N_VDestroy(self.y);
            // Last: everything above was created with it.
            SUNContext_Free(&mut self.ctx);
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
