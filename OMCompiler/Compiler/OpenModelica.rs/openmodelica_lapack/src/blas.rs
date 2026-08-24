//! The BLAS kernels the factorizations here are written on, plus the two
//! (`dtrsm`, `dnrm2`) that `Modelica.Math.Matrices` reaches directly.

use crate::{abs, opt, sqrt, SAFMIN};

/// Index of the first element of largest magnitude (0-based; `x` is contiguous).
/// `IDAMAX` returns the *first* maximum, which is what makes LU pivoting
/// reproducible.
pub fn idamax(x: &[f64]) -> usize {
    let mut k = 0;
    let mut best = -1.0;
    for (i, v) in x.iter().enumerate() {
        let a = abs(*v);
        if a > best {
            best = a;
            k = i;
        }
    }
    k
}

/// Euclidean norm, scaled so that squaring cannot overflow or flush to zero.
pub fn dnrm2(x: &[f64]) -> f64 {
    let mut scale = 0.0f64;
    let mut ssq = 1.0f64;
    for v in x {
        if *v == 0.0 {
            continue;
        }
        let a = abs(*v);
        if scale < a {
            let r = scale / a;
            ssq = 1.0 + ssq * r * r;
            scale = a;
        } else {
            let r = a / scale;
            ssq += r * r;
        }
    }
    scale * sqrt(ssq)
}

/// `y += alpha * x`.
pub fn daxpy(alpha: f64, x: &[f64], y: &mut [f64]) {
    if alpha == 0.0 {
        return;
    }
    for (yi, xi) in y.iter_mut().zip(x) {
        *yi += alpha * xi;
    }
}

pub fn ddot(x: &[f64], y: &[f64]) -> f64 {
    x.iter().zip(y).map(|(a, b)| a * b).sum()
}

pub fn dscal(alpha: f64, x: &mut [f64]) {
    for v in x {
        *v *= alpha;
    }
}

/// Column-major element access helper: `a[i + j*lda]`.
#[inline]
pub(crate) fn at(a: &[f64], lda: usize, i: usize, j: usize) -> f64 {
    a[i + j * lda]
}

#[inline]
pub(crate) fn set(a: &mut [f64], lda: usize, i: usize, j: usize, v: f64) {
    a[i + j * lda] = v;
}

/// Swap rows `r1` and `r2` over columns `cols`.
pub(crate) fn swap_rows(a: &mut [f64], lda: usize, cols: core::ops::Range<usize>, r1: usize, r2: usize) {
    if r1 == r2 {
        return;
    }
    for j in cols {
        a.swap(r1 + j * lda, r2 + j * lda);
    }
}

/// `B := alpha * op(A)^{-1} * B` (`side = 'L'`) or `B := alpha * B * op(A)^{-1}`
/// (`side = 'R'`), with `A` triangular. `uplo` `'U'`/`'L'`, `transa` `'N'`/`'T'`,
/// `diag` `'U'` (unit) / `'N'`.
#[allow(clippy::too_many_arguments)]
pub fn dtrsm(
    side: &str,
    uplo: &str,
    transa: &str,
    diag: &str,
    m: usize,
    n: usize,
    alpha: f64,
    a: &[f64],
    lda: usize,
    b: &mut [f64],
    ldb: usize,
) {
    #[cfg(feature = "faer-backend")]
    return crate::faer_backend::dtrsm(side, uplo, transa, diag, m, n, alpha, a, lda, b, ldb);
    #[cfg(not(feature = "faer-backend"))]
    dtrsm_ref(side, uplo, transa, diag, m, n, alpha, a, lda, b, ldb)
}

/// The port of `DTRSM`, kept as the faer-free fallback.
#[allow(clippy::too_many_arguments)]
pub fn dtrsm_ref(
    side: &str,
    uplo: &str,
    transa: &str,
    diag: &str,
    m: usize,
    n: usize,
    alpha: f64,
    a: &[f64],
    lda: usize,
    b: &mut [f64],
    ldb: usize,
) {
    let left = opt(side) == b'L';
    let upper = opt(uplo) == b'U';
    let trans = opt(transa) != b'N';
    let unit = opt(diag) == b'U';
    if alpha != 1.0 {
        for j in 0..n {
            dscal(alpha, &mut b[j * ldb..j * ldb + m]);
        }
    }
    if alpha == 0.0 {
        return;
    }
    // The triangle actually solved against: transposing swaps upper for lower.
    let lower = upper == trans;
    // op(A)[i,k].
    let opa = |i: usize, k: usize| if trans { at(a, lda, k, i) } else { at(a, lda, i, k) };
    if left {
        for j in 0..n {
            for step in 0..m {
                // Forward substitution over a lower triangle, back substitution
                // over an upper one.
                let i = if lower { step } else { m - 1 - step };
                let mut s = at(b, ldb, i, j);
                if lower {
                    for k in 0..i {
                        s -= opa(i, k) * at(b, ldb, k, j);
                    }
                } else {
                    for k in i + 1..m {
                        s -= opa(i, k) * at(b, ldb, k, j);
                    }
                }
                if !unit {
                    s /= opa(i, i);
                }
                set(b, ldb, i, j, s);
            }
        }
    } else {
        for step in 0..n {
            let j = if lower { n - 1 - step } else { step };
            for i in 0..m {
                let mut s = at(b, ldb, i, j);
                if lower {
                    for k in j + 1..n {
                        s -= at(b, ldb, i, k) * opa(k, j);
                    }
                } else {
                    for k in 0..j {
                        s -= at(b, ldb, i, k) * opa(k, j);
                    }
                }
                if !unit {
                    s /= opa(j, j);
                }
                set(b, ldb, i, j, s);
            }
        }
    }
}

/// LAPACK's `DLARFG`: the Householder reflector `H = I - tau*v*v'` with
/// `H * (alpha, x)' = (beta, 0)'`. `x` is overwritten with `v(2:)`; `v(1)` is
/// implicitly 1. Returns `(beta, tau)`.
pub(crate) fn dlarfg(alpha: f64, x: &mut [f64]) -> (f64, f64) {
    let xnorm = dnrm2(x);
    if xnorm == 0.0 {
        return (alpha, 0.0);
    }
    let mut beta = -copysign(crate::hypot(alpha, xnorm), alpha);
    // Rescale if beta underflows, as DLARFG does, so 1/(alpha-beta) is finite.
    let mut alpha = alpha;
    let mut scaled = 0;
    while abs(beta) < SAFMIN {
        let rsafmn = 1.0 / SAFMIN;
        dscal(rsafmn, x);
        beta *= rsafmn;
        alpha *= rsafmn;
        scaled += 1;
        if scaled > 20 {
            break;
        }
    }
    let tau = (beta - alpha) / beta;
    dscal(1.0 / (alpha - beta), x);
    for _ in 0..scaled {
        beta *= SAFMIN;
    }
    (beta, tau)
}

fn copysign(x: f64, sign: f64) -> f64 {
    libm::copysign(x, sign)
}

/// LAPACK's `DLARF` for `side = 'L'`: `C := (I - tau*v*v') * C`, where `v` is
/// `(1, v_rest)` and `C` is `m`×`n` with leading dimension `ldc`.
pub(crate) fn dlarf_left(v_rest: &[f64], tau: f64, m: usize, n: usize, c: &mut [f64], ldc: usize) {
    if tau == 0.0 || m == 0 {
        return;
    }
    for j in 0..n {
        let col = &c[j * ldc..j * ldc + m];
        let mut s = col[0];
        s += ddot(v_rest, &col[1..m]);
        if s == 0.0 {
            continue;
        }
        let t = tau * s;
        let col = &mut c[j * ldc..j * ldc + m];
        col[0] -= t;
        daxpy(-t, v_rest, &mut col[1..m]);
    }
}

/// `DLARF` for `side = 'R'`: `C := C * (I - tau*v*v')`, `C` is `m`×`n`.
pub(crate) fn dlarf_right(v_rest: &[f64], tau: f64, m: usize, n: usize, c: &mut [f64], ldc: usize) {
    if tau == 0.0 || n == 0 {
        return;
    }
    for i in 0..m {
        let mut s = at(c, ldc, i, 0);
        for (k, vk) in v_rest.iter().enumerate() {
            s += vk * at(c, ldc, i, k + 1);
        }
        if s == 0.0 {
            continue;
        }
        let t = tau * s;
        set(c, ldc, i, 0, at(c, ldc, i, 0) - t);
        for (k, vk) in v_rest.iter().enumerate() {
            set(c, ldc, i, k + 1, at(c, ldc, i, k + 1) - t * vk);
        }
    }
}
