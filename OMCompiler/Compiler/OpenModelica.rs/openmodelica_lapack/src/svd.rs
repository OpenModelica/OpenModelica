//! Singular value decomposition: `DGESVD` and `DGESDD`.
//!
//! Both map onto oxiblas's divide-and-conquer SVD, which already produces the
//! full `m`×`m` `U` and `n`×`n` `V^T` that LAPACK's `jobu = "A"` asks for, so the
//! shims only select and place the requested blocks.

use oxiblas_lapack::svd::SvdDc;

use crate::{from_mat, opt, to_mat};

/// `A = U * diag(S) * VT` (`DGESVD`). `jobu`/`jobvt` are LAPACK's `"A"` (all
/// columns/rows), `"S"` (the first `min(m, n)`), `"O"` (the first `min(m, n)`,
/// written over `A`) and `"N"` (not computed). `s` has length `min(m, n)`, in
/// descending order. Returns `INFO`, `> 0` when the iteration did not converge.
#[allow(clippy::too_many_arguments)]
pub fn dgesvd(
    jobu: &str,
    jobvt: &str,
    m: usize,
    n: usize,
    a: &mut [f64],
    lda: usize,
    s: &mut [f64],
    u: &mut [f64],
    ldu: usize,
    vt: &mut [f64],
    ldvt: usize,
) -> i32 {
    let k = m.min(n);
    if k == 0 {
        return 0;
    }
    let mat = to_mat(m, n, a, lda);
    let Ok(svd) = crate::parallel::install(|| SvdDc::compute(mat.as_ref())) else {
        return 1;
    };
    let sigma = svd.singular_values();
    for (slot, v) in s.iter_mut().zip(sigma).take(k) {
        *slot = *v;
    }
    // `A` is only overwritten by a `"O"` job, and at most one of the two may ask
    // for it — so reading the decomposition first and writing after is safe.
    let ju = opt(jobu);
    let jvt = opt(jobvt);
    if ju != b'N' {
        let full = svd.u();
        let cols = if ju == b'A' { m } else { k };
        let block = crate::mat_from_fn(m, cols, |i, j| full[(i, j)]);
        match ju {
            b'O' => from_mat(a, lda, &block),
            _ => from_mat(u, ldu, &block),
        }
    }
    if jvt != b'N' {
        let full = svd.vt();
        let rows = if jvt == b'A' { n } else { k };
        let block = crate::mat_from_fn(rows, n, |i, j| full[(i, j)]);
        match jvt {
            b'O' => from_mat(a, lda, &block),
            _ => from_mat(vt, ldvt, &block),
        }
    }
    0
}

/// `DGESDD`: one `jobz` for both factors (`"A"`, `"S"`, `"O"`, `"N"`). For `"O"`
/// LAPACK overwrites `A` with `U` when `m >= n` and with `V^T` otherwise, and
/// returns the other factor in full.
#[allow(clippy::too_many_arguments)]
pub fn dgesdd(
    jobz: &str,
    m: usize,
    n: usize,
    a: &mut [f64],
    lda: usize,
    s: &mut [f64],
    u: &mut [f64],
    ldu: usize,
    vt: &mut [f64],
    ldvt: usize,
) -> i32 {
    let (ju, jvt) = match opt(jobz) {
        b'O' if m >= n => ("O", "A"),
        b'O' => ("A", "O"),
        b'A' => ("A", "A"),
        b'S' => ("S", "S"),
        _ => ("N", "N"),
    };
    dgesvd(ju, jvt, m, n, a, lda, s, u, ldu, vt, ldvt)
}
