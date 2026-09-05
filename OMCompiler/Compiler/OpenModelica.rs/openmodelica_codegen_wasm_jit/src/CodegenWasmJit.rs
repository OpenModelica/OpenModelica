// Manually written file (the `CodegenWasmJit` MetaModelica package is a
// placeholder; see HANDWRITTEN_TOP_PACKAGES in mmtorust/src/codegen.rs).
//
// Simulation half of the `wasm-jit` target — the counterpart of `CodegenC` for
// the C target. Instead of generating ~25 C files + `_init.xml` + a makefile,
// building an executable and running it to write a `.mat`, this lowers the
// SimCode equation systems to a single WebAssembly *model module* (the
// numerical right-hand sides) and runs the simulation in-process with wasmer.
//
// Two design departures from the C runtime, per the project steer:
//   * No XML/JSON serialization of model metadata. The host (this Rust code)
//     holds the SimCode-derived data (variable names, start values, parameter
//     values, simulation settings) in memory and feeds it to the run / to the
//     `.mat` writer directly — the "expose SimCode data through host functions"
//     approach.
//   * The forward-Euler integrator loop runs *in wasm* (the precompiled runtime
//     primitives `rt_euler_step` / `rt_sim_store_row` plus an emitted `simulate`
//     loop), so the whole integration is a single host->wasm call with no
//     per-step boundary crossing (initialization stays with the shared driver).
//     A second, host-driven driver (the Euler loop in native
//     Rust, one wasm call per step) is provided for benchmarking — selected with
//     `OMC_WASM_SIM_DRIVER=host`.
//
// ## SimData memory layout
//
// All model state lives in one `SimData` block (allocated with the runtime's
// `rt_alloc`) of contiguous little-endian slots:
//
//   [ time:f64 | realVars:f64[2*nStates + nAlgs] | realParams:f64[nRP]
//     | intVars:i32[nIA] | intParams:i32[nIP] | boolVars:i32[nBA] | boolParams:i32[nBP] ]
//
// `realVars` is ordered `[states | derivatives | algebraics]`, matching the C
// runtime's `realVars` ordering. Every model variable therefore has a
// compile-time-constant byte offset; the generated equation functions take the
// `SimData` pointer as their single parameter and access a variable with one
// `f64.load`/`f64.store` (or `i32.*`) at that offset. A result-buffer row is the
// time-variant prefix `[time | realVars]` (`n_reals = 1 + 2*nStates + nAlgs`
// f64), so emitting a row is a copy of the first `n_reals` slots of `SimData`.

#![allow(non_snake_case)]

use std::collections::{BTreeMap, HashMap, HashSet};
use std::sync::{Mutex, OnceLock};
use std::sync::Arc;

use metamodelica::Result;
use arcstr::ArcStr;
use metamodelica::List;
use wasm_encoder as we;

use openmodelica_backend_types::BackendDAE;
use openmodelica_frontend_types::DAE;
use openmodelica_simcode_types::SimCode;
use openmodelica_simcode_types::SimCodeVar;
use openmodelica_simcode_types::SimCodeFunction;
use openmodelica_frontend_dump::ComponentReferenceBasics;

use crate::CodegenWasmJitFunctions::{
    ArrayGroup, Attr, AttrTargets, BUILTINS, ConstGroup, ENV_EXTRA, ExtCallSig, FnCtx, FnInfo, Literals, NLS_BASE_GLOBAL, NLS_HIST_GLOBAL, NlsJob, RT_BUILTINS,
    ProfPlan, ScatterGroup, SimCtx, SimSlot, WTy, WTyVal, compile_function, compile_linear_system, compile_linear_system_analytic,
    compile_linear_system_analytic_csc, compile_linear_system_symbolic,
    ClockInit, ClockUpdate,
    NlsResidual, NlsResiduals, backup_known_outputs, residual_rows, restore_known_outputs,
    emit_nls_load_body, emit_nls_jac_body, emit_nls_jac_csc_body, nls_use_sparse,
    emit_entwined_assign, emit_generic_assign, emit_resizable_assign,
    emit_nls_residual_body, emit_solve_nls_call, external_import_sig, external_known,
    external_general_why, note_declined_external, reset_declined_externals,
    function_signature, rt_index, sim_cref_key, sim_const_store,
    emit_sim_const_stores,
};

// The `SimData` layout, result-variable descriptors, and solver metadata are
// defined once in `openmodelica_sim_meta` and shared with the in-wasm driver, so
// the emitted module and the driver's readback cannot drift. Aliased to their
// historical host names.
use openmodelica_sim_meta::omclog;
use openmodelica_sim_meta::simflags;
use openmodelica_sim_meta::{
    var_filter, BaseClockMeta, BaseUnit, DisplayUnit, FmiVr, JacAInfo, Layout as SimLayout,
    MetaKind as ResultKind, MetaVar as ResultVar, Neg, SimMeta, StateSetInfo, SubClockMeta,
    UnitDef, VarTy,
};

// Engine selected at compile time; same module interface across all three
// (mirrors the block in CodegenWasmJitFunctions.rs, including the misconfig
// guards). The `SimModel` below stores compiled modules as `sim_runtime::Module`.
// Engine, model data and driver flags live in `openmodelica_wasm_jit`; the
// orchestration below keeps its `sim_runtime::`/`SimModel` paths via these.
use openmodelica_sim_meta::result::MatLayout;
use openmodelica_wasm_jit::result_sink::{ResultTarget, Written};
use openmodelica_wasm_jit::{sim_driver, sim_runtime};
#[cfg(feature = "jit")]
use openmodelica_wasm_jit::wasi_shim;
pub(crate) use openmodelica_wasm_jit::model::{
    EditableParam, ExtArchives, ExtIncludes, ExtLibrary, ModelCompileJob, SimModel,
};
#[cfg(feature = "jit")]
pub use openmodelica_wasm_jit::model::{set_inwasm_driver_override, set_sim_bench};
#[cfg(feature = "jit")]
pub(crate) use openmodelica_wasm_jit::model::{
    encode_overrides, inwasm_driver_enabled, sim_bench_enabled, INWASM_SLOT_NAMES,
};

#[path = "CodegenWasmJit/native_fmu.rs"]
pub(crate) mod native_fmu;

#[path = "CodegenWasmJit/linearize.rs"]
pub(crate) mod linearize;

#[path = "CodegenWasmJit/optimization.rs"]
pub(crate) mod optimization;

#[path = "CodegenWasmJit/datarecon.rs"]
pub(crate) mod datarecon;

#[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
#[path = "CodegenWasmJit/artifact.rs"]
pub(crate) mod artifact;

#[cfg(all(feature = "artifact", feature = "jit", not(target_arch = "wasm32")))]
#[path = "CodegenWasmJit/dylink_fmi.rs"]
pub(crate) mod dylink_fmi;

/// Iterate a MetaModelica `List` (which is `IntoIterator` by reference, not via
/// an `.iter()` method).
pub(crate) fn lst<T: Clone>(l: &Arc<List<T>>) -> impl Iterator<Item = &T> {
    (&**l).into_iter()
}

// ===========================================================================
// SimData layout
// ===========================================================================

/// Byte offset of `time` within `SimData`.
const TIME_OFF: u32 = 0;
/// Byte offset of the first real variable (`realVars[0]`, a state).
const REAL_OFF: u32 = 8;



/// Solver statistics, filled by the driver (now `openmodelica_sim_meta`, shared
/// with the in-wasm driver) and rendered here into the `LOG_STATS` block.
pub(crate) use openmodelica_sim_meta::SolveStats;


/// Process-wide table of prepared models, keyed by file-name prefix. Populated
/// by `translateModel` (during `callTargetTemplates`) and read by
/// `runSimulation` (during `simulate`) in the same process.
fn sim_models() -> &'static Mutex<HashMap<String, Arc<SimModel>>> {
    static MODELS: OnceLock<Mutex<HashMap<String, Arc<SimModel>>>> = OnceLock::new();
    MODELS.get_or_init(|| Mutex::new(HashMap::new()))
}

/// A model kernel a wasm FMU can be built around. Only kernels an export can
/// actually use are kept, so finding one is the whole test.
struct FmuKernel {
    model: Arc<SimModel>,
    /// Reaches the kernel's embedded metadata, so a different one cannot reuse it.
    cs_method: String,
    fmi_solver_flags: String,
}

/// Kept by [`translateFmu`] so the export that follows links this kernel rather
/// than lowering it again. Keyed by file-name prefix.
fn fmu_kernels() -> &'static Mutex<HashMap<String, Arc<FmuKernel>>> {
    static KERNELS: OnceLock<Mutex<HashMap<String, Arc<FmuKernel>>>> = OnceLock::new();
    KERNELS.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Where a captured signal's values live: a `data_2` column of the result file
/// (negated for a `-v` alias), or one time-invariant value.
#[derive(Clone, Copy)]
pub enum SeriesData {
    Column { col: usize, negate: bool },
    Scalar(f64),
}

/// One captured result signal. Its values are read out of the result file on
/// demand ([`CapturedSim::values`]).
pub struct SimSeries {
    pub name: String,
    pub comment: String,
    pub unit: String,
    /// The unit it is preferably plotted in, a display unit of `unit`.
    pub display_unit: String,
    /// FMI's `relativeQuantity`: a difference in the unit, so a conversion to a
    /// display unit scales it but adds no offset.
    pub relative_quantity: bool,
    /// Time-invariant (parameter, constant, or computed once at initialization) —
    /// the web simulator hides these from the default plot ("all non-constant vars").
    pub constant: bool,
    /// This signal aliases the same underlying data as an earlier series (e.g.
    /// `der(h)` and `v` when `v = der(h)`): plotting one of them suffices.
    pub alias: bool,
    pub data: SeriesData,
}

/// A parameter's value after the run, with the metadata a host needs to show it
/// as an editable initial condition.
pub struct CapturedParam {
    pub name: String,
    pub comment: String,
    pub unit: String,
    pub display_unit: String,
    pub relative_quantity: bool,
    pub value: f64,
    /// Enumeration literal names (1-based index → name), empty for non-enum.
    pub enum_names: Vec<String>,
}

/// The last run's results: the per-signal metadata plus where each kept signal
/// sits in the `.mat` the run wrote, so a host (the web simulator) reads a column
/// straight out of that file. `series` excludes `time`.
pub struct CapturedSim {
    pub model_name: String,
    pub start_time: f64,
    pub stop_time: f64,
    pub result_file: String,
    n_rows: usize,
    layout: Option<MatLayout>,
    pub series: Vec<SimSeries>,
    pub params: Vec<CapturedParam>,
    /// The units the signals and parameters name, defined: what a host needs to
    /// plot or edit a value in its display unit.
    pub units: Vec<openmodelica_sim_meta::UnitDef>,
    /// Solver counters, so a host with no stdout can tell a run that did more work
    /// from one that did the same work slower.
    pub stats: SolveStats,
}

impl CapturedSim {
    pub fn n_rows(&self) -> usize {
        self.n_rows
    }

    fn column(&self, col: usize, negate: bool) -> Vec<f64> {
        let Some(l) = &self.layout else { return Vec::new() };
        openmodelica_wasi::fs::with_bytes(&self.result_file, |b| l.column(b, col, negate)).unwrap_or_default()
    }

    /// The independent `time` column.
    pub fn time(&self) -> Vec<f64> {
        self.column(0, false)
    }

    /// The values of `series[index]` over the run (length 1 for a time-invariant
    /// signal), or `None` when out of range.
    pub fn values(&self, index: usize) -> Option<Vec<f64>> {
        Some(match self.series.get(index)?.data {
            SeriesData::Column { col, negate } => self.column(col, negate),
            SeriesData::Scalar(v) => vec![v],
        })
    }
}

fn last_sim() -> &'static Mutex<Option<CapturedSim>> {
    static LAST: OnceLock<Mutex<Option<CapturedSim>>> = OnceLock::new();
    LAST.get_or_init(|| Mutex::new(None))
}

/// Stash a finished run's per-signal metadata and the result file's layout for
/// the host to read directly.
fn capture_last_sim(
    model: &SimModel,
    written: Written,
    params: &[f64],
    stats: &SolveStats,
    keep: &[bool],
    result_file: &str,
) {
    let Written { n_rows, layout } = written;
    let first_row: &[f64] = layout.as_ref().map_or(&[], |l| &l.first_row);
    let unit_of = |name: &str| model.var_units.get(name).cloned().unwrap_or_default();
    let mut series = Vec::new();
    let mut param_idx = 0usize;
    // The kept signals are the file's, in order; `file_ix` is the next one's index.
    let mut file_ix = 0usize;
    // A signal aliases an earlier one when it reads the same underlying data: the
    // same result column, or the same parameter slot (the `.mat`'s `dataInfo`
    // aliasing — several names, one stored column). Distinct columns are distinct
    // signals even when an equation keeps them near-equal (`der(h) = v` differs at
    // event rows), so both are plotted. First occurrence is canonical.
    let mut seen_cols = HashSet::new();
    let mut seen_param_offs = HashSet::new();
    let mut param_value_by_off: HashMap<u32, f64> = HashMap::new();
    // Row 0 of every signal, for the start values of the editable parameters.
    let mut row0_by_name: HashMap<&str, f64> = HashMap::new();
    for (v, &kept) in model.result_vars.iter().zip(keep) {
        let k = kept.then(|| {
            file_ix += 1;
            file_ix - 1
        });
        let (alias, row0, data) = match &v.kind {
            ResultKind::Time => continue,
            ResultKind::Column { col, negate } => {
                let col = *col as usize;
                let row0 = negate.apply_f64(first_row.get(col).copied().unwrap_or(0.0));
                let data = k.zip(layout.as_ref()).and_then(|(k, l)| match l.data2_col(k) {
                    Some((col, negate)) => Some(SeriesData::Column { col, negate }),
                    None => l.data1_value(k).map(SeriesData::Scalar),
                });
                (!seen_cols.insert(col), row0, data)
            }
            ResultKind::Param { off, negate, .. } => {
                let raw = params.get(param_idx).copied().unwrap_or(0.0);
                param_idx += 1;
                param_value_by_off.entry(*off).or_insert(raw);
                let value = negate.apply_f64(raw);
                (!seen_param_offs.insert(*off), value, Some(SeriesData::Scalar(value)))
            }
            ResultKind::Const { value } => (false, *value, Some(SeriesData::Scalar(*value))),
        };
        row0_by_name.entry(v.name.as_str()).or_insert(row0);
        if let (true, Some(data)) = (kept, data) {
            series.push(SimSeries {
                name: v.name.clone(),
                comment: v.comment.clone(),
                unit: unit_of(&v.name),
                display_unit: v.display_unit.clone(),
                relative_quantity: v.relative_quantity,
                constant: matches!(data, SeriesData::Scalar(_)),
                alias,
                data,
            });
        }
    }
    // A start value shows the state's t0 value; a plain parameter shows its slot.
    let params: Vec<CapturedParam> = model
        .editable_params
        .iter()
        .filter(|p| !p.is_string)
        .map(|p| CapturedParam {
            name: p.name.clone(),
            comment: p.comment.clone(),
            unit: p.unit.clone(),
            display_unit: p.display_unit.clone(),
            relative_quantity: p.relative_quantity,
            value: if p.is_start {
                row0_by_name.get(p.name.as_str()).copied().unwrap_or(0.0)
            } else {
                param_value_by_off.get(&p.off).copied().unwrap_or(0.0)
            },
            enum_names: p.enum_names.clone(),
        })
        .collect();
    *last_sim().lock().unwrap_or_else(|e| e.into_inner()) = Some(CapturedSim {
        model_name: model.model_name.clone(),
        start_time: model.start_time,
        stop_time: model.stop_time,
        result_file: result_file.to_string(),
        n_rows,
        layout,
        series,
        params,
        units: model.meta.units.iter().cloned().map(|mut u| {
            u.add_predefined_display_units();
            u
        }).collect(),
        stats: stats.clone(),
    });
}

/// Run `f` with the last captured simulation results, if any. Lets a host read
/// signal data directly out of the runtime instead of parsing a result file.
pub fn with_last_sim<R>(f: impl FnOnce(&CapturedSim) -> R) -> Option<R> {
    last_sim().lock().unwrap_or_else(|e| e.into_inner()).as_ref().map(f)
}

/// Write `bytes` to `path`: the OS filesystem natively, or the in-memory VFS on
/// wasm (where there is no filesystem — the `.wasm` dump, `.log` and result file
/// land there for the JS host / `getSimulationResult` to read back).
fn write_output(path: &str, bytes: &[u8]) -> std::io::Result<()> {
    openmodelica_wasi::fs::write(path, bytes)
}

/// C's `fileSize(outputFilename)`, which the `+profiling` report quotes: `-1` when
/// the file is not there.
fn output_size(path: &str) -> i64 {
    openmodelica_wasi::fs::len(path).map(|n| n as i64).unwrap_or(-1)
}

// ===========================================================================
// Public entry points (called from the MetaModelica sources after regen)
// ===========================================================================

/// Record the reason as an `INTERNAL_ERROR` so `getErrorString()` (and OMEdit)
/// show it and the scripting layer treats the build as failed. Does NOT panic: a
/// panic traps the wasm instance, after which the buffered error can't be read
/// back (the web omc then reports a bare "Translation failed"). Callers return
/// after this instead — an unsupported construct is a normal failure, not a crash.
/// The position is the Rust call site, as `sourceInfo()` gives a MetaModelica
/// `addInternalError`.
#[track_caller]
pub(crate) fn record_error(msg: String) {
    let loc = std::panic::Location::caller();
    let _ = openmodelica_util::Error::addInternalError(
        ArcStr::from(msg.as_str()),
        metamodelica::SourceInfo {
            fileName: ArcStr::from(loc.file()),
            isReadOnly: false,
            lineNumberStart: loc.line() as i32,
            columnNumberStart: loc.column() as i32,
            lineNumberEnd: loc.line() as i32,
            columnNumberEnd: loc.column() as i32,
            lastModification: metamodelica::OrderedFloat(0.0),
        },
    );
}

/// `e` plus the engine's own message (trap kind + wasm backtrace) that the
/// `&'static str` error dropped — but not for a model `assert()`, which already
/// reported itself.
fn with_engine_detail(e: &str) -> String {
    let detail = openmodelica_wasm_jit::take_engine_error_detail();
    let e = match (sim_driver::init_failed_lambda(), sim_driver::failed_nls_system()) {
        (Some(l), Some(k)) if e.ends_with("at lambda") => {
            format!("{e} = {l} (nonlinear system {k})")
        }
        _ => e.to_string(),
    };
    match detail {
        Some(d) if e != sim_driver::ASSERT_ERR => format!("{e}\n{d}"),
        _ => e,
    }
}

/// Mirror `-n` into the engine, before anything reaches the JIT.
fn sync_engine_threading() -> Result<()> {
    openmodelica_wasm_jit::model::set_single_threaded(openmodelica_util::Config::noProc()? == 1);
    Ok(())
}

/// `CodegenWasmJit.translateModel`: lower `simCode` to a model wasm module, write
/// `<prefix>.wasm`, and stash the prepared [`SimModel`] for the later
/// `runSimulation`. On a lowering error the message is recorded to the Error
/// buffer (so `getErrorString` / OMEdit show it) and the failure is returned so
/// translation fails — as the other codegen targets do — never a stderr print or
/// a panic (a panic would trap the wasm instance and lose the buffered message).
pub fn translateModel(simCode: SimCode::SimCode) -> Result<()> {
    sync_engine_threading()?;
    sim_runtime::start_runtime_compile();
    let prefix = simCode.fileNamePrefix.to_string();
    let _ = std::fs::remove_file(format!("{prefix}.wasm"));
    let errs_before = openmodelica_util::Error::getNumErrorMessages();
    let outcome = build_sim_model(&simCode, false, ExtHost::SIM, "", "").and_then(|model| {
        write_output(&format!("{prefix}.wasm"), &model.wasm).map_err(|_| "CodegenWasmJit: write failed")?;
        sim_models().lock().unwrap_or_else(|e| e.into_inner()).insert(prefix.clone(), Arc::new(model));
        Ok(())
    });
    if let Err(e) = &outcome {
        if openmodelica_util::Error::getNumErrorMessages() == errs_before {
            record_error(format!(
                "CodegenWasmJit: cannot build simulation module for `{prefix}`: {}",
                with_engine_detail(e)
            ));
        }
    }
    outcome
}

/// `CodegenWasmJit.runSimulation`: run the prepared model in-process and write
/// the result file. Returns 0 on success, 1 on failure (matching the exit code
/// the C target's executable would return, which `simulate` checks).
/// The initialization success line, from the homotopy-step count the last
/// `run_initialization` recorded (0 → "without homotopy method").
fn init_success_line() -> String {
    let steps = sim_driver::init_homotopy_steps();
    if steps == 0 {
        "LOG_SUCCESS       | info    | The initialization finished successfully without homotopy method.".to_string()
    } else {
        let local = if sim_driver::init_homotopy_local() { "local " } else { "" };
        format!("LOG_SUCCESS       | info    | The initialization finished successfully with {steps} {local}homotopy steps.")
    }
}

/// A run reports itself through `<prefix>.log` alone, which `simulate` returns as
/// `messages` — as C's separate simulation executable does. Whatever it left in the
/// Error buffer would also surface from `getErrorString()`, where C returns "".
const RUN_CHECKPOINT: ArcStr = arcstr::literal!("wasm-jit simulation run");

pub fn runSimulation(fileNamePrefix: ArcStr, resultFile: ArcStr, simflags: ArcStr) -> i32 {
    let (mut prefix, mut result_file) = (fileNamePrefix.to_string(), resultFile.to_string());
    // `resimulateExecutable` may name a wasm artifact: its own simulation is the
    // model this session exported, run the ordinary way, while an FMI face or an
    // artifact from elsewhere runs inside it.
    #[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
    if let Some(path) = artifact::locate(&fileNamePrefix) {
        match artifact::translated(&path, &simflags) {
            Some(p) => {
                prefix = p;
                result_file = artifact::plain_result_name(&resultFile);
            }
            None => return run_artifact(&path, &fileNamePrefix, &resultFile, &simflags),
        }
    }
    openmodelica_error::ErrorExt::setCheckpoint(RUN_CHECKPOINT);
    let (res, init_output, sim_output, post_output) = run_simulation_inner(&prefix, &result_file, &simflags);
    openmodelica_error::ErrorExt::rollBack(RUN_CHECKPOINT);
    // `simulate` reads `<prefix>.log` after a run; the model's captured stdout
    // (`print`, LOG_STATS, ...) is folded in so it shows in the log rather than the
    // process console.
    let init_line = init_success_line();
    // A failed run keeps the init line too, as C does.
    let init_done = init_output.is_some();
    let init_out = init_output.unwrap_or_default();
    let init_seg = if init_done { format!("{init_out}{init_line}\n") } else { init_out };
    let log = match &res {
        // Init prints, the init line, then the sim prints and the final success.
        Ok(()) => format!(
            "{init_seg}{sim_output}\
             LOG_SUCCESS       | info    | The simulation finished successfully.\n{post_output}"
        ),
        // Chattering abort (`-abortSlowSimulation`): the driver's output carries the
        // chattering + aborting lines.
        Err(e) if *e == sim_driver::CHATTER_ABORT_ERR => format!("{init_seg}{sim_output}"),
        // A failed assertion, initialization or integrator has logged its own
        // reason (`LOG_ASSERT` / `LOG_INIT` / `model terminate`).
        Err(e)
            if *e == sim_driver::ASSERT_ERR
                || *e == sim_driver::INIT_FAILED_ERR
                || *e == sim_driver::SOLVER_FAILED_ERR =>
        {
            format!("{init_seg}{sim_output}")
        }
        Err(e) => format!(
            "{init_seg}{sim_output}LOG_ERROR         | error   | wasm-jit simulation failed: {}\n",
            with_engine_detail(e)
        ),
    };
    // C's `freeNonlinearSystems`, the last thing a simulation executable logs.
    let log = if openmodelica_sim_meta::omclog::active(openmodelica_sim_meta::omclog::NLS) {
        format!("{log}LOG_NLS           | info    | free non-linear system solvers\n")
    } else {
        log
    };
    let _ = write_output(&format!("{fileNamePrefix}.log"), log.as_bytes());
    // Error is in `<prefix>.log` (hence the result `messages`); no stderr.
    match res {
        Ok(()) => 0,
        Err(_) => 1,
    }
}

/// Simulate an exported wasm artifact. The three faces (`-s fmi3:me[:solver]`,
/// `-s fmi3:cs`, and the artifact's own simulation runtime otherwise) all report
/// themselves through `<prefix>.log`, as a run of a translated model does.
#[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
fn run_artifact(path: &std::path::Path, prefix: &str, result_file: &str, simflags: &str) -> i32 {
    let (face, rest) = match artifact::select_face(simflags) {
        Ok(v) => v,
        Err(e) => {
            let _ = write_output(&format!("{prefix}.log"), format!("LOG_ERROR         | error   | {e}\n").as_bytes());
            return 1;
        }
    };
    let (res, mut log) = artifact::run(path, face, result_file, &rest);
    match &res {
        Ok(()) => log.push_str("LOG_SUCCESS       | info    | The simulation finished successfully.\n"),
        Err(e) => log.push_str(&format!("LOG_ERROR         | error   | {e}\n")),
    }
    let _ = write_output(&format!("{prefix}.log"), log.as_bytes());
    if res.is_ok() { 0 } else { 1 }
}

/// `CodegenWasmJit.finishCompile`: force the model's wasm modules to finish
/// compiling. Called from `buildModel`'s compile phase (the wasm-jit counterpart
/// of `compileModel` building the C executable) so the JIT-compile cost is
/// measured as `timeCompile` rather than leaking into `timeSimulation`. It joins
/// the background model-module compile (started by `translateModel`) and forces
/// the runtime module (compiled-once / AOT-cached), stashing the compiled model
/// module for `runSimulation`. A JIT-compile error is deferred — `runSimulation`
/// recompiles and reports it — but the `external "C"` implementations are resolved
/// here, so a broken `Include` fails the build rather than the run.
pub fn finishCompile(fileNamePrefix: ArcStr) -> Result<()> {
    let model = sim_models().lock().unwrap_or_else(|e| e.into_inner()).get(&fileNamePrefix.to_string()).cloned();
    let Some(model) = model else { return Ok(()) };
    // Force the runtime module (so its compile/cache-load is in `timeCompile`).
    let _ = sim_runtime::runtime_module();
    // Join the background model-module compile and stash the result.
    match sim_runtime::take_compiled_model(&model) {
        Ok(m) => *model.prepared.lock().unwrap_or_else(|e| e.into_inner()) = Some(m),
        // Deferred: `runSimulation` recompiles and reports the error via the log.
        Err(_) => {}
    }
    let missing = missing_ext_symbols(&model.ext_imports, &model.ext_libs);
    if let Err(e) = sim_runtime::prepare_native_externals(&model, &missing) {
        record_error(format!("CodegenWasmJit: the model's `external \"C\"` implementations are unavailable:\n{e}"));
        return Err("CodegenWasmJit: external \"C\" implementation unavailable");
    }
    Ok(())
}

/// `CodegenWasmJit.emitStandalone`: the `wasm` simCodeTarget's counterpart of
/// [`translateModel`]. Lower the model and `wasm-merge` it with the wasip1 runtime
/// into a self-contained WASI *command* module written to `<prefix>.wasm`, runnable
/// with `wasmtime run <prefix>.wasm --dir .::.` ([`runSimulationWasmtime`]). Unlike
/// `translateModel` it neither JIT-compiles nor stashes the model — the run is a
/// separate `wasmtime` process. Native only (the omc wasm build cannot `wasm-merge`).
/// A failure is recorded to the Error buffer and returned so translation fails.
#[cfg(not(target_arch = "wasm32"))]
pub fn emitStandalone(simCode: SimCode::SimCode) -> Result<()> {
    let prefix = simCode.fileNamePrefix.to_string();
    let _ = std::fs::remove_file(format!("{prefix}.wasm"));
    let bytes = emit_standalone_module(&simCode).map_err(|e| {
        record_error(format!("CodegenWasmJit: cannot build standalone module for `{prefix}`: {e:#}"));
        e
    })?;
    write_output(&format!("{prefix}.wasm"), &bytes).map_err(|e| {
        record_error(format!("CodegenWasmJit: cannot write {prefix}.wasm: {e:#}"));
        "CodegenWasmJit: cannot write standalone wasm"
    })?;
    Ok(())
}

/// The omc wasm build cannot `wasm-merge` the standalone module; record why and
/// fail so translation reports it rather than emitting a silent empty module.
#[cfg(target_arch = "wasm32")]
pub fn emitStandalone(simCode: SimCode::SimCode) -> Result<()> {
    let _ = simCode;
    let msg = "CodegenWasmJit: simCodeTarget=wasm (standalone export) is unavailable in the wasm omc build";
    record_error(msg.to_string());
    return Err(msg)
}

/// `CodegenWasmJit.runSimulationWasmtime`: run the standalone module emitted by
/// [`emitStandalone`] in a `wasmtime` subprocess (the `wasm` target's counterpart
/// of [`runSimulation`]). The module's `_start` writes `<prefix>_res.mat` via WASI;
/// returns 0 on success, 1 on failure (matching the C executable's exit code).
pub fn runSimulationWasmtime(fileNamePrefix: ArcStr, resultFile: ArcStr, simflags: ArcStr) -> i32 {
    let res = run_wasmtime_inner(&fileNamePrefix, &resultFile, &simflags);
    // The simulate flow reads `<prefix>.log` after a run (the C target's executable
    // writes one); mirror runSimulation so the success path is taken.
    let log = match &res {
        Ok(()) => "LOG_SUCCESS       | info    | The initialization finished successfully without homotopy method.\n\
                    LOG_SUCCESS       | info    | The simulation finished successfully.\n"
            .to_string(),
        Err(e) => format!("LOG_ERROR         | error   | wasm standalone simulation failed: {e:#}\n"),
    };
    let _ = write_output(&format!("{fileNamePrefix}.log"), log.as_bytes());
    // Error already captured in `<prefix>.log` / the result `messages`; no stderr.
    match res {
        Ok(()) => 0,
        Err(_) => 1,
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn run_wasmtime_inner(prefix: &str, result_file: &str, _simflags: &str) -> Result<()> {
    use std::process::Command;
    let module = format!("{prefix}.wasm");
    if !std::path::Path::new(&module).exists() {
        return Err("standalone module not found (emitStandalone not run?)");
    }
    let wasmtime = std::env::var("OMC_WASMTIME").unwrap_or_else(|_| "wasmtime".to_owned());
    // `--dir .::.` preopens the cwd as the guest `.`; the module writes the result
    // file there with a relative path. `-W all-proposals=y` matches the `-all` given
    // to `wasm-merge`: models with nonlinear systems use a funcref table + `ref.func`
    // (reference-types / function-references), which the CLI otherwise rejects with
    // "heap types not supported without the gc feature". (The interactive wasmtime
    // crate enables these by default.)
    let status = Command::new(&wasmtime)
        .arg("run")
        .arg("-W")
        .arg("all-proposals=y")
        .arg("--dir")
        .arg(".::.")
        .arg(&module)
        .status()
        .map_err(|e| "cannot run (is it on PATH? override with OMC_WASMTIME)")?;
    if !status.success() {
        return Err("` run ` failed with");
    }
    // The module writes `<prefix>_res.mat`; rename if omc selected another name.
    let produced = format!("{prefix}_res.mat");
    if result_file != produced && std::path::Path::new(&produced).exists() {
        std::fs::rename(&produced, result_file)
            .map_err(|e| "cannot rename ->")?;
    }
    Ok(())
}

#[cfg(target_arch = "wasm32")]
fn run_wasmtime_inner(_prefix: &str, _result_file: &str, _simflags: &str) -> Result<()> {
    return Err("CodegenWasmJit: simCodeTarget=wasm is unavailable in the wasm omc build")
}

// Runs the model and returns its captured stdout/stderr (the model's runtime
// output — Modelica `Streams.print`, `ModelicaMessage`, …) alongside the result.
// Capturing keeps that output out of the process stdout (the browser console on
// the web target) so the caller can fold it into the simulation log.
/// Whether the driver that will run the model has CVODE and IDA: the host one links
/// the native archives, the in-wasm one (always, on the web) the wasm archives in the
/// runtime blob.
const SUNDIALS_DRIVER: bool =
    openmodelica_sim_meta::IDA || (cfg!(target_arch = "wasm32") && openmodelica_wasm_jit::SUNDIALS);

/// What the wasm-jit runtimes can serve, for `simflags::check`. Checked at the host
/// parse, where a rejection still has a message channel to report on.
const CAPABILITIES: simflags::Capabilities = simflags::Capabilities {
    klu: openmodelica_wasm_jit::SUNDIALS,
    kinsol: openmodelica_wasm_jit::SUNDIALS,
    umfpack: openmodelica_wasm_jit::SUNDIALS,
    lis: openmodelica_wasm_jit::SUNDIALS,
    ida: SUNDIALS_DRIVER,
    cvode: SUNDIALS_DRIVER,
    // Served by the driver's per-step deadline, so every engine has it.
    alarm: true,
    // The `.mat` is written here, where a regex engine is available.
    variable_filter: true,
    // `optimize()`'s solver: the host-driven driver's Ipopt.
    optimization: openmodelica_sim_meta::optimization::AVAILABLE,
    // A `simulate()` run drives the whole trajectory, which is all QSS can do.
    qss: true,
};

/// The solver values a caller may offer for this build, so a menu built from it
/// cannot disagree with [`install_sim_flags`]'s check.
pub fn solver_options() -> Vec<(&'static str, Vec<&'static str>)> {
    simflags::supported(CAPABILITIES)
}

/// What an exported wasm FMU *could* serve: every solver, each a PIC side module the
/// FMU linker adds beside the model. What a given FMU carries is narrower —
/// [`fmu_solver_libraries`] picks from the flags it was exported with.
fn fmu_capabilities() -> simflags::Capabilities {
    simflags::Capabilities {
        klu: sundials_available(),
        kinsol: sundials_available(),
        umfpack: sundials_available(),
        lis: sundials_available(),
        ida: sundials_available(),
        cvode: sundials_available(),
        // The driver's per-step deadline comes along; a regex engine does not.
        alarm: true,
        variable_filter: false,
        // An FMU has no notion of an optimization problem.
        optimization: false,
        // A Co-Simulation FMU steps to communication points; QSS cannot be stepped.
        qss: false,
    }
}

/// Whether an FMU exported with `method` needs the SUNDIALS side module.
fn fmu_needs_sundials(method: &str) -> bool {
    matches!(method, "cvode" | "ida")
}

/// The simulation flags to hard-code into an FMU's metadata: the export's
/// `_flags.json` but `-s`, which [`SimMeta::cs_method`] carries. An importer has no
/// channel to pass simulation flags, so the FMU applies these when it instantiates.
/// `--fmiFlags` takes any name; like C's `parseFlags`, ignore what this FMU cannot
/// honour — `createFMISimulationFlags` has already warned about the name.
fn fmu_solver_flags(flags_json: &str) -> String {
    fmi_flags(flags_json)
        .into_iter()
        .filter(|(name, _)| name != "s")
        .filter(|(name, value)| fmu_accepts_flag(name, value))
        .map(|(name, value)| if value.is_empty() { format!("-{name}") } else { format!("-{name}={value}") })
        .collect::<Vec<_>>()
        .join(" ")
}

/// `CodegenWasmJit.fmuAcceptsFlag`: whether a wasm FMU can honour `-name=value`
/// (an empty value for a flag that takes none). One it cannot is better dropped
/// where it comes from than baked into `_flags.json`, where it would only
/// surface at the importer's `instantiate`.
pub fn fmuAcceptsFlag(name: ArcStr, value: ArcStr) -> bool {
    fmu_accepts_flag(name.as_str(), value.as_str())
}

/// Flags the importer owns: it sets start values through `fmi3Set*` and decides
/// when the co-simulation ends. `-variableFilter` is refused by [`fmu_capabilities`].
const IMPORTER_FLAGS: &[&str] = &["override", "overrideFile", "steadyState", "steadyStateTol"];

fn fmu_accepts_flag(name: &str, value: &str) -> bool {
    if name == "s" {
        // Baked into the component rather than parsed at instantiation, so only
        // what it linked can serve it.
        return fmu_cs_solvers().contains(&value);
    }
    if IMPORTER_FLAGS.contains(&name) {
        return false;
    }
    let arg = if value.is_empty() { format!("-{name}") } else { format!("-{name}={value}") };
    match simflags::parse(&["model".to_string(), arg]) {
        Ok(f) => simflags::check(&f, fmu_capabilities()).is_ok(),
        Err(_) => false,
    }
}

/// Every `"name" : "value"` pair of a `_flags.json`, in file order.
fn fmi_flags(json: &str) -> Vec<(String, String)> {
    let mut out = Vec::new();
    let mut rest = json;
    while let Some(start) = rest.find('"') {
        let Some(len) = rest[start + 1..].find('"') else { break };
        let name = &rest[start + 1..start + 1 + len];
        let after = rest[start + 1 + len + 1..].trim_start();
        let Some(value_part) = after.strip_prefix(':').map(str::trim_start).and_then(|a| a.strip_prefix('"')) else {
            rest = &rest[start + 1 + len + 1..];
            continue;
        };
        let Some(vlen) = value_part.find('"') else { break };
        out.push((name.to_string(), value_part[..vlen].to_string()));
        rest = &value_part[vlen + 1..];
    }
    out
}

/// Which solver libraries an FMU exported with these `--fmiFlags` and this
/// Co-Simulation method can reach; the rest are linked as stubs. Both are fixed
/// at export, so this is the whole set the FMU will ever select from. `klu` comes
/// along with any of the others: the shared SUNDIALS core they call into, and
/// IDA's default linear solver.
///
/// `cs` gates only the integrator: Model Exchange never integrates, but its
/// initialisation and residuals run the same nonlinear and linear solvers.
///
/// `sparse_nls` is the one selection no flag records: C's density/size rule sends a
/// large sparse nonlinear system to kinsol+KLU whatever the flags say, so a model
/// carrying one needs both however it was exported.
fn fmu_solver_libraries(
    flags_json: &str,
    cs_method: &str,
    cs: bool,
    sparse_nls: bool,
) -> Vec<&'static str> {
    let flag = |name: &str| fmi_flag(flags_json, name).unwrap_or_default();
    let (nls, ls, lss) = (flag("nls"), flag("ls"), flag("lss"));
    let named = |v: &str| ls == v || lss == v;
    let mut wanted = Vec::new();
    if cs && fmu_needs_sundials(cs_method) {
        wanted.push("sundials_driver");
    }
    if sparse_nls || matches!(nls.as_str(), "kinsol" | "experimental-kinsol") {
        wanted.push("kinsol");
    }
    if named("umfpack") {
        wanted.push("umfpack");
    }
    if named("lis") {
        wanted.push("lis");
    }
    if !wanted.is_empty() || named("klu") || flag("nlsLS") == "klu" || (cs && flag("idaLS") == "klu")
    {
        wanted.push("klu");
    }
    wanted
}

/// The `method=` values `buildModelFMU` accepts for a `cs`/`me_cs` wasm FMU.
pub fn fmu_cs_solvers() -> Vec<&'static str> {
    simflags::supported(fmu_capabilities())
        .into_iter()
        .find(|(flag, _)| *flag == "s")
        .map(|(_, v)| v)
        .unwrap_or_default()
}

/// `CodegenWasmJit.fmuCsSolvers`: [`fmu_cs_solvers`] for the MetaModelica side,
/// which folds an accepted `method=` into the FMU's `_flags.json`.
pub fn fmuCsSolvers() -> Arc<List<ArcStr>> {
    Arc::new(fmu_cs_solvers().into_iter().map(ArcStr::from).collect())
}

/// The `platforms=` values `buildModelFMU` can serve besides `"wasm"`: those this
/// omc has a loader library for.
pub fn fmu_platforms() -> Vec<String> {
    native_fmu::available()
}

/// Parse `simflags` as an argv and install the result for this run. omc hands the
/// flags over as one string, which for every other target a shell splits into the
/// executable's argv; `argv[0]` stands in for the program name a WASI command would
/// see, so the same parser serves this path and a standalone `wasmtime model.wasm …`
/// run.
fn install_sim_flags(simflags: &str) -> std::result::Result<simflags::SimFlags, String> {
    let argv: Vec<String> = core::iter::once("model".to_string()).chain(split_simflags(simflags)).collect();
    let f = simflags::parse(&argv)?;
    simflags::check(&f, CAPABILITIES)?;
    simflags::set_flags(f.clone());
    Ok(f)
}

/// Split `simflags` as the shell splits `CevalScriptBackend`'s `sim_call` for every
/// other target: on whitespace outside quotes, `'…'`/`"…"` removed.
fn split_simflags(s: &str) -> Vec<String> {
    let mut out = Vec::new();
    let mut cur = String::new();
    let mut quote: Option<char> = None;
    let mut started = false;
    for c in s.chars() {
        match (quote, c) {
            (Some(q), c) if c == q => quote = None,
            (Some(_), c) => cur.push(c),
            (None, '\'' | '"') => {
                quote = Some(c);
                started = true;
            }
            (None, c) if c.is_whitespace() => {
                if started {
                    out.push(core::mem::take(&mut cur));
                    started = false;
                }
            }
            (None, c) => {
                cur.push(c);
                started = true;
            }
        }
    }
    if started {
        out.push(cur);
    }
    out
}

/// This run's scalars, and what `read_experiment` printed getting them — captured
/// separately because C prints it ahead of every other startup notice.
fn run_experiment(model: &SimModel, flags: &simflags::SimFlags) -> (SimMeta, String) {
    openmodelica_wasi::wasi::start_stdout_capture();
    let meta = model.meta.with_flags(flags);
    (meta, openmodelica_wasi::wasi::take_stdout_capture())
}

/// C's `initializeResultData`: the formats this runtime has a writer for, over the
/// model's own `outputFormat` as `-outputFormat` may have replaced it.
fn check_output_format(meta: &SimMeta) -> std::result::Result<(), String> {
    match meta.output_format.as_str() {
        f if openmodelica_sim_meta::result::known(f) => Ok(()),
        other => Err(format!(
            "CodegenWasmJit: this runtime writes `mat`/`csv`/`plt` results, or `empty` for none (got `{other}`)"
        )),
    }
}

/// C's result-file resolution (`simulation_runtime.cpp`): `-r` outright, else
/// `<prefix>_res.<format>` under `-outputPath`, else what the caller derived from
/// the model.
fn result_path(flags: &simflags::SimFlags, meta: &SimMeta, derived: &str) -> String {
    match (&flags.result_file, &flags.output_path) {
        (Some(r), _) => r.clone(),
        (None, Some(dir)) => format!("{dir}/{}_res.{}", meta.prefix, meta.output_format),
        // C names the file after the format `-outputFormat` settled on, while the
        // caller keeps the name it derived from the model — swap the extension in
        // `derived` to land on C's name without losing its directory.
        (None, None) => match derived.rsplit_once('.') {
            Some((stem, _)) if flags.output_format.is_some() => {
                format!("{stem}.{}", meta.output_format)
            }
            _ => derived.to_string(),
        },
    }
}

/// The result file of a run: its resolved path, the `-variableFilter` decision
/// per signal, and `-single`.
fn result_target(model: &SimModel, meta: &SimMeta, flags: &simflags::SimFlags, derived: &str) -> ResultTarget {
    ResultTarget {
        path: result_path(flags, meta, derived),
        keep: output_selection(model),
        single: flags.single_precision,
    }
}

/// Resolve each `-override=name=value` to its editable parameter's `SimData` slot.
/// Returns `(param_overrides, start_overrides, string_overrides)`: plain parameters
/// vs. state start values, applied at different points of initialization (see
/// `run_initialization`), and the String parameters, whose value is bytes.
///
/// C's `doOverride` also reports what it could not do, walking the `_init.xml`
/// quantities in class order. The result signals are that roster in that order,
/// with the editable parameters as its `isValueChangeable` subset.
fn resolve_overrides(
    model: &SimModel,
    flags: &simflags::SimFlags,
) -> (Vec<(u32, WTy, f64)>, Vec<(u32, WTy, f64)>, Vec<(u32, String)>) {
    let raw = flags.override_raw.as_deref();
    let file = flags.override_file.as_ref();
    if let (Some(raw), Some((path, _))) = (raw, file) {
        omclog::info!(omclog::SOLVER, false, "using -override={raw} and -overrideFile={path}");
    }
    if let Some((path, _)) = file {
        omclog::info!(omclog::SOLVER, false, "read override values from file: {path}");
    }
    if raw.is_none() && file.is_none() {
        omclog::info(omclog::SOLVER, false, "NO override given on the command line.");
        return (Vec::new(), Vec::new(), Vec::new());
    }
    let given = |v: Option<&str>| v.unwrap_or("[not given]").to_string();
    omclog::info!(omclog::SOLVER, false, "-override={}", given(raw));
    omclog::info!(omclog::SOLVER, false, "-overrideFile={}", given(file.map(|(_, j)| j.as_str())));

    // C fills a hash map, so a repeated name keeps the last value and warns.
    let mut map: Vec<(&str, &str)> = Vec::new();
    for (name, val) in &flags.overrides {
        match map.iter_mut().find(|(n, _)| *n == name) {
            Some((_, old)) => {
                omclog::warning!(
                    omclog::STDOUT,
                    false,
                    "You are overriding variable: {name}={old} again with {name}={val}.",
                );
                *old = val;
            }
            None => map.push((name, val)),
        }
    }

    let mut params = Vec::new();
    let mut starts = Vec::new();
    let mut strings = Vec::new();
    let mut used: Vec<&str> = Vec::new();
    // C's `singleOverride` walks the `_init.xml` quantities in class order. The String
    // parameters are not result signals, so they follow, as `_init.xml` has them.
    let string_names = model.editable_params.iter().filter(|p| p.is_string).map(|p| p.name.as_str());
    for name in model.result_vars.iter().map(|v| v.name.as_str()).chain(string_names) {
        let Some(&(name, val)) = map.iter().find(|(n, _)| *n == name) else { continue };
        used.push(name);
        let Some(p) = model.editable_params.iter().find(|p| p.name == name) else {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "It is not possible to override the following quantity: {name}\nIt seems to be \
                 structural, final, protected or evaluated or has a non-constant binding.",
            );
            continue;
        };
        omclog::info!(omclog::SOLVER, false, "override {name} = {val}");
        if p.is_string {
            strings.push((p.off, val.to_string()));
            continue;
        }
        // C warns only for the real and integer parameters (`warn_small_override`).
        let numeric_param = !p.is_start && (p.wty == WTy::F64 || !p.is_bool);
        if numeric_param && val.parse::<f64>().is_ok_and(|v| v.abs() < 1e-6) {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "You are overriding {name} with a small value or zero.\nThis could lead to \
                 numerically dirty solutions or divisions by zero if not tearingStrictness=veryStrict.",
            );
        }
        let v = p.read_value(val);
        if p.is_start { &mut starts } else { &mut params }.push((p.off, p.wty, v));
    }
    for (name, _) in &map {
        if !used.contains(name) {
            omclog::warning!(
                omclog::STDOUT,
                false,
                "simulation_input_xml.c: override variable name not found in model: {name}\n",
            );
        }
    }
    omclog::info(omclog::SOLVER, false, "override done!");
    (params, starts, strings)
}

/// Resolve `-iif=<file>` against the model's [`SimMeta::import_roster`] at `-iit`
/// (the start time by default). Only the host can open the file — the browser reaches
/// it through the VFS — so the driver applies the values where C's
/// `importStartValues` does. A quantity `-override` names is left out so the command
/// line wins (ticket #15807); the driver reports the skip.
fn resolve_start_imports(meta: &SimMeta, flags: &simflags::SimFlags) -> Option<sim_driver::StartImports> {
    let file = flags.init_file.as_ref()?;
    let time = flags.init_time.unwrap_or(meta.start_time);
    let mut reader = match openmodelica_mat_reader::MatReader::open(file) {
        Ok(r) => r,
        Err(e) => {
            record_error(format!("wasm-jit: unable to read input-file <{file}> [{e}]"));
            return None;
        }
    };
    let overridden = |n: &str| flags.overrides.iter().any(|(o, _)| o == n);
    let values = meta
        .import_roster()
        .iter()
        .flatten()
        .enumerate()
        .filter(|(_, (name, _, _))| !overridden(name))
        .filter_map(|(i, (name, _, _))| {
            let v = reader.find_var(name).and_then(|idx| reader.val(idx, time))?;
            Some((i as u32, v))
        })
        .collect();
    Some(sim_driver::StartImports { file: file.clone(), time, values })
}

/// The driver's [`sim_driver::ResultFileReader`]: C's `importStartValues` for the
/// real variables, which the optimizer's `-ipopt_init=file` repeats at every
/// collocation point. A name the file does not carry keeps the start it has.
fn read_result_values(
    file: &str,
    names: &[&str],
    t: f64,
    out: &mut [f64],
) -> std::result::Result<(), String> {
    GUESS_READER.with(|c| {
        let mut c = c.borrow_mut();
        if c.as_ref().is_none_or(|(f, _)| f != file) {
            let r = openmodelica_mat_reader::MatReader::open(file)
                .map_err(|e| format!("unable to read input-file <{file}> [{e}]"))?;
            *c = Some((file.to_string(), r));
        }
        let (_, reader) = c.as_mut().expect("just filled");
        for (name, slot) in names.iter().zip(out) {
            if let Some(v) = reader.find_var(name).and_then(|i| reader.val(i, t)) {
                *slot = v;
            }
        }
        Ok(())
    })
}

thread_local! {
    /// The result file `-ipopt_init=file` reads, opened once for the whole run.
    static GUESS_READER: std::cell::RefCell<
        Option<(String, openmodelica_mat_reader::MatReader)>,
    > = const { std::cell::RefCell::new(None) };
    /// Model stdout captured during initialization, split from the simulation-phase
    /// output so the log stays ordered. `None` until initialization completes.
    static INIT_OUTPUT: std::cell::RefCell<Option<String>> = const { std::cell::RefCell::new(None) };
    /// Only [`run_simulation_inner`] wants the split; other `run_initialization`
    /// callers (the interactive session) share the hook but must not split. Armed
    /// for one firing.
    static SPLIT_ARMED: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
    /// Taken when the teardown hook fires, so destructor output follows the
    /// success line.
    static SIM_OUTPUT: std::cell::RefCell<Option<String>> = const { std::cell::RefCell::new(None) };
}

/// Init-done hook: take the initialization phase's output, then restart the
/// capture. A no-op unless [`run_simulation_inner`] armed it.
fn on_init_done() {
    if !SPLIT_ARMED.with(|a| a.replace(false)) {
        return;
    }
    INIT_OUTPUT.with(|c| *c.borrow_mut() = Some(openmodelica_wasi::wasi::take_stdout_capture()));
    openmodelica_wasi::wasi::start_stdout_capture();
}

/// The same split for what the external objects' destructors print: C runs them
/// after "The simulation finished successfully.".
fn on_teardown() {
    SIM_OUTPUT.with(|c| *c.borrow_mut() = Some(openmodelica_wasi::wasi::take_stdout_capture()));
    openmodelica_wasi::wasi::start_stdout_capture();
}

/// Run the model, returning the result and the model's stdout split into the
/// initialization segment (`Some` once init completed) and the simulation segment.
/// Write `-l`'s linearized model where C's `linearize` puts it and render its
/// notice, which the caller appends after the run's success line.
fn write_lin_file(meta: &SimMeta, run: &sim_driver::RunResult, flags: &simflags::SimFlags) -> String {
    let (Some(f), Some(lin)) = (&run.lin, &meta.lin) else { return String::new() };
    let path = match &flags.output_path {
        Some(dir) => format!("{dir}/{}", f.name),
        None => f.name.clone(),
    };
    if write_output(&path, f.content.as_bytes()).is_err() {
        return openmodelica_modelica_utilities::format_log_stdout(
            &format!("Cannot open File {path}"),
            openmodelica_modelica_utilities::LOG_STDOUT_ERROR,
        );
    }
    let full = std::fs::canonicalize(&path).map(|p| p.display().to_string()).unwrap_or(path);
    let (msgs, is_error) = openmodelica_sim_meta::linearize::write_notice(lin, f, &full);
    let prefix = if is_error {
        openmodelica_modelica_utilities::LOG_STDOUT_ERROR
    } else {
        openmodelica_modelica_utilities::LOG_STDOUT_INFO
    };
    msgs.iter().map(|m| openmodelica_modelica_utilities::format_log_stdout(m, prefix)).collect()
}

fn run_simulation_inner(prefix: &str, result_file: &str, simflags: &str) -> (std::result::Result<(), String>, Option<String>, String, String) {
    let model = sim_models()
        .lock()
        .unwrap_or_else(|e| e.into_inner())
        .get(prefix)
        .cloned();
    let Some(model) = model else {
        return (
            Err("no prepared wasm-jit model for (translateModel not run?)".to_string()),
            None,
            String::new(),
            String::new(),
        );
    };
    // The caller prefixes the failure, so this is the bare reason.
    let flags = match install_sim_flags(simflags) {
        Ok(f) => f,
        Err(e) => return (Err(e), None, String::new(), String::new()),
    };
    // The `-lv=` runtime flag list selects log streams, as for the C executable.
    let log_stats = flags.has_log("LOG_STATS");
    // C refuses to seed a run from the file it is about to overwrite.
    if let Some(init) = &flags.init_file
        && init == flags.result_file.as_deref().unwrap_or(result_file)
    {
        return (
            Err(format!(
                "Cannot import a result file for initialization that is also the current output \
                 file <{init}>.\nConsider redirecting the output result file (-r=<new_res.mat>) or \
                 renaming the result file that is used for initialization import."
            )
            ),
            None,
            String::new(),
            String::new(),
        );
    }
    INIT_OUTPUT.with(|c| *c.borrow_mut() = None);
    sim_driver::set_init_done_hook(on_init_done);
    SIM_OUTPUT.with(|c| *c.borrow_mut() = None);
    sim_driver::set_teardown_hook(on_teardown);
    SPLIT_ARMED.with(|a| a.set(true));
    openmodelica_wasm_jit::host::native_stdout::install();
    sim_driver::init_host_hooks();
    sim_driver::set_result_file_reader(read_result_values);
    let (meta, experiment_log) = run_experiment(&model, &flags);
    openmodelica_wasi::wasi::start_stdout_capture();
    let (param_ov, start_ov, string_ov) = resolve_overrides(&model, &flags);
    sim_driver::set_param_overrides(param_ov, start_ov, string_ov);
    sim_driver::set_start_imports(resolve_start_imports(&meta, &flags));
    // `-abortSlowSimulation`: stop the run when chattering is detected.
    sim_driver::set_abort_slow(flags.abort_slow);
    // The hard `-alarm`, if asked for: set before the modules are instantiated.
    sim_runtime::set_alarm(flags.alarm);
    let mut extra = String::new();
    let mut post = String::new();
    let res = (|| -> std::result::Result<(), String> {
        // `empty` (and `-noemit`) runs the integration but writes no result file —
        // useful for benchmarking the solver in isolation from the `.mat` writer.
        check_output_format(&meta)?;
        let target = result_target(&model, &meta, &flags, result_file);
        let (path, keep) = (target.path.clone(), target.keep.clone());
        let (run, written) = sim_runtime::run(&model, &meta, target)?;
        // The driver already printed the `-output` line that precedes this block.
        if log_stats {
            extra.push_str(&openmodelica_sim_meta::stats::log_stats_block(&run.stats));
        }
        // C's `printModelInfo`, after the result file is closed.
        openmodelica_sim_meta::profiling::finish(&meta, &path, output_size(&path));
        post = write_lin_file(&meta, &run, &flags);
        capture_last_sim(&model, written, &run.params, &run.stats, &keep, &path);
        Ok(())
    })();
    // Disarm in case init failed before the hook fired.
    SPLIT_ARMED.with(|a| a.set(false));
    // Everything captured after the split is the simulation phase (plus `extra`:
    // LOG_STATS / chattering lines). `INIT_OUTPUT` is `None` when init failed.
    // With the hook fired, the capture holds the destructors' output instead.
    let teardown_output = SIM_OUTPUT.with(|c| c.borrow_mut().take());
    let tail = openmodelica_wasi::wasi::take_stdout_capture();
    let (sim_capture, post_capture) = match teardown_output {
        Some(sim) => (sim, tail),
        None => (tail, String::new()),
    };
    let post = format!("{post_capture}{post}");
    let sim_output = format!("{sim_capture}{extra}");
    let init_output = INIT_OUTPUT.with(|c| c.borrow_mut().take());
    // C prints the sparse-solver announcements (initializeLinear/NonlinearSystems)
    // ahead of the init-success line; prepend our pre-rendered copy to the init output.
    let head = format!("{experiment_log}{}", flag_change_log(&flags));
    let init_output = if head.is_empty() {
        init_output
    } else {
        Some(format!("{head}{}", init_output.unwrap_or_default()))
    };
    (res, init_output, sim_output, post)
}

// ===========================================================================
// Resumable / cancellable simulation session
// ===========================================================================
//
// `runSimulation` runs a prepared model in one blocking call. For cooperative
// cancellation the run is split into a persistent session: `sim_start` builds the
// engine + driver (init + row 0), `sim_advance(budget_ms)` integrates a time-bounded
// chunk and returns, `sim_free` drops it. A run short enough to finish in one
// `advance` never yields. See HANDOFF-sim-cancel.md.

/// Status of a resumable simulation session.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum SimStatus {
    /// More rows remain; call `sim_advance` again.
    Running,
    /// Reached `stopTime`; results captured, `.mat` written, session freed.
    Done,
    /// `terminate()` ended it early; results captured, session freed.
    Terminated,
    /// Cancelled; externals freed, session dropped, no results captured.
    Cancelled,
}

/// Request cancellation of the running simulation (native, cross-thread).
#[cfg(feature = "jit")]
pub fn request_cancel() {
    sim_driver::request_cancel();
}
#[cfg(not(feature = "jit"))]
pub fn request_cancel() {}

/// Install the wasm wall-clock (`performance.now`) for the chunk budget; wasm-only.
#[cfg(all(feature = "jit", target_arch = "wasm32"))]
pub fn set_clock(f: fn() -> f64) {
    sim_driver::set_clock(f);
}

/// Install a host cancel poll (a cross-thread `SharedArrayBuffer` flag read) so a
/// blocking wasm `simulate()` can be cancelled from another thread — OMEdit-wasm.
#[cfg(all(feature = "jit", target_arch = "wasm32"))]
pub fn set_cancel_poll(f: fn() -> bool) {
    sim_driver::set_cancel_poll(f);
}

/// Install the host's compiler for an FMU's native platforms, for an omc that
/// cannot link wasmtime in. `preload` is called as soon as an export is known to
/// need one, `compile` once the component is built.
#[cfg(any(not(feature = "fmu-native"), target_arch = "wasm32"))]
pub fn set_fmu_aot(
    compile: fn(&[u8], &str) -> core::result::Result<Vec<u8>, String>,
    preload: fn(),
) {
    native_fmu::set_aot_compiler(compile, preload);
}

/// Install the host's source for the FMU loader libraries, which a wasm omc does
/// not carry (they are files in the web bundle).
#[cfg(target_arch = "wasm32")]
pub fn set_fmu_loaders(fetch: fn(&str) -> Option<Vec<u8>>, platforms: Vec<String>) {
    native_fmu::set_loader_source(fetch, platforms);
}

#[cfg(feature = "jit")]
mod session {
    use super::*;

    /// A resumable, cancellable simulation. One per thread (omc is single-threaded
    /// per process).
    pub(super) struct SimSession {
        model: Arc<SimModel>,
        /// This run's scalars: the model's metadata with the run's flags applied.
        meta: SimMeta,
        result_file: String,
        /// The `-variableFilter` decision per result signal.
        keep: Vec<bool>,
        backend: SessionBackend,
        /// Wall-clock inside `advance`, summed over chunks: excludes the yields
        /// between them, so it stays comparable to the one-shot `run()` timing.
        integrate_ms: f64,
        /// The model's output so far. `take_stdout_capture` ends the capture, so
        /// each chunk drains it here and re-arms.
        log: String,
        /// `-lv=LOG_STATS` was requested.
        log_stats: bool,
    }

    thread_local! {
        /// The last run's model output, for [`last_sim_log`]: `sim_advance` returns
        /// a status code and has no other channel for it.
        static LAST_SIM_LOG: std::cell::RefCell<String> = const { std::cell::RefCell::new(String::new()) };
    }

    /// The last session run's model output, including a failed run's.
    pub fn last_sim_log() -> String {
        LAST_SIM_LOG.with(|c| c.borrow().clone())
    }

    /// Drain the capture into `dst` and re-arm it for the next chunk.
    fn drain_capture(dst: &mut String) {
        dst.push_str(&openmodelica_wasi::wasi::take_stdout_capture());
        openmodelica_wasi::wasi::start_stdout_capture();
    }

    /// End the capture, fold everything the run produced into `log`, and publish it.
    fn publish_log(mut log: String) {
        log.push_str(&openmodelica_wasi::wasi::take_stdout_capture());
        LAST_SIM_LOG.with(|c| *c.borrow_mut() = log);
    }

    /// Either the host driver (Rust driver calling the model through the wasm
    /// engine) or the in-wasm session driver (`rt_sim_*`, the model reached
    /// wasm->wasm), selected by `OMC_WASM_INWASM_DRIVER` at `sim_start`.
    enum SessionBackend {
        Host {
            engine: Box<dyn sim_driver::SimEngine + 'static>,
            driver: Box<dyn sim_driver::Driver>,
            sim_data: u32,
        },
        InWasm(sim_runtime::InWasmSession),
    }

    thread_local! {
        static SIM_SESSION: std::cell::RefCell<Option<SimSession>> = const { std::cell::RefCell::new(None) };
    }

    /// Capture results for the `omc_sim_*` getters once the result file is written.
    fn finalize_and_capture(
        model: &SimModel,
        meta: &SimMeta,
        result_file: &str,
        keep: &[bool],
        run: sim_driver::RunResult,
        written: Written,
    ) -> Result<String> {
        openmodelica_sim_meta::profiling::finish(meta, result_file, output_size(result_file));
        let lin = write_lin_file(meta, &run, &simflags::flags());
        capture_last_sim(model, written, &run.params, &run.stats, keep, result_file);
        Ok(lin)
    }

    /// Start a resumable run of a model already prepared by `buildModel`
    /// (`translateModel` + `finishCompile`). Mirrors `run_simulation_inner`'s setup
    /// but stops before integrating. One session at a time — any prior one is freed.
    pub fn sim_start(prefix: &str, result_file: &str, simflags: &str) -> Result<()> {
        sim_free();
        let model = sim_models()
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .get(prefix)
            .cloned()
            .ok_or_else(|| "no prepared wasm-jit model for (translateModel not run?)")?;
        let flags = install_sim_flags(simflags).map_err(|e| {
            record_error(format!("wasm-jit: {e}"));
            "CodegenWasmJit: unusable simulation flags"
        })?;
        sim_driver::clear_cancel();
        // Split init from simulation output as `run_simulation_inner` does; the
        // hook fires while the backend below is built, which is what initializes.
        LAST_SIM_LOG.with(|c| c.borrow_mut().clear());
        INIT_OUTPUT.with(|c| *c.borrow_mut() = None);
        sim_driver::set_init_done_hook(on_init_done);
    SIM_OUTPUT.with(|c| *c.borrow_mut() = None);
    sim_driver::set_teardown_hook(on_teardown);
        SPLIT_ARMED.with(|a| a.set(true));
        openmodelica_wasm_jit::host::native_stdout::install();
        sim_driver::init_host_hooks();
        sim_driver::set_result_file_reader(read_result_values);
        let (meta, experiment_log) = run_experiment(&model, &flags);
        check_output_format(&meta).map_err(|e| {
            record_error(e);
            "CodegenWasmJit: unsupported output format"
        })?;
        openmodelica_wasi::wasi::start_stdout_capture();
        let (param_ov, start_ov, string_ov) = resolve_overrides(&model, &flags);
        sim_driver::set_param_overrides(param_ov, start_ov, string_ov);
        sim_driver::set_start_imports(resolve_start_imports(&meta, &flags));
        // Build the backend (instantiate, init, emit row 0). An init trap is usually
        // a failed `assert()`; the host driver routes it via `enrich_trap`.
        let inwasm = inwasm_driver_enabled();
        let target = result_target(&model, &meta, &flags, result_file);
        let (path, keep) = (target.path.clone(), target.keep.clone());
        let built = (|| -> std::result::Result<SessionBackend, String> {
            if inwasm {
                Ok(SessionBackend::InWasm(sim_runtime::build_inwasm_session(&model, Some(&target))?))
            } else {
                let (mut engine, sim_data) = sim_runtime::build_engine(&model, &meta)?;
                let made = sim_driver::make_driver(&mut *engine, &meta, sim_data, meta.method.as_str())
                    .map_err(|err| sim_driver::enrich_trap_init(&mut *engine, err, meta.start_time));
                let (driver, _label) = match made {
                    Ok(v) => v,
                    Err(e) => {
                        return Err(e.to_string());
                    }
                };
                // `make_driver` initialized, so the file opens here rather than from
                // inside `drive`.
                openmodelica_wasm_jit::result_sink::arm(target);
                sim_driver::open_result(&mut *engine, &meta, sim_data).map_err(|e| e.to_string())?;
                Ok(SessionBackend::Host { engine, driver, sim_data })
            }
        })();
        // Disarm in case init failed before the hook fired.
        SPLIT_ARMED.with(|a| a.set(false));
        let flags = simflags::flags();
        let init_log = format!(
            "{experiment_log}{}{}",
            flag_change_log(&flags),
            INIT_OUTPUT.with(|c| c.borrow_mut().take()).unwrap_or_default()
        );
        let backend = match built {
            Ok(v) => v,
            Err(e) => {
                publish_log(init_log);
                record_error(format!("wasm-jit simulation failed: {}", with_engine_detail(&e)));
                return Err("CodegenWasmJit: wasm-jit simulation failed");
            }
        };
        SIM_SESSION.with(|s| {
            *s.borrow_mut() = Some(SimSession {
                model,
                result_file: path,
                keep,
                meta,
                backend,
                integrate_ms: 0.0,
                log: init_log,
                log_stats: flags.has_log("LOG_STATS"),
            })
        });
        Ok(())
    }

    /// Integrate for about `budget_ms` of wall-clock, then return. On completion
    /// finalizes exactly as `run_simulation_inner` (capture results for the
    /// `omc_sim_*` getters + write the `.mat`) and frees the session.
    pub fn sim_advance(budget_ms: f64) -> Result<SimStatus> {
        SIM_SESSION.with(|s| {
            let mut guard = s.borrow_mut();
            let Some(sess) = guard.as_mut() else {
                return Err("no active simulation session");
            };
            // Clone the cheap identity fields so the `sess` borrow can end before we
            // touch `guard` again (to clear it on completion/error).
            let model = sess.model.clone();
            let result_file = sess.result_file.clone();
            let keep = sess.keep.clone();
            let log_stats = sess.log_stats;
            let n_intervals = sess.meta.n_intervals;
            // Stopped before the finalize/`.mat` work in each arm below.
            let mut adv_ms = 0.0f64;
            // Filled by whichever arm finishes the run, appended to the log below.
            let mut stats_block = String::new();

            // Advance one chunk. All `sess` borrows end when this block returns its
            // status value.
            let outcome: Result<SimStatus> = match &mut sess.backend {
                SessionBackend::Host { engine, driver, sim_data } => {
                    let t = sim_driver::now_ms_host();
                    let advanced = driver
                        .advance(&mut **engine, &sess.meta, budget_ms)
                        .map_err(|err| sim_driver::enrich_trap(&mut **engine, err));
                    adv_ms = sim_driver::now_ms_host() - t;
                    match advanced {
                        Ok(sim_driver::Advance::Running) => Ok(SimStatus::Running),
                        Ok(sim_driver::Advance::Cancelled) => {
                            // Free external objects so the cancelled run leaks nothing.
                            let _ = sim_driver::finalize_run(&mut **engine, &sess.meta, *sim_data);
                            Ok(SimStatus::Cancelled)
                        }
                        Ok(done) => {
                            let mut rows = driver.take_rows();
                            sim_driver::finish_rows(&mut rows);
                            let written = openmodelica_wasm_jit::result_sink::take();
                            let mut stats = SolveStats::default();
                            driver.fill_stats(&sess.meta, &mut stats);
                            // C's order: the `-reconcile*` procedures, then `-l`.
                            let (recon_log, recon_res) =
                                sim_driver::reconcile(&mut **engine, &sess.meta, *sim_data);
                            let lin = match recon_res.is_ok() {
                                true => openmodelica_sim_meta::linearize::linearize(
                                    &mut **engine,
                                    &sess.meta,
                                    *sim_data,
                                )?,
                                false => None,
                            };
                            let params = sim_driver::finalize_run(&mut **engine, &sess.meta, *sim_data)?;
                            stats_block.push_str(&recon_log);
                            recon_res?;
                            let run = sim_driver::RunResult {
                                rows,
                                n_reals: model.layout.n_row_total(),
                                params,
                                stats,
                                lin,
                            };
                            if log_stats {
                                stats_block = openmodelica_sim_meta::stats::log_stats_block(&run.stats);
                            }
                            stats_block
                                .push_str(&finalize_and_capture(&model, &sess.meta, &result_file, &keep, run, written)?);
                            Ok(if matches!(done, sim_driver::Advance::Terminated) {
                                SimStatus::Terminated
                            } else {
                                SimStatus::Done
                            })
                        }
                        Err(e) => Err(e),
                    }
                }
                SessionBackend::InWasm(inwasm) => {
                    let t = sim_driver::now_ms_host();
                    let advanced = inwasm.advance(budget_ms);
                    adv_ms = sim_driver::now_ms_host() - t;
                    match advanced {
                        Ok(0) => Ok(SimStatus::Running),
                        Ok(3) => Ok(SimStatus::Cancelled),
                        Ok(rc) => {
                            // 1 done, 2 terminated
                            let run = inwasm.take_result()?;
                            let written = inwasm.take_written()?;
                            if log_stats {
                                stats_block = openmodelica_sim_meta::stats::log_stats_block(&run.stats);
                            }
                            stats_block
                                .push_str(&finalize_and_capture(&model, &sess.meta, &result_file, &keep, run, written)?);
                            Ok(if rc == 2 { SimStatus::Terminated } else { SimStatus::Done })
                        }
                        Err(e) => Err(e),
                    }
                }
            };
            sess.integrate_ms += adv_ms;
            let integrate_ms = sess.integrate_ms;
            drain_capture(&mut sess.log);
            sess.log.push_str(&stats_block);
            // The run is over unless it asked for another chunk, so hand the log on.
            let run_log = match outcome {
                Ok(SimStatus::Running) => None,
                _ => Some(core::mem::take(&mut sess.log)),
            };

            match outcome {
                Ok(SimStatus::Running) => Ok(SimStatus::Running),
                Ok(st) => {
                    if sim_bench_enabled() {
                        eprintln!(
                            "wasm-jit session [{}]: integrate {integrate_ms:.1} ms ({} intervals)",
                            if inwasm_driver_enabled() { "in-wasm" } else { "host" },
                            n_intervals,
                        );
                    }
                    publish_log(run_log.unwrap_or_default());
                    *guard = None;
                    Ok(st)
                }
                Err(e) => {
                    publish_log(run_log.unwrap_or_default());
                    record_error(format!("wasm-jit simulation failed: {}", with_engine_detail(e)));
                    *guard = None;
                    Err(e)
                }
            }
        })
    }

    /// Drop the active session, freeing its external objects. Safe to call with no
    /// session (the cancel path and `sim_start`'s reset both use it).
    pub fn sim_free() {
        SIM_SESSION.with(|s| {
            if let Some(mut sess) = s.borrow_mut().take() {
                // Cancel path: end the capture, keeping what was printed.
                publish_log(core::mem::take(&mut sess.log));
                // The in-wasm session frees itself on `Drop` (`rt_sim_free`).
                let SimSession { meta, backend, .. } = &mut sess;
                if let SessionBackend::Host { engine, sim_data, .. } = backend {
                    let _ = sim_driver::finalize_run(&mut **engine, meta, *sim_data);
                    openmodelica_wasm_jit::result_sink::take();
                }
            }
        });
    }
}

#[cfg(feature = "jit")]
pub use session::{last_sim_log, sim_advance, sim_free, sim_start};

#[cfg(not(feature = "jit"))]
pub fn sim_start(_prefix: &str, _result_file: &str, _simflags: &str) -> Result<()> {
    return Err("CodegenWasmJit: the wasm JIT engine is not built in (enable the `jit` feature)")
}
#[cfg(not(feature = "jit"))]
pub fn sim_advance(_budget_ms: f64) -> Result<SimStatus> {
    return Err("CodegenWasmJit: the wasm JIT engine is not built in (enable the `jit` feature)")
}
#[cfg(not(feature = "jit"))]
pub fn sim_free() {}
#[cfg(not(feature = "jit"))]
pub fn last_sim_log() -> String {
    String::new()
}

// ===========================================================================
// Standalone WASI command-module export (native only)
// ===========================================================================

/// The `wasm32-wasip1` standalone runtime (`_start` + the in-wasm driver in
/// `openmodelica_codegen_wasm_jit_runtime::standalone`), embedded for the native
/// standalone-export path. Empty when omc itself targets wasm32, or when the
/// wasip1 build was unavailable (see `build.rs`); [`emit_standalone_module`] then
/// reports the absence rather than producing a broken module.
#[cfg(not(target_arch = "wasm32"))]
use openmodelica_wasm_jit::RUNTIME_WASIP1;

/// Emit a self-contained `wasm32-wasip1` *command* module for `sim_code`: lower
/// the model to its wasm module, then `wasm-merge` it with the standalone runtime
/// so the merged module's `_start` runs the whole simulation in-wasm and writes
/// `<prefix>_res.mat` over WASI (`wasmtime run <module> --dir .::.`). Native only —
/// `wasm-merge` is an external tool, absent in the omc wasm build.
#[cfg(not(target_arch = "wasm32"))]
pub fn emit_standalone_module(sim_code: &SimCode::SimCode) -> Result<Vec<u8>> {
    let model = build_sim_model(sim_code, false, ExtHost::Wasm, "", "")?;
    merge_standalone(&model.wasm)
}

/// `wasm-merge` the standalone runtime (module name `rt`) with a model module
/// (module name `model`), resolving both directions of the merge contract (see
/// `openmodelica_codegen_wasm_jit_runtime::standalone`) and leaving only the WASI
/// imports. The merge tool is `wasm-merge` on `PATH`, overridable with
/// `OMC_WASM_MERGE`.
#[cfg(not(target_arch = "wasm32"))]
fn merge_standalone(model_wasm: &[u8]) -> Result<Vec<u8>> {
    use std::process::Command;
    if RUNTIME_WASIP1.is_empty() {
        return Err("error");
    }
    let merge = std::env::var("OMC_WASM_MERGE").unwrap_or_else(|_| "wasm-merge".to_owned());

    let dir = std::env::temp_dir().join(format!(
        "om-wasm-merge-{}-{:p}",
        std::process::id(),
        model_wasm.as_ptr()
    ));
    std::fs::create_dir_all(&dir).map_err(|_| "CodegenWasmJit: cannot create temp merge dir")?;
    let rt_path = dir.join("runtime.wasm");
    let model_path = dir.join("model.wasm");
    let out_path = dir.join("standalone.wasm");
    std::fs::write(&rt_path, RUNTIME_WASIP1).map_err(|_| "CodegenWasmJit: cannot write runtime.wasm")?;
    std::fs::write(&model_path, model_wasm).map_err(|_| "CodegenWasmJit: cannot write model.wasm")?;

    // `-all` enables every wasm feature so the model's bulk-memory `memory.init`
    // (the metadata data segment) and the runtime's features pass through unmodified.
    let status = Command::new(&merge)
        .arg(&rt_path)
        .arg("rt")
        .arg(&model_path)
        .arg("model")
        .arg("-o")
        .arg(&out_path)
        .arg("-all")
        .status()
        .map_err(|e| "CodegenWasmJit: cannot run")?;
    if !status.success() {
        return Err("CodegenWasmJit: failed with");
    }
    let bytes = std::fs::read(&out_path).map_err(|_| "CodegenWasmJit: cannot read merged wasm")?;
    let _ = std::fs::remove_dir_all(&dir);
    Ok(bytes)
}

// ===========================================================================
// FMI 3.0 wasm Model-Exchange FMU export (fmi-ls-wasm component)
// ===========================================================================

/// The model-agnostic FMI3 adapters, built + embedded by build.rs as dylink side
/// modules: one per FMU type (the same crate, two WIT worlds).
use openmodelica_wasm_jit::FMI3_ME_ADAPTER;
/// The combined me_cs component (both interfaces, one binary, one modelIdentifier).
use openmodelica_wasm_jit::FMI3_MECS_ADAPTER;
/// LAPACK for the `external "FORTRAN 77"` calls of `Modelica.Math.Matrices`, which
/// a host-free FMU has no system library to resolve.
use openmodelica_wasm_jit::LAPACK_DYLINK;
/// The solvers the me_cs adapter's embedded driver calls, one side module each.
use openmodelica_wasm_jit::{sundials_dylink_available as sundials_available, SOLVER_LIBRARIES};

/// The external-"C" FMU artifacts, linked in only when the model uses `external
/// "C"`. Any is empty when that omc was built without the toolchain.
use openmodelica_wasi_libc::{
    available as external_c_available, EXTERNAL_C_DYLINK, LIBC_PIC, USERTAB_DYLINK,
    WASI_P1_ADAPTER,
};

// ===========================================================================
// The model's own `external "C"` libraries
// ===========================================================================

/// What the `Library` annotations resolved to. `SimCodeFunctionUtil` emits each
/// one twice: the wasm module name, then the host linker spec.
#[derive(Default)]
pub(crate) struct ExtLibraries {
    pub wasm: Vec<ExtLibrary>,
    /// In link order, for a native host to fall back to.
    pub native: Vec<String>,
    /// The system libraries among them: named by soname, with no file behind them
    /// that an export could ship. Also in `native`, which only ever dlopens.
    pub native_system: Vec<String>,
    /// The static archives and object files among them, likewise in link order.
    pub archives: Vec<String>,
    /// `#include` lines for the C sources a `Library` named, which the C target
    /// hands to the compiler rather than the linker.
    pub sources: Vec<String>,
}

/// Resolve the `Library` annotations against the library directories. A name that
/// resolves to nothing is reported here, not later as an unresolvable `ext.<fn>`
/// import.
pub(crate) fn resolve_ext_libraries(
    mp: &SimCodeFunction::MakefileParams,
    notes: &mut Vec<String>,
) -> Result<ExtLibraries> {
    let mut dirs: Vec<String> = vec![String::new()]; // relative to the working directory
    for d in lst(&mp.libPaths) {
        dirs.push(format!("{d}/"));
    }
    for lib in lst(&mp.libs) {
        if let Some(d) = lib.strip_prefix("-L") {
            dirs.push(format!("{}/", d.trim_matches('"')));
        }
    }
    // The rest of the `LDFLAGS=` line CodegenC.tpl writes. `ffi/` comes first: it
    // holds the shared build of libraries the lib dir ships only as archives.
    dirs.push(format!("{}/lib/{}/omc/ffi/", mp.omhome, openmodelica_util::Autoconf::triple));
    dirs.push(format!("{}/lib/{}/omc/", mp.omhome, openmodelica_util::Autoconf::triple));
    dirs.push(format!("{}/lib/", mp.omhome));
    for d in ld_search_dirs(&mp.ldflags) {
        dirs.push(format!("{d}/"));
    }
    let mut out = ExtLibraries::default();
    let mut seen: HashSet<String> = HashSet::new();
    // A `Library` yields `<name>.wasm` and the `-l<name>` a native host falls back
    // to, both naming the same file. Placing one twice re-runs its `_initialize`.
    let mut placed: HashSet<String> = HashSet::new();
    for lib in lst(&mp.libs) {
        let lib = lib.to_string();
        if !seen.insert(lib.clone()) {
            continue;
        }
        if !lib.ends_with(".wasm") {
            // A wasm build installed beside the native one: its functions bind
            // wasm->wasm, where the native one costs a host trampoline per call.
            // Both are kept — the `Include` wrappers over the library are served by
            // the host, and those link against the platform build.
            let mut have_wasm = false;
            if let Some((path, bytes)) = find_wasm_library(&lib, &dirs) {
                have_wasm = true;
                if placed.insert(path.clone()) {
                    out.wasm.push(ExtLibrary { name: path, bytes, fixed: true });
                }
            }
            if let Some(path) = find_source_library(&lib, &dirs) {
                out.sources.push(format!("#include \"{}\"", path.replace('\\', "/")));
            } else {
                match find_native_library(&lib, &dirs) {
                    Some(NativeLib::Shared(path)) => out.native.push(path),
                    Some(NativeLib::Archive(path)) => out.archives.push(path),
                    // A soname no file backs is the platform's to find. Not worth
                    // asking for when the module is already here.
                    Some(NativeLib::System(soname)) if !have_wasm => {
                        out.native.push(soname.clone());
                        out.native_system.push(soname);
                    }
                    _ => (),
                }
            }
            continue;
        }
        let Some((path, bytes)) = find_ext_library(&lib, &dirs) else {
            notes.push(format!(
                "`{lib}` was not found (looked in {}); a wasm target loads a prebuilt shared \
                 library, built with `clang --target=wasm32-wasip1 -fPIC -shared`",
                dirs.iter().map(|d| if d.is_empty() { "." } else { d.trim_end_matches('/') })
                    .collect::<Vec<_>>().join(", ")
            ));
            continue;
        };
        if placed.insert(path.clone()) {
            out.wasm.push(ExtLibrary { name: path, bytes, fixed: true });
        }
    }
    Ok(out)
}

/// Compile the model's `Include` annotations into a wasm library: C *source* has no
/// `Library` to load. Native only; the browser omc has no compiler. A failure is a
/// note, not an error: only a symbol nothing defines is fatal.
#[cfg(not(target_arch = "wasm32"))]
pub(crate) fn compile_include_library(
    prefix: &str,
    includes: &[String],
    include_dirs: &[String],
    cflags: &str,
    missing: &[ExtCallSig],
    notes: &mut Vec<String>,
) -> Result<Option<ExtLibrary>> {
    if includes.is_empty() {
        return Ok(None);
    }
    let wrappers = openmodelica_wasm_jit::model::ext_wrappers(missing);
    match compile_include_tu(prefix, includes, include_dirs, cflags, &wrappers, notes)? {
        // Keep why they did not compile: it explains a symbol still missing.
        None if !wrappers.is_empty() => compile_include_tu(prefix, includes, include_dirs, cflags, "", notes),
        r => Ok(r),
    }
}

const INCLUDE_PREAMBLE: &str = "\
/* No preamble: the Modelica specification gives an external \"C\" translation unit
   nothing beyond what its own Include sources bring in, so omc must not add headers
   or declarations here. A library that fails to compile is fixed upstream, or gets
   `-std=`/`-include` flags in the library-testing configuration. */
";

#[cfg(not(target_arch = "wasm32"))]
fn compile_include_tu(
    prefix: &str,
    includes: &[String],
    include_dirs: &[String],
    cflags: &str,
    wrappers: &str,
    notes: &mut Vec<String>,
) -> Result<Option<ExtLibrary>> {
    use std::process::Command;
    let sysroot = wasi_sysroot();
    let clang = std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned());
    let dir = std::env::temp_dir().join(format!("om-wasm-include-{}-{prefix}", std::process::id()));
    std::fs::create_dir_all(&dir).map_err(|_| "CodegenWasmJit: cannot create a temporary directory")?;
    let tu = dir.join(format!("{prefix}_includes.c"));
    let out = dir.join(format!("{prefix}_includes.wasm"));
    std::fs::write(&tu, [INCLUDE_PREAMBLE, &includes.join("\n"), "\n", wrappers].concat())
        .map_err(|_| "CodegenWasmJit: cannot write the external \"C\" translation unit")?;

    let mut cmd = Command::new(&clang);
    cmd.args(["--target=wasm32-wasip1", "-O1", "-fPIC", "-shared", "-nodefaultlibs"])
        .arg(format!("--sysroot={}", sysroot.display()))
        .args(["-Wl,--export-all", "-Wl,--allow-undefined"]);
    // Only the preprocessor part of `--cflags`: the rest is host code generation.
    cmd.args(openmodelica_wasm_jit::model::cflags_cpp_args(cflags));
    // Compiled in a temporary directory, so `#include "x.h"` needs the model's own.
    if let Ok(cwd) = std::env::current_dir() {
        cmd.arg("-I").arg(cwd);
    }
    for dir in openmodelica_wasm_jit::model::omc_c_include_dirs() {
        cmd.arg("-I").arg(dir);
    }
    // `IncludeDirectory` annotations, already `-I"..."` strings.
    for inc in include_dirs {
        cmd.arg(inc.trim_matches('"'));
    }
    cmd.arg("-o").arg(&out).arg(&tu);
    if let Some(builtins) = wasm_builtins(&sysroot) {
        cmd.arg(builtins);
    }
    let output = match cmd.output() {
        Ok(o) => o,
        Err(e) => {
            notes.push(format!("`{clang}` could not be run to compile the `Include` C sources: {e}"));
            return Ok(None);
        }
    };
    if !output.status.success() {
        notes.push(format!(
            "the `Include` C sources did not compile for the wasm target:\n{}\n{}",
            openmodelica_wasm_jit::model::command_line(&cmd),
            String::from_utf8_lossy(&output.stderr)
        ));
        return Ok(None);
    }
    let bytes = std::fs::read(&out).map_err(|_| "CodegenWasmJit: cannot read the compiled include library")?;
    let _ = std::fs::remove_dir_all(&dir);
    Ok(Some(ExtLibrary { name: format!("{prefix}_includes.wasm"), bytes, fixed: false }))
}

#[cfg(target_arch = "wasm32")]
pub(crate) fn compile_include_library(
    _prefix: &str,
    includes: &[String],
    _include_dirs: &[String],
    _cflags: &str,
    _missing: &[ExtCallSig],
    notes: &mut Vec<String>,
) -> Result<Option<ExtLibrary>> {
    if includes.is_empty() {
        return Ok(None);
    }
    notes.push(
        "the implementation comes from an `Include` annotation with C source, which has to be \
         compiled — the browser omc has no compiler. Provide it as a `Library` built with \
         `clang --target=wasm32-wasip1 -fPIC -shared`"
            .to_string(),
    );
    Ok(None)
}

/// The sysroot omc ships, unless pointed elsewhere.
#[cfg(not(target_arch = "wasm32"))]
fn wasi_sysroot() -> std::path::PathBuf {
    if let Ok(p) = std::env::var("OMC_WASI_SYSROOT") {
        return std::path::PathBuf::from(p);
    }
    let home = openmodelica_util::Settings::getInstallationDirectoryPath()
        .map(|p| p.to_string())
        .unwrap_or_default();
    std::path::PathBuf::from(home).join("lib/wasm32-wasi/omc")
}

/// The shipped sysroot carries a copy; otherwise probe clang, whose 21 driver
/// looks under a per-triple directory while Debian still uses `lib/wasi`.
#[cfg(not(target_arch = "wasm32"))]
fn wasm_builtins(sysroot: &std::path::Path) -> Option<std::path::PathBuf> {
    let shipped = sysroot.join("lib/wasm32-wasip1/libclang_rt.builtins-wasm32.a");
    if shipped.exists() {
        return Some(shipped);
    }
    let out = std::process::Command::new(std::env::var("OMC_WASI_CLANG").unwrap_or_else(|_| "clang".to_owned()))
        .arg("-print-resource-dir")
        .output()
        .ok()?;
    let res = std::path::PathBuf::from(String::from_utf8_lossy(&out.stdout).trim().to_string());
    [
        res.join("lib/wasm32-unknown-wasip1/libclang_rt.builtins.a"),
        res.join("lib/wasi/libclang_rt.builtins-wasm32.a"),
    ]
    .into_iter()
    .find(|p| p.exists())
}

/// Whether the `Include` sources must become a wasm library even with nothing
/// missing from the `ext` imports: ModelicaExternalC calls C's overridable
/// `usertab` hook from inside the wasm, so no `ext` import names it and only the
/// sources say whether the model overrides the erroring default.
pub(crate) fn include_overrides_builtin(sources: &[String]) -> bool {
    sources.iter().any(|s| s.contains("usertab"))
}

/// The `external "C"` functions neither `libs` nor the libraries every run can
/// load (libc, ModelicaExternalC, LAPACK) export — what an `Include` still has to
/// provide.
pub(crate) fn missing_ext_symbols(ext_imports: &[ExtCallSig], libs: &[ExtLibrary]) -> Vec<ExtCallSig> {
    let mut defined: HashSet<&str> = HashSet::new();
    for bytes in libs.iter().map(|l| &l.bytes[..]).chain([LIBC_PIC, EXTERNAL_C_DYLINK, LAPACK_DYLINK]) {
        defined.extend(wasm_exports(bytes));
    }
    ext_imports.iter().filter(|s| !defined.contains(s.name.as_str())).cloned().collect()
}

/// What a dylink library needs from outside: the functions it calls (`env`) and
/// the ones whose address it takes (`GOT.func`).
fn dylink_needs(bytes: &[u8]) -> Vec<String> {
    use wasmparser::{Imports, TypeRef};
    let mut out = Vec::new();
    let mut add = |module: &str, name: &str, is_func: bool| {
        if (module == "env" && is_func) || module == "GOT.func" {
            out.push(name.to_string());
        }
    };
    for payload in wasmparser::Parser::new(0).parse_all(bytes).flatten() {
        let wasmparser::Payload::ImportSection(reader) = payload else { continue };
        for group in reader.into_iter().flatten() {
            match group {
                Imports::Single(_, imp) => add(imp.module, imp.name, matches!(imp.ty, TypeRef::Func(_))),
                Imports::Compact1 { module, items } => {
                    for it in items.into_iter().flatten() {
                        add(module, it.name, matches!(it.ty, TypeRef::Func(_)));
                    }
                }
                Imports::Compact2 { module, names, ty } => {
                    for n in names.into_iter().flatten() {
                        add(module, n, matches!(ty, TypeRef::Func(_)));
                    }
                }
            }
        }
    }
    out.sort();
    out.dedup();
    out
}

/// Which of `needs` nothing in the wasm world defines; `--allow-undefined` lets a
/// library link without them.
fn unresolved_dylink_needs(needs: &[String], lib: &ExtLibrary, others: &[ExtLibrary]) -> Vec<String> {
    let mut defined: HashSet<&str> = HashSet::new();
    for bytes in others
        .iter()
        .map(|l| &l.bytes[..])
        .chain([&lib.bytes[..], LIBC_PIC, EXTERNAL_C_DYLINK, LAPACK_DYLINK, openmodelica_wasm_jit::RUNTIME_WASM])
    {
        defined.extend(wasm_exports(bytes));
    }
    needs.iter().filter(|n| !defined.contains(n.as_str())).cloned().collect()
}

/// The `-L` directories of a linker flag string (`-Ldir`, `-L"dir"`, `-L dir`).
/// It is a shell command line, so quotes group rather than belong to the path.
fn ld_search_dirs(flags: &str) -> Vec<String> {
    let mut words: Vec<String> = Vec::new();
    let mut word = String::new();
    let mut quote: Option<char> = None;
    for c in flags.chars() {
        match (quote, c) {
            (Some(q), c) if c == q => quote = None,
            (Some(_), c) => word.push(c),
            (None, '"' | '\'') => quote = Some(c),
            (None, c) if c.is_whitespace() => {
                if !word.is_empty() {
                    words.push(std::mem::take(&mut word));
                }
            }
            (None, c) => word.push(c),
        }
    }
    if !word.is_empty() {
        words.push(word);
    }
    let mut dirs = Vec::new();
    let mut words = words.into_iter();
    while let Some(w) = words.next() {
        if w == "-L" {
            dirs.extend(words.next());
        } else if let Some(d) = w.strip_prefix("-L") {
            dirs.push(d.to_owned());
        }
    }
    dirs
}

/// A `Library` naming a C source file, which gcc compiles rather than links.
fn find_source_library(spec: &str, dirs: &[String]) -> Option<String> {
    if !spec.ends_with(".c") && !spec.ends_with(".cc") && !spec.ends_with(".cpp") && !spec.ends_with(".cxx") {
        return None;
    }
    dirs.iter().map(|d| format!("{d}{spec}")).find(|p| openmodelica_wasi::fs::exists(p))
}

/// What a host linker spec resolves to.
enum NativeLib {
    /// A shared object, which the loader opens as it is.
    Shared(String),
    /// A static archive or an object file, which [`ExtArchives`] has to link first.
    Archive(String),
    /// A soname no search directory held a file for, so only the platform's own
    /// loader can find it: a system dependency, not a file an export can ship.
    System(String),
}

fn is_link_input(name: &str) -> bool {
    // `gcc -c -o x.lib` spells an object file the MSVC way. On Windows the suffix
    // is a real static/import library, which no `cc -shared` makes loadable.
    name.ends_with(".a") || name.ends_with(".o") || (!cfg!(windows) && (name.ends_with(".lib") || name.ends_with(".obj")))
}

/// The platform library a host linker spec names. A `-lfoo` nothing under `dirs`
/// provides stays a plain soname, for the system loader to find the way the linker
/// would.
fn find_native_library(spec: &str, dirs: &[String]) -> Option<NativeLib> {
    if cfg!(target_arch = "wasm32") {
        return None; // no dynamic loader to fall back to
    }
    let (prefix, suffix) = (std::env::consts::DLL_PREFIX, std::env::consts::DLL_SUFFIX);
    let name = match spec.strip_prefix("-l") {
        Some(n) => n,
        // Any other linker flag (`-L`, `-Wl,…`, `-pthread`) names no library.
        None if spec.starts_with('-') => return None,
        None => spec,
    };
    // `.lib` is both spellings on Windows, with no `cc -shared` to sort them out.
    if cfg!(windows) && (name.ends_with(".obj") || name.ends_with(".lib")) {
        return None;
    }
    // A bare name is what the loader searches its own path for, not the working
    // directory `dirs[0]` matched it in.
    let found = |p: String| {
        let p = if p.contains(['/', '\\']) { p } else { format!("./{p}") };
        Some(if is_link_input(&p) { NativeLib::Archive(p) } else { NativeLib::Shared(p) })
    };
    if is_link_input(name) || name.contains(suffix) || name.contains(std::path::MAIN_SEPARATOR) {
        return dirs.iter().map(|d| format!("{d}{name}")).find(|p| std::path::Path::new(p).exists()).and_then(found);
    }
    // As ld searches: a directory at a time, the shared object before the archive.
    for dir in dirs {
        let candidates =
            [format!("{dir}{prefix}{name}{suffix}"), format!("{dir}{name}{suffix}"), format!("{dir}{prefix}{name}.a")];
        if let Some(p) = candidates.into_iter().find(|p| std::path::Path::new(p).exists()) {
            return found(p);
        }
    }
    (spec != name).then(|| NativeLib::System(format!("{prefix}{name}{suffix}")))
}

/// `<dir><name>` or `<dir>lib<name>`, the two spellings a `Library="foo"`
/// annotation is written with.
fn find_ext_library(name: &str, dirs: &[String]) -> Option<(String, Vec<u8>)> {
    let stem = name.strip_suffix(".wasm").unwrap_or(name);
    for dir in dirs {
        for candidate in [format!("{dir}{stem}.wasm"), format!("{dir}lib{stem}.wasm")] {
            if let Ok(bytes) = openmodelica_wasi::fs::read(&candidate) {
                return Some((candidate, bytes));
            }
        }
    }
    None
}

/// [`find_ext_library`] for a linker spec (`-lFoo`, `Foo`, `dir/Foo.wasm`).
fn find_wasm_library(spec: &str, dirs: &[String]) -> Option<(String, Vec<u8>)> {
    let name = match spec.strip_prefix("-l") {
        Some(n) => n,
        // Any other linker flag (`-L`, `-Wl,…`, `-pthread`) names no library.
        None if spec.starts_with('-') => return None,
        None => spec,
    };
    find_ext_library(name, dirs)
}

/// Whether the built-in ModelicaExternalC side module defines an `external "C"`
/// the model's own libraries leave open ([`SimModel::ext_builtin`]). It carries
/// the whole MSL C set, which no installed `.wasm` names, so it is matched by
/// symbol rather than by `Library` name.
///
/// It does not join `ext_libs`: those are the model's *own*, and the FMU link adds
/// this one itself.
fn builtin_wasm_needed(ext_imports: &[ExtCallSig], libs: &[ExtLibrary]) -> bool {
    if EXTERNAL_C_DYLINK.is_empty() {
        return false;
    }
    let mut open: HashSet<&str> = ext_imports.iter().map(|s| s.name.as_str()).collect();
    for l in libs {
        for n in wasm_exports(&l.bytes) {
            open.remove(n);
        }
    }
    !open.is_empty() && wasm_exports(EXTERNAL_C_DYLINK).any(|n| open.contains(n))
}

/// Renames the model's `rt`/`ext` import modules → `env`, the dylink convention
/// `wit_component::Linker` resolves against (so `ext.<fn>` binds to the
/// ModelicaExternalC side module's export `<fn>`).
struct RtToEnv;
impl RtToEnv {
    fn rename(module: &str) -> &str {
        if module == "rt" || module == "ext" { "env" } else { module }
    }
}
impl wasm_encoder::reencode::Reencode for RtToEnv {
    type Error = core::convert::Infallible;
    /// `parse_imports`, not `parse_import`: only this one is on the section's
    /// dispatch path (`parse_import` is a convenience wrapper nothing calls).
    fn parse_imports(
        &mut self,
        imports: &mut wasm_encoder::ImportSection,
        group: wasmparser::Imports<'_>,
    ) -> core::result::Result<(), wasm_encoder::reencode::Error<Self::Error>> {
        let group = match group {
            wasmparser::Imports::Single(n, import) => wasmparser::Imports::Single(
                n,
                wasmparser::Import { module: Self::rename(import.module), ..import },
            ),
            wasmparser::Imports::Compact1 { module, items } => {
                wasmparser::Imports::Compact1 { module: Self::rename(module), items }
            }
            wasmparser::Imports::Compact2 { module, ty, names } => {
                wasmparser::Imports::Compact2 { module: Self::rename(module), ty, names }
            }
        };
        wasm_encoder::reencode::utils::parse_imports(self, imports, group)
    }
}

fn uleb(v: u32, out: &mut Vec<u8>) {
    let mut v = v;
    loop {
        let mut b = (v & 0x7f) as u8;
        v >>= 7;
        if v != 0 {
            b |= 0x80;
        }
        out.push(b);
        if v == 0 {
            break;
        }
    }
}

/// Splice a `dylink.0` section after the 8-byte header, marking the module a
/// shared-everything library. MEM_INFO is all-zero because the model has no
/// static data (its only data segment is passive) and no own table.
fn add_dylink0(module: &[u8]) -> Vec<u8> {
    add_dylink0_sized(module, 0, 0)
}

/// `mem_size` bytes of `__memory_base`-relative data, `mem_align` its log2 alignment.
fn add_dylink0_sized(module: &[u8], mem_size: u32, mem_align: u32) -> Vec<u8> {
    let mut meminfo = Vec::new();
    for v in [mem_size, mem_align, 0, 0] {
        uleb(v, &mut meminfo); // mem_size, mem_align, table_size, table_align
    }
    let mut sub = Vec::new();
    sub.push(1u8); // WASM_DYLINK_MEM_INFO
    uleb(meminfo.len() as u32, &mut sub);
    sub.extend_from_slice(&meminfo);
    let mut content = Vec::new();
    uleb(8, &mut content);
    content.extend_from_slice(b"dylink.0");
    content.extend_from_slice(&sub);
    let mut sec = Vec::new();
    sec.push(0u8); // custom section id
    uleb(content.len() as u32, &mut sec);
    sec.extend_from_slice(&content);
    let mut out = Vec::with_capacity(module.len() + sec.len());
    out.extend_from_slice(&module[..8]);
    out.extend_from_slice(&sec);
    out.extend_from_slice(&module[8..]);
    out
}

const NATIVE_EXT_ABSENT: &str = "om_ext_native_absent";

/// The me_cs adapter always imports `om:ext/native@0.1.0`, but only an export whose
/// `external "C"` a host must serve reaches it, and a component importing it is one
/// no fmi-ls-wasm host will instantiate. Point it at [`native_ext_absent`] instead.
fn drop_native_ext_import(adapter: &[u8]) -> Option<Vec<u8>> {
    const MODULE: &str = "om:ext/native@0.1.0";
    struct Redirect;
    impl wasm_encoder::reencode::Reencode for Redirect {
        type Error = core::convert::Infallible;
        fn parse_imports(
            &mut self,
            imports: &mut we::ImportSection,
            group: wasmparser::Imports<'_>,
        ) -> core::result::Result<(), wasm_encoder::reencode::Error<Self::Error>> {
            use wasmparser::Imports;
            let single = |ty| wasmparser::Import { module: "env", name: NATIVE_EXT_ABSENT, ty };
            match group {
                Imports::Single(n, import) if import.module == MODULE => {
                    let group = Imports::Single(n, single(import.ty));
                    wasm_encoder::reencode::utils::parse_imports(self, imports, group)
                }
                Imports::Compact1 { module: MODULE, items } => {
                    for item in items {
                        let group = Imports::Single(0, single(item?.ty));
                        wasm_encoder::reencode::utils::parse_imports(self, imports, group)?;
                    }
                    Ok(())
                }
                Imports::Compact2 { module: MODULE, ty, names } => {
                    for _ in names {
                        let group = Imports::Single(0, single(ty));
                        wasm_encoder::reencode::utils::parse_imports(self, imports, group)?;
                    }
                    Ok(())
                }
                group => wasm_encoder::reencode::utils::parse_imports(self, imports, group),
            }
        }
    }
    if !wasm_imports_module(adapter, MODULE) {
        return None;
    }
    use wasm_encoder::reencode::Reencode;
    let mut m = we::Module::new();
    Redirect.parse_core_module(&mut m, wasmparser::Parser::new(0), adapter).ok()?;
    Some(m.finish())
}

/// Defines [`NATIVE_EXT_ABSENT`] as a trap: its only caller is the stub of a
/// host-served `external "C"`, which such an export has none of.
fn native_ext_absent() -> Vec<u8> {
    let mut types = we::TypeSection::new();
    types.ty().function([we::ValType::I32; 4], []);
    let mut functions = we::FunctionSection::new();
    functions.function(0);
    let mut exports = we::ExportSection::new();
    exports.export(NATIVE_EXT_ABSENT, we::ExportKind::Func, 0);
    let mut code = we::CodeSection::new();
    let mut f = we::Function::new(Vec::<(u32, we::ValType)>::new());
    f.instruction(&we::Instruction::Unreachable);
    f.instruction(&we::Instruction::End);
    code.function(&f);
    let mut m = we::Module::new();
    m.section(&types).section(&functions).section(&exports).section(&code);
    add_dylink0(&m.finish())
}

fn wasm_imports_module(wasm: &[u8], module: &str) -> bool {
    use wasmparser::Imports;
    wasmparser::Parser::new(0).parse_all(wasm).flatten().any(|payload| {
        let wasmparser::Payload::ImportSection(reader) = payload else { return false };
        reader.into_iter().flatten().any(|group| match group {
            Imports::Single(_, imp) => imp.module == module,
            Imports::Compact1 { module: m, .. } | Imports::Compact2 { module: m, .. } => m == module,
        })
    })
}

/// Turn an emitted model kernel module into a dylink side module.
fn model_to_dylink(model_wasm: &[u8]) -> Result<Vec<u8>> {
    use wasm_encoder::reencode::Reencode;
    let mut re = RtToEnv;
    let mut m = wasm_encoder::Module::new();
    re.parse_core_module(&mut m, wasmparser::Parser::new(0), model_wasm)
        .map_err(|_| "CodegenWasmJit: cannot reencode model module to dylink")?;
    Ok(add_dylink0(&m.finish()))
}

/// `wit_component` rejects a library exporting both `__wasm_call_ctors` and
/// `_initialize`, which is what clang's reactor mode emits. Keep the dylink
/// convention. `openmodelica_wasi_libc` does this to ModelicaExternalC at build
/// time; a model's own `Library=`/`Include=` arrives already built.
fn drop_redundant_initialize(lib: &[u8]) -> Vec<u8> {
    let mut has_ctors = false;
    let mut has_initialize = false;
    for payload in wasmparser::Parser::new(0).parse_all(lib).flatten() {
        if let wasmparser::Payload::ExportSection(reader) = payload {
            for e in reader.into_iter().flatten() {
                has_ctors |= e.name == "__wasm_call_ctors";
                has_initialize |= e.name == "_initialize";
            }
        }
    }
    if !(has_ctors && has_initialize) {
        return lib.to_vec();
    }
    struct DropInitialize;
    impl wasm_encoder::reencode::Reencode for DropInitialize {
        type Error = std::convert::Infallible;
        fn parse_export_section(
            &mut self,
            exports: &mut wasm_encoder::ExportSection,
            section: wasmparser::ExportSectionReader<'_>,
        ) -> Result<(), wasm_encoder::reencode::Error<Self::Error>> {
            for e in section {
                let e = e?;
                if e.name != "_initialize" {
                    exports.export(e.name, self.export_kind(e.kind)?, self.external_index(e.kind, e.index)?);
                }
            }
            Ok(())
        }
    }
    use wasm_encoder::reencode::Reencode;
    let mut re = DropInitialize;
    let mut m = wasm_encoder::Module::new();
    match re.parse_core_module(&mut m, wasmparser::Parser::new(0), lib) {
        Ok(()) => m.finish(),
        Err(_) => lib.to_vec(),
    }
}

/// The `external` functions (import module `ext`) the model calls.
fn external_imports(model_wasm: &[u8]) -> Vec<String> {
    use wasmparser::Imports;
    let mut out = Vec::new();
    for payload in wasmparser::Parser::new(0).parse_all(model_wasm).flatten() {
        if let wasmparser::Payload::ImportSection(reader) = payload {
            for group in reader.into_iter().flatten() {
                match group {
                    Imports::Single(_, imp) if imp.module == "ext" => out.push(imp.name.to_string()),
                    Imports::Compact1 { module: "ext", items } => {
                        out.extend(items.into_iter().flatten().map(|it| it.name.to_string()));
                    }
                    Imports::Compact2 { module: "ext", names, .. } => {
                        out.extend(names.into_iter().flatten().map(|n| n.to_string()));
                    }
                    _ => {}
                }
            }
        }
    }
    out
}

/// The first `external "C"` import (module `ext`) in the model, if any. A
/// host-free FMU has no host to provide these, so the export names the function
/// rather than failing later inside `wit_component`.
fn first_external_import(model_wasm: &[u8]) -> Option<String> {
    external_imports(model_wasm).into_iter().next()
}

/// Whether the FMU has to carry [`LAPACK_DYLINK`]: the model calls a routine only
/// it defines. A model whose own `Library` resolved to a `liblapack.wasm` brings
/// its own, and then that one is linked instead of this 1.3 MB.
fn needs_lapack(model_wasm: &[u8], ext_libs: &[ExtLibrary]) -> bool {
    if LAPACK_DYLINK.is_empty() {
        return false;
    }
    let mut wanted: HashSet<String> = external_imports(model_wasm).into_iter().collect();
    if wanted.is_empty() {
        return false;
    }
    for bytes in ext_libs.iter().map(|l| &l.bytes[..]).chain([LIBC_PIC, EXTERNAL_C_DYLINK]) {
        for name in wasm_exports(bytes) {
            wanted.remove(name);
        }
    }
    wasm_exports(LAPACK_DYLINK).any(|name| wanted.contains(name))
}

/// The names a wasm module exports.
fn wasm_exports(bytes: &[u8]) -> impl Iterator<Item = &str> {
    wasmparser::Parser::new(0).parse_all(bytes).flatten().filter_map(|p| match p {
        wasmparser::Payload::ExportSection(exports) => Some(exports),
        _ => None,
    })
    .flat_map(|exports| exports.into_iter().flatten().map(|e| e.name))
}

/// `resources/native_externals.txt`: the platform libraries to load and the
/// functions to serve from them, in the form `openmodelica_ext_native_marshal`
/// parses. `libs` are file names under `binaries/<platform>/`; `system` are the
/// sonames the FMU does not ship, which its loader opens through the platform's.
fn native_externals_table(sigs: &[ExtCallSig], libs: &[String], system: &[String]) -> String {
    use openmodelica_wasm_jit::sig::ExtLang;
    let mut out = String::new();
    for l in libs {
        out.push_str(&format!("lib {l}\n"));
    }
    for l in system {
        out.push_str(&format!("extlib {l}\n"));
    }
    for sig in sigs {
        let mut code = String::new();
        let mut line = format!("fn {} {}", sig.name, if sig.lang == ExtLang::Fortran77 { "F" } else { "C" });
        match &sig.ret {
            Some(t) => {
                code.clear();
                t.write_code(&mut code);
                line.push_str(&format!(" {code}"));
            }
            None => line.push_str(" -"),
        }
        for (t, out) in &sig.args {
            code.clear();
            t.write_code(&mut code);
            line.push_str(&format!(" {}{code}", if *out { "*" } else { "" }));
        }
        out.push_str(&line);
        out.push('\n');
    }
    out
}

/// `sources/buildDescription.xml` declaring the libraries the FMU does not ship
/// (FMI 3.0 `<Library external="true"/>`). `system` are sonames; `name` carries the
/// linker name, as the schema's examples spell it.
fn external_build_description(model_id: &str, system: &[String]) -> String {
    let platform = native_fmu::host_platform().map(|p| format!(" platform=\"{}\"", p.fmi)).unwrap_or_default();
    let mut out = String::from(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\
         <fmiBuildDescription fmiVersion=\"3.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \
         xsi:noNamespaceSchemaLocation=\"https://raw.githubusercontent.com/modelica/fmi-standard/v3.0.2/schema/fmi3BuildDescription.xsd\">\n",
    );
    out.push_str(&format!("  <BuildConfiguration modelIdentifier=\"{}\"{platform}>\n", xml_escape(model_id)));
    for soname in system {
        let name = soname
            .strip_prefix(std::env::consts::DLL_PREFIX)
            .unwrap_or(soname)
            .strip_suffix(std::env::consts::DLL_SUFFIX)
            .unwrap_or(soname);
        out.push_str(&format!(
            "    <Library name=\"{}\" external=\"true\" description=\"a Library annotation named it; \
             resolved as {} by the loader of the platform running the FMU\"/>\n",
            xml_escape(name),
            xml_escape(soname),
        ));
    }
    out.push_str("  </BuildConfiguration>\n</fmiBuildDescription>\n");
    out
}

fn xml_escape(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;").replace('"', "&quot;")
}

/// The dylink stub module defining the host-served externals: each stores its
/// parameters in a frame of 8-byte slots, calls the adapter's
/// `om_ext_native_call(index, frame, table, table_len)` and loads the return value
/// from the slot after them. The table text rides in the module's data.
/// One 8-byte frame slot; wasm rejects an alignment hint larger than the access.
fn slot_mem(offset: u32, wty: openmodelica_wasm_jit::sig::WTy) -> we::MemArg {
    let align = match wty {
        openmodelica_wasm_jit::sig::WTy::F64 => 3,
        openmodelica_wasm_jit::sig::WTy::I32 => 2,
    };
    we::MemArg { offset: offset as u64, align, memory_index: 0 }
}

fn native_ext_stub(sigs: &[ExtCallSig], table: &str) -> Result<Vec<u8>> {
    let table_bytes = table.as_bytes();
    let frame_off = (table_bytes.len() as u32 + 7) & !7;
    let mut frame_slots = 1u32;
    let mut types = we::TypeSection::new();
    let val = |t: &openmodelica_wasm_jit::sig::SigTy| match t.wty() {
        openmodelica_wasm_jit::sig::WTy::I32 => we::ValType::I32,
        openmodelica_wasm_jit::sig::WTy::F64 => we::ValType::F64,
    };
    types.ty().function([we::ValType::I32; 4], []);
    let mut fn_sigs = Vec::with_capacity(sigs.len());
    for sig in sigs {
        let fs = sig.wasm_sig_c_shared();
        types.ty().function(fs.params.iter().map(val), fs.results.iter().map(val));
        frame_slots = frame_slots.max(fs.params.len() as u32 + 1);
        fn_sigs.push(fs);
    }
    let mut imports = we::ImportSection::new();
    imports.import("env", "memory", we::MemoryType { minimum: 0, maximum: None, memory64: false, shared: false, page_size_log2: None });
    imports.import("env", "__memory_base", we::GlobalType { val_type: we::ValType::I32, mutable: false, shared: false });
    imports.import("env", "om_ext_native_call", we::EntityType::Function(0));
    let mut functions = we::FunctionSection::new();
    let mut exports = we::ExportSection::new();
    let mut code = we::CodeSection::new();
    for (i, (sig, fs)) in sigs.iter().zip(&fn_sigs).enumerate() {
        functions.function(i as u32 + 1);
        exports.export(&sig.name, we::ExportKind::Func, i as u32 + 1);
        let mut f = we::Function::new(Vec::<(u32, we::ValType)>::new());
        for (p, t) in fs.params.iter().enumerate() {
            let mem = slot_mem(frame_off + 8 * p as u32, t.wty());
            f.instruction(&we::Instruction::GlobalGet(0));
            f.instruction(&we::Instruction::LocalGet(p as u32));
            f.instruction(&match t.wty() {
                openmodelica_wasm_jit::sig::WTy::F64 => we::Instruction::F64Store(mem),
                openmodelica_wasm_jit::sig::WTy::I32 => we::Instruction::I32Store(mem),
            });
        }
        f.instruction(&we::Instruction::I32Const(i as i32));
        f.instruction(&we::Instruction::GlobalGet(0));
        f.instruction(&we::Instruction::I32Const(frame_off as i32));
        f.instruction(&we::Instruction::I32Add);
        f.instruction(&we::Instruction::GlobalGet(0));
        f.instruction(&we::Instruction::I32Const(table_bytes.len() as i32));
        f.instruction(&we::Instruction::Call(0));
        if let Some(r) = fs.results.first() {
            let mem = slot_mem(frame_off + 8 * fs.params.len() as u32, r.wty());
            f.instruction(&we::Instruction::GlobalGet(0));
            f.instruction(&match r.wty() {
                openmodelica_wasm_jit::sig::WTy::F64 => we::Instruction::F64Load(mem),
                openmodelica_wasm_jit::sig::WTy::I32 => we::Instruction::I32Load(mem),
            });
        }
        f.instruction(&we::Instruction::End);
        code.function(&f);
    }
    let mut data = we::DataSection::new();
    data.active(0, &we::ConstExpr::global_get(0), table_bytes.iter().copied());
    let mut m = we::Module::new();
    m.section(&types).section(&imports).section(&functions).section(&exports).section(&code).section(&data);
    Ok(add_dylink0_sized(&m.finish(), frame_off + 8 * frame_slots, 3))
}

/// What an export with host-served externals adds: the stub linked in, and the
/// table and platform libraries written as resources.
struct NativeExternals {
    table: String,
    stub: Vec<u8>,
    /// (file name under `binaries/<platform>/`, contents)
    libs: Vec<(String, Vec<u8>)>,
    /// Sonames declared but not shipped, for `sources/buildDescription.xml`.
    system: Vec<String>,
}

#[cfg(not(target_arch = "wasm32"))]
fn native_externals(model: &SimModel, kind: &str) -> Result<Option<NativeExternals>> {
    if model.ext_native.is_empty() {
        return Ok(None);
    }
    let names: Vec<&str> = model.ext_native.iter().map(|s| s.name.as_str()).collect();
    if kind == "ME" {
        record_error(format!(
            "CodegenWasmJit: `external \"C\"` {} has no wasm implementation; only an me_cs wasm FMU \
             can serve it from a platform library (fmuType=\"me_cs\").",
            names.join(", ")
        ));
        return Err("CodegenWasmJit: host-served externals need an me_cs FMU");
    }
    let files = sim_runtime::native_external_library_files(model).map_err(|e| {
        record_error(format!(
            "CodegenWasmJit: `external \"C\"` {} has no wasm implementation and no platform library \
             this omc can ship either:\n{e}",
            names.join(", ")
        ));
        "CodegenWasmJit: unresolved host-served externals"
    })?;
    let mut libs = Vec::new();
    let mut system = Vec::new();
    for path in &files {
        // Declared, not shipped: no file behind the soname to pack.
        if model.ext_native_system.iter().any(|s| s == path) {
            system.push(path.clone());
            continue;
        }
        let name = std::path::Path::new(path).file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default();
        let bytes = std::fs::read(path).map_err(|e| {
            record_error(format!("CodegenWasmJit: cannot read `{path}`: {e}"));
            "CodegenWasmJit: cannot read a platform library"
        })?;
        libs.push((name, bytes));
    }
    let table =
        native_externals_table(&model.ext_native, &libs.iter().map(|(n, _)| n.clone()).collect::<Vec<_>>(), &system);
    let stub = native_ext_stub(&model.ext_native, &table)?;
    Ok(Some(NativeExternals { table, stub, libs, system }))
}

#[cfg(target_arch = "wasm32")]
fn native_externals(model: &SimModel, _kind: &str) -> Result<Option<NativeExternals>> {
    if let Some(sig) = model.ext_native.first() {
        record_error(format!(
            "CodegenWasmJit: `external \"C\"` `{}` has no wasm implementation, and the browser omc has \
             no platform library to serve it from.",
            sig.name
        ));
        return Err("CodegenWasmJit: unresolved external \"C\"");
    }
    Ok(None)
}

/// Link the adapter + model into an fmi-ls-wasm component (pure Rust, so it runs in
/// the browser omc too). When the model uses `external "C"`, ModelicaExternalC +
/// PIC `libc.so` are added as shared-everything libraries. The reactor adapter
/// bridges preview1 to the component's preview2 WASI: libc's calls, and the FMI
/// adapter's own `fd_write` for the simulation log.
fn link_fmu_component(
    model_wasm: &[u8],
    adapter: &[u8],
    solvers: Option<&[&str]>,
    ext_libs: &[ExtLibrary],
    native_stub: Option<&[u8]>,
) -> Result<Vec<u8>> {
    let sundials = solvers.is_some();
    if adapter.is_empty() {
        // The plain adapter is always built; the SUNDIALS one only where the
        // wasm SUNDIALS archives were, so name which is missing.
        if sundials {
            record_error(
                "CodegenWasmJit: this omc has no SUNDIALS FMI3 adapter, so a Co-Simulation FMU                  cannot embed CVODE or IDA. Export with `--fmiFlags=s:dassl` (or euler), or                  rebuild omc with RUST_OMC_ENABLE_SUNDIALS=ON."
                    .to_string(),
            );
            return Err("CodegenWasmJit: no SUNDIALS FMI3 adapter in this omc");
        }
        return Err("CodegenWasmJit: FMI3 adapter unavailable (build wasm32-unknown-unknown + -Z build-std)");
    }
    let has_ext = first_external_import(model_wasm).is_some();
    let model = model_to_dylink(model_wasm)?;
    let plain_adapter = native_stub.is_none().then(|| drop_native_ext_import(adapter)).flatten();
    let mut l = wit_component::Linker::default().validate(true);
    l = l.library("adapter", plain_adapter.as_deref().unwrap_or(adapter), false).map_err(link_err)?;
    if plain_adapter.is_some() {
        l = l.library("native_absent", &native_ext_absent(), false).map_err(link_err)?;
    }
    l = l.library("model", &model, false).map_err(link_err)?;
    // The adapter imports every solver whatever the flags say, so each is resolved
    // either way; what changes is whether the real library or its stub answers. CVODE
    // reaches the residual through a C function pointer, which works because every
    // library here imports the one `env.__indirect_function_table`.
    if let Some(wanted) = solvers {
        for lib in SOLVER_LIBRARIES {
            let bytes =
                if wanted.contains(&lib.name) { lib.module } else { lib.stub };
            l = l.library(lib.name, bytes, false).map_err(link_err)?;
        }
    }
    if needs_lapack(model_wasm, ext_libs) {
        l = l.library("lapack", LAPACK_DYLINK, false).map_err(link_err)?;
    }
    let real_solvers = solvers.is_some_and(|w| !w.is_empty());
    if has_ext || real_solvers {
        // modelicaexternalc before libc; the coexisting allocator (libc dlmalloc +
        // runtime rt_alloc over one shared heap) is intentional. A solver library
        // needs libc too, so it brings the same libraries along; the stubs do not.
        if has_ext {
            // First, so a symbol they define wins over ModelicaExternalC's.
            let ext_bytes: Vec<Vec<u8>> =
                ext_libs.iter().map(|lib| drop_redundant_initialize(&lib.bytes)).collect();
            for (lib, bytes) in ext_libs.iter().zip(&ext_bytes) {
                l = l.library(&lib.name, bytes, false).map_err(link_err)?;
            }
            if let Some(stub) = native_stub {
                l = l.library("native_stub", stub, false).map_err(link_err)?;
            }
            l = l.library("modelicaexternalc", EXTERNAL_C_DYLINK, false).map_err(link_err)?;
        }
        l = l.library("libc", LIBC_PIC, false).map_err(link_err)?;
        if has_ext {
            // Last, so a `usertab` from the model's own libraries wins.
            l = l.library("usertab", USERTAB_DYLINK, false).map_err(link_err)?;
        }
    }
    // Unconditional: the adapter is also what gives the FMU the stdout its
    // simulation log goes to.
    l = l.adapter("wasi_snapshot_preview1", WASI_P1_ADAPTER).map_err(link_err)?;
    l.encode().map_err(link_err)
}

fn link_err(e: impl core::fmt::Debug) -> &'static str {
    record_error(format!("CodegenWasmJit: FMI3 component link failed: {e:?}"));
    "CodegenWasmJit: FMI3 component link failed"
}

/// The `vr -> SimData slot` table the FMI3 adapter resolves getters/setters with.
/// The value references are `getFMI3ValueReference`'s, the ones `CodegenFMU3`
/// writes into `modelDescription.xml`. Variables with no slot are skipped; the
/// adapter reports an unresolvable vr as an error.
/// Also the fmi-ls-dae `EnableDAEParameter` value reference, 0 for a model without a DAE
/// formulation. The synthetic variables follow `CodegenFMU3`: time, then the event
/// indicators, then (`--daeMode`) the DAE-mode switch and the residuals.
fn build_fmi_vrs(sim_code: &SimCode::SimCode, map: &SimVarMap, layout: &SimLayout) -> Result<(Vec<FmiVr>, u32)> {
    use openmodelica_backend::SimCodeUtil;
    let vars = &sim_code.modelInfo.vars;
    let all = lst(&vars.stateVars)
        .chain(lst(&vars.derivativeVars))
        .chain(lst(&vars.algVars))
        .chain(lst(&vars.discreteAlgVars))
        .chain(lst(&vars.paramVars))
        .chain(lst(&vars.aliasVars))
        .chain(lst(&vars.intAlgVars))
        .chain(lst(&vars.intParamVars))
        .chain(lst(&vars.intAliasVars))
        .chain(lst(&vars.boolAlgVars))
        .chain(lst(&vars.boolParamVars))
        .chain(lst(&vars.boolAliasVars));
    // C's `mapOutputReference2RealOutputDerivatives`.
    let mut out_der: HashMap<String, u32> = HashMap::new();
    for sv in lst(&vars.outputVars) {
        let key = sim_cref_key(&sv.name)?;
        if let Some(slot) = map.vars.get(&format!("${key}_der")) {
            out_der.insert(key, slot.off);
        }
    }
    let mut lens: HashMap<String, u32> = HashMap::new();
    if let Some(ms) = &sim_code.modelStructure {
        for a in lst(&ms.fmiArrays) {
            lens.insert(sim_cref_key(&a.first)?, u32::try_from(a.numElements).unwrap_or(1));
        }
    }
    let mut out = Vec::new();
    for sv in all {
        let key = sim_cref_key(&sv.name)?;
        let Some(slot) = map.vars.get(&key).copied() else { continue };
        let vr: u32 = SimCodeUtil::getFMI3ValueReference(sv.clone(), sim_code.clone())?
            .parse()
            .map_err(|_| "CodegenWasmJit: FMI3 value reference is not a number")?;
        // A real variable's start slot: an init-mode set must go to the `start`
        // attribute, not to the live slot `setAllVarsToStart` is about to rewrite.
        let start_off = map.start_slots.get(&key).copied().unwrap_or(0);
        let der_off = out_der.get(&key).copied().unwrap_or(0);
        out.push(FmiVr {
            vr,
            off: slot.off,
            wty: slot.wty,
            negate: slot.negate,
            start_off,
            is_string: false,
            der_off,
            len: lens.get(&key).copied().unwrap_or(1),
        });
    }
    // String variables: `is_string` marks the slot as an i32 runtime-String
    // handle, so the adapter reads/writes it via `rt_str_*`, not as a number.
    for sv in lst(&vars.stringAlgVars)
        .chain(lst(&vars.stringParamVars))
        .chain(lst(&vars.stringAliasVars))
    {
        let key = sim_cref_key(&sv.name)?;
        let Some(slot) = map.vars.get(&key).copied() else { continue };
        let vr: u32 = SimCodeUtil::getFMI3ValueReference(sv.clone(), sim_code.clone())?
            .parse()
            .map_err(|_| "CodegenWasmJit: FMI3 value reference is not a number")?;
        out.push(FmiVr {
            vr,
            off: slot.off,
            wty: slot.wty,
            negate: slot.negate,
            start_off: 0,
            is_string: true,
            der_off: 0,
            len: lens.get(&key).copied().unwrap_or(1),
        });
    }
    // time, then the event indicators after it (`EventIndicatorVariables3`).
    let time_vr: u32 = SimCodeUtil::getFMI3TimeValueReference(sim_code.clone())?
        .parse()
        .map_err(|_| "CodegenWasmJit: FMI3 time value reference is not a number")?;
    out.push(FmiVr {
        vr: time_vr,
        off: TIME_OFF,
        wty: WTy::F64,
        negate: Neg::None,
        start_off: 0,
        is_string: false,
        der_off: 0,
        len: 1,
    });
    for k in 0..layout.n_zc {
        out.push(FmiVr {
            vr: time_vr + 1 + k,
            off: layout.zc_off + k * 8,
            wty: WTy::F64,
            negate: Neg::None,
            start_off: 0,
            is_string: false,
            der_off: 0,
            len: 1,
        });
    }
    let mut dae_enable_vr = 0;
    if let Some(d) = &sim_code.daeModeData {
        dae_enable_vr = time_vr + 1 + layout.n_zc;
        for sv in lst(&d.residualVars) {
            let i = u32::try_from(sv.index).map_err(|_| "CodegenWasmJit: DAE mode residual has no index")?;
            out.push(FmiVr {
                vr: dae_enable_vr + 1 + i,
                off: layout.dae_res_off + i * 8,
                wty: WTy::F64,
                negate: Neg::None,
                start_off: 0,
                is_string: false,
                der_off: 0,
                len: 1,
            });
        }
    }
    out.sort_by_key(|e| e.vr);
    out.dedup_by_key(|e| e.vr);
    Ok((out, dae_enable_vr))
}

/// CRC-32 (IEEE) for the ZIP entries.
fn crc32(data: &[u8]) -> u32 {
    let mut crc: u32 = 0xffff_ffff;
    for &b in data {
        crc ^= b as u32;
        for _ in 0..8 {
            crc = (crc >> 1) ^ (0xedb8_8320 & (0u32.wrapping_sub(crc & 1)));
        }
    }
    !crc
}

/// Raw deflate (ZIP method 8), or `None` when the input is not worth compressing.
fn deflate(data: &[u8]) -> Option<Vec<u8>> {
    if data.len() < 256 {
        return None;
    }
    Some(miniz_oxide::deflate::compress_to_vec(data, 6))
}

/// Add `path` (a file, or a directory copied whole) under `resources/<path>`,
/// keeping the absolute path so `rt_uri_to_filename` names it again at run time.
fn add_resource(entries: &mut Vec<(String, Vec<u8>)>, path: &str) {
    if openmodelica_wasi::fs::is_dir(path) {
        let Ok(dir) = openmodelica_wasi::fs::read_dir(path) else { return };
        for e in dir {
            add_resource(entries, &format!("{}/{}", path.trim_end_matches('/'), e.name));
        }
        return;
    }
    // A drive letter cannot be a directory name.
    let drive = path.len() > 2
        && path.as_bytes()[0].is_ascii_alphabetic()
        && path.as_bytes()[1] == b':'
        && matches!(path.as_bytes()[2], b'/' | b'\\');
    let name = if drive { path.replace(':', "").replace('\\', "/") } else { path.trim_start_matches('/').to_string() };
    if let Ok(bytes) = openmodelica_wasi::fs::read(path) {
        entries.push((format!("resources/{name}"), bytes));
    }
}

/// Ship `dir` as the FMU's `terminalsAndIcons/`: the XML SimCode wrote and the icons
/// the OMGraphics renderer put beside it, as the C export's `fmutmp` subtree is.
/// Ship everything under `dir` as `prefix/<path below dir>`, recursively: the
/// staged `documentation/` (whose images keep the modelica:// URI's own directory
/// structure) and `terminalsAndIcons/`.
fn add_directory(entries: &mut Vec<(String, Vec<u8>)>, dir: &str, prefix: &str) {
    if dir.is_empty() {
        return;
    }
    let dir = dir.trim_end_matches('/');
    let Ok(files) = openmodelica_wasi::fs::read_dir(dir) else { return };
    for e in files {
        let path = format!("{dir}/{}", e.name);
        let name = format!("{prefix}/{}", e.name);
        if e.is_dir {
            add_directory(entries, &path, &name);
        } else if let Ok(bytes) = openmodelica_wasi::fs::read(&path) {
            entries.push((name, bytes));
        }
    }
}

/// A ZIP assembled in-process rather than by an external `zip`, deflated unless
/// that would grow the entry.
/// `--fmuDirectory`: the same entries as files under `path`, which then names a
/// directory rather than a zip. A stale export of the same name is removed first,
/// so what is there is what this run wrote.
fn write_directory(path: &str, entries: &[(String, Vec<u8>)]) -> Result<()> {
    let root = std::path::Path::new(path);
    if root.is_dir() {
        let _ = std::fs::remove_dir_all(root);
    } else {
        let _ = std::fs::remove_file(root);
    }
    for (name, bytes) in entries {
        let out = root.join(name);
        if let Some(parent) = out.parent()
            && std::fs::create_dir_all(parent).is_err()
        {
            record_error(format!("CodegenWasmJit: cannot create {}", parent.display()));
            return Err("CodegenWasmJit: cannot write the FMU directory");
        }
        if write_output(&out.to_string_lossy(), bytes).is_err() {
            record_error(format!("CodegenWasmJit: cannot write {}", out.display()));
            return Err("CodegenWasmJit: cannot write the FMU directory");
        }
    }
    Ok(())
}

fn zip_archive(entries: &[(String, Vec<u8>)]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut central = Vec::new();
    let le16 = |v: u16, o: &mut Vec<u8>| o.extend_from_slice(&v.to_le_bytes());
    let le32 = |v: u32, o: &mut Vec<u8>| o.extend_from_slice(&v.to_le_bytes());
    let mut offsets: Vec<u32> = Vec::new();
    // Deflate once: the central directory must agree with the local headers.
    let stored: Vec<(u16, Vec<u8>)> = entries
        .iter()
        .map(|(_, data)| match deflate(data) {
            Some(z) if z.len() < data.len() => (8, z),
            _ => (0, data.clone()),
        })
        .collect();
    for ((name, data), (method, payload)) in entries.iter().zip(&stored) {
        offsets.push(out.len() as u32);
        let crc = crc32(data);
        let n = name.as_bytes();
        // local file header
        le32(0x0403_4b50, &mut out);
        le16(20, &mut out); // version needed
        le16(0, &mut out); // flags
        le16(*method, &mut out);
        le16(0, &mut out); // mod time
        le16(0x21, &mut out); // mod date (1980-01-01)
        le32(crc, &mut out);
        le32(payload.len() as u32, &mut out); // compressed size
        le32(data.len() as u32, &mut out); // uncompressed size
        le16(n.len() as u16, &mut out);
        le16(0, &mut out); // extra len
        out.extend_from_slice(n);
        out.extend_from_slice(payload);
    }
    let cd_start = out.len() as u32;
    for (((name, data), (method, payload)), off) in entries.iter().zip(&stored).zip(&offsets) {
        let crc = crc32(data);
        let n = name.as_bytes();
        le32(0x0201_4b50, &mut central);
        le16(20, &mut central); // version made by
        le16(20, &mut central); // version needed
        le16(0, &mut central); // flags
        le16(*method, &mut central);
        le16(0, &mut central); // time
        le16(0x21, &mut central); // date
        le32(crc, &mut central);
        le32(payload.len() as u32, &mut central);
        le32(data.len() as u32, &mut central);
        le16(n.len() as u16, &mut central);
        le16(0, &mut central); // extra
        le16(0, &mut central); // comment
        le16(0, &mut central); // disk
        le16(0, &mut central); // internal attrs
        le32(0, &mut central); // external attrs
        le32(*off, &mut central);
        central.extend_from_slice(n);
    }
    let cd_len = central.len() as u32;
    out.extend_from_slice(&central);
    // end of central directory
    le32(0x0605_4b50, &mut out);
    le16(0, &mut out); // disk
    le16(0, &mut out); // cd disk
    le16(entries.len() as u16, &mut out);
    le16(entries.len() as u16, &mut out);
    le32(cd_len, &mut out);
    le32(cd_start, &mut out);
    le16(0, &mut out); // comment len
    out
}

/// `CodegenWasmJit.emitMeFmu` / `emitCsFmu`: build the wasm FMU for `sim_code`
/// and write it to `fmu_path`. Host-free: no `wasm-merge`, no `zip`.
pub fn emitMeFmu(
    sim_code: SimCode::SimCode,
    fmu_path: ArcStr,
    _guid: ArcStr,
    model_description: ArcStr,
    ls_dae_manifest: ArcStr,
    documentation_dir: ArcStr,
    terminals_dir: ArcStr,
    simulation_flags_json: ArcStr,
) -> Result<()> {
    emit_fmu(sim_code, fmu_path, model_description, ls_dae_manifest, documentation_dir, terminals_dir, simulation_flags_json, FMI3_ME_ADAPTER, "ME")
}

/// Co-Simulation: the FMU integrates itself, so the adapter embeds the driver.
///
/// Served by the me_cs component, which substitutes for a `co-simulation-fmu`:
/// identical imports, a superset of its exports. `modelDescription.xml` still
/// declares CoSimulation alone; the unused ME exports cost ~38 KB against the
/// 1.28 MB a fourth adapter blob costs every omc.
pub fn emitCsFmu(
    sim_code: SimCode::SimCode,
    fmu_path: ArcStr,
    _guid: ArcStr,
    model_description: ArcStr,
    ls_dae_manifest: ArcStr,
    documentation_dir: ArcStr,
    terminals_dir: ArcStr,
    simulation_flags_json: ArcStr,
) -> Result<()> {
    emit_fmu(sim_code, fmu_path, model_description, ls_dae_manifest, documentation_dir, terminals_dir, simulation_flags_json, FMI3_MECS_ADAPTER, "CS")
}

/// me_cs: one component exporting both interfaces (the wasm equivalent of a
/// classic me_cs FMU — a single binary and modelIdentifier).
pub fn emitMeCsFmu(
    sim_code: SimCode::SimCode,
    fmu_path: ArcStr,
    _guid: ArcStr,
    model_description: ArcStr,
    ls_dae_manifest: ArcStr,
    documentation_dir: ArcStr,
    terminals_dir: ArcStr,
    simulation_flags_json: ArcStr,
) -> Result<()> {
    emit_fmu(sim_code, fmu_path, model_description, ls_dae_manifest, documentation_dir, terminals_dir, simulation_flags_json, FMI3_MECS_ADAPTER, "me_cs")
}

/// Say that the FMU answers `fmi3GetDirectionalDerivative` when the model was
/// compiled with its symbolic Jacobian, which the adapter answers from.
///
/// The shared template only sets the attribute from `<ModelStructure>`'s
/// `continuousPartialDerivatives`, which the C export needs and this one does
/// not: what matters here is whether the metadata carries the Jacobian.
fn announce_directional_derivatives(model_description: &str, model: &SimModel) -> String {
    let has_symbolic = model.jac_a.as_ref().is_some_and(|j| j.sym.is_some());
    if !has_symbolic {
        return model_description.to_string();
    }
    model_description.replace(
        "providesDirectionalDerivatives=\"false\"",
        "providesDirectionalDerivatives=\"true\"",
    )
}

/// The runtime's `-lv` streams as log categories of an FMI 3.0 export, so an
/// importer can ask the FMU for the trace `simulate()` would print.
fn declare_log_streams(model_description: &str) -> String {
    let end = model_description.find("</LogCategories>").filter(|_| fmi_version() == "3.0");
    let Some(end) = end else { return model_description.to_string() };
    let categories: String = omclog::STREAM_NAME[1..]
        .iter()
        .map(|s| format!("      <Category name=\"{s}\" />\n"))
        .collect();
    format!("{}{categories}    {}", &model_description[..end], &model_description[end..])
}

/// The FMI version being exported, `"3.0"` unless `buildModelFMU` asked otherwise.
fn fmi_version() -> String {
    let v = openmodelica_util::Flags::getConfigString(openmodelica_util::Flags::FMI_VERSION.clone())
        .unwrap_or_default();
    if v.is_empty() { "3.0".to_string() } else { v.to_string() }
}

/// Where an unzipped export keeps the model kernel. Not `binaries/wasm32-wasip2/`,
/// which fmi-ls-wasm defines as a *component*: this is a dylink library, and only
/// a host that links it against the adapter can run it.
pub(crate) const DYLINK_DIR: &str = "binaries/wasm32-om-dylink";
/// The stub module for host-served externals, among the linked form's libraries.
pub(crate) const NATIVE_STUB: &str = "native_stub";
/// The host-served externals' table (`openmodelica_ext_native_marshal::parse`).
pub(crate) const NATIVE_TABLE: &str = "resources/native_externals.txt";

/// What the host has to load beside the model kernel, decided here because this
/// is where the model's `external "C"` libraries were resolved. A tiny JSON, read
/// by `CodegenWasmJit::artifact`.
/// `sundials` is the *fused* runtime's, which this form binds the model to: it links
/// the archives statically, so it has every solver whatever the flags say.
fn artifact_manifest(model: &SimModel, sundials: bool) -> String {
    let ext = first_external_import(&model.wasm).is_some();
    let mut out = String::from("{\n");
    out.push_str(&format!("  \"externalC\": {ext},\n"));
    out.push_str(&format!("  \"lapack\": {},\n", needs_lapack(&model.wasm, &model.ext_libs)));
    out.push_str(&format!("  \"sundials\": {sundials},\n"));
    out.push_str(&format!("  \"extLibraries\": {}\n", model.ext_libs.len()));
    out.push_str("}\n");
    out
}

/// `--fmuDirectory`: write the export as an unzipped directory holding only what
/// an OpenModelica importer reads, rather than a portable FMU in a zip.
fn fmu_directory() -> bool {
    openmodelica_util::Flags::getConfigBool(openmodelica_util::Flags::FMU_DIRECTORY.clone())
        .unwrap_or(false)
}

/// A `-d=execstat` phase, beside the `FMU modelDescription.xml` ones the
/// MetaModelica side emits. Not a compiler notification: those reach
/// `getErrorString()`, where a timing makes every FMU test depend on the clock.
fn export_phase(name: &str) {
    let _ = openmodelica_util::ExecStat::execStat(ArcStr::from(name));
}

/// The platforms `platforms={...}` named besides `"wasm"`.
fn requested_native_platforms() -> Vec<String> {
    openmodelica_util::Flags::getConfigString(openmodelica_util::Flags::FMU_NATIVE_PLATFORMS.clone())
        .unwrap_or_default()
        .split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_owned)
        .collect()
}

/// Per platform named in `platforms={...}` besides `"wasm"`: the component
/// compiled ahead of time for it, plus the loader that serves the FMI C API from
/// that artifact. The FMU then works with a WebAssembly-unaware importer.
/// Compile the component for this machine and keep it, so the runs that follow
/// the export in this session neither serialize it nor read it back.
///
/// An unzipped export is for this omc, so it is always compiled — and then the
/// `.cwasm` need not be written at all unless `platforms` asked for one. A zipped
/// export is only compiled here if it is going to carry this machine's artifact
/// anyway. `None` if the engine refuses it; the caller then falls back to
/// [`native_fmu::precompile`].
#[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
fn compile_for_host(
    component: &[u8],
    fmu_path: &str,
    linked: bool,
    bare: bool,
) -> Option<std::sync::Arc<openmodelica_fmi_driver::component::WasmArtifact>> {
    // The unzipped form is not a component at all — the host links the model
    // kernel against the adapter it has already compiled — so there is nothing
    // here to compile ahead of time.
    if linked {
        return None;
    }
    let host = native_fmu::host_platform()?;
    // An unzipped export is for this omc: compiling here means the runs that
    // follow take the live component rather than each compiling it again.
    if !bare
        && !requested_native_platforms().iter().any(|n| native_fmu::lookup(n).is_some_and(|p| p.fmi == host.fmi))
    {
        return None;
    }
    // The resources it reads through are written after this, so the caller points
    // it at them ([`WasmArtifact::use_resources`]) and remembers it then.
    let _ = fmu_path;
    Some(std::sync::Arc::new(
        openmodelica_fmi_driver::component::WasmArtifact::compile(component, None).ok()?,
    ))
}

#[cfg(not(all(feature = "artifact", not(target_arch = "wasm32"))))]
fn compile_for_host(_component: &[u8], _fmu_path: &str, _linked: bool, _bare: bool) -> Option<()> {
    None
}

/// The `.cwasm` for `platform`: serialized out of what [`compile_for_host`] just
/// compiled when it is this machine's, and a cross-compile otherwise.
#[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
fn host_cwasm(
    host: Option<&std::sync::Arc<openmodelica_fmi_driver::component::WasmArtifact>>,
    platform: &native_fmu::Platform,
    component: &[u8],
) -> Result<Vec<u8>> {
    match host.filter(|_| native_fmu::host_platform().is_some_and(|h| h.fmi == platform.fmi)) {
        Some(a) => a.serialize().map_err(|e| {
            record_error(format!("CodegenWasmJit: serializing the artifact for {}: {e}", platform.fmi));
            "CodegenWasmJit: cannot serialize the compiled artifact"
        }),
        None => native_fmu::precompile(component, platform),
    }
}

#[cfg(not(all(feature = "artifact", not(target_arch = "wasm32"))))]
fn host_cwasm(_host: Option<&()>, platform: &native_fmu::Platform, component: &[u8]) -> Result<Vec<u8>> {
    native_fmu::precompile(component, platform)
}

fn add_native_platforms(
    entries: &mut Vec<(String, Vec<u8>)>,
    component: &[u8],
    model_id: &str,
    version: &str,
    linked: bool,
    natives: Option<&NativeExternals>,
    #[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
    host: Option<&std::sync::Arc<openmodelica_fmi_driver::component::WasmArtifact>>,
    #[cfg(not(all(feature = "artifact", not(target_arch = "wasm32"))))] host: Option<&()>,
) -> Result<()> {
    // The host-served externals' libraries, beside the platform's binary as FMI
    // has it; only this machine's exist.
    if let (Some(n), Some(host_platform)) = (natives, native_fmu::host_platform()) {
        let dir = native_fmu::fmi_dir(host_platform, version);
        for (name, bytes) in &n.libs {
            entries.push((format!("binaries/{dir}/{name}"), bytes.clone()));
        }
    }
    if linked {
        // Nothing to precompile: see `compile_for_host`.
        return Ok(());
    }
    for name in requested_native_platforms() {
        let Some(platform) = native_fmu::lookup(&name) else {
            record_error(format!(
                "CodegenWasmJit: `{name}` is not a platform a wasm FMU can be built for. \
                 Available: {}.",
                native_fmu::PLATFORMS.iter().map(|p| p.fmi).collect::<Vec<_>>().join(", ")
            ));
            return Err("CodegenWasmJit: unknown FMU platform");
        };
        let dir = native_fmu::fmi_dir(platform, version);
        let Some(loader) = native_fmu::loader(platform) else {
            record_error(format!(
                "CodegenWasmJit: this omc has no FMI loader library for `{}`, so an FMU \
                 cannot serve that platform. Available: {}. Rebuild omc with \
                 OMC_FMU_NATIVE_TARGETS={} to add it.",
                platform.fmi,
                native_fmu::available().join(", "),
                platform.triple
            ));
            return Err("CodegenWasmJit: no FMU loader for the requested platform");
        };
        let cwasm = host_cwasm(host, platform, component)?;
        entries.push((
            format!("binaries/{dir}/{}", native_fmu::loader_file_name(platform, model_id)),
            loader,
        ));
        entries.push((format!("binaries/{dir}/{model_id}.cwasm"), cwasm));
    }
    Ok(())
}

/// One `--fmiFlags` entry, out of the `"name" : "value"` pairs `CodegenFMU`
/// renders into `resources/<prefix>_flags.json`.
fn fmi_flag(json: &str, name: &str) -> Option<String> {
    let key = format!("\"{name}\"");
    json.match_indices(&key).find_map(|(i, _)| {
        let rest = json[i + key.len()..].trim_start().strip_prefix(':')?.trim_start().strip_prefix('"')?;
        Some(rest[..rest.find('"')?].to_string())
    })
}

/// `fmi2GetReal` and friends name a base type, not a value-reference space: the
/// loader recovers the component's value reference by adding the offset for the
/// type the call names (`SimCodeUtil.getFMI2ValueReferenceOffsets`).
fn fmi2_vr_offsets(sim_code: &SimCode::SimCode) -> Result<String> {
    let offsets = openmodelica_backend::SimCodeUtil::getFMI2ValueReferenceOffsets(sim_code.modelInfo.clone());
    let [real, integer, boolean, string] = lst(&offsets).collect::<Vec<_>>()[..] else {
        return Err("CodegenWasmJit: expected four FMI 2.0 value-reference offsets");
    };
    Ok(format!("{{\"real\":{real},\"integer\":{integer},\"boolean\":{boolean},\"string\":{string}}}\n"))
}

/// The distinct CAD file references (`<type>` values ending in a CAD extension)
/// in a `_visual.xml`, in document order.
fn cad_type_refs(visual_xml: &str) -> Vec<String> {
    let mut out: Vec<String> = Vec::new();
    let mut rest = visual_xml;
    while let Some(i) = rest.find("<type>") {
        rest = &rest[i + "<type>".len()..];
        let Some(j) = rest.find("</type>") else { break };
        let t = &rest[..j];
        let lower = t.to_ascii_lowercase();
        if [".dxf", ".stl", ".obj", ".3ds"].iter().any(|e| lower.ends_with(e))
            && !out.iter().any(|s| s == t)
        {
            out.push(t.to_string());
        }
        rest = &rest[j + "</type>".len()..];
    }
    out
}

/// The FMU-resource file name for a CAD reference (its basename).
fn cad_basename(uri: &str) -> &str {
    uri.rsplit(['/', '\\']).next().unwrap_or(uri)
}

/// The integrator a Co-Simulation FMU embeds: `-s` from the export's `_flags.json`,
/// else the model's own method, with DASKR for one this build cannot step with. A
/// `--daeMode` model integrates with IDA. Empty for Model Exchange.
fn fmu_cs_method(simulation_flags_json: &str, kind: &str, sim_code: &SimCode::SimCode) -> String {
    let own = sim_code.simulationSettingsOpt.as_ref().map(|s| s.method.to_string()).unwrap_or_default();
    cs_method_from(simulation_flags_json, kind, sim_code.daeModeData.is_some(), &own)
}

fn cs_method_from(simulation_flags_json: &str, kind: &str, dae_mode: bool, own: &str) -> String {
    if kind == "ME" {
        return String::new();
    }
    if dae_mode {
        return "ida".to_string();
    }
    if let Some(s) = fmi_flag(simulation_flags_json, "s") {
        return s;
    }
    let own = if own.is_empty() { "dassl".to_string() } else { own.to_string() };
    if fmu_cs_solvers().contains(&own.as_str()) {
        return own;
    }
    let _ = openmodelica_util::Error::addCompilerNotification(ArcStr::from(format!(
        "A Co-Simulation wasm FMU cannot integrate with method=\"{own}\"; it integrates with dassl. \
         Available: {}.",
        fmu_cs_solvers().join(", ")
    )));
    "dassl".to_string()
}

/// Lower the model kernel a wasm FMU is built around, and check that this omc and
/// this `kind` can serve it. Shared linear memory across model + runtime +
/// ModelicaExternalC, so `external "C"` calls pass real pointers rather than
/// runtime handles — which is also why the simulation path cannot bind it.
fn lower_fmu_kernel(
    sim_code: &SimCode::SimCode,
    kind: &str,
    cs_method: &str,
    fmi_solver_flags: &str,
) -> Result<SimModel> {
    let model = crate::CodegenWasmJitFunctions::with_shared_externals(|| {
        build_sim_model(sim_code, true, ExtHost::Wasm, cs_method, fmi_solver_flags)
    })?;
    if let Some(func) = first_external_import(&model.wasm) {
        if !external_c_available() {
            record_error(format!(
                "CodegenWasmJit: model `{}` uses the external C function `{func}`, but this omc \
                 was built without the PIC wasi-libc needed for external \"C\" in a host-free \
                 wasm FMU. Rebuild with a PIC wasi-libc (set OMC_WASI_PIC_SYSROOT), or simulate \
                 the model in the browser (`--simCodeTarget=wasm-jit`) instead.", model.model_name));
            return Err("CodegenWasmJit: external \"C\" support not built into this omc");
        }
    }
    check_fmu_method(&model, kind)?;
    Ok(model)
}

/// A CS FMU integrates itself, so an unservable method has to fail at export
/// rather than at the importer's first do-step.
fn check_fmu_method(model: &SimModel, kind: &str) -> Result<()> {
    if kind != "ME" && !fmu_cs_solvers().contains(&model.meta.cs_method.as_str()) {
        record_error(format!(
            "CodegenWasmJit: a Co-Simulation wasm FMU cannot integrate with method=\"{}\". \
             Available: {}.",
            model.meta.cs_method,
            fmu_cs_solvers().join(", ")
        ));
        return Err("CodegenWasmJit: unusable Co-Simulation integration method");
    }
    Ok(())
}

/// The kernel to build this FMU around: the one [`translateFmu`] left behind if it
/// was lowered the way this export needs, and a fresh lowering otherwise.
fn fmu_kernel(
    sim_code: &SimCode::SimCode,
    kind: &str,
    cs_method: &str,
    fmi_solver_flags: &str,
) -> Result<Arc<SimModel>> {
    let prefix = sim_code.fileNamePrefix.to_string();
    let cached = fmu_kernels().lock().unwrap_or_else(|e| e.into_inner()).get(&prefix).cloned();
    // Both are baked into the kernel's metadata, so a re-export that changed either
    // has to lower again rather than reuse what the last one left behind.
    if let Some(k) = cached
        .filter(|k| k.cs_method == cs_method && k.fmi_solver_flags == fmi_solver_flags)
    {
        check_fmu_method(&k.model, kind)?;
        return Ok(k.model.clone());
    }
    let model = Arc::new(lower_fmu_kernel(sim_code, kind, cs_method, fmi_solver_flags)?);
    keep_fmu_kernel(&prefix, &model);
    Ok(model)
}

fn keep_fmu_kernel(prefix: &str, model: &Arc<SimModel>) {
    fmu_kernels().lock().unwrap_or_else(|e| e.into_inner()).insert(
        prefix.to_string(),
        Arc::new(FmuKernel {
            model: model.clone(),
            cs_method: model.meta.cs_method.clone(),
            fmi_solver_flags: model.meta.fmi_solver_flags.clone(),
        }),
    );
}

/// `CodegenWasmJit.translateFmu`: the wasm counterpart of the C target generating
/// the FMU sources without building them. Lower the model once and keep it, both
/// for the `buildModelFMU` that follows and as the prepared simulation model, so a
/// run and an export share one kernel.
pub fn translateFmu(sim_code: SimCode::SimCode, fmu_type: ArcStr, simulation_flags_json: ArcStr) -> Result<()> {
    sync_engine_threading()?;
    sim_runtime::start_runtime_compile();
    let kind = fmu_kind(&fmu_type);
    let cs_method = fmu_cs_method(&simulation_flags_json, kind, &sim_code);
    let fmi_solver_flags = fmu_solver_flags(&simulation_flags_json);
    let prefix = sim_code.fileNamePrefix.to_string();
    let _ = openmodelica_wasi::fs::remove_file(&format!("{prefix}.wasm"));
    let errs_before = openmodelica_util::Error::getNumErrorMessages();
    let outcome = (|| -> Result<()> {
        // Lowered the way the simulation path binds it, since that is what runs it.
        // With no `external "C"` this is the FMU kernel too: shared externals
        // change the lowering only where there are `ext` imports.
        let model = Arc::new(build_sim_model(&sim_code, true, ExtHost::SIM, &cs_method, &fmi_solver_flags)?);
        check_fmu_method(&model, kind)?;
        write_output(&format!("{prefix}.wasm"), &model.wasm).map_err(|_| "CodegenWasmJit: write failed")?;
        sim_models().lock().unwrap_or_else(|e| e.into_inner()).insert(prefix.clone(), model.clone());
        // With `external "C"` the two differ, and the export lowers its own.
        if first_external_import(&model.wasm).is_none() {
            keep_fmu_kernel(&prefix, &model);
        }
        Ok(())
    })();
    if let Err(e) = &outcome {
        if openmodelica_util::Error::getNumErrorMessages() == errs_before {
            record_error(format!(
                "CodegenWasmJit: cannot build the FMU model kernel for `{prefix}`: {}",
                with_engine_detail(e)
            ));
        }
    }
    outcome
}

/// Keep the model translated the way `simulate` runs it, for `artifact::translated`.
/// Without `external "C"` the kernel is that model; with it the two lowerings
/// differ. Its compile is joined here so it counts as the build.
fn keep_translated_model(sim_code: &SimCode::SimCode, kernel: &Arc<SimModel>) -> Result<()> {
    let prefix = sim_code.fileNamePrefix.to_string();
    let kept = sim_models().lock().unwrap_or_else(|e| e.into_inner()).get(&prefix).cloned();
    let model = match kept {
        Some(m) => m,
        None if first_external_import(&kernel.wasm).is_none() => kernel.clone(),
        None => Arc::new(build_sim_model(sim_code, true, ExtHost::SIM, &kernel.meta.cs_method, &kernel.meta.fmi_solver_flags)?),
    };
    if model.prepared.lock().unwrap_or_else(|e| e.into_inner()).is_none()
        && let Ok(compiled) = sim_runtime::take_compiled_model(&model)
    {
        *model.prepared.lock().unwrap_or_else(|e| e.into_inner()) = Some(compiled);
    }
    sim_models().lock().unwrap_or_else(|e| e.into_inner()).insert(prefix, model);
    Ok(())
}

/// `emit_fmu`'s `kind` for a `buildModelFMU(fmuType=)`.
fn fmu_kind(fmu_type: &str) -> &'static str {
    match fmu_type {
        "me" => "ME",
        "cs" => "CS",
        _ => "me_cs",
    }
}

/// `adapter` is `(plain, with-SUNDIALS)`; the second is picked for a method that needs
/// CVODE/IDA and is empty for Model Exchange.
/// `openmodelica_fmi::lsdae::MANIFEST_PATH`, which the web build does not link.
const LS_DAE_MANIFEST: &str = "extra/org.fmi-standard.fmi-ls-dae/fmi-ls-manifest.xml";

#[allow(clippy::too_many_arguments)]
fn emit_fmu(
    sim_code: SimCode::SimCode,
    fmu_path: ArcStr,
    model_description: ArcStr,
    ls_dae_manifest: ArcStr,
    documentation_dir: ArcStr,
    terminals_dir: ArcStr,
    simulation_flags_json: ArcStr,
    adapter: &[u8],
    kind: &str,
) -> Result<()> {
    sync_engine_threading()?;
    sim_runtime::start_runtime_compile();
    let cs_method = fmu_cs_method(&simulation_flags_json, kind, &sim_code);
    let fmi_solver_flags = fmu_solver_flags(&simulation_flags_json);
    // Emitting the model takes seconds; a host that compiles the native platforms
    // out of process can spend them loading its compiler.
    if !requested_native_platforms().is_empty() {
        native_fmu::preload_aot_compiler();
    }
    let errs_before = openmodelica_util::Error::getNumErrorMessages();
    let outcome = (|| -> Result<()> {
        let model = fmu_kernel(&sim_code, kind, &cs_method, &fmi_solver_flags)?;
        export_phase("FMU model kernel");
        let natives = native_externals(&model, kind)?;
        let bare = fmu_directory();
        if bare {
            keep_translated_model(&sim_code, &model)?;
            export_phase("FMU translated model");
        }
        let cs = kind != "ME";
        // Both adapters import every solver, real or stubbed; only the integrator is
        // Co-Simulation's alone.
        let solvers = sundials_available()
            .then(|| fmu_solver_libraries(&simulation_flags_json, &cs_method, cs, model.sparse_nls));
        // An unzipped export is for an OpenModelica importer: it holds the model
        // description and the model kernel and nothing else, and the host links
        // that kernel against an adapter it compiled once into
        // `~/.openmodelica/cache`. A component would carry that megabyte itself
        // and be compiled with it, which is nearly all of what exporting a small
        // model used to cost. `OMC_WASM_LINKED_ARTIFACT=0` asks for one anyway.
        let linked = bare && std::env::var("OMC_WASM_LINKED_ARTIFACT").as_deref() != Ok("0");
        let component = if linked {
            // The model kernel exactly as the ordinary simulation path runs it —
            // not a dylink library. PIC would put its every data access behind
            // `__memory_base` and its calls through the indirect table, in the
            // loop that dominates a run; only the *adapter* has to be relocatable,
            // because only the adapter is shared between models.
            model.wasm.clone()
        } else {
            link_fmu_component(
                &model.wasm,
                adapter,
                solvers.as_deref(),
                &model.ext_libs,
                natives.as_ref().map(|n| &n.stub[..]),
            )?
        };
        export_phase("FMU component link");
        // The modelIdentifier modelDescription.xml declares, not the class name:
        // an importer resolves `binaries/<platform>/<modelIdentifier>`.
        let model_id = model_name_prefix(&sim_code);
        let mut entries = vec![
            (
                "modelDescription.xml".to_string(),
                declare_log_streams(&announce_directional_derivatives(&model_description, &model)).into_bytes(),
            ),
        ];
        if !ls_dae_manifest.is_empty() {
            entries.push((LS_DAE_MANIFEST.to_string(), ls_dae_manifest.as_bytes().to_vec()));
        }
        if !bare {
            add_directory(&mut entries, &documentation_dir, "documentation");
            add_directory(&mut entries, &terminals_dir, "terminalsAndIcons");
        }
        // What the FMU was built with, where C's carries what its runtime reads.
        if !simulation_flags_json.is_empty() {
            entries.push((
                format!("resources/{}_flags.json", sim_code.fileNamePrefix),
                simulation_flags_json.as_bytes().to_vec(),
            ));
        }
        let version = fmi_version();
        // This machine's artifact, compiled once: the runs that follow in this
        // session get the live component and never read a `.cwasm` back.
        let host = compile_for_host(&component, &fmu_path, linked, bare);
        add_native_platforms(&mut entries, &component, &model_id, &version, linked, natives.as_ref(), host.as_ref())?;
        export_phase("FMU precompile");
        if version == "2.0" {
            if requested_native_platforms().is_empty() {
                record_error(format!(
                    "CodegenWasmJit: an FMI 2.0 FMU can only be loaded through a native binary — \
                     fmi-ls-wasm, which is what platforms={{\"wasm\"}} alone produces, is layered on \
                     FMI 3.0. Add the platforms to serve ({}), or export with version=\"3.0\".",
                    native_fmu::available().join(", ")
                ));
                return Err("CodegenWasmJit: an FMI 2.0 FMU needs a native platform");
            }
            entries.push(("resources/fmi2vr.json".to_string(), fmi2_vr_offsets(&sim_code)?.into_bytes()));
            // Not in binaries/: an FMI 2.0 FMU is not an fmi-ls-wasm one. Here so
            // a platform can still be added to it later, as the browser page does.
            entries.push((format!("resources/{model_id}.wasm"), component));
        } else if linked {
            // Not a component: the model kernel as a dylink library, which the host
            // links against the adapter and libc it has already compiled.
            entries.push((format!("{DYLINK_DIR}/{model_id}.wasm"), component));
            entries.push(("resources/artifact.json".to_string(), artifact_manifest(&model, sundials_available()).into_bytes()));
            for (i, lib) in model.ext_libs.iter().enumerate() {
                entries.push((format!("resources/ext/{i:02}.wasm"), lib.bytes.clone()));
            }
            if let Some(n) = &natives {
                entries.push((format!("resources/ext/{NATIVE_STUB}.wasm"), n.stub.clone()));
            }
        } else if natives.is_some() {
            // Imports `om:ext/native`, so no fmi-ls-wasm host can instantiate it:
            // out of `binaries/`, as an FMI 2.0 export is for the same reason.
            let names: Vec<&str> = model.ext_native.iter().map(|s| s.name.as_str()).collect();
            let _ = openmodelica_util::Error::addCompilerNotification(ArcStr::from(format!(
                "`external \"C\"` {} is served from a platform library, so this FMU's wasm binary \
                 imports `om:ext/native`, which fmi-ls-wasm does not define. It is at \
                 `resources/{model_id}.wasm` rather than `binaries/wasm32-wasip2/`, and runs only \
                 in an OpenModelica host or through one of the FMU's native platform binaries.",
                names.join(", ")
            ).as_str()));
            entries.push((format!("resources/{model_id}.wasm"), component));
        } else {
            entries.push((format!("binaries/wasm32-wasip2/{model_id}.wasm"), component));
        }
        if let Some(n) = &natives {
            entries.push((NATIVE_TABLE.to_string(), n.table.clone().into_bytes()));
            if version == "3.0" && !n.system.is_empty() {
                entries.push(("sources/buildDescription.xml".to_string(), external_build_description(&model_id, &n.system).into_bytes()));
            }
        }
        // What `Modelica.Utilities.Files.loadResource` named; C's `SimCodeMain`
        // copies the same set.
        for path in lst(&sim_code.modelInfo.resourcePaths) {
            add_resource(&mut entries, path);
        }
        // Ship the -d=visxml scene as a resource (the <Visualization> annotation
        // points at it), plus the CAD files it references so the scene is
        // self-contained. openmodelica_wasi::fs, not std::fs, which no-ops on wasm.
        if openmodelica_util::Flags::isSet(openmodelica_util::Flags::VISUAL_XML.clone()).unwrap_or(false) {
            let visual = format!("{}_visual.xml", sim_code.fileNamePrefix);
            if let Ok(data) = openmodelica_wasi::fs::read(&visual) {
                let xml = String::from_utf8_lossy(&data).into_owned();
                entries.push((format!("resources/{visual}"), data));
                for uri in cad_type_refs(&xml) {
                    let base = cad_basename(&uri);
                    if let Ok(path) = metamodelica::uriToFilename(ArcStr::from(uri.as_str())) {
                        if let Ok(bytes) = openmodelica_wasi::fs::read(&path) {
                            entries.push((format!("resources/{base}"), bytes));
                        }
                    }
                }
            }
        }
        let (packed, how) = if bare {
            write_directory(&fmu_path, &entries)?;
            (entries.iter().map(|(_, b)| b.len()).sum::<usize>(), "unzipped")
        } else {
            let fmu = zip_archive(&entries);
            let n = fmu.len();
            write_output(&fmu_path, &fmu).map_err(|_| "CodegenWasmJit: cannot write .fmu")?;
            (n, "zipped")
        };
        // Now that the files are there, hand the compiled component to the runs
        // that follow, pointed at the resources they read through.
        #[cfg(all(feature = "artifact", not(target_arch = "wasm32")))]
        if let Some(a) = &host {
            let path = std::path::Path::new(&*fmu_path);
            let resources = path.join("resources");
            if bare && resources.is_dir() {
                a.use_resources(&resources);
            }
            artifact::remember(path, a.clone());
        }
        export_phase(&format!("FMU write ({} MB {how})", (packed as f64 / 1.0e6 * 10.0).round() / 10.0));
        Ok(())
    })();
    if let Err(e) = &outcome {
        if openmodelica_util::Error::getNumErrorMessages() == errs_before {
            record_error(format!(
                "CodegenWasmJit: cannot build FMI {} {kind} FMU: {}",
                fmi_version(),
                with_engine_detail(e)
            ));
        }
    }
    outcome
}

// ===========================================================================
// Building the variable->slot map and the result-variable list
// ===========================================================================

/// The data the equation-function lowering needs to resolve component
/// references: the cref->slot map and the per-variable start expressions.
#[derive(Clone)]
pub(crate) struct SimVarMap {
    /// Shared with every [`SimCtx`] rather than copied per generated function, so
    /// filled through `Arc::make_mut` (single owner until emission starts).
    pub(crate) vars: Arc<HashMap<String, SimSlot>>,
    starts: Arc<HashMap<String, Option<Arc<DAE::Exp>>>>,
    /// State cref key -> its start-value slot; when present, `$START.<key>` reads the
    /// slot instead of the inline expression.
    start_slots: Arc<HashMap<String, u32>>,
    /// Finalized array-variable groups (base cref key -> contiguous slot range).
    array_groups: Arc<HashMap<String, ArrayGroup>>,
    /// The arrays that are not one contiguous range (see `ScatterGroup`).
    scatter_groups: Arc<HashMap<String, ScatterGroup>>,
    /// `varKind = CONST` variables own no `SimData` slot: a reference is the
    /// binding literal, as in C's `varArrayNameValues`. `const_groups` is the
    /// `array_groups` counterpart, `const_acc` its transient accumulator.
    consts: Arc<HashMap<String, Arc<DAE::Exp>>>,
    const_groups: Arc<HashMap<String, ConstGroup>>,
    const_acc: HashMap<String, Vec<(Vec<i32>, Arc<DAE::Exp>, WTy)>>,
    /// Transient accumulator: base cref key -> the scalarized elements seen.
    /// Finalized into `array_groups` / `scatter_groups` at the end of
    /// [`build_var_map`].
    array_acc: HashMap<String, Vec<AccElem>>,
    /// `SimData` byte offset of the `terminate` flag (see [`SimLayout`]).
    terminate_off: u32,
    terminal_off: u32,
    initial_off: u32,
    /// `SimData` byte offset of the fired `terminate`'s message + source position.
    term_info_off: u32,
    /// `SimData` byte offset of the nonlinear-solver failure flag (see [`SimLayout`]).
    nls_fail_off: u32,
    /// `SES_NONLINEAR` system index -> its `rt_solve_nls` job. Filled by
    /// [`collect_nls_jobs`] before the equation functions are lowered.
    nls_jobs: Arc<HashMap<i32, NlsJob>>,
    /// `SimGenericCall` index -> the shared for-loop body (`generic_loop_calls`).
    generic_calls: Arc<HashMap<i32, SimCode::SimGenericCall>>,
    /// Number of `sample(...)` time events (see [`SampleInfo`]).
    n_samples: u32,
    /// `SimData` byte offset of the per-sample `active` flags (`SimLayout`).
    sample_active_off: u32,
    /// `SimData` byte offset of the held relation values (`SimLayout::relations_off`).
    relations_off: u32,
    /// `SimData` byte offset of the relation-evaluation-mode flag.
    rel_fresh_off: u32,
    /// `SimData` byte offset of the held relation snapshot (`SimLayout::stored_rel_off`).
    stored_rel_off: u32,
    /// `SimData` byte offset of `relationsPre` (`SimLayout::relations_pre_off`).
    relations_pre_off: u32,
    /// Number of indexed relations (bounds the `relations[]` region).
    n_relations: u32,
    /// `SimData` byte offset of the held math-event values (`mathEventsValuePre`).
    mathevents_off: u32,
    /// Number of math-event slots (bounds the `mathEventsValuePre` region).
    n_mathevents: u32,
    /// `SimData` byte offset of the homotopy parameter lambda (`SimLayout`).
    lambda_off: u32,
    /// C's `homotopyMethod` code (`SimLayout::homotopy_method`).
    homotopy_method: u8,
    /// `SimCtx::old_real`.
    old_real: Option<(u32, u32)>,
    /// `SimData` byte offset of the zero-crossing hysteresis tolerance (`SimCtx::zctol_off`).
    zctol_off: u32,
    /// `SimData` byte offset of `zeroCrossingsPre` (`SimLayout::zc_pre_off`).
    zc_pre_off: u32,
    /// `SimData` byte offset of the `$_clkfire` flags (`SimLayout::clock_fire_off`).
    clock_fire_off: u32,
    /// Number of `delay(...)` expression buffers (`delayedExps.maxDelayedIndex + 1`).
    n_delays: u32,
    /// Number of `spatialDistribution(...)` operators (`spatialInfo.maxIndex + 1`).
    n_spatial: u32,
    /// `+profiling`'s clock plan (`SimCtx::prof`).
    prof: Option<Arc<ProfPlan>>,
}

/// C's `crefStrXml`: the display name `_init.xml` carries into `modelData`'s
/// `info.name`, and with it the result file. `$DER` / `$PRE` qualifiers print as
/// `der(...)` / `pre(...)`, nesting included (`$DER.$DER.x` -> `der(der(x))`).
pub(crate) fn cref_display(cr: &Arc<DAE::ComponentRef>) -> Result<String> {
    use DAE::ComponentRef as C;
    Ok(match &**cr {
        C::CREF_QUAL { ident, componentRef, .. } if &**ident == "$DER" => {
            format!("der({})", cref_display(componentRef)?)
        }
        C::CREF_QUAL { ident, componentRef, .. } if &**ident == "$PRE" => {
            format!("pre({})", cref_display(componentRef)?)
        }
        C::CREF_QUAL { componentRef, .. } => format!(
            "{}.{}",
            ComponentReferenceBasics::printComponentRefStr(ComponentReferenceBasics::crefFirstCref(
                cr.clone()
            )?)?,
            cref_display(componentRef)?
        ),
        _ => ComponentReferenceBasics::printComponentRefStr(cr.clone())?.to_string(),
    })
}

/// C's `shouldFilterOutput`: protected variables and `HideResult=true`, each
/// switched back on by its own simflag.
fn filter_bits(sv: &SimCodeVar::SimVar) -> u8 {
    let mut f = 0;
    if sv.isProtected {
        f |= var_filter::PROTECTED;
        if sv.isEncrypted {
            f |= var_filter::ENCRYPTED;
        }
    }
    if sv.hideResult == Some(true) {
        f |= var_filter::HIDE_RESULT;
    }
    f
}

/// In the result file with no simflag asked for it — the `-override` reachable set.
fn is_result_output(sv: &SimCodeVar::SimVar) -> bool {
    filter_bits(sv) == 0
}

/// Resolve `simulate(..., variableFilter=)` — C's `initializeOutputFilter`, which
/// filters every name that does not match `^(<filter>)$`. C matches per run; the
/// runtimes have no regex engine, so it is settled here into
/// [`var_filter::FILTERED`], protected variables included (`-emit_protected`
/// can reach them). It walks the variable and *alias* arrays only, so a plain
/// parameter is never filtered.
fn apply_variable_filter(result_vars: &mut [ResultVar], filter: &str) {
    if filter == ".*" || filter.is_empty() {
        return;
    }
    let Ok(re) = openmodelica_util::System::Regex::new(&format!("^({filter})$")) else {
        eprintln!("Failed to compile regular expression: {filter}. Defaulting to outputting all variables.");
        return;
    };
    for v in result_vars.iter_mut() {
        let is_param = matches!(v.kind, ResultKind::Param { .. }) && v.filter & var_filter::ALIAS == 0;
        if !matches!(v.kind, ResultKind::Time) && !is_param && !re.is_match(&v.name) {
            v.filter |= var_filter::FILTERED;
        }
    }
}

/// The Modelica type of a variable, through subtype and array wrappers.
fn var_ty(ty: &DAE::Type) -> VarTy {
    match ty {
        DAE::Type::T_INTEGER { .. } | DAE::Type::T_ENUMERATION { .. } => VarTy::Integer,
        DAE::Type::T_BOOL { .. } => VarTy::Boolean,
        DAE::Type::T_STRING { .. } => VarTy::String,
        DAE::Type::T_SUBTYPE_BASIC { complexType, .. } => var_ty(complexType),
        DAE::Type::T_ARRAY { ty, .. } => var_ty(ty),
        _ => VarTy::Real,
    }
}

fn is_boolean_type(ty: &DAE::Type) -> bool {
    match ty {
        DAE::Type::T_BOOL { .. } => true,
        DAE::Type::T_SUBTYPE_BASIC { complexType, .. } => is_boolean_type(complexType),
        DAE::Type::T_ARRAY { ty, .. } => is_boolean_type(ty),
        _ => false,
    }
}

/// Literal names of an enumeration type; the stored value is the 1-based index
/// into these.
fn enumeration_names(ty: &DAE::Type) -> Option<Vec<String>> {
    match ty {
        DAE::Type::T_ENUMERATION { names, .. } => Some(lst(names).map(|n| n.to_string()).collect()),
        DAE::Type::T_SUBTYPE_BASIC { complexType, .. } => enumeration_names(complexType),
        DAE::Type::T_ARRAY { ty, .. } => enumeration_names(ty),
        _ => None,
    }
}

/// Map a display name ([`cref_display`], so a derivative already reads `der(x)`)
/// to the name it carries in the result file, or `None` to drop it. `$`-prefixed
/// names are backend-internal auxiliaries (`$cse*`, `$whenCondition*`, …) and are
/// not output.
/// C's `time_unvarying`: a variable a literal parameter equation assigns is
/// computed once at initialization, so the `.mat` stores it with the parameters
/// (`CodegenC.functionUpdateBoundParameters`, `Expression.isSimpleLiteralValue`).
fn mark_unvarying(result_vars: &mut [ResultVar], param_eqs: &[Arc<SimCode::SimEqSystem>]) -> Result<()> {
    let mut literal: HashSet<String> = HashSet::new();
    for eq in param_eqs {
        if let SimCode::SimEqSystem::SES_SIMPLE_ASSIGN { cref, exp, .. } = &**eq
            && matches!(
                &**exp,
                DAE::Exp::ICONST { .. } | DAE::Exp::RCONST { .. } | DAE::Exp::BCONST { .. } | DAE::Exp::ENUM_LITERAL { .. }
            )
            && let Some(name) = result_name(&cref_display(cref)?)
        {
            literal.insert(name);
        }
    }
    for v in result_vars.iter_mut() {
        if matches!(v.kind, ResultKind::Column { .. }) && v.filter & var_filter::ALIAS == 0 && literal.contains(&v.name) {
            v.unvarying = true;
        }
    }
    Ok(())
}

fn result_name(raw: &str) -> Option<String> {
    if raw.starts_with('$') && !OPT_RESULT_PREFIXES.iter().any(|p| raw.starts_with(p)) {
        None
    } else {
        Some(raw.to_string())
    }
}

/// The `$`-prefixed variables C's result file *does* carry: an `optimization`
/// model's objective terms (`BackendDAE.optimization{Mayer,Lagrange}TermName`) and
/// its constraint residuals (`DynamicOptimization`'s `$con$` / `$finalCon$` /
/// `$EqCon$`). The rest of the `$` namespace is the backend's own bookkeeping,
/// which C hides through `hideResult` and this port drops by name.
const OPT_RESULT_PREFIXES: [&str; 4] = ["$OMC$object", "$con$", "$finalCon$", "$EqCon$"];

/// Evaluate a constant variable's binding to a scalar, for the `*ConstVars`
/// lists (which have no SimData slot). Handles the literal forms model constants
/// actually take (numbers, booleans, enums, and unary minus thereof).
pub(crate) fn const_value(exp: &Option<Arc<DAE::Exp>>) -> Option<f64> {
    fn eval(e: &DAE::Exp) -> Option<f64> {
        use DAE::Exp as E;
        match e {
            E::ICONST { integer } => Some(*integer as f64),
            E::RCONST { real } => Some(real.into_inner()),
            E::BCONST { bool } => Some(if *bool { 1.0 } else { 0.0 }),
            E::ENUM_LITERAL { index, .. } => Some(*index as f64),
            E::UNARY { operator: DAE::Operator::UMINUS { .. }, exp } => eval(exp).map(|v| -v),
            E::CAST { exp, .. } => eval(exp),
            _ => None,
        }
    }
    exp.as_ref().and_then(|e| eval(e))
}

/// Classify a `SimData` slot (by byte offset) into how it appears in the result
/// file: a time-variant real reads a result-buffer column; a real/integer/
/// boolean parameter reads `data_1`. Integer/boolean *algebraic* variables (not
/// captured per row) and string variables have no numeric result column.
fn kind_from_slot(off: u32, wty: WTy, negate: Neg, heap: bool, layout: &SimLayout) -> Option<ResultKind> {
    if heap {
        // Strings: the row carries the interned text (`sim_meta::strings`) for an
        // algebraic one; a parameter is read at result-file open.
        if off >= layout.str_off && off < layout.sparam_off {
            return Some(ResultKind::Column { col: layout.str_col0() + (off - layout.str_off) / 4, negate });
        }
        if off >= layout.sparam_off && off < layout.eobj_off {
            return Some(ResultKind::Param { off, wty, negate });
        }
        return None;
    }
    if off == TIME_OFF {
        return Some(ResultKind::Column { col: 0, negate });
    }
    if off >= REAL_OFF && off < layout.rparam_off {
        // realVars region (states | derivatives | algebraics) -> data_2 column.
        return Some(ResultKind::Column { col: 1 + (off - REAL_OFF) / 8, negate });
    }
    // Integer / boolean *algebraic* variables are captured per row (as f64) in
    // the columns after the real part, so a varying one is recorded over time.
    if off >= layout.int_off && off < layout.iparam_off {
        let col = layout.n_reals_row() + (off - layout.int_off) / 4;
        return Some(ResultKind::Column { col, negate });
    }
    if off >= layout.bool_off && off < layout.bparam_off {
        let col = layout.n_reals_row() + layout.n_int_alg() + (off - layout.bool_off) / 4;
        return Some(ResultKind::Column { col, negate });
    }
    // Real / integer / boolean *parameters* are time-invariant -> data_1.
    let is_param = (off >= layout.rparam_off && off < layout.int_off)
        || (off >= layout.iparam_off && off < layout.bool_off)
        || (off >= layout.bparam_off && off < layout.str_off);
    if is_param {
        return Some(ResultKind::Param { off, wty, negate });
    }
    None // string slots
}

/// Expand every whole-array `SimVar` (`--simCodeScalarize=false`) into its
/// row-major scalar element `SimVar`s; already-scalar vars pass through.
fn scalarize_sim_vars(vars: &SimCodeVar::SimVars) -> Result<SimCodeVar::SimVars> {
    // Already scalarized by NBackend; the element vars still carry the parent's
    // numArrayElement, so re-expanding would duplicate them.
    if openmodelica_util::Flags::getConfigBool(openmodelica_util::Flags::SIM_CODE_SCALARIZE.clone())? {
        return Ok(vars.clone());
    }
    let mut out = vars.clone();
    out.stateVars = scalarize_var_list(&vars.stateVars)?;
    out.derivativeVars = scalarize_var_list(&vars.derivativeVars)?;
    out.algVars = scalarize_var_list(&vars.algVars)?;
    out.discreteAlgVars = scalarize_var_list(&vars.discreteAlgVars)?;
    out.realOptimizeConstraintsVars = scalarize_var_list(&vars.realOptimizeConstraintsVars)?;
    out.realOptimizeFinalConstraintsVars = scalarize_var_list(&vars.realOptimizeFinalConstraintsVars)?;
    out.intAlgVars = scalarize_var_list(&vars.intAlgVars)?;
    out.boolAlgVars = scalarize_var_list(&vars.boolAlgVars)?;
    out.inputVars = scalarize_var_list(&vars.inputVars)?;
    out.outputVars = scalarize_var_list(&vars.outputVars)?;
    out.aliasVars = scalarize_var_list(&vars.aliasVars)?;
    out.intAliasVars = scalarize_var_list(&vars.intAliasVars)?;
    out.boolAliasVars = scalarize_var_list(&vars.boolAliasVars)?;
    out.paramVars = scalarize_var_list(&vars.paramVars)?;
    out.intParamVars = scalarize_var_list(&vars.intParamVars)?;
    out.boolParamVars = scalarize_var_list(&vars.boolParamVars)?;
    out.stringAlgVars = scalarize_var_list(&vars.stringAlgVars)?;
    out.stringParamVars = scalarize_var_list(&vars.stringParamVars)?;
    out.stringAliasVars = scalarize_var_list(&vars.stringAliasVars)?;
    out.extObjVars = scalarize_var_list(&vars.extObjVars)?;
    out.constVars = scalarize_var_list(&vars.constVars)?;
    out.intConstVars = scalarize_var_list(&vars.intConstVars)?;
    out.boolConstVars = scalarize_var_list(&vars.boolConstVars)?;
    out.stringConstVars = scalarize_var_list(&vars.stringConstVars)?;
    Ok(out)
}

fn scalarize_var_list(list: &Arc<List<SimCodeVar::SimVar>>) -> Result<Arc<List<SimCodeVar::SimVar>>> {
    let mut out: Vec<SimCodeVar::SimVar> = Vec::new();
    for sv in &**list {
        let dims = array_dims_of(&sv.numArrayElement)?;
        if dims.is_empty() {
            out.push(sv.clone());
            continue;
        }
        for idx in row_major_indices(&dims) {
            let mut e = sv.clone();
            e.name = cref_with_indices(&sv.name, &idx);
            e.numArrayElement = metamodelica::nil();
            e.arrayCref = None;
            e.aliasvar = reindex_aliasvar(&sv.aliasvar, &idx);
            e.initialValue = index_attr(&sv.initialValue, &idx);
            e.nominalValue = index_attr(&sv.nominalValue, &idx);
            e.minValue = index_attr(&sv.minValue, &idx);
            e.maxValue = index_attr(&sv.maxValue, &idx);
            out.push(e);
        }
    }
    Ok(Arc::new(out.into_iter().collect::<List<SimCodeVar::SimVar>>()))
}

/// Parse `numArrayElement` (dimension sizes) to integers; empty for a scalar.
fn array_dims_of(nae: &Arc<List<ArcStr>>) -> Result<Vec<u32>> {
    let mut dims = Vec::new();
    for s in &**nae {
        match s.trim().parse::<u32>() {
            Ok(d) => dims.push(d),
            Err(_) => {
                record_error(format!("CodegenWasmJit: non-integer array dimension `{s}`"));
                return Err("CodegenWasmJit: non-integer array dimension");
            }
        }
    }
    Ok(dims)
}

/// All 1-based index tuples of shape `dims`, row-major (last axis fastest).
pub(crate) fn row_major_indices(dims: &[u32]) -> Vec<Vec<i32>> {
    let mut out = vec![Vec::new()];
    for &d in dims {
        let mut next = Vec::with_capacity(out.len() * d as usize);
        for prefix in &out {
            for i in 1..=d as i32 {
                let mut p = prefix.clone();
                p.push(i);
                next.push(p);
            }
        }
        out = next;
    }
    out
}

/// A copy of `cr` with `idx` appended as `INDEX` subscripts on its deepest ident.
fn cref_with_indices(cr: &Arc<DAE::ComponentRef>, idx: &[i32]) -> Arc<DAE::ComponentRef> {
    use DAE::ComponentRef as C;
    match &**cr {
        C::CREF_IDENT { ident, identType, .. } => {
            let subs: List<Arc<DAE::Subscript>> = idx
                .iter()
                .map(|&i| Arc::new(DAE::Subscript::INDEX { exp: Arc::new(DAE::Exp::ICONST { integer: i }) }))
                .collect();
            Arc::new(C::CREF_IDENT { ident: ident.clone(), identType: identType.clone(), subscriptLst: Arc::new(subs) })
        }
        C::CREF_QUAL { ident, identType, subscriptLst, componentRef } => Arc::new(C::CREF_QUAL {
            ident: ident.clone(),
            identType: identType.clone(),
            subscriptLst: subscriptLst.clone(),
            componentRef: cref_with_indices(componentRef, idx),
        }),
        _ => cr.clone(),
    }
}

/// Index an optional array-valued attribute (start/nominal/min/max) to element `idx`.
fn index_attr(attr: &Option<Arc<DAE::Exp>>, idx: &[i32]) -> Option<Arc<DAE::Exp>> {
    attr.as_ref().map(|e| index_exp(e, idx))
}

/// Element `idx` of an array expression: literal `ARRAY`/`MATRIX` indexed
/// statically, otherwise a simplified `ASUB` — `x(each start = 1)` arrives as
/// `{1.0 for $i in 1:n}`, which only folds through `simplifyAsub`.
fn index_exp(exp: &Arc<DAE::Exp>, idx: &[i32]) -> Arc<DAE::Exp> {
    use DAE::Exp as E;
    if idx.is_empty() {
        return exp.clone();
    }
    match &**exp {
        E::ARRAY { array, .. } => {
            if let Some(e) = (&**array).into_iter().nth((idx[0] - 1) as usize) {
                return index_exp(e, &idx[1..]);
            }
        }
        E::MATRIX { matrix, .. } if idx.len() >= 2 => {
            if let Some(row) = (&**matrix).into_iter().nth((idx[0] - 1) as usize) {
                if let Some(e) = (&**row).into_iter().nth((idx[1] - 1) as usize) {
                    return index_exp(e, &idx[2..]);
                }
            }
        }
        _ => {}
    }
    let sub: List<Arc<DAE::Subscript>> = idx
        .iter()
        .map(|&i| Arc::new(DAE::Subscript::INDEX { exp: Arc::new(E::ICONST { integer: i }) }))
        .collect();
    let asub = Arc::new(E::ASUB { exp: exp.clone(), sub: Arc::new(sub) });
    openmodelica_frontend_base::ExpressionSimplify::simplify1(asub.clone())
        .map(|(e, _)| e)
        .unwrap_or(asub)
}

/// Subscript an alias target by the same `idx`; `NOALIAS` passes through.
fn reindex_aliasvar(av: &SimCodeVar::AliasVariable, idx: &[i32]) -> SimCodeVar::AliasVariable {
    use SimCodeVar::AliasVariable as A;
    match av {
        A::ALIAS { varName } => A::ALIAS { varName: cref_with_indices(varName, idx) },
        A::NEGATEDALIAS { varName } => A::NEGATEDALIAS { varName: cref_with_indices(varName, idx) },
        A::NOALIAS => A::NOALIAS,
    }
}

/// Append the `$Sensitivities.<par>.<state>` result variables — the layout's
/// sensitivity block, in its order — and return the `SimData` offsets of the
/// parameters they differentiate against (C's `sensitivityParList`, resolved
/// through the `paramVars` order the real-parameter region follows). The names
/// bypass [`result_name`], which filters `$`-prefixed ones; C keeps them.
fn push_sensitivity_vars(
    sens_vars: &[&SimCodeVar::SimVar],
    n_sens_par: usize,
    vars: &SimCodeVar::SimVars,
    layout: &SimLayout,
    result_vars: &mut Vec<ResultVar>,
) -> Result<Vec<u32>> {
    if sens_vars.is_empty() {
        return Ok(Vec::new());
    }
    let params: HashMap<String, u32> = lst(&vars.paramVars)
        .enumerate()
        .map(|(k, sv)| Ok((cref_display(&sv.name)?, layout.rparam_off + (k as u32) * 8)))
        .collect::<Result<_>>()?;
    let mut offs = Vec::with_capacity(n_sens_par);
    for sv in &sens_vars[..n_sens_par] {
        let name = cref_display(&sv.name)?;
        let off = *params
            .get(&name)
            .ok_or("CodegenWasmJit: a sensitivity parameter is not a real parameter of the model")?;
        offs.push(off);
    }
    for (i, sv) in sens_vars[n_sens_par..].iter().enumerate() {
        result_vars.push(ResultVar {
            name: cref_display(&sv.name)?,
            comment: sv.comment.to_string(),
            kind: ResultKind::Column { col: layout.sens_col0() + i as u32, negate: Neg::None },
            unit: sv.unit.to_string(),
            display_unit: sv.displayUnit.to_string(),
            relative_quantity: sv.relativeQuantity,
            ty: var_ty(&sv.type_),
            discrete: sv.isDiscrete,
            filter: filter_bits(sv),
            unvarying: false,
            enumeration: None,
        });
    }
    Ok(offs)
}

/// Build the cref->slot map and the result-variable list from the model's
/// `SimVars`. The slot offsets follow [`SimLayout`]; the result order matches
/// the C runtime (time, states, state derivatives, real algebraics, then
/// parameters) so the `.mat` reads back identically.
fn build_var_map(
    vars: &SimCodeVar::SimVars,
    layout: &SimLayout,
) -> Result<(SimVarMap, Vec<ResultVar>, Vec<EditableParam>)> {
    let mut map = SimVarMap {
        vars: Arc::default(),
        starts: Arc::default(),
        start_slots: Arc::default(),
        array_groups: Arc::default(),
        scatter_groups: Arc::default(),
        consts: Arc::default(),
        const_groups: Arc::default(),
        const_acc: HashMap::new(),
        array_acc: HashMap::new(),
        terminate_off: layout.terminate_off,
        terminal_off: layout.terminal_off,
        initial_off: layout.initial_off,
        term_info_off: layout.term_info_off,
        nls_fail_off: layout.nls_fail_off,
        nls_jobs: Arc::new(HashMap::new()),
        generic_calls: Arc::new(HashMap::new()),
        n_samples: 0,
        sample_active_off: layout.sample_active_off,
        relations_off: layout.relations_off,
        rel_fresh_off: layout.rel_fresh_off,
        stored_rel_off: layout.stored_rel_off,
        relations_pre_off: layout.relations_pre_off,
        n_relations: layout.n_rel,
        mathevents_off: layout.mathevents_off,
        n_mathevents: layout.n_math,
        lambda_off: layout.lambda_off,
        homotopy_method: layout.homotopy_method.code(),
        old_real: layout.has_old_real.then_some((layout.rparam_off, layout.old_real_off)),
        zctol_off: layout.zctol_off,
        zc_pre_off: layout.zc_pre_off,
        clock_fire_off: layout.clock_fire_off,
        n_delays: 0,
        n_spatial: 0,
        prof: None,
    };
    let mut result_vars: Vec<ResultVar> = Vec::new();
    // User-settable parameters (isValueChangeable), collected as they are laid out.
    let mut editable: Vec<EditableParam> = Vec::new();
    // Collected separately: the `push_editable` closure borrows `editable`. Merged below.
    let mut start_editable: Vec<EditableParam> = Vec::new();
    let mut string_editable: Vec<EditableParam> = Vec::new();
    let mut push_editable = |sv: &SimCodeVar::SimVar, name: &str, off: u32, wty: WTy| {
        if sv.isValueChangeable && is_result_output(sv) {
            if let Some(disp) = result_name(name) {
                editable.push(EditableParam {
                    name: disp,
                    comment: sv.comment.to_string(),
                    unit: sv.unit.to_string(),
                    display_unit: sv.displayUnit.to_string(),
                    relative_quantity: sv.relativeQuantity,
                    off,
                    wty,
                    is_start: false,
                    is_bool: is_boolean_type(&sv.type_),
                    is_string: false,
                    enum_names: enumeration_names(&sv.type_).unwrap_or_default(),
                });
            }
        }
    };

    // time — result signal 0.
    result_vars.push(ResultVar {
        name: "time".to_string(),
        comment: "Simulation time [s]".to_string(),
        unit: "s".to_string(),
        display_unit: String::new(),
        relative_quantity: false,
        ty: VarTy::Real,
        discrete: false,
        kind: ResultKind::Time,
        filter: 0,
        unvarying: false,
        enumeration: None,
    });

    let states: Vec<&SimCodeVar::SimVar> = lst(&vars.stateVars).collect();
    let ders: Vec<&SimCodeVar::SimVar> = lst(&vars.derivativeVars).collect();

    // Push a primary (non-alias) variable: register its slot (equations reference
    // even protected ones) and list it as a result signal carrying why a run would
    // filter it — the overriding flags are not known here.
    let mut push_primary =
        |map: &mut SimVarMap, result_vars: &mut Vec<ResultVar>,
         sv: &SimCodeVar::SimVar, off: u32, wty: WTy, heap: bool, raw_name: String| -> Result<()> {
            insert_var(map, sv, off, wty, heap)?;
            if let Some(name) = result_name(&raw_name) {
                if let Some(kind) = kind_from_slot(off, wty, Neg::None, heap, layout) {
                    result_vars.push(ResultVar {
                        name,
                        comment: sv.comment.to_string(),
                        kind,
                        unit: sv.unit.to_string(),
                        display_unit: sv.displayUnit.to_string(),
            relative_quantity: sv.relativeQuantity,
                        ty: var_ty(&sv.type_),
                        discrete: sv.isDiscrete,
                        filter: filter_bits(sv),
                        unvarying: false,
                        enumeration: enumeration_names(&sv.type_),
                    });
                }
            }
            Ok(())
        };

    // States | derivatives | real algebraics -> the realVars region (data_2). Each
    // also owns a `start` attribute slot (C's `realVarsData[i].attribute.start`).
    let mut push_start = |map: &mut SimVarMap, sv: &SimCodeVar::SimVar, i: u32, name: &str| -> Result<()> {
        let start_off = layout.real_start_off(i);
        Arc::make_mut(&mut map.start_slots).insert(sim_cref_key(&sv.name)?, start_off);
        if sv.isValueChangeable && is_result_output(sv) {
            if let Some(disp) = result_name(name) {
                start_editable.push(EditableParam {
                    name: disp,
                    comment: sv.comment.to_string(),
                    unit: sv.unit.to_string(),
                    display_unit: sv.displayUnit.to_string(),
                    relative_quantity: sv.relativeQuantity,
                    off: start_off,
                    wty: WTy::F64,
                    is_start: true,
                    is_bool: is_boolean_type(&sv.type_),
                    is_string: false,
                    enum_names: enumeration_names(&sv.type_).unwrap_or_default(),
                });
            }
        }
        Ok(())
    };
    for (i, sv) in states.iter().enumerate() {
        let name = cref_display(&sv.name)?;
        push_start(&mut map, sv, i as u32, &name)?;
        push_primary(&mut map, &mut result_vars, sv, REAL_OFF + (i as u32) * 8, WTy::F64, false, name)?;
    }
    for (i, sv) in ders.iter().enumerate() {
        let name = cref_display(&sv.name)?;
        push_start(&mut map, sv, layout.n_states + i as u32, &name)?;
        push_primary(&mut map, &mut result_vars, sv, REAL_OFF + (layout.n_states + i as u32) * 8, WTy::F64, false, name)?;
    }
    let real_algs = real_alg_vars(vars);
    for (j, sv) in real_algs.iter().enumerate() {
        let name = cref_display(&sv.name)?;
        push_start(&mut map, sv, 2 * layout.n_states + j as u32, &name)?;
        push_primary(&mut map, &mut result_vars, sv, REAL_OFF + (2 * layout.n_states + j as u32) * 8, WTy::F64, false, name)?;
    }

    // Real / Integer / Boolean parameters -> data_1. Integer & Boolean algebraic
    // variables get slots (for equation resolution) but no result column yet
    // (they are not captured per row); strings get slots only.
    for (k, sv) in lst(&vars.paramVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.rparam_off + (k as u32) * 8;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::F64, false, name.clone())?;
        push_editable(sv, &name, off, WTy::F64);
    }
    for (i, sv) in lst(&vars.intAlgVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.int_off + (i as u32) * 4;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::I32, false, name)?;
    }
    for (k, sv) in lst(&vars.intParamVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.iparam_off + (k as u32) * 4;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::I32, false, name.clone())?;
        push_editable(sv, &name, off, WTy::I32);
    }
    for (i, sv) in lst(&vars.boolAlgVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.bool_off + (i as u32) * 4;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::I32, false, name)?;
    }
    for (k, sv) in lst(&vars.boolParamVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.bparam_off + (k as u32) * 4;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::I32, false, name.clone())?;
        push_editable(sv, &name, off, WTy::I32);
    }
    for (i, sv) in lst(&vars.stringAlgVars).enumerate() {
        let name = cref_display(&sv.name)?;
        push_primary(&mut map, &mut result_vars, sv, layout.str_off + (i as u32) * 4, WTy::I32, true, name)?;
    }
    for (k, sv) in lst(&vars.stringParamVars).enumerate() {
        let off = layout.sparam_off + (k as u32) * 4;
        push_primary(&mut map, &mut result_vars, sv, off, WTy::I32, true, cref_display(&sv.name)?)?;
        // Not a result signal, but `_init.xml` lists it and C's `-override` reaches it.
        if sv.isValueChangeable && is_result_output(sv)
            && let Some(disp) = result_name(&cref_display(&sv.name)?)
        {
            string_editable.push(EditableParam {
                name: disp,
                comment: sv.comment.to_string(),
                unit: sv.unit.to_string(),
                display_unit: String::new(),
                relative_quantity: false,
                off,
                wty: WTy::I32,
                is_start: false,
                is_bool: false,
                is_string: true,
                enum_names: Vec::new(),
            });
        }
    }
    // External objects: one i32 pointer-registry handle each. Not heap (no ARC);
    // the constructor (a parameter equation) writes the handle, the destructor
    // frees the native object. No result column.
    for (i, sv) in lst(&vars.extObjVars).enumerate() {
        insert_var(&mut map, sv, layout.eobj_off + (i as u32) * 4, WTy::I32, false)?;
    }

    // Compile-time constants (real / integer / boolean): no SimData slot — their
    // value is the binding literal. Emit each to data_1 (the C runtime keeps them
    // in the result too, e.g. visualization colors). Record their values so a
    // constant's aliases resolve below.
    let mut const_of: HashMap<String, f64> = HashMap::new();
    let const_lists = [
        (&vars.constVars, Some(WTy::F64)),
        (&vars.intConstVars, Some(WTy::I32)),
        (&vars.boolConstVars, Some(WTy::I32)),
        (&vars.stringConstVars, None),
    ];
    for sv in const_lists.iter().flat_map(|(l, wty)| lst(l).map(move |sv| (sv, *wty))) {
        let (sv, wty) = sv;
        let key = sim_cref_key(&sv.name)?;
        if let Some(exp) = sv.initialValue.clone() {
            Arc::make_mut(&mut map.consts).insert(key.clone(), exp.clone());
            if let (Some(wty), Some((base, subs))) = (wty, array_element_of(&sv.name)?) {
                map.const_acc.entry(base).or_default().push((subs, exp, wty));
            }
        }
        let Some(value) = const_value(&sv.initialValue) else { continue };
        const_of.insert(key, value);
        if let Some(name) = result_name(&cref_display(&sv.name)?) {
            result_vars.push(ResultVar {
                name,
                comment: sv.comment.to_string(),
                kind: ResultKind::Const { value },
                unit: sv.unit.to_string(),
                display_unit: sv.displayUnit.to_string(),
            relative_quantity: sv.relativeQuantity,
                ty: var_ty(&sv.type_),
                discrete: sv.isDiscrete,
                filter: filter_bits(sv),
                unvarying: false,
                enumeration: enumeration_names(&sv.type_),
            });
        }
    }

    // Aliases: resolve to the target variable's slot (with negation) so equations
    // and `$START` of an alias read the aliased value, AND emit the alias as a
    // result signal pointing at the target's data column / parameter (with sign)
    // — the C runtime's `dataInfo` aliasing, so the data is stored once.
    // A Boolean negation is logical, any other arithmetic (C's `crefToCStr`).
    let alias_lists = lst(&vars.aliasVars)
        .map(|v| (v, false))
        .chain(lst(&vars.intAliasVars).map(|v| (v, false)))
        .chain(lst(&vars.boolAliasVars).map(|v| (v, true)))
        .chain(lst(&vars.stringAliasVars).map(|v| (v, false)));
    for (av, is_bool) in alias_lists {
        let (target, negate) = match &av.aliasvar {
            SimCodeVar::AliasVariable::ALIAS { varName } => (varName.clone(), false),
            SimCodeVar::AliasVariable::NEGATEDALIAS { varName } => (varName.clone(), true),
            SimCodeVar::AliasVariable::NOALIAS => continue,
        };
        let tkey = sim_cref_key(&target)?;
        let time_slot = match &*target {
            DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } if ident.as_str() == "time" && subscriptLst.is_empty() => {
                Some(SimSlot { off: TIME_OFF, wty: WTy::F64, negate: Neg::None, heap: false })
            }
            _ => None,
        };
        let Some(tslot) = map.vars.get(&tkey).copied().or(time_slot) else {
            // Target has no slot: it may be a compile-time constant.
            if let Some(&cval) = const_of.get(&tkey) {
                if let Some(name) = result_name(&cref_display(&av.name)?) {
                    let value =
                        if negate { Neg::None.toggle(is_bool).apply_f64(cval) } else { cval };
                    result_vars.push(ResultVar {
                        name,
                        comment: av.comment.to_string(),
                        kind: ResultKind::Const { value },
                        unit: av.unit.to_string(),
                        display_unit: av.displayUnit.to_string(),
                        relative_quantity: av.relativeQuantity,
                        ty: var_ty(&av.type_),
                        discrete: av.isDiscrete,
                        filter: filter_bits(av) | var_filter::ALIAS,
                        unvarying: false,
                        enumeration: enumeration_names(&av.type_),
                    });
                }
            }
            continue;
        };
        let slot = SimSlot {
            off: tslot.off,
            wty: tslot.wty,
            negate: if negate { tslot.negate.toggle(is_bool) } else { tslot.negate },
            heap: tslot.heap,
        };
        Arc::make_mut(&mut map.vars).insert(sim_cref_key(&av.name)?, slot);
        // An alias array is assigned as a whole, so it needs a group over the
        // target's slots.
        for g in array_element_keys(&av.name)? {
            map.array_acc.entry(g.base).or_default().push(AccElem {
                subs: g.subs,
                pieces: g.pieces,
                off: slot.off,
                wty: slot.wty,
                neg: slot.negate,
                heap: slot.heap,
            });
        }
        if let (Some(name), Some(kind)) = (
            result_name(&cref_display(&av.name)?),
            kind_from_slot(slot.off, slot.wty, slot.negate, slot.heap, layout),
        ) {
            result_vars.push(ResultVar {
                name,
                comment: av.comment.to_string(),
                kind,
                unit: av.unit.to_string(),
                display_unit: av.displayUnit.to_string(),
                        relative_quantity: av.relativeQuantity,
                ty: var_ty(&av.type_),
                discrete: av.isDiscrete,
                filter: filter_bits(av) | var_filter::ALIAS,
                unvarying: false,
                enumeration: enumeration_names(&av.type_),
            });
        }
    }

    // `pre()` slots: for every live variable slot in a pre-carrying region
    // (real / integer / boolean variables, including aliases), register a
    // parallel `$PRE.<key>` slot at the mirrored offset. Reads/writes of
    // `$PRE.x` then resolve like any other variable (see `compile_sim_cref_*`).
    let pre_entries: Vec<(String, SimSlot)> = map
        .vars
        .iter()
        .filter_map(|(key, slot)| {
            layout.pre_slot_off(slot.off).map(|off| {
                (format!("$PRE.{key}"), SimSlot { off, ..*slot })
            })
        })
        .collect();
    for (key, slot) in pre_entries {
        Arc::make_mut(&mut map.vars).insert(key, slot);
    }
    // Same for the array accumulator, so `pre(x[i])` with a non-constant subscript
    // resolves through a `$PRE.<base>` group.
    let pre_groups: Vec<(String, Vec<AccElem>)> = map
        .array_acc
        .iter()
        .filter_map(|(base, elems)| {
            let pre: Option<Vec<_>> = elems
                .iter()
                .map(|e| {
                    let mut pieces = e.pieces.clone();
                    pieces[0].insert_str(0, "$PRE.");
                    Some(AccElem {
                        subs: e.subs.clone(),
                        pieces,
                        off: layout.pre_slot_off(e.off)?,
                        wty: e.wty,
                        neg: e.neg,
                        heap: e.heap,
                    })
                })
                .collect();
            Some((format!("$PRE.{base}"), pre?))
        })
        .collect();
    map.array_acc.extend(pre_groups);

    finalize_array_groups(&mut map)?;
    editable.extend(start_editable);
    editable.extend(string_editable);
    Ok((map, result_vars, editable))
}

/// Register one variable's slot (by canonical cref key) and its start value. If
/// the variable is a scalarized array element (`base[c1,…,cn]`), also record it
/// under its array base name so a whole-array reference can later be marshalled.
fn insert_var(map: &mut SimVarMap, sv: &SimCodeVar::SimVar, off: u32, wty: WTy, heap: bool) -> Result<()> {
    let key = sim_cref_key(&sv.name)?;
    Arc::make_mut(&mut map.vars).insert(key.clone(), SimSlot { off, wty, negate: Neg::None, heap });
    Arc::make_mut(&mut map.starts).insert(key, sv.initialValue.clone());
    for g in array_element_keys(&sv.name)? {
        map.array_acc.entry(g.base).or_default().push(AccElem {
            subs: g.subs,
            pieces: g.pieces,
            off,
            wty,
            neg: Neg::None,
            heap,
        });
    }
    Ok(())
}

/// If `cr` is a scalarized array element `base[c1,…,cn]` — the subscripts on the
/// deepest component all constant — its base name and those subscripts.
fn array_element_of(cr: &Arc<DAE::ComponentRef>) -> Result<Option<(String, Vec<i32>)>> {
    use DAE::ComponentRef as C;
    let mut base = String::new();
    let mut node: &Arc<DAE::ComponentRef> = cr;
    loop {
        match &**node {
            C::CREF_IDENT { ident, subscriptLst, .. } => {
                base.push_str(ident);
                if subscriptLst.is_empty() {
                    return Ok(None);
                }
                return Ok(const_int_subscripts(subscriptLst)?.map(|subs| (base, subs)));
            }
            C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
                base.push_str(ident);
                if !crate::CodegenWasmJitFunctions::push_qual_subs(subscriptLst, &mut base) {
                    return Ok(None);
                }
                base.push('.');
                node = componentRef;
            }
            _ => return Ok(None),
        }
    }
}

/// The array groups a scalarized element joins. `b[1].a[2].y` joins `b[1].a`,
/// keyed as `sim_cref_key` spells it, and the flattened `b.a.y`, which is what
/// `b[$i].a[$j].y` resolves through.
fn array_element_keys(cr: &Arc<DAE::ComponentRef>) -> Result<Vec<GroupEntry>> {
    let mut out = Vec::new();
    if let Some((base, subs)) = array_element_of(cr)? {
        let mut pieces = vec![base.clone()];
        pieces.resize(subs.len() + 1, String::new());
        out.push(GroupEntry { base, subs, pieces });
    }
    if let Some(e) = flat_array_element_of(cr)? {
        if !out.iter().any(|g| g.base == e.base) {
            out.push(e);
        }
    }
    Ok(out)
}

/// A group membership: its key, the element's index in it, and how the group
/// spells an element key (`ArrayGroup::key_pieces`).
struct GroupEntry {
    base: String,
    subs: Vec<i32>,
    pieces: Vec<String>,
}

/// One scalarized element accumulated for an array base: where it sits in the
/// array, how the group spells its key, and where its value lives.
#[derive(Clone)]
struct AccElem {
    subs: Vec<i32>,
    pieces: Vec<String>,
    off: u32,
    wty: WTy,
    neg: Neg,
    heap: bool,
}

/// The name with every subscript stripped, the subscripts outermost-first, and
/// the pieces they sit between. `None` unless an outer component is subscripted.
fn flat_array_element_of(cr: &Arc<DAE::ComponentRef>) -> Result<Option<GroupEntry>> {
    use DAE::ComponentRef as C;
    let mut base = String::new();
    let mut subs = Vec::new();
    let mut pieces = Vec::new();
    let mut piece = String::new();
    let mut qualified_subs = false;
    let mut node: &Arc<DAE::ComponentRef> = cr;
    loop {
        let (ident, subscriptLst, next) = match &**node {
            C::CREF_IDENT { ident, subscriptLst, .. } => (ident, subscriptLst, None),
            C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
                qualified_subs |= !subscriptLst.is_empty();
                (ident, subscriptLst, Some(componentRef))
            }
            _ => return Ok(None),
        };
        base.push_str(ident);
        piece.push_str(ident);
        match const_int_subscripts(subscriptLst)? {
            Some(s) => {
                for ix in s {
                    subs.push(ix);
                    pieces.push(core::mem::take(&mut piece));
                }
            }
            None => return Ok(None),
        }
        match next {
            Some(n) => {
                base.push('.');
                piece.push('.');
                node = n;
            }
            None => {
                pieces.push(piece);
                return Ok((qualified_subs && !subs.is_empty())
                    .then_some(GroupEntry { base, subs, pieces }));
            }
        }
    }
}

/// Parse a subscript list to constant 1-based integer indices, or `None` if any
/// subscript is not a constant integer / enum literal (a slice, `:`, expression).
fn const_int_subscripts(subs: &Arc<List<Arc<DAE::Subscript>>>) -> Result<Option<Vec<i32>>> {
    let mut out = Vec::new();
    for sub in &**subs {
        match &**sub {
            DAE::Subscript::INDEX { exp } => match &**exp {
                DAE::Exp::ICONST { integer } => out.push(*integer),
                DAE::Exp::ENUM_LITERAL { index, .. } => out.push(*index),
                _ => return Ok(None),
            },
            _ => return Ok(None),
        }
    }
    Ok(Some(out))
}

/// Finalize the accumulated array elements into [`ArrayGroup`]s. For each base:
/// derive the shape from the maximum index per axis, then *verify* that the
/// scalarized elements occupy a contiguous, row-major slot range (offset of
/// element `[i1,…,in]` equals `base_off + rowmajor_index * stride`). If the
/// backend ever lays them out differently, fail loudly rather than silently
/// build a wrong array — there is no heuristic fallback.
///
/// A well-shaped group that is not contiguous becomes a [`ScatterGroup`] instead,
/// which is enough to select one element by a run-time subscript.
fn finalize_array_groups(map: &mut SimVarMap) -> Result<()> {
    let acc = std::mem::take(&mut map.array_acc);
    for (base, elems) in acc {
        let Some(first) = elems.first() else { continue };
        let rank = first.subs.len();
        // A group that cannot be treated as one whole-array is skipped, not fatal:
        // individual element references still resolve through their own slots, and
        // a genuine whole-array reference fails later as "unknown variable". Only
        // truly malformed shapes (non-positive index) are errors.
        if elems.iter().any(|e| e.subs.len() != rank) {
            continue; // ragged rank (element and its own sub-slice both present)
        }
        // Shape: 1-based max index per axis.
        let mut dims = vec![0u32; rank];
        for e in &elems {
            for (axis, &ix) in e.subs.iter().enumerate() {
                if ix < 1 {
                    record_error(format!(
                        "CodegenWasmJit: non-positive subscript {ix} for array variable `{base}`"));
                    return Err("CodegenWasmJit: non-positive array subscript");
                }
                dims[axis] = dims[axis].max(ix as u32);
            }
        }
        let total: u32 = dims.iter().product();
        if total as usize != elems.len() {
            continue; // not all elements present (e.g. a sub-slice is its own variable)
        }
        let wty = first.wty;
        let heap = first.heap;
        if elems.iter().any(|e| e.wty != wty || e.heap != heap) {
            continue; // mixed element storage types: not a uniform array
        }
        // Row-major element table. `total == elems.len()` only rules out a hole if
        // no two elements share an index, so an unfilled entry skips the group.
        let mut table = vec![None; total as usize];
        for e in &elems {
            let lin = e.subs.iter().enumerate().fold(0u32, |lin, (axis, &ix)| lin * dims[axis] + (ix as u32 - 1));
            table[lin as usize] = Some((e.off, e.neg));
        }
        let Some(table) = table.into_iter().collect::<Option<Vec<_>>>() else { continue };
        // Contiguous row-major and unnegated? If not (aliased elsewhere, or the
        // elements straddle SimData regions) the array cannot be gathered or
        // assigned as a whole; only a single element resolves.
        let stride = match wty { WTy::F64 => 8, WTy::I32 => 4 };
        let base_off = table[0].0;
        let contiguous = table.iter().enumerate().all(|(lin, &(off, neg))| {
            neg == Neg::None && off == base_off + lin as u32 * stride
        });
        if !contiguous {
            Arc::make_mut(&mut map.scatter_groups)
                .insert(base, ScatterGroup { wty, heap, dims, elems: table });
            continue;
        }
        let key_pieces = first.pieces.clone();
        Arc::make_mut(&mut map.array_groups)
            .insert(base, ArrayGroup { base_off, wty, heap, dims, total, key_pieces });
    }
    finalize_const_groups(map)
}

/// [`finalize_array_groups`] for constants, which own no slots: the group is the
/// row-major list of its elements' literals.
fn finalize_const_groups(map: &mut SimVarMap) -> Result<()> {
    let acc = std::mem::take(&mut map.const_acc);
    for (base, mut elems) in acc {
        let Some(rank) = elems.first().map(|(s, _, _)| s.len()) else { continue };
        if elems.iter().any(|(s, _, _)| s.len() != rank) {
            continue; // ragged rank
        }
        if elems.iter().any(|(subs, _, _)| subs.iter().any(|&ix| ix < 1)) {
            continue;
        }
        let mut dims = vec![0u32; rank];
        for (subs, _, _) in &elems {
            for (axis, &ix) in subs.iter().enumerate() {
                dims[axis] = dims[axis].max(ix as u32);
            }
        }
        let total: u32 = dims.iter().product();
        if total as usize != elems.len() {
            continue; // not every element is its own constant
        }
        let wty = elems[0].2;
        if elems.iter().any(|(_, _, w)| *w != wty) {
            continue;
        }
        elems.sort_by_key(|(subs, _, _)| {
            subs.iter().enumerate().fold(0u32, |lin, (axis, &ix)| lin * dims[axis] + (ix as u32 - 1))
        });
        let values = elems.into_iter().map(|(_, e, _)| e).collect();
        Arc::make_mut(&mut map.const_groups).insert(base, ConstGroup { wty, dims, values });
    }
    Ok(())
}

// ===========================================================================
// Module assembly
// ===========================================================================

/// Wasm function indices of the generated equation functions (after the
/// imports and the model's Modelica functions).
struct EqFnIdx {
    parameters: u32,
    initial: u32,
    ode: u32,
    algebraics: u32,
    init_start_values: u32,
}

/// One `sample(index, start, interval)` time event, from `SimCode.timeEvents`.
/// `start`/`interval` are the (parameter-dependent) expressions the emitted
/// `initSample` evaluates into the sample region; `index` is the sample's unique
/// index as it appears in the `sample(index,…)` calls in equations.
struct SampleInfo {
    index: i32,
    start: Arc<DAE::Exp>,
    interval: Arc<DAE::Exp>,
}

/// One state-event zero-crossing. The driver's DASKR root callback watches `g`
/// and locates the sign change. `SimCode.zeroCrossings` maps 1:1 onto these (as
/// in the C target's `function_ZeroCrossings`), one `g` per entry.
pub(crate) enum ZcInfo {
    /// A relation or boolean condition: `g = expr ? 1 : -1`. DASKR brackets the ±1
    /// step. A Real inequality is lowered with a hysteresis band and held-relation
    /// direction (see `compile_relation`), consistent with how the same relation
    /// reads in the equations, so an event fires exactly when the relation flips.
    Bool { expr: Arc<DAE::Exp> },
    /// A math-event builtin (`integer`/`floor`/`ceil`/`div`/`mod`): `g =
    /// (test(fresh arg) != test(pre[idx])) ? 1 : -1`, C's `zeroCrossingTpl`. `ops`
    /// are the operands (1 for integer/floor/ceil, 2 for div/mod).
    /// `expr` is the original call, only for the `LOG_EVENTS` description.
    Math { kind: MathEventKind, ops: Vec<Arc<DAE::Exp>>, idx: u32, expr: Arc<DAE::Exp> },
}

/// A math-event builtin's discretizing test (what `mathEventsValuePre` compares).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) enum MathEventKind {
    /// `integer`/`floor`: `floor`.
    Floor,
    /// `ceil`: `ceil`.
    Ceil,
    /// `div`: `trunc(a/b)`.
    Div,
    /// `mod`: `floor(a/b)`.
    Mod,
}

/// Classify a builtin call as a math event by name and arity. `FindZeroCrossings`
/// appends the `mathEventsValuePre` index to event-context calls
/// (`integer(x)`→`integer(x,idx)`), so the extra argument marks the held form.
pub(crate) fn math_event_kind(name: &str, nargs: usize) -> Option<MathEventKind> {
    match (name, nargs) {
        ("integer", 2) | ("floor", 2) => Some(MathEventKind::Floor),
        ("ceil", 2) => Some(MathEventKind::Ceil),
        ("div", 3) => Some(MathEventKind::Div),
        ("mod", 3) => Some(MathEventKind::Mod),
        _ => None,
    }
}

/// The `mathEventsValuePre` slot index (a math-event call's last argument).
pub(crate) fn math_event_index(last: &DAE::Exp) -> Result<u32> {
    match last {
        DAE::Exp::ICONST { integer } if *integer >= 0 => Ok(*integer as u32),
        other => return Err("CodegenWasmJit: math-event index is not a non-negative ICONST"),
    }
}

/// Whether `path` is the unqualified builtin call `name`.
fn path_ident_is(path: &openmodelica_ast::Absyn::Path, name: &str) -> bool {
    matches!(path, openmodelica_ast::Absyn::Path::IDENT { name: n } if &**n == name)
}

/// The unqualified identifier of a builtin call path, or `None` if qualified.
fn path_ident_name(path: &openmodelica_ast::Absyn::Path) -> Option<&str> {
    match path {
        openmodelica_ast::Absyn::Path::IDENT { name } => Some(name),
        _ => None,
    }
}

/// Collect the model's zero-crossings (`SimCode.zeroCrossings`), one `ZcInfo` per
/// entry (matching the C `zeroCrossingTpl` cases). A bare numeric inequality keeps
/// the exact continuous `lhs - rhs`; a boolean condition (`==`/`<>`, `LBINARY`
/// combinations, `LUNARY`) maps to ±1 like C's `gout[i] = (relation_) ? 1 : -1`.
/// A `sample(…)` crossing emits no root (time events are driven separately).
/// Math-event builtins (`integer`/`floor`/`ceil`/`div`/`mod`) map to a
/// `ZcInfo::Math` (held-value comparison, C's `mathEventsValuePre` hysteresis).
/// For-loop (`iter`) crossings still error — they need iterator expansion, not
/// yet ported.
fn collect_zero_crossings(
    zcs: &Arc<List<openmodelica_backend_types::BackendDAE::ZeroCrossing>>,
) -> Result<Vec<ZcInfo>> {
    let mut out = Vec::new();
    for zc in lst(zcs) {
        for relation in expand_iter_crossing(&zc.relation_, &zc.iter)? {
            match &*relation {
                DAE::Exp::RELATION { .. } | DAE::Exp::LBINARY { .. } | DAE::Exp::LUNARY { .. } => {
                    out.push(ZcInfo::Bool { expr: relation.clone() });
                }
                // `sample()` in the zero-crossing list is a time event (handled via
                // `collect_samples`); it contributes no DASKR root, like C's empty case.
                DAE::Exp::CALL { path, .. } if path_ident_is(path, "sample") => {}
                DAE::Exp::CALL { path, expLst, .. }
                    if path_ident_name(path)
                        .and_then(|n| math_event_kind(n, count(expLst) as usize))
                        .is_some() =>
                {
                    let kind = math_event_kind(path_ident_name(path).unwrap(), count(expLst) as usize).unwrap();
                    let argv: Vec<Arc<DAE::Exp>> = lst(expLst).cloned().collect();
                    let idx = math_event_index(argv.last().unwrap())?;
                    let ops = argv[..argv.len() - 1].to_vec();
                    out.push(ZcInfo::Math { kind, ops, idx, expr: relation.clone() });
                }
                other => return Err("CodegenWasmJit: unsupported zero-crossing form"),
            }
        }
    }
    Ok(out)
}

/// A for-loop crossing occupies one slot per iteration: C's `forIteratorBody`
/// offsets `gout` mixed-radix, first iterator least significant. The counts are
/// constant, so the same slots come from substituting each iterator value in.
fn expand_iter_crossing(
    relation: &Arc<DAE::Exp>,
    iters: &Option<Arc<List<openmodelica_backend_types::BackendDAE::SimIterator>>>,
) -> Result<Vec<Arc<DAE::Exp>>> {
    let Some(iters) = iters else { return Ok(vec![relation.clone()]) };
    let mut out = vec![relation.clone()];
    for iter in lst(iters) {
        let (name, values, sub_iters) = iterator_bindings(iter)?;
        let mut next = Vec::with_capacity(out.len() * values.len());
        for (pos, value) in values.iter().enumerate() {
            for e in &out {
                let mut e = subst_iterator(e, &name, value)?;
                for (sub_name, table) in &sub_iters {
                    let v = table
                        .get(pos)
                        .ok_or("CodegenWasmJit: dependent iterator range is too short")?;
                    e = subst_iterator(&e, sub_name, v)?;
                }
                next.push(e);
            }
        }
        out = next;
    }
    Ok(out)
}

/// An iterator's name and per-iteration value, and the same for its dependents.
type IteratorBindings = (String, Vec<Arc<DAE::Exp>>, Vec<(String, Vec<Arc<DAE::Exp>>)>);

fn iterator_bindings(
    iter: &openmodelica_backend_types::BackendDAE::SimIterator,
) -> Result<IteratorBindings> {
    use openmodelica_backend_types::BackendDAE::SimIterator as S;
    let iconst = |v: i32| Arc::new(DAE::Exp::ICONST { integer: v });
    let (name, sub_iter, values) = match iter {
        S::SIM_ITERATOR_RANGE { name, start, step, non_resizable_size, sub_iter, .. } => {
            let (Some(start), Some(step)) = (const_int_exp(start), const_int_exp(step)) else {
                return Err("CodegenWasmJit: for-loop crossing over a non-constant range");
            };
            let values = (0..*non_resizable_size).map(|k| iconst(start + k * step)).collect();
            (name, sub_iter, values)
        }
        S::SIM_ITERATOR_LIST { name, lst: values, sub_iter, .. } => {
            (name, sub_iter, (&**values).into_iter().map(|v| iconst(*v)).collect())
        }
    };
    let mut subs = Vec::new();
    for (sub_name, table) in &**sub_iter {
        subs.push((cref_display(sub_name)?, table.borrow().clone()));
    }
    Ok((cref_display(name)?, values, subs))
}

fn const_int_exp(e: &DAE::Exp) -> Option<i32> {
    match e {
        DAE::Exp::ICONST { integer } => Some(*integer),
        _ => None,
    }
}

/// Replace the bare iterator `name`, including inside cref subscripts.
fn subst_iterator(exp: &Arc<DAE::Exp>, name: &str, value: &Arc<DAE::Exp>) -> Result<Arc<DAE::Exp>> {
    let name = name.to_string();
    let value = value.clone();
    let replace = move |e: Arc<DAE::Exp>, acc: i32| -> Result<(Arc<DAE::Exp>, i32)> {
        if let DAE::Exp::CREF { componentRef, .. } = &*e {
            if let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = &**componentRef {
                if subscriptLst.is_empty() && ident.as_str() == name {
                    return Ok((value.clone(), acc));
                }
            }
        }
        Ok((e, acc))
    };
    openmodelica_frontend_base::Expression::traverseExpBottomUp(exp.clone(), Arc::new(replace), 0)
        .map(|(e, _)| e)
}

/// Collect `SimCode.relations`, one slot per entry as in C's `functionRelations`:
/// `Some` for a bare relation, `None` for a form C's `relationTpl` also leaves
/// untouched while still consuming its index.
fn collect_relations(
    rels: &Arc<List<openmodelica_backend_types::BackendDAE::ZeroCrossing>>,
) -> Result<Vec<Option<Arc<DAE::Exp>>>> {
    let mut out = Vec::new();
    for zc in lst(rels) {
        for relation in expand_iter_crossing(&zc.relation_, &zc.iter)? {
            out.push(match &*relation {
                DAE::Exp::RELATION { .. } => Some(relation.clone()),
                _ => None,
            });
        }
    }
    Ok(out)
}

/// Collect the model's `SAMPLE_TIME_EVENT`s in order. For-loop samples (with an
/// `iter`) expand to multiple runtime samples and are not handled yet, so bail
/// loudly rather than mis-simulate.
fn collect_samples(
    time_events: &Arc<List<openmodelica_backend_types::BackendDAE::TimeEvent>>,
) -> Result<Vec<SampleInfo>> {
    use openmodelica_backend_types::BackendDAE::TimeEvent as TE;
    let mut out = Vec::new();
    for te in lst(time_events) {
        if let TE::SAMPLE_TIME_EVENT { index, startExp, intervalExp, iter } = te {
            if iter.is_some() {
                return Err("CodegenWasmJit: for-loop `sample` (iterator) not yet supported");
            }
            out.push(SampleInfo { index: *index, start: startExp.clone(), interval: intervalExp.clone() });
        }
    }
    Ok(out)
}

/// One synchronous base clock: the [`BaseClockMeta`] the driver needs, plus the
/// `ClockKind` expressions and sub-partition equations the three emitted
/// functions are built from (C's `baseClockInit`/`updatePartition`/
/// `functionEquationsSynchronous`).
struct ClockInfo {
    meta: BaseClockMeta,
    kind: Arc<DAE::ClockKind>,
    /// Equations of each sub-partition (`equations ++ removedEquations`).
    sub_eqs: Vec<Vec<Arc<SimCode::SimEqSystem>>>,
}

/// Split a `ClockedPartition` list into per-base-clock info, assigning the flat
/// sub-clock indices the `SimData` sub-clock region is addressed by.
fn collect_clocks(partitions: &Arc<List<SimCode::ClockedPartition>>) -> Result<Vec<ClockInfo>> {
    let mut out = Vec::new();
    let mut sub_base = 0u32;
    for part in lst(partitions) {
        let mut sub = Vec::new();
        let mut sub_eqs = Vec::new();
        for sp in lst(&part.subPartitions) {
            let BackendDAE::SubClock::SUBCLOCK { factor, shift, solver } = &sp.subClock else {
                return Err("CodegenWasmJit: sub-partition still has an inferred sub-clock");
            };
            sub.push(SubClockMeta {
                shift_num: shift.nom as i64,
                shift_den: shift.denom as i64,
                factor_num: factor.nom as i64,
                factor_den: factor.denom as i64,
                hold_events: sp.holdEvents,
                external_solver: solver.is_some(),
            });
            sub_eqs.push(lst(&sp.equations).chain(lst(&sp.removedEquations)).cloned().collect());
        }
        // C's "fake" sub-partition 0 for an empty clocked partition, which its
        // base-clock handling then activates like any other.
        if sub.is_empty() {
            sub.push(SubClockMeta { shift_den: 1, factor_num: 1, factor_den: 1, ..SubClockMeta::default() });
            sub_eqs.push(Vec::new());
        }
        let n_sub = sub.len() as u32;
        out.push(ClockInfo {
            meta: BaseClockMeta {
                is_event_clock: matches!(&*part.baseClock, DAE::ClockKind::EVENT_CLOCK { .. }),
                inferred: matches!(&*part.baseClock, DAE::ClockKind::INFERRED_CLOCK),
                sub_base,
                sub,
            },
            kind: part.baseClock.clone(),
            sub_eqs,
        });
        sub_base += n_sub;
    }
    Ok(out)
}

/// Where the model will run, which decides how an `Include` C source is built: for
/// the host, or for an artifact that is itself wasm (an FMU, the standalone module).
#[derive(Clone, Copy, PartialEq)]
enum ExtHost {
    Native,
    Wasm,
}

impl ExtHost {
    /// A simulation run. The browser omc has neither a host compiler nor a dynamic
    /// loader, so there a run is as wasm as an exported FMU.
    const SIM: ExtHost = if cfg!(target_arch = "wasm32") { ExtHost::Wasm } else { ExtHost::Native };
}

/// The wasm signature an `ext.*` import is declared with. In a shared-memory module
/// the import binds directly to the real symbol, so it takes the C or Fortran
/// argument list rather than the host-trampoline shape.
fn ext_import_sig(sig: &ExtCallSig) -> openmodelica_wasm_jit::sig::FnSig {
    use openmodelica_wasm_jit::sig::ExtLang;
    if !crate::CodegenWasmJitFunctions::externals_shared() {
        return sig.wasm_sig();
    }
    match sig.lang {
        ExtLang::Fortran77 => sig.wasm_sig_f77_shared(),
        ExtLang::C => sig.wasm_sig_c_shared(),
    }
}

/// `fmi_vrs`: also record the FMI value-reference table (FMU export only).
/// One `<entry>$guard`, per the wrappers `build_sim_model` emits.
fn build_guard_fn(target: u32) -> we::Function {
    use we::Instruction as I;
    let mut f = we::Function::new([(1, we::ValType::I32)]);
    let threw = 1; // param 0 is the SimData pointer
    f.instruction(&I::Block(we::BlockType::Empty)); // done
    f.instruction(&I::Block(we::BlockType::Result(we::ValType::EXNREF))); // handler
    f.instruction(&I::TryTable(we::BlockType::Empty, vec![we::Catch::OneRef { tag: 0, label: 0 }].into()));
    f.instruction(&I::LocalGet(0));
    f.instruction(&I::Call(target));
    f.instruction(&I::End); // try_table
    f.instruction(&I::I32Const(0));
    f.instruction(&I::LocalSet(threw));
    f.instruction(&I::Br(1)); // done
    f.instruction(&I::End); // handler: the exception is on the stack
    f.instruction(&I::Drop);
    f.instruction(&I::I32Const(1));
    f.instruction(&I::LocalSet(threw));
    f.instruction(&I::End); // done
    f.instruction(&I::LocalGet(threw));
    f.instruction(&I::End);
    f
}

fn build_sim_model(
    sim_code: &SimCode::SimCode,
    fmi_vrs: bool,
    ext_host: ExtHost,
    cs_method: &str,
    fmi_solver_flags: &str,
) -> Result<SimModel> {
    crate::CodegenWasmJitFunctions::set_record_decls(&sim_code.recordDecls)?;
    let mi = &sim_code.modelInfo;
    let vi = &mi.varInfo;
    let scalarized_vars = scalarize_sim_vars(&mi.vars)?;
    let vars = &scalarized_vars;
    let states: Vec<&SimCodeVar::SimVar> = lst(&vars.stateVars).collect();

    let n_states = count(&vars.stateVars) as u32;
    let n_real_alg = real_alg_vars(vars).len() as u32;
    let n_real_param = count(&vars.paramVars) as u32;
    let samples = collect_samples(&sim_code.timeEvents)?;
    let zero_crossings = collect_zero_crossings(&sim_code.zeroCrossings)?;
    let relations = collect_relations(&sim_code.relations)?;
    let stateset_scratch_f64 = stateset_scratch_f64(&sim_code.stateSets)?;
    // Jacobian scratch region: nonlinear-system slots + torn-linear slots (after).
    let nls_jac_scratch_f64 = nls_jac_scratch_f64(sim_code) + lin_jac_scratch_f64(sim_code);
    let all_eqs = flatten_eqs(&sim_code.allEquations);
    let local_known_eqs = flatten_eqs(&sim_code.localKnownVars);
    // `--daeMode`: `allEquations`/`odeEquations` are empty and the whole continuous
    // system is `daeModeData.daeEquations`, the residual `F(t, y, y') = 0`.
    let dae_mode = sim_code.daeModeData.as_ref();
    let dae_eqs: Vec<(Arc<SimCode::SimEqSystem>, u32)> =
        dae_mode.map(|d| dae_residual_equations(d)).unwrap_or_default();
    let dae_res_vars: Vec<&SimCodeVar::SimVar> =
        dae_mode.map(|d| lst(&d.residualVars).collect()).unwrap_or_default();
    let dae_aux_vars: Vec<&SimCodeVar::SimVar> =
        dae_mode.map(|d| lst(&d.auxiliaryVars).collect()).unwrap_or_default();
    let dae_alg_vars: Vec<&SimCodeVar::SimVar> =
        dae_mode.map(|d| lst(&d.algebraicVars).collect()).unwrap_or_default();
    if dae_mode.is_some() && dae_res_vars.len() != (n_states as usize + dae_alg_vars.len()) {
        return Err("CodegenWasmJit: DAE mode residual count does not match states + algebraic unknowns");
    }
    // A model has discrete `when` behaviour through when-equations (SES_WHEN) or
    // when-statements inside an algorithm — both need the per-step pre-value save
    // and the full `allEquations` list as the per-step function.
    let when_scan = eqs_with_nested(&all_eqs);
    let has_when = dae_eqs.iter().map(|(e, _)| e).chain(when_scan.iter()).any(|e| match &**e {
        SimCode::SimEqSystem::SES_WHEN { .. } => true,
        SimCode::SimEqSystem::SES_ALGORITHM { statements, .. }
        | SimCode::SimEqSystem::SES_INVERSE_ALGORITHM { statements, .. } => {
            (&**statements).into_iter().any(|s| matches!(&**s, DAE::Statement::STMT_WHEN { .. }))
        }
        _ => false,
    });
    let has_homotopy = nls_homotopy_support(sim_code);
    // `--calculateSensitivities`: `sensitivityVars` is the `Ns` differentiated
    // parameters followed by the `Ns * nStates` `$Sensitivities.<par>.<state>`
    // signals (C's `rSen` init-XML category, split by `numSensitivityParameters`).
    let n_sens_par = vi.numSensitivityParameters.max(0) as usize;
    let sens_vars: Vec<&SimCodeVar::SimVar> = lst(&mi.vars.sensitivityVars).collect();
    let n_sens = sens_vars.len().saturating_sub(n_sens_par) as u32;
    let clocks = collect_clocks(&sim_code.clockedPartitions)?;
    let n_sub_clocks: u32 = clocks.iter().map(|c| c.meta.sub.len() as u32).sum();
    // `-l`: the symbolic A/B/C/D and the scratch their column equations need.
    let mut linz = build_linz_plan(sim_code, vars, n_states)?;
    // `-reconcile`: F/H, laid out right behind them.
    let mut recon = datarecon::build_plan(sim_code, vars);
    let sym_solver = sym_solver_kind()?;
    let layout = SimLayout::new(
        n_states,
        n_real_alg,
        n_real_param,
        count(&vars.intAlgVars) as u32,
        count(&vars.intParamVars) as u32,
        count(&vars.boolAlgVars) as u32,
        count(&vars.boolParamVars) as u32,
        count(&vars.stringAlgVars) as u32,
        count(&vars.stringParamVars) as u32,
        count(&vars.extObjVars) as u32,
        samples.len() as u32,
        zero_crossings.len() as u32,
        vi.numRelations.max(0) as u32,
        stateset_scratch_f64,
        nls_jac_scratch_f64,
        vi.numMathEventFunctions.max(0) as u32,
        n_sens,
        dae_res_vars.len() as u32,
        dae_aux_vars.len() as u32,
        dae_alg_vars.len() as u32,
        clocks.len() as u32,
        n_sub_clocks,
        linz.n_scratch_f64() + recon.n_scratch_f64(),
        // The optimizer's attribute arrays: one entry per real variable, only for a
        // model that carries an optimization problem.
        if optimization::is_optimization(sim_code) { 2 * n_states + n_real_alg } else { 0 },
        bound_attr_equations(sim_code).len() as u32,
        removed_init_residuals(sim_code).len() as u32,
        sym_solver,
        has_when,
        has_homotopy,
        homotopy_method()?,
        lst(&sim_code.initialEquations_lambda0).next().is_some(),
        // `delay(...)` / `spatialDistribution(...)`: the driver has to store their
        // accepted points, which costs an extra evaluation, so it asks first.
        sim_code.delayedExps.maxDelayedIndex >= 0 || sim_code.spatialInfo.maxIndex >= 0,
        // Mirroring the last accepted step's reals costs a copy per step, so only
        // a model with a method-1 linear system to read them asks for it.
        has_method1_linear(sim_code),
    );

    let (mut var_map, mut result_vars, editable_params) = build_var_map(vars, &layout)?;
    let (prof_plan, prof_info) = prof_plan(sim_code, mi)?;
    var_map.prof = prof_plan;
    // DAE-mode residual/auxiliary variables: their own `SimData` regions, indexed by
    // the SimVar's `index` as C's `crefToCStr` does. Solver workspace, not results.
    for (svs, base) in [(&dae_res_vars, layout.dae_res_off), (&dae_aux_vars, layout.dae_aux_off)] {
        for sv in svs.iter() {
            let i = u32::try_from(sv.index).map_err(|_| "CodegenWasmJit: DAE mode variable has no index")?;
            insert_var(&mut var_map, sv, base + i * 8, WTy::F64, false)?;
        }
    }
    // An auxiliary variable can be a whole array (`$AUX.w = f(…)`), so its element
    // group needs finalizing too.
    if dae_mode.is_some() {
        finalize_array_groups(&mut var_map)?;
    }
    // The inline equations' `__OMC_DT` and `<state>$Old` operands: `SimCodeUtil`
    // only ever put them in the cref->SimVar table, so no `modelInfo.vars` walk
    // reaches them.
    if sym_solver > 0 {
        Arc::make_mut(&mut var_map.vars).insert(
            "__OMC_DT".to_string(),
            SimSlot { off: layout.inline_dt_off, wty: WTy::F64, negate: Neg::None, heap: false },
        );
        for (i, sv) in states.iter().enumerate() {
            let old = openmodelica_frontend_base::ComponentReference::appendStringLastIdent(
                arcstr::literal!("$Old"),
                sv.name.clone(),
            )?;
            Arc::make_mut(&mut var_map.vars).insert(
                sim_cref_key(&old)?,
                SimSlot {
                    off: layout.alg_old_off + (i as u32) * 8,
                    wty: WTy::F64,
                    negate: Neg::None,
                    heap: false,
                },
            );
        }
    }
    let sens_params = push_sensitivity_vars(&sens_vars, n_sens_par, vars, &layout, &mut result_vars)?;
    let var_units = collect_var_units(vars)?;
    var_map.n_samples = samples.len() as u32;
    var_map.sample_active_off = layout.sample_active_off;
    // Delay-buffer count (0 when the model has no `delay(...)`).
    var_map.n_delays = (sim_code.delayedExps.maxDelayedIndex + 1).max(0) as u32;
    // Transported-profile count (`maxIndex` is -1 when the model has none).
    var_map.n_spatial = (sim_code.spatialInfo.maxIndex + 1).max(0) as u32;

    // State sets: register the Jacobian seed/result crefs at the scratch region
    // and collect the driver-side selection metadata (candidate/state/A offsets).
    let state_sets = build_state_set_infos(&sim_code.stateSets, &layout, &mut var_map)?;

    // Index -> equation map (for SES_ALIAS, which re-runs another equation by
    // index). An alias may point at an equation defined in a different system
    // list than the one being lowered (e.g. a parameter-equation alias to an
    // initial equation), or at an equation nested inside a torn linear/nonlinear
    // (or mixed / if-) system, so index every list recursively. `eqFunction_<n>`
    // is emitted once in the C target and shared; here the target is inlined.
    let mut eq_index: HashMap<i32, Arc<SimCode::SimEqSystem>> = HashMap::new();
    let index_list = |eqs: &Arc<List<Arc<SimCode::SimEqSystem>>>, idx: &mut HashMap<i32, Arc<SimCode::SimEqSystem>>| {
        for e in lst(eqs) {
            index_eq_recursive(e, idx);
        }
    };
    index_list(&sim_code.allEquations, &mut eq_index);
    index_list(&sim_code.initialEquations, &mut eq_index);
    index_list(&sim_code.removedInitialEquations, &mut eq_index);
    index_list(&sim_code.parameterEquations, &mut eq_index);
    index_list(&sim_code.removedEquations, &mut eq_index);
    index_list(&sim_code.startValueEquations, &mut eq_index);
    index_list(&sim_code.algorithmAndEquationAsserts, &mut eq_index);
    index_list(&sim_code.equationsForZeroCrossings, &mut eq_index);
    index_list(&sim_code.inlineEquations, &mut eq_index);
    for e in dae_eqs.iter() {
        index_eq_recursive(&e.0, &mut eq_index);
    }
    for part in lst(&sim_code.odeEquations).chain(lst(&sim_code.algebraicEquations)) {
        index_list(part, &mut eq_index);
    }
    // Last: an index these lists share with one above keeps the earlier entry.
    index_list(&sim_code.initialEquations_lambda0, &mut eq_index);
    for e in clocked_eqs(sim_code).iter() {
        index_eq_recursive(e, &mut eq_index);
    }

    // --- Collect the model's Modelica functions (callable from equations). ---
    reset_declined_externals();
    let model_fns: Vec<&SimCodeFunction::Function::Function> = lst(&mi.functions)
        .map(|f| &**f)
        .filter(|f| {
            if matches!(f, SimCodeFunction::Function::Function::FUNCTION { .. }) || external_known(f) {
                return true;
            }
            match external_general_why(f) {
                Ok(()) => true,
                Err(why) => {
                    note_declined_external(f, why);
                    false
                }
            }
        })
        .collect();

    // Distinct `ext.<extName>` host imports for the general external scalar
    // functions, resolved by the host at instantiation (dlopen-self native; a
    // side module on wasm). Models without such externals emit none.
    let mut ext_imports: Vec<ExtCallSig> = Vec::new();
    let mut ext_seen: HashSet<String> = HashSet::new();
    for f in &model_fns {
        if external_general_why(f).is_ok() {
            let sig = external_import_sig(f)?;
            if ext_seen.insert(sig.name.clone()) {
                ext_imports.push(sig);
            }
        }
    }
    // A `Library` on a function the model never reaches must not fail the build.
    let mut ext_lib_notes: Vec<String> = Vec::new();
    let mut ext_libs = ExtLibraries::default();
    let mut ext_includes = None;
    let mut ext_archives = None;
    let mut ext_builtin = false;
    let mut ext_native: Vec<ExtCallSig> = Vec::new();
    if !ext_imports.is_empty() {
        ext_libs = resolve_ext_libraries(&sim_code.makefileParams, &mut ext_lib_notes)?;
        ext_builtin = builtin_wasm_needed(&ext_imports, &ext_libs.wasm);
        // What the `Library` annotations did not provide may come from an `Include`
        // carrying the C source, though most carry only the declarations.
        let mp = &sim_code.makefileParams;
        let sources: Vec<String> = lst(&sim_code.externalFunctionIncludes)
            .map(|s| s.to_string())
            .chain(std::mem::take(&mut ext_libs.sources))
            .collect();
        let dirs: Vec<String> = lst(&mp.includes).map(|s| s.to_string()).collect();
        let prefix = sim_code.fileNamePrefix.to_string();
        if !sources.is_empty() {
            // A hook ModelicaExternalC calls from inside the wasm is named by no
            // `ext` import and the native fallback cannot reach it, so it takes a
            // wasm library on either host. A wasm artifact carries every
            // implementation, so there the same decision is made off the exports.
            let hook = ext_builtin && include_overrides_builtin(&sources);
            if hook || ext_host == ExtHost::Wasm {
                let missing = missing_ext_symbols(&ext_imports, &ext_libs.wasm);
                if hook || !missing.is_empty() {
                    if let Some(l) = compile_include_library(&prefix, &sources, &dirs, &mp.cflags, &missing, &mut ext_lib_notes)? {
                        // Sources that only wrap a platform library still compile,
                        // and keeping the result would hide the functions from the
                        // host fallback that can serve them.
                        let unresolved = unresolved_dylink_needs(&dylink_needs(&l.bytes), &l, &ext_libs.wasm);
                        if unresolved.is_empty() {
                            ext_libs.wasm.push(l);
                        } else {
                            ext_lib_notes.push(format!(
                                "the `Include` C sources compiled for wasm but need `{}`, which no \
                                 wasm library defines; serving them from the host instead",
                                unresolved.join("`, `")
                            ));
                        }
                    }
                }
            }
        }
        // What no wasm library defines, a shared-memory kernel hands to the host.
        if ext_host == ExtHost::Wasm && crate::CodegenWasmJitFunctions::externals_shared() {
            ext_native = missing_ext_symbols(&ext_imports, &ext_libs.wasm);
        }
        crate::CodegenWasmJitFunctions::set_native_externals(ext_native.iter().map(|s| s.name.clone()));
        let want_native = ext_host == ExtHost::Native || !ext_native.is_empty();
        let symbols: Vec<String> = ext_imports.iter().map(|s| s.name.clone()).collect();
        // Built on demand, for a symbol the loaded libraries turn out not to define.
        // The archives are on this link too, not only on their own: a member only
        // these sources reference is pulled in by nothing else.
        if !sources.is_empty() && want_native {
            ext_includes = Some(ExtIncludes {
                sources,
                include_dirs: dirs,
                archives: ext_libs.archives.clone(),
                symbols: symbols.clone(),
                ccompiler: mp.ccompiler.to_string(),
                cflags: mp.cflags.to_string(),
                dllext: mp.dllext.to_string(),
                prefix: prefix.clone(),
            });
        }
        if !ext_libs.archives.is_empty() && want_native {
            ext_archives = Some(ExtArchives {
                archives: std::mem::take(&mut ext_libs.archives),
                symbols,
                ccompiler: mp.ccompiler.to_string(),
                dllext: mp.dllext.to_string(),
                prefix,
            });
        }
    }

    // Function index space: imports (env builtins, rt runtime, env-extra, then
    // the `ext.*` externals), then the model's Modelica functions, then the
    // generated equation functions.
    let ext_base = (BUILTINS.len() + RT_BUILTINS.len() + ENV_EXTRA.len()) as u32;
    let import_base = ext_base + ext_imports.len() as u32;
    let mut by_name: HashMap<String, FnInfo> = HashMap::new();
    for (i, sig) in ext_imports.iter().enumerate() {
        by_name.insert(format!("ext.{}", sig.name), FnInfo { index: ext_base + i as u32, sig: ext_import_sig(sig) });
    }
    for (id, f) in model_fns.iter().enumerate() {
        let (name, sig) = function_signature(f)?;
        by_name.insert(name, FnInfo { index: import_base + id as u32, sig });
    }
    let eq_base = import_base + model_fns.len() as u32;
    let eqfn = EqFnIdx {
        parameters: eq_base,
        initial: eq_base + 1,
        ode: eq_base + 2,
        algebraics: eq_base + 3,
        // Always emitted (no-op with no states) so the fixed indices below hold.
        init_start_values: eq_base + 4,
    };
    let simulate_idx = eq_base + 5;
    // The two metadata accessors the standalone wasip1 runtime imports
    // (`om_meta_ptr`/`om_meta_len`), appended after `simulate`.
    let om_meta_ptr_idx = eq_base + 6;
    let om_meta_len_idx = eq_base + 7;

    // --- Equation lists + nonlinear-system registration. Flattened here (before
    // the type/import sections, which need to know whether the model has any
    // nonlinear systems) and consumed by the equation-function builders below. ---
    let param_eqs = flatten_eqs(&sim_code.parameterEquations);
    mark_unvarying(&mut result_vars, &param_eqs)?;
    let initial_eqs = flatten_eqs(&sim_code.initialEquations);
    let mut computed_params = assigned_cref_keys(&eqs_with_nested(&param_eqs));
    computed_params.extend(assigned_cref_keys(&eqs_with_nested(&initial_eqs)));
    let param_bindings = collect_param_bindings(vars, &computed_params);
    // C's `functionODE` and `functionDAE` both open with `functionLocalKnownVars`
    // (`--preOptModules+=removeLocalKnownVars` moves the equations that depend only
    // on states and inputs there); empty unless that module ran.
    let with_local_known = |eqs: Vec<Arc<SimCode::SimEqSystem>>| -> Vec<Arc<SimCode::SimEqSystem>> {
        if local_known_eqs.is_empty() {
            return eqs;
        }
        let mut out = local_known_eqs.clone();
        out.extend(eqs);
        out
    };
    let alg_eqs_raw = flatten_eqs_ll(&sim_code.algebraicEquations);
    let algebraic_eqs = with_local_known(alg_eqs_raw.clone());
    // C's `storePreValues` at the end of `updateContinuousSystem`, which here tails
    // `functionAlgebraics` (see `sim_save_pre_values`).
    let save_pre: Vec<(u32, u32, u32)> = if has_when {
        vec![
            (layout.pre_real_off, REAL_OFF, (2 * layout.n_states + layout.n_real_alg) * 8),
            (layout.pre_int_off, layout.int_off, layout.n_int_alg() * 4),
            (layout.pre_bool_off, layout.bool_off, layout.n_bool_alg() * 4),
        ]
    } else {
        Vec::new()
    };
    let lambda0_eqs = flatten_eqs(&sim_code.initialEquations_lambda0);
    let assert_eqs = flatten_eqs(&sim_code.algorithmAndEquationAsserts);
    let ode_eqs = with_local_known(flatten_eqs_ll(&sim_code.odeEquations));
    let parmod = openmodelica_util::Flags::getConfigBool(openmodelica_util::Flags::PARMODAUTO.clone())?;
    let ode_task_eqs = flatten_eqs_ll(&sim_code.odeEquations);
    let parmod_info = match parmod && !ode_task_eqs.is_empty() {
        true => Some(parmod_info(&ode_task_eqs)?),
        false => None,
    };
    let zc_eqs = flatten_eqs(&sim_code.equationsForZeroCrossings);
    let inline_eqs = flatten_eqs(&sim_code.inlineEquations);
    // Register every nonlinear system with the runtime solver `rt_solve_nls`
    // *before* lowering the equation functions (which call it): assign each a
    // shared-table job and thread the map through `var_map`. The systems' own
    // `residual`/`load` callbacks are emitted after the equation functions.
    let nls_nominal_map = build_nls_nominal_map(vars);
    let mut attr_targets: HashMap<String, AttrTargets> = HashMap::new();
    let dae_only_eqs: Vec<Arc<SimCode::SimEqSystem>> = dae_eqs.iter().map(|(e, _)| e.clone()).collect();
    let removed_init_eqs = flatten_eqs(&sim_code.removedInitialEquations);
    let clocked = clocked_eqs(sim_code);
    let nls_scan: Vec<Vec<Arc<SimCode::SimEqSystem>>> = [
        &param_eqs, &initial_eqs, &lambda0_eqs, &ode_eqs, &algebraic_eqs, &dae_only_eqs, &zc_eqs,
        &assert_eqs, &removed_init_eqs, &clocked, &inline_eqs,
    ]
    .iter()
    .map(|l| eqs_with_nested(l.as_slice()))
    .collect();
    let (nls_systems, nls_jobs, nls_hist_bytes, nls_nominals, nls_bounds, nls_patterns, nls_warnings) = collect_nls_jobs(
        &nls_scan.iter().map(|l| l.as_slice()).collect::<Vec<_>>(),
        &nls_nominal_map,
        &mut attr_targets,
    );
    // Dynamic tearing: casual set index -> strict set index.
    let nls_strict_of = nls_strict_map(&nls_scan.iter().map(|l| l.as_slice()).collect::<Vec<_>>());
    // The integrator's per-unknown atol and the Jacobian's FD step floor: the states,
    // then in DAE mode the algebraic unknowns (C's `getAlgebraicDAEVarNominals`).
    let mut nominal_defaults: Vec<(u32, f64)> = Vec::new();
    for (svs, base) in [
        (lst(&vars.stateVars).take(n_states as usize).collect::<Vec<_>>(), layout.state_nom_off),
        (dae_alg_vars.clone(), layout.dae_alg_nom_off),
    ] {
        for (i, sv) in svs.iter().enumerate() {
            let off = base + (i as u32) * 8;
            nominal_defaults.push((off, const_value(&sv.nominalValue).unwrap_or(1.0).abs().max(1e-32)));
            if let Ok(k) = sim_cref_key(&sv.name) {
                attr_targets.entry(k).or_default().nom_offs.push(off);
            }
        }
    }
    // C's `functionJacAC_num` reads each state's `max` to sign its step.
    let mut max_defaults: Vec<(u32, f64)> = Vec::new();
    for (i, sv) in lst(&vars.stateVars).take(n_states as usize).enumerate() {
        let off = layout.state_max_off + (i as u32) * 8;
        max_defaults.push((off, const_value(&sv.maxValue).unwrap_or(f64::MAX)));
        if let Ok(k) = sim_cref_key(&sv.name) {
            attr_targets.entry(k).or_default().max_offs.push(off);
        }
    }
    // Register the analytic-Jacobian seed/result crefs before the equation
    // functions are lowered, so the column equations resolve their slots.
    let nls_jac_infos = build_nls_jac_infos(&nls_systems, &layout, &mut var_map)?;
    // Same, for torn linear systems that assemble A analytically.
    build_lin_jac_infos(sim_code, &layout, &mut var_map)?;
    // Same, for the `-l` matrices; "A" there is the ODE state Jacobian, so these
    // are also the slots the integrators seed and read.
    let (linz_jac_infos, adj_jac_info) = build_linz_jac_infos(&linz, &layout, &mut var_map)?;
    let recon_base = layout.linz_off + linz.n_scratch_f64() * 8;
    let mut recon_jac_infos = datarecon::build_jac_infos(&recon, recon_base, &mut var_map)?;
    var_map.nls_jobs = Arc::new(nls_jobs);
    var_map.generic_calls = Arc::new(
        lst(&sim_code.generic_loop_calls).map(|c| (generic_call_index(c), c.clone())).collect(),
    );

    // --- Type section: one type per import, per model function, per equation
    // function (all take one i32 `SimData` ptr, no result), then `simulate`
    // (f64,f64,f64,i32 -> i32). ---
    let mut types = we::TypeSection::new();
    for (_, params, result) in BUILTINS {
        types.ty().function(params.iter().map(|w| w.val()), [result.val()]);
    }
    for (_, params, results) in RT_BUILTINS {
        types.ty().function(params.iter().map(|w| w.val()), results.iter().map(|w| w.val()));
    }
    for (_, params, results) in ENV_EXTRA {
        types.ty().function(params.iter().map(|w| w.val()), results.iter().map(|w| w.val()));
    }
    // One type per `ext.*` external import: input args -> outputs (multi-value).
    let mut ext_type: Vec<u32> = Vec::with_capacity(ext_imports.len());
    for sig in &ext_imports {
        let ti = types.len();
        let s = ext_import_sig(sig);
        types.ty().function(
            s.params.iter().map(|s| s.wty().val()),
            s.results.iter().map(|s| s.wty().val()),
        );
        ext_type.push(ti);
    }
    // `om_throw_model_error`'s type, shared with the `model_error` tag: a
    // library's `ModelicaError` throws it and the `ext` call site catches it,
    // C's `longjmp` out of a residual. Only a model with external "C" carries a
    // tag — a module with one needs an engine that takes the exception-handling
    // proposal.
    let throw_fn_type = types.len();
    types.ty().function([], []);
    // A host-free module also carries one: nothing outside it catches a trap, so a
    // failed `assert()` unwinds to the entry point it fired under instead.
    let host_free = matches!(ext_host, ExtHost::Wasm);
    let error_tag_type = (!ext_imports.is_empty() || host_free).then_some(throw_fn_type);
    // `<entry>$guard`'s type: (i32 SimData) -> i32, nonzero if it threw.
    let guard_fn_type = types.len();
    types.ty().function([we::ValType::I32], [we::ValType::I32]);
    let mut model_fn_type: Vec<u32> = Vec::with_capacity(model_fns.len());
    for f in &model_fns {
        let (_, sig) = function_signature(f)?;
        let ti = types.len();
        types.ty().function(
            sig.params.iter().map(|s| s.wty().val()),
            sig.results.iter().map(|s| s.wty().val()),
        );
        model_fn_type.push(ti);
    }
    // Equation function type: (i32) -> ().
    let eqfn_type = types.len();
    types.ty().function([we::ValType::I32], []);
    // simulate type: (i32 simdata, f64 start, f64 stop, i32 nsteps) -> i32 buf.
    let simulate_type = types.len();
    types.ty().function(
        [we::ValType::I32, we::ValType::F64, we::ValType::F64, we::ValType::I32],
        [we::ValType::I32],
    );
    // `om_meta_ptr`/`om_meta_len` type: () -> i32.
    let meta_fn_type = types.len();
    types.ty().function([], [we::ValType::I32]);
    // Nonlinear-solver callback types (only when the model has nonlinear systems,
    // so output stays byte-identical otherwise): `residual` (i32,i32,i32)->(),
    // `load` (i32,i32)->(). The `start` type is allocated at the end, with the
    // closure thunks' types.
    let nls_types = if nls_systems.is_empty() {
        None
    } else {
        let residual_type = types.len();
        types.ty().function([we::ValType::I32, we::ValType::I32, we::ValType::I32], []);
        let load_type = types.len();
        types.ty().function([we::ValType::I32, we::ValType::I32], []);
        // Dynamic tearing's strict-set callback: (i32) -> i32.
        let strict_type = types.len();
        types.ty().function([we::ValType::I32], [we::ValType::I32]);
        Some((residual_type, load_type, strict_type))
    };
    // `evaluateDAEResiduals(SimData*, stage)`: (i32,i32) -> (). Emitted (empty for an
    // explicit-ODE model) either way, so the shared FMI adapter can import it.
    let dae_fn_type = {
        let ti = types.len();
        types.ty().function([we::ValType::I32, we::ValType::I32], []);
        ti
    };
    // `functionUpdateSynchronous`/`functionEquationsSynchronous`: (i32,i32) -> ().
    let sync_fn_type = {
        let ti = types.len();
        types.ty().function([we::ValType::I32, we::ValType::I32], []);
        ti
    };
    // Function references met while lowering the bodies add thunks to the closure
    // pool; this global holds their shared-table base.
    let closure_global = crate::CodegenWasmJitFunctions::closure_base_global(nls_types.is_some());
    crate::CodegenWasmJitFunctions::closures::begin(types.len(), closure_global);
    let lit_global = crate::CodegenWasmJitFunctions::lit_base_global(nls_types.is_some());
    crate::CodegenWasmJitFunctions::shared_lits::begin(lit_global);

    // --- Import section. ---
    let mut imports = we::ImportSection::new();
    imports.import(
        "rt",
        "memory",
        we::MemoryType { minimum: 0, maximum: None, memory64: false, shared: false, page_size_log2: None },
    );
    for (i, (name, _, _)) in BUILTINS.iter().enumerate() {
        // Math builtins are provided in-wasm by the runtime module (via libm),
        // not the host `env` namespace — see the runtime's rt_math exports.
        imports.import("rt", *name, we::EntityType::Function(i as u32));
    }
    for (j, (name, _, _)) in RT_BUILTINS.iter().enumerate() {
        imports.import("rt", *name, we::EntityType::Function((BUILTINS.len() + j) as u32));
    }
    for (k, (name, _, _)) in ENV_EXTRA.iter().enumerate() {
        // `rt_assert` is imported from `rt`, not the host `env`: for the JIT path
        // the host registers it under `rt` alongside the runtime instance, and for
        // the standalone wasip1 export the merged runtime provides it — so the
        // model module never imports anything from `env` (clean wasm-merge).
        imports.import("rt", *name, we::EntityType::Function((BUILTINS.len() + RT_BUILTINS.len() + k) as u32));
    }
    // General external "C" functions: imported from module `ext`, resolved by
    // the host (dlopen-self native; side module on wasm).
    for (i, sig) in ext_imports.iter().enumerate() {
        imports.import("ext", &sig.name, we::EntityType::Function(ext_type[i]));
    }

    // --- Compile bodies (collecting String literals into the module pool). ---
    let mut literals = Literals::default();
    let mut bodies: Vec<we::Function> = Vec::new();
    // With a tag in the module, every `ext` call is lowered under a `try_table`
    // (tag index 0: the module imports none).
    crate::CodegenWasmJitFunctions::set_ext_error_catch(error_tag_type.map(|_| 0));
    crate::CodegenWasmJitFunctions::set_assert_throw_tag(host_free.then_some(0));
    // Model functions first, in index order; poll for cancellation between them so
    // a long emit is interruptible like the frontend/backend upstream.
    for f in &model_fns {
        metamodelica::cancel::bail_if_cancelled()?;
        bodies.push(compile_function(f, &by_name, &mut literals)?);
    }
    // C's `setAllParamsToStart`: every parameter from its binding, in declaration
    // order (the backend sorts dependent parameters so a binding only references
    // earlier ones). `parameterEquations` belongs to `functionUpdateBoundParameters`
    // alone — evaluated in both, an external object's constructor runs twice.
    let stateset_diag = stateset_diag_offsets(&sim_code.stateSets, &var_map)?;
    let mut pool = ChunkPool::default();
    let mut splits: Vec<SplitFn> = Vec::new();
    let param_units: Vec<EqUnit> =
        param_bindings.iter().map(|(cref, exp)| EqUnit::Binding(cref, exp)).collect();
    splits.push(build_split_fn("functionParameters", &param_units, 1, eqfn_type, &stateset_diag, &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
    // Seed `relationsPre := relations` at the end of init (the in-wasm `simulate`
    // path skips the host `run_initialization`).
    let init_save: Vec<(u32, u32, u32)> = if layout.n_rel > 0 {
        vec![(layout.relations_pre_off, layout.relations_off, layout.n_rel * 4)]
    } else {
        Vec::new()
    };
    splits.push(build_split_fn("functionInitialEquations", &eq_units(&initial_eqs), 1, eqfn_type, &[], &init_save, &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
    // Three orders over one equation set, so where they agree on a run they call the
    // same chunk. Not under `--parmodauto`, whose tasks *are* the ODE chunks.
    let shared = match parmod_info.is_none() {
        true => eq_segments(&ode_task_eqs, &alg_eqs_raw, &all_eqs),
        false => None,
    };
    // A chunk of its own, so the equations before it stay shared.
    let pre_store = |pool: &mut ChunkPool, literals: &mut Literals| -> Result<Vec<usize>> {
        match save_pre.is_empty() {
            true => Ok(Vec::new()),
            false => build_chunks("storePreValues", &[], 1, eqfn_type, &[], &save_pre, &var_map, &eq_index, &by_name, literals, pool, false),
        }
    };
    let ode_split = splits.len();
    let dae_chunks = match shared {
        Some(segs) => {
            let (ode, mut alg, dae) = build_shared_eq_chunks(segs, &all_eqs, &local_known_eqs, eqfn_type, &var_map, &eq_index, &by_name, &mut literals, &mut pool)?;
            alg.extend(pre_store(&mut pool, &mut literals)?);
            for chunks in [ode, alg] {
                let slot = bodies.len();
                bodies.push(empty_eqfn());
                splits.push(SplitFn { slot, chunks, n_params: 1, pre_calls: Vec::new() });
            }
            Some(dae)
        }
        // `--parmodauto`: one chunk per ODE equation, each a schedulable task.
        None => {
            if parmod_info.is_some() {
                splits.push(build_split_fn("functionODE", &eq_units(&ode_task_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, true)?);
            } else {
                splits.push(build_split_fn("functionODE", &eq_units(&ode_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
            }
            let slot = bodies.len();
            bodies.push(empty_eqfn());
            let mut chunks = build_chunks("functionAlgebraics", &eq_units(&algebraic_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut pool, false)?;
            chunks.extend(pre_store(&mut pool, &mut literals)?);
            splits.push(SplitFn { slot, chunks, n_params: 1, pre_calls: Vec::new() });
            None
        }
    };
    // eq_base + 4, before `simulate` so the in-wasm integrator can call it.
    let all_reals: Vec<&SimCodeVar::SimVar> = states
        .iter()
        .copied()
        .chain(lst(&vars.derivativeVars))
        .chain(real_alg_vars(vars))
        .collect();
    bodies.push(build_init_start_values_fn(&all_reals, &layout, &var_map, &by_name, &mut literals)?);
    // A start or nominal bound to a parameter arrives as an attribute equation;
    // `functionUpdateBoundVariableAttributes` fills these slots from those.
    for (i, sv) in all_reals.iter().enumerate() {
        let nom_off = layout.real_nominal_off(i as u32);
        nominal_defaults.push((nom_off, literal_value(&sv.nominalValue).unwrap_or(1.0)));
        if let Ok(k) = sim_cref_key(&sv.name) {
            let t = attr_targets.entry(k).or_default();
            t.start_offs.push(layout.real_start_off(i as u32));
            t.raw_nom_offs.push(nom_off);
        }
    }
    // The integrator loop calls `functionCheckAsserts`, whose index is only known
    // once the nonlinear systems below have taken theirs; keep its fixed slot
    // (`simulate_idx`) and fill it in there.
    let simulate_slot = bodies.len();
    bodies.push(empty_eqfn());

    // --- Standalone-export metadata: encode the SimData layout, the run settings
    // and the result variables into a blob the standalone wasip1 runtime decodes
    // (via the `om_meta_ptr`/`om_meta_len` exports). It rides in the last passive
    // data segment and is materialized at run time into a runtime-allocated buffer
    // with `memory.init`, exactly like a String literal. These accessors are
    // harmless on the JIT path (unused). ---
    let settings = sim_code
        .simulationSettingsOpt
        .as_ref()
        .ok_or_else(|| "CodegenWasmJit: model has no simulation settings")?;
    apply_variable_filter(&mut result_vars, &settings.variableFilter);
    let model_name = openmodelica_frontend_dump::AbsynUtil::pathString(mi.name.clone(), arcstr::literal!("."), true, false)?.to_string();
    // Solver metadata, shared by the embedded blob and the host `SimModel`.
    let jac_a_n = match dae_mode {
        Some(_) => dae_res_vars.len() as u32,
        None => n_states,
    };
    let mut jac_a = build_jac_a_info(sim_code, jac_a_n);
    // Build the driver metadata once: embedded in the module (for the in-wasm
    // driver / standalone) and kept on the `SimModel` (for the host driver).
    // Only the FMU export needs the vr table; a plain simulation would just carry
    // it around unused.
    let (fmi_vrs, fmi_dae_enable_vr) =
        if fmi_vrs { build_fmi_vrs(sim_code, &var_map, &layout)? } else { (Vec::new(), 0) };
    // C labels its `-lv=LOG_NLS` unknowns from the `_info.json` `defines` array,
    // which `SerializeModelInfo` writes from these same `crefs`.
    // C diagnoses (`newtonDiagnostics`) the systems of `initialEquations_lambda0`,
    // or of `initialEquations` when there is no lambda0 section.
    let nls_in = |eqs: &[Arc<SimCode::SimEqSystem>]| -> HashSet<i32> {
        eqs.iter()
            .filter_map(|e| match &**e {
                SimCode::SimEqSystem::SES_NONLINEAR { nlSystem, .. } => Some(nlSystem.index),
                _ => None,
            })
            .collect()
    };
    let diag_nls = if lambda0_eqs.is_empty() { nls_in(&initial_eqs) } else { nls_in(&lambda0_eqs) };
    let nls_vars = nls_systems
        .iter()
        .map(|sys| {
            let names = lst(&sys.crefs).map(cref_display).collect::<Result<Vec<_>>>()?;
            // C's `eqn_simcode_indices` runs over the torn equations first; only
            // the `size` residual ones at the end are read back.
            let eqns: Vec<i32> = lst(&sys.eqs).map(|e| eq_index_of(e)).collect();
            let tail = eqns.len().saturating_sub(names.len());
            let pattern = match &sys.jacobianMatrix {
                Some(jm) => [
                    lst(&jm.nonlinear).count() as u32,
                    lst(&jm.nonlinearT).count() as u32,
                    lst(&jm.nonlinear).map(|(_, cols)| lst(cols).count() as u32).sum(),
                ],
                None => [0; 3],
            };
            Ok(openmodelica_sim_meta::NlsVars {
                eq_index: sys.index as u32,
                names,
                eqns: eqns[tail..].to_vec(),
                pattern,
                init_diag: diag_nls.contains(&sys.index),
            })
        })
        .collect::<Result<Vec<_>>>()?;
    // The residual Jacobian's sparsity is a matrix of its own, not the ODE `A` that
    // the backend leaves empty in DAE mode.
    let dae = dae_mode
        .map(|d| -> Result<openmodelica_sim_meta::DaeInfo> {
            let alg_offs = dae_alg_vars
                .iter()
                .map(|sv| {
                    let key = sim_cref_key(&sv.name)?;
                    var_map
                        .vars
                        .get(&key)
                        .map(|s| s.off)
                        .ok_or("CodegenWasmJit: DAE mode algebraic unknown has no SimData slot")
                })
                .collect::<Result<Vec<u32>>>()?;
            Ok(openmodelica_sim_meta::DaeInfo {
                alg_offs,
                sparsity: d.sparsityPattern.as_ref().and_then(|jm| jac_pattern_info(jm, dae_res_vars.len())),
            })
        })
        .transpose()?;
    // Lowering the columns is what decides which matrices survive; everything below
    // reads `linz.jacs` after this.
    let (linz_jac_fns, jac_a_fns, opt_jac_fns, jac_adj_fns) = build_jac_fns(
        &mut linz, &linz_jac_infos, optimization::is_optimization(sim_code), &layout, &var_map,
        &eq_index, &by_name, &mut literals, adj_jac_info.as_ref().map(|a| &a.map),
    )?;
    // Same for F/H, before the metadata is built: a matrix that does not lower is
    // dropped from the plan, and `ReconInfo` must not advertise it.
    let recon_jac_fns = match recon.present {
        true => Some(datarecon::build_jac_fns(
            &mut recon, &mut recon_jac_infos, &var_map, &eq_index, &by_name, &mut literals,
        )?),
        false => None,
    };
    // C's `JACOBIAN_AVAILABLE`: "A" lowered, at a shape indexable by state.
    if let (Some(info), Some(sym_info)) = (jac_a.as_mut(), linz_jac_infos[0].as_ref())
        && linz.jacs[0].is_some()
        && sym_info.seed_offs.len() == n_states as usize
        && sym_info.result_offs.len() == n_states as usize
    {
        info.sym = Some(openmodelica_sim_meta::JacSym {
            seed_offs: sym_info.seed_offs.clone(),
            // A row the backend left out is structurally zero, so it has no slot.
            result_offs: sym_info.result_offs.iter().map(|o| o.unwrap_or(u32::MAX)).collect(),
            has_constant: linz.jacs[0]
                .as_ref()
                .and_then(|jm| lst(&jm.columns).next())
                .is_some_and(|c| lst(&c.constantEqns).next().is_some()),
            adj: None,
        });
        if let (Some(jm), Some(adj), Some(sym)) = (linz.adj.as_ref(), adj_jac_info.as_ref(), info.sym.as_mut())
            && adj.info.seed_offs.len() == n_states as usize
            && adj.info.result_offs.len() == n_states as usize
        {
            sym.adj = Some(openmodelica_sim_meta::JacAdj {
                seed_offs: adj.info.seed_offs.clone(),
                result_offs: adj.info.result_offs.iter().map(|o| o.unwrap_or(u32::MAX)).collect(),
                zero_offs: adj.zero_offs.clone(),
                has_constant: lst(&jm.columns).next().is_some_and(|c| lst(&c.constantEqns).next().is_some()),
                row_colors: row_coloring(&info.rows_by_col, n_states as usize),
            });
        }
    }
    // `method="optimization"`: B, C and D with the slots the optimizer seeds and
    // reads, plus the problem's own metadata.
    let opt_info = {
        let jacs: [Option<openmodelica_sim_meta::OptJac>; 3] = core::array::from_fn(|i| {
            let k = i + 1; // B, C, D
            let (jm, info) = (linz.jacs[k].as_ref()?, linz_jac_infos.get(k)?.as_ref()?);
            Some(optimization::opt_jac(
                jm,
                linz.real_rows[k],
                linz.real_cols[k],
                &info.seed_offs,
                &info.result_offs,
                OPT_JAC_FNS[2 * i + 1],
                match lst(&jm.columns).next().is_some_and(|c| lst(&c.constantEqns).next().is_some()) {
                    true => OPT_JAC_FNS[2 * i],
                    false => "",
                },
            ))
        });
        let reals: Vec<&SimCodeVar::SimVar> = states
            .iter()
            .copied()
            .chain(lst(&vars.derivativeVars))
            .chain(real_alg_vars(vars))
            .collect();
        optimization::build_opt_info(sim_code, vars, &reals, jacs, &var_map)?
    };
    // C's `inputNames` / `nInputVars`. No slot ⇒ no column to receive.
    let mut input_vars: Vec<openmodelica_sim_meta::InputVar> = Vec::new();
    for sv in lst(&vars.inputVars) {
        let key = sim_cref_key(&sv.name)?;
        let name = cref_display(&sv.name)?;
        match all_reals.iter().position(|r| sim_cref_key(&r.name).ok().as_deref() == Some(key.as_str())) {
            Some(i) => input_vars.push(openmodelica_sim_meta::InputVar {
                off: openmodelica_sim_meta::REAL_OFF + i as u32 * 8,
                start_off: layout.real_start_off(i as u32),
                wty: WTy::F64,
                name,
            }),
            None => {
                if let Some(slot) = var_map.vars.get(&key) {
                    input_vars.push(openmodelica_sim_meta::InputVar {
                        off: slot.off,
                        start_off: slot.off,
                        wty: slot.wty,
                        name,
                    });
                }
            }
        }
    }
    let meta = build_sim_meta(
        &layout, &result_vars, collect_unit_defs(mi, &result_vars), settings, cs_method, fmi_solver_flags, &model_name,
        &sim_code.fileNamePrefix, jac_a.clone(), &state_sets,
        fmi_vrs, fmi_dae_enable_vr, zc_descriptions(&zero_crossings), rel_descriptions(&sim_code.relations),
        param_vars(vars)?, attr_log_entries(sim_code)?,
        removed_init_residuals(sim_code).iter().map(|e| dump_exp(e)).collect(),
        nls_warnings.clone(),
        samples.iter().map(|s| s.index).collect(), soti_vars(vars)?, sens_params, nls_vars,
        mi.varInfo.numLinearSystems.max(0) as u32, dae,
        clocks.iter().map(|c| c.meta.clone()).collect(),
        build_lin_info(&linz, vars, &var_map)?,
        opt_info, input_vars,
        datarecon::build_recon_info(
            sim_code, vars, &recon, &recon_jac_infos, &var_map,
            mi.varInfo.numRelatedBoundaryConditions.max(0) as u32,
        )?,
        prof_info,
        parmod_info.clone(),
    );
    let meta_bytes = openmodelica_sim_meta::encode(&meta);
    let meta_len = meta_bytes.len() as u32;
    let meta_off = literals.intern(&meta_bytes);
    {
        // om_meta_ptr(): rt_alloc(len), memory.init the blob into it, return ptr.
        use we::Instruction as I;
        let mut f = we::Function::new([(1, we::ValType::I32)]);
        f.instruction(&I::I32Const(meta_len as i32));
        f.instruction(&I::Call(rt_index("rt_alloc")?));
        f.instruction(&I::LocalTee(0));
        f.instruction(&I::I32Const(meta_off as i32));
        f.instruction(&I::I32Const(meta_len as i32));
        f.instruction(&I::MemoryInit { mem: 0, data_index: 0 });
        f.instruction(&I::LocalGet(0));
        f.instruction(&I::End);
        bodies.push(f);
    }
    {
        // om_meta_len(): the constant blob length.
        use we::Instruction as I;
        let mut f = we::Function::new([]);
        f.instruction(&I::I32Const(meta_len as i32));
        f.instruction(&I::End);
        bodies.push(f);
    }

    // --- External-object destructors (teardown). One function that calls each
    // extObj's `<class>.destructor(handle)`, reading the handle from its SimData
    // slot, in `listReverse(extObjInfo.vars)` order as CodegenC's
    // `callExternalObjectDestructors` does — the causalized construction order,
    // a different permutation from the `extObjVars` slot order. ---
    let extobj_vars: Vec<&SimCodeVar::SimVar> = lst(&vars.extObjVars).collect();
    let extobj_slot: HashMap<String, u32> = extobj_vars
        .iter()
        .enumerate()
        .map(|(i, sv)| Ok((sim_cref_key(&sv.name)?, layout.eobj_off + (i as u32) * 4)))
        .collect::<Result<_>>()?;
    let mut destruct_order: Vec<&SimCodeVar::SimVar> = lst(&sim_code.extObjInfo.vars).collect();
    if destruct_order.len() != extobj_vars.len()
        || destruct_order.iter().any(|sv| {
            sim_cref_key(&sv.name).is_ok_and(|k| !extobj_slot.contains_key(&k))
        })
    {
        destruct_order = extobj_vars.clone();
    }
    destruct_order.reverse();
    // Always emitted + exported (empty when the model has no external objects) so
    // the standalone `wasm-merge` and interactive table always resolve it. It is
    // the first body after the fixed base functions, so its index stays `eq_base+8`.
    let destructors_idx = {
        use we::Instruction as I;
        let mut f = we::Function::new([]);
        for sv in &destruct_order {
            let key = extobj_destructor_key(sv)?;
            let didx = by_name
                .get(&key)
                .ok_or_else(|| "CodegenWasmJit: external-object destructor was not compiled")?
                .index;
            let slot = *extobj_slot
                .get(&sim_cref_key(&sv.name)?)
                .ok_or_else(|| "CodegenWasmJit: external object has no SimData slot")?;
            f.instruction(&I::LocalGet(0)); // SimData*
            f.instruction(&I::I32Load(crate::CodegenWasmJitFunctions::mem_arg(slot, 2))); // handle
            f.instruction(&I::Call(didx));
        }
        f.instruction(&I::End);
        bodies.push(f);
        eq_base + 8
    };

    // --- Nonlinear-system callbacks: per system a `residual`/`load` function.
    // The module's `start` (built last, shared with the closure thunks) appends
    // them to the shared table, base in the `nls_base` global; every `ref.func`d
    // callback is also listed in the declared element segment below so the
    // references validate. Only when the model has nonlinear systems. ---
    let nls_wiring = if nls_types.is_some() {
        let mut callback_indices: Vec<u32> = Vec::new(); // for the declared segment
        // (residual, load, Option<jac>, Option<strict>) per system; the shared table
        // gets 4 slots per system (`4k`..`4k+3`), unused ones left null.
        let mut fn_indices: Vec<(u32, u32, Option<u32>, Option<u32>)> = Vec::new();
        for sys in &nls_systems {
            // The job the casual set's fourth callback solves.
            let strict = nls_strict_of
                .get(&sys.index)
                .and_then(|i| var_map.nls_jobs.get(i))
                .copied();
            let (res_fn, load_fn, jac_fn, strict_fn) = build_nls_fns(
                sys, &var_map, &eq_index, &by_name, &mut literals,
                nls_jac_infos.get(&sys.index), strict,
            )?;
            let res_idx = import_base + bodies.len() as u32;
            bodies.push(res_fn);
            let load_idx = import_base + bodies.len() as u32;
            bodies.push(load_fn);
            callback_indices.push(res_idx);
            callback_indices.push(load_idx);
            let jac_idx = jac_fn.map(|f| {
                let idx = import_base + bodies.len() as u32;
                bodies.push(f);
                callback_indices.push(idx);
                idx
            });
            let strict_idx = strict_fn.map(|f| {
                let idx = import_base + bodies.len() as u32;
                bodies.push(f);
                callback_indices.push(idx);
                idx
            });
            fn_indices.push((res_idx, load_idx, jac_idx, strict_idx));
        }
        Some((fn_indices, callback_indices))
    } else {
        None
    };

    // --- The optional equation functions, appended last so the indices above are
    // undisturbed. All always emitted + exported (an empty stub when the model
    // lacks the feature) so the standalone `wasm-merge` and the interactive shared
    // table always resolve every driver entry point; the shared driver only calls
    // one when its metadata count is nonzero, so a stub is never entered. ---
    let init_sample_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if samples.is_empty() {
            empty_eqfn()
        } else {
            build_init_sample_fn(&samples, &layout, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    let zc_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if zero_crossings.is_empty() {
            empty_eqfn()
        } else {
            build_zero_crossings_fn(&zero_crossings, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    let stateset_jac_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if state_sets.is_empty() {
            empty_eqfn()
        } else {
            build_stateset_jac_fn(&sim_code.stateSets, &var_map, &eq_index, &by_name, &mut literals)?
        });
        idx
    };
    // C's `functionJacA_constantEqns` / `functionJacA_column`.
    let jac_a_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.extend(jac_a_fns);
        idx
    };
    let jac_adj_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.extend(jac_adj_fns);
        idx
    };
    // The lambda-0 (simplified) initial system, for the homotopy continuation's
    // first step; a stub for models that do not use `homotopy()`.
    let init_lambda0_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("functionInitialEquations_lambda0", &eq_units(&lambda0_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };
    // Min/max variable-attribute (and equation) assertion checks: C's
    // `checkForAsserts`, evaluated at each accepted output point. Warning-level
    // asserts record a `LOG_ASSERT` via `rt_assert_warning` and continue.
    let has_asserts = !assert_eqs.is_empty();
    let check_asserts_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("functionCheckAsserts", &eq_units(&assert_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };
    // C's `function_ZeroCrossingsEquations`: what the crossings read, which is
    // neither `functionODE` nor all of `functionAlgebraics`.
    let zc_equations_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("functionZeroCrossingsEquations", &eq_units(&zc_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };
    // The name the FMI getters call `functionAlgebraics` by.
    let outputs_idx = {
        let idx = import_base + bodies.len() as u32;
        use we::Instruction as I;
        let mut f = we::Function::new([]);
        f.instruction(&I::LocalGet(0));
        f.instruction(&I::Call(eqfn.algebraics));
        f.instruction(&I::End);
        bodies.push(f);
        idx
    };
    bodies[simulate_slot] = build_simulate(&layout, &eqfn, has_asserts.then_some(check_asserts_idx))?;
    let update_relations_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if relations.iter().all(Option::is_none) {
            empty_eqfn()
        } else {
            build_update_relations_fn(&relations, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    // `functionStoreDelayed` / `functionInitDelay` (C's `function_storeDelayed` +
    // `rt_delay_init`); empty stubs when the model has no `delay(...)`.
    let store_delayed_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if var_map.n_delays == 0 {
            empty_eqfn()
        } else {
            build_store_delayed_fn(sim_code, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    let init_delay_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if var_map.n_delays == 0 {
            empty_eqfn()
        } else {
            build_init_delay_fn(var_map.n_delays)
        });
        idx
    };
    // `functionStoreSpatialDistribution` / `functionInitSpatialDistribution` (C's
    // `function_storeSpatialDistribution` + `function_initSpatialDistribution`);
    // empty stubs when the model has no `spatialDistribution(...)`.
    let store_spatial_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if var_map.n_spatial == 0 {
            empty_eqfn()
        } else {
            build_store_spatial_fn(sim_code, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    let init_spatial_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if var_map.n_spatial == 0 {
            empty_eqfn()
        } else {
            build_init_spatial_fn(sim_code, &var_map, &by_name, &mut literals)?
        });
        idx
    };
    // C's `updateBoundParameters`: `parameterEquations` *without* the constant
    // bindings, so re-evaluating the dependent parameters does not undo a
    // perturbation IDAS made to a sensitivity parameter.
    let update_bound_params_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("functionUpdateBoundParameters", &eq_units(&param_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };
    // The optimizer's per-real-variable attributes (C reads them out of the
    // `_init.xml`): constants here, parameter-dependent ones through `attr_targets`.
    let opt_attrs = match layout.n_opt_attr {
        0 => optimization::AttrDefaults { reals: Vec::new(), ints: Vec::new() },
        _ => {
            let reals: Vec<&SimCodeVar::SimVar> = states
                .iter()
                .copied()
                .chain(lst(&vars.derivativeVars))
                .chain(real_alg_vars(vars))
                .collect();
            optimization::attr_defaults(&reals, &layout, &mut attr_targets)
        }
    };
    let update_bound_attrs_idx = {
        let idx = import_base + bodies.len() as u32;
        let defaults: Vec<(u32, f64)> = nominal_defaults
            .iter()
            .chain(max_defaults.iter())
            .chain(opt_attrs.reals.iter())
            .copied()
            .collect();
        bodies.push(build_update_bound_attrs_fn(
            sim_code, &layout, &defaults, &opt_attrs.ints, &attr_targets, &var_map, &by_name,
            &mut literals,
        )?);
        idx
    };
    // C's `setupDataStruc` half: the constant defaults, written before the solver is
    // allocated. The expression-bound ones stay in the update function.
    let attr_defaults_idx = {
        let idx = import_base + bodies.len() as u32;
        let defaults: Vec<(u32, f64)> =
            nominal_defaults.iter().chain(max_defaults.iter()).copied().collect();
        bodies.push(build_attr_defaults_fn(&defaults, &var_map, &by_name, &mut literals)?);
        idx
    };
    // Always exported (empty when the backend generated none) so the standalone
    // merge resolves regardless of the model.
    let linz_jac_idx = {
        let base = import_base + bodies.len() as u32;
        bodies.extend(linz_jac_fns);
        base
    };
    let opt_jac_idx = {
        let base = import_base + bodies.len() as u32;
        bodies.extend(opt_jac_fns);
        base
    };
    // `-reconcile`'s F/H, only for a model the extraction algorithm ran on.
    let recon_jac_idx = recon_jac_fns.map(|fns| {
        let base = import_base + bodies.len() as u32;
        bodies.extend(fns);
        base
    });
    // Synchronous features. Always emitted, as the C target emits them (empty
    // without clocked partitions): an FMU adapter cannot import them
    // conditionally without leaving a clock-free model's `env` import unresolved.
    let sync_idx = {
        let init = import_base + bodies.len() as u32;
        bodies.push(build_init_synchronous_fn(&clocks, &layout, &var_map, &by_name, &mut literals)?);
        bodies.push(build_update_synchronous_fn(&clocks, &layout, &var_map, &by_name, &mut literals)?);
        bodies.push(build_equations_synchronous_fn(
            &clocks, &layout, &var_map, &eq_index, &by_name, &mut literals,
        )?);
        (init, init + 1, init + 2)
    };
    // C's over-determined check; a stub when nothing was removed.
    let removed_init_idx = {
        let idx = import_base + bodies.len() as u32;
        bodies.push(if count(&sim_code.removedInitialEquations) == 0 {
            empty_eqfn()
        } else {
            build_removed_init_eqs_fn(sim_code, &layout, &var_map, &eq_index, &by_name, &mut literals)?
        });
        idx
    };
    // `layout.dae_mode()`, not this function's presence, is what tells a driver
    // which form the model is in.
    let dae_residuals_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("evaluateDAEResiduals", &dae_units(&dae_eqs), 2, dae_fn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };
    // C's `symbolicInlineSystem`. Emitted (empty without `--symSolver`) either way,
    // so every module's entry points sit at the same indices.
    let sym_inline_idx = {
        let idx = import_base + bodies.len() as u32;
        splits.push(build_split_fn("symbolicInlineSystem", &eq_units(&inline_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
        idx
    };

    // C's `functionDAE`: `functionLocalKnownVars` + `allEquations` in the discrete
    // context, and the discrete pass wherever `functionAlgebraics` is not already the
    // full list: the sorted order interleaves the two subsets, so `functionODE` then
    // `functionAlgebraics` would read an algebraic variable one pass stale. Exported
    // from every model, as `MODEL_FNS` promises the runtimes that import it by name.
    let dae_entry_idx = {
        let idx = import_base + bodies.len() as u32;
        match dae_chunks {
            Some(chunks) => {
                let slot = bodies.len();
                bodies.push(empty_eqfn());
                splits.push(SplitFn { slot, chunks, n_params: 1, pre_calls: Vec::new() });
            }
            None => {
                let mut units = eq_units(&local_known_eqs);
                units.extend(eq_units(&all_eqs));
                splits.push(build_split_fn("functionDAE", &units, 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
            }
        }
        idx
    };

    // `parmodTask(sim_data, k)` `call_indirect`s task `k` out of the module's own table 1.
    let parmod_fns = match parmod_info.is_some() {
        false => None,
        true => {
            let lk_idx = import_base + bodies.len() as u32;
            splits.push(build_split_fn("functionLocalKnownVars", &eq_units(&local_known_eqs), 1, eqfn_type, &[], &[], &var_map, &eq_index, &by_name, &mut literals, &mut bodies, &mut pool, false)?);
            splits[ode_split].pre_calls.push(lk_idx);
            let task_idx = import_base + bodies.len() as u32;
            let mut f = we::Function::new([]);
            f.instruction(&we::Instruction::LocalGet(0));
            f.instruction(&we::Instruction::LocalGet(1));
            f.instruction(&we::Instruction::CallIndirect { type_index: eqfn_type as u32, table_index: 1 });
            f.instruction(&we::Instruction::End);
            bodies.push(f);
            Some((lk_idx, task_idx))
        }
    };

    // The chunks, after all fixed-index bodies; each entry point's placeholder
    // becomes a thunk calling the ones it needs.
    let chunk_base = import_base + bodies.len() as u32;
    let ChunkPool { fns: chunk_fns, meta: chunk_meta } = pool;
    bodies.extend(chunk_fns);
    for s in &splits {
        bodies[s.slot] = s.thunk(chunk_base);
    }
    let parmod_tasks: Option<Vec<u32>> = parmod_fns.map(|_| {
        splits[ode_split].chunks.iter().map(|c| chunk_base + *c as u32).collect()
    });

    // --- Function section (type index per body, in body order). ---
    crate::CodegenWasmJitFunctions::set_ext_error_catch(None);
    crate::CodegenWasmJitFunctions::set_assert_throw_tag(None);
    crate::CodegenWasmJitFunctions::set_native_externals([]);

    let mut functions = we::FunctionSection::new();
    for ti in &model_fn_type {
        functions.function(*ti);
    }
    // param / initial / ode / algebraics / initStartValues — all (i32) -> ().
    for _ in 0..5 {
        functions.function(eqfn_type);
    }
    functions.function(simulate_type);
    functions.function(meta_fn_type); // om_meta_ptr
    functions.function(meta_fn_type); // om_meta_len
    // Optional eq functions — always emitted (order must match the `bodies` pushes:
    // destructors, nls callbacks, initSample, zc, statesetJac, lambda0, …, then
    // the closure thunks and `start` below).
    functions.function(eqfn_type); // callExternalObjectDestructors
    if let Some((residual_type, load_type, strict_type)) = nls_types {
        for sys in &nls_systems {
            functions.function(residual_type);
            functions.function(load_type);
            // The analytic-Jacobian callback (3 params, like the residual) is emitted
            // and type-listed only for systems that have a usable symbolic Jacobian —
            // matching the conditional body push in `nls_wiring`.
            if nls_jac_infos.contains_key(&sys.index) {
                functions.function(residual_type);
            }
            if nls_strict_of.contains_key(&sys.index) {
                functions.function(strict_type);
            }
        }
    }
    functions.function(eqfn_type); // initSample: (i32) -> ()
    functions.function(sync_fn_type); // functionZeroCrossings: (i32 SimData, i32 gout) -> ()
    functions.function(eqfn_type); // functionStateSetJacobians: (i32) -> ()
    functions.function(eqfn_type); // functionJacA_constantEqns: (i32) -> ()
    functions.function(eqfn_type); // functionJacA_column: (i32) -> ()
    functions.function(eqfn_type); // functionJacADJ_constantEqns: (i32) -> ()
    functions.function(eqfn_type); // functionJacADJ_column: (i32) -> ()
    functions.function(eqfn_type); // functionInitialEquations_lambda0: (i32) -> ()
    functions.function(eqfn_type); // functionCheckAsserts: (i32) -> ()
    functions.function(eqfn_type); // functionZeroCrossingsEquations: (i32) -> ()
    functions.function(eqfn_type); // functionOutputs: (i32) -> ()
    functions.function(eqfn_type); // functionUpdateRelations: (i32) -> ()
    functions.function(eqfn_type); // functionStoreDelayed: (i32) -> ()
    functions.function(eqfn_type); // functionInitDelay: (i32) -> ()
    functions.function(eqfn_type); // functionStoreSpatialDistribution: (i32) -> ()
    functions.function(eqfn_type); // functionInitSpatialDistribution: (i32) -> ()
    functions.function(eqfn_type); // functionUpdateBoundParameters: (i32) -> ()
    functions.function(eqfn_type); // functionUpdateBoundVariableAttributes: (i32) -> ()
    functions.function(eqfn_type); // functionAttrDefaults: (i32) -> ()
    for _ in 0..4 {
        functions.function(eqfn_type); // linearJacA..linearJacD: (i32) -> ()
    }
    for _ in 0..OPT_JAC_FNS.len() {
        functions.function(eqfn_type); // optJac{B,C,D}{_const,}: (i32) -> ()
    }
    for _ in 0..(if recon.present { datarecon::JAC_FNS.len() } else { 0 }) {
        functions.function(eqfn_type); // reconJacF / reconJacH: (i32) -> ()
    }
    functions.function(eqfn_type); // functionInitSynchronous: (i32) -> ()
    functions.function(sync_fn_type); // functionUpdateSynchronous: (i32, i32) -> ()
    functions.function(sync_fn_type); // functionEquationsSynchronous: (i32, i32) -> ()
    functions.function(eqfn_type); // functionRemovedInitialEquations: (i32) -> ()
    functions.function(dae_fn_type); // evaluateDAEResiduals: (i32, i32) -> ()
    functions.function(eqfn_type); // symbolicInlineSystem: (i32) -> ()
    functions.function(eqfn_type); // functionDAE: (i32) -> ()
    if parmod_fns.is_some() {
        functions.function(eqfn_type); // functionLocalKnownVars: (i32) -> ()
        functions.function(dae_fn_type); // parmodTask: (i32 SimData, i32 task) -> ()
    }
    for (ty, _) in &chunk_meta {
        functions.function(*ty);
    }

    // --- Shared literals, closure thunks and the module `start`. Both come after
    // every other body — their indices are only known here. ---
    let lits = crate::CodegenWasmJitFunctions::shared_lits::take();
    let lit_init = lits
        .iter()
        .any(|s| s.is_some())
        .then(|| {
            crate::CodegenWasmJitFunctions::shared_lits::build_init_fn(
                &lits, lit_global, &by_name, &mut literals,
            )
        })
        .transpose()?;
    let closure_wiring = crate::CodegenWasmJitFunctions::closures::take();
    let mut thunk_indices: Vec<u32> = Vec::new();
    for (type_index, body) in closure_wiring.thunks {
        thunk_indices.push(import_base + bodies.len() as u32);
        functions.function(type_index);
        bodies.push(body);
    }
    for (params, results) in &closure_wiring.types {
        types.ty().function(params.iter().copied(), results.iter().copied());
    }
    let start_wiring = if nls_wiring.is_some() || !thunk_indices.is_empty() || lit_init.is_some() {
        let void_type = types.len();
        types.ty().function([], []);
        let lit_init_idx = lit_init.map(|f| {
            let idx = import_base + bodies.len() as u32;
            functions.function(void_type);
            bodies.push(f);
            idx
        });
        let start_idx = import_base + bodies.len() as u32;
        let mut f = we::Function::new([]);
        if let Some(i) = lit_init_idx {
            f.instruction(&we::Instruction::Call(i));
        }
        if let Some((fn_indices, _)) = &nls_wiring {
            let sizes: Vec<u32> = nls_systems.iter().map(|s| lst(&s.crefs).count() as u32).collect();
            emit_nls_start(&mut f, fn_indices, nls_hist_bytes, &sizes, &nls_nominals, &nls_bounds, &nls_patterns);
        }
        if !thunk_indices.is_empty() {
            crate::CodegenWasmJitFunctions::closures::emit_start(&mut f, &thunk_indices, closure_global);
        }
        f.instruction(&we::Instruction::End);
        functions.function(void_type);
        bodies.push(f);
        let mut declared: Vec<u32> =
            nls_wiring.as_ref().map(|(_, cbs)| cbs.clone()).unwrap_or_default();
        declared.extend_from_slice(&thunk_indices);
        Some((start_idx, declared))
    } else {
        None
    };
    // The throw a host-free `rt_ext_error` reaches for, rustc emitting none for a
    // wasm target. Always exported, whatever the model does: the runtime module is
    // prebuilt and its import cannot be conditional.
    let throw_fn = import_base + bodies.len() as u32;
    {
        let mut f = we::Function::new([]);
        f.instruction(&match error_tag_type {
            Some(_) => we::Instruction::Throw(0),
            None => we::Instruction::Unreachable,
        });
        f.instruction(&we::Instruction::End);
        functions.function(throw_fn_type);
        bodies.push(f);
    }
    if nls_wiring.is_some() || !thunk_indices.is_empty() || parmod_fns.is_some() {
        imports.import("rt", "__indirect_function_table", we::EntityType::Table(we::TableType {
            element_type: we::RefType::FUNCREF,
            table64: false,
            minimum: 1,
            maximum: None,
            shared: false,
        }));
    }

    // `<entry>$guard`: the entry point under a `try_table` for the model-error tag, so
    // the adapter answers a status rather than trapping — a trapped component is done.
    let guarded: Vec<(&str, u32)> = vec![
        ("functionParameters", eqfn.parameters),
        ("functionInitialEquations", eqfn.initial),
        ("functionInitStartValues", eqfn.init_start_values),
        ("functionODE", eqfn.ode),
        ("functionAlgebraics", eqfn.algebraics),
        ("functionOutputs", outputs_idx),
        ("callExternalObjectDestructors", destructors_idx),
        ("initSample", init_sample_idx),
        ("functionZeroCrossingsEquations", zc_equations_idx),
        ("functionStateSetJacobians", stateset_jac_idx),
        ("functionJacA_constantEqns", jac_a_idx),
        ("functionJacA_column", jac_a_idx + 1),
        ("functionInitialEquations_lambda0", init_lambda0_idx),
        ("functionCheckAsserts", check_asserts_idx),
        ("functionUpdateRelations", update_relations_idx),
        ("functionStoreDelayed", store_delayed_idx),
        ("functionInitDelay", init_delay_idx),
        ("functionStoreSpatialDistribution", store_spatial_idx),
        ("functionInitSpatialDistribution", init_spatial_idx),
        ("functionUpdateBoundParameters", update_bound_params_idx),
        ("functionUpdateBoundVariableAttributes", update_bound_attrs_idx),
        ("functionAttrDefaults", attr_defaults_idx),
        ("functionRemovedInitialEquations", removed_init_idx),
        ("functionInitSynchronous", sync_idx.0),
        ("symbolicInlineSystem", sym_inline_idx),
        ("functionDAE", dae_entry_idx),
        ("linearJacA", linz_jac_idx),
        ("linearJacB", linz_jac_idx + 1),
        ("linearJacC", linz_jac_idx + 2),
        ("linearJacD", linz_jac_idx + 3),
    ];
    let guard_base = import_base + bodies.len() as u32;
    if error_tag_type.is_some() {
        for (_, target) in &guarded {
            functions.function(guard_fn_type);
            bodies.push(build_guard_fn(*target));
        }
    }

    // --- Code section. ---
    let mut code = we::CodeSection::new();
    for body in &bodies {
        code.function(body);
    }

    // --- Exports: the equation functions (for the host-driven driver) and
    // `simulate` (for the in-wasm driver). ---
    let mut exports = we::ExportSection::new();
    if error_tag_type.is_some() {
        // Exported for the host to throw with; caught here whoever throws, so the
        // tag itself never crosses a module boundary.
        exports.export("model_error", we::ExportKind::Tag, 0);
    }
    exports.export("om_throw_model_error", we::ExportKind::Func, throw_fn);
    exports.export("functionParameters", we::ExportKind::Func, eqfn.parameters);
    exports.export("functionInitialEquations", we::ExportKind::Func, eqfn.initial);
    exports.export("functionInitStartValues", we::ExportKind::Func, eqfn.init_start_values);
    exports.export("functionODE", we::ExportKind::Func, eqfn.ode);
    exports.export("functionAlgebraics", we::ExportKind::Func, eqfn.algebraics);
    exports.export("functionOutputs", we::ExportKind::Func, outputs_idx);
    if let Some((lk_idx, task_idx)) = parmod_fns {
        exports.export("functionLocalKnownVars", we::ExportKind::Func, lk_idx);
        exports.export("parmodTask", we::ExportKind::Func, task_idx);
    }
    exports.export("simulate", we::ExportKind::Func, simulate_idx);
    exports.export("om_meta_ptr", we::ExportKind::Func, om_meta_ptr_idx);
    exports.export("om_meta_len", we::ExportKind::Func, om_meta_len_idx);
    exports.export("callExternalObjectDestructors", we::ExportKind::Func, destructors_idx);
    exports.export("initSample", we::ExportKind::Func, init_sample_idx);
    exports.export("functionZeroCrossings", we::ExportKind::Func, zc_idx);
    exports.export("functionZeroCrossingsEquations", we::ExportKind::Func, zc_equations_idx);
    exports.export("functionStateSetJacobians", we::ExportKind::Func, stateset_jac_idx);
    exports.export("functionJacA_constantEqns", we::ExportKind::Func, jac_a_idx);
    exports.export("functionJacA_column", we::ExportKind::Func, jac_a_idx + 1);
    exports.export("functionJacADJ_constantEqns", we::ExportKind::Func, jac_adj_idx);
    exports.export("functionJacADJ_column", we::ExportKind::Func, jac_adj_idx + 1);
    exports.export("functionInitialEquations_lambda0", we::ExportKind::Func, init_lambda0_idx);
    exports.export("functionCheckAsserts", we::ExportKind::Func, check_asserts_idx);
    exports.export("functionUpdateRelations", we::ExportKind::Func, update_relations_idx);
    exports.export("functionStoreDelayed", we::ExportKind::Func, store_delayed_idx);
    exports.export("functionInitDelay", we::ExportKind::Func, init_delay_idx);
    exports.export("functionStoreSpatialDistribution", we::ExportKind::Func, store_spatial_idx);
    exports.export("functionInitSpatialDistribution", we::ExportKind::Func, init_spatial_idx);
    exports.export("functionUpdateBoundParameters", we::ExportKind::Func, update_bound_params_idx);
    exports.export("functionUpdateBoundVariableAttributes", we::ExportKind::Func, update_bound_attrs_idx);
    exports.export("functionAttrDefaults", we::ExportKind::Func, attr_defaults_idx);
    for (k, name) in ["linearJacA", "linearJacB", "linearJacC", "linearJacD"].iter().enumerate() {
        exports.export(name, we::ExportKind::Func, linz_jac_idx + k as u32);
    }
    for (k, name) in OPT_JAC_FNS.iter().enumerate() {
        exports.export(*name, we::ExportKind::Func, opt_jac_idx + k as u32);
    }
    if let Some(base) = recon_jac_idx {
        for (k, name) in datarecon::JAC_FNS.iter().enumerate() {
            exports.export(name, we::ExportKind::Func, base + k as u32);
        }
    }
    exports.export("functionDAE", we::ExportKind::Func, dae_entry_idx);
    let (sync_init, sync_update, sync_eqs) = sync_idx;
    exports.export("functionRemovedInitialEquations", we::ExportKind::Func, removed_init_idx);
    exports.export("functionInitSynchronous", we::ExportKind::Func, sync_init);
    exports.export("functionUpdateSynchronous", we::ExportKind::Func, sync_update);
    exports.export("functionEquationsSynchronous", we::ExportKind::Func, sync_eqs);
    exports.export("evaluateDAEResiduals", we::ExportKind::Func, dae_residuals_idx);
    exports.export("symbolicInlineSystem", we::ExportKind::Func, sym_inline_idx);
    if error_tag_type.is_some() {
        for (k, (name, _)) in guarded.iter().enumerate() {
            exports.export(&format!("{name}$guard"), we::ExportKind::Func, guard_base + k as u32);
        }
    }

    // --- Name section: without it a trap backtrace is bare function indices. The
    // unnamed remainder is the NLS callbacks, the closure thunks and `start`. ---
    let mut names: Vec<(u32, String)> = Vec::new();
    for (i, name) in BUILTINS
        .iter()
        .map(|b| b.0)
        .chain(RT_BUILTINS.iter().map(|b| b.0))
        .chain(ENV_EXTRA.iter().map(|b| b.0))
        .enumerate()
    {
        names.push((i as u32, name.to_string()));
    }
    for (i, sig) in ext_imports.iter().enumerate() {
        names.push((ext_base + i as u32, format!("ext.{}", sig.name)));
    }
    for (id, f) in model_fns.iter().enumerate() {
        names.push((import_base + id as u32, function_signature(f)?.0));
    }
    for (name, idx) in [
        ("functionParameters", eqfn.parameters),
        ("functionInitialEquations", eqfn.initial),
        ("functionInitStartValues", eqfn.init_start_values),
        ("functionODE", eqfn.ode),
        ("functionAlgebraics", eqfn.algebraics),
        ("functionOutputs", outputs_idx),
        ("simulate", simulate_idx),
        ("om_meta_ptr", om_meta_ptr_idx),
        ("om_meta_len", om_meta_len_idx),
        ("callExternalObjectDestructors", destructors_idx),
        ("initSample", init_sample_idx),
        ("functionZeroCrossings", zc_idx),
        ("functionZeroCrossingsEquations", zc_equations_idx),
        ("functionStateSetJacobians", stateset_jac_idx),
        ("functionJacA_constantEqns", jac_a_idx),
        ("functionJacA_column", jac_a_idx + 1),
        ("functionJacADJ_constantEqns", jac_adj_idx),
        ("functionJacADJ_column", jac_adj_idx + 1),
        ("functionInitialEquations_lambda0", init_lambda0_idx),
        ("functionCheckAsserts", check_asserts_idx),
        ("functionUpdateRelations", update_relations_idx),
        ("functionStoreDelayed", store_delayed_idx),
        ("functionInitDelay", init_delay_idx),
        ("functionStoreSpatialDistribution", store_spatial_idx),
        ("functionInitSpatialDistribution", init_spatial_idx),
        ("functionUpdateBoundParameters", update_bound_params_idx),
        ("functionUpdateBoundVariableAttributes", update_bound_attrs_idx),
        ("functionAttrDefaults", attr_defaults_idx),
        ("linearJacA", linz_jac_idx),
        ("linearJacB", linz_jac_idx + 1),
        ("linearJacC", linz_jac_idx + 2),
        ("linearJacD", linz_jac_idx + 3),
        (OPT_JAC_FNS[0], opt_jac_idx),
        (OPT_JAC_FNS[1], opt_jac_idx + 1),
        (OPT_JAC_FNS[2], opt_jac_idx + 2),
        (OPT_JAC_FNS[3], opt_jac_idx + 3),
        (OPT_JAC_FNS[4], opt_jac_idx + 4),
        (OPT_JAC_FNS[5], opt_jac_idx + 5),
    ] {
        names.push((idx, name.to_string()));
    }
    names.push((removed_init_idx, "functionRemovedInitialEquations".to_string()));
    if let Some(base) = recon_jac_idx {
        for (k, name) in datarecon::JAC_FNS.iter().enumerate() {
            names.push((base + k as u32, name.to_string()));
        }
    }
    names.push((dae_entry_idx, "functionDAE".to_string()));
    names.push((sync_init, "functionInitSynchronous".to_string()));
    names.push((sync_update, "functionUpdateSynchronous".to_string()));
    names.push((sync_eqs, "functionEquationsSynchronous".to_string()));
    names.push((dae_residuals_idx, "evaluateDAEResiduals".to_string()));
    names.push((sym_inline_idx, "symbolicInlineSystem".to_string()));
    if let Some((lk_idx, task_idx)) = parmod_fns {
        names.push((lk_idx, "functionLocalKnownVars".to_string()));
        names.push((task_idx, "parmodTask".to_string()));
    }
    for (k, (_, name)) in chunk_meta.iter().enumerate() {
        names.push((chunk_base + k as u32, name.clone()));
    }
    names.sort_by_key(|(idx, _)| *idx);
    let mut fn_names = we::NameMap::new();
    for (idx, name) in &names {
        fn_names.append(*idx, name);
    }
    let mut name_section = we::NameSection::new();
    name_section.functions(&fn_names);

    let mut module = we::Module::new();
    module.section(&types);
    module.section(&imports);
    module.section(&functions);
    if let Some(tasks) = &parmod_tasks {
        let mut tables = we::TableSection::new();
        tables.table(we::TableType {
            element_type: we::RefType::FUNCREF,
            table64: false,
            minimum: tasks.len() as u64,
            maximum: Some(tasks.len() as u64),
            shared: false,
        });
        module.section(&tables);
    }
    if let Some(ti) = error_tag_type {
        let mut tags = we::TagSection::new();
        tags.tag(we::TagType { kind: we::TagKind::Exception, func_type_idx: ti });
        module.section(&tags);
    }
    // Global + Start + Element sections (in the canonical order) carry the
    // shared-table wiring (NLS callbacks and/or closure thunks) and the
    // shared-literal objects.
    // Flag slots need the globals even with no `start` to fill them.
    if start_wiring.is_some() || !lits.is_empty() {
        let mut globals = we::GlobalSection::new();
        // NLS_BASE_GLOBAL (shared-table base), NLS_HIST_GLOBAL (history block base),
        // NLS_NOMINAL_GLOBAL (nominal block base), NLS_PAT_GLOBAL (sparse-pattern
        // block base) and NLS_BOUNDS_GLOBAL (min/max block base) when the model has
        // nonlinear systems, then the closure-thunk table base and one per shared
        // literal; all set by `start`.
        for _ in 0..lit_global as usize + lits.len() {
            globals.global(
                we::GlobalType { val_type: we::ValType::I32, mutable: true, shared: false },
                &we::ConstExpr::i32_const(0),
            );
        }
        module.section(&globals);
    }
    module.section(&exports);
    let mut elements = we::ElementSection::new();
    let mut have_elements = false;
    if let Some((start_idx, declared)) = &start_wiring {
        module.section(&we::StartSection { function_index: *start_idx });
        if !declared.is_empty() {
            elements.declared(we::Elements::Functions(declared.as_slice().into()));
            have_elements = true;
        }
    }
    if let Some(tasks) = &parmod_tasks {
        elements.active(Some(1), &we::ConstExpr::i32_const(0), we::Elements::Functions(tasks.as_slice().into()));
        have_elements = true;
    }
    if have_elements {
        module.section(&elements);
    }
    if !literals.is_empty() {
        module.section(&we::DataCountSection { count: 1 });
    }
    module.section(&code);
    if !literals.is_empty() {
        let mut data = we::DataSection::new();
        data.passive(literals.blob().iter().copied());
        module.section(&data);
    }
    module.section(&name_section);
    let wasm = module.finish();
    // `OMC_WASM_DUMP_DIR=<dir>`: the lowered module as `<dir>/<prefix>.wasm`, for
    // `wasm-objdump` on a trap the backtrace names only by function index.
    #[cfg(not(target_arch = "wasm32"))]
    if let Ok(dir) = std::env::var("OMC_WASM_DUMP_DIR") {
        let _ = std::fs::write(format!("{dir}/{}.wasm", sim_code.fileNamePrefix), &wasm);
    }

    // Kick off the (cranelift) JIT compile of this model module on a background
    // thread now, while the rest of the OMC pipeline (remaining templates,
    // buildModel, the scripting round-trip) runs, so it is off `runSimulation`'s
    // critical path. The thread also warms the process-wide runtime module
    // (compiled once). `runSimulation` joins this via `take_compiled_model`.
    // The runtime module is already compiling (started at `translateModel`
    // entry); compile the model module concurrently here so the two overlap.
    let compile_wasm = wasm.clone();
    // Native: compile on a background thread to overlap the rest of the pipeline.
    // wasm: no threads — compile eagerly and store the result for take_compiled_model.
    // `-n=1`: no job, so `take_compiled_model` compiles inline where it is timed.
    #[cfg(not(target_arch = "wasm32"))]
    let compiled = Mutex::new(match openmodelica_wasm_jit::model::single_threaded() {
        true => None,
        false => Some(std::thread::spawn(move || {
            sim_runtime::compile_model_module(&compile_wasm)
        })),
    });
    #[cfg(target_arch = "wasm32")]
    let compiled = Mutex::new(Some(sim_runtime::compile_model_module(&compile_wasm)));

    Ok(SimModel {
        wasm,
        compiled,
        prepared: Mutex::new(None),
        layout,
        result_vars,
        ext_libs: ext_libs.wasm,
        ext_native,
        ext_builtin,
        ext_native_libs: ext_libs.native,
        ext_native_system: ext_libs.native_system,
        ext_archives,
        ext_includes,
        ext_lib_notes,
        ext_imports,
        model_name,
        start_time: settings.startTime.into_inner(),
        stop_time: settings.stopTime.into_inner(),
        n_intervals: settings.numberOfIntervals.max(0) as u32,
        output_format: settings.outputFormat.to_string(),
        method: settings.method.to_string(),
        tolerance: settings.tolerance.into_inner(),
        state_sets,
        jac_a,
        sparse_nls: var_map.nls_jobs.values().any(|j| j.sparse_default),
        editable_params,
        var_units,
        meta,
    })
}

/// Wrap a `\n`-separated message in the `LOG_STDOUT`/continuation prefixes.
fn format_log_stdout(msg: &str) -> String {
    openmodelica_modelica_utilities::format_log_stdout(msg, openmodelica_modelica_utilities::LOG_STDOUT_INFO)
}

/// C's `homotopySupport` loop over `nonlinearSystemData`: whether a nonlinear
/// system carries the operator, not whether the model uses `homotopy()` at all.
fn nls_homotopy_support(sim_code: &SimCode::SimCode) -> bool {
    let has = |eqs: Vec<Arc<SimCode::SimEqSystem>>| {
        eqs.iter().any(|e| match &**e {
            SimCode::SimEqSystem::SES_NONLINEAR { nlSystem, .. } => nlSystem.homotopySupport,
            _ => false,
        })
    };
    has(flatten_eqs(&sim_code.parameterEquations))
        || has(flatten_eqs(&sim_code.initialEquations))
        || has(flatten_eqs_ll(&sim_code.odeEquations))
        || has(flatten_eqs_ll(&sim_code.algebraicEquations))
}

/// C's `homotopyMethod` model-callback entry, from the same `Config` predicates.
fn homotopy_method() -> Result<openmodelica_sim_meta::HomotopyMethod> {
    use openmodelica_sim_meta::HomotopyMethod as H;
    use openmodelica_util::Config;
    Ok(if Config::replacedHomotopy()? {
        H::None
    } else if Config::adaptiveHomotopy()? {
        if Config::globalHomotopy()? { H::GlobalAdaptive } else { H::LocalAdaptive }
    } else if Config::globalHomotopy()? {
        H::GlobalEquidistant
    } else {
        H::LocalEquidistant
    })
}

/// C's `compiledWithSymSolver`: which `--symSolver` variant generated the model's
/// inline update equations, 0 for none.
fn sym_solver_kind() -> Result<u8> {
    Ok(openmodelica_util::Flags::getConfigEnum(openmodelica_util::Flags::SYM_SOLVER.clone())?
        .clamp(0, 2) as u8)
}

/// C's `LOG_STDOUT` "… changed to …" lines, ahead of everything the run prints.
fn flag_change_log(flags: &simflags::SimFlags) -> String {
    use openmodelica_modelica_utilities::{LOG_STDOUT_INFO, LOG_STDOUT_WARNING};
    let mut out = String::new();
    for (ty, msg) in simflags::notices(flags) {
        let prefix = if ty == openmodelica_sim_meta::omclog::WARNING {
            LOG_STDOUT_WARNING
        } else {
            LOG_STDOUT_INFO
        };
        out.push_str(&openmodelica_modelica_utilities::format_log_stdout(&msg, prefix));
    }
    out
}

/// The nonzero count of a linear system's matrix `A`, matching C's
/// `initializeLinearSystems`: `listLength(simJac)` for the non-torn (method-0)
/// form, else the symbolic Jacobian's sparsity nnz (method 1, torn systems).
fn lin_system_nnz(lsystem: &SimCode::LinearSystem) -> usize {
    let sj = count(&lsystem.simJac) as usize;
    if sj > 0 {
        return sj;
    }
    lsystem
        .jacobianMatrix
        .as_ref()
        .map(|jm| lst(&jm.sparsity).map(|(_, rows)| lst(rows).count()).sum())
        .unwrap_or(0)
}

/// A nonlinear system's Jacobian sparsity in CSC — `colptr` (`n+1`), `rowidx`
/// (`nnz`) and the column coloring. Columns and rows are positional, as C's
/// `evalJacobian` indexes `seedVars[column]` / `resultVars[row]`.
struct NlsJacPattern {
    colptr: Vec<i32>,
    rowidx: Vec<i32>,
    colors: Vec<Vec<u32>>,
}

impl NlsJacPattern {
    fn passes_sanity_check(&self, n: usize) -> bool {
        sparsity_sanity_check(&self.colptr, &self.rowidx, self.colptr.len() - 1, n)
    }

    /// C's `colorCols`, 0-based. A column the backend left out of the colouring gets
    /// one of its own.
    fn color_of_column(&self, n: usize) -> Vec<i32> {
        let mut of = vec![-1i32; n];
        for (c, cols) in self.colors.iter().enumerate() {
            for &col in cols {
                if let Some(slot) = of.get_mut(col as usize) {
                    *slot = c as i32;
                }
            }
        }
        let mut next = self.colors.len() as i32;
        for slot in of.iter_mut().filter(|s| **s < 0) {
            *slot = next;
            next += 1;
        }
        of
    }

    /// C keeps a pattern that is not `n × n`; no solver here could use one.
    fn is_square(&self, n: usize) -> bool {
        self.colptr.len() == n + 1 && self.rowidx.iter().all(|&r| (r as usize) < n)
    }
}

/// The two patterns C can carry, in the order `functionNonLinearResiduals` picks
/// them, minus what C's `sparsitySanityCheck` rejects.
fn nls_jac_pattern(jm: &SimCode::JacobianMatrix, n: usize) -> Option<NlsJacPattern> {
    let pat = nls_jac_pattern_raw(jm, n)?;
    (pat.passes_sanity_check(n) && pat.is_square(n)).then_some(pat)
}

/// The pattern as the backend emitted it, before C's sanity check.
fn nls_jac_pattern_raw(jm: &SimCode::JacobianMatrix, n: usize) -> Option<NlsJacPattern> {
    match &jm.sparsityMatrix {
        SimCode::Sparsity::SPARSITY { .. } => nls_jac_pattern_resizable(jm, n),
        _ => nls_jac_pattern_static(jm, n),
    }
}

/// C's `sparsitySanityCheck`; `size_cols` is what the pattern was built with,
/// which need not be `n`.
fn sparsity_sanity_check(colptr: &[i32], rowidx: &[i32], size_cols: usize, n: usize) -> bool {
    if n == 0 || rowidx.len() < n {
        return false;
    }
    if (1..size_cols.min(n)).any(|i| colptr[i] == colptr[i - 1]) {
        return false;
    }
    let mut seen = vec![false; n];
    for &r in &rowidx[..colptr[size_cols] as usize] {
        if let Some(s) = seen.get_mut(r as usize) {
            *s = true;
        }
    }
    seen.iter().all(|&s| s)
}

/// C's `generateStaticSparseData`: one `sparsity` entry per column holding its
/// nonzero rows, coloring precomputed in `coloredCols`.
fn nls_jac_pattern_static(jm: &SimCode::JacobianMatrix, n: usize) -> Option<NlsJacPattern> {
    let mut cols: Vec<Vec<i32>> =
        lst(&jm.sparsity).map(|(_, rows)| lst(rows).copied().collect()).collect();
    if cols.iter().flatten().any(|&r| r < 0) {
        return None;
    }
    let (colptr, rowidx) = csc_from_columns(&mut cols)?;
    // A coloring that is not a partition of the columns would drop or double-count
    // entries, so recompute instead of trusting it.
    let colors: Vec<Vec<u32>> =
        lst(&jm.coloredCols).map(|grp| lst(grp).map(|&c| c as u32).collect()).collect();
    let mut seen = vec![false; n];
    let partition = cols.len() == n
        && colors.iter().flatten().all(|&c| {
            (c as usize) < n && !core::mem::replace(&mut seen[c as usize], true)
        })
        && seen.iter().all(|&s| s);
    let colors = match (partition, rowidx.iter().all(|&r| (r as usize) < cols.len())) {
        (true, _) => colors,
        (false, true) => computed_coloring(&colptr, &rowidx, cols.len()),
        (false, false) => (0..cols.len() as u32).map(|c| vec![c]).collect(),
    };
    Some(NlsJacPattern { colptr, rowidx, colors })
}

/// C's `initialResizableAnalyticJacobian<M>`, with the equation iterators expanded
/// at build time. A regular whole-array dependency of a whole-array unknown pairs
/// element-wise (`resizableColCountRegular`); everything else is the cross product.
fn resizable_rows_by_col(jm: &SimCode::JacobianMatrix, n_cols: usize, n_rows: usize) -> Option<Vec<Vec<i32>>> {
    let SimCode::Sparsity::SPARSITY { rows } = &jm.sparsityMatrix else { return None };
    let slots = JacArraySlots::of(jm)?;
    let mut cols: Vec<Vec<i32>> = vec![Vec::new(); n_cols];
    let mut add = |r: usize, c: usize| {
        if r < n_rows && c < n_cols {
            cols[c].push(r as i32);
        }
    };
    for row in lst(rows) {
        let iters: Vec<&BackendDAE::SimIterator> = lst(&row.equation_iterators).collect();
        for (flat, bindings) in iterator_expansion(&iters).ok()?.into_iter().enumerate() {
            for sc in lst(&row.solved_crefs) {
                let sc = BoundCref::new(sc, &bindings)?;
                let sc_offs = match sc.whole_1d() && !bindings.is_empty() {
                    true => vec![slots.base(&sc.cref)? + flat],
                    false => slots.offsets(&sc)?,
                };
                for (seed, dep, rep) in lst(&row.dependencies) {
                    let seed = BoundCref::new(seed, &bindings)?;
                    let regular = !*rep && lst(&dep.kinds).next() == Some(&false) && seed.whole_1d() && sc.whole_1d();
                    if regular {
                        let (rb, cb) = (slots.base(&sc.cref)?, slots.base(&seed.cref)?);
                        match bindings.is_empty() {
                            true => (0..sc.first_dim()?).for_each(|k| add(rb + k, cb + k)),
                            false => add(rb + flat, cb + flat),
                        }
                        continue;
                    }
                    for c in slots.offsets(&seed)? {
                        for &r in &sc_offs {
                            add(r, c);
                        }
                    }
                }
            }
        }
    }
    Some(cols)
}

/// `SimVar.index` per array base (the C template's `crefsHT` after `crefStripSubs`).
struct JacArraySlots {
    base: HashMap<String, usize>,
}

impl JacArraySlots {
    fn of(jm: &SimCode::JacobianMatrix) -> Option<JacArraySlots> {
        let mut base = HashMap::new();
        for sv in lst(&jm.seedVars).cloned().chain(jac_listed_vars(jm)) {
            let Ok(index) = usize::try_from(sv.index) else { continue };
            let stripped = openmodelica_frontend_base::ComponentReference::crefStripSubs(sv.name.clone()).ok()?;
            base.entry(sim_cref_key(&stripped).ok()?).or_insert(index);
        }
        Some(JacArraySlots { base })
    }

    fn base(&self, cr: &Arc<DAE::ComponentRef>) -> Option<usize> {
        let stripped = openmodelica_frontend_base::ComponentReference::crefStripSubs(cr.clone()).ok()?;
        self.base.get(&sim_cref_key(&stripped).ok()?).copied()
    }

    fn offsets(&self, cr: &BoundCref) -> Option<Vec<usize>> {
        let base = self.base(&cr.cref)?;
        let mut offs = vec![0usize];
        for (dim, positions) in &cr.dims {
            let mut next = Vec::with_capacity(offs.len() * positions.len());
            for o in &offs {
                for p in positions {
                    next.push(o * dim + p);
                }
            }
            offs = next;
        }
        Some(offs.into_iter().map(|o| base + o).collect())
    }
}

/// A sparsity cref with its iterators bound: per dimension, size and selected
/// 0-based positions.
struct BoundCref {
    cref: Arc<DAE::ComponentRef>,
    dims: Vec<(usize, Vec<usize>)>,
    whole: Vec<bool>,
}

impl BoundCref {
    fn new(cr: &Arc<DAE::ComponentRef>, bindings: &[(String, Arc<DAE::Exp>)]) -> Option<BoundCref> {
        let mut dims = Vec::new();
        let mut whole = Vec::new();
        let mut part = cr;
        loop {
            let (ty, subs, next) = match &**part {
                DAE::ComponentRef::CREF_IDENT { identType, subscriptLst, .. } => (identType, subscriptLst, None),
                DAE::ComponentRef::CREF_QUAL { identType, subscriptLst, componentRef, .. } => {
                    (identType, subscriptLst, Some(componentRef))
                }
                _ => return None,
            };
            let part_dims = type_dims(ty)?;
            let subs: Vec<&Arc<DAE::Subscript>> = lst(subs).collect();
            if subs.len() > part_dims.len() {
                return None;
            }
            for (k, &dim) in part_dims.iter().enumerate() {
                let (positions, is_whole) = match subs.get(k).map(|s| &***s) {
                    None | Some(DAE::Subscript::WHOLEDIM) | Some(DAE::Subscript::WHOLE_NONEXP { .. }) => {
                        ((0..dim).collect(), true)
                    }
                    Some(DAE::Subscript::INDEX { exp }) => {
                        let v = bound_int(exp, bindings)?;
                        (usize::try_from(v - 1).ok().into_iter().collect(), false)
                    }
                    Some(DAE::Subscript::SLICE { exp }) => {
                        let vs = bound_ints(exp, bindings)?;
                        (vs.into_iter().filter_map(|v| usize::try_from(v - 1).ok()).collect(), false)
                    }
                };
                dims.push((dim, positions));
                whole.push(is_whole);
            }
            match next {
                Some(n) => part = n,
                None => break,
            }
        }
        Some(BoundCref { cref: cr.clone(), dims, whole })
    }

    /// C's `crefSubs(cr) == {WHOLEDIM()}`.
    fn whole_1d(&self) -> bool {
        self.dims.len() == 1 && self.whole[0]
    }

    fn first_dim(&self) -> Option<usize> {
        self.dims.first().map(|(d, _)| *d)
    }
}

fn type_dims(ty: &DAE::Type) -> Option<Vec<usize>> {
    let mut out = Vec::new();
    let mut ty = ty;
    while let DAE::Type::T_ARRAY { ty: inner, dims } = ty {
        for d in lst(dims) {
            match &**d {
                DAE::Dimension::DIM_INTEGER { integer } => out.push(usize::try_from(*integer).ok()?),
                _ => return None,
            }
        }
        ty = inner;
    }
    Some(out)
}

fn bound_int(exp: &Arc<DAE::Exp>, bindings: &[(String, Arc<DAE::Exp>)]) -> Option<i32> {
    const_int_exp(&*bound_exp(exp, bindings)?)
}

fn bound_ints(exp: &Arc<DAE::Exp>, bindings: &[(String, Arc<DAE::Exp>)]) -> Option<Vec<i32>> {
    match &*bound_exp(exp, bindings)? {
        DAE::Exp::ARRAY { array, .. } => lst(array).map(|e| const_int_exp(e)).collect(),
        DAE::Exp::RANGE { start, step, stop, .. } => {
            let (start, stop) = (const_int_exp(start)?, const_int_exp(stop)?);
            let step = match step {
                Some(s) => const_int_exp(s)?,
                None => 1,
            };
            if step == 0 {
                return None;
            }
            let mut out = Vec::new();
            let mut v = start;
            while (step > 0 && v <= stop) || (step < 0 && v >= stop) {
                out.push(v);
                v += step;
            }
            Some(out)
        }
        e => const_int_exp(e).map(|v| vec![v]),
    }
}

fn bound_exp(exp: &Arc<DAE::Exp>, bindings: &[(String, Arc<DAE::Exp>)]) -> Option<Arc<DAE::Exp>> {
    let mut e = exp.clone();
    for (name, value) in bindings {
        e = subst_iterator(&e, name, value).ok()?;
    }
    openmodelica_frontend_base::ExpressionSimplify::simplify1(e).ok().map(|(e, _)| e)
}

/// Every iterator combination, first iterator least significant (C's `forIteratorBody`).
fn iterator_expansion(iters: &[&BackendDAE::SimIterator]) -> Result<Vec<Vec<(String, Arc<DAE::Exp>)>>> {
    let mut out: Vec<Vec<(String, Arc<DAE::Exp>)>> = vec![Vec::new()];
    for iter in iters {
        let (name, values, sub_iters) = iterator_bindings(iter)?;
        let mut next = Vec::with_capacity(out.len() * values.len());
        for (pos, value) in values.iter().enumerate() {
            for prev in &out {
                let mut b = prev.clone();
                b.push((name.clone(), value.clone()));
                for (sub_name, table) in &sub_iters {
                    let v = table.get(pos).ok_or("CodegenWasmJit: dependent iterator range is too short")?;
                    b.push((sub_name.clone(), v.clone()));
                }
                next.push(b);
            }
        }
        out = next;
    }
    Ok(out)
}

/// Built at C's size (`numScalarElems(seedVars)` columns, rows unguarded) so the
/// sanity check sees what C's does.
fn nls_jac_pattern_resizable(jm: &SimCode::JacobianMatrix, _n: usize) -> Option<NlsJacPattern> {
    let n_cols = jac_seed_scalar_count(jm)?;
    let mut cols = resizable_rows_by_col(jm, n_cols, usize::MAX)?;
    let (colptr, rowidx) = csc_from_columns(&mut cols)?;
    let colors = match rowidx.iter().all(|&r| (r as usize) < n_cols) {
        true => computed_coloring(&colptr, &rowidx, n_cols),
        false => (0..n_cols as u32).map(|c| vec![c]).collect(),
    };
    Some(NlsJacPattern { colptr, rowidx, colors })
}

/// Per-column row lists → CSC, sorted and deduplicated. `None` for an all-zero
/// Jacobian.
fn csc_from_columns(cols: &mut [Vec<i32>]) -> Option<(Vec<i32>, Vec<i32>)> {
    let mut colptr = vec![0i32; cols.len() + 1];
    let mut rowidx: Vec<i32> = Vec::new();
    for (c, rows) in cols.iter_mut().enumerate() {
        rows.sort_unstable();
        rows.dedup();
        rowidx.extend_from_slice(rows);
        colptr[c + 1] = rowidx.len() as i32;
    }
    (!rowidx.is_empty()).then_some((colptr, rowidx))
}

/// C's `computeColumnColoring`: one column-equation pass per group of columns
/// sharing no row.
fn computed_coloring(colptr: &[i32], rowidx: &[i32], n: usize) -> Vec<Vec<u32>> {
    let (color_ptr, color_cols) =
        crate::CodegenWasmJitFunctions::lin_jac_coloring(colptr, rowidx, n);
    (0..color_ptr.len() - 1)
        .map(|c| {
            color_cols[color_ptr[c] as usize..color_ptr[c + 1] as usize].iter().map(|&j| j as u32).collect()
        })
        .collect()
}

/// The nonzero count of a nonlinear system's Jacobian, matching C's
/// `initializeNonlinearSystemData` (`sparsePattern->nnz`).
fn nls_system_nnz(nlsystem: &SimCode::NonlinearSystem) -> usize {
    let Some(jm) = nlsystem.jacobianMatrix.as_ref() else { return 0 };
    let n = lst(&nlsystem.crefs).count();
    nls_jac_pattern(jm, n).map_or(0, |p| p.rowidx.len())
}

/// Row coloring for the adjoint evaluation: rows seeded together share no column.
fn row_coloring(rows_by_col: &[Vec<u32>], n: usize) -> Vec<Vec<u32>> {
    let mut cols_by_row: Vec<Vec<i32>> = vec![Vec::new(); n];
    for (c, rows) in rows_by_col.iter().enumerate() {
        for &r in rows {
            cols_by_row[r as usize].push(c as i32);
        }
    }
    match csc_from_columns(&mut cols_by_row) {
        Some((colptr, rowidx)) => computed_coloring(&colptr, &rowidx, n),
        None => (0..n as u32).map(|r| vec![r]).collect(),
    }
}

/// The ODE state Jacobian "A", if the backend emitted one at all.
fn jac_a_matrix(sim_code: &SimCode::SimCode) -> Option<&SimCode::JacobianMatrix> {
    lst(&sim_code.jacobianMatrices).find(|j| &*j.matrixName == "A").map(|j| &**j)
}

fn build_jac_a_info(sim_code: &SimCode::SimCode, n_states: u32) -> Option<JacAInfo> {
    if n_states == 0 {
        return None;
    }
    let jac = jac_a_matrix(sim_code)?;
    let info = jac_pattern_info(jac, n_states as usize)?;
    if std::env::var("OMC_WASM_SIM_BENCH").is_ok() {
        let nnz: usize = info.rows_by_col.iter().map(|r| r.len()).sum();
        eprintln!("wasm-jit jac-A: n={n_states} colors={} nnz={nnz}", info.colors.len());
    }
    Some(info)
}

/// One Jacobian matrix's `n × n` sparsity + coloring, or `None` when the backend
/// left either out (or produced indices out of range), in which case the caller
/// falls back to a solver-internal numerical Jacobian.
fn jac_pattern_info(jac: &SimCode::JacobianMatrix, n: usize) -> Option<JacAInfo> {
    if n == 0 {
        return None;
    }
    let (rows_by_col, colors): (Vec<Vec<u32>>, Vec<Vec<u32>>) = match &jac.sparsityMatrix {
        SimCode::Sparsity::SPARSITY { .. } => {
            if jac_seed_scalar_count(jac)? != n {
                return None;
            }
            let mut cols = resizable_rows_by_col(jac, n, n)?;
            let (colptr, rowidx) = csc_from_columns(&mut cols)?;
            let colors = computed_coloring(&colptr, &rowidx, n);
            (cols.iter().map(|c| c.iter().map(|&r| r as u32).collect()).collect(), colors)
        }
        _ => {
            // sparsity: positional per column → 0-based nonzero rows (CSC), one entry per
            // column (empty columns carry an empty row list).
            let rows_by_col = lst(&jac.sparsity)
                .map(|(_, rows)| lst(rows).map(|r| *r as u32).collect())
                .collect();
            // coloredCols: each color → its 0-based column indices.
            let colors = lst(&jac.coloredCols)
                .map(|grp| lst(grp).map(|c| *c as u32).collect())
                .collect();
            (rows_by_col, colors)
        }
    };
    if rows_by_col.len() != n
        || colors.is_empty()
        || colors.iter().flatten().any(|&c| c as usize >= n)
        || rows_by_col.iter().flatten().any(|&r| r as usize >= n)
    {
        return None;
    }
    Some(JacAInfo { n: n as u32, colors, rows_by_col, sym: None })
}

/// Map each result variable's display name to its unit (`h` -> `m`, `der(h)` ->
/// the derivative var's unit), for a host to label plotted signals. Empty units
/// are skipped. Names match [`build_var_map`]'s result-variable names.
fn collect_var_units(vars: &SimCodeVar::SimVars) -> Result<HashMap<String, String>> {
    let mut units = HashMap::new();
    let mut add = |name: String, sv: &SimCodeVar::SimVar| {
        if !sv.unit.is_empty() {
            units.insert(name, sv.unit.to_string());
        }
    };
    for sv in lst(&vars.stateVars).chain(lst(&vars.derivativeVars)) {
        add(cref_display(&sv.name)?, sv);
    }
    for sv in lst(&vars.algVars)
        .chain(lst(&vars.discreteAlgVars))
        .chain(lst(&vars.paramVars))
        .chain(lst(&vars.intAlgVars))
        .chain(lst(&vars.intParamVars))
        .chain(lst(&vars.boolAlgVars))
        .chain(lst(&vars.boolParamVars))
    {
        add(cref_display(&sv.name)?, sv);
    }
    for av in lst(&vars.aliasVars).chain(lst(&vars.intAliasVars)).chain(lst(&vars.boolAliasVars)) {
        add(cref_display(&av.name)?, av);
    }
    Ok(units)
}

/// The `modelica.units` table: every unit the result variables name, with its SI
/// dimensions and the conversion to each display unit they name.
///
/// The SI dimensions come from `modelInfo.unitDefinitions`, which the FMI
/// exporter already builds; the display conversion comes from the unit database
/// itself (`SimCodeUtil.unitConversion`, which is `convertUnits`), because in
/// that list a display unit is a top-level unit and collides with a variable
/// declaring the same name as its own unit.
fn collect_unit_defs(mi: &SimCode::ModelInfo, result_vars: &[ResultVar]) -> Vec<UnitDef> {
    let base_of = |name: &str| {
        lst(&mi.unitDefinitions).find(|u| u.name.as_str() == name).and_then(|u| match u.baseUnit {
            SimCode::BASEUNIT { s, m, kg, A, K, mol, cd, factor, offset } => {
                Some(BaseUnit { exponents: [kg, m, s, A, K, mol, cd, 0], factor: factor.into_inner(), offset: offset.into_inner() })
            }
            SimCode::NOBASEUNIT => None,
        })
    };
    let mut units: Vec<UnitDef> = Vec::new();
    for v in result_vars.iter().filter(|v| !v.unit.is_empty()) {
        let at = match units.iter().position(|u| u.name == v.unit) {
            Some(i) => i,
            None => {
                units.push(UnitDef { name: v.unit.clone(), base: base_of(&v.unit), display_units: Vec::new() });
                units.len() - 1
            }
        };
        if v.display_unit.is_empty() || v.display_unit == v.unit || units[at].display_unit(&v.display_unit).is_some() {
            continue;
        }
        // v_display = factor * v_unit + offset, FMI's own <DisplayUnit>.
        let (converts, factor, offset) =
            openmodelica_backend::SimCodeUtil::unitConversion(ArcStr::from(v.display_unit.as_str()), ArcStr::from(v.unit.as_str()));
        if converts {
            units[at].display_units.push(DisplayUnit::new(&v.display_unit, factor.into_inner(), offset.into_inner()));
        }
    }
    units
}

/// Assemble the [`openmodelica_sim_meta::SimMeta`] embedded in the model module
/// (decoded by both the in-wasm driver and the standalone `_start`) from the
/// resolved layout, result variables, run settings and solver metadata. The
/// layout / result-var / solver types are shared with the driver, so this is a
/// direct copy — no conversion, hence no drift.
#[allow(clippy::too_many_arguments)]
fn build_sim_meta(
    layout: &SimLayout,
    result_vars: &[ResultVar],
    units: Vec<UnitDef>,
    settings: &SimCode::SimulationSettings,
    cs_method: &str,
    fmi_solver_flags: &str,
    model_name: &str,
    prefix: &str,
    jac_a: Option<JacAInfo>,
    state_sets: &[StateSetInfo],
    fmi_vrs: Vec<FmiVr>,
    fmi_dae_enable_vr: u32,
    zc_desc: Vec<String>,
    rel_desc: Vec<String>,
    params: openmodelica_sim_meta::ParamVars,
    attr_log: Vec<openmodelica_sim_meta::AttrLog>,
    removed_init_desc: Vec<String>,
    nls_warnings: Vec<String>,
    sample_index: Vec<i32>,
    soti: openmodelica_sim_meta::SotiVars,
    sens_params: Vec<u32>,
    nls_vars: Vec<openmodelica_sim_meta::NlsVars>,
    n_lin_systems: u32,
    dae: Option<openmodelica_sim_meta::DaeInfo>,
    clocks: Vec<BaseClockMeta>,
    lin: Option<openmodelica_sim_meta::LinInfo>,
    opt: Option<openmodelica_sim_meta::OptInfo>,
    inputs: Vec<openmodelica_sim_meta::InputVar>,
    recon: Option<openmodelica_sim_meta::ReconInfo>,
    prof: Option<openmodelica_sim_meta::ProfInfo>,
    parmod: Option<openmodelica_sim_meta::ParmodInfo>,
) -> openmodelica_sim_meta::SimMeta {
    openmodelica_sim_meta::SimMeta {
        layout: *layout,
        start_time: settings.startTime.into_inner(),
        stop_time: settings.stopTime.into_inner(),
        n_intervals: settings.numberOfIntervals.max(0) as u32,
        method: settings.method.to_string(),
        cs_method: cs_method.to_string(),
        fmi_solver_flags: fmi_solver_flags.to_string(),
        tolerance: settings.tolerance.into_inner(),
        output_format: settings.outputFormat.to_string(),
        prefix: prefix.to_string(),
        model_name: model_name.to_string(),
        vars: result_vars.to_vec(),
        units,
        jac_a,
        state_sets: state_sets.to_vec(),
        fmi_vrs,
        fmi_dae_enable_vr,
        zc_desc,
        rel_desc,
        params,
        attr_log,
        removed_init_desc,
        nls_warnings,
        sample_index,
        soti,
        sens_params,
        nls_vars,
        n_lin_systems,
        dae,
        clocks,
        lin,
        opt,
        inputs,
        recon,
        prof,
        parmod,
    }
}

/// The Modelica source of each zero-crossing relation (via
/// `ExpressionBasics::printExpStr`), so the driver can name the crossing that
/// triggered chattering. A math-event crossing has no relation string.
/// C's `modelData` variable arrays: the same lists, in the same order, as the
/// `SimData` variable regions.
fn soti_vars(vars: &SimCodeVar::SimVars) -> Result<openmodelica_sim_meta::SotiVars> {
    let named = |sv: &SimCodeVar::SimVar| cref_display(&sv.name);
    let mut reals = Vec::new();
    for sv in lst(&vars.stateVars).chain(lst(&vars.derivativeVars)).chain(real_alg_vars(vars)) {
        reals.push(named(sv)?);
    }
    let mut ints = Vec::new();
    for sv in lst(&vars.intAlgVars) {
        ints.push((named(sv)?, const_int(&sv.initialValue).unwrap_or(0)));
    }
    let mut bools = Vec::new();
    for sv in lst(&vars.boolAlgVars) {
        bools.push((named(sv)?, const_int(&sv.initialValue).unwrap_or(0)));
    }
    let mut strings = Vec::new();
    for sv in lst(&vars.stringAlgVars) {
        strings.push((named(sv)?, const_str(&sv.initialValue).unwrap_or_default()));
    }
    let n_discrete_real = lst(&vars.discreteAlgVars).count() as u32;
    Ok(openmodelica_sim_meta::SotiVars { reals, ints, bools, strings, n_discrete_real })
}

/// C's `modelData` parameter arrays: the same lists, in the same order, as the
/// `SimData` parameter regions.
fn param_vars(vars: &SimCodeVar::SimVars) -> Result<openmodelica_sim_meta::ParamVars> {
    let mut reals = Vec::new();
    for sv in lst(&vars.paramVars) {
        reals.push((cref_display(&sv.name)?.to_string(), const_real(&sv.initialValue).unwrap_or(0.0), sv.isFixed));
    }
    let mut ints = Vec::new();
    for sv in lst(&vars.intParamVars) {
        ints.push((cref_display(&sv.name)?.to_string(), const_int(&sv.initialValue).unwrap_or(0), sv.isFixed));
    }
    let mut bools = Vec::new();
    for sv in lst(&vars.boolParamVars) {
        bools.push((cref_display(&sv.name)?.to_string(), const_int(&sv.initialValue).unwrap_or(0), sv.isFixed));
    }
    let mut strings = Vec::new();
    for sv in lst(&vars.stringParamVars) {
        strings.push((cref_display(&sv.name)?.to_string(), const_str(&sv.initialValue).unwrap_or_default()));
    }
    Ok(openmodelica_sim_meta::ParamVars { reals, ints, bools, strings })
}

/// Name and attribute kind of every attribute-log slot.
fn attr_log_entries(sim_code: &SimCode::SimCode) -> Result<Vec<openmodelica_sim_meta::AttrLog>> {
    let mut out = Vec::new();
    for (attr, cref, _) in bound_attr_equations(sim_code) {
        let raw = cref_display(cref)?.to_string();
        let name = raw.strip_prefix("$START.").unwrap_or(&raw).to_string();
        let kind = match attr {
            Attr::Min => 0,
            Attr::Max => 1,
            Attr::Nominal => 2,
            Attr::Start => 3,
        };
        out.push(openmodelica_sim_meta::AttrLog { kind, name });
    }
    Ok(out)
}

fn const_real(e: &Option<Arc<DAE::Exp>>) -> Option<f64> {
    match e.as_deref()? {
        DAE::Exp::RCONST { real } => Some(real.into_inner()),
        DAE::Exp::ICONST { integer } => Some(*integer as f64),
        _ => None,
    }
}

fn const_int(e: &Option<Arc<DAE::Exp>>) -> Option<i32> {
    match e.as_deref()? {
        DAE::Exp::ICONST { integer } => Some(*integer),
        DAE::Exp::BCONST { bool } => Some(*bool as i32),
        DAE::Exp::ENUM_LITERAL { index, .. } => Some(*index),
        _ => None,
    }
}

fn const_str(e: &Option<Arc<DAE::Exp>>) -> Option<String> {
    match e.as_deref()? {
        DAE::Exp::SCONST { string } => Some(string.to_string()),
        _ => None,
    }
}

/// One description per relation, from the backend's list rather than from the
/// subset [`collect_relations`] can evaluate: `delayZeroCrossing` /
/// `spatialDistributionZeroCrossing` are stored as the bare call, which no target
/// assigns to `relations[]`, but C's `relationDescription` still names them.
fn rel_descriptions(
    rels: &Arc<List<openmodelica_backend_types::BackendDAE::ZeroCrossing>>,
) -> Vec<String> {
    lst(rels).map(|zc| dump_exp(&zc.relation_)).collect()
}

fn dump_exp(e: &Arc<DAE::Exp>) -> String {
    openmodelica_frontend_dump::ExpressionBasics::printExpStr(e.clone())
        .map(|s| s.to_string())
        .unwrap_or_default()
}

fn zc_descriptions(crossings: &[ZcInfo]) -> Vec<String> {
    crossings
        .iter()
        .map(|zc| match zc {
            ZcInfo::Bool { expr } => dump_exp(expr),
            ZcInfo::Math { expr, .. } => dump_exp(expr),
        })
        .collect()
}

/// A fresh `T_REAL` type for synthesizing the lhs `CREF` expression of a simple
/// assignment (the type is not consulted on the simulation cref path).
pub(crate) fn t_real() -> Arc<DAE::Type> {
    Arc::new(DAE::Type::T_REAL { varLst: metamodelica::nil() })
}

pub(crate) fn count<T: Clone>(list: &Arc<List<T>>) -> usize {
    lst(list).count()
}

/// The mangled name of an external object's destructor (`<class>.destructor`), for
/// looking up its compiled wasm function. `sv` must be an `extObjVars` entry
/// (`T_COMPLEX`/`EXTERNAL_OBJ`); mirrors `SimCodeFunctionUtil.addDestructor`.
fn extobj_destructor_key(sv: &SimCodeVar::SimVar) -> Result<String> {
    let path = match &*sv.type_ {
        DAE::Type::T_COMPLEX { complexClassType: openmodelica_frontend_types::ClassInf::State::EXTERNAL_OBJ { path }, .. } => path.clone(),
        _ => return Err("CodegenWasmJit: external object variable has a non-EXTERNAL_OBJ type"),
    };
    let dpath = openmodelica_frontend_dump::AbsynUtil::joinPaths(
        path,
        Arc::new(openmodelica_ast::Absyn::Path::IDENT { name: arcstr::literal!("destructor") }),
    )?;
    crate::CodegenWasmJitFunctions::mangle(&dpath)
}

/// Flatten a `list<SimEqSystem>` to a Vec of references.
fn flatten_eqs(eqs: &Arc<List<Arc<SimCode::SimEqSystem>>>) -> Vec<Arc<SimCode::SimEqSystem>> {
    lst(eqs).cloned().collect()
}

/// Flatten a `list<list<SimEqSystem>>` (partitioned equations) to a flat Vec.
fn flatten_eqs_ll(
    eqs: &Arc<List<Arc<List<Arc<SimCode::SimEqSystem>>>>>,
) -> Vec<Arc<SimCode::SimEqSystem>> {
    let mut out = Vec::new();
    for part in lst(eqs) {
        for e in lst(part) {
            out.push(e.clone());
        }
    }
    out
}

/// `+profiling`: the clock plan the instrumented code ticks and the report's
/// metadata. C reads both out of `_info.json` (`simulation_info_json.c`): every
/// equation in position order — which is index order — with a profile block for
/// each linear/nonlinear system under `blocks`, for every equation under `all`.
fn prof_plan(
    sim_code: &SimCode::SimCode,
    mi: &SimCode::ModelInfo,
) -> Result<(Option<Arc<ProfPlan>>, Option<openmodelica_sim_meta::ProfInfo>)> {
    use openmodelica_sim_meta::{ProfEq, ProfFn, ProfInfo, ProfVar, SrcInfo};
    use openmodelica_util::Config;
    // C's `measure_time_flag` initializer, in `CodegenC`'s order.
    let level: u8 = if Config::profileHtml()? {
        5
    } else if Config::profileSome()? {
        1
    } else if Config::profileAll()? {
        2
    } else {
        return Ok((None, None));
    };
    let src_info = |i: &metamodelica::SourceInfo| SrcInfo {
        file: i.fileName.to_string(),
        line_start: i.lineNumberStart,
        col_start: i.columnNumberStart,
        line_end: i.lineNumberEnd,
        col_end: i.columnNumberEnd,
        read_only: i.isReadOnly,
    };
    let mut fn_index = HashMap::new();
    let mut functions = Vec::new();
    for (i, f) in lst(&mi.functions).enumerate() {
        use SimCodeFunction::Function::Function as F;
        let (name, info) = match &**f {
            F::FUNCTION { name, info, .. }
            | F::PARALLEL_FUNCTION { name, info, .. }
            | F::KERNEL_FUNCTION { name, info, .. }
            | F::EXTERNAL_FUNCTION { name, info, .. }
            | F::RECORD_CONSTRUCTOR { name, info, .. } => (name, info),
        };
        fn_index.insert(crate::CodegenWasmJitFunctions::mangle(name)?, i as u32);
        functions.push(ProfFn {
            // `SerializeModelInfo.serializePath`, which drops the `FULLYQUALIFIED`
            // wrapper without a leading delimiter: `MeasureTime.A.f`, not `.MeasureTime.A.f`.
            name: openmodelica_frontend_dump::AbsynUtil::pathString(name.clone(), arcstr::literal!("."), false, false)?
                .to_string(),
            info: src_info(info),
        });
    }
    // C's `info.id` is the variable's `_init.xml` value reference: one counter from
    // 1000 over `SerializeInitXML.modelVariables`' lists, the alias and sensitivity
    // variables included. The report lists `modelData`'s arrays instead, so an id is
    // not a position in it.
    let mut vr_of: HashMap<String, u32> = HashMap::new();
    let mut vr = 1000u32;
    for list in [
        &mi.vars.stateVars, &mi.vars.derivativeVars, &mi.vars.algVars, &mi.vars.discreteAlgVars,
        &mi.vars.realOptimizeConstraintsVars, &mi.vars.realOptimizeFinalConstraintsVars,
        &mi.vars.paramVars, &mi.vars.aliasVars,
        &mi.vars.intAlgVars, &mi.vars.intParamVars, &mi.vars.intAliasVars,
        &mi.vars.boolAlgVars, &mi.vars.boolParamVars, &mi.vars.boolAliasVars,
        &mi.vars.stringAlgVars, &mi.vars.stringParamVars, &mi.vars.stringAliasVars,
        &mi.vars.sensitivityVars,
    ] {
        for sv in lst(list) {
            vr_of.entry(cref_display(&sv.name)?).or_insert(vr);
            vr += 1;
        }
    }
    // C's `modelData` variable arrays, in `printModelInfo` order.
    let mut vars = Vec::new();
    for list in [
        &mi.vars.stateVars, &mi.vars.derivativeVars, &mi.vars.algVars, &mi.vars.discreteAlgVars, &mi.vars.paramVars,
        &mi.vars.intAlgVars, &mi.vars.intParamVars, &mi.vars.boolAlgVars, &mi.vars.boolParamVars,
        &mi.vars.stringAlgVars, &mi.vars.stringParamVars,
    ] {
        for sv in lst(list) {
            let name = cref_display(&sv.name)?;
            vars.push(ProfVar {
                id: vr_of.get(&name).copied().unwrap_or(0),
                name,
                comment: sv.comment.to_string(),
                info: src_info(&sv.source.info),
            });
        }
    }
    // Every equation the `_info.json` lists, by index; a system's defines are its
    // unknowns, an assignment's its left-hand side.
    let mut table: HashMap<i32, (bool, Vec<String>)> = HashMap::new();
    let mut err = None;
    let mut note = |e: &Arc<SimCode::SimEqSystem>| {
        use SimCode::SimEqSystem as E;
        let entry = match &**e {
            E::SES_LINEAR { lSystem, .. } => {
                lst(&lSystem.vars).map(|v| cref_display(&v.name)).collect::<Result<Vec<_>>>().map(|d| (true, d))
            }
            E::SES_NONLINEAR { nlSystem, .. } => {
                lst(&nlSystem.crefs).map(cref_display).collect::<Result<Vec<_>>>().map(|d| (true, d))
            }
            E::SES_SIMPLE_ASSIGN { cref, .. } | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cref, .. } => {
                cref_display(cref).map(|d| (false, vec![d]))
            }
            E::SES_ARRAY_CALL_ASSIGN { lhs, .. } => match &**lhs {
                DAE::Exp::CREF { componentRef, .. } => cref_display(componentRef).map(|d| (false, vec![d])),
                _ => Ok((false, Vec::new())),
            },
            _ => Ok((false, Vec::new())),
        };
        match entry {
            Ok(v) => {
                table.insert(eq_index_of(e), v);
            }
            Err(x) => err = Some(x),
        }
    };
    for list in [
        &sim_code.initialEquations, &sim_code.initialEquations_lambda0, &sim_code.removedInitialEquations,
        &sim_code.allEquations, &sim_code.startValueEquations, &sim_code.nominalValueEquations,
        &sim_code.minValueEquations, &sim_code.maxValueEquations, &sim_code.parameterEquations,
        &sim_code.algorithmAndEquationAsserts, &sim_code.inlineEquations, &sim_code.jacobianEquations,
    ] {
        for e in lst(list) {
            visit_nested_eqs(e, &mut note);
        }
    }
    drop(note);
    if let Some(x) = err {
        return Err(x);
    }
    let n = table.keys().max().map_or(1, |m| (*m).max(0) + 1) as usize;
    let mut equations = Vec::with_capacity(n);
    let mut blocks = HashMap::new();
    // Under `all` C's block 0 exists but belongs to no equation.
    let all = level & 2 != 0;
    let mut block_eqs: Vec<u32> = if all { vec![0] } else { Vec::new() };
    for i in 0..n {
        let (system, defines) = table.get(&(i as i32)).cloned().unwrap_or_default();
        equations.push(ProfEq { id: i as u32, defines });
        // `readEquations`: a block for each system under `blocks`, for every
        // equation but the dummy under `all`.
        if i > 0 && (all || (level & 1 != 0 && system)) {
            blocks.insert(i as i32, block_eqs.len() as u32);
            block_eqs.push(i as u32);
        }
    }
    let plan = ProfPlan { level, n_functions: functions.len() as u32, n_blocks: block_eqs.len() as u32, fn_index, blocks };
    Ok((Some(Arc::new(plan)), Some(ProfInfo { level, functions, vars, equations, blocks: block_eqs })))
}

/// Visit `e` and every equation nested inside it, along the paths
/// [`lower_equation`] descends — the casual tearing set of a dynamically torn
/// system included.
fn visit_nested_eqs(e: &Arc<SimCode::SimEqSystem>, f: &mut dyn FnMut(&Arc<SimCode::SimEqSystem>)) {
    use SimCode::SimEqSystem as E;
    fn visit_list(
        eqs: &Arc<List<Arc<SimCode::SimEqSystem>>>,
        f: &mut dyn FnMut(&Arc<SimCode::SimEqSystem>),
    ) {
        for e in lst(eqs) {
            visit_nested_eqs(e, f);
        }
    }
    f(e);
    match &**e {
        E::SES_IFEQUATION { ifbranches, elsebranch, .. } => {
            for (_, branch) in lst(ifbranches) {
                visit_list(branch, f);
            }
            visit_list(elsebranch, f);
        }
        E::SES_ENTWINED_ASSIGN { single_calls, .. } => visit_list(single_calls, f),
        E::SES_MIXED { cont, discEqs, .. } => {
            visit_nested_eqs(cont, f);
            visit_list(discEqs, f);
        }
        E::SES_WHEN { elseWhen: Some(w), .. } => visit_nested_eqs(w, f),
        E::SES_FOR_EQUATION { body, .. } => visit_list(body, f),
        E::SES_LINEAR { lSystem, alternativeTearing, .. } => {
            for s in std::iter::once(lSystem).chain(alternativeTearing.iter()) {
                visit_list(&s.residual, f);
                for (_, _, inner) in lst(&s.simJac) {
                    visit_nested_eqs(inner, f);
                }
            }
        }
        E::SES_NONLINEAR { nlSystem, alternativeTearing, .. } => {
            for s in std::iter::once(nlSystem).chain(alternativeTearing.iter()) {
                visit_list(&s.eqs, f);
            }
        }
        _ => {}
    }
}

/// `eqs` with everything [`visit_nested_eqs`] reaches appended.
fn eqs_with_nested(eqs: &[Arc<SimCode::SimEqSystem>]) -> Vec<Arc<SimCode::SimEqSystem>> {
    let mut out = Vec::with_capacity(eqs.len());
    for e in eqs {
        visit_nested_eqs(e, &mut |i| out.push(i.clone()));
    }
    out
}

/// Build one equation function (`SimData* -> ()`), lowering each equation in
/// order. Unsupported equation kinds (systems, array assigns) fail loudly so a
/// model that needs them is rejected rather than silently mis-simulated.
/// Collect parameter binding assignments (`cref := initialValue`) from all
/// parameter `SimVar`s that have a binding, in declaration order.
fn collect_param_bindings(
    vars: &SimCodeVar::SimVars,
    computed: &std::collections::HashSet<String>,
) -> Vec<(Arc<DAE::ComponentRef>, Arc<DAE::Exp>)> {
    let mut out = Vec::new();
    for p in lst(&vars.paramVars)
        .chain(lst(&vars.intParamVars))
        .chain(lst(&vars.boolParamVars))
        .chain(lst(&vars.stringParamVars))
    {
        // A parameter an equation computes must not also be assigned from its binding
        // here: the prelude runs before both equation lists, so the binding would see
        // dependencies that are still 0 (or a null handle). A *constant* binding reads
        // nothing, so it is stored regardless — C's `setAllParamsToStart`.
        if let Some(v) = &p.initialValue {
            if !is_const_exp(v) && sim_cref_key(&p.name).map(|k| is_computed(&k, computed)).unwrap_or(false) {
                continue;
            }
            out.push((p.name.clone(), v.clone()));
        }
    }
    out
}

/// A literal the `_init.xml` would carry verbatim as a `start` attribute.
fn is_const_exp(e: &DAE::Exp) -> bool {
    matches!(
        e,
        DAE::Exp::ICONST { .. }
            | DAE::Exp::RCONST { .. }
            | DAE::Exp::BCONST { .. }
            | DAE::Exp::SCONST { .. }
            | DAE::Exp::ENUM_LITERAL { .. }
    )
}

/// Whether an equation list assigns `key`, directly or as one element of its array:
/// the `SimVar`s are scalarized (`ts[1]`, `layer[1][1][1][1]`), an array assign names
/// the whole `ts`. `sim_cref_key` spells one bracket pair per subscript, so strip
/// every rank, not just the last.
fn is_computed(key: &str, computed: &std::collections::HashSet<String>) -> bool {
    let mut key = key;
    loop {
        if computed.contains(key) {
            return true;
        }
        let Some(i) = key.strip_suffix(']').and_then(|k| k.rfind('[')) else { return false };
        key = &key[..i];
    }
}

/// Keys of the crefs a `SimEqSystem` list assigns, a system's iteration
/// variables included.
fn assigned_cref_keys(eqs: &[Arc<SimCode::SimEqSystem>]) -> std::collections::HashSet<String> {
    use SimCode::SimEqSystem as E;
    let mut set = std::collections::HashSet::new();
    let mut add = |cr: &DAE::ComponentRef| {
        if let Ok(k) = sim_cref_key(cr) {
            set.insert(k);
        }
    };
    for eq in eqs {
        match &**eq {
            E::SES_SIMPLE_ASSIGN { cref, .. }
            | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cref, .. }
            | E::SES_FOR_LOOP { cref, .. } => add(cref),
            E::SES_ARRAY_CALL_ASSIGN { lhs, .. } => {
                if let DAE::Exp::CREF { componentRef, .. } = &**lhs {
                    add(componentRef);
                }
            }
            E::SES_LINEAR { lSystem, alternativeTearing, .. } => {
                for s in std::iter::once(lSystem).chain(alternativeTearing.iter()) {
                    for v in lst(&s.vars) {
                        add(&v.name);
                    }
                }
            }
            E::SES_NONLINEAR { nlSystem, alternativeTearing, .. } => {
                for s in std::iter::once(nlSystem).chain(alternativeTearing.iter()) {
                    for c in lst(&s.crefs) {
                        add(c);
                    }
                }
            }
            E::SES_MIXED { discVars, .. } => {
                for v in lst(discVars) {
                    add(&v.name);
                }
            }
            E::SES_ALGORITHM { statements, .. } | E::SES_INVERSE_ALGORITHM { statements, .. } => {
                let defs = openmodelica_frontend_base::Expression::extractUniqueCrefsFromStatmentS(
                    statements.clone(),
                );
                if let Ok((defs, _)) = defs {
                    for c in lst(&defs) {
                        add(c);
                    }
                }
            }
            _ => {}
        }
    }
    set
}

/// The lowering context every generated `SimData*` function shares: local 0 is the
/// `SimData` pointer, and every slot comes from the one variable map.
pub(crate) fn sim_ctx(var_map: &SimVarMap) -> SimCtx {
    SimCtx {
        data_local: 0,
        vars: var_map.vars.clone(),
        starts: var_map.starts.clone(),
        start_slots: var_map.start_slots.clone(),
        array_groups: var_map.array_groups.clone(),
        scatter_groups: var_map.scatter_groups.clone(),
        consts: var_map.consts.clone(),
        const_groups: var_map.const_groups.clone(),
        terminate_off: var_map.terminate_off,
        terminal_off: var_map.terminal_off,
        initial_off: var_map.initial_off,
        term_info_off: var_map.term_info_off,
        nls_fail_off: var_map.nls_fail_off,
        nls_jobs: var_map.nls_jobs.clone(),
        generic_calls: var_map.generic_calls.clone(),
        n_samples: var_map.n_samples,
        sample_active_off: var_map.sample_active_off,
        relations_off: var_map.relations_off,
        rel_fresh_off: var_map.rel_fresh_off,
        stored_rel_off: var_map.stored_rel_off,
        relations_pre_off: var_map.relations_pre_off,
        n_relations: var_map.n_relations,
        mathevents_off: var_map.mathevents_off,
        n_mathevents: var_map.n_mathevents,
        lambda_off: var_map.lambda_off,
        homotopy_method: var_map.homotopy_method,
        old_real: var_map.old_real,
        zctol_off: var_map.zctol_off,
        zc_pre_off: var_map.zc_pre_off,
        zc_context: false,
        clock_fire_off: var_map.clock_fire_off,
        sub_clock_off: None,
        prof: var_map.prof.clone(),
    }
}

/// `daeModeData.daeEquations` flattened over its partitions, each equation paired with
/// the `EVAL_*` stage mask it runs in. Mirrors C's `equationNames_` for
/// `contextDAEmode`: an equation with no evaluation attributes inherits the preceding
/// one's mask (C leaves `evalStages` unassigned there), starting from every stage.
fn dae_residual_equations(dae: &SimCode::DaeModeData) -> Vec<(Arc<SimCode::SimEqSystem>, u32)> {
    use openmodelica_sim_meta::driver::eval_stage as stage;
    let all = stage::DYNAMIC | stage::ALGEBRAIC | stage::ZEROCROSS | stage::DISCRETE;
    let mut stages = all;
    let mut out = Vec::new();
    for part in lst(&dae.daeEquations) {
        for eq in lst(part) {
            let mut discrete = false;
            if let Some(attr) = eq_attr_of(eq) {
                let ev = &attr.evalStages;
                stages = (ev.dynamicEval as u32) * stage::DYNAMIC
                    | (ev.algebraicEval as u32) * stage::ALGEBRAIC
                    | (ev.zerocrossEval as u32) * stage::ZEROCROSS
                    | (ev.discreteEval as u32) * stage::DISCRETE;
                discrete = matches!(attr.kind, openmodelica_backend_types::BackendDAE::EquationKind::DISCRETE_EQUATION);
            }
            // A discrete-kind equation runs in the discrete stage only.
            let stages = if discrete { stages & stage::DISCRETE } else { stages };
            if stages != 0 {
                out.push((eq.clone(), stages));
            }
        }
    }
    out
}

/// `SimCodeUtil.eqInfo`.
fn eq_info(eq: &SimCode::SimEqSystem) -> Option<&metamodelica::SourceInfo> {
    use SimCode::SimEqSystem as E;
    match eq {
        E::SES_RESIDUAL { source, .. }
        | E::SES_FOR_RESIDUAL { source, .. }
        | E::SES_GENERIC_RESIDUAL { source, .. }
        | E::SES_SIMPLE_ASSIGN { source, .. }
        | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { source, .. }
        | E::SES_ARRAY_CALL_ASSIGN { source, .. }
        | E::SES_RESIZABLE_ASSIGN { source, .. }
        | E::SES_GENERIC_ASSIGN { source, .. }
        | E::SES_ENTWINED_ASSIGN { source, .. }
        | E::SES_IFEQUATION { source, .. }
        | E::SES_WHEN { source, .. }
        | E::SES_FOR_LOOP { source, .. }
        | E::SES_FOR_EQUATION { source, .. } => Some(&source.info),
        _ => None,
    }
}

/// The equation's `BackendDAE.EquationAttributes`, absent for the few systems that
/// carry none (`SES_ALIAS` and friends).
fn eq_attr_of(eq: &SimCode::SimEqSystem) -> Option<&openmodelica_backend_types::BackendDAE::EquationAttributes> {
    use SimCode::SimEqSystem as E;
    match eq {
        E::SES_RESIDUAL { eqAttr, .. }
        | E::SES_FOR_RESIDUAL { eqAttr, .. }
        | E::SES_GENERIC_RESIDUAL { eqAttr, .. }
        | E::SES_SIMPLE_ASSIGN { eqAttr, .. }
        | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { eqAttr, .. }
        | E::SES_ARRAY_CALL_ASSIGN { eqAttr, .. }
        | E::SES_RESIZABLE_ASSIGN { eqAttr, .. }
        | E::SES_GENERIC_ASSIGN { eqAttr, .. }
        | E::SES_ENTWINED_ASSIGN { eqAttr, .. }
        | E::SES_IFEQUATION { eqAttr, .. }
        | E::SES_ALGORITHM { eqAttr, .. }
        | E::SES_INVERSE_ALGORITHM { eqAttr, .. }
        | E::SES_LINEAR { eqAttr, .. }
        | E::SES_NONLINEAR { eqAttr, .. }
        | E::SES_MIXED { eqAttr, .. }
        | E::SES_WHEN { eqAttr, .. }
        | E::SES_FOR_LOOP { eqAttr, .. }
        | E::SES_FOR_EQUATION { eqAttr, .. }
        | E::SES_ALGEBRAIC_SYSTEM { eqAttr, .. } => Some(eqAttr),
        E::SES_ALIAS { .. } => None,
    }
}

/// Units of `evaluateDAEResiduals(SimData*, stage)`. C tests `evalStages &
/// currentEvalStage` against a per-equation assignment; here the mask is a
/// constant, so the guard is a single `and`/`if`.
fn dae_units(eqs: &[(Arc<SimCode::SimEqSystem>, u32)]) -> Vec<EqUnit<'_>> {
    eqs.iter().map(|(eq, stages)| EqUnit::Eq(eq, Some(*stages))).collect()
}

fn finish_fn(ctx: FnCtx) -> we::Function {
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    func
}

/// One lowering step of an equation entry point.
enum EqUnit<'a> {
    /// A parameter's binding expression, assigned ahead of `parameterEquations`.
    Binding(&'a Arc<DAE::ComponentRef>, &'a Arc<DAE::Exp>),
    /// A SimCode equation; `Some(mask)` adds the DAE-mode stage guard.
    Eq(&'a Arc<SimCode::SimEqSystem>, Option<u32>),
}

impl EqUnit<'_> {
    /// Operands of a plain `cref := exp`, which `sim_const_store` may fold into a
    /// data segment.
    fn assign_operands(&self) -> Option<(&Arc<DAE::ComponentRef>, &Arc<DAE::Exp>)> {
        match self {
            EqUnit::Binding(cref, exp) => Some((cref, exp)),
            EqUnit::Eq(eq, None) => match &***eq {
                SimCode::SimEqSystem::SES_SIMPLE_ASSIGN { cref, exp, .. } => Some((cref, exp)),
                _ => None,
            },
            EqUnit::Eq(_, Some(_)) => None,
        }
    }
}

/// Lower one unit. A constant store to a `SimData` slot reads nothing, so a
/// consecutive stretch of them may be merged: such a unit only joins `pending`
/// (by slot offset, last value winning), and anything else first flushes the
/// stretch as data segments through `emit_sim_const_stores`.
fn lower_unit(
    ctx: &mut FnCtx,
    unit: &EqUnit,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    pending: &mut BTreeMap<u32, Vec<u8>>,
) -> Result<()> {
    if let Some((cref, exp)) = unit.assign_operands() {
        if let Some((off, bytes)) = sim_const_store(ctx, cref, exp)? {
            pending.insert(off, bytes);
            return Ok(());
        }
    }
    emit_sim_const_stores(ctx, &core::mem::take(pending))?;
    match unit {
        EqUnit::Binding(cref, exp) => {
            let lhs = DAE::Exp::CREF { componentRef: (*cref).clone(), ty: t_real() };
            ctx.sim_assign(&lhs, exp)
        }
        EqUnit::Eq(eq, stages) => {
            if let Some(mask) = stages {
                ctx.sim_stage_guard(*mask);
            }
            lower_equation(ctx, eq, eq_index)?;
            if stages.is_some() {
                ctx.sim_end_block();
            }
            Ok(())
        }
    }
}

/// Instruction budget for one chunk of a split equation entry point, cut on emitted
/// size rather than equation count (one `SES_ALGORITHM` can outweigh a thousand
/// assignments). Emitting a whole list as one function makes Cranelift the dominant
/// cost of a wasm-jit build: its register allocation is superlinear in body size,
/// every declared local is zero-initialized at entry, and per-function parallel
/// compilation has nothing to spread. `OMC_WASM_CHUNK_INSTRS` overrides it; 0 never
/// splits.
fn chunk_instrs() -> usize {
    static N: OnceLock<usize> = OnceLock::new();
    *N.get_or_init(|| match std::env::var("OMC_WASM_CHUNK_INSTRS").ok().and_then(|v| v.parse().ok()) {
        Some(0) => usize::MAX,
        Some(n) => n,
        None => 4096,
    })
}

/// An equation entry point lowered into chunk functions. The entry points sit at
/// fixed function indices (`simulate` and the host driver call them by index), so
/// the chunks go after every fixed-index body and their indices are only known at
/// the end of module assembly: the entry point is reserved as a placeholder body
/// and filled in with [`SplitFn::thunk`] there.
struct SplitFn {
    /// Body-list slot reserved for the entry point.
    slot: usize,
    /// This entry point's chunks, by position in [`ChunkPool`]. Entry points that
    /// evaluate the same equations share them (see [`eq_segments`]).
    chunks: Vec<usize>,
    /// `(SimData*)`, plus DAE mode's `stage`.
    n_params: u32,
    /// Entry points called (with the same arguments) ahead of the chunks.
    pre_calls: Vec<u32>,
}

impl SplitFn {
    fn thunk(&self, chunk_base: u32) -> we::Function {
        use we::Instruction as I;
        let mut f = we::Function::new([]);
        let mut call = |f: &mut we::Function, idx: u32| {
            for p in 0..self.n_params {
                f.instruction(&I::LocalGet(p));
            }
            f.instruction(&I::Call(idx));
        };
        for c in &self.pre_calls {
            call(&mut f, *c);
        }
        for c in &self.chunks {
            call(&mut f, chunk_base + *c as u32);
        }
        f.instruction(&I::End);
        f
    }
}

/// The module's chunk functions, emitted after every fixed-index body. An entry
/// point names them by pool position, and several may name the same one.
#[derive(Default)]
struct ChunkPool {
    fns: Vec<we::Function>,
    /// Per chunk, for the function and name sections.
    meta: Vec<(u32, String)>,
}

impl ChunkPool {
    fn len(&self) -> usize {
        self.fns.len()
    }
    fn push(&mut self, f: we::Function, ty: u32, name: String) {
        self.fns.push(f);
        self.meta.push((ty, name));
    }
}

/// Lower `units` into chunk functions appended to `pool`, reserving a `bodies`
/// slot for the entry point that calls them. `stateset_diag` heads the first chunk
/// and `save_pre` tails the last; with no units at all they get a chunk to
/// themselves. Cuts only happen where no constant-store stretch is open, so
/// [`lower_unit`]'s merging never straddles a chunk boundary.
#[allow(clippy::too_many_arguments)]
fn build_split_fn(
    name: &'static str,
    units: &[EqUnit],
    n_params: u32,
    ty: u32,
    stateset_diag: &[u32],
    save_pre: &[(u32, u32, u32)],
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    bodies: &mut Vec<we::Function>,
    pool: &mut ChunkPool,
    per_unit: bool,
) -> Result<SplitFn> {
    let slot = bodies.len();
    bodies.push(empty_eqfn());
    let chunks = build_chunks(
        name, units, n_params, ty, stateset_diag, save_pre, var_map, eq_index, by_name, literals,
        pool, per_unit,
    )?;
    Ok(SplitFn { slot, chunks, n_params, pre_calls: Vec::new() })
}

/// [`build_split_fn`] without an entry point of its own.
#[allow(clippy::too_many_arguments)]
fn build_chunks(
    name: &str,
    units: &[EqUnit],
    n_params: u32,
    ty: u32,
    stateset_diag: &[u32],
    save_pre: &[(u32, u32, u32)],
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    pool: &mut ChunkPool,
    per_unit: bool,
) -> Result<Vec<usize>> {
    let first = pool.len();
    let mut i = 0usize;
    let _fg = crate::CodegenWasmJitFunctions::FnNameGuard::new(name);
    while i < units.len() || (pool.len() == first && !(stateset_diag.is_empty() && save_pre.is_empty()))
    {
        let mut ctx = FnCtx::new_sim_params(sim_ctx(var_map), by_name, &mut *literals, n_params);
        if pool.len() == first {
            ctx.emit_stateset_diag_init(stateset_diag)?;
        }
        let mut pending: BTreeMap<u32, Vec<u8>> = BTreeMap::new();
        while i < units.len() {
            // Cancellation poll, throttled: the equation functions are the bulk of
            // the emit for models with no user functions to poll between.
            if i & 63 == 0 {
                metamodelica::cancel::bail_if_cancelled()?;
            }
            lower_unit(&mut ctx, &units[i], eq_index, &mut pending)?;
            i += 1;
            if per_unit || (pending.is_empty() && ctx.instr_len() >= chunk_instrs()) {
                break;
            }
        }
        emit_sim_const_stores(&mut ctx, &pending)?;
        if i == units.len() {
            ctx.sim_save_pre_values(save_pre)?;
        }
        pool.push(finish_fn(ctx), ty, format!("{name}${}", pool.len() - first));
    }
    Ok((first..pool.len()).collect())
}

/// `Dae` is C's `allEquationsPlusWhen` surplus: the when-equations, which only
/// `functionDAE` runs.
#[derive(Clone, Copy, PartialEq)]
enum EqOwner {
    Ode,
    Alg,
    Dae,
}

/// A run of `allEquations` that is also a run of the `odeEquations` or
/// `algebraicEquations` list holding it, so its chunks serve both entry points, the
/// way C's `eqFunction_<n>` do.
struct EqSegment {
    owner: EqOwner,
    /// Where the run starts in its own list (0 for an [`EqOwner::Dae`] run).
    pos: usize,
    /// Where it sits in `allEquations`.
    span: core::ops::Range<usize>,
    chunks: Vec<usize>,
}

/// The equation's own index, including the forms [`eq_index_of`] leaves at -1.
fn eq_id_of(eq: &SimCode::SimEqSystem) -> i32 {
    use SimCode::SimEqSystem as E;
    match eq {
        E::SES_ALIAS { index, .. } | E::SES_FOR_EQUATION { index, .. } => *index,
        _ => eq_index_of(eq),
    }
}

/// Cut `all` (C's `allEquations`) into runs shared with `ode`/`alg`; `None` unless
/// the two tile what they claim of it, which leaves the caller lowering a copy of
/// its own.
///
/// The orders differ by more than the interleaving -- `algebraicEquations` ends with
/// C's `removedEquations` reversed -- so that tail comes back one equation per run.
fn eq_segments(
    ode: &[Arc<SimCode::SimEqSystem>],
    alg: &[Arc<SimCode::SimEqSystem>],
    all: &[Arc<SimCode::SimEqSystem>],
) -> Option<Vec<EqSegment>> {
    let mut own: HashMap<i32, (EqOwner, usize)> = HashMap::new();
    for (owner, eqs) in [(EqOwner::Ode, ode), (EqOwner::Alg, alg)] {
        for (pos, e) in eqs.iter().enumerate() {
            if own.insert(eq_id_of(e), (owner, pos)).is_some() {
                return None;
            }
        }
    }
    let mut segs: Vec<EqSegment> = Vec::new();
    for (i, e) in all.iter().enumerate() {
        let (owner, pos) = own.get(&eq_id_of(e)).copied().unwrap_or((EqOwner::Dae, 0));
        let joins = |s: &EqSegment| {
            s.owner == owner && (owner == EqOwner::Dae || s.pos + s.span.len() == pos)
        };
        match segs.last_mut() {
            Some(s) if joins(s) => s.span.end = i + 1,
            _ => segs.push(EqSegment { owner, pos, span: i..i + 1, chunks: Vec::new() }),
        }
    }
    // An entry point calls its own segments in its list's order, so they must tile it.
    for (owner, len) in [(EqOwner::Ode, ode.len()), (EqOwner::Alg, alg.len())] {
        let mut runs: Vec<(usize, usize)> =
            segs.iter().filter(|s| s.owner == owner).map(|s| (s.pos, s.span.len())).collect();
        runs.sort_unstable();
        let mut next = 0;
        for (pos, n) in runs {
            if pos != next {
                return None;
            }
            next += n;
        }
        if next != len {
            return None;
        }
    }
    Some(segs)
}

/// Lower the segments once; the three entry points' chunk lists come back, each
/// headed by `functionLocalKnownVars` as C's are.
#[allow(clippy::too_many_arguments)]
fn build_shared_eq_chunks(
    mut segs: Vec<EqSegment>,
    all: &[Arc<SimCode::SimEqSystem>],
    local_known: &[Arc<SimCode::SimEqSystem>],
    ty: u32,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    pool: &mut ChunkPool,
) -> Result<(Vec<usize>, Vec<usize>, Vec<usize>)> {
    let head = build_chunks(
        "functionLocalKnownVars", &eq_units(local_known), 1, ty, &[], &[], var_map, eq_index,
        by_name, literals, pool, false,
    )?;
    for seg in &mut segs {
        let name = format!("eqFunction_{}", eq_id_of(&all[seg.span.start]));
        seg.chunks = build_chunks(
            &name, &eq_units(&all[seg.span.clone()]), 1, ty, &[], &[], var_map, eq_index, by_name,
            literals, pool, false,
        )?;
    }
    let call = |segs: &[&EqSegment]| -> Vec<usize> {
        head.iter().copied().chain(segs.iter().flat_map(|s| s.chunks.iter().copied())).collect()
    };
    let own = |owner: EqOwner| -> Vec<&EqSegment> {
        let mut own: Vec<&EqSegment> = segs.iter().filter(|s| s.owner == owner).collect();
        own.sort_by_key(|s| s.pos);
        own
    };
    Ok((call(&own(EqOwner::Ode)), call(&own(EqOwner::Alg)), call(&segs.iter().collect::<Vec<_>>())))
}

/// Lower `units` into one function, for entry points whose size is bounded by the
/// model's structure rather than its equation count.
fn build_eq_fn_single(
    units: &[EqUnit],
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    let mut pending: BTreeMap<u32, Vec<u8>> = BTreeMap::new();
    for (i, unit) in units.iter().enumerate() {
        if i & 63 == 0 {
            metamodelica::cancel::bail_if_cancelled()?;
        }
        lower_unit(&mut ctx, unit, eq_index, &mut pending)?;
    }
    emit_sim_const_stores(&mut ctx, &pending)?;
    Ok(finish_fn(ctx))
}

/// `EqUnit::Eq` over a plain equation list.
fn eq_units(eqs: &[Arc<SimCode::SimEqSystem>]) -> Vec<EqUnit<'_>> {
    eqs.iter().map(|e| EqUnit::Eq(e, None)).collect()
}

/// Build the `initSample(SimData*)` function: evaluate each sample's
/// `start`/`interval` into the sample region (see [`FnCtx::emit_init_sample`]).
/// Called by the driver after `functionParameters`.
fn build_init_sample_fn(
    samples: &[SampleInfo],
    layout: &SimLayout,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let sim = sim_ctx(var_map);
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    let pairs: Vec<(Arc<DAE::Exp>, Arc<DAE::Exp>)> =
        samples.iter().map(|s| (s.start.clone(), s.interval.clone())).collect();
    ctx.emit_init_sample(&pairs, layout.sample_off)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// The initial equations the backend removed as redundant, kept as `0 = <exp>`
/// checks. A `SCONST` residual is C's `res = 0`, never inconsistent.
fn removed_init_residuals(sim_code: &SimCode::SimCode) -> Vec<&Arc<DAE::Exp>> {
    lst(&sim_code.removedInitialEquations)
        .filter_map(|eq| match &**eq {
            SimCode::SimEqSystem::SES_RESIDUAL { exp, .. } => Some(exp),
            _ => None,
        })
        .filter(|exp| !matches!(&***exp, DAE::Exp::SCONST { .. }))
        .collect()
}

/// Build `functionRemovedInitialEquations(SimData*)`. The first residual off zero
/// stops the function; a non-residual entry is an ordinary equation.
fn build_removed_init_eqs_fn(
    sim_code: &SimCode::SimCode,
    layout: &SimLayout,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    ctx.emit_removed_init_reset(layout.removed_init_idx_off)?;
    let mut pending: BTreeMap<u32, Vec<u8>> = BTreeMap::new();
    let mut index = 0u32;
    for eq in lst(&sim_code.removedInitialEquations) {
        match &**eq {
            SimCode::SimEqSystem::SES_RESIDUAL { exp, .. } => {
                if matches!(&**exp, DAE::Exp::SCONST { .. }) {
                    continue;
                }
                emit_sim_const_stores(&mut ctx, &core::mem::take(&mut pending))?;
                ctx.emit_removed_init_residual(
                    index,
                    exp,
                    layout.removed_init_res_off,
                    layout.removed_init_idx_off,
                )?;
                index += 1;
            }
            _ => lower_unit(&mut ctx, &EqUnit::Eq(eq, None), eq_index, &mut pending)?,
        }
    }
    emit_sim_const_stores(&mut ctx, &pending)?;
    Ok(finish_fn(ctx))
}

/// Build `functionInitSynchronous(SimData*)` — C's `function_initSynchronous`.
fn build_init_synchronous_fn(
    clocks: &[ClockInfo],
    layout: &SimLayout,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    let inits: Vec<ClockInit> = clocks
        .iter()
        .enumerate()
        .map(|(i, c)| ClockInit {
            off: layout.base_clock_off(i as u32),
            resolution: match &*c.kind {
                DAE::ClockKind::RATIONAL_CLOCK { resolution, .. } => Some(resolution.clone()),
                _ => None,
            },
            start_interval: match &*c.kind {
                DAE::ClockKind::EVENT_CLOCK { startInterval, .. } => Some(startInterval.clone()),
                _ => None,
            },
            sub_offs: (0..c.meta.sub.len() as u32)
                .map(|k| layout.sub_clock_off(c.meta.sub_base + k))
                .collect(),
        })
        .collect();
    ctx.emit_init_synchronous(&inits)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionUpdateSynchronous(SimData*, base_idx)` — C's
/// `function_updateSynchronous`, whose `switch` becomes one `if` per base clock.
fn build_update_synchronous_fn(
    clocks: &[ClockInfo],
    layout: &SimLayout,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim_params(sim_ctx(var_map), by_name, literals, 2);
    for (i, c) in clocks.iter().enumerate() {
        let update = match &*c.kind {
            DAE::ClockKind::RATIONAL_CLOCK { intervalCounter, .. } => ClockUpdate::Rational(intervalCounter.clone()),
            DAE::ClockKind::REAL_CLOCK { interval } => ClockUpdate::Real(interval.clone()),
            DAE::ClockKind::INFERRED_CLOCK => ClockUpdate::Inferred,
            DAE::ClockKind::EVENT_CLOCK { .. } | DAE::ClockKind::SOLVER_CLOCK { .. } => ClockUpdate::Nothing,
        };
        if matches!(update, ClockUpdate::Nothing) {
            continue;
        }
        ctx.sim_index_guard(i as u32);
        ctx.emit_update_synchronous(layout.base_clock_off(i as u32), &update)?;
        ctx.sim_end_block();
    }
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionEquationsSynchronous(SimData*, sub_idx)` — C's
/// `function_equationsSynchronous`, with the (base, sub) pair flattened to the
/// sub-clock's index in the `SimData` sub-clock region.
fn build_equations_synchronous_fn(
    clocks: &[ClockInfo],
    layout: &SimLayout,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim_params(sim_ctx(var_map), by_name, literals, 2);
    for c in clocks {
        for (k, eqs) in c.sub_eqs.iter().enumerate() {
            let flat = c.meta.sub_base + k as u32;
            ctx.sim_index_guard(flat);
            ctx.set_sub_clock(Some(layout.sub_clock_off(flat)));
            for eq in eqs {
                lower_equation(&mut ctx, eq, eq_index)?;
            }
            ctx.set_sub_clock(None);
            ctx.sim_end_block();
        }
    }
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionInitStartValues(SimData*)`: every real variable's `start`
/// attribute slot, in real-variable index order — the values C's `_init.xml`
/// carries. The driver copies the slots over the live region afterwards (C's
/// `setAllVarsToStart`), so `-iif`/`-override` land in between. Literals only, as
/// in C's `SerializeInitXML.expString`: evaluating a parameter-bound start here
/// would put it on the wrong side of the `pre`-value snapshot.
fn build_init_start_values_fn(
    reals: &[&SimCodeVar::SimVar],
    layout: &SimLayout,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    let starts: Vec<(f64, u32)> = reals
        .iter()
        .enumerate()
        .map(|(i, sv)| (literal_value(&sv.initialValue).unwrap_or(0.0), layout.real_start_off(i as u32)))
        .collect();
    ctx.emit_init_start_values(&starts)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// The attribute equations in C's `min`, `max`, `nominal`, `start` group order.
/// A start equation assigns `$START.<var>`, i.e. that variable's `start` attribute.
fn bound_attr_equations(
    sim_code: &SimCode::SimCode,
) -> Vec<(Attr, &Arc<DAE::ComponentRef>, &Arc<DAE::Exp>)> {
    let mut out = Vec::new();
    for (attr, eqs) in [
        (Attr::Min, &sim_code.minValueEquations),
        (Attr::Max, &sim_code.maxValueEquations),
        (Attr::Nominal, &sim_code.nominalValueEquations),
        (Attr::Start, &sim_code.startValueEquations),
    ] {
        for eq in lst(eqs) {
            if let SimCode::SimEqSystem::SES_SIMPLE_ASSIGN { cref, exp, .. } = &**eq {
                out.push((attr, cref, exp));
            }
        }
    }
    out
}

/// What C's `_init.xml` records for an attribute, i.e. what
/// `SerializeInitXML.expString` serializes: a literal, and nothing else.
fn literal_value(exp: &Option<Arc<DAE::Exp>>) -> Option<f64> {
    fn eval(e: &DAE::Exp) -> Option<f64> {
        use DAE::Exp as E;
        match e {
            E::ICONST { integer } => Some(*integer as f64),
            E::RCONST { real } => Some(real.into_inner()),
            E::BCONST { bool } => Some(*bool as u8 as f64),
            E::ENUM_LITERAL { index, .. } => Some(*index as f64),
            E::REDUCTION { expr, .. } => eval(expr),
            _ => None,
        }
    }
    exp.as_deref().and_then(eval)
}

/// Build `functionUpdateBoundVariableAttributes(SimData*)`. An attribute bound to a
/// parameter is not a constant, so the backend hands it over as an equation; only
/// here, after `functionParameters`, does it have a value. Every attribute is
/// evaluated (as C does) and left in the log region, whatever else it feeds.
fn build_update_bound_attrs_fn(
    sim_code: &SimCode::SimCode,
    layout: &SimLayout,
    defaults: &[(u32, f64)],
    int_defaults: &[(u32, i32)],
    attr_targets: &HashMap<String, AttrTargets>,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut attrs: Vec<(Attr, Arc<DAE::Exp>, AttrTargets, u32, Option<SimSlot>)> = Vec::new();
    for (i, (attr, cref, exp)) in bound_attr_equations(sim_code).into_iter().enumerate() {
        let key = sim_cref_key(cref).ok().map(|k| k.strip_prefix("$START.").unwrap_or(&k).to_string());
        let targets = key.as_deref().and_then(|k| attr_targets.get(k)).cloned().unwrap_or_default();
        let var = match attr {
            Attr::Start => key.as_deref().and_then(|k| var_map.vars.get(k)).copied(),
            _ => None,
        };
        attrs.push((attr, exp.clone(), targets, layout.attr_log_off + i as u32 * 8, var));
    }
    let sim = sim_ctx(var_map);
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_update_bound_attrs(defaults, int_defaults, &attrs)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionAttrDefaults(SimData*)`: the constant attribute defaults only, for
/// a solver built before initialization.
fn build_attr_defaults_fn(
    defaults: &[(u32, f64)],
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    ctx.emit_update_bound_attrs(defaults, &[], &[])?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionZeroCrossings(SimData*, gout)`: evaluate each crossing into
/// `gout` (see [`FnCtx::emit_zero_crossings`]).
fn build_zero_crossings_fn(
    crossings: &[ZcInfo],
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let sim = SimCtx { zc_context: true, ..sim_ctx(var_map) };
    let mut ctx = FnCtx::new_sim_params(sim, by_name, literals, 2);
    ctx.emit_zero_crossings(crossings, 1)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionUpdateRelations(SimData*)`: C's `function_updateRelations(data,
/// 0)`, the exact recomputation of every `relations[]` entry.
fn build_update_relations_fn(
    relations: &[Option<Arc<DAE::Exp>>],
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let sim = SimCtx { zc_context: true, ..sim_ctx(var_map) };
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_update_relations(relations, var_map.relations_off)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionStoreDelayed(SimData*)` (C's `function_storeDelayed`): append
/// each `delay(...)` expression's current value to its ring buffer.
fn build_store_delayed_fn(
    sim_code: &SimCode::SimCode,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let delayed: Vec<(i32, Arc<DAE::Exp>, Arc<DAE::Exp>, Arc<DAE::Exp>)> =
        lst(&sim_code.delayedExps.delayedExps)
            .map(|(i, (e, d, dmax))| (*i, e.clone(), d.clone(), dmax.clone()))
            .collect();
    let sim = sim_ctx(var_map);
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_store_delayed(&delayed)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionInitDelay(SimData*)`: `rt_delay_init(n_delays, time)`, called at
/// init with `time == startTime`.
fn build_init_delay_fn(n_delays: u32) -> we::Function {
    use we::Instruction as I;
    let mut f = we::Function::new([]);
    f.instruction(&I::I32Const(n_delays as i32));
    f.instruction(&I::LocalGet(0)); // SimData*
    f.instruction(&I::F64Load(crate::CodegenWasmJitFunctions::mem_arg(0, 3))); // time (TIME_OFF)
    f.instruction(&I::Call(rt_index("rt_delay_init").expect("rt_delay_init is a runtime builtin")));
    f.instruction(&I::End);
    f
}

/// The model's `spatialDistribution(...)` operators, lowest index first (the
/// backend collects them in reverse).
fn spatial_ops(sim_code: &SimCode::SimCode) -> Vec<SimCode::SpatialDistribution> {
    let mut ops: Vec<SimCode::SpatialDistribution> =
        lst(&sim_code.spatialInfo.spatialDistributions).cloned().collect();
    ops.sort_by_key(|sd| sd.index);
    ops
}

/// Build `functionStoreSpatialDistribution(SimData*)`; see [`FnCtx::emit_store_spatial`].
fn build_store_spatial_fn(
    sim_code: &SimCode::SimCode,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let sim = sim_ctx(var_map);
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_store_spatial(&spatial_ops(sim_code))?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build `functionInitSpatialDistribution(SimData*)`; see [`FnCtx::emit_init_spatial`].
fn build_init_spatial_fn(
    sim_code: &SimCode::SimCode,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let sim = sim_ctx(var_map);
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_init_spatial(var_map.n_spatial, &spatial_ops(sim_code))?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Lower a single `SimEqSystem` into the current equation function.
pub(crate) fn lower_equation(
    ctx: &mut FnCtx,
    eq: &SimCode::SimEqSystem,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    // C's `SIM_PROF_TICK_EQ` / `SIM_PROF_ACC_EQ` around a profiled block: every
    // equation under `all`, the linear and nonlinear systems under `blocks` — where
    // C's tick counts one call, its nonlinear block takes it back (the residual
    // calls count) and its linear one adds the setup call.
    let prof = ctx.sim.as_ref().and_then(|s| s.prof.clone());
    let clock = prof.as_ref().and_then(|p| p.block_clock(eq_index_of(eq)));
    if let Some(c) = clock {
        crate::CodegenWasmJitFunctions::emit_prof(ctx, clock, "rt_prof_tick")?;
        let all = prof.as_ref().is_some_and(|p| p.all());
        let ncall = match eq {
            SimCode::SimEqSystem::SES_NONLINEAR { .. } if !all => -1,
            SimCode::SimEqSystem::SES_LINEAR { .. } if !all => 1,
            _ => 0,
        };
        if ncall != 0 {
            ctx.emit(we::Instruction::I32Const(c as i32));
            ctx.emit(we::Instruction::I32Const(ncall));
            ctx.emit(we::Instruction::Call(rt_index("rt_prof_add_ncall")?));
        }
    }
    let _g = crate::CodegenWasmJitFunctions::PartGuard::new(format!("equation {}", eq_index_of(eq)));
    lower_equation_inner(ctx, eq, eq_index)?;
    crate::CodegenWasmJitFunctions::emit_prof(ctx, clock, "rt_prof_acc")
}

fn lower_equation_inner(
    ctx: &mut FnCtx,
    eq: &SimCode::SimEqSystem,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    use SimCode::SimEqSystem as E;
    if let Some(info) = eq_info(eq) {
        ctx.set_src_loc(info);
    }
    match eq {
        E::SES_SIMPLE_ASSIGN { cref, exp, .. } => {
            let lhs = DAE::Exp::CREF { componentRef: cref.clone(), ty: t_real() };
            ctx.sim_assign(&lhs, exp)
        }
        // Dynamic tearing: C's `createLocalConstraints` checks the `localCon`
        // constraints *before* the assignment, and only in the casual set's residual.
        E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cref, exp, cons, .. } => {
            if ctx.dt_local_cons() {
                for (c, local) in dt_constraints(cons) {
                    if local {
                        crate::CodegenWasmJitFunctions::emit_dt_local_constraint(ctx, &c)?;
                    }
                }
            }
            let lhs = DAE::Exp::CREF { componentRef: cref.clone(), ty: t_real() };
            ctx.sim_assign(&lhs, exp)
        }
        // A whole-array assignment `lhs := exp` (lhs is already a cref expression,
        // exp an array-valued expression). For a model array variable this routes
        // through the whole-array scatter in `compile_sim_cref_assign`.
        E::SES_ARRAY_CALL_ASSIGN { lhs, exp, .. } => ctx.sim_assign(lhs, exp),
        // C's `equationGenericAssign`.
        E::SES_RESIZABLE_ASSIGN { call_index, iters, .. } => {
            emit_resizable_assign(ctx, *call_index, iters)
        }
        E::SES_GENERIC_ASSIGN { call_index, scal_indices, .. } => {
            emit_generic_assign(ctx, *call_index, scal_indices)
        }
        E::SES_ENTWINED_ASSIGN { call_order, single_calls, .. } => {
            emit_entwined_assign(ctx, call_order, single_calls, eq_index)
        }
        E::SES_LINEAR { lSystem, alternativeTearing: Some(at), .. } => {
            lower_dynamic_tearing(ctx, eq_index, DtSystem::Linear(lSystem, at))
        }
        E::SES_NONLINEAR { nlSystem, alternativeTearing: Some(at), .. } => {
            lower_dynamic_tearing(ctx, eq_index, DtSystem::Nonlinear(nlSystem, at))
        }
        E::SES_LINEAR { lSystem, .. } => lower_linear_system(ctx, lSystem, eq_index, -1),
        E::SES_NONLINEAR { nlSystem, .. } => lower_nonlinear_system(ctx, nlSystem, eq_index),
        E::SES_ALGORITHM { statements, .. } => ctx.sim_stmts(statements),
        // Inside a nonlinear system the residual function backs the known outputs
        // up around the body; standalone this is C's `equationAlgorithm`.
        E::SES_INVERSE_ALGORITHM { statements, knownOutputCrefs, insideNonLinearSystem, .. } => {
            if *insideNonLinearSystem {
                return ctx.sim_stmts(statements);
            }
            let known: Vec<Arc<DAE::ComponentRef>> = lst(knownOutputCrefs).cloned().collect();
            let saved = backup_known_outputs(ctx, &known)?;
            ctx.sim_stmts(statements)?;
            restore_known_outputs(ctx, &known, &saved)
        }
        E::SES_WHEN { conditions, whenStmtLst, elseWhen, .. } => {
            ctx.sim_when(conditions, whenStmtLst, elseWhen)
        }
        // C's `equationIfEquationAssign`.
        E::SES_IFEQUATION { ifbranches, elsebranch, .. } => {
            let mut depth = 0;
            for (cond, eqs) in lst(ifbranches) {
                ctx.sim_if_cond(cond)?;
                for e in lst(eqs) {
                    lower_equation(ctx, e, eq_index)?;
                }
                ctx.sim_else();
                depth += 1;
            }
            for e in lst(elsebranch) {
                lower_equation(ctx, e, eq_index)?;
            }
            for _ in 0..depth {
                ctx.sim_end_block();
            }
            Ok(())
        }
        // An alias equation re-runs another equation (by index): inline it.
        E::SES_ALIAS { aliasOf, .. } => {
            let target = eq_index
                .get(aliasOf)
                .ok_or_else(|| "SES_ALIAS references unknown equation index")?
                .clone();
            lower_equation(ctx, &target, eq_index)
        }
        other => Err(eq_kind_name(other)),
    }
}

/// Dynamic tearing (`--dynamicTearing`): the two tearing sets of one torn strong
/// component. `Linear`/`Nonlinear` carry `(strict, casual)`, C's `lSystem`/`nlSystem`
/// and its `alternativeTearing`.
enum DtSystem<'a> {
    Linear(&'a Arc<SimCode::LinearSystem>, &'a Arc<SimCode::LinearSystem>),
    Nonlinear(&'a Arc<SimCode::NonlinearSystem>, &'a Arc<SimCode::NonlinearSystem>),
}

/// Every `CONSTRAINT_DT` of an equation's constraint list, as `(condition, local)`.
pub(crate) fn dt_constraints(cons: &Arc<List<Arc<DAE::Constraint>>>) -> Vec<(Arc<DAE::Exp>, bool)> {
    lst(cons)
        .filter_map(|c| match &**c {
            DAE::Constraint::CONSTRAINT_DT { constraint, localCon } => {
                Some((constraint.clone(), *localCon))
            }
            _ => None,
        })
        .collect()
}

/// Every constraint a casual tearing set's inner equations carry, in C's order
/// (`createGlobalConstraints` over `at.eqs` / `at.residual`).
fn dt_system_constraints(sys: &DtSystem) -> Vec<(Arc<DAE::Exp>, bool)> {
    use SimCode::SimEqSystem as E;
    let inner: Vec<Arc<SimCode::SimEqSystem>> = match sys {
        DtSystem::Linear(_, at) => lst(&at.residual).cloned().collect(),
        DtSystem::Nonlinear(_, at) => lst(&at.eqs).cloned().collect(),
    };
    let mut out = Vec::new();
    for e in &inner {
        if let E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cons, .. } = &**e {
            out.extend(dt_constraints(cons));
        }
    }
    out
}

/// Lower a dynamically torn strong component, C's `equation*AlternativeTearing`:
/// announce the casual set, check its constraints, solve it; a violated constraint
/// (or, for a linear system, a failed solve) falls through to the strict set. A
/// *nonlinear* casual set's failed solve is handled inside `rt_solve_nls`, where
/// C's `solveNLS` calls `strictTearingFunctionCall`.
fn lower_dynamic_tearing(
    ctx: &mut FnCtx,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    sys: DtSystem,
) -> Result<()> {
    let linear = matches!(sys, DtSystem::Linear(..));
    let (strict_index, casual_index) = match &sys {
        DtSystem::Linear(ls, at) => (ls.index, at.index),
        DtSystem::Nonlinear(nls, at) => (nls.index, at.index),
    };
    let cons = dt_system_constraints(&sys);
    let mut lower_casual = |c: &mut FnCtx| -> Result<()> {
        match &sys {
            DtSystem::Linear(_, at) => lower_linear_system(c, at, eq_index, strict_index),
            DtSystem::Nonlinear(_, at) => lower_nonlinear_system(c, at, eq_index),
        }
    };
    let mut lower_strict = |c: &mut FnCtx| -> Result<()> {
        match &sys {
            DtSystem::Linear(ls, _) => lower_linear_system(c, ls, eq_index, -1),
            DtSystem::Nonlinear(nls, _) => lower_nonlinear_system(c, nls, eq_index),
        }
    };
    crate::CodegenWasmJitFunctions::emit_dynamic_tearing(
        ctx, casual_index, strict_index, linear, &cons, &mut lower_casual, &mut lower_strict,
    )
}

/// Lower a `SES_LINEAR` system. Matching the C runtime, `A` is assembled
/// symbolically from `simJac` (`(row, col, SES_RESIDUAL(exp))`, 0-based,
/// column-major) and `b` from `beqs` — `setLinearMatrixA`/`setLinearVectorb` —
/// rather than by residual probing; [`compile_linear_system_symbolic`] then solves
/// dense or sparse per the density/size threshold. For a torn system the
/// `residual` list's non-`SES_RESIDUAL` entries are the inner equations that
/// recover the non-iteration torn variables, run once at the solution.
///
/// The residual-probing path ([`compile_linear_system`]) is the fallback for the
/// rare system without a usable `simJac`.
///
/// `dt_strict`: the strict set's equation index when `lsystem` is a casual tearing
/// set (whose `LOG_DT` line the caller has already printed, ahead of the constraint
/// check), or -1 for a system solved on its own.
fn lower_linear_system(
    ctx: &mut FnCtx,
    lsystem: &SimCode::LinearSystem,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    dt_strict: i32,
) -> Result<()> {
    // C's `equationLinear` line; the casual variant is printed at the call site.
    if dt_strict < 0 {
        crate::CodegenWasmJitFunctions::emit_dt_solving(ctx, lsystem.index, -1, true)?;
    }
    // Only the casual set itself hands a failed solve to the strict set; a system
    // nested in its inner equations reports its own, as C's own function does.
    let saved = ctx.dt_fallback();
    if dt_strict < 0 {
        ctx.set_dt_fallback(None);
    }
    // C measures `solve_linear_system` from before the `A`/`b` assembly, which here
    // is emitted code rather than a runtime call, so the bracket spans the system.
    let n = lst(&lsystem.vars).count() as i32;
    crate::CodegenWasmJitFunctions::emit_ls_bracket(ctx, lsystem.index, n, lin_system_nnz(lsystem) as i32, true)?;
    let r = lower_linear_system_body(ctx, lsystem, eq_index);
    ctx.set_dt_fallback(saved);
    r?;
    crate::CodegenWasmJitFunctions::emit_ls_bracket(ctx, lsystem.index, n, 0, false)
}

fn lower_linear_system_body(
    ctx: &mut FnCtx,
    lsystem: &SimCode::LinearSystem,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    use SimCode::SimEqSystem as E;
    let mut inner: Vec<Arc<SimCode::SimEqSystem>> = Vec::new();
    let residuals = lin_residuals(lsystem, &mut inner);
    let torn = !residuals.is_empty();
    let vars: Vec<Arc<DAE::ComponentRef>> = lst(&lsystem.vars).map(|v| v.name.clone()).collect();
    let n = vars.len();

    // A from simJac, b from beqs. `usable` false if any entry is not an ordinary
    // scalar residual (e.g. a for-residual we can't index statically).
    let mut a_entries: Vec<(usize, usize, &Arc<DAE::Exp>)> = Vec::new();
    let mut usable = true;
    for entry in lst(&lsystem.simJac) {
        let (row, col, eq) = entry;
        match &**eq {
            E::SES_RESIDUAL { exp, .. } => a_entries.push((*row as usize, *col as usize, exp)),
            _ => {
                usable = false;
                break;
            }
        }
    }
    let b_exps: Vec<&Arc<DAE::Exp>> = lst(&lsystem.beqs).collect();

    if usable && !a_entries.is_empty() && b_exps.len() == n {
        // Torn systems recover their inner variables at the solution; the non-torn
        // form has none (its `inner` is empty regardless).
        let mut lower_inner = |c: &mut FnCtx| -> Result<()> {
            if torn {
                for eq in &inner {
                    lower_equation(c, eq, eq_index)?;
                }
            }
            Ok(())
        };
        return compile_linear_system_symbolic(ctx, &vars, n, &a_entries, &b_exps, &mut lower_inner, lsystem.index);
    }

    // Only a torn system supplies the residuals both assembly paths need.
    if !torn {
        return Err("CodegenWasmJit: SES_LINEAR has neither a usable simJac nor residual equations");
    }
    let use_sparse = lin_torn_use_sparse(lsystem, n);
    let mut lower_inner = |c: &mut FnCtx| -> Result<()> {
        for eq in &inner {
            lower_equation(c, eq, eq_index)?;
        }
        Ok(())
    };

    // Prefer analytic-Jacobian assembly (C's method 1); probe only when there is no
    // usable Jacobian (its slots were registered by `build_lin_jac_infos`).
    if lin_jac_usable(lsystem, residual_rows(&residuals)) {
        let (seed_offs, result_offs) = {
            let vars = &ctx.sim()?.vars;
            lin_jac_offsets(lsystem, vars, n)?
        };
        let jm = lsystem.jacobianMatrix.as_ref().unwrap();
        let col = lst(&jm.columns).next().unwrap();
        let constant_eqns: Vec<Arc<SimCode::SimEqSystem>> = lst(&col.constantEqns).cloned().collect();
        let column_eqns: Vec<Arc<SimCode::SimEqSystem>> = lst(&col.columnEqns).cloned().collect();
        let mut lower_constant = |c: &mut FnCtx| -> Result<()> {
            for eq in &constant_eqns { lower_equation(c, eq, eq_index)?; }
            Ok(())
        };
        let mut lower_column = |c: &mut FnCtx| -> Result<()> {
            for eq in &column_eqns { lower_equation(c, eq, eq_index)?; }
            Ok(())
        };
        // Sparse: assemble straight into CSC (no dense n² buffer) when the pattern
        // remaps cleanly to res_index rows; otherwise dense A + runtime nonzero scan.
        if use_sparse {
            if let Some((colptr, rowidx)) = lin_jac_csc_pattern(lsystem, n) {
                return compile_linear_system_analytic_csc(
                    ctx, lsystem.index, &vars, &residuals, &seed_offs, &result_offs, &colptr, &rowidx,
                    &mut lower_inner, &mut lower_constant, &mut lower_column,
                );
            }
        }
        return compile_linear_system_analytic(
            ctx, &vars, &residuals, &seed_offs, &result_offs,
            &mut lower_inner, &mut lower_constant, &mut lower_column, use_sparse, lsystem.index,
        );
    }

    // C keys `method` off `ls.jacobianMatrix` alone, not off whether it assembles
    // `A` from one.
    compile_linear_system(ctx, &vars, &residuals, &mut lower_inner, use_sparse, lsystem.jacobianMatrix.is_some(), lsystem.index)
}

/// Whether a torn linear system uses the sparse solver (C's density/size
/// threshold), an unknown nonzero count counting as dense.
fn lin_torn_use_sparse(lsystem: &SimCode::LinearSystem, n: usize) -> bool {
    use crate::CodegenWasmJitFunctions::lin_use_sparse;
    if n == 0 {
        return false;
    }
    let nnz = lin_system_nnz(lsystem);
    nnz > 0 && lin_use_sparse(n, nnz)
}


/// Total f64 count of the state-set Jacobian scratch region: the seeds plus every
/// variable the column equations write.
fn stateset_scratch_f64(state_sets: &Arc<List<SimCode::StateSet>>) -> Result<u32> {
    let mut n = 0u32;
    for set in lst(state_sets) {
        n += count(&set.jacobianMatrix.seedVars) as u32 + jac_column_vars(&set.jacobianMatrix).len() as u32;
    }
    Ok(n)
}

/// Register each state set's Jacobian seed/column crefs at the scratch region and
/// collect the driver-side [`StateSetInfo`], so the emitted
/// `functionStateSetJacobians` works on the Jacobian's own storage.
fn build_state_set_infos(
    state_sets: &Arc<List<SimCode::StateSet>>,
    layout: &SimLayout,
    var_map: &mut SimVarMap,
) -> Result<Vec<StateSetInfo>> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let mut infos = Vec::new();
    let mut cursor = layout.stateset_off;
    let real_slot = |var_map: &SimVarMap, cr: &Arc<DAE::ComponentRef>| -> Result<u32> {
        let key = sim_cref_key(cr)?;
        let slot = var_map
            .vars
            .get(&key)
            .ok_or_else(|| "CodegenWasmJit: state-set variable has no slot")?;
        if slot.wty != WTy::F64 {
            return Err("CodegenWasmJit: state-set variable is not a Real variable");
        }
        Ok(slot.off)
    };
    for set in lst(state_sets) {
        let n_candidates = set.nCandidates.max(0) as u32;
        let n_states = set.nStates.max(0) as u32;
        let n_dummy = n_candidates - n_states;
        let jm = &set.jacobianMatrix;
        let register = |var_map: &mut SimVarMap, sv: &SimCodeVar::SimVar, cursor: &mut u32| -> Result<u32> {
            let off = *cursor;
            *cursor += 8;
            Arc::make_mut(&mut var_map.vars).insert(sim_cref_key(&sv.name)?, SimSlot { off, wty: WTy::F64, negate: Neg::None, heap: false });
            Ok(off)
        };

        // Seeds are listed in their own order; the driver wants Jacobian-column order.
        let listed: Vec<u32> = lst(&jm.seedVars)
            .map(|sv| register(var_map, &sv, &mut cursor))
            .collect::<Result<_>>()?;
        let seed_offs = jac_seed_offs_by_column(jm, &listed, n_candidates as usize)
            .ok_or("CodegenWasmJit: state-set Jacobian seed columns are not a permutation")?;

        let mut result_offs = vec![u32::MAX; n_dummy as usize];
        for sv in &jac_column_vars(jm) {
            let off = register(var_map, sv, &mut cursor)?;
            if matches!(sv.varKind, VarKind::JAC_VAR) {
                let row = jac_result_row(sv)
                    .filter(|&r| r < n_dummy as usize)
                    .ok_or("CodegenWasmJit: state-set Jacobian result var has no row index")?;
                result_offs[row] = off;
            }
        }
        if result_offs.contains(&u32::MAX) {
            return Err("CodegenWasmJit: state-set Jacobian has no result var for every row");
        }

        let candidate_offs: Vec<u32> = lst(&set.statescandidates)
            .map(|cr| real_slot(var_map, cr))
            .collect::<Result<_>>()?;
        let candidate_names: Vec<String> =
            lst(&set.statescandidates).map(|cr| cref_display(cr)).collect::<Result<_>>()?;
        let state_offs: Vec<u32> = lst(&set.states)
            .map(|cr| real_slot(var_map, cr))
            .collect::<Result<_>>()?;

        // `$STATESET.A` is an `nStates × nCandidates` integer selection matrix.
        // a_offs is row-major (the driver reads `a_offs[row*nc+col]`).
        let a_base_cref = openmodelica_frontend_dump::ComponentReferenceBasics::crefStripLastSubs(set.crA.clone())?;
        let a_base = sim_cref_key(&a_base_cref)?;
        let mut a_offs = Vec::new();
        for row in 1..=n_states {
            for c in 1..=n_candidates {
                let slot = stateset_a_slot(var_map, &a_base, row, c, n_candidates)
                    .ok_or_else(|| "CodegenWasmJit: state-set matrix entry has no slot")?;
                a_offs.push(slot.off);
            }
        }

        infos.push(StateSetInfo {
            n_candidates,
            n_states,
            n_dummy,
            candidate_offs,
            state_offs,
            a_offs,
            seed_offs,
            result_offs,
            candidate_names,
        });
    }
    Ok(infos)
}

/// Build `functionStateSetJacobians(SimData*)`: run every state set's Jacobian
/// `constantEqns` and `columnEqns` over the scratch slots. The driver seeds one
/// candidate at a time and reads back one Jacobian column
/// (`getAnalyticalJacobianSet` in C's `stateset.c`).
fn build_stateset_jac_fn(
    state_sets: &Arc<List<SimCode::StateSet>>,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let mut eqs: Vec<Arc<SimCode::SimEqSystem>> = Vec::new();
    for set in lst(state_sets) {
        for col in lst(&set.jacobianMatrix.columns) {
            eqs.extend(lst(&col.constantEqns).cloned());
            eqs.extend(lst(&col.columnEqns).cloned());
        }
    }
    build_eq_fn_single(&eq_units(&eqs), var_map, eq_index, by_name, literals)
}

/// Slot of the state-set selection-matrix entry `A[row,col]` (1-based). The backend
/// scalarizes `$STATESET{n}.A` either 2D (key `A[row][col]`) or flat row-major (key
/// `A[k]`, `k = (row-1)*nCandidates + col`); try the 2D key first, then the flat one.
fn stateset_a_slot<'a>(
    var_map: &'a SimVarMap,
    a_base: &str,
    row: u32,
    col: u32,
    n_candidates: u32,
) -> Option<&'a SimSlot> {
    var_map.vars.get(&format!("{a_base}[{row}][{col}]")).or_else(|| {
        let k = (row - 1) * n_candidates + col;
        var_map.vars.get(&format!("{a_base}[{k}]"))
    })
}

/// Byte offsets of the diagonal `$STATESET.A[n,n]` integer slots for every state
/// set, so [`FnCtx::emit_stateset_diag_init`] can seed an identity state
/// selection before initialisation (C's `initializeStateSetPivoting`). The A
/// matrix (`nStates × nCandidates`) is otherwise never assigned on this path — no
/// dynamic re-pivoting yet — so a fixed valid selection is what makes the
/// `set.x = A·candidates` systems solvable. `A[n,n]=1` (states = the first
/// `nStates` candidates) is a valid selection whenever those candidates stay
/// independent (true for the models in scope; a candidate going singular
/// mid-run would need the runtime `pivot`/`stateSelection` port).
fn stateset_diag_offsets(
    state_sets: &Arc<List<SimCode::StateSet>>,
    var_map: &SimVarMap,
) -> Result<Vec<u32>> {
    let mut offs = Vec::new();
    for set in lst(state_sets) {
        // `crA` names the first `A` element; strip its subscripts to the base `A`.
        let base_cref = openmodelica_frontend_dump::ComponentReferenceBasics::crefStripLastSubs(set.crA.clone())?;
        let base = sim_cref_key(&base_cref)?;
        let n_candidates = set.nCandidates.max(0) as u32;
        for n in 1..=set.nStates.max(0) as u32 {
            let slot = stateset_a_slot(var_map, &base, n, n, n_candidates)
                .ok_or_else(|| "CodegenWasmJit: state-set matrix entry has no slot")?;
            if slot.wty != WTy::I32 {
                return Err("CodegenWasmJit: state-set matrix entry is not an Integer variable");
            }
            offs.push(slot.off);
        }
    }
    Ok(offs)
}

/// Lower a `SES_NONLINEAR` (torn) system: emit the call to the runtime solver
/// `rt_solve_nls` for this system's pre-registered job. The Newton driver lives
/// in the runtime; the model contributes only the `residual`/`load` functions
/// (emitted by [`build_nls_fns`]) reached via `call_indirect`. The system's job
/// (shared-table slot + unknown count) was assigned in [`collect_nls_jobs`].
fn lower_nonlinear_system(
    ctx: &mut FnCtx,
    nlsystem: &SimCode::NonlinearSystem,
    _eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    let job = *ctx
        .sim()?
        .nls_jobs
        .get(&nlsystem.index)
        .ok_or_else(|| "CodegenWasmJit: SES_NONLINEAR was not registered for rt_solve_nls")?;
    emit_solve_nls_call(ctx, job)?;
    // The 0/1/2 return is dropped here — a failure surfaces through the `nls_fail`
    // flag, and only the strict-set function ([`emit_nls_strict_body`]) reads it.
    ctx.emit_drop();
    Ok(())
}

/// Partition a nonlinear system's equations into the inner (torn) constraint
/// equations and the `SES_RESIDUAL` residual expressions, and its iteration
/// unknowns. Shared by [`collect_nls_jobs`] (which counts unknowns) and
/// [`build_nls_fns`] (which emits the callbacks).
fn nls_parts(
    nlsystem: &SimCode::NonlinearSystem,
) -> Result<(Vec<Arc<SimCode::SimEqSystem>>, NlsResiduals, Vec<Arc<DAE::ComponentRef>>)> {
    use SimCode::SimEqSystem as E;
    let mut inner: Vec<Arc<SimCode::SimEqSystem>> = Vec::new();
    let mut residuals: Vec<NlsResidual> = Vec::new();
    for e in lst(&nlsystem.eqs) {
        match &**e {
            E::SES_RESIDUAL { exp, res_index, .. } => {
                residuals.push(match exp_array_rows(exp) {
                    Some(rows) => NlsResidual::Array { exp: exp.clone(), res_index: *res_index, rows },
                    None => NlsResidual::Scalar { exp: exp.clone(), res_index: *res_index },
                });
            }
            E::SES_FOR_RESIDUAL { iterators, exp, res_index, .. } => {
                residuals.push(NlsResidual::For {
                    iterators: lst(iterators).cloned().collect(),
                    exp: exp.clone(),
                    res_index: *res_index,
                });
            }
            E::SES_GENERIC_RESIDUAL { iterators, scal_indices, exp, res_index, .. } => {
                residuals.push(NlsResidual::Generic {
                    iterators: lst(iterators).cloned().collect(),
                    scal_indices: lst(scal_indices).copied().collect(),
                    exp: exp.clone(),
                    res_index: *res_index,
                });
            }
            _ => inner.push(e.clone()),
        }
    }
    let iter_vars: Vec<Arc<DAE::ComponentRef>> = lst(&nlsystem.crefs).cloned().collect();
    if residuals.is_empty() {
        // An inverse algorithm is the system's lone equation and its own residual.
        if let [e] = inner.as_slice() {
            if let E::SES_INVERSE_ALGORITHM { knownOutputCrefs, .. } = &**e {
                let known = lst(knownOutputCrefs).cloned().collect();
                return Ok((inner, NlsResiduals::InverseAlgorithm(known), iter_vars));
            }
        }
        // No unknowns either: the system is its inner equations, evaluated once.
        if iter_vars.is_empty() {
            return Ok((inner, NlsResiduals::Explicit(residuals), iter_vars));
        }
        return Err("CodegenWasmJit: SES_NONLINEAR has no residual equations");
    }
    // Only checkable when every residual's row count is static. An adaptive
    // approach appends `__HOM_LAMBDA` without a residual: the arc-length
    // condition closes it.
    let extra = usize::from(is_homotopy_lambda(iter_vars.last()));
    let rows = residuals.iter().try_fold(0usize, |acc, r| r.rows().map(|n| acc + n));
    if rows.is_some_and(|rows| iter_vars.len() != rows + extra) {
        return Err("CodegenWasmJit: SES_NONLINEAR unknown/residual count mismatch");
    }
    Ok((inner, NlsResiduals::Explicit(residuals), iter_vars))
}

/// The element count of an array-typed expression; `None` for a scalar.
fn exp_array_rows(exp: &Arc<DAE::Exp>) -> Option<usize> {
    let ty = openmodelica_frontend_base::Expression::r#typeof(exp.clone()).ok()?;
    let dims = type_dims(&ty)?;
    (!dims.is_empty()).then(|| dims.iter().product())
}

/// Dynamic tearing: each casual tearing set's equation index -> its strict set's.
fn nls_strict_map(eq_lists: &[&[Arc<SimCode::SimEqSystem>]]) -> HashMap<i32, i32> {
    use SimCode::SimEqSystem as E;
    let mut out = HashMap::new();
    for list in eq_lists {
        for e in *list {
            if let E::SES_NONLINEAR { nlSystem, alternativeTearing: Some(at), .. } = &**e {
                out.insert(at.index, nlSystem.index);
            }
        }
    }
    out
}

/// The `__HOM_LAMBDA` unknown `generateHomotopyComponents` appends under an
/// adaptive approach. C maps the cref to `simulationInfo->lambda`.
fn is_homotopy_lambda(cr: Option<&Arc<DAE::ComponentRef>>) -> bool {
    matches!(cr.map(|c| &**c),
        Some(DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. })
            if subscriptLst.is_empty()
                && ident.as_str() == openmodelica_backend_types::BackendDAE::homotopyLambda)
}

/// Scan the compiled equation lists for `SES_NONLINEAR` systems (deduplicated by
/// index, in first-seen order) and assign each an `rt_solve_nls` job. Returns the
/// ordered systems (for [`build_nls_fns`]) and the index -> job map, which is
/// threaded to the equation lowering via `SimVarMap`/`SimCtx`.
fn collect_nls_jobs(
    eq_lists: &[&[Arc<SimCode::SimEqSystem>]],
    nominal_of: &HashMap<String, (f64, f64, f64)>,
    attr_targets: &mut HashMap<String, AttrTargets>,
) -> (Vec<Arc<SimCode::NonlinearSystem>>, HashMap<i32, NlsJob>, u32, Vec<f64>, Vec<f64>, Vec<i32>, Vec<String>) {
    use SimCode::SimEqSystem as E;
    let mut systems: Vec<Arc<SimCode::NonlinearSystem>> = Vec::new();
    // Numbered and ordered by `indexNonLinearSystem`, as C's `sysNum` loop is.
    let mut warnings: Vec<(i32, String)> = Vec::new();
    let mut jobs: HashMap<i32, NlsJob> = HashMap::new();
    let mut hist_off = 0u32;
    let mut nominal_off = 0u32;
    let mut pat_off = 0u32;
    // Concatenated `colptr[n+1] | rowidx[nnz]` of every sparsely-solved system, in
    // system order; the module `start` writes them into the pattern block.
    let mut patterns: Vec<i32> = Vec::new();
    // Concatenated nominal values, in system order; the module `start` writes them
    // into the nominal block, and each job's `nominal_off` indexes into it.
    let mut nominals: Vec<f64> = Vec::new();
    // `min`/`max` pairs alongside them, in the same order.
    let mut bounds: Vec<f64> = Vec::new();
    for list in eq_lists {
        for e in *list {
            // A dynamically torn component registers both sets: the strict one (whose
            // function the casual set falls back to) and the casual one.
            let both: Vec<(&Arc<SimCode::NonlinearSystem>, bool)> = match &**e {
                E::SES_NONLINEAR { nlSystem, alternativeTearing: Some(at), .. } => {
                    vec![(nlSystem, false), (at, true)]
                }
                E::SES_NONLINEAR { nlSystem, .. } => vec![(nlSystem, false)],
                _ => Vec::new(),
            };
            for (nlSystem, casual) in both {
                if jobs.contains_key(&nlSystem.index) {
                    continue;
                }
                let n = lst(&nlSystem.crefs).count() as u32;
                let mut has_jac = nls_jac_usable(nlSystem);
                // C's `initializeNonlinearSystemData` shape check.
                if let Some((rows, cols)) = nls_jac_dims(nlSystem) {
                    let size = n as usize;
                    if rows != size - nls_lambda_extra(nlSystem) as usize || cols != size {
                        warnings.push((nlSystem.indexNonLinearSystem, format!(
                            "Analytic Jacobian of non-linear system {} is {rows}x{cols}, but the system \
                             has {size} iteration variables. This indicates that something went wrong \
                             during Jacobian generation. Using a numeric Jacobian instead.",
                            nlSystem.indexNonLinearSystem
                        )));
                        has_jac = false;
                    }
                }
                let mixed = nlSystem.mixedSystem;
                // The pattern goes in whenever it exists: C's density/size rule only
                // picks the *default* solver (kinsol+KLU vs the dense ladder), while
                // `-nls=kinsol` hands every patterned system to KINSOL.
                // C builds the pattern from the `JAC_MATRIX` alone — an empty column
                // list still carries one — then checks it.
                let raw_pat = nlSystem
                    .jacobianMatrix
                    .as_ref()
                    .and_then(|jm| nls_jac_pattern_raw(jm, n as usize));
                let pat = raw_pat.filter(|p| {
                    p.passes_sanity_check(n as usize) || {
                        warnings.push((nlSystem.indexNonLinearSystem, format!(
                            "Sparsity pattern for non-linear system {} is not regular. This indicates \
                             that something went wrong during sparsity pattern generation. Removing \
                             sparsity pattern and disabling NLS scaling.",
                            nlSystem.indexNonLinearSystem
                        )));
                        false
                    }
                });
                let pat = pat.filter(|p| p.is_square(n as usize));
                let nnz = pat.as_ref().map_or(0, |p| p.rowidx.len() as u32);
                let sparse_default = nnz != 0 && nls_use_sparse(n as usize, nnz as usize);
                if std::env::var("OMC_WASM_SIM_BENCH").is_ok() {
                    eprintln!(
                        "wasm-jit nls {}: n={n} nnz={} jac={has_jac} mixed={mixed} sparse={} colors={}",
                        nlSystem.index,
                        nls_system_nnz(nlSystem),
                        sparse_default,
                        pat.as_ref().map_or(0, |p| p.colors.len()),
                    );
                }
                if let Some(p) = &pat {
                    patterns.extend_from_slice(&p.colptr);
                    patterns.extend_from_slice(&p.rowidx);
                    patterns.extend_from_slice(&p.color_of_column(n as usize));
                }
                jobs.insert(nlSystem.index, NlsJob { k: systems.len() as u32, n, eq_index: nlSystem.index as u32, hist_off, nominal_off, has_jac, mixed, nnz, pat_off, sparse_default, homotopy_support: nlSystem.homotopySupport, casual });
                if nnz != 0 {
                    pat_off += 4 * (2 * n + 1 + nnz);
                }
                hist_off += crate::CodegenWasmJitFunctions::nls_hist_bytes(n);
                nominal_off += 8 * n;
                for cr in lst(&nlSystem.crefs) {
                    let key = sim_cref_key(cr).ok();
                    let (nom, lo, hi) = key
                        .as_ref()
                        .and_then(|k| nominal_of.get(k).copied())
                        .unwrap_or((1.0, -f64::MAX, f64::MAX));
                    if let Some(k) = key {
                        attr_targets.entry(k).or_default().nls.push(nominals.len() as u32);
                    }
                    nominals.push(nom);
                    bounds.push(lo);
                    bounds.push(hi);
                }
                systems.push(nlSystem.clone());
            }
        }
    }
    warnings.sort_by_key(|(k, _)| *k);
    (systems, jobs, hist_off, nominals, bounds, patterns, warnings.into_iter().map(|(_, w)| w).collect())
}

/// The optimizer's Jacobian entry points, in emission order: for B, C and D the
/// seed-independent equations and then one column. Matched by
/// `OptJac::{const_fn, column_fn}`.
pub(crate) const OPT_JAC_FNS: [&str; 6] = [
    "optJacB_const", "optJacB", "optJacC_const", "optJacC", "optJacD_const", "optJacD",
];

/// The real variables after the states and their derivatives, in C's
/// `realVars` order: the algebraics, then the discrete ones, then an
/// `optimization` model's path and final constraint variables (C's
/// `nVariablesReal` counts those last, which is what the optimizer's
/// `index_con = nReal - (nc + ncf)` relies on).
fn real_alg_vars(vars: &SimCodeVar::SimVars) -> Vec<&SimCodeVar::SimVar> {
    lst(&vars.algVars)
        .chain(lst(&vars.discreteAlgVars))
        .chain(lst(&vars.realOptimizeConstraintsVars))
        .chain(lst(&vars.realOptimizeFinalConstraintsVars))
        .collect()
}

/// Map each scalar real variable's cref key to its `(nominal, min, max)` attributes,
/// defaulting to `(1.0, -inf, +inf)` where unset or non-constant.
fn build_nls_nominal_map(vars: &SimCodeVar::SimVars) -> HashMap<String, (f64, f64, f64)> {
    let mut map = HashMap::new();
    // `derivativeVars`: a `$DER.x` iteration variable otherwise scales at nominal 1.
    let all = lst(&vars.stateVars)
        .chain(lst(&vars.derivativeVars))
        .chain(lst(&vars.algVars))
        .chain(lst(&vars.discreteAlgVars))
        .chain(lst(&vars.paramVars))
        .chain(lst(&vars.aliasVars));
    for sv in all {
        if let Ok(key) = sim_cref_key(&sv.name) {
            let nom = const_value(&sv.nominalValue).map(|v| v.abs()).filter(|v| *v > 0.0).unwrap_or(1.0);
            let lo = const_value(&sv.minValue).unwrap_or(-f64::MAX);
            let hi = const_value(&sv.maxValue).unwrap_or(f64::MAX);
            map.entry(key).or_insert((nom, lo, hi));
        }
    }
    map
}

/// Per-system scratch offsets for the analytic-Jacobian `nls_jac` callback: the
/// seed slots (one per differentiation column) and the column-result slots (one
/// per residual row). Both live in the `nls_jac_off` region, registered as var
/// slots so the Jacobian `columnEqns` resolve their `$SEED.*`/`$pDER.*` crefs.
struct NlsJacInfo {
    seed_offs: Vec<u32>,
    result_offs: Vec<u32>,
    /// This system's own seed/column slots. The new backend names every system's
    /// Jacobian variables after the *same* matrix (`$SEED_ALG_LS_JAC_1.u`,
    /// `$pDER_ALG_LS_JAC_1.$RES_SIM_0`, ...), so the shared cref map only keeps the
    /// last system that registered them; lowering a Jacobian body binds these back.
    slots: Vec<(String, SimSlot)>,
}

/// The residual row a Jacobian result var maps to: its `SimVar.index`, which is
/// what the C template indexes `jacobian->resultVars[]` with.
pub(crate) fn jac_result_row(sv: &SimCodeVar::SimVar) -> Option<usize> {
    usize::try_from(sv.index).ok()
}

/// Every variable a Jacobian's column equations can reference, other than the
/// seeds: the `$pDER` results and the temporaries. The old backend lists them in
/// `columnVars`; the new backend leaves that empty and registers them (together
/// with the seeds, which are filtered out here) in `crefsHT` only.
pub(crate) fn jac_column_vars(jm: &SimCode::JacobianMatrix) -> Vec<SimCodeVar::SimVar> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let mut seen: HashSet<String> = HashSet::new();
    let mut out: Vec<SimCodeVar::SimVar> = Vec::new();
    let mut push = |sv: &SimCodeVar::SimVar| {
        if matches!(sv.varKind, VarKind::SEED_VAR) {
            return;
        }
        if let Ok(key) = sim_cref_key(&sv.name) {
            if seen.insert(key) {
                out.push(sv.clone());
            }
        }
    };
    for sv in jac_listed_vars(jm) {
        push(&sv);
    }
    out
}

/// Every variable a Jacobian matrix lists, nothing dropped — what
/// [`jac_column_vars`] filters. One it cannot name (an array slice) gets no slot,
/// so [`jac_lowerable`] has to see it.
fn jac_listed_vars(jm: &SimCode::JacobianMatrix) -> Vec<SimCodeVar::SimVar> {
    let columns = lst(&jm.columns).next().into_iter().flat_map(|c| lst(&c.columnVars).cloned());
    let ht = jm
        .crefsHT
        .iter()
        .flat_map(|(_, (_, _, entries), _, _)| {
            entries.borrow().iter().flatten().map(|e| e.1.clone()).collect::<Vec<_>>()
        })
        .collect::<Vec<_>>();
    columns.chain(ht).collect()
}

/// A cref's name with its final subscripts dropped, spelled as [`array_element_of`]
/// spells an element's base.
fn cref_base_name(cr: &Arc<DAE::ComponentRef>) -> Option<String> {
    use DAE::ComponentRef as C;
    let mut base = String::new();
    let mut node: &Arc<DAE::ComponentRef> = cr;
    loop {
        match &**node {
            C::CREF_IDENT { ident, .. } => {
                base.push_str(ident);
                return Some(base);
            }
            C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
                base.push_str(ident);
                if !crate::CodegenWasmJitFunctions::push_qual_subs(subscriptLst, &mut base) {
                    return None;
                }
                base.push('.');
                node = componentRef;
            }
            _ => return None,
        }
    }
}

/// Whether a symbolic Jacobian can be lowered at all: every seed / column variable
/// resolves to a scratch slot, and every column equation is one [`lower_equation`]
/// handles and names nothing but those slots. An array-valued Jacobian needs the
/// run-time loops the C template emits, so it keeps the numerical Jacobian instead.
pub(crate) fn jac_lowerable(jm: &SimCode::JacobianMatrix) -> bool {
    let Some(col) = lst(&jm.columns).next() else { return false };
    let listed = jac_listed_vars(jm);
    if lst(&jm.seedVars).chain(listed.iter()).any(|sv| sim_cref_key(&sv.name).is_err()) {
        return false;
    }
    lst(&col.constantEqns).chain(lst(&col.columnEqns)).all(jac_eq_lowerable)
}

/// One column equation of a symbolic Jacobian, against what [`lower_equation`]
/// accepts: a differentiated algebraic loop is a `SES_LINEAR`, a differentiated
/// external or table call a `SES_ALGORITHM`.
fn jac_eq_lowerable(eq: &Arc<SimCode::SimEqSystem>) -> bool {
    use SimCode::SimEqSystem as E;
    match &**eq {
        // `lower_linear_system` needs either a usable `simJac` or the residuals of a
        // torn system; the inner equations run through `lower_equation` too.
        E::SES_LINEAR { lSystem, .. } => {
            let torn = lst(&lSystem.residual).any(|e| matches!(&**e, E::SES_RESIDUAL { .. }));
            let sim_jac = lst(&lSystem.simJac).next().is_some()
                && lst(&lSystem.simJac).all(|(_, _, e)| matches!(&**e, E::SES_RESIDUAL { .. }))
                && count(&lSystem.beqs) == count(&lSystem.vars);
            (torn || sim_jac)
                && lst(&lSystem.residual).all(jac_eq_lowerable)
                && lst(&lSystem.simJac).all(|(_, _, e)| jac_eq_lowerable(e))
                && lst(&lSystem.beqs)
                    .all(|e| openmodelica_frontend_base::Expression::extractCrefsFromExp(e.clone()).is_ok())
        }
        // The aliased equation is a model equation, which lowering handles anyway.
        E::SES_ALIAS { .. } => true,
        _ => jac_eq_crefs(eq).is_some(),
    }
}

/// Every cref a Jacobian column equation names, `None` for a kind
/// [`lower_equation`] does not handle at all.
fn jac_eq_crefs(eq: &SimCode::SimEqSystem) -> Option<Vec<Arc<DAE::ComponentRef>>> {
    use SimCode::SimEqSystem as E;
    use openmodelica_backend_types::BackendDAE::WhenOperator as W;
    let mut out = Vec::new();
    let exp = |e: &Arc<DAE::Exp>, out: &mut Vec<_>| -> bool {
        match openmodelica_frontend_base::Expression::extractCrefsFromExp(e.clone()) {
            Ok(crs) => {
                out.extend(lst(&crs).cloned());
                true
            }
            Err(_) => false,
        }
    };
    match eq {
        E::SES_SIMPLE_ASSIGN { cref, exp: rhs, .. } => {
            out.push(cref.clone());
            exp(rhs, &mut out).then_some(out)
        }
        E::SES_ARRAY_CALL_ASSIGN { lhs, exp: rhs, .. } => {
            (exp(lhs, &mut out) && exp(rhs, &mut out)).then_some(out)
        }
        E::SES_RESIDUAL { exp: e, .. } => exp(e, &mut out).then_some(out),
        E::SES_RESIZABLE_ASSIGN { .. } | E::SES_GENERIC_ASSIGN { .. } => Some(out),
        // `traverseDAEEquationsStmts` visits a statement's left-hand side too.
        E::SES_ALGORITHM { statements, .. } => {
            let alg = Arc::new(DAE::Algorithm { statementLst: statements.clone() });
            let exps = openmodelica_frontend_base::Algorithm::getAllExps(alg).ok()?;
            lst(&exps).all(|e| exp(e, &mut out)).then_some(out)
        }
        E::SES_WHEN { conditions, whenStmtLst, elseWhen, .. } => {
            out.extend(lst(conditions).cloned());
            for op in lst(whenStmtLst) {
                let ok = match op {
                    W::ASSIGN { left, right, .. } => exp(left, &mut out) && exp(right, &mut out),
                    W::REINIT { stateVar, value, .. } => {
                        out.push(stateVar.clone());
                        exp(value, &mut out)
                    }
                    W::ASSERT { condition, message, .. } => {
                        exp(condition, &mut out) && exp(message, &mut out)
                    }
                    W::TERMINATE { message, .. } => exp(message, &mut out),
                    W::NORETCALL { exp: e, .. } => exp(e, &mut out),
                };
                if !ok {
                    return None;
                }
            }
            match elseWhen {
                Some(ew) => {
                    out.extend(jac_eq_crefs(ew)?);
                    Some(out)
                }
                None => Some(out),
            }
        }
        _ => None,
    }
}

/// The residual rows of the Jacobian's `JAC_VAR` result variables, in
/// [`jac_column_vars`] order, iff they form a valid permutation of `0..n` (so the
/// Jacobian rows can be placed unambiguously); otherwise `None`.
fn nls_jac_result_rows(jm: &SimCode::JacobianMatrix, n: usize) -> Option<Vec<usize>> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let rows: Vec<usize> = jac_column_vars(jm)
        .iter()
        .filter(|v| matches!(v.varKind, VarKind::JAC_VAR))
        .map(jac_result_row)
        .collect::<Option<Vec<_>>>()?;
    let mut sorted = rows.clone();
    sorted.sort_unstable();
    if sorted.len() == n && sorted.iter().enumerate().all(|(i, &r)| i == r) {
        Some(rows)
    } else {
        None
    }
}

/// The seed slot offsets in *column* order (`SimVar.index`, what the C template
/// indexes `jacobian->seedVars[]` with), from the offsets registered for
/// `jm.seedVars`. `None` unless the indices are a permutation of `0..n`.
pub(crate) fn jac_seed_offs_by_column(jm: &SimCode::JacobianMatrix, offs: &[u32], n: usize) -> Option<Vec<u32>> {
    let mut by_col = vec![u32::MAX; n];
    for (sv, &off) in lst(&jm.seedVars).zip(offs) {
        let c = usize::try_from(sv.index).ok()?;
        if c >= n || by_col[c] != u32::MAX {
            return None;
        }
        by_col[c] = off;
    }
    by_col.iter().all(|&o| o != u32::MAX).then_some(by_col)
}

/// A nonlinear system has a usable symbolic Jacobian: a `jacobianMatrix` with one
/// seed per iteration variable and `JAC_VAR` results covering every residual row
/// (a square dense Jacobian, as `hybrj` needs).
fn nls_jac_usable(nlsystem: &SimCode::NonlinearSystem) -> bool {
    use SimCode::SimEqSystem as E;
    // For/generic-residual Jacobian columns are array-valued, which the flat
    // `emit_nls_jac_body` can't model; use the numerical Jacobian instead.
    if lst(&nlsystem.eqs).any(|e| matches!(&**e, E::SES_FOR_RESIDUAL { .. } | E::SES_GENERIC_RESIDUAL { .. })) {
        return false;
    }
    // `emit_nls_residual_body` writes `r[i]` for the i-th scalar residual while the
    // Jacobian rows are in `res_index` space (C's `res[res_index]`), so the two only
    // line up when the residuals are already in that order.
    if lst(&nlsystem.eqs)
        .filter_map(|e| match &**e {
            E::SES_RESIDUAL { res_index, .. } => Some(*res_index),
            _ => None,
        })
        .enumerate()
        .any(|(i, r)| r != i as i32)
    {
        return false;
    }
    let Some(jm) = &nlsystem.jacobianMatrix else { return false };
    if lst(&jm.columns).next().is_none_or(|c| lst(&c.columnEqns).next().is_none()) || !jac_lowerable(jm) {
        return false;
    }
    let n = lst(&nlsystem.crefs).count();
    let rows = n - nls_lambda_extra(nlsystem) as usize;
    n > 0 && count(&jm.seedVars) as usize == n && nls_jac_result_rows(jm, rows).is_some()
}

/// The `SimData` slot a torn system's iteration variable reads and writes. An
/// initialization system can solve for a start value, and C's `cref` makes
/// `$START.<var>` an lvalue into that variable's `attribute.start` — its start
/// slot here. `Ok(None)` leaves naming the system to the caller.
pub(crate) fn iteration_var_slot(
    vars: &HashMap<String, SimSlot>,
    start_slots: &HashMap<String, u32>,
    cr: &Arc<DAE::ComponentRef>,
) -> Result<Option<u32>> {
    let key = sim_cref_key(cr)?;
    if let Some(off) = key.strip_prefix("$START.").and_then(|k| start_slots.get(k)) {
        return Ok(Some(*off));
    }
    match vars.get(&key) {
        None => Ok(None),
        Some(slot) if slot.wty != WTy::F64 => {
            record_error(format!(
                "CodegenWasmJit: torn-system unknown `{key}` is not a Real variable"
            ));
            Err("CodegenWasmJit: torn-system unknown is not a Real variable")
        }
        Some(slot) => Ok(Some(slot.off)),
    }
}

/// 1 when the last unknown is `__HOM_LAMBDA`, which has no residual row: C's
/// `size` is then one more than the solver's `n`.
/// `(sizeRows, sizeCols)` of the Jacobian C's `initialAnalyticalJacobian` would
/// initialize; `None` when it returns none (no column equations or no pattern).
fn nls_jac_dims(nlsystem: &SimCode::NonlinearSystem) -> Option<(usize, usize)> {
    let jm = nlsystem.jacobianMatrix.as_ref()?;
    let col = lst(&jm.columns).next()?;
    let cols = match &jm.sparsityMatrix {
        SimCode::Sparsity::SPARSITY { .. } => jac_seed_scalar_count(jm)?,
        _ if lst(&jm.sparsity).next().is_none() => return None,
        _ => count(&jm.seedVars),
    };
    Some((usize::try_from(col.numberOfResultVars).ok()?, cols))
}

/// C's `getNumElems`.
fn sim_var_scalar_count(sv: &SimCodeVar::SimVar) -> Option<usize> {
    if !matches!(&*sv.type_, DAE::Type::T_ARRAY { .. }) {
        return Some(1);
    }
    lst(&sv.numArrayElement).map(|d| d.parse::<usize>().ok()).product()
}

/// C's `numScalarElems(seedVars)`.
fn jac_seed_scalar_count(jm: &SimCode::JacobianMatrix) -> Option<usize> {
    lst(&jm.seedVars).map(sim_var_scalar_count).sum()
}

fn nls_lambda_extra(nlsystem: &SimCode::NonlinearSystem) -> u32 {
    u32::from(is_homotopy_lambda(lst(&nlsystem.crefs).last()))
}

/// `nls_parts` for a linear system: the residuals, which may be array-valued and so
/// carry their `res_index`, and the inner (torn) equations, into `inner`.
fn lin_residuals(
    lsystem: &SimCode::LinearSystem,
    inner: &mut Vec<Arc<SimCode::SimEqSystem>>,
) -> Vec<NlsResidual> {
    use SimCode::SimEqSystem as E;
    let mut residuals = Vec::new();
    for e in lst(&lsystem.residual) {
        match &**e {
            E::SES_RESIDUAL { exp, res_index, .. } => residuals.push(match exp_array_rows(exp) {
                Some(rows) => NlsResidual::Array { exp: exp.clone(), res_index: *res_index, rows },
                None => NlsResidual::Scalar { exp: exp.clone(), res_index: *res_index },
            }),
            E::SES_FOR_RESIDUAL { iterators, exp, res_index, .. } => residuals.push(NlsResidual::For {
                iterators: lst(iterators).cloned().collect(),
                exp: exp.clone(),
                res_index: *res_index,
            }),
            E::SES_GENERIC_RESIDUAL { iterators, scal_indices, exp, res_index, .. } => {
                residuals.push(NlsResidual::Generic {
                    iterators: lst(iterators).cloned().collect(),
                    scal_indices: lst(scal_indices).copied().collect(),
                    exp: exp.clone(),
                    res_index: *res_index,
                })
            }
            _ => inner.push(e.clone()),
        }
    }
    residuals
}

/// Torn linear system usable for analytic assembly: square Jacobian with one seed
/// per iteration variable and `JAC_VAR` results covering every residual row
/// (`n_res` = the residual vector's row count). The `nls_jac_usable` analogue for
/// linear.
fn lin_jac_usable(lsystem: &SimCode::LinearSystem, n_res: Option<usize>) -> bool {
    let Some(n_res) = n_res else { return false };
    let Some(jm) = &lsystem.jacobianMatrix else { return false };
    if lst(&jm.columns).next().is_none_or(|c| lst(&c.columnEqns).next().is_none()) || !jac_lowerable(jm) {
        return false;
    }
    let n = count(&lsystem.vars) as usize;
    n > 0 && n == n_res && count(&jm.seedVars) as usize == n && nls_jac_result_rows(jm, n).is_some()
}

/// Total f64 scratch slots the NLS analytic Jacobians need: seeds + column
/// variables per usable system. Scans a superset of the systems
/// [`collect_nls_jobs`] registers, so the region is always large enough.
fn nls_jac_scratch_f64(sim_code: &SimCode::SimCode) -> u32 {
    use SimCode::SimEqSystem as E;
    let mut seen: HashSet<i32> = HashSet::new();
    let mut total = 0u32;
    let mut scan = |eqs: Vec<Arc<SimCode::SimEqSystem>>| {
        for e in &eqs_with_nested(&eqs) {
            if let E::SES_NONLINEAR { nlSystem, alternativeTearing, .. } = &**e {
                // A dynamically torn component has two sets, each with its own Jacobian.
                for sys in std::iter::once(nlSystem).chain(alternativeTearing.iter()) {
                    if seen.insert(sys.index) && nls_jac_usable(sys) {
                        // seeds + all column variables (results + intermediates) get slots.
                        let jm = sys.jacobianMatrix.as_ref().unwrap();
                        total += count(&jm.seedVars) as u32 + jac_column_vars(jm).len() as u32;
                    }
                }
            }
        }
    };
    scan(flatten_eqs(&sim_code.parameterEquations));
    scan(flatten_eqs(&sim_code.initialEquations));
    scan(flatten_eqs(&sim_code.initialEquations_lambda0));
    scan(flatten_eqs(&sim_code.removedInitialEquations));
    scan(flatten_eqs(&sim_code.algorithmAndEquationAsserts));
    scan(flatten_eqs(&sim_code.equationsForZeroCrossings));
    scan(flatten_eqs_ll(&sim_code.odeEquations));
    scan(flatten_eqs_ll(&sim_code.algebraicEquations));
    scan(flatten_eqs(&sim_code.allEquations));
    scan(flatten_eqs(&sim_code.inlineEquations));
    scan(clocked_eqs(sim_code));
    if let Some(d) = &sim_code.daeModeData {
        scan(flatten_eqs_ll(&d.daeEquations));
    }
    total
}

/// Every clocked sub-partition equation, flattened.
fn clocked_eqs(sim_code: &SimCode::SimCode) -> Vec<Arc<SimCode::SimEqSystem>> {
    let mut out = Vec::new();
    for part in lst(&sim_code.clockedPartitions) {
        for sp in lst(&part.subPartitions) {
            out.extend(lst(&sp.equations).chain(lst(&sp.removedEquations)).cloned());
        }
    }
    out
}

/// Register each system's Jacobian seed/result crefs at the `nls_jac_off` scratch
/// region (mirroring [`build_state_set_infos`]) and return the per-system offsets.
/// `nls_systems` is in [`collect_nls_jobs`] order, so offsets are assigned in the
/// same order the jobs were.
fn build_nls_jac_infos(
    nls_systems: &[Arc<SimCode::NonlinearSystem>],
    layout: &SimLayout,
    var_map: &mut SimVarMap,
) -> Result<HashMap<i32, NlsJacInfo>> {
    let mut infos = HashMap::new();
    let mut cursor = layout.nls_jac_off;
    for sys in nls_systems {
        if !nls_jac_usable(sys) {
            continue;
        }
        let jm = sys.jacobianMatrix.as_ref().unwrap();
        // A homotopy system's Jacobian is `n×(n+1)`: a `__HOM_LAMBDA` column, no row.
        let n_cols = count(&jm.seedVars);
        let n_rows = n_cols - nls_lambda_extra(sys) as usize;
        let (info, _, slots) = register_jac_slots(jm, n_rows, n_cols, &mut cursor, var_map)
            .map_err(|_| "CodegenWasmJit: nonlinear-system Jacobian seed columns are not a permutation")?;
        let result_offs: Vec<u32> = info
            .result_offs
            .iter()
            .map(|o| o.ok_or("CodegenWasmJit: nonlinear-system Jacobian is missing a residual row"))
            .collect::<Result<_>>()?;
        let seed_offs = info.seed_offs;
        infos.insert(sys.index, NlsJacInfo { seed_offs, result_offs, slots });
    }
    finalize_array_groups(var_map)?;
    Ok(infos)
}

/// The `-l` plan: the frames, and the symbolic `A`/`B`/`C`/`D` the flat emitter
/// can lower.
pub(crate) struct LinzPlan {
    frames: linearize::Frames,
    /// `[A, B, C, D]` dimensions.
    rows: [u32; 4],
    cols: [u32; 4],
    jacs: [Option<Arc<SimCode::JacobianMatrix>>; 4],
    /// A's adjoint (row) evaluator, when compiled bidirectionally.
    adj: Option<Arc<SimCode::JacobianMatrix>>,
    /// The shape each matrix really has (`symbolic_jacobians`), which differs from
    /// `rows`/`cols` when `DynamicOptimization` reshaped it for an `optimization`
    /// model. The slots and the results follow these.
    real_rows: [u32; 4],
    real_cols: [u32; 4],
}

impl LinzPlan {
    /// C's `initialAnalyticJacobian<X>` availability, as [`LinInfo::sym_mask`]: a
    /// matrix is the linearization's only if it fits the shape `-l` expects — one
    /// column per seed, and no more rows than the output region (a row the backend
    /// left out is structurally zero, which `emit_linz_jac_body` stores). An
    /// `optimization` model's reshaped B/C/D are lowered for the optimizer but left
    /// off the linearization's difference-quotient fallback.
    fn sym_mask(&self) -> u8 {
        (0..4)
            .filter(|&k| {
                self.jacs[k].is_some()
                    && self.real_rows[k] <= self.rows[k]
                    && self.real_cols[k] == self.cols[k]
            })
            .fold(0u8, |m, k| m | 1 << k)
    }

    /// Whether matrix `k` fills the linearization's output region.
    fn lin_ok(&self, k: usize) -> bool {
        self.sym_mask() & (1 << k) != 0
    }

    /// f64 slots the matrices occupy at the head of the region — all four at the
    /// linearization's shape, so an offset does not move with availability.
    fn n_matrix_f64(&self) -> u32 {
        (0..4).map(|k| self.rows[k] * self.cols[k]).sum()
    }

    /// Those plus every seed / column variable the available columns assign.
    fn n_scratch_f64(&self) -> u32 {
        if self.jacs.iter().all(Option::is_none) {
            return 0;
        }
        self.n_matrix_f64()
            + self
                .jacs
                .iter()
                .chain(core::iter::once(&self.adj))
                .flatten()
                .map(|jm| count(&jm.seedVars) as u32 + jac_column_vars(jm).len() as u32)
                .sum::<u32>()
    }
}

fn build_linz_plan(
    sim_code: &SimCode::SimCode,
    vars: &SimCodeVar::SimVars,
    n_states: u32,
) -> Result<LinzPlan> {
    let n_in = count(&vars.inputVars) as u32;
    let n_out = count(&vars.outputVars) as u32;
    let n_alg = count(&vars.algVars) as u32;
    let prefix = model_name_prefix(sim_code);
    let frames = linearize::build_frames(vars, n_states, n_in, n_out, n_alg, &prefix)?;
    let rows = [n_states, n_states, n_out, n_out];
    let cols = [n_states, n_in, n_states, n_in];
    let found = linearize::symbolic_jacobians(sim_code);
    let jacs = core::array::from_fn(|k| found[k].as_ref().map(|(jm, _, _)| jm.clone()));
    let real_rows = core::array::from_fn(|k| found[k].as_ref().map_or(0, |&(_, r, _)| r));
    let real_cols = core::array::from_fn(|k| found[k].as_ref().map_or(0, |&(_, _, c)| c));
    let adj = found[0].as_ref().filter(|(a, _, _)| a.isBidirectional).and_then(|(a, _, _)| {
        let jm = lst(&sim_code.jacobianMatrices).find(|j| j.matrixName == a.adjointMatrixName)?.clone();
        let has_equations = lst(&jm.columns).next().is_some_and(|c| lst(&c.columnEqns).next().is_some());
        (has_equations && jac_lowerable(&jm)).then_some(jm)
    });
    Ok(LinzPlan { frames, rows, cols, jacs, adj, real_rows, real_cols })
}

/// C's `modelNamePrefix`: the linearization frames quote it as the model's
/// description, and it is the FMU's modelIdentifier.
fn model_name_prefix(sim_code: &SimCode::SimCode) -> String {
    openmodelica_util::System::makeC89Identifier(sim_code.fileNamePrefix.clone()).to_string()
}

/// Register the Jacobians' seed / column-variable crefs behind the matrices, and
/// return each matrix's seed and result slots.
fn build_linz_jac_infos(
    plan: &LinzPlan,
    layout: &SimLayout,
    var_map: &mut SimVarMap,
) -> Result<(Vec<Option<LinzJacInfo>>, Option<AdjJacInfo>)> {
    let mut cursor = layout.linz_off + plan.n_matrix_f64() * 8;
    let mut infos = Vec::with_capacity(4);
    for (k, jm) in plan.jacs.iter().enumerate() {
        let Some(jm) = jm else {
            infos.push(None);
            continue;
        };
        // `emit_linz_jac_body` stores a slot or a structural zero for every row of
        // the output region, so cover both shapes.
        let rows = plan.real_rows[k].max(plan.rows[k]) as usize;
        let cols = plan.real_cols[k] as usize;
        let (info, _, _) = register_jac_slots(jm, rows, cols, &mut cursor, var_map)?;
        infos.push(Some(info));
    }
    // The new backend's column code reads seed/result arrays whole.
    finalize_array_groups(var_map)?;
    // The adjoint names its temporaries as A does; C keeps `tmpVars` per matrix.
    let adj = match &plan.adj {
        Some(jm) => {
            let n = plan.real_rows[0] as usize;
            let mut map = var_map.clone();
            let (info, zero_offs, _) = register_jac_slots(jm, n, n, &mut cursor, &mut map)?;
            finalize_array_groups(&mut map)?;
            Some(AdjJacInfo { info, zero_offs, map })
        }
        None => None,
    };
    Ok((infos, adj))
}

struct AdjJacInfo {
    info: LinzJacInfo,
    zero_offs: Vec<u32>,
    map: SimVarMap,
}

/// A scratch slot per seed and column variable from `cursor` on; also returns the
/// non-seed slots.
fn register_jac_slots(
    jm: &SimCode::JacobianMatrix,
    rows: usize,
    cols: usize,
    cursor: &mut u32,
    var_map: &mut SimVarMap,
) -> Result<(LinzJacInfo, Vec<u32>, Vec<(String, SimSlot)>)> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let column_vars = jac_column_vars(jm);
    // The pairs this matrix registered. Two matrices can name their variables alike
    // (the new backend names every system's after the same one), and then the shared
    // map only keeps the last; lowering a body binds these back over it.
    let mut registered: Vec<(String, SimSlot)> = Vec::new();
    // The new backend lists an array's base beside its elements.
    let mut bases: HashSet<String> = HashSet::new();
    for sv in lst(&jm.seedVars).chain(column_vars.iter()) {
        if let Some((base, _)) = array_element_of(&sv.name)? {
            bases.insert(base);
        }
    }
    let mut insert = |sv: &SimCodeVar::SimVar, var_map: &mut SimVarMap, cursor: &mut u32| -> Result<Option<u32>> {
        let key = sim_cref_key(&sv.name)?;
        if bases.contains(&key) {
            return Ok(None);
        }
        let off = *cursor;
        let slot = SimSlot { off, wty: WTy::F64, negate: Neg::None, heap: false };
        registered.push((key.clone(), slot));
        Arc::make_mut(&mut var_map.vars).insert(key, slot);
        for g in array_element_keys(&sv.name)? {
            var_map.array_acc.entry(g.base).or_default().push(AccElem {
                subs: g.subs,
                pieces: g.pieces,
                off,
                wty: WTy::F64,
                neg: Neg::None,
                heap: false,
            });
        }
        *cursor += 8;
        Ok(Some(off))
    };
    let mut listed = Vec::new();
    for sv in lst(&jm.seedVars) {
        listed.push(insert(sv, var_map, cursor)?.ok_or("CodegenWasmJit: a Jacobian seed is an array base")?);
    }
    let mut result_offs = vec![None; rows];
    let mut others = Vec::new();
    for sv in &column_vars {
        let Some(off) = insert(sv, var_map, cursor)? else { continue };
        others.push(off);
        if matches!(sv.varKind, VarKind::JAC_VAR)
            && let Some(row) = jac_result_row(sv).filter(|&r| r < rows)
        {
            result_offs[row] = Some(off);
        }
    }
    let seed_offs = jac_seed_offs_by_column(jm, &listed, cols)
        .ok_or("CodegenWasmJit: linearization Jacobian seed columns are not a permutation")?;
    Ok((LinzJacInfo { seed_offs, result_offs }, others, registered))
}

/// One matrix's seed slots (column order) and result slots (row order; `None` is
/// a structural zero).
struct LinzJacInfo {
    seed_offs: Vec<u32>,
    result_offs: Vec<Option<u32>>,
}

/// The runtime half of the plan, once the variable map exists.
fn build_lin_info(
    plan: &LinzPlan,
    vars: &SimCodeVar::SimVars,
    var_map: &SimVarMap,
) -> Result<Option<openmodelica_sim_meta::LinInfo>> {
    use openmodelica_sim_meta::LinVar;
    // A compile-time-constant input/output has no slot to perturb or read, so the
    // model cannot be linearized (nor can C's); `-l` reports it rather than
    // translation failing.
    let slots = |list: &Arc<List<SimCodeVar::SimVar>>| -> Result<Option<Vec<LinVar>>> {
        let mut out = Vec::new();
        for sv in lst(list) {
            let Some(slot) = var_map.vars.get(&sim_cref_key(&sv.name)?) else { return Ok(None) };
            out.push(LinVar { off: slot.off, negate: slot.negate });
        }
        Ok(Some(out))
    };
    let (Some(input_vars), Some(output_vars)) = (slots(&vars.inputVars)?, slots(&vars.outputVars)?)
    else {
        return Ok(None);
    };
    Ok(Some(openmodelica_sim_meta::LinInfo {
        input_vars,
        output_vars,
        language: plan.frames.language,
        frame: plan.frames.frame.clone(),
        frame_datarec: plan.frames.frame_datarec.clone(),
        disabled_reason: plan.frames.disabled_reason.clone(),
        sym_mask: plan.sym_mask(),
        run_testsuite: openmodelica_util::Testsuite::isRunning()?,
        jac_rows: plan.rows,
        jac_cols: plan.cols,
    }))
}

/// A Jacobian the emitter cannot lower is not an error, so its attempt reports here.
pub(crate) const JAC_CHECKPOINT: ArcStr = arcstr::literal!("wasm-jit symbolic Jacobian");

/// Lower the symbolic Jacobians' columns: `linearJac<X>` for `-l`, the
/// `functionJacA_{constantEqns,column}` pair the integrators drive, and for an
/// `optimization` model the `optJac<X>{_const,}` pair the optimizer drives one
/// colour at a time. A matrix that does not lower is dropped from the plan, so
/// `sym_mask` reports it unavailable and the run differentiates numerically —
/// availability is what the emitter can lower, not a prediction of it. Returns
/// `linearJac<X>`, A's pair, then B/C/D's.
#[allow(clippy::too_many_arguments)]
fn build_jac_fns(
    plan: &mut LinzPlan,
    infos: &[Option<LinzJacInfo>],
    is_optimization: bool,
    layout: &SimLayout,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    adj_map: Option<&SimVarMap>,
) -> Result<(Vec<we::Function>, [we::Function; 2], Vec<we::Function>, [we::Function; 2])> {
    let (mut linz_fns, mut jac_a_fns, mut opt_fns) = (Vec::new(), None, Vec::new());
    let mut out_off = layout.linz_off;
    for k in 0..4 {
        let mut built = None;
        if let (Some(jm), Some(info)) = (plan.jacs[k].clone(), infos.get(k).and_then(Option::as_ref)) {
            openmodelica_error::ErrorExt::setCheckpoint(JAC_CHECKPOINT);
            let attempt = (|| -> Result<(we::Function, [we::Function; 2])> {
                // A reshaped matrix has no linearization output region to fill.
                let lin = match plan.lin_ok(k) {
                    true => build_linz_jac_fn(plan, info, k, out_off, var_map, eq_index, by_name, literals)?,
                    false => empty_eqfn(),
                };
                // A is the integrators'; only the optimizer reads B, C and D.
                if k > 0 && !is_optimization {
                    return Ok((lin, [empty_eqfn(), empty_eqfn()]));
                }
                let (constant, column) = optimization::jac_eqns(&jm);
                let jm_map = with_jac_calls(var_map, &jm);
                Ok((lin, [
                    build_eq_fn_single(&eq_units(&constant), &jm_map, eq_index, by_name, literals)?,
                    build_eq_fn_single(&eq_units(&column), &jm_map, eq_index, by_name, literals)?,
                ]))
            })();
            match attempt {
                Ok(fns) => {
                    openmodelica_error::ErrorExt::delCheckpoint(JAC_CHECKPOINT);
                    built = Some(fns);
                }
                Err(_) => {
                    openmodelica_error::ErrorExt::rollBack(JAC_CHECKPOINT);
                    plan.jacs[k] = None;
                }
            }
        }
        let (lin, pair) = built.unwrap_or_else(|| (empty_eqfn(), [empty_eqfn(), empty_eqfn()]));
        linz_fns.push(lin);
        match k {
            0 => jac_a_fns = Some(pair),
            _ => opt_fns.extend(pair),
        }
        out_off += plan.rows[k] * plan.cols[k] * 8;
    }
    let mut adj_fns = [empty_eqfn(), empty_eqfn()];
    if plan.jacs[0].is_none() {
        plan.adj = None;
    }
    if let (Some(jm), Some(adj_map)) = (plan.adj.clone(), adj_map) {
        openmodelica_error::ErrorExt::setCheckpoint(JAC_CHECKPOINT);
        let attempt = (|| -> Result<[we::Function; 2]> {
            let (constant, column) = optimization::jac_eqns(&jm);
            let jm_map = with_jac_calls(adj_map, &jm);
            Ok([
                build_eq_fn_single(&eq_units(&constant), &jm_map, eq_index, by_name, literals)?,
                build_eq_fn_single(&eq_units(&column), &jm_map, eq_index, by_name, literals)?,
            ])
        })();
        match attempt {
            Ok(fns) => {
                openmodelica_error::ErrorExt::delCheckpoint(JAC_CHECKPOINT);
                adj_fns = fns;
            }
            Err(_) => {
                openmodelica_error::ErrorExt::rollBack(JAC_CHECKPOINT);
                plan.adj = None;
            }
        }
    }
    Ok((linz_fns, jac_a_fns.unwrap_or_else(|| [empty_eqfn(), empty_eqfn()]), opt_fns, adj_fns))
}

/// The matrix's own `generic_loop_calls` (C's `genericCall_jac_<i>`) in front of
/// the model's.
fn with_jac_calls(var_map: &SimVarMap, jm: &SimCode::JacobianMatrix) -> SimVarMap {
    let mut out = var_map.clone();
    if lst(&jm.generic_loop_calls).next().is_some() {
        let mut calls = (*out.generic_calls).clone();
        for c in lst(&jm.generic_loop_calls) {
            calls.insert(generic_call_index(c), c.clone());
        }
        out.generic_calls = Arc::new(calls);
    }
    out
}

/// Build one `linearJac<X>(SimData*)`: C's `functionJacX` loop moved into the
/// model, so the driver reads a finished matrix.
#[allow(clippy::too_many_arguments)]
fn build_linz_jac_fn(
    plan: &LinzPlan,
    info: &LinzJacInfo,
    k: usize,
    out_off: u32,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
) -> Result<we::Function> {
    let jm = plan.jacs[k].as_ref().ok_or("CodegenWasmJit: no linearization Jacobian")?;
    let col = lst(&jm.columns).next();
    let constant_eqns: Vec<Arc<SimCode::SimEqSystem>> =
        col.map(|c| lst(&c.constantEqns).cloned().collect()).unwrap_or_default();
    let column_eqns: Vec<Arc<SimCode::SimEqSystem>> =
        col.map(|c| lst(&c.columnEqns).cloned().collect()).unwrap_or_default();
    let mut ctx = FnCtx::new_sim(sim_ctx(var_map), by_name, literals);
    let mut lower = |c: &mut FnCtx, eqs: &[Arc<SimCode::SimEqSystem>]| -> Result<()> {
        for eq in eqs {
            lower_equation(c, eq, eq_index)?;
        }
        Ok(())
    };
    lower(&mut ctx, &constant_eqns)?;
    crate::CodegenWasmJitFunctions::emit_linz_jac_body(
        &mut ctx,
        out_off,
        plan.rows[k] as usize,
        &info.seed_offs,
        &info.result_offs,
        &mut |c: &mut FnCtx| lower(c, &column_eqns),
    )?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// A linear system's `A x = b` row count, `None` if it is not static.
fn lin_n_res(lsystem: &SimCode::LinearSystem) -> Option<usize> {
    residual_rows(&lin_residuals(lsystem, &mut Vec::new()))
}

/// Usable torn linear systems, deduped by index. `lin_jac_scratch_f64` (reserve)
/// and `build_lin_jac_infos` (register) both call this so they agree on the set.
fn lin_jac_systems(sim_code: &SimCode::SimCode) -> Vec<Arc<SimCode::LinearSystem>> {
    use SimCode::SimEqSystem as E;
    let mut seen: HashSet<i32> = HashSet::new();
    let mut out: Vec<Arc<SimCode::LinearSystem>> = Vec::new();
    let mut scan = |eqs: Vec<Arc<SimCode::SimEqSystem>>| {
        for e in &eqs_with_nested(&eqs) {
            if let E::SES_LINEAR { lSystem, alternativeTearing, .. } = &**e {
                // A dynamically torn component has two sets, each with its own Jacobian.
                for sys in std::iter::once(lSystem).chain(alternativeTearing.iter()) {
                    if sys.tornSystem && seen.insert(sys.index) && lin_jac_usable(sys, lin_n_res(sys)) {
                        out.push(sys.clone());
                    }
                }
            }
        }
    };
    scan(flatten_eqs(&sim_code.parameterEquations));
    scan(flatten_eqs(&sim_code.initialEquations));
    scan(flatten_eqs(&sim_code.initialEquations_lambda0));
    scan(flatten_eqs(&sim_code.removedInitialEquations));
    scan(flatten_eqs(&sim_code.algorithmAndEquationAsserts));
    scan(flatten_eqs(&sim_code.equationsForZeroCrossings));
    scan(flatten_eqs_ll(&sim_code.odeEquations));
    scan(flatten_eqs_ll(&sim_code.algebraicEquations));
    scan(flatten_eqs(&sim_code.allEquations));
    scan(flatten_eqs(&sim_code.inlineEquations));
    scan(clocked_eqs(sim_code));
    if let Some(d) = &sim_code.daeModeData {
        scan(flatten_eqs_ll(&d.daeEquations));
    }
    // A differentiated algebraic loop is a torn linear system in a Jacobian column.
    for jm in lst(&sim_code.jacobianMatrices) {
        if !jac_lowerable(jm) {
            continue;
        }
        for col in lst(&jm.columns) {
            scan(flatten_eqs(&col.constantEqns));
            scan(flatten_eqs(&col.columnEqns));
        }
    }
    out
}

/// f64 scratch slots the torn-linear analytic Jacobians need: seeds + all column
/// variables per usable system. Reserved after the NLS portion of the Jacobian
/// scratch region.
fn lin_jac_scratch_f64(sim_code: &SimCode::SimCode) -> u32 {
    let mut total = 0u32;
    for sys in lin_jac_systems(sim_code) {
        let jm = sys.jacobianMatrix.as_ref().unwrap();
        total += count(&jm.seedVars) as u32 + jac_column_vars(jm).len() as u32;
    }
    total
}

/// Register each torn-linear system's Jacobian seed/column-result crefs in the
/// Jacobian scratch region, starting after the NLS portion (`nls_jac_scratch_f64`).
/// The column equations then resolve their `$SEED`/`$pDER` slots when lowered, and
/// [`lin_jac_offsets`] reads the same slots back for assembly.
fn build_lin_jac_infos(
    sim_code: &SimCode::SimCode,
    layout: &SimLayout,
    var_map: &mut SimVarMap,
) -> Result<()> {
    let mut cursor = layout.nls_jac_off + nls_jac_scratch_f64(sim_code) * 8;
    for sys in lin_jac_systems(sim_code) {
        let jm = sys.jacobianMatrix.as_ref().unwrap();
        let column_vars = jac_column_vars(jm);
        // As in `register_jac_slots`: an array base listed beside its elements gets
        // no slot, an access to it reaches the elements' through `array_acc`.
        let mut bases: HashSet<String> = HashSet::new();
        for sv in lst(&jm.seedVars).chain(column_vars.iter()) {
            if let Some((base, _)) = array_element_of(&sv.name)? {
                bases.insert(base);
            }
        }
        for sv in lst(&jm.seedVars).chain(column_vars.iter()) {
            let key = sim_cref_key(&sv.name)?;
            if bases.contains(&key) {
                continue;
            }
            let off = cursor;
            Arc::make_mut(&mut var_map.vars).insert(key, SimSlot { off, wty: WTy::F64, negate: Neg::None, heap: false });
            for g in array_element_keys(&sv.name)? {
                var_map.array_acc.entry(g.base).or_default().push(AccElem {
                    subs: g.subs,
                    pieces: g.pieces,
                    off,
                    wty: WTy::F64,
                    neg: Neg::None,
                    heap: false,
                });
            }
            cursor += 8;
        }
    }
    Ok(())
}

/// Seed slots (in `seedVars`/column order) and result slots (at residual row via
/// `jac_result_row`) for a torn-linear Jacobian, read from the slots
/// `build_lin_jac_infos` registered. Feeds `compile_linear_system_analytic`.
fn lin_jac_offsets(lsystem: &SimCode::LinearSystem, vars: &HashMap<String, SimSlot>, n: usize) -> Result<(Vec<u32>, Vec<u32>)> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let jm = lsystem.jacobianMatrix.as_ref().ok_or("CodegenWasmJit: torn-linear system has no Jacobian")?;
    let lookup = |cr: &Arc<DAE::ComponentRef>| -> Result<u32> {
        let key = sim_cref_key(cr)?;
        Ok(vars.get(&key).ok_or("CodegenWasmJit: torn-linear Jacobian slot not registered")?.off)
    };
    let listed: Vec<u32> = lst(&jm.seedVars).map(|sv| lookup(&sv.name)).collect::<Result<_>>()?;
    let seed_offs = jac_seed_offs_by_column(jm, &listed, n)
        .ok_or("CodegenWasmJit: torn-linear Jacobian seed columns are not a permutation")?;
    let mut result_offs = vec![u32::MAX; n];
    for sv in &jac_column_vars(jm) {
        if matches!(sv.varKind, VarKind::JAC_VAR) {
            let row = jac_result_row(sv).filter(|&r| r < n)
                .ok_or("CodegenWasmJit: torn-linear Jacobian result var has no row index")?;
            result_offs[row] = lookup(&sv.name)?;
        }
    }
    if seed_offs.len() != n || result_offs.iter().any(|&o| o == u32::MAX) {
        return Err("CodegenWasmJit: torn-linear Jacobian seed/result mismatch");
    }
    Ok((seed_offs, result_offs))
}

/// Accumulate into `dep[lhs]` the seed columns that `eq`'s RHS depends on, for the
/// [`lin_jac_csc_pattern`] dataflow: a seed cref contributes its own column, any
/// other cref contributes its already-computed `dep` set (the column equations are
/// in dependency order). Only `SES_SIMPLE_ASSIGN` is handled; anything else -> None.
fn csc_accum_dep(
    eq: &Arc<SimCode::SimEqSystem>,
    seed_col: &HashMap<String, usize>,
    dep: &mut HashMap<String, Vec<usize>>,
) -> Option<()> {
    use SimCode::SimEqSystem as E;
    let E::SES_SIMPLE_ASSIGN { cref, exp, .. } = &**eq else { return None };
    let mut s: Vec<usize> = Vec::new();
    let crefs = openmodelica_frontend_base::Expression::extractCrefsFromExp(exp.clone()).ok()?;
    for cr in &*crefs {
        let k = sim_cref_key(cr).ok()?;
        if let Some(&c) = seed_col.get(&k) {
            if !s.contains(&c) { s.push(c); }
        } else if let Some(ds) = dep.get(&k) {
            for &c in ds { if !s.contains(&c) { s.push(c); } }
        }
    }
    dep.insert(sim_cref_key(cref).ok()?, s);
    Some(())
}

/// CSC pattern (`colptr`, `rowidx`, in `res_index` rows / iteration-variable cols)
/// of a torn-linear system's `A`, derived by propagating seed dependencies through
/// the Jacobian column equations: `A[row][col] != 0` iff the residual `row`'s
/// derivative depends on seed `col`. This is the true sparsity in the assembler's
/// own row order — the Jacobian's stored `sparsity` is in a dependent-var order
/// that does not map to `res_index`. Returns `None` for any unsupported equation
/// (caller falls back to dense assembly).
fn lin_jac_csc_pattern(lsystem: &SimCode::LinearSystem, n: usize) -> Option<(Vec<i32>, Vec<i32>)> {
    use openmodelica_backend_types::BackendDAE::VarKind;
    let jm = lsystem.jacobianMatrix.as_ref()?;
    let col = lst(&jm.columns).next()?;
    let mut seed_col: HashMap<String, usize> = HashMap::new();
    for sv in lst(&jm.seedVars) {
        seed_col.insert(sim_cref_key(&sv.name).ok()?, usize::try_from(sv.index).ok()?);
    }
    let mut dep: HashMap<String, Vec<usize>> = HashMap::new();
    for eq in lst(&col.constantEqns) {
        csc_accum_dep(eq, &seed_col, &mut dep)?;
    }
    for eq in lst(&col.columnEqns) {
        csc_accum_dep(eq, &seed_col, &mut dep)?;
    }
    // Column c (iteration var) gets residual row r whenever result r depends on seed c.
    let mut cols: Vec<Vec<i32>> = vec![Vec::new(); n];
    for sv in &jac_column_vars(jm) {
        if !matches!(sv.varKind, VarKind::JAC_VAR) {
            continue;
        }
        let r = jac_result_row(sv).filter(|&r| r < n)?;
        if let Some(ds) = dep.get(&sim_cref_key(&sv.name).ok()?) {
            for &c in ds {
                if c >= n {
                    return None;
                }
                cols[c].push(r as i32);
            }
        }
    }
    let mut colptr = vec![0i32; n + 1];
    let mut rowidx = Vec::new();
    for c in 0..n {
        cols[c].sort_unstable();
        rowidx.extend_from_slice(&cols[c]);
        colptr[c + 1] = colptr[c] + cols[c].len() as i32;
    }
    if rowidx.is_empty() {
        return None;
    }
    Some((colptr, rowidx))
}

/// Build the `residual(sim_data, x, r)` and `load(sim_data, x)` callback
/// functions for one nonlinear system (the model-specific half of
/// `rt_solve_nls`, reached by `call_indirect` over the shared table).
///
/// `strict` is the strict tearing set's job when `nlsystem` is a casual one: a
/// fourth callback, `solve(sim_data) -> solved`, is then emitted for
/// `rt_solve_nls` to fall back to (C's `strictTearingFunctionCall`), and the
/// residual carries the casual set's local constraint checks.
#[allow(clippy::too_many_arguments)]
fn build_nls_fns(
    nlsystem: &SimCode::NonlinearSystem,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Literals,
    jac_info: Option<&NlsJacInfo>,
    strict: Option<NlsJob>,
) -> Result<(we::Function, we::Function, Option<we::Function>, Option<we::Function>)> {
    let _fg = crate::CodegenWasmJitFunctions::FnNameGuard::new(&format!(
        "nonlinear system {}",
        nlsystem.index
    ));
    let (inner, residuals, iter_vars) = nls_parts(nlsystem)?;
    // Resolve each unknown to its (real) SimData slot offset.
    let mut slots: Vec<u32> = Vec::with_capacity(iter_vars.len());
    for cr in &iter_vars {
        if is_homotopy_lambda(Some(cr)) {
            slots.push(var_map.lambda_off);
            continue;
        }
        let off = iteration_var_slot(&var_map.vars, &var_map.start_slots, cr)?
            .ok_or("CodegenWasmJit: nonlinear-system unknown has no slot")?;
        slots.push(off);
    }
    let mk_sim = || sim_ctx(var_map);
    let finish = |ctx: FnCtx| -> we::Function {
        let (locals, instrs) = ctx.finish_sim();
        let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
        for i in &instrs {
            func.instruction(i);
        }
        func
    };

    // residual(sim_data, x, r): 3 params.
    let residual = {
        let mut ctx = FnCtx::new_sim_params(mk_sim(), by_name, literals, 3);
        // C's `residualFuncConstraints` for a casual set: each inner equation's
        // `localCon` constraints are checked before it runs.
        ctx.set_dt_local_cons(strict.is_some());
        let mut lower_inner = |c: &mut FnCtx| -> Result<()> {
            for eq in &inner {
                lower_equation(c, eq, eq_index)?;
            }
            Ok(())
        };
        emit_nls_residual_body(&mut ctx, nlsystem.index, &slots, &residuals, &mut lower_inner)?;
        finish(ctx)
    };
    // load(sim_data, x): 2 params.
    let load = {
        let mut ctx = FnCtx::new_sim_params(mk_sim(), by_name, literals, 2);
        emit_nls_load_body(&mut ctx, &slots)?;
        finish(ctx)
    };
    // jac(sim_data, x, jptr): column-major `n×n` analytic Jacobian, emitted only
    // when the system carries a usable symbolic Jacobian.
    let jac = match (&nlsystem.jacobianMatrix, jac_info) {
        (Some(jm), Some(info)) => {
            let col = lst(&jm.columns)
                .next()
                .ok_or_else(|| "CodegenWasmJit: nonlinear-system Jacobian has no column")?;
            let constant_eqns: Vec<Arc<SimCode::SimEqSystem>> = lst(&col.constantEqns).cloned().collect();
            let column_eqns: Vec<Arc<SimCode::SimEqSystem>> = lst(&col.columnEqns).cloned().collect();
            // Bind this matrix's own seed/column slots over the shared map, which
            // holds whichever system registered the shared names last.
            let mut sim = mk_sim();
            let mut vars = (*sim.vars).clone();
            for (key, slot) in &info.slots {
                vars.insert(key.clone(), *slot);
            }
            sim.vars = Arc::new(vars);
            let mut ctx = FnCtx::new_sim_params(sim, by_name, literals, 3);
            let mut lower_inner = |c: &mut FnCtx| -> Result<()> {
                for eq in &inner {
                    lower_equation(c, eq, eq_index)?;
                }
                Ok(())
            };
            let mut lower_constant = |c: &mut FnCtx| -> Result<()> {
                for eq in &constant_eqns {
                    lower_equation(c, eq, eq_index)?;
                }
                Ok(())
            };
            let mut lower_column = |c: &mut FnCtx| -> Result<()> {
                for eq in &column_eqns {
                    lower_equation(c, eq, eq_index)?;
                }
                Ok(())
            };
            // Colored CSC assembly (C's `evalJacobian`) whenever the symbolic
            // sparsity is available: `#colors` column-equation passes instead of
            // `n`, into CSC values for a sparse system or a dense `n×n` otherwise.
            match nls_jac_pattern(jm, slots.len()) {
                Some(pat) => emit_nls_jac_csc_body(
                    &mut ctx, &slots, &info.seed_offs, &info.result_offs,
                    &pat.colptr, &pat.rowidx, &pat.colors,
                    !nls_use_sparse(slots.len(), pat.rowidx.len()),
                    &mut lower_inner, &mut lower_constant, &mut lower_column,
                )?,
                None => emit_nls_jac_body(
                    &mut ctx, &slots, &info.seed_offs, &info.result_offs,
                    &mut lower_inner, &mut lower_constant, &mut lower_column,
                )?,
            }
            Some(finish(ctx))
        }
        _ => None,
    };
    // solve(sim_data) -> solved: the strict tearing set, C's `eqFunction_<ls.index>`.
    let strict_fn = strict
        .map(|job| -> Result<we::Function> {
            let mut ctx = FnCtx::new_sim_params(mk_sim(), by_name, literals, 1);
            crate::CodegenWasmJitFunctions::emit_nls_strict_body(&mut ctx, job)?;
            Ok(finish(ctx))
        })
        .transpose()?;
    Ok((residual, load, jac, strict_fn))
}

/// The nonlinear-solver part of the module `start`: grow the shared
/// `rt.__indirect_function_table` by `4 * n` slots, record the base (the old
/// size) in the `nls_base` global, then write each system's `residual`/`load`
/// function references into `base + 4k` / `base + 4k + 1`
/// (`fn_indices[k] = (residual, load, jac, strict)`). `rt_solve_nls` reads these
/// indices back via the global (see `emit_solve_nls_call`). Also `rt_alloc`s the
/// extrapolation-history block (`hist_bytes`) into `NLS_HIST_GLOBAL`.
fn emit_nls_start(
    f: &mut we::Function,
    fn_indices: &[(u32, u32, Option<u32>, Option<u32>)],
    hist_bytes: u32,
    sizes: &[u32],
    nominals: &[f64],
    bounds: &[f64],
    patterns: &[i32],
) {
    use we::Instruction as I;
    use crate::CodegenWasmJitFunctions::{NLS_BOUNDS_GLOBAL, NLS_NOMINAL_GLOBAL, NLS_PAT_GLOBAL};
    // history block (zeroed by rt_alloc, so every system's count starts 0).
    if hist_bytes > 0 {
        f.instruction(&I::I32Const(hist_bytes as i32));
        f.instruction(&I::Call(rt_index("rt_alloc").expect("rt_alloc is a runtime builtin")));
        f.instruction(&I::GlobalSet(NLS_HIST_GLOBAL));
    }
    // Hand each system's slice of it to the runtime's roster.
    let mut hist_off = 0u32;
    for (k, n) in sizes.iter().enumerate() {
        f.instruction(&I::I32Const(k as i32));
        f.instruction(&I::GlobalGet(NLS_HIST_GLOBAL));
        f.instruction(&I::I32Const(hist_off as i32));
        f.instruction(&I::I32Add);
        f.instruction(&I::I32Const(*n as i32));
        f.instruction(&I::Call(rt_index("rt_nls_register").expect("rt_nls_register is a runtime builtin")));
        hist_off += crate::CodegenWasmJitFunctions::nls_hist_bytes(*n);
    }
    // nominal block: rt_alloc, then store each system's iteration-variable nominal
    // constants (concatenated in system order) for `rt_solve_nls`'s x-scaling.
    if !nominals.is_empty() {
        f.instruction(&I::I32Const((nominals.len() * 8) as i32));
        f.instruction(&I::Call(rt_index("rt_alloc").expect("rt_alloc is a runtime builtin")));
        f.instruction(&I::GlobalSet(NLS_NOMINAL_GLOBAL));
        for (i, nom) in nominals.iter().enumerate() {
            f.instruction(&I::GlobalGet(NLS_NOMINAL_GLOBAL));
            f.instruction(&I::F64Const((*nom).into()));
            f.instruction(&I::F64Store(crate::CodegenWasmJitFunctions::mem_arg((i * 8) as u32, 3)));
        }
    }
    // bounds block: the `min`/`max` pair per iteration variable, same order.
    if !bounds.is_empty() {
        f.instruction(&I::I32Const((bounds.len() * 8) as i32));
        f.instruction(&I::Call(rt_index("rt_alloc").expect("rt_alloc is a runtime builtin")));
        f.instruction(&I::GlobalSet(NLS_BOUNDS_GLOBAL));
        for (i, v) in bounds.iter().enumerate() {
            f.instruction(&I::GlobalGet(NLS_BOUNDS_GLOBAL));
            f.instruction(&I::F64Const((*v).into()));
            f.instruction(&I::F64Store(crate::CodegenWasmJitFunctions::mem_arg((i * 8) as u32, 3)));
        }
    }
    // sparse-pattern block: the concatenated `colptr`/`rowidx` of every system
    // solved sparsely, indexed by each job's `pat_off`.
    if !patterns.is_empty() {
        f.instruction(&I::I32Const((patterns.len() * 4) as i32));
        f.instruction(&I::Call(rt_index("rt_alloc").expect("rt_alloc is a runtime builtin")));
        f.instruction(&I::GlobalSet(NLS_PAT_GLOBAL));
        for (i, v) in patterns.iter().enumerate() {
            f.instruction(&I::GlobalGet(NLS_PAT_GLOBAL));
            f.instruction(&I::I32Const(*v));
            f.instruction(&I::I32Store(crate::CodegenWasmJitFunctions::mem_arg((i * 4) as u32, 2)));
        }
    }
    // base = table.grow(null, 4n) — returns the old size (the growable table's max
    // is unbounded, so this cannot fail here). Four slots per system:
    // `4k`=residual, `4k+1`=load, `4k+2`=jac, `4k+3`=the strict tearing set's solve
    // (the last two left null where the system has neither).
    f.instruction(&I::RefNull(we::HeapType::FUNC));
    f.instruction(&I::I32Const((4 * fn_indices.len()) as i32));
    f.instruction(&I::TableGrow(0));
    f.instruction(&I::GlobalSet(NLS_BASE_GLOBAL));
    fn set_slot(f: &mut we::Function, off: i32, idx: u32) {
        use we::Instruction as I;
        f.instruction(&I::GlobalGet(NLS_BASE_GLOBAL));
        f.instruction(&I::I32Const(off));
        f.instruction(&I::I32Add);
        f.instruction(&I::RefFunc(idx));
        f.instruction(&I::TableSet(0));
    }
    for (k, (res_idx, load_idx, jac_idx, strict_idx)) in fn_indices.iter().enumerate() {
        let base_off = (4 * k) as i32;
        set_slot(f, base_off, *res_idx);
        set_slot(f, base_off + 1, *load_idx);
        if let Some(jac_idx) = jac_idx {
            set_slot(f, base_off + 2, *jac_idx);
        }
        if let Some(strict_idx) = strict_idx {
            set_slot(f, base_off + 3, *strict_idx);
        }
    }
}

fn generic_call_index(call: &SimCode::SimGenericCall) -> i32 {
    use SimCode::SimGenericCall as G;
    match call {
        G::SINGLE_GENERIC_CALL { index, .. }
        | G::IF_GENERIC_CALL { index, .. }
        | G::WHEN_GENERIC_CALL { index, .. } => *index,
    }
}

pub(crate) fn eq_kind_name(eq: &SimCode::SimEqSystem) -> &'static str {
    use SimCode::SimEqSystem as E;
    match eq {
        E::SES_RESIDUAL { .. } => "SES_RESIDUAL",
        E::SES_FOR_RESIDUAL { .. } => "SES_FOR_RESIDUAL",
        E::SES_GENERIC_RESIDUAL { .. } => "SES_GENERIC_RESIDUAL",
        E::SES_SIMPLE_ASSIGN { .. } => "SES_SIMPLE_ASSIGN",
        E::SES_SIMPLE_ASSIGN_CONSTRAINTS { .. } => "SES_SIMPLE_ASSIGN_CONSTRAINTS",
        E::SES_ARRAY_CALL_ASSIGN { .. } => "SES_ARRAY_CALL_ASSIGN",
        E::SES_LINEAR { .. } => "SES_LINEAR",
        E::SES_NONLINEAR { .. } => "SES_NONLINEAR",
        E::SES_MIXED { .. } => "SES_MIXED",
        E::SES_WHEN { .. } => "SES_WHEN",
        E::SES_IFEQUATION { .. } => "SES_IFEQUATION",
        E::SES_ALGORITHM { .. } => "SES_ALGORITHM",
        E::SES_INVERSE_ALGORITHM { .. } => "SES_INVERSE_ALGORITHM",
        E::SES_RESIZABLE_ASSIGN { .. } => "SES_RESIZABLE_ASSIGN",
        E::SES_GENERIC_ASSIGN { .. } => "SES_GENERIC_ASSIGN",
        E::SES_ENTWINED_ASSIGN { .. } => "SES_ENTWINED_ASSIGN",
        E::SES_FOR_LOOP { .. } => "SES_FOR_LOOP",
        E::SES_FOR_EQUATION { .. } => "SES_FOR_EQUATION",
        E::SES_ALIAS { .. } => "SES_ALIAS",
        E::SES_ALGEBRAIC_SYSTEM { .. } => "SES_ALGEBRAIC_SYSTEM",
    }
}

/// Whether any equation, at any nesting depth, is a `SES_LINEAR` C would solve
/// with `method = 1`.
fn has_method1_linear(sim_code: &SimCode::SimCode) -> bool {
    fn walk(e: &Arc<SimCode::SimEqSystem>) -> bool {
        use SimCode::SimEqSystem as E;
        match &**e {
            E::SES_LINEAR { lSystem, alternativeTearing, .. } => {
                lSystem.jacobianMatrix.is_some()
                    || alternativeTearing.as_ref().is_some_and(|a| a.jacobianMatrix.is_some())
                    || lst(&lSystem.residual).any(walk)
            }
            E::SES_NONLINEAR { nlSystem, alternativeTearing, .. } => {
                lst(&nlSystem.eqs).any(walk)
                    || alternativeTearing.as_ref().is_some_and(|a| lst(&a.eqs).any(walk))
            }
            E::SES_MIXED { cont, discEqs, .. } => walk(cont) || lst(discEqs).any(walk),
            E::SES_IFEQUATION { ifbranches, elsebranch, .. } => {
                lst(ifbranches).any(|(_, eqs)| lst(eqs).any(walk)) || lst(elsebranch).any(walk)
            }
            _ => false,
        }
    }
    let lists = [
        &sim_code.allEquations,
        &sim_code.initialEquations,
        &sim_code.initialEquations_lambda0,
        &sim_code.parameterEquations,
        &sim_code.removedInitialEquations,
        &sim_code.removedEquations,
        &sim_code.startValueEquations,
        &sim_code.equationsForZeroCrossings,
        &sim_code.inlineEquations,
    ];
    lists.iter().any(|l| lst(l).any(walk))
        || lst(&sim_code.odeEquations).chain(lst(&sim_code.algebraicEquations)).any(|p| lst(p).any(walk))
        || sim_code.daeModeData.as_ref().is_some_and(|d| lst(&d.daeEquations).any(|p| lst(p).any(walk)))
}

/// Index `e` by its own index and recurse into nested equations (torn-system
/// inner constraints, mixed cont/disc parts, if-branches), which an `SES_ALIAS`
/// may target but which the top-level lists don't reach.
fn index_eq_recursive(e: &Arc<SimCode::SimEqSystem>, idx: &mut HashMap<i32, Arc<SimCode::SimEqSystem>>) {
    use SimCode::SimEqSystem as E;
    let key = eq_index_of(e);
    if key >= 0 {
        idx.entry(key).or_insert_with(|| e.clone());
    }
    match &**e {
        E::SES_LINEAR { lSystem, alternativeTearing, .. } => {
            let mut index_lin = |s: &Arc<SimCode::LinearSystem>, idx: &mut _| {
                for inner in lst(&s.residual) {
                    index_eq_recursive(inner, idx);
                }
                for (_, _, inner) in lst(&s.simJac) {
                    index_eq_recursive(inner, idx);
                }
            };
            index_lin(lSystem, idx);
            if let Some(alt) = alternativeTearing {
                index_lin(alt, idx);
            }
        }
        E::SES_NONLINEAR { nlSystem, alternativeTearing, .. } => {
            for inner in lst(&nlSystem.eqs) {
                index_eq_recursive(inner, idx);
            }
            if let Some(alt) = alternativeTearing {
                for inner in lst(&alt.eqs) {
                    index_eq_recursive(inner, idx);
                }
            }
        }
        E::SES_MIXED { cont, discEqs, .. } => {
            index_eq_recursive(cont, idx);
            for inner in lst(discEqs) {
                index_eq_recursive(inner, idx);
            }
        }
        E::SES_IFEQUATION { ifbranches, elsebranch, .. } => {
            for (_, eqs) in lst(ifbranches) {
                for inner in lst(eqs) {
                    index_eq_recursive(inner, idx);
                }
            }
            for inner in lst(elsebranch) {
                index_eq_recursive(inner, idx);
            }
        }
        _ => {}
    }
}

/// The `index` of a `SimEqSystem` (best-effort; systems without a top-level
/// index report -1).
/// The `--parmodauto` task graph C's `SerializeTaskSystemInfo` writes to
/// `<model>_ode.json` and `om_pm_model.cpp` loads: one task per ODE equation with
/// what it defines and uses, and an edge from every earlier task defining
/// something a later one uses (`TaskSystem_v2::add_node`). Reads of a dense
/// linear system's `A`/`b` count as uses too; C's loader only sees a torn system's
/// inner equations.
fn parmod_info(ode_eqs: &[Arc<SimCode::SimEqSystem>]) -> Result<openmodelica_sim_meta::ParmodInfo> {
    use SimCode::SimEqSystem as E;
    use openmodelica_frontend_base::{ComponentReference, Expression};
    fn name(cref: &Arc<DAE::ComponentRef>) -> Result<String> {
        Ok(ComponentReference::crefStr(cref.clone())?.to_string())
    }
    fn uses(exp: &Arc<DAE::Exp>) -> Result<Vec<String>> {
        lst(&Expression::extractUniqueCrefsFromExpDerPreStart(exp.clone(), true)?).map(name).collect()
    }
    fn unsupported(index: i32, what: &str) -> &'static str {
        Box::leak(format!("parmodauto: equation {index}: {what}").into_boxed_str())
    }
    // C's `load_simple_assign_check_local_define` / `load_simple_residual`.
    fn inner(eq: &E, lhs: &mut HashSet<String>, rhs: &mut HashSet<String>) -> Result<()> {
        let (define, exp) = match eq {
            E::SES_SIMPLE_ASSIGN { cref, exp, .. }
            | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cref, exp, .. }
            | E::SES_FOR_LOOP { cref, exp, .. } => (Some(name(cref)?), exp),
            E::SES_ARRAY_CALL_ASSIGN { lhs, exp, .. } => (Some(name(&Expression::expCref(lhs.clone())?)?), exp),
            E::SES_RESIDUAL { exp, .. } => (None, exp),
            other => return Err(unsupported(eq_index_of(other), "internal equation type not yet handled")),
        };
        match define {
            Some(d) => {
                lhs.insert(d);
                for u in uses(exp)? {
                    if !lhs.contains(&u) {
                        rhs.insert(u);
                    }
                }
            }
            None => rhs.extend(uses(exp)?),
        }
        Ok(())
    }
    let sorted = |eqs: &Arc<List<Arc<E>>>| -> Vec<Arc<E>> {
        let mut v: Vec<Arc<E>> = lst(eqs).cloned().collect();
        v.sort_by_key(|e| eq_index_of(e));
        v
    };
    let mut nodes: Vec<(i32, HashSet<String>, HashSet<String>)> = Vec::new();
    for eq in ode_eqs {
        let index = eq_index_of(eq);
        let mut lhs = HashSet::new();
        let mut rhs = HashSet::new();
        match &**eq {
            E::SES_RESIDUAL { exp, .. } => rhs.extend(uses(exp)?),
            E::SES_SIMPLE_ASSIGN { cref, exp, .. }
            | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { cref, exp, .. }
            | E::SES_FOR_LOOP { cref, exp, .. } => {
                lhs.insert(name(cref)?);
                rhs.extend(uses(exp)?);
            }
            E::SES_ARRAY_CALL_ASSIGN { lhs: l, exp, .. } => {
                lhs.insert(name(&Expression::expCref(l.clone())?)?);
                rhs.extend(uses(exp)?);
            }
            E::SES_ALGORITHM { statements, .. } | E::SES_INVERSE_ALGORITHM { statements, .. } => {
                let (defs, used) = Expression::extractUniqueCrefsFromStatmentS(statements.clone())?;
                lhs.extend(lst(&defs).map(name).collect::<Result<Vec<_>>>()?);
                rhs.extend(lst(&used).map(name).collect::<Result<Vec<_>>>()?);
            }
            E::SES_LINEAR { lSystem, alternativeTearing: None, .. } => {
                for v in lst(&lSystem.vars) {
                    lhs.insert(name(&v.name)?);
                }
                for e in sorted(&lSystem.residual) {
                    inner(&e, &mut lhs, &mut rhs)?;
                }
                for b in lst(&lSystem.beqs) {
                    rhs.extend(uses(b)?.into_iter().filter(|u| !lhs.contains(u)));
                }
                for (_, _, cell) in lst(&lSystem.simJac) {
                    if let E::SES_RESIDUAL { exp, .. } = &**cell {
                        rhs.extend(uses(exp)?.into_iter().filter(|u| !lhs.contains(u)));
                    }
                }
            }
            E::SES_NONLINEAR { nlSystem, alternativeTearing: None, .. } => {
                for c in lst(&nlSystem.crefs) {
                    lhs.insert(name(c)?);
                }
                for e in sorted(&nlSystem.eqs) {
                    inner(&e, &mut lhs, &mut rhs)?;
                }
            }
            E::SES_LINEAR { .. } | E::SES_NONLINEAR { .. } => {
                return Err(unsupported(index, "dynamic tearing is not supported"));
            }
            E::SES_WHEN { .. } => return Err(unsupported(index, "equation type not yet handled: when")),
            E::SES_IFEQUATION { .. } => return Err(unsupported(index, "equation type not yet handled: if-equation")),
            E::SES_MIXED { .. } => return Err(unsupported(index, "equation type not yet handled: container")),
            E::SES_ALIAS { .. } => return Err(unsupported(index, "equation type not yet handled: alias")),
            _ => return Err(unsupported(index, "equation type not yet handled")),
        }
        nodes.push((index, lhs, rhs));
    }
    let mut tasks = Vec::with_capacity(nodes.len());
    for (j, (index, _, rhs)) in nodes.iter().enumerate() {
        let parents: Vec<u32> = nodes[..j]
            .iter()
            .enumerate()
            .filter(|(_, (_, lhs, _))| rhs.iter().any(|u| lhs.contains(u)))
            .map(|(i, _)| i as u32)
            .collect();
        tasks.push(openmodelica_sim_meta::ParmodTask { eq_index: *index, parents });
    }
    Ok(openmodelica_sim_meta::ParmodInfo { tasks })
}

fn eq_index_of(eq: &SimCode::SimEqSystem) -> i32 {
    use SimCode::SimEqSystem as E;
    match eq {
        E::SES_RESIDUAL { index, .. }
        | E::SES_FOR_RESIDUAL { index, .. }
        | E::SES_GENERIC_RESIDUAL { index, .. }
        | E::SES_SIMPLE_ASSIGN { index, .. }
        | E::SES_SIMPLE_ASSIGN_CONSTRAINTS { index, .. }
        | E::SES_ARRAY_CALL_ASSIGN { index, .. }
        | E::SES_RESIZABLE_ASSIGN { index, .. }
        | E::SES_GENERIC_ASSIGN { index, .. }
        | E::SES_ENTWINED_ASSIGN { index, .. }
        | E::SES_IFEQUATION { index, .. }
        | E::SES_ALGORITHM { index, .. }
        | E::SES_INVERSE_ALGORITHM { index, .. }
        | E::SES_MIXED { index, .. }
        | E::SES_WHEN { index, .. }
        | E::SES_ALGEBRAIC_SYSTEM { index, .. }
        | E::SES_FOR_LOOP { index, .. } => *index,
        // Torn systems carry their index inside the system record, not as a
        // top-level field; an `SES_ALIAS` can point at the whole system.
        E::SES_LINEAR { lSystem, .. } => lSystem.index,
        E::SES_NONLINEAR { nlSystem, .. } => nlSystem.index,
        _ => -1,
    }
}

/// An empty function body, valid for any void signature. Used for the optional
/// equation functions (`initSample`, `functionZeroCrossings`,
/// `functionStateSetJacobians`, `functionInitialEquations_lambda0`) when a model
/// lacks that feature, so the model still *exports* every driver entry point. The
/// standalone `wasm-merge` (and the interactive shared table) then always resolve
/// them; the shared driver only calls one when the corresponding metadata count is
/// nonzero, so the stub is never entered.
pub(crate) fn empty_eqfn() -> we::Function {
    let mut f = we::Function::new([]);
    f.instruction(&we::Instruction::End);
    f
}

/// Emit the in-wasm forward-Euler integrator loop:
/// `simulate(sim_data, start, stop, n_steps) -> result_buffer`. The caller
/// (`driver::run_wasm`) has initialized the model, so this starts at row 0.
/// `check_asserts` is `functionCheckAsserts` when the model has any min/max check.
fn build_simulate(layout: &SimLayout, eqfn: &EqFnIdx, check_asserts: Option<u32>) -> Result<we::Function> {
    // Params: 0 sim_data(i32), 1 start(f64), 2 stop(f64), 3 n_steps(i32).
    // Locals: 4 buf(i32), 5 h(f64), 6 row(i32).
    const SIM_DATA: u32 = 0;
    const START: u32 = 1;
    const STOP: u32 = 2;
    const N_STEPS: u32 = 3;
    const BUF: u32 = 4;
    const H: u32 = 5;
    const ROW: u32 = 6;
    const DEST: u32 = 7;

    let n_reals = layout.n_reals_row();
    let n_total = layout.n_row_total();
    let n_states = layout.n_states;
    // locals: BUF(i32), H(f64), ROW(i32), DEST(i32)
    let mut f = we::Function::new([(1, we::ValType::I32), (1, we::ValType::F64), (2, we::ValType::I32)]);
    use we::Instruction as I;

    // buf = rt_alloc((n_steps + 1) * n_total * 8)
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::I32Const(1));
    f.instruction(&I::I32Add);
    f.instruction(&I::I32Const((n_total * 8) as i32));
    f.instruction(&I::I32Mul);
    f.instruction(&I::Call(rt_index("rt_alloc")?));
    f.instruction(&I::LocalSet(BUF));

    // h = (stop - start) / max(n_steps, 1): `stopTime <= startTime` takes no step.
    f.instruction(&I::LocalGet(STOP));
    f.instruction(&I::LocalGet(START));
    f.instruction(&I::F64Sub);
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::F64ConvertI32S);
    f.instruction(&I::F64Const(1.0.into()));
    f.instruction(&I::F64Max);
    f.instruction(&I::F64Div);
    f.instruction(&I::LocalSet(H));

    // row = 0
    f.instruction(&I::I32Const(0));
    f.instruction(&I::LocalSet(ROW));

    // block { loop {
    f.instruction(&I::Block(we::BlockType::Empty));
    f.instruction(&I::Loop(we::BlockType::Empty));

    // time = start + row * h
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::LocalGet(START));
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::F64ConvertI32S);
    f.instruction(&I::LocalGet(H));
    f.instruction(&I::F64Mul);
    f.instruction(&I::F64Add);
    f.instruction(&I::F64Store(crate::CodegenWasmJitFunctions::mem_arg(TIME_OFF, 3)));

    // Row 0 is the initialized point: capture it without re-evaluating, as C does
    // after `initializeModel` (a second pass would repeat the equations' side
    // effects). Every later row is evaluated at its time.
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::If(we::BlockType::Empty));

    // C's terminal step is a row of its own (`emit_terminal_row`), so no row here
    // raises the flag.

    // functionODE(sim_data); functionAlgebraics(sim_data)
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::Call(eqfn.ode));
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::Call(eqfn.algebraics));

    f.instruction(&I::End); // if row != 0

    // Store the row at dest = buf + row * n_total * 8:
    //   - copy the real part [time | realVars] (contiguous from sim_data[0])
    //   - then each integer / boolean algebraic slot, converted i32 -> f64
    f.instruction(&I::LocalGet(BUF));
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::I32Const((n_total * 8) as i32));
    f.instruction(&I::I32Mul);
    f.instruction(&I::I32Add);
    f.instruction(&I::LocalSet(DEST));
    // memory.copy(dest, sim_data, n_reals*8)
    f.instruction(&I::LocalGet(DEST));
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::I32Const((n_reals * 8) as i32));
    f.instruction(&I::MemoryCopy { src_mem: 0, dst_mem: 0 });
    let store_islot = |f: &mut we::Function, src_off: u32, dst_col: u32| {
        f.instruction(&I::LocalGet(DEST));
        f.instruction(&I::LocalGet(SIM_DATA));
        f.instruction(&I::I32Load(crate::CodegenWasmJitFunctions::mem_arg(src_off, 2)));
        f.instruction(&I::F64ConvertI32S);
        f.instruction(&I::F64Store(crate::CodegenWasmJitFunctions::mem_arg(dst_col * 8, 3)));
    };
    for i in 0..layout.n_int_alg() {
        store_islot(&mut f, layout.int_off + i * 4, n_reals + i);
    }
    for j in 0..layout.n_bool_alg() {
        store_islot(&mut f, layout.bool_off + j * 4, n_reals + layout.n_int_alg() + j);
    }
    // The raw String handles keep the row width; the driver never takes this path
    // with String results (they need interning at capture).
    for i in 0..layout.n_str_alg() {
        store_islot(&mut f, layout.str_off + i * 4, layout.str_col0() + i);
    }
    // Only IDA fills the sensitivity block, and this loop is Euler's.
    if layout.n_sens > 0 {
        f.instruction(&I::LocalGet(DEST));
        f.instruction(&I::I32Const((layout.sens_col0() * 8) as i32));
        f.instruction(&I::I32Add);
        f.instruction(&I::I32Const(0));
        f.instruction(&I::I32Const((layout.n_sens * 8) as i32));
        f.instruction(&I::MemoryFill(0));
    }

    // The driver's per-row `check_asserts`: evaluate the min/max checks, then let
    // the host format what they recorded while `time` still holds this row's.
    // Level `warning` for the first and the terminal row, `info` in between.
    if let Some(idx) = check_asserts {
        f.instruction(&I::LocalGet(SIM_DATA));
        f.instruction(&I::Call(idx));
    }
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::I32Eqz);
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::I32Eq);
    f.instruction(&I::I32Or);
    f.instruction(&I::Call(crate::CodegenWasmJitFunctions::env_extra_index("rt_row_asserts")?));
    f.instruction(&I::BrIf(1)); // a suppressed assert ends the run; `run_wasm` throws

    // if terminate() fired this step (functionAlgebraics raised the flag): break,
    // keeping the row just stored as the last one.
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::I32Load(crate::CodegenWasmJitFunctions::mem_arg(layout.terminate_off, 2)));
    f.instruction(&I::BrIf(1)); // branch out of the loop to the block end

    // if a nonlinear system failed to converge: break too (the host `run_wasm`
    // reads the flag afterward and reports it — Euler cannot back off the step).
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::I32Load(crate::CodegenWasmJitFunctions::mem_arg(layout.nls_fail_off, 2)));
    f.instruction(&I::BrIf(1));

    // if row >= n_steps: break (exit the block)
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::I32GeS);
    f.instruction(&I::BrIf(1)); // branch out of the loop to the block end

    // rt_euler_step(sim_data, n_states, h)
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::I32Const(n_states as i32));
    f.instruction(&I::LocalGet(H));
    f.instruction(&I::Call(rt_index("rt_euler_step")?));

    // row += 1; continue
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::I32Const(1));
    f.instruction(&I::I32Add);
    f.instruction(&I::LocalSet(ROW));
    f.instruction(&I::Br(0));

    f.instruction(&I::End); // loop
    f.instruction(&I::End); // block

    // Record how many rows were written (row + 1), so the host driver reads only
    // the produced rows after an early terminate (full run: n_steps + 1).
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::I32Const(1));
    f.instruction(&I::I32Add);
    f.instruction(&I::I32Store(crate::CodegenWasmJitFunctions::mem_arg(layout.n_out_off, 2)));

    // return buf
    f.instruction(&I::LocalGet(BUF));
    f.instruction(&I::End); // function
    Ok(f)
}

// ===========================================================================
// MATLAB v4 result-file writer
// ===========================================================================

/// Write the simulation result as an OpenModelica MATLAB v4 (`.mat`) file.
/// Which result variables this run emits, one flag per [`SimModel::result_vars`]
/// entry. An uncompilable `-variableFilter` is C's "Defaulting to outputting all
/// variables": it has already replaced the model's filter, so nothing remains to
/// fall back on.
fn output_selection(model: &SimModel) -> Vec<bool> {
    let Some(pattern) = simflags::with_flags(|f| f.variable_filter.clone()) else {
        return model.meta.output_keep(None);
    };
    match openmodelica_util::System::Regex::new(&format!("^({pattern})$")) {
        Ok(re) => model.meta.output_keep(Some(&|name: &str| re.is_match(name))),
        Err(e) => {
            eprintln!(
                "Failed to compile regular expression: {pattern} with error: {e}. \
                 Defaulting to outputting all variables."
            );
            model.meta.output_keep(Some(&|_: &str| true))
        }
    }
}

// Both link paths (standalone merge, FMU component) are native-only.
#[cfg(test)]
#[cfg(not(target_arch = "wasm32"))]
mod link_tests {
    use super::*;
    use wasm_encoder as we;

    /// A minimal stand-in for a lowered model module: it exports the four model
    /// functions and the two metadata accessors the standalone runtime imports
    /// (module `model`), and imports `rt.memory` + `rt.rt_alloc` like a real model,
    /// so the merge must resolve both directions of the contract.
    fn build_stub_model() -> Vec<u8> {
        use we::Instruction as I;
        let mut m = we::Module::new();

        let mut types = we::TypeSection::new();
        types.ty().function([we::ValType::I32], [we::ValType::I32]); // 0: (i32)->i32  (rt_alloc)
        types.ty().function([we::ValType::I32], []); // 1: (i32)->()   (model fns)
        types.ty().function([], [we::ValType::I32]); // 2: ()->i32      (om_meta_*)
        // 3: (i32,f64,f64,i32)->i32  (simulate)
        types.ty().function(
            [we::ValType::I32, we::ValType::F64, we::ValType::F64, we::ValType::I32],
            [we::ValType::I32],
        );
        // 4: (i32,i32)->()  (functionUpdateSynchronous / functionEquationsSynchronous)
        types.ty().function([we::ValType::I32, we::ValType::I32], []);
        types.ty().function([], []); // 5: ()->()      (om_throw_model_error)
        m.section(&types);

        let mut imports = we::ImportSection::new();
        imports.import(
            "rt",
            "memory",
            we::MemoryType { minimum: 0, maximum: None, memory64: false, shared: false, page_size_log2: None },
        );
        imports.import("rt", "rt_alloc", we::EntityType::Function(0));
        m.section(&imports);
        // Imported func index: rt_alloc = 0.

        // The standalone runtime imports every driver entry point from `model`; the
        // emitter always exports them, so the stub must too or the merge leaves
        // unresolved `model.*` imports. Taken from the canonical list rather than
        // copied, so adding an entry point cannot leave this stub behind.
        // `simulate` aside, the entry points that are not `fn(SimData*)`.
        let two_arg = [
            openmodelica_sim_meta::driver::MODEL_FN_UPDATE_SYNC,
            openmodelica_sim_meta::driver::MODEL_FN_EQS_SYNC,
            openmodelica_sim_meta::driver::MODEL_FN_ZC,
            openmodelica_sim_meta::driver::MODEL_FN_DAE,
        ];
        let one_arg: Vec<&str> = openmodelica_sim_meta::driver::MODEL_FNS
            .iter()
            .copied()
            .filter(|n| *n != "simulate" && !two_arg.contains(n))
            .collect();

        let mut funcs = we::FunctionSection::new();
        for _ in &one_arg {
            funcs.function(1);
        }
        funcs.function(2); // om_meta_ptr
        funcs.function(2); // om_meta_len
        funcs.function(3); // simulate
        for _ in &two_arg {
            funcs.function(4);
        }
        funcs.function(5); // om_throw_model_error
        for _ in &one_arg {
            funcs.function(0); // <entry>$guard: (i32)->i32, like rt_alloc's type
        }
        m.section(&funcs);

        // Defined-func indices start at 1 (rt_alloc is import 0).
        let mut exports = we::ExportSection::new();
        for (i, name) in one_arg.iter().enumerate() {
            exports.export(name, we::ExportKind::Func, 1 + i as u32);
        }
        let meta_ptr_idx = 1 + one_arg.len() as u32;
        exports.export("om_meta_ptr", we::ExportKind::Func, meta_ptr_idx);
        exports.export("om_meta_len", we::ExportKind::Func, meta_ptr_idx + 1);
        exports.export("simulate", we::ExportKind::Func, meta_ptr_idx + 2);
        for (i, name) in two_arg.iter().enumerate() {
            exports.export(name, we::ExportKind::Func, meta_ptr_idx + 3 + i as u32);
        }
        exports.export(
            "om_throw_model_error",
            we::ExportKind::Func,
            meta_ptr_idx + 3 + two_arg.len() as u32,
        );
        // The adapter reaches the one-argument entry points only through their guards.
        let guard_base = meta_ptr_idx + 4 + two_arg.len() as u32;
        for (i, name) in one_arg.iter().enumerate() {
            exports.export(&format!("{name}$guard"), we::ExportKind::Func, guard_base + i as u32);
        }
        m.section(&exports);

        let mut code = we::CodeSection::new();
        for _ in &one_arg {
            let mut f = we::Function::new([]);
            f.instruction(&I::End);
            code.function(&f);
        }
        // om_meta_ptr(): rt_alloc(8) — exercises the model->rt import resolution.
        let mut ptr = we::Function::new([]);
        ptr.instruction(&I::I32Const(8));
        ptr.instruction(&I::Call(0));
        ptr.instruction(&I::End);
        code.function(&ptr);
        // om_meta_len(): 0.
        let mut len = we::Function::new([]);
        len.instruction(&I::I32Const(0));
        len.instruction(&I::End);
        code.function(&len);
        // simulate(...): return 0.
        let mut sim = we::Function::new([]);
        sim.instruction(&I::I32Const(0));
        sim.instruction(&I::End);
        code.function(&sim);
        // The two-argument entry points: noop.
        for _ in &two_arg {
            let mut f = we::Function::new([]);
            f.instruction(&I::End);
            code.function(&f);
        }
        // om_throw_model_error(): the emitter's no-external-"C" body.
        let mut throw = we::Function::new([]);
        throw.instruction(&I::Unreachable);
        throw.instruction(&I::End);
        code.function(&throw);
        // Each guard: nothing threw.
        for _ in &one_arg {
            let mut f = we::Function::new([]);
            f.instruction(&I::I32Const(0));
            f.instruction(&I::End);
            code.function(&f);
        }
        m.section(&code);

        m.finish()
    }

    /// Every adapter `env` import must be satisfied by the model or by the runtime
    /// linked into the adapter itself; an `env` host callback (`rt_host_log`) is an
    /// unresolved symbol here.
    #[test]
    fn fmu_component_links_without_a_host() {
        // Both ends of the selection have to resolve, for both adapters: each imports
        // every solver whatever its flags named.
        let all: Vec<&str> = SOLVER_LIBRARIES.iter().map(|l| l.name).collect();
        let mut cases: Vec<(&str, &[u8], Option<&[&str]>)> = Vec::new();
        if sundials_available() {
            for (label, adapter) in [("ME", FMI3_ME_ADAPTER), ("me_cs", FMI3_MECS_ADAPTER)] {
                cases.push((label, adapter, Some(&all)));
                cases.push((label, adapter, Some(&[])));
            }
        } else {
            cases.push(("ME", FMI3_ME_ADAPTER, None));
        }
        for (label, adapter, solvers) in cases {
            if adapter.is_empty() {
                continue; // omc built without the wasm32 toolchain
            }
            assert!(
                link_fmu_component(&build_stub_model(), adapter, solvers, &[], None).is_ok(),
                "{label} does not link into a component: {}",
                openmodelica_util::Error::printMessagesStr(false)
            );
        }
    }

    /// The mapping has to name `klu`, the shared core, whenever anything else is named.
    /// Only the integrator is Co-Simulation's alone: a Model Exchange FMU runs the same
    /// nonlinear and linear solvers during initialisation. A model with a sparse
    /// nonlinear system needs kinsol+KLU with no flag saying so.
    #[test]
    fn solver_libraries_follow_the_fmi_flags() {
        for (json, cs, sparse_nls, want) in [
            ("{}", true, false, vec![]),
            (r#"{"s":"euler"}"#, true, false, vec![]),
            (r#"{"s":"cvode"}"#, true, false, vec!["sundials_driver", "klu"]),
            (r#"{"s":"ida"}"#, true, false, vec!["sundials_driver", "klu"]),
            (r#"{"nls":"kinsol"}"#, true, false, vec!["kinsol", "klu"]),
            (r#"{"lss":"lis"}"#, true, false, vec!["lis", "klu"]),
            (r#"{"ls":"umfpack"}"#, true, false, vec!["umfpack", "klu"]),
            (r#"{"nlsLS":"klu"}"#, true, false, vec!["klu"]),
            (r#"{"ls":"lapack"}"#, true, false, vec![]),
            // ME: the same solvers, never the integrator.
            (r#"{"nls":"kinsol"}"#, false, false, vec!["kinsol", "klu"]),
            (r#"{"lss":"lis"}"#, false, false, vec!["lis", "klu"]),
            (r#"{"s":"cvode"}"#, false, false, vec![]),
            // The density rule's own choice, which no flag records.
            ("{}", false, true, vec!["kinsol", "klu"]),
            ("{}", true, true, vec!["kinsol", "klu"]),
            (r#"{"nls":"kinsol"}"#, true, true, vec!["kinsol", "klu"]),
            (r#"{"s":"ida"}"#, true, true, vec!["sundials_driver", "kinsol", "klu"]),
        ] {
            let method = cs_method_from(json, if cs { "CS" } else { "ME" }, false, "dassl");
            assert_eq!(
                fmu_solver_libraries(json, &method, cs, sparse_nls), want,
                "{json} cs={cs} sparse_nls={sparse_nls}"
            );
        }
        // Every name the mapping can produce must be a library that exists.
        let known: Vec<&str> = SOLVER_LIBRARIES.iter().map(|l| l.name).collect();
        let all = r#"{"s":"ida","nls":"kinsol","ls":"lis","lss":"umfpack"}"#;
        for name in fmu_solver_libraries(all, "ida", true, true) {
            assert!(known.contains(&name), "{name} is not a solver library");
        }
    }

    /// What the FMU applies when it instantiates, since an importer cannot pass flags.
    /// `-s` is not among them: it is the integrator, carried by `SimMeta::cs_method`.
    #[test]
    fn baked_solver_flags_come_from_the_fmi_flags() {
        assert_eq!(fmu_solver_flags("{}"), "");
        assert_eq!(fmu_solver_flags(r#"{"s":"cvode"}"#), "");
        assert_eq!(fmu_solver_flags(r#"{"nls":"kinsol"}"#), "-nls=kinsol");
        assert_eq!(
            fmu_solver_flags(r#"{"s":"ida","nls":"kinsol","lss":"klu"}"#),
            "-nls=kinsol -lss=klu"
        );
        // Whatever is baked has to parse, and be servable by the libraries the same
        // flags select.
        for json in [r#"{"nls":"kinsol"}"#, r#"{"ls":"lis"}"#, r#"{"lss":"umfpack"}"#,
                     r#"{"nlsLS":"klu"}"#] {
            let baked = fmu_solver_flags(json);
            let argv: Vec<String> = core::iter::once("model".to_string())
                .chain(baked.split_whitespace().map(str::to_string))
                .collect();
            let f = simflags::parse(&argv).expect(&baked);
            let libs =
                fmu_solver_libraries(json, &cs_method_from(json, "CS", false, "dassl"), true, false);
            let cap = simflags::Capabilities {
                klu: libs.contains(&"klu"),
                kinsol: libs.contains(&"kinsol"),
                umfpack: libs.contains(&"umfpack"),
                lis: libs.contains(&"lis"),
                ida: false,
                cvode: false,
                alarm: true,
                variable_filter: false,
                optimization: false,
                qss: true,
            };
            assert!(simflags::check(&f, cap).is_ok(), "{json}: {baked}");
        }
    }

    // The standalone-export merge validates the result with `wasmtime::Module`, so
    // it runs only under the default (wasmtime) engine.
    #[cfg(all(feature = "jit", not(feature = "engine-wasmer")))]
    #[test]
    fn merge_leaves_only_wasi_imports() {
        let merged = merge_standalone(&build_stub_model()).expect("wasm-merge should succeed");
        let engine = wasmtime::Engine::default();
        let module = wasmtime::Module::new(&engine, &merged).expect("merged module should validate");
        // After the merge the only remaining imports are the WASI surface the shim
        // (or `wasmtime run`) provides; every `rt.*`/`model.*` import is internalized.
        for imp in module.imports() {
            assert_eq!(
                imp.module(),
                "wasi_snapshot_preview1",
                "unexpected unresolved import {}::{}",
                imp.module(),
                imp.name()
            );
        }
        // And the command entry point survives the merge.
        assert!(module.get_export("_start").is_some(), "merged module must export `_start`");
    }
}
