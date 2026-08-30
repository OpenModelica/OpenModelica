//! The FMI 3.0 API as the masters use it: one trait for what every instance can
//! do, one per interface kind. A backend implements them over whatever actually
//! serves the FMU — a shared library called through FFI, or a wasm FMU linked
//! into this module — and the masters never learn which.
//!
//! `fmi3Status` is folded into `Result`: `ok` and `warning` are success (the
//! warning has already reached the logger), everything else is an error naming
//! the call that returned it. `discard` keeps its own variant, since a
//! Co-Simulation master may retry a discarded step.

use crate::{Error, Result};
use openmodelica_fmi::VarType;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Status {
    Ok,
    Warning,
    Discard,
    Error,
    Fatal,
}

impl Status {
    pub fn from_raw(v: i32) -> Status {
        match v {
            0 => Status::Ok,
            1 => Status::Warning,
            2 => Status::Discard,
            3 => Status::Error,
            _ => Status::Fatal,
        }
    }

    pub fn is_ok(self) -> bool {
        matches!(self, Status::Ok | Status::Warning)
    }

    pub fn as_str(self) -> &'static str {
        match self {
            Status::Ok => "ok",
            Status::Warning => "warning",
            Status::Discard => "discard",
            Status::Error => "error",
            Status::Fatal => "fatal",
        }
    }
}

/// What `fmi3UpdateDiscreteStates` reports about the event it just handled.
#[derive(Clone, Copy, Debug, Default)]
pub struct DiscreteStates {
    /// Another event iteration is needed.
    pub need_update: bool,
    pub terminate: bool,
    pub nominals_changed: bool,
    pub states_changed: bool,
    pub next_event_time: Option<f64>,
}

/// What `fmi3CompletedIntegratorStep` reports.
#[derive(Clone, Copy, Debug, Default)]
pub struct CompletedStep {
    pub enter_event_mode: bool,
    pub terminate: bool,
}

/// What `fmi3DoStep` reports.
#[derive(Clone, Copy, Debug, Default)]
pub struct DoStep {
    /// The FMU hit an event and needs Event Mode before the next step.
    pub event_handling_needed: bool,
    pub terminate: bool,
    /// The FMU stopped before the end of the requested step.
    pub early_return: bool,
    /// How far it actually got.
    pub last_successful_time: f64,
}

/// What every FMI 3.0 instance can do, whichever interface it serves.
pub trait Fmi3 {
    fn get_version(&mut self) -> String;

    fn enter_initialization_mode(
        &mut self,
        tolerance: Option<f64>,
        start_time: f64,
        stop_time: Option<f64>,
    ) -> Result<()>;
    fn exit_initialization_mode(&mut self) -> Result<()>;
    fn enter_event_mode(&mut self) -> Result<()>;
    fn update_discrete_states(&mut self) -> Result<DiscreteStates>;
    fn terminate(&mut self) -> Result<()>;

    /// `fmi3EnterConfigurationMode`/`fmi3ExitConfigurationMode`, the only place a
    /// structural parameter may be set. An FMU without structural parameters
    /// need not offer them.
    fn enter_configuration_mode(&mut self) -> Result<()> {
        Err(Error::Unsupported("fmi3EnterConfigurationMode".into()))
    }
    fn exit_configuration_mode(&mut self) -> Result<()> {
        Err(Error::Unsupported("fmi3ExitConfigurationMode".into()))
    }

    /// Read numeric variables as `f64`, whatever their declared type: the
    /// masters plot and record in `f64`, and the `.mat` holds nothing else.
    /// `ty` selects the `fmi3Get*` to call.
    fn get_numeric(&mut self, ty: VarType, vrs: &[u32], values: &mut [f64]) -> Result<()>;
    fn set_numeric(&mut self, ty: VarType, vrs: &[u32], values: &[f64]) -> Result<()>;

    fn get_string(&mut self, vrs: &[u32]) -> Result<Vec<String>> {
        let _ = vrs;
        Err(Error::Unsupported("fmi3GetString".into()))
    }
    fn set_string(&mut self, vrs: &[u32], values: &[&str]) -> Result<()> {
        let _ = (vrs, values);
        Err(Error::Unsupported("fmi3SetString".into()))
    }

    /// Drain what the FMU logged since the last call, as `(status, category,
    /// message)`. A backend whose logger writes straight through returns none.
    fn take_log(&mut self) -> Vec<(Status, String, String)> {
        Vec::new()
    }
}

/// The Model Exchange interface: the master owns the integration.
pub trait Fmi3ModelExchange: Fmi3 {
    fn enter_continuous_time_mode(&mut self) -> Result<()>;
    fn set_time(&mut self, time: f64) -> Result<()>;
    fn set_continuous_states(&mut self, states: &[f64]) -> Result<()>;
    fn get_continuous_states(&mut self, states: &mut [f64]) -> Result<()>;
    fn get_continuous_state_derivatives(&mut self, ders: &mut [f64]) -> Result<()>;
    fn get_event_indicators(&mut self, indicators: &mut [f64]) -> Result<()>;
    fn get_nominals_of_continuous_states(&mut self, nominals: &mut [f64]) -> Result<()>;
    fn completed_integrator_step(&mut self, no_set_state_prior: bool) -> Result<CompletedStep>;

    /// `fmi3GetDirectionalDerivative`: `sensitivity = d(unknowns)/d(knowns) ·
    /// seed`. An FMU that declares `providesDirectionalDerivatives` answers the
    /// integrator's Jacobian from the model's own derivatives instead of making
    /// it difference them.
    fn get_directional_derivative(
        &mut self,
        unknowns: &[u32],
        knowns: &[u32],
        seed: &[f64],
        sensitivity: &mut [f64],
    ) -> Result<()> {
        let _ = (unknowns, knowns, seed, sensitivity);
        Err(Error::Unsupported("fmi3GetDirectionalDerivative".into()))
    }

    /// `fmi3GetNumberOfContinuousStates`, which not every FMU implements; the
    /// model description carries the same count, so a backend may report
    /// [`Error::Unsupported`] and let the master fall back to it.
    fn get_number_of_continuous_states(&mut self) -> Result<usize> {
        Err(Error::Unsupported("fmi3GetNumberOfContinuousStates".into()))
    }
    fn get_number_of_event_indicators(&mut self) -> Result<usize> {
        Err(Error::Unsupported("fmi3GetNumberOfEventIndicators".into()))
    }
}

/// The Co-Simulation interface: the FMU owns the integration.
pub trait Fmi3CoSimulation: Fmi3 {
    fn enter_step_mode(&mut self) -> Result<()>;
    fn do_step(
        &mut self,
        current_communication_point: f64,
        communication_step_size: f64,
        no_set_state_prior: bool,
    ) -> Result<DoStep>;
}

/// Turn a raw `fmi3Status` into the master's result, naming the call.
pub fn check(call: &'static str, raw: i32) -> Result<()> {
    let status = Status::from_raw(raw);
    if status.is_ok() {
        Ok(())
    } else {
        Err(Error::Status { call, status })
    }
}
