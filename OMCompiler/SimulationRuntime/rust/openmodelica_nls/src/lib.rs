//! C's `solve_nonlinear_system` and the whole ladder under it: the Newton /
//! homotopy / MINPACK solvers every `SES_NONLINEAR` system is put through.
//!
//! Port of `nonlinearSystem.c`, `nonlinearSolverHomotopy.c`, `nonlinearSolverHybrd.c`
//! and `nonlinearSolverNewton.c`, with `kinsolSolver.c` / `kinsol_b.c` in
//! [`kinsol`], `newton_diagnostics.c` in [`newton_diagnostics`] and the
//! `-nlsJacTest` / `LOG_NLS_SVD` reports in [`jacobian_analysis`].
//!
//! [`solve_nls`] holds all of it with nothing about either host left in it: it
//! reaches the model through [`NlsModel`], [`NlsState`], [`NlsPersistent`] and
//! [`NlsBackend`]. The wasm-jit runtime supplies those over
//! `__indirect_function_table` indices and linear-memory addresses;
//! `openmodelica_simulation_runtime` supplies them over `NONLINEAR_SYSTEM_DATA`.
//!
//! What the two hosts do differently beyond the model is in [`host`]: how a model
//! error leaves the run, and where a solver's side file is written.
//!
//! Everything here is OpenModelica's own runtime. The upstream numerics stay in the
//! crates that own them -- `minpack`, `openmodelica_lapack`, and the SUNDIALS/KLU
//! archives [`kinsol`] binds -- and are only called from here.
//!
//! `no_std` + `alloc` by default, as `openmodelica_solvers` is, so the in-wasm
//! runtime and a host build share one compilation.

#![cfg_attr(not(feature = "std"), no_std)]

extern crate alloc;

#[cfg(sundials)]
pub mod jacobian_analysis;
pub mod kinsol;
pub mod newton_diagnostics;
#[cfg(test)]
mod nls_c_trace;

use openmodelica_solvers::format_g;
use openmodelica_solvers::omclog;
use openmodelica_solvers::{counters, solverflags, sysstat};

use alloc::vec;

use counters::{
    stat_inc, STAT_NEWTON_IRREGULAR, STAT_NEWTON_JAC, STAT_NEWTON_LAMBDA, STAT_NEWTON_MAXITER,
    STAT_NEWTON_NEGSTEP, STAT_NEWTON_SINGULAR, STAT_NEWTON_STUCK, STAT_NLS_ACCEPT, STAT_NLS_FAIL,
    STAT_NLS_GUESS_HIT, STAT_NLS_ITER, STAT_NLS_JAC, STAT_NLS_NEWTON_FAIL, STAT_NLS_RES,
    STAT_NLS_RETRY, STAT_NLS_SOLVE, STAT_NLS_STALE, STAT_NLS_STORE_BACK, STAT_NLS_VARY_START,
};
use solverflags::Nls;
use core::cell::UnsafeCell;
use core::sync::atomic::{AtomicU32, Ordering};

/// The parts of a run that belong to the runtime around this solver: how a model
/// error ends the evaluation, and where a side file goes.
///
/// Each is a function pointer a host installs once. Unset, a model error is only
/// logged and the evaluation carries on with whatever value it had (which is what
/// a `cargo test` of the numeric paths wants), and a side file is dropped.
pub mod host {
    use core::sync::atomic::{AtomicUsize, Ordering};

    static TRAP: AtomicUsize = AtomicUsize::new(0);
    static NOTE_ERROR: AtomicUsize = AtomicUsize::new(0);
    static WRITE_FILE: AtomicUsize = AtomicUsize::new(0);
    static FILE_PREFIX: AtomicUsize = AtomicUsize::new(0);
    static VAR_NAMES: AtomicUsize = AtomicUsize::new(0);
    static NOTE_ERROR_FLAG: AtomicUsize = AtomicUsize::new(0);
    static GUESS_REQUEST: AtomicUsize = AtomicUsize::new(0);
    static GUESS_WRITE: AtomicUsize = AtomicUsize::new(0);

    /// End the run: a wasm trap, or a `longjmp` out of the model. Never returns
    /// where a host installed it.
    pub fn set_trap(f: fn() -> !) {
        TRAP.store(f as usize, Ordering::Relaxed);
    }

    /// C's `throwStreamPrint` outside a solver region: log the message and arm the
    /// unwind that follows to report as a model error rather than a crash.
    pub fn set_note_runtime_error(f: fn(&str)) {
        NOTE_ERROR.store(f as usize, Ordering::Relaxed);
    }

    /// C's `omc_fopen` beside the result: the homotopy path CSV and the like.
    pub fn set_write_file(f: fn(&str, &str)) {
        WRITE_FILE.store(f as usize, Ordering::Relaxed);
    }

    /// C's `modelData->modelFilePrefix`, which those files are named after.
    pub fn set_file_prefix(f: fn() -> &'static str) {
        FILE_PREFIX.store(f as usize, Ordering::Relaxed);
    }

    /// C's `modelInfoGetEquation(...).vars`: one system's iteration-variable names,
    /// looked up the first time a log line wants them. A host that ships the whole
    /// roster ahead of time (`set_var_names`) does not need this.
    pub fn set_var_names_lookup(f: fn(u32) -> alloc::vec::Vec<alloc::string::String>) {
        VAR_NAMES.store(f as usize, Ordering::Relaxed);
    }

    pub(super) fn var_names_lookup()
    -> Option<fn(u32) -> alloc::vec::Vec<alloc::string::String>> {
        let p = VAR_NAMES.load(Ordering::Relaxed);
        (p != 0).then(|| unsafe { core::mem::transmute(p) })
    }

    pub(super) fn trap() -> ! {
        let p = TRAP.load(Ordering::Relaxed);
        if p == 0 {
            panic!("a model error reached a runtime with no trap installed");
        }
        let f: fn() -> ! = unsafe { core::mem::transmute(p) };
        f()
    }

    /// C's `throwStreamPrint` without the log line: the message is already on the
    /// log, or C suppresses it (a nonlinear solver's, with `LOG_NLS` off). The run
    /// still ends on it.
    pub fn set_note_runtime_error_flag(f: fn()) {
        NOTE_ERROR_FLAG.store(f as usize, Ordering::Relaxed);
    }

    /// `-saveInitialGuess_system=<file.mat>,<nls index>` (C's
    /// `B_save_initial_guess_system`): the request for this system, as
    /// `(the name the flag gave, the name to open)`. One-shot -- C writes the file
    /// once and never comes back -- and only a host can serve it, since the state it
    /// writes is the run's model and `SimData`.
    pub fn set_initial_guess_request(f: fn(u32) -> Option<(alloc::string::String, alloc::string::String)>) {
        GUESS_REQUEST.store(f as usize, Ordering::Relaxed);
    }

    /// Write that file; the `Err` message is reported as C's is.
    pub fn set_initial_guess_writer(f: fn(&str) -> Result<(), alloc::string::String>) {
        GUESS_WRITE.store(f as usize, Ordering::Relaxed);
    }

    // Only the KINSOL path reaches these.
    #[cfg(sundials)]
    pub(super) fn note_runtime_error_flag() {
        let p = NOTE_ERROR_FLAG.load(Ordering::Relaxed);
        if p != 0 {
            let f: fn() = unsafe { core::mem::transmute(p) };
            f();
        }
    }

    // Only the KINSOL path reaches these.
    #[cfg(sundials)]
    pub(super) fn take_initial_guess_request(
        eq_index: u32,
    ) -> Option<(alloc::string::String, alloc::string::String)> {
        let p = GUESS_REQUEST.load(Ordering::Relaxed);
        if p == 0 {
            return None;
        }
        let f: fn(u32) -> Option<(alloc::string::String, alloc::string::String)> =
            unsafe { core::mem::transmute(p) };
        f(eq_index)
    }

    // Only the KINSOL path reaches these.
    #[cfg(sundials)]
    pub(super) fn write_initial_guess(file: &str) -> Result<(), alloc::string::String> {
        let p = GUESS_WRITE.load(Ordering::Relaxed);
        if p == 0 {
            return Err(alloc::string::String::from("this runtime cannot write a state file"));
        }
        let f: fn(&str) -> Result<(), alloc::string::String> = unsafe { core::mem::transmute(p) };
        f(file)
    }

    pub(super) fn note_runtime_error(msg: &str) {
        let p = NOTE_ERROR.load(Ordering::Relaxed);
        if p == 0 {
            openmodelica_solvers::omclog::error(openmodelica_solvers::omclog::STDOUT, false, msg);
            return;
        }
        let f: fn(&str) = unsafe { core::mem::transmute(p) };
        f(msg);
    }

    pub(super) fn write_file(name: &str, data: &str) {
        let p = WRITE_FILE.load(Ordering::Relaxed);
        if p != 0 {
            let f: fn(&str, &str) = unsafe { core::mem::transmute(p) };
            f(name, data);
        }
    }

    pub(super) fn file_prefix() -> &'static str {
        let p = FILE_PREFIX.load(Ordering::Relaxed);
        if p == 0 {
            return "";
        }
        let f: fn() -> &'static str = unsafe { core::mem::transmute(p) };
        f()
    }
}

/// C's `EVAL_CONTEXT` (`util/context.h`), set by the driver. `updateInitialGuessDB`
/// records only for `ODE`/`ALGEBRAIC`/`EVENTS`; a Jacobian assembly evaluates at
/// perturbed states. `ALGEBRAIC` is what C leaves standing outside a `setContext`
/// region, so output points and event updates do record.
pub const CONTEXT_ODE: u32 = 1;
pub const CONTEXT_ALGEBRAIC: u32 = 2;
pub const CONTEXT_EVENTS: u32 = 3;
pub const CONTEXT_JACOBIAN: u32 = 4;
pub const CONTEXT_SYM_JACOBIAN: u32 = 5;

/// What is fixed about one `SES_NONLINEAR` system for the duration of a solve.
pub struct NlsSpec<'a> {
    /// C's `nonlinsys->equationIndex`, which names the system in its messages.
    pub eq_index: u32,
    /// C's `nonlinsys->size`: the residual count, plus one for `__HOM_LAMBDA`
    /// where an adaptive homotopy carries it as an unknown.
    pub size: usize,
    pub time: f64,
    /// C's `strictTearingFunctionCall` is present, which is what marks the system
    /// as dynamic tearing's casual set.
    pub casual: bool,
    /// C's `nonlinsys->mixedSystem`.
    pub mixed: bool,
    /// C's `homotopySupport` and `homotopyMethod`.
    pub hom_support: bool,
    pub hom_method: u32,
    /// Nonzeros in the model's sparsity pattern; 0 ⇒ no pattern.
    pub nnz: u32,
    /// The codegen chose to solve this system sparsely, so [`NlsModel::jacobian`]
    /// fills `nnz` CSC values rather than a dense matrix.
    pub jac_csc: bool,
    /// The system's ordinal, which names its side files.
    pub sys_num: u32,
    /// C's per-iteration-variable `nominal`.
    pub nominal: &'a [f64],
    /// The `min`/`max` pairs a restart point is held inside.
    pub bounds: &'a [f64],
    /// `colptr[size+1] ++ rowidx[nnz] ++ colorCols[size]`; empty without a pattern.
    /// The colours are 0-based, unlike C's.
    pub pattern: &'a [u32],
    /// C's `analyticalJacobianColumn != NULL`.
    pub has_jacobian: bool,
}

impl NlsSpec<'_> {
    /// The pattern's `colorCols` tail; empty where the host emitted no colouring.
    fn colors(&self) -> &[u32] {
        let base = self.size + 1 + self.nnz as usize;
        self.pattern.get(base..base + self.size).unwrap_or(&[])
    }
}

/// The model side of one nonlinear system: C's `NONLINEAR_SYSTEM_DATA` function
/// pointers, or the wasm module's function table.
pub trait NlsModel {
    /// C's `getIterationVars`: the unknowns' current values (the warm start).
    fn load_guess(&mut self, x: &mut [f64]);
    /// C's `residualFunc`: write `x` back into the unknown slots, run the inner
    /// (torn) equations, evaluate the residuals into `r`. Where the system has a
    /// homotopy parameter, `x` carries it after the residual coordinates.
    fn residual(&mut self, x: &[f64], r: &mut [f64]);
    /// C's `analyticalJacobianColumn`, in the model's own layout: `nnz` CSC values
    /// under [`NlsSpec::jac_csc`], else a dense column-major matrix.
    fn jacobian(&mut self, x: &[f64], out: &mut [f64]);
    /// C's `strictTearingFunctionCall`: hand the component to the strict tearing set.
    fn strict_fallback(&mut self) -> bool;
}

/// The runtime state a solve moves as it runs. Kept apart from [`NlsModel`] so the
/// residual closure can hold the model while these still move.
pub trait NlsState {
    /// The relation-evaluation mode: 0 held, 1 event, 2 initialization.
    fn relation_mode(&self) -> u32;
    fn set_relation_mode(&mut self, mode: u32);
    /// C's `relations[]`; snapshotted to see a mixed system's discrete state settle.
    fn relations(&self, out: &mut [i32]);
    fn relation_count(&self) -> usize;
    /// C's `simulationInfo->lambda`.
    fn lambda(&self) -> f64;
    fn set_lambda(&mut self, v: f64);
    /// C's first-writer-wins failure flag, recording `eq_index + 1`.
    fn note_failure(&mut self, eq_index: u32);
}

/// One call into a [`NlsBackend`] solver.
pub struct NlsRequest<'a> {
    pub n: usize,
    /// The start point on entry, the solution on exit.
    pub x: &'a mut [f64],
    /// C's `xStart` (`discreteCall ? nlsx : nlsxExtrapolation`).
    pub guess: &'a [f64],
    /// The values the unknowns held on entry, which a retry restarts from.
    pub warm: &'a [f64],
    pub nominal: &'a [f64],
    /// C's `nlsxOld`, the newest stored solution at or before `time`.
    pub old_values: &'a [f64],
    pub eq_index: u32,
    pub time: f64,
    pub has_jacobian: bool,
    /// C's `colorCols`, 0-based; empty leaves every column its own colour.
    pub colors: &'a [u32],
    /// C's `nlsData->max`.
    pub max: &'a [f64],
}

/// The nonlinear solvers a runtime supplies beyond the core's own dense ladder:
/// KINSOL, and the sparse Newton over the model's CSC pattern. Both want the
/// runtime's own pattern buffers and cached handle, so they live with it.
///
/// A runtime that has neither says so through [`NlsBackend::has_sparse`] /
/// [`NlsBackend::has_kinsol`] and every system takes the dense ladder, whatever
/// its sparsity pattern says: the two are alternatives to that ladder, not stages
/// ahead of it, so a default that merely failed would fail the system.
pub trait NlsBackend {
    /// Whether [`NlsBackend::solve_sparse`] is a solver rather than the default.
    fn has_sparse(&self) -> bool {
        false
    }
    /// The same for [`NlsBackend::solve_kinsol_dense`].
    fn has_kinsol(&self) -> bool {
        false
    }
    /// Whether [`NlsBackend::solve_sparse`] also serves a system with no sparsity
    /// pattern -- C's `-nls=kinsol` there, where `initKinsolMemory` takes the dense
    /// linear solver.
    fn has_kinsol_dense(&self) -> bool {
        false
    }

    fn solve_sparse(
        &mut self,
        req: NlsRequest,
        load_guess: &mut dyn FnMut(&mut [f64]),
        eval: &mut dyn FnMut(&[f64], &mut [f64]),
        jac: &mut dyn FnMut(&[f64], &mut [f64]),
    ) -> bool {
        let _ = (req, load_guess, eval, jac);
        false
    }
    /// C's `-nls=experimental-kinsol` on a system with no sparsity pattern.
    fn solve_kinsol_dense(
        &mut self,
        req: NlsRequest,
        load_guess: &mut dyn FnMut(&mut [f64]),
        eval: &mut dyn FnMut(&[f64], &mut [f64]),
        jac: &mut dyn FnMut(&[f64], &mut [f64]),
    ) -> bool {
        let _ = (req, load_guess, eval, jac);
        false
    }
}

/// C's per-system solver data that outlives one call: the stored solutions
/// `getInitialGuess` extrapolates from, `solveHomotopy`'s residual scaling, and
/// `lastTimeSolved`.
pub struct NlsPersistent<'a> {
    pub history: &'a mut dyn History,
    pub res_scaling: &'a mut [f64],
    pub extrapolation: &'a mut [f64],
    pub last_solved: &'a mut f64,
}

static EVAL_CONTEXT: AtomicU32 = AtomicU32::new(CONTEXT_ALGEBRAIC);

/// Address of the evaluation context, so a driver marks a context with a store
/// rather than a call per evaluation.
pub fn eval_context_addr() -> usize {
    &EVAL_CONTEXT as *const AtomicU32 as usize
}

pub fn set_eval_context(c: u32) {
    EVAL_CONTEXT.store(c, Ordering::Relaxed);
}

fn context_stores_guess() -> bool {
    matches!(
        EVAL_CONTEXT.load(Ordering::Relaxed),
        CONTEXT_ODE | CONTEXT_ALGEBRAIC | CONTEXT_EVENTS
    )
}

/// C's `simulationInfo->stepSize`, which bounds how far back [`solve_nls`] looks in
/// a system's solution history. Pushed in by the host, which has the model
/// description it comes from. 0 leaves the window empty.
static STEP_SIZE: core::sync::atomic::AtomicU64 = core::sync::atomic::AtomicU64::new(0);

/// C's `simulationInfo->stepSize`, pushed in by the driver that has it.
pub fn set_step_size(h: f64) {
    STEP_SIZE.store(h.to_bits(), Ordering::Relaxed);
}

fn step_size() -> f64 {
    f64::from_bits(STEP_SIZE.load(Ordering::Relaxed))
}

/// C's `threadData->currentErrorStage`, as two words the driver stores into: `[0]`
/// the stage, `[1]` set when a model error was absorbed there.
pub const ERROR_SIMULATION: u32 = 0;
pub const ERROR_INTEGRATOR: u32 = 1;
/// `solve_nonlinear_system`'s own region, which begins after C's `updateInnerEquation`.
pub const ERROR_NONLINEARSOLVER: u32 = 2;
/// C's `MMC_TRY_INTERNAL(simulationJumpBuffer)`, which the driver holds over one step.
pub const ERROR_SIMULATION_STEP: u32 = 3;
/// C's `handleEvents`: a model error there is not the step's to retry.
pub const ERROR_EVENTHANDLING: u32 = 4;
static ERROR_STAGE: [AtomicU32; 2] = [AtomicU32::new(ERROR_SIMULATION), AtomicU32::new(0)];

/// Address of [`ERROR_STAGE`], so a driver marks a region with a store rather than
/// a call per evaluation (as for [`eval_context_addr`]).
pub fn error_stage_addr() -> usize {
    ERROR_STAGE.as_ptr() as usize
}

pub fn error_stage() -> u32 {
    ERROR_STAGE[0].load(Ordering::Relaxed)
}

/// C's `saveJumpState`: the stage held over the solver region and put back after.
struct StageGuard(u32);

impl Drop for StageGuard {
    fn drop(&mut self) {
        ERROR_STAGE[0].store(self.0, Ordering::Relaxed);
    }
}

fn enter_nls_stage() -> StageGuard {
    let saved = ERROR_STAGE[0].swap(ERROR_NONLINEARSOLVER, Ordering::Relaxed);
    StageGuard(saved)
}

/// Recoverable-assert state (C's `ERROR_NONLINEARSOLVER`). While `NLS_DEPTH` > 0 a
/// failed model `assert()` records itself in `NLS_ASSERT_HIT` and returns instead of
/// trapping; `eval` then turns that trial into a huge residual so the solver backs off.
static NLS_DEPTH: AtomicU32 = AtomicU32::new(0);
static NLS_ASSERT_HIT: AtomicU32 = AtomicU32::new(0);
/// Outcome of the last *completed* evaluation, read after `eval` returns.
static NLS_EVAL_HIT: AtomicU32 = AtomicU32::new(0);
/// C's `assertCalled`, sticky over one solver attempt.
static NLS_ASSERT_SEEN: AtomicU32 = AtomicU32::new(0);
/// The same two, narrowed to a rejection the *model* caused. C's `residualFunc`
/// throws on a non-finite iteration variable as the guard below rejects one, but
/// only this target's linear algebra reaches that state (a rank-deficient Jacobian
/// steps to inf where C's does not), so reporting the guard as a model throw prints
/// C's assert block for solver states C never enters.
static NLS_EVAL_THREW: AtomicU32 = AtomicU32::new(0);
static NLS_THROW_SEEN: AtomicU32 = AtomicU32::new(0);

/// The residual a rejected trial reports; [`newton_c`] damps its step on it.
const ASSERT_RESIDUAL: f64 = 1e60;


/// Dynamic tearing: a violated `CONSTRAINT_DT` inside the casual set's residual,
/// which C's `f_con` reports by returning 1 — the emitted residual is a `void`
/// callback, so this flag stands in for that return. [`solve_nls`] clears it before
/// each evaluation and the sites C checks the return at read it back.
static DT_VIOLATED: AtomicU32 = AtomicU32::new(0);

/// Whether the last residual evaluation violated a local constraint of a casual
/// tearing set.
pub fn dt_violated() -> bool {
    DT_VIOLATED.load(Ordering::Relaxed) != 0
}

/// A host whose residual reports a violated local constraint by return value
/// rather than by calling [`dt_local_violated`] (C's `f_con`, whose generated form
/// returns 1) marks the evaluation here.
pub fn dt_note_violated() {
    DT_VIOLATED.store(1, Ordering::Relaxed);
}

fn dt_clear() {
    DT_VIOLATED.store(0, Ordering::Relaxed);
}

/// C's `createGlobalConstraints`, run before the casual set is solved: report the
/// constraint and let the caller fall back to the strict set.
pub fn dt_cons_violated(msg: &str, local: bool) {
    omclog::debug_string(
        omclog::DT_CONS,
        &alloc::format!(
            "The following {} constraint is violated:\n{msg}",
            if local { "local" } else { "global" }
        ),
    );
}

/// C's `createLocalConstraints`, run inside the casual set's residual: report the
/// constraint and fail this evaluation ([`DT_VIOLATED`] is `f_con`'s return 1).
pub fn dt_local_violated(msg: &str) {
    dt_cons_violated(msg, true);
    omclog::debug_string(
        omclog::DT,
        "Local constraints of the casual tearing set are violated! Let's fail...",
    );
    DT_VIOLATED.store(1, Ordering::Relaxed);
}

/// C's `equationLinear`/`equationNonlinear` entry line, and the casual-set variant
/// of it. `strict` is the strict set's equation index for a casual system, or -1
/// for a system solved on its own (which is every system without dynamic tearing).
pub fn dt_solving(index: i32, strict: i32, time: f64, linear: bool) {
    if !omclog::active(omclog::DT) {
        return;
    }
    let kind = if linear { "linear" } else { "nonlinear" };
    let what = if strict < 0 {
        alloc::string::String::from("(STRICT TEARING SET if tearing enabled)")
    } else {
        alloc::format!("(CASUAL TEARING SET, strict: {strict})")
    };
    omclog::info(
        omclog::DT,
        false,
        &alloc::format!(
            "Solving {kind} system {index} {what} at time = {}",
            format_g(time, 6)
        ),
    );
}

/// C's two `LOG_DT` lines that announce the strict set taking over: `cons` tells
/// the constraint check from the failed solve apart.
pub fn dt_fallback(cons: bool) {
    omclog::debug_string(
        omclog::DT,
        if cons {
            "Constraints of the casual tearing set are violated! Now the strict tearing set is used."
        } else {
            "Solving the casual tearing set failed! Now the strict tearing set is used."
        },
    );
}

/// C's `strictTearingFunctionCall`: hand the component to the strict tearing set
/// after the casual one failed.
fn dt_strict_fallback(model: &mut dyn NlsModel) -> bool {
    dt_fallback(false);
    model.strict_fallback()
}

/// Whether the last residual evaluation hit a recoverable model assert.
pub fn assert_hit() -> bool {
    NLS_EVAL_HIT.load(Ordering::Relaxed) != 0
}

/// The same for the last evaluation, and for the attempt: did the model throw?
fn eval_threw() -> bool {
    NLS_EVAL_THREW.load(Ordering::Relaxed) != 0
}

fn attempt_threw() -> bool {
    NLS_THROW_SEEN.load(Ordering::Relaxed) != 0
}

/// Take over the hit flag: a residual routinely runs a nested [`solve_nls`], whose
/// evaluations must not consume the enclosing one's.
fn enter_eval() -> u32 {
    NLS_DEPTH.fetch_add(1, Ordering::Relaxed);
    NLS_ASSERT_HIT.swap(0, Ordering::Relaxed)
}

/// Restore the enclosing evaluation's flag; reports this one's hit.
fn leave_eval(saved: u32) -> bool {
    NLS_DEPTH.fetch_sub(1, Ordering::Relaxed);
    let hit = NLS_ASSERT_HIT.swap(saved, Ordering::Relaxed) != 0;
    note_eval_hit(hit, hit);
    hit
}

pub fn note_eval_hit(hit: bool, threw: bool) {
    NLS_EVAL_HIT.store(hit as u32, Ordering::Relaxed);
    NLS_EVAL_THREW.store(threw as u32, Ordering::Relaxed);
    if hit {
        NLS_ASSERT_SEEN.store(1, Ordering::Relaxed);
    }
    if threw {
        NLS_THROW_SEEN.store(1, Ordering::Relaxed);
    }
}

/// Open C's `MMC_TRY_INTERNAL` around one solver attempt.
fn arm_attempt() {
    NLS_ASSERT_SEEN.store(0, Ordering::Relaxed);
    NLS_THROW_SEEN.store(0, Ordering::Relaxed);
}

/// The `abort` MINPACK polls. Without it the dogleg grinds against
/// [`ASSERT_RESIDUAL`] to `maxfev`, where C's `longjmp` leaves at once.
fn attempt_aborted() -> bool {
    NLS_ASSERT_SEEN.load(Ordering::Relaxed) != 0
}

/// Whether a `throwStreamPrint` model error unwinds into a catcher: the solver
/// regions plus the step region. A failed `assert()` asks [`rt_nls_recovering`]
/// alone -- `noThrowAsserts` suppresses it before any jump buffer sees it.
/// Model side: is a failed assert currently recoverable -- inside a nonlinear-solver
/// residual, or the integrator's? True ⇒ the model records the assert via
/// [`note_assert`] and bails out instead of ending the run.
pub fn recovering() -> bool {
    NLS_DEPTH.load(Ordering::Relaxed) > 0
        || matches!(error_stage(), ERROR_INTEGRATOR | ERROR_NONLINEARSOLVER)
}

/// Whether a `throwStreamPrint` model error unwinds into a catcher: the solver
/// regions plus the step region. A failed `assert()` asks [`recovering`]
/// alone -- `noThrowAsserts` suppresses it before any jump buffer sees it.
pub fn error_caught() -> bool {
    recovering() || error_stage() == ERROR_SIMULATION_STEP
}

/// Model side: flag that a recoverable assert fired at the current trial point.
pub fn note_assert() {
    note_slot().store(1, Ordering::Relaxed);
}

/// C's stage switch in `va_throwStreamPrint`, which unlike the assert one leaves
/// the integrator region ungated.
pub fn throw_logged() -> bool {
    ERROR_STAGE[0].load(Ordering::Relaxed) != ERROR_NONLINEARSOLVER
        || omclog::active(omclog::NLS)
}

/// Where [`rt_nls_note_assert`] records: the residual's own flag, or the
/// integrator region's when the model error is not inside a residual.
fn note_slot() -> &'static AtomicU32 {
    if NLS_DEPTH.load(Ordering::Relaxed) > 0 { &NLS_ASSERT_HIT } else { &ERROR_STAGE[1] }
}

/// A model error where C's generated code calls `throwStreamPrint` — an invalid
/// root, a zero divisor, an index out of range. C's `longjmp` lands in the innermost
/// `MMC_TRY_INTERNAL`, so inside a residual note the trial and let the caller return
/// a dummy the solver discards. With neither stage open the error is fatal.
pub fn model_error() {
    if error_caught() {
        note_assert();
        return;
    }
    host::trap()
}

/// Whether the next [`throw_stream`] reports, for a caller with its own message.
pub fn throw_reports() -> bool {
    !(error_caught() && note_slot().load(Ordering::Relaxed) != 0)
}

pub fn throw_stream(s: &str) {
    let recovering = error_caught();
    // C's `longjmp` leaves the rest of the evaluation unreached, so it reports one
    // throw per evaluation. Here each frame returns and the ones above it carry on:
    // report only the throw C's jump would have carried out.
    if throw_reports() {
        if !recovering {
            // Also arms the trap below to report as an assertion, not a crash.
            host::note_runtime_error(s);
        } else if throw_logged() {
            omclog::debug(omclog::ASSERT, false, s);
        }
    }
    if !recovering {
        host::trap()
    }
    note_assert();
}

/// C's `noThrowDivZero`, which is *sticky*: `solve_linear_system` and
/// `solve_nonlinear_system` both raise it, but only the end of a nonlinear solve
/// (and `initializeModel`) lowers it again — so a model whose algebraic systems
/// are all linear tolerates every division by zero after its first solve.
/// `runOptimizer` holds it over the whole optimization, hence the exported address.
static NO_THROW_DIV_ZERO: AtomicU32 = AtomicU32::new(0);

/// Address of C's `noThrowDivZero`, which `runOptimizer` holds over the whole
/// optimization.
pub fn no_throw_div_zero_addr() -> usize {
    (&NO_THROW_DIV_ZERO) as *const AtomicU32 as usize
}

pub fn set_no_throw_div_zero(on: bool) {
    NO_THROW_DIV_ZERO.store(on as u32, Ordering::Relaxed);
}

pub fn no_throw_div_zero() -> bool {
    NLS_DEPTH.load(Ordering::Relaxed) > 0 || NO_THROW_DIV_ZERO.load(Ordering::Relaxed) != 0
}

/// sqrt(DBL_EPSILON): the classic forward-difference relative step.
const SQRT_EPS: f64 = 1.4901161193847656e-08;
/// `sqrt(DBL_EPSILON*2e1)`, the step `getNumericalJacobianHomotopy` uses. 4.5×
/// `SQRT_EPS`: too small a step costs Newton iterations to FD noise.
const FD_DELTA: f64 = 6.664001874625056e-08;
/// Newton/LM convergence tolerance: stop once a residual / step measure drops below.
const NEWTON_EPS: f64 = 1.0e-6;
/// C's `newtonFTol`/`newtonXTol` (nonlinearSolverHomotopy.c), which `-newtonFTol` /
/// `-newtonXTol` move. `newton_solve` mirrors C's residual-gated convergence: a
/// step-stall counts as success only when the residual is also small
/// (`< ftol*1e3`), else it fails so the homotopy globaliser engages instead of
/// accepting a non-root.
fn newton_ftol() -> f64 {
    solverflags::newton_ftol()
}
fn newton_xtol() -> f64 {
    solverflags::newton_xtol()
}
const MAX_ITER: i32 = 100;
/// Line-search damping floor (2^-10): below this, keep the small step and let the
/// outer iteration retry (or hit the iteration limit → recoverable failure).
pub const LAMBDA_MIN: f64 = 9.765625e-4;

/// Euclidean norm (C's `enorm_`). NaN propagates, so a diverged residual falls
/// through every `< eps` test to the iteration-limit failure.
pub fn enorm(v: &[f64]) -> f64 {
    let mut s = 0.0;
    for &x in v {
        s += x * x;
    }
    libm::sqrt(s)
}

/// Solve the dense `n`×`n` system `A x = b` in place (`A` column-major, `b ← x`).
/// Returns `true` on success, `false` on a singular/failed factorization (in
/// which case `b` is unchanged). Shared by [`newton_solve`] and `rt_linsolve`.
pub fn lu_solve(a: &[f64], b: &mut [f64], n: usize) -> bool {
    lu_solve_singular_pivot(a, b, n).is_none()
}

/// [`lu_solve`] also reporting C's `detJac`: `dgesv` leaves the factors in `A`, and
/// `linearSolverWrapper` reads their diagonal, so the permutation's sign is not in it.
pub fn lu_solve_det(a: &[f64], b: &mut [f64], n: usize) -> Option<f64> {
    let mut lu = a[..n * n].to_vec();
    let mut ipiv = alloc::vec![0i32; n];
    if openmodelica_lapack::dgetrf(n, n, &mut lu, n, &mut ipiv) != 0 {
        return None;
    }
    openmodelica_lapack::dgetrs("N", n, 1, &lu, n, &ipiv, b, n);
    Some((0..n).map(|k| lu[k * n + k]).product())
}

/// [`lu_solve`] reporting `dgesv`'s `info`: `None` on success, else the 0-based
/// index of the first zero pivot, straight from `dgetrf`. `A` is copied because
/// `dgetrf` factors in place and the caller keeps it for the total-pivot fallback.
pub fn lu_solve_singular_pivot(a: &[f64], b: &mut [f64], n: usize) -> Option<usize> {
    let mut lu = a[..n * n].to_vec();
    let mut ipiv = alloc::vec![0i32; n];
    let info = openmodelica_lapack::dgetrf(n, n, &mut lu, n, &mut ipiv);
    if info != 0 {
        return Some((info.max(1) - 1) as usize);
    }
    openmodelica_lapack::dgetrs("N", n, 1, &lu, n, &ipiv, b, n);
    None
}

/// Total-pivot fallback for a singular / rank-deficient `A x = b`, a port of C's
/// `solveSystemWithTotalPivotSearchLS`. Returns `true` (with `b ← x`) for a
/// consistent system, picking the same particular solution C does; `false` only
/// when the system is inconsistent. `A` is column-major `n`×`n`.
pub fn total_pivot_solve(a: &[f64], b: &mut [f64], n: usize) -> bool {
    let m = n + 1;
    // Ab: n×(n+1) column-major; first n columns are A, the last is -b.
    let mut ab = vec![0.0f64; n * m];
    ab[..n * n].copy_from_slice(&a[..n * n]);
    for i in 0..n {
        ab[n * n + i] = -b[i];
    }
    let mut ind_row: alloc::vec::Vec<usize> = (0..n).collect();
    let mut ind_col: alloc::vec::Vec<usize> = (0..m).collect();
    let mut rank = n;

    for i in 0..n {
        let mut abs_max = ab[ind_row[i] + ind_col[i] * n].abs();
        let (mut p_row, mut p_col) = (i, i);
        for r in i..n {
            for c in i..n {
                let v = ab[ind_row[r] + ind_col[c] * n].abs();
                if v > abs_max {
                    abs_max = v;
                    p_row = r;
                    p_col = c;
                }
            }
        }
        if abs_max < f64::EPSILON {
            rank = i;
            break;
        }
        ind_row.swap(i, p_row);
        ind_col.swap(i, p_col);
        let piv = ab[ind_row[i] + ind_col[i] * n];
        for k in (i + 1)..n {
            let h = -ab[ind_row[k] + ind_col[i] * n] / piv;
            for j in (i + 1)..m {
                ab[ind_row[k] + ind_col[j] * n] += h * ab[ind_row[i] + ind_col[j] * n];
            }
            ab[ind_row[k] + ind_col[i] * n] = 0.0;
        }
    }

    let mut x = vec![0.0f64; m];
    for i in (0..n).rev() {
        if i >= rank {
            if ab[ind_row[i] + n * n].abs() > 1e-12 {
                return false;
            }
            x[ind_col[i]] = 0.0;
        } else {
            let mut xi = -ab[ind_row[i] + n * n];
            for j in ((i + 1)..n).rev() {
                xi -= ab[ind_row[i] + ind_col[j] * n] * x[ind_col[j]];
            }
            x[ind_col[i]] = xi / ab[ind_row[i] + ind_col[i] * n];
        }
    }
    b.copy_from_slice(&x[..n]);
    true
}

/// Over-determined total-pivot linear solver, C's `solveSystemWithTotalPivotSearch`
/// (`nonlinearSolverHomotopy.c`). `a` is an `n×(n+1)` column-major matrix
/// (`a[row + col*n]`); the last column is the right-hand side. With `pos < 0` it
/// solves the homogeneous `n×(n+1)` system for the null vector (tangent), setting
/// the freest coordinate to 1 and returning its index in `pos`. With `pos >= 0`
/// that coordinate is fixed (its column treated as the RHS). Writes the length
/// `n+1` solution into `x`. Returns `0` on success, `-1` if under-determined.
fn total_pivot_augmented(n: usize, x: &mut [f64], a: &mut [f64], pos: &mut i32, casual: bool) -> i32 {
    let m = n + 1;
    omclog::debug_matrix_double(omclog::NLS_JAC, "Linear System Matrix [Jac res]:", a, n, m);
    omclog::debug_vector_double(omclog::NLS_JAC, "vector b:", &a[n * n..n * n + n]);
    let mut n_pivot = n;
    let mut rank = n;
    let mut ind_row: alloc::vec::Vec<usize> = (0..n).collect();
    let mut ind_col: alloc::vec::Vec<usize> = (0..m).collect();
    if *pos >= 0 {
        let p = *pos as usize;
        ind_col[n] = p;
        ind_col[p] = n;
    } else {
        n_pivot = n + 1;
    }
    for i in 0..n {
        // Total pivot over rows [i,n) and columns [i,n_pivot).
        let mut abs_max = a[ind_row[i] + ind_col[i] * n].abs();
        let (mut p_row, mut p_col) = (i, i);
        for r in i..n {
            for c in i..n_pivot {
                let v = a[ind_row[r] + ind_col[c] * n].abs();
                if v > abs_max {
                    abs_max = v;
                    p_row = r;
                    p_col = c;
                }
            }
        }
        if abs_max < f64::EPSILON {
            rank = i;
            omclog::debug_int(omclog::NLS_V, "rank = ", rank as i32);
            omclog::debug_int(omclog::NLS_V, "position = ", *pos);
            break;
        }
        ind_row.swap(i, p_row);
        ind_col.swap(i, p_col);
        let piv = a[ind_row[i] + ind_col[i] * n];
        for k in (i + 1)..n {
            let h = -a[ind_row[k] + ind_col[i] * n] / piv;
            for j in (i + 1)..m {
                a[ind_row[k] + ind_col[j] * n] += h * a[ind_row[i] + ind_col[j] * n];
            }
            a[ind_row[k] + ind_col[i] * n] = 0.0;
        }
    }
    let mut det = 1.0;
    for k in 0..n {
        det *= a[ind_row[k] + ind_col[k] * n];
    }
    omclog::debug_double(omclog::NLS_JAC, "Determinant = ", det);
    if det.is_nan() {
        return -1;
    }
    // C notes a casual tearing set whose Jacobian is on the way to singular, but
    // steps on it anyway: `newtonAlgorithm` only gives up on `-1`.
    if casual && libm::fabs(det) < 1e-9 {
        omclog::debug_string(
            omclog::DT,
            "The determinant of the casual tearing set is vanishing, let's fail if this is not the solution...",
        );
    }
    for i in (0..n).rev() {
        if i >= rank {
            if a[ind_row[i] + ind_col[n] * n].abs() > 1e-6 {
                return -1;
            }
            x[ind_col[i]] = 0.0;
        } else {
            let mut xi = -a[ind_row[i] + ind_col[n] * n];
            for j in ((i + 1)..n).rev() {
                xi -= a[ind_row[i] + ind_col[j] * n] * x[ind_col[j]];
            }
            x[ind_col[i]] = xi / a[ind_row[i] + ind_col[i] * n];
        }
    }
    x[ind_col[n]] = 1.0;
    if omclog::active(omclog::NLS_V) {
        let as_i32 = |v: &[usize]| v.iter().map(|i| *i as i32).collect::<alloc::vec::Vec<i32>>();
        omclog::debug_vector_int(omclog::NLS_V, "indRow:", &as_i32(&ind_row));
        omclog::debug_vector_int(omclog::NLS_V, "indCol:", &as_i32(&ind_col));
        omclog::debug_vector_double(omclog::NLS_V, "vector x (solution):", x);
    }
    if *pos < 0 {
        *pos = ind_col[n] as i32;
        omclog::debug_int(omclog::NLS_V, "position of largest value = ", *pos);
    }
    0
}

/// Row-equilibrate an `n×(n+1)` matrix (C's `scaleMatrixRows`): divide each row by
/// the max magnitude over its first `n` columns (the Jacobian part), 1 if all zero.
fn scale_matrix_rows_aug(n: usize, a: &mut [f64]) {
    let m = n + 1;
    let mut rows_max = vec![0.0f64; n];
    for j in 0..n {
        for i in 0..n {
            let v = a[i + j * n].abs();
            if v > rows_max[i] {
                rows_max[i] = v;
            }
        }
    }
    for r in rows_max.iter_mut() {
        if *r <= 0.0 {
            *r = 1.0;
        }
    }
    for j in 0..m {
        for i in 0..n {
            a[i + j * n] /= rows_max[i];
        }
    }
}

/// Why a homotopy run stopped, so the init arm can print the message C prints.
enum HomFail {
    /// C's `iter >= maxTries` with tau already at `tauMin`.
    TauStuck,
    /// C's `iter >= maxTries` with tries left to shrink tau.
    MaxTries(i32),
    /// C's `y0[n] < -1`: the path turned away from lambda = 1.
    LambdaNegative(f64),
    /// C's `numSteps >= maxLambdaSteps`.
    MaxLambdaSteps(usize),
    /// C's singular `solveSystemWithTotalPivotSearch` on the tangent.
    Singular,
    /// C's "increment zero": the corrector step vanished against the predictor.
    IncrementZero,
    /// C's predictor `assert` with tau no longer shrinkable.
    PredictorTau(f64),
}

impl HomFail {
    /// The `LOG_ASSERT` text C's `initHomotopy` arm prints.
    fn message(&self) -> alloc::string::String {
        const MORE: &str = "You can use -lv=LOG_INIT_HOMOTOPY,LOG_NLS_HOMOTOPY to get more information.";
        const NEWTON_TAIL: &str = "You can also try to allow more newton steps in the corrector step with:\n\t\
             -homMaxNewtonSteps=<value>\nor change the tolerance for the solution with:\n\t\
             -homHEps=<value>\nYou can also try to use another backtrace stategy in the corrector step \
             with:\n\t-homBacktraceStrategy=<fix|orthogonal>\n";
        const TAU_TAIL: &str = "\t-homTauDecFac=<value>\n\t-homTauDecFacPredictor=<value>\n\t\
             -homTauIncFac=<value>\n\t-homTauIncThreshold=<value>\n\t-homTauMax=<value>\n\t\
             -homTauMin=<value>\n\t-homTauStart=<value>\n";
        let head = "Homotopy algorithm did not converge.\n";
        match self {
            HomFail::TauStuck => alloc::format!(
                "{head}No solution for current step size tau found and tau cannot be decreased any \
                 further.\nYou can set the minimum step size tau with:\n\t-homTauMin=<value>\n\
                 {NEWTON_TAIL}{MORE}"
            ),
            HomFail::MaxTries(iter) => alloc::format!(
                "{head}The maximum number of tries for one lambda is reached ({iter}).\nYou can \
                 change the number of tries with:\n\t-homMaxTries=<value>\n{NEWTON_TAIL}{MORE}"
            ),
            HomFail::LambdaNegative(l) => {
                alloc::format!("{head}lambda is smaller than -1: lambda={}\n{MORE}", fmt_g6(*l))
            }
            HomFail::MaxLambdaSteps(n) => alloc::format!(
                "{head}The maximum number of lambda steps is reached ({n}).\nYou can change the \
                 maximum number of lambda steps with:\n\t-homMaxLambdaSteps=<value>\nYou can also \
                 try to influence the step size tau with the following flags:\n{TAU_TAIL}or you can \
                 also set the threshold for accepting the current bending with:\n\t\
                 -homAdaptBend=<value>\nYou can also try to use another backtrace stategy in the \
                 corrector step with:\n\t-homBacktraceStrategy=<fix|orthogonal>\n{MORE}"
            ),
            HomFail::Singular => alloc::format!("{head}The system is singular and not solvable.\n{MORE}"),
            HomFail::IncrementZero => alloc::format!(
                "{head}The value specifying the bending of the homotopy curve is smaller than \
                 DBL_EPSILON (increment zero).\n{MORE}"
            ),
            HomFail::PredictorTau(tau) => alloc::format!(
                "{head}The step size tau cannot be decreased anymore and current tau={} already \
                 failed.\nYou can influence the calculation of tau with the following flags:\n\
                 {TAU_TAIL}You can also set the threshold for accepting the current bending with:\n\t\
                 -homAdaptBend=<value>\n{MORE}",
                fmt_g6(*tau)
            ),
        }
    }
}

/// C's adaptive-homotopy path CSV (`_nonlinsys<k>_adaptive_<local|global>_homotopy_<pos|neg>.csv`),
/// written only for an initial-homotopy run under `LOG_INIT_HOMOTOPY`.
struct HomExport {
    name: alloc::string::String,
    /// The system's iteration-variable names, for the header.
    vars: alloc::vec::Vec<alloc::string::String>,
}

/// The homotopy `H(y)` a continuation tracks, `y = [x, λ]` with `m = n+1` entries:
/// C's `h_function` / `hJac_dh` pair, in its two variants.
trait Homotopy {
    /// `H(y)` into `hvec` (`n` residuals).
    fn h(&mut self, y: &[f64], hvec: &mut [f64]);
    /// The `n×m` Jacobian at `y`, column-scaled by `xScaling`, given `H(y)` as the
    /// finite-difference base.
    fn jac(&mut self, y: &[f64], hbase: &[f64], out: &mut [f64]);
}

/// C's `getNumericalJacobianHomotopy`: forward differences over the first `n_cols`
/// coordinates of `y`, scaled by `xScaling[j]`; `max_value` flips the step's sign.
fn fd_homotopy_jacobian(
    hom: &mut impl Homotopy,
    n: usize,
    n_cols: usize,
    y: &[f64],
    hbase: &[f64],
    xscaling: &[f64],
    max_value: Option<&[f64]>,
    out: &mut [f64],
) {
    let delta_h = libm::sqrt(f64::EPSILON * 20.0);
    let mut yp = y.to_vec();
    let mut f2 = vec![0.0f64; n];
    for j in 0..n_cols {
        let ysave = yp[j];
        let mut hh = delta_h * (libm::fabs(ysave) + 1.0);
        if max_value.is_some_and(|mx| ysave + hh >= mx[j]) {
            hh = -hh;
        }
        yp[j] = ysave + hh;
        let inv = xscaling[j] / hh;
        hom.h(&yp, &mut f2);
        for i in 0..n {
            out[i + j * n] = (f2[i] - hbase[i]) * inv;
        }
        yp[j] = ysave;
    }
}

/// C's `wrapper_fvec_homotopy_newton`: `H(y) = F(x) − (1−λ)·F(x0)`, whose λ column
/// is the constant `F(x0)`.
struct NewtonHom<'a, 'b> {
    n: usize,
    fx0: alloc::vec::Vec<f64>,
    fx: alloc::vec::Vec<f64>,
    xscaling: &'a [f64],
    eval: &'a mut (dyn FnMut(&[f64], &mut [f64]) + 'b),
}

impl Homotopy for NewtonHom<'_, '_> {
    fn h(&mut self, y: &[f64], hvec: &mut [f64]) {
        (self.eval)(&y[..self.n], &mut self.fx);
        let lam = y[self.n];
        for i in 0..self.n {
            hvec[i] = self.fx[i] - (1.0 - lam) * self.fx0[i];
        }
    }
    fn jac(&mut self, y: &[f64], hbase: &[f64], out: &mut [f64]) {
        let (n, xs) = (self.n, self.xscaling);
        let xs: alloc::vec::Vec<f64> = xs.to_vec();
        fd_homotopy_jacobian(self, n, n, y, hbase, &xs, None, out);
        out[n * n..].copy_from_slice(&self.fx0);
    }
}

/// C's `initHomotopy`: `H(y)` is the model's own residual with `λ = y[n]` driving
/// its `homotopy()` calls, so the λ column is one more Jacobian column.
struct InitHom<'a, 'b> {
    n: usize,
    xscaling: &'a [f64],
    max_value: Option<&'a [f64]>,
    /// `y` (`m` entries) -> residual (`n` entries), the model's `residualFunc`.
    eval: &'a mut (dyn FnMut(&[f64], &mut [f64]) + 'b),
    /// The symbolic `n×m` Jacobian, unscaled, or `None` for finite differences.
    jac: Option<&'a mut (dyn FnMut(&[f64], &mut [f64]) + 'b)>,
}

impl Homotopy for InitHom<'_, '_> {
    fn h(&mut self, y: &[f64], hvec: &mut [f64]) {
        (self.eval)(y, hvec);
    }
    fn jac(&mut self, y: &[f64], hbase: &[f64], out: &mut [f64]) {
        let (n, m) = (self.n, self.n + 1);
        if let Some(j) = self.jac.as_mut() {
            j(y, out);
            // C's `getAnalyticalJacobianHomotopy` scales each column by `xScaling[j]`.
            for c in 0..m {
                for r in 0..n {
                    out[r + c * n] *= self.xscaling[c];
                }
            }
            return;
        }
        let xs: alloc::vec::Vec<f64> = self.xscaling.to_vec();
        let mx: Option<alloc::vec::Vec<f64>> = self.max_value.map(|v| v.to_vec());
        fd_homotopy_jacobian(self, n, m, y, hbase, &xs, mx.as_deref(), out);
    }
}

/// Arc-length homotopy continuation, a port of C's `homotopyAlgorithm`
/// (`nonlinearSolverHomotopy.c`): `H(y)`, `y = [x, λ]`, tracked λ: 0→1 by a tangent
/// predictor + fixed-coordinate Newton corrector with adaptive step `tau`. Follows
/// folds a fixed-λ homotopy can't. `y` carries the start `x` in and the λ=1 root
/// out; `Ok(steps)` is C's `numSteps`.
fn homotopy_algorithm(
    n: usize,
    y: &mut [f64],
    xscaling: &[f64],
    start_dir: f64,
    log: omclog::Stream,
    export: Option<HomExport>,
    hom: &mut impl Homotopy,
) -> core::result::Result<usize, HomFail> {
    let t = solverflags::hom_tuning();
    let m = n + 1;
    let max_newton = t.max_newton_steps as usize;
    let max_tries = t.max_tries as i32;
    // C's `homMaxLambdaSteps ? … : maxNumberOfIterations` (the solver's `size*100`).
    let max_lambda_steps = if t.max_lambda_steps > 0 { t.max_lambda_steps as usize } else { n * 100 };
    let mut tau = t.tau_start;

    let mut y0 = vec![0.0f64; m];
    y0[..n].copy_from_slice(&y[..n]);
    let mut prev_tangent = vec![0.0f64; m];
    prev_tangent[m - 1] = start_dir;

    let mut hvec = vec![0.0f64; n];
    hom.h(&y0, &mut hvec);

    // C's `pFile`: header (`"lambda"` then the unknowns) and the start row.
    let mut csv = export.map(|e| {
        omclog::info(
            omclog::INIT_HOMOTOPY,
            false,
            &alloc::format!("The homotopy path will be exported to {}.", e.name),
        );
        let mut s = alloc::string::String::from("\"sep=,\"\n\"lambda\"");
        // C names the `n` residual coordinates; lambda has its own column.
        for v in e.vars.iter().take(n) {
            s.push_str(&alloc::format!(",\"{v}\""));
        }
        s.push_str("\n0.0");
        for v in &y0[..n] {
            s.push(',');
            s.push_str(&omclog::g(*v, 0, 16));
        }
        s.push('\n');
        (e.name, s)
    });

    let mut iter: i32 = 0;
    let mut num_steps = 0usize;
    let mut initial_step = true;
    let mut tangent = vec![0.0f64; m]; // dy0
    let mut hjac = vec![0.0f64; n * m];
    let mut y1 = vec![0.0f64; m];
    let mut yt = vec![0.0f64; m];
    let mut dy1 = vec![0.0f64; m];
    let mut res_scaling = vec![1.0f64; n];
    let mut hvec_scaled = vec![0.0f64; n];
    let mut pre_tau = tau;
    let mut tangent_pos: i32 = -1;

    while y0[n] < 1.0 {
        omclog::info(log, false, &alloc::format!("homotopy parameter lambda = {}", fmt_g6(y0[n])));
        if iter >= max_tries {
            return Err(if pre_tau == tau { HomFail::TauStuck } else { HomFail::MaxTries(iter) });
        }
        if y0[n] < -1.0 {
            return Err(HomFail::LambdaNegative(y0[n]));
        }
        if num_steps >= max_lambda_steps {
            return Err(HomFail::MaxLambdaSteps(max_lambda_steps));
        }

        // ---- Predictor: tangent vector (only after an accepted step) ----
        if iter == 0 {
            hom.jac(&y0, &hvec, &mut hjac);
            scale_matrix_rows_aug(n, &mut hjac);
            tangent_pos = -1;
            if total_pivot_augmented(n, &mut tangent, &mut hjac, &mut tangent_pos, false) == -1 {
                return Err(HomFail::Singular);
            }
            for i in 0..m {
                tangent[i] *= xscaling[i];
            }
            // Direction: keep an acute angle with the previous tangent.
            let mut dot = 0.0;
            for i in 0..m {
                dot += tangent[i] * prev_tangent[i];
            }
            if dot < 0.0 || (libm::fabs(dot) < f64::EPSILON && start_dir == -1.0 && initial_step) {
                for v in tangent.iter_mut() {
                    *v = -*v;
                }
            }
            // Cap tau so λ + tau·dλ ≤ 1.
            if libm::fabs(tangent[n]) > 1e-8 {
                tau = tau.min((1.0 - y0[n]) / libm::fabs(tangent[n]));
            }
        }

        // Predictor point y1 = y0 + tau·tangent (shrink tau on a function assert).
        let mut assert_ok = false;
        loop {
            for i in 0..m {
                y1[i] = y0[i] + tau * tangent[i];
            }
            hom.h(&y1, &mut hvec);
            if hvec.iter().all(|v| libm::fabs(*v) < ASSERT_RESIDUAL) {
                assert_ok = true;
                break;
            }
            tau /= t.tau_dec_pred;
            if tau <= t.tau_min {
                break;
            }
        }
        if !assert_ok {
            return Err(HomFail::PredictorTau(tau));
        }
        yt.copy_from_slice(&y1);

        // ---- Corrector: Newton with coordinate `pos` fixed ----
        let last_step = y1[n] >= 1.0;
        let h_eps = if last_step { newton_ftol() } else { t.h_eps };
        let mut pos = if last_step { n as i32 } else { tangent_pos };
        let mut step_accept = false;
        let mut corrector_ok = true;
        hvec_scaled.copy_from_slice(&hvec); // C: hvecScaled starts as hvec (unscaled)
        for _ in 0..max_newton {
            if enorm(&hvec) < h_eps || enorm(&hvec_scaled) < h_eps {
                step_accept = true;
                break;
            }
            hom.jac(&y1, &hvec, &mut hjac);
            // resScaling[i] = row abs-sum of the homotopy Jacobian (before fixing pos).
            for i in 0..n {
                let mut s = 0.0;
                for j in 0..m {
                    s += libm::fabs(hjac[i + j * n]);
                }
                res_scaling[i] = if s > 0.0 { s } else { 1.0 };
            }
            // Fix coordinate `pos`: put the residual into its column, then solve.
            let pc = pos as usize;
            for i in 0..n {
                hjac[i + pc * n] = hvec[i];
            }
            scale_matrix_rows_aug(n, &mut hjac);
            if total_pivot_augmented(n, &mut dy1, &mut hjac, &mut pos, false) == -1 {
                corrector_ok = false;
                break;
            }
            dy1[pc] = 0.0;
            for i in 0..m {
                dy1[i] *= xscaling[i];
                y1[i] += dy1[i];
            }
            hom.h(&y1, &mut hvec);
            if hvec.iter().any(|v| libm::fabs(*v) >= ASSERT_RESIDUAL) {
                corrector_ok = false;
                break;
            }
            for i in 0..n {
                hvec_scaled[i] = hvec[i] / res_scaling[i];
            }
        }

        // ---- Step acceptance and adaptive tau via path bending ----
        let mut bend = 0.0;
        if corrector_ok {
            let mut corr = 0.0;
            let mut pred = 0.0;
            for i in 0..m {
                let c = y1[i] - yt[i];
                let p = yt[i] - y0[i];
                corr += c * c;
                pred += p * p;
            }
            let pred = libm::sqrt(pred);
            bend = if pred > 0.0 { libm::sqrt(corr) / pred } else { f64::INFINITY };
        }

        if bend > t.adapt_bend || !step_accept {
            if corrector_ok && bend < f64::EPSILON {
                return Err(HomFail::IncrementZero);
            }
            pre_tau = tau;
            tau = t.tau_min.max(tau / t.tau_dec);
            if tau == pre_tau {
                iter = max_tries;
            } else {
                iter += 1;
            }
        } else {
            initial_step = false;
            iter = 0;
            num_steps += 1;
            if bend < t.adapt_bend / t.tau_inc_threshold {
                tau = t.tau_max.min(tau * t.tau_inc);
            }
            y0.copy_from_slice(&y1);
            prev_tangent.copy_from_slice(&tangent);
            if let Some((_, s)) = csv.as_mut() {
                s.push_str(&omclog::g(y0[n], 0, 16));
                for v in &y0[..n] {
                    s.push(',');
                    s.push_str(&omclog::g(*v, 0, 16));
                }
                s.push('\n');
            }
        }
    }
    omclog::info(log, false, &alloc::format!("homotopy parameter lambda = {}", fmt_g6(y0[n])));
    if let Some((name, s)) = csv {
        host::write_file(&name, &s);
    }
    y.copy_from_slice(&y1);
    Ok(num_steps)
}

/// C's `!initHomotopy` runs: the Newton homotopy over `F`, from the regular start
/// point the perturbation search below finds. `x` = guess in / λ=1 root out.
/// C's `wrapper_fvec_homotopy_fixpoint`: `H(y) = λ·F(x) + (1−λ)·(x − x0)`.
struct FixpointHom<'a, 'b> {
    n: usize,
    x0: alloc::vec::Vec<f64>,
    fx: alloc::vec::Vec<f64>,
    xscaling: &'a [f64],
    eval: &'a mut (dyn FnMut(&[f64], &mut [f64]) + 'b),
}

impl Homotopy for FixpointHom<'_, '_> {
    fn h(&mut self, y: &[f64], hvec: &mut [f64]) {
        (self.eval)(&y[..self.n], &mut self.fx);
        let lam = y[self.n];
        for i in 0..self.n {
            hvec[i] = lam * self.fx[i] + (1.0 - lam) * (y[i] - self.x0[i]);
        }
    }
    fn jac(&mut self, y: &[f64], _hbase: &[f64], out: &mut [f64]) {
        let n = self.n;
        let xs: alloc::vec::Vec<f64> = self.xscaling.to_vec();
        let mut fbase = vec![0.0f64; n];
        (self.eval)(&y[..n], &mut fbase);
        let mut plain = PlainF { n, eval: self.eval };
        fd_homotopy_jacobian(&mut plain, n, n, y, &fbase, &xs, None, out);
        let lam = y[n];
        for j in 0..n {
            for i in 0..n {
                out[i + j * n] *= lam;
            }
            // Unscaled, as C adds it.
            out[j + j * n] += 1.0 - lam;
        }
        for i in 0..n {
            out[i + n * n] = fbase[i] - (y[i] - self.x0[i]);
        }
    }
}

struct PlainF<'a, 'b> {
    n: usize,
    eval: &'a mut (dyn FnMut(&[f64], &mut [f64]) + 'b),
}

impl Homotopy for PlainF<'_, '_> {
    fn h(&mut self, y: &[f64], hvec: &mut [f64]) {
        (self.eval)(&y[..self.n], hvec);
    }
    fn jac(&mut self, _y: &[f64], _hbase: &[f64], _out: &mut [f64]) {
        unreachable!("PlainF only evaluates")
    }
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum HomVariant {
    Newton,
    Fixpoint,
}

fn homotopy_solve(
    n: usize,
    x: &mut [f64],
    nominal: &[f64],
    start_dir: f64,
    variant: HomVariant,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    let m = n + 1;
    // xScaling[i] = max(nominal[i], |xStart[i]|) from the original start values.
    let mut xscaling = vec![0.0f64; m];
    for i in 0..n {
        xscaling[i] = libm::fabs(nominal[i]).max(libm::fabs(x[i]));
        if xscaling[i] <= 0.0 {
            xscaling[i] = 1.0;
        }
    }
    xscaling[m - 1] = 1.0;

    // Regular-initial-point search (C solveHomotopy): the raw start may sit on a
    // singularity, where the path is pathological. Perturb x0 by
    // xScaling·(i/n)·{0, 1%, 10%} until f(x0) is finite and moderate.
    let xstart = x[..n].to_vec();
    let mut x0v = xstart.clone();
    let mut fx0 = vec![0.0f64; n];
    for tries in 0..=2 {
        let pert = match tries {
            1 => 0.01,
            2 => 0.10,
            _ => 0.0,
        };
        for i in 0..n {
            x0v[i] = xstart[i] + xscaling[i] * (i as f64 / n as f64) * pert;
        }
        eval(&x0v, &mut fx0);
        if fx0.iter().all(|v| v.is_finite() && libm::fabs(*v) < 1e6) {
            break;
        }
    }

    let mut y = vec![0.0f64; m];
    y[..n].copy_from_slice(&x0v);
    let ok = match variant {
        HomVariant::Newton => {
            let mut hom = NewtonHom { n, fx0, fx: vec![0.0f64; n], xscaling: &xscaling, eval };
            homotopy_algorithm(n, &mut y, &xscaling, start_dir, omclog::NLS_HOMOTOPY, None, &mut hom).is_ok()
        }
        HomVariant::Fixpoint => {
            let mut hom = FixpointHom { n, x0: x0v.clone(), fx: vec![0.0f64; n], xscaling: &xscaling, eval };
            homotopy_algorithm(n, &mut y, &xscaling, start_dir, omclog::NLS_HOMOTOPY, None, &mut hom).is_ok()
        }
    };
    if ok {
        x[..n].copy_from_slice(&y[..n]);
    }
    ok
}

/// C's `solveHomotopy` with `initHomotopy`: continue the component along its own
/// lambda from 0, the opposing start direction being the second and last try. `x`
/// holds `n` unknowns plus the lambda slot. Returns C's `homotopySteps` share.
fn init_homotopy_solve<'e>(
    n: usize,
    x: &mut [f64],
    nominal: &[f64],
    bounds: &[f64],
    export: Option<(u32, bool, alloc::vec::Vec<alloc::string::String>)>,
    eval: &mut (dyn FnMut(&[f64], &mut [f64]) + 'e),
    mut jac: Option<&mut (dyn FnMut(&[f64], &mut [f64]) + 'e)>,
) -> Option<usize> {
    let m = n + 1;
    let mut xscaling = vec![0.0f64; m];
    for i in 0..n {
        xscaling[i] = libm::fabs(nominal[i]).max(libm::fabs(x[i]));
    }
    xscaling[m - 1] = 1.0;
    // C's `nlsData->max`, the FD sign-flip bound; lambda's own is unbounded.
    let mut max_value = vec![f64::MAX; m];
    for i in 0..n {
        max_value[i] = bounds[2 * i + 1];
    }
    let x0 = x[..n].to_vec();
    let neg = solverflags::hom_tuning().neg_start_dir;
    // C's `runHomotopy` 1 and 2: the second try reverses the start direction.
    for run in 1..=2 {
        let dir = if (run == 1) != neg { 1.0 } else { -1.0 };
        if run == 2 {
            omclog::info(
                omclog::ASSERT,
                false,
                "The homotopy algorithm is started again with opposing start direction.",
            );
        }
        omclog::debug_int(omclog::INIT_HOMOTOPY, "Homotopy run: ", run);
        omclog::debug_double(
            omclog::INIT_HOMOTOPY,
            if run == 1 { "startDirection = " } else { "Try again with startDirection = " },
            dir,
        );
        let mut y = vec![0.0f64; m];
        y[..n].copy_from_slice(&x0);
        // C's `_nonlinsys<k>_adaptive_<local|global>_homotopy_<pos|neg>.csv`.
        let hom_export = export.as_ref().map(|(sys_num, global, vars)| HomExport {
            name: alloc::format!(
                "{}_nonlinsys{sys_num}_adaptive_{}_homotopy_{}.csv",
                host::file_prefix(),
                if *global { "global" } else { "local" },
                if dir > 0.0 { "pos" } else { "neg" }
            ),
            vars: vars.clone(),
        });
        let r = {
            let mut hom = InitHom {
                n,
                xscaling: &xscaling,
                max_value: Some(&max_value),
                eval,
                jac: jac.as_deref_mut(),
            };
            homotopy_algorithm(n, &mut y, &xscaling, dir, omclog::INIT_HOMOTOPY, hom_export, &mut hom)
        };
        match r {
            Ok(steps) => {
                x[..m].copy_from_slice(&y);
                omclog::debug_int(
                    omclog::INIT_HOMOTOPY,
                    "Total number of lambda steps for this homotopy loop:",
                    steps as i32,
                );
                return Some(steps);
            }
            Err(e) => omclog::warning(omclog::ASSERT, false, &e.message()),
        }
    }
    None
}

/// Newton's method with a forward-difference Jacobian and a damped (line-search)
/// step, faithful to the C runtime's `_omc_newton` (`newtonIteration.c`). `x` is
/// the entry guess in / solution out; `eval(x, r)` writes the residual `r = f(x)`.
///
/// Convergence mirrors C exactly: the iteration continues only while *all* of the
/// residual norm (`error_f`), scaled residual norm (`scaledError_f`), step norm
/// (`delta_x`), residual-change (`delta_f`), and scaled step (`delta_x_scaled`)
/// stay above `NEWTON_EPS`; it succeeds as soon as *any* drops below. This is what
/// lets a system converge when a finite-difference Jacobian floors the residual
/// above a pure `‖r‖` tolerance but the Newton step has otherwise stalled at the
/// solution. Returns `false` on a singular Jacobian or `MAX_ITER` overrun. On
/// return `x` holds the last iterate.
pub fn newton_solve(
    n: usize,
    x: &mut [f64],
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    let mut fvec = vec![0.0f64; n];
    let mut f_old = vec![0.0f64; n];
    let mut x_new = vec![0.0f64; n];
    let mut rp = vec![0.0f64; n];
    let mut dx = vec![0.0f64; n];
    let mut jac = vec![0.0f64; n * n]; // column-major

    eval(x, &mut fvec);
    let mut error_f = enorm(&fvec);
    if error_f < newton_ftol() {
        return true;
    }
    f_old.copy_from_slice(&fvec);

    let mut iter = 0;
    let mut neg_steps = 0i32; // C's countNegativeSteps
    let mut small_steps = 0i32; // C's numberOfSmallSteps
    loop {
        // Jacobian columns by forward differences: J[:,col] = (f(x+h e_col) - f(x)) / h.
        for col in 0..n {
            let h = SQRT_EPS * (x[col].abs() + 1.0);
            let saved = x[col];
            x[col] = saved + h;
            eval(x, &mut rp);
            for i in 0..n {
                jac[col * n + i] = (rp[i] - fvec[i]) / h;
            }
            x[col] = saved;
        }

        // Solve J dx = fvec; x_new = x - dx (C's `x_new = x - x_increment`).
        dx.copy_from_slice(&fvec);
        if !lu_solve(&jac, &mut dx, n) {
            return false;
        }
        for i in 0..n {
            x_new[i] = x[i] - dx[i];
        }

        // Damped step: halve lambda until the residual norm improves (C damping).
        eval(&x_new, &mut fvec);
        let mut lambda = 1.0;
        while enorm(&fvec) >= error_f && lambda > LAMBDA_MIN {
            lambda *= 0.5;
            for i in 0..n {
                x_new[i] = x[i] - lambda * dx[i];
            }
            eval(&x_new, &mut fvec);
        }

        // calculatingErrors: step, residual, and their scaled variants.
        let mut d2 = 0.0;
        for i in 0..n {
            let d = x[i] - x_new[i];
            d2 += d * d;
        }
        let delta_x = libm::sqrt(d2);
        let xn = enorm(x);
        let scale = if xn > 1.0 { xn } else { 1.0 };
        let delta_x_scaled = delta_x / scale;
        let error_f_old = error_f;
        error_f = enorm(&fvec);
        // scaledError_f = ‖ fvec / resScaling ‖, resScaling[i] = max-norm of Jac row i.
        let mut se2 = 0.0;
        for i in 0..n {
            let mut row_max = 0.0f64;
            for col in 0..n {
                let a = jac[col * n + i].abs();
                if a > row_max {
                    row_max = a;
                }
            }
            let s = if row_max > 0.0 && row_max.is_finite() {
                row_max
            } else if row_max == 0.0 {
                1e-16
            } else {
                1.0
            };
            let v = fvec[i] / s;
            se2 += v * v;
        }
        let scaled_error_f = libm::sqrt(se2);

        x.copy_from_slice(&x_new);
        f_old.copy_from_slice(&fvec);

        // C's newtonAlgorithm convergence (nonlinearSolverHomotopy.c): residual-gated.
        // A vanishing step alone is NOT success — the residual must also be small,
        // else the solver reports failure so the homotopy globaliser engages instead
        // of accepting a non-root (the ThreeSprings spring-loop stall).
        neg_steps += (error_f > 10.0 * error_f_old) as i32;
        if neg_steps > 20 {
            return false;
        }
        let (ftol, xtol) = (newton_ftol(), newton_xtol());
        let f_small = error_f < ftol || scaled_error_f < ftol;
        let x_small = delta_x < xtol || delta_x_scaled < xtol;
        if f_small && x_small {
            return true;
        }
        small_steps += (delta_x < xtol * 100.0 || delta_x_scaled < xtol * 100.0) as i32;
        if x_small || small_steps > 20 {
            // Stalled step: accept only with a small residual (C's ftol*1e3), else fail.
            return error_f < ftol * 1.0e3 || scaled_error_f < ftol * 1.0e3;
        }
        iter += 1;
        if iter > MAX_ITER {
            return false;
        }
    }
}

/// Levenberg–Marquardt globaliser with a forward-difference Jacobian, tried when
/// the damped Newton step stalls (a stand-in for C's hybrd / homotopy init
/// solver). It solves the Marquardt-damped normal equations
/// `(JᵀJ + λ·diag JᵀJ) dx = -Jᵀf`, adapting `λ` by whether a step reduces the
/// residual, so it converges to the same root from a poorer guess (e.g.
/// `DoublePendulumInitTip`'s initialisation). Returns `false` if the residual
/// cannot be driven below tolerance.
pub fn lm_solve(
    n: usize,
    x: &mut [f64],
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    let mut f = vec![0.0f64; n];
    let mut f_new = vec![0.0f64; n];
    let mut jac = vec![0.0f64; n * n]; // column-major
    let mut jtj = vec![0.0f64; n * n];
    let mut g = vec![0.0f64; n]; // Jᵀf
    let mut dx = vec![0.0f64; n];
    let mut x_new = vec![0.0f64; n];

    eval(x, &mut f);
    let mut nf = enorm(&f);
    if nf < NEWTON_EPS {
        return true;
    }
    let mut lambda = 1.0e-3;
    let mut iter = 0;
    loop {
        for col in 0..n {
            let h = SQRT_EPS * (x[col].abs() + 1.0);
            let saved = x[col];
            x[col] = saved + h;
            eval(x, &mut f_new);
            for i in 0..n {
                jac[col * n + i] = (f_new[i] - f[i]) / h;
            }
            x[col] = saved;
        }
        for a in 0..n {
            for b in a..n {
                let mut s = 0.0;
                for i in 0..n {
                    s += jac[a * n + i] * jac[b * n + i];
                }
                jtj[a * n + b] = s;
                jtj[b * n + a] = s;
            }
            let mut s = 0.0;
            for i in 0..n {
                s += jac[a * n + i] * f[i];
            }
            g[a] = s;
        }

        let mut accepted = false;
        for _ in 0..30 {
            let mut m = jtj.clone();
            for d in 0..n {
                let diag = jtj[d * n + d];
                m[d * n + d] = diag + lambda * if diag > 1e-12 { diag } else { 1e-12 };
            }
            for i in 0..n {
                dx[i] = -g[i];
            }
            if !lu_solve(&m, &mut dx, n) {
                lambda *= 10.0;
                if lambda > 1e14 {
                    break;
                }
                continue;
            }
            for i in 0..n {
                x_new[i] = x[i] + dx[i];
            }
            eval(&x_new, &mut f_new);
            let nf_new = enorm(&f_new);
            if nf_new < nf {
                x.copy_from_slice(&x_new);
                f.copy_from_slice(&f_new);
                nf = nf_new;
                lambda *= 0.5;
                accepted = true;
                break;
            }
            lambda *= 2.0;
            if lambda > 1e14 {
                break;
            }
        }

        if nf < NEWTON_EPS {
            return true;
        }
        if !accepted {
            return false;
        }
        iter += 1;
        if iter > MAX_ITER {
            return false;
        }
    }
}

/// [`minpack::hybrd`] run in coordinates scaled by `max(|x[i]|, nominal[i])`, so
/// the relative `xtol` resolves every variable to its own magnitude.
fn hybrd_scaled(
    n: usize,
    x: &mut [f64],
    fvec: &mut [f64],
    nominal: &[f64],
    maxfev: usize,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    let mut scale = vec![0.0f64; n];
    for i in 0..n {
        let s = x[i].abs().max(nominal[i]);
        scale[i] = if s > 0.0 { s } else { 1.0 };
    }
    for i in 0..n {
        x[i] /= scale[i];
    }
    let mut real = vec![0.0f64; n];
    let mut seval = |sx: &[f64], r: &mut [f64]| {
        for i in 0..n {
            real[i] = sx[i] * scale[i];
        }
        eval(&real, r);
    };
    arm_attempt();
    let mut hooks =
        minpack::Hooks { abort: Some(&attempt_aborted), fjacobian: None, diag: None };
    minpack::hybrd_hooked(&mut seval, &mut hooks, n, x, fvec, 1e-12, maxfev, 1e-12, 100.0);
    drop(seval);
    for i in 0..n {
        x[i] *= scale[i];
    }
    nls_accept(fvec)
}

/// A solve succeeds only when the residual is at C's `local_tol`: MINPACK's
/// `info == 1` is a step test (the trust region collapsed), not a root.
fn nls_accept(fvec: &[f64]) -> bool {
    enorm(fvec) <= 1.0e-12
}

/// C's `resScaling` over the Jacobian `hybrd` last formed. C reads
/// `fjacobian[i*n + j]` for the whole slice `j`, so entry `i` is the max of *column*
/// `i`, not of residual `i`'s row.
fn hybrd_res_scaling(n: usize, fjac: &[f64], res_scaling: &mut [f64]) {
    for i in 0..n {
        let mut m = 1e-16f64;
        for v in &fjac[i * n..(i + 1) * n] {
            m = m.max(libm::fabs(*v));
        }
        res_scaling[i] = m;
    }
}

/// C's `solveHybrd` block for the first model assert that voids a solver attempt.
fn log_hybrd_assert(t: &HomotopyTrace) {
    use omclog;
    use alloc::string::String;
    let head = if t.initial {
        String::from("While solving non-linear system an assertion failed during initialization.")
    } else {
        alloc::format!(
            "While solving non-linear system an assertion failed at time {}.",
            format_g(t.time, 6)
        )
    };
    omclog::warning(omclog::STDOUT, true, &head);
    let tail = [
        "The non-linear solver tries to solve the problem that could take some time.",
        "It could help to provide better start-values for the iteration variables.",
    ];
    for line in tail {
        omclog::warning(omclog::STDOUT, false, line);
    }
    if !omclog::active(omclog::NLS_V) {
        omclog::warning(omclog::STDOUT, false, "For more information simulate with -lv LOG_NLS_V");
    }
    omclog::close_warning(omclog::STDOUT);
}

/// C's warning where a model assert fires in an evaluation made around a solver
/// attempt rather than in one: `solveHybrd`'s two and `updateInnerEquation`'s.
fn log_assert_handled() {
    omclog::warning(
        omclog::STDOUT,
        false,
        "Non-Linear Solver try to handle a problem with a called assert.",
    );
}

/// C's `solveHybrd` (nonlinearSolverHybrd.c): MINPACK `hybrd` over C's
/// forward-difference Jacobian, wrapped in the retry ladder C grinds through before
/// giving a system up. Every rung restarts the whole solve — the trust-region
/// `factor` cut tenfold three times, start-point variations, x-scaling dropped, the
/// solver's internal variable scaling replaced then disabled, and finally five
/// tenfold relaxations of the acceptance tolerance, each of which replays all the
/// earlier rungs. It is the last thing C tries, and reaching the far end of it is
/// what solves BranchingDynamicPipes' 79-unknown medium system at lambda = 1.
///
/// `x_start`, `warm` and `extrapolation` are C's `nlsx` (the point `solveHomotopy`
/// settled on), `nlsxOld` and `nlsxExtrapolation`; `x` holds the solution, or the
/// last iterate when every rung fails.
///
/// With a symbolic Jacobian C runs `hybrj` over it and hands it over unscaled even
/// while the unknowns are x-scaled (`wrapper_fvec_hybrj` never rescales the
/// analytic columns); the dogleg's path, and so the root, depends on that.
#[allow(clippy::too_many_arguments)]
fn hybrd_c(
    n: usize,
    x: &mut [f64],
    x_start: &[f64],
    warm: &[f64],
    extrapolation: &[f64],
    nominal: &[f64],
    bounds: &[f64],
    t: &HomotopyTrace,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    mut jac: Option<&mut dyn FnMut(&[f64], &mut [f64])>,
    set_continuous: &mut dyn FnMut(bool),
) -> bool {
    use omclog;
    let log_v = omclog::active(omclog::NLS_V);
    let names = var_names(t.eq_index);
    // C's `printVector`.
    let print_vector = |name: &str, v: &[f64]| {
        omclog::info(omclog::NLS_V, true, name);
        for (i, x) in v.iter().enumerate() {
            omclog::info(omclog::NLS_V, false, &alloc::format!("[{i:>2}] {}", omclog::g(*x, 20, 12)));
        }
        omclog::close(omclog::NLS_V);
    };
    let log_rung = |msg: &str| {
        if log_v {
            omclog::info(omclog::NLS_V, false, msg);
        }
    };
    if log_v {
        omclog::info(
            omclog::NLS_V,
            true,
            &alloc::format!(
                "Start solving Non-Linear System {} (size {n}) at time {} with Hybrd Solver",
                t.eq_index,
                fmt_g6(t.time)
            ),
        );
        for i in 0..n {
            let name = names.get(i).map_or("", |s| s.as_str());
            omclog::info(omclog::NLS_V, true, &alloc::format!("{}. {name} = {}", i + 1, omclog::f(x_start[i], 0, 6)));
            omclog::info(
                omclog::NLS_V,
                false,
                &alloc::format!(
                    "    nominal = {}\nold = {}\nextrapolated = {}",
                    omclog::f(nominal[i], 0, 6),
                    omclog::f(warm[i], 0, 6),
                    omclog::f(extrapolation[i], 0, 6)
                ),
            );
            omclog::close(omclog::NLS_V);
        }
        omclog::close(omclog::NLS_V);
    }
    const XTOL: f64 = 1.0e-12;
    /// C's `hybrdData->epsfcn`; `fdjac1` derives its step from it as C does.
    const EPSFCN: f64 = 1.0e-12;
    let maxfev = n * 10000;
    let initial_factor = 100.0f64;
    let discrete_call = t.discrete;

    let mut local_tol = 1.0e-12f64;
    let mut factor = initial_factor;
    let mut use_xscaling = true;
    let mut continuous = true;
    let mut non_continuous = false;
    // C's `mode == 2`: the solver's own variable scaling replaced by ours.
    let mut diag: Option<alloc::vec::Vec<f64>> = None;
    let (mut retries, mut retries2, mut retries3) = (0i32, 0i32, 0i32);
    let mut assert_retries = 0usize;
    let mut assert_called = false;
    // C's `assertMessage`: once per solve.
    let mut assert_message = false;

    // C's `nlsxOld`, which a clean run after an assert moves.
    let mut warm = warm.to_vec();
    // C's `nlsx`, which the assert rung lifts off zero and success overwrites.
    let mut nlsx = x_start.to_vec();
    let mut xv = nlsx.clone();
    let mut xscale = vec![1.0f64; n];
    let mut fvec = vec![0.0f64; n];
    let mut fjacobian = vec![0.0f64; n * n];
    let mut res_scaling = vec![1.0f64; n];
    let mut unscaled = vec![0.0f64; n];

    loop {
        // C's "constrain x": no attempt starts outside the declared range.
        for i in 0..n {
            xv[i] = xv[i].max(bounds[2 * i]).min(bounds[2 * i + 1]);
            xscale[i] = xv[i].abs().max(nominal[i]).max(1e-16);
        }
        if log_v {
            print_vector("scaling factors x vector", &xscale);
            print_vector("Iteration variable values", &xv);
        }
        if use_xscaling {
            for i in 0..n {
                xv[i] /= xscale[i];
            }
        }
        if log_v {
            print_vector("Iteration variable values (scaled)", &xv);
        }
        set_continuous(continuous);
        arm_attempt();
        let status = {
            let mut seval = |sx: &[f64], r: &mut [f64]| {
                for i in 0..n {
                    unscaled[i] = if use_xscaling { sx[i] * xscale[i] } else { sx[i] };
                }
                eval(&unscaled, r);
            };
            let mut hooks = minpack::Hooks {
                abort: Some(&attempt_aborted),
                fjacobian: Some(&mut fjacobian),
                diag: diag.as_deref(),
            };
            match jac.as_deref_mut() {
                Some(jac) => {
                    let mut unscaled_j = vec![0.0f64; n];
                    let mut sjac = |sx: &[f64], fj: &mut [f64]| {
                        for i in 0..n {
                            unscaled_j[i] = if use_xscaling { sx[i] * xscale[i] } else { sx[i] };
                        }
                        jac(&unscaled_j, fj);
                    };
                    minpack::hybrj_hooked(&mut seval, &mut sjac, &mut hooks, n, &mut xv, &mut fvec, XTOL, maxfev, factor)
                }
                None => minpack::hybrd_hooked(
                    &mut seval, &mut hooks, n, &mut xv, &mut fvec, XTOL, maxfev, EPSFCN, factor,
                ),
            }
        };
        if use_xscaling {
            for i in 0..n {
                xv[i] *= xscale[i];
            }
        }

        // An assert voids the attempt: C's `longjmp` lands here with both error
        // measures at 1, so no rung can mistake it for progress.
        let mut void_run = status == minpack::Status::Aborted;
        if void_run {
            if !assert_message && attempt_threw() {
                log_hybrd_assert(t);
                assert_message = true;
            }
            assert_called = true;
        } else {
            if assert_called {
                omclog::info(
                    omclog::NLS_V,
                    false,
                    "After assertions failed, found a solution for which assertions did not fail.",
                );
                warm.copy_from_slice(&xv);
            }
            assert_retries = 0;
            assert_called = false;
            if discrete_call {
                // Judge the point with the relations live, not held.
                set_continuous(false);
                arm_attempt();
                eval(&xv, &mut fvec);
                if attempt_aborted() {
                    if eval_threw() {
                        log_assert_handled();
                    }
                    void_run = true;
                    assert_called = true;
                }
            }
        }
        let (xerror, xerror_scaled) = if void_run {
            (1.0, 1.0)
        } else {
            hybrd_res_scaling(n, &fjacobian, &mut res_scaling);
            let mut scaled = vec![0.0f64; n];
            for i in 0..n {
                scaled[i] = fvec[i] * (1.0 / res_scaling[i]);
            }
            if log_v {
                omclog::info(omclog::NLS_V, true, "scaling factors for residual vector");
                for i in 0..n {
                    omclog::info(omclog::NLS_V, true, &alloc::format!("scaled residual [{i}] : {}", omclog::e(scaled[i], 0, 20)));
                    omclog::info(omclog::NLS_V, false, &alloc::format!("scaling factor [{i}] : {}", omclog::e(res_scaling[i], 0, 20)));
                    omclog::close(omclog::NLS_V);
                }
                omclog::close(omclog::NLS_V);
            }
            (minpack::enorm(&fvec), minpack::enorm(&scaled))
        };
        // C's `if (info < 4 && xerror > local_tol && xerror_scaled > local_tol) info = 4`:
        // only the residual decides, and a rejected run advances a rung.
        let accurate = xerror <= local_tol || xerror_scaled <= local_tol;
        if non_continuous && !accurate {
            non_continuous = false;
        }

        if accurate {
            nlsx.copy_from_slice(&xv);
            x.copy_from_slice(&xv);
            // C confirms the solution by evaluating there once more; an assert at it
            // rejects the point and retries from it without advancing a rung.
            arm_attempt();
            eval(&xv, &mut fvec);
            if !attempt_aborted() {
                if log_v {
                    omclog::info(omclog::NLS_V, true, "System solved");
                    omclog::info(omclog::NLS_V, false, &alloc::format!("{retries} retries\n{} restarts", retries2 + retries3));
                    omclog::close(omclog::NLS_V);
                }
                set_continuous(true);
                return true;
            }
            if eval_threw() {
                log_assert_handled();
            }
            assert_called = true;
            continue;
        }

        // C's `set x vector` for a restarting rung.
        let restart = |xv: &mut [f64], nlsx: &[f64]| {
            xv.copy_from_slice(if discrete_call { nlsx } else { x_start })
        };
        if assert_called && assert_retries < 1 + n {
            // The model asserted: lift collapsed unknowns to nominal, then nudge one
            // variable at a time by 1% of it.
            xv.copy_from_slice(&warm);
            if assert_retries == 0 {
                for i in 0..n {
                    if nlsx[i] == 0.0 {
                        nlsx[i] = nominal[i];
                        xv[i] = nominal[i];
                    }
                }
            } else {
                xv[assert_retries - 1] += 0.01 * nominal[assert_retries - 1];
            }
            assert_retries += 1;
            log_rung(&alloc::format!(" - try to handle a problem with a called assert vary initial value a bit. (Retry: {assert_retries})"));
        } else if retries < 3 {
            restart(&mut xv, &nlsx);
            factor /= 10.0;
            retries += 1;
            log_rung(&alloc::format!(" - iteration making no progress:\t decreasing initial step bound to {}.", omclog::f(factor, 0, 6)));
        } else if retries < 4 {
            for i in 0..n {
                xv[i] += nominal[i] * 0.1;
            }
            factor = initial_factor;
            retries += 1;
            log_rung("iteration making no progress:\t vary solution point by 1%.");
        } else if retries < 5 {
            // C's "try old values as x-scaling factors"; the constrain-x block above
            // overwrites them again, in C too, so this is a plain restart.
            restart(&mut xv, &nlsx);
            retries += 1;
            log_rung("iteration making no progress:\t try old values as scaling factors.");
        } else if retries < 6 {
            restart(&mut xv, &nlsx);
            use_xscaling = false;
            retries += 1;
            log_rung("iteration making no progress:\t try without scaling at all.");
        } else if retries < 7 && discrete_call {
            xv.copy_from_slice(&warm);
            continuous = false;
            non_continuous = true;
            retries += 1;
            log_rung(" - iteration making no progress:\t try to solve a discontinuous system.");
        } else if retries2 < 1 {
            xv.copy_from_slice(&warm);
            use_xscaling = true;
            continuous = true;
            factor = initial_factor;
            retries = 0;
            retries2 += 1;
            log_rung(" - iteration making no progress:\t use old values instead extrapolated.");
        } else if retries2 < 2 {
            restart(&mut xv, &nlsx);
            for v in xv.iter_mut() {
                *v *= 1.01;
            }
            retries = 0;
            retries2 += 1;
            log_rung(" - iteration making no progress:\t vary initial point by adding 1%.");
        } else if retries2 < 3 {
            restart(&mut xv, &nlsx);
            for v in xv.iter_mut() {
                *v *= 0.99;
            }
            retries = 0;
            retries2 += 1;
            log_rung(" - iteration making no progress:\t vary initial point by -1%.");
        } else if retries2 < 4 {
            xv.copy_from_slice(nominal);
            retries = 0;
            retries2 += 1;
            log_rung(" - iteration making no progress:\t try scaling factor as initial point.");
        } else if retries2 < 5 && !assert_called {
            restart(&mut xv, &nlsx);
            diag = Some(res_scaling.iter().map(|v| libm::fabs(*v).max(1e-16)).collect());
            retries = 0;
            retries2 += 1;
            log_rung(" - iteration making no progress:\t try with own scaling factors.");
        } else if retries3 < 1 {
            restart(&mut xv, &nlsx);
            diag = Some(vec![1.0f64; n]);
            use_xscaling = true;
            retries = 0;
            retries2 = 0;
            retries3 += 1;
            log_rung(" - iteration making no progress:\t disable solver internal scaling.");
        } else if retries3 < 6 {
            restart(&mut xv, &nlsx);
            local_tol *= 10.0;
            factor = initial_factor;
            diag = None;
            retries = 0;
            retries2 = 0;
            retries3 += 1;
            log_rung(&alloc::format!(" - iteration making no progress:\t reduce the tolerance slightly to {}.", omclog::e(local_tol, 0, 6)));
        } else {
            log_rung(&alloc::format!("### No Solution! ###\n after {} restarts", retries * retries2 * retries3));
            x.copy_from_slice(&xv);
            set_continuous(true);
            return false;
        }
    }
}

/// [`minpack::hybrj`] with the same scaling as [`hybrd_scaled`], using the model's
/// analytic Jacobian. Not on the ladder: the rungs that reach [`hybrd_scaled`] are
/// the ones past where C gives up, and they restart from a point the analytic
/// Jacobian has already failed at.
/// `jac(x, fjac)` fills the column-major `n×n` Jacobian `∂f_i/∂x_j` at the
/// unscaled `x`; column `j` is scaled by `scale[j]`.
#[allow(dead_code)]
#[allow(clippy::too_many_arguments)]
fn hybrj_scaled(
    n: usize,
    x: &mut [f64],
    fvec: &mut [f64],
    nominal: &[f64],
    maxfev: usize,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    jac: &mut dyn FnMut(&[f64], &mut [f64]),
) -> bool {
    let mut scale = vec![0.0f64; n];
    for i in 0..n {
        let s = x[i].abs().max(nominal[i]);
        scale[i] = if s > 0.0 { s } else { 1.0 };
    }
    for i in 0..n {
        x[i] /= scale[i];
    }
    let mut real = vec![0.0f64; n];
    let mut seval = |sx: &[f64], r: &mut [f64]| {
        for i in 0..n {
            real[i] = sx[i] * scale[i];
        }
        eval(&real, r);
    };
    let mut realj = vec![0.0f64; n];
    let mut sjac = |sx: &[f64], fj: &mut [f64]| {
        for i in 0..n {
            realj[i] = sx[i] * scale[i];
        }
        jac(&realj, fj);
        for j in 0..n {
            for i in 0..n {
                fj[i + j * n] *= scale[j];
            }
        }
    };
    arm_attempt();
    let mut hooks =
        minpack::Hooks { abort: Some(&attempt_aborted), fjacobian: None, diag: None };
    minpack::hybrj_hooked(&mut seval, &mut sjac, &mut hooks, n, x, fvec, 1e-12, maxfev, 100.0);
    drop(seval);
    drop(sjac);
    for i in 0..n {
        x[i] *= scale[i];
    }
    nls_accept(fvec)
}

/// Stored solutions per system; `nls_hist_bytes` in the codegen must agree. C's list
/// is unbounded and reaches 40+, but the entry `getValues` picks is never past 5.
pub const HIST_DEPTH: usize = 10;

/// C's `MINIMAL_STEP_SIZE` (`epsilon.h`): times within this count as the same time.
const MINIMAL_STEP_SIZE: f64 = 1.0e-12;

/// C's `LOCAL_EQUIDISTANT_HOMOTOPY`, the one method the sweep below serves.
const HOM_LOCAL_EQUIDISTANT: u32 = 0;
/// The two `HOMOTOPY_METHOD` values C hands to `solveWithInitHomotopy`.
pub const HOM_GLOBAL_ADAPTIVE: u32 = 2;
pub const HOM_LOCAL_ADAPTIVE: u32 = 3;

/// C's `%g`, the precision `infoStreamPrint` prints lambda with.
fn fmt_g6(v: f64) -> alloc::string::String {
    format_g(v, 6)
}

/// C's two openings of the local equidistant sweep.
/// C's opening of the local adaptive approach's lambda0 pre-solve.
fn log_local_adaptive_start(sys_num: u32) {
    let s = omclog::INIT_HOMOTOPY;
    omclog::info(
        s,
        false,
        &alloc::format!("Local homotopy with adaptive step size started for nonlinear system {sys_num}."),
    );
    omclog::info(s, true, "homotopy process\n---------------------------");
    omclog::info(s, false, "solve lambda0-system");
}

fn log_local_homotopy_start(sys_num: u32, wanted: bool) {
    let msg = if wanted {
        alloc::format!("Local homotopy with equidistant step size started for nonlinear system {sys_num}.")
    } else {
        alloc::format!(
            "Failed to solve the initial system {sys_num} without homotopy method. \
             The local homotopy method with equidistant step size is used now."
        )
    };
    if wanted {
        omclog::info(omclog::INIT_HOMOTOPY, false, &msg);
    } else {
        omclog::warning(omclog::ASSERT, false, &msg);
    }
}

/// Storage behind C's `oldValueList`. Each host keeps it its own way: the wasm
/// runtime in the per-system block the codegen reserved, the C one in a `Vec` beside
/// `NONLINEAR_SYSTEM_DATA`.
pub trait History {
    /// Entries currently stored, newest-stored first.
    fn len(&self) -> usize;
    fn time(&self, k: usize) -> f64;
    fn value(&self, k: usize, i: usize) -> f64;
    /// Copy entry `from` onto entry `to`.
    fn shift(&mut self, from: usize, to: usize);
    /// Overwrite entry `k` and set the count to `len`.
    fn put(&mut self, k: usize, len: usize, time: f64, x: &[f64]);
    fn set_len(&mut self, len: usize);
}

/// Which stored solutions C's `getValues` builds the guess from.
#[derive(Debug, PartialEq)]
pub struct Pick {
    /// The first entry at or older than the requested time; `None` = empty list.
    pub old: Option<usize>,
    /// The entry stored just before `old`, to extrapolate with.
    pub old2: Option<usize>,
    /// `old`'s time is the requested time: take it verbatim, no extrapolation.
    pub exact: bool,
}

/// `getValues`' search: the first entry at or older than `time`, or the oldest.
/// A hit within `MINIMAL_STEP_SIZE` is taken verbatim — `b+f*(a-b)` lands an ULP
/// away even at `f == 1`, which costs a Newton iteration on a linear residual.
pub fn history_pick(h: &dyn History, time: f64) -> Pick {
    for k in 0..h.len() {
        if libm::fabs(h.time(k) - time) <= MINIMAL_STEP_SIZE {
            return Pick { old: Some(k), old2: None, exact: true };
        }
        if h.time(k) < time {
            return Pick { old: Some(k), old2: (k + 1 < h.len()).then_some(k + 1), exact: false };
        }
    }
    Pick { old: h.len().checked_sub(1), old2: None, exact: false }
}

/// `getValues`' `oldOutput` (C's `nlsxOld`): the `old` entry verbatim.
pub fn history_old(h: &dyn History, pick: &Pick, out: &mut [f64]) {
    if let Some(a) = pick.old {
        for (i, v) in out.iter_mut().enumerate() {
            *v = h.value(a, i);
        }
    }
}

/// `extrapolateValues`; leaves `guess` alone when the list is empty.
pub fn history_guess(h: &dyn History, pick: &Pick, time: f64, guess: &mut [f64]) {
    match (pick.old, pick.old2) {
        (Some(a), Some(b)) => {
            let (t_a, t_b) = (h.time(a), h.time(b));
            let f = (time - t_b) / (t_a - t_b);
            for (i, g) in guess.iter_mut().enumerate() {
                let (va, vb) = (h.value(a, i), h.value(b, i));
                *g = if t_a == t_b || va == vb { va } else { vb + f * (va - vb) };
            }
        }
        (Some(a), None) => {
            for (i, g) in guess.iter_mut().enumerate() {
                *g = h.value(a, i);
            }
        }
        (None, _) => {}
    }
}

/// `addListElement`: push to the front, or replace it when the times match. Unlike
/// C's, the oldest entry falls off at [`HIST_DEPTH`].
pub fn history_store(h: &mut dyn History, time: f64, x: &[f64]) {
    let count = h.len();
    if count > 0 && libm::fabs(h.time(0) - time) <= MINIMAL_STEP_SIZE {
        h.put(0, count, time, x);
        return;
    }
    for k in (0..count.min(HIST_DEPTH - 1)).rev() {
        h.shift(k, k + 1);
    }
    h.put(0, (count + 1).min(HIST_DEPTH), time, x);
}

/// `cleanValueListbyTime`: keep only the newest entry at or before `time`.
pub fn history_clean(h: &mut dyn History, time: f64) {
    for k in 0..h.len() {
        if h.time(k) <= time {
            if k > 0 {
                h.shift(k, 0);
            }
            return h.set_len(1);
        }
    }
    h.set_len(0);
}

/// C's `NONLINEAR_SYSTEM_DATA::numberOf{Iterations,FEval,JEval}`: per system,
/// cumulative over the run, keyed by equation index.
struct CountersCell(UnsafeCell<alloc::vec::Vec<(u32, [u64; 3])>>);
unsafe impl Sync for CountersCell {}
static COUNTERS: CountersCell = CountersCell(UnsafeCell::new(alloc::vec::Vec::new()));

/// Nonzero while a Jacobian is being formed: C counts `numberOfFEval` in
/// `wrapper_fvec`, which the FD Jacobian does not go through.
static JAC_DEPTH: AtomicU32 = AtomicU32::new(0);

/// C's `numberOfJEval`: `wrapper_fvec_der` counts an analytic and an FD Jacobian
/// alike. [`solve_nls`] takes the difference over its own call.
static JAC_EVALS: core::sync::atomic::AtomicU64 = core::sync::atomic::AtomicU64::new(0);

fn note_jac_eval() {
    JAC_EVALS.fetch_add(1, Ordering::Relaxed);
}

/// C's `numberOfIterations`, `numberOfFEval` and `numberOfJEval` as run totals; a
/// solve's own share is the difference across it, less what a nested solve took.
fn sys_counts() -> [u64; 3] {
    [
        counters::stat(STAT_NLS_ITER),
        counters::stat(STAT_NLS_RES),
        JAC_EVALS.load(Ordering::Relaxed),
    ]
}

fn counters_of(eq_index: u32) -> &'static mut [u64; 3] {
    let v = unsafe { &mut *COUNTERS.0.get() };
    let pos = match v.iter().position(|(i, _)| *i == eq_index) {
        Some(p) => p,
        None => {
            v.push((eq_index, [0; 3]));
            v.len() - 1
        }
    };
    &mut v[pos].1
}

/// C's `modelInfoGetEquation(...).vars[i]`, keyed by `equationIndex`. Pushed in
/// from the decoded `SimMeta`, and only when the stream is on.
struct NamesCell(UnsafeCell<alloc::vec::Vec<(u32, alloc::vec::Vec<alloc::string::String>)>>);
unsafe impl Sync for NamesCell {}
static NAMES: NamesCell = NamesCell(UnsafeCell::new(alloc::vec::Vec::new()));

/// `eq_index`'s iteration-variable names, or `[]` when they were not pushed in.
pub fn var_names(eq_index: u32) -> &'static [alloc::string::String] {
    if let Some((_, v)) = unsafe { &*NAMES.0.get() }.iter().find(|(i, _)| *i == eq_index) {
        return v.as_slice();
    }
    // Not shipped ahead of time: ask the host, which reads the model's equation
    // metadata the first time a name is actually wanted -- C's own laziness, and
    // the reason a run with every log stream off never opens the file.
    let Some(f) = host::var_names_lookup() else { return &[] };
    push_var_names(eq_index, f(eq_index));
    var_names(eq_index)
}

/// C's `[%2ld] %30s  = ` prefix; the name column is empty for a system the blob
/// does not cover.
fn var_label(names: &[alloc::string::String], i: usize) -> alloc::string::String {
    let name = names.get(i).map(|s| s.as_str()).unwrap_or("");
    alloc::format!("[{:2}] {name:>30}  = ", i + 1)
}

/// Replace the name roster. `set` is `(eq_index, names)` in any order.
pub fn set_var_names(set: alloc::vec::Vec<(u32, alloc::vec::Vec<alloc::string::String>)>) {
    *unsafe { &mut *NAMES.0.get() } = set;
}

/// What `-lv=LOG_NLS_NEWTON_DIAGNOSTICS` needs per system beyond the names, keyed
/// by equation index; pushed in from the model's metadata.
struct DiagCell(UnsafeCell<alloc::vec::Vec<(u32, newton_diagnostics::DiagInfo)>>);
unsafe impl Sync for DiagCell {}
static DIAG: DiagCell = DiagCell(UnsafeCell::new(alloc::vec::Vec::new()));

/// Replace the `LOG_NLS_NEWTON_DIAGNOSTICS` roster. `set` is `(eq_index, info)`
/// in any order.
pub fn set_diag(set: alloc::vec::Vec<(u32, newton_diagnostics::DiagInfo)>) {
    *unsafe { &mut *DIAG.0.get() } = set;
}

/// Add one system to it, for a host that ships the roster a system at a time.
pub fn push_diag(eq_index: u32, info: newton_diagnostics::DiagInfo) {
    unsafe { &mut *DIAG.0.get() }.push((eq_index, info));
}

/// [`set_var_names`] one system at a time.
pub fn push_var_names(eq_index: u32, names: alloc::vec::Vec<alloc::string::String>) {
    unsafe { &mut *NAMES.0.get() }.push((eq_index, names));
}

/// The SimCode equation index of each residual, as the Newton-diagnostics roster
/// carries it. `LOG_NLS_SVD` names its rows by them.
pub fn diag_eqns(eq_index: u32) -> alloc::vec::Vec<u32> {
    diag_info(eq_index).map(|d| d.eqns.clone()).unwrap_or_default()
}

/// Empty the name roster and the iteration counters.
pub fn clear_names() {
    unsafe { &mut *NAMES.0.get() }.clear();
    unsafe { &mut *COUNTERS.0.get() }.clear();
}

/// Empty the diagnostics roster.
pub fn clear_diag() {
    unsafe { &mut *DIAG.0.get() }.clear();
}

fn diag_info(eq_index: u32) -> Option<&'static newton_diagnostics::DiagInfo> {
    unsafe { &*DIAG.0.get() }.iter().find(|(e, _)| *e == eq_index).map(|(_, d)| d)
}

/// C's `printNonLinearInitialInfo`, under the `solve_nonlinear_system` header.
fn log_nls_enter(eq_index: u32, time: f64, x: &[f64], nominal: &[f64]) {
    use omclog;
    omclog::info(
        omclog::NLS,
        true,
        &alloc::format!(
            "############ Solve nonlinear system {eq_index} at time {} ############",
            format_g(time, 6)
        ),
    );
    omclog::info(omclog::NLS, true, "initial variable values:");
    let names = var_names(eq_index);
    for i in 0..x.len() {
        omclog::info(
            omclog::NLS,
            false,
            &alloc::format!(
                "{}{}\t\t nom = {}",
                var_label(names, i),
                omclog::g(x[i], 16, 8),
                omclog::g(nominal[i], 16, 8)
            ),
        );
    }
    omclog::close(omclog::NLS);
}

/// C's `printNonLinearFinishInfo` plus the `messageClose` that ends the block
/// `log_nls_enter` opened.
fn log_nls_leave(eq_index: u32, solved: bool, x: &[f64]) {
    use omclog;
    let c = counters_of(eq_index);
    omclog::info(
        omclog::NLS,
        true,
        if solved { "Solution status: SOLVED" } else { "Solution status: FAILED" },
    );
    omclog::info(omclog::NLS, false, &alloc::format!(" number of iterations           : {}", c[0]));
    omclog::info(omclog::NLS, false, &alloc::format!(" number of function evaluations : {}", c[1]));
    omclog::info(omclog::NLS, false, &alloc::format!(" number of jacobian evaluations : {}", c[2]));
    omclog::info(omclog::NLS, false, "solution values:");
    let names = var_names(eq_index);
    for i in 0..x.len() {
        omclog::info(
            omclog::NLS,
            false,
            &alloc::format!("{}{}", var_label(names, i), omclog::g(x[i], 16, 8)),
        );
    }
    omclog::close(omclog::NLS);
    omclog::close(omclog::NLS);
}

/// Row abs-sum of `J` (`matVecMultAbsBB` + `vecMakeFinite`). A zero row stays 0,
/// which `scaled_sq` reads as unscaled, as C's `vecDivScaling` does.
fn row_scaling(n: usize, jac: &[f64], res_scaling: &mut [f64]) {
    for i in 0..n {
        let mut s = 0.0;
        for j in 0..n {
            s += jac[j * n + i].abs();
        }
        res_scaling[i] = if s.is_finite() { s } else { 1.0 };
    }
}

/// `‖v / resScaling‖²` (C's `vecDivScaling` + `vec2NormSqrd`).
fn scaled_sq(n: usize, v: &[f64], res_scaling: &[f64]) -> f64 {
    let mut s = 0.0;
    for i in 0..n {
        let d = res_scaling[i].abs();
        let t = if d > 0.0 { v[i] / d } else { v[i] };
        s += t * t;
    }
    s
}

/// Which system `newton_c` is solving, for C's `LOG_NLS_V` block. `None` where C runs
/// another solver (`-nls=newton`), which has its own trace.
struct HomotopyTrace {
    eq_index: u32,
    time: f64,
    /// C's `discreteCall`: "System values" rather than "System extrapolation".
    discrete: bool,
    /// C's `simulationInfo->initial`, which its warnings name instead of a time.
    initial: bool,
    /// Print the opening block; false for the later Newton runs.
    header: bool,
}

/// C's `solveHomotopy` header block, which opens the `LOG_NLS_V` block
/// [`solve_nls`] closes.
fn log_homotopy_enter(t: &HomotopyTrace, n: usize, x: &[f64], nominal: &[f64], xscaling: &[f64]) {
    use omclog;
    if !omclog::active(omclog::NLS_V) {
        return;
    }
    omclog::info(
        omclog::NLS_V,
        true,
        &alloc::format!(
            "Start solving Non-Linear System {} (size {n}) at time {} with Mixed (Newton/Homotopy) Solver",
            t.eq_index,
            format_g(t.time, 6)
        ),
    );
    let label = if t.discrete { "System values" } else { "System extrapolation" };
    omclog::debug_vector_double(omclog::NLS_V, label, x);
    omclog::debug_vector_double(omclog::NLS_V, "Nominal values", nominal);
    // C's `xScaling` element `n` is the homotopy parameter's own scaling.
    let mut scaling = xscaling.to_vec();
    scaling.push(1.0);
    omclog::debug_vector_double(omclog::NLS_V, "Scaling values", &scaling);
}

/// `newtonAlgorithm`'s block rule and its two verdicts, verbatim.
const BAR: &str = "******************************************************";
const NO_CONVERGE: &str = "NEWTON SOLVER DID ---NOT--- CONVERGE TO A SOLUTION!!!";
const UPS: &str = "UPS! MUST HANDLE A PROBLEM (Newton method), time : ";

/// C's `printUnknowns`. Its `nom` column is `xScaling`, not the `nominal` attribute.
fn log_nls_status(t: &HomotopyTrace, x: &[f64], xscaling: &[f64], bounds: &[f64]) {
    use omclog;
    if !omclog::active(omclog::NLS_V) {
        return;
    }
    let names = var_names(t.eq_index);
    omclog::info(omclog::NLS_V, true, "nls status");
    omclog::info(omclog::NLS_V, false, "variables");
    for i in 0..x.len() {
        omclog::info(
            omclog::NLS_V,
            false,
            &alloc::format!(
                "{}{}\t\t nom = {}\t\t min = {}\t\t max = {}",
                var_label(names, i),
                omclog::g(x[i], 16, 8),
                omclog::g(xscaling[i], 16, 8),
                omclog::g(bounds[2 * i], 16, 8),
                omclog::g(bounds[2 * i + 1], 16, 8)
            ),
        );
    }
    omclog::close(omclog::NLS_V);
}

/// C's `printNewtonStep`: the full Newton step and the iterate it leads to.
fn log_newton_step(t: &HomotopyTrace, x1: &[f64], step: &[f64], x: &[f64]) {
    use omclog;
    if !omclog::active(omclog::NLS_V) {
        return;
    }
    let names = var_names(t.eq_index);
    omclog::info(omclog::NLS_V, true, "newton step");
    omclog::info(omclog::NLS_V, false, "variables");
    for i in 0..x.len() {
        omclog::info(
            omclog::NLS_V,
            false,
            &alloc::format!(
                "{}{}\t\t step = {}\t\t old = {}",
                var_label(names, i),
                omclog::g(x1[i], 16, 8),
                omclog::g(step[i], 16, 8),
                omclog::g(x[i], 16, 8)
            ),
        );
    }
    omclog::close(omclog::NLS_V);
}

/// C's `solveHomotopy` entry phase and its `newtonAlgorithm`
/// (`nonlinearSolverHomotopy.c`): a start point already at tolerance is taken
/// outright, else the Jacobian formed there feeds a damped Newton with a
/// Numerical-Recipes cubic line search and two-tier residual-gated convergence.
/// Analytic Jacobian when `has_jac`, else FD; `x` = guess in / last iterate out.
/// Returns `(root found, last residual eval was at the returned `x`)`.
#[allow(clippy::too_many_arguments)]
fn newton_c(
    n: usize,
    x: &mut [f64],
    nominal: &[f64],
    bounds: &[f64],
    res_scaling: &mut [f64],
    x0: &mut [f64],
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    jaceval: &mut dyn FnMut(&[f64], &mut [f64]),
    has_jac: bool,
    trace: Option<&HomotopyTrace>,
    casual: bool,
) -> (bool, bool) {
    const ALPHA: f64 = 1.0e-1;
    const LAMBDA_MIN_C: f64 = 1.0e-4;
    let ftol_sq = newton_ftol() * newton_ftol();
    let xtol_sq = newton_xtol() * newton_xtol();
    // C's `vec2NormSqrd`: the plain sum of squares. Squaring [`enorm`] instead
    // rounds twice, and these measures decide the damping and the convergence test.
    let nsq = |v: &[f64]| -> f64 {
        let mut s = 0.0;
        for x in v {
            s += x * x;
        }
        s
    };

    // C's `xStart`: the retries below vary off this, not off the last varied point.
    let x_start = x.to_vec();
    let mut xscaling = vec![1.0f64; n];
    for i in 0..n {
        xscaling[i] = nominal[i].abs().max(x[i].abs());
        if xscaling[i] <= 0.0 {
            xscaling[i] = 1.0;
        }
    }

    if let Some(t) = trace.filter(|t| t.header) {
        log_homotopy_enter(t, n, x, nominal, &xscaling);
    }

    let mut fvec = vec![0.0f64; n];
    let mut x1 = vec![0.0f64; n];
    let mut rp = vec![0.0f64; n];
    let mut step = vec![0.0f64; n]; // C's dy0 (the full Newton step −J⁻¹f)
    let mut jac = vec![0.0f64; n * n];
    let mut aug = vec![0.0f64; n * (n + 1)]; // C's `fJac`, whose last column is `fvec`

    // The Jacobian is w.r.t. *scaled* unknowns: both of C's paths scale column `j` by
    // `xScaling[j]`, and the step is unscaled after the solve. `resScaling` is a row
    // abs-sum of that column-equilibrated matrix, so the scaling is part of the
    // convergence test, not just the rounding.
    //
    // The first one comes from C's `solveHomotopy` pre-phase and the loop re-forms it
    // at its *bottom*, so the iteration that converges never pays for a Jacobian.
    //
    // False when an assert fired while forming it: C ends the solve there rather
    // than stepping on a poisoned matrix.
    let form_jac = |x: &mut [f64], fvec: &[f64], jac: &mut [f64], rp: &mut [f64],
                    xscaling: &[f64],
                    eval: &mut dyn FnMut(&[f64], &mut [f64]),
                    jaceval: &mut dyn FnMut(&[f64], &mut [f64])| {
        arm_attempt();
        let t0 = sysstat::tick();
        JAC_DEPTH.fetch_add(1, Ordering::Relaxed);
        if !has_jac {
            note_jac_eval();
        }
        if has_jac {
            jaceval(x, jac);
            for col in 0..n {
                for i in 0..n {
                    jac[col * n + i] *= xscaling[col];
                }
            }
        } else {
            for col in 0..n {
                let mut h = FD_DELTA * (x[col].abs() + 1.0);
                let saved = x[col];
                if saved + h >= bounds[2 * col + 1] {
                    h = -h; // difference away from the variable's max attribute
                }
                x[col] = saved + h;
                eval(x, rp);
                // C's `1./delta_hh * xScaling[i]`: `xScaling[i]/delta_hh` rounds
                // differently, and `1/h` magnifies that into the quotient.
                let inv = 1.0 / h * xscaling[col];
                for i in 0..n {
                    jac[col * n + i] = (rp[i] - fvec[i]) * inv;
                }
                x[col] = saved;
            }
        }
        JAC_DEPTH.fetch_sub(1, Ordering::Relaxed);
        sysstat::add_jacobian_time(sysstat::tick() - t0);
        !attempt_aborted()
    };

    // C's `tries <= 2` loop: the point is regular only if the residual, the Jacobian
    // *and* the first linear solve all come through. Otherwise C breaks the symmetry
    // of the guess by `xScaling[i]·i/n` of 1%, then 10%, before giving up.
    let mut regular = false;
    for tries in 0..3 {
        if trace.is_some() {
            omclog::debug_vector_double(omclog::NLS_V, "x0", x);
        }
        arm_attempt();
        eval(x, &mut fvec);
        // C's `giveUp` in `solveHomotopy`'s entry phase: no varied retry, since the
        // residual the casual set just reported is not a residual at all.
        if dt_violated() {
            x0.copy_from_slice(x);
            return (false, false);
        }
        if !attempt_aborted() {
            // A start point already at tolerance is the solution; C forms no Jacobian.
            // ~40% of calls, nearly all of them an exact time hit whose residual is 0.
            if nsq(&fvec) < ftol_sq * 1e-4 || scaled_sq(n, &fvec, res_scaling) < ftol_sq * 1e-4 {
                stat_inc(STAT_NLS_ACCEPT);
                if trace.is_some() {
                    omclog::debug_string(omclog::NLS_V, "regular initial point!!!");
                }
                return (true, true);
            }
            if form_jac(x, &fvec, &mut jac, &mut rp, &xscaling, eval, jaceval) {
                row_scaling(n, &jac, res_scaling);
                regular = total_pivot_step(n, &jac, &fvec, &xscaling, &mut step, casual);
                if regular {
                    if trace.is_some() {
                        omclog::debug_string(omclog::NLS_V, "regular initial point!!!");
                    }
                    break;
                }
            }
        }
        if tries == 2 {
            break;
        }
        stat_inc(STAT_NLS_VARY_START);
        let (vary, pct) = if tries == 0 { (0.01, "1") } else { (0.1, "10") };
        if trace.is_some() {
            omclog::debug_string(
                omclog::NLS_V,
                &alloc::format!("assert handling:\t vary initial guess by +{pct}%."),
            );
        }
        for i in 0..n {
            x[i] = x_start[i] + xscaling[i] * (i as f64) / (n as f64) * vary;
        }
    }
    // C's `x0`, which `solveHomotopy` publishes as `nlsx`: every later rung, up to
    // and including `solveHybrd`, restarts from the varied point, not from `xStart`.
    x0.copy_from_slice(x);
    if !regular {
        stat_inc(STAT_NEWTON_IRREGULAR);
        return (false, false);
    }
    let mut error_f_sqrd = nsq(&fvec);
    let mut error_f_sqrd_scaled = scaled_sq(n, &fvec, res_scaling);

    let max_iter = 100 * n as i32;
    if let Some(t) = trace {
        omclog::debug_string(omclog::NLS_V, BAR);
        omclog::debug_int(omclog::NLS_V, "NEWTON SOLVER STARTED! equation number: ", t.eq_index as i32);
        omclog::debug_int(omclog::NLS_V, "maximum number of function evaluation: ", max_iter);
        log_nls_status(t, &x[..n], &xscaling, bounds);
    }
    let mut iter = 0i32;
    let mut neg_steps = 0i32;
    let mut small_steps = 0i32;
    // C's `solverinfo == 1`, which its first iteration cannot see: the entry phase's
    // total-pivot solve reports a vanishing determinant only to the log.
    let mut vanishing = false;
    loop {
        stat_inc(STAT_NLS_ITER);
        if let Some(t) = trace {
            omclog::debug_int(omclog::NLS_V, "Iteration:", iter + 1);
            for i in 0..n {
                x1[i] = x[i] + step[i];
            }
            log_newton_step(t, &x1, &step, x);
        }
        let grad_f = -2.0 * error_f_sqrd;
        let grad_f_scaled = -2.0 * error_f_sqrd_scaled;

        // λ1: back off from the full step while the residual asserts (C's `longjmp`);
        // an overflowed but finite one goes to the damping below, which collapses λ.
        let mut lambda1 = 1.0;
        loop {
            for i in 0..n {
                x1[i] = x[i] + lambda1 * step[i];
            }
            eval(&x1, &mut fvec);
            // C's `f_con` failing here ends the whole Newton, not just this step.
            if dt_violated() {
                lambda1 = LAMBDA_MIN_C - 1.0;
                break;
            }
            if !assert_hit() {
                break;
            }
            if trace.is_some() {
                omclog::debug_double(omclog::NLS_V, "Assert of Newton step: lambda1 =", lambda1);
            }
            lambda1 *= 0.655;
            if lambda1 <= LAMBDA_MIN_C {
                break;
            }
        }
        if lambda1 < LAMBDA_MIN_C {
            stat_inc(STAT_NEWTON_LAMBDA);
            if let Some(t) = trace {
                omclog::debug_double(omclog::NLS_V, UPS, t.time);
            }
            return (false, false);
        }
        let error_f1_sqrd = nsq(&fvec);
        let error_f1_sqrd_scaled = scaled_sq(n, &fvec, res_scaling);
        if trace.is_some() {
            let d = |m: &str, v: f64| omclog::debug_double(omclog::NLS_V, m, v);
            d("Need to damp, grad_f = ", grad_f);
            d("Need to damp, error_f = ", libm::sqrt(error_f_sqrd));
            d("Need to damp this!! lambda1 = ", lambda1);
            d("Need to damp, error_f1 = ", libm::sqrt(error_f1_sqrd));
            d("Need to damp, forced error = ", error_f_sqrd + ALPHA * lambda1 * grad_f);
        }

        // Numerical-Recipes damping: quadratic then cubic model of ‖f‖².
        if error_f1_sqrd > error_f_sqrd + ALPHA * lambda1 * grad_f
            && error_f1_sqrd_scaled > error_f_sqrd_scaled + ALPHA * lambda1 * grad_f_scaled
            && error_f_sqrd > 1e-12
            && error_f_sqrd_scaled > 1e-12
        {
            let lambda2 = (-lambda1 * lambda1 * grad_f
                / (2.0 * (error_f1_sqrd - error_f_sqrd - lambda1 * grad_f)))
                .max(LAMBDA_MIN_C);
            if trace.is_some() {
                omclog::debug_double(omclog::NLS_V, "Need to damp this!! lambda2 = ", lambda2);
            }
            for i in 0..n {
                x1[i] = x[i] + lambda2 * step[i];
            }
            eval(&x1, &mut fvec);
            if dt_violated() {
                return (false, false);
            }
            if assert_hit() {
                if let Some(t) = trace {
                    omclog::debug_double(omclog::NLS_V, UPS, t.time);
                }
                return (false, false);
            }
            let error_f2_sqrd = nsq(&fvec);
            if trace.is_some() {
                omclog::debug_double(omclog::NLS_V, "Need to damp, error_f2 = ", libm::sqrt(error_f2_sqrd));
            }
            if error_f1_sqrd > error_f_sqrd + ALPHA * lambda2 * grad_f
                && error_f_sqrd > 1e-12
                && error_f_sqrd_scaled > 1e-12
            {
                let rhs1 = error_f1_sqrd - grad_f * lambda1 - error_f_sqrd;
                let rhs2 = error_f2_sqrd - grad_f * lambda2 - error_f_sqrd;
                let a3 = (rhs1 / (lambda1 * lambda1) - rhs2 / (lambda2 * lambda2)) / (lambda1 - lambda2);
                let a2 = (-lambda2 * rhs1 / (lambda1 * lambda1) + lambda1 * rhs2 / (lambda2 * lambda2))
                    / (lambda1 - lambda2);
                let mut lam;
                if a3 == 0.0 {
                    lam = -grad_f / (2.0 * a2);
                } else {
                    let d = a2 * a2 - 3.0 * a3 * grad_f;
                    if d <= 0.0 {
                        lam = 0.5 * lambda1;
                    } else if a2 <= 0.0 {
                        lam = (-a2 + libm::sqrt(d)) / (3.0 * a3);
                    } else {
                        lam = -grad_f / (a2 + libm::sqrt(d));
                    }
                }
                lam = lam.max(LAMBDA_MIN_C);
                if trace.is_some() {
                    omclog::debug_double(omclog::NLS_V, "Need to damp this!! lambda = ", lam);
                }
                for i in 0..n {
                    x1[i] = x[i] + lam * step[i];
                }
                eval(&x1, &mut fvec);
                if dt_violated() {
                    return (false, false);
                }
                if assert_hit() {
                    if let Some(t) = trace {
                        omclog::debug_double(omclog::NLS_V, UPS, t.time);
                    }
                    return (false, false);
                }
                if trace.is_some() {
                    omclog::debug_double(omclog::NLS_V, "Need to damp, error_f1 = ", libm::sqrt(nsq(&fvec)));
                }
            }
        }

        if trace.is_some() {
            omclog::debug_vector_double(omclog::NLS_V, "function values:", &fvec);
            let mut scaled = vec![0.0f64; n];
            for i in 0..n {
                let d = res_scaling[i].abs();
                scaled[i] = if d > 0.0 { fvec[i] / d } else { fvec[i] };
            }
            omclog::debug_vector_double(omclog::NLS_V, "scaled function values:", &scaled);
        }

        // Error measures (C uses the FULL Newton step ‖dy0‖ for delta_x).
        let delta_x_sqrd = nsq(&step);
        let mut dxs = 0.0;
        for i in 0..n {
            let v = step[i] / xscaling[i];
            dxs += v * v;
        }
        let delta_x_sqrd_scaled = dxs;
        let error_f_old = error_f_sqrd;
        error_f_sqrd = nsq(&fvec);
        error_f_sqrd_scaled = scaled_sq(n, &fvec, res_scaling);
        neg_steps += (error_f_sqrd > 10.0 * error_f_old) as i32;
        if trace.is_some() {
            let d = |m: &str, v: f64| omclog::debug_double(omclog::NLS_V, m, v);
            omclog::debug_string(omclog::NLS_V, "error measurements:");
            d("delta_x        =", libm::sqrt(delta_x_sqrd));
            d("delta_x_scaled =", libm::sqrt(delta_x_sqrd_scaled));
            d("newtonXTol          =", libm::sqrt(xtol_sq));
            d("error_f        =", libm::sqrt(error_f_sqrd));
            d("error_f_scaled =", libm::sqrt(error_f_sqrd_scaled));
            d("newtonFTol          =", libm::sqrt(ftol_sq));
        }
        if neg_steps > 20 {
            stat_inc(STAT_NEWTON_NEGSTEP);
            if trace.is_some() {
                omclog::debug_int(omclog::NLS_V, "UPS! Something happened, NegativeSteps = ", neg_steps);
            }
            return (false, false);
        }
        // C's issue #6419: on success keep the previous `x` when the new residual is no
        // better. Every other exit below also leaves `x` at the previous iterate.
        let last_was_good = error_f_sqrd >= error_f_old;

        let f_ok = error_f_sqrd < ftol_sq || error_f_sqrd_scaled < ftol_sq;
        let x_ok = delta_x_sqrd_scaled < xtol_sq || delta_x_sqrd < xtol_sq;
        if f_ok && x_ok {
            if last_was_good {
                if trace.is_some() {
                    omclog::debug_string(
                        omclog::NLS_V,
                        "Note: newton solver rejected last x because previous was as good",
                    );
                }
            } else {
                x.copy_from_slice(&x1);
            }
            return (true, !last_was_good);
        }
        if vanishing {
            omclog::debug_string(omclog::DT, "It is not the solution.");
            return (false, false);
        }
        iter += 1;
        // C's `maxNumberOfIterations = size*100`.
        if iter > max_iter {
            stat_inc(STAT_NEWTON_MAXITER);
            if let Some(t) = trace {
                let when = if t.initial {
                    alloc::string::String::from("at initialization")
                } else {
                    alloc::format!("at time {:.6}", t.time)
                };
                omclog::warning(
                    omclog::NLS_V,
                    false,
                    &alloc::format!(
                        "Homotopy solver Newton iteration: Maximum number of iterations reached {when}, but no root found."
                    ),
                );
                omclog::debug_string(omclog::NLS_V, NO_CONVERGE);
                omclog::debug_string(omclog::NLS_V, BAR);
            }
            return (false, false);
        }
        small_steps += (delta_x_sqrd < xtol_sq * 1e4 || delta_x_sqrd_scaled < xtol_sq * 1e4) as i32;
        if delta_x_sqrd < xtol_sq || delta_x_sqrd_scaled < xtol_sq || small_steps > 20 {
            let less_accurate = error_f_sqrd < ftol_sq * 1e6 || error_f_sqrd_scaled < ftol_sq * 1e6;
            if !less_accurate {
                stat_inc(STAT_NEWTON_STUCK);
            }
            if let Some(t) = trace {
                if less_accurate {
                    omclog::debug_string(
                        omclog::NLS_V,
                        "NEWTON SOLVER DID CONVERGE TO A SOLUTION WITH LESS ACCURACY!!!",
                    );
                    log_nls_status(t, &x[..n], &xscaling, bounds);
                } else {
                    omclog::debug_string(omclog::NLS_V, "Warning: newton solver gets stuck!!!");
                    omclog::debug_string(omclog::NLS_V, NO_CONVERGE);
                }
                omclog::debug_string(omclog::NLS_V, BAR);
            }
            return (less_accurate, false);
        }

        x.copy_from_slice(&x1);
        if !form_jac(x, &fvec, &mut jac, &mut rp, &xscaling, eval, jaceval) {
            stat_inc(STAT_NEWTON_JAC);
            if trace.is_some() {
                omclog::debug_string(omclog::NLS_V, "UPS! assert when calculating Jacobian!!!");
            }
            return (false, false);
        }
        row_scaling(n, &jac, res_scaling);
        // C's `linearSolverWrapper` at the head of the next iteration, over the
        // row-equilibrated `[J f]` its `scaleMatrixRows` leaves behind: solve J·d = f
        // in scaled unknowns, unscale, negate so `x1 = x + step`.
        aug[..n * n].copy_from_slice(&jac);
        aug[n * n..].copy_from_slice(&fvec);
        scale_matrix_rows_aug(n, &mut aug);
        step.copy_from_slice(&aug[n * n..]);
        let det = match lu_solve_det(&aug[..n * n], &mut step, n) {
            Some(d) => d,
            None => {
                stat_inc(STAT_NEWTON_SINGULAR);
                if trace.is_some() {
                    omclog::debug_string(omclog::NLS_V, "Linear lapack solver failed!!!");
                    omclog::debug_string(omclog::NLS_V, BAR);
                    omclog::debug_string(omclog::NLS_V, NO_CONVERGE);
                    omclog::debug_string(omclog::NLS_V, BAR);
                }
                return (false, false);
            }
        };
        // `linearSolverWrapper` returns 1 for a casual tearing set whose determinant is
        // on its way to singular: the step keeps the sign `dgesv` gave it (C skips the
        // `vecScalarMult(n, x, -1, x)` there) and, unless this iterate turns out to be
        // the solution, the Newton ends on it.
        vanishing = casual && libm::fabs(det) < 1e-9;
        if vanishing {
            omclog::debug_string(
                omclog::DT,
                "The determinant of the casual tearing set is vanishing, let's fail if this is not the solution...",
            );
        }
        let sign = if vanishing { 1.0 } else { -1.0 };
        for (s, sc) in step.iter_mut().zip(xscaling.iter()) {
            *s = sign * *s * sc;
        }
    }
}

/// The Newton step at the start point; failing it is what makes the point
/// "irregular". C's `solveHomotopy` entry phase reaches for
/// `solveSystemWithTotalPivotSearch` rather than the LAPACK solve its iterations
/// use: a rank-deficient-but-consistent start point is regular there. Step comes
/// back unscaled.
fn total_pivot_step(n: usize, jac: &[f64], fvec: &[f64], xscaling: &[f64], step: &mut [f64], casual: bool) -> bool {
    let mut aug = vec![0.0f64; n * (n + 1)];
    aug[..n * n].copy_from_slice(jac);
    aug[n * n..].copy_from_slice(fvec);
    scale_matrix_rows_aug(n, &mut aug);
    let mut sol = vec![0.0f64; n + 1];
    let mut pos = n as i32;
    if total_pivot_augmented(n, &mut sol, &mut aug, &mut pos, casual) != 0 {
        return false;
    }
    for i in 0..n {
        step[i] = sol[i] * xscaling[i];
    }
    true
}

// `-nls=newton`: C's `solveNewton` (nonlinearSolverNewton.c) over `_omc_newton`
// (newtonIteration.c). Not the `newton_c` above, which is `solveHomotopy`'s inner
// damped Newton — the two converge to different roots.

/// LAPACK's `dgetf2`: in-place partial-pivot LU of the column-major `n×n` `a`, the
/// factors left packed in `a` for C's Newton to reuse. Singularity goes unreported, as
/// in C: `solveLinearSystem` overwrites `dgetrf`'s `info` with `dgetrs`'s.
fn dgetf2(n: usize, a: &mut [f64], piv: &mut [usize]) {
    /// `DLAMCH('S')`: below it, divide rather than scale by the reciprocal.
    const SFMIN: f64 = 2.2250738585072014e-308;
    for j in 0..n {
        let mut p = j;
        for i in j + 1..n {
            if libm::fabs(a[j * n + i]) > libm::fabs(a[j * n + p]) {
                p = i;
            }
        }
        piv[j] = p;
        if a[j * n + p] != 0.0 {
            if p != j {
                for c in 0..n {
                    let t = a[c * n + j];
                    a[c * n + j] = a[c * n + p];
                    a[c * n + p] = t;
                }
            }
            let d = a[j * n + j];
            if libm::fabs(d) >= SFMIN {
                let r = 1.0 / d;
                for i in j + 1..n {
                    a[j * n + i] *= r;
                }
            } else {
                for i in j + 1..n {
                    a[j * n + i] /= d;
                }
            }
        }
        // `dger`: rank-1 update of the trailing submatrix.
        for c in j + 1..n {
            let t = a[c * n + j];
            if t != 0.0 {
                for i in j + 1..n {
                    a[c * n + i] += a[j * n + i] * -t;
                }
            }
        }
    }
}

/// LAPACK's `dgetrs('N')`, one right-hand side: `b ← A⁻¹b`.
fn dgetrs(n: usize, a: &[f64], piv: &[usize], b: &mut [f64]) {
    for j in 0..n {
        b.swap(j, piv[j]);
    }
    for k in 0..n {
        if b[k] != 0.0 {
            for i in k + 1..n {
                b[i] -= b[k] * a[k * n + i];
            }
        }
    }
    for k in (0..n).rev() {
        if b[k] != 0.0 {
            b[k] /= a[k * n + k];
            for i in 0..k {
                b[i] -= b[k] * a[k * n + i];
            }
        }
    }
}

/// C's `compute_scaling_vector`, over a buffer that holds LU factors by then.
fn newton_res_scaling(n: usize, jac: &[f64], scaling: &mut [f64]) {
    for i in 0..n {
        let mut m = libm::fabs(jac[i * n]);
        for k in 1..n {
            m = libm::fmax(libm::fabs(jac[i * n + k]), m);
        }
        scaling[i] = if m <= 0.0 {
            1.0e-16
        } else if !m.is_finite() {
            1.0
        } else {
            m
        };
    }
}

/// C's `wrapper_fvec_newton(fj = 0)`: the analytic Jacobian, else forward differences
/// stepped by `sqrt(DBL_EPSILON)·max(|x_i|, |f_i|)`, signed by `f_i`.
#[allow(clippy::too_many_arguments)]
fn newton_jacobian(
    n: usize,
    x: &mut [f64],
    fvec: &[f64],
    jac: &mut [f64],
    rwork: &mut [f64],
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    jaceval: &mut dyn FnMut(&[f64], &mut [f64]),
    has_jac: bool,
) {
    if has_jac {
        jaceval(x, jac);
        return;
    }
    for i in 0..n {
        let mut dhh = libm::fmax(
            SQRT_EPS * libm::fmax(libm::fabs(x[i]), libm::fabs(fvec[i])),
            SQRT_EPS,
        );
        if fvec[i] < 0.0 {
            dhh = -dhh;
        }
        let saved = x[i];
        dhh = saved + dhh - saved;
        x[i] = saved + dhh;
        let inv = 1.0 / dhh;
        eval(x, rwork);
        for j in 0..n {
            jac[i * n + j] = (rwork[j] - fvec[j]) * inv;
        }
        x[i] = saved;
    }
}

/// C's `damping_heuristic2` (the default `NEWTON_DAMPED2`): shrink by 3/4 until the
/// residual improves; below `1e-4` take the full step, or the tiny one after five tries.
#[allow(clippy::too_many_arguments)]
fn damping_heuristic2(
    n: usize,
    x: &[f64],
    x_incr: &[f64],
    x_new: &mut [f64],
    current: f64,
    fvec: &mut [f64],
    k: &mut i32,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
) {
    const TRESHOLD: f64 = 1.0e-4;
    let mut lambda = 1.0f64;
    eval(x_new, fvec);
    while minpack::enorm(fvec) >= current {
        lambda *= 0.75;
        for i in 0..n {
            x_new[i] = x[i] - lambda * x_incr[i];
        }
        eval(x_new, fvec);
        if lambda <= TRESHOLD {
            if *k < 5 {
                for i in 0..n {
                    x_new[i] = x[i] - x_incr[i];
                }
            }
            eval(x_new, fvec);
            *k += 1;
            return;
        }
    }
}

/// C's `_omc_newton` tolerance; `solveNewton` relaxes only its acceptance bound.
const NEWTON_ITER_TOL: f64 = 1.0e-6;

/// C's `_omc_newton`: damped Newton over a factorization reused while `every_jac` is
/// false (C's `calculate_jacobian = 0`). Returns `(info > 0, ‖fvec‖, ‖fvec/resScaling‖)`.
#[allow(clippy::too_many_arguments)]
fn omc_newton(
    n: usize,
    x: &mut [f64],
    fvec: &mut [f64],
    res_scaling: &mut [f64],
    every_jac: bool,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    jaceval: &mut dyn FnMut(&[f64], &mut [f64]),
    has_jac: bool,
) -> (bool, f64, f64) {
    let eps = NEWTON_ITER_TOL;
    let maxfev = n * 100;
    let mut jac = vec![0.0f64; n * n];
    let mut piv = vec![0usize; n];
    let mut f_old = vec![0.0f64; n];
    let mut x_new = vec![0.0f64; n];
    let mut x_incr = vec![0.0f64; n];
    let mut rwork = vec![0.0f64; n];
    let mut fvec_scaled = vec![0.0f64; n];

    let mut info = 1i32;
    let mut calc_jac = true;
    let mut factorized = false;
    let mut k = 0i32;
    let mut l = 0usize;

    eval(x, fvec);
    f_old.copy_from_slice(fvec);
    let mut error_f = minpack::enorm(fvec);
    let mut current = error_f;
    fvec_scaled.copy_from_slice(fvec);
    // Unknown before the first iteration, so start above `eps`.
    let mut scaled_error_f = 1.0 + eps;
    let mut delta_x = 1.0 + eps;
    let mut delta_f = 1.0 + eps;
    let mut delta_x_scaled = 1.0 + eps;

    while error_f > eps && scaled_error_f > eps && delta_x > eps && delta_f > eps && delta_x_scaled > eps {
        stat_inc(STAT_NLS_ITER);
        if calc_jac {
            newton_jacobian(n, x, fvec, &mut jac, &mut rwork, eval, jaceval, has_jac);
            factorized = false;
            calc_jac = every_jac;
        }
        if !factorized {
            dgetf2(n, &mut jac, &mut piv);
            factorized = true;
        }
        x_incr.copy_from_slice(fvec);
        dgetrs(n, &jac, &piv, &mut x_incr);
        for i in 0..n {
            x_new[i] = x[i] - x_incr[i];
        }
        damping_heuristic2(n, x, &x_incr, &mut x_new, current, fvec, &mut k, eval);

        // C's `calculatingErrors`.
        for i in 0..n {
            rwork[i] = x[i] - x_new[i];
        }
        delta_x = minpack::enorm(&rwork);
        let scale = minpack::enorm(x);
        delta_x_scaled = if scale > 1.0 { delta_x * (1.0 / scale) } else { delta_x };
        for i in 0..n {
            rwork[i] = f_old[i] - fvec[i];
        }
        delta_f = minpack::enorm(&rwork);
        error_f = minpack::enorm(fvec);
        newton_res_scaling(n, &jac, res_scaling);
        for i in 0..n {
            fvec_scaled[i] = fvec[i] / res_scaling[i];
        }
        scaled_error_f = minpack::enorm(&fvec_scaled);

        x.copy_from_slice(&x_new);
        f_old.copy_from_slice(fvec);
        current = error_f;
        l += 1;
        if l > maxfev || k > 5 {
            info = -1;
            break;
        }
    }
    (info > 0, error_f, scaled_error_f)
}

/// C's `solveNewton`: [`omc_newton`] under a retry ladder that varies the start point,
/// refreshes the Jacobian every iteration, then relaxes the acceptance bound. `warm` is
/// C's `nlsxOld`.
#[allow(clippy::too_many_arguments)]
fn solve_newton_c(
    n: usize,
    x: &mut [f64],
    warm: &[f64],
    nominal: &[f64],
    res_scaling: &mut [f64],
    discrete_call: bool,
    eval: &mut dyn FnMut(&[f64], &mut [f64]),
    jaceval: &mut dyn FnMut(&[f64], &mut [f64]),
    has_jac: bool,
) -> bool {
    let mut fvec = vec![0.0f64; n];
    let mut local_tol = NEWTON_ITER_TOL;
    let mut every_jac = false;
    let mut retries = 0i32;
    let mut retries2 = 0i32;
    loop {
        let (ok, xerror, xerror_scaled) =
            omc_newton(n, x, &mut fvec, res_scaling, every_jac, eval, jaceval, has_jac);
        if ok && (xerror <= local_tol || xerror_scaled <= local_tol) {
            return true;
        }
        stat_inc(STAT_NLS_RETRY);
        if retries < 1 {
            x.copy_from_slice(warm);
            every_jac = true;
            retries += 1;
        } else if retries < 2 {
            for i in 0..n {
                x[i] += nominal[i] * 0.01;
            }
            retries += 1;
        } else if retries < 3 {
            x.copy_from_slice(nominal);
            retries += 1;
        } else if retries < 4 && discrete_call {
            // C also holds the relations at their `pre` values here — as
            // `solve_nls` does throughout.
            x.copy_from_slice(warm);
            retries += 1;
        } else if retries2 < 4 {
            x.copy_from_slice(warm);
            local_tol *= 10.0;
            retries = 0;
            retries2 += 1;
        } else {
            return false;
        }
    }
}

/// C's `solve_nonlinear_system`: solve one `SES_NONLINEAR` system in place.
///
/// On convergence the unknown slots (and the torn variables) are left at the
/// solution; on failure the entry guess is restored and [`NlsState::note_failure`]
/// is raised so the integrator can retry at a smaller step.
///
/// Returns 0 solved, 1 failed, 2 solved by the strict tearing set.
pub fn solve_nls(
    spec: &NlsSpec,
    model: &mut dyn NlsModel,
    state: &mut dyn NlsState,
    mem: &mut NlsPersistent,
    backend: &mut dyn NlsBackend,
) -> i32 {
    let NlsSpec { eq_index, time, nnz, sys_num, hom_method, .. } = *spec;
    let (nominal, bounds) = (spec.nominal, spec.bounds);
    let casual = spec.casual;
    let n = spec.size as u32;
    let hom_support = u32::from(spec.hom_support);
    // The residual / Jacobian / guess closures below all reach the model, and none
    // may hold it borrowed across the solve. They are never active at once, and a
    // nested system's solve has its own cell.
    let model = core::cell::RefCell::new(model);
    let state = core::cell::RefCell::new(state);
    // Under an adaptive approach a homotopy-carrying system has one unknown more
    // than residuals: `__HOM_LAMBDA`, the lambda slot (C's `size` vs `size-1`).
    // `n` below is the residual count; the homotopy solver drives the extra one.
    let lambda_unknown = hom_support != 0
        && (hom_method == HOM_GLOBAL_ADAPTIVE || hom_method == HOM_LOCAL_ADAPTIVE)
        && n > 1;
    let n = n as usize - usize::from(lambda_unknown);
    // C's `solve_nonlinear_system` opens the system's clock before anything else.
    sysstat::begin(eq_index as i32, true, n as u32, nnz);
    // C's `equationNonlinear` line. The casual set's own is printed at the call
    // site, ahead of the constraint check that may keep us out of here.
    if !casual {
        dt_solving(eq_index as i32, -1, time, false);
    }
    set_no_throw_div_zero(true);
    let sys0 = sys_counts();
    if n == 0 {
        // No unknowns: C's Newton evaluates the residual once and finds the empty
        // vector converged, so the inner equations run once.
        let saved = enter_eval();
        model.borrow_mut().residual(&[], &mut []);
        let threw = leave_eval(saved);
        if threw {
            state.borrow_mut().note_failure(eq_index);
            stat_inc(STAT_NLS_FAIL);
        }
        set_no_throw_div_zero(false);
        let now = sys_counts();
        sysstat::end([now[0] - sys0[0], now[1] - sys0[1], now[2] - sys0[2]]);
        return i32::from(threw);
    }
    // Relation mode (C's hysteresis): Newton always holds relations (mode 0) so it
    // is smooth; mode 2 (init) is fresh throughout; mode 1 (event) re-solves with
    // fresh relations until the discrete state stabilizes (mixed-system iteration).
    let saved_rel_fresh = state.borrow().relation_mode();
    // A nested solve (a medium inversion inside a flow residual) must not end the
    // enclosing attempt.
    let saved_assert_seen = NLS_ASSERT_SEEN.swap(0, Ordering::Relaxed);
    let saved_throw_seen = NLS_THROW_SEEN.swap(0, Ordering::Relaxed);
    // The buffers handed to [`NlsModel`] each call; the host marshals them into
    // whatever its model reads. `x` carries lambda too, as C's `residualFunc`
    // addresses `xloc[n]`.
    let m = n + usize::from(lambda_unknown);
    let mut load_guess = |x: &mut [f64]| model.borrow_mut().load_guess(x);

    // Warm start: the current slot values (the fallback guess, and what is
    // restored on failure).
    let mut warm = vec![0.0f64; n];
    load_guess(&mut warm);

    stat_inc(STAT_NLS_SOLVE);
    let mut xbuf = vec![0.0f64; m];
    let mut rbuf = vec![0.0f64; n];
    let n_feval = core::cell::Cell::new(0u64);
    let iter0 = counters::stat(STAT_NLS_ITER);
    let jac0 = JAC_EVALS.load(Ordering::Relaxed);
    let mut eval = |xs: &[f64], r: &mut [f64]| {
        stat_inc(STAT_NLS_RES);
        if JAC_DEPTH.load(Ordering::Relaxed) == 0 {
            n_feval.set(n_feval.get() + 1);
        }
        // C's generated `residualFunc`: an inf/nan iteration variable fails the
        // evaluation instead of reaching the model. Feed kinsol the nan residual
        // and its line search takes a nan step length, which no exit test catches.
        // Not a model throw — see [`NLS_EVAL_THREW`].
        if xs.iter().any(|v| !v.is_finite()) {
            if let Some(i) = xs[..n.min(xs.len())].iter().position(|v| !v.is_finite()) {
                omclog::error(
                    omclog::NLS,
                    false,
                    &alloc::format!(
                        "residualFunc{eq_index}: Iteration variable `{}` is inf or nan.",
                        var_names(eq_index).get(i).map_or("", |s| s.as_str())
                    ),
                );
            }
            note_eval_hit(true, false);
            for i in 0..n {
                r[i] = ASSERT_RESIDUAL;
            }
            return;
        }
        // The model owns the slot -- `residualFunc` assigns it from the homotopy
        // unknown -- so it is read back, not mirrored.
        let lambda_now = state.borrow().lambda();
        for i in 0..m {
            xbuf[i] = xs.get(i).copied().unwrap_or(lambda_now);
        }
        // Asserts are recoverable while the residual runs (C's ERROR_NONLINEARSOLVER).
        let saved = enter_eval();
        dt_clear();
        model.borrow_mut().residual(&xbuf, &mut rbuf);
        if leave_eval(saved) {
            // A model assert failed at this trial (e.g. length < s_small): reject the
            // step with a huge residual so the solver backtracks (C caught the longjmp).
            r[..n].fill(ASSERT_RESIDUAL);
        } else {
            r[..n].copy_from_slice(&rbuf);
        }
    };

    // No analytic Jacobian means numeric `hybrd`. A homotopy system's symbolic
    // Jacobian is `n×m`, which only the arc-length solver can use; the plain
    // ladder there takes finite differences.
    let has_hom_jac = lambda_unknown && spec.has_jacobian;
    let has_jac = spec.has_jacobian && !lambda_unknown;
    // `jac_csc` says which shape the model fills: CSC values where the codegen
    // chose to solve sparsely, a dense column-major `n×m` for the rest.
    let jac_csc = has_jac && spec.jac_csc;
    let jac_len = if jac_csc { nnz as usize } else { n * m };
    let mut jacbuf = vec![0.0f64; if has_jac || has_hom_jac { jac_len } else { 0 }];
    // `-nls=` overrides the codegen-time choice (C's per-system `nlsMethod`): `kinsol`
    // takes every patterned system, the dense solvers force dense, unset keeps it.
    let pick = solverflags::nls();
    // C's `initializeNonlinearSystemData` hands a patterned sparse system to KINSOL
    // whatever `analyticalJacobianColumn` is; `nlsSparseJac` differences the pattern.
    let sparse = !lambda_unknown
        && nnz != 0
        && backend.has_sparse()
        && match pick {
            // With neither `-nlss*` flag this is the codegen's own answer.
            Nls::Default => solverflags::nls_use_sparse(n, nnz as usize),
            Nls::Kinsol | Nls::KinsolB => true,
            _ => false,
        };
    // A dense solver over a CSC-emitting `jac`: C's `evalJacobian` with `isDense`.
    let scatter = !sparse && jac_csc;
    let pat: &[u32] = if scatter { spec.pattern } else { &[] };
    let colors: &[u32] = if lambda_unknown { &[] } else { spec.colors() };
    let max: alloc::vec::Vec<f64> = bounds.chunks_exact(2).map(|b| b[1]).collect();
    let mut jaceval = |xs: &[f64], fj: &mut [f64]| {
        stat_inc(STAT_NLS_JAC);
        note_jac_eval();
        // Keep asserts recoverable here too so a probe never traps. C's
        // `MMC_TRY_INTERNAL` spans `hybrj_`, so one here ends the attempt.
        let saved = enter_eval();
        model.borrow_mut().jacobian(xs, &mut jacbuf);
        leave_eval(saved);
        if scatter {
            fj.fill(0.0);
            for c in 0..n {
                for k in pat[c] as usize..pat[c + 1] as usize {
                    let row = pat[n + 1 + k] as usize;
                    fj[c * n + row] = jacbuf[k];
                }
            }
            return;
        }
        fj.copy_from_slice(&jacbuf[..fj.len()]);
    };

    // Per-system state: count | lastTimeSolved | resScaling[n] | nlsxExtrapolation[n]
    // | DEPTH × (time, x[n]).
    // `resScaling` is C's `homotopyData->resScaling`, which lives in the per-system
    // solver data and survives between calls, starting zeroed (= unscaled).
    // The entries are C's `oldValueList`. Depth is what makes the exact-time hit
    // below common: DASSL revisits an already-solved time on about half of all
    // calls, and only a deep list still holds it.
    let hist = &mut *mem.history;
    let mut res_scaling: alloc::vec::Vec<f64> = mem.res_scaling.to_vec();

    // C's `getInitialGuess`: the extrapolation to `time`, and `nlsxOld` = the newest
    // stored solution at or before it.
    let mut guess = warm.clone();
    let mut nlsx_old = warm.clone();
    // C's "if last solving is too long ago use just old values": past five output
    // intervals neither is consulted and the current variable values stand in — a
    // casual tearing set always consults them.
    if casual || libm::fabs(time - *mem.last_solved) < 5.0 * step_size() {
        let hpick = history_pick(hist, time);
        if hpick.exact {
            stat_inc(STAT_NLS_GUESS_HIT);
        }
        // `getInitialGuess` publishes what it picked to the system's own buffer.
        history_guess(hist, &hpick, time, &mut guess);
        history_old(hist, &hpick, &mut nlsx_old);
        mem.extrapolation.copy_from_slice(&guess);
    } else {
        // C's "if last solving is too long ago use just old values" assigns `nlsx`
        // alone and leaves `nlsxExtrapolation` where the last `getInitialGuess` put
        // it — zeroes until this system has taken the other branch once.
        stat_inc(STAT_NLS_STALE);
        guess.copy_from_slice(mem.extrapolation);
    }

    let mut scratch = vec![0.0f64; n];
    // C's start-point rule, shared by `solveHomotopy` and `solveHybrd`:
    // `discreteCall ? nlsx : nlsxExtrapolation`. Extrapolating past a just-switched
    // branch would re-flip the relation the event set. Newton holds relations
    // (`solveContinuous`); an event primes once live, then holds.
    let discrete_call = saved_rel_fresh == 1;
    let mixed = spec.mixed && discrete_call;
    // `functionInitialEquations` sets `discreteCall` too, so an initial system starts
    // from `nlsx`: its extrapolation is still zeroes, and the equidistant homotopy
    // hands each lambda step the previous one's solution through the unknowns.
    let mut x = if saved_rel_fresh != 0 { nlsx_old.clone() } else { guess.clone() };
    // C's `relationsPreBackup`; `updateInnerEquation` primes at `nlsx`. C gates it on
    // `discreteCall`, which `functionInitialEquations` also sets, so an initial system
    // gets it too — with relations already fresh there, only an event moves the flag.
    let mut rel_backup = alloc::vec::Vec::new();
    if saved_rel_fresh != 0 {
        if discrete_call {
            state.borrow_mut().set_relation_mode(1);
        }
        // `updateInnerEquation` calls the residual directly rather than through
        // `wrapper_fvec`, so C does not count this evaluation.
        let uncounted = n_feval.get();
        eval(&nlsx_old, &mut scratch);
        n_feval.set(uncounted);
        if eval_threw() {
            log_assert_handled();
        }
        if mixed {
            rel_backup = vec![0i32; state.borrow().relation_count()];
            state.borrow().relations(&mut rel_backup);
        }
        if discrete_call {
            state.borrow_mut().set_relation_mode(0);
        }
    } else {
        state.borrow_mut().set_relation_mode(0);
    }
    // C prints over `nlsx` (the stored solution), not the extrapolation the solver
    // starts from.
    let log_nls = omclog::active(omclog::NLS);
    if log_nls {
        log_nls_enter(eq_index, time, &nlsx_old, &nominal);
    }
    // C's `ERROR_NONLINEARSOLVER` region starts here, after `updateInnerEquation`.
    let _stage = enter_nls_stage();
    // C runs `newtonDiagnostics` on an initial system here, over `nlsx` and the
    // residual `updateInnerEquation` left in `resValues`. Its own residual and
    // Jacobian calls go to the callbacks directly, uncounted.
    if saved_rel_fresh == 2 && omclog::active(omclog::NLS_NEWTON_DIAGNOSTICS) {
        if let Some(diag) = diag_info(eq_index).filter(|d| d.init_diag) {
            if !spec.has_jacobian {
                omclog::error(omclog::ASSERT, false, "NEWTON_DIAGNOSTICS: numeric jacobian not yet supported.");
            } else {
                let feval0 = n_feval.get();
                let jac0 = JAC_EVALS.load(Ordering::Relaxed);
                let names = var_names(eq_index);
                let mut residual = |xs: &[f64], r: &mut [f64]| {
                    eval(xs, r);
                    eval_threw()
                };
                let mut jacobian = |xs: &[f64], fj: &mut [f64]| jaceval(xs, fj);
                newton_diagnostics::newton_diagnostics(
                    eq_index,
                    &nlsx_old,
                    &scratch,
                    &names,
                    diag,
                    &mut newton_diagnostics::Callbacks { residual: &mut residual, jacobian: &mut jacobian },
                );
                n_feval.set(feval0);
                JAC_EVALS.store(jac0, Ordering::Relaxed);
            }
        }
    }
    let mut fvec = vec![0.0f64; n];
    let maxfev = n * 10000;
    // Last residual eval was at the returned `x`, so the epilogue need not repeat
    // it to leave the slots and torn variables set.
    let mut settled = false;
    // C's `alreadyTested`: the mixed re-check below fires at most once.
    let mut retried = false;
    // C's `x0`, which the mixed retry restarts from; re-taken per homotopy attempt.
    let mut start_point;
    // C's `solve_nonlinear_system` homotopy dispatch: only a *local* equidistant
    // approach sweeps here.
    let equidistant_homotopy = saved_rel_fresh == 2
        && hom_support != 0
        && hom_method == HOM_LOCAL_EQUIDISTANT
        && solverflags::init_lambda_steps() >= 1;
    // C's `solveWithHomotopySolver`, run after the loop below.
    let adaptive_homotopy = saved_rel_fresh == 2 && lambda_unknown;
    let homotopy_deactivated = !(equidistant_homotopy || adaptive_homotopy);
    let run_plain = homotopy_deactivated || !solverflags::homotopy_on_first_try();
    let hom_steps = solverflags::init_lambda_steps();
    let original_lambda = state.borrow().lambda();
    // C's lambda0-system pre-solve, which only the *local* adaptive approach runs.
    let pre_lambda0 = adaptive_homotopy && hom_method == HOM_LOCAL_ADAPTIVE;
    let mut lambda0_ok = true;
    // -2 = the lambda0 pre-solve, -1 = C's plain `solveNLS` attempt,
    // 0..=hom_steps = the local equidistant lambda sweep.
    let mut attempt: i32 = if run_plain {
        -1
    } else if pre_lambda0 {
        -2
    } else if equidistant_homotopy {
        0
    } else {
        i32::MIN // the arc-length solver alone
    };
    // C's `pFile`: the path CSV, written under `LOG_INIT_HOMOTOPY` only.
    let mut hom_csv: Option<(alloc::string::String, alloc::string::String)> = None;
    let open_hom_csv = |csv: &mut Option<(alloc::string::String, alloc::string::String)>| {
        if !omclog::active(omclog::INIT_HOMOTOPY) {
            return;
        }
        let name = alloc::format!("{}_nonlinsys{sys_num}_equidistant_local_homotopy.csv", host::file_prefix());
        omclog::info(
            omclog::INIT_HOMOTOPY,
            false,
            &alloc::format!("The homotopy path of system {sys_num} will be exported to {name}."),
        );
        let mut head = alloc::string::String::from("\"sep=,\"\n\"lambda\"");
        for v in var_names(eq_index) {
            head.push_str(&alloc::format!(",\"{v}\""));
        }
        head.push('\n');
        *csv = Some((name, head));
    };
    if attempt == 0 {
        log_local_homotopy_start(sys_num, true);
        open_hom_csv(&mut hom_csv);
    }
    if attempt == -2 {
        log_local_adaptive_start(sys_num);
    }
    // The strict set solved the component in place of this casual one, so the
    // unknowns already hold the answer: nothing to settle, no failure to report.
    let mut strict_used = false;
    // Whether `solveWithInitHomotopy`, rather than the `solveNLS` ladder, solved it.
    let mut init_hom_solved = false;
    let mut converged = if attempt == i32::MIN { false } else { 'attempts: loop {
        if attempt == -2 {
            // C sets `lambda = 0` before the lambda0-system pre-solve.
            state.borrow_mut().set_lambda(0.0);
        }
        if attempt >= 0 {
            let lambda = (attempt as f64 / hom_steps as f64).min(1.0);
            state.borrow_mut().set_lambda(lambda);
            omclog::info(
                omclog::INIT_HOMOTOPY,
                false,
                &alloc::format!("[system {sys_num}] homotopy parameter lambda = {}", fmt_g6(lambda)),
            );
        }
        settled = false;
        retried = false;
        start_point = x.clone();
        let attempt_converged = loop {
            // A system C would hand to kinsol+KLU: scaled Newton over the CSC Jacobian
            // (`kinsol_sparse_solve`). The dense ladder below is O(n^2) per Jacobian and
            // O(n^3) per step, which is what the sparse choice exists to avoid.
            // `start_point` below is C's `xStart` (`discreteCall ? nlsx :
            // nlsxExtrapolation`), which every solver starts its first try from.
            let converged = if !sparse && pick == Nls::KinsolB && backend.has_kinsol() {
                // C hands *every* system to the selected solver; without a sparsity
                // pattern `initKinsolMemory` takes its dense linear solver, and
                // KINSOL differences the Jacobian itself.
                backend.solve_kinsol_dense(
                    NlsRequest {
                        n, x: &mut x, guess: &start_point, warm: &warm, nominal, old_values: &nlsx_old,
                        eq_index, time, has_jacobian: has_jac, colors, max: &max,
                    },
                    &mut load_guess,
                    &mut eval,
                    &mut jaceval,
                )
            } else if sparse || (pick == Nls::Kinsol && !lambda_unknown && backend.has_kinsol_dense()) {
                backend.solve_sparse(
                    NlsRequest {
                        n, x: &mut x, guess: &start_point, warm: &warm, nominal, old_values: &nlsx_old,
                        eq_index, time, has_jacobian: has_jac, colors, max: &max,
                    },
                    &mut load_guess,
                    &mut eval,
                    &mut jaceval,
                )
            } else if pick == Nls::Newton {
                let ok = solve_newton_c(
                    n, &mut x, &warm, &nominal, &mut res_scaling, discrete_call, &mut eval, &mut jaceval,
                    has_jac,
                );
                // C's `NLS_NEWTON` case in `solveNLS` also falls back to the strict set.
                if casual && !ok {
                    strict_used = dt_strict_fallback(*model.borrow_mut());
                }
                ok
            } else if pick == Nls::Homotopy {
                // Both start directions, as C's runHomotopy.
                let mut ok = false;
                for &dir in &[1.0f64, -1.0] {
                    let mut hx = start_point.clone();
                    if homotopy_solve(n, &mut hx, &nominal, dir, HomVariant::Newton, &mut eval) {
                        x.copy_from_slice(&hx);
                        ok = true;
                        break;
                    }
                }
                ok
            } else {
                // C's default `NLS_MIXED` runs `solveHomotopy`, whose primary solver is
                // `newtonAlgorithm`; minpack `hybrd` is only its fallback, restarted from the
                // same start point. `-nls=hybrid` selects `solveHybrd` alone and skips ahead.
                // Both share the retry/homotopy tail below.
                let start = x.clone();
                // C's `nlsx`, which `solveHomotopy` overwrites with the start point its entry
                // phase settled on. `solveHybrd` restarts from that, not from the raw guess.
                let mut nlsx = start.clone();
                // The approximation a failed `solveHybrd` leaves in `nlsx` for the next one.
                let mut best = start.clone();
                let mut converged = false;
                // C's `solveHomotopy` opens one `LOG_NLS_V` block over everything down to
                // its homotopy runs.
                let homotopy_solver = matches!(pick, Nls::Default | Nls::Mixed);
                // C's `discreteCall` covers the initial system too, so it is not
                // `discrete_call` (which is only about holding relations).
                let t =
                    HomotopyTrace { eq_index, time, discrete: saved_rel_fresh != 0, initial: saved_rel_fresh == 2, header: true };
                // C wraps `newtonAlgorithm`'s reporting in `OMC_ACTIVE_STREAM(LOG_NLS_V)`.
                let trace = omclog::active(omclog::NLS_V).then_some(&t);
                // C's `discreteCall` is set for an initial system too; only an event call
                // has relations to hold, so only there does the continuity flag move.
                let mut set_cont = |c: bool| {
                    if saved_rel_fresh == 1 {
                        state.borrow_mut().set_relation_mode(u32::from(!c));
                    }
                };
                if homotopy_solver {
                    // C's `solveHomotopy` loop.
                    let mut skip_newton = false;
                    let mut run_homotopy = 0;
                    let t_again = HomotopyTrace { header: false, ..t };
                    let mut newton_trace = trace;
                    loop {
                        if !skip_newton {
                            (converged, settled) = newton_c(
                                n, &mut x, &nominal, &bounds, &mut res_scaling, &mut nlsx, &mut eval, &mut jaceval,
                                has_jac, newton_trace, casual,
                            );
                            newton_trace = trace.map(|_| &t_again);
                            if !converged {
                                stat_inc(STAT_NLS_NEWTON_FAIL);
                                x.copy_from_slice(&start);
                            }
                            settled &= converged;
                            // A casual tearing set gets one Newton try before the strict set.
                            if casual && !converged {
                                strict_used = dt_strict_fallback(*model.borrow_mut());
                                break;
                            }
                            if !converged {
                                stat_inc(STAT_NLS_RETRY);
                                converged = hybrd_c(
                                    n, &mut x, &nlsx, &warm, &guess, &nominal, &bounds, &t, &mut eval,
                                    has_jac.then_some(&mut jaceval as &mut dyn FnMut(&[f64], &mut [f64])),
                                    &mut set_cont,
                                );
                                if !converged {
                                    best.copy_from_slice(&x);
                                }
                            }
                        }
                        if converged || run_homotopy >= 3 {
                            break;
                        }
                        run_homotopy += 1;
                        let (variant, dir) = match run_homotopy {
                            1 => (HomVariant::Newton, 1.0),
                            2 => (HomVariant::Newton, -1.0),
                            _ => (HomVariant::Fixpoint, 1.0),
                        };
                        let mut hx = start.clone();
                        skip_newton = !homotopy_solve(n, &mut hx, &nominal, dir, variant, &mut eval);
                        if skip_newton {
                            if run_homotopy >= 3 {
                                break;
                            }
                        } else {
                            x.copy_from_slice(&hx);
                        }
                    }
                }
                if !homotopy_solver && !converged {
                    stat_inc(STAT_NLS_RETRY);
                    converged = hybrd_c(
                        n, &mut x, &nlsx, &warm, &guess, &nominal, &bounds, &t, &mut eval,
                        has_jac.then_some(&mut jaceval as &mut dyn FnMut(&[f64], &mut [f64])), &mut set_cont,
                    );
                    if !converged {
                        best.copy_from_slice(&x);
                    }
                }
                // C's `solveNLS` `NLS_MIXED` tail: `solveHybrd` once more.
                if !converged && homotopy_solver && !strict_used {
                    stat_inc(STAT_NLS_RETRY);
                    converged = hybrd_c(
                        n, &mut x, &best, &warm, &guess, &nominal, &bounds, &t, &mut eval,
                        has_jac.then_some(&mut jaceval as &mut dyn FnMut(&[f64], &mut [f64])), &mut set_cont,
                    );
                }
                // Not C's; these catch what C gives up on.
                // `nls_accept` takes only a point at tolerance, so none can report a non-root.
                // A casual set stops where C's `solveNLS` does: grinding on past minpack
                // would find points its constraints exist to reject.
                if !casual && !strict_used && !converged {
                    stat_inc(STAT_NLS_RETRY);
                    x.copy_from_slice(&warm);
                    converged = newton_solve(n, &mut x, &mut eval);
                    // An initial system gets a second `newtonAlgorithm`, from `x0`.
                    if !converged && saved_rel_fresh == 2 {
                        x.copy_from_slice(&guess);
                        converged = newton_c(
                            n, &mut x, &nominal, &bounds, &mut res_scaling, &mut nlsx, &mut eval, &mut jaceval,
                            has_jac, None, casual,
                        )
                        .0;
                    }
                    if !converged {
                        stat_inc(STAT_NLS_RETRY);
                        converged = hybrd_scaled(n, &mut x, &mut fvec, &nominal, maxfev, &mut eval);
                    }
                    if !converged {
                        x.copy_from_slice(&guess);
                        converged = hybrd_scaled(n, &mut x, &mut fvec, &nominal, maxfev, &mut eval);
                    }
                    if !converged {
                        x.copy_from_slice(&guess);
                        converged = lm_solve(n, &mut x, &mut eval);
                    }
                    if !converged {
                        x.copy_from_slice(&warm);
                        converged = lm_solve(n, &mut x, &mut eval);
                    }
                }
                if homotopy_solver {
                    if !converged {
                        omclog::debug_string(omclog::NLS_V, "Homotopy solver did not converge!");
                    }
                    omclog::close(omclog::NLS_V);
                }
                converged
            };
            // C's `solveHomotopy` mixed tail: relations live at the solution, and if the
            // branch moved, the *same* ladder again from the start point with them live.
            if !converged || !mixed || retried {
                break converged;
            }
            state.borrow_mut().set_relation_mode(1);
            let uncounted = n_feval.get();
            eval(&x, &mut scratch);
            n_feval.set(uncounted);
            settled = true;
            let mut rel_now = vec![0i32; rel_backup.len()];
            state.borrow().relations(&mut rel_now);
            if rel_now == rel_backup {
                break converged;
            }
            retried = true;
            settled = false;
            x.copy_from_slice(&start_point);
        };
        if strict_used {
            break 'attempts false;
        }
        // C's step loop stops at the first lambda that does not converge, and the plain
        // attempt falls through to the sweep.
        if attempt == -2 {
            lambda0_ok = attempt_converged;
            omclog::info(
                omclog::INIT_HOMOTOPY,
                false,
                &alloc::format!(
                    "solving lambda0-system done with{} success\n---------------------------",
                    if attempt_converged { "" } else { "no" }
                ),
            );
            omclog::close(omclog::INIT_HOMOTOPY);
            break 'attempts false;
        }
        if attempt < 0 {
            if attempt_converged {
                break 'attempts true;
            }
            if adaptive_homotopy {
                omclog::warning(
                    omclog::ASSERT,
                    false,
                    &alloc::format!(
                        "Failed to solve the initial system {sys_num} without homotopy method."
                    ),
                );
                if pre_lambda0 {
                    log_local_adaptive_start(sys_num);
                    attempt = -2;
                    continue;
                }
                break 'attempts false;
            }
            if !equidistant_homotopy {
                break 'attempts false;
            }
            log_local_homotopy_start(sys_num, false);
            open_hom_csv(&mut hom_csv);
            attempt = 0;
            continue;
        }
        if !attempt_converged {
            counters::stat_add(counters::STAT_HOMOTOPY_STEPS, hom_steps as u64);
            break 'attempts false;
        }
        omclog::info(
            omclog::INIT_HOMOTOPY,
            false,
            &alloc::format!(
                "[system {sys_num}] homotopy parameter lambda = {} done\n---------------------------",
                fmt_g6((attempt as f64 / hom_steps as f64).min(1.0))
            ),
        );
        if let Some((_, csv)) = hom_csv.as_mut() {
            csv.push_str(&omclog::g((attempt as f64 / hom_steps as f64).min(1.0), 0, 16));
            for v in &x {
                csv.push(',');
                csv.push_str(&omclog::g(*v, 0, 16));
            }
            csv.push('\n');
        }
        if attempt >= hom_steps {
            counters::stat_add(counters::STAT_HOMOTOPY_STEPS, hom_steps as u64);
            break 'attempts true;
        }
        // The next lambda starts from this one's solution, as C's `nlsx` does.
        attempt += 1;
        warm.copy_from_slice(&x);
        guess.copy_from_slice(&x);
        nlsx_old.copy_from_slice(&x);
    } };
    if let Some((name, csv)) = hom_csv {
        host::write_file(&name, &csv);
    }
    // C's `solveWithInitHomotopy`: run along the model's own homotopy path.
    if adaptive_homotopy && !converged && !strict_used && (hom_method == HOM_GLOBAL_ADAPTIVE || lambda0_ok) {
        omclog::info(
            omclog::INIT_HOMOTOPY,
            false,
            "run along the homotopy path and solve the actual system",
        );
        state.borrow_mut().set_lambda(0.0);
        let mut y = x.clone();
        y.push(0.0);
        let mut hom_jac = |ys: &[f64], out: &mut [f64]| {
            stat_inc(STAT_NLS_JAC);
            note_jac_eval();
            let saved = enter_eval();
            model.borrow_mut().jacobian(ys, &mut jacbuf);
            leave_eval(saved);
            out.copy_from_slice(&jacbuf[..out.len()]);
        };
        let export = omclog::active(omclog::INIT_HOMOTOPY).then(|| {
            (sys_num, hom_method == HOM_GLOBAL_ADAPTIVE, var_names(eq_index).to_vec())
        });
        let steps = init_homotopy_solve(
            n,
            &mut y,
            &nominal,
            &bounds,
            export,
            &mut eval,
            has_hom_jac.then_some(&mut hom_jac as &mut dyn FnMut(&[f64], &mut [f64])),
        );
        if let Some(steps) = steps {
            x.copy_from_slice(&y[..n]);
            counters::stat_add(counters::STAT_HOMOTOPY_STEPS, steps as u64);
            converged = true;
            settled = false;
            init_hom_solved = true;
        }
    }
    if retried {
        // `hybrd_c`'s rung may have left the flag held.
        state.borrow_mut().set_relation_mode(1);
    }
    // `solveNLS`'s `NLS_MIXED` tail closes with `getIterationVars(data, nlsx)`, so the
    // solution is *harvested* from the unknown slots wherever the last residual
    // evaluation left them: a Newton that rejected its last trial point (issue #6419)
    // still reports that point, with the torn variables consistent with it. Nothing is
    // evaluated, so C's feval count has no entry for it. `solveWithInitHomotopy` is
    // not `solveNLS`, and so is not harvested.
    let harvest =
        converged && !strict_used && !init_hom_solved && matches!(pick, Nls::Default | Nls::Mixed);
    if harvest {
        load_guess(&mut x);
    } else if converged && !settled && !strict_used {
        // The other `-nls` solvers publish the solver's own answer instead.
        let uncounted = n_feval.get();
        eval(&x, &mut scratch);
        n_feval.set(uncounted);
    }
    // C's `data->simulationInfo->lambda = originalLambda` closing
    // `solve_nonlinear_system` — after the last evaluation, so the torn variables
    // keep the values the solve left them at, not their values at the old lambda.
    state.borrow_mut().set_lambda(original_lambda);
    mem.res_scaling.copy_from_slice(&res_scaling);

    let ret = if strict_used {
        // C's `solveNLS` reports the component solved and `getIterationVars` re-reads
        // the unknowns the strict set wrote, so there is nothing here to store or
        // restore: 2 tells the call site the values already stand.
        2
    } else if converged {
        // `updateInitialGuessDB`: record the solution, unless this evaluation is a
        // Jacobian assembly — those are at perturbed states.
        if context_stores_guess() {
            if hist.len() > 0 && time < hist.time(0) - MINIMAL_STEP_SIZE {
                stat_inc(STAT_NLS_STORE_BACK);
            }
            history_store(hist, time, &x);
        }
        *mem.last_solved = time;
        0
    } else {
        // Restore the entry guess (held) and flag a recoverable failure.
        if saved_rel_fresh != 2 {
            state.borrow_mut().set_relation_mode(0);
        }
        let uncounted = n_feval.get();
        eval(&warm, &mut scratch);
        n_feval.set(uncounted);
        // C's equation index, +1 so nonzero still means "failed". First-writer-wins:
        // C throws out of the equation list at the first failure, never reporting a
        // later one.
        state.borrow_mut().note_failure(eq_index);
        // C's `equationNonlinear` throws here (`throwStreamPrintWithEquationIndexes`),
        // so whichever region is open absorbs it: an integrator residual answers
        // `IRES = -1`, an enclosing solve voids its trial, and the step falls back.
        if error_caught() {
            note_assert();
        }
        stat_inc(STAT_NLS_FAIL);
        1
    };

    if log_nls {
        let c = counters_of(eq_index);
        c[0] += counters::stat(STAT_NLS_ITER) - iter0;
        c[1] += n_feval.get();
        c[2] += JAC_EVALS.load(Ordering::Relaxed) - jac0;
        log_nls_leave(eq_index, converged || strict_used, &x);
    }

    if saved_rel_fresh != 2 {
        state.borrow_mut().set_relation_mode(saved_rel_fresh);
    }
    NLS_ASSERT_SEEN.store(saved_assert_seen, Ordering::Relaxed);
    NLS_THROW_SEEN.store(saved_throw_seen, Ordering::Relaxed);

    // C lowers `noThrowDivZero` here and nowhere else during a run.
    set_no_throw_div_zero(false);

    let now = sys_counts();
    sysstat::end([now[0] - sys0[0], now[1] - sys0[1], now[2] - sys0[2]]);
    ret
}

#[cfg(test)]
mod tests {
    use super::*;

    /// [`History`] over a plain `Vec`, so the list logic can be replayed without a
    /// host.
    #[derive(Default)]
    struct VecHistory {
        entries: alloc::vec::Vec<(f64, alloc::vec::Vec<f64>)>,
    }

    impl History for VecHistory {
        fn len(&self) -> usize {
            self.entries.len()
        }
        fn time(&self, k: usize) -> f64 {
            self.entries[k].0
        }
        fn value(&self, k: usize, i: usize) -> f64 {
            self.entries[k].1[i]
        }
        fn shift(&mut self, from: usize, to: usize) {
            if to == self.entries.len() {
                let e = self.entries[from].clone();
                self.entries.push(e);
            } else {
                self.entries[to] = self.entries[from].clone();
            }
        }
        fn put(&mut self, k: usize, len: usize, time: f64, x: &[f64]) {
            if k == self.entries.len() {
                self.entries.push((time, x.to_vec()));
            } else {
                self.entries[k] = (time, x.to_vec());
            }
            self.entries.truncate(len);
            assert_eq!(self.entries.len(), len);
        }
        fn set_len(&mut self, len: usize) {
            self.entries.truncate(len);
        }
    }

    // Replay the C runtime's own `oldValueList` trace (`nls_c_trace`): for every
    // call, the entries `getValues` picks must be the ones C picked, and an
    // exact-time hit must hand back the stored solution untouched.
    #[test]
    fn history_matches_c_trace() {
        let mut h = VecHistory::default();
        let mut guess = [f64::NAN];
        for (i, (time, picked, store)) in nls_c_trace::TRACE.iter().enumerate() {
            if !time.is_nan() {
                let pick = history_pick(&h, *time);
                let got: alloc::vec::Vec<f64> = pick
                    .old
                    .iter()
                    .chain(pick.old2.iter())
                    .map(|&k| h.time(k))
                    .collect();
                assert_eq!(got, *picked, "call {i}: picked entries differ from C");
                history_guess(&h, &pick, *time, &mut guess);
                if pick.exact {
                    assert_eq!(guess[0], h.value(pick.old.unwrap(), 0), "call {i}: not verbatim");
                }
            }
            if let Some((t, v)) = store {
                history_store(&mut h, *t, &[*v]);
                assert_eq!(h.time(0), *t, "call {i}: store did not land at the front");
                assert!(h.len() <= HIST_DEPTH);
            }
        }
        // The trace is long enough to fill the list and start dropping the oldest.
        assert_eq!(h.len(), HIST_DEPTH);
    }

    // `addListElement` replaces the front when the times match and pushes otherwise,
    // so the list is in insertion order, not time order — a step back in time lands
    // at the front and is found again exactly (which is what skips a Newton solve).
    #[test]
    fn history_keeps_insertion_order() {
        let mut h = VecHistory::default();
        for (t, v) in [(0.0, 1.0), (2.0, 3.0), (1.0, 2.0)] {
            history_store(&mut h, t, &[v]);
        }
        assert_eq!([h.time(0), h.time(1), h.time(2)], [1.0, 2.0, 0.0]);
        let pick = history_pick(&h, 1.0);
        assert!(pick.exact && pick.old == Some(0));
        // Re-storing at the front's time replaces it instead of growing the list.
        history_store(&mut h, 1.0, &[9.0]);
        assert_eq!((h.len(), h.value(0, 0)), (3, 9.0));
    }

    // `extrapolateValues`: linear in time through the picked pair, but the older
    // value verbatim when the two are level.
    #[test]
    fn history_extrapolates_linearly() {
        let mut h = VecHistory::default();
        history_store(&mut h, 1.0, &[10.0, 5.0]);
        history_store(&mut h, 2.0, &[20.0, 5.0]);
        let mut guess = [f64::NAN; 2];
        let pick = history_pick(&h, 4.0);
        assert_eq!((pick.old, pick.old2, pick.exact), (Some(0), Some(1), false));
        history_guess(&h, &pick, 4.0, &mut guess);
        assert_eq!(guess, [40.0, 5.0]);
    }

    // An event before every stored entry empties the list.
    #[test]
    fn history_clean_keeps_one_entry() {
        let mut h = VecHistory::default();
        for (t, v) in [(1.0, 10.0), (2.0, 20.0), (3.0, 30.0)] {
            history_store(&mut h, t, &[v]);
        }
        history_clean(&mut h, 2.5);
        assert_eq!((h.len(), h.time(0), h.value(0, 0)), (1, 2.0, 20.0));
        history_clean(&mut h, 0.5);
        assert_eq!(h.len(), 0);
    }

    /// `initializationTests.singularJacobian_05`: five monomial equations whose
    /// Jacobian vanishes at the all-zero start values. C solves it on `solveHybrd`'s
    /// "try with own scaling factors" rung, from the point `solveHomotopy`'s entry
    /// phase varied to (`xScaling[i]*i/n*0.1`) after finding zero irregular.
    #[test]
    fn hybrd_c_solves_from_a_singular_start() {
        let n = 5;
        let mut x = vec![0.0f64; n];
        let x_start: alloc::vec::Vec<f64> = (0..n).map(|i| i as f64 / n as f64 * 0.1).collect();
        let warm = vec![0.0f64; n];
        let nominal = vec![1.0f64; n];
        let mut bounds = vec![0.0f64; 2 * n];
        for i in 0..n {
            bounds[2 * i] = 0.0;
            bounds[2 * i + 1] = 1e60;
        }
        // Residual signs as the code generator emits them: `c - x^i*x_{i+1}`. They
        // matter — C's forward-difference step is signed by the residual.
        let mut eval = |xs: &[f64], r: &mut [f64]| {
            for i in 0..n - 1 {
                let k = (i + 1) as f64;
                r[i] = libm::pow(k, k) * (k + 1.0) - libm::pow(xs[i], k) * xs[i + 1];
            }
            let k = n as f64;
            r[n - 1] = libm::pow(k, k) - libm::pow(xs[n - 1], k) * xs[0];
        };
        let mut cont = |_: bool| {};
        let t = HomotopyTrace { eq_index: 0, time: 0.0, discrete: true, initial: true, header: true };
        assert!(hybrd_c(n, &mut x, &x_start, &warm, &x_start, &nominal, &bounds, &t, &mut eval, None, &mut cont));
        for i in 0..n {
            assert!((x[i] - (i + 1) as f64).abs() < 1e-6, "x={x:?}");
        }
    }

    // 2×2 linear system solved as if nonlinear: r = A x - b, A=[[2,0],[0,3]], b=[4,9] → x=[2,3].
    #[test]
    fn newton_solves_linear() {
        let mut x = [0.0, 0.0];
        let mut eval = |xs: &[f64], r: &mut [f64]| {
            r[0] = 2.0 * xs[0] - 4.0;
            r[1] = 3.0 * xs[1] - 9.0;
        };
        assert!(newton_solve(2, &mut x, &mut eval));
        assert!((x[0] - 2.0).abs() < 1e-9);
        assert!((x[1] - 3.0).abs() < 1e-9);
    }

    // Genuinely nonlinear + coupled: x^2 + y = 3, x + y^2 = 5 near (1, 2).
    #[test]
    fn newton_solves_nonlinear() {
        let mut x = [1.0, 2.0];
        let mut eval = |xs: &[f64], r: &mut [f64]| {
            r[0] = xs[0] * xs[0] + xs[1] - 3.0;
            r[1] = xs[0] + xs[1] * xs[1] - 5.0;
        };
        assert!(newton_solve(2, &mut x, &mut eval));
        assert!((x[0] * x[0] + x[1] - 3.0).abs() < 1e-8);
        assert!((x[0] + x[1] * x[1] - 5.0).abs() < 1e-8);
    }

    // A stiff-ish scalar case where the undamped full step overshoots: exp(x) - 1 = 0 → x = 0.
    #[test]
    fn newton_line_search_recovers() {
        let mut x = [5.0];
        let mut eval = |xs: &[f64], r: &mut [f64]| {
            r[0] = libm::exp(xs[0]) - 1.0;
        };
        assert!(newton_solve(1, &mut x, &mut eval));
        assert!(x[0].abs() < 1e-7);
    }

    // Full-rank system: total pivot matches the LU solution.
    #[test]
    fn total_pivot_full_rank() {
        // A = [[2,1],[1,3]] column-major, b = [3,5] → x = [0.8, 1.4].
        let a = [2.0, 1.0, 1.0, 3.0];
        let mut b = [3.0, 5.0];
        assert!(total_pivot_solve(&a, &mut b, 2));
        assert!((b[0] - 0.8).abs() < 1e-12);
        assert!((b[1] - 1.4).abs() < 1e-12);
    }

    // Rank-deficient but consistent: second row = 2× first. LU fails, total pivot
    // returns a particular solution (free variable zeroed) that satisfies A x = b.
    #[test]
    fn total_pivot_rank_deficient_consistent() {
        // A = [[1,2],[2,4]] column-major, b = [3,6]. x1 + 2 x2 = 3.
        let a = [1.0, 2.0, 2.0, 4.0];
        assert!(!lu_solve(&a, &mut [3.0, 6.0], 2));
        let mut b = [3.0, 6.0];
        assert!(total_pivot_solve(&a, &mut b, 2));
        assert!((b[0] + 2.0 * b[1] - 3.0).abs() < 1e-12);
    }

    // Rank-deficient and inconsistent: no solution → reported as failure.
    #[test]
    fn total_pivot_inconsistent_fails() {
        // A = [[1,2],[2,4]] column-major, b = [3,7]: parallel rows, incompatible rhs.
        let a = [1.0, 2.0, 2.0, 4.0];
        let mut b = [3.0, 7.0];
        assert!(!total_pivot_solve(&a, &mut b, 2));
    }

    // LM converges from a far-off guess where a full Newton step would overshoot.
    #[test]
    fn lm_solves_from_poor_guess() {
        let mut x = [3.0, -3.0];
        let mut eval = |xs: &[f64], r: &mut [f64]| {
            r[0] = xs[0] * xs[0] + xs[1] - 3.0;
            r[1] = xs[0] + xs[1] * xs[1] - 5.0;
        };
        assert!(lm_solve(2, &mut x, &mut eval));
        assert!((x[0] * x[0] + x[1] - 3.0).abs() < 1e-6);
        assert!((x[0] + x[1] * x[1] - 5.0).abs() < 1e-6);
    }

    // Singular Jacobian → reported as failure, not a panic.
    // Brown's almost-linear function (`nlsTestPackage.problem7`): reaching a root at
    // all exercises the frozen-Jacobian first attempt, the damping and the retry.
    // *Which* root is `problem7_newton`'s job to pin — it follows from the torn system.
    #[test]
    fn solve_newton_solves_browns_almost_linear() {
        let n = 10;
        let mut eval = |x: &[f64], r: &mut [f64]| {
            let sum: f64 = x.iter().sum();
            for i in 0..n - 1 {
                r[i] = x[i] + sum - (n as f64 + 1.0);
            }
            r[n - 1] = x.iter().product::<f64>() - 1.0;
        };
        let mut jaceval = |_: &[f64], _: &mut [f64]| unreachable!();
        let mut x = vec![1.5f64; n];
        let warm = x.clone();
        let nominal = vec![1.0f64; n];
        let mut res_scaling = vec![0.0f64; n];
        assert!(solve_newton_c(
            n, &mut x, &warm, &nominal, &mut res_scaling, false, &mut eval, &mut jaceval, false,
        ));
        let mut r = vec![0.0f64; n];
        eval(&x, &mut r);
        assert!(minpack::enorm(&r) < 1e-6, "{:?}", r);
    }

    #[test]
    fn newton_reports_singular() {
        let mut x = [0.0, 0.0];
        let mut eval = |xs: &[f64], r: &mut [f64]| {
            r[0] = xs[0] + xs[1] - 1.0;
            r[1] = xs[0] + xs[1] - 2.0; // parallel: no solution, singular J
        };
        assert!(!newton_solve(2, &mut x, &mut eval));
    }
}
