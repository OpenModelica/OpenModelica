//! The real SUNDIALS/KLU, cross-compiled to wasm and linked in by `build.rs`
//! (`cfg(sundials)`).
//!
//! Indices are `i32` (`SUNDIALS_INDEX_SIZE=32`, see the build script for why) and
//! `sunrealtype` is `f64`.

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
        ida: openmodelica_sim_meta::IDA,
        cvode: openmodelica_sim_meta::CVODE,
        // Served by the driver's per-step deadline; both runtimes install a clock.
        alarm: true,
        // No regex engine in wasm; the model's own filter is resolved at codegen.
        variable_filter: false,
        // Ipopt has no wasm build (MUMPS is Fortran), so `method="optimization"`
        // reports "Ipopt is needed but not available." here.
        optimization: false,
        // Both runtimes drive a whole trajectory, which is all QSS can do.
        qss: true,
    }
}

/// Smoke test that the archives are linked and callable: `klu_defaults` reports
/// success and its values land where [`klu::Common`] mirrors them, and KINSOL
/// allocates.
#[cfg(sundials)]
#[unsafe(no_mangle)]
pub extern "C" fn rt_sundials_selftest() -> i32 {
    let common_ok = klu::Common::defaults().is_some();
    (common_ok && kinsol::probe()) as i32
}

#[cfg(not(sundials))]
#[unsafe(no_mangle)]
pub extern "C" fn rt_sundials_selftest() -> i32 {
    0
}

/// The CSC of `Aᵀ` both SuiteSparse wrappers factorize, as C's
/// `setAElementKlu`/`setAElementUmfpack` fill it, plus `perm`: where each entry
/// reads from in the caller's CSC-of-`A` values.
#[cfg(sundials)]
pub(crate) struct Transposed {
    ap: alloc::vec::Vec<i32>,
    ai: alloc::vec::Vec<i32>,
    perm: alloc::vec::Vec<u32>,
    ax: alloc::vec::Vec<f64>,
}

#[cfg(sundials)]
impl Transposed {
    fn new(n: usize, colptr: &[i32], rowidx: &[i32]) -> Option<Transposed> {
        let nnz = *colptr.get(n)? as usize;
        let mut ap = alloc::vec![0i32; n + 1];
        for &r in &rowidx[..nnz] {
            ap[r as usize + 1] += 1;
        }
        for r in 0..n {
            ap[r + 1] += ap[r];
        }
        let mut fill: alloc::vec::Vec<i32> = ap[..n].to_vec();
        let mut ai = alloc::vec![0i32; nnz];
        let mut perm = alloc::vec![0u32; nnz];
        for c in 0..n {
            for k in colptr[c] as usize..colptr[c + 1] as usize {
                let slot = &mut fill[rowidx[k] as usize];
                ai[*slot as usize] = c as i32;
                perm[*slot as usize] = k as u32;
                *slot += 1;
            }
        }
        Some(Transposed { ap, ai, perm, ax: alloc::vec![0.0f64; nnz] })
    }

    fn gather(&mut self, values: *const f64) {
        let src = unsafe { core::slice::from_raw_parts(values, self.perm.len()) };
        for (dst, &k) in self.ax.iter_mut().zip(&self.perm) {
            *dst = src[k as usize];
        }
    }
}

#[cfg(sundials)]
pub(crate) mod klu {
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
        pub fn klu_tsolve(symbolic: *mut c_void, numeric: *mut c_void, ldim: i32, nrhs: i32, b: *mut f64, common: *mut Common) -> i32;
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

    /// C's `DATA_KLU` (`linearSolverKlu.c`): symbolic analysis once per system,
    /// numeric factorization refactored per solve.
    ///
    /// KLU gets `Aᵀ` and a transpose solve, as in C. Factorizing `A` instead holds
    /// `rgrowth` under the 1e-3 threshold on a MultiBody chain, so the pivots are
    /// rechosen every solve and `functionODE` stops being a function of the states
    /// alone — which quietly ruins any finite-difference Jacobian taken through it.
    pub struct Solver {
        common: Common,
        symbolic: *mut c_void,
        numeric: *mut c_void,
        t: super::Transposed,
    }

    /// Below this reciprocal pivot growth the reused pivots are no longer good
    /// enough and the factorization is redone (C's threshold).
    const MIN_RGROWTH: f64 = 1e-3;

    impl Solver {
        /// `colptr`/`rowidx` are the caller's CSC of `A`; the transpose is built here.
        pub fn new(n: usize, colptr: &[i32], rowidx: &[i32]) -> Option<Solver> {
            let mut s = Solver {
                common: Common::defaults()?,
                symbolic: core::ptr::null_mut(),
                numeric: core::ptr::null_mut(),
                t: super::Transposed::new(n, colptr, rowidx)?,
            };
            s.symbolic = unsafe {
                klu_analyze(n as i32, s.t.ap.as_mut_ptr(), s.t.ai.as_mut_ptr(), &mut s.common)
            };
            (!s.symbolic.is_null()).then_some(s)
        }

        /// Factorize with `values` (the caller's CSC-of-`A` order) and solve
        /// `A x = b` in place. `false` if the matrix is singular or a KLU call failed.
        pub fn solve(&mut self, values: *const f64, b: *mut f64, n: usize) -> bool {
            self.t.gather(values);
            let ax = self.t.ax.as_mut_ptr();
            let (ap, ai) = (self.t.ap.as_mut_ptr(), self.t.ai.as_mut_ptr());
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
            unsafe { klu_tsolve(self.symbolic, self.numeric, n as i32, 1, b, &mut self.common) != 0 }
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
pub(crate) mod umfpack {
    use alloc::vec::Vec;
    use core::ffi::c_void;

    const CONTROL: usize = 20;
    const INFO: usize = 90;
    const PIVOT_TOLERANCE: usize = 3;
    const STRATEGY: usize = 5;
    const IRSTEP: usize = 7;
    const SCALE: usize = 16;
    /// `A.'x = b`; the stored matrix is `Aᵀ`, so this solves `A x = b`.
    const SYS_AAT: i32 = 2;
    const OK: i32 = 0;
    pub const WARNING_SINGULAR_MATRIX: i32 = 1;

    unsafe extern "C" {
        fn umfpack_di_defaults(control: *mut f64);
        fn umfpack_di_symbolic(
            n_row: i32, n_col: i32, ap: *const i32, ai: *const i32, ax: *const f64,
            symbolic: *mut *mut c_void, control: *const f64, info: *mut f64,
        ) -> i32;
        fn umfpack_di_numeric(
            ap: *const i32, ai: *const i32, ax: *const f64, symbolic: *mut c_void,
            numeric: *mut *mut c_void, control: *const f64, info: *mut f64,
        ) -> i32;
        fn umfpack_di_wsolve(
            sys: i32, ap: *const i32, ai: *const i32, ax: *const f64, x: *mut f64, b: *const f64,
            numeric: *mut c_void, control: *const f64, info: *mut f64, wi: *mut i32, w: *mut f64,
        ) -> i32;
        fn umfpack_di_free_symbolic(symbolic: *mut *mut c_void);
        fn umfpack_di_free_numeric(numeric: *mut *mut c_void);
    }

    /// C's `DATA_UMFPACK` (`linearSolverUmfpack.c`): pre-ordering on the first
    /// solve (C's `numberSolving == 0`), refactorized on every solve.
    pub struct Solver {
        symbolic: *mut c_void,
        numeric: *mut c_void,
        control: [f64; CONTROL],
        info: [f64; INFO],
        t: super::Transposed,
        /// `umfpack_di_wsolve`'s workspaces and its separate solution vector.
        wi: Vec<i32>,
        w: Vec<f64>,
        x: Vec<f64>,
    }

    impl Solver {
        /// `colptr`/`rowidx` are the caller's CSC of `A`; the transpose is built here.
        pub fn new(n: usize, colptr: &[i32], rowidx: &[i32]) -> Option<Solver> {
            let mut control = [0.0f64; CONTROL];
            unsafe { umfpack_di_defaults(control.as_mut_ptr()) };
            // C's `allocateUmfPackData`. The first three restate UMFPACK's own
            // defaults; `STRATEGY` is out of range (0/1/3), read back as auto.
            control[PIVOT_TOLERANCE] = 0.1;
            control[IRSTEP] = 2.0;
            control[SCALE] = 1.0;
            control[STRATEGY] = 5.0;
            Some(Solver {
                symbolic: core::ptr::null_mut(),
                numeric: core::ptr::null_mut(),
                control,
                info: [0.0f64; INFO],
                t: super::Transposed::new(n, colptr, rowidx)?,
                wi: alloc::vec![0i32; n],
                w: alloc::vec![0.0f64; 5 * n],
                x: alloc::vec![0.0f64; n],
            })
        }

        /// Factorize with `values` (the caller's CSC-of-`A` order) and solve
        /// `A x = b` in place, returning UMFPACK's status.
        pub fn solve(&mut self, values: *const f64, b: *mut f64, n: usize) -> i32 {
            self.t.gather(values);
            let (ap, ai, ax) = (self.t.ap.as_ptr(), self.t.ai.as_ptr(), self.t.ax.as_ptr());
            let mut status = OK;
            if self.symbolic.is_null() {
                status = unsafe {
                    umfpack_di_symbolic(
                        n as i32, n as i32, ap, ai, ax,
                        &mut self.symbolic, self.control.as_ptr(), self.info.as_mut_ptr(),
                    )
                };
            }
            if !self.numeric.is_null() {
                unsafe { umfpack_di_free_numeric(&mut self.numeric) };
            }
            if status == OK {
                status = unsafe {
                    umfpack_di_numeric(
                        ap, ai, ax, self.symbolic, &mut self.numeric,
                        self.control.as_ptr(), self.info.as_mut_ptr(),
                    )
                };
            }
            if status == OK {
                status = unsafe {
                    umfpack_di_wsolve(
                        SYS_AAT, ap, ai, ax, self.x.as_mut_ptr(), b, self.numeric,
                        self.control.as_ptr(), self.info.as_mut_ptr(),
                        self.wi.as_mut_ptr(), self.w.as_mut_ptr(),
                    )
                };
            }
            if status == OK {
                unsafe { core::ptr::copy_nonoverlapping(self.x.as_ptr(), b, n) };
            }
            status
        }
    }

    impl Drop for Solver {
        fn drop(&mut self) {
            unsafe {
                if !self.numeric.is_null() {
                    umfpack_di_free_numeric(&mut self.numeric);
                }
                umfpack_di_free_symbolic(&mut self.symbolic);
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
    /// The same for [`umfpack::Solver`].
    static UMFPACK_CACHE: core::cell::RefCell<std::collections::HashMap<u32, umfpack::Solver>> =
        core::cell::RefCell::new(std::collections::HashMap::new());
}

/// Drop the per-system factorizations and KINSOL memory; they belong to one run.
pub(crate) fn reset_caches() {
    #[cfg(sundials)]
    {
        KLU_CACHE.with(|c| c.borrow_mut().clear());
        UMFPACK_CACHE.with(|c| c.borrow_mut().clear());
        KIN_CACHE.with(|c| c.borrow_mut().clear());
        crate::lis::reset_caches();
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

/// UMFPACK solve of the CSC system `A x = b` (`b ← x`), reusing `handle`'s
/// pre-ordering. 0 solved, 1 not.
#[cfg(sundials)]
pub(crate) fn umfpack_solve_cached(handle: u32, colptr: u32, rowidx: u32, values: u32, b_ptr: u32, n: usize, nnz: usize) -> i32 {
    UMFPACK_CACHE.with(|cell| {
        let mut cache = cell.borrow_mut();
        let entry = match cache.entry(handle) {
            std::collections::hash_map::Entry::Occupied(e) => e.into_mut(),
            std::collections::hash_map::Entry::Vacant(slot) => {
                let colp = unsafe { core::slice::from_raw_parts(colptr as *const i32, n + 1) };
                let rowi = unsafe { core::slice::from_raw_parts(rowidx as *const i32, nnz) };
                match umfpack::Solver::new(n, colp, rowi) {
                    Some(s) => slot.insert(s),
                    None => return 1,
                }
            }
        };
        (entry.solve(values as *const f64, b_ptr as *mut f64, n) != 0) as i32
    })
}

/// A dense column-major `A` as CSC of its structural nonzeros.
#[cfg(sundials)]
fn csc_from_dense(a: &[f64], n: usize) -> (alloc::vec::Vec<i32>, alloc::vec::Vec<i32>, alloc::vec::Vec<f64>) {
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
    (colptr, rowidx, values)
}

/// KLU solve of a dense column-major `A` (`n*n` f64 at `a_ptr`): scan the
/// structural nonzeros into CSC and factorize from scratch, there being no system
/// handle to cache under. 0 solved, 1 singular.
#[cfg(sundials)]
pub(crate) fn klu_solve_dense(a_ptr: u32, b_ptr: u32, n: usize) -> i32 {
    let a = unsafe { core::slice::from_raw_parts(a_ptr as *const f64, n * n) };
    let (colptr, rowidx, values) = csc_from_dense(a, n);
    match klu::Solver::new(n, &colptr, &rowidx) {
        Some(mut s) => !s.solve(values.as_ptr(), b_ptr as *mut f64, n) as i32,
        None => 1,
    }
}

/// [`klu_solve_dense`] with UMFPACK. A singular matrix (1) reports separately
/// from an outright failure (2), so the caller can retry with total pivoting as
/// C's `solveUmfPack` retries with its own rank-deficient back-substitution.
#[cfg(sundials)]
pub(crate) fn umfpack_solve_dense(a_ptr: u32, b_ptr: u32, n: usize) -> i32 {
    let a = unsafe { core::slice::from_raw_parts(a_ptr as *const f64, n * n) };
    let (colptr, rowidx, values) = csc_from_dense(a, n);
    let Some(mut s) = umfpack::Solver::new(n, &colptr, &rowidx) else { return 2 };
    match s.solve(values.as_ptr(), b_ptr as *mut f64, n) {
        0 => 0,
        umfpack::WARNING_SINGULAR_MATRIX => 1,
        _ => 2,
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
    pub type SunContext = *mut c_void;

    type SysFn = extern "C" fn(u: NVector, fval: NVector, user: *mut c_void) -> c_int;
    type JacFn = extern "C" fn(u: NVector, fu: NVector, j: SunMatrix, user: *mut c_void, t1: NVector, t2: NVector) -> c_int;

    unsafe extern "C" {
        fn SUNContext_Create(comm: c_int, ctx: *mut SunContext) -> c_int;
        fn SUNContext_Free(ctx: *mut SunContext) -> c_int;
        fn SUNContext_ClearErrHandlers(ctx: SunContext) -> c_int;

        fn KINCreate(ctx: SunContext) -> *mut c_void;
        fn KINFree(kinmem: *mut *mut c_void);
        fn KINInit(kinmem: *mut c_void, func: SysFn, tmpl: NVector) -> c_int;
        fn KINSol(kinmem: *mut c_void, uu: NVector, strategy: c_int, u_scale: NVector, f_scale: NVector) -> c_int;
        fn KINSetUserData(kinmem: *mut c_void, user: *mut c_void) -> c_int;
        fn KINSetFuncNormTol(kinmem: *mut c_void, tol: f64) -> c_int;
        fn KINSetScaledStepTol(kinmem: *mut c_void, tol: f64) -> c_int;
        fn KINSetNumMaxIters(kinmem: *mut c_void, iters: c_long) -> c_int;
        fn KINSetNoInitSetup(kinmem: *mut c_void, no_init_setup: c_int) -> c_int;
        fn KINSetMaxSetupCalls(kinmem: *mut c_void, msbset: c_long) -> c_int;
        fn KINSetMaxNewtonStep(kinmem: *mut c_void, mxnewtstep: f64) -> c_int;
        fn KINSetLinearSolver(kinmem: *mut c_void, ls: SunLinSol, a: SunMatrix) -> c_int;
        fn KINSetJacFn(kinmem: *mut c_void, jac: JacFn) -> c_int;
        fn KINGetFuncNorm(kinmem: *mut c_void, fnorm: *mut f64) -> c_int;
        fn N_VNew_Serial(len: i32, ctx: SunContext) -> NVector;
        fn N_VDestroy(v: NVector);
        fn N_VGetArrayPointer(v: NVector) -> *mut f64;
        fn N_VConst(c: f64, z: NVector);
        fn N_VWL2Norm(x: NVector, w: NVector) -> f64;
        fn SUNSparseMatrix(m: i32, n: i32, nnz: i32, sparsetype: c_int, ctx: SunContext) -> SunMatrix;
        fn SUNMatDestroy(a: SunMatrix);
        fn SUNSparseMatrix_Data(a: SunMatrix) -> *mut f64;
        fn SUNSparseMatrix_IndexPointers(a: SunMatrix) -> *mut i32;
        fn SUNSparseMatrix_IndexValues(a: SunMatrix) -> *mut i32;
        fn SUNLinSol_KLU(y: NVector, a: SunMatrix, ctx: SunContext) -> SunLinSol;
        fn SUNLinSol_KLUReInit(s: SunLinSol, a: SunMatrix, nnz: i32, reinit_type: c_int) -> c_int;
        fn SUNLinSolFree(s: SunLinSol) -> c_int;
    }

    const SUN_SUCCESS: c_int = 0;
    const SUN_COMM_NULL: c_int = 0;
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

    /// C's `FTOL_WITH_LESS_ACCURACY` and `RETRY_MAX`; the stopping tolerances and
    /// the step factor are C's `newtonFTol`/`newtonXTol`/`maxStepFactor`, which
    /// `crate::solvers` holds because `-newtonFTol` and friends move them.
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
        /// Difference the Jacobian rather than assemble it analytically.
        numeric: bool,
    }

    /// Extract the backing array pointer from an N_Vector.
    ///
    /// Returns `&mut [f64]` with a lifetime bounded by the `'a` parameter of the
    /// enclosing Ud struct. The slice is only valid while the N_Vector exists;
    /// the caller must not let it escape the callback scope.
    fn data<'a>(v: NVector, n: usize) -> &'a mut [f64] {
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

    /// C's `nlsSparseJac`: forward differences into the pattern's CSC values. C
    /// perturbs a whole colour group per evaluation; column at a time gives the same
    /// entries (no row sees two columns of a group) for more evaluations, and only on
    /// the systems whose analytic Jacobian KINSOL has already rejected.
    fn numeric_csc(ud: &mut Ud, x: &mut [f64], fx: &[f64], vals: &mut [f64]) {
        /// `sqrt(DBL_EPSILON * 2e1)`, C's difference step.
        const DELTA_H: f64 = 6.664001874625056e-08;
        let mut fres = vec![0.0f64; ud.n];
        for c in 0..ud.n {
            let saved = x[c];
            let dh = DELTA_H * (libm::fabs(saved) + 1.0);
            x[c] = saved + dh;
            (ud.eval)(x, &mut fres);
            x[c] = saved;
            let inv = 1.0 / dh;
            for k in ud.colptr[c] as usize..ud.colptr[c + 1] as usize {
                let row = ud.rowidx[k] as usize;
                vals[k] = (fres[row] - fx[row]) * inv;
            }
        }
    }

    extern "C" fn jacobian(u: NVector, fu: NVector, j: SunMatrix, user: *mut c_void, _t1: NVector, _t2: NVector) -> c_int {
        let ud = unsafe { &mut *(user as *mut Ud) };
        let x = data(u, ud.n);
        let vals = unsafe { core::slice::from_raw_parts_mut(SUNSparseMatrix_Data(j), ud.nnz) };
        if ud.numeric {
            let fx = data(fu, ud.n);
            numeric_csc(ud, x, fx, vals);
        } else {
            (ud.assemble)(x, vals);
        }
        unsafe {
            core::ptr::copy_nonoverlapping(ud.colptr.as_ptr(), SUNSparseMatrix_IndexPointers(j), ud.n + 1);
            core::ptr::copy_nonoverlapping(ud.rowidx.as_ptr(), SUNSparseMatrix_IndexValues(j), ud.nnz);
        }
        0
    }

    /// A silent context: KINSOL writes its own diagnostics to `stderr`, which is
    /// captured and dropped during a simulation, and the return code carries
    /// everything the ladder needs.
    fn context() -> SunContext {
        let mut ctx: SunContext = core::ptr::null_mut();
        if unsafe { SUNContext_Create(SUN_COMM_NULL, &mut ctx) } != SUN_SUCCESS {
            return core::ptr::null_mut();
        }
        unsafe { SUNContext_ClearErrHandlers(ctx) };
        ctx
    }

    /// Smoke test for [`rt_sundials_selftest`](super::rt_sundials_selftest): a
    /// context and a KINSOL memory block can be allocated and freed.
    pub fn probe() -> bool {
        let ctx = context();
        if ctx.is_null() {
            return false;
        }
        let mut kin = unsafe { KINCreate(ctx) };
        let ok = !kin.is_null();
        unsafe {
            if ok {
                KINFree(&mut kin);
            }
            let mut ctx = ctx;
            SUNContext_Free(&mut ctx);
        }
        ok
    }

    /// One system's KINSOL memory, kept across solves as C keeps its `NLS_KINSOL_DATA`:
    /// the KLU symbolic factorization, the strategy and the step factor all persist.
    pub struct Solver {
        /// Outlives every object below it; freed last.
        ctx: SunContext,
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
        /// Set for good once `KIN_LSETUP_FAIL` rejects the analytic Jacobian.
        numeric_jac: bool,
    }

    impl Solver {
        pub fn new(n: usize, nnz: usize) -> Option<Solver> {
            let ctx = context();
            if ctx.is_null() {
                return None;
            }
            let mut s = Solver {
                ctx,
                kin: unsafe { KINCreate(ctx) },
                u: unsafe { N_VNew_Serial(n as i32, ctx) },
                xscale: unsafe { N_VNew_Serial(n as i32, ctx) },
                fscale: unsafe { N_VNew_Serial(n as i32, ctx) },
                ftmp: unsafe { N_VNew_Serial(n as i32, ctx) },
                j: unsafe { SUNSparseMatrix(n as i32, n as i32, nnz as i32, CSC_MAT, ctx) },
                ls: core::ptr::null_mut(),
                n,
                nnz,
                strategy: KIN_LINESEARCH,
                maxstepfactor: crate::solvers::max_step_factor(),
                numeric_jac: false,
            };
            if s.kin.is_null()
                || s.j.is_null()
                || [s.u, s.xscale, s.fscale, s.ftmp].iter().any(|v| v.is_null())
            {
                return None;
            }
            s.ls = unsafe { SUNLinSol_KLU(s.u, s.j, s.ctx) };
            if s.ls.is_null() {
                return None;
            }
            unsafe {
                if KINInit(s.kin, residual, s.u) != KIN_SUCCESS
                    || KINSetLinearSolver(s.kin, s.ls, s.j) != KIN_SUCCESS
                    || KINSetJacFn(s.kin, jacobian) != KIN_SUCCESS
                {
                    return None;
                }
                KINSetFuncNormTol(s.kin, crate::solvers::newton_ftol());
                KINSetScaledStepTol(s.kin, crate::solvers::newton_xtol());
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
                // A Jacobian KLU cannot factorize (all-zero at the start point, say):
                // difference it from here on, as C re-points `KINSetJacFn`.
                KIN_LSETUP_FAIL => self.numeric_jac = true,
                KIN_MAXITER_REACHED | KIN_REPTD_SYSFUNC_ERR | KIN_LINESEARCH_BCFAIL => {}
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
            let mut ud =
                Ud { n: self.n, nnz: self.nnz, colptr, rowidx, eval, assemble, numeric: self.numeric_jac };
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
                ud.numeric = self.numeric_jac;
                retries += 1;
                passes += 1;
                if success || !retry || retries >= RETRY_MAX || passes >= 2 * RETRY_MAX {
                    break;
                }
            }
            if reset_tol {
                unsafe {
                    KINSetFuncNormTol(self.kin, crate::solvers::newton_ftol());
                    KINSetScaledStepTol(self.kin, crate::solvers::newton_xtol());
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
                // Last: everything above was created with it.
                if !self.ctx.is_null() {
                    SUNContext_Free(&mut self.ctx);
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
