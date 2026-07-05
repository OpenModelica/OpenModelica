//! Real OMC backend. `backend()` returns the right implementation for the target.

use omshell_core::{Eval, Init, OmcBackend};

pub fn backend() -> Box<dyn OmcBackend + Send> {
    #[cfg(not(target_arch = "wasm32"))]
    {
        Box::new(native::InProcessBackend)
    }
    #[cfg(target_arch = "wasm32")]
    {
        Box::new(wasm::WorkerBackend)
    }
}

/// Post-init session setup shared by both backends. On wasm there is no
/// pre-installed library, so install the Modelica Standard Library to make the
/// shell immediately usable with `Modelica.*`; a native omc uses the libraries
/// already on disk, so it skips this. installPackage is best-effort — a failure
/// (e.g. no network) must not stop the shell from starting, so only its
/// diagnostics are surfaced (via getErrorString, called right after so it
/// reflects the install and clears the buffer), not a hard error.
///
/// Native only: on wasm the omc module runs inside a Web Worker, which mirrors
/// this orchestration in JS (see omc_worker.js).
#[cfg(not(target_arch = "wasm32"))]
fn init_session(install_modelica: bool, mut raw: impl FnMut(&str) -> (String, bool)) -> Init {
    if install_modelica {
        let _ = raw("installPackage(Modelica)");
    }
    let (message, _) = raw("getErrorString()");
    let (version, _) = raw("getVersion()");
    Init {
        version: version.trim().trim_matches('"').to_owned(),
        message: message.trim().trim_matches('"').trim().to_owned(),
    }
}

/// Evaluate `command`, then `getErrorString()`, via the two raw closures.
/// Native only; the wasm worker mirrors this in JS (see omc_worker.js).
#[cfg(not(target_arch = "wasm32"))]
fn eval_with_errors(
    command: &str,
    mut raw: impl FnMut(&str) -> (String, bool),
) -> Eval {
    let (result, keep_running) = raw(command);
    let (error, _) = raw("getErrorString()");
    Eval {
        result: result.trim().to_owned(),
        error: error.trim().trim_matches('"').trim().to_owned(),
        keep_running,
    }
}

#[cfg(not(target_arch = "wasm32"))]
mod native {
    use super::*;
    use arcstr::ArcStr;
    use openmodelica_backend_main::capi;
    use std::panic::{AssertUnwindSafe, catch_unwind};

    pub struct InProcessBackend;

    fn raw_eval(cmd: &str) -> (String, bool) {
        // capi::eval evaluates on the calling thread (the driver's omc worker).
        // A MetaModelica trap surfaces as a panic, so isolate it as the old
        // C-ABI wrapper did, rather than letting it tear down the worker.
        match catch_unwind(AssertUnwindSafe(|| capi::eval(ArcStr::from(cmd)))) {
            Ok(Ok((keep, reply))) => (reply.to_string(), keep),
            Ok(Err(e)) => (format!("{e}"), true),
            Err(_) => ("evaluation failed".to_owned(), true),
        }
    }

    impl OmcBackend for InProcessBackend {
        fn init(&mut self) -> Result<Init, String> {
            match catch_unwind(AssertUnwindSafe(|| capi::init(&[]))) {
                Ok(Ok(())) => {}
                Ok(Err(e)) => return Err(format!("omc init failed: {e}")),
                Err(_) => return Err("omc init failed (panic)".to_owned()),
            }
            // Native omc uses the libraries already installed on disk.
            Ok(init_session(false, raw_eval))
        }

        fn eval(&mut self, command: &str) -> Eval {
            eval_with_errors(command, raw_eval)
        }
    }
}

#[cfg(target_arch = "wasm32")]
mod wasm {
    use super::*;

    /// On wasm the omc module runs inside a dedicated Web Worker (omc_worker.js,
    /// staged next to the omc module by the build). The driver posts commands to
    /// that worker and receives replies asynchronously, so it never calls a
    /// backend on this thread — but `Shell::with_backend` still takes one, so this
    /// is an inert placeholder whose methods are never reached.
    pub struct WorkerBackend;

    impl OmcBackend for WorkerBackend {
        fn init(&mut self) -> Result<Init, String> {
            unreachable!("wasm omc runs in a Web Worker; the driver bypasses the backend")
        }

        fn eval(&mut self, _command: &str) -> Eval {
            unreachable!("wasm omc runs in a Web Worker; the driver bypasses the backend")
        }
    }
}
