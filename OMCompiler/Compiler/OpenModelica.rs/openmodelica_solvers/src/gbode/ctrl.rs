//! Step size controllers, a port of C's `gbode_ctrl.c`. `GenericController`
//! dispatches to the P/PI/PID families (see Hairer et al.); all of them return a
//! factor the caller multiplies the step size by.
//!
//! The predictive variants add a step-ratio term:
//! `h_fac = (1/err_0)^(a1/k) * (1/err_-1)^(a2/k) * (h/h_-1)^ratio`.

use super::conf::{CtrlMethod, GbConf};
use crate::gbode::math::{abs, ln, pow, sqrt};

const DBL_EPSILON: f64 = f64::EPSILON;

/// C's `PIController`.
fn pi_controller(err: &[f64], err_order: i32, m: CtrlMethod) -> f64 {
    let k = (err_order + 1) as f64;
    let (err_n, err_n1) = (err[0], err[1]);
    if err_n1 < DBL_EPSILON {
        return pow(1.0 / err_n, 1.0 / k);
    }
    let (beta1, beta2) = match m {
        CtrlMethod::Pi34 => (0.7 / k, -0.4 / k),
        CtrlMethod::Pi33 => ((2.0 / 3.0) / k, (-1.0 / 3.0) / k),
        CtrlMethod::Pi42 => (0.6 / k, -0.2 / k),
        _ => unreachable!("pi_controller: not a PI method"),
    };
    pow(1.0 / err_n, beta1) * pow(1.0 / err_n1, beta2)
}

/// C's `PIDController`.
fn pid_controller(err: &[f64], err_order: i32, m: CtrlMethod) -> f64 {
    let k = (err_order + 1) as f64;
    let (err_n, err_n1, err_n2) = (err[0], err[1], err[2]);
    if err_n1 < DBL_EPSILON || err_n2 < DBL_EPSILON {
        return pow(1.0 / err_n, 1.0 / k);
    }
    let (beta1, beta2, beta3) = match m {
        CtrlMethod::PidH312 => (1. / 18. / k, 1. / 9. / k, 1. / 18. / k),
        CtrlMethod::PidSoederlind => (0.1 / k, 0.2 / k, 0.1 / k),
        CtrlMethod::PidStiff => (0.58 / k, 0.21 / k, 0.21 / k),
        _ => unreachable!("pid_controller: not a PID method"),
    };
    pow(1.0 / err_n, beta1) * pow(1.0 / err_n1, beta2) * pow(1.0 / err_n2, beta3)
}

/// C's `PredictivePIController`.
fn predictive_pi(err: &[f64], step: &[f64], err_order: i32, m: CtrlMethod) -> f64 {
    let k = (err_order + 1) as f64;
    let (err_n, err_n1) = (err[0], err[1]);
    let (h, h_n1) = (step[0], step[1]);
    if err_n1 < DBL_EPSILON || h_n1 < DBL_EPSILON {
        return pow(1.0 / err_n, 1.0 / k);
    }
    let (beta1, beta2, ratio) = match m {
        CtrlMethod::PiPcHybrid | CtrlMethod::PiPc => (2.0 / k, -1.0 / k, 1.0),
        CtrlMethod::PiH211 => (0.25 / k, 0.25 / k, -0.25),
        CtrlMethod::PiH0211 => (0.5 / k, 0.5 / k, -0.5),
        _ => unreachable!("predictive_pi: not a predictive PI method"),
    };
    let pi_pc = pow(1.0 / err_n, beta1) * pow(1.0 / err_n1, beta2) * pow(h / h_n1, ratio);
    if m == CtrlMethod::PiPcHybrid {
        pi_pc.min(pow(1.0 / err_n, 1.0 / k))
    } else {
        pi_pc
    }
}

/// C's `PredictivePIDController`.
fn predictive_pid(err: &[f64], step: &[f64], err_order: i32, m: CtrlMethod) -> f64 {
    let k = (err_order + 1) as f64;
    let (err_n, err_n1, err_n2) = (err[0], err[1], err[2]);
    let (h, h_n1, h_n2) = (step[0], step[1], step[2]);
    if err_n1 < DBL_EPSILON || h_n1 < DBL_EPSILON || err_n2 < DBL_EPSILON || h_n2 < DBL_EPSILON {
        return pow(1.0 / err_n, 1.0 / k);
    }
    let (beta1, beta2, beta3, ratio1, ratio2) = match m {
        CtrlMethod::PidH0312 => (0.25 / k, 0.5 / k, 0.25 / k, -0.75, -0.25),
        CtrlMethod::PidH0321 => (1.25 / k, 0.5 / k, -0.75 / k, 0.25, 0.75),
        CtrlMethod::Ppid => ((6. / 20.) / k, (1. / 20.) / k, (-5. / 20.) / k, 1.0, 0.0),
        _ => unreachable!("predictive_pid: not a predictive PID method"),
    };
    pow(1.0 / err_n, beta1)
        * pow(1.0 / err_n1, beta2)
        * pow(1.0 / err_n2, beta3)
        * pow(h / h_n1, ratio1)
        * pow(h_n1 / h_n2, ratio2)
}

/// C's `computeGamma`.
fn compute_gamma(err_now: f64, err_prev: f64, h_now: f64, h_prev: f64, eta: f64) -> f64 {
    let log_h_ratio = ln(h_now / h_prev);
    let log_e_ratio = ln((err_now + DBL_EPSILON) / (err_prev + DBL_EPSILON));
    eta * log_h_ratio / (log_e_ratio + DBL_EPSILON)
}

/// C's `GenericController`: the step size factor for the next step.
pub(super) fn generic_controller(err: &[f64], step: &[f64], err_order: i32, conf: &GbConf) -> f64 {
    const FAC: f64 = 0.9;
    const FACMAX: f64 = 2.5;
    const FACMIN: f64 = 0.2;
    let k = (err_order + 1) as f64;
    let (err_n, err_n1) = (err[0], err[1]);
    let (h_n, h_n1) = (step[0], step[1]);
    if err_n < DBL_EPSILON {
        return FACMAX;
    }
    let m = conf.ctrl_method;
    let mut h_fac = match m {
        CtrlMethod::Const => 1.0,
        CtrlMethod::I => pow(1. / err_n, 1. / k),
        CtrlMethod::Pi33 | CtrlMethod::Pi34 | CtrlMethod::Pi42 => pi_controller(err, err_order, m),
        CtrlMethod::PidH312 | CtrlMethod::PidSoederlind | CtrlMethod::PidStiff => {
            pid_controller(err, err_order, m)
        }
        CtrlMethod::PiPc | CtrlMethod::PiPcHybrid | CtrlMethod::PiH211 | CtrlMethod::PiH0211 => {
            predictive_pi(err, step, err_order, m)
        }
        CtrlMethod::PidH0312 | CtrlMethod::PidH0321 | CtrlMethod::Ppid => {
            predictive_pid(err, step, err_order, m)
        }
    };
    if conf.fhr && h_n1 > DBL_EPSILON {
        let gamma = compute_gamma(err_n, err_n1, h_n, h_n1, 0.1);
        h_fac *= pow(h_n / h_n1, gamma);
    }
    if conf.ctrl_filter > 0.0 {
        h_fac = conf.ctrl_filter * h_fac + (1.0 - conf.ctrl_filter);
    }
    h_fac *= FAC;
    if (0.99 < h_fac) && (h_fac < 1.2) {
        1.0
    } else {
        FACMAX.min(FACMIN.max(h_fac))
    }
}

/// The weighted norms C's `getInitStepSize` builds; split out so the caller owns
/// the two `functionODE` evaluations it needs.
pub(super) fn init_step_norms(y0: &[f64], f0: &[f64], tol: f64) -> (f64, f64) {
    let n = y0.len() as f64;
    let mut d0 = 0.0;
    let mut d1 = 0.0;
    for i in 0..y0.len() {
        let sc = tol + abs(y0[i]) * tol;
        d0 += (y0[i] * y0[i]) / (sc * sc);
        d1 += (f0[i] * f0[i]) / (sc * sc);
    }
    (sqrt(d0 / n), sqrt(d1 / n))
}
