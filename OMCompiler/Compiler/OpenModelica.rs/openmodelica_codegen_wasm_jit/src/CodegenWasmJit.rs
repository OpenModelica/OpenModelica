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
    IterSlot, NlsResidual, NlsResiduals, backup_known_outputs, residual_rows, restore_known_outputs,
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

/// Solver statistics, filled by the driver (now `openmodelica_sim_meta`, shared
/// with the in-wasm driver) and rendered here into the `LOG_STATS` block.
pub(crate) use openmodelica_sim_meta::SolveStats;
#[cfg(feature = "jit")]
pub use session::{last_sim_log, sim_advance, sim_free, sim_start};
/// The `wasm32-wasip1` standalone runtime (`_start` + the in-wasm driver in
/// `openmodelica_codegen_wasm_jit_runtime::standalone`), embedded for the native
/// standalone-export path. Empty when omc itself targets wasm32, or when the
/// wasip1 build was unavailable (see `build.rs`); [`emit_standalone_module`] then
/// reports the absence rather than producing a broken module.
#[cfg(not(target_arch = "wasm32"))]
use openmodelica_wasm_jit::RUNTIME_WASIP1;
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
use openmodelica_wasm_jit::{
    external_c_available, EXTERNAL_C_DYLINK, LIBC_PIC, USERTAB_DYLINK, WASI_P1_ADAPTER,
};

// Small shared helpers: list iteration, constant folding of literal
// expressions, expression dumping, file output.
#[path = "CodegenWasmJit/util.rs"]
mod util;
pub(crate) use util::*;

// Process-wide state: the translated models by prefix, the FMU kernels, and
// the last run's captured result series (the web plot API reads them).
#[path = "CodegenWasmJit/registry.rs"]
mod registry;
pub use registry::*;

// MetaModelica-facing entry points: `translateModel`, `runSimulation`,
// `finishCompile`, `emitStandalone`, `runSimulationWasmtime`.
#[path = "CodegenWasmJit/entry.rs"]
mod entry;
pub use entry::*;

// Simulation flags: solver capabilities, `-s` vocabulary, the FMU flag
// vocabulary (`fmuAcceptsFlag`, CS solvers, platforms), simflags parsing.
#[path = "CodegenWasmJit/flags.rs"]
mod flags;
pub use flags::*;

// Running a translated model in-process: experiment settings, overrides,
// start-value imports, the result target and the one-shot `run_simulation_inner`.
#[path = "CodegenWasmJit/run.rs"]
mod run;
use run::*;

// Hooks the embedding installs (web API): `SimStatus`, cancel, clock,
// FMU AOT/loader sources, and the no-engine stubs of the session API.
#[path = "CodegenWasmJit/host_hooks.rs"]
mod host_hooks;
pub use host_hooks::*;

// Standalone WASI command-module export (native only).
#[path = "CodegenWasmJit/standalone.rs"]
mod standalone;
pub use standalone::*;

// The model's own `external "C"` libraries: resolving `Library`/`Include`
// annotations, compiling include sources, dylink needs, search paths.
#[path = "CodegenWasmJit/ext_libs.rs"]
mod ext_libs;
pub(crate) use ext_libs::*;

// Byte-level rewrites of emitted wasm modules: `dylink.0` sections, import
// module renames, dropping imports/exports, scanning imports and exports.
#[path = "CodegenWasmJit/wasm_rewrite.rs"]
mod wasm_rewrite;
use wasm_rewrite::*;

// Externals an exported FMU serves natively: the stub module, the externals
// table and the build description.
#[path = "CodegenWasmJit/native_ext.rs"]
mod native_ext;
use native_ext::*;

// Linking the fmi-ls-wasm component (adapter + model + libraries) and the
// FMI value-reference table.
#[path = "CodegenWasmJit/fmu_link.rs"]
mod fmu_link;
use fmu_link::*;

// In-process ZIP writer (stored + deflate) and the FMU directory packaging.
#[path = "CodegenWasmJit/zip.rs"]
mod zip;
pub use zip::*;

// FMI wasm FMU export: `translateFmu`, `emit_fmu`, kernel lowering, the CS
// method, native platform compilation, model-description patching.
#[path = "CodegenWasmJit/fmu.rs"]
mod fmu;
pub use fmu::*;

// The variable->slot map (`SimVarMap`), scalarization of array variables,
// array/const groups, and the result-variable list.
#[path = "CodegenWasmJit/var_map.rs"]
mod var_map;
pub(crate) use var_map::*;

// Zero crossings, relations, `sample()` and clock collection.
#[path = "CodegenWasmJit/events.rs"]
mod events;
pub(crate) use events::*;

// `build_sim_model`: assembling the model module from the SimCode, plus the
// compiler-flag readers it needs.
#[path = "CodegenWasmJit/model.rs"]
mod model;
pub(crate) use model::*;

// Jacobian sparsity patterns and colorings (NLS, linear, the A matrix).
#[path = "CodegenWasmJit/sparsity.rs"]
mod sparsity;
use sparsity::*;

// `SimMeta` construction: units, start/parameter tables, attribute logs and
// the relation/zero-crossing descriptions.
#[path = "CodegenWasmJit/meta.rs"]
mod meta;
use meta::*;

// Equation-list utilities: flattening, nested equations, parameter
// bindings, assigned crefs, equation indices/kinds, parmod task graph.
#[path = "CodegenWasmJit/equations.rs"]
mod equations;
pub(crate) use equations::*;

// The profiling plan (`-clock`, LOG_PROFILE hooks).
#[path = "CodegenWasmJit/prof.rs"]
mod prof;
use prof::*;

// Lowering equation lists into wasm functions: units, chunking and
// splitting oversized bodies, shared chunks.
#[path = "CodegenWasmJit/eq_fns.rs"]
mod eq_fns;
use eq_fns::*;

// The model's auxiliary exported functions: init/sample, synchronous,
// bound attributes, zero crossings, relations, delay and spatialDistribution.
#[path = "CodegenWasmJit/aux_fns.rs"]
mod aux_fns;
pub(crate) use aux_fns::*;

// Lowering one `SimEqSystem`: assignments, arrays, dynamic tearing and
// linear systems.
#[path = "CodegenWasmJit/lower_eq.rs"]
mod lower_eq;
pub(crate) use lower_eq::*;

// State sets: scratch layout, `StateSetInfo`, the state-set Jacobian.
#[path = "CodegenWasmJit/state_sets.rs"]
mod state_sets;
use state_sets::*;

// Nonlinear systems: parts, jobs, nominal map, the residual/Jacobian
// functions (`build_nls_fns`) and start-value emission.
#[path = "CodegenWasmJit/nls.rs"]
mod nls;
pub(crate) use nls::*;

// Symbolic Jacobian usability for NLS/linear systems: result rows, seeds,
// dimensions, scratch sizes.
#[path = "CodegenWasmJit/nls_jac.rs"]
mod nls_jac;
pub(crate) use nls_jac::*;

// Symbolic Jacobians: the linearization plan, per-system Jacobian
// functions, slot registration, linear-system CSC patterns.
#[path = "CodegenWasmJit/jacobians.rs"]
mod jacobians;
pub(crate) use jacobians::*;

// The in-wasm `simulate` loop and the result-column selection.
#[path = "CodegenWasmJit/simulate_fn.rs"]
mod simulate_fn;
use simulate_fn::*;

#[cfg(feature = "jit")]
#[path = "CodegenWasmJit/session.rs"]
mod session;

// Both link paths (standalone merge, FMU component) are native-only.
#[cfg(test)]
#[cfg(not(target_arch = "wasm32"))]
#[path = "CodegenWasmJit/link_tests.rs"]
mod link_tests;
