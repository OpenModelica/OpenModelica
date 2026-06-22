// Manually written file.
//
// Rust counterpart of `OMCompiler/Compiler/runtime/OMSimulator_omc.c` for the
// `external "C"` bodies of `OMCompiler/Compiler/Util/OMSimulatorExt.mo`
// (`statusToString` is plain MetaModelica and is hand-ported at the bottom).
//
// The C runtime does not link OMSimulator; it `dlopen`s `libOMSimulator` from
// the installation on the first `loadOMSimulator()` call and resolves each
// `oms_*` entry point from it. We mirror that:
//
//   * `loadOMSimulator` opens
//     `<install>/lib/<triple>/omc/libOMSimulator<dllExt>` (on Windows the C
//     code loads `<install>/bin/libOMSimulator<dllExt>` instead) with
//     `RTLD_LAZY` and keeps the handle in a process-global slot.
//   * Every wrapper resolves its symbol from that handle and forwards the
//     call. Calling any wrapper before `loadOMSimulator()` — or with a
//     library that lacks the symbol — prints the same
//     `could not locate the function <name>` message as the C wrapper and
//     exits with status 0, because scripts compare that output verbatim.
//   * `unloadOMSimulator` closes the handle. (The C code `dlclose`s but
//     keeps the stale handle and function pointers around, so a second
//     load/call sequence after unload is undefined behavior there. We clear
//     the slot instead so load→unload→load works; for the load-once usage in
//     all scripts the behavior is identical.)
//
// Symbols are resolved per call (`dlsym` on the held handle) instead of all
// at once like the C `resolveFunctionNames()`. Observable behavior is the
// same — the C code also only notices a missing symbol when the wrapper is
// called — and these calls are never on a hot path (each one drives a whole
// model-composition/simulation step inside OMSimulator).
//
// Thread-safety: the handle lives behind a `Mutex`; the function pointer is
// resolved under the lock and the foreign call is made after dropping it.
// Concurrent calls into OMSimulator itself are no more synchronized than in
// the C omc (OMSimulator has its own global model state).

#![allow(non_snake_case)]

use std::ffi::{CStr, CString};
use std::sync::Mutex;

use arcstr::ArcStr;
use libc::{c_char, c_double, c_int, c_void};

use crate::Autoconf;
use crate::Settings;

/// `dlopen` handle of `libOMSimulator` (cast to `usize` so the slot is
/// `Send`); `None` until `loadOMSimulator()` succeeds.
static OMSIMULATOR_DLL: Mutex<Option<usize>> = Mutex::new(None);

/// Mirrors the C wrappers' behavior for a NULL function pointer: print the
/// message (compared verbatim by scripts) and exit with status 0.
fn missing_function(name: &str) -> ! {
    println!("could not locate the function {name}");
    std::process::exit(0);
}

/// Resolve `name` in the loaded `libOMSimulator`, or print-and-exit exactly
/// like the C wrapper does when its function pointer is NULL (either because
/// `loadOMSimulator()` was never called or the symbol is absent).
fn resolve(name: &str) -> usize {
    let dll = OMSIMULATOR_DLL.lock().unwrap();
    let Some(handle) = *dll else { missing_function(name) };
    let c_name = CString::new(name).expect("oms symbol names contain no NUL");
    let addr = unsafe { libc::dlsym(handle as *mut c_void, c_name.as_ptr()) };
    if addr.is_null() {
        missing_function(name);
    }
    addr as usize
}

/// MetaModelica `String` → C string. MM strings are NUL-terminated in the C
/// runtime, so an embedded NUL truncates the value there; mirror that here.
fn c_string(s: &ArcStr) -> CString {
    match CString::new(s.as_bytes()) {
        Ok(c) => c,
        Err(e) => {
            let pos = e.nul_position();
            CString::new(&s.as_bytes()[..pos]).expect("truncated at first NUL")
        }
    }
}

/// Copy a C string returned through an OMSimulator out-parameter. The C glue
/// (`mmc_mk_scon`) would dereference NULL; we map NULL (out-parameter left
/// untouched on error) to `""` instead of crashing.
fn from_c_str(p: *const c_char) -> ArcStr {
    if p.is_null() {
        return arcstr::literal!("");
    }
    ArcStr::from(unsafe { CStr::from_ptr(p) }.to_string_lossy().as_ref())
}

/// Resolve `$name` and cast it to the given C function-pointer type.
macro_rules! oms_sym {
    ($name:expr => $fty:ty) => {{
        let addr = resolve($name);
        // SAFETY: the symbol comes from libOMSimulator whose C API declares
        // exactly this signature (see the typedefs in OMSimulator_omc.c).
        unsafe { std::mem::transmute::<usize, $fty>(addr) }
    }};
}

pub fn loadOMSimulator() -> i32 {
    let mut dll = OMSIMULATOR_DLL.lock().unwrap();
    if dll.is_none() {
        // The C code asprintf's with a NULL path if the installation
        // directory cannot be determined; that lookup practically never
        // fails (it falls back to the executable's prefix). Use "" so the
        // failure mode is the load-error message below, not a crash.
        let path = Settings::getInstallationDirectoryPath().unwrap_or_else(|_| arcstr::literal!(""));
        // Same layout split as the C code: Windows installs the DLL next to
        // the executables under bin/, unix under lib/<triple>/omc/.
        let full_file_name = if cfg!(windows) {
            format!("{path}/bin/libOMSimulator{}", Autoconf::dllExt)
        } else {
            format!("{path}/lib/{}/omc/libOMSimulator{}", Autoconf::triple, Autoconf::dllExt)
        };
        let c_path = c_string(&ArcStr::from(full_file_name.as_str()));
        let handle = unsafe { libc::dlopen(c_path.as_ptr(), libc::RTLD_LAZY) };
        if handle.is_null() {
            // Message and exit status mirror OMSimulator_loadDLL.
            println!("Could not load the dynamic library {full_file_name} Exiting the program");
            std::process::exit(0);
        }
        *dll = Some(handle as usize);
    }
    0
}

pub fn unloadOMSimulator() -> i32 {
    let mut dll = OMSIMULATOR_DLL.lock().unwrap();
    match dll.take() {
        Some(handle) => {
            unsafe { libc::dlclose(handle as *mut c_void) };
            0
        }
        None => {
            // Message and exit status mirror OMSimulator_unloadDLL.
            println!("OMSimulator instance is not found, Please load the OMSimulator instance using loadOMSimulator()");
            std::process::exit(0);
        }
    }
}

pub fn oms_getVersion() -> ArcStr {
    let f = oms_sym!("oms_getVersion" => unsafe extern "C" fn() -> *const c_char);
    from_c_str(unsafe { f() })
}

/// MetaModelica parameter type → the Rust parameter type of the wrapper.
macro_rules! mm_ty {
    (String) => { ArcStr };
    (Integer) => { i32 };
    (Real) => { metamodelica::Real };
    (Boolean) => { bool };
}

/// MetaModelica parameter type → the C ABI type it is passed as.
macro_rules! oms_c_ty {
    (String) => { *const c_char };
    (Integer) => { c_int };
    (Real) => { c_double };
    (Boolean) => { bool }; // Rust bool is ABI-compatible with C _Bool
}

/// Per-argument conversion before the call: `String` needs a CString
/// temporary, `Real` unwraps `OrderedFloat` to the raw f64.
macro_rules! oms_c_prep {
    (String, $v:ident) => { let $v = c_string(&$v); };
    (Real, $v:ident) => { let $v: c_double = $v.into_inner(); };
    ($t:ident, $v:ident) => {};
}

/// Per-argument expression passed to the C call.
macro_rules! oms_c_pass {
    (String, $v:ident) => { $v.as_ptr() };
    ($t:ident, $v:ident) => { $v };
}

/// Define wrappers of the dominant shape: all-input arguments, `int` status
/// result. The Rust function name equals the symbol name in libOMSimulator.
macro_rules! oms_status_fns {
    ($($fname:ident ( $($arg:ident : $mmty:ident),* );)*) => { $(
        pub fn $fname($($arg: mm_ty!($mmty)),*) -> i32 {
            $(oms_c_prep!($mmty, $arg);)*
            let f = oms_sym!(stringify!($fname) => unsafe extern "C" fn($(oms_c_ty!($mmty)),*) -> c_int);
            unsafe { f($(oms_c_pass!($mmty, $arg)),*) }
        }
    )* }
}

oms_status_fns! {
    oms_addBus(cref: String);
    oms_addConnection(crefA: String, crefB: String);
    oms_addConnector(cref: String, causality: Integer, type_: Integer);
    oms_addConnectorToBus(busCref: String, connectorCref: String);
    oms_addConnectorToTLMBus(busCref: String, connectorCref: String, type_: String);
    oms_addDynamicValueIndicator(signal: String, lower: String, upper: String, stepSize: Real);
    oms_addEventIndicator(signal: String);
    oms_addExternalModel(cref: String, path: String, startscript: String);
    oms_addSignalsToResults(cref: String, regex: String);
    oms_addStaticValueIndicator(signal: String, lower: Real, upper: Real, stepSize: Real);
    oms_addSubModel(cref: String, fmuPath: String);
    oms_addSystem(cref: String, type_: Integer);
    oms_addTimeIndicator(signal: String);
    oms_addTLMBus(cref: String, domain: Integer, dimensions: Integer, interpolation: Integer);
    oms_addTLMConnection(crefA: String, crefB: String, delay: Real, alpha: Real, linearimpedance: Real, angularimpedance: Real);
    oms_compareSimulationResults(filenameA: String, filenameB: String, var: String, relTol: Real, absTol: Real);
    oms_copySystem(source: String, target: String);
    oms_delete(cref: String);
    oms_deleteConnection(crefA: String, crefB: String);
    oms_deleteConnectorFromBus(busCref: String, connectorCref: String);
    oms_deleteConnectorFromTLMBus(busCref: String, connectorCref: String);
    oms_export(cref: String, filename: String);
    oms_exportDependencyGraphs(cref: String, initialization: String, event: String, simulation: String);
    oms_faultInjection(signal: String, faultType: Integer, faultValue: Real);
    oms_importSnapshot(cref: String, snapshot: String);
    oms_initialize(cref: String);
    oms_instantiate(cref: String);
    oms_newModel(cref: String);
    oms_removeSignalsFromResults(cref: String, regex: String);
    oms_rename(cref: String, newCref: String);
    oms_reset(cref: String);
    oms_RunFile(filename: String);
    oms_setBoolean(cref: String, value: Boolean);
    oms_setCommandLineOption(cmd: String);
    oms_setFixedStepSize(cref: String, stepSize: Real);
    oms_setInteger(cref: String, value: Integer);
    oms_setLogFile(filename: String);
    oms_setLoggingInterval(cref: String, loggingInterval: Real);
    oms_setLoggingLevel(logLevel: Integer);
    oms_setReal(cref: String, value: Real);
    oms_setRealInputDerivative(cref: String, value: Real);
    oms_setResultFile(cref: String, filename: String, bufferSize: Integer);
    oms_setSignalFilter(cref: String, regex: String);
    oms_setSolver(cref: String, solver: Integer);
    oms_setStartTime(cref: String, startTime: Real);
    oms_setStopTime(cref: String, stopTime: Real);
    oms_setTempDirectory(newTempDir: String);
    oms_setTLMPositionAndOrientation(cref: String, x1: Real, x2: Real, x3: Real, A11: Real, A12: Real, A13: Real, A21: Real, A22: Real, A23: Real, A31: Real, A32: Real, A33: Real);
    oms_setTLMSocketData(cref: String, address: String, managerPort: Integer, monitorPort: Integer);
    oms_setTolerance(cref: String, absoluteTolerance: Real, relativeTolerance: Real);
    oms_setVariableStepSize(cref: String, initialStepSize: Real, minimumStepSize: Real, maximumStepSize: Real);
    oms_setWorkingDirectory(newWorkingDir: String);
    oms_simulate(cref: String);
    oms_stepUntil(cref: String, stopTime: Real);
    oms_terminate(cref: String);
}

// ── getters with out-parameters ─────────────────────────────────────────────
// Out-parameters are pre-initialized to "no value" defaults (0 / 0.0 / false /
// NULL→"") because OMSimulator only writes them on success; the C glue would
// read an uninitialized stack slot in that case.

pub fn oms_exportSnapshot(cref: ArcStr) -> (ArcStr, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_exportSnapshot" => unsafe extern "C" fn(*const c_char, *mut *const c_char) -> c_int);
    let mut contents: *const c_char = std::ptr::null();
    let status = unsafe { f(cref.as_ptr(), &mut contents) };
    (from_c_str(contents), status)
}

pub fn oms_extractFMIKind(filename: ArcStr) -> (i32, i32) {
    let filename = c_string(&filename);
    let f = oms_sym!("oms_extractFMIKind" => unsafe extern "C" fn(*const c_char, *mut c_int) -> c_int);
    let mut kind: c_int = 0;
    let status = unsafe { f(filename.as_ptr(), &mut kind) };
    (kind, status)
}

pub fn oms_getBoolean(cref: ArcStr) -> (bool, i32) {
    let cref = c_string(&cref);
    // `bool*` out-parameter: read back through u8 so an uninitialized or
    // non-0/1 byte from the C side cannot create an invalid Rust `bool`.
    let f = oms_sym!("oms_getBoolean" => unsafe extern "C" fn(*const c_char, *mut u8) -> c_int);
    let mut value: u8 = 0;
    let status = unsafe { f(cref.as_ptr(), &mut value) };
    (value != 0, status)
}

pub fn oms_getFixedStepSize(cref: ArcStr) -> (metamodelica::Real, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_getFixedStepSize" => unsafe extern "C" fn(*const c_char, *mut c_double) -> c_int);
    let mut step_size: c_double = 0.0;
    let status = unsafe { f(cref.as_ptr(), &mut step_size) };
    (metamodelica::Real::from(step_size), status)
}

pub fn oms_getInteger(cref: ArcStr) -> (i32, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_getInteger" => unsafe extern "C" fn(*const c_char, *mut c_int) -> c_int);
    let mut value: c_int = 0;
    let status = unsafe { f(cref.as_ptr(), &mut value) };
    (value, status)
}

pub fn oms_getModelState(cref: ArcStr) -> (i32, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_getModelState" => unsafe extern "C" fn(*const c_char, *mut c_int) -> c_int);
    let mut model_state: c_int = 0;
    let status = unsafe { f(cref.as_ptr(), &mut model_state) };
    (model_state, status)
}

pub fn oms_getReal(cref: ArcStr) -> (metamodelica::Real, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_getReal" => unsafe extern "C" fn(*const c_char, *mut c_double) -> c_int);
    let mut value: c_double = 0.0;
    let status = unsafe { f(cref.as_ptr(), &mut value) };
    (metamodelica::Real::from(value), status)
}

pub fn oms_getSolver(cref: ArcStr) -> (i32, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_getSolver" => unsafe extern "C" fn(*const c_char, *mut c_int) -> c_int);
    let mut solver: c_int = 0;
    let status = unsafe { f(cref.as_ptr(), &mut solver) };
    (solver, status)
}

pub fn oms_getStartTime(cref: ArcStr) -> (metamodelica::Real, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_getStartTime" => unsafe extern "C" fn(*const c_char, *mut c_double) -> c_int);
    let mut start_time: c_double = 0.0;
    let status = unsafe { f(cref.as_ptr(), &mut start_time) };
    (metamodelica::Real::from(start_time), status)
}

pub fn oms_getStopTime(cref: ArcStr) -> (metamodelica::Real, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_getStopTime" => unsafe extern "C" fn(*const c_char, *mut c_double) -> c_int);
    let mut stop_time: c_double = 0.0;
    let status = unsafe { f(cref.as_ptr(), &mut stop_time) };
    (metamodelica::Real::from(stop_time), status)
}

pub fn oms_getSubModelPath(cref: ArcStr) -> (ArcStr, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_getSubModelPath" => unsafe extern "C" fn(*const c_char, *mut *const c_char) -> c_int);
    let mut path: *const c_char = std::ptr::null();
    let status = unsafe { f(cref.as_ptr(), &mut path) };
    (from_c_str(path), status)
}

pub fn oms_getSystemType(cref: ArcStr) -> (i32, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_getSystemType" => unsafe extern "C" fn(*const c_char, *mut c_int) -> c_int);
    let mut type_: c_int = 0;
    let status = unsafe { f(cref.as_ptr(), &mut type_) };
    (type_, status)
}

pub fn oms_getTolerance(cref: ArcStr) -> (metamodelica::Real, metamodelica::Real, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_getTolerance" => unsafe extern "C" fn(*const c_char, *mut c_double, *mut c_double) -> c_int);
    let mut absolute_tolerance: c_double = 0.0;
    let mut relative_tolerance: c_double = 0.0;
    let status = unsafe { f(cref.as_ptr(), &mut absolute_tolerance, &mut relative_tolerance) };
    (metamodelica::Real::from(absolute_tolerance), metamodelica::Real::from(relative_tolerance), status)
}

pub fn oms_getVariableStepSize(cref: ArcStr) -> (metamodelica::Real, metamodelica::Real, metamodelica::Real, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_getVariableStepSize" => unsafe extern "C" fn(*const c_char, *mut c_double, *mut c_double, *mut c_double) -> c_int);
    let mut initial_step_size: c_double = 0.0;
    let mut minimum_step_size: c_double = 0.0;
    let mut maximum_step_size: c_double = 0.0;
    let status = unsafe { f(cref.as_ptr(), &mut initial_step_size, &mut minimum_step_size, &mut maximum_step_size) };
    (metamodelica::Real::from(initial_step_size), metamodelica::Real::from(minimum_step_size), metamodelica::Real::from(maximum_step_size), status)
}

pub fn oms_importFile(filename: ArcStr) -> (ArcStr, i32) {
    let filename = c_string(&filename);
    let f = oms_sym!("oms_importFile" => unsafe extern "C" fn(*const c_char, *mut *const c_char) -> c_int);
    let mut cref: *const c_char = std::ptr::null();
    let status = unsafe { f(filename.as_ptr(), &mut cref) };
    (from_c_str(cref), status)
}

pub fn oms_list(cref: ArcStr) -> (ArcStr, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_list" => unsafe extern "C" fn(*const c_char, *mut *const c_char) -> c_int);
    let mut contents: *const c_char = std::ptr::null();
    let status = unsafe { f(cref.as_ptr(), &mut contents) };
    (from_c_str(contents), status)
}

pub fn oms_listUnconnectedConnectors(cref: ArcStr) -> (ArcStr, i32) {
    let cref = c_string(&cref);
    let f = oms_sym!("oms_listUnconnectedConnectors" => unsafe extern "C" fn(*const c_char, *mut *const c_char) -> c_int);
    let mut contents: *const c_char = std::ptr::null();
    let status = unsafe { f(cref.as_ptr(), &mut contents) };
    (from_c_str(contents), status)
}

pub fn oms_loadSnapshot(cref: ArcStr, snapshot: ArcStr) -> (ArcStr, i32) {
    let cref = c_string(&cref);
    let snapshot = c_string(&snapshot);
    let f = oms_sym!("oms_loadSnapshot" => unsafe extern "C" fn(*const c_char, *const c_char, *mut *const c_char) -> c_int);
    let mut new_cref: *const c_char = std::ptr::null();
    let status = unsafe { f(cref.as_ptr(), snapshot.as_ptr(), &mut new_cref) };
    (from_c_str(new_cref), status)
}

// ── plain MetaModelica function from OMSimulatorExt.mo ──────────────────────

pub fn statusToString(status: i32) -> ArcStr {
    match status {
        0 => arcstr::literal!("ok"),
        1 => arcstr::literal!("warning"),
        2 => arcstr::literal!("discard"),
        3 => arcstr::literal!("error"),
        4 => arcstr::literal!("fatal"),
        5 => arcstr::literal!("pending"),
        _ => arcstr::literal!("unknown_status"),
    }
}
