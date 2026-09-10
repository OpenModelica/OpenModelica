//! Small shared helpers: list iteration, constant folding of literal
//! expressions, expression dumping, file output.

use super::*;

/// Iterate a MetaModelica `List` (which is `IntoIterator` by reference, not via
/// an `.iter()` method).
pub(crate) fn lst<T: Clone>(l: &List<T>) -> impl Iterator<Item = &T> {
    l.iter()
}

/// Record the reason as an `INTERNAL_ERROR` so `getErrorString()` (and OMEdit)
/// show it and the scripting layer treats the build as failed. Does NOT panic: a
/// panic traps the wasm instance, after which the buffered error can't be read
/// back (the web omc then reports a bare "Translation failed"). Callers return
/// after this instead — an unsupported construct is a normal failure, not a crash.
/// The position is the Rust call site, as `sourceInfo()` gives a MetaModelica
/// `addInternalError`.
#[track_caller]
pub(crate) fn record_error(msg: String) {
    let loc = std::panic::Location::caller();
    let _ = openmodelica_util::Error::addInternalError(
        ArcStr::from(msg.as_str()),
        metamodelica::SourceInfo {
            fileName: ArcStr::from(loc.file()),
            isReadOnly: false,
            lineNumberStart: loc.line() as i32,
            columnNumberStart: loc.column() as i32,
            lineNumberEnd: loc.line() as i32,
            columnNumberEnd: loc.column() as i32,
            lastModification: metamodelica::OrderedFloat(0.0),
        },
    );
}

/// `e` plus the engine's own message (trap kind + wasm backtrace) that the
/// `&'static str` error dropped — but not for a model `assert()`, which already
/// reported itself.
pub(super) fn with_engine_detail(e: &str) -> String {
    let detail = openmodelica_wasm_jit::take_engine_error_detail();
    let e = match (sim_driver::init_failed_lambda(), sim_driver::failed_nls_system()) {
        (Some(l), Some(k)) if e.ends_with("at lambda") => {
            format!("{e} = {l} (nonlinear system {k})")
        }
        _ => e.to_string(),
    };
    match detail {
        Some(d) if e != sim_driver::ASSERT_ERR => format!("{e}\n{d}"),
        _ => e,
    }
}

pub(super) fn xml_escape(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;").replace('"', "&quot;")
}

pub(super) fn const_real(e: &Option<Arc<DAE::Exp>>) -> Option<f64> {
    match e.as_deref()? {
        DAE::Exp::RCONST { real } => Some(real.into_inner()),
        DAE::Exp::ICONST { integer } => Some(*integer as f64),
        _ => None,
    }
}

pub(super) fn const_int(e: &Option<Arc<DAE::Exp>>) -> Option<i32> {
    match e.as_deref()? {
        DAE::Exp::ICONST { integer } => Some(*integer),
        DAE::Exp::BCONST { bool } => Some(*bool as i32),
        DAE::Exp::ENUM_LITERAL { index, .. } => Some(*index),
        _ => None,
    }
}

pub(super) fn const_str(e: &Option<Arc<DAE::Exp>>) -> Option<String> {
    match e.as_deref()? {
        DAE::Exp::SCONST { string } => Some(string.to_string()),
        _ => None,
    }
}

pub(super) fn dump_exp(e: &Arc<DAE::Exp>) -> String {
    openmodelica_frontend_dump::ExpressionBasics::printExpStr(e.clone())
        .map(|s| s.to_string())
        .unwrap_or_default()
}

/// A fresh `T_REAL` type for synthesizing the lhs `CREF` expression of a simple
/// assignment (the type is not consulted on the simulation cref path).
pub(crate) fn t_real() -> Arc<DAE::Type> {
    Arc::new(DAE::Type::T_REAL { varLst: metamodelica::nil() })
}

pub(crate) fn count<T: Clone>(list: &List<T>) -> usize {
    lst(list).count()
}
