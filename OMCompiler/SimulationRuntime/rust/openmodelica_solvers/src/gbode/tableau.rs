//! Butcher tableaux and the per-method options attached to them, mirroring C's
//! `gbode_tableau.c`/`.h`. The numeric data itself lives in [`super::tableau_data`],
//! which is generated from the C file; this module is the structure it fills in and
//! the queries the solver makes of it.

use alloc::vec;
use alloc::vec::Vec;

use crate::gbode::math::abs;

pub use super::tableau_data::GbMethod;

/// C's `enum GB_ERROR_METHOD` (`-gberr`).
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum ErrMethod {
    /// Whichever of the below the method offers, two-step first.
    Default,
    /// Two half steps plus a full one, extrapolated.
    Richardson,
    /// The tableau's second weight vector `bt`.
    Embedded,
    TwoStep,
    Contractive,
    /// The contractive filter applied to the embedded estimator.
    Filter,
}

/// C's `enum GM_TYPE`: how the `A` matrix constrains the step function.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum GmType {
    /// `A` is strictly lower triangular.
    Explicit,
    /// `A` is triangular with a nonzero diagonal: one `nStates` solve per stage.
    Dirk,
    /// `A` has elements above the diagonal: one coupled `nStages*nStates` solve.
    Implicit,
    /// `A == 0`, an implicit multi-step method (`adams`).
    MultiStep,
}

/// C's `STAGE_VALUE_PREDICTOR_TYPE`.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum SvpType {
    NotAvailable,
    LinearCombination,
    DenseOutput,
}

/// Fills `b_dt` with the dense-output weights at `dt` (the normalized position in
/// the step). C passes these as a function pointer per method.
pub type DenseOutputFn = fn(&mut [f64], f64);

/// Evaluates the variable-step two-step weights at the step ratio `r = h_new/h_old`
/// and returns `mu(r)`. The weights always act in K-space:
///
/// ```text
///     y_emb = y_n + h_old * d_old(r)^T * K_old + h_new * g_new(r)^T * K_new
/// ```
///
/// and the estimate is `err = mu(r) * (y_main - y_emb)`.
pub type TwoStepWeightsFn = fn(f64, &mut [f64], &mut [f64]) -> f64;

/// C's `T_TRANSFORM`: `T^-1 * A^-1 * T = Lambda + L` diagonalizes (or lower
/// block-triangularizes) the Runge-Kutta matrix, so the coupled `(s*N)x(s*N)` FIRK
/// system becomes a few sequential `NxN` ones — real systems for the real
/// eigenvalues of `A^-1`, 2x2 real blocks for the complex conjugate pairs. That
/// turns `O((s*N)^3)` into `C*s*O(N^3)` with `C <= 2`: 3-stage Radau IIA goes from
/// `27*N^3` to `5*N^3`, 6-stage Gauss from `216*N^3` to `12*N^3`. Methods with
/// explicit stages (Lobatto IIIA/IIIB) transform only the implicit part, which is
/// why the transformed system's size is `size`, not `nStages`.
///
/// `T`, `T^-1` and `Lambda` must be permuted so the real scalar rows come first and
/// the complex 2x2 blocks follow; any leftover coupling lives in the strictly lower
/// triangular `L` and is handled by forward substitution.
///
/// Consumed by [`super::nls`]'s `solve_firk_t`; a FIRK tableau without one gets
/// the coupled solve instead.
pub struct TTransform {
    pub a_part_inv: Vec<f64>,
    pub t: Vec<f64>,
    pub t_inv: Vec<f64>,
    pub gamma: Vec<f64>,
    pub alpha: Vec<f64>,
    pub beta: Vec<f64>,
    pub real_eigenvalue_index: Vec<usize>,
    pub complex_eigenpair_index: Vec<usize>,
    pub l: Vec<f64>,
    pub has_l: Vec<bool>,
    pub phi: Option<Vec<f64>>,
    pub rho: Option<Vec<f64>>,
    pub first_row_zero: bool,
    pub last_column_zero: bool,
    pub n_real_eigenvalues: usize,
    pub n_complex_eigenpairs: usize,
    pub n_real_blocks: usize,
    pub n_complex_blocks: usize,
    pub size: usize,
}

/// C's `STAGE_VALUE_PREDICTORS`: because an (E)SDIRK method is solved stage by
/// stage in order, a linear combination of the already-known `k_1..k_{s-1}` is a
/// good and stable prediction of stage `s` — an explicit EDIRK row alongside the
/// implicit one. See Carpenter et al., "Intrastep, Stage-Value Predictors for
/// Diagonally-Implicit Runge-Kutta Methods" (NASA-TM-20240008442).
pub struct Svp {
    pub a_predictor: Vec<f64>,
    pub types: Vec<SvpType>,
    pub dense_output_predictor: Option<DenseOutputFn>,
}

/// One error estimator, as selected by `-gberr` / the method's default.
#[derive(Clone, Copy)]
pub struct Estimator {
    pub kind: ErrMethod,
    pub order: i32,
}

/// C's `BUTCHER_TABLEAU`:
///
/// ```text
///     c_1 | a_1_1   a_1_2   ...   a_1_s
///     c_2 | a_2_1   a_2_2   ...   a_2_s
///     ... |
///     c_s | a_s_1   a_s_2   ...   a_s_s
///     ---------------------------------
///         | b_1     b_2     ...   b_s
///         | bt_1    bt_2    ...   bt_s
/// ```
pub struct Tableau {
    pub n_stages: usize,
    pub order_b: i32,
    pub order_bt: i32,
    pub error_order: i32,
    pub fac: f64,
    pub richardson: bool,
    /// Row-major `n_stages * n_stages`.
    pub a: Vec<f64>,
    pub b: Vec<f64>,
    pub bt: Option<Vec<f64>>,
    pub c: Vec<f64>,
    pub with_dense_output: bool,
    pub dense_output: Option<DenseOutputFn>,
    pub k_left: bool,
    pub k_right: bool,
    pub t_transform: Option<TTransform>,
    /// `d(0)^T * A` for the contractive-defect estimator.
    pub contractive_dt_a: Option<Vec<f64>>,
    pub svp: Option<Svp>,
    /// Available estimators, filled in by the `set_*` builders below.
    pub embedded: Option<Estimator>,
    pub contractive_defect: Option<Estimator>,
    pub contractive_filter: Option<Estimator>,
    pub two_step: Option<Estimator>,
    pub two_step_weights: Option<TwoStepWeightsFn>,
    /// The one `-gberr` asked for, resolved by [`finalize_error`].
    pub active: Estimator,
    pub error_method: ErrMethod,
    pub gm_type: GmType,
}

impl Tableau {
    pub fn new(richardson: bool) -> Self {
        Tableau {
            n_stages: 0,
            order_b: 0,
            order_bt: 0,
            error_order: 0,
            fac: 1.0,
            richardson,
            a: Vec::new(),
            b: Vec::new(),
            bt: None,
            c: Vec::new(),
            with_dense_output: false,
            dense_output: None,
            k_left: false,
            k_right: false,
            t_transform: None,
            contractive_dt_a: None,
            svp: None,
            embedded: None,
            contractive_defect: None,
            contractive_filter: None,
            two_step: None,
            two_step_weights: None,
            active: Estimator { kind: ErrMethod::Default, order: 0 },
            error_method: ErrMethod::Default,
            gm_type: GmType::Explicit,
        }
    }

    pub fn a_at(&self, row: usize, col: usize) -> f64 {
        self.a[row * self.n_stages + col]
    }

    /// C's `denseOutput`: `y = yOld + dt*h * (K otimes I) * b_dt`, over `idx` when
    /// given. `b_dt` is scratch of `n_stages` entries.
    pub fn dense_out(
        &self,
        b_dt: &mut [f64],
        y_old: &[f64],
        k: &[f64],
        dt: f64,
        step_size: f64,
        y: &mut [f64],
        idx: Option<&[usize]>,
        n_states: usize,
    ) {
        let f = self.dense_output.expect("dense output requested without a formula");
        f(b_dt, dt);
        let scale = dt * step_size;
        match idx {
            None => {
                for i in 0..n_states {
                    let mut acc = 0.0;
                    for stage in 0..self.n_stages {
                        acc += b_dt[stage] * k[stage * n_states + i];
                    }
                    y[i] = y_old[i] + scale * acc;
                }
            }
            Some(ix) => {
                for &i in ix {
                    let mut acc = 0.0;
                    for stage in 0..self.n_stages {
                        acc += b_dt[stage] * k[stage * n_states + i];
                    }
                    y[i] = y_old[i] + scale * acc;
                }
            }
        }
    }
}

/// C's `setButcherTableau`.
pub(super) fn set_butcher(t: &mut Tableau, c: &[f64], a: &[f64], b: &[f64], bt: Option<&[f64]>) {
    let n = t.n_stages;
    debug_assert_eq!(c.len(), n);
    debug_assert_eq!(a.len(), n * n);
    debug_assert_eq!(b.len(), n);
    t.c = c.to_vec();
    t.a = a.to_vec();
    t.b = b.to_vec();
    t.bt = bt.map(|v| v.to_vec());
    t.with_dense_output = false;
    t.k_left = false;
    t.k_right = false;
    t.t_transform = None;
    // C's `setEmbeddedErrorEstimator`.
    if t.bt.is_some() {
        t.embedded = Some(Estimator { kind: ErrMethod::Embedded, order: t.order_b.min(t.order_bt) });
    }
}

/// C's `setTTransform`.
#[allow(clippy::too_many_arguments)]
pub(super) fn set_t_transform(
    t: &mut Tableau,
    a_part_inv: &[f64],
    tm: &[f64],
    t_inv: &[f64],
    gamma: Option<&[f64]>,
    alpha: Option<&[f64]>,
    beta: Option<&[f64]>,
    first_row_zero: bool,
    last_column_zero: bool,
    n_real: usize,
    n_cmplx: usize,
    phi: Option<&[f64]>,
    rho: Option<&[f64]>,
) {
    set_t_transform_lower(
        t, a_part_inv, tm, t_inv, gamma, alpha, beta, first_row_zero, last_column_zero, n_real,
        n_cmplx, n_real, n_cmplx, None, None, None, None, phi, rho,
    );
}

/// C's `setTTransformLowerTriangular`.
#[allow(clippy::too_many_arguments)]
pub(super) fn set_t_transform_lower(
    t: &mut Tableau,
    a_part_inv: &[f64],
    tm: &[f64],
    t_inv: &[f64],
    gamma: Option<&[f64]>,
    alpha: Option<&[f64]>,
    beta: Option<&[f64]>,
    first_row_zero: bool,
    last_column_zero: bool,
    n_real_blocks: usize,
    n_cmplx_blocks: usize,
    n_real_eigs: usize,
    n_cmplx_eigs: usize,
    real_eig_index: Option<&[usize]>,
    cmplx_eig_index: Option<&[usize]>,
    l: Option<&[f64]>,
    has_l: Option<&[bool]>,
    phi: Option<&[f64]>,
    rho: Option<&[f64]>,
) {
    let size = n_real_blocks + 2 * n_cmplx_blocks;
    debug_assert_eq!(
        size,
        t.n_stages - usize::from(first_row_zero) - usize::from(last_column_zero)
    );
    t.t_transform = Some(TTransform {
        a_part_inv: a_part_inv[..size * size].to_vec(),
        t: tm[..size * size].to_vec(),
        t_inv: t_inv[..size * size].to_vec(),
        gamma: gamma.map(|g| g[..n_real_eigs].to_vec()).unwrap_or_default(),
        alpha: alpha.map(|g| g[..n_cmplx_eigs].to_vec()).unwrap_or_default(),
        beta: beta.map(|g| g[..n_cmplx_eigs].to_vec()).unwrap_or_default(),
        real_eigenvalue_index: real_eig_index
            .map(|v| v[..n_real_blocks].to_vec())
            .unwrap_or_else(|| (0..n_real_blocks).collect()),
        complex_eigenpair_index: cmplx_eig_index
            .map(|v| v[..n_cmplx_blocks].to_vec())
            .unwrap_or_else(|| (0..n_cmplx_blocks).collect()),
        l: l.map(|v| v[..size * (size - 1) / 2].to_vec())
            .unwrap_or_else(|| vec![0.0; size * (size - 1) / 2]),
        has_l: has_l.map(|v| v[..size].to_vec()).unwrap_or_else(|| vec![false; size]),
        phi: phi.map(|v| v[..size].to_vec()),
        rho: rho.map(|v| v[..size].to_vec()),
        first_row_zero,
        last_column_zero,
        n_real_eigenvalues: n_real_eigs,
        n_complex_eigenpairs: n_cmplx_eigs,
        n_real_blocks,
        n_complex_blocks: n_cmplx_blocks,
        size,
    });
}

/// C's `setContractiveDefectError`.
///
/// An embedded estimate is poor for a superconvergent FIRK method: it can reach
/// order `s-1` for `s` stages while the method itself is order `2s` (Gauss),
/// `2s-1` (Radau) or `2s-2` (Lobatto), which leaves the estimate non-A-stable. For
/// a collocation method with at least one real eigenvalue `gamma` of `A^-1` and `0`
/// as a non-collocated point there is an A-stable estimate of order `s` costing one
/// extra function evaluation and one LU solve:
///
/// ```text
///     ERR = (I - h*gamma*J)^-1 * h*gamma * (f(x0, y0) - d(0)^T * A * k)
/// ```
///
/// where `d(0)` are the differentiation matrix's weights at node 0. The Newton
/// iteration already has the factorization of `1/(h*gamma)*I - J`, so what is
/// actually computed is `ERR = (1/(h*gamma)*I - J)^-1 * (f(x0,y0) - d(0)^T*A*k)`.
///
/// Theory: Shampine & Baka, "Error estimators for stiff differential equations";
/// Hairer & Wanner, "Solving Ordinary Differential Equations II" p.123 (the Radau
/// IIA estimate); Gonzalez-Pinto et al., "Two-step error estimators for implicit
/// Runge-Kutta methods applied to stiff systems".
pub(super) fn set_contractive_defect(t: &mut Tableau, dt_a: Option<&[f64]>, only_filter: bool) {
    if t.t_transform.is_none() && !only_filter {
        return;
    }
    if only_filter {
        if t.bt.is_some() {
            t.contractive_filter =
                Some(Estimator { kind: ErrMethod::Filter, order: t.order_b.min(t.order_bt) });
        }
        return;
    }
    t.contractive_dt_a = dt_a.map(|v| v[..t.n_stages].to_vec());
    t.contractive_defect =
        Some(Estimator { kind: ErrMethod::Contractive, order: t.n_stages as i32 });
}

/// C's `setTwoStepErrorEstimator`, in the spirit of Gonzalez-Pinto et al.,
/// "Two-step error estimators for implicit Runge-Kutta methods applied to stiff
/// systems": reuse the previous accepted step's stage derivatives alongside this
/// step's (see [`TwoStepWeightsFn`]).
///
/// The pole-free weights `d`/`g` hold a fixed exact order for every `r > 0`, and
/// `mu(r)` removes the step-ratio dependence of the estimator's leading non-stiff
/// term so a standard controller can consume it: comparing the controller feedback
/// of the estimate against that of the exact local error and cancelling the powers
/// of the tolerance gives `mu(r) = scale / |C_est(r)|`. Where Gonzalez-Pinto et al.
/// achieve the same cancellation by modifying the controller, this treats it as a
/// property of the estimate, which is scaled before the controller sees it.
pub(super) fn set_two_step(t: &mut Tableau, order: i32, weights: TwoStepWeightsFn) {
    t.two_step_weights = Some(weights);
    t.two_step = Some(Estimator { kind: ErrMethod::TwoStep, order });
}

/// C's `setStageValuePredictors`.
pub(super) fn set_svp(
    t: &mut Tableau,
    a_pred: &[f64],
    types: &[SvpType],
    dense_pred: Option<DenseOutputFn>,
) {
    t.svp = Some(Svp {
        a_predictor: a_pred[..t.n_stages * t.n_stages].to_vec(),
        types: types[..t.n_stages].to_vec(),
        dense_output_predictor: dense_pred,
    });
}

/// C's `horner`.
pub(super) fn horner(coefficients: &[f64], x: f64) -> f64 {
    let mut y = 0.0;
    for &c in coefficients.iter().rev() {
        y = y * x + c;
    }
    y
}

/// C's `evaluateTwoStepRationalWeights`.
pub(super) fn two_step_rational_weights(
    n_stages: usize,
    r: f64,
    denominator: &[f64],
    denominator_size: usize,
    numerators: &[&[f64]],
    numerator_sizes: &[usize],
    d_old: &mut [f64],
    g_new: &mut [f64],
) {
    let q = horner(&denominator[..denominator_size], r);
    for stage in 0..n_stages {
        d_old[stage] = horner(&numerators[stage][..numerator_sizes[stage]], r) / q;
        g_new[stage] =
            horner(&numerators[n_stages + stage][..numerator_sizes[n_stages + stage]], r) / q;
    }
}

/// C's `evaluateTwoStepMu`.
pub(super) fn two_step_mu(
    r: f64,
    scale: f64,
    num: &[f64],
    num_size: usize,
    den: &[f64],
    den_size: usize,
) -> f64 {
    let n = horner(&num[..num_size], r);
    let d = horner(&den[..den_size], r);
    if !n.is_finite() || !d.is_finite() || abs(n) < 1e-300 {
        return 1e1;
    }
    scale * abs(d) / abs(n)
}

/// C's `initButcherTableau` + `analyseButcherTableau`: build the tableau for
/// `method` and classify it. Returns the tableau and the size of the nonlinear
/// system one step has to solve.
pub(super) fn init(method: GbMethod, err_method: ErrMethod, n_states: usize) -> (Tableau, usize) {
    let richardson = err_method == ErrMethod::Richardson;
    let mut t = super::tableau_data::build(method, richardson);
    t.error_method = err_method;
    // `getButcherTableau_MS` clears it again; keep the tableau's own word for it.
    let mut is_generic_irk = false;
    let mut is_dirk = false;
    for i in 0..t.n_stages {
        if abs(t.a_at(i, i)) > 0.0 {
            is_dirk = true;
        }
        for j in i + 1..t.n_stages {
            if abs(t.a_at(i, j)) > 0.0 {
                is_generic_irk = true;
                break;
            }
        }
    }
    // C keys `MS_TYPE_IMPLICIT` off the method, not off `A`; `adams` is the only one.
    let (gm_type, nls_size) = if method == GbMethod::MS_ADAMS_MOULTON {
        (GmType::MultiStep, n_states)
    } else if is_generic_irk {
        (GmType::Implicit, t.n_stages * n_states)
    } else if is_dirk {
        (GmType::Dirk, n_states)
    } else {
        (GmType::Explicit, 0)
    };
    t.gm_type = gm_type;
    if t.richardson {
        t.fac = 1.0;
        t.order_bt = t.order_b + 1;
    }
    (t, nls_size)
}

/// C's `finalizeButcherTableauError`: pick the estimator `-gberr` asked for, after
/// the NLS method is known (the contractive ones need the internal solver).
/// Returns the fallback the two-step estimator uses when it has no history.
pub(super) fn finalize_error(
    t: &mut Tableau,
    internal_nls: bool,
) -> Result<Option<Estimator>, &'static str> {
    // C's `ensureContractiveFilterError`.
    if internal_nls
        && t.contractive_filter.is_none()
        && let Some(emb) = t.embedded
        && t.t_transform.as_ref().is_some_and(|tr| tr.n_real_eigenvalues > 0)
    {
        t.contractive_filter = Some(Estimator { kind: ErrMethod::Filter, order: emb.order });
    }
    let best_non_two_step = |t: &Tableau| -> Option<Estimator> {
        if internal_nls && t.contractive_defect.is_some() {
            return t.contractive_defect;
        }
        if internal_nls && t.contractive_filter.is_some() {
            return t.contractive_filter;
        }
        t.embedded
    };
    let selected = match t.error_method {
        ErrMethod::Default => {
            if t.two_step.is_some() {
                t.two_step
            } else {
                best_non_two_step(t)
            }
        }
        ErrMethod::Richardson => {
            t.active = Estimator { kind: ErrMethod::Richardson, order: t.order_b };
            t.error_order = t.order_b;
            return Ok(None);
        }
        ErrMethod::Embedded => t.embedded,
        ErrMethod::TwoStep => t.two_step,
        ErrMethod::Contractive => {
            if !internal_nls {
                return Err("Selected contractive defect error estimator is only available with -gbnls=internal.");
            }
            t.contractive_defect
        }
        ErrMethod::Filter => {
            if !internal_nls {
                return Err("Selected contractive filter error estimator is only available with -gbnls=internal.");
            }
            t.contractive_filter
        }
    };
    let Some(selected) = selected else {
        return Err("Selected GBODE error estimator is not available for this Runge-Kutta method.");
    };
    let mut fallback = None;
    if selected.kind == ErrMethod::TwoStep {
        fallback = best_non_two_step(t);
        if fallback.is_none() {
            return Err("Two-step error estimator requires an embedded, contractive defect, or contractive filter fallback.");
        }
    }
    t.active = selected;
    t.error_order = selected.order;
    Ok(fallback)
}
