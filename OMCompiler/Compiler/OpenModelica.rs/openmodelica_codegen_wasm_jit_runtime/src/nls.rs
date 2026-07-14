//! Dense nonlinear solver (Newton with a forward-difference Jacobian and a
//! backtracking line search) shared by every `SES_NONLINEAR` system. Previously
//! this Newton driver was emitted as wasm into each system; it now lives here as
//! one compiled-once function. `newton_solve` is the pure numeric core (generic
//! over the residual, so it unit-tests natively); `rt_solve_nls` is the wasm
//! entry point the generated modules call, bridging the residual to a model
//! `residual`/`load` function pair via `call_indirect` over the shared table.

use alloc::vec;

use crate::{load_f64, load_u32, rt_alloc, rt_free, store_f64, store_u32};

/// sqrt(DBL_EPSILON): the classic forward-difference relative step.
const SQRT_EPS: f64 = 1.4901161193847656e-08;
/// Convergence tolerance (C's `newtonData->ftol`/`xtol`): the iteration stops
/// once *any* of the residual / step / residual-change measures drops below it.
const NEWTON_EPS: f64 = 1.0e-6;
const MAX_ITER: i32 = 100;
/// Line-search damping floor (2^-10): below this, keep the small step and let
/// the outer iteration retry (or hit the iteration limit → recoverable failure).
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
    if error_f < NEWTON_EPS {
        return true;
    }
    f_old.copy_from_slice(&fvec);

    let mut iter = 0;
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
        let mut df2 = 0.0;
        for i in 0..n {
            let d = f_old[i] - fvec[i];
            df2 += d * d;
        }
        let delta_f = libm::sqrt(df2);
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

        if error_f < NEWTON_EPS
            || scaled_error_f < NEWTON_EPS
            || delta_x < NEWTON_EPS
            || delta_f < NEWTON_EPS
            || delta_x_scaled < NEWTON_EPS
        {
            return true;
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

/// wasm entry point: solve one `SES_NONLINEAR` system. `res_idx`/`load_idx` are
/// shared-table indices of the model's `residual(sim_data, x, r)` and
/// `load(sim_data, x)` functions; `n` is the unknown count; `nls_fail_addr` is
/// the absolute address of the `SimData` recoverable-failure flag.
///
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

    let mut eval = |xs: &[f64], r: &mut [f64]| {
        for i in 0..n {
            unsafe { store_f64(x_ptr + (i * 8) as u32, xs[i]) };
        }
        residual(sim_data, x_ptr, r_ptr);
        for i in 0..n {
            r[i] = unsafe { load_f64(r_ptr + (i * 8) as u32) };
        }
    };

    // History: count | time1 (newest) | time2 | x1[n] (newest) | x2[n].
    let count = unsafe { load_u32(hist_addr) };
    let time1 = unsafe { load_f64(hist_addr + 8) };
    let time2 = unsafe { load_f64(hist_addr + 16) };
    let x1_addr = hist_addr + 24;
    let x2_addr = x1_addr + (n * 8) as u32;

    // Initial guess (getInitialGuess): extrapolate the last two solutions to
    // `time`, else the last solution, else the warm start.
    let mut guess = warm.clone();
    if count >= 2 && time1 != time2 {
        let f = (time - time2) / (time1 - time2);
        for i in 0..n {
            let a = unsafe { load_f64(x1_addr + (i * 8) as u32) };
            let b = unsafe { load_f64(x2_addr + (i * 8) as u32) };
            // extrapolateValues: `a` if the two are level, else linear in time.
            guess[i] = if a == b { a } else { b + f * (a - b) };
        }
    } else if count >= 1 {
        for i in 0..n {
            guess[i] = unsafe { load_f64(x1_addr + (i * 8) as u32) };
        }
    }

    let mut scratch = vec![0.0f64; n];
    let mut x = guess.clone();
    // At an event (mode 1) keep relations hysteretic during Newton, as C does (its
    // residual recomputes them via `LessZC`/`GreaterZC` each eval). Freezing to
    // `relationsPre` (mode 0) locks the discrete branch of a coupled system such as
    // Rotational friction (sa ↔ mode/startForward) to the guess, converging to a
    // different root than C. Integration (0) stays held/smooth; init (2) stays fresh.
    if saved_rel_fresh == 1 {
        // Prime relations at the guess so a branch switch reaches the driver's event
        // loop, then leave mode 1 for Newton.
        unsafe { store_u32(rel_fresh_addr, 1) };
        eval(&x, &mut scratch);
    } else if saved_rel_fresh == 0 {
        unsafe { store_u32(rel_fresh_addr, 0) };
    }
    let mut converged = newton_solve(n, &mut x, &mut eval);
    if !converged {
        // Second start value, then a trust-region globaliser from each start.
        x.copy_from_slice(&warm);
        converged = newton_solve(n, &mut x, &mut eval);
        if !converged {
            x.copy_from_slice(&guess);
            converged = lm_solve(n, &mut x, &mut eval);
        }
        if !converged {
            x.copy_from_slice(&warm);
            converged = lm_solve(n, &mut x, &mut eval);
        }
    }
    if converged {
        // Leave the slots + torn variables at the solution (held/init mode, so an
        // event keeps the fresh-at-guess relations).
        eval(&x, &mut scratch);
    }

    let ret = if converged {
        // Record the solution for extrapolation, advancing the two-point history
        // only when time moves forward; repeated solves at the same time (DASSL
        // Jacobian columns, root-finding probes) keep the first solution there.
        if count == 0 || time > time1 {
            for i in 0..n {
                let a = unsafe { load_f64(x1_addr + (i * 8) as u32) };
                unsafe { store_f64(x2_addr + (i * 8) as u32, a) };
            }
            unsafe { store_f64(hist_addr + 16, time1) };
            unsafe { store_f64(hist_addr + 8, time) };
            for i in 0..n {
                unsafe { store_f64(x1_addr + (i * 8) as u32, x[i]) };
            }
            unsafe { store_u32(hist_addr, (count + 1).min(2)) };
        }
        0
    } else {
        // Restore the entry guess (held) and flag a recoverable failure.
        if saved_rel_fresh != 2 {
            unsafe { store_u32(rel_fresh_addr, 0) };
        }
        eval(&warm, &mut scratch);
        unsafe { store_u32(nls_fail_addr, 1) };
        1
    };

    if saved_rel_fresh != 2 {
        unsafe { store_u32(rel_fresh_addr, saved_rel_fresh) };
    }

    rt_free(x_ptr);
    rt_free(r_ptr);
    ret
}

#[cfg(test)]
mod tests {
    use super::*;

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
