//! MetaModelica-ABI compatibility shims for OMEdit (built with `-DOMC_RUST_ABI`).
//!
//! OMEdit's in-process command path calls the MMC entry points `omc_Main_init` /
//! `omc_Main_handleCommand` (and the GC/Windows no-ops), exchanging values built
//! with the `mmc_mk_*` constructors from `include/omc_rust_embedding.h`. That
//! header replaces the real MMC value/runtime with a trivial malloc-boxed value
//! (no OMC Boehm GC); these shims implement the entry points over the safe Rust
//! embedding ABI ([`crate::omc_compiler_eval_keep`] etc.), reading and freeing
//! those boxes at the boundary.
//!
//! The box layout and `threadData_t` here mirror the C declarations in that
//! header exactly (`#[repr(C)]`). Boxes are allocated by OMEdit with
//! `malloc`/`strdup`, so the shims free them with `libc::free`; the reply box the
//! shim hands back is likewise built with `libc` so OMEdit can read it and the
//! shim can free it on the next command.
//!
//! Single-threaded by contract (see [`openmodelica_backend_main::capi`]): all of
//! OMEdit's init/command calls run on one thread.

use std::cell::RefCell;
use std::ffi::{CString, c_char, c_int, c_void};
use std::panic::catch_unwind;
use std::ptr;
use std::sync::atomic::{AtomicPtr, Ordering};

use openmodelica_util::System::{
    LoadModelCallback, PlotCallback, omc_set_loadmodel_callback, omc_set_plot_callback,
};

/// Mirror of `OmcRtBox` in `omc_rust_embedding.h`: a tagged NIL/CONS/SCON box.
#[repr(C)]
struct OmcRtBox {
    tag: c_int,
    s: *mut c_char,
    head: *mut OmcRtBox,
    tail: *mut OmcRtBox,
}

const OMCRT_CONS: c_int = 1;
const OMCRT_SCON: c_int = 2;

/// Mirror of `struct threadData_s` in `omc_rust_embedding.h`: the carrier for the
/// plot/loadModel callbacks OMEdit installs. `Option<fn>` is ABI-identical to the
/// C function pointer (a null pointer arrives as `None`).
#[repr(C)]
struct ThreadData {
    plot_class_ptr: *mut c_void,
    plot_cb: Option<PlotCallback>,
    load_class_ptr: *mut c_void,
    load_cb: Option<LoadModelCallback>,
}

/// Recursively free a box and any owned strings, with the same allocator that
/// `mmc_mk_*` used (`malloc`/`strdup`).
///
/// # Safety
/// `v` must be null or a box produced by the header's `mmc_mk_*` / [`make_scon_box`].
unsafe fn free_box(v: *mut OmcRtBox) {
    if v.is_null() {
        return;
    }
    let b = unsafe { &*v };
    match b.tag {
        OMCRT_SCON => {
            if !b.s.is_null() {
                unsafe { libc::free(b.s as *mut c_void) };
            }
        }
        OMCRT_CONS => unsafe {
            free_box(b.head);
            free_box(b.tail);
        },
        _ => {}
    }
    unsafe { libc::free(v as *mut c_void) };
}

/// Build a SCON box holding a copy of `s` (or `""` if null), allocated with
/// `libc` so it is layout- and allocator-compatible with the header's boxes.
///
/// # Safety
/// `s` must be null or a valid NUL-terminated C string.
unsafe fn make_scon_box(s: *const c_char) -> *mut OmcRtBox {
    let b = unsafe { libc::malloc(std::mem::size_of::<OmcRtBox>()) } as *mut OmcRtBox;
    unsafe {
        (*b).tag = OMCRT_SCON;
        (*b).head = ptr::null_mut();
        (*b).tail = ptr::null_mut();
        (*b).s = if s.is_null() {
            libc::strdup(c"".as_ptr())
        } else {
            libc::strdup(s)
        };
    }
    b
}

/// The reply box from the previous command. OMEdit copies the reply into a
/// QString immediately after `omc_Main_handleCommand` returns, so the box is
/// safe to free at the next call. (Single-threaded; the atomic just satisfies
/// `Sync` for the static.)
static PREV_REPLY: AtomicPtr<OmcRtBox> = AtomicPtr::new(ptr::null_mut());

/// GC no-op: the Rust runtime owns and lazily initialises its own collector.
/// Kept so OMEdit's `omc_System_initGarbageCollector(NULL)` call links.
#[unsafe(no_mangle)]
pub extern "C" fn omc_System_initGarbageCollector(_thread_data: *mut c_void) {}

/// Initialise the compiler, forwarding the boxed argument list (a cons list of
/// flag strings such as `+locale=sv_SE`) to the Rust init. Returns the
/// thread-data pointer unchanged (OMEdit ignores the result).
#[unsafe(no_mangle)]
pub extern "C" fn omc_Main_init(thread_data: *mut c_void, args: *mut c_void) -> *mut c_void {
    unsafe {
        let mut argv: Vec<*const c_char> = Vec::new();
        let mut p = args as *const OmcRtBox;
        while !p.is_null() && (*p).tag == OMCRT_CONS {
            let h = (*p).head;
            argv.push(if h.is_null() { c"".as_ptr() } else { (*h).s });
            p = (*p).tail;
        }
        let (ptr, len) = if argv.is_empty() {
            (ptr::null(), 0)
        } else {
            (argv.as_ptr(), argv.len() as c_int)
        };
        crate::omc_compiler_init_args(ptr, len);
        free_box(args as *mut OmcRtBox);
    }
    thread_data
}

/// Evaluate one command. `imsg` is a boxed command string; `*omsg` receives a
/// boxed reply string; the result is the keep-running flag (0 after `quit()`),
/// matching the MMC `omc_Main_handleCommand`.
#[unsafe(no_mangle)]
pub extern "C" fn omc_Main_handleCommand(
    thread_data: *mut c_void,
    imsg: *mut c_void,
    omsg: *mut *mut c_void,
) -> c_int {
    unsafe {
        // Forward OMEdit's plot/loadModel callbacks (stored on threadData) to the
        // Rust runtime's registry, which `System.*CallBack` consult. Cheap, and
        // robust to OMEdit (re)installing them.
        let td = thread_data as *const ThreadData;
        if !td.is_null() {
            let td = &*td;
            omc_set_plot_callback(td.plot_class_ptr, td.plot_cb);
            omc_set_loadmodel_callback(td.load_class_ptr, td.load_cb);
        }

        // Release the previous reply box (already consumed by OMEdit).
        free_box(PREV_REPLY.swap(ptr::null_mut(), Ordering::Relaxed));

        let imsg = imsg as *mut OmcRtBox;
        let cmd = if imsg.is_null() { c"".as_ptr() } else { (*imsg).s };
        let mut keep: c_int = 1;
        let reply = crate::omc_compiler_eval_keep(cmd, &mut keep);

        // The command box is fully consumed by the eval above; free it.
        free_box(imsg);

        let reply_box = make_scon_box(reply);
        crate::omc_compiler_free_string(reply);
        if !omsg.is_null() {
            *omsg = reply_box as *mut c_void;
        }
        PREV_REPLY.store(reply_box, Ordering::Relaxed);
        keep
    }
}

/// Windows path fix-up in the stock OMEdit; the Rust port derives platform paths
/// itself, so this is a no-op kept for link compatibility (only ever called on
/// Windows).
#[unsafe(no_mangle)]
pub extern "C" fn omc_Main_setWindowsPaths(_thread_data: *mut c_void, _in_om_home: *mut c_void) {}

// OMEdit calls this Settings runtime symbol once at startup (OMEditApplication,
// via settingsimpl.h) to discover OPENMODELICAHOME. Providing it here lets OMEdit
// drop `-lomcruntime` entirely (the MMC value runtime) — the only other symbols
// it pulled from there (ModelInstanceReference_get/release) are exported above.
thread_local! {
    static INSTALL_DIR: RefCell<Option<CString>> = const { RefCell::new(None) };
}

/// `const char* SettingsImpl__getInstallationDirectoryPath(void)` — returns the
/// installation directory (OPENMODELICAHOME). The returned pointer is owned by
/// the library and stays valid until the next call on the same thread; OMEdit
/// copies it immediately.
#[unsafe(no_mangle)]
pub extern "C" fn SettingsImpl__getInstallationDirectoryPath() -> *const c_char {
    let dir = match catch_unwind(openmodelica_util::Settings::getInstallationDirectoryPath) {
        Ok(Ok(s)) => s,
        _ => return ptr::null(),
    };
    INSTALL_DIR.with(|cell| {
        *cell.borrow_mut() = CString::new(dir.as_bytes()).ok();
        cell.borrow().as_ref().map_or(ptr::null(), |c| c.as_ptr())
    })
}
