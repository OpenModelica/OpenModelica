//! The FMI 2.0 C API of a C+Rust FMU, in place of `fmi-export/fmu2_model_interface.c`;
//! `fmi-export/fmu2_rust_interface.c.inc` gives it the standard names.
//!
//! The FMI 3.0 state machine ([`crate::fmi_native`]) translated as
//! `openmodelica_fmi_ls_wasm_to_native` translates it.

use core::ffi::{c_char, c_int, c_void};
use std::ffi::CString;

use openmodelica_fmi3_wasm::fmi_types::Status;

use crate::abi::*;
use crate::fmi_native::{DISCARD, ERROR, Kind, Logger, Native, OK, code, cstr};

/// `fmi2Type`.
const MODEL_EXCHANGE: c_int = 0;
const CO_SIMULATION: c_int = 1;

/// `fmi2StatusKind`.
const DO_STEP_STATUS: c_int = 0;
const PENDING_STATUS: c_int = 1;
const LAST_SUCCESSFUL_TIME: c_int = 2;
const TERMINATED: c_int = 3;

#[repr(C)]
#[derive(Clone, Copy)]
pub struct CallbackFunctions {
    logger: crate::fmi_native::Fmi2LogCb,
    allocate_memory: Option<unsafe extern "C" fn(usize, usize) -> *mut c_void>,
    free_memory: Option<unsafe extern "C" fn(*mut c_void)>,
    step_finished: Option<unsafe extern "C" fn(*mut c_void, c_int)>,
    component_environment: *mut c_void,
}

#[repr(C)]
pub struct EventInfo {
    new_discrete_states_needed: c_int,
    terminate_simulation: c_int,
    nominals_of_continuous_states_changed: c_int,
    values_of_continuous_states_changed: c_int,
    next_event_time_defined: c_int,
    next_event_time: f64,
}

#[derive(Clone, Copy)]
enum Base {
    Real,
    Integer,
    Boolean,
    Str,
}

struct Component {
    n: Box<Native>,
    /// C's `logCategories[LOG_FMI2CALL]`.
    call_log: bool,
    /// The FMI 3.0 value reference of each base type's first FMI 2.0 one.
    offsets: [u32; 4],
    tolerance: Option<f64>,
    start_time: f64,
    stop_time: Option<f64>,
    /// What the `fmi2GetXxxStatus` family reports about the last `fmi2DoStep`.
    step_status: c_int,
    last_successful_time: f64,
    terminated: bool,
    /// What the last `fmi2GetString` handed out, alive until the next one.
    strings: Vec<CString>,
    /// C's `comp->state`, one of [`st`].
    state: u32,
}

fn comp<'a>(c: *mut c_void) -> Option<&'a mut Component> {
    let c = unsafe { (c as *mut Component).as_mut() }?;
    c.n.enter();
    Some(c)
}

/// C's `ModelState`.
mod st {
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
}

fn state_name(state: u32) -> &'static str {
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

/// [`comp`], if `func` may be called in the instance's state: C's `invalidState`,
/// which reports the call and leaves the instance in the error state otherwise.
fn in_state<'a>(c: *mut c_void, func: &str, me: u32, cs: u32) -> Option<&'a mut Component> {
    let c = comp(c)?;
    let is_me = c.n.kind == Kind::ModelExchange;
    if c.state & if is_me { me } else { cs } == 0 {
        let kind = if is_me { "model exchange" } else { "co-simulation" };
        let msg = format!(
            "{func}: Illegal {kind} call sequence. {func} is not allowed in {} state.",
            state_name(c.state)
        );
        c.n.logger.log(ERROR, "logStatusError", &msg);
        c.state = st::ERROR;
        return None;
    }
    Some(c)
}

impl Component {
    /// The state a call that returned `r` leaves the instance in.
    fn moved(&mut self, r: c_int, next: u32) -> c_int {
        if r < DISCARD {
            self.state = next;
        }
        r
    }

    /// An `Error` from a call that only fails on an assertion, reported as C's
    /// `longjmp` catch reports it.
    fn asserted(&self, call: &str, s: Status) -> c_int {
        if s == Status::Error && self.call_log {
            self.n
                .logger
                .log(ERROR, "logFmi2Call", &format!("{call}: terminated by an assertion."));
        }
        code(s)
    }
}

fn b(v: c_int) -> bool {
    v != 0
}

fn fmi2_bool(v: bool) -> c_int {
    c_int::from(v)
}

fn offsets(md: &MODEL_DATA) -> [u32; 4] {
    let real = (md.nVariablesReal + md.nParametersReal + md.nAliasReal) as u32;
    let integer = (md.nVariablesInteger + md.nParametersInteger + md.nAliasInteger) as u32;
    let boolean = (md.nVariablesBoolean + md.nParametersBoolean + md.nAliasBoolean) as u32;
    [0, real, real + integer, real + integer + boolean]
}

unsafe fn shift(c: &Component, vr: *const u32, nvr: usize, base: Base) -> Option<Vec<u32>> {
    if nvr == 0 {
        return Some(Vec::new());
    }
    if vr.is_null() {
        return None;
    }
    let off = c.offsets[base as usize];
    Some((0..nvr).map(|i| unsafe { *vr.add(i) } + off).collect())
}

// ── Lifecycle ───────────────────────────────────────────────────────────────

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2Instantiate(
    instance_name: *const c_char,
    fmu_type: c_int,
    fmu_guid: *const c_char,
    fmu_resource_location: *const c_char,
    functions: *const CallbackFunctions,
    _visible: c_int,
    logging_on: c_int,
) -> *mut c_void {
    let Some(&callbacks) = (unsafe { functions.as_ref() }) else {
        return core::ptr::null_mut();
    };
    if callbacks.logger.is_none() {
        return core::ptr::null_mut();
    }
    let name = cstr(instance_name);
    let logger = Logger::Fmi2 {
        cb: callbacks.logger,
        env: callbacks.component_environment,
        name: CString::new(name.as_str()).unwrap_or_default(),
    };
    let kind = match fmu_type {
        _ if name.is_empty() => {
            logger.log(ERROR, "error", "fmi2Instantiate: Missing instance name.");
            return core::ptr::null_mut();
        }
        MODEL_EXCHANGE => Kind::ModelExchange,
        // No Event Mode and no early return in 2.0: fmi2DoStep handles the events.
        CO_SIMULATION => Kind::CoSimulation {
            event_mode_used: false,
            early_return_allowed: false,
        },
        _ => {
            let msg = format!("fmi2Instantiate: fmuType {fmu_type} is neither Model Exchange nor Co-Simulation.");
            logger.log(ERROR, "error", &msg);
            return core::ptr::null_mut();
        }
    };
    let res = crate::fmi::OpenModelica_parseFmuResourcePath(fmu_resource_location);
    let resources = (!res.is_null()).then(|| {
        let r = CString::new(cstr(res)).unwrap_or_default();
        unsafe { libc::free(res as *mut c_void) };
        r
    });
    let Some(n) = Native::instantiate(
        &name,
        &cstr(fmu_guid),
        resources,
        kind,
        b(logging_on),
        logger,
        "fmi2Instantiate",
    ) else {
        return core::ptr::null_mut();
    };
    let offsets = offsets(unsafe { &*n.model_data() });
    Box::into_raw(Box::new(Component {
        n,
        call_log: b(logging_on),
        offsets,
        tolerance: None,
        start_time: 0.0,
        stop_time: None,
        step_status: OK,
        last_successful_time: 0.0,
        terminated: false,
        strings: Vec::new(),
        state: st::INSTANTIATED,
    })) as *mut c_void
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2FreeInstance(c: *mut c_void) {
    if in_state(c, "fmi2FreeInstance", st::ME_ANY, st::CS_ANY).is_none() {
        return;
    }
    let c = *unsafe { Box::from_raw(c as *mut Component) };
    c.n.free();
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2SetDebugLogging(
    c: *mut c_void,
    logging_on: c_int,
    n_categories: usize,
    categories: *const *const c_char,
) -> c_int {
    let Some(c) = in_state(c, "fmi2SetDebugLogging", st::ME_ANY, st::CS_ANY | st::STEP_IN_PROGRESS) else {
        return ERROR;
    };
    let raw: Vec<String> = if categories.is_null() {
        Vec::new()
    } else {
        (0..n_categories).map(|i| cstr(unsafe { *categories.add(i) })).collect()
    };
    c.call_log = b(logging_on) && raw.iter().any(|c| c == "logFmi2Call" || c == "logAll");
    let cats = raw
        .into_iter()
        .map(|s| {
            if s == "logFmi2Call" {
                "logFmi3Call".to_string()
            } else {
                s
            }
        })
        .collect();
    code(c.n.set_debug_logging(b(logging_on), cats))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2SetupExperiment(
    c: *mut c_void,
    tolerance_defined: c_int,
    tolerance: f64,
    start_time: f64,
    stop_time_defined: c_int,
    stop_time: f64,
) -> c_int {
    let Some(c) = in_state(c, "fmi2SetupExperiment", st::INSTANTIATED, st::INSTANTIATED) else {
        return ERROR;
    };
    c.tolerance = b(tolerance_defined).then_some(tolerance);
    c.start_time = start_time;
    c.stop_time = b(stop_time_defined).then_some(stop_time);
    OK
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2EnterInitializationMode(c: *mut c_void) -> c_int {
    let Some(c) = in_state(c, "fmi2EnterInitializationMode", st::INSTANTIATED, st::INSTANTIATED) else {
        return ERROR;
    };
    c.moved(
        code(
            c.n.inst
                .enter_initialization_mode(c.tolerance, c.start_time, c.stop_time),
        ),
        st::INIT,
    )
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2ExitInitializationMode(c: *mut c_void) -> c_int {
    let Some(c) = in_state(c, "fmi2ExitInitializationMode", st::INIT, st::INIT) else {
        return ERROR;
    };
    let s = c.n.inst.exit_initialization_mode();
    let next = if c.n.kind == Kind::ModelExchange {
        st::EVENT
    } else {
        st::STEP_COMPLETE
    };
    let r = c.moved(c.asserted("fmi2ExitInitializationMode", s), next);
    if r >= ERROR {
        c.state = st::ERROR;
    }
    r
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2Terminate(c: *mut c_void) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi2Terminate",
        st::EVENT | st::CONTINUOUS,
        st::STEP_COMPLETE | st::STEP_FAILED,
    ) else {
        return ERROR;
    };
    let s = c.n.inst.terminate();
    let r = c.asserted("fmi2Terminate", s);
    c.moved(r, st::TERMINATED)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2Reset(c: *mut c_void) -> c_int {
    let Some(c) = in_state(c, "fmi2Reset", st::ME_ANY, st::CS_ANY) else {
        return ERROR;
    };
    (c.tolerance, c.start_time, c.stop_time) = (None, 0.0, None);
    (c.step_status, c.last_successful_time, c.terminated) = (OK, 0.0, false);
    let r = c.n.reset("fmi2Reset");
    c.moved(r, st::INSTANTIATED)
}

// ── Variable access ─────────────────────────────────────────────────────────

macro_rules! getter {
    ($cfn:ident, $fname:literal, $me:expr, $cs:expr, $method:ident, $base:expr, $ty:ty, $conv:expr) => {
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $cfn(c: *mut c_void, vr: *const u32, nvr: usize, values: *mut $ty) -> c_int {
            let Some(c) = in_state(c, $fname, $me, $cs) else {
                return ERROR;
            };
            let Some(refs) = (unsafe { shift(c, vr, nvr, $base) }) else {
                return ERROR;
            };
            if values.is_null() && nvr != 0 {
                return ERROR;
            }
            match c.n.inst.$method(refs) {
                Ok(v) if v.len() == nvr => {
                    for (i, x) in v.into_iter().enumerate() {
                        unsafe { *values.add(i) = $conv(x) };
                    }
                    OK
                }
                Ok(_) => ERROR,
                Err(s) => code(s),
            }
        }
    };
}
getter!(
    omc_fmi2GetReal,
    "fmi2GetReal",
    st::ME_READ,
    st::CS_READ,
    get_float64,
    Base::Real,
    f64,
    |v| v
);
getter!(
    omc_fmi2GetInteger,
    "fmi2GetInteger",
    st::ME_READ,
    st::CS_READ,
    get_int32,
    Base::Integer,
    c_int,
    |v| v
);
getter!(
    omc_fmi2GetBoolean,
    "fmi2GetBoolean",
    st::ME_READ,
    st::CS_READ,
    get_boolean,
    Base::Boolean,
    c_int,
    fmi2_bool
);

macro_rules! setter {
    ($cfn:ident, $fname:literal, $me:expr, $cs:expr, $method:ident, $base:expr, $ty:ty, $conv:expr) => {
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $cfn(c: *mut c_void, vr: *const u32, nvr: usize, values: *const $ty) -> c_int {
            let Some(c) = in_state(c, $fname, $me, $cs) else {
                return ERROR;
            };
            let Some(refs) = (unsafe { shift(c, vr, nvr, $base) }) else {
                return ERROR;
            };
            if values.is_null() && nvr != 0 {
                return ERROR;
            }
            let vals = (0..nvr).map(|i| $conv(unsafe { *values.add(i) })).collect();
            code(c.n.inst.$method(refs, vals))
        }
    };
}
setter!(
    omc_fmi2SetReal,
    "fmi2SetReal",
    st::INSTANTIATED | st::INIT | st::EVENT | st::CONTINUOUS,
    st::INSTANTIATED | st::INIT | st::STEP_COMPLETE,
    set_float64,
    Base::Real,
    f64,
    |v| v
);
setter!(
    omc_fmi2SetInteger,
    "fmi2SetInteger",
    st::INSTANTIATED | st::INIT | st::EVENT,
    st::INSTANTIATED | st::INIT | st::STEP_COMPLETE,
    set_int32,
    Base::Integer,
    c_int,
    |v| v
);
setter!(
    omc_fmi2SetBoolean,
    "fmi2SetBoolean",
    st::INSTANTIATED | st::INIT | st::EVENT,
    st::INSTANTIATED | st::INIT | st::STEP_COMPLETE,
    set_boolean,
    Base::Boolean,
    c_int,
    b
);

/// The pointers stay valid until the next `fmi2GetString` on this instance.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2GetString(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    values: *mut *const c_char,
) -> c_int {
    let Some(c) = in_state(c, "fmi2GetString", st::ME_READ, st::CS_READ) else {
        return ERROR;
    };
    let Some(refs) = (unsafe { shift(c, vr, nvr, Base::Str) }) else {
        return ERROR;
    };
    if values.is_null() && nvr != 0 {
        return ERROR;
    }
    match c.n.inst.get_string(refs) {
        Ok(v) if v.len() == nvr => {
            c.strings = v.into_iter().map(|s| CString::new(s).unwrap_or_default()).collect();
            for (i, s) in c.strings.iter().enumerate() {
                unsafe { *values.add(i) = s.as_ptr() };
            }
            OK
        }
        Ok(_) => ERROR,
        Err(s) => code(s),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2SetString(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    values: *const *const c_char,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi2SetString",
        st::INSTANTIATED | st::INIT | st::EVENT,
        st::INSTANTIATED | st::INIT | st::STEP_COMPLETE,
    ) else {
        return ERROR;
    };
    let Some(refs) = (unsafe { shift(c, vr, nvr, Base::Str) }) else {
        return ERROR;
    };
    if values.is_null() && nvr != 0 {
        return ERROR;
    }
    let vals = (0..nvr).map(|i| cstr(unsafe { *values.add(i) })).collect();
    code(c.n.inst.set_string(refs, vals))
}

// ── FMU state ───────────────────────────────────────────────────────────────
// A state is its serialized bytes, boxed.

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2GetFMUstate(c: *mut c_void, state: *mut *mut c_void) -> c_int {
    let Some(c) = in_state(c, "fmi2GetFMUstate", st::ME_ANY, st::CS_ANY) else {
        return ERROR;
    };
    if state.is_null() {
        return ERROR;
    }
    match c.n.inst.get_fmu_state() {
        Ok(bytes) => {
            unsafe {
                if !(*state).is_null() {
                    drop(Box::from_raw(*state as *mut Vec<u8>));
                }
                *state = Box::into_raw(Box::new(bytes)) as *mut c_void;
            }
            OK
        }
        Err(s) => code(s),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2SetFMUstate(c: *mut c_void, state: *mut c_void) -> c_int {
    let Some(c) = in_state(c, "fmi2SetFMUstate", st::ME_ANY, st::CS_ANY) else {
        return ERROR;
    };
    let Some(bytes) = (unsafe { (state as *const Vec<u8>).as_ref() }) else {
        return ERROR;
    };
    code(c.n.inst.set_fmu_state(bytes.clone()))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2FreeFMUstate(c: *mut c_void, state: *mut *mut c_void) -> c_int {
    if in_state(c, "fmi2FreeFMUstate", st::ME_ANY, st::CS_ANY).is_none() {
        return ERROR;
    }
    if state.is_null() {
        return ERROR;
    }
    unsafe {
        if !(*state).is_null() {
            drop(Box::from_raw(*state as *mut Vec<u8>));
            *state = core::ptr::null_mut();
        }
    }
    OK
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2SerializedFMUstateSize(
    _c: *mut c_void,
    state: *mut c_void,
    size: *mut usize,
) -> c_int {
    let (Some(bytes), false) = (unsafe { (state as *const Vec<u8>).as_ref() }, size.is_null()) else {
        return ERROR;
    };
    unsafe { *size = bytes.len() };
    OK
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2SerializeFMUstate(
    _c: *mut c_void,
    state: *mut c_void,
    out: *mut u8,
    size: usize,
) -> c_int {
    let Some(bytes) = (unsafe { (state as *const Vec<u8>).as_ref() }) else {
        return ERROR;
    };
    if out.is_null() || size != bytes.len() {
        return ERROR;
    }
    unsafe { core::slice::from_raw_parts_mut(out, size).copy_from_slice(bytes) };
    OK
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2DeSerializeFMUstate(
    _c: *mut c_void,
    serialized: *const u8,
    size: usize,
    state: *mut *mut c_void,
) -> c_int {
    if serialized.is_null() || state.is_null() {
        return ERROR;
    }
    let bytes = unsafe { core::slice::from_raw_parts(serialized, size) }.to_vec();
    unsafe { *state = Box::into_raw(Box::new(bytes)) as *mut c_void };
    OK
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2GetDirectionalDerivative(
    c: *mut c_void,
    unknowns: *const u32,
    n_unknowns: usize,
    knowns: *const u32,
    n_knowns: usize,
    dv_known: *const f64,
    dv_unknown: *mut f64,
) -> c_int {
    let Some(c) = in_state(c, "fmi2GetDirectionalDerivative", st::ME_READ, st::CS_READ) else {
        return ERROR;
    };
    let (Some(u), Some(k)) = (unsafe { shift(c, unknowns, n_unknowns, Base::Real) }, unsafe {
        shift(c, knowns, n_knowns, Base::Real)
    }) else {
        return ERROR;
    };
    if (dv_known.is_null() && n_knowns != 0) || (dv_unknown.is_null() && n_unknowns != 0) {
        return ERROR;
    }
    let seed = if n_knowns == 0 {
        Vec::new()
    } else {
        unsafe { core::slice::from_raw_parts(dv_known, n_knowns) }.to_vec()
    };
    match c.n.inst.get_directional_derivative(u, k, seed) {
        Ok(v) if v.len() == n_unknowns => {
            unsafe { core::slice::from_raw_parts_mut(dv_unknown, n_unknowns).copy_from_slice(&v) };
            OK
        }
        Ok(_) => ERROR,
        Err(s) => code(s),
    }
}

// ── Model Exchange ──────────────────────────────────────────────────────────

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2EnterEventMode(c: *mut c_void) -> c_int {
    let Some(c) = in_state(c, "fmi2EnterEventMode", st::EVENT | st::CONTINUOUS, 0) else {
        return ERROR;
    };
    let s = c.n.inst.enter_event_mode();
    let r = c.asserted("fmi2EnterEventMode", s);
    c.moved(r, st::EVENT)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2NewDiscreteStates(c: *mut c_void, event_info: *mut EventInfo) -> c_int {
    let Some(c) = in_state(c, "fmi2NewDiscreteStates", st::EVENT, 0) else {
        return ERROR;
    };
    let Some(info) = (unsafe { event_info.as_mut() }) else {
        return ERROR;
    };
    match c.n.inst.update_discrete_states() {
        Ok(u) => {
            info.new_discrete_states_needed = fmi2_bool(u.new_discrete_states_needed);
            info.terminate_simulation = fmi2_bool(u.terminate_simulation);
            info.nominals_of_continuous_states_changed = fmi2_bool(u.nominals_of_continuous_states_changed);
            info.values_of_continuous_states_changed = fmi2_bool(u.values_of_continuous_states_changed);
            info.next_event_time_defined = fmi2_bool(u.next_event_time_defined);
            info.next_event_time = u.next_event_time;
            OK
        }
        Err(s) => c.asserted("internalEventUpdate", s),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2EnterContinuousTimeMode(c: *mut c_void) -> c_int {
    let Some(c) = in_state(c, "fmi2EnterContinuousTimeMode", st::EVENT, 0) else {
        return ERROR;
    };
    c.moved(code(c.n.inst.enter_continuous_time_mode()), st::CONTINUOUS)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2CompletedIntegratorStep(
    c: *mut c_void,
    no_set_fmu_state_prior: c_int,
    enter_event_mode: *mut c_int,
    terminate_simulation: *mut c_int,
) -> c_int {
    let Some(c) = in_state(c, "fmi2CompletedIntegratorStep", st::CONTINUOUS, 0) else {
        return ERROR;
    };
    if enter_event_mode.is_null() || terminate_simulation.is_null() {
        return ERROR;
    }
    match c.n.inst.completed_integrator_step(b(no_set_fmu_state_prior)) {
        Ok(r) => {
            unsafe {
                *enter_event_mode = fmi2_bool(r.enter_event_mode);
                *terminate_simulation = fmi2_bool(r.terminate_simulation);
            }
            OK
        }
        Err(s) => c.asserted("fmi2CompletedIntegratorStep", s),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2SetTime(c: *mut c_void, time: f64) -> c_int {
    let Some(c) = in_state(c, "fmi2SetTime", st::EVENT | st::CONTINUOUS, 0) else {
        return ERROR;
    };
    code(c.n.inst.set_time(time))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2SetContinuousStates(c: *mut c_void, x: *const f64, nx: usize) -> c_int {
    let Some(c) = in_state(c, "fmi2SetContinuousStates", st::INIT | st::EVENT | st::CONTINUOUS, 0) else {
        return ERROR;
    };
    if x.is_null() && nx != 0 {
        return ERROR;
    }
    let states = if nx == 0 {
        Vec::new()
    } else {
        unsafe { core::slice::from_raw_parts(x, nx) }.to_vec()
    };
    code(c.n.inst.set_continuous_states(states))
}

macro_rules! vector_getter {
    ($cfn:ident, $fname:literal, $me:expr, $cs:expr, $method:ident) => {
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $cfn(c: *mut c_void, out: *mut f64, n: usize) -> c_int {
            let Some(c) = in_state(c, $fname, $me, $cs) else {
                return ERROR;
            };
            if out.is_null() && n != 0 {
                return ERROR;
            }
            match c.n.inst.$method() {
                Ok(v) if v.len() == n => {
                    if n != 0 {
                        unsafe { core::slice::from_raw_parts_mut(out, n).copy_from_slice(&v) };
                    }
                    OK
                }
                Ok(_) => ERROR,
                Err(s) => code(s),
            }
        }
    };
}
vector_getter!(
    omc_fmi2GetDerivatives,
    "fmi2GetDerivatives",
    st::ME_READ,
    0,
    get_continuous_state_derivatives
);
vector_getter!(
    omc_fmi2GetEventIndicators,
    "fmi2GetEventIndicators",
    st::ME_READ,
    0,
    get_event_indicators
);
vector_getter!(
    omc_fmi2GetContinuousStates,
    "fmi2GetContinuousStates",
    st::ME_READ,
    0,
    get_continuous_states
);
vector_getter!(
    omc_fmi2GetNominalsOfContinuousStates,
    "fmi2GetNominalsOfContinuousStates",
    st::ME_ANY,
    0,
    get_nominals_of_continuous_states
);

// ── Co-Simulation ───────────────────────────────────────────────────────────

/// No early return in 2.0: a step that did not reach the communication point is
/// `fmi2Discard`, with the reason in `fmi2GetBooleanStatus(fmi2Terminated)`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2DoStep(
    c: *mut c_void,
    current_communication_point: f64,
    communication_step_size: f64,
    no_set_fmu_state_prior: c_int,
) -> c_int {
    let Some(c) = in_state(c, "fmi2DoStep", 0, st::STEP_COMPLETE) else {
        return ERROR;
    };
    if !matches!(c.n.kind, Kind::CoSimulation { .. }) {
        return ERROR;
    }
    let target = current_communication_point + communication_step_size;
    (c.step_status, c.last_successful_time, c.terminated) = match c.n.inst.do_step(
        current_communication_point,
        communication_step_size,
        b(no_set_fmu_state_prior),
    ) {
        Ok(r) => {
            let status = if r.terminate_simulation || r.early_return || r.discarded {
                DISCARD
            } else {
                OK
            };
            (status, r.last_successful_time, r.terminate_simulation)
        }
        Err(s) => (code(s), target, false),
    };
    c.step_status
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2CancelStep(_c: *mut c_void) -> c_int {
    ERROR
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2GetStatus(c: *mut c_void, kind: c_int, value: *mut c_int) -> c_int {
    let (Some(c), false) = (comp(c), value.is_null()) else {
        return ERROR;
    };
    if kind != DO_STEP_STATUS {
        return ERROR;
    }
    unsafe { *value = c.step_status };
    OK
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2GetRealStatus(c: *mut c_void, kind: c_int, value: *mut f64) -> c_int {
    let (Some(c), false) = (comp(c), value.is_null()) else {
        return ERROR;
    };
    if kind != LAST_SUCCESSFUL_TIME {
        return ERROR;
    }
    unsafe { *value = c.last_successful_time };
    OK
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2GetIntegerStatus(_c: *mut c_void, _kind: c_int, _value: *mut c_int) -> c_int {
    ERROR
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2GetBooleanStatus(c: *mut c_void, kind: c_int, value: *mut c_int) -> c_int {
    let (Some(c), false) = (comp(c), value.is_null()) else {
        return ERROR;
    };
    if kind != TERMINATED {
        return ERROR;
    }
    unsafe { *value = fmi2_bool(c.terminated) };
    OK
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2GetStringStatus(_c: *mut c_void, kind: c_int, value: *mut *const c_char) -> c_int {
    if kind != PENDING_STATUS || value.is_null() {
        return ERROR;
    }
    unsafe { *value = c"".as_ptr() };
    OK
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2SetRealInputDerivatives(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    orders: *const c_int,
    values: *const f64,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi2SetRealInputDerivatives",
        0,
        st::INSTANTIATED | st::INIT | st::STEP_COMPLETE,
    ) else {
        return ERROR;
    };
    let Some(refs) = (unsafe { shift(c, vr, nvr, Base::Real) }) else {
        return ERROR;
    };
    if (orders.is_null() || values.is_null()) && nvr != 0 {
        return ERROR;
    }
    let requests = refs
        .iter()
        .enumerate()
        .map(|(i, vr)| (*vr, unsafe { *orders.add(i) }.max(0) as u32))
        .collect();
    let vals = (0..nvr).map(|i| unsafe { *values.add(i) }).collect();
    code(c.n.inst.set_input_derivatives(requests, vals))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi2GetRealOutputDerivatives(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    orders: *const c_int,
    values: *mut f64,
) -> c_int {
    let Some(c) = in_state(c, "fmi2GetRealOutputDerivatives", 0, st::CS_READ & !st::INIT) else {
        return ERROR;
    };
    let Some(refs) = (unsafe { shift(c, vr, nvr, Base::Real) }) else {
        return ERROR;
    };
    if (values.is_null() || orders.is_null()) && nvr != 0 {
        return ERROR;
    }
    let requests = refs
        .iter()
        .enumerate()
        .map(|(i, vr)| (*vr, unsafe { *orders.add(i) }.max(0) as u32))
        .collect();
    match c.n.inst.get_output_derivatives(requests) {
        Ok(v) if v.len() == nvr => {
            for (i, x) in v.into_iter().enumerate() {
                unsafe { *values.add(i) = x };
            }
            OK
        }
        Ok(_) => ERROR,
        Err(s) => code(s),
    }
}
