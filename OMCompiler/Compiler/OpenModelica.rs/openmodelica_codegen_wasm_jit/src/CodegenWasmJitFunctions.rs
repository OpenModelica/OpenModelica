// Manually written file (the `CodegenWasmJitFunctions` MetaModelica package is a
// placeholder; see HANDWRITTEN_TOP_PACKAGES in mmtorust/src/codegen.rs).
//
// The `wasm-jit` simCodeTarget, function half. Counterpart of
// `CodegenCFunctions` for the C target and of `DynLoad`/`DynLoadExt` for the
// execute side: instead of generating C, building a shared object and
// `dlopen`ing it, the `-d=gen` functions are lowered to a WebAssembly module
// that is JIT-compiled and run in-process with `wasmer`. This skips the
// gcc/clang invocation, which dominates the latency of interactive function
// evaluation.
//
// `translateFunctions` lowers the `SimCodeFunction.FunctionCode` to a `.wasm`
// module (via the `wasm-encoder` crate) plus a small `.wasm.sig` sidecar that
// records the input/output scalar types (the wasm value types alone cannot tell
// Integer from Boolean). `loadAndExecute` reads them back, instantiates the
// module and calls the exported entry `main`, marshalling `Values.Value`s in
// and out.
//
// SCOPE: scalar functions over Integer / Real / Boolean / String (and
// Enumeration literals, treated as their Integer index). Arithmetic,
// comparisons, `if`/`while`/`for`, calls to other generated functions and a
// curated set of math builtins are supported. Strings are reference-counted
// values in the shared runtime's linear memory (see the `rt_*` imports and
// `openmodelica_codegen_wasm_jit_runtime`): literals are materialized from
// passive data segments with `memory.init`, retain/release is inserted by this
// codegen (ownership-based ARC; see `release_heap_locals` / `str_binop`), and
// the string builtins (`+`/concat, comparison, `substring`, `stringLength`,
// `String`/`intString`/`boolString`) lower to runtime calls.
//
// When the `wasm-jit` target is selected it is authoritative: a construct this
// codegen cannot lower is a hard, visible failure (a panic naming the reason),
// NOT a silent degradation to the C target — see `translateFunctions`. Scalars,
// arrays (element-wise/structural ops, slicing, reductions) and records (nested,
// array-valued fields, value-semantic construction) are supported; default
// variable bindings are initialized like the C target's `varInit`. Known gaps
// that still panic today: `String(Real, significantDigits, …)` and any non-zero
// `minimumLength` padding/justification (need printf-style formatting to stay
// byte-identical to the C target), MetaModelica lists, external functions, and
// the remaining items in `HANDOFF.md`.

// The two entry points keep their MetaModelica camelCase names so the generated
// `CevalScript` caller resolves them; the rest of the module is idiomatic Rust.
#![allow(non_snake_case)]

use std::collections::{HashMap, HashSet};
// The record layout is shared with the host, which reads records this code built.
use openmodelica_wasm_jit::sig::{record_layout, RecordLayout};
use std::sync::Arc;

use metamodelica::Result;
use arcstr::ArcStr;
use metamodelica::List;

use openmodelica_ast::Absyn;
use openmodelica_frontend_base::Expression;
use openmodelica_frontend_base::Types;
use openmodelica_frontend_dump::AbsynUtil;
use openmodelica_frontend_dump::ExpressionDumpTpl;
use openmodelica_tpl::Tpl;
use openmodelica_frontend_types::{ClassInf, DAE, Values};
use openmodelica_simcode_types::SimCode;
use openmodelica_simcode_types::SimCodeFunction;

use wasm_encoder as we;

// On wasm32 wasmtime has no backend, so `engine-wasmer` is mandatory there.
#[cfg(all(feature = "jit", target_arch = "wasm32", not(feature = "engine-wasmer")))]
compile_error!("openmodelica_codegen_wasm_jit: the wasm32 target requires `engine-wasmer` (wasmtime has no wasm backend)");

// The execution engine is selected at compile time: wasmtime natively (the
// default/fast path), wasmer when `engine-wasmer` is set or on wasm32 (its `js`
// backend), or a no-engine stub when the `jit` feature is off. Same module
// interface across all three (see the parallel block in CodegenWasmJit.rs).
#[cfg(all(feature = "jit", not(feature = "engine-wasmer"), not(target_arch = "wasm32")))]
#[path = "CodegenWasmJitFunctions/runtime_wasmtime.rs"]
pub(crate) mod runtime;
#[cfg(all(feature = "jit", any(feature = "engine-wasmer", target_arch = "wasm32")))]
#[path = "CodegenWasmJitFunctions/runtime_wasmer.rs"]
pub(crate) mod runtime;
#[cfg(not(feature = "jit"))]
#[path = "CodegenWasmJitFunctions/runtime_stub.rs"]
pub(crate) mod runtime;

/// A wasm value type. MetaModelica `Integer` is the port's `i32`
/// ([[funcbuiltin-i32-intmaxlit]]); `Boolean` and `Enumeration` indices also
/// live in an `i32`; `Real` is an `f64`.
// `WTy` is defined once in `openmodelica_sim_meta` (shared with the in-wasm sim
// driver so the emitted layout and the driver's readback cannot drift). Its
// wasm-encoder `ValType` mapping is host-only, so it lives here as an extension
// trait rather than an inherent method.
pub(crate) use openmodelica_sim_meta::{Neg, WTy};
use openmodelica_sim_meta::clock_field;
pub(crate) use openmodelica_wasm_jit::sig::{ExtCallSig, ExtLang, FnSig, SigTy, WTyVal};

// Diagnostics context: the part/function being lowered and the
// unknown-variable message.
#[path = "CodegenWasmJitFunctions/diag.rs"]
mod diag;
pub(crate) use diag::*;

// The `.wasm.sig` sidecar: parsing and writing signature lines.
#[path = "CodegenWasmJitFunctions/sidecar.rs"]
mod sidecar;
use sidecar::*;

// Import tables: env builtins, env extras, runtime primitives, global
// indices, name mangling.
#[path = "CodegenWasmJitFunctions/imports.rs"]
mod imports;
pub(crate) use imports::*;

// Module assembly: `build_module` lays out imports, memory, globals,
// data segments and exports.
#[path = "CodegenWasmJitFunctions/module.rs"]
mod module;
pub(crate) use module::*;

// Function signatures: main signature types, variable/type -> `SigTy`.
#[path = "CodegenWasmJitFunctions/signatures.rs"]
mod signatures;
pub(crate) use signatures::*;

// External function classification: known, shared and general externals,
// declined reasons, import signatures.
#[path = "CodegenWasmJitFunctions/externals.rs"]
mod externals;
pub(crate) use externals::*;

// Records: declared record fields, object layout, construction, defaults,
// field access and assignment, qualified crefs, element addresses.
#[path = "CodegenWasmJitFunctions/records.rs"]
mod records;
pub(crate) use records::*;

// Codegen contexts and descriptors: `FnCtx`, `SimCtx`, `Literals`,
// `ProfPlan`, `NlsJob`, attribute targets, array/scatter/const groups, slots.
#[path = "CodegenWasmJitFunctions/ctx.rs"]
mod ctx;
pub(crate) use ctx::*;

// Compiling one function: body, locals, outputs, heap release.
#[path = "CodegenWasmJitFunctions/function.rs"]
mod function;
pub(crate) use function::*;

// Calling external C: shared-memory marshalling, known externals, general
// externals, native externals, error catching.
#[path = "CodegenWasmJitFunctions/external_calls.rs"]
mod external_calls;
pub(crate) use external_calls::*;

// Assignments: scalar, tuple, fresh-value stores into locals, fields,
// elements and crefs.
#[path = "CodegenWasmJitFunctions/assign.rs"]
mod assign;
use assign::*;

// Asserts, terminate, model errors, the initial flag, math domain guards.
#[path = "CodegenWasmJitFunctions/errors.rs"]
mod errors;
pub(crate) use errors::*;

// Statements: if/when/else, loops and `for` over ranges and arrays.
#[path = "CodegenWasmJitFunctions/statements.rs"]
mod statements;
use statements::*;

// Ranges, reductions, thread iterators and array comprehensions.
#[path = "CodegenWasmJitFunctions/loops.rs"]
mod loops;
use loops::*;

// Model-variable keys: pre/der/clkpre crefs, `sim_cref_key`, array-ref
// and slice decomposition.
#[path = "CodegenWasmJitFunctions/sim_keys.rs"]
mod sim_keys;
pub(crate) use sim_keys::*;

// Reading/writing model variables: scalars, slices, array/record gather and
// scatter, constant stores, start values.
#[path = "CodegenWasmJitFunctions/sim_access.rs"]
mod sim_access;
pub(crate) use sim_access::*;

// Expression compilation: `compile_exp`, type inference, unary/binary
// operators, division guards.
#[path = "CodegenWasmJitFunctions/expressions.rs"]
mod expressions;
use expressions::*;

// Relations: indexed (event) relations, hysteresis, nominal scaling.
#[path = "CodegenWasmJitFunctions/relations.rs"]
mod relations;
use relations::*;

// Calls: user functions, profiling hooks, spatialDistribution, math events.
#[path = "CodegenWasmJitFunctions/calls.rs"]
mod calls;
pub(crate) use calls::*;

// `compile_math_builtin`: the curated scalar builtins.
#[path = "CodegenWasmJitFunctions/math_builtins.rs"]
mod math_builtins;
use math_builtins::*;

// Strings: concatenation, comparison, substring, `String(...)` formatting,
// enumeration names.
#[path = "CodegenWasmJitFunctions/strings.rs"]
mod strings;
use strings::*;

// Array objects: element addressing, literals, constant runs, ranges.
#[path = "CodegenWasmJitFunctions/array_literals.rs"]
mod array_literals;
use array_literals::*;

// Array operations: element-wise, dot/matmul, indexing, slicing, `size`,
// the array builtins, coercion.
#[path = "CodegenWasmJitFunctions/array_ops.rs"]
mod array_ops;
use array_ops::*;

// MetaModelica entry points: `translateFunctions`, `loadAndExecute`.
#[path = "CodegenWasmJitFunctions/entry.rs"]
mod entry;
pub use entry::*;

#[path = "CodegenWasmJitFunctions/closures.rs"]
pub(crate) mod closures;

#[path = "CodegenWasmJitFunctions/shared_lits.rs"]
pub(crate) mod shared_lits;

#[path = "CodegenWasmJitFunctions/generic_calls.rs"]
mod generic_calls;
pub(crate) use generic_calls::{
    emit_entwined_assign, emit_generic_assign, emit_index_list_loop, emit_resizable_assign,
};

#[path = "CodegenWasmJitFunctions/sim_systems.rs"]
mod sim_systems;
pub(crate) use sim_systems::{
    LSS_MAX_DENSITY, LSS_MIN_SIZE, NLSS_MAX_DENSITY, NLSS_MIN_SIZE, IterSlot, NlsResidual, NlsResiduals,
    backup_known_outputs, residual_rows, restore_known_outputs,
    compile_linear_system, compile_linear_system_analytic, compile_linear_system_analytic_csc,
    compile_linear_system_symbolic, emit_linz_jac_body, emit_nls_jac_body, emit_nls_jac_csc_body,
    emit_ls_bracket, emit_nls_load_body, emit_nls_residual_body, emit_nls_residual_prologue,
    emit_nls_residual_epilogue, emit_nls_residual_store, emit_solve_nls_call, lin_jac_coloring,
    lin_use_sparse, nls_use_sparse,
    emit_dt_solving, emit_dt_local_constraint, emit_dynamic_tearing, emit_nls_strict_body,
};
