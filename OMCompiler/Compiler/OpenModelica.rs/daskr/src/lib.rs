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
//! * [`aux`] — machine constants and the error-message helpers (`daux.c`).
//! * [`solver`] — the core integrator (`ddaskr.c`): the BDF predictor/corrector,
//!   initial-condition solver, root finder, and the Krylov (SPIGMR) linear
//!   solver. All paths are cross-checked bit-for-bit against the C in
//!   `tests/solver_cref.rs` (direct dense/banded, analytic Jacobian, IC calc,
//!   root finding, and the Krylov method with and without a preconditioner).
//!
//! The crate is pure Rust with no I/O on the numerical hot path, so it
//! cross-compiles to `wasm32` with no extra toolchain.

pub mod aux;
pub mod linpack;
pub mod solver;
