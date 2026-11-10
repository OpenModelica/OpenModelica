//! The C ABI the Julia bridge calls (`omjl_*`). omc runs on a thread of its
//! own with omc's stack; the caller only reads the values it returns, through
//! the `metamodelica::reflect` view. A flat model holds `Rc`s, so every call
//! takes the one `OMC` lock: no two threads touch those values at once.

use crate::set_revision;
use arcstr::ArcStr;
use metamodelica::reflect::MMField;
use openmodelica_backend_main::capi;
use std::ffi::{CStr, CString, c_char, c_int};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::sync::mpsc::{Sender, channel};
use std::sync::{Arc, Mutex, MutexGuard};

type Job = Box<dyn FnOnce() + Send>;

struct Unshared<T>(T);
// SAFETY: an `Unshared` only moves between threads while the `OMC` lock is held.
unsafe impl<T> Send for Unshared<T> {}

pub struct OmjlValue(MMField);

static OMC: Mutex<Option<Sender<Job>>> = Mutex::new(None);
static LAST_ERROR: Mutex<String> = Mutex::new(String::new());

fn lock() -> MutexGuard<'static, Option<Sender<Job>>> {
    OMC.lock().unwrap_or_else(|e| e.into_inner())
}

fn set_error(msg: impl Into<String>) {
    *LAST_ERROR.lock().unwrap_or_else(|e| e.into_inner()) = msg.into();
}

/// Run `f` on the omc thread and wait for it. A panic is returned as `Err`.
fn on_omc<T: 'static>(
    guard: &MutexGuard<'_, Option<Sender<Job>>>,
    f: impl FnOnce() -> T + 'static,
) -> Result<T, String> {
    let Some(tx) = guard.as_ref() else {
        return Err("omjl_init has not been called".into());
    };
    let (rtx, rrx) = channel();
    let f = Unshared(f);
    let job: Job = Box::new(move || {
        let f = f;
        let r = catch_unwind(AssertUnwindSafe(f.0)).map_err(|p| {
            p.downcast_ref::<&str>()
                .map(|s| s.to_string())
                .or_else(|| p.downcast_ref::<String>().cloned())
                .unwrap_or_else(|| "panic in omc".into())
        });
        let _ = rtx.send(Unshared(r));
    });
    tx.send(job).map_err(|_| "the omc thread is gone".to_string())?;
    rrx.recv().map_err(|_| "the omc thread is gone".to_string())?.0
}

fn c_str(p: *const c_char) -> Option<ArcStr> {
    if p.is_null() {
        return None;
    }
    // SAFETY: the caller passes a valid NUL-terminated string.
    Some(ArcStr::from(String::from_utf8_lossy(
        unsafe { CStr::from_ptr(p) }.to_bytes(),
    )))
}

fn new_value(f: MMField) -> *mut OmjlValue {
    Box::into_raw(Box::new(OmjlValue(f)))
}

fn value<'a>(v: *const OmjlValue) -> Option<&'a MMField> {
    // SAFETY: `v` is null or a live pointer from `new_value`.
    unsafe { v.as_ref() }.map(|v| &v.0)
}

fn out_str(s: &str, len: *mut usize) -> *const u8 {
    if !len.is_null() {
        // SAFETY: `len` points to writable memory when not null.
        unsafe { *len = s.len() };
    }
    s.as_ptr()
}

/// Start omc with the command-line arguments `argv[0..argc]`. Returns 0 on
/// success, also when omc already runs.
#[unsafe(no_mangle)]
pub extern "C" fn omjl_init(argv: *const *const c_char, argc: c_int) -> c_int {
    let mut guard = lock();
    if guard.is_some() {
        return 0;
    }
    let args: Vec<ArcStr> = (0..argc.max(0) as usize)
        // SAFETY: `argv` holds `argc` valid NUL-terminated strings.
        .filter_map(|i| c_str(unsafe { *argv.add(i) }))
        .collect();
    let (tx, rx) = channel::<Job>();
    let spawned = std::thread::Builder::new()
        .name("omc-julia".into())
        .stack_size(metamodelica::thread_stack_size())
        .spawn(move || {
            for job in rx {
                job();
            }
        });
    if let Err(e) = spawned {
        set_error(format!("cannot start the omc thread: {e}"));
        return -1;
    }
    *guard = Some(tx);
    match on_omc(&guard, move || {
        set_revision();
        capi::init(&args)
    }) {
        Ok(Ok(())) => 0,
        Ok(Err(e)) => {
            set_error(e);
            -1
        }
        Err(e) => {
            set_error(e);
            -1
        }
    }
}

/// The message of the last failed `omjl_*` call; valid until the next one.
#[unsafe(no_mangle)]
pub extern "C" fn omjl_last_error() -> *mut c_char {
    let msg = LAST_ERROR.lock().unwrap_or_else(|e| e.into_inner()).replace('\0', " ");
    CString::new(msg).unwrap_or_default().into_raw()
}

/// Evaluate a scripting command, e.g. `loadModel(Modelica)`. Free the reply
/// with `omc_compiler_free_string`.
#[unsafe(no_mangle)]
pub extern "C" fn omjl_eval(command: *const c_char) -> *mut c_char {
    let Some(cmd) = c_str(command) else {
        return std::ptr::null_mut();
    };
    let guard = lock();
    let reply = match on_omc(&guard, move || capi::eval(cmd)) {
        Ok(Ok((_, reply))) => reply.to_string(),
        Ok(Err(e)) => format!("Error: {e}"),
        Err(e) => format!("Error: {e}"),
    };
    CString::new(reply.replace('\0', " ")).unwrap_or_default().into_raw()
}

/// Instantiate a class with the new frontend. Returns its flat model and
/// stores the list of its functions in `*functions`; null on failure (see
/// `omjl_last_error` and `getErrorString()`).
#[unsafe(no_mangle)]
pub extern "C" fn omjl_instantiate(class_name: *const c_char, functions: *mut *mut OmjlValue) -> *mut OmjlValue {
    let Some(name) = c_str(class_name) else {
        return std::ptr::null_mut();
    };
    let guard = lock();
    match on_omc(&guard, move || capi::instantiate_flat(&name)) {
        Ok(Ok((model, fns))) => {
            if !functions.is_null() {
                // SAFETY: `functions` points to writable memory when not null.
                unsafe { *functions = new_value(MMField::List(fns.into_iter().map(MMField::Node).collect())) };
            }
            new_value(MMField::Node(model))
        }
        Ok(Err(e)) => {
            set_error(e);
            std::ptr::null_mut()
        }
        Err(e) => {
            set_error(e);
            std::ptr::null_mut()
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn omjl_free(v: *mut OmjlValue) {
    if !v.is_null() {
        let _guard = lock();
        // SAFETY: `v` came from `new_value` and is freed once.
        drop(unsafe { Box::from_raw(v) });
    }
}

/// 0 Integer, 1 Real, 2 Boolean, 3 String, 4 enumeration literal, 5 node
/// (record or uniontype), 6 list, 7 array, 8 tuple, 9 option, 10 opaque.
#[unsafe(no_mangle)]
pub extern "C" fn omjl_kind(v: *const OmjlValue) -> c_int {
    let Some(f) = value(v) else { return -1 };
    match f {
        MMField::Integer(_) => 0,
        MMField::Real(_) => 1,
        MMField::Boolean(_) => 2,
        MMField::String(_) => 3,
        MMField::Enum { .. } => 4,
        MMField::Node(_) => 5,
        MMField::List(_) => 6,
        MMField::Array(_) => 7,
        MMField::Tuple(_) => 8,
        MMField::Option(_) => 9,
        MMField::Opaque(_) => 10,
    }
}

/// An Integer, a Boolean (0/1), or an enumeration literal's index.
#[unsafe(no_mangle)]
pub extern "C" fn omjl_integer(v: *const OmjlValue) -> i64 {
    match value(v) {
        Some(MMField::Integer(i)) => *i,
        Some(MMField::Boolean(b)) => *b as i64,
        Some(MMField::Enum { index, .. }) => *index as i64,
        _ => 0,
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn omjl_real(v: *const OmjlValue) -> f64 {
    match value(v) {
        Some(MMField::Real(r)) => *r,
        Some(MMField::Integer(i)) => *i as f64,
        _ => f64::NAN,
    }
}

/// A String's contents, an enumeration literal's name, a node's constructor
/// name or an opaque value's Rust type. Not NUL-terminated; valid while `v`
/// lives.
#[unsafe(no_mangle)]
pub extern "C" fn omjl_name(v: *const OmjlValue, len: *mut usize) -> *const u8 {
    let _guard = lock();
    match value(v) {
        Some(MMField::String(s)) => out_str(s, len),
        Some(MMField::Enum { literal, .. }) => out_str(literal, len),
        Some(MMField::Node(n)) => out_str(n.mm_ctor_name(), len),
        Some(MMField::Opaque(t)) => out_str(t, len),
        _ => out_str("", len),
    }
}

/// The type of a node or of an enumeration literal.
#[unsafe(no_mangle)]
pub extern "C" fn omjl_type_name(v: *const OmjlValue, len: *mut usize) -> *const u8 {
    let _guard = lock();
    match value(v) {
        Some(MMField::Node(n)) => out_str(n.mm_type_name(), len),
        Some(MMField::Enum { type_name, .. }) => out_str(type_name, len),
        _ => out_str("", len),
    }
}

/// The number of fields of a node, or of elements of a list, array, tuple
/// or option.
#[unsafe(no_mangle)]
pub extern "C" fn omjl_length(v: *const OmjlValue) -> i64 {
    let _guard = lock();
    match value(v) {
        Some(MMField::Node(n)) => n.mm_field_names().len() as i64,
        Some(MMField::List(e) | MMField::Array(e) | MMField::Tuple(e)) => e.len() as i64,
        Some(MMField::Option(o)) => o.is_some() as i64,
        _ => 0,
    }
}

/// The name of field `i` (0-based) of a node.
#[unsafe(no_mangle)]
pub extern "C" fn omjl_field_name(v: *const OmjlValue, i: i64, len: *mut usize) -> *const u8 {
    let _guard = lock();
    match value(v) {
        Some(MMField::Node(n)) => out_str(n.mm_field_names().get(i as usize).copied().unwrap_or(""), len),
        _ => out_str("", len),
    }
}

/// Field `i` of a node or element `i` of a container, 0-based; null when out
/// of range. Free the result with `omjl_free`.
#[unsafe(no_mangle)]
pub extern "C" fn omjl_child(v: *const OmjlValue, i: i64) -> *mut OmjlValue {
    let _guard = lock();
    let i = i as usize;
    let child = match value(v) {
        Some(MMField::Node(n)) => n.mm_field(i),
        Some(MMField::List(e) | MMField::Array(e) | MMField::Tuple(e)) => e.get(i).cloned(),
        Some(MMField::Option(Some(o))) if i == 0 => Some((**o).clone()),
        _ => None,
    };
    child.map_or(std::ptr::null_mut(), new_value)
}

/// Call the frontend function `function` (see `capi::apply`) on the node `v`.
/// Null on failure (see `omjl_last_error`).
#[unsafe(no_mangle)]
pub extern "C" fn omjl_apply(function: *const c_char, v: *const OmjlValue) -> *mut OmjlValue {
    let (Some(function), Some(MMField::Node(n))) = (c_str(function), value(v)) else {
        set_error("omjl_apply: not a node");
        return std::ptr::null_mut();
    };
    let guard = lock();
    let n = n.clone();
    match on_omc(&guard, move || capi::apply(&function, &n)) {
        Ok(Ok(f)) => new_value(f),
        Ok(Err(e)) => {
            set_error(e);
            std::ptr::null_mut()
        }
        Err(e) => {
            set_error(e);
            std::ptr::null_mut()
        }
    }
}

/// The address of a node's allocation: equal for two handles to one node.
#[unsafe(no_mangle)]
pub extern "C" fn omjl_identity(v: *const OmjlValue) -> usize {
    match value(v) {
        Some(MMField::Node(n)) => Arc::as_ptr(n) as *const () as usize,
        _ => 0,
    }
}
