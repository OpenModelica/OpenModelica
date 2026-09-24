//! The seam `fmi-export/fmu2_model_interface.c` links against: what
//! `libSimulationRuntimeC` gave an FMU beyond the entry points the generated model
//! already reaches in an executable -- the lifecycle, i.e. allocate `DATA`,
//! initialize the model, iterate an event, tear down.
//!
//! C's `model_help.c` is transliterated over `DATA` rather than routed through the
//! shared driver: the importer owns the stepping, so the control flow has to stay
//! C's call for call. Only `initialization`, which needs the solver stack, goes
//! through [`CEngine`] and the driver.

use core::ffi::{c_char, c_double, c_int, c_long, c_void};

use openmodelica_sim_meta::{SimMeta, driver, omclog};

use crate::abi::*;
use crate::engine::CEngine;

/// The FMI interface sizes its own ring buffer with this.
#[unsafe(no_mangle)]
pub static SIZERINGBUFFER: usize = 3;

// ---------------------------------------------------------------------------
// Per-instance state
// ---------------------------------------------------------------------------

/// What `initialization` needs and the FMI interface has nowhere to keep: the
/// region map over this instance's `DATA`, the model description the driver runs
/// on, and the state-set pivoting carried across the run. Keyed by `DATA*`,
/// because that is the only handle the seam is given -- `fmi2Instantiate`
/// allocates one per component, so several may be live.
///
/// Built at the first `initialization` rather than in `initializeDataStruc`: the
/// layout is sized from the systems, and the importer sets the parameters (and
/// the generated `read_input_fmu` the attributes) in between.
struct Instance {
    data: *mut DATA,
    engine: CEngine,
    meta: SimMeta,
    sel: driver::StateSelection,
    /// C's `intvlTimers`, set up by `initialization` for a model with clocks.
    sync: Option<openmodelica_sim_meta::sync::Sync>,
}

/// The flat address the region map starts the model at. A C model has one block,
/// so the driver's `sim_data` base is always zero here.
const SIM_DATA: u32 = 0;

fn instance_for(data: *mut DATA, thread_data: *mut threadData_t) -> &'static mut Instance {
    if let Some(i) = instances().iter().position(|i| i.data == data) {
        return &mut instances()[i];
    }
    let rt = crate::data::build_rt(data, thread_data);
    let layout = rt.layout;
    let mut meta =
        crate::meta::build(data, thread_data, &crate::model_data::InitXml::default(), &layout, &model_prefix(data));
    (meta.fmi_vrs, meta.fmi_dae_enable_vr) = crate::fmi_vrs::build(data, &layout);
    let mut engine = CEngine::new(rt);
    engine.keep_params = true;
    engine.sync_attributes();
    engine.seed_string_vars();
    let sel = driver::StateSelection::new(&meta);
    instances().push(Box::new(Instance { data, engine, meta, sel, sync: None }));
    instances().last_mut().expect("just pushed")
}

struct Instances(core::cell::UnsafeCell<Vec<Box<Instance>>>);
// One FMU component is driven by one thread at a time, which is the same
// assumption C's own runtime makes of its globals.
unsafe impl Sync for Instances {}
static INSTANCES: Instances = Instances(core::cell::UnsafeCell::new(Vec::new()));

/// `CEngine` publishes the driver's mode into `solveContinuous`, which C only
/// sets inside a nonlinear solve; the event-triggering math functions refresh
/// their held values only when it is clear.
fn leave_driver(data: *mut DATA) {
    unsafe { (*(*data).simulationInfo).solveContinuous = 0 };
}

fn instances() -> &'static mut Vec<Box<Instance>> {
    unsafe { &mut *INSTANCES.0.get() }
}

fn instance(data: *mut DATA) -> Option<&'static mut Instance> {
    instances().iter_mut().find(|i| i.data == data).map(|i| &mut **i)
}

// ---------------------------------------------------------------------------
// MODEL_DATA: what the generated `<Model>_read_input_fmu` fills in
// ---------------------------------------------------------------------------

fn alloc<T>(n: usize) -> *mut T {
    crate::model_data::calloc(n)
}

/// C's `allocModelDataVars`. `allocAlias` is false for every FMU -- the FMI
/// interface resolves aliases through the model description, not `DATA`.
#[unsafe(no_mangle)]
pub extern "C" fn allocModelDataVars(
    model_data: *mut MODEL_DATA,
    alloc_alias: modelica_boolean,
    _thread_data: *mut threadData_t,
) {
    let md = unsafe { &mut *model_data };
    md.realVarsData = alloc(md.nVariablesRealArray as usize);
    md.integerVarsData = alloc(md.nVariablesIntegerArray as usize);
    md.booleanVarsData = alloc(md.nVariablesBooleanArray as usize);
    md.stringVarsData = alloc(md.nVariablesStringArray as usize);
    md.realParameterData = alloc(md.nParametersRealArray as usize);
    md.integerParameterData = alloc(md.nParametersIntegerArray as usize);
    md.booleanParameterData = alloc(md.nParametersBooleanArray as usize);
    md.stringParameterData = alloc(md.nParametersStringArray as usize);
    md.realSensitivityData = alloc(md.nSensitivityVars as usize);
    if alloc_alias != 0 {
        md.realAlias = alloc(md.nAliasRealArray as usize);
        md.integerAlias = alloc(md.nAliasIntegerArray as usize);
        md.booleanAlias = alloc(md.nAliasBooleanArray as usize);
        md.stringAlias = alloc(md.nAliasStringArray as usize);
    } else {
        md.realAlias = core::ptr::null_mut();
        md.integerAlias = core::ptr::null_mut();
        md.booleanAlias = core::ptr::null_mut();
        md.stringAlias = core::ptr::null_mut();
    }
}

/// The one element `<Model>_read_input_fmu`'s `put_real_element` writes into.
fn alloc_scalar_real_array(a: &mut real_array) {
    alloc_scalar_array::<f64>(a);
}

/// The one element `<Model>_read_input_fmu`'s `put_<type>_element` writes into.
fn alloc_scalar_array<T>(a: &mut base_array_t) {
    a.ndims = 1;
    a.dim_size = alloc(1);
    unsafe { *a.dim_size = 1 };
    a.data = alloc::<T>(1).cast();
    a.flexible = 0;
}

#[unsafe(no_mangle)]
pub extern "C" fn scalarAllocArrayAttributes(model_data: *mut MODEL_DATA) {
    let md = unsafe { &mut *model_data };
    for (base, count) in [
        (md.realVarsData, md.nVariablesRealArray),
        (md.realParameterData, md.nParametersRealArray),
    ] {
        for i in 0..count as usize {
            let a = unsafe { &mut (*base.add(i)).attribute };
            alloc_scalar_real_array(&mut a.start);
            alloc_scalar_real_array(&mut a.nominal);
            alloc_scalar_real_array(&mut a.min);
            alloc_scalar_real_array(&mut a.max);
        }
    }
    for (base, count) in [
        (md.integerVarsData, md.nVariablesIntegerArray),
        (md.integerParameterData, md.nParametersIntegerArray),
    ] {
        for i in 0..count as usize {
            let a = unsafe { &mut (*base.add(i)).attribute };
            alloc_scalar_array::<modelica_integer>(&mut a.start);
            alloc_scalar_array::<modelica_integer>(&mut a.min);
            alloc_scalar_array::<modelica_integer>(&mut a.max);
        }
    }
    for (base, count) in [
        (md.booleanVarsData, md.nVariablesBooleanArray),
        (md.booleanParameterData, md.nParametersBooleanArray),
    ] {
        for i in 0..count as usize {
            alloc_scalar_array::<modelica_boolean>(unsafe { &mut (*base.add(i)).attribute.start });
        }
    }
    for (base, count) in [
        (md.stringVarsData, md.nVariablesStringArray),
        (md.stringParameterData, md.nParametersStringArray),
    ] {
        for i in 0..count as usize {
            alloc_scalar_array::<modelica_string>(unsafe { &mut (*base.add(i)).attribute.start });
        }
    }
}

/// `initializeDataStruc` runs this again while building the array index maps; the
/// FMI interface asks for it before the start values are in place, as C's does.
#[unsafe(no_mangle)]
pub extern "C" fn calculateAllScalarLength(model_data: *mut MODEL_DATA) {
    crate::data::calculate_all_scalar_length(unsafe { &mut *model_data });
}

// ---------------------------------------------------------------------------
// DATA lifecycle
// ---------------------------------------------------------------------------

/// C's `initializeDataStruc`: the arrays only. The FMI interface asks for the
/// solver systems separately, after the generated `read_input_fmu` has put the
/// attributes a system is sized and scaled from in place.
#[unsafe(no_mangle)]
pub extern "C" fn initializeDataStruc(data: *mut DATA, thread_data: *mut threadData_t) {
    crate::data::initialize_data_struc(data, thread_data);
    crate::nls::install_hooks(data, thread_data, &model_prefix(data));
}

/// Forgets the instance. The `DATA` arrays are left to the process, as the
/// simulation executable's are, so repeated instantiation grows.
#[unsafe(no_mangle)]
pub extern "C" fn deInitializeDataStruc(data: *mut DATA) {
    instances().retain(|i| i.data != data);
}

#[unsafe(no_mangle)]
pub extern "C" fn setAllVarsToStart(
    simulation_data: *mut SIMULATION_DATA,
    simulation_info: *const SIMULATION_INFO,
    model_data: *const MODEL_DATA,
) {
    let (sd, si, md) =
        unsafe { (&mut *simulation_data, &*simulation_info, &*model_data) };
    for a in 0..md.nVariablesRealArray as usize {
        let attr = unsafe { &(*md.realVarsData.add(a)).attribute };
        let base = unsafe { *si.realVarsIndex.add(a) };
        let n = unsafe { (*md.realVarsData.add(a)).dimension.scalar_length };
        for k in 0..n {
            unsafe { *sd.realVars.add(base + k) = attr.start.real_at(k, 0.0) };
        }
    }
    for a in 0..md.nVariablesIntegerArray as usize {
        let v = unsafe { &*md.integerVarsData.add(a) };
        let base = unsafe { *si.integerVarsIndex.add(a) };
        for k in 0..v.dimension.scalar_length {
            unsafe { *sd.integerVars.add(base + k) = v.attribute.start.elem_at(k, 0) };
        }
    }
    for a in 0..md.nVariablesBooleanArray as usize {
        let v = unsafe { &*md.booleanVarsData.add(a) };
        let base = unsafe { *si.booleanVarsIndex.add(a) };
        for k in 0..v.dimension.scalar_length {
            unsafe { *sd.booleanVars.add(base + k) = v.attribute.start.elem_at(k, 0) };
        }
    }
    for a in 0..md.nVariablesStringArray as usize {
        let v = unsafe { &*md.stringVarsData.add(a) };
        let base = unsafe { *si.stringVarsIndex.add(a) };
        for k in 0..v.dimension.scalar_length {
            let start = v.attribute.start.elem_at(k, core::ptr::null_mut());
            unsafe { *sd.stringVars.add(base + k) = persist_string(start) };
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn setAllParamsToStart(
    simulation_info: *mut SIMULATION_INFO,
    model_data: *const MODEL_DATA,
) {
    let (si, md) = unsafe { (&mut *simulation_info, &*model_data) };
    for a in 0..md.nParametersRealArray as usize {
        let attr = unsafe { &(*md.realParameterData.add(a)).attribute };
        let base = unsafe { *si.realParamsIndex.add(a) };
        let n = unsafe { (*md.realParameterData.add(a)).dimension.scalar_length };
        for k in 0..n {
            unsafe { *si.realParameter.add(base + k) = attr.start.real_at(k, 0.0) };
        }
    }
    for a in 0..md.nParametersIntegerArray as usize {
        let p = unsafe { &*md.integerParameterData.add(a) };
        let base = unsafe { *si.integerParamsIndex.add(a) };
        for k in 0..p.dimension.scalar_length {
            unsafe { *si.integerParameter.add(base + k) = p.attribute.start.elem_at(k, 0) };
        }
    }
    for a in 0..md.nParametersBooleanArray as usize {
        let p = unsafe { &*md.booleanParameterData.add(a) };
        let base = unsafe { *si.booleanParamsIndex.add(a) };
        for k in 0..p.dimension.scalar_length {
            unsafe { *si.booleanParameter.add(base + k) = p.attribute.start.elem_at(k, 0) };
        }
    }
    for a in 0..md.nParametersStringArray as usize {
        let p = unsafe { &*md.stringParameterData.add(a) };
        let base = unsafe { *si.stringParamsIndex.add(a) };
        for k in 0..p.dimension.scalar_length {
            let start = p.attribute.start.elem_at(k, core::ptr::null_mut());
            unsafe { crate::model_data::string_store(si.stringParameter.add(base + k), start) };
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn copyStartValuestoInitValues(data: *mut DATA) {
    unsafe {
        setAllParamsToStart((*data).simulationInfo, (*data).modelData);
        setAllVarsToStart(*(*data).localData, (*data).simulationInfo, (*data).modelData);
    }
    storePreValues(data);
    overwriteOldSimulationData(data);
}

#[unsafe(no_mangle)]
pub extern "C" fn storePreValues(data: *mut DATA) {
    let (md, si, sd) = unsafe {
        (&*(*data).modelData, &mut *(*data).simulationInfo, &**(*data).localData)
    };
    unsafe {
        copy(sd.realVars, si.realVarsPre, md.nVariablesReal);
        copy(sd.integerVars, si.integerVarsPre, md.nVariablesInteger);
        copy(sd.booleanVars, si.booleanVarsPre, md.nVariablesBoolean);
        copy(sd.stringVars, si.stringVarsPre, md.nVariablesString);
    }
}

/// C's `overwriteOldSimulationData`: every ring slot takes the one before it.
#[unsafe(no_mangle)]
pub extern "C" fn overwriteOldSimulationData(data: *mut DATA) {
    let md = unsafe { &*(*data).modelData };
    for i in 1..SIZERINGBUFFER {
        let (dst, src) = unsafe { (&mut **(*data).localData.add(i), &**(*data).localData.add(i - 1)) };
        dst.timeValue = src.timeValue;
        unsafe {
            copy(src.realVars, dst.realVars, md.nVariablesReal);
            copy(src.integerVars, dst.integerVars, md.nVariablesInteger);
            copy(src.booleanVars, dst.booleanVars, md.nVariablesBoolean);
            copy(src.stringVars, dst.stringVars, md.nVariablesString);
        }
    }
}

unsafe fn copy<T>(src: *const T, dst: *mut T, n: c_long) {
    if n > 0 && !src.is_null() && !dst.is_null() {
        unsafe { core::ptr::copy_nonoverlapping(src, dst, n as usize) };
    }
}

// ---------------------------------------------------------------------------
// Relations and the discrete system
// ---------------------------------------------------------------------------

#[unsafe(no_mangle)]
pub extern "C" fn updateRelationsPre(data: *mut DATA) {
    let (md, si) = unsafe { (&*(*data).modelData, &*(*data).simulationInfo) };
    unsafe { copy(si.relations, si.relationsPre, md.nRelations) };
}

#[unsafe(no_mangle)]
pub extern "C" fn storeRelations(data: *mut DATA) {
    let (md, si) = unsafe { (&*(*data).modelData, &*(*data).simulationInfo) };
    unsafe { copy(si.relations, si.storedRelations, md.nRelations) };
}

/// C's `checkRelations`: whether any relation differs from its `pre` value.
#[unsafe(no_mangle)]
pub extern "C" fn checkRelations(data: *mut DATA) -> modelica_boolean {
    let (md, si) = unsafe { (&*(*data).modelData, &*(*data).simulationInfo) };
    for i in 0..md.nRelations as usize {
        if unsafe { *si.relationsPre.add(i) != *si.relations.add(i) } {
            return 1;
        }
    }
    0
}

/// Whether a discrete variable moved away from its `pre` value. `$cse` variables
/// are the backend's common subexpressions, not discrete state, and C skips them.
#[unsafe(no_mangle)]
pub extern "C" fn checkForDiscreteChanges(
    data: *mut DATA,
    _thread_data: *mut threadData_t,
) -> modelica_boolean {
    let (md, si, sd) = unsafe {
        (&*(*data).modelData, &*(*data).simulationInfo, &**(*data).localData)
    };
    let verbose = omclog::active(omclog::EVENTS_V);
    let mut changed = false;
    if verbose {
        omclog::info!(
            omclog::EVENTS_V,
            true,
            "check for discrete changes at time={:.12}",
            sd.timeValue
        );
    }

    macro_rules! scan {
        ($count:expr, $data:expr, $index:expr, $pre:expr, $live:expr, $first:expr) => {
            for a in $first..$count as usize {
                let var = unsafe { &*$data.add(a) };
                if is_cse(var.info.name) {
                    continue;
                }
                let base = unsafe { *$index.add(a) };
                for k in 0..var.dimension.scalar_length {
                    let (v1, v2) = unsafe { (*$pre.add(base + k), *$live.add(base + k)) };
                    if v1 != v2 {
                        changed = true;
                        if !verbose {
                            return 1;
                        }
                        omclog::info!(
                            omclog::EVENTS_V,
                            false,
                            "discrete var changed: {} from {} to {}",
                            cstr(var.info.name),
                            v1,
                            v2
                        );
                    }
                }
            }
        };
    }

    let first_discrete_real =
        (md.nVariablesRealArray - md.nDiscreteRealArray).max(0) as usize;
    scan!(
        md.nVariablesRealArray,
        md.realVarsData,
        si.realVarsIndex,
        si.realVarsPre,
        sd.realVars,
        first_discrete_real
    );
    scan!(
        md.nVariablesIntegerArray,
        md.integerVarsData,
        si.integerVarsIndex,
        si.integerVarsPre,
        sd.integerVars,
        0
    );
    scan!(
        md.nVariablesBooleanArray,
        md.booleanVarsData,
        si.booleanVarsIndex,
        si.booleanVarsPre,
        sd.booleanVars,
        0
    );

    for a in 0..md.nVariablesStringArray as usize {
        let var = unsafe { &*md.stringVarsData.add(a) };
        if is_cse(var.info.name) {
            continue;
        }
        let base = unsafe { *si.stringVarsIndex.add(a) };
        for k in 0..var.dimension.scalar_length {
            let (v1, v2) = unsafe { (*si.stringVarsPre.add(base + k), *sd.stringVars.add(base + k)) };
            if string_value(v1) != string_value(v2) {
                changed = true;
                if !verbose {
                    return 1;
                }
            }
        }
    }

    if verbose {
        omclog::close(omclog::EVENTS_V);
    }
    changed as modelica_boolean
}

/// Iterate `functionDAE` until neither a relation nor a discrete variable moves.
#[unsafe(no_mangle)]
pub extern "C" fn updateDiscreteSystem(data: *mut DATA, thread_data: *mut threadData_t) {
    // Every read goes through the pointer: `functionDAE` writes into the same
    // `SIMULATION_INFO`, and a `&mut` held across it would let the compiler keep
    // `needToIterate` in a register.
    let si = |data: *mut DATA| unsafe { &mut *(*data).simulationInfo };
    si(data).needToIterate = 0;
    si(data).discreteStateChanged = 0;
    si(data).callStatistics.updateDiscreteSystem += 1;

    update_relations(data, thread_data);
    updateRelationsPre(data);
    storeRelations(data);
    function_dae(data, thread_data);

    let mut relation_changed = checkRelations(data) != 0;
    let mut discrete_changed = checkForDiscreteChanges(data, thread_data) != 0;

    // C deactivates the sample events that fired, after the first iteration.
    if si(data).sampleActivated != 0 {
        let md = unsafe { &*(*data).modelData };
        for i in 0..md.nSamples as usize {
            if unsafe { *si(data).samples.add(i) } != 0 {
                unsafe {
                    *si(data).samples.add(i) = 0;
                    *si(data).nextSampleTimes.add(i) += (*md.samplesInfo.add(i)).interval;
                }
            }
        }
    }

    let max_iterations =
        openmodelica_solvers::simflags::with_flags(|f| f.max_event_iter).unwrap_or(20);
    let mut iterations = 0;
    while discrete_changed || si(data).needToIterate != 0 || relation_changed {
        si(data).discreteStateChanged = 1;
        storePreValues(data);
        updateRelationsPre(data);
        function_dae(data, thread_data);

        iterations += 1;
        if iterations > max_iterations {
            crate::throw(
                thread_data,
                &format!(
                    "Simulation terminated due to too many, i.e. {max_iterations}, event iterations.\n\
                     This could either indicate an inconsistent system or an undersized limit of event iterations.\n\
                     The limit of event iterations can be specified using the runtime flag '–mei=<value>'."
                ),
            );
        }
        relation_changed = checkRelations(data) != 0;
        discrete_changed = checkForDiscreteChanges(data, thread_data) != 0;
    }
    storeRelations(data);
}

/// `function_updateRelations(data, threadData, 0)`: the relations evaluated
/// without arming the zero crossings, under the jump buffer every model call
/// made from a Rust frame needs.
fn update_relations(data: *mut DATA, thread_data: *mut threadData_t) {
    let cb = unsafe { &*(*data).callback };
    let Some(f) = cb.function_updateRelations else { return };
    crate::support::protected(thread_data, crate::support::error_stage::EVENTHANDLING, || {
        unsafe { f(data, thread_data, 0) };
    });
}

fn function_dae(data: *mut DATA, thread_data: *mut threadData_t) {
    let cb = unsafe { &*(*data).callback };
    let Some(f) = cb.functionDAE else { return };
    crate::support::protected(thread_data, crate::support::error_stage::EVENTHANDLING, || {
        unsafe { f(data, thread_data) };
    });
}

// ---------------------------------------------------------------------------
// Samples and clocks
// ---------------------------------------------------------------------------

#[unsafe(no_mangle)]
pub extern "C" fn initSample(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    start_time: c_double,
    _stop_time: c_double,
) {
    let cb = unsafe { &*(*data).callback };
    if let Some(f) = cb.function_initSample {
        crate::support::protected(thread_data, crate::support::error_stage::SIMULATION, || {
            unsafe { f(data, thread_data) };
        });
    }
    let (md, si) = unsafe { (&*(*data).modelData, &mut *(*data).simulationInfo) };
    si.nextSampleEvent = f64::MAX;
    for i in 0..md.nSamples as usize {
        let info = unsafe { &*md.samplesInfo.add(i) };
        let next = if start_time < info.start {
            info.start
        } else {
            info.start + ((start_time - info.start) / info.interval).ceil() * info.interval
        };
        unsafe { *si.nextSampleTimes.add(i) = next };
        if i == 0 || next < si.nextSampleEvent {
            si.nextSampleEvent = next;
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn getNextSampleTimeFMU(data: *mut DATA, next_sample_event: *mut c_double) -> c_int {
    let (md, si) = unsafe { (&*(*data).modelData, &*(*data).simulationInfo) };
    if md.nSamples <= 0 {
        return 0;
    }
    omclog::info!(omclog::EVENTS, false, "Next event time = {}", si.nextSampleEvent);
    unsafe { *next_sample_event = si.nextSampleEvent };
    1
}

/// Fires the clocks due at `current_time`; 1 (`TIMER_FIRED`) if any did.
#[unsafe(no_mangle)]
pub extern "C" fn handleTimersFMI(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    current_time: c_double,
    next_timer_defined: *mut modelica_boolean,
    next_timer_activation_time: *mut c_double,
) -> c_int {
    unsafe { *next_timer_defined = 0 };
    let Some(inst) = instance(data) else { return 0 };
    let Some(sync) = inst.sync.as_mut() else { return 0 };
    let r = driver::fmi_handle_timers(&mut inst.engine, sync, &inst.meta, SIM_DATA, current_time);
    leave_driver(data);
    let fired = match r {
        Ok(fired) => fired,
        Err(e) if driver::is_model_throw(e) => crate::support::rethrow(thread_data),
        Err(e) => crate::throw(thread_data, e),
    };
    let next = sync.next_time();
    if next.is_finite() {
        unsafe {
            *next_timer_defined = 1;
            *next_timer_activation_time = next;
        }
    }
    fired as c_int
}

// ---------------------------------------------------------------------------
// Systems and state sets
// ---------------------------------------------------------------------------

#[unsafe(no_mangle)]
pub extern "C" fn initializeNonlinearSystems(
    data: *mut DATA,
    thread_data: *mut threadData_t,
) -> c_int {
    crate::nls::initialize_nonlinear_systems(data, thread_data);
    0
}

#[unsafe(no_mangle)]
pub extern "C" fn freeNonlinearSystems(_data: *mut DATA, _thread_data: *mut threadData_t) {
    omclog::info(omclog::NLS, true, "free non-linear system solvers");
    omclog::close(omclog::NLS);
}

#[unsafe(no_mangle)]
pub extern "C" fn initializeLinearSystems(data: *mut DATA, thread_data: *mut threadData_t) -> c_int {
    crate::systems::initialize_linear_systems(data, thread_data);
    0
}

#[unsafe(no_mangle)]
pub extern "C" fn freeLinearSystems(_data: *mut DATA, _thread_data: *mut threadData_t) -> c_int {
    omclog::info(omclog::LS_V, true, "free linear system solvers");
    omclog::close(omclog::LS_V);
    0
}

#[unsafe(no_mangle)]
pub extern "C" fn initializeMixedSystems(data: *mut DATA, thread_data: *mut threadData_t) -> c_int {
    crate::mixed::initialize_mixed_systems(data, thread_data);
    0
}

#[unsafe(no_mangle)]
pub extern "C" fn freeMixedSystems(_data: *mut DATA, _thread_data: *mut threadData_t) -> c_int {
    omclog::info(omclog::MIXED, true, "free mixed system solvers");
    omclog::close(omclog::MIXED);
    0
}

#[unsafe(no_mangle)]
pub extern "C" fn initializeStateSetJacobians(data: *mut DATA, thread_data: *mut threadData_t) {
    crate::stateset::initialize_state_sets(data, thread_data);
}

/// The pivoting belongs to the shared driver, which addresses a state set through
/// the region map, so this goes through the instance's engine.
#[unsafe(no_mangle)]
pub extern "C" fn stateSelection(
    data: *mut DATA,
    _thread_data: *mut threadData_t,
    _report_error: c_char,
    switch_states: c_int,
) -> c_int {
    let md = unsafe { &*(*data).modelData };
    if md.nStateSets == 0 {
        return 0;
    }
    let Some(inst) = instance(data) else { return 0 };
    let r = if switch_states != 0 {
        inst.sel.reselect(&mut inst.engine, SIM_DATA, &inst.meta)
    } else {
        inst.sel.would_change(&mut inst.engine, SIM_DATA, &inst.meta)
    };
    leave_driver(data);
    match r {
        Ok(changed) => changed as c_int,
        Err(e) => {
            omclog::error(omclog::ASSERT, false, e);
            0
        }
    }
}

// ---------------------------------------------------------------------------
// Initialization
// ---------------------------------------------------------------------------

/// C's `initialization`. `pInitMethod` is `"fmi"` for every FMU, which tells C to
/// keep the parameter values the importer set rather than re-reading the start
/// attributes; the shared driver's `run_initialization_model` does the same
/// because it never sets them here either.
#[unsafe(no_mangle)]
pub extern "C" fn initialization(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    _init_method: *const c_char,
    _init_file: *const c_char,
    _init_time: c_double,
) -> c_int {
    let inst = instance_for(data, thread_data);
    // The discrete starts the driver seeds from; the importer may have set them
    // since the instance was built (`fmi2Reset`).
    inst.meta.soti = unsafe { crate::meta::soti_vars(&*(*data).modelData, &*(*data).simulationInfo) };
    // `fmi2SetupExperiment`'s start time.
    inst.meta.start_time = unsafe { (**(*data).localData).timeValue };
    unsafe { (*(*data).simulationInfo).homotopySteps = 0 };
    omclog::info(omclog::INIT, false, "### START INITIALIZATION ###");
    let r = driver::run_initialization_model(&mut inst.engine, SIM_DATA, &inst.meta)
        // C's `initialization()` pivots the state sets on the resolved initial
        // point before it returns, so the caller's first step already has the
        // selected states.
        .and_then(|()| driver::StateSelection::initial(&mut inst.engine, SIM_DATA, &inst.meta));
    omclog::info(omclog::INIT, false, "### END INITIALIZATION ###");
    // C's `initialization` ends with `initSynchronous`.
    let r = r.and_then(|sel| {
        inst.sync = None;
        if !inst.meta.clocks.is_empty() {
            let mut sync = openmodelica_sim_meta::sync::Sync::new(&mut inst.engine, &inst.meta, SIM_DATA)?;
            sync.take_fired(&mut inst.engine, inst.meta.start_time)?;
            inst.sync = Some(sync);
        }
        Ok(sel)
    });
    leave_driver(data);
    match r {
        Ok(sel) => {
            inst.sel = sel;
            0
        }
        Err(e) => {
            if !driver::is_model_throw(e) {
                omclog::error(omclog::ASSERT, false, e);
            }
            -1
        }
    }
}

// ---------------------------------------------------------------------------
// Odds and ends
// ---------------------------------------------------------------------------

#[unsafe(no_mangle)]
pub extern "C" fn setZCtol(relative_tol: c_double) {
    // C's TOL_HYSTERESIS_ZEROCROSSINGS * fmax(relativeTol, MINIMAL_STEP_SIZE).
    const TOL_HYSTERESIS: f64 = 1e-4;
    const MINIMAL_STEP_SIZE: f64 = 1e-12;
    let tol = TOL_HYSTERESIS * relative_tol.max(MINIMAL_STEP_SIZE);
    unsafe { crate::support::tolZC = tol };
    omclog::info!(omclog::EVENTS_V, false, "Set tolerance for zero-crossing hysteresis to: {tol:e}");
}

/// `<Model>_info.json` is read lazily (`src/info_json.rs`), so there is nothing
/// to open here.
#[unsafe(no_mangle)]
pub extern "C" fn modelInfoInit(_xml: *mut MODEL_DATA_XML) {}

unsafe extern "C" {
    fn OpenModelica_uriToFilename_impl(
        threadData: *mut threadData_t,
        uri: modelica_string,
        resourcesDir: *const c_char,
    ) -> modelica_string;
    fn OpenModelica_decode_uri_inplace(uri: *mut c_char);
}

/// `loadResource` in an FMU resolves against its `resources` directory.
#[unsafe(no_mangle)]
pub extern "C" fn OpenModelica_fmuLoadResource(
    threadData: *mut threadData_t,
    path: modelica_string,
) -> modelica_string {
    unsafe {
        let data = (*threadData).localRoots[LOCAL_ROOT_SIMULATION_DATA] as *mut DATA;
        OpenModelica_uriToFilename_impl(threadData, path, (*(*data).modelData).resourcesDir)
    }
}

/// `fmi2Instantiate` is handed a URI and wants a path. Returns a `malloc`ed string
/// the caller frees, or null for a scheme that names no local directory.
#[unsafe(no_mangle)]
pub extern "C" fn OpenModelica_parseFmuResourcePath(path: *const c_char) -> *const c_char {
    if path.is_null() {
        return core::ptr::null();
    }
    let s = cstr(path);
    let body = match s.strip_prefix("file://") {
        // file:///a/b and file://host/a/b: an empty authority is the local host.
        Some(rest) => match rest.find('/') {
            Some(i) => &rest[i..],
            None => return core::ptr::null(),
        },
        None if s.starts_with("file:") => &s["file:".len()..],
        None if !s.contains("://") => &s[..],
        None => return core::ptr::null(),
    };
    // Windows spells it file:///C:/... -- the leading slash is not part of the path.
    let body = match body.as_bytes() {
        [b'/', c, b':', ..] if c.is_ascii_alphabetic() => &body[1..],
        _ => body,
    };
    let mut bytes = body.as_bytes().to_vec();
    bytes.push(0);
    let p = unsafe { libc::malloc(bytes.len()) } as *mut u8;
    if p.is_null() {
        return core::ptr::null();
    }
    unsafe {
        core::ptr::copy_nonoverlapping(bytes.as_ptr(), p, bytes.len());
        OpenModelica_decode_uri_inplace(p as *mut c_char);
    }
    p as *const c_char
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// C's `strncmp(name, "$cse", 4) == 0`.
fn is_cse(name: *const c_char) -> bool {
    if name.is_null() {
        return false;
    }
    for (i, c) in b"$cse".iter().enumerate() {
        if unsafe { *name.add(i) } as u8 != *c {
            return false;
        }
    }
    true
}

fn cstr(p: *const c_char) -> String {
    if p.is_null() {
        String::new()
    } else {
        unsafe { core::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned()
    }
}

fn string_value(p: modelica_string) -> String {
    crate::model_data::string_value(p as *mut c_void)
}

fn persist_string(s: modelica_string) -> modelica_string {
    crate::model_data::mk_scon_persist(&string_value(s)) as modelica_string
}

/// The prefix `<Model>_info.json` and the log lines are named after.
fn model_prefix(data: *mut DATA) -> String {
    let md = unsafe { &*(*data).modelData };
    let name = cstr(md.modelFilePrefix);
    if name.is_empty() { cstr(md.modelName) } else { name }
}
