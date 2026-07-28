//! The real SUNDIALS/KLU, cross-compiled to wasm and linked in by `build.rs`
//! (`cfg(sundials)`).
//!
//! Indices are `i32` (`SUNDIALS_INDEX_SIZE=32`, see the build script for why) and
//! `sunrealtype` is `f64`.

use core::sync::atomic::{AtomicBool, Ordering};

/// Whether the real solvers are linked into this blob.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sundials_available() -> i32 {
    cfg!(sundials) as i32
}

/// What this build can serve, for `simflags::check`.
#[cfg(any(feature = "session", feature = "standalone"))]
pub fn capabilities() -> openmodelica_sim_meta::simflags::Capabilities {
    openmodelica_sim_meta::simflags::Capabilities {
        klu: cfg!(sundials),
        ida: false,
        cvode: false,
        gbode: false,
    }
}

// Solver selection, with C's defaults: dense systems go to LAPACK, sparse ones to
// KLU (`-ls=lapack`, `-lss=klu`, `-nlsLS=klu`).

static KLU_LS: AtomicBool = AtomicBool::new(false);
static KLU_LSS: AtomicBool = AtomicBool::new(true);
static KLU_NLS_LS: AtomicBool = AtomicBool::new(true);

/// Which backend serves a sparse solve.
#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum Sparse {
    Klu,
    Rsparse,
}

fn pick(klu: &AtomicBool) -> Sparse {
    if cfg!(sundials) && klu.load(Ordering::Relaxed) {
        Sparse::Klu
    } else {
        Sparse::Rsparse
    }
}

/// `-lss`: torn linear systems solved sparsely.
pub(crate) fn lss_backend() -> Sparse {
    pick(&KLU_LSS)
}

/// `-nlsLS`: the linear solver inside the sparse nonlinear solver.
pub(crate) fn nls_ls_backend() -> Sparse {
    pick(&KLU_NLS_LS)
}

/// `-ls=klu`: dense-stored linear systems handed to KLU.
pub(crate) fn ls_is_klu() -> bool {
    cfg!(sundials) && KLU_LS.load(Ordering::Relaxed)
}

fn set_klu(ls: bool, lss: bool, nls_ls: bool) {
    KLU_LS.store(ls, Ordering::Relaxed);
    KLU_LSS.store(lss, Ordering::Relaxed);
    KLU_NLS_LS.store(nls_ls, Ordering::Relaxed);
}

/// The three selectors for a host-driven run: that build links no flag store, so
/// its host parses `-ls`/`-lss`/`-nlsLS` and sets the bits here.
#[unsafe(no_mangle)]
pub extern "C" fn rt_lin_set_klu(ls: i32, lss: i32, nls_ls: i32) {
    set_klu(ls != 0, lss != 0, nls_ls != 0);
}

#[cfg(any(feature = "session", feature = "standalone"))]
pub(crate) fn apply_flags(f: &openmodelica_sim_meta::simflags::SimFlags) {
    let (ls, lss, nls_ls) = f.klu_selectors();
    set_klu(ls, lss, nls_ls);
}

/// Smoke test that the archives are linked and callable: `klu_defaults` reports
/// success and its values land where [`klu::Common`] mirrors them, and KINSOL
/// allocates.
#[cfg(sundials)]
#[unsafe(no_mangle)]
pub extern "C" fn rt_sundials_selftest() -> i32 {
    let common_ok = klu::Common::defaults().is_some();
    let mut kin = unsafe { kinsol::KINCreate() };
    let kin_ok = !kin.is_null();
    if kin_ok {
        unsafe { kinsol::KINFree(&mut kin) };
    }
    (common_ok && kin_ok) as i32
}

#[cfg(not(sundials))]
#[unsafe(no_mangle)]
pub extern "C" fn rt_sundials_selftest() -> i32 {
    0
}

#[cfg(sundials)]
pub(crate) mod klu {
    use alloc::vec::Vec;
    use core::ffi::c_void;

    /// `klu_common` of the `SUNDIALS_INDEX_SIZE=32` build (`Int` = `int`), mirrored
    /// rather than opaque because the factor/refactor decision reads `status` and
    /// `rgrowth`. [`Common::defaults`] validates the layout against what
    /// `klu_defaults` writes.
    #[repr(C)]
    pub struct Common {
        pub tol: f64,
        pub memgrow: f64,
        pub initmem_amd: f64,
        pub initmem: f64,
        pub maxwork: f64,
        pub btf: i32,
        pub ordering: i32,
        pub scale: i32,
        pub user_order: *mut c_void,
        pub user_data: *mut c_void,
        pub halt_if_singular: i32,
        pub status: i32,
        pub nrealloc: i32,
        pub structural_rank: i32,
        pub numerical_rank: i32,
        pub singular_col: i32,
        pub noffdiag: i32,
        pub flops: f64,
        pub rcond: f64,
        pub condest: f64,
        pub rgrowth: f64,
        pub work: f64,
        pub memusage: usize,
        pub mempeak: usize,
    }

    unsafe extern "C" {
        pub fn klu_defaults(common: *mut Common) -> i32;
        pub fn klu_analyze(n: i32, ap: *mut i32, ai: *mut i32, common: *mut Common) -> *mut c_void;
        pub fn klu_factor(ap: *mut i32, ai: *mut i32, ax: *mut f64, symbolic: *mut c_void, common: *mut Common) -> *mut c_void;
        pub fn klu_refactor(ap: *mut i32, ai: *mut i32, ax: *mut f64, symbolic: *mut c_void, numeric: *mut c_void, common: *mut Common) -> i32;
        pub fn klu_rgrowth(ap: *mut i32, ai: *mut i32, ax: *mut f64, symbolic: *mut c_void, numeric: *mut c_void, common: *mut Common) -> i32;
        pub fn klu_solve(symbolic: *mut c_void, numeric: *mut c_void, ldim: i32, nrhs: i32, b: *mut f64, common: *mut Common) -> i32;
        pub fn klu_free_symbolic(symbolic: *mut *mut c_void, common: *mut Common) -> i32;
        pub fn klu_free_numeric(numeric: *mut *mut c_void, common: *mut Common) -> i32;
    }

    impl Common {
        /// `klu_defaults`, `None` if the values did not land where this mirror puts
        /// them — a layout mismatch would otherwise show up as silent nonsense.
        pub fn defaults() -> Option<Common> {
            let mut c: Common = unsafe { core::mem::zeroed() };
            if unsafe { klu_defaults(&mut c) } != 1 {
                return None;
            }
            let laid_out = c.tol == 0.001
                && c.initmem == 10.0
                && c.btf == 1
                && c.scale == 2
                && c.halt_if_singular == 1
                && c.status == 0
                && c.structural_rank == -1
                && c.rgrowth == -1.0
                && c.memusage == 0;
            laid_out.then_some(c)
        }
    }

    /// C's `DATA_KLU` (`linearSolverKlu.c`): the symbolic analysis is done once per
    /// system and reused, the numeric factorization refactored per solve. The
    /// pattern is copied in because the caller's arrays live in a block that is
    /// freed between solves; the values are only read, so they stay in place.
    pub struct Solver {
        common: Common,
        symbolic: *mut c_void,
        numeric: *mut c_void,
        ap: Vec<i32>,
        ai: Vec<i32>,
    }

    /// Below this reciprocal pivot growth the reused pivots are no longer good
    /// enough and the factorization is redone (C's threshold).
    const MIN_RGROWTH: f64 = 1e-3;

    impl Solver {
        pub fn new(n: usize, colptr: &[i32], rowidx: &[i32]) -> Option<Solver> {
            let mut s = Solver {
                common: Common::defaults()?,
                symbolic: core::ptr::null_mut(),
                numeric: core::ptr::null_mut(),
                ap: colptr.to_vec(),
                ai: rowidx.to_vec(),
            };
            s.symbolic = unsafe {
                klu_analyze(n as i32, s.ap.as_mut_ptr(), s.ai.as_mut_ptr(), &mut s.common)
            };
            (!s.symbolic.is_null()).then_some(s)
        }

        /// Factorize with `values` (in the pattern's order) and solve `A x = b` in
        /// place. `false` if the matrix is singular or a KLU call failed.
        pub fn solve(&mut self, values: *const f64, b: *mut f64, n: usize) -> bool {
            let ax = values as *mut f64;
            let (ap, ai) = (self.ap.as_mut_ptr(), self.ai.as_mut_ptr());
            if !self.numeric.is_null() {
                let ok = unsafe {
                    klu_refactor(ap, ai, ax, self.symbolic, self.numeric, &mut self.common) != 0
                        && klu_rgrowth(ap, ai, ax, self.symbolic, self.numeric, &mut self.common) != 0
                };
                if !ok || self.common.rgrowth < MIN_RGROWTH {
                    unsafe { klu_free_numeric(&mut self.numeric, &mut self.common) };
                    self.numeric = core::ptr::null_mut();
                }
            }
            if self.numeric.is_null() {
                self.numeric = unsafe { klu_factor(ap, ai, ax, self.symbolic, &mut self.common) };
            }
            if self.numeric.is_null() || self.common.status != 0 {
                return false;
            }
            unsafe { klu_solve(self.symbolic, self.numeric, n as i32, 1, b, &mut self.common) != 0 }
        }
    }

    impl Drop for Solver {
        fn drop(&mut self) {
            unsafe {
                if !self.numeric.is_null() {
                    klu_free_numeric(&mut self.numeric, &mut self.common);
                }
                klu_free_symbolic(&mut self.symbolic, &mut self.common);
            }
        }
    }
}

#[cfg(sundials)]
std::thread_local! {
    /// One [`klu::Solver`] per system `handle`, so the symbolic analysis is done
    /// once per run as it is in C.
    static KLU_CACHE: core::cell::RefCell<std::collections::HashMap<u32, klu::Solver>> =
        core::cell::RefCell::new(std::collections::HashMap::new());
}

/// Drop the per-system factorizations and KINSOL memory; they belong to one run.
pub(crate) fn reset_caches() {
    #[cfg(sundials)]
    {
        KLU_CACHE.with(|c| c.borrow_mut().clear());
        KIN_CACHE.with(|c| c.borrow_mut().clear());
    }
}

/// KLU solve of the CSC system `A x = b` (`b ← x`), reusing `handle`'s symbolic
/// analysis. 0 solved, 1 singular.
#[cfg(sundials)]
pub(crate) fn klu_solve_cached(handle: u32, colptr: u32, rowidx: u32, values: u32, b_ptr: u32, n: usize, nnz: usize) -> i32 {
    KLU_CACHE.with(|cell| {
        let mut cache = cell.borrow_mut();
        let entry = match cache.entry(handle) {
            std::collections::hash_map::Entry::Occupied(e) => e.into_mut(),
            std::collections::hash_map::Entry::Vacant(slot) => {
                let colp = unsafe { core::slice::from_raw_parts(colptr as *const i32, n + 1) };
                let rowi = unsafe { core::slice::from_raw_parts(rowidx as *const i32, nnz) };
                match klu::Solver::new(n, colp, rowi) {
                    Some(s) => slot.insert(s),
                    None => return 1,
                }
            }
        };
        !entry.solve(values as *const f64, b_ptr as *mut f64, n) as i32
    })
}

/// KLU solve of a dense column-major `A` (`n*n` f64 at `a_ptr`): scan the
/// structural nonzeros into CSC and factorize from scratch, there being no system
/// handle to cache under. 0 solved, 1 singular.
#[cfg(sundials)]
pub(crate) fn klu_solve_dense(a_ptr: u32, b_ptr: u32, n: usize) -> i32 {
    let a = unsafe { core::slice::from_raw_parts(a_ptr as *const f64, n * n) };
    let mut colptr = alloc::vec::Vec::with_capacity(n + 1);
    let mut rowidx = alloc::vec::Vec::new();
    let mut values = alloc::vec::Vec::new();
    colptr.push(0i32);
    for col in 0..n {
        for row in 0..n {
            let v = a[col * n + row];
            if v != 0.0 {
                rowidx.push(row as i32);
                values.push(v);
            }
        }
        colptr.push(rowidx.len() as i32);
    }
    match klu::Solver::new(n, &colptr, &rowidx) {
        Some(mut s) => !s.solve(values.as_ptr(), b_ptr as *mut f64, n) as i32,
        None => 1,
    }
}

/// KINSOL over the sparse Jacobian, with KLU as its linear solver — C's
/// `kinsolSolver.c` for a system with an analytic sparsity pattern.
#[cfg(sundials)]
pub(crate) mod kinsol {
    use alloc::vec;
    use core::ffi::{c_int, c_long, c_void};

    pub type NVector = *mut c_void;
    pub type SunMatrix = *mut c_void;
    pub type SunLinSol = *mut c_void;

    type SysFn = extern "C" fn(u: NVector, fval: NVector, user: *mut c_void) -> c_int;
    type JacFn = extern "C" fn(u: NVector, fu: NVector, j: SunMatrix, user: *mut c_void, t1: NVector, t2: NVector) -> c_int;
    type ErrFn = extern "C" fn(code: c_int, module: *const u8, function: *const u8, msg: *mut u8, user: *mut c_void);

    unsafe extern "C" {
        pub fn KINCreate() -> *mut c_void;
        pub fn KINFree(kinmem: *mut *mut c_void);
        fn KINInit(kinmem: *mut c_void, func: SysFn, tmpl: NVector) -> c_int;
        fn KINSol(kinmem: *mut c_void, uu: NVector, strategy: c_int, u_scale: NVector, f_scale: NVector) -> c_int;
        fn KINSetUserData(kinmem: *mut c_void, user: *mut c_void) -> c_int;
        fn KINSetErrHandlerFn(kinmem: *mut c_void, eh: ErrFn, user: *mut c_void) -> c_int;
        fn KINSetFuncNormTol(kinmem: *mut c_void, tol: f64) -> c_int;
        fn KINSetScaledStepTol(kinmem: *mut c_void, tol: f64) -> c_int;
        fn KINSetNumMaxIters(kinmem: *mut c_void, iters: c_long) -> c_int;
        fn KINSetNoInitSetup(kinmem: *mut c_void, no_init_setup: c_int) -> c_int;
        fn KINSetMaxSetupCalls(kinmem: *mut c_void, msbset: c_long) -> c_int;
        fn KINSetMaxNewtonStep(kinmem: *mut c_void, mxnewtstep: f64) -> c_int;
        fn KINSetLinearSolver(kinmem: *mut c_void, ls: SunLinSol, a: SunMatrix) -> c_int;
        fn KINSetJacFn(kinmem: *mut c_void, jac: JacFn) -> c_int;
        fn KINGetFuncNorm(kinmem: *mut c_void, fnorm: *mut f64) -> c_int;
        fn N_VNew_Serial(len: i32) -> NVector;
        fn N_VDestroy(v: NVector);
        fn N_VGetArrayPointer(v: NVector) -> *mut f64;
        fn N_VConst(c: f64, z: NVector);
        fn N_VWL2Norm(x: NVector, w: NVector) -> f64;
        fn SUNSparseMatrix(m: i32, n: i32, nnz: i32, sparsetype: c_int) -> SunMatrix;
        fn SUNMatDestroy(a: SunMatrix);
        fn SUNSparseMatrix_Data(a: SunMatrix) -> *mut f64;
        fn SUNSparseMatrix_IndexPointers(a: SunMatrix) -> *mut i32;
        fn SUNSparseMatrix_IndexValues(a: SunMatrix) -> *mut i32;
        fn SUNLinSol_KLU(y: NVector, a: SunMatrix) -> SunLinSol;
        fn SUNLinSol_KLUReInit(s: SunLinSol, a: SunMatrix, nnz: i32, reinit_type: c_int) -> c_int;
        fn SUNLinSolFree(s: SunLinSol) -> c_int;
    }

    const CSC_MAT: c_int = 0;
    const SUNKLU_REINIT_PARTIAL: c_int = 2;
    const KIN_NONE: c_int = 0;
    const KIN_LINESEARCH: c_int = 1;
    const KIN_SUCCESS: c_int = 0;
    const KIN_INITIAL_GUESS_OK: c_int = 1;
    const KIN_STEP_LT_STPTOL: c_int = 2;
    const KIN_MEM_NULL: c_int = -1;
    const KIN_ILL_INPUT: c_int = -2;
    const KIN_NO_MALLOC: c_int = -3;
    const KIN_LINESEARCH_NONCONV: c_int = -5;
    const KIN_MAXITER_REACHED: c_int = -6;
    const KIN_MXNEWT_5X_EXCEEDED: c_int = -7;
    const KIN_LINESEARCH_BCFAIL: c_int = -8;
    const KIN_LINIT_FAIL: c_int = -10;
    const KIN_LSETUP_FAIL: c_int = -11;
    const KIN_LSOLVE_FAIL: c_int = -12;
    const KIN_REPTD_SYSFUNC_ERR: c_int = -15;

    /// C's `newtonFTol`/`newtonXTol`, `maxStepFactor` and `FTOL_WITH_LESS_ACCURACY`
    /// defaults, and `RETRY_MAX`.
    const FNORMTOL: f64 = 1.0e-12;
    const SCSTEPTOL: f64 = 1.0e-12;
    const MAXSTEPFACTOR: f64 = 1.0e12;
    const FTOL_LESS_ACCURACY: f64 = 1.0e-6;
    const RETRY_MAX: i32 = 5;

    /// The system KINSOL is solving, handed to the callbacks through
    /// `KINSetUserData` for the duration of one [`Solver::solve`].
    struct Ud<'a> {
        n: usize,
        nnz: usize,
        colptr: &'a [i32],
        rowidx: &'a [i32],
        eval: &'a mut dyn FnMut(&[f64], &mut [f64]),
        assemble: &'a mut dyn FnMut(&[f64], &mut [f64]),
    }

    fn data(v: NVector, n: usize) -> &'static mut [f64] {
        unsafe { core::slice::from_raw_parts_mut(N_VGetArrayPointer(v), n) }
    }

    extern "C" fn residual(u: NVector, fval: NVector, user: *mut c_void) -> c_int {
        let ud = unsafe { &mut *(user as *mut Ud) };
        let x = data(u, ud.n);
        let f = data(fval, ud.n);
        (ud.eval)(x, f);
        // A model assert at this point is recoverable: KINSOL shortens the step, as
        // it does for the C runtime's longjmp-caught residual.
        crate::nls::assert_hit() as c_int
    }

    extern "C" fn jacobian(u: NVector, _fu: NVector, j: SunMatrix, user: *mut c_void, _t1: NVector, _t2: NVector) -> c_int {
        let ud = unsafe { &mut *(user as *mut Ud) };
        let x = data(u, ud.n);
        let vals = unsafe { core::slice::from_raw_parts_mut(SUNSparseMatrix_Data(j), ud.nnz) };
        (ud.assemble)(x, vals);
        unsafe {
            core::ptr::copy_nonoverlapping(ud.colptr.as_ptr(), SUNSparseMatrix_IndexPointers(j), ud.n + 1);
            core::ptr::copy_nonoverlapping(ud.rowidx.as_ptr(), SUNSparseMatrix_IndexValues(j), ud.nnz);
        }
        0
    }

    /// KINSOL writes its own diagnostics to `stderr`, which is captured and dropped
    /// during a simulation; the return code carries everything the ladder needs.
    extern "C" fn silent(_code: c_int, _module: *const u8, _function: *const u8, _msg: *mut u8, _user: *mut c_void) {}

    /// One system's KINSOL memory, kept across solves as C keeps its `NLS_KINSOL_DATA`:
    /// the KLU symbolic factorization, the strategy and the step factor all persist.
    pub struct Solver {
        kin: *mut c_void,
        u: NVector,
        xscale: NVector,
        fscale: NVector,
        ftmp: NVector,
        j: SunMatrix,
        ls: SunLinSol,
        n: usize,
        nnz: usize,
        strategy: c_int,
        maxstepfactor: f64,
    }

    impl Solver {
        pub fn new(n: usize, nnz: usize) -> Option<Solver> {
            let mut s = Solver {
                kin: unsafe { KINCreate() },
                u: unsafe { N_VNew_Serial(n as i32) },
                xscale: unsafe { N_VNew_Serial(n as i32) },
                fscale: unsafe { N_VNew_Serial(n as i32) },
                ftmp: unsafe { N_VNew_Serial(n as i32) },
                j: unsafe { SUNSparseMatrix(n as i32, n as i32, nnz as i32, CSC_MAT) },
                ls: core::ptr::null_mut(),
                n,
                nnz,
                strategy: KIN_LINESEARCH,
                maxstepfactor: MAXSTEPFACTOR,
            };
            if s.kin.is_null()
                || s.j.is_null()
                || [s.u, s.xscale, s.fscale, s.ftmp].iter().any(|v| v.is_null())
            {
                return None;
            }
            s.ls = unsafe { SUNLinSol_KLU(s.u, s.j) };
            if s.ls.is_null() {
                return None;
            }
            unsafe {
                KINSetErrHandlerFn(s.kin, silent, core::ptr::null_mut());
                if KINInit(s.kin, residual, s.u) != KIN_SUCCESS
                    || KINSetLinearSolver(s.kin, s.ls, s.j) != KIN_SUCCESS
                    || KINSetJacFn(s.kin, jacobian) != KIN_SUCCESS
                {
                    return None;
                }
                KINSetFuncNormTol(s.kin, FNORMTOL);
                KINSetScaledStepTol(s.kin, SCSTEPTOL);
                KINSetNumMaxIters(s.kin, 100 * n as c_long);
                KINSetNoInitSetup(s.kin, 0);
            }
            Some(s)
        }

        /// `xScale[i] = 1/max(nominal_i, |x_i|)` at the start point (C's
        /// `SCALING_NOMINALSTART`).
        fn x_scaling(&mut self, nominal: &[f64]) {
            let start = data(self.u, self.n);
            for (s, (nom, x)) in data(self.xscale, self.n).iter_mut().zip(nominal.iter().zip(start.iter())) {
                *s = 1.0 / libm::fmax(*nom, libm::fabs(*x));
            }
        }

        /// `fScale[i] = 1/max_j |J_ij / xScale_j|` from the Jacobian at the start
        /// point (C's `SCALING_JACOBIAN`), with C's `1e-12` floor on the row maximum.
        fn f_scaling(&mut self, ud: &mut Ud, vals: &mut [f64]) {
            (ud.assemble)(data(self.u, self.n), vals);
            let xscale = data(self.xscale, self.n);
            let fscale = data(self.fscale, self.n);
            fscale.fill(1e-12);
            for c in 0..self.n {
                for k in ud.colptr[c] as usize..ud.colptr[c + 1] as usize {
                    let v = libm::fabs(vals[k] / xscale[c]);
                    let row = &mut fscale[ud.rowidx[k] as usize];
                    if *row < v {
                        *row = v;
                    }
                }
            }
            for s in fscale.iter_mut() {
                *s = 1.0 / *s;
            }
        }

        /// `mxnewtstep = maxstepfactor * ‖xScale‖₂` (C's `nlsKinsolSetMaxNewtonStep`).
        fn max_newton_step(&mut self) {
            unsafe {
                N_VConst(self.maxstepfactor, self.ftmp);
                let step = N_VWL2Norm(self.xscale, self.ftmp);
                KINSetMaxNewtonStep(self.kin, step);
            }
        }

        /// C's `nlsKinsolErrorHandler`: `true` to try again. C also re-picks the
        /// scaling and the start point per retry, but [`solve`](Self::solve) applies
        /// both again before the next `KINSol`, so only what is set here survives.
        fn handle_error(&mut self, code: c_int, retries: &mut i32, reset_tol: &mut bool) -> bool {
            unsafe { KINSetNoInitSetup(self.kin, 0) };
            match code {
                KIN_MEM_NULL | KIN_ILL_INPUT | KIN_NO_MALLOC | KIN_LINIT_FAIL => return false,
                KIN_MXNEWT_5X_EXCEEDED => {
                    self.maxstepfactor *= 1e5;
                    self.max_newton_step();
                    return true;
                }
                KIN_LINESEARCH_NONCONV => {
                    self.strategy = KIN_NONE;
                    *retries -= 1;
                    return true;
                }
                KIN_LSOLVE_FAIL => {
                    // An out-of-date factorization; redo it from the pattern.
                    unsafe { SUNLinSol_KLUReInit(self.ls, self.j, self.nnz as i32, SUNKLU_REINIT_PARTIAL) };
                    return true;
                }
                // C answers `LSETUP_FAIL` by switching to a numeric Jacobian; this
                // path only exists for systems that have the analytic one.
                KIN_MAXITER_REACHED | KIN_REPTD_SYSFUNC_ERR | KIN_LSETUP_FAIL | KIN_LINESEARCH_BCFAIL => {}
                _ => return false,
            }
            let mut fnorm = 0.0;
            unsafe { KINGetFuncNorm(self.kin, &mut fnorm) };
            if fnorm < FTOL_LESS_ACCURACY {
                // C's "move forward with a less accurate solution".
                unsafe {
                    KINSetFuncNormTol(self.kin, FTOL_LESS_ACCURACY);
                    KINSetScaledStepTol(self.kin, FTOL_LESS_ACCURACY);
                }
                *reset_tol = true;
                return true;
            }
            match *retries {
                0 => {}
                1 => self.strategy = KIN_LINESEARCH,
                2 => self.strategy = KIN_NONE,
                3 | 4 => {
                    unsafe { KINSetMaxSetupCalls(self.kin, 1) };
                    self.strategy = KIN_LINESEARCH;
                }
                _ => return false,
            }
            true
        }

        /// C's `nlsKinsolSolve`: solve from `guess`, retrying per
        /// [`handle_error`](Self::handle_error) until it gives up or `RETRY_MAX`.
        /// On success `x` is the solution.
        pub fn solve(
            &mut self,
            guess: &[f64],
            nominal: &[f64],
            colptr: &[i32],
            rowidx: &[i32],
            x: &mut [f64],
            eval: &mut dyn FnMut(&[f64], &mut [f64]),
            assemble: &mut dyn FnMut(&[f64], &mut [f64]),
        ) -> bool {
            let mut ud = Ud { n: self.n, nnz: self.nnz, colptr, rowidx, eval, assemble };
            unsafe { KINSetUserData(self.kin, &mut ud as *mut Ud as *mut c_void) };
            let mut vals = vec![0.0f64; self.nnz];
            let mut success = false;
            let mut reset_tol = false;
            let mut retries = 0;
            let mut passes = 0;
            loop {
                data(self.u, self.n).copy_from_slice(guess);
                self.x_scaling(nominal);
                self.f_scaling(&mut ud, &mut vals);
                self.max_newton_step();
                let flag = unsafe { KINSol(self.kin, self.u, self.strategy, self.xscale, self.fscale) };
                success = matches!(flag, KIN_SUCCESS | KIN_INITIAL_GUESS_OK | KIN_STEP_LT_STPTOL);
                let retry = flag < 0 && self.handle_error(flag, &mut retries, &mut reset_tol);
                retries += 1;
                passes += 1;
                if success || !retry || retries >= RETRY_MAX || passes >= 2 * RETRY_MAX {
                    break;
                }
            }
            if reset_tol {
                unsafe {
                    KINSetFuncNormTol(self.kin, FNORMTOL);
                    KINSetScaledStepTol(self.kin, SCSTEPTOL);
                }
            }
            if success {
                x.copy_from_slice(data(self.u, self.n));
            }
            unsafe { KINSetUserData(self.kin, core::ptr::null_mut()) };
            success
        }
    }

    impl Drop for Solver {
        fn drop(&mut self) {
            unsafe {
                if !self.kin.is_null() {
                    KINFree(&mut self.kin);
                }
                if !self.ls.is_null() {
                    SUNLinSolFree(self.ls);
                }
                if !self.j.is_null() {
                    SUNMatDestroy(self.j);
                }
                for v in [self.u, self.xscale, self.fscale, self.ftmp] {
                    if !v.is_null() {
                        N_VDestroy(v);
                    }
                }
            }
        }
    }
}

#[cfg(sundials)]
std::thread_local! {
    /// One [`kinsol::Solver`] per system `handle`, kept for the run so KINSOL and
    /// KLU reuse their setup.
    static KIN_CACHE: core::cell::RefCell<std::collections::HashMap<u32, kinsol::Solver>> =
        core::cell::RefCell::new(std::collections::HashMap::new());
}

/// Solve system `handle` with KINSOL + KLU from `guess`, writing the solution into
/// `x`. `eval` evaluates the residual, `assemble` the `nnz` CSC Jacobian values.
#[cfg(sundials)]
#[allow(clippy::too_many_arguments)]
pub(crate) fn kinsol_solve(
    handle: u32,
    n: usize,
    nnz: usize,
    colptr: &[i32],
    rowidx: &[i32],
    nominal: &[f64],
    guess: &[f64],
    x: &mut [f64],
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    assemble: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    KIN_CACHE.with(|cell| {
        // Detach solver so model callbacks can re-enter kinsol_solve for a nested system.
        let mut solver = match cell.borrow_mut().remove(&handle) {
            Some(s) => s,
            None => match kinsol::Solver::new(n, nnz) {
                Some(s) => s,
                None => return false,
            },
        };
        let ok = solver.solve(guess, nominal, colptr, rowidx, x, eval, assemble);
        cell.borrow_mut().insert(handle, solver);
        ok
    })
}
