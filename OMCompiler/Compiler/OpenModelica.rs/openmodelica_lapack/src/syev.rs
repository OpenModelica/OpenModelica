//! The symmetric eigenproblem: `DSYEVX`/`DSYGVX` with `RANGE = 'A'`.
//!
//! Translated from the reference `DSYTD2` + `DORGTR` + `DSTEQR`, the path `DSYEVX`
//! takes when every eigenvalue is wanted and `ABSTOL <= 0`. Step for step, because
//! an eigenvector's *sign* is decided by the algorithm and nothing else: a caller
//! that reports eigenvectors — PRIMME's Ritz vectors, and through them the singular
//! vectors `LOG_NLS_SVD` prints — sees a different answer from any other correct
//! decomposition.
//!
//! `DSYTRD` is unblocked at the orders reached here (`n <= nb`), so `DSYTD2` is it.

use crate::blas::{daxpy, ddot, dlarfg, dscal};
use crate::hqr::{dlapy2, dlartg, dlascl};
use crate::{abs, chol, sqrt, SAFMIN};

/// `DSTEQR`'s iteration budget per eigenvalue.
const MAXIT: usize = 30;

/// The stored triangle as a full symmetric matrix, column-major.
fn full(upper: bool, n: usize, a: &[f64], lda: usize) -> Vec<f64> {
    let mut m = vec![0.0f64; n * n];
    for j in 0..n {
        for i in 0..n {
            let (r, c) = if (i <= j) == upper { (i, j) } else { (j, i) };
            m[j * n + i] = a[c * lda + r];
        }
    }
    m
}

/// `DLARF('Left', …)` with `v` given in full — `DORG2L`'s reflector carries its
/// unit entry at the bottom, not the top.
fn dlarf_left(v: &[f64], tau: f64, m: usize, n: usize, c: &mut [f64], ldc: usize) {
    if tau == 0.0 || m == 0 {
        return;
    }
    for j in 0..n {
        let s = ddot(v, &c[j * ldc..j * ldc + m]);
        if s == 0.0 {
            continue;
        }
        daxpy(-tau * s, v, &mut c[j * ldc..j * ldc + m]);
    }
}

/// `DSYMV`: `y := alpha * A * x`, reading only the `upper` (or lower) triangle.
fn dsymv(upper: bool, n: usize, alpha: f64, a: &[f64], lda: usize, x: &[f64], y: &mut [f64]) {
    for (i, yi) in y.iter_mut().enumerate().take(n) {
        let mut s = 0.0;
        for (j, xj) in x.iter().enumerate().take(n) {
            let (r, c) = if (i <= j) == upper { (i, j) } else { (j, i) };
            s += a[c * lda + r] * xj;
        }
        *yi = alpha * s;
    }
}

/// `DSYR2`: `A := alpha * (x y' + y x') + A` over the stored triangle.
fn dsyr2(upper: bool, n: usize, alpha: f64, x: &[f64], y: &[f64], a: &mut [f64], lda: usize) {
    for j in 0..n {
        for i in 0..n {
            if (i <= j) != upper && i != j {
                continue;
            }
            a[j * lda + i] += alpha * (x[i] * y[j] + y[i] * x[j]);
        }
    }
}

/// `DSYTD2`: reduce the symmetric `A` to tridiagonal form `Q' A Q = T`, leaving the
/// reflectors that make up `Q` in `A` and `tau`.
fn dsytd2(upper: bool, n: usize, a: &mut [f64], lda: usize, d: &mut [f64], e: &mut [f64], tau: &mut [f64]) {
    let mut w = vec![0.0f64; n];
    if upper {
        for i in (1..n).rev() {
            // Annihilate A(1:i-1, i+1); the reflector's unit entry is A(i, i+1).
            let col = i * lda;
            let head = a[col + i - 1];
            let (beta, taui) = dlarfg(head, &mut a[col..col + i - 1]);
            a[col + i - 1] = beta;
            e[i - 1] = beta;
            if taui != 0.0 {
                a[col + i - 1] = 1.0;
                let v: Vec<f64> = a[col..col + i].to_vec();
                dsymv(true, i, taui, a, lda, &v, &mut w[..i]);
                let alpha = -0.5 * taui * ddot(&w[..i], &v);
                daxpy(alpha, &v, &mut w[..i]);
                let wv = w[..i].to_vec();
                dsyr2(true, i, -1.0, &v, &wv, a, lda);
                a[col + i - 1] = e[i - 1];
            }
            d[i] = a[col + i];
            tau[i - 1] = taui;
        }
        d[0] = a[0];
    } else {
        for i in 0..n - 1 {
            // Annihilate A(i+2:n, i); the unit entry is A(i+1, i).
            let col = i * lda;
            let head = a[col + i + 1];
            let (beta, taui) = dlarfg(head, &mut a[col + i + 2..col + n]);
            a[col + i + 1] = beta;
            e[i] = beta;
            if taui != 0.0 {
                a[col + i + 1] = 1.0;
                let m = n - i - 1;
                let v: Vec<f64> = a[col + i + 1..col + n].to_vec();
                let base = (i + 1) * lda + i + 1;
                dsymv(false, m, taui, &a[base..], lda, &v, &mut w[..m]);
                let alpha = -0.5 * taui * ddot(&w[..m], &v);
                daxpy(alpha, &v, &mut w[..m]);
                let wv = w[..m].to_vec();
                dsyr2(false, m, -1.0, &v, &wv, &mut a[base..], lda);
                a[col + i + 1] = e[i];
            }
            d[i] = a[col + i];
            tau[i] = taui;
        }
        d[n - 1] = a[(n - 1) * lda + n - 1];
    }
}

/// `DORGTR`: form `Q` from what [`dsytd2`] left in `a`/`tau`, in place.
fn dorgtr(upper: bool, n: usize, a: &mut [f64], lda: usize, tau: &[f64]) {
    if n == 0 {
        return;
    }
    if n == 1 {
        a[0] = 1.0;
        return;
    }
    let k = n - 1;
    if upper {
        for j in 0..k {
            for i in 0..j {
                a[j * lda + i] = a[(j + 1) * lda + i];
            }
            a[j * lda + n - 1] = 0.0;
        }
        for i in 0..k {
            a[(n - 1) * lda + i] = 0.0;
        }
        a[(n - 1) * lda + n - 1] = 1.0;
        dorg2l(k, k, k, a, lda, tau);
    } else {
        for j in (1..n).rev() {
            a[j * lda] = 0.0;
            for i in j + 1..n {
                a[j * lda + i] = a[(j - 1) * lda + i];
            }
        }
        a[0] = 1.0;
        for i in 1..n {
            a[i] = 0.0;
        }
        let sub = &mut a[lda + 1..];
        dorg2r(k, k, k, sub, lda, tau);
    }
}

/// `DORG2L`: the last `k` columns of `Q = H(1) … H(k)`, `Q` being `m × n`.
fn dorg2l(m: usize, n: usize, k: usize, a: &mut [f64], lda: usize, tau: &[f64]) {
    for j in 0..n - k {
        for l in 0..m {
            a[j * lda + l] = 0.0;
        }
        a[j * lda + m - n + j] = 1.0;
    }
    for i in 0..k {
        let ii = n - k + i;
        let rows = m - n + ii + 1;
        a[ii * lda + rows - 1] = 1.0;
        let v: Vec<f64> = (0..rows).map(|l| a[ii * lda + l]).collect();
        dlarf_left(&v, tau[i], rows, ii, a, lda);
        dscal(-tau[i], &mut a[ii * lda..ii * lda + rows - 1]);
        a[ii * lda + rows - 1] = 1.0 - tau[i];
        for l in rows..m {
            a[ii * lda + l] = 0.0;
        }
    }
}

/// `DORG2R`: the first `k` columns of `Q = H(1) … H(k)`.
fn dorg2r(m: usize, n: usize, k: usize, a: &mut [f64], lda: usize, tau: &[f64]) {
    for j in k..n {
        for l in 0..m {
            a[j * lda + l] = 0.0;
        }
        a[j * lda + j] = 1.0;
    }
    for i in (0..k).rev() {
        if i + 1 < n {
            a[i * lda + i] = 1.0;
            let v: Vec<f64> = (0..m - i).map(|l| a[i * lda + i + l]).collect();
            let sub = &mut a[(i + 1) * lda + i..];
            dlarf_left(&v, tau[i], m - i, n - i - 1, sub, lda);
        }
        if i + 1 < m {
            dscal(-tau[i], &mut a[i * lda + i + 1..i * lda + m]);
        }
        a[i * lda + i] = 1.0 - tau[i];
        for l in 0..i {
            a[i * lda + l] = 0.0;
        }
    }
}

/// `DLAEV2`: the eigenvalues of `[a b; b c]`, larger first, plus the rotation
/// `(cs1, sn1)` whose first column is the eigenvector for `rt1`.
fn dlaev2(a: f64, b: f64, c: f64) -> (f64, f64, f64, f64) {
    let (sm, df) = (a + c, a - c);
    let adf = abs(df);
    let tb = b + b;
    let ab = abs(tb);
    let (acmx, acmn) = if abs(a) > abs(c) { (a, c) } else { (c, a) };
    let rt = if adf > ab {
        adf * sqrt(1.0 + (ab / adf) * (ab / adf))
    } else if adf < ab {
        ab * sqrt(1.0 + (adf / ab) * (adf / ab))
    } else {
        ab * sqrt(2.0)
    };
    let (rt1, rt2, sgn1) = if sm < 0.0 {
        let rt1 = 0.5 * (sm - rt);
        (rt1, (acmx / rt1) * acmn - (b / rt1) * b, -1)
    } else if sm > 0.0 {
        let rt1 = 0.5 * (sm + rt);
        (rt1, (acmx / rt1) * acmn - (b / rt1) * b, 1)
    } else {
        (0.5 * rt, -0.5 * rt, 1)
    };
    let (cs, sgn2) = if df >= 0.0 { (df + rt, 1) } else { (df - rt, -1) };
    let acs = abs(cs);
    let (mut cs1, mut sn1) = if acs > ab {
        let ct = -tb / cs;
        let sn1 = 1.0 / sqrt(1.0 + ct * ct);
        (ct * sn1, sn1)
    } else if ab == 0.0 {
        (1.0, 0.0)
    } else {
        let tn = -cs / tb;
        let cs1 = 1.0 / sqrt(1.0 + tn * tn);
        (cs1, tn * cs1)
    };
    if sgn1 == sgn2 {
        let tn = cs1;
        cs1 = -sn1;
        sn1 = tn;
    }
    (rt1, rt2, cs1, sn1)
}

/// `DLASR('R', 'V', direct, …)`: apply the plane rotations `(c, s)` to `a` from
/// the right, rotating adjacent column pairs.
fn dlasr_right(forward: bool, m: usize, n: usize, c: &[f64], s: &[f64], a: &mut [f64], lda: usize) {
    if n <= 1 {
        return;
    }
    let apply = |j: usize, a: &mut [f64]| {
        let (ct, st) = (c[j], s[j]);
        if ct == 1.0 && st == 0.0 {
            return;
        }
        for i in 0..m {
            let temp = a[(j + 1) * lda + i];
            a[(j + 1) * lda + i] = ct * temp - st * a[j * lda + i];
            a[j * lda + i] = st * temp + ct * a[j * lda + i];
        }
    };
    if forward {
        for j in 0..n - 1 {
            apply(j, a);
        }
    } else {
        for j in (0..n - 1).rev() {
            apply(j, a);
        }
    }
}

/// `DLANST('M', …)`.
fn dlanst(d: &[f64], e: &[f64]) -> f64 {
    d.iter().chain(e).fold(0.0f64, |m, v| f64::max(m, abs(*v)))
}

/// `DSTEQR` with `COMPZ = 'V'`: the eigenvalues of the tridiagonal `(d, e)`,
/// ascending, with `z` post-multiplied by the accumulated rotations. Indices
/// follow the reference's 1-based ones.
fn dsteqr(n: usize, d: &mut [f64], e: &mut [f64], z: &mut [f64], ldz: usize) -> i32 {
    if n == 0 {
        return 0;
    }
    if n == 1 {
        return 0;
    }
    let eps = f64::EPSILON / 2.0;
    let eps2 = eps * eps;
    let safmax = 1.0 / SAFMIN;
    let ssfmax = sqrt(safmax) / 3.0;
    let ssfmin = sqrt(SAFMIN) / eps2;
    let mut info = 0;

    let mut cs = vec![0.0f64; n + 1];
    let mut sn = vec![0.0f64; n + 1];

    let nmaxit = n * MAXIT;
    let mut jtot = 0usize;
    let mut l1 = 1usize;

    'outer: loop {
        if l1 > n {
            break;
        }
        if l1 > 1 {
            e[l1 - 2] = 0.0;
        }
        let mut m = n;
        if l1 <= n - 1 {
            let mut found = false;
            for k in l1..=n - 1 {
                let tst = abs(e[k - 1]);
                if tst == 0.0 {
                    m = k;
                    found = true;
                    break;
                }
                if tst <= (sqrt(abs(d[k - 1])) * sqrt(abs(d[k]))) * eps {
                    e[k - 1] = 0.0;
                    m = k;
                    found = true;
                    break;
                }
            }
            if !found {
                m = n;
            }
        }

        let mut l = l1;
        let lsv = l;
        let mut lend = m;
        let lendsv = lend;
        l1 = m + 1;
        if lend == l {
            continue;
        }

        let anorm = dlanst(&d[l - 1..lend], &e[l - 1..lend - 1]);
        let mut iscale = 0;
        if anorm == 0.0 {
            continue;
        }
        if anorm > ssfmax {
            iscale = 1;
            dlascl(anorm, ssfmax, &mut d[l - 1..lend]);
            dlascl(anorm, ssfmax, &mut e[l - 1..lend - 1]);
        } else if anorm < ssfmin {
            iscale = 2;
            dlascl(anorm, ssfmin, &mut d[l - 1..lend]);
            dlascl(anorm, ssfmin, &mut e[l - 1..lend - 1]);
        }

        if abs(d[lend - 1]) < abs(d[l - 1]) {
            lend = lsv;
            l = lendsv;
        }

        if lend > l {
            // QL iteration.
            loop {
                let mut m = lend;
                if l != lend {
                    let mut found = false;
                    for k in l..=lend - 1 {
                        let tst = e[k - 1] * e[k - 1];
                        if tst <= (eps2 * abs(d[k - 1])) * abs(d[k]) + SAFMIN {
                            m = k;
                            found = true;
                            break;
                        }
                    }
                    if !found {
                        m = lend;
                    }
                }
                if m < lend {
                    e[m - 1] = 0.0;
                }
                let mut p = d[l - 1];
                if m == l {
                    d[l - 1] = p;
                    l += 1;
                    if l <= lend {
                        continue;
                    }
                    break;
                }
                if m == l + 1 {
                    let (rt1, rt2, c, s) = dlaev2(d[l - 1], e[l - 1], d[l]);
                    cs[l] = c;
                    sn[l] = s;
                    dlasr_right(false, n, 2, &cs[l..], &sn[l..], &mut z[(l - 1) * ldz..], ldz);
                    d[l - 1] = rt1;
                    d[l] = rt2;
                    e[l - 1] = 0.0;
                    l += 2;
                    if l <= lend {
                        continue;
                    }
                    break;
                }
                if jtot == nmaxit {
                    break;
                }
                jtot += 1;

                let mut g = (d[l] - p) / (2.0 * e[l - 1]);
                let mut r = dlapy2(g, 1.0);
                g = d[m - 1] - p + (e[l - 1] / (g + libm::copysign(r, g)));
                let mut s = 1.0;
                let mut c = 1.0;
                p = 0.0;
                for i in (l..=m - 1).rev() {
                    let f = s * e[i - 1];
                    let b = c * e[i - 1];
                    let (c2, s2, r2) = dlartg(g, f);
                    c = c2;
                    s = s2;
                    r = r2;
                    if i != m - 1 {
                        e[i] = r;
                    }
                    g = d[i] - p;
                    r = (d[i - 1] - g) * s + 2.0 * c * b;
                    p = s * r;
                    d[i] = g + p;
                    g = c * r - b;
                    cs[i] = c;
                    sn[i] = -s;
                }
                let mm = m - l + 1;
                dlasr_right(false, n, mm, &cs[l..], &sn[l..], &mut z[(l - 1) * ldz..], ldz);
                d[l - 1] -= p;
                e[l - 1] = g;
            }
        } else {
            // QR iteration.
            loop {
                let mut m = lend;
                if l != lend {
                    let mut found = false;
                    let mut k = l;
                    while k >= lend + 1 {
                        let tst = e[k - 2] * e[k - 2];
                        if tst <= (eps2 * abs(d[k - 1])) * abs(d[k - 2]) + SAFMIN {
                            m = k;
                            found = true;
                            break;
                        }
                        k -= 1;
                    }
                    if !found {
                        m = lend;
                    }
                }
                if m > lend {
                    e[m - 2] = 0.0;
                }
                let mut p = d[l - 1];
                if m == l {
                    d[l - 1] = p;
                    if l == lend {
                        break;
                    }
                    l -= 1;
                    if l >= lend {
                        continue;
                    }
                    break;
                }
                if m + 1 == l {
                    let (rt1, rt2, c, s) = dlaev2(d[l - 2], e[l - 2], d[l - 1]);
                    cs[m] = c;
                    sn[m] = s;
                    dlasr_right(true, n, 2, &cs[m..], &sn[m..], &mut z[(l - 2) * ldz..], ldz);
                    d[l - 2] = rt1;
                    d[l - 1] = rt2;
                    e[l - 2] = 0.0;
                    l -= 2;
                    if l >= lend {
                        continue;
                    }
                    break;
                }
                if jtot == nmaxit {
                    break;
                }
                jtot += 1;

                let mut g = (d[l - 2] - p) / (2.0 * e[l - 2]);
                let mut r = dlapy2(g, 1.0);
                g = d[m - 1] - p + (e[l - 2] / (g + libm::copysign(r, g)));
                let mut s = 1.0;
                let mut c = 1.0;
                p = 0.0;
                for i in m..=l - 1 {
                    let f = s * e[i - 1];
                    let b = c * e[i - 1];
                    let (c2, s2, r2) = dlartg(g, f);
                    c = c2;
                    s = s2;
                    r = r2;
                    if i != m {
                        e[i - 2] = r;
                    }
                    g = d[i - 1] - p;
                    r = (d[i] - g) * s + 2.0 * c * b;
                    p = s * r;
                    d[i - 1] = g + p;
                    g = c * r - b;
                    cs[i] = c;
                    sn[i] = s;
                }
                let mm = l - m + 1;
                dlasr_right(true, n, mm, &cs[m..], &sn[m..], &mut z[(m - 1) * ldz..], ldz);
                d[l - 1] -= p;
                e[l - 2] = g;
            }
        }

        if iscale == 1 {
            dlascl(ssfmax, anorm, &mut d[lsv - 1..lendsv]);
            dlascl(ssfmax, anorm, &mut e[lsv - 1..lendsv - 1]);
        } else if iscale == 2 {
            dlascl(ssfmin, anorm, &mut d[lsv - 1..lendsv]);
            dlascl(ssfmin, anorm, &mut e[lsv - 1..lendsv - 1]);
        }

        if jtot >= nmaxit {
            for k in 0..n - 1 {
                if e[k] != 0.0 {
                    info += 1;
                }
            }
            break 'outer;
        }
    }

    if info != 0 {
        return info;
    }
    // Selection sort, which moves the fewest eigenvectors.
    for ii in 2..=n {
        let i = ii - 1;
        let mut k = i;
        let mut p = d[i - 1];
        for j in ii..=n {
            if d[j - 1] < p {
                k = j;
                p = d[j - 1];
            }
        }
        if k != i {
            d[k - 1] = d[i - 1];
            d[i - 1] = p;
            for r in 0..n {
                z.swap((i - 1) * ldz + r, (k - 1) * ldz + r);
            }
        }
    }
    0
}

/// All eigenvalues (ascending) and eigenvectors of the symmetric matrix in the
/// `upper` (or lower) triangle of `a`: `DSYEVX` with `RANGE = 'A'` and
/// `ABSTOL <= 0`. `z` is `n × n` with leading dimension `ldz`; `None` for
/// eigenvalues alone. Returns LAPACK's `INFO`.
pub fn dsyevx(upper: bool, n: usize, a: &[f64], lda: usize, w: &mut [f64], z: Option<(&mut [f64], usize)>) -> i32 {
    if n == 0 {
        return 0;
    }
    if n == 1 {
        w[0] = a[0];
        if let Some((z, _)) = z {
            z[0] = 1.0;
        }
        return 0;
    }
    // C's `DLANSY('M', …)` then the `RMIN`/`RMAX` window.
    let smlnum = SAFMIN / f64::EPSILON;
    let rmin = sqrt(smlnum);
    let rmax = f64::min(sqrt(1.0 / smlnum), 1.0 / sqrt(sqrt(SAFMIN)));
    let mut work = full(upper, n, a, lda);
    let anrm = work.iter().fold(0.0f64, |m, v| f64::max(m, abs(*v)));
    let mut sigma = 1.0;
    if anrm > 0.0 && anrm < rmin {
        sigma = rmin / anrm;
    } else if anrm > rmax {
        sigma = rmax / anrm;
    }
    if sigma != 1.0 {
        for v in work.iter_mut() {
            *v *= sigma;
        }
    }

    let (mut d, mut e, mut tau) = (vec![0.0f64; n], vec![0.0f64; n], vec![0.0f64; n]);
    dsytd2(upper, n, &mut work, n, &mut d, &mut e, &mut tau);

    let info = match z {
        None => {
            // `DSTERF`'s answer, by the same iteration with no vectors to carry.
            let mut zz = vec![0.0f64; n * n];
            dsteqr(n, &mut d, &mut e, &mut zz, n)
        }
        Some((z, ldz)) => {
            for j in 0..n {
                for i in 0..n {
                    z[j * ldz + i] = work[j * n + i];
                }
            }
            dorgtr(upper, n, z, ldz, &tau);
            dsteqr(n, &mut d, &mut e, z, ldz)
        }
    };
    if info != 0 {
        return info;
    }
    for (i, v) in w.iter_mut().enumerate().take(n) {
        *v = if sigma != 1.0 { d[i] / sigma } else { d[i] };
    }
    0
}

/// `DSYGS2` with `ITYPE = 1`: reduce `A x = lambda B x` to standard form in place,
/// `B` holding the Cholesky factor of the same triangle.
fn dsygst(upper: bool, n: usize, a: &mut [f64], lda: usize, b: &[f64], ldb: usize) {
    for k in 0..n {
        let bkk = b[k * ldb + k];
        let akk = a[k * lda + k] / (bkk * bkk);
        a[k * lda + k] = akk;
        if k + 1 >= n {
            continue;
        }
        // The k-th row (upper) or column (lower) of the trailing block, gathered so
        // the rank-2 update and the triangular solve see a contiguous vector.
        let m = n - k - 1;
        let at = |i: usize| if upper { (k + 1 + i) * lda + k } else { k * lda + k + 1 + i };
        let bt = |i: usize| if upper { (k + 1 + i) * ldb + k } else { k * ldb + k + 1 + i };
        let mut av: Vec<f64> = (0..m).map(|i| a[at(i)]).collect();
        let bv: Vec<f64> = (0..m).map(|i| b[bt(i)]).collect();
        dscal(1.0 / bkk, &mut av);
        let ct = -0.5 * akk;
        daxpy(ct, &bv, &mut av);
        dsyr2(upper, m, -1.0, &av, &bv, &mut a[(k + 1) * lda + k + 1..], lda);
        daxpy(ct, &bv, &mut av);
        // `DTRSV`: `U' y = x` for the upper factor, `L y = x` for the lower one.
        let sub = &b[(k + 1) * ldb + k + 1..];
        for i in 0..m {
            let mut sum = av[i];
            for j in 0..i {
                sum -= if upper { sub[i * ldb + j] } else { sub[j * ldb + i] } * av[j];
            }
            av[i] = sum / sub[i * ldb + i];
        }
        for (i, v) in av.iter().enumerate() {
            a[at(i)] = *v;
        }
    }
}

/// `DSYGVX` with `RANGE = 'A'` and `ITYPE = 1`: `A x = lambda B x` for symmetric
/// `A` and positive-definite `B`, by `DPOTRF` + `DSYGST` + [`dsyevx`], then C's
/// back-transform `x = inv(U) y` (upper) or `inv(L') y` (lower).
pub fn dsygvx(
    upper: bool, n: usize, a: &[f64], lda: usize, b: &[f64], ldb: usize,
    w: &mut [f64], z: Option<(&mut [f64], usize)>,
) -> i32 {
    let mut bf = b[..ldb * n].to_vec();
    let info = chol::dpotrf(if upper { "U" } else { "L" }, n, &mut bf, ldb);
    if info != 0 {
        return n as i32 + info;
    }
    let mut af = a[..lda * n].to_vec();
    dsygst(upper, n, &mut af, lda, &bf, ldb);
    match z {
        None => dsyevx(upper, n, &af, lda, w, None),
        Some((z, ldz)) => {
            let info = dsyevx(upper, n, &af, lda, w, Some((z, ldz)));
            if info != 0 {
                return info;
            }
            // `DTRSM('Left', uplo, trans, 'Non-unit')`: `U x = y` / `L' x = y`, an
            // upper-triangular back substitution either way.
            for k in 0..n {
                let col = &mut z[k * ldz..k * ldz + n];
                for i in (0..n).rev() {
                    let mut sum = col[i];
                    for j in i + 1..n {
                        sum -= if upper { bf[j * ldb + i] } else { bf[i * ldb + j] } * col[j];
                    }
                    col[i] = sum / bf[i * ldb + i];
                }
            }
            0
        }
    }
}

