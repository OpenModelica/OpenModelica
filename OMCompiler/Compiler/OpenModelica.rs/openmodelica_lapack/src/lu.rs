//! LU with partial pivoting and the routines built on it: `DGETRF`, `DGETRS`,
//! `DGETRI`, `DGESV`, `DGESVX`, plus `DLANGE` and `DGECON`.
//!
//! `dgetrf` is LAPACK's unblocked `DGETF2` kernel, so `A` comes back holding the
//! packed `L\U` and `IPIV` the 1-based row interchanges — the same bytes the
//! reference implementation writes, which `Modelica.Math.Matrices.LU` exposes to
//! Modelica code directly.


use crate::blas::{at, dscal, idamax, set, swap_rows};
use crate::{abs, opt};

/// `A = P*L*U` by Gaussian elimination with partial pivoting (`DGETRF`). `A` is
/// `m`×`n` column-major with leading dimension `lda`, overwritten by the factors;
/// `ipiv` (length `min(m, n)`) receives the 1-based pivot rows. Returns `INFO`:
/// `0`, or `i > 0` when `U(i,i)` is exactly zero.
pub fn dgetrf(m: usize, n: usize, a: &mut [f64], lda: usize, ipiv: &mut [i32]) -> i32 {
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
    let notran = opt(trans) == b'N';
    if notran {
        apply_pivots(n, nrhs, ipiv, b, ldb, false);
        crate::blas::dtrsm("L", "L", "N", "U", n, nrhs, 1.0, a, lda, b, ldb);
        crate::blas::dtrsm("L", "U", "N", "N", n, nrhs, 1.0, a, lda, b, ldb);
    } else {
        crate::blas::dtrsm("L", "U", "T", "N", n, nrhs, 1.0, a, lda, b, ldb);
        crate::blas::dtrsm("L", "L", "T", "U", n, nrhs, 1.0, a, lda, b, ldb);
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
