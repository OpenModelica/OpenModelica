//! What the page calls.
//!
//! The page hands over the bytes of an `.fmu`, asks for what is in it, and asks
//! for a run; everything in between — unzipping, the model description, the
//! solvers, the event handling, the `.mat` — happens here. The FMU's own wasm is
//! the host's business: this module reaches it through the imports in
//! `openmodelica_fmi_driver::wasm_host`, which the page's bridge binds to the
//! component's core exports.
//!
//! Strings cross as JSON in one buffer ([`om_fmi_out_ptr`]/[`om_fmi_out_len`]);
//! sample values are read straight out of the recorder's buffer.

use openmodelica_fmi::{Causality, Fmu, InterfaceKind, ModelDescription, VarType, Variability};
use openmodelica_fmi_driver::api::{Fmi3CoSimulation, Fmi3ModelExchange};
use openmodelica_fmi_driver::record::Recorder;
use openmodelica_fmi_driver::wasm_host::{HostFmu, KIND_CO_SIMULATION, KIND_MODEL_EXCHANGE};
use openmodelica_fmi_driver::{Error, Input, Options, Parameter, Solver, cs, expr, me};
use serde_json::{Value, json};
use std::cell::RefCell;

#[link(wasm_import_module = "host")]
unsafe extern "C" {
    /// The samples so far, at each output point: the page plots a run while it
    /// happens rather than at the end. The rows are `stride` values each, the
    /// time first, and stay valid only for the length of the call.
    fn host_progress(time: f64, rows: *const f64, len: usize, stride: usize);
    /// The columns those rows carry, once per run, as JSON in the out buffer.
    fn host_columns();
    /// Whether the page has asked for the run to stop.
    fn host_cancelled() -> i32;
}

#[derive(Default)]
struct State {
    fmu: Option<Fmu>,
    run: Option<Run>,
    /// A file taken out of the archive for the page — the wasm component, or a
    /// resource the FMU's own WASI host has to serve.
    binary: Vec<u8>,
}

struct Run {
    recorder: Recorder,
    summary: Value,
}

thread_local! {
    static STATE: RefCell<State> = RefCell::new(State::default());
    // The strings the page reads are their own cells: a run holds `STATE`
    // borrowed for its whole length, and the progress hook writes here from
    // inside it.
    static OUT: RefCell<String> = const { RefCell::new(String::new()) };
    static ERROR: RefCell<String> = const { RefCell::new(String::new()) };
    static COLUMNS_PUBLISHED: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
}

fn with<T>(f: impl FnOnce(&mut State) -> T) -> T {
    STATE.with(|s| f(&mut s.borrow_mut()))
}

fn set_out(text: String) {
    OUT.with(|o| *o.borrow_mut() = text);
}

fn fail(message: impl std::fmt::Display) -> i32 {
    ERROR.with(|e| *e.borrow_mut() = message.to_string());
    0
}

/// Memory for the page to write the FMU into. Freed by [`om_fmi_free`], or by
/// the module going away with the run.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_alloc(len: usize) -> *mut u8 {
    let mut v = Vec::<u8>::with_capacity(len);
    let ptr = v.as_mut_ptr();
    std::mem::forget(v);
    ptr
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn om_fmi_free(ptr: *mut u8, len: usize) {
    if !ptr.is_null() {
        drop(unsafe { Vec::from_raw_parts(ptr, 0, len) });
    }
}

/// Read the FMU archive at `ptr`. `1` on success; on `0` the reason is in
/// [`om_fmi_error_ptr`].
#[unsafe(no_mangle)]
pub unsafe extern "C" fn om_fmi_load(ptr: *const u8, len: usize) -> i32 {
    let bytes = unsafe { std::slice::from_raw_parts(ptr, len) };
    with(|s| {
        s.run = None;
        match Fmu::from_bytes(bytes) {
            Ok(fmu) => {
                s.fmu = Some(fmu);
                1
            }
            Err(e) => fail(e),
        }
    })
}

/// Take the wasm component for `kind` (0 Model Exchange, 1 Co-Simulation) out
/// of the archive, for the page to instantiate. The bytes land in the binary
/// buffer ([`om_fmi_binary_ptr`]).
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_select_component(kind: i32) -> i32 {
    with(|s| {
        let Some(fmu) = s.fmu.as_ref() else { return fail("no FMU is loaded") };
        let kind = if kind == 1 { InterfaceKind::CoSimulation } else { InterfaceKind::ModelExchange };
        let Some(binary) = fmu.select_binary(kind, openmodelica_fmi::Preference::Wasm) else {
            return fail(format!("the FMU has no binary for {}", kind.as_str()));
        };
        if binary.kind != openmodelica_fmi::BinaryKind::Wasm {
            return fail(format!(
                "{} is a native binary; this page can only run the wasm one",
                binary.path
            ));
        }
        let Some(bytes) = fmu.read(&binary.path) else {
            return fail(format!("{} is missing from the archive", binary.path));
        };
        s.binary = bytes.into_owned();
        1
    })
}

/// Take one file out of the archive, by its path inside the FMU.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn om_fmi_select_file(ptr: *const u8, len: usize) -> i32 {
    let name = String::from_utf8_lossy(unsafe { std::slice::from_raw_parts(ptr, len) }).into_owned();
    with(|s| {
        let Some(fmu) = s.fmu.as_ref() else { return fail("no FMU is loaded") };
        match fmu.read(&name) {
            Some(bytes) => {
                s.binary = bytes.into_owned();
                1
            }
            None => fail(format!("{name} is not in the archive")),
        }
    })
}

/// The `resources/` entries, as a JSON array in the out buffer: what the FMU
/// expects to find on its own filesystem.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_resource_names() -> i32 {
    with(|s| {
        let Some(fmu) = s.fmu.as_ref() else { return fail("no FMU is loaded") };
        let names: Vec<&str> = fmu.resources().collect();
        set_out(serde_json::to_string(&names).unwrap_or_else(|_| "[]".into()));
        1
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_binary_ptr() -> *const u8 {
    with(|s| s.binary.as_ptr())
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_binary_len() -> usize {
    with(|s| s.binary.len())
}

/// The model description as JSON, in the out buffer: what the page needs to
/// show the FMU and to build a run out of it.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_info() -> i32 {
    with(|s| {
        let Some(fmu) = s.fmu.as_ref() else { return fail("no FMU is loaded") };
        let info = describe(fmu);
        set_out(info.to_string());
        1
    })
}

/// Simulate, with the options the page passes as JSON:
/// `{"interface":"me"|"cs", "startTime":…, "stopTime":…, "stepSize":…,
///   "tolerance":…, "solver":"gbode"|"euler"|"rungekutta", "eventMode":bool,
///   "loggingOn":bool, "parameters":[{"vr":…,"value":…}],
///   "inputs":[{"vr":…,"expr":"sin(t)"}], "resultFile":"…"}`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn om_fmi_run(ptr: *const u8, len: usize) -> i32 {
    let text = String::from_utf8_lossy(unsafe { std::slice::from_raw_parts(ptr, len) }).into_owned();
    with(|s| {
        s.run = None;
        COLUMNS_PUBLISHED.with(|c| c.set(false));
        let options: Value = match serde_json::from_str(&text) {
            Ok(v) => v,
            Err(e) => return fail(format!("the run options are not JSON: {e}")),
        };
        let Some(fmu) = s.fmu.as_ref() else { return fail("no FMU is loaded") };
        match run(fmu, &options) {
            Ok(run) => {
                s.run = Some(run);
                1
            }
            Err(e) => fail(e),
        }
    })
}

/// The finished run as JSON — the columns, the statistics, the event times — in
/// the out buffer. The sample values themselves stay in wasm memory
/// ([`om_fmi_rows_ptr`]).
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_result() -> i32 {
    with(|s| {
        let Some(run) = s.run.as_ref() else { return fail("nothing has been simulated") };
        let columns = columns_json(&run.recorder)["columns"].clone();
        let parameters: Vec<Value> = run
            .recorder
            .parameters()
            .map(|(name, value)| json!({ "name": name, "value": value }))
            .collect();
        set_out(json!({
            "rows": run.recorder.len(),
            "stride": run.recorder.stride(),
            "columns": columns,
            "parameters": parameters,
            "summary": run.summary,
        })
        .to_string());
        1
    })
}

/// The samples: `stride` values per row, the time first.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_rows_ptr() -> *const f64 {
    with(|s| s.run.as_ref().map_or(std::ptr::null(), |r| r.recorder.raw().as_ptr()))
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_rows_len() -> usize {
    with(|s| s.run.as_ref().map_or(0, |r| r.recorder.raw().len()))
}

/// Write the result file, through WASI like every other file a simulation
/// writes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn om_fmi_write_mat(ptr: *const u8, len: usize) -> i32 {
    let path = String::from_utf8_lossy(unsafe { std::slice::from_raw_parts(ptr, len) }).into_owned();
    with(|s| {
        let Some(run) = s.run.as_ref() else { return fail("nothing has been simulated") };
        let (start, stop) = (
            run.summary["startTime"].as_f64().unwrap_or(0.0),
            run.summary["stopTime"].as_f64().unwrap_or(0.0),
        );
        match run.recorder.write_mat(std::path::Path::new(&path), start, stop) {
            Ok(()) => 1,
            Err(e) => fail(e),
        }
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_out_ptr() -> *const u8 {
    OUT.with(|o| o.borrow().as_ptr())
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_out_len() -> usize {
    OUT.with(|o| o.borrow().len())
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_error_ptr() -> *const u8 {
    ERROR.with(|e| e.borrow().as_ptr())
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_error_len() -> usize {
    ERROR.with(|e| e.borrow().len())
}

fn causality_name(c: Causality) -> &'static str {
    match c {
        Causality::Parameter => "parameter",
        Causality::CalculatedParameter => "calculatedParameter",
        Causality::Input => "input",
        Causality::Output => "output",
        Causality::Local => "local",
        Causality::Independent => "independent",
        Causality::StructuralParameter => "structuralParameter",
    }
}

/// Everything the page shows about an FMU before it is run.
fn describe(fmu: &Fmu) -> Value {
    let md = &fmu.model_description;
    let interface = |kind: InterfaceKind| {
        md.interface(kind).map(|i| {
            json!({
                "modelIdentifier": i.model_identifier,
                "hasEventMode": i.has_event_mode,
                "mightReturnEarlyFromDoStep": i.might_return_early_from_do_step,
                "canHandleVariableCommunicationStepSize": i.can_handle_variable_communication_step_size,
                "fixedInternalStepSize": i.fixed_internal_step_size,
                "needsCompletedIntegratorStep": i.needs_completed_integrator_step,
                "providesDirectionalDerivatives": i.provides_directional_derivatives,
            })
        })
    };
    let e = md.default_experiment.unwrap_or_default();
    let variables: Vec<Value> = md
        .variables
        .iter()
        .map(|v| {
            json!({
                "name": v.name,
                "vr": v.value_reference,
                "description": v.description,
                "type": v.ty.as_str(),
                "causality": causality_name(v.causality),
                "variability": match v.variability {
                    Variability::Constant => "constant",
                    Variability::Fixed => "fixed",
                    Variability::Tunable => "tunable",
                    Variability::Discrete => "discrete",
                    Variability::Continuous => "continuous",
                },
                "unit": v.unit,
                "start": v.start.as_ref().and_then(|s| s.first_f64()),
                "numeric": v.ty.is_numeric(),
                "settable": v.is_settable(),
            })
        })
        .collect();
    json!({
        "fmiVersion": md.fmi_version_string,
        "modelName": md.model_name,
        "description": md.description,
        "generationTool": md.generation_tool,
        "instantiationToken": md.instantiation_token,
        "modelExchange": interface(InterfaceKind::ModelExchange),
        "coSimulation": interface(InterfaceKind::CoSimulation),
        "scheduledExecution": interface(InterfaceKind::ScheduledExecution),
        "defaultExperiment": {
            "startTime": e.start_time,
            "stopTime": e.stop_time,
            "stepSize": e.step_size,
            "tolerance": e.tolerance,
        },
        "numberOfContinuousStates": md.number_of_continuous_states(),
        "numberOfEventIndicators": md.number_of_event_indicators,
        "variables": variables,
        "toolAnnotations": md.tool_annotations.iter()
            .map(|a| json!({"name": a.name, "xml": a.xml}))
            .collect::<Vec<_>>(),
    })
}

fn options_from(md: &ModelDescription, o: &Value) -> Result<Options, Error> {
    let mut opts = Options::from_model_description(md);
    let num = |key: &str| o.get(key).and_then(Value::as_f64);
    opts.start_time = num("startTime").unwrap_or(opts.start_time);
    opts.stop_time = num("stopTime").unwrap_or(opts.stop_time);
    opts.step_size = num("stepSize").filter(|h| *h > 0.0).unwrap_or(opts.step_size);
    opts.tolerance = num("tolerance").filter(|t| *t > 0.0).or(opts.tolerance);
    opts.logging_on = o.get("loggingOn").and_then(Value::as_bool).unwrap_or(false);
    opts.event_mode = o.get("eventMode").and_then(Value::as_bool).unwrap_or(true);
    opts.directional_derivatives =
        o.get("directionalDerivatives").and_then(Value::as_bool).unwrap_or(true);
    opts.solver = o
        .get("solver")
        .and_then(Value::as_str)
        .and_then(Solver::parse)
        .unwrap_or_default();
    opts.progress = Some(report_progress);
    opts.cancelled = Some(cancelled);

    let variable_type = |vr: u64| -> VarType {
        md.variable_by_vr(vr as u32).map(|v| v.ty).unwrap_or(VarType::Float64)
    };
    for p in o.get("parameters").and_then(Value::as_array).into_iter().flatten() {
        let (Some(vr), Some(value)) =
            (p.get("vr").and_then(Value::as_u64), p.get("value").and_then(Value::as_f64))
        else {
            continue;
        };
        opts.parameters.push(Parameter {
            value_reference: vr as u32,
            ty: variable_type(vr),
            value,
        });
    }
    for i in o.get("inputs").and_then(Value::as_array).into_iter().flatten() {
        let (Some(vr), Some(text)) =
            (i.get("vr").and_then(Value::as_u64), i.get("expr").and_then(Value::as_str))
        else {
            continue;
        };
        let value = expr::Expr::parse(text)
            .map_err(|e| Error::Unsupported(format!("the input expression `{text}`: {e}")))?;
        opts.inputs.push(Input { value_reference: vr as u32, ty: variable_type(vr), value });
    }
    Ok(opts)
}

fn report_progress(time: f64, rec: &Recorder) {
    // The column layout is fixed for the run, so it is published once, before
    // the first batch of samples the page would plot.
    if !COLUMNS_PUBLISHED.with(std::cell::Cell::get) {
        set_out(columns_json(rec).to_string());
        COLUMNS_PUBLISHED.with(|c| c.set(true));
        unsafe { host_columns() };
    }
    let rows = rec.raw();
    unsafe { host_progress(time, rows.as_ptr(), rows.len(), rec.stride()) };
}

fn cancelled() -> bool {
    unsafe { host_cancelled() != 0 }
}

fn columns_json(rec: &Recorder) -> Value {
    let columns: Vec<Value> = rec
        .columns
        .iter()
        .map(|c| {
            json!({
                "name": c.name,
                "description": c.description,
                "unit": c.unit,
                "causality": causality_name(c.causality),
                "isState": c.is_state,
            })
        })
        .collect();
    json!({ "columns": columns, "stride": rec.stride() })
}

fn run(fmu: &Fmu, o: &Value) -> Result<Run, Error> {
    let md = &fmu.model_description;
    let wanted = match o.get("interface").and_then(Value::as_str) {
        Some("me") => Some(InterfaceKind::ModelExchange),
        Some("cs") => Some(InterfaceKind::CoSimulation),
        _ => None,
    };
    let kind = openmodelica_fmi_driver::choose_interface(md, wanted)?;
    let opts = options_from(md, o)?;

    match kind {
        InterfaceKind::CoSimulation => {
            let event_mode =
                opts.event_mode && md.interface(kind).is_some_and(|i| i.has_event_mode);
            let mut inst = HostFmu::instantiate(
                KIND_CO_SIMULATION,
                event_mode,
                true,
                opts.logging_on,
            )?;
            let r = cs::simulate(&mut inst as &mut dyn Fmi3CoSimulation, md, &opts)?;
            Ok(Run {
                summary: json!({
                    "interface": "cs",
                    "startTime": opts.start_time,
                    "stopTime": opts.stop_time,
                    "steps": r.steps,
                    "events": r.events,
                    "earlyReturns": r.early_returns,
                    "eventTimes": r.event_times,
                    "terminatedAt": r.terminated_at,
                    "cancelled": r.cancelled,
                }),
                recorder: r.recorder,
            })
        }
        InterfaceKind::ModelExchange => {
            let mut inst =
                HostFmu::instantiate(KIND_MODEL_EXCHANGE, false, false, opts.logging_on)?;
            let r = me::simulate(&mut inst as &mut dyn Fmi3ModelExchange, md, &opts)?;
            Ok(Run {
                summary: json!({
                    "interface": "me",
                    "startTime": opts.start_time,
                    "stopTime": opts.stop_time,
                    "steps": r.steps,
                    "calls": r.calls,
                    "jacobians": r.jacobians,
                    "stateEvents": r.state_events,
                    "timeEvents": r.time_events,
                    "eventTimes": r.event_times,
                    "terminatedAt": r.terminated_at,
                    "cancelled": r.cancelled,
                    "solver": opts.solver.as_str(),
                }),
                recorder: r.recorder,
            })
        }
        InterfaceKind::ScheduledExecution => {
            Err(Error::Unsupported("Scheduled Execution, which nothing drives yet".into()))
        }
    }
}
