//! In-process embedding API for the compiler.
//!
//! A thin, hand-written `pub` wrapper over the interactive entry points in
//! [`crate::Main`] (`init` / `readSettings` / `handleCommand`). It exists so the
//! separate `libopenmodelica_compiler` crate can wrap these in an `extern "C"`
//! interface and build `libOpenModelicaCompiler.so`, the shared library OMEdit
//! links against to drive omc in-process (instead of over ZeroMQ/Corba IPC).
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

use anyhow::Result;
use arcstr::ArcStr;
use std::sync::Arc;

use crate::Main;

/// Initialise the compiler runtime on the current thread.
///
/// `args` are the command-line arguments omc would receive (without the
/// executable name); flags such as `-d=…` and the installation directory are
/// honoured here just as in a normal omc startup. Pass an empty slice for the
/// default configuration (the installation directory is then taken from the
/// `OPENMODELICAHOME` environment variable).
pub fn init(args: &[ArcStr]) -> Result<()> {
    let arglist: Arc<metamodelica::List<ArcStr>> = Arc::new(args.iter().cloned().collect());
    let arglist = Main::init(arglist)?;
    Main::readSettings(arglist)?;
    Ok(())
}

/// Evaluate one interactive command string (e.g. `"getVersion()"`).
///
/// Returns `(keep_running, reply)`, mirroring [`Main::handleCommand`]: a normal
/// command yields `(true, reply)`; the `quit()` command yields `(false, _)` so
/// an embedder can shut the session down.
pub fn eval(command: ArcStr) -> Result<(bool, ArcStr)> {
    Main::handleCommand(command)
}
