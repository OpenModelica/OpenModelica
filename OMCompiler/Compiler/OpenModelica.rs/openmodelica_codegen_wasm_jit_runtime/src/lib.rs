//! Static linear-memory runtime for the `wasm-jit` simCodeTarget.
//!
//! Compiled once to `wasm32-unknown-unknown` and shared (its `memory` plus the
//! `rt_*` exports) by every JIT-compiled function / simulation-RHS module. This
//! is the *static* half the user asked to precompile: the allocator, reference
//! counting and string operations live here as one optimized native artifact
//! instead of being re-emitted into each generated module.
//!
//! ## Heap object ABI
//!
//! Every heap object is reference counted. `rt_alloc` returns a pointer to the
//! object; the first 4 bytes (`obj[0..4]`) are the `u32` reference count, the
//! rest is payload. A hidden size word precedes the object so `rt_free` can hand
//! the block back to `dlmalloc`. `rt_retain` / `rt_release` adjust the count;
//! `rt_release` frees the object (via `dlmalloc`) when it reaches zero. Handle
//! `0` is the null object: retain/release on it are no-ops, so a heap local can
//! start zero-initialized.
//!
//! ## String layout
//!
//! A `String` object is `[refcount:u32][len:u32][utf8 bytes...]`; the byte data
//! starts at `obj + 8` (`rt_str_data`). Strings are immutable: every operation
//! that "modifies" a string returns a freshly allocated one. Formatting
//! (`rt_int_string` / `rt_real_string` / `rt_bool_string`) reuses the exact same
//! algorithm as the rest of the compiler so `String(x)` is byte-identical to the
//! C target (see `ryu_to_hr`, ported from `metamodelica`/the C `om_format.c`).
//!
//! ## Arrays
//!
//! 1-D arrays reuse `rt_alloc`/`rt_retain` and add a self-describing object (see
//! the Arrays section) with its own `rt_array_release` that releases contained
//! heap elements before freeing. Records will follow the same pattern with an
//! `rt_record_release` when they land.

// `no_std` on the JIT runtime target (`wasm32-unknown-unknown`, no std). The
// standalone-export target (`wasm32-wasip1`) has std — needed for the in-wasm
// driver / `write_mat4` / `_start` to do file I/O over WASI — so std is left
// enabled there, and the custom panic handler (std provides one) is dropped.
#![cfg_attr(not(target_os = "wasi"), no_std)]

extern crate alloc;

use alloc::format;
use alloc::string::String;
use core::alloc::{GlobalAlloc, Layout};

// dlmalloc is the global allocator on both targets so every allocation in the
// merged module — runtime `rt_alloc`, and on wasip1 the driver's `Vec`s — shares
// one heap. (It builds for wasip1 too.)
#[global_allocator]
static GLOBAL: dlmalloc::GlobalDlmalloc = dlmalloc::GlobalDlmalloc;

/// A wasm trap on panic (e.g. allocation failure or a bad substring range),
/// which the host surfaces as `Values.META_FAIL` exactly like a runtime error.
/// Only on the `no_std` JIT runtime target; std supplies the handler on wasip1.
#[cfg(not(target_os = "wasi"))]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    core::arch::wasm32::unreachable()
}

// ---------------------------------------------------------------------------
// Raw little-endian memory access (all pointers are byte offsets into the one
// shared linear memory).
// ---------------------------------------------------------------------------

#[inline]
unsafe fn load_u32(addr: u32) -> u32 {
    unsafe { core::ptr::read_unaligned(addr as *const u32) }
}

#[inline]
unsafe fn store_u32(addr: u32, v: u32) {
    unsafe { core::ptr::write_unaligned(addr as *mut u32, v) }
}

#[inline]
unsafe fn load_i32(addr: u32) -> i32 {
    unsafe { core::ptr::read_unaligned(addr as *const i32) }
}

#[inline]
unsafe fn load_f64(addr: u32) -> f64 {
    unsafe { core::ptr::read_unaligned(addr as *const f64) }
}

#[inline]
unsafe fn store_f64(addr: u32, v: f64) {
    unsafe { core::ptr::write_unaligned(addr as *mut f64, v) }
}

// ---------------------------------------------------------------------------
// Allocator + reference counting
// ---------------------------------------------------------------------------

/// Bytes reserved before every object for the allocation size (used by
/// `rt_free`). 8 rather than 4 so the returned object is 8-byte aligned, which
/// keeps `f64` array/record elements naturally aligned.
const HEADER: usize = 8;
const ALIGN: usize = 8;

/// Allocate an object of `size` payload bytes (including its 4-byte refcount),
/// returning its pointer. The reference count is left zero — the typed
/// constructors below set it to 1.
#[unsafe(no_mangle)]
pub extern "C" fn rt_alloc(size: u32) -> u32 {
    let total = HEADER + size as usize;
    let layout = Layout::from_size_align(total, ALIGN).expect("bad layout");
    let raw = unsafe { GLOBAL.alloc(layout) } as u32;
    if raw == 0 {
        // Out of memory: trap.
        core::arch::wasm32::unreachable();
    }
    unsafe { store_u32(raw, total as u32) };
    raw + HEADER as u32
}

/// Free an object previously returned by `rt_alloc`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_free(obj: u32) {
    if obj == 0 {
        return;
    }
    let raw = obj - HEADER as u32;
    let total = unsafe { load_u32(raw) } as usize;
    let layout = Layout::from_size_align(total, ALIGN).expect("bad layout");
    unsafe { GLOBAL.dealloc(raw as *mut u8, layout) };
}

/// Increment an object's reference count (no-op on the null handle).
#[unsafe(no_mangle)]
pub extern "C" fn rt_retain(obj: u32) {
    if obj == 0 {
        return;
    }
    unsafe { store_u32(obj, load_u32(obj) + 1) };
}

/// Decrement an object's reference count, freeing it at zero (no-op on null).
///
/// Only valid for objects with no contained heap references (currently every
/// `String`). Arrays/records of heap elements will get typed release entry
/// points that release their children first.
#[unsafe(no_mangle)]
pub extern "C" fn rt_release(obj: u32) {
    if obj == 0 {
        return;
    }
    let rc = unsafe { load_u32(obj) } - 1;
    unsafe { store_u32(obj, rc) };
    if rc == 0 {
        rt_free(obj);
    }
}

// ---------------------------------------------------------------------------
// Arrays (N-dimensional, flat row-major)
// ---------------------------------------------------------------------------
//
// An array object is
//   `[refcount:u32][elem_kind:u32][ndims:u32][total:u32][dim_0:u32 .. dim_{n-1}:u32]
//    [pad to 8][elements row-major ...]`.
// `total` is the product of the dims (the number of scalar elements). The
// element area is 8-byte aligned (so `f64` elements are aligned) and the
// elements are packed by kind — 4 bytes for Integer/Boolean and for a heap
// *handle* (String / nested array), 8 bytes for Real — stored row-major (last
// subscript varies fastest), matching the C runtime's `base_array` and the
// nested `Values.ARRAY` the rest of the compiler uses.
//
// The `elem_kind`/`ndims`/`dim_*` words make the object self-describing, so the
// generic `rt_array_release` frees contained heap elements (recursing into
// nested arrays) and the host marshals it out without a per-element sidecar.
//
// The element-kind tags MUST match `SigTy::elem_kind` in the codegen.
const EK_INT: u32 = 0;
const EK_REAL: u32 = 1;
const EK_BOOL: u32 = 2;
const EK_STR: u32 = 3;
const EK_ARRAY: u32 = 4;
const EK_RECORD: u32 = 5;

const ARR_KIND_OFF: u32 = 4;
const ARR_NDIMS_OFF: u32 = 8;
const ARR_TOTAL_OFF: u32 = 12;
const ARR_DIMS_OFF: u32 = 16;

/// Byte stride of one element of the given kind: 8 for Real, 4 for Integer /
/// Boolean and for a heap handle (String / nested array).
fn elem_stride(kind: u32) -> u32 {
    match kind {
        EK_REAL => 8,
        // Integer/Boolean and every heap *handle* (String / array / record) are 4.
        EK_INT | EK_BOOL | EK_STR | EK_ARRAY | EK_RECORD => 4,
        _ => 4,
    }
}

/// Release one heap handle of the given element/field kind (no-op for a scalar
/// kind). Shared by array-element and record-field cleanup.
fn release_kind(kind: u32, handle: u32) {
    match kind {
        EK_STR => rt_release(handle),
        EK_ARRAY => rt_array_release(handle),
        EK_RECORD => rt_record_release(handle),
        _ => {}
    }
}

/// Value-semantics copy of one heap handle of the given kind: immutable strings
/// are shared with a retain, mutable arrays/records are deep-copied. Returns the
/// (possibly new) handle to store back.
fn copy_kind(kind: u32, handle: u32) -> u32 {
    match kind {
        EK_STR => {
            rt_retain(handle);
            handle
        }
        EK_ARRAY => rt_array_copy(handle),
        EK_RECORD => rt_record_copy(handle),
        _ => handle,
    }
}

/// Round `n` up to the next multiple of 8 (element-area alignment).
fn align8(n: u32) -> u32 {
    (n + 7) & !7
}

/// Byte offset from the object base to the first element, given `ndims`.
fn arr_data_off(ndims: u32) -> u32 {
    align8(ARR_DIMS_OFF + ndims * 4)
}

/// Byte address of the first element.
fn arr_data(obj: u32) -> u32 {
    obj + arr_data_off(unsafe { load_u32(obj + ARR_NDIMS_OFF) })
}

/// Allocate a zero-initialized array object: `ndims` dimensions, `total` scalar
/// elements of `elem_kind` (refcount 1, dims left 0 — set with `rt_array_set_dim`).
/// Zeroing means handle elements start as the null handle (0), so releasing a
/// partially filled array is safe.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_new(elem_kind: u32, ndims: u32, total: u32) -> u32 {
    let data_off = arr_data_off(ndims);
    let obj = rt_alloc(data_off + total * elem_stride(elem_kind));
    unsafe {
        store_u32(obj, 1); // refcount
        store_u32(obj + ARR_KIND_OFF, elem_kind);
        store_u32(obj + ARR_NDIMS_OFF, ndims);
        store_u32(obj + ARR_TOTAL_OFF, total);
        // Zero the dim words and the element area (rt_alloc does not zero).
        for off in (ARR_DIMS_OFF..data_off + total * elem_stride(elem_kind)).step_by(4) {
            store_u32(obj + off, 0);
        }
    }
    obj
}

/// Set the size of dimension `axis` (0-based) of an array.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_set_dim(obj: u32, axis: u32, size: u32) {
    unsafe { store_u32(obj + ARR_DIMS_OFF + axis * 4, size) };
}

/// Number of dimensions.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_ndims(obj: u32) -> u32 {
    unsafe { load_u32(obj + ARR_NDIMS_OFF) }
}

/// Total number of scalar elements (product of the dimensions).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_total(obj: u32) -> u32 {
    unsafe { load_u32(obj + ARR_TOTAL_OFF) }
}

/// Size of dimension `axis` (1-based, as Modelica `size(a, axis)` is). Traps on
/// an out-of-range axis.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_dim(obj: u32, axis: i32) -> u32 {
    let ndims = rt_array_ndims(obj) as i32;
    if axis < 1 || axis > ndims {
        core::arch::wasm32::unreachable();
    }
    unsafe { load_u32(obj + ARR_DIMS_OFF + (axis as u32 - 1) * 4) }
}

/// Byte address of the element at row-major linear position `index` (1-based).
/// Traps on an out-of-range index (→ META_FAIL), matching the bounds check the
/// C target performs. The generated code computes `index` from the per-axis
/// subscripts and `rt_array_dim`, then loads/stores through this address with
/// the element's natural wasm type.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_elem_ptr(obj: u32, index: i32) -> u32 {
    let total = rt_array_total(obj) as i32;
    if index < 1 || index > total {
        core::arch::wasm32::unreachable();
    }
    let kind = unsafe { load_u32(obj + ARR_KIND_OFF) };
    arr_data(obj) + (index as u32 - 1) * elem_stride(kind)
}

/// Copy every element of `src` into `dst` starting at the 0-based element
/// offset `dst_off`. Heap elements are copied with value semantics (`copy_kind`:
/// strings retained, arrays/records deep-copied), so the destination owns its
/// own references. The two arrays must share the same element kind — the codegen
/// guarantees this when flattening a nested array constructor whose elements are
/// themselves arrays (`{v, w}` of vectors). Used by `compile_array_literal`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_blit(dst: u32, dst_off: u32, src: u32) {
    if src == 0 {
        return;
    }
    let kind = unsafe { load_u32(src + ARR_KIND_OFF) };
    let stride = elem_stride(kind);
    let n = rt_array_total(src);
    let sdata = arr_data(src);
    let ddata = arr_data(dst) + dst_off * stride;
    for i in 0..n {
        let s = sdata + i * stride;
        let d = ddata + i * stride;
        if kind == EK_REAL {
            unsafe { store_f64(d, load_f64(s)) };
        } else {
            let v = unsafe { load_u32(s) };
            unsafe { store_u32(d, copy_kind(kind, v)) };
        }
    }
}

/// Value-semantics copy of an array: a fresh array (refcount 1) with the same
/// kind/dimensions and independent storage, so mutating either does not affect
/// the other. Strings are immutable, so a String element is shared with a
/// retain; a nested *array* element is deep-copied (recursively) to preserve
/// value semantics. The null handle copies to null.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_copy(obj: u32) -> u32 {
    if obj == 0 {
        return 0;
    }
    let kind = unsafe { load_u32(obj + ARR_KIND_OFF) };
    let ndims = rt_array_ndims(obj);
    let total = rt_array_total(obj);
    let dup = rt_array_new(kind, ndims, total);
    for axis in 0..ndims {
        unsafe { store_u32(dup + ARR_DIMS_OFF + axis * 4, load_u32(obj + ARR_DIMS_OFF + axis * 4)) };
    }
    let (src, dst) = (arr_data(obj), arr_data(dup));
    let stride = elem_stride(kind);
    unsafe {
        core::ptr::copy_nonoverlapping(src as *const u8, dst as *mut u8, (total * stride) as usize);
    }
    // Adjust the (now byte-copied) heap element handles: retain strings, deep-copy
    // mutable arrays/records so the copy shares no mutable storage.
    if kind == EK_STR || kind == EK_ARRAY || kind == EK_RECORD {
        for i in 0..total {
            let copied = copy_kind(kind, unsafe { load_u32(dst + i * 4) });
            unsafe { store_u32(dst + i * 4, copied) };
        }
    }
    dup
}

/// Decrement an array's reference count, freeing it at zero (no-op on null).
/// Before freeing, any contained heap elements are released according to the
/// element kind, so nested strings / arrays are not leaked. Recurses through
/// nested arrays (each carries its own `elem_kind`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_release(obj: u32) {
    if obj == 0 {
        return;
    }
    let rc = unsafe { load_u32(obj) } - 1;
    unsafe { store_u32(obj, rc) };
    if rc != 0 {
        return;
    }
    let kind = unsafe { load_u32(obj + ARR_KIND_OFF) };
    // Heap element kinds hold handles that must be released first.
    if kind == EK_STR || kind == EK_ARRAY || kind == EK_RECORD {
        let data = arr_data(obj);
        for i in 0..rt_array_total(obj) {
            release_kind(kind, unsafe { load_u32(data + i * 4) });
        }
    }
    rt_free(obj);
}

/// Slice / partial-index a source array into a fresh (refcount-1) array, the
/// runtime counterpart of `a[i, :, lo:hi, ...]` on an array whose dimensions
/// are not known at codegen time (constant-dimension slices are scalarized by
/// the frontend and lowered element-by-element instead).
///
/// `spec` is an Integer array of `2 * nspec` words describing the first `nspec`
/// source axes (0-based): `spec[2*s]` is the axis kind and `spec[2*s+1]` its
/// value —
///   * kind 0 = INDEX  → value is the fixed 1-based index; the axis is dropped
///     from the result (rank-reducing).
///   * kind 1 = WHOLE  → value unused; the axis is kept at full size.
///   * kind 2 = SLICE  → value is a handle to an Integer array of 1-based
///     indices; the axis is kept, sized to that index array's length.
/// Source axes `>= nspec` are treated as WHOLE (trailing `a[i]` on a matrix).
///
/// The result's element kind matches the source; heap elements are deep-copied
/// (`copy_kind`, matching `rt_array_copy`) so the slice shares no mutable
/// storage. The source array is read only — the caller still owns and releases
/// it (and the per-axis SLICE index arrays).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_slice(src: u32, nspec: u32, spec: u32) -> u32 {
    let kind = unsafe { load_u32(src + ARR_KIND_OFF) };
    let src_ndims = rt_array_ndims(src);
    let spec_data = arr_data(spec);
    // Per-source-axis kind/value, with axes past `nspec` defaulting to WHOLE.
    let ax_kind = |s: u32| -> u32 {
        if s < nspec { unsafe { load_u32(spec_data + (2 * s) * 4) } } else { 1 }
    };
    let ax_val = |s: u32| -> u32 {
        if s < nspec { unsafe { load_u32(spec_data + (2 * s + 1) * 4) } } else { 0 }
    };

    // Result rank/shape: one axis per kept (WHOLE/SLICE) source axis.
    let mut res_ndims = 0u32;
    let mut res_total = 1u32;
    for s in 0..src_ndims {
        match ax_kind(s) {
            0 => {} // INDEX: dropped
            1 => {
                res_total *= rt_array_dim(src, s as i32 + 1);
                res_ndims += 1;
            }
            _ => {
                res_total *= rt_array_total(ax_val(s)); // SLICE index-array length
                res_ndims += 1;
            }
        }
    }
    let result = rt_array_new(kind, res_ndims, res_total);
    {
        let mut rk = 0u32;
        for s in 0..src_ndims {
            match ax_kind(s) {
                0 => {}
                1 => {
                    rt_array_set_dim(result, rk, rt_array_dim(src, s as i32 + 1));
                    rk += 1;
                }
                _ => {
                    rt_array_set_dim(result, rk, rt_array_total(ax_val(s)));
                    rk += 1;
                }
            }
        }
    }

    // Scratch: 0-based source coordinate per source axis (INDEX axes fixed once)
    // followed by the result coordinate per result axis (recomputed per element).
    let scratch = rt_alloc((src_ndims + res_ndims) * 4);
    let src_coord = scratch;
    let res_coord = scratch + src_ndims * 4;
    for s in 0..src_ndims {
        let c = if ax_kind(s) == 0 { ax_val(s) - 1 } else { 0 };
        unsafe { store_u32(src_coord + s * 4, c) };
    }

    let stride = elem_stride(kind);
    let src_base = arr_data(src);
    let dst_base = arr_data(result);
    let heap = matches!(kind, EK_STR | EK_ARRAY | EK_RECORD);
    for r in 0..res_total {
        // Decompose `r` into per-result-axis coordinates (row-major).
        let mut rem = r;
        let mut rk = res_ndims;
        while rk > 0 {
            rk -= 1;
            let d = unsafe { load_u32(result + ARR_DIMS_OFF + rk * 4) };
            unsafe { store_u32(res_coord + rk * 4, rem % d) };
            rem /= d;
        }
        // Map result coordinates back onto the source axes.
        let mut rk = 0u32;
        for s in 0..src_ndims {
            match ax_kind(s) {
                0 => {} // fixed
                1 => {
                    let c = unsafe { load_u32(res_coord + rk * 4) };
                    unsafe { store_u32(src_coord + s * 4, c) };
                    rk += 1;
                }
                _ => {
                    let idx_arr = ax_val(s);
                    let pos = unsafe { load_u32(res_coord + rk * 4) };
                    // SLICE index array holds 1-based source indices (Integer).
                    let one_based = unsafe { load_u32(arr_data(idx_arr) + pos * 4) };
                    unsafe { store_u32(src_coord + s * 4, one_based - 1) };
                    rk += 1;
                }
            }
        }
        // Row-major source linear index from the source coordinates.
        let mut lin = 0u32;
        for s in 0..src_ndims {
            lin = lin * rt_array_dim(src, s as i32 + 1) + unsafe { load_u32(src_coord + s * 4) };
        }
        let sp = src_base + lin * stride;
        let dp = dst_base + r * stride;
        unsafe {
            core::ptr::copy_nonoverlapping(sp as *const u8, dp as *mut u8, stride as usize);
            if heap {
                store_u32(dp, copy_kind(kind, load_u32(dp)));
            }
        }
    }

    rt_free(scratch);
    result
}

/// Concatenate `n` arrays along dimension `dim` (1-based) into a fresh
/// (refcount-1) array — the runtime counterpart of `cat(dim, a1, ..., an)`.
/// `handles` is an Integer array of the `n` input array handles. The inputs
/// share rank and element kind and agree on every dimension except `dim`; the
/// result keeps that shape with its `dim` size the sum of the inputs' `dim`
/// sizes. Elements are copied row-major with a running offset along `dim`; heap
/// elements are deep-copied (`copy_kind`) for value semantics. The inputs are
/// read only — the caller still owns and releases them.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_cat(dim: u32, n: u32, handles: u32) -> u32 {
    let hdata = arr_data(handles);
    let first = unsafe { load_u32(hdata) };
    let kind = unsafe { load_u32(first + ARR_KIND_OFF) };
    let ndims = rt_array_ndims(first);
    let axis = dim - 1; // 0-based concatenation axis

    // Result total: product of dims, where the `axis` dim is the sum over inputs.
    let mut total = 1u32;
    for a in 0..ndims {
        let d = if a == axis {
            let mut s = 0u32;
            for c in 0..n {
                s += rt_array_dim(unsafe { load_u32(hdata + c * 4) }, a as i32 + 1);
            }
            s
        } else {
            rt_array_dim(first, a as i32 + 1)
        };
        total *= d;
    }
    let result = rt_array_new(kind, ndims, total);
    for a in 0..ndims {
        let d = if a == axis {
            let mut s = 0u32;
            for c in 0..n {
                s += rt_array_dim(unsafe { load_u32(hdata + c * 4) }, a as i32 + 1);
            }
            s
        } else {
            rt_array_dim(first, a as i32 + 1)
        };
        rt_array_set_dim(result, a, d);
    }

    let scratch = rt_alloc(ndims * 4); // per-axis source coordinate
    let stride = elem_stride(kind);
    let heap = matches!(kind, EK_STR | EK_ARRAY | EK_RECORD);
    let dst_base = arr_data(result);
    let mut off = 0u32; // running offset of this input along `axis`
    for c in 0..n {
        let src = unsafe { load_u32(hdata + c * 4) };
        let src_total = rt_array_total(src);
        let src_base = arr_data(src);
        for e in 0..src_total {
            // Decompose `e` into per-axis source coordinates (row-major).
            let mut rem = e;
            let mut a = ndims;
            while a > 0 {
                a -= 1;
                let d = rt_array_dim(src, a as i32 + 1);
                unsafe { store_u32(scratch + a * 4, rem % d) };
                rem /= d;
            }
            // Shift the concatenation axis by this input's running offset.
            let shifted = unsafe { load_u32(scratch + axis * 4) } + off;
            unsafe { store_u32(scratch + axis * 4, shifted) };
            // Recompose into the result linear index (row-major over result dims).
            let mut r = 0u32;
            for a in 0..ndims {
                let rd = unsafe { load_u32(result + ARR_DIMS_OFF + a * 4) };
                r = r * rd + unsafe { load_u32(scratch + a * 4) };
            }
            let sp = src_base + e * stride;
            let dp = dst_base + r * stride;
            unsafe {
                core::ptr::copy_nonoverlapping(sp as *const u8, dp as *mut u8, stride as usize);
                if heap {
                    store_u32(dp, copy_kind(kind, load_u32(dp)));
                }
            }
        }
        off += rt_array_dim(src, dim as i32);
    }

    rt_free(scratch);
    result
}

/// Scalar (dot) product of two equal-length numeric vectors `sum a[i]*b[i]`.
/// The runtime counterpart of `v1 * v2` (`MUL_SCALAR_PRODUCT`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_dot_f64(a: u32, b: u32) -> f64 {
    let n = rt_array_total(a);
    let (da, db) = (arr_data(a), arr_data(b));
    let mut acc = 0.0f64;
    for i in 0..n {
        acc += unsafe { load_f64(da + i * 8) * load_f64(db + i * 8) };
    }
    acc
}

#[unsafe(no_mangle)]
pub extern "C" fn rt_array_dot_i32(a: u32, b: u32) -> i32 {
    let n = rt_array_total(a);
    let (da, db) = (arr_data(a), arr_data(b));
    let mut acc = 0i32;
    for i in 0..n {
        acc = acc.wrapping_add(unsafe { load_i32(da + i * 4).wrapping_mul(load_i32(db + i * 4)) });
    }
    acc
}

// Inner dimensions for a rank-agnostic matrix product `a * b` where each operand
// is a vector (treated as 1×n / n×1) or a matrix: `a` is logically m×k row-major,
// `b` is k×p row-major, the result m×p. A vector `a` has m = 1, a matrix has
// m = dim 1; `k` is always `a`'s last dim; a vector `b` has p = 1, a matrix has
// p = dim 2. The result rank is `a.ndims + b.ndims - 2` (matrix·matrix → 2,
// matrix·vector / vector·matrix → 1), sized m*p along its single axis when 1-D.
fn matmul_shape(a: u32, b: u32) -> (u32, u32, u32, u32) {
    let a_nd = rt_array_ndims(a);
    let b_nd = rt_array_ndims(b);
    let m = if a_nd == 2 { rt_array_dim(a, 1) } else { 1 };
    let k = rt_array_dim(a, a_nd as i32);
    let p = if b_nd == 2 { rt_array_dim(b, 2) } else { 1 };
    let res_nd = a_nd + b_nd - 2;
    (m, k, p, res_nd)
}

fn matmul_result(kind: u32, m: u32, p: u32, res_nd: u32) -> u32 {
    let result = rt_array_new(kind, res_nd, m * p);
    if res_nd == 2 {
        rt_array_set_dim(result, 0, m);
        rt_array_set_dim(result, 1, p);
    } else {
        rt_array_set_dim(result, 0, m * p);
    }
    result
}

/// Matrix product `a * b` for Real operands (`MUL_MATRIX_PRODUCT`), handling
/// matrix·matrix, matrix·vector and vector·matrix uniformly (see `matmul_shape`).
/// Returns a fresh array; the operands are read only.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_matmul_f64(a: u32, b: u32) -> u32 {
    let (m, k, p, res_nd) = matmul_shape(a, b);
    let result = matmul_result(EK_REAL, m, p, res_nd);
    let (da, db, dr) = (arr_data(a), arr_data(b), arr_data(result));
    for i in 0..m {
        for j in 0..p {
            let mut acc = 0.0f64;
            for t in 0..k {
                acc += unsafe { load_f64(da + (i * k + t) * 8) * load_f64(db + (t * p + j) * 8) };
            }
            unsafe { store_f64(dr + (i * p + j) * 8, acc) };
        }
    }
    result
}

#[unsafe(no_mangle)]
pub extern "C" fn rt_array_matmul_i32(a: u32, b: u32) -> u32 {
    let (m, k, p, res_nd) = matmul_shape(a, b);
    let result = matmul_result(EK_INT, m, p, res_nd);
    let (da, db, dr) = (arr_data(a), arr_data(b), arr_data(result));
    for i in 0..m {
        for j in 0..p {
            let mut acc = 0i32;
            for t in 0..k {
                acc = acc.wrapping_add(unsafe {
                    load_i32(da + (i * k + t) * 4).wrapping_mul(load_i32(db + (t * p + j) * 4))
                });
            }
            unsafe { store_u32(dr + (i * p + j) * 4, acc as u32) };
        }
    }
    result
}

/// Copy every (row-major) element of `src` into `dst` (same kind/total),
/// deep-copying heap handles for value semantics. Shared by reshape builtins.
fn copy_all_elems(src: u32, dst: u32, kind: u32, total: u32) {
    let stride = elem_stride(kind);
    let (sd, dd) = (arr_data(src), arr_data(dst));
    unsafe {
        core::ptr::copy_nonoverlapping(sd as *const u8, dd as *mut u8, (total * stride) as usize);
    }
    if matches!(kind, EK_STR | EK_ARRAY | EK_RECORD) {
        for i in 0..total {
            unsafe { store_u32(dd + i * 4, copy_kind(kind, load_u32(dd + i * 4))) };
        }
    }
}

/// `vector(a)`: flatten to a 1-D array (row-major order), copying all elements.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_vector(a: u32) -> u32 {
    let kind = unsafe { load_u32(a + ARR_KIND_OFF) };
    let total = rt_array_total(a);
    let res = rt_array_new(kind, 1, total);
    rt_array_set_dim(res, 0, total);
    copy_all_elems(a, res, kind, total);
    res
}

/// `matrix(a)`: reshape to a 2-D `[size(a,1), total/size(a,1)]` array (the
/// trailing dimensions are 1), copying all elements row-major.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_matrix(a: u32) -> u32 {
    let kind = unsafe { load_u32(a + ARR_KIND_OFF) };
    let total = rt_array_total(a);
    let d1 = rt_array_dim(a, 1);
    let d2 = if d1 == 0 { 0 } else { total / d1 };
    let res = rt_array_new(kind, 2, total);
    rt_array_set_dim(res, 0, d1);
    rt_array_set_dim(res, 1, d2);
    copy_all_elems(a, res, kind, total);
    res
}

/// `symmetric(a)`: copy the upper triangle (incl. diagonal) of a square matrix
/// into the lower triangle — `r[i,j] = a[i,j]` for `j >= i`, else `a[j,i]`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_symmetric(a: u32) -> u32 {
    let kind = unsafe { load_u32(a + ARR_KIND_OFF) };
    let n = rt_array_dim(a, 1);
    let m = rt_array_dim(a, 2);
    let res = rt_array_new(kind, 2, n * m);
    rt_array_set_dim(res, 0, n);
    rt_array_set_dim(res, 1, m);
    let stride = elem_stride(kind);
    let (sd, dd) = (arr_data(a), arr_data(res));
    let heap = matches!(kind, EK_STR | EK_ARRAY | EK_RECORD);
    for i in 0..n {
        for j in 0..m {
            let (si, sj) = if j >= i { (i, j) } else { (j, i) };
            let sp = sd + (si * m + sj) * stride;
            let dp = dd + (i * m + j) * stride;
            unsafe {
                core::ptr::copy_nonoverlapping(sp as *const u8, dp as *mut u8, stride as usize);
                if heap {
                    store_u32(dp, copy_kind(kind, load_u32(dp)));
                }
            }
        }
    }
    res
}

/// `cross(a, b)`: the 3-vector cross product (Real-only per the Modelica spec).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_cross_f64(a: u32, b: u32) -> u32 {
    let (da, db) = (arr_data(a), arr_data(b));
    let g = |p: u32, i: u32| unsafe { load_f64(p + i * 8) };
    let (a1, a2, a3) = (g(da, 0), g(da, 1), g(da, 2));
    let (b1, b2, b3) = (g(db, 0), g(db, 1), g(db, 2));
    let res = rt_array_new(EK_REAL, 1, 3);
    rt_array_set_dim(res, 0, 3);
    let dr = arr_data(res);
    unsafe {
        store_f64(dr, a2 * b3 - a3 * b2);
        store_f64(dr + 8, a3 * b1 - a1 * b3);
        store_f64(dr + 16, a1 * b2 - a2 * b1);
    }
    res
}

/// `outerProduct(a, b)`: matrix `r[i,j] = a[i]*b[j]` (sizes `n` x `m`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_outer_f64(a: u32, b: u32) -> u32 {
    let (n, m) = (rt_array_total(a), rt_array_total(b));
    let res = rt_array_new(EK_REAL, 2, n * m);
    rt_array_set_dim(res, 0, n);
    rt_array_set_dim(res, 1, m);
    let (da, db, dr) = (arr_data(a), arr_data(b), arr_data(res));
    for i in 0..n {
        for j in 0..m {
            unsafe { store_f64(dr + (i * m + j) * 8, load_f64(da + i * 8) * load_f64(db + j * 8)) };
        }
    }
    res
}

/// Convert an Integer-element array to a fresh Real-element array (element-wise
/// `i32 as f64`), preserving the shape. Implements the implicit `Integer[] ->
/// Real[]` cast the frontend inserts (assignment, mixed arithmetic, division,
/// which always yields Real, …).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_int_to_real(a: u32) -> u32 {
    let nd = rt_array_ndims(a);
    let total = rt_array_total(a);
    let res = rt_array_new(EK_REAL, nd, total);
    for axis in 0..nd {
        rt_array_set_dim(res, axis, rt_array_dim(a, axis as i32 + 1));
    }
    let (da, dr) = (arr_data(a), arr_data(res));
    for i in 0..total {
        unsafe { store_f64(dr + i * 8, load_i32(da + i * 4) as f64) };
    }
    res
}

/// `promote(a, n)`: add trailing size-1 dimensions so the array has `n`
/// dimensions (n >= ndims(a)); the element data is unchanged (row-major), only
/// the shape grows. Used by the dynamic-size expansions of `outerProduct` etc.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_promote(a: u32, n: u32) -> u32 {
    let kind = unsafe { load_u32(a + ARR_KIND_OFF) };
    let nd = rt_array_ndims(a);
    let total = rt_array_total(a);
    let res = rt_array_new(kind, n, total);
    for axis in 0..n {
        let d = if axis < nd { rt_array_dim(a, axis as i32 + 1) } else { 1 };
        rt_array_set_dim(res, axis, d);
    }
    copy_all_elems(a, res, kind, total);
    res
}

/// `skew(x)`: the 3x3 skew-symmetric matrix `{{0,-x3,x2},{x3,0,-x1},{-x2,x1,0}}`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_skew_f64(x: u32) -> u32 {
    let dx = arr_data(x);
    let g = |i: u32| unsafe { load_f64(dx + i * 8) };
    let (x1, x2, x3) = (g(0), g(1), g(2));
    let res = rt_array_new(EK_REAL, 2, 9);
    rt_array_set_dim(res, 0, 3);
    rt_array_set_dim(res, 1, 3);
    let dr = arr_data(res);
    let vals = [0.0, -x3, x2, x3, 0.0, -x1, -x2, x1, 0.0];
    for (i, v) in vals.iter().enumerate() {
        unsafe { store_f64(dr + (i as u32) * 8, *v) };
    }
    res
}

/// `base ^ n` for an integer exponent, replicating the C runtime's
/// `real_int_pow` (exponentiation by squaring) bit-for-bit so that scalar
/// `x ^ <integer literal>` stays byte-identical with the C target — which uses
/// this form rather than a generic `pow` for integer exponents (`x*x`, `x*x*x`,
/// `(x*x)*(x*x)` and `real_int_pow` for the rest all reduce to this squaring
/// sequence). Negative exponents return the reciprocal; `0 ^ (negative)` is
/// undefined and traps.
#[unsafe(no_mangle)]
pub extern "C" fn rt_real_int_pow(mut base: f64, mut n: i32) -> f64 {
    let mut result = 1.0f64;
    let neg = n < 0;
    if neg {
        if base == 0.0 {
            core::arch::wasm32::unreachable();
        }
        n = -n;
    }
    while n != 0 {
        if n % 2 != 0 {
            result *= base;
            n -= 1;
        }
        base *= base;
        n /= 2;
    }
    if neg { 1.0 / result } else { result }
}

// Transcendental math builtins that generated model modules import (the
// `BUILTINS` table in CodegenWasmJitFunctions). Previously these crossed the
// wasm->host boundary (`add_host_builtins`, module `env`); providing them
// in-wasm via `libm` removes that per-call crossing — a win on the browser js
// backend — and lets a merged standalone module be self-contained. Exported
// under their bare libm names so the generated `rt`-namespace import resolves.
macro_rules! rt_math1 {
    ($name:ident) => {
        #[unsafe(no_mangle)]
        pub extern "C" fn $name(x: f64) -> f64 { libm::$name(x) }
    };
}
macro_rules! rt_math2 {
    ($name:ident) => {
        #[unsafe(no_mangle)]
        pub extern "C" fn $name(x: f64, y: f64) -> f64 { libm::$name(x, y) }
    };
}
rt_math2!(pow);
rt_math2!(atan2);
rt_math1!(sin);
rt_math1!(cos);
rt_math1!(tan);
rt_math1!(asin);
rt_math1!(acos);
rt_math1!(atan);
rt_math1!(sinh);
rt_math1!(cosh);
rt_math1!(tanh);
rt_math1!(exp);
rt_math1!(log);
rt_math1!(log10);
rt_math1!(cbrt);
rt_math1!(expm1);
rt_math1!(log1p);
rt_math1!(exp2);
rt_math1!(log2);
rt_math1!(asinh);
rt_math1!(acosh);
rt_math1!(atanh);
rt_math2!(hypot);
rt_math2!(fmod);

/// Scalar `base ^ exp` for a non-integer-literal exponent, replicating the C
/// target's inlined generic real-power semantics so the result stays
/// byte-identical. A negative base with an (effectively) integer exponent or an
/// odd-root fractional exponent gives a real value; any other negative-base
/// fractional exponent is an "invalid root"; and any nan/inf result is rejected.
/// All the error cases trap, surfacing as `fail()` (META_FAIL) exactly as the C
/// `throwStreamPrint` path does in the function-evaluation context.
#[unsafe(no_mangle)]
pub extern "C" fn rt_real_pow(base: f64, exp: f64) -> f64 {
    let result;
    if base < 0.0 && exp != 0.0 {
        // Split the exponent into integer / fractional parts and round to the
        // nearest integer (residual in [-0.5, 0.5]).
        let mut int = libm::trunc(exp);
        let mut frac = exp - int;
        if frac > 0.5 {
            frac -= 1.0;
            int += 1.0;
        } else if frac < -0.5 {
            frac += 1.0;
            int -= 1.0;
        }
        if libm::fabs(frac) < 1e-10 {
            // Effectively an integer exponent: well-defined for a negative base.
            result = libm::pow(base, int);
        } else {
            // A real fractional exponent is only real when 1/exp is an odd
            // integer (an odd root, e.g. (-8)^(1/3) = -2).
            let inv = 1.0 / exp;
            let mut iint = libm::trunc(inv);
            let mut ifrac = inv - iint;
            if ifrac > 0.5 {
                ifrac -= 1.0;
                iint += 1.0;
            } else if ifrac < -0.5 {
                ifrac += 1.0;
                iint -= 1.0;
            }
            if libm::fabs(ifrac) < 1e-10 && ((iint as i64 as u64) & 1) != 0 {
                result = -libm::pow(-base, frac) * libm::pow(base, int);
            } else {
                core::arch::wasm32::unreachable();
            }
        }
    } else {
        result = libm::pow(base, exp);
    }
    if result.is_nan() || result.is_infinite() {
        core::arch::wasm32::unreachable();
    }
    result
}

/// Integer `mod(x, y)` — Modelica's floored modulo `x - floor(x/y)*y`, whose
/// result takes the sign of the divisor (unlike C's truncated `%`). Traps on a
/// zero divisor, matching integer division by zero.
#[unsafe(no_mangle)]
pub extern "C" fn rt_mod_int(x: i32, y: i32) -> i32 {
    if y == 0 {
        core::arch::wasm32::unreachable();
    }
    let r = x.wrapping_rem(y);
    if r != 0 && (r < 0) != (y < 0) { r + y } else { r }
}

// ---------------------------------------------------------------------------
// Records (heterogeneous, self-describing via an inline heap-field table)
// ---------------------------------------------------------------------------
//
// A record object is
//   `[refcount:u32][nheap:u32][ (elem_kind:u32, field_off:u32) × nheap ]
//    [pad to 8][field data...]`.
// The fixed fields (Integer/Boolean=4, Real=8, heap handle=4) are laid out by
// the codegen in declaration order at `field_off` bytes into the field-data
// area, which begins at `rec_data_off(nheap)`. The inline table lists only the
// *heap* fields (string / array / nested record) — their element kind and offset
// — so the generic `rt_record_release`/`rt_record_copy` can free or deep-copy
// nested heap values without a per-type runtime descriptor. Field *access* needs
// no runtime call: the codegen loads/stores at the constant `data_off + off`.
//
// `elem_kind` here is the same tag set as arrays (`EK_*`), so `release_kind` /
// `copy_kind` are shared.

const REC_NHEAP_OFF: u32 = 4;

/// Byte offset from the object base to the field-data area, given the number of
/// heap fields (each table entry is 8 bytes; the area is 8-aligned so Real
/// fields stay aligned).
fn rec_data_off(nheap: u32) -> u32 {
    align8(8 + nheap * 8)
}

/// Allocate a zero-initialized record object: `nheap` heap fields and `size`
/// total payload bytes (refcount 1; the heap-field table and field data are left
/// zero — the codegen fills the table and the fields). Zeroing means heap fields
/// start as the null handle, so releasing a partially built record is safe.
#[unsafe(no_mangle)]
pub extern "C" fn rt_record_new(nheap: u32, size: u32) -> u32 {
    let obj = rt_alloc(size);
    unsafe {
        store_u32(obj, 1); // refcount
        store_u32(obj + REC_NHEAP_OFF, nheap);
        for off in (8..size).step_by(4) {
            store_u32(obj + off, 0);
        }
    }
    obj
}

/// Decrement a record's reference count, freeing it at zero (no-op on null).
/// Before freeing, every heap field listed in the inline table is released
/// according to its kind (recursing into nested records/arrays).
#[unsafe(no_mangle)]
pub extern "C" fn rt_record_release(obj: u32) {
    if obj == 0 {
        return;
    }
    let rc = unsafe { load_u32(obj) } - 1;
    unsafe { store_u32(obj, rc) };
    if rc != 0 {
        return;
    }
    let nheap = unsafe { load_u32(obj + REC_NHEAP_OFF) };
    let data = obj + rec_data_off(nheap);
    for k in 0..nheap {
        let kind = unsafe { load_u32(obj + 8 + k * 8) };
        let off = unsafe { load_u32(obj + 8 + k * 8 + 4) };
        release_kind(kind, unsafe { load_u32(data + off) });
    }
    rt_free(obj);
}

/// Value-semantics copy of a record: a fresh object (refcount 1) with the same
/// layout and independent storage. Scalar fields are byte-copied; heap fields
/// are retained (strings) or deep-copied (arrays/records). The null handle
/// copies to null.
#[unsafe(no_mangle)]
pub extern "C" fn rt_record_copy(obj: u32) -> u32 {
    if obj == 0 {
        return 0;
    }
    // Payload size = allocation size minus the allocator's `HEADER` word, which
    // `rt_alloc` stored just before the object.
    let payload = unsafe { load_u32(obj - HEADER as u32) } - HEADER as u32;
    let dup = rt_alloc(payload);
    unsafe {
        core::ptr::copy_nonoverlapping(obj as *const u8, dup as *mut u8, payload as usize);
        store_u32(dup, 1); // fresh refcount
    }
    let nheap = unsafe { load_u32(obj + REC_NHEAP_OFF) };
    let data = dup + rec_data_off(nheap);
    for k in 0..nheap {
        let kind = unsafe { load_u32(dup + 8 + k * 8) };
        let off = unsafe { load_u32(dup + 8 + k * 8 + 4) };
        let copied = copy_kind(kind, unsafe { load_u32(data + off) });
        unsafe { store_u32(data + off, copied) };
    }
    dup
}

// ---------------------------------------------------------------------------
// Array builtins (numeric: Integer/Boolean live in i32, Real in f64)
// ---------------------------------------------------------------------------
//
// These operate element-wise over the flat row-major data and so are
// independent of rank. The codegen picks the i32 vs f64 variant from the
// element type; `fill` is used for `fill`/`zeros`/`ones`, the reductions for
// `sum`/`product`/`min`/`max`. The array's `total` is the element count.

/// `fill(v, ...)` for an i32-element (Integer/Boolean) array: set every element.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_fill_i32(obj: u32, v: i32) {
    let data = arr_data(obj);
    for i in 0..rt_array_total(obj) {
        unsafe { store_u32(data + i * 4, v as u32) };
    }
}

/// `fill(v, ...)` for a Real array.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_fill_f64(obj: u32, v: f64) {
    let data = arr_data(obj);
    for i in 0..rt_array_total(obj) {
        unsafe { store_f64(data + i * 8, v) };
    }
}

/// `sum(a)` over an i32-element array (wrapping, like Modelica Integer arithmetic).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_sum_i32(obj: u32) -> i32 {
    let data = arr_data(obj);
    let mut acc = 0i32;
    for i in 0..rt_array_total(obj) {
        acc = acc.wrapping_add(unsafe { load_i32(data + i * 4) });
    }
    acc
}

/// `sum(a)` over a Real array.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_sum_f64(obj: u32) -> f64 {
    let data = arr_data(obj);
    let mut acc = 0.0f64;
    for i in 0..rt_array_total(obj) {
        acc += unsafe { load_f64(data + i * 8) };
    }
    acc
}

/// `product(a)` over an i32-element array.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_product_i32(obj: u32) -> i32 {
    let data = arr_data(obj);
    let mut acc = 1i32;
    for i in 0..rt_array_total(obj) {
        acc = acc.wrapping_mul(unsafe { load_i32(data + i * 4) });
    }
    acc
}

/// `product(a)` over a Real array.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_product_f64(obj: u32) -> f64 {
    let data = arr_data(obj);
    let mut acc = 1.0f64;
    for i in 0..rt_array_total(obj) {
        acc *= unsafe { load_f64(data + i * 8) };
    }
    acc
}

/// `min(a)`/`max(a)` over an i32-element array. An empty array is a runtime
/// error in Modelica, so it traps (→ META_FAIL). `want_max != 0` selects max.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_extreme_i32(obj: u32, want_max: i32) -> i32 {
    let total = rt_array_total(obj);
    if total == 0 {
        core::arch::wasm32::unreachable();
    }
    let data = arr_data(obj);
    let mut acc = unsafe { load_i32(data) };
    for i in 1..total {
        let x = unsafe { load_i32(data + i * 4) };
        if (want_max != 0 && x > acc) || (want_max == 0 && x < acc) {
            acc = x;
        }
    }
    acc
}

/// `min(a)`/`max(a)` over a Real array (see `rt_array_extreme_i32`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_extreme_f64(obj: u32, want_max: i32) -> f64 {
    let total = rt_array_total(obj);
    if total == 0 {
        core::arch::wasm32::unreachable();
    }
    let data = arr_data(obj);
    let mut acc = unsafe { load_f64(data) };
    for i in 1..total {
        let x = unsafe { load_f64(data + i * 8) };
        if (want_max != 0 && x > acc) || (want_max == 0 && x < acc) {
            acc = x;
        }
    }
    acc
}

// ---------------------------------------------------------------------------
// Element-wise array arithmetic (numeric: Integer in i32, Real in f64)
// ---------------------------------------------------------------------------
//
// `op`: 0 add, 1 sub, 2 mul, 3 div. These produce a *fresh* array with the same
// kind/dimensions as the (first) array operand; the codegen releases the
// operand arrays afterwards. Used for `a .+ b` / `a + b` (`ADD_ARR` …), scalar
// broadcast (`a * s`, `s - a`, …) and unary negation.

const OP_ADD: u32 = 0;
const OP_SUB: u32 = 1;
const OP_MUL: u32 = 2;
const OP_DIV: u32 = 3;
const OP_POW: u32 = 4;
const OP_AND: u32 = 5;
const OP_OR: u32 = 6;

fn ew_i32(x: i32, y: i32, op: u32) -> i32 {
    match op {
        OP_ADD => x.wrapping_add(y),
        OP_SUB => x.wrapping_sub(y),
        OP_MUL => x.wrapping_mul(y),
        OP_POW => libm::pow(x as f64, y as f64) as i32,
        OP_AND => x & y,
        OP_OR => x | y,
        _ => {
            if y == 0 {
                core::arch::wasm32::unreachable();
            }
            x.wrapping_div(y)
        }
    }
}

fn ew_f64(x: f64, y: f64, op: u32) -> f64 {
    match op {
        OP_ADD => x + y,
        OP_SUB => x - y,
        OP_MUL => x * y,
        OP_DIV => x / y,
        _ => libm::pow(x, y),
    }
}

/// A fresh array with the same kind and dimensions as `obj`, zeroed data.
fn array_like(obj: u32) -> u32 {
    let kind = unsafe { load_u32(obj + ARR_KIND_OFF) };
    let ndims = rt_array_ndims(obj);
    let res = rt_array_new(kind, ndims, rt_array_total(obj));
    for axis in 0..ndims {
        unsafe { store_u32(res + ARR_DIMS_OFF + axis * 4, load_u32(obj + ARR_DIMS_OFF + axis * 4)) };
    }
    res
}

/// `a op b` element-wise (i32 elements), `a` and `b` the same shape.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_ew_i32(a: u32, b: u32, op: u32) -> u32 {
    let res = array_like(a);
    let (da, db, dr) = (arr_data(a), arr_data(b), arr_data(res));
    for i in 0..rt_array_total(a) {
        let v = ew_i32(unsafe { load_i32(da + i * 4) }, unsafe { load_i32(db + i * 4) }, op);
        unsafe { store_u32(dr + i * 4, v as u32) };
    }
    res
}

/// `a op b` element-wise (f64 elements).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_ew_f64(a: u32, b: u32, op: u32) -> u32 {
    let res = array_like(a);
    let (da, db, dr) = (arr_data(a), arr_data(b), arr_data(res));
    for i in 0..rt_array_total(a) {
        let v = ew_f64(unsafe { load_f64(da + i * 8) }, unsafe { load_f64(db + i * 8) }, op);
        unsafe { store_f64(dr + i * 8, v) };
    }
    res
}

/// Broadcast a scalar over an i32-element array: `rev ? (s op a[i]) : (a[i] op s)`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_scalar_i32(a: u32, s: i32, op: u32, rev: u32) -> u32 {
    let res = array_like(a);
    let (da, dr) = (arr_data(a), arr_data(res));
    for i in 0..rt_array_total(a) {
        let x = unsafe { load_i32(da + i * 4) };
        let v = if rev != 0 { ew_i32(s, x, op) } else { ew_i32(x, s, op) };
        unsafe { store_u32(dr + i * 4, v as u32) };
    }
    res
}

/// Broadcast a scalar over an f64-element array.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_scalar_f64(a: u32, s: f64, op: u32, rev: u32) -> u32 {
    let res = array_like(a);
    let (da, dr) = (arr_data(a), arr_data(res));
    for i in 0..rt_array_total(a) {
        let x = unsafe { load_f64(da + i * 8) };
        let v = if rev != 0 { ew_f64(s, x, op) } else { ew_f64(x, s, op) };
        unsafe { store_f64(dr + i * 8, v) };
    }
    res
}

/// Negate every element of an i32-element array.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_neg_i32(a: u32) -> u32 {
    let res = array_like(a);
    let (da, dr) = (arr_data(a), arr_data(res));
    for i in 0..rt_array_total(a) {
        unsafe { store_u32(dr + i * 4, (load_i32(da + i * 4)).wrapping_neg() as u32) };
    }
    res
}

/// Logical `not` of every Boolean element (element-wise `x == 0`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_not_i32(a: u32) -> u32 {
    let res = array_like(a);
    let (da, dr) = (arr_data(a), arr_data(res));
    for i in 0..rt_array_total(a) {
        unsafe { store_u32(dr + i * 4, (load_i32(da + i * 4) == 0) as u32) };
    }
    res
}

/// Negate every element of an f64-element array.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_neg_f64(a: u32) -> u32 {
    let res = array_like(a);
    let (da, dr) = (arr_data(a), arr_data(res));
    for i in 0..rt_array_total(a) {
        unsafe { store_f64(dr + i * 8, -load_f64(da + i * 8)) };
    }
    res
}

/// `transpose(a)` of a 2-D array: a fresh `n x m` array with `res[j,i] = a[i,j]`.
/// Heap elements (string/array/record) are value-copied (retain/deep-copy) so
/// the result shares no mutable storage with `a`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_transpose(a: u32) -> u32 {
    if rt_array_ndims(a) != 2 {
        core::arch::wasm32::unreachable();
    }
    let m = rt_array_dim(a, 1);
    let n = rt_array_dim(a, 2);
    let kind = unsafe { load_u32(a + ARR_KIND_OFF) };
    let stride = elem_stride(kind);
    let res = rt_array_new(kind, 2, m * n);
    rt_array_set_dim(res, 0, n);
    rt_array_set_dim(res, 1, m);
    let (sd, rd) = (arr_data(a), arr_data(res));
    for i in 0..m {
        for j in 0..n {
            unsafe {
                core::ptr::copy_nonoverlapping(
                    (sd + (i * n + j) * stride) as *const u8,
                    (rd + (j * m + i) * stride) as *mut u8,
                    stride as usize,
                );
            }
        }
    }
    // Value semantics: copy the (now byte-shared) heap-element handles.
    if kind == EK_STR || kind == EK_ARRAY || kind == EK_RECORD {
        for idx in 0..m * n {
            let copied = copy_kind(kind, unsafe { load_u32(rd + idx * 4) });
            unsafe { store_u32(rd + idx * 4, copied) };
        }
    }
    res
}

/// `identity(n)`: the `n x n` Integer identity matrix (1 on the diagonal, 0
/// elsewhere — the rest is left zero by `rt_array_new`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_identity(n: u32) -> u32 {
    let res = rt_array_new(EK_INT, 2, n * n);
    rt_array_set_dim(res, 0, n);
    rt_array_set_dim(res, 1, n);
    let d = arr_data(res);
    for i in 0..n {
        unsafe { store_u32(d + (i * n + i) * 4, 1) };
    }
    res
}

/// `diagonal(v)`: the `n x n` matrix with vector `v` (length `n`) on the diagonal
/// and zeros elsewhere. Same element kind as `v`; heap diagonal entries are
/// value-copied.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_diagonal(v: u32) -> u32 {
    let kind = unsafe { load_u32(v + ARR_KIND_OFF) };
    let stride = elem_stride(kind);
    let n = rt_array_total(v);
    let res = rt_array_new(kind, 2, n * n);
    rt_array_set_dim(res, 0, n);
    rt_array_set_dim(res, 1, n);
    let (sv, dv) = (arr_data(v), arr_data(res));
    for i in 0..n {
        let dst = dv + (i * n + i) * stride;
        unsafe { core::ptr::copy_nonoverlapping((sv + i * stride) as *const u8, dst as *mut u8, stride as usize) };
        if kind == EK_STR || kind == EK_ARRAY || kind == EK_RECORD {
            let copied = copy_kind(kind, unsafe { load_u32(dst) });
            unsafe { store_u32(dst, copied) };
        }
    }
    res
}

/// `linspace(x1, x2, n)`: a Real vector of `n` points evenly spaced from `x1` to
/// `x2` inclusive (`x1 + (x2-x1)*i/(n-1)`). For `n == 1` the single point is `x1`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_array_linspace(x1: f64, x2: f64, n: u32) -> u32 {
    let res = rt_array_new(EK_REAL, 1, n);
    rt_array_set_dim(res, 0, n);
    let d = arr_data(res);
    for i in 0..n {
        let v = if n <= 1 { x1 } else { x1 + (x2 - x1) * (i as f64) / ((n - 1) as f64) };
        unsafe { store_f64(d + i * 8, v) };
    }
    res
}

// ---------------------------------------------------------------------------
// Strings
// ---------------------------------------------------------------------------

const STR_LEN_OFF: u32 = 4;
const STR_DATA_OFF: u32 = 8;

/// Allocate an uninitialized `String` object of `len` bytes (refcount 1, length
/// set). The caller fills `rt_str_data(obj)..+len` with the bytes.
#[unsafe(no_mangle)]
pub extern "C" fn rt_str_new(len: u32) -> u32 {
    let obj = rt_alloc(STR_DATA_OFF + len);
    unsafe {
        store_u32(obj, 1); // refcount
        store_u32(obj + STR_LEN_OFF, len);
    }
    obj
}

/// Byte length of a string.
#[unsafe(no_mangle)]
pub extern "C" fn rt_str_len(obj: u32) -> u32 {
    unsafe { load_u32(obj + STR_LEN_OFF) }
}

/// Pointer to a string's UTF-8 bytes (lets generated/host code load/store
/// directly without per-byte calls).
#[unsafe(no_mangle)]
pub extern "C" fn rt_str_data(obj: u32) -> u32 {
    obj + STR_DATA_OFF
}

/// View a string object's bytes as a slice.
unsafe fn str_bytes<'a>(obj: u32) -> &'a [u8] {
    let len = rt_str_len(obj) as usize;
    unsafe { core::slice::from_raw_parts((obj + STR_DATA_OFF) as *const u8, len) }
}

/// Allocate a `String` object holding `s` and return its pointer.
fn new_str_from(s: &str) -> u32 {
    let bytes = s.as_bytes();
    let obj = rt_str_new(bytes.len() as u32);
    unsafe {
        core::ptr::copy_nonoverlapping(bytes.as_ptr(), rt_str_data(obj) as *mut u8, bytes.len());
    }
    obj
}

/// `stringAppend(a, b)` — concatenate two strings into a fresh one.
#[unsafe(no_mangle)]
pub extern "C" fn rt_concat(a: u32, b: u32) -> u32 {
    let la = rt_str_len(a);
    let lb = rt_str_len(b);
    let obj = rt_str_new(la + lb);
    unsafe {
        let dst = rt_str_data(obj) as *mut u8;
        core::ptr::copy_nonoverlapping(rt_str_data(a) as *const u8, dst, la as usize);
        core::ptr::copy_nonoverlapping(rt_str_data(b) as *const u8, dst.add(la as usize), lb as usize);
    }
    obj
}

/// `stringEqual(a, b)` → 1 / 0.
#[unsafe(no_mangle)]
pub extern "C" fn rt_streq(a: u32, b: u32) -> i32 {
    (unsafe { str_bytes(a) == str_bytes(b) }) as i32
}

/// `stringCompare(a, b)` → -1 / 0 / 1 (lexicographic over bytes).
#[unsafe(no_mangle)]
pub extern "C" fn rt_strcmp(a: u32, b: u32) -> i32 {
    use core::cmp::Ordering::*;
    match unsafe { str_bytes(a).cmp(str_bytes(b)) } {
        Less => -1,
        Equal => 0,
        Greater => 1,
    }
}

/// `substring(s, i, j)` — 1-based inclusive `[i, j]`. A bad range traps (→
/// META_FAIL), matching the bounds check in the canonical builtin.
#[unsafe(no_mangle)]
pub extern "C" fn rt_substring(obj: u32, i: i32, j: i32) -> u32 {
    let len = rt_str_len(obj) as i32;
    if i < 1 || j > len || i > j + 1 {
        core::arch::wasm32::unreachable();
    }
    let start = (i - 1) as usize;
    let count = (j - i + 1) as usize;
    let out = rt_str_new(count as u32);
    unsafe {
        core::ptr::copy_nonoverlapping(
            (rt_str_data(obj) as *const u8).add(start),
            rt_str_data(out) as *mut u8,
            count,
        );
    }
    out
}

/// `String(i)` for an Integer.
#[unsafe(no_mangle)]
pub extern "C" fn rt_int_string(i: i32) -> u32 {
    new_str_from(&format!("{i}"))
}

/// `String(b)` for a Boolean.
#[unsafe(no_mangle)]
pub extern "C" fn rt_bool_string(b: i32) -> u32 {
    new_str_from(if b != 0 { "true" } else { "false" })
}

/// `String(r)` for a Real — byte-identical to `metamodelica::realString` and the
/// C target (`ryu_to_hr` below is the same algorithm).
#[unsafe(no_mangle)]
pub extern "C" fn rt_real_string(r: f64) -> u32 {
    if r.is_infinite() {
        return new_str_from(if r < 0.0 { "-inf" } else { "inf" });
    }
    if r.is_nan() {
        return new_str_from("NaN");
    }
    new_str_from(&ryu_to_hr(&format!("{r:e}"), true))
}

/// `String(r, significantDigits, minimumLength, leftJustified)` for a Real.
///
/// The frontend always expands `String(Real)` to this 4-argument form (defaults
/// `significantDigits = 6`, `minimumLength = 0`, `leftJustified = true`), and
/// `Ceval.cevalBuiltinString` evaluates it as the C `printf` conversion
/// `"%[-]{minimumLength}.{significantDigits}g"`. This must therefore match C's
/// `%g` (NOT the shortest-round-trip `rt_real_string`/`realString`). The `%g`
/// rendering and the trailing-zero trimming below mirror
/// `openmodelica_util::System::c_format_double` exactly so the wasm-jit target,
/// the Ceval interpreter and the C target all agree byte-for-byte.
#[unsafe(no_mangle)]
pub extern "C" fn rt_real_format(r: f64, sig: i32, min_len: i32, left_just: i32) -> u32 {
    // C `%g` treats a precision of 0 as 1; the default is 6. `significantDigits`
    // is always supplied here, so a non-positive value is the only edge case.
    let p = if sig < 1 { 1 } else { sig as usize };
    let body = format_g(r, p);
    new_str_from(&pad(&body, min_len, left_just != 0))
}

/// A parsed Modelica printf-style format directive (`String(value, format)`).
/// Mirrors `modelica_string_format_to_c_string_format` in the C runtime.
struct FmtSpec {
    minus: bool, // '-' left-justify
    zero: bool,  // '0' zero-pad
    plus: bool,  // '+' always show sign
    space: bool, // ' ' leading space for non-negative
    hash: bool,  // '#' alternate form
    width: u32,
    prec: Option<u32>,
    conv: u8,
}

/// Parse a Modelica format directive (the body after the implicit leading `%`)
/// into a [`FmtSpec`], mirroring `modelica_string_format_to_c_string_format`:
/// flags, optional width, optional `.precision`, then a single conversion
/// specifier. Returns `None` for an unparseable directive (length modifiers,
/// unknown specifier, trailing data) — the caller traps, matching the C
/// runtime's `omc_assert`.
fn parse_modelica_format(bytes: &[u8]) -> Option<FmtSpec> {
    let mut spec = FmtSpec {
        minus: false, zero: false, plus: false, space: false, hash: false,
        width: 0, prec: None, conv: 0,
    };
    let mut i = 0;
    // Flags.
    while i < bytes.len() {
        match bytes[i] {
            b'#' => spec.hash = true,
            b'0' => spec.zero = true,
            b'-' => spec.minus = true,
            b' ' => spec.space = true,
            b'+' => spec.plus = true,
            _ => break,
        }
        i += 1;
    }
    // Width (digits).
    while i < bytes.len() && bytes[i].is_ascii_digit() {
        spec.width = spec.width * 10 + (bytes[i] - b'0') as u32;
        i += 1;
    }
    // Precision (`.` then digits; `.` with no digits means 0).
    if i < bytes.len() && bytes[i] == b'.' {
        i += 1;
        let mut p = 0u32;
        while i < bytes.len() && bytes[i].is_ascii_digit() {
            p = p * 10 + (bytes[i] - b'0') as u32;
            i += 1;
        }
        spec.prec = Some(p);
    }
    // Conversion specifier (single character; length modifiers are rejected, as
    // in the C runtime).
    if i >= bytes.len() {
        return None;
    }
    let conv = bytes[i];
    match conv {
        b'f' | b'e' | b'E' | b'g' | b'G' | b'c' | b'd' | b'i' | b'o' | b'x' | b'X' | b'u' => {}
        _ => return None, // length modifier / unknown specifier
    }
    spec.conv = conv;
    i += 1;
    // No trailing data after the directive.
    if i != bytes.len() {
        return None;
    }
    Some(spec)
}

/// Apply a [`FmtSpec`]'s sign flag and field width to an already-rendered numeric
/// `body` (which carries a leading `-` only for a negative value, as produced by
/// Rust's float/int formatting). Matches C printf field padding: `-` left-
/// justifies, `0` zero-pads after the sign, otherwise space-pads on the left.
fn apply_sign_width(mut body: String, spec: &FmtSpec) -> String {
    // Sign: a non-negative value gets '+' or ' ' if requested.
    if !body.starts_with('-') {
        if spec.plus {
            body.insert(0, '+');
        } else if spec.space {
            body.insert(0, ' ');
        }
    }
    let len = body.len() as u32;
    if len >= spec.width {
        return body;
    }
    let fill = (spec.width - len) as usize;
    if spec.minus {
        // Left-justify: trailing spaces.
        let mut s = body;
        s.push_str(&" ".repeat(fill));
        s
    } else if spec.zero {
        // Zero-pad after any sign character.
        let sign_len = body.bytes().next().map_or(0, |c| {
            if c == b'-' || c == b'+' || c == b' ' { 1 } else { 0 }
        });
        let (sign, rest) = body.split_at(sign_len);
        format!("{sign}{}{rest}", "0".repeat(fill))
    } else {
        // Right-justify: leading spaces.
        format!("{}{body}", " ".repeat(fill))
    }
}

/// Render a double for a floating conversion (`f e E g G`) per `spec`, returning
/// the numeric body (leading `-` only for a negative value; sign/width applied by
/// the caller). Traps on a non-floating specifier or the unimplemented `#` flag.
fn format_float_body(r: f64, spec: &FmtSpec) -> String {
    // Alternate form (`#`) changes trailing-zero / decimal-point behavior; not
    // yet replicated. No in-scope model uses it; trap rather than mis-format.
    if spec.hash {
        core::arch::wasm32::unreachable()
    }
    match spec.conv {
        b'f' | b'F' => {
            let p = spec.prec.unwrap_or(6) as usize;
            format!("{r:.p$}")
        }
        b'e' | b'E' => {
            let p = spec.prec.unwrap_or(6) as usize;
            let s = format_c_exp(r, p);
            if spec.conv == b'E' { s.replace('e', "E") } else { s }
        }
        b'g' | b'G' => {
            // %g precision is significant digits (0 is treated as 1), default 6.
            let p = spec.prec.unwrap_or(6).max(1) as usize;
            let s = format_g(r, p);
            if spec.conv == b'G' { s.replace('e', "E") } else { s }
        }
        // Non-floating specifier for a Real value: the C runtime asserts.
        _ => core::arch::wasm32::unreachable(),
    }
}

/// `String(Real, format)` — the format-string variant. `fmt` is a (borrowed)
/// Modelica printf directive; only the floating conversions `f e E g G` are
/// valid for a Real (others trap, as the C runtime's
/// `modelica_real_to_modelica_string_format` asserts). Mirrors that function:
/// parse the directive, render the double, apply sign/width.
#[unsafe(no_mangle)]
pub extern "C" fn rt_string_format_real(r: f64, fmt: u32) -> u32 {
    let spec = match parse_modelica_format(unsafe { str_bytes(fmt) }) {
        Some(s) => s,
        None => core::arch::wasm32::unreachable(),
    };
    let body = format_float_body(r, &spec);
    new_str_from(&apply_sign_width(body, &spec))
}

/// `String(Integer, format)` — the integer format-string variant. Mirrors the C
/// runtime's `modelica_integer_to_modelica_string_format`: a floating specifier
/// renders the value as a double; `c d i` render a signed value; `o x X u`
/// render the (sign-extended, as C does) value in the given radix. Integer
/// precision is the minimum digit count (zero-padded), as in C printf.
#[unsafe(no_mangle)]
pub extern "C" fn rt_string_format_int(i: i32, fmt: u32) -> u32 {
    let spec = match parse_modelica_format(unsafe { str_bytes(fmt) }) {
        Some(s) => s,
        None => core::arch::wasm32::unreachable(),
    };
    match spec.conv {
        b'f' | b'F' | b'e' | b'E' | b'g' | b'G' => {
            let body = format_float_body(i as f64, &spec);
            new_str_from(&apply_sign_width(body, &spec))
        }
        b'c' => {
            // Character conversion: the byte with code `i`.
            let mut s = String::new();
            s.push((i as u8) as char);
            new_str_from(&apply_sign_width(s, &spec))
        }
        b'd' | b'i' => {
            let neg = i < 0;
            let mut digits = format!("{}", (i as i64).unsigned_abs());
            if let Some(p) = spec.prec {
                while (digits.len() as u32) < p {
                    digits.insert(0, '0');
                }
            }
            let body = if neg { format!("-{digits}") } else { digits };
            new_str_from(&apply_sign_width(body, &effective_int_spec(&spec)))
        }
        b'o' | b'x' | b'X' | b'u' => {
            // C casts to (unsigned long); replicate the sign extension.
            let u = (i as i64) as u64;
            let mut digits = match spec.conv {
                b'o' => format!("{u:o}"),
                b'x' => format!("{u:x}"),
                b'X' => format!("{u:X}"),
                _ => format!("{u}"),
            };
            if let Some(p) = spec.prec {
                while (digits.len() as u32) < p {
                    digits.insert(0, '0');
                }
            }
            new_str_from(&apply_sign_width(digits, &effective_int_spec(&spec)))
        }
        _ => core::arch::wasm32::unreachable(),
    }
}

/// A copy of `spec` with the `0` (zero-pad) flag cleared when a precision is
/// present — C printf ignores `0` for integer conversions with an explicit
/// precision (the precision already zero-pads the digits).
fn effective_int_spec(spec: &FmtSpec) -> FmtSpec {
    FmtSpec {
        minus: spec.minus,
        zero: spec.zero && spec.prec.is_none(),
        plus: spec.plus,
        space: spec.space,
        hash: spec.hash,
        width: spec.width,
        prec: spec.prec,
        conv: spec.conv,
    }
}

/// Pad a string to `min_len` bytes with spaces (`leftJustified` → trailing,
/// otherwise leading), used by `String(Integer/Boolean/Enumeration, minLength,
/// leftJustified)`. Mirrors `ExpressionSimplify.cevalBuiltinStringFormat`:
/// strings already at least `min_len` long are returned unchanged.
#[unsafe(no_mangle)]
pub extern "C" fn rt_str_pad(obj: u32, min_len: i32, left_just: i32) -> u32 {
    let s = core::str::from_utf8(unsafe { str_bytes(obj) }).unwrap_or("");
    new_str_from(&pad(s, min_len, left_just != 0))
}

/// Space-pad `s` to `min_len` bytes (no-op if already long enough). Shared by
/// `rt_real_format` (printf width field) and `rt_str_pad`.
fn pad(s: &str, min_len: i32, left_just: bool) -> String {
    let len = s.len() as i32;
    if len >= min_len {
        return String::from(s);
    }
    let fill = (min_len - len) as usize;
    let spaces = " ".repeat(fill);
    if left_just { format!("{s}{spaces}") } else { format!("{spaces}{s}") }
}

/// C `%.{p}g` of `val` (`p` significant digits, `p >= 1`), with trailing zeros
/// trimmed. Faithful port of the `'g'` arm of
/// `openmodelica_util::System::c_format_double` (kept identical so all targets
/// agree): the `%e`-style decimal exponent `x` selects the presentation — `%f`
/// when `-4 <= x < p`, otherwise `%e` — then a trailing-zero/point trim.
fn format_g(val: f64, p: usize) -> String {
    let x = decimal_exponent(val, p);
    let s = if x >= -4 && (x as i64) < p as i64 {
        let prec = (p as i32 - 1 - x).max(0) as usize;
        format!("{val:.prec$}")
    } else {
        format_c_exp(val, p - 1)
    };
    trim_g_significand(s)
}

/// Decimal exponent `X` that C's `%e` conversion of `val` would use at `sig`
/// significant digits (rounding can carry into a higher exponent, e.g. 9.99 at
/// 2 sig digits → "1.0e1", X = 1). Mirrors `System::decimal_exponent`.
fn decimal_exponent(val: f64, sig: usize) -> i32 {
    if val == 0.0 || !val.is_finite() {
        return 0;
    }
    let raw = format!("{:.*e}", sig.saturating_sub(1), val);
    raw.split_once('e').and_then(|(_, e)| e.parse().ok()).unwrap_or(0)
}

/// C `%e` rendering: mantissa, `e`, explicit sign, at-least-two-digit exponent
/// (Rust's `{:e}` omits the sign and zero-padding). Mirrors `System::format_c_exp`.
fn format_c_exp(val: f64, precision: usize) -> String {
    let raw = format!("{:.*e}", precision, val);
    let (mant, exp) = raw.split_once('e').unwrap_or((raw.as_str(), "0"));
    let exp_num: i32 = exp.parse().unwrap_or(0);
    let sign = if exp_num < 0 { '-' } else { '+' };
    format!("{mant}e{sign}{:02}", exp_num.abs())
}

/// Strip trailing zeros (and a dangling decimal point) from a `%g` significand,
/// leaving any exponent suffix intact. Mirrors `System::trim_g_significand`.
fn trim_g_significand(s: String) -> String {
    let (mant, exp) = match s.find(['e', 'E']) {
        Some(idx) => (&s[..idx], &s[idx..]),
        None => (s.as_str(), ""),
    };
    let mant = if mant.contains('.') {
        mant.trim_end_matches('0').trim_end_matches('.')
    } else {
        mant
    };
    format!("{mant}{exp}")
}

/// Port of `ryu_to_hr` from `3rdParty/ryu/ryu/om_format.c` (and
/// `metamodelica::ryu_to_hr`): convert a shortest-form scientific representation
/// (`8.13e2`) to the minimal decimal / exponential rendering omc uses for Reals.
/// `real_output` adds a trailing `.0` to round values. Kept identical to the
/// `metamodelica` copy so `String(Real)` matches everywhere.
fn ryu_to_hr(d2s_str: &str, real_output: bool) -> String {
    let Some(epos) = d2s_str.find(['e', 'E']) else {
        return d2s_str.replace('E', "e");
    };
    let mant_str = &d2s_str[..epos];
    let mut exp: i32 = d2s_str[epos + 1..].parse().unwrap_or(0);
    let (neg, mut digits) = match mant_str.strip_prefix('-') {
        Some(m) => (true, String::from(m)),
        None => (false, String::from(mant_str)),
    };
    let mut ndec: i32 = if digits.contains('.') { digits.len() as i32 - 2 } else { 0 };
    let mut exp_repr: String = d2s_str.replace('E', "e");

    if ndec > 12 && !real_output {
        let mant: f64 = digits.parse().unwrap_or(0.0);
        let mut rounded = format!("{mant:.12}");
        if rounded == "10.000000000000" {
            rounded = String::from("1.000000000000");
            exp += 1;
        }
        let mut nz = 0;
        while rounded.ends_with('0') {
            rounded.pop();
            nz += 1;
        }
        if rounded.ends_with('.') {
            rounded.pop();
        }
        if nz > 3 {
            digits = rounded;
            ndec = if digits.contains('.') { digits.len() as i32 - 2 } else { 0 };
            exp_repr = format!("{}{digits}e{exp}", if neg { "-" } else { "" });
        }
    }

    if !(-3..=5).contains(&exp) || (exp > 0 && exp - ndec > 3) {
        return exp_repr;
    }

    let digs: alloc::vec::Vec<char> = digits.chars().filter(|c| *c != '.').collect();
    let mut out = String::with_capacity(24);
    if neg {
        out.push('-');
    }
    if exp == 0 {
        out.push_str(&digits);
    } else if exp > 0 {
        out.push(digs[0]);
        let take = ndec.min(exp) as usize;
        out.extend(&digs[1..1 + take]);
        if exp > ndec {
            for _ in 0..(exp - ndec) {
                out.push('0');
            }
        } else if exp < ndec {
            out.push('.');
            out.extend(&digs[1 + take..]);
        }
    } else {
        out.push_str("0.");
        for _ in 0..(-exp - 1) {
            out.push('0');
        }
        out.extend(&digs);
    }
    if exp >= ndec && real_output {
        out.push_str(".0");
    }
    out
}

// ---------------------------------------------------------------------------
// Simulation primitives (wasm-jit simulation target)
//
// All model state lives in one `SimData` block (allocated with `rt_alloc`) of
// contiguous little-endian f64 slots, laid out as:
//
//   [ time | states[nStates] | ders[nStates] | algs[nAlgs] | params[nParams] ]
//
// `time` is at offset 0, `states` at offset 8, `ders` at `8 + 8*nStates`, etc.
// Every offset is a compile-time constant in the generated model module, which
// receives the block pointer as a function argument and accesses a variable
// with a single `f64.load`/`f64.store` at a constant offset. The runtime only
// needs the two operations that loop over the (runtime-sized) state vector:
// the integrator step and the per-step result copy.
//
// A result-buffer row is exactly the time-variant prefix
// `[ time | states | ders | algs ]` (`n_reals = 1 + 2*nStates + nAlgs` f64),
// so emitting a row is a copy of the first `n_reals` f64 of the block. The
// parameters tail is written once (after initialization) by the host.
// ---------------------------------------------------------------------------

/// Forward-Euler update of the state vector in place: `state[i] += h * der[i]`
/// for `i in 0..n_states`. States start at `sim_data + 8`, derivatives at
/// `sim_data + 8 + 8*n_states`.
#[unsafe(no_mangle)]
pub extern "C" fn rt_euler_step(sim_data: u32, n_states: u32, h: f64) {
    let states = sim_data + 8;
    let ders = states + n_states * 8;
    for i in 0..n_states {
        unsafe {
            let s = load_f64(states + i * 8);
            let d = load_f64(ders + i * 8);
            store_f64(states + i * 8, s + h * d);
        }
    }
}

/// Copy one time-variant result row — the `n_reals` (= `1 + 2*nStates + nAlgs`)
/// f64 prefix of `SimData` — into the result buffer `buf` at row `row`
/// (row-major: row `r` occupies `buf[r*n_reals .. (r+1)*n_reals]`).
#[unsafe(no_mangle)]
pub extern "C" fn rt_sim_store_row(buf: u32, row: u32, sim_data: u32, n_reals: u32) {
    let dst = buf + row * n_reals * 8;
    for i in 0..n_reals {
        unsafe { store_f64(dst + i * 8, load_f64(sim_data + i * 8)) };
    }
}

// ---------------------------------------------------------------------------
// Dense linear solve (LU with partial pivoting), used by `SES_LINEAR` and,
// later, the `Modelica.Math.Matrices.*` LAPACK externals. Backed by `nalgebra`
// (no_std, dlmalloc-backed `alloc`, `libm` floats) so the solve stays in-wasm —
// no per-step host boundary crossing. LU with partial pivoting is the same
// algorithm class as LAPACK's `dgesv`, so results track the C target closely.
// ---------------------------------------------------------------------------

/// Solve the dense `n`×`n` system `A x = b` in place: `A` is `a_ptr` as `n*n`
/// f64 in **column-major** order, `b` is `b_ptr` as `n` f64. On success the
/// solution overwrites `b` (`b ← x`) and 0 is returned; on a singular/failed
/// factorization `b` is left unchanged and 1 is returned.
#[unsafe(no_mangle)]
pub extern "C" fn rt_linsolve(a_ptr: u32, b_ptr: u32, n: u32) -> i32 {
    use nalgebra::{DMatrix, DVector};
    let n = n as usize;
    let a = unsafe { core::slice::from_raw_parts(a_ptr as *const f64, n * n) };
    let b = unsafe { core::slice::from_raw_parts(b_ptr as *const f64, n) };
    let am = DMatrix::<f64>::from_column_slice(n, n, a);
    let bv = DVector::<f64>::from_column_slice(b);
    match am.lu().solve(&bv) {
        Some(x) => {
            let out = unsafe { core::slice::from_raw_parts_mut(b_ptr as *mut f64, n) };
            out.copy_from_slice(x.as_slice());
            0
        }
        None => 1,
    }
}
