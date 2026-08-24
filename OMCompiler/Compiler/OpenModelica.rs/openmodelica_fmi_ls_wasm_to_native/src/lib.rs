//! FMI C API over an [fmi-ls-wasm](https://github.com/modelica/fmi-ls-wasm)
//! component: the importer `dlopen`s this library and calls `fmi3*`; every call
//! is forwarded to the component through the WIT bindings.
//!
//! The same library also exports the **FMI 2.0** API (see [`fmi2`]), translated
//! onto the component's 3.0 interface, so one build per platform serves an FMU of
//! either version. An FMU declares one `fmiVersion`, so the two symbol sets never
//! both matter to an importer.
//!
//! The library is model-agnostic. The model arrives as a resource next to it:
//!
//! | file | used when |
//! | --- | --- |
//! | `resources/<platform>.cwasm` | always, if present: a precompiled artifact, `deserialize`d in ~1 ms |
//! | `resources/*.wasm` | `jit` builds only: the component, compiled at instantiate |
//! | `binaries/wasm32-wasip2/*.wasm` | `jit` builds only, last resort — the wasm binary an FMI 3.0 FMU already ships |
//!
//! A `.cwasm` is tied to the exact wasmtime version *and* engine configuration
//! that produced it, so the exporter and this library must ship as one version.
//!
//! Every `fmi2*`/`fmi3*` below is a C entry point: unsafe by signature, with the
//! caller owning the pointers it passes, exactly as the standard specifies.
#![allow(clippy::missing_safety_doc)]

use std::ffi::{c_char, c_void, CStr, CString};
use std::path::{Path, PathBuf};

use wasmtime::component::{Component, Linker, ResourceAny};
use wasmtime::{Config, Engine, Store};

mod bindings {
    //! The WIT is shared with the wasm-side adapter rather than copied.
    //!
    //! Two worlds, not three: a `model-exchange-fmu` binding also instantiates an
    //! me_cs component (extra exports are not an error), and likewise for
    //! co-simulation, so both halves are reachable without a third set of types.
    pub mod me {
        wasmtime::component::bindgen!({
            path: "../openmodelica_fmi3_wasm/wit",
            world: "model-exchange-fmu",
        });
    }
    pub mod cs {
        wasmtime::component::bindgen!({
            path: "../openmodelica_fmi3_wasm/wit",
            world: "co-simulation-fmu",
        });
    }
}

use bindings::cs::exports::fmi::fmi3::co_simulation::GuestCoSimulationInstance;
use bindings::me::exports::fmi::fmi3::model_exchange::GuestModelExchangeInstance;

// ── FMI status codes ────────────────────────────────────────────────────────
// The same five values in both versions.

const OK: i32 = 0;
const WARNING: i32 = 1;
const DISCARD: i32 = 2;
const ERROR: i32 = 3;

/// One generated `status` enum per world, both from the same WIT definition.
macro_rules! status_conv {
    ($name:ident, $path:path) => {
        fn $name(s: $path) -> i32 {
            use $path as S;
            match s {
                S::Ok => OK,
                S::Warning => WARNING,
                S::Discard => DISCARD,
                S::Error => ERROR,
                S::Fatal => 4,
            }
        }
    };
}
status_conv!(st_me, bindings::me::fmi::fmi3::types::Status);
status_conv!(st_cs, bindings::cs::fmi::fmi3::types::Status);

// ── Host state ──────────────────────────────────────────────────────────────

type LogCb = Option<extern "C" fn(*mut c_void, i32, *const c_char, *const c_char)>;
type IntermediateUpdateCb = Option<
    extern "C" fn(*mut c_void, f64, bool, bool, bool, bool, *mut bool, *mut f64),
>;

/// The importer's log callback, whose shape is the one per-call difference
/// between the two APIs (see [`fmi2::LogCb`]).
pub(crate) enum Log {
    Fmi3(LogCb),
    Fmi2 { cb: fmi2::LogCb, name: CString },
}

impl Log {
    fn emit(&self, env: *mut c_void, status: i32, category: &str, message: &str) {
        let (Ok(cat), Ok(msg)) = (CString::new(category), CString::new(message)) else { return };
        match self {
            Log::Fmi3(Some(cb)) => cb(env, status, cat.as_ptr(), msg.as_ptr()),
            Log::Fmi2 { cb: Some(cb), name } => unsafe {
                cb(env, name.as_ptr(), status, cat.as_ptr(), msg.as_ptr())
            },
            _ => {}
        }
    }
}

struct Host {
    env: *mut c_void,
    log: Log,
    intermediate_update: IntermediateUpdateCb,
    wasi: wasmtime_wasi::WasiCtx,
    table: wasmtime::component::ResourceTable,
}

// The C API requires one thread at a time per instance.
unsafe impl Send for Host {}

impl wasmtime_wasi::WasiView for Host {
    fn ctx(&mut self) -> wasmtime_wasi::WasiCtxView<'_> {
        wasmtime_wasi::WasiCtxView { ctx: &mut self.wasi, table: &mut self.table }
    }
}

impl Host {
    fn log(&mut self, status: i32, category: &str, message: &str) {
        self.log.emit(self.env, status, category, message);
    }
}

macro_rules! impl_host {
    ($m:ident, $conv:ident) => {
        impl bindings::$m::fmi::fmi3::types::Host for Host {}
        impl bindings::$m::fmi::fmi3::callbacks::Host for Host {
            fn log_message(
                &mut self,
                _instance_name: String,
                status: bindings::$m::fmi::fmi3::types::Status,
                category: String,
                message: String,
            ) {
                self.log($conv(status), &category, &message);
            }
            fn clock_update(&mut self) {}
            fn lock_preemption(&mut self) {}
            fn unlock_preemption(&mut self) {}
        }
    };
}
impl_host!(me, st_me);
impl_host!(cs, st_cs);

impl bindings::cs::fmi::fmi3::intermediate_update_callbacks::Host for Host {
    fn intermediate_update(
        &mut self,
        time: f64,
        set_requested: bool,
        get_allowed: bool,
        step_finished: bool,
        can_return_early: bool,
    ) -> (bool, f64) {
        let Some(cb) = self.intermediate_update else { return (false, 0.0) };
        let (mut early, mut at) = (false, 0.0f64);
        cb(self.env, time, set_requested, get_allowed, step_finished, can_return_early, &mut early, &mut at);
        (early, at)
    }
}

// ── Instance ────────────────────────────────────────────────────────────────

enum Kind {
    Me { world: bindings::me::ModelExchangeFmu, handle: ResourceAny },
    Cs { world: bindings::cs::CoSimulationFmu, handle: ResourceAny },
}

struct Instance {
    store: Store<Host>,
    kind: Kind,
    /// `fmi3GetString`/`fmi3GetBinary` hand out pointers that live until the
    /// next such call.
    strings: Vec<CString>,
    binaries: Vec<Vec<u8>>,
    /// FMI 2.0 only: what the 3.0 interface has no place to keep.
    fmi2: Option<fmi2::State>,
}

impl Instance {
    fn me(&mut self) -> Option<(&mut Store<Host>, GuestModelExchangeInstance<'_>, ResourceAny)> {
        let Instance { store, kind, .. } = self;
        match kind {
            Kind::Me { world, handle } => {
                Some((store, world.fmi_fmi3_model_exchange().model_exchange_instance(), *handle))
            }
            Kind::Cs { .. } => None,
        }
    }
    fn cs(&mut self) -> Option<(&mut Store<Host>, GuestCoSimulationInstance<'_>, ResourceAny)> {
        let Instance { store, kind, .. } = self;
        match kind {
            Kind::Cs { world, handle } => {
                Some((store, world.fmi_fmi3_co_simulation().co_simulation_instance(), *handle))
            }
            Kind::Me { .. } => None,
        }
    }
}

/// Run `$body` against whichever resource this instance holds. The arms are
/// textually identical but resolve to different generated types. Takes an
/// `Option<&mut Instance>`, so [`fmi2`] can use it on one it already holds.
macro_rules! on_instance {
    ($c:expr, |$store:ident, $g:ident, $h:ident, $st:ident| $body:expr) => {{
        let Some(inst) = $c else { return ERROR };
        let Instance { store: $store, kind, .. } = inst;
        match kind {
            Kind::Me { world, handle } => {
                let $g = world.fmi_fmi3_model_exchange().model_exchange_instance();
                let $h = *handle;
                let $st = st_me;
                $body
            }
            Kind::Cs { world, handle } => {
                let $g = world.fmi_fmi3_co_simulation().co_simulation_instance();
                let $h = *handle;
                let $st = st_cs;
                $body
            }
        }
    }};
}

fn inst_mut<'a>(c: *mut c_void) -> Option<&'a mut Instance> {
    unsafe { (c as *mut Instance).as_mut() }
}

unsafe fn cstr(p: *const c_char) -> String {
    if p.is_null() { String::new() } else { CStr::from_ptr(p).to_string_lossy().into_owned() }
}

// After `on_instance!`: a `macro_rules!` is in scope only for what follows it.
mod fmi2;

/// The `(value reference, derivative order)` pairs the WIT takes where the C API
/// passes two parallel arrays.
unsafe fn requests(vr: *const u32, n: usize, orders: *const i32) -> Option<Vec<(u32, u32)>> {
    if n == 0 {
        return Some(Vec::new());
    }
    if vr.is_null() || orders.is_null() {
        return None;
    }
    (0..n)
        .map(|i| {
            let order = *orders.add(i);
            (order >= 0).then(|| (*vr.add(i), order as u32))
        })
        .collect()
}

unsafe fn vrs<'a>(p: *const u32, n: usize) -> &'a [u32] {
    if p.is_null() || n == 0 { &[] } else { std::slice::from_raw_parts(p, n) }
}

// ── Loading the component ───────────────────────────────────────────────────

/// The FMI platform tuple this build serves, which is also the `.cwasm`'s name.
const PLATFORM: &str = {
    #[cfg(all(target_arch = "x86_64", target_os = "linux"))]
    { "x86_64-linux" }
    #[cfg(all(target_arch = "x86", target_os = "linux"))]
    { "x86-linux" }
    #[cfg(all(target_arch = "aarch64", target_os = "linux"))]
    { "aarch64-linux" }
    #[cfg(all(target_arch = "x86_64", target_os = "windows"))]
    { "x86_64-windows" }
    #[cfg(all(target_arch = "x86", target_os = "windows"))]
    { "x86-windows" }
    #[cfg(all(target_arch = "aarch64", target_os = "windows"))]
    { "aarch64-windows" }
    #[cfg(all(target_arch = "x86_64", target_os = "macos"))]
    { "x86_64-darwin" }
    #[cfg(all(target_arch = "aarch64", target_os = "macos"))]
    { "aarch64-darwin" }
};

fn engine() -> wasmtime::Result<Engine> {
    let mut cfg = Config::new();
    cfg.wasm_component_model(true);
    // A model with external "C" carries the `model_error` tag its call sites catch.
    // The exporter's engine must agree, or the `.cwasm` it precompiled is rejected.
    cfg.wasm_exceptions(true);
    Engine::new(&cfg)
}

/// The component wasm the `jit` feature can compile, if this FMU ships one:
/// `resources/` in an FMI 2.0 FMU, fmi-ls-wasm's `binaries/` in a 3.0 one.
fn component_source(res: &Path) -> Option<PathBuf> {
    let wasm = |dir: PathBuf| -> Option<PathBuf> {
        std::fs::read_dir(dir)
            .ok()?
            .flatten()
            .map(|e| e.path())
            .find(|p| p.extension().is_some_and(|e| e == "wasm"))
    };
    wasm(res.to_path_buf()).or_else(|| wasm(res.parent()?.join("binaries/wasm32-wasip2")))
}

fn load_component(engine: &Engine, res: &Path) -> wasmtime::Result<Component> {
    let cwasm = res.join(format!("{PLATFORM}.cwasm"));
    if cwasm.is_file() {
        let bytes = std::fs::read(&cwasm)?;
        // Safety: the artifact is part of the FMU this library was packaged into.
        return unsafe { Component::deserialize(engine, &bytes) };
    }
    #[cfg(feature = "jit")]
    if let Some(src) = component_source(res) {
        return Component::new(engine, std::fs::read(src)?);
    }
    #[cfg(not(feature = "jit"))]
    let _ = component_source(res);
    wasmtime::bail!(
        "no {PLATFORM}.cwasm in the FMU's resources ({}), and this build cannot compile \
         the component itself",
        res.display()
    )
}

fn new_store(engine: &Engine, res: &str, env: *mut c_void, log: Log, iu: IntermediateUpdateCb) -> wasmtime::Result<Store<Host>> {
    let mut builder = wasmtime_wasi::WasiCtxBuilder::new();
    // C's `messageText` puts the simulation log on the importer's stdout with
    // `printf`; the component's stdout is WASI's, so it has to be this library's.
    builder.inherit_stdout().inherit_stderr();
    // What fmi3Instantiate* points at: a file-based CombiTable reads its table
    // through this preopen.
    if Path::new(res).is_dir() {
        builder.preopened_dir(res, "/", wasmtime_wasi::DirPerms::READ, wasmtime_wasi::FilePerms::READ)?;
    }
    Ok(Store::new(
        engine,
        Host {
            env,
            log,
            intermediate_update: iu,
            wasi: builder.build(),
            table: wasmtime::component::ResourceTable::new(),
        },
    ))
}

fn report(name: &str, env: *mut c_void, log: &Log, e: impl std::fmt::Display) -> *mut c_void {
    log.emit(env, ERROR, "error", &format!("{name}: {e}"));
    std::ptr::null_mut()
}

// ── Lifecycle ───────────────────────────────────────────────────────────────

#[no_mangle]
pub extern "C" fn fmi3GetVersion() -> *const c_char {
    c"3.0".as_ptr()
}

/// Load the component and instantiate its Model Exchange resource; [`fmi2`]
/// differs only in the log sink it hands over.
pub(crate) fn instantiate_me(
    name: &str,
    token: &str,
    res: &str,
    visible: bool,
    logging_on: bool,
    env: *mut c_void,
    log: Log,
) -> wasmtime::Result<Box<Instance>> {
    let engine = engine()?;
    let component = load_component(&engine, Path::new(res))?;
    let mut linker: Linker<Host> = Linker::new(&engine);
    wasmtime_wasi::p2::add_to_linker_sync(&mut linker)?;
    bindings::me::ModelExchangeFmu::add_to_linker::<Host, wasmtime::component::HasSelf<Host>>(&mut linker, |s| s)?;
    // An me_cs component reaches this path too, and its world imports the
    // intermediate-update callbacks even in ME mode.
    bindings::cs::fmi::fmi3::intermediate_update_callbacks::add_to_linker::<Host, wasmtime::component::HasSelf<Host>>(&mut linker, |s| s)?;
    let mut store = new_store(&engine, res, env, log, None)?;
    let world = bindings::me::ModelExchangeFmu::instantiate(&mut store, &component, &linker)?;
    let handle = world
        .fmi_fmi3_model_exchange()
        .model_exchange_instance()
        .call_instantiate_model_exchange(&mut store, name, token, res, visible, logging_on)?
        .ok_or_else(|| wasmtime::Error::msg("the FMU refused to instantiate for Model Exchange"))?;
    Ok(Box::new(Instance {
        store,
        kind: Kind::Me { world, handle },
        strings: Vec::new(),
        binaries: Vec::new(),
        fmi2: None,
    }))
}

/// The Co-Simulation counterpart of [`instantiate_me`].
#[allow(clippy::too_many_arguments)]
pub(crate) fn instantiate_cs(
    name: &str,
    token: &str,
    res: &str,
    visible: bool,
    logging_on: bool,
    event_mode_used: bool,
    early_return_allowed: bool,
    required: &[u32],
    env: *mut c_void,
    log: Log,
    iu: IntermediateUpdateCb,
) -> wasmtime::Result<Box<Instance>> {
    let engine = engine()?;
    let component = load_component(&engine, Path::new(res))?;
    let mut linker: Linker<Host> = Linker::new(&engine);
    wasmtime_wasi::p2::add_to_linker_sync(&mut linker)?;
    bindings::cs::CoSimulationFmu::add_to_linker::<Host, wasmtime::component::HasSelf<Host>>(&mut linker, |s| s)?;
    let mut store = new_store(&engine, res, env, log, iu)?;
    let world = bindings::cs::CoSimulationFmu::instantiate(&mut store, &component, &linker)?;
    let handle = world
        .fmi_fmi3_co_simulation()
        .co_simulation_instance()
        .call_instantiate_co_simulation(
            &mut store, name, token, res, visible, logging_on, event_mode_used,
            early_return_allowed, required,
        )?
        .ok_or_else(|| wasmtime::Error::msg("the FMU refused to instantiate for Co-Simulation"))?;
    Ok(Box::new(Instance {
        store,
        kind: Kind::Cs { world, handle },
        strings: Vec::new(),
        binaries: Vec::new(),
        fmi2: None,
    }))
}

#[no_mangle]
pub unsafe extern "C" fn fmi3InstantiateModelExchange(
    instance_name: *const c_char,
    instantiation_token: *const c_char,
    resource_path: *const c_char,
    visible: bool,
    logging_on: bool,
    instance_environment: *mut c_void,
    log_message: LogCb,
) -> *mut c_void {
    let name = cstr(instance_name);
    let (token, res) = (cstr(instantiation_token), cstr(resource_path));
    match instantiate_me(&name, &token, &res, visible, logging_on, instance_environment, Log::Fmi3(log_message)) {
        Ok(b) => Box::into_raw(b) as *mut c_void,
        Err(e) => report(&name, instance_environment, &Log::Fmi3(log_message), e),
    }
}

#[no_mangle]
pub unsafe extern "C" fn fmi3InstantiateCoSimulation(
    instance_name: *const c_char,
    instantiation_token: *const c_char,
    resource_path: *const c_char,
    visible: bool,
    logging_on: bool,
    event_mode_used: bool,
    early_return_allowed: bool,
    required_intermediate_variables: *const u32,
    n_required_intermediate_variables: usize,
    instance_environment: *mut c_void,
    log_message: LogCb,
    intermediate_update: IntermediateUpdateCb,
) -> *mut c_void {
    let name = cstr(instance_name);
    let (token, res) = (cstr(instantiation_token), cstr(resource_path));
    let required = vrs(required_intermediate_variables, n_required_intermediate_variables).to_vec();
    let built = instantiate_cs(
        &name, &token, &res, visible, logging_on, event_mode_used, early_return_allowed, &required,
        instance_environment, Log::Fmi3(log_message), intermediate_update,
    );
    match built {
        Ok(b) => Box::into_raw(b) as *mut c_void,
        Err(e) => report(&name, instance_environment, &Log::Fmi3(log_message), e),
    }
}

/// Scheduled Execution: no fmi-ls-wasm exporter emits that world yet.
#[no_mangle]
pub unsafe extern "C" fn fmi3InstantiateScheduledExecution(
    instance_name: *const c_char,
    _instantiation_token: *const c_char,
    _resource_path: *const c_char,
    _visible: bool,
    _logging_on: bool,
    instance_environment: *mut c_void,
    log_message: LogCb,
    _clock_update: *mut c_void,
    _lock_preemption: *mut c_void,
    _unlock_preemption: *mut c_void,
) -> *mut c_void {
    let name = cstr(instance_name);
    report(&name, instance_environment, &Log::Fmi3(log_message), "Scheduled Execution is not supported by this FMU")
}

#[no_mangle]
pub unsafe extern "C" fn fmi3FreeInstance(c: *mut c_void) {
    if !c.is_null() {
        drop(Box::from_raw(c as *mut Instance));
    }
}

// ── Mode transitions and other nullary calls ────────────────────────────────

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
nullary!(fmi3ExitInitializationMode, call_exit_initialization_mode);
nullary!(fmi3EnterEventMode, call_enter_event_mode);
nullary!(fmi3Terminate, call_terminate);
nullary!(fmi3Reset, call_reset);
nullary!(fmi3EnterConfigurationMode, call_enter_configuration_mode);
nullary!(fmi3ExitConfigurationMode, call_exit_configuration_mode);
nullary!(fmi3EvaluateDiscreteStates, call_evaluate_discrete_states);
nullary!(fmi3EnterStepMode, call_enter_step_mode);

#[no_mangle]
pub unsafe extern "C" fn fmi3EnterInitializationMode(
    c: *mut c_void,
    tolerance_defined: bool,
    tolerance: f64,
    start_time: f64,
    stop_time_defined: bool,
    stop_time: f64,
) -> i32 {
    let tol = tolerance_defined.then_some(tolerance);
    let stop = stop_time_defined.then_some(stop_time);
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_enter_initialization_mode(store, h, tol, start_time, stop) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SetDebugLogging(
    c: *mut c_void,
    logging_on: bool,
    n_categories: usize,
    categories: *const *const c_char,
) -> i32 {
    let cats: Vec<String> = if categories.is_null() {
        Vec::new()
    } else {
        (0..n_categories).map(|i| cstr(*categories.add(i))).collect()
    };
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_set_debug_logging(store, h, logging_on, &cats) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi3UpdateDiscreteStates(
    c: *mut c_void,
    discrete_states_need_update: *mut bool,
    terminate_simulation: *mut bool,
    nominals_changed: *mut bool,
    values_changed: *mut bool,
    next_event_time_defined: *mut bool,
    next_event_time: *mut f64,
) -> i32 {
    macro_rules! out {
        ($info:expr) => {{
            let i = $info;
            if !discrete_states_need_update.is_null() { *discrete_states_need_update = i.new_discrete_states_needed; }
            if !terminate_simulation.is_null() { *terminate_simulation = i.terminate_simulation; }
            if !nominals_changed.is_null() { *nominals_changed = i.nominals_of_continuous_states_changed; }
            if !values_changed.is_null() { *values_changed = i.values_of_continuous_states_changed; }
            if !next_event_time_defined.is_null() { *next_event_time_defined = i.next_event_time_defined; }
            if !next_event_time.is_null() { *next_event_time = i.next_event_time; }
            OK
        }};
    }
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_update_discrete_states(store, h) {
        Ok(Ok(info)) => out!(info),
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

// ── Variable access ─────────────────────────────────────────────────────────

macro_rules! getter {
    ($cfn:ident, $wfn:ident, $ty:ty) => {
        #[no_mangle]
        pub unsafe extern "C" fn $cfn(
            c: *mut c_void,
            value_references: *const u32,
            n_value_references: usize,
            values: *mut $ty,
            n_values: usize,
        ) -> i32 {
            let refs = vrs(value_references, n_value_references);
            on_instance!(inst_mut(c), |store, g, h, st| match g.$wfn(store, h, refs) {
                Ok(Ok(v)) => {
                    if v.len() != n_values || values.is_null() {
                        return ERROR;
                    }
                    std::slice::from_raw_parts_mut(values, n_values).copy_from_slice(&v);
                    OK
                }
                Ok(Err(s)) => st(s),
                Err(_) => ERROR,
            })
        }
    };
}
getter!(fmi3GetFloat32, call_get_float32, f32);
getter!(fmi3GetFloat64, call_get_float64, f64);
getter!(fmi3GetInt8, call_get_int8, i8);
getter!(fmi3GetUInt8, call_get_uint8, u8);
getter!(fmi3GetInt16, call_get_int16, i16);
getter!(fmi3GetUInt16, call_get_uint16, u16);
getter!(fmi3GetInt32, call_get_int32, i32);
getter!(fmi3GetUInt32, call_get_uint32, u32);
getter!(fmi3GetInt64, call_get_int64, i64);
getter!(fmi3GetUInt64, call_get_uint64, u64);
getter!(fmi3GetBoolean, call_get_boolean, bool);

macro_rules! setter {
    ($cfn:ident, $wfn:ident, $ty:ty) => {
        #[no_mangle]
        pub unsafe extern "C" fn $cfn(
            c: *mut c_void,
            value_references: *const u32,
            n_value_references: usize,
            values: *const $ty,
            n_values: usize,
        ) -> i32 {
            let refs = vrs(value_references, n_value_references);
            if values.is_null() && n_values != 0 {
                return ERROR;
            }
            let vals = if n_values == 0 { &[][..] } else { std::slice::from_raw_parts(values, n_values) };
            on_instance!(inst_mut(c), |store, g, h, st| match g.$wfn(store, h, refs, vals) {
                Ok(s) => st(s),
                Err(_) => ERROR,
            })
        }
    };
}
setter!(fmi3SetFloat32, call_set_float32, f32);
setter!(fmi3SetFloat64, call_set_float64, f64);
setter!(fmi3SetInt8, call_set_int8, i8);
setter!(fmi3SetUInt8, call_set_uint8, u8);
setter!(fmi3SetInt16, call_set_int16, i16);
setter!(fmi3SetUInt16, call_set_uint16, u16);
setter!(fmi3SetInt32, call_set_int32, i32);
setter!(fmi3SetUInt32, call_set_uint32, u32);
setter!(fmi3SetInt64, call_set_int64, i64);
setter!(fmi3SetUInt64, call_set_uint64, u64);
setter!(fmi3SetBoolean, call_set_boolean, bool);

/// `fmi3Clock` has no `nValues`: one value per reference.
#[no_mangle]
pub unsafe extern "C" fn fmi3GetClock(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    values: *mut bool,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_get_clock(store, h, refs) {
        Ok(Ok(v)) => {
            if v.len() != n_value_references || values.is_null() {
                return ERROR;
            }
            std::slice::from_raw_parts_mut(values, n_value_references).copy_from_slice(&v);
            OK
        }
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SetClock(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    values: *const bool,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    if values.is_null() && n_value_references != 0 {
        return ERROR;
    }
    let vals = if n_value_references == 0 { &[][..] } else { std::slice::from_raw_parts(values, n_value_references) };
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_set_clock(store, h, refs, vals) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

/// The returned pointers borrow from the instance until the next `fmi3GetString`.
#[no_mangle]
pub unsafe extern "C" fn fmi3GetString(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    values: *mut *const c_char,
    n_values: usize,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    let Some(inst) = inst_mut(c) else { return ERROR };
    let got = {
        let Instance { store, kind, .. } = inst;
        match kind {
            Kind::Me { world, handle } => world
                .fmi_fmi3_model_exchange()
                .model_exchange_instance()
                .call_get_string(store, *handle, refs)
                .map(|r| r.map_err(st_me)),
            Kind::Cs { world, handle } => world
                .fmi_fmi3_co_simulation()
                .co_simulation_instance()
                .call_get_string(store, *handle, refs)
                .map(|r| r.map_err(st_cs)),
        }
    };
    let strings = match got {
        Ok(Ok(v)) => v,
        Ok(Err(s)) => return s,
        Err(_) => return ERROR,
    };
    if strings.len() != n_values || values.is_null() {
        return ERROR;
    }
    inst.strings = strings
        .into_iter()
        .map(|s| CString::new(s).unwrap_or_default())
        .collect();
    for (i, s) in inst.strings.iter().enumerate() {
        *values.add(i) = s.as_ptr();
    }
    OK
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SetString(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    values: *const *const c_char,
    n_values: usize,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    if values.is_null() && n_values != 0 {
        return ERROR;
    }
    let vals: Vec<String> = (0..n_values).map(|i| cstr(*values.add(i))).collect();
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_set_string(store, h, refs, &vals) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

/// The returned pointers borrow from the instance until the next `fmi3GetBinary`.
#[no_mangle]
pub unsafe extern "C" fn fmi3GetBinary(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    value_sizes: *mut usize,
    values: *mut *const u8,
    n_values: usize,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    let Some(inst) = inst_mut(c) else { return ERROR };
    let got = {
        let Instance { store, kind, .. } = inst;
        match kind {
            Kind::Me { world, handle } => world
                .fmi_fmi3_model_exchange()
                .model_exchange_instance()
                .call_get_binary(store, *handle, refs)
                .map(|r| r.map_err(st_me)),
            Kind::Cs { world, handle } => world
                .fmi_fmi3_co_simulation()
                .co_simulation_instance()
                .call_get_binary(store, *handle, refs)
                .map(|r| r.map_err(st_cs)),
        }
    };
    let blobs = match got {
        Ok(Ok(v)) => v,
        Ok(Err(s)) => return s,
        Err(_) => return ERROR,
    };
    if blobs.len() != n_values || values.is_null() || value_sizes.is_null() {
        return ERROR;
    }
    inst.binaries = blobs;
    for (i, b) in inst.binaries.iter().enumerate() {
        *value_sizes.add(i) = b.len();
        *values.add(i) = b.as_ptr();
    }
    OK
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SetBinary(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    value_sizes: *const usize,
    values: *const *const u8,
    n_values: usize,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    if (values.is_null() || value_sizes.is_null()) && n_values != 0 {
        return ERROR;
    }
    let vals: Vec<Vec<u8>> = (0..n_values)
        .map(|i| {
            let p = *values.add(i);
            let n = *value_sizes.add(i);
            if p.is_null() { Vec::new() } else { std::slice::from_raw_parts(p, n).to_vec() }
        })
        .collect();
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_set_binary(store, h, refs, &vals) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

// ── FMU state ───────────────────────────────────────────────────────────────
//
// The WIT models a state as its serialized bytes, so `fmi3FMUState` is a boxed
// `Vec<u8>`.

#[no_mangle]
pub unsafe extern "C" fn fmi3GetFMUState(c: *mut c_void, state: *mut *mut c_void) -> i32 {
    if state.is_null() {
        return ERROR;
    }
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_get_fmu_state(store, h) {
        Ok(Ok(bytes)) => {
            // A non-null incoming state is a buffer to reuse.
            if !(*state).is_null() {
                drop(Box::from_raw(*state as *mut Vec<u8>));
            }
            *state = Box::into_raw(Box::new(bytes)) as *mut c_void;
            OK
        }
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SetFMUState(c: *mut c_void, state: *mut c_void) -> i32 {
    let Some(bytes) = (state as *const Vec<u8>).as_ref() else { return ERROR };
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_set_fmu_state(store, h, bytes) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi3FreeFMUState(_c: *mut c_void, state: *mut *mut c_void) -> i32 {
    if state.is_null() {
        return ERROR;
    }
    if !(*state).is_null() {
        drop(Box::from_raw(*state as *mut Vec<u8>));
        *state = std::ptr::null_mut();
    }
    OK
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SerializedFMUStateSize(_c: *mut c_void, state: *mut c_void, size: *mut usize) -> i32 {
    let (Some(bytes), false) = ((state as *const Vec<u8>).as_ref(), size.is_null()) else { return ERROR };
    *size = bytes.len();
    OK
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SerializeFMUState(
    _c: *mut c_void,
    state: *mut c_void,
    serialized: *mut u8,
    size: usize,
) -> i32 {
    let Some(bytes) = (state as *const Vec<u8>).as_ref() else { return ERROR };
    if serialized.is_null() || size != bytes.len() {
        return ERROR;
    }
    std::slice::from_raw_parts_mut(serialized, size).copy_from_slice(bytes);
    OK
}

#[no_mangle]
pub unsafe extern "C" fn fmi3DeserializeFMUState(
    _c: *mut c_void,
    serialized: *const u8,
    size: usize,
    state: *mut *mut c_void,
) -> i32 {
    if state.is_null() || (serialized.is_null() && size != 0) {
        return ERROR;
    }
    let bytes = if size == 0 { Vec::new() } else { std::slice::from_raw_parts(serialized, size).to_vec() };
    *state = Box::into_raw(Box::new(bytes)) as *mut c_void;
    OK
}

// ── Derivatives and dependencies ────────────────────────────────────────────

macro_rules! derivative {
    ($cfn:ident, $wfn:ident) => {
        #[no_mangle]
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
        ) -> i32 {
            let (u, k) = (vrs(unknowns, n_unknowns), vrs(knowns, n_knowns));
            if seed.is_null() && n_seed != 0 {
                return ERROR;
            }
            let s = if n_seed == 0 { &[][..] } else { std::slice::from_raw_parts(seed, n_seed) };
            on_instance!(inst_mut(c), |store, g, h, st| match g.$wfn(store, h, u, k, s) {
                Ok(Ok(v)) => {
                    if v.len() != n_sensitivity || sensitivity.is_null() {
                        return ERROR;
                    }
                    std::slice::from_raw_parts_mut(sensitivity, n_sensitivity).copy_from_slice(&v);
                    OK
                }
                Ok(Err(s)) => st(s),
                Err(_) => ERROR,
            })
        }
    };
}
derivative!(fmi3GetDirectionalDerivative, call_get_directional_derivative);
derivative!(fmi3GetAdjointDerivative, call_get_adjoint_derivative);

#[no_mangle]
pub unsafe extern "C" fn fmi3GetNumberOfVariableDependencies(
    c: *mut c_void,
    value_reference: u32,
    n_dependencies: *mut usize,
) -> i32 {
    if n_dependencies.is_null() {
        return ERROR;
    }
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_get_number_of_variable_dependencies(store, h, value_reference) {
        Ok(Ok(n)) => {
            *n_dependencies = n as usize;
            OK
        }
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi3GetVariableDependencies(
    c: *mut c_void,
    dependent: u32,
    element_indices_of_dependent: *mut usize,
    independents: *mut u32,
    element_indices_of_independents: *mut usize,
    dependency_kinds: *mut i32,
    n_dependencies: usize,
) -> i32 {
    macro_rules! out {
        ($deps:expr) => {{
            let deps = $deps;
            if deps.len() != n_dependencies {
                return ERROR;
            }
            for (i, d) in deps.iter().enumerate() {
                if !element_indices_of_dependent.is_null() {
                    *element_indices_of_dependent.add(i) = d.element_index_of_dependent as usize;
                }
                if !independents.is_null() {
                    *independents.add(i) = d.independent_value_reference;
                }
                if !element_indices_of_independents.is_null() {
                    *element_indices_of_independents.add(i) = d.element_index_of_independent as usize;
                }
                if !dependency_kinds.is_null() {
                    *dependency_kinds.add(i) = d.kind as i32;
                }
            }
            OK
        }};
    }
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_get_variable_dependencies(store, h, dependent) {
        Ok(Ok(deps)) => out!(deps),
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

// ── Clocks ──────────────────────────────────────────────────────────────────

#[no_mangle]
pub unsafe extern "C" fn fmi3GetIntervalDecimal(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    intervals: *mut f64,
    qualifiers: *mut i32,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_get_interval_decimal(store, h, refs) {
        Ok(Ok(v)) => {
            if v.len() != n_value_references {
                return ERROR;
            }
            for (i, (interval, q)) in v.iter().enumerate() {
                if !intervals.is_null() { *intervals.add(i) = *interval; }
                if !qualifiers.is_null() { *qualifiers.add(i) = *q as i32; }
            }
            OK
        }
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi3GetIntervalFraction(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    counters: *mut u64,
    resolutions: *mut u64,
    qualifiers: *mut i32,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_get_interval_fraction(store, h, refs) {
        Ok(Ok(v)) => {
            if v.len() != n_value_references {
                return ERROR;
            }
            for (i, (f, q)) in v.iter().enumerate() {
                if !counters.is_null() { *counters.add(i) = f.counter; }
                if !resolutions.is_null() { *resolutions.add(i) = f.resolution; }
                if !qualifiers.is_null() { *qualifiers.add(i) = *q as i32; }
            }
            OK
        }
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi3GetShiftDecimal(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    shifts: *mut f64,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_get_shift_decimal(store, h, refs) {
        Ok(Ok(v)) => {
            if v.len() != n_value_references || shifts.is_null() {
                return ERROR;
            }
            std::slice::from_raw_parts_mut(shifts, n_value_references).copy_from_slice(&v);
            OK
        }
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi3GetShiftFraction(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    counters: *mut u64,
    resolutions: *mut u64,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_get_shift_fraction(store, h, refs) {
        Ok(Ok(v)) => {
            if v.len() != n_value_references {
                return ERROR;
            }
            for (i, f) in v.iter().enumerate() {
                if !counters.is_null() { *counters.add(i) = f.counter; }
                if !resolutions.is_null() { *resolutions.add(i) = f.resolution; }
            }
            OK
        }
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SetIntervalDecimal(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    intervals: *const f64,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    if intervals.is_null() && n_value_references != 0 {
        return ERROR;
    }
    let v = if n_value_references == 0 { &[][..] } else { std::slice::from_raw_parts(intervals, n_value_references) };
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_set_interval_decimal(store, h, refs, v) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SetShiftDecimal(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    shifts: *const f64,
) -> i32 {
    let refs = vrs(value_references, n_value_references);
    if shifts.is_null() && n_value_references != 0 {
        return ERROR;
    }
    let v = if n_value_references == 0 { &[][..] } else { std::slice::from_raw_parts(shifts, n_value_references) };
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_set_shift_decimal(store, h, refs, v) {
        Ok(s) => st(s),
        Err(_) => ERROR,
    })
}

macro_rules! set_fraction {
    ($cfn:ident, $wfn:ident, $rec_me:path, $rec_cs:path) => {
        #[no_mangle]
        pub unsafe extern "C" fn $cfn(
            c: *mut c_void,
            value_references: *const u32,
            n_value_references: usize,
            counters: *const u64,
            resolutions: *const u64,
        ) -> i32 {
            let refs = vrs(value_references, n_value_references);
            if (counters.is_null() || resolutions.is_null()) && n_value_references != 0 {
                return ERROR;
            }
            let Some(inst) = inst_mut(c) else { return ERROR };
            let Instance { store, kind, .. } = inst;
            match kind {
                Kind::Me { world, handle } => {
                    type Frac = $rec_me;
                    let v: Vec<_> = (0..n_value_references)
                        .map(|i| Frac { counter: *counters.add(i), resolution: *resolutions.add(i) })
                        .collect();
                    match world.fmi_fmi3_model_exchange().model_exchange_instance().$wfn(store, *handle, refs, &v) {
                        Ok(s) => st_me(s),
                        Err(_) => ERROR,
                    }
                }
                Kind::Cs { world, handle } => {
                    type Frac = $rec_cs;
                    let v: Vec<_> = (0..n_value_references)
                        .map(|i| Frac { counter: *counters.add(i), resolution: *resolutions.add(i) })
                        .collect();
                    match world.fmi_fmi3_co_simulation().co_simulation_instance().$wfn(store, *handle, refs, &v) {
                        Ok(s) => st_cs(s),
                        Err(_) => ERROR,
                    }
                }
            }
        }
    };
}
set_fraction!(
    fmi3SetIntervalFraction,
    call_set_interval_fraction,
    bindings::me::fmi::fmi3::types::IntervalFraction,
    bindings::cs::fmi::fmi3::types::IntervalFraction
);
set_fraction!(
    fmi3SetShiftFraction,
    call_set_shift_fraction,
    bindings::me::fmi::fmi3::types::IntervalFraction,
    bindings::cs::fmi::fmi3::types::IntervalFraction
);

// ── Model Exchange ──────────────────────────────────────────────────────────

#[no_mangle]
pub unsafe extern "C" fn fmi3EnterContinuousTimeMode(c: *mut c_void) -> i32 {
    let Some(inst) = inst_mut(c) else { return ERROR };
    let Some((store, g, h)) = inst.me() else { return ERROR };
    match g.call_enter_continuous_time_mode(store, h) {
        Ok(s) => st_me(s),
        Err(_) => ERROR,
    }
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SetTime(c: *mut c_void, time: f64) -> i32 {
    let Some(inst) = inst_mut(c) else { return ERROR };
    let Some((store, g, h)) = inst.me() else { return ERROR };
    match g.call_set_time(store, h, time) {
        Ok(s) => st_me(s),
        Err(_) => ERROR,
    }
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SetContinuousStates(c: *mut c_void, states: *const f64, n: usize) -> i32 {
    if states.is_null() && n != 0 {
        return ERROR;
    }
    let v = if n == 0 { &[][..] } else { std::slice::from_raw_parts(states, n) };
    let Some(inst) = inst_mut(c) else { return ERROR };
    let Some((store, g, h)) = inst.me() else { return ERROR };
    match g.call_set_continuous_states(store, h, v) {
        Ok(s) => st_me(s),
        Err(_) => ERROR,
    }
}

macro_rules! me_vector {
    ($cfn:ident, $wfn:ident) => {
        #[no_mangle]
        pub unsafe extern "C" fn $cfn(c: *mut c_void, values: *mut f64, n: usize) -> i32 {
            let Some(inst) = inst_mut(c) else { return ERROR };
            let Some((store, g, h)) = inst.me() else { return ERROR };
            match g.$wfn(store, h) {
                Ok(Ok(v)) => {
                    if v.len() != n || values.is_null() {
                        return ERROR;
                    }
                    std::slice::from_raw_parts_mut(values, n).copy_from_slice(&v);
                    OK
                }
                Ok(Err(s)) => st_me(s),
                Err(_) => ERROR,
            }
        }
    };
}
me_vector!(fmi3GetContinuousStateDerivatives, call_get_continuous_state_derivatives);
me_vector!(fmi3GetEventIndicators, call_get_event_indicators);
me_vector!(fmi3GetContinuousStates, call_get_continuous_states);
me_vector!(fmi3GetNominalsOfContinuousStates, call_get_nominals_of_continuous_states);

macro_rules! me_count {
    ($cfn:ident, $wfn:ident) => {
        #[no_mangle]
        pub unsafe extern "C" fn $cfn(c: *mut c_void, n: *mut usize) -> i32 {
            if n.is_null() {
                return ERROR;
            }
            let Some(inst) = inst_mut(c) else { return ERROR };
            let Some((store, g, h)) = inst.me() else { return ERROR };
            match g.$wfn(store, h) {
                Ok(Ok(v)) => {
                    *n = v as usize;
                    OK
                }
                Ok(Err(s)) => st_me(s),
                Err(_) => ERROR,
            }
        }
    };
}
me_count!(fmi3GetNumberOfEventIndicators, call_get_number_of_event_indicators);
me_count!(fmi3GetNumberOfContinuousStates, call_get_number_of_continuous_states);

#[no_mangle]
pub unsafe extern "C" fn fmi3CompletedIntegratorStep(
    c: *mut c_void,
    no_set_fmu_state_prior: bool,
    enter_event_mode: *mut bool,
    terminate_simulation: *mut bool,
) -> i32 {
    let Some(inst) = inst_mut(c) else { return ERROR };
    let Some((store, g, h)) = inst.me() else { return ERROR };
    match g.call_completed_integrator_step(store, h, no_set_fmu_state_prior) {
        Ok(Ok(r)) => {
            if !enter_event_mode.is_null() {
                *enter_event_mode = r.enter_event_mode;
            }
            if !terminate_simulation.is_null() {
                *terminate_simulation = r.terminate_simulation;
            }
            OK
        }
        Ok(Err(s)) => st_me(s),
        Err(_) => ERROR,
    }
}

// ── Co-Simulation ───────────────────────────────────────────────────────────

#[no_mangle]
pub unsafe extern "C" fn fmi3DoStep(
    c: *mut c_void,
    current_communication_point: f64,
    communication_step_size: f64,
    no_set_fmu_state_prior: bool,
    event_handling_needed: *mut bool,
    terminate_simulation: *mut bool,
    early_return: *mut bool,
    last_successful_time: *mut f64,
) -> i32 {
    let Some(inst) = inst_mut(c) else { return ERROR };
    let Some((store, g, h)) = inst.cs() else { return ERROR };
    match g.call_do_step(store, h, current_communication_point, communication_step_size, no_set_fmu_state_prior) {
        Ok(Ok(r)) => {
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
            OK
        }
        Ok(Err(s)) => st_cs(s),
        Err(_) => ERROR,
    }
}

#[no_mangle]
pub unsafe extern "C" fn fmi3SetInputDerivatives(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    orders: *const i32,
    values: *const f64,
    n_values: usize,
) -> i32 {
    let Some(requests) = requests(value_references, n_value_references, orders) else { return ERROR };
    if values.is_null() && n_values != 0 {
        return ERROR;
    }
    let v = if n_values == 0 { &[][..] } else { std::slice::from_raw_parts(values, n_values) };
    let Some(inst) = inst_mut(c) else { return ERROR };
    let Some((store, g, h)) = inst.cs() else { return ERROR };
    match g.call_set_input_derivatives(store, h, &requests, v) {
        Ok(s) => st_cs(s),
        Err(_) => ERROR,
    }
}

#[no_mangle]
pub unsafe extern "C" fn fmi3GetOutputDerivatives(
    c: *mut c_void,
    value_references: *const u32,
    n_value_references: usize,
    orders: *const i32,
    values: *mut f64,
    n_values: usize,
) -> i32 {
    let Some(requests) = requests(value_references, n_value_references, orders) else { return ERROR };
    on_instance!(inst_mut(c), |store, g, h, st| match g.call_get_output_derivatives(store, h, &requests) {
        Ok(Ok(v)) => {
            if v.len() != n_values || values.is_null() {
                return ERROR;
            }
            std::slice::from_raw_parts_mut(values, n_values).copy_from_slice(&v);
            OK
        }
        Ok(Err(s)) => st(s),
        Err(_) => ERROR,
    })
}

/// Scheduled Execution only; no world exports it yet.
#[no_mangle]
pub unsafe extern "C" fn fmi3ActivateModelPartition(_c: *mut c_void, _clock: u32, _activation_time: f64) -> i32 {
    ERROR
}
