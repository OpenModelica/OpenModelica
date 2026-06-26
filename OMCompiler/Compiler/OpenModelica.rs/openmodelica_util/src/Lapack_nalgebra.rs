//! wasm implementation of [`crate::Lapack`]. The native module binds the system
//! LAPACK/BLAS via FFI; wasm has no LAPACK to link, so the LAPACK builtins
//! (reached from CevalFunction for compile-time `Modelica.Math.Matrices.*`
//! evaluation) are implemented over **nalgebra**'s pure-Rust decompositions.
//!
//! Implemented: the dense linear-solve / inverse / determinant family
//! (`dgesv`/`dgetrf`/`dgetrs`/`dgetri`), the SVD (`dgesvd`), least squares
//! (`dgels`) and eigenvalues (`dgeev`, values only). The generalized
//! eigenproblem, QR-with-column-pivoting, constrained least squares and the
//! banded/tridiagonal solvers have no direct nalgebra counterpart and `todo!()`.
//!
//! Caveat: `dgetrf` returns the *original* matrix in the factored-A slot (not
//! LAPACK's packed L\\U) and an identity pivot vector — `dgetrs`/`dgetri`
//! re-factor it with nalgebra, so solve/inverse/determinant are correct; only a
//! direct read of the raw LU factors (rare) would differ from native LAPACK.
#![allow(non_snake_case)]

use std::sync::Arc;

use arcstr::ArcStr;

use metamodelica::{List, OrderedFloat, Real};
use nalgebra::DMatrix;

type Mat = Arc<List<Arc<List<Real>>>>;
type Vec64 = Arc<List<Real>>;
type IVec = Arc<List<i32>>;

/// Read an `r`×`c` `list<list<Real>>` into a `nalgebra::DMatrix`.
fn dm_in(r: i32, c: i32, data: &Mat) -> DMatrix<f64> {
    let (r, c) = (r.max(0) as usize, c.max(0) as usize);
    let mut m = DMatrix::<f64>::zeros(r, c);
    for (i, row) in (&**data).into_iter().enumerate() {
        if i >= r { break; }
        for (j, v) in (&**row).into_iter().enumerate() {
            if j >= c { break; }
            m[(i, j)] = v.0;
        }
    }
    m
}

/// Build an `r`×`c` `list<list<Real>>` from a `DMatrix` (zero-padded/truncated
/// to the requested shape).
fn dm_out(r: i32, c: i32, m: &DMatrix<f64>) -> Mat {
    let (r, c) = (r.max(0) as usize, c.max(0) as usize);
    Arc::new(List::from_iter((0..r).map(|i| {
        Arc::new(List::from_iter((0..c).map(|j| {
            OrderedFloat(if i < m.nrows() && j < m.ncols() { m[(i, j)] } else { 0.0 })
        })))
    })))
}

fn vec_out(n: i32, v: &[f64]) -> Vec64 {
    let len = n.max(0) as usize;
    Arc::new(List::from_iter((0..len).map(|i| OrderedFloat(v.get(i).copied().unwrap_or(0.0)))))
}

fn identity_ipiv(n: i32) -> IVec {
    Arc::new(List::from_iter(1..=n.max(0)))
}

fn first_char(s: &ArcStr) -> u8 {
    s.as_bytes().first().copied().unwrap_or(b' ').to_ascii_uppercase()
}

// ─────────────────────── dense LU: solve / factor / inverse ──────────────────

/// Solve `A*X = B` for a general N×N system (LAPACK `dgesv`). nalgebra's
/// partial-pivot LU does the factor+solve; the solution goes into B's slot. The
/// factored-A slot returns the original A and the pivots an identity vector
/// (see the module caveat); INFO is `0` (solution) or `1` (singular).
pub fn dgesv(inN: i32, inNRHS: i32, inA: Mat, inLDA: i32, inB: Mat, inLDB: i32) -> (Mat, IVec, Mat, i32) {
    let a = dm_in(inN, inN, &inA);
    let b = dm_in(inN, inNRHS, &inB);
    match a.clone().lu().solve(&b) {
        Some(x) => (dm_out(inLDA, inN, &a), identity_ipiv(inN), dm_out(inLDB, inNRHS, &x), 0),
        None => (dm_out(inLDA, inN, &a), identity_ipiv(inN), dm_out(inLDB, inNRHS, &b), 1),
    }
}

/// LU factorization of a square matrix (LAPACK `dgetrf`). Returns the original
/// matrix (re-factored by dgetrs/dgetri) + an identity pivot vector; INFO is `0`
/// unless the matrix is singular. See the module caveat.
pub fn dgetrf(inM: i32, inN: i32, inA: Mat, inLDA: i32) -> (Mat, IVec, i32) {
    if inM != inN {
        todo!("Lapack.dgetrf: rectangular LU (M != N) is not implemented on wasm");
    }
    let a = dm_in(inN, inN, &inA);
    let n = inN.max(0) as usize;
    let info = if a.clone().lu().solve(&DMatrix::identity(n, n)).is_some() { 0 } else { 1 };
    (dm_out(inLDA, inN, &a), identity_ipiv(inN), info)
}

/// Solve a factored system (LAPACK `dgetrs`): `A*X=B` for TRANS="N" else
/// `A'*X=B`. `inA` is dgetrf's output (the original A here), re-factored.
pub fn dgetrs(inTRANS: ArcStr, inN: i32, inNRHS: i32, inA: Mat, _inLDA: i32, _inIPIV: IVec, inB: Mat, inLDB: i32) -> (Mat, i32) {
    let mut a = dm_in(inN, inN, &inA);
    if first_char(&inTRANS) != b'N' {
        a.transpose_mut();
    }
    let b = dm_in(inN, inNRHS, &inB);
    match a.lu().solve(&b) {
        Some(x) => (dm_out(inLDB, inNRHS, &x), 0),
        None => (dm_out(inLDB, inNRHS, &b), 1),
    }
}

/// Inverse of a factored matrix (LAPACK `dgetri`). `inA` is dgetrf's output (the
/// original A here); nalgebra inverts it directly.
pub fn dgetri(inN: i32, inA: Mat, inLDA: i32, _inIPIV: IVec, inWORK: Vec64, _inLWORK: i32) -> (Mat, Vec64, i32) {
    let a = dm_in(inN, inN, &inA);
    let n = inN.max(0) as usize;
    match a.try_inverse() {
        Some(inv) => (dm_out(inLDA, inN, &inv), inWORK, 0),
        None => (dm_out(inLDA, inN, &DMatrix::zeros(n, n)), inWORK, 1),
    }
}

// ─────────────────────────────── SVD ─────────────────────────────────────────

/// Singular value decomposition `A = U·Σ·Vᵀ` (LAPACK `dgesvd`). Returns U, the
/// singular values, V and Vᵀ, an empty work vector and INFO.
pub fn dgesvd(
    inJOBU: ArcStr,
    inJOBVT: ArcStr,
    inM: i32,
    inN: i32,
    inA: Mat,
    _inLDA: i32,
    inLDU: i32,
    inLDVT: i32,
    _inWORK: Vec64,
    _inLWORK: i32,
) -> (Mat, Vec64, Mat, Mat, Vec64, i32) {
    let _ = (&inJOBU, &inJOBVT);
    let a = dm_in(inM, inN, &inA);
    let svd = a.svd(true, true);
    let s: Vec<f64> = svd.singular_values.iter().copied().collect();
    let u = svd.u.unwrap_or_else(|| DMatrix::identity(inM.max(0) as usize, inM.max(0) as usize));
    let vt = svd.v_t.unwrap_or_else(|| DMatrix::identity(inN.max(0) as usize, inN.max(0) as usize));
    let v = vt.transpose();
    (dm_out(inLDU, inM, &u), vec_out(inN.min(inM), &s), dm_out(inLDVT, inN, &vt), dm_out(inN, inN, &v), empty_vec(), 0)
}

// ───────────────────────────── least squares ─────────────────────────────────

/// Minimum-norm least-squares solution of `A·X ≈ B` (LAPACK `dgels`), via the
/// SVD pseudo-inverse (coincides with the full-rank `dgels` solution).
pub fn dgels(
    _inTRANS: ArcStr,
    inM: i32,
    inN: i32,
    inNRHS: i32,
    inA: Mat,
    inLDA: i32,
    inB: Mat,
    inLDB: i32,
    _inWORK: Vec64,
    _inLWORK: i32,
) -> (Mat, Mat, Vec64, i32) {
    let a = dm_in(inM, inN, &inA);
    let b = dm_in(inM, inNRHS, &inB);
    let x = a
        .clone()
        .svd(true, true)
        .solve(&b, 1e-12)
        .unwrap_or_else(|_| DMatrix::zeros(inN.max(0) as usize, inNRHS.max(0) as usize));
    (dm_out(inLDA, inN, &a), dm_out(inLDB.max(inN), inNRHS, &x), empty_vec(), 0)
}

// ───────────────────────────── eigenvalues ───────────────────────────────────

/// Eigenvalues of a general real N×N matrix (LAPACK `dgeev`), returned as the
/// real (WR) and imaginary (WI) parts. Eigenvector computation (JOBVL/JOBVR =
/// "V") is not yet implemented.
pub fn dgeev(
    inJOBVL: ArcStr,
    inJOBVR: ArcStr,
    inN: i32,
    inA: Mat,
    inLDA: i32,
    inLDVL: i32,
    inLDVR: i32,
    inWORK: Vec64,
    _inLWORK: i32,
) -> (Mat, Vec64, Vec64, Mat, Mat, Vec64, i32) {
    if first_char(&inJOBVL) == b'V' || first_char(&inJOBVR) == b'V' {
        todo!("Lapack.dgeev: eigenvector computation (JOBVL/JOBVR = \"V\") is not implemented on wasm");
    }
    let a = dm_in(inN, inN, &inA);
    let eig = a.complex_eigenvalues();
    let wr: Vec<f64> = eig.iter().map(|c| c.re).collect();
    let wi: Vec<f64> = eig.iter().map(|c| c.im).collect();
    let empty = DMatrix::<f64>::zeros(0, 0);
    (
        dm_out(inLDA, inN, &dm_in(inN, inN, &inA)),
        vec_out(inN, &wr),
        vec_out(inN, &wi),
        dm_out(inLDVL, inN, &empty),
        dm_out(inLDVR, inN, &empty),
        inWORK,
        0,
    )
}

fn empty_vec() -> Vec64 {
    metamodelica::nil()
}

// ───────────── not implemented on wasm (no direct nalgebra counterpart) ───────

pub fn dgegv(
    _inJOBVL: ArcStr,
    _inJOBVR: ArcStr,
    _inN: i32,
    _inA: Mat,
    _inLDA: i32,
    _inB: Mat,
    _inLDB: i32,
    _inLDVL: i32,
    _inLDVR: i32,
    _inWORK: Vec64,
    _inLWORK: i32,
) -> (Vec64, Vec64, Vec64, Mat, Mat, Vec64, i32) {
    todo!("Lapack.dgegv: the generalized eigenproblem is not available on wasm (no nalgebra counterpart)")
}

pub fn dgelsx(
    _inM: i32,
    _inN: i32,
    _inNRHS: i32,
    _inA: Mat,
    _inLDA: i32,
    _inB: Mat,
    _inLDB: i32,
    _inJPVT: IVec,
    _inRCOND: Real,
    _inWORK: Vec64,
) -> (Mat, Mat, IVec, i32, i32) {
    todo!("Lapack.dgelsx: column-pivoted least squares is not implemented on wasm (use dgels)")
}

pub fn dgelsy(
    _inM: i32,
    _inN: i32,
    _inNRHS: i32,
    _inA: Mat,
    _inLDA: i32,
    _inB: Mat,
    _inLDB: i32,
    _inJPVT: IVec,
    _inRCOND: Real,
    _inWORK: Vec64,
    _inLWORK: i32,
) -> (Mat, Mat, IVec, i32, Vec64, i32) {
    todo!("Lapack.dgelsy: column-pivoted least squares is not implemented on wasm (use dgels)")
}

pub fn dgglse(
    _inM: i32,
    _inN: i32,
    _inP: i32,
    _inA: Mat,
    _inLDA: i32,
    _inB: Mat,
    _inLDB: i32,
    _inC: Vec64,
    _inD: Vec64,
    _inWORK: Vec64,
    _inLWORK: i32,
) -> (Mat, Mat, Vec64, Vec64, Vec64, Vec64, i32) {
    todo!("Lapack.dgglse: equality-constrained least squares is not implemented on wasm")
}

pub fn dgtsv(
    _inN: i32,
    _inNRHS: i32,
    _inDL: Vec64,
    _inD: Vec64,
    _inDU: Vec64,
    _inB: Mat,
    _inLDB: i32,
) -> (Vec64, Vec64, Vec64, Mat, i32) {
    todo!("Lapack.dgtsv: tridiagonal solve is not implemented on wasm (assemble a dense system and use dgesv)")
}

pub fn dgbsv(
    _inN: i32,
    _inKL: i32,
    _inKU: i32,
    _inNRHS: i32,
    _inAB: Mat,
    _inLDAB: i32,
    _inB: Mat,
    _inLDB: i32,
) -> (Mat, IVec, Mat, i32) {
    todo!("Lapack.dgbsv: banded solve is not implemented on wasm (assemble a dense system and use dgesv)")
}

pub fn dgeqpf(
    _inM: i32,
    _inN: i32,
    _inA: Mat,
    _inLDA: i32,
    _inJPVT: IVec,
    _inWORK: Vec64,
) -> (Mat, IVec, Vec64, i32) {
    todo!("Lapack.dgeqpf: column-pivoted QR is not implemented on wasm")
}

pub fn dorgqr(
    _inM: i32,
    _inN: i32,
    _inK: i32,
    _inA: Mat,
    _inLDA: i32,
    _inTAU: Vec64,
    _inWORK: Vec64,
    _inLWORK: i32,
) -> (Mat, Vec64, i32) {
    todo!("Lapack.dorgqr: forming Q from a QR factorization is not implemented on wasm")
}

pub fn dhseqr(
    _inJOB: ArcStr,
    _inCOMPZ: ArcStr,
    _inN: i32,
    _inILO: i32,
    _inIHI: i32,
    _inH: Mat,
    _inLDH: i32,
    _inZ: Mat,
    _inLDZ: i32,
    _inWORK: Vec64,
    _inLWORK: i32,
) -> (Mat, Vec64, Vec64, Mat, Vec64, i32) {
    todo!("Lapack.dhseqr: the Schur/Hessenberg eigenvalue routine is not implemented on wasm")
}
