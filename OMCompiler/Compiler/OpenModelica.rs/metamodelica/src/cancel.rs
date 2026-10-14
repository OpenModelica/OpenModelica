//! Cooperative cancellation and progress reporting shared across the whole
//! compiler — frontend, loader, backend, and the wasm-jit sim driver.
//!
//! Native: a process-global `AtomicBool` flipped from another thread (an OMEdit
//! Cancel button, a Ctrl-C handler). wasm: the omc worker is blocked inside one
//! synchronous call and can't receive a message, so a cross-origin-isolated host
//! injects a poll fn that reads a `SharedArrayBuffer` control block instead.
//!
//! Call sites `check_cancel()` at coarse chokepoints (per file / per class /
//! per equation-system — NOT per AST node) and, on hitting it, unwind with
//! [`cancelled_error`] so the op fails like any other error and leaves omc
//! consistent (the caller must roll back partial state).

use std::sync::atomic::{AtomicBool, AtomicI32, AtomicUsize, Ordering};
use std::sync::Mutex;

// ── Phases (control block index 2; see HANDOFF-coi-consolidation.md) ──────────
pub const PHASE_IDLE: i32 = 0;
pub const PHASE_DOWNLOAD: i32 = 1;
pub const PHASE_PARSE: i32 = 2;
pub const PHASE_INSTANTIATE: i32 = 3;
pub const PHASE_BACKEND: i32 = 4;
pub const PHASE_SIMULATE: i32 = 5;

/// Permille value meaning "indeterminate" (spinner, not a bar).
pub const PROGRESS_INDETERMINATE: i32 = -1;

static CANCEL: AtomicBool = AtomicBool::new(false);

/// Request cancellation of the running operation (native, cross-thread).
pub fn request_cancel() {
    CANCEL.store(true, Ordering::Relaxed);
}

/// Clear the cancel flag; call at the start of each new cancellable op. Also
/// resets progress to idle so a stale phase can't leak into the next op.
pub fn clear_cancel() {
    CANCEL.store(false, Ordering::Relaxed);
    PROGRESS_PERMILLE.store(PROGRESS_INDETERMINATE, Ordering::Relaxed);
    PROGRESS_PHASE.store(PHASE_IDLE, Ordering::Relaxed);
    clear_progress_message();
}

// wasm: the blocked worker can't get a cancel message, so a cross-origin-isolated
// host polls a `SharedArrayBuffer` flag through an injected fn ptr. Unset for
// hosts that cancel another way (the standalone simulator frees its session).
#[cfg(target_arch = "wasm32")]
thread_local! {
    static CANCEL_POLL: std::cell::Cell<Option<fn() -> bool>> = const { std::cell::Cell::new(None) };
}

/// wasm: point the cancel check at a host poll (reads control block index 0).
#[cfg(target_arch = "wasm32")]
pub fn set_cancel_poll(f: fn() -> bool) {
    CANCEL_POLL.with(|c| c.set(Some(f)));
}

// Native: a host embedding omc in-process (OMEdit) runs the compiler on its UI
// thread, so a long call would freeze the GUI and the Cancel button could never
// be clicked. The host registers a "pump" callback that we invoke at every
// cancel check; its OMEdit implementation runs `QCoreApplication::processEvents`
// (rate-limited on its side), which delivers the Cancel click that flips the
// flag below and repaints progress — cooperative, on the same thread, so it is
// safe with the compiler's non-reentrant global state as long as the host
// disables everything but the Cancel affordance while a call is in flight.
// Null (the default) for the CLI and any host that doesn't opt in. Defined on all
// targets so the cdylib API is uniform; on wasm the worker frees the UI thread so
// nothing registers a pump and it stays null (a harmless no-op).
static PUMP: AtomicUsize = AtomicUsize::new(0);

/// Register (or clear, with `None`) the host event-pump callback invoked at each
/// [`check_cancel`]. See [`PUMP`]. No effect on wasm (no pump is registered).
pub fn set_pump_callback(f: Option<extern "C" fn()>) {
    PUMP.store(f.map_or(0, |f| f as usize), Ordering::Relaxed);
}

/// True if cancellation has been requested. Cheap (a relaxed atomic load, or one
/// injected poll on wasm) — safe to call once per coarse work unit. Also drives
/// the host event pump (see [`PUMP`]) so an in-process GUI stays live; null (and
/// so a no-op) unless a host registered one.
pub fn check_cancel() -> bool {
    #[cfg(target_arch = "wasm32")]
    if CANCEL_POLL.with(|c| c.get()).map(|f| f()).unwrap_or(false) {
        return true;
    }
    let p = PUMP.load(Ordering::Relaxed);
    if p != 0 {
        let f: extern "C" fn() = unsafe { std::mem::transmute(p) };
        f();
    }
    CANCEL.load(Ordering::Relaxed)
}

/// The canonical cancellation error. Distinct message so callers/UI can tell a
/// user-cancel from a real failure.
pub fn cancelled_error() -> &'static str {
    "Operation cancelled by user"
}

/// `Err(cancelled_error())` if cancellation was requested, else `Ok(())`.
/// Use with `?` at a chokepoint: `metamodelica::bail_if_cancelled()?;`.
#[inline]
pub fn bail_if_cancelled() -> crate::Result<()> {
    if check_cancel() {
        return Err(cancelled_error());
    }
    Ok(())
}

// ── Progress (worker → main, control block indices 1/2) ───────────────────────
//
// Mirror of the cancel poll in the opposite direction. Native is a no-op; wasm
// stores permille + phase into the shared control block through an injected sink.
#[cfg(target_arch = "wasm32")]
thread_local! {
    static PROGRESS_SINK: std::cell::Cell<Option<fn(i32, i32)>> = const { std::cell::Cell::new(None) };
}

/// wasm: point progress reports at a host sink (writes control block 1/2).
#[cfg(target_arch = "wasm32")]
pub fn set_progress_sink(f: fn(i32, i32)) {
    PROGRESS_SINK.with(|c| c.set(Some(f)));
}

// Last reported progress, readable by an in-process host (OMEdit) from its pump
// callback to fill a status-bar progress bar. Kept on all targets so the cdylib
// getters compile uniformly; on wasm the host reads the shared control block (fed
// by the sink) instead, but storing here too is harmless.
static PROGRESS_PERMILLE: AtomicI32 = AtomicI32::new(PROGRESS_INDETERMINATE);
static PROGRESS_PHASE: AtomicI32 = AtomicI32::new(PHASE_IDLE);

// Free-form label for the step in progress, shown by a host instead of the
// generic phase label ("Compiling model…" says nothing about which of five FMU
// platforms is building). A String, so a Mutex rather than an atomic; it is
// written once per step and read once per pump, so contention is irrelevant.
static PROGRESS_MESSAGE: Mutex<Option<String>> = Mutex::new(None);

fn clear_progress_message() {
    *PROGRESS_MESSAGE.lock().unwrap_or_else(|e| e.into_inner()) = None;
}

/// Report progress of the current op: `permille` in 0..=1000 (or
/// [`PROGRESS_INDETERMINATE`]) and one of the `PHASE_*` constants. wasm also
/// forwards to the host sink; [`progress_permille`]/[`progress_phase`] read it back.
#[inline]
pub fn report_progress(permille: i32, phase: i32) {
    PROGRESS_PERMILLE.store(permille, Ordering::Relaxed);
    PROGRESS_PHASE.store(phase, Ordering::Relaxed);
    // The label belongs to the step that set it; letting it outlive that step
    // would mislabel whatever comes next.
    clear_progress_message();
    #[cfg(target_arch = "wasm32")]
    if let Some(f) = PROGRESS_SINK.with(|c| c.get()) {
        f(permille, phase);
    }
}

/// Last reported permille (0..=1000 or [`PROGRESS_INDETERMINATE`]).
pub fn progress_permille() -> i32 {
    PROGRESS_PERMILLE.load(Ordering::Relaxed)
}

/// Last reported phase (a `PHASE_*` constant).
pub fn progress_phase() -> i32 {
    PROGRESS_PHASE.load(Ordering::Relaxed)
}

/// Label the step in progress, for a host that shows it instead of the phase
/// label. Cleared by the next [`report_progress`], so report it after that one.
pub fn report_progress_message(message: &str) {
    let mut slot = PROGRESS_MESSAGE.lock().unwrap_or_else(|e| e.into_inner());
    *slot = if message.is_empty() { None } else { Some(message.to_owned()) };
}

/// Last reported step label, empty if none.
pub fn progress_message() -> String {
    PROGRESS_MESSAGE
        .lock()
        .unwrap_or_else(|e| e.into_inner())
        .clone()
        .unwrap_or_default()
}

// ── Step in progress, per thread ──────────────────────────────────────────────
//
// What each thread is in the middle of, for a crash report rather than a host:
// Rust's stack-overflow message names a thread only as it was named at spawn.
// Only a binary that installs no other fault handler should call
// `install_fatal_signal_report`: wasmtime recovers from SIGSEGV in JIT code, and
// every such trap would be reported as fatal.

/// Names what this thread is doing until the guard drops; printed if the
/// process dies of SIGSEGV or SIGBUS on this thread.
pub use step::{StepGuard, enter_step};

/// Chains in front of the current SIGSEGV/SIGBUS handlers -- in a Rust binary,
/// std's stack-overflow reporter.
pub use step::install_fatal_signal_report;

/// [`report_progress`], plus [`enter_step`] for the calling thread.
pub fn report_progress_step(permille: i32, phase: i32, what: &str) -> StepGuard {
    report_progress(permille, phase);
    enter_step(what)
}

#[cfg(all(unix, not(target_arch = "wasm32")))]
mod step {
    use std::cell::{Cell, UnsafeCell};
    use std::sync::atomic::{Ordering, compiler_fence};

    const CAPACITY: usize = 512;

    struct Context {
        len: Cell<usize>,
        bytes: UnsafeCell<[u8; CAPACITY]>,
    }

    thread_local! {
        // Const-initialised and without a destructor, so the signal handler
        // can read it without allocating.
        static CONTEXT: Context = const {
            Context { len: Cell::new(0), bytes: UnsafeCell::new([0; CAPACITY]) }
        };
    }

    fn store(what: &[u8]) {
        let len = what.len().min(CAPACITY);
        CONTEXT.with(|c| {
            c.len.set(0);
            compiler_fence(Ordering::SeqCst);
            // SAFETY: only this thread and its signal handler touch the
            // buffer, and the handler reads no further than `len`.
            unsafe { (&mut *c.bytes.get())[..len].copy_from_slice(&what[..len]) };
            compiler_fence(Ordering::SeqCst);
            c.len.set(len);
        });
    }

    fn current() -> Vec<u8> {
        CONTEXT.with(|c| unsafe { (&*c.bytes.get())[..c.len.get()].to_vec() })
    }

    pub struct StepGuard {
        previous: Vec<u8>,
    }

    impl Drop for StepGuard {
        fn drop(&mut self) {
            store(&self.previous);
        }
    }

    pub fn enter_step(what: &str) -> StepGuard {
        let previous = current();
        store(what.as_bytes());
        StepGuard { previous }
    }

    const SIGNALS: [libc::c_int; 2] = [libc::SIGSEGV, libc::SIGBUS];

    struct Previous(UnsafeCell<[libc::sigaction; 2]>);
    // SAFETY: written once, before the handler that reads it is installed.
    unsafe impl Sync for Previous {}
    static PREVIOUS: Previous = Previous(UnsafeCell::new(unsafe { std::mem::zeroed() }));

    fn write_all(mut bytes: &[u8]) {
        while !bytes.is_empty() {
            let n = unsafe { libc::write(2, bytes.as_ptr().cast(), bytes.len()) };
            if n <= 0 {
                return;
            }
            bytes = &bytes[n as usize..];
        }
    }

    extern "C" fn handler(sig: libc::c_int, info: *mut libc::siginfo_t, data: *mut libc::c_void) {
        let _ = CONTEXT.try_with(|c| {
            let len = c.len.get();
            if len > 0 {
                write_all(b"\nfatal signal while ");
                write_all(unsafe { &(&*c.bytes.get())[..len] });
                write_all(b"\n");
            }
        });
        let index = usize::from(sig != libc::SIGSEGV);
        let previous = unsafe { &(&*PREVIOUS.0.get())[index] };
        let action = previous.sa_sigaction;
        unsafe {
            if action == libc::SIG_DFL || action == libc::SIG_IGN {
                // Returning re-executes the faulting instruction, which now
                // takes the default action.
                let mut default: libc::sigaction = std::mem::zeroed();
                default.sa_sigaction = libc::SIG_DFL;
                libc::sigaction(sig, &default, std::ptr::null_mut());
            } else if previous.sa_flags & libc::SA_SIGINFO != 0 {
                let f: extern "C" fn(libc::c_int, *mut libc::siginfo_t, *mut libc::c_void) =
                    std::mem::transmute(action);
                f(sig, info, data);
            } else {
                let f: extern "C" fn(libc::c_int) = std::mem::transmute(action);
                f(sig);
            }
        }
    }

    pub fn install_fatal_signal_report() {
        static ONCE: std::sync::Once = std::sync::Once::new();
        ONCE.call_once(|| unsafe {
            let previous = &mut *PREVIOUS.0.get();
            for (sig, previous) in SIGNALS.into_iter().zip(previous.iter_mut()) {
                let mut action: libc::sigaction = std::mem::zeroed();
                action.sa_sigaction = handler as *const () as usize;
                action.sa_flags = libc::SA_SIGINFO | libc::SA_ONSTACK;
                libc::sigemptyset(&mut action.sa_mask);
                libc::sigaction(sig, &action, previous);
            }
        });
    }
}

#[cfg(not(all(unix, not(target_arch = "wasm32"))))]
mod step {
    pub struct StepGuard;

    pub fn enter_step(_what: &str) -> StepGuard {
        StepGuard
    }

    pub fn install_fatal_signal_report() {}
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;

    // The flag is process-global; this is the only test that touches it, so the
    // set/clear ordering here is deterministic.
    #[test]
    fn request_then_clear() {
        clear_cancel();
        assert!(!check_cancel());
        assert!(bail_if_cancelled().is_ok());

        request_cancel();
        assert!(check_cancel());
        assert!(bail_if_cancelled().is_err());

        clear_cancel();
        assert!(!check_cancel());
        assert!(bail_if_cancelled().is_ok());
    }

    #[test]
    fn progress_is_noop_native() {
        // Native has no sink; must not panic.
        report_progress(500, PHASE_PARSE);
    }

    #[test]
    fn progress_message_does_not_outlive_its_step() {
        report_progress(500, PHASE_BACKEND);
        report_progress_message("Building FMU for x86_64-w64-mingw32 (2/5)");
        assert_eq!(progress_message(), "Building FMU for x86_64-w64-mingw32 (2/5)");
        // The next step's report drops the previous step's label.
        report_progress(600, PHASE_BACKEND);
        assert_eq!(progress_message(), "");
    }
}
