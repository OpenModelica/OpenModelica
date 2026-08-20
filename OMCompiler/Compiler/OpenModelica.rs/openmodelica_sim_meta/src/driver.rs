//! Engine-independent simulation drivers.
//!
//! The two JIT backends (`sim_runtime_wasmtime`, `sim_runtime_wasmer`) differ
//! only in how they compile a module, call an exported function, and read/write
//! linear memory. Everything above that — the forward-Euler and DASSL loops, the
//! in-wasm `simulate` driver, result-row capture, `terminate()` polling, and the
//! post-run parameter read — is identical, so it lives here once, expressed
//! against the object-safe [`SimEngine`] trait. Each backend provides a thin
//! `SimEngine` impl (memory access + function calls) plus its own module
//! compilation and external-"C" import wiring, then hands an engine to [`drive`].

use alloc::boxed::Box;
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;
use core::cell::RefCell;

use crate::omclog;
use crate::{
    JacAInfo, Layout as SimLayout, MetaKind as ResultKind, Neg, REAL_OFF, SimMeta, SolveStats, StateSetInfo,
    TIME_OFF,
    WTy,
};

/// The driver's error type. Was `metamodelica::Result`; the driver is `no_std`
/// (it compiles into the runtime wasm) so it can't depend on the compiler crates.
pub type Result<T> = core::result::Result<T, &'static str>;

/// The driver reads a model purely through its shared metadata blob, so the host
/// (native/wasmer) and in-wasm drivers share one model view.
type SimModel = SimMeta;

/// Persistent pivoting state for one `$STATESET` across integration steps (C's
/// `set->colPivot`/`rowPivot`). `comparePivot` detects a selection change against
/// the previous `col_pivot`.
struct StateSetPivot {
    col_pivot: Vec<usize>,
    row_pivot: Vec<usize>,
}

/// Initialise each state set's pivoting to the identity selection, matching C's
/// `initializeStateSetPivoting` (`colPivot[n] = nCandidates-n-1`) and the
/// wasm-side `A[n,n]=1` seeded in `functionParameters`.
fn init_state_pivots(state_sets: &[StateSetInfo]) -> Vec<StateSetPivot> {
    state_sets
        .iter()
        .map(|s| {
            let nc = s.n_candidates as usize;
            let nd = s.n_dummy as usize;
            StateSetPivot {
                col_pivot: (0..nc).map(|n| nc - n - 1).collect(),
                row_pivot: (0..nd).collect(),
            }
        })
        .collect()
}

/// Full-pivot Gaussian elimination selecting `n_rows` pivot columns of the
/// `n_rows × n_cols` matrix `a` (column-major), reordering `row_ind`/`col_ind` so
/// `a_pivoted[i,j] = a[row_ind[i], col_ind[j]]`. Port of C's `pivot()`
/// (`math-support/pivot.c`). Returns false if the (remaining) matrix is all zero.
fn pivot(a: &mut [f64], n_rows: usize, n_cols: usize, row_ind: &mut [usize], col_ind: &mut [usize]) -> bool {
    const FAC: f64 = 1.125; // how much larger before rows/cols are interchanged
    let at = |a: &[f64], r: usize, c: usize, ri: &[usize], ci: &[usize]| a[ri[r] + n_rows * ci[c]];
    for row in 0..n_rows.min(n_cols) {
        // maxsearch: largest |element| in the trailing submatrix.
        let mut best: Option<(usize, usize)> = None;
        let mut mabs = 0.0f64;
        for r in row..n_rows {
            for c in row..n_cols {
                let t = at(a, r, c, row_ind, col_ind).abs();
                if t > mabs {
                    mabs = t;
                    best = Some((r, c));
                }
            }
        }
        let Some((maxrow, maxcol)) = best else { return false };
        let pv = at(a, row, row, row_ind, col_ind).abs();
        if mabs > FAC * pv {
            row_ind.swap(row, maxrow);
            col_ind.swap(row, maxcol);
        }
        let pv = at(a, row, row, row_ind, col_ind);
        // one step of Gaussian elimination on the pivoted matrix
        for i in (row + 1)..n_rows {
            let leader = at(a, i, row, row_ind, col_ind);
            if leader != 0.0 {
                let scale = -leader / pv;
                a[row_ind[i] + n_rows * col_ind[row]] = 0.0;
                for j in (row + 1)..n_cols {
                    let t2 = at(a, row, j, row_ind, col_ind);
                    a[row_ind[i] + n_rows * col_ind[j]] += scale * t2;
                }
            }
        }
    }
    true
}

/// Select the states for one `$STATESET` at the current point (C's
/// `stateSelectionSet` with `switchStates=1`): evaluate the analytic Jacobian
/// column-by-column via `functionStateSetJacobians`, pivot to choose the dummy
/// columns, and — if the selection changed — rebuild the `A` matrix and reinit
/// the state variables from their candidates (`setAMatrix`). Returns whether the
/// selection changed (the caller restarts the integrator, as a state change is a
/// discontinuity in the state vector).
fn state_selection_set(
    e: &mut dyn SimEngine,
    sim_data: u32,
    info: &StateSetInfo,
    st: &mut StateSetPivot,
    set_index: usize,
    report_error: bool,
) -> Result<bool> {
    let nc = info.n_candidates as usize;
    let nd = info.n_dummy as usize;
    if nd == 0 {
        return Ok(false);
    }

    // getAnalyticalJacobianSet: J (column-major nd x nc). Seed one candidate at a
    // time, run the column equations, read the result rows.
    let mut jac = vec![0.0f64; nd * nc];
    for col in 0..nc {
        for (c, &soff) in info.seed_offs.iter().enumerate() {
            write_f64(e, sim_data + soff, if c == col { 1.0 } else { 0.0 })?;
        }
        e.call1("functionStateSetJacobians", sim_data)?;
        for row in 0..nd {
            jac[row + nd * col] = read_f64(e, sim_data + info.result_offs[row])?;
        }
    }
    // leave seeds cleared
    for &soff in &info.seed_offs {
        write_f64(e, sim_data + soff, 0.0)?;
    }

    if omclog::active(omclog::DSS_JAC) {
        log_state_set_jacobian(omclog::INFO, omclog::DSS_JAC, info, &jac, set_index);
    }

    let old_col = st.col_pivot.clone();
    if !pivot(&mut jac, nd, nc, &mut st.row_pivot, &mut st.col_pivot) && report_error {
        log_state_set_jacobian(omclog::WARNING, omclog::DSS, info, &jac, set_index);
        let t = read_f64(e, sim_data + TIME_OFF)?;
        omclog::error(
            omclog::STDOUT,
            false,
            &format!(
                "Error, singular Jacobian for dynamic state selection at time {t:.6}\nUse -lv LOG_DSS_JAC to get the Jacobian"
            ),
        );
        return Err("CodegenWasmJit: singular Jacobian for dynamic state selection");
    }

    // comparePivot: enable = 1 for the first nd pivot columns (dummy), 2 for the
    // rest (states). A change in which columns are states means a new selection.
    let mut new_enable = vec![0u8; nc];
    let mut old_enable = vec![0u8; nc];
    for i in 0..nc {
        let entry = if i < nd { 1 } else { 2 };
        new_enable[st.col_pivot[i]] = entry;
        old_enable[old_col[i]] = entry;
    }
    let changed = new_enable != old_enable;
    if changed {
        // setAMatrix: zero A, then for each state column set A[row,col]=1 and
        // reinit the state variable to its candidate's current value.
        for &aoff in &info.a_offs {
            write_i32(e, sim_data + aoff, 0)?;
        }
        let mut row = 0usize;
        for col in 0..nc {
            if new_enable[col] == 2 {
                write_i32(e, sim_data + info.a_offs[row * nc + col], 1)?;
                let v = read_f64(e, sim_data + info.candidate_offs[col])?;
                write_f64(e, sim_data + info.state_offs[row], v)?;
                row += 1;
            }
        }
        if omclog::active(omclog::DSS) {
            let t = read_f64(e, sim_data + TIME_OFF)?;
            omclog::info(omclog::DSS, true, &format!("StateSelection Set {set_index} at time = {t:.6}"));
            print_state_selection_info(e, sim_data, info)?;
            omclog::close(omclog::DSS);
        }
    }
    Ok(changed)
}

/// C's `printStateSelectionInfo`.
fn print_state_selection_info(e: &mut dyn SimEngine, sim_data: u32, info: &StateSetInfo) -> Result<()> {
    let nc = info.n_candidates as usize;
    let ns = info.n_states as usize;
    let name = |i: usize| info.candidate_names.get(i).map(String::as_str).unwrap_or("?");
    let plural = if ns == 1 { "" } else { "s" };
    omclog::info(omclog::DSS, false, &format!("Select {ns} state{plural} from {nc} candidates."));
    omclog::info(omclog::DSS, true, "State candidates:");
    for k in 0..nc {
        omclog::info(omclog::DSS, false, &format!("[{}] {}", k + 1, name(k)));
    }
    omclog::close(omclog::DSS);
    omclog::info(omclog::DSS, true, &format!("Selected state{plural}"));
    for row in 0..ns {
        for col in 0..nc {
            if read_i32(e, sim_data + info.a_offs[row * nc + col])? == 1 {
                omclog::info(omclog::DSS, false, &format!("[{}] {}", col + 1, name(col)));
                break;
            }
        }
    }
    omclog::close(omclog::DSS);
    Ok(())
}

/// C's `LOG_DSS_JAC` dump, and the block it warns with before throwing on a
/// singular Jacobian (which adds the candidate names).
fn log_state_set_jacobian(ty: omclog::LogType, stream: omclog::Stream, info: &StateSetInfo, jac: &[f64], set_index: usize) {
    let nc = info.n_candidates as usize;
    let nd = info.n_dummy as usize;
    let mut block = format!("jacobian {nd}x{nc} [id: {set_index}]");
    for row in 0..nd {
        block.push('\n');
        for col in 0..nc {
            block.push_str(&omclog::e(jac[row + nd * col], 0, 5));
            block.push(' ');
        }
    }
    if ty == omclog::WARNING {
        for n in &info.candidate_names {
            block.push('\n');
            block.push_str(n);
        }
        omclog::warning(stream, false, &block);
    } else {
        omclog::info(stream, false, &block);
    }
}

/// Run state selection over every `$STATESET` (C's `stateSelection` with
/// `reportError=1`). Returns whether any set switched its selection.
fn run_state_selection(
    e: &mut dyn SimEngine,
    sim_data: u32,
    state_sets: &[StateSetInfo],
    pivots: &mut [StateSetPivot],
) -> Result<bool> {
    state_selection(e, sim_data, state_sets, pivots, true)
}

/// The selection C runs at the end of `initialization()`: the first pass does not
/// report a singular Jacobian, and only a second switch in a row warns.
fn run_state_selection_initial(
    e: &mut dyn SimEngine,
    sim_data: u32,
    state_sets: &[StateSetInfo],
    pivots: &mut [StateSetPivot],
) -> Result<bool> {
    if !state_selection(e, sim_data, state_sets, pivots, false)? {
        return Ok(false);
    }
    if state_selection(e, sim_data, state_sets, pivots, true)? {
        omclog::warning(
            omclog::STDOUT,
            false,
            "Cannot initialize the dynamic state selection in an unique way. Use -lv LOG_DSS to see the switching state set.",
        );
    }
    Ok(true)
}

fn state_selection(
    e: &mut dyn SimEngine,
    sim_data: u32,
    state_sets: &[StateSetInfo],
    pivots: &mut [StateSetPivot],
    report_error: bool,
) -> Result<bool> {
    let mut changed = false;
    for (i, (info, st)) in state_sets.iter().zip(pivots.iter_mut()).enumerate() {
        changed |= state_selection_set(e, sim_data, info, st, i, report_error)?;
    }
    Ok(changed)
}

/// Every model entry point the drivers below may pass to [`SimEngine::call1`] /
/// [`SimEngine::call1_if_present`], in the table-slot order the in-wasm session
/// uses. The host's table wiring and the runtime's dispatch both derive from this,
/// so they cannot disagree about which functions exist or where they sit.
pub const MODEL_FNS: &[&str] = &[
    "functionParameters",
    "functionInitStartValues",
    "functionInitialEquations",
    "functionODE",
    "functionAlgebraics",
    "functionStateSetJacobians",
    "functionZeroCrossings",
    "initSample",
    "simulate",
    "callExternalObjectDestructors",
    "functionInitialEquations_lambda0",
    "functionUpdateRelations",
    "functionCheckAsserts",
    "functionStoreDelayed",
    "functionInitDelay",
    "functionStoreSpatialDistribution",
    "functionInitSpatialDistribution",
    "functionUpdateBoundParameters",
    "functionUpdateBoundVariableAttributes",
    "evaluateDAEResiduals",
    "functionInitSynchronous",
    "functionUpdateSynchronous",
    "functionEquationsSynchronous",
    "linearJacA",
    "linearJacB",
    "linearJacC",
    "linearJacD",
    "functionRemovedInitialEquations",
    "functionZeroCrossingsEquations",
];

/// The model entry points that are not `fn(SimData*)`: `--daeMode`'s residual
/// takes the evaluation stage as a second argument (C's `currentEvalStage`), and
/// the two synchronous dispatchers take a clock index.
pub const MODEL_FN_DAE: &str = "evaluateDAEResiduals";
pub const MODEL_FN_UPDATE_SYNC: &str = "functionUpdateSynchronous";
pub const MODEL_FN_EQS_SYNC: &str = "functionEquationsSynchronous";

/// C's `EVAL_*` (`dae_mode.c`): which stage of the step an equation belongs to.
/// `evaluateDAEResiduals` runs exactly those whose `evalStages` intersect it.
pub mod eval_stage {
    pub const DYNAMIC: u32 = 1;
    pub const ALGEBRAIC: u32 = 2;
    pub const ZEROCROSS: u32 = 4;
    /// The only stage that runs `when`-bodies.
    pub const DISCRETE: u32 = 8;
}

/// The per-run capabilities a backend must expose: read/write the instance's
/// linear memory and call its exported functions. Object-safe so the drivers can
/// take `&mut dyn SimEngine` (and the DASSL residual callback a `*mut dyn`).
pub trait SimEngine {
    /// Read `buf.len()` bytes of linear memory starting at byte address `addr`.
    fn read_bytes(&self, addr: u32, buf: &mut [u8]) -> Result<()>;
    /// Write `buf` to linear memory starting at byte address `addr`.
    fn write_bytes(&mut self, addr: u32, buf: &[u8]) -> Result<()>;
    /// Call the exported `fn(u32) -> ()` `name` (an equation function). Backends
    /// cache the resolved function; a missing export is an error.
    fn call1(&mut self, name: &str, arg: u32) -> Result<()>;
    /// Like [`call1`] but a no-op if `name` is not exported (optional teardown
    /// hooks such as `callExternalObjectDestructors`).
    fn call1_if_present(&mut self, name: &str, arg: u32) -> Result<()>;
    /// Call the exported `fn(u32, u32) -> ()` `name` — only [`MODEL_FN_DAE`],
    /// whose second argument is the evaluation stage.
    fn call2(&mut self, name: &str, a: u32, b: u32) -> Result<()>;
    /// Call the exported `simulate(sim_data, start, stop, n_steps) -> buf`, the
    /// in-wasm Euler driver; returns the result-buffer pointer.
    fn call_simulate(&mut self, sim_data: u32, start: f64, stop: f64, n_steps: u32) -> Result<u32>;
    /// If the last wasm call trapped on a failed `assert()`, take the recorded
    /// assertion as `[msg, file, sline, scol, eline, ecol, read_only, cond, initial]`
    /// (handles into shared memory), else `None`. Backed by the engine's `rt_assert`
    /// host import; lets [`drive`] report a model assertion instead of a bare trap.
    fn take_pending_assert(&mut self) -> Option<[i32; 9]>;
    /// Take the violations that did not throw, each as `[kind, cond, msg, file,
    /// sline, scol, eline, ecol, read_only, initial]` (`kind` per `ASSERT_*`). Drained
    /// by the drivers to emit C's `LOG_ASSERT` blocks. Default: none.
    fn take_pending_warnings(&mut self) -> Vec<[i32; 10]> {
        Vec::new()
    }
    /// Take the `reinit`s the model executed since the last call, as `(state
    /// SimData offset, value)`, for the event's `LOG_EVENTS` block. Default: none.
    fn take_pending_reinits(&mut self) -> Vec<(u32, f64)> {
        Vec::new()
    }
    /// Linear-system solves the runtime performed in-wasm, which the host driver
    /// never sees. Default: none (backends whose solver runs host-side).
    fn lin_solves(&mut self) -> u64 {
        0
    }
    /// The runtime's `rt_stat` counters, in slot order. Default: none.
    fn rt_stats(&mut self) -> [u64; RT_STATS] {
        [0; RT_STATS]
    }
    /// Address of the runtime's evaluation context, or 0 when the backend has no
    /// such export.
    fn context_addr(&mut self) -> u32 {
        0
    }
    /// Address of the runtime's error stage / absorbed-error pair, or 0 when the
    /// backend has no such export.
    fn error_stage_addr(&mut self) -> u32 {
        0
    }
    /// C's `cleanUpOldValueListAfterEvent`. Default: none (an engine that never
    /// integrates).
    fn clean_nls_history(&mut self, _time: f64) {}
}

/// C's `EVAL_CONTEXT`, mirrored from the runtime's `nls.rs`. `unsetContext` restores
/// to `ALGEBRAIC`, not `UNKNOWN`.
pub const CONTEXT_ODE: i32 = 1;
pub const CONTEXT_ALGEBRAIC: i32 = 2;
pub const CONTEXT_EVENTS: i32 = 3;
pub const CONTEXT_JACOBIAN: i32 = 4;

/// gbode's view of the three `setContext` calls it needs; the driver's own uses go
/// through [`set_context`] directly.
pub(crate) fn set_context_jacobian(e: &mut dyn SimEngine, addr: u32) {
    set_context(e, addr, CONTEXT_JACOBIAN);
}

pub(crate) fn set_context_algebraic(e: &mut dyn SimEngine, addr: u32) {
    set_context(e, addr, CONTEXT_ALGEBRAIC);
}

pub(crate) fn set_context_events(e: &mut dyn SimEngine, addr: u32) {
    set_context(e, addr, CONTEXT_EVENTS);
}

/// C's `setContext`; a no-op when the backend has no context slot.
fn set_context(e: &mut dyn SimEngine, addr: u32, ctx: i32) {
    if addr != 0 {
        let _ = write_i32(e, addr, ctx);
    }
}

/// C's `threadData->currentErrorStage`, mirrored from the runtime's `nls.rs`.
pub const ERROR_SIMULATION: i32 = 0;
pub const ERROR_INTEGRATOR: i32 = 1;

/// Open C's `MMC_TRY_INTERNAL(simulationJumpBuffer)` around an integrator callback: a
/// model error inside it is absorbed rather than trapping, and [`took_error_stage`]
/// reports it. A no-op without the runtime slot, where such an error stays fatal.
fn set_error_stage(e: &mut dyn SimEngine, addr: u32, stage: i32) {
    if addr != 0 {
        let _ = write_i32(e, addr, stage);
        if stage != ERROR_SIMULATION {
            let _ = write_i32(e, addr + 4, 0);
        }
    }
}

/// Close the region [`set_error_stage`] opened: back to `ERROR_SIMULATION`, and
/// whether a model error was absorbed while it was open (C's `success == 0`).
fn took_error_stage(e: &mut dyn SimEngine, addr: u32) -> bool {
    if addr == 0 {
        return false;
    }
    let hit = read_i32(e, addr + 4).unwrap_or(0) != 0;
    let _ = write_i32(e, addr, ERROR_SIMULATION);
    hit
}

/// Must match the runtime's `N_STATS`.
pub const RT_STATS: usize = 25;

pub const RT_STAT_NAMES: [&str; RT_STATS] = [
    "alloc", "array_new", "record_new", "str_new", "nls_solve", "nls_res", "nls_jac", "nls_fail", "nls_retry",
    "elem_ptr", "nls_iter", "nls_newton_fail", "nls_guess_hit", "nls_accept", "nls_store_back",
    "nls_vary_start", "nls_stale", "newton_irregular", "newton_lambda", "newton_negstep",
    "newton_maxiter", "newton_stuck", "newton_jac", "newton_singular", "homotopy_steps",
];

/// Lambda steps the runtime's locally-continued systems took, part of the same
/// `homotopySteps` the driver's own continuation feeds.
pub const RT_STAT_HOMOTOPY_STEPS: usize = 24;

/// Read a runtime String heap value (`[refcount:u32][len:u32][utf8]`, handle at
/// its base; `0` is null) into a Rust `String`.
fn read_rt_string(e: &dyn SimEngine, handle: i32) -> Result<String> {
    if handle <= 0 {
        return Ok(String::new());
    }
    let base = handle as u32;
    let len = read_i32(e, base + 4)?.max(0) as usize;
    let mut buf = vec![0u8; len];
    e.read_bytes(base + 8, &mut buf)?;
    Ok(String::from_utf8_lossy(&buf).into_owned())
}

/// A model `assert()` failure recorded by `rt_assert`, decoded from the runtime's
/// String heap. The host routes it to the compiler error buffer (so OMEdit shows
/// `[file:l:c] Error: <msg>`); the in-wasm driver has no such buffer — the trap
/// already aborts the run.
pub struct AssertInfo {
    pub msg: String,
    pub file: String,
    pub read_only: bool,
    pub line_start: i32,
    pub col_start: i32,
    pub line_end: i32,
    pub col_end: i32,
}

static ASSERT_REPORTER: AtomicUsize = AtomicUsize::new(0);
/// Install a hook the driver calls with a decoded model assertion, so a host can
/// surface it. Unset ⇒ the assertion just aborts the run (still reported as an
/// error via the returned string).
pub fn set_assert_reporter(f: fn(&AssertInfo)) {
    ASSERT_REPORTER.store(f as usize, Ordering::Relaxed);
}

/// A `functionODE`/`functionAlgebraics` trap during integration is usually a
/// failed model `assert()`, whose message + source info `rt_assert` recorded.
/// Decode it, hand it to the reporter hook if any, and return the enriched error;
/// otherwise return the original trap error.
pub fn enrich_trap(e: &mut dyn SimEngine, err: &'static str) -> &'static str {
    enrich_trap_impl(e, err, None)
}

/// The same for a trap out of initialization, where C logs the violation itself
/// (`errorStreamPrint` before the longjmp). `start_time` is the time it reports.
pub fn enrich_trap_init(e: &mut dyn SimEngine, err: &'static str, start_time: f64) -> &'static str {
    enrich_trap_impl(e, err, Some(start_time))
}

/// Set by [`note_runtime_error`]; consumed by the trap it precedes.
static RUNTIME_ERROR: core::sync::atomic::AtomicBool = core::sync::atomic::AtomicBool::new(false);

/// C's `va_throwStreamPrint(NULL, …)`, which an external function's `ModelicaError`
/// reaches: log the message on `LOG_ASSERT` and unwind. It has no condition and no
/// source position, so the trap that follows must not go looking for the assertion
/// block a model `assert()` would have left.
pub fn note_runtime_error(msg: &str) {
    // The whole `vsnprintf` buffer is one message, so a format ending in a
    // newline must not turn into a blank line.
    omclog::message_text(omclog::DEBUG_TYPE, omclog::ASSERT, false, msg.trim_end());
    note_runtime_error_flag();
}

/// Raise the flag alone: an in-wasm runtime has already logged the message and
/// relays only this over `env.rt_host_runtime_error`.
pub fn note_runtime_error_flag() {
    RUNTIME_ERROR.store(true, Ordering::Relaxed);
}

/// Drop one a previous run left behind (only a trap consumes it).
pub fn clear_runtime_error() {
    RUNTIME_ERROR.store(false, Ordering::Relaxed);
}

fn enrich_trap_impl(e: &mut dyn SimEngine, err: &'static str, init_time: Option<f64>) -> &'static str {
    if RUNTIME_ERROR.swap(false, Ordering::Relaxed) {
        if init_time.is_some() {
            omclog::info(omclog::ASSERT, false, "simulation terminated by an assertion at initialization");
        }
        return ASSERT_ERR;
    }
    let Some(pa) = e.take_pending_assert() else { return err };
    let cond = read_rt_string(e, pa[7]).unwrap_or_default();
    let info = AssertInfo {
        msg: read_rt_string(e, pa[0]).unwrap_or_default(),
        file: read_rt_string(e, pa[1]).unwrap_or_default(),
        read_only: pa[6] != 0,
        line_start: pa[2],
        col_start: pa[3],
        line_end: pa[4],
        col_end: pa[5],
    };
    if let Some(t) = init_time {
        log_assert_block(&info, &cond, t, pa[8] != 0);
        omclog::info(omclog::ASSERT, false, "simulation terminated by an assertion at initialization");
    }
    let p = ASSERT_REPORTER.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn(&AssertInfo) = unsafe { core::mem::transmute(p) };
        f(&info);
    }
    ASSERT_ERR
}

/// Result of a simulation run.
pub struct RunResult {
    /// Row-major trajectory: `n_rows * n_reals` f64, each row
    /// `[time, realVars…, intAlg…, boolAlg…]` (integer/boolean algebraics
    /// captured per row, as f64).
    pub rows: Vec<f64>,
    /// Columns per row = `SimLayout::n_row_total()`.
    pub n_reals: u32,
    /// Parameter values (in result `Param` order), read from `SimData` after the run.
    pub params: Vec<f64>,
    /// Solver statistics (steps, evaluations, events).
    pub stats: SolveStats,
    /// `-l`'s linearized model, for the caller to write out.
    pub lin: Option<crate::linearize::LinFile>,
}

/// Outcome of one [`Driver::advance`] chunk.
pub enum Advance {
    /// More rows remain; call again to continue where it left off.
    Running,
    Done,
    /// `terminate()` fired; the rows so far are the result.
    Terminated,
    Cancelled,
}

/// A resumable simulation driver. All cross-row state (DASKR work arrays, `y`/`yp`,
/// pivots, row index) lives in the driver, so an `advance` resumes the exact same
/// continuation — `.mat` output is identical to running the whole loop at once.
pub trait Driver {
    /// Advance until `budget_ms` of wall-clock elapses (checked before each DASKR
    /// call and each output row, so a stuck/stiff interval yields too) or the run
    /// finishes; `+inf` runs to completion. `e` is `'static` because the DASSL
    /// residual callback stashes a raw pointer to it in a thread-local.
    fn advance(&mut self, e: &mut (dyn SimEngine + 'static), model: &SimModel, budget_ms: f64) -> Result<Advance>;
    fn take_rows(&mut self) -> Vec<f64>;
    fn fill_stats(&mut self, model: &SimModel, stats: &mut SolveStats);
    /// The time C's `finishSimulation` emits its terminal row at
    /// (`localData[0]->timeValue`). `None` ⇒ the last emitted row's time, where
    /// every driver that follows the output grid leaves it.
    fn terminal_time(&self) -> Option<f64> {
        None
    }
}

// Wall-clock (ms) for the chunk budget. wasm has no `Instant`, so the host injects
// a `performance.now` clock via `set_clock`; unset reads 0 (any finite deadline
// then fires at once — safe, chatty).
// Wall-clock (ms) for the chunk budget. A host may inject a clock (wasm
// `performance.now`, or the in-wasm runtime's own timer) via `set_clock`; the
// native/std build otherwise falls back to `Instant`. wasm has no usable
// `Instant`, so there the hook is required — unset reads 0, and any finite
// deadline then fires at once (safe but chatty).
use core::sync::atomic::{AtomicUsize, Ordering};
static CLOCK: AtomicUsize = AtomicUsize::new(0);
pub fn set_clock(f: fn() -> f64) {
    CLOCK.store(f as usize, Ordering::Relaxed);
}
/// The driver's wall-clock reading (ms). Public so a host driving the in-wasm
/// session can feed the runtime the *same* clock via `rt_host_now_ms`.
pub fn now_ms_host() -> f64 {
    now_ms()
}

fn now_ms() -> f64 {
    let p = CLOCK.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn() -> f64 = unsafe { core::mem::transmute(p) };
        return f();
    }
    #[cfg(all(feature = "std", not(target_arch = "wasm32")))]
    {
        use std::time::Instant;
        static START: std::sync::OnceLock<Instant> = std::sync::OnceLock::new();
        return START.get_or_init(Instant::now).elapsed().as_secs_f64() * 1000.0;
    }
    #[cfg(not(all(feature = "std", not(target_arch = "wasm32"))))]
    0.0
}

/// Read an env var (host/std only; the in-wasm runtime has no environment, so the
/// bench/self-test knobs default off there).
fn env_var(_name: &str) -> Option<String> {
    #[cfg(feature = "std")]
    {
        std::env::var(_name).ok()
    }
    #[cfg(not(feature = "std"))]
    {
        None
    }
}

/// `+inf` (one-shot) keeps `now_ms` off the hot path via `is_finite` short-circuit.
pub(crate) fn deadline_from(budget_ms: f64) -> f64 {
    if budget_ms.is_finite() { now_ms() + budget_ms } else { f64::INFINITY }
}
pub(crate) fn past_deadline(deadline: f64) -> bool {
    deadline.is_finite() && now_ms() >= deadline
}

/// `-alarm=N` as an absolute `now_ms` deadline (`+inf` = no alarm). C's `SIGALRM`
/// stops the executable wherever it is; the drivers poll this once per step,
/// where they already poll for cancellation. A run wedged *inside* one call into
/// wasm never gets back here — `OMC_WASM_HARD_ALARM` is for that.
mod alarm_store {
    #[cfg(feature = "std")]
    mod imp {
        use core::cell::Cell;
        std::thread_local! {
            static DEADLINE: Cell<f64> = const { Cell::new(f64::INFINITY) };
        }
        pub fn set(v: f64) {
            DEADLINE.with(|d| d.set(v));
        }
        pub fn get() -> f64 {
            DEADLINE.with(|d| d.get())
        }
    }

    #[cfg(not(feature = "std"))]
    mod imp {
        use core::cell::UnsafeCell;
        // The in-wasm runtime is single-threaded, so a plain cell is sound.
        struct Store(UnsafeCell<f64>);
        unsafe impl Sync for Store {}
        static DEADLINE: Store = Store(UnsafeCell::new(f64::INFINITY));
        pub fn set(v: f64) {
            unsafe { *DEADLINE.0.get() = v };
        }
        pub fn get() -> f64 {
            unsafe { *DEADLINE.0.get() }
        }
    }

    pub use imp::{get, set};
}

fn arm_alarm() {
    alarm_store::set(match crate::simflags::with_flags(|f| f.alarm) {
        Some(secs) => now_ms() + secs as f64 * 1000.0,
        None => f64::INFINITY,
    });
}

pub(crate) fn check_alarm() -> Result<()> {
    match past_deadline(alarm_store::get()) {
        true => Err(ALARM_ABORT_ERR),
        false => Ok(()),
    }
}

// Cancellation is a host concern (the native atomic flag, the wasm
// SharedArrayBuffer poll, or the in-wasm session's own cancel flag). The driver
// only polls it, so a host installs a hook; unset means "never cancelled". The
// host re-exports `request_cancel`/`clear_cancel`/`set_cancel_poll` from
// `metamodelica::cancel` and wires `check_cancel` in here.
static CANCEL_HOOK: AtomicUsize = AtomicUsize::new(0);
pub fn set_cancel_hook(f: fn() -> bool) {
    CANCEL_HOOK.store(f as usize, Ordering::Relaxed);
}
pub(crate) fn cancel_requested() -> bool {
    let p = CANCEL_HOOK.load(Ordering::Relaxed);
    if p == 0 {
        return false;
    }
    let f: fn() -> bool = unsafe { core::mem::transmute(p) };
    f()
}

// Fires once when `run_initialization` finishes — the boundary between the
// initialization and simulation output. The host (which owns the stdout capture)
// uses it to keep the model's `print` output ordered: init prints, the
// "initialization finished" line, then the simulation prints.
static INIT_DONE_HOOK: AtomicUsize = AtomicUsize::new(0);
pub fn set_init_done_hook(f: fn()) {
    INIT_DONE_HOOK.store(f as usize, Ordering::Relaxed);
}
// Fires before the external objects are destroyed. C prints "The simulation
// finished successfully." before destroying them, so the host keeps their output
// apart from the simulation's.
static TEARDOWN_HOOK: AtomicUsize = AtomicUsize::new(0);
pub fn set_teardown_hook(f: fn()) {
    TEARDOWN_HOOK.store(f as usize, Ordering::Relaxed);
}
fn signal_teardown() {
    let p = TEARDOWN_HOOK.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn() = unsafe { core::mem::transmute(p) };
        f();
    }
}

/// Public because the in-wasm driver's hook cannot reach the host's capture: it
/// relays the boundary over `env.rt_host_init_done`, which calls this.
pub fn signal_init_done() {
    let p = INIT_DONE_HOOK.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn() = unsafe { core::mem::transmute(p) };
        f();
    }
}

// C's `noThrowAsserts`. The flag lives with the `rt_assert` import — on the host —
// so the in-wasm driver relays it over `env.rt_host_set_no_throw`.
static NO_THROW_HOOK: AtomicUsize = AtomicUsize::new(0);
pub fn set_no_throw_hook(f: fn(bool)) {
    NO_THROW_HOOK.store(f as usize, Ordering::Relaxed);
}
fn set_no_throw(v: bool) {
    let p = NO_THROW_HOOK.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn(bool) = unsafe { core::mem::transmute(p) };
        f(v);
    }
}

// Where the driver's own log lines go. The model's `print` output shares the
// channel, so the two interleave in the order C prints them.
static LOG_SINK: AtomicUsize = AtomicUsize::new(0);
pub fn set_log_sink(f: fn(&str)) {
    LOG_SINK.store(f as usize, Ordering::Relaxed);
}
pub(crate) fn log_line(s: &str) {
    let p = LOG_SINK.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn(&str) = unsafe { core::mem::transmute(p) };
        f(s);
    }
}

// C's `importStartValues`, which `-ipopt_init=file` repeats at every collocation
// point. Opening a result file is the host's job (on the web it has to go through
// the VFS), so the host installs the reader. `out` arrives holding the current
// start values and keeps them for a name the file does not carry, as C's does.
pub type ResultFileReader = fn(&str, &[&str], f64, &mut [f64]) -> core::result::Result<(), String>;
static RESULT_FILE_READER: AtomicUsize = AtomicUsize::new(0);
pub fn set_result_file_reader(f: ResultFileReader) {
    RESULT_FILE_READER.store(f as usize, Ordering::Relaxed);
}
pub(crate) fn read_result_file(
    file: &str,
    names: &[&str],
    t: f64,
    out: &mut [f64],
) -> core::result::Result<(), String> {
    let p = RESULT_FILE_READER.load(Ordering::Relaxed);
    if p == 0 {
        return Err(format!("unable to read input-file <{file}>"));
    }
    let f: ResultFileReader = unsafe { core::mem::transmute(p) };
    f(file, names, t, out)
}

/// [`SimEngine::take_pending_warnings`] kinds.
pub const ASSERT_WARNING: i32 = 0;
pub const ASSERT_SUPPRESSED: i32 = 1;

/// Read one little-endian i32 from linear memory at byte address `addr`.
pub fn read_i32(e: &dyn SimEngine, addr: u32) -> Result<i32> {
    let mut b = [0u8; 4];
    e.read_bytes(addr, &mut b)?;
    Ok(i32::from_le_bytes(b))
}

/// Read one little-endian f64 from linear memory at byte address `addr`.
pub fn read_f64(e: &dyn SimEngine, addr: u32) -> Result<f64> {
    let mut b = [0u8; 8];
    e.read_bytes(addr, &mut b)?;
    Ok(f64::from_le_bytes(b))
}

/// Write one little-endian f64 to linear memory at byte address `addr`.
pub fn write_f64(e: &mut dyn SimEngine, addr: u32, v: f64) -> Result<()> {
    e.write_bytes(addr, &v.to_le_bytes())
}

/// Write one little-endian i32 to linear memory at byte address `addr`.
pub(crate) fn write_i32(e: &mut dyn SimEngine, addr: u32, v: i32) -> Result<()> {
    e.write_bytes(addr, &v.to_le_bytes())
}

/// Error out if a nonlinear system raised the `nls_fail` flag during the last
/// equation call in a context that cannot back off (initialisation, an output
/// point, the Euler loop). The DASSL residual handles this recoverably instead.
pub(crate) fn check_nls(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    let failed = read_i32(e, sim_data + layout.nls_fail_off)?;
    if failed != 0 {
        init_report::set_failed_system(failed - 1);
        report_nls_failure(e, sim_data, layout);
        return Err("CodegenWasmJit: nonlinear system did not converge");
    }
    Ok(())
}

/// C's `equationNonlinear` (`CodegenC.tpl`) after a non-converged
/// `solve_nonlinear_system`. The flag carries `equationIndex + 1`; C's `longjmp` is
/// the caller's `Err` (or, in an integrator residual, `IRES = -1`).
fn report_nls_failure(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) {
    report_nls_failure_at(e, sim_data, layout.nls_fail_off);
}

fn report_nls_failure_at(e: &dyn SimEngine, sim_data: u32, nls_fail_off: u32) {
    let failed = read_i32(e, sim_data + nls_fail_off).unwrap_or(0);
    if failed == 0 {
        return;
    }
    let time = read_f64(e, sim_data + TIME_OFF).unwrap_or(0.0);
    omclog::message_text(
        omclog::DEBUG_TYPE,
        omclog::ASSERT,
        false,
        &format!(
            "Solving non-linear system {} failed at time={}.\nFor more information please use -lv LOG_NLS.",
            failed - 1,
            format_g15(time),
        ),
    );
}

/// Number of equidistant homotopy steps: C's `init_lambda_steps`, which `-ils`
/// overrides.
const HOMOTOPY_STEPS: i32 = 3;

/// C clamps a negative `-ils` to 0, which turns the continuation off entirely.
fn homotopy_steps() -> i32 {
    crate::simflags::with_flags(|f| f.init_lambda_steps).unwrap_or(HOMOTOPY_STEPS).max(0)
}

// Parameter / start `-override`s for the next run, resolved to `(SimData offset,
// type, value)`. Params are applied right after `functionParameters` (so
// `-override=h0=2` also flows into a start value bound to that parameter, e.g.
// `h(start=h0)`); starts after `functionInitStartValues` (so they replace the
// computed start). Set per run by the host before `drive`.
mod overrides_store {
    use super::WTy;
    use alloc::vec::Vec;

    #[cfg(feature = "std")]
    mod imp {
        use super::WTy;
        use alloc::vec::Vec;
        use core::cell::RefCell;
        std::thread_local! {
            static PARAM: RefCell<Vec<(u32, WTy, f64)>> = const { RefCell::new(Vec::new()) };
            static START: RefCell<Vec<(u32, WTy, f64)>> = const { RefCell::new(Vec::new()) };
        }
        pub fn set(p: Vec<(u32, WTy, f64)>, s: Vec<(u32, WTy, f64)>) {
            PARAM.with(|o| *o.borrow_mut() = p);
            START.with(|o| *o.borrow_mut() = s);
        }
        pub fn params() -> Vec<(u32, WTy, f64)> {
            PARAM.with(|o| o.borrow().clone())
        }
        pub fn starts() -> Vec<(u32, WTy, f64)> {
            START.with(|o| o.borrow().clone())
        }
    }

    #[cfg(not(feature = "std"))]
    mod imp {
        use super::WTy;
        use alloc::vec::Vec;
        use core::cell::UnsafeCell;
        // The in-wasm runtime is single-threaded, so a plain cell is sound.
        struct Store(UnsafeCell<(Vec<(u32, WTy, f64)>, Vec<(u32, WTy, f64)>)>);
        unsafe impl Sync for Store {}
        static STORE: Store = Store(UnsafeCell::new((Vec::new(), Vec::new())));
        pub fn set(p: Vec<(u32, WTy, f64)>, s: Vec<(u32, WTy, f64)>) {
            unsafe { *STORE.0.get() = (p, s) };
        }
        pub fn params() -> Vec<(u32, WTy, f64)> {
            unsafe { (*STORE.0.get()).0.clone() }
        }
        pub fn starts() -> Vec<(u32, WTy, f64)> {
            unsafe { (*STORE.0.get()).1.clone() }
        }
    }

    pub use imp::{params, set, starts};
}

/// Set the parameter/start overrides applied by the next [`run_initialization`].
pub fn set_param_overrides(params: Vec<(u32, WTy, f64)>, starts: Vec<(u32, WTy, f64)>) {
    overrides_store::set(params, starts);
}

/// The overrides last set, as `(params, starts)`. A host driving the in-wasm
/// session must forward these into it: the runtime module has its own copy of this
/// store, which `set_param_overrides` on the host side does not reach.
pub fn param_overrides() -> (Vec<(u32, WTy, f64)>, Vec<(u32, WTy, f64)>) {
    (overrides_store::params(), overrides_store::starts())
}

fn apply_overrides(e: &mut dyn SimEngine, sim_data: u32, overrides: &[(u32, WTy, f64)]) -> Result<()> {
    for &(off, wty, val) in overrides {
        match wty {
            WTy::F64 => write_f64(e, sim_data + off, val)?,
            WTy::I32 => write_i32(e, sim_data + off, val as i32)?,
        }
    }
    Ok(())
}

fn apply_param_overrides(e: &mut dyn SimEngine, sim_data: u32) -> Result<()> {
    apply_overrides(e, sim_data, &overrides_store::params())
}

/// What `-iif` found, by index into the concatenated [`SimMeta::import_roster`]. The
/// host resolves the file; [`import_start_values`] applies and logs it.
#[derive(Clone, Debug, Default, PartialEq)]
pub struct StartImports {
    pub file: String,
    pub time: f64,
    pub values: Vec<(u32, f64)>,
}

mod imports_store {
    use super::StartImports;

    #[cfg(feature = "std")]
    mod imp {
        use super::StartImports;
        use core::cell::RefCell;
        std::thread_local! {
            static IMPORTS: RefCell<Option<StartImports>> = const { RefCell::new(None) };
        }
        pub fn set(i: Option<StartImports>) {
            IMPORTS.with(|o| *o.borrow_mut() = i);
        }
        pub fn get() -> Option<StartImports> {
            IMPORTS.with(|o| o.borrow().clone())
        }
    }

    #[cfg(not(feature = "std"))]
    mod imp {
        use super::StartImports;
        use core::cell::UnsafeCell;
        // Single-threaded in-wasm runtime, as `overrides_store`.
        struct Store(UnsafeCell<Option<StartImports>>);
        unsafe impl Sync for Store {}
        static STORE: Store = Store(UnsafeCell::new(None));
        pub fn set(i: Option<StartImports>) {
            unsafe { *STORE.0.get() = i };
        }
        pub fn get() -> Option<StartImports> {
            unsafe { (*STORE.0.get()).clone() }
        }
    }

    pub use imp::{get, set};
}

/// Install the `-iif` values the next [`run_initialization`] imports. As with
/// [`set_param_overrides`], a host driving the in-wasm session must forward them in.
pub fn set_start_imports(imports: Option<StartImports>) {
    imports_store::set(imports);
}

/// The imports last set, for that forwarding.
pub fn start_imports() -> Option<StartImports> {
    imports_store::get()
}

/// C's `isQuantityOverridden`: the file must not clobber an explicit `-override`
/// (ticket #15807).
fn overridden_on_command_line(name: &str) -> bool {
    crate::simflags::with_flags(|f| f.overrides.iter().any(|(o, _)| o == name))
}

/// C's `importStartValues` (`initialization.c`): the `start` of every quantity the
/// `-iif` file names. Runs where C's does — after the bound parameters and
/// attributes, before `setAllVarsToStart` publishes the starts — so a start bound to
/// a parameter is overwritten rather than the other way round.
fn import_start_values(e: &mut dyn SimEngine, sim_data: u32, model: &SimMeta) -> Result<()> {
    let Some(imports) = imports_store::get() else { return Ok(()) };
    omclog::info(
        omclog::INIT,
        false,
        &format!("import start values\nfile: {}\ntime: {}", imports.file, format_g(imports.time, 6)),
    );
    // `values` is in roster order, so one cursor walks both.
    let mut next = 0usize;
    let mut flat = 0u32;
    for (group, entries) in crate::IMPORT_GROUP.iter().zip(model.import_roster()) {
        omclog::info(omclog::INIT, false, &format!("import {group}"));
        // C's headers are plural, its per-quantity lines singular.
        let one = group.trim_end_matches('s');
        for (name, off, wty) in entries {
            let found = imports.values.get(next).filter(|(i, _)| *i == flat).map(|&(_, v)| v);
            if found.is_some() {
                next += 1;
            }
            flat += 1;
            if overridden_on_command_line(name) {
                omclog::info(
                    omclog::INIT_V,
                    false,
                    &format!("| skip import of {one} {name}: overridden on command line"),
                );
                continue;
            }
            let Some(v) = found else {
                // C reports a missing quantity, except for the backend's own variables.
                if !(group.ends_with("variables") && is_generated(name)) {
                    omclog::warning(
                        omclog::INIT,
                        false,
                        &format!("unable to import {one} {name} from given file"),
                    );
                }
                continue;
            };
            match wty {
                WTy::F64 => {
                    write_f64(e, sim_data + off, v)?;
                    omclog::info(omclog::INIT_V, false, &format!("| {name}(start={})", format_g(v, 6)));
                }
                WTy::I32 if group.starts_with("boolean") => {
                    write_i32(e, sim_data + off, (v != 0.0) as i32)?;
                    let b = if v != 0.0 { "true" } else { "false" };
                    omclog::info(omclog::INIT_V, false, &format!("| {name}(start={b})"));
                }
                WTy::I32 => {
                    write_i32(e, sim_data + off, v as i32)?;
                    omclog::info(omclog::INIT_V, false, &format!("| {name}(start={})", v as i32));
                }
            }
        }
    }
    Ok(())
}

/// C's warning filter in `importStartValues`: a name the backend made up.
fn is_generated(name: &str) -> bool {
    name.is_empty() || name.starts_with('$') || name.starts_with("der($")
}

/// What `-iif` imported, as `(roster group, slot, value)`.
fn imported_slots(model: &SimMeta) -> Vec<(usize, u32, f64)> {
    let Some(imports) = imports_store::get() else { return Vec::new() };
    let mut out = Vec::new();
    let mut next = 0usize;
    let mut flat = 0u32;
    for (g, entries) in model.import_roster().iter().enumerate() {
        for &(_, off, _) in entries {
            if let Some(&(_, v)) = imports.values.get(next).filter(|(i, _)| *i == flat) {
                out.push((g, off, v));
                next += 1;
            }
            flat += 1;
        }
    }
    out
}

/// Imported discrete `start`s, which `setAllVarsToStart` publishes over the
/// constants the metadata carries.
fn imported_discrete_starts(model: &SimMeta) -> Vec<(u32, i32)> {
    imported_slots(model)
        .into_iter()
        .filter(|(g, _, _)| *g == 1 || *g == 2)
        .map(|(g, off, v)| (off, if g == 2 { (v != 0.0) as i32 } else { v as i32 }))
        .collect()
}

/// The imported `start`s of the parameters, which C's `printParameters` reports.
fn imported_param_starts(model: &SimMeta) -> Vec<(u32, f64)> {
    imported_slots(model)
        .into_iter()
        .filter(|(g, _, _)| *g >= 3)
        .map(|(g, off, v)| (off, if g == 5 { (v != 0.0) as i32 as f64 } else { v }))
        .collect()
}

fn apply_start_overrides(e: &mut dyn SimEngine, sim_data: u32) -> Result<()> {
    apply_overrides(e, sim_data, &overrides_store::starts())
}

/// Returned to abort a run on detected chattering (`-abortSlowSimulation`).
pub const CHATTER_ABORT_ERR: &str = "CodegenWasmJit: aborting simulation due to chattering";
/// Returned when the `-alarm` deadline expires.
pub const ALARM_ABORT_ERR: &str = "CodegenWasmJit: simulation aborted (-alarm)";
/// What [`enrich_trap`] returns for a trap that was a failed model `assert()`.
pub const ASSERT_ERR: &str = "assertion failed";
/// C's `initialization()` returning nonzero: the reason is already logged.
pub const INIT_FAILED_ERR: &str = "initialization failed";

/// `-abortSlowSimulation` flag + the driver's chattering log lines, set on the host
/// before a run (the driver can only return a `&'static str`).
mod chatter_store {
    #[cfg(feature = "std")]
    mod imp {
        use core::cell::Cell;
        std::thread_local! {
            static ABORT: Cell<bool> = const { Cell::new(false) };
        }
        pub fn set_abort(v: bool) {
            ABORT.with(|a| a.set(v));
        }
        pub fn abort() -> bool {
            ABORT.with(|a| a.get())
        }
    }

    #[cfg(not(feature = "std"))]
    mod imp {
        use core::cell::UnsafeCell;
        // The in-wasm runtime is single-threaded, so a plain cell is sound.
        struct Store(UnsafeCell<bool>);
        unsafe impl Sync for Store {}
        static ABORT: Store = Store(UnsafeCell::new(false));
        pub fn set_abort(v: bool) {
            unsafe { *ABORT.0.get() = v };
        }
        pub fn abort() -> bool {
            unsafe { *ABORT.0.get() }
        }
    }

    pub use imp::{abort, set_abort};
}

/// Homotopy-step count of the last initialization, so the host can print C's
/// "finished successfully with N homotopy steps" / "without homotopy method"
/// (the driver only returns a `&'static str`). 0 = no homotopy was used.
mod init_report {
    use core::sync::atomic::{AtomicBool, AtomicU32, Ordering};
    static HOMOTOPY_STEPS: AtomicU32 = AtomicU32::new(0);
    static LOCAL: AtomicBool = AtomicBool::new(false);
    /// The homotopy step a failed initialization gave up at, and the system that
    /// did not converge there, both biased by one.
    static FAILED_STEP: AtomicU32 = AtomicU32::new(0);
    static FAILED_SYSTEM: AtomicU32 = AtomicU32::new(0);
    pub fn reset() {
        HOMOTOPY_STEPS.store(0, Ordering::Relaxed);
        LOCAL.store(false, Ordering::Relaxed);
        FAILED_STEP.store(0, Ordering::Relaxed);
        FAILED_SYSTEM.store(0, Ordering::Relaxed);
    }
    pub fn set_failed_system(k: i32) {
        FAILED_SYSTEM.store(k as u32 + 1, Ordering::Relaxed);
    }
    pub fn failed_system() -> Option<u32> {
        FAILED_SYSTEM.load(Ordering::Relaxed).checked_sub(1)
    }
    /// C's `homotopySteps +=`, fed by the driver and every local sweep alike.
    pub fn add_homotopy_steps(n: u32) {
        HOMOTOPY_STEPS.fetch_add(n, Ordering::Relaxed);
    }
    pub fn homotopy_steps() -> u32 {
        HOMOTOPY_STEPS.load(Ordering::Relaxed)
    }
    /// C's `usedLocal`.
    pub fn set_local(local: bool) {
        LOCAL.store(local, Ordering::Relaxed);
    }
    pub fn local() -> bool {
        LOCAL.load(Ordering::Relaxed)
    }
    pub fn set_failed_step(step: i32) {
        FAILED_STEP.store(step as u32 + 1, Ordering::Relaxed);
    }
    pub fn failed_step() -> Option<u32> {
        FAILED_STEP.load(Ordering::Relaxed).checked_sub(1)
    }
}

/// Homotopy steps the last `run_initialization` used (0 = none); the host reads it
/// to format the initialization success message like the C runtime.
pub fn init_homotopy_steps() -> u32 {
    init_report::homotopy_steps()
}

/// Whether those steps were a *local* approach's, which C names in the same line.
pub fn init_homotopy_local() -> bool {
    init_report::local()
}

/// `lambda` of the homotopy step the last initialization failed at, for the host
/// to name in the error the driver could only return as a `&'static str`.
pub fn init_failed_lambda() -> Option<f64> {
    init_report::failed_step().map(|s| s as f64 / homotopy_steps() as f64)
}

/// Index of the nonlinear system the last failed solve gave up on.
pub fn failed_nls_system() -> Option<u32> {
    init_report::failed_system()
}

/// The per-site keys already reported, so a warning-level violation warns only
/// once (C's static `warningTriggered`). Cleared at run start.
mod assert_warn_store {
    #[cfg(feature = "std")]
    mod imp {
        use alloc::string::String;
        use alloc::vec::Vec;
        use core::cell::RefCell;
        std::thread_local! {
            static SEEN: RefCell<Vec<String>> = const { RefCell::new(Vec::new()) };
        }
        pub fn reset() {
            SEEN.with(|s| s.borrow_mut().clear());
        }
        pub fn first_time(key: String) -> bool {
            SEEN.with(|s| {
                let mut s = s.borrow_mut();
                if s.iter().any(|k| *k == key) {
                    return false;
                }
                s.push(key);
                true
            })
        }
    }
    #[cfg(not(feature = "std"))]
    mod imp {
        use alloc::string::String;
        use alloc::vec::Vec;
        use core::cell::UnsafeCell;
        struct Store(UnsafeCell<Vec<String>>);
        unsafe impl Sync for Store {}
        static SEEN: Store = Store(UnsafeCell::new(Vec::new()));
        pub fn reset() {
            unsafe { (*SEEN.0.get()).clear() };
        }
        pub fn first_time(key: String) -> bool {
            unsafe {
                let seen = &mut *SEEN.0.get();
                if seen.iter().any(|k| *k == key) {
                    return false;
                }
                seen.push(key);
                true
            }
        }
    }
    pub use imp::{first_time, reset};
}

/// Reported-once latch for the fired `terminate(...)`.
mod term_report {
    #[cfg(feature = "std")]
    mod imp {
        use core::cell::Cell;
        std::thread_local! {
            static DONE: Cell<bool> = const { Cell::new(false) };
        }
        pub fn reset() {
            DONE.with(|d| d.set(false));
        }
        pub fn mark() -> bool {
            DONE.with(|d| !d.replace(true))
        }
    }
    #[cfg(not(feature = "std"))]
    mod imp {
        use core::cell::UnsafeCell;
        struct Store(UnsafeCell<bool>);
        unsafe impl Sync for Store {}
        static DONE: Store = Store(UnsafeCell::new(false));
        pub fn reset() {
            unsafe { *DONE.0.get() = false };
        }
        pub fn mark() -> bool {
            unsafe { !core::mem::replace(&mut *DONE.0.get(), true) }
        }
    }
    pub use imp::{mark, reset};
}

/// Whether `-steadyState` was ever satisfied, for the warning C prints when the run
/// reaches `stopTime` without it. Same shape as [`term_report`].
mod steady_report {
    #[cfg(feature = "std")]
    mod imp {
        use core::cell::Cell;
        std::thread_local! {
            static HIT: Cell<bool> = const { Cell::new(false) };
        }
        pub fn reset() {
            HIT.with(|d| d.set(false));
        }
        pub fn mark() {
            HIT.with(|d| d.set(true));
        }
        pub fn hit() -> bool {
            HIT.with(|d| d.get())
        }
    }
    #[cfg(not(feature = "std"))]
    mod imp {
        use core::cell::UnsafeCell;
        struct Store(UnsafeCell<bool>);
        unsafe impl Sync for Store {}
        static HIT: Store = Store(UnsafeCell::new(false));
        pub fn reset() {
            unsafe { *HIT.0.get() = false };
        }
        pub fn mark() {
            unsafe { *HIT.0.get() = true };
        }
        pub fn hit() -> bool {
            unsafe { *HIT.0.get() }
        }
    }
    pub use imp::{hit, mark, reset};
}

/// Format `%f`-style (C's `%f`: 6 fractional digits), for the assertion time value.
pub(crate) fn format_f(v: f64) -> String {
    format!("{v:.6}")
}

fn format_g15(v: f64) -> String {
    format_g(v, 15)
}

/// C's `%.<p>g`: `p` significant digits, `%e` outside `[1e-4, 10^p)`, trailing
/// zeros and a bare decimal point trimmed.
pub fn format_g(v: f64, p: i32) -> String {
    if !v.is_finite() || v == 0.0 {
        return format!("{v}");
    }
    let exp = libm::floor(libm::log10(libm::fabs(v))) as i32;
    let trim = |s: String| -> String {
        if !s.contains('.') {
            return s;
        }
        s.trim_end_matches('0').trim_end_matches('.').to_string()
    };
    if exp < -4 || exp >= p {
        let m = trim(format!("{:.*}", (p - 1) as usize, v / libm::pow(10.0, exp as f64)));
        return format!("{m}e{}{:02}", if exp < 0 { '-' } else { '+' }, exp.abs());
    }
    trim(format!("{:.*}", (p - 1 - exp).max(0) as usize, v))
}

/// C's `%e`: six decimals on the mantissa, a two-digit exponent.
pub fn format_e(v: f64) -> String {
    if !v.is_finite() {
        return format!("{v}");
    }
    let exp = if v == 0.0 { 0 } else { libm::floor(libm::log10(libm::fabs(v))) as i32 };
    let m = v / libm::pow(10.0, exp as f64);
    format!("{m:.6}e{}{:02}", if exp < 0 { '-' } else { '+' }, exp.abs())
}

/// Evaluate `functionCheckAsserts` (C's `checkForAsserts`) at the current point and
/// format any `AssertionLevel.warning` violation it recorded into a `LOG_ASSERT`
/// block, once per site. Called by the drivers after each accepted solver step.
///
/// `level`: C reports a violation met while the integrator updates the system
/// (`simulationUpdate`, which sets `noThrowAsserts`) as `info`, one met anywhere
/// else — initialization, the terminal step — as `warning`.
fn check_asserts(e: &mut dyn SimEngine, sim_data: u32, _layout: &SimLayout, level: omclog::LogType) -> Result<()> {
    e.call1_if_present("functionCheckAsserts", sim_data)?;
    drain_asserts(e, sim_data, level)?;
    Ok(())
}

/// Log the violations recorded since the last call. A warning goes once per site;
/// a suppressed error goes every time (as in C) and arms the re-throw, which the
/// `true` return reports.
fn drain_asserts(e: &mut dyn SimEngine, sim_data: u32, level: omclog::LogType) -> Result<bool> {
    let pending = e.take_pending_warnings();
    if pending.is_empty() {
        return Ok(false);
    }
    let mut armed = false;
    let time = read_f64(e, sim_data + TIME_OFF)?;
    for w in pending {
        let suppressed = w[0] == ASSERT_SUPPRESSED;
        let cond = read_rt_string(e, w[1])?;
        let msg = read_rt_string(e, w[2])?;
        let file = read_rt_string(e, w[3])?;
        let (sl, sc, el, ec, ro) = (w[4], w[5], w[6], w[7], w[8] != 0);
        let info = AssertInfo {
            msg,
            file,
            read_only: ro,
            line_start: sl,
            col_start: sc,
            line_end: el,
            col_end: ec,
        };
        let line = assert_block(&info, &cond, time, w[9] != 0);
        let ty = if suppressed { omclog::INFO } else { level };
        if suppressed {
            omclog::message_text(ty, omclog::ASSERT, false, &line);
            rethrow_store::arm(info);
            armed = true;
        } else {
            let key = format!("{}:{sl}:{sc}-{el}:{ec}|{cond}", info.file);
            if assert_warn_store::first_time(key) {
                omclog::message_text(ty, omclog::ASSERT, false, &line);
            }
        }
    }
    Ok(armed)
}

/// [`check_asserts`] for the in-wasm Euler loop (`rt_row_asserts`), which calls
/// `functionCheckAsserts` itself and needs only the formatting. `warn` picks the
/// level as [`emit_row`] does. Nonzero means a suppressed `assert()` ends the run,
/// which [`run_wasm`] settles once the loop is out.
pub fn row_asserts(e: &mut dyn SimEngine, sim_data: u32, warn: i32) -> i32 {
    let level = if warn != 0 { omclog::WARNING } else { omclog::INFO };
    drain_asserts(e, sim_data, level).unwrap_or(true) as i32
}

/// C's `LOG_ASSERT` block (`omc_error.c` messageText + printInfo). C wraps the
/// already-parenthesised `assert_cond` in its own `(%s)`, hence the doubled
/// parentheses; without a source position only the message is printed.
fn assert_block(info: &AssertInfo, cond: &str, time: f64, initial: bool) -> String {
    let during = if initial { "during initialization " } else { "" };
    let t = format_f(time);
    let head = format!("The following assertion has been violated {during}at time {t}");
    let ro_str = if info.read_only { "readonly" } else { "writable" };
    let pos = format!(
        "[{}:{}:{}-{}:{}:{ro_str}]",
        info.file, info.line_start, info.col_start, info.line_end, info.col_end,
    );
    // An equation `assert()` always names its condition, and C prints it with the
    // message as one message's second line — including for a backend-generated
    // variable, whose `FILE_INFO` is empty (`$finalCon$…`'s min/max guard). Without
    // a condition it is C's `FUNCTION_CONTEXT` `omc_assert` (position and message
    // only) or `assertCommonVar` (the math-domain guards, neither).
    if cond.is_empty() {
        return if info.file.is_empty() { head } else { format!("{pos}\n{}", info.msg) };
    }
    let body = format!("(({cond})) --> \"{}\"", info.msg);
    if info.file.is_empty() {
        return format!("{head}\n{body}");
    }
    format!("{pos}\n{head}\n{body}")
}

fn log_assert_block(info: &AssertInfo, cond: &str, time: f64, initial: bool) {
    let block = assert_block(info, cond, time, initial);
    // C's `assertCommonVar` (the math-domain guards, no condition and no source
    // position): the warning names the time, a debug line carries the message.
    if cond.is_empty() && info.file.is_empty() {
        omclog::warning(omclog::ASSERT, false, &block);
        omclog::message_text(omclog::DEBUG_TYPE, omclog::ASSERT, false, &info.msg);
        return;
    }
    // C's generated guard for a backend variable warns (`omc_assert_warning`); one
    // with a source position is a model `assert()`, which is an error.
    if info.file.is_empty() {
        omclog::warning(omclog::ASSERT, false, &block);
        return;
    }
    omclog::error(omclog::ASSERT, false, &block);
}

/// What the open window has seen: the first assertion suppressed in it, and
/// whether an event was handled — which is what decides its fate.
mod rethrow_store {
    use super::AssertInfo;
    #[cfg(feature = "std")]
    mod imp {
        use super::AssertInfo;
        use core::cell::{Cell, RefCell};
        std::thread_local! {
            static PENDING: RefCell<Option<AssertInfo>> = const { RefCell::new(None) };
            static EVENT: Cell<bool> = const { Cell::new(false) };
        }
        pub fn arm(info: AssertInfo) {
            PENDING.with(|p| {
                let mut p = p.borrow_mut();
                if p.is_none() {
                    *p = Some(info);
                }
            });
        }
        pub fn note_event() {
            EVENT.with(|ev| ev.set(true));
        }
        pub fn take() -> (Option<AssertInfo>, bool) {
            (PENDING.with(|p| p.borrow_mut().take()), EVENT.with(|ev| ev.replace(false)))
        }
    }
    #[cfg(not(feature = "std"))]
    mod imp {
        use super::AssertInfo;
        use core::cell::UnsafeCell;
        struct Store(UnsafeCell<(Option<AssertInfo>, bool)>);
        unsafe impl Sync for Store {}
        static PENDING: Store = Store(UnsafeCell::new((None, false)));
        pub fn arm(info: AssertInfo) {
            unsafe {
                let st = &mut *PENDING.0.get();
                if st.0.is_none() {
                    st.0 = Some(info);
                }
            }
        }
        pub fn note_event() {
            unsafe { (*PENDING.0.get()).1 = true };
        }
        pub fn take() -> (Option<AssertInfo>, bool) {
            unsafe {
                let st = &mut *PENDING.0.get();
                (st.0.take(), core::mem::replace(&mut st.1, false))
            }
        }
    }
    pub use imp::{arm, note_event, take};
}

/// Enter C's `noThrowAsserts` phase: a failed `assert()` is recorded, not thrown.
/// Idempotent, so a chunk that yields mid-step just re-enters it.
fn open_assert_window() {
    set_no_throw(true);
}

/// Leave it and settle what was recorded (C's `simulationUpdate` tail): an event
/// makes the point they were raised at obsolete, otherwise the run fails now.
fn close_assert_window(e: &mut dyn SimEngine, sim_data: u32) -> Result<()> {
    set_no_throw(false);
    drain_asserts(e, sim_data, omclog::INFO)?;
    let (info, found_event) = rethrow_store::take();
    let Some(info) = info else {
        return Ok(());
    };
    if found_event {
        omclog::info(omclog::ASSERT, false, "Found event, previous asserts are ignored.");
        return Ok(());
    }
    omclog::error(omclog::ASSERT, false, "No event found, but assert was triggered. Throwing now!");
    let p = ASSERT_REPORTER.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn(&AssertInfo) = unsafe { core::mem::transmute(p) };
        f(&info);
    }
    Err(ASSERT_ERR)
}

/// Arm `-abortSlowSimulation` for the next run.
pub fn set_abort_slow(v: bool) {
    chatter_store::set_abort(v);
}

/// Solve the initial system: `functionParameters`, then `functionInitialEquations`
/// with the relations fresh (init mode) — directly, or through the global
/// equidistant homotopy continuation (C's `solveWithGlobalHomotopy`), see
/// `run_initialization_impl`. Leaves lambda = 1, then seeds `relationsPre` for the
/// continuous phase's held relations.
pub fn run_initialization(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    inputs: &[crate::InputVar],
    start_time: f64,
) -> Result<()> {
    init_model(e, sim_data, layout, inputs, start_time, None)?;
    signal_init_done();
    terminate_at_init(e, sim_data, layout)
}

/// [`run_initialization`] where the caller has the metadata the `LOG_SOTI` dump
/// and the discrete start attributes need.
pub fn run_initialization_model(e: &mut dyn SimEngine, sim_data: u32, model: &SimMeta) -> Result<()> {
    init_model(e, sim_data, &model.layout, &model.inputs, model.start_time, Some(model))?;
    signal_init_done();
    terminate_at_init(e, sim_data, &model.layout)
}

/// C asks after `initializeModel` reported success and before the main loop: a
/// `terminate()` from an initial equation ends the run at `startTime`. The drivers
/// see the same flag after the first output row and stop there.
fn terminate_at_init(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if read_i32(e, sim_data + layout.terminate_off)? != 0 {
        report_terminate(e, sim_data, layout, true)?;
    }
    Ok(())
}

/// [`run_initialization`] plus C's `initSynchronous`, which `initializeModel` runs
/// before it reports success — so the clock dump lands in the log's init segment.
pub fn run_initialization_with_clocks(
    e: &mut dyn SimEngine,
    sim_data: u32,
    model: &SimMeta,
) -> Result<crate::sync::Sync> {
    init_model(e, sim_data, &model.layout, &model.inputs, model.start_time, Some(model))?;
    let mut sync = crate::sync::Sync::new(e, model, sim_data)?;
    // An event clock whose `when` already fired during the initial discrete update
    // is only *scheduled* here (C's `data->simulationInfo->initial` case).
    sync.take_fired(e, model.start_time)?;
    log_event_status(e, sim_data, model, omclog::EVENTS)?;
    signal_init_done();
    terminate_at_init(e, sim_data, &model.layout)?;
    Ok(sync)
}

fn init_model(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    inputs: &[crate::InputVar],
    start_time: f64,
    model: Option<&SimMeta>,
) -> Result<()> {
    // C's `initializeNonlinearSystems`, which reports its dropped patterns here.
    if let Some(m) = model {
        for w in &m.nls_warnings {
            omclog::warning(omclog::STDOUT, false, w);
        }
    }
    // `functionInitDelay` reads `startTime` from `TIME_OFF`; init the buffers
    // before any equation function (`rt_delay_eval` traps on unallocated ones).
    write_f64(e, sim_data + TIME_OFF, start_time)?;
    e.call1_if_present("functionInitDelay", sim_data)?;
    run_initialization_impl(e, sim_data, layout, inputs, model)?;
    if let Some(m) = model {
        dump_initial_solution(e, sim_data, m);
    }
    omclog::info(omclog::INIT, false, "### END INITIALIZATION ###");
    // C's `storePreValues` after the initial solve (initialization.c:903).
    seed_pre_from_live(e, sim_data, layout)?;
    save_old_real(e, sim_data, layout)?;
    // Seed the continuous phase's held relations from a full discrete fixed point.
    // The initial system does not necessarily touch every relation guarding the
    // continuous equations, so a straight snapshot of `relations[]` here would
    // freeze those at their stale (zero) value and pick the wrong equation branch.
    // `refresh_relations` first, as C's `updateDiscreteSystem` does: a relation
    // sitting in a branch no evaluation takes (`if a then .. else if b then ..`,
    // entered on the `a` side) is reached by nothing but the exact sweep.
    refresh_relations(e, sim_data, layout)?;
    iterate_discrete(e, sim_data, layout)?;
    store_relations(e, sim_data, layout)?;
    update_relations_pre(e, sim_data, layout)?;
    // Seed the delay buffers / transported profiles and snapshot `zeroCrossingsPre`
    // for step 1.
    store_operators(e, sim_data, layout)?;
    if layout.n_zc > 0 {
        write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
        save_zc_pre(e, sim_data, layout)?;
        e.call1("functionZeroCrossings", sim_data)?;
    }
    write_i32(e, sim_data + layout.initial_off, 0)?;
    // C's `initializeModel` ends with `checkForAsserts` — before the
    // initialization-success line.
    check_asserts(e, sim_data, layout, omclog::WARNING)?;
    Ok(())
}

fn run_initialization_impl(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    inputs: &[crate::InputVar],
    model: Option<&SimMeta>,
) -> Result<()> {
    omclog::info(omclog::INIT, false, "### START INITIALIZATION ###");
    init_report::reset();
    assert_warn_store::reset();
    // Initialization throws on a failed assert (C clears `noThrowAsserts` here).
    let _ = rethrow_store::take();
    set_no_throw(false);
    term_report::reset();
    steady_report::reset();
    seed_start_values(e, sim_data, layout, inputs, model)?;
    log_static_data_update();
    // C sets `initial()` here: the start values and bound parameters above are
    // evaluated with it still clear.
    write_i32(e, sim_data + layout.initial_off, 1)?;

    // C's `IIM_NONE`: every variable keeps its start value, the initial system is
    // never solved. C still marks the systems solved before it picks the method.
    if crate::simflags::with_flags(|f| f.init_method) == crate::simflags::InitMethod::None {
        log_init_method("none", "sets all variables to their start values and skips the initialization process");
        write_i32(e, sim_data + layout.nls_fail_off, 0)?;
        return Ok(());
    }
    log_init_method("symbolic", "solves the initialization problem symbolically - default");

    symbolic_initialization(e, sim_data, layout, inputs, model)
}

/// C's `updateStaticDataOf{Linear,Nonlinear}Systems`: after the start values are
/// final, before the method is picked.
fn log_static_data_update() {
    omclog::info(omclog::LS_V, true, "update static data of linear system solvers");
    omclog::close(omclog::LS_V);
    omclog::info(omclog::NLS, true, "update static data of non-linear system solvers");
    omclog::close(omclog::NLS);
}

/// C's `INIT_METHOD_NAME`/`INIT_METHOD_DESC` line.
fn log_init_method(name: &str, desc: &str) {
    omclog::info(omclog::INIT, false, &format!("initialization method: {name:<15} [{desc}]"));
}

/// C's `symbolic_initialization`: solve, then check the equations the backend
/// removed as redundant.
fn symbolic_initialization(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    inputs: &[crate::InputVar],
    model: Option<&SimMeta>,
) -> Result<()> {
    // C's `storePreValues` opening `symbolic_initialization`, so a `$PRE.<discrete>`
    // read in an initial equation sees `start`. `-iim=none` never gets here, and the
    // homotopy retry below does not re-store.
    seed_pre_from_live(e, sim_data, layout)?;
    save_old_real(e, sim_data, layout)?;
    init_report::set_local(!layout.homotopy_method.is_global());
    let res = solve_initial_system(e, sim_data, layout, inputs, model);
    // A local approach counts its steps inside the runtime; collect them.
    init_report::add_homotopy_steps(e.rt_stats()[RT_STAT_HOMOTOPY_STEPS] as u32);
    res?;
    check_removed_initial_equations(e, sim_data, layout, model)
}

/// C's `symbolic_initialization` homotopy dispatch: only a *global* approach
/// continues here, a local one leaving the job to `rt_solve_nls`.
fn solve_initial_system(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    inputs: &[crate::InputVar],
    model: Option<&SimMeta>,
) -> Result<()> {
    use crate::HomotopyMethod as H;
    let method = layout.homotopy_method;
    if layout.has_homotopy && crate::simflags::with_flags(|f| f.homotopy_on_first_try).is_none() {
        omclog::info(
            omclog::INIT_HOMOTOPY,
            false,
            "Model contains homotopy operator: Use adaptive homotopy method to solve initialization \
             problem. To disable initialization with homotopy operator use \"-noHomotopyOnFirstTry\".",
        );
    }
    let mut solve_with_global = layout.has_homotopy
        && ((method == H::GlobalEquidistant && homotopy_steps() >= 1) || method == H::GlobalAdaptive);
    if !solve_with_global {
        return direct_initial_solve(e, sim_data, layout);
    }
    if !homotopy_on_first_try() {
        omclog::info(omclog::INIT_HOMOTOPY, false, "Try to solve the initialization problem without homotopy first.");
        if direct_initial_solve(e, sim_data, layout).is_ok() {
            solve_with_global = false;
        } else {
            omclog::warning(
                omclog::ASSERT,
                false,
                "Failed to solve the initialization problem without homotopy method. \
                 If homotopy is available the homotopy method is used now.",
            );
            // C's catch arm resets everything to start before the continuation runs.
            init_report::reset();
            let _ = rethrow_store::take();
            seed_start_values(e, sim_data, layout, inputs, model)?;
        }
    }
    if !solve_with_global {
        return Ok(());
    }
    if method == H::GlobalEquidistant {
        run_homotopy_continuation(e, sim_data, layout, model)?;
        init_report::add_homotopy_steps(homotopy_steps() as u32);
        return Ok(());
    }
    // GLOBAL_ADAPTIVE: the simplified lambda = 0 system first, then the actual one,
    // whose homotopy-carrying component runs the arc-length continuation itself.
    omclog::info(omclog::INIT_HOMOTOPY, false, "Global homotopy with adaptive step size started.");
    omclog::info(omclog::INIT_HOMOTOPY, true, "homotopy process\n---------------------------");
    write_f64(e, sim_data + layout.lambda_off, 0.0)?;
    omclog::info(omclog::INIT_HOMOTOPY, false, "solve simplified lambda0-DAE");
    call_initial_equations_lambda0(e, sim_data, layout)?;
    omclog::info(omclog::INIT_HOMOTOPY, false, "solving simplified lambda0-DAE done\n---------------------------");
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;
    e.call1("functionInitialEquations", sim_data)?;
    omclog::close(omclog::INIT_HOMOTOPY);
    check_nls(e, sim_data, layout)
}

/// The continuation's lambda = 0 step, falling back to the full initial system.
fn call_initial_equations_lambda0(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;
    if layout.has_init_lambda0 {
        return e.call1("functionInitialEquations_lambda0", sim_data);
    }
    omclog::warning(
        omclog::INIT_HOMOTOPY,
        false,
        "No initialEquation_lambda0 was generated. Using normal initial equation system with lambda=0 instead.",
    );
    e.call1("functionInitialEquations", sim_data)
}

/// C's over-determined check: the removed initial equations are residuals of the
/// solution just found, and one off zero means the problem has none.
fn check_removed_initial_equations(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    model: Option<&SimMeta>,
) -> Result<()> {
    if layout.n_removed_init == 0 {
        return Ok(());
    }
    e.call1("functionRemovedInitialEquations", sim_data)?;
    let idx = read_i32(e, sim_data + layout.removed_init_idx_off)?;
    if idx == 0 {
        return Ok(());
    }
    let res = read_f64(e, sim_data + layout.removed_init_res_off)?;
    let desc = model
        .and_then(|m| m.removed_init_desc.get(idx as usize - 1))
        .map(String::as_str)
        .unwrap_or_default();
    omclog::error(
        omclog::INIT,
        false,
        &format!(
            "The initialization problem is inconsistent due to the following equation: 0 != {} = {desc}",
            format_g(res, 6)
        ),
    );
    Err(report_init_failure())
}

/// C's `solver_main` reaction to a failed `initialization()`.
fn report_init_failure() -> &'static str {
    omclog::warning(
        omclog::STDOUT,
        false,
        "Error in initialization. Storing results and exiting.\nUse -lv=LOG_INIT -w for more information.",
    );
    INIT_FAILED_ERR
}

/// C's `setAllParamsToStart` + `setAllVarsToStart` + `updateBoundParameters` +
/// `updateBoundVariableAttributes`: every variable back at its start value with
/// the bound parameters recomputed. Run before each attempt at the initial system.
/// C's `fmi2Instantiate`/`fmi2Reset` run `setAllParamsToStart` +
/// `setAllVarsToStart` there too, not only in `initializeModel`: a get before
/// Initialization Mode is left must report the `start` attributes, and an equation
/// over a zeroed `SimData` can produce a NaN instead.
pub fn seed_start_state(e: &mut dyn SimEngine, sim_data: u32, model: &SimMeta) -> Result<()> {
    // `functionInitDelay` before any equation function, as in `init_model`.
    write_f64(e, sim_data + TIME_OFF, model.start_time)?;
    e.call1_if_present("functionInitDelay", sim_data)?;
    seed_start_values(e, sim_data, &model.layout, &model.inputs, Some(model))
}

fn seed_start_values(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    inputs: &[crate::InputVar],
    model: Option<&SimMeta>,
) -> Result<()> {
    // C's `initialization` order: `setAllParamsToStart`, the start values (here the
    // start expressions, then `-iif`/`-override`), `setAllVarsToStart`.
    e.call1("functionParameters", sim_data)?;
    apply_param_overrides(e, sim_data)?;
    e.call1("functionInitStartValues", sim_data)?;
    apply_external_input(e, sim_data, inputs)?;
    copy_start_values_to_init_values(e, sim_data, layout, model)?;
    // C's `read_init_from_file` branch runs them *before* `importStartValues`, giving
    // the file the last word on a start value.
    let from_file = crate::simflags::with_flags(|f| f.init_file.is_some());
    if from_file {
        update_bound_values(e, sim_data, layout, model)?;
        if let Some(m) = model {
            import_start_values(e, sim_data, m)?;
        }
    }
    apply_start_overrides(e, sim_data)?;
    set_all_vars_to_start(e, sim_data, layout, model, true)?;
    if !from_file {
        update_bound_values(e, sim_data, layout, model)?;
    }
    // The initial profiles come from parameter arrays, so this follows the bound
    // parameters and precedes the initial system (C's `initializeModel`). Idempotent:
    // it reallocates, so a retried initialization starts from a clean profile.
    e.call1_if_present("functionInitSpatialDistribution", sim_data)?;
    write_i32(e, sim_data + layout.rel_fresh_off, 2)?;
    if layout.n_samples > 0 {
        e.call1("initSample", sim_data)?;
    }
    Ok(())
}

/// C's `copyStartValuestoInitValues` (`model_help.c`), which `initializeModel` runs
/// *before* `initialization`: variables and `pre` both take the start attributes as
/// declared. `-iif` and the bound attributes come later, inside `initialization`, so
/// neither reaches these `pre` values.
fn copy_start_values_to_init_values(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    model: Option<&SimMeta>,
) -> Result<()> {
    set_all_vars_to_start(e, sim_data, layout, model, false)?;
    seed_pre_from_live(e, sim_data, layout)?;
    save_old_real(e, sim_data, layout)
}

/// C's `updateBoundParameters` + `updateBoundVariableAttributes`, always a pair and
/// after `setAllVarsToStart`, whose copy would undo the variables they assign.
fn update_bound_values(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    model: Option<&SimMeta>,
) -> Result<()> {
    e.call1("functionUpdateBoundParameters", sim_data)?;
    e.call1("functionUpdateBoundVariableAttributes", sim_data)?;
    log_bound_attr_updates(e, sim_data, layout, model);
    Ok(())
}

/// C's `updateBoundVariableAttributes` log, over the values the model left in the
/// attribute-log region. A group's header appears even when it is empty, as C's
/// unconditional `infoStreamPrint` in that function gives.
fn log_bound_attr_updates(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout, model: Option<&SimMeta>) {
    if !omclog::active(omclog::INIT) {
        return;
    }
    let entries: &[crate::AttrLog] = model.map_or(&[], |m| &m.attr_log);
    for (kind, name) in crate::ATTR_NAME.iter().enumerate() {
        let header = match *name {
            "start" => "primary start-values".to_string(),
            _ => format!("{name}-values"),
        };
        omclog::info(omclog::INIT, true, &format!("updating {header}"));
        if omclog::active(omclog::INIT_V) {
            for (i, a) in entries.iter().enumerate().filter(|(_, a)| a.kind as usize == kind) {
                let v = read_f64(e, sim_data + layout.attr_log_off + i as u32 * 8).unwrap_or(0.0);
                let line = match *name {
                    "start" => format!("updated start value: {}(start={})", a.name, format_g(v, 6)),
                    _ => format!("{}({name}={})", a.name, format_g(v, 6)),
                };
                omclog::info(omclog::INIT_V, false, &line);
            }
        }
        omclog::close(omclog::INIT);
    }
}

/// C's `printParameters` (`model_help.c`), which `dumpInitialSolution` opens with.
fn print_parameters(e: &dyn SimEngine, sim_data: u32, model: &SimMeta) {
    if !omclog::active(omclog::INIT_V) {
        return;
    }
    let p = &model.params;
    let layout = &model.layout;
    // `-override` rewrites the `_init.xml` entry, `start` included; the import
    // assigns `attribute.start` directly.
    let ov = overrides_store::params();
    let imported = imported_param_starts(model);
    let start_of = |off: u32, v: f64| {
        ov.iter()
            .find(|o| o.0 == off)
            .map(|o| o.2)
            .or_else(|| imported.iter().find(|i| i.0 == off).map(|i| i.1))
            .unwrap_or(v)
    };
    omclog::info(omclog::INIT_V, true, "parameter values");
    let mut group = |header: &str, lines: alloc::vec::Vec<String>| {
        if lines.is_empty() {
            return;
        }
        omclog::info(omclog::INIT_V, true, header);
        for l in &lines {
            omclog::info(omclog::INIT_V, false, l);
        }
        omclog::close(omclog::INIT_V);
    };
    let fixed = |f: bool| if f { "true" } else { "false" };
    group(
        "real parameters",
        p.reals
            .iter()
            .enumerate()
            .map(|(i, (n, start, f))| {
                let off = layout.rparam_off + i as u32 * 8;
                let v = read_f64(e, sim_data + off).unwrap_or(0.0);
                format!(
                    "[{}] parameter Real {n}(start={}, fixed={}) = {}",
                    i + 1,
                    format_g(start_of(off, *start), 6),
                    fixed(*f),
                    format_g(v, 6)
                )
            })
            .collect(),
    );
    group(
        "integer parameters",
        p.ints
            .iter()
            .enumerate()
            .map(|(i, (n, start, f))| {
                let off = layout.iparam_off + i as u32 * 4;
                let v = read_i32(e, sim_data + off).unwrap_or(0);
                let start = start_of(off, *start as f64) as i32;
                format!("[{}] parameter Integer {n}(start={start}, fixed={}) = {v}", i + 1, fixed(*f))
            })
            .collect(),
    );
    let b = |v: i32| if v != 0 { "true" } else { "false" };
    group(
        "boolean parameters",
        p.bools
            .iter()
            .enumerate()
            .map(|(i, (n, start, f))| {
                let off = layout.bparam_off + i as u32 * 4;
                let v = read_i32(e, sim_data + off).unwrap_or(0);
                format!(
                    "[{}] parameter Boolean {n}(start={}, fixed={}) = {}",
                    i + 1,
                    b(start_of(off, *start as f64) as i32),
                    fixed(*f),
                    b(v)
                )
            })
            .collect(),
    );
    group(
        "string parameters",
        p.strings
            .iter()
            .enumerate()
            .map(|(i, (n, start))| {
                let h = read_i32(e, sim_data + layout.sparam_off + i as u32 * 4).unwrap_or(0);
                let v = read_rt_string(e, h).unwrap_or_default();
                format!("[{}] parameter String {n}(start=\"{start}\") = \"{v}\"", i + 1)
            })
            .collect(),
    );
    omclog::close(omclog::INIT_V);
}

/// Solve the initial system at lambda = 1, where `homotopy(a, s)` is `a`.
fn direct_initial_solve(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    write_f64(e, sim_data + layout.lambda_off, 1.0)?;
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;
    e.call1("functionInitialEquations", sim_data)?;
    check_nls(e, sim_data, layout)
}

/// C's `FLAG_HOMOTOPY_ON_FIRST_TRY`, which it sets itself for a model with
/// homotopy support unless `-noHomotopyOnFirstTry` was given.
fn homotopy_on_first_try() -> bool {
    crate::simflags::with_flags(|f| f.homotopy_on_first_try).unwrap_or(true)
}

/// Global equidistant homotopy continuation (C's `solveWithGlobalHomotopy`):
/// lambda 0 → 1 in `HOMOTOPY_STEPS` steps, step 0 solving the simplified
/// `functionInitialEquations_lambda0`, each step seeded by the previous solution.
/// Leaves lambda = 1.
fn run_homotopy_continuation(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    model: Option<&SimMeta>,
) -> Result<()> {
    let steps = homotopy_steps();
    omclog::info(omclog::INIT_HOMOTOPY, false, "Global homotopy with equidistant step size started.");
    let mut path = HomotopyPath::open(model, "equidistant_global_homotopy.csv");
    path.header(model);
    omclog::info(omclog::INIT_HOMOTOPY, true, "homotopy process\n---------------------------");
    // C runs every step unconditionally and checks the systems once at the end
    // (`check_nonlinear_solutions`), so a system that misses at lambda = 1/3 and
    // lands at lambda = 1 is not a failure. A model assert still aborts.
    for step in 0..=steps {
        let lambda = (step as f64 / steps as f64).min(1.0);
        write_f64(e, sim_data + layout.lambda_off, lambda)?;
        omclog::info(omclog::INIT_HOMOTOPY, false, &format!("homotopy parameter lambda = {}", format_g(lambda, 6)));
        if step == 0 {
            call_initial_equations_lambda0(e, sim_data, layout)?;
        } else {
            write_i32(e, sim_data + layout.nls_fail_off, 0)?;
            e.call1("functionInitialEquations", sim_data)?;
        }
        omclog::info(
            omclog::INIT_HOMOTOPY,
            false,
            &format!("homotopy parameter lambda = {} done\n---------------------------", format_g(lambda, 6)),
        );
        path.row(e, sim_data, layout, lambda);
    }
    omclog::close(omclog::INIT_HOMOTOPY);
    path.finish();
    write_f64(e, sim_data + layout.lambda_off, 1.0)?;
    if check_nls(e, sim_data, layout).is_err() {
        omclog::error(
            omclog::ASSERT,
            false,
            "Failed to solve the initialization problem with global homotopy with equidistant step size.",
        );
        init_report::set_failed_step(steps);
        return Err("CodegenWasmJit: homotopy initialization did not converge at lambda");
    }
    Ok(())
}

/// C's `log_homotopy_lambda_vars`: with `-lv=LOG_INIT_HOMOTOPY` the real variable
/// vector is appended to `<prefix>_<name>` at every accepted lambda. Inert without
/// a filesystem, as C's `OMC_NO_FILESYSTEM` builds are.
struct HomotopyPath {
    #[cfg(feature = "std")]
    file: Option<(String, String)>,
}

impl HomotopyPath {
    fn open(model: Option<&SimMeta>, name: &str) -> Self {
        #[cfg(feature = "std")]
        {
            let file = match model {
                Some(m) if omclog::active(omclog::INIT_HOMOTOPY) => {
                    let path = format!("{}_{name}", m.prefix);
                    omclog::info(
                        omclog::INIT_HOMOTOPY,
                        false,
                        &format!("The homotopy path will be exported to {path}."),
                    );
                    Some((path, String::new()))
                }
                _ => None,
            };
            HomotopyPath { file }
        }
        #[cfg(not(feature = "std"))]
        {
            let _ = (model, name);
            HomotopyPath {}
        }
    }

    fn header(&mut self, model: Option<&SimMeta>) {
        #[cfg(feature = "std")]
        if let (Some((_, buf)), Some(m)) = (self.file.as_mut(), model) {
            buf.push_str("\"lambda\"");
            for name in &m.soti.reals {
                buf.push_str(&format!(",\"{name}\""));
            }
            buf.push('\n');
        }
    }

    fn row(&mut self, e: &dyn SimEngine, sim_data: u32, layout: &SimLayout, lambda: f64) {
        let _ = (sim_data, layout, lambda, e);
        #[cfg(feature = "std")]
        if let Some((_, buf)) = self.file.as_mut() {
            buf.push_str(&format_g(lambda, 16));
            for i in 0..2 * layout.n_states + layout.n_real_alg {
                let v = read_f64(e, sim_data + crate::REAL_OFF + i * 8).unwrap_or(f64::NAN);
                buf.push(',');
                buf.push_str(&format_g(v, 16));
            }
            buf.push('\n');
        }
    }

    fn finish(&mut self) {
        #[cfg(feature = "std")]
        if let Some((path, buf)) = self.file.take() {
            let _ = std::fs::write(path, buf);
        }
    }
}

/// Append one trajectory row to `rows`: the real part `[time | realVars]`
/// followed by the integer and boolean algebraic slots (converted to f64),
/// matching `SimLayout::n_row_total()` and the column layout `kind_from_slot`
/// assigns. Used by the host-driven drivers; the in-wasm `simulate` emits the
/// same layout.
pub(crate) fn capture_row(e: &dyn SimEngine, rows: &mut Vec<f64>, sim_data: u32, layout: &SimLayout) -> Result<()> {
    for i in 0..layout.n_reals_row() {
        rows.push(read_f64(e, sim_data + i * 8)?);
    }
    for i in 0..layout.n_int_alg() {
        rows.push(read_i32(e, sim_data + layout.int_off + i * 4)? as f64);
    }
    for j in 0..layout.n_bool_alg() {
        rows.push(read_i32(e, sim_data + layout.bool_off + j * 4)? as f64);
    }
    // Zero for every solver but IDA, which refreshes it from `IDAGetSens`.
    for k in 0..layout.n_sens {
        rows.push(read_f64(e, sim_data + layout.sens_off + k * 8)?);
    }
    Ok(())
}

/// Whether the run stops here rather than at `stopTime`: `terminate()` raised the
/// `SimData` flag during the last step (C's `checkSimulationTerminated`), or
/// `-steadyState` is satisfied. Every driver asks after each output row, so both
/// C stop conditions are served in one place. The first observation reports it.
pub(crate) fn terminated(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<bool> {
    if read_i32(e, sim_data + layout.terminate_off)? == 0 {
        return steady_state_reached(e, sim_data, layout);
    }
    report_terminate(e, sim_data, layout, false)?;
    Ok(true)
}

/// C's `checkSimulationTerminated` notice: the source position raw (`printInfo`,
/// outside the message system) then the message, once per run. `at_init` picks
/// the wording C uses before the main loop.
fn report_terminate(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout, at_init: bool) -> Result<()> {
    if !term_report::mark() {
        return Ok(());
    }
    let w = |i: u32| read_i32(e, sim_data + layout.term_info_off + i * 4);
    let msg = read_rt_string(e, w(0)?)?;
    let file = read_rt_string(e, w(1)?)?;
    if !file.is_empty() {
        let ro = if w(6)? != 0 { "readonly" } else { "writable" };
        log_line(&format!("[{file}:{}:{}-{}:{}:{ro}]\n", w(2)?, w(3)?, w(4)?, w(5)?));
    }
    let time = format_f(read_f64(e, sim_data + TIME_OFF)?);
    let at = if at_init { format!("at initialization (time {time})") } else { format!("at time {time}") };
    omclog::info(omclog::STDOUT, false, &format!("Simulation call terminate() {at}\nMessage : {msg}"));
    Ok(())
}

/// C's `-steadyState` (`perform_simulation.c.inc`): the run ends once every state
/// derivative is under `-steadyStateTol` relative to that state's nominal.
fn steady_state_reached(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<bool> {
    let Some(tol) = crate::simflags::with_flags(crate::simflags::steady_state_tol) else {
        return Ok(false);
    };
    if layout.n_states == 0 {
        return Err("No states in model. Flag -steadyState can only be used if states are present.");
    }
    let ders = sim_data + REAL_OFF + layout.n_states * 8;
    let mut max_der = 0.0f64;
    for i in 0..layout.n_states {
        let nominal = read_f64(e, sim_data + layout.state_nom_off + i * 8)?;
        let d = libm::fabs(read_f64(e, ders + i * 8)? / nominal);
        if max_der < d {
            max_der = d;
        }
    }
    if max_der >= tol {
        return Ok(false);
    }
    steady_report::mark();
    omclog::info(
        omclog::STDOUT,
        false,
        &format!(
            "steady state reached at time = {}\n  * max(|d(x_i)/dt|/nominal(x_i)) = {}\n  * \
             relative tolerance = {}",
            format_g(read_f64(e, sim_data + TIME_OFF)?, 6),
            format_g(max_der, 6),
            format_g(tol, 6),
        ),
    );
    Ok(true)
}

/// C's `updateContinuousSystem`: recompute everything an output row reads. A
/// `--daeMode` model has no explicit ODE, so that is one algebraic-stage residual.
/// C's `function_storeDelayed` + `function_storeSpatialDistribution`, the tail of
/// `updateContinuousSystem`: the operators with an internal history record the point
/// the model was last evaluated at. A model without any skips it entirely.
pub(crate) fn store_operators(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if !layout.has_history_ops {
        return Ok(());
    }
    e.call1_if_present("functionStoreDelayed", sim_data)?;
    e.call1_if_present("functionStoreSpatialDistribution", sim_data)
}

/// [`store_operators`] at an accepted point the model has not been evaluated at yet:
/// the whole of C's `updateContinuousSystem`. `spatialDistribution` reads its
/// boundary conditions out of `SimData`, and its own `x` must not have moved by the
/// time the discrete update calls it, so the store belongs *before* the event.
fn store_operators_at(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    time: f64,
) -> Result<()> {
    if !layout.has_history_ops {
        return Ok(());
    }
    write_f64(e, sim_data + TIME_OFF, time)?;
    eval_continuous(e, sim_data, layout)?;
    store_operators(e, sim_data, layout)
}

pub(crate) fn eval_continuous(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if layout.dae_mode() {
        return e.call2(MODEL_FN_DAE, sim_data, eval_stage::ALGEBRAIC);
    }
    e.call1("functionODE", sim_data)?;
    e.call1("functionAlgebraics", sim_data)
}

/// `functionODE` alone: the derivative slots for the state the integrator last
/// wrote. In DAE mode `y'` is an unknown, so the dynamic residual stage stands in.
fn eval_ode(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if layout.dae_mode() {
        return e.call2(MODEL_FN_DAE, sim_data, eval_stage::DYNAMIC);
    }
    e.call1("functionODE", sim_data)
}

/// One pass of C's `functionDAE`: the discrete update.
fn eval_discrete(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if layout.dae_mode() {
        return e.call2(MODEL_FN_DAE, sim_data, eval_stage::DISCRETE);
    }
    e.call1("functionODE", sim_data)?;
    e.call1("functionAlgebraics", sim_data)
}

/// C's `function_ZeroCrossingsEquations`: what the crossing functions read.
fn eval_zc_equations(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if layout.dae_mode() {
        return e.call2(MODEL_FN_DAE, sim_data, eval_stage::ZEROCROSS);
    }
    e.call1("functionZeroCrossingsEquations", sim_data)
}

/// Emit one result row from SimData at `time`, recomputing `functionODE`/
/// `functionAlgebraics` first so the reported derivatives/algebraics are consistent.
/// The integrator has accepted the state, so a non-converging NLS here is a genuine
/// failure; `nls_fail` is cleared first so `check_nls` sees only this point's solve.
fn emit_row(
    e: &mut dyn SimEngine,
    rows: &mut Vec<f64>,
    sim_data: u32,
    layout: &SimLayout,
    time: f64,
    stop: f64,
) -> Result<()> {
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;
    write_f64(e, sim_data + TIME_OFF, time)?;
    eval_continuous(e, sim_data, layout)?;
    check_nls(e, sim_data, layout)?;
    capture_row(e, rows, sim_data, layout)?;
    check_asserts(e, sim_data, layout, if time >= stop { omclog::WARNING } else { omclog::INFO })
}

/// C's `finishSimulation`: a discrete update with `terminal()` true and one more
/// row at the same time, so a `when terminal()` body reaches the result file. `at`
/// overrides that time for a driver whose last row is older than `stopTime`
/// ([`Driver::terminal_time`]).
pub fn emit_terminal_row(
    e: &mut dyn SimEngine,
    rows: &mut Vec<f64>,
    sim_data: u32,
    layout: &SimLayout,
    n_reals: u32,
    at: Option<f64>,
) -> Result<()> {
    let Some(time) = rows.len().checked_sub(n_reals as usize).map(|i| at.unwrap_or(rows[i])) else {
        return Ok(());
    };
    if no_event_emit() {
        return Ok(());
    }
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;
    write_f64(e, sim_data + TIME_OFF, time)?;
    write_i32(e, sim_data + layout.terminal_off, 1)?;
    // A discrete call, so relations are live (C's `updateDiscreteSystem`
    // prologue): a condition that only becomes true at `stop` flips here.
    write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
    let updated = refresh_relations(e, sim_data, layout).and_then(|_| iterate_discrete(e, sim_data, layout));
    write_i32(e, sim_data + layout.terminal_off, 0)?;
    updated?;
    check_nls(e, sim_data, layout)?;
    capture_row(e, rows, sim_data, layout)?;
    check_asserts(e, sim_data, layout, omclog::WARNING)
}

/// C's `writeOutputVars` (`solver_main.c`): `time=<t>` and each `-output` name's
/// final value, Reals as `%.20g` and Strings quoted. A name contributes once per
/// match, as C's loops over the `modelData` arrays do.
fn write_output_vars(
    e: &dyn SimEngine,
    model: &SimModel,
    sim_data: u32,
    rows: &[f64],
    n_reals: usize,
    names: &[String],
) -> Result<()> {
    if n_reals == 0 || rows.len() < n_reals {
        return Ok(());
    }
    let layout = &model.layout;
    let last = rows.len() - n_reals;
    let n_real_cols = layout.n_reals_row();
    let mut out = format!("time={}", format_g(rows[last], 20));
    for name in names {
        for v in &model.vars {
            if v.name != *name {
                continue;
            }
            match &v.kind {
                ResultKind::Time => {}
                ResultKind::Column { col, negate } => {
                    let raw = negate.apply_f64(rows[last + *col as usize]);
                    if *col < n_real_cols {
                        out.push_str(&format!(",{name}={}", format_g(raw, 20)));
                    } else {
                        out.push_str(&format!(",{name}={}", raw as i64));
                    }
                }
                ResultKind::Param { off, wty, negate } => match wty {
                    WTy::F64 => {
                        let v = negate.apply_f64(read_f64(e, sim_data + off)?);
                        out.push_str(&format!(",{name}={}", format_g(v, 20)));
                    }
                    WTy::I32 => {
                        let v = negate.apply_f64(read_i32(e, sim_data + off)? as f64);
                        out.push_str(&format!(",{name}={}", v as i64));
                    }
                },
                ResultKind::Const { value } => out.push_str(&format!(",{name}={}", format_g(*value, 20))),
            }
        }
        // Strings own no result column; C reads them from `stringVars`/`stringParameter`.
        let mut string_at = |off: u32| -> Result<()> {
            let s = read_rt_string(e, read_i32(e, sim_data + off)?)?;
            out.push_str(&format!(",{name}=\"{s}\""));
            Ok(())
        };
        for (i, (n, _)) in model.soti.strings.iter().enumerate() {
            if n == name {
                string_at(layout.str_off + i as u32 * 4)?;
            }
        }
        for (i, (n, _)) in model.params.strings.iter().enumerate() {
            if n == name {
                string_at(layout.sparam_off + i as u32 * 4)?;
            }
        }
    }
    out.push('\n');
    log_line(&out);
    Ok(())
}

/// The initial result row. C emits it straight after `initializeModel` with no
/// re-evaluation: `SimData` is already consistent, and re-running the equations
/// would repeat any side effect they have (`Streams.print`).
pub(crate) fn emit_initial_row(
    e: &mut dyn SimEngine,
    rows: &mut Vec<f64>,
    sim_data: u32,
    layout: &SimLayout,
    time: f64,
) -> Result<()> {
    write_f64(e, sim_data + TIME_OFF, time)?;
    capture_row(e, rows, sim_data, layout)?;
    check_asserts(e, sim_data, layout, omclog::WARNING)
}

/// Pre-event snapshot row (state just before a discrete update). Skips
/// `functionAlgebraics` for `has_when` models — there it saves `pre` early, which
/// would break the post-event edge test.
fn capture_pre(e: &mut dyn SimEngine, rows: &mut Vec<f64>, sim_data: u32, layout: &SimLayout, time: f64) -> Result<()> {
    write_f64(e, sim_data + TIME_OFF, time)?;
    if layout.has_when {
        eval_ode(e, sim_data, layout)?;
    } else {
        eval_continuous(e, sim_data, layout)?;
    }
    capture_row(e, rows, sim_data, layout)
}

/// Copy the live real-variable region (states | derivatives | real algebraics) to
/// its pre-value mirror. Called at a state event before the discrete update so
/// `pre(x)` of a continuous variable equals its value *at the event* — e.g.
/// `reinit(v, -0.8*pre(v))` must see the impact velocity, not the last output
/// row's. The boolean/integer pre regions are deliberately left stale so the
/// when-body edge test (`cond && !pre(cond)`) still fires.
fn save_pre_real(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    let bytes = ((2 * layout.n_states + layout.n_real_alg) * 8) as usize;
    if bytes == 0 {
        return Ok(());
    }
    let mut buf = vec![0u8; bytes];
    e.read_bytes(sim_data + REAL_OFF, &mut buf)?;
    e.write_bytes(sim_data + layout.pre_real_off, &buf)
}

/// C's `rotateRingBuffer` + `overwriteOldSimulationData`: the live reals become
/// `localData[1]`. Only a method-1 linear system reads them (its `aux_x`).
fn save_old_real(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if !layout.has_old_real {
        return Ok(());
    }
    let mut buf = vec![0u8; layout.real_bytes()];
    e.read_bytes(sim_data + REAL_OFF, &mut buf)?;
    e.write_bytes(sim_data + layout.old_real_off, &buf)
}

/// Copy the live real/integer/boolean regions into their `pre()` mirrors (C's
/// `storePreValues`), so `$PRE.<var>` reads the current value. Used at init to
/// seed `pre` from the start values before the initial system solves.
fn seed_pre_from_live(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    let regions = [
        (REAL_OFF, layout.pre_real_off, (2 * layout.n_states + layout.n_real_alg) * 8),
        (layout.int_off, layout.pre_int_off, layout.n_int_alg() * 4),
        (layout.bool_off, layout.pre_bool_off, layout.n_bool_alg() * 4),
    ];
    for (live, pre, bytes) in regions {
        if bytes == 0 {
            continue;
        }
        let mut buf = vec![0u8; bytes as usize];
        e.read_bytes(sim_data + live, &mut buf)?;
        e.write_bytes(sim_data + pre, &buf)?;
    }
    Ok(())
}

/// C's `initializeModel` input step: `input_function_init` seeds `inputVars` from
/// the inputs' start attributes, `externalInputUpdate` replaces them with
/// `-csvInput` at `t0`, and `input_function_updateStartValues` writes them back as
/// the start attributes — so `setAllVarsToStart` puts the file's values on the
/// inputs. Runs before the attribute equations and `-iif`, both of which C lets
/// win over the file.
#[cfg(feature = "std")]
fn apply_external_input(
    e: &mut dyn SimEngine,
    sim_data: u32,
    inputs: &[crate::InputVar],
) -> Result<()> {
    if inputs.is_empty() {
        return Ok(());
    }
    let Some(file) = crate::simflags::with_flags(|f| f.csv_input.clone()) else { return Ok(()) };
    let names: Vec<&str> = inputs.iter().map(|v| v.name.as_str()).collect();
    let Some(mut ext) = crate::extinput::ExternalInput::load(&file, &names) else { return Ok(()) };
    // C's `input_function_init`; `externalInputUpdate` rewrites every entry (a
    // column the file lacks becomes 0, from its `calloc`ed rows), so this only
    // matters for the shape.
    let mut u = crate::extinput::empty(inputs.len());
    let t = read_f64(e, sim_data + TIME_OFF)?;
    ext.update(t, &mut u);
    for (input, v) in inputs.iter().zip(&u) {
        match input.wty {
            crate::WTy::F64 => write_f64(e, sim_data + input.off, *v)?,
            crate::WTy::I32 => write_i32(e, sim_data + input.off, *v as i32)?,
        }
    }
    Ok(())
}

/// `-csvInput` needs a filesystem, which the in-wasm runtime has not.
#[cfg(not(feature = "std"))]
fn apply_external_input(
    _e: &mut dyn SimEngine,
    _sim_data: u32,
    _inputs: &[crate::InputVar],
) -> Result<()> {
    Ok(())
}

/// C's `setAllVarsToStart` for the reals: every real variable takes its `start`
/// attribute. Integer/Boolean/String starts are still the emitted equations'.
/// C's `setAllVarsToStart`. `with_imports` is false for the pass before
/// `initialization` ([`copy_start_values_to_init_values`]), which predates `-iif`.
fn set_all_vars_to_start(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    model: Option<&SimMeta>,
    with_imports: bool,
) -> Result<()> {
    // The discrete `start` attributes are constants, so they are metadata rather
    // than a `SimData` region; C reads them out of the `_init.xml`.
    if let Some(m) = model {
        for (i, (_, start)) in m.soti.ints.iter().enumerate() {
            write_i32(e, sim_data + layout.int_off + i as u32 * 4, *start)?;
        }
        for (i, (_, start)) in m.soti.bools.iter().enumerate() {
            write_i32(e, sim_data + layout.bool_off + i as u32 * 4, *start)?;
        }
        // `-iif` replaced those constants, and C's `attribute.start` is what it wrote.
        if with_imports {
            for (off, start) in imported_discrete_starts(m) {
                write_i32(e, sim_data + off, start)?;
            }
        }
    }
    let bytes = ((2 * layout.n_states + layout.n_real_alg) * 8) as usize;
    if bytes == 0 {
        return Ok(());
    }
    let mut buf = vec![0u8; bytes];
    e.read_bytes(sim_data + layout.start_off, &mut buf)?;
    e.write_bytes(sim_data + REAL_OFF, &buf)
}

/// Upper bound on discrete-update iterations at one event: C's `maxEventIterations`
/// default, which `-mei` replaces.
const MAX_EVENT_ITER: usize = 20;

fn max_event_iter() -> usize {
    crate::simflags::with_flags(|f| f.max_event_iter).map_or(MAX_EVENT_ITER, |n| n as usize)
}

/// C's `bisection` iteration bound (`events.c`, `gbode_events.c`): `-mbi` when it is
/// set to a positive value, else what halving the bracket down to `ttol` takes.
pub(crate) fn bisection_iterations(width: f64, ttol: f64) -> i64 {
    match crate::simflags::with_flags(|f| f.max_bisection_iter) {
        Some(n) if n > 0 => n as i64,
        _ => 1 + libm::ceil(libm::log(libm::fabs(width) / ttol) / libm::log(2.0)) as i64,
    }
}

/// Hold the zero-crossing g-values as `pre(zeroCrossing)`.
fn save_zc_pre(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if layout.n_zc == 0 {
        return Ok(());
    }
    let mut buf = vec![0u8; (layout.n_zc * 8) as usize];
    e.read_bytes(sim_data + layout.zc_off, &mut buf)?;
    e.write_bytes(sim_data + layout.zc_pre_off, &buf)
}

/// C's `sign()` (`omc_math.h`).
fn zsign(v: f64) -> i32 {
    if v > 0.0 {
        1
    } else if v < 0.0 {
        -1
    } else {
        0
    }
}

/// C's `checkForStateEvent` (`events.c`): the crossings whose g-value changed sign
/// against the held one. The root finding only supplies the time.
fn zc_sign_changed(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<Vec<usize>> {
    let mut out = Vec::new();
    for i in 0..layout.n_zc {
        let cur = read_f64(e, sim_data + layout.zc_off + i * 8)?;
        let pre = read_f64(e, sim_data + layout.zc_pre_off + i * 8)?;
        if zsign(cur) != zsign(pre) {
            out.push(i as usize);
        }
    }
    Ok(out)
}

/// C's `saveZeroCrossings` (`model_help.c`), the tail of every `simulationUpdate`:
/// hold, then recompute at the accepted point.
fn save_zero_crossings(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
) -> Result<Vec<usize>> {
    if layout.n_zc == 0 {
        return Ok(Vec::new());
    }
    save_zc_pre(e, sim_data, layout)?;
    e.call1("functionZeroCrossings", sim_data)?;
    zc_sign_changed(e, sim_data, layout)
}

/// C's `saveZeroCrossingsAfterEvent` (`events.c`): recompute first, *then* hold, so
/// the discrete update's own jump is not read as a crossing.
fn save_zero_crossings_after_event(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
) -> Result<()> {
    if layout.n_zc == 0 {
        return Ok(());
    }
    e.call1("functionZeroCrossings", sim_data)?;
    save_zc_pre(e, sim_data, layout)
}

/// Copy `relations[]` into the held relation snapshot at `stored_rel_off`. The
/// hysteresis band and the zero-crossing function read the snapshot as their
/// *direction*. It is refreshed at init and around each event, and left untouched
/// during an event's discrete update so the band edge stays fixed while
/// `iterate_discrete` rewrites `relations[]`.
fn store_relations(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if layout.n_rel == 0 {
        return Ok(());
    }
    let mut buf = vec![0u8; (layout.n_rel * 4) as usize];
    e.read_bytes(sim_data + layout.relations_off, &mut buf)?;
    e.write_bytes(sim_data + layout.stored_rel_off, &buf)
}

/// C's `updateDiscreteSystem` prologue: recompute every relation exactly, then
/// seed both `relationsPre` and the held snapshot from it. Without it the snapshot
/// comes from the banded evaluation the old snapshot itself steers, so a crossing
/// is never consumed.
fn refresh_relations(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    e.call1("functionUpdateRelations", sim_data)?;
    update_relations_pre(e, sim_data, layout)?;
    store_relations(e, sim_data, layout)
}

/// C's `dumpInitialSolution` (`initialization.c`): the `LOG_SOTI` block, printed
/// after the initial system is solved and *before* the pre-values are stored — so
/// a derivative still reads `(pre: 0)`.
fn dump_initial_solution(e: &dyn SimEngine, sim_data: u32, model: &SimMeta) {
    print_parameters(e, sim_data, model);
    if !omclog::active(omclog::SOTI) {
        return;
    }
    let layout = &model.layout;
    let soti = &model.soti;
    let n = layout.n_states as usize;
    let real = |off: u32| read_f64(e, sim_data + off).unwrap_or(0.0);
    let pre_real = |off: u32| layout.pre_slot_off(off).map_or(0.0, |p| real(p));
    let g = |v: f64| format_g(v, 6);
    omclog::info(omclog::SOTI, true, "### SOLUTION OF THE INITIALIZATION ###");
    let real_line = |i: usize| {
        let off = REAL_OFF + i as u32 * 8;
        let name = &soti.reals[i];
        format!(
            "[{}] Real {name}(start={}, nominal={}) = {} (pre: {})",
            i + 1,
            g(real(layout.real_start_off(i as u32))),
            g(real(layout.real_nominal_off(i as u32))),
            g(real(off)),
            g(pre_real(off))
        )
    };
    if n > 0 && soti.reals.len() >= 2 * n {
        omclog::info(omclog::SOTI, true, "states variables");
        for i in 0..n {
            omclog::info(omclog::SOTI, false, &real_line(i));
        }
        omclog::close(omclog::SOTI);
        omclog::info(omclog::SOTI, true, "derivatives variables");
        for i in n..2 * n {
            let off = REAL_OFF + i as u32 * 8;
            let name = &soti.reals[i];
            let line = format!("[{}] Real {name} = {} (pre: {})", i + 1, g(real(off)), g(pre_real(off)));
            omclog::info(omclog::SOTI, false, &line);
        }
        omclog::close(omclog::SOTI);
    }
    if soti.reals.len() > 2 * n {
        omclog::info(omclog::SOTI, true, "other real variables");
        for i in 2 * n..soti.reals.len() {
            omclog::info(omclog::SOTI, false, &real_line(i));
        }
        omclog::close(omclog::SOTI);
    }
    let i32_at = |off: u32| read_i32(e, sim_data + off).unwrap_or(0);
    let pre_i32 = |off: u32| layout.pre_slot_off(off).map_or(0, |p| i32_at(p));
    // A real's `start` is the slot the import wrote; a discrete one is metadata.
    let imported = imported_discrete_starts(model);
    let start_of = |off: u32, v: i32| imported.iter().find(|i| i.0 == off).map_or(v, |i| i.1);
    if !soti.ints.is_empty() {
        omclog::info(omclog::SOTI, true, "integer variables");
        for (i, (name, start)) in soti.ints.iter().enumerate() {
            let off = layout.int_off + i as u32 * 4;
            let line = format!(
                "[{}] Integer {name}(start={}) = {} (pre: {})",
                i + 1,
                start_of(off, *start),
                i32_at(off),
                pre_i32(off)
            );
            omclog::info(omclog::SOTI, false, &line);
        }
        omclog::close(omclog::SOTI);
    }
    if !soti.bools.is_empty() {
        omclog::info(omclog::SOTI, true, "boolean variables");
        let b = |v: i32| if v != 0 { "true" } else { "false" };
        for (i, (name, start)) in soti.bools.iter().enumerate() {
            let off = layout.bool_off + i as u32 * 4;
            let line = format!(
                "[{}] Boolean {name}(start={}) = {} (pre: {})",
                i + 1,
                b(start_of(off, *start)),
                b(i32_at(off)),
                b(pre_i32(off))
            );
            omclog::info(omclog::SOTI, false, &line);
        }
        omclog::close(omclog::SOTI);
    }
    if !soti.strings.is_empty() {
        omclog::info(omclog::SOTI, true, "string variables");
        for (i, (name, start)) in soti.strings.iter().enumerate() {
            let cur = read_rt_string(e, i32_at(layout.str_off + i as u32 * 4)).unwrap_or_default();
            let line = format!("[{}] String {name}(start=\"{start}\") = \"{cur}\" (pre: \"{cur}\")", i + 1);
            omclog::info(omclog::SOTI, false, &line);
        }
        omclog::close(omclog::SOTI);
    }
    omclog::close(omclog::SOTI);
}

/// C's `perform_simulation` event header plus `handleEvents`' crossing list. Left
/// open until the discrete update has run, so the model's `reinit` lines land in it.
fn log_state_event(time: f64, roots: &[usize], model: &SimMeta) {
    if !omclog::active(omclog::EVENTS) {
        return;
    }
    omclog::info(omclog::EVENTS, true, &format!("state event at time={}", format_g(time, 12)));
    // Highest index first: C's `checkForStateEvent` pushes each crossing onto the
    // front of the event list it then walks, so simultaneous ones come out reversed.
    for &i in roots.iter().rev() {
        let desc = model.zc_desc.get(i).map(String::as_str).unwrap_or_default();
        omclog::info(omclog::EVENTS, false, &format!("[{}] {desc}", i + 1));
    }
}

/// C's `algStmtReinit` message, from what the model recorded during the update.
fn log_reinits(e: &mut dyn SimEngine, model: &SimMeta) {
    for (off, value) in e.take_pending_reinits() {
        if !omclog::active(omclog::EVENTS) {
            continue;
        }
        let col = 1 + off.saturating_sub(REAL_OFF) / 8; // column 0 is `time`
        let name = model
            .vars
            .iter()
            .find(|v| matches!(v.kind, ResultKind::Column { col: c, negate: Neg::None } if c == col))
            .map(|v| v.name.as_str())
            .unwrap_or_default();
        omclog::info(omclog::EVENTS, false, &format!("reinit {name} = {}", format_g(value, 6)));
    }
}

/// [`log_state_event`] for a time event: C names the samples that fired.
fn log_time_event(time: f64, samples: &Samples, model: &SimMeta) {
    if !omclog::active(omclog::EVENTS) {
        return;
    }
    omclog::info(omclog::EVENTS, true, &format!("time event at time={}", format_g(time, 12)));
    for (k, start, interval) in samples.due(time) {
        let index = model.sample_index.get(k).copied().unwrap_or(k as i32 + 1);
        omclog::info(
            omclog::EVENTS,
            false,
            &format!("[{index}] sample({}, {})", format_g(start, 6), format_g(interval, 6)),
        );
    }
}

/// C's `printRelations` + `printZeroCrossings` (`model_help.c`), which
/// `initializeModel` ends with on `LOG_EVENTS`.
pub fn log_event_status(e: &dyn SimEngine, sim_data: u32, model: &SimMeta, stream: omclog::Stream) -> Result<()> {
    if !omclog::active(stream) {
        return Ok(());
    }
    let layout = &model.layout;
    let time = format_g(read_f64(e, sim_data + TIME_OFF)?, 12);
    omclog::info(stream, true, &format!("status of relations at time={time}"));
    for i in 0..layout.n_rel {
        let flag = |off: u32| if read_i32(e, sim_data + off + i * 4).unwrap_or(0) != 0 { " true" } else { "false" };
        let desc = model.rel_desc.get(i as usize).map(String::as_str).unwrap_or_default();
        let (pre, cur) = (flag(layout.relations_pre_off), flag(layout.relations_off));
        omclog::info(stream, false, &format!("[{}] (pre: {pre}) {cur} = {desc}", i + 1));
    }
    omclog::close(stream);
    omclog::info(stream, true, &format!("status of zero crossings at time={time}"));
    for i in 0..layout.n_zc {
        let g = |off: u32| omclog::g(read_f64(e, sim_data + off + i * 8).unwrap_or(0.0), 2, 1);
        let desc = model.zc_desc.get(i as usize).map(String::as_str).unwrap_or_default();
        let (pre, cur) = (g(layout.zc_pre_off), g(layout.zc_off));
        omclog::info(stream, false, &format!("[{}] (pre: {pre}) {cur} = {desc}", i + 1));
    }
    omclog::close(stream);
    Ok(())
}

/// Copy `relations[]` into `relationsPre`. Freezing it before an event-iteration
/// pass keeps held relations fixed while that pass's NLS solve runs.
fn update_relations_pre(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if layout.n_rel == 0 {
        return Ok(());
    }
    let mut buf = vec![0u8; (layout.n_rel * 4) as usize];
    e.read_bytes(sim_data + layout.relations_off, &mut buf)?;
    e.write_bytes(sim_data + layout.relations_pre_off, &buf)
}

/// Evaluate the zero-crossing functions at `time` with the current discrete state,
/// filling `out` with the `n_zc` values (`gout[i] = relation ? 1 : -1`). Held
/// relations (mode 0): only a located event changes discrete state, so the probe
/// must not flip a relation or fire a when-body; the crossing function itself
/// re-evaluates relations regardless of the flag.
fn read_zero_crossings(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout, out: &mut [f64]) -> Result<()> {
    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
    e.call1("functionZeroCrossings", sim_data)?;
    for (i, v) in out.iter_mut().enumerate() {
        *v = read_f64(e, sim_data + layout.zc_off + (i as u32) * 8)?;
    }
    Ok(())
}

/// C's `bisection`: the crossings at `time` off their own equations. A subset, so
/// an assert outside it does not fire on every trial point of the root search.
fn probe_zero_crossings(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout, time: f64, out: &mut [f64]) -> Result<()> {
    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
    write_f64(e, sim_data + TIME_OFF, time)?;
    eval_zc_equations(e, sim_data, layout)?;
    read_zero_crossings(e, sim_data, layout, out)
}

/// C's `updateContinuousSystem` + `saveZeroCrossings`, what `checkForStateEvent`
/// compares against: detection runs off a full evaluation.
fn update_zero_crossings(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout, time: f64, out: &mut [f64]) -> Result<()> {
    // The row re-evaluates this point and reports what it raises; flush anything
    // older so only this pass's violations are dropped below.
    drain_asserts(e, sim_data, omclog::INFO)?;
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;
    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
    write_f64(e, sim_data + TIME_OFF, time)?;
    eval_continuous(e, sim_data, layout)?;
    let _ = e.take_pending_warnings();
    read_zero_crossings(e, sim_data, layout, out)
}

/// Whether any zero-crossing value changed sign between `a` and `b` — i.e. a state
/// event lies in the bracketed interval.
fn zc_crossed(a: &[f64], b: &[f64]) -> bool {
    a.iter().zip(b).any(|(&x, &y)| (x < 0.0) != (y < 0.0))
}

/// Which crossings changed sign — C's `eventLst`.
fn zc_crossed_idx(a: &[f64], b: &[f64]) -> Vec<usize> {
    a.iter().zip(b).enumerate().filter(|(_, (x, y))| (**x < 0.0) != (**y < 0.0)).map(|(i, _)| i).collect()
}

/// Bisect `(t0, t1]` for the earliest zero-crossing, given the values `zc0` at `t0`
/// and a known sign change by `t1`. Holds the discrete state fixed (only `time`
/// varies), as the crossing is a continuous function of time. Returns the located
/// event time; `scratch` is reused for the probe evaluations.
fn locate_zc_root(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    mut t0: f64,
    mut t1: f64,
    zc0: &[f64],
    scratch: &mut [f64],
) -> Result<f64> {
    let tol = t1.abs().max(1.0) * 1e-12;
    while t1 - t0 > tol {
        let tm = 0.5 * (t0 + t1);
        if tm <= t0 || tm >= t1 {
            break;
        }
        probe_zero_crossings(e, sim_data, layout, tm, scratch)?;
        if zc_crossed(zc0, scratch) {
            t1 = tm;
        } else {
            t0 = tm;
        }
    }
    Ok(t1)
}

/// Snapshot of the discrete state — boolean/integer algebraics and held relations
/// — used to detect when an event's discrete update has reached a fixed point.
fn discrete_snapshot(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<Vec<u8>> {
    let mut buf = vec![0u8; ((layout.n_bool_alg() + layout.n_int_alg()) * 4 + layout.n_rel * 4) as usize];
    let (bools, rest) = buf.split_at_mut((layout.n_bool_alg() * 4) as usize);
    let (ints, rels) = rest.split_at_mut((layout.n_int_alg() * 4) as usize);
    e.read_bytes(sim_data + layout.bool_off, bools)?;
    e.read_bytes(sim_data + layout.int_off, ints)?;
    e.read_bytes(sim_data + layout.relations_off, rels)?;
    Ok(buf)
}

/// Run the discrete update to a fixed point: re-evaluate the whole system —
/// `functionODE` (relations in the continuous equations) then `functionAlgebraics`
/// (algebraic relations, edge-detected when-bodies, pre-values) — until the discrete
/// state stops changing. Re-running both each pass lets relations guarding the
/// derivative equations re-settle after a when-body flips a discrete variable or
/// `reinit`s a state; evaluating only the algebraic half leaves those relations at
/// their pre-event value, so two mutually-triggering crossings never reach a
/// consistent set and chatter on the integrator instead. Assumes the event time is
/// already written.
pub(crate) fn iterate_discrete(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    // Each pass freezes `relationsPre = relations` so the NLS in `functionODE` holds
    // this pass's relations, then re-evaluates the continuous system; the discrete
    // state settles across passes. Comparing the snapshot before and after the
    // evaluation lets an already-settled system stop after a single evaluation.
    let max = max_event_iter();
    let mut iter = 0usize;
    loop {
        let prev = discrete_snapshot(e, sim_data, layout)?;
        // C's `updateDiscreteSystem` `storePreValues`: make this pass's discrete
        // values visible as `pre()` to the next (e.g. a clutch's `pre(mode)`).
        if iter > 0 {
            seed_pre_from_live(e, sim_data, layout)?;
        }
        update_relations_pre(e, sim_data, layout)?;
        eval_discrete(e, sim_data, layout)?;
        if discrete_snapshot(e, sim_data, layout)? == prev {
            return Ok(());
        }
        iter += 1;
        if iter > max {
            omclog::message_text(
                omclog::DEBUG_TYPE,
                omclog::ASSERT,
                false,
                &format!(
                    "Simulation terminated due to too many, i.e. {max}, event iterations.\n                     This could either indicate an inconsistent system or an undersized limit of                      event iterations.\nThe limit of event iterations can be specified using the                      runtime flag '\u{2013}mei=<value>'."
                ),
            );
            return Err(ASSERT_ERR);
        }
    }
}

/// Per-sample time-event state: each sample's next firing time and its interval,
/// loaded from the sample region (populated by the model's `initSample`). The
/// driver interleaves these events with the integration — at a firing time it
/// raises the sample's `active` flag, runs the discrete update, and advances the
/// next time by the interval (C's `samplesInfo` + `nextSampleEvent`).
pub struct Samples {
    /// Next firing time per sample (starts at the sample's `start`).
    next: Vec<f64>,
    /// C's `samplesInfo[i].start`, kept for the `LOG_EVENTS` time-event line.
    start: Vec<f64>,
    interval: Vec<f64>,
    /// Absolute address of the `active` flag array (`sim_data + sample_active_off`).
    active_off: u32,
    /// Which model call a firing evaluates (see [`eval_discrete`]).
    dae: bool,
}

impl Samples {
    /// Read the start/interval pairs `initSample` wrote into the sample region.
    pub fn load(
        e: &dyn SimEngine,
        sim_data: u32,
        layout: &SimLayout,
        start_time: f64,
    ) -> Result<Self> {
        let n = layout.n_samples as usize;
        let mut start = Vec::with_capacity(n);
        let mut next = Vec::with_capacity(n);
        let mut interval = Vec::with_capacity(n);
        for k in 0..n as u32 {
            let base = sim_data + layout.sample_off + k * 16;
            let s = read_f64(e, base)?;
            let iv = read_f64(e, base + 8)?;
            start.push(s);
            next.push(if start_time < s || iv <= 0.0 {
                s
            } else {
                s + libm::ceil((start_time - s) / iv) * iv
            });
            interval.push(iv);
        }
        Ok(Samples {
            start,
            next,
            interval,
            active_off: sim_data + layout.sample_active_off,
            dae: layout.dae_mode(),
        })
    }

    /// The samples due at `t` as `(k, start, interval)`, C's `handleEvents`
    /// `LOG_EVENTS` line.
    pub fn due(&self, t: f64) -> impl Iterator<Item = (usize, f64, f64)> + '_ {
        let eps = t.abs().max(1.0) * 1e-10;
        (0..self.next.len())
            .filter(move |&k| self.next[k] <= t + eps)
            .map(move |k| (k, self.start[k], self.interval[k]))
    }

    /// Time of the next sample event (min of `next`), or +inf if there are none.
    pub fn next_time(&self) -> f64 {
        self.next.iter().copied().fold(f64::INFINITY, f64::min)
    }

    /// Fire every sample due at `t`: raise its `active` flag, run the discrete
    /// update (`functionAlgebraics` — evaluates the sample conditions, the
    /// when-bodies on their rising edge, and saves pre-values), then clear the
    /// flags and advance the fired samples by their interval. `t` is written as
    /// the current simulation time first.
    pub fn fire(&mut self, e: &mut dyn SimEngine, sim_data: u32, t: f64) -> Result<()> {
        rethrow_store::note_event();
        let eps = t.abs().max(1.0) * 1e-10;
        let mut fired = vec![false; self.next.len()];
        for k in 0..self.next.len() {
            if self.next[k] <= t + eps {
                fired[k] = true;
                write_i32(e, self.active_off + k as u32 * 4, 1)?;
            }
        }
        write_f64(e, sim_data + TIME_OFF, t)?;
        if self.dae {
            e.call2(MODEL_FN_DAE, sim_data, eval_stage::DISCRETE)?;
        } else {
            e.call1("functionAlgebraics", sim_data)?;
        }
        for k in 0..self.next.len() {
            if fired[k] {
                write_i32(e, self.active_off + k as u32 * 4, 0)?;
                // Advance to the next firing; a non-positive interval is a
                // one-shot event (guard against a never-advancing schedule).
                self.next[k] = if self.interval[k] > 0.0 {
                    self.next[k] + self.interval[k]
                } else {
                    f64::INFINITY
                };
            }
        }
        Ok(())
    }
}

/// C's `handleEvents` time-event half plus `updateDiscreteSystem`, which C runs at
/// a time event exactly as at a state event.
fn fire_time_event(
    e: &mut dyn SimEngine,
    samples: &mut Samples,
    sim_data: u32,
    layout: &SimLayout,
    te: f64,
) -> Result<()> {
    write_f64(e, sim_data + TIME_OFF, te)?;
    write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
    refresh_relations(e, sim_data, layout)?;
    samples.fire(e, sim_data, te)?;
    iterate_discrete(e, sim_data, layout)?;
    store_relations(e, sim_data, layout)
}

/// The clock half of C's `simulationUpdate`: fire every timer due at `time`,
/// running the discrete update in between whenever one asks for an event, until
/// nothing more fires. `SimData` must already hold the state at `time` — a tick
/// emits its result row *before* evaluating its partition. Returns whether any
/// ticked, which makes the caller restart the integrator (`hold()` may have moved).
fn fire_clocks(
    e: &mut dyn SimEngine,
    sync: &mut crate::sync::Sync,
    model: &SimModel,
    sim_data: u32,
    time: f64,
    eps: f64,
    mut rows: Option<&mut Vec<f64>>,
) -> Result<bool> {
    use crate::sync::Fired;
    if sync.is_empty() {
        return Ok(false);
    }
    let layout = &model.layout;
    let mut any = false;
    let mut did_event = false;
    for _ in 0..MAX_EVENT_ITER {
        sync.take_fired(e, time)?;
        write_f64(e, sim_data + TIME_OFF, time)?;
        let fired = sync.handle_timers(e, time, eps, rows.as_deref_mut())?;
        if fired == Fired::None {
            break;
        }
        any = true;
        rethrow_store::note_event();
        did_event |= fired == Fired::Event;
        if fired == Fired::Event {
            // C's pre-event row: after the partition ran, unlike the tick's own row.
            if let Some(r) = rows.as_deref_mut()
                && !no_event_emit()
            {
                capture_row(e, r, sim_data, layout)?;
            }
            write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
            iterate_discrete(e, sim_data, layout)?;
            store_relations(e, sim_data, layout)?;
        }
        seed_pre_from_live(e, sim_data, layout)?;
    }
    if any {
        // C: "Update continous system because hold() needs to be re-evaluated".
        write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
        eval_continuous(e, sim_data, layout)?;
        // C truncates the step to the activation time, so its output row lands here.
        if let Some(r) = rows
            && (!did_event || emit_post_event_row(model, time))
        {
            capture_row(e, r, sim_data, layout)?;
        }
    }
    Ok(any)
}

/// C's `handleTimersFMI`: the clock half of the event update for a host that owns
/// the integration (`fmi2NewDiscreteStates`), so no output rows. Reports whether
/// any clock ticked.
pub fn fmi_handle_timers(
    e: &mut dyn SimEngine,
    sync: &mut crate::sync::Sync,
    model: &SimMeta,
    sim_data: u32,
    time: f64,
) -> Result<bool> {
    fire_clocks(e, sync, model, sim_data, time, time.abs().max(1.0) * 1e-10, None)
}

/// Output point `row` of the equidistant grid, as C's `perform_simulation`
/// computes it: `row*(stop-start)/numSteps + start`, *not* `start + row*h` —
/// the two round differently and the result files must agree bit for bit.
fn grid_time(row: u32, start: f64, stop: f64, n_steps: u32) -> f64 {
    if n_steps == 0 { start } else { row as f64 * (stop - start) / n_steps as f64 + start }
}

/// Outcome of one [`event_update`] pass.
pub struct EventUpdate {
    /// A `reinit` moved a continuous state, so the integrator must re-read them.
    pub states_changed: bool,
    pub terminate: bool,
    /// Time of the next sample event, or `None` if none is scheduled.
    pub next_event_time: Option<f64>,
}

/// The discrete update at an already-located event, for hosts that own the
/// integration and the root-finding (FMI `update-discrete-states`). The
/// `EventsDriver` inlines this same sequence around its row bookkeeping.
/// A sample due at `time` is a time event, otherwise it is a state event.
pub fn event_update(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    samples: Option<&mut Samples>,
    time: f64,
) -> Result<EventUpdate> {
    rethrow_store::note_event();
    let n_states = layout.n_states as usize;
    let states_base = sim_data + REAL_OFF;
    let mut before = vec![0.0f64; n_states];
    for (i, v) in before.iter_mut().enumerate() {
        *v = read_f64(e, states_base + (i as u32) * 8)?;
    }

    write_f64(e, sim_data + TIME_OFF, time)?;
    write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;

    let eps = time.abs().max(1.0) * 1e-10;
    let mut samples = samples;
    let time_event = samples.as_ref().is_some_and(|s| s.next_time() <= time + eps);
    if time_event {
        if let Some(s) = samples.as_deref_mut() {
            fire_time_event(e, s, sim_data, layout, time)?;
        }
    } else {
        // `pre(x)` of a continuous variable must be its value at the crossing.
        save_pre_real(e, sim_data, layout)?;
        refresh_relations(e, sim_data, layout)?;
        iterate_discrete(e, sim_data, layout)?;
        store_relations(e, sim_data, layout)?;
        check_nls(e, sim_data, layout)?;
        // A reinit changes the state the derivatives are computed from.
        eval_ode(e, sim_data, layout)?;
    }

    let mut states_changed = false;
    for (i, b) in before.iter().enumerate() {
        if read_f64(e, states_base + (i as u32) * 8)? != *b {
            states_changed = true;
            break;
        }
    }

    e.clean_nls_history(time);
    save_old_real(e, sim_data, layout)?;

    let next = samples.as_ref().map(|s| s.next_time()).filter(|t| t.is_finite());
    Ok(EventUpdate { states_changed, terminate: terminated(e, sim_data, layout)?, next_event_time: next })
}

/// Set the zero-crossing hysteresis band from the solver tolerance. Every driver
/// must do this before the first `functionZeroCrossings`: a 0 band re-triggers an
/// indicator left sitting on the crossing by an event.
pub fn set_zc_tolerance(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    tolerance: f64,
) -> Result<()> {
    let rtol = if tolerance > 0.0 { tolerance } else { 1e-6 };
    write_f64(e, sim_data + layout.zctol_off, 1e-4 * rtol.max(1e-12))
}

/// Build the resumable driver (init + row 0 + the zero-crossing band); shared by
/// [`drive`] and the session. `method` empty = DASSL.
/// `-s=` wins over the method compiled into the model's metadata. `cvode`/`ida`
/// without `cfg(sundials)` never reach here — `simflags::check` rejects them at
/// startup rather than let them silently run as DASSL.
pub(crate) fn effective_method<'a>(method: &'a str) -> &'a str {
    match crate::simflags::with_flags(|f| f.solver) {
        Some(crate::simflags::Solver::Euler) => "euler",
        Some(crate::simflags::Solver::Dassl) => "dassl",
        Some(crate::simflags::Solver::Cvode) => "cvode",
        Some(crate::simflags::Solver::Ida) => "ida",
        Some(crate::simflags::Solver::Gbode) => "gbode",
        Some(crate::simflags::Solver::RungeKutta) => "rungekutta",
        Some(crate::simflags::Solver::SymSolver) => "symSolver",
        Some(crate::simflags::Solver::SymSolverSsc) => "symSolverSsc",
        Some(crate::simflags::Solver::Qss) => "qss",
        Some(crate::simflags::Solver::Optimization) => "optimization",
        _ => method,
    }
}

/// Whether this build's `SolverCore` can serve `method`. `dassljac` is dassl
/// with a symbolic Jacobian and `""` the dassl default.
fn check_method(method: &str) -> bool {
    matches!(method, "dassl" | "dasslrt" | "dassljac" | "euler" | "rungekutta" | "gbode" | "qss" | "")
        || (matches!(method, "cvode" | "ida") && cfg!(sundials))
        // `optimize()`; `drive` handles it before the integrators, and reports
        // C's "Ipopt is needed but not available." when it was not linked.
        || method == "optimization"
}

/// Resolve the solver method: apply `-s=`, then default DAE-mode models to IDA
/// (matching C's `simulation_runtime.cpp` solver override), then validate.
fn resolve_solver_method<'a>(method: &'a str, dae_mode: bool) -> Result<&'a str> {
    let method = effective_method(method);
    // C: if the model is compiled in daeMode, overwrite the solver to IDA
    let method = if dae_mode && method != "ida" {
        omclog::info(
            omclog::SIMULATION,
            false,
            "overwrite solver method: ida [DAEmode works only with IDA solver]",
        );
        "ida"
    } else {
        method
    };
    if !check_method(method) {
        return Err(UNSUPPORTED_METHOD);
    }
    Ok(method)
}

/// C allocates the solver before initializing the model, and gbode logs its setup
/// there, so it is built outside the driver.
fn alloc_gbode(
    model: &SimModel,
    method: &str,
) -> Result<Option<alloc::boxed::Box<crate::gbode::Gbode>>> {
    if method != "gbode" {
        return Ok(None);
    }
    let layout = &model.layout;
    let colors = model.jac_a.as_ref().map_or(0, |j| j.colors.len());
    let tol = if model.tolerance > 0.0 { model.tolerance } else { 1e-6 };
    let gb =
        crate::gbode::Gbode::new(layout.n_states as usize, tol, layout.n_zc as usize, colors)
            .map_err(leak_error)?;
    Ok(Some(alloc::boxed::Box::new(gb)))
}

pub fn make_driver(
    e: &mut (dyn SimEngine + 'static),
    model: &SimModel,
    sim_data: u32,
    method: &str,
) -> Result<(Box<dyn Driver>, &'static str)> {
    let layout = &model.layout;
    let method = resolve_solver_method(method, layout.dae_mode())?;
    // Both `drive` and the in-wasm `rt_sim_start` build their driver here.
    arm_alarm();
    // C warns about a deprecated `-s=` while it resolves the flag, before it
    // allocates the solver or initializes the model.
    crate::fixedstep::deprecation_warning(method);
    // `dassl_initial`'s flag warnings, before initialization as in C.
    let (freq, out_time) =
        crate::simflags::with_flags(|f| (f.no_equidistant_freq, f.no_equidistant_time));
    if freq.is_some() && out_time.is_some() && no_equidistant_grid() {
        omclog::warning(
            omclog::STDOUT,
            false,
            "The flags are  \"noEquidistantOutputFrequency\" and \"noEquidistantOutputTime\" \
             are in opposition to each other. The flag \"noEquidistantOutputFrequency\" superiors.",
        );
    }
    // C's `initializeNonlinearSystems`.
    omclog::info(omclog::NLS, true, "initialize non-linear system solvers");
    omclog::info(
        omclog::NLS,
        false,
        &format!("{} non-linear systems", model.nls_vars.len()),
    );
    omclog::close(omclog::NLS);
    set_zc_tolerance(e, sim_data, layout, model.tolerance.min(model.step_size()))?;
    for k in 0..layout.n_sens {
        write_f64(e, sim_data + layout.sens_off + k * 8, 0.0)?;
    }
    let gbode = alloc_gbode(model, method)?;

    // C's `setJacobianMethod` reports INTERNALNUMJAC in DAE mode (no symbolic `A` is
    // generated) and announces the colored-FD fallback. C configures IDA before
    // `initializeModel`, so this precedes the initialization messages.
    #[cfg(sundials)]
    if layout.dae_mode() && ida_linear_solver(layout) == crate::sundials::IdaLs::Klu {
        omclog::warning(
            omclog::STDOUT,
            false,
            "Internal Numerical Jacobians without coloring are currently not supported by IDA with KLU. \
             Colored numerical Jacobian will be used.",
        );
    }
    // C's `solver_main` runs QSS from its own branch: it has no event handling and
    // no output grid, so it never reaches the standard solver interface. With no
    // states there is nothing to quantize, and C's `simulation_runtime.cpp` has
    // already swapped in euler ("since it does nothing").
    let mut method = method;
    if method == "qss" {
        if layout.n_states > 0 {
            return Ok((Box::new(crate::qss::Qss::new(e, model, sim_data)?), "qss"));
        }
        omclog::info(omclog::SOLVER, false, "No states present, continuing without ODE solver.");
        method = "euler";
    }
    // DAE mode always takes the `SolverCore` path: the consistent-restart its
    // discrete update needs lives there.
    // A clocked partition is an event source too, and only `EventsDriver` has the
    // timer list and the consistent restart a tick needs.
    let events = layout.n_samples > 0 || layout.n_zc > 0 || !model.clocks.is_empty();
    if events || method == "gbode" || layout.dae_mode() {
        let label = match method {
            "cvode" => "cvode-events",
            "ida" if events => "ida-events",
            "ida" => "ida",
            "gbode" => "gbode",
            _ => "dassl-events",
        };
        return Ok((Box::new(EventsDriver::new(e, model, sim_data, method, gbode)?), label));
    }
    match method {
        "dassl" | "dasslrt" | "dassljac" | "" => Ok((Box::new(DasslDriver::new(e, model, sim_data)?), "dassl")),
        // Uniform host-driven Euler so it is resumable/cancellable like DASSL.
        "euler" => Ok((Box::new(EulerDriver::new(e, model, sim_data)?), "euler-host")),
        "rungekutta" => {
            Ok((Box::new(EventsDriver::new(e, model, sim_data, method, None)?), "rungekutta"))
        }
        #[cfg(sundials)]
        "cvode" => Ok((Box::new(CvodeDriver::new(e, model, sim_data)?), "cvode")),
        #[cfg(sundials)]
        "ida" => Ok((Box::new(IdaDriver::new(e, model, sim_data)?), "ida")),
        _ => Err(UNSUPPORTED_METHOD),
    }
}

/// Listing what `make_driver` accepts; `simflags::check` rejects the rest earlier,
/// so this is only reached by a `method=` the model was compiled with.
const UNSUPPORTED_METHOD: &str = if cfg!(sundials) {
    "CodegenWasmJit: unsupported integration method (supported: `dassl`, `cvode`, `ida`, `gbode`, \
     `euler`, `rungekutta`, `qss`)"
} else {
    "CodegenWasmJit: unsupported integration method (supported: `dassl`, `gbode`, `euler`, \
     `rungekutta`, `qss`)"
};

/// Free external objects (so repeated runs don't leak) and read back parameter
/// values (result `Param` order) after a run.
pub fn finalize_run(e: &mut dyn SimEngine, model: &SimModel, sim_data: u32) -> Result<Vec<f64>> {
    if let Some(tol) = crate::simflags::with_flags(crate::simflags::steady_state_tol)
        && !steady_report::hit()
    {
        omclog::warning(
            omclog::STDOUT,
            false,
            &format!(
                "Steady state has not been reached.\nThis may be due to too restrictive relative \
                 tolerance ({}) or short stopTime ({}).",
                format_g(tol, 6),
                format_g(model.stop_time, 6),
            ),
        );
    }
    signal_teardown();
    e.call1_if_present("callExternalObjectDestructors", sim_data)?;
    let mut params = Vec::new();
    for v in &model.vars {
        if let ResultKind::Param { off, wty, .. } = &v.kind {
            let val = match wty {
                WTy::F64 => read_f64(e, sim_data + off)?,
                WTy::I32 => read_i32(e, sim_data + off)? as f64,
            };
            params.push(val);
        }
    }
    Ok(params)
}

/// Select the integrator and run it to completion, then finalize — the
/// non-resumable one-shot path (native CLI and any caller that does not need
/// cancellation). `host_driven` forces the resumable host Euler over the fast
/// in-wasm one for `method="euler"`.
pub fn drive(
    e: &mut (dyn SimEngine + 'static),
    model: &SimModel,
    sim_data: u32,
    method: &str,
    host_driven: bool,
    bench: bool,
) -> Result<(RunResult, &'static str)> {
    // The host clears any stale cancel request before entering the driver (it owns
    // the cancel flag; the driver only polls it via the installed hook).
    let layout = &model.layout;
    let n_reals = layout.n_row_total();
    let n_rows = model.n_output_rows();
    let start = model.start_time;
    let stop = model.stop_time;

    let mut stats = SolveStats::default();
    let use_events = layout.n_samples > 0 || layout.n_zc > 0 || !model.clocks.is_empty();
    let method = resolve_solver_method(method, layout.dae_mode())?;

    let mut label = "";
    let outcome = (|| -> Result<Vec<f64>> {
        // `optimize()`: C's `solver_main` initializes the model, then the loop makes a
        // single `S_OPTIMIZATION` step and breaks — every result row comes from the
        // optimizer's own `res2file`, and neither the initial nor the terminal row is
        // emitted around it.
        if method == "optimization" {
            // C's `solver_main_step`: with neither a state nor an input there is
            // nothing to optimize, and it runs explicit Euler instead.
            let nothing_to_optimize =
                layout.n_states == 0 && model.opt.as_ref().is_none_or(|o| o.inputs.is_empty());
            if nothing_to_optimize {
                label = "euler-host";
                let (mut driver, _) = make_driver(e, model, sim_data, "euler")
                    .map_err(|err| enrich_trap_init(e, err, model.start_time))?;
                loop {
                    match driver.advance(e, model, f64::INFINITY).map_err(|err| enrich_trap(e, err))? {
                        Advance::Done | Advance::Terminated => break,
                        Advance::Cancelled => return Err("CodegenWasmJit: simulation cancelled"),
                        Advance::Running => continue,
                    }
                }
                driver.fill_stats(model, &mut stats);
                let mut rows = driver.take_rows();
                emit_terminal_row(e, &mut rows, sim_data, layout, n_reals, driver.terminal_time())?;
                return Ok(rows);
            }
            label = "optimization";
            if !crate::optimization::AVAILABLE {
                omclog::warning(omclog::STDOUT, false, crate::optimization::UNAVAILABLE);
                return Err(crate::optimization::UNAVAILABLE);
            }
            #[cfg(all(ipopt, feature = "std"))]
            {
                run_initialization_model(e, sim_data, model)
                    .map_err(|err| enrich_trap_init(e, err, start))?;
                return crate::optimization::run_optimizer(e, model, sim_data)
                    .map_err(|err| enrich_trap(e, err));
            }
            #[cfg(not(all(ipopt, feature = "std")))]
            unreachable!("optimization::AVAILABLE is false");
        }
        if !use_events && method == "euler" && !host_driven {
            // Fast in-wasm Euler (one host->wasm call; not resumable/cancellable).
            label = "euler-wasm";
            set_zc_tolerance(e, sim_data, layout, model.tolerance.min(model.step_size()))?;
            let mut rows = run_wasm(e, sim_data, n_reals, n_rows, model, start, stop, &mut stats)?;
            emit_terminal_row(e, &mut rows, sim_data, layout, n_reals, None)?;
            return Ok(rows);
        }
        // enrich_trap: a trap in init/integration is usually a failed model assert().
        let (mut driver, l) =
            make_driver(e, model, sim_data, method).map_err(|err| enrich_trap_init(e, err, model.start_time))?;
        label = l;
        // Infinite budget runs to completion; the per-step cancel poll still lets a
        // native embedder interrupt. `OMC_WASM_SIM_YIELD_MS` forces a finite budget to
        // self-test yield/resume (must be `.mat`-identical to the un-yielded run).
        let budget_ms = env_var("OMC_WASM_SIM_YIELD_MS")
            .and_then(|v| v.parse::<f64>().ok())
            .unwrap_or(f64::INFINITY);
        loop {
            match driver.advance(e, model, budget_ms).map_err(|err| enrich_trap(e, err))? {
                Advance::Done | Advance::Terminated => break,
                Advance::Cancelled => return Err("CodegenWasmJit: simulation cancelled"),
                Advance::Running => continue,
            }
        }
        driver.fill_stats(model, &mut stats);
        let mut rows = driver.take_rows();
        emit_terminal_row(e, &mut rows, sim_data, layout, n_reals, driver.terminal_time())?;
        Ok(rows)
    })();
    let _ = bench;
    // Before `outcome?`: a failed run is when the counters matter most.
    #[cfg(feature = "std")]
    if bench {
        eprintln!(
            "wasm-jit sim [{label}]: {} steps, {} residual evals, {} jacobian evals",
            stats.steps, stats.res_evals, stats.jac_evals
        );
        let counters = e.rt_stats();
        if counters.iter().any(|&c| c != 0) {
            let line: Vec<String> =
                RT_STAT_NAMES.iter().zip(counters.iter()).map(|(n, c)| format!("{n}={c}")).collect();
            eprintln!("wasm-jit sim [{label}]: {}", line.join(" "));
        }
    }
    let rows = outcome?;
    stats.method = label;

    // C's `finishSimulation` order: this line, then the caller's LOG_STATS block.
    let out_names = crate::simflags::with_flags(|f| f.output_vars.clone());
    if !out_names.is_empty() {
        write_output_vars(e, model, sim_data, &rows, n_reals as usize, &out_names)?;
    }

    let lin = crate::linearize::linearize(e, model, sim_data)?;
    let params = finalize_run(e, model, sim_data)?;
    Ok((RunResult { rows, n_reals, params, stats, lin }, label))
}

/// In-wasm driver: initialize here (so the run initializes like every other
/// driver, and the host sees the init/simulation boundary), then one call to
/// `simulate` for the integration loop, then read the result buffer. C's
/// `noThrowAsserts` phase stays open across the loop — Euler locates no event that
/// could excuse a violation before the settle below.
fn run_wasm(
    e: &mut dyn SimEngine,
    sim_data: u32,
    n_reals: u32,
    n_rows: u32,
    model: &SimModel,
    start: f64,
    stop: f64,
    stats: &mut SolveStats,
) -> Result<Vec<f64>> {
    let layout = &model.layout;
    stats.steps = (n_rows - 1) as u64;
    run_initialization_model(e, sim_data, model)
        .map_err(|err| enrich_trap_init(e, err, start))?;
    open_assert_window();
    let called = e.call_simulate(sim_data, start, stop, n_rows - 1);
    let settled = close_assert_window(e, sim_data);
    // A trap says what went wrong; the settle only fails on a suppressed assert.
    let buf = called.map_err(|err| enrich_trap(e, err))?;
    settled?;
    terminated(e, sim_data, layout)?; // C's `checkSimulationTerminated` notice
    // The Euler loop cannot back off, so a non-converging NLS is fatal here.
    check_nls(e, sim_data, layout)?;
    // The loop records how many rows it wrote (< n_rows if terminate() fired).
    let written = read_i32(e, sim_data + layout.n_out_off)?.max(0) as u32;
    let count = (written.min(n_rows) * n_reals) as usize;
    let mut bytes = vec![0u8; count * 8];
    e.read_bytes(buf, &mut bytes)?;
    Ok(bytes.chunks_exact(8).map(|c| f64::from_le_bytes(c.try_into().unwrap())).collect())
}

/// Host-driven forward-Euler driver (resumable). Emits output rows `0..=n_steps`
/// on the equidistant grid, one Euler update between rows.
struct EulerDriver {
    sim_data: u32,
    /// Next output row to produce (0-based).
    row: u32,
    pivots: Vec<StateSetPivot>,
    rows: Vec<f64>,
}

impl EulerDriver {
    fn new(e: &mut dyn SimEngine, model: &SimModel, sim_data: u32) -> Result<Self> {
        // Init (with homotopy fallback). No state events on this path, so relations
        // stay fresh (mode 2, set by run_initialization); `rt_solve_nls` still holds
        // them internally around its Newton solve.
        run_initialization_model(e, sim_data, model)?;
        let n_rows = model.n_output_rows();
        let n_reals = model.layout.n_row_total();
        Ok(EulerDriver {
            sim_data,
            row: 0,
            pivots: init_state_pivots(&model.state_sets),
            rows: Vec::with_capacity((n_rows * n_reals) as usize),
        })
    }
}

impl Driver for EulerDriver {
    fn advance(&mut self, e: &mut (dyn SimEngine + 'static), model: &SimModel, budget_ms: f64) -> Result<Advance> {
        let layout = &model.layout;
        let sim_data = self.sim_data;
        let n_states = layout.n_states;
        let n_rows = model.n_output_rows();
        let n_steps = n_rows - 1;
        let start = model.start_time;
        let stop = model.stop_time;
        let grid = |row: u32| grid_time(row, start, stop, n_steps);
        let states_base = sim_data + REAL_OFF;
        let ders_base = states_base + n_states * 8;

        let deadline = deadline_from(budget_ms);
        let mut did_step = false;
        while self.row < n_rows {
            if did_step && past_deadline(deadline) {
                return Ok(Advance::Running);
            }
            check_alarm()?;
            if cancel_requested() {
                return Ok(Advance::Cancelled);
            }
            did_step = true;
            // The last row lands exactly on `stop`: the terminal step.
            let time = if self.row == n_steps { stop } else { grid(self.row) };
            // Euler locates no events, so a suppressed assert always throws; the
            // window is what gets it reported like C's.
            open_assert_window();
            let emitted = if self.row == 0 {
                emit_initial_row(e, &mut self.rows, sim_data, layout, time)
            } else {
                emit_row(e, &mut self.rows, sim_data, layout, time, stop)
            };
            close_assert_window(e, sim_data).and(emitted)?;
            store_operators(e, sim_data, layout)?;
            check_nls(e, sim_data, layout)?; // Euler cannot back off — non-convergence is fatal
            // terminate() fired in functionAlgebraics: keep this row, stop the run.
            if terminated(e, sim_data, layout)? {
                self.row = n_rows;
                return Ok(Advance::Terminated);
            }
            if self.row == n_steps {
                self.row = n_rows;
                return Ok(Advance::Done);
            }
            // Re-select states before the Euler update; a switch reinits the states,
            // so refresh the derivatives it uses (see `DasslDriver`).
            if !model.state_sets.is_empty() {
                let sets = &model.state_sets;
                let changed = if self.row == 0 {
                    run_state_selection_initial(e, sim_data, sets, &mut self.pivots)?
                } else {
                    run_state_selection(e, sim_data, sets, &mut self.pivots)?
                };
                if changed {
                    e.call1("functionODE", sim_data)?;
                }
            }
            // Forward-Euler update of the states, over this row's own step.
            let h = grid(self.row + 1) - grid(self.row);
            for i in 0..n_states {
                let s = read_f64(e, states_base + i * 8)?;
                let d = read_f64(e, ders_base + i * 8)?;
                write_f64(e, states_base + i * 8, s + h * d)?;
            }
            self.row += 1;
        }
        Ok(Advance::Done)
    }

    fn take_rows(&mut self) -> Vec<f64> {
        core::mem::take(&mut self.rows)
    }

    fn fill_stats(&mut self, model: &SimModel, stats: &mut SolveStats) {
        stats.steps = (model.n_output_rows() - 1) as u64;
    }
}

// ===========================================================================
// DASSL (daskr) driver
// ===========================================================================
//
// The model is an explicit ODE `der(y) = f(t, y)` (the wasm `functionODE`
// computes `f` into the derivative slots given `time` + state slots). DASSL
// solves the equivalent DAE residual `G(t, y, y') = y' - f(t, y) = 0` with its
// numerical Jacobian, choosing internal steps adaptively and interpolating back
// to each output point. `daskr`'s `RES` callback is a bare `unsafe fn` (Fortran
// calling convention) that cannot capture, so the wasm context is passed through
// a thread-local raw pointer set for the duration of the integration
// (single-threaded; `RES` only runs nested inside `ddaskr`).

/// Context the `RES` callback needs to evaluate `f(t, y)` through wasm. `engine`
/// is a type-erased pointer to the backend (valid only while `ddaskr` runs).
struct ResCtx {
    engine: *mut dyn SimEngine,
    sim_data: u32,
    states_base: u32,
    ders_base: u32,
    n_states: usize,
    /// `SimData` offset of the nonlinear-solve failure flag.
    nls_fail_off: u32,
    /// Number of residual (right-hand-side) evaluations, for the bench line.
    nfe: u64,
    /// `SimData` offset of the zero-crossing value region (for the root callback).
    zc_off: u32,
    /// Number of zero-crossings (root functions).
    n_zc: usize,
    /// A wasm trap / memory error captured inside the callback, surfaced after
    /// `ddaskr` returns (the C-style callback cannot return a `Result`).
    err: Option<&'static str>,
    /// ODE Jacobian sparsity+coloring for the colored-FD `jacd`; null ⇒ the
    /// analytic path is off and daskr's own numerical Jacobian is used.
    jac: *const JacAInfo,
    /// Scratch reused across `dassl_jac` colors (sized by the unknown count):
    /// perturbed residual, saved states, reciprocal steps, and the der read buffer.
    jac_gp: Vec<f64>,
    jac_ysave: Vec<f64>,
    jac_del: Vec<f64>,
    jac_ders: Vec<u8>,
    /// DAE mode: the saved `y'` the Jacobian perturbs alongside `y`.
    jac_ypsave: Vec<f64>,
    /// Jacobian evaluations (colors summed over all Jacobian assemblies).
    nje: u64,
    /// `-csvInput` for the optimizer's initial guess: C's `functionODE_residual`
    /// re-reads the external input at *every* residual evaluation, so the hook is
    /// applied here rather than only at the step boundaries. Null when there is none;
    /// type-erased so the optimization module's types stay out of the driver.
    ext_input: *mut core::ffi::c_void,
    ext_apply: Option<unsafe fn(*mut core::ffi::c_void, &mut dyn SimEngine, u32, f64)>,
    /// Linear-memory address of the runtime's evaluation context (0 = unsupported).
    ctx_addr: u32,
    /// Linear-memory address of the runtime's error stage (0 = unsupported).
    err_stage_addr: u32,
    /// The FD step's fallback scale: `n_states` nominals owned by the driver.
    nominals: *const f64,
    nominal_factor: f64,
    /// Relative tolerance; with `nominals` it gives the first step's floor.
    tol: f64,
    /// What IDA's Jacobian callback needs on top of the above; all-null otherwise.
    #[cfg(sundials)]
    ida: IdaCtx,
}

/// `-idaSensitivity`: the parameters IDAS perturbs to difference `dF/dp`. The
/// residual pushes `values` into `offs` and re-evaluates the dependent
/// parameters, which is the only way a perturbation reaches the model (C's
/// `updateBoundParameters` call in `residualFunctionIDA`).
#[cfg(sundials)]
#[derive(Clone, Copy)]
struct SensPush {
    offs: *const u32,
    values: *const f64,
    n: usize,
}

#[cfg(sundials)]
impl Default for SensPush {
    fn default() -> Self {
        SensPush { offs: core::ptr::null(), values: core::ptr::null(), n: 0 }
    }
}

/// The IDA memory block (for the step size the difference quotient scales by)
/// and the CSC layout its sparse Jacobian is filled in, both owned by the driver
/// and outliving the `ResCtx` that points at them.
#[cfg(sundials)]
#[derive(Clone, Copy)]
struct IdaCtx {
    mem: *mut core::ffi::c_void,
    pattern: *const IdaPattern,
    sens: SensPush,
    /// `--daeMode` only; null for an explicit ODE.
    dae: *const DaeSolve,
}

#[cfg(sundials)]
impl Default for IdaCtx {
    fn default() -> Self {
        IdaCtx {
            mem: core::ptr::null_mut(),
            pattern: core::ptr::null(),
            sens: SensPush::default(),
            dae: core::ptr::null(),
        }
    }
}

/// DASKR root (constraint) function: fills `rval[i]` with `g_i(t, y)`, the value
/// whose sign change is a state event. Writes the candidate `t`/`y` into SimData,
/// evaluates the continuous equations (`functionODE`) so any algebraics a
/// crossing depends on are current, then the emitted `functionZeroCrossings`, and
/// reads the results back. Errors are stashed in `ResCtx::err` (the C-style
/// callback cannot return a status).
unsafe fn dassl_rt(
    _neq: *mut i32,
    t: *mut f64,
    y: *mut f64,
    _yprime: *mut f64,
    _nrt: *mut i32,
    rval: *mut f64,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
    let ctx = RES_CTX.load(Ordering::Relaxed);
    if ctx.is_null() {
        return;
    }
    let ctx = unsafe { &mut *ctx };
    let e = unsafe { &mut *ctx.engine };
    let run = (|| -> Result<()> {
        // A root probe may sit at an awkward candidate state where a nonlinear
        // system can't converge; keep that transient failure from leaking into the
        // next checked evaluation by clearing the flag around this probe.
        write_i32(e, ctx.sim_data + ctx.nls_fail_off, 0)?;
        write_f64(e, ctx.sim_data + TIME_OFF, unsafe { *t })?;
        let y_bytes = unsafe { core::slice::from_raw_parts(y as *const u8, ctx.n_states * 8) };
        e.write_bytes(ctx.states_base, y_bytes)?;
        set_context(e, ctx.ctx_addr, CONTEXT_EVENTS);
        e.call1("functionZeroCrossingsEquations", ctx.sim_data)?;
        e.call1("functionZeroCrossings", ctx.sim_data)?;
        set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
        let rval_bytes = unsafe { core::slice::from_raw_parts_mut(rval as *mut u8, ctx.n_zc * 8) };
        e.read_bytes(ctx.sim_data + ctx.zc_off, rval_bytes)?;
        Ok(())
    })();
    if let Err(err) = run {
        ctx.err = Some(err);
    }
}

// Single global (the DASSL residual callback is a bare fn that can't capture);
// sims are serialized per process, and the in-wasm runtime is single-threaded.
static RES_CTX: core::sync::atomic::AtomicPtr<ResCtx> =
    core::sync::atomic::AtomicPtr::new(core::ptr::null_mut());

/// Clears the thread-local `RES_CTX` on drop so a stale pointer never leaks into
/// a later run on the same thread (even if `ddaskr` bails early).
struct ResCtxGuard;
impl Drop for ResCtxGuard {
    fn drop(&mut self) {
        RES_CTX.store(core::ptr::null_mut(), Ordering::Relaxed);
    }
}

/// DASSL residual `G(t, y, y') = y' - f(t, y)`. Writes `t` and the candidate
/// states `y` into `SimData`, calls the wasm `functionODE` to get `f` into the
/// derivative slots, then `delta := y' - f`. A wasm trap sets `IRES = -2`
/// (unrecoverable). A *non-converging nonlinear system* inside `functionODE`
/// (which raises the `nls_fail` flag instead of trapping) sets `IRES = -1`, the
/// recoverable signal that makes DASKR back off to a smaller step and retry from
/// the restored guess — mirroring the C runtime.
unsafe fn dassl_res(
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    _cj: *mut f64,
    delta: *mut f64,
    ires: *mut i32,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
    let ctx = RES_CTX.load(Ordering::Relaxed);
    if ctx.is_null() {
        unsafe { *ires = -2 };
        return;
    }
    let ctx = unsafe { &mut *ctx };
    let e = unsafe { &mut *ctx.engine };
    let n = ctx.n_states;
    let run = (|| -> Result<()> {
        write_i32(e, ctx.sim_data + ctx.nls_fail_off, 0)?; // clear before the solve
        write_f64(e, ctx.sim_data + TIME_OFF, unsafe { *t })?;
        if let Some(f) = ctx.ext_apply {
            unsafe { f(ctx.ext_input, e, ctx.sim_data, *t) };
        }
        let y_bytes = unsafe { core::slice::from_raw_parts(y as *const u8, n * 8) };
        e.write_bytes(ctx.states_base, y_bytes)?;
        set_context(e, ctx.ctx_addr, CONTEXT_ODE);
        set_error_stage(e, ctx.err_stage_addr, ERROR_INTEGRATOR);
        e.call1("functionODE", ctx.sim_data)?;
        set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
        // delta := yprime - f
        let delta_bytes = unsafe { core::slice::from_raw_parts_mut(delta as *mut u8, n * 8) };
        e.read_bytes(ctx.ders_base, delta_bytes)?;
        for i in 0..n {
            unsafe { *delta.add(i) = *yprime.add(i) - *delta.add(i) };
        }
        Ok(())
    })();
    let model_error = took_error_stage(e, ctx.err_stage_addr);
    ctx.nfe += 1;
    match run {
        Err(err) => {
            ctx.err = Some(err);
            unsafe { *ires = -2 };
        }
        Ok(()) => {
            // A model error, or a nonlinear system that did not converge: both
            // recoverable — ask DASKR to retry at a smaller step (the guess was
            // restored by the codegen).
            if read_i32(e, ctx.sim_data + ctx.nls_fail_off).unwrap_or(0) != 0 {
                report_nls_failure_at(e, ctx.sim_data, ctx.nls_fail_off);
                unsafe { *ires = -1 };
            } else if model_error {
                unsafe { *ires = -1 };
            }
        }
    }
}

/// DASSL direct-method Jacobian (`INFO(5)=1`, dense `mtype 1`): fill the iteration
/// matrix `∂G/∂y + cj·∂G/∂y'` (G = y' − f) by a colored numerical FD, one
/// `functionODE` per color, mirroring the C runtime's `jacA_numColored`.
///
/// Argument order follows the `dmatd` call site (`jacd(t,y,yprime,delta,wm,…)`),
/// not the misleadingly-named `JacFn` params: `base` is the current residual, `pd`
/// the dense column-major matrix daskr zeroed for us to fill.
unsafe fn dassl_jac(
    t: *mut f64,
    y: *mut f64,
    yprime: *mut f64,
    base: *mut f64,
    pd: *mut f64,
    cj: *mut f64,
    h: *mut f64,
    _wt: *mut f64,
    _rpar: *mut f64,
    _ipar: *mut i32,
) {
    let ctx = RES_CTX.load(Ordering::Relaxed);
    if ctx.is_null() {
        return;
    }
    let ctx = unsafe { &mut *ctx };
    if ctx.jac.is_null() {
        return;
    }
    let jac = unsafe { &*ctx.jac };
    let e = unsafe { &mut *ctx.engine };
    let n = ctx.n_states;
    let cj = unsafe { *cj };
    let h = unsafe { *h };
    ctx.jac_ders.resize(n * 8, 0);
    // One assembly, however many colours it takes, as C's DASSL counts it.
    ctx.nje += 1;
    set_context(e, ctx.ctx_addr, CONTEXT_JACOBIAN);
    // C holds `ERROR_INTEGRATOR` over the whole DDASKR call, and there is no `IRES`
    // here: a model error at a perturbed point leaves the assembly as it stands.
    set_error_stage(e, ctx.err_stage_addr, ERROR_INTEGRATOR);
    let run = (|| -> Result<()> {
        write_f64(e, ctx.sim_data + TIME_OFF, unsafe { *t })?;
        for color in &jac.colors {
            // Perturb every column in this colour; record del and the base value.
            for &col in color {
                let ci = col as usize;
                let yi = unsafe { *y.add(ci) };
                let hyp = h * unsafe { *yprime.add(ci) };
                let nom = unsafe { *ctx.nominals.add(ci) };
                let mut del = fd_step(yi, hyp, ctx.tol, nom, ctx.nominal_factor);
                del = yi + del - yi; // floating-point rounding, as in the C runtime
                if del == 0.0 {
                    del = DELTA_X_SOLVER;
                }
                ctx.jac_ysave[ci] = yi;
                ctx.jac_del[ci] = del;
                unsafe { *y.add(ci) = yi + del };
            }
            // One residual evaluation at the perturbed point.
            write_i32(e, ctx.sim_data + ctx.nls_fail_off, 0)?;
            let y_bytes = unsafe { core::slice::from_raw_parts(y as *const u8, n * 8) };
            e.write_bytes(ctx.states_base, y_bytes)?;
            e.call1("functionODE", ctx.sim_data)?;
            e.read_bytes(ctx.ders_base, &mut ctx.jac_ders)?;
            for row in 0..n {
                let f = f64::from_le_bytes(ctx.jac_ders[row * 8..row * 8 + 8].try_into().unwrap());
                ctx.jac_gp[row] = unsafe { *yprime.add(row) } - f;
            }
            // Scatter the finite difference into the affected rows, restore y.
            for &col in color {
                let ci = col as usize;
                let del = ctx.jac_del[ci];
                for &row in &jac.rows_by_col[ci] {
                    let ri = row as usize;
                    let d = ctx.jac_gp[ri] - unsafe { *base.add(ri) };
                    unsafe { *pd.add(ci * n + ri) = d / del };
                }
                unsafe { *y.add(ci) = ctx.jac_ysave[ci] };
            }
        }
        // cj·∂G/∂y' = cj·I — the diagonal the ∂G/∂y difference above does not carry.
        for col in 0..n {
            unsafe { *pd.add(col * n + col) += cj };
        }
        // Restore the base states in SimData.
        let y_bytes = unsafe { core::slice::from_raw_parts(y as *const u8, n * 8) };
        e.write_bytes(ctx.states_base, y_bytes)?;
        Ok(())
    })();
    set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
    took_error_stage(e, ctx.err_stage_addr);
    if let Err(err) = run {
        ctx.err = Some(err);
    }
}

/// C's `numericalDifferentiationDeltaXsolver`: `sqrt(DBL_EPSILON)` unless
/// `-numericalDifferentiationDeltaXsolver` says otherwise (`simulation_runtime.cpp`).
const DELTA_X_SOLVER: f64 = 1.4901161193847656e-8;

/// Give a step the sign of `h*y'`, as both runtimes do.
fn signed(mag: f64, hyp: f64) -> f64 {
    if hyp >= 0.0 { mag } else { -mag }
}

/// The Jacobian's step for a column, C's `numericalJacobianStep` (`model_help.h`):
/// the relative step, or the nominal where the state is inside its own absolute
/// tolerance and so is no scale of its own to difference over.
fn fd_step(yi: f64, hyp: f64, tol: f64, nominal: f64, factor: f64) -> f64 {
    let scale = yi.abs().max(hyp.abs());
    let ewt_inv = tol * (yi.abs() + nominal);
    let step = if scale > ewt_inv { scale } else { ewt_inv.max(factor * nominal) };
    signed(DELTA_X_SOLVER * step, hyp)
}

/// C's `-noEquidistantTimeGrid` (`dassl.c`'s `dasslSteps`): DASKR's own steps are
/// the output points, not an interpolated equidistant grid.
fn no_equidistant_grid() -> bool {
    crate::simflags::with_flags(|f| f.no_equidistant_grid)
}

/// C's `-noEventEmit`: the rows a step that handled an event produces are dropped.
fn no_event_emit() -> bool {
    crate::simflags::with_flags(|f| f.no_event_emit)
}

/// C's `do_emit`: under `-noEventEmit` a post-event row survives only if the
/// equidistant grid puts an output point on `time`. The left-limit row never does.
fn emit_post_event_row(model: &SimModel, time: f64) -> bool {
    if !no_event_emit() {
        return true;
    }
    if no_equidistant_grid() || model.n_intervals == 0 {
        return false;
    }
    let (start, stop, n) = (model.start_time, model.stop_time, model.n_intervals as f64);
    let step_no = libm::round(n * (time - start) / (stop - start));
    let grid = step_no * (stop - start) / n + start;
    grid == time || libm::fabs(grid - time) / (libm::fabs(grid) + libm::fabs(time)) < 1e-15
}

/// `-maxIntegrationOrder` (INFO(9)/IWORK(3)) and the step-size cap
/// (INFO(7)/RWORK(2)), which `-noEquidistantOutputTime` also sets, as `dassl.c` does.
fn daskr_limits(info: &mut [i32; 24], rwork: &mut [f64], iwork: &mut [i32]) {
    let (order, h_max, out_time) = crate::simflags::with_flags(|f| {
        (f.max_order, f.max_step_size, f.no_equidistant_time)
    });
    if let Some(n) = order {
        info[8] = 1;
        iwork[2] = n;
    }
    if let Some(h) = h_max.or(out_time) {
        info[6] = 1;
        rwork[1] = h;
    }
}

/// `dassl.c`'s `dasslStepsFreq` / `dasslStepsTime`: every n-th step, or the first
/// step past each multiple of `t`. Neither set = every step.
#[derive(Default)]
struct StepEmit {
    freq: Option<u32>,
    time: Option<f64>,
    counter: u32,
}

impl StepEmit {
    fn new() -> Self {
        let (freq, time) =
            crate::simflags::with_flags(|f| (f.no_equidistant_freq, f.no_equidistant_time));
        // C: the frequency wins when both are given; `make_driver` warns.
        StepEmit { freq, time: if freq.is_some() { None } else { time }, counter: 1 }
    }

    fn take(&mut self, t: f64) -> bool {
        match (self.freq, self.time) {
            (Some(n), _) => {
                if self.counter >= n.max(1) {
                    self.counter = 1;
                    return true;
                }
                self.counter += 1;
                false
            }
            (None, Some(dt)) => {
                if t > self.counter as f64 * dt {
                    self.counter += 1;
                    return true;
                }
                false
            }
            _ => true,
        }
    }
}

/// C's `-lv=LOG_DASSL`, printed by `dassl.c` around every `DDASKR` call.
fn log_dassl() -> bool {
    omclog::active(omclog::DASSL)
}

fn log_dassl_step(t: f64) {
    omclog::info(omclog::DASSL, false, &format!("new step at time = {}", format_g(t, 15)));
}

/// The `dassl call statistics:` block, from the work-array indices `dassl.c` reads.
/// A restart zeroes the counters, as in C.
/// C's `continue_DASSL`: name the negative `IDID` DASKR stopped on, then
/// `can't continue`. `-10` is the one [`dassl_res`]'s `IRES = -1` leads to.
fn report_dassl_failure(idid: i32, t: f64) -> &'static str {
    let msg = match idid {
        -2 => "The error tolerances are too stringent",
        -6 => "DDASSL had repeated error test failures on the last attempted step.",
        -7 => "The corrector could not converge.",
        -8 => "The matrix of partial derivatives is singular.",
        -9 => "The corrector could not converge. There were repeated error test failures in this step.",
        -10 => "A Modelica assert prevents the integrator to continue. For more information use -lv LOG_SOLVER",
        -11 => "IRES equal to -2 was encountered and control is being returned to the calling program.",
        -12 => "DDASSL failed to compute the initial YPRIME.",
        -33 => "The code has encountered trouble from which it cannot recover.",
        _ => "",
    };
    if !msg.is_empty() {
        omclog::warning(omclog::STDOUT, false, msg);
    }
    omclog::warning(omclog::STDOUT, false, &format!("can't continue. time = {t:.6}"));
    "CodegenWasmJit: DASSL (daskr) failed"
}

fn log_dassl_stats(idid: i32, t: f64, rwork: &[f64], iwork: &[i32]) {
    let g = |v: f64| format_g(v, 4);
    let r = |k: usize| rwork.get(k).copied().unwrap_or(0.0);
    let i = |k: usize| iwork.get(k).copied().unwrap_or(0);
    omclog::info(omclog::DASSL, true, "dassl call statistics: ");
    for l in [
        format!("value of idid: {idid}"),
        format!("current time value: {}", g(t)),
        format!("current integration time value: {}", g(r(3))),
        format!("step size H to be attempted on next step: {}", g(r(2))),
        format!("step size used on last successful step: {}", g(r(6))),
        format!("the order of the method used on the last step: {}", i(7)),
        format!("the order of the method to be attempted on the next step: {}", i(8)),
        format!("number of steps taken so far: {}", i(10)),
        format!("number of calls of functionODE() : {}", i(11)),
        format!("number of calculation of jacobian : {}", i(12)),
        format!("total number of convergence test failures: {}", i(14)),
        format!("total number of error test failures: {}", i(13)),
    ] {
        omclog::info(omclog::DASSL, false, &l);
    }
    omclog::close(omclog::DASSL);
    omclog::info(omclog::DASSL, false, "Finished DASSL step.");
}

/// C's `realVarsData[i].attribute.nominal` for the states, floored at 1e-32 by
/// `functionUpdateBoundVariableAttributes` and so only readable after
/// initialization. In DAE mode the algebraic unknowns' nominals follow (C's
/// `getAlgebraicDAEVarNominals`), one per extra component of IDA's `y`. Length ≥ 1
/// so daskr never sees an empty array.
fn read_state_nominals(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<Vec<f64>> {
    let mut nominals: Vec<f64> = (0..layout.n_states)
        .map(|i| read_f64(e, sim_data + layout.state_nom_off + i * 8))
        .collect::<Result<_>>()?;
    for k in 0..layout.n_dae_alg {
        nominals.push(read_f64(e, sim_data + layout.dae_alg_nom_off + k * 8)?);
    }
    if nominals.is_empty() {
        nominals.push(1.0);
    }
    Ok(nominals)
}

/// Per-state DASSL tolerances as in `dassl.c`: rtol `tol`, atol `tol·nominal[i]`.
fn dassl_tolerances(tol: f64, nominals: &[f64]) -> (Vec<f64>, Vec<f64>) {
    (vec![tol; nominals.len()], nominals.iter().map(|n| tol * n).collect())
}

fn nominal_factor() -> f64 {
    crate::simflags::with_flags(|f| f.jacobian_nominal_factor).unwrap_or(1.0)
}

/// Resumable DASSL (daskr) driver, event-free path. Owns the DASKR work arrays
/// and `y`/`yp` across chunks so an `advance` resumes the exact same
/// continuation — the trajectory is identical to running the whole loop at once.
struct DasslDriver {
    sim_data: u32,
    n_states: usize,
    states_base: u32,
    ders_base: u32,
    /// Next output row to produce (row 0 was emitted in `new`).
    row: u32,
    y: Vec<f64>,
    yp: Vec<f64>,
    info: [i32; 24],
    rtol: Vec<f64>,
    atol: Vec<f64>,
    nominals: Vec<f64>,
    /// Relative tolerance, for the numerical Jacobian's first step.
    tol: f64,
    rwork: Vec<f64>,
    iwork: Vec<i32>,
    rpar: [f64; 1],
    ipar: [i32; 1],
    jroot: [i32; 1],
    idid: i32,
    t: f64,
    /// `RES` (functionODE) eval count, accumulated across chunks.
    nfe: u64,
    pivots: Vec<StateSetPivot>,
    rows: Vec<f64>,
    /// Target of an interval left in progress at a mid-solve yield; `None` at a
    /// row boundary. Resumed on the next `advance`.
    pending_tout: Option<f64>,
    /// DASKR continuations spent on the in-progress interval (persisted so the
    /// runaway cap bounds one interval across yields).
    work_retries: i32,
    /// `-noEquidistantOutput{Frequency,Time}` over the integrator's own steps.
    step_emit: StepEmit,
    /// C's degenerate first `-noEquidistantTimeGrid` iteration has been emitted.
    no_grid_primed: bool,
    /// `terminate()` fired at the initial point; the first `advance` reports it.
    pending_terminate: bool,
    finished: bool,
    /// Analytic-Jacobian sparsity+coloring (colored numerical FD); `None` ⇒
    /// daskr's own numerical Jacobian.
    jac_a: Option<JacAInfo>,
    /// Jacobian evaluation count, accumulated across chunks (for the bench line).
    nje: u64,
    past: DaskrCounters,
}

/// DASKR zeroes its IWORK counters on a fresh start, so the run totals are folded
/// in here before each restart.
#[derive(Default)]
struct DaskrCounters {
    steps: u64,
    err_test_fails: u64,
    conv_test_fails: u64,
}

impl DaskrCounters {
    fn fold(&mut self, iwork: &[i32]) {
        self.steps += iwork.get(10).copied().unwrap_or(0).max(0) as u64;
        self.err_test_fails += iwork.get(13).copied().unwrap_or(0).max(0) as u64;
        self.conv_test_fails += iwork.get(14).copied().unwrap_or(0).max(0) as u64;
    }
}

impl DasslDriver {
    fn new(e: &mut (dyn SimEngine + 'static), model: &SimModel, sim_data: u32) -> Result<Self> {
        // Silence DASKR's own diagnostic printing (it would go to stdout and corrupt
        // the omc result record); failures are surfaced here via IDID instead.
        daskr::auxiliary::xsetf(0);
        let layout = &model.layout;
        // Init (with homotopy fallback). No state events on this path, so relations
        // stay fresh (mode 2); `rt_solve_nls` still holds them internally.
        run_initialization_model(e, sim_data, model)?;

        let n_states = layout.n_states as usize;
        let states_base = sim_data + REAL_OFF;
        let ders_base = states_base + layout.n_states * 8;
        let n_rows = model.n_output_rows();
        let n_reals = layout.n_row_total();
        let start = model.start_time;

        let mut rows: Vec<f64> = Vec::with_capacity((n_rows * n_reals) as usize);
        // Row 0 at the start time.
        emit_initial_row(e, &mut rows, sim_data, layout, start)?;
        let pending_terminate = terminated(e, sim_data, layout)?; // terminate() at the initial point

        // Dynamic state selection: seed the identity pivots (matching the wasm-side
        // `A[n,n]=1`), then re-pivot once at the initial point on the resolved states
        // — C re-selects immediately after initialisation. A switch reinits the state
        // variables from their candidates, so refresh the derivatives before reading
        // the initial `y`/`yp`. For an explicit ODE the consistent initial derivative
        // is exactly f(t0, y0), which `functionODE` (already called by `emit_row`) has
        // written into the derivative slots — so INFO(11)=0.
        let mut pivots = init_state_pivots(&model.state_sets);
        let (mut y, mut yp) = (Vec::new(), Vec::new());
        if n_states > 0 && !pending_terminate {
            if !model.state_sets.is_empty() && run_state_selection_initial(e, sim_data, &model.state_sets, &mut pivots)? {
                e.call1("functionODE", sim_data)?;
            }
            y = (0..n_states).map(|i| read_f64(e, states_base + (i as u32) * 8)).collect::<Result<_>>()?;
            yp = (0..n_states).map(|i| read_f64(e, ders_base + (i as u32) * 8)).collect::<Result<_>>()?;
        }

        // --- DASKR work arrays / options (dense, numerical Jacobian). ---
        let neq = n_states as i32;
        let nrt = 0i32;
        let tol = if model.tolerance > 0.0 { model.tolerance } else { 1e-6 };
        let lrw = (60 + 9 * neq + neq * neq + 3 * nrt + 64) as usize;
        let liw = (40 + neq + 64) as usize;
        // Analytic (colored numerical-FD) Jacobian when the backend gave us the "A"
        // sparsity+coloring: INFO(5)=1 selects daskr's dense user-Jacobian path.
        let jac_a = if env_var("OMC_WASM_NO_ANALYTIC_JAC").is_some() { None } else { model.jac_a.clone() };
        let mut info = [0i32; 24];
        if jac_a.is_some() {
            info[4] = 1;
        }
        // Per-state tolerances scaled by nominal, matching the C runtime
        // (`dassl.c`: INFO(2)=1, atol[i]=tol·max(|nominal_i|,1e-32)).
        let nominals = read_state_nominals(e, sim_data, layout)?;
        let (rtol, atol) = dassl_tolerances(tol, &nominals);
        if n_states > 0 {
            info[1] = 1; // INFO(2)=1: per-state (vector) rtol/atol
        }
        if no_equidistant_grid() && n_states > 0 {
            info[2] = 1; // INFO(3)=1: return after every internal step
        }
        let mut rwork = vec![0.0f64; lrw];
        let mut iwork = vec![0i32; liw];
        daskr_limits(&mut info, &mut rwork, &mut iwork);
        Ok(DasslDriver {
            sim_data,
            n_states,
            states_base,
            ders_base,
            row: 1,
            y,
            yp,
            // dense direct method, per-state nominal-scaled tolerances,
            // interpolating output, no IC calc; INFO(5) set above when the
            // analytic Jacobian is available.
            info,
            rtol,
            atol,
            nominals,
            tol,
            rwork,
            iwork,
            rpar: [0.0f64],
            ipar: [0i32],
            jroot: [0i32],
            idid: 0,
            t: start,
            nfe: 0,
            pivots,
            rows,
            pending_tout: None,
            step_emit: StepEmit::new(),
            no_grid_primed: false,
            work_retries: 0,
            pending_terminate,
            finished: false,
            jac_a,
            nje: 0,
            past: DaskrCounters::default(),
        })
    }

    /// Restart DASKR (INFO(1)=0), banking the IWORK run totals first.
    fn restart(&mut self) {
        self.past.fold(&self.iwork);
        self.info[0] = 0;
    }
}

impl Driver for DasslDriver {
    fn advance(&mut self, e: &mut (dyn SimEngine + 'static), model: &SimModel, budget_ms: f64) -> Result<Advance> {
        use daskr::solver;
        if self.finished {
            return Ok(Advance::Done);
        }
        let layout = &model.layout;
        let sim_data = self.sim_data;
        if self.pending_terminate {
            self.pending_terminate = false;
            self.finished = true;
            return Ok(Advance::Terminated);
        }
        let n_rows = model.n_output_rows();
        let n_steps = n_rows - 1;
        let start = model.start_time;
        let stop = model.stop_time;
        let grid = |row: u32| grid_time(row, start, stop, n_steps);
        let deadline = deadline_from(budget_ms);
        // `-noEquidistantTimeGrid`: one interval spans the run, rows come from the
        // IDID=1 returns below.
        let no_grid = no_equidistant_grid() && self.n_states > 0 && stop > start;
        let n_rows = if no_grid { 2 } else { n_rows };
        // C's first iteration here is a zero-length step (`lastdesiredStep` starts an
        // output interval ahead) and emits a second row at the start time.
        if no_grid && !self.no_grid_primed {
            self.no_grid_primed = true;
            emit_row(e, &mut self.rows, sim_data, layout, self.t, stop)?;
        }

        // No integration — just evaluate outputs on the grid — with no states or an
        // empty time span (`stopTime <= startTime`; a zero-width `ddaskr` step errors).
        if self.n_states == 0 || stop <= start {
            let mut did_step = false;
            while self.row < n_rows {
                if did_step && past_deadline(deadline) {
                    return Ok(Advance::Running);
                }
                check_alarm()?;
                if cancel_requested() {
                    return Ok(Advance::Cancelled);
                }
                did_step = true;
                let time = if self.row == n_steps { stop } else { grid(self.row) };
                open_assert_window();
                let emitted = emit_row(e, &mut self.rows, sim_data, layout, time, model.stop_time);
                close_assert_window(e, sim_data).and(emitted)?;
                store_operators(e, sim_data, layout)?;
                if terminated(e, sim_data, layout)? {
                    self.finished = true;
                    return Ok(Advance::Terminated);
                }
                self.row += 1;
            }
            self.finished = true;
            return Ok(Advance::Done);
        }

        let n_states = self.n_states;
        let states_base = self.states_base;
        let ders_base = self.ders_base;
        let neq = n_states as i32;
        let nrt = 0i32;
        let lrw = self.rwork.len();
        let liw = self.iwork.len();

        // Install the residual context for the duration of this chunk. `engine` is a
        // raw pointer to `*e`, live only across the `ddaskr` calls below (`e` is not
        // used directly meanwhile); the guard clears the thread-local on any exit.
        // `nfe` carries over between chunks.
        let jac_ptr = self.jac_a.as_ref().map_or(core::ptr::null(), |j| j as *const JacAInfo);
        let jacfn: solver::JacFn = if jac_ptr.is_null() { solver::dummy_jacd } else { dassl_jac };
        let mut ctx = ResCtx {
            engine: &mut *e as *mut dyn SimEngine,
            sim_data,
            states_base,
            ders_base,
            n_states,
            nls_fail_off: layout.nls_fail_off,
            nfe: self.nfe,
            zc_off: 0,
            n_zc: 0,
            err: None,
            jac: jac_ptr,
            jac_gp: vec![0.0; n_states],
            jac_ysave: vec![0.0; n_states],
            jac_del: vec![0.0; n_states],
            jac_ders: Vec::new(),
            jac_ypsave: Vec::new(),
            nje: self.nje,
            ext_input: core::ptr::null_mut(),
            ext_apply: None,
            ctx_addr: e.context_addr(),
            err_stage_addr: e.error_stage_addr(),
            nominals: self.nominals.as_ptr(),
            nominal_factor: nominal_factor(),
            tol: self.tol,
            #[cfg(sundials)]
            ida: IdaCtx::default(),
        };
        let _guard = ResCtxGuard;
        RES_CTX.store(&mut ctx as *mut ResCtx, Ordering::Relaxed);

        // Yield when the budget is spent, checked before each `ddaskr` call (so a
        // stuck interval spinning the work-quota loop yields too). `did_step` forces
        // ≥1 solver call per advance, so any budget (even 0) makes progress.
        let mut did_step = false;
        let outcome = loop {
            if self.row >= n_rows {
                break Advance::Done;
            }
            if did_step && past_deadline(deadline) {
                break Advance::Running;
            }
            check_alarm()?;
            if cancel_requested() {
                break Advance::Cancelled;
            }
            did_step = true;
            // IDID=-1: DASKR hit its per-call work quota before TOUT — resume with
            // INFO(1)=1 (a stiff interval hits this repeatedly), up to a cap.
            // `pending_tout`/`work_retries` persist an interval unfinished at a yield.
            let mut tout = self.pending_tout.unwrap_or(if no_grid || self.row == n_steps {
                stop
            } else {
                grid(self.row)
            });
            // Zero-length final interval (stop == start): daskr rejects TOUT == T,
            // so emit the held state directly instead of stepping.
            if tout <= self.t {
                for i in 0..n_states {
                    write_f64(e, states_base + (i as u32) * 8, self.y[i])?;
                }
                emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time)?;
                self.row += 1;
                continue;
            }
            let logging = log_dassl();
            if logging {
                log_dassl_step(self.t);
            }
            unsafe {
                solver::ddaskr(
                    dassl_res, neq, &mut self.t, self.y.as_mut_ptr(), self.yp.as_mut_ptr(),
                    &mut tout, self.info.as_mut_ptr(), self.rtol.as_mut_ptr(), self.atol.as_mut_ptr(),
                    &mut self.idid, self.rwork.as_mut_ptr(), lrw as i32, self.iwork.as_mut_ptr(), liw as i32,
                    self.rpar.as_mut_ptr(), self.ipar.as_mut_ptr(), jacfn, solver::dummy_jack,
                    solver::dummy_psol, solver::dummy_rt, nrt, self.jroot.as_mut_ptr(),
                );
            }
            if logging && self.idid != -1 {
                log_dassl_stats(self.idid, self.t, &self.rwork, &self.iwork);
            }
            self.nfe = ctx.nfe;
            self.nje = ctx.nje;
            // Surface a wasm error captured in the callback, then DASSL failures.
            if let Some(err) = ctx.err.take() {
                return Err(err);
            }
            if self.idid == -1 && self.work_retries < 10_000 {
                // Work quota expended before TOUT: stay on this interval, continue.
                self.info[0] = 1;
                self.work_retries += 1;
                self.pending_tout = Some(tout);
                continue;
            }
            if self.idid < 0 {
                return Err(report_dassl_failure(self.idid, self.t));
            }
            // IDID=1 (INFO(3)=1): one internal step, TOUT still ahead.
            if self.idid == 1 {
                self.pending_tout = Some(tout);
                self.work_retries = 0;
                if self.step_emit.take(self.t) {
                    for i in 0..n_states {
                        write_f64(e, states_base + (i as u32) * 8, self.y[i])?;
                    }
                    open_assert_window();
                    let emitted =
                        emit_row(e, &mut self.rows, sim_data, layout, self.t, model.stop_time);
                    close_assert_window(e, sim_data).and(emitted)?;
                    store_operators(e, sim_data, layout)?;
                    if terminated(e, sim_data, layout)? {
                        break Advance::Terminated;
                    }
                }
                continue;
            }
            // Interval complete: reset the resume state, write the interpolated state
            // back, and emit the row.
            self.pending_tout = None;
            self.work_retries = 0;
            for i in 0..n_states {
                write_f64(e, states_base + (i as u32) * 8, self.y[i])?;
            }
            open_assert_window();
            let emitted = emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time);
            close_assert_window(e, sim_data).and(emitted)?;
            store_operators(e, sim_data, layout)?;
            if terminated(e, sim_data, layout)? {
                break Advance::Terminated; // terminate() fired: keep this row, stop
            }
            // Re-read y/yp and restart DASKR (INFO(1)=0). No `functionODE` in
            // between: C's `dassl_step` takes YPRIME from the ring buffer, so it
            // restarts on the derivatives of the *previous* selection.
            if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)? {
                for i in 0..n_states {
                    self.y[i] = read_f64(e, states_base + (i as u32) * 8)?;
                    self.yp[i] = read_f64(e, ders_base + (i as u32) * 8)?;
                }
                self.restart();
            }
            self.row += 1;
        };
        self.nfe = ctx.nfe;
        if matches!(outcome, Advance::Done | Advance::Terminated) {
            self.finished = true;
        }
        Ok(outcome)
    }

    fn take_rows(&mut self) -> Vec<f64> {
        core::mem::take(&mut self.rows)
    }

    fn fill_stats(&mut self, _model: &SimModel, stats: &mut SolveStats) {
        // DASKR IWORK counters (1-based): IWORK(11)=NST steps, IWORK(13)=NJE Jacobian
        // evals, IWORK(14)=NETF error-test failures, IWORK(15)=NCFN convergence fails.
        let mut total = DaskrCounters {
            steps: self.past.steps,
            err_test_fails: self.past.err_test_fails,
            conv_test_fails: self.past.conv_test_fails,
        };
        total.fold(&self.iwork);
        stats.steps = total.steps;
        stats.res_evals = self.nfe;
        stats.jac_evals = if self.jac_a.is_some() { self.nje } else { self.iwork.get(12).copied().unwrap_or(0).max(0) as u64 };
        stats.err_test_fails = total.err_test_fails;
        stats.conv_test_fails = total.conv_test_fails;
    }
}

// ===========================================================================
// DASSL driver with event handling (time events + state events)
// ===========================================================================
//
// A near-copy of `run_dassl` that clamps the integration to each `sample` firing
// time and uses DASKR root-finding on the zero-crossing functions for state
// events: between events DASSL integrates as usual; at a sample time or a located
// crossing the discrete update runs (edge-detected when-bodies) and the
// integrator restarts. Kept separate from `run_dassl` so the fullRobot-validated
// event-free path is untouched. A discrete update that reinitialises a continuous
// state re-reads y and recomputes yp before restarting; state events on algebraic
// variables that need the full discrete solve are only approximately handled.

/// The integrator [`SolverCore`] drives, with the work state only it needs.
enum Solver {
    Daskr(DaskrState),
    /// Built on first use: the initial `y` is only read into the core after the
    /// core exists, and a model with no states never integrates at all.
    #[cfg(sundials)]
    Cvode(CvodeState),
    /// Built on first use, as [`Solver::Cvode`].
    #[cfg(sundials)]
    Ida(IdaState),
    /// `-s=gbode`: takes its own steps, locates its own events and interpolates
    /// onto the output grid, so [`SolverCore`] only has to hand it a target.
    Gbode(alloc::boxed::Box<crate::gbode::Gbode>),
    /// `-s=euler` / `-s=rungekutta`: one step per output interval, events located
    /// by bisecting the step afterwards.
    Fixed(crate::fixedstep::FixedStep),
}

/// DASKR's work arrays and options.
struct DaskrState {
    info: [i32; 24],
    rtol: Vec<f64>,
    atol: Vec<f64>,
    rwork: Vec<f64>,
    iwork: Vec<i32>,
    rpar: [f64; 1],
    ipar: [i32; 1],
    jroot: Vec<i32>,
    nrt: i32,
    idid: i32,
    past: DaskrCounters,
    /// The in-progress target's DASKR continuation count (IDID=-1 work quota).
    ev_retries: i32,
    /// Analytic-Jacobian sparsity+coloring (colored numerical FD); `None` ⇒
    /// daskr's own numerical Jacobian.
    jac_a: Option<JacAInfo>,
}

/// What one call into the integrator did.
enum Progress {
    Reached,
    /// INFO(3)=1 only: one internal step taken, the target not yet reached.
    Stepped,
    Root,
    /// The per-call work quota ran out before the target; call again to continue.
    WorkQuota,
    Failed(&'static str),
}

impl DaskrState {
    fn new(model: &SimModel, n_states: usize, nrt: i32, rtol: Vec<f64>, atol: Vec<f64>) -> Self {
        let neq = n_states as i32;
        let lrw = (60 + 9 * neq + neq * neq + 3 * nrt + 64) as usize;
        let liw = (40 + neq + 64) as usize;
        let jac_a = if env_var("OMC_WASM_NO_ANALYTIC_JAC").is_some() { None } else { model.jac_a.clone() };
        let mut info = [0i32; 24];
        if jac_a.is_some() {
            info[4] = 1; // INFO(5)=1: dense user (colored numerical-FD) Jacobian
        }
        if n_states > 0 {
            info[1] = 1; // INFO(2)=1: per-state (vector) rtol/atol
        }
        if no_equidistant_grid() {
            info[2] = 1; // INFO(3)=1: return after every internal step
        }
        let mut rwork = vec![0.0f64; lrw];
        let mut iwork = vec![0i32; liw];
        daskr_limits(&mut info, &mut rwork, &mut iwork);
        DaskrState {
            info,
            rtol,
            atol,
            rwork,
            iwork,
            rpar: [0.0f64],
            ipar: [0i32],
            jroot: vec![0i32; (nrt as usize).max(1)],
            nrt,
            idid: 0,
            past: DaskrCounters::default(),
            ev_retries: 0,
            jac_a,
        }
    }

    fn step(&mut self, t: &mut f64, y: &mut [f64], yp: &mut [f64], target: f64) -> Progress {
        use daskr::solver;
        let neq = y.len() as i32;
        let (lrw, liw) = (self.rwork.len(), self.iwork.len());
        let rt_fn: solver::RtFn = if self.nrt > 0 { dassl_rt } else { solver::dummy_rt };
        let jacfn: solver::JacFn = if self.jac_a.is_none() { solver::dummy_jacd } else { dassl_jac };
        let mut tt = target;
        let logging = log_dassl();
        if logging {
            log_dassl_step(*t);
        }
        unsafe {
            solver::ddaskr(
                dassl_res, neq, t, y.as_mut_ptr(), yp.as_mut_ptr(), &mut tt,
                self.info.as_mut_ptr(), self.rtol.as_mut_ptr(), self.atol.as_mut_ptr(), &mut self.idid,
                self.rwork.as_mut_ptr(), lrw as i32, self.iwork.as_mut_ptr(), liw as i32,
                self.rpar.as_mut_ptr(), self.ipar.as_mut_ptr(), jacfn,
                solver::dummy_jack, solver::dummy_psol, rt_fn, self.nrt,
                self.jroot.as_mut_ptr(),
            );
        }
        if logging && self.idid != -1 {
            log_dassl_stats(self.idid, *t, &self.rwork, &self.iwork);
        }
        // IDID=-1: the work quota expended before TOUT — resume with INFO(1)=1.
        if self.idid == -1 && self.ev_retries < 10_000 {
            self.info[0] = 1;
            self.ev_retries += 1;
            return Progress::WorkQuota;
        }
        self.ev_retries = 0; // this target's integration is done (or failing)
        if self.idid < 0 {
            return Progress::Failed(report_dassl_failure(self.idid, *t));
        }
        // IDID=5: stopped at a zero-crossing root; IDID=1: intermediate-output step.
        match self.idid {
            5 => Progress::Root,
            1 => Progress::Stepped,
            _ => Progress::Reached,
        }
    }
}

#[cfg(sundials)]
struct CvodeState {
    cv: Option<crate::sundials::Cvode>,
    rtol: f64,
    atol: Vec<f64>,
    n_roots: usize,
    work_retries: u32,
}

#[cfg(sundials)]
impl CvodeState {
    /// `cvode_solver.c`'s `LOG_SOLVER` banner. The configuration is fixed here, so
    /// every line but the tolerance is constant.
    fn log_configuration(&self) {
        for line in [
            "CVODE linear multistep method CV_BDF",
            "CVODE maximum integration order CV_ITER_NEWTON",
            "CVODE use equidistant time grid YES",
        ] {
            omclog::info(omclog::SOLVER, false, line);
        }
        omclog::info(
            omclog::SOLVER,
            false,
            &format!("CVODE Using relative error tolerance {}", format_e(self.rtol)),
        );
        for line in [
            "CVODE Using dense internal linear solver SUNLinSol_Dense.",
            "CVODE Use internal dense numeric jacobian method.",
            "CVODE uses internal root finding method NO",
            "CVODE maximum absolut step size 0",
            "CVODE initial step size is set automatically",
            "CVODE maximum integration order 5",
            "CVODE maximum number of nonlinear convergence failures permitted during one step 10",
            "CVODE BDF stability limit detection algorithm OFF",
        ] {
            omclog::info(omclog::SOLVER, false, line);
        }
    }

    /// The CVODE block is built on the first step, when `y` first holds the state
    /// to start from. `ctx` is the callbacks' `user_data`; it lives on the stack of
    /// one `advance`, so it is rebound on every call rather than stored.
    fn step(&mut self, t: &mut f64, y: &mut [f64], target: f64, ctx: *mut ResCtx) -> Result<Progress> {
        let cv = match self.cv.as_mut() {
            Some(cv) => cv,
            None => {
                let root = (self.n_roots > 0).then_some(cvode_root as crate::sundials::RootFn);
                let cv = crate::sundials::Cvode::new(
                    *t, y, self.rtol, &self.atol, self.n_roots, cvode_rhs, root,
                )
                .ok_or("CodegenWasmJit: CVODE initialization failed")?;
                self.log_configuration();
                self.cv.insert(cv)
            }
        };
        if !cv.set_user_data(ctx as *mut core::ffi::c_void) {
            return Err("CodegenWasmJit: CVODE setup failed");
        }
        let stop = cv.step(t, target);
        y.copy_from_slice(cv.y());
        Ok(match stop {
            crate::sundials::Stop::Failed(flag)
                if flag == crate::sundials::CV_TOO_MUCH_WORK && self.work_retries < CVODE_WORK_RETRIES =>
            {
                self.work_retries += 1;
                Progress::WorkQuota
            }
            crate::sundials::Stop::Failed(_) => Progress::Failed("CodegenWasmJit: CVODE failed"),
            other => {
                self.work_retries = 0;
                match other {
                    crate::sundials::Stop::Root => Progress::Root,
                    crate::sundials::Stop::Stepped => Progress::Stepped,
                    _ => Progress::Reached,
                }
            }
        })
    }
}

#[cfg(sundials)]
struct IdaState {
    ida: Option<crate::sundials::Ida>,
    rtol: f64,
    atol: Vec<f64>,
    n_roots: usize,
    work_retries: u32,
    setup: IdaSetup,
}

#[cfg(sundials)]
impl IdaState {
    /// The IDA block, built on first use — when `y`/`yp` first hold the state to
    /// start from. In DAE mode that also runs one `IDACalcIC`: C's initialization
    /// ends with `updateDiscreteSystem`, whose `functionDAE` is `ida_event_update`,
    /// and that is what makes the algebraic unknowns and `y'` consistent.
    #[allow(clippy::too_many_arguments)]
    fn ensure(
        &mut self,
        e: &mut dyn SimEngine,
        sim_data: u32,
        t: f64,
        y: &mut [f64],
        yp: &mut [f64],
        ctx: *mut ResCtx,
    ) -> Result<()> {
        if self.ida.is_some() {
            return Ok(());
        }
        let fresh = self.setup.build(e, sim_data, t, y, yp, self.rtol, &self.atol, self.n_roots)?;
        let ida = self.ida.insert(fresh);
        // `IDACalcIC` below calls them, so bind `user_data` first.
        unsafe { (*ctx).ida = self.setup.ctx(Some(ida)) };
        if !ida.set_user_data(ctx as *mut core::ffi::c_void) {
            return Err("CodegenWasmJit: IDA setup failed");
        }
        if self.setup.dae.is_some() {
            dae_calc_ic(ida, t)?;
            y.copy_from_slice(ida.y());
            yp.copy_from_slice(ida.yp());
            self.setup.dae_store(e, sim_data, y, yp)?;
            e.call2(MODEL_FN_DAE, sim_data, eval_stage::DISCRETE)?;
        }
        Ok(())
    }

    /// The IDA block is built on the first step, when `y`/`yp` first hold the
    /// state to start from. `ctx` is the callbacks' `user_data`, which lives on
    /// one `advance`'s stack, so it is rebound per call rather than stored.
    #[allow(clippy::too_many_arguments)]
    fn step(
        &mut self,
        e: &mut dyn SimEngine,
        sim_data: u32,
        t: &mut f64,
        y: &mut [f64],
        yp: &mut [f64],
        target: f64,
        ctx: *mut ResCtx,
    ) -> Result<Progress> {
        self.ensure(e, sim_data, *t, y, yp, ctx)?;
        let ida = self.ida.as_mut().expect("built by `ensure`");
        unsafe { (*ctx).ida = self.setup.ctx(Some(ida)) };
        if !ida.set_user_data(ctx as *mut core::ffi::c_void) {
            return Err("CodegenWasmJit: IDA setup failed");
        }
        let stop = ida.step(t, target, no_equidistant_grid());
        y.copy_from_slice(ida.y());
        yp.copy_from_slice(ida.yp());
        if !matches!(stop, crate::sundials::Stop::Failed(_)) {
            self.setup.store_sens(e, sim_data, ida)?;
        }
        Ok(match stop {
            crate::sundials::Stop::Failed(flag)
                if flag == crate::sundials::IDA_TOO_MUCH_WORK && self.work_retries < IDA_WORK_RETRIES =>
            {
                self.work_retries += 1;
                Progress::WorkQuota
            }
            crate::sundials::Stop::Failed(_) => Progress::Failed("CodegenWasmJit: IDA failed"),
            other => {
                self.work_retries = 0;
                match other {
                    crate::sundials::Stop::Root => Progress::Root,
                    _ => Progress::Reached,
                }
            }
        })
    }
}

/// The integrator state and the one integration path over it: [`integrate_to`]
/// runs the solver to a time, handling the state events it roots out and the
/// samples due on the way. `EventsDriver` drives it to each output row and
/// `CsDriver` to each communication point, so the two cannot drift. Only
/// [`solve_toward`] knows which integrator is underneath, so the event, sample and
/// chattering handling is shared by DASSL and CVODE.
///
/// [`integrate_to`]: SolverCore::integrate_to
/// [`solve_toward`]: SolverCore::solve_toward
struct SolverCore {
    sim_data: u32,
    n_states: usize,
    /// Components of the integrator's `y`: the states, plus in DAE mode the
    /// algebraic unknowns that follow them.
    n_unknowns: usize,
    /// `SimData` slot of each algebraic DAE unknown, empty for an explicit ODE.
    dae_alg_offs: Vec<u32>,
    /// The model was translated with `--daeMode`, so `y'` is a solver result.
    dae: bool,
    states_base: u32,
    ders_base: u32,
    y: Vec<f64>,
    yp: Vec<f64>,
    solver: Solver,
    t: f64,
    nfe: u64,
    /// Jacobian evaluation count, accumulated across chunks (for the bench line).
    nje: u64,
    state_events: u64,
    time_events: u64,
    nominals: Vec<f64>,
    /// Relative tolerance, for the numerical Jacobian's first step.
    tol: f64,
    /// Chattering detector: a ring of the last [`CHATTER_LIMIT`] state-event times
    /// + a consecutive-event counter. Fires once.
    chatter_times: [f64; CHATTER_LIMIT],
    chatter_idx: usize,
    chatter_consec: u32,
    chatter_emitted: bool,
    /// `-noEquidistantOutput{Frequency,Time}` over the integrator's own steps.
    step_emit: StepEmit,
    /// The next time event, which gbode may step up to but not past — it steps
    /// beyond the output point and interpolates back, so `target` alone is not
    /// the ceiling.
    sample_limit: f64,
    /// The model's ODE Jacobian sparsity+coloring, for the solvers that difference
    /// it themselves rather than through a `ResCtx` the integrator owns.
    jac_a: Option<JacAInfo>,
}

/// Consecutive state events within one output step that count as chattering.
const CHATTER_LIMIT: usize = 100;

/// The model-call handle the hand-written solvers (gbode, the fixed-step ones)
/// evaluate through, built from the `ResCtx` the integrator already has.
fn model_ode<'a>(
    e: &'a mut (dyn SimEngine + 'static),
    ctx: &'a ResCtx,
    states_base: u32,
    ders_base: u32,
    nominals: &'a [f64],
) -> crate::gbode::Ode<'a> {
    crate::gbode::Ode {
        e,
        sim_data: ctx.sim_data,
        states_base,
        ders_base,
        time_off: TIME_OFF,
        nls_fail_off: ctx.nls_fail_off,
        ctx_addr: ctx.ctx_addr,
        jac_a: unsafe { ctx.jac.as_ref() },
        nominals,
        nominal_factor: ctx.nominal_factor,
        zc_off: ctx.zc_off,
        calls: 0,
    }
}

/// C's `-s=euler`/`-s=rungekutta`, the two schemes [`crate::fixedstep`] serves.
fn fixed_kind(method: &str) -> Option<crate::fixedstep::FixedKind> {
    match method {
        "euler" => Some(crate::fixedstep::FixedKind::Euler),
        "rungekutta" => Some(crate::fixedstep::FixedKind::RungeKutta),
        _ => None,
    }
}

/// The driver's errors are `&'static str`, but a solver setup error carries the
/// offending flag value, so the message is built at runtime. Leaking it is fine:
/// it happens at most once per run, on the path that aborts the run.
pub(crate) fn leak_error(s: String) -> &'static str {
    alloc::boxed::Box::leak(s.into_boxed_str())
}

/// How close to a target counts as reached, and so the smallest step the chunked
/// fixed-step loop may ask for. Floored at the run's own time scale.
fn reached_eps(t: f64, span: f64) -> f64 {
    let floor = if span > 0.0 { span.min(1.0) } else { 1.0 };
    t.abs().max(floor) * 1e-10
}

/// C's `DASSL_STEP_EPS` (`simulation/solver/epsilon.h`).
const DASSL_STEP_EPS: f64 = 1e-13;

/// `dassl.c`'s floor on a step worth handing to DASKR.
fn small_step_eps(span: f64) -> f64 {
    DASSL_STEP_EPS.max(DASSL_STEP_EPS * span)
}

/// How far one [`SolverCore::solve_toward`] got.
enum Solved {
    Reached,
    /// `-noEquidistantTimeGrid`: one integrator step ended at `SolverCore::t`.
    Stepped,
    /// A root function changed sign; `SolverCore::t` is where.
    Root,
    Yielded,
    Cancelled,
}

/// How far [`SolverCore::integrate_to`] got.
enum Step {
    /// `tout` reached; `grid_covered` when an event landed on it, so its rows are
    /// already emitted.
    Reached { grid_covered: bool },
    Terminated,
    /// Located an event at `time`, discrete update left undone for the caller to
    /// report (CS Event Mode). Only returned under `stop_at_event`.
    Event { time: f64 },
    /// Out of budget mid-target; call again with the same `tout`.
    Yielded,
    Cancelled,
}

/// Resumable driver with event handling (time + state events). Like
/// [`DasslDriver`] but clamps integration to each `sample` time and root-finds the
/// zero-crossings. `mid_row`/`grid_covered` persist a partial output row so a yield
/// mid-interval (or a stuck stiff/chattering one) resumes exactly.
struct EventsDriver {
    core: SolverCore,
    row: u32,
    pivots: Vec<StateSetPivot>,
    samp: Samples,
    sync: crate::sync::Sync,
    rows: Vec<f64>,
    /// Resume state for a yield mid output row, so `grid_covered` is not reset.
    mid_row: bool,
    grid_covered: bool,
    /// C's degenerate first iteration under `-noEquidistantTimeGrid` is emitted.
    no_grid_primed: bool,
    pending_terminate: bool,
    finished: bool,
}

impl SolverCore {
    /// Size the integrator's workspaces. `y`/`yp` are latched afterwards by
    /// [`read_states`]; the caller has already initialized the model
    /// (`run_initialization`).
    ///
    /// [`read_states`]: SolverCore::read_states
    fn new(
        e: &dyn SimEngine,
        model: &SimModel,
        sim_data: u32,
        t: f64,
        method: &str,
        gbode: Option<alloc::boxed::Box<crate::gbode::Gbode>>,
    ) -> Result<Self> {
        let layout = &model.layout;
        let n_states = layout.n_states as usize;
        let states_base = sim_data + REAL_OFF;
        let ders_base = states_base + layout.n_states * 8;
        let nrt = layout.n_zc as i32;
        let tol = if model.tolerance > 0.0 { model.tolerance } else { 1e-6 };
        // Per-state nominal-scaled tolerances (see `dassl_tolerances`); CVODE and
        // IDA take the same ones, as `cvode_solver_initial`/`ida_solver_initial` do.
        let nominals = read_state_nominals(e, sim_data, layout)?;
        let (rtol, atol) = dassl_tolerances(tol, &nominals);
        let _ = method;
        #[cfg(sundials)]
        let solver = match method {
            "cvode" => {
                Solver::Cvode(CvodeState { cv: None, rtol: tol, atol, n_roots: nrt as usize, work_retries: 0 })
            }
            "ida" => Solver::Ida(IdaState {
                ida: None,
                rtol: tol,
                atol,
                n_roots: nrt as usize,
                work_retries: 0,
                setup: IdaSetup::new(model)?,
            }),
            _ => Solver::Daskr(DaskrState::new(model, n_states, nrt, rtol, atol)),
        };
        #[cfg(not(sundials))]
        let solver = Solver::Daskr(DaskrState::new(model, n_states, nrt, rtol, atol));
        let solver = if let Some(kind) = fixed_kind(method) {
            Solver::Fixed(crate::fixedstep::FixedStep::new(kind, n_states, layout.n_zc as usize))
        } else if let Some(mut g) = gbode {
            g.set_experiment(model.start_time, model.stop_time, model.step_size());
            g.set_nominals(&nominals);
            Solver::Gbode(g)
        } else {
            solver
        };
        Ok(SolverCore {
            sim_data,
            n_states,
            n_unknowns: n_states + layout.n_dae_alg as usize,
            dae_alg_offs: model.dae.as_ref().map(|d| d.alg_offs.clone()).unwrap_or_default(),
            dae: layout.dae_mode(),
            states_base,
            ders_base,
            y: Vec::new(),
            yp: Vec::new(),
            solver,
            t,
            nfe: 0,
            nje: 0,
            state_events: 0,
            time_events: 0,
            nominals,
            tol,
            chatter_times: [0.0; CHATTER_LIMIT],
            chatter_idx: 0,
            chatter_consec: 0,
            chatter_emitted: false,
            step_emit: StepEmit::new(),
            sample_limit: f64::INFINITY,
            jac_a: model.jac_a.clone(),
        })
    }

    /// The IDA memory and sparse layout the Jacobian callback reads through;
    /// all-null unless this core runs IDA.
    #[cfg(sundials)]
    fn ida_ctx(&self) -> IdaCtx {
        match &self.solver {
            Solver::Ida(s) => s.setup.ctx(s.ida.as_ref()),
            _ => IdaCtx::default(),
        }
    }

    /// The `IDACalcIC` half of C's `ida_event_update`, run after `restart` has
    /// re-initialized IDA at the post-event state: consistent algebraic unknowns and
    /// derivatives, pushed back into `SimData`. `ctx` must be the live callback
    /// context — `IDACalcIC` evaluates the residual.
    fn dae_restart(&mut self, e: &mut (dyn SimEngine + 'static), ctx: *mut ResCtx) -> Result<()> {
        if !self.dae {
            return Ok(());
        }
        let _ = ctx; // DAE mode needs SUNDIALS, so without it there is nothing to do
        #[cfg(sundials)]
        if let Solver::Ida(s) = &mut self.solver {
            let Some(ida) = s.ida.as_mut() else { return Ok(()) };
            if !ida.set_user_data(ctx as *mut core::ffi::c_void) {
                return Err("CodegenWasmJit: IDA setup failed");
            }
            dae_calc_ic(ida, self.t)?;
            self.y.copy_from_slice(ida.y());
            self.yp.copy_from_slice(ida.yp());
            self.write_states(e)?;
            e.call2(MODEL_FN_DAE, self.sim_data, eval_stage::DISCRETE)?;
        }
        Ok(())
    }

    /// The `IDACalcIC` C's initialization performs before the first output row —
    /// which already reports the algebraic unknowns and derivatives IDA solves for.
    fn prime(&mut self, e: &mut (dyn SimEngine + 'static), layout: &SimLayout) -> Result<()> {
        if !self.dae {
            return Ok(());
        }
        self.read_states(e)?;
        let mut ctx = self.res_ctx(e, layout);
        let ctx_ptr = &mut ctx as *mut ResCtx;
        RES_CTX.store(ctx_ptr, Ordering::Relaxed);
        let _guard = ResCtxGuard;
        let (t, sim_data) = (self.t, self.sim_data);
        #[cfg(sundials)]
        if let Solver::Ida(state) = &mut self.solver {
            let e = unsafe { &mut *ctx.engine };
            state.ensure(e, sim_data, t, &mut self.y, &mut self.yp, ctx_ptr)?;
        }
        if let Some(err) = ctx.err.take() {
            return Err(err);
        }
        Ok(())
    }

    /// Record a state event at `time`. `Some((t0, time))` once [`CHATTER_LIMIT`]
    /// consecutive events span less than `step_size`.
    fn note_chatter_event(&mut self, time: f64, step_size: f64) -> Option<(f64, f64)> {
        self.chatter_times[self.chatter_idx] = time;
        self.chatter_consec += 1;
        let hit = if !self.chatter_emitted && self.chatter_consec >= CHATTER_LIMIT as u32 {
            let t0 = self.chatter_times[(self.chatter_idx + 1) % CHATTER_LIMIT];
            (time - t0 < step_size).then_some((t0, time))
        } else {
            None
        };
        if hit.is_some() {
            self.chatter_emitted = true;
        }
        self.chatter_idx = (self.chatter_idx + 1) % CHATTER_LIMIT;
        hit
    }

    /// A step with no state event breaks the run.
    fn note_clean_step(&mut self) {
        self.chatter_consec = 0;
    }

    /// Record a state event for chattering detection, reporting the run once it
    /// trips (C's `chatteringInfo`). `-abortSlowSimulation` makes it a failure.
    fn note_chatter(&mut self, model: &SimModel, zc: usize) -> Result<()> {
        let step_size = model.step_size();
        let Some((t0, t1)) = self.note_chatter_event(self.t, step_size) else {
            return Ok(());
        };
        let desc = model.zc_desc.get(zc).map(String::as_str).unwrap_or("<zero-crossing>");
        omclog::info(
            omclog::STDOUT,
            false,
            &format!(
                "Chattering detected around time {t0}..{t1} ({CHATTER_LIMIT} state events in a row \
                 with a total time delta less than the step size {step_size}). This can be a \
                 performance bottleneck. Use -lv LOG_EVENTS for more information. The \
                 zero-crossing was: {desc}"
            ),
        );
        if chatter_store::abort() {
            omclog::message_text(
                omclog::DEBUG_TYPE,
                omclog::ASSERT,
                false,
                "Aborting simulation due to chattering being detected and the simulation flags \
                 requesting we do not continue further.",
            );
            return Err(CHATTER_ABORT_ERR);
        }
        Ok(())
    }

    /// Restart the integrator at the current `(t, y)`, banking the run totals its
    /// own counters are about to lose. Every event restarts, so without this the
    /// step count is only the last segment's.
    fn restart(&mut self) -> Result<()> {
        match &mut self.solver {
            Solver::Daskr(d) => {
                d.past.fold(&d.iwork);
                d.info[0] = 0; // INFO(1)=0
            }
            #[cfg(sundials)]
            Solver::Cvode(c) => {
                if let Some(cv) = c.cv.as_mut() {
                    cv.y_mut().copy_from_slice(&self.y);
                    if !cv.reinit(self.t) {
                        return Err("CodegenWasmJit: CVODE re-initialization failed");
                    }
                }
            }
            #[cfg(sundials)]
            Solver::Ida(s) => {
                if let Some(ida) = s.ida.as_mut() {
                    ida.y_mut().copy_from_slice(&self.y);
                    ida.yp_mut().copy_from_slice(&self.yp);
                    if !ida.reinit(self.t) {
                        return Err("CodegenWasmJit: IDA re-initialization failed");
                    }
                }
            }
            Solver::Gbode(g) => g.restart(),
            // The fixed-step solvers carry no step history to invalidate.
            Solver::Fixed(_) => {}
        }
        Ok(())
    }

    /// A time event changes discrete state the derivative may depend on, so a
    /// solver that carries its own step history has to re-initialize. gbode always
    /// does, as C's `didEventStep` is set for time events too.
    fn restart_after_time_event(&self) -> bool {
        matches!(self.solver, Solver::Gbode(_))
    }

    /// Recompute `yp` after an event, as C's `updateContinuousSystem` does: a
    /// `reinit` otherwise leaves the next step on the pre-event derivative.
    fn refresh_yp(&mut self, e: &mut (dyn SimEngine + 'static)) -> Result<()> {
        if self.dae {
            return Ok(());
        }
        e.call1("functionODE", self.sim_data)?;
        for i in 0..self.n_states {
            self.yp[i] = read_f64(e, self.ders_base + (i as u32) * 8)?;
        }
        Ok(())
    }

    /// Latch `(y, yp)` from `SimData` — after initialization, or after anything
    /// that moved a state behind DASKR's back. In DAE mode the algebraic unknowns
    /// follow the states in `y` (C's `getAlgebraicDAEVars`); their `y'` entries stay
    /// zero, as C's `calloc`'d `statesDer` leaves them.
    fn read_states(&mut self, e: &mut (dyn SimEngine + 'static)) -> Result<()> {
        self.read_y(e)?;
        self.yp = (0..self.n_states)
            .map(|i| read_f64(e, self.ders_base + (i as u32) * 8))
            .collect::<Result<_>>()?;
        self.yp.resize(self.n_unknowns, 0.0);
        Ok(())
    }

    /// The `y` half of [`read_states`](SolverCore::read_states), for the callers
    /// that must not disturb the integrator's own `y'`.
    fn read_y(&mut self, e: &mut (dyn SimEngine + 'static)) -> Result<()> {
        self.y = (0..self.n_states)
            .map(|i| read_f64(e, self.states_base + (i as u32) * 8))
            .collect::<Result<_>>()?;
        for &off in &self.dae_alg_offs {
            self.y.push(read_f64(e, self.sim_data + off)?);
        }
        Ok(())
    }

    /// The integrator's accepted point back into `SimData`. For an explicit ODE only
    /// the states move (the model computes `y'`); in DAE mode `y'` and the algebraic
    /// unknowns are solver results too.
    fn write_states(&self, e: &mut (dyn SimEngine + 'static)) -> Result<()> {
        for i in 0..self.n_states {
            write_f64(e, self.states_base + (i as u32) * 8, self.y[i])?;
        }
        for (k, &off) in self.dae_alg_offs.iter().enumerate() {
            write_f64(e, self.sim_data + off, self.y[self.n_states + k])?;
        }
        if self.dae {
            for i in 0..self.n_states {
                write_f64(e, self.ders_base + (i as u32) * 8, self.yp[i])?;
            }
        }
        Ok(())
    }

    /// The `ResCtx` the solver callbacks read through, held for one `integrate_to`
    /// (`RES_CTX` is a thread-local raw pointer to it; CVODE gets the same pointer
    /// as its `user_data`).
    fn res_ctx(&self, e: &mut (dyn SimEngine + 'static), layout: &SimLayout) -> ResCtx {
        ResCtx {
            engine: e as *mut dyn SimEngine,
            sim_data: self.sim_data,
            states_base: self.states_base,
            ders_base: self.ders_base,
            n_states: self.n_states,
            nls_fail_off: layout.nls_fail_off,
            nfe: self.nfe,
            zc_off: layout.zc_off,
            n_zc: layout.n_zc as usize,
            err: None,
            jac: match &self.solver {
                Solver::Daskr(d) => d.jac_a.as_ref().map_or(core::ptr::null(), |j| j as *const JacAInfo),
                #[cfg(sundials)]
                Solver::Cvode(_) => core::ptr::null(),
                #[cfg(sundials)]
                Solver::Ida(s) => s.setup.jac_a.as_ref().map_or(core::ptr::null(), |j| j as *const JacAInfo),
                // gbode differences the ODE Jacobian itself and takes the pattern
                // from here; the fixed-step solvers need none.
                Solver::Gbode(_) => self.jac_a.as_ref().map_or(core::ptr::null(), |j| j as *const JacAInfo),
                Solver::Fixed(_) => core::ptr::null(),
            },
            jac_gp: vec![0.0; self.n_unknowns],
            jac_ysave: vec![0.0; self.n_unknowns],
            jac_del: vec![0.0; self.n_unknowns],
            jac_ders: Vec::new(),
            jac_ypsave: vec![0.0; self.n_unknowns],
            nje: self.nje,
            ext_input: core::ptr::null_mut(),
            ext_apply: None,
            ctx_addr: e.context_addr(),
            err_stage_addr: e.error_stage_addr(),
            nominals: self.nominals.as_ptr(),
            nominal_factor: nominal_factor(),
            tol: self.tol,
            #[cfg(sundials)]
            ida: self.ida_ctx(),
        }
    }

    /// Integrate from `t` toward `target` with whichever integrator this core has,
    /// leaving `t`/`y` where it stopped. Both may stop early at a zero-crossing
    /// root, and both may return having spent a per-call work quota without
    /// reaching `target` — that is retried here, so the caller sees only the four
    /// outcomes.
    fn solve_toward(
        &mut self,
        target: f64,
        ctx: &mut ResCtx,
        deadline: f64,
        did_step: &mut bool,
    ) -> Result<Solved> {
        let sim_data = self.sim_data;
        loop {
            // Yield inside the work-quota loop too, so a stuck stiff interval is
            // interruptible; resume re-enters with the same target.
            if *did_step && past_deadline(deadline) {
                return Ok(Solved::Yielded);
            }
            check_alarm()?;
            if cancel_requested() {
                return Ok(Solved::Cancelled);
            }
            let again = match &mut self.solver {
                Solver::Daskr(d) => d.step(&mut self.t, &mut self.y, &mut self.yp, target),
                #[cfg(sundials)]
                Solver::Cvode(c) => c.step(&mut self.t, &mut self.y, target, ctx as *mut ResCtx)?,
                #[cfg(sundials)]
                Solver::Ida(s) => {
                    let e = unsafe { &mut *ctx.engine };
                    let ctx_ptr = ctx as *mut ResCtx;
                    s.step(e, sim_data, &mut self.t, &mut self.y, &mut self.yp, target, ctx_ptr)?
                }
                Solver::Fixed(f) => {
                    let e = unsafe { &mut *ctx.engine };
                    let mut ode = model_ode(e, ctx, self.states_base, self.ders_base, &self.nominals);
                    match f.step(&mut ode, &mut self.t, &mut self.y, &mut self.yp, target)? {
                        crate::fixedstep::FixedProgress::Reached => Progress::Reached,
                        crate::fixedstep::FixedProgress::Root(_) => Progress::Root,
                    }
                }
                Solver::Gbode(g) => {
                    let e = unsafe { &mut *ctx.engine };
                    let mut ode = model_ode(e, ctx, self.states_base, self.ders_base, &self.nominals);
                    let limit = self.sample_limit;
                    match g.step(&mut ode, target, limit, &mut self.t, &mut self.y)? {
                        crate::gbode::GbStep::Reached => Progress::Reached,
                        crate::gbode::GbStep::Stepped => Progress::Stepped,
                        crate::gbode::GbStep::Root(_) => Progress::Root,
                    }
                }
            };
            self.nfe = ctx.nfe;
            self.nje = ctx.nje;
            *did_step = true;
            // A wasm error in a callback outranks whatever the solver reported.
            if let Some(err) = ctx.err.take() {
                return Err(err);
            }
            match again {
                Progress::WorkQuota => continue,
                Progress::Failed(err) => return Err(err),
                Progress::Reached => return Ok(Solved::Reached),
                Progress::Stepped => return Ok(Solved::Stepped),
                Progress::Root => return Ok(Solved::Root),
            }
        }
    }

    /// Steps, evaluations and failure counts from the integrator (run totals, so
    /// the segments a restart discarded are included).
    fn fill_stats(&self, stats: &mut SolveStats) {
        match &self.solver {
            Solver::Daskr(d) => {
                let mut total = DaskrCounters {
                    steps: d.past.steps,
                    err_test_fails: d.past.err_test_fails,
                    conv_test_fails: d.past.conv_test_fails,
                };
                total.fold(&d.iwork);
                stats.steps = total.steps;
                stats.res_evals = self.nfe;
                stats.jac_evals = if d.jac_a.is_some() {
                    self.nje
                } else {
                    d.iwork.get(12).copied().unwrap_or(0).max(0) as u64
                };
                stats.err_test_fails = total.err_test_fails;
                stats.conv_test_fails = total.conv_test_fails;
            }
            #[cfg(sundials)]
            Solver::Cvode(c) => {
                if let Some(cv) = c.cv.as_ref() {
                    fill_sundials_stats(stats, cv.counters());
                }
            }
            #[cfg(sundials)]
            Solver::Ida(s) => {
                if let Some(ida) = s.ida.as_ref() {
                    fill_sundials_stats(stats, ida.counters());
                }
            }
            Solver::Fixed(f) => {
                stats.steps = f.steps;
                stats.res_evals = self.nfe;
            }
            Solver::Gbode(g) => {
                let s = g.stats();
                stats.steps = s.steps;
                stats.res_evals = s.calls_ode;
                stats.jac_evals = s.calls_jacobian;
                stats.err_test_fails = s.err_test_failures;
                stats.conv_test_fails = s.convergence_test_failures;
            }
        }
        stats.state_events = self.state_events;
        stats.time_events = self.time_events;
    }

    /// Whether the solver returns after each internal step, which
    /// `-noEquidistantTimeGrid` needs. CVODE here does not.
    fn reports_steps(&self) -> bool {
        match &self.solver {
            Solver::Daskr(_) => true,
            #[cfg(sundials)]
            Solver::Cvode(_) => false,
            #[cfg(sundials)]
            Solver::Ida(_) => true,
            Solver::Gbode(_) => true,
            // C's fixed-step solvers land on the output grid by construction.
            Solver::Fixed(_) => false,
        }
    }

    /// Every crossing whose indicator flipped at the located root — C's `eventLst`.
    fn roots_nonzero(&self) -> Vec<usize> {
        let pos = |r: &[i32]| r.iter().enumerate().filter(|(_, v)| **v != 0).map(|(i, _)| i).collect();
        match &self.solver {
            Solver::Daskr(d) => pos(&d.jroot),
            #[cfg(sundials)]
            Solver::Cvode(c) => c.cv.as_ref().map(|cv| pos(cv.roots())).unwrap_or_default(),
            #[cfg(sundials)]
            Solver::Ida(s) => s.ida.as_ref().map(|ida| pos(ida.roots())).unwrap_or_default(),
            Solver::Gbode(g) => vec![g.root_index()],
            Solver::Fixed(f) => vec![f.root_index()],
        }
    }

    /// C's `handleEvents` for the crossings [`save_zero_crossings`] reported at an
    /// accepted point; there is no root to localize. `Ok(true)` = terminated.
    #[allow(clippy::too_many_arguments)]
    fn handle_zc_flips(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        ctx: &mut ResCtx,
        sync: &mut crate::sync::Sync,
        mut rows: Option<&mut Vec<f64>>,
        flips: &[usize],
    ) -> Result<bool> {
        let layout = &model.layout;
        let sim_data = self.sim_data;
        let t = self.t;
        let eps = t.abs().max(1.0) * 1e-10;
        self.state_events += 1;
        log_state_event(t, flips, model);
        if let Some(r) = rows.as_deref_mut()
            && !no_event_emit()
        {
            capture_pre(e, r, sim_data, layout, t)?;
        }
        event_update(e, sim_data, layout, None, t)?;
        save_zero_crossings_after_event(e, sim_data, layout)?;
        if let Some(r) = rows.as_deref_mut() {
            if emit_post_event_row(model, t) {
                capture_row(e, r, sim_data, layout)?;
            }
            check_asserts(e, sim_data, layout, omclog::INFO)?;
        }
        if terminated(e, sim_data, layout)? {
            return Ok(true);
        }
        fire_clocks(e, sync, model, sim_data, t, eps, rows.as_deref_mut())?;
        store_operators(e, sim_data, layout)?;
        log_reinits(e, model);
        omclog::close(omclog::EVENTS);
        if terminated(e, sim_data, layout)? {
            return Ok(true);
        }
        self.read_states(e)?;
        self.refresh_yp(e)?;
        self.restart()?;
        self.dae_restart(e, ctx)?;
        Ok(false)
    }

    /// Integrate to `tout`, handling the state events the solver roots out and the
    /// samples due on the way. `rows` collects the pre/post-event rows when the
    /// caller wants them; CS passes `None`. A `Yielded` return resumes on the same
    /// `tout` (the integrator continues where it left off), so yields are safe points.
    /// `stop_at_event` (CS Event Mode) stops at the first event and returns
    /// [`Step::Event`] instead of updating in place.
    #[allow(clippy::too_many_arguments)]
    fn integrate_to(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        ctx: &mut ResCtx,
        samp: &mut Samples,
        sync: &mut crate::sync::Sync,
        tout: f64,
        deadline: f64,
        mut rows: Option<&mut Vec<f64>>,
        did_step: &mut bool,
        stop_at_event: bool,
    ) -> Result<Step> {
        let layout = &model.layout;
        let sim_data = self.sim_data;
        let n_states = self.n_states;
        let ders_base = self.ders_base;
        let span = model.stop_time - model.start_time;
        let eps = reached_eps(tout, span);
        let step_eps = small_step_eps(span);
        let mut grid_covered = false;

        loop {
            // Yield at the loop boundary (before any state mutation).
            if *did_step && past_deadline(deadline) {
                self.nfe = ctx.nfe;
                return Ok(Step::Yielded);
            }
            check_alarm()?;
            if cancel_requested() {
                self.nfe = ctx.nfe;
                return Ok(Step::Cancelled);
            }
            save_old_real(e, sim_data, layout)?; // C's `rotateRingBuffer`
            // Mode 0: hold relations across the DASKR solve so its residual/Jacobian
            // probes are smooth (C's `solveContinuous`); events/outputs refresh them.
            write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
            let te = samp.next_time();
            // C's `checkForSynchronous`: never step past the next activation. Snapped
            // onto `tout` (as samples are) so the last row's time is exactly `stop`.
            let mut tc = sync.next_time();
            if (tc - tout).abs() <= eps {
                tc = tout;
            }
            let target = tout.min(te).min(tc);
            self.sample_limit = te.min(tc);
            // Integrate from the current t toward `target` (the caller's time or the
            // next scheduled sample). DASKR may stop early at a zero-crossing root.
            if target - self.t > step_eps {
                // C's `perform_simulation` `LOG_SOLVER` block around `simulationStep`.
                if omclog::active(omclog::SOLVER) {
                    omclog::info(
                        omclog::SOLVER,
                        true,
                        &format!(
                            "call solver from {} to {} (stepSize: {})",
                            format_g(self.t, 6),
                            format_g(target, 6),
                            format_g15(target - self.t)
                        ),
                    );
                }
                let solved = self.solve_toward(target, ctx, deadline, did_step)?;
                if omclog::active(omclog::SOLVER) {
                    omclog::info(omclog::SOLVER, false, &format!("finished solver step {}", format_g(self.t, 6)));
                    omclog::close(omclog::SOLVER);
                }
                let rooted = match solved {
                    Solved::Yielded => {
                        self.nfe = ctx.nfe;
                        return Ok(Step::Yielded);
                    }
                    Solved::Cancelled => {
                        self.nfe = ctx.nfe;
                        return Ok(Step::Cancelled);
                    }
                    Solved::Reached | Solved::Stepped => false,
                    Solved::Root => true,
                };
                self.write_states(e)?;
                // C runs `simulationUpdate` on every accepted step, row due or not.
                if let Solved::Stepped = solved {
                    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
                    let mut emitted = false;
                    if let Some(r) = rows.as_deref_mut()
                        && self.step_emit.take(self.t)
                    {
                        emit_row(e, r, sim_data, layout, self.t, model.stop_time)?;
                        emitted = true;
                        if terminated(e, sim_data, layout)? {
                            return Ok(Step::Terminated);
                        }
                    }
                    if !emitted {
                        // C's `updateContinuousSystem`.
                        write_f64(e, sim_data + TIME_OFF, self.t)?;
                        eval_continuous(e, sim_data, layout)?;
                    }
                    store_operators(e, sim_data, layout)?;
                    let flips = save_zero_crossings(e, sim_data, layout)?;
                    if !flips.is_empty() {
                        *did_step = true;
                        self.note_chatter(model, flips[0])?;
                        if self.handle_zc_flips(e, model, ctx, sync, rows.as_deref_mut(), &flips)? {
                            return Ok(Step::Terminated);
                        }
                    }
                    check_asserts(e, sim_data, layout, omclog::INFO)?;
                    continue;
                }
                // A zero-crossing root at `t` (< target): DASKR stops on the
                // crossing, so the root itself is the event.
                if rooted {
                    let troot = self.t;
                    if stop_at_event {
                        write_f64(e, sim_data + TIME_OFF, troot)?;
                        return Ok(Step::Event { time: troot });
                    }
                    self.state_events += 1;
                    let roots = self.roots_nonzero();
                    log_state_event(troot, &roots, model);
                    self.note_chatter(model, roots.first().copied().unwrap_or(0))?;
                    // pre-event row (before the discrete update), then event +
                    // post-event row.
                    if let Some(r) = rows.as_deref_mut()
                        && !no_event_emit()
                    {
                        capture_pre(e, r, sim_data, layout, troot)?;
                    }
                    store_operators_at(e, sim_data, layout, troot)?;
                    let _ = save_zero_crossings(e, sim_data, layout)?;
                    event_update(e, sim_data, layout, None, troot)?;
                    save_zero_crossings_after_event(e, sim_data, layout)?;
                    if let Some(r) = rows.as_deref_mut() {
                        if emit_post_event_row(model, troot) {
                            capture_row(e, r, sim_data, layout)?;
                        }
                        check_asserts(e, sim_data, layout, omclog::INFO)?;
                    }
                    if terminated(e, sim_data, layout)? {
                        return Ok(Step::Terminated);
                    }
                    fire_clocks(e, sync, model, sim_data, troot, eps, rows.as_deref_mut())?;
                    // C's "add event to spatialDistribution": the post-event input
                    // jump becomes a discontinuity in the transported profile.
                    store_operators(e, sim_data, layout)?;
                    log_reinits(e, model);
                    omclog::close(omclog::EVENTS);
                    if terminated(e, sim_data, layout)? {
                        return Ok(Step::Terminated);
                    }
                    // Re-read states (a reinit may have jumped one), recompute the
                    // consistent derivative, and restart DASKR at troot (INFO(1)=0).
                    self.read_states(e)?;
                    self.refresh_yp(e)?;
                    self.restart()?;
                    self.dae_restart(e, ctx)?;
                    continue;
                }
                // Reached the target with no state event: breaks a chattering run.
                self.note_clean_step();
            } else if target > self.t && !self.dae {
                // `dassl.c`'s "Desired step size too small": one Euler step instead.
                let h = target - self.t;
                for i in 0..n_states {
                    self.y[i] += self.yp[i] * h;
                }
                self.t = target;
                self.write_states(e)?;
                write_f64(e, sim_data + TIME_OFF, self.t)?;
                self.refresh_yp(e)?;
                *did_step = true;
            }
            // Reached `target`. Fire a sample event at `te` if it lands at or
            // before `tout` (pre-event row, fire, post-event row).
            if te <= target + eps {
                // Only the final row snaps onto `stop`; C reports every other sample
                // at its accumulated time.
                let last = (tout - model.stop_time).abs() <= eps;
                let te = if last && (te - tout).abs() <= eps { tout } else { te };
                *did_step = true;
                if stop_at_event {
                    self.t = te;
                    write_f64(e, sim_data + TIME_OFF, te)?;
                    return Ok(Step::Event { time: te });
                }
                log_time_event(te, samp, model);
                if let Some(r) = rows.as_deref_mut()
                    && !no_event_emit()
                {
                    emit_row(e, r, sim_data, layout, te, model.stop_time)?; // pre-event row (held)
                }
                store_operators_at(e, sim_data, layout, te)?;
                let _ = save_zero_crossings(e, sim_data, layout)?;
                fire_time_event(e, samp, sim_data, layout, te)?;
                e.clean_nls_history(te);
                self.time_events += 1;
                if let Some(r) = rows.as_deref_mut()
                    && emit_post_event_row(model, te)
                {
                    emit_row(e, r, sim_data, layout, te, model.stop_time)?;
                }
                save_zero_crossings_after_event(e, sim_data, layout)?;
                store_operators(e, sim_data, layout)?;
                log_reinits(e, model);
                omclog::close(omclog::EVENTS);
                if terminated(e, sim_data, layout)? {
                    return Ok(Step::Terminated);
                }
                self.read_y(e)?;
                // A sample may change discrete state the derivative depends on;
                // recompute yp and restart so the integrator continues consistently.
                self.refresh_yp(e)?;
                if layout.n_zc > 0 || self.dae || self.restart_after_time_event() {
                    self.restart()?;
                    self.dae_restart(e, ctx)?;
                }
                if te >= tout - eps {
                    grid_covered = true;
                }
            }
            // C's `handleTimers`, plus any event clock a `when` body above just fired.
            if !sync.is_empty() {
                write_f64(e, sim_data + TIME_OFF, target)?;
                sync.take_fired(e, target)?;
            }
            if sync.next_time() <= target + eps {
                *did_step = true;
                write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
                eval_continuous(e, sim_data, layout)?;
                if fire_clocks(e, sync, model, sim_data, target, eps, rows.as_deref_mut())? {
                    if terminated(e, sim_data, layout)? {
                        return Ok(Step::Terminated);
                    }
                    store_operators(e, sim_data, layout)?;
                    self.read_y(e)?;
                    self.refresh_yp(e)?;
                    self.restart()?;
                    self.dae_restart(e, ctx)?;
                    if target >= tout - eps {
                        grid_covered = true;
                    }
                }
            }
            if target >= tout - eps {
                // C stores after the accepted point's evaluation and before the row is
                // written, so the row reports the operator's pre-store outputs — an
                // input-side output extrapolated from the just-stored value would close
                // the algebraic loop the extrapolation exists to avoid. `rows` is Some
                // exactly when the caller writes that row and stores after it.
                if rows.is_none() {
                    store_operators_at(e, sim_data, layout, self.t)?;
                    let flips = save_zero_crossings(e, sim_data, layout)?;
                    if !flips.is_empty() && self.handle_zc_flips(e, model, ctx, sync, None, &flips)? {
                        return Ok(Step::Terminated);
                    }
                }
                return Ok(Step::Reached { grid_covered });
            }
        }
    }
}

/// Co-Simulation: the FMU owns the integration, the importer picks the
/// communication points. Unlike [`EventsDriver`] there is no output grid and
/// no rows. [`step_to`](CsDriver::step_to) handles events internally
/// (`eventModeUsed = false`); [`step_to_event`](CsDriver::step_to_event) stops at
/// each event and reports it for the master to drive (`eventModeUsed = true`).
///
/// The caller initializes the model (`run_initialization`) before building this,
/// since FMI does that in its own Initialization Mode.
pub struct CsDriver {
    core: SolverCore,
    samp: Samples,
    sync: crate::sync::Sync,
    pivots: Vec<StateSetPivot>,
    /// The step `euler`/`rungekutta` take (the model's own output step); `None` for a
    /// variable-step method, which is handed the whole interval.
    fixed_h: Option<f64>,
    /// A `do_event_update` ran since the last step, so `step_to_event` must re-read
    /// states and restart DASKR.
    resume_reinit: bool,
}

/// What [`CsDriver::step_to`] / [`step_to_event`](CsDriver::step_to_event) did.
pub enum CsStep {
    /// Reached the requested time.
    Reached,
    /// Event Mode only: stopped at an event at `time` for the master to handle.
    Event { time: f64 },
    /// `terminate()` fired; `last_time` is where it stopped.
    Terminated,
}

impl CsDriver {
    /// Build over an already-initialized model at time `t`, integrating with the
    /// method the FMU was exported with (`buildModelFMU`'s `method=`).
    pub fn new(e: &mut (dyn SimEngine + 'static), model: &SimModel, sim_data: u32, t: f64) -> Result<Self> {
        daskr::auxiliary::xsetf(0);
        let layout = &model.layout;
        let method = resolve_solver_method(&model.method, layout.dae_mode())?;
        // QSS runs a whole simulation of its own; C's `solver_main_step` throws
        // "Unhandled case" for it rather than stepping it.
        if method == "qss" {
            return Err("CodegenWasmJit: method=\"qss\" cannot step to a communication point");
        }
        store_relations(e, sim_data, layout)?;
        let samp = Samples::load(e, sim_data, layout, t)?;
        let mut sync = crate::sync::Sync::new(e, model, sim_data)?;
        sync.take_fired(e, t)?;
        let mut core = SolverCore::new(&*e, model, sim_data, t, method, alloc_gbode(model, method)?)?;
        let mut pivots = init_state_pivots(&model.state_sets);
        if core.n_states > 0 {
            if !model.state_sets.is_empty() && run_state_selection_initial(e, sim_data, &model.state_sets, &mut pivots)? {
                e.call1("functionODE", sim_data)?;
            }
            core.read_states(e)?;
        }
        let h = model.step_size();
        let fixed_h = fixed_kind(method).map(|_| if h > 0.0 { h } else { f64::INFINITY });
        Ok(CsDriver { core, samp, sync, pivots, fixed_h, resume_reinit: false })
    }

    /// The time reached so far (FMI's `last-successful-time`).
    pub fn time(&self) -> f64 {
        self.core.t
    }

    /// Advance to `t_target`, handling events on the way. No budget: an importer's
    /// `do-step` runs to completion.
    pub fn step_to(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        t_target: f64,
    ) -> Result<CsStep> {
        let layout = &model.layout;
        let sim_data = self.core.sim_data;
        // No continuous states: only the samples move the model along.
        if self.core.n_states == 0 {
            let eps = t_target.abs().max(1.0) * 1e-10;
            while self.samp.next_time() <= t_target + eps {
                let te = self.samp.next_time();
                write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
                event_update(e, sim_data, layout, Some(&mut self.samp), te)?;
                self.core.time_events += 1;
                if terminated(e, sim_data, layout)? {
                    self.core.t = te;
                    return Ok(CsStep::Terminated);
                }
            }
            self.core.t = t_target;
            write_f64(e, sim_data + TIME_OFF, t_target)?;
            e.call1_if_present("functionAlgebraics", sim_data)?;
            return Ok(CsStep::Reached);
        }

        self.refresh_ders(e)?;
        let outcome = self.integrate_chunked(e, model, t_target, false)?;
        match outcome {
            Step::Terminated => return Ok(CsStep::Terminated),
            // `deadline` is +inf, CS does not cancel, and `stop_at_event` is off on
            // this path, so none of these can arise.
            Step::Yielded | Step::Cancelled | Step::Event { .. } => {
                return Err("CodegenWasmJit: CS step yielded unexpectedly")
            }
            Step::Reached { .. } => {}
        }
        // Refresh the outputs at the communication point, and re-select states there
        // (see `DasslDriver`).
        write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
        write_f64(e, sim_data + TIME_OFF, t_target)?;
        e.call1("functionODE", sim_data)?;
        e.call1_if_present("functionAlgebraics", sim_data)?;
        if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)? {
            e.call1("functionODE", sim_data)?;
            self.core.read_states(e)?;
            self.core.restart()?;
        }
        if terminated(e, sim_data, layout)? {
            return Ok(CsStep::Terminated);
        }
        Ok(CsStep::Reached)
    }

    /// Event Mode step (`eventModeUsed = true`): integrate toward `t_target`,
    /// stopping at the first event and returning [`CsStep::Event`] without the
    /// discrete update — the master runs that via [`do_event_update`] and resumes.
    ///
    /// [`do_event_update`]: CsDriver::do_event_update
    pub fn step_to_event(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        t_target: f64,
    ) -> Result<CsStep> {
        let layout = &model.layout;
        let sim_data = self.core.sim_data;
        // A reinit or discrete change in the master's update needs a DASKR restart.
        if self.resume_reinit {
            if self.core.n_states > 0 {
                e.call1("functionODE", sim_data)?;
                self.core.read_states(e)?;
                self.core.restart()?;
            }
            self.resume_reinit = false;
        }
        // No continuous states: stop at the next sample in the step for the master.
        if self.core.n_states == 0 {
            let eps = t_target.abs().max(1.0) * 1e-10;
            let te = self.samp.next_time();
            if te <= t_target + eps {
                self.core.t = te;
                write_f64(e, sim_data + TIME_OFF, te)?;
                return Ok(CsStep::Event { time: te });
            }
            self.core.t = t_target;
            write_f64(e, sim_data + TIME_OFF, t_target)?;
            e.call1_if_present("functionAlgebraics", sim_data)?;
            return Ok(CsStep::Reached);
        }

        self.refresh_ders(e)?;
        let outcome = self.integrate_chunked(e, model, t_target, true)?;
        match outcome {
            Step::Terminated => return Ok(CsStep::Terminated),
            Step::Event { time } => return Ok(CsStep::Event { time }),
            // `deadline` is +inf and CS does not cancel.
            Step::Yielded | Step::Cancelled => return Err("CodegenWasmJit: CS step yielded unexpectedly"),
            Step::Reached { .. } => {}
        }
        // Communication point reached with no event: refresh outputs like `step_to`.
        write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
        write_f64(e, sim_data + TIME_OFF, t_target)?;
        e.call1("functionODE", sim_data)?;
        e.call1_if_present("functionAlgebraics", sim_data)?;
        if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)? {
            e.call1("functionODE", sim_data)?;
            self.core.read_states(e)?;
            self.core.restart()?;
        }
        if terminated(e, sim_data, layout)? {
            return Ok(CsStep::Terminated);
        }
        Ok(CsStep::Reached)
    }

    /// The master's `update-discrete-states` at the event `step_to_event` stopped on.
    /// Fires any sample through the driver's own schedule so it stays in step with
    /// the integrator, and flags a DASKR restart for the next step.
    pub fn do_event_update(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        time: f64,
    ) -> Result<EventUpdate> {
        let layout = &model.layout;
        let eps = time.abs().max(1.0) * 1e-10;
        if self.samp.next_time() <= time + eps {
            self.core.time_events += 1;
        } else {
            self.core.state_events += 1;
        }
        let up = event_update(e, self.core.sim_data, layout, Some(&mut self.samp), time)?;
        self.resume_reinit = true;
        Ok(up)
    }

    /// C's `fmi2DoStep` reads the derivatives at the start of every step, after the
    /// master has set that point's inputs; a fixed-step method takes its first
    /// stage from them. The variable-step solvers evaluate the model themselves and
    /// must keep their own history, so this is for the fixed-step ones.
    fn refresh_ders(&mut self, e: &mut (dyn SimEngine + 'static)) -> Result<()> {
        if self.fixed_h.is_none() || self.core.n_states == 0 {
            return Ok(());
        }
        e.call1("functionODE", self.core.sim_data)?;
        self.core.read_states(e)
    }

    /// Integrate to `t_target`: in one go for a variable-step method, or one step per
    /// call for a fixed-step one. Those steps land on the model's own output grid — the
    /// sequence the standalone driver produces — so a communication point only cuts the
    /// last step of an interval short, as an event does. Returns early on `Terminated`
    /// and, in Event Mode, on the first event.
    fn integrate_chunked(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        t_target: f64,
        stop_at_event: bool,
    ) -> Result<Step> {
        let layout = &model.layout;
        let eps = t_target.abs().max(1.0) * 1e-12;
        let mut ctx = self.core.res_ctx(e, layout);
        let _guard = ResCtxGuard;
        RES_CTX.store(&mut ctx as *mut ResCtx, Ordering::Relaxed);
        let mut did_step = false;
        loop {
            let target = match self.fixed_h {
                // The next grid point past `t` by more than `integrate_to` calls
                // reached, or it refuses the step and this asks forever. Communication
                // points drift off the grid further than a nudge on the quotient.
                Some(h) => {
                    let mut g = model.start_time + (libm::floor((self.core.t - model.start_time) / h) + 1.0) * h;
                    if g - self.core.t <= reached_eps(self.core.t, model.stop_time - model.start_time) {
                        g += h;
                    }
                    g.min(t_target)
                }
                None => t_target,
            };
            let t_before = self.core.t;
            let outcome = self.core.integrate_to(
                e, model, &mut ctx, &mut self.samp, &mut self.sync, target, f64::INFINITY, None,
                &mut did_step, stop_at_event,
            )?;
            // On the chunk that asked for the caller's target, wherever rounding left
            // `t`: a tighter test on `t` asks for the same chunk forever.
            if !matches!(outcome, Step::Reached { .. }) || target >= t_target - eps {
                self.core.nfe = ctx.nfe;
                return Ok(outcome);
            }
            if self.core.t <= t_before {
                return Err(leak_error(alloc::format!(
                    "CodegenWasmJit: the integrator made no progress at t={} toward {t_target}",
                    self.core.t
                )));
            }
        }
    }

    pub fn fill_stats(&self, stats: &mut SolveStats) {
        self.core.fill_stats(stats);
    }
}

impl EventsDriver {
    /// `gbode` is built (and has logged its setup) by [`make_driver`] before
    /// initialization, as C's `gbode_allocateData` runs before `initializeModel`.
    fn new(
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        sim_data: u32,
        method: &str,
        gbode: Option<alloc::boxed::Box<crate::gbode::Gbode>>,
    ) -> Result<Self> {
        daskr::auxiliary::xsetf(0);
        let layout = &model.layout;
        // Init (with homotopy fallback). Relation mode 2 and `initSample` are handled
        // inside run_initialization; seed the hysteresis direction from the relations.
        crate::sync::clear_fire_flags(e, sim_data, layout)?;
        let sync = run_initialization_with_clocks(e, sim_data, model)?;
        store_relations(e, sim_data, layout)?;

        let n_states = layout.n_states as usize;
        let states_base = sim_data + REAL_OFF;
        let n_rows = model.n_output_rows();
        let n_reals = layout.n_row_total();
        let start = model.start_time;

        let samp = Samples::load(e, sim_data, layout, start)?;
        let mut rows: Vec<f64> = Vec::with_capacity((n_rows * n_reals) as usize);
        let mut core = SolverCore::new(&*e, model, sim_data, start, method, gbode)?;
        core.prime(e, layout)?;
        // A sample due at the start time is left to the first step, which C shortens
        // to zero length and handles as an ordinary time event.
        emit_initial_row(e, &mut rows, sim_data, layout, start)?;
        let pending_terminate = terminated(e, sim_data, layout)?;

        // Dynamic state selection: identity pivots, then re-pivot at the initial
        // point (see `DasslDriver`). A switch reinits states, so refresh derivatives.
        let mut pivots = init_state_pivots(&model.state_sets);
        if n_states > 0 && !pending_terminate {
            if !model.state_sets.is_empty() && run_state_selection_initial(e, sim_data, &model.state_sets, &mut pivots)? {
                e.call1("functionODE", sim_data)?;
            }
            core.read_states(e)?;
        }
        let _ = states_base;
        Ok(EventsDriver {
            core,
            row: 1,
            pivots,
            samp,
            sync,
            rows,
            mid_row: false,
            grid_covered: false,
            no_grid_primed: false,
            pending_terminate,
            finished: false,
        })
    }
}

impl Driver for EventsDriver {
    fn advance(&mut self, e: &mut (dyn SimEngine + 'static), model: &SimModel, budget_ms: f64) -> Result<Advance> {
        if self.finished {
            return Ok(Advance::Done);
        }
        let layout = &model.layout;
        let sim_data = self.core.sim_data;
        if self.pending_terminate {
            self.pending_terminate = false;
            self.finished = true;
            return Ok(Advance::Terminated);
        }
        let n_rows = model.n_output_rows();
        let n_steps = n_rows - 1;
        let start = model.start_time;
        let stop = model.stop_time;
        let grid = |row: u32| grid_time(row, start, stop, n_steps);
        let deadline = deadline_from(budget_ms);
        // `-noEquidistantTimeGrid`: the rows come from `integrate_to`, so one "row"
        // spans the run; `Samples` still bounds each solve.
        let no_grid = no_equidistant_grid()
            && self.core.n_unknowns > 0
            && stop > start
            && self.core.reports_steps();
        let n_rows = if no_grid { 2 } else { n_rows };
        // See `DasslDriver`: C's degenerate first iteration in this mode.
        if no_grid && !self.no_grid_primed {
            self.no_grid_primed = true;
            emit_row(e, &mut self.rows, sim_data, layout, self.core.t, stop)?;
        }
        let tout_of = |row: u32| {
            if no_grid || row == n_steps { stop } else { grid(row) }
        };

        // No continuous states: nothing to integrate, but zero-crossings on `time`
        // (e.g. a timer `time >= t_start + waitTime`) are still continuous events
        // that must be located between grid points. Walk grid point to grid point,
        // bracketing each state event on a zero-crossing sign change and bisecting to
        // its exact time, interleaved with the sample (time) events in time order.
        // A DAE-mode model still has its algebraic unknowns for IDA to solve, so it
        // takes the integrating path even with no states.
        if self.core.n_unknowns == 0 {
            let mut did_step = false;
            let mut zc0 = vec![0.0f64; layout.n_zc as usize];
            let mut scratch = vec![0.0f64; layout.n_zc as usize];
            if layout.n_zc > 0 {
                read_zero_crossings(e, sim_data, layout, &mut zc0)?;
            }
            while self.row < n_rows {
                if did_step && past_deadline(deadline) {
                    return Ok(Advance::Running);
                }
                check_alarm()?;
                if cancel_requested() {
                    return Ok(Advance::Cancelled);
                }
                did_step = true;
                let tout = tout_of(self.row);
                let eps = tout.abs().max(1.0) * 1e-10;
                let mut grid_covered = false;
                open_assert_window();
                // Handle every event (state or sample) up to `tout`, earliest first.
                loop {
                    save_old_real(e, sim_data, layout)?; // C's `rotateRingBuffer`
                    let te = self.samp.next_time();
                    let mut tc = self.sync.next_time();
                    if (tc - tout).abs() <= eps {
                        tc = tout;
                    }
                    let subtarget = tout.min(te).min(tc);
                    // A state event bracketed in (t, subtarget]?
                    let mut troot = None;
                    if layout.n_zc > 0 && subtarget - self.core.t > eps {
                        update_zero_crossings(e, sim_data, layout, subtarget, &mut scratch)?;
                        if zc_crossed(&zc0, &scratch) {
                            troot = Some(locate_zc_root(
                                e, sim_data, layout, self.core.t, subtarget, &zc0, &mut scratch,
                            )?);
                        }
                    }
                    if let Some(tr) = troot {
                        // The bisection left `SimData` at its last trial point.
                        update_zero_crossings(e, sim_data, layout, tr, &mut scratch)?;
                        log_state_event(tr, &zc_crossed_idx(&zc0, &scratch), model);
                        if !no_event_emit() {
                            capture_pre(e, &mut self.rows, sim_data, layout, tr)?; // pre-event row
                        }
                        store_operators_at(e, sim_data, layout, tr)?;
                        event_update(e, sim_data, layout, None, tr)?;
                        self.core.state_events += 1;
                        if emit_post_event_row(model, tr) {
                            capture_row(e, &mut self.rows, sim_data, layout)?; // post-event row
                        }
                        check_asserts(e, sim_data, layout, omclog::INFO)?;
                        if terminated(e, sim_data, layout)? {
                            self.finished = true;
                            return Ok(Advance::Terminated);
                        }
                        self.core.t = tr;
                        // The discrete update may have fired an event clock.
                        if fire_clocks(e, &mut self.sync, model, sim_data, tr, eps, Some(&mut self.rows))?
                            && terminated(e, sim_data, layout)?
                        {
                            self.finished = true;
                            return Ok(Advance::Terminated);
                        }
                        // C's "add event to spatialDistribution": the post-event
                        // input jump becomes a discontinuity in the profile.
                        store_operators(e, sim_data, layout)?;
                        read_zero_crossings(e, sim_data, layout, &mut zc0)?;
                        save_zc_pre(e, sim_data, layout)?;
                        log_reinits(e, model);
                        omclog::close(omclog::EVENTS);
                        continue;
                    }
                    // No state event before the next sample time. Fire the sample if
                    // it is due at or before this grid point; otherwise the interval
                    // is clean up to `tout`.
                    if te <= subtarget + eps {
                        let last = (tout - stop).abs() <= eps;
                        let te = if last && (te - tout).abs() <= eps { tout } else { te };
                        log_time_event(te, &self.samp, model);
                        write_i32(e, sim_data + layout.rel_fresh_off, 0)?; // held pre row
                        if !no_event_emit() {
                            emit_row(e, &mut self.rows, sim_data, layout, te, model.stop_time)?;
                        }
                        store_operators_at(e, sim_data, layout, te)?;
                        fire_time_event(e, &mut self.samp, sim_data, layout, te)?;
                        e.clean_nls_history(te);
                        self.core.time_events += 1;
                        if emit_post_event_row(model, te) {
                            emit_row(e, &mut self.rows, sim_data, layout, te, model.stop_time)?;
                        }
                        if terminated(e, sim_data, layout)? {
                            self.finished = true;
                            return Ok(Advance::Terminated);
                        }
                        self.core.t = te;
                        store_operators(e, sim_data, layout)?;
                        if layout.n_zc > 0 {
                            read_zero_crossings(e, sim_data, layout, &mut zc0)?;
                            save_zc_pre(e, sim_data, layout)?;
                        }
                        log_reinits(e, model);
                        omclog::close(omclog::EVENTS);
                        if te >= tout - eps {
                            grid_covered = true;
                        }
                    }
                    if !self.sync.is_empty() {
                        write_f64(e, sim_data + TIME_OFF, subtarget)?;
                        self.sync.take_fired(e, subtarget)?;
                    }
                    if self.sync.next_time() <= subtarget + eps {
                        self.core.t = subtarget;
                        write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
                        eval_continuous(e, sim_data, layout)?;
                        if fire_clocks(e, &mut self.sync, model, sim_data, subtarget, eps, Some(&mut self.rows))? {
                            if terminated(e, sim_data, layout)? {
                                self.finished = true;
                                return Ok(Advance::Terminated);
                            }
                            store_operators(e, sim_data, layout)?;
                            if layout.n_zc > 0 {
                                read_zero_crossings(e, sim_data, layout, &mut zc0)?;
                                save_zc_pre(e, sim_data, layout)?;
                            }
                            if subtarget >= tout - eps {
                                grid_covered = true;
                            }
                        }
                    } else if te > subtarget + eps {
                        break;
                    }
                }
                if !grid_covered {
                    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
                    let emitted = emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time);
                    close_assert_window(e, sim_data).and(emitted)?;
                    if terminated(e, sim_data, layout)? {
                        self.finished = true;
                        return Ok(Advance::Terminated);
                    }
                    store_operators(e, sim_data, layout)?;
                    if layout.n_zc > 0 {
                        read_zero_crossings(e, sim_data, layout, &mut zc0)?;
                        save_zc_pre(e, sim_data, layout)?;
                    }
                } else {
                    close_assert_window(e, sim_data)?;
                }
                self.core.t = tout;
                self.row += 1;
            }
            self.finished = true;
            return Ok(Advance::Done);
        }

        let mut ctx = self.core.res_ctx(e, layout);
        let _guard = ResCtxGuard;
        RES_CTX.store(&mut ctx as *mut ResCtx, Ordering::Relaxed);

        let mut did_step = false;
        let outcome = loop {
            if self.row >= n_rows {
                break Advance::Done;
            }
            if did_step && past_deadline(deadline) {
                break Advance::Running;
            }
            check_alarm()?;
            if cancel_requested() {
                break Advance::Cancelled;
            }
            let tout = tout_of(self.row);
            if !self.mid_row {
                self.grid_covered = false;
            }
            // C's `simulationUpdate` window: until this row's events are handled,
            // the state the model is evaluated at may still be discarded.
            open_assert_window();
            match self.core.integrate_to(
                e, model, &mut ctx, &mut self.samp, &mut self.sync, tout, deadline,
                Some(&mut self.rows), &mut did_step, false,
            )? {
                Step::Yielded => {
                    // Resume on the same row; `mid_row` keeps `grid_covered`.
                    self.mid_row = true;
                    return Ok(Advance::Running);
                }
                Step::Cancelled => return Ok(Advance::Cancelled),
                Step::Terminated => break Advance::Terminated,
                // `stop_at_event` is false here, so `Event` never arises.
                Step::Event { .. } => unreachable!("stop_at_event is off for the output-grid driver"),
                Step::Reached { grid_covered } => self.grid_covered |= grid_covered,
            }
            // Row's inner loop done; the rest is bounded — next yield is a clean boundary.
            self.mid_row = false;
            if !self.grid_covered {
                write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
                did_step = true;
                let emitted = emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time);
                close_assert_window(e, sim_data).and(emitted)?;
                // The row's evaluation is this point's `updateContinuousSystem`.
                store_operators(e, sim_data, layout)?;
                let flips = save_zero_crossings(e, sim_data, layout)?;
                if !flips.is_empty()
                    && self.core.handle_zc_flips(e, model, &mut ctx, &mut self.sync, Some(&mut self.rows), &flips)?
                {
                    break Advance::Terminated;
                }
                if terminated(e, sim_data, layout)? {
                    break Advance::Terminated;
                }
            } else {
                close_assert_window(e, sim_data)?;
            }
            // Re-select states at the accepted output point (see `DasslDriver`).
            if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)? {
                e.call1("functionODE", sim_data)?;
                self.core.read_states(e)?;
                self.core.restart()?;
            }
            self.row += 1;
        };
        self.core.nfe = ctx.nfe;
        if matches!(outcome, Advance::Done | Advance::Terminated) {
            self.finished = true;
        }
        Ok(outcome)
    }

    fn take_rows(&mut self) -> Vec<f64> {
        core::mem::take(&mut self.rows)
    }

    fn fill_stats(&mut self, _model: &SimModel, stats: &mut SolveStats) {
        self.core.fill_stats(stats);
    }
}

// ===========================================================================
// CVODE driver
// ===========================================================================
//
// The real SUNDIALS CVODE, configured as `cvode_solver.c` does: BDF + Newton
// over CVODE's own dense difference-quotient Jacobian, per-state nominal-scaled
// tolerances, and CVODE's root finding on the zero-crossings. Only linked when
// the archives are (`cfg(sundials)`); `simflags::check` rejects `-s=cvode`
// otherwise rather than let it run as DASSL.
//
// The callbacks reach wasm through the same [`ResCtx`] the DASSL ones use, but
// receive it as CVODE's `user_data` rather than through the `RES_CTX` global.

/// `CVRhsFn`: `ydot := f(t, y)`. Writes `t` and the candidate states into
/// `SimData`, calls the wasm `functionODE`, reads the derivative slots back.
/// A wasm trap is unrecoverable (-1); a non-converging nonlinear system is
/// recoverable (+1), which makes CVODE retry from a smaller step.
#[cfg(sundials)]
unsafe extern "C" fn cvode_rhs(
    t: f64,
    y: crate::sundials::NVector,
    ydot: crate::sundials::NVector,
    user_data: *mut core::ffi::c_void,
) -> core::ffi::c_int {
    let ctx = unsafe { &mut *(user_data as *mut ResCtx) };
    let e = unsafe { &mut *ctx.engine };
    let n = ctx.n_states;
    let run = (|| -> Result<()> {
        write_i32(e, ctx.sim_data + ctx.nls_fail_off, 0)?;
        write_f64(e, ctx.sim_data + TIME_OFF, t)?;
        let y_bytes = unsafe { core::slice::from_raw_parts(crate::sundials::nv_data(y) as *const u8, n * 8) };
        e.write_bytes(ctx.states_base, y_bytes)?;
        set_context(e, ctx.ctx_addr, CONTEXT_ODE);
        e.call1("functionODE", ctx.sim_data)?;
        set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
        let out = unsafe { core::slice::from_raw_parts_mut(crate::sundials::nv_data(ydot) as *mut u8, n * 8) };
        e.read_bytes(ctx.ders_base, out)
    })();
    ctx.nfe += 1;
    match run {
        Err(err) => {
            ctx.err = Some(err);
            -1
        }
        Ok(()) => {
            if read_i32(e, ctx.sim_data + ctx.nls_fail_off).unwrap_or(0) == 0 {
                return 0;
            }
            report_nls_failure_at(e, ctx.sim_data, ctx.nls_fail_off);
            1
        }
    }
}

/// `gout[i] := g_i(t, y)`, the zero-crossing values whose sign changes are state
/// events. The body of [`dassl_rt`], shared by the CVODE and IDA root callbacks.
#[cfg(sundials)]
unsafe fn eval_roots(ctx: &mut ResCtx, t: f64, y: *const f64, yp: *const f64, gout: *mut f64) -> Result<()> {
    let e = unsafe { &mut *ctx.engine };
    write_i32(e, ctx.sim_data + ctx.nls_fail_off, 0)?;
    write_f64(e, ctx.sim_data + TIME_OFF, t)?;
    unsafe { ida_push_unknowns(ctx, y, yp) }?;
    set_context(e, ctx.ctx_addr, CONTEXT_EVENTS);
    if unsafe { ctx.ida.dae.as_ref() }.is_some() {
        e.call2(MODEL_FN_DAE, ctx.sim_data, eval_stage::ZEROCROSS)?;
    } else {
        e.call1("functionZeroCrossingsEquations", ctx.sim_data)?;
    }
    e.call1("functionZeroCrossings", ctx.sim_data)?;
    set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
    let out = unsafe { core::slice::from_raw_parts_mut(gout as *mut u8, ctx.n_zc * 8) };
    e.read_bytes(ctx.sim_data + ctx.zc_off, out)
}

/// `CVRootFn`.
#[cfg(sundials)]
unsafe extern "C" fn cvode_root(
    t: f64,
    y: crate::sundials::NVector,
    gout: *mut f64,
    user_data: *mut core::ffi::c_void,
) -> core::ffi::c_int {
    let ctx = unsafe { &mut *(user_data as *mut ResCtx) };
    match unsafe { eval_roots(ctx, t, crate::sundials::nv_data(y), core::ptr::null(), gout) } {
        Err(err) => {
            ctx.err = Some(err);
            -1
        }
        Ok(()) => 0,
    }
}

/// How many times one interval may be resumed after `CV_TOO_MUCH_WORK` (1000
/// internal steps per call, as in C). C aborts the run instead; resuming continues
/// the same trajectory, it only allows more work.
#[cfg(sundials)]
const CVODE_WORK_RETRIES: u32 = 10_000;

/// Resumable CVODE driver, event-free path. Owns the CVODE memory block across
/// chunks, so an `advance` resumes the exact same continuation.
#[cfg(sundials)]
struct CvodeDriver {
    sim_data: u32,
    n_states: usize,
    nominals: Vec<f64>,
    /// Relative tolerance, for the numerical Jacobian's first step.
    tol: f64,
    states_base: u32,
    ders_base: u32,
    /// Next output row to produce (row 0 was emitted in `new`).
    row: u32,
    /// `None` when the model has no states (nothing to integrate).
    cv: Option<crate::sundials::Cvode>,
    t: f64,
    pivots: Vec<StateSetPivot>,
    rows: Vec<f64>,
    /// Resumes an output interval left unfinished by a work-quota return or a yield.
    work_retries: u32,
    pending_terminate: bool,
    finished: bool,
}

#[cfg(sundials)]
impl CvodeDriver {
    fn new(e: &mut (dyn SimEngine + 'static), model: &SimModel, sim_data: u32) -> Result<Self> {
        let layout = &model.layout;
        run_initialization_model(e, sim_data, model)?;

        let n_states = layout.n_states as usize;
        let states_base = sim_data + REAL_OFF;
        let n_rows = model.n_output_rows();
        let n_reals = layout.n_row_total();
        let start = model.start_time;

        let mut rows: Vec<f64> = Vec::with_capacity((n_rows * n_reals) as usize);
        emit_initial_row(e, &mut rows, sim_data, layout, start)?;
        let pending_terminate = terminated(e, sim_data, layout)?;

        // Dynamic state selection at the initial point, as in `DasslDriver::new`.
        let mut pivots = init_state_pivots(&model.state_sets);
        let mut y = Vec::new();
        if n_states > 0 && !pending_terminate {
            if !model.state_sets.is_empty() && run_state_selection_initial(e, sim_data, &model.state_sets, &mut pivots)? {
                e.call1("functionODE", sim_data)?;
            }
            y = (0..n_states).map(|i| read_f64(e, states_base + (i as u32) * 8)).collect::<Result<_>>()?;
        }

        let tol = if model.tolerance > 0.0 { model.tolerance } else { 1e-6 };
        let nominals = read_state_nominals(e, sim_data, layout)?;
        let (_, atol) = dassl_tolerances(tol, &nominals);
        let cv = if y.is_empty() {
            None
        } else {
            Some(
                crate::sundials::Cvode::new(start, &y, tol, &atol, 0, cvode_rhs, None)
                    .ok_or("CodegenWasmJit: CVODE initialization failed")?,
            )
        };

        Ok(CvodeDriver {
            sim_data,
            n_states,
            nominals,
            tol,
            states_base,
            ders_base: states_base + layout.n_states * 8,
            row: 1,
            cv,
            t: start,
            pivots,
            rows,
            work_retries: 0,
            pending_terminate,
            finished: false,
        })
    }
}

#[cfg(sundials)]
impl Driver for CvodeDriver {
    fn advance(&mut self, e: &mut (dyn SimEngine + 'static), model: &SimModel, budget_ms: f64) -> Result<Advance> {
        if self.finished {
            return Ok(Advance::Done);
        }
        let layout = &model.layout;
        let sim_data = self.sim_data;
        if self.pending_terminate {
            self.pending_terminate = false;
            self.finished = true;
            return Ok(Advance::Terminated);
        }
        let n_rows = model.n_output_rows();
        let n_steps = n_rows - 1;
        let start = model.start_time;
        let stop = model.stop_time;
        let grid = |row: u32| grid_time(row, start, stop, n_steps);
        let deadline = deadline_from(budget_ms);

        // No integration — evaluate outputs on the grid — with no states or an
        // empty time span.
        let Some(cv) = self.cv.as_mut().filter(|_| stop > start) else {
            let mut did_step = false;
            while self.row < n_rows {
                if did_step && past_deadline(deadline) {
                    return Ok(Advance::Running);
                }
                check_alarm()?;
                if cancel_requested() {
                    return Ok(Advance::Cancelled);
                }
                did_step = true;
                let time = if self.row == n_steps { stop } else { grid(self.row) };
                open_assert_window();
                let emitted = emit_row(e, &mut self.rows, sim_data, layout, time, model.stop_time);
                close_assert_window(e, sim_data).and(emitted)?;
                store_operators(e, sim_data, layout)?;
                if terminated(e, sim_data, layout)? {
                    self.finished = true;
                    return Ok(Advance::Terminated);
                }
                self.row += 1;
            }
            self.finished = true;
            return Ok(Advance::Done);
        };

        let n_states = self.n_states;
        let states_base = self.states_base;
        let mut ctx = ResCtx {
            engine: &mut *e as *mut dyn SimEngine,
            sim_data,
            states_base,
            ders_base: self.ders_base,
            n_states,
            nls_fail_off: layout.nls_fail_off,
            nfe: 0,
            zc_off: 0,
            n_zc: 0,
            err: None,
            jac: core::ptr::null(),
            jac_gp: Vec::new(),
            jac_ysave: Vec::new(),
            jac_del: Vec::new(),
            jac_ders: Vec::new(),
            jac_ypsave: Vec::new(),
            nje: 0,
            ext_input: core::ptr::null_mut(),
            ext_apply: None,
            ctx_addr: e.context_addr(),
            err_stage_addr: e.error_stage_addr(),
            nominals: self.nominals.as_ptr(),
            nominal_factor: nominal_factor(),
            tol: self.tol,
            #[cfg(sundials)]
            ida: IdaCtx::default(),
        };
        if !cv.set_user_data(&mut ctx as *mut ResCtx as *mut core::ffi::c_void) {
            return Err("CodegenWasmJit: CVODE setup failed");
        }

        let mut did_step = false;
        let outcome = loop {
            if self.row >= n_rows {
                break Advance::Done;
            }
            if did_step && past_deadline(deadline) {
                break Advance::Running;
            }
            check_alarm()?;
            if cancel_requested() {
                break Advance::Cancelled;
            }
            did_step = true;
            let tout = if self.row == n_steps { stop } else { grid(self.row) };
            // Zero-length final interval: emit the held state rather than step.
            if tout <= self.t {
                for (i, v) in cv.y().iter().enumerate() {
                    write_f64(e, states_base + (i as u32) * 8, *v)?;
                }
                emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time)?;
                self.row += 1;
                continue;
            }
            let stop_reason = cv.step(&mut self.t, tout);
            if let Some(err) = ctx.err.take() {
                return Err(err);
            }
            match stop_reason {
                crate::sundials::Stop::Reached
                | crate::sundials::Stop::Stepped
                | crate::sundials::Stop::Root => {}
                crate::sundials::Stop::Failed(flag)
                    if flag == crate::sundials::CV_TOO_MUCH_WORK && self.work_retries < CVODE_WORK_RETRIES =>
                {
                    self.work_retries += 1;
                    continue;
                }
                crate::sundials::Stop::Failed(_) => return Err("CodegenWasmJit: CVODE failed"),
            }
            self.work_retries = 0;
            for (i, v) in cv.y().iter().enumerate() {
                write_f64(e, states_base + (i as u32) * 8, *v)?;
            }
            open_assert_window();
            let emitted = emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time);
            close_assert_window(e, sim_data).and(emitted)?;
            store_operators(e, sim_data, layout)?;
            if terminated(e, sim_data, layout)? {
                break Advance::Terminated;
            }
            // A state-set switch changes the meaning of the state vector, so
            // re-read it and restart CVODE (see `DasslDriver`).
            if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)? {
                e.call1("functionODE", sim_data)?;
                for i in 0..n_states {
                    cv.y_mut()[i] = read_f64(e, states_base + (i as u32) * 8)?;
                }
                if !cv.reinit(self.t) {
                    return Err("CodegenWasmJit: CVODE re-initialization failed");
                }
            }
            self.row += 1;
        };
        if matches!(outcome, Advance::Done | Advance::Terminated) {
            self.finished = true;
        }
        Ok(outcome)
    }

    fn take_rows(&mut self) -> Vec<f64> {
        core::mem::take(&mut self.rows)
    }

    fn fill_stats(&mut self, _model: &SimModel, stats: &mut SolveStats) {
        if let Some(cv) = self.cv.as_ref() {
            fill_sundials_stats(stats, cv.counters());
        }
    }
}

/// The five run totals every SUNDIALS integrator reports the same way.
#[cfg(sundials)]
fn fill_sundials_stats(stats: &mut SolveStats, c: crate::sundials::Counters) {
    stats.steps = c.steps;
    stats.res_evals = c.rhs_evals;
    stats.jac_evals = c.jac_evals;
    stats.err_test_fails = c.err_test_fails;
    stats.conv_test_fails = c.conv_test_fails;
}

// ===========================================================================
// IDA driver
// ===========================================================================
//
// The real SUNDIALS IDA, configured as `ida_solver.c` does for a model compiled
// without `--daeMode`: the explicit ODE goes to IDA as the residual
// `F(t, y, y') = f(t, y) - y'`, differentiated by a colored numerical FD into
// KLU's sparse iteration matrix (C's default `-idaLS=klu`), with per-state
// nominal-scaled tolerances and IDA's root finding on the zero-crossings. The
// callbacks reach wasm through the same `ResCtx` the DASSL ones use, received as
// IDA's `user_data`.

/// The CSC layout IDA's sparse Jacobian is filled in: the model's sparsity, widened
/// by the diagonal for an ODE model, which `J = ∂F/∂y - cj·I` needs whether or not
/// the pattern carries it (C allocates `nnz + N` and lets `SUNMatScaleIAdd_Sparse`
/// insert what is missing). A DAE-mode residual needs no widening — `∂F/∂y'` is
/// differenced along with `∂F/∂y`.
#[cfg(sundials)]
struct IdaPattern {
    colptr: Vec<crate::sundials::SunIndex>,
    rowidx: Vec<crate::sundials::SunIndex>,
    /// Value index of each column's diagonal entry; empty when not widened.
    diag: Vec<usize>,
    /// `slots[col][k]` is where `rows_by_col[col][k]`'s difference quotient goes.
    slots: Vec<Vec<usize>>,
}

#[cfg(sundials)]
impl IdaPattern {
    fn new(jac: &JacAInfo, widen_diagonal: bool) -> IdaPattern {
        let n = jac.n as usize;
        let mut p = IdaPattern {
            colptr: Vec::with_capacity(n + 1),
            rowidx: Vec::new(),
            diag: Vec::with_capacity(if widen_diagonal { n } else { 0 }),
            slots: Vec::with_capacity(n),
        };
        p.colptr.push(0);
        for col in 0..n {
            let base = p.rowidx.len();
            let mut rows = jac.rows_by_col[col].clone();
            if widen_diagonal {
                rows.push(col as u32);
            }
            rows.sort_unstable();
            rows.dedup();
            let at = |r: u32| base + rows.binary_search(&r).expect("row is in the column");
            if widen_diagonal {
                p.diag.push(at(col as u32));
            }
            p.slots.push(jac.rows_by_col[col].iter().map(|&r| at(r)).collect());
            p.rowidx.extend(rows.iter().map(|&r| r as crate::sundials::SunIndex));
            p.colptr.push(p.rowidx.len() as crate::sundials::SunIndex);
        }
        p
    }

    fn nnz(&self) -> usize {
        self.rowidx.len()
    }
}

/// What `-idaLS` and the model's Jacobian availability settled on, shared by the
/// event-free [`IdaDriver`] and the [`SolverCore`] one.
#[cfg(sundials)]
struct IdaSetup {
    ls: crate::sundials::IdaLs,
    /// Sparsity + coloring for the FD Jacobian; `None` ⇒ IDA's own dense
    /// difference-quotient Jacobian (C's `INTERNALNUMJAC`).
    jac_a: Option<JacAInfo>,
    /// Present exactly when `ls` is KLU.
    pattern: Option<IdaPattern>,
    opts: crate::sundials::IdaOptions,
    /// `SimData` offsets of the differentiated parameters; empty unless
    /// `-idaSensitivity` was given and the model carries them.
    sens_offs: Vec<u32>,
    /// Where `IDAGetSens` deposits `n_sens` values for the next row to capture.
    sens_off: u32,
    sens_scratch: Vec<f64>,
    /// `--daeMode`: the residual and the unknown vector this IDA solves over;
    /// `None` for an explicit ODE.
    dae: Option<Box<DaeSolve>>,
}

/// What the DAE-mode residual and Jacobian need beyond an ODE model's: the shape of
/// `y = [states | algebraic unknowns]` and where each half lives in `SimData`. Boxed
/// so the raw pointer the callbacks reach it through outlives every call.
#[cfg(sundials)]
struct DaeSolve {
    /// `nResidualVars` — also `n_states + alg_offs.len()`.
    n: usize,
    n_states: usize,
    /// Base of `daeModeData->residualVars` in `SimData`.
    res_off: u32,
    /// `SimData` slot of each algebraic unknown (C's `algIndexes`).
    alg_offs: Vec<u32>,
    /// `IDASetId`: 1 for a state, 0 for an algebraic unknown.
    id: Vec<f64>,
}

/// `IDACalcIC` over the algebraic unknowns and every derivative, directed by the
/// step IDA would take next (floored, so a zero step still gives a direction). A
/// failed first attempt is retried with the line search off, as C does.
#[cfg(sundials)]
fn dae_calc_ic(ida: &mut crate::sundials::Ida, t: f64) -> Result<()> {
    let mut h = ida.actual_init_step();
    if h < f64::EPSILON {
        h = f64::EPSILON;
        ida.set_init_step(h);
    }
    if !ida.calc_ic(t + h, true) && !ida.calc_ic(t + h, false) {
        return Err("CodegenWasmJit: IDA could not find consistent initial conditions (IDACalcIC)");
    }
    if !ida.consistent_ic() {
        return Err("CodegenWasmJit: IDAGetConsistentIC failed");
    }
    // C resets the initial step to automatic afterwards.
    ida.set_init_step(0.0);
    Ok(())
}

/// `-idaLS`, defaulting to KLU as `ida_solver.c` does. Without states there is
/// nothing to factorize, so KLU's demand for a pattern does not apply — the driver
/// never steps such a model anyway (a DAE-mode one still has algebraic unknowns).
#[cfg(sundials)]
fn ida_linear_solver(layout: &SimLayout) -> crate::sundials::IdaLs {
    use crate::sundials::IdaLs;
    let ls = match crate::simflags::with_flags(|f| f.ida_ls) {
        Some(crate::simflags::IdaLs::Dense) => IdaLs::Dense,
        Some(crate::simflags::IdaLs::Spgmr) => IdaLs::Spgmr,
        Some(crate::simflags::IdaLs::Spbcg) => IdaLs::Spbcg,
        Some(crate::simflags::IdaLs::Sptfqmr) => IdaLs::Sptfqmr,
        _ => IdaLs::Klu,
    };
    if layout.n_states == 0 && !layout.dae_mode() && ls == IdaLs::Klu { IdaLs::Dense } else { ls }
}

#[cfg(sundials)]
impl IdaSetup {
    fn new(model: &SimModel) -> Result<IdaSetup> {
        use crate::sundials::IdaLs;
        let layout = &model.layout;
        let ls = ida_linear_solver(layout);
        let dae = match layout.dae_mode() {
            false => None,
            true => {
                let info = model.dae.as_ref().ok_or("CodegenWasmJit: DAE-mode model without DAE metadata")?;
                let n_states = layout.n_states as usize;
                let mut id = vec![1.0; n_states];
                id.resize(layout.n_dae_res as usize, 0.0);
                Some(Box::new(DaeSolve {
                    n: layout.n_dae_res as usize,
                    n_states,
                    res_off: layout.dae_res_off,
                    alg_offs: info.alg_offs.clone(),
                    id,
                }))
            }
        };
        // The Krylov solvers assemble no matrix (C pins them to INTERNALNUMJAC).
        // In DAE mode the pattern is the residual Jacobian's, not the ODE `A`'s
        // (which the backend leaves empty there).
        let jac_a = match () {
            _ if ls.matrix_free() || env_var("OMC_WASM_NO_ANALYTIC_JAC").is_some() => None,
            _ if dae.is_some() => model.dae.as_ref().and_then(|d| d.sparsity.clone()),
            _ => model.jac_a.clone(),
        };
        let pattern = match (&jac_a, ls) {
            // C throws here rather than fall back: KLU has nothing to factorize.
            (None, IdaLs::Klu) => return Err(IDA_NO_SPARSE_PATTERN),
            (Some(j), IdaLs::Klu) => Some(IdaPattern::new(j, dae.is_none())),
            _ => None,
        };
        let opts = crate::simflags::with_flags(|f| crate::sundials::IdaOptions {
            max_order: f.max_order,
            max_err_test_fails: f.ida_max_err_test_fails,
            max_nonlin_iters: f.ida_max_nonlin_iters,
            max_conv_fails: f.ida_max_conv_fails,
            nonlin_conv_coef: f.ida_nonlin_conv_coef,
            init_step: f.initial_step_size,
        });
        let sens_offs = match crate::simflags::with_flags(|f| f.ida_sensitivity) {
            true => model.sens_params.clone(),
            false => Vec::new(),
        };
        let n_sens = if sens_offs.is_empty() { 0 } else { layout.n_sens as usize };
        Ok(IdaSetup {
            ls,
            jac_a,
            pattern,
            opts,
            sens_offs,
            sens_off: layout.sens_off,
            sens_scratch: vec![0.0; n_sens],
            dae,
        })
    }

    /// The sensitivities at the point IDA last returned, into the layout's
    /// block for [`capture_row`] to append to the next result row.
    fn store_sens(&mut self, e: &mut dyn SimEngine, sim_data: u32, ida: &mut crate::sundials::Ida) -> Result<()> {
        if self.sens_scratch.is_empty() {
            return Ok(());
        }
        if !ida.sens_values(&mut self.sens_scratch) {
            return Err("CodegenWasmJit: IDAGetSens failed");
        }
        for (i, x) in self.sens_scratch.iter().enumerate() {
            write_f64(e, sim_data + self.sens_off + (i as u32) * 8, *x)?;
        }
        Ok(())
    }

    /// Build the IDA block for `n_roots` zero-crossings, starting from `(t, y, yp)`.
    #[allow(clippy::too_many_arguments)]
    fn build(
        &self,
        e: &mut dyn SimEngine,
        sim_data: u32,
        t: f64,
        y: &[f64],
        yp: &[f64],
        rtol: f64,
        atol: &[f64],
        n_roots: usize,
    ) -> Result<crate::sundials::Ida> {
        let mut ida = crate::sundials::Ida::new(
            t,
            y,
            yp,
            rtol,
            atol,
            n_roots,
            ida_res,
            (n_roots > 0).then_some(ida_root as crate::sundials::IdaRootFn),
            self.ls,
            self.pattern.as_ref().map_or(0, |p| p.nnz()),
            self.jac_a.as_ref().map(|_| ida_jac as crate::sundials::IdaJacFn),
            &self.opts,
        )
        .ok_or("CodegenWasmJit: IDA initialization failed")?;
        if !self.sens_offs.is_empty() {
            let p0: Vec<f64> =
                self.sens_offs.iter().map(|&off| read_f64(e, sim_data + off)).collect::<Result<_>>()?;
            if !ida.init_sensitivities(&p0) {
                return Err("CodegenWasmJit: IDA sensitivity initialization failed");
            }
        }
        if let Some(d) = self.dae.as_deref() {
            let suppress_alg = crate::simflags::with_flags(|f| f.ida_no_suppress_alg);
            if !ida.set_id(&d.id, suppress_alg) {
                return Err("CodegenWasmJit: IDASetId failed");
            }
        }
        Ok(ida)
    }

    /// The DAE-mode unknown vector back into `SimData` (C's `setAlgebraicDAEVars`).
    fn dae_store(&self, e: &mut dyn SimEngine, sim_data: u32, y: &[f64], yp: &[f64]) -> Result<()> {
        let Some(d) = self.dae.as_deref() else { return Ok(()) };
        for i in 0..d.n_states {
            write_f64(e, sim_data + REAL_OFF + (i as u32) * 8, y[i])?;
            write_f64(e, sim_data + REAL_OFF + ((d.n_states + i) as u32) * 8, yp[i])?;
        }
        for (k, &off) in d.alg_offs.iter().enumerate() {
            write_f64(e, sim_data + off, y[d.n_states + k])?;
        }
        Ok(())
    }

    fn ctx(&self, ida: Option<&crate::sundials::Ida>) -> IdaCtx {
        IdaCtx {
            mem: ida.map_or(core::ptr::null_mut(), |i| i.mem()),
            pattern: self.pattern.as_ref().map_or(core::ptr::null(), |p| p as *const IdaPattern),
            sens: match ida.and_then(|i| i.sens_params()) {
                Some(p) => SensPush { offs: self.sens_offs.as_ptr(), values: p.as_ptr(), n: p.len() },
                None => SensPush::default(),
            },
            dae: self.dae.as_deref().map_or(core::ptr::null(), |d| d as *const DaeSolve),
        }
    }
}

#[cfg(sundials)]
const IDA_NO_SPARSE_PATTERN: &str = "CodegenWasmJit: -s=ida with the KLU linear solver needs the model's \
     Jacobian sparsity pattern, which this model has none of (use -idaLS=dense)";

/// The unknown vector into `SimData` without evaluating anything.
#[cfg(sundials)]
unsafe fn ida_push_unknowns(ctx: &mut ResCtx, y: *const f64, yp: *const f64) -> Result<()> {
    let dae = unsafe { ctx.ida.dae.as_ref() };
    let e = unsafe { &mut *ctx.engine };
    let n_states = dae.map_or(ctx.n_states, |d| d.n_states);
    let states = unsafe { core::slice::from_raw_parts(y as *const u8, n_states * 8) };
    e.write_bytes(ctx.states_base, states)?;
    if let Some(d) = dae {
        let ders = unsafe { core::slice::from_raw_parts(yp as *const u8, d.n_states * 8) };
        e.write_bytes(ctx.ders_base, ders)?;
        for (k, &off) in d.alg_offs.iter().enumerate() {
            write_f64(e, ctx.sim_data + off, unsafe { *y.add(d.n_states + k) })?;
        }
    }
    Ok(())
}

/// `F(t, y, y') := f(t, y) - y'`, the residual `residualFunctionIDA` builds outside
/// DAE mode: `t` and the candidate states into `SimData`, the wasm `functionODE`, the
/// derivative slots back out. In DAE mode the model computes the residual itself —
/// `evaluateDAEResiduals` at the dynamic stage leaves `nResidualVars` values behind.
#[cfg(sundials)]
unsafe fn ida_residual(ctx: &mut ResCtx, t: f64, y: *const f64, yp: *const f64, out: *mut f64) -> Result<()> {
    let e = unsafe { &mut *ctx.engine };
    let sens = ctx.ida.sens;
    for i in 0..sens.n {
        write_f64(e, ctx.sim_data + unsafe { *sens.offs.add(i) }, unsafe { *sens.values.add(i) })?;
    }
    if sens.n > 0 {
        e.call1("functionUpdateBoundParameters", ctx.sim_data)?;
    }
    write_f64(e, ctx.sim_data + TIME_OFF, t)?;
    unsafe { ida_push_unknowns(ctx, y, yp) }?;
    if let Some(d) = unsafe { ctx.ida.dae.as_ref() } {
        e.call2(MODEL_FN_DAE, ctx.sim_data, eval_stage::DYNAMIC)?;
        let out_bytes = unsafe { core::slice::from_raw_parts_mut(out as *mut u8, d.n * 8) };
        return e.read_bytes(ctx.sim_data + d.res_off, out_bytes);
    }
    let n = ctx.n_states;
    e.call1("functionODE", ctx.sim_data)?;
    let out_bytes = unsafe { core::slice::from_raw_parts_mut(out as *mut u8, n * 8) };
    e.read_bytes(ctx.ders_base, out_bytes)?;
    for i in 0..n {
        unsafe { *out.add(i) -= *yp.add(i) };
    }
    Ok(())
}

/// `IDAResFn`. A wasm trap is unrecoverable (-1); a non-converging nonlinear
/// system is recoverable (+1), which makes IDA retry from a smaller step.
#[cfg(sundials)]
unsafe extern "C" fn ida_res(
    t: f64,
    yy: crate::sundials::NVector,
    yp: crate::sundials::NVector,
    rr: crate::sundials::NVector,
    user_data: *mut core::ffi::c_void,
) -> core::ffi::c_int {
    let ctx = unsafe { &mut *(user_data as *mut ResCtx) };
    let e = unsafe { &mut *ctx.engine };
    let run = (|| -> Result<()> {
        write_i32(e, ctx.sim_data + ctx.nls_fail_off, 0)?;
        set_context(e, ctx.ctx_addr, CONTEXT_ODE);
        let r = unsafe {
            ida_residual(ctx, t, crate::sundials::nv_data(yy), crate::sundials::nv_data(yp), crate::sundials::nv_data(rr))
        };
        set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
        r
    })();
    ctx.nfe += 1;
    match run {
        Err(err) => {
            ctx.err = Some(err);
            -1
        }
        Ok(()) => {
            if read_i32(e, ctx.sim_data + ctx.nls_fail_off).unwrap_or(0) == 0 {
                return 0;
            }
            report_nls_failure_at(e, ctx.sim_data, ctx.nls_fail_off);
            1
        }
    }
}

/// `IDARootFn`: `gout[i] := g_i(t, y)`. `y'` is unused, as in `rootsFunctionIDA`
/// outside DAE mode.
#[cfg(sundials)]
unsafe extern "C" fn ida_root(
    t: f64,
    yy: crate::sundials::NVector,
    yp: crate::sundials::NVector,
    gout: *mut f64,
    user_data: *mut core::ffi::c_void,
) -> core::ffi::c_int {
    let ctx = unsafe { &mut *(user_data as *mut ResCtx) };
    match unsafe { eval_roots(ctx, t, crate::sundials::nv_data(yy), crate::sundials::nv_data(yp), gout) } {
        Err(err) => {
            ctx.err = Some(err);
            -1
        }
        Ok(()) => 0,
    }
}

/// `IDALsJacFn`: fill `J = ∂F/∂y - cj·I` by a colored numerical FD, one
/// `functionODE` per color — `ida_solver.c`'s `jacoColoredNumericalSparse` and
/// `jacColoredNumericalDense`, which differ only in where an entry lands.
#[cfg(sundials)]
#[allow(clippy::too_many_arguments)]
unsafe extern "C" fn ida_jac(
    t: f64,
    cj: f64,
    yy: crate::sundials::NVector,
    yp: crate::sundials::NVector,
    rr: crate::sundials::NVector,
    j: crate::sundials::SunMatrix,
    user_data: *mut core::ffi::c_void,
    _t1: crate::sundials::NVector,
    _t2: crate::sundials::NVector,
    _t3: crate::sundials::NVector,
) -> core::ffi::c_int {
    let ctx = unsafe { &mut *(user_data as *mut ResCtx) };
    if ctx.jac.is_null() {
        return -1;
    }
    let jac = unsafe { &*ctx.jac };
    let dae = unsafe { ctx.ida.dae.as_ref() };
    let e = unsafe { &mut *ctx.engine };
    let n = dae.map_or(ctx.n_states, |d| d.n);
    let y = crate::sundials::nv_data(yy);
    let ypv = crate::sundials::nv_data(yp);
    let base = crate::sundials::nv_data(rr);
    let h = crate::sundials::ida_current_step(ctx.ida.mem);
    let pattern = unsafe { ctx.ida.pattern.as_ref() };
    let vals = match pattern {
        Some(p) => unsafe {
            let (data, colptr, rowidx) = crate::sundials::sparse_arrays(j);
            core::ptr::copy_nonoverlapping(p.colptr.as_ptr(), colptr, n + 1);
            core::ptr::copy_nonoverlapping(p.rowidx.as_ptr(), rowidx, p.nnz());
            core::slice::from_raw_parts_mut(data, p.nnz())
        },
        None => unsafe { core::slice::from_raw_parts_mut(crate::sundials::dense_data(j), n * n) },
    };
    ctx.jac_gp.resize(n, 0.0);
    ctx.nje += 1;
    set_context(e, ctx.ctx_addr, CONTEXT_JACOBIAN);
    let run = (|| -> Result<()> {
        for color in &jac.colors {
            for &col in color {
                let ci = col as usize;
                let yi = unsafe { *y.add(ci) };
                let hyp = h * unsafe { *ypv.add(ci) };
                let nom = unsafe { *ctx.nominals.add(ci) };
                let mut del = fd_step(yi, hyp, ctx.tol, nom, ctx.nominal_factor);
                del = yi + del - yi; // floating-point rounding, as in the C runtime
                ctx.jac_ysave[ci] = yi;
                ctx.jac_del[ci] = del;
                unsafe { *y.add(ci) = yi + del };
                // In DAE mode the same difference carries `cj·∂F/∂y'`, so there is
                // no `-cj·I` term to add afterwards.
                if dae.is_some() {
                    ctx.jac_ypsave[ci] = unsafe { *ypv.add(ci) };
                    unsafe { *ypv.add(ci) += cj * del };
                }
            }
            write_i32(e, ctx.sim_data + ctx.nls_fail_off, 0)?;
            // Detached so the residual can borrow `ctx`; same buffer.
            let mut gp = core::mem::take(&mut ctx.jac_gp);
            let r = unsafe { ida_residual(ctx, t, y, ypv, gp.as_mut_ptr()) };
            ctx.jac_gp = gp;
            r?;
            for &col in color {
                let ci = col as usize;
                let del = ctx.jac_del[ci];
                for (k, &row) in jac.rows_by_col[ci].iter().enumerate() {
                    let ri = row as usize;
                    let d = ctx.jac_gp[ri] - unsafe { *base.add(ri) };
                    vals[match pattern {
                        Some(p) => p.slots[ci][k],
                        None => ci * n + ri,
                    }] = d / del;
                }
                unsafe { *y.add(ci) = ctx.jac_ysave[ci] };
                if dae.is_some() {
                    unsafe { *ypv.add(ci) = ctx.jac_ypsave[ci] };
                }
            }
        }
        // -cj·∂F/∂y' = -cj·I, the diagonal the ∂F/∂y difference does not carry.
        if dae.is_none() {
            for col in 0..n {
                vals[pattern.map_or(col * n + col, |p| p.diag[col])] -= cj;
            }
        }
        // Restore the base point; the last colour left a perturbed one.
        unsafe { ida_push_unknowns(ctx, y, ypv) }
    })();
    set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
    match run {
        Err(err) => {
            ctx.err = Some(err);
            -1
        }
        Ok(()) => 0,
    }
}

/// How many times one interval may be resumed after `IDA_TOO_MUCH_WORK` (IDA's
/// 500 internal steps per call). C warns and calls `IDASolve` again with no
/// limit; resuming continues the same trajectory, this only bounds it.
#[cfg(sundials)]
const IDA_WORK_RETRIES: u32 = 10_000;

/// Resumable IDA driver, event-free path. [`CvodeDriver`] with `y'` carried
/// alongside `y`, IDA needing a consistent derivative at every restart.
#[cfg(sundials)]
struct IdaDriver {
    sim_data: u32,
    n_states: usize,
    nominals: Vec<f64>,
    /// Relative tolerance, for the numerical Jacobian's first step.
    tol: f64,
    states_base: u32,
    ders_base: u32,
    /// Next output row to produce (row 0 was emitted in `new`).
    row: u32,
    /// `None` when the model has no states (nothing to integrate).
    ida: Option<crate::sundials::Ida>,
    setup: IdaSetup,
    t: f64,
    pivots: Vec<StateSetPivot>,
    rows: Vec<f64>,
    /// Resumes an output interval left unfinished by a work-quota return or a yield.
    work_retries: u32,
    /// `-noEquidistantOutput{Frequency,Time}` over IDA's own steps.
    step_emit: StepEmit,
    /// C's degenerate first `-noEquidistantTimeGrid` iteration has been emitted.
    no_grid_primed: bool,
    pending_terminate: bool,
    finished: bool,
}

#[cfg(sundials)]
impl IdaDriver {
    fn new(e: &mut (dyn SimEngine + 'static), model: &SimModel, sim_data: u32) -> Result<Self> {
        let layout = &model.layout;
        let setup = IdaSetup::new(model)?;
        run_initialization_model(e, sim_data, model)?;

        let n_states = layout.n_states as usize;
        let states_base = sim_data + REAL_OFF;
        let ders_base = states_base + layout.n_states * 8;
        let n_rows = model.n_output_rows();
        let n_reals = layout.n_row_total();
        let start = model.start_time;

        let mut rows: Vec<f64> = Vec::with_capacity((n_rows * n_reals) as usize);
        emit_initial_row(e, &mut rows, sim_data, layout, start)?;
        let pending_terminate = terminated(e, sim_data, layout)?;

        // Dynamic state selection at the initial point, as in `DasslDriver::new`.
        // For an explicit ODE the consistent `y'` is f(t0, y0), which the row above
        // has already left in the derivative slots.
        let mut pivots = init_state_pivots(&model.state_sets);
        let (mut y, mut yp) = (Vec::new(), Vec::new());
        if n_states > 0 && !pending_terminate {
            if !model.state_sets.is_empty() && run_state_selection_initial(e, sim_data, &model.state_sets, &mut pivots)? {
                e.call1("functionODE", sim_data)?;
            }
            y = (0..n_states).map(|i| read_f64(e, states_base + (i as u32) * 8)).collect::<Result<_>>()?;
            yp = (0..n_states).map(|i| read_f64(e, ders_base + (i as u32) * 8)).collect::<Result<_>>()?;
        }

        let tol = if model.tolerance > 0.0 { model.tolerance } else { 1e-6 };
        let nominals = read_state_nominals(e, sim_data, layout)?;
        let (_, atol) = dassl_tolerances(tol, &nominals);
        let ida = if y.is_empty() {
            None
        } else {
            Some(setup.build(e, sim_data, start, &y, &yp, tol, &atol, 0)?)
        };

        Ok(IdaDriver {
            sim_data,
            n_states,
            nominals,
            tol,
            states_base,
            ders_base,
            row: 1,
            ida,
            setup,
            t: start,
            pivots,
            rows,
            work_retries: 0,
            step_emit: StepEmit::new(),
            no_grid_primed: false,
            pending_terminate,
            finished: false,
        })
    }
}

#[cfg(sundials)]
impl Driver for IdaDriver {
    fn advance(&mut self, e: &mut (dyn SimEngine + 'static), model: &SimModel, budget_ms: f64) -> Result<Advance> {
        if self.finished {
            return Ok(Advance::Done);
        }
        let layout = &model.layout;
        let sim_data = self.sim_data;
        if self.pending_terminate {
            self.pending_terminate = false;
            self.finished = true;
            return Ok(Advance::Terminated);
        }
        let n_rows = model.n_output_rows();
        let n_steps = n_rows - 1;
        let start = model.start_time;
        let stop = model.stop_time;
        let grid = |row: u32| grid_time(row, start, stop, n_steps);
        let deadline = deadline_from(budget_ms);
        // `-noEquidistantTimeGrid`: one interval spans the run, rows come from the
        // one-step returns below (`ida_solver.c`'s `idaSmode`).
        let no_grid = no_equidistant_grid() && self.n_states > 0 && stop > start;
        let n_rows = if no_grid { 2 } else { n_rows };
        if no_grid && !self.no_grid_primed {
            self.no_grid_primed = true;
            emit_row(e, &mut self.rows, sim_data, layout, self.t, stop)?;
        }

        // No integration — evaluate outputs on the grid — with no states or an
        // empty time span.
        let Some(ida) = self.ida.as_mut().filter(|_| stop > start) else {
            let mut did_step = false;
            while self.row < n_rows {
                if did_step && past_deadline(deadline) {
                    return Ok(Advance::Running);
                }
                check_alarm()?;
                if cancel_requested() {
                    return Ok(Advance::Cancelled);
                }
                did_step = true;
                let time = if self.row == n_steps { stop } else { grid(self.row) };
                open_assert_window();
                let emitted = emit_row(e, &mut self.rows, sim_data, layout, time, model.stop_time);
                close_assert_window(e, sim_data).and(emitted)?;
                store_operators(e, sim_data, layout)?;
                if terminated(e, sim_data, layout)? {
                    self.finished = true;
                    return Ok(Advance::Terminated);
                }
                self.row += 1;
            }
            self.finished = true;
            return Ok(Advance::Done);
        };

        let n_states = self.n_states;
        let states_base = self.states_base;
        let mut ctx = ResCtx {
            engine: &mut *e as *mut dyn SimEngine,
            sim_data,
            states_base,
            ders_base: self.ders_base,
            n_states,
            nls_fail_off: layout.nls_fail_off,
            nfe: 0,
            zc_off: 0,
            n_zc: 0,
            err: None,
            jac: self.setup.jac_a.as_ref().map_or(core::ptr::null(), |j| j as *const JacAInfo),
            jac_gp: Vec::new(),
            jac_ysave: vec![0.0; n_states],
            jac_del: vec![0.0; n_states],
            jac_ders: Vec::new(),
            jac_ypsave: Vec::new(),
            nje: 0,
            ext_input: core::ptr::null_mut(),
            ext_apply: None,
            ctx_addr: e.context_addr(),
            err_stage_addr: e.error_stage_addr(),
            nominals: self.nominals.as_ptr(),
            nominal_factor: nominal_factor(),
            tol: self.tol,
            ida: self.setup.ctx(Some(ida)),
        };
        if !ida.set_user_data(&mut ctx as *mut ResCtx as *mut core::ffi::c_void) {
            return Err("CodegenWasmJit: IDA setup failed");
        }

        let mut did_step = false;
        let outcome = loop {
            if self.row >= n_rows {
                break Advance::Done;
            }
            if did_step && past_deadline(deadline) {
                break Advance::Running;
            }
            check_alarm()?;
            if cancel_requested() {
                break Advance::Cancelled;
            }
            did_step = true;
            let tout = if no_grid || self.row == n_steps { stop } else { grid(self.row) };
            // Zero-length final interval: emit the held state rather than step.
            if tout <= self.t {
                for (i, v) in ida.y().iter().enumerate() {
                    write_f64(e, states_base + (i as u32) * 8, *v)?;
                }
                emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time)?;
                self.row += 1;
                continue;
            }
            let stop_reason = ida.step(&mut self.t, tout, no_grid);
            if let Some(err) = ctx.err.take() {
                return Err(err);
            }
            let stepped = matches!(stop_reason, crate::sundials::Stop::Stepped);
            match stop_reason {
                crate::sundials::Stop::Reached
                | crate::sundials::Stop::Stepped
                | crate::sundials::Stop::Root => {}
                crate::sundials::Stop::Failed(flag)
                    if flag == crate::sundials::IDA_TOO_MUCH_WORK && self.work_retries < IDA_WORK_RETRIES =>
                {
                    self.work_retries += 1;
                    continue;
                }
                crate::sundials::Stop::Failed(_) => return Err("CodegenWasmJit: IDA failed"),
            }
            self.work_retries = 0;
            // One-step mode: the step that just ended is an output point of its own
            // and `tout` is still ahead.
            if stepped {
                if self.step_emit.take(self.t) {
                    self.setup.store_sens(e, sim_data, ida)?;
                    for (i, v) in ida.y().iter().enumerate() {
                        write_f64(e, states_base + (i as u32) * 8, *v)?;
                    }
                    open_assert_window();
                    let emitted =
                        emit_row(e, &mut self.rows, sim_data, layout, self.t, model.stop_time);
                    close_assert_window(e, sim_data).and(emitted)?;
                    store_operators(e, sim_data, layout)?;
                    if terminated(e, sim_data, layout)? {
                        break Advance::Terminated;
                    }
                }
                continue;
            }
            self.setup.store_sens(e, sim_data, ida)?;
            for (i, v) in ida.y().iter().enumerate() {
                write_f64(e, states_base + (i as u32) * 8, *v)?;
            }
            open_assert_window();
            let emitted = emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time);
            close_assert_window(e, sim_data).and(emitted)?;
            store_operators(e, sim_data, layout)?;
            if terminated(e, sim_data, layout)? {
                break Advance::Terminated;
            }
            // Restart IDA on the reinitialised states (see `DasslDriver`).
            if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)? {
                for i in 0..n_states {
                    ida.y_mut()[i] = read_f64(e, states_base + (i as u32) * 8)?;
                    ida.yp_mut()[i] = read_f64(e, self.ders_base + (i as u32) * 8)?;
                }
                if !ida.reinit(self.t) {
                    return Err("CodegenWasmJit: IDA re-initialization failed");
                }
            }
            self.row += 1;
        };
        if matches!(outcome, Advance::Done | Advance::Terminated) {
            self.finished = true;
        }
        Ok(outcome)
    }

    fn take_rows(&mut self) -> Vec<f64> {
        core::mem::take(&mut self.rows)
    }

    fn fill_stats(&mut self, _model: &SimModel, stats: &mut SolveStats) {
        if let Some(ida) = self.ida.as_ref() {
            fill_sundials_stats(stats, ida.counters());
        }
    }
}

// ───────────────────── optimization: the initial guess's stepper ─────────────────────

/// Publish the time the stepper jumped to (the no-state case).
#[cfg(ipopt)]
fn driver_write_time(e: &mut dyn SimEngine, sim_data: u32, t: f64) -> Result<()> {
    write_f64(e, sim_data + TIME_OFF, t)
}

/// C's `smallIntSolverStep` (`optimization/DataManagement/InitialGuess.c`): DASSL
/// stepped to a given time with no event handling and no output rows.
///
/// The optimizer's initial guess is a plain simulation over the collocation grid,
/// so it reuses the integrator the DASSL driver uses without the event/row
/// machinery around it. Lives here because [`SolverCore`] and its residual context
/// are private to this module.
#[cfg(ipopt)]
pub(crate) struct GuessStepper {
    core: SolverCore,
    /// `-csvInput`'s hook, applied at every residual evaluation like C's.
    ext: Option<*mut core::ffi::c_void>,
}

#[cfg(ipopt)]
impl GuessStepper {
    /// The model is already initialized (the optimizer's caller did that), so this
    /// only sizes the integrator and latches the current point as `y`/`y'`.
    pub(crate) fn new(
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        sim_data: u32,
        t0: f64,
    ) -> Result<Self> {
        daskr::auxiliary::xsetf(0); // DASKR's own printing would corrupt the log
        let mut core = SolverCore::new(e, model, sim_data, t0, "dassl", None)?;
        core.read_states(e)?;
        Ok(GuessStepper { core, ext: None })
    }

    /// Install `-csvInput`'s external-input hook (a `*mut ExtInputHook`, kept alive
    /// by the caller for as long as this stepper is used).
    pub(crate) fn set_external_input(&mut self, hook: *mut core::ffi::c_void) {
        self.ext = Some(hook);
    }

    pub(crate) fn time(&self) -> f64 {
        self.core.t
    }

    /// Integrate to `tstop` and publish the point, ending with C's
    /// `updateContinuousSystem`. A solver failure is retried from the current time
    /// with a halved target, as C halves its step size, up to 10 times.
    pub(crate) fn step_to(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        tstop: f64,
    ) -> Result<()> {
        let layout = &model.layout;
        // C's `smallIntSolverStep` steps the integrator only when there is a state to
        // integrate: with none it jumps straight to `tstop` and re-evaluates. DASKR
        // with `NEQ = 0` would `STOP` inside its Fortran, taking omc down with it.
        if layout.n_states == 0 {
            self.core.t = tstop;
            driver_write_time(e, self.core.sim_data, tstop)?;
            return eval_continuous(e, self.core.sim_data, layout);
        }
        let mut ctx = self.core.res_ctx(e, layout);
        if let Some(hook) = self.ext {
            ctx.ext_input = hook;
            ctx.ext_apply = Some(crate::optimization::EXT_INPUT_APPLY);
        }
        let _guard = ResCtxGuard;
        RES_CTX.store(&mut ctx as *mut ResCtx, Ordering::Relaxed);
        let mut did_step = false;
        let mut iter = 0;
        let mut frac = 1.0;
        while self.core.t < tstop {
            let target = self.core.t + frac * (tstop - self.core.t);
            match self.core.solve_toward(target, &mut ctx, f64::INFINITY, &mut did_step) {
                // A root is not an event here: C's initial guess does not locate
                // events, it just keeps integrating toward `tstop`.
                Ok(Solved::Reached | Solved::Stepped | Solved::Root | Solved::Yielded) => {
                    frac = 1.0;
                }
                Ok(Solved::Cancelled) => return Err("CodegenWasmJit: simulation cancelled"),
                Err(err) => {
                    iter += 1;
                    if iter > 10 {
                        omclog::warning(
                            omclog::STDOUT,
                            false,
                            &format!(
                                "Initial guess failure at time {}",
                                format_g(self.core.t, 12)
                            ),
                        );
                        return Err(err);
                    }
                    frac *= 0.5;
                }
            }
        }
        self.core.write_states(e)?;
        // C's `dassl_step` publishes the accepted time before `updateContinuousSystem`.
        driver_write_time(e, self.core.sim_data, self.core.t)?;
        eval_continuous(e, self.core.sim_data, layout)
    }
}
