//! Banded and tridiagonal solvers: `DGTSV` and `DGBSV`.

use crate::blas::at;
use crate::{abs, lu};

/// `DGTSV`: solve `A*X = B` for a tridiagonal `A` given as its three diagonals —
/// `dl` (sub, length `n-1`), `d` (main, `n`), `du` (super, `n-1`). All three are
/// overwritten, as LAPACK overwrites them. Returns `INFO`: `i > 0` when `U(i,i)`
/// is exactly zero, so no solution was computed.
///
/// Gaussian elimination with partial pivoting over the two candidate rows, which
/// is what LAPACK does; the fill-in it creates lives in `du2`.
pub fn dgtsv(
    n: usize,
    nrhs: usize,
    dl: &mut [f64],
    d: &mut [f64],
    du: &mut [f64],
    b: &mut [f64],
    ldb: usize,
) -> i32 {
    if n == 0 {
        return 0;
    }
    let mut du2 = vec![0.0f64; n.saturating_sub(2)];
    for i in 0..n - 1 {
        if abs(d[i]) >= abs(dl[i]) {
            // No row interchange: eliminate with the diagonal.
            if d[i] == 0.0 {
                return (i + 1) as i32;
            }
            let f = dl[i] / d[i];
            d[i + 1] -= f * du[i];
            for j in 0..nrhs {
                let v = at(b, ldb, i, j);
                b[i + 1 + j * ldb] -= f * v;
            }
            if i + 2 < n {
                du2[i] = 0.0;
            }
            dl[i] = f;
        } else {
            // Interchange rows i and i+1.
            let f = d[i] / dl[i];
            d[i] = dl[i];
            let t = d[i + 1];
            d[i + 1] = du[i] - f * t;
            if i + 2 < n {
                du2[i] = du[i + 1];
                du[i + 1] = -f * du2[i];
            }
            du[i] = t;
            for j in 0..nrhs {
                let bi = at(b, ldb, i, j);
                let bi1 = at(b, ldb, i + 1, j);
                b[i + j * ldb] = bi1;
                b[i + 1 + j * ldb] = bi - f * bi1;
            }
            dl[i] = f;
        }
    }
    if d[n - 1] == 0.0 {
        return n as i32;
    }
    // Back substitution over the (at most) three surviving diagonals.
    for j in 0..nrhs {
        b[n - 1 + j * ldb] /= d[n - 1];
        if n > 1 {
            let x = at(b, ldb, n - 1, j);
            b[n - 2 + j * ldb] = (at(b, ldb, n - 2, j) - du[n - 2] * x) / d[n - 2];
        }
        for i in (0..n.saturating_sub(2)).rev() {
            let acc = at(b, ldb, i, j)
                - du[i] * at(b, ldb, i + 1, j)
                - du2[i] * at(b, ldb, i + 2, j);
            b[i + j * ldb] = acc / d[i];
        }
    }
    0
}

/// `DGBSV`: solve `A*X = B` for a general banded `A` with `kl` subdiagonals and
/// `ku` superdiagonals, in LAPACK band storage — column `j` holds `A(i,j)` at row
/// `kl + ku + i - j`, and `ldab >= 2*kl + ku + 1` leaves the extra `kl` rows the
/// factorization fills. `ab` is overwritten by the factors and `b` by the
/// solution.
///
/// Densified and passed to [`lu::dgesv`]: the band structure buys nothing at the
/// sizes `Modelica.Math.Matrices` uses, and this keeps one pivoting path.
#[allow(clippy::too_many_arguments)]
pub fn dgbsv(
    n: usize,
    kl: usize,
    ku: usize,
    nrhs: usize,
    ab: &mut [f64],
    ldab: usize,
    ipiv: &mut [i32],
    b: &mut [f64],
    ldb: usize,
) -> i32 {
    if n == 0 {
        return 0;
    }
    let mut dense = vec![0.0f64; n * n];
    for j in 0..n {
        // The rows of column j that the band actually covers.
        let lo = j.saturating_sub(ku);
        let hi = (j + kl + 1).min(n);
        for i in lo..hi {
            dense[i + j * n] = ab[kl + ku + i - j + j * ldab];
        }
    }
    let info = lu::dgesv(n, nrhs, &mut dense, n, ipiv, b, ldb);
    // Hand the factors back in band storage. The factored band is wider than the
    // original — kl extra rows — which is why LAPACK asks for ldab >= 2*kl+ku+1.
    for j in 0..n {
        let lo = j.saturating_sub(ku + kl);
        let hi = (j + kl + 1).min(n);
        for i in lo..hi {
            let row = kl + ku + i - j;
            if row < ldab {
                ab[row + j * ldab] = dense[i + j * n];
            }
        }
    }
    info
}
