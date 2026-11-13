//! The call sequences an FMU accepts: the FMI 2.0 and FMI 3.0 state machines, as
//! C's `invalidState` enforces them. A refused call leaves the instance in the
//! error state.
//!
//! An FMU state handed out by the C API starts with the mode it was taken in, so
//! that `SetFMUState` after an error continues there (FMI 2.0.5, 2.1.3; FMI 3.0.2,
//! 2.2.4).
#![no_std]
extern crate alloc;

use alloc::format;
use alloc::string::String;
use alloc::vec::Vec;

pub const DISCARD: i32 = 2;
pub const ERROR: i32 = 3;

fn save(mode: u32, bytes: &[u8]) -> Vec<u8> {
    [&mode.to_le_bytes()[..], bytes].concat()
}

fn split(bytes: &[u8], modes: u32) -> Option<(u32, &[u8])> {
    let (mode, rest) = bytes.split_first_chunk::<4>()?;
    let mode = u32::from_le_bytes(*mode);
    (mode.is_power_of_two() && mode & modes != 0).then_some((mode, rest))
}

pub mod fmi3 {
    use super::*;

    #[derive(Clone, Copy, PartialEq, Eq, Debug)]
    pub enum Interface {
        ModelExchange,
        CoSimulation { event_mode_used: bool },
        ScheduledExecution,
    }

    pub mod st {
        pub const INSTANTIATED: u32 = 1 << 0;
        pub const CONFIGURATION: u32 = 1 << 1;
        pub const INIT: u32 = 1 << 2;
        pub const EVENT: u32 = 1 << 3;
        pub const CONTINUOUS: u32 = 1 << 4;
        pub const STEP: u32 = 1 << 5;
        pub const CLOCK: u32 = 1 << 6;
        pub const TERMINATED: u32 = 1 << 7;
        pub const ERROR: u32 = 1 << 8;
        pub const ANY: u32 = u32::MAX;
        /// The directional and adjoint derivatives, and fmi3Get{VariableType} after Instantiated.
        pub const DERIVATIVE: u32 = INIT | EVENT | CONTINUOUS | STEP | CLOCK | TERMINATED | ERROR;
        /// fmi3Get{VariableType}. Instantiated returns the start values, or what was
        /// set (modelica/fmi-standard#2174, after 3.0.2).
        pub const GET: u32 = INSTANTIATED | DERIVATIVE;
        /// fmi3SetFloat{32,64}. Configuration Mode takes structural parameters only.
        pub const SET_REAL: u32 = INSTANTIATED | CONFIGURATION | INIT | EVENT | CONTINUOUS | STEP | CLOCK;
        /// The other fmi3Set{VariableType}.
        pub const SET_OTHER: u32 = SET_REAL & !CONTINUOUS;
        /// FMI 3.0.2, 2.3.1: after fmi3Error the FMU is in Terminated, where the FMU
        /// state calls are allowed.
        pub const FMU_STATE: u32 = INSTANTIATED | INIT | EVENT | CONTINUOUS | STEP | CLOCK | TERMINATED | ERROR;
        /// The Model Exchange calls that inspect the instance.
        pub const ME_INSPECT: u32 = INIT | EVENT | CONTINUOUS | TERMINATED | ERROR;
        pub const GET_INTERVAL: u32 = INIT | EVENT | CLOCK;
        pub const TERMINATE: u32 = EVENT | CONTINUOUS | STEP | CLOCK;
        pub const GET_OUTPUT_DERIVATIVES: u32 = STEP | TERMINATED | ERROR;
        pub const ME_COUNT: u32 = INSTANTIATED | EVENT;
        /// Not a state: the call does not change it.
        pub const KEEP: u32 = 0;
    }

    pub fn state_name(state: u32) -> &'static str {
        match state {
            st::INSTANTIATED => "Instantiated",
            st::CONFIGURATION => "Configuration Mode",
            st::INIT => "Initialization Mode",
            st::EVENT => "Event Mode",
            st::CONTINUOUS => "Continuous-Time Mode",
            st::STEP => "Step Mode",
            st::CLOCK => "Clock Activation Mode",
            st::TERMINATED => "Terminated",
            _ => "Error",
        }
    }

    pub struct Machine {
        pub state: u32,
        pub interface: Interface,
    }

    impl Machine {
        pub fn new(interface: Interface) -> Self {
            Machine {
                state: st::INSTANTIATED,
                interface,
            }
        }

        /// The message to log for `func`, which is not allowed in `place`.
        pub fn refuse(&mut self, func: &str, place: &str) -> String {
            self.state = st::ERROR;
            format!("{func}: Illegal call sequence. {func} is not allowed in {place}.")
        }

        pub fn check(&mut self, func: &str, allowed: u32) -> Result<(), String> {
            if self.state & allowed == 0 {
                return Err(self.refuse(func, state_name(self.state)));
            }
            Ok(())
        }

        fn check_for(&mut self, func: &str, allowed: u32, has: bool) -> Result<(), String> {
            self.check(func, allowed)?;
            if !has {
                return Err(self.refuse(func, "this interface"));
            }
            Ok(())
        }

        pub fn check_me(&mut self, func: &str, allowed: u32) -> Result<(), String> {
            let has = self.interface == Interface::ModelExchange;
            self.check_for(func, allowed, has)
        }

        pub fn check_cs(&mut self, func: &str, allowed: u32) -> Result<(), String> {
            let has = matches!(self.interface, Interface::CoSimulation { .. });
            self.check_for(func, allowed, has)
        }

        pub fn check_se(&mut self, func: &str, allowed: u32) -> Result<(), String> {
            let has = self.interface == Interface::ScheduledExecution;
            self.check_for(func, allowed, has)
        }

        /// The state a call that returned `r` leaves the instance in.
        pub fn moved(&mut self, r: i32, next: u32) -> i32 {
            if r < DISCARD && next != st::KEEP {
                self.state = next;
            }
            r
        }

        pub fn exit_initialization_mode(&mut self, r: i32) -> i32 {
            let next = match self.interface {
                Interface::ModelExchange | Interface::CoSimulation { event_mode_used: true } => st::EVENT,
                Interface::CoSimulation { .. } => st::STEP,
                Interface::ScheduledExecution => st::CLOCK,
            };
            let r = self.moved(r, next);
            if r >= ERROR {
                self.state = st::ERROR;
            }
            r
        }

        /// fmi3EnterEventMode: from Step Mode only for an importer that uses Event Mode.
        pub fn enter_event_mode_states(&self) -> u32 {
            match self.interface {
                Interface::ModelExchange => st::CONTINUOUS,
                Interface::CoSimulation { event_mode_used: true } => st::STEP,
                Interface::CoSimulation { .. } | Interface::ScheduledExecution => 0,
            }
        }

        /// The modes an instance of this interface can be in.
        fn modes(&self) -> u32 {
            st::FMU_STATE
                & match self.interface {
                    Interface::ModelExchange => !(st::STEP | st::CLOCK),
                    Interface::CoSimulation { .. } => !(st::CONTINUOUS | st::CLOCK),
                    Interface::ScheduledExecution => !(st::EVENT | st::CONTINUOUS | st::STEP),
                }
        }

        pub fn save(&self, bytes: &[u8]) -> Vec<u8> {
            save(self.state, bytes)
        }

        /// The mode and the instance's bytes of a state [`Self::save`] wrote.
        pub fn split(bytes: &[u8]) -> Option<(u32, &[u8])> {
            split(bytes, st::FMU_STATE)
        }

        /// fmi3SetFMUState of a state taken in `mode` returned `r`. Whether the
        /// instance left the error state for `mode`.
        pub fn restored(&mut self, r: i32, mode: u32) -> bool {
            let back = r < DISCARD && self.state == st::ERROR && mode & self.modes() != 0;
            if back {
                self.state = mode;
            }
            back
        }
    }
}

pub mod fmi2 {
    use super::*;

    /// C's `ModelState`.
    pub mod st {
        pub const INSTANTIATED: u32 = 1 << 1;
        pub const INIT: u32 = 1 << 2;
        pub const STEP_COMPLETE: u32 = 1 << 3;
        pub const STEP_IN_PROGRESS: u32 = 1 << 4;
        pub const STEP_FAILED: u32 = 1 << 5;
        pub const STEP_CANCELED: u32 = 1 << 6;
        pub const EVENT: u32 = 1 << 7;
        pub const CONTINUOUS: u32 = 1 << 8;
        pub const TERMINATED: u32 = 1 << 9;
        pub const ERROR: u32 = 1 << 10;

        pub const ME_ANY: u32 = INSTANTIATED | INIT | EVENT | CONTINUOUS | TERMINATED | ERROR;
        pub const CS_ANY: u32 = INSTANTIATED | INIT | STEP_COMPLETE | STEP_FAILED | STEP_CANCELED | TERMINATED | ERROR;
        pub const ME_READ: u32 = ME_ANY & !INSTANTIATED;
        pub const CS_READ: u32 = CS_ANY & !INSTANTIATED;
        pub const ME_SET_REAL: u32 = INSTANTIATED | INIT | EVENT | CONTINUOUS;
        pub const ME_SET_OTHER: u32 = INSTANTIATED | INIT | EVENT;
        pub const CS_SET: u32 = INSTANTIATED | INIT | STEP_COMPLETE;
        pub const ME_TERMINATE: u32 = EVENT | CONTINUOUS;
        pub const CS_TERMINATE: u32 = STEP_COMPLETE | STEP_FAILED;
    }

    pub fn state_name(state: u32) -> &'static str {
        match state {
            st::INSTANTIATED => "model_state_instantiated",
            st::INIT => "model_state_initialization_mode",
            st::STEP_COMPLETE => "model_state_cs_step_complete",
            st::STEP_IN_PROGRESS => "model_state_cs_step_in_progress",
            st::STEP_FAILED => "model_state_cs_step_failed",
            st::STEP_CANCELED => "model_state_cs_step_canceled",
            st::EVENT => "model_state_me_event_mode",
            st::CONTINUOUS => "model_state_me_continuous_time_mode",
            st::TERMINATED => "model_state_terminated",
            _ => "model_state_error",
        }
    }

    pub struct Machine {
        pub state: u32,
        pub model_exchange: bool,
    }

    impl Machine {
        pub fn new(model_exchange: bool) -> Self {
            Machine {
                state: st::INSTANTIATED,
                model_exchange,
            }
        }

        /// Whether `func` is allowed: in `me` for Model Exchange, in `cs` for
        /// Co-Simulation. Otherwise the message to log.
        pub fn check(&mut self, func: &str, me: u32, cs: u32) -> Result<(), String> {
            let (allowed, kind) = if self.model_exchange {
                (me, "model exchange")
            } else {
                (cs, "co-simulation")
            };
            if self.state & allowed == 0 {
                let msg = format!(
                    "{func}: Illegal {kind} call sequence. {func} is not allowed in {} state.",
                    state_name(self.state)
                );
                self.state = st::ERROR;
                return Err(msg);
            }
            Ok(())
        }

        /// The state a call that returned `r` leaves the instance in.
        pub fn moved(&mut self, r: i32, next: u32) -> i32 {
            if r < DISCARD {
                self.state = next;
            }
            r
        }

        pub fn exit_initialization_mode(&mut self, r: i32) -> i32 {
            let next = if self.model_exchange {
                st::EVENT
            } else {
                st::STEP_COMPLETE
            };
            let r = self.moved(r, next);
            if r >= ERROR {
                self.state = st::ERROR;
            }
            r
        }

        pub fn save(&self, bytes: &[u8]) -> Vec<u8> {
            save(self.state, bytes)
        }

        /// The mode and the instance's bytes of a state [`Self::save`] wrote.
        pub fn split(bytes: &[u8]) -> Option<(u32, &[u8])> {
            split(bytes, st::ME_ANY | st::CS_ANY)
        }

        /// fmi2SetFMUstate of a state taken in `mode` returned `r`. Whether the
        /// instance left the error state for `mode`.
        pub fn restored(&mut self, r: i32, mode: u32) -> bool {
            let modes = if self.model_exchange { st::ME_ANY } else { st::CS_ANY };
            let back = r < DISCARD && self.state == st::ERROR && mode & modes != 0;
            if back {
                self.state = mode;
            }
            back
        }
    }
}
