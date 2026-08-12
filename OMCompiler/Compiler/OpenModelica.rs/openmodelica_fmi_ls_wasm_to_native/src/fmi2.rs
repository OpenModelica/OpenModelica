//! FMI 2.0 C API over the same component the [FMI 3.0 half](crate) serves. The
//! component keeps its FMI 3.0 world, so the translation lives here.
//!
//! Two things do not follow from the call itself:
//!
//! * **Value references.** FMI 2.0 numbers them per base type, FMI 3.0 globally:
//!   `fmi3_vr = fmi2_vr + getFMI3TypeOffset(baseType)`. The exporter writes the
//!   four offsets to `resources/fmi2vr.json`; the C type of the call names the
//!   base type, so the translation is exact.
//! * **The experiment.** `fmi2SetupExperiment` carries what
//!   `fmi3EnterInitializationMode` takes as arguments, so it is kept here until
//!   `fmi2EnterInitializationMode` arrives.

use std::ffi::{c_char, c_void, CString};
use std::path::PathBuf;

use crate::{cstr, inst_mut, st_cs, st_me, Instance, Kind, Log, DISCARD, ERROR, OK};

/// The instance name comes with every call, and the message is a `printf` format
/// string — C's FMUs pass pre-formatted text and no arguments, and so do we.
pub(crate) type LogCb = Option<
    unsafe extern "C" fn(*mut c_void, *const c_char, i32, *const c_char, *const c_char, ...),
>;

/// Only the logger and the environment are used: the component allocates from its
/// own linear memory, and this FMU never reports an asynchronous step.
#[repr(C)]
#[allow(dead_code)]
pub struct CallbackFunctions {
    logger: LogCb,
    allocate_memory: Option<unsafe extern "C" fn(usize, usize) -> *mut c_void>,
    free_memory: Option<unsafe extern "C" fn(*mut c_void)>,
    step_finished: Option<unsafe extern "C" fn(*mut c_void, i32)>,
    component_environment: *mut c_void,
}

#[repr(C)]
pub struct EventInfo {
    new_discrete_states_needed: i32,
    terminate_simulation: i32,
    nominals_of_continuous_states_changed: i32,
    values_of_continuous_states_changed: i32,
    next_event_time_defined: i32,
    next_event_time: f64,
}

/// `fmi2Type`.
const MODEL_EXCHANGE: i32 = 0;
const CO_SIMULATION: i32 = 1;

/// `fmi2StatusKind`.
const DO_STEP_STATUS: i32 = 0;
const PENDING_STATUS: i32 = 1;
const LAST_SUCCESSFUL_TIME: i32 = 2;
const TERMINATED: i32 = 3;

/// `fmi2Boolean` is `int`, not a C99 `bool` as in FMI 3.0.
fn b(v: i32) -> bool {
    v != 0
}
fn fmi2_bool(v: bool) -> i32 {
    i32::from(v)
}

/// The FMI 2.0 base types, in the order `resources/fmi2vr.json` lists them.
#[derive(Clone, Copy)]
enum Base {
    Real,
    Integer,
    Boolean,
    Str,
}

/// The value-reference offsets and the experiment, per the module docs.
pub(crate) struct State {
    offsets: [u32; 4],
    tolerance: Option<f64>,
    start_time: f64,
    stop_time: Option<f64>,
    /// What the `fmi2GetXxxStatus` family reports about the last `fmi2DoStep`.
    step_status: i32,
    last_successful_time: f64,
    terminated: bool,
}

impl State {
    fn offset(&self, base: Base) -> u32 {
        self.offsets[base as usize]
    }
}

/// `{"real":0,"integer":57,"boolean":61,"string":63}`, written by the exporter.
/// Four integers, so scanned rather than parsed.
fn read_offsets(res: &str) -> Result<[u32; 4], String> {
    let path = PathBuf::from(res).join("fmi2vr.json");
    let text = std::fs::read_to_string(&path)
        .map_err(|e| format!("cannot read {} ({e}); this FMU was not exported for FMI 2.0", path.display()))?;
    let mut offsets = [0u32; 4];
    for (i, key) in ["real", "integer", "boolean", "string"].iter().enumerate() {
        let at = text
            .find(&format!("\"{key}\""))
            .and_then(|k| text[k..].find(':').map(|c| k + c + 1))
            .ok_or_else(|| format!("{}: no \"{key}\" offset", path.display()))?;
        let digits: String = text[at..].trim_start().chars().take_while(char::is_ascii_digit).collect();
        offsets[i] = digits
            .parse()
            .map_err(|_| format!("{}: \"{key}\" is not a value-reference offset", path.display()))?;
    }
    Ok(offsets)
}

/// FMI 2.0 passes the resources directory as a URI, FMI 3.0 as a path. Anything
/// that is not a `file:` URI is taken as a path, as some importers hand over.
fn resource_dir(location: &str) -> String {
    let Some(rest) = location.strip_prefix("file:") else { return location.to_owned() };
    // file://host/path and file:///path both leave the path at the third slash.
    let path = rest.strip_prefix("//").map_or(rest, |r| &r[r.find('/').unwrap_or(r.len())..]);
    let mut decoded = Vec::with_capacity(path.len());
    let mut bytes = path.bytes();
    while let Some(c) = bytes.next() {
        if c != b'%' {
            decoded.push(c);
            continue;
        }
        let hex: String = bytes.by_ref().take(2).map(char::from).collect();
        match u8::from_str_radix(&hex, 16) {
            Ok(v) => decoded.push(v),
            Err(_) => decoded.push(b'%'),
        }
    }
    let out = String::from_utf8_lossy(&decoded).into_owned();
    // "/C:/dir" is a Windows path with the URI's leading separator still on it.
    match out.strip_prefix('/') {
        Some(drive) if drive.as_bytes().get(1) == Some(&b':') => drive.to_owned(),
        _ => out,
    }
}

/// The component's value references for an FMI 2.0 `(vr[], nvr)` argument pair.
unsafe fn shift(inst: &Instance, vr: *const u32, nvr: usize, base: Base) -> Option<Vec<u32>> {
    if nvr == 0 {
        return Some(Vec::new());
    }
    if vr.is_null() {
        return None;
    }
    let off = inst.fmi2.as_ref()?.offset(base);
    Some((0..nvr).map(|i| *vr.add(i) + off).collect())
}

// ── Lifecycle ───────────────────────────────────────────────────────────────

#[no_mangle]
pub extern "C" fn fmi2GetTypesPlatform() -> *const c_char {
    c"default".as_ptr()
}

#[no_mangle]
pub extern "C" fn fmi2GetVersion() -> *const c_char {
    c"2.0".as_ptr()
}

#[no_mangle]
pub unsafe extern "C" fn fmi2Instantiate(
    instance_name: *const c_char,
    fmu_type: i32,
    fmu_guid: *const c_char,
    fmu_resource_location: *const c_char,
    functions: *const CallbackFunctions,
    visible: i32,
    logging_on: i32,
) -> *mut c_void {
    let name = cstr(instance_name);
    let token = cstr(fmu_guid);
    let res = resource_dir(&cstr(fmu_resource_location));
    let (env, logger) = match functions.as_ref() {
        Some(f) => (f.component_environment, f.logger),
        None => (std::ptr::null_mut(), None),
    };
    let log = || Log::Fmi2 { cb: logger, name: CString::new(name.as_str()).unwrap_or_default() };
    let built = (|| -> wasmtime::Result<Box<Instance>> {
        let offsets = read_offsets(&res).map_err(wasmtime::Error::msg)?;
        let mut inst = match fmu_type {
            MODEL_EXCHANGE => {
                crate::instantiate_me(&name, &token, &res, b(visible), b(logging_on), env, log())?
            }
            CO_SIMULATION => crate::instantiate_cs(
                &name,
                &token,
                &res,
                b(visible),
                b(logging_on),
                // No Event Mode and no early return in 2.0: fmi2DoStep handles
                // the events itself.
                false,
                false,
                &[],
                env,
                log(),
                None,
            )?,
            _ => wasmtime::bail!("fmi2Instantiate: fmuType {fmu_type} is neither Model Exchange nor Co-Simulation"),
        };
        inst.fmi2 = Some(State {
            offsets,
            tolerance: None,
            start_time: 0.0,
            stop_time: None,
            step_status: OK,
            last_successful_time: 0.0,
            terminated: false,
        });
        Ok(inst)
    })();
    match built {
        Ok(b) => Box::into_raw(b) as *mut c_void,
        Err(e) => crate::report(&name, env, &log(), e),
    }
}

#[no_mangle]
pub unsafe extern "C" fn fmi2FreeInstance(c: *mut c_void) {
    crate::fmi3FreeInstance(c)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2SetDebugLogging(
    c: *mut c_void,
    logging_on: i32,
    n_categories: usize,
    categories: *const *const c_char,
) -> i32 {
    // Only the call-trace category has a different name in 3.0.
    let cats: Vec<String> = if categories.is_null() {
        Vec::new()
    } else {
        (0..n_categories)
            .map(|i| match cstr(*categories.add(i)) {
                s if s == "logFmi2Call" => "logFmi3Call".to_owned(),
                s => s,
            })
            .collect()
    };
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_set_debug_logging(store, h, b(logging_on), &cats) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi2SetupExperiment(
    c: *mut c_void,
    tolerance_defined: i32,
    tolerance: f64,
    start_time: f64,
    stop_time_defined: i32,
    stop_time: f64,
) -> i32 {
    let Some(inst) = inst_mut(c) else { return ERROR };
    let Some(st) = inst.fmi2.as_mut() else { return ERROR };
    st.tolerance = b(tolerance_defined).then_some(tolerance);
    st.start_time = start_time;
    st.stop_time = b(stop_time_defined).then_some(stop_time);
    OK
}

#[no_mangle]
pub unsafe extern "C" fn fmi2EnterInitializationMode(c: *mut c_void) -> i32 {
    let Some(inst) = inst_mut(c) else { return ERROR };
    let Some(&State { tolerance, start_time, stop_time, .. }) = inst.fmi2.as_ref() else { return ERROR };
    on_instance!(Some(inst), |store, g, h, st| match g.call_enter_initialization_mode(store, h, tolerance, start_time, stop_time) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

macro_rules! nullary {
    ($cfn:ident, $wfn:ident) => {
        #[no_mangle]
        pub unsafe extern "C" fn $cfn(c: *mut c_void) -> i32 {
            on_instance!(inst_mut(c), |store, g, h, st| match g.$wfn(store, h) {
                Ok(s) => st(s),
                Err(_) => ERROR,
            })
        }
    };
}
nullary!(fmi2ExitInitializationMode, call_exit_initialization_mode);
nullary!(fmi2Terminate, call_terminate);
nullary!(fmi2EnterEventMode, call_enter_event_mode);

/// Back to the instantiated state: the experiment and the last step's status go.
#[no_mangle]
pub unsafe extern "C" fn fmi2Reset(c: *mut c_void) -> i32 {
    let Some(inst) = inst_mut(c) else { return ERROR };
    if let Some(st) = inst.fmi2.as_mut() {
        (st.tolerance, st.start_time, st.stop_time) = (None, 0.0, None);
        (st.step_status, st.last_successful_time, st.terminated) = (OK, 0.0, false);
    }
    on_instance!(Some(inst), |store, g, h, st| match g.call_reset(store, h) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

// ── Variable access ─────────────────────────────────────────────────────────

macro_rules! getter {
    ($cfn:ident, $wfn:ident, $base:expr, $ty:ty, $conv:expr) => {
        #[no_mangle]
        pub unsafe extern "C" fn $cfn(
            c: *mut c_void,
            value_references: *const u32,
            n_value_references: usize,
            values: *mut $ty,
        ) -> i32 {
            let Some(inst) = inst_mut(c) else { return ERROR };
            let Some(refs) = shift(inst, value_references, n_value_references, $base) else { return ERROR };
            if values.is_null() && n_value_references != 0 {
                return ERROR;
            }
            on_instance!(Some(inst), |store, g, h, st| match g.$wfn(store, h, &refs) {
                Ok(Ok(v)) => {
                    if v.len() != n_value_references {
                        return ERROR;
                    }
                    for (i, x) in v.into_iter().enumerate() {
                        *values.add(i) = $conv(x);
                    }
                    OK
                }
                Ok(Err(s)) => st(s),
                Err(_) => ERROR,
            })
        }
    };
}
getter!(fmi2GetReal, call_get_float64, Base::Real, f64, |v| v);
getter!(fmi2GetInteger, call_get_int32, Base::Integer, i32, |v| v);
getter!(fmi2GetBoolean, call_get_boolean, Base::Boolean, i32, fmi2_bool);

macro_rules! setter {
    ($cfn:ident, $wfn:ident, $base:expr, $ty:ty, $conv:expr) => {
        #[no_mangle]
        pub unsafe extern "C" fn $cfn(
            c: *mut c_void,
            value_references: *const u32,
            n_value_references: usize,
            values: *const $ty,
        ) -> i32 {
            let Some(inst) = inst_mut(c) else { return ERROR };
            let Some(refs) = shift(inst, value_references, n_value_references, $base) else { return ERROR };
            if values.is_null() && n_value_references != 0 {
                return ERROR;
            }
            let vals: Vec<_> = (0..n_value_references).map(|i| $conv(*values.add(i))).collect();
            on_instance!(Some(inst), |store, g, h, st| match g.$wfn(store, h, &refs, &vals) {
                Ok(s) => st(s),
                Err(_) => ERROR,
            })
        }
    };
}
setter!(fmi2SetReal, call_set_float64, Base::Real, f64, |v| v);
setter!(fmi2SetInteger, call_set_int32, Base::Integer, i32, |v| v);
setter!(fmi2SetBoolean, call_set_boolean, Base::Boolean, i32, b);

/// The pointers borrow from the instance until the next `fmi2GetString` on it.
#[no_mangle]
pub unsafe extern "C" fn fmi2GetString(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    values: *mut *const c_char,
) -> i32 {
    let Some(inst) = inst_mut(c) else { return ERROR };
    let Some(refs) = shift(inst, value_references, n_value_references, Base::Str) else { return ERROR };
    if values.is_null() && n_value_references != 0 {
        return ERROR;
    }
    let got = {
        let Instance { store, kind, .. } = &mut *inst;
        match kind {
            Kind::Me { world, handle } => world
                .fmi_fmi3_model_exchange()
                .model_exchange_instance()
                .call_get_string(store, *handle, &refs)
                .map(|r| r.map_err(crate::st_me)),
            Kind::Cs { world, handle } => world
                .fmi_fmi3_co_simulation()
                .co_simulation_instance()
                .call_get_string(store, *handle, &refs)
                .map(|r| r.map_err(crate::st_cs)),
        }
    };
    let strings = match got {
        Ok(Ok(v)) => v,
        Ok(Err(s)) => return s,
        Err(_) => return ERROR,
    };
    if strings.len() != n_value_references {
        return ERROR;
    }
    inst.strings = strings.into_iter().map(|s| CString::new(s).unwrap_or_default()).collect();
    for (i, s) in inst.strings.iter().enumerate() {
        *values.add(i) = s.as_ptr();
    }
    OK
}

#[no_mangle]
pub unsafe extern "C" fn fmi2SetString(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    values: *const *const c_char,
) -> i32 {
    let Some(inst) = inst_mut(c) else { return ERROR };
    let Some(refs) = shift(inst, value_references, n_value_references, Base::Str) else { return ERROR };
    if values.is_null() && n_value_references != 0 {
        return ERROR;
    }
    let vals: Vec<String> = (0..n_value_references).map(|i| cstr(*values.add(i))).collect();
    on_instance!(Some(inst), |store, g, h, st| match g.call_set_string(store, h, &refs, &vals) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

// ── FMU state ───────────────────────────────────────────────────────────────
// Identical in both versions, down to the opaque pointer being a boxed `Vec<u8>`.

#[no_mangle]
pub unsafe extern "C" fn fmi2GetFMUstate(c: *mut c_void, state: *mut *mut c_void) -> i32 {
    crate::fmi3GetFMUState(c, state)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2SetFMUstate(c: *mut c_void, state: *mut c_void) -> i32 {
    crate::fmi3SetFMUState(c, state)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2FreeFMUstate(c: *mut c_void, state: *mut *mut c_void) -> i32 {
    crate::fmi3FreeFMUState(c, state)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2SerializedFMUstateSize(c: *mut c_void, state: *mut c_void, size: *mut usize) -> i32 {
    crate::fmi3SerializedFMUStateSize(c, state, size)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2SerializeFMUstate(
    c: *mut c_void,
    state: *mut c_void,
    serialized: *mut u8,
    size: usize,
) -> i32 {
    crate::fmi3SerializeFMUState(c, state, serialized, size)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2DeSerializeFMUstate(
    c: *mut c_void,
    serialized: *const u8,
    size: usize,
    state: *mut *mut c_void,
) -> i32 {
    crate::fmi3DeserializeFMUState(c, serialized, size, state)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2GetDirectionalDerivative(
    c: *mut c_void,
    unknowns: *const u32,
    n_unknowns: usize,
    knowns: *const u32,
    n_knowns: usize,
    dv_known: *const f64,
    dv_unknown: *mut f64,
) -> i32 {
    let Some(inst) = inst_mut(c) else { return ERROR };
    // Both directions are Real-valued, so both index the Real block.
    let (Some(u), Some(k)) = (
        shift(inst, unknowns, n_unknowns, Base::Real),
        shift(inst, knowns, n_knowns, Base::Real),
    ) else {
        return ERROR;
    };
    if (dv_known.is_null() && n_knowns != 0) || (dv_unknown.is_null() && n_unknowns != 0) {
        return ERROR;
    }
    let seed = if n_knowns == 0 { &[][..] } else { std::slice::from_raw_parts(dv_known, n_knowns) };
    on_instance!(Some(inst), |store, g, h, st| match g.call_get_directional_derivative(store, h, &u, &k, seed) {
        Ok(Ok(v)) => {
            if v.len() != n_unknowns {
                return ERROR;
            }
            std::slice::from_raw_parts_mut(dv_unknown, n_unknowns).copy_from_slice(&v);
            OK
        }
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

// ── Model Exchange ──────────────────────────────────────────────────────────

#[no_mangle]
pub unsafe extern "C" fn fmi2EnterContinuousTimeMode(c: *mut c_void) -> i32 {
    crate::fmi3EnterContinuousTimeMode(c)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2SetTime(c: *mut c_void, time: f64) -> i32 {
    crate::fmi3SetTime(c, time)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2SetContinuousStates(c: *mut c_void, x: *const f64, nx: usize) -> i32 {
    crate::fmi3SetContinuousStates(c, x, nx)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2GetDerivatives(c: *mut c_void, derivatives: *mut f64, nx: usize) -> i32 {
    crate::fmi3GetContinuousStateDerivatives(c, derivatives, nx)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2GetEventIndicators(c: *mut c_void, event_indicators: *mut f64, ni: usize) -> i32 {
    crate::fmi3GetEventIndicators(c, event_indicators, ni)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2GetContinuousStates(c: *mut c_void, x: *mut f64, nx: usize) -> i32 {
    crate::fmi3GetContinuousStates(c, x, nx)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2GetNominalsOfContinuousStates(c: *mut c_void, x_nominal: *mut f64, nx: usize) -> i32 {
    crate::fmi3GetNominalsOfContinuousStates(c, x_nominal, nx)
}

#[no_mangle]
pub unsafe extern "C" fn fmi2NewDiscreteStates(c: *mut c_void, event_info: *mut EventInfo) -> i32 {
    let Some(info) = event_info.as_mut() else { return ERROR };
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_update_discrete_states(store, h) {
        Ok(Ok(u)) => {
            info.new_discrete_states_needed = fmi2_bool(u.new_discrete_states_needed);
            info.terminate_simulation = fmi2_bool(u.terminate_simulation);
            info.nominals_of_continuous_states_changed = fmi2_bool(u.nominals_of_continuous_states_changed);
            info.values_of_continuous_states_changed = fmi2_bool(u.values_of_continuous_states_changed);
            info.next_event_time_defined = fmi2_bool(u.next_event_time_defined);
            info.next_event_time = u.next_event_time;
            OK
        }
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi2CompletedIntegratorStep(
    c: *mut c_void,
    no_set_fmu_state_prior: i32,
    enter_event_mode: *mut i32,
    terminate_simulation: *mut i32,
) -> i32 {
    if enter_event_mode.is_null() || terminate_simulation.is_null() {
        return ERROR;
    }
    let (mut enter, mut terminate) = (false, false);
    let status = crate::fmi3CompletedIntegratorStep(c, b(no_set_fmu_state_prior), &mut enter, &mut terminate);
    if status == OK {
        *enter_event_mode = fmi2_bool(enter);
        *terminate_simulation = fmi2_bool(terminate);
    }
    status
}

// ── Co-Simulation ───────────────────────────────────────────────────────────

/// No early return in 2.0: a step that did not reach the communication point is
/// `fmi2Discard`, with the reason in `fmi2GetBooleanStatus(fmi2Terminated)`.
#[no_mangle]
pub unsafe extern "C" fn fmi2DoStep(
    c: *mut c_void,
    current_communication_point: f64,
    communication_step_size: f64,
    no_set_fmu_state_prior: i32,
) -> i32 {
    let target = current_communication_point + communication_step_size;
    let (mut event, mut terminate, mut early, mut last) = (false, false, false, target);
    let status = crate::fmi3DoStep(
        c,
        current_communication_point,
        communication_step_size,
        b(no_set_fmu_state_prior),
        &mut event,
        &mut terminate,
        &mut early,
        &mut last,
    );
    let Some(inst) = inst_mut(c) else { return ERROR };
    let Some(st) = inst.fmi2.as_mut() else { return ERROR };
    st.last_successful_time = last;
    st.terminated = terminate;
    st.step_status = if status != OK {
        status
    } else if terminate || early {
        DISCARD
    } else {
        OK
    };
    st.step_status
}

/// `fmi2DoStep` never returns `fmi2Pending`, so there is never a step to cancel.
#[no_mangle]
pub unsafe extern "C" fn fmi2CancelStep(_c: *mut c_void) -> i32 {
    ERROR
}

#[no_mangle]
pub unsafe extern "C" fn fmi2GetStatus(c: *mut c_void, kind: i32, value: *mut i32) -> i32 {
    let (Some(inst), false) = (inst_mut(c), value.is_null()) else { return ERROR };
    let Some(st) = inst.fmi2.as_ref() else { return ERROR };
    match kind {
        DO_STEP_STATUS => {
            *value = st.step_status;
            OK
        }
        _ => ERROR,
    }
}

#[no_mangle]
pub unsafe extern "C" fn fmi2GetRealStatus(c: *mut c_void, kind: i32, value: *mut f64) -> i32 {
    let (Some(inst), false) = (inst_mut(c), value.is_null()) else { return ERROR };
    let Some(st) = inst.fmi2.as_ref() else { return ERROR };
    match kind {
        LAST_SUCCESSFUL_TIME => {
            *value = st.last_successful_time;
            OK
        }
        _ => ERROR,
    }
}

/// No status kind is integer-valued.
#[no_mangle]
pub unsafe extern "C" fn fmi2GetIntegerStatus(_c: *mut c_void, _kind: i32, _value: *mut i32) -> i32 {
    ERROR
}

#[no_mangle]
pub unsafe extern "C" fn fmi2GetBooleanStatus(c: *mut c_void, kind: i32, value: *mut i32) -> i32 {
    let (Some(inst), false) = (inst_mut(c), value.is_null()) else { return ERROR };
    let Some(st) = inst.fmi2.as_ref() else { return ERROR };
    match kind {
        TERMINATED => {
            *value = fmi2_bool(st.terminated);
            OK
        }
        _ => ERROR,
    }
}

/// `fmi2PendingStatus` is the only string-valued kind, and nothing is ever pending.
#[no_mangle]
pub unsafe extern "C" fn fmi2GetStringStatus(_c: *mut c_void, kind: i32, value: *mut *const c_char) -> i32 {
    if kind != PENDING_STATUS || value.is_null() {
        return ERROR;
    }
    *value = c"".as_ptr();
    OK
}

/// The component's Co-Simulation driver takes no derivative information.
#[no_mangle]
pub unsafe extern "C" fn fmi2SetRealInputDerivatives(
    _c: *mut c_void,
    _value_references: *const u32,
    _n_value_references: usize,
    _orders: *const i32,
    _values: *const f64,
) -> i32 {
    ERROR
}

#[no_mangle]
pub unsafe extern "C" fn fmi2GetRealOutputDerivatives(
    _c: *mut c_void,
    _value_references: *const u32,
    _n_value_references: usize,
    _orders: *const i32,
    _values: *mut f64,
) -> i32 {
    ERROR
}
