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

#[cfg(sundials)]
unsafe extern "C" {
    fn KINCreate() -> *mut core::ffi::c_void;
    fn KINFree(kinmem: *mut *mut core::ffi::c_void);
}

/// Smoke test that the archives are linked and callable: `klu_defaults` reports
/// success and its values land where [`klu::Common`] mirrors them, and KINSOL
/// allocates.
#[cfg(sundials)]
#[unsafe(no_mangle)]
pub extern "C" fn rt_sundials_selftest() -> i32 {
    let common_ok = klu::Common::defaults().is_some();
    let mut kin = unsafe { KINCreate() };
    let kin_ok = !kin.is_null();
    if kin_ok {
        unsafe { KINFree(&mut kin) };
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

/// Drop the per-system factorizations; their patterns belong to one run.
pub(crate) fn reset_caches() {
    #[cfg(sundials)]
    KLU_CACHE.with(|c| c.borrow_mut().clear());
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
