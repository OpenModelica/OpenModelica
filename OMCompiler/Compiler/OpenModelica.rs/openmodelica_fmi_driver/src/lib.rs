//! The master algorithm for an imported FMU.
//!
//! * **Co-Simulation** — the FMU integrates itself; the master feeds inputs at
//!   each communication point and handles the events the FMU returns early from
//!   ([`cs`]).
//! * **Model Exchange** — the master integrates, with the same solvers a
//!   compiled OpenModelica model runs under ([`me`], over
//!   `openmodelica_solvers`).
//!
//! What actually serves the FMU is behind [`api::Fmi3`]: a native binary called
//! through the FMI 3.0 C API ([`ffi`]), or — in the browser — a wasm FMU linked
//! into this module. The masters never learn which.

pub mod api;
pub(crate) mod common;
pub mod cs;
pub mod expr;
pub mod me;
pub mod record;

#[cfg(all(feature = "ffi", not(target_arch = "wasm32")))]
pub mod ffi;

/// The FMU as wasm beside us, reached through host imports — the browser page.
#[cfg(target_arch = "wasm32")]
pub mod wasm_host;

/// An fmi-ls-wasm component driven in this process by wasmtime.
#[cfg(all(feature = "component", not(target_arch = "wasm32")))]
pub mod component;

use openmodelica_fmi::{InterfaceKind, ModelDescription, VarType};

#[derive(Debug)]
pub enum Error {
    /// The FMU returned a status the master cannot continue from.
    Status { call: &'static str, status: api::Status },
    /// Instantiation returned no instance; the FMU's own log usually says why.
    Instantiate { call: &'static str, log: Vec<(api::Status, String, String)> },
    /// The FMU does not offer something the run needs.
    Unsupported(String),
    /// The binary could not be loaded, or an entry point is missing.
    Load(String),
    Io(String),
    /// The integrator gave up (step size underflow, no convergence).
    Solver(&'static str),
    /// The FMU's own simulation runtime reported a failure.
    Simulation(String),
    /// The FMU asked for termination during initialization.
    TerminatedAtInit,
    /// `-alarm=N` expired.
    Alarm,
    Cancelled,
}

impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Error::Status { call, status } => write!(f, "{call} returned {}", status.as_str()),
            Error::Instantiate { call, log } => {
                write!(f, "{call} returned no instance")?;
                for (_, category, message) in log {
                    write!(f, "\n  {category}: {message}")?;
                }
                Ok(())
            }
            Error::Unsupported(what) => write!(f, "the FMU does not support {what}"),
            Error::Load(m) => write!(f, "cannot load the FMU binary: {m}"),
            Error::Io(m) => write!(f, "{m}"),
            Error::Solver(m) => write!(f, "{m}"),
            Error::Simulation(m) => write!(f, "{m}"),
            Error::TerminatedAtInit => {
                write!(f, "the FMU requested termination during initialization")
            }
            Error::Alarm => write!(f, "simulation aborted (-alarm)"),
            Error::Cancelled => write!(f, "cancelled"),
        }
    }
}

impl std::error::Error for Error {}

impl From<openmodelica_fmi::Error> for Error {
    fn from(e: openmodelica_fmi::Error) -> Error {
        match e {
            openmodelica_fmi::Error::Io(m) => Error::Io(m),
            e => Error::Load(e.to_string()),
        }
    }
}

pub type Result<T> = std::result::Result<T, Error>;

/// How a Model Exchange run integrates. Co-Simulation ignores this — the FMU
/// brings its own solver.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Solver {
    /// DASKR's BDF integrator with its own root finding, which is what a
    /// compiled OpenModelica model runs under by default, and what a stiff
    /// model wants.
    #[default]
    Dassl,
    /// SUNDIALS CVODE, in the BDF/Newton configuration `cvode_solver.c` builds.
    Cvode,
    /// SUNDIALS IDA, given the ODE as the residual `y' - f(t, y)`.
    Ida,
    /// The generic Runge-Kutta solver, under the `-gb*` flags.
    Gbode,
    Euler,
    RungeKutta,
}

impl Solver {
    /// Every solver this build can run, in the order to offer them: CVODE and
    /// IDA only where SUNDIALS was linked in.
    pub fn all() -> &'static [Solver] {
        const SUNDIALS: &[Solver] = &[
            Solver::Dassl, Solver::Cvode, Solver::Ida, Solver::Gbode, Solver::Euler,
            Solver::RungeKutta,
        ];
        const PLAIN: &[Solver] =
            &[Solver::Dassl, Solver::Gbode, Solver::Euler, Solver::RungeKutta];
        if cfg!(sundials) { SUNDIALS } else { PLAIN }
    }

    pub fn as_str(self) -> &'static str {
        match self {
            Solver::Dassl => "dassl",
            Solver::Cvode => "cvode",
            Solver::Ida => "ida",
            Solver::Gbode => "gbode",
            Solver::Euler => "euler",
            Solver::RungeKutta => "rungekutta",
        }
    }

    /// What a chooser puts next to the name.
    pub fn description(self) -> &'static str {
        match self {
            Solver::Dassl => "BDF with root finding, the default for a model too",
            Solver::Cvode => "SUNDIALS BDF, Newton over a dense Jacobian",
            Solver::Ida => "SUNDIALS BDF over the residual y' - f(t, y)",
            Solver::Gbode => "Runge-Kutta, under the -gb* flags",
            Solver::Euler => "fixed step",
            Solver::RungeKutta => "fixed step, RK4",
        }
    }

    /// The name as a `-s=` flag or the page's selector spells it, out of
    /// [`all`](Solver::all).
    pub fn parse(name: &str) -> Option<Solver> {
        Solver::all().iter().copied().find(|s| s.as_str() == name)
    }
}

/// A value the master feeds an input variable, as a function of time.
pub struct Input {
    pub value_reference: u32,
    pub ty: VarType,
    /// An expression in `t` ([`expr`]).
    pub value: expr::Expr,
}

/// A value applied once, in Initialization Mode. FMI allows no other time for a
/// parameter.
pub struct Parameter {
    pub value_reference: u32,
    pub ty: VarType,
    pub value: f64,
}

pub struct Options<'a> {
    pub start_time: f64,
    pub stop_time: f64,
    /// The output interval, and for Co-Simulation the communication step size.
    pub step_size: f64,
    pub tolerance: Option<f64>,
    pub solver: Solver,
    /// Ask the FMU to log; its messages reach [`api::Fmi3::take_log`].
    pub logging_on: bool,
    /// Drive the FMU's Event Mode (Co-Simulation), when it has one.
    pub event_mode: bool,
    /// Ask an FMU that offers them for the Jacobian's columns instead of
    /// differencing them (Model Exchange). Off compares the two.
    pub directional_derivatives: bool,
    pub parameters: Vec<Parameter>,
    pub inputs: Vec<Input>,
    /// Called at each output point with the samples so far, for a host that
    /// plots a run while it happens. A run is one call, so without this nothing
    /// is heard until it ends.
    pub progress: Option<fn(f64, &record::Recorder)>,
    /// Asked at each output point: `true` ends the run where it stands, with
    /// the samples taken so far kept.
    pub cancelled: Option<fn() -> bool>,
    /// `-alarm=N`: seconds of wall clock the run may take. C raises `SIGALRM`;
    /// here omc is the process, so the masters report [`Error::Alarm`] instead.
    pub alarm: Option<u32>,
    /// `-variableFilter`: which variables the result file keeps; `None` keeps all.
    /// Borrowed, since the caller owns the compiled regex; this crate has none.
    pub keep: Option<&'a dyn Fn(&str) -> bool>,
}

impl Options<'_> {
    /// The options an FMU is simulated with when the caller says nothing: its
    /// own `<DefaultExperiment>`, and 500 output points where it gives no step
    /// size.
    pub fn from_model_description(md: &ModelDescription) -> Options<'static> {
        let e = md.default_experiment.unwrap_or_default();
        let start_time = e.start_time.unwrap_or(0.0);
        let stop_time = e.stop_time.unwrap_or(start_time + 1.0);
        let step_size = e
            .step_size
            .filter(|h| *h > 0.0)
            .unwrap_or_else(|| (stop_time - start_time) / 500.0);
        Options {
            start_time,
            stop_time,
            step_size,
            tolerance: e.tolerance,
            solver: Solver::default(),
            logging_on: false,
            event_mode: true,
            directional_derivatives: true,
            parameters: Vec::new(),
            inputs: Vec::new(),
            progress: None,
            cancelled: None,
            alarm: None,
            keep: None,
        }
    }

    /// The output grid: `start`, then every `step_size` up to `stop`.
    pub fn output_times(&self) -> impl Iterator<Item = f64> + '_ {
        self.grid(self.step_size)
    }

    /// The same grid at another step size, which Co-Simulation needs when the
    /// FMU only advances in multiples of its own internal step.
    pub fn grid(&self, step: f64) -> impl Iterator<Item = f64> + '_ {
        let span = self.stop_time - self.start_time;
        let n = if !(step > 0.0) || span <= 0.0 { 0 } else { (span / step).ceil() as u64 };
        (0..=n).map(move |k| {
            // The last interval is whatever is left, so a step size that does
            // not divide the span still ends exactly at the stop time.
            if k == n { self.stop_time } else { self.start_time + k as f64 * step }
        })
    }
}

/// The wall clock a run may take, from [`Options::alarm`]. The browser has no
/// clock here and cancels through [`Options::cancelled`], so it never expires.
pub(crate) struct Deadline {
    #[cfg(not(target_arch = "wasm32"))]
    until: Option<std::time::Instant>,
}

impl Deadline {
    pub(crate) fn arm(opts: &Options<'_>) -> Deadline {
        #[cfg(not(target_arch = "wasm32"))]
        return Deadline {
            until: opts
                .alarm
                .filter(|s| *s > 0)
                .map(|s| std::time::Instant::now() + std::time::Duration::from_secs(s as u64)),
        };
        #[cfg(target_arch = "wasm32")]
        {
            let _ = opts;
            Deadline {}
        }
    }

    pub(crate) fn expired(&self) -> bool {
        #[cfg(not(target_arch = "wasm32"))]
        return self.until.is_some_and(|t| std::time::Instant::now() >= t);
        #[cfg(target_arch = "wasm32")]
        false
    }
}

/// Which interface to drive: what the caller asked for, else Co-Simulation when
/// the FMU has it (its own solver knows the model best), else Model Exchange.
pub fn choose_interface(
    md: &ModelDescription,
    wanted: Option<InterfaceKind>,
) -> Result<InterfaceKind> {
    if let Some(kind) = wanted {
        if md.interface(kind).is_none() {
            return Err(Error::Unsupported(format!("the {} interface", kind.as_str())));
        }
        return Ok(kind);
    }
    [InterfaceKind::CoSimulation, InterfaceKind::ModelExchange]
        .into_iter()
        .find(|&k| md.interface(k).is_some())
        .ok_or_else(|| {
            Error::Unsupported("Model Exchange or Co-Simulation (only Scheduled Execution)".into())
        })
}
