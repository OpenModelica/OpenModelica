//! Port of `ddaskr.c`: the DASKR / DASSL variable-order, variable-step BDF
//! solver for differential-algebraic systems `G(t, y, y') = 0`, with optional
//! root-finding and (Krylov) iterative linear solves.
//!
//! ## Data model
//!
//! DASKR is a Fortran 77 code: it keeps *all* persistent state in two
//! user-supplied work arrays (`rwork`, `iwork`) and threads overlapping
//! sub-pointers of them through its ~30 subroutines — aliasing that Rust's
//! borrow checker forbids. To stay a faithful 1:1 translation (and so the
//! bit-exact cross-check against the C is a direct comparison) the port keeps
//! the same model: array parameters are raw pointers, accessed 1-based through
//! the `at!` / `at2!` macros, exactly mirroring the f2c pointer arithmetic.
//! The public entry point is safe; the internals are `unsafe`.
//!
//! Indices and increments are kept in `i32` (the C `integer`); reductions keep
//! the original operation order. See `tests/cref.rs` for the equivalence tests.

#![allow(
    clippy::too_many_arguments,
    clippy::missing_safety_doc,
    clippy::manual_range_contains,
    // The following mirror the C control flow / expression structure verbatim
    // (`x = x + y`, nested `if`s, identical branches) and are kept faithful.
    clippy::assign_op_pattern,
    clippy::collapsible_if,
    clippy::if_same_then_else,
    unsafe_op_in_unsafe_fn,
    dead_code,
    // f2c declares locals uninitialized (`doublereal terk;`) and may assign them
    // on every path before use; Rust requires an initializer, leaving dead
    // initial stores. Keeping them mirrors the C 1:1 rather than restructuring.
    unused_assignments,
    unused_mut
)]

use crate::aux::{real_pow, real_sign, xerrwd};
use crate::linpack;
use core::slice;

/// 1-based element access mirroring f2c's `arr[i]` after a `--arr` adjustment:
/// `at!(p, i)` is the place `*(p + (i - 1))`. Works for any pointer type and is
/// usable as both an rvalue and an lvalue. Must be used in an `unsafe` context.
macro_rules! at {
    ($p:expr, $i:expr) => {
        (*($p).offset((($i) - 1) as isize))
    };
}

/// 1-based column-major matrix access: element `(i, j)` of an array with leading
/// dimension `d`, i.e. `*(p + (i - 1) + (j - 1) * d)`.
macro_rules! at2 {
    ($p:expr, $i:expr, $j:expr, $d:expr) => {
        (*($p).offset(((($i) - 1) + (($j) - 1) * ($d)) as isize))
    };
}

/// Build a `&[f64]` of length `n` from a raw pointer for an immediate BLAS call.
#[inline]
unsafe fn rsl<'a>(p: *const f64, n: i32) -> &'a [f64] {
    slice::from_raw_parts(p, n as usize)
}
/// Build a `&mut [f64]` of length `n` from a raw pointer for an immediate BLAS call.
#[inline]
unsafe fn rslm<'a>(p: *mut f64, n: i32) -> &'a mut [f64] {
    slice::from_raw_parts_mut(p, n as usize)
}

// --- callback signatures (Fortran calling convention, all by pointer) -------

/// Residual `G(t, y, y')`: arguments `(t, y, yprime, cj, delta, ires, rpar,
/// ipar)`. Writes the residual into `delta`; sets `*ires < 0` to signal trouble.
pub type ResFn = unsafe fn(
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    cj: *mut f64,
    delta: *mut f64,
    ires: *mut i32,
    rpar: *mut f64,
    ipar: *mut i32,
);

/// Dense/banded analytic Jacobian: `(t, y, yprime, pd, delta, cj, h, wt, rpar,
/// ipar)`. `pd` is the iteration matrix to fill in.
pub type JacFn = unsafe fn(
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    pd: *mut f64,
    delta: *mut f64,
    cj: *mut f64,
    h: *mut f64,
    wt: *mut f64,
    rpar: *mut f64,
    ipar: *mut i32,
);

/// Root (constraint) function: `(neq, t, y, yprime, nrt, rval, rpar, ipar)`.
/// Fills `rval[0..nrt]` with the values whose zeros are sought.
pub type RtFn = unsafe fn(
    neq: *mut i32,
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    nrt: *mut i32,
    rval: *mut f64,
    rpar: *mut f64,
    ipar: *mut i32,
);

/// Krylov Jacobian/preconditioner setup `jac`:
/// `(res, ires, neq, t, y, yprime, rewt, savr, wk, h, cj, wp, iwp, ier, rpar, ipar)`.
pub type JacKFn = unsafe fn(
    res: ResFn,
    ires: *mut i32,
    neq: *mut i32,
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    rewt: *mut f64,
    savr: *mut f64,
    wk: *mut f64,
    h: *mut f64,
    cj: *mut f64,
    wp: *mut f64,
    iwp: *mut i32,
    ier: *mut i32,
    rpar: *mut f64,
    ipar: *mut i32,
);

/// Krylov preconditioner solve `psol`:
/// `(neq, t, y, yprime, savr, wk, cj, wt, wp, iwp, b, eplin, ier, rpar, ipar)`.
pub type PsolFn = unsafe fn(
    neq: *mut i32,
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    savr: *mut f64,
    wk: *mut f64,
    cj: *mut f64,
    wt: *mut f64,
    wp: *mut f64,
    iwp: *mut i32,
    b: *mut f64,
    eplin: *mut f64,
    ier: *mut i32,
    rpar: *mut f64,
    ipar: *mut i32,
);

// ===========================================================================
// Leaf helpers
// ===========================================================================

/// `DDAWTS` — set the error-weight vector `WT(i) = RTOL*|Y(i)| + ATOL`
/// (`RTOL`/`ATOL` are scalars when `iwt == 0`, vectors when `iwt == 1`).
pub(crate) unsafe fn ddawts(
    neq: i32,
    iwt: i32,
    rtol: *mut f64,
    atol: *mut f64,
    y: *mut f64,
    wt: *mut f64,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
    let mut rtoli = at!(rtol, 1);
    let mut atoli = at!(atol, 1);
    for i in 1..=neq {
        if iwt != 0 {
            rtoli = at!(rtol, i);
            atoli = at!(atol, i);
        }
        at!(wt, i) = rtoli * at!(y, i).abs() + atoli;
    }
}

/// `DINVWT` — check `WT` for non-positive entries; if all positive, invert in
/// place (so norms can multiply instead of divide). `*ier` is 0 on success, or
/// the index of the first non-positive weight.
pub(crate) unsafe fn dinvwt(neq: i32, wt: *mut f64, ier: &mut i32) {
    for i in 1..=neq {
        if at!(wt, i) <= 0.0 {
            *ier = i;
            return;
        }
    }
    for i in 1..=neq {
        at!(wt, i) = 1.0 / at!(wt, i);
    }
    *ier = 0;
}

/// `DDATRP` — interpolate the BDF polynomial (and its derivative) to time
/// `xout`, producing `yout`/`ypout`. `phi` are the scaled divided differences,
/// `psi` the stepsize history.
pub(crate) unsafe fn ddatrp(
    x: f64,
    xout: f64,
    yout: *mut f64,
    ypout: *mut f64,
    neq: i32,
    kold: i32,
    phi: *mut f64,
    psi: *mut f64,
) {
    let koldp1 = kold + 1;
    let temp1 = xout - x;
    for i in 1..=neq {
        at!(yout, i) = at2!(phi, i, 1, neq);
        at!(ypout, i) = 0.0;
    }
    let mut c = 1.0;
    let mut d = 0.0;
    let mut gamma = temp1 / at!(psi, 1);
    for j in 2..=koldp1 {
        d = d * gamma + c / at!(psi, j - 1);
        c *= gamma;
        gamma = (temp1 + at!(psi, j - 1)) / at!(psi, j);
        for i in 1..=neq {
            at!(yout, i) += c * at2!(phi, i, j, neq);
            at!(ypout, i) += d * at2!(phi, i, j, neq);
        }
    }
}

/// `DDWNRM` — weighted RMS norm `sqrt((1/neq) * sum (v_i * rwt_i)^2)`, where
/// `rwt` holds *reciprocal* weights, computed with scaling to avoid overflow.
pub(crate) unsafe fn ddwnrm(
    neq: i32,
    v: *mut f64,
    rwt: *mut f64,
    _rpar: *mut f64,
    _ipar: *mut i32,
) -> f64 {
    let mut vmax = 0.0f64;
    for i in 1..=neq {
        let a = (at!(v, i) * at!(rwt, i)).abs();
        if a > vmax {
            vmax = a;
        }
    }
    if vmax <= 0.0 {
        return 0.0;
    }
    let mut sum = 0.0f64;
    for i in 1..=neq {
        let d = at!(v, i) * at!(rwt, i) / vmax;
        sum += d * d;
    }
    vmax * (sum / neq as f64).sqrt()
}

/// `DYYPNW` — form the new `(ynew, ypnew)` pair for a linesearch step of length
/// `rl` along Newton direction `p`, honouring the IC-mode (`icopt`/`id`).
pub(crate) unsafe fn dyypnw(
    neq: i32,
    y: *mut f64,
    yprime: *mut f64,
    cj: f64,
    rl: f64,
    p: *mut f64,
    icopt: i32,
    id: *mut i32,
    ynew: *mut f64,
    ypnew: *mut f64,
) {
    if icopt == 1 {
        for i in 1..=neq {
            if at!(id, i) < 0 {
                at!(ynew, i) = at!(y, i) - rl * at!(p, i);
                at!(ypnew, i) = at!(yprime, i);
            } else {
                at!(ynew, i) = at!(y, i);
                at!(ypnew, i) = at!(yprime, i) - rl * cj * at!(p, i);
            }
        }
    } else {
        for i in 1..=neq {
            at!(ynew, i) = at!(y, i) - rl * at!(p, i);
            at!(ypnew, i) = at!(yprime, i);
        }
    }
}

/// `DCNSTR` — check the proposed step `ynew` against the constraint flags
/// `icnstr`; on a violation, shrink the linesearch length `tau` and set
/// `*iret = 1` (`*ivar` = offending index).
pub(crate) unsafe fn dcnstr(
    neq: i32,
    y: *mut f64,
    ynew: *mut f64,
    icnstr: *mut i32,
    tau: &mut f64,
    rlx: f64,
    iret: &mut i32,
    ivar: &mut i32,
) {
    const FAC: f64 = 0.6;
    const FAC2: f64 = 0.9;
    *iret = 0;
    let mut rdymx = 0.0f64;
    *ivar = 0;
    for i in 1..=neq {
        let c = at!(icnstr, i);
        if c == 2 {
            let rdy = ((at!(ynew, i) - at!(y, i)) / at!(y, i)).abs();
            if rdy > rdymx {
                rdymx = rdy;
                *ivar = i;
            }
            if at!(ynew, i) <= 0.0 {
                *tau = FAC * *tau;
                *ivar = i;
                *iret = 1;
                return;
            }
        } else if c == 1 {
            if at!(ynew, i) < 0.0 {
                *tau = FAC * *tau;
                *ivar = i;
                *iret = 1;
                return;
            }
        } else if c == -1 {
            if at!(ynew, i) > 0.0 {
                *tau = FAC * *tau;
                *ivar = i;
                *iret = 1;
                return;
            }
        } else if c == -2 {
            let rdy = ((at!(ynew, i) - at!(y, i)) / at!(y, i)).abs();
            if rdy > rdymx {
                rdymx = rdy;
                *ivar = i;
            }
            if at!(ynew, i) >= 0.0 {
                *tau = FAC * *tau;
                *ivar = i;
                *iret = 1;
                return;
            }
        }
    }
    if rdymx >= rlx {
        *tau = FAC2 * *tau * rlx / rdymx;
        *iret = 1;
    }
}

/// `DCNST0` — check the initial guess `y` against the constraint flags; sets
/// `*iret` to the first violated index (0 if all satisfied).
pub(crate) unsafe fn dcnst0(neq: i32, y: *mut f64, icnstr: *mut i32, iret: &mut i32) {
    *iret = 0;
    for i in 1..=neq {
        let c = at!(icnstr, i);
        if c == 2 {
            if at!(y, i) <= 0.0 {
                *iret = i;
                return;
            }
        } else if c == 1 {
            if at!(y, i) < 0.0 {
                *iret = i;
                return;
            }
        } else if c == -1 {
            if at!(y, i) > 0.0 {
                *iret = i;
                return;
            }
        } else if c == -2 {
            if at!(y, i) >= 0.0 {
                *iret = i;
                return;
            }
        }
    }
}

// ===========================================================================
// Direct (dense/banded) nonlinear corrector path
// ===========================================================================

/// `DSLVD` — solve the linear system in the Newton iteration using the factored
/// iteration matrix stored in `wm`/`iwm` (LINPACK `dgesl`/`dgbsl`).
pub(crate) unsafe fn dslvd(neq: i32, delta: *mut f64, wm: *mut f64, iwm: *mut i32) {
    let lipvt = at!(iwm, 30);
    let mtype = at!(iwm, 4);
    match mtype {
        1 | 2 => {
            let a = slice::from_raw_parts(wm, (neq * neq) as usize);
            let ipvt = slice::from_raw_parts(iwm.offset((lipvt - 1) as isize), neq as usize);
            let b = slice::from_raw_parts_mut(delta, neq as usize);
            linpack::dgesl(a, neq, neq, ipvt, b, 0);
        }
        3 => {}
        4 | 5 => {
            let meband = (at!(iwm, 1) << 1) + at!(iwm, 2) + 1;
            let a = slice::from_raw_parts(wm, (meband * neq) as usize);
            let ipvt = slice::from_raw_parts(iwm.offset((lipvt - 1) as isize), neq as usize);
            let b = slice::from_raw_parts_mut(delta, neq as usize);
            linpack::dgbsl(a, meband, neq, at!(iwm, 1), at!(iwm, 2), ipvt, b, 0);
        }
        _ => {}
    }
}

/// `DMATD` — form and LU-factor the iteration matrix `J = dG/dY + CJ*dG/dY'`,
/// either from the user Jacobian (`mtype` 1/4) or by difference quotients
/// (`mtype` 2/5), dense or banded. `*ier != 0` flags a singular factor.
pub(crate) unsafe fn dmatd(
    neq: i32,
    x: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    delta: *mut f64,
    cj: *mut f64,
    h: *mut f64,
    ier: *mut i32,
    ewt: *mut f64,
    e: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    res: ResFn,
    ires: *mut i32,
    uround: *mut f64,
    jacd: JacFn,
    rpar: *mut f64,
    ipar: *mut i32,
) {
    let lipvt = at!(iwm, 30);
    *ier = 0;
    let mtype = at!(iwm, 4);

    // Factor helpers (shared exits L230 dense / L550 banded).
    macro_rules! dense_factor {
        () => {{
            let a = slice::from_raw_parts_mut(wm, (neq * neq) as usize);
            let ipvt = slice::from_raw_parts_mut(iwm.offset((lipvt - 1) as isize), neq as usize);
            linpack::dgefa(a, neq, neq, ipvt, &mut *ier);
        }};
    }
    macro_rules! band_factor {
        ($meband:expr) => {{
            let meband = $meband;
            let a = slice::from_raw_parts_mut(wm, (meband * neq) as usize);
            let ipvt = slice::from_raw_parts_mut(iwm.offset((lipvt - 1) as isize), neq as usize);
            linpack::dgbfa(a, meband, neq, at!(iwm, 1), at!(iwm, 2), ipvt, &mut *ier);
        }};
    }

    match mtype {
        // Dense user-supplied matrix.
        1 => {
            let lenpd = at!(iwm, 22);
            for i in 1..=lenpd {
                at!(wm, i) = 0.0;
            }
            jacd(x, y, yprime, delta, wm, cj, h, ewt, rpar, ipar);
            dense_factor!();
        }
        // Dense finite-difference-generated matrix.
        2 => {
            *ires = 0;
            let mut nrow = 0i32;
            let squr = (*uround).sqrt();
            for i in 1..=neq {
                let d5 = at!(y, i).abs();
                let d6 = (*h * at!(yprime, i)).abs();
                let mut del = (squr * d5.max(d6)).max(1.0 / at!(ewt, i));
                del = real_sign(del, *h * at!(yprime, i));
                del = at!(y, i) + del - at!(y, i);
                let ysave = at!(y, i);
                let ypsave = at!(yprime, i);
                at!(y, i) += del;
                at!(yprime, i) += *cj * del;
                at!(iwm, 12) += 1;
                res(x, y, yprime, cj, e, ires, rpar, ipar);
                if *ires < 0 {
                    return;
                }
                let delinv = 1.0 / del;
                for l in 1..=neq {
                    at!(wm, nrow + l) = (at!(e, l) - at!(delta, l)) * delinv;
                }
                nrow += neq;
                at!(y, i) = ysave;
                at!(yprime, i) = ypsave;
            }
            dense_factor!();
        }
        // Dummy section for mtype 3.
        3 => {}
        // Banded user-supplied matrix.
        4 => {
            let lenpd = at!(iwm, 22);
            for i in 1..=lenpd {
                at!(wm, i) = 0.0;
            }
            jacd(x, y, yprime, delta, wm, cj, h, ewt, rpar, ipar);
            let meband = (at!(iwm, 1) << 1) + at!(iwm, 2) + 1;
            band_factor!(meband);
        }
        // Banded finite-difference-generated matrix.
        5 => {
            let mband = at!(iwm, 1) + at!(iwm, 2) + 1;
            let mba = mband.min(neq);
            let meband = mband + at!(iwm, 1);
            let meb1 = meband - 1;
            let msave = neq / mband + 1;
            let isave = at!(iwm, 22);
            let ipsave = isave + msave;
            *ires = 0;
            let squr = (*uround).sqrt();
            for j in 1..=mba {
                let mut n = j;
                while n <= neq {
                    let k = (n - j) / mband + 1;
                    at!(wm, isave + k) = at!(y, n);
                    at!(wm, ipsave + k) = at!(yprime, n);
                    let d5 = at!(y, n).abs();
                    let d6 = (*h * at!(yprime, n)).abs();
                    let mut del = (squr * d5.max(d6)).max(1.0 / at!(ewt, n));
                    del = real_sign(del, *h * at!(yprime, n));
                    del = at!(y, n) + del - at!(y, n);
                    at!(y, n) += del;
                    at!(yprime, n) += *cj * del;
                    n += mband;
                }
                at!(iwm, 12) += 1;
                res(x, y, yprime, cj, e, ires, rpar, ipar);
                if *ires < 0 {
                    return;
                }
                let mut n = j;
                while n <= neq {
                    let k = (n - j) / mband + 1;
                    at!(y, n) = at!(wm, isave + k);
                    at!(yprime, n) = at!(wm, ipsave + k);
                    let d5 = at!(y, n).abs();
                    let d6 = (*h * at!(yprime, n)).abs();
                    let mut del = (squr * d5.max(d6)).max(1.0 / at!(ewt, n));
                    del = real_sign(del, *h * at!(yprime, n));
                    del = at!(y, n) + del - at!(y, n);
                    let delinv = 1.0 / del;
                    let i1 = 1.max(n - at!(iwm, 2));
                    let i2 = neq.min(n + at!(iwm, 1));
                    let ii = n * meb1 - at!(iwm, 1);
                    for i in i1..=i2 {
                        at!(wm, ii + i) = (at!(e, i) - at!(delta, i)) * delinv;
                    }
                    n += mband;
                }
            }
            band_factor!(meband);
        }
        _ => {}
    }
}

/// `DNSD` — the modified-Newton corrector loop for the direct solver. Iterates
/// `y -= J^{-1} G`, accumulating the net change in `e`, until the weighted-norm
/// convergence test passes or it fails (`*iernew != 0`).
pub(crate) unsafe fn dnsd(
    x: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    neq: i32,
    res: ResFn,
    wt: *mut f64,
    rpar: *mut f64,
    ipar: *mut i32,
    delta: *mut f64,
    e: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    cj: *mut f64,
    epcon: *mut f64,
    s: *mut f64,
    confac: f64,
    tolnew: f64,
    muldel: i32,
    maxit: i32,
    ires: *mut i32,
    iernew: *mut i32,
) {
    let mut m = 0i32;
    for i in 1..=neq {
        at!(e, i) = 0.0;
    }
    let mut oldnrm = 0.0f64;
    loop {
        at!(iwm, 19) += 1;
        if muldel == 1 {
            for i in 1..=neq {
                at!(delta, i) *= confac;
            }
        }
        dslvd(neq, delta, wm, iwm);
        for i in 1..=neq {
            at!(y, i) -= at!(delta, i);
            at!(e, i) -= at!(delta, i);
            at!(yprime, i) -= *cj * at!(delta, i);
        }
        let delnrm = ddwnrm(neq, delta, wt, rpar, ipar);
        if m == 0 {
            oldnrm = delnrm;
            if delnrm <= tolnew {
                return;
            }
        } else {
            let rate = real_pow(delnrm / oldnrm, 1.0 / (m as f64));
            if rate > 0.9 {
                *iernew = if *ires <= -2 { -1 } else { 1 };
                return;
            }
            *s = rate / (1.0 - rate);
        }
        if *s * delnrm <= *epcon {
            return;
        }
        m += 1;
        if m >= maxit {
            *iernew = if *ires <= -2 { -1 } else { 1 };
            return;
        }
        at!(iwm, 12) += 1;
        res(x, y, yprime, cj, delta, ires, rpar, ipar);
        if *ires < 0 {
            *iernew = if *ires <= -2 { -1 } else { 1 };
            return;
        }
    }
}

/// `DNEDD` — nonlinear-solver driver for the direct method: predicts `(y, y')`,
/// decides whether to refresh the Jacobian (via [`dmatd`]), runs the Newton
/// corrector [`dnsd`], and applies optional nonnegativity. Sets `*iernls`.
pub(crate) unsafe fn dnedd(
    x: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    neq: i32,
    res: ResFn,
    jacd: JacFn,
    h: *mut f64,
    wt: *mut f64,
    jstart: i32,
    idid: *mut i32,
    rpar: *mut f64,
    ipar: *mut i32,
    phi: *mut f64,
    gamma: *mut f64,
    delta: *mut f64,
    e: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    cj: *mut f64,
    cjold: *mut f64,
    cjlast: *mut f64,
    s: *mut f64,
    uround: *mut f64,
    epcon: *mut f64,
    jcalc: *mut i32,
    kp1: i32,
    nonneg: i32,
    ntype: i32,
    iernls: *mut i32,
) {
    const MULDEL: i32 = 1;
    const MAXIT: i32 = 4;
    const XRATE: f64 = 0.25;

    let mut ires = 0i32;
    let mut ierj = 0i32;
    let mut iertyp = 0i32;
    let mut success = false;

    if ntype != 0 {
        iertyp = 1;
    } else {
        if jstart == 0 {
            *cjold = *cj;
            *jcalc = -1;
        }
        *iernls = 0;
        let temp1 = (1.0 - XRATE) / (XRATE + 1.0);
        let temp2 = 1.0 / temp1;
        if *cj / *cjold < temp1 || *cj / *cjold > temp2 {
            *jcalc = -1;
        }
        if *cj != *cjlast {
            *s = 100.0;
        }

        'l300: loop {
            ierj = 0;
            ires = 0;
            let mut iernew = 0i32;

            // Predict the solution and derivative.
            for i in 1..=neq {
                at!(y, i) = at2!(phi, i, 1, neq);
                at!(yprime, i) = 0.0;
            }
            for j in 2..=kp1 {
                for i in 1..=neq {
                    at!(y, i) += at2!(phi, i, j, neq);
                    at!(yprime, i) += at!(gamma, j) * at2!(phi, i, j, neq);
                }
            }
            let pnorm = ddwnrm(neq, y, wt, rpar, ipar);
            let tolnew = *uround * 100.0 * pnorm;

            at!(iwm, 12) += 1;
            res(x, y, yprime, cj, delta, &mut ires, rpar, ipar);
            if ires < 0 {
                break 'l300;
            }

            // Reevaluate the iteration matrix if indicated.
            if *jcalc == -1 {
                at!(iwm, 13) += 1;
                *jcalc = 0;
                dmatd(
                    neq, x, y, yprime, delta, cj, h, &mut ierj, wt, e, wm, iwm, res, &mut ires,
                    uround, jacd, rpar, ipar,
                );
                *cjold = *cj;
                *s = 100.0;
                if ires < 0 {
                    break 'l300;
                }
                if ierj != 0 {
                    break 'l300;
                }
            }

            let confac = 2.0 / (*cj / *cjold + 1.0);
            dnsd(
                x, y, yprime, neq, res, wt, rpar, ipar, delta, e, wm, iwm, cj, epcon, s, confac,
                tolnew, MULDEL, MAXIT, &mut ires, &mut iernew,
            );

            if iernew > 0 && *jcalc != 0 {
                // Recoverable failure with an old matrix: retry with a new one.
                *jcalc = -1;
                continue 'l300;
            }
            if iernew != 0 {
                break 'l300;
            }

            // Converged. Apply nonnegativity if requested.
            if nonneg != 0 {
                for i in 1..=neq {
                    at!(delta, i) = at!(y, i).min(0.0);
                }
                let delnrm = ddwnrm(neq, delta, wt, rpar, ipar);
                if delnrm > *epcon {
                    break 'l300;
                }
                for i in 1..=neq {
                    at!(e, i) -= at!(delta, i);
                }
            }
            success = true;
            break 'l300;
        }
    }

    if !success {
        // L380: classify the failure.
        if ires <= -2 || iertyp != 0 {
            *iernls = -1;
            if ires <= -2 {
                *idid = -11;
            }
            if iertyp != 0 {
                *idid = -15;
            }
        } else {
            *iernls = 1;
            if ires < 0 {
                *idid = -10;
            }
            if ierj != 0 {
                *idid = -8;
            }
        }
    }
    // L390.
    *jcalc = 1;
}

// ===========================================================================
// Dummy callbacks (passed where a mode does not use a given user routine,
// mirroring the dummy externals the Fortran driver supplies).
// ===========================================================================

pub unsafe fn dummy_jacd(
    _t: *mut f64,
    _y: *mut f64,
    _yp: *mut f64,
    _pd: *mut f64,
    _delta: *mut f64,
    _cj: *mut f64,
    _h: *mut f64,
    _wt: *mut f64,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
}

pub unsafe fn dummy_jack(
    _res: ResFn,
    _ires: *mut i32,
    _neq: *mut i32,
    _t: *mut f64,
    _y: *mut f64,
    _yp: *mut f64,
    _rewt: *mut f64,
    _savr: *mut f64,
    _wk: *mut f64,
    _h: *mut f64,
    _cj: *mut f64,
    _wp: *mut f64,
    _iwp: *mut i32,
    _ier: *mut i32,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
}

pub unsafe fn dummy_psol(
    _neq: *mut i32,
    _t: *mut f64,
    _y: *mut f64,
    _yp: *mut f64,
    _savr: *mut f64,
    _wk: *mut f64,
    _cj: *mut f64,
    _wt: *mut f64,
    _wp: *mut f64,
    _iwp: *mut i32,
    _b: *mut f64,
    _eplin: *mut f64,
    _ier: *mut i32,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
}

pub unsafe fn dummy_rt(
    _neq: *mut i32,
    _t: *mut f64,
    _y: *mut f64,
    _yp: *mut f64,
    _nrt: *mut i32,
    _rval: *mut f64,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
}

/// Krylov nonlinear-solver driver (placeholder until the Krylov path is ported).
#[allow(unused_variables)]
pub(crate) unsafe fn dnedk(
    x: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    neq: i32,
    res: ResFn,
    jack: JacKFn,
    psol: PsolFn,
    h: *mut f64,
    wt: *mut f64,
    jstart: i32,
    idid: *mut i32,
    rpar: *mut f64,
    ipar: *mut i32,
    phi: *mut f64,
    gamma: *mut f64,
    savr: *mut f64,
    delta: *mut f64,
    e: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    cj: *mut f64,
    cjold: *mut f64,
    cjlast: *mut f64,
    s: *mut f64,
    uround: *mut f64,
    epli: *mut f64,
    sqrtn: *mut f64,
    rsqrtn: *mut f64,
    epcon: *mut f64,
    jcalc: *mut i32,
    jflg: *mut i32,
    kp1: i32,
    nonneg: i32,
    ntype: i32,
    iernls: *mut i32,
) {
    const MULDEL: i32 = 0;
    const MAXIT: i32 = 4;
    const XRATE: f64 = 0.25;

    let mut ires = 0i32;
    let mut ierpj = 0i32;
    let mut iersl = 0i32;
    let mut iertyp = 0i32;
    let mut success = false;

    if ntype != 1 {
        iertyp = 1;
    } else {
        if jstart == 0 {
            *cjold = *cj;
            *jcalc = -1;
            *s = 100.0;
        }
        *iernls = 0;
        let lwp = at!(iwm, 29);
        let liwp = at!(iwm, 30);
        if *jflg != 0 {
            let temp1 = (1.0 - XRATE) / (XRATE + 1.0);
            let temp2 = 1.0 / temp1;
            if *cj / *cjold < temp1 || *cj / *cjold > temp2 {
                *jcalc = -1;
            }
            if *cj != *cjlast {
                *s = 100.0;
            }
        } else {
            *jcalc = 0;
        }

        'l300: loop {
            ierpj = 0;
            ires = 0;
            iersl = 0;
            let mut iernew = 0i32;
            for i in 1..=neq {
                at!(y, i) = at2!(phi, i, 1, neq);
                at!(yprime, i) = 0.0;
            }
            for j in 2..=kp1 {
                for i in 1..=neq {
                    at!(y, i) += at2!(phi, i, j, neq);
                    at!(yprime, i) += at!(gamma, j) * at2!(phi, i, j, neq);
                }
            }
            let eplin = *epli * *epcon;
            let tolnew = eplin;
            at!(iwm, 12) += 1;
            res(x, y, yprime, cj, delta, &mut ires, rpar, ipar);
            if ires < 0 {
                break 'l300;
            }
            if *jcalc == -1 {
                at!(iwm, 13) += 1;
                *jcalc = 0;
                let mut neqv = neq;
                jack(
                    res, &mut ires, &mut neqv, x, y, yprime, wt, delta, e, h, cj,
                    wm.offset((lwp - 1) as isize), iwm.offset((liwp - 1) as isize), &mut ierpj,
                    rpar, ipar,
                );
                *cjold = *cj;
                *s = 100.0;
                if ires < 0 || ierpj != 0 {
                    break 'l300;
                }
            }
            let mut eplin_v = eplin;
            dnsk(
                x, y, yprime, neq, res, psol, wt, rpar, ipar, savr, delta, e, wm, iwm, cj, sqrtn,
                rsqrtn, &mut eplin_v, epcon, s, 0.0, tolnew, MULDEL, MAXIT, &mut ires, &mut iersl,
                &mut iernew,
            );
            if iernew > 0 && *jcalc != 0 {
                *jcalc = -1;
                continue 'l300;
            }
            if iernew != 0 {
                break 'l300;
            }
            if nonneg != 0 {
                for i in 1..=neq {
                    at!(delta, i) = at!(y, i).min(0.0);
                }
                let delnrm = ddwnrm(neq, delta, wt, rpar, ipar);
                if delnrm > *epcon {
                    break 'l300;
                }
                for i in 1..=neq {
                    at!(e, i) -= at!(delta, i);
                }
            }
            success = true;
            break 'l300;
        }
    }

    if !success {
        if ires <= -2 || iersl < 0 || iertyp != 0 {
            *iernls = -1;
            if ires <= -2 {
                *idid = -11;
            }
            if iersl < 0 {
                *idid = -13;
            }
            if iertyp != 0 {
                *idid = -15;
            }
        } else {
            *iernls = 1;
            if ires == -1 {
                *idid = -10;
            }
            if ierpj != 0 {
                *idid = -5;
            }
            if iersl > 0 {
                *idid = -14;
            }
        }
    }
    let _ = uround;
    *jcalc = 1;
}

// ===========================================================================
// BDF step controller
// ===========================================================================

/// `DDSTP` — take one step of the variable-order, variable-step, fixed-leading-
/// coefficient BDF method (normally `x -> x + h`), adjusting order and stepsize
/// to control the local error. Dispatches to the direct ([`dnedd`]) or Krylov
/// ([`dnedk`]) nonlinear solver per `ntype`.
pub(crate) unsafe fn ddstp(
    x: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    neq: i32,
    res: ResFn,
    jacd: JacFn,
    jack: JacKFn,
    psol: PsolFn,
    h: *mut f64,
    wt: *mut f64,
    vt: *mut f64,
    jstart: *mut i32,
    idid: *mut i32,
    rpar: *mut f64,
    ipar: *mut i32,
    phi: *mut f64,
    savr: *mut f64,
    delta: *mut f64,
    e: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    alpha: *mut f64,
    beta: *mut f64,
    gamma: *mut f64,
    psi: *mut f64,
    sigma: *mut f64,
    cj: *mut f64,
    cjold: *mut f64,
    hold: *mut f64,
    s: *mut f64,
    hmin: *mut f64,
    uround: *mut f64,
    epli: *mut f64,
    sqrtn: *mut f64,
    rsqrtn: *mut f64,
    epcon: *mut f64,
    iphase: *mut i32,
    jcalc: *mut i32,
    jflg: *mut i32,
    k: *mut i32,
    kold: *mut i32,
    ns: *mut i32,
    nonneg: i32,
    ntype: i32,
) {
    // BLOCK 1: initialize.
    let xold = *x;
    let mut ncf = 0i32;
    let mut nef = 0i32;
    if *jstart == 0 {
        *k = 1;
        *kold = 0;
        *hold = 0.0;
        at!(psi, 1) = *h;
        *cj = 1.0 / *h;
        *iphase = 0;
        *ns = 0;
    }

    macro_rules! l675 {
        () => {{
            // Restore Y, interpolate YPRIME at last X, return with error idid.
            ddatrp(*x, *x, y, yprime, neq, *k, phi, psi);
            *jstart = 1;
            if *idid >= 0 {
                *idid = -7;
            }
            return;
        }};
    }
    macro_rules! l690 {
        ($r:expr) => {{
            // Retry the step; on the first step reset PSI(1) and rescale PHI(*,2).
            if *kold == 0 {
                at!(psi, 1) = *h;
                for i in 1..=neq {
                    at2!(phi, i, 2, neq) = $r * at2!(phi, i, 2, neq);
                }
            }
            continue;
        }};
    }

    loop {
        // BLOCK 2: coefficients for this step.
        let kp1 = *k + 1;
        let kp2 = *k + 2;
        let km1 = *k - 1;
        if *h != *hold || *k != *kold {
            *ns = 0;
        }
        *ns = (*ns + 1).min(*kold + 2);
        let nsp1 = *ns + 1;
        if kp1 >= *ns {
            at!(beta, 1) = 1.0;
            at!(alpha, 1) = 1.0;
            let mut temp1 = *h;
            at!(gamma, 1) = 0.0;
            at!(sigma, 1) = 1.0;
            for i in 2..=kp1 {
                let temp2 = at!(psi, i - 1);
                at!(psi, i - 1) = temp1;
                at!(beta, i) = at!(beta, i - 1) * at!(psi, i - 1) / temp2;
                temp1 = temp2 + *h;
                at!(alpha, i) = *h / temp1;
                at!(sigma, i) = (i - 1) as f64 * at!(sigma, i - 1) * at!(alpha, i);
                at!(gamma, i) = at!(gamma, i - 1) + at!(alpha, i - 1) / *h;
            }
            at!(psi, kp1) = temp1;
        }

        // ALPHAS, ALPHA0
        let mut alphas = 0.0f64;
        let mut alpha0 = 0.0f64;
        for i in 1..=*k {
            alphas -= 1.0 / (i as f64);
            alpha0 -= at!(alpha, i);
        }
        let mut cjlast = *cj;
        *cj = -alphas / *h;
        let mut ck = (at!(alpha, kp1) + alphas - alpha0).abs();
        ck = ck.max(at!(alpha, kp1));

        // PHI -> PHI*
        if kp1 >= nsp1 {
            for j in nsp1..=kp1 {
                for i in 1..=neq {
                    at2!(phi, i, j, neq) = at!(beta, j) * at2!(phi, i, j, neq);
                }
            }
        }

        *x += *h;
        *idid = 1;

        // BLOCK 3: nonlinear solve.
        let mut iernls = 0i32;
        if ntype == 0 {
            dnedd(
                x, y, yprime, neq, res, jacd, h, wt, *jstart, idid, rpar, ipar, phi, gamma, delta,
                e, wm, iwm, cj, cjold, &mut cjlast, s, uround, epcon, jcalc, kp1, nonneg, ntype,
                &mut iernls,
            );
        } else {
            dnedk(
                x, y, yprime, neq, res, jack, psol, h, wt, *jstart, idid, rpar, ipar, phi, gamma,
                savr, delta, e, wm, iwm, cj, cjold, &mut cjlast, s, uround, epli, sqrtn, rsqrtn,
                epcon, jcalc, jflg, kp1, nonneg, ntype, &mut iernls,
            );
        }

        // Per-iteration order-selection state (set in block 4).
        let mut knew = *k;
        let mut est = 0.0f64;
        let mut erkm1 = 0.0f64;
        let mut terk = 0.0f64;
        let mut terkm1 = 0.0f64;

        let mut goto600 = iernls != 0;

        if !goto600 {
            // BLOCK 4: error estimates at orders k, k-1, k-2.
            let enorm = ddwnrm(neq, e, vt, rpar, ipar);
            let erk = at!(sigma, *k + 1) * enorm;
            terk = (*k + 1) as f64 * erk;
            est = erk;
            knew = *k;
            if *k != 1 {
                for i in 1..=neq {
                    at!(delta, i) = at2!(phi, i, kp1, neq) + at!(e, i);
                }
                erkm1 = at!(sigma, *k) * ddwnrm(neq, delta, vt, rpar, ipar);
                terkm1 = *k as f64 * erkm1;
                let mut lower = false;
                if *k > 2 {
                    for i in 1..=neq {
                        at!(delta, i) = at2!(phi, i, *k, neq) + at!(delta, i);
                    }
                    let erkm2 = at!(sigma, *k - 1) * ddwnrm(neq, delta, vt, rpar, ipar);
                    let terkm2 = (*k - 1) as f64 * erkm2;
                    if terkm1.max(terkm2) <= terk {
                        lower = true;
                    }
                } else if terkm1 <= terk * 0.5 {
                    lower = true;
                }
                if lower {
                    knew = *k - 1;
                    est = erkm1;
                }
            }

            // L430: local error test.
            let err = ck * enorm;
            if err > 1.0 {
                goto600 = true;
            } else {
                // BLOCK 5: step succeeded; choose next order and stepsize.
                *idid = 1;
                at!(iwm, 11) += 1;
                let kdiff = *k - *kold;
                *kold = *k;
                *hold = *h;

                if knew == km1 || *k == at!(iwm, 3) {
                    *iphase = 1;
                }

                let mut to_l575 = false;
                if *iphase == 0 {
                    // L545: increase order, double stepsize.
                    *k = kp1;
                    *h *= 2.0;
                    to_l575 = true;
                } else {
                    #[derive(PartialEq)]
                    enum Sel {
                        Raise,
                        Lower,
                        Keep,
                    }
                    let sel = if knew == km1 {
                        Sel::Lower
                    } else if *k == at!(iwm, 3) {
                        Sel::Keep
                    } else if kp1 >= *ns || kdiff == 1 {
                        Sel::Keep
                    } else {
                        for i in 1..=neq {
                            at!(delta, i) = at!(e, i) - at2!(phi, i, kp2, neq);
                        }
                        let erkp1 =
                            1.0 / ((*k + 2) as f64) * ddwnrm(neq, delta, vt, rpar, ipar);
                        let terkp1 = (*k + 2) as f64 * erkp1;
                        if *k > 1 {
                            if terkm1 <= terk.min(terkp1) {
                                Sel::Lower
                            } else if terkp1 >= terk || *k == at!(iwm, 3) {
                                Sel::Keep
                            } else {
                                est = erkp1;
                                Sel::Raise
                            }
                        } else if terkp1 >= terk * 0.5 {
                            Sel::Keep
                        } else {
                            est = erkp1;
                            Sel::Raise
                        }
                    };
                    match sel {
                        Sel::Raise => {
                            *k = kp1;
                            // est already set to erkp1 above
                        }
                        Sel::Lower => {
                            *k = km1;
                            est = erkm1;
                        }
                        Sel::Keep => {}
                    }
                }

                if !to_l575 {
                    // L550: determine the next stepsize.
                    let temp2 = (*k + 1) as f64;
                    let mut r = real_pow(est * 2.0 + 1e-4, -1.0 / temp2);
                    let hnew;
                    if r >= 2.0 {
                        hnew = *h * 2.0;
                    } else if r > 1.0 {
                        hnew = *h;
                    } else {
                        r = 0.5f64.max(0.9f64.min(r));
                        hnew = *h * r;
                    }
                    *h = hnew;
                }

                // L575: update divided differences for next step.
                if *kold != at!(iwm, 3) {
                    for i in 1..=neq {
                        at2!(phi, i, kp2, neq) = at!(e, i);
                    }
                }
                for i in 1..=neq {
                    at2!(phi, i, kp1, neq) += at!(e, i);
                }
                for j1 in 2..=kp1 {
                    let j = kp1 - j1 + 1;
                    for i in 1..=neq {
                        at2!(phi, i, j, neq) += at2!(phi, i, j + 1, neq);
                    }
                }
                *jstart = 1;
                return;
            }
        }

        // BLOCK 6: step failed. Restore X, PHI, PSI; pick a new stepsize or bail.
        debug_assert!(goto600);
        *iphase = 1;
        *x = xold;
        if kp1 >= nsp1 {
            for j in nsp1..=kp1 {
                let temp1 = 1.0 / at!(beta, j);
                for i in 1..=neq {
                    at2!(phi, i, j, neq) = temp1 * at2!(phi, i, j, neq);
                }
            }
        }
        for i in 2..=kp1 {
            at!(psi, i - 1) = at!(psi, i) - *h;
        }

        if iernls != 0 {
            // Nonlinear solver failed.
            at!(iwm, 15) += 1;
            if iernls < 0 {
                l675!();
            }
            ncf += 1;
            let r = 0.25;
            *h *= r;
            if ncf < 10 && (*h).abs() >= *hmin {
                l690!(r);
            }
            if *idid == 1 {
                *idid = -7;
            }
            if nef >= 3 {
                *idid = -9;
            }
            l675!();
        } else {
            // Error test failed.
            nef += 1;
            at!(iwm, 14) += 1;
            if nef <= 1 {
                *k = knew;
                let temp2 = (*k + 1) as f64;
                let mut r = real_pow(est * 2.0 + 1e-4, -1.0 / temp2) * 0.9;
                r = 0.25f64.max(0.9f64.min(r));
                *h *= r;
                if (*h).abs() >= *hmin {
                    l690!(r);
                }
                *idid = -6;
                l675!();
            } else if nef <= 2 {
                *k = knew;
                let r = 0.25;
                *h *= r;
                if (*h).abs() >= *hmin {
                    l690!(r);
                }
                *idid = -6;
                l675!();
            } else {
                *k = 1;
                let r = 0.25;
                *h *= r;
                if (*h).abs() >= *hmin {
                    l690!(r);
                }
                *idid = -6;
                l675!();
            }
        }
    }
}

// ===========================================================================
// Initial-condition solver (direct method)
// ===========================================================================

/// `DFNRMD` — scaled norm `||J^{-1} G(t, y, y')||` used by the IC linesearch:
/// evaluates the residual into `r`, applies `J^{-1}` ([`dslvd`]), then takes the
/// weighted norm into `*fnorm`.
pub(crate) unsafe fn dfnrmd(
    neq: i32,
    y: *mut f64,
    t: *mut f64,
    yprime: *mut f64,
    r: *mut f64,
    cj: *mut f64,
    tscale: *mut f64,
    wt: *mut f64,
    res: ResFn,
    ires: *mut i32,
    fnorm: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    rpar: *mut f64,
    ipar: *mut i32,
) {
    *ires = 0;
    res(t, y, yprime, cj, r, ires, rpar, ipar);
    if *ires < 0 {
        return;
    }
    dslvd(neq, r, wm, iwm);
    *fnorm = ddwnrm(neq, r, wt, rpar, ipar);
    if *tscale > 0.0 {
        *fnorm = *fnorm * *tscale * (*cj).abs();
    }
}

/// `DLINSD` — backtracking linesearch for the IC Newton step: find `rl in (0,1]`
/// so the merit function `f = ½||J^{-1}G||²` satisfies the alpha-condition,
/// honouring constraints. Updates `(y, yprime)` and `*fnrm`.
pub(crate) unsafe fn dlinsd(
    neq: i32,
    y: *mut f64,
    t: *mut f64,
    yprime: *mut f64,
    cj: *mut f64,
    tscale: *mut f64,
    p: *mut f64,
    pnrm: *mut f64,
    wt: *mut f64,
    lsoff: i32,
    stptol: *mut f64,
    iret: *mut i32,
    res: ResFn,
    ires: *mut i32,
    wm: *mut f64,
    iwm: *mut i32,
    fnrm: *mut f64,
    icopt: i32,
    id: *mut i32,
    r: *mut f64,
    ynew: *mut f64,
    ypnew: *mut f64,
    icnflg: i32,
    icnstr: *mut i32,
    rlx: *mut f64,
    rpar: *mut f64,
    ipar: *mut i32,
) {
    const ALPHA: f64 = 1e-4;
    let kprin = at!(iwm, 31);
    let f1nrm = *fnrm * *fnrm / 2.0;
    let mut ratio = 1.0f64;
    if kprin >= 2 {
        xerrwd("------ IN ROUTINE DLINSD-- PNRM = (R1)", 901, 0, 0, 0, 0, 1, *pnrm, 0.0);
    }
    let mut tau = *pnrm;
    let mut rl = 1.0f64;

    // Constraint check / rescale loop.
    if icnflg != 0 {
        loop {
            dyypnw(neq, y, yprime, *cj, rl, p, icopt, id, ynew, ypnew);
            let mut ivar = 0i32;
            dcnstr(neq, y, ynew, icnstr, &mut tau, *rlx, &mut *iret, &mut ivar);
            if *iret == 1 {
                let ratio1 = tau / *pnrm;
                ratio *= ratio1;
                for i in 1..=neq {
                    at!(p, i) *= ratio1;
                }
                *pnrm = tau;
                if kprin >= 2 {
                    xerrwd(
                        "------ CONSTRAINT VIOL., PNRM = (R1), INDEX = (I1)",
                        902, 0, 1, ivar, 0, 1, *pnrm, 0.0,
                    );
                }
                if *pnrm <= *stptol {
                    *iret = 1;
                    return;
                }
                continue;
            }
            break;
        }
    }

    let slpi = -2.0 * f1nrm * ratio;
    let rlmin = *stptol / *pnrm;
    if lsoff == 0 && kprin >= 2 {
        xerrwd("------ MIN. LAMBDA = (R1)", 903, 0, 0, 0, 0, 1, rlmin, 0.0);
    }

    // Backtracking loop on rl.
    loop {
        dyypnw(neq, y, yprime, *cj, rl, p, icopt, id, ynew, ypnew);
        let mut fnrmp = 0.0f64;
        dfnrmd(
            neq, ynew, t, ypnew, r, cj, tscale, wt, res, ires, &mut fnrmp, wm, iwm, rpar, ipar,
        );
        at!(iwm, 12) += 1;
        if *ires != 0 {
            *iret = 2;
            return;
        }

        let mut accept = lsoff == 1;
        if !accept {
            let f1nrmp = fnrmp * fnrmp / 2.0;
            if kprin >= 2 {
                xerrwd("------ LAMBDA = (R1)", 904, 0, 0, 0, 0, 1, rl, 0.0);
                xerrwd(
                    "------ NORM(F1) = (R1),  NORM(F1NEW) = (R2)",
                    905, 0, 0, 0, 0, 2, f1nrm, f1nrmp,
                );
            }
            if f1nrmp > f1nrm + ALPHA * slpi * rl {
                // Alpha-condition not satisfied: backtrack.
                if rl < rlmin {
                    *iret = 1;
                    return;
                }
                rl /= 2.0;
                continue;
            }
            accept = true;
        }

        if accept {
            *iret = 0;
            for i in 1..=neq {
                at!(y, i) = at!(ynew, i);
            }
            for i in 1..=neq {
                at!(yprime, i) = at!(ypnew, i);
            }
            *fnrm = fnrmp;
            if kprin >= 1 {
                xerrwd(
                    "------ LEAVING ROUTINE DLINSD, FNRM = (R1)",
                    906, 0, 0, 0, 0, 1, *fnrm, 0.0,
                );
            }
            return;
        }
    }
}

/// `DNSID` — modified-Newton corrector for consistent initial conditions, using
/// the linesearch [`dlinsd`] for global convergence. Sets `*iernew`.
pub(crate) unsafe fn dnsid(
    x: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    neq: i32,
    icopt: i32,
    id: *mut i32,
    res: ResFn,
    wt: *mut f64,
    rpar: *mut f64,
    ipar: *mut i32,
    delta: *mut f64,
    r: *mut f64,
    yic: *mut f64,
    ypic: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    cj: *mut f64,
    tscale: *mut f64,
    epcon: *mut f64,
    ratemx: *mut f64,
    maxit: i32,
    stptol: *mut f64,
    icnflg: i32,
    icnstr: *mut i32,
    iernew: *mut i32,
) {
    let lsoff = at!(iwm, 35);
    let mut m = 0i32;
    let mut rate = 1.0f64;
    let mut rlx = 0.4f64;

    dslvd(neq, delta, wm, iwm);
    let mut delnrm = ddwnrm(neq, delta, wt, rpar, ipar);
    let mut fnrm = delnrm;
    if *tscale > 0.0 {
        fnrm = fnrm * *tscale * (*cj).abs();
    }
    if fnrm <= *epcon {
        return;
    }

    let mut ires = 0i32;
    let mut iret = 0i32;
    loop {
        at!(iwm, 19) += 1;
        let oldfnm = fnrm;
        dlinsd(
            neq, y, x, yprime, cj, tscale, delta, &mut delnrm, wt, lsoff, stptol, &mut iret, res,
            &mut ires, wm, iwm, &mut fnrm, icopt, id, r, yic, ypic, icnflg, icnstr, &mut rlx, rpar,
            ipar,
        );
        rate = fnrm / oldfnm;
        if iret != 0 {
            *iernew = if ires <= -2 { -1 } else { 3 };
            return;
        }
        if fnrm <= *epcon {
            return;
        }
        m += 1;
        if m >= maxit {
            *iernew = if rate <= *ratemx { 1 } else { 2 };
            return;
        }
        for i in 1..=neq {
            at!(delta, i) = at!(r, i);
        }
        delnrm = fnrm;
    }
}

/// `DDASID` — IC nonlinear-solver driver (direct method): refreshes the
/// iteration matrix ([`dmatd`]) and runs the Newton corrector [`dnsid`], up to
/// `MXNJ` Jacobian updates. Sets `*iernls`.
pub(crate) unsafe fn ddasid(
    x: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    neq: i32,
    icopt: i32,
    id: *mut i32,
    res: ResFn,
    jacd: JacFn,
    h: *mut f64,
    tscale: *mut f64,
    wt: *mut f64,
    rpar: *mut f64,
    ipar: *mut i32,
    delta: *mut f64,
    r: *mut f64,
    yic: *mut f64,
    ypic: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    cj: *mut f64,
    uround: *mut f64,
    epcon: *mut f64,
    ratemx: *mut f64,
    stptol: *mut f64,
    icnflg: i32,
    icnstr: *mut i32,
    iernls: *mut i32,
) {
    let mxnit = at!(iwm, 32);
    let mxnj = at!(iwm, 33);
    *iernls = 0;
    let mut nj = 0i32;

    macro_rules! l370 {
        ($ires:expr) => {{
            *iernls = 2;
            if $ires <= -2 {
                *iernls = -1;
            }
            return;
        }};
    }

    let mut ires = 0i32;
    at!(iwm, 12) += 1;
    res(x, y, yprime, cj, delta, &mut ires, rpar, ipar);
    if ires < 0 {
        l370!(ires);
    }

    loop {
        let mut ierj = 0i32;
        ires = 0;
        let mut iernew = 0i32;
        nj += 1;
        at!(iwm, 13) += 1;
        dmatd(
            neq, x, y, yprime, delta, cj, h, &mut ierj, wt, r, wm, iwm, res, &mut ires, uround,
            jacd, rpar, ipar,
        );
        if ires < 0 || ierj != 0 {
            l370!(ires);
        }
        dnsid(
            x, y, yprime, neq, icopt, id, res, wt, rpar, ipar, delta, r, yic, ypic, wm, iwm, cj,
            tscale, epcon, ratemx, mxnit, stptol, icnflg, icnstr, &mut iernew,
        );
        if iernew == 1 && nj < mxnj {
            at!(iwm, 12) += 1;
            res(x, y, yprime, cj, delta, &mut ires, rpar, ipar);
            if ires < 0 {
                l370!(ires);
            }
            continue;
        }
        if iernew != 0 {
            *iernls = iernew.min(2);
            return;
        }
        return;
    }
}

/// Krylov IC nonlinear solver (placeholder until the Krylov path is ported).
#[allow(unused_variables)]
pub(crate) unsafe fn ddasik(
    x: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    neq: i32,
    icopt: i32,
    id: *mut i32,
    res: ResFn,
    jack: JacKFn,
    psol: PsolFn,
    h: *mut f64,
    tscale: *mut f64,
    wt: *mut f64,
    jskip: i32,
    rpar: *mut f64,
    ipar: *mut i32,
    savr: *mut f64,
    delta: *mut f64,
    r: *mut f64,
    yic: *mut f64,
    ypic: *mut f64,
    pwk: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    cj: *mut f64,
    uround: *mut f64,
    epli: *mut f64,
    sqrtn: *mut f64,
    rsqrtn: *mut f64,
    epcon: *mut f64,
    ratemx: *mut f64,
    stptol: *mut f64,
    jflg: *mut i32,
    icnflg: i32,
    icnstr: *mut i32,
    iernls: *mut i32,
) {
    let lwp = at!(iwm, 29);
    let liwp = at!(iwm, 30);
    let mxnit = at!(iwm, 32);
    let mxnj = at!(iwm, 33);
    *iernls = 0;
    let mut nj = 0i32;
    let eplin = *epli * *epcon;

    macro_rules! l370 {
        ($ires:expr) => {{
            *iernls = 2;
            if $ires <= -2 {
                *iernls = -1;
            }
            return;
        }};
    }

    let mut ires = 0i32;
    at!(iwm, 12) += 1;
    res(x, y, yprime, cj, delta, &mut ires, rpar, ipar);
    if ires < 0 {
        l370!(ires);
    }

    let mut jskip_v = jskip;
    loop {
        let mut ierpj = 0i32;
        ires = 0;
        let mut iernew = 0i32;
        if *jflg == 1 && jskip_v == 0 {
            nj += 1;
            at!(iwm, 13) += 1;
            let mut neqv = neq;
            jack(
                res, &mut ires, &mut neqv, x, y, yprime, wt, delta, r, h, cj,
                wm.offset((lwp - 1) as isize), iwm.offset((liwp - 1) as isize), &mut ierpj, rpar,
                ipar,
            );
            if ires < 0 || ierpj != 0 {
                l370!(ires);
            }
        }
        jskip_v = 0;
        let mut eplin_v = eplin;
        dnsik(
            x, y, yprime, neq, icopt, id, res, psol, wt, rpar, ipar, savr, delta, r, yic, ypic,
            pwk, wm, iwm, cj, tscale, sqrtn, rsqrtn, &mut eplin_v, epcon, ratemx, mxnit, stptol,
            icnflg, icnstr, &mut iernew,
        );
        if iernew == 1 && nj < mxnj && *jflg == 1 {
            for i in 1..=neq {
                at!(delta, i) = at!(savr, i);
            }
            continue;
        }
        if iernew != 0 {
            *iernls = iernew.min(2);
            return;
        }
        let _ = uround;
        return;
    }
}

/// `DDASIC` — driver to compute consistent initial values for `y` and `yprime`
/// (option 1: given `y_d`, find `y_a`, `y_d'`; option 2: given `y'`, find `y`),
/// retrying with reduced `h` on recoverable failure. Calls the direct
/// ([`ddasid`]) or Krylov ([`ddasik`]) IC nonlinear solver per `ntype`.
pub(crate) unsafe fn ddasic(
    x: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    neq: i32,
    icopt: i32,
    id: *mut i32,
    res: ResFn,
    jacd: JacFn,
    jack: JacKFn,
    psol: PsolFn,
    h: *mut f64,
    tscale: *mut f64,
    wt: *mut f64,
    nic: i32,
    idid: *mut i32,
    rpar: *mut f64,
    ipar: *mut i32,
    phi: *mut f64,
    savr: *mut f64,
    delta: *mut f64,
    e: *mut f64,
    yic: *mut f64,
    ypic: *mut f64,
    pwk: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    uround: *mut f64,
    epli: *mut f64,
    sqrtn: *mut f64,
    rsqrtn: *mut f64,
    epconi: *mut f64,
    stptol: *mut f64,
    jflg: *mut i32,
    icnflg: i32,
    icnstr: *mut i32,
    ntype: i32,
) {
    const RHCUT: f64 = 0.1;
    let mxnh = at!(iwm, 34);
    *idid = 1;
    let mut nh = 1i32;
    let mut jskip = 0i32;
    if nic == 2 {
        jskip = 1;
    }
    for i in 1..=neq {
        at2!(phi, i, 1, neq) = at!(y, i);
    }
    for i in 1..=neq {
        at2!(phi, i, 2, neq) = at!(yprime, i);
    }
    let mut cj = if icopt == 2 { 0.0 } else { 1.0 / *h };
    let mut ratemx = 0.8f64;

    loop {
        let mut iernls = 0i32;
        if ntype == 0 {
            ddasid(
                x, y, yprime, neq, icopt, id, res, jacd, h, tscale, wt, rpar, ipar, delta, e, yic,
                ypic, wm, iwm, &mut cj, uround, epconi, &mut ratemx, stptol, icnflg, icnstr,
                &mut iernls,
            );
        } else {
            ddasik(
                x, y, yprime, neq, icopt, id, res, jack, psol, h, tscale, wt, jskip, rpar, ipar,
                savr, delta, e, yic, ypic, pwk, wm, iwm, &mut cj, uround, epli, sqrtn, rsqrtn,
                epconi, &mut ratemx, stptol, jflg, icnflg, icnstr, &mut iernls,
            );
        }

        if iernls == 0 {
            return;
        }

        // Nonlinear solver failed.
        at!(iwm, 15) += 1;
        jskip = 0;
        if iernls == -1 || icopt == 2 || nh == mxnh {
            *idid = -12;
            return;
        }
        nh += 1;
        *h *= RHCUT;
        cj = 1.0 / *h;
        if iernls == 1 {
            continue;
        }
        // iernls > 1: restore Y and YPRIME to their original values.
        for i in 1..=neq {
            at!(y, i) = at2!(phi, i, 1, neq);
        }
        for i in 1..=neq {
            at!(yprime, i) = at2!(phi, i, 2, neq);
        }
    }
}

// ===========================================================================
// Root finding (Illinois algorithm)
// ===========================================================================

/// Illinois-algorithm state that DROOTS keeps in Fortran `SAVE` locals across
/// its re-entrant (`jflag == 1`) calls. Owned by [`drchek`] per search.
#[derive(Default)]
pub(crate) struct DRoots {
    imax: i32,
    x2: f64,
    last: i32,
    nxlast: i32,
    alpha: f64,
    xroot: bool,
}

/// `DROOTS` — find the leftmost root (sign change of odd multiplicity) of the
/// vector function `R(x)` in `(x0, x1)` via the Illinois method. Re-entrant:
/// returns `*jflag == 1` to request `R(x)` in `rx`, or `>= 2` when done.
pub(crate) unsafe fn droots(
    nrt: i32,
    hmin: f64,
    jflag: *mut i32,
    x0: *mut f64,
    x1: *mut f64,
    r0: *mut f64,
    r1: *mut f64,
    rx: *mut f64,
    x: *mut f64,
    jroot: *mut i32,
    st: &mut DRoots,
) {
    const HALF: f64 = 0.5;
    const TENTH: f64 = 0.1;
    const FIVE: f64 = 5.0;

    if *jflag != 1 {
        // First call: look for sign change or zero at X1.
        st.imax = 0;
        let mut tmax = 0.0f64;
        let mut zroot = false;
        for i in 1..=nrt {
            if at!(r1, i).abs() > 0.0 {
                if real_sign(1.0, at!(r0, i)) != real_sign(1.0, at!(r1, i)) {
                    let t2 = (at!(r1, i) / (at!(r1, i) - at!(r0, i))).abs();
                    if t2 > tmax {
                        tmax = t2;
                        st.imax = i;
                    }
                }
            } else {
                zroot = true;
            }
        }
        if st.imax <= 0 {
            // L400: no sign change.
            if zroot {
                // Zero at X1, no sign change: jflag = 3.
                *x = *x1;
                for i in 1..=nrt {
                    at!(rx, i) = at!(r1, i);
                }
                for i in 1..=nrt {
                    at!(jroot, i) = 0;
                    if at!(r1, i).abs() == 0.0 {
                        at!(jroot, i) = (-real_sign(1.0, at!(r0, i))) as i32;
                    }
                }
                *jflag = 3;
                return;
            }
            // L420: no roots.
            for i in 1..=nrt {
                at!(rx, i) = at!(r1, i);
            }
            *x = *x1;
            *jflag = 4;
            return;
        }
        // Sign change: start the iteration.
        st.xroot = false;
        st.nxlast = 0;
        st.last = 1;
    } else {
        // Re-entry (jflag == 1): determine which subinterval has the sign change.
        let imxold = st.imax;
        st.imax = 0;
        let mut tmax = 0.0f64;
        let mut zroot = false;
        for i in 1..=nrt {
            if at!(rx, i).abs() > 0.0 {
                if real_sign(1.0, at!(r0, i)) != real_sign(1.0, at!(rx, i)) {
                    let t2 = (at!(rx, i) / (at!(rx, i) - at!(r0, i))).abs();
                    if t2 > tmax {
                        tmax = t2;
                        st.imax = i;
                    }
                }
            } else {
                zroot = true;
            }
        }
        let sgnchg = st.imax > 0;
        if !sgnchg {
            st.imax = imxold;
        }
        st.nxlast = st.last;
        if sgnchg {
            // Sign change in (X0,X2): replace X1 with X2.
            *x1 = st.x2;
            for i in 1..=nrt {
                at!(r1, i) = at!(rx, i);
            }
            st.last = 1;
            st.xroot = false;
        } else if zroot {
            // Zero at X2, no sign change in (X0,X2): X2 is a root.
            *x1 = st.x2;
            for i in 1..=nrt {
                at!(r1, i) = at!(rx, i);
            }
            st.xroot = true;
        } else {
            // No sign change in (X0,X2): replace X0 with X2.
            for i in 1..=nrt {
                at!(r0, i) = at!(rx, i);
            }
            *x0 = st.x2;
            st.last = 0;
            st.xroot = false;
        }
        if (*x1 - *x0).abs() <= hmin {
            st.xroot = true;
        }
    }

    // L150 body (reached once per call).
    if st.xroot {
        // L300: return X1 as the root.
        *jflag = 2;
        *x = *x1;
        for i in 1..=nrt {
            at!(rx, i) = at!(r1, i);
        }
        for i in 1..=nrt {
            at!(jroot, i) = 0;
            if at!(r1, i).abs() == 0.0 {
                at!(jroot, i) = (-real_sign(1.0, at!(r0, i))) as i32;
            } else if real_sign(1.0, at!(r0, i)) != real_sign(1.0, at!(r1, i)) {
                at!(jroot, i) = real_sign(1.0, at!(r1, i) - at!(r0, i)) as i32;
            }
        }
        return;
    }

    // Compute the next test point X2 (Illinois secant step).
    if st.nxlast != st.last {
        st.alpha = 1.0;
    } else if st.last == 0 {
        st.alpha *= 2.0;
    } else {
        st.alpha *= 0.5;
    }
    let mut x2 = *x1 - (*x1 - *x0) * at!(r1, st.imax) / (at!(r1, st.imax) - st.alpha * at!(r0, st.imax));
    if (x2 - *x0).abs() < HALF * hmin {
        let fracint = (*x1 - *x0).abs() / hmin;
        let fracsub = if fracint > FIVE { TENTH } else { HALF / fracint };
        x2 = *x0 + fracsub * (*x1 - *x0);
    }
    if (*x1 - x2).abs() < HALF * hmin {
        let fracint = (*x1 - *x0).abs() / hmin;
        let fracsub = if fracint > FIVE { TENTH } else { HALF / fracint };
        x2 = *x1 - fracsub * (*x1 - *x0);
    }
    st.x2 = x2;
    *jflag = 1;
    *x = x2;
}

/// `DRCHEK` — check for a root of `R(t, y, y')` near the current `t`, per `job`
/// (1 = initialization, 2 = continuation, 3 = after a step), driving [`droots`]
/// and the user `rt` callback. Uses global `rwork[51]`=T0, `rwork[52]`=TLAST,
/// `iwork[36]`=#R-evals, `iwork[37]`=IRFND. Sets `*irt`.
pub(crate) unsafe fn drchek(
    job: i32,
    rt: RtFn,
    nrt: *mut i32,
    neq: *mut i32,
    tn: *mut f64,
    tout: *mut f64,
    y: *mut f64,
    yp: *mut f64,
    phi: *mut f64,
    psi: *mut f64,
    kold: *mut i32,
    r0: *mut f64,
    r1: *mut f64,
    rx: *mut f64,
    jroot: *mut i32,
    irt: *mut i32,
    uround: *mut f64,
    _info3: i32,
    rwork: *mut f64,
    iwork: *mut i32,
    rpar: *mut f64,
    ipar: *mut i32,
) {
    let h = at!(psi, 1);
    *irt = 0;
    for i in 1..=*nrt {
        at!(jroot, i) = 0;
    }
    let hminr = ((*tn).abs() + h.abs()) * *uround * 100.0;
    let lt0 = rwork.offset(50); // &rwork[51]

    let mut to260 = false;
    let mut to300 = false;

    if job == 1 {
        // Evaluate R at initial T; check for zeros.
        ddatrp(*tn, at!(rwork, 51), y, yp, *neq, *kold, phi, psi);
        rt(neq, lt0, y, yp, nrt, r0, rpar, ipar);
        at!(iwork, 36) = 1;
        let mut zroot = false;
        for i in 1..=*nrt {
            if at!(r0, i).abs() == 0.0 {
                zroot = true;
            }
        }
        if !zroot {
            return;
        }
        // R has a zero at T; look slightly past T.
        let temp2 = (hminr / h.abs()).max(0.1);
        let temp1 = temp2 * h;
        at!(rwork, 51) += temp1;
        for i in 1..=*neq {
            at!(y, i) += temp2 * at2!(phi, i, 2, *neq);
        }
        rt(neq, lt0, y, yp, nrt, r0, rpar, ipar);
        at!(iwork, 36) += 1;
        zroot = false;
        for i in 1..=*nrt {
            if at!(r0, i).abs() == 0.0 {
                zroot = true;
            }
        }
        if !zroot {
            return;
        }
        *irt = -1;
        return;
    } else if job == 2 {
        if at!(iwork, 37) == 0 {
            to260 = true;
        } else {
            // A root was found last step: evaluate R0 = R(T0).
            ddatrp(*tn, at!(rwork, 51), y, yp, *neq, *kold, phi, psi);
            rt(neq, lt0, y, yp, nrt, r0, rpar, ipar);
            at!(iwork, 36) += 1;
            let mut zroot = false;
            for i in 1..=*nrt {
                if at!(r0, i).abs() == 0.0 {
                    zroot = true;
                    at!(jroot, i) = 1;
                }
            }
            if !zroot {
                to260 = true;
            } else {
                // R has a zero at T0; look at T0 + small increment.
                let temp1 = real_sign(hminr, h);
                at!(rwork, 51) += temp1;
                if (at!(rwork, 51) - *tn) * h < 0.0 {
                    ddatrp(*tn, at!(rwork, 51), y, yp, *neq, *kold, phi, psi);
                } else {
                    let temp2 = temp1 / h;
                    for i in 1..=*neq {
                        at!(y, i) += temp2 * at2!(phi, i, 2, *neq);
                    }
                }
                rt(neq, lt0, y, yp, nrt, r0, rpar, ipar);
                at!(iwork, 36) += 1;
                for i in 1..=*nrt {
                    if at!(r0, i).abs() > 0.0 {
                        continue;
                    }
                    if at!(jroot, i) == 1 {
                        *irt = -2;
                        return;
                    } else {
                        at!(jroot, i) = (-real_sign(1.0, at!(r0, i))) as i32;
                        *irt = 1;
                    }
                }
                if *irt == 1 {
                    return;
                }
                to260 = true;
            }
        }
    } else {
        to300 = true;
    }

    if to260 {
        // L260
        if *tn == at!(rwork, 52) {
            return;
        }
        to300 = true;
    }

    if to300 {
        // L300: set T1 to TN or TOUT, whichever comes first, get R at T1.
        let mut t1;
        if (*tout - *tn) * h >= 0.0 {
            t1 = *tn;
        } else {
            t1 = *tout;
            if (t1 - at!(rwork, 51)) * h <= 0.0 {
                return;
            }
        }
        ddatrp(*tn, t1, y, yp, *neq, *kold, phi, psi);
        rt(neq, &mut t1, y, yp, nrt, r1, rpar, ipar);
        at!(iwork, 36) += 1;

        // Search for a root in (T0, T1) via DROOTS.
        let mut jflag = 0i32;
        let mut st = DRoots::default();
        let mut xx = 0.0f64;
        loop {
            droots(*nrt, hminr, &mut jflag, lt0, &mut t1, r0, r1, rx, &mut xx, jroot, &mut st);
            if jflag > 1 {
                break;
            }
            ddatrp(*tn, xx, y, yp, *neq, *kold, phi, psi);
            rt(neq, &mut xx, y, yp, nrt, rx, rpar, ipar);
            at!(iwork, 36) += 1;
        }
        at!(rwork, 51) = xx;
        for i in 1..=*nrt {
            at!(r0, i) = at!(rx, i);
        }
        if jflag == 4 {
            return;
        }
        // Found a root: interpolate to X and return.
        ddatrp(*tn, xx, y, yp, *neq, *kold, phi, psi);
        *irt = 1;
    }
}

// ===========================================================================
// Main driver
// ===========================================================================

/// `DDASKR` — the main driver. Integrates the DAE `G(t, y, y') = 0` from `t` to
/// `tout`, with optional root-finding. State lives in the user-supplied
/// `rwork`/`iwork`; `info` selects options; `*idid` reports the outcome. This is
/// a faithful translation of the Fortran driver: geometry that the C kept in
/// `SAVE` locals is recomputed each call from `info`/`iwork` so the port is
/// stateless. `jacd` is used for the direct method, `jack`/`psol` for Krylov;
/// pass [`dummy_jacd`] / [`dummy_jack`] / [`dummy_psol`] / [`dummy_rt`] for
/// unused slots.
pub unsafe fn ddaskr(
    res: ResFn,
    neq: i32,
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    tout: *mut f64,
    info: *mut i32,
    rtol: *mut f64,
    atol: *mut f64,
    idid: *mut i32,
    rwork: *mut f64,
    lrw: i32,
    iwork: *mut i32,
    liw: i32,
    rpar: *mut f64,
    ipar: *mut i32,
    jacd: JacFn,
    jack: JacKFn,
    psol: PsolFn,
    rt: RtFn,
    nrt: i32,
    jroot: *mut i32,
) {
    // Pointer helpers: rw(n) = &rwork[n], iw(n) = &iwork[n], inf(n) = &info[n].
    let rw = |n: i32| rwork.offset((n - 1) as isize);
    let iw = |n: i32| iwork.offset((n - 1) as isize);
    let inf = |n: i32| info.offset((n - 1) as isize);
    let mut neq_l = neq;
    let mut nrt_l = nrt;

    // Geometry the C keeps in SAVE locals (recomputed; depends only on
    // info[]/iwork[3], which the user holds across calls).
    let mxord = if at!(info, 9) != 0 { at!(iwork, 3) } else { 5 };
    let mut icnflg = 0i32;
    let mut nonneg = 0i32;
    let mut lid = 41i32;
    match at!(info, 10) {
        1 => {
            icnflg = 1;
            lid = neq + 41;
        }
        2 => {
            nonneg = 1;
        }
        3 => {
            icnflg = 1;
            nonneg = 1;
            lid = neq + 41;
        }
        _ => {}
    }
    let lenid = if at!(info, 11) == 1 || at!(info, 16) == 1 { neq } else { 0 };
    let ncphi = if at!(info, 12) == 0 { (mxord + 1).max(4) } else { mxord + 1 };

    // Working scalars (correspond to the f2c locals).
    let mut tn = 0.0f64;
    let mut h = 0.0f64;
    let mut h0 = 0.0f64;
    let mut uround;
    let mut hmin;
    let mut tstop = 0.0f64;
    let mut r_acc = 0.0f64;

    macro_rules! l590 {
        () => {{
            at!(rwork, 4) = tn;
            at!(rwork, 52) = *t;
            at!(rwork, 3) = h;
            return;
        }};
    }
    macro_rules! l700 {
        () => {{
            at!(info, 1) = -1;
            *t = tn;
            at!(rwork, 4) = tn;
            at!(rwork, 3) = h;
            return;
        }};
    }
    macro_rules! l750 {
        () => {{
            if at!(info, 1) == -1 {
                xerrwd("DASKR--  REPEATED OCCURRENCES OF ILLEGAL INPUT", 701, 0, 0, 0, 0, 0, 0.0, 0.0);
                xerrwd("DASKR--  RUN TERMINATED. APPARENT INFINITE LOOP", 702, 2, 0, 0, 0, 0, 0.0, 0.0);
                return;
            }
            at!(info, 1) = -1;
            *idid = -33;
            return;
        }};
    }
    macro_rules! l600 {
        () => {{
            match -*idid {
                1 => {
                    xerrwd("DASKR--  AT CURRENT T (=R1)  500 STEPS", 610, 0, 0, 0, 0, 1, tn, 0.0);
                    xerrwd("DASKR--  TAKEN ON THIS CALL BEFORE REACHING TOUT", 611, 0, 0, 0, 0, 0, 0.0, 0.0);
                }
                2 => {
                    xerrwd("DASKR--  AT T (=R1) TOO MUCH ACCURACY REQUESTED", 620, 0, 0, 0, 0, 1, tn, 0.0);
                    xerrwd("DASKR--  FOR PRECISION OF MACHINE. RTOL AND ATOL", 621, 0, 0, 0, 0, 0, 0.0, 0.0);
                    xerrwd("DASKR--  WERE INCREASED BY A FACTOR R (=R1)", 622, 0, 0, 0, 0, 1, r_acc, 0.0);
                }
                3 => {
                    xerrwd("DASKR--  AT T (=R1) SOME ELEMENT OF WT", 630, 0, 0, 0, 0, 1, tn, 0.0);
                    xerrwd("DASKR--  HAS BECOME .LE. 0.0", 631, 0, 0, 0, 0, 0, 0.0, 0.0);
                }
                4 => {}
                5 => {
                    xerrwd("DASKR--  AT T (=R1) AND STEPSIZE H (=R2) THE", 655, 0, 0, 0, 0, 2, tn, h);
                    xerrwd("DASKR--  PRECONDITIONER HAD REPEATED FAILURES.", 656, 0, 0, 0, 0, 0, 0.0, 0.0);
                }
                6 => {
                    xerrwd("DASKR--  AT T (=R1) AND STEPSIZE H (=R2) THE", 640, 0, 0, 0, 0, 2, tn, h);
                    xerrwd("DASKR--  ERROR TEST FAILED REPEATEDLY OR WITH ABS(H)=HMIN", 641, 0, 0, 0, 0, 0, 0.0, 0.0);
                }
                7 => {
                    xerrwd("DASKR--  AT T (=R1) AND STEPSIZE H (=R2) THE", 650, 0, 0, 0, 0, 2, tn, h);
                    xerrwd("DASKR--  NONLINEAR SOLVER FAILED TO CONVERGE", 651, 0, 0, 0, 0, 0, 0.0, 0.0);
                    xerrwd("DASKR--  REPEATEDLY OR WITH ABS(H)=HMIN", 652, 0, 0, 0, 0, 0, 0.0, 0.0);
                }
                8 => {
                    xerrwd("DASKR--  AT T (=R1) AND STEPSIZE H (=R2) THE", 660, 0, 0, 0, 0, 2, tn, h);
                    xerrwd("DASKR--  ITERATION MATRIX IS SINGULAR.", 661, 0, 0, 0, 0, 0, 0.0, 0.0);
                }
                9 => {
                    xerrwd("DASKR--  AT T (=R1) AND STEPSIZE H (=R2) THE", 670, 0, 0, 0, 0, 2, tn, h);
                    xerrwd("DASKR--  NONLINEAR SOLVER COULD NOT CONVERGE.", 671, 0, 0, 0, 0, 0, 0.0, 0.0);
                    xerrwd("DASKR--  ALSO, THE ERROR TEST FAILED REPEATEDLY.", 672, 0, 0, 0, 0, 0, 0.0, 0.0);
                }
                10 => {
                    xerrwd("DASKR--  AT T (=R1) AND STEPSIZE H (=R2) THE", 675, 0, 0, 0, 0, 2, tn, h);
                    xerrwd("DASKR--  NONLINEAR SYSTEM SOLVER COULD NOT CONVERGE", 676, 0, 0, 0, 0, 0, 0.0, 0.0);
                    xerrwd("DASKR--  BECAUSE IRES WAS EQUAL TO MINUS ONE", 677, 0, 0, 0, 0, 0, 0.0, 0.0);
                }
                11 => {
                    xerrwd("DASKR--  AT T (=R1) AND STEPSIZE H (=R2)", 680, 0, 0, 0, 0, 2, tn, h);
                    xerrwd("DASKR--  IRES WAS EQUAL TO MINUS TWO", 681, 0, 0, 0, 0, 0, 0.0, 0.0);
                }
                12 => {
                    xerrwd("DASKR--  AT T (=R1) AND STEPSIZE H (=R2) THE", 685, 0, 0, 0, 0, 0, 0.0, 0.0);
                    xerrwd("DASKR--  INITIAL (Y,YPRIME) COULD NOT BE COMPUTED", 686, 0, 0, 0, 0, 2, tn, h0);
                }
                13 => {
                    xerrwd("DASKR--  AT T (=R1) AND STEPSIZE H (=R2)", 690, 0, 0, 0, 0, 2, tn, h);
                    xerrwd("DASKR--  IER WAS NEGATIVE FROM PSOL", 691, 0, 0, 0, 0, 0, 0.0, 0.0);
                }
                14 => {
                    xerrwd("DASKR--  AT T (=R1) AND STEPSIZE H (=R2) THE", 695, 0, 0, 0, 0, 2, tn, h);
                    xerrwd("DASKR--  LINEAR SYSTEM SOLVER COULD NOT CONVERGE.", 696, 0, 0, 0, 0, 0, 0.0, 0.0);
                }
                _ => {}
            }
            l700!();
        }};
    }

    // -------------------------------------------------------------------
    // Initial-call validation, or continuation-call checks.
    // -------------------------------------------------------------------
    let mut itemp;
    if at!(info, 1) == 0 {
        for i in 2..=9 {
            itemp = i;
            if at!(info, i) != 0 && at!(info, i) != 1 {
                xerrwd("DASKR--  ELEMENT (=I1) OF INFO VECTOR IS NOT VALID", 1, 0, 1, itemp, 0, 0, 0.0, 0.0);
                l750!();
            }
        }
        itemp = 10;
        if at!(info, 10) < 0 || at!(info, 10) > 3 {
            xerrwd("DASKR--  ELEMENT (=I1) OF INFO VECTOR IS NOT VALID", 1, 0, 1, itemp, 0, 0, 0.0, 0.0);
            l750!();
        }
        itemp = 11;
        if at!(info, 11) < 0 || at!(info, 11) > 2 {
            xerrwd("DASKR--  ELEMENT (=I1) OF INFO VECTOR IS NOT VALID", 1, 0, 1, itemp, 0, 0, 0.0, 0.0);
            l750!();
        }
        for i in 12..=17 {
            itemp = i;
            if at!(info, i) != 0 && at!(info, i) != 1 {
                xerrwd("DASKR--  ELEMENT (=I1) OF INFO VECTOR IS NOT VALID", 1, 0, 1, itemp, 0, 0, 0.0, 0.0);
                l750!();
            }
        }
        itemp = 18;
        if at!(info, 18) < 0 || at!(info, 18) > 2 {
            xerrwd("DASKR--  ELEMENT (=I1) OF INFO VECTOR IS NOT VALID", 1, 0, 1, itemp, 0, 0, 0.0, 0.0);
            l750!();
        }
        if neq <= 0 {
            xerrwd("DASKR--  NEQ (=I1) .LE. 0", 2, 0, 1, neq, 0, 0, 0.0, 0.0);
            l750!();
        }
        if at!(info, 9) != 0 && (mxord < 1 || mxord > 5) {
            xerrwd("DASKR--  MAXORD (=I1) NOT IN RANGE", 3, 0, 1, mxord, 0, 0, 0.0, 0.0);
            l750!();
        }
        at!(iwork, 3) = mxord;

        // Krylov input checks (info[12] != 0).
        if at!(info, 12) != 0 {
            at!(iwork, 23) = at!(info, 12);
            if at!(info, 13) == 0 {
                at!(iwork, 24) = 5.min(neq);
                at!(iwork, 25) = at!(iwork, 24);
                at!(iwork, 26) = 5;
                at!(rwork, 10) = 0.05;
            } else {
                if at!(iwork, 24) < 1 || at!(iwork, 24) > neq {
                    xerrwd("DASKR--  MAXL (=I1) ILLEGAL. EITHER .LT. 1 OR .GT. NEQ", 20, 0, 1, at!(iwork, 24), 0, 0, 0.0, 0.0);
                    l750!();
                }
                if at!(iwork, 25) < 1 || at!(iwork, 25) > at!(iwork, 24) {
                    xerrwd("DASKR--  KMP (=I1) ILLEGAL. EITHER .LT. 1 OR .GT. MAXL", 21, 0, 1, at!(iwork, 25), 0, 0, 0.0, 0.0);
                    l750!();
                }
                if at!(iwork, 26) < 0 {
                    xerrwd("DASKR--  NRMAX (=I1) ILLEGAL. .LT. 0", 22, 0, 1, at!(iwork, 26), 0, 0, 0.0, 0.0);
                    l750!();
                }
                if at!(rwork, 10) <= 0.0 || at!(rwork, 10) >= 1.0 {
                    xerrwd("DASKR--  EPLI (=R1) ILLEGAL. EITHER .LE. 0.D0 OR .GE. 1.D0", 23, 0, 0, 0, 0, 1, at!(rwork, 10), 0.0);
                    l750!();
                }
            }
        }

        // IC-calculation controls (info[11] > 0).
        if at!(info, 11) != 0 {
            if at!(info, 17) == 0 {
                at!(iwork, 32) = if at!(info, 12) > 0 { 15 } else { 5 };
                at!(iwork, 33) = if at!(info, 12) > 0 { 2 } else { 6 };
                at!(iwork, 34) = 5;
                at!(iwork, 35) = 0;
                at!(rwork, 15) = 0.01;
            } else {
                let lsoff = at!(iwork, 35);
                if at!(iwork, 32) <= 0
                    || at!(iwork, 33) <= 0
                    || at!(iwork, 34) <= 0
                    || lsoff < 0
                    || lsoff > 1
                    || at!(rwork, 15) <= 0.0
                {
                    xerrwd("DASKR--  ONE OF THE INPUTS FOR INFO(17) = 1 IS ILLEGAL", 25, 0, 0, 0, 0, 0, 0.0, 0.0);
                    l750!();
                }
            }
        }

        // Work-array length computation and checks.
        let lenic = if at!(info, 10) == 1 || at!(info, 10) == 3 { neq } else { 0 };
        let lenpd;
        let lenrw;
        let leniw;
        let lenwp;
        if at!(info, 12) == 0 {
            if at!(info, 6) == 0 {
                lenpd = neq * neq;
                lenrw = nrt * 3 + 60 + (ncphi + 3) * neq + lenpd;
                at!(iwork, 4) = if at!(info, 5) == 0 { 2 } else { 1 };
            } else {
                if at!(iwork, 1) < 0 || at!(iwork, 1) >= neq {
                    xerrwd("DASKR--  ML (=I1) ILLEGAL. EITHER .LT. 0 OR .GT. NEQ", 17, 0, 1, at!(iwork, 1), 0, 0, 0.0, 0.0);
                    l750!();
                }
                if at!(iwork, 2) < 0 || at!(iwork, 2) >= neq {
                    xerrwd("DASKR--  MU (=I1) ILLEGAL. EITHER .LT. 0 OR .GT. NEQ", 18, 0, 1, at!(iwork, 2), 0, 0, 0.0, 0.0);
                    l750!();
                }
                lenpd = ((at!(iwork, 1) << 1) + at!(iwork, 2) + 1) * neq;
                if at!(info, 5) == 0 {
                    at!(iwork, 4) = 5;
                    let mband = at!(iwork, 1) + at!(iwork, 2) + 1;
                    let msave = neq / mband + 1;
                    lenrw = nrt * 3 + 60 + (ncphi + 3) * neq + lenpd + (msave << 1);
                } else {
                    at!(iwork, 4) = 4;
                    lenrw = nrt * 3 + 60 + (ncphi + 3) * neq + lenpd;
                }
            }
            leniw = lenic + 40 + lenid + neq;
            lenwp = 0;
        } else {
            let maxl = at!(iwork, 24);
            lenwp = at!(iwork, 27);
            let leniwp = at!(iwork, 28);
            lenpd = (maxl + 3 + 1.min(maxl - at!(iwork, 25))) * neq + (maxl + 3) * maxl + 1 + lenwp;
            lenrw = nrt * 3 + 60 + (mxord + 5) * neq + lenpd;
            leniw = lenic + 40 + lenid + leniwp;
        }
        let lenrw = if at!(info, 16) != 0 { lenrw + neq } else { lenrw };

        at!(iwork, 17) = leniw;
        at!(iwork, 18) = lenrw;
        at!(iwork, 22) = lenpd;
        at!(iwork, 29) = lenpd - lenwp + 1;
        if lrw < lenrw {
            xerrwd("DASKR--  RWORK LENGTH NEEDED, LENRW (=I1), EXCEEDS LRW (=I2)", 4, 0, 2, lenrw, lrw, 0, 0.0, 0.0);
            l750!();
        }
        if liw < leniw {
            xerrwd("DASKR--  IWORK LENGTH NEEDED, LENIW (=I1), EXCEEDS LIW (=I2)", 5, 0, 2, leniw, liw, 0, 0.0, 0.0);
            l750!();
        }

        // ICNSTR / Y consistency checks.
        if lenic > 0 {
            for i in 1..=neq {
                let ici = at!(iwork, i + 40);
                if ici < -2 || ici > 2 {
                    xerrwd("DASKR--  ILLEGAL IWORK VALUE FOR INFO(10) .NE. 0", 26, 0, 0, 0, 0, 0, 0.0, 0.0);
                    l750!();
                }
            }
            let mut iret = 0i32;
            dcnst0(neq, y, iw(41), &mut iret);
            if iret != 0 {
                xerrwd("DASKR--  Y(I) AND IWORK(40+I) (I=I1) INCONSISTENT", 27, 0, 1, iret, 0, 0, 0.0, 0.0);
                l750!();
            }
        }

        // ID legality (and INDEX).
        if lenid > 0 {
            for i in 1..=neq {
                let idi = at!(iwork, lid - 1 + i);
                if idi != 1 && idi != -1 {
                    xerrwd("DASKR--  ILLEGAL IWORK VALUE FOR INFO(11) .NE. 0", 24, 0, 0, 0, 0, 0, 0.0, 0.0);
                    l750!();
                }
            }
        }

        if *tout == *t {
            xerrwd("DASKR--  TOUT (=R1) IS EQUAL TO T (=R2)", 19, 0, 0, 0, 0, 2, *tout, *t);
            l750!();
        }
        if nrt < 0 {
            xerrwd("DASKR--  NRT (=I1) .LT. 0", 30, 1, 1, nrt, 0, 0, 0.0, 0.0);
            l750!();
        }
        if at!(info, 7) != 0 {
            let hmax = at!(rwork, 2);
            if hmax <= 0.0 {
                xerrwd("DASKR--  HMAX (=R1) .LT. 0.0", 10, 0, 0, 0, 0, 1, hmax, 0.0);
                l750!();
            }
        }

        // Initialize counters.
        for &k in &[11, 12, 13, 14, 15, 19, 20, 21, 16, 36] {
            at!(iwork, k) = 0;
        }
        at!(iwork, 31) = at!(info, 18);
        *idid = 1;
    } else if at!(info, 1) != 1 {
        if at!(info, 1) != -1 {
            xerrwd("DASKR--  ELEMENT (=I1) OF INFO VECTOR IS NOT VALID", 1, 0, 1, 1, 0, 0, 0.0, 0.0);
            l750!();
        }
        xerrwd("DASKR--  THE LAST STEP TERMINATED WITH A NEGATIVE", 201, 0, 0, 0, 0, 0, 0.0, 0.0);
        xerrwd("DASKR--  VALUE (=I1) OF IDID AND NO APPROPRIATE", 202, 0, 1, *idid, 0, 0, 0.0, 0.0);
        xerrwd("DASKR--  ACTION WAS TAKEN. RUN TERMINATED", 203, 2, 0, 0, 0, 0, 0.0, 0.0);
        return;
    }

    // -------------------------------------------------------------------
    // L200: executed on all calls.
    // -------------------------------------------------------------------
    at!(iwork, 10) = at!(iwork, 11);
    let nli0 = at!(iwork, 20);
    let nni0 = at!(iwork, 19);
    let ncfn0 = at!(iwork, 15);
    let ncfl0 = at!(iwork, 16);
    let mut nwarn = 0i32;

    // Check RTOL and ATOL.
    let mut nzflg = 0i32;
    let mut rtoli = at!(rtol, 1);
    let mut atoli = at!(atol, 1);
    for i in 1..=neq {
        if at!(info, 2) == 1 {
            rtoli = at!(rtol, i);
            atoli = at!(atol, i);
        }
        if rtoli > 0.0 || atoli > 0.0 {
            nzflg = 1;
        }
        if rtoli < 0.0 {
            xerrwd("DASKR--  SOME ELEMENT OF RTOL IS .LT. 0", 6, 0, 0, 0, 0, 0, 0.0, 0.0);
            l750!();
        }
        if atoli < 0.0 {
            xerrwd("DASKR--  SOME ELEMENT OF ATOL IS .LT. 0", 7, 0, 0, 0, 0, 0, 0.0, 0.0);
            l750!();
        }
    }
    if nzflg == 0 {
        xerrwd("DASKR--  ALL ELEMENTS OF RTOL AND ATOL ARE ZERO", 8, 0, 0, 0, 0, 0, 0.0, 0.0);
        l750!();
    }

    // Set pointers to RWORK / IWORK segments.
    at!(iwork, 30) = lid + lenid;
    let lsavr = if at!(info, 12) != 0 { neq + 61 } else { 61 };
    let le = lsavr + neq;
    let lwt = le + neq;
    let lvt = if at!(info, 16) != 0 { lwt + neq } else { lwt };
    let lphi = lvt + neq;
    let lr0 = lphi + ncphi * neq;
    let lr1 = lr0 + nrt;
    let lrx = lr1 + nrt;
    let lwm = lrx + nrt;

    let mut ier = 0i32;
    let mut irt = 0i32;

    if at!(info, 1) != 1 {
        // ---------------------------------------------------------------
        // Initial call: set up step size, weights, PHI; compute IC.
        // ---------------------------------------------------------------
        tn = *t;
        *idid = 1;
        ddawts(neq, at!(info, 2), rtol, atol, y, rw(lwt), rpar, ipar);
        dinvwt(neq, rw(lwt), &mut ier);
        if ier != 0 {
            xerrwd("DASKR--  SOME ELEMENT OF WT IS .LE. 0.0", 13, 0, 0, 0, 0, 0, 0.0, 0.0);
            l750!();
        }
        if at!(info, 16) != 0 {
            for i in 1..=neq {
                at!(rwork, lvt + i - 1) = at!(iwork, lid + i - 1).max(0) as f64 * at!(rwork, lwt + i - 1);
            }
        }

        uround = crate::aux::d1mach();
        at!(rwork, 9) = uround;
        hmin = uround * 4.0 * (*t).abs().max((*tout).abs());

        if at!(info, 11) != 0 {
            if at!(info, 17) == 0 {
                at!(rwork, 14) = real_pow(uround, 0.6667);
            } else if at!(rwork, 14) <= 0.0 {
                xerrwd("DASKR--  ONE OF THE INPUTS FOR INFO(17) = 1 IS ILLEGAL", 25, 0, 0, 0, 0, 0, 0.0, 0.0);
                l750!();
            }
        }

        at!(rwork, 13) = 0.33;
        let floatn = neq as f64;
        at!(rwork, 11) = floatn.sqrt();
        at!(rwork, 12) = 1.0 / at!(rwork, 11);

        let tdist = (*tout - *t).abs();
        if tdist < hmin {
            xerrwd("DASKR-- TOUT (=R1) TOO CLOSE TO T (=R2) TO START INTEGRATION", 14, 0, 0, 0, 0, 2, *tout, *t);
            l750!();
        }

        // Initial stepsize H0.
        if at!(info, 8) != 0 {
            h0 = at!(rwork, 3);
            if (*tout - *t) * h0 < 0.0 {
                xerrwd("DASKR--  TOUT (=R1) BEHIND T (=R2)", 11, 0, 0, 0, 0, 2, *tout, *t);
                l750!();
            }
            if h0 == 0.0 {
                xerrwd("DASKR--  INFO(8)=1 AND H0=0.0", 12, 0, 0, 0, 0, 0, 0.0, 0.0);
                l750!();
            }
        } else {
            h0 = tdist * 0.001;
            let ypnorm = ddwnrm(neq, yprime, rw(lvt), rpar, ipar);
            if ypnorm > 0.5 / h0 {
                h0 = 0.5 / ypnorm;
            }
            h0 = real_sign(h0, *tout - *t);
        }
        if at!(info, 7) != 0 {
            let rh = h0.abs() / at!(rwork, 2);
            if rh > 1.0 {
                h0 /= rh;
            }
        }
        if at!(info, 4) != 0 {
            tstop = at!(rwork, 1);
            if (tstop - *t) * h0 < 0.0 {
                xerrwd("DASKR--  INFO(4)=1 AND TSTOP (=R1) BEHIND T (=R2)", 15, 0, 0, 0, 0, 2, tstop, *t);
                l750!();
            }
            if (*t + h0 - tstop) * h0 > 0.0 {
                h0 = tstop - *t;
            }
            if (tstop - *tout) * h0 < 0.0 {
                xerrwd("DASKR--  INFO(4) = 1 AND TSTOP (=R1) BEHIND TOUT (=R2)", 9, 0, 0, 0, 0, 2, tstop, *tout);
                l750!();
            }
        }

        // IC calculation (info[11] != 0).
        if at!(info, 11) != 0 {
            let mut nwt = 1i32;
            let epconi = at!(rwork, 15) * at!(rwork, 13);
            let index = if lenid > 0 {
                let mut idx = 0i32;
                for i in 1..=neq {
                    if at!(iwork, lid - 1 + i) == -1 {
                        idx = 1;
                    }
                }
                idx
            } else {
                1
            };
            let tscale = if index == 0 { tdist } else { 0.0 };
            let ntype = at!(info, 12);
            loop {
                let (lyic, lypic, lpwk) = if ntype == 0 {
                    let lyic = lphi + (neq << 1);
                    (lyic, lyic + neq, lyic + neq)
                } else {
                    let lyic = lwm;
                    (lyic, lyic + neq, lyic + 2 * neq)
                };
                let mut h0v = h0;
                let mut tscale_v = tscale;
                let mut epconi_v = epconi;
                ddasic(
                    &mut tn, y, yprime, neq, at!(info, 11), iw(lid), res, jacd, jack, psol,
                    &mut h0v, &mut tscale_v, rw(lwt), nwt, idid, rpar, ipar, rw(lphi), rw(lsavr),
                    rw(61), rw(le), rw(lyic), rw(lypic), rw(lpwk), rw(lwm), iworkbase(iwork), rw(9),
                    rw(10), rw(11), rw(12), &mut epconi_v, rw(14), inf(15), icnflg, iw(41), ntype,
                );
                h0 = h0v;
                if *idid < 0 {
                    l600!();
                }
                if nwt == 2 {
                    break;
                }
                nwt = 2;
                ddawts(neq, at!(info, 2), rtol, atol, y, rw(lwt), rpar, ipar);
                dinvwt(neq, rw(lwt), &mut ier);
                if ier != 0 {
                    xerrwd("DASKR--  SOME ELEMENT OF WT IS .LE. 0.0", 13, 0, 0, 0, 0, 0, 0.0, 0.0);
                    l750!();
                }
            }

            // L355: optional early return (info[14] = 1).
            if at!(info, 14) == 1 {
                *idid = 4;
                h = h0;
                if at!(info, 11) == 1 {
                    at!(rwork, 7) = h0;
                }
                l590!();
            }

            // Update WT/VT with the new Y.
            ddawts(neq, at!(info, 2), rtol, atol, y, rw(lwt), rpar, ipar);
            dinvwt(neq, rw(lwt), &mut ier);
            if ier != 0 {
                xerrwd("DASKR--  SOME ELEMENT OF WT IS .LE. 0.0", 13, 0, 0, 0, 0, 0, 0.0, 0.0);
                l750!();
            }
            if at!(info, 16) != 0 {
                for i in 1..=neq {
                    at!(rwork, lvt + i - 1) = at!(iwork, lid + i - 1).max(0) as f64 * at!(rwork, lwt + i - 1);
                }
            }

            // Reset initial stepsize for DDSTP.
            if at!(info, 8) != 0 {
                h0 = at!(rwork, 3);
            } else {
                h0 = tdist * 0.001;
                let ypnorm = ddwnrm(neq, yprime, rw(lvt), rpar, ipar);
                if ypnorm > 0.5 / h0 {
                    h0 = 0.5 / ypnorm;
                }
                h0 = real_sign(h0, *tout - *t);
            }
            if at!(info, 7) != 0 {
                let rh = h0.abs() / at!(rwork, 2);
                if rh > 1.0 {
                    h0 /= rh;
                }
            }
            if at!(info, 4) != 0 {
                tstop = at!(rwork, 1);
                if (*t + h0 - tstop) * h0 > 0.0 {
                    h0 = tstop - *t;
                }
            }
        }

        // L370: load H and PHI(*,1), PHI(*,2).
        h = h0;
        at!(rwork, 3) = h;
        for i in 1..=neq {
            at!(rwork, lphi + i - 1) = at!(y, i);
            at!(rwork, lphi + neq + i - 1) = h * at!(yprime, i);
        }

        at!(rwork, 51) = *t;
        at!(iwork, 37) = 0;
        at!(rwork, 39) = h;
        at!(rwork, 40) = h * 2.0;
        at!(iwork, 8) = 1;
        if nrt != 0 {
            drchek(
                1, rt, &mut nrt_l, &mut neq_l, t, tout, y, yprime, rw(lphi), rw(39), iw(8), rw(lr0),
                rw(lr1), rw(lrx), jroot, &mut irt, rw(9), at!(info, 3), rwork, iwork, rpar, ipar,
            );
            if irt < 0 {
                xerrwd("DASKR--  R IS ILL-DEFINED.  ZERO VALUES WERE FOUND AT TWO", 31, 1, 0, 0, 0, 0, 0.0, 0.0);
                xerrwd("         VERY CLOSE T VALUES, AT T = R1", 31, 1, 0, 0, 0, 1, at!(rwork, 51), 0.0);
                l750!();
            }
        }
        // -> L500
    } else {
        // ---------------------------------------------------------------
        // L400: continuation call: check stop conditions before stepping.
        // ---------------------------------------------------------------
        uround = at!(rwork, 9);
        let mut done = false;
        tn = at!(rwork, 4);
        h = at!(rwork, 3);
        if nrt != 0 {
            drchek(
                2, rt, &mut nrt_l, &mut neq_l, &mut tn, tout, y, yprime, rw(lphi), rw(39), iw(8),
                rw(lr0), rw(lr1), rw(lrx), jroot, &mut irt, rw(9), at!(info, 3), rwork, iwork, rpar,
                ipar,
            );
            if irt < 0 {
                xerrwd("DASKR--  R IS ILL-DEFINED.  ZERO VALUES WERE FOUND AT TWO", 31, 1, 0, 0, 0, 0, 0.0, 0.0);
                xerrwd("         VERY CLOSE T VALUES, AT T = R1", 31, 1, 0, 0, 0, 1, at!(rwork, 51), 0.0);
                l750!();
            }
            if irt == 1 {
                at!(iwork, 37) = 1;
                *idid = 5;
                *t = at!(rwork, 51);
                done = true;
            }
        }

        if !done {
            // L405
            if at!(info, 7) != 0 {
                let rh = h.abs() / at!(rwork, 2);
                if rh > 1.0 {
                    h /= rh;
                }
            }
            if *t == *tout {
                xerrwd("DASKR--  TOUT (=R1) IS EQUAL TO T (=R2)", 19, 0, 0, 0, 0, 2, *tout, *t);
                l750!();
            }
            if (*t - *tout) * h > 0.0 {
                xerrwd("DASKR--  TOUT (=R1) BEHIND T (=R2)", 11, 0, 0, 0, 0, 2, *tout, *t);
                l750!();
            }
            if at!(info, 4) == 1 {
                // TSTOP cases (L430/L440).
                tstop = at!(rwork, 1);
                if at!(info, 3) == 0 {
                    if (tn - tstop) * h > 0.0 {
                        xerrwd("DASKR--  INFO(4)=1 AND TSTOP (=R1) BEHIND T (=R2)", 15, 0, 0, 0, 0, 2, tstop, *t);
                        l750!();
                    }
                    if (tstop - *tout) * h < 0.0 {
                        xerrwd("DASKR--  INFO(4) = 1 AND TSTOP (=R1) BEHIND TOUT (=R2)", 9, 0, 0, 0, 0, 2, tstop, *tout);
                        l750!();
                    }
                    if (tn - *tout) * h >= 0.0 {
                        ddatrp(tn, *tout, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                        *t = *tout;
                        *idid = 3;
                        done = true;
                    }
                } else {
                    if (tn - tstop) * h > 0.0 {
                        xerrwd("DASKR--  INFO(4)=1 AND TSTOP (=R1) BEHIND T (=R2)", 15, 0, 0, 0, 0, 2, tstop, *t);
                        l750!();
                    }
                    if (tstop - *tout) * h < 0.0 {
                        xerrwd("DASKR--  INFO(4) = 1 AND TSTOP (=R1) BEHIND TOUT (=R2)", 9, 0, 0, 0, 0, 2, tstop, *tout);
                        l750!();
                    }
                    if (tn - *t) * h <= 0.0 {
                        // L450 roundoff-of-tstop test
                    } else if (tn - *tout) * h >= 0.0 {
                        ddatrp(tn, *tout, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                        *t = *tout;
                        *idid = 3;
                        done = true;
                    } else {
                        ddatrp(tn, tn, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                        *t = tn;
                        *idid = 1;
                        done = true;
                    }
                }
                if !done {
                    // L450
                    if (tn - tstop).abs() <= uround * 100.0 * (tn.abs() + h.abs()) {
                        ddatrp(tn, tstop, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                        *idid = 2;
                        *t = tstop;
                        done = true;
                    } else {
                        let tnext = tn + h;
                        if (tnext - tstop) * h > 0.0 {
                            h = tstop - tn;
                            at!(rwork, 3) = h;
                        }
                    }
                }
            } else if at!(info, 3) == 1 {
                // L420 intermediate-output, no TSTOP.
                if (tn - *t) * h <= 0.0 {
                    // -> L490 (not done)
                } else if (tn - *tout) * h >= 0.0 {
                    ddatrp(tn, *tout, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                    *t = *tout;
                    *idid = 3;
                    done = true;
                } else {
                    ddatrp(tn, tn, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                    *t = tn;
                    *idid = 1;
                    done = true;
                }
            } else {
                // No TSTOP, interval-output.
                if (tn - *tout) * h >= 0.0 {
                    ddatrp(tn, *tout, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                    *t = *tout;
                    *idid = 3;
                    done = true;
                }
            }
        }

        if done {
            l590!();
        }
        // -> L500
    }

    // -------------------------------------------------------------------
    // L500: step loop.
    // -------------------------------------------------------------------
    let info12 = at!(info, 12);
    loop {
        let mut to527 = false;

        // Too many steps?
        if at!(iwork, 11) - at!(iwork, 10) >= 500 {
            *idid = -1;
            to527 = true;
        }

        if !to527 {
            // Poor Newton/Krylov performance (Krylov only).
            if info12 != 0 {
                let nstd = at!(iwork, 11) - at!(iwork, 10);
                let nnid = at!(iwork, 19) - nni0;
                if nstd >= 10 && nnid != 0 {
                    let avlin = (at!(iwork, 20) - nli0) as f64 / nnid as f64;
                    let rcfn = (at!(iwork, 15) - ncfn0) as f64 / nstd as f64;
                    let rcfl = (at!(iwork, 16) - ncfl0) as f64 / nnid as f64;
                    let fmaxl = at!(iwork, 24) as f64;
                    let lavl = avlin > fmaxl;
                    let lcfn = rcfn > 0.9;
                    let lcfl = rcfl > 0.9;
                    if (lavl || lcfn || lcfl) && nwarn <= 10 {
                        nwarn += 1;
                        if lavl {
                            xerrwd("DASKR-- Warning. Poor iterative algorithm performance   ", 501, 0, 0, 0, 0, 0, 0.0, 0.0);
                            xerrwd("      at T = R1. Average no. of linear iterations = R2  ", 501, 0, 0, 0, 0, 2, tn, avlin);
                        }
                        if lcfn {
                            xerrwd("DASKR-- Warning. Poor iterative algorithm performance   ", 502, 0, 0, 0, 0, 0, 0.0, 0.0);
                            xerrwd("      at T = R1. Nonlinear convergence failure rate = R2", 502, 0, 0, 0, 0, 2, tn, rcfn);
                        }
                        if lcfl {
                            xerrwd("DASKR-- Warning. Poor iterative algorithm performance   ", 503, 0, 0, 0, 0, 0, 0.0, 0.0);
                            xerrwd("      at T = R1. Linear convergence failure rate = R2   ", 503, 0, 0, 0, 0, 2, tn, rcfl);
                        }
                    }
                }
            }

            // L510: update WT/VT.
            ddawts(neq, at!(info, 2), rtol, atol, rw(lphi), rw(lwt), rpar, ipar);
            dinvwt(neq, rw(lwt), &mut ier);
            if ier != 0 {
                *idid = -3;
                to527 = true;
            }
        }

        if !to527 {
            if at!(info, 16) != 0 {
                for i in 1..=neq {
                    at!(rwork, lvt + i - 1) = at!(iwork, lid + i - 1).max(0) as f64 * at!(rwork, lwt + i - 1);
                }
            }

            // Test for too much accuracy.
            r_acc = ddwnrm(neq, rw(lphi), rw(lwt), rpar, ipar) * 100.0 * uround;
            if r_acc > 1.0 {
                if at!(info, 2) == 1 {
                    for i in 1..=neq {
                        at!(rtol, i) = r_acc * at!(rtol, i);
                        at!(atol, i) = r_acc * at!(atol, i);
                    }
                } else {
                    at!(rtol, 1) = r_acc * at!(rtol, 1);
                    at!(atol, 1) = r_acc * at!(atol, 1);
                }
                *idid = -2;
                to527 = true;
            }
        }

        if !to527 {
            hmin = uround * 4.0 * tn.abs().max((*tout).abs());
            if at!(info, 7) != 0 {
                let rh = h.abs() / at!(rwork, 2);
                if rh > 1.0 {
                    h /= rh;
                }
            }

            // Call the one-step integrator.
            ddstp(
                &mut tn, y, yprime, neq, res, jacd, jack, psol, &mut h, rw(lwt), rw(lvt), inf(1),
                idid, rpar, ipar, rw(lphi), rw(lsavr), rw(61), rw(le), rw(lwm), iworkbase(iwork),
                rw(21), rw(27), rw(33), rw(39), rw(45), rw(5), rw(6), rw(7), rw(8), &mut hmin, rw(9),
                rw(10), rw(11), rw(12), rw(13), iw(6), iw(5), inf(15), iw(7), iw(8), iw(9), nonneg,
                info12,
            );
        }

        // L527
        if *idid < 0 {
            l600!();
        }

        // Successful step (idid = 1): test stop conditions.
        let mut at_l530 = nrt == 0;
        if !at_l530 {
            drchek(
                3, rt, &mut nrt_l, &mut neq_l, &mut tn, tout, y, yprime, rw(lphi), rw(39), iw(8),
                rw(lr0), rw(lr1), rw(lrx), jroot, &mut irt, rw(9), at!(info, 3), rwork, iwork, rpar,
                ipar,
            );
            if irt == 1 {
                at!(iwork, 37) = 1;
                *idid = 5;
                *t = at!(rwork, 51);
                l590!();
            }
            at_l530 = true;
        }

        if at_l530 {
            if at!(info, 4) == 0 {
                // No TSTOP.
                if (tn - *tout) * h >= 0.0 {
                    ddatrp(tn, *tout, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                    *t = *tout;
                    *idid = 3;
                    l590!();
                }
                if at!(info, 3) == 0 {
                    continue;
                }
                *t = tn;
                *idid = 1;
                l590!();
            } else if at!(info, 3) == 0 {
                // TSTOP, interval-output (L540).
                if (tn - tstop).abs() <= uround * 100.0 * (tn.abs() + h.abs()) {
                    ddatrp(tn, tstop, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                    *t = tstop;
                    *idid = 2;
                    l590!();
                }
                if (tn - *tout) * h >= 0.0 {
                    ddatrp(tn, *tout, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                    *t = *tout;
                    *idid = 3;
                    l590!();
                }
                let tnext = tn + h;
                if (tnext - tstop) * h > 0.0 {
                    h = tstop - tn;
                }
                continue;
            } else {
                // TSTOP, intermediate-output (L550).
                if (tn - tstop).abs() <= uround * 100.0 * (tn.abs() + h.abs()) {
                    ddatrp(tn, tstop, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                    *t = tstop;
                    *idid = 2;
                    l590!();
                }
                if (tn - *tout) * h >= 0.0 {
                    ddatrp(tn, *tout, y, yprime, neq, at!(iwork, 8), rw(lphi), rw(39));
                    *t = *tout;
                    *idid = 3;
                    l590!();
                }
                *t = tn;
                *idid = 1;
                l590!();
            }
        }
    }
}

/// Helper: the IWORK base pointer as `&iwork[1]` (element 1).
#[inline]
unsafe fn iworkbase(iwork: *mut i32) -> *mut i32 {
    iwork
}

// ===========================================================================
// Krylov (GMRES) linear-solver core
// ===========================================================================

/// `DHEQR` — QR factorization of an `(n+1) x n` upper-Hessenberg matrix `a` via
/// Givens rotations (stored in `q`). `ijob > 1` updates an existing
/// factorization by one row/column. `*info = k` flags a zero `R(k,k)`.
pub(crate) unsafe fn dheqr(a: *mut f64, lda: i32, n: i32, q: *mut f64, info: *mut i32, ijob: i32) {
    let givens = |t1: f64, t2: f64| -> (f64, f64) {
        if t2 == 0.0 {
            (1.0, 0.0)
        } else if t2.abs() >= t1.abs() {
            let t = t1 / t2;
            let s = -1.0 / (t * t + 1.0).sqrt();
            (-s * t, s)
        } else {
            let t = t2 / t1;
            let c = 1.0 / (t * t + 1.0).sqrt();
            (c, -c * t)
        }
    };
    if ijob <= 1 {
        *info = 0;
        for k in 1..=n {
            let km1 = k - 1;
            let kp1 = k + 1;
            if km1 >= 1 {
                for j in 1..=km1 {
                    let i = ((j - 1) << 1) + 1;
                    let t1 = at2!(a, j, k, lda);
                    let t2 = at2!(a, j + 1, k, lda);
                    let c = at!(q, i);
                    let s = at!(q, i + 1);
                    at2!(a, j, k, lda) = c * t1 - s * t2;
                    at2!(a, j + 1, k, lda) = s * t1 + c * t2;
                }
            }
            let iq = (km1 << 1) + 1;
            let t1 = at2!(a, k, k, lda);
            let t2 = at2!(a, kp1, k, lda);
            let (c, s) = givens(t1, t2);
            at!(q, iq) = c;
            at!(q, iq + 1) = s;
            at2!(a, k, k, lda) = c * t1 - s * t2;
            if at2!(a, k, k, lda) == 0.0 {
                *info = k;
            }
        }
    } else {
        let nm1 = n - 1;
        for k in 1..=nm1 {
            let i = ((k - 1) << 1) + 1;
            let t1 = at2!(a, k, n, lda);
            let t2 = at2!(a, k + 1, n, lda);
            let c = at!(q, i);
            let s = at!(q, i + 1);
            at2!(a, k, n, lda) = c * t1 - s * t2;
            at2!(a, k + 1, n, lda) = s * t1 + c * t2;
        }
        *info = 0;
        let t1 = at2!(a, n, n, lda);
        let t2 = at2!(a, n + 1, n, lda);
        let (c, s) = givens(t1, t2);
        let iq = (n << 1) - 1;
        at!(q, iq) = c;
        at!(q, iq + 1) = s;
        at2!(a, n, n, lda) = c * t1 - s * t2;
        if at2!(a, n, n, lda) == 0.0 {
            *info = n;
        }
    }
}

/// `DHELS` — least-squares solve `min ||b - a x||` for the Hessenberg system,
/// using the QR factors from [`dheqr`]. `b` holds the RHS, then the solution.
pub(crate) unsafe fn dhels(a: *mut f64, lda: i32, n: i32, q: *mut f64, b: *mut f64) {
    for k in 1..=n {
        let kp1 = k + 1;
        let iq = ((k - 1) << 1) + 1;
        let c = at!(q, iq);
        let s = at!(q, iq + 1);
        let t1 = at!(b, k);
        let t2 = at!(b, kp1);
        at!(b, k) = c * t1 - s * t2;
        at!(b, kp1) = s * t1 + c * t2;
    }
    for kb in 1..=n {
        let k = n + 1 - kb;
        at!(b, k) /= at2!(a, k, k, lda);
        let t = -at!(b, k);
        for i in 1..=(k - 1) {
            at!(b, i) += t * at2!(a, i, k, lda);
        }
    }
}

/// `DORTH` — modified Gram-Schmidt orthogonalization (with conditional
/// reorthogonalization) of `vnew` against the previous `kmp` columns of `v`;
/// fills column `ll` of `hes` and returns `||vnew||` in `*snormw`.
pub(crate) unsafe fn dorth(
    vnew: *mut f64,
    v: *mut f64,
    hes: *mut f64,
    n: i32,
    ll: i32,
    ldhes: i32,
    kmp: i32,
    snormw: *mut f64,
) {
    let col = |i: i32| v.offset(((i - 1) * n) as isize);
    let vnrm = linpack::dnrm2(n, rsl(vnew, n), 1);
    let i0 = 1.max(ll - kmp + 1);
    for i in i0..=ll {
        let d = linpack::ddot(n, rsl(col(i), n), 1, rsl(vnew, n), 1);
        at2!(hes, i, ll, ldhes) = d;
        linpack::daxpy(n, -d, rsl(col(i), n), 1, rslm(vnew, n), 1);
    }
    *snormw = linpack::dnrm2(n, rsl(vnew, n), 1);
    if vnrm + *snormw * 0.001 != vnrm {
        return;
    }
    let mut sumdsq = 0.0f64;
    for i in i0..=ll {
        let tem = -linpack::ddot(n, rsl(col(i), n), 1, rsl(vnew, n), 1);
        if at2!(hes, i, ll, ldhes) + tem * 0.001 == at2!(hes, i, ll, ldhes) {
            continue;
        }
        at2!(hes, i, ll, ldhes) -= tem;
        linpack::daxpy(n, tem, rsl(col(i), n), 1, rslm(vnew, n), 1);
        sumdsq += tem * tem;
    }
    if sumdsq == 0.0 {
        return;
    }
    let d3 = *snormw;
    *snormw = 0.0f64.max(d3 * d3 - sumdsq).sqrt();
}

/// `DATV` — scaled, preconditioned matrix-vector product
/// `z = D^{-1} P^{-1} (dF/dY) D v`, formed by a difference quotient (one `res`)
/// and one `psol`. `v` may equal `z`.
pub(crate) unsafe fn datv(
    neq: i32,
    y: *mut f64,
    tn: *mut f64,
    yprime: *mut f64,
    savr: *mut f64,
    v: *mut f64,
    wght: *mut f64,
    yptem: *mut f64,
    res: ResFn,
    ires: *mut i32,
    psol: PsolFn,
    z: *mut f64,
    vtem: *mut f64,
    wp: *mut f64,
    iwp: *mut i32,
    cj: *mut f64,
    eplin: *mut f64,
    ier: *mut i32,
    nre: *mut i32,
    npsl: *mut i32,
    rpar: *mut f64,
    ipar: *mut i32,
) {
    *ires = 0;
    for i in 1..=neq {
        at!(vtem, i) = at!(v, i) / at!(wght, i);
    }
    *ier = 0;
    for i in 1..=neq {
        at!(yptem, i) = at!(yprime, i) + at!(vtem, i) * *cj;
        at!(z, i) = at!(y, i) + at!(vtem, i);
    }
    res(tn, z, yptem, cj, vtem, ires, rpar, ipar);
    *nre += 1;
    if *ires < 0 {
        return;
    }
    for i in 1..=neq {
        at!(z, i) = at!(vtem, i) - at!(savr, i);
    }
    let mut neqv = neq;
    psol(&mut neqv, tn, y, yprime, savr, yptem, cj, wght, wp, iwp, z, eplin, ier, rpar, ipar);
    *npsl += 1;
    if *ier != 0 {
        return;
    }
    for i in 1..=neq {
        at!(z, i) *= at!(wght, i);
    }
}

/// `DSPIGM` — scaled, preconditioned GMRES solve of `A z = r` (initial guess 0).
/// Builds the Krylov basis `v`, the Hessenberg `hes`/`q`, and the iterate `z`.
/// `*iflag`: 0 converged, 1 reduced (not converged), 2 no progress, 3/-1 PSOL.
pub(crate) unsafe fn dspigm(
    neq: i32,
    tn: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    savr: *mut f64,
    r: *mut f64,
    wght: *mut f64,
    maxl: i32,
    maxlp1: i32,
    kmp: i32,
    eplin: *mut f64,
    cj: *mut f64,
    res: ResFn,
    ires: *mut i32,
    nre: *mut i32,
    psol: PsolFn,
    npsl: *mut i32,
    z: *mut f64,
    v: *mut f64,
    hes: *mut f64,
    q: *mut f64,
    lgmr: *mut i32,
    wp: *mut f64,
    iwp: *mut i32,
    wk: *mut f64,
    dl: *mut f64,
    rhok: *mut f64,
    iflag: *mut i32,
    irst: i32,
    nrsts: i32,
    rpar: *mut f64,
    ipar: *mut i32,
) {
    let col = |j: i32| v.offset(((j - 1) * neq) as isize);
    let mut ier = 0i32;
    *iflag = 0;
    *lgmr = 0;
    *npsl = 0;
    *nre = 0;
    for i in 1..=neq {
        at!(z, i) = 0.0;
    }

    macro_rules! l300 {
        () => {{
            if ier < 0 {
                *iflag = -1;
            }
            if ier > 0 {
                *iflag = 3;
            }
            return;
        }};
    }

    if nrsts == 0 {
        let mut neqv = neq;
        psol(&mut neqv, tn, y, yprime, savr, wk, cj, wght, wp, iwp, r, eplin, &mut ier, rpar, ipar);
        *npsl = 1;
        if ier != 0 {
            l300!();
        }
        for i in 1..=neq {
            at2!(v, i, 1, neq) = at!(r, i) * at!(wght, i);
        }
    } else {
        for i in 1..=neq {
            at2!(v, i, 1, neq) = at!(r, i);
        }
    }

    let rnrm = linpack::dnrm2(neq, rsl(v, neq), 1);
    if rnrm <= *eplin {
        *rhok = rnrm;
        return;
    }
    linpack::dscal(neq, 1.0 / rnrm, rslm(v, neq), 1);
    for j in 1..=maxl {
        for i in 1..=maxlp1 {
            at2!(hes, i, j, maxlp1) = 0.0;
        }
    }

    let mut prod = 1.0f64;
    let mut rho = 0.0f64;
    let mut snormw = 0.0f64;
    let mut info = 0i32;
    let mut converged = false;
    let mut to100 = false;

    for ll in 1..=maxl {
        *lgmr = ll;
        datv(
            neq, y, tn, yprime, savr, col(ll), wght, z, res, ires, psol, col(ll + 1), wk, wp, iwp,
            cj, eplin, &mut ier, nre, npsl, rpar, ipar,
        );
        if *ires < 0 {
            return;
        }
        if ier != 0 {
            l300!();
        }
        dorth(col(ll + 1), v, hes, neq, ll, maxlp1, kmp, &mut snormw);
        at2!(hes, ll + 1, ll, maxlp1) = snormw;
        dheqr(hes, maxlp1, ll, q, &mut info, ll);
        if info == ll {
            *iflag = 2;
            for i in 1..=neq {
                at!(z, i) = 0.0;
            }
            return;
        }

        prod *= at!(q, ll * 2);
        rho = (prod * rnrm).abs();
        if ll > kmp && kmp < maxl {
            if ll == kmp + 1 {
                for k in 1..=neq {
                    at!(dl, k) = at2!(v, k, 1, neq);
                }
                for i in 1..=kmp {
                    let ip1 = i + 1;
                    let i2 = i << 1;
                    let s = at!(q, i2);
                    let c = at!(q, i2 - 1);
                    for k in 1..=neq {
                        at!(dl, k) = s * at!(dl, k) + c * at2!(v, k, ip1, neq);
                    }
                }
            }
            let s = at!(q, ll * 2);
            let c = at!(q, (ll << 1) - 1) / snormw;
            let llp1 = ll + 1;
            for k in 1..=neq {
                at!(dl, k) = s * at!(dl, k) + c * at2!(v, k, llp1, neq);
            }
            rho *= linpack::dnrm2(neq, rsl(dl, neq), 1);
        }

        if rho <= *eplin {
            converged = true;
            break;
        }
        if ll == maxl {
            to100 = true;
            break;
        }
        linpack::dscal(neq, 1.0 / snormw, rslm(col(ll + 1), neq), 1);
    }

    if to100 {
        if rho < rnrm {
            *iflag = 1;
            if irst > 0 {
                if kmp == maxl {
                    for k in 1..=neq {
                        at!(dl, k) = at2!(v, k, 1, neq);
                    }
                    let maxlm1 = maxl - 1;
                    for i in 1..=maxlm1 {
                        let ip1 = i + 1;
                        let i2 = i << 1;
                        let s = at!(q, i2);
                        let c = at!(q, i2 - 1);
                        for k in 1..=neq {
                            at!(dl, k) = s * at!(dl, k) + c * at2!(v, k, ip1, neq);
                        }
                    }
                    let s = at!(q, maxl * 2);
                    let c = at!(q, (maxl << 1) - 1) / snormw;
                    for k in 1..=neq {
                        at!(dl, k) = s * at!(dl, k) + c * at2!(v, k, maxlp1, neq);
                    }
                }
                linpack::dscal(neq, rnrm * prod, rslm(dl, neq), 1);
            }
            converged = true;
        } else {
            *iflag = 2;
            for i in 1..=neq {
                at!(z, i) = 0.0;
            }
            return;
        }
    }

    // L200: compute the approximation ZL.
    let _ = converged;
    let ll = *lgmr;
    let llp1 = ll + 1;
    for k in 1..=llp1 {
        at!(r, k) = 0.0;
    }
    at!(r, 1) = rnrm;
    dhels(hes, maxlp1, ll, q, r);
    for k in 1..=neq {
        at!(z, k) = 0.0;
    }
    for i in 1..=ll {
        linpack::daxpy(neq, at!(r, i), rsl(col(i), neq), 1, rslm(z, neq), 1);
    }
    for i in 1..=neq {
        at!(z, i) /= at!(wght, i);
    }
    *rhok = rho;
}

/// `DSLVK` — interface to GMRES ([`dspigm`]) with restarting, solving the linear
/// system of the Krylov Newton iteration. `x` is RHS on input, solution on
/// output. `*iersl`: 0 ok, 1 failed to converge, -1 unrecoverable.
pub(crate) unsafe fn dslvk(
    neq: i32,
    y: *mut f64,
    tn: *mut f64,
    yprime: *mut f64,
    savr: *mut f64,
    x: *mut f64,
    ewt: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    res: ResFn,
    ires: *mut i32,
    psol: PsolFn,
    iersl: *mut i32,
    cj: *mut f64,
    eplin: *mut f64,
    sqrtn: *mut f64,
    rsqrtn: *mut f64,
    rhok: *mut f64,
    rpar: *mut f64,
    ipar: *mut i32,
) {
    const IRST: i32 = 1;
    let liwp = at!(iwm, 30);
    let mut nli = at!(iwm, 20);
    let mut nps = at!(iwm, 21);
    let mut ncfl = at!(iwm, 16);
    let mut nre = at!(iwm, 12);
    let lwp = at!(iwm, 29);
    let maxl = at!(iwm, 24);
    let kmp = at!(iwm, 25);
    let nrmax = at!(iwm, 26);
    *iersl = 0;
    *ires = 0;

    let maxlp1 = maxl + 1;
    let lv = 1;
    let lr = lv + neq * maxl;
    let lhes = lr + neq + 1;
    let lq = lhes + maxl * maxlp1;
    let lwk = lq + (maxl << 1);
    let ldl = lwk + 1.min(maxl - kmp) * neq;
    let lz = ldl + neq;

    linpack::dscal(neq, *rsqrtn, rslm(ewt, neq), 1);
    for i in 1..=neq {
        at!(wm, lr + i - 1) = at!(x, i);
    }
    for i in 1..=neq {
        at!(x, i) = 0.0;
    }

    let mut nrsts = -1i32;
    let mut iflag = 0i32;
    loop {
        nrsts += 1;
        if nrsts > 0 {
            for i in 1..=neq {
                at!(wm, lr + i - 1) = at!(wm, ldl + i - 1);
            }
        }
        let mut nres = 0i32;
        let mut npsl = 0i32;
        let mut lgmr = 0i32;
        iflag = 0;
        dspigm(
            neq, tn, y, yprime, savr, wm.offset((lr - 1) as isize), ewt, maxl, maxlp1, kmp, eplin,
            cj, res, ires, &mut nres, psol, &mut npsl, wm.offset((lz - 1) as isize),
            wm.offset((lv - 1) as isize), wm.offset((lhes - 1) as isize),
            wm.offset((lq - 1) as isize), &mut lgmr, wm.offset((lwp - 1) as isize),
            iwm.offset((liwp - 1) as isize), wm.offset((lwk - 1) as isize),
            wm.offset((ldl - 1) as isize), rhok, &mut iflag, IRST, nrsts, rpar, ipar,
        );
        nli += lgmr;
        nps += npsl;
        nre += nres;
        for i in 1..=neq {
            at!(x, i) += at!(wm, lz + i - 1);
        }
        if iflag == 1 && nrsts < nrmax && *ires == 0 {
            continue;
        }
        break;
    }

    if *ires < 0 {
        ncfl += 1;
    } else if iflag != 0 {
        ncfl += 1;
        if iflag > 0 {
            *iersl = 1;
        }
        if iflag < 0 {
            *iersl = -1;
        }
    }
    at!(iwm, 20) = nli;
    at!(iwm, 21) = nps;
    at!(iwm, 16) = ncfl;
    at!(iwm, 12) = nre;
    linpack::dscal(neq, *sqrtn, rslm(ewt, neq), 1);
}

/// `DNSK` — modified-Newton corrector for the Krylov method: each iterate solves
/// the linear system via [`dslvk`] and accumulates the change in `e`.
pub(crate) unsafe fn dnsk(
    x: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    neq: i32,
    res: ResFn,
    psol: PsolFn,
    wt: *mut f64,
    rpar: *mut f64,
    ipar: *mut i32,
    savr: *mut f64,
    delta: *mut f64,
    e: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    cj: *mut f64,
    sqrtn: *mut f64,
    rsqrtn: *mut f64,
    eplin: *mut f64,
    epcon: *mut f64,
    s: *mut f64,
    confac: f64,
    tolnew: f64,
    muldel: i32,
    maxit: i32,
    ires: *mut i32,
    iersl: *mut i32,
    iernew: *mut i32,
) {
    let mut m = 0i32;
    for i in 1..=neq {
        at!(e, i) = 0.0;
    }
    let mut oldnrm = 0.0f64;
    loop {
        at!(iwm, 19) += 1;
        if muldel == 1 {
            for i in 1..=neq {
                at!(delta, i) *= confac;
            }
        }
        for i in 1..=neq {
            at!(savr, i) = at!(delta, i);
        }
        let mut rhok = 0.0f64;
        dslvk(
            neq, y, x, yprime, savr, delta, wt, wm, iwm, res, ires, psol, iersl, cj, eplin, sqrtn,
            rsqrtn, &mut rhok, rpar, ipar,
        );
        if *ires != 0 || *iersl != 0 {
            *iernew = if *ires <= -2 || *iersl < 0 { -1 } else { 1 };
            return;
        }
        for i in 1..=neq {
            at!(y, i) -= at!(delta, i);
            at!(e, i) -= at!(delta, i);
            at!(yprime, i) -= *cj * at!(delta, i);
        }
        let delnrm = ddwnrm(neq, delta, wt, rpar, ipar);
        if m == 0 {
            oldnrm = delnrm;
            if delnrm <= tolnew {
                return;
            }
        } else {
            let rate = real_pow(delnrm / oldnrm, 1.0 / (m as f64));
            if rate > 0.9 {
                *iernew = if *ires <= -2 || *iersl < 0 { -1 } else { 1 };
                return;
            }
            *s = rate / (1.0 - rate);
        }
        if *s * delnrm <= *epcon {
            return;
        }
        m += 1;
        if m >= maxit {
            *iernew = if *ires <= -2 || *iersl < 0 { -1 } else { 1 };
            return;
        }
        at!(iwm, 12) += 1;
        res(x, y, yprime, cj, delta, ires, rpar, ipar);
        if *ires < 0 {
            *iernew = if *ires <= -2 || *iersl < 0 { -1 } else { 1 };
            return;
        }
    }
}

/// `DFNRMK` — scaled, preconditioned norm `||P^{-1} G(t, y, y')||` for the
/// Krylov IC iteration (weights temporarily scaled by `1/sqrt(neq)`).
pub(crate) unsafe fn dfnrmk(
    neq: i32,
    y: *mut f64,
    t: *mut f64,
    yprime: *mut f64,
    savr: *mut f64,
    r: *mut f64,
    cj: *mut f64,
    tscale: *mut f64,
    wt: *mut f64,
    sqrtn: *mut f64,
    rsqrtn: *mut f64,
    res: ResFn,
    ires: *mut i32,
    psol: PsolFn,
    irin: i32,
    ier: *mut i32,
    fnorm: *mut f64,
    eplin: *mut f64,
    wp: *mut f64,
    iwp: *mut i32,
    pwk: *mut f64,
    rpar: *mut f64,
    ipar: *mut i32,
) {
    if irin == 0 {
        *ires = 0;
        res(t, y, yprime, cj, savr, ires, rpar, ipar);
        if *ires < 0 {
            return;
        }
    }
    for i in 1..=neq {
        at!(r, i) = at!(savr, i);
    }
    linpack::dscal(neq, *rsqrtn, rslm(wt, neq), 1);
    *ier = 0;
    let mut neqv = neq;
    psol(&mut neqv, t, y, yprime, savr, pwk, cj, wt, wp, iwp, r, eplin, ier, rpar, ipar);
    linpack::dscal(neq, *sqrtn, rslm(wt, neq), 1);
    if *ier != 0 {
        return;
    }
    *fnorm = ddwnrm(neq, r, wt, rpar, ipar);
    if *tscale > 0.0 {
        *fnorm = *fnorm * *tscale * (*cj).abs();
    }
}

/// `DLINSK` — backtracking linesearch for the Krylov IC Newton step (merit
/// function `½||P^{-1} G||²`), honouring constraints. Updates `(y, yprime)`.
pub(crate) unsafe fn dlinsk(
    neq: i32,
    y: *mut f64,
    t: *mut f64,
    yprime: *mut f64,
    savr: *mut f64,
    cj: *mut f64,
    tscale: *mut f64,
    p: *mut f64,
    pnrm: *mut f64,
    wt: *mut f64,
    sqrtn: *mut f64,
    rsqrtn: *mut f64,
    lsoff: i32,
    stptol: *mut f64,
    iret: *mut i32,
    res: ResFn,
    ires: *mut i32,
    psol: PsolFn,
    _wm: *mut f64,
    iwm: *mut i32,
    _rhok: *mut f64,
    fnrm: *mut f64,
    icopt: i32,
    id: *mut i32,
    wp: *mut f64,
    iwp: *mut i32,
    r: *mut f64,
    eplin: *mut f64,
    ynew: *mut f64,
    ypnew: *mut f64,
    pwk: *mut f64,
    icnflg: i32,
    icnstr: *mut i32,
    rlx: *mut f64,
    rpar: *mut f64,
    ipar: *mut i32,
) {
    const ALPHA: f64 = 1e-4;
    let kprin = at!(iwm, 31);
    let f1nrm = *fnrm * *fnrm / 2.0;
    let mut ratio = 1.0f64;
    if kprin >= 2 {
        xerrwd("------ IN ROUTINE DLINSK-- PNRM = (R1)", 921, 0, 0, 0, 0, 1, *pnrm, 0.0);
    }
    let mut tau = *pnrm;
    let mut rl = 1.0f64;

    if icnflg != 0 {
        loop {
            dyypnw(neq, y, yprime, *cj, rl, p, icopt, id, ynew, ypnew);
            let mut ivar = 0i32;
            dcnstr(neq, y, ynew, icnstr, &mut tau, *rlx, &mut *iret, &mut ivar);
            if *iret == 1 {
                let ratio1 = tau / *pnrm;
                ratio *= ratio1;
                for i in 1..=neq {
                    at!(p, i) *= ratio1;
                }
                *pnrm = tau;
                if kprin >= 2 {
                    xerrwd(
                        "------ CONSTRAINT VIOL., PNRM = (R1), INDEX = (I1)",
                        922, 0, 1, ivar, 0, 1, *pnrm, 0.0,
                    );
                }
                if *pnrm <= *stptol {
                    *iret = 1;
                    return;
                }
                continue;
            }
            break;
        }
    }

    let slpi = -2.0 * f1nrm * ratio;
    let rlmin = *stptol / *pnrm;
    if lsoff == 0 && kprin >= 2 {
        xerrwd("------ MIN. LAMBDA = (R1)", 923, 0, 0, 0, 0, 1, rlmin, 0.0);
    }

    loop {
        dyypnw(neq, y, yprime, *cj, rl, p, icopt, id, ynew, ypnew);
        let mut fnrmp = 0.0f64;
        let mut ier = 0i32;
        dfnrmk(
            neq, ynew, t, ypnew, savr, r, cj, tscale, wt, sqrtn, rsqrtn, res, ires, psol, 0,
            &mut ier, &mut fnrmp, eplin, wp, iwp, pwk, rpar, ipar,
        );
        at!(iwm, 12) += 1;
        if *ires >= 0 {
            at!(iwm, 21) += 1;
        }
        if *ires != 0 || ier != 0 {
            *iret = 2;
            return;
        }

        let mut accept = lsoff == 1;
        if !accept {
            let f1nrmp = fnrmp * fnrmp / 2.0;
            if kprin >= 2 {
                xerrwd("------ LAMBDA = (R1)", 924, 0, 0, 0, 0, 1, rl, 0.0);
                xerrwd(
                    "------ NORM(F1) = (R1),  NORM(F1NEW) = (R2)",
                    925, 0, 0, 0, 0, 2, f1nrm, f1nrmp,
                );
            }
            if f1nrmp > f1nrm + ALPHA * slpi * rl {
                if rl < rlmin {
                    *iret = 1;
                    return;
                }
                rl /= 2.0;
                continue;
            }
            accept = true;
        }

        if accept {
            *iret = 0;
            for i in 1..=neq {
                at!(y, i) = at!(ynew, i);
            }
            for i in 1..=neq {
                at!(yprime, i) = at!(ypnew, i);
            }
            *fnrm = fnrmp;
            if kprin >= 1 {
                xerrwd("------ LEAVING ROUTINE DLINSK, FNRM = (R1)", 926, 0, 0, 0, 0, 1, *fnrm, 0.0);
            }
            return;
        }
    }
}

/// `DNSIK` — Newton + linesearch corrector for consistent initial conditions
/// using the Krylov linear solver. Sets `*iernew`.
pub(crate) unsafe fn dnsik(
    x: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    neq: i32,
    icopt: i32,
    id: *mut i32,
    res: ResFn,
    psol: PsolFn,
    wt: *mut f64,
    rpar: *mut f64,
    ipar: *mut i32,
    savr: *mut f64,
    delta: *mut f64,
    r: *mut f64,
    yic: *mut f64,
    ypic: *mut f64,
    pwk: *mut f64,
    wm: *mut f64,
    iwm: *mut i32,
    cj: *mut f64,
    tscale: *mut f64,
    sqrtn: *mut f64,
    rsqrtn: *mut f64,
    eplin: *mut f64,
    epcon: *mut f64,
    ratemx: *mut f64,
    maxit: i32,
    stptol: *mut f64,
    icnflg: i32,
    icnstr: *mut i32,
    iernew: *mut i32,
) {
    let lsoff = at!(iwm, 35);
    let mut m = 0i32;
    let mut rate = 1.0f64;
    let lwp = at!(iwm, 29);
    let liwp = at!(iwm, 30);
    let mut rlx = 0.4f64;

    for i in 1..=neq {
        at!(savr, i) = at!(delta, i);
    }

    let mut ires = 0i32;
    let mut ier = 0i32;
    let mut fnrm = 0.0f64;
    dfnrmk(
        neq, y, x, yprime, savr, r, cj, tscale, wt, sqrtn, rsqrtn, res, &mut ires, psol, 1,
        &mut ier, &mut fnrm, eplin, wm.offset((lwp - 1) as isize), iwm.offset((liwp - 1) as isize),
        pwk, rpar, ipar,
    );
    at!(iwm, 21) += 1;
    if ier != 0 {
        *iernew = 3;
        return;
    }
    if fnrm <= *epcon {
        return;
    }
    let fnrm0 = fnrm;

    let mut iret = 0i32;
    let mut iersl = 0i32;
    loop {
        at!(iwm, 19) += 1;
        let mut rhok = 0.0f64;
        dslvk(
            neq, y, x, yprime, savr, delta, wt, wm, iwm, res, &mut ires, psol, &mut iersl, cj,
            eplin, sqrtn, rsqrtn, &mut rhok, rpar, ipar,
        );
        if ires != 0 || iersl != 0 {
            *iernew = if ires <= -2 || iersl < 0 {
                -1
            } else if ires == 0 && iersl == 1 && m >= 2 && rate < 1.0 {
                1
            } else {
                3
            };
            return;
        }
        let mut delnrm = ddwnrm(neq, delta, wt, rpar, ipar);
        if delnrm == 0.0 {
            return;
        }
        let oldfnm = fnrm;
        dlinsk(
            neq, y, x, yprime, savr, cj, tscale, delta, &mut delnrm, wt, sqrtn, rsqrtn, lsoff,
            stptol, &mut iret, res, &mut ires, psol, wm, iwm, &mut rhok, &mut fnrm, icopt, id,
            wm.offset((lwp - 1) as isize), iwm.offset((liwp - 1) as isize), r, eplin, yic, ypic,
            pwk, icnflg, icnstr, &mut rlx, rpar, ipar,
        );
        rate = fnrm / oldfnm;
        if iret != 0 {
            *iernew = if ires <= -2 || iersl < 0 {
                -1
            } else if ires == 0 && iersl == 1 && m >= 2 && rate < 1.0 {
                1
            } else {
                3
            };
            return;
        }
        if fnrm <= *epcon {
            return;
        }
        m += 1;
        if m >= maxit {
            *iernew = if rate <= *ratemx || fnrm <= fnrm0 * 0.1 { 1 } else { 2 };
            return;
        }
        for i in 1..=neq {
            at!(delta, i) = at!(savr, i);
        }
    }
}
