//! Cholesky factorization: `DPOTRF` and `DPOTRS`.

use crate::blas::{at, set};
use crate::{opt, sqrt};

/// `A = U'*U` (`uplo = "U"`) or `A = L*L'` (`uplo = "L"`) for a symmetric
/// positive definite `A` (`DPOTRF`). Only the named triangle is read and written;
/// the other is left untouched, as LAPACK leaves it. Returns `INFO`: `i > 0` when
/// the leading `i`×`i` minor is not positive definite.
pub fn dpotrf(uplo: &str, n: usize, a: &mut [f64], lda: usize) -> i32 {
    #[cfg(feature = "faer-backend")]
    return crate::faer_backend::dpotrf(uplo, n, a, lda);
    #[cfg(not(feature = "faer-backend"))]
    dpotrf_ref(uplo, n, a, lda)
}

/// The port of `DPOTRF`, kept as the faer-free fallback.
pub fn dpotrf_ref(uplo: &str, n: usize, a: &mut [f64], lda: usize) -> i32 {
    let upper = opt(uplo) == b'U';
    for j in 0..n {
        let mut ajj = at(a, lda, j, j);
        for k in 0..j {
            let v = if upper { at(a, lda, k, j) } else { at(a, lda, j, k) };
            ajj -= v * v;
        }
        if !(ajj > 0.0) {
            set(a, lda, j, j, ajj);
            return (j + 1) as i32;
        }
        let ajj = sqrt(ajj);
        set(a, lda, j, j, ajj);
        for i in j + 1..n {
            let mut s = if upper { at(a, lda, j, i) } else { at(a, lda, i, j) };
            for k in 0..j {
                let (l, r) = if upper {
                    (at(a, lda, k, j), at(a, lda, k, i))
                } else {
                    (at(a, lda, j, k), at(a, lda, i, k))
                };
                s -= l * r;
            }
            let v = s / ajj;
            if upper {
                set(a, lda, j, i, v);
            } else {
                set(a, lda, i, j, v);
            }
        }
    }
    0
}

/// Solve `A*X = B` from a `dpotrf` factorization (`DPOTRS`).
#[allow(clippy::too_many_arguments)]
pub fn dpotrs(
    uplo: &str,
    n: usize,
    nrhs: usize,
    a: &[f64],
    lda: usize,
    b: &mut [f64],
    ldb: usize,
) -> i32 {
    #[cfg(feature = "faer-backend")]
    return crate::faer_backend::dpotrs(uplo, n, nrhs, a, lda, b, ldb);
    #[cfg(not(feature = "faer-backend"))]
    dpotrs_ref(uplo, n, nrhs, a, lda, b, ldb)
}

/// The port of `DPOTRS`, kept as the faer-free fallback.
#[allow(clippy::too_many_arguments)]
pub fn dpotrs_ref(
    uplo: &str,
    n: usize,
    nrhs: usize,
    a: &[f64],
    lda: usize,
    b: &mut [f64],
    ldb: usize,
) -> i32 {
    if opt(uplo) == b'U' {
        crate::blas::dtrsm("L", "U", "T", "N", n, nrhs, 1.0, a, lda, b, ldb);
        crate::blas::dtrsm("L", "U", "N", "N", n, nrhs, 1.0, a, lda, b, ldb);
    } else {
        crate::blas::dtrsm("L", "L", "N", "N", n, nrhs, 1.0, a, lda, b, ldb);
        crate::blas::dtrsm("L", "L", "T", "N", n, nrhs, 1.0, a, lda, b, ldb);
    }
    0
}
