//! `DGESVD` and `DGESDD`, from reference `DGESVD`'s general path.
//!
//! Reference LAPACK reaches the same decomposition through a QR (or LQ)
//! factorization first when one dimension is more than about 1.6 times the
//! other. That is a shortcut for its blocked kernels; the unblocked ones here
//! have nothing to gain from it.

use crate::bdsqr::dbdsqr;
use crate::bidiag::{dgebd2, dorgbr};
use crate::hqr::dlascl;
use crate::{dlacpy, dlange, opt, sqrt, PREC, SAFMIN};

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
    #[cfg(feature = "faer-backend")]
    return crate::faer_backend::dgesvd(jobu, jobvt, m, n, a, lda, s, u, ldu, vt, ldvt);
    #[cfg(not(feature = "faer-backend"))]
    dgesvd_ref(jobu, jobvt, m, n, a, lda, s, u, ldu, vt, ldvt)
}

/// The port of reference `DGESVD`, kept as the faer-free fallback.
#[allow(clippy::too_many_arguments)]
pub fn dgesvd_ref(
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
    let (ju, jvt) = (opt(jobu), opt(jobvt));
    let (wntua, wntus, wntuo, wntun) =
        (ju == b'A', ju == b'S', ju == b'O', ju == b'N');
    let (wntva, wntvs, wntvo, wntvn) =
        (jvt == b'A', jvt == b'S', jvt == b'O', jvt == b'N');
    let (wntuas, wntvas) = (wntua || wntus, wntva || wntvs);
    if !(wntua || wntus || wntuo || wntun) {
        return -1;
    }
    if !(wntva || wntvs || wntvo || wntvn) || (wntvo && wntuo) {
        return -2;
    }
    let minmn = m.min(n);
    if minmn == 0 {
        return 0;
    }

    // The bidiagonal iteration's absolute thresholds only mean what they should
    // in this range; `s` is scaled back at the end.
    let smlnum = sqrt(SAFMIN) / PREC;
    let bignum = 1.0 / smlnum;
    let anrm = dlange("M", m, n, a, lda);
    let mut iscl = false;
    if anrm > 0.0 && anrm < smlnum {
        iscl = true;
        dlascl_mat(anrm, smlnum, m, n, a, lda);
    } else if anrm > bignum {
        iscl = true;
        dlascl_mat(anrm, bignum, m, n, a, lda);
    }

    let mut e = vec![0.0f64; minmn];
    let mut tauq = vec![0.0f64; minmn];
    let mut taup = vec![0.0f64; minmn];
    dgebd2(m, n, a, lda, s, &mut e, &mut tauq, &mut taup);

    let info;
    if m >= n {
        if wntuas {
            dlacpy(b'L', m, n, a, lda, u, ldu);
            let ncu = if wntus { n } else { m };
            dorgbr("Q", m, ncu, n, u, ldu, &tauq);
        }
        if wntvas {
            dlacpy(b'U', n, n, a, lda, vt, ldvt);
            dorgbr("P", n, n, n, vt, ldvt, &taup);
        }
        if wntuo {
            dorgbr("Q", m, n, n, a, lda, &tauq);
        }
        if wntvo {
            dorgbr("P", n, n, n, a, lda, &taup);
        }
        let nru = if wntun { 0 } else { m };
        let ncvt = if wntvn { 0 } else { n };
        info = if wntvo {
            dbdsqr("U", n, ncvt, nru, s, &mut e, a, lda, u, ldu)
        } else if wntuo {
            dbdsqr("U", n, ncvt, nru, s, &mut e, vt, ldvt, a, lda)
        } else {
            dbdsqr("U", n, ncvt, nru, s, &mut e, vt, ldvt, u, ldu)
        };
    } else {
        if wntuas {
            dlacpy(b'L', m, m, a, lda, u, ldu);
            dorgbr("Q", m, m, n, u, ldu, &tauq);
        }
        if wntvas {
            dlacpy(b'U', m, n, a, lda, vt, ldvt);
            let nrvt = if wntva { n } else { m };
            dorgbr("P", nrvt, n, m, vt, ldvt, &taup);
        }
        if wntuo {
            dorgbr("Q", m, m, n, a, lda, &tauq);
        }
        if wntvo {
            dorgbr("P", m, n, m, a, lda, &taup);
        }
        let nru = if wntun { 0 } else { m };
        let ncvt = if wntvn { 0 } else { n };
        info = if wntvo {
            dbdsqr("L", m, ncvt, nru, s, &mut e, a, lda, u, ldu)
        } else if wntuo {
            dbdsqr("L", m, ncvt, nru, s, &mut e, vt, ldvt, a, lda)
        } else {
            dbdsqr("L", m, ncvt, nru, s, &mut e, vt, ldvt, u, ldu)
        };
    }

    if iscl {
        if anrm > bignum {
            dlascl(bignum, anrm, &mut s[..minmn]);
        } else {
            dlascl(smlnum, anrm, &mut s[..minmn]);
        }
    }
    info
}

/// `DLASCL('G', …)` over an `m`×`n` submatrix. Its multipliers depend only on
/// `cfrom`/`cto`, so column by column gives the reference's single pass.
fn dlascl_mat(cfrom: f64, cto: f64, m: usize, n: usize, a: &mut [f64], lda: usize) {
    for j in 0..n {
        dlascl(cfrom, cto, &mut a[j * lda..j * lda + m]);
    }
}

/// `DGESDD`: one `jobz` for both factors (`"A"`, `"S"`, `"O"`, `"N"`). For `"O"`
/// LAPACK overwrites `A` with `U` when `m >= n` and with `V^T` otherwise, and
/// returns the other factor in full.
///
/// Reference `DGESDD` runs divide-and-conquer where [`dgesvd`] runs QR; the
/// decomposition is the same, so this is `dgesvd` under the `jobz` mapping.
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
