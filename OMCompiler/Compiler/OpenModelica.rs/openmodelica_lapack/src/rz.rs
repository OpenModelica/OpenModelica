//! The kernels `DGELSY` needs beyond the QR family: `DLAIC1`'s incremental
//! condition estimate, and the `RZ` factorization (`DLATRZ`/`DLARZ`/`DORMR3`)
//! that compresses a rank-deficient upper trapezoid to upper triangular.
//!
//! Translated line by line from the reference LAPACK Fortran (`SRC/dlaic1.f`,
//! `dlatrz.f`, `dlarz.f`, `dormr3.f`), whose license is in `LICENSE-LAPACK` at
//! the crate root.
//!
//! `DTZRZF` and `DORMRZ` are their unblocked forms ([`dlatrz`], [`dormr3`]),
//! which is what LAPACK itself runs below the blocking crossover.

use crate::blas::{at, ddot, set};
use crate::{abs, opt, sqrt};

/// Which end of the spectrum [`dlaic1`] estimates. LAPACK's `JOB`, whose values
/// `DGELSY` names `IMAX = 1, IMIN = 2` — the largest first.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Est {
    /// `JOB = 1`: the largest singular value.
    Max,
    /// `JOB = 2`: the smallest.
    Min,
}

fn sign(x: f64, y: f64) -> f64 {
    libm::copysign(x, y)
}

/// `DLAIC1`: given the singular vector `x` of an estimate `sest` for `L`, the
/// estimate for `[L 0; w' gamma]` one row larger. Returns
/// `(sestpr, s, c)` — the new estimate and the rotation that extends `x`.
///
/// This is how LAPACK decides a rank: not from singular values, but by growing
/// the triangle a column at a time and stopping when the condition estimate
/// crosses `rcond`. A rank taken any other way disagrees near the threshold.
pub fn dlaic1(job: Est, j: usize, x: &[f64], sest: f64, w: &[f64], gamma: f64) -> (f64, f64, f64) {
    let eps = f64::EPSILON;
    let alpha = ddot(&x[..j], &w[..j]);
    let absalp = abs(alpha);
    let absgam = abs(gamma);
    let absest = abs(sest);

    if job == Est::Max {
        if sest == 0.0 {
            let s1 = f64::max(absgam, absalp);
            if s1 == 0.0 {
                return (0.0, 0.0, 1.0);
            }
            let (s, c) = (alpha / s1, gamma / s1);
            let tmp = sqrt(s * s + c * c);
            return (s1 * tmp, s / tmp, c / tmp);
        }
        if absgam <= eps * absest {
            let tmp = f64::max(absest, absalp);
            let (s1, s2) = (absest / tmp, absalp / tmp);
            return (tmp * sqrt(s1 * s1 + s2 * s2), 1.0, 0.0);
        }
        if absalp <= eps * absest {
            return if absgam <= absest { (absest, 1.0, 0.0) } else { (absgam, 0.0, 1.0) };
        }
        if absest <= eps * absalp || absest <= eps * absgam {
            let (s1, s2) = (absgam, absalp);
            if s1 <= s2 {
                let tmp = s1 / s2;
                let s = sqrt(1.0 + tmp * tmp);
                return (s2 * s, sign(1.0, alpha) / s, (gamma / s2) / s);
            }
            let tmp = s2 / s1;
            let c = sqrt(1.0 + tmp * tmp);
            return (s1 * c, (alpha / s1) / c, sign(1.0, gamma) / c);
        }
        let zeta1 = alpha / absest;
        let zeta2 = gamma / absest;
        let b = (1.0 - zeta1 * zeta1 - zeta2 * zeta2) * 0.5;
        let c = zeta1 * zeta1;
        let t = if b > 0.0 { c / (b + sqrt(b * b + c)) } else { sqrt(b * b + c) - b };
        let sine = -zeta1 / t;
        let cosine = -zeta2 / (1.0 + t);
        let tmp = sqrt(sine * sine + cosine * cosine);
        return (sqrt(t + 1.0) * absest, sine / tmp, cosine / tmp);
    }

    // Est::Min
    if sest == 0.0 {
        let (sine, cosine) = if f64::max(absgam, absalp) == 0.0 { (1.0, 0.0) } else { (-gamma, alpha) };
        let s1 = f64::max(abs(sine), abs(cosine));
        let (s, c) = (sine / s1, cosine / s1);
        let tmp = sqrt(s * s + c * c);
        return (0.0, s / tmp, c / tmp);
    }
    if absgam <= eps * absest {
        return (absgam, 0.0, 1.0);
    }
    if absalp <= eps * absest {
        return if absgam <= absest { (absgam, 0.0, 1.0) } else { (absest, 1.0, 0.0) };
    }
    if absest <= eps * absalp || absest <= eps * absgam {
        let (s1, s2) = (absgam, absalp);
        if s1 <= s2 {
            let tmp = s1 / s2;
            let c = sqrt(1.0 + tmp * tmp);
            return (absest * (tmp / c), -(gamma / s2) / c, sign(1.0, alpha) / c);
        }
        let tmp = s2 / s1;
        let s = sqrt(1.0 + tmp * tmp);
        return (absest / s, (alpha / s1) / s, -sign(1.0, gamma) / s);
    }
    let zeta1 = alpha / absest;
    let zeta2 = gamma / absest;
    let norma = f64::max(
        1.0 + zeta1 * zeta1 + abs(zeta1 * zeta2),
        abs(zeta1 * zeta2) + zeta2 * zeta2,
    );
    let test = 1.0 + 2.0 * (zeta1 - zeta2) * (zeta1 + zeta2);
    let (sine, cosine, sestpr);
    if test >= 0.0 {
        let b = (zeta1 * zeta1 + zeta2 * zeta2 + 1.0) * 0.5;
        let c = zeta2 * zeta2;
        let t = c / (b + sqrt(abs(b * b - c)));
        sine = zeta1 / (1.0 - t);
        cosine = -zeta2 / t;
        sestpr = sqrt(t + 4.0 * eps * eps * norma) * absest;
    } else {
        let b = (zeta2 * zeta2 + zeta1 * zeta1 - 1.0) * 0.5;
        let c = zeta1 * zeta1;
        let t = if b >= 0.0 { -c / (b + sqrt(b * b + c)) } else { b - sqrt(b * b + c) };
        sine = -zeta1 / t;
        cosine = -zeta2 / (1.0 + t);
        sestpr = sqrt(1.0 + t + 4.0 * eps * eps * norma) * absest;
    }
    let tmp = sqrt(sine * sine + cosine * cosine);
    (sestpr, sine / tmp, cosine / tmp)
}

/// `DLARZ`: apply `H = I - tau*v*v'` where `v` is `(1, 0…0, z)` — `l` trailing
/// entries preceded by zeros. `v_z` holds `z` with stride `incv`; `c` is `m`×`n`.
#[allow(clippy::too_many_arguments)]
fn dlarz(
    side: &str,
    m: usize,
    n: usize,
    l: usize,
    v_z: &[f64],
    incv: usize,
    tau: f64,
    c: &mut [f64],
    ldc: usize,
) {
    if tau == 0.0 {
        return;
    }
    let v = |k: usize| v_z[k * incv];
    if opt(side) == b'L' {
        let mut w: Vec<f64> = (0..n).map(|j| at(c, ldc, 0, j)).collect();
        for j in 0..n {
            for k in 0..l {
                w[j] += at(c, ldc, m - l + k, j) * v(k);
            }
        }
        for j in 0..n {
            set(c, ldc, 0, j, at(c, ldc, 0, j) - tau * w[j]);
        }
        for j in 0..n {
            for k in 0..l {
                let e = at(c, ldc, m - l + k, j);
                set(c, ldc, m - l + k, j, e - tau * v(k) * w[j]);
            }
        }
    } else {
        let mut w: Vec<f64> = (0..m).map(|i| at(c, ldc, i, 0)).collect();
        for (i, wi) in w.iter_mut().enumerate() {
            for k in 0..l {
                *wi += at(c, ldc, i, n - l + k) * v(k);
            }
        }
        for i in 0..m {
            set(c, ldc, i, 0, at(c, ldc, i, 0) - tau * w[i]);
        }
        for i in 0..m {
            for k in 0..l {
                let e = at(c, ldc, i, n - l + k);
                set(c, ldc, i, n - l + k, e - tau * w[i] * v(k));
            }
        }
    }
}

/// `DLATRZ` (and so `DTZRZF` below the blocking crossover): factor the `m`×`n`
/// upper trapezoid `[A1 A2]` as `[R 0] * Z`, `l = n - m`. `A2` is replaced by the
/// reflectors' `z` parts and `tau` by their scalars.
pub fn dlatrz(m: usize, n: usize, l: usize, a: &mut [f64], lda: usize, tau: &mut [f64]) {
    if m == 0 {
        return;
    }
    if m == n {
        for t in tau[..n].iter_mut() {
            *t = 0.0;
        }
        return;
    }
    for i in (0..m).rev() {
        // The reflector's tail is a *row* segment, A(i, n-l..n), stride lda.
        let mut z: Vec<f64> = (0..l).map(|k| at(a, lda, i, n - l + k)).collect();
        let (beta, t) = crate::blas::dlarfg(at(a, lda, i, i), &mut z);
        tau[i] = t;
        for (k, zk) in z.iter().enumerate() {
            set(a, lda, i, n - l + k, *zk);
        }
        set(a, lda, i, i, beta);
        // From the right over the rows above, whose own columns start at i.
        if i > 0 {
            dlarz("R", i, n - i, l, &z, 1, t, &mut a[i * lda..], lda);
        }
    }
}

/// `DORMR3` (and so `DORMRZ` below the blocking crossover) for
/// `side = "L"`, `trans = "T"`: `C := Z' * C`, with `Z` the [`dlatrz`] product.
pub fn dormr3_left_trans(
    m: usize,
    n: usize,
    k: usize,
    l: usize,
    a: &[f64],
    lda: usize,
    tau: &[f64],
    c: &mut [f64],
    ldc: usize,
) {
    if m == 0 || n == 0 || k == 0 {
        return;
    }
    let ja = m - l;
    for i in 0..k {
        let z: Vec<f64> = (0..l).map(|t| at(a, lda, i, ja + t)).collect();
        dlarz("L", m - i, n, l, &z, 1, tau[i], &mut c[i..], ldc);
    }
}
