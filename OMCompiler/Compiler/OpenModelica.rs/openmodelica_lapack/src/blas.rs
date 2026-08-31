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

// ─────────────────── Level 2/3, for the Fortran ABI's callers ───────────────────
// Reference implementations: nothing in this crate calls them, and the linked-in
// library that does (PRIMME) works on projected matrices of a few dozen rows.

/// `y := alpha * op(A) * x + beta * y`, `op` transposing when `trans`.
pub fn dgemv(trans: bool, m: usize, n: usize, alpha: f64, a: &[f64], lda: usize, x: &[f64], beta: f64, y: &mut [f64]) {
    let rows = if trans { n } else { m };
    for v in y.iter_mut().take(rows) {
        *v = if beta == 0.0 { 0.0 } else { beta * *v };
    }
    if alpha == 0.0 {
        return;
    }
    if trans {
        for j in 0..n {
            let mut s = 0.0;
            for i in 0..m {
                s += a[j * lda + i] * x[i];
            }
            y[j] += alpha * s;
        }
    } else {
        for j in 0..n {
            let t = alpha * x[j];
            if t == 0.0 {
                continue;
            }
            for i in 0..m {
                y[i] += t * a[j * lda + i];
            }
        }
    }
}

/// `C := alpha * op(A) * op(B) + beta * C`, `C` being `m × n` and `op(A)` `m × k`.
#[allow(clippy::too_many_arguments)]
pub fn dgemm(
    ta: bool, tb: bool, m: usize, n: usize, k: usize, alpha: f64,
    a: &[f64], lda: usize, b: &[f64], ldb: usize, beta: f64, c: &mut [f64], ldc: usize,
) {
    let aij = |i: usize, j: usize| if ta { a[i * lda + j] } else { a[j * lda + i] };
    let bij = |i: usize, j: usize| if tb { b[i * ldb + j] } else { b[j * ldb + i] };
    for j in 0..n {
        for i in 0..m {
            let cij = &mut c[j * ldc + i];
            let mut s = 0.0;
            if alpha != 0.0 {
                for p in 0..k {
                    s += aij(i, p) * bij(p, j);
                }
                s *= alpha;
            }
            *cij = if beta == 0.0 { s } else { s + beta * *cij };
        }
    }
}

/// `C := alpha * A * B + beta * C` (`left`) or `C := alpha * B * A + beta * C`,
/// with `A` symmetric and only its `upper` (or lower) triangle stored.
#[allow(clippy::too_many_arguments)]
pub fn dsymm(
    left: bool, upper: bool, m: usize, n: usize, alpha: f64,
    a: &[f64], lda: usize, b: &[f64], ldb: usize, beta: f64, c: &mut [f64], ldc: usize,
) {
    // The stored triangle mirrored, so the products below read `A` as a full matrix.
    let sym = |i: usize, j: usize| {
        let (r, col) = if (i <= j) == upper { (i, j) } else { (j, i) };
        a[col * lda + r]
    };
    for j in 0..n {
        for i in 0..m {
            let mut s = 0.0;
            if alpha != 0.0 {
                s = alpha
                    * if left {
                        (0..m).map(|p| sym(i, p) * b[j * ldb + p]).sum::<f64>()
                    } else {
                        (0..n).map(|p| b[p * ldb + i] * sym(p, j)).sum::<f64>()
                    };
            }
            let cij = &mut c[j * ldc + i];
            *cij = if beta == 0.0 { s } else { s + beta * *cij };
        }
    }
}

/// `B := alpha * op(A) * B` (`left`) or `B := alpha * B * op(A)`, with `A`
/// triangular (`upper`, transposed by `trans`, unit-diagonal by `unit`).
#[allow(clippy::too_many_arguments)]
pub fn dtrmm(
    left: bool, upper: bool, trans: bool, unit: bool, m: usize, n: usize, alpha: f64,
    a: &[f64], lda: usize, b: &mut [f64], ldb: usize,
) {
    let k = if left { m } else { n };
    let at = |i: usize, j: usize| {
        let (r, c) = if trans { (j, i) } else { (i, j) };
        if r == c && unit {
            1.0
        } else if (r <= c) == upper || r == c {
            a[c * lda + r]
        } else {
            0.0
        }
    };
    // A column (`left`) or row (`right`) of the product, so `B` is not read after
    // the part of it the product needs has been overwritten.
    let mut tmp = vec![0.0f64; k];
    if left {
        for j in 0..n {
            for (i, v) in tmp.iter_mut().enumerate() {
                *v = alpha * (0..k).map(|p| at(i, p) * b[j * ldb + p]).sum::<f64>();
            }
            b[j * ldb..][..m].copy_from_slice(&tmp[..m]);
        }
    } else {
        for i in 0..m {
            for (j, v) in tmp.iter_mut().enumerate() {
                *v = alpha * (0..k).map(|p| b[p * ldb + i] * at(p, j)).sum::<f64>();
            }
            for j in 0..n {
                b[j * ldb + i] = tmp[j];
            }
        }
    }
}
