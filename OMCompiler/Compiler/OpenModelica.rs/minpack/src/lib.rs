//! Pure-Rust port of MINPACK's `hybrd`: Powell's hybrid method for solving a
//! system of `n` nonlinear equations in `n` unknowns, `f(x) = 0`. It combines a
//! forward-difference Jacobian, a QR factorisation, a dogleg trust-region step,
//! and Broyden rank-1 updates between Jacobian evaluations.
//!
//! Ported from the reference MINPACK (via the C translation in `cminpack`);
//! `enorm`, `fdjac1`, `qrfac`, `qform`, `dogleg`, `r1updt` and `r1mpyq` are the
//! original subroutines. Arrays are 0-based; `fjac` is column-major `n×n`, `r`
//! the packed upper triangle of length `n(n+1)/2`.
//!
//! `no_std` by default-off of the `std` feature; math routes through `libm` so
//! the solver compiles unchanged to `wasm32-unknown-unknown`.
//!
//! MINPACK Copyright (1999) University of Chicago; see the bundled `LICENSE`.

#![cfg_attr(not(feature = "std"), no_std)]

extern crate alloc;
use alloc::vec;

const EPSMCH: f64 = 2.2204460492503131e-16;
const GIANT: f64 = 1.7976931348623157e+308;
const RDWARF: f64 = 3.834e-20;
const RGIANT: f64 = 1.304e19;

#[inline]
fn abs(x: f64) -> f64 {
    if x < 0.0 { -x } else { x }
}
#[inline]
fn fmax(a: f64, b: f64) -> f64 {
    if a > b { a } else { b }
}
#[inline]
fn fmin(a: f64, b: f64) -> f64 {
    if a < b { a } else { b }
}
#[inline]
fn sqrt(x: f64) -> f64 {
    #[cfg(feature = "std")]
    {
        x.sqrt()
    }
    #[cfg(not(feature = "std"))]
    {
        libm::sqrt(x)
    }
}

/// MINPACK `enorm`: Euclidean norm, computed in three accumulators to avoid
/// destructive over/underflow.
pub fn enorm(x: &[f64]) -> f64 {
    let n = x.len();
    let (mut s1, mut s2, mut s3) = (0.0f64, 0.0f64, 0.0f64);
    let (mut x1max, mut x3max) = (0.0f64, 0.0f64);
    let agiant = RGIANT / (n as f64);
    for &xi in x.iter() {
        let xabs = abs(xi);
        if xabs > RDWARF && xabs < agiant {
            s2 += xabs * xabs;
        } else if xabs <= RDWARF {
            if xabs <= x3max {
                if xabs != 0.0 {
                    let d = xabs / x3max;
                    s3 += d * d;
                }
            } else {
                let d = x3max / xabs;
                s3 = 1.0 + s3 * d * d;
                x3max = xabs;
            }
        } else if xabs <= x1max {
            let d = xabs / x1max;
            s1 += d * d;
        } else {
            let d = x1max / xabs;
            s1 = 1.0 + s1 * d * d;
            x1max = xabs;
        }
    }
    if s1 != 0.0 {
        x1max * sqrt(s1 + s2 / x1max / x1max)
    } else if s2 != 0.0 {
        if s2 >= x3max {
            sqrt(s2 * (1.0 + x3max / s2 * (x3max * s3)))
        } else {
            sqrt(x3max * (s2 / x3max + x3max * s3))
        }
    } else {
        x3max * sqrt(s3)
    }
}

/// Forward-difference Jacobian, dense (`ml+mu+1 >= n`) path. `fjac` is filled
/// column-major; `eval(x, f)` computes the residual.
fn fdjac1(
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    n: usize,
    x: &mut [f64],
    fvec: &[f64],
    fjac: &mut [f64],
    epsfcn: f64,
    wa1: &mut [f64],
) {
    let eps = sqrt(fmax(epsfcn, EPSMCH));
    for j in 0..n {
        let temp = x[j];
        let mut h = eps * abs(temp);
        if h == 0.0 {
            h = eps;
        }
        x[j] = temp + h;
        eval(x, wa1);
        x[j] = temp;
        for i in 0..n {
            fjac[i + j * n] = (wa1[i] - fvec[i]) / h;
        }
    }
}

/// QR factorisation by Householder (no column pivoting, as `hybrd` uses). On
/// return the lower part of `a` (column-major `m×n`) holds the Householder
/// vectors, `rdiag` the diagonal of R, `acnorm` the original column norms.
fn qrfac(m: usize, n: usize, a: &mut [f64], rdiag: &mut [f64], acnorm: &mut [f64], wa: &mut [f64]) {
    for j in 0..n {
        acnorm[j] = enorm(&a[j * m..j * m + m]);
        rdiag[j] = acnorm[j];
        wa[j] = rdiag[j];
    }
    let minmn = if m < n { m } else { n };
    for j in 0..minmn {
        let mut ajnorm = enorm(&a[j + j * m..j * m + m]);
        if ajnorm != 0.0 {
            if a[j + j * m] < 0.0 {
                ajnorm = -ajnorm;
            }
            for i in j..m {
                a[i + j * m] /= ajnorm;
            }
            a[j + j * m] += 1.0;
            for k in (j + 1)..n {
                let mut sum = 0.0;
                for i in j..m {
                    sum += a[i + j * m] * a[i + k * m];
                }
                let temp = sum / a[j + j * m];
                for i in j..m {
                    a[i + k * m] -= temp * a[i + j * m];
                }
            }
        }
        rdiag[j] = -ajnorm;
    }
}

/// Accumulate the orthogonal factor Q (`m×m`) from the Householder vectors left
/// in `q` (column-major, first `n` columns on input).
fn qform(m: usize, n: usize, q: &mut [f64], wa: &mut [f64]) {
    let minmn = if m < n { m } else { n };
    for j in 1..minmn {
        for i in 0..j {
            q[i + j * m] = 0.0;
        }
    }
    for j in n..m {
        for i in 0..m {
            q[i + j * m] = 0.0;
        }
        q[j + j * m] = 1.0;
    }
    for l in 0..minmn {
        let k = minmn - 1 - l;
        for i in k..m {
            wa[i] = q[i + k * m];
            q[i + k * m] = 0.0;
        }
        q[k + k * m] = 1.0;
        if wa[k] != 0.0 {
            for j in k..m {
                let mut sum = 0.0;
                for i in k..m {
                    sum += q[i + j * m] * wa[i];
                }
                let temp = sum / wa[k];
                for i in k..m {
                    q[i + j * m] -= temp * wa[i];
                }
            }
        }
    }
}

/// Dogleg: combine the Gauss-Newton and scaled-gradient directions inside the
/// trust region `delta`. `r` is the packed upper triangle, `qtb = Qᵀ b`; the
/// step is returned in `x`.
fn dogleg(n: usize, r: &[f64], diag: &[f64], qtb: &[f64], delta: f64, x: &mut [f64], wa1: &mut [f64], wa2: &mut [f64]) {
    // Gauss-Newton direction: back-substitution of R x = qtb.
    let mut jj = n * (n + 1) / 2;
    for k in 0..n {
        let j = n - 1 - k;
        jj -= k + 1;
        let mut l = jj + 1;
        let mut sum = 0.0;
        for i in (j + 1)..n {
            sum += r[l] * x[i];
            l += 1;
        }
        let mut temp = r[jj];
        if temp == 0.0 {
            let mut ll = j;
            for i in 0..=j {
                temp = fmax(temp, abs(r[ll]));
                ll += n - 1 - i;
            }
            temp *= EPSMCH;
            if temp == 0.0 {
                temp = EPSMCH;
            }
        }
        x[j] = (qtb[j] - sum) / temp;
    }
    // Take the Gauss-Newton step if it is inside the trust region.
    for j in 0..n {
        wa1[j] = 0.0;
        wa2[j] = diag[j] * x[j];
    }
    let qnorm = enorm(&wa2[..n]);
    if qnorm <= delta {
        return;
    }
    // Scaled gradient direction (wa1).
    let mut l = 0;
    for j in 0..n {
        let temp = qtb[j];
        for i in j..n {
            wa1[i] += r[l] * temp;
            l += 1;
        }
        wa1[j] /= diag[j];
    }
    let gnorm = enorm(&wa1[..n]);
    let mut sgnorm = 0.0;
    let mut alpha = delta / qnorm;
    if gnorm != 0.0 {
        for j in 0..n {
            wa1[j] = wa1[j] / gnorm / diag[j];
        }
        let mut l = 0;
        for j in 0..n {
            let mut sum = 0.0;
            for i in j..n {
                sum += r[l] * wa1[i];
                l += 1;
            }
            wa2[j] = sum;
        }
        let temp = enorm(&wa2[..n]);
        sgnorm = gnorm / temp / temp;
        alpha = 0.0;
        if sgnorm < delta {
            let bnorm = enorm(&qtb[..n]);
            let mut temp = bnorm / gnorm * (bnorm / qnorm) * (sgnorm / delta);
            let d1 = sgnorm / delta;
            let d3 = delta / qnorm;
            temp = temp - delta / qnorm * (d1 * d1)
                + sqrt((temp - delta / qnorm) * (temp - delta / qnorm) + (1.0 - d3 * d3) * (1.0 - d1 * d1));
            alpha = delta / qnorm * (1.0 - d1 * d1) / temp;
        }
    }
    let temp = (1.0 - alpha) * fmin(sgnorm, delta);
    for j in 0..n {
        x[j] = temp * wa1[j] + alpha * x[j];
    }
}

/// Rank-1 update of the QR factorisation, `(R + u vᵀ) = Q₁ R₁`. `s` is the
/// packed upper triangle (updated in place); the Givens rotations are recorded
/// in `v`/`w`.
fn r1updt(m: usize, n: usize, s: &mut [f64], u: &[f64], v: &mut [f64], w: &mut [f64], sing: &mut bool) {
    let p5 = 0.5;
    let p25 = 0.25;
    let mut jj = n * (2 * m - n + 1) / 2 - (m - n) - 1;
    let mut l = jj;
    for i in (n - 1)..m {
        w[i] = s[l];
        l += 1;
    }
    if n >= 2 {
        for nmj in 1..n {
            let j = n - 1 - nmj;
            jj -= m - j;
            w[j] = 0.0;
            if v[j] != 0.0 {
                let (sin_, cos_, tau);
                if abs(v[n - 1]) < abs(v[j]) {
                    let cotan = v[n - 1] / v[j];
                    sin_ = p5 / sqrt(p25 + p25 * cotan * cotan);
                    cos_ = sin_ * cotan;
                    tau = if abs(cos_) * GIANT > 1.0 { 1.0 / cos_ } else { 1.0 };
                } else {
                    let tan_ = v[j] / v[n - 1];
                    cos_ = p5 / sqrt(p25 + p25 * tan_ * tan_);
                    sin_ = cos_ * tan_;
                    tau = sin_;
                }
                v[n - 1] = sin_ * v[j] + cos_ * v[n - 1];
                v[j] = tau;
                let mut ll = jj;
                for i in j..m {
                    let temp = cos_ * s[ll] - sin_ * w[i];
                    w[i] = sin_ * s[ll] + cos_ * w[i];
                    s[ll] = temp;
                    ll += 1;
                }
            }
        }
    }
    for i in 0..m {
        w[i] += v[n - 1] * u[i];
    }
    *sing = false;
    if n >= 2 {
        for j in 0..(n - 1) {
            if w[j] != 0.0 {
                let (sin_, cos_, tau);
                if abs(s[jj]) < abs(w[j]) {
                    let cotan = s[jj] / w[j];
                    sin_ = p5 / sqrt(p25 + p25 * cotan * cotan);
                    cos_ = sin_ * cotan;
                    tau = if abs(cos_) * GIANT > 1.0 { 1.0 / cos_ } else { 1.0 };
                } else {
                    let tan_ = w[j] / s[jj];
                    cos_ = p5 / sqrt(p25 + p25 * tan_ * tan_);
                    sin_ = cos_ * tan_;
                    tau = sin_;
                }
                let mut ll = jj;
                for i in j..m {
                    let temp = cos_ * s[ll] + sin_ * w[i];
                    w[i] = -sin_ * s[ll] + cos_ * w[i];
                    s[ll] = temp;
                    ll += 1;
                }
                w[j] = tau;
            }
            if s[jj] == 0.0 {
                *sing = true;
            }
            jj += m - j;
        }
    }
    let mut l = jj;
    for i in (n - 1)..m {
        s[l] = w[i];
        l += 1;
    }
    if s[jj] == 0.0 {
        *sing = true;
    }
}

/// Apply the accumulated Givens rotations of [`r1updt`] to `a` (column-major
/// `m×n`): `a := a Qᵀ`, Q built from `v` then `w`.
fn r1mpyq(m: usize, n: usize, a: &mut [f64], v: &[f64], w: &[f64]) {
    if n < 2 {
        return;
    }
    for nmj in 1..n {
        let j = n - 1 - nmj;
        let (sin_, cos_);
        if abs(v[j]) > 1.0 {
            cos_ = 1.0 / v[j];
            sin_ = sqrt(1.0 - cos_ * cos_);
        } else {
            sin_ = v[j];
            cos_ = sqrt(1.0 - sin_ * sin_);
        }
        for i in 0..m {
            let temp = cos_ * a[i + j * m] - sin_ * a[i + (n - 1) * m];
            a[i + (n - 1) * m] = sin_ * a[i + j * m] + cos_ * a[i + (n - 1) * m];
            a[i + j * m] = temp;
        }
    }
    for j in 0..(n - 1) {
        let (sin_, cos_);
        if abs(w[j]) > 1.0 {
            cos_ = 1.0 / w[j];
            sin_ = sqrt(1.0 - cos_ * cos_);
        } else {
            sin_ = w[j];
            cos_ = sqrt(1.0 - sin_ * sin_);
        }
        for i in 0..m {
            let temp = cos_ * a[i + j * m] + sin_ * a[i + (n - 1) * m];
            a[i + (n - 1) * m] = -sin_ * a[i + j * m] + cos_ * a[i + (n - 1) * m];
            a[i + j * m] = temp;
        }
    }
}

/// `r1mpyq` specialised to a single row (`m = 1`) — rotates `qtf`.
fn r1mpyq_row(n: usize, a: &mut [f64], v: &[f64], w: &[f64]) {
    if n < 2 {
        return;
    }
    for nmj in 1..n {
        let j = n - 1 - nmj;
        let (sin_, cos_);
        if abs(v[j]) > 1.0 {
            cos_ = 1.0 / v[j];
            sin_ = sqrt(1.0 - cos_ * cos_);
        } else {
            sin_ = v[j];
            cos_ = sqrt(1.0 - sin_ * sin_);
        }
        let temp = cos_ * a[j] - sin_ * a[n - 1];
        a[n - 1] = sin_ * a[j] + cos_ * a[n - 1];
        a[j] = temp;
    }
    for j in 0..(n - 1) {
        let (sin_, cos_);
        if abs(w[j]) > 1.0 {
            cos_ = 1.0 / w[j];
            sin_ = sqrt(1.0 - cos_ * cos_);
        } else {
            sin_ = w[j];
            cos_ = sqrt(1.0 - sin_ * sin_);
        }
        let temp = cos_ * a[j] + sin_ * a[n - 1];
        a[n - 1] = -sin_ * a[j] + cos_ * a[n - 1];
        a[j] = temp;
    }
}

/// Outcome of [`hybrd`], mirroring MINPACK's `info`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Status {
    /// Relative error between `x` and the solution is at most `xtol` (info = 1).
    Converged,
    /// `maxfev` function evaluations reached (info = 2).
    MaxEval,
    /// `xtol` is too small; no further progress in `x` is possible (info = 3).
    XtolTooSmall,
    /// Iteration is not making good progress (info = 4 or 5).
    Stalled,
}

/// Solve `f(x) = 0` for `n` equations in `n` unknowns with MINPACK's `hybrd`
/// (numerical Jacobian). `eval(x, f)` writes the residual `f` for the point `x`.
/// On return `x` holds the last iterate and `fvec` its residual.
///
/// `xtol` is the relative step tolerance, `maxfev` the evaluation budget,
/// `epsfcn` the forward-difference step scale (the actual step is
/// `sqrt(max(epsfcn, eps_machine)) * |x_j|`), and `factor` the initial
/// trust-region bound (MINPACK recommends 100).
#[allow(clippy::too_many_arguments)]
pub fn hybrd(
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    n: usize,
    x: &mut [f64],
    fvec: &mut [f64],
    xtol: f64,
    maxfev: usize,
    epsfcn: f64,
    factor: f64,
) -> Status {
    hybrd_common(eval, None, n, x, fvec, xtol, maxfev, epsfcn, factor)
}

/// Solve `f(x) = 0` with MINPACK's `hybrj` (user-supplied analytic Jacobian).
/// `jac(x, fjac)` fills the column-major `n×n` Jacobian `fjac[i+j*n] = ∂f_i/∂x_j`
/// at `x`. Otherwise identical to [`hybrd`].
#[allow(clippy::too_many_arguments)]
pub fn hybrj(
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    jac: &mut dyn FnMut(&[f64], &mut [f64]),
    n: usize,
    x: &mut [f64],
    fvec: &mut [f64],
    xtol: f64,
    maxfev: usize,
    factor: f64,
) -> Status {
    hybrd_common(eval, Some(jac), n, x, fvec, xtol, maxfev, 0.0, factor)
}

/// Shared dogleg/trust-region driver for [`hybrd`] (numeric Jacobian via
/// [`fdjac1`]) and [`hybrj`] (analytic Jacobian via `jac`).
#[allow(clippy::too_many_arguments)]
fn hybrd_common(
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    mut jac: Option<&mut dyn FnMut(&[f64], &mut [f64])>,
    n: usize,
    x: &mut [f64],
    fvec: &mut [f64],
    xtol: f64,
    maxfev: usize,
    epsfcn: f64,
    factor: f64,
) -> Status {
    let p1 = 0.1;
    let p5 = 0.5;
    let p001 = 0.001;
    let p0001 = 0.0001;

    let lr = n * (n + 1) / 2;
    let mut fjac = vec![0.0f64; n * n];
    let mut r = vec![0.0f64; lr];
    let mut qtf = vec![0.0f64; n];
    let mut diag = vec![0.0f64; n];
    let mut wa1 = vec![0.0f64; n];
    let mut wa2 = vec![0.0f64; n];
    let mut wa3 = vec![0.0f64; n];
    let mut wa4 = vec![0.0f64; n];

    let mut info = Status::Stalled;
    let mut nfev;

    eval(x, fvec);
    nfev = 1;
    let mut fnorm = enorm(&fvec[..n]);

    let mut iter = 1;
    let (mut ncsuc, mut ncfail, mut nslow1, mut nslow2) = (0i32, 0i32, 0i32, 0i32);
    let mut delta = 0.0f64;
    let mut xnorm = 0.0f64;

    'outer: loop {
        let mut jeval = true;

        match jac.as_mut() {
            Some(jacf) => jacf(x, &mut fjac),
            None => {
                fdjac1(eval, n, x, fvec, &mut fjac, epsfcn, &mut wa1);
                nfev += n;
            }
        }
        qrfac(n, n, &mut fjac, &mut wa1, &mut wa2, &mut wa3);

        if iter == 1 {
            for j in 0..n {
                diag[j] = if wa2[j] == 0.0 { 1.0 } else { wa2[j] };
            }
            for j in 0..n {
                wa3[j] = diag[j] * x[j];
            }
            xnorm = enorm(&wa3[..n]);
            delta = factor * xnorm;
            if delta == 0.0 {
                delta = factor;
            }
        }

        for i in 0..n {
            qtf[i] = fvec[i];
        }
        for j in 0..n {
            if fjac[j + j * n] != 0.0 {
                let mut sum = 0.0;
                for i in j..n {
                    sum += fjac[i + j * n] * qtf[i];
                }
                let temp = -sum / fjac[j + j * n];
                for i in j..n {
                    qtf[i] += fjac[i + j * n] * temp;
                }
            }
        }

        // Copy the triangular factor R into packed storage.
        for j in 0..n {
            let mut l = j;
            if j >= 1 {
                for i in 0..j {
                    r[l] = fjac[i + j * n];
                    l += n - 1 - i;
                }
            }
            r[l] = wa1[j];
        }

        qform(n, n, &mut fjac, &mut wa1);

        for j in 0..n {
            diag[j] = fmax(diag[j], wa2[j]);
        }

        loop {
            dogleg(n, &r, &diag, &qtf, delta, &mut wa1, &mut wa2, &mut wa3);
            for j in 0..n {
                wa1[j] = -wa1[j];
                wa2[j] = x[j] + wa1[j];
                wa3[j] = diag[j] * wa1[j];
            }
            let pnorm = enorm(&wa3[..n]);
            if iter == 1 {
                delta = fmin(delta, pnorm);
            }

            eval(&wa2, &mut wa4);
            nfev += 1;
            let fnorm1 = enorm(&wa4[..n]);

            let actred = if fnorm1 < fnorm {
                1.0 - (fnorm1 / fnorm) * (fnorm1 / fnorm)
            } else {
                -1.0
            };

            let mut l = 0;
            for i in 0..n {
                let mut sum = 0.0;
                for j in i..n {
                    sum += r[l] * wa1[j];
                    l += 1;
                }
                wa3[i] = qtf[i] + sum;
            }
            let temp = enorm(&wa3[..n]);
            let prered = if temp < fnorm {
                1.0 - (temp / fnorm) * (temp / fnorm)
            } else {
                0.0
            };

            let ratio = if prered > 0.0 { actred / prered } else { 0.0 };

            if ratio < p1 {
                ncsuc = 0;
                ncfail += 1;
                delta = p5 * delta;
            } else {
                ncfail = 0;
                ncsuc += 1;
                if ratio >= p5 || ncsuc > 1 {
                    delta = fmax(delta, pnorm / p5);
                }
                if abs(ratio - 1.0) <= p1 {
                    delta = pnorm / p5;
                }
            }

            if ratio >= p0001 {
                for j in 0..n {
                    x[j] = wa2[j];
                    wa2[j] = diag[j] * x[j];
                    fvec[j] = wa4[j];
                }
                xnorm = enorm(&wa2[..n]);
                fnorm = fnorm1;
                iter += 1;
            }

            nslow1 += 1;
            if actred >= p001 {
                nslow1 = 0;
            }
            if jeval {
                nslow2 += 1;
            }
            if actred >= p1 {
                nslow2 = 0;
            }

            if delta <= xtol * xnorm || fnorm == 0.0 {
                info = Status::Converged;
                break 'outer;
            }
            if nfev >= maxfev {
                info = Status::MaxEval;
                break 'outer;
            }
            if p1 * fmax(p1 * delta, pnorm) <= EPSMCH * xnorm {
                info = Status::XtolTooSmall;
                break 'outer;
            }
            if nslow2 == 5 || nslow1 == 10 {
                info = Status::Stalled;
                break 'outer;
            }

            if ncfail == 2 {
                break;
            }

            for j in 0..n {
                let mut sum = 0.0;
                for i in 0..n {
                    sum += fjac[i + j * n] * wa4[i];
                }
                wa2[j] = (sum - wa3[j]) / pnorm;
                wa1[j] = diag[j] * (diag[j] * wa1[j] / pnorm);
                if ratio >= p0001 {
                    qtf[j] = sum;
                }
            }
            let mut sing = false;
            r1updt(n, n, &mut r, &wa1, &mut wa2, &mut wa3, &mut sing);
            r1mpyq(n, n, &mut fjac, &wa2, &wa3);
            r1mpyq_row(n, &mut qtf, &wa2, &wa3);

            jeval = false;
        }
    }

    info
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn solves_linear() {
        let mut x = [0.0, 0.0];
        let mut f = [0.0, 0.0];
        let s = hybrd(
            &mut |x: &[f64], r: &mut [f64]| {
                r[0] = 2.0 * x[0] + x[1] - 5.0;
                r[1] = x[0] - x[1] - 1.0;
            },
            2, &mut x, &mut f, 1e-12, 2000, 1e-12, 100.0,
        );
        assert_eq!(s, Status::Converged);
        assert!((x[0] - 2.0).abs() < 1e-9 && (x[1] - 1.0).abs() < 1e-9, "x={x:?}");
    }

    #[test]
    fn solves_nonlinear() {
        let mut x = [2.0, 0.5];
        let mut f = [0.0, 0.0];
        let s = hybrd(
            &mut |x: &[f64], r: &mut [f64]| {
                r[0] = x[0] * x[0] + x[1] * x[1] - 2.0;
                r[1] = x[0] - x[1];
            },
            2, &mut x, &mut f, 1e-12, 2000, 1e-12, 100.0,
        );
        assert_eq!(s, Status::Converged);
        assert!((x[0] - 1.0).abs() < 1e-8 && (x[1] - 1.0).abs() < 1e-8, "x={x:?}");
    }

    #[test]
    fn solves_rosenbrock() {
        let mut x = [-1.2, 1.0];
        let mut f = [0.0, 0.0];
        let s = hybrd(
            &mut |x: &[f64], r: &mut [f64]| {
                r[0] = 1.0 - x[0];
                r[1] = 10.0 * (x[1] - x[0] * x[0]);
            },
            2, &mut x, &mut f, 1e-12, 2000, 1e-12, 100.0,
        );
        assert_eq!(s, Status::Converged);
        assert!((x[0] - 1.0).abs() < 1e-8 && (x[1] - 1.0).abs() < 1e-8, "x={x:?}");
    }

    #[test]
    fn hybrj_solves_nonlinear() {
        // Same system as `solves_nonlinear`, but with an analytic Jacobian.
        let mut x = [2.0, 0.5];
        let mut f = [0.0, 0.0];
        let s = hybrj(
            &mut |x: &[f64], r: &mut [f64]| {
                r[0] = x[0] * x[0] + x[1] * x[1] - 2.0;
                r[1] = x[0] - x[1];
            },
            &mut |x: &[f64], j: &mut [f64]| {
                // column-major: j[i + col*n]
                j[0] = 2.0 * x[0]; // dr0/dx0
                j[1] = 1.0; //        dr1/dx0
                j[2] = 2.0 * x[1]; // dr0/dx1
                j[3] = -1.0; //       dr1/dx1
            },
            2, &mut x, &mut f, 1e-12, 2000, 100.0,
        );
        assert_eq!(s, Status::Converged);
        assert!((x[0] - 1.0).abs() < 1e-9 && (x[1] - 1.0).abs() < 1e-9, "x={x:?}");
    }

    #[test]
    fn solves_larger_system() {
        // MINPACK trigonometric-style: x_i = cos(sum x) shifted; use a simple
        // diagonally-dominant nonlinear system with known root at all-ones.
        let n = 6;
        let mut x = vec![0.5f64; n];
        let mut f = vec![0.0f64; n];
        let s = hybrd(
            &mut |x: &[f64], r: &mut [f64]| {
                for i in 0..x.len() {
                    r[i] = x[i] * x[i] * x[i] - 1.0 + 0.1 * (x[(i + 1) % x.len()] - 1.0);
                }
            },
            n, &mut x, &mut f, 1e-12, 4000, 1e-12, 100.0,
        );
        assert_eq!(s, Status::Converged);
        for xi in &x {
            assert!((xi - 1.0).abs() < 1e-7, "x={x:?}");
        }
    }
}
