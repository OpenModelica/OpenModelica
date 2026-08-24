//! LAPACK for the targets that have no LAPACK to link against: the in-wasm
//! `wasm-jit` runtime (a wasm FMU or a browser simulation calling
//! `Modelica.Math.Matrices.LAPACK.*`, which is `external "FORTRAN 77"`) and omc
//! itself, whose `openmodelica_util::Lapack` binds these symbols in place of the
//! system LAPACK on every target.
//!
//! # Conventions
//!
//! Every routine takes the same arguments as its LAPACK counterpart, in the same
//! order, with the same semantics: matrices are **column-major** with an explicit
//! leading dimension, `IPIV`/`JPVT` are 1-based, and `INFO` follows LAPACK (`0`
//! success, `-i` bad argument `i`, `> 0` routine-specific). Slices replace the
//! pointer+dimension pairs where the dimension is implied, but a leading
//! dimension is always explicit because the caller's buffer may be larger than
//! the matrix.
//!
//! `WORK`/`LWORK` do not appear: allocation is this crate's business, so an
//! `LWORK = -1` workspace query has no counterpart. The Fortran-ABI layer
//! ([`fortran`]) accepts and ignores them, answering a query with the size the
//! reference implementation would report.
//!
//! # Where each routine comes from
//!
//! The LU, Cholesky and QR families are implemented here, so their factored
//! output (packed `L\U`, `IPIV`, `TAU`) is what LAPACK's unblocked kernels
//! produce and a caller may read the raw factors — which
//! `Modelica.Math.Matrices.LU` does. Just as importantly, a singular matrix
//! yields `INFO > 0` *together with* the factors, which `rcond` relies on.
//!
//! # License
//!
//! Routines here that reproduce a reference LAPACK kernel step for step carry
//! LAPACK's copyright and license, reproduced in `LICENSE-LAPACK` at the crate
//! root; [`hqr`] names the files it was translated from.
//!
//! The SVD comes from `oxiblas-lapack`, whose kernels use wasm32 `simd128`. The
//! eigenvalue path is ported instead ([`hqr`], [`trevc`]): the order `DGEEV`
//! returns eigenvalues in, and which of a conjugate pair's two equivalent
//! eigenvector representations comes back, are decided by the algorithm, and a
//! model reads both.

#![allow(non_snake_case)]
pub mod band;
pub mod blas;
pub mod chol;
pub mod eig;
#[cfg(feature = "fortran-abi")]
pub mod fortran;
pub mod gev;
pub mod hqr;
pub mod lu;
pub mod parallel;
pub mod qr;
pub mod rz;
#[cfg(feature = "decompositions")]
pub mod svd;
pub mod trevc;

pub use band::{dgbsv, dgtsv};
pub use chol::{dpotrf, dpotrs};
pub use eig::{dgees, dgeev, dgehrd, dhseqr, dorghr, dtrsyl};
pub use gev::dgegv;
pub use lu::{dgecon, dgesv, dgesvx, dgetrf, dgetri, dgetrs, dlange};
pub use qr::{dgels, dgelsx, dgelsy, dgeqp3, dgeqpf, dgeqrf, dgglse, dorgqr, dormqr};
#[cfg(feature = "decompositions")]
pub use svd::{dgesdd, dgesvd};

#[cfg(feature = "decompositions")]
use oxiblas_matrix::Mat;

/// The uppercase first byte of a LAPACK character argument (`"N"`,
/// `"Transpose"`, … — Fortran compares only the first character, case
/// insensitively).
pub(crate) fn opt(s: &str) -> u8 {
    s.as_bytes().first().copied().unwrap_or(b' ').to_ascii_uppercase()
}

/// An `r`×`c` matrix filled from `f(row, col)`. `oxiblas_matrix::Mat` offers only
/// `zeros` and `from_rows`.
#[cfg(feature = "decompositions")]
pub(crate) fn mat_from_fn(r: usize, c: usize, mut f: impl FnMut(usize, usize) -> f64) -> Mat<f64> {
    let mut out: Mat<f64> = Mat::zeros(r, c);
    for j in 0..c {
        for i in 0..r {
            out[(i, j)] = f(i, j);
        }
    }
    out
}

/// A column-major `m`×`n` view of `a` (leading dimension `lda`) copied into a
/// packed oxiblas matrix.
#[cfg(feature = "decompositions")]
pub(crate) fn to_mat(m: usize, n: usize, a: &[f64], lda: usize) -> Mat<f64> {
    let mut out: Mat<f64> = Mat::zeros(m, n);
    for j in 0..n {
        for i in 0..m {
            out[(i, j)] = a[i + j * lda];
        }
    }
    out
}

/// Write an `m`×`n` oxiblas matrix back into a column-major buffer with leading
/// dimension `lda`.
#[cfg(feature = "decompositions")]
pub(crate) fn from_mat(dst: &mut [f64], lda: usize, src: &Mat<f64>) {
    for j in 0..src.ncols() {
        for i in 0..src.nrows() {
            dst[i + j * lda] = src[(i, j)];
        }
    }
}

/// A packed `m`×`n` column-major copy of a strided matrix.
pub(crate) fn pack(m: usize, n: usize, a: &[f64], lda: usize) -> Vec<f64> {
    let mut out = vec![0.0f64; m * n];
    for j in 0..n {
        out[j * m..j * m + m].copy_from_slice(&a[j * lda..j * lda + m]);
    }
    out
}

/// `DLAMCH('S')`: the smallest number whose reciprocal does not overflow, the
/// threshold Householder generation and the norm routines guard with.
pub(crate) const SAFMIN: f64 = 2.2250738585072014e-308;
/// `DLAMCH('E')`, the relative machine epsilon — half of `f64::EPSILON`, which is
/// LAPACK's `DLAMCH('P')`.
pub(crate) const EPS: f64 = f64::EPSILON / 2.0;

pub(crate) fn abs(x: f64) -> f64 {
    libm::fabs(x)
}

pub(crate) fn hypot(x: f64, y: f64) -> f64 {
    libm::hypot(x, y)
}

pub(crate) fn sqrt(x: f64) -> f64 {
    libm::sqrt(x)
}
