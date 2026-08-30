//! A native FMU binary, called through the FMI 3.0 C API.
//!
//! Every entry point is resolved once, when the library is opened, into a
//! [`Vtable`] of plain function pointers: a call from the masters is then an
//! indirect call, never a symbol lookup. Entry points an FMU may legitimately
//! omit are `Option`s and reported as [`Error::Unsupported`] when the masters
//! ask for them.

use crate::api::*;
use crate::{Error, Result};
use openmodelica_fmi::VarType;
use std::cell::RefCell;
use std::ffi::{CStr, CString, c_char, c_void};
use std::path::Path;

type Instance = *mut c_void;
type Vr = u32;

type LogCallback =
    extern "C" fn(env: *mut c_void, status: i32, category: *const c_char, message: *const c_char);
type IntermediateUpdateCallback = extern "C" fn(
    env: *mut c_void,
    time: f64,
    set_requested: bool,
    get_allowed: bool,
    step_finished: bool,
    can_return_early: bool,
    early_return_requested: *mut bool,
    early_return_time: *mut f64,
);

type GetT<T> = unsafe extern "C" fn(Instance, *const Vr, usize, *mut T, usize) -> i32;
type SetT<T> = unsafe extern "C" fn(Instance, *const Vr, usize, *const T, usize) -> i32;

/// Every FMI 3.0 entry point the masters use, resolved once.
#[allow(clippy::type_complexity)]
struct Vtable {
    get_version: unsafe extern "C" fn() -> *const c_char,
    instantiate_model_exchange: Option<
        unsafe extern "C" fn(
            *const c_char,
            *const c_char,
            *const c_char,
            bool,
            bool,
            *mut c_void,
            LogCallback,
        ) -> Instance,
    >,
    instantiate_co_simulation: Option<
        unsafe extern "C" fn(
            *const c_char,
            *const c_char,
            *const c_char,
            bool,
            bool,
            bool,
            bool,
            *const Vr,
            usize,
            *mut c_void,
            LogCallback,
            Option<IntermediateUpdateCallback>,
        ) -> Instance,
    >,
    free_instance: unsafe extern "C" fn(Instance),
    enter_initialization_mode: unsafe extern "C" fn(Instance, bool, f64, f64, bool, f64) -> i32,
    exit_initialization_mode: unsafe extern "C" fn(Instance) -> i32,
    enter_event_mode: unsafe extern "C" fn(Instance) -> i32,
    update_discrete_states: unsafe extern "C" fn(
        Instance,
        *mut bool,
        *mut bool,
        *mut bool,
        *mut bool,
        *mut bool,
        *mut f64,
    ) -> i32,
    terminate: unsafe extern "C" fn(Instance) -> i32,

    get_float32: GetT<f32>,
    set_float32: SetT<f32>,
    get_float64: GetT<f64>,
    set_float64: SetT<f64>,
    get_int8: GetT<i8>,
    set_int8: SetT<i8>,
    get_uint8: GetT<u8>,
    set_uint8: SetT<u8>,
    get_int16: GetT<i16>,
    set_int16: SetT<i16>,
    get_uint16: GetT<u16>,
    set_uint16: SetT<u16>,
    get_int32: GetT<i32>,
    set_int32: SetT<i32>,
    get_uint32: GetT<u32>,
    set_uint32: SetT<u32>,
    get_int64: GetT<i64>,
    set_int64: SetT<i64>,
    get_uint64: GetT<u64>,
    set_uint64: SetT<u64>,
    get_boolean: GetT<bool>,
    set_boolean: SetT<bool>,
    get_string: GetT<*const c_char>,
    set_string: SetT<*const c_char>,
    enter_configuration_mode: Option<unsafe extern "C" fn(Instance) -> i32>,
    exit_configuration_mode: Option<unsafe extern "C" fn(Instance) -> i32>,

    // Model Exchange
    enter_continuous_time_mode: Option<unsafe extern "C" fn(Instance) -> i32>,
    set_time: Option<unsafe extern "C" fn(Instance, f64) -> i32>,
    set_continuous_states: Option<unsafe extern "C" fn(Instance, *const f64, usize) -> i32>,
    get_continuous_states: Option<unsafe extern "C" fn(Instance, *mut f64, usize) -> i32>,
    get_continuous_state_derivatives: Option<unsafe extern "C" fn(Instance, *mut f64, usize) -> i32>,
    get_event_indicators: Option<unsafe extern "C" fn(Instance, *mut f64, usize) -> i32>,
    get_nominals_of_continuous_states: Option<unsafe extern "C" fn(Instance, *mut f64, usize) -> i32>,
    get_number_of_continuous_states: Option<unsafe extern "C" fn(Instance, *mut usize) -> i32>,
    get_number_of_event_indicators: Option<unsafe extern "C" fn(Instance, *mut usize) -> i32>,
    completed_integrator_step:
        Option<unsafe extern "C" fn(Instance, bool, *mut bool, *mut bool) -> i32>,

    get_directional_derivative: Option<
        unsafe extern "C" fn(
            Instance,
            *const Vr,
            usize,
            *const Vr,
            usize,
            *const f64,
            usize,
            *mut f64,
            usize,
        ) -> i32,
    >,

    // Co-Simulation
    enter_step_mode: Option<unsafe extern "C" fn(Instance) -> i32>,
    do_step: Option<
        unsafe extern "C" fn(Instance, f64, f64, bool, *mut bool, *mut bool, *mut bool, *mut f64) -> i32,
    >,
}

/// A loaded FMU binary. Instances borrow it, so it must outlive them.
pub struct Library {
    v: Vtable,
    // Dropped last: the function pointers above point into it.
    _lib: libloading::Library,
}

macro_rules! required {
    ($lib:expr, $name:literal) => {{
        let sym: libloading::Symbol<_> = unsafe { $lib.get(concat!($name, "\0").as_bytes()) }
            .map_err(|e| Error::Load(format!("{}: {e}", $name)))?;
        *sym
    }};
}

macro_rules! optional {
    ($lib:expr, $name:literal) => {{
        let sym: std::result::Result<libloading::Symbol<_>, _> =
            unsafe { $lib.get(concat!($name, "\0").as_bytes()) };
        sym.ok().map(|s| *s)
    }};
}

impl Library {
    /// `dlopen` the FMU binary and resolve every entry point.
    pub fn open(path: &Path) -> Result<Library> {
        let lib = unsafe { libloading::Library::new(path) }
            .map_err(|e| Error::Load(format!("{}: {e}", path.display())))?;
        let v = Vtable {
            get_version: required!(lib, "fmi3GetVersion"),
            instantiate_model_exchange: optional!(lib, "fmi3InstantiateModelExchange"),
            instantiate_co_simulation: optional!(lib, "fmi3InstantiateCoSimulation"),
            free_instance: required!(lib, "fmi3FreeInstance"),
            enter_initialization_mode: required!(lib, "fmi3EnterInitializationMode"),
            exit_initialization_mode: required!(lib, "fmi3ExitInitializationMode"),
            enter_event_mode: required!(lib, "fmi3EnterEventMode"),
            update_discrete_states: required!(lib, "fmi3UpdateDiscreteStates"),
            terminate: required!(lib, "fmi3Terminate"),
            get_float32: required!(lib, "fmi3GetFloat32"),
            set_float32: required!(lib, "fmi3SetFloat32"),
            get_float64: required!(lib, "fmi3GetFloat64"),
            set_float64: required!(lib, "fmi3SetFloat64"),
            get_int8: required!(lib, "fmi3GetInt8"),
            set_int8: required!(lib, "fmi3SetInt8"),
            get_uint8: required!(lib, "fmi3GetUInt8"),
            set_uint8: required!(lib, "fmi3SetUInt8"),
            get_int16: required!(lib, "fmi3GetInt16"),
            set_int16: required!(lib, "fmi3SetInt16"),
            get_uint16: required!(lib, "fmi3GetUInt16"),
            set_uint16: required!(lib, "fmi3SetUInt16"),
            get_int32: required!(lib, "fmi3GetInt32"),
            set_int32: required!(lib, "fmi3SetInt32"),
            get_uint32: required!(lib, "fmi3GetUInt32"),
            set_uint32: required!(lib, "fmi3SetUInt32"),
            get_int64: required!(lib, "fmi3GetInt64"),
            set_int64: required!(lib, "fmi3SetInt64"),
            get_uint64: required!(lib, "fmi3GetUInt64"),
            set_uint64: required!(lib, "fmi3SetUInt64"),
            get_boolean: required!(lib, "fmi3GetBoolean"),
            set_boolean: required!(lib, "fmi3SetBoolean"),
            get_string: required!(lib, "fmi3GetString"),
            set_string: required!(lib, "fmi3SetString"),
            enter_configuration_mode: optional!(lib, "fmi3EnterConfigurationMode"),
            exit_configuration_mode: optional!(lib, "fmi3ExitConfigurationMode"),
            enter_continuous_time_mode: optional!(lib, "fmi3EnterContinuousTimeMode"),
            set_time: optional!(lib, "fmi3SetTime"),
            set_continuous_states: optional!(lib, "fmi3SetContinuousStates"),
            get_continuous_states: optional!(lib, "fmi3GetContinuousStates"),
            get_continuous_state_derivatives: optional!(lib, "fmi3GetContinuousStateDerivatives"),
            get_event_indicators: optional!(lib, "fmi3GetEventIndicators"),
            get_nominals_of_continuous_states: optional!(lib, "fmi3GetNominalsOfContinuousStates"),
            get_number_of_continuous_states: optional!(lib, "fmi3GetNumberOfContinuousStates"),
            get_number_of_event_indicators: optional!(lib, "fmi3GetNumberOfEventIndicators"),
            completed_integrator_step: optional!(lib, "fmi3CompletedIntegratorStep"),
            get_directional_derivative: optional!(lib, "fmi3GetDirectionalDerivative"),
            enter_step_mode: optional!(lib, "fmi3EnterStepMode"),
            do_step: optional!(lib, "fmi3DoStep"),
        };
        Ok(Library { v, _lib: lib })
    }

    pub fn instantiate_model_exchange(
        &self,
        name: &str,
        token: &str,
        resource_path: Option<&str>,
        logging_on: bool,
    ) -> Result<FmuInstance<'_>> {
        let f = self
            .v
            .instantiate_model_exchange
            .ok_or_else(|| Error::Unsupported("fmi3InstantiateModelExchange".into()))?;
        let mut inst = FmuInstance::new(self);
        let (name, token, path) = cstrings(name, token, resource_path)?;
        let handle = unsafe {
            f(
                name.as_ptr(),
                token.as_ptr(),
                path.as_ref().map_or(std::ptr::null(), |p| p.as_ptr()),
                false,
                logging_on,
                inst.env(),
                log_message,
            )
        };
        inst.attach(handle, "fmi3InstantiateModelExchange")
    }

    pub fn instantiate_co_simulation(
        &self,
        name: &str,
        token: &str,
        resource_path: Option<&str>,
        logging_on: bool,
        event_mode_used: bool,
        early_return_allowed: bool,
    ) -> Result<FmuInstance<'_>> {
        let f = self
            .v
            .instantiate_co_simulation
            .ok_or_else(|| Error::Unsupported("fmi3InstantiateCoSimulation".into()))?;
        let mut inst = FmuInstance::new(self);
        let (name, token, path) = cstrings(name, token, resource_path)?;
        let handle = unsafe {
            f(
                name.as_ptr(),
                token.as_ptr(),
                path.as_ref().map_or(std::ptr::null(), |p| p.as_ptr()),
                false,
                logging_on,
                event_mode_used,
                early_return_allowed,
                std::ptr::null(),
                0,
                inst.env(),
                log_message,
                Some(intermediate_update),
            )
        };
        inst.attach(handle, "fmi3InstantiateCoSimulation")
    }
}

fn cstrings(
    name: &str,
    token: &str,
    path: Option<&str>,
) -> Result<(CString, CString, Option<CString>)> {
    let mk = |s: &str| CString::new(s).map_err(|_| Error::Unsupported("NUL in a string".into()));
    Ok((mk(name)?, mk(token)?, path.map(mk).transpose()?))
}

/// What the FMU's callbacks reach: the log it writes and the early return it may
/// be granted. Boxed, and handed to the FMU as its `instanceEnvironment`.
#[derive(Default)]
struct Env {
    log: RefCell<Vec<(Status, String, String)>>,
    /// Time the master wants the FMU to stop at, when it may return early.
    early_return_at: RefCell<Option<f64>>,
}

extern "C" fn log_message(
    env: *mut c_void,
    status: i32,
    category: *const c_char,
    message: *const c_char,
) {
    if env.is_null() {
        return;
    }
    let env = unsafe { &*(env as *const Env) };
    let text = |p: *const c_char| {
        if p.is_null() {
            String::new()
        } else {
            unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned()
        }
    };
    env.log.borrow_mut().push((Status::from_raw(status), text(category), text(message)));
}

/// The FMU is inside `fmi3DoStep` and asks whether it may stop. It may, if the
/// master has a reason to want control back before the communication point —
/// an input discontinuity or an output sample it must not step over.
extern "C" fn intermediate_update(
    env: *mut c_void,
    time: f64,
    _set_requested: bool,
    _get_allowed: bool,
    _step_finished: bool,
    can_return_early: bool,
    early_return_requested: *mut bool,
    early_return_time: *mut f64,
) {
    if early_return_requested.is_null() {
        return;
    }
    let want = (!env.is_null() && can_return_early)
        .then(|| *unsafe { &*(env as *const Env) }.early_return_at.borrow())
        .flatten()
        .filter(|&at| at > time);
    unsafe {
        *early_return_requested = want.is_some();
        if let (Some(at), false) = (want, early_return_time.is_null()) {
            *early_return_time = at;
        }
    }
}

/// One instantiated FMU.
pub struct FmuInstance<'a> {
    lib: &'a Library,
    handle: Instance,
    env: Box<Env>,
}

impl<'a> FmuInstance<'a> {
    fn new(lib: &'a Library) -> FmuInstance<'a> {
        FmuInstance { lib, handle: std::ptr::null_mut(), env: Box::default() }
    }

    fn env(&mut self) -> *mut c_void {
        &*self.env as *const Env as *mut c_void
    }

    fn attach(mut self, handle: Instance, call: &'static str) -> Result<FmuInstance<'a>> {
        if handle.is_null() {
            return Err(Error::Instantiate { call, log: self.take_log() });
        }
        self.handle = handle;
        Ok(self)
    }

    /// Stop the next `fmi3DoStep` at `time` if the FMU offers to.
    pub fn request_early_return_at(&mut self, time: Option<f64>) {
        *self.env.early_return_at.borrow_mut() = time;
    }

    fn v(&self) -> &Vtable {
        &self.lib.v
    }
}

impl Drop for FmuInstance<'_> {
    fn drop(&mut self) {
        if !self.handle.is_null() {
            unsafe { (self.lib.v.free_instance)(self.handle) };
        }
    }
}

/// `fmi3Get<T>`/`fmi3Set<T>` for a type the master handles as `f64`.
macro_rules! numeric {
    ($self:expr, $ty:ty, $get:ident, $vrs:expr, $out:expr, $call:literal) => {{
        let mut buf = vec![<$ty>::default(); $out.len()];
        let f = $self.v().$get;
        check($call, unsafe {
            f($self.handle, $vrs.as_ptr(), $vrs.len(), buf.as_mut_ptr(), buf.len())
        })?;
        for (o, v) in $out.iter_mut().zip(&buf) {
            *o = *v as f64;
        }
        Ok(())
    }};
}

macro_rules! numeric_set {
    ($self:expr, $ty:ty, $set:ident, $vrs:expr, $values:expr, $call:literal) => {{
        let buf: Vec<$ty> = $values.iter().map(|v| v.round() as $ty).collect();
        let f = $self.v().$set;
        check($call, unsafe {
            f($self.handle, $vrs.as_ptr(), $vrs.len(), buf.as_ptr(), buf.len())
        })
    }};
}

impl Fmi3 for FmuInstance<'_> {
    fn get_version(&mut self) -> String {
        let p = unsafe { (self.v().get_version)() };
        if p.is_null() {
            String::new()
        } else {
            unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned()
        }
    }

    fn enter_initialization_mode(
        &mut self,
        tolerance: Option<f64>,
        start_time: f64,
        stop_time: Option<f64>,
    ) -> Result<()> {
        let f = self.v().enter_initialization_mode;
        check("fmi3EnterInitializationMode", unsafe {
            f(
                self.handle,
                tolerance.is_some(),
                tolerance.unwrap_or(0.0),
                start_time,
                stop_time.is_some(),
                stop_time.unwrap_or(0.0),
            )
        })
    }

    fn exit_initialization_mode(&mut self) -> Result<()> {
        let f = self.v().exit_initialization_mode;
        check("fmi3ExitInitializationMode", unsafe { f(self.handle) })
    }

    fn enter_event_mode(&mut self) -> Result<()> {
        let f = self.v().enter_event_mode;
        check("fmi3EnterEventMode", unsafe { f(self.handle) })
    }

    fn update_discrete_states(&mut self) -> Result<DiscreteStates> {
        let (mut need, mut term, mut nom, mut states, mut defined) = (false, false, false, false, false);
        let mut next = 0.0;
        let f = self.v().update_discrete_states;
        check("fmi3UpdateDiscreteStates", unsafe {
            f(self.handle, &mut need, &mut term, &mut nom, &mut states, &mut defined, &mut next)
        })?;
        Ok(DiscreteStates {
            need_update: need,
            terminate: term,
            nominals_changed: nom,
            states_changed: states,
            next_event_time: defined.then_some(next),
        })
    }

    fn terminate(&mut self) -> Result<()> {
        let f = self.v().terminate;
        check("fmi3Terminate", unsafe { f(self.handle) })
    }

    fn enter_configuration_mode(&mut self) -> Result<()> {
        let Some(f) = self.v().enter_configuration_mode else {
            return missing("fmi3EnterConfigurationMode");
        };
        check("fmi3EnterConfigurationMode", unsafe { f(self.handle) })
    }

    fn exit_configuration_mode(&mut self) -> Result<()> {
        let Some(f) = self.v().exit_configuration_mode else {
            return missing("fmi3ExitConfigurationMode");
        };
        check("fmi3ExitConfigurationMode", unsafe { f(self.handle) })
    }

    fn get_numeric(&mut self, ty: VarType, vrs: &[u32], values: &mut [f64]) -> Result<()> {
        match ty.wire() {
            VarType::Float64 => {
                let f = self.v().get_float64;
                check("fmi3GetFloat64", unsafe {
                    f(self.handle, vrs.as_ptr(), vrs.len(), values.as_mut_ptr(), values.len())
                })
            }
            VarType::Float32 => {
                let mut buf = vec![0f32; values.len()];
                let f = self.v().get_float32;
                check("fmi3GetFloat32", unsafe {
                    f(self.handle, vrs.as_ptr(), vrs.len(), buf.as_mut_ptr(), buf.len())
                })?;
                for (o, v) in values.iter_mut().zip(&buf) {
                    *o = *v as f64;
                }
                Ok(())
            }
            VarType::Int8 => numeric!(self, i8, get_int8, vrs, values, "fmi3GetInt8"),
            VarType::UInt8 => numeric!(self, u8, get_uint8, vrs, values, "fmi3GetUInt8"),
            VarType::Int16 => numeric!(self, i16, get_int16, vrs, values, "fmi3GetInt16"),
            VarType::UInt16 => numeric!(self, u16, get_uint16, vrs, values, "fmi3GetUInt16"),
            VarType::Int32 => numeric!(self, i32, get_int32, vrs, values, "fmi3GetInt32"),
            VarType::UInt32 => numeric!(self, u32, get_uint32, vrs, values, "fmi3GetUInt32"),
            VarType::Int64 => numeric!(self, i64, get_int64, vrs, values, "fmi3GetInt64"),
            VarType::UInt64 => numeric!(self, u64, get_uint64, vrs, values, "fmi3GetUInt64"),
            VarType::Boolean => {
                let mut buf = vec![false; values.len()];
                let f = self.v().get_boolean;
                check("fmi3GetBoolean", unsafe {
                    f(self.handle, vrs.as_ptr(), vrs.len(), buf.as_mut_ptr(), buf.len())
                })?;
                for (o, v) in values.iter_mut().zip(&buf) {
                    *o = *v as u8 as f64;
                }
                Ok(())
            }
            ty => Err(Error::Unsupported(format!("reading a {} as a number", ty.as_str()))),
        }
    }

    fn set_numeric(&mut self, ty: VarType, vrs: &[u32], values: &[f64]) -> Result<()> {
        match ty.wire() {
            VarType::Float64 => {
                let f = self.v().set_float64;
                check("fmi3SetFloat64", unsafe {
                    f(self.handle, vrs.as_ptr(), vrs.len(), values.as_ptr(), values.len())
                })
            }
            VarType::Float32 => {
                let buf: Vec<f32> = values.iter().map(|v| *v as f32).collect();
                let f = self.v().set_float32;
                check("fmi3SetFloat32", unsafe {
                    f(self.handle, vrs.as_ptr(), vrs.len(), buf.as_ptr(), buf.len())
                })
            }
            VarType::Int8 => numeric_set!(self, i8, set_int8, vrs, values, "fmi3SetInt8"),
            VarType::UInt8 => numeric_set!(self, u8, set_uint8, vrs, values, "fmi3SetUInt8"),
            VarType::Int16 => numeric_set!(self, i16, set_int16, vrs, values, "fmi3SetInt16"),
            VarType::UInt16 => numeric_set!(self, u16, set_uint16, vrs, values, "fmi3SetUInt16"),
            VarType::Int32 => numeric_set!(self, i32, set_int32, vrs, values, "fmi3SetInt32"),
            VarType::UInt32 => numeric_set!(self, u32, set_uint32, vrs, values, "fmi3SetUInt32"),
            VarType::Int64 => numeric_set!(self, i64, set_int64, vrs, values, "fmi3SetInt64"),
            VarType::UInt64 => numeric_set!(self, u64, set_uint64, vrs, values, "fmi3SetUInt64"),
            VarType::Boolean => {
                let buf: Vec<bool> = values.iter().map(|v| *v != 0.0).collect();
                let f = self.v().set_boolean;
                check("fmi3SetBoolean", unsafe {
                    f(self.handle, vrs.as_ptr(), vrs.len(), buf.as_ptr(), buf.len())
                })
            }
            ty => Err(Error::Unsupported(format!("setting a {} from a number", ty.as_str()))),
        }
    }

    fn get_string(&mut self, vrs: &[u32]) -> Result<Vec<String>> {
        let mut buf = vec![std::ptr::null(); vrs.len()];
        let f = self.v().get_string;
        check("fmi3GetString", unsafe {
            f(self.handle, vrs.as_ptr(), vrs.len(), buf.as_mut_ptr(), buf.len())
        })?;
        Ok(buf
            .into_iter()
            .map(|p| {
                if p.is_null() {
                    String::new()
                } else {
                    unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned()
                }
            })
            .collect())
    }

    fn set_string(&mut self, vrs: &[u32], values: &[&str]) -> Result<()> {
        let owned: Vec<CString> = values
            .iter()
            .map(|s| CString::new(*s).map_err(|_| Error::Unsupported("NUL in a string".into())))
            .collect::<Result<_>>()?;
        let ptrs: Vec<*const c_char> = owned.iter().map(|s| s.as_ptr()).collect();
        let f = self.v().set_string;
        check("fmi3SetString", unsafe {
            f(self.handle, vrs.as_ptr(), vrs.len(), ptrs.as_ptr(), ptrs.len())
        })
    }

    fn take_log(&mut self) -> Vec<(Status, String, String)> {
        std::mem::take(&mut *self.env.log.borrow_mut())
    }
}

/// An entry point the FMU declared but did not export.
fn missing<T>(call: &'static str) -> Result<T> {
    Err(Error::Unsupported(call.into()))
}

impl Fmi3ModelExchange for FmuInstance<'_> {
    fn enter_continuous_time_mode(&mut self) -> Result<()> {
        let Some(f) = self.v().enter_continuous_time_mode else {
            return missing("fmi3EnterContinuousTimeMode");
        };
        check("fmi3EnterContinuousTimeMode", unsafe { f(self.handle) })
    }

    fn set_time(&mut self, time: f64) -> Result<()> {
        let Some(f) = self.v().set_time else { return missing("fmi3SetTime") };
        check("fmi3SetTime", unsafe { f(self.handle, time) })
    }

    fn set_continuous_states(&mut self, states: &[f64]) -> Result<()> {
        if states.is_empty() {
            return Ok(());
        }
        let Some(f) = self.v().set_continuous_states else {
            return missing("fmi3SetContinuousStates");
        };
        check("fmi3SetContinuousStates", unsafe {
            f(self.handle, states.as_ptr(), states.len())
        })
    }

    fn get_continuous_states(&mut self, states: &mut [f64]) -> Result<()> {
        if states.is_empty() {
            return Ok(());
        }
        let Some(f) = self.v().get_continuous_states else {
            return missing("fmi3GetContinuousStates");
        };
        check("fmi3GetContinuousStates", unsafe {
            f(self.handle, states.as_mut_ptr(), states.len())
        })
    }

    fn get_continuous_state_derivatives(&mut self, ders: &mut [f64]) -> Result<()> {
        if ders.is_empty() {
            return Ok(());
        }
        let Some(f) = self.v().get_continuous_state_derivatives else {
            return missing("fmi3GetContinuousStateDerivatives");
        };
        check("fmi3GetContinuousStateDerivatives", unsafe {
            f(self.handle, ders.as_mut_ptr(), ders.len())
        })
    }

    fn get_event_indicators(&mut self, indicators: &mut [f64]) -> Result<()> {
        if indicators.is_empty() {
            return Ok(());
        }
        let Some(f) = self.v().get_event_indicators else {
            return missing("fmi3GetEventIndicators");
        };
        check("fmi3GetEventIndicators", unsafe {
            f(self.handle, indicators.as_mut_ptr(), indicators.len())
        })
    }

    fn get_nominals_of_continuous_states(&mut self, nominals: &mut [f64]) -> Result<()> {
        if nominals.is_empty() {
            return Ok(());
        }
        let Some(f) = self.v().get_nominals_of_continuous_states else {
            return missing("fmi3GetNominalsOfContinuousStates");
        };
        check("fmi3GetNominalsOfContinuousStates", unsafe {
            f(self.handle, nominals.as_mut_ptr(), nominals.len())
        })
    }

    fn get_number_of_continuous_states(&mut self) -> Result<usize> {
        let Some(f) = self.v().get_number_of_continuous_states else {
            return missing("fmi3GetNumberOfContinuousStates");
        };
        let mut n = 0usize;
        check("fmi3GetNumberOfContinuousStates", unsafe { f(self.handle, &mut n) })?;
        Ok(n)
    }

    fn get_number_of_event_indicators(&mut self) -> Result<usize> {
        let Some(f) = self.v().get_number_of_event_indicators else {
            return missing("fmi3GetNumberOfEventIndicators");
        };
        let mut n = 0usize;
        check("fmi3GetNumberOfEventIndicators", unsafe { f(self.handle, &mut n) })?;
        Ok(n)
    }

    fn get_directional_derivative(
        &mut self,
        unknowns: &[u32],
        knowns: &[u32],
        seed: &[f64],
        sensitivity: &mut [f64],
    ) -> Result<()> {
        let Some(f) = self.v().get_directional_derivative else {
            return missing("fmi3GetDirectionalDerivative");
        };
        check("fmi3GetDirectionalDerivative", unsafe {
            f(
                self.handle,
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
        let Some(f) = self.v().completed_integrator_step else {
            return missing("fmi3CompletedIntegratorStep");
        };
        let (mut enter, mut term) = (false, false);
        check("fmi3CompletedIntegratorStep", unsafe {
            f(self.handle, no_set_state_prior, &mut enter, &mut term)
        })?;
        Ok(CompletedStep { enter_event_mode: enter, terminate: term })
    }
}

impl Fmi3CoSimulation for FmuInstance<'_> {
    fn enter_step_mode(&mut self) -> Result<()> {
        let Some(f) = self.v().enter_step_mode else { return missing("fmi3EnterStepMode") };
        check("fmi3EnterStepMode", unsafe { f(self.handle) })
    }

    fn do_step(
        &mut self,
        current_communication_point: f64,
        communication_step_size: f64,
        no_set_state_prior: bool,
    ) -> Result<DoStep> {
        let Some(f) = self.v().do_step else { return missing("fmi3DoStep") };
        let (mut event, mut term, mut early) = (false, false, false);
        let mut last = current_communication_point;
        check("fmi3DoStep", unsafe {
            f(
                self.handle,
                current_communication_point,
                communication_step_size,
                no_set_state_prior,
                &mut event,
                &mut term,
                &mut early,
                &mut last,
            )
        })?;
        Ok(DoStep {
            event_handling_needed: event,
            terminate: term,
            early_return: early,
            last_successful_time: last,
        })
    }
}

/// Unpack `fmu` into `dir` and open the shared library that serves `kind`,
/// together with the resource path to instantiate with. Native binaries are
/// preferred; a wasm-only FMU has nothing here to `dlopen` and is refused.
pub fn open_fmu(
    fmu: &openmodelica_fmi::Fmu,
    kind: openmodelica_fmi::InterfaceKind,
    dir: &Path,
) -> Result<(Library, Option<String>)> {
    use openmodelica_fmi::{BinaryKind, Preference};
    let binary = fmu
        .select_binary(kind, Preference::Native)
        .ok_or_else(|| Error::Load(format!("the FMU has no binary for {}", kind.as_str())))?;
    if binary.kind != BinaryKind::Native {
        return Err(Error::Load(format!(
            "the FMU only ships {} ({}), which needs a WebAssembly runtime",
            binary.platform_dir, binary.path
        )));
    }
    let path = dir.join(&binary.path);
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).map_err(|e| Error::Io(e.to_string()))?;
    }
    let bytes = fmu
        .read(&binary.path)
        .ok_or_else(|| Error::Load(format!("{} is missing from the archive", binary.path)))?;
    std::fs::write(&path, &bytes).map_err(|e| Error::Io(format!("{}: {e}", path.display())))?;
    // FMI 3.0 hands the FMU the resources directory as a path ending in a
    // separator; an FMU that appends its own file name to it needs that.
    let resources = fmu
        .resources()
        .next()
        .is_some()
        .then(|| fmu.extract_resources(dir))
        .transpose()?
        .map(|p| format!("{}{}", p.display(), std::path::MAIN_SEPARATOR));
    Ok((Library::open(&path)?, resources))
}
