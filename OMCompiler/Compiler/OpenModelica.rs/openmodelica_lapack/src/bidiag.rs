//! `DGEBD2`, `DORGBR`, `DORGL2`, translated from the reference LAPACK.

use crate::blas::{dlarf_left, dlarf_right, dlarfg};
use crate::opt;
use crate::qr::dorgqr;

/// `A(i, j0..j1)` — a row, stride `lda` — as a packed vector.
fn row(a: &[f64], lda: usize, i: usize, j0: usize, j1: usize) -> Vec<f64> {
    (j0..j1).map(|j| a[i + j * lda]).collect()
}

/// `DLARFG` along a row: `alpha = A(i, j0)`, `x = A(i, j0+1..j1)`.
fn dlarfg_row(a: &mut [f64], lda: usize, i: usize, j0: usize, j1: usize) -> (f64, f64) {
    let alpha = a[i + j0 * lda];
    let mut x = row(a, lda, i, j0 + 1, j1);
    let (beta, tau) = dlarfg(alpha, &mut x);
    for (k, v) in x.iter().enumerate() {
        a[i + (j0 + 1 + k) * lda] = *v;
    }
    (beta, tau)
}

/// `DGEBD2`: `A = Q*B*P'` with `B` bidiagonal, unblocked. `B` is upper when
/// `m >= n` and lower otherwise, as diagonal `d` and off-diagonal `e`; `A` keeps
/// the reflectors in the packing `DORGBR` reads back.
#[allow(clippy::too_many_arguments)]
pub fn dgebd2(
    m: usize,
    n: usize,
    a: &mut [f64],
    lda: usize,
    d: &mut [f64],
    e: &mut [f64],
    tauq: &mut [f64],
    taup: &mut [f64],
) {
    if m >= n {
        for i in 0..n {
            let alpha = a[i + i * lda];
            let (beta, t) = dlarfg(alpha, &mut a[i + 1 + i * lda..m + i * lda]);
            tauq[i] = t;
            d[i] = beta;
            a[i + i * lda] = 1.0;
            if i + 1 < n {
                let v = a[i + 1 + i * lda..m + i * lda].to_vec();
                dlarf_left(&v, t, m - i, n - i - 1, &mut a[i + (i + 1) * lda..], lda);
            }
            a[i + i * lda] = d[i];

            if i + 1 < n {
                let (beta, t) = dlarfg_row(a, lda, i, i + 1, n);
                taup[i] = t;
                e[i] = beta;
                a[i + (i + 1) * lda] = 1.0;
                let v = row(a, lda, i, i + 2, n);
                dlarf_right(&v, t, m - i - 1, n - i - 1, &mut a[i + 1 + (i + 1) * lda..], lda);
                a[i + (i + 1) * lda] = e[i];
            } else {
                taup[i] = 0.0;
            }
        }
    } else {
        for i in 0..m {
            let (beta, t) = dlarfg_row(a, lda, i, i, n);
            taup[i] = t;
            d[i] = beta;
            a[i + i * lda] = 1.0;
            if i + 1 < m {
                let v = row(a, lda, i, i + 1, n);
                dlarf_right(&v, t, m - i - 1, n - i, &mut a[i + 1 + i * lda..], lda);
            }
            a[i + i * lda] = d[i];

            if i + 1 < m {
                let alpha = a[i + 1 + i * lda];
                let (beta, t) = dlarfg(alpha, &mut a[i + 2 + i * lda..m + i * lda]);
                tauq[i] = t;
                e[i] = beta;
                a[i + 1 + i * lda] = 1.0;
                let v = a[i + 2 + i * lda..m + i * lda].to_vec();
                dlarf_left(&v, t, m - i - 1, n - i - 1, &mut a[i + 1 + (i + 1) * lda..], lda);
                a[i + 1 + i * lda] = e[i];
            } else {
                tauq[i] = 0.0;
            }
        }
    }
}

/// `DORGL2`: the first `m` rows of the `Q` of an LQ factorization, from `k`
/// reflectors packed in the rows of `A`.
pub fn dorgl2(m: usize, n: usize, k: usize, a: &mut [f64], lda: usize, tau: &[f64]) {
    if m == 0 {
        return;
    }
    if k < m {
        for j in 0..n {
            for l in k..m {
                a[l + j * lda] = 0.0;
            }
            if j >= k && j < m {
                a[j + j * lda] = 1.0;
            }
        }
    }
    for i in (0..k).rev() {
        if i + 1 < n {
            if i + 1 < m {
                a[i + i * lda] = 1.0;
                let v = row(a, lda, i, i + 1, n);
                dlarf_right(&v, tau[i], m - i - 1, n - i, &mut a[i + 1 + i * lda..], lda);
            }
            for j in i + 1..n {
                a[i + j * lda] *= -tau[i];
            }
        }
        a[i + i * lda] = 1.0 - tau[i];
        for l in 0..i {
            a[i + l * lda] = 0.0;
        }
    }
}

/// `DORGBR`: the orthogonal factor `Q` (`vect = "Q"`) or `P'` (`vect = "P"`) of
/// the bidiagonal reduction of a `k`-column (`"Q"`) or `k`-row (`"P"`) matrix,
/// from the reflectors [`dgebd2`] left in `A`.
pub fn dorgbr(vect: &str, m: usize, n: usize, k: usize, a: &mut [f64], lda: usize, tau: &[f64]) {
    if m == 0 || n == 0 {
        return;
    }
    if opt(vect) == b'Q' {
        // With more columns than rows H(i) annihilates below row i+1, so shift
        // the columns right and prepend e1 before DORGQR's packing fits.
        if m >= k {
            dorgqr(m, n, k, a, lda, tau);
        } else {
            for j in (1..m).rev() {
                a[j * lda] = 0.0;
                for i in j + 1..m {
                    a[i + j * lda] = a[i + (j - 1) * lda];
                }
            }
            a[0] = 1.0;
            for i in 1..m {
                a[i] = 0.0;
            }
            if m > 1 {
                dorgqr(m - 1, m - 1, m - 1, &mut a[1 + lda..], lda, tau);
            }
        }
    } else if k < n {
        dorgl2(m, n, k, a, lda, tau);
    } else {
        a[0] = 1.0;
        for i in 1..n {
            a[i] = 0.0;
        }
        for j in 1..n {
            for i in (1..j).rev() {
                a[i + j * lda] = a[i - 1 + j * lda];
            }
            a[j * lda] = 0.0;
        }
        if n > 1 {
            dorgl2(n - 1, n - 1, n - 1, &mut a[1 + lda..], lda, tau);
        }
    }
}
