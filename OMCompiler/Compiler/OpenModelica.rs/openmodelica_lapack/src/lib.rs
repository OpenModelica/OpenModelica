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
//! The LU, Cholesky and QR families are written against LAPACK's unblocked
//! kernels, so their factored output (packed `L\U`, `IPIV`, `TAU`) is what a
//! caller reading the raw factors expects — which `Modelica.Math.Matrices.LU`
//! does — and a singular matrix yields `INFO > 0` *together with* the factors,
//! which `rcond` relies on.
//!
//! The SVD ([`bidiag`], [`bdsqr`], [`dqds`], [`svd`]) and the eigenvalue path
//! ([`hqr`], [`trevc`]) are translated from the reference Fortran. For the
//! eigenvalue path that is load-bearing: the order `DGEEV` returns eigenvalues
//! in, and which of a conjugate pair's two equivalent eigenvector
//! representations comes back, are decided by the algorithm, and a model reads
//! both.
//!
//! # License
//!
//! Routines here that reproduce a reference LAPACK kernel step for step carry
//! LAPACK's copyright and license, reproduced in `LICENSE-LAPACK` at the crate
//! root; each module names the routines it was translated from.

#![allow(non_snake_case)]
pub mod band;
pub mod bdsqr;
pub mod bidiag;
pub mod blas;
pub mod chol;
pub mod dqds;
pub mod eig;
#[cfg(feature = "fortran-abi")]
pub mod fortran;
pub mod gev;
pub mod hqr;
pub mod lu;
#[cfg(feature = "faer-backend")]
pub mod faer_backend;
#[cfg(feature = "faer-backend")]
mod faer_real_schur;
pub mod qr;
pub mod rand;
pub mod rz;
pub mod svd;
pub mod syev;
pub mod trevc;

pub use band::{dgbsv, dgtsv};
pub use bdsqr::dbdsqr;
pub use chol::{dpotrf, dpotrs};
pub use eig::{dgees, dgeev, dgehrd, dhseqr, dorghr, dtrsyl};
pub use gev::dgegv;
pub use lu::{dgecon, dgesv, dgesvx, dgetrf, dgetri, dgetrs, dlange};
pub use qr::{dgels, dgelsx, dgelsy, dgeqp3, dgeqpf, dgeqrf, dgglse, dorgqr, dormqr};
pub use svd::{dgesdd, dgesvd};

/// The uppercase first byte of a LAPACK character argument (`"N"`,
/// `"Transpose"`, … — Fortran compares only the first character, case
/// insensitively).
pub(crate) fn opt(s: &str) -> u8 {
    s.as_bytes().first().copied().unwrap_or(b' ').to_ascii_uppercase()
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
/// `DLAMCH('E')`, the relative machine epsilon.
pub(crate) const EPS: f64 = f64::EPSILON / 2.0;
/// `DLAMCH('P')`, the unit in the last place — `EPS` times the radix.
pub(crate) const PREC: f64 = f64::EPSILON;

/// `DLACPY`: copy an `m`×`n` matrix, or its `b'L'`/`b'U'` triangle, into another
/// with its own leading dimension.
#[allow(clippy::too_many_arguments)]
pub(crate) fn dlacpy(uplo: u8, m: usize, n: usize, a: &[f64], lda: usize, b: &mut [f64], ldb: usize) {
    for j in 0..n {
        let rows = match uplo {
            b'L' => j..m,
            b'U' => 0..(j + 1).min(m),
            _ => 0..m,
        };
        for i in rows {
            b[i + j * ldb] = a[i + j * lda];
        }
    }
}

pub(crate) fn abs(x: f64) -> f64 {
    libm::fabs(x)
}

pub(crate) fn hypot(x: f64, y: f64) -> f64 {
    libm::hypot(x, y)
}

pub(crate) fn sqrt(x: f64) -> f64 {
    libm::sqrt(x)
}
