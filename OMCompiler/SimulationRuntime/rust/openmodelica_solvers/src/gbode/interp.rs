//! Interpolation of the integrator's step onto the output grid / event times,
//! a port of C's `gbode_util.c`.

use super::conf::Interpolation;
use super::tableau::Tableau;
use crate::gbode::math::abs;

/// C's `GBODE_EPSILON` (`gbode_util.c`).
pub(super) const GBODE_EPSILON: f64 = f64::EPSILON;

fn copy_over(f: &mut [f64], src: &[f64], idx: Option<&[usize]>, n_states: usize) {
    match idx {
        None => f[..n_states].copy_from_slice(&src[..n_states]),
        Some(ix) => {
            for &i in ix {
                f[i] = src[i];
            }
        }
    }
}

/// C's `linear_interpolation`.
#[allow(clippy::too_many_arguments)]
pub(super) fn linear(
    ta: f64,
    fa: &[f64],
    tb: f64,
    fb: &[f64],
    t: f64,
    f: &mut [f64],
    idx: Option<&[usize]>,
    n_states: usize,
) {
    if abs(tb - ta) <= GBODE_EPSILON {
        copy_over(f, fb, idx, n_states);
        return;
    }
    let lambda = (t - ta) / (tb - ta);
    let (h0, h1) = (1.0 - lambda, lambda);
    apply(f, idx, n_states, |i| h0 * fa[i] + h1 * fb[i]);
}

/// C's `hermite_interpolation`.
#[allow(clippy::too_many_arguments)]
pub(super) fn hermite(
    ta: f64,
    fa: &[f64],
    dfa: &[f64],
    tb: f64,
    fb: &[f64],
    dfb: &[f64],
    t: f64,
    f: &mut [f64],
    idx: Option<&[usize]>,
    n_states: usize,
) {
    if abs(tb - ta) <= GBODE_EPSILON {
        copy_over(f, fb, idx, n_states);
        return;
    }
    let tt = (t - ta) / (tb - ta);
    let h00 = (1.0 + 2.0 * tt) * (1.0 - tt) * (1.0 - tt);
    let h10 = (tb - ta) * tt * (1.0 - tt) * (1.0 - tt);
    let h01 = (3.0 - 2.0 * tt) * tt * tt;
    let h11 = (tb - ta) * (tt - 1.0) * tt * tt;
    apply(f, idx, n_states, |i| h00 * fa[i] + h10 * dfa[i] + h01 * fb[i] + h11 * dfb[i]);
}

/// C's `hermite_interpolation_b` (only the right derivative is known).
#[allow(clippy::too_many_arguments)]
pub(super) fn hermite_b(
    ta: f64,
    fa: &[f64],
    tb: f64,
    fb: &[f64],
    dfb: &[f64],
    t: f64,
    f: &mut [f64],
    idx: Option<&[usize]>,
    n_states: usize,
) {
    if abs(tb - ta) <= GBODE_EPSILON {
        copy_over(f, fb, idx, n_states);
        return;
    }
    let tat = ta - t;
    let tbt = tb - t;
    let tbta = tb - ta;
    let h00 = tbt * tbt / (tbta * tbta);
    let h01 = tat * (tat - tbt) / (tbta * tbta);
    let h11 = tat * tbt / tbta;
    apply(f, idx, n_states, |i| h00 * fa[i] + h01 * fb[i] + h11 * dfb[i]);
}

/// C's `hermite_interpolation_a` (only the left derivative is known).
#[allow(clippy::too_many_arguments)]
pub(super) fn hermite_a(
    ta: f64,
    fa: &[f64],
    dfa: &[f64],
    tb: f64,
    fb: &[f64],
    t: f64,
    f: &mut [f64],
    idx: Option<&[usize]>,
    n_states: usize,
) {
    if abs(tb - ta) <= GBODE_EPSILON {
        copy_over(f, fb, idx, n_states);
        return;
    }
    let tat = ta - t;
    let tbt = tb - t;
    let tbta = tb - ta;
    let h01 = tat * tat / (tbta * tbta);
    let h00 = 1.0 - h01;
    let h10 = -tat * tbt / tbta;
    apply(f, idx, n_states, |i| h00 * fa[i] + h01 * fb[i] + h10 * dfa[i]);
}

fn apply(f: &mut [f64], idx: Option<&[usize]>, n_states: usize, mut g: impl FnMut(usize) -> f64) {
    match idx {
        None => {
            for i in 0..n_states {
                f[i] = g(i);
            }
        }
        Some(ix) => {
            for &i in ix {
                f[i] = g(i);
            }
        }
    }
}

/// C's `gb_interpolation`: interpolate the accepted step `[ta, tb]` at `t`.
/// `x`/`k` are the stage values of the step the dense output formula needs.
#[allow(clippy::too_many_arguments)]
pub(super) fn interpolate(
    method: Interpolation,
    ta: f64,
    fa: &[f64],
    dfa: &[f64],
    tb: f64,
    fb: &[f64],
    dfb: &[f64],
    t: f64,
    f: &mut [f64],
    idx: Option<&[usize]>,
    n_states: usize,
    tableau: &Tableau,
    b_dt: &mut [f64],
    k: &[f64],
) {
    if tb == ta || abs(tb - ta) < GBODE_EPSILON * (abs(tb) + abs(ta)) {
        copy_over(f, fa, idx, n_states);
        return;
    }
    match method {
        Interpolation::Lin => linear(ta, fa, tb, fb, t, f, idx, n_states),
        Interpolation::DenseOutput | Interpolation::DenseOutputErrCtrl
            if tableau.with_dense_output =>
        {
            tableau.dense_out(b_dt, fa, k, (t - ta) / (tb - ta), tb - ta, f, idx, n_states);
        }
        // C falls through from the dense-output cases to hermite_a when the method
        // has no dense output formula.
        Interpolation::DenseOutput
        | Interpolation::DenseOutputErrCtrl
        | Interpolation::HermiteA => hermite_a(ta, fa, dfa, tb, fb, t, f, idx, n_states),
        Interpolation::HermiteB => hermite_b(ta, fa, tb, fb, dfb, t, f, idx, n_states),
        Interpolation::HermiteErrCtrl | Interpolation::Hermite => {
            hermite(ta, fa, dfa, tb, fb, dfb, t, f, idx, n_states)
        }
    }
}
