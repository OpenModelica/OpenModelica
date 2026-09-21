//! Rust port of **Cdaskr** — the f2c translation of the DASKR / DASSL
//! differential-algebraic equation solver
//! (`OMCompiler/3rdParty/Cdaskr`).
//!
//! The port is faithful to the C (which is itself a faithful translation of the
//! original Fortran): control flow, floating-point operation order and pivoting
//! are preserved so results match the C reference bit-for-bit. That equivalence
//! is checked by the `cref` cross-validation tests (see `tests/cref.rs`), which
//! link the original C and compare outputs.
//!
//! Layers, bottom-up:
//! * [`linpack`] — the LINPACK dense/banded LU factor+solve and the BLAS-1
//!   kernels (`dlinpk.c`).
//! * [`auxiliary`] — machine constants and the error-message helpers (`daux.c`).
//! * [`solver`] — the core integrator (`ddaskr.c`): the BDF predictor/corrector,
//!   initial-condition solver, root finder, and the Krylov (SPIGMR) linear
//!   solver. All paths are cross-checked bit-for-bit against the C in
//!   `tests/solver_cref.rs` (direct dense/banded, analytic Jacobian, IC calc,
//!   root finding, and the Krylov method with and without a preconditioner).
//!
//! The crate is pure Rust with no allocation and no I/O on the numerical hot
//! path. It builds `no_std` (default feature `std` off) so the wasm-jit runtime
//! can compile it into the in-wasm simulation driver; the transcendental float
//! ops then route through `libm` instead of the platform math library.

#![cfg_attr(not(feature = "std"), no_std)]

pub mod auxiliary;
pub mod linpack;
pub mod solver;

// `no_std` builds lack the inherent `f64::{sqrt,powf}` (they lower to the
// platform libm); provide them via `libm`. `abs`/`max`/`min` are in `core`, so
// they need no shim. Not compiled for `std`, which keeps the native/`cref` build
// bit-identical to before.
#[cfg(not(feature = "std"))]
pub(crate) use float_shim::FloatShim;
#[cfg(not(feature = "std"))]
mod float_shim {
    pub(crate) trait FloatShim {
        fn sqrt(self) -> Self;
        fn powf(self, n: Self) -> Self;
    }
    impl FloatShim for f64 {
        #[inline]
        fn sqrt(self) -> Self {
            libm::sqrt(self)
        }
        #[inline]
        fn powf(self, n: Self) -> Self {
            libm::pow(self, n)
        }
    }
}
