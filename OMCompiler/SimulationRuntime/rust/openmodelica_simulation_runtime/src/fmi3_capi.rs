//! The FMI 3.0 C API of a C+Rust FMU, in place of `fmi-export/fmu3_model_interface.c`;
//! `fmi-export/fmu3_rust_interface.c.inc` gives it the standard names.

use core::ffi::{c_char, c_int, c_void};
use std::ffi::CString;

use crate::fmi_native::{DISCARD, ERROR, Fmi3LogCb, Kind, Logger, Native, OK, code, cstr};

struct Component {
    n: Box<Native>,
    /// What `fmi3GetString` handed out, alive until the next call.
    strings: Vec<CString>,
    /// The FMI 3.0 state the calls so far left the instance in, one of [`st`].
    state: u32,
}

impl Component {
    /// The state a call that returned `r` leaves the instance in.
    fn moved(&mut self, r: c_int, next: u32) -> c_int {
        if r < DISCARD && next != st::KEEP {
            self.state = next;
        }
        r
    }
}

mod st {
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
    /// Not a state: the call does not change it.
    pub const KEEP: u32 = 0;
}

fn state_name(state: u32) -> &'static str {
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

/// [`comp`], if `func` may be called in the instance's state (FMI 3.0, 5.x state
/// machines); otherwise reported, and the instance is in the error state, as
/// C's `invalidState` leaves it.
fn in_state<'a>(c: *mut c_void, func: &str, allowed: u32) -> Option<&'a mut Component> {
    let c = comp(c)?;
    if c.state & allowed == 0 {
        let msg = format!(
            "{func}: Illegal call sequence. {func} is not allowed in {}.",
            state_name(c.state)
        );
        c.n.logger.log(ERROR, "logStatusError", &msg);
        c.state = st::ERROR;
        return None;
    }
    Some(c)
}

fn in_state_me<'a>(c: *mut c_void, func: &str, allowed: u32) -> Option<&'a mut Component> {
    in_state(c, func, allowed).filter(|c| c.n.kind == Kind::ModelExchange)
}

fn in_state_cs<'a>(c: *mut c_void, func: &str, allowed: u32) -> Option<&'a mut Component> {
    in_state(c, func, allowed).filter(|c| matches!(c.n.kind, Kind::CoSimulation { .. }))
}

fn comp<'a>(c: *mut c_void) -> Option<&'a mut Component> {
    let c = unsafe { (c as *mut Component).as_mut() }?;
    c.n.enter();
    Some(c)
}

unsafe fn vrs(p: *const u32, n: usize) -> Vec<u32> {
    if p.is_null() || n == 0 {
        Vec::new()
    } else {
        unsafe { core::slice::from_raw_parts(p, n) }.to_vec()
    }
}

unsafe fn slice<'a, T>(p: *const T, n: usize) -> Option<&'a [T]> {
    match (p.is_null(), n) {
        (_, 0) => Some(&[]),
        (true, _) => None,
        (false, _) => Some(unsafe { core::slice::from_raw_parts(p, n) }),
    }
}

/// Copy `v` into the importer's `(out, n)`, which must be exactly its length.
fn out<T: Copy>(v: &[T], out: *mut T, n: usize) -> c_int {
    if v.len() != n || (out.is_null() && n != 0) {
        return ERROR;
    }
    if n != 0 {
        unsafe { core::slice::from_raw_parts_mut(out, n).copy_from_slice(v) };
    }
    OK
}

/// The `(value reference, derivative order)` pairs the state machine takes.
unsafe fn requests(vr: *const u32, n: usize, orders: *const c_int) -> Option<Vec<(u32, u32)>> {
    if n == 0 {
        return Some(Vec::new());
    }
    if vr.is_null() || orders.is_null() {
        return None;
    }
    (0..n)
        .map(|i| unsafe {
            let order = *orders.add(i);
            (order >= 0).then(|| (*vr.add(i), order as u32))
        })
        .collect()
}

fn instantiate(
    instance_name: *const c_char,
    instantiation_token: *const c_char,
    resource_path: *const c_char,
    logging_on: bool,
    env: *mut c_void,
    log_message: Fmi3LogCb,
    kind: Kind,
    call: &str,
) -> *mut c_void {
    let name = cstr(instance_name);
    let logger = Logger::Fmi3 { cb: log_message, env };
    let resources = (!resource_path.is_null()).then(|| CString::new(cstr(resource_path)).unwrap_or_default());
    let Some(n) = Native::instantiate(
        &name,
        &cstr(instantiation_token),
        resources,
        kind,
        logging_on,
        logger,
        call,
    ) else {
        return core::ptr::null_mut();
    };
    Box::into_raw(Box::new(Component {
        n,
        strings: Vec::new(),
        state: st::INSTANTIATED,
    })) as *mut c_void
}

// ── Lifecycle ───────────────────────────────────────────────────────────────

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3InstantiateModelExchange(
    instance_name: *const c_char,
    instantiation_token: *const c_char,
    resource_path: *const c_char,
    _visible: bool,
    logging_on: bool,
    instance_environment: *mut c_void,
    log_message: Fmi3LogCb,
) -> *mut c_void {
    instantiate(
        instance_name,
        instantiation_token,
        resource_path,
        logging_on,
        instance_environment,
        log_message,
        Kind::ModelExchange,
        "fmi3InstantiateModelExchange",
    )
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3InstantiateCoSimulation(
    instance_name: *const c_char,
    instantiation_token: *const c_char,
    resource_path: *const c_char,
    _visible: bool,
    logging_on: bool,
    event_mode_used: bool,
    early_return_allowed: bool,
    _required_intermediate_variables: *const u32,
    _n_required_intermediate_variables: usize,
    instance_environment: *mut c_void,
    log_message: Fmi3LogCb,
    _intermediate_update: *mut c_void,
) -> *mut c_void {
    instantiate(
        instance_name,
        instantiation_token,
        resource_path,
        logging_on,
        instance_environment,
        log_message,
        Kind::CoSimulation {
            event_mode_used,
            early_return_allowed,
        },
        "fmi3InstantiateCoSimulation",
    )
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3InstantiateScheduledExecution(
    instance_name: *const c_char,
    instantiation_token: *const c_char,
    resource_path: *const c_char,
    _visible: bool,
    logging_on: bool,
    instance_environment: *mut c_void,
    log_message: Fmi3LogCb,
    _clock_update: *mut c_void,
    _lock_preemption: *mut c_void,
    _unlock_preemption: *mut c_void,
) -> *mut c_void {
    instantiate(
        instance_name,
        instantiation_token,
        resource_path,
        logging_on,
        instance_environment,
        log_message,
        Kind::ScheduledExecution,
        "fmi3InstantiateScheduledExecution",
    )
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3FreeInstance(c: *mut c_void) {
    if in_state(c, "fmi3FreeInstance", st::ANY).is_none() {
        return;
    }
    let c = *unsafe { Box::from_raw(c as *mut Component) };
    c.n.free();
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3Reset(c: *mut c_void) -> c_int {
    let Some(c) = in_state(c, "fmi3Reset", st::ANY) else {
        return ERROR;
    };
    let r = c.n.reset("fmi3Reset");
    c.moved(r, st::INSTANTIATED)
}

macro_rules! nullary {
    ($cfn:ident, $fname:literal, $mask:expr, $next:expr, $method:ident) => {
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $cfn(c: *mut c_void) -> c_int {
            let Some(c) = in_state(c, $fname, $mask) else {
                return ERROR;
            };
            let r = code(c.n.inst.$method());
            c.moved(r, $next)
        }
    };
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3ExitInitializationMode(c: *mut c_void) -> c_int {
    let Some(c) = in_state(c, "fmi3ExitInitializationMode", st::INIT) else {
        return ERROR;
    };
    let next = match c.n.kind {
        Kind::ModelExchange
        | Kind::CoSimulation {
            event_mode_used: true, ..
        } => st::EVENT,
        Kind::CoSimulation { .. } => st::STEP,
        Kind::ScheduledExecution => st::CLOCK,
    };
    let r = c.moved(code(c.n.inst.exit_initialization_mode()), next);
    if r >= ERROR {
        c.state = st::ERROR;
    }
    r
}
nullary!(
    omc_fmi3EnterEventMode,
    "fmi3EnterEventMode",
    st::EVENT | st::CONTINUOUS | st::STEP,
    st::EVENT,
    enter_event_mode
);
nullary!(
    omc_fmi3Terminate,
    "fmi3Terminate",
    st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    st::TERMINATED,
    terminate
);
nullary!(
    omc_fmi3EnterConfigurationMode,
    "fmi3EnterConfigurationMode",
    st::INSTANTIATED,
    st::CONFIGURATION,
    enter_configuration_mode
);
nullary!(
    omc_fmi3ExitConfigurationMode,
    "fmi3ExitConfigurationMode",
    st::CONFIGURATION,
    st::INSTANTIATED,
    exit_configuration_mode
);
nullary!(
    omc_fmi3EvaluateDiscreteStates,
    "fmi3EvaluateDiscreteStates",
    st::EVENT | st::CLOCK,
    st::KEEP,
    evaluate_discrete_states
);
nullary!(
    omc_fmi3EnterStepMode,
    "fmi3EnterStepMode",
    st::EVENT,
    st::STEP,
    enter_step_mode
);

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3EnterInitializationMode(
    c: *mut c_void,
    tolerance_defined: bool,
    tolerance: f64,
    start_time: f64,
    stop_time_defined: bool,
    stop_time: f64,
) -> c_int {
    let Some(c) = in_state(c, "fmi3EnterInitializationMode", st::INSTANTIATED) else {
        return ERROR;
    };
    let (tol, stop) = (
        tolerance_defined.then_some(tolerance),
        stop_time_defined.then_some(stop_time),
    );
    let r = code(c.n.inst.enter_initialization_mode(tol, start_time, stop));
    c.moved(r, st::INIT)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3SetDebugLogging(
    c: *mut c_void,
    logging_on: bool,
    n_categories: usize,
    categories: *const *const c_char,
) -> c_int {
    let Some(c) = in_state(c, "fmi3SetDebugLogging", st::ANY) else {
        return ERROR;
    };
    let cats = if categories.is_null() {
        Vec::new()
    } else {
        (0..n_categories).map(|i| cstr(unsafe { *categories.add(i) })).collect()
    };
    code(c.n.set_debug_logging(logging_on, cats))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3UpdateDiscreteStates(
    c: *mut c_void,
    discrete_states_need_update: *mut bool,
    terminate_simulation: *mut bool,
    nominals_changed: *mut bool,
    values_changed: *mut bool,
    next_event_time_defined: *mut bool,
    next_event_time: *mut f64,
) -> c_int {
    let Some(c) = in_state(c, "fmi3UpdateDiscreteStates", st::EVENT | st::CLOCK) else {
        return ERROR;
    };
    match c.n.inst.update_discrete_states() {
        Ok(i) => {
            unsafe {
                if !discrete_states_need_update.is_null() {
                    *discrete_states_need_update = i.new_discrete_states_needed;
                }
                if !terminate_simulation.is_null() {
                    *terminate_simulation = i.terminate_simulation;
                }
                if !nominals_changed.is_null() {
                    *nominals_changed = i.nominals_of_continuous_states_changed;
                }
                if !values_changed.is_null() {
                    *values_changed = i.values_of_continuous_states_changed;
                }
                if !next_event_time_defined.is_null() {
                    *next_event_time_defined = i.next_event_time_defined;
                }
                if !next_event_time.is_null() {
                    *next_event_time = i.next_event_time;
                }
            }
            OK
        }
        Err(s) => code(s),
    }
}

// ── Variable access ─────────────────────────────────────────────────────────

macro_rules! getter {
    ($cfn:ident, $fname:literal, $mask:expr, $method:ident, $ty:ty) => {
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $cfn(c: *mut c_void, vr: *const u32, nvr: usize, values: *mut $ty, n: usize) -> c_int {
            let Some(c) = in_state(c, $fname, $mask) else {
                return ERROR;
            };
            match c.n.inst.$method(unsafe { vrs(vr, nvr) }) {
                Ok(v) => out(&v, values, n),
                Err(s) => code(s),
            }
        }
    };
}
getter!(
    omc_fmi3GetFloat32,
    "fmi3GetFloat32",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_float32,
    f32
);
getter!(
    omc_fmi3GetFloat64,
    "fmi3GetFloat64",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_float64,
    f64
);
getter!(
    omc_fmi3GetInt8,
    "fmi3GetInt8",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_int8,
    i8
);
getter!(
    omc_fmi3GetUInt8,
    "fmi3GetUInt8",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_uint8,
    u8
);
getter!(
    omc_fmi3GetInt16,
    "fmi3GetInt16",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_int16,
    i16
);
getter!(
    omc_fmi3GetUInt16,
    "fmi3GetUInt16",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_uint16,
    u16
);
getter!(
    omc_fmi3GetInt32,
    "fmi3GetInt32",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_int32,
    i32
);
getter!(
    omc_fmi3GetUInt32,
    "fmi3GetUInt32",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_uint32,
    u32
);
getter!(
    omc_fmi3GetInt64,
    "fmi3GetInt64",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_int64,
    i64
);
getter!(
    omc_fmi3GetUInt64,
    "fmi3GetUInt64",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_uint64,
    u64
);
getter!(
    omc_fmi3GetBoolean,
    "fmi3GetBoolean",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_boolean,
    bool
);

macro_rules! setter {
    ($cfn:ident, $fname:literal, $mask:expr, $method:ident, $ty:ty) => {
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $cfn(
            c: *mut c_void,
            vr: *const u32,
            nvr: usize,
            values: *const $ty,
            n: usize,
        ) -> c_int {
            let Some(c) = in_state(c, $fname, $mask) else {
                return ERROR;
            };
            let Some(v) = (unsafe { slice(values, n) }) else {
                return ERROR;
            };
            code(c.n.inst.$method(unsafe { vrs(vr, nvr) }, v.to_vec()))
        }
    };
}
setter!(
    omc_fmi3SetFloat32,
    "fmi3SetFloat32",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    set_float32,
    f32
);
setter!(
    omc_fmi3SetFloat64,
    "fmi3SetFloat64",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    set_float64,
    f64
);
setter!(
    omc_fmi3SetInt8,
    "fmi3SetInt8",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    set_int8,
    i8
);
setter!(
    omc_fmi3SetUInt8,
    "fmi3SetUInt8",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    set_uint8,
    u8
);
setter!(
    omc_fmi3SetInt16,
    "fmi3SetInt16",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    set_int16,
    i16
);
setter!(
    omc_fmi3SetUInt16,
    "fmi3SetUInt16",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    set_uint16,
    u16
);
setter!(
    omc_fmi3SetInt32,
    "fmi3SetInt32",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    set_int32,
    i32
);
setter!(
    omc_fmi3SetUInt32,
    "fmi3SetUInt32",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    set_uint32,
    u32
);
setter!(
    omc_fmi3SetInt64,
    "fmi3SetInt64",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    set_int64,
    i64
);
setter!(
    omc_fmi3SetUInt64,
    "fmi3SetUInt64",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    set_uint64,
    u64
);
setter!(
    omc_fmi3SetBoolean,
    "fmi3SetBoolean",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    set_boolean,
    bool
);

/// A Clock has no `nValues`: one value per reference.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3GetClock(c: *mut c_void, vr: *const u32, nvr: usize, values: *mut bool) -> c_int {
    let Some(c) = in_state(c, "fmi3GetClock", st::EVENT | st::CLOCK) else {
        return ERROR;
    };
    match c.n.inst.get_clock(unsafe { vrs(vr, nvr) }) {
        Ok(v) => out(&v, values, nvr),
        Err(s) => code(s),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3SetClock(c: *mut c_void, vr: *const u32, nvr: usize, values: *const bool) -> c_int {
    let Some(c) = in_state(c, "fmi3SetClock", st::EVENT | st::CLOCK) else {
        return ERROR;
    };
    let Some(v) = (unsafe { slice(values, nvr) }) else {
        return ERROR;
    };
    code(c.n.inst.set_clock(unsafe { vrs(vr, nvr) }, v.to_vec()))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3GetString(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    values: *mut *const c_char,
    n: usize,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3GetString",
        st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    ) else {
        return ERROR;
    };
    match c.n.inst.get_string(unsafe { vrs(vr, nvr) }) {
        Ok(v) => {
            c.strings = v.into_iter().map(|s| CString::new(s).unwrap_or_default()).collect();
            let ptrs: Vec<*const c_char> = c.strings.iter().map(|s| s.as_ptr()).collect();
            out(&ptrs, values, n)
        }
        Err(s) => code(s),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3SetString(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    values: *const *const c_char,
    n: usize,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3SetString",
        st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    ) else {
        return ERROR;
    };
    let Some(v) = (unsafe { slice(values, n) }) else {
        return ERROR;
    };
    code(
        c.n.inst
            .set_string(unsafe { vrs(vr, nvr) }, v.iter().map(|p| cstr(*p)).collect()),
    )
}

/// An external object is its handle, one pointer wide, as in C.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3GetBinary(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    value_sizes: *mut usize,
    values: *mut *const u8,
    n: usize,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3GetBinary",
        st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    ) else {
        return ERROR;
    };
    if n != nvr || (nvr != 0 && (value_sizes.is_null() || values.is_null())) {
        return ERROR;
    }
    for (i, vr) in unsafe { vrs(vr, nvr) }.into_iter().enumerate() {
        let Some(slot) = c.n.ext_obj_slot(vr) else {
            return bad_binary(c, "fmi3GetBinary", vr);
        };
        unsafe {
            *value_sizes.add(i) = core::mem::size_of::<*mut c_void>();
            *values.add(i) = slot as *const u8;
        }
    }
    OK
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3SetBinary(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    value_sizes: *const usize,
    values: *const *const u8,
    n: usize,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3SetBinary",
        st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK,
    ) else {
        return ERROR;
    };
    let (Some(sizes), Some(ptrs)) = (unsafe { slice(value_sizes, n) }, unsafe { slice(values, n) }) else {
        return ERROR;
    };
    if n != nvr {
        return ERROR;
    }
    for (i, vr) in unsafe { vrs(vr, nvr) }.into_iter().enumerate() {
        let Some(slot) = c.n.ext_obj_slot(vr) else {
            return bad_binary(c, "fmi3SetBinary", vr);
        };
        if sizes[i] != core::mem::size_of::<*mut c_void>() || ptrs[i].is_null() {
            return bad_binary(c, "fmi3SetBinary", vr);
        }
        unsafe { core::ptr::copy_nonoverlapping(ptrs[i], slot as *mut u8, sizes[i]) };
    }
    OK
}

fn bad_binary(c: &Component, call: &str, vr: u32) -> c_int {
    c.n.logger.log(
        ERROR,
        "logStatusError",
        &format!("{call}: illegal value reference {vr}."),
    );
    ERROR
}

// ── FMU state ───────────────────────────────────────────────────────────────
// A state is its serialized bytes, boxed.

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3GetFMUState(c: *mut c_void, state: *mut *mut c_void) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3GetFMUState",
        st::INSTANTIATED | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED,
    ) else {
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
pub unsafe extern "C" fn omc_fmi3SetFMUState(c: *mut c_void, state: *mut c_void) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3SetFMUState",
        st::INSTANTIATED | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED,
    ) else {
        return ERROR;
    };
    let Some(bytes) = (unsafe { (state as *const Vec<u8>).as_ref() }) else {
        return ERROR;
    };
    code(c.n.inst.set_fmu_state(bytes.clone()))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3FreeFMUState(_c: *mut c_void, state: *mut *mut c_void) -> c_int {
    if in_state(
        _c,
        "fmi3FreeFMUState",
        st::INSTANTIATED | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED,
    )
    .is_none()
    {
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
pub unsafe extern "C" fn omc_fmi3SerializedFMUStateSize(
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
pub unsafe extern "C" fn omc_fmi3SerializeFMUState(
    _c: *mut c_void,
    state: *mut c_void,
    serialized: *mut u8,
    size: usize,
) -> c_int {
    let Some(bytes) = (unsafe { (state as *const Vec<u8>).as_ref() }) else {
        return ERROR;
    };
    if size != bytes.len() {
        return ERROR;
    }
    out(bytes, serialized, size)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3DeserializeFMUState(
    _c: *mut c_void,
    serialized: *const u8,
    size: usize,
    state: *mut *mut c_void,
) -> c_int {
    let (Some(bytes), false) = (unsafe { slice(serialized, size) }, state.is_null()) else {
        return ERROR;
    };
    unsafe { *state = Box::into_raw(Box::new(bytes.to_vec())) as *mut c_void };
    OK
}

// ── Derivatives and dependencies ────────────────────────────────────────────

macro_rules! derivative {
    ($cfn:ident, $fname:literal, $mask:expr, $method:ident) => {
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $cfn(
            c: *mut c_void,
            unknowns: *const u32,
            n_unknowns: usize,
            knowns: *const u32,
            n_knowns: usize,
            seed: *const f64,
            n_seed: usize,
            sensitivity: *mut f64,
            n_sensitivity: usize,
        ) -> c_int {
            let Some(c) = in_state(c, $fname, $mask) else {
                return ERROR;
            };
            let Some(s) = (unsafe { slice(seed, n_seed) }) else {
                return ERROR;
            };
            let (u, k) = unsafe { (vrs(unknowns, n_unknowns), vrs(knowns, n_knowns)) };
            match c.n.inst.$method(u, k, s.to_vec()) {
                Ok(v) => out(&v, sensitivity, n_sensitivity),
                Err(s) => code(s),
            }
        }
    };
}
derivative!(
    omc_fmi3GetDirectionalDerivative,
    "fmi3GetDirectionalDerivative",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_directional_derivative
);
derivative!(
    omc_fmi3GetAdjointDerivative,
    "fmi3GetAdjointDerivative",
    st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    get_adjoint_derivative
);

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3GetNumberOfVariableDependencies(
    c: *mut c_void,
    value_reference: u32,
    n_dependencies: *mut usize,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3GetNumberOfVariableDependencies",
        st::INSTANTIATED | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    ) else {
        return ERROR;
    };
    match c.n.inst.get_number_of_variable_dependencies(value_reference) {
        Ok(n) => out(&[n as usize], n_dependencies, 1),
        Err(s) => code(s),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3GetVariableDependencies(
    c: *mut c_void,
    dependent: u32,
    element_indices_of_dependent: *mut usize,
    independents: *mut u32,
    element_indices_of_independents: *mut usize,
    dependency_kinds: *mut c_int,
    n_dependencies: usize,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3GetVariableDependencies",
        st::INSTANTIATED | st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    ) else {
        return ERROR;
    };
    let deps = match c.n.inst.get_variable_dependencies(dependent) {
        Ok(d) if d.len() == n_dependencies => d,
        Ok(_) => return ERROR,
        Err(s) => return code(s),
    };
    for (i, d) in deps.iter().enumerate() {
        unsafe {
            if !element_indices_of_dependent.is_null() {
                *element_indices_of_dependent.add(i) = d.element as usize;
            }
            if !independents.is_null() {
                *independents.add(i) = d.independent;
            }
            if !dependency_kinds.is_null() {
                *dependency_kinds.add(i) = c_int::from(d.kind);
            }
            if !element_indices_of_independents.is_null() {
                *element_indices_of_independents.add(i) = 0;
            }
        }
    }
    OK
}

// ── Clocks ──────────────────────────────────────────────────────────────────

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3GetIntervalDecimal(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    intervals: *mut f64,
    qualifiers: *mut c_int,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3GetIntervalDecimal",
        st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    ) else {
        return ERROR;
    };
    match c.n.inst.get_interval_decimal(unsafe { vrs(vr, nvr) }) {
        Ok(v) => {
            for (i, (interval, q)) in v.iter().enumerate() {
                unsafe {
                    if !intervals.is_null() {
                        *intervals.add(i) = *interval;
                    }
                    if !qualifiers.is_null() {
                        *qualifiers.add(i) = *q as c_int;
                    }
                }
            }
            OK
        }
        Err(s) => code(s),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3GetIntervalFraction(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    counters: *mut u64,
    resolutions: *mut u64,
    qualifiers: *mut c_int,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3GetIntervalFraction",
        st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    ) else {
        return ERROR;
    };
    match c.n.inst.get_interval_fraction(unsafe { vrs(vr, nvr) }) {
        Ok(v) => {
            for (i, (f, q)) in v.iter().enumerate() {
                unsafe {
                    if !counters.is_null() {
                        *counters.add(i) = f.counter;
                    }
                    if !resolutions.is_null() {
                        *resolutions.add(i) = f.resolution;
                    }
                    if !qualifiers.is_null() {
                        *qualifiers.add(i) = *q as c_int;
                    }
                }
            }
            OK
        }
        Err(s) => code(s),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3GetShiftDecimal(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    shifts: *mut f64,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3GetShiftDecimal",
        st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    ) else {
        return ERROR;
    };
    match c.n.inst.get_shift_decimal(unsafe { vrs(vr, nvr) }) {
        Ok(v) => out(&v, shifts, nvr),
        Err(s) => code(s),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3GetShiftFraction(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    counters: *mut u64,
    resolutions: *mut u64,
) -> c_int {
    let Some(c) = in_state(
        c,
        "fmi3GetShiftFraction",
        st::INIT | st::EVENT | st::CONTINUOUS | st::STEP | st::CLOCK | st::TERMINATED | st::ERROR,
    ) else {
        return ERROR;
    };
    match c.n.inst.get_shift_fraction(unsafe { vrs(vr, nvr) }) {
        Ok(v) => {
            let (cs, rs): (Vec<u64>, Vec<u64>) = v.iter().map(|f| (f.counter, f.resolution)).unzip();
            match out(&cs, counters, nvr) {
                OK => out(&rs, resolutions, nvr),
                s => s,
            }
        }
        Err(s) => code(s),
    }
}

macro_rules! set_decimal {
    ($cfn:ident, $fname:literal, $mask:expr, $method:ident) => {
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $cfn(c: *mut c_void, vr: *const u32, nvr: usize, values: *const f64) -> c_int {
            let Some(c) = in_state(c, $fname, $mask) else {
                return ERROR;
            };
            let Some(v) = (unsafe { slice(values, nvr) }) else {
                return ERROR;
            };
            code(c.n.inst.$method(unsafe { vrs(vr, nvr) }, v.to_vec()))
        }
    };
}
set_decimal!(
    omc_fmi3SetIntervalDecimal,
    "fmi3SetIntervalDecimal",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CLOCK,
    set_interval_decimal
);
set_decimal!(
    omc_fmi3SetShiftDecimal,
    "fmi3SetShiftDecimal",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CLOCK,
    set_shift_decimal
);

macro_rules! set_fraction {
    ($cfn:ident, $fname:literal, $mask:expr, $method:ident) => {
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $cfn(
            c: *mut c_void,
            vr: *const u32,
            nvr: usize,
            counters: *const u64,
            resolutions: *const u64,
        ) -> c_int {
            let Some(c) = in_state(c, $fname, $mask) else {
                return ERROR;
            };
            let (Some(cs), Some(rs)) = (unsafe { slice(counters, nvr) }, unsafe {
                slice(resolutions, nvr)
            }) else {
                return ERROR;
            };
            let v = cs
                .iter()
                .zip(rs)
                .map(
                    |(&counter, &resolution)| openmodelica_fmi3_wasm::fmi_types::IntervalFraction {
                        counter,
                        resolution,
                    },
                )
                .collect();
            code(c.n.inst.$method(unsafe { vrs(vr, nvr) }, v))
        }
    };
}
set_fraction!(
    omc_fmi3SetIntervalFraction,
    "fmi3SetIntervalFraction",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CLOCK,
    set_interval_fraction
);
set_fraction!(
    omc_fmi3SetShiftFraction,
    "fmi3SetShiftFraction",
    st::INSTANTIATED | st::CONFIGURATION | st::INIT | st::EVENT | st::CLOCK,
    set_shift_fraction
);

// ── Model Exchange ──────────────────────────────────────────────────────────

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3EnterContinuousTimeMode(c: *mut c_void) -> c_int {
    let Some(c) = in_state_me(c, "fmi3EnterContinuousTimeMode", st::EVENT) else {
        return ERROR;
    };
    let r = code(c.n.inst.enter_continuous_time_mode());
    c.moved(r, st::CONTINUOUS)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3SetTime(c: *mut c_void, time: f64) -> c_int {
    let Some(c) = in_state_me(c, "fmi3SetTime", st::EVENT | st::CONTINUOUS) else {
        return ERROR;
    };
    code(c.n.inst.set_time(time))
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3SetContinuousStates(c: *mut c_void, states: *const f64, n: usize) -> c_int {
    let Some(c) = in_state_me(c, "fmi3SetContinuousStates", st::INIT | st::EVENT | st::CONTINUOUS) else {
        return ERROR;
    };
    let Some(v) = (unsafe { slice(states, n) }) else {
        return ERROR;
    };
    code(c.n.inst.set_continuous_states(v.to_vec()))
}

macro_rules! me_vector {
    ($cfn:ident, $fname:literal, $mask:expr, $method:ident) => {
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $cfn(c: *mut c_void, values: *mut f64, n: usize) -> c_int {
            let Some(c) = in_state_me(c, $fname, $mask) else {
                return ERROR;
            };
            match c.n.inst.$method() {
                Ok(v) => out(&v, values, n),
                Err(s) => code(s),
            }
        }
    };
}
me_vector!(
    omc_fmi3GetContinuousStateDerivatives,
    "fmi3GetContinuousStateDerivatives",
    st::INIT | st::EVENT | st::CONTINUOUS | st::TERMINATED | st::ERROR,
    get_continuous_state_derivatives
);
me_vector!(
    omc_fmi3GetEventIndicators,
    "fmi3GetEventIndicators",
    st::INIT | st::EVENT | st::CONTINUOUS | st::TERMINATED | st::ERROR,
    get_event_indicators
);
me_vector!(
    omc_fmi3GetContinuousStates,
    "fmi3GetContinuousStates",
    st::INIT | st::EVENT | st::CONTINUOUS | st::TERMINATED | st::ERROR,
    get_continuous_states
);
me_vector!(
    omc_fmi3GetNominalsOfContinuousStates,
    "fmi3GetNominalsOfContinuousStates",
    st::INSTANTIATED | st::INIT | st::EVENT | st::CONTINUOUS | st::TERMINATED | st::ERROR,
    get_nominals_of_continuous_states
);

macro_rules! me_count {
    ($cfn:ident, $fname:literal, $mask:expr, $method:ident) => {
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $cfn(c: *mut c_void, n: *mut usize) -> c_int {
            let Some(c) = in_state(c, $fname, $mask) else {
                return ERROR;
            };
            match c.n.inst.$method() {
                Ok(v) => out(&[v as usize], n, 1),
                Err(s) => code(s),
            }
        }
    };
}
me_count!(
    omc_fmi3GetNumberOfEventIndicators,
    "fmi3GetNumberOfEventIndicators",
    st::ANY,
    get_number_of_event_indicators
);
me_count!(
    omc_fmi3GetNumberOfContinuousStates,
    "fmi3GetNumberOfContinuousStates",
    st::ANY,
    get_number_of_continuous_states
);

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3CompletedIntegratorStep(
    c: *mut c_void,
    no_set_fmu_state_prior: bool,
    enter_event_mode: *mut bool,
    terminate_simulation: *mut bool,
) -> c_int {
    let Some(c) = in_state_me(c, "fmi3CompletedIntegratorStep", st::CONTINUOUS) else {
        return ERROR;
    };
    match c.n.inst.completed_integrator_step(no_set_fmu_state_prior) {
        Ok(r) => {
            unsafe {
                if !enter_event_mode.is_null() {
                    *enter_event_mode = r.enter_event_mode;
                }
                if !terminate_simulation.is_null() {
                    *terminate_simulation = r.terminate_simulation;
                }
            }
            OK
        }
        Err(s) => code(s),
    }
}

// ── Co-Simulation ───────────────────────────────────────────────────────────

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3DoStep(
    c: *mut c_void,
    current_communication_point: f64,
    communication_step_size: f64,
    no_set_fmu_state_prior: bool,
    event_handling_needed: *mut bool,
    terminate_simulation: *mut bool,
    early_return: *mut bool,
    last_successful_time: *mut f64,
) -> c_int {
    let Some(c) = in_state_cs(c, "fmi3DoStep", st::STEP) else {
        return ERROR;
    };
    match c.n.inst.do_step(
        current_communication_point,
        communication_step_size,
        no_set_fmu_state_prior,
    ) {
        Ok(r) => {
            unsafe {
                if !event_handling_needed.is_null() {
                    *event_handling_needed = r.event_handling_needed;
                }
                if !terminate_simulation.is_null() {
                    *terminate_simulation = r.terminate_simulation;
                }
                if !early_return.is_null() {
                    *early_return = r.early_return;
                }
                if !last_successful_time.is_null() {
                    *last_successful_time = r.last_successful_time;
                }
            }
            OK
        }
        Err(s) => code(s),
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3GetOutputDerivatives(
    c: *mut c_void,
    vr: *const u32,
    nvr: usize,
    orders: *const c_int,
    values: *mut f64,
    n: usize,
) -> c_int {
    let Some(c) = in_state(c, "fmi3GetOutputDerivatives", st::STEP | st::TERMINATED | st::ERROR) else {
        return ERROR;
    };
    let Some(requests) = (unsafe { requests(vr, nvr, orders) }) else {
        return ERROR;
    };
    match c.n.inst.get_output_derivatives(requests) {
        Ok(v) => out(&v, values, n),
        Err(s) => code(s),
    }
}

// ── Scheduled Execution ─────────────────────────────────────────────────────

#[unsafe(no_mangle)]
pub unsafe extern "C" fn omc_fmi3ActivateModelPartition(
    c: *mut c_void,
    clock_reference: u32,
    activation_time: f64,
) -> c_int {
    let Some(c) = in_state(c, "fmi3ActivateModelPartition", st::CLOCK).filter(|c| c.n.kind == Kind::ScheduledExecution)
    else {
        return ERROR;
    };
    code(c.n.inst.activate_model_partition(clock_reference, activation_time))
}
