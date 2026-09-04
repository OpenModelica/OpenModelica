//! The real SUNDIALS/KLU, cross-compiled to wasm and linked in by `build.rs`
//! (`cfg(sundials)`): the SuiteSparse solvers behind this runtime's *linear*
//! systems. KINSOL, which the nonlinear ones use, is
//! [`openmodelica_nls::kinsol`] -- shared with the runtime the C code generator
//! links -- and is re-exported at the end of this file under the names
//! `src/nls.rs` calls it by.
//!
//! Indices here are `i32` (`SUNDIALS_INDEX_SIZE=32`, see the build script for why)
//! and `sunrealtype` is `f64`. The shared binding cannot assume that: the host
//! archives are built with 64-bit indices, so it takes them as `SunIndex`.

/// Whether the real solvers are linked into this blob.
#[unsafe(no_mangle)]
pub extern "C" fn rt_sundials_available() -> i32 {
    cfg!(sundials) as i32
}

/// What this build can serve, for `simflags::check`.
pub fn capabilities() -> openmodelica_sim_meta::simflags::Capabilities {
    openmodelica_sim_meta::simflags::Capabilities {
        klu: groups::klu(),
        kinsol: groups::kinsol(),
        umfpack: groups::umfpack(),
        lis: groups::lis(),
        ida: openmodelica_sim_meta::IDA && groups::driver(),
        cvode: openmodelica_sim_meta::CVODE && groups::driver(),
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

/// Which solver libraries this build has. An FMU links one PIC side module per
/// library, chosen at export, so the answer is a run-time one: the stub standing in
/// for what was left out answers 0 where a real module answers 1. Every other build
/// links the archives statically and has all of them or none.
#[cfg(sundials_dylink)]
mod groups {
    unsafe extern "C" {
        fn om_have_klu() -> i32;
        fn om_have_kinsol() -> i32;
        fn om_have_umfpack() -> i32;
        fn om_have_lis() -> i32;
        fn om_have_sundials_driver() -> i32;
    }
    macro_rules! ask {
        ($name:ident, $sym:ident) => {
            pub fn $name() -> bool {
                unsafe { $sym() != 0 }
            }
        };
    }
    ask!(klu, om_have_klu);
    ask!(kinsol, om_have_kinsol);
    ask!(umfpack, om_have_umfpack);
    ask!(lis, om_have_lis);
    ask!(driver, om_have_sundials_driver);
}

#[cfg(not(sundials_dylink))]
mod groups {
    macro_rules! ask {
        ($name:ident) => {
            pub fn $name() -> bool {
                cfg!(sundials)
            }
        };
    }
    ask!(klu);
    ask!(kinsol);
    ask!(umfpack);
    ask!(lis);
    ask!(driver);
}

/// Whether KINSOL is linked. Only an FMU answers no: what its export left out is a
/// stub that traps, and no flag records the density rule's choice of KINSOL.
pub(crate) fn have_kinsol() -> bool {
    groups::kinsol()
}

/// The same for KLU.
pub(crate) fn have_klu() -> bool {
    groups::klu()
}

/// The same for UMFPACK.
pub(crate) fn have_umfpack() -> bool {
    groups::umfpack()
}

/// Smoke test that the archives are linked and callable: `klu_defaults` reports
/// success and its values land where [`klu::Common`] mirrors them, and KINSOL
/// allocates.
#[cfg(sundials)]
#[unsafe(no_mangle)]
pub extern "C" fn rt_sundials_selftest() -> i32 {
    let common_ok = klu::Common::defaults().is_some();
    (common_ok && openmodelica_nls::kinsol::sun::probe()) as i32
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
        openmodelica_nls::kinsol::reset_caches();
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

// The KINSOL half of C's `kinsolSolver.c` / `kinsol_b.c` is
// `openmodelica_nls::kinsol`, shared with `openmodelica_simulation_runtime`: the
// binding exchanges plain slices, so both runtimes drive the same one.
#[cfg(sundials)]
pub(crate) use openmodelica_nls::kinsol::{
    b_solve as kinsol_b_solve, solve_selected as kinsol_solve_selected,
};
