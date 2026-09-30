//! What the FMI 2.0 and 3.0 C APIs of a C+Rust FMU share (`fmi2_capi.rs`,
//! `fmi3_capi.rs`): an [`openmodelica_fmi3_wasm::Instance`] over [`CEngine`] and
//! the `DATA` it runs on, built as C's `fmi2Instantiate` builds it.

use core::ffi::{c_char, c_int, c_void};
use std::ffi::{CStr, CString};

use openmodelica_fmi3_wasm::Instance;
use openmodelica_fmi3_wasm::fmi_types::Status;

use crate::abi::*;
use crate::engine::CEngine;

pub(crate) const OK: c_int = 0;
pub(crate) const WARNING: c_int = 1;
pub(crate) const DISCARD: c_int = 2;
pub(crate) const ERROR: c_int = 3;
pub(crate) const FATAL: c_int = 4;

pub(crate) type Fmi2LogCb =
    Option<unsafe extern "C" fn(*mut c_void, *const c_char, c_int, *const c_char, *const c_char, ...)>;
pub(crate) type Fmi3LogCb = Option<unsafe extern "C" fn(*mut c_void, c_int, *const c_char, *const c_char)>;

unsafe extern "C" {
    // The generated `<Model>_FMU.c`.
    static omc_fmu_threadDataSize: usize;
    static omc_fmu3_nArrays: c_int;
    static omc_fmu3_arrayVrs: [u32; 1];
    static omc_fmu3_arrayLengths: [u32; 1];
    fn omc_fmu_setupDataStruc(data: *mut DATA, thread_data: *mut threadData_t);
    fn omc_fmu_setDefaultStartValues(data: *mut DATA);

    fn mmc_init_nogc();
    static mut omc_assert: *const c_void;
    static mut omc_assert_warning: *const c_void;
    static mut omc_terminate: *const c_void;
    fn omc_assert_simulation();
    fn omc_assert_warning_simulation();
    fn omc_terminate_simulation();
}

#[cfg(unix)]
unsafe extern "C" {
    static mmc_thread_data_key: libc::pthread_key_t;
}

/// The importer's logger.
pub(crate) enum Logger {
    Fmi2 { cb: Fmi2LogCb, env: *mut c_void, name: CString },
    Fmi3 { cb: Fmi3LogCb, env: *mut c_void },
}

impl Logger {
    pub(crate) fn log(&self, status: c_int, category: &str, message: &str) {
        let (Ok(cat), Ok(msg)) = (CString::new(category), CString::new(message)) else { return };
        match self {
            Logger::Fmi2 { cb: Some(cb), env, name } => unsafe {
                cb(*env, name.as_ptr(), status, cat.as_ptr(), c"%s".as_ptr(), msg.as_ptr())
            },
            Logger::Fmi3 { cb: Some(cb), env } => unsafe { cb(*env, status, cat.as_ptr(), msg.as_ptr()) },
            _ => {}
        }
    }
}

/// Where the state machine's log hook reports to. One instance is driven by one
/// thread at a time, and every entry point sets it first.
static mut CURRENT: *const Logger = core::ptr::null();

fn log_hook(status: Status, category: &str, message: &str) {
    if let Some(l) = unsafe { CURRENT.as_ref() } {
        l.log(code(status), category, message);
    }
}

/// C's `omc_assert_fmi`: the importer's logger, or stderr when the runtime raised
/// the assert without a `threadData` to find the instance by.
fn report_assert(error: bool, info: &FILE_INFO, text: &str, passed_thread_data: bool) {
    let file = cstr(info.filename);
    if error && !passed_thread_data {
        let pos = format!(
            "[{file}:{}:{}-{}:{}:{}]",
            info.lineStart,
            info.colStart,
            info.lineEnd,
            info.colEnd,
            if info.readonly != 0 { "readonly" } else { "writable" }
        );
        eprintln!("{pos}Modelica Assert: {text}!");
        return;
    }
    let msg = if info.lineStart != 0 { format!("{file}:{}: {text}", info.lineStart) } else { text.to_string() };
    if error {
        openmodelica_fmi3_wasm::log_status_error(&msg);
    } else {
        openmodelica_fmi3_wasm::log_status_warning(&msg);
    }
}

pub(crate) fn code(s: Status) -> c_int {
    match s {
        Status::Ok => OK,
        Status::Warning => WARNING,
        Status::Discard => DISCARD,
        Status::Error => ERROR,
        Status::Fatal => FATAL,
    }
}

pub(crate) fn cstr(p: *const c_char) -> String {
    if p.is_null() { String::new() } else { unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned() }
}

#[derive(Clone, Copy, PartialEq)]
pub(crate) enum Kind {
    ModelExchange,
    CoSimulation { event_mode_used: bool, early_return_allowed: bool },
    ScheduledExecution,
}

pub(crate) struct Native {
    pub inst: Instance<CEngine>,
    data: *mut DATA,
    thread_data: *mut threadData_t,
    pub logger: Logger,
    log: core::cell::RefCell<openmodelica_fmi3_wasm::LogState>,
    resources: Option<CString>,
    pub kind: Kind,
}

impl Native {
    /// Also C's `setThreadData`: an external function finds `threadData` through
    /// the key, and the importer may have driven another instance since.
    pub(crate) fn enter(&self) {
        unsafe { CURRENT = &self.logger };
        openmodelica_fmi3_wasm::restore_logging(&self.log.borrow());
        #[cfg(unix)]
        unsafe {
            libc::pthread_setspecific(mmc_thread_data_key, self.thread_data as *const c_void)
        };
    }

    /// `token` is FMI 2.0's GUID, FMI 3.0's instantiation token.
    pub(crate) fn instantiate(
        name: &str,
        token: &str,
        resources: Option<CString>,
        kind: Kind,
        logging_on: bool,
        logger: Logger,
        call: &str,
    ) -> Option<Box<Native>> {
        unsafe { CURRENT = &logger };
        openmodelica_fmi3_wasm::set_log_hook(log_hook);
        openmodelica_fmi3_wasm::init_logging(name.to_string(), logging_on);
        crate::support::set_fmu_assert_report(report_assert);
        crate::support::publish_log_streams();
        let resources = resources.or_else(library_resources);
        let (inst, data, thread_data) = match build(resources.as_ref(), kind, Some(token)) {
            Ok(b) => b,
            Err(msg) => {
                logger.log(ERROR, "logStatusError", &format!("{call}: {msg}"));
                return None;
            }
        };
        let log = core::cell::RefCell::new(openmodelica_fmi3_wasm::save_logging());
        let n = Box::new(Native { inst, data, thread_data, logger, log, resources, kind });
        n.enter();
        Some(n)
    }

    /// C's `fmi2Reset`: the model set up again from scratch, as instantiate left it.
    pub(crate) fn reset(&mut self, call: &str) -> c_int {
        match build(self.resources.as_ref(), self.kind, None) {
            Ok((inst, data, thread_data)) => {
                let old = core::mem::replace(&mut self.inst, inst);
                let old_data = core::mem::replace(&mut self.data, data);
                let old_td = core::mem::replace(&mut self.thread_data, thread_data);
                old.free();
                release(old_data, old_td);
                self.enter();
                OK
            }
            Err(msg) => {
                self.logger.log(ERROR, "logStatusError", &format!("{call}: {msg}"));
                ERROR
            }
        }
    }

    pub(crate) fn set_debug_logging(&self, logging_on: bool, categories: Vec<String>) -> Status {
        let s = self.inst.set_debug_logging(logging_on, categories);
        *self.log.borrow_mut() = openmodelica_fmi3_wasm::save_logging();
        s
    }

    pub(crate) fn model_data(&self) -> *const MODEL_DATA {
        unsafe { (*self.data).modelData }
    }

    /// An external object's `simulationInfo->extObjs` slot, which FMI 3.0 exports
    /// as a Binary after the Real, Integer, Boolean and String blocks.
    pub(crate) fn ext_obj_slot(&self, vr: u32) -> Option<*mut *mut c_void> {
        let md = unsafe { &*self.model_data() };
        let first = (md.nVariablesReal + md.nParametersReal + md.nAliasReal)
            + (md.nVariablesInteger + md.nParametersInteger + md.nAliasInteger)
            + (md.nVariablesBoolean + md.nParametersBoolean + md.nAliasBoolean)
            + (md.nVariablesString + md.nParametersString + md.nAliasString);
        let i = (vr as i64).checked_sub(first as i64)?;
        (0..md.nExtObjs as i64).contains(&i).then(|| unsafe { (*(*self.data).simulationInfo).extObjs.add(i as usize) })
    }

    pub(crate) fn free(self) {
        self.enter();
        self.inst.free();
        release(self.data, self.thread_data);
        unsafe { CURRENT = core::ptr::null() };
    }
}

/// `<fmu>/resources` for an importer that names no resource location, which FMI
/// 1.0 Model Exchange cannot: this binary is `<fmu>/binaries/<platform>/<model>`.
fn library_resources() -> Option<CString> {
    let lib = library_path()?;
    let fmu = lib.parent()?.parent()?.parent()?;
    CString::new(fmu.join("resources").to_str()?).ok()
}

#[cfg(unix)]
fn library_path() -> Option<std::path::PathBuf> {
    let mut info: libc::Dl_info = unsafe { core::mem::zeroed() };
    if unsafe { libc::dladdr(library_path as *const c_void, &mut info) } == 0 || info.dli_fname.is_null() {
        return None;
    }
    Some(unsafe { CStr::from_ptr(info.dli_fname) }.to_str().ok()?.into())
}

#[cfg(windows)]
fn library_path() -> Option<std::path::PathBuf> {
    use std::os::windows::ffi::OsStringExt;
    unsafe extern "system" {
        fn GetModuleHandleExW(flags: u32, name: *const u16, module: *mut *mut c_void) -> i32;
        fn GetModuleFileNameW(module: *mut c_void, name: *mut u16, size: u32) -> u32;
    }
    const FROM_ADDRESS: u32 = 0x4;
    const UNCHANGED_REFCOUNT: u32 = 0x2;
    let mut module = core::ptr::null_mut();
    let mut buf = [0u16; 32768];
    unsafe {
        if GetModuleHandleExW(FROM_ADDRESS | UNCHANGED_REFCOUNT, library_path as *const u16, &mut module) == 0 {
            return None;
        }
        let n = GetModuleFileNameW(module, buf.as_mut_ptr(), buf.len() as u32) as usize;
        (n > 0).then(|| std::ffi::OsString::from_wide(&buf[..n]).into())
    }
}

fn release(data: *mut DATA, thread_data: *mut threadData_t) {
    crate::fmi::deInitializeDataStruc(data);
    crate::data::free_data_struc(data, thread_data);
}

fn calloc<T>(n: usize) -> *mut T {
    unsafe { libc::calloc(n.max(1), core::mem::size_of::<T>()) as *mut T }
}

/// C's `FMI2CS_initializeSolverData`: `s` in `resources/<model>_flags.json` picks
/// the Co-Simulation solver, Euler without one. Nothing else in it is read.
fn cs_method(data: *mut DATA) -> String {
    let md = unsafe { &*(*data).modelData };
    let path = format!("{}/{}_flags.json", cstr(md.resourcesDir), cstr(md.modelFilePrefix));
    let Ok(text) = std::fs::read_to_string(path) else { return "euler".into() };
    let value = text.find("\"s\"").and_then(|k| {
        let rest = &text[k + 3..];
        let rest = &rest[rest.find(':')? + 1..];
        let rest = &rest[rest.find('"')? + 1..];
        Some(rest[..rest.find('"')?].to_string())
    });
    value.unwrap_or_else(|| "euler".into())
}

type Built = (Instance<CEngine>, *mut DATA, *mut threadData_t);

/// FMI 3.0 exports a scalarized array as one variable: its first element's value
/// reference, followed by the rest (`CodegenFMU`'s `FMI3_ARRAY_VRS`).
fn fmi3_arrays(table: &mut [openmodelica_sim_meta::FmiVr]) {
    let n = unsafe { omc_fmu3_nArrays }.max(0) as usize;
    let (vrs, lens) = unsafe {
        (
            core::slice::from_raw_parts(core::ptr::addr_of!(omc_fmu3_arrayVrs) as *const u32, n),
            core::slice::from_raw_parts(core::ptr::addr_of!(omc_fmu3_arrayLengths) as *const u32, n),
        )
    };
    for (&vr, &len) in vrs.iter().zip(lens) {
        if let Some(e) = table.iter_mut().find(|e| e.vr == vr) {
            e.len = len;
        }
    }
}

/// C's `fmi2Instantiate` up to the solver, then the instance over it.
fn build(resources: Option<&CString>, kind: Kind, token: Option<&str>) -> Result<Built, String> {
    let (data, td) = unsafe {
        mmc_init_nogc();
        omc_alloc_interface.init.expect("omc_alloc_interface")();
        let data = calloc::<DATA>(1);
        (*data).modelData = calloc::<MODEL_DATA>(1);
        (*data).simulationInfo = calloc::<SIMULATION_INFO>(1);
        let td = libc::calloc(1, omc_fmu_threadDataSize) as *mut threadData_t;
        (*td).localRoots[LOCAL_ROOT_SIMULATION_DATA] = data as *mut c_void;
        #[cfg(unix)]
        libc::pthread_setspecific(mmc_thread_data_key, td as *const c_void);
        omc_assert = omc_assert_simulation as *const c_void;
        omc_assert_warning = omc_assert_warning_simulation as *const c_void;
        omc_terminate = omc_terminate_simulation as *const c_void;
        if let Some(r) = resources {
            (*(*data).modelData).resourcesDir = libc::strdup(r.as_ptr());
        }
        (data, td)
    };
    // Nothing above the importer catches a model error while the instance is set
    // up: C's `fmi2Instantiate` runs it under `MMC_TRY_INTERNAL(globalJumpBuffer)`.
    let mut built: Result<Option<Instance<CEngine>>, String> = Ok(None);
    let ok = crate::support::protected_global(td, || built = setup(data, td, kind, token));
    match built {
        Ok(Some(inst)) if ok => Ok((inst, data, td)),
        Err(msg) => Err(msg),
        _ => Err("the model could not be set up.".into()),
    }
}

fn setup(data: *mut DATA, td: *mut threadData_t, kind: Kind, token: Option<&str>) -> Result<Option<Instance<CEngine>>, String> {
    unsafe {
        omc_fmu_setupDataStruc(data, td);
        let md = &*(*data).modelData;
        if let Some(token) = token
            && token != cstr(md.modelGUID)
        {
            return Err(format!("Wrong GUID {token}. Expected {}.", cstr(md.modelGUID)));
        }
        let cb = &*(*data).callback;
        cb.read_simulation_info.expect("read_simulation_info")((*data).simulationInfo);
        crate::fmi::allocModelDataVars((*data).modelData, 0, td);
        crate::fmi::scalarAllocArrayAttributes((*data).modelData);
        crate::fmi::calculateAllScalarLength((*data).modelData);
        omc_fmu_setDefaultStartValues(data);
        crate::fmi::initializeDataStruc(data, td);
        crate::fmi::setAllParamsToStart((*data).simulationInfo, (*data).modelData);
        crate::fmi::setAllVarsToStart(*(*data).localData, (*data).simulationInfo, (*data).modelData);
        cb.read_input_fmu.expect("read_input_fmu")((*data).modelData);
        crate::fmi::initializeNonlinearSystems(data, td);
        crate::fmi::initializeLinearSystems(data, td);
        crate::fmi::initializeMixedSystems(data, td);
        crate::fmi::initializeStateSetJacobians(data, td);
    }
    let (engine, mut meta) = crate::fmi::engine_and_meta(data, td);
    fmi3_arrays(&mut meta.fmi_vrs);
    let inst = match kind {
        Kind::CoSimulation { event_mode_used, early_return_allowed } => {
            meta.cs_method = cs_method(data);
            Instance::new_co_simulation(engine, meta, 0, event_mode_used, early_return_allowed)
        }
        Kind::ModelExchange | Kind::ScheduledExecution => Instance::new(engine, meta, 0),
    };
    Ok(inst)
}
