//! In-memory model-instance references (issue #15219) — Rust port of
//! `runtime/ModelInstanceReference_omc.c`, plus an in-process JSON walker.
//!
//! `NFApi.getModelInstanceReference` / `getModelInstanceAnnotationReference`
//! build the same MetaModelica `JSON` structure as the non-reference variants
//! but, instead of serialising it to a string, store the (boxed) value here and
//! return a 1-based integer handle. OMEdit links the compiler in-process (via
//! `libOpenModelicaCompiler.so`), so it fetches the stored value with
//! [`ModelInstanceReference_get`] and walks it directly with the `omc_json_*`
//! accessors below — avoiding both JSON string generation here and JSON string
//! parsing in OMEdit, which for large models takes seconds.
//!
//! ## Memory & lifetime
//! Each occupied slot holds an owning `Arc<JSON>`, so the stored tree stays
//! alive (independent of the cycle collector — JSON trees are acyclic and an
//! `Arc` in this process-global table is a root) until the handle is released.
//! The raw `*const JSON` returned by [`ModelInstanceReference_get`] and the
//! `*const JSON` element pointers handed out by the walker therefore remain
//! valid until the corresponding [`ModelInstanceReference_release`]. The values
//! are immutable, so the pointers may be walked without holding any lock.
//!
//! ## Threading
//! `store` runs on the compiler eval thread; OMEdit's `get`/walk/`release` run
//! on its calling thread — the same thread in the in-process embedding, exactly
//! as the C runtime assumed. The table mutex guards only the slot array; the
//! contract is that a handle is not released while it is being walked.

use std::cell::RefCell;
use std::ffi::{c_char, c_double, c_int};
use std::ptr;
use std::sync::Arc;

use metamodelica::List;
use openmodelica_util::JSON::JSON;

/// Number of live references, matching `MODEL_INSTANCE_REFERENCE_MAX` in the C
/// runtime. OMEdit fetches and releases each handle promptly, so a small fixed
/// table suffices.
const MAX: usize = 256;

// Per-thread slot array. The C runtime used a process-global static (single
// threaded, conservatively GC-scanned); the port instead keys on the thread
// because (a) `JSON` is not `Send`/`Sync` — its `OBJECT` variant holds the
// hash/eq closures of an `UnorderedMap` — so it cannot live in a `Sync` static,
// and (b) the in-process embedding contract already requires `store` and the
// OMEdit-side `get`/walk/`release` to run on the *same* thread (see `capi`). A
// handle reaching a different thread simply finds an empty table and yields a
// null pointer, letting OMEdit fall back to the JSON-string path. Each occupied
// slot owns its tree, keeping it alive (the `Arc` is a root, independent of the
// cycle collector) until released.
thread_local! {
    static TABLE: RefCell<[Option<Arc<JSON>>; MAX]> = RefCell::new([const { None }; MAX]);
}

/// Store a boxed JSON value and return a 1-based handle, or 0 if no slot is
/// free. Called from MetaModelica (`NFApi.storeModelInstanceReference`) via
/// [`crate::external_c_calls::external_c_impl_path`]; signature mirrors the
/// MetaModelica wrapper (`input JSON; output Integer`).
pub fn store(json: Arc<JSON>) -> i32 {
    TABLE.with_borrow_mut(|tbl| {
        for (i, slot) in tbl.iter_mut().enumerate() {
            if slot.is_none() {
                *slot = Some(json);
                return (i + 1) as i32;
            }
        }
        0 /* no free slot */
    })
}

/// Release a handle previously returned by [`store`]. Returns `true` on success,
/// `false` for an invalid handle. Called from MetaModelica
/// (`NFApi.releaseModelInstanceReferenceImpl`).
pub fn release(handle: i32) -> bool {
    let i = handle - 1;
    if i < 0 || i as usize >= MAX {
        return false;
    }
    TABLE.with_borrow_mut(|tbl| {
        if tbl[i as usize].is_none() {
            return false;
        }
        tbl[i as usize] = None;
        true
    })
}

// ───────────────────────────── C ABI for OMEdit ──────────────────────────────

/// Returns a borrowed pointer to the stored JSON value for `handle`, or null for
/// an invalid handle. The value is kept alive by its table slot until
/// [`ModelInstanceReference_release`]; OMEdit must finish walking before
/// releasing. Called directly as a C symbol from OMEdit.
#[unsafe(no_mangle)]
pub extern "C" fn ModelInstanceReference_get(handle: c_int) -> *const JSON {
    let i = handle - 1;
    if i < 0 || i as usize >= MAX {
        return ptr::null();
    }
    TABLE.with_borrow(|tbl| match &tbl[i as usize] {
        // The slot keeps the `Arc` alive after this borrow ends, so the pointee
        // outlives it (until the matching release).
        Some(arc) => Arc::as_ptr(arc),
        None => ptr::null(),
    })
}

/// Release a handle. Returns 1 on success, 0 for an invalid handle. The C
/// runtime exposed this symbol both to MetaModelica and to OMEdit; here OMEdit
/// is the direct C caller (MetaModelica goes through [`release`]).
#[unsafe(no_mangle)]
pub extern "C" fn ModelInstanceReference_release(handle: c_int) -> c_int {
    if release(handle) { 1 } else { 0 }
}

// JSON node kinds, kept in sync with the `OmcJsonKind` enum in the C header
// (OpenModelicaScriptingAPIQtABI.h / the rust-ABI replacement header).
const KIND_OBJECT: c_int = 0;
const KIND_LIST_OBJECT: c_int = 1;
const KIND_ARRAY: c_int = 2;
const KIND_LIST: c_int = 3;
const KIND_STRING: c_int = 4;
const KIND_INTEGER: c_int = 5;
const KIND_NUMBER: c_int = 6;
const KIND_TRUE: c_int = 7;
const KIND_FALSE: c_int = 8;
const KIND_NULL: c_int = 9;

/// Discriminant of a JSON node, or -1 for a null pointer. `node` must be a
/// pointer obtained from [`ModelInstanceReference_get`] or a walker accessor.
#[unsafe(no_mangle)]
pub extern "C" fn omc_json_kind(node: *const JSON) -> c_int {
    if node.is_null() {
        return -1;
    }
    // SAFETY: `node` points into a live, immutable JSON tree held by a handle.
    match unsafe { &*node } {
        JSON::OBJECT { .. } => KIND_OBJECT,
        JSON::LIST_OBJECT { .. } => KIND_LIST_OBJECT,
        JSON::ARRAY { .. } => KIND_ARRAY,
        JSON::LIST { .. } => KIND_LIST,
        JSON::STRING { .. } => KIND_STRING,
        JSON::INTEGER { .. } => KIND_INTEGER,
        JSON::NUMBER { .. } => KIND_NUMBER,
        JSON::TRUE => KIND_TRUE,
        JSON::FALSE => KIND_FALSE,
        JSON::NULL => KIND_NULL,
    }
}

/// For a `STRING` node, returns a pointer to its UTF-8 bytes and writes the byte
/// length to `*len`. The bytes are *not* NUL-terminated; the caller must use the
/// length (e.g. `QString::fromUtf8(ptr, len)`). Returns null with `*len = 0` for
/// any other node kind. The bytes stay valid until the owning handle is released.
#[unsafe(no_mangle)]
pub extern "C" fn omc_json_string(node: *const JSON, len: *mut usize) -> *const c_char {
    // SAFETY: as in `omc_json_kind`; `len` is a valid out-pointer.
    match unsafe { &*node } {
        JSON::STRING { r#str } => {
            unsafe { *len = r#str.len() };
            r#str.as_ptr() as *const c_char
        }
        _ => {
            unsafe { *len = 0 };
            ptr::null()
        }
    }
}

/// Integer payload of an `INTEGER` node (0 for other kinds).
#[unsafe(no_mangle)]
pub extern "C" fn omc_json_integer(node: *const JSON) -> i64 {
    match unsafe { &*node } {
        JSON::INTEGER { i } => *i as i64,
        _ => 0,
    }
}

/// Real payload of a `NUMBER` node, with an `INTEGER` widened to double (so the
/// walker matches `QJsonDocument`'s numeric coercion). 0.0 for other kinds.
#[unsafe(no_mangle)]
pub extern "C" fn omc_json_number(node: *const JSON) -> c_double {
    match unsafe { &*node } {
        JSON::NUMBER { r } => r.0 as c_double,
        JSON::INTEGER { i } => *i as c_double,
        _ => 0.0,
    }
}

// ── O(n) cursor over LIST / LIST_OBJECT nodes ────────────────────────────────
//
// The stored value is normalised to list form (`JSON.toListForm` in
// NFApi.getModelInstanceReference), so aggregates are singly-linked
// `LIST` / `LIST_OBJECT` cons lists. An index-based getter would be O(n²) over
// such a list; this cursor walks head-to-tail in O(n), mirroring the C side's
// `MMC_CAR`/`MMC_CDR` loop.

enum Cursor {
    /// Position in a `JSON::LIST` (`List<Arc<JSON>>`).
    List(*const List<Arc<JSON>>),
    /// Position in a `JSON::LIST_OBJECT` (`List<(key, value)>`).
    Object(*const List<(arcstr::ArcStr, Arc<JSON>)>),
}

/// Opaque list cursor handed to OMEdit. Created by [`omc_json_iter_new`] and
/// released with [`omc_json_iter_free`].
pub struct OmcJsonIter {
    cur: Cursor,
}

/// Create a cursor positioned at the first element of a `LIST` or `LIST_OBJECT`
/// node. Returns null for any other node kind (the caller checks
/// [`omc_json_kind`] first). The cursor borrows the tree owned by the handle and
/// must be freed with [`omc_json_iter_free`] before the handle is released.
#[unsafe(no_mangle)]
pub extern "C" fn omc_json_iter_new(node: *const JSON) -> *mut OmcJsonIter {
    // SAFETY: `node` points into a live, immutable JSON tree.
    let cur = match unsafe { &*node } {
        JSON::LIST { values } => Cursor::List(Arc::as_ptr(values)),
        JSON::LIST_OBJECT { values } => Cursor::Object(Arc::as_ptr(values)),
        _ => return ptr::null_mut(),
    };
    Box::into_raw(Box::new(OmcJsonIter { cur }))
}

/// 1 if the cursor is at the end (no current element), 0 otherwise.
#[unsafe(no_mangle)]
pub extern "C" fn omc_json_iter_at_end(it: *const OmcJsonIter) -> c_int {
    let it = unsafe { &*it };
    let at_end = match it.cur {
        Cursor::List(p) => matches!(unsafe { &*p }, List::Nil),
        Cursor::Object(p) => matches!(unsafe { &*p }, List::Nil),
    };
    if at_end { 1 } else { 0 }
}

/// The value of the current element (a `*const JSON`), or null at end. For a
/// `LIST_OBJECT` this is the value half of the current key/value pair.
#[unsafe(no_mangle)]
pub extern "C" fn omc_json_iter_value(it: *const OmcJsonIter) -> *const JSON {
    let it = unsafe { &*it };
    match it.cur {
        Cursor::List(p) => match unsafe { &*p } {
            List::Cons { head, .. } => Arc::as_ptr(head),
            List::Nil => ptr::null(),
        },
        Cursor::Object(p) => match unsafe { &*p } {
            List::Cons { head, .. } => Arc::as_ptr(&head.1),
            List::Nil => ptr::null(),
        },
    }
}

/// The key of the current `LIST_OBJECT` element: a pointer to its UTF-8 bytes
/// (not NUL-terminated) with the length written to `*len`. Returns null with
/// `*len = 0` for a `LIST` cursor or at end.
#[unsafe(no_mangle)]
pub extern "C" fn omc_json_iter_key(it: *const OmcJsonIter, len: *mut usize) -> *const c_char {
    let it = unsafe { &*it };
    match it.cur {
        Cursor::Object(p) => match unsafe { &*p } {
            List::Cons { head, .. } => {
                unsafe { *len = head.0.len() };
                head.0.as_ptr() as *const c_char
            }
            List::Nil => {
                unsafe { *len = 0 };
                ptr::null()
            }
        },
        Cursor::List(_) => {
            unsafe { *len = 0 };
            ptr::null()
        }
    }
}

/// Advance the cursor to the next element (no-op at end).
#[unsafe(no_mangle)]
pub extern "C" fn omc_json_iter_advance(it: *mut OmcJsonIter) {
    let it = unsafe { &mut *it };
    match &mut it.cur {
        Cursor::List(p) => {
            if let List::Cons { tail, .. } = unsafe { &**p } {
                *p = Arc::as_ptr(tail);
            }
        }
        Cursor::Object(p) => {
            if let List::Cons { tail, .. } = unsafe { &**p } {
                *p = Arc::as_ptr(tail);
            }
        }
    }
}

/// Free a cursor created by [`omc_json_iter_new`].
#[unsafe(no_mangle)]
pub extern "C" fn omc_json_iter_free(it: *mut OmcJsonIter) {
    if !it.is_null() {
        // SAFETY: `it` was produced by `Box::into_raw` in `omc_json_iter_new`.
        unsafe { drop(Box::from_raw(it)) };
    }
}
