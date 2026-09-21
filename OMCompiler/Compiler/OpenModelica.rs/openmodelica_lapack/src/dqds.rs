//! `DLASQ1` … `DLASQ6` and `DLASRT`, translated from the reference LAPACK: the
//! path [`crate::bdsqr::dbdsqr`] takes when no singular vectors are wanted.
//!
//! `ILAENV(10, 'DLASQ2', …)` asks whether a division may produce an infinity
//! rather than trap. Rust's `f64` always may, so only the `IEEE` branches are
//! here.

use crate::hqr::dlascl;
use crate::{abs, opt, sqrt, PREC, SAFMIN};

use crate::bdsqr::dlas2;

/// `Z(*)` 1-based, so the `Z(4*n0+pp-3)` index arithmetic still reads as it does
/// in the Fortran.
struct Z<'a>(&'a mut [f64]);

impl core::ops::Index<usize> for Z<'_> {
    type Output = f64;
    #[inline]
    fn index(&self, i: usize) -> &f64 {
        &self.0[i - 1]
    }
}

impl core::ops::IndexMut<usize> for Z<'_> {
    #[inline]
    fn index_mut(&mut self, i: usize) -> &mut f64 {
        &mut self.0[i - 1]
    }
}

/// `DLASRT`: sort in place, `"D"`escending or `"I"`ncreasing.
pub(crate) fn dlasrt(id: &str, d: &mut [f64]) {
    if opt(id) == b'D' {
        d.sort_by(|a, b| b.total_cmp(a));
    } else {
        d.sort_by(f64::total_cmp);
    }
}

/// What DLASQ3 … DLASQ6 pass between each other; every field is read and written
/// across the group.
struct Dqds {
    i0: usize,
    n0: usize,
    pp: usize,
    dmin: f64,
    dmin1: f64,
    dmin2: f64,
    dn: f64,
    dn1: f64,
    dn2: f64,
    sigma: f64,
    desig: f64,
    qmax: f64,
    tau: f64,
    g: f64,
    ttype: i32,
    nfail: i32,
    iter: i32,
    ndiv: i32,
}

/// `DLASQ1`: the singular values of the bidiagonal matrix with diagonal `d` and
/// off-diagonal `e`, descending, in `d`.
///
/// Returns `INFO`: `1` a negative shift, `2` no convergence — `d` and `e` then
/// hold the current bidiagonal for the caller to finish by plane rotations — and
/// `3` a termination failure. `e` needs `n` elements: `INFO = 2` writes `e[n-1]`,
/// as the reference does.
pub(crate) fn dlasq1(n: usize, d: &mut [f64], e: &mut [f64]) -> i32 {
    match n {
        0 => return 0,
        1 => {
            d[0] = abs(d[0]);
            return 0;
        }
        2 => {
            let (sigmn, sigmx) = dlas2(d[0], e[0], d[1]);
            d[0] = sigmx;
            d[1] = sigmn;
            return 0;
        }
        _ => {}
    }

    let mut sigmx = 0.0f64;
    for i in 0..n - 1 {
        d[i] = abs(d[i]);
        sigmx = sigmx.max(abs(e[i]));
    }
    d[n - 1] = abs(d[n - 1]);

    if sigmx == 0.0 {
        dlasrt("D", &mut d[..n]);
        return 0;
    }
    for v in d[..n].iter() {
        sigmx = sigmx.max(*v);
    }

    // dqds runs on the squares, so scale the largest entry to sqrt(eps/safmin)
    // first, leaving room for the squaring at both ends.
    let scale = sqrt(PREC / SAFMIN);
    let mut work = vec![0.0f64; 4 * n];
    for i in 0..n {
        work[2 * i] = d[i];
    }
    for i in 0..n - 1 {
        work[2 * i + 1] = e[i];
    }
    dlascl(sigmx, scale, &mut work[..2 * n - 1]);
    for v in work[..2 * n - 1].iter_mut() {
        *v *= *v;
    }
    work[2 * n - 1] = 0.0;

    let info = dlasq2(n, &mut work);
    if info == 0 {
        for i in 0..n {
            d[i] = sqrt(work[i]);
        }
        dlascl(scale, sigmx, &mut d[..n]);
    } else if info == 2 {
        for i in 0..n {
            d[i] = sqrt(work[2 * i]);
            e[i] = sqrt(work[2 * i + 1]);
        }
        dlascl(scale, sigmx, &mut d[..n]);
        dlascl(scale, sigmx, &mut e[..n]);
    }
    info
}

/// `DLASQ2`: the eigenvalues of the symmetric positive definite tridiagonal
/// matrix whose squared entries `z` holds, descending, in `z[0..n]`.
fn dlasq2(n: usize, z: &mut [f64]) -> i32 {
    const CBIAS: f64 = 1.5;
    let tol = PREC * 100.0;
    let tol2 = tol * tol;
    let mut zz = Z(z);
    let z = &mut zz;

    if n == 0 {
        return 0;
    }
    if n == 1 {
        return if z[1] < 0.0 { -201 } else { 0 };
    }
    if n == 2 {
        if z[1] < 0.0 {
            return -201;
        } else if z[2] < 0.0 {
            return -202;
        } else if z[3] < 0.0 {
            return -203;
        } else if z[3] > z[1] {
            let d = z[3];
            z[3] = z[1];
            z[1] = d;
        }
        z[5] = z[1] + z[2] + z[3];
        if z[2] > z[3] * tol2 {
            let mut t = 0.5 * ((z[1] - z[3]) + z[2]);
            let mut s = z[3] * (z[2] / t);
            if s <= t {
                s = z[3] * (z[2] / (t * (1.0 + sqrt(1.0 + s / t))));
            } else {
                s = z[3] * (z[2] / (t + sqrt(t) * sqrt(t + s)));
            }
            t = z[1] + (s + z[2]);
            z[3] *= z[1] / t;
            z[1] = t;
        }
        z[2] = z[3];
        z[6] = z[2] + z[1];
        return 0;
    }

    z[2 * n] = 0.0;
    let (mut dsum, mut esum) = (0.0f64, 0.0f64);
    let mut k = 1;
    while k <= 2 * (n - 1) {
        if z[k] < 0.0 {
            return -((200 + k) as i32);
        } else if z[k + 1] < 0.0 {
            return -((200 + k + 1) as i32);
        }
        dsum += z[k];
        esum += z[k + 1];
        k += 2;
    }
    if z[2 * n - 1] < 0.0 {
        return -((200 + 2 * n - 1) as i32);
    }
    dsum += z[2 * n - 1];

    if esum == 0.0 {
        for k in 2..=n {
            z[k] = z[2 * k - 1];
        }
        dlasrt("D", &mut z.0[..n]);
        z[2 * n - 1] = dsum;
        return 0;
    }
    let trace = dsum + esum;
    if trace == 0.0 {
        z[2 * n - 1] = 0.0;
        return 0;
    }

    // Spread the q's and e's over the four-word slots the ping-pong alternates.
    let mut k = 2 * n;
    while k >= 2 {
        z[2 * k] = 0.0;
        z[2 * k - 1] = z[k];
        z[2 * k - 2] = 0.0;
        z[2 * k - 3] = z[k - 1];
        k -= 2;
    }

    let mut s = Dqds {
        i0: 1,
        n0: n,
        pp: 0,
        dmin: 0.0,
        dmin1: 0.0,
        dmin2: 0.0,
        dn: 0.0,
        dn1: 0.0,
        dn2: 0.0,
        sigma: 0.0,
        desig: 0.0,
        qmax: 0.0,
        tau: 0.0,
        g: 0.0,
        ttype: 0,
        nfail: 0,
        iter: 2,
        ndiv: 0,
    };

    // Reverse when that puts the larger q's last, where the shift can see them.
    if CBIAS * z[4 * s.i0 - 3] < z[4 * s.n0 - 3] {
        let ipn4 = 4 * (s.i0 + s.n0);
        let mut i4 = 4 * s.i0;
        while i4 <= 2 * (s.i0 + s.n0 - 1) {
            z.0.swap(i4 - 4, ipn4 - i4 - 4);
            z.0.swap(i4 - 2, ipn4 - i4 - 6);
            i4 += 4;
        }
    }

    // One round per slot: fills the second copy, drops negligible e's.
    for _ in 0..2 {
        let mut d = z[4 * s.n0 + s.pp - 3];
        let mut i4 = 4 * (s.n0 - 1) + s.pp;
        while i4 >= 4 * s.i0 + s.pp {
            if z[i4 - 1] <= tol2 * d {
                z[i4 - 1] = -0.0;
                d = z[i4 - 3];
            } else {
                d = z[i4 - 3] * (d / (d + z[i4 - 1]));
            }
            i4 -= 4;
        }
        let mut emin = z[4 * s.i0 + s.pp + 1];
        d = z[4 * s.i0 + s.pp - 3];
        let mut i4 = 4 * s.i0 + s.pp;
        while i4 <= 4 * (s.n0 - 1) + s.pp {
            z[i4 - 2 * s.pp - 2] = d + z[i4 - 1];
            if z[i4 - 1] <= tol2 * d {
                z[i4 - 1] = -0.0;
                z[i4 - 2 * s.pp - 2] = d;
                z[i4 - 2 * s.pp] = 0.0;
                d = z[i4 + 1];
            } else if SAFMIN * z[i4 + 1] < z[i4 - 2 * s.pp - 2]
                && SAFMIN * z[i4 - 2 * s.pp - 2] < z[i4 + 1]
            {
                let temp = z[i4 + 1] / z[i4 - 2 * s.pp - 2];
                z[i4 - 2 * s.pp] = z[i4 - 1] * temp;
                d *= temp;
            } else {
                z[i4 - 2 * s.pp] = z[i4 + 1] * (z[i4 - 1] / z[i4 - 2 * s.pp - 2]);
                d = z[i4 + 1] * (d / z[i4 - 2 * s.pp - 2]);
            }
            emin = emin.min(z[i4 - 2 * s.pp]);
            i4 += 4;
        }
        z[4 * s.n0 - s.pp - 2] = d;
        s.qmax = z[4 * s.i0 - s.pp - 2];
        let mut i4 = 4 * s.i0 - s.pp + 2;
        while i4 <= 4 * s.n0 - s.pp - 2 {
            s.qmax = s.qmax.max(z[i4]);
            i4 += 4;
        }
        s.pp = 1 - s.pp;
    }

    s.ndiv = 2 * (s.n0 - s.i0) as i32;

    for _ in 0..n + 1 {
        if s.n0 < 1 {
            // Converged. The tail of Z carries the reference's statistics.
            for k in 2..=n {
                z[k] = z[4 * k - 3];
            }
            dlasrt("D", &mut z.0[..n]);
            let mut e = 0.0;
            for k in (1..=n).rev() {
                e += z[k];
            }
            z[2 * n + 1] = trace;
            z[2 * n + 2] = e;
            z[2 * n + 3] = s.iter as f64;
            z[2 * n + 4] = s.ndiv as f64 / (n * n) as f64;
            z[2 * n + 5] = 100.0 * s.nfail as f64 / s.iter as f64;
            return 0;
        }

        s.desig = 0.0;
        s.sigma = if s.n0 == n { 0.0 } else { -z[4 * s.n0 - 1] };
        if s.sigma < 0.0 {
            return 1;
        }

        // The last split, and the extremes of the block after it.
        let mut emax = 0.0f64;
        let mut emin = if s.n0 > s.i0 { abs(z[4 * s.n0 - 5]) } else { 0.0 };
        let mut qmin = z[4 * s.n0 - 3];
        s.qmax = qmin;
        let mut i4 = 4;
        let mut j4 = 4 * s.n0;
        while j4 >= 8 {
            if z[j4 - 5] <= 0.0 {
                i4 = j4;
                break;
            }
            if qmin >= 4.0 * emax {
                qmin = qmin.min(z[j4 - 3]);
                emax = emax.max(z[j4 - 5]);
            }
            s.qmax = s.qmax.max(z[j4 - 7] + z[j4 - 5]);
            emin = emin.min(z[j4 - 5]);
            j4 -= 4;
        }
        s.i0 = i4 / 4;
        s.pp = 0;

        // Reverse when the smallest running product sits near the front;
        // `pp = 2` tells DLASQ3 that both copies were swapped.
        if s.n0 > s.i0 + 1 {
            let mut dee = z[4 * s.i0 - 3];
            let mut deemin = dee;
            let mut kmin = s.i0;
            let mut i4 = 4 * s.i0 + 1;
            while i4 <= 4 * s.n0 - 3 {
                dee = z[i4] * (dee / (dee + z[i4 - 2]));
                if dee <= deemin {
                    deemin = dee;
                    kmin = (i4 + 3) / 4;
                }
                i4 += 4;
            }
            if (kmin as i64 - s.i0 as i64) * 2 < s.n0 as i64 - kmin as i64
                && deemin <= 0.5 * z[4 * s.n0 - 3]
            {
                let ipn4 = 4 * (s.i0 + s.n0);
                s.pp = 2;
                let mut i4 = 4 * s.i0;
                while i4 <= 2 * (s.i0 + s.n0 - 1) {
                    z.0.swap(i4 - 4, ipn4 - i4 - 4);
                    z.0.swap(i4 - 3, ipn4 - i4 - 3);
                    z.0.swap(i4 - 2, ipn4 - i4 - 6);
                    z.0.swap(i4 - 1, ipn4 - i4 - 5);
                    i4 += 4;
                }
            }
        }

        s.dmin = -(0.0f64.max(qmin - 2.0 * sqrt(qmin) * sqrt(emax)));

        let nbig = 100 * (s.n0 - s.i0 + 1);
        let mut deflated = false;
        for _ in 0..nbig {
            if s.i0 > s.n0 {
                deflated = true;
                break;
            }
            dlasq3(&mut s, z);
            s.pp = 1 - s.pp;

            // A new split inside the block: mark it and restart from there.
            if s.pp == 0
                && s.n0 >= s.i0 + 3
                && (z[4 * s.n0] <= tol2 * s.qmax || z[4 * s.n0 - 1] <= tol2 * s.sigma)
            {
                let mut splt = s.i0 - 1;
                s.qmax = z[4 * s.i0 - 3];
                emin = z[4 * s.i0 - 1];
                let mut oldemn = z[4 * s.i0];
                let mut i4 = 4 * s.i0;
                while i4 <= 4 * (s.n0 - 3) {
                    if z[i4] <= tol2 * z[i4 - 3] || z[i4 - 1] <= tol2 * s.sigma {
                        z[i4 - 1] = -s.sigma;
                        splt = i4 / 4;
                        s.qmax = 0.0;
                        emin = z[i4 + 3];
                        oldemn = z[i4 + 4];
                    } else {
                        s.qmax = s.qmax.max(z[i4 + 1]);
                        emin = emin.min(z[i4 - 1]);
                        oldemn = oldemn.min(z[i4]);
                    }
                    i4 += 4;
                }
                z[4 * s.n0 - 1] = emin;
                z[4 * s.n0] = oldemn;
                s.i0 = splt + 1;
            }
        }
        if !deflated {
            undo_shifts(&mut s, z, n);
            return 2;
        }
    }
    3
}

/// Put the accumulated shift back into every block, so `DLASQ1` can hand a
/// bidiagonal matrix on to the plane-rotation QR.
///
/// The reference walks the blocks with `I1`/`N1` but re-enters its unshift loop
/// on `I0`/`N0`, which cannot terminate once a split marker stays negative. This
/// walks the blocks themselves, ending at the first.
fn undo_shifts(s: &mut Dqds, z: &mut Z<'_>, n: usize) {
    let n0_at_failure = s.n0;
    let (mut i0, mut n0, mut sigma) = (s.i0, s.n0, s.sigma);
    loop {
        let mut tempq = z[4 * i0 - 3];
        z[4 * i0 - 3] += sigma;
        for k in i0 + 1..=n0 {
            let tempe = z[4 * k - 5];
            z[4 * k - 5] *= tempq / z[4 * k - 7];
            tempq = z[4 * k - 3];
            z[4 * k - 3] += sigma + tempe - z[4 * k - 5];
        }
        if i0 <= 1 {
            break;
        }
        let n1 = i0 - 1;
        let mut start = i0;
        while start >= 2 && z[4 * start - 5] >= 0.0 {
            start -= 1;
        }
        sigma = -z[4 * n1 - 1];
        i0 = start;
        n0 = n1;
    }
    for k in 1..=n {
        z[2 * k - 1] = z[4 * k - 3];
        z[2 * k] = if k < n0_at_failure { z[4 * k - 1] } else { 0.0 };
    }
}

/// `DLASQ3`: deflate what has converged, choose a shift and take a step, retrying
/// smaller when the step goes negative.
fn dlasq3(s: &mut Dqds, z: &mut Z<'_>) {
    let n0in = s.n0;
    let tol = PREC * 100.0;
    let tol2 = tol * tol;

    // One eigenvalue at the bottom.
    fn deflate1(s: &mut Dqds, z: &mut Z<'_>) {
        z[4 * s.n0 - 3] = z[4 * s.n0 + s.pp - 3] + s.sigma;
        s.n0 -= 1;
    }
    loop {
        if s.n0 < s.i0 {
            return;
        }
        if s.n0 == s.i0 {
            deflate1(s, z);
            continue;
        }
        let nn = 4 * s.n0 + s.pp;
        if s.n0 > s.i0 + 1 {
            if !(z[nn - 5] > tol2 * (s.sigma + z[nn - 3])
                && z[nn - 2 * s.pp - 4] > tol2 * z[nn - 7])
            {
                deflate1(s, z);
                continue;
            }
            if z[nn - 9] > tol2 * s.sigma && z[nn - 2 * s.pp - 8] > tol2 * z[nn - 11] {
                break;
            }
        }
        // Two at the bottom, from the 2x2 block directly.
        if z[nn - 3] > z[nn - 7] {
            let t = z[nn - 3];
            z[nn - 3] = z[nn - 7];
            z[nn - 7] = t;
        }
        let mut t = 0.5 * ((z[nn - 7] - z[nn - 3]) + z[nn - 5]);
        if z[nn - 5] > z[nn - 3] * tol2 && t != 0.0 {
            let mut sv = z[nn - 3] * (z[nn - 5] / t);
            if sv <= t {
                sv = z[nn - 3] * (z[nn - 5] / (t * (1.0 + sqrt(1.0 + sv / t))));
            } else {
                sv = z[nn - 3] * (z[nn - 5] / (t + sqrt(t) * sqrt(t + sv)));
            }
            t = z[nn - 7] + (sv + z[nn - 5]);
            z[nn - 3] *= z[nn - 7] / t;
            z[nn - 7] = t;
        }
        z[4 * s.n0 - 7] = z[nn - 7] + s.sigma;
        z[4 * s.n0 - 3] = z[nn - 3] + s.sigma;
        s.n0 -= 2;
    }

    if s.pp == 2 {
        s.pp = 0;
    }

    // Reverse again if a deflation left the larger q's at the front.
    if s.dmin <= 0.0 || s.n0 < n0in {
        const CBIAS: f64 = 1.5;
        if CBIAS * z[4 * s.i0 + s.pp - 3] < z[4 * s.n0 + s.pp - 3] {
            let ipn4 = 4 * (s.i0 + s.n0);
            let mut j4 = 4 * s.i0;
            while j4 <= 2 * (s.i0 + s.n0 - 1) {
                z.0.swap(j4 - 4, ipn4 - j4 - 4);
                z.0.swap(j4 - 3, ipn4 - j4 - 3);
                z.0.swap(j4 - 2, ipn4 - j4 - 6);
                z.0.swap(j4 - 1, ipn4 - j4 - 5);
                j4 += 4;
            }
            if s.n0 <= s.i0 + 4 {
                z[4 * s.n0 + s.pp - 1] = z[4 * s.i0 + s.pp - 1];
                z[4 * s.n0 - s.pp] = z[4 * s.i0 - s.pp];
            }
            s.dmin2 = s.dmin2.min(z[4 * s.n0 + s.pp - 1]);
            z[4 * s.n0 + s.pp - 1] = z[4 * s.n0 + s.pp - 1]
                .min(z[4 * s.i0 + s.pp - 1])
                .min(z[4 * s.i0 + s.pp + 3]);
            z[4 * s.n0 - s.pp] = z[4 * s.n0 - s.pp]
                .min(z[4 * s.i0 - s.pp])
                .min(z[4 * s.i0 - s.pp + 4]);
            s.qmax = s.qmax.max(z[4 * s.i0 + s.pp - 3]).max(z[4 * s.i0 + s.pp + 1]);
            s.dmin = -0.0;
        }
    }

    dlasq4(s, z, n0in);

    let steps = |s: &mut Dqds| {
        s.ndiv += (s.n0 - s.i0 + 2) as i32;
        s.iter += 1;
    };
    loop {
        dlasq5(s, z);
        steps(s);

        if s.dmin >= 0.0 && s.dmin1 >= 0.0 {
            break;
        }
        if s.dmin < 0.0
            && s.dmin1 > 0.0
            && z[4 * (s.n0 - 1) - s.pp] < tol * (s.sigma + s.dn1)
            && abs(s.dn) < tol * s.sigma
        {
            // Convergence hidden below the shift.
            z[4 * (s.n0 - 1) - s.pp + 2] = 0.0;
            s.dmin = 0.0;
            break;
        }
        if s.dmin < 0.0 {
            // The shift was too big; shrink it and take the step again.
            s.nfail += 1;
            if s.ttype < -22 {
                s.tau = 0.0;
            } else if s.dmin1 > 0.0 {
                s.tau = (s.tau + s.dmin) * (1.0 - 2.0 * PREC);
                s.ttype -= 11;
            } else {
                s.tau *= 0.25;
                s.ttype -= 12;
            }
            continue;
        }
        if s.dmin.is_nan() && s.tau != 0.0 {
            s.tau = 0.0;
            continue;
        }
        // Fall back to the unshifted step, which cannot overflow.
        dlasq6(s, z);
        steps(s);
        s.tau = 0.0;
        break;
    }

    // Accumulate the shift, keeping what fell off in `desig`.
    let t;
    if s.tau < s.sigma {
        s.desig += s.tau;
        t = s.sigma + s.desig;
        s.desig -= t - s.sigma;
    } else {
        t = s.sigma + s.tau;
        s.desig += s.sigma - (t - s.tau);
    }
    s.sigma = t;
}

/// `DLASQ4`: the shift for the next step, and the `ttype` naming the case it came
/// from. Several branches return with `tau` untouched — a ratio above one means
/// the estimate is unusable, and the reference leaves the previous shift.
fn dlasq4(s: &mut Dqds, z: &Z<'_>, n0in: usize) {
    const CNST1: f64 = 0.563;
    const CNST2: f64 = 1.01;
    const CNST3: f64 = 1.05;
    const THIRD: f64 = 0.333;

    if s.dmin <= 0.0 {
        s.tau = -s.dmin;
        s.ttype = -1;
        return;
    }
    let nn = 4 * s.n0 + s.pp;
    // Lower bound of the backward scans; a start below it means no iterations.
    let lo = 4 * s.i0 as i64 - 1 + s.pp as i64;
    let sv;
    if n0in == s.n0 {
        if s.dmin == s.dn || s.dmin == s.dn1 {
            let mut b1 = sqrt(z[nn - 3]) * sqrt(z[nn - 5]);
            let mut b2 = sqrt(z[nn - 7]) * sqrt(z[nn - 9]);
            let mut a2 = z[nn - 7] + z[nn - 5];

            if s.dmin == s.dn && s.dmin1 == s.dn1 {
                let gap2 = s.dmin2 - a2 - s.dmin2 * 0.25;
                let gap1 = if gap2 > 0.0 && gap2 > b2 {
                    a2 - s.dn - (b2 / gap2) * b2
                } else {
                    a2 - s.dn - (b1 + b2)
                };
                if gap1 > 0.0 && gap1 > b1 {
                    sv = (s.dn - (b1 / gap1) * b1).max(0.5 * s.dmin);
                    s.ttype = -2;
                } else {
                    let mut v = 0.0f64;
                    if s.dn > b1 {
                        v = s.dn - b1;
                    }
                    if a2 > b1 + b2 {
                        v = v.min(a2 - (b1 + b2));
                    }
                    sv = v.max(THIRD * s.dmin);
                    s.ttype = -3;
                }
            } else {
                s.ttype = -4;
                let mut v = 0.25 * s.dmin;
                let gam;
                let np: i64;
                if s.dmin == s.dn {
                    gam = s.dn;
                    a2 = 0.0;
                    if z[nn - 5] > z[nn - 7] {
                        return;
                    }
                    b2 = z[nn - 5] / z[nn - 7];
                    np = nn as i64 - 9;
                } else {
                    let p = nn - 2 * s.pp;
                    gam = s.dn1;
                    if z[p - 4] > z[p - 2] {
                        return;
                    }
                    a2 = z[p - 4] / z[p - 2];
                    if z[nn - 9] > z[nn - 11] {
                        return;
                    }
                    b2 = z[nn - 9] / z[nn - 11];
                    np = nn as i64 - 13;
                }
                a2 += b2;
                let mut i4 = np;
                while i4 >= lo {
                    if b2 == 0.0 {
                        break;
                    }
                    b1 = b2;
                    let k = i4 as usize;
                    if z[k] > z[k - 2] {
                        return;
                    }
                    b2 *= z[k] / z[k - 2];
                    a2 += b2;
                    if 100.0 * b2.max(b1) < a2 || CNST1 < a2 {
                        break;
                    }
                    i4 -= 4;
                }
                a2 *= CNST3;
                if a2 < CNST1 {
                    v = gam * (1.0 - sqrt(a2)) / (1.0 + a2);
                }
                sv = v;
            }
        } else if s.dmin == s.dn2 {
            s.ttype = -5;
            let mut v = 0.25 * s.dmin;
            let np = nn - 2 * s.pp;
            let mut b1 = z[np - 2];
            let mut b2 = z[np - 6];
            let gam = s.dn2;
            if z[np - 8] > b2 || z[np - 4] > b1 {
                return;
            }
            let mut a2 = (z[np - 8] / b2) * (1.0 + z[np - 4] / b1);
            if s.n0 > s.i0 + 2 {
                b2 = z[nn - 13] / z[nn - 15];
                a2 += b2;
                let mut i4 = nn as i64 - 17;
                while i4 >= lo {
                    if b2 == 0.0 {
                        break;
                    }
                    b1 = b2;
                    let k = i4 as usize;
                    if z[k] > z[k - 2] {
                        return;
                    }
                    b2 *= z[k] / z[k - 2];
                    a2 += b2;
                    if 100.0 * b2.max(b1) < a2 || CNST1 < a2 {
                        break;
                    }
                    i4 -= 4;
                }
                a2 *= CNST3;
            }
            if a2 < CNST1 {
                v = gam * (1.0 - sqrt(a2)) / (1.0 + a2);
            }
            sv = v;
        } else {
            // dmin from the middle: back off a fixed fraction.
            if s.ttype == -6 {
                s.g += THIRD * (1.0 - s.g);
            } else if s.ttype == -18 {
                s.g = 0.25 * THIRD;
            } else {
                s.g = 0.25;
            }
            sv = s.g * s.dmin;
            s.ttype = -6;
        }
    } else if n0in == s.n0 + 1 {
        // One eigenvalue deflated last step.
        if s.dmin1 == s.dn1 && s.dmin2 == s.dn2 {
            s.ttype = -7;
            let mut v = THIRD * s.dmin1;
            if z[nn - 5] > z[nn - 7] {
                return;
            }
            let mut b1 = z[nn - 5] / z[nn - 7];
            let mut b2 = b1;
            if b2 != 0.0 {
                let mut i4 = 4 * s.n0 as i64 - 9 + s.pp as i64;
                while i4 >= lo {
                    let a2 = b1;
                    let k = i4 as usize;
                    if z[k] > z[k - 2] {
                        return;
                    }
                    b1 *= z[k] / z[k - 2];
                    b2 += b1;
                    if 100.0 * b1.max(a2) < b2 {
                        break;
                    }
                    i4 -= 4;
                }
            }
            b2 = sqrt(CNST3 * b2);
            let a2 = s.dmin1 / (1.0 + b2 * b2);
            let gap2 = 0.5 * s.dmin2 - a2;
            if gap2 > 0.0 && gap2 > b2 * a2 {
                sv = v.max(a2 * (1.0 - CNST2 * a2 * (b2 / gap2) * b2));
            } else {
                v = v.max(a2 * (1.0 - CNST2 * b2));
                s.ttype = -8;
                sv = v;
            }
        } else {
            sv = if s.dmin1 == s.dn1 { 0.5 * s.dmin1 } else { 0.25 * s.dmin1 };
            s.ttype = -9;
        }
    } else if n0in == s.n0 + 2 {
        // Two eigenvalues deflated last step.
        if s.dmin2 == s.dn2 && 2.0 * z[nn - 5] < z[nn - 7] {
            s.ttype = -10;
            let mut v = THIRD * s.dmin2;
            if z[nn - 5] > z[nn - 7] {
                return;
            }
            let mut b1 = z[nn - 5] / z[nn - 7];
            let mut b2 = b1;
            if b2 != 0.0 {
                let mut i4 = 4 * s.n0 as i64 - 9 + s.pp as i64;
                while i4 >= lo {
                    let k = i4 as usize;
                    if z[k] > z[k - 2] {
                        return;
                    }
                    b1 *= z[k] / z[k - 2];
                    b2 += b1;
                    if 100.0 * b1 < b2 {
                        break;
                    }
                    i4 -= 4;
                }
            }
            b2 = sqrt(CNST3 * b2);
            let a2 = s.dmin2 / (1.0 + b2 * b2);
            let gap2 = z[nn - 7] + z[nn - 9] - sqrt(z[nn - 11]) * sqrt(z[nn - 9]) - a2;
            if gap2 > 0.0 && gap2 > b2 * a2 {
                sv = v.max(a2 * (1.0 - CNST2 * a2 * (b2 / gap2) * b2));
            } else {
                v = v.max(a2 * (1.0 - CNST2 * b2));
                sv = v;
            }
        } else {
            sv = 0.25 * s.dmin2;
            s.ttype = -11;
        }
    } else {
        sv = 0.0;
        s.ttype = -12;
    }
    s.tau = sv;
}

/// `DLASQ5`: one dqds step with shift `tau`, from slot `pp` into the other.
fn dlasq5(s: &mut Dqds, z: &mut Z<'_>) {
    if s.n0 < s.i0 + 2 {
        return;
    }
    let dthresh = PREC * (s.sigma + s.tau);
    if s.tau < dthresh * 0.5 {
        s.tau = 0.0;
    }
    // Unshifted the recurrence cannot go negative, so the reference flushes
    // below the threshold instead of guarding.
    let clamp = s.tau == 0.0;
    let tau = s.tau;

    let mut j4 = 4 * s.i0 + s.pp - 3;
    let mut emin = z[j4 + 4];
    let mut d = z[j4] - tau;
    s.dmin = d;
    s.dmin1 = -z[j4];

    let mut j = 4 * s.i0;
    while j <= 4 * (s.n0 - 3) {
        let (di, dnext, ei, eout) = if s.pp == 0 {
            (j - 2, j + 1, j - 1, j)
        } else {
            (j - 3, j + 2, j, j - 1)
        };
        z[di] = d + z[ei];
        let temp = z[dnext] / z[di];
        d = d * temp - tau;
        if clamp && d < dthresh {
            d = 0.0;
        }
        s.dmin = s.dmin.min(d);
        z[eout] = z[ei] * temp;
        emin = emin.min(z[eout]);
        j += 4;
    }

    s.dn2 = d;
    s.dmin2 = s.dmin;
    j4 = 4 * (s.n0 - 2) - s.pp;
    let mut j4p2 = j4 + 2 * s.pp - 1;
    z[j4 - 2] = s.dn2 + z[j4p2];
    z[j4] = z[j4p2 + 2] * (z[j4p2] / z[j4 - 2]);
    s.dn1 = z[j4p2 + 2] * (s.dn2 / z[j4 - 2]) - tau;
    s.dmin = s.dmin.min(s.dn1);

    s.dmin1 = s.dmin;
    j4 += 4;
    j4p2 = j4 + 2 * s.pp - 1;
    z[j4 - 2] = s.dn1 + z[j4p2];
    z[j4] = z[j4p2 + 2] * (z[j4p2] / z[j4 - 2]);
    s.dn = z[j4p2 + 2] * (s.dn1 / z[j4 - 2]) - tau;
    s.dmin = s.dmin.min(s.dn);

    z[j4 + 2] = s.dn;
    z[4 * s.n0 - s.pp] = emin;
}

/// `DLASQ6`: one unshifted step, with the overflow guards [`dlasq5`] skips.
fn dlasq6(s: &mut Dqds, z: &mut Z<'_>) {
    if s.n0 < s.i0 + 2 {
        return;
    }
    let j4 = 4 * s.i0 + s.pp - 3;
    let mut emin = z[j4 + 4];
    let mut d = z[j4];
    s.dmin = d;

    let mut j = 4 * s.i0;
    while j <= 4 * (s.n0 - 3) {
        let (di, dnext, ei, eout) = if s.pp == 0 {
            (j - 2, j + 1, j - 1, j)
        } else {
            (j - 3, j + 2, j, j - 1)
        };
        z[di] = d + z[ei];
        if z[di] == 0.0 {
            z[eout] = 0.0;
            d = z[dnext];
            s.dmin = d;
            emin = 0.0;
        } else if SAFMIN * z[dnext] < z[di] && SAFMIN * z[di] < z[dnext] {
            let temp = z[dnext] / z[di];
            z[eout] = z[ei] * temp;
            d *= temp;
        } else {
            z[eout] = z[dnext] * (z[ei] / z[di]);
            d = z[dnext] * (d / z[di]);
        }
        s.dmin = s.dmin.min(d);
        emin = emin.min(z[eout]);
        j += 4;
    }

    s.dn2 = d;
    s.dmin2 = s.dmin;
    let mut j4 = 4 * (s.n0 - 2) - s.pp;
    let mut j4p2 = j4 + 2 * s.pp - 1;
    z[j4 - 2] = s.dn2 + z[j4p2];
    if z[j4 - 2] == 0.0 {
        z[j4] = 0.0;
        s.dn1 = z[j4p2 + 2];
        s.dmin = s.dn1;
        emin = 0.0;
    } else if SAFMIN * z[j4p2 + 2] < z[j4 - 2] && SAFMIN * z[j4 - 2] < z[j4p2 + 2] {
        let temp = z[j4p2 + 2] / z[j4 - 2];
        z[j4] = z[j4p2] * temp;
        s.dn1 = s.dn2 * temp;
    } else {
        z[j4] = z[j4p2 + 2] * (z[j4p2] / z[j4 - 2]);
        s.dn1 = z[j4p2 + 2] * (s.dn2 / z[j4 - 2]);
    }
    s.dmin = s.dmin.min(s.dn1);

    s.dmin1 = s.dmin;
    j4 += 4;
    j4p2 = j4 + 2 * s.pp - 1;
    z[j4 - 2] = s.dn1 + z[j4p2];
    if z[j4 - 2] == 0.0 {
        z[j4] = 0.0;
        s.dn = z[j4p2 + 2];
        s.dmin = s.dn;
        emin = 0.0;
    } else if SAFMIN * z[j4p2 + 2] < z[j4 - 2] && SAFMIN * z[j4 - 2] < z[j4p2 + 2] {
        let temp = z[j4p2 + 2] / z[j4 - 2];
        z[j4] = z[j4p2] * temp;
        s.dn = s.dn1 * temp;
    } else {
        z[j4] = z[j4p2 + 2] * (z[j4p2] / z[j4 - 2]);
        s.dn = z[j4p2 + 2] * (s.dn1 / z[j4 - 2]);
    }
    s.dmin = s.dmin.min(s.dn);

    z[j4 + 2] = s.dn;
    z[4 * s.n0 - s.pp] = emin;
}
