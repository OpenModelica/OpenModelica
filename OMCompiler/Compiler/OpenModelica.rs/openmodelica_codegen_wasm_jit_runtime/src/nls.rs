//! Dense nonlinear solvers shared by every `SES_NONLINEAR` system. `rt_solve_nls`
//! (the wasm entry point) bridges the model `residual`/`load` pair to
//! [`minpack::hybrj`] (analytic Jacobian) or [`minpack::hybrd`] (numeric), with
//! [`newton_solve`] and [`lm_solve`] as fallbacks.

use alloc::vec;

use crate::solvers::Nls;
use core::sync::atomic::{AtomicU32, Ordering};

use crate::{
    load_f64, load_u32, rt_alloc, rt_free, stat_inc, store_f64, store_u32, STAT_NLS_FAIL,
    STAT_NLS_ACCEPT, STAT_NLS_GUESS_HIT, STAT_NLS_ITER, STAT_NLS_JAC, STAT_NLS_NEWTON_FAIL,
    STAT_NLS_RES, STAT_NLS_RETRY, STAT_NLS_SOLVE, STAT_NLS_STORE_BACK,
};

/// C's `EVAL_CONTEXT` (`util/context.h`), set by the driver. `updateInitialGuessDB`
/// records only for `ODE`/`ALGEBRAIC`/`EVENTS`; a Jacobian assembly evaluates at
/// perturbed states. `ALGEBRAIC` is what C leaves standing outside a `setContext`
/// region, so output points and event updates do record.
pub const CONTEXT_ODE: u32 = 1;
pub const CONTEXT_ALGEBRAIC: u32 = 2;
pub const CONTEXT_EVENTS: u32 = 3;
pub const CONTEXT_JACOBIAN: u32 = 4;

static EVAL_CONTEXT: AtomicU32 = AtomicU32::new(CONTEXT_ALGEBRAIC);

/// Address of the evaluation context, so the driver marks a context with a store
/// rather than a wasm call per evaluation.
#[unsafe(no_mangle)]
pub extern "C" fn rt_context_addr() -> u32 {
    &EVAL_CONTEXT as *const AtomicU32 as u32
}

fn context_stores_guess() -> bool {
    matches!(
        EVAL_CONTEXT.load(Ordering::Relaxed),
        CONTEXT_ODE | CONTEXT_ALGEBRAIC | CONTEXT_EVENTS
    )
}

/// Recoverable-assert state (C's `ERROR_NONLINEARSOLVER`). While `NLS_DEPTH` > 0 a
/// failed model `assert()` records itself in `NLS_ASSERT_HIT` and returns instead of
/// trapping; `eval` then turns that trial into a huge residual so the solver backs off.
static NLS_DEPTH: AtomicU32 = AtomicU32::new(0);
static NLS_ASSERT_HIT: AtomicU32 = AtomicU32::new(0);

/// Whether the last residual evaluation hit a recoverable model assert.
pub(crate) fn assert_hit() -> bool {
    NLS_ASSERT_HIT.load(Ordering::Relaxed) != 0
}

/// Model side (emitted by `emit_assert`): is a failed assert currently recoverable
/// (i.e. inside a nonlinear-solver residual)? Non-zero → the model records the
/// assert via [`rt_nls_note_assert`] and bails out instead of trapping.
#[unsafe(no_mangle)]
pub extern "C" fn rt_nls_recovering() -> i32 {
    (NLS_DEPTH.load(Ordering::Relaxed) > 0) as i32
}

/// Model side: flag that a recoverable assert fired at the current trial point.
#[unsafe(no_mangle)]
pub extern "C" fn rt_nls_note_assert() {
    NLS_ASSERT_HIT.store(1, Ordering::Relaxed);
}

/// Build the Jacobian-assemble closure used by both kinsol and newton sparse paths.
fn make_assemble(
    n: usize,
    x_ptr: u32,
    sim_data: u32,
    jac_idx: u32,
    val_ptr: u32,
) -> impl FnMut(&[f64], &mut [f64]) {
    move |xs: &[f64], vals: &mut [f64]| {
        let jacf: extern "C" fn(u32, u32, u32) = unsafe { core::mem::transmute(jac_idx as usize) };
        for i in 0..n {
            unsafe { store_f64(x_ptr + (i * 8) as u32, xs[i]) };
        }
        NLS_DEPTH.fetch_add(1, Ordering::Relaxed);
        jacf(sim_data, x_ptr, val_ptr);
        NLS_DEPTH.fetch_sub(1, Ordering::Relaxed);
        NLS_ASSERT_HIT.store(0, Ordering::Relaxed);
        for (k, v) in vals.iter_mut().enumerate() {
            *v = unsafe { load_f64(val_ptr + (k * 8) as u32) };
        }
    }
}


/// sqrt(DBL_EPSILON): the classic forward-difference relative step.
const SQRT_EPS: f64 = 1.4901161193847656e-08;
/// `sqrt(DBL_EPSILON*2e1)`, the step `getNumericalJacobianHomotopy` uses. 4.5×
/// `SQRT_EPS`: too small a step costs Newton iterations to FD noise.
const FD_DELTA: f64 = 6.664001874625056e-08;
/// Newton/LM convergence tolerance: stop once a residual / step measure drops below.
const NEWTON_EPS: f64 = 1.0e-6;
/// C's `newtonFTol`/`newtonXTol` (nonlinearSolverHomotopy.c). `newton_solve`
/// mirrors C's residual-gated convergence: a step-stall counts as success only
/// when the residual is also small (`< NEWTON_FTOL*1e3`), else it fails so the
/// homotopy globaliser engages instead of accepting a non-root.
const NEWTON_FTOL: f64 = 1.0e-12;
const NEWTON_XTOL: f64 = 1.0e-12;
const MAX_ITER: i32 = 100;
/// Line-search damping floor (2^-10): below this, keep the small step and let the
/// outer iteration retry (or hit the iteration limit → recoverable failure).
const LAMBDA_MIN: f64 = 9.765625e-4;

/// Euclidean norm (C's `enorm_`). NaN propagates, so a diverged residual falls
/// through every `< eps` test to the iteration-limit failure.
fn enorm(v: &[f64]) -> f64 {
    let mut s = 0.0;
    for &x in v {
        s += x * x;
    }
    libm::sqrt(s)
}

/// Solve the dense `n`×`n` system `A x = b` in place (`A` column-major, `b ← x`).
/// Returns `true` on success, `false` on a singular/failed factorization (in
/// which case `b` is unchanged). Shared by [`newton_solve`] and `rt_linsolve`.
pub(crate) fn lu_solve(a: &[f64], b: &mut [f64], n: usize) -> bool {
    use nalgebra::{DMatrix, DVector};
    let am = DMatrix::<f64>::from_column_slice(n, n, a);
    let bv = DVector::<f64>::from_column_slice(b);
    match am.lu().solve(&bv) {
        Some(x) => {
            b.copy_from_slice(x.as_slice());
            true
        }
        None => false,
    }
}

/// Total-pivot fallback for a singular / rank-deficient `A x = b`, a port of C's
/// `solveSystemWithTotalPivotSearchLS`. Returns `true` (with `b ← x`) for a
/// consistent system, picking the same particular solution C does; `false` only
/// when the system is inconsistent. `A` is column-major `n`×`n`.
pub(crate) fn total_pivot_solve(a: &[f64], b: &mut [f64], n: usize) -> bool {
    let m = n + 1;
    // Ab: n×(n+1) column-major; first n columns are A, the last is -b.
    let mut ab = vec![0.0f64; n * m];
    ab[..n * n].copy_from_slice(&a[..n * n]);
    for i in 0..n {
        ab[n * n + i] = -b[i];
    }
    let mut ind_row: alloc::vec::Vec<usize> = (0..n).collect();
    let mut ind_col: alloc::vec::Vec<usize> = (0..m).collect();
    let mut rank = n;

    for i in 0..n {
        let mut abs_max = ab[ind_row[i] + ind_col[i] * n].abs();
        let (mut p_row, mut p_col) = (i, i);
        for r in i..n {
            for c in i..n {
                let v = ab[ind_row[r] + ind_col[c] * n].abs();
                if v > abs_max {
                    abs_max = v;
                    p_row = r;
                    p_col = c;
                }
            }
        }
        if abs_max < f64::EPSILON {
            rank = i;
            break;
        }
        ind_row.swap(i, p_row);
        ind_col.swap(i, p_col);
        let piv = ab[ind_row[i] + ind_col[i] * n];
        for k in (i + 1)..n {
            let h = -ab[ind_row[k] + ind_col[i] * n] / piv;
            for j in (i + 1)..m {
                ab[ind_row[k] + ind_col[j] * n] += h * ab[ind_row[i] + ind_col[j] * n];
            }
            ab[ind_row[k] + ind_col[i] * n] = 0.0;
        }
    }

    let mut x = vec![0.0f64; m];
    for i in (0..n).rev() {
        if i >= rank {
            if ab[ind_row[i] + n * n].abs() > 1e-12 {
                return false;
            }
            x[ind_col[i]] = 0.0;
        } else {
            let mut xi = -ab[ind_row[i] + n * n];
            for j in ((i + 1)..n).rev() {
                xi -= ab[ind_row[i] + ind_col[j] * n] * x[ind_col[j]];
            }
            x[ind_col[i]] = xi / ab[ind_row[i] + ind_col[i] * n];
        }
    }
    b.copy_from_slice(&x[..n]);
    true
}

/// Over-determined total-pivot linear solver, C's `solveSystemWithTotalPivotSearch`
/// (`nonlinearSolverHomotopy.c`). `a` is an `n×(n+1)` column-major matrix
/// (`a[row + col*n]`); the last column is the right-hand side. With `pos < 0` it
/// solves the homogeneous `n×(n+1)` system for the null vector (tangent), setting
/// the freest coordinate to 1 and returning its index in `pos`. With `pos >= 0`
/// that coordinate is fixed (its column treated as the RHS). Writes the length
/// `n+1` solution into `x`. Returns `0` on success, `-1` if under-determined.
fn total_pivot_augmented(n: usize, x: &mut [f64], a: &mut [f64], pos: &mut i32) -> i32 {
    let m = n + 1;
    let mut n_pivot = n;
    let mut rank = n;
    let mut ind_row: alloc::vec::Vec<usize> = (0..n).collect();
    let mut ind_col: alloc::vec::Vec<usize> = (0..m).collect();
    if *pos >= 0 {
        let p = *pos as usize;
        ind_col[n] = p;
        ind_col[p] = n;
    } else {
        n_pivot = n + 1;
    }
    for i in 0..n {
        // Total pivot over rows [i,n) and columns [i,n_pivot).
        let mut abs_max = a[ind_row[i] + ind_col[i] * n].abs();
        let (mut p_row, mut p_col) = (i, i);
        for r in i..n {
            for c in i..n_pivot {
                let v = a[ind_row[r] + ind_col[c] * n].abs();
                if v > abs_max {
                    abs_max = v;
                    p_row = r;
                    p_col = c;
                }
            }
        }
        if abs_max < f64::EPSILON {
            rank = i;
            break;
        }
        ind_row.swap(i, p_row);
        ind_col.swap(i, p_col);
        let piv = a[ind_row[i] + ind_col[i] * n];
        for k in (i + 1)..n {
            let h = -a[ind_row[k] + ind_col[i] * n] / piv;
            for j in (i + 1)..m {
                a[ind_row[k] + ind_col[j] * n] += h * a[ind_row[i] + ind_col[j] * n];
            }
            a[ind_row[k] + ind_col[i] * n] = 0.0;
        }
    }
    let mut det = 1.0;
    for k in 0..n {
        det *= a[ind_row[k] + ind_col[k] * n];
    }
    if det.is_nan() {
        return -1;
    }
    for i in (0..n).rev() {
        if i >= rank {
            if a[ind_row[i] + ind_col[n] * n].abs() > 1e-6 {
                return -1;
            }
            x[ind_col[i]] = 0.0;
        } else {
            let mut xi = -a[ind_row[i] + ind_col[n] * n];
            for j in ((i + 1)..n).rev() {
                xi -= a[ind_row[i] + ind_col[j] * n] * x[ind_col[j]];
            }
            x[ind_col[i]] = xi / a[ind_row[i] + ind_col[i] * n];
        }
    }
    x[ind_col[n]] = 1.0;
    if *pos < 0 {
        *pos = ind_col[n] as i32;
    }
    0
}

/// Row-equilibrate an `n×(n+1)` matrix (C's `scaleMatrixRows`): divide each row by
/// the max magnitude over its first `n` columns (the Jacobian part), 1 if all zero.
fn scale_matrix_rows_aug(n: usize, a: &mut [f64]) {
    let m = n + 1;
    let mut rows_max = vec![0.0f64; n];
    for j in 0..n {
        for i in 0..n {
            let v = a[i + j * n].abs();
            if v > rows_max[i] {
                rows_max[i] = v;
            }
        }
    }
    for r in rows_max.iter_mut() {
        if *r <= 0.0 {
            *r = 1.0;
        }
    }
    for j in 0..m {
        for i in 0..n {
            a[i + j * n] /= rows_max[i];
        }
    }
}

/// Arc-length homotopy continuation, a port of C's `homotopyAlgorithm`
/// (`nonlinearSolverHomotopy.c`): Newton homotopy `H(y) = F(x) − (1−λ)·F(x0)` tracked
/// λ: 0→1 by a tangent predictor + fixed-coordinate Newton corrector with adaptive
/// step `tau`. Follows folds a fixed-λ homotopy can't. `x` = guess in / λ=1 root out.
fn homotopy_solve(
    n: usize,
    x: &mut [f64],
    nominal: &[f64],
    start_dir: f64,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    const TAU_START: f64 = 0.2;
    const TAU_MAX: f64 = 10.0;
    const TAU_MIN: f64 = 1.0e-4;
    const H_EPS: f64 = 1.0e-5;
    const ADAPT_BEND: f64 = 0.5;
    const TAU_DEC: f64 = 10.0;
    const TAU_DEC_PRED: f64 = 2.0;
    const TAU_INC: f64 = 2.0;
    const TAU_INC_THRESH: f64 = 10.0;
    const MAX_NEWTON: usize = 20;
    const MAX_TRIES: i32 = 10;
    const MAX_LAMBDA_STEPS: usize = 1000;
    let m = n + 1;

    // xScaling[i] = max(nominal[i], |xStart[i]|) from the original start values.
    let mut xscaling = vec![0.0f64; m];
    for i in 0..n {
        xscaling[i] = nominal[i].abs().max(x[i].abs());
        if xscaling[i] <= 0.0 {
            xscaling[i] = 1.0;
        }
    }
    xscaling[m - 1] = 1.0;

    // Regular-initial-point search (C solveHomotopy): the raw start may sit on a
    // singularity (a spring loop seeds s_rel=0, where the residual and Jacobian
    // blow up and the homotopy path becomes pathological). Perturb x0 by
    // xScaling·(i/n)·{0, 1%, 10%} until f(x0) is finite and moderate.
    let xstart = x[..n].to_vec();
    let mut x0v = xstart.clone();
    let mut fx0 = vec![0.0f64; n];
    for tries in 0..=2 {
        let pert = match tries {
            1 => 0.01,
            2 => 0.10,
            _ => 0.0,
        };
        for i in 0..n {
            x0v[i] = xstart[i] + xscaling[i] * (i as f64 / n as f64) * pert;
        }
        eval(&x0v, &mut fx0);
        if fx0.iter().all(|v| v.is_finite() && v.abs() < 1e6) {
            break;
        }
    }

    // Homotopy function H and its FD Jacobian, both over the augmented y = [x, λ].
    let fx0_ref = &fx0;
    let h_function = |y: &[f64], hvec: &mut [f64], fx: &mut [f64], eval: &mut dyn FnMut(&[f64], &mut [f64])| {
        eval(&y[..n], fx);
        let lam = y[n];
        for i in 0..n {
            hvec[i] = fx[i] - (1.0 - lam) * fx0_ref[i];
        }
    };

    let mut y0 = vec![0.0f64; m];
    y0[..n].copy_from_slice(&x0v);
    let mut prev_tangent = vec![0.0f64; m];
    prev_tangent[m - 1] = start_dir;

    let mut hvec = vec![0.0f64; n];
    let mut fx = vec![0.0f64; n];
    h_function(&y0, &mut hvec, &mut fx, eval);

    let mut tau = TAU_START;
    let mut iter: i32 = 0;
    let mut num_steps = 0usize;
    let mut initial_step = true;
    let mut tangent = vec![0.0f64; m]; // dy0
    let mut hjac = vec![0.0f64; n * m];
    let mut y1 = vec![0.0f64; m];
    let mut yt = vec![0.0f64; m];
    let mut dy1 = vec![0.0f64; m];
    let mut f2 = vec![0.0f64; n];
    let mut res_scaling = vec![1.0f64; n];
    let mut hvec_scaled = vec![0.0f64; n];

    let mut tangent_pos: i32 = -1;

    let delta_h = libm::sqrt(f64::EPSILON * 20.0);
    // Build the scaled n×(n+1) homotopy Jacobian at `y` (FD, fx = F(x) base).
    let build_jac = |y: &[f64],
                     fbase: &[f64],
                     hjac: &mut [f64],
                     f2: &mut [f64],
                     xscaling: &[f64],
                     eval: &mut dyn FnMut(&[f64], &mut [f64])| {
        let mut xp = y[..n].to_vec();
        for j in 0..n {
            let xsave = xp[j];
            let hh = delta_h * (xsave.abs() + 1.0);
            xp[j] = xsave + hh;
            let inv = xscaling[j] / hh;
            eval(&xp, f2);
            for i in 0..n {
                hjac[i + j * n] = (f2[i] - fbase[i]) * inv;
            }
            xp[j] = xsave;
        }
        // The λ column (∂H/∂λ = F(x0)) is filled in by the caller.
    };

    while y0[n] < 1.0 {
        if iter >= MAX_TRIES || y0[n] < -1.0 || num_steps >= MAX_LAMBDA_STEPS {
            return false;
        }

        // ---- Predictor: tangent vector (only after an accepted step) ----
        if iter == 0 {
            build_jac(&y0, &fx, &mut hjac, &mut f2, &xscaling, eval);
            for i in 0..n {
                hjac[i + n * n] = fx0[i]; // ∂H/∂λ = F(x0)
            }
            scale_matrix_rows_aug(n, &mut hjac);
            tangent_pos = -1;
            if total_pivot_augmented(n, &mut tangent, &mut hjac, &mut tangent_pos) == -1 {
                return false;
            }
            for i in 0..m {
                tangent[i] *= xscaling[i];
            }
            // Direction: keep an acute angle with the previous tangent.
            let mut dot = 0.0;
            for i in 0..m {
                dot += tangent[i] * prev_tangent[i];
            }
            if dot < 0.0 || (dot.abs() < f64::EPSILON && start_dir == -1.0 && initial_step) {
                for t in tangent.iter_mut() {
                    *t = -*t;
                }
            }
            // Cap tau so λ + tau·dλ ≤ 1.
            if tangent[n].abs() > 1e-8 {
                tau = tau.min((1.0 - y0[n]) / tangent[n].abs());
            }
        }

        // Predictor point y1 = y0 + tau·tangent (shrink tau on a function assert).
        let mut assert_ok = false;
        loop {
            for i in 0..m {
                y1[i] = y0[i] + tau * tangent[i];
            }
            h_function(&y1, &mut hvec, &mut fx, eval);
            if hvec.iter().all(|v| v.abs() < 1e30) {
                assert_ok = true;
                break;
            }
            tau /= TAU_DEC_PRED;
            if tau <= TAU_MIN {
                break;
            }
        }
        if !assert_ok {
            return false;
        }
        yt.copy_from_slice(&y1);

        // ---- Corrector: Newton with coordinate `pos` fixed ----
        let last_step = y1[n] >= 1.0;
        let h_eps = if last_step { NEWTON_FTOL } else { H_EPS };
        let mut pos = if last_step { n as i32 } else { tangent_pos };
        let mut step_accept = false;
        let mut corrector_ok = true;
        hvec_scaled.copy_from_slice(&hvec); // C: hvecScaled starts as hvec (unscaled)
        for _ in 0..MAX_NEWTON {
            if enorm(&hvec) < h_eps || enorm(&hvec_scaled) < h_eps {
                step_accept = true;
                break;
            }
            build_jac(&y1, &fx, &mut hjac, &mut f2, &xscaling, eval);
            for i in 0..n {
                hjac[i + n * n] = fx0[i];
            }
            // resScaling[i] = row abs-sum of the homotopy Jacobian (before fixing pos).
            for i in 0..n {
                let mut s = 0.0;
                for j in 0..m {
                    s += hjac[i + j * n].abs();
                }
                res_scaling[i] = if s > 0.0 { s } else { 1.0 };
            }
            // Fix coordinate `pos`: put the residual into its column, then solve.
            let pc = pos as usize;
            for i in 0..n {
                hjac[i + pc * n] = hvec[i];
            }
            scale_matrix_rows_aug(n, &mut hjac);
            if total_pivot_augmented(n, &mut dy1, &mut hjac, &mut pos) == -1 {
                corrector_ok = false;
                break;
            }
            dy1[pc] = 0.0;
            for i in 0..m {
                dy1[i] *= xscaling[i];
                y1[i] += dy1[i];
            }
            h_function(&y1, &mut hvec, &mut fx, eval);
            if hvec.iter().any(|v| v.abs() >= 1e30) {
                corrector_ok = false;
                break;
            }
            for i in 0..n {
                hvec_scaled[i] = hvec[i] / res_scaling[i];
            }
        }

        // ---- Step acceptance and adaptive tau via path bending ----
        let mut bend = 0.0;
        if corrector_ok {
            let mut corr = 0.0;
            let mut pred = 0.0;
            for i in 0..m {
                let c = y1[i] - yt[i];
                let p = yt[i] - y0[i];
                corr += c * c;
                pred += p * p;
            }
            let pred = libm::sqrt(pred);
            bend = if pred > 0.0 { libm::sqrt(corr) / pred } else { f64::INFINITY };
        }

        if bend > ADAPT_BEND || !step_accept {
            if corrector_ok && bend < f64::EPSILON {
                return false;
            }
            let pre_tau = tau;
            tau = TAU_MIN.max(tau / TAU_DEC);
            if tau == pre_tau {
                iter = MAX_TRIES;
            } else {
                iter += 1;
            }
        } else {
            initial_step = false;
            iter = 0;
            num_steps += 1;
            if bend < ADAPT_BEND / TAU_INC_THRESH {
                tau = TAU_MAX.min(tau * TAU_INC);
            }
            y0.copy_from_slice(&y1);
            prev_tangent.copy_from_slice(&tangent);
        }
    }
    x[..n].copy_from_slice(&y1[..n]);
    true
}

/// Newton's method with a forward-difference Jacobian and a damped (line-search)
/// step, faithful to the C runtime's `_omc_newton` (`newtonIteration.c`). `x` is
/// the entry guess in / solution out; `eval(x, r)` writes the residual `r = f(x)`.
///
/// Convergence mirrors C exactly: the iteration continues only while *all* of the
/// residual norm (`error_f`), scaled residual norm (`scaledError_f`), step norm
/// (`delta_x`), residual-change (`delta_f`), and scaled step (`delta_x_scaled`)
/// stay above `NEWTON_EPS`; it succeeds as soon as *any* drops below. This is what
/// lets a system converge when a finite-difference Jacobian floors the residual
/// above a pure `‖r‖` tolerance but the Newton step has otherwise stalled at the
/// solution. Returns `false` on a singular Jacobian or `MAX_ITER` overrun. On
/// return `x` holds the last iterate.
pub(crate) fn newton_solve(
    n: usize,
    x: &mut [f64],
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    let mut fvec = vec![0.0f64; n];
    let mut f_old = vec![0.0f64; n];
    let mut x_new = vec![0.0f64; n];
    let mut rp = vec![0.0f64; n];
    let mut dx = vec![0.0f64; n];
    let mut jac = vec![0.0f64; n * n]; // column-major

    eval(x, &mut fvec);
    let mut error_f = enorm(&fvec);
    if error_f < NEWTON_FTOL {
        return true;
    }
    f_old.copy_from_slice(&fvec);

    let mut iter = 0;
    let mut neg_steps = 0i32; // C's countNegativeSteps
    let mut small_steps = 0i32; // C's numberOfSmallSteps
    loop {
        // Jacobian columns by forward differences: J[:,col] = (f(x+h e_col) - f(x)) / h.
        for col in 0..n {
            let h = SQRT_EPS * (x[col].abs() + 1.0);
            let saved = x[col];
            x[col] = saved + h;
            eval(x, &mut rp);
            for i in 0..n {
                jac[col * n + i] = (rp[i] - fvec[i]) / h;
            }
            x[col] = saved;
        }

        // Solve J dx = fvec; x_new = x - dx (C's `x_new = x - x_increment`).
        dx.copy_from_slice(&fvec);
        if !lu_solve(&jac, &mut dx, n) {
            return false;
        }
        for i in 0..n {
            x_new[i] = x[i] - dx[i];
        }

        // Damped step: halve lambda until the residual norm improves (C damping).
        eval(&x_new, &mut fvec);
        let mut lambda = 1.0;
        while enorm(&fvec) >= error_f && lambda > LAMBDA_MIN {
            lambda *= 0.5;
            for i in 0..n {
                x_new[i] = x[i] - lambda * dx[i];
            }
            eval(&x_new, &mut fvec);
        }

        // calculatingErrors: step, residual, and their scaled variants.
        let mut d2 = 0.0;
        for i in 0..n {
            let d = x[i] - x_new[i];
            d2 += d * d;
        }
        let delta_x = libm::sqrt(d2);
        let xn = enorm(x);
        let scale = if xn > 1.0 { xn } else { 1.0 };
        let delta_x_scaled = delta_x / scale;
        let error_f_old = error_f;
        error_f = enorm(&fvec);
        // scaledError_f = ‖ fvec / resScaling ‖, resScaling[i] = max-norm of Jac row i.
        let mut se2 = 0.0;
        for i in 0..n {
            let mut row_max = 0.0f64;
            for col in 0..n {
                let a = jac[col * n + i].abs();
                if a > row_max {
                    row_max = a;
                }
            }
            let s = if row_max > 0.0 && row_max.is_finite() {
                row_max
            } else if row_max == 0.0 {
                1e-16
            } else {
                1.0
            };
            let v = fvec[i] / s;
            se2 += v * v;
        }
        let scaled_error_f = libm::sqrt(se2);

        x.copy_from_slice(&x_new);
        f_old.copy_from_slice(&fvec);

        // C's newtonAlgorithm convergence (nonlinearSolverHomotopy.c): residual-gated.
        // A vanishing step alone is NOT success — the residual must also be small,
        // else the solver reports failure so the homotopy globaliser engages instead
        // of accepting a non-root (the ThreeSprings spring-loop stall).
        neg_steps += (error_f > 10.0 * error_f_old) as i32;
        if neg_steps > 20 {
            return false;
        }
        let f_small = error_f < NEWTON_FTOL || scaled_error_f < NEWTON_FTOL;
        let x_small = delta_x < NEWTON_XTOL || delta_x_scaled < NEWTON_XTOL;
        if f_small && x_small {
            return true;
        }
        small_steps += (delta_x < NEWTON_XTOL * 100.0 || delta_x_scaled < NEWTON_XTOL * 100.0) as i32;
        if x_small || small_steps > 20 {
            // Stalled step: accept only with a small residual (C's ftol*1e3), else fail.
            return error_f < NEWTON_FTOL * 1.0e3 || scaled_error_f < NEWTON_FTOL * 1.0e3;
        }
        iter += 1;
        if iter > MAX_ITER {
            return false;
        }
    }
}

/// Levenberg–Marquardt globaliser with a forward-difference Jacobian, tried when
/// the damped Newton step stalls (a stand-in for C's hybrd / homotopy init
/// solver). It solves the Marquardt-damped normal equations
/// `(JᵀJ + λ·diag JᵀJ) dx = -Jᵀf`, adapting `λ` by whether a step reduces the
/// residual, so it converges to the same root from a poorer guess (e.g.
/// `DoublePendulumInitTip`'s initialisation). Returns `false` if the residual
/// cannot be driven below tolerance.
pub(crate) fn lm_solve(
    n: usize,
    x: &mut [f64],
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    let mut f = vec![0.0f64; n];
    let mut f_new = vec![0.0f64; n];
    let mut jac = vec![0.0f64; n * n]; // column-major
    let mut jtj = vec![0.0f64; n * n];
    let mut g = vec![0.0f64; n]; // Jᵀf
    let mut dx = vec![0.0f64; n];
    let mut x_new = vec![0.0f64; n];

    eval(x, &mut f);
    let mut nf = enorm(&f);
    if nf < NEWTON_EPS {
        return true;
    }
    let mut lambda = 1.0e-3;
    let mut iter = 0;
    loop {
        for col in 0..n {
            let h = SQRT_EPS * (x[col].abs() + 1.0);
            let saved = x[col];
            x[col] = saved + h;
            eval(x, &mut f_new);
            for i in 0..n {
                jac[col * n + i] = (f_new[i] - f[i]) / h;
            }
            x[col] = saved;
        }
        for a in 0..n {
            for b in a..n {
                let mut s = 0.0;
                for i in 0..n {
                    s += jac[a * n + i] * jac[b * n + i];
                }
                jtj[a * n + b] = s;
                jtj[b * n + a] = s;
            }
            let mut s = 0.0;
            for i in 0..n {
                s += jac[a * n + i] * f[i];
            }
            g[a] = s;
        }

        let mut accepted = false;
        for _ in 0..30 {
            let mut m = jtj.clone();
            for d in 0..n {
                let diag = jtj[d * n + d];
                m[d * n + d] = diag + lambda * if diag > 1e-12 { diag } else { 1e-12 };
            }
            for i in 0..n {
                dx[i] = -g[i];
            }
            if !lu_solve(&m, &mut dx, n) {
                lambda *= 10.0;
                if lambda > 1e14 {
                    break;
                }
                continue;
            }
            for i in 0..n {
                x_new[i] = x[i] + dx[i];
            }
            eval(&x_new, &mut f_new);
            let nf_new = enorm(&f_new);
            if nf_new < nf {
                x.copy_from_slice(&x_new);
                f.copy_from_slice(&f_new);
                nf = nf_new;
                lambda *= 0.5;
                accepted = true;
                break;
            }
            lambda *= 2.0;
            if lambda > 1e14 {
                break;
            }
        }

        if nf < NEWTON_EPS {
            return true;
        }
        if !accepted {
            return false;
        }
        iter += 1;
        if iter > MAX_ITER {
            return false;
        }
    }
}

/// [`minpack::hybrd`] run in coordinates scaled by `max(|x[i]|, nominal[i])`, so
/// the relative `xtol` resolves every variable to its own magnitude.
fn hybrd_scaled(
    n: usize,
    x: &mut [f64],
    fvec: &mut [f64],
    nominal: &[f64],
    maxfev: usize,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    let mut scale = vec![0.0f64; n];
    for i in 0..n {
        let s = x[i].abs().max(nominal[i]);
        scale[i] = if s > 0.0 { s } else { 1.0 };
    }
    for i in 0..n {
        x[i] /= scale[i];
    }
    let mut real = vec![0.0f64; n];
    let mut seval = |sx: &[f64], r: &mut [f64]| {
        for i in 0..n {
            real[i] = sx[i] * scale[i];
        }
        eval(&real, r);
    };
    let status = minpack::hybrd(&mut seval, n, x, fvec, 1e-12, maxfev, 1e-12, 100.0);
    drop(seval);
    for i in 0..n {
        x[i] *= scale[i];
    }
    nls_accept(status, fvec)
}

/// A solve succeeds when MINPACK reports convergence or the residual is already at
/// the tolerance (an exact Jacobian can reach the root before the step test fires,
/// leaving `Stalled` with a machine-zero residual).
fn nls_accept(status: minpack::Status, fvec: &[f64]) -> bool {
    status == minpack::Status::Converged || enorm(fvec) <= 1.0e-12
}

/// Residual-scaled norm (C's `xerror_scaled`): divide each residual by the row max
/// of an FD Jacobian at `x`, then take the 2-norm. Lets a solver accept a stalled
/// iterate whose residual is negligible relative to the system's own magnitudes.
fn scaled_res_norm(
    n: usize,
    x: &[f64],
    fvec: &[f64],
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> f64 {
    let mut xw = x.to_vec();
    let mut rp = vec![0.0f64; n];
    let mut scaled = vec![0.0f64; n];
    for i in 0..n {
        let mut row = 1e-16f64;
        for j in 0..n {
            let h = SQRT_EPS * (x[j].abs() + 1.0);
            let saved = xw[j];
            xw[j] = saved + h;
            eval(&xw, &mut rp);
            xw[j] = saved;
            let d = ((rp[i] - fvec[i]) / h).abs();
            if d > row {
                row = d;
            }
        }
        scaled[i] = fvec[i] / row;
    }
    enorm(&scaled)
}

/// C's `solveHybrd` (nonlinearSolverHybrd.c): numeric `hybrd` in a retry ladder. On a
/// stall it restarts from the guess with the trust-region `factor` cut tenfold
/// (100→10→1→0.1), then varies the start, rescales, then drops x-scaling. Accepts on
/// convergence or a raw/residual-scaled norm at tolerance. The small-`factor` restart
/// is what reaches the ThreeSprings physical root, where `factor=100` stalls near x0.
fn hybrd_c(
    n: usize,
    x: &mut [f64],
    nominal: &[f64],
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    const LOCAL_TOL: f64 = 1e-12;
    let maxfev = n * 10000;
    let initial_factor = 100.0f64;
    let mut factor = initial_factor;
    let guess = x.to_vec(); // C's nlsxExtrapolation (=start values at init)
    let mut xscale = vec![1.0f64; n];
    for i in 0..n {
        xscale[i] = x[i].abs().max(nominal[i]).max(1e-16);
    }
    let mut use_xscaling = true;
    let mut fvec = vec![0.0f64; n];
    let mut retries = 0i32;
    loop {
        let mut xw = vec![0.0f64; n];
        for i in 0..n {
            xw[i] = if use_xscaling { x[i] / xscale[i] } else { x[i] };
        }
        let mut real = vec![0.0f64; n];
        let mut seval = |sx: &[f64], r: &mut [f64]| {
            for i in 0..n {
                real[i] = if use_xscaling { sx[i] * xscale[i] } else { sx[i] };
            }
            eval(&real, r);
        };
        let status = minpack::hybrd(&mut seval, n, &mut xw, &mut fvec, 1e-12, maxfev, 1e-12, factor);
        drop(seval);
        for i in 0..n {
            x[i] = if use_xscaling { xw[i] * xscale[i] } else { xw[i] };
        }
        let xerror = enorm(&fvec);
        let xerror_scaled = scaled_res_norm(n, x, &fvec, eval);
        if status == minpack::Status::Converged || xerror <= LOCAL_TOL || xerror_scaled <= LOCAL_TOL {
            return true;
        }
        // C retries on info 4/5 (stall); we also escalate on the trust-region /
        // step-bound terminations, which are the same "no progress" condition here.
        let no_progress = status != minpack::Status::Converged;
        if no_progress && retries < 3 {
            x.copy_from_slice(&guess);
            factor /= 10.0;
            retries += 1;
        } else if no_progress && retries < 4 {
            for i in 0..n {
                x[i] += nominal[i] * 0.1;
            }
            factor = initial_factor;
            retries += 1;
        } else if no_progress && retries < 5 {
            x.copy_from_slice(&guess);
            for i in 0..n {
                xscale[i] = guess[i].abs().max(nominal[i]).max(1e-16);
            }
            retries += 1;
        } else if no_progress && retries < 6 {
            x.copy_from_slice(&guess);
            use_xscaling = false;
            retries += 1;
        } else {
            return false;
        }
    }
}

/// [`minpack::hybrj`] with the same scaling as [`hybrd_scaled`], using the model's
/// analytic Jacobian. `jac(x, fjac)` fills the column-major `n×n` Jacobian
/// `∂f_i/∂x_j` at the unscaled `x`; column `j` is scaled by `scale[j]`.
#[allow(clippy::too_many_arguments)]
fn hybrj_scaled(
    n: usize,
    x: &mut [f64],
    fvec: &mut [f64],
    nominal: &[f64],
    maxfev: usize,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    jac: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    let mut scale = vec![0.0f64; n];
    for i in 0..n {
        let s = x[i].abs().max(nominal[i]);
        scale[i] = if s > 0.0 { s } else { 1.0 };
    }
    for i in 0..n {
        x[i] /= scale[i];
    }
    let mut real = vec![0.0f64; n];
    let mut seval = |sx: &[f64], r: &mut [f64]| {
        for i in 0..n {
            real[i] = sx[i] * scale[i];
        }
        eval(&real, r);
    };
    let mut realj = vec![0.0f64; n];
    let mut sjac = |sx: &[f64], fj: &mut [f64]| {
        for i in 0..n {
            realj[i] = sx[i] * scale[i];
        }
        jac(&realj, fj);
        for j in 0..n {
            for i in 0..n {
                fj[i + j * n] *= scale[j];
            }
        }
    };
    let status = minpack::hybrj(&mut seval, &mut sjac, n, x, fvec, 1e-12, maxfev, 100.0);
    drop(seval);
    drop(sjac);
    for i in 0..n {
        x[i] *= scale[i];
    }
    nls_accept(status, fvec)
}

/// `-nlsLS`: which backend the linear solve inside the sparse nonlinear solver
/// runs on. C's `totalpivot`/`lapack` have no sparse implementation here, so they
/// fall to `rsparse` alongside an unlinked KLU.
fn nls_ls_backend() -> crate::solvers::Sparse {
    match crate::solvers::nls_ls() {
        crate::solvers::NlsLs::Klu => crate::solvers::Sparse::Klu,
        _ => crate::solvers::Sparse::Rsparse,
    }
}

/// Stored solutions per system; `nls_hist_bytes` in the codegen must agree. C's list
/// is unbounded and reaches 40+, but the entry `getValues` picks is never past 5.
pub(crate) const HIST_DEPTH: usize = 10;

/// C's `MINIMAL_STEP_SIZE` (`epsilon.h`): times within this count as the same time.
const MINIMAL_STEP_SIZE: f64 = 1.0e-12;

/// Storage behind C's `oldValueList`: linear memory in the solver, a `Vec` in tests.
pub(crate) trait History {
    /// Entries currently stored, newest-stored first.
    fn len(&self) -> usize;
    fn time(&self, k: usize) -> f64;
    fn value(&self, k: usize, i: usize) -> f64;
    /// Copy entry `from` onto entry `to`.
    fn shift(&mut self, from: usize, to: usize);
    /// Overwrite entry `k` and set the count to `len`.
    fn put(&mut self, k: usize, len: usize, time: f64, x: &[f64]);
}

/// Count at `count_addr`, then `HIST_DEPTH` × (time, `n` values) from `base`.
struct MemHistory {
    count_addr: u32,
    base: u32,
    n: usize,
}

impl MemHistory {
    fn entry(&self, k: usize) -> u32 {
        self.base + (k * (8 + self.n * 8)) as u32
    }
}

impl History for MemHistory {
    fn len(&self) -> usize {
        (unsafe { load_u32(self.count_addr) } as usize).min(HIST_DEPTH)
    }
    fn time(&self, k: usize) -> f64 {
        unsafe { load_f64(self.entry(k)) }
    }
    fn value(&self, k: usize, i: usize) -> f64 {
        unsafe { load_f64(self.entry(k) + 8 + (i * 8) as u32) }
    }
    fn shift(&mut self, from: usize, to: usize) {
        let (src, dst) = (self.entry(from), self.entry(to));
        for b in 0..(1 + self.n) as u32 {
            unsafe { store_f64(dst + b * 8, load_f64(src + b * 8)) };
        }
    }
    fn put(&mut self, k: usize, len: usize, time: f64, x: &[f64]) {
        let at = self.entry(k);
        unsafe { store_f64(at, time) };
        for (i, v) in x.iter().enumerate() {
            unsafe { store_f64(at + 8 + (i * 8) as u32, *v) };
        }
        unsafe { store_u32(self.count_addr, len as u32) };
    }
}

/// Which stored solutions C's `getValues` builds the guess from.
#[derive(Debug, PartialEq)]
pub(crate) struct Pick {
    /// The first entry at or older than the requested time; `None` = empty list.
    pub old: Option<usize>,
    /// The entry stored just before `old`, to extrapolate with.
    pub old2: Option<usize>,
    /// `old`'s time is the requested time: take it verbatim, no extrapolation.
    pub exact: bool,
}

/// `getValues`' search: the first entry at or older than `time`, or the oldest.
/// A hit within `MINIMAL_STEP_SIZE` is taken verbatim — `b+f*(a-b)` lands an ULP
/// away even at `f == 1`, which costs a Newton iteration on a linear residual.
pub(crate) fn history_pick(h: &dyn History, time: f64) -> Pick {
    for k in 0..h.len() {
        if libm::fabs(h.time(k) - time) <= MINIMAL_STEP_SIZE {
            return Pick { old: Some(k), old2: None, exact: true };
        }
        if h.time(k) < time {
            return Pick { old: Some(k), old2: (k + 1 < h.len()).then_some(k + 1), exact: false };
        }
    }
    Pick { old: h.len().checked_sub(1), old2: None, exact: false }
}

/// `extrapolateValues`; leaves `guess` alone when the list is empty.
pub(crate) fn history_guess(h: &dyn History, pick: &Pick, time: f64, guess: &mut [f64]) {
    match (pick.old, pick.old2) {
        (Some(a), Some(b)) => {
            let (t_a, t_b) = (h.time(a), h.time(b));
            let f = (time - t_b) / (t_a - t_b);
            for (i, g) in guess.iter_mut().enumerate() {
                let (va, vb) = (h.value(a, i), h.value(b, i));
                *g = if t_a == t_b || va == vb { va } else { vb + f * (va - vb) };
            }
        }
        (Some(a), None) => {
            for (i, g) in guess.iter_mut().enumerate() {
                *g = h.value(a, i);
            }
        }
        (None, _) => {}
    }
}

/// `addListElement`: push to the front, or replace it when the times match. Unlike
/// C's, the oldest entry falls off at [`HIST_DEPTH`].
pub(crate) fn history_store(h: &mut dyn History, time: f64, x: &[f64]) {
    let count = h.len();
    if count > 0 && libm::fabs(h.time(0) - time) <= MINIMAL_STEP_SIZE {
        h.put(0, count, time, x);
        return;
    }
    for k in (0..count.min(HIST_DEPTH - 1)).rev() {
        h.shift(k, k + 1);
    }
    h.put(0, (count + 1).min(HIST_DEPTH), time, x);
}

/// Row abs-sum of `J` (`matVecMultAbsBB` + `vecMakeFinite`). A zero row stays 0,
/// which `scaled_sq` reads as unscaled, as C's `vecDivScaling` does.
fn row_scaling(n: usize, jac: &[f64], res_scaling: &mut [f64]) {
    for i in 0..n {
        let mut s = 0.0;
        for j in 0..n {
            s += jac[j * n + i].abs();
        }
        res_scaling[i] = if s.is_finite() { s } else { 1.0 };
    }
}

/// `‖v / resScaling‖²` (C's `vecDivScaling` + `vec2NormSqrd`).
fn scaled_sq(n: usize, v: &[f64], res_scaling: &[f64]) -> f64 {
    let mut s = 0.0;
    for i in 0..n {
        let d = res_scaling[i].abs();
        let t = if d > 0.0 { v[i] / d } else { v[i] };
        s += t * t;
    }
    s
}

/// C's `newtonAlgorithm` (`nonlinearSolverHomotopy.c`): damped Newton with a
/// Numerical-Recipes cubic line search and two-tier residual-gated convergence.
/// Analytic Jacobian when `has_jac`, else FD; `x` = guess in / last iterate out.
/// Returns `(root found, last residual eval was at the returned `x`)`. `f0` is the
/// residual at the incoming `x` when the caller already has it.
fn newton_c(
    n: usize,
    x: &mut [f64],
    nominal: &[f64],
    f0: Option<&[f64]>,
    res_scaling: &mut [f64],
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    jaceval: &mut dyn FnMut(&[f64], &mut [f64]),
    has_jac: bool,
) -> (bool, bool) {
    const ALPHA: f64 = 1.0e-1;
    const LAMBDA_MIN_C: f64 = 1.0e-4;
    let ftol_sq = NEWTON_FTOL * NEWTON_FTOL;
    let xtol_sq = NEWTON_XTOL * NEWTON_XTOL;
    let nsq = |v: &[f64]| -> f64 {
        let e = enorm(v);
        e * e
    };

    let mut xscaling = vec![1.0f64; n];
    for i in 0..n {
        xscaling[i] = nominal[i].abs().max(x[i].abs());
        if xscaling[i] <= 0.0 {
            xscaling[i] = 1.0;
        }
    }

    let mut fvec = vec![0.0f64; n];
    let mut x1 = vec![0.0f64; n];
    let mut rp = vec![0.0f64; n];
    let mut step = vec![0.0f64; n]; // C's dy0 (the full Newton step −J⁻¹f)
    let mut jac = vec![0.0f64; n * n];

    match f0 {
        Some(f) => fvec.copy_from_slice(f),
        None => eval(x, &mut fvec),
    }
    let mut error_f_sqrd = nsq(&fvec);

    // The Jacobian is w.r.t. *scaled* unknowns: both of C's paths scale column `j` by
    // `xScaling[j]`, and the step is unscaled after the solve. `resScaling` is a row
    // abs-sum of that column-equilibrated matrix, so the scaling is part of the
    // convergence test, not just the rounding.
    //
    // The first one comes from C's `solveHomotopy` pre-phase and the loop re-forms it
    // at its *bottom*, so the iteration that converges never pays for a Jacobian.
    let form_jac = |x: &mut [f64], fvec: &[f64], jac: &mut [f64], rp: &mut [f64],
                    xscaling: &[f64],
                    eval: &mut dyn FnMut(&[f64], &mut [f64]),
                    jaceval: &mut dyn FnMut(&[f64], &mut [f64])| {
        if has_jac {
            jaceval(x, jac);
            for col in 0..n {
                for i in 0..n {
                    jac[col * n + i] *= xscaling[col];
                }
            }
        } else {
            for col in 0..n {
                let h = FD_DELTA * (x[col].abs() + 1.0);
                let saved = x[col];
                x[col] = saved + h;
                eval(x, rp);
                let inv = xscaling[col] / h;
                for i in 0..n {
                    jac[col * n + i] = (rp[i] - fvec[i]) * inv;
                }
                x[col] = saved;
            }
        }
    };
    form_jac(x, &fvec, &mut jac, &mut rp, &xscaling, eval, jaceval);
    row_scaling(n, &jac, res_scaling);
    let mut error_f_sqrd_scaled = scaled_sq(n, &fvec, res_scaling);

    let mut iter = 0i32;
    let mut neg_steps = 0i32;
    let mut small_steps = 0i32;
    loop {
        stat_inc(STAT_NLS_ITER);
        // Newton step: solve J·d = f in scaled unknowns, unscale (C's
        // `vecMultScaling`), then step = −d (so x1 = x + step).
        step.copy_from_slice(&fvec);
        if !lu_solve(&jac, &mut step, n) {
            return (false, false);
        }
        for (s, sc) in step.iter_mut().zip(xscaling.iter()) {
            *s = -*s * sc;
        }

        let grad_f = -2.0 * error_f_sqrd;
        let grad_f_scaled = -2.0 * error_f_sqrd_scaled;

        // λ1: back off from the full step until the residual eval is finite.
        let mut lambda1 = 1.0;
        loop {
            for i in 0..n {
                x1[i] = x[i] + lambda1 * step[i];
            }
            eval(&x1, &mut fvec);
            if fvec.iter().all(|v| v.abs() < 1e30) {
                break;
            }
            lambda1 *= 0.655;
            if lambda1 <= LAMBDA_MIN_C {
                break;
            }
        }
        if lambda1 < LAMBDA_MIN_C {
            return (false, false);
        }
        let error_f1_sqrd = nsq(&fvec);
        let error_f1_sqrd_scaled = scaled_sq(n, &fvec, res_scaling);

        // Numerical-Recipes damping: quadratic then cubic model of ‖f‖².
        if error_f1_sqrd > error_f_sqrd + ALPHA * lambda1 * grad_f
            && error_f1_sqrd_scaled > error_f_sqrd_scaled + ALPHA * lambda1 * grad_f_scaled
            && error_f_sqrd > 1e-12
            && error_f_sqrd_scaled > 1e-12
        {
            let lambda2 = (-lambda1 * lambda1 * grad_f
                / (2.0 * (error_f1_sqrd - error_f_sqrd - lambda1 * grad_f)))
                .max(LAMBDA_MIN_C);
            for i in 0..n {
                x1[i] = x[i] + lambda2 * step[i];
            }
            eval(&x1, &mut fvec);
            let error_f2_sqrd = nsq(&fvec);
            if error_f1_sqrd > error_f_sqrd + ALPHA * lambda2 * grad_f
                && error_f_sqrd > 1e-12
                && error_f_sqrd_scaled > 1e-12
            {
                let rhs1 = error_f1_sqrd - grad_f * lambda1 - error_f_sqrd;
                let rhs2 = error_f2_sqrd - grad_f * lambda2 - error_f_sqrd;
                let a3 = (rhs1 / (lambda1 * lambda1) - rhs2 / (lambda2 * lambda2)) / (lambda1 - lambda2);
                let a2 = (-lambda2 * rhs1 / (lambda1 * lambda1) + lambda1 * rhs2 / (lambda2 * lambda2))
                    / (lambda1 - lambda2);
                let mut lam;
                if a3 == 0.0 {
                    lam = -grad_f / (2.0 * a2);
                } else {
                    let d = a2 * a2 - 3.0 * a3 * grad_f;
                    if d <= 0.0 {
                        lam = 0.5 * lambda1;
                    } else if a2 <= 0.0 {
                        lam = (-a2 + libm::sqrt(d)) / (3.0 * a3);
                    } else {
                        lam = -grad_f / (a2 + libm::sqrt(d));
                    }
                }
                lam = lam.max(LAMBDA_MIN_C);
                for i in 0..n {
                    x1[i] = x[i] + lam * step[i];
                }
                eval(&x1, &mut fvec);
            }
        }

        // Error measures (C uses the FULL Newton step ‖dy0‖ for delta_x).
        let delta_x_sqrd = nsq(&step);
        let mut dxs = 0.0;
        for i in 0..n {
            let v = step[i] / xscaling[i];
            dxs += v * v;
        }
        let delta_x_sqrd_scaled = dxs;
        let error_f_old = error_f_sqrd;
        error_f_sqrd = nsq(&fvec);
        error_f_sqrd_scaled = scaled_sq(n, &fvec, res_scaling);
        neg_steps += (error_f_sqrd > 10.0 * error_f_old) as i32;
        if neg_steps > 20 {
            return (false, false);
        }
        // C's issue #6419: on success keep the previous `x` when the new residual is no
        // better. Every other exit below also leaves `x` at the previous iterate.
        let last_was_good = error_f_sqrd >= error_f_old;

        let f_ok = error_f_sqrd < ftol_sq || error_f_sqrd_scaled < ftol_sq;
        let x_ok = delta_x_sqrd_scaled < xtol_sq || delta_x_sqrd < xtol_sq;
        if f_ok && x_ok {
            if !last_was_good {
                x.copy_from_slice(&x1);
            }
            return (true, !last_was_good);
        }
        iter += 1;
        if iter > MAX_ITER {
            return (false, false);
        }
        small_steps += (delta_x_sqrd < xtol_sq * 1e4 || delta_x_sqrd_scaled < xtol_sq * 1e4) as i32;
        if delta_x_sqrd < xtol_sq || delta_x_sqrd_scaled < xtol_sq || small_steps > 20 {
            return (error_f_sqrd < ftol_sq * 1e6 || error_f_sqrd_scaled < ftol_sq * 1e6, false);
        }

        x.copy_from_slice(&x1);
        form_jac(x, &fvec, &mut jac, &mut rp, &xscaling, eval, jaceval);
        row_scaling(n, &jac, res_scaling);
    }
}

/// KINSOL function-norm / scaled-step stopping tolerances (C's `newtonFTol` /
/// `newtonXTol`, `model_help.c`) and the norm below which C accepts a less
/// accurate solution rather than failing (`FTOL_WITH_LESS_ACCURACY`).
const KIN_FNORMTOL: f64 = 1.0e-12;
const KIN_SCSTEPTOL: f64 = 1.0e-12;
const KIN_FTOL_LESS_ACCURACY: f64 = 1.0e-6;

/// `‖diag(scale)·v‖∞`, the norm KINSOL's stopping tests use.
fn scaled_max_norm(v: &[f64], scale: &[f64]) -> f64 {
    let mut m = 0.0f64;
    for (a, s) in v.iter().zip(scale) {
        let t = libm::fabs(a * s);
        if !(t <= m) {
            m = t;
        }
    }
    m
}

/// The sparse nonlinear solver a system with an analytic sparsity pattern gets, as
/// in C: KINSOL over the Jacobian assembled straight into CSC, factorized by KLU.
/// [`newton_sparse_solve`] stands in for it where SUNDIALS is not linked in, and
/// serves `-nlsLS=rsparse`.
///
/// `pat_addr` holds the compile-time pattern (`colptr[n+1]` then `rowidx[nnz]`),
/// `val_ptr` the `nnz` values the model's `jac` callback fills, and `handle` keys
/// the solver kept for this system.
#[allow(clippy::too_many_arguments)]
fn kinsol_sparse_solve(
    n: usize,
    x: &mut [f64],
    guess: &[f64],
    warm: &[f64],
    nominal: &[f64],
    sim_data: u32,
    x_ptr: u32,
    jac_idx: u32,
    val_ptr: u32,
    pat_addr: u32,
    nnz: usize,
    handle: u32,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    #[cfg(sundials)]
    if nls_ls_backend() == crate::solvers::Sparse::Klu {
        // C's retry ladder re-picks the start point, but only through settings its
        // loop head overrides; `warm` is the caller's own second attempt.
        let colptr = unsafe { core::slice::from_raw_parts(pat_addr as *const i32, n + 1) };
        let rowidx =
            unsafe { core::slice::from_raw_parts((pat_addr + ((n + 1) * 4) as u32) as *const i32, nnz) };
        let mut assemble = make_assemble(n, x_ptr, sim_data, jac_idx, val_ptr);
        return crate::sundials::kinsol_solve(
            handle, n, nnz, colptr, rowidx, nominal, guess, x, eval, &mut assemble,
        );
    }
    newton_sparse_solve(
        n, x, guess, warm, nominal, sim_data, x_ptr, jac_idx, val_ptr, pat_addr, nnz, handle, eval,
    )
}

/// A scaled Newton iteration with a line search over the same CSC Jacobian, using
/// the runtime's own sparse LU: KINSOL's scaling (`xScale[i] = 1/max(nominal_i,
/// |x_i|)`, `fScale[i] = 1/max_j |J_ij / xScale_j|`) and stopping tests, with C's
/// retry ladder approximated by five start-point / scaling / line-search variations.
#[allow(clippy::too_many_arguments)]
fn newton_sparse_solve(
    n: usize,
    x: &mut [f64],
    guess: &[f64],
    warm: &[f64],
    nominal: &[f64],
    sim_data: u32,
    x_ptr: u32,
    jac_idx: u32,
    val_ptr: u32,
    pat_addr: u32,
    nnz: usize,
    handle: u32,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    let colptr_addr = pat_addr;
    let rowidx_addr = pat_addr + ((n + 1) * 4) as u32;
    let colptr: alloc::vec::Vec<usize> =
        (0..=n).map(|k| unsafe { load_u32(colptr_addr + (k * 4) as u32) } as usize).collect();
    let rowidx: alloc::vec::Vec<usize> =
        (0..nnz).map(|k| unsafe { load_u32(rowidx_addr + (k * 4) as u32) } as usize).collect();
    let b_ptr = rt_alloc((n * 8) as u32);

    let mut vals = vec![0.0f64; nnz];
    let mut assemble = make_assemble(n, x_ptr, sim_data, jac_idx, val_ptr);

    let mut f = vec![0.0f64; n];
    let mut xscale = vec![1.0f64; n];
    let mut fscale = vec![1.0f64; n];
    let mut xnew = vec![0.0f64; n];
    let mut dx = vec![0.0f64; n];

    // `(start from the last accepted values, scaled, line search)` per attempt;
    // attempt 0 is kinsol's configured default, the rest are C's retry ladder.
    const ATTEMPTS: [(bool, bool, bool); 5] = [
        (false, true, true),
        (false, false, true),
        (true, true, true),
        (false, true, false),
        (true, false, true),
    ];
    let mut solved = false;
    for &(from_warm, scaled, linesearch) in ATTEMPTS.iter() {
        x.copy_from_slice(if from_warm { warm } else { guess });
        for i in 0..n {
            xscale[i] = if scaled { 1.0 / libm::fmax(nominal[i], libm::fabs(x[i])) } else { 1.0 };
        }
        // f scaling from the column-scaled Jacobian at the entry point.
        for s in fscale.iter_mut() {
            *s = 1.0;
        }
        if scaled {
            assemble(x, &mut vals);
            let mut rowmax = vec![1.0e-12f64; n];
            for c in 0..n {
                for k in colptr[c]..colptr[c + 1] {
                    let v = libm::fabs(vals[k] / xscale[c]);
                    if v > rowmax[rowidx[k]] {
                        rowmax[rowidx[k]] = v;
                    }
                }
            }
            for i in 0..n {
                fscale[i] = 1.0 / rowmax[i];
            }
        }

        eval(x, &mut f);
        let mut fnorm = scaled_max_norm(&f, &fscale);
        for _ in 0..100 * n {
            if !fnorm.is_finite() {
                break;
            }
            if fnorm <= KIN_FNORMTOL {
                solved = true;
                break;
            }
            assemble(x, &mut vals);
            for i in 0..n {
                unsafe { store_f64(b_ptr + (i * 8) as u32, -f[i]) };
            }
            if crate::lin_sparse_cached(
                handle, colptr_addr, rowidx_addr, val_ptr, b_ptr, n as u32, nnz as u32,
                nls_ls_backend(),
            ) != 0
            {
                break; // singular: next attempt
            }
            for i in 0..n {
                dx[i] = unsafe { load_f64(b_ptr + (i * 8) as u32) };
            }
            // Damped step: halve until the scaled residual improves (kinsol's
            // KIN_LINESEARCH; KIN_NONE takes the full step).
            let mut lambda = 1.0f64;
            let mut fnew;
            loop {
                for i in 0..n {
                    xnew[i] = x[i] + lambda * dx[i];
                }
                eval(&xnew, &mut f);
                fnew = scaled_max_norm(&f, &fscale);
                if !linesearch || fnew < fnorm || lambda <= LAMBDA_MIN {
                    break;
                }
                lambda *= 0.5;
            }
            // KIN_STEP_LT_STPTOL: a step this small cannot improve the iterate.
            let mut step = 0.0f64;
            for i in 0..n {
                let d = libm::fabs(lambda * dx[i]) / libm::fmax(libm::fabs(x[i]), 1.0 / xscale[i]);
                if !(d <= step) {
                    step = d;
                }
            }
            x.copy_from_slice(&xnew);
            fnorm = fnew;
            if step <= KIN_SCSTEPTOL {
                solved = fnorm < KIN_FTOL_LESS_ACCURACY;
                break;
            }
        }
        if !solved && fnorm.is_finite() && fnorm < KIN_FTOL_LESS_ACCURACY {
            // C's "move forward with a less accurate solution".
            solved = true;
        }
        if solved {
            break;
        }
    }
    rt_free(b_ptr);
    solved
}

/// The `load` callback copies the current unknown slots into `x` (warm start);
/// `residual` writes `x` back into the slots, runs the inner (torn) equations,
/// and evaluates the residuals into `r`. On convergence the slots (and torn
/// variables) are left at the solution; on failure the entry guess is restored
/// and the flag is raised so the integrator can retry at a smaller step.
///
/// `hist_addr` points at this system's extrapolation history (see [`nls_hist`
/// layout in the codegen]): `count: u32 | time1: f64 | time2: f64 | x1[n] |
/// x2[n]`. The initial guess is a linear extrapolation of the last two solutions
/// to `time`, mirroring the C runtime's `getInitialGuess`/`extrapolateValues`;
/// this is what lets a system converge at a fast transition (e.g. friction
/// stuck↔slip) where the previous solution is a poor guess. If the extrapolated
/// guess fails, the warm start is retried (a second start value, like the C
/// solver), so no model regresses.
#[unsafe(no_mangle)]
pub extern "C" fn rt_solve_nls(
    sim_data: u32,
    res_idx: u32,
    load_idx: u32,
    n: u32,
    nls_fail_addr: u32,
    hist_addr: u32,
    time: f64,
    rel_fresh_addr: u32,
    nominal_addr: u32,
    jac_idx: u32,
    rel_addr: u32,
    n_rel: u32,
    mixed: u32,
    pat_addr: u32,
    nnz: u32,
    lss_handle: u32,
) -> i32 {
    let n = n as usize;
    // Relation mode (C's hysteresis): Newton always holds relations (mode 0) so it
    // is smooth; mode 2 (init) is fresh throughout; mode 1 (event) re-solves with
    // fresh relations until the discrete state stabilizes (mixed-system iteration).
    let saved_rel_fresh = unsafe { load_u32(rel_fresh_addr) };
    // Scratch buffers in the shared linear memory so the model callbacks (which
    // take wasm pointers) can read `x` / write `r`.
    let x_ptr = rt_alloc((n * 8) as u32);
    let r_ptr = rt_alloc((n * 8) as u32);

    // Function-pointer values are `__indirect_function_table` indices on wasm.
    let residual: extern "C" fn(u32, u32, u32) = unsafe { core::mem::transmute(res_idx as usize) };
    let load: extern "C" fn(u32, u32) = unsafe { core::mem::transmute(load_idx as usize) };

    // Warm start: the current slot values (the fallback guess, and what is
    // restored on failure).
    load(sim_data, x_ptr);
    let mut warm = vec![0.0f64; n];
    for i in 0..n {
        warm[i] = unsafe { load_f64(x_ptr + (i * 8) as u32) };
    }

    // Per-variable nominal values for x-scaling.
    let mut nominal = vec![0.0f64; n];
    for i in 0..n {
        nominal[i] = unsafe { load_f64(nominal_addr + (i * 8) as u32) };
    }

    stat_inc(STAT_NLS_SOLVE);
    let mut eval = |xs: &[f64], r: &mut [f64]| {
        stat_inc(STAT_NLS_RES);
        for i in 0..n {
            unsafe { store_f64(x_ptr + (i * 8) as u32, xs[i]) };
        }
        // Asserts are recoverable while the residual runs (C's ERROR_NONLINEARSOLVER).
        NLS_ASSERT_HIT.store(0, Ordering::Relaxed);
        NLS_DEPTH.fetch_add(1, Ordering::Relaxed);
        residual(sim_data, x_ptr, r_ptr);
        NLS_DEPTH.fetch_sub(1, Ordering::Relaxed);
        if NLS_ASSERT_HIT.load(Ordering::Relaxed) != 0 {
            // A model assert failed at this trial (e.g. length < s_small): reject the
            // step with a huge residual so the solver backtracks (C caught the longjmp).
            for i in 0..n {
                r[i] = 1e60;
            }
        } else {
            for i in 0..n {
                r[i] = unsafe { load_f64(r_ptr + (i * 8) as u32) };
            }
        }
    };

    // Analytic Jacobian callback: `jac(sim_data, x, jptr)` fills a column-major
    // `n×n` matrix, or the `nnz` CSC values when the system is solved sparsely.
    // `u32::MAX` means none, so numeric `hybrd` is used.
    let has_jac = jac_idx != u32::MAX;
    let sparse = has_jac && nnz != 0;
    let jac_len = if sparse { nnz as usize } else { n * n };
    let jac_ptr = if has_jac { rt_alloc((jac_len * 8) as u32) } else { 0 };
    // `-nls=` overrides the codegen-time density choice; the dense solvers force
    // the dense path.
    let pick = crate::solvers::nls();
    let sparse = match pick {
        Nls::Default | Nls::Kinsol => sparse,
        _ => false,
    };
    // A dense solver over a CSC-emitting `jac`: C's `evalJacobian` with `isDense`.
    let scatter = !sparse && nnz != 0 && jac_len == nnz as usize;
    let pat: alloc::vec::Vec<u32> = if scatter {
        (0..n + 1 + nnz as usize).map(|k| unsafe { load_u32(pat_addr + (k * 4) as u32) }).collect()
    } else {
        alloc::vec::Vec::new()
    };
    let mut jaceval = |xs: &[f64], fj: &mut [f64]| {
        stat_inc(STAT_NLS_JAC);
        let jacf: extern "C" fn(u32, u32, u32) = unsafe { core::mem::transmute(jac_idx as usize) };
        for i in 0..n {
            unsafe { store_f64(x_ptr + (i * 8) as u32, xs[i]) };
        }
        // The Jacobian is evaluated at accepted iterates; keep asserts recoverable
        // here too so a probe never traps, and drop any hit (the residual guards `r`).
        NLS_DEPTH.fetch_add(1, Ordering::Relaxed);
        jacf(sim_data, x_ptr, jac_ptr);
        NLS_DEPTH.fetch_sub(1, Ordering::Relaxed);
        NLS_ASSERT_HIT.store(0, Ordering::Relaxed);
        if scatter {
            fj.fill(0.0);
            for c in 0..n {
                for k in pat[c] as usize..pat[c + 1] as usize {
                    let row = pat[n + 1 + k] as usize;
                    fj[c * n + row] = unsafe { load_f64(jac_ptr + (k * 8) as u32) };
                }
            }
            return;
        }
        for (k, v) in fj.iter_mut().enumerate() {
            *v = unsafe { load_f64(jac_ptr + (k * 8) as u32) };
        }
    };

    // Per-system state: count | resScaling[n] | HIST_DEPTH × (time, x[n]).
    // `resScaling` is C's `homotopyData->resScaling`, which lives in the per-system
    // solver data and survives between calls, starting zeroed (= unscaled).
    // The entries are C's `oldValueList`. Depth is what makes the exact-time hit
    // below common: DASSL revisits an already-solved time on about half of all
    // calls, and only a deep list still holds it.
    let scale_addr = hist_addr + 8;
    let mut hist = MemHistory { count_addr: hist_addr, base: scale_addr + (n * 8) as u32, n };
    let mut res_scaling: alloc::vec::Vec<f64> =
        (0..n).map(|i| unsafe { load_f64(scale_addr + (i * 8) as u32) }).collect();

    let mut guess = warm.clone();
    let hpick = history_pick(&hist, time);
    if hpick.exact {
        stat_inc(STAT_NLS_GUESS_HIT);
    }
    history_guess(&hist, &hpick, time, &mut guess);

    let mut scratch = vec![0.0f64; n];
    let mut x = guess.clone();
    // C's `solve_nonlinear_system`: Newton holds relations (`solveContinuous`); at an
    // event, prime once live then hold, priming and solving from `nlsxOld` (=`warm`).
    // Extrapolating past a just-switched branch re-flips the relation the event set.
    let discrete_call = saved_rel_fresh == 1;
    let mixed = mixed != 0 && discrete_call;
    // C's `solveHomotopy` `relationsPreBackup`.
    let mut rel_backup = alloc::vec::Vec::new();
    if discrete_call {
        unsafe { store_u32(rel_fresh_addr, 1) };
        eval(&warm, &mut scratch);
        if mixed {
            rel_backup = (0..n_rel).map(|i| unsafe { load_u32(rel_addr + i * 4) }).collect();
        }
        unsafe { store_u32(rel_fresh_addr, 0) };
        x.copy_from_slice(&warm);
    } else if saved_rel_fresh == 0 {
        unsafe { store_u32(rel_fresh_addr, 0) };
    }
    let mut fvec = vec![0.0f64; n];
    let maxfev = n * 10000;
    // Last residual eval was at the returned `x`, so the epilogue need not repeat
    // it to leave the slots and torn variables set.
    let mut settled = false;
    // A system C would hand to kinsol+KLU: scaled Newton over the CSC Jacobian
    // (`kinsol_sparse_solve`). The dense ladder below is O(n^2) per Jacobian and
    // O(n^3) per step, which is what the sparse choice exists to avoid.
    let converged = if sparse {
        kinsol_sparse_solve(
            n, &mut x, &guess, &warm, &nominal, sim_data, x_ptr, jac_idx, jac_ptr,
            pat_addr, nnz as usize, lss_handle, &mut eval,
        )
    } else if pick == Nls::Newton {
        let (mut ok, s) =
            newton_c(n, &mut x, &nominal, None, &mut res_scaling, &mut eval, &mut jaceval, has_jac);
        settled = s;
        if !ok {
            settled = false;
            x.copy_from_slice(&warm);
            ok = newton_solve(n, &mut x, &mut eval);
        }
        ok
    } else if pick == Nls::Homotopy {
        // Both start directions, as C's runHomotopy.
        let mut ok = false;
        for &dir in &[1.0f64, -1.0] {
            let mut hx = guess.clone();
            if homotopy_solve(n, &mut hx, &nominal, dir, &mut eval) {
                x.copy_from_slice(&hx);
                ok = true;
                break;
            }
        }
        ok
    } else {
        // C's default `NLS_MIXED` runs `solveHomotopy`, whose primary solver is
        // `newtonAlgorithm`; minpack `hybrd` is only its fallback, restarted from the
        // same start point. `-nls=hybrid` selects `solveHybrd` alone and skips ahead.
        // Both share the retry/homotopy tail below.
        let start = x.clone();
        let mut converged = false;
        if matches!(pick, Nls::Default | Nls::Mixed) {
            // `solveHomotopy`'s pre-phase: a start point whose residual is already
            // tiny is taken outright, forming no Jacobian. ~40% of calls, nearly all
            // of them an exact time hit whose residual is therefore 0.
            eval(&x, &mut fvec);
            let e = enorm(&fvec);
            let ftol_accept = NEWTON_FTOL * NEWTON_FTOL * 1e-4;
            converged = e * e < ftol_accept || scaled_sq(n, &fvec, &res_scaling) < ftol_accept;
            settled = converged;
            if converged {
                stat_inc(STAT_NLS_ACCEPT);
            }
            if !converged {
                let f0 = fvec.clone();
                (converged, settled) = newton_c(
                    n, &mut x, &nominal, Some(&f0), &mut res_scaling, &mut eval, &mut jaceval,
                    has_jac,
                );
                if !converged {
                    stat_inc(STAT_NLS_NEWTON_FAIL);
                    x.copy_from_slice(&start);
                }
            }
        }
        settled &= converged;
        let mut solve = |x: &mut [f64], fvec: &mut [f64]| {
            if has_jac {
                hybrj_scaled(n, x, fvec, &nominal, maxfev, &mut eval, &mut jaceval)
            } else {
                hybrd_scaled(n, x, fvec, &nominal, maxfev, &mut eval)
            }
        };
        if !converged {
            converged = solve(&mut x, &mut fvec);
        }
        if !converged {
            stat_inc(STAT_NLS_RETRY);
            x.copy_from_slice(&warm);
            converged = solve(&mut x, &mut fvec);
        }
        drop(solve);
        if !converged {
            stat_inc(STAT_NLS_RETRY);
            x.copy_from_slice(&warm);
            converged = newton_solve(n, &mut x, &mut eval);
        }
        // C's init ladder: newtonAlgorithm, then solveHybrd (retry ladder) from x0.
        if !converged && saved_rel_fresh == 2 {
            x.copy_from_slice(&guess);
            converged =
                newton_c(n, &mut x, &nominal, None, &mut res_scaling, &mut eval, &mut jaceval, has_jac).0;
        }
        if !converged && saved_rel_fresh == 2 {
            x.copy_from_slice(&guess);
            converged = hybrd_c(n, &mut x, &nominal, &mut eval);
        }
        // Seed collapsed zero unknowns (e.g. the spring-loop s_rel) to nominal, off the
        // degenerate residual plateau, then re-solve — C's "zero start values to nominal".
        if !converged && saved_rel_fresh == 2 {
            x.copy_from_slice(&guess);
            for i in 0..n {
                if x[i] == 0.0 {
                    x[i] = nominal[i];
                }
            }
            converged = hybrd_c(n, &mut x, &nominal, &mut eval);
        }
        // Numeric-Jacobian hybrd, then LM, from the last iterate and from the guess.
        if !converged {
            stat_inc(STAT_NLS_RETRY);
            converged = hybrd_scaled(n, &mut x, &mut fvec, &nominal, maxfev, &mut eval);
        }
        if !converged {
            x.copy_from_slice(&guess);
            converged = hybrd_scaled(n, &mut x, &mut fvec, &nominal, maxfev, &mut eval);
        }
        if !converged {
            x.copy_from_slice(&guess);
            converged = lm_solve(n, &mut x, &mut eval);
        }
        if !converged {
            x.copy_from_slice(&warm);
            converged = lm_solve(n, &mut x, &mut eval);
        }
        // C's mixed-solver homotopy fallback: track H(x,λ)=F(x)−(1−λ)·F(x0) from λ=0 to 1.
        if !converged && saved_rel_fresh == 2 {
            // Forward then reversed start direction, as C's runHomotopy.
            for &dir in &[1.0f64, -1.0f64] {
                let mut hx = guess.clone();
                if homotopy_solve(n, &mut hx, &nominal, dir, &mut eval) {
                    x.copy_from_slice(&hx);
                    converged = true;
                    break;
                }
            }
        }
        converged
    };
    if converged {
        // Leave the slots + torn variables at the solution. C's `solveHomotopy`: a
        // mixed system at an event re-checks the relations live at the solution and,
        // if the branch moved, re-solves once from the start point with them live.
        if mixed {
            unsafe { store_u32(rel_fresh_addr, 1) };
            eval(&x, &mut scratch);
            if (0..n_rel).any(|i| unsafe { load_u32(rel_addr + i * 4) } != rel_backup[i as usize]) {
                let held = core::mem::replace(&mut x, warm.clone());
                let ok = if sparse {
                    kinsol_sparse_solve(
                        n, &mut x, &warm, &warm, &nominal, sim_data, x_ptr, jac_idx, jac_ptr,
                        pat_addr, nnz as usize, lss_handle, &mut eval,
                    )
                } else if has_jac {
                    hybrj_scaled(n, &mut x, &mut fvec, &nominal, maxfev, &mut eval, &mut jaceval)
                } else {
                    hybrd_scaled(n, &mut x, &mut fvec, &nominal, maxfev, &mut eval)
                };
                if !ok {
                    x = held;
                }
                eval(&x, &mut scratch);
            }
            unsafe { store_u32(rel_fresh_addr, 0) };
        } else if !settled {
            eval(&x, &mut scratch);
        }
    }
    for i in 0..n {
        unsafe { store_f64(scale_addr + (i * 8) as u32, res_scaling[i]) };
    }

    let ret = if converged {
        // `updateInitialGuessDB`: record the solution, unless this evaluation is a
        // Jacobian assembly — those are at perturbed states.
        if context_stores_guess() {
            if hist.len() > 0 && time < hist.time(0) - MINIMAL_STEP_SIZE {
                stat_inc(STAT_NLS_STORE_BACK);
            }
            history_store(&mut hist, time, &x);
        }
        0
    } else {
        // Restore the entry guess (held) and flag a recoverable failure.
        if saved_rel_fresh != 2 {
            unsafe { store_u32(rel_fresh_addr, 0) };
        }
        eval(&warm, &mut scratch);
        unsafe { store_u32(nls_fail_addr, 1) };
        stat_inc(STAT_NLS_FAIL);
        1
    };

    if saved_rel_fresh != 2 {
        unsafe { store_u32(rel_fresh_addr, saved_rel_fresh) };
    }

    rt_free(x_ptr);
    rt_free(r_ptr);
    if has_jac {
        rt_free(jac_ptr);
    }
    ret
}

#[cfg(test)]
mod tests {
    use super::*;

    /// [`History`] over a plain `Vec`, so the list logic can be replayed off-wasm.
    #[derive(Default)]
    struct VecHistory {
        entries: alloc::vec::Vec<(f64, alloc::vec::Vec<f64>)>,
    }

    impl History for VecHistory {
        fn len(&self) -> usize {
            self.entries.len()
        }
        fn time(&self, k: usize) -> f64 {
            self.entries[k].0
        }
        fn value(&self, k: usize, i: usize) -> f64 {
            self.entries[k].1[i]
        }
        fn shift(&mut self, from: usize, to: usize) {
            if to == self.entries.len() {
                let e = self.entries[from].clone();
                self.entries.push(e);
            } else {
                self.entries[to] = self.entries[from].clone();
            }
        }
        fn put(&mut self, k: usize, len: usize, time: f64, x: &[f64]) {
            if k == self.entries.len() {
                self.entries.push((time, x.to_vec()));
            } else {
                self.entries[k] = (time, x.to_vec());
            }
            self.entries.truncate(len);
            assert_eq!(self.entries.len(), len);
        }
    }

    // Replay the C runtime's own `oldValueList` trace (`nls_c_trace`): for every
    // call, the entries `getValues` picks must be the ones C picked, and an
    // exact-time hit must hand back the stored solution untouched.
    #[test]
    fn history_matches_c_trace() {
        let mut h = VecHistory::default();
        let mut guess = [f64::NAN];
        for (i, (time, picked, store)) in crate::nls_c_trace::TRACE.iter().enumerate() {
            if !time.is_nan() {
                let pick = history_pick(&h, *time);
                let got: alloc::vec::Vec<f64> = pick
                    .old
                    .iter()
                    .chain(pick.old2.iter())
                    .map(|&k| h.time(k))
                    .collect();
                assert_eq!(got, *picked, "call {i}: picked entries differ from C");
                history_guess(&h, &pick, *time, &mut guess);
                if pick.exact {
                    assert_eq!(guess[0], h.value(pick.old.unwrap(), 0), "call {i}: not verbatim");
                }
            }
            if let Some((t, v)) = store {
                history_store(&mut h, *t, &[*v]);
                assert_eq!(h.time(0), *t, "call {i}: store did not land at the front");
                assert!(h.len() <= HIST_DEPTH);
            }
        }
        // The trace is long enough to fill the list and start dropping the oldest.
        assert_eq!(h.len(), HIST_DEPTH);
    }

    // `addListElement` replaces the front when the times match and pushes otherwise,
    // so the list is in insertion order, not time order — a step back in time lands
    // at the front and is found again exactly (which is what skips a Newton solve).
    #[test]
    fn history_keeps_insertion_order() {
        let mut h = VecHistory::default();
        for (t, v) in [(0.0, 1.0), (2.0, 3.0), (1.0, 2.0)] {
            history_store(&mut h, t, &[v]);
        }
        assert_eq!([h.time(0), h.time(1), h.time(2)], [1.0, 2.0, 0.0]);
        let pick = history_pick(&h, 1.0);
        assert!(pick.exact && pick.old == Some(0));
        // Re-storing at the front's time replaces it instead of growing the list.
        history_store(&mut h, 1.0, &[9.0]);
        assert_eq!((h.len(), h.value(0, 0)), (3, 9.0));
    }

    // `extrapolateValues`: linear in time through the picked pair, but the older
    // value verbatim when the two are level.
    #[test]
    fn history_extrapolates_linearly() {
        let mut h = VecHistory::default();
        history_store(&mut h, 1.0, &[10.0, 5.0]);
        history_store(&mut h, 2.0, &[20.0, 5.0]);
        let mut guess = [f64::NAN; 2];
        let pick = history_pick(&h, 4.0);
        assert_eq!((pick.old, pick.old2, pick.exact), (Some(0), Some(1), false));
        history_guess(&h, &pick, 4.0, &mut guess);
        assert_eq!(guess, [40.0, 5.0]);
    }

    // 2×2 linear system solved as if nonlinear: r = A x - b, A=[[2,0],[0,3]], b=[4,9] → x=[2,3].
    #[test]
    fn newton_solves_linear() {
        let mut x = [0.0, 0.0];
        let mut eval = |xs: &[f64], r: &mut [f64]| {
            r[0] = 2.0 * xs[0] - 4.0;
            r[1] = 3.0 * xs[1] - 9.0;
        };
        assert!(newton_solve(2, &mut x, &mut eval));
        assert!((x[0] - 2.0).abs() < 1e-9);
        assert!((x[1] - 3.0).abs() < 1e-9);
    }

    // Genuinely nonlinear + coupled: x^2 + y = 3, x + y^2 = 5 near (1, 2).
    #[test]
    fn newton_solves_nonlinear() {
        let mut x = [1.0, 2.0];
        let mut eval = |xs: &[f64], r: &mut [f64]| {
            r[0] = xs[0] * xs[0] + xs[1] - 3.0;
            r[1] = xs[0] + xs[1] * xs[1] - 5.0;
        };
        assert!(newton_solve(2, &mut x, &mut eval));
        assert!((x[0] * x[0] + x[1] - 3.0).abs() < 1e-8);
        assert!((x[0] + x[1] * x[1] - 5.0).abs() < 1e-8);
    }

    // A stiff-ish scalar case where the undamped full step overshoots: exp(x) - 1 = 0 → x = 0.
    #[test]
    fn newton_line_search_recovers() {
        let mut x = [5.0];
        let mut eval = |xs: &[f64], r: &mut [f64]| {
            r[0] = libm::exp(xs[0]) - 1.0;
        };
        assert!(newton_solve(1, &mut x, &mut eval));
        assert!(x[0].abs() < 1e-7);
    }

    // Full-rank system: total pivot matches the LU solution.
    #[test]
    fn total_pivot_full_rank() {
        // A = [[2,1],[1,3]] column-major, b = [3,5] → x = [0.8, 1.4].
        let a = [2.0, 1.0, 1.0, 3.0];
        let mut b = [3.0, 5.0];
        assert!(total_pivot_solve(&a, &mut b, 2));
        assert!((b[0] - 0.8).abs() < 1e-12);
        assert!((b[1] - 1.4).abs() < 1e-12);
    }

    // Rank-deficient but consistent: second row = 2× first. LU fails, total pivot
    // returns a particular solution (free variable zeroed) that satisfies A x = b.
    #[test]
    fn total_pivot_rank_deficient_consistent() {
        // A = [[1,2],[2,4]] column-major, b = [3,6]. x1 + 2 x2 = 3.
        let a = [1.0, 2.0, 2.0, 4.0];
        assert!(!lu_solve(&a, &mut [3.0, 6.0], 2));
        let mut b = [3.0, 6.0];
        assert!(total_pivot_solve(&a, &mut b, 2));
        assert!((b[0] + 2.0 * b[1] - 3.0).abs() < 1e-12);
    }

    // Rank-deficient and inconsistent: no solution → reported as failure.
    #[test]
    fn total_pivot_inconsistent_fails() {
        // A = [[1,2],[2,4]] column-major, b = [3,7]: parallel rows, incompatible rhs.
        let a = [1.0, 2.0, 2.0, 4.0];
        let mut b = [3.0, 7.0];
        assert!(!total_pivot_solve(&a, &mut b, 2));
    }

    // LM converges from a far-off guess where a full Newton step would overshoot.
    #[test]
    fn lm_solves_from_poor_guess() {
        let mut x = [3.0, -3.0];
        let mut eval = |xs: &[f64], r: &mut [f64]| {
            r[0] = xs[0] * xs[0] + xs[1] - 3.0;
            r[1] = xs[0] + xs[1] * xs[1] - 5.0;
        };
        assert!(lm_solve(2, &mut x, &mut eval));
        assert!((x[0] * x[0] + x[1] - 3.0).abs() < 1e-6);
        assert!((x[0] + x[1] * x[1] - 5.0).abs() < 1e-6);
    }

    // Singular Jacobian → reported as failure, not a panic.
    #[test]
    fn newton_reports_singular() {
        let mut x = [0.0, 0.0];
        let mut eval = |xs: &[f64], r: &mut [f64]| {
            r[0] = xs[0] + xs[1] - 1.0;
            r[1] = xs[0] + xs[1] - 2.0; // parallel: no solution, singular J
        };
        assert!(!newton_solve(2, &mut x, &mut eval));
    }
}
