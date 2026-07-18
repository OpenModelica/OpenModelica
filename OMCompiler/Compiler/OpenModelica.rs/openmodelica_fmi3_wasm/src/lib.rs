//! Model-agnostic FMI 3.0 Model-Exchange adapter.
//!
//! Compiled once to a `wasm32-unknown-unknown` dylink side module, then linked
//! (`wit_component::Linker`, see `CodegenWasmJit::link_fmu_component`) with a
//! per-model kernel module into an `fmi:fmi3/model-exchange-fmu` component. It
//! drives the model over the shared `SimData` linear-memory block, calling the
//! model's exported equation functions.
//!
//! Value references are `CodegenFMU3`'s (the same ones in the FMU's
//! `modelDescription.xml`); the emitter embeds the vr -> `SimData` slot table in
//! the metadata blob, since that scheme cannot be derived from the layout.
//!
//! The runtime is linked in only for the shared dlmalloc allocator + `rt_*`
//! primitives + linear memory: one heap for both the model's `rt_alloc` and
//! wit-bindgen's `cabi_realloc`.

#![no_std]

extern crate alloc;
// Linked in for its allocator, panic handler, memory and `rt_*` exports, which
// also satisfy the model's `env` imports.
extern crate openmodelica_codegen_wasm_jit_runtime;

use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;
use core::cell::RefCell;

use openmodelica_sim_meta::driver::{
    self, event_update, run_initialization, set_param_overrides, set_zc_tolerance, Samples,
    SimEngine,
};
#[cfg(feature = "cs")]
use openmodelica_sim_meta::driver::{CsDriver, CsStep};
use openmodelica_sim_meta::{decode, FmiVr, Layout, WTy, REAL_OFF, TIME_OFF};

// ── Model kernel imports ─────────────────────────────────────────────────────
// `env` is the dylink convention: the Linker resolves these against the model
// library's exports, and the model's `rt_*` + memory against this adapter's.
#[link(wasm_import_module = "env")]
unsafe extern "C" {
    fn functionParameters(sim_data: u32);
    fn functionInitStartValues(sim_data: u32);
    fn functionInitialEquations(sim_data: u32);
    fn functionInitialEquations_lambda0(sim_data: u32);
    fn functionODE(sim_data: u32);
    fn functionAlgebraics(sim_data: u32);
    fn functionStateSetJacobians(sim_data: u32);
    fn functionZeroCrossings(sim_data: u32);
    fn initSample(sim_data: u32);
    fn callExternalObjectDestructors(sim_data: u32);
    fn om_meta_ptr() -> u32;
    fn om_meta_len() -> u32;
}

/// The runtime leaves `rt_assert` to the host on this target. A failed assertion
/// traps, aborting the FMI call; the master surfaces it as a fatal status.
#[unsafe(no_mangle)]
pub extern "C" fn rt_assert(
    _msg: i32,
    _file: i32,
    _sline: i32,
    _scol: i32,
    _eline: i32,
    _ecol: i32,
    _read_only: i32,
) {
    core::arch::wasm32::unreachable()
}

// ── SimEngine over the merged module's shared linear memory ──────────────────
struct Engine;

impl SimEngine for Engine {
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> driver::Result<()> {
        let src = unsafe { core::slice::from_raw_parts(addr as *const u8, buf.len()) };
        buf.copy_from_slice(src);
        Ok(())
    }
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> driver::Result<()> {
        let dst = unsafe { core::slice::from_raw_parts_mut(addr as *mut u8, buf.len()) };
        dst.copy_from_slice(buf);
        Ok(())
    }
    fn call1(&mut self, name: &str, arg: u32) -> driver::Result<()> {
        unsafe {
            match name {
                "functionParameters" => functionParameters(arg),
                "functionInitStartValues" => functionInitStartValues(arg),
                "functionInitialEquations" => functionInitialEquations(arg),
                "functionInitialEquations_lambda0" => functionInitialEquations_lambda0(arg),
                "functionODE" => functionODE(arg),
                "functionAlgebraics" => functionAlgebraics(arg),
                "functionStateSetJacobians" => functionStateSetJacobians(arg),
                "functionZeroCrossings" => functionZeroCrossings(arg),
                "initSample" => initSample(arg),
                "callExternalObjectDestructors" => callExternalObjectDestructors(arg),
                _ => return Err("fmi3-me: unknown model function"),
            }
        }
        Ok(())
    }
    fn call1_if_present(&mut self, name: &str, arg: u32) -> driver::Result<()> {
        self.call1(name, arg)
    }
    fn call_simulate(&mut self, _s: u32, _a: f64, _b: f64, _n: u32) -> driver::Result<u32> {
        Err("fmi3-me: simulate not used")
    }
    fn take_pending_assert(&mut self) -> Option<[i32; 7]> {
        None
    }
}

// ── Value references ─────────────────────────────────────────────────────────
/// vr -> `SimData` slot, agreeing with the `modelDescription.xml` `CodegenFMU3`
/// generated for this FMU. The blob carries the table sorted; instantiation
/// expands it into a direct index, the value references being dense.
struct Vrs {
    by_vr: Vec<Option<FmiVr>>,
}

impl Vrs {
    fn new(table: Vec<FmiVr>) -> Self {
        let max = table.last().map_or(0, |e| e.vr as usize);
        let mut by_vr = vec![None; max + 1];
        for e in table {
            by_vr[e.vr as usize] = Some(e);
        }
        Vrs { by_vr }
    }

    /// `None` for a vr with no `SimData` slot (a String, an external object).
    fn resolve(&self, vr: u32) -> Option<FmiVr> {
        *self.by_vr.get(vr as usize)?
    }
}

// ── Instance state ───────────────────────────────────────────────────────────
struct MeState {
    sim_data: u32,
    layout: Layout,
    /// The whole metadata blob: CS needs the solver settings, the state sets and
    /// the Jacobian sparsity to build its driver, not just the layout.
    #[cfg(feature = "cs")]
    meta: openmodelica_sim_meta::SimMeta,
    /// Built on exit-initialization-mode, once the model is initialized.
    #[cfg(feature = "cs")]
    cs: Option<CsDriver>,
    /// `eventModeUsed` from instantiation: `do-step` stops at and reports each event
    /// for the master, rather than handling it internally.
    #[cfg(feature = "cs")]
    event_mode: bool,
    vrs: Vrs,
    in_init: bool,
    /// Set during Initialization Mode, applied by `run_initialization`: states as
    /// start overrides (see `FmiVr::start_off`), everything else as parameters.
    init_overrides: Vec<(u32, WTy, f64)>,
    init_start_overrides: Vec<(u32, WTy, f64)>,
    /// String parameter sets from Initialization Mode, applied after
    /// `run_initialization` so init equations don't clobber them (cf `init_overrides`).
    init_string_overrides: Vec<(u32, String)>,
    /// Sample schedule, loaded once the model's `initSample` has run.
    samples: Option<Samples>,
}

impl MeState {
    fn read_f64(&self, off: u32) -> f64 {
        driver::read_f64(&Engine, self.sim_data + off).unwrap_or(0.0)
    }
    fn write_f64(&self, off: u32, v: f64) {
        let mut e = Engine;
        let _ = driver::write_f64(&mut e, self.sim_data + off, v);
    }
    fn read_i32(&self, off: u32) -> i32 {
        driver::read_i32(&Engine, self.sim_data + off).unwrap_or(0)
    }
    fn write_i32(&self, off: u32, v: i32) {
        let mut e = Engine;
        let _ = e.write_bytes(self.sim_data + off, &v.to_le_bytes());
    }
    /// Read the runtime `String` referenced by the i32 handle in slot `off`. Empty
    /// for the null handle (an unset String).
    fn read_string(&self, off: u32) -> String {
        use openmodelica_codegen_wasm_jit_runtime as rt;
        let h = self.read_i32(off) as u32;
        if h == 0 {
            return String::new();
        }
        let len = rt::rt_str_len(h) as usize;
        let bytes = unsafe { core::slice::from_raw_parts(rt::rt_str_data(h) as *const u8, len) };
        String::from_utf8_lossy(bytes).into_owned()
    }
    /// Store `s` as a fresh runtime `String` handle in slot `off`, releasing the
    /// handle it replaces (a no-op on the null handle).
    fn write_string(&self, off: u32, s: &str) {
        use openmodelica_codegen_wasm_jit_runtime as rt;
        let old = self.read_i32(off) as u32;
        let bytes = s.as_bytes();
        let h = rt::rt_str_new(bytes.len() as u32);
        unsafe {
            core::ptr::copy_nonoverlapping(bytes.as_ptr(), rt::rt_str_data(h) as *mut u8, bytes.len());
        }
        self.write_i32(off, h as i32);
        rt::rt_release(old);
    }
    /// Refresh algebraics/derivatives so getters report consistent values.
    fn eval(&self) {
        let mut e = Engine;
        let _ = e.call1("functionODE", self.sim_data);
        if !self.layout.has_when {
            let _ = e.call1("functionAlgebraics", self.sim_data);
        }
    }
}

// ── WIT bindings ────────────────────────────────────────────────────────────
// One crate, three FMU types selected by the `me`/`cs` features: `me` → Model
// Exchange, `cs` → Co-Simulation, both → a single me_cs component. All builds
// share the state, the vr table and the 54 common resource methods.
#[cfg(all(feature = "me", not(feature = "cs")))]
wit_bindgen::generate!({
    world: "model-exchange-fmu",
    path: "wit",
    std_feature,
});
#[cfg(all(feature = "cs", not(feature = "me")))]
wit_bindgen::generate!({
    world: "co-simulation-fmu",
    path: "wit",
    std_feature,
});
#[cfg(all(feature = "me", feature = "cs"))]
wit_bindgen::generate!({
    world: "model-exchange-and-co-simulation-fmu",
    path: "wit",
    std_feature,
});

use exports::fmi::fmi3::common::Guest as CommonGuest;
#[cfg(feature = "me")]
use exports::fmi::fmi3::model_exchange::{
    CompletedStepResult, Guest as MeGuest, GuestModelExchangeInstance, ModelExchangeInstance,
};
#[cfg(feature = "cs")]
use exports::fmi::fmi3::co_simulation::{
    CoSimulationInstance, DoStepResult, Guest as CsGuest, GuestCoSimulationInstance,
};
// The shared types (`use types.{…}` in both interfaces) are one type; import them
// from whichever interface this build exports, preferring model-exchange.
#[cfg(feature = "me")]
use exports::fmi::fmi3::model_exchange::{
    DiscreteStatesInfo, IntervalFraction, IntervalQualifier, Status, VariableDependency,
};
#[cfg(all(feature = "cs", not(feature = "me")))]
use exports::fmi::fmi3::co_simulation::{
    DiscreteStatesInfo, IntervalFraction, IntervalQualifier, Status, VariableDependency,
};

pub struct Instance {
    st: RefCell<MeState>,
}

/// Allocate and zero the model's `SimData` and build the instance state. Shared by
/// both worlds' instantiate.
fn new_state() -> Option<MeState> {
    #[allow(unused_mut)]
    let mut meta = read_meta();
    let layout = meta.layout;
    if layout.total == 0 {
        return None;
    }
    let sim_data = openmodelica_codegen_wasm_jit_runtime::rt_alloc(layout.total);
    // rt_alloc leaves the block uninitialised; zero it so unset slots read 0.
    unsafe {
        core::ptr::write_bytes(sim_data as *mut u8, 0, layout.total as usize);
    }
    Some(MeState {
        sim_data,
        layout,
        vrs: Vrs::new(core::mem::take(&mut meta.fmi_vrs)),
        #[cfg(feature = "cs")]
        meta,
        #[cfg(feature = "cs")]
        cs: None,
        #[cfg(feature = "cs")]
        event_mode: false,
        in_init: false,
        init_overrides: Vec::new(),
        init_start_overrides: Vec::new(),
        init_string_overrides: Vec::new(),
        samples: None,
    })
}

/// The metadata blob the emitter embedded in the model module.
fn read_meta() -> openmodelica_sim_meta::SimMeta {
    let ptr = unsafe { om_meta_ptr() };
    let len = unsafe { om_meta_len() } as usize;
    let bytes = unsafe { core::slice::from_raw_parts(ptr as *const u8, len) };
    decode(bytes).unwrap_or_default()
}

/// The 54 methods both resources share (`co-simulation-instance` and
/// `model-exchange-instance` declare the same getters/setters and mode
/// transitions). One body, expanded into whichever guest trait this build's world
/// generated.
macro_rules! shared_instance_methods {
    () => {

    fn set_debug_logging(&self, _logging_on: bool, _categories: Vec<String>) -> Status {
        Status::Ok
    }

    fn enter_initialization_mode(
        &self,
        tolerance: Option<f64>,
        start_time: f64,
        _stop_time: Option<f64>,
    ) -> Status {
        let mut st = self.st.borrow_mut();
        st.in_init = true;
        st.init_overrides.clear();
        st.init_start_overrides.clear();
        st.write_f64(TIME_OFF, start_time);
        let (sim_data, layout) = (st.sim_data, st.layout);
        let mut e = Engine;
        match set_zc_tolerance(&mut e, sim_data, &layout, tolerance.unwrap_or(0.0)) {
            Ok(()) => Status::Ok,
            Err(_) => Status::Error,
        }
    }

    fn exit_initialization_mode(&self) -> Status {
        let mut st = self.st.borrow_mut();
        st.in_init = false;
        let params = core::mem::take(&mut st.init_overrides);
        let starts = core::mem::take(&mut st.init_start_overrides);
        set_param_overrides(params, starts);
        let mut e = Engine;
        if run_initialization(&mut e, st.sim_data, &st.layout).is_err() {
            return Status::Error;
        }
        // Apply deferred String parameter sets now that init equations have run, so
        // they land in the slots last (mirrors the numeric init_overrides above).
        for (off, val) in core::mem::take(&mut st.init_string_overrides) {
            st.write_string(off, &val);
        }
        // `run_initialization` has run `initSample`, so the schedule is readable.
        if st.layout.n_samples > 0 {
            match Samples::load(&Engine, st.sim_data, &st.layout) {
                Ok(s) => st.samples = Some(s),
                Err(_) => return Status::Error,
            }
        }
        // The CS driver is built lazily on the first `do-step` (see there): a me_cs
        // component driven in Model Exchange must not pay for — or be perturbed by —
        // a driver it never uses. Event Mode is the exception: the master's first
        // action after init is an event iteration (`update-discrete-states`), which
        // must run through the driver's sample schedule, so build it eagerly.
        #[cfg(feature = "cs")]
        if st.event_mode {
            let (sim_data, t) = (st.sim_data, st.read_f64(TIME_OFF));
            let meta = st.meta.clone();
            match CsDriver::new(&mut e, &meta, sim_data, t) {
                Ok(d) => st.cs = Some(d),
                Err(_) => return Status::Error,
            }
        }
        Status::Ok
    }

    fn enter_event_mode(&self) -> Status {
        Status::Ok
    }

    /// The master has located the event and set time/states; run the discrete
    /// update here. `iterate_discrete` already runs to a fixed point, so one pass
    /// always suffices and `new-discrete-states-needed` stays false.
    fn update_discrete_states(&self) -> Result<DiscreteStatesInfo, Status> {
        let mut st = self.st.borrow_mut();
        let (sim_data, layout) = (st.sim_data, st.layout);
        let time = st.read_f64(TIME_OFF);
        let mut e = Engine;

        #[cfg(feature = "cs")]
        let up = if st.event_mode {
            // Route through the driver so its sample schedule advances in step with
            // the integrator (see `CsDriver::do_event_update`).
            let meta = st.meta.clone();
            let mut d = st.cs.take().ok_or(Status::Error)?;
            let r = d.do_event_update(&mut e, &meta, time);
            st.cs = Some(d);
            match r {
                Ok(up) => up,
                Err(_) => return Err(Status::Error),
            }
        } else {
            match event_update(&mut e, sim_data, &layout, st.samples.as_mut(), time) {
                Ok(up) => up,
                Err(_) => return Err(Status::Error),
            }
        };
        #[cfg(not(feature = "cs"))]
        let up = match event_update(&mut e, sim_data, &layout, st.samples.as_mut(), time) {
            Ok(up) => up,
            Err(_) => return Err(Status::Error),
        };

        Ok(DiscreteStatesInfo {
            new_discrete_states_needed: false,
            terminate_simulation: up.terminate,
            nominals_of_continuous_states_changed: false,
            values_of_continuous_states_changed: up.states_changed,
            next_event_time_defined: up.next_event_time.is_some(),
            next_event_time: up.next_event_time.unwrap_or(0.0),
        })
    }

    fn terminate(&self) -> Status {
        let st = self.st.borrow();
        let mut e = Engine;
        let _ = e.call1_if_present("callExternalObjectDestructors", st.sim_data);
        Status::Ok
    }

    fn reset(&self) -> Status {
        let st = self.st.borrow();
        unsafe {
            core::ptr::write_bytes(st.sim_data as *mut u8, 0, st.layout.total as usize);
        }
        Status::Ok
    }

    fn enter_configuration_mode(&self) -> Status {
        Status::Error
    }
    fn exit_configuration_mode(&self) -> Status {
        Status::Error
    }

    // ── Getters ───────────────────────────────────────────────────────────────
    fn get_float32(&self, _: Vec<u32>) -> Result<Vec<f32>, Status> {
        Err(Status::Error)
    }
    fn get_float64(&self, vrs: Vec<u32>) -> Result<Vec<f64>, Status> {
        let st = self.st.borrow();
        st.eval();
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::F64 => {
                    let v = st.read_f64(e.off);
                    out.push(if e.negate { -v } else { v });
                }
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    fn get_int8(&self, _: Vec<u32>) -> Result<Vec<i8>, Status> {
        Err(Status::Error)
    }
    fn get_int16(&self, _: Vec<u32>) -> Result<Vec<i16>, Status> {
        Err(Status::Error)
    }
    fn get_int32(&self, vrs: Vec<u32>) -> Result<Vec<i32>, Status> {
        let st = self.st.borrow();
        st.eval();
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.is_string => {
                    let v = st.read_i32(e.off);
                    out.push(if e.negate { -v } else { v });
                }
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    // fmi3 accesses `<Enumeration>` vars via Int64; they are `WTy::I32` slots here,
    // so widen/narrow around the i32.
    fn get_int64(&self, vrs: Vec<u32>) -> Result<Vec<i64>, Status> {
        let st = self.st.borrow();
        st.eval();
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.is_string => {
                    let v = st.read_i32(e.off);
                    out.push((if e.negate { -v } else { v }) as i64);
                }
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    fn get_uint8(&self, _: Vec<u32>) -> Result<Vec<u8>, Status> {
        Err(Status::Error)
    }
    fn get_uint16(&self, _: Vec<u32>) -> Result<Vec<u16>, Status> {
        Err(Status::Error)
    }
    fn get_uint32(&self, _: Vec<u32>) -> Result<Vec<u32>, Status> {
        Err(Status::Error)
    }
    fn get_uint64(&self, vrs: Vec<u32>) -> Result<Vec<u64>, Status> {
        let st = self.st.borrow();
        st.eval();
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.is_string => out.push(st.read_i32(e.off) as u64),
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    fn get_boolean(&self, vrs: Vec<u32>) -> Result<Vec<bool>, Status> {
        let st = self.st.borrow();
        st.eval();
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.is_string => out.push(st.read_i32(e.off) != 0),
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    fn get_string(&self, vrs: Vec<u32>) -> Result<Vec<String>, Status> {
        let st = self.st.borrow();
        let mut out = Vec::with_capacity(vrs.len());
        for vr in vrs {
            match st.vrs.resolve(vr) {
                Some(e) if e.is_string => out.push(st.read_string(e.off)),
                _ => return Err(Status::Error),
            }
        }
        Ok(out)
    }
    fn get_binary(&self, _: Vec<u32>) -> Result<Vec<Vec<u8>>, Status> {
        Err(Status::Error)
    }
    fn get_clock(&self, _: Vec<u32>) -> Result<Vec<bool>, Status> {
        Err(Status::Error)
    }

    // ── Setters ───────────────────────────────────────────────────────────────
    fn set_float32(&self, _: Vec<u32>, _: Vec<f32>) -> Status {
        Status::Error
    }
    fn set_float64(&self, vrs: Vec<u32>, values: Vec<f64>) -> Status {
        if vrs.len() != values.len() {
            return Status::Error;
        }
        let mut st = self.st.borrow_mut();
        for (vr, v) in vrs.into_iter().zip(values) {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::F64 && !e.negate => {
                    if st.in_init && e.start_off != 0 {
                        st.init_start_overrides.push((e.start_off, WTy::F64, v));
                    } else if st.in_init {
                        st.init_overrides.push((e.off, WTy::F64, v));
                    } else {
                        st.write_f64(e.off, v);
                    }
                }
                _ => return Status::Error,
            }
        }
        Status::Ok
    }
    fn set_int8(&self, _: Vec<u32>, _: Vec<i8>) -> Status {
        Status::Error
    }
    fn set_int16(&self, _: Vec<u32>, _: Vec<i16>) -> Status {
        Status::Error
    }
    fn set_int32(&self, vrs: Vec<u32>, values: Vec<i32>) -> Status {
        if vrs.len() != values.len() {
            return Status::Error;
        }
        let mut st = self.st.borrow_mut();
        for (vr, v) in vrs.into_iter().zip(values) {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.negate && !e.is_string => {
                    if st.in_init {
                        st.init_overrides.push((e.off, WTy::I32, v as f64));
                    } else {
                        st.write_i32(e.off, v);
                    }
                }
                _ => return Status::Error,
            }
        }
        Status::Ok
    }
    fn set_int64(&self, vrs: Vec<u32>, values: Vec<i64>) -> Status {
        if vrs.len() != values.len() {
            return Status::Error;
        }
        let mut st = self.st.borrow_mut();
        for (vr, v) in vrs.into_iter().zip(values) {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.negate && !e.is_string => {
                    if st.in_init {
                        st.init_overrides.push((e.off, WTy::I32, v as f64));
                    } else {
                        st.write_i32(e.off, v as i32);
                    }
                }
                _ => return Status::Error,
            }
        }
        Status::Ok
    }
    fn set_uint8(&self, _: Vec<u32>, _: Vec<u8>) -> Status {
        Status::Error
    }
    fn set_uint16(&self, _: Vec<u32>, _: Vec<u16>) -> Status {
        Status::Error
    }
    fn set_uint32(&self, _: Vec<u32>, _: Vec<u32>) -> Status {
        Status::Error
    }
    fn set_uint64(&self, vrs: Vec<u32>, values: Vec<u64>) -> Status {
        if vrs.len() != values.len() {
            return Status::Error;
        }
        let mut st = self.st.borrow_mut();
        for (vr, v) in vrs.into_iter().zip(values) {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.negate && !e.is_string => {
                    if st.in_init {
                        st.init_overrides.push((e.off, WTy::I32, v as f64));
                    } else {
                        st.write_i32(e.off, v as i32);
                    }
                }
                _ => return Status::Error,
            }
        }
        Status::Ok
    }
    fn set_boolean(&self, vrs: Vec<u32>, values: Vec<bool>) -> Status {
        if vrs.len() != values.len() {
            return Status::Error;
        }
        let mut st = self.st.borrow_mut();
        for (vr, v) in vrs.into_iter().zip(values) {
            match st.vrs.resolve(vr) {
                Some(e) if e.wty == WTy::I32 && !e.negate && !e.is_string => {
                    let iv = if v { 1 } else { 0 };
                    if st.in_init {
                        st.init_overrides.push((e.off, WTy::I32, iv as f64));
                    } else {
                        st.write_i32(e.off, iv);
                    }
                }
                _ => return Status::Error,
            }
        }
        Status::Ok
    }
    fn set_string(&self, vrs: Vec<u32>, values: Vec<String>) -> Status {
        if vrs.len() != values.len() {
            return Status::Error;
        }
        let mut st = self.st.borrow_mut();
        for (vr, val) in vrs.into_iter().zip(values) {
            match st.vrs.resolve(vr) {
                Some(e) if e.is_string => {
                    if st.in_init {
                        st.init_string_overrides.push((e.off, val)); // see the field
                    } else {
                        st.write_string(e.off, &val);
                    }
                }
                _ => return Status::Error,
            }
        }
        Status::Ok
    }
    fn set_binary(&self, _: Vec<u32>, _: Vec<Vec<u8>>) -> Status {
        Status::Error
    }
    fn set_clock(&self, _: Vec<u32>, _: Vec<bool>) -> Status {
        Status::Error
    }

    fn get_number_of_variable_dependencies(&self, _: u32) -> Result<u64, Status> {
        Err(Status::Error)
    }
    fn get_variable_dependencies(&self, _: u32) -> Result<Vec<VariableDependency>, Status> {
        Err(Status::Error)
    }

    fn get_fmu_state(&self) -> Result<Vec<u8>, Status> {
        let st = self.st.borrow();
        let mut bytes = vec![0u8; st.layout.total as usize];
        let _ = Engine.read_bytes(st.sim_data, &mut bytes);
        Ok(bytes)
    }
    fn set_fmu_state(&self, state: Vec<u8>) -> Status {
        let st = self.st.borrow();
        if state.len() != st.layout.total as usize {
            return Status::Error;
        }
        let mut e = Engine;
        let _ = e.write_bytes(st.sim_data, &state);
        Status::Ok
    }

    fn get_directional_derivative(
        &self,
        _: Vec<u32>,
        _: Vec<u32>,
        _: Vec<f64>,
    ) -> Result<Vec<f64>, Status> {
        Err(Status::Error)
    }
    fn get_adjoint_derivative(
        &self,
        _: Vec<u32>,
        _: Vec<u32>,
        _: Vec<f64>,
    ) -> Result<Vec<f64>, Status> {
        Err(Status::Error)
    }

    fn get_interval_decimal(&self, _: Vec<u32>) -> Result<Vec<(f64, IntervalQualifier)>, Status> {
        Err(Status::Error)
    }
    fn get_interval_fraction(
        &self,
        _: Vec<u32>,
    ) -> Result<Vec<(IntervalFraction, IntervalQualifier)>, Status> {
        Err(Status::Error)
    }
    fn get_shift_decimal(&self, _: Vec<u32>) -> Result<Vec<f64>, Status> {
        Err(Status::Error)
    }
    fn get_shift_fraction(&self, _: Vec<u32>) -> Result<Vec<IntervalFraction>, Status> {
        Err(Status::Error)
    }
    fn set_interval_decimal(&self, _: Vec<u32>, _: Vec<f64>) -> Status {
        Status::Error
    }
    fn set_interval_fraction(&self, _: Vec<u32>, _: Vec<IntervalFraction>) -> Status {
        Status::Error
    }
    fn set_shift_decimal(&self, _: Vec<u32>, _: Vec<f64>) -> Status {
        Status::Error
    }
    fn set_shift_fraction(&self, _: Vec<u32>, _: Vec<IntervalFraction>) -> Status {
        Status::Error
    }
    fn evaluate_discrete_states(&self) -> Status {
        Status::Ok
    }
    fn enter_step_mode(&self) -> Status {
        Status::Ok
    }

    fn get_output_derivatives(&self, _: Vec<(u32, u32)>) -> Result<Vec<f64>, Status> {
        Err(Status::Error)
    }
    };
}

#[cfg(feature = "me")]
impl GuestModelExchangeInstance for Instance {
    shared_instance_methods!();
    fn instantiate_model_exchange(
        _instance_name: String,
        _instantiation_token: String,
        _resource_path: String,
        _visible: bool,
        _logging_on: bool,
    ) -> Option<ModelExchangeInstance> {
        let st = new_state()?;
        Some(ModelExchangeInstance::new(Instance { st: RefCell::new(st) }))
    }

    fn enter_continuous_time_mode(&self) -> Status {
        Status::Ok
    }

    fn set_time(&self, time: f64) -> Status {
        let st = self.st.borrow();
        st.write_f64(TIME_OFF, time);
        Status::Ok
    }
    fn set_continuous_states(&self, states: Vec<f64>) -> Status {
        let st = self.st.borrow();
        if states.len() != st.layout.n_states as usize {
            return Status::Error;
        }
        for (i, v) in states.into_iter().enumerate() {
            st.write_f64(REAL_OFF + (i as u32) * 8, v);
        }
        Status::Ok
    }

    fn get_continuous_state_derivatives(&self) -> Result<Vec<f64>, Status> {
        let st = self.st.borrow();
        let mut e = Engine;
        if e.call1("functionODE", st.sim_data).is_err() {
            return Err(Status::Error);
        }
        let n = st.layout.n_states;
        let base = REAL_OFF + n * 8;
        Ok((0..n).map(|i| st.read_f64(base + i * 8)).collect())
    }
    fn get_event_indicators(&self) -> Result<Vec<f64>, Status> {
        let st = self.st.borrow();
        let mut e = Engine;
        let _ = e.call1("functionODE", st.sim_data);
        if st.layout.n_zc == 0 {
            return Ok(Vec::new());
        }
        if e.call1("functionZeroCrossings", st.sim_data).is_err() {
            return Err(Status::Error);
        }
        Ok((0..st.layout.n_zc).map(|i| st.read_f64(st.layout.zc_off + i * 8)).collect())
    }
    fn get_continuous_states(&self) -> Result<Vec<f64>, Status> {
        let st = self.st.borrow();
        Ok((0..st.layout.n_states).map(|i| st.read_f64(REAL_OFF + i * 8)).collect())
    }
    fn get_nominals_of_continuous_states(&self) -> Result<Vec<f64>, Status> {
        let st = self.st.borrow();
        Ok(vec![1.0; st.layout.n_states as usize])
    }
    fn get_number_of_event_indicators(&self) -> Result<u64, Status> {
        Ok(self.st.borrow().layout.n_zc as u64)
    }
    fn get_number_of_continuous_states(&self) -> Result<u64, Status> {
        Ok(self.st.borrow().layout.n_states as u64)
    }

    /// Must not touch the model state: `functionAlgebraics` would fire the
    /// when-bodies outside Event Mode and save their `pre`, so the following
    /// `update-discrete-states` sees no edge and the `reinit` is lost. Every when
    /// is guarded by a zero-crossing or a sample, so Event Mode is reached anyway.
    fn completed_integrator_step(
        &self,
        _no_set_fmu_state_prior_to_current_point: bool,
    ) -> Result<CompletedStepResult, Status> {
        let st = self.st.borrow();
        Ok(CompletedStepResult {
            enter_event_mode: false,
            terminate_simulation: st.read_i32(st.layout.terminate_off) != 0,
        })
    }
}


struct Fmu;

impl CommonGuest for Fmu {
    fn get_version() -> String {
        "3.0".to_string()
    }
}

#[cfg(feature = "me")]
impl MeGuest for Fmu {
    type ModelExchangeInstance = Instance;
}

#[cfg(feature = "cs")]
impl GuestCoSimulationInstance for Instance {
    shared_instance_methods!();

    fn instantiate_co_simulation(
        _instance_name: String,
        _instantiation_token: String,
        _resource_path: String,
        _visible: bool,
        _logging_on: bool,
        event_mode_used: bool,
        _early_return_allowed: bool,
        _required_intermediate_variables: Vec<u32>,
    ) -> Option<CoSimulationInstance> {
        let mut st = new_state()?;
        st.event_mode = event_mode_used;
        Some(CoSimulationInstance::new(Instance { st: RefCell::new(st) }))
    }

    /// Integrate to the communication point. Under `eventModeUsed` it stops at the
    /// first event and returns `event-handling-needed`; otherwise events are handled
    /// internally.
    fn do_step(
        &self,
        current_communication_point: f64,
        communication_step_size: f64,
        _no_set_fmu_state_prior_to_current_point: bool,
    ) -> Result<DoStepResult, Status> {
        let mut st = self.st.borrow_mut();
        let target = current_communication_point + communication_step_size;
        let event_mode = st.event_mode;
        let meta = st.meta.clone();
        let mut e = Engine;
        // Build the driver on first use, over the initialized state at the start
        // point (FMI ran Initialization Mode; the importer may also have set inputs).
        // Event Mode already built it in exit-initialization-mode.
        if st.cs.is_none() {
            let (sim_data, t) = (st.sim_data, st.read_f64(TIME_OFF));
            match CsDriver::new(&mut e, &meta, sim_data, t) {
                Ok(d) => st.cs = Some(d),
                Err(_) => return Err(Status::Error),
            }
        }
        let Some(mut driver) = st.cs.take() else { return Err(Status::Error) };
        let outcome = if event_mode {
            driver.step_to_event(&mut e, &meta, target)
        } else {
            driver.step_to(&mut e, &meta, target)
        };
        let last = driver.time();
        st.cs = Some(driver);
        let eps = target.abs().max(1.0) * 1e-10;
        match outcome {
            Ok(CsStep::Reached) => Ok(DoStepResult {
                last_successful_time: last,
                event_handling_needed: false,
                terminate_simulation: false,
                early_return: false,
            }),
            Ok(CsStep::Event { time }) => Ok(DoStepResult {
                last_successful_time: time,
                event_handling_needed: true,
                terminate_simulation: false,
                early_return: time + eps < target,
            }),
            Ok(CsStep::Terminated) => Ok(DoStepResult {
                last_successful_time: last,
                event_handling_needed: false,
                terminate_simulation: true,
                early_return: false,
            }),
            Err(_) => Err(Status::Error),
        }
    }

    fn set_input_derivatives(&self, _: Vec<(u32, u32)>, _: Vec<f64>) -> Status {
        Status::Error
    }
}

#[cfg(feature = "cs")]
impl CsGuest for Fmu {
    type CoSimulationInstance = Instance;
}

export!(Fmu);
