//! C's `simulation/solver/jacobian_analysis.c` plus the derivative test
//! `kinsolSolver.c` still keeps next to KINSOL: what `-lv=LOG_NLS_DERIVATIVE_TEST`
//! and `-lv=LOG_NLS_SVD` report about a nonlinear system's Jacobian.

use alloc::format;
use alloc::string::String;
use alloc::vec;

use crate::omclog;

/// C's `SolverCaller`.
#[derive(Clone, Copy, PartialEq, Eq)]
pub(crate) enum Caller {
    KinsolJacEval,
    #[allow(dead_code)]
    KinsolEntry,
    #[allow(dead_code)]
    KinsolBJacEval,
    #[allow(dead_code)]
    KinsolBEntry,
}

impl Caller {
    /// C's `SolverCaller_callerString`.
    fn solver(self) -> &'static str {
        match self {
            Caller::KinsolJacEval | Caller::KinsolEntry => "kinsol",
            Caller::KinsolBJacEval | Caller::KinsolBEntry => "experimental-kinsol",
        }
    }

    /// C's `SolverCaller_toString`.
    fn full(self) -> &'static str {
        match self {
            Caller::KinsolJacEval => "kinsol: Jacobian eval",
            Caller::KinsolEntry => "kinsol: Kinsol entry point",
            Caller::KinsolBJacEval => "experimental-kinsol: Jacobian eval",
            Caller::KinsolBEntry => "experimental-kinsol: Kinsol entry point",
        }
    }
}

fn sgn_e(v: f64, prec: usize) -> String {
    let s = omclog::e(v, 0, prec);
    if v.is_sign_negative() || s.starts_with('-') { s } else { format!("+{s}") }
}

/// C's `nlsDenseJac` with `nominalJac` clear. Column-major, so `out[col * n + row]`
/// is `SM_ELEMENT_D(Jnum, row, col)`.
fn dense_fd_jacobian(n: usize, x: &mut [f64], fx: &[f64], out: &mut [f64], eval: &mut dyn FnMut(&[f64], &mut [f64])) {
    /// `sqrt(DBL_EPSILON * 2e1)`, C's difference step.
    const DELTA_H: f64 = 6.664001874625056e-08;
    let mut fres = vec![0.0f64; n];
    for i in 0..n {
        let saved = x[i];
        let dh = DELTA_H * (libm::fabs(saved) + 1.0);
        x[i] = saved + dh;
        eval(x, &mut fres);
        x[i] = saved;
        let inv = 1.0 / dh;
        for j in 0..n {
            out[i * n + j] = (fres[j] - fx[j]) * inv;
        }
    }
}

/// C's `nlsKinsolDenseDerivativeTest`: the symbolic Jacobian `sym` (CSC over
/// `colptr`/`rowidx`) against forward differences at the same point.
#[allow(clippy::too_many_arguments)]
pub(crate) fn derivative_test(
    eq_index: u32,
    time: f64,
    n: usize,
    x: &mut [f64],
    colptr: &[i32],
    rowidx: &[i32],
    sym: &[f64],
    scaled: bool,
    caller: Caller,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) {
    let stream = omclog::NLS_DERIVATIVE_TEST;
    let (atol, rtol) = crate::solvers::jac_test_tolerances();
    let mut fx = vec![0.0f64; n];
    eval(x, &mut fx);
    let mut num = vec![0.0f64; n * n];
    dense_fd_jacobian(n, x, &fx, &mut num, eval);

    omclog::info(
        stream,
        true,
        &format!(
            "{}: Derivative test (atol={}, rtol={}, scaled = {}, Caller: {}):",
            caller.solver(),
            omclog::e(atol, 0, 5),
            omclog::e(rtol, 0, 5),
            scaled,
            caller.full()
        ),
    );
    omclog::info(stream, true, "Matrix Info");
    omclog::info(stream, false, &format!("NLS index = {eq_index}"));
    omclog::info(stream, false, &format!("Columns   = {n}"));
    omclog::info(stream, false, &format!("Rows      = {n}"));
    omclog::info(stream, false, &format!("NNZ       = {}", sym.len()));
    omclog::info(stream, false, &format!("Curr Time = {:<11}", omclog::e(time, 0, 5)));
    omclog::close(stream);

    omclog::info(stream, true, "Anomalies");
    let names = crate::nls::var_names(eq_index);
    let (mut numerical, mut structural, mut max_error) = (0u32, 0u32, 0.0f64);
    let mut nz = 0usize;
    for col in 0..n {
        let mut found = false;
        let open_column = |found: &mut bool| {
            if *found {
                return;
            }
            let name = names.get(col).map(String::as_str).unwrap_or_default();
            omclog::info(stream, true, &format!("Column / Variable: {}, Name: {name}", col + 1));
            omclog::info(
                stream,
                false,
                &format!("{:<12} {:<6} {:<6} {:<15}  {:<15}  {:<8}", "Type", "Col", "Row", "Symbolic", "Numerical", "RelError"),
            );
            *found = true;
        };
        for row in 0..n {
            let num_value = num[col * n + row];
            let in_pattern = (colptr[col] as usize) <= nz
                && nz < colptr[col + 1] as usize
                && rowidx[nz] as usize == row;
            if in_pattern {
                let sym_value = sym[nz];
                nz += 1;
                let abs_error = libm::fabs(sym_value - num_value);
                let rel_error = if abs_error < atol {
                    0.0
                } else {
                    abs_error / libm::fmax(libm::fabs(num_value), libm::fabs(sym_value))
                };
                if rel_error > max_error {
                    max_error = rel_error;
                }
                if rel_error > rtol {
                    open_column(&mut found);
                    omclog::info(
                        stream,
                        false,
                        &format!(
                            "{:<12} {:<6} {:<6} {}  {}  {}",
                            "Numerical",
                            col + 1,
                            row + 1,
                            sgn_e(sym_value, 8),
                            sgn_e(num_value, 8),
                            sgn_e(rel_error, 8)
                        ),
                    );
                    numerical += 1;
                }
            } else if libm::fabs(num_value) > atol {
                open_column(&mut found);
                omclog::info(
                    stream,
                    false,
                    &format!(
                        "{:<12} {:<6} {:<6} {}  {}  {}",
                        "Structural",
                        col + 1,
                        row + 1,
                        sgn_e(0.0, 8),
                        sgn_e(num_value, 8),
                        sgn_e(1.0, 8)
                    ),
                );
                structural += 1;
            }
        }
        if found {
            omclog::close(stream);
        }
    }
    omclog::close(stream);

    omclog::info(stream, true, "Summary");
    omclog::info(stream, false, &format!("Numerical errors:  {numerical} (value mismatch w.r.t. reference)"));
    omclog::info(stream, false, &format!("Structural errors: {structural} (non-zero not in sparsity pattern)"));
    omclog::info(stream, false, &format!("Max relative error: {}", omclog::e(max_error, 0, 3)));
    if numerical + structural > 0 {
        omclog::warning(
            stream,
            false,
            &format!("Derivative test failed ({numerical} numerical, {structural} structural errors)"),
        );
    }
    omclog::close(stream);
    omclog::close(stream);
}

/// C's `svd_compute`, over the CSC Jacobian the solver is about to use.
/// `-svdCount` picks the sparse (PRIMME) path; 0 is the dense decomposition.
pub(crate) fn svd_analysis(
    eq_index: u32,
    time: f64,
    n: usize,
    colptr: &[i32],
    rowidx: &[i32],
    vals: &[f64],
    scaled: bool,
    caller: Caller,
) {
    if !(omclog::active(omclog::NLS_SVD) || omclog::active(omclog::NLS_SVD_V)) {
        return;
    }
    let (count, sigma) = crate::solvers::svd_params();
    if count == 0 {
        return dense_svd(eq_index, time, n, colptr, rowidx, vals, scaled, caller);
    }
    sparse_svd(eq_index, time, n, colptr, rowidx, vals, scaled, caller, count as usize, sigma);
}

fn dense(n: usize, colptr: &[i32], rowidx: &[i32], vals: &[f64]) -> vec::Vec<f64> {
    let mut a = vec![0.0f64; n * n];
    for c in 0..n {
        for k in colptr[c] as usize..colptr[c + 1] as usize {
            a[c * n + rowidx[k] as usize] = vals[k];
        }
    }
    a
}

/// C's `svd_general_matrix_print_info`.
fn print_matrix_info(eq_index: u32, time: f64, n: usize, nnz: usize) {
    let s = omclog::NLS_SVD;
    omclog::info(s, true, "Matrix Info");
    omclog::info(s, false, &format!("NLS eq index = {eq_index}"));
    omclog::info(s, false, &format!("Columns      = {n}"));
    omclog::info(s, false, &format!("Rows         = {n}"));
    omclog::info(s, false, &format!("NNZ          = {nnz}"));
    omclog::info(s, false, &format!("Curr Time    = {:<11}", omclog::e(time, 0, 5)));
    omclog::close(s);
}

/// C's `svd_general_matrix_print_cond`.
fn print_cond(cond: f64) {
    let s = omclog::NLS_SVD;
    let c = |v: f64| omclog::e(v, 0, 8);
    omclog::info(s, true, "Matrix condition");
    omclog::info(s, false, &format!("Cond(M) = {}", c(cond)));
    if cond > 1e12 {
        omclog::warning(s, false, &format!("Matrix is very ill-conditioned: 1e12 < Cond(M) = {}", c(cond)));
    } else if cond > 1e8 {
        omclog::warning(
            s, false,
            &format!("Matrix is fairly ill-conditioned: 1e8 < Cond(M) = {} < 1e12", c(cond)),
        );
    } else if cond > 1e4 {
        omclog::warning(
            s, false,
            &format!("Matrix is moderately ill-conditioned: 1e4 < Cond(M) = {} < 1e8", c(cond)),
        );
    } else {
        omclog::info(s, false, &format!("Matrix is well conditioned: Cond(M) = {} < 1e4", c(cond)));
    }
    omclog::close(s);
}

/// C's `cmp_fabs_desc`. `sort_by` is stable, so equal magnitudes keep their index
/// order, as `qsort` leaves them for vectors this short.
fn by_magnitude(v: &[f64]) -> vec::Vec<(usize, f64)> {
    let mut e: vec::Vec<(usize, f64)> = v.iter().copied().enumerate().collect();
    e.sort_by(|a, b| {
        libm::fabs(b.1).partial_cmp(&libm::fabs(a.1)).unwrap_or(core::cmp::Ordering::Equal)
    });
    e
}

/// C's `svd_sparse_print_vectors`, for one singular triplet.
fn print_vectors(eq_index: u32, n: usize, idx: usize, sigma: f64, v: &[f64], u: &[f64]) {
    let s = omclog::NLS_SVD;
    let names = crate::nls::var_names(eq_index);
    let eqns = crate::model_ctx::with_model(|m| {
        m.nls_vars.iter().find(|s| s.eq_index == eq_index).map(|s| s.eqns.clone()).unwrap_or_default()
    })
    .unwrap_or_default();

    omclog::info(s, true, "Smallest right singular vectors (variable space)");
    omclog::info(s, false, "Found 1 singular vectors.");
    omclog::info(s, true, &format!("V[:,{idx}] (singular value {})", omclog::e(sigma, 0, 8)));
    for (i, val) in by_magnitude(v) {
        let name = names.get(i).map(String::as_str).unwrap_or_default();
        let line = format!(
            "V[{}][{idx}] = {} for NLS Var: {} with Name: {name}",
            i + 1,
            sgn_e(val, 8),
            i + 1
        );
        omclog::info(s, false, &line);
    }
    omclog::close(s);
    omclog::close(s);

    omclog::info(s, true, "Smallest left singular vectors (function space)");
    omclog::info(s, false, "Found 1 singular vectors.");
    omclog::info(s, true, &format!("U[:,{idx}] (singular value {})", omclog::e(sigma, 0, 8)));
    for (i, val) in by_magnitude(u) {
        let eq = eqns.get(i).copied().unwrap_or(0);
        let line = format!(
            "U[{}][{idx}] = {} for NLS Eqn: {} with transformational debugger Idx: {eq}",
            i + 1,
            sgn_e(val, 8),
            i + 1
        );
        omclog::info(s, false, &line);
    }
    omclog::close(s);
    omclog::close(s);
    let _ = n;
}

/// C's `svd_sparse_main` + `svd_sparse_dump_statistics`.
#[allow(clippy::too_many_arguments)]
fn sparse_svd(
    eq_index: u32, time: f64, n: usize, colptr: &[i32], rowidx: &[i32], vals: &[f64],
    scaled: bool, caller: Caller, count: usize, sigma: f64,
) {
    let s = omclog::NLS_SVD;
    #[cfg(not(feature = "primme"))]
    {
        let _ = (eq_index, time, n, colptr, rowidx, vals, scaled, caller, count, sigma);
        omclog::error(
            omclog::STDOUT,
            false,
            "Cannot call sparse SVD analysis, because OpenModelica was not build with PRIMME. \
             Set FLAG_SVD_SPARSE_COUNT=0 to perform dense SVD or build OpenModelica with \
             PRIMME via -DOM_OMC_ENABLE_PRIMME=ON.",
        );
    }
    #[cfg(feature = "primme")]
    {
        unsafe extern "C" {
            #[allow(clippy::too_many_arguments)]
            fn omc_primme_svds(
                n: i32, colptr: *const i32, rowidx: *const i32, vals: *const f64, count: i32,
                sigma: f64, print_level: i32, sval_top: *mut f64, rnorm_top: *mut f64,
                svals: *mut f64, rnorms: *mut f64, svecs: *mut f64,
            ) -> i32;
        }
        let want = count.min(n);
        let (mut sval_top, mut rnorm_top) = (0.0f64, 0.0f64);
        let mut svals = vec![0.0f64; want];
        let mut rnorms = vec![0.0f64; want];
        let mut svecs = vec![0.0f64; 2 * n * want];
        let level = if omclog::active(omclog::NLS_SVD_V) { 2 } else { 0 };
        let found = unsafe {
            omc_primme_svds(
                n as i32, colptr.as_ptr(), rowidx.as_ptr(), vals.as_ptr(), want as i32, sigma,
                level, &mut sval_top, &mut rnorm_top, svals.as_mut_ptr(), rnorms.as_mut_ptr(),
                svecs.as_mut_ptr(),
            )
        };
        if found < 0 {
            omclog::error(omclog::STDOUT, false, "Error: primme_svds returned with nonzero exit status");
            return;
        }
        let found = (found as usize).min(want);
        omclog::info(
            s, true,
            &format!(
                "{}: sparse SVD analysis (scaled = {scaled}, Caller: {}).",
                caller.solver(),
                caller.full()
            ),
        );
        print_matrix_info(eq_index, time, n, vals.len());
        // C's `cond`: infinite where the smallest singular value vanished.
        let sigma_min = svals.first().copied().unwrap_or(0.0);
        print_cond(if sigma_min != 0.0 { sval_top / sigma_min } else { f64::INFINITY });

        omclog::info(s, true, "Smallest Singular values");
        for i in 0..found {
            let line = format!(
                "sigma_{:<3} =  {}, rnorm_{:<3} =  {}",
                i + 1,
                omclog::e(svals[i], 0, 8),
                i + 1,
                omclog::e(rnorms[i], 0, 8)
            );
            omclog::info(s, false, &line);
        }
        omclog::close(s);
        omclog::info(s, true, "Largest Singular values");
        omclog::info(
            s, false,
            &format!("sigma_{:<3} =  {}, rnorm_{:<3} =  {}", 1, omclog::e(sval_top, 0, 8), 1, omclog::e(rnorm_top, 0, 8)),
        );
        omclog::close(s);

        // `svecs` holds the left vectors first, then the right ones.
        for v in 0..found {
            let u = &svecs[n * v..][..n];
            let right = &svecs[n * (found + v)..][..n];
            print_vectors(eq_index, n, n - v, svals[v], right, u);
        }
        omclog::close(s);
    }
}

/// C's `svd_dense_main`, for `-svdCount=0`.
#[allow(clippy::too_many_arguments)]
fn dense_svd(
    eq_index: u32, time: f64, n: usize, colptr: &[i32], rowidx: &[i32], vals: &[f64],
    scaled: bool, caller: Caller,
) {
    let s = omclog::NLS_SVD;
    let mut a = dense(n, colptr, rowidx, vals);
    let (mut sv, mut u, mut vt) = (vec![0.0f64; n], vec![0.0f64; n * n], vec![0.0f64; n * n]);
    if openmodelica_lapack::dgesvd("A", "A", n, n, &mut a, n, &mut sv, &mut u, n, &mut vt, n) != 0 {
        return;
    }
    omclog::info(
        s, true,
        &format!(
            "{}: dense SVD analysis (scaled = {scaled}, Caller: {}).",
            caller.solver(),
            caller.full()
        ),
    );
    print_matrix_info(eq_index, time, n, vals.len());
    let sigma_min = sv[n - 1];
    print_cond(if sigma_min > 0.0 { sv[0] / sigma_min } else { f64::INFINITY });
    omclog::info(s, true, "Singular values");
    for (i, v) in sv.iter().enumerate() {
        omclog::info(s, false, &format!("sigma_{:<3} =  {}", i + 1, omclog::e(*v, 0, 8)));
    }
    omclog::close(s);
    let tol = n as f64 * f64::EPSILON * sv[0];
    let rank = sv.iter().filter(|v| **v > tol).count();
    omclog::info(s, true, "Rank estimation");
    omclog::info(s, false, &format!("estimated = {rank}"));
    omclog::info(s, false, &format!("actual    = {n}"));
    omclog::info(
        s, false,
        &format!(
            "estimation tolerance = {} (= sigma_max * max(rows, cols) * DBL_EPSILON)",
            omclog::e(tol, 0, 8)
        ),
    );
    omclog::info(
        s, false,
        if rank < n { "Matrix may be rank-deficient." } else { "Matrix should have full rank." },
    );
    omclog::close(s);
    let threshold = 0.01 * sv[0];
    let first_below = sv.iter().position(|v| *v < threshold).unwrap_or(n);
    if first_below == n {
        for what in ["Smallest right singular vectors (variable space)", "Smallest left singular vectors (function space)"] {
            omclog::info(s, true, what);
            omclog::info(
                s, false,
                &format!("No singular values below {} (1% of max)", omclog::e(threshold, 0, 8)),
            );
            omclog::close(s);
        }
    } else {
        for k in (first_below..n).rev() {
            let right: vec::Vec<f64> = (0..n).map(|i| vt[i * n + k]).collect();
            let u_k: vec::Vec<f64> = (0..n).map(|i| u[k * n + i]).collect();
            print_vectors(eq_index, n, k + 1, sv[k], &right, &u_k);
        }
    }
    omclog::close(s);
}
