//! KINSOL over the model's sparse Jacobian, with KLU as its linear solver: C's
//! `kinsolSolver.c` for a system with an analytic sparsity pattern, and
//! `kinsol_b.c` (`-nls=kinsol_b`) over an explicitly scaled one.
//!
//! Shared by both runtimes: the binding exchanges plain slices and closures, so a
//! host supplies the same [`crate::NlsBackend`] over it whether the model is a wasm
//! module or a C `NONLINEAR_SYSTEM_DATA`.
//!
//! [`solve`] and [`b_solve`] exist whether or not the archives were built -- as
//! stubs that solve nothing when they were not -- so no caller needs a
//! `cfg(sundials)` of its own. Each crate's comes from its own build script, and
//! one written in a crate that has none compiles the call *out* silently. Ask
//! [`AVAILABLE`] instead, and take the dense ladder when it is false.

/// C's `SPARSE_PATTERN` in CSC addressing, plus the bounds a difference step must
/// not cross.
pub struct Pattern<'a> {
    pub nnz: usize,
    pub colptr: &'a [i32],
    pub rowidx: &'a [i32],
    /// C's `colorCols`, 0-based; empty leaves every column its own colour.
    pub colors: &'a [u32],
    /// C's `nlsData->max`; empty leaves the columns unbounded.
    pub max: &'a [f64],
}

/// The SUNDIALS-facing half: KINSOL over the sparse Jacobian with KLU as its
/// linear solver (C's `kinsolSolver.c`), and the explicitly scaled variant
/// `kinsol_b.c` runs. [`solve`] and [`b_solve`] below are what a backend calls.
#[cfg(sundials)]
pub mod sun {
    use alloc::vec;
    use core::ffi::{c_int, c_long, c_void};

    pub use openmodelica_solvers::sundials::SunIndex;

    /// The model's sparsity pattern is `i32`; SUNDIALS' `sunindextype` is 32 bits in
    /// the wasm build and 64 in the host one, so the copy into a `SUNMatrix_Sparse`
    /// widens rather than memcpy'ing.
    unsafe fn put_index(dst: *mut SunIndex, src: &[i32]) {
        for (i, &v) in src.iter().enumerate() {
            unsafe { *dst.add(i) = v as SunIndex };
        }
    }

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
        fn N_VNew_Serial(len: SunIndex, ctx: SunContext) -> NVector;
        fn N_VDestroy(v: NVector);
        fn N_VGetArrayPointer(v: NVector) -> *mut f64;
        fn N_VConst(c: f64, z: NVector);
        fn N_VWL2Norm(x: NVector, w: NVector) -> f64;
        fn SUNSparseMatrix(m: SunIndex, n: SunIndex, nnz: SunIndex, sparsetype: c_int, ctx: SunContext) -> SunMatrix;
        fn SUNMatDestroy(a: SunMatrix);
        fn SUNSparseMatrix_Data(a: SunMatrix) -> *mut f64;
        fn SUNSparseMatrix_IndexPointers(a: SunMatrix) -> *mut SunIndex;
        fn SUNSparseMatrix_IndexValues(a: SunMatrix) -> *mut SunIndex;
        fn SUNLinSol_KLU(y: NVector, a: SunMatrix, ctx: SunContext) -> SunLinSol;
        fn SUNDenseMatrix(m: SunIndex, n: SunIndex, ctx: SunContext) -> SunMatrix;
        fn SUNDenseMatrix_Data(a: SunMatrix) -> *mut f64;
        fn SUNLinSol_Dense(y: NVector, a: SunMatrix, ctx: SunContext) -> SunLinSol;
        fn SUNLinSol_KLUReInit(s: SunLinSol, a: SunMatrix, nnz: SunIndex, reinit_type: c_int) -> c_int;
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
    /// `openmodelica_solvers::solverflags` holds because `-newtonFTol` and friends
    /// move them.
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
        colors: &'a [u32],
        max: &'a [f64],
        /// What the `LOG_NLS_DERIVATIVE_TEST` header names.
        eq_index: u32,
        time: f64,
    }

    impl Ud<'_> {
        /// C's `sparsePattern->maxColors`, or one column at a time without a colouring.
        fn n_colors(&self) -> usize {
            match self.colors.iter().max() {
                Some(&c) => c as usize + 1,
                None => self.n,
            }
        }

        fn in_color(&self, col: usize, color: usize) -> bool {
            match self.colors.is_empty() {
                true => col == color,
                false => self.colors[col] as usize == color,
            }
        }

        fn max_of(&self, col: usize) -> f64 {
            self.max.get(col).copied().unwrap_or(f64::MAX)
        }
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
        crate::assert_hit() as c_int
    }

    /// C's `nlsSparseJac`: forward differences into the pattern's CSC values, one
    /// residual evaluation per colour group — no row sees two columns of a group, so
    /// the whole group can be perturbed at once.
    fn numeric_csc(ud: &mut Ud, x: &mut [f64], fx: &[f64], vals: &mut [f64]) {
        /// `sqrt(DBL_EPSILON * 2e1)`, C's difference step.
        const DELTA_H: f64 = 6.664001874625056e-08;
        let mut fres = vec![0.0f64; ud.n];
        let mut xsave = vec![0.0f64; ud.n];
        let mut inv = vec![0.0f64; ud.n];
        for color in 0..ud.n_colors() {
            for c in 0..ud.n {
                if !ud.in_color(c, color) {
                    continue;
                }
                xsave[c] = x[c];
                let mut dh = DELTA_H * (libm::fabs(xsave[c]) + 1.0);
                if xsave[c] + dh >= ud.max_of(c) {
                    dh = -dh;
                }
                x[c] = xsave[c] + dh;
                inv[c] = 1.0 / dh;
            }
            (ud.eval)(x, &mut fres);
            for c in 0..ud.n {
                if !ud.in_color(c, color) {
                    continue;
                }
                for k in ud.colptr[c] as usize..ud.colptr[c + 1] as usize {
                    let row = ud.rowidx[k] as usize;
                    vals[k] = (fres[row] - fx[row]) * inv[c];
                }
                x[c] = xsave[c];
            }
        }
    }

    /// The `LOG_NLS_DERIVATIVE_TEST` tail C gives `nlsSparseSymJac`/`nlsSparseJac`.
    /// Unscaled: this port applies `xScale` where it reads the Jacobian, so C's
    /// `nominalJac` is never set here.
    fn derivative_test(ud: &mut Ud, x: &mut [f64], vals: &[f64]) {
        if !openmodelica_solvers::omclog::active(openmodelica_solvers::omclog::NLS_DERIVATIVE_TEST) {
            return;
        }
        crate::jacobian_analysis::derivative_test(
            ud.eq_index, ud.time, ud.n, x, ud.colptr, ud.rowidx, vals, None,
            crate::jacobian_analysis::Caller::KinsolJacEval, ud.eval,
        );
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
            put_index(SUNSparseMatrix_IndexPointers(j), &ud.colptr[..ud.n + 1]);
            put_index(SUNSparseMatrix_IndexValues(j), &ud.rowidx[..ud.nnz]);
        }
        derivative_test(ud, x, vals);
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

    /// Smoke test for the wasm runtime's `rt_sundials_selftest` export: a
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
        /// C's `kinsolData->solved == NLS_SOLVED`: the last solve converged to the
        /// full tolerance, so [`f_scaling`](Self::f_scaling) reuses [`Self::vals`].
        solved: bool,
        /// The Jacobian values the scaling was last taken from.
        vals: vec::Vec<f64>,
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
                u: unsafe { N_VNew_Serial(n as SunIndex, ctx) },
                xscale: unsafe { N_VNew_Serial(n as SunIndex, ctx) },
                fscale: unsafe { N_VNew_Serial(n as SunIndex, ctx) },
                ftmp: unsafe { N_VNew_Serial(n as SunIndex, ctx) },
                j: unsafe { SUNSparseMatrix(n as SunIndex, n as SunIndex, nnz as SunIndex, CSC_MAT, ctx) },
                ls: core::ptr::null_mut(),
                n,
                nnz,
                strategy: KIN_LINESEARCH,
                maxstepfactor: openmodelica_solvers::solverflags::max_step_factor(),
                numeric_jac: false,
                solved: false,
                vals: vec![0.0; nnz],
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
                KINSetFuncNormTol(s.kin, openmodelica_solvers::solverflags::newton_ftol());
                KINSetScaledStepTol(s.kin, openmodelica_solvers::solverflags::newton_xtol());
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
        /// The Jacobian is re-evaluated unless the last solve reached full accuracy,
        /// where C scales the one still in memory.
        fn f_scaling(&mut self, ud: &mut Ud) {
            let vals = &mut self.vals;
            if !self.solved {
                let x = data(self.u, self.n);
                if ud.numeric {
                    let mut fx = vec![0.0f64; ud.n];
                    (ud.eval)(x, &mut fx);
                    numeric_csc(ud, x, &fx, vals);
                } else {
                    (ud.assemble)(x, vals);
                }
                derivative_test(ud, x, vals);
            }
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
                    unsafe { SUNLinSol_KLUReInit(self.ls, self.j, self.nnz as SunIndex, SUNKLU_REINIT_PARTIAL) };
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
        #[allow(clippy::too_many_arguments)]
        pub fn solve(
            &mut self,
            guess: &[f64],
            nominal: &[f64],
            pat: &super::Pattern,
            x: &mut [f64],
            eq_index: u32,
            time: f64,
            has_jacobian: bool,
            eval: &mut dyn FnMut(&[f64], &mut [f64]),
            assemble: &mut dyn FnMut(&[f64], &mut [f64]),
        ) -> bool {
            // C's `KINSetJacFn(.., nlsSparseJac)` for a system without an
            // analytical Jacobian: differenced from the start.
            if !has_jacobian {
                self.numeric_jac = true;
            }
            let mut ud = Ud {
                n: self.n,
                nnz: self.nnz,
                colptr: pat.colptr,
                rowidx: pat.rowidx,
                colors: pat.colors,
                max: pat.max,
                eval,
                assemble,
                numeric: self.numeric_jac,
                eq_index,
                time,
            };
            unsafe { KINSetUserData(self.kin, &mut ud as *mut Ud as *mut c_void) };
            let mut success = false;
            let mut reset_tol = false;
            let mut retries = 0;
            let mut passes = 0;
            loop {
                data(self.u, self.n).copy_from_slice(guess);
                self.x_scaling(nominal);
                self.f_scaling(&mut ud);
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
            self.solved = success && !reset_tol;
            if reset_tol {
                unsafe {
                    KINSetFuncNormTol(self.kin, openmodelica_solvers::solverflags::newton_ftol());
                    KINSetScaledStepTol(self.kin, openmodelica_solvers::solverflags::newton_xtol());
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

    // ---------------------------------------------------------------------------
    // `kinsol_b.c` ("experimental-kinsol"): the same library, driven differently.
    // KINSOL gets unit scale vectors and the solver keeps `x`, `f` and the Jacobian
    // in scaled units itself, so the analyses see a scaled matrix -- which is what
    // their headers report.
    // ---------------------------------------------------------------------------

    /// C's `B_FTOL_WITH_LESS_ACCURACY` / `B_RETRY_MAX`.
    const B_FTOL_LESS_ACCURACY: f64 = 1.0e-6;
    const B_RETRY_MAX: i32 = 5;

    /// C's `B_initialMode`.
    #[derive(Clone, Copy, PartialEq, Eq)]
    enum BInitial {
        Extrapolation,
        OldValues,
    }

    /// C's `B_scalingMode`.
    #[derive(Clone, Copy, PartialEq, Eq)]
    enum BScaling {
        NominalStart,
        Ones,
        Jacobian,
    }

    /// The system being solved, plus C's `useScaling` and its two scale vectors.
    struct BUd<'a> {
        n: usize,
        nnz: usize,
        /// `Some` for a system with a sparsity pattern, whose matrix is CSC; `None`
        /// for C's dense linear solver, whose matrix is column-major `n×n`.
        pattern: Option<(&'a [i32], &'a [i32])>,
        eval: &'a mut dyn FnMut(&[f64], &mut [f64]),
        /// C's `analyticalJacobianColumn`; `None` differences the Jacobian instead.
        assemble: Option<&'a mut dyn FnMut(&[f64], &mut [f64])>,
        eq_index: u32,
        time: f64,
        /// The model's iteration variables, where the residual last left them.
        /// C's `evalJacobian` reads the model where it stands rather than at a
        /// point handed to it, so the scaling Jacobian is taken there too.
        load_guess: &'a mut dyn FnMut(&mut [f64]),
        scaling: bool,
        xscale: vec::Vec<f64>,
        fscale: vec::Vec<f64>,
    }

    impl BUd<'_> {
        /// Every stored entry as `(column, row, index into the value array)`.
        fn for_each_entry(&self, mut f: impl FnMut(usize, usize, usize)) {
            match self.pattern {
                Some((colptr, rowidx)) => {
                    for c in 0..self.n {
                        for k in colptr[c] as usize..colptr[c + 1] as usize {
                            f(c, rowidx[k] as usize, k);
                        }
                    }
                }
                None => {
                    for c in 0..self.n {
                        for r in 0..self.n {
                            f(c, r, c * self.n + r);
                        }
                    }
                }
            }
        }

        /// C's `nlsKinsolInplaceScaleX` / `…UnscaleX`.
        fn scale_x(&self, x: &mut [f64]) {
            for (v, s) in x.iter_mut().zip(self.xscale.iter()) {
                *v *= *s;
            }
        }

        fn unscale_x(&self, x: &mut [f64]) {
            for (v, s) in x.iter_mut().zip(self.xscale.iter()) {
                *v /= *s;
            }
        }

        /// C's `nlsKinsolInplaceScaleJac`: `J[row][col] *= fScale[row] / xScale[col]`.
        fn scale_jac(&self, vals: &mut [f64]) {
            let (xscale, fscale) = (&self.xscale, &self.fscale);
            self.for_each_entry(|c, r, k| vals[k] *= fscale[r] / xscale[c]);
        }

        fn unscale_jac(&self, vals: &mut [f64]) {
            let (xscale, fscale) = (&self.xscale, &self.fscale);
            self.for_each_entry(|c, r, k| vals[k] *= xscale[c] / fscale[r]);
        }

        /// C's `B_nlsKinsolResiduals` called outside a KINSOL callback.
        fn residual(&mut self, x: &mut [f64], f: &mut [f64]) {
            if self.scaling {
                self.unscale_x(x);
            }
            (self.eval)(x, f);
            if self.scaling {
                self.scale_x(x);
                for (v, s) in f.iter_mut().zip(self.fscale.iter()) {
                    *v *= *s;
                }
            }
        }

        /// C's `B_nlsSparseSymJac` / `B_nlsSparseJac` / `B_nlsDenseJac` body. C
        /// evaluates `f(x)` itself before differencing, scaling off for the pass.
        fn jacobian(&mut self, x: &mut [f64], vals: &mut [f64]) {
            let scaled = self.scaling;
            if scaled {
                self.unscale_x(x);
                self.scaling = false;
            }
            match &mut self.assemble {
                Some(assemble) => assemble(x, vals),
                None => {
                    let mut f = vec![0.0f64; self.n];
                    (self.eval)(x, &mut f);
                    b_numeric_jac(self, x, &f, vals);
                }
            }
            self.scaling = scaled;
            if scaled {
                self.scale_x(x);
                self.scale_jac(vals);
            }
            self.derivative_test(x, vals);
        }

        /// C's `nlsKinsolDenseDerivativeTest`: a copy of the iterate, differenced
        /// unscaled by `B_nlsDenseJac`, and only the finished matrix scaled.
        fn derivative_test(&mut self, x: &[f64], vals: &[f64]) {
            if !openmodelica_solvers::omclog::active(openmodelica_solvers::omclog::NLS_DERIVATIVE_TEST) {
                return;
            }
            let Some((colptr, rowidx)) = self.pattern else { return };
            let (n, scaling) = (self.n, self.scaling);
            let (xscale, fscale) = (self.xscale.to_vec(), self.fscale.to_vec());
            let mut xu = x.to_vec();
            if scaling {
                for (v, s) in xu.iter_mut().zip(&xscale) {
                    *v /= *s;
                }
            }
            let scale = scaling.then(|| (&fscale[..], &xscale[..]));
            crate::jacobian_analysis::derivative_test(
                self.eq_index, self.time, n, &mut xu, colptr, rowidx, vals, scale,
                crate::jacobian_analysis::Caller::KinsolBJacEval, self.eval,
            );
        }
    }

    /// C's `B_nlsSparseJac` / `B_nlsDenseJac` difference quotients, one column at a
    /// time (see [`numeric_csc`] for why the colouring is not replayed).
    fn b_numeric_jac(ud: &mut BUd, x: &mut [f64], fx: &[f64], vals: &mut [f64]) {
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
            match ud.pattern {
                Some((colptr, rowidx)) => {
                    for k in colptr[c] as usize..colptr[c + 1] as usize {
                        let row = rowidx[k] as usize;
                        vals[k] = (fres[row] - fx[row]) * inv;
                    }
                }
                None => {
                    for r in 0..ud.n {
                        vals[c * ud.n + r] = (fres[r] - fx[r]) * inv;
                    }
                }
            }
        }
    }

    extern "C" fn b_residual(u: NVector, fval: NVector, user: *mut c_void) -> c_int {
        let ud = unsafe { &mut *(user as *mut BUd) };
        let (x, f) = (data(u, ud.n), data(fval, ud.n));
        ud.residual(x, f);
        crate::assert_hit() as c_int
    }

    /// Only registered for the sparse matrix: with C's dense linear solver KINSOL
    /// differences its own Jacobian (`initKinsolMemory` sets no `KINSetJacFn`).
    extern "C" fn b_jacobian(u: NVector, _fu: NVector, j: SunMatrix, user: *mut c_void, _t1: NVector, _t2: NVector) -> c_int {
        let ud = unsafe { &mut *(user as *mut BUd) };
        let x = data(u, ud.n);
        let vals = unsafe { core::slice::from_raw_parts_mut(SUNSparseMatrix_Data(j), ud.nnz) };
        ud.jacobian(x, vals);
        if let Some((colptr, rowidx)) = ud.pattern {
            unsafe {
                put_index(SUNSparseMatrix_IndexPointers(j), &colptr[..ud.n + 1]);
                put_index(SUNSparseMatrix_IndexValues(j), &rowidx[..ud.nnz]);
            }
        }
        0
    }

    /// One system's `B_NLS_KINSOL_DATA`.
    pub struct BSolver {
        ctx: SunContext,
        kin: *mut c_void,
        /// C's `initialGuess`, which is also KINSOL's solution vector.
        u: NVector,
        ones_x: NVector,
        ones_f: NVector,
        j: SunMatrix,
        ls: SunLinSol,
        n: usize,
        nnz: usize,
        /// The matrix is CSC over a sparsity pattern; otherwise column-major dense.
        sparse: bool,
        /// Set for good once `KIN_LSETUP_FAIL` rejects the analytic Jacobian, as C
        /// re-points `KINSetJacFn` at its numeric one.
        numeric_jac: bool,
        strategy: c_int,
        maxstepfactor: f64,
        /// C's `kinsolData->solved == NLS_SOLVED`: the f-scaling then reuses `j`.
        solved: bool,
        reset_tol: bool,
    }

    impl BSolver {
        /// `nnz == 0` selects C's dense linear solver, which is what a system without
        /// a sparsity pattern gets (`initKinsolMemory`).
        pub fn new(n: usize, nnz: usize) -> Option<BSolver> {
            let ctx = context();
            if ctx.is_null() {
                return None;
            }
            let ones = |ctx| {
                let v = unsafe { N_VNew_Serial(n as SunIndex, ctx) };
                if !v.is_null() {
                    unsafe { N_VConst(1.0, v) };
                }
                v
            };
            let sparse = nnz != 0;
            let mut s = BSolver {
                ctx,
                kin: unsafe { KINCreate(ctx) },
                u: unsafe { N_VNew_Serial(n as SunIndex, ctx) },
                ones_x: ones(ctx),
                ones_f: ones(ctx),
                j: unsafe {
                    if sparse {
                        SUNSparseMatrix(n as SunIndex, n as SunIndex, nnz as SunIndex, CSC_MAT, ctx)
                    } else {
                        SUNDenseMatrix(n as SunIndex, n as SunIndex, ctx)
                    }
                },
                ls: core::ptr::null_mut(),
                n,
                nnz: if sparse { nnz } else { n * n },
                sparse,
                numeric_jac: false,
                strategy: KIN_LINESEARCH,
                maxstepfactor: openmodelica_solvers::solverflags::max_step_factor(),
                solved: false,
                reset_tol: false,
            };
            if s.kin.is_null() || s.j.is_null() || [s.u, s.ones_x, s.ones_f].iter().any(|v| v.is_null()) {
                return None;
            }
            s.ls = unsafe {
                if sparse { SUNLinSol_KLU(s.u, s.j, s.ctx) } else { SUNLinSol_Dense(s.u, s.j, s.ctx) }
            };
            if s.ls.is_null() {
                return None;
            }
            unsafe {
                if KINInit(s.kin, b_residual, s.u) != KIN_SUCCESS
                    || KINSetLinearSolver(s.kin, s.ls, s.j) != KIN_SUCCESS
                    || (sparse && KINSetJacFn(s.kin, b_jacobian) != KIN_SUCCESS)
                {
                    return None;
                }
                KINSetFuncNormTol(s.kin, openmodelica_solvers::solverflags::newton_ftol());
                KINSetScaledStepTol(s.kin, openmodelica_solvers::solverflags::newton_xtol());
                KINSetNumMaxIters(s.kin, 100 * n as c_long);
                KINSetNoInitSetup(s.kin, 0);
            }
            Some(s)
        }

        /// The Jacobian values KINSOL, the scaling and the analyses all share --
        /// C's one `kinsolData->J`.
        fn jvals(&self) -> &'static mut [f64] {
            let data = unsafe {
                if self.sparse { SUNSparseMatrix_Data(self.j) } else { SUNDenseMatrix_Data(self.j) }
            };
            unsafe { core::slice::from_raw_parts_mut(data, self.nnz) }
        }

        fn write_pattern(&self, ud: &BUd) {
            let Some((colptr, rowidx)) = ud.pattern else { return };
            unsafe {
                put_index(SUNSparseMatrix_IndexPointers(self.j), &colptr[..self.n + 1]);
                put_index(SUNSparseMatrix_IndexValues(self.j), &rowidx[..self.nnz]);
            }
        }

        /// C's `B_nlsKinsolResetInitialUnscaled`.
        fn reset_initial(&self, mode: BInitial, start: &[f64], old: &[f64]) {
            let src = match mode {
                BInitial::Extrapolation => start,
                BInitial::OldValues => old,
            };
            data(self.u, self.n).copy_from_slice(src);
        }

        /// C's `B_nlsKinsolXScaling`.
        fn x_scaling(&self, ud: &mut BUd, nominal: &[f64], mode: BScaling) {
            let start = data(self.u, self.n);
            match mode {
                BScaling::NominalStart => {
                    for (i, s) in ud.xscale.iter_mut().enumerate() {
                        *s = 1.0 / libm::fmax(nominal[i], libm::fabs(start[i]));
                    }
                }
                _ => ud.xscale.fill(1.0),
            }
        }

        /// C's `B_nlsKinsolFScaling`: `fScale[i] = 1/max_j |J_ij / xScale_j|`, with
        /// C's `1e-12` floor. The Jacobian is re-evaluated unless the last solve
        /// reached full accuracy.
        fn f_scaling(&mut self, ud: &mut BUd, mode: BScaling) {
            ud.scaling = false;
            if mode != BScaling::Jacobian {
                ud.fscale.fill(1.0);
                return;
            }
            if !self.solved {
                // C's `B_nlsSparseSymJac` passes `initialGuess` but `evalJacobian`
                // ignores it: after a failed `KINSol` the matrix is the one at that
                // solve's last iterate, not at the start point just restored.
                let mut x: vec::Vec<f64> = vec![0.0; self.n];
                (ud.load_guess)(&mut x);
                let vals = self.jvals();
                ud.jacobian(&mut x, vals);
                self.write_pattern(ud);
            }
            let vals = self.jvals();
            ud.fscale.fill(1e-12);
            // C's `_omc_SUNSparseMatrixVecScaling` on a copy, then the row maxima.
            let (n, pattern) = (ud.n, ud.pattern);
            let BUd { xscale, fscale, .. } = &mut *ud;
            let mut row_max = |c: usize, r: usize, k: usize| {
                let v = libm::fabs(vals[k] / xscale[c]);
                if fscale[r] < v {
                    fscale[r] = v;
                }
            };
            match pattern {
                Some((colptr, rowidx)) => {
                    for c in 0..n {
                        for k in colptr[c] as usize..colptr[c + 1] as usize {
                            row_max(c, rowidx[k] as usize, k);
                        }
                    }
                }
                None => {
                    for c in 0..n {
                        for r in 0..n {
                            row_max(c, r, c * n + r);
                        }
                    }
                }
            }
            for s in fscale.iter_mut() {
                *s = 1.0 / *s;
            }
        }

        /// C's `B_nlsKinsolSetMaxNewtonStep`: `N_VWL2Norm(xScale, maxstepfactor·1)`.
        fn max_newton_step(&self, ud: &BUd) {
            let sq: f64 = ud.xscale.iter().map(|s| s * self.maxstepfactor).map(|v| v * v).sum();
            unsafe { KINSetMaxNewtonStep(self.kin, libm::sqrt(sq)) };
        }

        /// C's `nlsKinsolErrorHandler` (`kinsol_b.c`): `true` to try again.
        fn handle_error(
            &mut self,
            code: c_int,
            ud: &mut BUd,
            nominal: &[f64],
            start: &[f64],
            old: &[f64],
            retries: &mut i32,
        ) -> bool {
            unsafe { KINSetNoInitSetup(self.kin, 0) };
            match code {
                KIN_MEM_NULL | KIN_ILL_INPUT | KIN_NO_MALLOC => return false,
                KIN_MXNEWT_5X_EXCEEDED => {
                    self.maxstepfactor *= 1e5;
                    self.max_newton_step(ud);
                    return true;
                }
                KIN_LINESEARCH_NONCONV => {
                    self.strategy = KIN_NONE;
                    *retries -= 1;
                    return true;
                }
                KIN_LSOLVE_FAIL => {
                    unsafe { SUNLinSol_KLUReInit(self.ls, self.j, self.nnz as SunIndex, SUNKLU_REINIT_PARTIAL) };
                    return true;
                }
                // C's own `return errorCode` here is a nonzero "retry".
                KIN_LINIT_FAIL => return true,
                // A Jacobian KLU cannot factorize: difference it from here on, as C
                // re-points `KINSetJacFn`.
                KIN_LSETUP_FAIL => {
                    self.numeric_jac = true;
                    ud.assemble = None;
                }
                KIN_MAXITER_REACHED | KIN_REPTD_SYSFUNC_ERR | KIN_LINESEARCH_BCFAIL => {}
                _ => return false,
            }
            let mut fnorm = 0.0;
            unsafe { KINGetFuncNorm(self.kin, &mut fnorm) };
            if fnorm < B_FTOL_LESS_ACCURACY {
                unsafe {
                    KINSetFuncNormTol(self.kin, B_FTOL_LESS_ACCURACY);
                    KINSetScaledStepTol(self.kin, B_FTOL_LESS_ACCURACY);
                }
                self.reset_tol = true;
                return true;
            }
            match *retries {
                0 => {
                    self.x_scaling(ud, nominal, BScaling::Ones);
                    self.f_scaling(ud, BScaling::Ones);
                }
                1 => {
                    self.reset_initial(BInitial::OldValues, start, old);
                    self.strategy = KIN_LINESEARCH;
                }
                2 => {
                    self.reset_initial(BInitial::Extrapolation, start, old);
                    self.strategy = KIN_NONE;
                }
                3 => {
                    self.x_scaling(ud, nominal, BScaling::NominalStart);
                    self.f_scaling(ud, BScaling::Jacobian);
                    self.reset_initial(BInitial::Extrapolation, start, old);
                    unsafe { KINSetMaxSetupCalls(self.kin, 1) };
                    self.strategy = KIN_LINESEARCH;
                }
                4 => {
                    self.x_scaling(ud, nominal, BScaling::Ones);
                    self.f_scaling(ud, BScaling::Ones);
                    self.reset_initial(BInitial::OldValues, start, old);
                    unsafe { KINSetMaxSetupCalls(self.kin, 1) };
                    self.strategy = KIN_LINESEARCH;
                }
                _ => return false,
            }
            true
        }

        /// C's `B_nlsKinsolSolve`.
        #[allow(clippy::too_many_arguments)]
        pub fn solve<'a>(
            &mut self,
            start: &[f64],
            old: &[f64],
            nominal: &[f64],
            pattern: Option<(&'a [i32], &'a [i32])>,
            x: &mut [f64],
            eq_index: u32,
            time: f64,
            load_guess: &'a mut dyn FnMut(&mut [f64]),
            eval: &'a mut dyn FnMut(&[f64], &mut [f64]),
            assemble: Option<&'a mut dyn FnMut(&[f64], &mut [f64])>,
        ) -> bool {
            let mut ud = BUd {
                n: self.n,
                nnz: self.nnz,
                pattern,
                eval,
                assemble: if self.numeric_jac { None } else { assemble },
                eq_index,
                time,
                load_guess,
                scaling: false,
                xscale: vec![1.0f64; self.n],
                fscale: vec![1.0f64; self.n],
            };
            unsafe { KINSetUserData(self.kin, &mut ud as *mut BUd as *mut c_void) };
            let v = openmodelica_solvers::omclog::NLS_V;
            if openmodelica_solvers::omclog::active(v) {
                openmodelica_solvers::omclog::info!(
                    v,
                    true,
                    "Start solving Non-Linear System {eq_index} (size {}) at time {} with Kinsol Solver",
                    self.n,
                    openmodelica_solvers::format_g(time, 6),
                );
            }
            let mut success = false;
            let mut retries = 0;
            let mut passes = 0;
            self.reset_tol = false;
            loop {
                ud.scaling = false;
                self.reset_initial(BInitial::Extrapolation, start, old);
                self.x_scaling(&mut ud, nominal, BScaling::NominalStart);
                self.f_scaling(&mut ud, BScaling::Jacobian);
                self.max_newton_step(&ud);
                ud.scaling = true;
                ud.scale_x(data(self.u, self.n));
                ud.scale_jac(self.jvals());
                self.write_pattern(&ud);
                if let Some((colptr, rowidx)) = pattern {
                    crate::jacobian_analysis::svd_analysis(
                        eq_index, time, self.n, colptr, rowidx, self.jvals(), true,
                        crate::jacobian_analysis::Caller::KinsolBEntry,
                    );
                }
                // C's `B_save_initial_guess_system`, which throws once written; the
                // solve fails here instead, and the run ends on the failed system.
                if let Some((path, file)) = crate::host::take_initial_guess_request(eq_index) {
                    let mut f = vec![0.0f64; self.n];
                    ud.residual(data(self.u, self.n), &mut f);
                    openmodelica_solvers::omclog::info!(
                        openmodelica_solvers::omclog::STDOUT,
                        false,
                        "Trying to write write initial guess for NLS system with index {eq_index} to file {path}.",
                    );
                    match crate::host::write_initial_guess(&file) {
                        Ok(()) => openmodelica_solvers::omclog::info!(
                            openmodelica_solvers::omclog::STDOUT,
                            false,
                            "Success: Initial guess has been written to disk (path = {path}). The program will terminate now.",
                        ),
                        Err(e) => openmodelica_solvers::omclog::error(openmodelica_solvers::omclog::STDOUT, false, &e),
                    }
                    // C throws here; the message it would carry is suppressed with
                    // `LOG_NLS` off, but the run still ends on the failed system.
                    crate::host::note_runtime_error_flag();
                    unsafe { KINSetUserData(self.kin, core::ptr::null_mut()) };
                    return false;
                }
                let flag = unsafe { KINSol(self.kin, self.u, self.strategy, self.ones_x, self.ones_f) };
                let finished = alloc::format!("KINSol finished with errorCode {flag}.");
                if flag < 0 {
                    openmodelica_solvers::omclog::warning(openmodelica_solvers::omclog::NLS, false, &finished);
                } else {
                    openmodelica_solvers::omclog::info(v, false, &finished);
                }
                success = matches!(flag, KIN_SUCCESS | KIN_INITIAL_GUESS_OK | KIN_STEP_LT_STPTOL);
                let retry = flag < 0
                    && self.handle_error(flag, &mut ud, nominal, start, old, &mut retries);
                retries += 1;
                passes += 1;
                openmodelica_solvers::omclog::info!(
                    v,
                    false,
                    "Next try? success = {}, retry = {}, retries = {retries} = {}\n",
                    success as u32,
                    retry as u32,
                    !success && !retry && retries < B_RETRY_MAX,
                );
                if success || !retry || retries >= B_RETRY_MAX || passes >= 2 * B_RETRY_MAX {
                    break;
                }
            }
            self.solved = success && !self.reset_tol;
            if self.reset_tol {
                unsafe {
                    KINSetFuncNormTol(self.kin, openmodelica_solvers::solverflags::newton_ftol());
                    KINSetScaledStepTol(self.kin, openmodelica_solvers::solverflags::newton_xtol());
                }
                self.reset_tol = false;
            }
            if success {
                if ud.scaling {
                    ud.unscale_x(data(self.u, self.n));
                    ud.unscale_jac(self.jvals());
                    ud.scaling = false;
                }
                x.copy_from_slice(data(self.u, self.n));
            }
            openmodelica_solvers::omclog::close(v);
            unsafe { KINSetUserData(self.kin, core::ptr::null_mut()) };
            success
        }
    }

    impl Drop for BSolver {
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
                for v in [self.u, self.ones_x, self.ones_f] {
                    if !v.is_null() {
                        N_VDestroy(v);
                    }
                }
                if !self.ctx.is_null() {
                    SUNContext_Free(&mut self.ctx);
                }
            }
        }
    }
}

/// Whether the entry points below are the real KINSOL rather than the stubs at the
/// end of this file. Each crate's `cfg(sundials)` comes from its own build script,
/// so a host must ask rather than test its own.
pub const AVAILABLE: bool = cfg!(sundials);

/// One solver per system `handle`, kept for the run so KINSOL and KLU reuse their
/// setup. Keyed, not scanned: a model can have one system per discretization
/// volume. Single-threaded, as the rest of this crate's rosters are.
#[cfg(sundials)]
struct Cache<T>(core::cell::UnsafeCell<alloc::collections::BTreeMap<u32, T>>);
#[cfg(sundials)]
unsafe impl<T> Sync for Cache<T> {}

#[cfg(sundials)]
impl<T> Cache<T> {
    /// Detach the solver for `handle` so a model callback can re-enter for a nested
    /// system, run `f`, then put it back.
    fn with(&self, handle: u32, new: impl FnOnce() -> Option<T>, f: impl FnOnce(&mut T) -> bool) -> bool {
        let mut solver = match unsafe { &mut *self.0.get() }.remove(&handle) {
            Some(s) => s,
            None => match new() {
                Some(s) => s,
                None => return false,
            },
        };
        let ok = f(&mut solver);
        unsafe { &mut *self.0.get() }.insert(handle, solver);
        ok
    }
}

#[cfg(sundials)]
static KIN_CACHE: Cache<sun::Solver> =
    Cache(core::cell::UnsafeCell::new(alloc::collections::BTreeMap::new()));
/// [`KIN_CACHE`] for `-nls=kinsol_b`.
#[cfg(sundials)]
static KIN_B_CACHE: Cache<sun::BSolver> =
    Cache(core::cell::UnsafeCell::new(alloc::collections::BTreeMap::new()));

/// Drop every per-system KINSOL/KLU memory; they belong to one run.
#[cfg(sundials)]
pub fn reset_caches() {
    unsafe { &mut *KIN_CACHE.0.get() }.clear();
    unsafe { &mut *KIN_B_CACHE.0.get() }.clear();
}

/// [`solve`] for `-nls=kinsol_b` (C's `B_nlsKinsolSolve`). `start` is C's
/// `INITIAL_EXTRAPOLATION` value and `old` its `INITIAL_OLDVALUES`.
#[cfg(sundials)]
#[allow(clippy::too_many_arguments)]
pub fn b_solve<'a>(
    handle: u32,
    n: usize,
    nnz: usize,
    pattern: Option<(&'a [i32], &'a [i32])>,
    nominal: &[f64],
    start: &[f64],
    old: &[f64],
    x: &mut [f64],
    eq_index: u32,
    time: f64,
    load_guess: &'a mut dyn FnMut(&mut [f64]),
    eval: &'a mut dyn FnMut(&[f64], &mut [f64]),
    assemble: Option<&'a mut dyn FnMut(&[f64], &mut [f64])>,
) -> bool {
    KIN_B_CACHE.with(handle, || sun::BSolver::new(n, nnz), |solver| {
        solver.solve(start, old, nominal, pattern, x, eq_index, time, load_guess, eval, assemble)
    })
}

/// Solve system `handle` with KINSOL + KLU from `guess`, writing the solution into
/// `x`. `eval` evaluates the residual, `assemble` the `nnz` CSC Jacobian values.
#[cfg(sundials)]
#[allow(clippy::too_many_arguments)]
pub fn solve(
    handle: u32,
    n: usize,
    pat: &Pattern,
    nominal: &[f64],
    guess: &[f64],
    x: &mut [f64],
    eq_index: u32,
    time: f64,
    has_jacobian: bool,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    assemble: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    KIN_CACHE.with(handle, || sun::Solver::new(n, pat.nnz), |solver| {
        solver.solve(guess, nominal, pat, x, eq_index, time, has_jacobian, eval, assemble)
    })
}

// ---------------------------------------------------------------------------
// Without the archives
// ---------------------------------------------------------------------------

/// A host still calls these; they report that they solved nothing, and
/// [`AVAILABLE`] is what tells it to take the dense ladder instead.
#[cfg(not(sundials))]
mod stub {
    pub fn reset_caches() {}

    #[allow(clippy::too_many_arguments)]
    pub fn b_solve<'a>(
        _handle: u32,
        _n: usize,
        _nnz: usize,
        _pattern: Option<(&'a [i32], &'a [i32])>,
        _nominal: &[f64],
        _start: &[f64],
        _old: &[f64],
        _x: &mut [f64],
        _eq_index: u32,
        _time: f64,
        _load_guess: &'a mut dyn FnMut(&mut [f64]),
        _eval: &'a mut dyn FnMut(&[f64], &mut [f64]),
        _assemble: Option<&'a mut dyn FnMut(&[f64], &mut [f64])>,
    ) -> bool {
        false
    }

    #[allow(clippy::too_many_arguments)]
    pub fn solve(
        _handle: u32,
        _n: usize,
        _pat: &super::Pattern,
        _nominal: &[f64],
        _guess: &[f64],
        _x: &mut [f64],
        _eq_index: u32,
        _time: f64,
        _has_jacobian: bool,
        _eval: &mut dyn FnMut(&[f64], &mut [f64]),
        _assemble: &mut dyn FnMut(&[f64], &mut [f64]),
    ) -> bool {
        false
    }
}

#[cfg(not(sundials))]
pub use stub::{b_solve, reset_caches, solve};

/// The KINSOL driver `-nls` names, over the system's CSC pattern: `kinsolSolver.c`
/// for `kinsol`, `kinsol_b.c` for `experimental-kinsol`. C picks between them per
/// system in `solveNLS`, so the choice lives here rather than in each host.
#[allow(clippy::too_many_arguments)]
pub fn solve_selected(
    handle: u32,
    n: usize,
    pat: &Pattern,
    nominal: &[f64],
    guess: &[f64],
    old_values: &[f64],
    x: &mut [f64],
    eq_index: u32,
    time: f64,
    has_jacobian: bool,
    load_guess: &mut dyn FnMut(&mut [f64]),
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    assemble: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    if openmodelica_solvers::solverflags::nls() == openmodelica_solvers::solverflags::Nls::KinsolB {
        // C's `INITIAL_EXTRAPOLATION`: `discreteCall ? nlsx : nlsxExtrapolation`,
        // which is the start point the caller already picked.
        let start = x.to_vec();
        return b_solve(
            handle, n, pat.nnz, Some((pat.colptr, pat.rowidx)), nominal, &start, old_values, x,
            eq_index, time, load_guess, eval, has_jacobian.then_some(assemble),
        );
    }
    solve(handle, n, pat, nominal, guess, x, eq_index, time, has_jacobian, eval, assemble)
}
