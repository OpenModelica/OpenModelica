//! `ModelicaUtilities.h` for the libraries, exported from the loader itself.
//! An importer `dlopen`s the loader `RTLD_LOCAL`, so [`publish`] reopens it
//! `RTLD_GLOBAL` first, which is what lets a library loaded after resolve
//! `ModelicaError` here.

use std::cell::RefCell;
use std::ffi::{c_char, c_void, CStr, VaList};

thread_local! {
    /// What `ModelicaAllocateString` handed out during the current call.
    static ARENA: RefCell<Vec<Vec<u8>>> = const { RefCell::new(Vec::new()) };
    static SINK: RefCell<Option<fn(&str)>> = const { RefCell::new(None) };
}

/// Where `ModelicaMessage`/`ModelicaWarning` go; stderr until set.
pub fn set_message_sink(f: fn(&str)) {
    SINK.with(|s| *s.borrow_mut() = Some(f));
}

fn message(s: &str) {
    match SINK.with(|s| *s.borrow()) {
        Some(f) => f(s),
        None => eprintln!("{s}"),
    }
}

/// Make this library's symbols visible to the ones loaded after it.
pub(crate) fn publish() {
    use std::sync::Once;
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        let mut info: libc::Dl_info = unsafe { std::mem::zeroed() };
        if unsafe { libc::dladdr(publish as *const c_void, &mut info) } == 0 || info.dli_fname.is_null() {
            return;
        }
        unsafe { libc::dlopen(info.dli_fname, libc::RTLD_NOLOAD | libc::RTLD_GLOBAL | libc::RTLD_LAZY) };
    });
}

/// Frees what the call's `ModelicaAllocateString`s handed out when dropped —
/// after its String results were copied.
pub(crate) struct ReleaseStrings;

impl Drop for ReleaseStrings {
    fn drop(&mut self) {
        ARENA.with(|a| a.borrow_mut().clear());
    }
}

fn cstr(p: *const c_char) -> String {
    if p.is_null() { String::new() } else { unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned() }
}

unsafe extern "C" {
    fn vsnprintf(s: *mut c_char, n: usize, fmt: *const c_char, args: VaList) -> libc::c_int;
}

unsafe fn vformat(fmt: *const c_char, args: VaList) -> String {
    let mut buf = vec![0u8; 2048];
    let n = unsafe { vsnprintf(buf.as_mut_ptr() as *mut c_char, buf.len(), fmt, args) };
    if n < 0 {
        return cstr(fmt);
    }
    buf.truncate((n as usize).min(buf.len() - 1));
    String::from_utf8_lossy(&buf).into_owned()
}

#[unsafe(no_mangle)]
pub extern "C" fn ModelicaAllocateString(len: usize) -> *mut c_char {
    ARENA.with(|a| {
        let mut a = a.borrow_mut();
        a.push(vec![0u8; len + 1]);
        a.last_mut().expect("just pushed").as_mut_ptr() as *mut c_char
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn ModelicaAllocateStringWithErrorReturn(len: usize) -> *mut c_char {
    ModelicaAllocateString(len)
}

#[unsafe(no_mangle)]
pub extern "C-unwind" fn ModelicaError(s: *const c_char) -> ! {
    super::error::raise(cstr(s))
}

#[unsafe(no_mangle)]
pub unsafe extern "C-unwind" fn ModelicaVFormatError(fmt: *const c_char, args: VaList) -> ! {
    super::error::raise(unsafe { vformat(fmt, args) })
}

#[unsafe(no_mangle)]
pub unsafe extern "C-unwind" fn ModelicaFormatError(fmt: *const c_char, args: ...) -> ! {
    super::error::raise(unsafe { vformat(fmt, args) })
}

#[unsafe(no_mangle)]
pub extern "C" fn ModelicaMessage(s: *const c_char) {
    message(&cstr(s));
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn ModelicaVFormatMessage(fmt: *const c_char, args: VaList) {
    message(&unsafe { vformat(fmt, args) });
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn ModelicaFormatMessage(fmt: *const c_char, args: ...) {
    message(&unsafe { vformat(fmt, args) });
}

#[unsafe(no_mangle)]
pub extern "C" fn ModelicaWarning(s: *const c_char) {
    message(&cstr(s));
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn ModelicaVFormatWarning(fmt: *const c_char, args: VaList) {
    message(&unsafe { vformat(fmt, args) });
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn ModelicaFormatWarning(fmt: *const c_char, args: ...) {
    message(&unsafe { vformat(fmt, args) });
}
