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

use crate::omclog;
use crate::rtclock;
use crate::simflags::JacobianMethod;
#[cfg(sundials)]
use crate::simflags::{CvodeIter, CvodeLmm};
use crate::sync::SYNC_EPS;
use crate::{
    DaeInfo, JacAInfo, Layout as SimLayout, MetaKind as ResultKind, REAL_OFF, SimMeta, SolveStats, StateSetInfo,
    TIME_OFF,
    WTy,
};

/// The driver's error type. Was `metamodelica::Result`; the driver is `no_std`
/// (it compiles into the runtime wasm) so it can't depend on the compiler crates.
pub type Result<T> = core::result::Result<T, &'static str>;

// Moved to `openmodelica_solvers`, which the solvers themselves use; re-exported
// so `driver::format_g` and the rest keep naming them.
pub use openmodelica_solvers::{
    LogSink, MINIMAL_STEP_SIZE, format_e, format_g, log_line, log_sink_is_stdout, set_log_sink,
    set_log_sink_is_stdout,
};
pub(crate) use openmodelica_solvers::bisection_iterations;

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
/// `stateSelectionSet`): evaluate the analytic Jacobian column-by-column via
/// `functionStateSetJacobians`, pivot to choose the dummy columns, and — if the
/// selection changed and `switch` — rebuild the `A` matrix and reinit the state
/// variables from their candidates (`setAMatrix`). Returns whether the selection
/// changed (the caller restarts the integrator, as a state change is a
/// discontinuity in the state vector). Without `switch` the pivots are put back
/// as they were, so the change is only reported.
fn state_selection_set(
    e: &mut dyn SimEngine,
    sim_data: u32,
    info: &StateSetInfo,
    st: &mut StateSetPivot,
    set_index: usize,
    report_error: bool,
    switch: bool,
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
    let old_row = st.row_pivot.clone();
    if !pivot(&mut jac, nd, nc, &mut st.row_pivot, &mut st.col_pivot) && report_error {
        log_state_set_jacobian(omclog::WARNING, omclog::DSS, info, &jac, set_index);
        let t = read_f64(e, sim_data + TIME_OFF)?;
        omclog::error!(
            omclog::STDOUT,
            false,
            "Error, singular Jacobian for dynamic state selection at time {t:.6}\nUse -lv LOG_DSS_JAC to get the Jacobian",
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
    if changed && switch {
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
            omclog::info!(omclog::DSS, true, "StateSelection Set {set_index} at time = {t:.6}");
            print_state_selection_info(e, sim_data, info)?;
            omclog::close(omclog::DSS);
        }
    }
    if !switch {
        st.col_pivot = old_col;
        st.row_pivot = old_row;
    }
    Ok(changed)
}

/// C's `printStateSelectionInfo`.
fn print_state_selection_info(e: &mut dyn SimEngine, sim_data: u32, info: &StateSetInfo) -> Result<()> {
    let nc = info.n_candidates as usize;
    let ns = info.n_states as usize;
    let name = |i: usize| info.candidate_names.get(i).map(String::as_str).unwrap_or("?");
    let plural = if ns == 1 { "" } else { "s" };
    omclog::info!(omclog::DSS, false, "Select {ns} state{plural} from {nc} candidates.");
    omclog::info(omclog::DSS, true, "State candidates:");
    for k in 0..nc {
        omclog::info!(omclog::DSS, false, "[{}] {}", k + 1, name(k));
    }
    omclog::close(omclog::DSS);
    omclog::info!(omclog::DSS, true, "Selected state{plural}");
    for row in 0..ns {
        for col in 0..nc {
            if read_i32(e, sim_data + info.a_offs[row * nc + col])? == 1 {
                omclog::info!(omclog::DSS, false, "[{}] {}", col + 1, name(col));
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

/// C's `data->simulationInfo->stateSetData` pivoting, carried across a run: every
/// driver, and the FMI component the importer integrates, holds one.
pub struct StateSelection {
    pivots: Vec<StateSetPivot>,
}

impl StateSelection {
    /// The identity selection, before any pivoting.
    pub fn new(model: &SimMeta) -> Self {
        StateSelection { pivots: init_state_pivots(&model.state_sets) }
    }

    /// C's `initialization()` tail: pivot once on the resolved initial point, before
    /// the first result row is emitted. C runs `stateSelection` there and `solver_main`
    /// emits row 0 afterwards, so a model whose initial selection differs from the
    /// identity has the *selected* states in that row. A switch reinits the state
    /// variables from their candidates, so the derivatives are refreshed after it.
    ///
    /// The first pass does not report a singular Jacobian, and only a second switch
    /// in a row warns.
    pub fn initial(e: &mut dyn SimEngine, sim_data: u32, model: &SimMeta) -> Result<Self> {
        let mut sel = StateSelection::new(model);
        if model.state_sets.is_empty() {
            return Ok(sel);
        }
        if sel.run(e, sim_data, model, false, true)? {
            if sel.reselect(e, sim_data, model)? {
                omclog::warning(
                    omclog::STDOUT,
                    false,
                    "Cannot initialize the dynamic state selection in an unique way. Use -lv LOG_DSS to see the switching state set.",
                );
            }
            e.call1("functionODE", sim_data)?;
        }
        Ok(sel)
    }

    /// C's `stateSelection(data, threadData, 1, 1)`: select and switch, returning
    /// whether any set changed — the caller restarts the integrator.
    pub fn reselect(&mut self, e: &mut dyn SimEngine, sim_data: u32, model: &SimMeta) -> Result<bool> {
        self.run(e, sim_data, model, true, true)
    }

    /// C's `stateSelection(data, threadData, 1, 0)`: whether the selection *would*
    /// change here, leaving it as it is. The switch belongs to the event update that
    /// follows.
    pub fn would_change(&mut self, e: &mut dyn SimEngine, sim_data: u32, model: &SimMeta) -> Result<bool> {
        self.run(e, sim_data, model, true, false)
    }

    fn run(
        &mut self,
        e: &mut dyn SimEngine,
        sim_data: u32,
        model: &SimMeta,
        report_error: bool,
        switch: bool,
    ) -> Result<bool> {
        let mut changed = false;
        for (i, (info, st)) in model.state_sets.iter().zip(self.pivots.iter_mut()).enumerate() {
            changed |= state_selection_set(e, sim_data, info, st, i, report_error, switch)?;
        }
        Ok(changed)
    }
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
    "functionOutputs",
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
    "functionAttrDefaults",
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
    "functionJacA_constantEqns",
    "functionJacA_column",
    "functionDAE",
    "reconJacF",
    "reconJacH",
    "symbolicInlineSystem",
    "functionLocalKnownVars",
    "parmodTask",
    "functionInputVars",
    "functionOutputVars",
    "functionReconInputs",
    "functionReconSetC",
    "functionReconSetB",
];

/// The clock a model entry point runs under, where `CodegenC.tpl` ticks one inside
/// the generated function of the same name. `None` leaves the call unmeasured, as
/// every entry point is once the clocks are off.
fn model_fn_clock(name: &str) -> Option<usize> {
    if !rtclock::enabled() {
        return None;
    }
    match name {
        "functionODE" => Some(rtclock::FUNCTION_ODE),
        "functionAlgebraics" => Some(rtclock::ALGEBRAICS),
        "functionZeroCrossings" => Some(rtclock::ZC),
        "functionZeroCrossingsEquations" => Some(rtclock::ZC_EQUATIONS),
        _ => None,
    }
}

/// The model entry points that are not `fn(SimData*)`: `--daeMode`'s residual
/// takes the evaluation stage as a second argument (C's `currentEvalStage`), the
/// two synchronous dispatchers take a clock index, and the crossing function takes
/// where to put its g-values (C's `gout`).
pub const MODEL_FN_DAE: &str = "evaluateDAEResiduals";
pub const MODEL_FN_UPDATE_SYNC: &str = "functionUpdateSynchronous";
pub const MODEL_FN_EQS_SYNC: &str = "functionEquationsSynchronous";
pub const MODEL_FN_ZC: &str = "functionZeroCrossings";

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
    fn call1_raw(&mut self, name: &str, arg: u32) -> Result<()>;
    /// Like [`SimEngine::call1_raw`] but a no-op if `name` is not exported (optional
    /// teardown hooks such as `callExternalObjectDestructors`).
    fn call1_if_present_raw(&mut self, name: &str, arg: u32) -> Result<()>;
    /// Call the exported `fn(u32, u32) -> ()` `name` — only [`MODEL_FN_DAE`],
    /// whose second argument is the evaluation stage.
    fn call2_raw(&mut self, name: &str, a: u32, b: u32) -> Result<()>;
    /// Install `mask` as the active log streams of the runtime the model links, whose
    /// solvers log from inside it. A no-op where that runtime's store is this one.
    fn set_log_mask(&mut self, _mask: omclog::Mask) {}
    /// [`SimEngine::call1_raw`] under the clock C's generated entry point ticks
    /// around its own body ([`model_fn_clock`]); every driver goes through here.
    fn call1(&mut self, name: &str, arg: u32) -> Result<()> {
        let parmod = name == "functionODE" && crate::parmod::active();
        let Some(ix) = model_fn_clock(name) else {
            return if parmod { self.call_parmod_ode(arg) } else { self.call1_raw(name, arg) };
        };
        rtclock::tick(ix);
        let out = if parmod { self.call_parmod_ode(arg) } else { self.call1_raw(name, arg) };
        rtclock::accumulate(ix);
        out
    }
    /// C's `functionODE` under `--parmodauto`: the scheduler decides between the
    /// sequential entry point and the per-task `parmodTask(sim_data, task)`.
    fn call_parmod_ode(&mut self, sim_data: u32) -> Result<()> {
        use crate::parmod::Op;
        crate::parmod::evaluate_ode(&mut |op| match op {
            Op::All => self.call1_raw("functionODE", sim_data),
            Op::LocalKnown => self.call1_if_present_raw("functionLocalKnownVars", sim_data),
            Op::Task(k) => self.call2_raw("parmodTask", sim_data, k),
        })
    }
    fn call1_if_present(&mut self, name: &str, arg: u32) -> Result<()> {
        let Some(ix) = model_fn_clock(name) else { return self.call1_if_present_raw(name, arg) };
        rtclock::tick(ix);
        let out = self.call1_if_present_raw(name, arg);
        rtclock::accumulate(ix);
        out
    }
    fn call2(&mut self, name: &str, a: u32, b: u32) -> Result<()> {
        // `functionZeroCrossings` takes `gout`, so it lands here rather than in
        // [`SimEngine::call1`]; C clocks it just the same.
        let ix = model_fn_clock(name).or((name == MODEL_FN_DAE).then_some(rtclock::DAE));
        let Some(ix) = ix else { return self.call2_raw(name, a, b) };
        rtclock::tick(ix);
        let out = self.call2_raw(name, a, b);
        rtclock::accumulate(ix);
        out
    }
    /// Call the exported `simulate(sim_data, start, stop, n_steps) -> buf`, the
    /// in-wasm Euler driver; returns the result-buffer pointer.
    fn call_simulate(&mut self, sim_data: u32, start: f64, stop: f64, n_steps: u32) -> Result<u32>;
    /// Whether [`SimEngine::call_simulate`] is a model export rather than an error:
    /// the emitted module's own fixed-step loop, which saves a host call per step.
    /// A backend whose model is not a wasm module has none, and takes the ordinary
    /// driver instead.
    fn has_simulate_entry(&mut self) -> bool {
        false
    }
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
    /// The String at a string slot (`str_off`/`sparam_off` region). Default: the
    /// slot holds a handle into the runtime's String heap.
    fn string_at(&self, addr: u32) -> Result<String> {
        let mut b = [0u8; 4];
        self.read_bytes(addr, &mut b)?;
        let handle = i32::from_le_bytes(b);
        if handle == 0 {
            return Ok(String::new());
        }
        // An address past 2 GiB is a negative `i32`; wasm pointers are unsigned.
        let base = handle as u32;
        self.read_bytes(base + 4, &mut b)?;
        let mut buf = vec![0u8; i32::from_le_bytes(b).max(0) as usize];
        self.read_bytes(base + 8, &mut buf)?;
        Ok(String::from_utf8_lossy(&buf).into_owned())
    }
    /// C's `samplesInfo[k].index`, the number the `LOG_EVENTS` time-event line
    /// shows, where the runtime keeps it beside the model rather than in the
    /// metadata. Default: not here.
    fn sample_index(&self, _k: usize) -> Option<i32> {
        None
    }
    /// C's `updateStaticDataOf{Linear,Nonlinear}Systems`: refresh each system's
    /// `nominal`/`min`/`max` from the attributes once those are final. A wasm model
    /// reads the attributes live and has nothing to do. Default: nothing.
    fn update_static_system_data(&mut self, _linear: bool) {}
    /// Whether the model itself reported a violated `assert()` inside the current
    /// `noThrowAsserts` window and carried on (C's `needToReThrow`). A model that
    /// hands its violations back through [`take_pending_warnings`] leaves this
    /// false. Default: false.
    fn take_noted_assert(&mut self) -> bool {
        false
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
    /// Whether the host runs C's `initializeLinearSystems` /
    /// `initializeNonlinearSystems` itself, and so has already announced them.
    fn host_logs_system_init(&self) -> bool {
        false
    }
    /// The `terminate()` message and its `printInfo` position, for a backend that
    /// keeps them outside `SimData` (the C runtime's `TermMsg` / `TermInfo`).
    fn terminate_info(&self) -> Option<TerminateInfo> {
        None
    }
    /// Whether the model's own `functionUpdateBoundVariableAttributes` prints C's
    /// `updating <attribute>-values` block. The wasm codegen leaves it to
    /// [`log_bound_attr_updates`]; the C code generator emits it.
    fn model_logs_bound_attrs(&self) -> bool {
        false
    }
    /// The `printf` frame `-l` fills, where the model owns it rather than the
    /// metadata: C's `linear_model_frame()`, which prints its own diagnostic when
    /// linearization is disabled. `None` means [`crate::LinInfo::frame`] holds it.
    fn lin_frame(&mut self, _datarec: bool) -> Option<String> {
        None
    }
    /// The per-system solver statistics the runtime recorded for `LOG_STATS_V`
    /// (`rt_sys_stats_ptr`). Default: none — a backend with no runtime to ask.
    fn sys_stats(&mut self) -> Vec<crate::sysstat::SysStat> {
        Vec::new()
    }
    /// Address of the runtime's evaluation context, or 0 when the backend has no
    /// such export.
    fn context_addr(&mut self) -> u32 {
        0
    }
    /// The runtime's `rt_prof_row` / `rt_prof_dump` (see `profiling`): the address
    /// of the profiling clocks' step row and run totals, 0 without the export.
    fn prof_row(&mut self) -> u32 {
        0
    }
    fn prof_dump(&mut self) -> u32 {
        0
    }
    /// The runtime's `rt_prof_clear`: C's `rt_clear` over every profiling clock, so
    /// the step's share joins the run's totals. The clocks live in the runtime
    /// module, not the model's, hence an engine hook rather than a call by name.
    fn prof_clear(&mut self) {}
    /// The runtime's `rt_prof_init`: C's `rt_init` for the `n` function and block
    /// clocks, at the head of a profiled run.
    fn prof_init(&mut self, n: u32) {
        let _ = n;
    }
    /// Address of the runtime's error stage / absorbed-error pair, or 0 when the
    /// backend has no such export.
    fn error_stage_addr(&mut self) -> u32 {
        0
    }
    /// Address of the runtime's `noThrowDivZero` word, or 0 when the backend has no
    /// such export.
    fn no_throw_div_zero_addr(&mut self) -> u32 {
        0
    }
    /// C's `cleanUpOldValueListAfterEvent`. Default: none (an engine that never
    /// integrates).
    fn clean_nls_history(&mut self, _time: f64) {}
    /// C's `RHSFinalFlag` (`dassl.c`): 0 while DASKR evaluates the residual, 1
    /// while the accepted step's outputs are evaluated, for `external "C"` to read.
    fn set_rhs_final(&mut self, _final_eval: bool) {}
    /// Assign a runtime String holding `bytes` to the String-handle slot at `addr`,
    /// releasing what was there. Only an `-override` of a String parameter needs it.
    fn set_string(&mut self, _addr: u32, _bytes: &[u8]) -> Result<()> {
        Err("CodegenWasmJit: this backend cannot set a String")
    }
}

/// C's `EVAL_CONTEXT`, mirrored from the runtime's `nls.rs`. `unsetContext` restores
/// to `ALGEBRAIC`, not `UNKNOWN`.
pub const CONTEXT_ODE: i32 = 1;
pub const CONTEXT_ALGEBRAIC: i32 = 2;
pub const CONTEXT_EVENTS: i32 = 3;
pub const CONTEXT_JACOBIAN: i32 = 4;
pub const CONTEXT_SYM_JACOBIAN: i32 = 5;

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
/// C's outer `MMC_TRY_INTERNAL(simulationJumpBuffer)`, held by [`StepRetry`].
pub const ERROR_SIMULATION_STEP: i32 = 3;
/// C's `handleEvents` stage: `getBestJumpBuffer` sends a model error raised here
/// past the step's catch, so it ends the run instead of being retried.
pub const ERROR_EVENTHANDLING: i32 = 4;
/// An exported FMU's try block around one FMI call: it catches as
/// [`ERROR_INTEGRATOR`] does, and reports as [`ERROR_SIMULATION`] does.
pub const ERROR_FMI_CALL: i32 = 5;

/// What a region displaced (C's `saveJumpState`), so regions nest.
#[derive(Clone, Copy, Default)]
pub struct StageSave {
    stage: i32,
    hit: i32,
}

/// Open C's `MMC_TRY_INTERNAL(simulationJumpBuffer)` around an integrator callback: a
/// model error inside it is absorbed rather than trapping, and [`took_error_stage`]
/// reports it. A no-op without the runtime slot, where such an error stays fatal.
fn set_error_stage(e: &mut dyn SimEngine, addr: u32, stage: i32) -> StageSave {
    if addr == 0 {
        return StageSave::default();
    }
    let save =
        StageSave { stage: read_i32(e, addr).unwrap_or(ERROR_SIMULATION), hit: read_i32(e, addr + 4).unwrap_or(0) };
    let _ = write_i32(e, addr, stage);
    let _ = write_i32(e, addr + 4, 0);
    save
}

/// C's `MMC_TRY_INTERNAL(simulationJumpBuffer)` in an exported FMU, whose integrator
/// is the importer's — so the callback is one FMI call.
pub fn open_fmi_call_region(e: &mut dyn SimEngine) -> StageSave {
    let addr = e.error_stage_addr();
    set_error_stage(e, addr, ERROR_FMI_CALL)
}

/// Close it, reporting the absorbed model error the caller answers `IRES = -1` to.
pub fn close_fmi_call_region(e: &mut dyn SimEngine, save: StageSave) -> bool {
    let addr = e.error_stage_addr();
    took_error_stage(e, addr, save)
}

fn stage_hit(e: &dyn SimEngine, addr: u32) -> bool {
    addr != 0 && read_i32(e, addr + 4).unwrap_or(0) != 0
}

fn clear_stage_hit(e: &mut dyn SimEngine, addr: u32) {
    if addr != 0 {
        let _ = write_i32(e, addr + 4, 0);
    }
}

fn mark_stage_hit(e: &mut dyn SimEngine, addr: u32) {
    if addr != 0 {
        let _ = write_i32(e, addr + 4, 1);
    }
}

/// Close the region [`set_error_stage`] opened: put `save` back, and report whether a
/// model error was absorbed in it (C's `success == 0`).
fn took_error_stage(e: &mut dyn SimEngine, addr: u32, save: StageSave) -> bool {
    if addr == 0 {
        return false;
    }
    let hit = read_i32(e, addr + 4).unwrap_or(0) != 0;
    let _ = write_i32(e, addr, save.stage);
    let _ = write_i32(e, addr + 4, save.hit);
    hit
}

/// C's `performSimulation` step guard: the `MMC_TRY_INTERNAL(simulationJumpBuffer)`
/// around one step, the `storeOldValues` snapshot it falls back to, and the `retry`
/// flag. A model error inside the region is recorded by the runtime instead of
/// trapping.
#[derive(Default)]
struct StepRetry {
    /// C's `simulationInfo->{timeValueOld,realVarsOld,integerVarsOld,booleanVarsOld}`.
    time: f64,
    real: Vec<u8>,
    int: Vec<u8>,
    bools: Vec<u8>,
    stored: bool,
    /// C's `retry`: a second throw on the same step ends the run.
    armed: bool,
    /// Output rows as of the step's start, so a step that throws leaves none.
    rows_mark: usize,
    /// The region is open; its close reported a model error absorbed in it.
    in_step: bool,
    threw: bool,
    save: StageSave,
}

impl StepRetry {
    /// Open a step. The rows so far are final: they go to the row sink, if one is
    /// installed, before the mark is taken.
    fn open(&mut self, e: &mut dyn SimEngine, rows: &mut Vec<f64>) {
        commit_rows(rows);
        let addr = e.error_stage_addr();
        self.rows_mark = rows.len();
        self.in_step = true;
        self.threw = false;
        THROW_PAST_STEP.store(false, Ordering::Relaxed);
        self.save = set_error_stage(e, addr, ERROR_SIMULATION_STEP);
    }

    fn close(&mut self, e: &mut dyn SimEngine) -> Result<()> {
        if !self.end(e) {
            return Ok(());
        }
        self.threw = true;
        Err(ASSERT_ERR)
    }

    /// Leave the region, reporting whether a model error was absorbed in it.
    fn end(&mut self, e: &mut dyn SimEngine) -> bool {
        if !core::mem::take(&mut self.in_step) {
            return false;
        }
        let addr = e.error_stage_addr();
        took_error_stage(e, addr, self.save)
    }

    /// C's `storeOldValues`, at the end of every accepted step — where it also
    /// clears `retry`. `simulationUpdate` runs `storePreValues` immediately before
    /// it, so `pre(x)` of a *continuous* variable is the last accepted step's value
    /// (`$_signNoNull($PRE.x + …)` picks a branch of a symbolically solved `abs()`
    /// that way); the two belong together.
    fn store(&mut self, e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
        seed_pre_from_live(e, sim_data, layout)?;
        let regions = [
            (REAL_OFF, layout.real_bytes()),
            (layout.int_off, layout.n_int_alg() as usize * 4),
            (layout.bool_off, layout.n_bool_alg() as usize * 4),
        ];
        for ((off, bytes), buf) in regions.into_iter().zip([&mut self.real, &mut self.int, &mut self.bools]) {
            buf.resize(bytes, 0);
            e.read_bytes(sim_data + off, buf)?;
        }
        self.time = read_f64(e, sim_data + TIME_OFF)?;
        self.stored = true;
        self.armed = false;
        Ok(())
    }

    /// C's `retrySimulationStep`: restore the last accepted point and settle the
    /// discrete system over it. `None` ⇒ the throw ends the run.
    fn undo(&mut self, e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<Option<f64>> {
        // Only a model error the region absorbed reaches C's catch; a rethrown
        // `assert()` is `MMC_THROW_INTERNAL`, which jumps past it.
        let caught = self.end(e) || self.threw || RUNTIME_ERROR.load(Ordering::Relaxed);
        if !caught || THROW_PAST_STEP.load(Ordering::Relaxed) || !self.stored {
            return Ok(None);
        }
        if self.armed {
            // C's catch with `retry` already spent: the run ends here.
            let t = read_f64(e, sim_data + TIME_OFF).unwrap_or(f64::NAN);
            omclog::info!(
                omclog::STDOUT,
                false,
                "model terminate | Simulation terminated by an assert at time: {}",
                format_g(t, 6),
            );
            return Ok(None);
        }
        self.armed = true;
        // The throw is being retried, so nothing downstream may report it.
        clear_runtime_error();
        let _ = e.take_pending_assert();
        write_f64(e, sim_data + TIME_OFF, self.time)?;
        for (off, buf) in
            [(REAL_OFF, &self.real), (layout.int_off, &self.int), (layout.bool_off, &self.bools)]
        {
            if !buf.is_empty() {
                e.write_bytes(sim_data + off, buf)?;
            }
        }
        save_old_real(e, sim_data, layout)?; // C's `overwriteOldSimulationData`
        iterate_discrete(e, sim_data, layout)?;
        omclog::warning(omclog::STDOUT, false, "Integrator attempt to handle a problem with a called assert.");
        Ok(Some(self.time))
    }
}

/// Must match the runtime's `N_STATS`.
pub const RT_STATS: usize = 32;

pub const RT_STAT_NAMES: [&str; RT_STATS] = [
    "alloc", "array_new", "record_new", "str_new", "nls_solve", "nls_res", "nls_jac", "nls_fail", "nls_retry",
    "elem_ptr", "nls_iter", "nls_newton_fail", "nls_guess_hit", "nls_accept", "nls_store_back",
    "nls_vary_start", "nls_stale", "newton_irregular", "newton_lambda", "newton_negstep",
    "newton_maxiter", "newton_stuck", "newton_jac", "newton_singular", "homotopy_steps",
    "free", "alloc_bytes", "free_bytes", "live_rc1", "live_rc2", "live_rcn", "live_maxrc",
];

/// Lambda steps the runtime's locally-continued systems took, part of the same
/// `homotopySteps` the driver's own continuation feeds.
pub const RT_STAT_HOMOTOPY_STEPS: usize = 24;

/// Read a runtime String heap value (`[refcount:u32][len:u32][utf8]`, handle at
/// its base; `0` is null) into a Rust `String`.
fn read_rt_string(e: &dyn SimEngine, handle: i32) -> Result<String> {
    if handle == 0 {
        return Ok(String::new());
    }
    // An address past 2 GiB is a negative `i32`; wasm pointers are unsigned.
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

/// C's `getBestJumpBuffer`: a model error raised under `ERROR_EVENTHANDLING` goes to
/// `globalJumpBuffer`, past `performSimulation`'s per-step catch, so the step is not
/// retaken.
static THROW_PAST_STEP: core::sync::atomic::AtomicBool = core::sync::atomic::AtomicBool::new(false);

fn note_throw_past_step() {
    THROW_PAST_STEP.store(true, Ordering::Relaxed);
}

/// C's `va_throwStreamPrint(NULL, …)`, which an external function's `ModelicaError`
/// reaches: log the message on `LOG_ASSERT` and unwind. It has no condition and no
/// source position, so the trap that follows must not go looking for the assertion
/// block a model `assert()` would have left.
pub fn note_runtime_error(msg: &str) {
    omclog::debug(omclog::ASSERT, false, msg);
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
    THROW_PAST_STEP.store(false, Ordering::Relaxed);
}

/// Cleared per run by [`init_model`].
static INIT_NOTICE_LOGGED: core::sync::atomic::AtomicBool = core::sync::atomic::AtomicBool::new(false);

/// C's notice after an `assert()` violation at initialization. Both the throw site
/// (`sync::init_assert`) and the trap carrying its error out report the failure,
/// and C prints the line once, so the first caller wins.
pub fn log_init_assert_notice() {
    if !INIT_NOTICE_LOGGED.swap(true, Ordering::Relaxed) {
        omclog::info(omclog::ASSERT, false, "simulation terminated by an assertion at initialization");
    }
}

/// The assertion `rt_assert` recorded, as `[msg, file, sline, scol, eline, ecol,
/// read_only, cond, initial]` String handles and flags.
fn assert_info(e: &dyn SimEngine, pa: &[i32; 9]) -> (AssertInfo, String) {
    let info = AssertInfo {
        msg: read_rt_string(e, pa[0]).unwrap_or_default(),
        file: read_rt_string(e, pa[1]).unwrap_or_default(),
        read_only: pa[6] != 0,
        line_start: pa[2],
        col_start: pa[3],
        line_end: pa[4],
        col_end: pa[5],
    };
    (info, read_rt_string(e, pa[7]).unwrap_or_default())
}

/// C's residual catch (`MMC_CATCH_INTERNAL` in `functionODE_residual` /
/// `residualFunctionIDA`): a model error unwinding through the residual is
/// recoverable, and `omc_assert_simulation` logs it in the integrator stage only
/// under `LOG_SOLVER`. Consumes what the throw left; false for an engine failure.
fn residual_model_throw(e: &mut dyn SimEngine, err: &str, t: f64) -> bool {
    caught_model_throw(e, err, t, omclog::active(omclog::SOLVER))
}

/// C's `finishSimulation`: the simulation stage logs the block unconditionally, and
/// the terminal row still follows.
fn terminal_model_throw(e: &mut dyn SimEngine, err: &str, t: f64) -> bool {
    caught_model_throw(e, err, t, true)
}

fn caught_model_throw(e: &mut dyn SimEngine, err: &str, t: f64, logged: bool) -> bool {
    let pending = e.take_pending_assert();
    if !is_model_throw(err) && pending.is_none() {
        return false;
    }
    clear_runtime_error();
    if let Some(pa) = pending
        && logged
    {
        let (info, cond) = assert_info(e, &pa);
        log_assert_block(&info, &cond, t, pa[8] != 0);
    }
    true
}

fn enrich_trap_impl(e: &mut dyn SimEngine, err: &'static str, init_time: Option<f64>) -> &'static str {
    THROW_PAST_STEP.store(false, Ordering::Relaxed);
    if RUNTIME_ERROR.swap(false, Ordering::Relaxed) {
        if init_time.is_some() {
            log_init_assert_notice();
        }
        return ASSERT_ERR;
    }
    let Some(pa) = e.take_pending_assert() else {
        // C's `initializeModel` reports every `longjmp` reaching it, including the
        // generated `functionDAE`'s throw for a non-converged system.
        if init_time.is_some() && err == ASSERT_ERR {
            log_init_assert_notice();
        }
        return err;
    };
    let (info, cond) = assert_info(e, &pa);
    if let Some(t) = init_time {
        log_assert_block(&info, &cond, t, pa[8] != 0);
        log_init_assert_notice();
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
    /// C's `performSimulation` catch: undo the step `advance` threw in and retake it at
    /// half the size. `false` ⇒ the throw ends the run.
    fn retry_step(&mut self, _e: &mut (dyn SimEngine + 'static), _model: &SimModel) -> Result<bool> {
        Ok(false)
    }
    fn take_rows(&mut self) -> Vec<f64>;
    fn fill_stats(&mut self, model: &SimModel, stats: &mut SolveStats);
    /// The time C's `finishSimulation` emits its terminal row at
    /// (`localData[0]->timeValue`). `None` ⇒ the last emitted row's time, where
    /// every driver that follows the output grid leaves it.
    fn terminal_time(&self) -> Option<f64> {
        None
    }
}

// The run's wall clock (ms), which the driver's chunk budget and the per-system
// statistics share, so a host injects it once. It lives in `openmodelica_solvers`
// because `sysstat` -- measured inside the solvers -- needs it too.
pub use openmodelica_solvers::clock::{now_ms as now_ms_host, set_clock};

use core::sync::atomic::{AtomicUsize, Ordering};

fn now_ms() -> f64 {
    now_ms_host()
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

/// C's per-step `-lv_time` check (`perform_simulation.c.inc`): the streams come on
/// for a step that reaches the window and go off once past it.
fn logging_window(e: &mut dyn SimEngine, t: f64, t_next: f64) {
    let Some((t0, t1)) = crate::simflags::with_flags(|f| f.lv_time) else { return };
    let before = omclog::mask();
    if (t >= t0 || t_next >= t0) && t_next < t1 {
        omclog::reactivate();
    }
    if t > t1 {
        omclog::deactivate();
    }
    if omclog::mask() != before {
        e.set_log_mask(omclog::mask());
    }
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
// Where a run's result rows go. A driver commits its buffer at every step
// boundary (`StepRetry::open`) and `drive` commits the rest before the run's
// clock stops, so a sink sees every row exactly once, in order, while the run is
// still timed. The sink returns `false` while it has nowhere to put them yet (its
// file opens after initialization, see `set_result_opener`); the rows then stay
// in the buffer. Unset, they stay there until `take_rows`.
static ROW_SINK: AtomicUsize = AtomicUsize::new(0);
static ROW_SINK_FINISH: AtomicUsize = AtomicUsize::new(0);
pub fn set_row_sink(rows: Option<fn(&[f64]) -> bool>, finish: Option<fn()>) {
    ROW_SINK.store(rows.map_or(0, |f| f as usize), Ordering::Relaxed);
    ROW_SINK_FINISH.store(finish.map_or(0, |f| f as usize), Ordering::Relaxed);
}
/// Hand `rows` to the sink and empty the buffer; nothing without a sink.
pub fn commit_rows(rows: &mut Vec<f64>) {
    let p = ROW_SINK.load(Ordering::Relaxed);
    if p == 0 || rows.is_empty() {
        return;
    }
    let f: fn(&[f64]) -> bool = unsafe { core::mem::transmute(p) };
    if f(rows) {
        rows.clear();
    }
}
// Opens the embedder's result file: called once initialization is done (C's
// `writeParameterData`), with the engine, so the file's parameter section can be
// read out of `SimData`.
static RESULT_OPENER: AtomicUsize = AtomicUsize::new(0);
pub fn set_result_opener(f: Option<fn(&mut dyn SimEngine, &SimModel, u32) -> Result<()>>) {
    RESULT_OPENER.store(f.map_or(0, |f| f as usize), Ordering::Relaxed);
}
pub fn open_result(e: &mut dyn SimEngine, model: &SimModel, sim_data: u32) -> Result<()> {
    let p = RESULT_OPENER.load(Ordering::Relaxed);
    if p == 0 {
        return Ok(());
    }
    let f: fn(&mut dyn SimEngine, &SimModel, u32) -> Result<()> = unsafe { core::mem::transmute(p) };
    f(e, model, sim_data)
}
/// Commit `rows` and close the sink's file, inside the run's total time.
pub fn finish_rows(rows: &mut Vec<f64>) {
    commit_rows(rows);
    let p = ROW_SINK_FINISH.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn() = unsafe { core::mem::transmute(p) };
        f();
    }
}

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
static NO_THROW: core::sync::atomic::AtomicBool = core::sync::atomic::AtomicBool::new(false);
pub fn set_no_throw_hook(f: fn(bool)) {
    NO_THROW_HOOK.store(f as usize, Ordering::Relaxed);
}
fn set_no_throw(v: bool) {
    NO_THROW.store(v, Ordering::Relaxed);
    let p = NO_THROW_HOOK.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn(bool) = unsafe { core::mem::transmute(p) };
        f(v);
    }
}

/// C's `noThrowAsserts` covers `simulationUpdate` only: the integrator's own
/// evaluations run outside it and a violated `assert()` there throws, so the step
/// is retried. The drivers open the window over a whole row, so the integrator
/// step suspends it.
struct AssertWindowSuspended(bool);
fn suspend_assert_window() -> AssertWindowSuspended {
    let was_open = NO_THROW.load(Ordering::Relaxed);
    if was_open {
        set_no_throw(false);
    }
    AssertWindowSuspended(was_open)
}
impl Drop for AssertWindowSuspended {
    fn drop(&mut self) {
        if self.0 {
            set_no_throw(true);
        }
    }
}

/// C's error report for a `-reconcile*` run whose simulation failed.
#[cfg(feature = "std")]
fn report_run_failure(model: &SimMeta) {
    crate::datarecon::report_run_failure(model);
}
#[cfg(not(feature = "std"))]
fn report_run_failure(_model: &SimMeta) {}

/// The `-reconcile*` procedures; a runtime without a filesystem has none.
#[cfg(feature = "std")]
pub fn reconcile(e: &mut dyn SimEngine, model: &SimMeta, sim_data: u32) -> (alloc::string::String, Result<()>) {
    crate::datarecon::reconcile(e, model, sim_data)
}
#[cfg(not(feature = "std"))]
pub fn reconcile(_e: &mut dyn SimEngine, _model: &SimMeta, _sim_data: u32) -> (alloc::string::String, Result<()>) {
    (alloc::string::String::new(), Ok(()))
}

/// C's `OpenModelica_uriToFilename`, which needs the compiler's class-directory
/// table. The host installs its own; without one a `modelica://` URI is left as
/// written, and `file://` is stripped.
pub type UriResolver = fn(&str) -> alloc::string::String;
static URI_RESOLVER: AtomicUsize = AtomicUsize::new(0);
pub fn set_uri_resolver(f: UriResolver) {
    URI_RESOLVER.store(f as usize, Ordering::Relaxed);
}
pub(crate) fn uri_to_filename(uri: &str) -> alloc::string::String {
    use alloc::string::ToString;
    let p = URI_RESOLVER.load(Ordering::Relaxed);
    if p != 0 {
        let f: UriResolver = unsafe { core::mem::transmute(p) };
        return f(uri);
    }
    match uri.strip_prefix("file://") {
        Some(path) => path.to_string(),
        None => uri.to_string(),
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

/// Read a contiguous run of little-endian f64 starting at `addr`.
pub fn read_f64s(e: &dyn SimEngine, addr: u32, out: &mut [f64]) -> Result<()> {
    let mut bytes = vec![0u8; out.len() * 8];
    e.read_bytes(addr, &mut bytes)?;
    for (i, v) in out.iter_mut().enumerate() {
        *v = f64::from_le_bytes(bytes[i * 8..i * 8 + 8].try_into().unwrap());
    }
    Ok(())
}

/// Write a contiguous run of little-endian f64 starting at `addr`.
pub fn write_f64s(e: &mut dyn SimEngine, addr: u32, v: &[f64]) -> Result<()> {
    let mut bytes = vec![0u8; v.len() * 8];
    for (i, x) in v.iter().enumerate() {
        bytes[i * 8..i * 8 + 8].copy_from_slice(&x.to_le_bytes());
    }
    e.write_bytes(addr, &bytes)
}

/// Write one little-endian i32 to linear memory at byte address `addr`.
pub(crate) fn write_i32(e: &mut dyn SimEngine, addr: u32, v: i32) -> Result<()> {
    e.write_bytes(addr, &v.to_le_bytes())
}

/// Move the model clock. C pairs `timeValue = t` with `externalInputUpdate` +
/// `input_function` in each solver's residual and root callback, in
/// `updateContinuousSystem` and in the event bisection; every one of those goes
/// through here, so `-csvInput` is applied once, for all of them.
pub(crate) fn write_time(e: &mut dyn SimEngine, sim_data: u32, t: f64) -> Result<()> {
    write_f64(e, sim_data + TIME_OFF, t)?;
    #[cfg(feature = "std")]
    crate::extinput::apply(e, sim_data, t);
    Ok(())
}

/// Raise the throw C's `equationNonlinear` makes when the last equation call left
/// the `nls_fail` flag up. The step's catch retries it; a DASSL residual has
/// already answered `IRES = -1` and never reaches here.
pub(crate) fn check_nls(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    let failed = read_i32(e, sim_data + layout.nls_fail_off)?;
    if failed != 0 {
        init_report::set_failed_system(failed - 1);
        report_nls_failure(e, sim_data, layout);
        return Err(ASSERT_ERR);
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
    omclog::debug!(
        omclog::ASSERT,
        false,
        "Solving non-linear system {} failed at time={}.\nFor more information please use -lv LOG_NLS.",
        failed - 1,
        format_g15(time),
    );
}

/// C's `equationNonlinear` throw for a host outside this module: reported and cleared.
pub fn take_nls_failure(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> bool {
    if read_i32(e, sim_data + layout.nls_fail_off).unwrap_or(0) == 0 {
        return false;
    }
    report_nls_failure(e, sim_data, layout);
    let _ = write_i32(e, sim_data + layout.nls_fail_off, 0);
    true
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
        use alloc::string::String;
        std::thread_local! {
            static PARAM: RefCell<Vec<(u32, WTy, f64)>> = const { RefCell::new(Vec::new()) };
            static START: RefCell<Vec<(u32, WTy, f64)>> = const { RefCell::new(Vec::new()) };
            static STRINGS: RefCell<Vec<(u32, String)>> = const { RefCell::new(Vec::new()) };
        }
        pub fn set(p: Vec<(u32, WTy, f64)>, s: Vec<(u32, WTy, f64)>, t: Vec<(u32, String)>) {
            PARAM.with(|o| *o.borrow_mut() = p);
            START.with(|o| *o.borrow_mut() = s);
            STRINGS.with(|o| *o.borrow_mut() = t);
        }
        pub fn params() -> Vec<(u32, WTy, f64)> {
            PARAM.with(|o| o.borrow().clone())
        }
        pub fn starts() -> Vec<(u32, WTy, f64)> {
            START.with(|o| o.borrow().clone())
        }
        pub fn strings() -> Vec<(u32, String)> {
            STRINGS.with(|o| o.borrow().clone())
        }
    }

    #[cfg(not(feature = "std"))]
    mod imp {
        use super::WTy;
        use alloc::string::String;
        use alloc::vec::Vec;
        use core::cell::UnsafeCell;
        // The in-wasm runtime is single-threaded, so a plain cell is sound.
        type Groups = (Vec<(u32, WTy, f64)>, Vec<(u32, WTy, f64)>, Vec<(u32, String)>);
        struct Store(UnsafeCell<Groups>);
        unsafe impl Sync for Store {}
        static STORE: Store = Store(UnsafeCell::new((Vec::new(), Vec::new(), Vec::new())));
        pub fn set(p: Vec<(u32, WTy, f64)>, s: Vec<(u32, WTy, f64)>, t: Vec<(u32, String)>) {
            unsafe { *STORE.0.get() = (p, s, t) };
        }
        pub fn params() -> Vec<(u32, WTy, f64)> {
            unsafe { (*STORE.0.get()).0.clone() }
        }
        pub fn starts() -> Vec<(u32, WTy, f64)> {
            unsafe { (*STORE.0.get()).1.clone() }
        }
        pub fn strings() -> Vec<(u32, String)> {
            unsafe { (*STORE.0.get()).2.clone() }
        }
    }

    pub use imp::{params, set, starts, strings};
}

/// Set the parameter/start overrides applied by the next [`run_initialization`].
/// `strings` are the String parameters among them, whose value is bytes rather
/// than a number.
pub fn set_param_overrides(
    params: Vec<(u32, WTy, f64)>,
    starts: Vec<(u32, WTy, f64)>,
    strings: Vec<(u32, String)>,
) {
    overrides_store::set(params, starts, strings);
}

/// The overrides last set, as `(params, starts, strings)`. A host driving the
/// in-wasm session must forward these into it: the runtime module has its own copy
/// of this store, which [`set_param_overrides`] on the host side does not reach.
pub fn param_overrides() -> (Vec<(u32, WTy, f64)>, Vec<(u32, WTy, f64)>, Vec<(u32, String)>) {
    (overrides_store::params(), overrides_store::starts(), overrides_store::strings())
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
    apply_overrides(e, sim_data, &overrides_store::params())?;
    for (off, value) in overrides_store::strings() {
        e.set_string(sim_data + off, value.as_bytes())?;
    }
    Ok(())
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
    omclog::info!(
        omclog::INIT,
        false,
        "import start values\nfile: {}\ntime: {}",
        imports.file,
        format_g(imports.time, 6),
    );
    // `values` is in roster order, so one cursor walks both.
    let mut next = 0usize;
    let mut flat = 0u32;
    for (group, entries) in crate::IMPORT_GROUP.iter().zip(model.import_roster()) {
        omclog::info!(omclog::INIT, false, "import {group}");
        // C's headers are plural, its per-quantity lines singular.
        let one = group.trim_end_matches('s');
        for (name, off, wty) in entries {
            let found = imports.values.get(next).filter(|(i, _)| *i == flat).map(|&(_, v)| v);
            if found.is_some() {
                next += 1;
            }
            flat += 1;
            if overridden_on_command_line(name) {
                omclog::info!(
                    omclog::INIT_V,
                    false,
                    "| skip import of {one} {name}: overridden on command line",
                );
                continue;
            }
            let Some(v) = found else {
                // C reports a missing quantity, except for the backend's own variables.
                if !(group.ends_with("variables") && is_generated(name)) {
                    omclog::warning!(
                        omclog::INIT,
                        false,
                        "unable to import {one} {name} from given file",
                    );
                }
                continue;
            };
            match wty {
                WTy::F64 => {
                    write_f64(e, sim_data + off, v)?;
                    omclog::info!(omclog::INIT_V, false, "| {name}(start={})", format_g(v, 6));
                }
                WTy::I32 if group.starts_with("boolean") => {
                    write_i32(e, sim_data + off, (v != 0.0) as i32)?;
                    let b = if v != 0.0 { "true" } else { "false" };
                    omclog::info!(omclog::INIT_V, false, "| {name}(start={b})");
                }
                WTy::I32 => {
                    write_i32(e, sim_data + off, v as i32)?;
                    omclog::info!(omclog::INIT_V, false, "| {name}(start={})", v as i32);
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

/// Whether an error out of a step is one of C's `longjmp`s; a solver failure, a
/// cancelled run or a raw wasm trap is not. Which buffer it targeted, and so whether
/// the step is retried, is [`StepRetry::undo`]'s.
pub fn is_model_throw(err: &str) -> bool {
    // An external function's `ModelicaError` unwinds as a bare engine trap; only the
    // flag it left says the solver may retake the step.
    err == ASSERT_ERR || RUNTIME_ERROR.load(Ordering::Relaxed)
}
/// C's `initialization()` returning nonzero: the reason is already logged.
pub const INIT_FAILED_ERR: &str = "initialization failed";

/// C's `retValIntegrator != 0`: the reason is logged, and [`drive`] still owes C's
/// `performSimulation` tail.
pub const SOLVER_FAILED_ERR: &str = "integrator failed";

/// Where the integrator gave up (C's `solverInfo->currentTime`), for the tail
/// [`drive`] runs; the driver can only return a `&'static str`.
mod solver_fail_store {
    #[cfg(feature = "std")]
    mod imp {
        use core::cell::Cell;
        std::thread_local! {
            static AT: Cell<f64> = const { Cell::new(f64::NAN) };
        }
        pub fn set(t: f64) {
            AT.with(|a| a.set(t));
        }
        pub fn take() -> Option<f64> {
            let t = AT.with(|a| a.replace(f64::NAN));
            t.is_finite().then_some(t)
        }
    }
    #[cfg(not(feature = "std"))]
    mod imp {
        use core::cell::UnsafeCell;
        struct Store(UnsafeCell<f64>);
        unsafe impl Sync for Store {}
        static AT: Store = Store(UnsafeCell::new(f64::NAN));
        pub fn set(t: f64) {
            unsafe { *AT.0.get() = t };
        }
        pub fn take() -> Option<f64> {
            let t = unsafe { core::mem::replace(&mut *AT.0.get(), f64::NAN) };
            t.is_finite().then_some(t)
        }
    }
    pub use imp::{set, take};
}

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

/// C's `perform_simulation` line after `simulationStep`, closing its `LOG_SOLVER` block.
fn log_solver_finished(t: f64) {
    if omclog::active(omclog::SOLVER) {
        omclog::info!(omclog::SOLVER, false, "finished solver step {}", format_g(t, 6));
        omclog::close(omclog::SOLVER);
    }
}

fn format_g15(v: f64) -> String {
    format_g(v, 15)
}

/// Evaluate `functionCheckAsserts` (C's `checkForAsserts`) at the current point and
/// format any `AssertionLevel.warning` violation it recorded into a `LOG_ASSERT`
/// block. Called by the drivers after each accepted solver step.
///
/// `level`: C reports a violation met while the integrator updates the system
/// (`simulationUpdate`, which sets `noThrowAsserts`) as `info`, one met anywhere
/// else — initialization, the terminal step — as `warning`.
fn check_asserts(e: &mut dyn SimEngine, sim_data: u32, _layout: &SimLayout, level: omclog::LogType) -> Result<()> {
    e.call1_if_present("functionCheckAsserts", sim_data)?;
    drain_asserts(e, sim_data, level)?;
    Ok(())
}

/// Log the violations recorded since the last call, every one: the generated code
/// latches a warning-level site itself (C's static `warningTriggered`). A suppressed
/// error also arms the re-throw, which the `true` return reports.
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
        if suppressed {
            omclog::info(omclog::ASSERT, false, &line);
            rethrow_store::arm(info);
            armed = true;
        } else if level == omclog::WARNING {
            omclog::warning(omclog::ASSERT, false, &line);
        } else {
            omclog::info(omclog::ASSERT, false, &line);
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
    // a condition it is C's `FUNCTION_CONTEXT` `omc_assert`: the message, under the
    // position where there is one (`omc_dummyFileInfo` has none).
    if cond.is_empty() {
        return if info.file.is_empty() { info.msg.clone() } else { format!("{pos}\n{}", info.msg) };
    }
    let body = format!("(({cond})) --> \"{}\"", info.msg);
    if info.file.is_empty() {
        return format!("{head}\n{body}");
    }
    format!("{pos}\n{head}\n{body}")
}

pub fn log_assert_block(info: &AssertInfo, cond: &str, time: f64, initial: bool) {
    let block = assert_block(info, cond, time, initial);
    // C's generated guard for a backend variable warns (`omc_assert_warning`); a
    // model `assert()` and `omc_assert`'s conditionless message are both errors.
    if info.file.is_empty() && !cond.is_empty() {
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
            static NOTED: Cell<bool> = const { Cell::new(false) };
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
        pub fn note() {
            NOTED.with(|n| n.set(true));
        }
        pub fn take() -> (Option<AssertInfo>, bool, bool) {
            (
                PENDING.with(|p| p.borrow_mut().take()),
                EVENT.with(|ev| ev.replace(false)),
                NOTED.with(|n| n.replace(false)),
            )
        }
    }
    #[cfg(not(feature = "std"))]
    mod imp {
        use super::AssertInfo;
        use core::cell::UnsafeCell;
        struct Store(UnsafeCell<(Option<AssertInfo>, bool, bool)>);
        unsafe impl Sync for Store {}
        static PENDING: Store = Store(UnsafeCell::new((None, false, false)));
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
        pub fn note() {
            unsafe { (*PENDING.0.get()).2 = true };
        }
        pub fn take() -> (Option<AssertInfo>, bool, bool) {
            unsafe {
                let st = &mut *PENDING.0.get();
                (st.0.take(), core::mem::replace(&mut st.1, false), core::mem::replace(&mut st.2, false))
            }
        }
    }
    pub use imp::{arm, note, note_event, take};
}

/// C's `assertCommonVar` under `noThrowAsserts`: arm `needToReThrow` and report
/// that the caller may carry on with the out-of-domain value instead of throwing.
pub fn note_no_throw_assert() -> bool {
    if !NO_THROW.load(Ordering::Relaxed) {
        return false;
    }
    rethrow_store::note();
    true
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
    let noted = e.take_noted_assert();
    let (info, found_event, self_noted) = rethrow_store::take();
    if info.is_none() && !noted && !self_noted {
        return Ok(());
    }
    if found_event {
        omclog::info(omclog::ASSERT, false, "Found event, previous asserts are ignored.");
        return Ok(());
    }
    omclog::error(omclog::ASSERT, false, "No event found, but assert was triggered. Throwing now!");
    let p = ASSERT_REPORTER.load(Ordering::Relaxed);
    if let Some(info) = info.filter(|_| p != 0) {
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
    init_model(e, sim_data, layout, inputs, start_time, None, None)?;
    signal_init_done();
    terminate_at_init(e, sim_data, layout)
}

/// [`run_initialization`] where the caller has the metadata the `LOG_SOTI` dump
/// and the discrete start attributes need.
pub fn run_initialization_model(e: &mut dyn SimEngine, sim_data: u32, model: &SimMeta) -> Result<()> {
    init_model(e, sim_data, &model.layout, &model.inputs, model.start_time, Some(model), None)?;
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
    dae: Option<&mut (dyn FnMut(&mut dyn SimEngine) -> Result<()> + '_)>,
) -> Result<crate::sync::Sync> {
    init_model(e, sim_data, &model.layout, &model.inputs, model.start_time, Some(model), dae)?;
    let mut sync = crate::sync::Sync::new(e, model, sim_data)?;
    // An event clock whose `when` already fired during the initial discrete update
    // is only *scheduled* here (C's `data->simulationInfo->initial` case).
    sync.take_fired(e, model.start_time)?;
    log_event_status(e, sim_data, &model.layout, omclog::EVENTS)?;
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
    dae: Option<&mut (dyn FnMut(&mut dyn SimEngine) -> Result<()> + '_)>,
) -> Result<()> {
    INIT_NOTICE_LOGGED.store(false, Ordering::Relaxed);
    // C's `initializeNonlinearSystems`, which reports its dropped patterns here.
    if let Some(m) = model {
        for w in &m.nls_warnings {
            omclog::warning(omclog::STDOUT, false, w);
        }
    }
    rtclock::enter_init();
    if let Some(m) = model {
        event_dump_store::set(EventDump::new(m));
    }
    // `functionInitDelay` reads `startTime` from `TIME_OFF`; init the buffers
    // before any equation function (`rt_delay_eval` traps on unallocated ones).
    write_time(e, sim_data, start_time)?;
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
    match dae {
        Some(dae) => iterate_discrete_dae(e, sim_data, layout, dae)?,
        None => iterate_discrete(e, sim_data, layout)?,
    }
    // C's generated `functionDAE` throws on a system that did not converge, and the
    // throw is still inside `initializeModel`.
    check_nls(e, sim_data, layout)?;
    // C's position: a `sample(t0, p)` start that is a `fixed=false` parameter is
    // only known once the initial equations have computed it.
    if layout.n_samples > 0 {
        e.call1("initSample", sim_data)?;
    }
    store_relations(e, sim_data, layout)?;
    update_relations_pre(e, sim_data, layout)?;
    // Seed the delay buffers / transported profiles and snapshot `zeroCrossingsPre`
    // for step 1.
    store_operators(e, sim_data, layout)?;
    // C's `functionInitialEquations` clears `discreteCall` on the way out. A model
    // that neither integrates (no states) nor crosses (no zero crossings) reaches no
    // other writer, and would spend the whole run in initialization mode.
    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
    if layout.n_zc > 0 {
        save_zc_pre(e, sim_data, layout)?;
        e.call2(MODEL_FN_ZC, sim_data, sim_data + layout.zc_off)?;
    }
    write_i32(e, sim_data + layout.initial_off, 0)?;
    // C's `initializeModel` ends with `checkForAsserts` — before the
    // initialization-success line.
    check_asserts(e, sim_data, layout, omclog::WARNING)?;
    rtclock::accumulate(rtclock::INIT);
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
    // Initialization throws on a failed assert (C clears `noThrowAsserts` here).
    let _ = rethrow_store::take();
    set_no_throw(false);
    term_report::reset();
    steady_report::reset();
    seed_start_values(e, sim_data, layout, inputs, model)?;
    log_static_data_update(e);
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
fn log_static_data_update(e: &mut dyn SimEngine) {
    omclog::info(omclog::LS_V, true, "update static data of linear system solvers");
    e.update_static_system_data(true);
    omclog::close(omclog::LS_V);
    omclog::info(omclog::NLS, true, "update static data of non-linear system solvers");
    e.update_static_system_data(false);
    omclog::close(omclog::NLS);
}

/// C's `INIT_METHOD_NAME`/`INIT_METHOD_DESC` line.
fn log_init_method(name: &str, desc: &str) {
    omclog::info!(omclog::INIT, false, "initialization method: {name:<15} [{desc}]");
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

/// What a host returns from `functionRemovedInitialEquations` when the model's own
/// code already printed which equation is inconsistent.
pub const REMOVED_INIT_INCONSISTENT: &str = "the removed initial equations are inconsistent";

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
    // A host whose model reports the inconsistency itself says so with this error
    // rather than filling the two slots below.
    match e.call1("functionRemovedInitialEquations", sim_data) {
        Err(REMOVED_INIT_INCONSISTENT) => return Err(report_init_failure()),
        other => other?,
    }
    let idx = read_i32(e, sim_data + layout.removed_init_idx_off)?;
    if idx == 0 {
        return Ok(());
    }
    let res = read_f64(e, sim_data + layout.removed_init_res_off)?;
    let desc = model
        .and_then(|m| m.removed_init_desc.get(idx as usize - 1))
        .map(String::as_str)
        .unwrap_or_default();
    omclog::error!(
        omclog::INIT,
        false,
        "The initialization problem is inconsistent due to the following equation: 0 != {} = {desc}",
        format_g(res, 6),
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
    write_time(e, sim_data, model.start_time)?;
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
    if !e.model_logs_bound_attrs() {
        log_bound_attr_updates(e, sim_data, layout, model);
    }
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
        omclog::info!(omclog::INIT, true, "updating {header}");
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
                let v = e.string_at(sim_data + layout.sparam_off + i as u32 * 4).unwrap_or_default();
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
        omclog::info!(omclog::INIT_HOMOTOPY, false, "homotopy parameter lambda = {}", format_g(lambda, 6));
        if step == 0 {
            call_initial_equations_lambda0(e, sim_data, layout)?;
        } else {
            write_i32(e, sim_data + layout.nls_fail_off, 0)?;
            e.call1("functionInitialEquations", sim_data)?;
        }
        omclog::info!(
            omclog::INIT_HOMOTOPY,
            false,
            "homotopy parameter lambda = {} done\n---------------------------",
            format_g(lambda, 6),
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
                    omclog::info!(
                        omclog::INIT_HOMOTOPY,
                        false,
                        "The homotopy path will be exported to {path}.",
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
            crate::files::write(&path, buf.as_bytes());
        }
    }
}

/// Append one trajectory row to `rows`: the real part `[time | realVars]`
/// followed by the integer and boolean algebraic slots (converted to f64),
/// matching `SimLayout::n_row_total()` and the column layout `kind_from_slot`
/// assigns. Used by the host-driven drivers; the in-wasm `simulate` emits the
/// same layout.
pub fn capture_row(e: &dyn SimEngine, rows: &mut Vec<f64>, sim_data: u32, layout: &SimLayout) -> Result<()> {
    // C's `emit` — the result writer's share of the run (`SIM_TIMER_OUTPUT`).
    rtclock::tick(rtclock::OUTPUT);
    let out = capture_row_values(e, rows, sim_data, layout);
    rtclock::accumulate(rtclock::OUTPUT);
    out
}

fn capture_row_values(e: &dyn SimEngine, rows: &mut Vec<f64>, sim_data: u32, layout: &SimLayout) -> Result<()> {
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
    for i in 0..layout.n_str_alg() {
        let s = e.string_at(sim_data + layout.str_off + i * 4)?;
        rows.push(crate::strings::intern(&s) as f64);
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

/// `printInfo`'s bracketed position, then the message.
static TERMINATE_REPORTER: AtomicUsize = AtomicUsize::new(0);

/// Report `terminate()` this way instead of as the driver's own notice — C's
/// `omc_terminate`, which `fmi2Instantiate` swaps for `omc_terminate_fmi`.
pub fn set_terminate_reporter(f: fn(&str, &str)) {
    TERMINATE_REPORTER.store(f as usize, Ordering::Relaxed);
}

/// Where a `terminate()` fired and what it said, as C's `TermMsg` / `TermInfo`
/// hold it. `span` is `printInfo`'s `[lineStart, colStart, lineEnd, colEnd]`.
pub struct TerminateInfo {
    pub msg: String,
    pub file: String,
    pub span: [i32; 4],
    pub readonly: bool,
}

/// C's `checkSimulationTerminated` notice: the source position raw (`printInfo`,
/// outside the message system) then the message, once per run. `at_init` picks
/// the wording C uses before the main loop.
fn report_terminate(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout, at_init: bool) -> Result<()> {
    if !term_report::mark() {
        return Ok(());
    }
    let t = match e.terminate_info() {
        Some(v) => v,
        None => {
            let w = |i: u32| read_i32(e, sim_data + layout.term_info_off + i * 4);
            TerminateInfo {
                msg: read_rt_string(e, w(0)?)?,
                file: read_rt_string(e, w(1)?)?,
                span: [w(2)?, w(3)?, w(4)?, w(5)?],
                readonly: w(6)? != 0,
            }
        }
    };
    let (msg, file) = (t.msg, t.file);
    let ro = if t.readonly { "readonly" } else { "writable" };
    let [ls, cs, le, ce] = t.span;
    let pos = format!("[{file}:{ls}:{cs}-{le}:{ce}:{ro}]");
    let p = TERMINATE_REPORTER.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn(&str, &str) = unsafe { core::mem::transmute(p) };
        f(&pos, &msg);
        return Ok(());
    }
    if !file.is_empty() {
        log_line(crate::omclog::STDOUT, crate::omclog::INFO, &format!("{pos}\n"));
    }
    let time = format_f(read_f64(e, sim_data + TIME_OFF)?);
    let at = if at_init { format!("at initialization (time {time})") } else { format!("at time {time}") };
    omclog::info!(omclog::STDOUT, false, "Simulation call terminate() {at}\nMessage : {msg}");
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
    omclog::info!(
        omclog::STDOUT,
        false,
        "steady state reached at time = {}\n  * max(|d(x_i)/dt|/nominal(x_i)) = {}\n  * \
         relative tolerance = {}",
        format_g(read_f64(e, sim_data + TIME_OFF)?, 6),
        format_g(max_der, 6),
        format_g(tol, 6),
    );
    Ok(true)
}

/// C's `updateContinuousSystem`: recompute everything an output row reads. A
/// `--daeMode` model has no explicit ODE, so that is one algebraic-stage residual.
/// C's `function_storeDelayed` + `function_storeSpatialDistribution`, the tail of
/// `updateContinuousSystem`: the operators with an internal history record the point
/// the model was last evaluated at. A model without any skips it entirely.
pub fn store_operators(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
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
    write_time(e, sim_data, time)?;
    eval_continuous(e, sim_data, layout)?;
    store_operators(e, sim_data, layout)
}

/// C's `findRoot` tail: evaluate at the bracket's left end, record the operator
/// history and freeze `relationsPre` there. The caller restores the right end
/// without re-evaluating, so the pre-event row carries the left end's algebraics.
fn eval_event_left(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    states_base: u32,
    time: f64,
    y: &[f64],
) -> Result<()> {
    write_time(e, sim_data, time)?;
    if !y.is_empty() {
        write_f64s(e, states_base, y)?;
    }
    // As `capture_pre`: a when-model's `functionAlgebraics` runs the discrete update.
    if layout.has_history_ops || !layout.has_when {
        eval_continuous(e, sim_data, layout)?;
    } else {
        eval_ode(e, sim_data, layout)?;
    }
    if layout.has_history_ops {
        store_operators(e, sim_data, layout)?;
    }
    update_relations_pre(e, sim_data, layout)
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

/// One pass of C's `functionDAE`, which evaluates `allEquations` once.
fn eval_discrete(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if layout.dae_mode() {
        return e.call2(MODEL_FN_DAE, sim_data, eval_stage::DISCRETE);
    }
    e.call1("functionDAE", sim_data)
}

/// C's `function_ZeroCrossingsEquations`: what the crossing functions read.
pub fn eval_zc_equations(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
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
    write_time(e, sim_data, time)?;
    eval_continuous(e, sim_data, layout)?;
    emit_row_evaluated(e, rows, sim_data, layout, time, stop)
}

/// [`emit_row`] for a point C's `updateContinuousSystem` has already run at. A second
/// pass is not idempotent: `delayImpl` interpolates toward the *current* expression
/// value, so it walks a `delay()` chain one propagation step further than C.
fn emit_row_evaluated(
    e: &mut dyn SimEngine,
    rows: &mut Vec<f64>,
    sim_data: u32,
    layout: &SimLayout,
    time: f64,
    stop: f64,
) -> Result<()> {
    check_nls(e, sim_data, layout)?;
    capture_row(e, rows, sim_data, layout)?;
    let checked = check_asserts(e, sim_data, layout, if time >= stop { omclog::WARNING } else { omclog::INFO });
    // C's `fmtEmitStep`, once per global step.
    crate::profiling::on_row(e, time);
    checked
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
    // A run that ended mid-step left its `StepRetry` region open.
    let addr = e.error_stage_addr();
    set_error_stage(e, addr, ERROR_SIMULATION);
    let Some(time) = rows.len().checked_sub(n_reals as usize).map(|i| at.unwrap_or(rows[i])) else {
        return Ok(());
    };
    if no_event_emit() {
        return Ok(());
    }
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;
    write_time(e, sim_data, time)?;
    omclog::info!(omclog::EVENTS_V, false, "terminal event at stop time {}", format_g(time, 6));
    write_i32(e, sim_data + layout.terminal_off, 1)?;
    // A discrete call, so relations are live (C's `updateDiscreteSystem`
    // prologue): a condition that only becomes true at `stop` flips here.
    write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
    let updated = refresh_relations(e, sim_data, layout).and_then(|_| iterate_discrete(e, sim_data, layout));
    write_i32(e, sim_data + layout.terminal_off, 0)?;
    if let Err(err) = updated
        && !terminal_model_throw(e, err, time)
    {
        return Err(err);
    }
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
            // A String's column holds its interned id; the loops below print the text.
            if v.name != *name || v.ty == crate::VarTy::String {
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
        // C reads Strings from `stringVars`/`stringParameter`.
        let mut string_at = |off: u32| -> Result<()> {
            let s = e.string_at(sim_data + off)?;
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
    log_line(crate::omclog::STDOUT, crate::omclog::INFO, &out);
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
    write_time(e, sim_data, time)?;
    capture_row(e, rows, sim_data, layout)?;
    check_asserts(e, sim_data, layout, omclog::WARNING)
}

/// Pre-event snapshot row (state just before a discrete update). Skips
/// `functionAlgebraics` for `has_when` models — there it saves `pre` early, which
/// would break the post-event edge test.
fn capture_pre(e: &mut dyn SimEngine, rows: &mut Vec<f64>, sim_data: u32, layout: &SimLayout, time: f64) -> Result<()> {
    write_time(e, sim_data, time)?;
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

/// C's per-step `rotateRingBuffer` + `continueSimulationData`
/// (`perform_simulation.c.inc`), which every driver's step opens with; `--daeMode`
/// with states skips it, as C does.
fn rotate_old_real(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if layout.dae_mode() && layout.n_states > 0 {
        return Ok(());
    }
    save_old_real(e, sim_data, layout)
}

/// C's `overwriteOldSimulationData`: the live reals become `localData[1]`. Only a
/// method-1 linear system reads them (its `aux_x`).
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
/// win over the file. Armed for the integration loop separately, in [`drive`].
#[cfg(feature = "std")]
fn apply_external_input(
    e: &mut dyn SimEngine,
    sim_data: u32,
    inputs: &[crate::InputVar],
) -> Result<()> {
    let slot = crate::extinput::Slot::Start;
    let Some(mut hook) = crate::extinput::ExtInputHook::load(inputs, slot) else { return Ok(()) };
    let t = read_f64(e, sim_data + TIME_OFF)?;
    hook.apply(e, sim_data, t);
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
    e.call2(MODEL_FN_ZC, sim_data, sim_data + layout.zc_off)?;
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
    e.call2(MODEL_FN_ZC, sim_data, sim_data + layout.zc_off)?;
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
            let cur = e.string_at(sim_data + layout.str_off + i as u32 * 4).unwrap_or_default();
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
    omclog::info!(omclog::EVENTS, true, "state event at time={}", format_g(time, 12));
    // Highest index first: C's `checkForStateEvent` pushes each crossing onto the
    // front of the event list it then walks, so simultaneous ones come out reversed.
    for &i in roots.iter().rev() {
        let desc = model.zc_desc.get(i).map(String::as_str).unwrap_or_default();
        omclog::info!(omclog::EVENTS, false, "[{}] {desc}", i + 1);
    }
}

/// C's `algStmtReinit` message, from what the model recorded during the pass.
fn log_reinits(e: &mut dyn SimEngine) {
    for (off, value) in e.take_pending_reinits() {
        if !omclog::active(omclog::EVENTS) {
            continue;
        }
        let i = off.saturating_sub(REAL_OFF) as usize / 8;
        let name = event_dump_store::with(|d| d.real_names.get(i).cloned().unwrap_or_default());
        omclog::info!(omclog::EVENTS, false, "reinit {name} = {}", format_g(value, 6));
    }
}

/// [`log_state_event`] for a time event: C names the samples that fired.
fn log_time_event(e: &dyn SimEngine, time: f64, samples: &Samples, model: &SimMeta) {
    if !omclog::active(omclog::EVENTS) {
        return;
    }
    omclog::info!(omclog::EVENTS, true, "time event at time={}", format_g(time, 12));
    for (k, start, interval) in samples.due(time) {
        let index = e
            .sample_index(k)
            .or_else(|| model.sample_index.get(k).copied())
            .unwrap_or(k as i32 + 1);
        omclog::info!(
            omclog::EVENTS,
            false,
            "[{index}] sample({}, {})",
            format_g(start, 6),
            format_g(interval, 6),
        );
    }
}

/// What C's `updateDiscreteSystem` names on `LOG_EVENTS`/`LOG_EVENTS_V`. Installed
/// once per run because the event paths that print it carry only a [`SimLayout`].
#[derive(Default)]
pub(crate) struct EventDump {
    rel_desc: Vec<String>,
    zc_desc: Vec<String>,
    /// `(name, live, pre)` in C's walk order. Strings have no `pre` region here.
    reals: Vec<(String, u32, u32)>,
    ints: Vec<(String, u32, u32)>,
    bools: Vec<(String, u32, u32)>,
    /// Every real variable in index order, for [`log_reinits`].
    real_names: Vec<String>,
}

impl EventDump {
    fn new(model: &SimMeta) -> Self {
        let l = &model.layout;
        let n_real = 2 * l.n_states + l.n_real_alg;
        let first = n_real.saturating_sub(model.soti.n_discrete_real) as usize;
        let slots = |names: &[String], live: u32, pre: u32, w: u32, from: usize| -> Vec<(String, u32, u32)> {
            names
                .iter()
                .enumerate()
                .skip(from)
                // C skips common-subexpression temporaries.
                .filter(|(_, n)| !n.starts_with("$cse"))
                .map(|(i, n)| (n.clone(), live + i as u32 * w, pre + i as u32 * w))
                .collect()
        };
        let named = |v: &[(String, i32)]| v.iter().map(|(n, _)| n.clone()).collect::<Vec<_>>();
        EventDump {
            rel_desc: model.rel_desc.clone(),
            zc_desc: model.zc_desc.clone(),
            reals: slots(&model.soti.reals, REAL_OFF, l.pre_real_off, 8, first),
            ints: slots(&named(&model.soti.ints), l.int_off, l.pre_int_off, 4, 0),
            bools: slots(&named(&model.soti.bools), l.bool_off, l.pre_bool_off, 4, 0),
            real_names: model.soti.reals.clone(),
        }
    }
}

pub(crate) mod event_dump_store {
    use super::EventDump;

    #[cfg(feature = "std")]
    mod imp {
        use super::EventDump;
        use core::cell::RefCell;
        std::thread_local! {
            static DUMP: RefCell<EventDump> = RefCell::new(EventDump::default());
        }
        pub fn set(d: EventDump) {
            DUMP.with(|c| *c.borrow_mut() = d);
        }
        pub fn with<R>(f: impl FnOnce(&EventDump) -> R) -> R {
            DUMP.with(|c| f(&c.borrow()))
        }
    }

    #[cfg(not(feature = "std"))]
    mod imp {
        use super::EventDump;
        use core::cell::UnsafeCell;
        // The in-wasm runtime is single-threaded, as `super::overrides_store`.
        struct Store(UnsafeCell<Option<EventDump>>);
        unsafe impl Sync for Store {}
        static DUMP: Store = Store(UnsafeCell::new(None));
        pub fn set(d: EventDump) {
            unsafe { *DUMP.0.get() = Some(d) };
        }
        pub fn with<R>(f: impl FnOnce(&EventDump) -> R) -> R {
            let slot = unsafe { &mut *DUMP.0.get() };
            f(slot.get_or_insert_with(EventDump::default))
        }
    }

    pub use imp::{set, with};
}

/// C's `printRelations` + `printZeroCrossings` (`model_help.c`): `initializeModel`
/// ends with them on `LOG_EVENTS`, and each event-iteration pass repeats them on
/// `LOG_EVENTS_V`.
pub fn log_event_status(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout, stream: omclog::Stream) -> Result<()> {
    if !omclog::active(stream) {
        return Ok(());
    }
    let time = format_g(read_f64(e, sim_data + TIME_OFF)?, 12);
    event_dump_store::with(|d| {
        omclog::info!(stream, true, "status of relations at time={time}");
        for i in 0..layout.n_rel {
            let flag = |off: u32| if read_i32(e, sim_data + off + i * 4).unwrap_or(0) != 0 { " true" } else { "false" };
            let desc = d.rel_desc.get(i as usize).map(String::as_str).unwrap_or_default();
            let (pre, cur) = (flag(layout.relations_pre_off), flag(layout.relations_off));
            omclog::info!(stream, false, "[{}] (pre: {pre}) {cur} = {desc}", i + 1);
        }
        omclog::close(stream);
        omclog::info!(stream, true, "status of zero crossings at time={time}");
        for i in 0..layout.n_zc {
            let g = |off: u32| omclog::g(read_f64(e, sim_data + off + i * 8).unwrap_or(0.0), 2, 1);
            let desc = d.zc_desc.get(i as usize).map(String::as_str).unwrap_or_default();
            let (pre, cur) = (g(layout.zc_pre_off), g(layout.zc_off));
            omclog::info!(stream, false, "[{}] (pre: {pre}) {cur} = {desc}", i + 1);
        }
        omclog::close(stream);
    });
    Ok(())
}

/// The `pre` values C's `checkForDiscreteChanges` compares against. Read *before*
/// the evaluation: an emitted `functionAlgebraics` ends with C's `storePreValues`,
/// so afterwards the mirror already holds the new values.
fn discrete_pre_values(e: &dyn SimEngine, sim_data: u32) -> Result<(Vec<f64>, Vec<i32>)> {
    event_dump_store::with(|d| {
        let reals = d.reals.iter().map(|(_, _, pre)| read_f64(e, sim_data + pre)).collect::<Result<_>>()?;
        let ints = d
            .ints
            .iter()
            .chain(&d.bools)
            .map(|(_, _, pre)| read_i32(e, sim_data + pre))
            .collect::<Result<_>>()?;
        Ok((reals, ints))
    })
}

/// C's `checkForDiscreteChanges` printing half; the detection half is
/// [`discrete_snapshot`], which compares the same regions in bulk.
fn log_discrete_changes(e: &dyn SimEngine, sim_data: u32, before: &(Vec<f64>, Vec<i32>)) -> Result<()> {
    let time = format_g(read_f64(e, sim_data + TIME_OFF)?, 12);
    omclog::info!(omclog::EVENTS_V, true, "check for discrete changes at time={time}");
    event_dump_store::with(|d| {
        for ((name, live, _), v1) in d.reals.iter().zip(&before.0) {
            let v2 = read_f64(e, sim_data + live)?;
            if *v1 != v2 {
                let line = format!("discrete var changed: {name} from {} to {}", format_g(*v1, 6), format_g(v2, 6));
                omclog::info(omclog::EVENTS_V, false, &line);
            }
        }
        let n_int = d.ints.len();
        for ((name, live, _), v1) in d.ints.iter().zip(&before.1) {
            let v2 = read_i32(e, sim_data + live)?;
            if *v1 != v2 {
                omclog::info!(omclog::EVENTS_V, false, "discrete var changed: {name} from {v1} to {v2}");
            }
        }
        for ((name, live, _), v1) in d.bools.iter().zip(&before.1[n_int..]) {
            let b = |v: i32| if v != 0 { "true" } else { "false" };
            let v2 = read_i32(e, sim_data + live)?;
            if *v1 != v2 {
                let line = format!("discrete var changed: {name} from {} to {}", b(*v1), b(v2));
                omclog::info(omclog::EVENTS_V, false, &line);
            }
        }
        Ok(())
    })?;
    omclog::close(omclog::EVENTS_V);
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
    e.call2(MODEL_FN_ZC, sim_data, sim_data + layout.zc_off)?;
    for (i, v) in out.iter_mut().enumerate() {
        *v = read_f64(e, sim_data + layout.zc_off + (i as u32) * 8)?;
    }
    Ok(())
}

/// C's `bisection`: the crossings at `time` off their own equations. A subset, so
/// an assert outside it does not fire on every trial point of the root search.
fn probe_zero_crossings(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout, time: f64, out: &mut [f64]) -> Result<()> {
    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
    write_time(e, sim_data, time)?;
    eval_zc_equations(e, sim_data, layout)?;
    read_zero_crossings(e, sim_data, layout, out)
}

/// Drop the violations [`update_zero_crossings`] kept for a row evaluated again since.
fn supersede(e: &mut dyn SimEngine, evaluated: &mut bool) {
    if core::mem::take(evaluated) {
        let _ = e.take_pending_warnings();
    }
}

/// C's `updateContinuousSystem` + `saveZeroCrossings`, what `checkForStateEvent`
/// compares against: detection runs off a full evaluation. `keep` holds this pass's
/// violations for a row emitted from it.
fn update_zero_crossings(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    time: f64,
    out: &mut [f64],
    keep: bool,
) -> Result<()> {
    // Flush older ones, so only this pass's are in hand below.
    drain_asserts(e, sim_data, omclog::INFO)?;
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;
    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
    write_time(e, sim_data, time)?;
    eval_continuous(e, sim_data, layout)?;
    if !keep {
        let _ = e.take_pending_warnings();
    }
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

/// C's `findRoot`/`bisection` (`events.c`) with only `time` varying. Returns the
/// bracket's two ends: the point `findRoot` evaluates at, and C's event time.
fn locate_zc_root(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    mut a: f64,
    mut b: f64,
    zc_left: &[f64],
    zc_right: &[f64],
) -> Result<(f64, f64)> {
    let hunted = zc_crossed_idx(zc_left, zc_right);
    let ttol = MINIMAL_STEP_SIZE + MINIMAL_STEP_SIZE * libm::fabs(b - a);
    let mut iters = bisection_iterations(b - a, ttol);
    let mut pre = zc_left.to_vec();
    let mut cur = zc_right.to_vec();
    let mut backup = cur.clone();
    while libm::fabs(b - a) > MINIMAL_STEP_SIZE && iters > 0 {
        iters -= 1;
        let c = 0.5 * (a + b);
        probe_zero_crossings(e, sim_data, layout, c, &mut cur)?;
        // C's `checkZeroCrossings`
        let in_left = hunted
            .iter()
            .any(|&i| (cur[i] == -1.0 && pre[i] == 1.0) || (cur[i] == 1.0 && pre[i] == -1.0));
        if in_left {
            b = c;
            backup.copy_from_slice(&cur);
        } else {
            a = c;
            pre.copy_from_slice(&cur);
            cur.copy_from_slice(&backup);
        }
    }
    Ok((a, b))
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
    iterate_discrete_from(e, sim_data, layout, false, None)
}

/// [`iterate_discrete`] entered after the first `functionDAE` has already run, as
/// C's loop is: its body opens with `storePreValues`, so the values that pass
/// assigned are what the next one reads as `pre()`. Without it a `when` body's
/// assignment is undone by the `x := pre(x)` its own equation block opens with.
pub(crate) fn iterate_discrete_after_eval(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    dae: Option<&mut (dyn FnMut(&mut dyn SimEngine) -> Result<()> + '_)>,
) -> Result<()> {
    iterate_discrete_from(e, sim_data, layout, true, dae)
}

/// [`iterate_discrete`] where DAE mode makes `functionDAE` C's `ida_event_update`:
/// `dae` ends every pass, so each settles around consistent algebraic unknowns.
pub(crate) fn iterate_discrete_dae(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    dae: &mut dyn FnMut(&mut dyn SimEngine) -> Result<()>,
) -> Result<()> {
    iterate_discrete_from(e, sim_data, layout, false, Some(dae))
}

fn iterate_discrete_from(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    evaluated: bool,
    mut dae: Option<&mut (dyn FnMut(&mut dyn SimEngine) -> Result<()> + '_)>,
) -> Result<()> {
    rtclock::tick(rtclock::DISCRETE); // C's `callStatistics.updateDiscreteSystem`
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
        if iter > 0 || evaluated {
            seed_pre_from_live(e, sim_data, layout)?;
        }
        update_relations_pre(e, sim_data, layout)?;
        if iter > 0 {
            log_event_status(e, sim_data, layout, omclog::EVENTS_V)?;
        }
        let events_v = omclog::active(omclog::EVENTS_V);
        let before = if events_v { Some(discrete_pre_values(e, sim_data)?) } else { None };
        eval_discrete(e, sim_data, layout)?;
        if let Some(dae) = dae.as_deref_mut() {
            dae(e)?;
        }
        log_reinits(e);
        if let Some(before) = &before {
            log_discrete_changes(e, sim_data, before)?;
        }
        if discrete_snapshot(e, sim_data, layout)? == prev {
            return Ok(());
        }
        iter += 1;
        if iter > max {
            omclog::debug!(
                omclog::ASSERT,
                false,
                "Simulation terminated due to too many, i.e. {max}, event iterations.\n                     This could either indicate an inconsistent system or an undersized limit of                      event iterations.\nThe limit of event iterations can be specified using the                      runtime flag '\u{2013}mei=<value>'.",
            );
            return Err(ASSERT_ERR);
        }
    }
}

/// C's `updateDiscreteSystem` as a whole: the exact relation sweep, the event
/// iteration and the held snapshot it leaves behind. The relations are live for the
/// evaluations in between — C's `discreteCall`, which `functionDAE` sets on entry
/// and clears on exit.
pub(crate) fn update_discrete_system(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
) -> Result<()> {
    write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
    let r = refresh_relations(e, sim_data, layout)
        .and_then(|_| iterate_discrete(e, sim_data, layout))
        .and_then(|_| store_relations(e, sim_data, layout));
    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
    r
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
        })
    }

    /// The samples due at `t` as `(k, start, interval)`, C's `handleEvents`
    /// `LOG_EVENTS` line.
    pub fn due(&self, t: f64) -> impl Iterator<Item = (usize, f64, f64)> + '_ {
        (0..self.next.len())
            .filter(move |&k| self.next[k] <= t + SAMPLE_EPS)
            .map(move |k| (k, self.start[k], self.interval[k]))
    }

    /// Time of the next sample event (min of `next`), or +inf if there are none.
    pub fn next_time(&self) -> f64 {
        self.next.iter().copied().fold(f64::INFINITY, f64::min)
    }

    /// Fire every sample due at `t`: raise its `active` flag, run the discrete
    /// update ([`eval_discrete`] — evaluates the sample conditions, the
    /// when-bodies on their rising edge, and saves pre-values), then clear the
    /// flags and advance the fired samples by their interval. `t` is written as
    /// the current simulation time first.
    pub fn fire(
        &mut self,
        e: &mut dyn SimEngine,
        sim_data: u32,
        layout: &SimLayout,
        t: f64,
    ) -> Result<()> {
        rethrow_store::note_event();
        let mut fired = vec![false; self.next.len()];
        for k in 0..self.next.len() {
            if self.next[k] <= t + SAMPLE_EPS {
                fired[k] = true;
                write_i32(e, self.active_off + k as u32 * 4, 1)?;
            }
        }
        write_time(e, sim_data, t)?;
        eval_discrete(e, sim_data, layout)?;
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
    dae: Option<&mut (dyn FnMut(&mut dyn SimEngine) -> Result<()> + '_)>,
) -> Result<()> {
    let addr = e.error_stage_addr();
    let save = set_error_stage(e, addr, ERROR_EVENTHANDLING);
    let r = fire_time_event_inner(e, samples, sim_data, layout, te, dae);
    took_error_stage(e, addr, save);
    if r.is_err() {
        note_throw_past_step();
    }
    r
}

fn fire_time_event_inner(
    e: &mut dyn SimEngine,
    samples: &mut Samples,
    sim_data: u32,
    layout: &SimLayout,
    te: f64,
    dae: Option<&mut (dyn FnMut(&mut dyn SimEngine) -> Result<()> + '_)>,
) -> Result<()> {
    write_time(e, sim_data, te)?;
    write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
    refresh_relations(e, sim_data, layout)?;
    samples.fire(e, sim_data, layout, te)?;
    iterate_discrete_after_eval(e, sim_data, layout, dae)?;
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
        write_time(e, sim_data, time)?;
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
    fire_clocks(e, sync, model, sim_data, time, SYNC_EPS, None)
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
    event_update_dae(e, sim_data, layout, samples, time, None)
}

/// [`event_update`] where DAE mode makes `functionDAE` C's `ida_event_update`:
/// `dae` ends every event-iteration pass, so the algebraic unknowns and the
/// derivatives are consistent with the discrete state each pass leaves behind.
/// Without it the integrator restarts on the values of the pass before the last.
pub fn event_update_dae(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    samples: Option<&mut Samples>,
    time: f64,
    dae: Option<&mut (dyn FnMut(&mut dyn SimEngine) -> Result<()> + '_)>,
) -> Result<EventUpdate> {
    let addr = e.error_stage_addr();
    let save = set_error_stage(e, addr, ERROR_EVENTHANDLING);
    let r = event_update_inner(e, sim_data, layout, samples, time, dae);
    took_error_stage(e, addr, save);
    if r.is_err() {
        note_throw_past_step();
    }
    r
}

fn event_update_inner(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    samples: Option<&mut Samples>,
    time: f64,
    mut dae: Option<&mut (dyn FnMut(&mut dyn SimEngine) -> Result<()> + '_)>,
) -> Result<EventUpdate> {
    rethrow_store::note_event();
    let n_states = layout.n_states as usize;
    let states_base = sim_data + REAL_OFF;
    let mut before = vec![0.0f64; n_states];
    for (i, v) in before.iter_mut().enumerate() {
        *v = read_f64(e, states_base + (i as u32) * 8)?;
    }

    write_time(e, sim_data, time)?;
    write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;

    let mut samples = samples;
    let time_event = samples.as_ref().is_some_and(|s| s.next_time() <= time + SAMPLE_EPS);
    if time_event {
        if let Some(s) = samples.as_deref_mut() {
            fire_time_event(e, s, sim_data, layout, time, dae.as_deref_mut())?;
        }
    } else {
        // `pre(x)` of a continuous variable must be its value at the crossing.
        save_pre_real(e, sim_data, layout)?;
        refresh_relations(e, sim_data, layout)?;
        iterate_discrete_from(e, sim_data, layout, false, dae.as_deref_mut())?;
        store_relations(e, sim_data, layout)?;
        check_nls(e, sim_data, layout)?;
    }

    let mut states_changed = false;
    for (i, b) in before.iter().enumerate() {
        if read_f64(e, states_base + (i as u32) * 8)? != *b {
            states_changed = true;
            break;
        }
    }
    // C's `needToIterate` after a `reinit`: the derivatives came from the state the
    // event replaced. Without one the last event-iteration pass left them consistent.
    if states_changed && !time_event {
        eval_ode(e, sim_data, layout)?;
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
    let tol_zc = 1e-4 * rtol.max(1e-12);
    omclog::info!(
        omclog::EVENTS_V,
        false,
        "Set tolerance for zero-crossing hysteresis to: {}",
        omclog::e(tol_zc, 0, 6),
    );
    write_f64(e, sim_data + layout.zctol_off, tol_zc)
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

/// The `-s` values C serves from `dassl.c`.
/// C's `realVarsData[i].info.name` for the states: the first `n` real result columns.
fn state_names(model: &SimModel, n: usize) -> Vec<String> {
    (0..n)
        .map(|i| {
            model
                .vars
                .iter()
                .find(|v| {
                    matches!(v.kind, ResultKind::Column { col, .. } if col as usize == i + 1)
                        && v.filter & crate::var_filter::ALIAS == 0
                })
                .map(|v| v.name.clone())
                .unwrap_or_default()
        })
        .collect()
}

fn is_dassl(method: &str) -> bool {
    matches!(method, "dassl" | "dasslrt" | "dassljac" | "")
}

/// Whether this build's `SolverCore` can serve `method`. `dassljac` is dassl
/// with a symbolic Jacobian and `""` the dassl default.
fn check_method(method: &str) -> bool {
    is_dassl(method)
        || matches!(method, "euler" | "rungekutta" | "gbode" | "qss" | "symSolver" | "symSolverSsc")
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

/// [`resolve_solver_method`] plus C's "no states present" swap, which lives in
/// `startNonInteractiveSimulation` — an FMU steps with the method it was exported
/// with, so only a standalone run applies it.
fn resolve_sim_solver_method<'a>(method: &'a str, layout: &SimLayout) -> Result<&'a str> {
    let method = resolve_solver_method(method, layout.dae_mode())?;
    // C warns before the swap below.
    crate::fixedstep::deprecation_warning(method);
    // C exempts `optimization` and `symSolver`.
    let nothing_to_solve = match layout.dae_mode() {
        true => layout.n_dae_res + layout.n_dae_alg < 1,
        false => layout.n_states < 1,
    };
    if nothing_to_solve && !matches!(method, "optimization" | "symSolver") {
        omclog::info(omclog::SOLVER, false, "No states present, continuing without ODE solver.");
        return Ok("euler");
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
    let jac_a = match env_var("OMC_WASM_NO_ANALYTIC_JAC").is_some() {
        true => None,
        false => model.jac_a.as_ref(),
    };
    let colors = jac_a.map_or(0, |j| j.colors.len());
    let sym = jac_a.is_some_and(|j| j.sym.is_some());
    let tol = if model.tolerance > 0.0 { model.tolerance } else { 1e-6 };
    let gb =
        crate::gbode::Gbode::new(layout.n_states as usize, tol, layout.n_zc as usize, colors, sym)
            .map_err(leak_error)?;
    Ok(Some(alloc::boxed::Box::new(gb)))
}

pub fn make_driver(
    e: &mut (dyn SimEngine + 'static),
    model: &SimModel,
    sim_data: u32,
    method: &str,
) -> Result<(Box<dyn Driver>, &'static str)> {
    let method = resolve_sim_solver_method(method, &model.layout)?;
    make_driver_resolved(e, model, sim_data, method)
}

/// C's flag warnings and `initializeNonlinearSystems`, between resolving the
/// solver flag and `initializeModel`. The in-wasm Euler loop builds no
/// [`Driver`], so it calls this itself.
fn solver_setup(e: &mut dyn SimEngine, model: &SimModel, sim_data: u32) -> Result<()> {
    let layout = &model.layout;
    arm_alarm();
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
    // C's `initializeLinearSystems` / `initializeNonlinearSystems` announcements,
    // which a host that runs those functions itself has already made.
    if !e.host_logs_system_init() {
        omclog::info(omclog::LS, true, "initialize linear system solvers");
        omclog::info!(omclog::LS, false, "{} linear systems", model.n_lin_systems);
        omclog::close(omclog::LS);
        omclog::info(omclog::NLS, true, "initialize non-linear system solvers");
        omclog::info!(omclog::NLS, false, "{} non-linear systems", model.nls_vars.len());
        omclog::close(omclog::NLS);
    }
    set_zc_tolerance(e, sim_data, layout, model.tolerance.min(model.step_size()))?;
    crate::parmod::init(model);
    for k in 0..layout.n_sens {
        write_f64(e, sim_data + layout.sens_off + k * 8, 0.0)?;
    }
    Ok(())
}

/// [`make_driver`] over an already-resolved method, so `drive` does not announce
/// the overrides twice.
fn make_driver_resolved(
    e: &mut (dyn SimEngine + 'static),
    model: &SimModel,
    sim_data: u32,
    method: &str,
) -> Result<(Box<dyn Driver>, &'static str)> {
    let layout = &model.layout;
    // Both `drive` and the in-wasm `rt_sim_start` build their driver here.
    solver_setup(e, model, sim_data)?;
    let gbode = alloc_gbode(model, method)?;

    // C configures the solver before `initializeModel`, so the method it settles on
    // is announced here; the drivers resolve the same thing again, silently.
    let jac_a_avail = match env_var("OMC_WASM_NO_ANALYTIC_JAC").is_some() {
        true => None,
        false => model.jac_a.as_ref(),
    };
    #[cfg(sundials)]
    if method == "ida" {
        ida_jacobian_method(jac_a_avail, ida_linear_solver(layout), true);
    }
    if is_dassl(method) {
        set_jacobian_method(jac_a_avail, true);
    }
    // C's `solver_main` runs QSS from its own branch: it has no event handling and
    // no output grid, so it never reaches the standard solver interface.
    if method == "qss" {
        return Ok((Box::new(crate::qss::Qss::new(e, model, sim_data)?), "qss"));
    }
    // DAE mode always takes the `SolverCore` path: the consistent-restart its
    // discrete update needs lives there.
    // A clocked partition is an event source too, and only `EventsDriver` has the
    // timer list and the consistent restart a tick needs.
    let events = layout.n_samples > 0 || layout.n_zc > 0 || !model.clocks.is_empty();
    let sym = sym_kind(method, layout).is_some();
    // C runs the step anyway and the generated `symbolicInlineSystem` stub fails it;
    // naming the missing translation flag is more use than that.
    if !sym && matches!(method, "symSolver" | "symSolverSsc") {
        return Err(NO_SYM_SOLVER);
    }
    if events || method == "gbode" || sym || layout.dae_mode() {
        let label = match method {
            "cvode" => "cvode-events",
            "ida" if events => "ida-events",
            "ida" => "ida",
            "gbode" => "gbode",
            "euler" => "euler-events",
            "rungekutta" => "rungekutta",
            "symSolver" => "symSolver",
            "symSolverSsc" => "symSolverSsc",
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

/// Whether `-csvInput` was given; never in wasm, which has no filesystem.
fn csv_input_given() -> bool {
    #[cfg(feature = "std")]
    return crate::simflags::with_flags(|f| f.csv_input.is_some());
    #[cfg(not(feature = "std"))]
    false
}

const NO_SYM_SOLVER: &str = "CodegenWasmJit: the model was not translated with \
--symSolver=impEuler or --symSolver=expEuler, so it has no symbolic inline system to step";

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
        omclog::warning!(
            omclog::STDOUT,
            false,
            "Steady state has not been reached.\nThis may be due to too restrictive relative \
             tolerance ({}) or short stopTime ({}).",
            format_g(tol, 6),
            format_g(model.stop_time, 6),
        );
    }
    signal_teardown();
    e.call1_if_present("callExternalObjectDestructors", sim_data)?;
    read_params(e, model, sim_data)
}

/// The `Param` signals' values, in signal order (C's `writeParameterData`).
pub fn read_params(e: &mut dyn SimEngine, model: &SimModel, sim_data: u32) -> Result<Vec<f64>> {
    let mut params = Vec::new();
    for v in &model.vars {
        if let ResultKind::Param { off, wty, .. } = &v.kind {
            let val = if v.ty == crate::VarTy::String {
                crate::strings::intern(&e.string_at(sim_data + off)?) as f64
            } else {
                match wty {
                    WTy::F64 => read_f64(e, sim_data + off)?,
                    WTy::I32 => read_i32(e, sim_data + off)? as f64,
                }
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

    // C's `measure_time_flag`: the clocks run only when the block that renders
    // them will be printed.
    // `+profiling` is C's other `measure_time_flag` source.
    rtclock::reset(omclog::active(omclog::STATS) || omclog::active(omclog::STATS_V) || model.prof.is_some());
    rtclock::tick(rtclock::TOTAL);
    let lv_time = crate::simflags::with_flags(|f| f.lv_time);
    if let Some((t0, t1)) = lv_time {
        omclog::info!(
            omclog::STDOUT,
            false,
            "Time dependent logging enabled. Activate logging in interval [{t0:.6}, {t1:.6}]",
        );
        // C reactivates the streams before `callSolver` when the run starts inside the window.
        if start >= t0 {
            omclog::reactivate();
            e.set_log_mask(omclog::mask());
        }
    }
    rtclock::tick(rtclock::PREINIT);
    crate::profiling::start(e, model);

    let mut stats = SolveStats::default();
    let use_events = layout.n_samples > 0 || layout.n_zc > 0 || !model.clocks.is_empty();
    let method = resolve_sim_solver_method(method, layout)?;

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
                let (mut driver, _) = make_driver_resolved(e, model, sim_data, "euler")
                    .map_err(|err| enrich_trap_init(e, err, model.start_time))?;
                open_result(e, model, sim_data)?;
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
                // C's `initialize{Linear,Nonlinear}Systems` run whatever the
                // method; the others reach them through `make_driver_resolved`.
                solver_setup(e, model, sim_data)?;
                run_initialization_model(e, sim_data, model)
                    .map_err(|err| enrich_trap_init(e, err, start))?;
                open_result(e, model, sim_data)?;
                return crate::optimization::run_optimizer(e, model, sim_data)
                    .map_err(|err| enrich_trap(e, err));
            }
            #[cfg(not(all(ipopt, feature = "std")))]
            unreachable!("optimization::AVAILABLE is false");
        }
        // `-csvInput` moves the inputs between steps, which the in-wasm loop cannot
        // do: it never returns until it is done. Nor can it retry a step a model
        // error threw in (C's `retrySimulationStep`), which is why a model that only
        // reached `euler` for want of states -- where the loop saves nothing anyway,
        // there being no integration -- keeps the host driver. `+profiling` also
        // needs the row-emitting loop (`fmtEmitStep`), so it stays off this path.
        if !use_events
            && method == "euler"
            && layout.n_states > 0
            && layout.n_str_alg() == 0
            && e.has_simulate_entry()
            && !host_driven
            && !csv_input_given()
            && model.prof.is_none()
            && model.parmod.is_none()
        {
            // Fast in-wasm Euler (one host->wasm call; not resumable/cancellable).
            label = "euler-wasm";
            solver_setup(e, model, sim_data)?;
            let mut rows = run_wasm(e, sim_data, n_reals, n_rows, model, start, stop, &mut stats)?;
            open_result(e, model, sim_data)?;
            emit_terminal_row(e, &mut rows, sim_data, layout, n_reals, None)?;
            return Ok(rows);
        }
        // enrich_trap: a trap in init/integration is usually a failed model assert().
        let (mut driver, l) =
            make_driver_resolved(e, model, sim_data, method).map_err(|err| enrich_trap_init(e, err, model.start_time))?;
        label = l;
        open_result(e, model, sim_data)?;
        // C's bracket up to `externalInputFree`: from here on the file drives the
        // inputs. Initialization got its one application in `apply_external_input`.
        #[cfg(feature = "std")]
        let mut hook =
            crate::extinput::ExtInputHook::load(&model.inputs, crate::extinput::Slot::Live);
        #[cfg(feature = "std")]
        let _armed = hook.as_mut().map(crate::extinput::arm);
        // Infinite budget runs to completion; the per-step cancel poll still lets a
        // native embedder interrupt. `OMC_WASM_SIM_YIELD_MS` forces a finite budget to
        // self-test yield/resume (must be `.mat`-identical to the un-yielded run).
        let budget_ms = env_var("OMC_WASM_SIM_YIELD_MS")
            .and_then(|v| v.parse::<f64>().ok())
            .unwrap_or(f64::INFINITY);
        loop {
            let advanced = match driver.advance(e, model, budget_ms) {
                Ok(a) => a,
                // C's `performSimulation` catch.
                Err(err) => match is_model_throw(err) && driver.retry_step(e, model)? {
                    true => continue,
                    false => {
                        // C reaches `simulationUpdate` even on a failed step: one
                        // more evaluation where the integrator stopped, then the line.
                        if let Some(t) = solver_fail_store::take() {
                            let mut last = Vec::new();
                            open_assert_window();
                            let updated = emit_row(e, &mut last, sim_data, layout, t, stop);
                            let _ = close_assert_window(e, sim_data).and(updated);
                            omclog::info!(
                                omclog::STDOUT,
                                false,
                                "model terminate | Integrator failed. | Simulation terminated at time {}",
                                format_g(t, 6),
                            );
                        }
                        return Err(enrich_trap(e, err));
                    }
                },
            };
            match advanced {
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
    if lv_time.is_some() {
        omclog::deactivate();
    }
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
    let mut rows = match outcome {
        Ok(rows) => rows,
        // C's `dataReconciliation(data, threadData, status)` with a non-zero status:
        // the run failed, so the procedure writes its error report and exits.
        Err(e) => {
            report_run_failure(model);
            return Err(e);
        }
    };
    stats.method = label;

    // C's `finishSimulation` order: this line, then the caller's LOG_STATS block.
    let out_names = crate::simflags::with_flags(|f| f.output_vars.clone());
    if !out_names.is_empty() {
        write_output_vars(e, model, sim_data, &rows, n_reals as usize, &out_names)?;
    }

    // C runs the `-reconcile*` procedures between the solver and `linearize`, and
    // prints their output after the run's success line — which is where the
    // caller's capture split puts anything logged past the teardown below.
    let (recon_log, recon_res) = reconcile(e, model, sim_data);
    let lin = match recon_res.is_ok() {
        true => crate::linearize::linearize(e, model, sim_data)?,
        false => None,
    };
    let params = finalize_run(e, model, sim_data)?;
    if !recon_log.is_empty() {
        log_line(crate::omclog::STDOUT, crate::omclog::INFO, &recon_log);
    }
    recon_res?;
    crate::parmod::finish();
    finish_rows(&mut rows);
    rtclock::accumulate(rtclock::TOTAL);
    crate::profiling::end_of_run(e);
    (stats.timers, stats.tcalls) = rtclock::snapshot();
    stats.systems = e.sys_stats();
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
    /// Where a retried step ends, short of this row's grid point.
    pending_time: Option<f64>,
    dss: StateSelection,
    rows: Vec<f64>,
    retry: StepRetry,
}

impl EulerDriver {
    fn new(e: &mut dyn SimEngine, model: &SimModel, sim_data: u32) -> Result<Self> {
        // Init (with homotopy fallback). No state events on this path, so relations
        // stay fresh (mode 2, set by run_initialization); `rt_solve_nls` still holds
        // them internally around its Newton solve.
        run_initialization_model(e, sim_data, model)?;
        let n_rows = model.n_output_rows();
        let n_reals = model.layout.n_row_total();
        let mut retry = StepRetry::default();
        retry.store(e, sim_data, &model.layout)?;
        // The initial selection belongs to initialization, before row 0 (see
        // `StateSelection::initial`); only the per-step ones are in `advance`.
        let dss = StateSelection::initial(e, sim_data, model)?;
        Ok(EulerDriver {
            sim_data,
            row: 0,
            pending_time: None,
            dss,
            rows: Vec::with_capacity((n_rows * n_reals) as usize),
            retry,
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
            rotate_old_real(e, sim_data, layout)?;
            // The last row lands exactly on `stop`: the terminal step.
            let time =
                self.pending_time.take().unwrap_or(if self.row == n_steps { stop } else { grid(self.row) });
            let t_now = read_f64(e, sim_data + TIME_OFF)?;
            logging_window(e, t_now, time);
            self.retry.open(e, &mut self.rows);
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
            self.retry.close(e)?;
            self.retry.store(e, sim_data, layout)?;
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
            if self.dss.reselect(e, sim_data, model)? {
                e.call1("functionODE", sim_data)?;
            }
            // Forward-Euler update of the states, over this row's own step.
            let h = grid(self.row + 1) - time;
            for i in 0..n_states {
                let s = read_f64(e, states_base + i * 8)?;
                let d = read_f64(e, ders_base + i * 8)?;
                write_f64(e, states_base + i * 8, s + h * d)?;
            }
            self.row += 1;
        }
        Ok(Advance::Done)
    }

    fn retry_step(&mut self, e: &mut (dyn SimEngine + 'static), model: &SimModel) -> Result<bool> {
        let Some(t) = self.retry.undo(e, self.sim_data, &model.layout)? else {
            return Ok(false);
        };
        self.rows.truncate(self.retry.rows_mark);
        let n_steps = model.n_output_rows() - 1;
        let target = if self.row >= n_steps {
            model.stop_time
        } else {
            grid_time(self.row, model.start_time, model.stop_time, n_steps)
        };
        // C's `euler_step` runs before the point is evaluated; redo it over half.
        let h = (target - t) / 2.0;
        let states_base = self.sim_data + REAL_OFF;
        let ders_base = states_base + model.layout.n_states * 8;
        for i in 0..model.layout.n_states {
            let x = read_f64(e, states_base + i * 8)?;
            let d = read_f64(e, ders_base + i * 8)?;
            write_f64(e, states_base + i * 8, x + h * d)?;
        }
        self.pending_time = Some(t + h);
        Ok(true)
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
    /// `--symSolver`'s `inlineData`: the `__OMC_DT` slot and the `y$Old` region.
    inline_dt_off: u32,
    alg_old_off: u32,
    /// Number of residual (right-hand-side) evaluations, for the bench line.
    nfe: u64,
    /// `SimData` offset of the root callback's own g-value buffer (C's `gout`).
    zc_probe_off: u32,
    /// `SimData` offset of the accepted-point g-values, which the hand-written
    /// solvers probe through, as `gbode_events.c` does.
    zc_off: u32,
    /// Number of zero-crossings (root functions).
    n_zc: usize,
    /// A wasm trap / memory error captured inside the callback, surfaced after
    /// `ddaskr` returns (the C-style callback cannot return a `Result`).
    err: Option<&'static str>,
    /// What `dassl_jac` / `ida_jac` assemble from; null ⇒ the analytic path is off
    /// and the integrator differences its own.
    jac: *const JacAInfo,
    /// C's `dasslData->dasslJacobian` / `idaData->jacobianMethod`.
    jac_method: JacobianMethod,
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
    /// Linear-memory address of the runtime's evaluation context (0 = unsupported).
    ctx_addr: u32,
    /// Linear-memory address of the runtime's error stage (0 = unsupported).
    err_stage_addr: u32,
    /// The FD step's fallback scale: `n_states` nominals owned by the driver.
    nominals: *const f64,
    nominal_factor: f64,
    /// Relative tolerance; with `nominals` it gives the first step's floor.
    tol: f64,
    /// For `LOG_JAC`; null when the driver keeps none.
    state_names: *const Vec<String>,
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
    ramp: LambdaRamp,
}

#[cfg(sundials)]
impl Default for IdaCtx {
    fn default() -> Self {
        IdaCtx {
            mem: core::ptr::null_mut(),
            pattern: core::ptr::null(),
            sens: SensPush::default(),
            dae: core::ptr::null(),
            ramp: LambdaRamp::default(),
        }
    }
}

/// C's daeMode homotopy ramp (`ida_solver.c`): where the actual DAE Jacobian is
/// singular at the start point, `lambda` is ramped 0 → 1 over the start of the
/// interval with the integrator step capped. Armed only after IDA fails there.
#[cfg(sundials)]
#[derive(Clone, Copy, Default)]
struct LambdaRamp {
    /// `SimData` slot of `simulationInfo->lambda`.
    off: u32,
    start: f64,
    /// Ramp window; 0 until armed.
    tramp: f64,
    active: bool,
}

#[cfg(sundials)]
impl LambdaRamp {
    fn lambda_at(&self, t: f64) -> Option<f64> {
        if !self.active || self.tramp <= 0.0 {
            return None;
        }
        Some(if t < self.start + self.tramp { (t - self.start) / self.tramp } else { 1.0 })
    }
}

/// DASKR root (constraint) function: fills `rval[i]` with `g_i(t, y)`, the value
/// whose sign change is a state event. Writes the candidate `t`/`y` into SimData,
/// evaluates the continuous equations (`functionODE`) so any algebraics a
/// crossing depends on are current, then the emitted `functionZeroCrossings`, and
/// reads the results back. A trap is stashed in `ResCtx::err`. A model error
/// aborts the call, as C's `longjmp` out of the root function does
/// ([`Solved::RootThrew`]).
unsafe fn dassl_rt(
    _neq: *mut i32,
    t: *mut f64,
    y: *mut f64,
    _yprime: *mut f64,
    _nrt: *mut i32,
    rval: *mut f64,
    _rpar: *mut f64,
    _ipar: *mut i32,
) -> i32 {
    let ctx = RES_CTX.load(Ordering::Relaxed);
    if ctx.is_null() {
        return 1;
    }
    let ctx = unsafe { &mut *ctx };
    let e = unsafe { &mut *ctx.engine };
    let _clock = rtclock::Handover::new(rtclock::SOLVER, rtclock::EVENT);
    let hit_before = stage_hit(e, ctx.err_stage_addr);
    let run = (|| -> Result<()> {
        // A root probe may sit at an awkward candidate state where a nonlinear
        // system can't converge; keep that transient failure from leaking into the
        // next checked evaluation by clearing the flag around this probe.
        write_i32(e, ctx.sim_data + ctx.nls_fail_off, 0)?;
        write_time(e, ctx.sim_data, unsafe { *t })?;
        let y_bytes = unsafe { core::slice::from_raw_parts(y as *const u8, ctx.n_states * 8) };
        e.write_bytes(ctx.states_base, y_bytes)?;
        set_context(e, ctx.ctx_addr, CONTEXT_EVENTS);
        e.call1("functionZeroCrossingsEquations", ctx.sim_data)?;
        e.call2(MODEL_FN_ZC, ctx.sim_data, ctx.sim_data + ctx.zc_probe_off)?;
        set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
        let rval_bytes = unsafe { core::slice::from_raw_parts_mut(rval as *mut u8, ctx.n_zc * 8) };
        e.read_bytes(ctx.sim_data + ctx.zc_probe_off, rval_bytes)?;
        Ok(())
    })();
    match run {
        Err(err) => {
            ctx.err = Some(err);
            1
        }
        Ok(()) => (!hit_before && stage_hit(e, ctx.err_stage_addr)) as i32,
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
    let _clock = rtclock::Handover::new(rtclock::SOLVER, rtclock::RESIDUALS);
    let save = set_error_stage(e, ctx.err_stage_addr, ERROR_INTEGRATOR);
    let run = (|| -> Result<()> {
        write_i32(e, ctx.sim_data + ctx.nls_fail_off, 0)?; // clear before the solve
        write_time(e, ctx.sim_data, unsafe { *t })?;
        let y_bytes = unsafe { core::slice::from_raw_parts(y as *const u8, n * 8) };
        e.write_bytes(ctx.states_base, y_bytes)?;
        set_context(e, ctx.ctx_addr, CONTEXT_ODE);
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
    let model_error = took_error_stage(e, ctx.err_stage_addr, save);
    ctx.nfe += 1;
    match run {
        Err(err) if residual_model_throw(e, err, unsafe { *t }) => unsafe { *ires = -1 },
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

/// C's `JACOBIAN_AVAILABILITY` (`jacobian_util.h`).
#[derive(Clone, Copy, PartialEq, Eq)]
enum JacAvail {
    NotAvailable,
    OnlySparsity,
    Available,
}

/// What the model carries for the requested method. The adjoint Jacobian is a matrix
/// of its own, which this backend never emits, so asking for it finds nothing.
fn jac_availability(jac: Option<&JacAInfo>, requested: Option<JacobianMethod>) -> JacAvail {
    if requested == Some(JacobianMethod::ColoredSymJacAdj) {
        return JacAvail::NotAvailable;
    }
    match jac {
        None => JacAvail::NotAvailable,
        Some(j) if j.sym.is_some() => JacAvail::Available,
        Some(_) => JacAvail::OnlySparsity,
    }
}

/// C's `setJacobianMethod` (`jacobian_util.c`): the `-jacobian` value against what
/// the model carries. `log` prints the downgrade warnings and the `LOG_JAC` line,
/// which only [`make_driver`]'s call — ordered as C's — does.
fn set_jacobian_method(jac: Option<&JacAInfo>, log: bool) -> JacobianMethod {
    use JacobianMethod as M;
    let requested = crate::simflags::with_flags(|f| f.jacobian);
    let warn = |m: &str| {
        if log {
            omclog::warning(omclog::STDOUT, false, m);
        }
    };
    let method = match jac_availability(jac, requested) {
        JacAvail::NotAvailable => {
            if !matches!(requested, None | Some(M::InternalNumJac)) {
                warn("Jacobian not available, switching to internal numerical Jacobian.");
            }
            M::InternalNumJac
        }
        JacAvail::OnlySparsity => match requested {
            Some(M::ColoredSymJac) | Some(M::BicoloredSymJac) => {
                warn("Symbolic Jacobian not available, only sparsity pattern. Switching to colored numerical Jacobian.");
                M::ColoredNumJac
            }
            Some(M::SymJac) => {
                warn("Symbolic Jacobian not available, only sparsity pattern. Switching to numerical Jacobian.");
                M::NumJac
            }
            None => M::ColoredNumJac,
            Some(m) => m,
        },
        JacAvail::Available => requested.unwrap_or(M::ColoredSymJac),
    };
    if log {
        omclog::info!(omclog::JAC, false, "Using Jacobian method: {}", method.desc());
    }
    // Without an adjoint C's `evalJacobian` degenerates to the colored evaluation.
    match method {
        M::BicoloredSymJac if jac.and_then(|j| j.sym.as_ref()).is_none_or(|s| s.adj.is_none()) => {
            if log {
                omclog::warning(
                    omclog::SOLVER,
                    false,
                    "bicoloredSymbolical selected but Jacobian was not compiled bidirectionally; \
                     falling back to standard colored symbolic evaluation.",
                );
            }
            M::ColoredSymJac
        }
        m => m,
    }
}

/// Whether the method assembles from the symbolic column equations.
fn jac_method_symbolic(m: JacobianMethod) -> bool {
    matches!(m, JacobianMethod::SymJac | JacobianMethod::ColoredSymJac | JacobianMethod::BicoloredSymJac)
}

/// Whether the method evaluates once per colour rather than once per column.
fn jac_method_colored(m: JacobianMethod) -> bool {
    matches!(m, JacobianMethod::ColoredNumJac | JacobianMethod::ColoredSymJac)
}

/// One symbolic assembly of `∂f/∂y`: C's
/// `genericColoredSymbolicJacobianEvaluation` (`jacobianSymbolical.c`) when
/// `colored`, else `jacA_sym`'s column-at-a-time loop, which reads every row and
/// not just the pattern's. `set(row, col, k, value)` places one entry, `k` being
/// its index within the column. SimData already holds the linearization point, as
/// in C: the residual at `(t, y)` ran just before.
/// The model's symbolic ODE Jacobian, column by column (or colour by colour),
/// reported to `set` as `(row, column, index within the column, value)`.
///
/// Public because an exported FMU answers `fmi3GetDirectionalDerivative` from
/// it.
pub fn eval_sym_jacobian(
    e: &mut dyn SimEngine,
    sim_data: u32,
    jac: &JacAInfo,
    ctx_addr: u32,
    colored: bool,
    set: &mut dyn FnMut(usize, usize, usize, f64),
) -> Result<()> {
    let sym = jac.sym.as_ref().ok_or("CodegenWasmJit: no symbolic Jacobian to evaluate")?;
    let n = jac.n as usize;
    if sym.seed_offs.len() != n || sym.result_offs.len() != n {
        return Err("CodegenWasmJit: symbolic Jacobian seed/result count does not match the states");
    }
    // C's `setContext(CONTEXT_SYM_JACOBIAN)`: lets a linear system inside a column
    // reuse its matrix across one assembly.
    set_context(e, ctx_addr, CONTEXT_SYM_JACOBIAN);
    let per_column: Vec<Vec<u32>> = match colored {
        true => Vec::new(),
        false => (0..n as u32).map(|c| vec![c]).collect(),
    };
    let run = (|| -> Result<()> {
        for &off in &sym.seed_offs {
            write_f64(e, sim_data + off, 0.0)?;
        }
        if sym.has_constant {
            e.call1("functionJacA_constantEqns", sim_data)?;
        }
        let groups: &[Vec<u32>] = if colored { &jac.colors } else { &per_column };
        for group in groups {
            for &c in group {
                write_f64(e, sim_data + sym.seed_offs[c as usize], 1.0)?;
            }
            e.call1("functionJacA_column", sim_data)?;
            for &c in group {
                let col = c as usize;
                let read = |e: &mut dyn SimEngine, row: usize| -> Result<f64> {
                    match sym.result_offs[row] {
                        u32::MAX => Ok(0.0),
                        off => read_f64(e, sim_data + off),
                    }
                };
                match colored {
                    true => {
                        for k in 0..jac.rows_by_col[col].len() {
                            let row = jac.rows_by_col[col][k] as usize;
                            let v = read(e, row)?;
                            set(row, col, k, v);
                        }
                    }
                    false => {
                        for row in 0..n {
                            let v = read(e, row)?;
                            set(row, col, usize::MAX, v);
                        }
                    }
                }
                write_f64(e, sim_data + sym.seed_offs[col], 0.0)?;
            }
        }
        Ok(())
    })();
    set_context(e, ctx_addr, CONTEXT_ALGEBRAIC);
    run
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
    wt: *mut f64,
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
    let _clock = rtclock::Handover::new(rtclock::SOLVER, rtclock::JACOBIAN);
    // One assembly, however many colours it takes, as C's DASSL counts it.
    ctx.nje += 1;
    // C holds `ERROR_INTEGRATOR` over the whole DDASKR call, and there is no `IRES`
    // here: a model error at a perturbed point leaves the assembly as it stands.
    let save = set_error_stage(e, ctx.err_stage_addr, ERROR_INTEGRATOR);
    let colored = jac_method_colored(ctx.jac_method);
    // C's `jacA_num` / `jacA_sym`: one column at a time, every row of it.
    let per_column: Vec<Vec<u32>> = match colored {
        true => Vec::new(),
        false => (0..n as u32).map(|c| vec![c]).collect(),
    };
    let all_rows: Vec<u32> = match colored {
        true => Vec::new(),
        false => (0..n as u32).collect(),
    };
    let run = (|| -> Result<()> {
        write_time(e, ctx.sim_data, unsafe { *t })?;
        if ctx.jac_method == JacobianMethod::BicoloredSymJac {
            eval_bicolored_jacobian(e, ctx.sim_data, jac, ctx.ctx_addr, &mut |row, col, v| {
                unsafe { *pd.add(col * n + row) = 0.0 - v };
            })?;
        } else if jac_method_symbolic(ctx.jac_method) {
            // C's `jacA_symColored` / `jacA_sym`. This residual is G = y' − f, the
            // negative of C's F = f − y', so ∂f/∂y enters negated (and the `cj·I`
            // below is added where C subtracts it).
            eval_sym_jacobian(e, ctx.sim_data, jac, ctx.ctx_addr, colored, &mut |row, col, _, v| {
                unsafe { *pd.add(col * n + row) = 0.0 - v };
            })?;
        } else {
            set_context(e, ctx.ctx_addr, CONTEXT_JACOBIAN);
            let groups: &[Vec<u32>] = if colored { &jac.colors } else { &per_column };
            for group in groups {
                // Perturb every column in this colour; record del and the base value.
                for &col in group {
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
                for &col in group {
                    let ci = col as usize;
                    let del = ctx.jac_del[ci];
                    let rows: &[u32] = if colored { &jac.rows_by_col[ci] } else { &all_rows };
                    for &row in rows {
                        let ri = row as usize;
                        let d = ctx.jac_gp[ri] - unsafe { *base.add(ri) };
                        unsafe { *pd.add(ci * n + ri) = d / del };
                    }
                    unsafe { *y.add(ci) = ctx.jac_ysave[ci] };
                }
            }
            set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
            // Restore the base states in SimData.
            let y_bytes = unsafe { core::slice::from_raw_parts(y as *const u8, n * 8) };
            e.write_bytes(ctx.states_base, y_bytes)?;
        }
        // cj·∂G/∂y' = cj·I — the diagonal the ∂G/∂y assembly above does not carry.
        for col in 0..n {
            unsafe { *pd.add(col * n + col) += cj };
        }
        if jac_method_symbolic(ctx.jac_method) && omclog::active(omclog::JAC) {
            dassl_log_jacobian(ctx, e, unsafe { *t }, y, yprime, base, pd, cj, h, wt)?;
        }
        Ok(())
    })();
    set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
    took_error_stage(e, ctx.err_stage_addr, save);
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

/// C's `numericalJacobianStep` as `jacA_num` calls it.
fn fd_step_ewt(yi: f64, hyp: f64, ewt_inv: f64, nominal: f64) -> f64 {
    let scale = yi.abs().max(hyp.abs());
    let step = if scale > ewt_inv { scale } else { ewt_inv.max(nominal) };
    signed(DELTA_X_SOLVER * step, hyp)
}

/// C's `LOG_JAC` block: `printJacobianMatrix`, then the largest differences against
/// `jacA_num`. C's matrix is `∂F/∂y − cj·I` with `F = f − y'`; `pd` is its negative.
#[allow(clippy::too_many_arguments)]
unsafe fn dassl_log_jacobian(
    ctx: &mut ResCtx,
    e: &mut dyn SimEngine,
    t: f64,
    y: *mut f64,
    yprime: *mut f64,
    base: *mut f64,
    pd: *mut f64,
    cj: f64,
    h: f64,
    wt: *mut f64,
) -> Result<()> {
    let n = ctx.n_states;
    let names: Vec<String> = match ctx.state_names.is_null() {
        true => (0..n).map(|i| format!("{i}")).collect(),
        false => unsafe { (*ctx.state_names).clone() },
    };
    let name = |i: usize| names.get(i).map(String::as_str).unwrap_or("");
    let value = |col: usize, row: usize| -(unsafe { *pd.add(col * n + row) });
    omclog::info!(
        omclog::JAC,
        true,
        "DASSL-Solver: analytical Jacobian pd (column-major) at time={}",
        format_g(t, 6),
    );
    for col in 0..n {
        for row in 0..n {
            omclog::info!(
                omclog::JAC,
                false,
                "J(row={row}:'{}', col={col}:'{}') = {} [flat={}]",
                name(row),
                name(col),
                format_g(value(col, row), 16),
                col * n + row,
            );
        }
    }
    omclog::close(omclog::JAC);
    let mut numerical = vec![0.0f64; n * n];
    set_context(e, ctx.ctx_addr, CONTEXT_JACOBIAN);
    for col in (0..n).rev() {
        let yi = unsafe { *y.add(col) };
        let hyp = h * unsafe { *yprime.add(col) };
        let ewt_inv = (1.0 / unsafe { *wt.add(col) }).abs();
        let nom = unsafe { *ctx.nominals.add(col) };
        let mut del = fd_step_ewt(yi, hyp, ewt_inv, ctx.nominal_factor * nom);
        del = yi + del - yi;
        let inv = 1.0 / del;
        unsafe { *y.add(col) = yi + del };
        write_i32(e, ctx.sim_data + ctx.nls_fail_off, 0)?;
        let y_bytes = unsafe { core::slice::from_raw_parts(y as *const u8, n * 8) };
        e.write_bytes(ctx.states_base, y_bytes)?;
        e.call1("functionODE", ctx.sim_data)?;
        e.read_bytes(ctx.ders_base, &mut ctx.jac_ders)?;
        for row in 0..n {
            let f = f64::from_le_bytes(ctx.jac_ders[row * 8..row * 8 + 8].try_into().unwrap());
            // `base` is G = y' − f.
            let f_new = f - unsafe { *yprime.add(row) };
            let f_old = -unsafe { *base.add(row) };
            numerical[col * n + row] = (f_new - f_old) * inv;
        }
        unsafe { *y.add(col) = yi };
    }
    set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
    let y_bytes = unsafe { core::slice::from_raw_parts(y as *const u8, n * 8) };
    e.write_bytes(ctx.states_base, y_bytes)?;
    for k in 0..n {
        numerical[k * n + k] -= cj;
    }
    let (mut max_abs, mut max_rel) = (0.0f64, 0.0f64);
    let (mut abs_at, mut rel_at) = ((0usize, 0usize), (0usize, 0usize));
    for col in 0..n {
        for row in 0..n {
            let num = numerical[col * n + row];
            let abs_diff = (value(col, row) - num).abs();
            let rel_diff = abs_diff / num.abs().max(1e-15);
            if abs_diff > max_abs {
                max_abs = abs_diff;
                abs_at = (row, col);
            }
            if rel_diff > max_rel {
                max_rel = rel_diff;
                rel_at = (row, col);
            }
        }
    }
    omclog::info(omclog::JAC, true, "Jacobian verification: analytical vs. numerical");
    omclog::info!(
        omclog::JAC,
        false,
        "Max absolute difference: {} at (row={}:'{}', col={}:'{}')",
        format_g(max_abs, 6),
        abs_at.0,
        name(abs_at.0),
        abs_at.1,
        name(abs_at.1),
    );
    omclog::info!(
        omclog::JAC,
        false,
        "Max relative difference: {} at (row={}:'{}', col={}:'{}')",
        format_g(max_rel, 6),
        rel_at.0,
        name(rel_at.0),
        rel_at.1,
        name(rel_at.1),
    );
    omclog::close(omclog::JAC);
    Ok(())
}

/// C's `evalJacobianBidirectional`: a column phase over A's coloring and a row
/// phase over the adjoint's, each entry taken from the phase that recovers it alone
/// (`initBidirectionalRecovery`).
pub fn eval_bicolored_jacobian(
    e: &mut dyn SimEngine,
    sim_data: u32,
    jac: &JacAInfo,
    ctx_addr: u32,
    set: &mut dyn FnMut(usize, usize, f64),
) -> Result<()> {
    let sym = jac.sym.as_ref().ok_or("CodegenWasmJit: no symbolic Jacobian to evaluate")?;
    let adj = sym.adj.as_ref().ok_or("CodegenWasmJit: no adjoint Jacobian to evaluate")?;
    let n = jac.n as usize;
    let mut col_color = vec![0usize; n];
    for (c, cols) in jac.colors.iter().enumerate() {
        for &col in cols {
            col_color[col as usize] = c;
        }
    }
    let mut row_color = vec![0usize; n];
    for (c, rows) in adj.row_colors.iter().enumerate() {
        for &row in rows {
            row_color[row as usize] = c;
        }
    }
    let mut cols_by_row: Vec<Vec<usize>> = vec![Vec::new(); n];
    for (col, rows) in jac.rows_by_col.iter().enumerate() {
        for &row in rows {
            cols_by_row[row as usize].push(col);
        }
    }
    let fwd_ok = |row: usize, col: usize| {
        cols_by_row[row].iter().all(|&c2| c2 == col || col_color[c2] != col_color[col])
    };
    let adj_ok = |row: usize, col: usize| {
        jac.rows_by_col[col].iter().all(|&r2| r2 as usize == row || row_color[r2 as usize] != row_color[row])
    };
    set_context(e, ctx_addr, CONTEXT_SYM_JACOBIAN);
    let run = (|| -> Result<()> {
        for &off in sym.seed_offs.iter().chain(adj.seed_offs.iter()) {
            write_f64(e, sim_data + off, 0.0)?;
        }
        if sym.has_constant {
            e.call1("functionJacA_constantEqns", sim_data)?;
        }
        if adj.has_constant {
            e.call1("functionJacADJ_constantEqns", sim_data)?;
        }
        for group in &jac.colors {
            for &c in group {
                write_f64(e, sim_data + sym.seed_offs[c as usize], 1.0)?;
            }
            e.call1("functionJacA_column", sim_data)?;
            for &c in group {
                let col = c as usize;
                for &r in &jac.rows_by_col[col] {
                    let row = r as usize;
                    if fwd_ok(row, col) {
                        let v = match sym.result_offs[row] {
                            u32::MAX => 0.0,
                            off => read_f64(e, sim_data + off)?,
                        };
                        set(row, col, v);
                    }
                }
                write_f64(e, sim_data + sym.seed_offs[col], 0.0)?;
            }
        }
        for &off in &adj.zero_offs {
            write_f64(e, sim_data + off, 0.0)?;
        }
        for group in &adj.row_colors {
            for &r in group {
                write_f64(e, sim_data + adj.seed_offs[r as usize], 1.0)?;
            }
            e.call1("functionJacADJ_column", sim_data)?;
            for &r in group {
                let row = r as usize;
                for &col in &cols_by_row[row] {
                    if adj_ok(row, col) {
                        let v = match adj.result_offs[col] {
                            u32::MAX => 0.0,
                            off => read_f64(e, sim_data + off)?,
                        };
                        set(row, col, v);
                    }
                }
                write_f64(e, sim_data + adj.seed_offs[row], 0.0)?;
            }
            // The row evaluator accumulates.
            for &off in &adj.zero_offs {
                write_f64(e, sim_data + off, 0.0)?;
            }
        }
        Ok(())
    })();
    set_context(e, ctx_addr, CONTEXT_ALGEBRAIC);
    run
}

/// C's `-noEquidistantTimeGrid` (`dassl.c`'s `dasslSteps`): DASKR's own steps are
/// the output points, not an interpolated equidistant grid.
fn no_equidistant_grid() -> bool {
    crate::simflags::with_flags(|f| f.no_equidistant_grid)
}

/// `perform_simulation`'s `currentStepSize < 1e-15`: an output point this close to
/// a handled event is skipped.
const GRID_SKIP_EPS: f64 = 1e-15;

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
    omclog::info!(omclog::DASSL, false, "new step at time = {}", format_g(t, 15));
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
    omclog::warning!(omclog::STDOUT, false, "can't continue. time = {t:.6}");
    solver_fail_store::set(t);
    SOLVER_FAILED_ERR
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

/// C's `realVarsData[i].attribute.nominal` for the states, which scales a
/// solver's absolute tolerance and is what `fmi3GetNominalsOfContinuousStates`
/// answers. Floored as `ida_solver_setNominals` does: read before
/// `initializeModel` has floored them, a zero nominal is an infinite error
/// weight.
pub fn state_nominals(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<Vec<f64>> {
    (0..layout.n_states)
        .map(|i| Ok(libm::fmax(libm::fabs(read_f64(e, sim_data + layout.state_nom_off + i * 8)?), 1e-32)))
        .collect()
}

/// [`state_nominals`], with the algebraic unknowns' nominals after them in DAE
/// mode (C's `getAlgebraicDAEVarNominals`), one per extra component of IDA's `y`.
/// Length ≥ 1 so daskr never sees an empty array.
fn read_state_nominals(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<Vec<f64>> {
    let mut nominals = state_nominals(e, sim_data, layout)?;
    for k in 0..layout.n_dae_alg {
        let n = read_f64(e, sim_data + layout.dae_alg_nom_off + k * 8)?;
        nominals.push(libm::fmax(libm::fabs(n), 1e-32));
    }
    if nominals.is_empty() {
        nominals.push(1.0);
    }
    Ok(nominals)
}

/// The states' `max` attributes, read like the nominals; gbode's FD step flips
/// its sign at the bound, as C's `gbode_setVarAttributes` data has it do.
fn read_state_maxs(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<Vec<f64>> {
    (0..layout.n_states).map(|i| read_f64(e, sim_data + layout.state_max_off + i * 8)).collect()
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
    dss: StateSelection,
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
    /// The "A" Jacobian's sparsity, coloring and symbolic columns; `None` ⇒ daskr's
    /// own numerical Jacobian.
    jac_a: Option<JacAInfo>,
    /// C's `dasslData->dasslJacobian`.
    jac_method: JacobianMethod,
    /// The states' names, in `y` order (`LOG_JAC`).
    state_names: Vec<String>,
    /// Jacobian evaluation count, accumulated across chunks (for the bench line).
    nje: u64,
    past: DaskrCounters,
    retry: StepRetry,
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
        // DASKR reports its own failures on stdout, as C's executable does — into
        // the run's captured output, not omc's console.
        daskr::auxiliary::xsetf(1);
        e.set_rhs_final(false); // C's `dassl_initial`
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
        // Dynamic state selection, then row 0 at the start time. For an explicit ODE
        // the consistent initial derivative is exactly f(t0, y0), which `functionODE`
        // (called by `emit_initial_row`) leaves in the derivative slots — so INFO(11)=0.
        let dss = StateSelection::initial(e, sim_data, model)?;
        emit_initial_row(e, &mut rows, sim_data, layout, start)?;
        let pending_terminate = terminated(e, sim_data, layout)?; // terminate() at the initial point

        let (mut y, mut yp) = (Vec::new(), Vec::new());
        if n_states > 0 && !pending_terminate {
            y = (0..n_states).map(|i| read_f64(e, states_base + (i as u32) * 8)).collect::<Result<_>>()?;
            yp = (0..n_states).map(|i| read_f64(e, ders_base + (i as u32) * 8)).collect::<Result<_>>()?;
        }
        // C's `storeOldValues` in `solver_main`.
        let mut retry = StepRetry::default();
        retry.store(e, sim_data, layout)?;

        // --- DASKR work arrays / options (dense, numerical Jacobian). ---
        let neq = n_states as i32;
        let nrt = 0i32;
        let tol = if model.tolerance > 0.0 { model.tolerance } else { 1e-6 };
        let lrw = (60 + 9 * neq + neq * neq + 3 * nrt + 64) as usize;
        let liw = (40 + neq + 64) as usize;
        // INFO(5)=1 selects daskr's dense user-Jacobian path.
        let jac_a = if env_var("OMC_WASM_NO_ANALYTIC_JAC").is_some() { None } else { model.jac_a.clone() };
        let jac_method = set_jacobian_method(jac_a.as_ref(), false);
        let mut info = [0i32; 24];
        if jac_method != JacobianMethod::InternalNumJac {
            info[4] = 1; // INFO(5)=1: a user Jacobian routine
        }
        // Per-state tolerances scaled by nominal, matching the C runtime
        // (`dassl.c`: INFO(2)=1, atol[i]=tol·max(|nominal_i|,1e-32)).
        let nominals = read_state_nominals(e, sim_data, layout)?;
        let (rtol, atol) = dassl_tolerances(tol, &nominals);
        if n_states > 0 {
            info[1] = 1; // INFO(2)=1: per-state (vector) rtol/atol
        }
        // C's `dassl_initial` sets INFO(3)=1 for every run, not just for
        // `-noEquidistantTimeGrid`: DASKR then returns after each internal step, so its
        // per-call quota of 500 steps (IDID=-1, reported on stdout by `xerrwd`) cannot
        // be spent on a stiff interval.
        if n_states > 0 {
            info[2] = 1;
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
            // per-step returns, no IC calc; INFO(5) set above when the
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
            dss,
            rows,
            pending_tout: None,
            step_emit: StepEmit::new(),
            no_grid_primed: false,
            work_retries: 0,
            pending_terminate,
            finished: false,
            jac_a,
            jac_method,
            state_names: state_names(model, n_states),
            nje: 0,
            past: DaskrCounters::default(),
            retry,
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
            // The step size is zero, so C's `dassl_step` takes its "desired step
            // size too small" branch instead of calling DASKR: a zero-length Euler
            // step, which leaves the states alone, and one `functionODE`.
            eval_ode(e, sim_data, layout)?;
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
                rotate_old_real(e, sim_data, layout)?;
                let time =
                    self.pending_tout.take().unwrap_or(if self.row == n_steps { stop } else { grid(self.row) });
                logging_window(e, self.t, time);
                self.retry.open(e, &mut self.rows);
                open_assert_window();
                let emitted = emit_row(e, &mut self.rows, sim_data, layout, time, model.stop_time);
                close_assert_window(e, sim_data).and(emitted)?;
                store_operators(e, sim_data, layout)?;
                self.retry.close(e)?;
                self.t = time;
                self.retry.store(e, sim_data, layout)?;
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
        let jacfn: solver::JacFn = match self.jac_method {
            JacobianMethod::InternalNumJac => solver::dummy_jacd,
            _ => dassl_jac,
        };
        let mut ctx = ResCtx {
            engine: &mut *e as *mut dyn SimEngine,
            sim_data,
            states_base,
            ders_base,
            n_states,
            nls_fail_off: layout.nls_fail_off,
            inline_dt_off: layout.inline_dt_off,
            alg_old_off: layout.alg_old_off,
            nfe: self.nfe,
            zc_probe_off: 0,
            zc_off: 0,
            n_zc: 0,
            err: None,
            jac: jac_ptr,
            jac_method: self.jac_method,
            jac_gp: vec![0.0; n_states],
            jac_ysave: vec![0.0; n_states],
            jac_del: vec![0.0; n_states],
            jac_ders: Vec::new(),
            jac_ypsave: Vec::new(),
            nje: self.nje,
            ctx_addr: e.context_addr(),
            err_stage_addr: e.error_stage_addr(),
            nominals: self.nominals.as_ptr(),
            nominal_factor: nominal_factor(),
            tol: self.tol,
            state_names: &self.state_names,
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
            rotate_old_real(e, sim_data, layout)?;
            self.retry.open(e, &mut self.rows);
            // IDID=-1: DASKR hit its per-call work quota before TOUT — resume with
            // INFO(1)=1, up to a cap. INFO(3)=1 keeps a call to one step, so this is
            // C's guard rather than a path a stiff interval takes.
            // `pending_tout`/`work_retries` persist an interval unfinished at a yield.
            let fresh = self.pending_tout.is_none();
            let mut tout = self.pending_tout.unwrap_or(if no_grid || self.row == n_steps {
                stop
            } else {
                grid(self.row)
            });
            logging_window(e, self.t, tout);
            // Zero-length final interval (stop == start): daskr rejects TOUT == T,
            // so emit the held state directly instead of stepping.
            if tout <= self.t {
                for i in 0..n_states {
                    write_f64(e, states_base + (i as u32) * 8, self.y[i])?;
                }
                emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time)?;
                self.retry.close(e)?;
                self.retry.store(e, sim_data, layout)?;
                self.row += 1;
                continue;
            }
            // C's `perform_simulation` `LOG_SOLVER` block around `simulationStep`.
            if fresh && omclog::active(omclog::SOLVER) {
                omclog::info!(
                    omclog::SOLVER,
                    true,
                    "call solver from {} to {} (stepSize: {})",
                    format_g(self.t, 6),
                    format_g(tout, 6),
                    format_g15(tout - self.t),
                );
            }
            let logging = log_dassl();
            if logging {
                log_dassl_step(self.t);
            }
            e.set_rhs_final(false); // C's `dassl_step`: clear for DASKR's own evaluations
            unsafe {
                solver::ddaskr(
                    dassl_res, neq, &mut self.t, self.y.as_mut_ptr(), self.yp.as_mut_ptr(),
                    &mut tout, self.info.as_mut_ptr(), self.rtol.as_mut_ptr(), self.atol.as_mut_ptr(),
                    &mut self.idid, self.rwork.as_mut_ptr(), lrw as i32, self.iwork.as_mut_ptr(), liw as i32,
                    self.rpar.as_mut_ptr(), self.ipar.as_mut_ptr(), jacfn, solver::dummy_jack,
                    solver::dummy_psol, solver::dummy_rt, nrt, self.jroot.as_mut_ptr(),
                );
            }
            e.set_rhs_final(true); // ... and set for the output evaluation
            // C's `dassl_step` logs the statistics once its `while (idid == 1)` loop is done.
            if logging && self.idid != -1 && self.idid != 1 {
                log_dassl_stats(self.idid, self.t, &self.rwork, &self.iwork);
            }
            if self.idid >= 0 && self.idid != 1 {
                log_solver_finished(self.t);
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
                self.retry.close(e)?;
                continue;
            }
            if self.idid < 0 {
                // See `SolverCore::solve`: the tail evaluates where DASKR stopped.
                for i in 0..n_states {
                    write_f64(e, states_base + (i as u32) * 8, self.y[i])?;
                }
                let err = report_dassl_failure(self.idid, self.t);
                log_solver_finished(self.t);
                return Err(err);
            }
            // IDID=1: one internal step with TOUT still ahead. C's `dassl_step` loops
            // on that until the interval is covered, and breaks out per step only for
            // `-noEquidistantTimeGrid`, where a step is an output point of its own.
            if self.idid == 1 {
                self.pending_tout = Some(tout);
                self.work_retries = 0;
                if !no_equidistant_grid() {
                    self.retry.close(e)?;
                    continue;
                }
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
                self.retry.close(e)?;
                self.retry.store(e, sim_data, layout)?;
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
            self.retry.close(e)?;
            self.retry.store(e, sim_data, layout)?;
            if terminated(e, sim_data, layout)? {
                break Advance::Terminated; // terminate() fired: keep this row, stop
            }
            // Re-read y/yp and restart DASKR (INFO(1)=0). No `functionODE` in
            // between: C's `dassl_step` takes YPRIME from the ring buffer, so it
            // restarts on the derivatives of the *previous* selection.
            if self.dss.reselect(e, sim_data, model)? {
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

    fn retry_step(&mut self, e: &mut (dyn SimEngine + 'static), model: &SimModel) -> Result<bool> {
        let layout = &model.layout;
        let Some(t) = self.retry.undo(e, self.sim_data, layout)? else {
            return Ok(false);
        };
        self.rows.truncate(self.retry.rows_mark);
        // C halves `currentStepSize` without advancing `__currStepNo`: the same output
        // step is retaken over half the interval and the next one catches up.
        let n_steps = model.n_output_rows() - 1;
        let target = self.pending_tout.unwrap_or(if self.row >= n_steps {
            model.stop_time
        } else {
            grid_time(self.row, model.start_time, model.stop_time, n_steps)
        });
        self.t = t;
        self.pending_tout = Some(t + (target - t) / 2.0);
        self.work_retries = 0;
        // C's `dassl_step` takes both from what `restoreOldValues` just put back.
        for i in 0..self.n_states {
            self.y[i] = read_f64(e, self.states_base + (i as u32) * 8)?;
            self.yp[i] = read_f64(e, self.ders_base + (i as u32) * 8)?;
        }
        self.restart(); // C's `didEventStep`: DASKR restarts on the retried step
        Ok(true)
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
    /// `-s=symSolver` / `-s=symSolverSsc`: the model's own symbolic update
    /// equations, events located the same way.
    Sym(openmodelica_solvers::symsolver::SymSolver),
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
    /// The "A" Jacobian's sparsity, coloring and symbolic columns; `None` ⇒ daskr's
    /// own numerical Jacobian.
    jac_a: Option<JacAInfo>,
    /// C's `dasslData->dasslJacobian`.
    jac_method: JacobianMethod,
}

/// What one call into the integrator did.
enum Progress {
    Reached,
    /// One internal step taken, the target not yet reached. DASKR returns that for
    /// every step (INFO(3)=1); `-noEquidistantTimeGrid` makes it an output point.
    Stepped,
    Root,
    /// The per-call work quota ran out before the target; call again to continue.
    WorkQuota,
    /// The root function raised a model error; see [`Solved::RootThrew`].
    RootThrew,
    Failed(&'static str),
}

impl DaskrState {
    fn new(model: &SimModel, n_states: usize, nrt: i32, rtol: Vec<f64>, atol: Vec<f64>) -> Self {
        let neq = n_states as i32;
        let lrw = (60 + 9 * neq + neq * neq + 3 * nrt + 64) as usize;
        let liw = (40 + neq + 64) as usize;
        let jac_a = if env_var("OMC_WASM_NO_ANALYTIC_JAC").is_some() { None } else { model.jac_a.clone() };
        let jac_method = set_jacobian_method(jac_a.as_ref(), false);
        let mut info = [0i32; 24];
        if jac_method != JacobianMethod::InternalNumJac {
            info[4] = 1; // INFO(5)=1: a dense user Jacobian routine
        }
        if n_states > 0 {
            info[1] = 1; // INFO(2)=1: per-state (vector) rtol/atol
        }
        // C's `dassl_initial`: INFO(3)=1 unconditionally, see `DasslDriver::new`.
        if n_states > 0 {
            info[2] = 1;
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
            jac_method,
        }
    }

    fn step(&mut self, t: &mut f64, y: &mut [f64], yp: &mut [f64], target: f64) -> Progress {
        use daskr::solver;
        let neq = y.len() as i32;
        let (lrw, liw) = (self.rwork.len(), self.iwork.len());
        let rt_fn: solver::RtFn = if self.nrt > 0 { dassl_rt } else { solver::dummy_rt };
        let jacfn: solver::JacFn = match self.jac_method {
            JacobianMethod::InternalNumJac => solver::dummy_jacd,
            _ => dassl_jac,
        };
        let mut tt = target;
        let logging = log_dassl();
        if logging {
            log_dassl_step(*t);
        }
        rtclock::tick(rtclock::SOLVER);
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
        rtclock::accumulate(rtclock::SOLVER);
        if logging && self.idid != -1 {
            log_dassl_stats(self.idid, *t, &self.rwork, &self.iwork);
        }
        // IDID=-1: the work quota expended before TOUT — resume with INFO(1)=1, as
        // C does. INFO(3)=1 ends a call after one step, so the quota is out of reach.
        if self.idid == -1 && self.ev_retries < 10_000 {
            self.info[0] = 1;
            self.ev_retries += 1;
            return Progress::WorkQuota;
        }
        self.ev_retries = 0; // this target's integration is done (or failing)
        if self.idid == solver::IDID_RT_ABORT {
            return Progress::RootThrew;
        }
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
    /// `cvodeGetConfig`'s two picks, resolved when the run's flags were parsed.
    config: CvodeConfig,
    work_retries: u32,
    /// Whether building the block still logs the banner; an FMU already did, at
    /// `fmi2Instantiate`.
    banner: bool,
}

#[cfg(sundials)]
type CvodeConfig = (CvodeLmm, CvodeIter);

/// `cvode_solver_initial`'s `LOG_SOLVER` banner.
#[cfg(sundials)]
fn log_cvode_configuration(rtol: f64, root_finding: bool, config: CvodeConfig) {
    // C's compatibility warning, before the banner it belongs to.
    let (lmm, iter) = config;
    if (lmm == CvodeLmm::Adams) != (iter == CvodeIter::FixedPoint) {
        omclog::warning!(
            omclog::SOLVER,
            true,
            "Combination of {} and {} not recommended.",
            lmm.name(),
            iter.name(),
        );
        for line in [
            "Use simflags -cvodeLinearMultistepMethod and -cvodeNonlinearSolverIteration to set.",
            "Use (CV_BDF, CV_ITER_NEWTON) for stiff problems (Default) or",
            "Use (CV_ADAMS, CV_ITER_FIXED_POINT) for nonstiff problems.",
        ] {
            omclog::warning(omclog::SOLVER, false, line);
        }
        omclog::close(omclog::SOLVER);
    }
    for line in [
        format!("CVODE linear multistep method {}", lmm.name()),
        format!("CVODE maximum integration order {}", iter.name()),
        "CVODE use equidistant time grid YES".to_string(),
    ] {
        omclog::info(omclog::SOLVER, false, &line);
    }
    omclog::info!(omclog::SOLVER, false, "CVODE Using relative error tolerance {}", format_e(rtol));
    omclog::info(omclog::SOLVER, false, "CVODE Using dense internal linear solver SUNLinSol_Dense.");
    omclog::info(omclog::SOLVER, false, "CVODE Use internal dense numeric jacobian method.");
    omclog::info!(
        omclog::SOLVER,
        false,
        "CVODE uses internal root finding method {}",
        if root_finding { "YES" } else { "NO" },
    );
    for line in [
        "CVODE maximum absolut step size 0".to_string(),
        "CVODE initial step size is set automatically".to_string(),
        format!("CVODE maximum integration order {}", lmm.max_order()),
        "CVODE maximum number of nonlinear convergence failures permitted during one step 10"
            .to_string(),
        "CVODE BDF stability limit detection algorithm OFF".to_string(),
    ] {
        omclog::info(omclog::SOLVER, false, &line);
    }
}

#[cfg(sundials)]
impl CvodeState {
    /// The CVODE block is built on the first step, when `y` first holds the state
    /// to start from. `ctx` is the callbacks' `user_data`; it lives on the stack of
    /// one `advance`, so it is rebound on every call rather than stored.
    fn step(&mut self, t: &mut f64, y: &mut [f64], target: f64, ctx: *mut ResCtx) -> Result<Progress> {
        let cv = match self.cv.as_mut() {
            Some(cv) => cv,
            None => {
                let root = (self.n_roots > 0).then_some(cvode_root as crate::sundials::RootFn);
                let cv = crate::sundials::Cvode::new(
                    *t, y, self.rtol, &self.atol, self.n_roots, cvode_rhs, root, self.config,
                )
                .ok_or("CodegenWasmJit: CVODE initialization failed")?;
                if self.banner {
                    log_cvode_configuration(self.rtol, self.n_roots > 0, self.config);
                }
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
            crate::sundials::Stop::Failed(crate::sundials::CV_RTFUNC_FAIL) => Progress::RootThrew,
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
    /// C's `restartAfterLSFail`: the one `IDAReInit` retry a failed step gets.
    restarted: bool,
    setup: IdaSetup,
    stop_time: f64,
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
            dae_calc_ic(ida, t, self.rtol)?;
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
        self.setup.finish_ramp(e, sim_data, ida, *t)?;
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
            // C's `ida_solver_step`: one `IDAReInit` retry for a failed setup, or for
            // the degenerate DAE start point the ramp recovers from.
            crate::sundials::Stop::Failed(flag)
                if !self.restarted
                    && (flag == crate::sundials::IDA_LSETUP_FAIL
                        || self.setup.ramp_recovers(flag, *t)) =>
            {
                if self.setup.ramp_recovers(flag, *t) {
                    self.setup.arm_ramp(ida, self.stop_time);
                    omclog::warning!(
                        omclog::SOLVER,
                        false,
                        "##IDA## degenerate DAE operating point at t = {} (flag {flag}); \
                         activating homotopy ramp",
                        format_g(*t, 15),
                    );
                }
                ida.reinit(*t);
                self.restarted = true;
                omclog::warning!(
                    omclog::SOLVER,
                    false,
                    "##IDA## solver failed, try once again at time = {}",
                    format_g(*t, 15),
                );
                Progress::WorkQuota
            }
            crate::sundials::Stop::Failed(crate::sundials::IDA_RTFUNC_FAIL) => Progress::RootThrew,
            crate::sundials::Stop::Failed(flag) => {
                // C's last word before it gives up (`ida_solver.c`).
                omclog::info!(
                    omclog::STDOUT,
                    false,
                    "##IDA## {flag} error occurred at time = {}",
                    format_g(*t, 15),
                );
                Progress::Failed("CodegenWasmJit: IDA failed")
            }
            other => {
                self.work_retries = 0;
                self.restarted = false;
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
    /// Steps of the no-unknowns walk, which never enters the integrator; C counts
    /// its `euler_ex_step` calls there all the same.
    walk_steps: u64,
    nominals: Vec<f64>,
    /// State `max` attributes, for gbode's finite-difference step sign.
    maxs: Vec<f64>,
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
/// The model in wasm linear memory as an [`openmodelica_solvers::Ode`]: the
/// solvers set the time and the states, call `functionODE`, and read the
/// derivatives back out of `SimData`.
pub struct EngineOde<'a> {
    pub e: &'a mut (dyn SimEngine + 'static),
    pub sim_data: u32,
    pub states_base: u32,
    pub ders_base: u32,
    pub nls_fail_off: u32,
    /// `--symSolver`'s `inlineData` slots (see [`openmodelica_solvers::symsolver`]).
    pub inline_dt_off: u32,
    pub alg_old_off: u32,
    pub ctx_addr: u32,
    /// Sparsity + coloring for the finite-difference Jacobian; `None` ⇒ dense
    /// column-by-column differencing.
    pub jac_a: Option<&'a JacAInfo>,
    pub nominals: &'a [f64],
    pub maxs: &'a [f64],
    pub nominal_factor: f64,
    /// Base of the zero-crossing value region.
    pub zc_off: u32,
    /// `functionODE` calls made through this handle, for the solver statistics.
    pub calls: u64,
}

impl openmodelica_solvers::Ode for EngineOde<'_> {
    fn eval(&mut self, t: f64, y: &[f64], f: &mut [f64]) -> Result<()> {
        write_time(self.e, self.sim_data, t)?;
        let mut bytes = vec![0u8; y.len() * 8];
        for (i, v) in y.iter().enumerate() {
            bytes[i * 8..i * 8 + 8].copy_from_slice(&v.to_le_bytes());
        }
        self.e.write_bytes(self.states_base, &bytes)?;
        self.e.call1("functionODE", self.sim_data)?;
        self.calls += 1;
        self.e.read_bytes(self.ders_base, &mut bytes)?;
        for (i, v) in f.iter_mut().enumerate() {
            *v = f64::from_le_bytes(bytes[i * 8..i * 8 + 8].try_into().unwrap());
        }
        Ok(())
    }

    /// Like the driver's DASKR root callback: the continuous equations first, so
    /// any algebraic a crossing depends on is current. A nonlinear system that
    /// fails at this probe must not leak into the next checked evaluation, so the
    /// flag is cleared around it.
    fn eval_zc(&mut self, t: f64, y: &[f64], zc: &mut [f64]) -> Result<()> {
        if zc.is_empty() {
            return Ok(());
        }
        write_i32(self.e, self.sim_data + self.nls_fail_off, 0)?;
        let mut f = vec![0.0; y.len()];
        set_context_events(self.e, self.ctx_addr);
        let run = (|| -> Result<()> {
            openmodelica_solvers::Ode::eval(self, t, y, &mut f)?;
            self.e.call2(MODEL_FN_ZC, self.sim_data, self.sim_data + self.zc_off)?;
            let mut bytes = vec![0u8; zc.len() * 8];
            self.e.read_bytes(self.sim_data + self.zc_off, &mut bytes)?;
            for (i, v) in zc.iter_mut().enumerate() {
                *v = f64::from_le_bytes(bytes[i * 8..i * 8 + 8].try_into().unwrap());
            }
            Ok(())
        })();
        set_context_algebraic(self.e, self.ctx_addr);
        run
    }

    fn nominals(&self) -> &[f64] {
        self.nominals
    }

    fn nominal_factor(&self) -> f64 {
        self.nominal_factor
    }

    fn maxs(&self) -> &[f64] {
        self.maxs
    }

    fn jac_colors(&self) -> &[Vec<u32>] {
        self.jac_a.map_or(&[], |j| &j.colors)
    }

    fn jac_rows_by_col(&self) -> &[Vec<u32>] {
        self.jac_a.map_or(&[], |j| &j.rows_by_col)
    }

    fn set_context_jacobian(&mut self) {
        set_context_jacobian(self.e, self.ctx_addr);
    }

    fn set_context_algebraic(&mut self) {
        set_context_algebraic(self.e, self.ctx_addr);
    }

    fn has_jacobian_vector(&self) -> bool {
        self.jac_a.is_some_and(|j| j.sym.is_some())
    }

    /// `out = ∂f/∂y · seed` through the model's symbolic Jacobian column
    /// equations (`functionJacA_column`), which are linear in the seed.
    fn jacobian_vector(&mut self, t: f64, y: &[f64], seed: &[f64], out: &mut [f64]) -> bool {
        let Some(jac) = self.jac_a else { return false };
        let Some(sym) = jac.sym.as_ref() else { return false };
        let n = jac.n as usize;
        if sym.seed_offs.len() != n || sym.result_offs.len() != n {
            return false;
        }
        let run = (|| -> Result<()> {
            write_time(self.e, self.sim_data, t)?;
            let mut bytes = vec![0u8; y.len() * 8];
            for (i, v) in y.iter().enumerate() {
                bytes[i * 8..i * 8 + 8].copy_from_slice(&v.to_le_bytes());
            }
            self.e.write_bytes(self.states_base, &bytes)?;
            set_context(self.e, self.ctx_addr, CONTEXT_SYM_JACOBIAN);
            for (c, &off) in sym.seed_offs.iter().enumerate() {
                write_f64(self.e, self.sim_data + off, seed[c])?;
            }
            if sym.has_constant {
                self.e.call1("functionJacA_constantEqns", self.sim_data)?;
            }
            self.e.call1("functionJacA_column", self.sim_data)?;
            for (r, &off) in sym.result_offs.iter().enumerate() {
                out[r] = match off {
                    u32::MAX => 0.0,
                    off => read_f64(self.e, self.sim_data + off)?,
                };
            }
            for &off in &sym.seed_offs {
                write_f64(self.e, self.sim_data + off, 0.0)?;
            }
            Ok(())
        })();
        set_context(self.e, self.ctx_addr, CONTEXT_ALGEBRAIC);
        run.is_ok()
    }

    fn calls(&self) -> u64 {
        self.calls
    }
}

/// `--symSolver`'s generated update equations over the same handle: they read the
/// model clock, `inlineData->dt` and `inlineData->algOldVars` and write the states.
impl openmodelica_solvers::symsolver::InlineOde for EngineOde<'_> {
    fn set_alg_old(&mut self, y: &[f64]) -> Result<()> {
        write_f64s(self.e, self.sim_data + self.alg_old_off, y)
    }

    fn get_states(&mut self, y: &mut [f64]) -> Result<()> {
        read_f64s(self.e, self.states_base, y)
    }

    fn set_states(&mut self, y: &[f64]) -> Result<()> {
        write_f64s(self.e, self.states_base, y)
    }

    fn inline_eval(&mut self, t: f64, dt: f64) -> Result<()> {
        // `write_time` is also C's `externalInputUpdate` + `input_function`.
        write_time(self.e, self.sim_data, t)?;
        write_f64(self.e, self.sim_data + self.inline_dt_off, dt)?;
        self.e.call1("symbolicInlineSystem", self.sim_data)
    }
}

fn model_ode<'a>(
    e: &'a mut (dyn SimEngine + 'static),
    ctx: &'a ResCtx,
    states_base: u32,
    ders_base: u32,
    nominals: &'a [f64],
    maxs: &'a [f64],
) -> EngineOde<'a> {
    EngineOde {
        e,
        sim_data: ctx.sim_data,
        states_base,
        ders_base,
        nls_fail_off: ctx.nls_fail_off,
        inline_dt_off: ctx.inline_dt_off,
        alg_old_off: ctx.alg_old_off,
        ctx_addr: ctx.ctx_addr,
        jac_a: unsafe { ctx.jac.as_ref() },
        nominals,
        maxs,
        nominal_factor: ctx.nominal_factor,
        zc_off: ctx.zc_off,
        calls: 0,
    }
}

/// Whether `method` asks for the model's symbolic update equations, and which
/// `--symSolver` variant they were generated as. `None` for every other method,
/// and for a model that carries no inline system.
fn sym_kind(method: &str, layout: &SimLayout) -> Option<openmodelica_solvers::symsolver::SymKind> {
    if !matches!(method, "symSolver" | "symSolverSsc") {
        return None;
    }
    openmodelica_solvers::symsolver::SymKind::from_code(layout.sym_solver)
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

/// C's `SAMPLE_EPS` (`simulation/solver/epsilon.h`).
const SAMPLE_EPS: f64 = 1e-14;


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
    /// The root function raised a model error. C's `dassl_step` catches that
    /// `longjmp` with `retVal` still 0, so `simulationUpdate` evaluates the probe
    /// point `SimData` was left at, and only its throw reaches the step's retry.
    RootThrew(&'static str),
    Yielded,
    Cancelled,
}

/// How far [`SolverCore::integrate_to`] got.
enum Step {
    /// `tout` reached; `grid_covered` when an event landed on it, so its rows are
    /// already emitted; `event_step` is C's `didEventStep`.
    Reached { grid_covered: bool, event_step: bool },
    Terminated,
    /// Located an event at `time`, discrete update left undone for the caller to
    /// report (CS Event Mode). Only returned when [`CsDefer`] asks for it.
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
    /// C's `currentTime` at the end of an output row: the grid point, or the event
    /// that covered it.
    reached: f64,
    dss: StateSelection,
    samp: Samples,
    sync: crate::sync::Sync,
    rows: Vec<f64>,
    /// Resume state for a yield mid output row, so `grid_covered` is not reset.
    mid_row: bool,
    grid_covered: bool,
    /// C's `didEventStep`.
    did_event_step: bool,
    /// C's degenerate first iteration under `-noEquidistantTimeGrid` is emitted.
    no_grid_primed: bool,
    pending_terminate: bool,
    finished: bool,
    /// Where a retried step ends, short of this row's grid point.
    pending_tout: Option<f64>,
    retry: StepRetry,
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
        let maxs = read_state_maxs(e, sim_data, layout)?;
        let (rtol, atol) = dassl_tolerances(tol, &nominals);
        let _ = method;
        #[cfg(sundials)]
        let solver = match method {
            "cvode" => {
                Solver::Cvode(CvodeState {
                    cv: None,
                    rtol: tol,
                    atol,
                    n_roots: nrt as usize,
                    config: crate::simflags::with_flags(|f| crate::simflags::cvode_config(&f)),
                    work_retries: 0,
                    banner: true,
                })
            }
            "ida" => Solver::Ida(IdaState {
                ida: None,
                rtol: tol,
                atol,
                n_roots: nrt as usize,
                work_retries: 0,
                restarted: false,
                setup: IdaSetup::new(model)?,
                stop_time: model.stop_time,
            }),
            _ => Solver::Daskr(DaskrState::new(model, n_states, nrt, rtol, atol)),
        };
        #[cfg(not(sundials))]
        let solver = Solver::Daskr(DaskrState::new(model, n_states, nrt, rtol, atol));
        let solver = if let Some(kind) = fixed_kind(method) {
            Solver::Fixed(crate::fixedstep::FixedStep::new(kind, n_states, layout.n_zc as usize))
        } else if let Some(kind) = sym_kind(method, layout) {
            Solver::Sym(openmodelica_solvers::symsolver::SymSolver::new(
                kind,
                method == "symSolverSsc",
                n_states,
                layout.n_zc as usize,
                tol,
            ))
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
            walk_steps: 0,
            nominals,
            maxs,
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

    /// C's `ida_event_update`, which DAE mode installs as `functionDAE`: residuals in
    /// the discrete context, re-initialize at what they leave behind, `IDACalcIC` for
    /// the algebraic unknowns and derivatives, answer back into `SimData`. `ctx` must
    /// be the live callback context — `IDACalcIC` evaluates the residual.
    fn dae_restart(&mut self, e: &mut dyn SimEngine, ctx: *mut ResCtx) -> Result<()> {
        let _ = ctx; // DAE mode needs SUNDIALS, so without it there is nothing to do
        e.call2(MODEL_FN_DAE, self.sim_data, eval_stage::DISCRETE)?;
        self.read_states(e)?;
        self.restart()?;
        #[cfg(sundials)]
        if let Solver::Ida(s) = &mut self.solver
            && let Some(ida) = s.ida.as_mut()
        {
            if !ida.set_user_data(ctx as *mut core::ffi::c_void) {
                return Err("CodegenWasmJit: IDA setup failed");
            }
            dae_calc_ic(ida, self.t, self.tol)?;
            self.y.copy_from_slice(ida.y());
            self.yp.copy_from_slice(ida.yp());
        }
        e.call2(MODEL_FN_DAE, self.sim_data, eval_stage::DISCRETE)?;
        self.write_states(e)
    }

    /// C's `didEventStep`: drop the step history at the post-event state. In DAE
    /// mode that is C's `IDAReInit` alone -- the `IDACalcIC` belongs to the event
    /// iteration, which ran [`Self::dae_restart`] at the end of every pass.
    fn event_restart(&mut self, e: &mut (dyn SimEngine + 'static), ctx: *mut ResCtx) -> Result<()> {
        let _ = (e, ctx);
        self.restart()
    }

    /// C's `handleEvents`: the event iteration with `functionDAE` as DAE mode
    /// installs it.
    fn event_update_here(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        sim_data: u32,
        layout: &SimLayout,
        ctx: *mut ResCtx,
        time: f64,
    ) -> Result<EventUpdate> {
        if !self.dae {
            return event_update(e, sim_data, layout, None, time);
        }
        let mut dae = |e: &mut dyn SimEngine| self.dae_restart(e, ctx);
        event_update_dae(e, sim_data, layout, None, time, Some(&mut dae))
    }

    /// The same for a time event, which C also ends in `updateDiscreteSystem`.
    fn fire_time_event_here(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        samples: &mut Samples,
        sim_data: u32,
        layout: &SimLayout,
        ctx: *mut ResCtx,
        te: f64,
    ) -> Result<()> {
        if !self.dae {
            return fire_time_event(e, samples, sim_data, layout, te, None);
        }
        let mut dae = |e: &mut dyn SimEngine| self.dae_restart(e, ctx);
        fire_time_event(e, samples, sim_data, layout, te, Some(&mut dae))
    }

    /// C's `ida_event_update` as the initial `updateDiscreteSystem` calls it: the IDA
    /// block on first use, then the ordinary restart. Interleaving it with the event
    /// iteration is what makes it work — a pass that flips a relation is what hands
    /// the next `IDACalcIC` a system to solve.
    fn dae_event_update(&mut self, e: &mut dyn SimEngine, ctx: *mut ResCtx) -> Result<()> {
        if !self.dae {
            return Ok(());
        }
        #[cfg(sundials)]
        {
            let (t, sim_data) = (self.t, self.sim_data);
            self.read_states(e)?;
            if let Solver::Ida(state) = &mut self.solver {
                state.ensure(e, sim_data, t, &mut self.y, &mut self.yp, ctx)?;
            }
        }
        self.dae_restart(e, ctx)
    }

    /// C's `updateSolverNominals`, for the DAE-mode core built before
    /// `initializeModel`: the nominals it took its tolerances from are only final now.
    fn refresh_nominals(&mut self, e: &dyn SimEngine, layout: &SimLayout) -> Result<()> {
        self.nominals = read_state_nominals(e, self.sim_data, layout)?;
        self.maxs = read_state_maxs(e, self.sim_data, layout)?;
        let (_, atol) = dassl_tolerances(self.tol, &self.nominals);
        #[cfg(sundials)]
        {
            let t = self.t;
            if let Solver::Ida(s) = &mut self.solver {
                if let Some(ida) = s.ida.as_mut()
                    && !ida.set_tolerances(t, s.rtol, &atol)
                {
                    return Err("CodegenWasmJit: IDA tolerances failed");
                }
                s.atol = atol;
            }
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
        omclog::info!(
            omclog::STDOUT,
            false,
            "Chattering detected around time {t0}..{t1} ({CHATTER_LIMIT} state events in a row \
             with a total time delta less than the step size {step_size}). This can be a \
             performance bottleneck. Use -lv LOG_EVENTS for more information. The \
             zero-crossing was: {desc}",
        );
        if chatter_store::abort() {
            omclog::debug(
                omclog::ASSERT,
                false,
                "Aborting simulation due to chattering being detected and the simulation flags \
                 requesting we do not continue further.",
            );
            return Err(CHATTER_ABORT_ERR);
        }
        Ok(())
    }

    /// C's `cvode_solver_initial` under `isFMI`, whose banner
    /// [`log_cs_solver_setup`] has already logged.
    fn fmi_cs_solver_setup(&mut self, defer: CsDefer) {
        #[cfg(sundials)]
        if let Solver::Cvode(c) = &mut self.solver {
            c.banner = false;
            if defer != CsDefer::Any {
                c.n_roots = 0;
            }
        }
        #[cfg(not(sundials))]
        let _ = defer;
    }

    /// Restart the integrator at the current `(t, y)`, banking the run totals its
    /// own counters are about to lose. Every event restarts, so without this the
    /// step count is only the last segment's.
    fn restart(&mut self) -> Result<()> {
        match &mut self.solver {
            Solver::Daskr(d) => {
                // C's `dasslAvoidEventRestart`: `-noRestart` keeps the BDF history.
                if !crate::simflags::with_flags(|f| f.no_restart) {
                    d.past.fold(&d.iwork);
                    d.info[0] = 0; // INFO(1)=0
                }
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
            // C's `didEventStep`: `first_step` re-seeds the inner integrator.
            Solver::Sym(s) => s.restart(),
        }
        Ok(())
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
    /// follow the states in `y` (C's `getAlgebraicDAEVars`); only the states' `y'`
    /// moves, as C's `statesDer` keeps what the last `IDAGetConsistentIC` left there.
    fn read_states(&mut self, e: &mut dyn SimEngine) -> Result<()> {
        self.read_y(e)?;
        self.yp.resize(self.n_unknowns, 0.0);
        for i in 0..self.n_states {
            self.yp[i] = read_f64(e, self.ders_base + (i as u32) * 8)?;
        }
        Ok(())
    }

    /// The `y` half of [`read_states`](SolverCore::read_states), for the callers
    /// that must not disturb the integrator's own `y'`.
    fn read_y(&mut self, e: &mut dyn SimEngine) -> Result<()> {
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
    fn write_states(&self, e: &mut dyn SimEngine) -> Result<()> {
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
            inline_dt_off: layout.inline_dt_off,
            alg_old_off: layout.alg_old_off,
            nfe: self.nfe,
            zc_probe_off: layout.zc_probe_off,
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
                Solver::Fixed(_) | Solver::Sym(_) => core::ptr::null(),
            },
            jac_method: match &self.solver {
                Solver::Daskr(d) => d.jac_method,
                #[cfg(sundials)]
                Solver::Ida(s) => s.setup.jac_method,
                // None of these reach `dassl_jac`/`ida_jac`.
                #[cfg(sundials)]
                Solver::Cvode(_) => JacobianMethod::InternalNumJac,
                Solver::Gbode(_) | Solver::Fixed(_) | Solver::Sym(_) => JacobianMethod::InternalNumJac,
            },
            jac_gp: vec![0.0; self.n_unknowns],
            jac_ysave: vec![0.0; self.n_unknowns],
            jac_del: vec![0.0; self.n_unknowns],
            jac_ders: Vec::new(),
            jac_ypsave: vec![0.0; self.n_unknowns],
            nje: self.nje,
            ctx_addr: e.context_addr(),
            err_stage_addr: e.error_stage_addr(),
            nominals: self.nominals.as_ptr(),
            nominal_factor: nominal_factor(),
            tol: self.tol,
            state_names: core::ptr::null(),
            #[cfg(sundials)]
            ida: self.ida_ctx(),
        }
    }

    /// Integrate from `t` toward `target` with whichever integrator this core has,
    /// leaving `t`/`y` where it stopped. Both may stop early at a zero-crossing
    /// root, and both may return short of `target` — one internal step done, or a
    /// per-call work quota spent — which is continued here, so the caller sees only
    /// the four outcomes.
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
            let outside_window = suspend_assert_window();
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
                    let mut ode = model_ode(e, ctx, self.states_base, self.ders_base, &self.nominals, &self.maxs);
                    match f.step(&mut ode, &mut self.t, &mut self.y, &mut self.yp, target)? {
                        openmodelica_solvers::events::StepEnd::Reached => Progress::Reached,
                        openmodelica_solvers::events::StepEnd::Root(_) => Progress::Root,
                    }
                }
                Solver::Sym(s) => {
                    let e = unsafe { &mut *ctx.engine };
                    let mut ode = model_ode(e, ctx, self.states_base, self.ders_base, &self.nominals, &self.maxs);
                    match s.step(&mut ode, &mut self.t, &mut self.y, &mut self.yp, target)? {
                        openmodelica_solvers::events::StepEnd::Reached => Progress::Reached,
                        openmodelica_solvers::events::StepEnd::Root(_) => Progress::Root,
                    }
                }
                Solver::Gbode(g) => {
                    let e = unsafe { &mut *ctx.engine };
                    let mut ode = model_ode(e, ctx, self.states_base, self.ders_base, &self.nominals, &self.maxs);
                    let limit = self.sample_limit;
                    match g.step(&mut ode, target, limit, &mut self.t, &mut self.y)? {
                        crate::gbode::GbStep::Reached => Progress::Reached,
                        crate::gbode::GbStep::Stepped => Progress::Stepped,
                        crate::gbode::GbStep::Root(_) => Progress::Root,
                    }
                }
            };
            drop(outside_window);
            self.nfe = ctx.nfe;
            self.nje = ctx.nje;
            *did_step = true;
            // A wasm error in a callback outranks whatever the solver reported.
            let err = ctx.err.take();
            if let Progress::RootThrew = again {
                return Ok(Solved::RootThrew(err.unwrap_or(ASSERT_ERR)));
            }
            if let Some(err) = err {
                return Err(err);
            }
            match again {
                Progress::WorkQuota => continue,
                Progress::RootThrew => unreachable!(),
                // An internal step below the target: only `-noEquidistantTimeGrid`
                // makes it an output point, so otherwise integrate on, as C's
                // `dassl_step` loop does while IDID == 1.
                Progress::Stepped if !no_equidistant_grid() => continue,
                // C integrates the model's own state array, so the point the solver
                // gave up at is what `drive`'s tail evaluates.
                Progress::Failed(err) => {
                    let e = unsafe { &mut *ctx.engine };
                    self.write_states(e)?;
                    return Err(err);
                }
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
            Solver::Sym(s) => {
                stats.steps = s.steps;
                // The inline evaluations, which is what C counts as `nCallsODE`.
                stats.res_evals = s.calls_ode;
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
        if self.n_unknowns == 0 {
            stats.steps = self.walk_steps;
            stats.res_evals = self.walk_steps;
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
            Solver::Fixed(_) | Solver::Sym(_) => false,
        }
    }

    /// C's `solverInfo->solverRootFinding`: the solver rooted for itself, so
    /// `simulationUpdate` still evaluates at the root. For the two that bisect here,
    /// `findRoot` has already pulled that evaluation back to the bracket's left end.
    fn solver_root_finding(&self) -> bool {
        !matches!(self.solver, Solver::Fixed(_) | Solver::Sym(_))
    }

    /// C's `time_left`/`states_left`, or `None` for a solver that roots without
    /// bisecting.
    fn event_left(&self) -> Option<(f64, Vec<f64>)> {
        let (t, y) = match &self.solver {
            Solver::Daskr(_) => return None,
            #[cfg(sundials)]
            Solver::Cvode(_) => return None,
            #[cfg(sundials)]
            Solver::Ida(_) => return None,
            Solver::Gbode(g) => g.event_left(),
            Solver::Fixed(f) => f.event_left(),
            Solver::Sym(s) => s.event_left(),
        };
        Some((t, y.to_vec()))
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
            Solver::Sym(s) => vec![s.root_index()],
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
        self.state_events += 1;
        log_state_event(t, flips, model);
        if let Some(r) = rows.as_deref_mut()
            && !no_event_emit()
        {
            capture_pre(e, r, sim_data, layout, t)?;
        }
        self.event_update_here(e, sim_data, layout, ctx as *mut ResCtx, t)?;
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
        fire_clocks(e, sync, model, sim_data, t, SYNC_EPS, rows.as_deref_mut())?;
        store_operators(e, sim_data, layout)?;
        omclog::close(omclog::EVENTS);
        if terminated(e, sim_data, layout)? {
            return Ok(true);
        }
        // No `functionODE`: `event_update` left the derivative slots consistent, and
        // C restarts DASKR on the `YPRIME` in its ring buffer.
        self.read_states(e)?;
        self.event_restart(e, ctx)?;
        Ok(false)
    }

    /// Integrate to `tout`, handling the state events the solver roots out and the
    /// samples due on the way. `rows` collects the pre/post-event rows when the
    /// caller wants them; CS passes `None`. A `Yielded` return resumes on the same
    /// `tout` (the integrator continues where it left off), so yields are safe points.
    /// `defer` (CS Event Mode) stops at an event the master owns and returns
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
        defer: CsDefer,
    ) -> Result<Step> {
        let layout = &model.layout;
        let sim_data = self.sim_data;
        let n_states = self.n_states;
        let span = model.stop_time - model.start_time;
        let eps = reached_eps(tout, span);
        let step_eps = small_step_eps(span);
        let mut grid_covered = false;
        let mut event_step = false;
        let defers = |t: f64| match defer {
            CsDefer::None => false,
            CsDefer::AtTarget => t >= tout - eps,
            CsDefer::Any => true,
        };

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
            rotate_old_real(e, sim_data, layout)?;
            // Mode 0: hold relations across the DASKR solve so its residual/Jacobian
            // probes are smooth (C's `solveContinuous`); events/outputs refresh them.
            write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
            let te = samp.next_time();
            let tc = sync.next_time();
            // C's `checkForSynchronous` then `checkForSampleEvent`: each shortens the
            // step onto its activation, or pulls one just past the end in.
            let mut target = tout;
            if tc >= self.t && tc <= target + SYNC_EPS {
                target = tc;
            }
            if te >= self.t && te <= target + SAMPLE_EPS {
                target = te;
            }
            self.sample_limit = te.min(tc);
            // Integrate from the current t toward `target` (the caller's time or the
            // next scheduled sample). DASKR may stop early at a zero-crossing root.
            if target - self.t > step_eps {
                // C's `perform_simulation` `LOG_SOLVER` block around `simulationStep`.
                if omclog::active(omclog::SOLVER) {
                    omclog::info!(
                        omclog::SOLVER,
                        true,
                        "call solver from {} to {} (stepSize: {})",
                        format_g(self.t, 6),
                        format_g(target, 6),
                        format_g15(target - self.t),
                    );
                }
                let solved = self.solve_toward(target, ctx, deadline, did_step)?;
                if omclog::active(omclog::SOLVER) {
                    omclog::info!(omclog::SOLVER, false, "finished solver step {}", format_g(self.t, 6));
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
                    Solved::RootThrew(err) => {
                        // C's `updateContinuousSystem` at the probe point; C carries on
                        // if it does not throw, here the root function's throw is the step's.
                        clear_stage_hit(e, ctx.err_stage_addr);
                        let evaluated = eval_continuous(e, sim_data, layout);
                        if err == ASSERT_ERR && !stage_hit(e, ctx.err_stage_addr) {
                            mark_stage_hit(e, ctx.err_stage_addr);
                        }
                        evaluated?;
                        return Err(err);
                    }
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
                        write_time(e, sim_data, self.t)?;
                        eval_continuous(e, sim_data, layout)?;
                    }
                    store_operators(e, sim_data, layout)?;
                    let flips = save_zero_crossings(e, sim_data, layout)?;
                    if !flips.is_empty() {
                        *did_step = true;
                        event_step = true;
                        self.note_chatter(model, flips[0])?;
                        if defers(self.t) {
                            log_state_event(self.t, &flips, model);
                            return Ok(Step::Event { time: self.t });
                        }
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
                    event_step = true;
                    let roots = self.roots_nonzero();
                    log_state_event(troot, &roots, model);
                    if !defers(troot) {
                        self.state_events += 1;
                        self.note_chatter(model, roots.first().copied().unwrap_or(0))?;
                    }
                    let left = self.event_left();
                    if let Some((t_l, y_l)) = &left {
                        eval_event_left(e, sim_data, layout, self.states_base, *t_l, y_l)?;
                        // C restores `time_right`/`states_right`.
                        write_time(e, sim_data, troot)?;
                        self.write_states(e)?;
                    }
                    // gbode re-evaluates at the root before the pre-event row (C's
                    // `simulationUpdate`); a fixed-step method's `findRoot` tail does not.
                    let bisected = left.is_some() && !self.solver_root_finding();
                    if self.solver_root_finding() {
                        store_operators_at(e, sim_data, layout, troot)?;
                    }
                    // pre-event row (before the discrete update), then event +
                    // post-event row.
                    if let Some(r) = rows.as_deref_mut()
                        && !no_event_emit()
                    {
                        if bisected {
                            capture_row(e, r, sim_data, layout)?;
                        } else {
                            capture_pre(e, r, sim_data, layout, troot)?;
                        }
                    }
                    let _ = save_zero_crossings(e, sim_data, layout)?;
                    if defers(troot) {
                        write_time(e, sim_data, troot)?;
                        return Ok(Step::Event { time: troot });
                    }
                    self.event_update_here(e, sim_data, layout, ctx, troot)?;
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
                    fire_clocks(e, sync, model, sim_data, troot, SYNC_EPS, rows.as_deref_mut())?;
                    // C's "add event to spatialDistribution": the post-event input
                    // jump becomes a discontinuity in the transported profile.
                    store_operators(e, sim_data, layout)?;
                    omclog::close(omclog::EVENTS);
                    if terminated(e, sim_data, layout)? {
                        return Ok(Step::Terminated);
                    }
                    // Re-read states (a reinit may have jumped one) and restart DASKR
                    // at troot (INFO(1)=0); see `handle_zc_flips` for the `functionODE`.
                    self.read_states(e)?;
                    self.event_restart(e, ctx)?;
                    if tout - troot < GRID_SKIP_EPS {
                        grid_covered = true;
                    }
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
                write_time(e, sim_data, self.t)?;
                self.refresh_yp(e)?;
                *did_step = true;
            }
            // Reached `target`. Fire a sample event at `te` if it lands at or
            // before `tout` (pre-event row, fire, post-event row).
            if te <= target + SAMPLE_EPS {
                *did_step = true;
                event_step = true;
                log_time_event(e, te, samp, model);
                if let Some(r) = rows.as_deref_mut()
                    && !no_event_emit()
                {
                    emit_row(e, r, sim_data, layout, te, model.stop_time)?; // pre-event row (held)
                }
                store_operators_at(e, sim_data, layout, te)?;
                let _ = save_zero_crossings(e, sim_data, layout)?;
                if defers(te) {
                    self.t = te;
                    write_time(e, sim_data, te)?;
                    return Ok(Step::Event { time: te });
                }
                self.fire_time_event_here(e, samp, sim_data, layout, ctx, te)?;
                e.clean_nls_history(te);
                self.time_events += 1;
                if let Some(r) = rows.as_deref_mut()
                    && emit_post_event_row(model, te)
                {
                    emit_row(e, r, sim_data, layout, te, model.stop_time)?;
                }
                save_zero_crossings_after_event(e, sim_data, layout)?;
                store_operators(e, sim_data, layout)?;
                omclog::close(omclog::EVENTS);
                if terminated(e, sim_data, layout)? {
                    return Ok(Step::Terminated);
                }
                self.read_y(e)?;
                // C sets `didEventStep` for a time event too.
                self.refresh_yp(e)?;
                self.event_restart(e, ctx)?;
                if tout - te < GRID_SKIP_EPS {
                    grid_covered = true;
                }
            }
            // C's `handleTimers`, plus any event clock a `when` body above just fired.
            if !sync.is_empty() {
                write_time(e, sim_data, target)?;
                sync.take_fired(e, target)?;
            }
            if sync.next_time() <= target + SYNC_EPS {
                *did_step = true;
                event_step = true;
                write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
                eval_continuous(e, sim_data, layout)?;
                if fire_clocks(e, sync, model, sim_data, target, SYNC_EPS, rows.as_deref_mut())? {
                    if terminated(e, sim_data, layout)? {
                        return Ok(Step::Terminated);
                    }
                    store_operators(e, sim_data, layout)?;
                    self.read_y(e)?;
                    self.refresh_yp(e)?;
                    self.event_restart(e, ctx)?;
                    if tout - target < GRID_SKIP_EPS {
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
                    // `fmi2DoStep`'s own detection: the only one an FMU without
                    // root finding has, and it lands on the communication point.
                    let flips = save_zero_crossings(e, sim_data, layout)?;
                    if !flips.is_empty() {
                        if defers(self.t) {
                            return Ok(Step::Event { time: self.t });
                        }
                        if self.handle_zc_flips(e, model, ctx, sync, None, &flips)? {
                            return Ok(Step::Terminated);
                        }
                    }
                }
                return Ok(Step::Reached { grid_covered, event_step });
            }
        }
    }
}

/// Co-Simulation: the FMU owns the integration, the importer picks the
/// communication points. Unlike [`EventsDriver`] there is no output grid and no
/// rows. [`step_to`](CsDriver::step_to) takes a [`CsDefer`] saying which events it
/// reports for the master to drive instead of resolving them itself.
///
/// The caller initializes the model (`run_initialization`) before building this,
/// since FMI does that in its own Initialization Mode.
pub struct CsDriver {
    core: SolverCore,
    samp: Samples,
    sync: crate::sync::Sync,
    /// The step `euler`/`rungekutta` take (the model's own output step); `None` for a
    /// variable-step method, which is handed the whole interval.
    fixed_h: Option<f64>,
    /// The event the master's `update-discrete-states` resolved since the last
    /// step; the next step restarts the integrator for it.
    resume: Option<MasterEvent>,
    /// The zero-crossing values at the last accepted point, for the no-states walk.
    zc0: Vec<f64>,
}

/// What the master's Event Mode resolved; the integrator resumes as
/// [`SolverCore::integrate_to`] does after the same event.
#[derive(Clone, Copy)]
enum MasterEvent {
    State,
    Time,
}

/// Which events the FMU reports to the master instead of resolving itself: C's
/// `doStepInternal` gate `eventModeUsed && (earlyReturnAllowed || t >= tEnd)`.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum CsDefer {
    /// `eventModeUsed = false`: the FMU resolves every event. Also the standalone
    /// drivers, which have no master.
    None,
    /// Event Mode without early return: the step must still reach the
    /// communication point, so only an event landing there is reported.
    AtTarget,
    /// Event Mode with `earlyReturnAllowed`: any event is reported where it happens.
    Any,
}

/// What [`CsDriver::step_to`] did.
pub enum CsStep {
    /// Reached the requested time.
    Reached,
    /// Event Mode only: stopped at an event at `time` for the master to handle.
    Event { time: f64 },
    /// `terminate()` fired; `last_time` is where it stopped.
    Terminated,
}

/// C's `FMI2CS_initializeSolverData`: an FMU's solver is set up in
/// `fmi2Instantiate`, and for CVODE `LOG_SOLVER` is forced on across
/// `cvode_solver_initial` so the banner reaches the log either way. `defer` decides
/// the root-finding line — see [`CsDriver::new`].
pub fn log_cs_solver_setup(model: &SimModel, defer: CsDefer) {
    let Ok(method) = resolve_solver_method(model.cs_method(), model.layout.dae_mode()) else { return };
    // "No states present, continuing without ODE solver": C falls back to euler,
    // which has nothing to set up and nothing to say.
    if method != "cvode" || model.layout.n_states == 0 {
        return;
    }
    #[cfg(sundials)]
    {
        let tol = if model.tolerance > 0.0 { model.tolerance } else { 1e-6 };
        let mask = omclog::mask();
        omclog::set_mask(mask | (1 << omclog::SOLVER));
        log_cvode_configuration(
            tol,
            defer == CsDefer::Any,
            crate::simflags::with_flags(|f| crate::simflags::cvode_config(&f)),
        );
        omclog::set_mask(mask);
    }
    #[cfg(not(sundials))]
    let _ = defer;
}

impl CsDriver {
    /// Build over an already-initialized model at time `t`, integrating with the
    /// method the FMU was exported with ([`SimMeta::cs_method`]).
    ///
    /// The driver takes over `sync` so the instance has exactly one clock schedule,
    /// and builds its own only for a caller with none.
    ///
    /// The integrator watches event indicators only under [`CsDefer::Any`], the one
    /// mode whose master can be handed the crossing time (Event Mode with early
    /// return). Otherwise the FMU resolves the event itself, and does it as C's
    /// `fmi2DoStep` does: no root finding (`cvodeGetConfig(…, isFMI)`) and the sign
    /// change picked up at the communication point.
    pub fn new(
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        sim_data: u32,
        t: f64,
        defer: CsDefer,
        sync: Option<crate::sync::Sync>,
    ) -> Result<Self> {
        daskr::auxiliary::xsetf(0);
        let layout = &model.layout;
        let method = resolve_solver_method(model.cs_method(), layout.dae_mode())?;
        // QSS runs a whole simulation of its own; C's `solver_main_step` throws
        // "Unhandled case" for it rather than stepping it.
        if method == "qss" {
            return Err("CodegenWasmJit: method=\"qss\" cannot step to a communication point");
        }
        store_relations(e, sim_data, layout)?;
        let samp = Samples::load(e, sim_data, layout, t)?;
        let sync = match sync {
            Some(s) => s,
            None => {
                let mut s = crate::sync::Sync::new(e, model, sim_data)?;
                s.take_fired(e, t)?;
                s
            }
        };
        let mut core = SolverCore::new(&*e, model, sim_data, t, method, alloc_gbode(model, method)?)?;
        core.fmi_cs_solver_setup(defer);
        if core.n_states > 0 {
            core.read_states(e)?;
        }
        let h = model.step_size();
        let fixed_h = fixed_kind(method).map(|_| if h > 0.0 { h } else { f64::INFINITY });
        let mut zc0 = vec![0.0f64; layout.n_zc as usize];
        if core.n_states == 0 && layout.n_zc > 0 {
            read_zero_crossings(e, sim_data, layout, &mut zc0)?;
        }
        Ok(CsDriver { core, samp, sync, fixed_h, resume: None, zc0 })
    }

    /// The time reached so far (FMI's `last-successful-time`).
    pub fn time(&self) -> f64 {
        self.core.t
    }

    /// Advance to `t_target`. `defer` decides which events are reported to the
    /// master rather than resolved here. No budget: an importer's `do-step` runs to
    /// completion.
    pub fn step_to(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        t_target: f64,
        defer: CsDefer,
        dss: &mut StateSelection,
    ) -> Result<CsStep> {
        let layout = &model.layout;
        let sim_data = self.core.sim_data;
        // No continuous states: samples, clock activations, and zero crossings on
        // `time` bracketed and bisected between the communication points as
        // `EventsDriver` does.
        if self.core.n_states == 0 {
            self.resume = None;
            let eps = reached_eps(t_target, model.stop_time - model.start_time);
            let defers = |t: f64| match defer {
                CsDefer::None => false,
                CsDefer::AtTarget => t >= t_target - eps,
                CsDefer::Any => true,
            };
            let mut scratch = vec![0.0f64; layout.n_zc as usize];
            loop {
                rotate_old_real(e, sim_data, layout)?;
                let te = self.samp.next_time();
                let tc = self.sync.next_time();
                let mut subtarget = t_target;
                if tc >= self.core.t && tc <= subtarget + SYNC_EPS {
                    subtarget = tc;
                }
                if te >= self.core.t && te <= subtarget + SAMPLE_EPS {
                    subtarget = te;
                }
                let mut troot = None;
                if layout.n_zc > 0 && subtarget - self.core.t > eps {
                    update_zero_crossings(e, sim_data, layout, subtarget, &mut scratch, false)?;
                    if zc_crossed(&self.zc0, &scratch) {
                        troot = Some(locate_zc_root(e, sim_data, layout, self.core.t, subtarget, &self.zc0, &scratch)?);
                    }
                }
                if let Some((tleft, tr)) = troot {
                    eval_event_left(e, sim_data, layout, sim_data + REAL_OFF, tleft, &[])?;
                    // The bisection left `SimData` at its last trial point.
                    update_zero_crossings(e, sim_data, layout, tr, &mut scratch, false)?;
                    self.core.t = tr;
                    log_state_event(tr, &zc_crossed_idx(&self.zc0, &scratch), model);
                    if defers(tr) {
                        write_time(e, sim_data, tr)?;
                        return Ok(CsStep::Event { time: tr });
                    }
                    event_update(e, sim_data, layout, None, tr)?;
                    self.core.state_events += 1;
                    if terminated(e, sim_data, layout)? {
                        return Ok(CsStep::Terminated);
                    }
                    self.after_walk_event(e, layout)?;
                    continue;
                }
                if te <= subtarget + SAMPLE_EPS {
                    self.core.t = te;
                    log_time_event(e, te, &self.samp, model);
                    if defers(te) {
                        write_time(e, sim_data, te)?;
                        return Ok(CsStep::Event { time: te });
                    }
                    store_operators_at(e, sim_data, layout, te)?;
                    fire_time_event(e, &mut self.samp, sim_data, layout, te, None)?;
                    e.clean_nls_history(te);
                    self.core.time_events += 1;
                    if terminated(e, sim_data, layout)? {
                        return Ok(CsStep::Terminated);
                    }
                    self.after_walk_event(e, layout)?;
                }
                // C's `handleTimers`, plus any event clock the update above fired.
                if !self.sync.is_empty() {
                    write_time(e, sim_data, subtarget)?;
                    self.sync.take_fired(e, subtarget)?;
                }
                if self.sync.next_time() <= subtarget + SYNC_EPS {
                    self.core.t = subtarget;
                    if defers(subtarget) {
                        write_time(e, sim_data, subtarget)?;
                        return Ok(CsStep::Event { time: subtarget });
                    }
                    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
                    eval_continuous(e, sim_data, layout)?;
                    if fire_clocks(e, &mut self.sync, model, sim_data, subtarget, SYNC_EPS, None)? {
                        if terminated(e, sim_data, layout)? {
                            return Ok(CsStep::Terminated);
                        }
                        self.after_walk_event(e, layout)?;
                    }
                } else if te > subtarget + SAMPLE_EPS {
                    break;
                }
            }
            self.core.t = t_target;
            write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
            write_time(e, sim_data, t_target)?;
            e.call1_if_present("functionAlgebraics", sim_data)?;
            if terminated(e, sim_data, layout)? {
                return Ok(CsStep::Terminated);
            }
            store_operators(e, sim_data, layout)?;
            if layout.n_zc > 0 {
                read_zero_crossings(e, sim_data, layout, &mut self.zc0)?;
                save_zc_pre(e, sim_data, layout)?;
            }
            return Ok(CsStep::Reached);
        }

        self.refresh_ders(e)?;
        let outcome = self.integrate_chunked(e, model, t_target, defer)?;
        match outcome {
            Step::Terminated => return Ok(CsStep::Terminated),
            Step::Event { time } => return Ok(CsStep::Event { time }),
            // `deadline` is +inf and CS does not cancel.
            Step::Yielded | Step::Cancelled => return Err("CodegenWasmJit: CS step yielded unexpectedly"),
            Step::Reached { .. } => {}
        }
        // Refresh the outputs at the communication point, and re-select states there
        // (see `DasslDriver`).
        write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
        write_time(e, sim_data, t_target)?;
        e.call1("functionODE", sim_data)?;
        e.call1_if_present("functionAlgebraics", sim_data)?;
        if dss.reselect(e, sim_data, model)? {
            e.call1("functionODE", sim_data)?;
            self.core.read_states(e)?;
            self.core.restart()?;
        }
        if terminated(e, sim_data, layout)? {
            return Ok(CsStep::Terminated);
        }
        Ok(CsStep::Reached)
    }

    /// After an event the no-states walk resolved itself.
    fn after_walk_event(&mut self, e: &mut (dyn SimEngine + 'static), layout: &SimLayout) -> Result<()> {
        let sim_data = self.core.sim_data;
        store_operators(e, sim_data, layout)?;
        if layout.n_zc > 0 {
            read_zero_crossings(e, sim_data, layout, &mut self.zc0)?;
            save_zc_pre(e, sim_data, layout)?;
        }
        omclog::close(omclog::EVENTS);
        Ok(())
    }

    /// The master's `update-discrete-states` at the event `step_to` stopped on: the
    /// discrete update and bookkeeping [`integrate_to`](SolverCore::integrate_to)
    /// runs for an event it resolves itself, the restart left to the next step.
    ///
    /// C's `internalEventUpdate` runs `handleTimersFMI` here too, and on this
    /// schedule: it is the one `step_to` cut its step onto.
    pub fn do_event_update(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        time: f64,
    ) -> Result<EventUpdate> {
        let layout = &model.layout;
        let sim_data = self.core.sim_data;
        let sample_due = self.samp.next_time() <= time + SAMPLE_EPS;
        let clock_due = self.sync.next_time() <= time + SYNC_EPS;
        if sample_due {
            self.core.time_events += 1;
        } else if !clock_due {
            self.core.state_events += 1;
        }
        let mut up = self.event_update_master(e, layout, time)?;
        let ticked = fire_clocks(e, &mut self.sync, model, sim_data, time, SYNC_EPS, None)?;
        up.states_changed |= ticked;
        let tc = self.sync.next_time();
        if tc.is_finite() {
            up.next_event_time = Some(up.next_event_time.map_or(tc, |n: f64| n.min(tc)));
        }
        save_zero_crossings_after_event(e, sim_data, layout)?;
        store_operators(e, sim_data, layout)?;
        if self.core.n_states == 0 && layout.n_zc > 0 {
            read_zero_crossings(e, sim_data, layout, &mut self.zc0)?;
        }
        omclog::close(omclog::EVENTS);
        self.resume =
            Some(if sample_due || clock_due { MasterEvent::Time } else { MasterEvent::State });
        Ok(up)
    }

    /// [`SolverCore::event_update_here`] for the event the master resolves: the
    /// residual context `IDACalcIC` reads through is live only for the call.
    fn event_update_master(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        layout: &SimLayout,
        time: f64,
    ) -> Result<EventUpdate> {
        let sim_data = self.core.sim_data;
        if !self.core.dae {
            return event_update(e, sim_data, layout, Some(&mut self.samp), time);
        }
        let mut ctx = self.core.res_ctx(e, layout);
        let ctx_ptr = &mut ctx as *mut ResCtx;
        RES_CTX.store(ctx_ptr, Ordering::Relaxed);
        let _guard = ResCtxGuard;
        let Self { core, samp, .. } = self;
        let mut dae = |e: &mut dyn SimEngine| core.dae_restart(e, ctx_ptr);
        let up = event_update_dae(e, sim_data, layout, Some(samp), time, Some(&mut dae));
        match ctx.err.take() {
            Some(err) => Err(err),
            None => up,
        }
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
        defer: CsDefer,
    ) -> Result<Step> {
        let layout = &model.layout;
        let eps = t_target.abs().max(1.0) * 1e-12;
        let mut ctx = self.core.res_ctx(e, layout);
        let _guard = ResCtxGuard;
        RES_CTX.store(&mut ctx as *mut ResCtx, Ordering::Relaxed);
        // Here, where the residual context the `IDACalcIC` needs is live.
        if let Some(event) = self.resume.take() {
            match event {
                MasterEvent::State => self.core.read_states(e)?,
                MasterEvent::Time => {
                    self.core.read_y(e)?;
                    self.core.refresh_yp(e)?;
                }
            }
            self.core.event_restart(e, &mut ctx as *mut ResCtx)?;
        }
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
                &mut did_step, defer,
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
        mut gbode: Option<alloc::boxed::Box<crate::gbode::Gbode>>,
    ) -> Result<Self> {
        daskr::auxiliary::xsetf(1); // see `DasslDriver::new`
        let layout = &model.layout;
        // Init (with homotopy fallback). Relation mode 2 and `initSample` are handled
        // inside run_initialization; seed the hysteresis direction from the relations.
        crate::sync::clear_fire_flags(e, sim_data, layout)?;
        // C's `setupDataStruc`, before `initializeSolverData`: the DAE core below
        // reads nominals and maxes, not slots nothing has written yet.
        e.call1_if_present("functionAttrDefaults", sim_data)?;
        let start = model.start_time;
        // C's `solver_main` builds the solver before `initializeModel` in DAE mode,
        // "since the solver is used to obtain consistent values also via
        // updateDiscreteSystem". Only DAE mode needs it, and only there is the
        // `refresh_nominals` that repairs the not-yet-final nominals wanted.
        let mut early = match layout.dae_mode() {
            false => None,
            true => Some(SolverCore::new(&*e, model, sim_data, start, method, gbode.take())?),
        };
        let sync = match early.as_mut() {
            None => run_initialization_with_clocks(e, sim_data, model, None)?,
            Some(core) => {
                let mut ctx = core.res_ctx(e, layout);
                let ctx_ptr = &mut ctx as *mut ResCtx;
                RES_CTX.store(ctx_ptr, Ordering::Relaxed);
                let _guard = ResCtxGuard;
                let mut dae = |e: &mut dyn SimEngine| core.dae_event_update(e, ctx_ptr);
                let sync = run_initialization_with_clocks(e, sim_data, model, Some(&mut dae))?;
                if let Some(err) = ctx.err.take() {
                    return Err(err);
                }
                sync
            }
        };
        let mut core = match early {
            Some(mut core) => {
                core.refresh_nominals(&*e, layout)?;
                core
            }
            None => SolverCore::new(&*e, model, sim_data, start, method, gbode)?,
        };
        store_relations(e, sim_data, layout)?;

        let n_states = layout.n_states as usize;
        let states_base = sim_data + REAL_OFF;
        let n_rows = model.n_output_rows();
        let n_reals = layout.n_row_total();

        let samp = Samples::load(e, sim_data, layout, start)?;
        let mut rows: Vec<f64> = Vec::with_capacity((n_rows * n_reals) as usize);
        // A sample due at the start time is left to the first step, which C shortens
        // to zero length and handles as an ordinary time event.
        let dss = StateSelection::initial(e, sim_data, model)?;
        emit_initial_row(e, &mut rows, sim_data, layout, start)?;
        let pending_terminate = terminated(e, sim_data, layout)?;

        if n_states > 0 && !pending_terminate {
            core.read_states(e)?;
        }
        let _ = states_base;
        // C's `storeOldValues` in `solver_main`.
        let mut retry = StepRetry::default();
        retry.store(e, sim_data, layout)?;
        Ok(EventsDriver {
            core,
            row: 1,
            reached: start,
            dss,
            samp,
            sync,
            rows,
            mid_row: false,
            grid_covered: false,
            did_event_step: false,
            no_grid_primed: false,
            pending_terminate,
            finished: false,
            pending_tout: None,
            retry,
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
        let tout_of = |row: u32| if no_grid { stop } else { grid(row) };
        // C ends on `currentTime >= stopTime`, not on a row count, so a last grid
        // point left short of `stop` gets one more step at `grid(n_steps + 1)`.
        let more = |row: u32, t: f64| if no_grid || n_steps == 0 { row < n_rows } else { t < stop };
        // C's `perform_simulation` skips an output point an event step already
        // carried the run past (`currentStepSize < 1e-15`).
        let skip_grid = |row: u32, t: f64, ev: bool| !no_grid && ev && grid(row) - t < GRID_SKIP_EPS;

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
            while more(self.row, self.reached) {
                if skip_grid(self.row, self.reached, self.did_event_step) {
                    self.row += 1;
                    continue;
                }
                if did_step && past_deadline(deadline) {
                    return Ok(Advance::Running);
                }
                check_alarm()?;
                if cancel_requested() {
                    return Ok(Advance::Cancelled);
                }
                did_step = true;
                let tout = self.pending_tout.take().unwrap_or_else(|| tout_of(self.row));
                logging_window(e, self.core.t, tout);
                let eps = reached_eps(tout, stop - start);
                let mut grid_covered = false;
                let mut event_step = false;
                // C's `MMC_TRY_INTERNAL(simulationJumpBuffer)` around the whole step.
                self.retry.open(e, &mut self.rows);
                open_assert_window();
                // C's `updateContinuousSystem` landed on the grid point and nothing
                // has moved the state since: the row is emitted from it, as C's is.
                let mut evaluated = false;
                // Handle every event (state or sample) up to `tout`, earliest first.
                loop {
                    rotate_old_real(e, sim_data, layout)?;
                    let te = self.samp.next_time();
                    let tc = self.sync.next_time();
                    let mut subtarget = tout;
                    if tc >= self.core.t && tc <= subtarget + SYNC_EPS {
                        subtarget = tc;
                    }
                    if te >= self.core.t && te <= subtarget + SAMPLE_EPS {
                        subtarget = te;
                    }
                    // A state event bracketed in (t, subtarget]?
                    let mut troot = None;
                    if layout.n_zc > 0 && subtarget - self.core.t > eps {
                        evaluated = subtarget >= tout - eps;
                        update_zero_crossings(e, sim_data, layout, subtarget, &mut scratch, evaluated)?;
                        if zc_crossed(&zc0, &scratch) {
                            troot = Some(locate_zc_root(
                                e, sim_data, layout, self.core.t, subtarget, &zc0, &scratch,
                            )?);
                        }
                    }
                    if let Some((tleft, tr)) = troot {
                        supersede(e, &mut evaluated);
                        // The bisection left `SimData` at its last trial point.
                        update_zero_crossings(e, sim_data, layout, tr, &mut scratch, false)?;
                        log_state_event(tr, &zc_crossed_idx(&zc0, &scratch), model);
                        eval_event_left(e, sim_data, layout, sim_data + REAL_OFF, tleft, &[])?;
                        write_time(e, sim_data, tr)?;
                        if !no_event_emit() {
                            capture_row(e, &mut self.rows, sim_data, layout)?; // pre-event row
                        }
                        event_update(e, sim_data, layout, None, tr)?;
                        self.core.state_events += 1;
                        self.core.walk_steps += 1;
                        event_step = true;
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
                        if fire_clocks(e, &mut self.sync, model, sim_data, tr, SYNC_EPS, Some(&mut self.rows))?
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
                                omclog::close(omclog::EVENTS);
                        if tout - tr < GRID_SKIP_EPS {
                            grid_covered = true;
                        }
                        continue;
                    }
                    // No state event before the next sample time. Fire the sample if
                    // it is due at or before this grid point; otherwise the interval
                    // is clean up to `tout`.
                    if te <= subtarget + SAMPLE_EPS {
                        supersede(e, &mut evaluated);
                        event_step = true;
                        log_time_event(e, te, &self.samp, model);
                        write_i32(e, sim_data + layout.rel_fresh_off, 0)?; // held pre row
                        if !no_event_emit() {
                            emit_row(e, &mut self.rows, sim_data, layout, te, model.stop_time)?;
                        }
                        store_operators_at(e, sim_data, layout, te)?;
                        fire_time_event(e, &mut self.samp, sim_data, layout, te, None)?;
                        e.clean_nls_history(te);
                        self.core.time_events += 1;
                        self.core.walk_steps += 1;
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
                                omclog::close(omclog::EVENTS);
                        if tout - te < GRID_SKIP_EPS {
                            grid_covered = true;
                        }
                    }
                    if !self.sync.is_empty() {
                        write_time(e, sim_data, subtarget)?;
                        self.sync.take_fired(e, subtarget)?;
                    }
                    if self.sync.next_time() <= subtarget + SYNC_EPS {
                        supersede(e, &mut evaluated);
                        event_step = true;
                        self.core.t = subtarget;
                        write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
                        eval_continuous(e, sim_data, layout)?;
                        if fire_clocks(e, &mut self.sync, model, sim_data, subtarget, SYNC_EPS, Some(&mut self.rows))? {
                            if terminated(e, sim_data, layout)? {
                                self.finished = true;
                                return Ok(Advance::Terminated);
                            }
                            store_operators(e, sim_data, layout)?;
                            if layout.n_zc > 0 {
                                read_zero_crossings(e, sim_data, layout, &mut zc0)?;
                                save_zc_pre(e, sim_data, layout)?;
                            }
                            if tout - subtarget < GRID_SKIP_EPS {
                                grid_covered = true;
                            }
                        }
                    } else if te > subtarget + SAMPLE_EPS {
                        break;
                    }
                }
                if !grid_covered {
                    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
                    let emitted = if evaluated {
                        emit_row_evaluated(e, &mut self.rows, sim_data, layout, tout, model.stop_time)
                    } else {
                        emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time)
                    };
                    close_assert_window(e, sim_data).and(emitted)?;
                    if terminated(e, sim_data, layout)? {
                        self.retry.end(e);
                        self.finished = true;
                        return Ok(Advance::Terminated);
                    }
                    store_operators(e, sim_data, layout)?;
                    if layout.n_zc > 0 {
                        read_zero_crossings(e, sim_data, layout, &mut zc0)?;
                        save_zc_pre(e, sim_data, layout)?;
                    }
                    self.core.t = tout;
                    self.core.walk_steps += 1;
                } else {
                    close_assert_window(e, sim_data)?;
                }
                self.retry.close(e)?;
                self.retry.store(e, sim_data, layout)?;
                self.reached = self.core.t;
                self.did_event_step = event_step;
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
            if !self.mid_row && !more(self.row, self.reached) {
                break Advance::Done;
            }
            if !self.mid_row && skip_grid(self.row, self.reached, self.did_event_step) {
                self.row += 1;
                continue;
            }
            if did_step && past_deadline(deadline) {
                break Advance::Running;
            }
            check_alarm()?;
            if cancel_requested() {
                break Advance::Cancelled;
            }
            let tout = self.pending_tout.unwrap_or_else(|| tout_of(self.row));
            logging_window(e, self.core.t, tout);
            if !self.mid_row {
                self.grid_covered = false;
                self.did_event_step = false;
            }
            // C's `MMC_TRY_INTERNAL(simulationJumpBuffer)`: the whole step, the
            // integration included, falls back to the last accepted point.
            self.retry.open(e, &mut self.rows);
            // C's `simulationUpdate` window: until this row's events are handled,
            // the state the model is evaluated at may still be discarded.
            open_assert_window();
            match self.core.integrate_to(
                e, model, &mut ctx, &mut self.samp, &mut self.sync, tout, deadline,
                Some(&mut self.rows), &mut did_step, CsDefer::None,
            )? {
                Step::Yielded => {
                    // Resume on the same row; `mid_row` keeps `grid_covered`.
                    self.mid_row = true;
                    self.retry.close(e)?;
                    return Ok(Advance::Running);
                }
                Step::Cancelled => {
                    self.retry.close(e)?;
                    return Ok(Advance::Cancelled);
                }
                Step::Terminated => break Advance::Terminated,
                // Nothing is deferred here, so `Event` never arises.
                Step::Event { .. } => unreachable!("the output-grid driver defers no event"),
                Step::Reached { grid_covered, event_step } => {
                    self.grid_covered |= grid_covered;
                    self.did_event_step |= event_step;
                }
            }
            // Row's inner loop done; the rest is bounded — next yield is a clean boundary.
            self.mid_row = false;
            self.reached = if self.grid_covered { self.core.t } else { tout };
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
            if self.dss.reselect(e, sim_data, model)? {
                e.call1("functionODE", sim_data)?;
                self.core.read_states(e)?;
                self.core.restart()?;
            }
            self.retry.close(e)?;
            self.retry.store(e, sim_data, layout)?;
            self.pending_tout = None;
            self.row += 1;
        };
        self.core.nfe = ctx.nfe;
        self.retry.end(e); // a `break` out of the region still has to leave it
        if matches!(outcome, Advance::Done | Advance::Terminated) {
            self.finished = true;
        }
        Ok(outcome)
    }

    fn retry_step(&mut self, e: &mut (dyn SimEngine + 'static), model: &SimModel) -> Result<bool> {
        let layout = &model.layout;
        let Some(t) = self.retry.undo(e, self.core.sim_data, layout)? else {
            return Ok(false);
        };
        self.rows.truncate(self.retry.rows_mark);
        let n_steps = model.n_output_rows() - 1;
        let target = self.pending_tout.unwrap_or(if self.row >= n_steps {
            model.stop_time
        } else {
            grid_time(self.row, model.start_time, model.stop_time, n_steps)
        });
        self.core.t = t;
        self.reached = t;
        self.mid_row = false;
        self.grid_covered = false;
        self.did_event_step = true; // C's `retrySimulationStep`
        self.pending_tout = Some(t + (target - t) / 2.0);
        self.core.read_states(e)?;
        self.core.restart()?;
        Ok(true)
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
        write_time(e, ctx.sim_data, t)?;
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
    write_time(e, ctx.sim_data, t)?;
    unsafe { ida_push_unknowns(ctx, y, yp) }?;
    set_context(e, ctx.ctx_addr, CONTEXT_EVENTS);
    if unsafe { ctx.ida.dae.as_ref() }.is_some() {
        e.call2(MODEL_FN_DAE, ctx.sim_data, eval_stage::ZEROCROSS)?;
    } else {
        e.call1("functionZeroCrossingsEquations", ctx.sim_data)?;
    }
    e.call2(MODEL_FN_ZC, ctx.sim_data, ctx.sim_data + ctx.zc_probe_off)?;
    set_context(e, ctx.ctx_addr, CONTEXT_ALGEBRAIC);
    let out = unsafe { core::slice::from_raw_parts_mut(gout as *mut u8, ctx.n_zc * 8) };
    e.read_bytes(ctx.sim_data + ctx.zc_probe_off, out)
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
    dss: StateSelection,
    rows: Vec<f64>,
    /// Resumes an output interval left unfinished by a work-quota return or a yield.
    work_retries: u32,
    pending_terminate: bool,
    finished: bool,
    /// Where a retried step ends, short of this row's grid point.
    pending_tout: Option<f64>,
    retry: StepRetry,
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
        let dss = StateSelection::initial(e, sim_data, model)?;
        emit_initial_row(e, &mut rows, sim_data, layout, start)?;
        let pending_terminate = terminated(e, sim_data, layout)?;

        let mut y = Vec::new();
        if n_states > 0 && !pending_terminate {
            y = (0..n_states).map(|i| read_f64(e, states_base + (i as u32) * 8)).collect::<Result<_>>()?;
        }

        let tol = if model.tolerance > 0.0 { model.tolerance } else { 1e-6 };
        let nominals = read_state_nominals(e, sim_data, layout)?;
        let (_, atol) = dassl_tolerances(tol, &nominals);
        let cv = if y.is_empty() {
            None
        } else {
            Some(
                crate::sundials::Cvode::new(
                    start, &y, tol, &atol, 0, cvode_rhs, None,
                    crate::simflags::with_flags(|f| crate::simflags::cvode_config(&f)),
                )
                .ok_or("CodegenWasmJit: CVODE initialization failed")?,
            )
        };

        // C's `storeOldValues` in `solver_main`.
        let mut retry = StepRetry::default();
        retry.store(e, sim_data, layout)?;
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
            dss,
            rows,
            work_retries: 0,
            pending_terminate,
            finished: false,
            pending_tout: None,
            retry,
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
                rotate_old_real(e, sim_data, layout)?;
                let time =
                    self.pending_tout.take().unwrap_or(if self.row == n_steps { stop } else { grid(self.row) });
                logging_window(e, self.t, time);
                self.retry.open(e, &mut self.rows);
                open_assert_window();
                let emitted = emit_row(e, &mut self.rows, sim_data, layout, time, model.stop_time);
                close_assert_window(e, sim_data).and(emitted)?;
                store_operators(e, sim_data, layout)?;
                self.retry.close(e)?;
                self.t = time;
                self.retry.store(e, sim_data, layout)?;
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
            inline_dt_off: layout.inline_dt_off,
            alg_old_off: layout.alg_old_off,
            nfe: 0,
            zc_probe_off: 0,
            zc_off: 0,
            n_zc: 0,
            err: None,
            jac: core::ptr::null(),
            jac_method: JacobianMethod::InternalNumJac,
            jac_gp: Vec::new(),
            jac_ysave: Vec::new(),
            jac_del: Vec::new(),
            jac_ders: Vec::new(),
            jac_ypsave: Vec::new(),
            nje: 0,
            ctx_addr: e.context_addr(),
            err_stage_addr: e.error_stage_addr(),
            nominals: self.nominals.as_ptr(),
            nominal_factor: nominal_factor(),
            tol: self.tol,
            state_names: core::ptr::null(),
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
            rotate_old_real(e, sim_data, layout)?;
            self.retry.open(e, &mut self.rows);
            let tout =
                self.pending_tout.take().unwrap_or(if self.row == n_steps { stop } else { grid(self.row) });
            logging_window(e, self.t, tout);
            // Zero-length final interval: emit the held state rather than step.
            if tout <= self.t {
                for (i, v) in cv.y().iter().enumerate() {
                    write_f64(e, states_base + (i as u32) * 8, *v)?;
                }
                emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time)?;
                self.retry.close(e)?;
                self.retry.store(e, sim_data, layout)?;
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
                    self.pending_tout = Some(tout);
                    self.retry.close(e)?;
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
            self.retry.close(e)?;
            self.retry.store(e, sim_data, layout)?;
            if terminated(e, sim_data, layout)? {
                break Advance::Terminated;
            }
            // A state-set switch changes the meaning of the state vector, so
            // re-read it and restart CVODE (see `DasslDriver`).
            if self.dss.reselect(e, sim_data, model)? {
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

    fn retry_step(&mut self, e: &mut (dyn SimEngine + 'static), model: &SimModel) -> Result<bool> {
        let Some(t) = self.retry.undo(e, self.sim_data, &model.layout)? else {
            return Ok(false);
        };
        self.rows.truncate(self.retry.rows_mark);
        let n_steps = model.n_output_rows() - 1;
        let target = self.pending_tout.unwrap_or(if self.row >= n_steps {
            model.stop_time
        } else {
            grid_time(self.row, model.start_time, model.stop_time, n_steps)
        });
        self.t = t;
        self.pending_tout = Some(t + (target - t) / 2.0);
        self.work_retries = 0;
        if let Some(cv) = self.cv.as_mut() {
            for i in 0..self.n_states {
                cv.y_mut()[i] = read_f64(e, self.states_base + (i as u32) * 8)?;
            }
            if !cv.reinit(t) {
                return Err("CodegenWasmJit: CVODE re-initialization failed");
            }
        }
        Ok(true)
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
    /// Sparsity, coloring and symbolic columns; `None` ⇒ IDA's own dense
    /// difference-quotient Jacobian (C's `INTERNALNUMJAC`).
    jac_a: Option<JacAInfo>,
    /// C's `idaData->jacobianMethod`, after IDA's own downgrades.
    jac_method: JacobianMethod,
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
    ramp: LambdaRamp,
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

#[cfg(sundials)]
fn dae_calc_ic(ida: &mut crate::sundials::Ida, t: f64, tol: f64) -> Result<()> {
    omclog::info!(omclog::SOLVER, false, "##IDA## do event update at {}", format_g(t, 15));
    match ida.calc_ic_at(t, tol) {
        true => Ok(()),
        false => Err("CodegenWasmJit: IDA could not find consistent initial conditions (IDACalcIC)"),
    }
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

/// `ida_solver.c`'s follow-up to [`set_jacobian_method`]: IDA has no uncolored
/// evaluator, and with KLU no internal one, so those become their colored form; a
/// Krylov solver assembles no matrix and C pins it to `INTERNALNUMJAC` last.
#[cfg(sundials)]
fn ida_jacobian_method(jac: Option<&JacAInfo>, ls: crate::sundials::IdaLs, log: bool) -> JacobianMethod {
    use JacobianMethod as M;
    let m = set_jacobian_method(jac, log);
    let (m, msg) = match m {
        M::SymJac => (
            M::ColoredSymJac,
            Some(
                "Symbolic Jacobians without coloring are currently not supported by IDA. \
                 Colored symbolical Jacobian will be used.",
            ),
        ),
        M::NumJac => (
            M::ColoredNumJac,
            Some(
                "Numerical Jacobians without coloring are currently not supported by IDA. \
                 Colored numerical Jacobian will be used.",
            ),
        ),
        M::InternalNumJac if ls == crate::sundials::IdaLs::Klu => (
            M::ColoredNumJac,
            Some(
                "Internal Numerical Jacobians without coloring are currently not supported by IDA with KLU. \
                 Colored numerical Jacobian will be used.",
            ),
        ),
        m => (m, None),
    };
    if log && let Some(msg) = msg {
        omclog::warning(omclog::STDOUT, false, msg);
    }
    match ls.matrix_free() {
        true => M::InternalNumJac,
        false => m,
    }
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
        // In DAE mode only the new backend fills "A"; the old one takes C's
        // `INTERNALNUMJAC` downgrade.
        let avail = match env_var("OMC_WASM_NO_ANALYTIC_JAC").is_some() {
            true => None,
            false => model.jac_a.as_ref(),
        };
        let jac_method = ida_jacobian_method(avail, ls, false);
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
            jac_method,
            pattern,
            opts,
            sens_offs,
            sens_off: layout.sens_off,
            sens_scratch: vec![0.0; n_sens],
            dae,
            ramp: LambdaRamp { off: layout.lambda_off, start: model.start_time, ..Default::default() },
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
            // Left out, IDA differences its own dense one (`INTERNALNUMJAC`).
            (self.jac_method != JacobianMethod::InternalNumJac && self.jac_a.is_some())
                .then_some(ida_jac as crate::sundials::IdaJacFn),
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
            ramp: self.ramp,
        }
    }

    /// C's `idaHomotopyRampRecovers`. The Jacobian is only singular to the accuracy
    /// of the difference quotient, so a failed corrector counts as well as a failed
    /// factorization.
    fn ramp_recovers(&self, flag: core::ffi::c_int, t: f64) -> bool {
        use crate::sundials::{IDA_CONV_FAIL, IDA_ERR_FAIL, IDA_LSETUP_FAIL};
        self.dae.is_some()
            && !self.ramp.active
            && init_homotopy_steps() > 0
            && matches!(flag, IDA_LSETUP_FAIL | IDA_CONV_FAIL | IDA_ERR_FAIL)
            && t <= self.ramp.start
    }

    /// C's `idaActivateHomotopyRamp`.
    fn arm_ramp(&mut self, ida: &mut crate::sundials::Ida, stop_time: f64) {
        self.ramp.tramp = match env_var("OMC_DAE_HOMOTOPY_TRAMP").and_then(|v| v.parse().ok()) {
            Some(v) => v,
            None => 0.1 * (stop_time - self.ramp.start),
        };
        self.ramp.active = true;
        if self.ramp.tramp > 0.0 {
            ida.set_max_step(self.ramp.tramp / 50.0);
        }
    }

    /// Past the ramp window: lift the step cap and pin lambda, as C does at the top
    /// of `ida_solver_step`.
    fn finish_ramp(
        &mut self,
        e: &mut dyn SimEngine,
        sim_data: u32,
        ida: &mut crate::sundials::Ida,
        t: f64,
    ) -> Result<()> {
        if !(self.ramp.active && self.ramp.tramp > 0.0 && t >= self.ramp.start + self.ramp.tramp) {
            return Ok(());
        }
        ida.set_max_step(0.0);
        write_f64(e, sim_data + self.ramp.off, 1.0)?;
        self.ramp.active = false;
        Ok(())
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
    write_time(e, ctx.sim_data, t)?;
    if let Some(lambda) = ctx.ida.ramp.lambda_at(t) {
        write_f64(e, ctx.sim_data + ctx.ida.ramp.off, lambda)?;
    }
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
        Err(err) if residual_model_throw(e, err, t) => 1,
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
    vals.fill(0.0); // C's `SUNMatZero`: the widened diagonal has no difference to carry
    ctx.jac_gp.resize(n, 0.0);
    ctx.nje += 1;
    // C's `jacColoredSymbolicalSparse` / `jacColoredSymbolicalDense`. IDA's residual
    // is F = f − y', so a column result is `∂F/∂y` already.
    if jac_method_symbolic(ctx.jac_method) {
        let run = (|| -> Result<()> {
            eval_sym_jacobian(e, ctx.sim_data, jac, ctx.ctx_addr, true, &mut |row, col, k, v| {
                vals[match pattern {
                    Some(p) => p.slots[col][k],
                    None => col * n + row,
                }] = v;
            })?;
            // -cj·∂F/∂y' = -cj·I, which the column equations do not carry. C adds it
            // for an ODE only; a DAE pattern is not widened and has no diagonal slot.
            if dae.is_none() {
                for col in 0..n {
                    vals[pattern.map_or(col * n + col, |p| p.diag[col])] -= cj;
                }
            }
            Ok(())
        })();
        return match run {
            Err(err) => {
                ctx.err = Some(err);
                -1
            }
            Ok(()) => 0,
        };
    }
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
            // C's `jacoColoredNumericalSparse` ignores what the probe returns:
            // `residualFunctionIDA` catches a model throw itself, leaving
            // `newdelta` at the previous colour's values.
            if let Err(err) = r
                && !residual_model_throw(e, err, t)
            {
                return Err(err);
            }
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
    dss: StateSelection,
    rows: Vec<f64>,
    /// Resumes an output interval left unfinished by a work-quota return or a yield.
    work_retries: u32,
    /// `-noEquidistantOutput{Frequency,Time}` over IDA's own steps.
    step_emit: StepEmit,
    /// C's degenerate first `-noEquidistantTimeGrid` iteration has been emitted.
    no_grid_primed: bool,
    pending_terminate: bool,
    finished: bool,
    /// Where a retried step ends, short of this row's grid point.
    pending_tout: Option<f64>,
    retry: StepRetry,
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
        // For an explicit ODE the consistent `y'` is f(t0, y0), which the initial
        // row leaves in the derivative slots.
        let dss = StateSelection::initial(e, sim_data, model)?;
        emit_initial_row(e, &mut rows, sim_data, layout, start)?;
        let pending_terminate = terminated(e, sim_data, layout)?;

        let (mut y, mut yp) = (Vec::new(), Vec::new());
        if n_states > 0 && !pending_terminate {
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

        // C's `storeOldValues` in `solver_main`.
        let mut retry = StepRetry::default();
        retry.store(e, sim_data, layout)?;
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
            dss,
            rows,
            work_retries: 0,
            step_emit: StepEmit::new(),
            no_grid_primed: false,
            pending_terminate,
            finished: false,
            pending_tout: None,
            retry,
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
                rotate_old_real(e, sim_data, layout)?;
                let time =
                    self.pending_tout.take().unwrap_or(if self.row == n_steps { stop } else { grid(self.row) });
                logging_window(e, self.t, time);
                self.retry.open(e, &mut self.rows);
                open_assert_window();
                let emitted = emit_row(e, &mut self.rows, sim_data, layout, time, model.stop_time);
                close_assert_window(e, sim_data).and(emitted)?;
                store_operators(e, sim_data, layout)?;
                self.retry.close(e)?;
                self.t = time;
                self.retry.store(e, sim_data, layout)?;
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
            inline_dt_off: layout.inline_dt_off,
            alg_old_off: layout.alg_old_off,
            nfe: 0,
            zc_probe_off: 0,
            zc_off: 0,
            n_zc: 0,
            err: None,
            jac: self.setup.jac_a.as_ref().map_or(core::ptr::null(), |j| j as *const JacAInfo),
            jac_method: self.setup.jac_method,
            jac_gp: Vec::new(),
            jac_ysave: vec![0.0; n_states],
            jac_del: vec![0.0; n_states],
            jac_ders: Vec::new(),
            jac_ypsave: Vec::new(),
            nje: 0,
            ctx_addr: e.context_addr(),
            err_stage_addr: e.error_stage_addr(),
            nominals: self.nominals.as_ptr(),
            nominal_factor: nominal_factor(),
            tol: self.tol,
            state_names: core::ptr::null(),
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
            rotate_old_real(e, sim_data, layout)?;
            self.retry.open(e, &mut self.rows);
            let tout = self
                .pending_tout
                .take()
                .unwrap_or(if no_grid || self.row == n_steps { stop } else { grid(self.row) });
            logging_window(e, self.t, tout);
            // Zero-length final interval: emit the held state rather than step.
            if tout <= self.t {
                for (i, v) in ida.y().iter().enumerate() {
                    write_f64(e, states_base + (i as u32) * 8, *v)?;
                }
                emit_row(e, &mut self.rows, sim_data, layout, tout, model.stop_time)?;
                self.retry.close(e)?;
                self.retry.store(e, sim_data, layout)?;
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
                    self.pending_tout = Some(tout);
                    self.retry.close(e)?;
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
                self.pending_tout = Some(tout);
                self.retry.close(e)?;
                self.retry.store(e, sim_data, layout)?;
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
            self.retry.close(e)?;
            self.retry.store(e, sim_data, layout)?;
            if terminated(e, sim_data, layout)? {
                break Advance::Terminated;
            }
            // Restart IDA on the reinitialised states (see `DasslDriver`).
            if self.dss.reselect(e, sim_data, model)? {
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

    fn retry_step(&mut self, e: &mut (dyn SimEngine + 'static), model: &SimModel) -> Result<bool> {
        let Some(t) = self.retry.undo(e, self.sim_data, &model.layout)? else {
            return Ok(false);
        };
        self.rows.truncate(self.retry.rows_mark);
        let n_steps = model.n_output_rows() - 1;
        let target = self.pending_tout.unwrap_or(if self.row >= n_steps {
            model.stop_time
        } else {
            grid_time(self.row, model.start_time, model.stop_time, n_steps)
        });
        self.t = t;
        self.pending_tout = Some(t + (target - t) / 2.0);
        self.work_retries = 0;
        if let Some(ida) = self.ida.as_mut() {
            for i in 0..self.n_states {
                ida.y_mut()[i] = read_f64(e, self.states_base + (i as u32) * 8)?;
                ida.yp_mut()[i] = read_f64(e, self.ders_base + (i as u32) * 8)?;
            }
            if !ida.reinit(t) {
                return Err("CodegenWasmJit: IDA re-initialization failed");
            }
        }
        Ok(true)
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
        Ok(GuessStepper { core })
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
            write_time(e, self.core.sim_data, tstop)?;
            return eval_continuous(e, self.core.sim_data, layout);
        }
        let mut ctx = self.core.res_ctx(e, layout);
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
                Ok(Solved::RootThrew(err)) | Err(err) => {
                    iter += 1;
                    if iter > 10 {
                        omclog::warning!(
                            omclog::STDOUT,
                            false,
                            "Initial guess failure at time {}",
                            format_g(self.core.t, 12),
                        );
                        return Err(err);
                    }
                    frac *= 0.5;
                }
            }
        }
        self.core.write_states(e)?;
        // C's `dassl_step` publishes the accepted time before
        // `updateContinuousSystem`, which re-reads the input there.
        write_time(e, self.core.sim_data, self.core.t)?;
        eval_continuous(e, self.core.sim_data, layout)
    }
}

// ── A `--daeMode` model evaluated as an explicit ODE ─────────────────────────

/// Solve `F(t, x, x', z) = 0` for the derivatives and the algebraic unknowns at
/// the time and states `SimData` holds — what an FMU exported from a `--daeMode`
/// model owes an importer that runs it as an ordinary ODE FMU. A damped Newton
/// iteration over `evaluateDAEResiduals`, started from the values the slots hold
/// (the previous point, or the initial system's), with a differenced Jacobian: a
/// colour at a time where the residual sparsity is known, a `der(x)` column taking
/// its state's pattern since DAE-mode differentiation folds `der(x)` into `x`.
pub fn dae_solve_explicit(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    dae: &DaeInfo,
) -> Result<()> {
    const MAX_ITER: usize = 100;
    const RTOL: f64 = 1e-10;
    let n = layout.n_dae_res as usize;
    let ns = layout.n_states as usize;
    if n == 0 {
        return Ok(());
    }
    if dae.alg_offs.len() + ns != n {
        return Err("CodegenWasmJit: DAE-mode metadata disagrees with the layout");
    }
    let offs: Vec<u32> = (0..ns)
        .map(|i| REAL_OFF + ((ns + i) as u32) * 8)
        .chain(dae.alg_offs.iter().copied())
        .collect();
    let mut scale = vec![1.0; n];
    for k in 0..dae.alg_offs.len() {
        let nom = read_f64(e, sim_data + layout.dae_alg_nom_off + (k as u32) * 8)?.abs();
        if nom > 0.0 && nom.is_finite() {
            scale[ns + k] = nom;
        }
    }
    let mut u: Vec<f64> = offs.iter().map(|&o| read_f64(e, sim_data + o)).collect::<Result<_>>()?;
    let res_base = sim_data + layout.dae_res_off;
    let mut residual = |e: &mut dyn SimEngine, u: &[f64], out: &mut [f64]| -> Result<()> {
        for (&o, &v) in offs.iter().zip(u) {
            write_f64(e, sim_data + o, v)?;
        }
        e.call2(MODEL_FN_DAE, sim_data, eval_stage::DYNAMIC)?;
        read_f64s(e, res_base, out)
    };
    let pattern = dae.sparsity.as_ref().filter(|p| p.n as usize == n && p.rows_by_col.len() == n);
    let mut f0 = vec![0.0; n];
    let mut f1 = vec![0.0; n];
    let mut jac = vec![0.0; n * n];
    let mut delta = vec![0.0; n];
    let mut trial = vec![0.0; n];
    residual(e, &u, &mut f0)?;
    let norm = |f: &[f64]| f.iter().fold(0.0f64, |m, v| m.max(v.abs()));
    let mut fnorm = norm(&f0);
    for _ in 0..MAX_ITER {
        if !fnorm.is_finite() {
            return Err(DAE_EXPLICIT_FAILED);
        }
        if fnorm == 0.0 {
            break;
        }
        jac.iter_mut().for_each(|v| *v = 0.0);
        let step = |j: usize, u: &[f64]| libm::sqrt(f64::EPSILON) * u[j].abs().max(scale[j]);
        let mut column = |e: &mut dyn SimEngine, cols: &[usize], jac: &mut [f64], u: &mut [f64]| -> Result<()> {
            let saved: Vec<f64> = cols.iter().map(|&j| u[j]).collect();
            for &j in cols {
                u[j] += step(j, u);
            }
            residual(e, u, &mut f1)?;
            for (&j, &old) in cols.iter().zip(&saved) {
                let h = u[j] - old;
                u[j] = old;
                let rows: Vec<usize> = match pattern {
                    Some(p) => p.rows_by_col[j].iter().map(|&r| r as usize).collect(),
                    None => (0..n).collect(),
                };
                for r in rows {
                    jac[r * n + j] = (f1[r] - f0[r]) / h;
                }
            }
            Ok(())
        };
        match pattern {
            Some(p) => {
                for color in &p.colors {
                    let cols: Vec<usize> = color.iter().map(|&c| c as usize).collect();
                    column(e, &cols, &mut jac, &mut u)?;
                }
            }
            None => {
                for j in 0..n {
                    column(e, &[j], &mut jac, &mut u)?;
                }
            }
        }
        for i in 0..n {
            delta[i] = -f0[i];
        }
        if !lu_solve(&mut jac, &mut delta, n) {
            return Err(DAE_EXPLICIT_FAILED);
        }
        let mut lambda = 1.0;
        let mut accepted = false;
        for _ in 0..8 {
            for i in 0..n {
                trial[i] = u[i] + lambda * delta[i];
            }
            residual(e, &trial, &mut f1)?;
            let fn1 = norm(&f1);
            if fn1.is_finite() && fn1 < fnorm * (1.0 - 1e-4 * lambda) {
                accepted = true;
                break;
            }
            lambda *= 0.5;
        }
        if !accepted {
            lambda = 1.0;
            for i in 0..n {
                trial[i] = u[i] + delta[i];
            }
            residual(e, &trial, &mut f1)?;
        }
        let converged =
            (0..n).all(|i| (lambda * delta[i]).abs() <= RTOL * u[i].abs().max(scale[i]));
        u.copy_from_slice(&trial);
        core::mem::swap(&mut f0, &mut f1);
        fnorm = norm(&f0);
        if converged && fnorm.is_finite() {
            return Ok(());
        }
    }
    if fnorm == 0.0 {
        return Ok(());
    }
    Err(DAE_EXPLICIT_FAILED)
}

const DAE_EXPLICIT_FAILED: &str =
    "CodegenWasmJit: the derivatives of the DAE-mode model could not be solved for (the Newton iteration over the residual did not converge)";

/// Gaussian elimination with partial pivoting on the row-major `a`, `b` becoming
/// the solution. `false` on a singular matrix.
fn lu_solve(a: &mut [f64], b: &mut [f64], n: usize) -> bool {
    for k in 0..n {
        let mut p = k;
        let mut best = a[k * n + k].abs();
        for i in k + 1..n {
            let v = a[i * n + k].abs();
            if v > best {
                best = v;
                p = i;
            }
        }
        if !(best > 0.0) || !best.is_finite() {
            return false;
        }
        if p != k {
            for j in 0..n {
                a.swap(k * n + j, p * n + j);
            }
            b.swap(k, p);
        }
        let pivot = a[k * n + k];
        for i in k + 1..n {
            let f = a[i * n + k] / pivot;
            if f == 0.0 {
                continue;
            }
            for j in k..n {
                a[i * n + j] -= f * a[k * n + j];
            }
            b[i] -= f * b[k];
        }
    }
    for k in (0..n).rev() {
        let mut s = b[k];
        for j in k + 1..n {
            s -= a[k * n + j] * b[j];
        }
        b[k] = s / a[k * n + k];
    }
    true
}
