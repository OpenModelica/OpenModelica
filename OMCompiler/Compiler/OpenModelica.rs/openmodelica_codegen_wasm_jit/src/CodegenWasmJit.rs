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
//     loop), so a whole run is a single host->wasm call with no per-step
//     boundary crossing. A second, host-driven driver (the Euler loop in native
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

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::sync::Arc;

use anyhow::{Result, anyhow, bail};
use arcstr::ArcStr;
use metamodelica::List;
use wasm_encoder as we;

use openmodelica_frontend_types::DAE;
use openmodelica_simcode_types::SimCode;
use openmodelica_simcode_types::SimCodeVar;
use openmodelica_simcode_types::SimCodeFunction;
use openmodelica_frontend_dump::ComponentReferenceBasics;

use crate::CodegenWasmJitFunctions::{
    ArrayGroup, BUILTINS, ENV_EXTRA, FnCtx, FnInfo, RT_BUILTINS, SimCtx, SimSlot, WTy,
    compile_function, compile_linear_system, compile_nonlinear_system, external_known,
    function_signature, rt_index, sim_cref_key,
};

// Engine selected at compile time; same module interface across all three
// (mirrors the block in CodegenWasmJitFunctions.rs, including the misconfig
// guards). The `SimModel` below stores compiled modules as `sim_runtime::Module`.
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
#[path = "CodegenWasmJit/sim_runtime_wasmtime.rs"]
mod sim_runtime;
#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
#[path = "CodegenWasmJit/sim_runtime_wasmer.rs"]
mod sim_runtime;
#[cfg(not(feature = "jit"))]
#[path = "CodegenWasmJit/sim_runtime_stub.rs"]
mod sim_runtime;

// The `wasi_snapshot_preview1` shim over `openmodelica_wasi`, for running the
// standalone wasip1 simulation command module. Not yet wired into the run path
// (its consumer — the merged standalone module — is a later step), so it is
// dead until then. The engine-independent `WasiCtx` is registered for both the
// wasmtime (native default) and wasmer (worker / native-wasmer) engines.
#[cfg(feature = "jit")]
#[path = "CodegenWasmJit/wasi_shim.rs"]
#[allow(dead_code)]
mod wasi_shim;

/// Iterate a MetaModelica `List` (which is `IntoIterator` by reference, not via
/// an `.iter()` method).
fn lst<T: Clone>(l: &Arc<List<T>>) -> impl Iterator<Item = &T> {
    (&**l).into_iter()
}

// ===========================================================================
// SimData layout
// ===========================================================================

/// Byte offset of `time` within `SimData`.
const TIME_OFF: u32 = 0;
/// Byte offset of the first real variable (`realVars[0]`, a state).
const REAL_OFF: u32 = 8;

/// Fully-resolved layout of one model's `SimData` block. All offsets are byte
/// offsets within the block; all are compile-time constants baked into the
/// generated module.
#[derive(Clone)]
struct SimLayout {
    n_states: u32,
    /// `algVars ++ discreteAlgVars` (the real algebraic variables emitted as
    /// time-variant result signals after the states and derivatives).
    n_real_alg: u32,
    rparam_off: u32,
    int_off: u32,
    iparam_off: u32,
    bool_off: u32,
    bparam_off: u32,
    /// String algebraic variables (one i32 String handle each).
    str_off: u32,
    /// String parameters (one i32 String handle each).
    sparam_off: u32,
    total: u32,
}

impl SimLayout {
    fn new(
        n_states: u32,
        n_real_alg: u32,
        n_real_param: u32,
        n_int_alg: u32,
        n_int_param: u32,
        n_bool_alg: u32,
        n_bool_param: u32,
        n_str_alg: u32,
        n_str_param: u32,
    ) -> Self {
        let n_real = 2 * n_states + n_real_alg; // states | ders | algs
        let rparam_off = REAL_OFF + n_real * 8;
        let int_off = rparam_off + n_real_param * 8;
        let iparam_off = int_off + n_int_alg * 4;
        let bool_off = iparam_off + n_int_param * 4;
        let bparam_off = bool_off + n_bool_alg * 4;
        let str_off = bparam_off + n_bool_param * 4;
        let sparam_off = str_off + n_str_alg * 4;
        let total = sparam_off + n_str_param * 4;
        SimLayout {
            n_states, n_real_alg, rparam_off, int_off, iparam_off, bool_off, bparam_off,
            str_off, sparam_off, total,
        }
    }

    /// Number of f64 in the real part of a result row: `time` + all real
    /// variables (states | derivatives | algebraics).
    fn n_reals_row(&self) -> u32 {
        1 + 2 * self.n_states + self.n_real_alg
    }
    /// Count of integer algebraic variables (the slots between `int_off` and
    /// `iparam_off`).
    fn n_int_alg(&self) -> u32 {
        (self.iparam_off - self.int_off) / 4
    }
    /// Count of boolean algebraic variables (between `bool_off` and `bparam_off`).
    fn n_bool_alg(&self) -> u32 {
        (self.bparam_off - self.bool_off) / 4
    }
    /// Total f64 columns in a result row: the real part followed by the integer
    /// and boolean algebraic variables (captured per row, as f64), so a varying
    /// Integer/Boolean is recorded over time rather than only at the end.
    fn n_row_total(&self) -> u32 {
        self.n_reals_row() + self.n_int_alg() + self.n_bool_alg()
    }
}

// ===========================================================================
// Result-variable metadata (held by the host, written into the `.mat`)
// ===========================================================================

/// How a result signal is stored in the `.mat` (which matrix + value source).
#[derive(Clone)]
enum ResultKind {
    /// The independent variable (`time`): data_2 row 1.
    Time,
    /// A time-variant real signal that reads result-buffer column `col` (0-based
    /// into the `[time | realVars]` row layout, so `col >= 1`). Several signals
    /// can reference the same column (alias variables) — the writer emits one
    /// data column and points each name at it (with `negate` for negated
    /// aliases), exactly like the C runtime's `dataInfo` aliasing.
    Column { col: u32, negate: bool },
    /// A time-invariant parameter read from `SimData` at byte offset `off`
    /// (`negate` for negated aliases of a parameter).
    Param { off: u32, wty: WTy, negate: bool },
    /// A compile-time constant (the `constVars`/`intConstVars`/`boolConstVars`
    /// lists, e.g. visualization colors): the value is known here, with no
    /// SimData slot, and is written directly to `data_1`.
    Const { value: f64 },
}

/// One signal in the result file (in C-compatible order: time, states,
/// derivatives, algebraics, then parameters).
#[derive(Clone)]
struct ResultVar {
    name: String,
    comment: String,
    kind: ResultKind,
}

/// A pending model-module compile. Native builds run it on a background thread
/// (overlapping the rest of the OMC pipeline); wasm has no threads, so it is
/// compiled eagerly and the result stored directly. [`sim_runtime`] takes it via
/// `take_compiled_model`, which joins on native and unwraps on wasm.
#[cfg(not(target_arch = "wasm32"))]
pub(crate) type ModelCompileJob = std::thread::JoinHandle<Result<sim_runtime::Module, String>>;
#[cfg(target_arch = "wasm32")]
pub(crate) type ModelCompileJob = Result<sim_runtime::Module, String>;

/// The prepared, ready-to-run artifact for one model, stashed in-process by
/// [`translateModel`] and consumed by [`runSimulation`] (keyed by file-name
/// prefix). This is the in-memory replacement for the C target's `_init.xml`
/// + `_info.json` + the built executable.
struct SimModel {
    wasm: Vec<u8>,
    layout: SimLayout,
    result_vars: Vec<ResultVar>,
    model_name: String,
    start_time: f64,
    stop_time: f64,
    n_intervals: u32,
    output_format: String,
    /// Integration method requested by `simulate(..., method=...)` (e.g.
    /// `"dassl"`, `"euler"`). Selects the driver in [`sim_runtime::run`].
    method: String,
    /// Relative/absolute tolerance for the adaptive integrators (DASSL).
    tolerance: f64,
    /// Background JIT job for the model module, spawned by [`translateModel`] so
    /// the (cranelift) compile overlaps the rest of the OMC pipeline instead of
    /// landing on `runSimulation`'s critical path. Joined by [`finishCompile`]
    /// (in `buildModel`'s compile phase) or, failing that, by `runSimulation`.
    compiled: Mutex<Option<ModelCompileJob>>,
    /// The compiled model module once [`finishCompile`] has joined the job, so
    /// `runSimulation` can instantiate without recompiling.
    prepared: Mutex<Option<sim_runtime::Module>>,
}

/// Process-wide table of prepared models, keyed by file-name prefix. Populated
/// by `translateModel` (during `callTargetTemplates`) and read by
/// `runSimulation` (during `simulate`) in the same process.
fn sim_models() -> &'static Mutex<HashMap<String, Arc<SimModel>>> {
    static MODELS: OnceLock<Mutex<HashMap<String, Arc<SimModel>>>> = OnceLock::new();
    MODELS.get_or_init(|| Mutex::new(HashMap::new()))
}

/// Write `bytes` to `path`: the OS filesystem natively, or the in-memory VFS on
/// wasm (where there is no filesystem — the `.wasm` dump, `.log` and result file
/// land there for the JS host / `getSimulationResult` to read back).
fn write_output(path: &str, bytes: &[u8]) -> std::io::Result<()> {
    #[cfg(target_arch = "wasm32")]
    {
        openmodelica_wasi::write(path, bytes.to_vec());
        Ok(())
    }
    #[cfg(not(target_arch = "wasm32"))]
    std::fs::write(path, bytes)
}

// ===========================================================================
// Public entry points (called from the MetaModelica sources after regen)
// ===========================================================================

/// `CodegenWasmJit.translateModel`: lower `simCode` to a model wasm module,
/// write `<prefix>.wasm`, and stash the prepared [`SimModel`] for the later
/// `runSimulation`. Counterpart of `CodegenC.translateModel` + the makefile/XML
/// machinery for the C target. Errors are fatal (a panic naming the reason),
/// matching `CodegenWasmJitFunctions.translateFunctions`.
pub fn translateModel(simCode: SimCode::SimCode) {
    // The runtime module is fixed and model-independent: start compiling it now,
    // on a background thread, so it overlaps the model-bytes generation in
    // `build_sim_model` below (and is cached for the run). Nothing else runs
    // between here and `runSimulation`, so this is the earliest useful point.
    sim_runtime::start_runtime_compile();
    let prefix = simCode.fileNamePrefix.to_string();
    let _ = std::fs::remove_file(format!("{prefix}.wasm"));
    match build_sim_model(&simCode) {
        Ok(model) => {
            // Write the module for inspection/debugging (mirrors the function
            // half writing `<name>.wasm`); the run itself uses the stashed bytes.
            if let Err(e) = write_output(&format!("{prefix}.wasm"), &model.wasm) {
                panic!("CodegenWasmJit: cannot write {prefix}.wasm: {e:#}");
            }
            sim_models().lock().unwrap().insert(prefix, Arc::new(model));
        }
        Err(e) => panic!("CodegenWasmJit: cannot build simulation module for `{prefix}`: {e:#}"),
    }
}

/// `CodegenWasmJit.runSimulation`: run the prepared model in-process and write
/// the result file. Returns 0 on success, 1 on failure (matching the exit code
/// the C target's executable would return, which `simulate` checks).
pub fn runSimulation(fileNamePrefix: ArcStr, resultFile: ArcStr, simflags: ArcStr) -> i32 {
    let res = run_simulation_inner(&fileNamePrefix, &resultFile, &simflags);
    // The simulate scripting flow reads `<prefix>.log` after a run (the C target's
    // executable writes one); write it here so the success path is taken. On
    // failure the log carries the error so it surfaces in the result `messages`.
    let log = match &res {
        Ok(()) => "LOG_SUCCESS       | info    | The initialization finished successfully without homotopy method.\n\
                    LOG_SUCCESS       | info    | The simulation finished successfully.\n"
            .to_string(),
        Err(e) => format!("LOG_ERROR         | error   | wasm-jit simulation failed: {e:#}\n"),
    };
    let _ = write_output(&format!("{fileNamePrefix}.log"), log.as_bytes());
    match res {
        Ok(()) => 0,
        Err(e) => {
            eprintln!("CodegenWasmJit: simulation of `{fileNamePrefix}` failed: {e:#}");
            1
        }
    }
}

/// `CodegenWasmJit.finishCompile`: force the model's wasm modules to finish
/// compiling. Called from `buildModel`'s compile phase (the wasm-jit counterpart
/// of `compileModel` building the C executable) so the JIT-compile cost is
/// measured as `timeCompile` rather than leaking into `timeSimulation`. It joins
/// the background model-module compile (started by `translateModel`) and forces
/// the runtime module (compiled-once / AOT-cached), stashing the compiled model
/// module for `runSimulation`. Errors are deferred — `runSimulation` recompiles
/// and reports them — so this never fails the build by itself.
pub fn finishCompile(fileNamePrefix: ArcStr) {
    let model = sim_models().lock().unwrap().get(&fileNamePrefix.to_string()).cloned();
    let Some(model) = model else { return };
    // Force the runtime module (so its compile/cache-load is in `timeCompile`).
    let _ = sim_runtime::runtime_module();
    // Join the background model-module compile and stash the result.
    match sim_runtime::take_compiled_model(&model) {
        Ok(m) => *model.prepared.lock().unwrap() = Some(m),
        Err(e) => eprintln!("CodegenWasmJit: model-module compile failed for `{fileNamePrefix}`: {e:#}"),
    }
}

/// `CodegenWasmJit.emitStandalone`: the `wasm` simCodeTarget's counterpart of
/// [`translateModel`]. Lower the model and `wasm-merge` it with the wasip1 runtime
/// into a self-contained WASI *command* module written to `<prefix>.wasm`, runnable
/// with `wasmtime run <prefix>.wasm --dir .::.` ([`runSimulationWasmtime`]). Unlike
/// `translateModel` it neither JIT-compiles nor stashes the model — the run is a
/// separate `wasmtime` process. Native only (the omc wasm build cannot `wasm-merge`).
pub fn emitStandalone(simCode: SimCode::SimCode) {
    let prefix = simCode.fileNamePrefix.to_string();
    let _ = std::fs::remove_file(format!("{prefix}.wasm"));
    #[cfg(target_arch = "wasm32")]
    {
        let _ = simCode;
        panic!("CodegenWasmJit: simCodeTarget=wasm (standalone export) is unavailable in the wasm omc build");
    }
    #[cfg(not(target_arch = "wasm32"))]
    match emit_standalone_module(&simCode) {
        Ok(bytes) => {
            if let Err(e) = write_output(&format!("{prefix}.wasm"), &bytes) {
                panic!("CodegenWasmJit: cannot write {prefix}.wasm: {e:#}");
            }
        }
        Err(e) => panic!("CodegenWasmJit: cannot build standalone module for `{prefix}`: {e:#}"),
    }
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
    match res {
        Ok(()) => 0,
        Err(e) => {
            eprintln!("CodegenWasmJit: wasmtime run of `{fileNamePrefix}` failed: {e:#}");
            1
        }
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn run_wasmtime_inner(prefix: &str, result_file: &str, _simflags: &str) -> Result<()> {
    use std::process::Command;
    let module = format!("{prefix}.wasm");
    if !std::path::Path::new(&module).exists() {
        bail!("standalone module `{module}` not found (emitStandalone not run?)");
    }
    let wasmtime = std::env::var("OMC_WASMTIME").unwrap_or_else(|_| "wasmtime".to_owned());
    // `--dir .::.` preopens the cwd as the guest `.`; the module writes the result
    // file there with a relative path.
    let status = Command::new(&wasmtime)
        .arg("run")
        .arg("--dir")
        .arg(".::.")
        .arg(&module)
        .status()
        .map_err(|e| anyhow!("cannot run `{wasmtime}` (is it on PATH? override with OMC_WASMTIME): {e}"))?;
    if !status.success() {
        bail!("`{wasmtime} run {module}` failed with {status}");
    }
    // The module writes `<prefix>_res.mat`; rename if omc selected another name.
    let produced = format!("{prefix}_res.mat");
    if result_file != produced && std::path::Path::new(&produced).exists() {
        std::fs::rename(&produced, result_file)
            .map_err(|e| anyhow!("cannot rename {produced} -> {result_file}: {e}"))?;
    }
    Ok(())
}

#[cfg(target_arch = "wasm32")]
fn run_wasmtime_inner(_prefix: &str, _result_file: &str, _simflags: &str) -> Result<()> {
    bail!("CodegenWasmJit: simCodeTarget=wasm is unavailable in the wasm omc build")
}

fn run_simulation_inner(prefix: &str, result_file: &str, _simflags: &str) -> Result<()> {
    let model = sim_models()
        .lock()
        .unwrap()
        .get(prefix)
        .cloned()
        .ok_or_else(|| anyhow!("no prepared wasm-jit model for `{prefix}` (translateModel not run?)"))?;
    // `empty` runs the integration but writes no result file — useful for
    // benchmarking the solver in isolation from the `.mat` writer.
    match model.output_format.as_str() {
        "mat" => {
            let run = sim_runtime::run(&model)?;
            write_mat4(&model, result_file, &run.rows, run.n_reals, &run.params)
        }
        "empty" => {
            sim_runtime::run(&model)?;
            Ok(())
        }
        other => bail!(
            "CodegenWasmJit: only the `mat` and `empty` output formats are supported (got `{other}`)"
        ),
    }
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
static RUNTIME_WASIP1: &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/runtime_wasip1.wasm"));

/// Emit a self-contained `wasm32-wasip1` *command* module for `sim_code`: lower
/// the model to its wasm module, then `wasm-merge` it with the standalone runtime
/// so the merged module's `_start` runs the whole simulation in-wasm and writes
/// `<prefix>_res.mat` over WASI (`wasmtime run <module> --dir .::.`). Native only —
/// `wasm-merge` is an external tool, absent in the omc wasm build.
#[cfg(not(target_arch = "wasm32"))]
pub fn emit_standalone_module(sim_code: &SimCode::SimCode) -> Result<Vec<u8>> {
    let model = build_sim_model(sim_code)?;
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
        bail!(
            "CodegenWasmJit: the wasip1 standalone runtime was not built \
             (run `rustup target add wasm32-wasip1` and rebuild, or set \
             OMC_WASM_RUNTIME_WASIP1=/path/to/runtime_wasip1.wasm)"
        );
    }
    let merge = std::env::var("OMC_WASM_MERGE").unwrap_or_else(|_| "wasm-merge".to_owned());

    let dir = std::env::temp_dir().join(format!(
        "om-wasm-merge-{}-{:p}",
        std::process::id(),
        model_wasm.as_ptr()
    ));
    std::fs::create_dir_all(&dir)?;
    let rt_path = dir.join("runtime.wasm");
    let model_path = dir.join("model.wasm");
    let out_path = dir.join("standalone.wasm");
    std::fs::write(&rt_path, RUNTIME_WASIP1)?;
    std::fs::write(&model_path, model_wasm)?;

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
        .map_err(|e| anyhow!("CodegenWasmJit: cannot run `{merge}`: {e}"))?;
    if !status.success() {
        bail!("CodegenWasmJit: `{merge}` failed with {status}");
    }
    let bytes = std::fs::read(&out_path)?;
    let _ = std::fs::remove_dir_all(&dir);
    Ok(bytes)
}

// ===========================================================================
// Building the variable->slot map and the result-variable list
// ===========================================================================

/// The data the equation-function lowering needs to resolve component
/// references: the cref->slot map and the per-variable start expressions.
struct SimVarMap {
    vars: HashMap<String, SimSlot>,
    starts: HashMap<String, Option<Arc<DAE::Exp>>>,
    /// Finalized array-variable groups (base cref key -> contiguous slot range).
    array_groups: HashMap<String, ArrayGroup>,
    /// Transient accumulator: base cref key -> the scalarized elements seen
    /// (subscripts, byte offset, value type). Finalized into `array_groups` at the
    /// end of [`build_var_map`].
    array_acc: HashMap<String, Vec<(Vec<i32>, u32, WTy)>>,
}

/// Display name of a model variable's component reference (OMC `.`-separated
/// form, e.g. `body.r[1]`).
fn cref_display(cr: &Arc<DAE::ComponentRef>) -> Result<String> {
    Ok(ComponentReferenceBasics::printComponentRefStr(cr.clone())?.to_string())
}

/// Whether a variable is emitted to the result file, matching the C runtime's
/// default selection: drop protected variables and `annotation(HideResult=true)`.
fn is_result_output(sv: &SimCodeVar::SimVar) -> bool {
    !sv.isProtected && sv.hideResult != Some(true)
}

/// Map a raw cref display name to the name it carries in the result file, or
/// `None` to drop it. The new backend names a derivative of a non-state variable
/// `$DER.x`; the C runtime shows it as `der(x)`. Other `$`-prefixed names are
/// backend-internal auxiliaries (`$cse*`, `$PRE*`, …) and are not output.
fn result_name(raw: &str) -> Option<String> {
    if let Some(rest) = raw.strip_prefix("$DER.") {
        Some(format!("der({rest})"))
    } else if raw.starts_with('$') {
        None
    } else {
        Some(raw.to_string())
    }
}

/// Evaluate a constant variable's binding to a scalar, for the `*ConstVars`
/// lists (which have no SimData slot). Handles the literal forms model constants
/// actually take (numbers, booleans, enums, and unary minus thereof).
fn const_value(exp: &Option<Arc<DAE::Exp>>) -> Option<f64> {
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
fn kind_from_slot(off: u32, wty: WTy, negate: bool, heap: bool, layout: &SimLayout) -> Option<ResultKind> {
    if heap {
        return None; // strings are not stored as numeric result data
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

/// Inverse of the `Column` assignment in [`kind_from_slot`]: the SimData byte
/// offset a result-buffer column reads from.
fn col_to_off(col: u32, layout: &SimLayout) -> u32 {
    let nr = layout.n_reals_row();
    if col < nr {
        REAL_OFF + (col - 1) * 8
    } else if col < nr + layout.n_int_alg() {
        layout.int_off + (col - nr) * 4
    } else {
        layout.bool_off + (col - nr - layout.n_int_alg()) * 4
    }
}

/// Build the cref->slot map and the result-variable list from the model's
/// `SimVars`. The slot offsets follow [`SimLayout`]; the result order matches
/// the C runtime (time, states, state derivatives, real algebraics, then
/// parameters) so the `.mat` reads back identically.
fn build_var_map(
    vars: &SimCodeVar::SimVars,
    layout: &SimLayout,
) -> Result<(SimVarMap, Vec<ResultVar>)> {
    let mut map = SimVarMap {
        vars: HashMap::new(),
        starts: HashMap::new(),
        array_groups: HashMap::new(),
        array_acc: HashMap::new(),
    };
    let mut result_vars: Vec<ResultVar> = Vec::new();

    // time — result signal 0.
    result_vars.push(ResultVar {
        name: "time".to_string(),
        comment: "Simulation time [s]".to_string(),
        kind: ResultKind::Time,
    });

    let states: Vec<&SimCodeVar::SimVar> = lst(&vars.stateVars).collect();
    let ders: Vec<&SimCodeVar::SimVar> = lst(&vars.derivativeVars).collect();

    // Protected/hidden primaries that were filtered out, kept as (name, comment,
    // off, wty, heap) so they can be re-emitted at the end if a non-protected
    // output ends up sharing their data slot (an alias-group member the C runtime
    // keeps in the result).
    let mut filtered: Vec<(String, String, u32, WTy, bool)> = Vec::new();

    // Push a primary (non-alias) variable: always register its slot (equations
    // reference even protected/internal vars), but only emit it as a result
    // signal if it passes the C-compatible filter (else stash it in `filtered`).
    let mut push_primary =
        |map: &mut SimVarMap, result_vars: &mut Vec<ResultVar>, filtered: &mut Vec<(String, String, u32, WTy, bool)>,
         sv: &SimCodeVar::SimVar, off: u32, wty: WTy, heap: bool, raw_name: String| -> Result<()> {
            insert_var(map, sv, off, wty, heap)?;
            if let Some(name) = result_name(&raw_name) {
                if is_result_output(sv) {
                    if let Some(kind) = kind_from_slot(off, wty, false, heap, layout) {
                        result_vars.push(ResultVar { name, comment: sv.comment.to_string(), kind });
                    }
                } else {
                    filtered.push((name, sv.comment.to_string(), off, wty, heap));
                }
            }
            Ok(())
        };

    // States | derivatives | real algebraics -> the realVars region (data_2).
    for (i, sv) in states.iter().enumerate() {
        let name = cref_display(&sv.name)?;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, REAL_OFF + (i as u32) * 8, WTy::F64, false, name)?;
    }
    for (i, sv) in ders.iter().enumerate() {
        // der(x) is displayed as `der(<state name>)`.
        let name = match states.get(i) {
            Some(s) => format!("der({})", cref_display(&s.name)?),
            None => cref_display(&sv.name)?,
        };
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, REAL_OFF + (layout.n_states + i as u32) * 8, WTy::F64, false, name)?;
    }
    let real_algs: Vec<&SimCodeVar::SimVar> =
        lst(&vars.algVars).chain(lst(&vars.discreteAlgVars)).collect();
    for (j, sv) in real_algs.iter().enumerate() {
        let name = cref_display(&sv.name)?;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, REAL_OFF + (2 * layout.n_states + j as u32) * 8, WTy::F64, false, name)?;
    }

    // Real / Integer / Boolean parameters -> data_1. Integer & Boolean algebraic
    // variables get slots (for equation resolution) but no result column yet
    // (they are not captured per row); strings get slots only.
    for (k, sv) in lst(&vars.paramVars).enumerate() {
        let name = cref_display(&sv.name)?;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, layout.rparam_off + (k as u32) * 8, WTy::F64, false, name)?;
    }
    for (i, sv) in lst(&vars.intAlgVars).enumerate() {
        let name = cref_display(&sv.name)?;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, layout.int_off + (i as u32) * 4, WTy::I32, false, name)?;
    }
    for (k, sv) in lst(&vars.intParamVars).enumerate() {
        let name = cref_display(&sv.name)?;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, layout.iparam_off + (k as u32) * 4, WTy::I32, false, name)?;
    }
    for (i, sv) in lst(&vars.boolAlgVars).enumerate() {
        let name = cref_display(&sv.name)?;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, layout.bool_off + (i as u32) * 4, WTy::I32, false, name)?;
    }
    for (k, sv) in lst(&vars.boolParamVars).enumerate() {
        let name = cref_display(&sv.name)?;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, layout.bparam_off + (k as u32) * 4, WTy::I32, false, name)?;
    }
    for (i, sv) in lst(&vars.stringAlgVars).enumerate() {
        insert_var(&mut map, sv, layout.str_off + (i as u32) * 4, WTy::I32, true)?;
    }
    for (k, sv) in lst(&vars.stringParamVars).enumerate() {
        insert_var(&mut map, sv, layout.sparam_off + (k as u32) * 4, WTy::I32, true)?;
    }

    // Compile-time constants (real / integer / boolean): no SimData slot — their
    // value is the binding literal. Emit each to data_1 (the C runtime keeps them
    // in the result too, e.g. visualization colors). Record their values so a
    // constant's aliases resolve below.
    let mut const_of: HashMap<String, f64> = HashMap::new();
    for sv in lst(&vars.constVars).chain(lst(&vars.intConstVars)).chain(lst(&vars.boolConstVars)) {
        let Some(value) = const_value(&sv.initialValue) else { continue };
        const_of.insert(sim_cref_key(&sv.name)?, value);
        if is_result_output(sv) {
            if let Some(name) = result_name(&cref_display(&sv.name)?) {
                result_vars.push(ResultVar { name, comment: sv.comment.to_string(), kind: ResultKind::Const { value } });
            }
        }
    }

    // Aliases: resolve to the target variable's slot (with negation) so equations
    // and `$START` of an alias read the aliased value, AND emit the alias as a
    // result signal pointing at the target's data column / parameter (with sign)
    // — the C runtime's `dataInfo` aliasing, so the data is stored once.
    for av in lst(&vars.aliasVars).chain(lst(&vars.intAliasVars)).chain(lst(&vars.boolAliasVars)) {
        let (target, negate) = match &av.aliasvar {
            SimCodeVar::AliasVariable::ALIAS { varName } => (varName.clone(), false),
            SimCodeVar::AliasVariable::NEGATEDALIAS { varName } => (varName.clone(), true),
            SimCodeVar::AliasVariable::NOALIAS => continue,
        };
        let tkey = sim_cref_key(&target)?;
        let Some(tslot) = map.vars.get(&tkey).copied() else {
            // Target has no slot: it may be a compile-time constant.
            if let Some(&cval) = const_of.get(&tkey) {
                if is_result_output(av) {
                    if let Some(name) = result_name(&cref_display(&av.name)?) {
                        let value = if negate { -cval } else { cval };
                        result_vars.push(ResultVar { name, comment: av.comment.to_string(), kind: ResultKind::Const { value } });
                    }
                }
            }
            continue;
        };
        let slot = SimSlot {
            off: tslot.off,
            wty: tslot.wty,
            negate: tslot.negate ^ negate,
            heap: tslot.heap,
        };
        map.vars.insert(sim_cref_key(&av.name)?, slot);
        if is_result_output(av) {
            if let (Some(name), Some(kind)) = (
                result_name(&cref_display(&av.name)?),
                kind_from_slot(slot.off, slot.wty, slot.negate, slot.heap, layout),
            ) {
                result_vars.push(ResultVar { name, comment: av.comment.to_string(), kind });
            }
        }
    }

    // Re-emit a filtered (protected/hidden) variable if a non-protected output
    // references its data slot — i.e. it is an alias-group member of an output
    // variable, which the C runtime keeps in the result (e.g. a protected
    // parameter aliased by a public connector variable).
    let referenced: std::collections::HashSet<u32> = result_vars
        .iter()
        .filter_map(|v| match &v.kind {
            ResultKind::Column { col, .. } => Some(col_to_off(*col, layout)),
            ResultKind::Param { off, .. } => Some(*off),
            _ => None,
        })
        .collect();
    for (name, comment, off, wty, heap) in filtered {
        if referenced.contains(&off) {
            if let Some(kind) = kind_from_slot(off, wty, false, heap, layout) {
                result_vars.push(ResultVar { name, comment, kind });
            }
        }
    }

    finalize_array_groups(&mut map)?;
    Ok((map, result_vars))
}

/// Register one variable's slot (by canonical cref key) and its start value. If
/// the variable is a scalarized array element (`base[c1,…,cn]`), also record it
/// under its array base name so a whole-array reference can later be marshalled.
fn insert_var(map: &mut SimVarMap, sv: &SimCodeVar::SimVar, off: u32, wty: WTy, heap: bool) -> Result<()> {
    let key = sim_cref_key(&sv.name)?;
    map.vars.insert(key.clone(), SimSlot { off, wty, negate: false, heap });
    map.starts.insert(key, sv.initialValue.clone());
    if let Some((base, subs)) = array_element_of(&sv.name)? {
        map.array_acc.entry(base).or_default().push((subs, off, wty));
    }
    Ok(())
}

/// If `cr` is a scalarized array element `base[c1,…,cn]` — the subscripts on the
/// *final* component, all constant integers, with every ancestor component
/// unsubscripted — return `(base cref key, subscripts)`. Returns `None` for a
/// plain scalar, a non-constant subscript, or a subscript on an intermediate
/// component (an array of records, handled element-wise instead).
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
                if !subscriptLst.is_empty() {
                    return Ok(None);
                }
                base.push_str(ident);
                base.push('.');
                node = componentRef;
            }
            _ => return Ok(None),
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
fn finalize_array_groups(map: &mut SimVarMap) -> Result<()> {
    let acc = std::mem::take(&mut map.array_acc);
    for (base, elems) in acc {
        let rank = elems[0].0.len();
        if elems.iter().any(|(s, _, _)| s.len() != rank) {
            bail!("CodegenWasmJit: inconsistent subscript rank for array variable `{base}`");
        }
        // Shape: 1-based max index per axis.
        let mut dims = vec![0u32; rank];
        for (subs, _, _) in &elems {
            for (axis, &ix) in subs.iter().enumerate() {
                if ix < 1 {
                    bail!("CodegenWasmJit: non-positive subscript {ix} for array variable `{base}`");
                }
                dims[axis] = dims[axis].max(ix as u32);
            }
        }
        let total: u32 = dims.iter().product();
        if total as usize != elems.len() {
            // Not all elements present (e.g. a sub-slice is its own variable):
            // cannot treat as one contiguous whole-array. Skip; a whole-array
            // reference then fails loudly with "unknown variable".
            continue;
        }
        let wty = elems[0].2;
        if elems.iter().any(|(_, _, w)| *w != wty) {
            bail!("CodegenWasmJit: mixed element types for array variable `{base}`");
        }
        let stride = match wty { WTy::F64 => 8, WTy::I32 => 4 };
        let base_off = elems.iter().map(|(_, o, _)| *o).min().unwrap();
        // Verify contiguous, row-major layout.
        for (subs, off, _) in &elems {
            let mut lin: u32 = 0;
            for (axis, &ix) in subs.iter().enumerate() {
                lin = lin * dims[axis] + (ix as u32 - 1);
            }
            let expected = base_off + lin * stride;
            if *off != expected {
                bail!(
                    "CodegenWasmJit: array variable `{base}` is not laid out contiguously in \
                     row-major order (element {subs:?} at offset {off}, expected {expected}); \
                     whole-array marshalling needs a contiguous slot range"
                );
            }
        }
        map.array_groups.insert(base, ArrayGroup { base_off, wty, dims, total });
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
}

fn build_sim_model(sim_code: &SimCode::SimCode) -> Result<SimModel> {
    let mi = &sim_code.modelInfo;
    let vi = &mi.varInfo;
    let vars = &mi.vars;

    let n_states = vi.numStateVars.max(0) as u32;
    let n_real_alg = (count(&vars.algVars) + count(&vars.discreteAlgVars)) as u32;
    let n_real_param = count(&vars.paramVars) as u32;
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
    );

    let (var_map, result_vars) = build_var_map(vars, &layout)?;

    // Index -> equation map (for SES_ALIAS, which re-runs another equation by
    // index). An alias may point at an equation defined in a different system
    // list than the one being lowered (e.g. a parameter-equation alias to an
    // initial equation), so index every list. `eqFunction_<n>` is emitted once in
    // the C target and shared; here the target equation is inlined.
    let mut eq_index: HashMap<i32, Arc<SimCode::SimEqSystem>> = HashMap::new();
    let mut index_list = |eqs: &Arc<List<Arc<SimCode::SimEqSystem>>>, idx: &mut HashMap<i32, Arc<SimCode::SimEqSystem>>| {
        for e in lst(eqs) {
            idx.entry(eq_index_of(e)).or_insert_with(|| e.clone());
        }
    };
    index_list(&sim_code.allEquations, &mut eq_index);
    index_list(&sim_code.initialEquations, &mut eq_index);
    index_list(&sim_code.removedInitialEquations, &mut eq_index);
    index_list(&sim_code.parameterEquations, &mut eq_index);
    index_list(&sim_code.removedEquations, &mut eq_index);
    index_list(&sim_code.startValueEquations, &mut eq_index);
    for part in lst(&sim_code.odeEquations).chain(lst(&sim_code.algebraicEquations)) {
        index_list(part, &mut eq_index);
    }

    // --- Collect the model's Modelica functions (callable from equations). ---
    let model_fns: Vec<&SimCodeFunction::Function::Function> = lst(&mi.functions)
        .map(|f| &**f)
        .filter(|f| {
            matches!(f, SimCodeFunction::Function::Function::FUNCTION { .. }) || external_known(f)
        })
        .collect();

    // Function index space: imports (env builtins, rt runtime, env-extra), then
    // the model's Modelica functions, then the generated equation functions.
    let import_base = (BUILTINS.len() + RT_BUILTINS.len() + ENV_EXTRA.len()) as u32;
    let mut by_name: HashMap<String, FnInfo> = HashMap::new();
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
    };
    let simulate_idx = eq_base + 4;
    // The two metadata accessors the standalone wasip1 runtime imports
    // (`om_meta_ptr`/`om_meta_len`), appended after `simulate`.
    let om_meta_ptr_idx = eq_base + 5;
    let om_meta_len_idx = eq_base + 6;

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

    // --- Compile bodies (collecting String literals into the module pool). ---
    let mut literals: Vec<Vec<u8>> = Vec::new();
    let mut bodies: Vec<we::Function> = Vec::new();
    // Model functions first, in index order.
    for f in &model_fns {
        bodies.push(compile_function(f, &by_name, &mut literals)?);
    }
    // Parameter bindings (`parameter Real c = 0.5`) are not in
    // `parameterEquations` for constant bindings — the C target reads them from
    // `_init.xml`. Initialize every parameter from its binding expression
    // (`SimVar.initialValue`) in declaration order (the backend sorts dependent
    // parameters so a binding only references earlier ones), then run
    // `parameterEquations` for any computed parameters.
    let param_bindings = collect_param_bindings(vars);

    // Equation functions.
    bodies.push(build_eq_fn_with_prelude("parameterEquations", &param_bindings, flatten_eqs(&sim_code.parameterEquations), &var_map, &eq_index, &by_name, &mut literals)?);
    bodies.push(build_eq_fn("initialEquations", flatten_eqs(&sim_code.initialEquations), &var_map, &eq_index, &by_name, &mut literals)?);
    bodies.push(build_eq_fn("odeEquations", flatten_eqs_ll(&sim_code.odeEquations), &var_map, &eq_index, &by_name, &mut literals)?);
    bodies.push(build_eq_fn("algebraicEquations", flatten_eqs_ll(&sim_code.algebraicEquations), &var_map, &eq_index, &by_name, &mut literals)?);
    // The integrator loop.
    bodies.push(build_simulate(&layout, &eqfn));

    // --- Standalone-export metadata: encode the SimData layout, the run settings
    // and the result variables into a blob the standalone wasip1 runtime decodes
    // (via the `om_meta_ptr`/`om_meta_len` exports). It rides in the last passive
    // data segment and is materialized at run time into a runtime-allocated buffer
    // with `memory.init`, exactly like a String literal. These accessors are
    // harmless on the JIT path (unused). ---
    let settings = sim_code
        .simulationSettingsOpt
        .as_ref()
        .ok_or_else(|| anyhow!("CodegenWasmJit: model has no simulation settings"))?;
    let model_name = openmodelica_frontend_dump::AbsynUtil::pathString(mi.name.clone(), arcstr::literal!("."), true, false)?.to_string();
    let meta_bytes = openmodelica_sim_meta::encode(&build_sim_meta(&layout, &result_vars, settings, &model_name, &sim_code.fileNamePrefix));
    let meta_len = meta_bytes.len() as u32;
    let meta_seg = literals.len() as u32;
    literals.push(meta_bytes);
    {
        // om_meta_ptr(): rt_alloc(len), memory.init the blob into it, return ptr.
        use we::Instruction as I;
        let mut f = we::Function::new([(1, we::ValType::I32)]);
        f.instruction(&I::I32Const(meta_len as i32));
        f.instruction(&I::Call(rt_index("rt_alloc")));
        f.instruction(&I::LocalTee(0));
        f.instruction(&I::I32Const(0));
        f.instruction(&I::I32Const(meta_len as i32));
        f.instruction(&I::MemoryInit { mem: 0, data_index: meta_seg });
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

    // --- Function section (type index per body, in body order). ---
    let mut functions = we::FunctionSection::new();
    for ti in &model_fn_type {
        functions.function(*ti);
    }
    for _ in 0..4 {
        functions.function(eqfn_type);
    }
    functions.function(simulate_type);
    functions.function(meta_fn_type); // om_meta_ptr
    functions.function(meta_fn_type); // om_meta_len

    // --- Code section. ---
    let mut code = we::CodeSection::new();
    for body in &bodies {
        code.function(body);
    }

    // --- Exports: the equation functions (for the host-driven driver) and
    // `simulate` (for the in-wasm driver). ---
    let mut exports = we::ExportSection::new();
    exports.export("functionParameters", we::ExportKind::Func, eqfn.parameters);
    exports.export("functionInitialEquations", we::ExportKind::Func, eqfn.initial);
    exports.export("functionODE", we::ExportKind::Func, eqfn.ode);
    exports.export("functionAlgebraics", we::ExportKind::Func, eqfn.algebraics);
    exports.export("simulate", we::ExportKind::Func, simulate_idx);
    exports.export("om_meta_ptr", we::ExportKind::Func, om_meta_ptr_idx);
    exports.export("om_meta_len", we::ExportKind::Func, om_meta_len_idx);

    let mut module = we::Module::new();
    module.section(&types);
    module.section(&imports);
    module.section(&functions);
    module.section(&exports);
    if !literals.is_empty() {
        module.section(&we::DataCountSection { count: literals.len() as u32 });
    }
    module.section(&code);
    if !literals.is_empty() {
        let mut data = we::DataSection::new();
        for lit in &literals {
            data.passive(lit.iter().copied());
        }
        module.section(&data);
    }
    let wasm = module.finish();

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
    #[cfg(not(target_arch = "wasm32"))]
    let compiled = Mutex::new(Some(std::thread::spawn(move || {
        sim_runtime::compile_model_module(&compile_wasm).map_err(|e| format!("{e:#}"))
    })));
    #[cfg(target_arch = "wasm32")]
    let compiled = Mutex::new(Some(
        sim_runtime::compile_model_module(&compile_wasm).map_err(|e| format!("{e:#}")),
    ));

    Ok(SimModel {
        wasm,
        compiled,
        prepared: Mutex::new(None),
        layout,
        result_vars,
        model_name,
        start_time: settings.startTime.into_inner(),
        stop_time: settings.stopTime.into_inner(),
        n_intervals: settings.numberOfIntervals.max(0) as u32,
        output_format: settings.outputFormat.to_string(),
        method: settings.method.to_string(),
        tolerance: settings.tolerance.into_inner(),
    })
}

/// Build the [`openmodelica_sim_meta::SimMeta`] embedded in the model module
/// (decoded by the standalone wasip1 runtime's `_start`) from the resolved
/// layout, result variables and run settings. The lean `MatKind`-equivalent
/// `Param` keeps its `SimData` offset/type so the runtime reads the value back.
fn build_sim_meta(
    layout: &SimLayout,
    result_vars: &[ResultVar],
    settings: &SimCode::SimulationSettings,
    model_name: &str,
    prefix: &str,
) -> openmodelica_sim_meta::SimMeta {
    use openmodelica_sim_meta as sm;
    sm::SimMeta {
        layout: sm::Layout {
            n_states: layout.n_states,
            n_real_alg: layout.n_real_alg,
            rparam_off: layout.rparam_off,
            int_off: layout.int_off,
            iparam_off: layout.iparam_off,
            bool_off: layout.bool_off,
            bparam_off: layout.bparam_off,
            str_off: layout.str_off,
            sparam_off: layout.sparam_off,
            total: layout.total,
        },
        start_time: settings.startTime.into_inner(),
        stop_time: settings.stopTime.into_inner(),
        n_intervals: settings.numberOfIntervals.max(0) as u32,
        method: settings.method.to_string(),
        tolerance: settings.tolerance.into_inner(),
        output_format: settings.outputFormat.to_string(),
        prefix: prefix.to_string(),
        model_name: model_name.to_string(),
        vars: result_vars
            .iter()
            .map(|v| sm::MetaVar {
                name: v.name.clone(),
                comment: v.comment.clone(),
                kind: match &v.kind {
                    ResultKind::Time => sm::MetaKind::Time,
                    ResultKind::Column { col, negate } => sm::MetaKind::Column { col: *col, negate: *negate },
                    ResultKind::Param { off, wty, negate } => sm::MetaKind::Param {
                        off: *off,
                        wty: match wty {
                            WTy::F64 => sm::WTy::F64,
                            WTy::I32 => sm::WTy::I32,
                        },
                        negate: *negate,
                    },
                    ResultKind::Const { value } => sm::MetaKind::Const { value: *value },
                },
            })
            .collect(),
    }
}

/// A fresh `T_REAL` type for synthesizing the lhs `CREF` expression of a simple
/// assignment (the type is not consulted on the simulation cref path).
fn t_real() -> Arc<DAE::Type> {
    Arc::new(DAE::Type::T_REAL { varLst: metamodelica::nil() })
}

fn count<T: Clone>(list: &Arc<List<T>>) -> usize {
    lst(list).count()
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

/// Build one equation function (`SimData* -> ()`), lowering each equation in
/// order. Unsupported equation kinds (systems, array assigns) fail loudly so a
/// model that needs them is rejected rather than silently mis-simulated.
/// Collect parameter binding assignments (`cref := initialValue`) from all
/// parameter `SimVar`s that have a binding, in declaration order.
fn collect_param_bindings(vars: &SimCodeVar::SimVars) -> Vec<(Arc<DAE::ComponentRef>, Arc<DAE::Exp>)> {
    let mut out = Vec::new();
    for p in lst(&vars.paramVars)
        .chain(lst(&vars.intParamVars))
        .chain(lst(&vars.boolParamVars))
        .chain(lst(&vars.stringParamVars))
    {
        if let Some(v) = &p.initialValue {
            out.push((p.name.clone(), v.clone()));
        }
    }
    out
}

fn build_eq_fn(
    which: &str,
    eqs: Vec<Arc<SimCode::SimEqSystem>>,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Vec<Vec<u8>>,
) -> Result<we::Function> {
    build_eq_fn_with_prelude(which, &[], eqs, var_map, eq_index, by_name, literals)
}

fn build_eq_fn_with_prelude(
    which: &str,
    prelude: &[(Arc<DAE::ComponentRef>, Arc<DAE::Exp>)],
    eqs: Vec<Arc<SimCode::SimEqSystem>>,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Vec<Vec<u8>>,
) -> Result<we::Function> {
    let sim = SimCtx {
        data_local: 0,
        vars: var_map.vars.clone(),
        starts: var_map.starts.clone(),
        array_groups: var_map.array_groups.clone(),
    };
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    for (cref, exp) in prelude {
        let lhs = DAE::Exp::CREF { componentRef: cref.clone(), ty: t_real() };
        ctx.sim_assign(&lhs, exp).map_err(|e| anyhow!("in {which} binding: {e}"))?;
    }
    for eq in &eqs {
        lower_equation(&mut ctx, eq, eq_index)
            .map_err(|e| anyhow!("in {which}: {e}"))?;
    }
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Lower a single `SimEqSystem` into the current equation function.
fn lower_equation(
    ctx: &mut FnCtx,
    eq: &SimCode::SimEqSystem,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    use SimCode::SimEqSystem as E;
    match eq {
        E::SES_SIMPLE_ASSIGN { cref, exp, .. } => {
            let lhs = DAE::Exp::CREF { componentRef: cref.clone(), ty: t_real() };
            ctx.sim_assign(&lhs, exp)
        }
        // A whole-array assignment `lhs := exp` (lhs is already a cref expression,
        // exp an array-valued expression). For a model array variable this routes
        // through the whole-array scatter in `compile_sim_cref_assign`.
        E::SES_ARRAY_CALL_ASSIGN { lhs, exp, .. } => ctx.sim_assign(lhs, exp),
        E::SES_LINEAR { lSystem, .. } => lower_linear_system(ctx, lSystem, eq_index),
        E::SES_NONLINEAR { nlSystem, .. } => lower_nonlinear_system(ctx, nlSystem, eq_index),
        E::SES_ALGORITHM { statements, .. } => ctx.sim_stmts(statements),
        // An alias equation re-runs another equation (by index): inline it.
        E::SES_ALIAS { aliasOf, .. } => {
            let target = eq_index
                .get(aliasOf)
                .ok_or_else(|| anyhow!("SES_ALIAS references unknown equation index {aliasOf}"))?
                .clone();
            lower_equation(ctx, &target, eq_index)
        }
        other => bail!(
            "CodegenWasmJit: unsupported equation kind in simulation (only simple assignments and \
             algorithms are handled so far): {} (index {})",
            eq_kind_name(other),
            eq_index_of(other),
        ),
    }
}

/// Lower a `SES_LINEAR` (torn) system. The `residual` list is partitioned into
/// the inner constraint equations (which compute the torn variables from the
/// iteration unknowns) and the `SES_RESIDUAL` residual expressions; the unknowns
/// are `lSystem.vars`. The numerical-Jacobian assembly + solve + scatter is in
/// [`compile_linear_system`]; here we just supply the unknowns, residual
/// expressions, and a closure that lowers the inner equations (re-invoked for
/// each residual probe).
fn lower_linear_system(
    ctx: &mut FnCtx,
    lsystem: &SimCode::LinearSystem,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    use SimCode::SimEqSystem as E;
    let mut inner: Vec<Arc<SimCode::SimEqSystem>> = Vec::new();
    let mut res_exps: Vec<&Arc<DAE::Exp>> = Vec::new();
    for e in lst(&lsystem.residual) {
        match &**e {
            E::SES_RESIDUAL { exp, .. } => res_exps.push(exp),
            _ => inner.push(e.clone()),
        }
    }
    if res_exps.is_empty() {
        // No residual equations: this is the non-torn symbolic form (A from
        // `simJac`, b from `beqs`), which is not yet lowered. The torn/residual
        // form is what the in-scope models use.
        bail!(
            "CodegenWasmJit: SES_LINEAR (index {}) has no residual equations — the symbolic \
             simJac/beqs form is not yet supported",
            lsystem.index
        );
    }
    let iter_vars: Vec<Arc<DAE::ComponentRef>> = lst(&lsystem.vars).map(|v| v.name.clone()).collect();
    let mut lower_inner = |c: &mut FnCtx| -> Result<()> {
        for eq in &inner {
            lower_equation(c, eq, eq_index)?;
        }
        Ok(())
    };
    compile_linear_system(ctx, &iter_vars, &res_exps, &mut lower_inner)
}

/// Lower a `SES_NONLINEAR` (torn) system. Like [`lower_linear_system`], partition
/// `nlSystem.eqs` into the inner constraint equations (which compute the torn
/// variables from the iteration unknowns) and the `SES_RESIDUAL` residual
/// expressions; the iteration unknowns are `nlSystem.crefs`. The Newton solve is
/// in [`compile_nonlinear_system`]. The optional symbolic Jacobian
/// (`nlSystem.jacobianMatrix`) is not used — the solver computes the Jacobian
/// numerically, like the linear system's residual probing.
fn lower_nonlinear_system(
    ctx: &mut FnCtx,
    nlsystem: &SimCode::NonlinearSystem,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
) -> Result<()> {
    use SimCode::SimEqSystem as E;
    let mut inner: Vec<Arc<SimCode::SimEqSystem>> = Vec::new();
    let mut res_exps: Vec<&Arc<DAE::Exp>> = Vec::new();
    for e in lst(&nlsystem.eqs) {
        match &**e {
            E::SES_RESIDUAL { exp, .. } => res_exps.push(exp),
            _ => inner.push(e.clone()),
        }
    }
    if res_exps.is_empty() {
        bail!(
            "CodegenWasmJit: SES_NONLINEAR (index {}) has no residual equations",
            nlsystem.index
        );
    }
    let iter_vars: Vec<Arc<DAE::ComponentRef>> = lst(&nlsystem.crefs).cloned().collect();
    let mut lower_inner = |c: &mut FnCtx| -> Result<()> {
        for eq in &inner {
            lower_equation(c, eq, eq_index)?;
        }
        Ok(())
    };
    compile_nonlinear_system(ctx, &iter_vars, &res_exps, &mut lower_inner)
}

fn eq_kind_name(eq: &SimCode::SimEqSystem) -> &'static str {
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

/// The `index` of a `SimEqSystem` (best-effort; systems without a top-level
/// index report -1).
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
        | E::SES_FOR_LOOP { index, .. } => *index,
        _ => -1,
    }
}

/// Emit the in-wasm forward-Euler integrator loop:
/// `simulate(sim_data, start, stop, n_steps) -> result_buffer`.
fn build_simulate(layout: &SimLayout, eqfn: &EqFnIdx) -> we::Function {
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

    // functionParameters(sim_data); functionInitialEquations(sim_data)
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::Call(eqfn.parameters));
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::Call(eqfn.initial));

    // buf = rt_alloc((n_steps + 1) * n_total * 8)
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::I32Const(1));
    f.instruction(&I::I32Add);
    f.instruction(&I::I32Const((n_total * 8) as i32));
    f.instruction(&I::I32Mul);
    f.instruction(&I::Call(rt_index("rt_alloc")));
    f.instruction(&I::LocalSet(BUF));

    // h = (stop - start) / n_steps   (n_steps converted to f64)
    f.instruction(&I::LocalGet(STOP));
    f.instruction(&I::LocalGet(START));
    f.instruction(&I::F64Sub);
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::F64ConvertI32S);
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

    // functionODE(sim_data); functionAlgebraics(sim_data)
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::Call(eqfn.ode));
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::Call(eqfn.algebraics));

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

    // if row >= n_steps: break (exit the block)
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::I32GeS);
    f.instruction(&I::BrIf(1)); // branch out of the loop to the block end

    // rt_euler_step(sim_data, n_states, h)
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::I32Const(n_states as i32));
    f.instruction(&I::LocalGet(H));
    f.instruction(&I::Call(rt_index("rt_euler_step")));

    // row += 1; continue
    f.instruction(&I::LocalGet(ROW));
    f.instruction(&I::I32Const(1));
    f.instruction(&I::I32Add);
    f.instruction(&I::LocalSet(ROW));
    f.instruction(&I::Br(0));

    f.instruction(&I::End); // loop
    f.instruction(&I::End); // block

    // return buf
    f.instruction(&I::LocalGet(BUF));
    f.instruction(&I::End); // function
    f
}

// ===========================================================================
// MATLAB v4 result-file writer
// ===========================================================================

/// Write the simulation result as an OpenModelica MATLAB v4 (`.mat`) file.
/// `rows` is the row-major result buffer (`n_rows * n_reals` f64: per row,
/// `[time, realVars...]`); `params` come from the [`SimModel`] result vars. The
/// serialization itself lives in `openmodelica_mat_writer` (`no_std` + `alloc`,
/// shared with the standalone wasip1 runtime's `_start`); here we only map the
/// result-var metadata onto its `MatVar`/`MatKind` and write the bytes out.
fn write_mat4(model: &SimModel, path: &str, rows: &[f64], n_reals: u32, params: &[f64]) -> Result<()> {
    use openmodelica_mat_writer::{MatKind, MatVar};
    let vars: Vec<MatVar> = model
        .result_vars
        .iter()
        .map(|v| MatVar {
            name: &v.name,
            comment: &v.comment,
            kind: match &v.kind {
                ResultKind::Time => MatKind::Time,
                ResultKind::Column { col, negate } => MatKind::Column { col: *col, negate: *negate },
                ResultKind::Param { negate, .. } => MatKind::Param { negate: *negate },
                ResultKind::Const { value } => MatKind::Const { value: *value },
            },
        })
        .collect();
    let bytes = openmodelica_mat_writer::write_mat4(&vars, model.start_time, model.stop_time, rows, n_reals, params);
    let _ = &model.model_name; // (kept for diagnostics)
    write_output(path, &bytes).map_err(|e| anyhow!("CodegenWasmJit: cannot write {path}: {e}"))
}

// The standalone-export merge uses `wasmtime::Module` to validate the result, so
// this test runs only under the default (wasmtime) engine on a native host.
#[cfg(test)]
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
mod standalone_tests {
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

        let mut funcs = we::FunctionSection::new();
        for _ in 0..4 {
            funcs.function(1); // functionParameters/InitialEquations/ODE/Algebraics
        }
        funcs.function(2); // om_meta_ptr
        funcs.function(2); // om_meta_len
        m.section(&funcs);

        let mut exports = we::ExportSection::new();
        exports.export("functionParameters", we::ExportKind::Func, 1);
        exports.export("functionInitialEquations", we::ExportKind::Func, 2);
        exports.export("functionODE", we::ExportKind::Func, 3);
        exports.export("functionAlgebraics", we::ExportKind::Func, 4);
        exports.export("om_meta_ptr", we::ExportKind::Func, 5);
        exports.export("om_meta_len", we::ExportKind::Func, 6);
        m.section(&exports);

        let mut code = we::CodeSection::new();
        for _ in 0..4 {
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
        m.section(&code);

        m.finish()
    }

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
