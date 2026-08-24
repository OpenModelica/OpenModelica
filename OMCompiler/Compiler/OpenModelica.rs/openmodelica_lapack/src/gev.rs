//! The generalized eigenproblem `A*x = λ*B*x`: `DGEGV`.
//!
//! **A nonsingular `B` only**, unlike LAPACK: the general case needs a QZ
//! factorization, which nothing here has — oxiblas's does not converge on most
//! pencils. So this reduces to `B⁻¹A` and returns `INFO > 0` where LAPACK would
//! report a `β = 0` infinite eigenvalue. MSL 3.2.3 declares `dgegv` but never
//! calls it, and MSL 4 dropped it.

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
