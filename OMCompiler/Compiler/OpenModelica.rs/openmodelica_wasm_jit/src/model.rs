//! The prepared model the codegen hands to the engine, and the driver-selection
//! knobs. `SimModel` is built by the codegen and consumed by [`crate::sim_runtime`].

use std::collections::HashMap;
use std::sync::Mutex;

use crate::sig::{ExtCallSig, WTy};
use openmodelica_sim_meta::{JacAInfo, Layout as SimLayout, MetaVar as ResultVar, SimMeta, StateSetInfo};

/// A pending model-module compile: a background-thread join handle natively, an
/// eager result on wasm (no threads).
#[cfg(not(target_arch = "wasm32"))]
pub type ModelCompileJob = std::thread::JoinHandle<Result<crate::sim_runtime::Module, String>>;
#[cfg(target_arch = "wasm32")]
pub type ModelCompileJob = Result<crate::sim_runtime::Module, String>;

/// The prepared, ready-to-run artifact for one model: the in-memory replacement
/// for the C target's `_init.xml` + `_info.json` + the built executable.
pub struct SimModel {
    pub wasm: Vec<u8>,
    pub layout: SimLayout,
    pub result_vars: Vec<ResultVar>,
    /// The `ext.<extName>` host imports (external "C" functions) with the full
    /// C-call shape, so the host trampoline can marshal strings/arrays/pointers.
    pub ext_imports: Vec<ExtCallSig>,
    pub model_name: String,
    pub start_time: f64,
    pub stop_time: f64,
    pub n_intervals: u32,
    pub output_format: String,
    /// Integration method (`"dassl"`, `"euler"`, …); selects the driver in [`crate::sim_runtime::run`].
    pub method: String,
    /// Relative/absolute tolerance for the adaptive integrators (DASSL).
    pub tolerance: f64,
    /// Background JIT job for the model module (joined by `finishCompile` or `runSimulation`).
    pub compiled: Mutex<Option<ModelCompileJob>>,
    /// The compiled model module once joined, so `runSimulation` need not recompile.
    pub prepared: Mutex<Option<crate::sim_runtime::Module>>,
    /// Dynamic state-selection metadata (one per `$STATESET`); empty otherwise.
    pub state_sets: Vec<StateSetInfo>,
    /// ODE state Jacobian ∂f/∂x sparsity + coloring; `None` ⇒ daskr's numerical Jacobian.
    pub jac_a: Option<JacAInfo>,
    /// User-settable initial conditions (changeable parameters), for `-override`.
    pub editable_params: Vec<EditableParam>,
    /// Result-variable display name -> unit, for a host to label plotted signals.
    pub var_units: HashMap<String, String>,
    /// Driver-facing metadata shared with the in-wasm driver (passed to `sim_driver::drive`).
    pub meta: SimMeta,
    /// Pre-rendered `LOG_STDOUT` lines announcing which *linear* systems use a
    /// sparse solver (C's `initializeLinearSystems`), prepended to the sim log.
    pub sparse_solver_log: String,
    /// `(sysNum, equationIndex, size, nnz)` per nonlinear system, in C's array
    /// order. The nonlinear half of that announcement is rendered per run instead,
    /// because `-nlssMinSize`/`-nlssMaxDensity` move the threshold it reports.
    pub nls_systems: Vec<(i32, i32, u32, u32)>,
}

/// A user-settable parameter (an editable initial condition): display name, unit,
/// and `SimData` slot so an `-override=name=value` can write it.
#[derive(Clone)]
pub struct EditableParam {
    pub name: String,
    pub comment: String,
    pub unit: String,
    pub off: u32,
    pub wty: WTy,
    /// A state's start value (vs. a plain parameter): overridden after `functionInitStartValues`.
    pub is_start: bool,
    /// Enumeration literal names (1-based index → name), empty for non-enum.
    pub enum_names: Vec<String>,
}

// ─────────────────────────── driver selection ───────────────────────────

#[cfg(feature = "jit")]
static INWASM_OVERRIDE: std::sync::atomic::AtomicI8 = std::sync::atomic::AtomicI8::new(-1);
#[cfg(feature = "jit")]
static SIM_BENCH_FORCE: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);
#[cfg(feature = "jit")]
static SINGLE_THREADED: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

/// Force the driver choice: `1` in-wasm, `0` host, `-1` default. Wins over the env
/// var and the target default — wasm has no environment.
#[cfg(feature = "jit")]
pub fn set_inwasm_driver_override(mode: i32) {
    INWASM_OVERRIDE.store(mode.clamp(-1, 1) as i8, std::sync::atomic::Ordering::Relaxed);
}

/// Force the bench lines on, for hosts with no `OMC_WASM_SIM_BENCH` to set.
#[cfg(feature = "jit")]
pub fn set_sim_bench(on: bool) {
    SIM_BENCH_FORCE.store(on, std::sync::atomic::Ordering::Relaxed);
}

#[cfg(feature = "jit")]
pub fn sim_bench_enabled() -> bool {
    SIM_BENCH_FORCE.load(std::sync::atomic::Ordering::Relaxed)
        || std::env::var("OMC_WASM_SIM_BENCH").is_ok()
}

/// Set from `-n`: one processor means no background precompile and no parallel
/// module compilation, so each phase is timed where it runs.
#[cfg(feature = "jit")]
pub fn set_single_threaded(on: bool) {
    SINGLE_THREADED.store(on, std::sync::atomic::Ordering::Relaxed);
}

#[cfg(feature = "jit")]
pub fn single_threaded() -> bool {
    SINGLE_THREADED.load(std::sync::atomic::Ordering::Relaxed)
}

/// Whether to run through the in-wasm session driver (`rt_sim_*`) instead of the
/// host driver. wasm32 defaults on; native defaults off (the host driver is the
/// faster parity oracle).
#[cfg(feature = "jit")]
pub fn inwasm_driver_enabled() -> bool {
    match INWASM_OVERRIDE.load(std::sync::atomic::Ordering::Relaxed) {
        0 => return false,
        1 => return true,
        _ => {}
    }
    match std::env::var("OMC_WASM_INWASM_DRIVER").ok().as_deref() {
        Some("0") | Some("false") => false,
        Some(_) => true,
        None => cfg!(target_arch = "wasm32"),
    }
}

/// Encode the host's parameter/start overrides for `rt_sim_set_overrides`.
#[cfg(feature = "jit")]
pub fn encode_overrides() -> Vec<u8> {
    let (params, starts) = crate::sim_driver::param_overrides();
    let mut b = Vec::new();
    for group in [&params, &starts] {
        b.extend_from_slice(&(group.len() as u32).to_le_bytes());
        for &(off, wty, val) in group.iter() {
            b.extend_from_slice(&off.to_le_bytes());
            b.extend_from_slice(&(if matches!(wty, WTy::F64) { 0u32 } else { 1u32 }).to_le_bytes());
            b.extend_from_slice(&val.to_le_bytes());
        }
    }
    b
}

/// Model export names in table-slot order. The runtime's `session::slot_of` derives
/// from the same list, so the two sides cannot drift.
#[cfg(feature = "jit")]
pub const INWASM_SLOT_NAMES: &[&str] = openmodelica_sim_meta::driver::MODEL_FNS;
