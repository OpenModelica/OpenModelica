//! `DTREVC`, and the `DLALN2`/`DLADIV` kernels under it: the eigenvectors of a
//! real quasi-upper-triangular Schur form, back-transformed through the Schur
//! basis.
//!
//! Translated line by line from the reference LAPACK Fortran (`SRC/dtrevc.f`,
//! `dlaln2.f`, `dladiv.f`), whose license is in `LICENSE-LAPACK` at the crate
//! root.
//!
//! Only `HOWMNY = "B"` is ported — every eigenvector, back-transformed in place
//! over the `Z` the caller passes — because that is what `DGEEV` asks for. The
//! choice matters beyond convenience: which of `(v_re, v_im)` and `(v_im, -v_re)`
//! comes back is a convention, not a mathematical fact, and it is DTREVC's
//! `WORK(KI-1)`/`WORK(KI+N2)` seeding that fixes it. Another solver's `trevc`
//! returns the same complex eigenvector rotated, which a model reading `evec`
//! sees.

use crate::blas::{at, daxpy, dscal, idamax};
use crate::hqr::ULP;
use crate::{abs, SAFMIN};

/// `DLADIV2`.
fn dladiv2(a: f64, b: f64, c: f64, d: f64, r: f64, t: f64) -> f64 {
    if r != 0.0 {
        let br = b * r;
        if br != 0.0 {
            (a + br) * t
        } else {
            a * t + (b * t) * r
        }
    } else {
        (a + d * (b / c)) * t
    }
}

/// `DLADIV1`.
fn dladiv1(a: f64, b: f64, c: f64, d: f64) -> (f64, f64) {
    let r = d / c;
    let t = 1.0 / (c + d * r);
    (dladiv2(a, b, c, d, r, t), dladiv2(b, -a, c, d, r, t))
}

/// `DLADIV`: `(a + i b) / (c + i d)`, scaled so neither part overflows on the way.
pub(crate) fn dladiv(a: f64, b: f64, c: f64, d: f64) -> (f64, f64) {
    const BS: f64 = 2.0;
    let (mut aa, mut bb, mut cc, mut dd) = (a, b, c, d);
    let ab = f64::max(abs(a), abs(b));
    let cd = f64::max(abs(c), abs(d));
    let mut s = 1.0f64;
    let ov = f64::MAX;
    let un = SAFMIN;
    let eps = f64::EPSILON;
    let be = BS / (eps * eps);
    if ab >= 0.5 * ov {
        aa *= 0.5;
        bb *= 0.5;
        s *= 2.0;
    }
    if cd >= 0.5 * ov {
        cc *= 0.5;
        dd *= 0.5;
        s *= 0.5;
    }
    if ab <= un * BS / eps {
        aa *= be;
        bb *= be;
        s /= be;
    }
    if cd <= un * BS / eps {
        cc *= be;
        dd *= be;
        s *= be;
    }
    let (p, q) = if abs(d) <= abs(c) {
        dladiv1(aa, bb, cc, dd)
    } else {
        let (p, q) = dladiv1(bb, aa, dd, cc);
        (p, -q)
    };
    (p * s, q * s)
}

/// `DLALN2`: solve the `na`×`na` system `(ca*op(A) - w*D) * X = s*B` for `X`,
/// where `w` is real (`nw == 1`) or complex (`nw == 2`, `X` and `B` then holding
/// a real and an imaginary column each). `d1`/`d2` are `D`'s diagonal.
///
/// Returns `(x, scale, xnorm, info)` with `x` in column-major `2`×`2` layout.
/// `scale` is never larger than 1 and `info = 1` says the system was perturbed to
/// keep it non-singular, which is how the caller learns the eigenvalue is close to
/// another.
#[allow(clippy::too_many_arguments)]
pub(crate) fn dlaln2(
    ltrans: bool,
    na: usize,
    nw: usize,
    smin: f64,
    ca: f64,
    a: &[f64],
    lda: usize,
    d1: f64,
    d2: f64,
    b: &[f64],
    ldb: usize,
    wr: f64,
    wi: f64,
) -> ([f64; 4], f64, f64, i32) {
    // Column-major, as CR/CI and X are in the Fortran: index 0 is (1,1), 1 is
    // (2,1), 2 is (1,2), 3 is (2,2).
    const ZSWAP: [bool; 4] = [false, false, true, true];
    const RSWAP: [bool; 4] = [false, true, false, true];
    const IPIVOT: [[usize; 4]; 4] =
        [[0, 1, 2, 3], [1, 0, 3, 2], [2, 3, 0, 1], [3, 2, 1, 0]];

    let smlnum = 2.0 * SAFMIN;
    let bignum = 1.0 / smlnum;
    let smini = f64::max(smin, smlnum);
    let mut info = 0;
    let mut scale = 1.0f64;
    let mut x = [0.0f64; 4];
    let bb = |i: usize, j: usize| at(b, ldb, i, j);

    if na == 1 {
        if nw == 1 {
            let mut csr = ca * at(a, lda, 0, 0) - wr * d1;
            let mut cnorm = abs(csr);
            if cnorm < smini {
                csr = smini;
                cnorm = smini;
                info = 1;
            }
            let bnorm = abs(bb(0, 0));
            if cnorm < 1.0 && bnorm > 1.0 && bnorm > bignum * cnorm {
                scale = 1.0 / bnorm;
            }
            x[0] = (bb(0, 0) * scale) / csr;
            return (x, scale, abs(x[0]), info);
        }
        let mut csr = ca * at(a, lda, 0, 0) - wr * d1;
        let mut csi = -wi * d1;
        let mut cnorm = abs(csr) + abs(csi);
        if cnorm < smini {
            csr = smini;
            csi = 0.0;
            cnorm = smini;
            info = 1;
        }
        let bnorm = abs(bb(0, 0)) + abs(bb(0, 1));
        if cnorm < 1.0 && bnorm > 1.0 && bnorm > bignum * cnorm {
            scale = 1.0 / bnorm;
        }
        let (p, q) = dladiv(scale * bb(0, 0), scale * bb(0, 1), csr, csi);
        x[0] = p;
        x[2] = q;
        return (x, scale, abs(p) + abs(q), info);
    }

    let mut cr = [0.0f64; 4];
    cr[0] = ca * at(a, lda, 0, 0) - wr * d1;
    cr[3] = ca * at(a, lda, 1, 1) - wr * d2;
    if ltrans {
        cr[2] = ca * at(a, lda, 1, 0);
        cr[1] = ca * at(a, lda, 0, 1);
    } else {
        cr[1] = ca * at(a, lda, 1, 0);
        cr[2] = ca * at(a, lda, 0, 1);
    }

    if nw == 1 {
        let mut cmax = 0.0f64;
        let mut icmax = 0usize;
        for (j, v) in cr.iter().enumerate() {
            if abs(*v) > cmax {
                cmax = abs(*v);
                icmax = j;
            }
        }
        if cmax < smini {
            // norm(C) below the perturbation floor: solve with smini*I instead.
            let bnorm = f64::max(abs(bb(0, 0)), abs(bb(1, 0)));
            if smini < 1.0 && bnorm > 1.0 && bnorm > bignum * smini {
                scale = 1.0 / bnorm;
            }
            let temp = scale / smini;
            x[0] = temp * bb(0, 0);
            x[1] = temp * bb(1, 0);
            return (x, scale, temp * bnorm, 1);
        }
        let ur11 = cr[icmax];
        let cr21 = cr[IPIVOT[icmax][1]];
        let ur12 = cr[IPIVOT[icmax][2]];
        let cr22 = cr[IPIVOT[icmax][3]];
        let ur11r = 1.0 / ur11;
        let lr21 = ur11r * cr21;
        let mut ur22 = cr22 - ur12 * lr21;
        if abs(ur22) < smini {
            ur22 = smini;
            info = 1;
        }
        let (br1, mut br2) = if RSWAP[icmax] { (bb(1, 0), bb(0, 0)) } else { (bb(0, 0), bb(1, 0)) };
        br2 -= lr21 * br1;
        let bbnd = f64::max(abs(br1 * (ur22 * ur11r)), abs(br2));
        if bbnd > 1.0 && abs(ur22) < 1.0 && bbnd >= bignum * abs(ur22) {
            scale = 1.0 / bbnd;
        }
        let xr2 = (br2 * scale) / ur22;
        let xr1 = (scale * br1) * ur11r - xr2 * (ur11r * ur12);
        if ZSWAP[icmax] {
            x[0] = xr2;
            x[1] = xr1;
        } else {
            x[0] = xr1;
            x[1] = xr2;
        }
        let mut xnorm = f64::max(abs(xr1), abs(xr2));
        if xnorm > 1.0 && cmax > 1.0 && xnorm > bignum / cmax {
            let temp = cmax / bignum;
            x[0] *= temp;
            x[1] *= temp;
            xnorm *= temp;
            scale *= temp;
        }
        return (x, scale, xnorm, info);
    }

    let ci = [-wi * d1, 0.0, 0.0, -wi * d2];
    let mut cmax = 0.0f64;
    let mut icmax = 0usize;
    for j in 0..4 {
        if abs(cr[j]) + abs(ci[j]) > cmax {
            cmax = abs(cr[j]) + abs(ci[j]);
            icmax = j;
        }
    }
    if cmax < smini {
        let bnorm = f64::max(abs(bb(0, 0)) + abs(bb(0, 1)), abs(bb(1, 0)) + abs(bb(1, 1)));
        if smini < 1.0 && bnorm > 1.0 && bnorm > bignum * smini {
            scale = 1.0 / bnorm;
        }
        let temp = scale / smini;
        x[0] = temp * bb(0, 0);
        x[1] = temp * bb(1, 0);
        x[2] = temp * bb(0, 1);
        x[3] = temp * bb(1, 1);
        return (x, scale, temp * bnorm, 1);
    }
    let (ur11, ui11) = (cr[icmax], ci[icmax]);
    let (cr21, ci21) = (cr[IPIVOT[icmax][1]], ci[IPIVOT[icmax][1]]);
    let (ur12, ui12) = (cr[IPIVOT[icmax][2]], ci[IPIVOT[icmax][2]]);
    let (cr22, ci22) = (cr[IPIVOT[icmax][3]], ci[IPIVOT[icmax][3]]);
    let (ur11r, ui11r, lr21, li21, ur12s, ui12s, mut ur22, mut ui22);
    if icmax == 0 || icmax == 3 {
        if abs(ur11) > abs(ui11) {
            let temp = ui11 / ur11;
            ur11r = 1.0 / (ur11 * (1.0 + temp * temp));
            ui11r = -temp * ur11r;
        } else {
            let temp = ur11 / ui11;
            ui11r = -1.0 / (ui11 * (1.0 + temp * temp));
            ur11r = -temp * ui11r;
        }
        lr21 = cr21 * ur11r;
        li21 = cr21 * ui11r;
        ur12s = ur12 * ur11r;
        ui12s = ur12 * ui11r;
        ur22 = cr22 - ur12 * lr21;
        ui22 = ci22 - ur12 * li21;
    } else {
        ur11r = 1.0 / ur11;
        ui11r = 0.0;
        lr21 = cr21 * ur11r;
        li21 = ci21 * ur11r;
        ur12s = ur12 * ur11r;
        ui12s = ui12 * ur11r;
        ur22 = cr22 - ur12 * lr21 + ui12 * li21;
        ui22 = -ur12 * li21 - ui12 * lr21;
    }
    let u22abs = abs(ur22) + abs(ui22);
    if u22abs < smini {
        ur22 = smini;
        ui22 = 0.0;
        info = 1;
    }
    let (mut br1, mut br2, mut bi1, mut bi2) = if RSWAP[icmax] {
        (bb(1, 0), bb(0, 0), bb(1, 1), bb(0, 1))
    } else {
        (bb(0, 0), bb(1, 0), bb(0, 1), bb(1, 1))
    };
    br2 = br2 - lr21 * br1 + li21 * bi1;
    bi2 = bi2 - li21 * br1 - lr21 * bi1;
    let bbnd = f64::max(
        (abs(br1) + abs(bi1)) * (u22abs * (abs(ur11r) + abs(ui11r))),
        abs(br2) + abs(bi2),
    );
    if bbnd > 1.0 && u22abs < 1.0 && bbnd >= bignum * u22abs {
        scale = 1.0 / bbnd;
        br1 *= scale;
        bi1 *= scale;
        br2 *= scale;
        bi2 *= scale;
    }
    let (xr2, xi2) = dladiv(br2, bi2, ur22, ui22);
    let xr1 = ur11r * br1 - ui11r * bi1 - ur12s * xr2 + ui12s * xi2;
    let xi1 = ui11r * br1 + ur11r * bi1 - ui12s * xr2 - ur12s * xi2;
    if ZSWAP[icmax] {
        x = [xr2, xr1, xi2, xi1];
    } else {
        x = [xr1, xr2, xi1, xi2];
    }
    let mut xnorm = f64::max(abs(xr1) + abs(xi1), abs(xr2) + abs(xi2));
    if xnorm > 1.0 && cmax > 1.0 && xnorm > bignum / cmax {
        let temp = cmax / bignum;
        for v in &mut x {
            *v *= temp;
        }
        xnorm *= temp;
        scale *= temp;
    }
    (x, scale, xnorm, info)
}

/// `DTREVC` with `howmny = "B"`: every eigenvector of the quasi-upper-triangular
/// `t`, back-transformed in place over the Schur basis in `v`.
///
/// `right` picks the side. A conjugate pair occupies columns `ki-1` (real part)
/// and `ki` (imaginary part), scaled so `max(|re| + |im|)` is 1; `DGEEV`
/// renormalizes afterwards.
pub(crate) fn dtrevc(right: bool, n: usize, t: &[f64], ldt: usize, v: &mut [f64], ldv: usize) {
    if n == 0 {
        return;
    }
    let unfl = SAFMIN;
    let smlnum = unfl * (n as f64 / ULP);
    let bignum = (1.0 - ULP) / smlnum;

    // work[j] is the 1-norm of T's strictly upper part in column j, the bound
    // DLALN2's scaling decisions are taken against.
    let mut cnorm = vec![0.0f64; n];
    if right {
        for j in 1..n {
            cnorm[j] = (0..j).map(|i| abs(at(t, ldt, i, j))).sum();
        }
    } else {
        for j in 0..n.saturating_sub(1) {
            cnorm[j] = (j + 1..n).map(|i| abs(at(t, ldt, i, j))).sum();
        }
    }
    let mut wk1 = vec![0.0f64; n];
    let mut wk2 = vec![0.0f64; n];

    if right {
        let mut ip = 0i32;
        let mut ki = n;
        while ki >= 1 {
            if ip == 1 {
                // The second half of a pair, already produced with the first.
                ip = 0;
                ki -= 1;
                continue;
            }
            if ki != 1 && at(t, ldt, ki - 1, ki - 2) != 0.0 {
                ip = -1;
            }
            let wr = at(t, ldt, ki - 1, ki - 1);
            let wi = if ip != 0 {
                crate::sqrt(abs(at(t, ldt, ki - 1, ki - 2))) * crate::sqrt(abs(at(t, ldt, ki - 2, ki - 1)))
            } else {
                0.0
            };
            let smin = f64::max(ULP * (abs(wr) + abs(wi)), smlnum);

            if ip == 0 {
                // Real eigenvalue: solve (T(1:ki-1,1:ki-1) - wr) x = -T(1:ki-1,ki).
                wk1[ki - 1] = 1.0;
                for k in 0..ki - 1 {
                    wk1[k] = -at(t, ldt, k, ki - 1);
                }
                let mut jnxt = ki - 1;
                let mut j = ki - 1;
                while j >= 1 {
                    if j > jnxt {
                        j -= 1;
                        continue;
                    }
                    let mut j1 = j;
                    jnxt = j - 1;
                    if j > 1 && at(t, ldt, j - 1, j - 2) != 0.0 {
                        j1 = j - 1;
                        jnxt = j.saturating_sub(2);
                    }
                    if j1 == j {
                        let (x, mut sc, xnorm, _) = dlaln2(
                            false, 1, 1, smin, 1.0, &t[(j - 1) + (j - 1) * ldt..], ldt, 1.0, 1.0,
                            &wk1[j - 1..], n, wr, 0.0,
                        );
                        let mut x11 = x[0];
                        if xnorm > 1.0 && cnorm[j - 1] > bignum / xnorm {
                            x11 /= xnorm;
                            sc /= xnorm;
                        }
                        if sc != 1.0 {
                            dscal(sc, &mut wk1[..ki]);
                        }
                        wk1[j - 1] = x11;
                        let col: Vec<f64> = (0..j - 1).map(|i| at(t, ldt, i, j - 1)).collect();
                        daxpy(-x11, &col, &mut wk1[..j - 1]);
                    } else {
                        let (x, mut sc, xnorm, _) = dlaln2(
                            false, 2, 1, smin, 1.0, &t[(j - 2) + (j - 2) * ldt..], ldt, 1.0, 1.0,
                            &wk1[j - 2..], n, wr, 0.0,
                        );
                        let (mut x11, mut x21) = (x[0], x[1]);
                        if xnorm > 1.0 {
                            let beta = f64::max(cnorm[j - 2], cnorm[j - 1]);
                            if beta > bignum / xnorm {
                                x11 /= xnorm;
                                x21 /= xnorm;
                                sc /= xnorm;
                            }
                        }
                        if sc != 1.0 {
                            dscal(sc, &mut wk1[..ki]);
                        }
                        wk1[j - 2] = x11;
                        wk1[j - 1] = x21;
                        let c1: Vec<f64> = (0..j - 2).map(|i| at(t, ldt, i, j - 2)).collect();
                        let c2: Vec<f64> = (0..j - 2).map(|i| at(t, ldt, i, j - 1)).collect();
                        daxpy(-x11, &c1, &mut wk1[..j - 2]);
                        daxpy(-x21, &c2, &mut wk1[..j - 2]);
                    }
                    if j == 1 {
                        break;
                    }
                    j -= 1;
                }
                gemv_into(v, ldv, n, ki - 1, &wk1, wk1[ki - 1], ki - 1);
                let ii = idamax(&v[(ki - 1) * ldv..(ki - 1) * ldv + n]);
                let remax = 1.0 / abs(at(v, ldv, ii, ki - 1));
                dscal(remax, &mut v[(ki - 1) * ldv..(ki - 1) * ldv + n]);
            } else {
                // Complex pair: the seeding that fixes which of (v_re, v_im) and
                // (v_im, -v_re) this is.
                if abs(at(t, ldt, ki - 2, ki - 1)) >= abs(at(t, ldt, ki - 1, ki - 2)) {
                    wk1[ki - 2] = 1.0;
                    wk2[ki - 1] = wi / at(t, ldt, ki - 2, ki - 1);
                } else {
                    wk1[ki - 2] = -wi / at(t, ldt, ki - 1, ki - 2);
                    wk2[ki - 1] = 1.0;
                }
                wk1[ki - 1] = 0.0;
                wk2[ki - 2] = 0.0;
                for k in 0..ki.saturating_sub(2) {
                    wk1[k] = -wk1[ki - 2] * at(t, ldt, k, ki - 2);
                    wk2[k] = -wk2[ki - 1] * at(t, ldt, k, ki - 1);
                }
                let mut jnxt = ki.saturating_sub(2);
                let mut j = ki.saturating_sub(2);
                while j >= 1 {
                    if j > jnxt {
                        j -= 1;
                        continue;
                    }
                    let mut j1 = j;
                    jnxt = j - 1;
                    if j > 1 && at(t, ldt, j - 1, j - 2) != 0.0 {
                        j1 = j - 1;
                        jnxt = j.saturating_sub(2);
                    }
                    if j1 == j {
                        let b = [wk1[j - 1], 0.0, wk2[j - 1], 0.0];
                        let (x, mut sc, xnorm, _) = dlaln2(
                            false, 1, 2, smin, 1.0, &t[(j - 1) + (j - 1) * ldt..], ldt, 1.0, 1.0,
                            &b, 2, wr, wi,
                        );
                        let (mut x11, mut x12) = (x[0], x[2]);
                        if xnorm > 1.0 && cnorm[j - 1] > bignum / xnorm {
                            x11 /= xnorm;
                            x12 /= xnorm;
                            sc /= xnorm;
                        }
                        if sc != 1.0 {
                            dscal(sc, &mut wk1[..ki]);
                            dscal(sc, &mut wk2[..ki]);
                        }
                        wk1[j - 1] = x11;
                        wk2[j - 1] = x12;
                        let col: Vec<f64> = (0..j - 1).map(|i| at(t, ldt, i, j - 1)).collect();
                        daxpy(-x11, &col, &mut wk1[..j - 1]);
                        daxpy(-x12, &col, &mut wk2[..j - 1]);
                    } else {
                        let b = [wk1[j - 2], wk1[j - 1], wk2[j - 2], wk2[j - 1]];
                        let (x, mut sc, xnorm, _) = dlaln2(
                            false, 2, 2, smin, 1.0, &t[(j - 2) + (j - 2) * ldt..], ldt, 1.0, 1.0,
                            &b, 2, wr, wi,
                        );
                        let (mut x11, mut x21, mut x12, mut x22) = (x[0], x[1], x[2], x[3]);
                        if xnorm > 1.0 {
                            let beta = f64::max(cnorm[j - 2], cnorm[j - 1]);
                            if beta > bignum / xnorm {
                                let rec = 1.0 / xnorm;
                                x11 *= rec;
                                x12 *= rec;
                                x21 *= rec;
                                x22 *= rec;
                                sc *= rec;
                            }
                        }
                        if sc != 1.0 {
                            dscal(sc, &mut wk1[..ki]);
                            dscal(sc, &mut wk2[..ki]);
                        }
                        wk1[j - 2] = x11;
                        wk1[j - 1] = x21;
                        wk2[j - 2] = x12;
                        wk2[j - 1] = x22;
                        let c1: Vec<f64> = (0..j - 2).map(|i| at(t, ldt, i, j - 2)).collect();
                        let c2: Vec<f64> = (0..j - 2).map(|i| at(t, ldt, i, j - 1)).collect();
                        daxpy(-x11, &c1, &mut wk1[..j - 2]);
                        daxpy(-x21, &c2, &mut wk1[..j - 2]);
                        daxpy(-x12, &c1, &mut wk2[..j - 2]);
                        daxpy(-x22, &c2, &mut wk2[..j - 2]);
                    }
                    if j == 1 {
                        break;
                    }
                    j -= 1;
                }
                if ki > 2 {
                    gemv_into(v, ldv, n, ki - 2, &wk1, wk1[ki - 2], ki - 2);
                    gemv_into(v, ldv, n, ki - 1, &wk2, wk2[ki - 1], ki - 2);
                } else {
                    let (f1, f2) = (wk1[ki - 2], wk2[ki - 1]);
                    dscal(f1, &mut v[(ki - 2) * ldv..(ki - 2) * ldv + n]);
                    dscal(f2, &mut v[(ki - 1) * ldv..(ki - 1) * ldv + n]);
                }
                let emax = (0..n)
                    .map(|k| abs(at(v, ldv, k, ki - 2)) + abs(at(v, ldv, k, ki - 1)))
                    .fold(0.0f64, f64::max);
                let remax = 1.0 / emax;
                dscal(remax, &mut v[(ki - 2) * ldv..(ki - 2) * ldv + n]);
                dscal(remax, &mut v[(ki - 1) * ldv..(ki - 1) * ldv + n]);
            }
            if ip == -1 {
                ip = 1;
            }
            if ki == 1 {
                break;
            }
            ki -= 1;
        }
    } else {
        left_eigenvectors(n, t, ldt, v, ldv, smlnum, bignum, &cnorm, &mut wk1, &mut wk2);
    }
}

/// `V(:, col) := V(:, 0..k)*x(0..k) + beta*V(:, col)`, DTREVC's back-transform
/// (`DGEMV` with `BETA` in the vector's own tail slot).
fn gemv_into(v: &mut [f64], ldv: usize, n: usize, col: usize, x: &[f64], beta: f64, k: usize) {
    let mut out = vec![0.0f64; n];
    for j in 0..k {
        let xj = x[j];
        if xj == 0.0 {
            continue;
        }
        for i in 0..n {
            out[i] += v[i + j * ldv] * xj;
        }
    }
    for i in 0..n {
        v[i + col * ldv] = out[i] + beta * v[i + col * ldv];
    }
}

/// The `LEFTV` half of DTREVC: the same recurrence read up the diagonal, over
/// `T'` rather than `T`.
#[allow(clippy::too_many_arguments)]
fn left_eigenvectors(
    n: usize,
    t: &[f64],
    ldt: usize,
    v: &mut [f64],
    ldv: usize,
    smlnum: f64,
    bignum: f64,
    cnorm: &[f64],
    wk1: &mut [f64],
    wk2: &mut [f64],
) {
    let mut ip = 0i32;
    let mut ki = 1usize;
    while ki <= n {
        if ip == -1 {
            ip = 0;
            ki += 1;
            continue;
        }
        if ki != n && at(t, ldt, ki, ki - 1) != 0.0 {
            ip = 1;
        }
        let wr = at(t, ldt, ki - 1, ki - 1);
        let wi = if ip != 0 {
            crate::sqrt(abs(at(t, ldt, ki - 1, ki))) * crate::sqrt(abs(at(t, ldt, ki, ki - 1)))
        } else {
            0.0
        };
        let smin = f64::max(ULP * (abs(wr) + abs(wi)), smlnum);

        if ip == 0 {
            wk1[ki - 1] = 1.0;
            for k in ki..n {
                wk1[k] = -at(t, ldt, ki - 1, k);
            }
            let mut jnxt = ki + 1;
            let mut j = ki + 1;
            while j <= n {
                if j < jnxt {
                    j += 1;
                    continue;
                }
                let mut j2 = j;
                jnxt = j + 1;
                if j < n && at(t, ldt, j, j - 1) != 0.0 {
                    j2 = j + 1;
                    jnxt = j + 2;
                }
                if j2 == j {
                    let (x, mut sc, xnorm, _) = dlaln2(
                        true, 1, 1, smin, 1.0, &t[(j - 1) + (j - 1) * ldt..], ldt, 1.0, 1.0,
                        &wk1[j - 1..], n, wr, 0.0,
                    );
                    let mut x11 = x[0];
                    if xnorm > 1.0 && cnorm[j - 1] > bignum / xnorm {
                        x11 /= xnorm;
                        sc /= xnorm;
                    }
                    if sc != 1.0 {
                        dscal(sc, &mut wk1[ki - 1..n]);
                    }
                    wk1[j - 1] = x11;
                    let row: Vec<f64> = (j..n).map(|c| at(t, ldt, j - 1, c)).collect();
                    daxpy(-x11, &row, &mut wk1[j..n]);
                } else {
                    let (x, mut sc, xnorm, _) = dlaln2(
                        true, 2, 1, smin, 1.0, &t[(j - 1) + (j - 1) * ldt..], ldt, 1.0, 1.0,
                        &wk1[j - 1..], n, wr, 0.0,
                    );
                    let (mut x11, mut x21) = (x[0], x[1]);
                    if xnorm > 1.0 {
                        let beta = f64::max(cnorm[j - 1], cnorm[j]);
                        if beta > bignum / xnorm {
                            x11 /= xnorm;
                            x21 /= xnorm;
                            sc /= xnorm;
                        }
                    }
                    if sc != 1.0 {
                        dscal(sc, &mut wk1[ki - 1..n]);
                    }
                    wk1[j - 1] = x11;
                    wk1[j] = x21;
                    let r1: Vec<f64> = (j + 1..n).map(|c| at(t, ldt, j - 1, c)).collect();
                    let r2: Vec<f64> = (j + 1..n).map(|c| at(t, ldt, j, c)).collect();
                    daxpy(-x11, &r1, &mut wk1[j + 1..n]);
                    daxpy(-x21, &r2, &mut wk1[j + 1..n]);
                }
                j += 1;
            }
            if ki < n {
                gemv_tail(v, ldv, n, ki - 1, wk1, wk1[ki - 1], ki);
            }
            let ii = idamax(&v[(ki - 1) * ldv..(ki - 1) * ldv + n]);
            let remax = 1.0 / abs(at(v, ldv, ii, ki - 1));
            dscal(remax, &mut v[(ki - 1) * ldv..(ki - 1) * ldv + n]);
        } else {
            if abs(at(t, ldt, ki - 1, ki)) >= abs(at(t, ldt, ki, ki - 1)) {
                wk1[ki - 1] = wi / at(t, ldt, ki - 1, ki);
                wk2[ki] = 1.0;
            } else {
                wk1[ki - 1] = 1.0;
                wk2[ki] = -wi / at(t, ldt, ki, ki - 1);
            }
            wk2[ki - 1] = 0.0;
            wk1[ki] = 0.0;
            for k in ki + 1..n {
                wk1[k] = -wk1[ki - 1] * at(t, ldt, ki - 1, k);
                wk2[k] = -wk2[ki] * at(t, ldt, ki, k);
            }
            let mut jnxt = ki + 2;
            let mut j = ki + 2;
            while j <= n {
                if j < jnxt {
                    j += 1;
                    continue;
                }
                let mut j2 = j;
                jnxt = j + 1;
                if j < n && at(t, ldt, j, j - 1) != 0.0 {
                    j2 = j + 1;
                    jnxt = j + 2;
                }
                if j2 == j {
                    let b = [wk1[j - 1], 0.0, wk2[j - 1], 0.0];
                    let (x, mut sc, xnorm, _) = dlaln2(
                        true, 1, 2, smin, 1.0, &t[(j - 1) + (j - 1) * ldt..], ldt, 1.0, 1.0, &b, 2,
                        wr, -wi,
                    );
                    let (mut x11, mut x12) = (x[0], x[2]);
                    if xnorm > 1.0 && cnorm[j - 1] > bignum / xnorm {
                        x11 /= xnorm;
                        x12 /= xnorm;
                        sc /= xnorm;
                    }
                    if sc != 1.0 {
                        dscal(sc, &mut wk1[ki - 1..n]);
                        dscal(sc, &mut wk2[ki - 1..n]);
                    }
                    wk1[j - 1] = x11;
                    wk2[j - 1] = x12;
                    let row: Vec<f64> = (j..n).map(|c| at(t, ldt, j - 1, c)).collect();
                    daxpy(-x11, &row, &mut wk1[j..n]);
                    daxpy(-x12, &row, &mut wk2[j..n]);
                } else {
                    let b = [wk1[j - 1], wk1[j], wk2[j - 1], wk2[j]];
                    let (x, mut sc, xnorm, _) = dlaln2(
                        true, 2, 2, smin, 1.0, &t[(j - 1) + (j - 1) * ldt..], ldt, 1.0, 1.0, &b, 2,
                        wr, -wi,
                    );
                    let (mut x11, mut x21, mut x12, mut x22) = (x[0], x[1], x[2], x[3]);
                    if xnorm > 1.0 {
                        let beta = f64::max(cnorm[j - 1], cnorm[j]);
                        if beta > bignum / xnorm {
                            let rec = 1.0 / xnorm;
                            x11 *= rec;
                            x12 *= rec;
                            x21 *= rec;
                            x22 *= rec;
                            sc *= rec;
                        }
                    }
                    if sc != 1.0 {
                        dscal(sc, &mut wk1[ki - 1..n]);
                        dscal(sc, &mut wk2[ki - 1..n]);
                    }
                    wk1[j - 1] = x11;
                    wk1[j] = x21;
                    wk2[j - 1] = x12;
                    wk2[j] = x22;
                    let r1: Vec<f64> = (j + 1..n).map(|c| at(t, ldt, j - 1, c)).collect();
                    let r2: Vec<f64> = (j + 1..n).map(|c| at(t, ldt, j, c)).collect();
                    daxpy(-x11, &r1, &mut wk1[j + 1..n]);
                    daxpy(-x21, &r2, &mut wk1[j + 1..n]);
                    daxpy(-x12, &r1, &mut wk2[j + 1..n]);
                    daxpy(-x22, &r2, &mut wk2[j + 1..n]);
                }
                j += 1;
            }
            if ki < n - 1 {
                gemv_tail(v, ldv, n, ki - 1, wk1, wk1[ki - 1], ki + 1);
                gemv_tail(v, ldv, n, ki, wk2, wk2[ki], ki + 1);
            } else {
                let (f1, f2) = (wk1[ki - 1], wk2[ki]);
                dscal(f1, &mut v[(ki - 1) * ldv..(ki - 1) * ldv + n]);
                dscal(f2, &mut v[ki * ldv..ki * ldv + n]);
            }
            let emax = (0..n)
                .map(|k| abs(at(v, ldv, k, ki - 1)) + abs(at(v, ldv, k, ki)))
                .fold(0.0f64, f64::max);
            let remax = 1.0 / emax;
            dscal(remax, &mut v[(ki - 1) * ldv..(ki - 1) * ldv + n]);
            dscal(remax, &mut v[ki * ldv..ki * ldv + n]);
        }
        if ip == 1 {
            ip = -1;
        }
        ki += 1;
    }
}

/// The left side's back-transform: `V(:, col) := V(:, from..n)*x(from..n) +
/// beta*V(:, col)`.
fn gemv_tail(v: &mut [f64], ldv: usize, n: usize, col: usize, x: &[f64], beta: f64, from: usize) {
    let mut out = vec![0.0f64; n];
    for j in from..n {
        let xj = x[j];
        if xj == 0.0 {
            continue;
        }
        for i in 0..n {
            out[i] += v[i + j * ldv] * xj;
        }
    }
    for i in 0..n {
        v[i + col * ldv] = out[i] + beta * v[i + col * ldv];
    }
}

/// `DTREVC` with LAPACK's argument list. `howmny = "A"` computes every
/// eigenvector of `t` itself, `"B"` back-transforms over the basis already in
/// `vl`/`vr` (what `DGEEV` does with the Schur vectors). `"S"` — a selected
/// subset — is not implemented and reports `INFO = -3`, the `select` position.
///
/// `side` is `"R"`, `"L"` or `"B"`. `m` receives the number of columns written,
/// which for `"A"`/`"B"` is `n`.
#[allow(clippy::too_many_arguments)]
pub fn dtrevc_lapack(
    side: &str,
    howmny: &str,
    n: usize,
    t: &[f64],
    ldt: usize,
    vl: &mut [f64],
    ldvl: usize,
    vr: &mut [f64],
    ldvr: usize,
    mm: usize,
    m: &mut i32,
) -> i32 {
    let side = crate::opt(side);
    let howmny = crate::opt(howmny);
    let (want_l, want_r) = (matches!(side, b'L' | b'B'), matches!(side, b'R' | b'B'));
    if !want_l && !want_r {
        return -1;
    }
    if !matches!(howmny, b'A' | b'B') {
        return -3;
    }
    if n > mm {
        return -11;
    }
    *m = n as i32;
    if n == 0 {
        return 0;
    }
    for (want, v, ldv, right) in
        [(want_l, &mut *vl, ldvl, false), (want_r, &mut *vr, ldvr, true)]
    {
        if !want {
            continue;
        }
        if howmny == b'A' {
            for j in 0..n {
                for i in 0..n {
                    crate::blas::set(v, ldv, i, j, if i == j { 1.0 } else { 0.0 });
                }
            }
        }
        dtrevc(right, n, t, ldt, v, ldv);
    }
    0
}
