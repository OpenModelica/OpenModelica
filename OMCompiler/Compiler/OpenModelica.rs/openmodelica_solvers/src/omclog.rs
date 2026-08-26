//! C's `util/omc_error.c`: the `-lv` stream table and the message layout.
//!
//! The layout is stateful, so it is not a per-line prefix: a stream carries an
//! indentation level that `indent_next` raises and [`close`] lowers, and the
//! stream/type columns collapse to `|` when the previous line came from the same
//! stream at a level above zero. [`message_text`] is C's `messageText`, subline
//! recursion over embedded newlines included.

use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;

/// Index into [`STREAM_NAME`], i.e. C's `OMC_LOG_*` enumerators.
pub type Stream = u8;

/// C's `OMC_LOG_STREAM_NAME`, in the order the `-lv` parser and the mask index by.
pub const STREAM_NAME: [&str; 57] = [
    "LOG_UNKNOWN",
    "LOG_STDOUT",
    "LOG_ASSERT",
    "LOG_DASSL",
    "LOG_DASSL_STATES",
    "LOG_DEBUG",
    "LOG_DELAY",
    "LOG_DIVISION",
    "LOG_DSS",
    "LOG_DSS_JAC",
    "LOG_DT",
    "LOG_DT_CONS",
    "LOG_EVENTS",
    "LOG_EVENTS_V",
    "LOG_GBODE",
    "LOG_GBODE_V",
    "LOG_GBODE_NLS",
    "LOG_GBODE_NLS_V",
    "LOG_GBODE_STATES",
    "LOG_INIT",
    "LOG_INIT_HOMOTOPY",
    "LOG_INIT_V",
    "LOG_IPOPT",
    "LOG_IPOPT_FULL",
    "LOG_IPOPT_JAC",
    "LOG_IPOPT_HESSE",
    "LOG_IPOPT_ERROR",
    "LOG_JAC",
    "LOG_LS",
    "LOG_LS_V",
    "LOG_MIXED",
    "LOG_MOO",
    "LOG_NLS",
    "LOG_NLS_V",
    "LOG_NLS_HOMOTOPY",
    "LOG_NLS_JAC",
    "LOG_NLS_JAC_TEST",
    "LOG_NLS_JAC_SUMS",
    "LOG_NLS_NEWTON_DIAGNOSTICS",
    "LOG_NLS_DERIVATIVE_TEST",
    "LOG_NLS_SVD",
    "LOG_NLS_SVD_V",
    "LOG_NLS_RES",
    "LOG_NLS_EXTRAPOLATE",
    "LOG_RES_INIT",
    "LOG_RT",
    "LOG_SIMULATION",
    "LOG_SOLVER",
    "LOG_SOLVER_V",
    "LOG_SOLVER_CONTEXT",
    "LOG_SOTI",
    "LOG_SPATIALDISTR",
    "LOG_STATS",
    "LOG_STATS_V",
    "LOG_SUCCESS",
    "LOG_SYNCHRONOUS",
    "LOG_ZEROCROSSINGS",
];

pub const N_STREAMS: usize = STREAM_NAME.len();

pub const UNKNOWN: Stream = 0;
pub const STDOUT: Stream = 1;
pub const ASSERT: Stream = 2;
pub const DASSL: Stream = 3;
pub const DEBUG: Stream = 5;
pub const DELAY: Stream = 6;
pub const DIVISION: Stream = 7;
pub const DSS: Stream = 8;
pub const DSS_JAC: Stream = 9;
pub const DT: Stream = 10;
pub const DT_CONS: Stream = 11;
pub const EVENTS: Stream = 12;
pub const EVENTS_V: Stream = 13;
pub const INIT: Stream = 19;
pub const INIT_HOMOTOPY: Stream = 20;
pub const INIT_V: Stream = 21;
pub const IPOPT: Stream = 22;
pub const IPOPT_FULL: Stream = 23;
pub const IPOPT_JAC: Stream = 24;
pub const IPOPT_HESSE: Stream = 25;
pub const IPOPT_ERROR: Stream = 26;
pub const JAC: Stream = 27;
pub const LS: Stream = 28;
pub const LS_V: Stream = 29;
pub const NLS: Stream = 32;
pub const NLS_V: Stream = 33;
pub const NLS_HOMOTOPY: Stream = 34;
pub const NLS_JAC: Stream = 35;
pub const NLS_RES: Stream = 42;
pub const NLS_EXTRAPOLATE: Stream = 43;
pub const SIMULATION: Stream = 46;
pub const SOLVER: Stream = 47;
pub const SOLVER_V: Stream = 48;
pub const SOTI: Stream = 50;
pub const SPATIALDISTR: Stream = 51;
pub const STATS: Stream = 52;
pub const STATS_V: Stream = 53;
pub const SUCCESS: Stream = 54;
pub const SYNCHRONOUS: Stream = 55;
pub const ZEROCROSSINGS: Stream = 56;

/// C's `OMC_LOG_TYPE_*` / `OMC_LOG_TYPE_DESC`.
pub type LogType = u8;
pub const INFO: LogType = 1;
pub const WARNING: LogType = 2;
pub const ERROR: LogType = 3;
pub const DEBUG_TYPE: LogType = 5;
const TYPE_DESC: [&str; 6] = ["unknown", "info", "warning", "error", "assert", "debug"];

/// Bit `s` set = stream `s` is on: C's `omc_useStream`, packed so a run can push it
/// into the wasm runtime as one value.
pub type Mask = u64;

/// The three streams C activates without `-lv`, and which [`deactivate`] leaves.
pub const ALWAYS_ON: Mask = (1 << STDOUT) | (1 << ASSERT) | (1 << SUCCESS);

/// What an FMU has on for its whole life: `initDumpSystem` never runs there, so
/// `omc_useStream` is a zeroed static and `fmi2Instantiate` turns these two on.
/// `fmi2SetDebugLogging` does not touch them.
pub const FMU_STREAMS: Mask = (1 << STDOUT) | (1 << ASSERT);

/// C's `omc_showAllWarnings` (`-w`): a warning prints even on an inactive stream.
/// It rides in the mask, above every stream index, so the single value a run pushes
/// into the wasm runtime carries it too.
pub const SHOW_ALL_WARNINGS: Mask = 1 << 63;

pub fn mask_has(m: Mask, s: Stream) -> bool {
    m & (1 << s) != 0
}

/// C's `setGlobalVerboseLevel`: `LOG_ALL`, the `-`-prefixed disable form, then the
/// implications below. An unrecognized name is C's fatal `unrecognized option -lv`.
pub fn mask_from_streams<S: AsRef<str>>(streams: &[S]) -> Result<Mask, String> {
    let mut m = ALWAYS_ON;
    if streams.is_empty() {
        return Ok(m);
    }
    // C re-enables only these two, so `-lv=-LOG_SUCCESS` does what it promises.
    m |= (1 << STDOUT) | (1 << ASSERT);
    if streams.iter().any(|s| s.as_ref().contains("LOG_ALL")) {
        return Ok(finish(((1 << N_STREAMS) - 1) & !1));
    }
    for s in streams {
        let s = s.as_ref();
        let (on, name) = match s.strip_prefix('-') {
            Some(rest) => (false, rest),
            None => (true, s),
        };
        // C searches from `firstOMCErrorStream`, so `LOG_UNKNOWN` is not selectable.
        let Some(i) = STREAM_NAME.iter().skip(1).position(|n| *n == name).map(|p| p + 1) else {
            return Err(format!("unrecognized option -lv {s}"));
        };
        if on {
            m |= 1 << i;
        } else {
            m &= !(1 << i);
        }
    }
    Ok(finish(m))
}

/// `setGlobalVerboseLevel`'s "print X if Y is active" implications, in its order
/// (`LOG_INIT_V` reaches `LOG_INIT_HOMOTOPY` through `LOG_INIT`).
fn finish(mut m: Mask) -> Mask {
    const GBODE: Stream = 14;
    const GBODE_V: Stream = 15;
    const GBODE_NLS: Stream = 16;
    const GBODE_NLS_V: Stream = 17;
    for (from, to) in [
        (GBODE_V, GBODE),
        (GBODE_NLS_V, GBODE_NLS),
        (INIT_V, INIT),
        (INIT_V, SOTI),
        (INIT, INIT_HOMOTOPY),
        (SOLVER_V, SOLVER),
        (SOLVER, STATS),
        (STATS_V, STATS),
        (NLS_V, NLS),
        (NLS_RES, NLS),
        (NLS_JAC, NLS),
        (EVENTS_V, EVENTS),
        (DSS_JAC, DSS),
    ] {
        if mask_has(m, from) {
            m |= 1 << to;
        }
    }
    m
}

/// C's `omc_level`/`omc_lastType`/`omc_lastStream`/`omc_useStream` + its backup.
struct State {
    use_stream: Mask,
    backup: Mask,
    streams_active: bool,
    level: [i16; N_STREAMS],
    last_type: [LogType; N_STREAMS],
    last_stream: Stream,
    /// `-logFormat=xml`: C's `setStreamPrintXML(1)`.
    xml: bool,
}

impl State {
    const fn new() -> Self {
        State {
            use_stream: ALWAYS_ON,
            backup: 0,
            streams_active: true,
            level: [0; N_STREAMS],
            last_type: [0; N_STREAMS],
            last_stream: UNKNOWN,
            xml: false,
        }
    }
}

mod store {
    use super::State;

    #[cfg(feature = "std")]
    mod imp {
        use super::State;
        use core::cell::RefCell;
        std::thread_local! {
            static STATE: RefCell<State> = const { RefCell::new(State::new()) };
        }
        pub fn with<R>(f: impl FnOnce(&mut State) -> R) -> R {
            STATE.with(|c| f(&mut c.borrow_mut()))
        }
    }

    #[cfg(not(feature = "std"))]
    mod imp {
        use super::State;
        use core::cell::UnsafeCell;
        // Single-threaded in-wasm runtime, as `driver::overrides_store`.
        struct Store(UnsafeCell<State>);
        unsafe impl Sync for Store {}
        static STATE: Store = Store(UnsafeCell::new(State::new()));
        pub fn with<R>(f: impl FnOnce(&mut State) -> R) -> R {
            f(unsafe { &mut *STATE.0.get() })
        }
    }

    pub use imp::with;
}

/// Where [`crate::driver::log_line`] puts a line while a capture is open. Same
/// storage pattern as [`store`]: thread-local under `std`, a static in-wasm.
mod capture_store {
    #[cfg(feature = "std")]
    mod imp {
        use alloc::string::String;
        use core::cell::RefCell;
        std::thread_local! {
            static BUF: RefCell<Option<String>> = const { RefCell::new(None) };
        }
        pub fn with<R>(f: impl FnOnce(&mut Option<String>) -> R) -> R {
            BUF.with(|c| f(&mut c.borrow_mut()))
        }
    }

    #[cfg(not(feature = "std"))]
    mod imp {
        use alloc::string::String;
        use core::cell::UnsafeCell;
        struct Store(UnsafeCell<Option<String>>);
        unsafe impl Sync for Store {}
        static BUF: Store = Store(UnsafeCell::new(None));
        pub fn with<R>(f: impl FnOnce(&mut Option<String>) -> R) -> R {
            f(unsafe { &mut *BUF.0.get() })
        }
    }

    pub use imp::with;
}

/// Start diverting log lines into a buffer. `-reconcile` runs while the model is
/// still alive but prints after the run's success line, so its lines are held here
/// until the caller places them.
pub fn start_capture() {
    capture_store::with(|b| *b = Some(String::new()));
}

/// End the diversion and return what was captured.
pub fn take_capture() -> String {
    capture_store::with(|b| b.take()).unwrap_or_default()
}

/// `true` when the line was captured and must not reach the sink.
pub(crate) fn capture_line(s: &str) -> bool {
    capture_store::with(|b| match b {
        Some(buf) => {
            buf.push_str(s);
            true
        }
        None => false,
    })
}

/// Install the run's active streams, and reset the indentation state so a run never
/// inherits an unclosed block.
pub fn set_mask(m: Mask) {
    store::with(|s| {
        let xml = s.xml;
        *s = State::new();
        s.use_stream = m;
        s.xml = xml;
    });
}

/// C's `setStreamPrintXML`: write every message as a `<message …>` element.
pub fn set_xml(v: bool) {
    store::with(|s| s.xml = v);
}

pub fn mask() -> Mask {
    store::with(|s| s.use_stream)
}

/// C's `OMC_ACTIVE_STREAM`.
pub fn active(stream: Stream) -> bool {
    store::with(|s| mask_has(s.use_stream, stream))
}

/// C's `deactivateLogging`: everything but stdout/assert/success off until
/// [`reactivate`].
pub fn deactivate() {
    store::with(|s| {
        if !s.streams_active {
            return;
        }
        s.backup = s.use_stream;
        s.use_stream = ALWAYS_ON | (s.use_stream & SHOW_ALL_WARNINGS);
        s.streams_active = false;
    });
}

pub fn reactivate() {
    store::with(|s| {
        if s.streams_active {
            return;
        }
        s.use_stream = (s.backup & !ALWAYS_ON) | (s.use_stream & ALWAYS_ON);
        s.streams_active = true;
    });
}

pub fn info(stream: Stream, indent_next: bool, msg: &str) {
    if active(stream) {
        message_text(INFO, stream, indent_next, msg);
    }
}

/// C's `OMC_ACTIVE_WARNING_STREAM`.
pub fn warning(stream: Stream, indent_next: bool, msg: &str) {
    if active(stream) || store::with(|s| s.use_stream & SHOW_ALL_WARNINGS != 0) {
        message_text(WARNING, stream, indent_next, msg);
    }
}

/// C's `warningStreamPrintWithLimit`, `max_displayed` being `-lvMaxWarn`.
pub fn warning_with_limit(stream: Stream, n_displayed: u64, max_displayed: u64, msg: &str) {
    if !(active(stream) || store::with(|s| s.use_stream & SHOW_ALL_WARNINGS != 0)) {
        return;
    }
    if n_displayed <= max_displayed {
        message_text(WARNING, stream, false, msg);
    }
    if n_displayed == max_displayed {
        message_text(
            INFO,
            stream,
            false,
            &format!(
                "Too many warnings, reached display limit of {max_displayed}. Suppressing further warning messages of the same type."
            ),
        );
        message_text(INFO, stream, false, "Change limit with simulation flag -lvMaxWarn=<newLimit>");
    }
}

/// C's `va_throwStreamPrint`: unlike [`error`], gated on `-lv`.
pub fn debug(stream: Stream, indent_next: bool, msg: &str) {
    if active(stream) {
        message_text(DEBUG_TYPE, stream, indent_next, msg);
    }
}

pub fn error(stream: Stream, indent_next: bool, msg: &str) {
    message_text(ERROR, stream, indent_next, msg);
}

/// C's `messageClose`: end a block opened with `indent_next`.
pub fn close(stream: Stream) {
    let end = store::with(|s| {
        if !mask_has(s.use_stream, stream) {
            return false;
        }
        if !s.xml {
            s.level[stream as usize] -= 1;
        }
        s.xml
    });
    if end {
        crate::log_line(stream, INFO, "</message>\n");
    }
}

/// C's `messageCloseWarning`: [`close`] for a block [`warning`] opened, so `-w`
/// keeps the level balanced on an inactive stream.
pub fn close_warning(stream: Stream) {
    let end = store::with(|s| {
        if !(mask_has(s.use_stream, stream) || s.use_stream & SHOW_ALL_WARNINGS != 0) {
            return false;
        }
        if !s.xml {
            s.level[stream as usize] -= 1;
        }
        s.xml
    });
    if end {
        crate::log_line(stream, INFO, "</message>\n");
    }
}

/// C's `messageText`. A newline in `msg` starts a `subline`: `|` in both header
/// columns and no level indent, as C's recursive call gives.
pub fn message_text(ty: LogType, stream: Stream, indent_next: bool, msg: &str) {
    if store::with(|s| s.xml) {
        return message_xml(ty, stream, indent_next, msg);
    }
    let mut out = String::new();
    store::with(|s| {
        let i = stream as usize;
        for (n, line) in msg.split('\n').enumerate() {
            let subline = n > 0;
            let collapse = subline || (s.last_stream == stream && s.level[i] > 0);
            let name = if collapse { "|" } else { STREAM_NAME[i] };
            let ty_col = if subline || (s.last_stream == stream && s.last_type[i] == ty && s.level[i] > 0)
            {
                "|"
            } else {
                TYPE_DESC[ty as usize]
            };
            out.push_str(&format!("{name:<17} | {ty_col:<7} | "));
            if !subline {
                for _ in 0..s.level[i] {
                    out.push_str("| ");
                }
            }
            out.push_str(line);
            out.push('\n');
            s.last_type[i] = ty;
            s.last_stream = stream;
        }
        // C's `messageText` recurses for the second line and returns, so a
        // multi-line message never opens a block however `indentNext` is set.
        if indent_next && !msg.contains('\n') {
            s.level[i] += 1;
        }
    });
    crate::log_line(stream, ty, &out);
}

/// C's `messageXML`: the whole message as one element's `text` attribute, left
/// open for [`close`] when `indent_next`.
fn message_xml(ty: LogType, stream: Stream, indent_next: bool, msg: &str) {
    let mut out = format!(
        "<message stream=\"{}\" type=\"{}\" text=\"",
        STREAM_NAME[stream as usize], TYPE_DESC[ty as usize]
    );
    for c in msg.chars() {
        match c {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            _ => out.push(c),
        }
    }
    out.push_str(if indent_next { "\">\n" } else { "\" />\n" });
    crate::log_line(stream, ty, &out);
}

/// C's `%<width>.<prec>g`.
pub fn g(v: f64, width: usize, prec: i32) -> String {
    pad(crate::format_g(v, prec), width)
}

/// C's `%<width>.<prec>f`: fixed point, no exponent.
pub fn f(v: f64, width: usize, prec: usize) -> String {
    if !v.is_finite() {
        return alloc::format!("{v}");
    }
    pad(alloc::format!("{v:.prec$}"), width)
}

/// C's `%<width>.<prec>e`: always an exponent, at least two exponent digits.
pub fn e(v: f64, width: usize, prec: usize) -> String {
    pad(exp_str(v, prec), width)
}

fn pad(s: String, width: usize) -> String {
    if s.len() >= width { s } else { format!("{s:>width$}") }
}

fn exp_str(v: f64, prec: usize) -> String {
    if !v.is_finite() {
        return alloc::format!("{v}");
    }
    // Round in the mantissa's own scale, and carry when it rounds up to 10.
    let mut exp = if v == 0.0 { 0 } else { libm::floor(libm::log10(libm::fabs(v))) as i32 };
    let mut m = if v == 0.0 { 0.0 } else { v / libm::pow(10.0, exp as f64) };
    if libm::fabs(m) >= 10.0 {
        m /= 10.0;
        exp += 1;
    } else if v != 0.0 && libm::fabs(m) < 1.0 {
        m *= 10.0;
        exp -= 1;
    }
    let mut s = alloc::format!("{m:.prec$}");
    if s.trim_start_matches('-').starts_with("10") {
        exp += 1;
        s = alloc::format!("{:.prec$}", m / 10.0);
    }
    alloc::format!("{s}e{}{:02}", if exp < 0 { '-' } else { '+' }, exp.abs())
}


/// C's `ryu_hr_tdzp_buf` (`3rdParty/ryu/ryu/om_format.c`): the shortest round-trip
/// representation, rendered decimal where that is shorter. The optimizer's
/// `LOG_IPOPT_ERROR` lines are printed with it, so they must match digit for digit.
///
/// The same port lives in `metamodelica::real::ryu` for the compiler's `realString`;
/// this copy keeps the `no_std` simulation runtime independent of it.
pub fn shortest(d: f64) -> String {
    if d.is_infinite() {
        return if d < 0.0 { "-inf".into() } else { "inf".into() };
    }
    if d.is_nan() {
        return "NaN".into();
    }
    ryu_to_hr(&format!("{d:e}"), false)
}

fn ryu_to_hr(d2s_str: &str, real_output: bool) -> String {
    let Some(epos) = d2s_str.find(['e', 'E']) else {
        // Not in mantissa-exponent form (e.g. "NaN"); pass through.
        return d2s_str.replace('E', "e");
    };
    let mant_str = &d2s_str[..epos];
    let mut exp: i32 = d2s_str[epos + 1..].parse().unwrap_or(0);
    let (neg, mut digits) = match mant_str.strip_prefix('-') {
        Some(m) => (true, m.to_string()),
        None => (false, mant_str.to_string()),
    };
    // Number of digits after the decimal point in the mantissa.
    let mut ndec: i32 = if digits.contains('.') { digits.len() as i32 - 2 } else { 0 };
    // The exponential rendering used when the decimal form is unsuitable.
    let mut exp_repr: String = d2s_str.replace('E', "e");

    if ndec > 12 && !real_output {
        // Round the mantissa to 12 decimals; use it only if that removed at
        // least 4 trailing zeros (i.e. the long tail was an artifact).
        let mant: f64 = digits.parse().unwrap_or(0.0);
        let mut rounded = format!("{mant:.12}");
        // 9.999999999999999 rounds to 10.000000000000: renormalise.
        if rounded == "10.000000000000" {
            rounded = "1.000000000000".to_string();
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

    // Decimal form. `digs` is the mantissa without its decimal point:
    // one leading digit followed by `ndec` decimals.
    let digs: Vec<char> = digits.chars().filter(|c| *c != '.').collect();
    let mut out = String::with_capacity(24);
    if neg {
        out.push('-');
    }
    if exp == 0 {
        out.push_str(&digits);
    } else if exp > 0 {
        // Move the decimal point `exp` places to the right.
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
        // exp < 0: the number starts with "0." and some zeros.
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
/// C's `debugString`: one plain line.
pub fn debug_string(stream: Stream, msg: &str) {
    info(stream, false, msg);
}

/// C's `debugInt`: `"%s %d"`. Built only when the stream is on, as C's variadic
/// `infoStreamPrint` is — the nonlinear solver calls these per iteration.
pub fn debug_int(stream: Stream, msg: &str, v: i32) {
    if active(stream) {
        info(stream, false, &format!("{msg} {v}"));
    }
}

/// C's `debugDouble`: `"%s %18.10e"`; guarded as [`debug_int`] is.
pub fn debug_double(stream: Stream, msg: &str, v: f64) {
    if active(stream) {
        info(stream, false, &format!("{msg} {}", e(v, 18, 10)));
    }
}

/// C's `debugVectorDouble`: a `name [n-dim]` block holding one line of
/// space-separated `%16.8g`, with `±INF` for anything past `1e300`.
pub fn debug_vector_double(stream: Stream, name: &str, v: &[f64]) {
    if !active(stream) {
        return;
    }
    info(stream, true, &format!("{name} [{}-dim]", v.len()));
    let mut line = String::new();
    for (i, x) in v.iter().enumerate() {
        if i > 0 {
            line.push(' ');
        }
        let cell = if *x < -1e300 {
            "-INF".to_string()
        } else if *x > 1e300 {
            "+INF".to_string()
        } else {
            g(*x, 16, 8)
        };
        line.push_str(&cell);
    }
    info(stream, false, &line);
    close(stream);
}

/// C's `debugVectorInt`: the same block over `%d`.
pub fn debug_vector_int(stream: Stream, name: &str, v: &[i32]) {
    if !active(stream) {
        return;
    }
    info(stream, true, &format!("{name} [{}-dim]", v.len()));
    let mut line = String::new();
    for (i, x) in v.iter().enumerate() {
        if i > 0 {
            line.push(' ');
        }
        line.push_str(&alloc::format!("{x}"));
    }
    info(stream, false, &line);
    close(stream);
}

#[cfg(test)]
mod tests {
    use super::*;
    use alloc::vec::Vec;

    fn capture(f: impl FnOnce()) -> String {
        crate::set_log_sink(sink);
        SINK.with(|s| s.borrow_mut().clear());
        f();
        SINK.with(|s| s.borrow().clone())
    }

    std::thread_local! {
        static SINK: core::cell::RefCell<String> = const { core::cell::RefCell::new(String::new()) };
    }
    fn sink(_stream: Stream, _ty: LogType, s: &str) {
        SINK.with(|c| c.borrow_mut().push_str(s));
    }

    #[test]
    fn header_columns_collapse_inside_a_block() {
        set_mask(ALWAYS_ON | (1 << NLS));
        let out = capture(|| {
            info(NLS, true, "############ Solve nonlinear system 7 at time 0 ############");
            info(NLS, true, "initial variable values:");
            info(NLS, false, "[ 1] y");
            close(NLS);
            close(NLS);
        });
        assert_eq!(
            out,
            "LOG_NLS           | info    | ############ Solve nonlinear system 7 at time 0 ############\n\
             |                 | |       | | initial variable values:\n\
             |                 | |       | | | [ 1] y\n"
        );
    }

    #[test]
    fn level_zero_never_collapses() {
        set_mask(ALWAYS_ON);
        let out = capture(|| {
            info(STDOUT, false, "a");
            info(STDOUT, false, "b");
        });
        assert_eq!(
            out,
            "LOG_STDOUT        | info    | a\nLOG_STDOUT        | info    | b\n"
        );
    }

    #[test]
    fn an_embedded_newline_is_a_subline() {
        set_mask(ALWAYS_ON);
        let out = capture(|| info(ASSERT, false, "first\nsecond"));
        assert_eq!(
            out,
            "LOG_ASSERT        | info    | first\n|                 | |       | second\n"
        );
    }

    #[test]
    fn inactive_streams_print_nothing() {
        set_mask(ALWAYS_ON);
        let out = capture(|| info(NLS, false, "nope"));
        assert!(out.is_empty());
    }

    #[test]
    fn verbose_streams_imply_their_plain_one() {
        let m = mask_from_streams(&["LOG_NLS_V"]).expect("parses");
        assert!(mask_has(m, NLS_V) && mask_has(m, NLS));
        let m = mask_from_streams(&["LOG_INIT_V"]).expect("parses");
        for s in [INIT_V, INIT, SOTI, INIT_HOMOTOPY] {
            assert!(mask_has(m, s), "{}", STREAM_NAME[s as usize]);
        }
        let m = mask_from_streams(&["LOG_ALL"]).expect("parses");
        assert!(mask_has(m, NLS_V) && mask_has(m, ZEROCROSSINGS));
        assert!(!mask_has(m, UNKNOWN));
    }

    #[test]
    fn a_minus_prefix_turns_a_stream_off() {
        let m = mask_from_streams(&["-LOG_SUCCESS"]).expect("parses");
        assert!(!mask_has(m, SUCCESS) && mask_has(m, STDOUT));
        assert!(mask_has(mask_from_streams::<&str>(&[]).expect("parses"), SUCCESS));
    }

    /// `-w`: a warning prints on an inactive stream, an info still does not.
    #[test]
    fn show_all_warnings_only_lifts_warnings() {
        set_mask(ALWAYS_ON);
        assert!(capture(|| warning(NLS, false, "quiet")).is_empty());
        set_mask(ALWAYS_ON | SHOW_ALL_WARNINGS);
        let out = capture(|| {
            info(NLS, false, "still quiet");
            warning(NLS, false, "loud");
        });
        assert_eq!(out, "LOG_NLS           | warning | loud\n");
    }

    #[test]
    fn an_unknown_stream_is_an_error() {
        let e = mask_from_streams(&["LOG_NOPE"]).expect_err("must reject");
        assert!(e.contains("LOG_NOPE"), "{e}");
    }

    #[test]
    fn c_printf_conversions() {
        assert_eq!(g(5e-06, 16, 8), "           5e-06");
        assert_eq!(g(50000.0, 16, 8), "           50000");
        assert_eq!(g(-0.51701271234, 16, 8), "     -0.51701271");
        assert_eq!(e(-4.3608668960, 18, 10), " -4.3608668960e+00");
        assert_eq!(e(1.0, 18, 10), "  1.0000000000e+00");
        assert_eq!(e(2.2204460493e-16, 18, 10), "  2.2204460493e-16");
        assert_eq!(e(0.0, 18, 10), "  0.0000000000e+00");
        assert_eq!(alloc::format!("error_f        = {}", e(2.2204460493e-16, 18, 10)),
                   "error_f        =   2.2204460493e-16");
    }

    #[test]
    fn vector_blocks_match_cs_layout() {
        set_mask(ALWAYS_ON | (1 << NLS_V));
        let out = capture(|| debug_vector_double(NLS_V, "System values", &[5e-06, 50000.0]));
        let lines: Vec<&str> = out.lines().collect();
        assert_eq!(lines[0], "LOG_NLS_V         | info    | System values [2-dim]");
        assert_eq!(lines[1], "|                 | |       | |            5e-06            50000");
    }
}
