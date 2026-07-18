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

use crate::{
    JacAInfo, Layout as SimLayout, MetaKind as ResultKind, REAL_OFF, SimMeta, SolveStats, StateSetInfo, TIME_OFF,
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

    let old_col = st.col_pivot.clone();
    if !pivot(&mut jac, nd, nc, &mut st.row_pivot, &mut st.col_pivot) {
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
    }
    Ok(changed)
}

/// Run state selection over every `$STATESET` (C's `stateSelection`). Returns
/// whether any set switched its selection.
fn run_state_selection(
    e: &mut dyn SimEngine,
    sim_data: u32,
    state_sets: &[StateSetInfo],
    pivots: &mut [StateSetPivot],
) -> Result<bool> {
    let mut changed = false;
    for (info, st) in state_sets.iter().zip(pivots.iter_mut()) {
        changed |= state_selection_set(e, sim_data, info, st)?;
    }
    Ok(changed)
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
    /// Call the exported `simulate(sim_data, start, stop, n_steps) -> buf`, the
    /// in-wasm Euler driver; returns the result-buffer pointer.
    fn call_simulate(&mut self, sim_data: u32, start: f64, stop: f64, n_steps: u32) -> Result<u32>;
    /// If the last wasm call trapped on a failed `assert()`, take the recorded
    /// assertion as `[msg, file, sline, scol, eline, ecol, read_only]` (handles
    /// into shared memory), else `None`. Backed by the engine's `rt_assert` host
    /// import; lets [`drive`] report a model assertion instead of a bare trap.
    fn take_pending_assert(&mut self) -> Option<[i32; 7]>;
}

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
    let Some(pa) = e.take_pending_assert() else { return err };
    let info = AssertInfo {
        msg: read_rt_string(e, pa[0]).unwrap_or_default(),
        file: read_rt_string(e, pa[1]).unwrap_or_default(),
        read_only: pa[6] != 0,
        line_start: pa[2],
        col_start: pa[3],
        line_end: pa[4],
        col_end: pa[5],
    };
    let p = ASSERT_REPORTER.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn(&AssertInfo) = unsafe { core::mem::transmute(p) };
        f(&info);
    }
    "assertion failed"
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

/// `f64::sqrt` (the one transcendental the driver uses); `core` has no inherent
/// `sqrt`, so no_std routes through `libm`.
#[inline]
fn sqrt(x: f64) -> f64 {
    #[cfg(feature = "std")]
    {
        x.sqrt()
    }
    #[cfg(not(feature = "std"))]
    {
        libm::sqrt(x)
    }
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
fn deadline_from(budget_ms: f64) -> f64 {
    if budget_ms.is_finite() { now_ms() + budget_ms } else { f64::INFINITY }
}
fn past_deadline(deadline: f64) -> bool {
    deadline.is_finite() && now_ms() >= deadline
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
fn cancel_requested() -> bool {
    let p = CANCEL_HOOK.load(Ordering::Relaxed);
    if p == 0 {
        return false;
    }
    let f: fn() -> bool = unsafe { core::mem::transmute(p) };
    f()
}

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
fn write_i32(e: &mut dyn SimEngine, addr: u32, v: i32) -> Result<()> {
    e.write_bytes(addr, &v.to_le_bytes())
}

/// Error out if a nonlinear system raised the `nls_fail` flag during the last
/// equation call in a context that cannot back off (initialisation, an output
/// point, the Euler loop). The DASSL residual handles this recoverably instead.
fn check_nls(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    if read_i32(e, sim_data + layout.nls_fail_off)? != 0 {
        return Err("CodegenWasmJit: nonlinear system did not converge");
    }
    Ok(())
}

/// Number of equidistant homotopy steps (C's `init_lambda_steps`).
const HOMOTOPY_STEPS: i32 = 3;

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

fn apply_start_overrides(e: &mut dyn SimEngine, sim_data: u32) -> Result<()> {
    apply_overrides(e, sim_data, &overrides_store::starts())
}

/// Returned to abort a run on detected chattering (`-abortSlowSimulation`).
pub const CHATTER_ABORT_ERR: &str = "CodegenWasmJit: aborting simulation due to chattering";

/// Log-line prefix `<stream>| <level>| ` at the runtime's column widths.
fn log_prefix(stream: &str, level: &str) -> String {
    format!("{stream:<18}| {level:<8}| ")
}

/// `-abortSlowSimulation` flag + the driver's chattering log lines, set on the host
/// before a run (the driver can only return a `&'static str`).
mod chatter_store {
    use alloc::string::String;
    use alloc::vec::Vec;

    #[cfg(feature = "std")]
    mod imp {
        use alloc::string::String;
        use alloc::vec::Vec;
        use core::cell::{Cell, RefCell};
        std::thread_local! {
            static ABORT: Cell<bool> = const { Cell::new(false) };
            static LOG: RefCell<Vec<String>> = const { RefCell::new(Vec::new()) };
        }
        pub fn set_abort(v: bool) {
            ABORT.with(|a| a.set(v));
        }
        pub fn abort() -> bool {
            ABORT.with(|a| a.get())
        }
        pub fn push(s: String) {
            LOG.with(|l| l.borrow_mut().push(s));
        }
        pub fn take() -> Vec<String> {
            LOG.with(|l| core::mem::take(&mut *l.borrow_mut()))
        }
    }

    #[cfg(not(feature = "std"))]
    mod imp {
        use alloc::string::String;
        use alloc::vec::Vec;
        use core::cell::UnsafeCell;
        // The in-wasm runtime is single-threaded, so a plain cell is sound.
        struct Store(UnsafeCell<(bool, Vec<String>)>);
        unsafe impl Sync for Store {}
        static STORE: Store = Store(UnsafeCell::new((false, Vec::new())));
        pub fn set_abort(v: bool) {
            unsafe { (*STORE.0.get()).0 = v };
        }
        pub fn abort() -> bool {
            unsafe { (*STORE.0.get()).0 }
        }
        pub fn push(s: String) {
            unsafe { (*STORE.0.get()).1.push(s) };
        }
        pub fn take() -> Vec<String> {
            unsafe { core::mem::take(&mut (*STORE.0.get()).1) }
        }
    }

    pub use imp::{abort, push, set_abort, take};
}

/// Arm `-abortSlowSimulation` for the next run and clear any stale chattering log.
pub fn set_abort_slow(v: bool) {
    chatter_store::set_abort(v);
    let _ = chatter_store::take();
}

/// Drain the chattering log lines the last run emitted.
pub fn take_chatter_log() -> Vec<String> {
    chatter_store::take()
}

/// Solve the initial system: `functionParameters`, then `functionInitialEquations`
/// with the relations fresh (init mode). Tries directly first (lambda = 1, so
/// `homotopy(a, s)` = a); if that leaves a non-converged nonlinear system and the
/// model uses `homotopy()`, fall back to the global equidistant homotopy
/// continuation (C's `solveWithGlobalHomotopy`): lambda 0 -> 1 in `HOMOTOPY_STEPS`
/// steps, step 0 solving the simplified `functionInitialEquations_lambda0`, each
/// step seeded by the previous one's solution. Leaves lambda = 1, then seeds
/// `relationsPre` for the continuous phase's held relations.
pub fn run_initialization(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    run_initialization_impl(e, sim_data, layout)?;
    update_relations_pre(e, sim_data, layout)
}

fn run_initialization_impl(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    e.call1("functionParameters", sim_data)?;
    // Params first (a start expression may read one), then fill start slots, then
    // start overrides (replacing the just-computed start).
    apply_param_overrides(e, sim_data)?;
    e.call1("functionInitStartValues", sim_data)?;
    apply_start_overrides(e, sim_data)?;
    write_i32(e, sim_data + layout.rel_fresh_off, 2)?;
    if layout.n_samples > 0 {
        e.call1("initSample", sim_data)?;
    }
    // Direct attempt (no continuation).
    write_f64(e, sim_data + layout.lambda_off, 1.0)?;
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;
    e.call1("functionInitialEquations", sim_data)?;
    if check_nls(e, sim_data, layout).is_ok() {
        return Ok(());
    }
    if !layout.has_homotopy {
        check_nls(e, sim_data, layout)?; // re-surface the failure
        return Ok(());
    }
    for step in 0..=HOMOTOPY_STEPS {
        let lambda = step as f64 / HOMOTOPY_STEPS as f64;
        write_f64(e, sim_data + layout.lambda_off, lambda)?;
        write_i32(e, sim_data + layout.nls_fail_off, 0)?;
        if step == 0 {
            e.call1("functionInitialEquations_lambda0", sim_data)?;
        } else {
            e.call1("functionInitialEquations", sim_data)?;
        }
        if check_nls(e, sim_data, layout).is_err() {
            return Err("CodegenWasmJit: homotopy initialization did not converge at lambda=");
        }
    }
    write_f64(e, sim_data + layout.lambda_off, 1.0)?;
    Ok(())
}

/// Append one trajectory row to `rows`: the real part `[time | realVars]`
/// followed by the integer and boolean algebraic slots (converted to f64),
/// matching `SimLayout::n_row_total()` and the column layout `kind_from_slot`
/// assigns. Used by the host-driven drivers; the in-wasm `simulate` emits the
/// same layout.
fn capture_row(e: &dyn SimEngine, rows: &mut Vec<f64>, sim_data: u32, layout: &SimLayout) -> Result<()> {
    for i in 0..layout.n_reals_row() {
        rows.push(read_f64(e, sim_data + i * 8)?);
    }
    for i in 0..layout.n_int_alg() {
        rows.push(read_i32(e, sim_data + layout.int_off + i * 4)? as f64);
    }
    for j in 0..layout.n_bool_alg() {
        rows.push(read_i32(e, sim_data + layout.bool_off + j * 4)? as f64);
    }
    Ok(())
}

/// True if `terminate()` raised the `SimData` flag during the last step.
fn terminated(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<bool> {
    Ok(read_i32(e, sim_data + layout.terminate_off)? != 0)
}

/// Emit one result row from SimData at `time`, recomputing `functionODE`/
/// `functionAlgebraics` first so the reported derivatives/algebraics are consistent.
/// The integrator has accepted the state, so a non-converging NLS here is a genuine
/// failure; `nls_fail` is cleared first so `check_nls` sees only this point's solve.
fn emit_row(e: &mut dyn SimEngine, rows: &mut Vec<f64>, sim_data: u32, layout: &SimLayout, time: f64) -> Result<()> {
    write_i32(e, sim_data + layout.nls_fail_off, 0)?;
    write_f64(e, sim_data + TIME_OFF, time)?;
    e.call1("functionODE", sim_data)?;
    e.call1("functionAlgebraics", sim_data)?;
    check_nls(e, sim_data, layout)?;
    capture_row(e, rows, sim_data, layout)
}

/// Pre-event snapshot row (state just before a discrete update). Skips
/// `functionAlgebraics` for `has_when` models — there it saves `pre` early, which
/// would break the post-event edge test.
fn capture_pre(e: &mut dyn SimEngine, rows: &mut Vec<f64>, sim_data: u32, layout: &SimLayout, time: f64) -> Result<()> {
    write_f64(e, sim_data + TIME_OFF, time)?;
    e.call1("functionODE", sim_data)?;
    if !layout.has_when {
        e.call1("functionAlgebraics", sim_data)?;
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

/// Upper bound on discrete-update iterations at one event (C's `maxEventIterations`).
const MAX_EVENT_ITER: usize = 20;

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
/// filling `out` with the `n_zc` values (`gout[i] = relation ? 1 : -1`). Used by
/// the discrete-only driver to bracket and localize state events between grid
/// points.
fn eval_zero_crossings(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout, time: f64, out: &mut [f64]) -> Result<()> {
    // Held relations (mode 0): the probe must not flip a relation or fire a
    // when-body, only a located event changes discrete state. `functionAlgebraics`
    // is needed alongside `functionODE` so a boolean algebraic the crossing reads
    // (e.g. StateGraph's `enableFire`) is current; the crossing function itself
    // re-evaluates relations regardless of this flag.
    write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
    write_f64(e, sim_data + TIME_OFF, time)?;
    e.call1("functionODE", sim_data)?;
    e.call1("functionAlgebraics", sim_data)?;
    e.call1("functionZeroCrossings", sim_data)?;
    for (i, v) in out.iter_mut().enumerate() {
        *v = read_f64(e, sim_data + layout.zc_off + (i as u32) * 8)?;
    }
    Ok(())
}

/// Whether any zero-crossing value changed sign between `a` and `b` — i.e. a state
/// event lies in the bracketed interval.
fn zc_crossed(a: &[f64], b: &[f64]) -> bool {
    a.iter().zip(b).any(|(&x, &y)| (x < 0.0) != (y < 0.0))
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
        eval_zero_crossings(e, sim_data, layout, tm, scratch)?;
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
fn iterate_discrete(e: &mut dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<()> {
    // Each pass freezes `relationsPre = relations` so the NLS in `functionODE` holds
    // this pass's relations; the discrete state settles across passes.
    update_relations_pre(e, sim_data, layout)?;
    e.call1("functionODE", sim_data)?;
    e.call1("functionAlgebraics", sim_data)?;
    let mut prev = discrete_snapshot(e, sim_data, layout)?;
    for _ in 1..MAX_EVENT_ITER {
        update_relations_pre(e, sim_data, layout)?;
        e.call1("functionODE", sim_data)?;
        e.call1("functionAlgebraics", sim_data)?;
        let cur = discrete_snapshot(e, sim_data, layout)?;
        if cur == prev {
            break;
        }
        prev = cur;
    }
    Ok(())
}

/// Per-sample time-event state: each sample's next firing time and its interval,
/// loaded from the sample region (populated by the model's `initSample`). The
/// driver interleaves these events with the integration — at a firing time it
/// raises the sample's `active` flag, runs the discrete update, and advances the
/// next time by the interval (C's `samplesInfo` + `nextSampleEvent`).
pub struct Samples {
    /// Next firing time per sample (starts at the sample's `start`).
    next: Vec<f64>,
    interval: Vec<f64>,
    /// Absolute address of the `active` flag array (`sim_data + sample_active_off`).
    active_off: u32,
}

impl Samples {
    /// Read the start/interval pairs `initSample` wrote into the sample region.
    pub fn load(e: &dyn SimEngine, sim_data: u32, layout: &SimLayout) -> Result<Self> {
        let n = layout.n_samples as usize;
        let mut next = Vec::with_capacity(n);
        let mut interval = Vec::with_capacity(n);
        for k in 0..n as u32 {
            let base = sim_data + layout.sample_off + k * 16;
            next.push(read_f64(e, base)?);
            interval.push(read_f64(e, base + 8)?);
        }
        Ok(Samples { next, interval, active_off: sim_data + layout.sample_active_off })
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
        let eps = t.abs().max(1.0) * 1e-10;
        let mut fired = vec![false; self.next.len()];
        for k in 0..self.next.len() {
            if self.next[k] <= t + eps {
                fired[k] = true;
                write_i32(e, self.active_off + k as u32 * 4, 1)?;
            }
        }
        write_f64(e, sim_data + TIME_OFF, t)?;
        e.call1("functionAlgebraics", sim_data)?;
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
/// `DasslEventsDriver` inlines this same sequence around its row bookkeeping.
/// A sample due at `time` is a time event, otherwise it is a state event.
pub fn event_update(
    e: &mut dyn SimEngine,
    sim_data: u32,
    layout: &SimLayout,
    samples: Option<&mut Samples>,
    time: f64,
) -> Result<EventUpdate> {
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
            s.fire(e, sim_data, time)?;
        }
        store_relations(e, sim_data, layout)?;
        // `fire` cleared the `active` flag; re-evaluate so the condition reads
        // false and `pre` records it, or the next firing sees no edge.
        e.call1("functionODE", sim_data)?;
        e.call1("functionAlgebraics", sim_data)?;
    } else {
        // `pre(x)` of a continuous variable must be its value at the crossing.
        save_pre_real(e, sim_data, layout)?;
        store_relations(e, sim_data, layout)?;
        iterate_discrete(e, sim_data, layout)?;
        store_relations(e, sim_data, layout)?;
        check_nls(e, sim_data, layout)?;
        // A reinit changes the state the derivatives are computed from.
        e.call1("functionODE", sim_data)?;
    }

    let mut states_changed = false;
    for (i, b) in before.iter().enumerate() {
        if read_f64(e, states_base + (i as u32) * 8)? != *b {
            states_changed = true;
            break;
        }
    }

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
/// [`drive`] and the session. `method` empty = DASSL. Any events force the
/// event-aware DASSL driver regardless of `method`.
pub fn make_driver(
    e: &mut (dyn SimEngine + 'static),
    model: &SimModel,
    sim_data: u32,
    method: &str,
) -> Result<(Box<dyn Driver>, &'static str)> {
    let layout = &model.layout;
    set_zc_tolerance(e, sim_data, layout, model.tolerance)?;

    if layout.n_samples > 0 || layout.n_zc > 0 {
        return Ok((Box::new(DasslEventsDriver::new(e, model, sim_data)?), "dassl-events"));
    }
    match method {
        "dassl" | "dasslrt" | "ida" | "" => Ok((Box::new(DasslDriver::new(e, model, sim_data)?), "dassl")),
        // Uniform host-driven Euler so it is resumable/cancellable like DASSL.
        "euler" => Ok((Box::new(EulerDriver::new(e, model, sim_data)?), "euler-host")),
        other => return Err("CodegenWasmJit: unsupported integration method (supported: `dassl`, `euler`)"),
    }
}

/// Free external objects (so repeated runs don't leak) and read back parameter
/// values (result `Param` order) after a run.
pub fn finalize_run(e: &mut dyn SimEngine, model: &SimModel, sim_data: u32) -> Result<Vec<f64>> {
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
    let n_rows = model.n_intervals + 1;
    let start = model.start_time;
    let stop = model.stop_time;

    let mut stats = SolveStats::default();
    let use_events = layout.n_samples > 0 || layout.n_zc > 0;

    let (rows, label) = if !use_events && method == "euler" && !host_driven {
        // Fast in-wasm Euler (one host->wasm call; not resumable/cancellable).
        set_zc_tolerance(e, sim_data, layout, model.tolerance)?;
        let rows = run_wasm(e, sim_data, n_reals, n_rows, layout, start, stop, &mut stats)
            .map_err(|err| enrich_trap(e, err))?;
        (rows, "euler-wasm")
    } else {
        // enrich_trap: a trap in init/integration is usually a failed model assert().
        let (mut driver, label) = make_driver(e, model, sim_data, method).map_err(|err| enrich_trap(e, err))?;
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
        (driver.take_rows(), label)
    };
    stats.method = label;
    let _ = bench;
    #[cfg(feature = "std")]
    if bench {
        eprintln!(
            "wasm-jit sim [{label}]: {} steps, {} residual evals, {} jacobian evals",
            stats.steps, stats.res_evals, stats.jac_evals
        );
    }

    let params = finalize_run(e, model, sim_data)?;
    Ok((RunResult { rows, n_reals, params, stats }, label))
}

/// In-wasm driver: one call to `simulate`, then read the result buffer.
fn run_wasm(
    e: &mut dyn SimEngine,
    sim_data: u32,
    n_reals: u32,
    n_rows: u32,
    layout: &SimLayout,
    start: f64,
    stop: f64,
    stats: &mut SolveStats,
) -> Result<Vec<f64>> {
    stats.steps = (n_rows - 1) as u64;
    let buf = e.call_simulate(sim_data, start, stop, n_rows - 1)?;
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
        run_initialization(e, sim_data, &model.layout)?;
        let n_rows = model.n_intervals + 1;
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
        let n_rows = model.n_intervals + 1;
        let n_steps = n_rows - 1;
        let start = model.start_time;
        let stop = model.stop_time;
        let h = if n_steps == 0 { 0.0 } else { (stop - start) / n_steps as f64 };
        let states_base = sim_data + REAL_OFF;
        let ders_base = states_base + n_states * 8;

        let deadline = deadline_from(budget_ms);
        let mut did_step = false;
        while self.row < n_rows {
            if did_step && past_deadline(deadline) {
                return Ok(Advance::Running);
            }
            if cancel_requested() {
                return Ok(Advance::Cancelled);
            }
            did_step = true;
            let time = start + self.row as f64 * h;
            write_f64(e, sim_data + TIME_OFF, time)?;
            e.call1("functionODE", sim_data)?;
            e.call1("functionAlgebraics", sim_data)?;
            check_nls(e, sim_data, layout)?; // Euler cannot back off — non-convergence is fatal
            capture_row(e, &mut self.rows, sim_data, layout)?;
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
            if !model.state_sets.is_empty()
                && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)?
            {
                e.call1("functionODE", sim_data)?;
            }
            // Forward-Euler update of the states.
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
        stats.steps = model.n_intervals as u64;
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
    /// Scratch reused across `dassl_jac` colors (sized `n_states`): perturbed
    /// residual, saved states, reciprocal steps, and the der read buffer.
    jac_gp: Vec<f64>,
    jac_ysave: Vec<f64>,
    jac_del: Vec<f64>,
    jac_ders: Vec<u8>,
    /// Jacobian evaluations (colors summed over all Jacobian assemblies).
    nje: u64,
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
        e.call1("functionODE", ctx.sim_data)?;
        e.call1("functionZeroCrossings", ctx.sim_data)?;
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
        let y_bytes = unsafe { core::slice::from_raw_parts(y as *const u8, n * 8) };
        e.write_bytes(ctx.states_base, y_bytes)?;
        e.call1("functionODE", ctx.sim_data)?;
        // delta := yprime - f
        let delta_bytes = unsafe { core::slice::from_raw_parts_mut(delta as *mut u8, n * 8) };
        e.read_bytes(ctx.ders_base, delta_bytes)?;
        for i in 0..n {
            unsafe { *delta.add(i) = *yprime.add(i) - *delta.add(i) };
        }
        Ok(())
    })();
    ctx.nfe += 1;
    match run {
        Err(err) => {
            ctx.err = Some(err);
            unsafe { *ires = -2 };
        }
        Ok(()) => {
            // A nonlinear system did not converge: recoverable — ask DASKR to
            // retry at a smaller step (the guess was restored by the codegen).
            if read_i32(e, ctx.sim_data + ctx.nls_fail_off).unwrap_or(0) != 0 {
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
    let sqrt_uround = sqrt(f64::EPSILON);
    ctx.jac_ders.resize(n * 8, 0);
    let run = (|| -> Result<()> {
        write_f64(e, ctx.sim_data + TIME_OFF, unsafe { *t })?;
        for color in &jac.colors {
            // Perturb every column in this color; record 1/del and the base value.
            for &col in color {
                let ci = col as usize;
                let yi = unsafe { *y.add(ci) };
                let ypi = unsafe { *yprime.add(ci) };
                let d6 = (h * ypi).abs();
                let mag = (sqrt_uround * yi.abs().max(d6)).max(1.0 / unsafe { *wt.add(ci) });
                let mut del = if h * ypi >= 0.0 { mag } else { -mag };
                del = yi + del - yi; // floating-point rounding, as in the C runtime
                if del == 0.0 {
                    del = sqrt_uround;
                }
                ctx.jac_ysave[ci] = yi;
                ctx.jac_del[ci] = 1.0 / del;
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
            ctx.nje += 1;
            // Scatter the finite difference into the affected rows, restore y.
            for &col in color {
                let ci = col as usize;
                let inv_del = ctx.jac_del[ci];
                for &row in &jac.rows_by_col[ci] {
                    let ri = row as usize;
                    let val = (ctx.jac_gp[ri] - unsafe { *base.add(ri) }) * inv_del;
                    unsafe { *pd.add(ci * n + ri) = val };
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
    if let Err(err) = run {
        ctx.err = Some(err);
    }
}

/// Per-state DASSL tolerances as in `dassl.c`: rtol `tol`, atol `tol·nominal[i]`
/// (`state_nominals` is already floored). Length ≥ 1 so daskr never sees an empty array.
fn dassl_tolerances(tol: f64, state_nominals: &[f64], n_states: usize) -> (Vec<f64>, Vec<f64>) {
    let n = n_states.max(1);
    let rtol = vec![tol; n];
    let atol = (0..n).map(|i| tol * state_nominals.get(i).copied().unwrap_or(1.0)).collect();
    (rtol, atol)
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
    /// `terminate()` fired at the initial point; the first `advance` reports it.
    pending_terminate: bool,
    finished: bool,
    /// Analytic-Jacobian sparsity+coloring (colored numerical FD); `None` ⇒
    /// daskr's own numerical Jacobian.
    jac_a: Option<JacAInfo>,
    /// Jacobian evaluation count, accumulated across chunks (for the bench line).
    nje: u64,
}

impl DasslDriver {
    fn new(e: &mut (dyn SimEngine + 'static), model: &SimModel, sim_data: u32) -> Result<Self> {
        // Silence DASKR's own diagnostic printing (it would go to stdout and corrupt
        // the omc result record); failures are surfaced here via IDID instead.
        daskr::auxiliary::xsetf(0);
        let layout = &model.layout;
        // Init (with homotopy fallback). No state events on this path, so relations
        // stay fresh (mode 2); `rt_solve_nls` still holds them internally.
        run_initialization(e, sim_data, layout)?;

        let n_states = layout.n_states as usize;
        let states_base = sim_data + REAL_OFF;
        let ders_base = states_base + layout.n_states * 8;
        let n_rows = model.n_intervals + 1;
        let n_reals = layout.n_row_total();
        let start = model.start_time;

        let mut rows: Vec<f64> = Vec::with_capacity((n_rows * n_reals) as usize);
        // Row 0 at the start time.
        emit_row(e, &mut rows, sim_data, layout, start)?;
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
            if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut pivots)? {
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
        let (rtol, atol) = dassl_tolerances(tol, &model.state_nominals, n_states);
        if n_states > 0 {
            info[1] = 1; // INFO(2)=1: per-state (vector) rtol/atol
        }
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
            rwork: vec![0.0f64; lrw],
            iwork: vec![0i32; liw],
            rpar: [0.0f64],
            ipar: [0i32],
            jroot: [0i32],
            idid: 0,
            t: start,
            nfe: 0,
            pivots,
            rows,
            pending_tout: None,
            work_retries: 0,
            pending_terminate,
            finished: false,
            jac_a,
            nje: 0,
        })
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
        let n_rows = model.n_intervals + 1;
        let n_steps = n_rows - 1;
        let start = model.start_time;
        let stop = model.stop_time;
        let h = if n_steps == 0 { 0.0 } else { (stop - start) / n_steps as f64 };
        let deadline = deadline_from(budget_ms);

        // No states: nothing to integrate — just evaluate outputs on the grid.
        if self.n_states == 0 {
            let mut did_step = false;
            while self.row < n_rows {
                if did_step && past_deadline(deadline) {
                    return Ok(Advance::Running);
                }
                if cancel_requested() {
                    return Ok(Advance::Cancelled);
                }
                did_step = true;
                let time = if self.row == n_steps { stop } else { start + self.row as f64 * h };
                emit_row(e, &mut self.rows, sim_data, layout, time)?;
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
            nje: self.nje,
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
            if cancel_requested() {
                break Advance::Cancelled;
            }
            did_step = true;
            // IDID=-1: DASKR hit its per-call work quota before TOUT — resume with
            // INFO(1)=1 (a stiff interval hits this repeatedly), up to a cap.
            // `pending_tout`/`work_retries` persist an interval unfinished at a yield.
            let mut tout =
                self.pending_tout.unwrap_or(if self.row == n_steps { stop } else { start + self.row as f64 * h });
            unsafe {
                solver::ddaskr(
                    dassl_res, neq, &mut self.t, self.y.as_mut_ptr(), self.yp.as_mut_ptr(),
                    &mut tout, self.info.as_mut_ptr(), self.rtol.as_mut_ptr(), self.atol.as_mut_ptr(),
                    &mut self.idid, self.rwork.as_mut_ptr(), lrw as i32, self.iwork.as_mut_ptr(), liw as i32,
                    self.rpar.as_mut_ptr(), self.ipar.as_mut_ptr(), jacfn, solver::dummy_jack,
                    solver::dummy_psol, solver::dummy_rt, nrt, self.jroot.as_mut_ptr(),
                );
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
                return Err("CodegenWasmJit: DASSL (daskr) failed at t=, IDID=");
            }
            // Interval complete: reset the resume state, write the interpolated state
            // back, and emit the row.
            self.pending_tout = None;
            self.work_retries = 0;
            for i in 0..n_states {
                write_f64(e, states_base + (i as u32) * 8, self.y[i])?;
            }
            emit_row(e, &mut self.rows, sim_data, layout, tout)?;
            if terminated(e, sim_data, layout)? {
                break Advance::Terminated; // terminate() fired: keep this row, stop
            }
            // Re-select states at the accepted point. A switch changes the meaning of
            // the state vector (a discontinuity), so refresh the derivatives, re-read
            // y/yp from the reinitialised states, and restart DASKR (INFO(1)=0).
            if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)? {
                e.call1("functionODE", sim_data)?;
                for i in 0..n_states {
                    self.y[i] = read_f64(e, states_base + (i as u32) * 8)?;
                    self.yp[i] = read_f64(e, ders_base + (i as u32) * 8)?;
                }
                self.info[0] = 0;
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
        let nst = self.iwork.get(10).copied().unwrap_or(0);
        stats.steps = nst.max(0) as u64;
        stats.res_evals = self.nfe;
        stats.jac_evals = if self.jac_a.is_some() { self.nje } else { self.iwork.get(12).copied().unwrap_or(0).max(0) as u64 };
        stats.err_test_fails = self.iwork.get(13).copied().unwrap_or(0).max(0) as u64;
        stats.conv_test_fails = self.iwork.get(14).copied().unwrap_or(0).max(0) as u64;
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

/// Resumable DASSL driver with event handling (time + state events). Like
/// [`DasslDriver`] but clamps integration to each `sample` time and root-finds the
/// zero-crossings. `mid_row`/`grid_covered` persist a partial output row so a yield
/// mid-interval (or a stuck stiff/chattering one) resumes exactly.
/// The DASKR state and the one integration path over it: [`integrate_to`] runs the
/// solver to a time, handling the state events it roots out and the samples due on
/// the way. `DasslEventsDriver` drives it to each output row and `CsDriver` to each
/// communication point, so the two cannot drift.
///
/// [`integrate_to`]: DasslCore::integrate_to
struct DasslCore {
    sim_data: u32,
    n_states: usize,
    states_base: u32,
    ders_base: u32,
    y: Vec<f64>,
    yp: Vec<f64>,
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
    t: f64,
    nfe: u64,
    /// Jacobian evaluation count, accumulated across chunks (for the bench line).
    nje: u64,
    /// The in-progress target's DASKR continuation count (IDID=-1 work quota).
    ev_retries: i32,
    /// Analytic-Jacobian sparsity+coloring (colored numerical FD); `None` ⇒
    /// daskr's own numerical Jacobian.
    jac_a: Option<JacAInfo>,
    state_events: u64,
    time_events: u64,
    /// Chattering detector: a ring of the last [`CHATTER_LIMIT`] state-event times
    /// + a consecutive-event counter. Fires once.
    chatter_times: [f64; CHATTER_LIMIT],
    chatter_idx: usize,
    chatter_consec: u32,
    chatter_emitted: bool,
}

/// Consecutive state events within one output step that count as chattering.
const CHATTER_LIMIT: usize = 100;

/// How far [`DasslCore::integrate_to`] got.
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

struct DasslEventsDriver {
    core: DasslCore,
    row: u32,
    pivots: Vec<StateSetPivot>,
    samp: Samples,
    rows: Vec<f64>,
    /// Resume state for a yield mid output row, so `grid_covered` is not reset.
    mid_row: bool,
    grid_covered: bool,
    pending_terminate: bool,
    finished: bool,
}

impl DasslCore {
    /// Size the DASKR workspaces and read the initial `(y, yp)` out of `SimData`.
    /// The caller has already initialized the model (`run_initialization`).
    fn new(model: &SimModel, sim_data: u32, t: f64) -> Self {
        let layout = &model.layout;
        let n_states = layout.n_states as usize;
        let states_base = sim_data + REAL_OFF;
        let ders_base = states_base + layout.n_states * 8;
        let neq = n_states as i32;
        let nrt = layout.n_zc as i32;
        let tol = if model.tolerance > 0.0 { model.tolerance } else { 1e-6 };
        let lrw = (60 + 9 * neq + neq * neq + 3 * nrt + 64) as usize;
        let liw = (40 + neq + 64) as usize;
        let jac_a = if env_var("OMC_WASM_NO_ANALYTIC_JAC").is_some() { None } else { model.jac_a.clone() };
        let mut info = [0i32; 24];
        if jac_a.is_some() {
            info[4] = 1; // INFO(5)=1: dense user (colored numerical-FD) Jacobian
        }
        // Per-state nominal-scaled tolerances (see `dassl_tolerances`).
        let (rtol, atol) = dassl_tolerances(tol, &model.state_nominals, n_states);
        if n_states > 0 {
            info[1] = 1; // INFO(2)=1: per-state (vector) rtol/atol
        }
        DasslCore {
            sim_data,
            n_states,
            states_base,
            ders_base,
            y: Vec::new(),
            yp: Vec::new(),
            info,
            rtol,
            atol,
            rwork: vec![0.0f64; lrw],
            iwork: vec![0i32; liw],
            rpar: [0.0f64],
            ipar: [0i32],
            jroot: vec![0i32; (nrt as usize).max(1)],
            nrt,
            idid: 0,
            t,
            nfe: 0,
            nje: 0,
            ev_retries: 0,
            jac_a,
            state_events: 0,
            time_events: 0,
            chatter_times: [0.0; CHATTER_LIMIT],
            chatter_idx: 0,
            chatter_consec: 0,
            chatter_emitted: false,
        }
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

    /// Latch `(y, yp)` from `SimData` — after initialization, or after anything
    /// that moved a state behind DASKR's back.
    fn read_states(&mut self, e: &mut (dyn SimEngine + 'static)) -> Result<()> {
        self.y = (0..self.n_states)
            .map(|i| read_f64(e, self.states_base + (i as u32) * 8))
            .collect::<Result<_>>()?;
        self.yp = (0..self.n_states)
            .map(|i| read_f64(e, self.ders_base + (i as u32) * 8))
            .collect::<Result<_>>()?;
        Ok(())
    }

    /// The `ResCtx` the DASKR callbacks read through, held for one `integrate_to`
    /// (`RES_CTX` is a thread-local raw pointer to it).
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
            jac: self.jac_a.as_ref().map_or(core::ptr::null(), |j| j as *const JacAInfo),
            jac_gp: vec![0.0; self.n_states],
            jac_ysave: vec![0.0; self.n_states],
            jac_del: vec![0.0; self.n_states],
            jac_ders: Vec::new(),
            nje: self.nje,
        }
    }

    /// Integrate to `tout`, handling the state events DASKR roots out and the
    /// samples due on the way. `rows` collects the pre/post-event rows when the
    /// caller wants them; CS passes `None`. A `Yielded` return resumes on the same
    /// `tout` (DASKR continues via INFO(1)=1), so the yields are safe points.
    /// `stop_at_event` (CS Event Mode) stops at the first event and returns
    /// [`Step::Event`] instead of updating in place.
    #[allow(clippy::too_many_arguments)]
    fn integrate_to(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        ctx: &mut ResCtx,
        samp: &mut Samples,
        tout: f64,
        deadline: f64,
        mut rows: Option<&mut Vec<f64>>,
        did_step: &mut bool,
        stop_at_event: bool,
    ) -> Result<Step> {
        use daskr::solver;
        let layout = &model.layout;
        let sim_data = self.sim_data;
        let n_states = self.n_states;
        let (states_base, ders_base) = (self.states_base, self.ders_base);
        let neq = n_states as i32;
        let nrt = self.nrt;
        let rt_fn: solver::RtFn = if layout.n_zc > 0 { dassl_rt } else { solver::dummy_rt };
        let lrw = self.rwork.len();
        let liw = self.iwork.len();
        let jacfn: solver::JacFn = if self.jac_a.is_none() { solver::dummy_jacd } else { dassl_jac };
        let eps = tout.abs().max(1.0) * 1e-10;
        let mut grid_covered = false;

        loop {
            // Yield at the loop boundary (before any state mutation).
            if *did_step && past_deadline(deadline) {
                self.nfe = ctx.nfe;
                return Ok(Step::Yielded);
            }
            if cancel_requested() {
                self.nfe = ctx.nfe;
                return Ok(Step::Cancelled);
            }
            // Mode 0: hold relations across the DASKR solve so its residual/Jacobian
            // probes are smooth (C's `solveContinuous`); events/outputs refresh them.
            write_i32(e, sim_data + layout.rel_fresh_off, 0)?;
            let te = samp.next_time();
            let target = tout.min(te);
            // Integrate from the current t toward `target` (the caller's time or the
            // next scheduled sample). DASKR may stop early at a zero-crossing root.
            if target - self.t > eps {
                let mut tt = target;
                loop {
                    // Yield inside the work-quota loop too, so a stuck stiff interval
                    // is interruptible; resume re-enters with the same target.
                    if *did_step && past_deadline(deadline) {
                        self.nfe = ctx.nfe;
                        return Ok(Step::Yielded);
                    }
                    if cancel_requested() {
                        self.nfe = ctx.nfe;
                        return Ok(Step::Cancelled);
                    }
                    unsafe {
                        solver::ddaskr(
                            dassl_res, neq, &mut self.t, self.y.as_mut_ptr(), self.yp.as_mut_ptr(), &mut tt,
                            self.info.as_mut_ptr(), self.rtol.as_mut_ptr(), self.atol.as_mut_ptr(), &mut self.idid,
                            self.rwork.as_mut_ptr(), lrw as i32, self.iwork.as_mut_ptr(), liw as i32,
                            self.rpar.as_mut_ptr(), self.ipar.as_mut_ptr(), jacfn,
                            solver::dummy_jack, solver::dummy_psol, rt_fn, nrt,
                            self.jroot.as_mut_ptr(),
                        );
                    }
                    self.nfe = ctx.nfe;
                    self.nje = ctx.nje;
                    *did_step = true;
                    if ctx.err.is_some() {
                        break;
                    }
                    if self.idid == -1 && self.ev_retries < 10_000 {
                        self.info[0] = 1;
                        self.ev_retries += 1;
                        continue;
                    }
                    break;
                }
                self.ev_retries = 0; // this target's integration is done (or failing)
                if let Some(err) = ctx.err.take() {
                    return Err(err);
                }
                if self.idid < 0 {
                    return Err("CodegenWasmJit: DASSL (daskr) failed at t=, IDID=");
                }
                for i in 0..n_states {
                    write_f64(e, states_base + (i as u32) * 8, self.y[i])?;
                }
                // IDID=5: a zero-crossing root at `t` (< target). Handle the state
                // event here, then restart the integrator and keep going.
                if self.idid == 5 {
                    let troot = self.t;
                    if stop_at_event {
                        write_f64(e, sim_data + TIME_OFF, troot)?;
                        return Ok(Step::Event { time: troot });
                    }
                    self.state_events += 1;
                    let step_size = if model.n_intervals > 0 {
                        (model.stop_time - model.start_time) / model.n_intervals as f64
                    } else {
                        0.0
                    };
                    if let Some((t0, t1)) = self.note_chatter_event(troot, step_size) {
                        let zc = self.jroot.iter().position(|&r| r != 0).unwrap_or(0);
                        let desc = model.zc_desc.get(zc).map(String::as_str).unwrap_or("<zero-crossing>");
                        chatter_store::push(format!(
                            "{}Chattering detected around time {t0}..{t1} ({CHATTER_LIMIT} state \
                             events in a row with a total time delta less than the step size \
                             {step_size}). This can be a performance bottleneck. Use -lv LOG_EVENTS \
                             for more information. The zero-crossing was: {desc}",
                            log_prefix("LOG_STDOUT", "info"),
                        ));
                        if chatter_store::abort() {
                            chatter_store::push(format!(
                                "{}Aborting simulation due to chattering being detected and the \
                                 simulation flags requesting we do not continue further.",
                                log_prefix("LOG_ASSERT", "debug"),
                            ));
                            return Err(CHATTER_ABORT_ERR);
                        }
                    }
                    // pre-event row (before the discrete update), then event +
                    // post-event row.
                    if let Some(r) = rows.as_deref_mut() {
                        capture_pre(e, r, sim_data, layout, troot)?;
                    }
                    event_update(e, sim_data, layout, None, troot)?;
                    if let Some(r) = rows.as_deref_mut() {
                        capture_row(e, r, sim_data, layout)?;
                    }
                    if terminated(e, sim_data, layout)? {
                        return Ok(Step::Terminated);
                    }
                    // Re-read states (a reinit may have jumped one), recompute the
                    // consistent derivative, and restart DASKR at troot (INFO(1)=0).
                    for i in 0..n_states {
                        self.y[i] = read_f64(e, states_base + (i as u32) * 8)?;
                    }
                    e.call1("functionODE", sim_data)?;
                    for i in 0..n_states {
                        self.yp[i] = read_f64(e, ders_base + (i as u32) * 8)?;
                    }
                    self.info[0] = 0;
                    continue;
                }
                // Reached the target with no state event: breaks a chattering run.
                self.note_clean_step();
            }
            // Reached `target`. Fire a sample event at `te` if it lands at or
            // before `tout` (pre-event row, fire, post-event row).
            if te <= tout + eps {
                // Snap an event near `tout` onto it (keeps the final row at `stop`
                // despite float drift).
                let te = if (te - tout).abs() <= eps { tout } else { te };
                *did_step = true;
                if stop_at_event {
                    self.t = te;
                    write_f64(e, sim_data + TIME_OFF, te)?;
                    return Ok(Step::Event { time: te });
                }
                if let Some(r) = rows.as_deref_mut() {
                    emit_row(e, r, sim_data, layout, te)?; // pre-event row (held)
                }
                write_i32(e, sim_data + layout.rel_fresh_off, 1)?; // event: refresh relations
                samp.fire(e, sim_data, te)?;
                store_relations(e, sim_data, layout)?; // advance the hysteresis direction
                self.time_events += 1;
                if let Some(r) = rows.as_deref_mut() {
                    emit_row(e, r, sim_data, layout, te)?;
                }
                if terminated(e, sim_data, layout)? {
                    return Ok(Step::Terminated);
                }
                for i in 0..n_states {
                    self.y[i] = read_f64(e, states_base + (i as u32) * 8)?;
                }
                // A sample may change discrete state the derivative depends on;
                // recompute yp and restart so DASKR continues consistently.
                if layout.n_zc > 0 {
                    e.call1("functionODE", sim_data)?;
                    for i in 0..n_states {
                        self.yp[i] = read_f64(e, ders_base + (i as u32) * 8)?;
                    }
                    self.info[0] = 0;
                }
                if te >= tout - eps {
                    grid_covered = true;
                }
            }
            if target >= tout - eps {
                return Ok(Step::Reached { grid_covered });
            }
        }
    }
}

/// Co-Simulation: the FMU owns the integration, the importer picks the
/// communication points. Unlike [`DasslEventsDriver`] there is no output grid and
/// no rows. [`step_to`](CsDriver::step_to) handles events internally
/// (`eventModeUsed = false`); [`step_to_event`](CsDriver::step_to_event) stops at
/// each event and reports it for the master to drive (`eventModeUsed = true`).
///
/// The caller initializes the model (`run_initialization`) before building this,
/// since FMI does that in its own Initialization Mode.
pub struct CsDriver {
    core: DasslCore,
    samp: Samples,
    pivots: Vec<StateSetPivot>,
    /// `None` = DASSL; `Some(h)` = fixed-step forward Euler with internal step `h`.
    /// Only ever set for event-free models (events force DASSL, as in `make_driver`).
    euler_h: Option<f64>,
    euler_steps: u64,
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
    /// Build over an already-initialized model at time `t`. The integrator follows
    /// `model.method` (`"euler"` → forward Euler, else DASSL), except that any events
    /// force DASSL — the same rule `make_driver` applies.
    pub fn new(e: &mut (dyn SimEngine + 'static), model: &SimModel, sim_data: u32, t: f64) -> Result<Self> {
        daskr::auxiliary::xsetf(0);
        let layout = &model.layout;
        store_relations(e, sim_data, layout)?;
        let samp = Samples::load(e, sim_data, layout)?;
        let mut core = DasslCore::new(model, sim_data, t);
        let mut pivots = init_state_pivots(&model.state_sets);
        if core.n_states > 0 {
            if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut pivots)? {
                e.call1("functionODE", sim_data)?;
            }
            core.read_states(e)?;
        }
        let has_events = layout.n_samples > 0 || layout.n_zc > 0;
        let euler_h = if !has_events && model.method == "euler" {
            let n = model.n_intervals.max(1) as f64;
            let h = (model.stop_time - model.start_time) / n;
            Some(if h > 0.0 { h } else { f64::INFINITY })
        } else {
            None
        };
        Ok(CsDriver { core, samp, pivots, euler_h, euler_steps: 0, resume_reinit: false })
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

        if let Some(h0) = self.euler_h {
            return self.euler_step_to(e, model, t_target, h0);
        }

        let mut ctx = self.core.res_ctx(e, layout);
        let _guard = ResCtxGuard;
        RES_CTX.store(&mut ctx as *mut ResCtx, Ordering::Relaxed);
        let mut did_step = false;
        let outcome = self.core.integrate_to(
            e, model, &mut ctx, &mut self.samp, t_target, f64::INFINITY, None, &mut did_step, false,
        )?;
        self.core.nfe = ctx.nfe;
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
        write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
        write_f64(e, sim_data + TIME_OFF, t_target)?;
        e.call1("functionODE", sim_data)?;
        e.call1_if_present("functionAlgebraics", sim_data)?;
        if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)? {
            e.call1("functionODE", sim_data)?;
            self.core.read_states(e)?;
            self.core.info[0] = 0;
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
                self.core.info[0] = 0;
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

        let mut ctx = self.core.res_ctx(e, layout);
        let _guard = ResCtxGuard;
        RES_CTX.store(&mut ctx as *mut ResCtx, Ordering::Relaxed);
        let mut did_step = false;
        let outcome = self.core.integrate_to(
            e, model, &mut ctx, &mut self.samp, t_target, f64::INFINITY, None, &mut did_step, true,
        )?;
        self.core.nfe = ctx.nfe;
        match outcome {
            Step::Terminated => return Ok(CsStep::Terminated),
            Step::Event { time } => return Ok(CsStep::Event { time }),
            // `deadline` is +inf and CS does not cancel.
            Step::Yielded | Step::Cancelled => return Err("CodegenWasmJit: CS step yielded unexpectedly"),
            Step::Reached { .. } => {}
        }
        // Communication point reached with no event: refresh outputs like `step_to`.
        write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
        write_f64(e, sim_data + TIME_OFF, t_target)?;
        e.call1("functionODE", sim_data)?;
        e.call1_if_present("functionAlgebraics", sim_data)?;
        if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)? {
            e.call1("functionODE", sim_data)?;
            self.core.read_states(e)?;
            self.core.info[0] = 0;
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

    /// Fixed-step forward Euler to `t_target`, sub-stepping by `h0` and landing
    /// exactly on the communication point. Event-free by construction (see `new`),
    /// so it never enters Event Mode; non-convergent NLS is fatal (Euler cannot back
    /// off), matching [`EulerDriver`].
    fn euler_step_to(
        &mut self,
        e: &mut (dyn SimEngine + 'static),
        model: &SimModel,
        t_target: f64,
        h0: f64,
    ) -> Result<CsStep> {
        let layout = &model.layout;
        let sim_data = self.core.sim_data;
        let states_base = self.core.states_base;
        let ders_base = self.core.ders_base;
        let n_states = self.core.n_states as u32;
        let eps = t_target.abs().max(1.0) * 1e-12;
        while self.core.t < t_target - eps {
            let h = (t_target - self.core.t).min(h0);
            write_f64(e, sim_data + TIME_OFF, self.core.t)?;
            e.call1("functionODE", sim_data)?;
            e.call1_if_present("functionAlgebraics", sim_data)?;
            check_nls(e, sim_data, layout)?;
            if terminated(e, sim_data, layout)? {
                return Ok(CsStep::Terminated);
            }
            if !model.state_sets.is_empty()
                && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)?
            {
                e.call1("functionODE", sim_data)?;
            }
            for i in 0..n_states {
                let s = read_f64(e, states_base + i * 8)?;
                let d = read_f64(e, ders_base + i * 8)?;
                write_f64(e, states_base + i * 8, s + h * d)?;
            }
            self.core.t += h;
            self.euler_steps += 1;
        }
        self.core.t = t_target;
        write_f64(e, sim_data + TIME_OFF, t_target)?;
        e.call1("functionODE", sim_data)?;
        e.call1_if_present("functionAlgebraics", sim_data)?;
        if terminated(e, sim_data, layout)? {
            return Ok(CsStep::Terminated);
        }
        Ok(CsStep::Reached)
    }

    pub fn fill_stats(&self, stats: &mut SolveStats) {
        let c = &self.core;
        stats.steps = if self.euler_h.is_some() {
            self.euler_steps
        } else {
            c.iwork.get(10).copied().unwrap_or(0).max(0) as u64
        };
        stats.res_evals = c.nfe;
        stats.state_events = c.state_events;
        stats.time_events = c.time_events;
    }
}

impl DasslEventsDriver {
    fn new(e: &mut (dyn SimEngine + 'static), model: &SimModel, sim_data: u32) -> Result<Self> {
        daskr::auxiliary::xsetf(0);
        let layout = &model.layout;
        // Init (with homotopy fallback). Relation mode 2 and `initSample` are handled
        // inside run_initialization; seed the hysteresis direction from the relations.
        run_initialization(e, sim_data, layout)?;
        store_relations(e, sim_data, layout)?;

        let n_states = layout.n_states as usize;
        let states_base = sim_data + REAL_OFF;
        let n_rows = model.n_intervals + 1;
        let n_reals = layout.n_row_total();
        let start = model.start_time;

        let mut samp = Samples::load(e, sim_data, layout)?;
        let mut rows: Vec<f64> = Vec::with_capacity((n_rows * n_reals) as usize);
        let mut core = DasslCore::new(model, sim_data, start);
        // A sample scheduled exactly at the start time fires before row 0.
        if samp.next_time() <= start + start.abs().max(1.0) * 1e-10 {
            samp.fire(e, sim_data, start)?;
            store_relations(e, sim_data, layout)?;
            core.time_events += 1;
        }
        emit_row(e, &mut rows, sim_data, layout, start)?;
        let pending_terminate = terminated(e, sim_data, layout)?;

        // Dynamic state selection: identity pivots, then re-pivot at the initial
        // point (see `DasslDriver`). A switch reinits states, so refresh derivatives.
        let mut pivots = init_state_pivots(&model.state_sets);
        if n_states > 0 && !pending_terminate {
            if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut pivots)? {
                e.call1("functionODE", sim_data)?;
            }
            core.read_states(e)?;
        }
        let _ = states_base;

        Ok(DasslEventsDriver {
            core,
            row: 1,
            pivots,
            samp,
            rows,
            mid_row: false,
            grid_covered: false,
            pending_terminate,
            finished: false,
        })
    }
}

impl Driver for DasslEventsDriver {
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
        let n_rows = model.n_intervals + 1;
        let n_steps = n_rows - 1;
        let start = model.start_time;
        let stop = model.stop_time;
        let h = if n_steps == 0 { 0.0 } else { (stop - start) / n_steps as f64 };
        let deadline = deadline_from(budget_ms);
        let n_states = self.core.n_states;
        let tout_of = |row: u32| if row == n_steps { stop } else { start + row as f64 * h };

        // No continuous states: nothing to integrate, but zero-crossings on `time`
        // (e.g. a timer `time >= t_start + waitTime`) are still continuous events
        // that must be located between grid points. Walk grid point to grid point,
        // bracketing each state event on a zero-crossing sign change and bisecting to
        // its exact time, interleaved with the sample (time) events in time order.
        if n_states == 0 {
            let mut did_step = false;
            let mut zc0 = vec![0.0f64; layout.n_zc as usize];
            let mut scratch = vec![0.0f64; layout.n_zc as usize];
            if layout.n_zc > 0 {
                eval_zero_crossings(e, sim_data, layout, self.core.t, &mut zc0)?;
            }
            while self.row < n_rows {
                if did_step && past_deadline(deadline) {
                    return Ok(Advance::Running);
                }
                if cancel_requested() {
                    return Ok(Advance::Cancelled);
                }
                did_step = true;
                let tout = tout_of(self.row);
                let eps = tout.abs().max(1.0) * 1e-10;
                let mut grid_covered = false;
                // Handle every event (state or sample) up to `tout`, earliest first.
                loop {
                    let te = self.samp.next_time();
                    let subtarget = tout.min(te);
                    // A state event bracketed in (t, subtarget]?
                    let mut troot = None;
                    if layout.n_zc > 0 && subtarget - self.core.t > eps {
                        eval_zero_crossings(e, sim_data, layout, subtarget, &mut scratch)?;
                        if zc_crossed(&zc0, &scratch) {
                            troot = Some(locate_zc_root(
                                e, sim_data, layout, self.core.t, subtarget, &zc0, &mut scratch,
                            )?);
                        }
                    }
                    if let Some(tr) = troot {
                        capture_pre(e, &mut self.rows, sim_data, layout, tr)?; // pre-event row
                        event_update(e, sim_data, layout, None, tr)?;
                        self.core.state_events += 1;
                        capture_row(e, &mut self.rows, sim_data, layout)?; // post-event row
                        if terminated(e, sim_data, layout)? {
                            self.finished = true;
                            return Ok(Advance::Terminated);
                        }
                        self.core.t = tr;
                        eval_zero_crossings(e, sim_data, layout, tr, &mut zc0)?;
                        continue;
                    }
                    // No state event before the next sample time. Fire the sample if
                    // it is due at or before this grid point; otherwise the interval
                    // is clean up to `tout`.
                    if te <= tout + eps {
                        let te = if (te - tout).abs() <= eps { tout } else { te };
                        write_i32(e, sim_data + layout.rel_fresh_off, 0)?; // held pre row
                        emit_row(e, &mut self.rows, sim_data, layout, te)?; // pre-event row
                        write_i32(e, sim_data + layout.rel_fresh_off, 1)?; // event: refresh
                        self.samp.fire(e, sim_data, te)?;
                        store_relations(e, sim_data, layout)?;
                        self.core.time_events += 1;
                        emit_row(e, &mut self.rows, sim_data, layout, te)?; // post-event row
                        if terminated(e, sim_data, layout)? {
                            self.finished = true;
                            return Ok(Advance::Terminated);
                        }
                        self.core.t = te;
                        if layout.n_zc > 0 {
                            eval_zero_crossings(e, sim_data, layout, te, &mut zc0)?;
                        }
                        if te >= tout - eps {
                            grid_covered = true;
                        }
                    } else {
                        break;
                    }
                }
                if !grid_covered {
                    // Fresh (mode 1) output solve: every event up to `tout` is already
                    // handled above, so no when-edge fires here, while an algebraic loop
                    // (e.g. an ideal-diode network) needs its relations solved fresh.
                    write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
                    emit_row(e, &mut self.rows, sim_data, layout, tout)?;
                    if terminated(e, sim_data, layout)? {
                        self.finished = true;
                        return Ok(Advance::Terminated);
                    }
                    if layout.n_zc > 0 {
                        eval_zero_crossings(e, sim_data, layout, tout, &mut zc0)?;
                    }
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
            if cancel_requested() {
                break Advance::Cancelled;
            }
            let tout = tout_of(self.row);
            if !self.mid_row {
                self.grid_covered = false;
            }
            match self.core.integrate_to(
                e, model, &mut ctx, &mut self.samp, tout, deadline, Some(&mut self.rows), &mut did_step, false,
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
                write_i32(e, sim_data + layout.rel_fresh_off, 1)?;
                did_step = true;
                emit_row(e, &mut self.rows, sim_data, layout, tout)?;
                if terminated(e, sim_data, layout)? {
                    break Advance::Terminated;
                }
            }
            // Re-select states at the accepted output point (see `DasslDriver`).
            if !model.state_sets.is_empty() && run_state_selection(e, sim_data, &model.state_sets, &mut self.pivots)? {
                e.call1("functionODE", sim_data)?;
                for i in 0..n_states {
                    self.core.y[i] = read_f64(e, self.core.states_base + (i as u32) * 8)?;
                    self.core.yp[i] = read_f64(e, self.core.ders_base + (i as u32) * 8)?;
                }
                self.core.info[0] = 0;
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
        let c = &self.core;
        let nst = c.iwork.get(10).copied().unwrap_or(0);
        stats.steps = nst.max(0) as u64;
        stats.res_evals = c.nfe;
        stats.jac_evals = if c.jac_a.is_some() { c.nje } else { c.iwork.get(12).copied().unwrap_or(0).max(0) as u64 };
        stats.err_test_fails = c.iwork.get(13).copied().unwrap_or(0).max(0) as u64;
        stats.conv_test_fails = c.iwork.get(14).copied().unwrap_or(0).max(0) as u64;
        stats.state_events = c.state_events;
        stats.time_events = c.time_events;
    }
}
