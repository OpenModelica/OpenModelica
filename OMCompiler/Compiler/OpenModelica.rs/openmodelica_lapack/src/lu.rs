//! LU with partial pivoting and the routines built on it: `DGETRF`, `DGETRS`,
//! `DGETRI`, `DGESV`, `DGESVX`, plus `DLANGE` and `DGECON`.
//!
//! `A` comes back holding the packed `L\U` and `IPIV` the 1-based row
//! interchanges, the layout `Modelica.Math.Matrices.LU` exposes to Modelica code
//! directly. `dgetrf2` is the recursive `DGETRF2` reference `DGETRF` factors a
//! small matrix with, step for step, and `dgetrf_ref` the unblocked `DGETF2`;
//! faer factors the larger matrices, to the same convention.


use crate::blas::{at, dscal, idamax, set, swap_rows};
use crate::{abs, opt};

/// Backend crossovers for the LU pair, measured on x86-64 and under wasm: at the
/// size a Modelica torn linear system usually has, faer's blocking and the `IPIV`
/// packaging around it cost more than the factorization, and its triangular solve
/// only pays off far later still. `IPIV` means the same thing either way, so a
/// factor from one backend solves with the other.
#[cfg(feature = "faer-backend")]
const FAER_LU_MIN: usize = 16;
#[cfg(feature = "faer-backend")]
const FAER_SOLVE_MIN: usize = 256;

/// `A = P*L*U` by Gaussian elimination with partial pivoting (`DGETRF`). `A` is
/// `m`×`n` column-major with leading dimension `lda`, overwritten by the factors;
/// `ipiv` (length `min(m, n)`) receives the 1-based pivot rows. Returns `INFO`:
/// `0`, or `i > 0` when `U(i,i)` is exactly zero.
pub fn dgetrf(m: usize, n: usize, a: &mut [f64], lda: usize, ipiv: &mut [i32]) -> i32 {
    #[cfg(feature = "faer-backend")]
    if m.min(n) >= FAER_LU_MIN {
        return crate::faer_backend::dgetrf(m, n, a, lda, ipiv);
    }
    dgetrf2(m, n, a, 0, lda, ipiv)
}

/// The port of `DGETRF2` on the `m`×`n` block at `a[off..]`: factor the left half
/// of the columns, update the right half, factor that, and apply its interchanges
/// back to the left. Its rounding is reference LAPACK's, which decides whether a
/// nearly singular system is singular.
fn dgetrf2(m: usize, n: usize, a: &mut [f64], off: usize, lda: usize, ipiv: &mut [i32]) -> i32 {
    if m == 0 || n == 0 {
        return 0;
    }
    let ix = |i: usize, j: usize| off + i + j * lda;
    if m == 1 {
        ipiv[0] = 1;
        return (a[ix(0, 0)] == 0.0) as i32;
    }
    if n == 1 {
        let p = idamax(&a[ix(0, 0)..ix(m, 0)]);
        ipiv[0] = (p + 1) as i32;
        if a[ix(p, 0)] == 0.0 {
            return 1;
        }
        a.swap(ix(0, 0), ix(p, 0));
        let piv = a[ix(0, 0)];
        if abs(piv) >= crate::SAFMIN {
            dscal(1.0 / piv, &mut a[ix(1, 0)..ix(m, 0)]);
        } else {
            for i in 1..m {
                a[ix(i, 0)] /= piv;
            }
        }
        return 0;
    }
    let k = m.min(n);
    let n1 = k / 2;
    let mut info = dgetrf2(m, n1, a, off, lda, &mut ipiv[..n1]);
    swap_pivots(a, ix(0, 0), lda, n1..n, &ipiv[..n1], 0);
    // DTRSM('L', 'L', 'N', 'U') on A12, then DGEMM's A22 -= A21*A12, in
    // reference BLAS's loop order.
    for j in n1..n {
        for l in 0..n1 {
            let b = a[ix(l, j)];
            if b != 0.0 {
                for i in l + 1..n1 {
                    a[ix(i, j)] -= b * a[ix(i, l)];
                }
            }
        }
        for l in 0..n1 {
            let t = -a[ix(l, j)];
            for i in n1..m {
                a[ix(i, j)] += t * a[ix(i, l)];
            }
        }
    }
    let iinfo = dgetrf2(m - n1, n - n1, a, ix(n1, n1), lda, &mut ipiv[n1..k]);
    if info == 0 && iinfo > 0 {
        info = iinfo + n1 as i32;
    }
    for p in &mut ipiv[n1..k] {
        *p += n1 as i32;
    }
    swap_pivots(a, ix(0, 0), lda, 0..n1, &ipiv[n1..k], n1);
    info
}

/// `DLASWP` over `cols` of the block at `a[off..]`: row `first + i` with the
/// 1-based pivot row `ipiv[i]`.
fn swap_pivots(a: &mut [f64], off: usize, lda: usize, cols: core::ops::Range<usize>, ipiv: &[i32], first: usize) {
    for (i, &p) in ipiv.iter().enumerate() {
        let (r, p) = (first + i, p as usize - 1);
        if p != r {
            for c in cols.clone() {
                a.swap(off + r + c * lda, off + p + c * lda);
            }
        }
    }
}

/// The port of `DGETF2`: the small-`n` and faer-free path.
pub fn dgetrf_ref(m: usize, n: usize, a: &mut [f64], lda: usize, ipiv: &mut [i32]) -> i32 {
    let mut info = 0;
    for j in 0..m.min(n) {
        let p = j + idamax(&a[j + j * lda..m + j * lda]);
        ipiv[j] = (p + 1) as i32;
        if at(a, lda, p, j) != 0.0 {
            swap_rows(a, lda, 0..n, j, p);
            if j + 1 < m {
                let piv = at(a, lda, j, j);
                // Reciprocal-multiply like DGETF2, except where it would overflow.
                if abs(piv) >= crate::SAFMIN {
                    dscal(1.0 / piv, &mut a[j + 1 + j * lda..m + j * lda]);
                } else {
                    for i in j + 1..m {
                        set(a, lda, i, j, at(a, lda, i, j) / piv);
                    }
                }
            }
        } else if info == 0 {
            info = (j + 1) as i32;
        }
        for c in j + 1..n {
            let t = at(a, lda, j, c);
            if t != 0.0 {
                for i in j + 1..m {
                    set(a, lda, i, c, at(a, lda, i, c) - at(a, lda, i, j) * t);
                }
            }
        }
    }
    info
}

/// Solve `A*X = B` (`trans = "N"`) or `A'*X = B` from the factors `dgetrf` left
/// (`DGETRS`). `B` is `n`×`nrhs`, overwritten with `X`.
#[allow(clippy::too_many_arguments)]
pub fn dgetrs(
    trans: &str,
    n: usize,
    nrhs: usize,
    a: &[f64],
    lda: usize,
    ipiv: &[i32],
    b: &mut [f64],
    ldb: usize,
) -> i32 {
    #[cfg(feature = "faer-backend")]
    if n >= FAER_SOLVE_MIN {
        return crate::faer_backend::dgetrs(trans, n, nrhs, a, lda, ipiv, b, ldb);
    }
    dgetrs_ref(trans, n, nrhs, a, lda, ipiv, b, ldb)
}

/// The port of `DGETRS`: the small-`n` and faer-free path.
#[allow(clippy::too_many_arguments)]
pub fn dgetrs_ref(
    trans: &str,
    n: usize,
    nrhs: usize,
    a: &[f64],
    lda: usize,
    ipiv: &[i32],
    b: &mut [f64],
    ldb: usize,
) -> i32 {
    let notran = opt(trans) == b'N';
    if notran {
        apply_pivots(n, nrhs, ipiv, b, ldb, false);
        crate::blas::dtrsm_ref("L", "L", "N", "U", n, nrhs, 1.0, a, lda, b, ldb);
        crate::blas::dtrsm_ref("L", "U", "N", "N", n, nrhs, 1.0, a, lda, b, ldb);
    } else {
        crate::blas::dtrsm_ref("L", "U", "T", "N", n, nrhs, 1.0, a, lda, b, ldb);
        crate::blas::dtrsm_ref("L", "L", "T", "U", n, nrhs, 1.0, a, lda, b, ldb);
        apply_pivots(n, nrhs, ipiv, b, ldb, true);
    }
    0
}

/// `DLASWP`: apply `ipiv` to the rows of `b`, forwards or in reverse.
fn apply_pivots(n: usize, nrhs: usize, ipiv: &[i32], b: &mut [f64], ldb: usize, reverse: bool) {
    let k = ipiv.len().min(n);
    for step in 0..k {
        let i = if reverse { k - 1 - step } else { step };
        let p = ipiv[i];
        if p > 0 {
            swap_rows(b, ldb, 0..nrhs, i, p as usize - 1);
        }
    }
}

/// `inv(A)` from the factors `dgetrf` left (`DGETRI`); `a` is overwritten.
/// Returns `INFO`: `i > 0` when `U(i,i)` is zero, so `A` is singular.
pub fn dgetri(n: usize, a: &mut [f64], lda: usize, ipiv: &[i32]) -> i32 {
    #[cfg(feature = "faer-backend")]
    return crate::faer_backend::dgetri(n, a, lda, ipiv);
    #[cfg(not(feature = "faer-backend"))]
    dgetri_ref(n, a, lda, ipiv)
}

/// The port of `DGETRI`, kept as the faer-free fallback.
pub fn dgetri_ref(n: usize, a: &mut [f64], lda: usize, ipiv: &[i32]) -> i32 {
    for j in 0..n {
        if at(a, lda, j, j) == 0.0 {
            return (j + 1) as i32;
        }
    }
    let mut inv = vec![0.0f64; n * n];
    for j in 0..n {
        inv[j + j * n] = 1.0;
    }
    dgetrs("N", n, n, a, lda, ipiv, &mut inv, n);
    for j in 0..n {
        a[j * lda..j * lda + n].copy_from_slice(&inv[j * n..j * n + n]);
    }
    0
}

/// `DGESV`: factor `A` and solve `A*X = B` in one step. `A` is overwritten by its
/// factors, `B` by the solution.
#[allow(clippy::too_many_arguments)]
pub fn dgesv(
    n: usize,
    nrhs: usize,
    a: &mut [f64],
    lda: usize,
    ipiv: &mut [i32],
    b: &mut [f64],
    ldb: usize,
) -> i32 {
    let info = dgetrf(n, n, a, lda, ipiv);
    if info == 0 {
        dgetrs("N", n, nrhs, a, lda, ipiv, b, ldb);
    }
    info
}

/// `DLANGE`: the `"M"` (max abs), `"1"`/`"O"` (max column sum), `"I"` (max row
/// sum) or `"F"`/`"E"` (Frobenius) norm of an `m`×`n` matrix.
pub fn dlange(norm: &str, m: usize, n: usize, a: &[f64], lda: usize) -> f64 {
    if m == 0 || n == 0 {
        return 0.0;
    }
    match opt(norm) {
        b'M' => (0..n)
            .flat_map(|j| (0..m).map(move |i| (i, j)))
            .map(|(i, j)| abs(at(a, lda, i, j)))
            .fold(0.0f64, f64::max),
        b'1' | b'O' => (0..n)
            .map(|j| a[j * lda..j * lda + m].iter().map(|v| abs(*v)).sum::<f64>())
            .fold(0.0f64, f64::max),
        b'I' => {
            let mut rows = vec![0.0f64; m];
            for j in 0..n {
                for i in 0..m {
                    rows[i] += abs(at(a, lda, i, j));
                }
            }
            rows.into_iter().fold(0.0f64, f64::max)
        }
        _ => {
            let mut cols: Vec<f64> = Vec::with_capacity(n);
            for j in 0..n {
                cols.push(crate::blas::dnrm2(&a[j * lda..j * lda + m]));
            }
            crate::blas::dnrm2(&cols)
        }
    }
}

/// `DGECON`: the reciprocal condition number `1/(norm(A) * norm(inv(A)))` from
/// the factors `dgetrf` left, in the `"1"`/`"O"` or `"I"` norm. `anorm` is the
/// same norm of the *unfactored* `A`. Returns `(rcond, INFO)`.
///
/// LAPACK estimates `norm(inv(A))` with `DLACN2`; this inverts the factors and
/// takes the norm exactly, which is more work but never underestimates.
pub fn dgecon(norm: &str, n: usize, a: &[f64], lda: usize, anorm: f64) -> (f64, i32) {
    if n == 0 {
        return (1.0, 0);
    }
    if anorm < 0.0 {
        return (0.0, -5);
    }
    if anorm == 0.0 {
        return (0.0, 0);
    }
    let mut lufac = crate::pack(n, n, a, lda);
    // `dgetri` needs the pivots, and inverting L\U with the identity permutation
    // gives inv(L*U) = inv(A)*P — a column permutation, which leaves the 1-norm
    // and the infinity norm unchanged.
    let ipiv: Vec<i32> = (1..=n as i32).collect();
    if dgetri(n, &mut lufac, n, &ipiv) != 0 {
        return (0.0, 0);
    }
    let ainvnorm = dlange(norm, n, n, &lufac, n);
    if ainvnorm == 0.0 {
        return (0.0, 0);
    }
    ((1.0 / anorm) / ainvnorm, 0)
}

/// `DGESVX`, the "expert" driver, in the subset `Modelica.Math.Matrices` asks
/// for: `fact = "N"` (factor here), `trans`, no equilibration. Returns
/// `(rcond, ferr, berr, INFO)`; `A` is overwritten by its factors and `B` by the
/// solution. `INFO = n + 1` reports a factorization that is nonsingular but whose
/// `rcond` is below machine precision, exactly as LAPACK does.
#[allow(clippy::too_many_arguments)]
pub fn dgesvx(
    fact: &str,
    trans: &str,
    n: usize,
    nrhs: usize,
    a: &mut [f64],
    lda: usize,
    af: &mut [f64],
    ldaf: usize,
    ipiv: &mut [i32],
    b: &[f64],
    ldb: usize,
    x: &mut [f64],
    ldx: usize,
    ferr: &mut [f64],
    berr: &mut [f64],
) -> (f64, i32) {
    let nofact = matches!(opt(fact), b'N' | b'E');
    let anorm = dlange("1", n, n, a, lda);
    if nofact {
        for j in 0..n {
            af[j * ldaf..j * ldaf + n].copy_from_slice(&a[j * lda..j * lda + n]);
        }
        let info = dgetrf(n, n, af, ldaf, ipiv);
        if info > 0 {
            return (0.0, info);
        }
    }
    let (rcond, _) = dgecon("1", n, af, ldaf, anorm);
    for j in 0..nrhs {
        x[j * ldx..j * ldx + n].copy_from_slice(&b[j * ldb..j * ldb + n]);
    }
    dgetrs(trans, n, nrhs, af, ldaf, ipiv, x, ldx);
    // One step of iterative refinement's worth of error bounds: the componentwise
    // backward error from the computed residual, and the forward error it implies.
    for j in 0..nrhs {
        let notran = opt(trans) == b'N';
        let mut num = 0.0f64;
        let mut den = 0.0f64;
        for i in 0..n {
            let mut r = -b[i + j * ldb];
            let mut s = 0.0f64;
            for k in 0..n {
                let aik = if notran { a[i + k * lda] } else { a[k + i * lda] };
                r += aik * x[k + j * ldx];
                s += abs(aik) * abs(x[k + j * ldx]);
            }
            num = num.max(abs(r));
            den = den.max(s + abs(b[i + j * ldb]));
        }
        berr[j] = if den > 0.0 { num / den } else { 0.0 };
        ferr[j] = if rcond > 0.0 { berr[j] / rcond } else { 1.0 };
    }
    if rcond < crate::EPS {
        return (rcond, (n + 1) as i32);
    }
    (rcond, 0)
}
