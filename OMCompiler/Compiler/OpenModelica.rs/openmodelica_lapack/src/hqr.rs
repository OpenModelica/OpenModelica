//! `DGEBAL`, `DGEBAK`, `DLAHQR` and `DLANV2`: the QR-iteration path that
//! `DGEEV`, `DGEES` and `DHSEQR` are built from.
//!
//! Translated line by line from the reference LAPACK Fortran (`SRC/dgebal.f`,
//! `dgebak.f`, `dlahqr.f`, `dlanv2.f`), whose license is in `LICENSE-LAPACK` at
//! the crate root.
//!
//! Ported from the reference Fortran rather than delegated to a decomposition
//! library, because the *order* the eigenvalues come out in is observable:
//! `Modelica.Math.Matrices.eigenValues` hands `WR`/`WI` to the model as they
//! are, so a model reading element 1 sees any reordering. The order is decided
//! by DGEBAL's isolating permutation and by DLAHQR deflating from the bottom —
//! any other correct Schur form lists the same eigenvalues in another sequence.
//!
//! Indices are LAPACK's: 1-based, with `ihi` inclusive. [`g`] and [`s`] index a
//! column-major buffer that way, so each routine reads against its Fortran.
//!
//! For `n > 75` DHSEQR uses DLAQR0's multishift iteration, which is not ported;
//! [`dlahqr`] serves every size. The result is a Schur form either way, but above
//! 75 the diagonal order can differ from reference LAPACK's.

use crate::blas::{dlarfg, dnrm2, dscal, idamax};
use crate::{abs, hypot, opt, sqrt, SAFMIN};

/// `DLAMCH('P')`, the precision LAPACK's stopping criteria are written against —
/// twice [`crate::EPS`], which is `DLAMCH('E')`.
pub(crate) const ULP: f64 = f64::EPSILON;

/// `a(i, j)`, 1-based, column-major with leading dimension `lda`.
#[inline]
fn g(a: &[f64], lda: usize, i: usize, j: usize) -> f64 {
    a[(i - 1) + (j - 1) * lda]
}

/// `a(i, j) := v`, 1-based.
#[inline]
fn s(a: &mut [f64], lda: usize, i: usize, j: usize, v: f64) {
    a[(i - 1) + (j - 1) * lda] = v;
}

fn sign(x: f64, y: f64) -> f64 {
    libm::copysign(x, y)
}

/// `DLAPY2`.
pub(crate) fn dlapy2(x: f64, y: f64) -> f64 {
    hypot(x, y)
}

/// `DLARTG`: the Givens rotation with `[c s; -s c] * (f, gg)' = (r, 0)'`.
pub(crate) fn dlartg(f: f64, gg: f64) -> (f64, f64, f64) {
    let rtmin = sqrt(SAFMIN);
    let rtmax = sqrt(f64::MAX / 2.0);
    let (f1, g1) = (abs(f), abs(gg));
    if gg == 0.0 {
        (1.0, 0.0, f)
    } else if f == 0.0 {
        (0.0, sign(1.0, gg), g1)
    } else if f1 > rtmin && f1 < rtmax && g1 > rtmin && g1 < rtmax {
        let d = sqrt(f * f + gg * gg);
        let r = sign(d, f);
        (f1 / d, gg / r, r)
    } else {
        let u = f64::min(f64::MAX, f64::max(SAFMIN, f64::max(f1, g1)));
        let (fs, gs) = (f / u, gg / u);
        let d = sqrt(fs * fs + gs * gs);
        let r = sign(d, f);
        (abs(fs) / d, gs / r, r * u)
    }
}

/// `DROT` over two strided vectors inside one buffer.
pub(crate) fn drot(
    n: usize,
    a: &mut [f64],
    off_x: usize,
    incx: usize,
    off_y: usize,
    incy: usize,
    cs: f64,
    sn: f64,
) {
    for k in 0..n {
        let (ix, iy) = (off_x + k * incx, off_y + k * incy);
        let (x, y) = (a[ix], a[iy]);
        a[ix] = cs * x + sn * y;
        a[iy] = cs * y - sn * x;
    }
}

/// `DLASCL('G', …)`: multiply `x` by `cto/cfrom` in steps that neither overflow
/// nor flush to zero on the way.
pub(crate) fn dlascl(cfrom: f64, cto: f64, x: &mut [f64]) {
    let smlnum = SAFMIN;
    let bignum = 1.0 / smlnum;
    let (mut cfromc, mut ctoc) = (cfrom, cto);
    loop {
        let cfrom1 = cfromc * smlnum;
        let (mul, done);
        if cfrom1 == cfromc {
            // cfromc is an infinity: one step gets there.
            mul = ctoc / cfromc;
            done = true;
        } else {
            let cto1 = ctoc / bignum;
            if cto1 == ctoc {
                mul = ctoc;
                done = true;
            } else if abs(cfrom1) > abs(ctoc) && ctoc != 0.0 {
                mul = smlnum;
                done = false;
                cfromc = cfrom1;
            } else if abs(cto1) > abs(cfromc) {
                mul = bignum;
                done = false;
                ctoc = cto1;
            } else {
                mul = ctoc / cfromc;
                done = true;
            }
        }
        dscal(mul, x);
        if done {
            return;
        }
    }
}

/// `DGEBAL`: balance a general matrix. `job` is `"P"` (permute only), `"S"`
/// (scale only), `"B"` (both) or `"N"`. Returns `(ilo, ihi, scale)`: rows and
/// columns outside `ilo..=ihi` are already triangular, so the QR iteration skips
/// them, and `scale` carries the permutation as a source index and the scaling as
/// a factor — the encoding [`dgebak`] reads back.
///
/// `DGEES` asks for `"P"`: a permutation is orthogonal, so `Z` stays a real Schur
/// basis. `DGEEV` asks for `"B"`, whose diagonal scaling sharpens the eigenvalues
/// and is undone on the eigenvectors afterwards.
pub fn dgebal(job: &str, n: usize, a: &mut [f64], lda: usize) -> (usize, usize, Vec<f64>) {
    const SCLFAC: f64 = 2.0;
    const FACTOR: f64 = 0.95;
    let mut scale = vec![1.0f64; n];
    let (mut k, mut l) = (1usize, n);
    if n == 0 || opt(job) == b'N' {
        return (k, l, scale);
    }

    if opt(job) != b'S' {
        // Rows that isolate an eigenvalue go to the bottom. The Fortran DO bounds
        // are fixed on entry, so one sweep walks i down from the entry `l` while
        // `l` shrinks under it.
        loop {
            let mut noconv = false;
            let top = l;
            for i in (1..=top).rev() {
                if (1..=l).any(|j| i != j && g(a, lda, i, j) != 0.0) {
                    continue;
                }
                scale[l - 1] = i as f64;
                if i != l {
                    for r in 1..=l {
                        a.swap((r - 1) + (i - 1) * lda, (r - 1) + (l - 1) * lda);
                    }
                    for c in k..=n {
                        a.swap((i - 1) + (c - 1) * lda, (l - 1) + (c - 1) * lda);
                    }
                }
                noconv = true;
                if l == 1 {
                    return (1, 1, scale);
                }
                l -= 1;
            }
            if !noconv {
                break;
            }
        }
        // Then columns that isolate one, to the left.
        loop {
            let mut noconv = false;
            let bot = k;
            for j in bot..=l {
                if (k..=l).any(|i| i != j && g(a, lda, i, j) != 0.0) {
                    continue;
                }
                scale[k - 1] = j as f64;
                if j != k {
                    for r in 1..=l {
                        a.swap((r - 1) + (j - 1) * lda, (r - 1) + (k - 1) * lda);
                    }
                    for c in k..=n {
                        a.swap((j - 1) + (c - 1) * lda, (k - 1) + (c - 1) * lda);
                    }
                }
                noconv = true;
                k += 1;
            }
            if !noconv {
                break;
            }
        }
    }

    for i in k..=l {
        scale[i - 1] = 1.0;
    }
    if opt(job) == b'P' {
        return (k, l, scale);
    }

    // Scale row i down and column i up until their norms are within FACTOR of
    // each other. Powers of two only, so the scaling itself is exact.
    let sfmin1 = SAFMIN / ULP;
    let sfmax1 = 1.0 / sfmin1;
    let sfmin2 = sfmin1 * SCLFAC;
    let sfmax2 = 1.0 / sfmin2;
    loop {
        let mut noconv = false;
        for i in k..=l {
            let col: Vec<f64> = (k..=l).map(|r| g(a, lda, r, i)).collect();
            let row: Vec<f64> = (k..=l).map(|c| g(a, lda, i, c)).collect();
            let mut c = dnrm2(&col);
            let mut r = dnrm2(&row);
            let full_col: Vec<f64> = (1..=l).map(|rr| g(a, lda, rr, i)).collect();
            let mut ca = abs(full_col[idamax(&full_col)]);
            let full_row: Vec<f64> = (k..=n).map(|cc| g(a, lda, i, cc)).collect();
            let mut ra = abs(full_row[idamax(&full_row)]);
            if c == 0.0 || r == 0.0 {
                continue;
            }
            if (c + ca + r + ra).is_nan() {
                return (k, l, scale);
            }

            let mut gg = r / SCLFAC;
            let mut f = 1.0f64;
            let sum = c + r;
            while c < gg
                && f64::max(f, f64::max(c, ca)) < sfmax2
                && f64::min(r, f64::min(gg, ra)) > sfmin2
            {
                f *= SCLFAC;
                c *= SCLFAC;
                ca *= SCLFAC;
                r /= SCLFAC;
                gg /= SCLFAC;
                ra /= SCLFAC;
            }
            gg = c / SCLFAC;
            while gg >= r
                && f64::max(r, ra) < sfmax2
                && f64::min(f64::min(f, c), f64::min(gg, ca)) > sfmin2
            {
                f /= SCLFAC;
                c /= SCLFAC;
                gg /= SCLFAC;
                ca /= SCLFAC;
                r *= SCLFAC;
                ra *= SCLFAC;
            }

            if (c + r) >= FACTOR * sum {
                continue;
            }
            if f < 1.0 && scale[i - 1] < 1.0 && f * scale[i - 1] <= sfmin1 {
                continue;
            }
            if f > 1.0 && scale[i - 1] > 1.0 && scale[i - 1] >= sfmax1 / f {
                continue;
            }
            scale[i - 1] *= f;
            noconv = true;
            let inv = 1.0 / f;
            for cc in k..=n {
                let v = g(a, lda, i, cc);
                s(a, lda, i, cc, v * inv);
            }
            for rr in 1..=l {
                let v = g(a, lda, rr, i);
                s(a, lda, rr, i, v * f);
            }
        }
        if !noconv {
            return (k, l, scale);
        }
    }
}

/// `DGEBAK`: undo [`dgebal`] on the `m` eigenvectors in `v` — scale the rows back
/// (reciprocally for `side = "L"`), then unwind the permutation.
#[allow(clippy::too_many_arguments)]
pub fn dgebak(
    job: &str,
    side: &str,
    n: usize,
    ilo: usize,
    ihi: usize,
    scale: &[f64],
    m: usize,
    v: &mut [f64],
    ldv: usize,
) {
    let right = opt(side) == b'R';
    if m == 0 || opt(job) == b'N' {
        return;
    }
    if matches!(opt(job), b'S' | b'B') && ilo != ihi {
        for i in ilo..=ihi {
            let f = if right { scale[i - 1] } else { 1.0 / scale[i - 1] };
            for j in 1..=m {
                let x = g(v, ldv, i, j);
                s(v, ldv, i, j, x * f);
            }
        }
    }
    if matches!(opt(job), b'P' | b'B') {
        for i in (1..ilo).rev() {
            swap_rows_1based(v, ldv, m, i, scale[i - 1] as usize);
        }
        for i in ihi + 1..=n {
            swap_rows_1based(v, ldv, m, i, scale[i - 1] as usize);
        }
    }
}

fn swap_rows_1based(v: &mut [f64], ldv: usize, m: usize, i: usize, k: usize) {
    if i == k {
        return;
    }
    for j in 1..=m {
        v.swap((i - 1) + (j - 1) * ldv, (k - 1) + (j - 1) * ldv);
    }
}

/// `DLANV2`: put the 2×2 block `[a b; c d]` into standardized real Schur form and
/// report its eigenvalues. Returns `(a, b, c, d, rt1r, rt1i, rt2r, rt2i, cs, sn)`
/// — `c` is zero for real eigenvalues; a complex pair leaves the diagonal equal
/// and `b*c < 0`.
///
/// Without this standardization a trailing 2×2 whose eigenvalues turn out real is
/// never split, which is what makes a Schur implementation lacking it report
/// non-convergence on ordinary matrices.
pub fn dlanv2(
    mut a: f64,
    mut b: f64,
    mut c: f64,
    mut d: f64,
) -> (f64, f64, f64, f64, f64, f64, f64, f64, f64, f64) {
    const MULTPL: f64 = 4.0;
    // DLAMCH('B')**INT(LOG(SAFMIN/EPS)/LOG(DLAMCH('B'))/2): the power of two the
    // "make the diagonal equal" branch scales by to stay in range.
    let safmn2 = libm::pow(2.0, libm::trunc(libm::log(SAFMIN / ULP) / libm::log(2.0) / 2.0));
    let safmx2 = 1.0 / safmn2;

    let (mut cs, mut sn) = (1.0f64, 0.0f64);
    if c == 0.0 {
    } else if b == 0.0 {
        cs = 0.0;
        sn = 1.0;
        core::mem::swap(&mut a, &mut d);
        b = -c;
        c = 0.0;
    } else if (a - d) == 0.0 && sign(1.0, b) != sign(1.0, c) {
        // Already standardized: equal diagonal, opposite off-diagonal signs.
    } else {
        let mut temp = a - d;
        let mut p = 0.5 * temp;
        let bcmax = f64::max(abs(b), abs(c));
        let bcmis = f64::min(abs(b), abs(c)) * sign(1.0, b) * sign(1.0, c);
        let mut scale = f64::max(abs(p), bcmax);
        let mut z = (p / scale) * p + (bcmax / scale) * bcmis;

        if z >= MULTPL * ULP {
            // Real eigenvalues: the rotation that triangularizes.
            z = p + sign(sqrt(scale) * sqrt(z), p);
            a = d + z;
            d -= (bcmax / z) * bcmis;
            let tau = dlapy2(c, z);
            cs = z / tau;
            sn = c / tau;
            b -= c;
            c = 0.0;
        } else {
            // Complex, or real and (almost) equal: make the diagonal equal.
            let mut sigma = b + c;
            let mut count = 0;
            loop {
                count += 1;
                scale = f64::max(abs(temp), abs(sigma));
                if scale >= safmx2 && count <= 20 {
                    sigma *= safmn2;
                    temp *= safmn2;
                    continue;
                }
                if scale <= safmn2 && count <= 20 {
                    sigma *= safmx2;
                    temp *= safmx2;
                    continue;
                }
                break;
            }
            p = 0.5 * temp;
            let mut tau = dlapy2(sigma, temp);
            cs = sqrt(0.5 * (1.0 + abs(sigma) / tau));
            sn = -(p / (tau * cs)) * sign(1.0, sigma);

            let aa = a * cs + b * sn;
            let bb = -a * sn + b * cs;
            let cc = c * cs + d * sn;
            let dd = -c * sn + d * cs;
            a = aa * cs + cc * sn;
            b = (bb * cs) + (dd * sn);
            c = -(aa * sn) + (cc * cs);
            d = -bb * sn + dd * cs;
            let mid = 0.5 * (a + d);
            a = mid;
            d = mid;

            if c != 0.0 {
                if b != 0.0 {
                    if sign(1.0, b) == sign(1.0, c) {
                        // Real after all: reduce to upper triangular.
                        let sab = sqrt(abs(b));
                        let sac = sqrt(abs(c));
                        p = sign(sab * sac, c);
                        tau = 1.0 / sqrt(abs(b + c));
                        a = mid + p;
                        d = mid - p;
                        b -= c;
                        c = 0.0;
                        let cs1 = sab * tau;
                        let sn1 = sac * tau;
                        let t = cs * cs1 - sn * sn1;
                        sn = cs * sn1 + sn * cs1;
                        cs = t;
                    }
                } else {
                    b = -c;
                    c = 0.0;
                    let t = cs;
                    cs = -sn;
                    sn = t;
                }
            }
        }
    }

    let (rt1r, rt2r) = (a, d);
    let (rt1i, rt2i) = if c == 0.0 {
        (0.0, 0.0)
    } else {
        let im = sqrt(abs(b)) * sqrt(abs(c));
        (im, -im)
    };
    (a, b, c, d, rt1r, rt1i, rt2r, rt2i, cs, sn)
}

/// `DLAHQR`: the double-shift QR iteration on the upper Hessenberg `h`, over rows
/// and columns `ilo..=ihi`. `wantt` writes the Schur form back into `h`; `wantz`
/// accumulates the rotations into `z` over rows `iloz..=ihiz`.
///
/// Eigenvalues are stored where they deflate, so `wr[i]`/`wi[i]` belong to
/// position `i` of the Schur form and a conjugate pair keeps the positive
/// imaginary part first. Returns LAPACK's `INFO`: `0`, or the index of the first
/// eigenvalue that did not converge.
#[allow(clippy::too_many_arguments)]
pub fn dlahqr(
    wantt: bool,
    wantz: bool,
    n: usize,
    ilo: usize,
    ihi: usize,
    h: &mut [f64],
    ldh: usize,
    wr: &mut [f64],
    wi: &mut [f64],
    iloz: usize,
    ihiz: usize,
    z: &mut [f64],
    ldz: usize,
) -> i32 {
    const DAT1: f64 = 0.75;
    const DAT2: f64 = -0.4375;
    const KEXSH: usize = 10;

    if n == 0 {
        return 0;
    }
    if ilo == ihi {
        wr[ilo - 1] = g(h, ldh, ilo, ilo);
        wi[ilo - 1] = 0.0;
        return 0;
    }

    // A bulge an earlier sweep left below the subdiagonal would break the
    // Hessenberg assumption.
    let mut j = ilo;
    while j + 3 <= ihi {
        s(h, ldh, j + 2, j, 0.0);
        s(h, ldh, j + 3, j, 0.0);
        j += 1;
    }
    if ilo + 2 <= ihi {
        s(h, ldh, ihi, ihi - 2, 0.0);
    }

    let nh = ihi - ilo + 1;
    let nz = ihiz - iloz + 1;
    let smlnum = SAFMIN * (nh as f64 / ULP);
    let itmax = 30 * usize::max(10, nh);
    let mut kdefl = 0usize;

    // The rows and columns transformations reach: the whole matrix when the Schur
    // form is wanted, the active block only when it is not.
    let (mut i1, mut i2) = (1usize, n);

    let mut v = [0.0f64; 3];
    let mut i = ihi;
    loop {
        let mut l = ilo;
        if i < ilo {
            return 0;
        }
        let mut converged = false;
        for _its in 0..=itmax {
            let mut k = i;
            while k > l {
                if abs(g(h, ldh, k, k - 1)) <= smlnum {
                    break;
                }
                let mut tst = abs(g(h, ldh, k - 1, k - 1)) + abs(g(h, ldh, k, k));
                if tst == 0.0 {
                    if k >= ilo + 2 {
                        tst += abs(g(h, ldh, k - 1, k - 2));
                    }
                    if k + 1 <= ihi {
                        tst += abs(g(h, ldh, k + 1, k));
                    }
                }
                // Ahues & Tisseur's deflation criterion (LAWN 122): better founded
                // than comparing against the neighbouring diagonal alone.
                if abs(g(h, ldh, k, k - 1)) <= ULP * tst {
                    let ab = f64::max(abs(g(h, ldh, k, k - 1)), abs(g(h, ldh, k - 1, k)));
                    let ba = f64::min(abs(g(h, ldh, k, k - 1)), abs(g(h, ldh, k - 1, k)));
                    let d1 = abs(g(h, ldh, k, k));
                    let d2 = abs(g(h, ldh, k - 1, k - 1) - g(h, ldh, k, k));
                    let aa = f64::max(d1, d2);
                    let bb = f64::min(d1, d2);
                    let ss = aa + ab;
                    if ba * (ab / ss) <= f64::max(smlnum, ULP * (bb * (aa / ss))) {
                        break;
                    }
                }
                k -= 1;
            }
            l = k;
            if l > ilo {
                s(h, ldh, l, l - 1, 0.0);
            }
            if l + 1 >= i {
                converged = true;
                break;
            }
            kdefl += 1;
            if !wantt {
                i1 = l;
                i2 = i;
            }

            // Francis' double shift from the trailing 2×2, or an exceptional shift
            // when deflation has stalled for KEXSH iterations.
            let (h11, h12, h21, h22);
            if kdefl % (2 * KEXSH) == 0 {
                let ss = abs(g(h, ldh, i, i - 1)) + abs(g(h, ldh, i - 1, i - 2));
                h11 = DAT1 * ss + g(h, ldh, i, i);
                h12 = DAT2 * ss;
                h21 = ss;
                h22 = h11;
            } else if kdefl % KEXSH == 0 {
                let ss = abs(g(h, ldh, l + 1, l)) + abs(g(h, ldh, l + 2, l + 1));
                h11 = DAT1 * ss + g(h, ldh, l, l);
                h12 = DAT2 * ss;
                h21 = ss;
                h22 = h11;
            } else {
                h11 = g(h, ldh, i - 1, i - 1);
                h21 = g(h, ldh, i, i - 1);
                h12 = g(h, ldh, i - 1, i);
                h22 = g(h, ldh, i, i);
            }
            let (rt1r, rt1i, rt2r, rt2i) = shift_pair(h11, h12, h21, h22);

            // Where to start the bulge, and `v` for that m: the lowest m at which
            // starting would make h(m, m-1) negligible.
            let m;
            let mut mm = i - 2;
            loop {
                let mut h21s = g(h, ldh, mm + 1, mm);
                let ss = abs(g(h, ldh, mm, mm) - rt2r) + abs(rt2i) + abs(h21s);
                h21s = g(h, ldh, mm + 1, mm) / ss;
                v[0] = h21s * g(h, ldh, mm, mm + 1)
                    + (g(h, ldh, mm, mm) - rt1r) * ((g(h, ldh, mm, mm) - rt2r) / ss)
                    - rt1i * (rt2i / ss);
                v[1] = h21s * (g(h, ldh, mm, mm) + g(h, ldh, mm + 1, mm + 1) - rt1r - rt2r);
                v[2] = h21s * g(h, ldh, mm + 2, mm + 1);
                let ss = abs(v[0]) + abs(v[1]) + abs(v[2]);
                v[0] /= ss;
                v[1] /= ss;
                v[2] /= ss;
                if mm == l {
                    m = mm;
                    break;
                }
                let lhs = abs(g(h, ldh, mm, mm - 1)) * (abs(v[1]) + abs(v[2]));
                let rhs = ULP
                    * abs(v[0])
                    * (abs(g(h, ldh, mm - 1, mm - 1))
                        + abs(g(h, ldh, mm, mm))
                        + abs(g(h, ldh, mm + 1, mm + 1)));
                if lhs <= rhs {
                    m = mm;
                    break;
                }
                mm -= 1;
            }

            for kk in m..i {
                let nr = usize::min(3, i - kk + 1);
                if kk > m {
                    for (t, slot) in v[..nr].iter_mut().enumerate() {
                        *slot = g(h, ldh, kk + t, kk - 1);
                    }
                }
                let (beta, t1) = dlarfg(v[0], &mut v[1..nr]);
                v[0] = beta;
                if kk > m {
                    s(h, ldh, kk, kk - 1, v[0]);
                    s(h, ldh, kk + 1, kk - 1, 0.0);
                    if kk < i - 1 {
                        s(h, ldh, kk + 2, kk - 1, 0.0);
                    }
                } else if m > l {
                    // Not `-h(kk, kk-1)`: that loses the value when v(2) and v(3)
                    // underflow.
                    let x = g(h, ldh, kk, kk - 1);
                    s(h, ldh, kk, kk - 1, x * (1.0 - t1));
                }
                let v2 = v[1];
                let t2 = t1 * v2;
                if nr == 3 {
                    let v3 = v[2];
                    let t3 = t1 * v3;
                    for j in kk..=i2 {
                        let sum =
                            g(h, ldh, kk, j) + v2 * g(h, ldh, kk + 1, j) + v3 * g(h, ldh, kk + 2, j);
                        s(h, ldh, kk, j, g(h, ldh, kk, j) - sum * t1);
                        s(h, ldh, kk + 1, j, g(h, ldh, kk + 1, j) - sum * t2);
                        s(h, ldh, kk + 2, j, g(h, ldh, kk + 2, j) - sum * t3);
                    }
                    for j in i1..=usize::min(kk + 3, i) {
                        let sum =
                            g(h, ldh, j, kk) + v2 * g(h, ldh, j, kk + 1) + v3 * g(h, ldh, j, kk + 2);
                        s(h, ldh, j, kk, g(h, ldh, j, kk) - sum * t1);
                        s(h, ldh, j, kk + 1, g(h, ldh, j, kk + 1) - sum * t2);
                        s(h, ldh, j, kk + 2, g(h, ldh, j, kk + 2) - sum * t3);
                    }
                    if wantz {
                        for j in iloz..=ihiz {
                            let sum = g(z, ldz, j, kk)
                                + v2 * g(z, ldz, j, kk + 1)
                                + v3 * g(z, ldz, j, kk + 2);
                            s(z, ldz, j, kk, g(z, ldz, j, kk) - sum * t1);
                            s(z, ldz, j, kk + 1, g(z, ldz, j, kk + 1) - sum * t2);
                            s(z, ldz, j, kk + 2, g(z, ldz, j, kk + 2) - sum * t3);
                        }
                    }
                } else if nr == 2 {
                    for j in kk..=i2 {
                        let sum = g(h, ldh, kk, j) + v2 * g(h, ldh, kk + 1, j);
                        s(h, ldh, kk, j, g(h, ldh, kk, j) - sum * t1);
                        s(h, ldh, kk + 1, j, g(h, ldh, kk + 1, j) - sum * t2);
                    }
                    for j in i1..=i {
                        let sum = g(h, ldh, j, kk) + v2 * g(h, ldh, j, kk + 1);
                        s(h, ldh, j, kk, g(h, ldh, j, kk) - sum * t1);
                        s(h, ldh, j, kk + 1, g(h, ldh, j, kk + 1) - sum * t2);
                    }
                    if wantz {
                        for j in iloz..=ihiz {
                            let sum = g(z, ldz, j, kk) + v2 * g(z, ldz, j, kk + 1);
                            s(z, ldz, j, kk, g(z, ldz, j, kk) - sum * t1);
                            s(z, ldz, j, kk + 1, g(z, ldz, j, kk + 1) - sum * t2);
                        }
                    }
                }
            }
        }
        if !converged {
            return i as i32;
        }

        if l == i {
            wr[i - 1] = g(h, ldh, i, i);
            wi[i - 1] = 0.0;
        } else if l + 1 == i {
            let (aa, bb, cc, dd, rt1r, rt1i, rt2r, rt2i, cs, sn) = dlanv2(
                g(h, ldh, i - 1, i - 1),
                g(h, ldh, i - 1, i),
                g(h, ldh, i, i - 1),
                g(h, ldh, i, i),
            );
            s(h, ldh, i - 1, i - 1, aa);
            s(h, ldh, i - 1, i, bb);
            s(h, ldh, i, i - 1, cc);
            s(h, ldh, i, i, dd);
            wr[i - 2] = rt1r;
            wi[i - 2] = rt1i;
            wr[i - 1] = rt2r;
            wi[i - 1] = rt2i;
            if wantt {
                if i2 > i {
                    drot(i2 - i, h, (i - 2) + i * ldh, ldh, (i - 1) + i * ldh, ldh, cs, sn);
                }
                if i > i1 + 1 {
                    drot(i - i1 - 1, h, (i1 - 1) + (i - 2) * ldh, 1, (i1 - 1) + (i - 1) * ldh, 1, cs, sn);
                }
            }
            if wantz {
                drot(nz, z, (iloz - 1) + (i - 2) * ldz, 1, (iloz - 1) + (i - 1) * ldz, 1, cs, sn);
            }
        }
        kdefl = 0;
        if l <= 1 {
            return 0;
        }
        i = l - 1;
    }
}

/// DLAHQR's shift: the eigenvalues of the scaled 2×2, as a conjugate pair or —
/// taking whichever root sits closer to `h22`, twice — a real one.
fn shift_pair(h11: f64, h12: f64, h21: f64, h22: f64) -> (f64, f64, f64, f64) {
    let ss = abs(h11) + abs(h12) + abs(h21) + abs(h22);
    if ss == 0.0 {
        return (0.0, 0.0, 0.0, 0.0);
    }
    let (h11, h21, h12, h22) = (h11 / ss, h21 / ss, h12 / ss, h22 / ss);
    let tr = (h11 + h22) / 2.0;
    let det = (h11 - tr) * (h22 - tr) - h12 * h21;
    let rtdisc = sqrt(abs(det));
    if det >= 0.0 {
        let rt1r = tr * ss;
        (rt1r, rtdisc * ss, rt1r, -(rtdisc * ss))
    } else {
        let r1 = tr + rtdisc;
        let r2 = tr - rtdisc;
        let r = if abs(r1 - h22) <= abs(r2 - h22) { r1 * ss } else { r2 * ss };
        (r, 0.0, r, 0.0)
    }
}
