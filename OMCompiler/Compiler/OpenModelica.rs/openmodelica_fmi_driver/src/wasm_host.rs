//! The FMI 3.0 API as imports of this wasm module, for a host that has the FMU
//! itself as wasm beside us — the browser page.
//!
//! The host provides one function per FMI call. Arrays cross in *this* module's
//! memory: the host copies them into the FMU's memory and back, which measured
//! at ~130 ns per call against the ~4 µs a component-model wrapper costs (see
//! `HANDOFF-fmi-import.md`). Everything else — the solvers, the event handling,
//! the result file — stays here.

use crate::api::*;
use crate::{Error, Result};
use openmodelica_fmi::VarType;

/// Kinds, as `fmu_instantiate` takes them.
pub const KIND_MODEL_EXCHANGE: i32 = 0;
pub const KIND_CO_SIMULATION: i32 = 1;

/// A status the host reports when it could not even make the call.
const HOST_FAILED: i32 = 5;

/// What the host writes back for the calls that report more than a status. The
/// layouts are fixed here and in `fmu-bridge.js`; each `f64` sits at the offset
/// its alignment gives it.
#[repr(C)]
#[derive(Default)]
struct DiscreteStatesOut {
    need_update: u32,
    terminate: u32,
    nominals_changed: u32,
    states_changed: u32,
    next_event_time_defined: u32,
    next_event_time: f64,
}

#[repr(C)]
#[derive(Default)]
struct CompletedStepOut {
    enter_event_mode: u32,
    terminate: u32,
}

#[repr(C)]
#[derive(Default)]
struct DoStepOut {
    event_handling_needed: u32,
    terminate: u32,
    early_return: u32,
    last_successful_time: f64,
}

// The page binds these to the FMU's own wasm; see `wasm/fmi-simulator/fmu-bridge.js`.
#[link(wasm_import_module = "fmu")]
unsafe extern "C" {
    fn fmu_instantiate(kind: i32, event_mode: i32, early_return: i32, logging_on: i32) -> i32;
    fn fmu_free_instance();
    fn fmu_enter_initialization_mode(
        tolerance_defined: i32,
        tolerance: f64,
        start_time: f64,
        stop_time_defined: i32,
        stop_time: f64,
    ) -> i32;
    fn fmu_exit_initialization_mode() -> i32;
    fn fmu_enter_event_mode() -> i32;
    fn fmu_enter_configuration_mode() -> i32;
    fn fmu_exit_configuration_mode() -> i32;
    fn fmu_enter_continuous_time_mode() -> i32;
    fn fmu_enter_step_mode() -> i32;
    fn fmu_terminate() -> i32;
    fn fmu_update_discrete_states(out: *mut DiscreteStatesOut) -> i32;
    fn fmu_set_time(time: f64) -> i32;
    fn fmu_set_continuous_states(values: *const f64, n: usize) -> i32;
    fn fmu_get_continuous_states(values: *mut f64, n: usize) -> i32;
    fn fmu_get_continuous_state_derivatives(values: *mut f64, n: usize) -> i32;
    fn fmu_get_event_indicators(values: *mut f64, n: usize) -> i32;
    fn fmu_get_nominals_of_continuous_states(values: *mut f64, n: usize) -> i32;
    fn fmu_completed_integrator_step(no_set_state_prior: i32, out: *mut CompletedStepOut) -> i32;
    fn fmu_get_directional_derivative(
        unknowns: *const u32,
        n_unknowns: usize,
        knowns: *const u32,
        n_knowns: usize,
        seed: *const f64,
        n_seed: usize,
        sensitivity: *mut f64,
        n_sensitivity: usize,
    ) -> i32;
    fn fmu_do_step(
        current_communication_point: f64,
        communication_step_size: f64,
        no_set_state_prior: i32,
        out: *mut DoStepOut,
    ) -> i32;
    /// `ty` is [`VarType`]'s discriminant; the values are always `f64` here and
    /// the host converts to the FMU's type.
    fn fmu_get_numeric(
        ty: i32,
        vrs: *const u32,
        n_vrs: usize,
        values: *mut f64,
        n_values: usize,
    ) -> i32;
    fn fmu_set_numeric(
        ty: i32,
        vrs: *const u32,
        n_vrs: usize,
        values: *const f64,
        n_values: usize,
    ) -> i32;
    /// `-1` when the FMU does not export the call.
    fn fmu_number_of_continuous_states() -> i32;
    fn fmu_number_of_event_indicators() -> i32;
}

/// The FMU the host has instantiated. There is one per module instance — the
/// page loads one FMU at a time — so the instance carries no state of its own.
pub struct HostFmu {
    kind: i32,
}

impl HostFmu {
    /// Ask the host to instantiate the FMU for `kind`.
    pub fn instantiate(
        kind: i32,
        event_mode: bool,
        early_return: bool,
        logging_on: bool,
    ) -> Result<HostFmu> {
        let ok = unsafe {
            fmu_instantiate(kind, event_mode as i32, early_return as i32, logging_on as i32)
        };
        if ok == 0 {
            return Err(Error::Instantiate { call: "instantiate", log: Vec::new() });
        }
        Ok(HostFmu { kind })
    }

    pub fn kind(&self) -> i32 {
        self.kind
    }
}

impl Drop for HostFmu {
    fn drop(&mut self) {
        unsafe { fmu_free_instance() };
    }
}

/// The host's status, with the call named for the error message.
fn check_host(call: &'static str, raw: i32) -> Result<()> {
    if raw == HOST_FAILED {
        return Err(Error::Unsupported(call.into()));
    }
    check(call, raw)
}

impl Fmi3 for HostFmu {
    fn get_version(&mut self) -> String {
        "3.0".to_string()
    }

    fn enter_initialization_mode(
        &mut self,
        tolerance: Option<f64>,
        start_time: f64,
        stop_time: Option<f64>,
    ) -> Result<()> {
        check_host("fmi3EnterInitializationMode", unsafe {
            fmu_enter_initialization_mode(
                tolerance.is_some() as i32,
                tolerance.unwrap_or(0.0),
                start_time,
                stop_time.is_some() as i32,
                stop_time.unwrap_or(0.0),
            )
        })
    }

    fn exit_initialization_mode(&mut self) -> Result<()> {
        check_host("fmi3ExitInitializationMode", unsafe { fmu_exit_initialization_mode() })
    }

    fn enter_event_mode(&mut self) -> Result<()> {
        check_host("fmi3EnterEventMode", unsafe { fmu_enter_event_mode() })
    }

    fn enter_configuration_mode(&mut self) -> Result<()> {
        check_host("fmi3EnterConfigurationMode", unsafe { fmu_enter_configuration_mode() })
    }

    fn exit_configuration_mode(&mut self) -> Result<()> {
        check_host("fmi3ExitConfigurationMode", unsafe { fmu_exit_configuration_mode() })
    }

    fn update_discrete_states(&mut self) -> Result<DiscreteStates> {
        let mut out = DiscreteStatesOut::default();
        check_host("fmi3UpdateDiscreteStates", unsafe { fmu_update_discrete_states(&mut out) })?;
        Ok(DiscreteStates {
            need_update: out.need_update != 0,
            terminate: out.terminate != 0,
            nominals_changed: out.nominals_changed != 0,
            states_changed: out.states_changed != 0,
            next_event_time: (out.next_event_time_defined != 0).then_some(out.next_event_time),
        })
    }

    fn terminate(&mut self) -> Result<()> {
        check_host("fmi3Terminate", unsafe { fmu_terminate() })
    }

    fn get_numeric(&mut self, ty: VarType, vrs: &[u32], values: &mut [f64]) -> Result<()> {
        check_host("fmi3Get<Type>", unsafe {
            fmu_get_numeric(
                type_code(ty),
                vrs.as_ptr(),
                vrs.len(),
                values.as_mut_ptr(),
                values.len(),
            )
        })
    }

    fn set_numeric(&mut self, ty: VarType, vrs: &[u32], values: &[f64]) -> Result<()> {
        check_host("fmi3Set<Type>", unsafe {
            fmu_set_numeric(type_code(ty), vrs.as_ptr(), vrs.len(), values.as_ptr(), values.len())
        })
    }
}

impl Fmi3ModelExchange for HostFmu {
    fn enter_continuous_time_mode(&mut self) -> Result<()> {
        check_host("fmi3EnterContinuousTimeMode", unsafe { fmu_enter_continuous_time_mode() })
    }

    fn set_time(&mut self, time: f64) -> Result<()> {
        check_host("fmi3SetTime", unsafe { fmu_set_time(time) })
    }

    fn set_continuous_states(&mut self, states: &[f64]) -> Result<()> {
        if states.is_empty() {
            return Ok(());
        }
        check_host("fmi3SetContinuousStates", unsafe {
            fmu_set_continuous_states(states.as_ptr(), states.len())
        })
    }

    fn get_continuous_states(&mut self, states: &mut [f64]) -> Result<()> {
        if states.is_empty() {
            return Ok(());
        }
        check_host("fmi3GetContinuousStates", unsafe {
            fmu_get_continuous_states(states.as_mut_ptr(), states.len())
        })
    }

    fn get_continuous_state_derivatives(&mut self, ders: &mut [f64]) -> Result<()> {
        if ders.is_empty() {
            return Ok(());
        }
        check_host("fmi3GetContinuousStateDerivatives", unsafe {
            fmu_get_continuous_state_derivatives(ders.as_mut_ptr(), ders.len())
        })
    }

    fn get_event_indicators(&mut self, indicators: &mut [f64]) -> Result<()> {
        if indicators.is_empty() {
            return Ok(());
        }
        check_host("fmi3GetEventIndicators", unsafe {
            fmu_get_event_indicators(indicators.as_mut_ptr(), indicators.len())
        })
    }

    fn get_nominals_of_continuous_states(&mut self, nominals: &mut [f64]) -> Result<()> {
        if nominals.is_empty() {
            return Ok(());
        }
        check_host("fmi3GetNominalsOfContinuousStates", unsafe {
            fmu_get_nominals_of_continuous_states(nominals.as_mut_ptr(), nominals.len())
        })
    }

    fn get_number_of_continuous_states(&mut self) -> Result<usize> {
        match unsafe { fmu_number_of_continuous_states() } {
            n if n >= 0 => Ok(n as usize),
            _ => Err(Error::Unsupported("fmi3GetNumberOfContinuousStates".into())),
        }
    }

    fn get_number_of_event_indicators(&mut self) -> Result<usize> {
        match unsafe { fmu_number_of_event_indicators() } {
            n if n >= 0 => Ok(n as usize),
            _ => Err(Error::Unsupported("fmi3GetNumberOfEventIndicators".into())),
        }
    }

    fn get_directional_derivative(
        &mut self,
        unknowns: &[u32],
        knowns: &[u32],
        seed: &[f64],
        sensitivity: &mut [f64],
    ) -> Result<()> {
        check_host("fmi3GetDirectionalDerivative", unsafe {
            fmu_get_directional_derivative(
                unknowns.as_ptr(),
                unknowns.len(),
                knowns.as_ptr(),
                knowns.len(),
                seed.as_ptr(),
                seed.len(),
                sensitivity.as_mut_ptr(),
                sensitivity.len(),
            )
        })
    }

    fn completed_integrator_step(&mut self, no_set_state_prior: bool) -> Result<CompletedStep> {
        let mut out = CompletedStepOut::default();
        check_host("fmi3CompletedIntegratorStep", unsafe {
            fmu_completed_integrator_step(no_set_state_prior as i32, &mut out)
        })?;
        Ok(CompletedStep {
            enter_event_mode: out.enter_event_mode != 0,
            terminate: out.terminate != 0,
        })
    }
}

impl Fmi3CoSimulation for HostFmu {
    fn enter_step_mode(&mut self) -> Result<()> {
        check_host("fmi3EnterStepMode", unsafe { fmu_enter_step_mode() })
    }

    fn do_step(
        &mut self,
        current_communication_point: f64,
        communication_step_size: f64,
        no_set_state_prior: bool,
    ) -> Result<DoStep> {
        let mut out = DoStepOut::default();
        check_host("fmi3DoStep", unsafe {
            fmu_do_step(
                current_communication_point,
                communication_step_size,
                no_set_state_prior as i32,
                &mut out,
            )
        })?;
        Ok(DoStep {
            event_handling_needed: out.event_handling_needed != 0,
            terminate: out.terminate != 0,
            early_return: out.early_return != 0,
            last_successful_time: out.last_successful_time,
        })
    }
}

/// The type codes the host switches on, in [`VarType`] order.
pub fn type_code(ty: VarType) -> i32 {
    match ty {
        VarType::Float32 => 0,
        VarType::Float64 => 1,
        VarType::Int8 => 2,
        VarType::UInt8 => 3,
        VarType::Int16 => 4,
        VarType::UInt16 => 5,
        VarType::Int32 => 6,
        VarType::UInt32 => 7,
        VarType::Int64 => 8,
        VarType::UInt64 => 9,
        VarType::Boolean => 10,
        VarType::String => 11,
        VarType::Binary => 12,
        VarType::Enumeration => 8,
        VarType::Clock => 13,
    }
}
