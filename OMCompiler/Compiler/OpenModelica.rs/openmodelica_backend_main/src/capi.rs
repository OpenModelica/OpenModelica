//! In-process embedding API for the compiler.
//!
//! A thin, hand-written `pub` wrapper over the interactive entry points in
//! [`crate::Main`] (`init` / `readSettings` / `handleCommand`). It exists so the
//! separate `libopenmodelica_compiler` crate can wrap these in an `extern "C"`
//! interface and build `libOpenModelicaCompiler.so`, the shared library OMEdit
//! links against to drive omc in-process (instead of over ZeroMQ IPC).
//!
//! The functions here mirror exactly what `Main.interactivemodeZMQ` does around
//! the socket loop: initialise the runtime once, then evaluate command strings
//! and return the textual reply. The command/response protocol is the same one
//! used over ZeroMQ, so the typed `OMCInterface` (OpenModelicaScriptingAPIQt)
//! is *not* required for OMEdit to talk to the compiler — that typed layer is a
//! future addition on top of this string interface.
//!
//! ## Threading
//! The compiler keeps per-thread state (the error buffer, GC roots, the global
//! symbol table is reset per process). [`init`] and all subsequent [`eval`]
//! calls must therefore run on the **same** thread, exactly as omc's own
//! interactive loop is single-threaded. The caller is also responsible for
//! providing a large stack (the C omc and this port's `main` both run on a
//! dedicated multi-MiB stack, because the port only lowers self-tail-calls and
//! deep traversals can overflow the default 8 MiB).

use arcstr::ArcStr;
use metamodelica::Result;

use crate::Main;

/// Initialise the compiler runtime on the current thread.
///
/// `args` are the command-line arguments omc would receive (without the
/// executable name); flags such as `-d=…` and the installation directory are
/// honoured here just as in a normal omc startup. Pass an empty slice for the
/// default configuration (the installation directory is then taken from the
/// `OPENMODELICAHOME` environment variable).
pub fn init(args: &[ArcStr]) -> Result<()> {
    let arglist: metamodelica::List<ArcStr> = args.iter().cloned().collect();
    let arglist = Main::init(arglist)?;
    Main::readSettings(arglist)?;
    Ok(())
}

/// Set the version `getVersion()` and `omc --version` report, normally
/// `capi::set_version(openmodelica_revision::REVISION.into())`. Call it before
/// [`init`]; an unset version reports as `"unknown"`.
pub fn set_version(version: ArcStr) {
    openmodelica_util::Settings::setVersionNr(version);
}

/// Evaluate one interactive command string (e.g. `"getVersion()"`).
///
/// Returns `(keep_running, reply)`, mirroring [`Main::handleCommand`]: a normal
/// command yields `(true, reply)`; the `quit()` command yields `(false, _)` so
/// an embedder can shut the session down.
pub fn eval(command: ArcStr) -> Result<(bool, ArcStr)> {
    Main::handleCommand(command)
}

/// Request cancellation of any running in-process op — simulation, or a long
/// frontend/loader/backend call (cross-thread; the op then returns a "cancelled"
/// error, leaving omc consistent). Routes to the shared `metamodelica::cancel`
/// flag every phase polls (the sim driver reads the same flag).
pub fn request_cancel() {
    metamodelica::cancel::request_cancel();
}

/// Clear the cancel flag; call at the start of each new cancellable op.
pub fn clear_cancel() {
    metamodelica::cancel::clear_cancel();
}

/// Register the host event-pump callback invoked at every cancel check (or clear
/// with `None`). Lets an in-process GUI host keep its event loop alive during a
/// long call so the Cancel button stays clickable. See `metamodelica::cancel`.
pub fn set_pump_callback(f: Option<extern "C" fn()>) {
    metamodelica::cancel::set_pump_callback(f);
}

/// Last reported progress permille (0..=1000, or negative for indeterminate) for
/// an in-process host to fill a progress bar from its pump callback.
pub fn progress_permille() -> i32 {
    metamodelica::cancel::progress_permille()
}

/// Last reported progress phase (a `metamodelica::cancel::PHASE_*` value).
pub fn progress_phase() -> i32 {
    metamodelica::cancel::progress_phase()
}

/// `simulate` against the builtin graph only; empty/non-positive args use its defaults.
pub fn simulate(
    class_name: ArcStr,
    stop_time: f64,
    number_of_intervals: i32,
    tolerance: f64,
    method: ArcStr,
    simflags: ArcStr,
) -> ArcStr {
    crate::Interactive::simulateModel(
        class_name,
        metamodelica::OrderedFloat(stop_time),
        number_of_intervals,
        metamodelica::OrderedFloat(tolerance),
        method,
        simflags,
    )
}

/// Instantiate `class_name` with the new frontend, as `instantiateModel`
/// does, and return the flat model and its functions as reflected nodes.
pub fn instantiate_flat(class_name: &str) -> Result<(metamodelica::reflect::Node, Vec<metamodelica::reflect::Node>)> {
    use openmodelica_nf_frontend::NFFlatten::FunctionTreeImpl;
    let path = openmodelica_frontend_dump::AbsynUtil::stringPath(ArcStr::from(class_name))?;
    let (flat, functions, _) = crate::CevalScriptBackend::runFrontEndWorkNF(path, false, false)?;
    let functions = FunctionTreeImpl::listValues(&functions, metamodelica::nil());
    Ok((
        flat,
        functions
            .iter()
            .map(|f| f.clone() as metamodelica::reflect::Node)
            .collect(),
    ))
}

/// The frontend functions the Julia bridge calls on a reflected node.
pub fn apply(function: &str, n: &metamodelica::reflect::Node) -> Result<metamodelica::reflect::MMField> {
    use metamodelica::reflect::{MMField, downcast};
    use openmodelica_ast::Absyn;
    use openmodelica_frontend_dump::AbsynUtil;
    use openmodelica_nf_frontend::{NFComponentRef, NFEquation, NFExpression, NFFunction, NFType};
    fn path_string(p: metamodelica::Ref<Absyn::Path>) -> Result<ArcStr> {
        AbsynUtil::pathString(p, ArcStr::from("."), false, false)
    }
    let wrong = || Err("capi::apply: the node has the wrong type");
    Ok(match function {
        "Expression.typeOf" => match downcast::<NFExpression::NFExpression>(n) {
            Some(e) => MMField::Node(NFExpression::typeOf(e)),
            None => return wrong(),
        },
        "Expression.toString" => match downcast::<NFExpression::NFExpression>(n) {
            Some(e) => MMField::String(NFExpression::toString(e)?),
            None => return wrong(),
        },
        "ComponentRef.getSubscriptedType" => match downcast::<NFComponentRef::NFComponentRef>(n) {
            Some(c) => MMField::Node(NFComponentRef::getSubscriptedType(&c, false)?),
            None => return wrong(),
        },
        "ComponentRef.toString" => match downcast::<NFComponentRef::NFComponentRef>(n) {
            Some(c) => MMField::String(NFComponentRef::toString(&c)?),
            None => return wrong(),
        },
        "Type.toString" => match downcast::<NFType::NFType>(n) {
            Some(t) => MMField::String(NFType::toString(&t)?),
            None => return wrong(),
        },
        "Equation.toString" => match downcast::<NFEquation::NFEquation>(n) {
            Some(e) => MMField::String(NFEquation::toString(&e, ArcStr::from(""))?),
            None => return wrong(),
        },
        "Function.name" => match downcast::<NFFunction::Function::Function>(n) {
            Some(f) => MMField::String(path_string(NFFunction::Function::nameConsiderBuiltin(&f))?),
            None => return wrong(),
        },
        "Path.toString" => match downcast::<Absyn::Path>(n) {
            Some(p) => MMField::String(path_string(p)?),
            None => return wrong(),
        },
        _ => return Err("capi::apply: unknown function"),
    })
}
