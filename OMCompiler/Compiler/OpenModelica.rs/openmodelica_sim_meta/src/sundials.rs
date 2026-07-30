//! CVODE bindings for the wasm-jit driver.
//!
//! Linked from `libsundials_cvode.a`: the wasm32-wasip1 cross-build for the
//! in-wasm runtimes, the C runtime's own archive for the native host-driven
//! driver. Their `SUNDIALS_INDEX_SIZE` differs (32 vs 64), so `build.rs` reports
//! which one this build got. It reaches only the two dimension arguments below —
//! CVODE with a dense matrix hands SUNDIALS no index array.

use alloc::vec;
use alloc::vec::Vec;
use core::ffi::{c_int, c_long, c_void};

#[cfg(sundials_i64)]
type SunIndex = i64;
#[cfg(not(sundials_i64))]
type SunIndex = i32;

pub type NVector = *mut c_void;
type SunMatrix = *mut c_void;
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
    fn SUNMatDestroy(a: SunMatrix);
    fn SUNLinSol_Dense(y: NVector, a: SunMatrix) -> SunLinearSolver;
    fn SUNLinSolFree(s: SunLinearSolver) -> c_int;

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
