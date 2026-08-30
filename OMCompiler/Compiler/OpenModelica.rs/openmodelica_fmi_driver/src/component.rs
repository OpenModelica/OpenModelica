//! The FMI 3.0 API over an fmi-ls-wasm **component**, in this process.
//!
//! The same thing `openmodelica_fmi_ls_wasm_to_native` does for an importer that
//! wants a shared library, done for a caller that is already Rust: wasmtime
//! instantiates the component and the [`api`](crate::api) traits are served from
//! its exports, so [`me::simulate`](crate::me::simulate) and
//! [`cs::simulate`](crate::cs::simulate) drive it exactly as they drive a native
//! FMU.
//!
//! The world bound here is OpenModelica's `me_cs` one, which also carries the
//! model's own simulation runtime (`om:sim/simulation`) — so one artifact, one
//! compilation, three ways to run it.
//!
//! A `.cwasm` is tied to the exact wasmtime version *and* [`engine`]
//! configuration that produced it; the exporter uses this same configuration.

use std::path::Path;

use wasmtime::component::{Component, Linker, ResourceAny};
use wasmtime::{Config, Engine, Store};

use crate::api::{CompletedStep, DiscreteStates, DoStep, Fmi3, Fmi3CoSimulation, Fmi3ModelExchange, Status};
use crate::{Error, Result};
use openmodelica_fmi::VarType;

mod bindings {
    //! The WIT is shared with the wasm-side adapter rather than copied.
    wasmtime::component::bindgen!({
        path: "../openmodelica_fmi3_wasm/wit",
        world: "model-exchange-and-co-simulation-fmu",
    });
}

use bindings::exports::fmi::fmi3::co_simulation::GuestCoSimulationInstance;
use bindings::exports::fmi::fmi3::model_exchange::GuestModelExchangeInstance;
use bindings::fmi::fmi3::types::Status as WitStatus;

fn status(s: WitStatus) -> Status {
    match s {
        WitStatus::Ok => Status::Ok,
        WitStatus::Warning => Status::Warning,
        WitStatus::Discard => Status::Discard,
        WitStatus::Error => Status::Error,
        WitStatus::Fatal => Status::Fatal,
    }
}

/// A component call that traps, or a status the master cannot continue from.
fn trap(call: &'static str, e: impl std::fmt::Display) -> Error {
    Error::Load(format!("{call}: {e}"))
}

fn check(call: &'static str, s: WitStatus) -> Result<()> {
    let s = status(s);
    if s.is_ok() { Ok(()) } else { Err(Error::Status { call, status: s }) }
}

/// Unwrap what a WIT `result<T, status>` returned.
fn unwrap<T>(call: &'static str, r: std::result::Result<T, WitStatus>) -> Result<T> {
    r.map_err(|s| Error::Status { call, status: status(s) })
}

// ── Host state ──────────────────────────────────────────────────────────────

/// What the component's imports are served from: the log callback and WASI (the
/// FMU's stdout, and the preopen a file-reading `external "C"` needs).
pub struct Host {
    /// What the FMU logged since the master last drained it.
    log: Vec<(Status, String, String)>,
    /// The FMU's stdout, which is where the simulation log goes (C's FMU prints
    /// the `-lv` streams with `printf`). Captured rather than inherited, so the
    /// caller can fold it into the run's log instead of the terminal.
    stdout: wasmtime_wasi::p2::pipe::MemoryOutputPipe,
    wasi: wasmtime_wasi::WasiCtx,
    table: wasmtime::component::ResourceTable,
    /// The FMU's resources, where its host-served externals' table is.
    resources: Option<std::path::PathBuf>,
    natives: Option<std::result::Result<openmodelica_ext_native::Natives, String>>,
}

impl wasmtime_wasi::WasiView for Host {
    fn ctx(&mut self) -> wasmtime_wasi::WasiCtxView<'_> {
        wasmtime_wasi::WasiCtxView { ctx: &mut self.wasi, table: &mut self.table }
    }
}

impl bindings::fmi::fmi3::types::Host for Host {}

impl bindings::fmi::fmi3::callbacks::Host for Host {
    fn log_message(&mut self, _instance_name: String, s: WitStatus, category: String, message: String) {
        self.log.push((status(s), category, message));
    }
    fn clock_update(&mut self) {}
    fn lock_preemption(&mut self) {}
    fn unlock_preemption(&mut self) {}
}

impl bindings::om::ext::native::Host for Host {
    fn call(
        &mut self,
        index: u32,
        args: Vec<bindings::om::ext::native::Value>,
    ) -> std::result::Result<Vec<bindings::om::ext::native::Value>, String> {
        use bindings::om::ext::native::Value as W;
        use openmodelica_ext_native::marshal::Value as V;
        if self.natives.is_none() {
            self.natives = Some(open_natives(self.resources.as_deref()));
        }
        let natives = self.natives.as_mut().unwrap().as_mut().map_err(|e| e.clone())?;
        let args: Vec<V> = args
            .into_iter()
            .map(|v| match v {
                W::Int(i) => V::Int(i),
                W::Real(r) => V::Real(r),
                W::Str(s) => V::Str(s),
                W::Bytes(b) => V::Bytes(b),
                W::Handle(h) => V::Handle(h),
            })
            .collect();
        Ok(natives
            .call(index, &args)?
            .into_iter()
            .map(|v| match v {
                V::Int(i) => W::Int(i),
                V::Real(r) => W::Real(r),
                V::Str(s) => W::Str(s),
                V::Bytes(b) => W::Bytes(b),
                V::Handle(h) => W::Handle(h),
            })
            .collect())
    }
}

/// The artifact's platform libraries, from its `binaries/<platform>/`.
fn open_natives(resources: Option<&Path>) -> std::result::Result<openmodelica_ext_native::Natives, String> {
    let Some(res) = resources else {
        return Err("the artifact has host-served `external \"C\"` functions but no resources directory".to_string());
    };
    let text = std::fs::read_to_string(res.join(openmodelica_ext_native::TABLE_FILE))
        .map_err(|e| format!("cannot read {}: {e}", openmodelica_ext_native::TABLE_FILE))?;
    let table = openmodelica_ext_native::marshal::parse(&text)?;
    let binaries = res
        .parent()
        .and_then(openmodelica_ext_native::binaries_dir)
        .ok_or_else(|| "the artifact has no binaries/ directory for this platform".to_string())?;
    openmodelica_ext_native::Natives::open(&table, &binaries)
}

impl bindings::fmi::fmi3::intermediate_update_callbacks::Host for Host {
    /// The master handles events between communication points instead, so it
    /// never asks the FMU to return early from inside a step.
    fn intermediate_update(&mut self, _t: f64, _set: bool, _get: bool, _finished: bool, _early: bool) -> (bool, f64) {
        (false, 0.0)
    }
}

// ── The component ───────────────────────────────────────────────────────────

/// The engine every artifact is compiled and run with. A `.cwasm` records the
/// configuration and is refused by an engine configured differently, so the
/// exporter (`CodegenWasmJit::native_fmu::precompile`) uses these same settings.
pub fn engine() -> Result<Engine> {
    let mut cfg = Config::new();
    cfg.wasm_component_model(true);
    // A model with external "C" carries the `model_error` tag its call sites catch.
    cfg.wasm_exceptions(true);
    Engine::new(&cfg).map_err(|e| trap("wasmtime engine", e))
}

pub struct WasmArtifact {
    engine: Engine,
    component: Component,
    /// Where `Modelica.Utilities.Files.loadResource` and a file-backed table read
    /// from, preopened as the component's `/`. Not part of the compilation, so an
    /// exporter that compiles the component before writing the files beside it
    /// says where they are afterwards ([`use_resources`](Self::use_resources)).
    resources: std::sync::Mutex<Option<std::path::PathBuf>>,
}

impl WasmArtifact {
    /// Deserialize a `.cwasm` this build precompiled. Loading is a mmap and a
    /// relocation pass, not a compilation — which is the whole point of exporting
    /// one.
    ///
    /// # Safety
    /// wasmtime cannot validate a precompiled artifact; the caller vouches that
    /// the bytes came from `precompile` on this machine.
    pub unsafe fn from_cwasm(bytes: &[u8], resources: Option<&Path>) -> Result<WasmArtifact> {
        let engine = engine()?;
        let component = unsafe { Component::deserialize(&engine, bytes) }
            .map_err(|e| trap("deserializing the precompiled artifact", e))?;
        Ok(WasmArtifact { engine, component, resources: std::sync::Mutex::new(resources.map(Path::to_path_buf)) })
    }

    /// Deserialize a `.cwasm` **from a file**, which wasmtime maps rather than
    /// reads: loading an artifact is then a few page faults whatever its size.
    ///
    /// # Safety
    /// As [`from_cwasm`](Self::from_cwasm): the file has to be one this build
    /// precompiled.
    pub unsafe fn from_cwasm_file(path: &Path, resources: Option<&Path>) -> Result<WasmArtifact> {
        let engine = engine()?;
        let component = unsafe { Component::deserialize_file(&engine, path) }
            .map_err(|e| trap("deserializing the precompiled artifact", e))?;
        Ok(WasmArtifact { engine, component, resources: std::sync::Mutex::new(resources.map(Path::to_path_buf)) })
    }

    /// Compile the component itself, for an artifact with no `.cwasm` for this
    /// platform.
    pub fn compile(bytes: &[u8], resources: Option<&Path>) -> Result<WasmArtifact> {
        let engine = engine()?;
        let component =
            Component::new(&engine, bytes).map_err(|e| trap("compiling the artifact", e))?;
        Ok(WasmArtifact { engine, component, resources: std::sync::Mutex::new(resources.map(Path::to_path_buf)) })
    }

    /// Compile `component` for this machine and return the `.cwasm` bytes.
    pub fn precompile(bytes: &[u8]) -> Result<Vec<u8>> {
        engine()?.precompile_component(bytes).map_err(|e| trap("precompiling the artifact", e))
    }

    /// The `.cwasm` bytes for what is already compiled here: serializing an
    /// artifact is writing out machine code that exists, where `precompile`
    /// would compile it a second time.
    pub fn serialize(&self) -> Result<Vec<u8>> {
        self.component.serialize().map_err(|e| trap("serializing the artifact", e))
    }

    /// Point the component at its resources, for a caller that compiled it before
    /// they were on disk.
    pub fn use_resources(&self, dir: &Path) {
        *self.resources.lock().unwrap_or_else(|e| e.into_inner()) = Some(dir.to_path_buf());
    }

    fn store(&self) -> Result<Store<Host>> {
        let mut builder = wasmtime_wasi::WasiCtxBuilder::new();
        // 16 MB: a chatty `-lv` run of a long simulation, and no more.
        let stdout = wasmtime_wasi::p2::pipe::MemoryOutputPipe::new(16 << 20);
        builder.stdout(stdout.clone()).stderr(stdout.clone());
        let resources = self.resources.lock().unwrap_or_else(|e| e.into_inner()).clone();
        if let Some(dir) = resources.filter(|d| d.is_dir()) {
            builder
                .preopened_dir(&dir, "/", wasmtime_wasi::DirPerms::READ, wasmtime_wasi::FilePerms::READ)
                .map_err(|e| trap("preopening the resources directory", e))?;
        }
        Ok(Store::new(
            &self.engine,
            Host {
                log: Vec::new(),
                stdout,
                wasi: builder.build(),
                table: wasmtime::component::ResourceTable::new(),
                resources: self.resources.lock().unwrap_or_else(|e| e.into_inner()).clone(),
                natives: None,
            },
        ))
    }

    fn linker(&self) -> Result<Linker<Host>> {
        let mut linker: Linker<Host> = Linker::new(&self.engine);
        wasmtime_wasi::p2::add_to_linker_sync(&mut linker)
            .map_err(|e| trap("linking WASI", e))?;
        bindings::ModelExchangeAndCoSimulationFmu::add_to_linker::<
            Host,
            wasmtime::component::HasSelf<Host>,
        >(&mut linker, |s| s)
        .map_err(|e| trap("linking the FMI callbacks", e))?;
        Ok(linker)
    }

    fn instantiate(&self) -> Result<(Store<Host>, bindings::ModelExchangeAndCoSimulationFmu)> {
        let linker = self.linker()?;
        let mut store = self.store()?;
        let world =
            bindings::ModelExchangeAndCoSimulationFmu::instantiate(&mut store, &self.component, &linker)
                .map_err(|e| trap("instantiating the artifact", e))?;
        Ok((store, world))
    }

    pub fn model_exchange(&self, name: &str, logging_on: bool) -> Result<WasmInstance> {
        let (mut store, world) = self.instantiate()?;
        let res = self.resource_path();
        let handle = world
            .fmi_fmi3_model_exchange()
            .model_exchange_instance()
            .call_instantiate_model_exchange(&mut store, name, "", &res, false, logging_on)
            .map_err(|e| trap("fmi3InstantiateModelExchange", e))?
            .ok_or_else(|| Error::Instantiate {
                call: "fmi3InstantiateModelExchange",
                log: std::mem::take(&mut store.data_mut().log),
            })?;
        Ok(WasmInstance { store, world, handle, kind: Kind::Me })
    }

    /// Instantiate the Co-Simulation interface. `event_mode` lets the FMU stop at
    /// its own events and hand them to the master, with early return.
    pub fn co_simulation(&self, name: &str, logging_on: bool, event_mode: bool) -> Result<WasmInstance> {
        let (mut store, world) = self.instantiate()?;
        let res = self.resource_path();
        let handle = world
            .fmi_fmi3_co_simulation()
            .co_simulation_instance()
            .call_instantiate_co_simulation(
                &mut store, name, "", &res, false, logging_on, event_mode, event_mode, &[],
            )
            .map_err(|e| trap("fmi3InstantiateCoSimulation", e))?
            .ok_or_else(|| Error::Instantiate {
                call: "fmi3InstantiateCoSimulation",
                log: std::mem::take(&mut store.data_mut().log),
            })?;
        Ok(WasmInstance { store, world, handle, kind: Kind::Cs })
    }

    /// Run the model's own simulation runtime inside the artifact (`om:sim/run`).
    /// `args` are the runtime flags a simulation executable would be given.
    pub fn run_simulation(&self, args: &[String]) -> Result<SimRun> {
        let (mut store, world) = self.instantiate()?;
        let out = world
            .om_sim_simulation()
            .call_run(&mut store, args)
            .map_err(|e| trap("om:sim/simulation.run", e))?
            .map_err(Error::Simulation)?;
        Ok(SimRun {
            file: out.file,
            linear_file: out.linear_file,
            prof_files: out.prof_files,
            prof_html: out.prof_html,
            rows: out.rows,
            solver: out.solver,
            log: std::mem::take(&mut store.data_mut().log),
            output: stdout_of(&store),
        })
    }

    /// What `fmi3Instantiate*` is told its resources are. The component's own
    /// root, since the preopen above is what it reaches them through.
    fn resource_path(&self) -> String {
        if self.resources.lock().unwrap_or_else(|e| e.into_inner()).is_some() {
            "/".to_string()
        } else {
            String::new()
        }
    }
}

/// What the artifact's own simulation runtime produced.
pub struct SimRun {
    /// The result file's bytes, empty when the run was asked to emit none.
    pub file: Vec<u8>,
    /// `-l`'s linearized model: its file name and content.
    pub linear_file: Option<(String, String)>,
    /// `+profiling`'s report files, each as a name and its content.
    pub prof_files: Vec<(String, Vec<u8>)>,
    /// The report asked for gnuplot + xsltproc (`+profiling=...+html`).
    pub prof_html: bool,
    pub rows: u32,
    /// The integration method the run actually used.
    pub solver: String,
    pub log: Vec<(Status, String, String)>,
    /// What the run printed: the `-lv` streams and the model's own `print`.
    pub output: String,
}

fn stdout_of(store: &Store<Host>) -> String {
    String::from_utf8_lossy(&store.data().stdout.contents()).into_owned()
}

enum Kind {
    Me,
    Cs,
}

/// One instantiated FMI interface of an artifact.
pub struct WasmInstance {
    store: Store<Host>,
    world: bindings::ModelExchangeAndCoSimulationFmu,
    handle: ResourceAny,
    kind: Kind,
}

impl WasmInstance {
    fn me(&mut self) -> (&mut Store<Host>, GuestModelExchangeInstance<'_>, ResourceAny) {
        let WasmInstance { store, world, handle, .. } = self;
        (store, world.fmi_fmi3_model_exchange().model_exchange_instance(), *handle)
    }
    fn cs(&mut self) -> (&mut Store<Host>, GuestCoSimulationInstance<'_>, ResourceAny) {
        let WasmInstance { store, world, handle, .. } = self;
        (store, world.fmi_fmi3_co_simulation().co_simulation_instance(), *handle)
    }
}

/// The common interface is declared on both resources with identical shapes; the
/// arms are textually the same and resolve to different generated types.
macro_rules! common {
    ($self:ident, |$store:ident, $g:ident, $h:ident| $body:expr) => {
        match $self.kind {
            Kind::Me => {
                let ($store, $g, $h) = $self.me();
                $body
            }
            Kind::Cs => {
                let ($store, $g, $h) = $self.cs();
                $body
            }
        }
    };
}

/// One `fmi3Get*` family member, widened to `f64` for the recorder.
macro_rules! get_numeric {
    ($store:ident, $g:ident, $h:ident, $call:ident, $name:literal, $vrs:expr, $values:expr) => {{
        let got = unwrap($name, $g.$call($store, $h, $vrs).map_err(|e| trap($name, e))?)?;
        for (o, v) in $values.iter_mut().zip(&got) {
            *o = *v as f64;
        }
        Ok(())
    }};
}

macro_rules! set_numeric {
    ($store:ident, $g:ident, $h:ident, $call:ident, $name:literal, $ty:ty, $vrs:expr, $values:expr) => {{
        let buf: Vec<$ty> = $values.iter().map(|v| *v as $ty).collect();
        check($name, $g.$call($store, $h, $vrs, &buf).map_err(|e| trap($name, e))?)
    }};
}

impl Fmi3 for WasmInstance {
    fn get_version(&mut self) -> String {
        let WasmInstance { store, world, .. } = self;
        world.fmi_fmi3_common().call_get_version(store).unwrap_or_else(|_| "3.0".to_string())
    }

    fn enter_initialization_mode(
        &mut self,
        tolerance: Option<f64>,
        start_time: f64,
        stop_time: Option<f64>,
    ) -> Result<()> {
        common!(self, |store, g, h| check(
            "fmi3EnterInitializationMode",
            g.call_enter_initialization_mode(store, h, tolerance, start_time, stop_time)
                .map_err(|e| trap("fmi3EnterInitializationMode", e))?
        ))
    }

    fn exit_initialization_mode(&mut self) -> Result<()> {
        common!(self, |store, g, h| check(
            "fmi3ExitInitializationMode",
            g.call_exit_initialization_mode(store, h)
                .map_err(|e| trap("fmi3ExitInitializationMode", e))?
        ))
    }

    fn enter_event_mode(&mut self) -> Result<()> {
        common!(self, |store, g, h| check(
            "fmi3EnterEventMode",
            g.call_enter_event_mode(store, h).map_err(|e| trap("fmi3EnterEventMode", e))?
        ))
    }

    fn update_discrete_states(&mut self) -> Result<DiscreteStates> {
        let info = common!(self, |store, g, h| unwrap(
            "fmi3UpdateDiscreteStates",
            g.call_update_discrete_states(store, h)
                .map_err(|e| trap("fmi3UpdateDiscreteStates", e))?
        ))?;
        Ok(DiscreteStates {
            need_update: info.new_discrete_states_needed,
            terminate: info.terminate_simulation,
            nominals_changed: info.nominals_of_continuous_states_changed,
            states_changed: info.values_of_continuous_states_changed,
            next_event_time: info.next_event_time_defined.then_some(info.next_event_time),
        })
    }

    fn terminate(&mut self) -> Result<()> {
        common!(self, |store, g, h| check(
            "fmi3Terminate",
            g.call_terminate(store, h).map_err(|e| trap("fmi3Terminate", e))?
        ))
    }

    fn enter_configuration_mode(&mut self) -> Result<()> {
        common!(self, |store, g, h| check(
            "fmi3EnterConfigurationMode",
            g.call_enter_configuration_mode(store, h).map_err(|e| trap("fmi3EnterConfigurationMode", e))?
        ))
    }

    fn exit_configuration_mode(&mut self) -> Result<()> {
        common!(self, |store, g, h| check(
            "fmi3ExitConfigurationMode",
            g.call_exit_configuration_mode(store, h).map_err(|e| trap("fmi3ExitConfigurationMode", e))?
        ))
    }

    fn get_numeric(&mut self, ty: VarType, vrs: &[u32], values: &mut [f64]) -> Result<()> {
        match ty.wire() {
            VarType::Float64 => {
                common!(self, |store, g, h| get_numeric!(store, g, h, call_get_float64, "fmi3GetFloat64", vrs, values))
            }
            VarType::Float32 => {
                common!(self, |store, g, h| get_numeric!(store, g, h, call_get_float32, "fmi3GetFloat32", vrs, values))
            }
            VarType::Int8 => common!(self, |store, g, h| get_numeric!(store, g, h, call_get_int8, "fmi3GetInt8", vrs, values)),
            VarType::UInt8 => common!(self, |store, g, h| get_numeric!(store, g, h, call_get_uint8, "fmi3GetUInt8", vrs, values)),
            VarType::Int16 => common!(self, |store, g, h| get_numeric!(store, g, h, call_get_int16, "fmi3GetInt16", vrs, values)),
            VarType::UInt16 => common!(self, |store, g, h| get_numeric!(store, g, h, call_get_uint16, "fmi3GetUInt16", vrs, values)),
            VarType::Int32 => common!(self, |store, g, h| get_numeric!(store, g, h, call_get_int32, "fmi3GetInt32", vrs, values)),
            VarType::UInt32 => common!(self, |store, g, h| get_numeric!(store, g, h, call_get_uint32, "fmi3GetUInt32", vrs, values)),
            VarType::Int64 => common!(self, |store, g, h| get_numeric!(store, g, h, call_get_int64, "fmi3GetInt64", vrs, values)),
            VarType::UInt64 => common!(self, |store, g, h| get_numeric!(store, g, h, call_get_uint64, "fmi3GetUInt64", vrs, values)),
            VarType::Boolean => {
                let got = common!(self, |store, g, h| unwrap(
                    "fmi3GetBoolean",
                    g.call_get_boolean(store, h, vrs).map_err(|e| trap("fmi3GetBoolean", e))?
                ))?;
                for (o, v) in values.iter_mut().zip(&got) {
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
                common!(self, |store, g, h| check(
                    "fmi3SetFloat64",
                    g.call_set_float64(store, h, vrs, values).map_err(|e| trap("fmi3SetFloat64", e))?
                ))
            }
            VarType::Float32 => common!(self, |store, g, h| set_numeric!(store, g, h, call_set_float32, "fmi3SetFloat32", f32, vrs, values)),
            VarType::Int8 => common!(self, |store, g, h| set_numeric!(store, g, h, call_set_int8, "fmi3SetInt8", i8, vrs, values)),
            VarType::UInt8 => common!(self, |store, g, h| set_numeric!(store, g, h, call_set_uint8, "fmi3SetUInt8", u8, vrs, values)),
            VarType::Int16 => common!(self, |store, g, h| set_numeric!(store, g, h, call_set_int16, "fmi3SetInt16", i16, vrs, values)),
            VarType::UInt16 => common!(self, |store, g, h| set_numeric!(store, g, h, call_set_uint16, "fmi3SetUInt16", u16, vrs, values)),
            VarType::Int32 => common!(self, |store, g, h| set_numeric!(store, g, h, call_set_int32, "fmi3SetInt32", i32, vrs, values)),
            VarType::UInt32 => common!(self, |store, g, h| set_numeric!(store, g, h, call_set_uint32, "fmi3SetUInt32", u32, vrs, values)),
            VarType::Int64 => common!(self, |store, g, h| set_numeric!(store, g, h, call_set_int64, "fmi3SetInt64", i64, vrs, values)),
            VarType::UInt64 => common!(self, |store, g, h| set_numeric!(store, g, h, call_set_uint64, "fmi3SetUInt64", u64, vrs, values)),
            VarType::Boolean => {
                let buf: Vec<bool> = values.iter().map(|v| *v != 0.0).collect();
                common!(self, |store, g, h| check(
                    "fmi3SetBoolean",
                    g.call_set_boolean(store, h, vrs, &buf).map_err(|e| trap("fmi3SetBoolean", e))?
                ))
            }
            ty => Err(Error::Unsupported(format!("writing a {} as a number", ty.as_str()))),
        }
    }

    fn get_string(&mut self, vrs: &[u32]) -> Result<Vec<String>> {
        common!(self, |store, g, h| unwrap(
            "fmi3GetString",
            g.call_get_string(store, h, vrs).map_err(|e| trap("fmi3GetString", e))?
        ))
    }

    fn set_string(&mut self, vrs: &[u32], values: &[&str]) -> Result<()> {
        let owned: Vec<String> = values.iter().map(|s| (*s).to_string()).collect();
        common!(self, |store, g, h| check(
            "fmi3SetString",
            g.call_set_string(store, h, vrs, &owned).map_err(|e| trap("fmi3SetString", e))?
        ))
    }

    fn take_log(&mut self) -> Vec<(Status, String, String)> {
        std::mem::take(&mut self.store.data_mut().log)
    }
}

impl WasmInstance {
    /// What the FMU has printed: its simulation log, which C's FMU sends to the
    /// importer's stdout.
    pub fn output(&self) -> String {
        stdout_of(&self.store)
    }
}

impl Fmi3ModelExchange for WasmInstance {
    fn enter_continuous_time_mode(&mut self) -> Result<()> {
        let (store, g, h) = self.me();
        check(
            "fmi3EnterContinuousTimeMode",
            g.call_enter_continuous_time_mode(store, h)
                .map_err(|e| trap("fmi3EnterContinuousTimeMode", e))?,
        )
    }

    fn set_time(&mut self, time: f64) -> Result<()> {
        let (store, g, h) = self.me();
        check("fmi3SetTime", g.call_set_time(store, h, time).map_err(|e| trap("fmi3SetTime", e))?)
    }

    fn set_continuous_states(&mut self, states: &[f64]) -> Result<()> {
        let (store, g, h) = self.me();
        check(
            "fmi3SetContinuousStates",
            g.call_set_continuous_states(store, h, states)
                .map_err(|e| trap("fmi3SetContinuousStates", e))?,
        )
    }

    fn get_continuous_states(&mut self, states: &mut [f64]) -> Result<()> {
        let (store, g, h) = self.me();
        let got = unwrap(
            "fmi3GetContinuousStates",
            g.call_get_continuous_states(store, h).map_err(|e| trap("fmi3GetContinuousStates", e))?,
        )?;
        states.copy_from_slice(&got[..states.len().min(got.len())]);
        Ok(())
    }

    fn get_continuous_state_derivatives(&mut self, ders: &mut [f64]) -> Result<()> {
        let (store, g, h) = self.me();
        let got = unwrap(
            "fmi3GetContinuousStateDerivatives",
            g.call_get_continuous_state_derivatives(store, h)
                .map_err(|e| trap("fmi3GetContinuousStateDerivatives", e))?,
        )?;
        ders.copy_from_slice(&got[..ders.len().min(got.len())]);
        Ok(())
    }

    fn get_event_indicators(&mut self, indicators: &mut [f64]) -> Result<()> {
        let (store, g, h) = self.me();
        let got = unwrap(
            "fmi3GetEventIndicators",
            g.call_get_event_indicators(store, h).map_err(|e| trap("fmi3GetEventIndicators", e))?,
        )?;
        indicators.copy_from_slice(&got[..indicators.len().min(got.len())]);
        Ok(())
    }

    fn get_nominals_of_continuous_states(&mut self, nominals: &mut [f64]) -> Result<()> {
        let (store, g, h) = self.me();
        let got = unwrap(
            "fmi3GetNominalsOfContinuousStates",
            g.call_get_nominals_of_continuous_states(store, h)
                .map_err(|e| trap("fmi3GetNominalsOfContinuousStates", e))?,
        )?;
        nominals.copy_from_slice(&got[..nominals.len().min(got.len())]);
        Ok(())
    }

    fn completed_integrator_step(&mut self, no_set_state_prior: bool) -> Result<CompletedStep> {
        let (store, g, h) = self.me();
        let r = unwrap(
            "fmi3CompletedIntegratorStep",
            g.call_completed_integrator_step(store, h, no_set_state_prior)
                .map_err(|e| trap("fmi3CompletedIntegratorStep", e))?,
        )?;
        Ok(CompletedStep { enter_event_mode: r.enter_event_mode, terminate: r.terminate_simulation })
    }

    fn get_directional_derivative(
        &mut self,
        unknowns: &[u32],
        knowns: &[u32],
        seed: &[f64],
        sensitivity: &mut [f64],
    ) -> Result<()> {
        let (store, g, h) = self.me();
        let got = unwrap(
            "fmi3GetDirectionalDerivative",
            g.call_get_directional_derivative(store, h, unknowns, knowns, seed)
                .map_err(|e| trap("fmi3GetDirectionalDerivative", e))?,
        )?;
        sensitivity.copy_from_slice(&got[..sensitivity.len().min(got.len())]);
        Ok(())
    }

    fn get_number_of_continuous_states(&mut self) -> Result<usize> {
        let (store, g, h) = self.me();
        Ok(unwrap(
            "fmi3GetNumberOfContinuousStates",
            g.call_get_number_of_continuous_states(store, h)
                .map_err(|e| trap("fmi3GetNumberOfContinuousStates", e))?,
        )? as usize)
    }

    fn get_number_of_event_indicators(&mut self) -> Result<usize> {
        let (store, g, h) = self.me();
        Ok(unwrap(
            "fmi3GetNumberOfEventIndicators",
            g.call_get_number_of_event_indicators(store, h)
                .map_err(|e| trap("fmi3GetNumberOfEventIndicators", e))?,
        )? as usize)
    }
}

impl Fmi3CoSimulation for WasmInstance {
    fn enter_step_mode(&mut self) -> Result<()> {
        let (store, g, h) = self.cs();
        check("fmi3EnterStepMode", g.call_enter_step_mode(store, h).map_err(|e| trap("fmi3EnterStepMode", e))?)
    }

    fn do_step(&mut self, point: f64, size: f64, no_set_state_prior: bool) -> Result<DoStep> {
        let (store, g, h) = self.cs();
        let r = unwrap(
            "fmi3DoStep",
            g.call_do_step(store, h, point, size, no_set_state_prior).map_err(|e| trap("fmi3DoStep", e))?,
        )?;
        Ok(DoStep {
            event_handling_needed: r.event_handling_needed,
            terminate: r.terminate_simulation,
            early_return: r.early_return,
            last_successful_time: r.last_successful_time,
        })
    }
}
