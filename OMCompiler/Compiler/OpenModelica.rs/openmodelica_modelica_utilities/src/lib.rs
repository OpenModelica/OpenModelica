// Our own `ModelicaUtilities` string allocation for the wasm-jit / FFI simulation
// host — never the old C runtime's (GC-backed) one. `ModelicaAllocateString` is
// called by external "C" functions (e.g. `ModelicaStrings_scanString`) to allocate
// the buffer they return a `char*` into. On the C runtime that buffer is GC-owned
// and never freed; here we own it in a thread-local arena that the external-call
// trampoline resets after unmarshalling the results into in-wasm strings.
//
// The same `ModelicaAllocateString` symbol is also referenced by the compile-time
// `-d=gen` function-eval path, which legitimately uses the C runtime's GC version.
// A thread-local flag distinguishes them: the simulation trampoline brackets each
// external call with [`omrs_sim_external_begin`]/[`omrs_sim_external_end`], so only
// then do we allocate from the arena; otherwise (native) we forward to the C
// runtime's `ModelicaAllocateString` via `RTLD_NEXT`.

use std::cell::{Cell, RefCell};
use std::os::raw::c_char;

thread_local! {
    /// Set while a simulation external "C" call is in flight (between
    /// `omrs_sim_external_begin` and `_end`). Only then does `ModelicaAllocateString`
    /// use the arena instead of forwarding to the C runtime.
    static SIM_MODE: Cell<bool> = const { Cell::new(false) };
    /// Buffers handed out by `ModelicaAllocateString` during the current external
    /// call. Cleared by `omrs_sim_external_end` once the results are unmarshalled.
    static ARENA: RefCell<Vec<Box<[u8]>>> = const { RefCell::new(Vec::new()) };
}

/// Allocate a `len+1`-byte zeroed buffer (room for the NUL) from the arena and
/// return a pointer to it; the buffer lives until [`omrs_sim_external_end`].
fn arena_alloc(len: usize) -> *mut c_char {
    ARENA.with(|a| {
        let mut buf = vec![0u8; len + 1].into_boxed_slice();
        let ptr = buf.as_mut_ptr() as *mut c_char;
        a.borrow_mut().push(buf);
        ptr
    })
}

/// Allocation used outside simulation mode. Native: the C runtime's own
/// allocator, one hop up the symbol chain (past ours) — present when a runtime
/// library is loaded (`-d=gen`, or the FFI evaluation of an external "C"
/// function); a leaking `malloc` otherwise (the caller contract is that the buffer
/// is not freed by the caller). Wasm: no C runtime, so the arena is the only
/// allocator.
///
/// The hop must target the leaf `ModelicaAllocateStringWithErrorReturn`: the C
/// runtime's `ModelicaAllocateString` only wraps it, and that inner call resolves
/// back to this crate's interposing definition — an unbounded cycle.
#[cfg(not(target_arch = "wasm32"))]
fn non_sim_alloc(len: usize) -> *mut c_char {
    let next =
        unsafe { libc::dlsym(libc::RTLD_NEXT, c"ModelicaAllocateStringWithErrorReturn".as_ptr()) };
    if !next.is_null() {
        let f: extern "C" fn(usize) -> *mut c_char = unsafe { std::mem::transmute(next) };
        let res = f(len);
        if !res.is_null() {
            return res;
        }
    }
    let res = unsafe { libc::malloc(len + 1) as *mut c_char };
    if !res.is_null() {
        unsafe { *res.add(len) = 0 };
    }
    res
}

#[cfg(target_arch = "wasm32")]
fn non_sim_alloc(len: usize) -> *mut c_char {
    arena_alloc(len)
}

/// `char* ModelicaAllocateString(size_t len)` — the Modelica Utilities allocator.
/// In simulation mode the buffer is arena-owned (freed per external call); outside
/// it, forwarded to the C runtime's GC-backed allocator (native).
#[unsafe(no_mangle)]
pub extern "C" fn ModelicaAllocateString(len: usize) -> *mut c_char {
    if SIM_MODE.with(Cell::get) {
        arena_alloc(len)
    } else {
        non_sim_alloc(len)
    }
}

/// `char* ModelicaAllocateStringWithErrorReturn(size_t len)` — same, but the
/// contract allows returning 0 on failure. Our arena/`malloc` do not fail in
/// practice, so this behaves like [`ModelicaAllocateString`].
#[unsafe(no_mangle)]
pub extern "C" fn ModelicaAllocateStringWithErrorReturn(len: usize) -> *mut c_char {
    ModelicaAllocateString(len)
}

/// Enter simulation-external mode: subsequent `ModelicaAllocateString` calls use
/// the arena. Called by the external-call trampoline before the libffi call.
pub fn sim_external_begin() {
    SIM_MODE.with(|f| f.set(true));
}

/// Leave simulation-external mode and free everything the call allocated. Call
/// only after the external's string results have been copied into in-wasm strings.
pub fn sim_external_end() {
    SIM_MODE.with(|f| f.set(false));
    ARENA.with(|a| a.borrow_mut().clear());
}

/// C-ABI aliases of [`sim_external_begin`]/[`sim_external_end`], in case the
/// bracketing is ever done from C.
#[unsafe(no_mangle)]
pub extern "C" fn omrs_sim_external_begin() {
    sim_external_begin();
}

#[unsafe(no_mangle)]
pub extern "C" fn omrs_sim_external_end() {
    sim_external_end();
}

// ---------------------------------------------------------------------------
// ModelicaMessage / ModelicaWarning
// ---------------------------------------------------------------------------
//
// The C runtime routes these to `OMC_LOG_STDOUT`, the stream `Streams.print`'s
// output reaches the simulation log through — but the compiler process never
// enables it. So the wasm-jit host rebinds the runtime's
// `OpenModelica_ModelicaVFormat{Message,Warning}` slots (dynload +
// runtime_error_shim.c) and the rendered message arrives here instead.

/// C's `messageText` prefixes (util/omc_error.c: `%-17s | %-7s | `), for a
/// message's first line and for its wrapped lines.
pub const LOG_STDOUT_INFO: &str = "LOG_STDOUT        | info    | ";
pub const LOG_STDOUT_WARNING: &str = "LOG_STDOUT        | warning | ";
const LOG_CONT: &str = "|                 | |       | ";

/// Prefix each line of a `\n`-separated message, the first with `prefix`.
pub fn format_log_stdout(msg: &str, prefix: &str) -> String {
    let mut out = String::new();
    for (i, line) in msg.split('\n').enumerate() {
        out.push_str(if i == 0 { prefix } else { LOG_CONT });
        out.push_str(line);
        out.push('\n');
    }
    out
}

/// Emit `msg` to the running simulation's captured stdout if an external call is
/// in flight; returns whether it was taken. The caller's format string
/// `\n`-terminates the line, which the prefixing re-adds.
fn take_message(msg: *const c_char, prefix: &str) -> bool {
    if !SIM_MODE.with(Cell::get) || msg.is_null() {
        return false;
    }
    let text = unsafe { std::ffi::CStr::from_ptr(msg) }.to_string_lossy().into_owned();
    let line = format_log_stdout(text.strip_suffix('\n').unwrap_or(&text), prefix);
    openmodelica_wasi::wasi::stdout_write(line.as_bytes());
    true
}

// The two hooks the simulation host hands to
// `dynload::install_modelica_message_interception`.

pub extern "C" fn modelica_message_hook(msg: *const c_char) -> i32 {
    take_message(msg, LOG_STDOUT_INFO) as i32
}

pub extern "C" fn modelica_warning_hook(msg: *const c_char) -> i32 {
    take_message(msg, LOG_STDOUT_WARNING) as i32
}
