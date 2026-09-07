//! `-gb*` flag handling, mirroring C's `gbode_conf.c`. C reads `omc_flagValue`
//! whenever it needs a value; here the run's [`SimFlags`] are read once into a
//! [`GbConf`] when the solver is built.
//!
//! [`SimFlags`]: crate::simflags::SimFlags

use alloc::format;
use alloc::string::String;

use super::tableau::{ErrMethod, GbMethod};
use super::tableau_data::METHOD_NAMES;

/// C's `enum GB_NLS_METHOD` (`-gbnls`).
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum NlsMethod {
    Newton,
    Kinsol,
    KinsolB,
    Internal,
}

/// C's `enum GB_CTRL_METHOD` (`-gbctrl`), in the C numbering.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum CtrlMethod {
    I,
    Pi33,
    Pi34,
    Pi42,
    PidH312,
    PidSoederlind,
    PidStiff,
    PiPc,
    PiPcHybrid,
    PiH211,
    PiH0211,
    PidH0312,
    PidH0321,
    Ppid,
    Const,
}

/// C's `enum GB_INTERPOL_METHOD` (`-gbint`). The `*ErrCtrl` variants additionally
/// reject a step whose interpolation error over the interval is too large; the
/// dense-output ones fall back to Hermite for a method that has no such formula.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Interpolation {
    Lin,
    Hermite,
    /// Hermite using the left-hand derivative only.
    HermiteA,
    /// Hermite using the right-hand derivative only.
    HermiteB,
    HermiteErrCtrl,
    DenseOutput,
    DenseOutputErrCtrl,
}

impl Interpolation {
    pub fn is_err_ctrl(self) -> bool {
        matches!(self, Interpolation::HermiteErrCtrl | Interpolation::DenseOutputErrCtrl)
    }
}

const NLS_NAMES: &[(&str, NlsMethod)] = &[
    ("newton", NlsMethod::Newton),
    ("kinsol", NlsMethod::Kinsol),
    ("experimental-kinsol", NlsMethod::KinsolB),
    ("internal", NlsMethod::Internal),
];

const CTRL_NAMES: &[(&str, CtrlMethod)] = &[
    ("i", CtrlMethod::I),
    ("pi_33", CtrlMethod::Pi33),
    ("pi_34", CtrlMethod::Pi34),
    ("pi_42", CtrlMethod::Pi42),
    ("pid_h312", CtrlMethod::PidH312),
    ("pid_soederlind", CtrlMethod::PidSoederlind),
    ("pid_stiff", CtrlMethod::PidStiff),
    ("pc", CtrlMethod::PiPc),
    ("pc_hybrid", CtrlMethod::PiPcHybrid),
    ("pi_h211", CtrlMethod::PiH211),
    ("pi_h0_211", CtrlMethod::PiH0211),
    ("pid_h0_312", CtrlMethod::PidH0312),
    ("pid_h0_321", CtrlMethod::PidH0321),
    ("ppid", CtrlMethod::Ppid),
    ("const", CtrlMethod::Const),
];

const INTERPOL_NAMES: &[(&str, Interpolation)] = &[
    ("linear", Interpolation::Lin),
    ("hermite", Interpolation::Hermite),
    ("hermite_a", Interpolation::HermiteA),
    ("hermite_b", Interpolation::HermiteB),
    ("hermite_errctrl", Interpolation::HermiteErrCtrl),
    ("dense_output", Interpolation::DenseOutput),
    ("dense_output_errctrl", Interpolation::DenseOutputErrCtrl),
];

const ERR_NAMES: &[(&str, ErrMethod)] = &[
    ("default", ErrMethod::Default),
    ("richardson", ErrMethod::Richardson),
    ("embedded", ErrMethod::Embedded),
    ("two_step", ErrMethod::TwoStep),
    ("contractive_defect", ErrMethod::Contractive),
    ("contractive_filter", ErrMethod::Filter),
];

fn name_of<T: Copy + PartialEq>(table: &[(&'static str, T)], v: T) -> &'static str {
    table.iter().find(|(_, m)| *m == v).map(|(n, _)| *n).unwrap_or("unknown")
}

fn lookup<T: Copy>(flag: &str, value: &str, table: &[(&str, T)]) -> Result<T, String> {
    if let Some((_, v)) = table.iter().find(|(n, _)| *n == value) {
        return Ok(*v);
    }
    let mut accepted = String::new();
    for (n, _) in table {
        if !accepted.is_empty() {
            accepted.push_str(", ");
        }
        accepted.push_str(n);
    }
    Err(format!("unrecognized value `{value}` for -{flag} (accepted: {accepted})"))
}

/// What the birate mode's inner (fast-states) integrator reads out of the
/// `-gbf*` flags, C's `FLAG_MR*` getters in `gbode_conf.c`.
pub struct GbfConf {
    pub method: GbMethod,
    pub nls_method: NlsMethod,
    pub ctrl_method: CtrlMethod,
    pub interpolation: Interpolation,
    pub err_method: ErrMethod,
}

impl GbfConf {
    pub fn method_name(&self) -> &'static str {
        name_of(METHOD_NAMES, self.method)
    }

    pub fn nls_method_name(&self) -> &'static str {
        name_of(NLS_NAMES, self.nls_method)
    }
}

/// Everything the single-rate integrator reads out of the `-gb*` flags. C's
/// per-flag defaults are applied here (esdirk4, internal NLS, pid_h312 control,
/// dense_output_errctrl interpolation).
pub struct GbConf {
    pub method: GbMethod,
    pub nls_method: NlsMethod,
    pub ctrl_method: CtrlMethod,
    pub interpolation: Interpolation,
    pub err_method: ErrMethod,
    /// `-gbctrl_filter`, C's `use_filter`: exponential smoothing of the step size
    /// factor. 0 keeps the step size constant, 1 adapts fully without smoothing.
    pub ctrl_filter: f64,
    /// `-gbctrl_fhr`, C's `use_fhr`.
    pub fhr: bool,
    /// `-gbratio`: the fraction of states the birate mode integrates fast.
    pub ratio: f64,
    /// `-gbctrl_evnt_reinit`: recompute the initial step size from scratch after an
    /// event instead of flooring it at a tenth of the last one.
    pub evnt_reinit: bool,
}

impl GbConf {
    pub fn from_flags() -> Result<Self, String> {
        let get = |name: &str| crate::simflags::with_flags(|f| f.gb_flag(name));
        let method = match get("gbm") {
            Some(v) => lookup("gbm", &v, METHOD_NAMES)?,
            None => GbMethod::RK_ESDIRK4,
        };
        let nls_method = match get("gbnls") {
            Some(v) => lookup("gbnls", &v, NLS_NAMES)?,
            None => NlsMethod::Internal,
        };
        let ctrl_method = match get("gbctrl") {
            Some(v) => lookup("gbctrl", &v, CTRL_NAMES)?,
            None => CtrlMethod::PidH312,
        };
        let interpolation = match get("gbint") {
            Some(v) => lookup("gbint", &v, INTERPOL_NAMES)?,
            None => Interpolation::DenseOutputErrCtrl,
        };
        let err_method = match get("gberr") {
            Some(v) => lookup("gberr", &v, ERR_NAMES)?,
            None => ErrMethod::Default,
        };
        let ctrl_filter = match get("gbctrl_filter") {
            Some(v) => {
                let f: f64 =
                    v.parse().map_err(|_| String::from("-gbctrl_filter needs a number"))?;
                if !(0.0..=1.0).contains(&f) {
                    return Err(format!(
                        "Flag -gbctrl_filter has to be between 0.0 and 1.0, but {v} was given."
                    ));
                }
                f
            }
            None => 1.0,
        };
        let ratio = match get("gbratio") {
            Some(v) => {
                let f: f64 = v.parse().map_err(|_| String::from("-gbratio needs a number"))?;
                if !(0.0..=1.0).contains(&f) {
                    return Err(format!(
                        "Flag -gbratio has to be between 0.0 and 1.0, but {v} was given."
                    ));
                }
                f
            }
            None => 0.0,
        };
        Ok(GbConf {
            method,
            nls_method,
            ctrl_method,
            interpolation,
            err_method,
            ctrl_filter,
            fhr: crate::simflags::with_flags(|f| f.gb_toggle("gbctrl_fhr")),
            ratio,
            evnt_reinit: crate::simflags::with_flags(|f| f.gb_toggle("gbctrl_evnt_reinit")),
        })
    }

    /// C's `getGB_method(FLAG_MR)` etc.: the fast (inner) integrator's options,
    /// each falling back to the single-rate one. A fully implicit single-rate
    /// method defaults the generic-NLS inner integrator to esdirk4, constant step
    /// size control falls back to the I controller, and the `*_errctrl`
    /// interpolations are not available for the fast states.
    pub fn fast_conf(&self, sr_is_implicit: impl Fn(super::tableau::GbMethod) -> bool) -> Result<GbfConf, String> {
        let get = |name: &str| crate::simflags::with_flags(|f| f.gb_flag(name));
        let nls_method = match get("gbfnls") {
            Some(v) => lookup("gbfnls", &v, NLS_NAMES)?,
            None => self.nls_method,
        };
        let method = match get("gbfm") {
            Some(v) => {
                let m = lookup("gbfm", &v, METHOD_NAMES)?;
                crate::omclog::info!(
                    crate::omclog::SOLVER,
                    false,
                    "Chosen gbode method: {}",
                    name_of(METHOD_NAMES, m),
                );
                m
            }
            None if nls_method == NlsMethod::Internal => self.method,
            None if sr_is_implicit(self.method) => super::tableau_data::GbMethod::RK_ESDIRK4,
            None => self.method,
        };
        let ctrl_method = match get("gbfctrl") {
            Some(v) => lookup("gbfctrl", &v, CTRL_NAMES)?,
            None => self.ctrl_method,
        };
        let ctrl_method = if ctrl_method == CtrlMethod::Const {
            crate::omclog::warning(
                crate::omclog::STDOUT,
                false,
                "Constant step size not supported for inner integration. Using IController.",
            );
            CtrlMethod::I
        } else {
            ctrl_method
        };
        let interpolation = match get("gbfint") {
            Some(v) => lookup("gbfint", &v, INTERPOL_NAMES)?,
            None => self.interpolation,
        };
        let interpolation = match interpolation {
            Interpolation::HermiteErrCtrl | Interpolation::DenseOutputErrCtrl => {
                crate::omclog::warning!(
                    crate::omclog::SOLVER,
                    false,
                    "Chosen gbode interpolation method {} not supported for fast state integration",
                    name_of(INTERPOL_NAMES, interpolation),
                );
                Interpolation::DenseOutput
            }
            other => other,
        };
        let err_method = match get("gbferr") {
            Some(v) => lookup("gbferr", &v, ERR_NAMES)?,
            None => ErrMethod::Default,
        };
        Ok(GbfConf { method, nls_method, ctrl_method, interpolation, err_method })
    }

    /// The names C echoes back for the chosen options.
    pub fn method_name(&self) -> &'static str {
        name_of(METHOD_NAMES, self.method)
    }

    pub fn nls_method_name(&self) -> &'static str {
        name_of(NLS_NAMES, self.nls_method)
    }

    pub fn ctrl_method_name(&self) -> &'static str {
        name_of(CTRL_NAMES, self.ctrl_method)
    }

    pub fn interpolation_name(&self) -> &'static str {
        name_of(INTERPOL_NAMES, self.interpolation)
    }
}
