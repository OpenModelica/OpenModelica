//! Import tables: env builtins, env extras, runtime primitives, global
//! indices, name mangling.

use super::*;

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

pub(super) fn builtin_index(name: &str) -> Option<u32> {
    BUILTINS.iter().position(|(n, _, _)| *n == name).map(|i| i as u32)
}

/// Extra host imports (module `"env"`) that the generated code calls but which
/// are *not* pure-math `BUILTINS` — they have their own signatures and host-side
/// effects. Imported *after* the [`BUILTINS`] and the [`RT_BUILTINS`] (so the
/// `rt_*` indices are unaffected), just before the generated functions. The host
/// closures live in `runtime::add_host_builtins`.
///
/// `rt_assert(msg, file, sline, scol, eline, ecol, isReadOnly, cond, initial, sim_data) -> shouldTrap`
/// records the failed assertion and answers whether the generated code must trap:
/// it need not while the driver has asserts suppressed (C's `noThrowAsserts`).
/// `cond` is the dumped condition, or 0 for a model/runtime error, which is never
/// suppressed; it comes last so callers that already pushed the message append.
/// `initial` is C's `initial()` at the assert site, for the message header, and
/// `sim_data` is C's `data` (0 outside a simulation), which an FMU heads the logged
/// block with the time from.
///
/// `rt_assert_warning(cond, msg, file, sline, scol, eline, ecol, isReadOnly, initial)`
/// records a *non-fatal* (AssertionLevel.warning) violation — the string handles
/// (dumped condition, message, file) plus source position — for the driver to
/// format as a `LOG_ASSERT` warning after the step. The generated code continues
/// (no trap), matching C's `omc_assert_warning`.
///
/// `rt_print(str)` writes the String's bytes to the model's stdout (the `print`
/// builtin). The host reads the handle's bytes from the shared memory during the
/// call; the generated code releases the (owned) handle afterwards.
///
/// `rt_row_asserts(sim_data, warn) -> stop` formats the violations recorded at the
/// output row the emitted `simulate` loop just stored — the driver's per-row
/// `LOG_ASSERT` step, which that loop cannot reach from wasm. `warn` selects the
/// level; a nonzero result means a suppressed `assert()` ends the run.
///
/// `rt_reinit_note(state_off, value)` records an executed `reinit` for the driver's
/// `LOG_EVENTS` block; C prints that line from the model itself, but the block's
/// indentation belongs to whichever driver owns the run.
///
/// `rt_uri_to_filename(uri, fmu) -> filename` is C's `OpenModelica_uriToFilename_impl`,
/// which needs a filesystem and the loaded program's class directories. `fmu` picks
/// the FMU resources directory (`OpenModelica_fmuLoadResource`). Borrows `uri`.
pub(crate) const ENV_EXTRA: &[(&str, &[WTy], &[WTy])] = &[
    (
        "rt_assert",
        &[WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32],
        &[WTy::I32],
    ),
    (
        "rt_assert_warning",
        &[WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32],
        &[],
    ),
    ("rt_print", &[WTy::I32], &[]),
    ("rt_row_asserts", &[WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_reinit_note", &[WTy::I32, WTy::F64], &[]),
    ("rt_uri_to_filename", &[WTy::I32, WTy::I32], &[WTy::I32]),
    // Give the external "C" libraries their shadow stack back after a throw
    // abandoned their frames — the epilogues that would have done it never ran.
    ("rt_ext_stack_save", &[], &[WTy::I32]),
    ("rt_ext_stack_restore", &[WTy::I32], &[]),
];

/// Absolute wasm function index of an `ENV_EXTRA` import (after the `BUILTINS`
/// and `RT_BUILTINS`).
pub(crate) fn env_extra_index(name: &str) -> Result<u32> {
    let pos = ENV_EXTRA
        .iter()
        .position(|(n, _, _)| *n == name)
        .ok_or_else(|| "CodegenWasmJit: unknown env-extra import")?;
    Ok((BUILTINS.len() + RT_BUILTINS.len() + pos) as u32)
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
    ("rt_extobj_arg_f64", &[WTy::I32, WTy::I32, WTy::F64], &[WTy::I32]),
    ("rt_extobj_arg_i32", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_extobj_arg_str", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_extobj_arg_arr", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    ("rt_extobj_arg_rec", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
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
    // The element area itself, for an `external "C"` array argument.
    ("rt_array_data", &[WTy::I32], &[WTy::I32]),
    // The out-of-range arm of the inlined element-address computation.
    ("rt_elem_ptr_oob", &[WTy::I32, WTy::I32], &[WTy::I32]),
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
    // Sliced left-hand side `a[i, :, lo:hi, ...] := src`: (dst, nspec, spec, src),
    // same spec encoding. `src` holds the selected positions in selection order.
    ("rt_array_indexed_assign", &[WTy::I32, WTy::I32, WTy::I32, WTy::I32], &[]),
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
    // odd-root / nan-inf handling; the third argument is the source position an
    // invalid root reports at.
    ("rt_real_pow", &[WTy::F64, WTy::F64, WTy::I32], &[WTy::F64]),
    ("rt_invalid_root", &[WTy::F64, WTy::F64, WTy::I32], &[]),
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
    // b `n` f64 at b_ptr; solution overwrites b), C's `aux_x` at x_ptr for the
    // iterative `-ls lis`, then the equation index and time the fallback warning
    // needs, whether a `rt_ls_check_step` follows, and whether this is a casual
    // tearing set (which has no fallback). Returns 0 ok, 1 singular.
    ("rt_linsolve", &[WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::F64, WTy::I32, WTy::I32], &[WTy::I32]),
    // The same `A` re-solved with total pivoting: (a_ptr, b_ptr, n, index, time) ->
    // 0 ok / 1 inconsistent. C's fallback for a step `rt_ls_check_step` rejected.
    ("rt_linsolve_totalpivot", &[WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::F64], &[WTy::I32]),
    // C's `check_linear_solution` + throw for an unsolved system: (index, time).
    ("rt_ls_failed", &[WTy::I32, WTy::F64], &[]),
    // `LOG_STATS_V`'s per-system bracket, C's `solve_linear_system`: the generated
    // code assembles `A`/`b` itself, so it has to open the clock. (index, size, nnz).
    ("rt_ls_begin", &[WTy::I32, WTy::I32, WTy::I32], &[]),
    ("rt_ls_end", &[], &[]),
    // Method-1 step test: (res_ptr, b_ptr, n, index, time, dense, casual) -> 1 when
    // the step must be redone with total pivoting (`b` then holding `-res`), 2 when
    // the system is unsolved. See `rt_ls_check_step`.
    ("rt_ls_check_step", &[WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::F64, WTy::I32, WTy::I32], &[WTy::I32]),
    // Sparse linear solve `A x = b` in place, A in CSC: (colptr n+1 i32, rowidx
    // nnz i32, values nnz f64, b_ptr n f64, n, nnz) -> 0 ok / 1 singular. The C
    // runtime's KLU path (AMD-ordered sparse LU); see `rt_solve_lin_sparse`.
    ("rt_solve_lin_sparse", &[WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    // Solve `A x = b` from dense column-major A via the sparse solver; see
    // `rt_solve_lin_dense_sparse`. (a_ptr, b_ptr, x_ptr, n, index, time) -> 0 ok /
    // 1 singular.
    ("rt_solve_lin_dense_sparse", &[WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::F64], &[WTy::I32]),
    // (handle, colptr, rowidx, values, b, x, n, nnz, time) -> 0 ok / 1 singular; cached analysis.
    ("rt_solve_lin_sparse_cached", &[WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::F64], &[WTy::I32]),
    // Raw deallocation (frees a block from `rt_alloc`); used to release the
    // `SES_LINEAR` scratch (A/b/residual buffers) after each solve.
    ("rt_free", &[WTy::I32], &[]),
    // Nonlinear solve for one `SES_NONLINEAR` system: (sim_data, residual-table
    // index, load-table index, n unknowns, nls_fail flag address) -> 0 ok / 1
    // recoverable failure (2 = dynamic tearing's strict set solved it instead). The
    // Newton driver lives in the runtime; the model supplies `residual`/`load` funcs
    // reached by `call_indirect` (see `nls.rs`).
    ("rt_solve_nls", &[WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::F64, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    // Dynamic tearing: the `LOG_DT` / `LOG_DT_CONS` lines C's `checkConstraints`,
    // `equationLinear` and `equation*AlternativeTearing` print. `rt_dt_local_violated`
    // also latches the failure, standing in for `residualFuncConstraints`'s return.
    ("rt_dt_cons_violated", &[WTy::I32, WTy::I32], &[]),
    ("rt_dt_local_violated", &[WTy::I32], &[]),
    ("rt_dt_solving", &[WTy::I32, WTy::I32, WTy::F64, WTy::I32], &[]),
    ("rt_dt_fallback", &[WTy::I32], &[]),
    // `delay(...)` / `delayZeroCrossing(...)` ring buffers (runtime `delay.rs`).
    ("rt_delay_init", &[WTy::I32, WTy::F64], &[]),
    ("rt_delay_store", &[WTy::I32, WTy::F64, WTy::F64, WTy::F64, WTy::F64], &[]),
    ("rt_delay_eval", &[WTy::I32, WTy::F64, WTy::F64, WTy::F64, WTy::F64], &[WTy::F64]),
    ("rt_delay_zc", &[WTy::I32, WTy::F64, WTy::F64, WTy::F64], &[WTy::F64]),
    // `spatialDistribution(...)` transported profiles (runtime `spatial.rs`).
    // `rt_spatial_eval` returns `out0`; `rt_spatial_out1` hands back the `out1` of
    // that same call, which is C's `double* out1` out-parameter without a
    // scratch address.
    ("rt_spatial_init", &[WTy::I32], &[]),
    ("rt_spatial_init_profile", &[WTy::I32, WTy::I32, WTy::I32], &[]),
    ("rt_spatial_store", &[WTy::I32, WTy::F64, WTy::F64, WTy::F64, WTy::F64, WTy::I32], &[]),
    ("rt_spatial_eval", &[WTy::I32, WTy::F64, WTy::F64, WTy::F64, WTy::F64, WTy::I32, WTy::I32], &[WTy::F64]),
    ("rt_spatial_out1", &[WTy::I32], &[WTy::F64]),
    ("rt_spatial_zc", &[WTy::I32, WTy::F64, WTy::I32, WTy::F64], &[WTy::F64]),
    // Recoverable-assert hooks for a nonlinear-solver residual (see `nls.rs`).
    ("rt_nls_recovering", &[], &[WTy::I32]),
    ("rt_nls_note_assert", &[], &[]),
    ("rt_assert_suppressed", &[], &[WTy::I32]),
    // C's `assertCommonVar` when a catcher is open: `(msg, sim_data, initial)`,
    // non-zero when the caller must return instead of trapping.
    ("rt_assert_common", &[WTy::I32, WTy::I32, WTy::I32], &[WTy::I32]),
    // `+profiling`: C's `rt_init` / `SIM_PROF_TICK_*` / `SIM_PROF_ACC_*` /
    // `SIM_PROF_ADD_NCALL_EQ` (see `prof.rs`).
    ("rt_prof_init", &[WTy::I32], &[]),
    ("rt_prof_tick", &[WTy::I32], &[]),
    ("rt_prof_acc", &[WTy::I32], &[]),
    ("rt_prof_add_ncall", &[WTy::I32, WTy::I32], &[]),
    // C's `throwStreamPrint` and the reporting half of its `DIVISION_SIM`.
    ("rt_throw_stream", &[WTy::I32], &[]),
    ("rt_div_sim", &[WTy::F64, WTy::F64, WTy::I32, WTy::F64, WTy::I32], &[WTy::F64]),
    // System `k`'s solver state (address, size), for `rt_nls_clean_history`.
    ("rt_nls_register", &[WTy::I32, WTy::I32, WTy::I32], &[]),
    // `rt_nls_note_assert` plus C's log line for the absorbed assertion:
    // `(msg, file, sline, scol, eline, ecol, isReadOnly, cond, initial, sim_data)`.
    (
        "rt_nls_assert_failed",
        &[
            WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32, WTy::I32,
            WTy::I32,
        ],
        &[],
    ),
    // `external` marshalling in a shared-memory module (a wasm FMU), where there
    // is no host trampoline to convert: a by-reference cell per `_Out_` (or
    // Fortran) scalar, and a column-major copy per multi-dimensional Fortran
    // array. Appended last so no existing `rt_index` shifts.
    ("rt_f77_cell_r", &[WTy::F64], &[WTy::I32]),
    ("rt_f77_cell_i", &[WTy::I32], &[WTy::I32]),
    ("rt_f77_cell_get_r", &[WTy::I32], &[WTy::F64]),
    ("rt_f77_cell_get_i", &[WTy::I32], &[WTy::I32]),
    ("rt_f77_arr_in", &[WTy::I32], &[WTy::I32]),
    ("rt_f77_arr_out", &[WTy::I32, WTy::I32, WTy::I32], &[]),
    // A `char*` a shared-memory `external "C"` returned or wrote, as a `String`.
    ("rt_str_from_cstr", &[WTy::I32], &[WTy::I32]),
    // A `String[…]` output: its elements released before the call, and the
    // `char*`s the callee wrote over them read back after it.
    ("rt_str_array_clear", &[WTy::I32], &[]),
    ("rt_str_array_from_cstr", &[WTy::I32], &[]),
];

/// Model global holding the base index at which this module's per-system
/// `residual`/`load` functions were appended to the shared
/// `rt.__indirect_function_table` (set once by the module's `start` function).
pub(crate) const NLS_BASE_GLOBAL: u32 = 0;

/// Module global holding the base index this module's closure thunks were
/// appended to the shared table at (set by `start`): after the five
/// nonlinear-solver globals, or the only global when there are none.
pub(crate) fn closure_base_global(has_nls: bool) -> u32 {
    if has_nls { NLS_BOUNDS_GLOBAL + 1 } else { 0 }
}

/// First of the module's shared-literal globals (see `shared_lits`). The closure
/// global is reserved whether or not the module has thunks, so this base is known
/// before the bodies are lowered.
pub(crate) fn lit_base_global(has_nls: bool) -> u32 {
    closure_base_global(has_nls) + 1
}

/// Absolute wasm function index of a runtime import (after all [`BUILTINS`]).
pub(crate) fn rt_index(name: &str) -> Result<u32> {
    let pos = RT_BUILTINS
        .iter()
        .position(|(n, _, _)| *n == name)
        .ok_or_else(|| "CodegenWasmJit: unknown runtime function")?;
    Ok((BUILTINS.len() + pos) as u32)
}

/// `_`-mangled name of a function path, matching `CevalScript`'s
/// `generateFunctionName` (`AbsynUtil.pathStringUnquoteReplaceDot(path, "_")`).
/// Used as the key that resolves a `CALL` to one of the generated functions.
pub(crate) fn mangle(path: &Absyn::Path) -> Result<String> {
    Ok(AbsynUtil::pathStringUnquoteReplaceDot(Arc::new(path.clone()), arcstr::literal!("_"))?.to_string())
}
