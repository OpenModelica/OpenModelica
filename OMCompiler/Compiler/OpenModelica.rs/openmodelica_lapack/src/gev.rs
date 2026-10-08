//! The generalized eigenproblem `A*x = λ*B*x`: `DGGEV` and the deprecated
//! `DGEGV`.
//!
//! With `faer-backend` both are a real QZ, so a singular `B` gives the `β = 0`
//! infinite eigenvalues LAPACK reports and the eigenvectors are available.
//! Without it there is no QZ here: the fallback reduces to `B⁻¹A`, which needs a
//! nonsingular `B` and cannot produce left eigenvectors.

use crate::{abs, opt, pack};

/// `DGEGV`: the generalized eigenvalues of `(A, B)` as
/// `(ALPHAR + i*ALPHAI) / BETA`, always with `BETA = 1` (see the module note).
///
/// `INFO = n+1` when `B` is singular or too ill-conditioned for `B⁻¹A`.
/// `jobvl`/`jobvr` must be `"N"`; `"V"` returns `-1`/`-2`, the argument position.
#[allow(clippy::too_many_arguments)]
pub fn dgegv(
    jobvl: &str,
    jobvr: &str,
    n: usize,
    a: &[f64],
    lda: usize,
    b: &[f64],
    ldb: usize,
    alphar: &mut [f64],
    alphai: &mut [f64],
    beta: &mut [f64],
) -> i32 {
    #[cfg(feature = "faer-backend")]
    return crate::faer_backend::dggev(
        jobvl, jobvr, n, a, lda, b, ldb, alphar, alphai, beta, &mut [], 1, &mut [], 1,
    );
    #[cfg(not(feature = "faer-backend"))]
    dgegv_ref(jobvl, jobvr, n, a, lda, b, ldb, alphar, alphai, beta)
}

/// `DGGEV`: the generalized eigenvalues of `(A, B)` and, for `jobvl`/`jobvr` of
/// `"V"`, the left and right eigenvectors. Needs `faer-backend`; without it
/// there is no QZ and only the eigenvalues of a nonsingular pencil can be had,
/// so `"V"` reports the argument position as LAPACK does for a bad option.
#[allow(clippy::too_many_arguments)]
pub fn dggev(
    jobvl: &str,
    jobvr: &str,
    n: usize,
    a: &[f64],
    lda: usize,
    b: &[f64],
    ldb: usize,
    alphar: &mut [f64],
    alphai: &mut [f64],
    beta: &mut [f64],
    vl: &mut [f64],
    ldvl: usize,
    vr: &mut [f64],
    ldvr: usize,
) -> i32 {
    #[cfg(feature = "faer-backend")]
    return crate::faer_backend::dggev(
        jobvl, jobvr, n, a, lda, b, ldb, alphar, alphai, beta, vl, ldvl, vr, ldvr,
    );
    #[cfg(not(feature = "faer-backend"))]
    {
        let _ = (vl, ldvl, vr, ldvr);
        dgegv_ref(jobvl, jobvr, n, a, lda, b, ldb, alphar, alphai, beta)
    }
}

/// The `B⁻¹A` reduction, kept as the fallback when faer is not linked.
#[allow(clippy::too_many_arguments)]
pub fn dgegv_ref(
    jobvl: &str,
    jobvr: &str,
    n: usize,
    a: &[f64],
    lda: usize,
    b: &[f64],
    ldb: usize,
    alphar: &mut [f64],
    alphai: &mut [f64],
    beta: &mut [f64],
) -> i32 {
    if opt(jobvl) == b'V' {
        return -1;
    }
    if opt(jobvr) == b'V' {
        return -2;
    }
    if n == 0 {
        return 0;
    }
    let mut lu = pack(n, n, b, ldb);
    let mut ipiv = vec![0i32; n];
    if crate::lu::dgetrf(n, n, &mut lu, n, &mut ipiv) != 0 {
        return (n + 1) as i32;
    }
    let bnorm = crate::lu::dlange("1", n, n, b, ldb);
    let (rcond, _) = crate::lu::dgecon("1", n, &lu, n, bnorm);
    if !(rcond > crate::EPS * n as f64) {
        return (n + 1) as i32;
    }
    // C = B⁻¹A, whose eigenvalues are the pencil's.
    let mut c = pack(n, n, a, lda);
    if crate::lu::dgetrs("N", n, n, &lu, n, &ipiv, &mut c, n) != 0 {
        return (n + 1) as i32;
    }
    let info = crate::eig::dgeev("N", "N", n, &c, n, alphar, alphai, &mut [], 1, &mut [], 1);
    if info != 0 {
        return info;
    }
    // LAPACK scales the triple to O(1); with BETA = 1 that means dividing through
    // by the largest of the three, which leaves the ratio alone.
    for k in 0..n {
        let scale = abs(alphar[k]).max(abs(alphai[k])).max(1.0);
        alphar[k] /= scale;
        alphai[k] /= scale;
        beta[k] = 1.0 / scale;
    }
    0
}
