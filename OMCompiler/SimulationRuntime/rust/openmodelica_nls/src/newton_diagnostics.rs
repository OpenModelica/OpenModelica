//! C's `newton_diagnostics.c`: the `-lv=LOG_NLS_NEWTON_DIAGNOSTICS` report on an
//! initial nonlinear system's start values, printed before the system is solved.
//!
//! From the first Newton step `dx = -J⁻¹ f(x0)` and a finite-difference Hessian of
//! the symbolic Jacobian it ranks the unknowns and equations by the indicators of
//! Deuflhard's convergence theory: `alpha_i` (how far equation `i` is from its
//! quadratic model), `Gamma_ijk` (curvature along the step) and `sigma_jj` (the
//! solution's sensitivity to unknown `j`).

use alloc::format;
use alloc::string::String;
use alloc::vec;
use alloc::vec::Vec;

use openmodelica_solvers::omclog;

const STREAM: omclog::Stream = omclog::NLS_NEWTON_DIAGNOSTICS;

/// What the metadata knows about one system, beyond its variable names.
pub struct DiagInfo {
    /// `numberOfEqns`, `numberOfVars`, `numberOfNonlinear` of C's `NONLINEAR_PATTERN`.
    pub pattern: [u32; 3],
    /// The system is in the section C diagnoses: `initialEquations_lambda0`, or
    /// `initialEquations` for a model without a lambda0 section.
    pub init_diag: bool,
    /// SimCode index of each residual equation, in solver order.
    pub eqns: Vec<u32>,
}

/// The model callbacks the report needs.
pub struct Callbacks<'a> {
    /// Residual `f(x)`; returns whether the evaluation hit a model error.
    pub residual: &'a mut dyn FnMut(&[f64], &mut [f64]) -> bool,
    /// Column-major `n×n` symbolic Jacobian at `x`, `fj[c*n + r] = ∂f_r/∂x_c`.
    pub jacobian: &'a mut dyn FnMut(&[f64], &mut [f64]),
}

macro_rules! info {
    ($($arg:tt)*) => { omclog::info!(STREAM, false, $($arg)*) };
}

macro_rules! open {
    ($($arg:tt)*) => { omclog::info!(STREAM, true, $($arg)*) };
}

fn close() {
    omclog::close(STREAM);
}

/// Width of C's `%<w>d` index field, chosen by the system size the way C does.
fn idx(i: usize, m: usize, quirk: bool) -> String {
    let w = if m < 10 {
        1
    } else if m < 100 {
        2
    } else if m < 1000 {
        3
    } else if !quirk && m < 10000 {
        4
    } else {
        5
    };
    format!("{i:>w$}")
}

fn f14(v: f64) -> String {
    omclog::f(v, 14, 10)
}

/// Row-major `m×m` inverse through LU; `None` when singular (C prints and goes on
/// with the partial factorization — the report is then meaningless, so stop).
fn invert(m: usize, a: &[Vec<f64>]) -> Option<Vec<Vec<f64>>> {
    let mut col = vec![0.0f64; m * m];
    for i in 0..m {
        for j in 0..m {
            col[j * m + i] = a[i][j];
        }
    }
    let mut ipiv = vec![0i32; m];
    if openmodelica_lapack::dgetrf(m, m, &mut col, m, &mut ipiv) != 0 {
        return None;
    }
    if openmodelica_lapack::dgetri(m, &mut col, m, &ipiv) != 0 {
        return None;
    }
    Some((0..m).map(|i| (0..m).map(|j| col[j * m + i]).collect()).collect())
}

fn mat_mult(a: &[Vec<f64>], b: &[Vec<f64>]) -> Vec<Vec<f64>> {
    let ra = a.len();
    let cb = b.first().map_or(0, |r| r.len());
    let inner = b.len();
    let mut c = vec![vec![0.0f64; cb]; ra];
    for i in 0..ra {
        for j in 0..cb {
            for k in 0..inner {
                c[i][j] += a[i][k] * b[k][j];
            }
        }
    }
    c
}

/// C's `newtonDiagnostics`. `x0` is the start point, `f` the residual there,
/// `names` the unknowns' names.
pub fn newton_diagnostics(
    eq_index: u32,
    x0: &[f64],
    f: &[f64],
    names: &[String],
    diag: &DiagInfo,
    cb: &mut Callbacks,
) {
    let m = x0.len();
    let name = |j: usize| names.get(j).map_or("", |s| s.as_str());
    let mut lambda = 1.0f64;
    info!("Running newton diagnostics for system {eq_index}");

    // fx[i][j] = ∂f_i/∂x_j
    let mut fj = vec![0.0f64; m * m];
    (cb.jacobian)(x0, &mut fj);
    let fx: Vec<Vec<f64>> = (0..m).map(|i| (0..m).map(|j| fj[j * m + i]).collect()).collect();

    // First Newton step dx = -fx⁻¹ f.
    let mut dx = vec![0.0f64; m];
    {
        let mut a = vec![0.0f64; m * m];
        for i in 0..m {
            for j in 0..m {
                a[j * m + i] = fx[i][j];
            }
        }
        let mut b = f.to_vec();
        let mut ipiv = vec![0i32; m];
        let info_ = openmodelica_lapack::dgesv(m, 1, &mut a, m, &mut ipiv, &mut b, m);
        if info_ > 0 {
            info!(
                "getFirstNewtonStep: the first Newton step could not be computed; the info satus is : {info_}",
            );
        } else {
            for j in 0..m {
                dx[j] = -b[j];
            }
        }
    }

    // Hessian fxx[i][k][j] = ∂fx[i][j]/∂x_k by central differences of the Jacobian.
    let eps = 1.0e-7;
    let nominal_x = 1.0e-4;
    let mut fxx = vec![vec![vec![0.0f64; m]; m]; m];
    let mut fj_pls = vec![0.0f64; m * m];
    let mut fj_min = vec![0.0f64; m * m];
    let mut xp = x0.to_vec();
    for k in 0..m {
        let delta_x = eps * libm::fmax(libm::fabs(x0[k]), nominal_x);
        xp[k] = x0[k] + delta_x;
        (cb.jacobian)(&xp, &mut fj_pls);
        xp[k] = x0[k] - delta_x;
        (cb.jacobian)(&xp, &mut fj_min);
        xp[k] = x0[k];
        for j in 0..m {
            for i in 0..m {
                let v = (fj_pls[j * m + i] - fj_min[j * m + i]) / (2.0 * delta_x);
                if v.is_nan() {
                    info!(
                        "NaN detected: fxx[{}][{}][{}]: fxPls[{}][{}] = {}, fxMin[{}][{}] = {}, delta_x = {}\n",
                        i + 1,
                        j + 1,
                        k + 1,
                        i + 1,
                        j + 1,
                        omclog::f(fj_pls[j * m + i], 0, 6),
                        i + 1,
                        j + 1,
                        omclog::f(fj_min[j * m + i], 0, 6),
                        omclog::f(delta_x, 0, 6),
                    );
                    return;
                }
                fxx[i][k][j] = v;
            }
        }
    }

    // Nonlinear equations: those whose residual is not linear along the step.
    let mut x1 = vec![0.0f64; m];
    let mut f_x1 = vec![0.0f64; m];
    let mut failed = true;
    let mut first = true;
    while failed {
        if !first {
            let d_lambda = 0.7;
            info!(
                "Dampening factor lowered from {} to {}",
                omclog::f(lambda, 7, 3),
                omclog::f(lambda * d_lambda, 7, 3),
            );
            lambda *= d_lambda;
        }
        first = false;
        for i in 0..m {
            x1[i] = x0[i] + lambda * dx[i];
        }
        failed = (cb.residual)(&x1, &mut f_x1);
    }
    let eps_nl = 1.0e-9;
    let n_idx: Vec<usize> =
        (0..m).filter(|&i| libm::fabs(f_x1[i] + (lambda - 1.0) * f[i]) > eps_nl).collect();
    let p = n_idx.len();
    if p == 0 {
        info!("Newton diagnostics terminated: no non-linear equations!");
        return;
    }

    // Nonlinear unknowns: a column of the Hessian with any entry above eps.
    let w_idx: Vec<usize> = (0..m)
        .filter(|&j| (0..m).any(|k| (0..m).any(|i| libm::fabs(fxx[k][i][j]) > eps_nl)))
        .collect();
    let q = w_idx.len();
    let z_idx: Vec<usize> = (0..m).filter(|i| !w_idx.contains(i)).collect();

    open!("Information about the system from non-linear pattern");
    info!("Total number of equations = {}", diag.pattern[0]);
    info!("Number of unknowns = {}", diag.pattern[1]);
    info!("Number of non-linear entries = {}", diag.pattern[2]);
    close();

    open!("Information about the initial guess");
    open!("Vector x0 of unknowns");
    for i in 0..m {
        info!("x0[{}] = {} ({})", idx(i + 1, m, true), f14(x0[i]), name(i));
    }
    close();
    open!("Residual function values of all equations f(x0)");
    for i in 0..m {
        if libm::fabs(f[i]) > 1.0e-9 {
            info!("f[{}] = {}", idx(i + 1, m, false), f14(f[i]));
        }
    }
    close();
    open!("Vector w0 of nonlinear unknowns");
    for i in 0..q {
        // C numbers w0 from q+1 on in the two widest branches.
        let no = if m < 1000 { i + 1 } else { i + q + 1 };
        info!(
            "w0[{}] = x0[{}] = {}  ({})",
            idx(no, m, false),
            idx(w_idx[i] + 1, m, false),
            f14(x0[w_idx[i]]),
            name(w_idx[i]),
        );
    }
    close();
    if m > q {
        open!("Vector z0 of nonlinear unknowns");
        for i in 0..m - q {
            info!("z0[{}] = {} ({})", idx(i + 1, m - q, false), f14(x0[z_idx[i]]), name(z_idx[i]));
        }
        close();
    }
    open!("Residual function values of all nonlinear equations n(w0)");
    for i in 0..p {
        info!(
            "n[{}] = f[{}] = {}",
            idx(i + 1, m, false),
            idx(n_idx[i] + 1, m, false),
            f14(f[n_idx[i]]),
        );
    }
    close();
    info!("Final damping factor lambda = {}", omclog::g(lambda, 0, 3));
    close();

    // Largest residual of the nonlinear part: f + fz·dz over the linear unknowns.
    let mut max_res = 0.0f64;
    for i in 0..m {
        let mut fz_dz = 0.0;
        for &z in &z_idx {
            fz_dz += fx[i][z] * dx[z];
        }
        max_res = libm::fmax(max_res, libm::fabs(f[i] + fz_dz));
    }

    // alpha_i: the residual's departure from its quadratic model at x0 + λ·dx.
    let mut x1_star = vec![0.0f64; m];
    for j in 0..m {
        x1_star[j] = x0[j] + lambda * dx[j];
    }
    let mut f_x1_star = vec![0.0f64; m];
    (cb.residual)(&x1_star, &mut f_x1_star);
    let w1_star_w0: Vec<f64> = w_idx.iter().map(|&w| lambda * dx[w]).collect();
    let mut alpha = vec![0.0f64; p];
    for (i, &ni) in n_idx.iter().enumerate() {
        let mut w_fww_w = 0.0;
        for j in 0..q {
            let mut acc = 0.0;
            for k in 0..q {
                let h = fxx[ni][w_idx[k]][w_idx[j]];
                if !h.is_nan() && h != 0.0 {
                    acc += w1_star_w0[k] * h;
                }
            }
            w_fww_w += acc * w1_star_w0[j];
        }
        alpha[i] = libm::fabs(f_x1_star[ni] - (1.0 - lambda) * f[ni] - 0.5 * w_fww_w)
            / (libm::pow(lambda, 3.0) * max_res);
    }

    // Gamma_ijk: curvature of nonlinear equation i along the step in (w_j, w_k).
    let mut gamma = vec![vec![vec![0.0f64; q]; q]; p];
    for i in 0..p {
        for j in 0..q {
            for k in 0..q {
                let h = fxx[n_idx[i]][w_idx[j]][w_idx[k]];
                gamma[i][j][k] = if !h.is_nan() && h != 0.0 {
                    libm::fabs(0.5 * h * (dx[w_idx[j]] * dx[w_idx[k]]) / max_res)
                } else {
                    0.0
                };
            }
        }
    }

    // Sigma = |diag(dw)⁻¹| · (-fx⁻¹ · (dxᵀ·fxx))[w,w] · diag(dw)
    let Some(mut inv_fx) = invert(m, &fx) else {
        info!("getInvJacobian: LU factorization could not be computed; the info status is : 1");
        return;
    };
    let mut h_i = vec![vec![0.0f64; m]; m];
    for i in 0..m {
        for j in 0..m {
            for k in 0..m {
                h_i[i][j] += dx[k] * fxx[i][k][j];
            }
        }
    }
    for row in inv_fx.iter_mut() {
        for v in row.iter_mut() {
            *v = -*v;
        }
    }
    let tmp1 = mat_mult(&inv_fx, &h_i);
    let tmp2: Vec<Vec<f64>> = (0..q).map(|i| (0..q).map(|j| tmp1[w_idx[i]][w_idx[j]]).collect()).collect();
    let mut w_diag = vec![vec![0.0f64; q]; q];
    for i in 0..q {
        w_diag[i][i] = dx[w_idx[i]];
    }
    let Some(mut inv_w) = invert(q, &w_diag) else {
        info!("getInvJacobian: LU factorization could not be computed; the info status is : 1");
        return;
    };
    for row in inv_w.iter_mut() {
        for v in row.iter_mut() {
            *v = libm::fabs(*v);
        }
    }
    let sigma = mat_mult(&mat_mult(&inv_w, &tmp2), &w_diag);

    print_results(m, p, q, &n_idx, &w_idx, x0, &alpha, &gamma, &sigma, names, diag);
    info!("Newton diagnostics complete!");
}

/// C's `PrintResults`: the indicators above `eps`, then ranked by variable and by
/// equation.
fn print_results(
    m: usize,
    p: usize,
    q: usize,
    n_idx: &[usize],
    w_idx: &[usize],
    x0: &[f64],
    alpha: &[f64],
    gamma: &[Vec<Vec<f64>>],
    sigma: &[Vec<f64>],
    names: &[String],
    diag: &DiagInfo,
) {
    let name = |j: usize| names.get(j).map_or("", |s| s.as_str());
    let eps = 1.0e-2;
    open!("Values of relevant indicators");
    open!("alpha_i > {}", omclog::f(eps, 5, 3));
    for i in 0..p {
        if alpha[i] > eps {
            info!("alpha_{:<3} = {}", n_idx[i] + 1, omclog::f(alpha[i], 5, 2));
        }
    }
    close();
    open!("Gamma_ijk > {}", omclog::f(eps, 5, 3));
    for i in 0..p {
        for j in 0..q {
            for k in j..q {
                if gamma[i][j][k] > eps {
                    info!(
                        "Gamma_{:<4}_{:<4}_{:<4} =  {}",
                        n_idx[i] + 1,
                        w_idx[j] + 1,
                        w_idx[k] + 1,
                        omclog::f(gamma[i][j][k], 5, 2),
                    );
                }
            }
        }
    }
    close();
    open!("sigma_jj > {}", omclog::f(eps, 5, 3));
    for i in 0..q {
        if libm::fabs(sigma[i][i]) > eps {
            info!(
                "sigma_{:<4}_{:<4} = {}",
                w_idx[i] + 1,
                w_idx[i] + 1,
                omclog::f(libm::fabs(sigma[i][i]), 5, 2),
            );
        }
    }
    close();
    close();

    // Rank Gamma and sigma together, largest first, down to eps.
    enum Pick {
        Gamma(usize, usize, usize),
        Scalar(usize),
    }
    let rank = |scalars: &[f64], scalar_idx: &dyn Fn(usize) -> f64| -> Vec<Pick> {
        let mut gamma_checked = vec![vec![vec![false; q]; q]; p];
        let mut scalar_checked = vec![false; scalars.len()];
        let mut picks = Vec::new();
        for _ in 0..p * q * q + m {
            let mut best_g = -1.0e10;
            let mut gi = (0, 0, 0);
            for i in 0..p {
                for j in 0..q {
                    for k in j..q {
                        if gamma[i][j][k] > best_g && !gamma_checked[i][j][k] {
                            best_g = gamma[i][j][k];
                            gi = (i, j, k);
                        }
                    }
                }
            }
            let mut best_s = -1.0e10;
            let mut si = 0;
            for i in 0..scalars.len() {
                let v = scalar_idx(i);
                if v > best_s && !scalar_checked[i] {
                    best_s = v;
                    si = i;
                }
            }
            if best_g < eps && best_s < eps {
                break;
            }
            if best_g > best_s {
                gamma_checked[gi.0][gi.1][gi.2] = true;
                picks.push(Pick::Gamma(gi.0, gi.1, gi.2));
            } else {
                scalar_checked[si] = true;
                picks.push(Pick::Scalar(si));
            }
        }
        picks
    };

    open!("Ranked indicators");
    open!("By variable");
    info!("Var no.  Var name                                  Initial guess  max(Gamma,sigma)");
    info!("-------  ----------------------------------------  -------------  ----------------");
    let sig_diag: Vec<f64> = (0..q).map(|i| libm::fabs(sigma[i][i])).collect();
    let mut printed: Vec<usize> = Vec::new();
    for pick in rank(&sig_diag, &|i| sig_diag[i]) {
        match pick {
            Pick::Scalar(s) => {
                if !printed.contains(&s) {
                    info!(
                        "{:>7}  {:>40}  {}    {}",
                        w_idx[s] + 1,
                        name(w_idx[s]),
                        omclog::g(x0[w_idx[s]], 13, 7),
                        omclog::f(sig_diag[s], 5, 2),
                    );
                    printed.push(s);
                }
            }
            Pick::Gamma(i, j, k) => {
                let pj = printed.contains(&j);
                let pk = printed.contains(&k);
                for (already, v) in [(pj, j), (pk, k)] {
                    if !already {
                        info!(
                            "{:>7}  {:>40}  {}  {}",
                            w_idx[v] + 1,
                            name(w_idx[v]),
                            omclog::g(x0[w_idx[v]], 13, 7),
                            omclog::f(gamma[i][j][k], 5, 2),
                        );
                        printed.push(v);
                    }
                }
            }
        }
    }
    close();

    open!("By equation");
    info!("Eq no.  Eq idx    max(alpha,Gamma)");
    info!("------  ------    ----------------");
    let eq_idx = |i: usize| diag.eqns.get(i).copied().unwrap_or(0);
    let mut printed: Vec<usize> = Vec::new();
    for pick in rank(alpha, &|i| alpha[i]) {
        match pick {
            Pick::Scalar(a) => {
                if !printed.contains(&a) {
                    let v = if alpha[a] < 1.0e3 { omclog::f(alpha[a], 5, 2) } else { omclog::e(alpha[a], 5, 2) };
                    info!("{:>6} {:>6} {}", n_idx[a] + 1, eq_idx(n_idx[a]), v);
                    printed.push(a);
                }
            }
            Pick::Gamma(i, j, k) => {
                if !printed.contains(&i) {
                    info!(
                        "{:>6}  {:>6}  {}",
                        n_idx[i] + 1,
                        eq_idx(n_idx[i]),
                        omclog::f(gamma[i][j][k], 5, 2),
                    );
                    printed.push(i);
                }
            }
        }
    }
    close();
    close();
}
