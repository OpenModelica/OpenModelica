//! Householder QR and the least-squares drivers on it: `DGEQRF`, `DGEQP3`,
//! `DORGQR`, `DORMQR`, `DGELS`, `DGELSY`.
//!
//! The factored form is LAPACK's: `R` in the upper triangle of `A`, reflector `k`
//! as `TAU(k)` plus `V(k+2:m)` below the diagonal of column `k` (`V(k+1)` is
//! implicitly 1).


use crate::blas::{at, dlarf_left, dlarf_right, dlarfg, dnrm2, set};
use crate::{abs, opt};

/// `A = Q*R` (`DGEQRF`). `tau` has length `min(m, n)`.
pub fn dgeqrf(m: usize, n: usize, a: &mut [f64], lda: usize, tau: &mut [f64]) -> i32 {
    for j in 0..m.min(n) {
        let (beta, t) = reflect_column(m, j, a, lda);
        tau[j] = t;
        // Apply H(j) to the trailing columns with V(j) = (1, A(j+1:m, j)).
        if j + 1 < n {
            let (head, rest) = a.split_at_mut((j + 1) * lda);
            let v: Vec<f64> = head[j + 1 + j * lda..m + j * lda].to_vec();
            dlarf_left(&v, t, m - j, n - j - 1, &mut rest[j..], lda);
        }
        set(a, lda, j, j, beta);
    }
    0
}

/// Generate `H(j)` from column `j` at and below the diagonal, leaving `V(j+1:)`
/// in place. Returns `(beta, tau)`; the caller stores `beta` at `A(j,j)` after
/// applying the reflector.
fn reflect_column(m: usize, j: usize, a: &mut [f64], lda: usize) -> (f64, f64) {
    let alpha = at(a, lda, j, j);
    let (beta, t) = if j + 1 < m {
        dlarfg(alpha, &mut a[j + 1 + j * lda..m + j * lda])
    } else {
        (alpha, 0.0)
    };
    set(a, lda, j, j, 1.0);
    (beta, t)
}

/// `A*P = Q*R` with column pivoting (`DGEQP3`). `jpvt` is LAPACK's: a nonzero
/// entry on input moves that column to the front, a zero leaves it free; on output
/// it holds the 1-based permutation.
pub fn dgeqp3(
    m: usize,
    n: usize,
    a: &mut [f64],
    lda: usize,
    jpvt: &mut [i32],
    tau: &mut [f64],
) -> i32 {
    let mut perm: Vec<usize> = Vec::with_capacity(n);
    for j in 0..n {
        if jpvt[j] != 0 {
            perm.push(j);
        }
    }
    let fixed = perm.len();
    for j in 0..n {
        if jpvt[j] == 0 {
            perm.push(j);
        }
    }
    permute_columns(m, n, a, lda, &perm);

    let mut colnorm: Vec<f64> = (0..n).map(|j| dnrm2(&a[j * lda..j * lda + m])).collect();
    for j in 0..m.min(n) {
        if j >= fixed {
            // Pivot on the largest remaining column norm, recomputed rather than
            // downdated (DGEQP3 downdates and refreshes; recomputing is the same
            // answer without the tolerance heuristics).
            let mut best = j;
            for k in j + 1..n {
                if colnorm[k] > colnorm[best] {
                    best = k;
                }
            }
            if best != j {
                for i in 0..m {
                    a.swap(i + j * lda, i + best * lda);
                }
                perm.swap(j, best);
                colnorm.swap(j, best);
            }
        }
        let (beta, t) = reflect_column(m, j, a, lda);
        tau[j] = t;
        if j + 1 < n {
            let (head, rest) = a.split_at_mut((j + 1) * lda);
            let v: Vec<f64> = head[j + 1 + j * lda..m + j * lda].to_vec();
            dlarf_left(&v, t, m - j, n - j - 1, &mut rest[j..], lda);
        }
        set(a, lda, j, j, beta);
        for k in j + 1..n {
            colnorm[k] = dnrm2(&a[j + 1 + k * lda..m + k * lda]);
        }
    }
    for (slot, src) in perm.iter().enumerate() {
        jpvt[slot] = (*src + 1) as i32;
    }
    0
}

fn permute_columns(m: usize, n: usize, a: &mut [f64], lda: usize, perm: &[usize]) {
    let mut tmp = vec![0.0f64; m * n];
    for (slot, src) in perm.iter().enumerate() {
        tmp[slot * m..slot * m + m].copy_from_slice(&a[src * lda..src * lda + m]);
    }
    for j in 0..n {
        a[j * lda..j * lda + m].copy_from_slice(&tmp[j * m..j * m + m]);
    }
}

/// Form the first `n` columns of `Q` from `k` reflectors (`DORGQR`). `A` holds the
/// factored form on input and `Q` (`m`×`n`) on output.
pub fn dorgqr(m: usize, n: usize, k: usize, a: &mut [f64], lda: usize, tau: &[f64]) -> i32 {
    // Zero out the columns beyond the reflectors, then set the identity in the
    // block those columns' reflectors do not reach, as DORG2R does.
    for j in k..n {
        for i in 0..m {
            set(a, lda, i, j, if i == j { 1.0 } else { 0.0 });
        }
    }
    for j in (0..k).rev() {
        let v: Vec<f64> = a[j + 1 + j * lda..m + j * lda].to_vec();
        if j + 1 < n {
            let (head, rest) = a.split_at_mut((j + 1) * lda);
            let _ = &head;
            dlarf_left(&v, tau[j], m - j, n - j - 1, &mut rest[j..], lda);
        }
        // Column j itself: Q(:,j) = (I - tau v v') e_j = e_j - tau*v.
        let t = tau[j];
        set(a, lda, j, j, 1.0 - t);
        for (i, vi) in v.iter().enumerate() {
            set(a, lda, j + 1 + i, j, -t * vi);
        }
        for i in 0..j {
            set(a, lda, i, j, 0.0);
        }
    }
    0
}

/// `C := op(Q)*C` (`side = "L"`) or `C := C*op(Q)` (`side = "R"`) for the `Q` of a
/// `dgeqrf` factorization (`DORMQR`). `a`/`tau` are that factorization; `k` is the
/// number of reflectors.
#[allow(clippy::too_many_arguments)]
pub fn dormqr(
    side: &str,
    trans: &str,
    m: usize,
    n: usize,
    k: usize,
    a: &[f64],
    lda: usize,
    tau: &[f64],
    c: &mut [f64],
    ldc: usize,
) -> i32 {
    let left = opt(side) == b'L';
    let notran = opt(trans) == b'N';
    // Q = H(1)…H(k), so Q*C applies them in reverse and Q'*C in order.
    let order: Vec<usize> = if notran == left { (0..k).rev().collect() } else { (0..k).collect() };
    let rows = if left { m } else { n };
    for j in order {
        let v: Vec<f64> = a[j + 1 + j * lda..rows + j * lda].to_vec();
        if left {
            dlarf_left(&v, tau[j], m - j, n, &mut c[j..], ldc);
        } else {
            dlarf_right(&v, tau[j], m, n - j, &mut c[j * ldc..], ldc);
        }
    }
    0
}

/// Least squares / minimum norm by QR (`DGELS`): the least-squares solution of
/// `op(A)*X = B` when `op(A)` has more rows than columns, the minimum-norm
/// solution when it has fewer. `B` is `max(m, n)`×`nrhs` and receives `X` in its
/// first `cols` rows. Returns `INFO`: `i > 0` when `A` does not have full rank.
#[allow(clippy::too_many_arguments)]
pub fn dgels(
    trans: &str,
    m: usize,
    n: usize,
    nrhs: usize,
    a: &mut [f64],
    lda: usize,
    b: &mut [f64],
    ldb: usize,
) -> i32 {
    // op(A) is `rows`×`cols`; the transposed case is the same algorithm on A'.
    let notran = opt(trans) == b'N';
    let (rows, cols) = if notran { (m, n) } else { (n, m) };
    let mut op: Vec<f64> = vec![0.0; rows * cols];
    for j in 0..cols {
        for i in 0..rows {
            op[i + j * rows] = if notran { at(a, lda, i, j) } else { at(a, lda, j, i) };
        }
    }
    let k = rows.min(cols);
    let mut tau = vec![0.0f64; k];
    if rows >= cols {
        dgeqrf(rows, cols, &mut op, rows, &mut tau);
        for j in 0..k {
            if at(&op, rows, j, j) == 0.0 {
                return (j + 1) as i32;
            }
        }
        dormqr("L", "T", rows, nrhs, k, &op, rows, &tau, b, ldb);
        crate::blas::dtrsm("L", "U", "N", "N", cols, nrhs, 1.0, &op, rows, b, ldb);
    } else {
        // Minimum-norm solution: QR of op(A)' = Q*R gives x = Q * (R'^{-1} b).
        let mut t: Vec<f64> = vec![0.0; cols * rows];
        for j in 0..rows {
            for i in 0..cols {
                t[i + j * cols] = op[j + i * rows];
            }
        }
        dgeqrf(cols, rows, &mut t, cols, &mut tau);
        for j in 0..k {
            if at(&t, cols, j, j) == 0.0 {
                return (j + 1) as i32;
            }
        }
        crate::blas::dtrsm("L", "U", "T", "N", rows, nrhs, 1.0, &t, cols, b, ldb);
        for j in 0..nrhs {
            for i in rows..cols {
                set(b, ldb, i, j, 0.0);
            }
        }
        dormqr("L", "N", cols, nrhs, k, &t, cols, &tau, b, ldb);
    }
    0
}

/// `DGEQPF`: LAPACK's deprecated unblocked pivoted QR, the predecessor of
/// [`dgeqp3`]. Same factorization, same output; MSL 3.2.3's `Matrices.QR` still
/// calls it.
pub fn dgeqpf(
    m: usize,
    n: usize,
    a: &mut [f64],
    lda: usize,
    jpvt: &mut [i32],
    tau: &mut [f64],
) -> i32 {
    dgeqp3(m, n, a, lda, jpvt, tau)
}

/// `DGELSX`: LAPACK's deprecated rank-deficient least squares, the predecessor of
/// [`dgelsy`] (which differs only in taking `LWORK`).
#[allow(clippy::too_many_arguments)]
pub fn dgelsx(
    m: usize,
    n: usize,
    nrhs: usize,
    a: &[f64],
    lda: usize,
    b: &mut [f64],
    ldb: usize,
    jpvt: &mut [i32],
    rcond: f64,
) -> (usize, i32) {
    dgelsy(m, n, nrhs, a, lda, b, ldb, jpvt, rcond)
}

/// `DGELSY`: minimum-norm least squares with a rank decision. Solves `A*X = B`
/// for the `min(m, n)`-by-`nrhs` `X`, where `A` may be rank deficient. `B` is
/// `max(m, n)`×`nrhs` and receives `X` in its first `n` rows; `jpvt` receives
/// `DGEQP3`'s pivots. Returns `(rank, INFO)`.
///
/// The rank is LAPACK's, from [`crate::rz::dlaic1`] growing the pivoted triangle
/// a column at a time until the condition estimate crosses `rcond` — not a count
/// of singular values above a threshold, which disagrees near the cut and cannot
/// report the pivots.
#[allow(clippy::too_many_arguments)]
pub fn dgelsy(
    m: usize,
    n: usize,
    nrhs: usize,
    a: &[f64],
    lda: usize,
    b: &mut [f64],
    ldb: usize,
    jpvt: &mut [i32],
    rcond: f64,
) -> (usize, i32) {
    use crate::rz::Est;
    let mn = m.min(n);
    for slot in jpvt[..n].iter_mut() {
        *slot = 0;
    }
    if mn == 0 || nrhs == 0 {
        return (0, 0);
    }
    let zero_out = |b: &mut [f64]| {
        for j in 0..nrhs {
            for i in 0..m.max(n) {
                set(b, ldb, i, j, 0.0);
            }
        }
    };

    let smlnum = crate::SAFMIN / crate::hqr::ULP;
    let bignum = 1.0 / smlnum;
    let mut work = crate::pack(m, n, a, lda);
    let anrm = work.iter().copied().fold(0.0f64, |acc, v| f64::max(acc, abs(v)));
    // Scale A and B into range, and undo it on the way out.
    let iascl = if anrm > 0.0 && anrm < smlnum {
        for j in 0..n {
            crate::hqr::dlascl(anrm, smlnum, &mut work[j * m..j * m + m]);
        }
        1
    } else if anrm > bignum {
        for j in 0..n {
            crate::hqr::dlascl(anrm, bignum, &mut work[j * m..j * m + m]);
        }
        2
    } else if anrm == 0.0 {
        zero_out(b);
        return (0, 0);
    } else {
        0
    };
    let mut bnrm = 0.0f64;
    for j in 0..nrhs {
        for i in 0..m {
            bnrm = f64::max(bnrm, abs(at(b, ldb, i, j)));
        }
    }
    let ibscl = if bnrm > 0.0 && bnrm < smlnum {
        scale_b(b, ldb, m, nrhs, bnrm, smlnum);
        1
    } else if bnrm > bignum {
        scale_b(b, ldb, m, nrhs, bnrm, bignum);
        2
    } else {
        0
    };

    let mut tau = vec![0.0f64; mn];
    dgeqp3(m, n, &mut work, m, jpvt, &mut tau);

    // Grow the rank while the pivoted triangle stays well conditioned.
    let mut xmin = vec![0.0f64; mn];
    let mut xmax = vec![0.0f64; mn];
    xmin[0] = 1.0;
    xmax[0] = 1.0;
    let mut smax = abs(at(&work, m, 0, 0));
    let mut smin = smax;
    if smax == 0.0 {
        zero_out(b);
        return (0, 0);
    }
    let mut rank = 1usize;
    while rank < mn {
        let col: Vec<f64> = (0..rank).map(|r| at(&work, m, r, rank)).collect();
        let gamma = at(&work, m, rank, rank);
        let (sminpr, s1, c1) = crate::rz::dlaic1(Est::Min, rank, &xmin, smin, &col, gamma);
        let (smaxpr, s2, c2) = crate::rz::dlaic1(Est::Max, rank, &xmax, smax, &col, gamma);
        if smaxpr * rcond > sminpr {
            break;
        }
        for i in 0..rank {
            xmin[i] *= s1;
            xmax[i] *= s2;
        }
        xmin[rank] = c1;
        xmax[rank] = c2;
        smin = sminpr;
        smax = smaxpr;
        rank += 1;
    }

    // Compress the leading `rank` rows to upper triangular, so the minimum-norm
    // solution falls out of one triangular solve.
    let mut rztau = vec![0.0f64; rank];
    if rank < n {
        crate::rz::dlatrz(rank, n, n - rank, &mut work, m, &mut rztau);
    }
    dormqr("L", "T", m, nrhs, mn, &work, m, &tau, b, ldb);
    crate::blas::dtrsm("L", "U", "N", "N", rank, nrhs, 1.0, &work, m, b, ldb);
    for j in 0..nrhs {
        for i in rank..n {
            set(b, ldb, i, j, 0.0);
        }
    }
    if rank < n {
        crate::rz::dormr3_left_trans(n, nrhs, rank, n - rank, &work, m, &rztau, b, ldb);
    }
    // Undo DGEQP3's column permutation.
    for j in 0..nrhs {
        let col: Vec<f64> = (0..n).map(|i| at(b, ldb, i, j)).collect();
        for (i, v) in col.iter().enumerate() {
            set(b, ldb, jpvt[i] as usize - 1, j, *v);
        }
    }

    match iascl {
        1 => scale_b(b, ldb, n, nrhs, anrm, smlnum),
        2 => scale_b(b, ldb, n, nrhs, anrm, bignum),
        _ => {}
    }
    match ibscl {
        1 => scale_b(b, ldb, n, nrhs, smlnum, bnrm),
        2 => scale_b(b, ldb, n, nrhs, bignum, bnrm),
        _ => {}
    }
    (rank, 0)
}

/// `DLASCL('G', …)` over the leading `rows`×`cols` of a strided buffer.
fn scale_b(b: &mut [f64], ldb: usize, rows: usize, cols: usize, from: f64, to: f64) {
    for j in 0..cols {
        crate::hqr::dlascl(from, to, &mut b[j * ldb..j * ldb + rows]);
    }
}

/// `DGGLSE`: minimize `||C - A*X||` subject to `B*X = D`. `A` is `m`×`n`, `B` is
/// `p`×`n` with `p <= n <= m + p`. Solved by eliminating the constraint through
/// the QR factorization of `B'`. `x` receives the `n` solution components.
#[allow(clippy::too_many_arguments)]
pub fn dgglse(
    m: usize,
    n: usize,
    p: usize,
    a: &[f64],
    lda: usize,
    b: &[f64],
    ldb: usize,
    c: &[f64],
    d: &[f64],
    x: &mut [f64],
) -> i32 {
    if p > n || n > m + p {
        return -1;
    }
    // B' = Q*R, so B = R'*Q'. With y = Q'x, the constraint fixes the first p
    // components of y (R' y1 = d) and the objective is a free least-squares
    // problem in the rest.
    let mut bt = vec![0.0f64; n * p];
    for j in 0..p {
        for i in 0..n {
            bt[i + j * n] = at(b, ldb, j, i);
        }
    }
    let mut tau = vec![0.0f64; p.min(n)];
    dgeqrf(n, p, &mut bt, n, &mut tau);
    let mut y = vec![0.0f64; n];
    y[..p].copy_from_slice(&d[..p]);
    crate::blas::dtrsm("L", "U", "T", "N", p, 1, 1.0, &bt, n, &mut y, n);
    // AQ = A*Q, split at column p: AQ1*y1 + AQ2*y2 = c.
    let mut aq = crate::pack(m, n, a, lda);
    dormqr("R", "N", m, n, p.min(n), &bt, n, &tau, &mut aq, m);
    let mut rhs = vec![0.0f64; m.max(n - p)];
    for i in 0..m {
        let mut r = c[i];
        for (k, yk) in y.iter().enumerate().take(p) {
            r -= aq[i + k * m] * yk;
        }
        rhs[i] = r;
    }
    let mut aq2 = vec![0.0f64; m * (n - p)];
    for j in 0..n - p {
        aq2[j * m..j * m + m].copy_from_slice(&aq[(p + j) * m..(p + j) * m + m]);
    }
    let ldr = rhs.len();
    let info = dgels("N", m, n - p, 1, &mut aq2, m, &mut rhs, ldr);
    if info != 0 {
        return info;
    }
    y[p..n].copy_from_slice(&rhs[..n - p]);
    // x = Q*y.
    let mut xq = y;
    dormqr("L", "N", n, 1, p.min(n), &bt, n, &tau, &mut xq, n);
    x[..n].copy_from_slice(&xq[..n]);
    0
}
