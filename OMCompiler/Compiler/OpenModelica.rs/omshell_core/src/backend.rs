//! The OMC connection. Mirrors `omcinteractiveenvironment.cpp`: evaluate a
//! command, then `getErrorString()` for diagnostics.
//!
//! Only the trait lives here; `omshell_omc` provides the real backend (the
//! compiler linked in-process on native, the omc wasm module's JS exports on
//! web). A front-end constructs a `Box<dyn OmcBackend>` and hands it to
//! [`crate::Shell::with_backend`].

pub struct Eval {
    pub result: String,
    pub error: String,
    pub keep_running: bool,
}

/// Result of [`OmcBackend::init`]: the omc version for the banner, and any
/// diagnostics produced during start-up (the `getErrorString()` left over after
/// the initial `installPackage(Modelica)`), shown in the terminal if non-empty.
pub struct Init {
    pub version: String,
    pub message: String,
}

pub trait OmcBackend {
    /// Initialise on the current thread; returns the version and start-up output.
    fn init(&mut self) -> Result<Init, String>;
    fn eval(&mut self, command: &str) -> Eval;
}
