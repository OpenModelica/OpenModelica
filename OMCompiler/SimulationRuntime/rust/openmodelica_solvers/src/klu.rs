//! KLU (SuiteSparse) over a compressed matrix, with C's `DATA_KLU` policy from
//! `linearSolverKlu.c`: one symbolic analysis per system, then a numeric
//! refactorization per solve that keeps the first factorization's pivots until
//! `rgrowth` says they went bad.
//!
//! Both runtimes drive it: the wasm-jit runtime hands it the transpose of a CSC
//! pattern, the runtime the C code generator links hands it the CSR the generated
//! `setA` builds. [`Factorization`] exists whether or not the archives were built
//! -- as a stub that solves nothing when they were not -- so no caller needs a
//! `cfg(sundials)` of its own; ask [`AVAILABLE`] instead.

/// Whether KLU is linked into this build.
pub const AVAILABLE: bool = cfg!(sundials);

/// Below this reciprocal pivot growth the reused pivots are no longer good enough
/// and the factorization is redone with new ones (C's threshold).
pub const MIN_RGROWTH: f64 = 1e-3;

/// `KLU_INVALID`, the status of a pattern KLU refused to analyze.
pub const INVALID: i32 = -3;

#[cfg(sundials)]
mod real {
    use core::ffi::c_void;

    /// `klu_common` (`Int` = `int`), mirrored rather than opaque because the
    /// factor/refactor decision reads `status` and `rgrowth`. [`Common::defaults`]
    /// validates the layout against what `klu_defaults` writes.
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
        fn klu_defaults(common: *mut Common) -> i32;
        fn klu_analyze(n: i32, ap: *mut i32, ai: *mut i32, common: *mut Common) -> *mut c_void;
        fn klu_factor(ap: *mut i32, ai: *mut i32, ax: *mut f64, symbolic: *mut c_void, common: *mut Common) -> *mut c_void;
        fn klu_refactor(ap: *mut i32, ai: *mut i32, ax: *mut f64, symbolic: *mut c_void, numeric: *mut c_void, common: *mut Common) -> i32;
        fn klu_rgrowth(ap: *mut i32, ai: *mut i32, ax: *mut f64, symbolic: *mut c_void, numeric: *mut c_void, common: *mut Common) -> i32;
        fn klu_solve(symbolic: *mut c_void, numeric: *mut c_void, ldim: i32, nrhs: i32, b: *mut f64, common: *mut Common) -> i32;
        fn klu_tsolve(symbolic: *mut c_void, numeric: *mut c_void, ldim: i32, nrhs: i32, b: *mut f64, common: *mut Common) -> i32;
        fn klu_free_symbolic(symbolic: *mut *mut c_void, common: *mut Common) -> i32;
        fn klu_free_numeric(numeric: *mut *mut c_void, common: *mut Common) -> i32;
    }

    impl Common {
        /// `klu_defaults`, `None` if the values did not land where this mirror puts
        /// them -- a layout mismatch would otherwise show up as silent nonsense.
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

    /// Whether `klu_defaults` writes where [`Common`] says it does.
    pub fn layout_ok() -> bool {
        Common::defaults().is_some()
    }

    /// The pattern's symbolic analysis and the numeric factors over it. The
    /// pattern (`ap`, `n + 1` long, and `ai`) is the caller's and must not change
    /// between [`Factorization::analyze`] and the solves.
    pub struct Factorization {
        common: Common,
        symbolic: *mut c_void,
        numeric: *mut c_void,
        n: usize,
    }

    impl Factorization {
        /// `klu_analyze`: the fill-reducing ordering of the pattern, once.
        pub fn analyze(n: usize, ap: &mut [i32], ai: &mut [i32]) -> Option<Factorization> {
            let mut f = Factorization {
                common: Common::defaults()?,
                symbolic: core::ptr::null_mut(),
                numeric: core::ptr::null_mut(),
                n,
            };
            f.symbolic = unsafe { klu_analyze(n as i32, ap.as_mut_ptr(), ai.as_mut_ptr(), &mut f.common) };
            (!f.symbolic.is_null()).then_some(f)
        }

        /// C's factor-or-refactor step over `ax`: reuse the pivots while `rgrowth`
        /// holds up, else factor afresh. `false` if the matrix is singular or a KLU
        /// call failed. Unlike C, a failure here does not stick: the next call
        /// refactors again.
        pub fn factor(&mut self, ap: &mut [i32], ai: &mut [i32], ax: &mut [f64]) -> bool {
            let (ap, ai, ax) = (ap.as_mut_ptr(), ai.as_mut_ptr(), ax.as_mut_ptr());
            if !self.numeric.is_null() {
                let ok = unsafe {
                    klu_refactor(ap, ai, ax, self.symbolic, self.numeric, &mut self.common) != 0
                        && klu_rgrowth(ap, ai, ax, self.symbolic, self.numeric, &mut self.common) != 0
                };
                if !ok || self.common.rgrowth < super::MIN_RGROWTH {
                    unsafe { klu_free_numeric(&mut self.numeric, &mut self.common) };
                    self.numeric = core::ptr::null_mut();
                }
            }
            if self.numeric.is_null() {
                self.numeric = unsafe { klu_factor(ap, ai, ax, self.symbolic, &mut self.common) };
            }
            !self.numeric.is_null() && self.common.status == 0
        }

        /// `klu_solve`: `A x = b` in place, for the factors of `A`'s own CSC.
        pub fn solve(&mut self, b: &mut [f64]) -> bool {
            !self.numeric.is_null()
                && unsafe { klu_solve(self.symbolic, self.numeric, self.n as i32, 1, b.as_mut_ptr(), &mut self.common) != 0 }
        }

        /// `klu_tsolve`: `A x = b` in place, for the factors of `Aᵀ` (a CSR of `A`).
        pub fn tsolve(&mut self, b: &mut [f64]) -> bool {
            !self.numeric.is_null()
                && unsafe { klu_tsolve(self.symbolic, self.numeric, self.n as i32, 1, b.as_mut_ptr(), &mut self.common) != 0 }
        }

        /// `klu_common.status` after the last call.
        pub fn status(&self) -> i32 {
            self.common.status
        }

        /// `klu_common.rgrowth` after the last refactorization.
        pub fn rgrowth(&self) -> f64 {
            self.common.rgrowth
        }
    }

    impl Drop for Factorization {
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

#[cfg(not(sundials))]
mod real {
    pub fn layout_ok() -> bool {
        false
    }

    /// The stub of a build without the archives: never analyzes.
    pub struct Factorization {}

    impl Factorization {
        pub fn analyze(_n: usize, _ap: &mut [i32], _ai: &mut [i32]) -> Option<Factorization> {
            None
        }
        pub fn factor(&mut self, _ap: &mut [i32], _ai: &mut [i32], _ax: &mut [f64]) -> bool {
            false
        }
        pub fn solve(&mut self, _b: &mut [f64]) -> bool {
            false
        }
        pub fn tsolve(&mut self, _b: &mut [f64]) -> bool {
            false
        }
        pub fn status(&self) -> i32 {
            -1
        }
        pub fn rgrowth(&self) -> f64 {
            -1.0
        }
    }
}

pub use real::*;
