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

use openmodelica_fmi::{Causality, Fmu, Initial, InterfaceKind, ModelDescription, VarType, Variability};
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

/// The FMU icon — `terminalsAndIcons/icon.svg` if there is one, else `icon.png`.
/// Bytes in the binary buffer, name as JSON in the out buffer; `0` for no icon.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_icon() -> i32 {
    with(|s| {
        let Some(fmu) = s.fmu.as_ref() else { return fail("no FMU is loaded") };
        for name in ["terminalsAndIcons/icon.svg", "terminalsAndIcons/icon.png"] {
            if let Some(bytes) = fmu.read(name) {
                s.binary = bytes.into_owned();
                set_out(json!({"name": name}).to_string());
                return 1;
            }
        }
        fail("the FMU carries no terminalsAndIcons icon")
    })
}

/// `{"entry":…, "files":[…]}` in the out buffer: the documentation entry point
/// (`index.html`, or FMI 1.0's `_main.html`) and the names beside it, which the
/// caller pulls through [`om_fmi_select_file`]. `0` when there is none.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi_documentation() -> i32 {
    with(|s| {
        let Some(fmu) = s.fmu.as_ref() else { return fail("no FMU is loaded") };
        let entry = ["documentation/index.html", "documentation/_main.html"]
            .into_iter()
            .find(|n| fmu.read(n).is_some());
        let Some(entry) = entry else { return fail("the FMU carries no documentation") };
        let files: Vec<&str> =
            fmu.names().iter().map(String::as_str).filter(|n| n.starts_with("documentation/")).collect();
        set_out(json!({"entry": entry, "files": files}).to_string());
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
///   "tolerance":…, "solver": one of the `solvers` [`om_fmi_info`] lists,
///   "eventMode":bool,
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
                "displayUnit": v.display_unit,
                "start": v.start.as_ref().and_then(|s| s.first_f64()),
                "numeric": v.ty.is_numeric(),
                "settable": v.is_settable(),
                // Together these name an editable start value: `derivative` the
                // state, `initial` whether the start is the model's.
                "derivative": v.derivative,
                "initial": v.initial.map(|i| match i {
                    Initial::Exact => "exact",
                    Initial::Approx => "approx",
                    Initial::Calculated => "calculated",
                }),
            })
        })
        .collect();
    // Alias name -> the variable carrying the data: an <Alias> shares its
    // variable's valueReference, so only the variable is ever recorded.
    let aliases: Value = md
        .variables
        .iter()
        .flat_map(|v| v.aliases.iter().map(move |a| (a.name.clone(), Value::from(v.name.clone()))))
        .collect::<serde_json::Map<String, Value>>()
        .into();
    // What each unit converts into, for the page's display-unit switch.
    let units: Value = md
        .units
        .iter()
        .map(|u| {
            let displays: Vec<Value> = u
                .display_units
                .iter()
                .map(|d| json!({
                    "name": d.name,
                    "factor": d.factor,
                    "offset": d.offset,
                    "inverse": d.inverse,
                }))
                .collect();
            (u.name.clone(), Value::from(displays))
        })
        .collect::<serde_json::Map<String, Value>>()
        .into();
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
        "version": md.version,
        "numberOfContinuousStates": md.number_of_continuous_states(),
        "numberOfEventIndicators": md.number_of_event_indicators,
        "variables": variables,
        "aliases": aliases,
        "units": units,
        // Whether the FMU declares fmi-ls-dae, so Model Exchange can be run over
        // its residuals instead of the ODE face the same FMU also serves.
        "lsDae": fmu.ls_dae_manifest().is_some(),
        "figures": md.figures().iter().map(figure_json).collect::<Vec<_>>(),
        "visualization": md.visualization().map(|v| json!({"file": v.file})),
        // Not the FMU's: what a run of it can be given, for the page's chooser.
        "solvers": Solver::all().iter()
            .map(|s| json!({"name": s.as_str(), "description": s.description()}))
            .collect::<Vec<_>>(),
        "toolAnnotations": md.tool_annotations.iter()
            .map(|a| json!({"name": a.name, "xml": a.xml}))
            .collect::<Vec<_>>(),
    })
}

fn figure_json(f: &openmodelica_fmi::Figure) -> Value {
    let axis = |a: &Option<openmodelica_fmi::Axis>| {
        a.as_ref().map(|a| json!({
            "label": a.label, "unit": a.unit, "min": a.min, "max": a.max, "log": a.log,
        }))
    };
    json!({
        "title": f.title,
        "group": f.group,
        "preferred": f.preferred,
        "caption": f.caption,
        "plots": f.plots.iter().map(|p| json!({
            "title": p.title,
            "preferred": p.preferred,
            "terminal": p.terminal,
            "curves": p.curves.iter()
                .map(|c| json!({"x": c.x, "y": c.y, "legend": c.legend}))
                .collect::<Vec<_>>(),
            "x": axis(&p.x), "y": axis(&p.y), "y2": axis(&p.y2),
        })).collect::<Vec<_>>(),
    })
}

fn options_from(md: &ModelDescription, o: &Value) -> Result<Options<'static>, Error> {
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
    let mut opts = options_from(md, o)?;

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
            // fmi-ls-dae: the FMU stays an ODE FMU until the master enables DAE
            // mode, after which the master sets the states, their derivatives and
            // the algebraic variables and reads the residuals back. Only IDA takes
            // that form, so the driver rejects any other solver itself.
            if o.get("daeMode").and_then(Value::as_bool).unwrap_or(false) {
                opts.dae = Some(match fmu.ls_dae_manifest() {
                    Some(Ok(m)) => m,
                    Some(Err(e)) => return Err(Error::Unsupported(format!("fmi-ls-dae manifest: {e}"))),
                    None => return Err(Error::Unsupported(
                        "DAE mode asks for fmi-ls-dae, which this FMU does not declare".to_string(),
                    )),
                });
            }
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
                    "daeMode": opts.dae.is_some(),
                }),
                recorder: r.recorder,
            })
        }
        InterfaceKind::ScheduledExecution => {
            Err(Error::Unsupported("Scheduled Execution, which nothing drives yet".into()))
        }
    }
}
