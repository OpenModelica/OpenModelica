//! C's `simulation/solver/ebdd_runtime.c`: under `-lv=LOG_EBDD` the run appends
//! one JSON object per line to `<prefix>_dbg.json`, keyed by the equation index
//! `<prefix>_info.json` uses. The record layout is C's, field for field.
//!
//! A host installs the file sink ([`set_sink`]); without one the records are
//! dropped.

use alloc::string::String;
use core::cell::UnsafeCell;
use core::fmt::Write;
use core::sync::atomic::{AtomicU32, AtomicUsize, Ordering};

use crate::omclog;

/// Write `chunk` to the file `name`: created (truncated) when `create`, appended
/// to otherwise.
pub type Sink = fn(name: &str, chunk: &str, create: bool);

struct State {
    file: String,
    model: String,
    opened: bool,
}

struct Store {
    lock: AtomicU32,
    state: UnsafeCell<State>,
}
// Guarded by `lock`: a `--parmodauto` run solves systems on several threads.
unsafe impl Sync for Store {}

static STORE: Store = Store {
    lock: AtomicU32::new(0),
    state: UnsafeCell::new(State {
        file: String::new(),
        model: String::new(),
        opened: false,
    }),
};
static SINK: AtomicUsize = AtomicUsize::new(0);
static SECTION: AtomicUsize = AtomicUsize::new(0);

pub fn set_sink(f: Sink) {
    SINK.store(f as usize, Ordering::Relaxed);
}

/// Whether an equation is in the initial section of `_info.json`. Without it a
/// record takes the phase of the run instead (see [`is_initial`]).
pub fn set_section_lookup(f: fn(u32) -> bool) {
    SECTION.store(f as usize, Ordering::Relaxed);
}

/// Start a run's file: C's `modelFilePrefix` and `modelName`.
pub fn begin(prefix: &str, model: &str) {
    locked(|s| {
        s.file = alloc::format!("{prefix}_dbg.json");
        s.model = String::from(model);
        s.opened = false;
    });
}

/// Forget the run's file, so [`begun`] is false until the next [`begin`].
pub fn reset() {
    locked(|s| {
        s.file.clear();
        s.model.clear();
        s.opened = false;
    });
}

/// Whether a run's file was started here ([`begin`]) and not [`reset`] since.
pub fn begun() -> bool {
    locked(|s| !s.file.is_empty())
}

pub fn active() -> bool {
    omclog::active(omclog::EBDD)
}

/// C's `eqInfo.section == EQUATION_SECTION_INITIAL`. `initializing` answers where
/// the host has no section table.
pub fn is_initial(eq_index: u32, initializing: bool) -> bool {
    let p = SECTION.load(Ordering::Relaxed);
    if p == 0 {
        return initializing;
    }
    let f: fn(u32) -> bool = unsafe { core::mem::transmute(p) };
    f(eq_index)
}

fn locked<R>(f: impl FnOnce(&mut State) -> R) -> R {
    while STORE
        .lock
        .compare_exchange_weak(0, 1, Ordering::Acquire, Ordering::Relaxed)
        .is_err()
    {
        core::hint::spin_loop();
    }
    let out = f(unsafe { &mut *STORE.state.get() });
    STORE.lock.store(0, Ordering::Release);
    out
}

fn emit(mut line: String) {
    line.push('\n');
    forward(&line);
}

/// Append records another recorder formatted (whole lines) to this run's file.
/// The host of a wasm module uses it where the driver, and so the file, is the
/// host's and the solves' records come from inside the module.
pub fn forward(line: &str) {
    let p = SINK.load(Ordering::Relaxed);
    if p == 0 {
        return;
    }
    let sink: Sink = unsafe { core::mem::transmute(p) };
    locked(|s| {
        if s.file.is_empty() {
            s.file = String::from("model_dbg.json");
        }
        if !s.opened {
            s.opened = true;
            let mut head = String::from("{\"format\":\"EBDD runtime info\",\"version\":1,\"model\":\"");
            escaped(&mut head, &s.model);
            head.push_str("\"}\n");
            sink(&s.file, &head, true);
        }
        sink(&s.file, line, false);
    });
}

fn escaped(out: &mut String, s: &str) {
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\u{8}' => out.push_str("\\b"),
            '\u{c}' => out.push_str("\\f"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => {
                let _ = write!(out, "\\u{:04x}", c as u32);
            }
            c => out.push(c),
        }
    }
}

/// C's `%.17g`, or `null` for a value JSON cannot hold.
fn number(out: &mut String, v: f64) {
    if v.is_finite() {
        out.push_str(&crate::format_g(v, 17));
    } else {
        out.push_str("null");
    }
}

fn name_at(names: &[String], i: usize) -> &str {
    names.get(i).map_or("", |s| s.as_str())
}

fn head(kind: &str, eq_index: u32, initial: bool, time: f64) -> String {
    let section = if initial { "initial" } else { "regular" };
    let mut s = alloc::format!("{{\"kind\":\"{kind}\",\"eqIndex\":{eq_index},\"section\":\"{section}\",\"time\":");
    number(&mut s, time);
    s
}

fn field(out: &mut String, key: &str, v: f64) {
    let _ = write!(out, ",\"{key}\":");
    number(out, v);
}

fn open_var(out: &mut String, first: bool, name: &str, value: f64) {
    if !first {
        out.push(',');
    }
    out.push_str("{\"name\":\"");
    escaped(out, name);
    out.push_str("\",\"value\":");
    number(out, value);
}

fn name_list(out: &mut String, names: &[String], idx: impl Iterator<Item = usize>) {
    for (k, i) in idx.enumerate() {
        if k > 0 {
            out.push(',');
        }
        out.push('"');
        escaped(out, name_at(names, i));
        out.push('"');
    }
}

/// C's `ebddRuntimeLogNonlinearSystem`. `status` is its `solved`,
/// `solved_less_accuracy` or `failed`.
#[allow(clippy::too_many_arguments)]
pub fn nonlinear(
    eq_index: u32,
    initial: bool,
    time: f64,
    status: &str,
    iterations: u64,
    names: &[String],
    x: &[f64],
    residual: &[f64],
    nominal: &dyn Fn(usize) -> f64,
) {
    let mut s = head("nonlinear", eq_index, initial, time);
    let _ = write!(
        s,
        ",\"status\":\"{status}\",\"iterations\":{iterations},\"size\":{},\"vars\":[",
        x.len()
    );
    for i in 0..x.len() {
        open_var(&mut s, i == 0, name_at(names, i), x[i]);
        field(&mut s, "residual", residual.get(i).copied().unwrap_or(f64::NAN));
        field(&mut s, "nominal", nominal(i));
        s.push('}');
    }
    s.push_str("]}");
    emit(s);
}

/// C's `ebddRuntimeLogNewtonIteration`: the iterate entering `iteration` (1-based)
/// and its residual, plain and divided by `res_scaling`.
#[allow(clippy::too_many_arguments)]
pub fn newton_iteration(
    eq_index: u32,
    initial: bool,
    time: f64,
    iteration: i32,
    names: &[String],
    x: &[f64],
    residual: &[f64],
    res_scaling: &[f64],
    nominal: &[f64],
) {
    let n = x.len();
    let mut s = head("newtonIteration", eq_index, initial, time);
    let _ = write!(s, ",\"iteration\":{iteration},\"size\":{n},\"vars\":[");
    for i in 0..n {
        let scale = match res_scaling.get(i) {
            Some(&v) if v != 0.0 => v,
            _ => 1.0,
        };
        open_var(&mut s, i == 0, name_at(names, i), x[i]);
        field(&mut s, "residual", residual[i]);
        field(&mut s, "residualScaled", residual[i] / scale);
        field(&mut s, "nominal", nominal.get(i).copied().unwrap_or(0.0));
        s.push('}');
    }
    s.push_str("]}");
    emit(s);
}

/// C's `ebddRuntimeLogJacobian`. `jac` is column-major and column-scaled by
/// `col_scaling`; the record holds the unscaled `d f_row / d x_col`, row-major.
pub fn jacobian(
    eq_index: u32,
    initial: bool,
    time: f64,
    iteration: i32,
    names: &[String],
    n: usize,
    jac: &[f64],
    col_scaling: &[f64],
) {
    let mut s = head("jacobian", eq_index, initial, time);
    let _ = write!(s, ",\"iteration\":{iteration},\"size\":{n},\"vars\":[");
    name_list(&mut s, names, 0..n);
    s.push_str("],\"rows\":[");
    for row in 0..n {
        if row > 0 {
            s.push(',');
        }
        s.push('[');
        for col in 0..n {
            let scale = match col_scaling.get(col) {
                Some(&v) if v != 0.0 => v,
                _ => 1.0,
            };
            if col > 0 {
                s.push(',');
            }
            number(&mut s, jac[col * n + row] / scale);
        }
        s.push(']');
    }
    s.push_str("]}");
    emit(s);
}

/// C's `ebddRuntimeLogHomotopyStep`: one accepted step of the initialization's
/// homotopy path.
#[allow(clippy::too_many_arguments)]
pub fn homotopy_step(
    eq_index: u32,
    initial: bool,
    time: f64,
    step: usize,
    lambda: f64,
    names: &[String],
    y: &[f64],
    residual: &[f64],
) {
    let mut s = head("homotopy", eq_index, initial, time);
    let _ = write!(s, ",\"step\":{step}");
    field(&mut s, "lambda", lambda);
    let _ = write!(s, ",\"size\":{},\"vars\":[", y.len());
    for i in 0..y.len() {
        open_var(&mut s, i == 0, name_at(names, i), y[i]);
        field(&mut s, "residual", residual.get(i).copied().unwrap_or(0.0));
        s.push('}');
    }
    s.push_str("]}");
    emit(s);
}

/// C's `ebddRuntimeLogNullSpace`: the variables the Newton diagnostics found to
/// be linearly dependent.
pub fn null_space(eq_index: u32, initial: bool, time: f64, size: usize, names: &[String], vars: &[usize]) {
    let mut s = head("nullSpace", eq_index, initial, time);
    let _ = write!(s, ",\"size\":{size},\"linearlyDependentVars\":[");
    name_list(&mut s, names, vars.iter().copied());
    s.push_str("]}");
    emit(s);
}

/// C's `ebddRuntimeLogConvergenceDiagnostics`: how many equations are nonlinear
/// and the variables they depend on nonlinearly.
pub fn convergence_diagnostics(
    eq_index: u32,
    initial: bool,
    time: f64,
    size: usize,
    nonlinear_eqs: usize,
    names: &[String],
    vars: &[usize],
) {
    let mut s = head("convergenceDiagnostics", eq_index, initial, time);
    let _ = write!(
        s,
        ",\"size\":{size},\"nonlinearEquations\":{nonlinear_eqs},\"nonlinearVars\":["
    );
    name_list(&mut s, names, vars.iter().copied());
    s.push_str("]}");
    emit(s);
}

/// C's `ebddRuntimeLogEventIteration`: the Boolean, then the Integer variables
/// after one event iteration. A model-level record, `eqIndex` -1.
pub fn event_iteration<'a>(
    time: f64,
    iteration: usize,
    bools: impl Iterator<Item = (&'a str, bool)>,
    ints: impl Iterator<Item = (&'a str, i32)>,
) {
    let mut s = String::from("{\"kind\":\"eventIteration\",\"eqIndex\":-1,\"time\":");
    number(&mut s, time);
    let _ = write!(s, ",\"iteration\":{iteration},\"vars\":[");
    let mut first = true;
    for (name, v) in bools {
        open_var(&mut s, first, name, if v { 1.0 } else { 0.0 });
        s.push('}');
        first = false;
    }
    for (name, v) in ints {
        open_var(&mut s, first, name, v as f64);
        s.push('}');
        first = false;
    }
    s.push_str("]}");
    emit(s);
}

/// C's `ebddRuntimeLogChattering`: one record per equation the chattering
/// zero-crossing occurs in.
pub fn chattering(eq_indexes: &[i32], time_start: f64, time_end: f64, state_events: usize, zero_crossing: &str) {
    for eq in eq_indexes {
        let mut s = alloc::format!("{{\"kind\":\"chattering\",\"eqIndex\":{eq},\"timeStart\":");
        number(&mut s, time_start);
        field(&mut s, "timeEnd", time_end);
        let _ = write!(s, ",\"stateEvents\":{state_events},\"zeroCrossing\":\"");
        escaped(&mut s, zero_crossing);
        s.push_str("\"}");
        emit(s);
    }
}
