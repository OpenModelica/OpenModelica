// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/ErrorExt.mo`'s `external "C"`
// declarations. The MetaModelica source defines this module purely as
// FFI shims into `OMCompiler/Compiler/runtime/errorext.cpp`, so the
// auto-generator emits `todo!()` stubs; we replace those with a real
// implementation here.
//
// The C++ side keeps one `errorext_members` per thread containing:
//
//   * `errorMessageQueue`        — deque of pending messages
//   * `checkPoints`              — stack of (queue_position, id) pairs
//   * `numErrorMessages`         — running count of ERROR/INTERNAL severities
//   * `numWarningMessages`       — running count of WARNING severities
//   * `lastDeletedCheckpoint`    — last id passed to `delCheckpoint` (used
//                                   to provide diagnostic context for stack
//                                   underflow assertions)
//   * `showErrorMessages`        — when true, every message is also echoed
//                                   to stderr at push time
//   * `pop_more_on_rollback`     — duplicate-suppression flag used by
//                                   `pop_message` during `rollBack`
//
// We mirror that state in a `thread_local!` `RefCell` so the Rust port
// preserves the per-thread isolation that the bootstrap depends on. The
// generated code never touches `threadData_t` directly (the codegen drops
// the `OpenModelica.threadData()` argument when lowering the external
// call), so the Rust API is parameterless.
//
// Functions that need richer runtime support than the message buffer
// alone (currently `registerModelicaFormatError`, `initAssertionFunctions`,
// and `moveMessagesToParentThread`) are intentionally left as no-ops —
// the bootstrap compiler does not use them, and the doc-comment on each
// records the C++ behavior we are forgoing.

#![allow(non_snake_case)]

use std::cell::RefCell;
use std::sync::Arc;

use arcstr::ArcStr;
use metamodelica::{List, SourceInfo, nil, cons};

use crate::ErrorTypes::{Message, Severity, MessageType, TotalMessage};

/// One slot in the per-thread error queue.
///
/// Stored separately from the `TotalMessage` we hand out to MetaModelica
/// callers so we can keep the original (untranslated) `tokens` list around
/// for `printMessagesStr` and friends without forcing every reader to
/// reach into the message's source info.
#[derive(Clone, Debug)]
struct QueuedMessage {
    msg: Message,
    tokens: Arc<List<ArcStr>>,
    info: SourceInfo,
}

impl QueuedMessage {
    /// Mirrors `get_message_alloc` in `errorext.cpp`: the message handed
    /// back to MetaModelica carries the token-substituted text (the C++
    /// `veryshort_msg`), not the raw `%s`/`%1` template.
    fn as_total(&self) -> TotalMessage {
        let mut msg = self.msg.clone();
        msg.message = ArcStr::from(self.substituted_body());
        TotalMessage { msg, info: self.info.clone() }
    }

    /// Mirrors `ErrorMessage::getShortMessage()` (`veryshort_msg`): the
    /// token-substituted message body without any position prefix.
    fn substituted_body(&self) -> String {
        substitute_tokens(&self.msg.message, &self.tokens)
    }

    /// Mirrors `ErrorMessage::getMessage_()`: the token-substituted text
    /// with the `[file:line:col-line:col:writable] Severity: ` prefix, or
    /// just `Severity: ` when there is no source location, with trailing
    /// whitespace trimmed. This is what `printMessagesStr` and friends
    /// render.
    fn rendered(&self, warnings_as_errors: bool) -> String {
        let body = self.substituted_body();
        let severity = if warnings_as_errors && matches!(self.msg.severity, Severity::WARNING) {
            severity_label(&Severity::ERROR)
        } else {
            severity_label(&self.msg.severity)
        };
        let info = &self.info;
        let mut out = if info.fileName.is_empty()
            && info.lineNumberStart == 0
            && info.columnNumberStart == 0
            && info.lineNumberEnd == 0
            && info.columnNumberEnd == 0
        {
            format!("{severity}: {body}")
        } else {
            format!(
                "[{}:{}:{}-{}:{}:{}] {}: {}",
                info.fileName,
                info.lineNumberStart,
                info.columnNumberStart,
                info.lineNumberEnd,
                info.columnNumberEnd,
                if info.isReadOnly { "readonly" } else { "writable" },
                severity,
                body,
            )
        };
        out.truncate(out.trim_end_matches([' ', '\n', '\r', '\t']).len());
        out
    }

    /// Mirrors `ErrorMessage::getFullMessage()`: a `{"msg", "TYPE",
    /// "Severity", "id"}` tuple string. Used for `pop_message`'s
    /// consecutive-duplicate suppression and the `showErrorMessages` echo.
    fn full_message(&self) -> String {
        format!(
            "{{\"{}\", \"{}\", \"{}\", \"{}\"}}",
            self.rendered(false),
            message_type_label(&self.msg.ty),
            severity_label(&self.msg.severity),
            self.msg.id,
        )
    }
}

/// Substitute placeholders with the supplied tokens, mirroring
/// `ErrorMessage::getMessage_()`: `%s` consumes tokens sequentially while
/// `%1`–`%9` index into the token list (1-based). Both styles may be mixed
/// in one template. On a missing token the C++ side prints an internal
/// error to stderr and renders the message as the empty string — we
/// preserve that so test output matches.
fn substitute_tokens(template: &str, tokens: &Arc<List<ArcStr>>) -> String {
    let toks: Vec<&ArcStr> = {
        let mut v = Vec::new();
        let mut cur = tokens;
        while let List::Cons { head, tail } = &**cur {
            v.push(head);
            cur = tail;
        }
        v
    };
    let mut out = String::with_capacity(template.len());
    let mut chars = template.chars().peekable();
    let mut next_seq = 0usize;
    while let Some(c) = chars.next() {
        if c == '%' {
            match chars.peek() {
                Some('s') => {
                    chars.next();
                    let Some(tok) = toks.get(next_seq) else {
                        eprintln!("Internal error: no tokens left to replace %s with.");
                        eprintln!("Given message was: {template}");
                        return String::new();
                    };
                    next_seq += 1;
                    out.push_str(tok);
                    continue;
                }
                Some(&d) if d.is_ascii_digit() => {
                    chars.next();
                    // `%0` underflows to an invalid index, matching C++.
                    let Some(tok) = (d as usize)
                        .checked_sub('0' as usize + 1)
                        .and_then(|i| toks.get(i))
                    else {
                        eprintln!(
                            "Internal error: Invalid positional index %{d} in error message."
                        );
                        eprintln!("Given message was: {template}");
                        return String::new();
                    };
                    out.push_str(tok);
                    continue;
                }
                _ => {}
            }
        }
        out.push(c);
    }
    out
}

fn severity_label(s: &Severity) -> &'static str {
    match s {
        Severity::INTERNAL => "Internal error",
        Severity::ERROR => "Error",
        Severity::WARNING => "Warning",
        Severity::NOTIFICATION => "Notification",
    }
}

/// Mirrors `ErrorType_toStr` in `errorext.cpp`. Note that the
/// MetaModelica constructor `SIMULATION` corresponds to the C enum value
/// `ErrorType_runtime`, which prints as `RUNTIME`.
fn message_type_label(t: &MessageType) -> &'static str {
    match t {
        MessageType::SYNTAX => "SYNTAX",
        MessageType::GRAMMAR => "GRAMMAR",
        MessageType::TRANSLATION => "TRANSLATION",
        MessageType::SYMBOLIC => "SYMBOLIC",
        MessageType::SIMULATION => "RUNTIME",
        MessageType::SCRIPTING => "SCRIPTING",
    }
}

#[derive(Default)]
struct State {
    queue: Vec<QueuedMessage>,
    /// Stack of (queue_length_at_set_time, id) pairs.
    check_points: Vec<(usize, ArcStr)>,
    num_errors: i32,
    num_warnings: i32,
    last_deleted_checkpoint: ArcStr,
    show_messages: bool,
}

thread_local! {
    static STATE: RefCell<State> = RefCell::new(State::default());
}

fn with_state<R>(f: impl FnOnce(&mut State) -> R) -> R {
    STATE.with(|s| f(&mut s.borrow_mut()))
}

fn bump_counters(state: &mut State, severity: &Severity, delta: i32) {
    match severity {
        Severity::ERROR | Severity::INTERNAL => state.num_errors += delta,
        Severity::WARNING => state.num_warnings += delta,
        Severity::NOTIFICATION => {}
    }
}

/// Mirrors `pop_message` in `errorext.cpp`: remove the newest queued
/// message *and any consecutive duplicates of it* (same
/// [`QueuedMessage::full_message`]), updating the severity counters.
/// During a rollback the duplicate scan stops at the topmost checkpoint
/// so messages belonging to the parent transaction survive.
///
/// Returns the popped message (the C++ version's callers read `back()`
/// before calling it instead).
fn pop_message(state: &mut State, rollback: bool) -> Option<QueuedMessage> {
    let msg = state.queue.pop()?;
    bump_counters(state, &msg.msg.severity, -1);
    let key = msg.full_message();
    loop {
        if rollback {
            let boundary = state.check_points.last().map(|(p, _)| *p).unwrap_or(0);
            if state.queue.len() <= boundary {
                break;
            }
        }
        match state.queue.last() {
            Some(next) if next.full_message() == key => {
                let dup = state.queue.pop().unwrap();
                bump_counters(state, &dup.msg.severity, -1);
            }
            _ => break,
        }
    }
    Some(msg)
}

// ---------------------------------------------------------------------------
// Public API — matches the signatures the auto-generated stub used to have.
// All return types stay `()` / plain primitives because the upstream
// MetaModelica declarations are `external "C"` with no `failure` clause.
// ---------------------------------------------------------------------------

/// Push a new diagnostic onto the per-thread queue.
pub fn addSourceMessage(
    id: i32,
    msg_type: MessageType,
    msg_severity: Severity,
    sline: i32,
    scol: i32,
    eline: i32,
    ecol: i32,
    read_only: bool,
    filename: ArcStr,
    msg: ArcStr,
    tokens: Arc<List<ArcStr>>,
) {
    let entry = QueuedMessage {
        msg: Message {
            id,
            ty: msg_type,
            severity: msg_severity.clone(),
            // The C++ side stores the rendered message verbatim.
            message: msg.clone(),
        },
        tokens,
        info: SourceInfo {
            fileName: filename,
            isReadOnly: read_only,
            lineNumberStart: sline,
            columnNumberStart: scol,
            lineNumberEnd: eline,
            columnNumberEnd: ecol,
            lastModification: metamodelica::OrderedFloat(0.0),
        },
    };
    with_state(|s| {
        if s.show_messages {
            // `--showErrorMessages`: echo at push time. Route through the host
            // stderr sink so the echo reaches the JS console on wasm (a bare
            // `eprintln!` is discarded there).
            metamodelica::host_eprint(&format!("{}\n", entry.full_message()));
        }
        bump_counters(s, &msg_severity, 1);
        s.queue.push(entry);
    });
}

pub fn clearMessages() {
    // The C++ `ErrorImpl__clearMessages` drains the queue but leaves the
    // checkpoint stack alone, so a caller holding an open checkpoint can
    // still delCheckpoint/rollBack it afterwards. Stored positions may now
    // exceed the queue length; every consumer clamps with `.min(len)`.
    with_state(|s| {
        s.queue.clear();
        s.num_errors = 0;
        s.num_warnings = 0;
    });
}

/// Pop the topmost checkpoint without affecting messages added after it.
///
/// `id` is recorded in `last_deleted_checkpoint` so that subsequent stack
/// underflow can produce a helpful diagnostic — the C++ side does the
/// same dance.
pub fn delCheckpoint(id: ArcStr) {
    with_state(|s| {
        if s.check_points.pop().is_none() {
            // Stack underflow — match C++ by printing to stderr instead of
            // panicking so the surrounding compilation continues.
            eprintln!("ErrorExt.delCheckpoint: no checkpoint to delete (id={id})");
        }
        s.last_deleted_checkpoint = id;
    });
}

/// Pop the topmost `n` checkpoints. Used to unwind after a stack-overflow
/// exception where the matching `delCheckpoint`s were skipped.
pub fn deleteNumCheckpoints(n: i32) {
    with_state(|s| {
        for _ in 0..n.max(0) {
            if s.check_points.pop().is_none() {
                break;
            }
        }
    });
}

/// Free a previously `popCheckPoint`-saved list of message handles.
///
/// In the C++ runtime each handle is a raw `ErrorMessage*` heap pointer
/// that must be `delete`d. In Rust the `QueuedMessage` lives by value, so
/// there is nothing to free — the handle list is purely an opaque
/// MetaModelica value we no longer reference once it is dropped.
pub fn freeMessages(_handles: Arc<List<i32>>) {
    // Intentionally empty — see doc comment.
}

/// Drain and return the messages added since the most recent checkpoint,
/// oldest first. Like `ErrorImpl__getCheckpointMessages` this *consumes*
/// the messages (popping consecutive duplicates as it goes); callers that
/// want to keep them re-add via `Error.addTotalMessages`.
pub fn getCheckpointMessages() -> Arc<List<TotalMessage>> {
    with_state(|s| {
        let mut out = nil::<TotalMessage>();
        let Some(&(boundary, _)) = s.check_points.last() else {
            return out;
        };
        while s.queue.len() > boundary {
            // Render before popping — `pop_message` may also remove
            // consecutive duplicates that we only want to emit once.
            let total = s.queue.last().unwrap().as_total();
            out = cons(total, out);
            pop_message(s, false);
        }
        out
    })
}

/// Drain and return all queued messages, oldest first (the newest message
/// is consed last in `ErrorImpl__getMessages`, ending up at the tail).
pub fn getMessages() -> Arc<List<TotalMessage>> {
    with_state(|s| {
        let mut out = nil::<TotalMessage>();
        while !s.queue.is_empty() {
            let total = s.queue.last().unwrap().as_total();
            out = cons(total, out);
            pop_message(s, false);
        }
        out
    })
}

pub fn getNumCheckpoints() -> i32 {
    with_state(|s| s.check_points.len() as i32)
}

pub fn getNumErrorMessages() -> i32 {
    with_state(|s| s.num_errors)
}

pub fn getNumMessages() -> i32 {
    with_state(|s| s.queue.len() as i32)
}

pub fn getNumWarningMessages() -> i32 {
    with_state(|s| s.num_warnings)
}

/// Register OMC's `assert(...)` family to route output through the
/// error buffer instead of stdout. The bootstrap compiler never relies
/// on this redirection (it always reads errors back through the queue
/// directly), so we leave it as a no-op.
pub fn initAssertionFunctions() {
    // Mirror `Error_initAssertionFunctions` (`runtime/Error_omc.cpp`): bind the
    // runtime's `omc_assert` reporter to `omc_assert_compiler`'s behaviour, so
    // that assertions raised by metamodelica runtime functions (e.g.
    // `uriToFilename`) append a `RUNTIME`/`Error` message to the buffer before
    // the assertion fails. The message carries no source position, so it
    // renders as `Error: <msg>`, exactly like the C compiler.
    metamodelica::setAssertHook(add_runtime_error_message);
    // Also request that the dlopened C runtime's `omc_assert` be rebound (see
    // `dynload::ensure_runtime`), so assertions raised inside an evaluated
    // external function reach the buffer instead of the default
    // `omc_assert_function` stderr print.
    ASSERT_FUNCTIONS_REGISTERED.store(true, std::sync::atomic::Ordering::Relaxed);
}

/// Append a positionless `RUNTIME`/`Error` message to the buffer — the analogue
/// of `c_add_message(NULL, 0, ErrorType_runtime, ErrorLevel_error, str, ...)`.
/// With no source location it renders as `Error: <msg>`, matching the C
/// compiler. Shared by the `omc_assert` hook and the external-function
/// `ModelicaError`/`ModelicaFormatError` interception (see
/// [`registerModelicaFormatError`]).
fn add_runtime_error_message(msg: &str) {
    addSourceMessage(
        0,
        MessageType::SIMULATION, // C `ErrorType_runtime` → prints as RUNTIME
        Severity::ERROR,
        0,
        0,
        0,
        0,
        false,
        ArcStr::from(""),
        ArcStr::from(msg),
        nil(),
    );
}

/// Whether [`initAssertionFunctions`] ran and so the dlopened runtime's
/// `omc_assert` should be rebound (the rebinding happens in
/// `dynload::ensure_runtime`, once the runtime is loaded).
static ASSERT_FUNCTIONS_REGISTERED: std::sync::atomic::AtomicBool =
    std::sync::atomic::AtomicBool::new(false);

/// Read by `dynload::ensure_runtime` to decide whether to rebind `omc_assert`.
pub fn assertFunctionsRegistered() -> bool {
    ASSERT_FUNCTIONS_REGISTERED.load(std::sync::atomic::Ordering::Relaxed)
}

/// Exported for the C interception shim (`src/runtime_error_shim.c`): append an
/// `omc_assert` message — carrying the assertion's source position — to the
/// error buffer. An empty `filename` with zero positions renders as
/// `Error: <msg>`.
///
/// # Safety
/// `msg`/`filename` must be valid NUL-terminated C strings for the call.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omrs_add_runtime_error_pos(
    msg: *const std::os::raw::c_char,
    filename: *const std::os::raw::c_char,
    sline: std::os::raw::c_int,
    scol: std::os::raw::c_int,
    eline: std::os::raw::c_int,
    ecol: std::os::raw::c_int,
    read_only: std::os::raw::c_int,
) {
    if msg.is_null() {
        return;
    }
    let text = unsafe { std::ffi::CStr::from_ptr(msg) }.to_string_lossy();
    let file = if filename.is_null() {
        ArcStr::from("")
    } else {
        ArcStr::from(unsafe { std::ffi::CStr::from_ptr(filename) }.to_string_lossy().as_ref())
    };
    addSourceMessage(
        0,
        MessageType::SIMULATION, // C `ErrorType_runtime` → prints as RUNTIME
        Severity::ERROR,
        sline,
        scol,
        eline,
        ecol,
        read_only != 0,
        file,
        ArcStr::from(text.as_ref()),
        nil(),
    );
}

/// Whether the host requested `ModelicaError`/`ModelicaFormatError` interception
/// (i.e. [`registerModelicaFormatError`] ran). The rebinding itself happens in
/// `dynload::ensure_runtime`, once the C runtime that owns the
/// `OpenModelica_Modelica*Error` function pointers has been loaded.
static MODELICA_ERROR_REGISTERED: std::sync::atomic::AtomicBool =
    std::sync::atomic::AtomicBool::new(false);

/// Whether [`registerModelicaFormatError`] has been called. Read by
/// `dynload::ensure_runtime` to decide whether to rebind the runtime pointers.
pub fn modelicaFormatErrorRegistered() -> bool {
    MODELICA_ERROR_REGISTERED.load(std::sync::atomic::Ordering::Relaxed)
}

/// Exported for the C interception shim (`src/runtime_error_shim.c`): append a
/// `ModelicaError`/`ModelicaFormatError` message raised inside an evaluated
/// external function to the error buffer.
///
/// # Safety
/// `msg` must be a valid NUL-terminated C string for the duration of the call.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn omrs_add_runtime_error(msg: *const std::os::raw::c_char) {
    if msg.is_null() {
        return;
    }
    let text = unsafe { std::ffi::CStr::from_ptr(msg) }.to_string_lossy();
    add_runtime_error_message(&text);
}

pub fn isTopCheckpoint(id: ArcStr) -> bool {
    with_state(|s| s.check_points.last().map(|(_, cid)| cid == &id).unwrap_or(false))
}

/// Hand off pending messages to the parent thread's queue when a worker
/// thread terminates. The bootstrap is single-threaded with respect to
/// the error buffer, so there is no parent to merge into.
pub fn moveMessagesToParentThread() {
    // Intentional no-op — see doc comment.
}

/// Roll back the messages added since the most recent checkpoint and
/// return their ids in a list so the caller can re-push them later
/// via [`pushMessages`].
///
/// The returned list of "handles" mirrors the C++ runtime's `void*` queue
/// of detached `ErrorMessage*`s; on the Rust side it is stored in a
/// thread-local side table keyed by an opaque integer.
pub fn popCheckPoint(id: ArcStr) -> Arc<List<i32>> {
    with_state(|s| {
        let start = s.check_points.last().map(|(p, _)| *p).unwrap_or(0);
        if !s.check_points.last().map(|(_, cid)| cid == &id).unwrap_or(false) {
            eprintln!(
                "ErrorExt.popCheckPoint: id mismatch (expected {:?}, got {id:?})",
                s.check_points.last().map(|(_, cid)| cid.as_str()),
            );
        }
        let detached: Vec<QueuedMessage> =
            s.queue.drain(start.min(s.queue.len())..).collect();
        for d in &detached {
            bump_counters(s, &d.msg.severity, -1);
        }
        s.check_points.pop();
        let mut handles = nil::<i32>();
        for d in detached.into_iter().rev() {
            let h = store_detached(d);
            handles = cons(h, handles);
        }
        handles
    })
}

/// Drain and render the messages added since the most recent checkpoint,
/// oldest first, one per line. Returns "" (without draining anything)
/// when no checkpoint is set — mirrors
/// `ErrorImpl__printCheckpointMessagesStr`.
pub fn printCheckpointMessagesStr(warningsAsErrors: bool) -> ArcStr {
    with_state(|s| {
        let Some(&(boundary, _)) = s.check_points.last() else {
            return ArcStr::from("");
        };
        let mut out = String::new();
        while s.queue.len() > boundary {
            let line = s.queue.last().unwrap().rendered(warningsAsErrors);
            out.insert(0, '\n');
            out.insert_str(0, &line);
            pop_message(s, false);
        }
        ArcStr::from(out)
    })
}

/// Drain the whole queue, rendering only ERROR/INTERNAL messages (oldest
/// first); warnings and notifications are discarded. Unlike the other
/// drains this does *not* suppress consecutive duplicates — the C++
/// `ErrorImpl__printErrorsNoWarning` pops each entry individually. (The
/// C++ version also forgets to decrement `numWarningMessages` for the
/// discarded warnings; we keep the counters consistent instead.)
pub fn printErrorsNoWarning() -> ArcStr {
    with_state(|s| {
        let mut out = String::new();
        while let Some(m) = s.queue.pop() {
            bump_counters(s, &m.msg.severity, -1);
            if matches!(m.msg.severity, Severity::ERROR | Severity::INTERNAL) {
                out.insert(0, '\n');
                out.insert_str(0, &m.rendered(false));
            }
        }
        ArcStr::from(out)
    })
}

/// Drain the whole queue and render it oldest first, one message per
/// line, suppressing consecutive duplicates — mirrors
/// `ErrorImpl__printMessagesStr`.
pub fn printMessagesStr(warningsAsErrors: bool) -> ArcStr {
    with_state(|s| {
        let mut out = String::new();
        while !s.queue.is_empty() {
            let line = s.queue.last().unwrap().rendered(warningsAsErrors);
            out.insert(0, '\n');
            out.insert_str(0, &line);
            pop_message(s, false);
        }
        ArcStr::from(out)
    })
}

/// Push previously [`popCheckPoint`]-detached handles back onto the queue.
pub fn pushMessages(handles: Arc<List<i32>>) {
    let mut cur = handles;
    let mut batch = Vec::new();
    while let List::Cons { head, tail } = &*cur {
        if let Some(d) = take_detached(*head) {
            batch.push(d);
        }
        cur = tail.clone();
    }
    with_state(|s| {
        for d in batch {
            bump_counters(s, &d.msg.severity, 1);
            s.queue.push(d);
        }
    });
}

/// Mirror `Error_registerModelicaFormatError` (`runtime/Error_omc.cpp`): make
/// `ModelicaError`/`ModelicaFormatError` raised inside an evaluated external C
/// function route to the error buffer (as a `RUNTIME`/`Error` message) rather
/// than only streaming to the simulation log.
///
/// The C compiler rebinds the `OpenModelica_Modelica{,V}FormatError` function
/// pointers here directly, because it links the runtime statically. The Rust
/// port dlopens the runtime lazily, so the pointers do not exist yet; we only
/// record the request and let `dynload::ensure_runtime` perform the rebinding
/// once the runtime is loaded (see [`modelicaFormatErrorRegistered`]).
pub fn registerModelicaFormatError() {
    MODELICA_ERROR_REGISTERED.store(true, std::sync::atomic::Ordering::Relaxed);
}

/// Roll back messages added since the most recent checkpoint and discard
/// them. The checkpoint itself is removed.
pub fn rollBack(_id: ArcStr) {
    with_state(|s| {
        if let Some((start, _)) = s.check_points.pop() {
            let drained = s.queue.split_off(start.min(s.queue.len()));
            for d in &drained {
                bump_counters(s, &d.msg.severity, -1);
            }
        }
    });
}

pub fn rollbackNumCheckpoints(n: i32) {
    with_state(|s| {
        for _ in 0..n.max(0) {
            if let Some((start, _)) = s.check_points.pop() {
                let drained = s.queue.split_off(start.min(s.queue.len()));
                for d in &drained {
                    bump_counters(s, &d.msg.severity, -1);
                }
            }
        }
    });
}

pub fn setCheckpoint(id: ArcStr) {
    with_state(|s| {
        let pos = s.queue.len();
        s.check_points.push((pos, id));
    });
}

pub fn setShowErrorMessages(inShow: bool) {
    with_state(|s| s.show_messages = inShow);
}

// ---------------------------------------------------------------------------
// Detached-message handle table.
//
// `popCheckPoint` hands MetaModelica callers an opaque integer handle for
// each detached message; `pushMessages` later trades that handle back for
// the original `QueuedMessage`. The C++ runtime stores raw heap pointers
// here, but Rust forbids transmuting an owned value through an `i32`, so
// we use a thread-local sparse table instead. Handles are monotonically
// increasing within a thread so there is no aliasing across detach/attach
// cycles even if a caller leaks them.
// ---------------------------------------------------------------------------

thread_local! {
    static DETACHED: RefCell<DetachedTable> = RefCell::new(DetachedTable::default());
}

#[derive(Default)]
struct DetachedTable {
    next_id: i32,
    slots: std::collections::HashMap<i32, QueuedMessage>,
}

fn store_detached(m: QueuedMessage) -> i32 {
    DETACHED.with(|d| {
        let mut d = d.borrow_mut();
        // Skip 0 so the value never collides with the C runtime's NULL
        // sentinel — callers that round-trip through C-style code paths
        // (none in the bootstrap, but cheap to preserve) can treat 0 as
        // "no handle".
        d.next_id = d.next_id.wrapping_add(1);
        if d.next_id == 0 {
            d.next_id = 1;
        }
        let id = d.next_id;
        d.slots.insert(id, m);
        id
    })
}

fn take_detached(id: i32) -> Option<QueuedMessage> {
    DETACHED.with(|d| d.borrow_mut().slots.remove(&id))
}
