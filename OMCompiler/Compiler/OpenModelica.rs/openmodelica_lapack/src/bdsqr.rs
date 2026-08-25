//! `DBDSQR`, `DLAS2`, `DLASV2`, `DLASR`, translated from the reference LAPACK.

use crate::dqds::dlasq1;
use crate::hqr::{dlartg, drot};
use crate::{abs, opt, sqrt, EPS, SAFMIN};

/// `DLAS2`: the singular values `(ssmin, ssmax)` of the 2x2 upper triangular
/// matrix `[f g; 0 h]`.
pub(crate) fn dlas2(f: f64, g: f64, h: f64) -> (f64, f64) {
    let (fa, ga, ha) = (abs(f), abs(g), abs(h));
    let fhmn = fa.min(ha);
    let fhmx = fa.max(ha);
    if fhmn == 0.0 {
        let ssmax = if fhmx == 0.0 {
            ga
        } else {
            let (big, small) = (fhmx.max(ga), fhmx.min(ga));
            big * sqrt(1.0 + (small / big) * (small / big))
        };
        return (0.0, ssmax);
    }
    if ga < fhmx {
        let as_ = 1.0 + fhmn / fhmx;
        let at = (fhmx - fhmn) / fhmx;
        let au = (ga / fhmx) * (ga / fhmx);
        let c = 2.0 / (sqrt(as_ * as_ + au) + sqrt(at * at + au));
        (fhmn * c, fhmx / c)
    } else {
        let au = fhmx / ga;
        if au == 0.0 {
            // ga is so large that fhmx/ga underflowed; the product still fits.
            ((fhmn * fhmx) / ga, ga)
        } else {
            let as_ = 1.0 + fhmn / fhmx;
            let at = (fhmx - fhmn) / fhmx;
            let c = 1.0 / (sqrt(1.0 + (as_ * au) * (as_ * au)) + sqrt(1.0 + (at * au) * (at * au)));
            let ssmin = (fhmn * c) * au;
            (ssmin + ssmin, ga / (c + c))
        }
    }
}

/// `DLASV2`: the SVD of the 2x2 upper triangular `[f g; 0 h]`, as
/// `(ssmin, ssmax, snr, csr, snl, csl)` with `|ssmax| >= |ssmin|`. The signs are
/// LAPACK's: the rotations give `diag(ssmax, ssmin)`, not its absolute value.
pub(crate) fn dlasv2(f: f64, g: f64, h: f64) -> (f64, f64, f64, f64, f64, f64) {
    let (mut ft, mut ht) = (f, h);
    let (mut fa, mut ha) = (abs(f), abs(h));
    let mut pmax = 1;
    let swap = ha > fa;
    if swap {
        pmax = 3;
        core::mem::swap(&mut ft, &mut ht);
        core::mem::swap(&mut fa, &mut ha);
    }
    let gt = g;
    let ga = abs(gt);

    let (ssmin, ssmax, clt, crt, slt, srt);
    if ga == 0.0 {
        (ssmin, ssmax, clt, crt, slt, srt) = (ha, fa, 1.0, 1.0, 0.0, 0.0);
    } else if ga > fa && (fa / ga) < EPS {
        // Numerically [0 g; 0 h].
        pmax = 2;
        ssmax = ga;
        ssmin = if ha > 1.0 { fa / (ga / ha) } else { (fa / ga) * ha };
        (clt, slt, srt, crt) = (1.0, ht / gt, 1.0, ft / gt);
    } else {
        if ga > fa {
            pmax = 2;
        }
        let d = fa - ha;
        let mut l = if d == fa { 1.0 } else { d / fa };
        let m = gt / ft;
        let mut t = 2.0 - l;
        let mm = m * m;
        let tt = t * t;
        let s = sqrt(tt + mm);
        let r = if l == 0.0 { abs(m) } else { sqrt(l * l + mm) };
        let a = 0.5 * (s + r);
        ssmin = ha / a;
        ssmax = fa * a;
        if mm == 0.0 {
            t = if l == 0.0 {
                sign(2.0, ft) * sign(1.0, gt)
            } else {
                gt / sign(d, ft) + m / t
            };
        } else {
            t = (m / (s + t) + m / (r + l)) * (1.0 + a);
        }
        l = sqrt(t * t + 4.0);
        crt = 2.0 / l;
        srt = t / l;
        clt = (crt + srt * m) / a;
        slt = (ht / ft) * srt / a;
    }

    let (csl, snl, csr, snr) = if swap { (srt, crt, slt, clt) } else { (clt, slt, crt, srt) };
    // The largest entry decides the sign the singular values must carry.
    let tsign = match pmax {
        1 => sign(1.0, csr) * sign(1.0, csl) * sign(1.0, f),
        2 => sign(1.0, snr) * sign(1.0, csl) * sign(1.0, g),
        _ => sign(1.0, snr) * sign(1.0, snl) * sign(1.0, h),
    };
    (
        sign(ssmin, tsign * sign(1.0, f) * sign(1.0, h)),
        sign(ssmax, tsign),
        snr,
        csr,
        snl,
        csl,
    )
}

fn sign(x: f64, y: f64) -> f64 {
    libm::copysign(x, y)
}

/// `DLASR('L', 'V', …)`: apply the plane rotations `(c[j], s[j])` in the
/// `(j, j+1)` planes to the rows of the `m`×`n` matrix `a`, in increasing
/// (`forward`) or decreasing order.
fn dlasr_left(forward: bool, m: usize, n: usize, c: &[f64], s: &[f64], a: &mut [f64], lda: usize) {
    if m == 0 || n == 0 {
        return;
    }
    for k in 0..m - 1 {
        let j = if forward { k } else { m - 2 - k };
        let (ct, st) = (c[j], s[j]);
        if ct == 1.0 && st == 0.0 {
            continue;
        }
        for i in 0..n {
            let temp = a[j + 1 + i * lda];
            a[j + 1 + i * lda] = ct * temp - st * a[j + i * lda];
            a[j + i * lda] = st * temp + ct * a[j + i * lda];
        }
    }
}

/// `DLASR('R', 'V', …)`: the same rotations against the columns.
fn dlasr_right(forward: bool, m: usize, n: usize, c: &[f64], s: &[f64], a: &mut [f64], lda: usize) {
    if m == 0 || n == 0 {
        return;
    }
    for k in 0..n - 1 {
        let j = if forward { k } else { n - 2 - k };
        let (ct, st) = (c[j], s[j]);
        if ct == 1.0 && st == 0.0 {
            continue;
        }
        for i in 0..m {
            let temp = a[i + (j + 1) * lda];
            a[i + (j + 1) * lda] = ct * temp - st * a[i + j * lda];
            a[i + j * lda] = st * temp + ct * a[i + j * lda];
        }
    }
}

/// `DBDSQR`: the singular values of the `n`×`n` bidiagonal matrix with diagonal
/// `d` and off-diagonal `e`, descending in `d`, with the rotations applied to
/// `VT` (`ncvt` columns) and `U` (`nru` rows) so they become `P'` and `Q`.
///
/// `uplo` is `"U"` or `"L"`. `e` needs `n` elements — the `DLASQ1` path writes
/// `e[n-1]`. Returns `INFO`: the number of off-diagonal entries still
/// unconverged when the iteration limit ran out.
///
/// LAPACK's `NCC`/`C`, a third matrix to rotate, has no user here.
#[allow(clippy::too_many_arguments)]
pub fn dbdsqr(
    uplo: &str,
    n: usize,
    ncvt: usize,
    nru: usize,
    d: &mut [f64],
    e: &mut [f64],
    vt: &mut [f64],
    ldvt: usize,
    u: &mut [f64],
    ldu: usize,
) -> i32 {
    const MAXITR: usize = 6;
    if n == 0 {
        return 0;
    }
    let lower = opt(uplo) == b'L';
    let rotate = ncvt > 0 || nru > 0;
    let mut work = vec![0.0f64; 4 * n];

    if n > 1 {
        if !rotate {
            let info = dlasq1(n, d, e);
            if info != 2 {
                return info;
            }
            // dqds gave up; go on with the rotations it skipped.
        }

        if lower {
            // Rotate into an upper bidiagonal, carrying the rotations into U.
            for i in 0..n - 1 {
                let (cs, sn, r) = dlartg(d[i], e[i]);
                d[i] = r;
                e[i] = sn * d[i + 1];
                d[i + 1] *= cs;
                work[i] = cs;
                work[n - 1 + i] = sn;
            }
            if nru > 0 {
                let (c, s) = work.split_at(n - 1);
                dlasr_right(true, nru, n, c, s, u, ldu);
            }
        }
    }

    // The relative tolerance the deflation tests use, and the absolute floor
    // beneath it.
    let tolmul = 10.0f64.max(100.0f64.min(libm::pow(EPS, -0.125)));
    let tol = tolmul * EPS;
    let mut smax = 0.0f64;
    for v in d[..n].iter() {
        smax = smax.max(abs(*v));
    }
    for v in e[..n.saturating_sub(1)].iter() {
        smax = smax.max(abs(*v));
    }
    let thresh = {
        // A lower bound on the smallest singular value, so the threshold scales
        // with the matrix and not with its largest entry.
        let mut sminoa = abs(d[0]);
        if sminoa != 0.0 {
            let mut mu = sminoa;
            for i in 1..n {
                mu = abs(d[i]) * (mu / (mu + abs(e[i - 1])));
                sminoa = sminoa.min(mu);
                if sminoa == 0.0 {
                    break;
                }
            }
        }
        sminoa /= sqrt(n as f64);
        (tol * sminoa).max(MAXITR as f64 * (n as f64 * (n as f64 * SAFMIN)))
    };

    let maxitdivn = MAXITR * n;
    let mut iterdivn = 0usize;
    let mut iter: i64 = -1;
    let mut oldll: i64 = -1;
    let mut oldm: i64 = -1;
    let mut idir = 0;
    // `m` and `ll` are LAPACK's, one-based: `ll..=m` is the active block.
    let mut m = n;

    let converged = 'qr: loop {
        if m <= 1 {
            break true;
        }
        if iter >= n as i64 {
            iter -= n as i64;
            iterdivn += 1;
            if iterdivn >= maxitdivn {
                break false;
            }
        }

        // Find the bottom of the active block, splitting off a negligible e.
        smax = abs(d[m - 1]);
        let mut ll = 0usize;
        let mut split = false;
        for lll in 1..m {
            let l = m - lll;
            let abss = abs(d[l - 1]);
            let abse = abs(e[l - 1]);
            if abse <= thresh {
                ll = l;
                split = true;
                break;
            }
            smax = smax.max(abss).max(abse);
        }
        if split {
            e[ll - 1] = 0.0;
            if ll == m - 1 {
                m -= 1;
                continue;
            }
        }
        ll += 1;

        if ll == m - 1 {
            let (sigmn, sigmx, sinr, cosr, sinl, cosl) = dlasv2(d[m - 2], e[m - 2], d[m - 1]);
            d[m - 2] = sigmx;
            e[m - 2] = 0.0;
            d[m - 1] = sigmn;
            if ncvt > 0 {
                drot(ncvt, vt, m - 2, ldvt, m - 1, ldvt, cosr, sinr);
            }
            if nru > 0 {
                drot(nru, u, (m - 2) * ldu, 1, (m - 1) * ldu, 1, cosl, sinl);
            }
            m -= 2;
            continue;
        }

        // Chase the bulge from whichever end has the larger diagonal entry.
        if ll as i64 > oldm || (m as i64) < oldll {
            idir = if abs(d[ll - 1]) >= abs(d[m - 1]) { 1 } else { 2 };
        }
        let smin;
        if idir == 1 {
            if abs(e[m - 2]) <= tol * abs(d[m - 1]) {
                e[m - 2] = 0.0;
                continue;
            }
            let mut mu = abs(d[ll - 1]);
            let mut lo = mu;
            for lll in ll..m {
                if abs(e[lll - 1]) <= tol * mu {
                    e[lll - 1] = 0.0;
                    continue 'qr;
                }
                mu = abs(d[lll]) * (mu / (mu + abs(e[lll - 1])));
                lo = lo.min(mu);
            }
            smin = lo;
        } else {
            if abs(e[ll - 1]) <= tol * abs(d[ll - 1]) {
                e[ll - 1] = 0.0;
                continue;
            }
            let mut mu = abs(d[m - 1]);
            let mut lo = mu;
            for lll in (ll..m).rev() {
                if abs(e[lll - 1]) <= tol * mu {
                    e[lll - 1] = 0.0;
                    continue 'qr;
                }
                mu = abs(d[lll - 1]) * (mu / (mu + abs(e[lll - 1])));
                lo = lo.min(mu);
            }
            smin = lo;
        }
        oldll = ll as i64;
        oldm = m as i64;

        // A shift too small to pay for itself is dropped: the zero-shift sweep
        // is the one that keeps tiny singular values.
        let shift = if n as f64 * tol * (smin / smax) <= EPS.max(0.01 * tol) {
            0.0
        } else {
            let (sll, sh) = if idir == 1 {
                (abs(d[ll - 1]), dlas2(d[m - 2], e[m - 2], d[m - 1]).0)
            } else {
                (abs(d[m - 1]), dlas2(d[ll - 1], e[ll - 1], d[ll]).0)
            };
            if sll > 0.0 && (sh / sll) * (sh / sll) < EPS {
                0.0
            } else {
                sh
            }
        };
        iter += (m - ll) as i64;
        let nm1 = n - 1;
        let (nm12, nm13) = (nm1 + nm1, nm1 + nm1 + nm1);

        if shift == 0.0 {
            if idir == 1 {
                let (mut cs, mut oldcs, mut oldsn) = (1.0, 1.0, 0.0);
                for i in ll..m {
                    let (c1, sn, r) = dlartg(d[i - 1] * cs, e[i - 1]);
                    cs = c1;
                    if i > ll {
                        e[i - 2] = oldsn * r;
                    }
                    let (c2, s2, dd) = dlartg(oldcs * r, d[i] * sn);
                    (oldcs, oldsn, d[i - 1]) = (c2, s2, dd);
                    work[i - ll] = cs;
                    work[i - ll + nm1] = sn;
                    work[i - ll + nm12] = oldcs;
                    work[i - ll + nm13] = oldsn;
                }
                let h = d[m - 1] * cs;
                d[m - 1] = h * oldcs;
                e[m - 2] = h * oldsn;
                apply(&work, nm1, nm12, nm13, ll, m, true, ncvt, nru, vt, ldvt, u, ldu);
                if abs(e[m - 2]) <= thresh {
                    e[m - 2] = 0.0;
                }
            } else {
                let (mut cs, mut oldcs, mut oldsn) = (1.0, 1.0, 0.0);
                for i in (ll + 1..=m).rev() {
                    let (c1, sn, r) = dlartg(d[i - 1] * cs, e[i - 2]);
                    cs = c1;
                    if i < m {
                        e[i - 1] = oldsn * r;
                    }
                    let (c2, s2, dd) = dlartg(oldcs * r, d[i - 2] * sn);
                    (oldcs, oldsn, d[i - 1]) = (c2, s2, dd);
                    work[i - ll - 1] = cs;
                    work[i - ll - 1 + nm1] = -sn;
                    work[i - ll - 1 + nm12] = oldcs;
                    work[i - ll - 1 + nm13] = -oldsn;
                }
                let h = d[ll - 1] * cs;
                d[ll - 1] = h * oldcs;
                e[ll - 1] = h * oldsn;
                apply(&work, nm1, nm12, nm13, ll, m, false, ncvt, nru, vt, ldvt, u, ldu);
                if abs(e[ll - 1]) <= thresh {
                    e[ll - 1] = 0.0;
                }
            }
        } else if idir == 1 {
            let mut f =
                (abs(d[ll - 1]) - shift) * (sign(1.0, d[ll - 1]) + shift / d[ll - 1]);
            let mut g = e[ll - 1];
            for i in ll..m {
                let (cosr, sinr, r) = dlartg(f, g);
                if i > ll {
                    e[i - 2] = r;
                }
                f = cosr * d[i - 1] + sinr * e[i - 1];
                e[i - 1] = cosr * e[i - 1] - sinr * d[i - 1];
                g = sinr * d[i];
                d[i] *= cosr;
                let (cosl, sinl, r) = dlartg(f, g);
                d[i - 1] = r;
                f = cosl * e[i - 1] + sinl * d[i];
                d[i] = cosl * d[i] - sinl * e[i - 1];
                if i < m - 1 {
                    g = sinl * e[i];
                    e[i] *= cosl;
                }
                work[i - ll] = cosr;
                work[i - ll + nm1] = sinr;
                work[i - ll + nm12] = cosl;
                work[i - ll + nm13] = sinl;
            }
            e[m - 2] = f;
            apply(&work, nm1, nm12, nm13, ll, m, true, ncvt, nru, vt, ldvt, u, ldu);
            if abs(e[m - 2]) <= thresh {
                e[m - 2] = 0.0;
            }
        } else {
            let mut f = (abs(d[m - 1]) - shift) * (sign(1.0, d[m - 1]) + shift / d[m - 1]);
            let mut g = e[m - 2];
            for i in (ll + 1..=m).rev() {
                let (cosr, sinr, r) = dlartg(f, g);
                if i < m {
                    e[i - 1] = r;
                }
                f = cosr * d[i - 1] + sinr * e[i - 2];
                e[i - 2] = cosr * e[i - 2] - sinr * d[i - 1];
                g = sinr * d[i - 2];
                d[i - 2] *= cosr;
                let (cosl, sinl, r) = dlartg(f, g);
                d[i - 1] = r;
                f = cosl * e[i - 2] + sinl * d[i - 2];
                d[i - 2] = cosl * d[i - 2] - sinl * e[i - 2];
                if i > ll + 1 {
                    g = sinl * e[i - 3];
                    e[i - 3] *= cosl;
                }
                work[i - ll - 1] = cosr;
                work[i - ll - 1 + nm1] = -sinr;
                work[i - ll - 1 + nm12] = cosl;
                work[i - ll - 1 + nm13] = -sinl;
            }
            e[ll - 1] = f;
            if abs(e[ll - 1]) <= thresh {
                e[ll - 1] = 0.0;
            }
            apply(&work, nm1, nm12, nm13, ll, m, false, ncvt, nru, vt, ldvt, u, ldu);
        }
    };

    if !converged {
        return e[..n - 1].iter().filter(|v| **v != 0.0).count() as i32;
    }

    for i in 0..n {
        if d[i] < 0.0 {
            d[i] = -d[i];
            if ncvt > 0 {
                for j in 0..ncvt {
                    vt[i + j * ldvt] = -vt[i + j * ldvt];
                }
            }
        }
    }
    for i in 0..n - 1 {
        let mut isub = 0;
        let mut smin = d[0];
        for j in 1..n - i {
            if d[j] <= smin {
                isub = j;
                smin = d[j];
            }
        }
        let last = n - 1 - i;
        if isub != last {
            d[isub] = d[last];
            d[last] = smin;
            if ncvt > 0 {
                for j in 0..ncvt {
                    vt.swap(isub + j * ldvt, last + j * ldvt);
                }
            }
            if nru > 0 {
                for j in 0..nru {
                    u.swap(j + isub * ldu, j + last * ldu);
                }
            }
        }
    }
    0
}

/// One sweep's rotations, applied to `VT` from the left and `U` from the right.
/// A forward sweep leaves `VT`'s in `work[0..]` and `U`'s in `work[nm12..]`, a
/// backward one the other way round.
#[allow(clippy::too_many_arguments)]
fn apply(
    work: &[f64],
    nm1: usize,
    nm12: usize,
    nm13: usize,
    ll: usize,
    m: usize,
    forward: bool,
    ncvt: usize,
    nru: usize,
    vt: &mut [f64],
    ldvt: usize,
    u: &mut [f64],
    ldu: usize,
) {
    let rows = m - ll + 1;
    let (vt_c, vt_s, u_c, u_s) = if forward {
        (&work[0..], &work[nm1..], &work[nm12..], &work[nm13..])
    } else {
        (&work[nm12..], &work[nm13..], &work[0..], &work[nm1..])
    };
    if ncvt > 0 {
        dlasr_left(forward, rows, ncvt, vt_c, vt_s, &mut vt[ll - 1..], ldvt);
    }
    if nru > 0 {
        dlasr_right(forward, nru, rows, u_c, u_s, &mut u[(ll - 1) * ldu..], ldu);
    }
}
