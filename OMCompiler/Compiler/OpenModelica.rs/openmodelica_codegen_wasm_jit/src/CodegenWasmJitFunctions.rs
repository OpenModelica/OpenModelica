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

use std::collections::HashMap;
use std::sync::Arc;

use anyhow::{Result, bail};
use arcstr::ArcStr;
use metamodelica::List;

use openmodelica_ast::Absyn;
use openmodelica_frontend_dump::AbsynUtil;
use openmodelica_frontend_types::{ClassInf, DAE, Values};
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
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub(crate) enum WTy {
    I32,
    F64,
}

impl WTy {
    pub(crate) fn val(self) -> we::ValType {
        match self {
            WTy::I32 => we::ValType::I32,
            WTy::F64 => we::ValType::F64,
        }
    }
}

/// One Modelica value type, as the wasm-jit models it and as recorded in the
/// `.wasm.sig` sidecar so `loadAndExecute` can map wasm values back to the right
/// `Values.Value` constructor (an `i32` result is otherwise ambiguous between
/// Integer, Boolean and a heap handle).
///
/// Scalars map to a wasm value type ([`SigTy::wty`]). `Str` and `Array` are
/// reference-counted heap values represented by an `i32` handle into the shared
/// runtime heap. `Array` carries its scalar element type and rank (number of
/// dimensions); Modelica arrays are rectangular, so the rank captures every
/// dimension rather than nesting `Array`s. The element stride, load/store value
/// type, release entry point and marshalling are all derivable from `elem`; the
/// runtime array object additionally records the element kind and the per-axis
/// sizes in its header so a single `rt_array_release` frees nested heap
/// elements and indexing/`size` work for any rank.
#[derive(Clone, PartialEq, Eq, Debug)]
pub(crate) enum SigTy {
    Int,
    Real,
    Bool,
    /// A `String`: an `i32` handle; the bytes live in linear memory.
    Str,
    /// An N-dimensional array of `elem` with `rank` dimensions: an `i32` handle
    /// to a runtime array object (flat row-major storage).
    Array { elem: Arc<SigTy>, rank: u32 },
    /// A record: an `i32` handle to a runtime record object. `path` is the
    /// record's class name (for `Values.RECORD`); `fields` are its components in
    /// declaration order (name + type), which fix the field layout.
    Record { path: ArcStr, fields: Arc<Vec<(ArcStr, SigTy)>> },
}

impl SigTy {
    /// Append this type's `.wasm.sig` encoding to `out`. Scalars are a single
    /// letter; a rank-`k` array is `k` `'['`s followed by its scalar element
    /// encoding (e.g. `"[R"` for `Real[:]`, `"[[I"` for `Integer[:,:]`). The
    /// `'['` prefix lets the reader consume one whole type without separators
    /// ([`parse_sig_types`]).
    fn write_code(&self, out: &mut String) {
        match self {
            SigTy::Int => out.push('I'),
            SigTy::Real => out.push('R'),
            SigTy::Bool => out.push('B'),
            SigTy::Str => out.push('S'),
            SigTy::Array { elem, rank } => {
                for _ in 0..*rank {
                    out.push('[');
                }
                elem.write_code(out);
            }
            // `{path;name:code;name:code…}` — a record, brace-delimited so the
            // reader can consume one whole (possibly nested) record type. Names
            // and dotted paths never contain `{};:` so those are safe delimiters.
            SigTy::Record { path, fields } => {
                out.push('{');
                out.push_str(path);
                for (name, code) in fields.iter() {
                    out.push(';');
                    out.push_str(name);
                    out.push(':');
                    code.write_code(out);
                }
                out.push('}');
            }
        }
    }
    pub(crate) fn wty(&self) -> WTy {
        match self {
            SigTy::Int | SigTy::Bool | SigTy::Str | SigTy::Array { .. } | SigTy::Record { .. } => WTy::I32,
            SigTy::Real => WTy::F64,
        }
    }
    /// The runtime element-kind tag stored in an array header when this type is
    /// the array's element. Must stay in sync with the runtime's `EK_*` constants.
    fn elem_kind(&self) -> u32 {
        match self {
            SigTy::Int => 0,
            SigTy::Real => 1,
            SigTy::Bool => 2,
            SigTy::Str => 3,
            SigTy::Array { .. } => 4,
            SigTy::Record { .. } => 5,
        }
    }
    /// The runtime release entry point for a heap value of this type, or `None`
    /// for a non-heap scalar. Used wherever an owned heap value is freed.
    fn release_fn(&self) -> Option<&'static str> {
        match self {
            SigTy::Str => Some("rt_release"),
            SigTy::Array { .. } => Some("rt_array_release"),
            SigTy::Record { .. } => Some("rt_record_release"),
            _ => None,
        }
    }
    /// Whether this is a reference-counted heap value (needs ARC on
    /// assignment / at scope exit).
    fn is_heap(&self) -> bool {
        self.release_fn().is_some()
    }
}

/// Parse one `.wasm.sig` line into a list of [`SigTy`]s (see [`SigTy::write_code`]
/// for the encoding). Types are concatenated without separators; an `'['`
/// consumes the following type as its array element.
fn parse_sig_types(line: &str) -> Result<Vec<SigTy>> {
    let mut chars = line.chars().peekable();
    let mut out = Vec::new();
    while chars.peek().is_some() {
        out.push(parse_sig_type(&mut chars)?);
    }
    Ok(out)
}

fn parse_sig_type(chars: &mut std::iter::Peekable<std::str::Chars>) -> Result<SigTy> {
    match chars.next() {
        Some('I') => Ok(SigTy::Int),
        Some('R') => Ok(SigTy::Real),
        Some('B') => Ok(SigTy::Bool),
        Some('S') => Ok(SigTy::Str),
        Some('[') => {
            // Consecutive `'['`s are the rank of one array (Modelica arrays are
            // rectangular, so the element after them is a scalar, never another
            // array).
            let mut rank = 1u32;
            while chars.peek() == Some(&'[') {
                chars.next();
                rank += 1;
            }
            Ok(SigTy::Array { elem: Arc::new(parse_sig_type(chars)?), rank })
        }
        // `{path;name:code;…}` — a record (see [`SigTy::write_code`]).
        Some('{') => {
            let mut path = String::new();
            while !matches!(chars.peek(), Some(&';') | Some(&'}') | None) {
                path.push(chars.next().unwrap());
            }
            let mut fields = Vec::new();
            while chars.peek() == Some(&';') {
                chars.next(); // ';'
                let mut name = String::new();
                loop {
                    match chars.next() {
                        Some(':') => break,
                        Some(c) => name.push(c),
                        None => bail!("CodegenWasmJit: unterminated record field in signature"),
                    }
                }
                fields.push((ArcStr::from(name.as_str()), parse_sig_type(chars)?));
            }
            match chars.next() {
                Some('}') => {}
                other => bail!("CodegenWasmJit: expected `}}` in record signature, got {other:?}"),
            }
            Ok(SigTy::Record { path: ArcStr::from(path.as_str()), fields: Arc::new(fields) })
        }
        other => bail!("CodegenWasmJit: malformed signature type code {other:?}"),
    }
}

/// Host-imported math builtins, in a fixed order so their wasm function indices
/// are stable: index `i` is `BUILTINS[i]`. Every generated module imports all
/// of them from module `"env"` (the runtime `Linker` provides them all); unused
/// imports cost nothing at runtime. Builtins implementable with a single wasm
/// instruction (`sqrt`, `abs`, `floor`, `ceil`, `min`, `max`, …) are emitted
/// inline instead and are not in this table.
pub(crate) const BUILTINS: &[(&str, &[WTy], WTy)] = &[
    ("pow", &[WTy::F64, WTy::F64], WTy::F64),
    ("atan2", &[WTy::F64, WTy::F64], WTy::F64),
    ("sin", &[WTy::F64], WTy::F64),
    ("cos", &[WTy::F64], WTy::F64),
    ("tan", &[WTy::F64], WTy::F64),
    ("asin", &[WTy::F64], WTy::F64),
    ("acos", &[WTy::F64], WTy::F64),
    ("atan", &[WTy::F64], WTy::F64),
    ("sinh", &[WTy::F64], WTy::F64),
    ("cosh", &[WTy::F64], WTy::F64),
    ("tanh", &[WTy::F64], WTy::F64),
    ("exp", &[WTy::F64], WTy::F64),
    ("log", &[WTy::F64], WTy::F64),
    ("log10", &[WTy::F64], WTy::F64),
    // libm functions reached as `external "C"` math functions (these are *not*
    // inlined to a Modelica builtin by the frontend, unlike sin/cos/exp/…), routed
    // to the host's libm via `external_function` lowering.
    ("cbrt", &[WTy::F64], WTy::F64),
    ("expm1", &[WTy::F64], WTy::F64),
    ("log1p", &[WTy::F64], WTy::F64),
    ("exp2", &[WTy::F64], WTy::F64),
    ("log2", &[WTy::F64], WTy::F64),
    ("asinh", &[WTy::F64], WTy::F64),
    ("acosh", &[WTy::F64], WTy::F64),
    ("atanh", &[WTy::F64], WTy::F64),
    ("hypot", &[WTy::F64, WTy::F64], WTy::F64),
    ("fmod", &[WTy::F64, WTy::F64], WTy::F64),
];

fn builtin_index(name: &str) -> Option<u32> {
    BUILTINS.iter().position(|(n, _, _)| *n == name).map(|i| i as u32)
}

/// Extra host imports (module `"env"`) that the generated code calls but which
/// are *not* pure-math `BUILTINS` — they have their own signatures and host-side
/// effects. Imported *after* the [`BUILTINS`] and the [`RT_BUILTINS`] (so the
/// `rt_*` indices are unaffected), just before the generated functions. The host
/// closures live in `runtime::add_host_builtins`.
///
/// `rt_assert(msg, file, sline, scol, eline, ecol, isReadOnly)` records a pending
/// assertion failure (the message and source-info handles) for `load_and_execute`
/// to route to the error buffer; the generated code then traps (`unreachable`).
pub(crate) const ENV_EXTRA: &[(&str, &[WTy], &[WTy])] = &[(
    "rt_assert",
    &[WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32],
    &[],
)];

/// Absolute wasm function index of an `ENV_EXTRA` import (after the `BUILTINS`
/// and `RT_BUILTINS`).
fn env_extra_index(name: &str) -> u32 {
    let pos = ENV_EXTRA
        .iter()
        .position(|(n, _, _)| *n == name)
        .unwrap_or_else(|| panic!("CodegenWasmJit: unknown env-extra import `{name}`"));
    (BUILTINS.len() + RT_BUILTINS.len() + pos) as u32
}

/// Heap-runtime functions imported from the precompiled runtime module `"rt"`
/// (see `openmodelica_codegen_wasm_jit_runtime`), in a fixed order so their wasm
/// function indices are stable. They are imported *after* the [`BUILTINS`], so
/// function index `i` is `rt_index(RT_BUILTINS[i].0)`. The result column is a
/// slice so void functions (`rt_retain`/`rt_release`) can be expressed. The
/// runtime's `memory` is imported separately (it is not a function).
pub(crate) const RT_BUILTINS: &[(&str, &[WTy], &[WTy])] = &[
    ("rt_retain", &[WTy::I32], &[]),
    ("rt_release", &[WTy::I32], &[]),
    ("rt_str_new", &[WTy::I32], &[WTy::I32]),
    ("rt_str_len", &[WTy::I32], &[WTy::I32]),
    ("rt_str_data", &[WTy::I32], &[WTy::I32]),
    ("rt_concat", &[WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_streq", &[WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_strcmp", &[WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_substring", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_int_string", &[WTy::I32], &[WTy::I32]),
    ("rt_real_string", &[WTy::F64], &[WTy::I32]),
    ("rt_bool_string", &[WTy::I32], &[WTy::I32]),
    // `String(Real, significantDigits, minimumLength, leftJustified)` (C `%g`),
    // and space-padding for `String(Integer/Boolean/Enumeration, minLength,
    // leftJustified)`.
    ("rt_real_format", &[WTy::F64, WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_str_pad", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    // N-dimensional arrays: allocate (elem_kind, ndims, total), set a dimension
    // size, query ndims / total / a dimension, element byte address by row-major
    // linear index (1-based, bounds-checked), and refcount release (frees nested
    // heap elements first).
    ("rt_array_new", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_array_set_dim", &[WTy::I32, WTy::I32, WTy::I32], &[]),
    ("rt_array_ndims", &[WTy::I32], &[WTy::I32]),
    ("rt_array_total", &[WTy::I32], &[WTy::I32]),
    ("rt_array_dim", &[WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_array_elem_ptr", &[WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_array_release", &[WTy::I32], &[]),
    // Value-semantics copy (for whole-array assignment from a variable source).
    ("rt_array_copy", &[WTy::I32], &[WTy::I32]),
    // Element-wise builtins: fill (zeros/ones), and reductions sum/product/min/max.
    ("rt_array_fill_i32", &[WTy::I32, WTy::I32], &[]),
    ("rt_array_fill_f64", &[WTy::I32, WTy::F64], &[]),
    ("rt_array_sum_i32", &[WTy::I32], &[WTy::I32]),
    ("rt_array_sum_f64", &[WTy::I32], &[WTy::F64]),
    ("rt_array_product_i32", &[WTy::I32], &[WTy::I32]),
    ("rt_array_product_f64", &[WTy::I32], &[WTy::F64]),
    ("rt_array_extreme_i32", &[WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_array_extreme_f64", &[WTy::I32, WTy::I32], &[WTy::F64]),
    // Records: allocate (nheap, total size; refcount 1, zeroed), refcount release
    // (frees nested heap fields via the inline table), and value-semantics copy.
    // Field access needs no call — the codegen loads/stores at a constant offset.
    ("rt_record_new", &[WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_record_release", &[WTy::I32], &[]),
    ("rt_record_copy", &[WTy::I32], &[WTy::I32]),
    // Element-wise array arithmetic (op: 0 add, 1 sub, 2 mul, 3 div): array op
    // array, scalar broadcast (`rev` swaps operand order), and negation.
    ("rt_array_ew_i32", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_array_ew_f64", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_array_scalar_i32", &[WTy::I32, WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_array_scalar_f64", &[WTy::I32, WTy::F64, WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_array_neg_i32", &[WTy::I32], &[WTy::I32]),
    ("rt_array_neg_f64", &[WTy::I32], &[WTy::I32]),
    ("rt_array_transpose", &[WTy::I32], &[WTy::I32]),
    ("rt_array_identity", &[WTy::I32], &[WTy::I32]),
    ("rt_array_diagonal", &[WTy::I32], &[WTy::I32]),
    ("rt_array_linspace", &[WTy::F64, WTy::F64, WTy::I32], &[WTy::I32]),
    // Slice / partial-index `a[i, :, lo:hi, ...]` of a dynamic-dimension array:
    // (src, nspec, spec) where `spec` is an Integer array of (kind, value) pairs
    // per source axis (kind 0 INDEX, 1 WHOLE, 2 SLICE). Returns a fresh array.
    ("rt_array_slice", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    // `cat(dim, a1, ..., an)`: (dim, n, handles) where `handles` is an Integer
    // array of the `n` input array handles. Returns a fresh concatenated array.
    ("rt_array_cat", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    // Scalar (dot) product `v1 * v2` of two numeric vectors -> a scalar.
    ("rt_array_dot_f64", &[WTy::I32, WTy::I32], &[WTy::F64]),
    ("rt_array_dot_i32", &[WTy::I32, WTy::I32], &[WTy::I32]),
    // Matrix product `a * b` (matrix·matrix / matrix·vector / vector·matrix) ->
    // a fresh array (rank a.ndims + b.ndims - 2).
    ("rt_array_matmul_f64", &[WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_array_matmul_i32", &[WTy::I32, WTy::I32], &[WTy::I32]),
    // `base ^ n` for an integer exponent (matches the C `real_int_pow` so scalar
    // integer powers stay byte-identical instead of going through generic pow).
    ("rt_real_int_pow", &[WTy::F64, WTy::I32], &[WTy::F64]),
    // `base ^ exp` generic scalar power matching the C target's negative-base /
    // odd-root / nan-inf handling (traps on an invalid root, surfacing fail()).
    ("rt_real_pow", &[WTy::F64, WTy::F64], &[WTy::F64]),
    // Integer `mod(x,y)` — floored modulo (result takes the divisor's sign).
    ("rt_mod_int", &[WTy::I32, WTy::I32], &[WTy::I32]),
    // Shape / geometric array builtins: vector / matrix reshape, symmetric,
    // cross (Real 3-vector), outerProduct, skew (Real 3-vector → 3x3).
    ("rt_array_vector", &[WTy::I32], &[WTy::I32]),
    ("rt_array_matrix", &[WTy::I32], &[WTy::I32]),
    ("rt_array_symmetric", &[WTy::I32], &[WTy::I32]),
    ("rt_array_cross_f64", &[WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_array_outer_f64", &[WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_array_skew_f64", &[WTy::I32], &[WTy::I32]),
    // promote(a, n): add trailing size-1 dimensions to reach rank n.
    ("rt_array_promote", &[WTy::I32, WTy::I32], &[WTy::I32]),
    // Integer[] -> Real[] element-wise cast (the implicit numeric array cast).
    ("rt_array_int_to_real", &[WTy::I32], &[WTy::I32]),
    // Element-wise logical `not` over a Boolean array.
    ("rt_array_not_i32", &[WTy::I32], &[WTy::I32]),
    // Simulation primitives (wasm-jit simulation target). `rt_euler_step` does
    // the in-place forward-Euler update `state[i] += h*der[i]`; `rt_sim_store_row`
    // copies the `n_reals`-f64 time-variant prefix of the `SimData` block into
    // the result buffer at a row index. See `CodegenWasmJit` and the runtime.
    ("rt_euler_step", &[WTy::I32, WTy::I32, WTy::F64], &[]),
    ("rt_sim_store_row", &[WTy::I32, WTy::I32, WTy::I32, WTy::I32], &[]),
    // Raw allocator (used by the emitted `simulate` loop to allocate the result
    // buffer). The function half reaches the allocator only indirectly (via
    // `rt_str_new`/`rt_array_new`), so it is imported here for the first time.
    ("rt_alloc", &[WTy::I32], &[WTy::I32]),
    // Copy all elements of `src` into `dst` at a 0-based element offset (used to
    // build an array constructor whose elements are themselves arrays).
    ("rt_array_blit", &[WTy::I32, WTy::I32, WTy::I32], &[]),
    // `String(Real, format)` (the format-string variant): (value, format-string
    // handle) -> formatted String. Borrows the format handle.
    ("rt_string_format_real", &[WTy::F64, WTy::I32], &[WTy::I32]),
    // `String(Integer, format)`: (value, format-string handle) -> formatted
    // String (Booleans are coerced to 0/1 i32). Borrows the format handle.
    ("rt_string_format_int", &[WTy::I32, WTy::I32], &[WTy::I32]),
    // Dense linear solve `A x = b` in place (A column-major `n*n` f64 at a_ptr,
    // b `n` f64 at b_ptr; solution overwrites b). Returns 0 ok, 1 singular.
    ("rt_linsolve", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    // Raw deallocation (frees a block from `rt_alloc`); used to release the
    // `SES_LINEAR` scratch (A/b/residual buffers) after each solve.
    ("rt_free", &[WTy::I32], &[]),
];

/// Absolute wasm function index of a runtime import (after all [`BUILTINS`]).
pub(crate) fn rt_index(name: &str) -> u32 {
    let pos = RT_BUILTINS
        .iter()
        .position(|(n, _, _)| *n == name)
        .unwrap_or_else(|| panic!("CodegenWasmJit: unknown runtime function {name}"));
    (BUILTINS.len() + pos) as u32
}

/// `_`-mangled name of a function path, matching `CevalScript`'s
/// `generateFunctionName` (`AbsynUtil.pathStringUnquoteReplaceDot(path, "_")`).
/// Used as the key that resolves a `CALL` to one of the generated functions.
pub(crate) fn mangle(path: &Absyn::Path) -> Result<String> {
    Ok(AbsynUtil::pathStringUnquoteReplaceDot(Arc::new(path.clone()), arcstr::literal!("_"))?.to_string())
}

// -------------------------------------------------------------------------
// Module assembly
// -------------------------------------------------------------------------

/// Signature of a generated wasm function: parameter and result Modelica types
/// (`SigTy`, so String parameters/results are distinguishable for reference
/// counting; the wasm value types are `SigTy::wty`).
#[derive(Clone)]
pub(crate) struct FnSig {
    pub(crate) params: Vec<SigTy>,
    pub(crate) results: Vec<SigTy>,
}

/// Everything the second pass needs to resolve a `CALL` to another generated
/// function: its final wasm function index and signature.
pub(crate) struct FnInfo {
    pub(crate) index: u32,
    pub(crate) sig: FnSig,
}

/// Build the wasm module for `fnCode`. Returns the encoded module bytes and the
/// input/output `SigTy`s of the main function (for the sidecar).
fn build_module(fn_code: &SimCodeFunction::FunctionCode) -> Result<(Vec<u8>, Vec<SigTy>, Vec<SigTy>)> {
    // Collect the functions: the main function first (wasm index BUILTINS.len()),
    // then the dependencies.
    let mut funcs: Vec<&SimCodeFunction::Function::Function> = Vec::new();
    let Some(main) = &fn_code.mainFunction else {
        bail!("CodegenWasmJit: function code has no main function");
    };
    funcs.push(&**main);
    for f in &*fn_code.functions {
        // Plain Modelica functions, plus known scalar-math external functions
        // (lowered to a host-builtin call). Record constructors arrive as
        // `RECORD_CONSTRUCTOR` but are lowered inline (`E::RECORD`), and unknown
        // external / function-pointer dependencies cannot be JITed and, if
        // actually called, fail loudly at that call site instead.
        if matches!(&**f, SimCodeFunction::Function::Function::FUNCTION { .. }) || external_known(f) {
            funcs.push(&**f);
        }
    }

    // Imported functions occupy the low function indices: the `env` math
    // builtins, then the `rt` heap-runtime functions; generated functions
    // follow. (The imported `memory` has its own index space and does not
    // shift function indices.)
    let base = (BUILTINS.len() + RT_BUILTINS.len() + ENV_EXTRA.len()) as u32;
    // Map mangled function name -> (local id, signature) so CALLs can resolve.
    let mut by_name: HashMap<String, FnInfo> = HashMap::new();
    let mut sigs: Vec<FnSig> = Vec::with_capacity(funcs.len());
    for (id, f) in funcs.iter().enumerate() {
        let (name, sig) = function_signature(f)?;
        by_name.insert(name, FnInfo { index: base + id as u32, sig: sig.clone() });
        sigs.push(sig);
    }

    // Type section: one type per env builtin, per rt builtin, then per
    // generated function (matching the import + function order).
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
    for sig in &sigs {
        types.ty().function(sig.params.iter().map(|s| s.wty().val()), sig.results.iter().map(|s| s.wty().val()));
    }

    // Import section: the runtime's shared linear memory, the `env` math
    // builtins, then the `rt` heap-runtime functions. Type indices line up with
    // the type section above.
    let mut imports = we::ImportSection::new();
    imports.import(
        "rt",
        "memory",
        we::MemoryType { minimum: 0, maximum: None, memory64: false, shared: false, page_size_log2: None },
    );
    for (i, (name, _, _)) in BUILTINS.iter().enumerate() {
        imports.import("env", *name, we::EntityType::Function(i as u32));
    }
    for (j, (name, _, _)) in RT_BUILTINS.iter().enumerate() {
        imports.import("rt", *name, we::EntityType::Function((BUILTINS.len() + j) as u32));
    }
    for (k, (name, _, _)) in ENV_EXTRA.iter().enumerate() {
        imports.import("env", *name, we::EntityType::Function((BUILTINS.len() + RT_BUILTINS.len() + k) as u32));
    }

    // Compile the function bodies first (collecting any String literals into a
    // module-wide pool), so the data-segment count is known before the code
    // section is emitted.
    let mut functions = we::FunctionSection::new();
    let mut bodies: Vec<we::Function> = Vec::with_capacity(funcs.len());
    let mut literals: Vec<Vec<u8>> = Vec::new();
    for (id, f) in funcs.iter().enumerate() {
        functions.function(base + id as u32); // type index = base + id
        bodies.push(compile_function(f, &by_name, &mut literals)?);
    }
    let mut code = we::CodeSection::new();
    for body in &bodies {
        code.function(body);
    }

    // Export the main function as "main".
    let mut exports = we::ExportSection::new();
    exports.export("main", we::ExportKind::Func, base);

    let mut module = we::Module::new();
    module.section(&types);
    module.section(&imports);
    module.section(&functions);
    module.section(&exports);
    // String literals become passive data segments materialized at runtime with
    // `memory.init` (see SCONST in `compile_exp`). The DataCount section must
    // precede the code section; the Data section follows it.
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
    let bytes = module.finish();

    // Signature types of the main function for the sidecar.
    let (in_sig, out_sig) = main_sig_types(main)?;
    Ok((bytes, in_sig, out_sig))
}

/// The mangled name and wasm signature of a generated function.
pub(crate) fn function_signature(f: &SimCodeFunction::Function::Function) -> Result<(String, FnSig)> {
    use SimCodeFunction::Function::Function as F;
    match f {
        F::FUNCTION { name, outVars, functionArguments, .. } => {
            let params = var_sigtys(functionArguments)?;
            let results = var_sigtys(outVars)?;
            Ok((mangle(name)?, FnSig { params, results }))
        }
        // A known scalar-math `external "C"`/"builtin" function is lowered to a
        // wasm function calling the corresponding host import ([Approach C]).
        F::EXTERNAL_FUNCTION { name, outVars, funArgs, .. } if external_known(f) => {
            let params = var_sigtys(funArgs)?;
            let results = var_sigtys(outVars)?;
            Ok((mangle(name)?, FnSig { params, results }))
        }
        _ => bail!("CodegenWasmJit: only plain Modelica/MetaModelica FUNCTIONs and known scalar-math external functions are supported"),
    }
}

/// Whether an `external "C"`/"builtin" function maps to a known host math builtin
/// we can route (Approach C, name-based). Only simple return-style scalar
/// functions — `output := extName(inputs)`, all-scalar args/result, no
/// output-pointer arguments — qualify; arrays, output-arg style, or an unknown
/// `extName` are left to fail loudly (the array/library ABI is future work).
pub(crate) fn external_known(f: &SimCodeFunction::Function::Function) -> bool {
    use SimCodeFunction::SimExtArg::SimExtArg as A;
    let SimCodeFunction::Function::Function::EXTERNAL_FUNCTION { extName, funArgs, outVars, extReturn, extArgs, .. } = f else {
        return false;
    };
    // One output, produced as the C call's return value (not via an output ptr).
    if (&**outVars).into_iter().count() != 1 || matches!(&**extReturn, A::SIMNOEXTARG) {
        return false;
    }
    // Every external-call argument must be an input (or a constant exp), never an
    // output pointer or a size argument.
    let args_ok = (&**extArgs).into_iter().all(|a| match &**a {
        A::SIMEXTARG { isInput, .. } => *isInput,
        A::SIMEXTARGEXP { .. } => true,
        _ => false,
    });
    if !args_ok {
        return false;
    }
    let (Ok(ins), Ok(outs)) = (var_sigtys(funArgs), var_sigtys(outVars)) else {
        return false;
    };
    supported_external(extName, &ins, &outs[0])
}

/// Whether external function `ext_name` with input types `ins` and result type
/// `out` is one this codegen can route (Approach C, name-based). Covers scalar
/// libm math (host builtins / inline) and the pure `ModelicaStrings` functions
/// that map directly to existing runtime string ops.
fn supported_external(ext_name: &str, ins: &[SigTy], out: &SigTy) -> bool {
    let scalar = |s: &SigTy| matches!(s, SigTy::Int | SigTy::Real | SigTy::Bool);
    match ext_name {
        // `Modelica.Utilities.Strings.length` → `rt_str_len`.
        "ModelicaStrings_length" => matches!(ins, [SigTy::Str]) && matches!(out, SigTy::Int),
        // `Modelica.Utilities.Strings.substring` → `rt_substring` (1-based incl.).
        "ModelicaStrings_substring" => matches!(ins, [SigTy::Str, SigTy::Int, SigTy::Int]) && matches!(out, SigTy::Str),
        // Scalar math: a host transcendental or single-instruction math function.
        _ if builtin_index(ext_name).is_some() || matches!(ext_name, "sqrt" | "fabs" | "floor" | "ceil") => {
            ins.iter().all(scalar) && scalar(out)
        }
        _ => false,
    }
}

/// The input/output scalar `SigTy`s of the main function, for the sidecar.
fn main_sig_types(f: &SimCodeFunction::Function::Function) -> Result<(Vec<SigTy>, Vec<SigTy>)> {
    use SimCodeFunction::Function::Function as F;
    match f {
        F::FUNCTION { outVars, functionArguments, .. } => Ok((var_sigtys(functionArguments)?, var_sigtys(outVars)?)),
        F::EXTERNAL_FUNCTION { outVars, funArgs, .. } if external_known(f) => Ok((var_sigtys(funArgs)?, var_sigtys(outVars)?)),
        _ => bail!("CodegenWasmJit: only plain FUNCTIONs and known scalar-math external functions are supported"),
    }
}

fn var_sigtys(vars: &Arc<List<Arc<SimCodeFunction::Variable::Variable>>>) -> Result<Vec<SigTy>> {
    let mut out = Vec::new();
    for v in &**vars {
        let SimCodeFunction::Variable::Variable::VARIABLE { ty, instDims, .. } = &**v else {
            bail!("CodegenWasmJit: unsupported variable kind (function pointer)");
        };
        out.push(variable_sigty(ty, instDims)?);
    }
    Ok(out)
}

/// The `SigTy` of a function variable, combining its declared `ty` with its
/// `instDims`. SimCode is inconsistent about where array dimensions live: an
/// input array's `ty` is the full `T_ARRAY`, while an output/local array's `ty`
/// is the scalar element type with the dimensions in `instDims`. So a `T_ARRAY`
/// `ty` is authoritative (its `dims` are complete); otherwise a non-empty
/// `instDims` makes the scalar `ty` the element type of a rank-`|instDims|` array.
fn variable_sigty(ty: &DAE::Type, inst_dims: &Arc<List<Arc<DAE::Dimension>>>) -> Result<SigTy> {
    let base = sig_ty(ty)?;
    if matches!(base, SigTy::Array { .. }) {
        return Ok(base);
    }
    let rank = (&**inst_dims).into_iter().count() as u32;
    if rank == 0 {
        Ok(base)
    } else {
        Ok(SigTy::Array { elem: Arc::new(base), rank })
    }
}

/// Map a `DAE.Type` to a `SigTy`, or fail for types not yet supported.
pub(crate) fn sig_ty(ty: &DAE::Type) -> Result<SigTy> {
    Ok(match ty {
        DAE::Type::T_INTEGER { .. } => SigTy::Int,
        DAE::Type::T_REAL { .. } => SigTy::Real,
        DAE::Type::T_BOOL { .. } => SigTy::Bool,
        // An enumeration value is its 1-based Integer index.
        DAE::Type::T_ENUMERATION { .. } => SigTy::Int,
        DAE::Type::T_STRING { .. } => SigTy::Str,
        // An N-dimensional array. A `T_ARRAY` usually carries all dimensions in
        // `dims` (so `Real[2,3]` is one `T_ARRAY` with two dims), but a nested
        // `T_ARRAY` element is also possible; both flatten to a single rank
        // since Modelica arrays are rectangular.
        DAE::Type::T_ARRAY { ty, dims } => {
            let ndims = (&**dims).into_iter().count() as u32;
            match sig_ty(ty)? {
                SigTy::Array { elem, rank } => SigTy::Array { elem, rank: rank + ndims },
                elem => SigTy::Array { elem: Arc::new(elem), rank: ndims },
            }
        }
        // A record class: an ordered set of component fields. MetaModelica
        // uniontypes / metarecords (`T_METARECORD`) are a different runtime
        // representation and are not handled here.
        DAE::Type::T_COMPLEX { complexClassType, varLst, .. } => {
            let ClassInf::State::RECORD { path } = complexClassType else {
                bail!("CodegenWasmJit: non-record complex type not supported: {complexClassType:?}");
            };
            let path_str = AbsynUtil::pathString(path.clone(), arcstr::literal!("."), true, false)?;
            let mut fields = Vec::new();
            for v in &**varLst {
                fields.push((v.name.clone(), sig_ty(&v.ty)?));
            }
            SigTy::Record { path: path_str, fields: Arc::new(fields) }
        }
        DAE::Type::T_SUBTYPE_BASIC { .. } => bail!("CodegenWasmJit: subtype-basic types not yet supported"),
        other => bail!("CodegenWasmJit: type not supported: {other:?}"),
    })
}

// -------------------------------------------------------------------------
// Function-body compilation
// -------------------------------------------------------------------------

/// Per-function compilation state.
pub(crate) struct FnCtx<'a> {
    /// ident -> (local index, Modelica type). Inputs are the wasm params
    /// (indices `0..n_params`); outputs and locals follow.
    locals: HashMap<String, (u32, SigTy)>,
    /// Wasm types of every non-parameter local (for `Function::new`), in index
    /// order starting at `n_params`.
    extra_locals: Vec<we::ValType>,
    n_params: u32,
    /// Output local indices, pushed (in order) before every `return`.
    outputs: Vec<(u32, SigTy)>,
    /// Resolves a `CALL` to another generated function.
    by_name: &'a HashMap<String, FnInfo>,
    /// Module-wide String-literal pool; index = passive data-segment index.
    literals: &'a mut Vec<Vec<u8>>,
    instrs: Vec<we::Instruction<'static>>,
    /// Number of currently-open structured-control frames (`block`/`loop`/`if`),
    /// maintained automatically by [`FnCtx::emit`]. A relative branch index to a
    /// frame opened at level `L` is `ctrl_depth - L` (see [`FnCtx::branch_to`]).
    ctrl_depth: u32,
    /// Stack of enclosing loops, innermost last: `(break_level, continue_level)`,
    /// the `ctrl_depth` values of the loop's break-target and continue-target
    /// blocks. Drives `break`/`continue` (`STMT_BREAK`/`STMT_CONTINUE`).
    loops: Vec<(u32, u32)>,
    /// Heap locals that hold a *borrowed* reference (not owned), so they must be
    /// skipped by `release_heap_locals` — currently the `for x in array` iterator,
    /// which aliases an element of the array that outlives the loop.
    borrowed_locals: Vec<u32>,
    /// Set when lowering *simulation* equations (the `CodegenWasmJit` target): a
    /// resolver that maps model component references not bound as wasm locals to
    /// slots in the shared `SimData` block. `None` for ordinary function bodies.
    pub(crate) sim: Option<SimCtx>,
}

/// Resolver for model variables when lowering simulation equations. Component
/// references that are not function-local wasm slots (states, state
/// derivatives, algebraics, parameters, `time`) are read/written through the
/// `SimData` block whose base pointer is held in the wasm local `data_local`
/// (the equation function's first parameter); every variable lives at a
/// compile-time-constant byte offset. See `CodegenWasmJit`.
pub(crate) struct SimCtx {
    /// wasm local index holding the `SimData` base pointer.
    pub(crate) data_local: u32,
    /// Canonical cref key (`super::sim_cref_key`) -> slot in `SimData`.
    pub(crate) vars: HashMap<String, SimSlot>,
    /// Canonical cref key -> its `start` value expression (for `$START.<cref>`),
    /// `None` when the variable has no explicit start (defaults to the type's
    /// zero). Stored separately from `vars` because `$START` reads the start
    /// attribute, not the live value.
    pub(crate) starts: HashMap<String, Option<Arc<DAE::Exp>>>,
    /// Canonical cref key of an *array-valued* model variable (the base name with
    /// no final subscript, e.g. `body.R_start.T`) -> the contiguous slot range its
    /// scalarized elements occupy. A whole-array reference reads/writes the range
    /// as one runtime array object (gather on read, scatter on assign). See
    /// `compile_sim_cref_read`/`compile_sim_cref_assign`.
    pub(crate) array_groups: HashMap<String, ArrayGroup>,
}

/// The contiguous `SimData` slot range backing one scalarized array model
/// variable. The backend lays an array's scalar elements out consecutively in
/// row-major order; this records the start offset and shape so a whole-array
/// reference can be marshalled to/from a runtime array object with one bulk copy.
#[derive(Clone)]
pub(crate) struct ArrayGroup {
    /// Byte offset of element `[1,1,…]` (row-major first) within `SimData`.
    pub(crate) base_off: u32,
    /// Element value type (`F64` for Real, `I32` for Integer/Boolean).
    pub(crate) wty: WTy,
    /// Array dimension sizes (row-major, outermost first).
    pub(crate) dims: Vec<u32>,
    /// Product of `dims` (number of scalar elements).
    pub(crate) total: u32,
}

/// A scalar model variable's location within the `SimData` block.
#[derive(Clone, Copy)]
pub(crate) struct SimSlot {
    /// Byte offset of the value within the `SimData` block.
    pub(crate) off: u32,
    /// Value type — `F64` for Real, `I32` for Integer/Boolean/String handle.
    pub(crate) wty: WTy,
    /// Alias negation: the cref is a negated alias of the variable at `off`, so
    /// a read negates and a write is rejected (aliases are never assigned).
    pub(crate) negate: bool,
    /// The slot holds a reference-counted heap handle (a String). A read retains;
    /// an assignment releases the previous handle before storing the new (owned)
    /// one. Scalar Real/Integer/Boolean slots are not heap.
    pub(crate) heap: bool,
}

impl<'a> FnCtx<'a> {
    fn emit(&mut self, i: we::Instruction<'static>) {
        // Track structured-control nesting so `break`/`continue` can compute their
        // relative branch depth. `Else` keeps the same frame; `End` closes one.
        match i {
            we::Instruction::Block(_) | we::Instruction::Loop(_) | we::Instruction::If(_) => {
                self.ctrl_depth += 1;
            }
            we::Instruction::End => {
                self.ctrl_depth = self.ctrl_depth.saturating_sub(1);
            }
            _ => {}
        }
        self.instrs.push(i);
    }
    /// Emit an unconditional branch to the structured-control frame that was open
    /// at `target_level` (a recorded `ctrl_depth`). `br 0` is the innermost frame.
    fn branch_to(&mut self, target_level: u32) {
        let rel = self.ctrl_depth - target_level;
        self.emit(we::Instruction::Br(rel));
    }
    /// Allocate a fresh scratch local of the given type and return its index.
    /// Never reused, so transient uses inside one expression never clobber.
    fn alloc_temp(&mut self, wty: WTy) -> u32 {
        let idx = self.n_params + self.extra_locals.len() as u32;
        self.extra_locals.push(wty.val());
        idx
    }

    /// Build a context for lowering one *simulation* equation function (see
    /// `CodegenWasmJit`). The function takes the `SimData` base pointer as its
    /// single parameter (wasm local 0); all model variables resolve through
    /// `sim` rather than wasm locals. `by_name` resolves calls to model
    /// functions (Modelica functions used by the equations); `literals` is the
    /// module-wide String-literal pool.
    pub(crate) fn new_sim(
        sim: SimCtx,
        by_name: &'a HashMap<String, FnInfo>,
        literals: &'a mut Vec<Vec<u8>>,
    ) -> Self {
        FnCtx {
            locals: HashMap::new(),
            extra_locals: Vec::new(),
            n_params: 1, // local 0 = SimData pointer
            outputs: Vec::new(),
            by_name,
            literals,
            instrs: Vec::new(),
            ctrl_depth: 0,
            loops: Vec::new(),
            borrowed_locals: Vec::new(),
            sim: Some(sim),
        }
    }

    /// Lower one equation `cref := rhs` into this context.
    pub(crate) fn sim_assign(&mut self, lhs: &DAE::Exp, rhs: &DAE::Exp) -> Result<()> {
        compile_assign(self, lhs, rhs)
    }

    /// Lower a list of algorithm statements into this context.
    pub(crate) fn sim_stmts(&mut self, stmts: &Arc<List<Arc<DAE::Statement>>>) -> Result<()> {
        compile_stmts(self, stmts)
    }

    /// Finish a hand-assembled (simulation) function body: append the final
    /// `end`, and return its extra-local declarations and instruction stream
    /// ready for `we::Function::new`. The caller has already emitted any
    /// `return`/fall-through value handling appropriate for the function.
    pub(crate) fn finish_sim(mut self) -> (Vec<we::ValType>, Vec<we::Instruction<'static>>) {
        self.emit(we::Instruction::End);
        (self.extra_locals, self.instrs)
    }
}

pub(crate) fn compile_function(
    f: &SimCodeFunction::Function::Function,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Vec<Vec<u8>>,
) -> Result<we::Function> {
    if matches!(f, SimCodeFunction::Function::Function::EXTERNAL_FUNCTION { .. }) {
        return compile_external_function(f, by_name, literals);
    }
    let SimCodeFunction::Function::Function::FUNCTION { outVars, functionArguments, variableDeclarations, body, .. } = f
    else {
        bail!("CodegenWasmJit: only plain FUNCTIONs are supported");
    };

    let mut locals: HashMap<String, (u32, SigTy)> = HashMap::new();
    let mut idx: u32 = 0;
    // Parameters first (wasm locals 0..n_params).
    for v in &**functionArguments {
        let (name, sty) = var_name_ty(v)?;
        locals.insert(name, (idx, sty));
        idx += 1;
    }
    let n_params = idx;
    let mut extra_locals: Vec<we::ValType> = Vec::new();
    let mut outputs: Vec<(u32, SigTy)> = Vec::new();
    // Array locals/outputs to allocate at function entry (see `emit_array_alloc`):
    // (local index, element type, dimension specs). Inputs are excluded — they
    // are passed in already built.
    let mut array_allocs: Vec<(u32, Arc<SigTy>, Vec<Arc<DAE::Dimension>>)> = Vec::new();
    // Outputs next, then local declarations. An output is often also listed in
    // `variableDeclarations` (the function body assigns to it through the same
    // name); it must map to a single local, so a name already allocated as an
    // input or output is reused rather than given a fresh slot.
    for v in &**outVars {
        let slot = intern_local(v, &mut idx, &mut extra_locals, &mut locals, &mut array_allocs)?;
        outputs.push(slot);
    }
    for v in &**variableDeclarations {
        intern_local(v, &mut idx, &mut extra_locals, &mut locals, &mut array_allocs)?;
    }

    let mut ctx = FnCtx { locals, extra_locals, n_params, outputs, by_name, literals, instrs: Vec::new(), ctrl_depth: 0, loops: Vec::new(), borrowed_locals: Vec::new(), sim: None };
    // Allocate every array local/output up front so it is a real (possibly empty)
    // array object, never a null handle — matching the C runtime, where the array
    // descriptor always exists. Unknown (`:`) dimensions start at size 0 and are
    // resized by the first whole-array assignment.
    for (slot, elem, dims) in &array_allocs {
        emit_array_alloc(&mut ctx, *slot, elem, dims)?;
    }
    // Default-binding initializers for protected/output variables, in
    // declaration order, mirroring the C target's `varInit` (driven by the
    // variable's `value`). A `bind_from_outside` variable is supplied by the
    // caller rather than its default, so it is skipped; inputs (function
    // arguments) are never initialized here — they arrive as parameters.
    for v in &**variableDeclarations {
        let SimCodeFunction::Variable::Variable::VARIABLE { name, ty, value, bind_from_outside, .. } = &**v else {
            continue;
        };
        if *bind_from_outside {
            continue;
        }
        let Some(val) = value else { continue };
        let lhs = DAE::Exp::CREF { componentRef: name.clone(), ty: ty.clone() };
        compile_assign(&mut ctx, &lhs, val)?;
    }
    compile_stmts(&mut ctx, body)?;
    // Fall-through return: release heap locals, push the output locals and end.
    release_heap_locals(&mut ctx);
    push_outputs(&mut ctx);
    ctx.emit(we::Instruction::End);

    let FnCtx { extra_locals, instrs, .. } = ctx;
    let mut func = we::Function::new(extra_locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Lower a known scalar-math `external "C"`/"builtin" function (see
/// [`external_known`]) to a wasm function body that calls the corresponding host
/// builtin: `output := extName(extArgs…)`. The inputs are the wasm parameters;
/// the external-call arguments (`extArgs`) reference them (or are constant
/// expressions). Only the return-value form is reached here.
fn compile_external_function(
    f: &SimCodeFunction::Function::Function,
    by_name: &HashMap<String, FnInfo>,
    literals: &mut Vec<Vec<u8>>,
) -> Result<we::Function> {
    use SimCodeFunction::SimExtArg::SimExtArg as A;
    let SimCodeFunction::Function::Function::EXTERNAL_FUNCTION { funArgs, outVars, extName, extArgs, .. } = f else {
        bail!("CodegenWasmJit: compile_external_function on a non-external function");
    };

    let mut locals: HashMap<String, (u32, SigTy)> = HashMap::new();
    let mut idx: u32 = 0;
    for v in &**funArgs {
        let (name, sty) = var_name_ty(v)?;
        locals.insert(name, (idx, sty));
        idx += 1;
    }
    let n_params = idx;
    let mut extra_locals: Vec<we::ValType> = Vec::new();
    let mut outputs: Vec<(u32, SigTy)> = Vec::new();
    for v in &**outVars {
        let (name, sty) = var_name_ty(v)?;
        extra_locals.push(sty.wty().val());
        let slot = (idx, sty.clone());
        locals.insert(name, slot.clone());
        outputs.push(slot);
        idx += 1;
    }

    let mut ctx = FnCtx { locals, extra_locals, n_params, outputs, by_name, literals, instrs: Vec::new(), ctrl_depth: 0, loops: Vec::new(), borrowed_locals: Vec::new(), sim: None };

    // The external-call arguments, as ordinary expressions over the inputs.
    let mut args: Vec<Arc<DAE::Exp>> = Vec::new();
    for a in &**extArgs {
        match &**a {
            A::SIMEXTARG { cref, type_, .. } => {
                args.push(Arc::new(DAE::Exp::CREF { componentRef: cref.clone(), ty: type_.clone() }));
            }
            A::SIMEXTARGEXP { exp, .. } => args.push(exp.clone()),
            other => bail!("CodegenWasmJit: unsupported external-call argument {other:?}"),
        }
    }

    let result = emit_known_external_call(&mut ctx, extName, &args)?;
    let (out_idx, out_sty) = ctx.outputs[0].clone();
    coerce(&mut ctx, result.wty(), out_sty.wty());
    ctx.emit(we::Instruction::LocalSet(out_idx));
    // Release heap parameters (e.g. a String input consumed by the callee), as a
    // normal function body would; the output is excluded and moved out.
    release_heap_locals(&mut ctx);
    push_outputs(&mut ctx);
    ctx.emit(we::Instruction::End);

    let FnCtx { extra_locals, instrs, .. } = ctx;
    let mut func = we::Function::new(extra_locals.into_iter().map(|t| (1u32, t)));
    for i in &instrs {
        func.instruction(i);
    }
    Ok(func)
}

/// Emit a call to a known math `extName` over already-lowered argument
/// expressions, leaving the (scalar Real) result on the stack. Mirrors the
/// host-builtin path of [`compile_math_builtin`]: an imported transcendental
/// ([`BUILTINS`]) or a single-instruction math function emitted inline.
fn emit_known_external_call(ctx: &mut FnCtx, ext_name: &str, args: &[Arc<DAE::Exp>]) -> Result<SigTy> {
    // `ModelicaStrings_*` functions that map directly to existing runtime string
    // ops (same lowering as the corresponding Modelica string builtins, so the
    // argument ARC is handled identically).
    match ext_name {
        "ModelicaStrings_length" => {
            str_unop(ctx, &args[0], "rt_str_len")?;
            return Ok(SigTy::Int);
        }
        "ModelicaStrings_substring" => {
            str_substring(ctx, &args[0], &args[1], &args[2])?;
            return Ok(SigTy::Str);
        }
        _ => {}
    }
    if let Some(bi) = builtin_index(ext_name) {
        let (_, params, _) = BUILTINS[bi as usize];
        if args.len() != params.len() {
            bail!("CodegenWasmJit: external `{ext_name}` expects {} args, got {}", params.len(), args.len());
        }
        for (a, p) in args.iter().zip(params.iter()) {
            let w = compile_exp(ctx, a)?;
            coerce(ctx, w, *p);
        }
        ctx.emit(we::Instruction::Call(bi));
        return Ok(SigTy::Real);
    }
    if args.len() != 1 {
        bail!("CodegenWasmJit: external `{ext_name}` expects 1 arg, got {}", args.len());
    }
    let w = compile_exp(ctx, &args[0])?;
    coerce(ctx, w, WTy::F64);
    match ext_name {
        "sqrt" => ctx.emit(we::Instruction::F64Sqrt),
        "fabs" => ctx.emit(we::Instruction::F64Abs),
        "floor" => ctx.emit(we::Instruction::F64Floor),
        "ceil" => ctx.emit(we::Instruction::F64Ceil),
        other => bail!("CodegenWasmJit: external math function `{other}` not supported"),
    }
    Ok(SigTy::Real)
}

/// Intern a function variable into the locals map (allocating a wasm local slot
/// on first sight of the name), returning its `(index, type)`. Array variables
/// are additionally recorded in `array_allocs` (once per slot) for entry-time
/// allocation.
fn intern_local(
    v: &SimCodeFunction::Variable::Variable,
    idx: &mut u32,
    extra_locals: &mut Vec<we::ValType>,
    locals: &mut HashMap<String, (u32, SigTy)>,
    array_allocs: &mut Vec<(u32, Arc<SigTy>, Vec<Arc<DAE::Dimension>>)>,
) -> Result<(u32, SigTy)> {
    let (name, sty) = var_name_ty(v)?;
    let slot = locals
        .entry(name)
        .or_insert_with(|| {
            extra_locals.push(sty.wty().val());
            let s = (*idx, sty.clone());
            *idx += 1;
            s
        })
        .clone();
    if let SigTy::Array { elem, .. } = &slot.1 {
        if !array_allocs.iter().any(|(i, ..)| *i == slot.0) {
            array_allocs.push((slot.0, elem.clone(), var_array_dims(v)?));
        }
    }
    Ok(slot)
}

/// The dimension list of an array `VARIABLE`, consistent with [`variable_sigty`]:
/// a `T_ARRAY` `ty` carries the dimensions (flattened across nesting); otherwise
/// they live in `instDims`.
fn var_array_dims(v: &SimCodeFunction::Variable::Variable) -> Result<Vec<Arc<DAE::Dimension>>> {
    let SimCodeFunction::Variable::Variable::VARIABLE { ty, instDims, .. } = v else {
        bail!("CodegenWasmJit: function-pointer variables not supported");
    };
    let from_ty = type_array_dims(ty);
    Ok(if from_ty.is_empty() { (&**instDims).into_iter().cloned().collect() } else { from_ty })
}

/// The dimensions carried by a `T_ARRAY` type, flattening nested `T_ARRAY`s
/// (outer dims first). Empty for a non-array type.
fn type_array_dims(ty: &DAE::Type) -> Vec<Arc<DAE::Dimension>> {
    match ty {
        DAE::Type::T_ARRAY { ty, dims } => {
            let mut out: Vec<Arc<DAE::Dimension>> = (&**dims).into_iter().cloned().collect();
            out.extend(type_array_dims(ty));
            out
        }
        _ => Vec::new(),
    }
}

/// Allocate an array local at function entry: evaluate each dimension to an
/// `i32` (unknown `:` dims start at 0), build the runtime array of the right
/// element kind, set the dimension sizes, and store the handle in `slot`.
fn emit_array_alloc(ctx: &mut FnCtx, slot: u32, elem: &SigTy, dims: &[Arc<DAE::Dimension>]) -> Result<()> {
    if dims.is_empty() {
        bail!("CodegenWasmJit: array local with no dimensions");
    }
    // Evaluate each dimension into a scratch local (reused for the total and the
    // per-axis size).
    let mut dim_temps = Vec::with_capacity(dims.len());
    for d in dims {
        let t = ctx.alloc_temp(WTy::I32);
        emit_dim_value(ctx, d)?;
        ctx.emit(we::Instruction::LocalSet(t));
        dim_temps.push(t);
    }
    // total = product of the dimension sizes.
    ctx.emit(we::Instruction::LocalGet(dim_temps[0]));
    for t in &dim_temps[1..] {
        ctx.emit(we::Instruction::LocalGet(*t));
        ctx.emit(we::Instruction::I32Mul);
    }
    let total_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(total_t));
    // obj = rt_array_new(elem_kind, rank, total); store into the local.
    ctx.emit(we::Instruction::I32Const(elem.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(dims.len() as i32));
    ctx.emit(we::Instruction::LocalGet(total_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")));
    ctx.emit(we::Instruction::LocalSet(slot));
    for (axis, t) in dim_temps.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(slot));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::LocalGet(*t));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")));
    }
    Ok(())
}

/// Emit the `i32` size of one array dimension. An unknown (`:`) dimension is 0
/// (an empty array, resized on first whole-array assignment).
fn emit_dim_value(ctx: &mut FnCtx, dim: &DAE::Dimension) -> Result<()> {
    match dim {
        DAE::Dimension::DIM_INTEGER { integer } => ctx.emit(we::Instruction::I32Const(*integer)),
        DAE::Dimension::DIM_BOOLEAN => ctx.emit(we::Instruction::I32Const(2)),
        DAE::Dimension::DIM_ENUM { size, .. } => ctx.emit(we::Instruction::I32Const(*size)),
        DAE::Dimension::DIM_UNKNOWN => ctx.emit(we::Instruction::I32Const(0)),
        DAE::Dimension::DIM_EXP { exp } => {
            let w = compile_exp(ctx, exp)?;
            coerce(ctx, w, WTy::I32);
        }
    }
    Ok(())
}

fn push_outputs(ctx: &mut FnCtx) {
    for (idx, _) in ctx.outputs.clone() {
        ctx.emit(we::Instruction::LocalGet(idx));
    }
}

/// Reference-count cleanup before a return: release every heap local that is
/// not an output (outputs are moved out to the caller). Parameters are included
/// — a generated function *owns* its heap parameters (the caller passes an owned
/// reference and does not release it after the call), so they are released here
/// too. Releasing the null handle (an unassigned heap local) is a no-op.
fn release_heap_locals(ctx: &mut FnCtx) {
    let output_idxs: std::collections::HashSet<u32> = ctx.outputs.iter().map(|(i, _)| *i).collect();
    // (local index, release entry point) for each owned heap local that is not
    // an output. The entry point depends on the type (string vs array vs …).
    let mut to_release: Vec<(u32, &'static str)> = ctx
        .locals
        .values()
        .filter(|(idx, _)| !output_idxs.contains(idx) && !ctx.borrowed_locals.contains(idx))
        .filter_map(|(idx, sty)| sty.release_fn().map(|f| (*idx, f)))
        .collect();
    // Deterministic order (HashMap iteration is unspecified) for stable output.
    to_release.sort_unstable();
    for (idx, release_fn) in to_release {
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::Call(rt_index(release_fn)));
    }
}

/// Name and Modelica type of a `VARIABLE` (combining `ty` and `instDims`; see
/// [`variable_sigty`]). The name must be a plain `CREF_IDENT`.
fn var_name_ty(v: &SimCodeFunction::Variable::Variable) -> Result<(String, SigTy)> {
    let SimCodeFunction::Variable::Variable::VARIABLE { name, ty, instDims, .. } = v else {
        bail!("CodegenWasmJit: function-pointer variables not supported");
    };
    Ok((cref_ident(name)?, variable_sigty(ty, instDims)?))
}

/// The identifier of a scalar `CREF_IDENT` component reference (no subscripts /
/// qualification, which only arise for arrays / records).
fn cref_ident(cr: &DAE::ComponentRef) -> Result<String> {
    match cr {
        DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } => {
            if !subscriptLst.is_empty() {
                bail!("CodegenWasmJit: subscripted component reference (arrays not supported)");
            }
            Ok(ident.to_string())
        }
        DAE::ComponentRef::CREF_QUAL { .. } => bail!("CodegenWasmJit: qualified component reference (records not supported)"),
        other => bail!("CodegenWasmJit: unsupported component reference {other:?}"),
    }
}

fn compile_stmts(ctx: &mut FnCtx, stmts: &Arc<List<Arc<DAE::Statement>>>) -> Result<()> {
    for s in &**stmts {
        compile_stmt(ctx, s)?;
    }
    Ok(())
}

/// Assign `rhs` to a lhs: a whole-variable (scalar / whole array / string) or a
/// subscripted array element (`a[i,...] := x`, written in place).
fn compile_assign(ctx: &mut FnCtx, lhs: &DAE::Exp, rhs: &DAE::Exp) -> Result<()> {
    let DAE::Exp::CREF { componentRef, .. } = lhs else {
        bail!("CodegenWasmJit: assignment to non-cref lhs not supported");
    };
    // Simulation mode: assigning to a model variable writes into the shared
    // `SimData` block. Returns false for an ordinary wasm local handled below.
    if compile_sim_cref_assign(ctx, componentRef, rhs)? {
        return Ok(());
    }
    // A qualified-cref assignment `base[..].f1[..].….fn[..] := rhs`: navigate to
    // the record holding the final field, then store into it.
    if let DAE::ComponentRef::CREF_QUAL { .. } = &**componentRef {
        return compile_cref_assign_qual(ctx, componentRef, rhs);
    }
    let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = &**componentRef else {
        bail!("CodegenWasmJit: assignment to qualified/record lhs not supported");
    };
    let name = ident.to_string();
    let (idx, dst_sty) = ctx
        .locals
        .get(&name)
        .ok_or_else(|| anyhow::anyhow!("CodegenWasmJit: assignment to unknown variable `{name}`"))?
        .clone();

    if !subscriptLst.is_empty() {
        // Element assignment `a[i,...] := x` — written in place into the local's
        // own (private) array, so no copy-on-write is needed (Modelica arrays are
        // mutable value objects; aliasing is broken at whole-array assignment).
        let SigTy::Array { elem, rank } = dst_sty else {
            bail!("CodegenWasmJit: subscripting non-array local `{name}`");
        };
        let idx_exps = index_subscripts(subscriptLst, rank)?;
        return compile_elem_assign(ctx, idx, &elem, &idx_exps, rhs);
    }

    let src_wty = compile_exp(ctx, rhs)?;
    // Value semantics for arrays and records: a whole-value assignment from
    // anything that is not a fresh constructor/call result would otherwise share
    // the source's mutable buffer (the rhs is a retained alias), so mutating the
    // destination later would corrupt the source — copy it to a private object.
    // A fresh rhs is already privately owned and is moved in. (Strings are
    // immutable, so they are shared via the retain on read — no copy.)
    if let Some((copy_fn, rel_fn)) = value_copy_fns(&dst_sty) {
        if !value_rhs_is_fresh(rhs) {
            let t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(t));
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::Call(rt_index(copy_fn)));
            // Release the alias we copied from (the rhs's +1 reference).
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::Call(rt_index(rel_fn)));
        }
    }
    if let Some(release_fn) = dst_sty.release_fn() {
        // Release-on-overwrite: free the previous value the local held *after*
        // computing the new one (which may read the old value, as in `s := s + x`),
        // then move the new owned value in. Stack: [new] -> release old -> store.
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::Call(rt_index(release_fn)));
        ctx.emit(we::Instruction::LocalSet(idx));
    } else {
        coerce(ctx, src_wty, dst_sty.wty());
        ctx.emit(we::Instruction::LocalSet(idx));
    }
    Ok(())
}

/// Store a freshly-owned value held in temp `vt` into simple local `idx` of type
/// `dst_sty`, releasing the local's previous value first (release-on-overwrite).
/// The value must already be privately owned (a call/constructor result), so no
/// value-semantics copy is made. Used by tuple assignment.
fn store_fresh_into_local(ctx: &mut FnCtx, idx: u32, dst_sty: &SigTy, vt: u32) {
    if let Some(release_fn) = dst_sty.release_fn() {
        // [new] -> release old -> store new.
        ctx.emit(we::Instruction::LocalGet(vt));
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::Call(rt_index(release_fn)));
        ctx.emit(we::Instruction::LocalSet(idx));
    } else {
        ctx.emit(we::Instruction::LocalGet(vt));
        ctx.emit(we::Instruction::LocalSet(idx));
    }
}

/// Lower `(l1, l2, …) := f(args)` (`STMT_TUPLE_ASSIGN`): call the multi-output
/// generated function (which leaves its results on the stack, first result
/// deepest), then move each owned result into its target local. A `_` (wildcard)
/// target discards its value (releasing it if heap). Targets must be simple
/// locals; subscripted / qualified tuple targets are not supported.
fn compile_tuple_assign(ctx: &mut FnCtx, lhs: &Arc<List<Arc<DAE::Exp>>>, call: &DAE::Exp) -> Result<()> {
    let DAE::Exp::CALL { path, expLst, attr } = call else {
        bail!("CodegenWasmJit: tuple assignment rhs is not a function call: {call:?}");
    };
    let lhs_v: Vec<&Arc<DAE::Exp>> = (&**lhs).into_iter().collect();
    let results = compile_call(ctx, path, expLst, attr)?;
    if results.len() != lhs_v.len() {
        bail!("CodegenWasmJit: tuple assignment arity mismatch ({} targets, {} results)", lhs_v.len(), results.len());
    }
    // Pop the results into temps (the last result is on top of the stack).
    let mut temps = vec![0u32; results.len()];
    for i in (0..results.len()).rev() {
        let vt = ctx.alloc_temp(results[i].wty());
        ctx.emit(we::Instruction::LocalSet(vt));
        temps[i] = vt;
    }
    for (i, lhs_exp) in lhs_v.iter().enumerate() {
        let sty = &results[i];
        let vt = temps[i];
        let DAE::Exp::CREF { componentRef, .. } = &***lhs_exp else {
            bail!("CodegenWasmJit: tuple-assignment target is not a cref: {lhs_exp:?}");
        };
        match &**componentRef {
            // `_` output: discard (release a heap value).
            DAE::ComponentRef::WILD => {
                if let Some(release_fn) = sty.release_fn() {
                    ctx.emit(we::Instruction::LocalGet(vt));
                    ctx.emit(we::Instruction::Call(rt_index(release_fn)));
                }
            }
            DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } if subscriptLst.is_empty() => {
                let name = ident.to_string();
                let (idx, dst_sty) = ctx
                    .locals
                    .get(&name)
                    .ok_or_else(|| anyhow::anyhow!("CodegenWasmJit: tuple assignment to unknown variable `{name}`"))?
                    .clone();
                store_fresh_into_local(ctx, idx, &dst_sty, vt);
            }
            other => bail!("CodegenWasmJit: unsupported tuple-assignment target `{other:?}`"),
        }
    }
    Ok(())
}

/// The (copy, release) runtime entry points for a mutable value type that needs
/// a private copy on aliasing assignment, or `None` for scalars and immutable
/// strings.
fn value_copy_fns(ty: &SigTy) -> Option<(&'static str, &'static str)> {
    match ty {
        SigTy::Array { .. } => Some(("rt_array_copy", "rt_array_release")),
        SigTy::Record { .. } => Some(("rt_record_copy", "rt_record_release")),
        _ => None,
    }
}

/// Whether a whole-value rhs expression produces a freshly-owned array/record
/// (so it can be moved into the destination without copying). Constructors,
/// ranges and call results are fresh; a variable reference / shared literal
/// aliases an existing object.
fn value_rhs_is_fresh(e: &DAE::Exp) -> bool {
    use DAE::Exp as E;
    match e {
        E::ARRAY { .. } | E::MATRIX { .. } | E::RANGE { .. } | E::CALL { .. } | E::RECORD { .. } => true,
        E::SHARED_LITERAL { exp, .. } | E::CAST { exp, .. } => value_rhs_is_fresh(exp),
        _ => false,
    }
}

// -------------------------------------------------------------------------
// Record object layout (mirrors the runtime's record object)
// -------------------------------------------------------------------------

/// Byte size of one record field: Real is 8, everything else (Integer/Boolean
/// and every heap handle) is 4.
fn field_size(t: &SigTy) -> u32 {
    if matches!(t, SigTy::Real) { 8 } else { 4 }
}

fn align_up(n: u32, a: u32) -> u32 {
    (n + a - 1) & !(a - 1)
}

/// The byte layout of a record object's payload. `data_off` is the offset from
/// the object base to the first field (after the refcount, `nheap`, and the
/// inline heap-field table); `field_off[i]` is field `i`'s offset within the
/// field-data area; `heap` lists `(elem_kind, field_off)` for the heap fields
/// (the inline release table); `size` is the total payload to allocate. Must
/// agree with `rec_data_off` / the field layout in the runtime.
struct RecordLayout {
    data_off: u32,
    size: u32,
    field_off: Vec<u32>,
    heap: Vec<(u32, u32)>,
}

fn record_layout(fields: &[(ArcStr, SigTy)]) -> RecordLayout {
    let nheap = fields.iter().filter(|(_, t)| t.is_heap()).count() as u32;
    let data_off = align_up(8 + nheap * 8, 8);
    let mut off = 0u32;
    let mut field_off = Vec::with_capacity(fields.len());
    let mut heap = Vec::new();
    for (_, t) in fields {
        let sz = field_size(t);
        off = align_up(off, sz);
        field_off.push(off);
        if t.is_heap() {
            heap.push((t.elem_kind(), off));
        }
        off += sz;
    }
    RecordLayout { data_off, size: data_off + align_up(off, 8), field_off, heap }
}

/// Resolve a record field by name to `(absolute offset from the object base,
/// field type)`.
fn record_field(fields: &[(ArcStr, SigTy)], name: &str) -> Result<(u32, SigTy)> {
    let layout = record_layout(fields);
    for (i, (fname, fty)) in fields.iter().enumerate() {
        if fname.as_str() == name {
            return Ok((layout.data_off + layout.field_off[i], fty.clone()));
        }
    }
    bail!("CodegenWasmJit: record has no field `{name}`");
}

pub(crate) fn mem_arg(offset: u32, align_log2: u32) -> we::MemArg {
    we::MemArg { offset: offset as u64, align: align_log2, memory_index: 0 }
}

/// Load a `wty` value from `(address on stack) + offset` (record field read).
fn field_load(ctx: &mut FnCtx, wty: WTy, offset: u32) {
    match wty {
        WTy::I32 => ctx.emit(we::Instruction::I32Load(mem_arg(offset, 2))),
        WTy::F64 => ctx.emit(we::Instruction::F64Load(mem_arg(offset, 3))),
    }
}

/// Store a `wty` value to `(address on stack) + offset` (record field write).
fn field_store(ctx: &mut FnCtx, wty: WTy, offset: u32) {
    match wty {
        WTy::I32 => ctx.emit(we::Instruction::I32Store(mem_arg(offset, 2))),
        WTy::F64 => ctx.emit(we::Instruction::F64Store(mem_arg(offset, 3))),
    }
}

/// Construct a record (`E::RECORD`): allocate the object, fill the inline
/// heap-field table, then store each field value (matched to the type's fields
/// by name, so out-of-order constructor arguments are handled). Leaves the owned
/// (+1) record handle on the stack.
/// Emit a record construction: allocate the object, fill the inline heap-field
/// table, then store each field value (`field_exps` in declaration order). The
/// record owns heap field values. Leaves the owned (+1) record handle on the
/// stack.
fn emit_record_construction(ctx: &mut FnCtx, fields: &[(ArcStr, SigTy)], field_exps: &[&Arc<DAE::Exp>]) -> Result<()> {
    let layout = record_layout(fields);
    ctx.emit(we::Instruction::I32Const(layout.heap.len() as i32));
    ctx.emit(we::Instruction::I32Const(layout.size as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_record_new")));
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(obj));

    // Inline heap-field table: (elem_kind, field_off) for each heap field.
    for (k, (kind, foff)) in layout.heap.iter().enumerate() {
        let base = 8 + k as u32 * 8;
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(*kind as i32));
        ctx.emit(we::Instruction::I32Store(mem_arg(base, 2)));
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(*foff as i32));
        ctx.emit(we::Instruction::I32Store(mem_arg(base + 4, 2)));
    }
    for (i, (_, fty)) in fields.iter().enumerate() {
        let w = compile_exp(ctx, field_exps[i])?;
        coerce(ctx, w, fty.wty());
        // Value semantics: a record/array field built from a non-fresh source
        // (a variable, a field read) aliases that source's mutable object — copy
        // it so the record owns a private value. Fresh constructors/calls/ranges
        // are already privately owned and move in. (Strings are immutable.)
        if let Some((copy_fn, rel_fn)) = value_copy_fns(fty) {
            if !value_rhs_is_fresh(field_exps[i]) {
                let t = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(t));
                ctx.emit(we::Instruction::LocalGet(t));
                ctx.emit(we::Instruction::Call(rt_index(copy_fn)));
                ctx.emit(we::Instruction::LocalGet(t));
                ctx.emit(we::Instruction::Call(rt_index(rel_fn)));
            }
        }
        // Store the owned (private) value into the field: address then value.
        let vt = ctx.alloc_temp(fty.wty());
        ctx.emit(we::Instruction::LocalSet(vt));
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::LocalGet(vt));
        field_store(ctx, fty.wty(), layout.data_off + layout.field_off[i]);
    }
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

/// A record literal `R(field=…, …)` (`E::RECORD`): the field values are matched
/// to the type's declaration order by component name.
fn compile_record(ctx: &mut FnCtx, ty: &DAE::Type, exps: &Arc<List<Arc<DAE::Exp>>>, comp: &Arc<List<ArcStr>>) -> Result<()> {
    let SigTy::Record { fields, .. } = sig_ty(ty)? else {
        bail!("CodegenWasmJit: record constructor with non-record type {ty:?}");
    };
    let expv: Vec<&Arc<DAE::Exp>> = (&**exps).into_iter().collect();
    let compv: Vec<&ArcStr> = (&**comp).into_iter().collect();
    if expv.len() != compv.len() || expv.len() != fields.len() {
        bail!("CodegenWasmJit: record constructor arity mismatch ({} values, {} fields)", expv.len(), fields.len());
    }
    let mut field_exps = Vec::with_capacity(fields.len());
    for (fname, _) in fields.iter() {
        let pos = compv
            .iter()
            .position(|n| n.as_str() == fname.as_str())
            .ok_or_else(|| anyhow::anyhow!("CodegenWasmJit: record constructor missing field `{fname}`"))?;
        field_exps.push(expv[pos]);
    }
    emit_record_construction(ctx, &fields, &field_exps)
}

/// A record-constructor *call* `R(v1, v2, …)` (a `CALL` whose result is a record
/// and which is not a generated function): the positional arguments are the
/// fields in declaration order.
fn compile_record_call(ctx: &mut FnCtx, ty: &DAE::Type, args: &Arc<List<Arc<DAE::Exp>>>) -> Result<()> {
    let SigTy::Record { fields, .. } = sig_ty(ty)? else {
        bail!("CodegenWasmJit: record constructor call with non-record type {ty:?}");
    };
    let argv: Vec<&Arc<DAE::Exp>> = (&**args).into_iter().collect();
    if argv.len() != fields.len() {
        bail!("CodegenWasmJit: record constructor call arity mismatch ({} args, {} fields)", argv.len(), fields.len());
    }
    emit_record_construction(ctx, &fields, &argv)
}

/// Read field `name` of the record produced by `exp` (`E::RSUB`). The record
/// expression is owned (retained if it was a variable) and released after the
/// field is read; a heap field is retained so the returned value is owned.
fn compile_rsub(ctx: &mut FnCtx, exp: &DAE::Exp, name: &str) -> Result<WTy> {
    let SigTy::Record { fields, .. } = exp_sigty(exp)? else {
        bail!("CodegenWasmJit: field access `.{name}` on a non-record expression");
    };
    let (off, fty) = record_field(&fields, name)?;
    compile_exp(ctx, exp)?; // owned record handle
    let rec = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(rec));
    ctx.emit(we::Instruction::LocalGet(rec));
    field_load(ctx, fty.wty(), off);
    if fty.is_heap() {
        // Retain the field (owned read), then release the record temp.
        let fv = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalTee(fv));
        ctx.emit(we::Instruction::LocalGet(fv));
        ctx.emit(we::Instruction::Call(rt_index("rt_retain")));
    }
    ctx.emit(we::Instruction::LocalGet(rec));
    ctx.emit(we::Instruction::Call(rt_index("rt_record_release")));
    Ok(fty.wty())
}

/// Assign `rhs` into field `name` of record local `rec_idx` (`r.field := rhs`),
/// in place. A heap field's previous value is released after the new owned value
/// is computed; an array/record field assigned from an alias is copied for value
/// semantics (like a whole-value assignment).
fn compile_record_field_assign(ctx: &mut FnCtx, rec_idx: u32, fields: &[(ArcStr, SigTy)], name: &str, rhs: &DAE::Exp) -> Result<()> {
    let (off, fty) = record_field(fields, name)?;
    let Some(release_fn) = fty.release_fn() else {
        // Scalar field: store directly.
        ctx.emit(we::Instruction::LocalGet(rec_idx));
        let w = compile_exp(ctx, rhs)?;
        coerce(ctx, w, fty.wty());
        field_store(ctx, fty.wty(), off);
        return Ok(());
    };
    // Heap field: compute the new owned value into a temp.
    let w = compile_exp(ctx, rhs)?;
    coerce(ctx, w, fty.wty());
    let val_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(val_t));
    // Value semantics: a mutable array/record from a non-fresh source aliases it.
    if let Some((copy_fn, rel_fn)) = value_copy_fns(&fty) {
        if !value_rhs_is_fresh(rhs) {
            ctx.emit(we::Instruction::LocalGet(val_t));
            ctx.emit(we::Instruction::Call(rt_index(copy_fn)));
            ctx.emit(we::Instruction::LocalGet(val_t));
            ctx.emit(we::Instruction::Call(rt_index(rel_fn)));
            ctx.emit(we::Instruction::LocalSet(val_t));
        }
    }
    // Release the previous field value (now that the new one is computed).
    ctx.emit(we::Instruction::LocalGet(rec_idx));
    field_load(ctx, fty.wty(), off);
    ctx.emit(we::Instruction::Call(rt_index(release_fn)));
    // Store the new owned value into the field.
    ctx.emit(we::Instruction::LocalGet(rec_idx));
    ctx.emit(we::Instruction::LocalGet(val_t));
    field_store(ctx, fty.wty(), off);
    Ok(())
}

/// Push an owned record handle for the head of a qualified cref onto a fresh
/// temp: either a record local (retained, so the local keeps its reference) or
/// an array-of-records local subscripted down to a single record element.
/// Returns the temp holding the owned handle and the record's fields; the caller
/// is responsible for releasing the temp.
fn push_owned_record_base(
    ctx: &mut FnCtx,
    ident: &str,
    subs: &Arc<List<Arc<DAE::Subscript>>>,
) -> Result<(u32, Arc<Vec<(ArcStr, SigTy)>>)> {
    let (idx, sty) = ctx
        .locals
        .get(ident)
        .ok_or_else(|| anyhow::anyhow!("CodegenWasmJit: reference to unknown variable `{ident}`"))?
        .clone();
    if subs.is_empty() {
        let SigTy::Record { fields, .. } = sty else {
            bail!("CodegenWasmJit: field access on non-record local `{ident}`");
        };
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::Call(rt_index("rt_retain")));
        let t = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalSet(t));
        Ok((t, fields))
    } else {
        let SigTy::Array { elem, rank } = sty else {
            bail!("CodegenWasmJit: subscripting non-array local `{ident}`");
        };
        let SigTy::Record { fields, .. } = &*elem else {
            bail!("CodegenWasmJit: indexed base `{ident}[..]` is not an array of records");
        };
        let fields = fields.clone();
        if !is_scalar_index(subs, rank) {
            bail!("CodegenWasmJit: slicing an array of records before field access is not supported");
        }
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::Call(rt_index("rt_retain")));
        let idx_exps = index_subscripts(subs, rank)?;
        index_loaded(ctx, &elem, &idx_exps)?; // owned record element on the stack
        let t = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalSet(t));
        Ok((t, fields))
    }
}

/// Read field `name` from the owned record handle in temp `rec`, consuming it
/// (the record is released). Leaves the field value in a fresh temp and returns
/// `(value_temp, field_type)`; a heap field value is retained so it is owned.
fn take_field(
    ctx: &mut FnCtx,
    rec: u32,
    fields: &[(ArcStr, SigTy)],
    name: &str,
) -> Result<(u32, SigTy)> {
    let (off, fty) = record_field(fields, name)?;
    let vt = ctx.alloc_temp(fty.wty());
    ctx.emit(we::Instruction::LocalGet(rec));
    field_load(ctx, fty.wty(), off);
    ctx.emit(we::Instruction::LocalSet(vt));
    if fty.is_heap() {
        // Own the field value before releasing the record that holds it.
        ctx.emit(we::Instruction::LocalGet(vt));
        ctx.emit(we::Instruction::Call(rt_index("rt_retain")));
    }
    ctx.emit(we::Instruction::LocalGet(rec));
    ctx.emit(we::Instruction::Call(rt_index("rt_record_release")));
    Ok((vt, fty))
}

/// Descend one qualified-cref step into field `field[fsubs]` of the record in
/// temp `rec`, producing an owned record handle for the field in a fresh temp.
/// Used by the read/assign navigators for an intermediate `.field.` segment that
/// must resolve to a (sub-)record. Returns `(record_temp, that record's fields)`.
fn step_into_record(
    ctx: &mut FnCtx,
    rec: u32,
    fields: &[(ArcStr, SigTy)],
    field: &str,
    fsubs: &Arc<List<Arc<DAE::Subscript>>>,
) -> Result<(u32, Arc<Vec<(ArcStr, SigTy)>>)> {
    let (vt, fty) = take_field(ctx, rec, fields, field)?;
    if fsubs.is_empty() {
        let SigTy::Record { fields: f2, .. } = fty else {
            bail!("CodegenWasmJit: field access on non-record field `{field}`");
        };
        Ok((vt, f2))
    } else {
        let SigTy::Array { elem, rank } = fty else {
            bail!("CodegenWasmJit: subscripting non-array field `{field}`");
        };
        let SigTy::Record { fields: f2, .. } = &*elem else {
            bail!("CodegenWasmJit: field access on non-record array element `{field}`");
        };
        let f2 = f2.clone();
        if !is_scalar_index(fsubs, rank) {
            bail!("CodegenWasmJit: slicing an array of records before field access is not supported");
        }
        ctx.emit(we::Instruction::LocalGet(vt)); // owned array handle
        let idx_exps = index_subscripts(fsubs, rank)?;
        index_loaded(ctx, &elem, &idx_exps)?; // owned record element
        let t = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalSet(t));
        Ok((t, f2))
    }
}

/// Read a qualified cref `base[..].f1[..].….fn[..]` (`E::CREF` with a
/// `CREF_QUAL` head), descending through nested records (and arrays of records)
/// to the final field, which may itself be subscripted (a scalar index or a
/// slice). Leaves the owned field value on the stack.
fn compile_cref_read_qual(ctx: &mut FnCtx, cref: &DAE::ComponentRef) -> Result<WTy> {
    let DAE::ComponentRef::CREF_QUAL { ident, subscriptLst, componentRef: rest, .. } = cref else {
        bail!("CodegenWasmJit: compile_cref_read_qual on non-qualified cref");
    };
    let (mut rec, mut fields) = push_owned_record_base(ctx, ident, subscriptLst)?;
    let mut cur: &DAE::ComponentRef = rest;
    loop {
        match cur {
            DAE::ComponentRef::CREF_IDENT { ident: field, subscriptLst: fsubs, .. } => {
                let (vt, fty) = take_field(ctx, rec, &fields, field)?;
                if fsubs.is_empty() {
                    ctx.emit(we::Instruction::LocalGet(vt));
                    return Ok(fty.wty());
                }
                let SigTy::Array { elem, rank } = fty else {
                    bail!("CodegenWasmJit: subscripting non-array field `{field}`");
                };
                ctx.emit(we::Instruction::LocalGet(vt)); // owned array handle
                return if is_scalar_index(fsubs, rank) {
                    let idx_exps = index_subscripts(fsubs, rank)?;
                    index_loaded(ctx, &elem, &idx_exps)
                } else {
                    slice_loaded(ctx, fsubs)
                };
            }
            DAE::ComponentRef::CREF_QUAL { ident: field, subscriptLst: fsubs, componentRef: inner, .. } => {
                let (t, f2) = step_into_record(ctx, rec, &fields, field, fsubs)?;
                rec = t;
                fields = f2;
                cur = inner;
            }
            other => bail!("CodegenWasmJit: unsupported component reference {other:?}"),
        }
    }
}

/// Navigate a qualified cref to the record that directly contains its final
/// field, returning `(owned record temp, that record's fields, final field
/// name, final field subscripts)`. The caller releases the returned temp.
fn navigate_qual<'c>(
    ctx: &mut FnCtx,
    cref: &'c DAE::ComponentRef,
) -> Result<(u32, Arc<Vec<(ArcStr, SigTy)>>, &'c str, &'c Arc<List<Arc<DAE::Subscript>>>)> {
    let DAE::ComponentRef::CREF_QUAL { ident, subscriptLst, componentRef: rest, .. } = cref else {
        bail!("CodegenWasmJit: navigate_qual on non-qualified cref");
    };
    let (mut rec, mut fields) = push_owned_record_base(ctx, ident, subscriptLst)?;
    let mut cur: &DAE::ComponentRef = rest;
    loop {
        match cur {
            DAE::ComponentRef::CREF_IDENT { ident: field, subscriptLst: fsubs, .. } => {
                return Ok((rec, fields, field, fsubs));
            }
            DAE::ComponentRef::CREF_QUAL { ident: field, subscriptLst: fsubs, componentRef: inner, .. } => {
                let (t, f2) = step_into_record(ctx, rec, &fields, field, fsubs)?;
                rec = t;
                fields = f2;
                cur = inner;
            }
            other => bail!("CodegenWasmJit: unsupported component reference {other:?}"),
        }
    }
}

/// Assign `rhs` into a qualified cref `base[..].f1[..].….fn[..]`. Navigates to
/// the record holding the final field and stores in place (a scalar/heap field,
/// or an element of an array-valued field).
fn compile_cref_assign_qual(ctx: &mut FnCtx, cref: &DAE::ComponentRef, rhs: &DAE::Exp) -> Result<()> {
    let (rec, fields, leaf, lsubs) = navigate_qual(ctx, cref)?;
    if lsubs.is_empty() {
        compile_record_field_assign(ctx, rec, &fields, leaf, rhs)?;
    } else {
        // `…field[i] := rhs`: element assignment into the field's (privately
        // owned) array, in place.
        let (off, fty) = record_field(&fields, leaf)?;
        let SigTy::Array { elem, rank } = fty else {
            bail!("CodegenWasmJit: subscripted field `{leaf}` is not an array");
        };
        let arr_t = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalGet(rec));
        field_load(ctx, WTy::I32, off);
        ctx.emit(we::Instruction::LocalSet(arr_t));
        let idx_exps = index_subscripts(lsubs, rank)?;
        compile_elem_assign(ctx, arr_t, &elem, &idx_exps, rhs)?;
    }
    // Release the navigated record handle (owned by us).
    ctx.emit(we::Instruction::LocalGet(rec));
    ctx.emit(we::Instruction::Call(rt_index("rt_record_release")));
    Ok(())
}

/// Element assignment `a[i,...] := rhs`, in place. `arr_idx` is the array local
/// (which privately owns its buffer). For a heap element the previous handle in
/// the slot is released and the new owned value moved in; the old value is
/// released only *after* the rhs is computed, in case the rhs reads it.
fn compile_elem_assign(ctx: &mut FnCtx, arr_idx: u32, elem: &SigTy, idx_exps: &[Arc<DAE::Exp>], rhs: &DAE::Exp) -> Result<()> {
    emit_elem_addr(ctx, arr_idx, idx_exps)?;
    let addr_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(addr_t));
    if let Some(release_fn) = elem.release_fn() {
        let w = compile_exp(ctx, rhs)?;
        coerce(ctx, w, elem.wty());
        let val_t = ctx.alloc_temp(elem.wty());
        ctx.emit(we::Instruction::LocalSet(val_t));
        // Release the previous element handle now that the new value is computed.
        ctx.emit(we::Instruction::LocalGet(addr_t));
        elem_load(ctx, elem);
        ctx.emit(we::Instruction::Call(rt_index(release_fn)));
        // Store the new owned handle into the slot.
        ctx.emit(we::Instruction::LocalGet(addr_t));
        ctx.emit(we::Instruction::LocalGet(val_t));
        elem_store(ctx, elem);
    } else {
        ctx.emit(we::Instruction::LocalGet(addr_t));
        let w = compile_exp(ctx, rhs)?;
        coerce(ctx, w, elem.wty());
        elem_store(ctx, elem);
    }
    Ok(())
}

/// Emit the byte address of array element `a[idx_exps...]`, reading the array
/// handle from local `arr_idx` (the local owns it — no retain/release). Leaves
/// the address on the stack. Same row-major linear index as [`index_loaded`].
fn emit_elem_addr(ctx: &mut FnCtx, arr_idx: u32, idx_exps: &[Arc<DAE::Exp>]) -> Result<()> {
    let acc = ctx.alloc_temp(WTy::I32);
    let w = compile_exp(ctx, &idx_exps[0])?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Sub);
    ctx.emit(we::Instruction::LocalSet(acc));
    for (axis0, ie) in idx_exps.iter().enumerate().skip(1) {
        ctx.emit(we::Instruction::LocalGet(acc));
        ctx.emit(we::Instruction::LocalGet(arr_idx));
        ctx.emit(we::Instruction::I32Const(axis0 as i32 + 1));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_dim")));
        ctx.emit(we::Instruction::I32Mul);
        let w = compile_exp(ctx, ie)?;
        coerce(ctx, w, WTy::I32);
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::I32Sub);
        ctx.emit(we::Instruction::I32Add);
        ctx.emit(we::Instruction::LocalSet(acc));
    }
    ctx.emit(we::Instruction::LocalGet(arr_idx));
    ctx.emit(we::Instruction::LocalGet(acc));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
    Ok(())
}

fn compile_stmt(ctx: &mut FnCtx, stmt: &DAE::Statement) -> Result<()> {
    use DAE::Statement as S;
    match stmt {
        S::STMT_ASSIGN { exp1, exp, .. } => compile_assign(ctx, exp1, exp),
        S::STMT_TUPLE_ASSIGN { expExpLst, exp, .. } => compile_tuple_assign(ctx, expExpLst, exp),
        // Whole-array assignment (`r := {...}`, `r := other`); `compile_assign`
        // copies when the source is a variable (value semantics) and moves a
        // fresh constructor/call result.
        S::STMT_ASSIGN_ARR { lhs, exp, .. } => compile_assign(ctx, lhs, exp),
        S::STMT_IF { exp, statementLst, else_, .. } => {
            let c = compile_exp(ctx, exp)?;
            coerce(ctx, c, WTy::I32);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            compile_stmts(ctx, statementLst)?;
            compile_else(ctx, else_)?;
            ctx.emit(we::Instruction::End);
            Ok(())
        }
        S::STMT_WHILE { exp, statementLst, .. } => {
            // block { loop { <cond>; i32.eqz; br_if 1; block { <body> }; br 0 } }
            // The inner block is the `continue` target (fall through re-checks the
            // condition); the outer block is the `break` target.
            ctx.emit(we::Instruction::Block(we::BlockType::Empty));
            let break_level = ctx.ctrl_depth;
            ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
            let c = compile_exp(ctx, exp)?;
            coerce(ctx, c, WTy::I32);
            ctx.emit(we::Instruction::I32Eqz);
            ctx.emit(we::Instruction::BrIf(1));
            compile_loop_body(ctx, break_level, statementLst)?;
            ctx.emit(we::Instruction::Br(0));
            ctx.emit(we::Instruction::End); // loop
            ctx.emit(we::Instruction::End); // block
            Ok(())
        }
        S::STMT_RETURN { .. } => {
            release_heap_locals(ctx);
            push_outputs(ctx);
            ctx.emit(we::Instruction::Return);
            Ok(())
        }
        S::STMT_NORETCALL { exp, .. } => {
            // Evaluate for side effects and discard any results. A discarded heap
            // result is owned (+1), so it must be released, not merely dropped.
            let results = compile_call_drop(ctx, exp)?;
            for sty in results.iter().rev() {
                match sty.release_fn() {
                    Some(release_fn) => ctx.emit(we::Instruction::Call(rt_index(release_fn))),
                    None => ctx.emit(we::Instruction::Drop),
                }
            }
            Ok(())
        }
        S::STMT_ASSERT { cond, msg, source, .. } => {
            // `if (!cond) { rt_assert(msg, file, line/col…); unreachable }`. In a
            // function context the C target always emits `omc_assert` (an error
            // that throws — the assertion level is irrelevant here), so a failed
            // assert routes its message + source info to the error buffer (host
            // import `rt_assert`, read back by `load_and_execute`) and then traps;
            // `loadAndExecute` returns `META_FAIL`, matching the C target's
            // `[file:l:c-l:c:writable] Error: <msg>` output.
            let c = compile_exp(ctx, cond)?;
            coerce(ctx, c, WTy::I32);
            ctx.emit(we::Instruction::I32Eqz);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            let mw = compile_exp(ctx, msg)?; // owned String handle
            if mw != WTy::I32 {
                bail!("CodegenWasmJit: assert message is not a String");
            }
            let info = &source.info;
            emit_str_literal(ctx, info.fileName.as_bytes()); // file String handle
            ctx.emit(we::Instruction::I32Const(info.lineNumberStart));
            ctx.emit(we::Instruction::I32Const(info.columnNumberStart));
            ctx.emit(we::Instruction::I32Const(info.lineNumberEnd));
            ctx.emit(we::Instruction::I32Const(info.columnNumberEnd));
            ctx.emit(we::Instruction::I32Const(info.isReadOnly as i32));
            ctx.emit(we::Instruction::Call(env_extra_index("rt_assert")));
            ctx.emit(we::Instruction::Unreachable);
            ctx.emit(we::Instruction::End);
            Ok(())
        }
        S::STMT_FOR { iter, range, statementLst, type_, .. } => compile_for(ctx, iter, range, statementLst, type_),
        S::STMT_BREAK { .. } => {
            let (brk, _) = *ctx
                .loops
                .last()
                .ok_or_else(|| anyhow::anyhow!("CodegenWasmJit: `break` outside a loop"))?;
            ctx.branch_to(brk);
            Ok(())
        }
        S::STMT_CONTINUE { .. } => {
            let (_, cont) = *ctx
                .loops
                .last()
                .ok_or_else(|| anyhow::anyhow!("CodegenWasmJit: `continue` outside a loop"))?;
            ctx.branch_to(cont);
            Ok(())
        }
        other => bail!("CodegenWasmJit: statement not yet supported: {other:?}"),
    }
}

fn compile_else(ctx: &mut FnCtx, e: &DAE::Else) -> Result<()> {
    match e {
        DAE::Else::NOELSE => Ok(()),
        DAE::Else::ELSE { statementLst } => {
            ctx.emit(we::Instruction::Else);
            compile_stmts(ctx, statementLst)
        }
        DAE::Else::ELSEIF { exp, statementLst, else_ } => {
            ctx.emit(we::Instruction::Else);
            let c = compile_exp(ctx, exp)?;
            coerce(ctx, c, WTy::I32);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            compile_stmts(ctx, statementLst)?;
            compile_else(ctx, else_)?;
            ctx.emit(we::Instruction::End);
            Ok(())
        }
    }
}

/// Emit a loop body wrapped in its `continue` block, with the loop registered on
/// `ctx.loops` so nested `break`/`continue` resolve to the right depths. The
/// enclosing `block` (break target) and `loop` frame must already be open;
/// `break_level` is the `ctrl_depth` recorded just after opening the break block.
/// On return the `continue` block is closed, so the caller emits the per-iteration
/// advance (increment / condition re-check) next — `continue` falls through to it.
fn compile_loop_body(
    ctx: &mut FnCtx,
    break_level: u32,
    body: &Arc<List<Arc<DAE::Statement>>>,
) -> Result<()> {
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    let continue_level = ctx.ctrl_depth;
    ctx.loops.push((break_level, continue_level));
    let r = compile_stmts(ctx, body);
    ctx.loops.pop();
    r?;
    ctx.emit(we::Instruction::End); // continue block
    Ok(())
}

/// Lower a `for iter in range loop ...` statement. An Integer (or enumeration)
/// scalar `start:stop` / `start:step:stop` range uses an efficient counter loop
/// (no allocation); any other iterable — an array variable, an array literal, a
/// slice — is evaluated to an array once and iterated element by element
/// ([`compile_for_array`]).
fn compile_for(
    ctx: &mut FnCtx,
    iter: &ArcStr,
    range: &DAE::Exp,
    body: &Arc<List<Arc<DAE::Statement>>>,
    ty: &DAE::Type,
) -> Result<()> {
    if let DAE::Exp::RANGE { .. } = range {
        if matches!(sig_ty(ty), Ok(SigTy::Int)) {
            return compile_for_int_range(ctx, iter, range, body);
        }
    }
    compile_for_array(ctx, iter, range, body)
}

/// The counter-loop lowering for an Integer scalar range (see [`compile_for`]).
fn compile_for_int_range(
    ctx: &mut FnCtx,
    iter: &ArcStr,
    range: &DAE::Exp,
    body: &Arc<List<Arc<DAE::Statement>>>,
) -> Result<()> {
    let DAE::Exp::RANGE { start, step, stop, .. } = range else {
        bail!("CodegenWasmJit: for-loop over non-range expression not supported");
    };
    // Allocate the iterator local and stop/step locals.
    let it = ctx.alloc_temp(WTy::I32);
    ctx.locals.insert(iter.to_string(), (it, SigTy::Int));
    let stop_l = ctx.alloc_temp(WTy::I32);
    let step_l = ctx.alloc_temp(WTy::I32);

    let sw = compile_exp(ctx, start)?;
    coerce(ctx, sw, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(it));
    match step {
        Some(e) => {
            let w = compile_exp(ctx, e)?;
            coerce(ctx, w, WTy::I32);
        }
        None => ctx.emit(we::Instruction::I32Const(1)),
    }
    ctx.emit(we::Instruction::LocalSet(step_l));
    let pw = compile_exp(ctx, stop)?;
    coerce(ctx, pw, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(stop_l));

    // block { loop { (it>stop) -> br 1; block { body }; it+=step; br 0 } }
    // Assumes a positive step (the common case for generated loops). The inner
    // block is the `continue` target — falling through runs the increment.
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    let break_level = ctx.ctrl_depth;
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(it));
    ctx.emit(we::Instruction::LocalGet(stop_l));
    ctx.emit(we::Instruction::I32GtS);
    ctx.emit(we::Instruction::BrIf(1));
    compile_loop_body(ctx, break_level, body)?;
    ctx.emit(we::Instruction::LocalGet(it));
    ctx.emit(we::Instruction::LocalGet(step_l));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(it));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block
    Ok(())
}

/// Lower `for x in <array> loop ...`: evaluate the iterable to an array once,
/// then loop `k = 1..total`, binding `x` to `arr[k]` each pass. Handles array
/// literals, array variables and slices — any rank-1 vector.
///
/// The iterator binds a *borrowed* element: the array (`arr_t`) is held for the
/// whole loop, so `x` need not own a reference — the body's heap reads retain on
/// read and release on consume, staying balanced. The slot is recorded in
/// `borrowed_locals` so `release_heap_locals` skips it (it owns nothing), which
/// also makes `break`/early-`return` leak-safe.
fn compile_for_array(
    ctx: &mut FnCtx,
    iter: &ArcStr,
    range: &DAE::Exp,
    body: &Arc<List<Arc<DAE::Statement>>>,
) -> Result<()> {
    let SigTy::Array { elem, rank } = exp_sigty(range)? else {
        bail!("CodegenWasmJit: for-loop over non-array, non-range expression not supported");
    };
    if rank != 1 {
        bail!("CodegenWasmJit: for-loop over a multi-dimensional array not yet supported");
    }
    let elem = (*elem).clone();
    // Evaluate the iterable to an owned array handle.
    compile_exp(ctx, range)?;
    let arr_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(arr_t));
    // n = total element count; k = 1-based counter.
    let n = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalGet(arr_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_total")));
    ctx.emit(we::Instruction::LocalSet(n));
    let k = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::LocalSet(k));
    let it = ctx.alloc_temp(elem.wty());
    ctx.locals.insert(iter.to_string(), (it, elem.clone()));
    if elem.is_heap() {
        ctx.borrowed_locals.push(it);
    }

    // block { loop { k>n -> br 1; it = arr[k]; block { body }; k++; br 0 } }
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    let break_level = ctx.ctrl_depth;
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(k));
    ctx.emit(we::Instruction::LocalGet(n));
    ctx.emit(we::Instruction::I32GtS);
    ctx.emit(we::Instruction::BrIf(1));
    // it = arr[k] (borrowed; the array outlives the loop).
    ctx.emit(we::Instruction::LocalGet(arr_t));
    ctx.emit(we::Instruction::LocalGet(k));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
    elem_load(ctx, &elem);
    ctx.emit(we::Instruction::LocalSet(it));
    compile_loop_body(ctx, break_level, body)?;
    ctx.emit(we::Instruction::LocalGet(k));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(k));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block
    release_temp_array(ctx, arr_t);
    Ok(())
}

/// Emit a constant from a (scalar) `Values.Value` and coerce it to `wty`. Used
/// for a reduction's default/identity value.
fn emit_value_const(ctx: &mut FnCtx, v: &Values::Value, wty: WTy) -> Result<()> {
    let from = match v {
        Values::Value::INTEGER { integer } => {
            ctx.emit(we::Instruction::I32Const(*integer));
            WTy::I32
        }
        Values::Value::BOOL { boolean } => {
            ctx.emit(we::Instruction::I32Const(*boolean as i32));
            WTy::I32
        }
        Values::Value::REAL { real } => {
            ctx.emit(we::Instruction::F64Const(real.into_inner().into()));
            WTy::F64
        }
        other => bail!("CodegenWasmJit: unsupported reduction default value {other:?}"),
    };
    coerce(ctx, from, wty);
    Ok(())
}

/// Bind a single Integer-range reduction/comprehension iterator: evaluate
/// `start`/`step`/`stop` into fresh locals, register `id` as the iterator local
/// (initialized to `start`), and return `(it, step_l, stop_l)`. A positive step
/// is assumed (matching `compile_for`).
fn emit_range_iter(
    ctx: &mut FnCtx,
    id: &ArcStr,
    start: &DAE::Exp,
    step: &Option<Arc<DAE::Exp>>,
    stop: &DAE::Exp,
) -> Result<(u32, u32, u32)> {
    let it = ctx.alloc_temp(WTy::I32);
    ctx.locals.insert(id.to_string(), (it, SigTy::Int));
    let step_l = ctx.alloc_temp(WTy::I32);
    let stop_l = ctx.alloc_temp(WTy::I32);
    let sw = compile_exp(ctx, start)?;
    coerce(ctx, sw, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(it));
    match step {
        Some(e) => {
            let w = compile_exp(ctx, e)?;
            coerce(ctx, w, WTy::I32);
        }
        None => ctx.emit(we::Instruction::I32Const(1)),
    }
    ctx.emit(we::Instruction::LocalSet(step_l));
    let pw = compile_exp(ctx, stop)?;
    coerce(ctx, pw, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(stop_l));
    Ok((it, step_l, stop_l))
}

/// Evaluate an Integer range into a fresh local holding its element count,
/// `max(0, (stop - start)/step + 1)`. Used to size an array comprehension.
fn emit_range_count(
    ctx: &mut FnCtx,
    start: &DAE::Exp,
    step: &Option<Arc<DAE::Exp>>,
    stop: &DAE::Exp,
) -> Result<u32> {
    let cnt = ctx.alloc_temp(WTy::I32);
    let pw = compile_exp(ctx, stop)?;
    coerce(ctx, pw, WTy::I32);
    let sw = compile_exp(ctx, start)?;
    coerce(ctx, sw, WTy::I32);
    ctx.emit(we::Instruction::I32Sub);
    match step {
        Some(e) => {
            let w = compile_exp(ctx, e)?;
            coerce(ctx, w, WTy::I32);
        }
        None => ctx.emit(we::Instruction::I32Const(1)),
    }
    ctx.emit(we::Instruction::I32DivS);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(cnt));
    // clamp a negative count (empty range) to 0.
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalGet(cnt));
    ctx.emit(we::Instruction::LocalGet(cnt));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::I32LtS);
    ctx.emit(we::Instruction::Select);
    ctx.emit(we::Instruction::LocalSet(cnt));
    Ok(cnt)
}

/// Emit nested `for` loops over the given Integer-range iterators (the first is
/// the outermost), running `body` at the innermost point. Each iterator's
/// optional `guardExp` wraps the inner work in an `if`, so a filtered-out
/// combination is skipped. Relative branch depths make the nesting compose.
fn emit_red_nest(
    ctx: &mut FnCtx,
    iters: &[&Arc<DAE::ReductionIterator>],
    body: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    let Some((iter, rest)) = iters.split_first() else {
        return body(ctx);
    };
    let DAE::Exp::RANGE { start, step, stop, .. } = &*iter.exp else {
        bail!("CodegenWasmJit: reduction over a non-range iterator not supported");
    };
    let (it, step_l, stop_l) = emit_range_iter(ctx, &iter.id, start, step, stop)?;
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(it));
    ctx.emit(we::Instruction::LocalGet(stop_l));
    ctx.emit(we::Instruction::I32GtS);
    ctx.emit(we::Instruction::BrIf(1));
    match &iter.guardExp {
        Some(guard) => {
            let w = compile_exp(ctx, guard)?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            emit_red_nest(ctx, rest, &mut *body)?;
            ctx.emit(we::Instruction::End);
        }
        None => emit_red_nest(ctx, rest, &mut *body)?,
    }
    ctx.emit(we::Instruction::LocalGet(it));
    ctx.emit(we::Instruction::LocalGet(step_l));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(it));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block
    Ok(())
}

/// Lower an iterator reduction over Integer ranges. The folding forms
/// `sum/product/min/max(expr for i in A, j in B, ...)` (`foldExp` present) build
/// `acc = default; for i,j,... { acc = foldExp(acc, expr) }`, where `foldExp`
/// reads the accumulator (`resultName`) and per-iteration value (`foldName`) as
/// locals — so the same mechanism covers all four. The `array(...)`
/// comprehension (`foldExp` absent — `{expr for i in A, j in B}`) builds a fresh
/// array: its dimensions are the iterator counts in reverse order (the last
/// iterator is the outermost), filled row-major. Per-iterator `guardExp`s are
/// honored in the folding forms (a guarded array comprehension — a MetaModelica
/// list form — and non-scalar/heap elements bail loudly).
fn compile_reduction(
    ctx: &mut FnCtx,
    info: &DAE::ReductionInfo,
    expr: &DAE::Exp,
    iterators: &DAE::ReductionIterators,
) -> Result<WTy> {
    let iters: Vec<&Arc<DAE::ReductionIterator>> = (&**iterators).into_iter().collect();
    if iters.is_empty() {
        bail!("CodegenWasmJit: reduction with no iterators");
    }

    if let Some(fold) = &info.foldExp {
        // Folding reduction. `info.exprType` is the (scalar) accumulator type.
        let elem_sty = sig_ty(&info.exprType)?;
        if elem_sty.is_heap() {
            bail!("CodegenWasmJit: non-scalar reduction result not supported");
        }
        let elem_wty = elem_sty.wty();
        let Some(default) = &info.defaultValue else {
            bail!("CodegenWasmJit: reduction without a default value not supported");
        };
        let acc = ctx.alloc_temp(elem_wty);
        let foldval = ctx.alloc_temp(elem_wty);
        ctx.locals.insert(info.resultName.to_string(), (acc, elem_sty.clone()));
        ctx.locals.insert(info.foldName.to_string(), (foldval, elem_sty.clone()));
        emit_value_const(ctx, default, elem_wty)?;
        ctx.emit(we::Instruction::LocalSet(acc));
        emit_red_nest(ctx, &iters, &mut |ctx| {
            let w = compile_exp(ctx, expr)?;
            coerce(ctx, w, elem_wty);
            ctx.emit(we::Instruction::LocalSet(foldval));
            let fw = compile_exp(ctx, fold)?;
            coerce(ctx, fw, elem_wty);
            ctx.emit(we::Instruction::LocalSet(acc));
            Ok(())
        })?;
        ctx.emit(we::Instruction::LocalGet(acc));
        return Ok(elem_wty);
    }

    // `array(...)` comprehension. The element type is the per-iteration
    // expression's type (`info.exprType` is the whole array type here).
    if iters.iter().any(|it| it.guardExp.is_some()) {
        bail!("CodegenWasmJit: guarded array comprehension not supported");
    }
    let elem_sty = exp_sigty(expr)?;
    if elem_sty.is_heap() {
        bail!("CodegenWasmJit: array comprehension with non-scalar elements not supported");
    }
    let elem_wty = elem_sty.wty();
    let n = iters.len() as u32;

    // Per-iterator element counts (forward order).
    let mut counts = Vec::with_capacity(iters.len());
    for it in &iters {
        let DAE::Exp::RANGE { start, step, stop, .. } = &*it.exp else {
            bail!("CodegenWasmJit: array comprehension over a non-range iterator not supported");
        };
        counts.push(emit_range_count(ctx, start, step, stop)?);
    }
    // total = product of the counts.
    let total = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::LocalSet(total));
    for c in &counts {
        ctx.emit(we::Instruction::LocalGet(total));
        ctx.emit(we::Instruction::LocalGet(*c));
        ctx.emit(we::Instruction::I32Mul);
        ctx.emit(we::Instruction::LocalSet(total));
    }
    // Allocate the result; its dimensions are the counts in reverse iterator
    // order (the last iterator is the outermost / slowest-varying dimension).
    let res = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(elem_sty.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(n as i32));
    ctx.emit(we::Instruction::LocalGet(total));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")));
    ctx.emit(we::Instruction::LocalSet(res));
    for d in 0..n {
        let c = counts[(n - 1 - d) as usize];
        ctx.emit(we::Instruction::LocalGet(res));
        ctx.emit(we::Instruction::I32Const(d as i32));
        ctx.emit(we::Instruction::LocalGet(c));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")));
    }
    // Fill row-major: nest with the last iterator outermost so the running index
    // advances with the first iterator fastest.
    let idx = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalSet(idx));
    let rev: Vec<&Arc<DAE::ReductionIterator>> = iters.iter().rev().cloned().collect();
    let store_sty = elem_sty.clone();
    emit_red_nest(ctx, &rev, &mut |ctx| {
        ctx.emit(we::Instruction::LocalGet(res));
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::I32Add);
        ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
        let w = compile_exp(ctx, expr)?;
        coerce(ctx, w, elem_wty);
        elem_store(ctx, &store_sty);
        ctx.emit(we::Instruction::LocalGet(idx));
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::I32Add);
        ctx.emit(we::Instruction::LocalSet(idx));
        Ok(())
    })?;
    ctx.emit(we::Instruction::LocalGet(res));
    Ok(WTy::I32)
}

// -------------------------------------------------------------------------
// Expression compilation
// -------------------------------------------------------------------------

/// Compile an expression, leaving exactly one value on the wasm stack; returns
/// its type.
/// Canonical string key for a component reference, used to match equation crefs
/// against the `SimVars` model-variable names (`CodegenWasmJit`). Identifiers
/// are joined with `.`; constant integer subscripts are appended as `[i]` (the
/// SimCode is scalarized, so a scalar element's subscripts are part of its
/// identity). The `$DER`/`$PRE`/`$START` qualifier idents are kept verbatim so
/// `der(x)` (cref `$DER.x`) keys distinctly from `x`.
pub(crate) fn sim_cref_key(cr: &DAE::ComponentRef) -> Result<String> {
    let mut s = String::new();
    sim_cref_key_into(cr, &mut s)?;
    Ok(s)
}

fn sim_cref_key_into(cr: &DAE::ComponentRef, s: &mut String) -> Result<()> {
    use DAE::ComponentRef as C;
    match cr {
        C::CREF_IDENT { ident, subscriptLst, .. } => {
            s.push_str(ident);
            sim_subs_into(subscriptLst, s)?;
        }
        C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
            s.push_str(ident);
            sim_subs_into(subscriptLst, s)?;
            s.push('.');
            sim_cref_key_into(componentRef, s)?;
        }
        other => bail!("CodegenWasmJit: unsupported component reference in simulation: {other:?}"),
    }
    Ok(())
}

fn sim_subs_into(subs: &Arc<List<Arc<DAE::Subscript>>>, s: &mut String) -> Result<()> {
    for sub in &**subs {
        match &**sub {
            DAE::Subscript::INDEX { exp } => match &**exp {
                DAE::Exp::ICONST { integer } => {
                    s.push('[');
                    s.push_str(&integer.to_string());
                    s.push(']');
                }
                DAE::Exp::ENUM_LITERAL { index, .. } => {
                    s.push('[');
                    s.push_str(&index.to_string());
                    s.push(']');
                }
                other => bail!("CodegenWasmJit: non-constant subscript in simulation cref: {other:?}"),
            },
            other => bail!("CodegenWasmJit: unsupported subscript in simulation cref: {other:?}"),
        }
    }
    Ok(())
}

/// In simulation mode, try to read a model variable from the `SimData` block.
/// Returns `Some(wty)` when `cref` resolved to a model variable (state,
/// derivative, algebraic, parameter, `time`, or a `$START`/`$PRE` access), or
/// `None` when it is an ordinary wasm local (a lowering temporary / iterator)
/// that the normal cref path should handle.
fn compile_sim_cref_read(ctx: &mut FnCtx, cref: &DAE::ComponentRef) -> Result<Option<WTy>> {
    if ctx.sim.is_none() {
        return Ok(None);
    }
    // `time` is the only built-in scalar; it lives at offset 0 of `SimData`.
    if let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = cref {
        if subscriptLst.is_empty() {
            if ident.as_str() == "time" {
                let data = ctx.sim.as_ref().unwrap().data_local;
                ctx.emit(we::Instruction::LocalGet(data));
                ctx.emit(we::Instruction::F64Load(mem_arg(0, 3)));
                return Ok(Some(WTy::F64));
            }
            // A real wasm local (e.g. a `for` iterator) shadows model lookup.
            if ctx.locals.contains_key(ident.as_str()) {
                return Ok(None);
            }
        }
    }
    // `$START.<cref>`: read the variable's start-attribute expression (used by
    // the initial-equation system). `$PRE.<cref>`: the value at the last event;
    // for the continuous models handled so far it equals the current value, so
    // we read the live slot (discrete/event handling is future work).
    if let DAE::ComponentRef::CREF_QUAL { ident, componentRef, .. } = cref {
        match ident.as_str() {
            "$START" => {
                let key = sim_cref_key(componentRef)?;
                let start = ctx.sim.as_ref().unwrap().starts.get(&key).cloned();
                return match start {
                    Some(Some(exp)) => Ok(Some(compile_exp(ctx, &exp)?)),
                    Some(None) => {
                        // No explicit start: the type default (0.0 for Real).
                        ctx.emit(we::Instruction::F64Const(0.0.into()));
                        Ok(Some(WTy::F64))
                    }
                    None => bail!("CodegenWasmJit: $START for unknown variable `{key}`"),
                };
            }
            "$PRE" => return compile_sim_cref_read(ctx, componentRef),
            _ => {}
        }
    }
    let key = sim_cref_key(cref)?;
    let slot = match ctx.sim.as_ref().unwrap().vars.get(&key) {
        Some(s) => *s,
        None => {
            // Not a scalar slot: it may be a whole array-valued model variable,
            // whose scalarized elements occupy a contiguous slot range. Gather the
            // range into a fresh runtime array object.
            if let Some(group) = ctx.sim.as_ref().unwrap().array_groups.get(&key).cloned() {
                emit_sim_array_gather(ctx, &group);
                return Ok(Some(WTy::I32));
            }
            bail!("CodegenWasmJit: simulation reference to unknown variable `{key}`")
        }
    };
    let data = ctx.sim.as_ref().unwrap().data_local;
    ctx.emit(we::Instruction::LocalGet(data));
    match slot.wty {
        WTy::F64 => {
            ctx.emit(we::Instruction::F64Load(mem_arg(slot.off, 3)));
            if slot.negate {
                ctx.emit(we::Instruction::F64Neg);
            }
        }
        WTy::I32 => {
            ctx.emit(we::Instruction::I32Load(mem_arg(slot.off, 2)));
            if slot.negate {
                // Integer negate; a Boolean negated alias uses `!` but is stored
                // as 0/1 — handled when Boolean aliases are added.
                ctx.emit(we::Instruction::I32Const(0));
                ctx.emit(we::Instruction::I32Sub);
            }
        }
    }
    if slot.heap {
        // Reading a heap (String) slot yields an owned reference, like reading a
        // heap local: retain so the slot keeps its reference while the value flows
        // into the consuming operation. (`rt_retain` is null-safe.)
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::I32Load(mem_arg(slot.off, 2)));
        ctx.emit(we::Instruction::Call(rt_index("rt_retain")));
    }
    Ok(Some(slot.wty))
}

/// In simulation mode, try to assign to a model variable in the `SimData`
/// block. Returns `true` when `cref` resolved to a writable model variable.
/// Aliases are never assigned (they are removed by the backend); `$START`/`time`
/// are not assignment targets in the equation systems handled here.
fn compile_sim_cref_assign(ctx: &mut FnCtx, cref: &DAE::ComponentRef, rhs: &DAE::Exp) -> Result<bool> {
    if ctx.sim.is_none() {
        return Ok(false);
    }
    // `$START.x := expr` in the initial system: the C target sets `x`'s start
    // attribute *and* the live value `realVars[x] = start` (see the
    // `$START.<cref>`-LHS pattern in `_06inz`). The numeric effect is `x := expr`,
    // so redirect the assignment to the underlying variable's live slot. (Reads of
    // `$START.x` still resolve to the start attribute via `compile_sim_cref_read`,
    // which is consistent — the start expression equals the assigned value.)
    if let DAE::ComponentRef::CREF_QUAL { ident, componentRef, .. } = cref {
        if ident.as_str() == "$START" {
            return compile_sim_cref_assign(ctx, componentRef, rhs);
        }
    }
    // Plain idents that are wasm locals are handled by the normal path.
    if let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = cref {
        if subscriptLst.is_empty() && ctx.locals.contains_key(ident.as_str()) {
            return Ok(false);
        }
    }
    let key = sim_cref_key(cref)?;
    let slot = match ctx.sim.as_ref().unwrap().vars.get(&key) {
        Some(s) => *s,
        None => {
            // A whole array-valued model variable: evaluate the rhs to a runtime
            // array and scatter its elements into the contiguous slot range.
            if let Some(group) = ctx.sim.as_ref().unwrap().array_groups.get(&key).cloned() {
                emit_sim_array_scatter(ctx, &group, rhs)?;
                return Ok(true);
            }
            bail!("CodegenWasmJit: simulation assignment to unknown variable `{key}`")
        }
    };
    if slot.negate {
        bail!("CodegenWasmJit: assignment to negated alias `{key}`");
    }
    let data = ctx.sim.as_ref().unwrap().data_local;
    if slot.heap {
        // Release the handle the slot currently holds before overwriting it with
        // the new (owned) one; the rhs reference transfers into the slot. The slot
        // starts null (zeroed `SimData`), and `rt_release` is null-safe.
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::I32Load(mem_arg(slot.off, 2)));
        ctx.emit(we::Instruction::Call(rt_index("rt_release")));
    }
    // Stack order for a store is [addr, value]: push the base, evaluate the rhs,
    // coerce to the slot type, then store at the constant offset.
    ctx.emit(we::Instruction::LocalGet(data));
    let rw = compile_exp(ctx, rhs)?;
    coerce(ctx, rw, slot.wty);
    match slot.wty {
        WTy::F64 => ctx.emit(we::Instruction::F64Store(mem_arg(slot.off, 3))),
        WTy::I32 => ctx.emit(we::Instruction::I32Store(mem_arg(slot.off, 2))),
    }
    Ok(true)
}

/// The `(elem_kind, byte_stride)` pair for an array of `wty` scalars: Real maps
/// to `EK_REAL`/8, Integer/Boolean to `EK_INT`/4. (A whole-array Boolean model
/// variable is tagged `EK_INT`; the two share 4-byte storage and no in-scope
/// builtin distinguishes them — revisit if a Boolean-array external appears.)
fn sim_array_elem_kind_stride(wty: WTy) -> (u32, u32) {
    match wty {
        WTy::F64 => (SigTy::Real.elem_kind(), 8),
        WTy::I32 => (SigTy::Int.elem_kind(), 4),
    }
}

/// Emit code that gathers a whole array-valued model variable from its
/// contiguous `SimData` slot range into a fresh (refcount-1) runtime array
/// object, leaving the owned handle on the stack. The slots are stored
/// row-major and contiguously (verified at layout time), so the element data is
/// one `memory.copy` from the slot range into the new object's data area.
fn emit_sim_array_gather(ctx: &mut FnCtx, group: &ArrayGroup) {
    let (ek, stride) = sim_array_elem_kind_stride(group.wty);
    let ndims = group.dims.len() as u32;
    let data = ctx.sim.as_ref().unwrap().data_local;
    let obj = ctx.alloc_temp(WTy::I32);
    // obj = rt_array_new(elem_kind, ndims, total); set each dimension.
    ctx.emit(we::Instruction::I32Const(ek as i32));
    ctx.emit(we::Instruction::I32Const(ndims as i32));
    ctx.emit(we::Instruction::I32Const(group.total as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")));
    ctx.emit(we::Instruction::LocalSet(obj));
    for (axis, d) in group.dims.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::I32Const(*d as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")));
    }
    // memory.copy(dst = obj data, src = SimData + base_off, len = total * stride).
    ctx.emit(we::Instruction::LocalGet(obj));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
    ctx.emit(we::Instruction::LocalGet(data));
    ctx.emit(we::Instruction::I32Const(group.base_off as i32));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::I32Const((group.total * stride) as i32));
    ctx.emit(we::Instruction::MemoryCopy { src_mem: 0, dst_mem: 0 });
    ctx.emit(we::Instruction::LocalGet(obj));
}

/// Emit code that scatters a whole-array assignment into a model variable's
/// contiguous `SimData` slot range: evaluate `rhs` to an owned runtime array,
/// `memory.copy` its (row-major, scalar) element data over the slots, then
/// release the handle. Real/Integer elements are flat scalars, so the bulk copy
/// is a complete (deep) value copy — no per-element retain is needed.
fn emit_sim_array_scatter(ctx: &mut FnCtx, group: &ArrayGroup, rhs: &DAE::Exp) -> Result<()> {
    let (_, stride) = sim_array_elem_kind_stride(group.wty);
    let data = ctx.sim.as_ref().unwrap().data_local;
    let h = ctx.alloc_temp(WTy::I32);
    let rw = compile_exp(ctx, rhs)?;
    if rw != WTy::I32 {
        bail!("CodegenWasmJit: whole-array assignment rhs is not an array handle");
    }
    ctx.emit(we::Instruction::LocalSet(h));
    // memory.copy(dst = SimData + base_off, src = rhs data, len = total * stride).
    ctx.emit(we::Instruction::LocalGet(data));
    ctx.emit(we::Instruction::I32Const(group.base_off as i32));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalGet(h));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
    ctx.emit(we::Instruction::I32Const((group.total * stride) as i32));
    ctx.emit(we::Instruction::MemoryCopy { src_mem: 0, dst_mem: 0 });
    // Consume the rhs reference (we copied out the element data, not the handle).
    ctx.emit(we::Instruction::LocalGet(h));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_release")));
    Ok(())
}

/// Emit one residual evaluation for a torn linear system: run the inner
/// constraint equations (`lower_inner`), then store each residual `r_k` as an f64
/// at `base + dest_off + k*8`. Used by [`compile_linear_system`] for each probe.
fn emit_residual_eval(
    ctx: &mut FnCtx,
    base: u32,
    res_exps: &[&Arc<DAE::Exp>],
    dest_off: u32,
    lower_inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    lower_inner(ctx)?;
    for (k, exp) in res_exps.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(base));
        let w = compile_exp(ctx, exp)?;
        coerce(ctx, w, WTy::F64);
        ctx.emit(we::Instruction::F64Store(mem_arg(dest_off + (k as u32) * 8, 3)));
    }
    Ok(())
}

/// Lower a torn linear system `A x = b` (the `SES_LINEAR` residual form) into the
/// current simulation equation function.
///
/// The system solves `iter_vars` (the `n` tearing unknowns). `lower_inner` lowers
/// the inner "local constraint" equations, which compute the torn variables (and
/// any intermediates) from the current values of `iter_vars`; `res_exps` are the
/// `n` residual expressions `r_i`, where the system is `r(x) = 0`. Because the
/// system is linear, `r(x) = A x - b`, so we recover `A` and `b` exactly by
/// probing the residual (the numerical-Jacobian approach the C runtime uses when
/// `setA == NULL`):
///   * `b_i = -r_i(0)` — residual with all unknowns set to 0;
///   * `A[i][j] = r_i(e_j) - r_i(0)` — residual with unknown `j` set to 1.
/// Then `rt_linsolve` (LU with partial pivoting) solves `A x = b` in place, the
/// solution is scattered back into `iter_vars`, and the inner equations are run
/// once more so the torn variables are consistent with the solution.
///
/// `lower_inner` is invoked `n + 2` times (once per probe + once to recover); the
/// inner equations read the unknowns from their `SimData` slots, which this code
/// sets before each invocation.
pub(crate) fn compile_linear_system(
    ctx: &mut FnCtx,
    iter_vars: &[Arc<DAE::ComponentRef>],
    res_exps: &[&Arc<DAE::Exp>],
    lower_inner: &mut dyn FnMut(&mut FnCtx) -> Result<()>,
) -> Result<()> {
    let n = iter_vars.len();
    if n == 0 {
        return Ok(());
    }
    if res_exps.len() != n {
        bail!(
            "CodegenWasmJit: linear system has {n} unknowns but {} residuals",
            res_exps.len()
        );
    }
    // Resolve each unknown to its (real) SimData slot offset.
    let mut slots: Vec<u32> = Vec::with_capacity(n);
    for cr in iter_vars {
        let key = sim_cref_key(cr)?;
        let slot = ctx
            .sim
            .as_ref()
            .unwrap()
            .vars
            .get(&key)
            .copied()
            .ok_or_else(|| anyhow::anyhow!("CodegenWasmJit: linear-system unknown `{key}` has no slot"))?;
        if slot.wty != WTy::F64 {
            bail!("CodegenWasmJit: linear-system unknown `{key}` is not a Real variable");
        }
        slots.push(slot.off);
    }
    let data = ctx.sim.as_ref().unwrap().data_local;

    // One scratch block: A (n*n, column-major) | b (n) | res0 (n) | rescol (n).
    let a_off: u32 = 0;
    let b_off: u32 = (n * n * 8) as u32;
    let res0_off: u32 = ((n * n + n) * 8) as u32;
    let rescol_off: u32 = ((n * n + 2 * n) * 8) as u32;
    let scratch_bytes: u32 = ((n * n + 3 * n) * 8) as u32;

    let base = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(scratch_bytes as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_alloc")));
    ctx.emit(we::Instruction::LocalSet(base));

    // Set unknown `j` to a literal 0.0 / 1.0 in its SimData slot.
    let set_unknown = |ctx: &mut FnCtx, slot_off: u32, val: f64| {
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::F64Const(val.into()));
        ctx.emit(we::Instruction::F64Store(mem_arg(slot_off, 3)));
    };

    // --- b = -r(0): all unknowns 0, residual into res0, then negate into b. ---
    for &off in &slots {
        set_unknown(ctx, off, 0.0);
    }
    emit_residual_eval(ctx, base, res_exps, res0_off, lower_inner)?;
    for i in 0..n {
        let i = i as u32;
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::F64Load(mem_arg(res0_off + i * 8, 3)));
        ctx.emit(we::Instruction::F64Neg);
        ctx.emit(we::Instruction::F64Store(mem_arg(b_off + i * 8, 3)));
    }

    // --- A columns: unknown `col` set to 1, the rest 0; A[:,col] = r(e_col) - r(0). ---
    for col in 0..n {
        for (j, &off) in slots.iter().enumerate() {
            set_unknown(ctx, off, if j == col { 1.0 } else { 0.0 });
        }
        emit_residual_eval(ctx, base, res_exps, rescol_off, lower_inner)?;
        for i in 0..n {
            let i_u = i as u32;
            let elem_off = a_off + ((col * n + i) as u32) * 8; // column-major
            ctx.emit(we::Instruction::LocalGet(base));
            ctx.emit(we::Instruction::LocalGet(base));
            ctx.emit(we::Instruction::F64Load(mem_arg(rescol_off + i_u * 8, 3)));
            ctx.emit(we::Instruction::LocalGet(base));
            ctx.emit(we::Instruction::F64Load(mem_arg(res0_off + i_u * 8, 3)));
            ctx.emit(we::Instruction::F64Sub);
            ctx.emit(we::Instruction::F64Store(mem_arg(elem_off, 3)));
        }
    }

    // --- solve A x = b in place (b <- x); trap on a singular system. ---
    ctx.emit(we::Instruction::LocalGet(base)); // a_ptr (a_off == 0)
    ctx.emit(we::Instruction::LocalGet(base));
    ctx.emit(we::Instruction::I32Const(b_off as i32));
    ctx.emit(we::Instruction::I32Add); // b_ptr
    ctx.emit(we::Instruction::I32Const(n as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_linsolve")));
    ctx.emit(we::Instruction::If(we::BlockType::Empty)); // nonzero => singular
    ctx.emit(we::Instruction::Unreachable);
    ctx.emit(we::Instruction::End);

    // --- scatter the solution into the unknown slots. ---
    for j in 0..n {
        ctx.emit(we::Instruction::LocalGet(data));
        ctx.emit(we::Instruction::LocalGet(base));
        ctx.emit(we::Instruction::F64Load(mem_arg(b_off + (j as u32) * 8, 3)));
        ctx.emit(we::Instruction::F64Store(mem_arg(slots[j], 3)));
    }

    // --- recover the torn variables: re-run the inner equations at the solution. ---
    lower_inner(ctx)?;

    // --- free the scratch block. ---
    ctx.emit(we::Instruction::LocalGet(base));
    ctx.emit(we::Instruction::Call(rt_index("rt_free")));
    Ok(())
}

fn compile_exp(ctx: &mut FnCtx, exp: &DAE::Exp) -> Result<WTy> {
    use DAE::Exp as E;
    match exp {
        E::ICONST { integer } => {
            ctx.emit(we::Instruction::I32Const(*integer));
            Ok(WTy::I32)
        }
        E::BCONST { bool } => {
            ctx.emit(we::Instruction::I32Const(*bool as i32));
            Ok(WTy::I32)
        }
        E::RCONST { real } => {
            ctx.emit(we::Instruction::F64Const(real.into_inner().into()));
            Ok(WTy::F64)
        }
        E::ENUM_LITERAL { index, .. } => {
            ctx.emit(we::Instruction::I32Const(*index));
            Ok(WTy::I32)
        }
        // The frontend interns constant literals (strings, but also numeric
        // ones) into a shared pool; the wrapper carries the underlying constant
        // expression, which is what we lower.
        E::SHARED_LITERAL { exp, .. } => compile_exp(ctx, exp),
        // A String literal: materialize a fresh (refcount 1) String from its
        // passive data segment with `memory.init`, so the value is owned exactly
        // like any other heap-producing expression.
        E::SCONST { string } => {
            emit_str_literal(ctx, string.as_bytes());
            Ok(WTy::I32)
        }
        E::CREF { componentRef, .. } => {
            // Simulation mode: model variables (states, derivatives, algebraics,
            // parameters, `time`, `$START`/`$PRE`) live in the shared `SimData`
            // block, not in wasm locals. Resolve those first; `None` means an
            // ordinary local that the normal path below handles.
            if let Some(wty) = compile_sim_cref_read(ctx, componentRef)? {
                return Ok(wty);
            }
            // A qualified cref `base[..].f1[..].….fn[..]`: descend through nested
            // records (and arrays of records) to the final field.
            if let DAE::ComponentRef::CREF_QUAL { .. } = &**componentRef {
                return compile_cref_read_qual(ctx, componentRef);
            }
            // A scalar/whole-value reference, or a subscripted array element.
            let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = &**componentRef else {
                bail!("CodegenWasmJit: unsupported component reference {componentRef:?}");
            };
            let name = ident.to_string();
            let (idx, sty) = ctx
                .locals
                .get(&name)
                .ok_or_else(|| anyhow::anyhow!("CodegenWasmJit: reference to unknown variable `{name}`"))?
                .clone();
            if subscriptLst.is_empty() {
                ctx.emit(we::Instruction::LocalGet(idx));
                // Reading a heap local yields an *owned* value: retain so the
                // local keeps its reference while the value flows into an
                // operation / assignment / call that will consume one reference.
                // `rt_retain` just bumps the refcount at offset 0, shared by
                // strings and arrays.
                if sty.is_heap() {
                    ctx.emit(we::Instruction::LocalGet(idx));
                    ctx.emit(we::Instruction::Call(rt_index("rt_retain")));
                }
                Ok(sty.wty())
            } else {
                // Indexed read `v[i, ...]`: push the (retained, owned) array
                // handle, then load the element (which releases the handle).
                let SigTy::Array { elem, rank } = sty else {
                    bail!("CodegenWasmJit: subscripting non-array local `{name}`");
                };
                ctx.emit(we::Instruction::LocalGet(idx));
                ctx.emit(we::Instruction::LocalGet(idx));
                ctx.emit(we::Instruction::Call(rt_index("rt_retain")));
                if is_scalar_index(subscriptLst, rank) {
                    let idx_exps = index_subscripts(subscriptLst, rank)?;
                    index_loaded(ctx, &elem, &idx_exps)
                } else {
                    slice_loaded(ctx, subscriptLst)
                }
            }
        }
        E::CAST { ty, exp } => {
            let target = sig_ty(ty)?;
            // Array casts: the only implicit numeric array cast is Integer[] ->
            // Real[] (e.g. `Real r := intArray`, mixed arithmetic, and division
            // which always yields Real). It must rebuild the array with f64
            // elements — a scalar `coerce` would leave the i32 data misread as
            // f64. Any other array cast is representationally a no-op (the handle
            // already has the right element layout).
            if let SigTy::Array { elem: tgt_elem, .. } = &target {
                let src_is_int = matches!(exp_sigty(exp), Ok(SigTy::Array { ref elem, .. }) if elem.wty() == WTy::I32);
                if tgt_elem.wty() == WTy::F64 && src_is_int {
                    compile_exp(ctx, exp)?; // owned Integer array
                    let at = ctx.alloc_temp(WTy::I32);
                    ctx.emit(we::Instruction::LocalSet(at));
                    ctx.emit(we::Instruction::LocalGet(at));
                    ctx.emit(we::Instruction::Call(rt_index("rt_array_int_to_real")));
                    release_temp_array(ctx, at);
                } else {
                    compile_exp(ctx, exp)?;
                }
                return Ok(WTy::I32);
            }
            let from = compile_exp(ctx, exp)?;
            let to = target.wty();
            coerce(ctx, from, to);
            Ok(to)
        }
        E::UNARY { operator, exp } => compile_unary(ctx, operator, exp),
        E::LUNARY { operator, exp } => {
            // `not` — the only logical unary.
            let DAE::Operator::NOT { .. } = operator else {
                bail!("CodegenWasmJit: unsupported logical unary operator {operator:?}");
            };
            // Element-wise `not` over a Boolean array.
            if matches!(exp_sigty(exp), Ok(SigTy::Array { .. })) {
                emit_unary_array(ctx, exp, "rt_array_not_i32")?;
                return Ok(WTy::I32);
            }
            let w = compile_exp(ctx, exp)?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::I32Eqz);
            Ok(WTy::I32)
        }
        E::BINARY { exp1, operator, exp2 } => compile_binary(ctx, exp1, operator, exp2),
        E::LBINARY { exp1, operator, exp2 } => {
            // Element-wise `and`/`or` over Boolean arrays (operands are array
            // handles, not i32 truth values — a scalar I32And would corrupt them).
            if matches!(exp_sigty(exp1), Ok(SigTy::Array { .. })) {
                let (op_code, ty) = match operator {
                    DAE::Operator::AND { ty } => (OP_AND, ty),
                    DAE::Operator::OR { ty } => (OP_OR, ty),
                    other => bail!("CodegenWasmJit: unsupported logical array operator {other:?}"),
                };
                return compile_array_ew(ctx, exp1, exp2, op_code, ty);
            }
            let a = compile_exp(ctx, exp1)?;
            coerce(ctx, a, WTy::I32);
            let b = compile_exp(ctx, exp2)?;
            coerce(ctx, b, WTy::I32);
            match operator {
                DAE::Operator::AND { .. } => ctx.emit(we::Instruction::I32And),
                DAE::Operator::OR { .. } => ctx.emit(we::Instruction::I32Or),
                other => bail!("CodegenWasmJit: unsupported logical binary operator {other:?}"),
            }
            Ok(WTy::I32)
        }
        E::RELATION { exp1, operator, exp2, .. } => compile_relation(ctx, exp1, operator, exp2),
        E::IFEXP { expCond, expThen, expElse } => {
            let c = compile_exp(ctx, expCond)?;
            coerce(ctx, c, WTy::I32);
            // Determine the result type from the then-branch; both branches are
            // coerced to it.
            let result_wty = exp_wty_hint(ctx, expThen)?;
            ctx.emit(we::Instruction::If(we::BlockType::Result(result_wty.val())));
            let t = compile_exp(ctx, expThen)?;
            coerce(ctx, t, result_wty);
            ctx.emit(we::Instruction::Else);
            let e = compile_exp(ctx, expElse)?;
            coerce(ctx, e, result_wty);
            ctx.emit(we::Instruction::End);
            Ok(result_wty)
        }
        E::CALL { path, expLst, attr } => {
            let results = compile_call(ctx, path, expLst, attr)?;
            match results.len() {
                1 => Ok(results[0].wty()),
                0 => bail!("CodegenWasmJit: call to {} used in expression position returns no value", mangle(path)?),
                _ => bail!("CodegenWasmJit: call to {} returns multiple values; not usable in expression position", mangle(path)?),
            }
        }
        // Array constructor `{e1, e2, ...}` or matrix `{{...}, {...}}`.
        E::ARRAY { ty, .. } | E::MATRIX { ty, .. } => {
            compile_array_literal(ctx, ty, exp)?;
            Ok(WTy::I32)
        }
        // A range used as an array value, e.g. `a := 1:n` or `1:2:m`.
        E::RANGE { ty, start, step, stop } => {
            compile_range_array(ctx, ty, start, step.as_deref(), stop)?;
            Ok(WTy::I32)
        }
        // Array subscription `a[i]` (single index into a 1-D array).
        E::ASUB { exp, sub } => compile_index(ctx, exp, sub),
        // `size(a)` / `size(a, d)`.
        E::SIZE { exp, sz } => {
            compile_size(ctx, exp, sz.as_deref())?;
            Ok(WTy::I32)
        }
        // Record constructor `R(field=…, …)`.
        E::RECORD { ty, exps, comp, .. } => {
            compile_record(ctx, ty, exps, comp)?;
            Ok(WTy::I32)
        }
        // Record field access on an expression result: `f().field`.
        E::RSUB { exp, fieldName, .. } => compile_rsub(ctx, exp, fieldName),
        E::REDUCTION { reductionInfo, expr, iterators } => {
            compile_reduction(ctx, reductionInfo, expr, iterators)
        }
        other => bail!("CodegenWasmJit: expression not yet supported: {other:?}"),
    }
}

/// A cheap static guess of an expression's wasm type, used to pick the result
/// type of an `if`-expression block before compiling the branches.
fn exp_wty_hint(ctx: &FnCtx, exp: &DAE::Exp) -> Result<WTy> {
    use DAE::Exp as E;
    Ok(match exp {
        E::RCONST { .. } => WTy::F64,
        E::ICONST { .. } | E::BCONST { .. } | E::ENUM_LITERAL { .. } | E::SCONST { .. } | E::RELATION { .. } | E::LBINARY { .. } | E::LUNARY { .. } => WTy::I32,
        E::CAST { ty, .. } => sig_ty(ty)?.wty(),
        // The CREF carries its (possibly field) type directly — handles a plain
        // local and a `r.field` reference alike.
        E::CREF { ty, .. } => sig_ty(ty)?.wty(),
        E::BINARY { operator, .. } => operator_wty(operator)?,
        E::UNARY { operator, .. } => operator_wty(operator)?,
        E::IFEXP { expThen, .. } => exp_wty_hint(ctx, expThen)?,
        E::CALL { attr, .. } => sig_ty(&attr.ty)?.wty(),
        E::SHARED_LITERAL { exp, .. } => exp_wty_hint(ctx, exp)?,
        // Array/record handles and `size(a, d)` are `i32`; an array element's /
        // record field's wasm type comes from its element / field type.
        E::ARRAY { .. } | E::MATRIX { .. } | E::RANGE { .. } | E::SIZE { .. } | E::RECORD { .. } => WTy::I32,
        E::REDUCTION { reductionInfo, .. } => sig_ty(&reductionInfo.exprType)?.wty(),
        E::RSUB { ty, .. } => sig_ty(ty)?.wty(),
        E::ASUB { .. } => exp_sigty(exp).map(|s| s.wty()).unwrap_or(WTy::I32),
        _ => WTy::F64,
    })
}

fn operator_wty(op: &DAE::Operator) -> Result<WTy> {
    Ok(operator_sigty(op)?.wty())
}

/// The integer value of a `Real` literal exponent, or `None` if it is not an
/// integral `RCONST` — mirrors the frontend's `Expression.realExpIntLit`, which
/// the C target uses to pick the `real_int_pow` (repeated-multiply) path for
/// scalar integer powers. Matching it exactly keeps the choice (and the output)
/// in lockstep with the C target.
fn real_exp_int_lit(e: &DAE::Exp) -> Option<i32> {
    if let DAE::Exp::RCONST { real } = e {
        let r = real.into_inner();
        let i = r.floor() as i32;
        if r == i as f64 { Some(i) } else { None }
    } else {
        None
    }
}

/// Whether a `Real` literal exponent is exactly `0.5` — mirrors the frontend's
/// `Expression.isHalf`, which the C target uses to lower `x ^ 0.5` to `sqrt`.
fn exp_is_half(e: &DAE::Exp) -> bool {
    matches!(e, DAE::Exp::RCONST { real } if real.into_inner() == 0.5)
}

/// The `SigTy` an arithmetic operator works on / produces. Unlike
/// [`operator_wty`] this distinguishes Integer/Boolean and, crucially, String
/// (so `+` on Strings can be lowered to `rt_concat` rather than `i32.add`).
fn operator_sigty(op: &DAE::Operator) -> Result<SigTy> {
    use DAE::Operator as O;
    let ty = match op {
        O::ADD { ty } | O::SUB { ty } | O::MUL { ty } | O::DIV { ty } | O::POW { ty } | O::UMINUS { ty } => ty,
        // Scalar/matrix products carry the element (scalar-product) or result
        // (matrix-product) type; `sig_ty` yields the produced value's `SigTy`.
        O::MUL_SCALAR_PRODUCT { ty } | O::MUL_MATRIX_PRODUCT { ty } => ty,
        // Element-wise and array/scalar operators all carry the (array) result
        // type. `sig_ty` turns it into the `SigTy::Array { .. }` value type.
        O::UMINUS_ARR { ty }
        | O::ADD_ARR { ty }
        | O::SUB_ARR { ty }
        | O::MUL_ARR { ty }
        | O::DIV_ARR { ty }
        | O::MUL_ARRAY_SCALAR { ty }
        | O::ADD_ARRAY_SCALAR { ty }
        | O::SUB_SCALAR_ARRAY { ty }
        | O::DIV_ARRAY_SCALAR { ty }
        | O::DIV_SCALAR_ARRAY { ty }
        | O::POW_ARRAY_SCALAR { ty }
        | O::POW_SCALAR_ARRAY { ty }
        | O::POW_ARR { ty }
        | O::POW_ARR2 { ty } => ty,
        other => bail!("CodegenWasmJit: cannot determine type of operator {other:?}"),
    };
    sig_ty(ty)
}

/// The `SigTy` of an expression, from the DAE type annotations it carries (the
/// component reference's `ty`, a call's result `attr.ty`, a literal's kind, …).
/// Used where the *Modelica* type matters beyond the wasm representation — e.g.
/// dispatching `String(x)` on the argument type, or telling an Integer `i32`
/// from a String handle `i32`.
fn exp_sigty(exp: &DAE::Exp) -> Result<SigTy> {
    use DAE::Exp as E;
    Ok(match exp {
        E::ICONST { .. } | E::ENUM_LITERAL { .. } => SigTy::Int,
        E::BCONST { .. } => SigTy::Bool,
        E::RCONST { .. } => SigTy::Real,
        E::SCONST { .. } => SigTy::Str,
        E::CREF { ty, .. } => sig_ty(ty)?,
        E::CALL { attr, .. } => sig_ty(&attr.ty)?,
        E::CAST { ty, .. } => sig_ty(ty)?,
        E::BINARY { operator, .. } | E::UNARY { operator, .. } => operator_sigty(operator)?,
        E::RELATION { .. } | E::LBINARY { .. } | E::LUNARY { .. } => SigTy::Bool,
        E::IFEXP { expThen, .. } => exp_sigty(expThen)?,
        E::SHARED_LITERAL { exp, .. } => exp_sigty(exp)?,
        // Array-valued expressions carry their (array) type directly.
        E::ARRAY { ty, .. } | E::MATRIX { ty, .. } | E::RANGE { ty, .. } => sig_ty(ty)?,
        // A reduction's result type is its element/fold type.
        E::REDUCTION { reductionInfo, .. } => sig_ty(&reductionInfo.exprType)?,
        // `a[subs]`: subscripting reduces the rank by the number of subscripts
        // (a full index yields the scalar element).
        E::ASUB { exp, sub } => {
            let SigTy::Array { elem, rank } = exp_sigty(exp)? else {
                bail!("CodegenWasmJit: subscripting a non-array expression");
            };
            let n = (&**sub).into_iter().count() as u32;
            match rank.checked_sub(n) {
                Some(0) | None => (*elem).clone(),
                Some(left) => SigTy::Array { elem, rank: left },
            }
        }
        // `size(a, d)` is a scalar Integer; `size(a)` is the dimension vector.
        E::SIZE { sz: Some(_), .. } => SigTy::Int,
        E::SIZE { sz: None, .. } => SigTy::Array { elem: Arc::new(SigTy::Int), rank: 1 },
        // A record constructor / field access carry their type directly.
        E::RECORD { ty, .. } | E::RSUB { ty, .. } => sig_ty(ty)?,
        other => bail!("CodegenWasmJit: cannot determine type of expression {other:?}"),
    })
}

fn compile_unary(ctx: &mut FnCtx, op: &DAE::Operator, exp: &DAE::Exp) -> Result<WTy> {
    // Array negation `-a`: negate every element into a fresh array.
    if let DAE::Operator::UMINUS_ARR { ty } = op {
        let SigTy::Array { elem, .. } = sig_ty(ty)? else {
            bail!("CodegenWasmJit: UMINUS_ARR with non-array type {ty:?}");
        };
        let rt = if elem.wty() == WTy::F64 { "rt_array_neg_f64" } else { "rt_array_neg_i32" };
        compile_exp(ctx, exp)?; // owned array
        let at = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalSet(at));
        ctx.emit(we::Instruction::LocalGet(at));
        ctx.emit(we::Instruction::Call(rt_index(rt)));
        release_temp_array(ctx, at);
        return Ok(WTy::I32);
    }
    let DAE::Operator::UMINUS { ty } = op else {
        bail!("CodegenWasmJit: unsupported unary operator {op:?}");
    };
    let wty = sig_ty(ty)?.wty();
    let w = compile_exp(ctx, exp)?;
    coerce(ctx, w, wty);
    match wty {
        WTy::F64 => ctx.emit(we::Instruction::F64Neg),
        WTy::I32 => {
            // 0 - x: reorder via a temp so the constant 0 is below x.
            let t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(t));
            ctx.emit(we::Instruction::I32Const(0));
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::I32Sub);
        }
    }
    Ok(wty)
}

fn compile_binary(ctx: &mut FnCtx, e1: &DAE::Exp, op: &DAE::Operator, e2: &DAE::Exp) -> Result<WTy> {
    use DAE::Operator as O;
    // Element-wise array arithmetic (same-shape arrays) and scalar broadcast.
    // Handled before the scalar paths because `operator_sigty` does not classify
    // the array operators.
    match op {
        O::ADD_ARR { ty } => return compile_array_ew(ctx, e1, e2, OP_ADD, ty),
        O::SUB_ARR { ty } => return compile_array_ew(ctx, e1, e2, OP_SUB, ty),
        O::MUL_ARR { ty } => return compile_array_ew(ctx, e1, e2, OP_MUL, ty),
        O::DIV_ARR { ty } => return compile_array_ew(ctx, e1, e2, OP_DIV, ty),
        // `a + s` / `a * s` (commutative — the array operand is found by type).
        O::ADD_ARRAY_SCALAR { ty } => return compile_array_scalar(ctx, e1, e2, OP_ADD, false, ty),
        O::MUL_ARRAY_SCALAR { ty } => return compile_array_scalar(ctx, e1, e2, OP_MUL, false, ty),
        // `s - a`, `a / s`, `s / a`.
        O::SUB_SCALAR_ARRAY { ty } => return compile_array_scalar(ctx, e1, e2, OP_SUB, true, ty),
        O::DIV_ARRAY_SCALAR { ty } => return compile_array_scalar(ctx, e1, e2, OP_DIV, false, ty),
        O::DIV_SCALAR_ARRAY { ty } => return compile_array_scalar(ctx, e1, e2, OP_DIV, true, ty),
        // `v1 * v2` dot product (scalar result) and `a * b` matrix product
        // (matrix·matrix / matrix·vector / vector·matrix → a fresh array).
        O::MUL_SCALAR_PRODUCT { .. } => return compile_dot(ctx, e1, e2),
        O::MUL_MATRIX_PRODUCT { .. } => return compile_matmul(ctx, e1, e2),
        // Element-wise power: `a .^ b` (POW_ARR2), `a .^ s` (POW_ARRAY_SCALAR)
        // and `s .^ a` (POW_SCALAR_ARRAY). The per-element `pow` runs in-wasm.
        O::POW_ARR2 { ty } => return compile_array_ew(ctx, e1, e2, OP_POW, ty),
        O::POW_ARRAY_SCALAR { ty } => return compile_array_scalar(ctx, e1, e2, OP_POW, false, ty),
        O::POW_SCALAR_ARRAY { ty } => return compile_array_scalar(ctx, e1, e2, OP_POW, true, ty),
        _ => {}
    }
    // String `+` is concatenation: both operands are String handles, the result
    // is a fresh String handle from the runtime.
    if operator_sigty(op)? == SigTy::Str {
        let O::ADD { .. } = op else {
            bail!("CodegenWasmJit: unsupported String operator {op:?}");
        };
        str_binop(ctx, e1, e2, "rt_concat")?;
        return Ok(WTy::I32);
    }
    let wty = operator_wty(op)?;
    // POW has no wasm instruction. Mirror the C target's scalar-power dispatch
    // exactly: a literal `0.5` exponent is `sqrt` (with a negative-base check),
    // an integer-literal exponent is exponentiation by squaring
    // (`rt_real_int_pow`), and everything else is the generic `rt_real_pow`
    // (negative-base / odd-root / nan-inf handling). Keeping the same three-way
    // choice as C keeps the output byte-identical.
    if matches!(op, O::POW { .. }) {
        if exp_is_half(e2) {
            // sqrt(base); a negative base is an invalid root → trap (fail()).
            let a = compile_exp(ctx, e1)?;
            coerce(ctx, a, WTy::F64);
            let bt = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(bt));
            ctx.emit(we::Instruction::LocalGet(bt));
            ctx.emit(we::Instruction::F64Const(0.0f64.into()));
            ctx.emit(we::Instruction::F64Lt);
            ctx.emit(we::Instruction::If(we::BlockType::Empty));
            ctx.emit(we::Instruction::Unreachable);
            ctx.emit(we::Instruction::End);
            ctx.emit(we::Instruction::LocalGet(bt));
            ctx.emit(we::Instruction::F64Sqrt);
            return Ok(WTy::F64);
        }
        let rt = if let Some(n) = real_exp_int_lit(e2) {
            let a = compile_exp(ctx, e1)?;
            coerce(ctx, a, WTy::F64);
            ctx.emit(we::Instruction::I32Const(n));
            "rt_real_int_pow"
        } else {
            let a = compile_exp(ctx, e1)?;
            coerce(ctx, a, WTy::F64);
            let b = compile_exp(ctx, e2)?;
            coerce(ctx, b, WTy::F64);
            "rt_real_pow"
        };
        ctx.emit(we::Instruction::Call(rt_index(rt)));
        // Integer power keeps Integer type in Modelica: truncate back.
        if wty == WTy::I32 {
            ctx.emit(we::Instruction::I32TruncF64S);
            return Ok(WTy::I32);
        }
        return Ok(WTy::F64);
    }
    let a = compile_exp(ctx, e1)?;
    coerce(ctx, a, wty);
    let b = compile_exp(ctx, e2)?;
    coerce(ctx, b, wty);
    match (op, wty) {
        (O::ADD { .. }, WTy::F64) => ctx.emit(we::Instruction::F64Add),
        (O::ADD { .. }, WTy::I32) => ctx.emit(we::Instruction::I32Add),
        (O::SUB { .. }, WTy::F64) => ctx.emit(we::Instruction::F64Sub),
        (O::SUB { .. }, WTy::I32) => ctx.emit(we::Instruction::I32Sub),
        (O::MUL { .. }, WTy::F64) => ctx.emit(we::Instruction::F64Mul),
        (O::MUL { .. }, WTy::I32) => ctx.emit(we::Instruction::I32Mul),
        (O::DIV { .. }, WTy::F64) => ctx.emit(we::Instruction::F64Div),
        (O::DIV { .. }, WTy::I32) => ctx.emit(we::Instruction::I32DivS),
        (other, _) => bail!("CodegenWasmJit: unsupported binary operator {other:?}"),
    }
    Ok(wty)
}

fn compile_relation(ctx: &mut FnCtx, e1: &DAE::Exp, op: &DAE::Operator, e2: &DAE::Exp) -> Result<WTy> {
    use DAE::Operator as O;
    // String comparisons go through the runtime: equality via `rt_streq`,
    // ordering via `rt_strcmp` (which returns -1/0/1) compared against 0.
    if relation_operand_sigty(op)? == SigTy::Str {
        match op {
            O::EQUAL { .. } => str_binop(ctx, e1, e2, "rt_streq")?,
            O::NEQUAL { .. } => {
                str_binop(ctx, e1, e2, "rt_streq")?;
                ctx.emit(we::Instruction::I32Eqz);
            }
            O::LESS { .. } | O::LESSEQ { .. } | O::GREATER { .. } | O::GREATEREQ { .. } => {
                str_binop(ctx, e1, e2, "rt_strcmp")?;
                ctx.emit(we::Instruction::I32Const(0));
                ctx.emit(match op {
                    O::LESS { .. } => we::Instruction::I32LtS,
                    O::LESSEQ { .. } => we::Instruction::I32LeS,
                    O::GREATER { .. } => we::Instruction::I32GtS,
                    _ => we::Instruction::I32GeS,
                });
            }
            other => bail!("CodegenWasmJit: unsupported String relation {other:?}"),
        }
        return Ok(WTy::I32);
    }
    let operand_wty = operand_type_of_relation(op)?;
    let a = compile_exp(ctx, e1)?;
    coerce(ctx, a, operand_wty);
    let b = compile_exp(ctx, e2)?;
    coerce(ctx, b, operand_wty);
    let instr = match (op, operand_wty) {
        (O::LESS { .. }, WTy::F64) => we::Instruction::F64Lt,
        (O::LESS { .. }, WTy::I32) => we::Instruction::I32LtS,
        (O::LESSEQ { .. }, WTy::F64) => we::Instruction::F64Le,
        (O::LESSEQ { .. }, WTy::I32) => we::Instruction::I32LeS,
        (O::GREATER { .. }, WTy::F64) => we::Instruction::F64Gt,
        (O::GREATER { .. }, WTy::I32) => we::Instruction::I32GtS,
        (O::GREATEREQ { .. }, WTy::F64) => we::Instruction::F64Ge,
        (O::GREATEREQ { .. }, WTy::I32) => we::Instruction::I32GeS,
        (O::EQUAL { .. }, WTy::F64) => we::Instruction::F64Eq,
        (O::EQUAL { .. }, WTy::I32) => we::Instruction::I32Eq,
        (O::NEQUAL { .. }, WTy::F64) => we::Instruction::F64Ne,
        (O::NEQUAL { .. }, WTy::I32) => we::Instruction::I32Ne,
        (other, _) => bail!("CodegenWasmJit: unsupported relational operator {other:?}"),
    };
    ctx.emit(instr);
    Ok(WTy::I32)
}

fn operand_type_of_relation(op: &DAE::Operator) -> Result<WTy> {
    Ok(relation_operand_sigty(op)?.wty())
}

/// The `SigTy` of a relational operator's operands (distinguishes String, whose
/// comparisons go through the runtime, from numeric ones).
fn relation_operand_sigty(op: &DAE::Operator) -> Result<SigTy> {
    use DAE::Operator as O;
    let ty = match op {
        O::LESS { ty } | O::LESSEQ { ty } | O::GREATER { ty } | O::GREATEREQ { ty } | O::EQUAL { ty } | O::NEQUAL { ty } => ty,
        other => bail!("CodegenWasmJit: not a relational operator: {other:?}"),
    };
    sig_ty(ty)
}

/// Compile a `CALL`, leaving its result value(s) on the stack; returns their
/// types. Resolves to another generated function, an inline math builtin, or a
/// host-imported builtin.
fn compile_call(
    ctx: &mut FnCtx,
    path: &Absyn::Path,
    args: &Arc<List<Arc<DAE::Exp>>>,
    attr: &DAE::CallAttributes,
) -> Result<Vec<SigTy>> {
    let mangled = mangle(path)?;
    // A call to another generated function. Heap arguments are passed as owned
    // (+1) references — a generated function *consumes* its heap parameters
    // (they are released at its scope exit), so the caller does not release them
    // after the call.
    if let Some(info) = ctx.by_name.get(&mangled) {
        let params = info.sig.params.clone();
        let results = info.sig.results.clone();
        let index = info.index;
        let argv: Vec<&Arc<DAE::Exp>> = (&**args).into_iter().collect();
        if argv.len() != params.len() {
            bail!("CodegenWasmJit: call to {mangled} expects {} args, got {}", params.len(), argv.len());
        }
        for (a, p) in argv.iter().zip(params.iter()) {
            let w = compile_exp(ctx, a)?;
            coerce(ctx, w, p.wty());
        }
        ctx.emit(we::Instruction::Call(index));
        return Ok(results);
    }
    // A call whose result is a record and which is not a generated function is a
    // record constructor `R(v1, …)` (the constructor function itself is not
    // emitted — construction is lowered inline).
    if let Ok(rty @ SigTy::Record { .. }) = sig_ty(&attr.ty) {
        compile_record_call(ctx, &attr.ty, args)?;
        return Ok(vec![rty]);
    }
    // Otherwise it must be a (builtin) math/string function.
    let name = AbsynUtil::pathLastIdent(Arc::new(path.clone()))?.to_string();
    compile_math_builtin(ctx, &name, args, attr).map(|s| vec![s])
}

/// Like [`compile_call`] but for statement position; returns the result types
/// left on the stack (to be released if heap, otherwise dropped).
fn compile_call_drop(ctx: &mut FnCtx, exp: &DAE::Exp) -> Result<Vec<SigTy>> {
    let DAE::Exp::CALL { path, expLst, attr } = exp else {
        bail!("CodegenWasmJit: no-return statement is not a call: {exp:?}");
    };
    compile_call(ctx, path, expLst, attr)
}

/// Lower a scalar math builtin. Single-instruction builtins are emitted inline;
/// transcendental ones go through the host imports in [`BUILTINS`].
fn compile_math_builtin(
    ctx: &mut FnCtx,
    name: &str,
    args: &Arc<List<Arc<DAE::Exp>>>,
    attr: &DAE::CallAttributes,
) -> Result<SigTy> {
    let argv: Vec<&Arc<DAE::Exp>> = (&**args).into_iter().collect();

    // Array-valued / array-reducing builtins (fill/zeros/ones, sum/product, the
    // one-array forms of min/max, ndims) take precedence over the scalar math
    // handling below (which also defines the two-argument min/max).
    if let Some(sig) = compile_array_builtin(ctx, name, &argv, attr)? {
        return Ok(sig);
    }

    let result_sig = sig_ty(&attr.ty).unwrap_or(SigTy::Real);
    let result_wty = result_sig.wty();

    // Host-imported transcendentals (all operate on and return f64).
    if let Some(bi) = builtin_index(name) {
        let (_, params, _) = BUILTINS[bi as usize];
        if argv.len() != params.len() {
            bail!("CodegenWasmJit: builtin {name} expects {} args", params.len());
        }
        for (a, p) in argv.iter().zip(params.iter()) {
            let w = compile_exp(ctx, a)?;
            coerce(ctx, w, *p);
        }
        ctx.emit(we::Instruction::Call(bi));
        return Ok(SigTy::Real);
    }

    match name {
        "sqrt" => {
            unary_f64(ctx, &argv, we::Instruction::F64Sqrt)?;
            Ok(SigTy::Real)
        }
        "floor" => {
            unary_f64(ctx, &argv, we::Instruction::F64Floor)?;
            Ok(SigTy::Real)
        }
        "ceil" => {
            unary_f64(ctx, &argv, we::Instruction::F64Ceil)?;
            Ok(SigTy::Real)
        }
        // integer(r): largest Integer <= r.
        "integer" => {
            unary_f64(ctx, &argv, we::Instruction::F64Floor)?;
            ctx.emit(we::Instruction::I32TruncF64S);
            Ok(SigTy::Int)
        }
        // `Integer(e)` — the ordinal of an enumeration value. Enum values are
        // already stored as their 1-based index (an i32), so this is identity.
        "Integer" => {
            need_args(&argv, 1, name)?;
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::I32);
            Ok(SigTy::Int)
        }
        "abs" => {
            need_args(&argv, 1, name)?;
            if result_wty == WTy::F64 {
                let w = compile_exp(ctx, argv[0])?;
                coerce(ctx, w, WTy::F64);
                ctx.emit(we::Instruction::F64Abs);
                Ok(SigTy::Real)
            } else {
                let w = compile_exp(ctx, argv[0])?;
                coerce(ctx, w, WTy::I32);
                let t = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(t));
                // select(-x, x, x<0)
                ctx.emit(we::Instruction::I32Const(0));
                ctx.emit(we::Instruction::LocalGet(t));
                ctx.emit(we::Instruction::I32Sub); // -x
                ctx.emit(we::Instruction::LocalGet(t)); // x
                ctx.emit(we::Instruction::LocalGet(t));
                ctx.emit(we::Instruction::I32Const(0));
                ctx.emit(we::Instruction::I32LtS); // x<0
                ctx.emit(we::Instruction::Select);
                Ok(result_sig)
            }
        }
        "max" | "min" => {
            need_args(&argv, 2, name)?;
            if result_wty == WTy::F64 {
                let a = compile_exp(ctx, argv[0])?;
                coerce(ctx, a, WTy::F64);
                let b = compile_exp(ctx, argv[1])?;
                coerce(ctx, b, WTy::F64);
                ctx.emit(if name == "max" { we::Instruction::F64Max } else { we::Instruction::F64Min });
                Ok(SigTy::Real)
            } else {
                let a = compile_exp(ctx, argv[0])?;
                coerce(ctx, a, WTy::I32);
                let b = compile_exp(ctx, argv[1])?;
                coerce(ctx, b, WTy::I32);
                let tb = ctx.alloc_temp(WTy::I32);
                let ta = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(tb));
                ctx.emit(we::Instruction::LocalSet(ta));
                ctx.emit(we::Instruction::LocalGet(ta));
                ctx.emit(we::Instruction::LocalGet(tb));
                ctx.emit(we::Instruction::LocalGet(ta));
                ctx.emit(we::Instruction::LocalGet(tb));
                ctx.emit(if name == "max" { we::Instruction::I32GtS } else { we::Instruction::I32LtS });
                ctx.emit(we::Instruction::Select);
                Ok(result_sig)
            }
        }
        // div(a,b): integer division truncating toward zero.
        "div" if result_wty == WTy::I32 => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::I32);
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::I32);
            ctx.emit(we::Instruction::I32DivS);
            Ok(SigTy::Int)
        }
        // div(a,b) for Reals: `trunc(a/b)` (truncate toward zero, Real result).
        // The frontend also expands Real `rem` into `a - b*div(a,b)`.
        "div" => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::F64);
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::F64);
            ctx.emit(we::Instruction::F64Div);
            ctx.emit(we::Instruction::F64Trunc);
            Ok(SigTy::Real)
        }
        // rem(a,b): integer remainder truncating toward zero.
        "rem" if result_wty == WTy::I32 => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::I32);
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::I32);
            ctx.emit(we::Instruction::I32RemS);
            Ok(SigTy::Int)
        }
        // rem(a,b) for Reals: `a - b*trunc(a/b)` (truncated remainder).
        "rem" => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::F64);
            let at = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(at));
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::F64);
            let bt = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(bt));
            ctx.emit(we::Instruction::LocalGet(at)); // a
            ctx.emit(we::Instruction::LocalGet(bt)); // b * trunc(a/b)
            ctx.emit(we::Instruction::LocalGet(at));
            ctx.emit(we::Instruction::LocalGet(bt));
            ctx.emit(we::Instruction::F64Div);
            ctx.emit(we::Instruction::F64Trunc);
            ctx.emit(we::Instruction::F64Mul);
            ctx.emit(we::Instruction::F64Sub);
            Ok(SigTy::Real)
        }
        // mod(a,b): Modelica floored modulo `a - floor(a/b)*b`. Integer goes
        // through the runtime (floored, result takes the divisor's sign);
        // Real is inlined with `floor`.
        "mod" if result_wty == WTy::I32 => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::I32);
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_mod_int")));
            Ok(SigTy::Int)
        }
        "mod" => {
            need_args(&argv, 2, name)?;
            let a = compile_exp(ctx, argv[0])?;
            coerce(ctx, a, WTy::F64);
            let at = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(at));
            let b = compile_exp(ctx, argv[1])?;
            coerce(ctx, b, WTy::F64);
            let bt = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(bt));
            ctx.emit(we::Instruction::LocalGet(at)); // a
            ctx.emit(we::Instruction::LocalGet(at)); // floor(a/b) * b
            ctx.emit(we::Instruction::LocalGet(bt));
            ctx.emit(we::Instruction::F64Div);
            ctx.emit(we::Instruction::F64Floor);
            ctx.emit(we::Instruction::LocalGet(bt));
            ctx.emit(we::Instruction::F64Mul);
            ctx.emit(we::Instruction::F64Sub);
            Ok(SigTy::Real)
        }
        // sign(x): -1 / 0 / 1 (Integer), `(x > 0) - (x < 0)`.
        "sign" => {
            need_args(&argv, 1, name)?;
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::F64);
            let t = ctx.alloc_temp(WTy::F64);
            ctx.emit(we::Instruction::LocalSet(t));
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::F64Const(0.0f64.into()));
            ctx.emit(we::Instruction::F64Gt); // (x > 0) -> i32
            ctx.emit(we::Instruction::LocalGet(t));
            ctx.emit(we::Instruction::F64Const(0.0f64.into()));
            ctx.emit(we::Instruction::F64Lt); // (x < 0) -> i32
            ctx.emit(we::Instruction::I32Sub);
            Ok(SigTy::Int)
        }
        // Number → String formatting via the runtime: a scalar becomes a freshly
        // allocated (refcount 1) String handle. The typed builtin names are
        // unambiguous; `String(x)` dispatches on the argument's Modelica type.
        "intString" => {
            need_args(&argv, 1, name)?;
            format_scalar_string(ctx, argv[0], SigTy::Int)
        }
        "boolString" => {
            need_args(&argv, 1, name)?;
            format_scalar_string(ctx, argv[0], SigTy::Bool)
        }
        "realString" if argv.len() == 1 => emit_real_string(ctx, argv[0]),
        "String" => emit_string_builtin(ctx, &argv),
        // `s1 + s2` arrives as a BINARY ADD (handled in `compile_binary`); the
        // explicit builtin form is `stringAppend`.
        "stringAppend" => {
            need_args(&argv, 2, name)?;
            str_binop(ctx, argv[0], argv[1], "rt_concat")?;
            Ok(SigTy::Str)
        }
        "stringLength" => {
            need_args(&argv, 1, name)?;
            str_unop(ctx, argv[0], "rt_str_len")?;
            Ok(SigTy::Int)
        }
        "stringEqual" => {
            need_args(&argv, 2, name)?;
            str_binop(ctx, argv[0], argv[1], "rt_streq")?;
            Ok(SigTy::Bool)
        }
        // `substring(s, i, j)` — 1-based inclusive.
        "substring" => {
            need_args(&argv, 3, name)?;
            str_substring(ctx, argv[0], argv[1], argv[2])?;
            Ok(SigTy::Str)
        }
        // `smooth(p, expr)` and `noEvent(expr)` are smoothness/event annotations
        // that are the identity on the value expression at runtime (the C target
        // likewise just evaluates the expression). The returned `SigTy` is
        // derived from the emitted wasm type so it always matches the stack.
        "smooth" => {
            need_args(&argv, 2, name)?;
            let w = compile_exp(ctx, argv[1])?;
            Ok(if w == WTy::F64 { SigTy::Real } else { SigTy::Int })
        }
        "noEvent" => {
            need_args(&argv, 1, name)?;
            let w = compile_exp(ctx, argv[0])?;
            Ok(if w == WTy::F64 { SigTy::Real } else { SigTy::Int })
        }
        other => bail!("CodegenWasmJit: builtin function `{other}` not yet supported"),
    }
}

/// Release a heap value held in scratch local `t` (used to free owned operands
/// after a borrowing runtime op consumed them off the stack).
fn release_temp(ctx: &mut FnCtx, t: u32) {
    ctx.emit(we::Instruction::LocalGet(t));
    ctx.emit(we::Instruction::Call(rt_index("rt_release")));
}

/// A runtime string op with two heap operands: each is an owned (+1) value, the
/// runtime only borrows them, so both are released after the call. Leaves the
/// op's result on the stack.
fn str_binop(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp, rt_fn: &str) -> Result<()> {
    compile_exp(ctx, e1)?;
    let t1 = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(t1));
    compile_exp(ctx, e2)?;
    let t2 = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(t2));
    ctx.emit(we::Instruction::LocalGet(t1));
    ctx.emit(we::Instruction::LocalGet(t2));
    ctx.emit(we::Instruction::Call(rt_index(rt_fn)));
    release_temp(ctx, t1);
    release_temp(ctx, t2);
    Ok(())
}

/// A runtime string op with one heap operand (e.g. `rt_str_len`): the owned
/// operand is released after the call. Leaves the op's result on the stack.
fn str_unop(ctx: &mut FnCtx, e: &DAE::Exp, rt_fn: &str) -> Result<()> {
    compile_exp(ctx, e)?;
    let t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(t));
    ctx.emit(we::Instruction::LocalGet(t));
    ctx.emit(we::Instruction::Call(rt_index(rt_fn)));
    release_temp(ctx, t);
    Ok(())
}

/// `substring(s, i, j)`: one heap operand `s` (released after) plus two scalar
/// indices. Leaves the new String handle on the stack.
fn str_substring(ctx: &mut FnCtx, s: &DAE::Exp, i: &DAE::Exp, j: &DAE::Exp) -> Result<()> {
    compile_exp(ctx, s)?;
    let ts = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(ts));
    ctx.emit(we::Instruction::LocalGet(ts));
    let wi = compile_exp(ctx, i)?;
    coerce(ctx, wi, WTy::I32);
    let wj = compile_exp(ctx, j)?;
    coerce(ctx, wj, WTy::I32);
    ctx.emit(we::Instruction::Call(rt_index("rt_substring")));
    release_temp(ctx, ts);
    Ok(())
}

/// `String(x[, significantDigits], minimumLength, leftJustified)` — the Modelica
/// builtin. The frontend (`Static.elabBuiltinString`) always fills the format
/// slots, so the argument shapes that reach here are:
///   * `String(Integer|Boolean|String, minimumLength, leftJustified)` (3 args)
///   * `String(Real, significantDigits, minimumLength, leftJustified)` (4 args)
/// matching `Ceval.cevalBuiltinString`. The Real form is the C `printf`
/// conversion `"%[-]{minimumLength}.{significantDigits}g"` (via `rt_real_format`,
/// NOT the shortest-round-trip `realString`); the others format the scalar and
/// then space-pad to `minimumLength` (`rt_str_pad`).
fn emit_string_builtin(ctx: &mut FnCtx, argv: &[&Arc<DAE::Exp>]) -> Result<SigTy> {
    // `String(Enumeration)` must render the enumeration literal *name*
    // (`Ceval.cevalBuiltinString` uses `AbsynUtil.pathLastIdent`); the wasm-jit
    // value model carries only the Integer index, so reject rather than silently
    // stringify the index. Carrying enum names would need the literal table
    // threaded through from the DAE type into the sidecar/runtime.
    if exp_is_enumeration(argv[0]) {
        let Some(names) = exp_enum_names(argv[0]) else {
            bail!("CodegenWasmJit: String(Enumeration) on an enum literal whose names are not in scope");
        };
        emit_enum_string(ctx, argv[0], &names)?;
        // String(e, minimumLength, leftJustified): pad the name like any scalar.
        if let [_, min_len, left_just] = argv {
            return apply_string_padding(ctx, min_len, left_just);
        }
        return Ok(SigTy::Str);
    }
    let vty = exp_sigty(argv[0])?;
    // `String(String, …)` is the identity: the C target ignores the
    // minimumLength/leftJustified arguments for a string value (see the
    // `"modelica_string"` arm of `CodegenCFunctions.tpl`'s String builtin —
    // `tvar = sExp`), so padding must NOT be applied here either.
    if vty == SigTy::Str {
        return format_scalar_string(ctx, argv[0], vty);
    }
    // The format-string variant `String(value, format)` (`elabBuiltinString`'s
    // second form): a 2-argument call whose second argument is a String. The
    // runtime parses the printf directive (mirroring the C runtime's
    // `modelica_*_to_modelica_string_format`).
    if argv.len() == 2 && exp_sigty(argv[1])? == SigTy::Str {
        return emit_string_format(ctx, argv[0], argv[1], &vty);
    }
    match (&vty, argv.len()) {
        // Bare `String(scalar)` (no format slots) — does not normally reach the
        // codegen (the frontend fills the slots), but is unambiguous.
        (SigTy::Int, 1) | (SigTy::Bool, 1) => format_scalar_string(ctx, argv[0], vty),
        // String(Integer|Boolean, minimumLength, leftJustified).
        (SigTy::Int, 3) | (SigTy::Bool, 3) => {
            emit_padded_scalar_string(ctx, argv[0], vty, argv[1], argv[2])
        }
        // String(Real, significantDigits, minimumLength, leftJustified).
        (SigTy::Real, 4) => emit_real_format(ctx, argv[0], argv[1], argv[2], argv[3]),
        other => bail!("CodegenWasmJit: unsupported String() argument shape {other:?}"),
    }
}

/// `String(value, format)` — the format-string variant. Evaluate the value and
/// the (owned) format-string handle and dispatch to the runtime formatter, which
/// parses the printf directive at runtime (so the format need not be constant).
/// The runtime borrows the format handle; it is released here afterwards.
fn emit_string_format(ctx: &mut FnCtx, val: &DAE::Exp, fmt: &DAE::Exp, vty: &SigTy) -> Result<SigTy> {
    let rt_fn = match vty {
        SigTy::Real => "rt_string_format_real",
        // Integer and Boolean share the integer formatter (Booleans coerce to
        // 0/1). The String format variant (`%s`) is not yet ported.
        SigTy::Int | SigTy::Bool => "rt_string_format_int",
        other => bail!("CodegenWasmJit: String(value, format) not yet implemented for {other:?}"),
    };
    let w = compile_exp(ctx, val)?;
    coerce(ctx, w, vty.wty());
    let fmt_t = ctx.alloc_temp(WTy::I32);
    let fw = compile_exp(ctx, fmt)?;
    if fw != WTy::I32 {
        bail!("CodegenWasmJit: String() format argument is not a string");
    }
    ctx.emit(we::Instruction::LocalTee(fmt_t)); // keep the handle, leave it on the stack
    ctx.emit(we::Instruction::Call(rt_index(rt_fn)));
    // Release the (borrowed) format handle now that formatting is done.
    ctx.emit(we::Instruction::LocalGet(fmt_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_release")));
    Ok(SigTy::Str)
}

/// Whether `exp` has an enumeration type (so `String(exp)` would need the
/// literal name). Covers the expression forms that carry a `DAE.Type`; anything
/// else is not an enumeration value.
/// Emit a String literal: materialize a fresh (refcount 1) String from a passive
/// data segment with `memory.init`, leaving the owned handle on the stack.
fn emit_str_literal(ctx: &mut FnCtx, bytes: &[u8]) {
    let len = bytes.len() as u32;
    let seg = ctx.literals.len() as u32;
    ctx.literals.push(bytes.to_vec());
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(len as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_str_new")));
    ctx.emit(we::Instruction::LocalTee(obj));
    // memory.init dest=rt_str_data(obj), src_offset=0, size=len
    ctx.emit(we::Instruction::Call(rt_index("rt_str_data")));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::I32Const(len as i32));
    ctx.emit(we::Instruction::MemoryInit { mem: 0, data_index: seg });
    ctx.emit(we::Instruction::LocalGet(obj));
}

/// The enumeration literal names of `exp`'s type (unqualified, indexed 1-based
/// by the enum value), or `None` if `exp` is not an enumeration carried by a
/// type we can read the names from.
fn exp_enum_names(exp: &DAE::Exp) -> Option<Vec<ArcStr>> {
    use DAE::Exp as E;
    let names_of = |ty: &DAE::Type| match ty {
        DAE::Type::T_ENUMERATION { names, .. } => Some((&**names).into_iter().cloned().collect()),
        _ => None,
    };
    match exp {
        E::CREF { ty, .. } | E::CAST { ty, .. } => names_of(ty),
        E::CALL { attr, .. } => names_of(&attr.ty),
        E::SHARED_LITERAL { exp, .. } => exp_enum_names(exp),
        _ => None,
    }
}

/// `String(e)` for an enumeration value `e`: render the literal *name* (matching
/// `Ceval.cevalBuiltinString`). The value is the 1-based index; emit a switch
/// that materializes the matching name literal (an out-of-range index traps).
/// Leaves an owned (+1) String handle on the stack.
fn emit_enum_string(ctx: &mut FnCtx, arg: &DAE::Exp, names: &[ArcStr]) -> Result<()> {
    let idx_t = ctx.alloc_temp(WTy::I32);
    let w = compile_exp(ctx, arg)?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(idx_t));
    ctx.emit(we::Instruction::Block(we::BlockType::Result(we::ValType::I32)));
    for (k, name) in names.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(idx_t));
        ctx.emit(we::Instruction::I32Const(k as i32 + 1));
        ctx.emit(we::Instruction::I32Eq);
        ctx.emit(we::Instruction::If(we::BlockType::Empty));
        emit_str_literal(ctx, name.as_bytes());
        ctx.emit(we::Instruction::Br(1)); // break out of the Block with the handle
        ctx.emit(we::Instruction::End); // if
    }
    ctx.emit(we::Instruction::Unreachable); // index out of range
    ctx.emit(we::Instruction::End); // block (result = the handle)
    Ok(())
}

fn exp_is_enumeration(exp: &DAE::Exp) -> bool {
    use DAE::Exp as E;
    let is_enum = |ty: &DAE::Type| matches!(ty, DAE::Type::T_ENUMERATION { .. });
    match exp {
        E::ENUM_LITERAL { .. } => true,
        E::CREF { ty, .. } | E::CAST { ty, .. } => is_enum(ty),
        E::CALL { attr, .. } => is_enum(&attr.ty),
        E::SHARED_LITERAL { exp, .. } => exp_is_enumeration(exp),
        _ => false,
    }
}

/// `String(Integer|Boolean|String, minimumLength, leftJustified)`: format the
/// scalar to an owned String handle, then space-pad it to `minimumLength`.
/// A literal `minimumLength` of 0 never pads (`cevalBuiltinStringFormat` returns
/// the string unchanged), so the runtime call is skipped in that common default.
fn emit_padded_scalar_string(
    ctx: &mut FnCtx,
    val: &DAE::Exp,
    vty: SigTy,
    min_len: &DAE::Exp,
    left_just: &DAE::Exp,
) -> Result<SigTy> {
    // Leaves an owned (+1) string handle on the stack.
    format_scalar_string(ctx, val, vty)?;
    apply_string_padding(ctx, min_len, left_just)
}

/// Pad the owned String handle on the stack to `min_len` (space-padded,
/// left-justified per `left_just`), a no-op for a literal-zero `min_len`. The
/// unpadded handle is released; a fresh owned padded handle is left.
fn apply_string_padding(ctx: &mut FnCtx, min_len: &DAE::Exp, left_just: &DAE::Exp) -> Result<SigTy> {
    if let DAE::Exp::ICONST { integer: 0 } = min_len {
        return Ok(SigTy::Str);
    }
    // `rt_str_pad` borrows the unpadded handle and returns a fresh owned one, so
    // the unpadded one is released afterwards.
    let t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(t));
    ctx.emit(we::Instruction::LocalGet(t));
    let wl = compile_exp(ctx, min_len)?;
    coerce(ctx, wl, WTy::I32);
    let wj = compile_exp(ctx, left_just)?;
    coerce(ctx, wj, WTy::I32);
    ctx.emit(we::Instruction::Call(rt_index("rt_str_pad")));
    release_temp(ctx, t);
    Ok(SigTy::Str)
}

/// `String(Real, significantDigits, minimumLength, leftJustified)` → the C `%g`
/// conversion via `rt_real_format`. All four operands are scalars (no heap
/// operands to release); the result is a fresh owned String handle.
fn emit_real_format(
    ctx: &mut FnCtx,
    r: &DAE::Exp,
    sig: &DAE::Exp,
    min_len: &DAE::Exp,
    left_just: &DAE::Exp,
) -> Result<SigTy> {
    let wr = compile_exp(ctx, r)?;
    coerce(ctx, wr, WTy::F64);
    let ws = compile_exp(ctx, sig)?;
    coerce(ctx, ws, WTy::I32);
    let wl = compile_exp(ctx, min_len)?;
    coerce(ctx, wl, WTy::I32);
    let wj = compile_exp(ctx, left_just)?;
    coerce(ctx, wj, WTy::I32);
    ctx.emit(we::Instruction::Call(rt_index("rt_real_format")));
    Ok(SigTy::Str)
}

/// Format a scalar of the given `SigTy` to an owned String handle via the
/// runtime.
fn format_scalar_string(ctx: &mut FnCtx, arg: &DAE::Exp, ty: SigTy) -> Result<SigTy> {
    match ty {
        SigTy::Int => {
            let w = compile_exp(ctx, arg)?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_int_string")));
            Ok(SigTy::Str)
        }
        SigTy::Bool => {
            let w = compile_exp(ctx, arg)?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_bool_string")));
            Ok(SigTy::Str)
        }
        SigTy::Real => emit_real_string(ctx, arg),
        // String(s) is the identity; `compile_exp` already returns an owned copy.
        SigTy::Str => {
            compile_exp(ctx, arg)?;
            Ok(SigTy::Str)
        }
        // `String(array)` / `String(record)` are not scalar conversions (the
        // frontend would not produce them here); reject rather than mis-format.
        SigTy::Array { .. } | SigTy::Record { .. } => {
            bail!("CodegenWasmJit: String() of an array/record is not supported")
        }
    }
}

/// `realString(r)` / `String(r)` with default formatting.
fn emit_real_string(ctx: &mut FnCtx, arg: &DAE::Exp) -> Result<SigTy> {
    let w = compile_exp(ctx, arg)?;
    coerce(ctx, w, WTy::F64);
    ctx.emit(we::Instruction::Call(rt_index("rt_real_string")));
    Ok(SigTy::Str)
}

// -------------------------------------------------------------------------
// Arrays (N-dimensional, flat row-major; see the runtime's Arrays section)
// -------------------------------------------------------------------------

/// Load one array element from the byte address on top of the stack, leaving its
/// value. The wasm load instruction (and natural alignment) follow the element
/// type.
fn elem_load(ctx: &mut FnCtx, elem: &SigTy) {
    match elem.wty() {
        WTy::I32 => ctx.emit(we::Instruction::I32Load(we::MemArg { offset: 0, align: 2, memory_index: 0 })),
        WTy::F64 => ctx.emit(we::Instruction::F64Load(we::MemArg { offset: 0, align: 3, memory_index: 0 })),
    }
}

/// Store an array element: stack is `[addr, value]`.
fn elem_store(ctx: &mut FnCtx, elem: &SigTy) {
    match elem.wty() {
        WTy::I32 => ctx.emit(we::Instruction::I32Store(we::MemArg { offset: 0, align: 2, memory_index: 0 })),
        WTy::F64 => ctx.emit(we::Instruction::F64Store(we::MemArg { offset: 0, align: 3, memory_index: 0 })),
    }
}

/// The constant per-axis sizes of an array `DAE.Type`, flattening nested
/// `T_ARRAY`s (a rectangular array may be one `T_ARRAY` with several `dims` or a
/// nest of `T_ARRAY`s). Fails on a non-constant dimension (`:` / expression),
/// which needs the dynamic-allocation path (resize) not yet implemented.
fn const_dims(ty: &DAE::Type) -> Result<Vec<u32>> {
    let DAE::Type::T_ARRAY { ty: elem, dims } = ty else {
        return Ok(Vec::new());
    };
    let mut out = Vec::new();
    for d in &**dims {
        match &**d {
            DAE::Dimension::DIM_INTEGER { integer } if *integer >= 0 => out.push(*integer as u32),
            other => bail!("CodegenWasmJit: array construction needs constant dimensions, got {other:?}"),
        }
    }
    out.extend(const_dims(elem)?);
    Ok(out)
}

/// Collect the scalar leaf expressions of a (possibly nested) array constructor
/// in row-major order. `ARRAY`/`MATRIX` nodes are the structure; anything else
/// is a leaf element.
fn flatten_array_exp<'a>(exp: &'a DAE::Exp, out: &mut Vec<&'a DAE::Exp>) {
    use DAE::Exp as E;
    match exp {
        E::ARRAY { array, .. } => {
            for e in &**array {
                flatten_array_exp(e, out);
            }
        }
        E::MATRIX { matrix, .. } => {
            for row in &**matrix {
                for e in &**row {
                    flatten_array_exp(e, out);
                }
            }
        }
        E::SHARED_LITERAL { exp, .. } => flatten_array_exp(exp, out),
        other => out.push(other),
    }
}

/// Lower an array constructor (`{...}`, possibly nested for a matrix) of the
/// given declared `ty`, leaving an owned (+1) array handle on the stack. Builds
/// the flat row-major runtime object and stores every scalar leaf; an owned heap
/// element's reference transfers into the array (released by `rt_array_release`).
fn compile_array_literal(ctx: &mut FnCtx, ty: &DAE::Type, whole: &DAE::Exp) -> Result<()> {
    let SigTy::Array { elem, rank } = sig_ty(ty)? else {
        bail!("CodegenWasmJit: array constructor with non-array type {ty:?}");
    };
    let dims = const_dims(ty)?;
    if dims.len() as u32 != rank {
        bail!("CodegenWasmJit: array constructor rank {rank} does not match {} dimensions", dims.len());
    }
    let total: u32 = dims.iter().product();
    // The top-level structure (`ARRAY`/`MATRIX` nodes) is flattened to its
    // outermost element expressions. Each is either a scalar (one element) or an
    // array-valued expression (a sub-array, e.g. `{v, w}` of vectors) whose
    // elements are blitted in. (Scalar leaves remain the common case.)
    let mut leaves = Vec::new();
    flatten_array_exp(whole, &mut leaves);

    // obj = rt_array_new(elem_kind, rank, total); set each dimension size.
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(elem.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(rank as i32));
    ctx.emit(we::Instruction::I32Const(total as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")));
    ctx.emit(we::Instruction::LocalSet(obj));
    for (axis, d) in dims.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::I32Const(*d as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")));
    }
    // Store each leaf at its row-major position. A scalar leaf occupies one
    // element; an array-valued leaf contributes its whole (row-major) contents.
    let mut k: u32 = 0; // running 0-based element index
    for leaf in &leaves {
        match leaf_array_count(leaf)? {
            None => {
                // Scalar element.
                ctx.emit(we::Instruction::LocalGet(obj));
                ctx.emit(we::Instruction::I32Const(k as i32 + 1));
                ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
                let w = compile_exp(ctx, leaf)?;
                coerce(ctx, w, elem.wty());
                elem_store(ctx, &elem);
                k += 1;
            }
            Some(n) => {
                // Array-valued element: evaluate to an owned handle, blit its
                // elements into the result at the running offset, then release it.
                let h = ctx.alloc_temp(WTy::I32);
                compile_exp(ctx, leaf)?;
                ctx.emit(we::Instruction::LocalSet(h));
                ctx.emit(we::Instruction::LocalGet(obj));
                ctx.emit(we::Instruction::I32Const(k as i32));
                ctx.emit(we::Instruction::LocalGet(h));
                ctx.emit(we::Instruction::Call(rt_index("rt_array_blit")));
                ctx.emit(we::Instruction::LocalGet(h));
                ctx.emit(we::Instruction::Call(rt_index("rt_array_release")));
                k += n;
            }
        }
    }
    if k != total {
        bail!("CodegenWasmJit: array constructor produced {k} elements but type implies {total}");
    }
    ctx.emit(we::Instruction::LocalGet(obj));
    Ok(())
}

/// The number of scalar elements an array constructor *leaf* contributes:
/// `None` for a scalar leaf, `Some(n)` for an array-valued leaf (a sub-array of
/// `n` elements, from its constant dimensions). Fails if the leaf is an array of
/// non-constant size (the dynamic case is not handled in a constructor).
fn leaf_array_count(exp: &DAE::Exp) -> Result<Option<u32>> {
    match exp_dae_type(exp) {
        Some(ty) if matches!(&*ty, DAE::Type::T_ARRAY { .. }) => {
            Ok(Some(const_dims(&ty)?.iter().product()))
        }
        _ => Ok(None),
    }
}

/// The DAE type an expression carries, for the cases that can appear as an
/// array-constructor leaf. `None` when no type annotation is readily available
/// (treated as a scalar leaf by [`leaf_array_count`]).
fn exp_dae_type(exp: &DAE::Exp) -> Option<Arc<DAE::Type>> {
    use DAE::Exp as E;
    match exp {
        E::CREF { ty, .. } | E::CAST { ty, .. } | E::ARRAY { ty, .. } | E::MATRIX { ty, .. } | E::RANGE { ty, .. } => {
            Some(ty.clone())
        }
        E::CALL { attr, .. } => Some(attr.ty.clone()),
        E::SHARED_LITERAL { exp, .. } => exp_dae_type(exp),
        E::BINARY { operator, .. } | E::UNARY { operator, .. } => operator_dae_type(operator),
        _ => None,
    }
}

/// The result DAE type carried by an arithmetic operator (for the array-valued
/// operators that can appear as a constructor leaf). `None` for operators that
/// do not carry a usable type here.
fn operator_dae_type(op: &DAE::Operator) -> Option<Arc<DAE::Type>> {
    use DAE::Operator as O;
    match op {
        O::ADD { ty } | O::SUB { ty } | O::MUL { ty } | O::DIV { ty } | O::POW { ty } | O::UMINUS { ty }
        | O::MUL_SCALAR_PRODUCT { ty } | O::MUL_MATRIX_PRODUCT { ty }
        | O::UMINUS_ARR { ty } | O::ADD_ARR { ty } | O::SUB_ARR { ty } | O::MUL_ARR { ty } | O::DIV_ARR { ty }
        | O::MUL_ARRAY_SCALAR { ty } | O::ADD_ARRAY_SCALAR { ty } | O::SUB_SCALAR_ARRAY { ty }
        | O::DIV_ARRAY_SCALAR { ty } | O::DIV_SCALAR_ARRAY { ty }
        | O::POW_ARRAY_SCALAR { ty } | O::POW_SCALAR_ARRAY { ty } | O::POW_ARR { ty } | O::POW_ARR2 { ty } => {
            Some(ty.clone())
        }
        _ => None,
    }
}

/// Lower a range used as an array value (`start:step:stop`, step default 1).
/// The element count is `(stop - start) / step + 1`, clamped to ≥ 0 (an empty
/// range yields a zero-length array), and a fill loop writes each element. Only
/// Integer-element ranges are handled; Real ranges need the C runtime's
/// element-count rounding to stay byte-identical, so they fail loudly.
fn compile_range_array(ctx: &mut FnCtx, ty: &DAE::Type, start: &DAE::Exp, step: Option<&DAE::Exp>, stop: &DAE::Exp) -> Result<()> {
    let SigTy::Array { elem, .. } = sig_ty(ty)? else {
        bail!("CodegenWasmJit: range with non-array type {ty:?}");
    };
    match &*elem {
        // Integer and enumeration ranges (enum literals are their i32 index).
        SigTy::Int => compile_int_range_array(ctx, start, step, stop),
        SigTy::Real => compile_real_range_array(ctx, start, step, stop),
        other => bail!("CodegenWasmJit: only Integer/Real ranges are supported as array values (element {other:?})"),
    }
}

/// `start:step:stop` over Integers — `n = max(0, (stop-start)/step + 1)`
/// elements (integer division naturally handles either step direction), filled
/// `arr[k] = start + k*step`.
fn compile_int_range_array(ctx: &mut FnCtx, start: &DAE::Exp, step: Option<&DAE::Exp>, stop: &DAE::Exp) -> Result<()> {
    let start_t = ctx.alloc_temp(WTy::I32);
    let w = compile_exp(ctx, start)?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(start_t));
    let step_t = ctx.alloc_temp(WTy::I32);
    match step {
        Some(e) => {
            let w = compile_exp(ctx, e)?;
            coerce(ctx, w, WTy::I32);
        }
        None => ctx.emit(we::Instruction::I32Const(1)),
    }
    ctx.emit(we::Instruction::LocalSet(step_t));
    let stop_t = ctx.alloc_temp(WTy::I32);
    let w = compile_exp(ctx, stop)?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(we::Instruction::LocalSet(stop_t));

    // n = (stop - start) / step + 1, then n = max(n, 0).
    let n_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalGet(stop_t));
    ctx.emit(we::Instruction::LocalGet(start_t));
    ctx.emit(we::Instruction::I32Sub);
    ctx.emit(we::Instruction::LocalGet(step_t));
    ctx.emit(we::Instruction::I32DivS);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(n_t));
    // n = (n > 0) ? n : 0
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::I32GtS);
    ctx.emit(we::Instruction::Select);
    ctx.emit(we::Instruction::LocalSet(n_t));

    let arr = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(SigTy::Int.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")));
    ctx.emit(we::Instruction::LocalSet(arr));
    ctx.emit(we::Instruction::LocalGet(arr));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")));

    // for k in 0..n: arr[k] = start + k*step
    let k_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalSet(k_t));
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::I32GeS);
    ctx.emit(we::Instruction::BrIf(1));
    ctx.emit(we::Instruction::LocalGet(arr));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
    ctx.emit(we::Instruction::LocalGet(start_t));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::LocalGet(step_t));
    ctx.emit(we::Instruction::I32Mul);
    ctx.emit(we::Instruction::I32Add);
    elem_store(ctx, &SigTy::Int);
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(k_t));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block
    ctx.emit(we::Instruction::LocalGet(arr));
    Ok(())
}

/// `start:step:stop` over Reals, byte-identical to the C runtime's
/// `create_real_array_from_range`: the element count is
/// `(step>0 ? start<=stop : start>=stop) ? (size_t)((stop-start)/step + 1) : 0`,
/// and the elements are produced by **accumulation** (`val += step`), not
/// `start + k*step`, so the rounding matches exactly.
fn compile_real_range_array(ctx: &mut FnCtx, start: &DAE::Exp, step: Option<&DAE::Exp>, stop: &DAE::Exp) -> Result<()> {
    // `val` doubles as the running accumulator (starts at `start`).
    let val_t = ctx.alloc_temp(WTy::F64);
    let w = compile_exp(ctx, start)?;
    coerce(ctx, w, WTy::F64);
    ctx.emit(we::Instruction::LocalSet(val_t));
    let step_t = ctx.alloc_temp(WTy::F64);
    match step {
        Some(e) => {
            let w = compile_exp(ctx, e)?;
            coerce(ctx, w, WTy::F64);
        }
        None => ctx.emit(we::Instruction::F64Const(1.0f64.into())),
    }
    ctx.emit(we::Instruction::LocalSet(step_t));
    let stop_t = ctx.alloc_temp(WTy::F64);
    let w = compile_exp(ctx, stop)?;
    coerce(ctx, w, WTy::F64);
    ctx.emit(we::Instruction::LocalSet(stop_t));

    // n = 0; if (step>0 ? start<=stop : start>=stop) n = trunc((stop-start)/step + 1)
    let n_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalSet(n_t));
    // cond on the stack:
    ctx.emit(we::Instruction::LocalGet(step_t));
    ctx.emit(we::Instruction::F64Const(0.0f64.into()));
    ctx.emit(we::Instruction::F64Gt);
    ctx.emit(we::Instruction::If(we::BlockType::Result(we::ValType::I32)));
    ctx.emit(we::Instruction::LocalGet(val_t));
    ctx.emit(we::Instruction::LocalGet(stop_t));
    ctx.emit(we::Instruction::F64Le);
    ctx.emit(we::Instruction::Else);
    ctx.emit(we::Instruction::LocalGet(val_t));
    ctx.emit(we::Instruction::LocalGet(stop_t));
    ctx.emit(we::Instruction::F64Ge);
    ctx.emit(we::Instruction::End);
    ctx.emit(we::Instruction::If(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(stop_t));
    ctx.emit(we::Instruction::LocalGet(val_t));
    ctx.emit(we::Instruction::F64Sub);
    ctx.emit(we::Instruction::LocalGet(step_t));
    ctx.emit(we::Instruction::F64Div);
    ctx.emit(we::Instruction::F64Const(1.0f64.into()));
    ctx.emit(we::Instruction::F64Add);
    ctx.emit(we::Instruction::I32TruncF64S); // truncate toward zero, like (size_t)
    ctx.emit(we::Instruction::LocalSet(n_t));
    ctx.emit(we::Instruction::End);

    let arr = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(SigTy::Real.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")));
    ctx.emit(we::Instruction::LocalSet(arr));
    ctx.emit(we::Instruction::LocalGet(arr));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")));

    // for k in 0..n: arr[k] = val; val += step
    let k_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::LocalSet(k_t));
    ctx.emit(we::Instruction::Block(we::BlockType::Empty));
    ctx.emit(we::Instruction::Loop(we::BlockType::Empty));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::LocalGet(n_t));
    ctx.emit(we::Instruction::I32GeS);
    ctx.emit(we::Instruction::BrIf(1));
    ctx.emit(we::Instruction::LocalGet(arr));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
    ctx.emit(we::Instruction::LocalGet(val_t));
    elem_store(ctx, &SigTy::Real);
    ctx.emit(we::Instruction::LocalGet(val_t));
    ctx.emit(we::Instruction::LocalGet(step_t));
    ctx.emit(we::Instruction::F64Add);
    ctx.emit(we::Instruction::LocalSet(val_t));
    ctx.emit(we::Instruction::LocalGet(k_t));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::LocalSet(k_t));
    ctx.emit(we::Instruction::Br(0));
    ctx.emit(we::Instruction::End); // loop
    ctx.emit(we::Instruction::End); // block
    ctx.emit(we::Instruction::LocalGet(arr));
    Ok(())
}

// Element-wise / broadcast op codes — must match the runtime's `OP_*`.
const OP_ADD: i32 = 0;
const OP_SUB: i32 = 1;
const OP_MUL: i32 = 2;
const OP_DIV: i32 = 3;
const OP_POW: i32 = 4;
const OP_AND: i32 = 5;
const OP_OR: i32 = 6;

/// Element-wise `a op b` over two same-shape arrays: produces a fresh array; the
/// operand arrays are released after.
fn compile_array_ew(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp, op_code: i32, ty: &DAE::Type) -> Result<WTy> {
    let SigTy::Array { elem, .. } = sig_ty(ty)? else {
        bail!("CodegenWasmJit: element-wise array op with non-array type {ty:?}");
    };
    let rt = if elem.wty() == WTy::F64 { "rt_array_ew_f64" } else { "rt_array_ew_i32" };
    compile_exp(ctx, e1)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    compile_exp(ctx, e2)?;
    let bt = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(bt));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::LocalGet(bt));
    ctx.emit(we::Instruction::I32Const(op_code));
    ctx.emit(we::Instruction::Call(rt_index(rt)));
    release_temp_array(ctx, at);
    release_temp_array(ctx, bt);
    Ok(WTy::I32)
}

/// `v1 * v2` scalar (dot) product of two numeric vectors → a scalar. Both
/// operand arrays are released; the scalar result is left on the stack.
fn compile_dot(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp) -> Result<WTy> {
    let elem = array_elem(e1)?.ok_or_else(|| anyhow::anyhow!("CodegenWasmJit: scalar-product operand is not an array"))?;
    let f64mode = elem.wty() == WTy::F64;
    let rt = if f64mode { "rt_array_dot_f64" } else { "rt_array_dot_i32" };
    compile_exp(ctx, e1)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    compile_exp(ctx, e2)?;
    let bt = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(bt));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::LocalGet(bt));
    ctx.emit(we::Instruction::Call(rt_index(rt)));
    release_temp_array(ctx, at);
    release_temp_array(ctx, bt);
    Ok(if f64mode { WTy::F64 } else { WTy::I32 })
}

/// `a * b` matrix product (matrix·matrix / matrix·vector / vector·matrix). The
/// runtime computes the result shape from the operand ranks; both operands are
/// released and the fresh result array handle is left on the stack.
fn compile_matmul(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp) -> Result<WTy> {
    let elem = array_elem(e1)?.ok_or_else(|| anyhow::anyhow!("CodegenWasmJit: matrix-product operand is not an array"))?;
    let rt = if elem.wty() == WTy::F64 { "rt_array_matmul_f64" } else { "rt_array_matmul_i32" };
    compile_exp(ctx, e1)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    compile_exp(ctx, e2)?;
    let bt = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(bt));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::LocalGet(bt));
    ctx.emit(we::Instruction::Call(rt_index(rt)));
    let result_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(result_t));
    release_temp_array(ctx, at);
    release_temp_array(ctx, bt);
    ctx.emit(we::Instruction::LocalGet(result_t));
    Ok(WTy::I32)
}

/// Scalar broadcast over an array: `rev ? (s op a[i]) : (a[i] op s)`. The array
/// and scalar operands are found by type (so commutative forms accept either
/// order); the array operand is released after.
fn compile_array_scalar(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp, op_code: i32, rev: bool, ty: &DAE::Type) -> Result<WTy> {
    let SigTy::Array { elem, .. } = sig_ty(ty)? else {
        bail!("CodegenWasmJit: array-scalar op with non-array type {ty:?}");
    };
    let elem_wty = elem.wty();
    let rt = if elem_wty == WTy::F64 { "rt_array_scalar_f64" } else { "rt_array_scalar_i32" };
    let (arr_e, scal_e) = if matches!(exp_sigty(e1)?, SigTy::Array { .. }) { (e1, e2) } else { (e2, e1) };
    compile_exp(ctx, arr_e)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    let sw = compile_exp(ctx, scal_e)?;
    coerce(ctx, sw, elem_wty);
    let st = ctx.alloc_temp(elem_wty);
    ctx.emit(we::Instruction::LocalSet(st));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::LocalGet(st));
    ctx.emit(we::Instruction::I32Const(op_code));
    ctx.emit(we::Instruction::I32Const(rev as i32));
    ctx.emit(we::Instruction::Call(rt_index(rt)));
    release_temp_array(ctx, at);
    Ok(WTy::I32)
}

/// Lower `a[i, j, ...]` (full subscripting of an N-D array to a scalar element).
/// `base` produces the owned array handle; `subs` must be one `INDEX` per
/// dimension (slicing / partial indexing is not yet supported). Returns the
/// element's wasm type.
fn compile_index(ctx: &mut FnCtx, base: &DAE::Exp, subs: &Arc<List<Arc<DAE::Subscript>>>) -> Result<WTy> {
    let SigTy::Array { elem, rank } = exp_sigty(base)? else {
        bail!("CodegenWasmJit: subscripting a non-array expression");
    };
    compile_exp(ctx, base)?; // owned array handle
    if is_scalar_index(subs, rank) {
        let idx_exps = index_subscripts(subs, rank)?;
        index_loaded(ctx, &elem, &idx_exps)
    } else {
        slice_loaded(ctx, subs)
    }
}

/// Whether a subscript list is a full scalar index — exactly one `INDEX` per
/// dimension — and so yields a scalar element. Anything else (a `WHOLEDIM` /
/// `SLICE`, or fewer subscripts than the rank, i.e. trailing whole dimensions)
/// slices the array to a lower-rank sub-array and goes through [`slice_loaded`].
fn is_scalar_index(subs: &Arc<List<Arc<DAE::Subscript>>>, rank: u32) -> bool {
    let mut n = 0u32;
    let mut all_index = true;
    for s in &**subs {
        n += 1;
        if !matches!(&**s, DAE::Subscript::INDEX { .. }) {
            all_index = false;
        }
    }
    all_index && n == rank
}

/// Extract one `INDEX` expression per dimension from a subscript list, or fail
/// for slicing / whole-dimension / wrong arity (not yet supported).
fn index_subscripts(subs: &Arc<List<Arc<DAE::Subscript>>>, rank: u32) -> Result<Vec<Arc<DAE::Exp>>> {
    let subs: Vec<&Arc<DAE::Subscript>> = (&**subs).into_iter().collect();
    if subs.len() as u32 != rank {
        bail!("CodegenWasmJit: array slicing / partial indexing not supported ({} subscripts on rank {rank})", subs.len());
    }
    let mut out = Vec::with_capacity(subs.len());
    for s in subs {
        match &**s {
            DAE::Subscript::INDEX { exp } => out.push(exp.clone()),
            other => bail!("CodegenWasmJit: non-scalar subscript {other:?} (slicing not supported)"),
        }
    }
    Ok(out)
}

/// Given an owned array handle on top of the stack plus the `INDEX` expressions
/// (one per dimension), compute the row-major linear index, load the scalar
/// element, release the array, and leave the (owned, if heap) element. Returns
/// the element's wasm type.
fn index_loaded(ctx: &mut FnCtx, elem: &SigTy, idx_exps: &[Arc<DAE::Exp>]) -> Result<WTy> {
    let arr_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(arr_t));

    // acc = (i0 - 1); then acc = acc * dim(axis) + (i_axis - 1) row-major.
    let acc = ctx.alloc_temp(WTy::I32);
    let w = compile_exp(ctx, &idx_exps[0])?;
    coerce(ctx, w, WTy::I32);
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Sub);
    ctx.emit(we::Instruction::LocalSet(acc));
    for (axis0, ie) in idx_exps.iter().enumerate().skip(1) {
        ctx.emit(we::Instruction::LocalGet(acc));
        ctx.emit(we::Instruction::LocalGet(arr_t));
        ctx.emit(we::Instruction::I32Const(axis0 as i32 + 1)); // 1-based axis
        ctx.emit(we::Instruction::Call(rt_index("rt_array_dim")));
        ctx.emit(we::Instruction::I32Mul);
        let w = compile_exp(ctx, ie)?;
        coerce(ctx, w, WTy::I32);
        ctx.emit(we::Instruction::I32Const(1));
        ctx.emit(we::Instruction::I32Sub);
        ctx.emit(we::Instruction::I32Add);
        ctx.emit(we::Instruction::LocalSet(acc));
    }
    // addr = rt_array_elem_ptr(arr, acc + 1); load the element.
    ctx.emit(we::Instruction::LocalGet(arr_t));
    ctx.emit(we::Instruction::LocalGet(acc));
    ctx.emit(we::Instruction::I32Const(1));
    ctx.emit(we::Instruction::I32Add);
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
    elem_load(ctx, elem);

    if elem.is_heap() {
        // The element is a borrowed handle into the array; retain it so it
        // outlives the array we now release, making it an owned (+1) result.
        let v = ctx.alloc_temp(WTy::I32);
        ctx.emit(we::Instruction::LocalSet(v));
        ctx.emit(we::Instruction::LocalGet(v));
        ctx.emit(we::Instruction::Call(rt_index("rt_retain")));
        release_temp_array(ctx, arr_t);
        ctx.emit(we::Instruction::LocalGet(v));
    } else {
        // Scalar value already on the stack; releasing the array (void) leaves it.
        release_temp_array(ctx, arr_t);
    }
    Ok(elem.wty())
}

/// Push the byte address of element `slot` (1-based) of the spec array held in
/// local `spec_t` onto the stack.
fn spec_elem_addr(ctx: &mut FnCtx, spec_t: u32, slot: i32) {
    ctx.emit(we::Instruction::LocalGet(spec_t));
    ctx.emit(we::Instruction::I32Const(slot));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
}

/// Given an owned source-array handle on top of the stack and a subscript list
/// that slices / partially indexes it (any `WHOLEDIM`/`SLICE`, or fewer
/// subscripts than the rank), build the per-axis spec and call `rt_array_slice`,
/// leaving a fresh (owned) lower-rank sub-array handle. The source array and any
/// `SLICE` index arrays are released. Returns `WTy::I32` (an array handle).
fn slice_loaded(ctx: &mut FnCtx, subs: &Arc<List<Arc<DAE::Subscript>>>) -> Result<WTy> {
    let subs: Vec<&Arc<DAE::Subscript>> = (&**subs).into_iter().collect();
    let nspec = subs.len() as u32;

    let arr_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(arr_t));

    // The spec is an Integer[2*nspec] array of (kind, value) pairs, one per axis:
    // kind 0 INDEX (value = 1-based index), 1 WHOLE (value unused), 2 SLICE
    // (value = handle to an Integer index array). Read by `rt_array_slice`.
    let spec_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(0)); // EK_INT
    ctx.emit(we::Instruction::I32Const(1)); // ndims
    ctx.emit(we::Instruction::I32Const(2 * nspec as i32)); // total
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")));
    ctx.emit(we::Instruction::LocalSet(spec_t));

    // SLICE index arrays are owned (a fresh range/array); release them after.
    let mut slice_idx_temps: Vec<u32> = Vec::new();
    for (ax, s) in subs.iter().enumerate() {
        let kind_slot = 2 * ax as i32 + 1;
        let val_slot = 2 * ax as i32 + 2;
        match &***s {
            DAE::Subscript::INDEX { exp } => {
                spec_elem_addr(ctx, spec_t, kind_slot);
                ctx.emit(we::Instruction::I32Const(0)); // INDEX
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
                spec_elem_addr(ctx, spec_t, val_slot);
                let w = compile_exp(ctx, exp)?;
                coerce(ctx, w, WTy::I32);
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
            }
            DAE::Subscript::WHOLEDIM | DAE::Subscript::WHOLE_NONEXP { .. } => {
                spec_elem_addr(ctx, spec_t, kind_slot);
                ctx.emit(we::Instruction::I32Const(1)); // WHOLE
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
                // value slot stays 0 (rt_array_new zeroes the spec).
            }
            DAE::Subscript::SLICE { exp } => {
                spec_elem_addr(ctx, spec_t, kind_slot);
                ctx.emit(we::Instruction::I32Const(2)); // SLICE
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
                spec_elem_addr(ctx, spec_t, val_slot);
                let w = compile_exp(ctx, exp)?; // owned Integer index array
                if w != WTy::I32 {
                    bail!("CodegenWasmJit: array slice subscript is not an integer index array");
                }
                let s_t = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalTee(s_t));
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
                slice_idx_temps.push(s_t);
            }
        }
    }

    // result = rt_array_slice(src, nspec, spec)
    ctx.emit(we::Instruction::LocalGet(arr_t));
    ctx.emit(we::Instruction::I32Const(nspec as i32));
    ctx.emit(we::Instruction::LocalGet(spec_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_slice")));
    let result_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(result_t));

    // Release the borrowed source, the per-axis SLICE index arrays, and the spec.
    release_temp_array(ctx, arr_t);
    for s_t in slice_idx_temps {
        release_temp_array(ctx, s_t);
    }
    release_temp_array(ctx, spec_t);

    ctx.emit(we::Instruction::LocalGet(result_t));
    Ok(WTy::I32)
}

/// Release an owned array handle held in scratch local `t`.
fn release_temp_array(ctx: &mut FnCtx, t: u32) {
    ctx.emit(we::Instruction::LocalGet(t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_release")));
}

/// Lower `size(a, d)` (a single dimension size, scalar Integer) or `size(a)`
/// (the whole dimension vector, an `Integer[ndims]`). `a`'s owned handle is
/// released after.
fn compile_size(ctx: &mut FnCtx, exp: &DAE::Exp, sz: Option<&DAE::Exp>) -> Result<()> {
    let SigTy::Array { rank, .. } = exp_sigty(exp)? else {
        bail!("CodegenWasmJit: size() of a non-array expression");
    };
    compile_exp(ctx, exp)?; // owned array handle
    let arr_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(arr_t));

    if let Some(d) = sz {
        // size(a, d): one dimension.
        ctx.emit(we::Instruction::LocalGet(arr_t));
        let w = compile_exp(ctx, d)?;
        coerce(ctx, w, WTy::I32);
        ctx.emit(we::Instruction::Call(rt_index("rt_array_dim")));
        release_temp_array(ctx, arr_t); // leaves the dim value
        return Ok(());
    }

    // size(a): build a fresh Integer[rank] whose element i is size(a, i). The
    // result rank equals `a`'s number of dimensions, known statically.
    let res = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(SigTy::Int.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(1)); // ndims of the result vector
    ctx.emit(we::Instruction::I32Const(rank as i32)); // total = number of axes
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")));
    ctx.emit(we::Instruction::LocalSet(res));
    ctx.emit(we::Instruction::LocalGet(res));
    ctx.emit(we::Instruction::I32Const(0));
    ctx.emit(we::Instruction::I32Const(rank as i32));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")));
    for axis in 1..=rank {
        ctx.emit(we::Instruction::LocalGet(res));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
        ctx.emit(we::Instruction::LocalGet(arr_t));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_dim")));
        elem_store(ctx, &SigTy::Int);
    }
    release_temp_array(ctx, arr_t);
    ctx.emit(we::Instruction::LocalGet(res));
    Ok(())
}

/// The scalar element type of an array-typed expression, or `None` if it is not
/// an array (so an overloaded builtin can fall through to its scalar form).
fn array_elem(e: &DAE::Exp) -> Result<Option<Arc<SigTy>>> {
    Ok(match exp_sigty(e)? {
        SigTy::Array { elem, .. } => Some(elem),
        _ => None,
    })
}

/// Lower the array builtins. Returns `Some(result type)` if `name` is one of
/// them (with the right argument shape), else `None` so the scalar math handler
/// runs. Numeric only (Integer/Boolean/Real elements); a heap-element array
/// (e.g. `sum` of a `String[]`, which is not valid Modelica anyway) is rejected
/// by the runtime dispatch picking an i32/f64 path.
fn compile_array_builtin(
    ctx: &mut FnCtx,
    name: &str,
    argv: &[&Arc<DAE::Exp>],
    attr: &DAE::CallAttributes,
) -> Result<Option<SigTy>> {
    match name {
        // fill(s, d1, ..., dk): array of the given dims, every element = s.
        "fill" => {
            if argv.len() < 2 {
                bail!("CodegenWasmJit: fill expects a value and at least one dimension");
            }
            let arr_ty = sig_ty(&attr.ty)?;
            let SigTy::Array { elem, .. } = &arr_ty else {
                bail!("CodegenWasmJit: fill result is not an array ({arr_ty:?})");
            };
            let obj = emit_alloc_from_exprs(ctx, elem, &argv[1..])?;
            emit_fill_value(ctx, obj, elem, argv[0])?;
            ctx.emit(we::Instruction::LocalGet(obj));
            Ok(Some(arr_ty))
        }
        // zeros(d...) / ones(d...): like fill with a constant 0 / 1.
        "zeros" | "ones" => {
            if argv.is_empty() {
                bail!("CodegenWasmJit: {name} expects at least one dimension");
            }
            let arr_ty = sig_ty(&attr.ty)?;
            let SigTy::Array { elem, .. } = &arr_ty else {
                bail!("CodegenWasmJit: {name} result is not an array ({arr_ty:?})");
            };
            let obj = emit_alloc_from_exprs(ctx, elem, argv)?;
            emit_fill_const(ctx, obj, elem, if name == "ones" { 1 } else { 0 });
            ctx.emit(we::Instruction::LocalGet(obj));
            Ok(Some(arr_ty))
        }
        // sum(a) / product(a) over all elements -> scalar of the element type.
        "sum" | "product" if argv.len() == 1 => match array_elem(argv[0])? {
            None => Ok(None),
            Some(elem) => {
                let rt = match (name, elem.wty()) {
                    ("sum", WTy::F64) => "rt_array_sum_f64",
                    ("sum", WTy::I32) => "rt_array_sum_i32",
                    (_, WTy::F64) => "rt_array_product_f64",
                    (_, WTy::I32) => "rt_array_product_i32",
                };
                emit_array_reduce(ctx, argv[0], rt, None)?;
                Ok(Some((*elem).clone()))
            }
        },
        // min(a) / max(a) of a single array (the two-argument forms are scalar
        // and handled by the math builtins).
        "min" | "max" if argv.len() == 1 => match array_elem(argv[0])? {
            None => Ok(None),
            Some(elem) => {
                let rt = if elem.wty() == WTy::F64 { "rt_array_extreme_f64" } else { "rt_array_extreme_i32" };
                emit_array_reduce(ctx, argv[0], rt, Some(if name == "max" { 1 } else { 0 }))?;
                Ok(Some((*elem).clone()))
            }
        },
        // identity(n): n×n Integer identity matrix.
        "identity" if argv.len() == 1 => {
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_array_identity")));
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // diagonal(v): n×n matrix with the vector v on the diagonal.
        "diagonal" if argv.len() == 1 => {
            if array_elem(argv[0])?.is_none() {
                bail!("CodegenWasmJit: diagonal of a non-array expression");
            }
            compile_exp(ctx, argv[0])?;
            let vt = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(vt));
            ctx.emit(we::Instruction::LocalGet(vt));
            ctx.emit(we::Instruction::Call(rt_index("rt_array_diagonal")));
            release_temp_array(ctx, vt);
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // linspace(x1, x2, n): n evenly-spaced Reals from x1 to x2.
        "linspace" if argv.len() == 3 => {
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::F64);
            let w = compile_exp(ctx, argv[1])?;
            coerce(ctx, w, WTy::F64);
            let w = compile_exp(ctx, argv[2])?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_array_linspace")));
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // transpose(a): a fresh n×m array (the operand 2-D array is released).
        "transpose" if argv.len() == 1 => {
            if array_elem(argv[0])?.is_none() {
                bail!("CodegenWasmJit: transpose of a non-array expression");
            }
            compile_exp(ctx, argv[0])?;
            let at = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(at));
            ctx.emit(we::Instruction::LocalGet(at));
            ctx.emit(we::Instruction::Call(rt_index("rt_array_transpose")));
            release_temp_array(ctx, at);
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // cat(dim, a1, ..., an): concatenate arrays along dimension `dim` into a
        // fresh array. The inputs are passed to the runtime as an Integer array
        // of handles; both the handle array and the inputs are released after.
        "cat" if argv.len() >= 2 => {
            let n = (argv.len() - 1) as u32;
            let dim_t = ctx.alloc_temp(WTy::I32);
            let w = compile_exp(ctx, argv[0])?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::LocalSet(dim_t));
            // Integer[n] array of the input handles.
            let handles_t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::I32Const(0)); // EK_INT
            ctx.emit(we::Instruction::I32Const(1)); // ndims
            ctx.emit(we::Instruction::I32Const(n as i32)); // total
            ctx.emit(we::Instruction::Call(rt_index("rt_array_new")));
            ctx.emit(we::Instruction::LocalSet(handles_t));
            let mut in_temps = Vec::with_capacity(n as usize);
            for (i, a) in argv[1..].iter().enumerate() {
                if array_elem(a)?.is_none() {
                    bail!("CodegenWasmJit: cat argument is not an array");
                }
                ctx.emit(we::Instruction::LocalGet(handles_t));
                ctx.emit(we::Instruction::I32Const(i as i32 + 1));
                ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
                compile_exp(ctx, a)?; // owned input array handle
                let t = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalTee(t));
                ctx.emit(we::Instruction::I32Store(mem_arg(0, 2)));
                in_temps.push(t);
            }
            ctx.emit(we::Instruction::LocalGet(dim_t));
            ctx.emit(we::Instruction::I32Const(n as i32));
            ctx.emit(we::Instruction::LocalGet(handles_t));
            ctx.emit(we::Instruction::Call(rt_index("rt_array_cat")));
            let result_t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(result_t));
            for t in in_temps {
                release_temp_array(ctx, t);
            }
            release_temp_array(ctx, handles_t);
            ctx.emit(we::Instruction::LocalGet(result_t));
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // ndims(a) -> Integer.
        "ndims" if argv.len() == 1 => {
            if array_elem(argv[0])?.is_none() {
                bail!("CodegenWasmJit: ndims of a non-array expression");
            }
            emit_array_reduce(ctx, argv[0], "rt_array_ndims", None)?;
            Ok(Some(SigTy::Int))
        }
        // scalar(a): the single element of an array whose dimensions are all 1.
        "scalar" if argv.len() == 1 => {
            let elem = array_elem(argv[0])?
                .ok_or_else(|| anyhow::anyhow!("CodegenWasmJit: scalar() of a non-array expression"))?;
            compile_exp(ctx, argv[0])?; // owned array
            let arr_t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(arr_t));
            ctx.emit(we::Instruction::LocalGet(arr_t));
            ctx.emit(we::Instruction::I32Const(1));
            ctx.emit(we::Instruction::Call(rt_index("rt_array_elem_ptr")));
            elem_load(ctx, &elem);
            if elem.is_heap() {
                // Retain the borrowed handle so it outlives the array release.
                let v = ctx.alloc_temp(WTy::I32);
                ctx.emit(we::Instruction::LocalSet(v));
                ctx.emit(we::Instruction::LocalGet(v));
                ctx.emit(we::Instruction::Call(rt_index("rt_retain")));
                release_temp_array(ctx, arr_t);
                ctx.emit(we::Instruction::LocalGet(v));
            } else {
                release_temp_array(ctx, arr_t);
            }
            Ok(Some((*elem).clone()))
        }
        // vector(a) / matrix(a): reshape to rank 1 / rank 2; symmetric(a):
        // mirror the upper triangle into the lower. Element-kind generic.
        "vector" if argv.len() == 1 => {
            emit_unary_array(ctx, argv[0], "rt_array_vector")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        "matrix" if argv.len() == 1 => {
            emit_unary_array(ctx, argv[0], "rt_array_matrix")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        "symmetric" if argv.len() == 1 => {
            emit_unary_array(ctx, argv[0], "rt_array_symmetric")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // cross(a,b): Real 3-vector cross product. skew(x): 3x3 skew matrix.
        "cross" if argv.len() == 2 => {
            emit_binary_array(ctx, argv[0], argv[1], "rt_array_cross_f64")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        "skew" if argv.len() == 1 => {
            emit_unary_array(ctx, argv[0], "rt_array_skew_f64")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // outerProduct(a,b): r[i,j] = a[i]*b[j]. Always Real (the operands are
        // promoted to Real by the frontend, like `cross`).
        "outerProduct" if argv.len() == 2 => {
            emit_binary_array(ctx, argv[0], argv[1], "rt_array_outer_f64")?;
            Ok(Some(sig_ty(&attr.ty)?))
        }
        // promote(a, n): add trailing size-1 dimensions to reach rank `n`.
        "promote" if argv.len() == 2 => {
            if array_elem(argv[0])?.is_none() {
                bail!("CodegenWasmJit: promote of a non-array expression");
            }
            compile_exp(ctx, argv[0])?;
            let at = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(at));
            ctx.emit(we::Instruction::LocalGet(at));
            let w = compile_exp(ctx, argv[1])?;
            coerce(ctx, w, WTy::I32);
            ctx.emit(we::Instruction::Call(rt_index("rt_array_promote")));
            let res_t = ctx.alloc_temp(WTy::I32);
            ctx.emit(we::Instruction::LocalSet(res_t));
            release_temp_array(ctx, at);
            ctx.emit(we::Instruction::LocalGet(res_t));
            Ok(Some(sig_ty(&attr.ty)?))
        }
        _ => Ok(None),
    }
}

/// Lower a one-array-argument runtime builtin: evaluate the operand, call `rt`
/// (which returns a fresh array handle), then release the operand. Leaves the
/// result handle on the stack.
fn emit_unary_array(ctx: &mut FnCtx, arg: &DAE::Exp, rt: &str) -> Result<()> {
    if array_elem(arg)?.is_none() {
        bail!("CodegenWasmJit: {rt} of a non-array expression");
    }
    compile_exp(ctx, arg)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::Call(rt_index(rt)));
    release_temp_array(ctx, at);
    Ok(())
}

/// Lower a two-array-argument runtime builtin: evaluate both operands, call
/// `rt`, then release both operands. Leaves the result handle on the stack.
fn emit_binary_array(ctx: &mut FnCtx, e1: &DAE::Exp, e2: &DAE::Exp, rt: &str) -> Result<()> {
    compile_exp(ctx, e1)?;
    let at = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(at));
    compile_exp(ctx, e2)?;
    let bt = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(bt));
    ctx.emit(we::Instruction::LocalGet(at));
    ctx.emit(we::Instruction::LocalGet(bt));
    ctx.emit(we::Instruction::Call(rt_index(rt)));
    release_temp_array(ctx, at);
    release_temp_array(ctx, bt);
    Ok(())
}

/// Allocate a fresh array of element type `elem` whose dimensions are the given
/// expressions (evaluated at runtime). Returns the scratch local holding the
/// owned array handle.
fn emit_alloc_from_exprs(ctx: &mut FnCtx, elem: &SigTy, dim_exprs: &[&Arc<DAE::Exp>]) -> Result<u32> {
    let rank = dim_exprs.len() as u32;
    let mut dim_temps = Vec::with_capacity(dim_exprs.len());
    for de in dim_exprs {
        let t = ctx.alloc_temp(WTy::I32);
        let w = compile_exp(ctx, de)?;
        coerce(ctx, w, WTy::I32);
        ctx.emit(we::Instruction::LocalSet(t));
        dim_temps.push(t);
    }
    ctx.emit(we::Instruction::LocalGet(dim_temps[0]));
    for t in &dim_temps[1..] {
        ctx.emit(we::Instruction::LocalGet(*t));
        ctx.emit(we::Instruction::I32Mul);
    }
    let total_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(total_t));
    let obj = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::I32Const(elem.elem_kind() as i32));
    ctx.emit(we::Instruction::I32Const(rank as i32));
    ctx.emit(we::Instruction::LocalGet(total_t));
    ctx.emit(we::Instruction::Call(rt_index("rt_array_new")));
    ctx.emit(we::Instruction::LocalSet(obj));
    for (axis, t) in dim_temps.iter().enumerate() {
        ctx.emit(we::Instruction::LocalGet(obj));
        ctx.emit(we::Instruction::I32Const(axis as i32));
        ctx.emit(we::Instruction::LocalGet(*t));
        ctx.emit(we::Instruction::Call(rt_index("rt_array_set_dim")));
    }
    Ok(obj)
}

/// Fill every element of array `obj` with the value of `val` (the `fill` value).
fn emit_fill_value(ctx: &mut FnCtx, obj: u32, elem: &SigTy, val: &DAE::Exp) -> Result<()> {
    ctx.emit(we::Instruction::LocalGet(obj));
    let w = compile_exp(ctx, val)?;
    coerce(ctx, w, elem.wty());
    ctx.emit(we::Instruction::Call(rt_index(fill_fn(elem))));
    Ok(())
}

/// Fill every element of array `obj` with the integer constant `k` (for
/// `zeros`/`ones`), converted to the element's wasm type.
fn emit_fill_const(ctx: &mut FnCtx, obj: u32, elem: &SigTy, k: i32) {
    ctx.emit(we::Instruction::LocalGet(obj));
    match elem.wty() {
        WTy::I32 => ctx.emit(we::Instruction::I32Const(k)),
        WTy::F64 => ctx.emit(we::Instruction::F64Const((k as f64).into())),
    }
    ctx.emit(we::Instruction::Call(rt_index(fill_fn(elem))));
}

fn fill_fn(elem: &SigTy) -> &'static str {
    match elem.wty() {
        WTy::F64 => "rt_array_fill_f64",
        WTy::I32 => "rt_array_fill_i32",
    }
}

/// Reduce an array to a scalar via runtime function `rt_fn` (optionally with an
/// extra `i32` argument, e.g. the min/max selector). The array operand is owned
/// (released after); the scalar result is left on the stack.
fn emit_array_reduce(ctx: &mut FnCtx, arr: &DAE::Exp, rt_fn: &str, extra: Option<i32>) -> Result<()> {
    compile_exp(ctx, arr)?; // owned array handle
    let a_t = ctx.alloc_temp(WTy::I32);
    ctx.emit(we::Instruction::LocalSet(a_t));
    ctx.emit(we::Instruction::LocalGet(a_t));
    if let Some(k) = extra {
        ctx.emit(we::Instruction::I32Const(k));
    }
    ctx.emit(we::Instruction::Call(rt_index(rt_fn)));
    release_temp_array(ctx, a_t); // leaves the scalar result
    Ok(())
}

fn unary_f64(ctx: &mut FnCtx, argv: &[&Arc<DAE::Exp>], instr: we::Instruction<'static>) -> Result<()> {
    need_args(argv, 1, "<f64 builtin>")?;
    let w = compile_exp(ctx, argv[0])?;
    coerce(ctx, w, WTy::F64);
    ctx.emit(instr);
    Ok(())
}

fn need_args(argv: &[&Arc<DAE::Exp>], n: usize, name: &str) -> Result<()> {
    if argv.len() != n {
        bail!("CodegenWasmJit: builtin {name} expects {n} args, got {}", argv.len());
    }
    Ok(())
}

/// Emit a numeric conversion if the value on the stack is not already the
/// wanted type. Integer/Boolean both live in `i32`, so I32<->I32 is a no-op.
fn coerce(ctx: &mut FnCtx, from: WTy, to: WTy) {
    match (from, to) {
        (WTy::I32, WTy::F64) => ctx.emit(we::Instruction::F64ConvertI32S),
        (WTy::F64, WTy::I32) => ctx.emit(we::Instruction::I32TruncF64S),
        _ => {}
    }
}

// -------------------------------------------------------------------------
// MetaModelica entry points (called from CevalScript)
// -------------------------------------------------------------------------

/// `CodegenWasmJitFunctions.translateFunctions`: lower `fnCode` to a wasm module
/// written to `<name>.wasm` (+ `<name>.wasm.sig`).
///
/// When the `wasm-jit` target is selected it is authoritative: a construct it
/// cannot lower is a hard, visible failure (a panic with the precise reason),
/// **not** a silent degradation to the C target. This surfaces exactly what is
/// unimplemented instead of masking it behind a `META_FAIL`. Stale artefacts
/// from a previous target are removed first so a panic cannot leave a mismatched
/// module behind.
pub fn translateFunctions(fnCode: SimCodeFunction::FunctionCode) {
    let _ = std::fs::remove_file(format!("{}.wasm", fnCode.name));
    let _ = std::fs::remove_file(format!("{}.wasm.sig", fnCode.name));
    if let Err(e) = translate_functions_inner(&fnCode) {
        panic!("CodegenWasmJit: cannot JIT function `{}` for the wasm-jit target: {e:#}", fnCode.name);
    }
}

fn translate_functions_inner(fn_code: &SimCodeFunction::FunctionCode) -> Result<()> {
    let (bytes, in_sig, out_sig) = build_module(fn_code)?;
    let base = fn_code.name.to_string();
    // Sidecar: line 1 = input type codes, line 2 = output type codes.
    let mut in_codes = String::new();
    in_sig.iter().for_each(|s| s.write_code(&mut in_codes));
    let mut out_codes = String::new();
    out_sig.iter().for_each(|s| s.write_code(&mut out_codes));
    let sig = format!("{in_codes}\n{out_codes}\n");
    // Native writes the module + sidecar to disk; wasm has no OS filesystem, so
    // stage them in the VFS where `load_and_execute` reads them back.
    #[cfg(target_arch = "wasm32")]
    {
        openmodelica_wasi::write(&format!("{base}.wasm"), bytes);
        openmodelica_wasi::write(&format!("{base}.wasm.sig"), sig.into_bytes());
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        std::fs::write(format!("{base}.wasm"), &bytes)?;
        std::fs::write(format!("{base}.wasm.sig"), sig)?;
    }
    Ok(())
}

/// `CodegenWasmJitFunctions.loadAndExecute`: instantiate `<fileName>.wasm` and
/// call the exported `main`, marshalling `args` in and the result out. Returns
/// `Values.META_FAIL` on any failure (missing/invalid module, a wasm trap from
/// a failed assertion or division by zero, …), mirroring `DynLoad.executeFunction`.
pub fn loadAndExecute(fileName: ArcStr, name: ArcStr, args: Arc<List<Arc<Values::Value>>>) -> Arc<Values::Value> {
    match runtime::load_and_execute(&fileName, &name, &args) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("CodegenWasmJit: execution of `{name}` failed: {e:#}");
            Arc::new(Values::Value::META_FAIL)
        }
    }
}
