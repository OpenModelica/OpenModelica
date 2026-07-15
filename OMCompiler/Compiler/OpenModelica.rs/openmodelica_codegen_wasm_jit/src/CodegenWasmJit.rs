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

use std::collections::{HashMap, HashSet};
use std::sync::{Mutex, OnceLock};
use std::sync::Arc;

use metamodelica::Result;
use arcstr::ArcStr;
use metamodelica::List;
use wasm_encoder as we;

use openmodelica_frontend_types::DAE;
use openmodelica_simcode_types::SimCode;
use openmodelica_simcode_types::SimCodeVar;
use openmodelica_simcode_types::SimCodeFunction;
use openmodelica_frontend_dump::ComponentReferenceBasics;

use crate::CodegenWasmJitFunctions::{
    ArrayGroup, BUILTINS, ENV_EXTRA, ExtCallSig, FnCtx, FnInfo, NLS_BASE_GLOBAL, NLS_HIST_GLOBAL, NlsJob, RT_BUILTINS,
    SimCtx, SimSlot, WTy, compile_function, compile_linear_system, compile_linear_system_symbolic,
    emit_nls_load_body,
    emit_nls_residual_body, emit_solve_nls_call, external_import_sig, external_known,
    external_general, function_signature, rt_index, sim_cref_key,
};

// Engine selected at compile time; same module interface across all three
// (mirrors the block in CodegenWasmJitFunctions.rs, including the misconfig
// guards). The `SimModel` below stores compiled modules as `sim_runtime::Module`.
// Engine-independent simulation drivers (shared by the wasmtime and wasmer
// backends via the `sim_driver::SimEngine` trait); absent in the stub build.
#[cfg(feature = "jit")]
mod sim_driver;
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
    /// When true, `functionAlgebraics` also runs the discrete update and saves the
    /// `pre` regions, so drivers must call it only in the once-per-step order.
    has_when: bool,
    /// The model uses `homotopy()`, so a `functionInitialEquations_lambda0` is
    /// emitted and the driver may fall back to the homotopy continuation on a
    /// failed direct initialization.
    has_homotopy: bool,
    /// `SimData` byte offset of the homotopy parameter lambda (f64). 1.0 outside
    /// the homotopy continuation; `homotopy(a, s)` reads it as `s + lambda*(a-s)`.
    lambda_off: u32,
    rparam_off: u32,
    int_off: u32,
    iparam_off: u32,
    bool_off: u32,
    bparam_off: u32,
    /// String algebraic variables (one i32 String handle each).
    str_off: u32,
    /// String parameters (one i32 String handle each).
    sparam_off: u32,
    /// External-object variables (one i32 pointer-registry handle each).
    eobj_off: u32,
    /// `pre()` values, parallel to the live variable regions (C's `realVarsPre`
    /// etc.): `pre_real_off` mirrors the real region (states|ders|algs, f64 each),
    /// `pre_int_off` the integer algebraics, `pre_bool_off` the boolean ones. A
    /// `$PRE.x` slot sits at the same relative offset as `x`'s live slot.
    pre_real_off: u32,
    pre_int_off: u32,
    pre_bool_off: u32,
    /// `terminate(...)` flag (i32): set to 1 by a fired `terminate` when-operator,
    /// polled by the drivers after each communication point to stop the run early.
    terminate_off: u32,
    /// Number of result rows actually written (i32), set by the in-wasm `simulate`
    /// loop so `run_wasm` reads only the rows produced before an early terminate.
    n_out_off: u32,
    /// Nonlinear-solver failure flag (i32): a `SES_NONLINEAR` system that does not
    /// converge (or has a singular Jacobian) restores the entry guess, raises this
    /// flag, and returns instead of trapping — so the DASSL residual callback can
    /// signal a *recoverable* error (IRES=-1) and let the integrator back off to a
    /// smaller step (a closer initial guess), as the C runtime does.
    nls_fail_off: u32,
    /// Number of `sample(...)` time events (C's `samplesInfo` length). Zero when
    /// the model has none, in which case the two offsets below are unused and the
    /// sample region is empty (byte-identical layout to before this feature).
    n_samples: u32,
    /// Base of the sample parameter region: for sample `k` the `start` time is at
    /// `sample_off + k*16` and the `interval` at `sample_off + k*16 + 8` (both f64,
    /// written by the emitted `initSample` from the events' `startExp`/`intervalExp`).
    sample_off: u32,
    /// Base of the per-sample `active` flags (one i32 each): the driver raises
    /// `active[k]` at a sample's firing time before the discrete update, so the
    /// `sample(index,…)` builtin (which reads this slot) is true only then.
    sample_active_off: u32,
    /// Number of state-event zero-crossing functions (`SimCode.zeroCrossings`).
    n_zc: u32,
    /// Base of the zero-crossing value region (one f64 `g_i` per crossing, ±1 as the
    /// condition holds), written by the emitted `functionZeroCrossings` and read back
    /// by the driver's DASKR root callback (`RtFn`). Empty when the model has none.
    zc_off: u32,
    /// Number of indexed relations (`SimCode.varInfo.numRelations`) — the C
    /// runtime's `relations[]`/hysteresis count.
    n_rel: u32,
    /// Base of the held relation values (one i32 per indexed relation): equations
    /// read these during continuous integration (mode fixed → smooth NLS residual),
    /// the driver refreshes them at events/init. Mirrors C's relation hysteresis.
    relations_off: u32,
    /// Relation evaluation mode (i32): 0 = held (return `relations[i]`), 1 = event
    /// (evaluate fresh + store), 2 = initialization (fresh everywhere incl. NLS).
    /// `rt_solve_nls` forces held (0) around its residual evals unless mode 2.
    rel_fresh_off: u32,
    /// Held relation snapshot (one i32 per relation): the hysteresis *direction* read
    /// by `compile_relation_hyst` and the crossing function. The driver refreshes it
    /// from `relations[]` at init and around each event, and holds it fixed for the
    /// duration of one event's discrete update.
    stored_rel_off: u32,
    /// `relationsPre` (one i32 per relation): the value a held relation returns, so
    /// it stays fixed while an NLS Newton solve varies the unknowns. The driver
    /// refreshes it from `relations[]` at init and each event-iteration pass.
    relations_pre_off: u32,
    /// Base of the state-set Jacobian scratch region (f64): the seed inputs and
    /// column result outputs of every `$STATESET` analytic Jacobian, so
    /// `functionStateSetJacobians` can evaluate a column into memory the driver
    /// reads (see [`StateSetInfo`]). Zero-sized when the model has no state sets.
    stateset_off: u32,
    /// C's `mathEventsValuePre` length (`varInfo.numMathEventFunctions`).
    n_math: u32,
    /// Base of the held math-event values (f64 each); C's `mathEventsValuePre`.
    mathevents_off: u32,
    /// Zero-crossing hysteresis tolerance slot (f64); see [`SimCtx::zctol_off`].
    zctol_off: u32,
    /// Base of the overridable start-value region (one f64 per state, state `i` at
    /// `start_off + i*8`): `functionInitStartValues` fills it from each start
    /// expression and `$START.<state>` reads it back, so `-override=<state>=v` sets
    /// the initial condition.
    start_off: u32,
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
        n_eobj: u32,
        n_samples: u32,
        n_zc: u32,
        n_rel: u32,
        n_stateset_f64: u32,
        n_math: u32,
        has_when: bool,
        has_homotopy: bool,
    ) -> Self {
        let n_real = 2 * n_states + n_real_alg; // states | ders | algs
        let rparam_off = REAL_OFF + n_real * 8;
        let int_off = rparam_off + n_real_param * 8;
        let iparam_off = int_off + n_int_alg * 4;
        let bool_off = iparam_off + n_int_param * 4;
        let bparam_off = bool_off + n_bool_alg * 4;
        let str_off = bparam_off + n_bool_param * 4;
        let sparam_off = str_off + n_str_alg * 4;
        let eobj_off = sparam_off + n_str_param * 4;
        // pre() region, 8-aligned so the real pre-slots are naturally aligned.
        let pre_real_off = (eobj_off + n_eobj * 4 + 7) & !7;
        let pre_int_off = pre_real_off + n_real * 8;
        let pre_bool_off = pre_int_off + n_int_alg * 4;
        // Control slots appended after all variable/pre regions (existing offsets
        // unchanged). Zeroed by `rt_alloc`, so `terminate` starts false.
        let terminate_off = pre_bool_off + n_bool_alg * 4;
        let n_out_off = terminate_off + 4;
        let nls_fail_off = n_out_off + 4;
        // Homotopy parameter (f64), 8-aligned.
        let lambda_off = (nls_fail_off + 4 + 7) & !7;
        // Sample region: 8-aligned start/interval f64 pairs, then i32 active flags.
        let sample_off = (lambda_off + 8 + 7) & !7;
        let sample_active_off = sample_off + n_samples * 16;
        // Zero-crossing values (f64 each), 8-aligned after the sample region.
        let zc_off = (sample_active_off + n_samples * 4 + 7) & !7;
        // Relation hysteresis region: one i32 held value per indexed relation, then
        // the relation-mode flag.
        let relations_off = zc_off + n_zc * 8;
        let rel_fresh_off = relations_off + n_rel * 4;
        // `storedRelations` snapshot (one i32 per relation), after the mode flag.
        let stored_rel_off = rel_fresh_off + 4;
        // `relationsPre` (one i32 per relation), the held-mode values.
        let relations_pre_off = stored_rel_off + n_rel * 4;
        // State-set Jacobian scratch (f64), 8-aligned after the relation region.
        let stateset_off = (relations_pre_off + n_rel * 4 + 7) & !7;
        // 2-slot pad: C's `_event_mod_real` writes `pre[index+2]`, past its 2
        // reserved slots.
        let mathevents_off = stateset_off + n_stateset_f64 * 8;
        let n_math_slots = if n_math > 0 { n_math + 2 } else { 0 };
        // Zero-crossing tolerance (f64), 8-aligned after the math-event region.
        let zctol_off = mathevents_off + n_math_slots * 8;
        // Overridable start values (one f64 per state), 8-aligned after the tolerance.
        let start_off = zctol_off + 8;
        let total = start_off + n_states * 8;
        SimLayout {
            n_states, n_real_alg, has_when, has_homotopy, lambda_off, rparam_off, int_off, iparam_off, bool_off, bparam_off,
            str_off, sparam_off, eobj_off, pre_real_off, pre_int_off, pre_bool_off,
            terminate_off, n_out_off, nls_fail_off, n_samples, sample_off, sample_active_off,
            n_zc, zc_off, n_rel, relations_off, rel_fresh_off, stored_rel_off, relations_pre_off, stateset_off, n_math, mathevents_off, zctol_off, start_off, total,
        }
    }

    /// Byte offset of state `i`'s overridable start-value slot.
    fn state_start_off(&self, i: u32) -> u32 {
        self.start_off + i * 8
    }

    /// Offset of the `pre()` slot mirroring a live variable slot at byte offset
    /// `off`, if `off` is in a variable region that carries pre-values (real /
    /// integer / boolean variables — not parameters, strings, or ext-objects).
    fn pre_slot_off(&self, off: u32) -> Option<u32> {
        if off >= REAL_OFF && off < self.rparam_off {
            Some(self.pre_real_off + (off - REAL_OFF))
        } else if off >= self.int_off && off < self.iparam_off {
            Some(self.pre_int_off + (off - self.int_off))
        } else if off >= self.bool_off && off < self.bparam_off {
            Some(self.pre_bool_off + (off - self.bool_off))
        } else {
            None
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

/// Solver statistics, reported in the simulation log when `LOG_STATS` is active
/// (mirrors the C runtime's `### STATISTICS ###` block from `solver_main.c`).
#[derive(Default)]
pub(crate) struct SolveStats {
    pub(crate) method: &'static str,
    pub(crate) steps: u64,
    pub(crate) res_evals: u64,
    pub(crate) jac_evals: u64,
    pub(crate) err_test_fails: u64,
    pub(crate) conv_test_fails: u64,
    pub(crate) state_events: u64,
    pub(crate) time_events: u64,
}

impl SolveStats {
    /// Render the `LOG_STATS` block the C runtime emits at simulation end, so it
    /// shows in the simulation log (and thus the OMEdit output widget).
    fn log_stats_block(&self) -> String {
        format!(
            "LOG_STATS         | info    | ### STATISTICS ###\n\
             LOG_STATS         | info    | events\n\
             LOG_STATS         | info    | |   {:5} state events\n\
             LOG_STATS         | info    | |   {:5} time events\n\
             LOG_STATS         | info    | solver: {}\n\
             LOG_STATS         | info    | |   {:5} steps taken\n\
             LOG_STATS         | info    | |   {:5} calls of functionODE\n\
             LOG_STATS         | info    | |   {:5} evaluations of jacobian\n\
             LOG_STATS         | info    | |   {:5} error test failures\n\
             LOG_STATS         | info    | |   {:5} convergence test failures\n",
            self.state_events, self.time_events, self.method, self.steps,
            self.res_evals, self.jac_evals, self.err_test_fails, self.conv_test_fails,
        )
    }
}

/// The prepared, ready-to-run artifact for one model, stashed in-process by
/// [`translateModel`] and consumed by [`runSimulation`] (keyed by file-name
/// prefix). This is the in-memory replacement for the C target's `_init.xml`
/// + `_info.json` + the built executable.
struct SimModel {
    wasm: Vec<u8>,
    layout: SimLayout,
    result_vars: Vec<ResultVar>,
    /// The `ext.<extName>` host imports (external "C" functions), with the full
    /// C-call shape ([`ExtCallSig`]: input/output args + return) so the host
    /// trampoline can marshal strings/arrays/pointers and output pointers — the
    /// wasm `FuncType` only sees i32/f64.
    ext_imports: Vec<ExtCallSig>,
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
    /// Dynamic state selection metadata (one per `$STATESET`); empty for models
    /// without state sets. The driver evaluates each set's Jacobian
    /// (`functionStateSetJacobians`), pivots, and rebuilds `A` between steps.
    state_sets: Vec<StateSetInfo>,
    /// ODE state Jacobian ∂f/∂x ("A") sparsity + coloring for the colored-FD path;
    /// `None` ⇒ daskr's own numerical Jacobian.
    jac_a: Option<JacAInfo>,
    /// Per-state nominal magnitude `max(|nominal|, 1e-32)` (integrator order) for the
    /// per-state atol `tol·nominal[i]`; constant-folded, `1.0` if absent.
    state_nominals: Vec<f64>,
    /// User-settable initial conditions (parameters with `isValueChangeable`):
    /// name/unit/slot, so a host can list them and `-override` them by name.
    editable_params: Vec<EditableParam>,
    /// Result-variable display name -> unit (e.g. `h` -> `m`), for a host to label
    /// plotted signals. Empty units are omitted.
    var_units: HashMap<String, String>,
}

/// A user-settable parameter (an editable initial condition): its display name,
/// unit, and `SimData` slot so an `-override=name=value` can write it.
#[derive(Clone)]
struct EditableParam {
    name: String,
    comment: String,
    unit: String,
    off: u32,
    wty: WTy,
    /// A state's start value (vs. a plain parameter): shown as the state's `t0`
    /// value, and overridden after `functionInitStartValues` rather than before.
    is_start: bool,
}

/// Process-wide table of prepared models, keyed by file-name prefix. Populated
/// by `translateModel` (during `callTargetTemplates`) and read by
/// `runSimulation` (during `simulate`) in the same process.
fn sim_models() -> &'static Mutex<HashMap<String, Arc<SimModel>>> {
    static MODELS: OnceLock<Mutex<HashMap<String, Arc<SimModel>>>> = OnceLock::new();
    MODELS.get_or_init(|| Mutex::new(HashMap::new()))
}

/// One captured result signal: its name/description and the resolved value over
/// the run (one f64 per output row; length 1 for a time-invariant signal).
pub struct SimSeries {
    pub name: String,
    pub comment: String,
    pub unit: String,
    /// Time-invariant (parameter/constant) or constant over the whole run — the
    /// web simulator hides these from the default plot ("all non-constant vars").
    pub constant: bool,
    /// This signal aliases the same underlying data as an earlier series (e.g.
    /// `der(h)` and `v` when `v = der(h)`): plotting one of them suffices.
    pub alias: bool,
    pub values: Vec<f64>,
}

/// A parameter's value after the run, with the metadata a host needs to show it
/// as an editable initial condition.
pub struct CapturedParam {
    pub name: String,
    pub comment: String,
    pub unit: String,
    pub value: f64,
}

/// The last run's results, resolved from the model's [`RunResult`] into per-signal
/// value arrays so a host (the web simulator) can read them directly, without the
/// intermediate `.mat` file. `time` is the independent column; `series` excludes
/// `time`.
pub struct CapturedSim {
    pub model_name: String,
    pub start_time: f64,
    pub stop_time: f64,
    pub time: Vec<f64>,
    pub series: Vec<SimSeries>,
    pub params: Vec<CapturedParam>,
}

fn last_sim() -> &'static Mutex<Option<CapturedSim>> {
    static LAST: OnceLock<Mutex<Option<CapturedSim>>> = OnceLock::new();
    LAST.get_or_init(|| Mutex::new(None))
}

/// Resolve a finished [`sim_driver::RunResult`] into per-signal value arrays
/// (reusing the result-var metadata the `.mat` writer uses) and stash it for the
/// host to read directly.
fn capture_last_sim(model: &SimModel, run: &sim_driver::RunResult) {
    let n_reals = run.n_reals as usize;
    let n_rows = if n_reals == 0 { 0 } else { run.rows.len() / n_reals };
    let column = |col: usize, negate: bool| -> Vec<f64> {
        (0..n_rows)
            .map(|r| {
                let v = run.rows[r * n_reals + col];
                if negate { -v } else { v }
            })
            .collect()
    };
    let is_const_col = |vals: &[f64]| vals.iter().all(|&v| v == vals.first().copied().unwrap_or(0.0));

    let unit_of = |name: &str| model.var_units.get(name).cloned().unwrap_or_default();
    let mut time = Vec::new();
    let mut series = Vec::new();
    let mut param_idx = 0usize;
    // A signal aliases an earlier one when it reads the same underlying data: the
    // same result column, or the same parameter slot (the `.mat`'s `dataInfo`
    // aliasing — several names, one stored column). Distinct columns are distinct
    // signals even when an equation keeps them near-equal (`der(h) = v` differs at
    // event rows), so both are plotted. First occurrence is canonical.
    let mut seen_cols = HashSet::new();
    let mut seen_param_offs = HashSet::new();
    let mut param_value_by_off: HashMap<u32, f64> = HashMap::new();
    for v in &model.result_vars {
        match &v.kind {
            ResultKind::Time => time = column(0, false),
            ResultKind::Column { col, negate } => {
                let values = column(*col as usize, *negate);
                let constant = is_const_col(&values);
                let alias = !seen_cols.insert(*col);
                series.push(SimSeries { name: v.name.clone(), comment: v.comment.clone(), unit: unit_of(&v.name), constant, alias, values });
            }
            ResultKind::Param { off, negate, .. } => {
                let raw = run.params.get(param_idx).copied().unwrap_or(0.0);
                param_idx += 1;
                param_value_by_off.entry(*off).or_insert(raw);
                let value = if *negate { -raw } else { raw };
                let alias = !seen_param_offs.insert(*off);
                series.push(SimSeries {
                    name: v.name.clone(),
                    comment: v.comment.clone(),
                    unit: unit_of(&v.name),
                    constant: true,
                    alias,
                    values: vec![value],
                });
            }
            ResultKind::Const { value } => series.push(SimSeries {
                name: v.name.clone(),
                comment: v.comment.clone(),
                unit: unit_of(&v.name),
                constant: true,
                alias: false,
                values: vec![*value],
            }),
        }
    }
    // A start value shows the state's t0 value; a plain parameter shows its slot.
    let row0_by_name: HashMap<&str, f64> =
        series.iter().map(|s| (s.name.as_str(), s.values.first().copied().unwrap_or(0.0))).collect();
    let params = model
        .editable_params
        .iter()
        .map(|p| CapturedParam {
            name: p.name.clone(),
            comment: p.comment.clone(),
            unit: p.unit.clone(),
            value: if p.is_start {
                row0_by_name.get(p.name.as_str()).copied().unwrap_or(0.0)
            } else {
                param_value_by_off.get(&p.off).copied().unwrap_or(0.0)
            },
        })
        .collect();
    *last_sim().lock().unwrap_or_else(|e| e.into_inner()) = Some(CapturedSim {
        model_name: model.model_name.clone(),
        start_time: model.start_time,
        stop_time: model.stop_time,
        time,
        series,
        params,
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

// ===========================================================================
// Public entry points (called from the MetaModelica sources after regen)
// ===========================================================================

/// Record the reason as an `INTERNAL_ERROR` so `getErrorString()` (and OMEdit)
/// show it and the scripting layer treats the build as failed. Does NOT panic: a
/// panic traps the wasm instance, after which the buffered error can't be read
/// back (the web omc then reports a bare "Translation failed"). Callers return
/// after this instead — an unsupported construct is a normal failure, not a crash.
pub(crate) fn record_error(msg: String) {
    let _ = openmodelica_util::Error::addInternalError(
        ArcStr::from(msg.as_str()),
        openmodelica_util::Error::dummyInfo.clone(),
    );
}

/// `CodegenWasmJit.translateModel`: lower `simCode` to a model wasm module, write
/// `<prefix>.wasm`, and stash the prepared [`SimModel`] for the later
/// `runSimulation`. On a lowering error the message is recorded to the Error
/// buffer (so `getErrorString` / OMEdit show it) and the failure is returned so
/// translation fails — as the other codegen targets do — never a stderr print or
/// a panic (a panic would trap the wasm instance and lose the buffered message).
pub fn translateModel(simCode: SimCode::SimCode) -> Result<()> {
    sim_runtime::start_runtime_compile();
    let prefix = simCode.fileNamePrefix.to_string();
    let _ = std::fs::remove_file(format!("{prefix}.wasm"));
    let errs_before = openmodelica_util::Error::getNumErrorMessages();
    let outcome = build_sim_model(&simCode).and_then(|model| {
        write_output(&format!("{prefix}.wasm"), &model.wasm).map_err(|_| "CodegenWasmJit: write failed")?;
        sim_models().lock().unwrap_or_else(|e| e.into_inner()).insert(prefix.clone(), Arc::new(model));
        Ok(())
    });
    if let Err(e) = &outcome {
        if openmodelica_util::Error::getNumErrorMessages() == errs_before {
            record_error(format!("CodegenWasmJit: cannot build simulation module for `{prefix}`: {e:#}"));
        }
    }
    outcome
}

/// `CodegenWasmJit.runSimulation`: run the prepared model in-process and write
/// the result file. Returns 0 on success, 1 on failure (matching the exit code
/// the C target's executable would return, which `simulate` checks).
pub fn runSimulation(fileNamePrefix: ArcStr, resultFile: ArcStr, simflags: ArcStr) -> i32 {
    let (res, output) = run_simulation_inner(&fileNamePrefix, &resultFile, &simflags);
    // The simulate scripting flow reads `<prefix>.log` after a run (the C target's
    // executable writes one); match the C target's log exactly so rtest diffs are
    // clean. `output` is the model's captured stdout (Streams.print, LOG_STATS, ...)
    // folded in so it shows in the log instead of the process console. No start
    // banner or flags line: OMEdit echoes those via its own compilation output.
    let log = match &res {
        Ok(()) => format!(
            "{output}LOG_SUCCESS       | info    | The initialization finished successfully without homotopy method.\n\
             LOG_SUCCESS       | info    | The simulation finished successfully.\n"
        ),
        Err(e) => format!("{output}LOG_ERROR         | error   | wasm-jit simulation failed: {e:#}\n"),
    };
    let _ = write_output(&format!("{fileNamePrefix}.log"), log.as_bytes());
    // Error is in `<prefix>.log` (hence the result `messages`); no stderr.
    match res {
        Ok(()) => 0,
        Err(_) => 1,
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
    let model = sim_models().lock().unwrap_or_else(|e| e.into_inner()).get(&fileNamePrefix.to_string()).cloned();
    let Some(model) = model else { return };
    // Force the runtime module (so its compile/cache-load is in `timeCompile`).
    let _ = sim_runtime::runtime_module();
    // Join the background model-module compile and stash the result.
    match sim_runtime::take_compiled_model(&model) {
        Ok(m) => *model.prepared.lock().unwrap_or_else(|e| e.into_inner()) = Some(m),
        // Deferred: `runSimulation` recompiles and reports the error via the log.
        Err(_) => {}
    }
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
    return Err("{msg}")
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
        return Err("standalone module `{module}` not found (emitStandalone not run?)");
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
        .map_err(|e| "cannot run `{wasmtime}` (is it on PATH? override with OMC_WASMTIME): {e}")?;
    if !status.success() {
        return Err("`{wasmtime} run {module}` failed with {status}");
    }
    // The module writes `<prefix>_res.mat`; rename if omc selected another name.
    let produced = format!("{prefix}_res.mat");
    if result_file != produced && std::path::Path::new(&produced).exists() {
        std::fs::rename(&produced, result_file)
            .map_err(|e| "cannot rename {produced} -> {result_file}: {e}")?;
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
/// Parse `-override=name=value,...` tokens out of `simflags` and resolve each to
/// its editable parameter's `SimData` slot. Unknown names / unparsable values are
/// skipped (an unknown override is a no-op, as in the C runtime).
/// Returns `(param_overrides, start_overrides)`: plain parameters vs. state start
/// values, applied at different points of initialization (see `run_initialization`).
fn resolve_overrides(model: &SimModel, simflags: &str) -> (Vec<(u32, WTy, f64)>, Vec<(u32, WTy, f64)>) {
    let mut params = Vec::new();
    let mut starts = Vec::new();
    for tok in simflags.split_whitespace() {
        let Some(list) = tok.strip_prefix("-override=") else { continue };
        for item in list.split(',') {
            let Some((name, value)) = item.split_once('=') else { continue };
            let Ok(val) = value.trim().parse::<f64>() else { continue };
            if let Some(p) = model.editable_params.iter().find(|p| p.name == name.trim()) {
                if p.is_start { &mut starts } else { &mut params }.push((p.off, p.wty, val));
            }
        }
    }
    (params, starts)
}

fn run_simulation_inner(prefix: &str, result_file: &str, simflags: &str) -> (Result<()>, String) {
    let model = sim_models()
        .lock()
        .unwrap_or_else(|e| e.into_inner())
        .get(prefix)
        .cloned();
    let Some(model) = model else {
        return (Err("no prepared wasm-jit model for `{prefix}` (translateModel not run?)"), String::new());
    };
    // The `-lv=` runtime flag list selects log streams, as for the C executable.
    let log_stats = simflags.contains("LOG_STATS") || simflags.contains("LOG_ALL");
    // `-override=name=value,...`: resolve each editable parameter to its SimData
    // slot and hand the list to the driver (applied after `functionParameters`).
    let (param_ov, start_ov) = resolve_overrides(&model, simflags);
    sim_driver::set_param_overrides(param_ov, start_ov);
    openmodelica_wasi::wasi::start_stdout_capture();
    let mut extra = String::new();
    let res = (|| -> Result<()> {
        // `empty` runs the integration but writes no result file — useful for
        // benchmarking the solver in isolation from the `.mat` writer.
        let fmt = model.output_format.as_str();
        if fmt != "mat" && fmt != "empty" {
            return Err("CodegenWasmJit: only the `mat` and `empty` output formats are supported (got `{fmt}`)");
        }
        let run = sim_runtime::run(&model)?;
        if log_stats {
            extra.push_str(&run.stats.log_stats_block());
        }
        capture_last_sim(&model, &run);
        if fmt == "mat" {
            write_mat4(&model, result_file, &run.rows, run.n_reals, &run.params)?;
        }
        Ok(())
    })();
    let captured = openmodelica_wasi::wasi::take_stdout_capture();
    (res, format!("{captured}{extra}"))
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

#[cfg(feature = "jit")]
mod session {
    use super::*;

    /// A resumable, cancellable simulation. Owns the JIT engine + driver across
    /// `advance` calls. One per thread (omc is single-threaded per process).
    pub(super) struct SimSession {
        model: Arc<SimModel>,
        engine: Box<dyn sim_driver::SimEngine + 'static>,
        driver: Box<dyn sim_driver::Driver>,
        sim_data: u32,
        result_file: String,
    }

    thread_local! {
        static SIM_SESSION: std::cell::RefCell<Option<SimSession>> = const { std::cell::RefCell::new(None) };
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
            .ok_or_else(|| "no prepared wasm-jit model for `{prefix}` (translateModel not run?)")?;
        let fmt = model.output_format.as_str();
        if fmt != "mat" && fmt != "empty" {
            return Err("CodegenWasmJit: only the `mat` and `empty` output formats are supported (got `{fmt}`)");
        }
        let (param_ov, start_ov) = resolve_overrides(&model, simflags);
        sim_driver::set_param_overrides(param_ov, start_ov);
        sim_driver::clear_cancel();
        openmodelica_wasi::wasi::start_stdout_capture();
        // Build engine + driver (instantiate, init, emit row 0). An init trap is
        // usually a failed `assert()`; route it to the Error buffer.
        let built = (|| -> Result<(Box<dyn sim_driver::SimEngine + 'static>, u32, Box<dyn sim_driver::Driver>)> {
            let (mut engine, sim_data) = sim_runtime::build_engine(&model)?;
            let (driver, _label) = sim_driver::make_driver(&mut *engine, &model, sim_data, model.method.as_str())
                .map_err(|err| sim_driver::enrich_trap(&mut *engine, err))?;
            Ok((engine, sim_data, driver))
        })();
        let (engine, sim_data, driver) = match built {
            Ok(v) => v,
            Err(e) => {
                let _ = openmodelica_wasi::wasi::take_stdout_capture();
                record_error(format!("wasm-jit simulation failed: {e:#}"));
                return Err(e);
            }
        };
        SIM_SESSION.with(|s| {
            *s.borrow_mut() = Some(SimSession { model, engine, driver, sim_data, result_file: result_file.to_string() })
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
            let adv = sess
                .driver
                .advance(&mut *sess.engine, &sess.model, budget_ms)
                .map_err(|err| sim_driver::enrich_trap(&mut *sess.engine, err));
            let adv = match adv {
                Ok(a) => a,
                Err(e) => {
                    let _ = openmodelica_wasi::wasi::take_stdout_capture();
                    record_error(format!("wasm-jit simulation failed: {e:#}"));
                    *guard = None;
                    return Err(e);
                }
            };
            match adv {
                sim_driver::Advance::Running => Ok(SimStatus::Running),
                sim_driver::Advance::Cancelled => {
                    // Free external objects so the cancelled run leaks nothing.
                    let _ = sim_driver::finalize_run(&mut *sess.engine, &sess.model, sess.sim_data);
                    let _ = openmodelica_wasi::wasi::take_stdout_capture();
                    *guard = None;
                    Ok(SimStatus::Cancelled)
                }
                done => {
                    let rows = sess.driver.take_rows();
                    let params = sim_driver::finalize_run(&mut *sess.engine, &sess.model, sess.sim_data)?;
                    let run = sim_driver::RunResult {
                        rows,
                        n_reals: sess.model.layout.n_row_total(),
                        params,
                        stats: SolveStats::default(),
                    };
                    capture_last_sim(&sess.model, &run);
                    if sess.model.output_format == "mat" {
                        write_mat4(&sess.model, &sess.result_file, &run.rows, run.n_reals, &run.params)?;
                    }
                    let _ = openmodelica_wasi::wasi::take_stdout_capture();
                    let st = if matches!(done, sim_driver::Advance::Terminated) {
                        SimStatus::Terminated
                    } else {
                        SimStatus::Done
                    };
                    *guard = None;
                    Ok(st)
                }
            }
        })
    }

    /// Drop the active session, freeing its external objects. Safe to call with no
    /// session (the cancel path and `sim_start`'s reset both use it).
    pub fn sim_free() {
        SIM_SESSION.with(|s| {
            if let Some(mut sess) = s.borrow_mut().take() {
                let _ = sim_driver::finalize_run(&mut *sess.engine, &sess.model, sess.sim_data);
            }
        });
    }
}

#[cfg(feature = "jit")]
pub use session::{sim_advance, sim_free, sim_start};

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
        .map_err(|e| "CodegenWasmJit: cannot run `{merge}`: {e}")?;
    if !status.success() {
        return Err("CodegenWasmJit: `{merge}` failed with {status}");
    }
    let bytes = std::fs::read(&out_path).map_err(|_| "CodegenWasmJit: cannot read merged wasm")?;
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
    /// State cref key -> its start-value slot; when present, `$START.<key>` reads the
    /// slot instead of the inline expression. Empty when building
    /// `functionInitStartValues` (it fills the slots, so must not read them).
    start_slots: HashMap<String, u32>,
    /// Finalized array-variable groups (base cref key -> contiguous slot range).
    array_groups: HashMap<String, ArrayGroup>,
    /// Transient accumulator: base cref key -> the scalarized elements seen
    /// (subscripts, byte offset, value type). Finalized into `array_groups` at the
    /// end of [`build_var_map`].
    array_acc: HashMap<String, Vec<(Vec<i32>, u32, WTy)>>,
    /// `SimData` byte offset of the `terminate` flag (see [`SimLayout`]).
    terminate_off: u32,
    /// `SimData` byte offset of the nonlinear-solver failure flag (see [`SimLayout`]).
    nls_fail_off: u32,
    /// `SES_NONLINEAR` system index -> its `rt_solve_nls` job. Filled by
    /// [`collect_nls_jobs`] before the equation functions are lowered.
    nls_jobs: Arc<HashMap<i32, NlsJob>>,
    /// `sample(index,…)` event index -> its slot `k` (see [`SampleInfo`]). Empty
    /// when the model has no samples.
    sample_map: Arc<HashMap<i32, u32>>,
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
    /// `SimData` byte offset of the zero-crossing hysteresis tolerance (`SimCtx::zctol_off`).
    zctol_off: u32,
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
) -> Result<(SimVarMap, Vec<ResultVar>, Vec<EditableParam>)> {
    let mut map = SimVarMap {
        vars: HashMap::new(),
        starts: HashMap::new(),
        start_slots: HashMap::new(),
        array_groups: HashMap::new(),
        array_acc: HashMap::new(),
        terminate_off: layout.terminate_off,
        nls_fail_off: layout.nls_fail_off,
        nls_jobs: Arc::new(HashMap::new()),
        sample_map: Arc::new(HashMap::new()),
        sample_active_off: layout.sample_active_off,
        relations_off: layout.relations_off,
        rel_fresh_off: layout.rel_fresh_off,
        stored_rel_off: layout.stored_rel_off,
        relations_pre_off: layout.relations_pre_off,
        n_relations: layout.n_rel,
        mathevents_off: layout.mathevents_off,
        n_mathevents: layout.n_math,
        lambda_off: layout.lambda_off,
        zctol_off: layout.zctol_off,
    };
    let mut result_vars: Vec<ResultVar> = Vec::new();
    // User-settable parameters (isValueChangeable), collected as they are laid out.
    let mut editable: Vec<EditableParam> = Vec::new();
    // Collected separately: the `push_editable` closure borrows `editable`. Merged below.
    let mut start_editable: Vec<EditableParam> = Vec::new();
    let mut push_editable = |sv: &SimCodeVar::SimVar, name: &str, off: u32, wty: WTy| {
        if sv.isValueChangeable && is_result_output(sv) {
            if let Some(disp) = result_name(name) {
                editable.push(EditableParam {
                    name: disp,
                    comment: sv.comment.to_string(),
                    unit: sv.unit.to_string(),
                    off,
                    wty,
                    is_start: false,
                });
            }
        }
    };

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
        // Every state gets a start slot; value-changeable ones are also editable.
        let start_off = layout.state_start_off(i as u32);
        map.start_slots.insert(sim_cref_key(&sv.name)?, start_off);
        if sv.isValueChangeable && is_result_output(sv) {
            if let Some(disp) = result_name(&name) {
                start_editable.push(EditableParam {
                    name: disp,
                    comment: sv.comment.to_string(),
                    unit: sv.unit.to_string(),
                    off: start_off,
                    wty: WTy::F64,
                    is_start: true,
                });
            }
        }
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
        let off = layout.rparam_off + (k as u32) * 8;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, off, WTy::F64, false, name.clone())?;
        push_editable(sv, &name, off, WTy::F64);
    }
    for (i, sv) in lst(&vars.intAlgVars).enumerate() {
        let name = cref_display(&sv.name)?;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, layout.int_off + (i as u32) * 4, WTy::I32, false, name)?;
    }
    for (k, sv) in lst(&vars.intParamVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.iparam_off + (k as u32) * 4;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, off, WTy::I32, false, name.clone())?;
        push_editable(sv, &name, off, WTy::I32);
    }
    for (i, sv) in lst(&vars.boolAlgVars).enumerate() {
        let name = cref_display(&sv.name)?;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, layout.bool_off + (i as u32) * 4, WTy::I32, false, name)?;
    }
    for (k, sv) in lst(&vars.boolParamVars).enumerate() {
        let name = cref_display(&sv.name)?;
        let off = layout.bparam_off + (k as u32) * 4;
        push_primary(&mut map, &mut result_vars, &mut filtered, sv, off, WTy::I32, false, name.clone())?;
        push_editable(sv, &name, off, WTy::I32);
    }
    for (i, sv) in lst(&vars.stringAlgVars).enumerate() {
        insert_var(&mut map, sv, layout.str_off + (i as u32) * 4, WTy::I32, true)?;
    }
    for (k, sv) in lst(&vars.stringParamVars).enumerate() {
        insert_var(&mut map, sv, layout.sparam_off + (k as u32) * 4, WTy::I32, true)?;
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
        map.vars.insert(key, slot);
    }

    finalize_array_groups(&mut map)?;
    editable.extend(start_editable);
    Ok((map, result_vars, editable))
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
        let Some(first) = elems.first() else { continue };
        let rank = first.0.len();
        if elems.iter().any(|(s, _, _)| s.len() != rank) {
            return Err("CodegenWasmJit: inconsistent subscript rank for array variable `{base}`");
        }
        // Shape: 1-based max index per axis.
        let mut dims = vec![0u32; rank];
        for (subs, _, _) in &elems {
            for (axis, &ix) in subs.iter().enumerate() {
                if ix < 1 {
                    return Err("CodegenWasmJit: non-positive subscript {ix} for array variable `{base}`");
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
        let wty = first.2;
        if elems.iter().any(|(_, _, w)| *w != wty) {
            return Err("CodegenWasmJit: mixed element types for array variable `{base}`");
        }
        let stride = match wty { WTy::F64 => 8, WTy::I32 => 4 };
        let Some(base_off) = elems.iter().map(|(_, o, _)| *o).min() else { continue };
        // Verify contiguous, row-major layout.
        for (subs, off, _) in &elems {
            let mut lin: u32 = 0;
            for (axis, &ix) in subs.iter().enumerate() {
                lin = lin * dims[axis] + (ix as u32 - 1);
            }
            let expected = base_off + lin * stride;
            if *off != expected {
                return Err("error");
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
    Math { kind: MathEventKind, ops: Vec<Arc<DAE::Exp>>, idx: u32 },
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
        other => return Err("CodegenWasmJit: math-event index is not a non-negative ICONST: {other:?}"),
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
        if zc.iter.is_some() {
            return Err("CodegenWasmJit: for-loop (iterator) zero-crossing not yet supported: {:?}");
        }
        match &*zc.relation_ {
            DAE::Exp::RELATION { .. } | DAE::Exp::LBINARY { .. } | DAE::Exp::LUNARY { .. } => {
                out.push(ZcInfo::Bool { expr: zc.relation_.clone() });
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
                out.push(ZcInfo::Math { kind, ops, idx });
            }
            other => return Err("CodegenWasmJit: unsupported zero-crossing form: {other:?}"),
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

fn build_sim_model(sim_code: &SimCode::SimCode) -> Result<SimModel> {
    let mi = &sim_code.modelInfo;
    let vi = &mi.varInfo;
    let vars = &mi.vars;
    let states: Vec<&SimCodeVar::SimVar> = lst(&vars.stateVars).collect();

    let n_states = vi.numStateVars.max(0) as u32;
    let n_real_alg = (count(&vars.algVars) + count(&vars.discreteAlgVars)) as u32;
    let n_real_param = count(&vars.paramVars) as u32;
    let samples = collect_samples(&sim_code.timeEvents)?;
    let zero_crossings = collect_zero_crossings(&sim_code.zeroCrossings)?;
    let stateset_scratch_f64 = stateset_scratch_f64(&sim_code.stateSets)?;
    let all_eqs = flatten_eqs(&sim_code.allEquations);
    let has_when = all_eqs.iter().any(|e| matches!(&**e, SimCode::SimEqSystem::SES_WHEN { .. }));
    // The backend only emits a lambda-0 initial system when the model uses
    // `homotopy()`; its presence is the signal to wire up the continuation.
    let has_homotopy = (&*sim_code.initialEquations_lambda0).into_iter().next().is_some();
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
        vi.numMathEventFunctions.max(0) as u32,
        has_when,
        has_homotopy,
    );

    let (mut var_map, result_vars, editable_params) = build_var_map(vars, &layout)?;
    let var_units = collect_var_units(vars)?;
    // Sample event index -> its slot `k` (position in `samples`), for the
    // `sample(index,…)` builtin and the driver's per-sample state.
    let sample_map: HashMap<i32, u32> =
        samples.iter().enumerate().map(|(k, s)| (s.index, k as u32)).collect();
    var_map.sample_map = Arc::new(sample_map);
    var_map.sample_active_off = layout.sample_active_off;

    // State sets: register the Jacobian seed/result crefs at the scratch region
    // and collect the driver-side selection metadata (candidate/state/A offsets).
    let state_sets = build_state_set_infos(&sim_code.stateSets, &layout, &mut var_map)?;

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
            matches!(f, SimCodeFunction::Function::Function::FUNCTION { .. })
                || external_known(f)
                || external_general(f)
        })
        .collect();

    // Distinct `ext.<extName>` host imports for the general external scalar
    // functions, resolved by the host at instantiation (dlopen-self native; a
    // side module on wasm). Models without such externals emit none.
    let mut ext_imports: Vec<ExtCallSig> = Vec::new();
    let mut ext_seen: HashSet<String> = HashSet::new();
    for f in &model_fns {
        if external_general(f) {
            let sig = external_import_sig(f)?;
            if ext_seen.insert(sig.name.clone()) {
                ext_imports.push(sig);
            }
        }
    }

    // Function index space: imports (env builtins, rt runtime, env-extra, then
    // the `ext.*` externals), then the model's Modelica functions, then the
    // generated equation functions.
    let ext_base = (BUILTINS.len() + RT_BUILTINS.len() + ENV_EXTRA.len()) as u32;
    let import_base = ext_base + ext_imports.len() as u32;
    let mut by_name: HashMap<String, FnInfo> = HashMap::new();
    for (i, sig) in ext_imports.iter().enumerate() {
        by_name.insert(format!("ext.{}", sig.name), FnInfo { index: ext_base + i as u32, sig: sig.wasm_sig() });
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
    let param_bindings = collect_param_bindings(vars, &assigned_cref_keys(&param_eqs));
    // When the model has `when`-equations, the discrete update (when-bodies with
    // edge detection) must run each step between the condition and output
    // equations. `allEquations` is the full solved list in that order, so it is
    // used as the per-step function (in place of `algebraicEquations`), and
    // pre-values are saved after each step so the next step's edge test sees them.
    let algebraic_eqs = if has_when { all_eqs } else { flatten_eqs_ll(&sim_code.algebraicEquations) };
    // pre := live regions, appended to the per-step (algebraic) function when the
    // model has `when`-equations (see `sim_save_pre_values`).
    let save_pre: Vec<(u32, u32, u32)> = if has_when {
        vec![
            (layout.pre_real_off, REAL_OFF, (2 * layout.n_states + layout.n_real_alg) * 8),
            (layout.pre_int_off, layout.int_off, layout.n_int_alg() * 4),
            (layout.pre_bool_off, layout.bool_off, layout.n_bool_alg() * 4),
        ]
    } else {
        Vec::new()
    };
    let initial_eqs = flatten_eqs(&sim_code.initialEquations);
    let lambda0_eqs = flatten_eqs(&sim_code.initialEquations_lambda0);
    let ode_eqs = flatten_eqs_ll(&sim_code.odeEquations);
    // Register every nonlinear system with the runtime solver `rt_solve_nls`
    // *before* lowering the equation functions (which call it): assign each a
    // shared-table job and thread the map through `var_map`. The systems' own
    // `residual`/`load` callbacks are emitted after the equation functions.
    let (nls_systems, nls_jobs, nls_hist_bytes) =
        collect_nls_jobs(&[&param_eqs, &initial_eqs, &lambda0_eqs, &ode_eqs, &algebraic_eqs]);
    var_map.nls_jobs = Arc::new(nls_jobs);

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
        types.ty().function(
            sig.wasm_params().iter().map(|s| s.wty().val()),
            sig.wasm_results().iter().map(|s| s.wty().val()),
        );
        ext_type.push(ti);
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
    // Nonlinear-solver callback + `start` types (only when the model has
    // nonlinear systems, so output stays byte-identical otherwise): `residual`
    // (i32,i32,i32)->(), `load` (i32,i32)->(), `start` ()->().
    let nls_types = if nls_systems.is_empty() {
        None
    } else {
        let residual_type = types.len();
        types.ty().function([we::ValType::I32, we::ValType::I32, we::ValType::I32], []);
        let load_type = types.len();
        types.ty().function([we::ValType::I32, we::ValType::I32], []);
        let start_type = types.len();
        types.ty().function([], []);
        Some((residual_type, load_type, start_type))
    };

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
    // Share the runtime's `__indirect_function_table` (as with `rt.memory`) so
    // the `start` function can append this model's `residual`/`load` callbacks and
    // `rt_solve_nls` can reach them by `call_indirect`.
    if !nls_systems.is_empty() {
        imports.import("rt", "__indirect_function_table", we::EntityType::Table(we::TableType {
            element_type: we::RefType::FUNCREF,
            table64: false,
            minimum: 1,
            maximum: None,
            shared: false,
        }));
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
    // Equation functions.
    let stateset_diag = stateset_diag_offsets(&sim_code.stateSets, &var_map)?;
    bodies.push(build_eq_fn_with_prelude("parameterEquations", &param_bindings, param_eqs, &var_map, &eq_index, &by_name, &mut literals, &[], &stateset_diag)?);
    // Seed `relationsPre := relations` at the end of init (the in-wasm `simulate`
    // path skips the host `run_initialization`).
    let init_save: Vec<(u32, u32, u32)> = if layout.n_rel > 0 {
        vec![(layout.relations_pre_off, layout.relations_off, layout.n_rel * 4)]
    } else {
        Vec::new()
    };
    bodies.push(build_eq_fn_with_prelude("initialEquations", &[], initial_eqs, &var_map, &eq_index, &by_name, &mut literals, &init_save, &[])?);
    bodies.push(build_eq_fn("odeEquations", ode_eqs, &var_map, &eq_index, &by_name, &mut literals)?);
    bodies.push(build_eq_fn_with_prelude("algebraicEquations", &[], algebraic_eqs, &var_map, &eq_index, &by_name, &mut literals, &save_pre, &[])?);
    // eq_base + 4, before `simulate` so the in-wasm integrator can call it.
    bodies.push(build_init_start_values_fn(&states, &layout, &var_map, &by_name, &mut literals)?);
    // The integrator loop.
    bodies.push(build_simulate(&layout, &eqfn)?);

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
        f.instruction(&I::Call(rt_index("rt_alloc")?));
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

    // --- External-object destructors (teardown). One function that calls each
    // extObj's `<class>.destructor(handle)` in reverse construction order, reading
    // the handle from its SimData slot. Emitted (and exported) only when the model
    // has external objects, so output is byte-identical otherwise. ---
    let extobj_vars: Vec<&SimCodeVar::SimVar> = lst(&vars.extObjVars).collect();
    let destructors_idx = if extobj_vars.is_empty() {
        None
    } else {
        use we::Instruction as I;
        let mut f = we::Function::new([]);
        for (i, sv) in extobj_vars.iter().enumerate().rev() {
            let key = extobj_destructor_key(sv)?;
            let didx = by_name
                .get(&key)
                .ok_or_else(|| "CodegenWasmJit: external-object destructor `{key}` was not compiled")?
                .index;
            let slot = layout.eobj_off + (i as u32) * 4;
            f.instruction(&I::LocalGet(0)); // SimData*
            f.instruction(&I::I32Load(crate::CodegenWasmJitFunctions::mem_arg(slot, 2))); // handle
            f.instruction(&I::Call(didx));
        }
        f.instruction(&I::End);
        bodies.push(f);
        Some(eq_base + 8)
    };

    // --- Nonlinear-system callbacks + `start`. For each system emit its
    // `residual`/`load` functions, then one `start` function that appends them to
    // the shared table (base recorded in the `nls_base` global). All `ref.func`d
    // callbacks are also listed in a declared element segment (below) so the
    // references validate. Emitted only when the model has nonlinear systems. ---
    let nls_wiring = if let Some((_, _, _)) = nls_types {
        let mut callback_indices: Vec<u32> = Vec::new(); // for the declared segment
        let mut fn_indices: Vec<(u32, u32)> = Vec::new(); // (residual, load) per system
        for sys in &nls_systems {
            let (res_fn, load_fn) = build_nls_fns(sys, &var_map, &eq_index, &by_name, &mut literals)?;
            let res_idx = import_base + bodies.len() as u32;
            bodies.push(res_fn);
            let load_idx = import_base + bodies.len() as u32;
            bodies.push(load_fn);
            callback_indices.push(res_idx);
            callback_indices.push(load_idx);
            fn_indices.push((res_idx, load_idx));
        }
        let start_idx = import_base + bodies.len() as u32;
        bodies.push(build_nls_start_fn(&fn_indices, nls_hist_bytes));
        Some((start_idx, callback_indices))
    } else {
        None
    };

    // --- initSample: appended last so the indices above are undisturbed. Emitted
    // (and exported) only when the model has samples. ---
    let init_sample_idx = if samples.is_empty() {
        None
    } else {
        let idx = import_base + bodies.len() as u32;
        bodies.push(build_init_sample_fn(&samples, &layout, &var_map, &by_name, &mut literals)?);
        Some(idx)
    };
    let zc_idx = if zero_crossings.is_empty() {
        None
    } else {
        let idx = import_base + bodies.len() as u32;
        bodies.push(build_zero_crossings_fn(&zero_crossings, &layout, &var_map, &by_name, &mut literals)?);
        Some(idx)
    };
    let stateset_jac_idx = if state_sets.is_empty() {
        None
    } else {
        let idx = import_base + bodies.len() as u32;
        bodies.push(build_stateset_jac_fn(&sim_code.stateSets, &var_map, &eq_index, &by_name, &mut literals)?);
        Some(idx)
    };
    // The lambda-0 (simplified) initial system, for the homotopy continuation's
    // first step. Emitted only for models that use `homotopy()`.
    let init_lambda0_idx = if lambda0_eqs.is_empty() {
        None
    } else {
        let idx = import_base + bodies.len() as u32;
        bodies.push(build_eq_fn("initialEquations_lambda0", lambda0_eqs, &var_map, &eq_index, &by_name, &mut literals)?);
        Some(idx)
    };

    // --- Function section (type index per body, in body order). ---
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
    if destructors_idx.is_some() {
        functions.function(eqfn_type); // callExternalObjectDestructors
    }
    if let Some((residual_type, load_type, start_type)) = nls_types {
        for _ in &nls_systems {
            functions.function(residual_type);
            functions.function(load_type);
        }
        functions.function(start_type);
    }
    if init_sample_idx.is_some() {
        functions.function(eqfn_type); // initSample: (i32) -> ()
    }
    if zc_idx.is_some() {
        functions.function(eqfn_type); // functionZeroCrossings: (i32) -> ()
    }
    if stateset_jac_idx.is_some() {
        functions.function(eqfn_type); // functionStateSetJacobians: (i32) -> ()
    }
    if init_lambda0_idx.is_some() {
        functions.function(eqfn_type); // functionInitialEquations_lambda0: (i32) -> ()
    }

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
    exports.export("functionInitStartValues", we::ExportKind::Func, eqfn.init_start_values);
    exports.export("functionODE", we::ExportKind::Func, eqfn.ode);
    exports.export("functionAlgebraics", we::ExportKind::Func, eqfn.algebraics);
    exports.export("simulate", we::ExportKind::Func, simulate_idx);
    exports.export("om_meta_ptr", we::ExportKind::Func, om_meta_ptr_idx);
    exports.export("om_meta_len", we::ExportKind::Func, om_meta_len_idx);
    if let Some(idx) = destructors_idx {
        exports.export("callExternalObjectDestructors", we::ExportKind::Func, idx);
    }
    if let Some(idx) = init_sample_idx {
        exports.export("initSample", we::ExportKind::Func, idx);
    }
    if let Some(idx) = zc_idx {
        exports.export("functionZeroCrossings", we::ExportKind::Func, idx);
    }
    if let Some(idx) = stateset_jac_idx {
        exports.export("functionStateSetJacobians", we::ExportKind::Func, idx);
    }
    if let Some(idx) = init_lambda0_idx {
        exports.export("functionInitialEquations_lambda0", we::ExportKind::Func, idx);
    }

    let mut module = we::Module::new();
    module.section(&types);
    module.section(&imports);
    module.section(&functions);
    // Global + Start + Element sections (in the canonical order) carry the
    // nonlinear-solver table wiring; present only when the model has NLS systems.
    if nls_wiring.is_some() {
        let mut globals = we::GlobalSection::new();
        // NLS_BASE_GLOBAL (shared-table base) and NLS_HIST_GLOBAL (history block
        // base); both are set by the module `start` function.
        for _ in 0..2 {
            globals.global(
                we::GlobalType { val_type: we::ValType::I32, mutable: true, shared: false },
                &we::ConstExpr::i32_const(0),
            );
        }
        module.section(&globals);
    }
    module.section(&exports);
    if let Some((start_idx, callback_indices)) = &nls_wiring {
        module.section(&we::StartSection { function_index: *start_idx });
        let mut elements = we::ElementSection::new();
        elements.declared(we::Elements::Functions(callback_indices.as_slice().into()));
        module.section(&elements);
    }
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
        ext_imports,
        model_name,
        start_time: settings.startTime.into_inner(),
        stop_time: settings.stopTime.into_inner(),
        n_intervals: settings.numberOfIntervals.max(0) as u32,
        output_format: settings.outputFormat.to_string(),
        method: settings.method.to_string(),
        tolerance: settings.tolerance.into_inner(),
        state_sets,
        jac_a: build_jac_a_info(sim_code, n_states),
        state_nominals: lst(&vars.stateVars)
            .take(n_states as usize)
            .map(|sv| const_value(&sv.nominalValue).unwrap_or(1.0).abs().max(1e-32))
            .collect(),
        editable_params,
        var_units,
    })
}

/// ODE state Jacobian ("A" = ∂f/∂x) sparsity + coloring, extracted from
/// `SimCode.jacobianMatrices`. Column/row indices are 0-based and correspond
/// directly to the integrator state order (same convention the C runtime's
/// `jacA_numColored` relies on). Data only — the finite-difference itself runs
/// in the driver via the existing residual machinery, so no wasm code is emitted.
#[derive(Clone, Debug)]
pub(crate) struct JacAInfo {
    pub n: usize,
    /// Each color: the 0-based column (state) indices perturbed together.
    pub colors: Vec<Vec<u32>>,
    /// `rows_by_col[col]` = 0-based rows nonzero in column `col` (CSC).
    pub rows_by_col: Vec<Vec<u32>>,
}

fn build_jac_a_info(sim_code: &SimCode::SimCode, n_states: u32) -> Option<JacAInfo> {
    if n_states == 0 {
        return None;
    }
    let n = n_states as usize;
    let jac = lst(&sim_code.jacobianMatrices).find(|j| &*j.matrixName == "A")?;
    // sparsity: positional per column → 0-based nonzero rows (CSC), one entry per
    // column (empty columns carry an empty row list).
    let rows_by_col: Vec<Vec<u32>> = lst(&jac.sparsity)
        .map(|(_, rows)| lst(rows).map(|r| *r as u32).collect())
        .collect();
    // coloredCols: each color → its 0-based column indices.
    let colors: Vec<Vec<u32>> = lst(&jac.coloredCols)
        .map(|grp| lst(grp).map(|c| *c as u32).collect())
        .collect();
    // Only usable when the pattern covers exactly the n states, the coloring is
    // present, and every index is in range; otherwise fall back to numerical.
    if rows_by_col.len() != n
        || colors.is_empty()
        || colors.iter().flatten().any(|&c| c as usize >= n)
        || rows_by_col.iter().flatten().any(|&r| r as usize >= n)
    {
        return None;
    }
    if std::env::var("OMC_WASM_SIM_BENCH").is_ok() {
        let nnz: usize = rows_by_col.iter().map(|r| r.len()).sum();
        eprintln!("wasm-jit jac-A: n={n} colors={} nnz={nnz}", colors.len());
    }
    Some(JacAInfo { n, colors, rows_by_col })
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
    let states: Vec<&SimCodeVar::SimVar> = lst(&vars.stateVars).collect();
    for sv in &states {
        add(cref_display(&sv.name)?, sv);
    }
    for (i, sv) in lst(&vars.derivativeVars).enumerate() {
        let name = match states.get(i) {
            Some(s) => format!("der({})", cref_display(&s.name)?),
            None => cref_display(&sv.name)?,
        };
        add(name, sv);
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
pub(crate) fn t_real() -> Arc<DAE::Type> {
    Arc::new(DAE::Type::T_REAL { varLst: metamodelica::nil() })
}

fn count<T: Clone>(list: &Arc<List<T>>) -> usize {
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
        // A parameter computed by a parameterEquation (e.g. `u_max =
        // getTable1DAbscissaUmax(tableID)`, scheduled after the table
        // constructor) must not also be assigned from its binding here: the
        // prelude runs before parameterEquations, so it would evaluate the
        // binding against not-yet-initialized dependencies (a null handle).
        if let Some(v) = &p.initialValue {
            if sim_cref_key(&p.name).map(|k| computed.contains(&k)).unwrap_or(false) {
                continue;
            }
            out.push((p.name.clone(), v.clone()));
        }
    }
    out
}

/// Keys of the crefs assigned by a `SimEqSystem` list (scalar/array assigns).
fn assigned_cref_keys(eqs: &[Arc<SimCode::SimEqSystem>]) -> std::collections::HashSet<String> {
    use SimCode::SimEqSystem as E;
    let mut set = std::collections::HashSet::new();
    for eq in eqs {
        let cr = match &**eq {
            E::SES_SIMPLE_ASSIGN { cref, .. } => Some(cref.clone()),
            E::SES_ARRAY_CALL_ASSIGN { lhs, .. } => match &**lhs {
                DAE::Exp::CREF { componentRef, .. } => Some(componentRef.clone()),
                _ => None,
            },
            _ => None,
        };
        if let Some(cr) = cr {
            if let Ok(k) = sim_cref_key(&cr) {
                set.insert(k);
            }
        }
    }
    set
}

fn build_eq_fn(
    which: &str,
    eqs: Vec<Arc<SimCode::SimEqSystem>>,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Vec<Vec<u8>>,
) -> Result<we::Function> {
    build_eq_fn_with_prelude(which, &[], eqs, var_map, eq_index, by_name, literals, &[], &[])
}

fn build_eq_fn_with_prelude(
    which: &str,
    prelude: &[(Arc<DAE::ComponentRef>, Arc<DAE::Exp>)],
    eqs: Vec<Arc<SimCode::SimEqSystem>>,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Vec<Vec<u8>>,
    save_pre: &[(u32, u32, u32)],
    stateset_diag: &[u32],
) -> Result<we::Function> {
    let sim = SimCtx {
        data_local: 0,
        vars: var_map.vars.clone(),
        starts: var_map.starts.clone(),
        start_slots: var_map.start_slots.clone(),
        array_groups: var_map.array_groups.clone(),
        terminate_off: var_map.terminate_off,
        nls_fail_off: var_map.nls_fail_off,
        nls_jobs: var_map.nls_jobs.clone(),
        sample_map: var_map.sample_map.clone(),
        sample_active_off: var_map.sample_active_off,
        relations_off: var_map.relations_off,
        rel_fresh_off: var_map.rel_fresh_off,
        stored_rel_off: var_map.stored_rel_off,
        relations_pre_off: var_map.relations_pre_off,
        n_relations: var_map.n_relations,
        mathevents_off: var_map.mathevents_off,
        n_mathevents: var_map.n_mathevents,
        lambda_off: var_map.lambda_off,
        zctol_off: var_map.zctol_off,
        zc_context: false,
    };
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_stateset_diag_init(stateset_diag)?;
    for (cref, exp) in prelude {
        let lhs = DAE::Exp::CREF { componentRef: cref.clone(), ty: t_real() };
        ctx.sim_assign(&lhs, exp).map_err(|e| "in {which} binding: {e}")?;
    }
    for eq in &eqs {
        lower_equation(&mut ctx, eq, eq_index)
            .map_err(|e| "in {which}: {e}")?;
    }
    ctx.sim_save_pre_values(save_pre)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build the `initSample(SimData*)` function: evaluate each sample's
/// `start`/`interval` into the sample region (see [`FnCtx::emit_init_sample`]).
/// Called by the driver after `functionParameters`.
fn build_init_sample_fn(
    samples: &[SampleInfo],
    layout: &SimLayout,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Vec<Vec<u8>>,
) -> Result<we::Function> {
    let sim = SimCtx {
        data_local: 0,
        vars: var_map.vars.clone(),
        starts: var_map.starts.clone(),
        start_slots: var_map.start_slots.clone(),
        array_groups: var_map.array_groups.clone(),
        terminate_off: var_map.terminate_off,
        nls_fail_off: var_map.nls_fail_off,
        nls_jobs: var_map.nls_jobs.clone(),
        sample_map: var_map.sample_map.clone(),
        sample_active_off: var_map.sample_active_off,
        relations_off: var_map.relations_off,
        rel_fresh_off: var_map.rel_fresh_off,
        stored_rel_off: var_map.stored_rel_off,
        relations_pre_off: var_map.relations_pre_off,
        n_relations: var_map.n_relations,
        mathevents_off: var_map.mathevents_off,
        n_mathevents: var_map.n_mathevents,
        lambda_off: var_map.lambda_off,
        zctol_off: var_map.zctol_off,
        zc_context: false,
    };
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

/// Build `functionInitStartValues(SimData*)`: fill each state's start slot from its
/// `start` expression. Called after `functionParameters` (so parameter-bound starts
/// see final values) and before the initial equations. Empty `start_slots` here so
/// the expressions compile inline (slots fill exactly as the old inline read).
fn build_init_start_values_fn(
    states: &[&SimCodeVar::SimVar],
    layout: &SimLayout,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Vec<Vec<u8>>,
) -> Result<we::Function> {
    let sim = SimCtx {
        data_local: 0,
        vars: var_map.vars.clone(),
        starts: var_map.starts.clone(),
        start_slots: HashMap::new(),
        array_groups: var_map.array_groups.clone(),
        terminate_off: var_map.terminate_off,
        nls_fail_off: var_map.nls_fail_off,
        nls_jobs: var_map.nls_jobs.clone(),
        sample_map: var_map.sample_map.clone(),
        sample_active_off: var_map.sample_active_off,
        relations_off: var_map.relations_off,
        rel_fresh_off: var_map.rel_fresh_off,
        stored_rel_off: var_map.stored_rel_off,
        relations_pre_off: var_map.relations_pre_off,
        n_relations: var_map.n_relations,
        mathevents_off: var_map.mathevents_off,
        n_mathevents: var_map.n_mathevents,
        lambda_off: var_map.lambda_off,
        zctol_off: var_map.zctol_off,
        zc_context: false,
    };
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    let mut pairs: Vec<(Option<Arc<DAE::Exp>>, u32)> = Vec::with_capacity(states.len());
    for (i, sv) in states.iter().enumerate() {
        pairs.push((sv.initialValue.clone(), layout.state_start_off(i as u32)));
    }
    ctx.emit_init_start_values(&pairs)?;
    let (locals, instrs) = ctx.finish_sim();
    let mut func = we::Function::new(locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Build the `functionZeroCrossings(SimData*)` function: evaluate each crossing's
/// `lhs - rhs` into the zero-crossing region (see [`FnCtx::emit_zero_crossings`]).
/// Called by the driver's DASKR root callback.
fn build_zero_crossings_fn(
    crossings: &[ZcInfo],
    layout: &SimLayout,
    var_map: &SimVarMap,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Vec<Vec<u8>>,
) -> Result<we::Function> {
    let sim = SimCtx {
        data_local: 0,
        vars: var_map.vars.clone(),
        starts: var_map.starts.clone(),
        start_slots: var_map.start_slots.clone(),
        array_groups: var_map.array_groups.clone(),
        terminate_off: var_map.terminate_off,
        nls_fail_off: var_map.nls_fail_off,
        nls_jobs: var_map.nls_jobs.clone(),
        sample_map: var_map.sample_map.clone(),
        sample_active_off: var_map.sample_active_off,
        relations_off: var_map.relations_off,
        rel_fresh_off: var_map.rel_fresh_off,
        stored_rel_off: var_map.stored_rel_off,
        relations_pre_off: var_map.relations_pre_off,
        n_relations: var_map.n_relations,
        mathevents_off: var_map.mathevents_off,
        n_mathevents: var_map.n_mathevents,
        lambda_off: var_map.lambda_off,
        zctol_off: var_map.zctol_off,
        zc_context: true,
    };
    let mut ctx = FnCtx::new_sim(sim, by_name, literals);
    ctx.emit_zero_crossings(crossings, layout.zc_off)?;
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
        E::SES_WHEN { conditions, whenStmtLst, elseWhen, .. } => {
            ctx.sim_when(conditions, whenStmtLst, elseWhen)
        }
        // An alias equation re-runs another equation (by index): inline it.
        E::SES_ALIAS { aliasOf, .. } => {
            let target = eq_index
                .get(aliasOf)
                .ok_or_else(|| "SES_ALIAS references unknown equation index {aliasOf}")?
                .clone();
            lower_equation(ctx, &target, eq_index)
        }
        other => return Err("CodegenWasmJit: unsupported equation kind {} (index {})"),
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
        // Non-torn symbolic form: A from `simJac`, b from `beqs` (the C runtime's
        // setA/setb path). No inner equations — the entries are functions of the
        // already-computed variables.
        return lower_linear_system_symbolic(ctx, lsystem);
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

/// Lower a non-torn `SES_LINEAR` system given symbolically as `A x = b`, where
/// `A` comes from `simJac` (a sparse list of `(row, col, SES_RESIDUAL(exp))`,
/// 0-based, column-major) and `b` from `beqs` (one expression per row). Mirrors
/// the C `setLinearMatrixA`/`setLinearVectorb` + `dgesv` path: assemble A and b
/// (both functions of already-solved variables), solve, and scatter into `vars`.
fn lower_linear_system_symbolic(
    ctx: &mut FnCtx,
    lsystem: &SimCode::LinearSystem,
) -> Result<()> {
    use SimCode::SimEqSystem as E;
    let vars: Vec<Arc<DAE::ComponentRef>> = lst(&lsystem.vars).map(|v| v.name.clone()).collect();
    let n = vars.len();
    let mut a_entries: Vec<(usize, usize, &Arc<DAE::Exp>)> = Vec::new();
    for entry in lst(&lsystem.simJac) {
        let (row, col, eq) = entry;
        match &**eq {
            E::SES_RESIDUAL { exp, .. } => a_entries.push((*row as usize, *col as usize, exp)),
            other => return Err("CodegenWasmJit: SES_LINEAR (index {}) simJac entry is {} (only SES_RESIDUAL supported)"),
        }
    }
    let b_exps: Vec<&Arc<DAE::Exp>> = lst(&lsystem.beqs).collect();
    compile_linear_system_symbolic(ctx, &vars, n, &a_entries, &b_exps, lsystem.index)
}

/// Driver-side metadata for one `$STATESET`, so the runtime state selector can
/// evaluate the analytic Jacobian, pivot, and rebuild `A` (see `sim_driver.rs`).
/// All offsets are SimData-relative bytes.
#[derive(Clone, Debug)]
pub(crate) struct StateSetInfo {
    pub n_candidates: u32,
    pub n_states: u32,
    pub n_dummy: u32,
    /// Candidate variable slots (real), candidate order (matches the seeds).
    pub candidate_offs: Vec<u32>,
    /// State variable slots (real), state order.
    pub state_offs: Vec<u32>,
    /// `A[row][col]` integer slots, row-major (`a_offs[row*n_candidates + col]`).
    pub a_offs: Vec<u32>,
    /// Jacobian seed slots (f64), candidate order: set one to 1 to pick a column.
    pub seed_offs: Vec<u32>,
    /// Jacobian result slots (f64), row order (`n_dummy` of them) — column output.
    pub result_offs: Vec<u32>,
}

/// Total f64 count of the state-set Jacobian scratch region: each set contributes
/// its seed inputs (`n_candidates`) and its column result outputs (`n_dummy`).
fn stateset_scratch_f64(state_sets: &Arc<List<SimCode::StateSet>>) -> Result<u32> {
    let mut n = 0u32;
    for set in lst(state_sets) {
        let col = lst(&set.jacobianMatrix.columns)
            .next()
            .ok_or_else(|| "CodegenWasmJit: state set {} has no Jacobian column")?;
        n += count(&set.jacobianMatrix.seedVars) as u32 + count(&col.columnVars) as u32;
    }
    Ok(n)
}

/// Register each state set's Jacobian seed/result crefs at the scratch region and
/// collect the driver-side [`StateSetInfo`]. The seed vars (one per candidate) and
/// the column result vars get f64 scratch slots so the emitted
/// `functionStateSetJacobians` (which lowers the `columnEqns`) reads/writes them.
fn build_state_set_infos(
    state_sets: &Arc<List<SimCode::StateSet>>,
    layout: &SimLayout,
    var_map: &mut SimVarMap,
) -> Result<Vec<StateSetInfo>> {
    let mut infos = Vec::new();
    let mut cursor = layout.stateset_off;
    let real_slot = |var_map: &SimVarMap, cr: &Arc<DAE::ComponentRef>| -> Result<u32> {
        let key = sim_cref_key(cr)?;
        let slot = var_map
            .vars
            .get(&key)
            .ok_or_else(|| "CodegenWasmJit: state-set variable `{key}` has no slot")?;
        if slot.wty != WTy::F64 {
            return Err("CodegenWasmJit: state-set variable `{key}` is not a Real variable");
        }
        Ok(slot.off)
    };
    for set in lst(state_sets) {
        let n_candidates = set.nCandidates.max(0) as u32;
        let n_states = set.nStates.max(0) as u32;
        let n_dummy = n_candidates - n_states;
        let col = lst(&set.jacobianMatrix.columns)
            .next()
            .ok_or_else(|| "CodegenWasmJit: state set {} has no Jacobian column")?;

        // Seed slots (candidate order) — register the seed var crefs.
        let mut seed_offs = Vec::new();
        for sv in lst(&set.jacobianMatrix.seedVars) {
            let off = cursor;
            cursor += 8;
            var_map.vars.insert(sim_cref_key(&sv.name)?, SimSlot { off, wty: WTy::F64, negate: false, heap: false });
            seed_offs.push(off);
        }
        // Result slots (row order) — register the column result var crefs.
        let mut result_offs = Vec::new();
        for sv in lst(&col.columnVars) {
            let off = cursor;
            cursor += 8;
            var_map.vars.insert(sim_cref_key(&sv.name)?, SimSlot { off, wty: WTy::F64, negate: false, heap: false });
            result_offs.push(off);
        }

        let candidate_offs: Vec<u32> = lst(&set.statescandidates)
            .map(|cr| real_slot(var_map, cr))
            .collect::<Result<_>>()?;
        let state_offs: Vec<u32> = lst(&set.states)
            .map(|cr| real_slot(var_map, cr))
            .collect::<Result<_>>()?;

        // A[row][col] integer slots, row-major.
        let a_base_cref = openmodelica_frontend_dump::ComponentReferenceBasics::crefStripLastSubs(set.crA.clone())?;
        let a_base = sim_cref_key(&a_base_cref)?;
        let mut a_offs = Vec::new();
        for row in 1..=n_states {
            for c in 1..=n_candidates {
                let key = format!("{a_base}[{row}][{c}]");
                let slot = var_map
                    .vars
                    .get(&key)
                    .ok_or_else(|| "CodegenWasmJit: state-set matrix entry `{key}` has no slot")?;
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
        });
    }
    Ok(infos)
}

/// Build `functionStateSetJacobians(SimData*)`: run every state set's Jacobian
/// `columnEqns`, reading the seed slots and writing the result slots (both in the
/// scratch region). The driver seeds one candidate at a time and reads back one
/// Jacobian column (`getAnalyticalJacobianSet` in C's `stateset.c`).
fn build_stateset_jac_fn(
    state_sets: &Arc<List<SimCode::StateSet>>,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Vec<Vec<u8>>,
) -> Result<we::Function> {
    let mut eqs: Vec<Arc<SimCode::SimEqSystem>> = Vec::new();
    for set in lst(state_sets) {
        for col in lst(&set.jacobianMatrix.columns) {
            eqs.extend(lst(&col.columnEqns).cloned());
        }
    }
    build_eq_fn("functionStateSetJacobians", eqs, var_map, eq_index, by_name, literals)
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
        // `crA` names the `A[1,1]` element; strip its subscripts to the base `A`.
        let base_cref = openmodelica_frontend_dump::ComponentReferenceBasics::crefStripLastSubs(set.crA.clone())?;
        let base = sim_cref_key(&base_cref)?;
        for n in 1..=set.nStates {
            let key = format!("{base}[{n}][{n}]");
            let slot = var_map
                .vars
                .get(&key)
                .ok_or_else(|| "CodegenWasmJit: state-set matrix entry `{key}` has no slot")?;
            if slot.wty != WTy::I32 {
                return Err("CodegenWasmJit: state-set matrix entry `{key}` is not an Integer variable");
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
        .ok_or_else(|| "CodegenWasmJit: SES_NONLINEAR (index {}) was not registered for rt_solve_nls")?;
    emit_solve_nls_call(ctx, job)
}

/// Partition a nonlinear system's equations into the inner (torn) constraint
/// equations and the `SES_RESIDUAL` residual expressions, and its iteration
/// unknowns. Shared by [`collect_nls_jobs`] (which counts unknowns) and
/// [`build_nls_fns`] (which emits the callbacks).
fn nls_parts(
    nlsystem: &SimCode::NonlinearSystem,
) -> Result<(Vec<Arc<SimCode::SimEqSystem>>, Vec<Arc<DAE::Exp>>, Vec<Arc<DAE::ComponentRef>>)> {
    use SimCode::SimEqSystem as E;
    let mut inner: Vec<Arc<SimCode::SimEqSystem>> = Vec::new();
    let mut res_exps: Vec<Arc<DAE::Exp>> = Vec::new();
    for e in lst(&nlsystem.eqs) {
        match &**e {
            E::SES_RESIDUAL { exp, .. } => res_exps.push(exp.clone()),
            _ => inner.push(e.clone()),
        }
    }
    if res_exps.is_empty() {
        return Err("CodegenWasmJit: SES_NONLINEAR (index {}) has no residual equations");
    }
    let iter_vars: Vec<Arc<DAE::ComponentRef>> = lst(&nlsystem.crefs).cloned().collect();
    if iter_vars.len() != res_exps.len() {
        return Err("CodegenWasmJit: SES_NONLINEAR (index {}) has {} unknowns but {} residuals");
    }
    Ok((inner, res_exps, iter_vars))
}

/// Scan the compiled equation lists for `SES_NONLINEAR` systems (deduplicated by
/// index, in first-seen order) and assign each an `rt_solve_nls` job. Returns the
/// ordered systems (for [`build_nls_fns`]) and the index -> job map, which is
/// threaded to the equation lowering via `SimVarMap`/`SimCtx`.
fn collect_nls_jobs(
    eq_lists: &[&[Arc<SimCode::SimEqSystem>]],
) -> (Vec<Arc<SimCode::NonlinearSystem>>, HashMap<i32, NlsJob>, u32) {
    use SimCode::SimEqSystem as E;
    let mut systems: Vec<Arc<SimCode::NonlinearSystem>> = Vec::new();
    let mut jobs: HashMap<i32, NlsJob> = HashMap::new();
    let mut hist_off = 0u32;
    for list in eq_lists {
        for e in *list {
            if let E::SES_NONLINEAR { nlSystem, .. } = &**e {
                if jobs.contains_key(&nlSystem.index) {
                    continue;
                }
                let n = lst(&nlSystem.crefs).count() as u32;
                jobs.insert(nlSystem.index, NlsJob { k: systems.len() as u32, n, hist_off });
                hist_off += crate::CodegenWasmJitFunctions::nls_hist_bytes(n);
                systems.push(nlSystem.clone());
            }
        }
    }
    (systems, jobs, hist_off)
}

/// Build the `residual(sim_data, x, r)` and `load(sim_data, x)` callback
/// functions for one nonlinear system (the model-specific half of
/// `rt_solve_nls`, reached by `call_indirect` over the shared table).
fn build_nls_fns(
    nlsystem: &SimCode::NonlinearSystem,
    var_map: &SimVarMap,
    eq_index: &HashMap<i32, Arc<SimCode::SimEqSystem>>,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Vec<Vec<u8>>,
) -> Result<(we::Function, we::Function)> {
    let (inner, res_exps, iter_vars) = nls_parts(nlsystem)?;
    // Resolve each unknown to its (real) SimData slot offset.
    let mut slots: Vec<u32> = Vec::with_capacity(iter_vars.len());
    for cr in &iter_vars {
        let key = sim_cref_key(cr)?;
        let slot = var_map
            .vars
            .get(&key)
            .copied()
            .ok_or_else(|| "CodegenWasmJit: nonlinear-system unknown `{key}` has no slot")?;
        if slot.wty != WTy::F64 {
            return Err("CodegenWasmJit: nonlinear-system unknown `{key}` is not a Real variable");
        }
        slots.push(slot.off);
    }
    let mk_sim = || SimCtx {
        data_local: 0,
        vars: var_map.vars.clone(),
        starts: var_map.starts.clone(),
        start_slots: var_map.start_slots.clone(),
        array_groups: var_map.array_groups.clone(),
        terminate_off: var_map.terminate_off,
        nls_fail_off: var_map.nls_fail_off,
        nls_jobs: var_map.nls_jobs.clone(),
        sample_map: var_map.sample_map.clone(),
        sample_active_off: var_map.sample_active_off,
        relations_off: var_map.relations_off,
        rel_fresh_off: var_map.rel_fresh_off,
        stored_rel_off: var_map.stored_rel_off,
        relations_pre_off: var_map.relations_pre_off,
        n_relations: var_map.n_relations,
        mathevents_off: var_map.mathevents_off,
        n_mathevents: var_map.n_mathevents,
        lambda_off: var_map.lambda_off,
        zctol_off: var_map.zctol_off,
        zc_context: false,
    };
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
        let mut lower_inner = |c: &mut FnCtx| -> Result<()> {
            for eq in &inner {
                lower_equation(c, eq, eq_index)?;
            }
            Ok(())
        };
        emit_nls_residual_body(&mut ctx, &slots, &res_exps, &mut lower_inner)?;
        finish(ctx)
    };
    // load(sim_data, x): 2 params.
    let load = {
        let mut ctx = FnCtx::new_sim_params(mk_sim(), by_name, literals, 2);
        emit_nls_load_body(&mut ctx, &slots)?;
        finish(ctx)
    };
    Ok((residual, load))
}

/// Build the module `start` function: grow the shared
/// `rt.__indirect_function_table` by `2 * n` slots, record the base (the old
/// size) in the `nls_base` global, then write each system's `residual`/`load`
/// function references into `base + 2k` / `base + 2k + 1`
/// (`fn_indices[k] = (residual, load)`). `rt_solve_nls` reads these indices back
/// via the global (see `emit_solve_nls_call`). Also `rt_alloc`s the
/// extrapolation-history block (`hist_bytes`) into `NLS_HIST_GLOBAL`.
fn build_nls_start_fn(fn_indices: &[(u32, u32)], hist_bytes: u32) -> we::Function {
    use we::Instruction as I;
    let mut f = we::Function::new([]);
    // history block (zeroed by rt_alloc, so every system's count starts 0).
    if hist_bytes > 0 {
        f.instruction(&I::I32Const(hist_bytes as i32));
        f.instruction(&I::Call(rt_index("rt_alloc").expect("rt_alloc is a runtime builtin")));
        f.instruction(&I::GlobalSet(NLS_HIST_GLOBAL));
    }
    // base = table.grow(null, 2n) — returns the old size (the growable table's max
    // is unbounded, so this cannot fail here).
    f.instruction(&I::RefNull(we::HeapType::FUNC));
    f.instruction(&I::I32Const((2 * fn_indices.len()) as i32));
    f.instruction(&I::TableGrow(0));
    f.instruction(&I::GlobalSet(NLS_BASE_GLOBAL));
    for (k, (res_idx, load_idx)) in fn_indices.iter().enumerate() {
        let base_off = (2 * k) as i32;
        f.instruction(&I::GlobalGet(NLS_BASE_GLOBAL));
        f.instruction(&I::I32Const(base_off));
        f.instruction(&I::I32Add);
        f.instruction(&I::RefFunc(*res_idx));
        f.instruction(&I::TableSet(0));
        f.instruction(&I::GlobalGet(NLS_BASE_GLOBAL));
        f.instruction(&I::I32Const(base_off + 1));
        f.instruction(&I::I32Add);
        f.instruction(&I::RefFunc(*load_idx));
        f.instruction(&I::TableSet(0));
    }
    f.instruction(&I::End);
    f
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
fn build_simulate(layout: &SimLayout, eqfn: &EqFnIdx) -> Result<we::Function> {
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

    // lambda = 1.0 so homotopy(a, s) evaluates to the actual expression (this
    // in-wasm Euler path does no homotopy continuation).
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::F64Const(1.0f64.into()));
    f.instruction(&I::F64Store(crate::CodegenWasmJitFunctions::mem_arg(layout.lambda_off, 3)));

    // functionParameters; functionInitStartValues; functionInitialEquations.
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::Call(eqfn.parameters));
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::Call(eqfn.init_start_values));
    f.instruction(&I::LocalGet(SIM_DATA));
    f.instruction(&I::Call(eqfn.initial));

    // buf = rt_alloc((n_steps + 1) * n_total * 8)
    f.instruction(&I::LocalGet(N_STEPS));
    f.instruction(&I::I32Const(1));
    f.instruction(&I::I32Add);
    f.instruction(&I::I32Const((n_total * 8) as i32));
    f.instruction(&I::I32Mul);
    f.instruction(&I::Call(rt_index("rt_alloc")?));
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
    write_output(path, &bytes).map_err(|e| "CodegenWasmJit: cannot write {path}: {e}")
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
        for _ in 0..5 {
            funcs.function(1); // param/initial/initStartValues/ODE/algebraics
        }
        funcs.function(2); // om_meta_ptr
        funcs.function(2); // om_meta_len
        m.section(&funcs);

        let mut exports = we::ExportSection::new();
        exports.export("functionParameters", we::ExportKind::Func, 1);
        exports.export("functionInitStartValues", we::ExportKind::Func, 2);
        exports.export("functionInitialEquations", we::ExportKind::Func, 3);
        exports.export("functionODE", we::ExportKind::Func, 4);
        exports.export("functionAlgebraics", we::ExportKind::Func, 5);
        exports.export("om_meta_ptr", we::ExportKind::Func, 6);
        exports.export("om_meta_len", we::ExportKind::Func, 7);
        m.section(&exports);

        let mut code = we::CodeSection::new();
        for _ in 0..5 {
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
