//! The error estimators, a port of C's `gbode_err.c`. Each one writes `|error|`
//! per state into `errest` and returns its order, which the step size controller
//! uses as the method order.

use alloc::vec;
use alloc::vec::Vec;

use super::tableau::{ErrMethod, Estimator};
use super::{Gbode, Ode};
use crate::driver::Result;
use crate::gbode::math::{abs, pow};

/// C's `MAX_GBODE_FIRK_STAGES`: the two-step estimator's weight tables only go
/// this far.
const MAX_GBODE_FIRK_STAGES: usize = 8;

impl Gbode {
    /// C's `gbEstimateError`: run the active estimator and record its order as the
    /// one the controller works with. `None` ⇒ the estimator failed and the step
    /// must be rejected.
    pub(super) fn estimate_error(&mut self, ode: &mut Ode) -> Result<Option<i32>> {
        let active = self.tableau.active;
        let order = self.evaluate_error(ode, Some(active))?;
        if let Some(order) = order {
            self.current_error_order = order;
        }
        Ok(order)
    }

    /// C's `evaluateError`, dispatching on the estimator kind.
    fn evaluate_error(
        &mut self,
        ode: &mut Ode,
        estimator: Option<Estimator>,
    ) -> Result<Option<i32>> {
        let Some(est) = estimator else { return Ok(None) };
        match est.kind {
            ErrMethod::Embedded => {
                let Some(bt) = self.tableau.bt.clone() else { return Ok(None) };
                self.embedded_estimate(&bt);
                Ok(Some(est.order))
            }
            // `gbode_richardson` already left the signed error in `yt`; the main
            // loop turns that into `errest`.
            ErrMethod::Richardson => Ok(Some(est.order)),
            ErrMethod::TwoStep => {
                if self.two_step_estimate(est.order) {
                    Ok(Some(est.order))
                } else {
                    let fallback = self.two_step_fallback;
                    self.evaluate_error(ode, fallback)
                }
            }
            ErrMethod::Contractive => self.contractive_defect_estimate(ode).map(|()| Some(est.order)),
            ErrMethod::Filter => {
                let Some(bt) = self.tableau.bt.clone() else { return Ok(None) };
                self.embedded_estimate(&bt);
                let step_size = self.step_size;
                let Some(nls) = self.nls.as_mut() else { return Ok(None) };
                nls.contractive_filter(&self.tableau, step_size, &mut self.errest)?;
                for v in &mut self.errest {
                    *v = abs(*v);
                }
                Ok(Some(est.order))
            }
            ErrMethod::Default => Ok(None),
        }
    }

    /// C's `embeddedErrorEstimate_gb` + `absErrorEstimate_gb`:
    /// `errest = |h * (K otimes I) * (b - bt)|`.
    fn embedded_estimate(&mut self, weights: &[f64]) {
        let n = self.n_states;
        let n_stages = self.tableau.n_stages;
        for i in 0..n {
            let mut acc = 0.0;
            for stage in 0..n_stages {
                acc += self.step_size * (self.tableau.b[stage] - weights[stage])
                    * self.k[stage * n + i];
            }
            self.errest[i] = abs(acc);
        }
    }

    /// C's `twoStepEstimate_gb`: build the embedded solution from the previous
    /// step's stage derivatives as well as this step's. `false` ⇒ no usable
    /// history, use the fallback estimator.
    fn two_step_estimate(&mut self, estimator_order: i32) -> bool {
        let n = self.n_states;
        let n_stages = self.tableau.n_stages;
        if n_stages > MAX_GBODE_FIRK_STAGES
            || self.last_step_size <= 0.0
            || self.extrapolation_base_time == f64::INFINITY
            || self.event_happened
        {
            return false;
        }
        let Some(weights) = self.tableau.two_step_weights else { return false };
        let r = self.step_size / self.last_step_size;
        let mut d_old = vec![0.0; n_stages];
        let mut g_new = vec![0.0; n_stages];
        let mut mu = weights(r, &mut d_old, &mut g_new);
        if !self.scale_two_step_mu(estimator_order, &mut mu) {
            return false;
        }
        for stage in 0..n_stages {
            d_old[stage] *= self.last_step_size;
            g_new[stage] *= self.step_size;
        }
        for i in 0..n {
            let mut y_emb = self.y_old[i];
            for stage in 0..n_stages {
                y_emb += d_old[stage] * self.k_last[stage * n + i]
                    + g_new[stage] * self.k[stage * n + i];
            }
            self.errest[i] = abs(mu * (self.y[i] - y_emb));
        }
        true
    }

    /// C's `twoStepScaleMu`: map the tabulated `mu(r)` onto gbode's scaled
    /// tolerance, and reject the estimate if it came out degenerate.
    fn scale_two_step_mu(&self, estimator_order: i32, mu: &mut f64) -> bool {
        let method_order = self.tableau.order_b;
        let tol = self.tol;
        let scaled_tol = {
            // `gbScaledErrorTolerance` with this estimator's order, not the
            // currently recorded one.
            if self.tableau.richardson || estimator_order >= method_order {
                tol
            } else {
                let q = (estimator_order as f64 + 1.0) / (method_order as f64 + 1.0);
                tol.max(super::GB_TOLERANCE_SCALING_SAFETY * pow(tol, q))
            }
        };
        let order_quot = (estimator_order as f64 + 1.0) / (method_order as f64 + 1.0);
        *mu *= scaled_tol / pow(tol, order_quot);
        if !mu.is_finite() {
            return false;
        }
        if abs(*mu) < 1e-6 || abs(*mu) > 1e6 {
            return false;
        }
        true
    }

    /// C's `gbContractiveDefectErrorEstimator`.
    fn contractive_defect_estimate(&mut self, ode: &mut Ode) -> Result<()> {
        let n = self.n_states;
        let n_stages = self.tableau.n_stages;
        // C reuses `kRight` of the previous step as `f(t_n, y_n)` when the method
        // collocates the right end point and the last step is still valid.
        let sr_valid = self.time != self.start_time
            && !self.event_happened
            && self.extrapolation_base_time != f64::INFINITY;
        let f_left: Option<Vec<f64>> = (self.tableau.k_right && sr_valid)
            .then(|| self.k_last[(n_stages - 1) * n..n_stages * n].to_vec());
        let (time, step_size) = (self.time, self.step_size);
        let (k, y_old) = (self.k.clone(), self.y_old.clone());
        let Some(nls) = self.nls.as_mut() else {
            return Err("CodegenWasmJit: gbode: contractive defect without an internal NLS");
        };
        nls.contractive_defect(
            ode,
            &self.tableau,
            time,
            step_size,
            &y_old,
            &k,
            f_left.as_deref(),
            &mut self.errest,
        )?;
        for v in &mut self.errest {
            *v = abs(*v);
        }
        Ok(())
    }
}
