//! The simulation algorithms that do not care where the model comes from.
//!
//! Everything here works against [`Ode`]: give it the state derivatives and the
//! zero-crossing functions at a point and it integrates, controls the step size,
//! locates the events it stepped over and interpolates onto the output grid.
//! `openmodelica_sim_meta` implements it over a model in wasm linear memory,
//! `openmodelica_fmi_driver` over an imported FMU, and both then run the same
//! `-s=gbode`/`-s=euler` code under the same `-gb*` flags.
//!
//! `no_std` + `alloc` by default (`std` adds nothing but the host's own `f64`
//! math), so an in-wasm runtime and a host build share one compilation.

#![cfg_attr(not(feature = "std"), no_std)]

extern crate alloc;

use alloc::format;
use alloc::string::{String, ToString};
use core::sync::atomic::{AtomicUsize, Ordering};

/// `omclog::info!(stream, indent_next, "…", args)`, the form to write: an
/// inactive stream costs the check alone, where the function plus a `&format!`
/// built the message either way. C's `infoStreamPrint` is variadic for the same
/// reason.
#[macro_export]
macro_rules! omclog_info {
    ($stream:expr, $indent:expr, $($arg:tt)*) => {
        $crate::omclog::info_fmt($stream, $indent, ::core::format_args!($($arg)*))
    };
}

/// [`omclog_info`] for [`omclog::warning`](omclog::warning).
#[macro_export]
macro_rules! omclog_warning {
    ($stream:expr, $indent:expr, $($arg:tt)*) => {
        $crate::omclog::warning_fmt($stream, $indent, ::core::format_args!($($arg)*))
    };
}

/// [`omclog_info`] for [`omclog::warning_with_limit`](omclog::warning_with_limit).
#[macro_export]
macro_rules! omclog_warning_with_limit {
    ($stream:expr, $n:expr, $max:expr, $($arg:tt)*) => {
        $crate::omclog::warning_with_limit_fmt($stream, $n, $max, ::core::format_args!($($arg)*))
    };
}

/// [`omclog_info`] for [`omclog::debug`](omclog::debug).
#[macro_export]
macro_rules! omclog_debug {
    ($stream:expr, $indent:expr, $($arg:tt)*) => {
        $crate::omclog::debug_fmt($stream, $indent, ::core::format_args!($($arg)*))
    };
}

/// [`omclog_info`] for [`omclog::error`](omclog::error), which prints whatever the
/// mask says and so only drops the `&format!`.
#[macro_export]
macro_rules! omclog_error {
    ($stream:expr, $indent:expr, $($arg:tt)*) => {
        $crate::omclog::error_fmt($stream, $indent, ::core::format_args!($($arg)*))
    };
}

pub mod clock;
pub mod counters;
pub mod dassl;
pub mod events;
pub mod fixedstep;
pub mod delay;
pub mod gbode;
pub mod omclog;
pub mod simflags;
pub mod solverflags;
pub mod spatial;
pub mod symsolver;
pub mod sysstat;
#[cfg(sundials)]
pub mod sundials;
#[cfg(sundials)]
pub mod sundials_ode;

/// Whether this build has the real CVODE and IDA linked in (`build.rs`).
pub const CVODE: bool = cfg!(sundials);
pub const IDA: bool = cfg!(sundials);

/// Solver errors are the C runtime's messages, which are all static.
pub type Result<T> = core::result::Result<T, &'static str>;

/// C's `MINIMAL_STEP_SIZE` (`simulation/solver/epsilon.h`), the bisection's
/// absolute tolerance.
pub const MINIMAL_STEP_SIZE: f64 = 1e-12;

/// What a solver needs of the model: the ODE right-hand side, the zero-crossing
/// functions, and the sparsity its finite-difference Jacobian can exploit.
///
/// One evaluation is `set the time and the states, evaluate, read back`, which
/// is what both a linear-memory model and an FMU do — the difference is only in
/// how the values get there.
pub trait Ode {
    /// `f := der(y)` at `(t, y)`.
    fn eval(&mut self, t: f64, y: &[f64], f: &mut [f64]) -> Result<()>;

    /// The zero-crossing (event indicator) functions at `(t, y)`. The continuous
    /// equations are evaluated first, so anything algebraic a crossing depends
    /// on is current.
    fn eval_zc(&mut self, t: f64, y: &[f64], zc: &mut [f64]) -> Result<()>;

    /// State nominals, for the error norm and the finite-difference step. One
    /// per state; an empty slice means "one".
    fn nominals(&self) -> &[f64] {
        &[]
    }

    /// C's `-nominalFactor`, scaling the nominal in the difference quotient.
    fn nominal_factor(&self) -> f64 {
        1.0
    }

    /// State `max` attributes, for the finite-difference step's sign choice.
    /// Empty ⇒ unbounded.
    fn maxs(&self) -> &[f64] {
        &[]
    }

    /// Colouring of the ODE Jacobian: each entry lists the columns that may be
    /// perturbed together. Empty ⇒ dense, column by column.
    fn jac_colors(&self) -> &[alloc::vec::Vec<u32>] {
        &[]
    }

    /// Rows that are nonzero in each column (CSC), matching [`Ode::jac_colors`].
    /// Empty ⇒ every row.
    fn jac_rows_by_col(&self) -> &[alloc::vec::Vec<u32>] {
        &[]
    }

    /// `out = df/dy · seed`, when the model can give it: a model compiled with
    /// its symbolic Jacobian answers this far more cheaply than differencing
    /// costs (one model evaluation per colour). `false` ⇒ the solvers difference
    /// it themselves.
    fn jacobian_vector(&mut self, _t: f64, _y: &[f64], _seed: &[f64], _out: &mut [f64]) -> bool {
        false
    }

    /// Whether [`Ode::jacobian_vector`] answers at all, asked once per assembly.
    fn has_jacobian_vector(&self) -> bool {
        false
    }

    /// C's `setContext(JACOBIAN)` around a finite-difference Jacobian, and the
    /// `ALGEBRAIC` it restores to. A model whose runtime has no such state
    /// leaves both alone.
    fn set_context_jacobian(&mut self) {}
    fn set_context_algebraic(&mut self) {}

    /// Right-hand-side evaluations so far, for the solver statistics.
    fn calls(&self) -> u64 {
        0
    }

    /// Count one evaluation. Solvers call this; an implementation that does not
    /// track evaluations can ignore it.
    fn note_call(&mut self) {}

    /// Whether the error the last [`Ode::eval`] returned is that trial point's
    /// rather than the run's (C's `IRES = -1`, FMI's `fmi3Discard`), so a solver
    /// that can shorten its step retries instead of failing.
    fn take_discard(&mut self) -> bool {
        false
    }
}

/// A residual Jacobian's sparsity, from a caller that knows it. `rows_by_col[j]`
/// are the rows of `F` that unknown `j` appears in — the states first, then the
/// algebraic ones, the order `y` follows — and `colors` groups columns sharing no
/// row, so one residual evaluation differences a whole group.
///
/// The pattern is `∂F/∂y + cj·∂F/∂y'`, which for a state column means the rows
/// reached through either `x` or `der(x)`: one difference carries both terms.
pub struct DaeSparsity {
    pub rows_by_col: alloc::vec::Vec<alloc::vec::Vec<u32>>,
    pub colors: alloc::vec::Vec<alloc::vec::Vec<u32>>,
}

/// A model in residual form, `F(t, y, y') = 0` over `y = [states | algebraic
/// unknowns]`, which only IDA integrates. `y'` carries a derivative per component,
/// the algebraic ones being whatever IDA holds there.
pub trait Dae {
    /// `res := F(t, y, y')`.
    fn residual(&mut self, t: f64, y: &[f64], yp: &[f64], res: &mut [f64]) -> Result<()>;

    /// The residual Jacobian's sparsity, when the caller can supply one; IDA then
    /// factorizes with KLU over a coloured difference-quotient Jacobian instead of
    /// building its own dense one.
    fn sparsity(&self) -> Option<&DaeSparsity> {
        None
    }

    /// The zero-crossing functions at `(t, y, y')`.
    fn eval_zc(&mut self, t: f64, y: &[f64], yp: &[f64], zc: &mut [f64]) -> Result<()>;

    /// One nominal per component of `y`; empty means "one".
    fn nominals(&self) -> &[f64] {
        &[]
    }

    fn note_call(&mut self) {}

    /// As [`Ode::take_discard`], for the last [`Dae::residual`].
    fn take_discard(&mut self) -> bool {
        false
    }
}

/// C's `bisection` iteration bound (`events.c`, `gbode_events.c`): `-mbi` when it
/// is set to a positive value, else what halving the bracket down to `ttol` takes.
pub fn bisection_iterations(width: f64, ttol: f64) -> i64 {
    match simflags::with_flags(|f| f.max_bisection_iter) {
        Some(n) if n > 0 => n as i64,
        _ => 1 + libm::ceil(libm::log(libm::fabs(width) / ttol) / libm::log(2.0)) as i64,
    }
}

// Where a solver's log lines go. The model's `print` output shares the channel,
// so the two interleave in the order C prints them.
//
// The stream and type come along for a host whose only channel is the FMI logger:
// it has to map them to a category and an `fmi3Status`. One writing to a stdout
// ignores both — they are already in the line's header columns.
pub type LogSink = fn(omclog::Stream, omclog::LogType, &str);
static LOG_SINK: AtomicUsize = AtomicUsize::new(0);

pub fn set_log_sink(f: LogSink) {
    LOG_SINK.store(f as usize, Ordering::Relaxed);
    // DASKR's own messages (`xerrwd`) belong in the same log, in call order.
    #[cfg(feature = "std")]
    daskr::auxiliary::set_print_hook(|s| log_line(omclog::STDOUT, omclog::INFO, s));
}

/// Whether the installed sink writes to the process's own `stdout`.
static SINK_IS_STDOUT: core::sync::atomic::AtomicBool = core::sync::atomic::AtomicBool::new(false);

/// Tell the log machinery that [`set_log_sink`]'s sink writes to `stdout`. The
/// optimizer redirects `stdout` into a pipe to bring Ipopt's own output into the
/// log; a sink that *is* `stdout` must not be, or draining the pipe writes it
/// straight back in. True for a simulation executable, false for the wasm-jit host.
pub fn set_log_sink_is_stdout(v: bool) {
    SINK_IS_STDOUT.store(v, Ordering::Relaxed);
}

pub fn log_sink_is_stdout() -> bool {
    SINK_IS_STDOUT.load(Ordering::Relaxed)
}

pub fn log_line(stream: omclog::Stream, ty: omclog::LogType, s: &str) {
    if omclog::capture_line(s) {
        return;
    }
    let p = LOG_SINK.load(Ordering::Relaxed);
    if p != 0 {
        let f: LogSink = unsafe { core::mem::transmute(p) };
        f(stream, ty, s);
    }
}

/// C's `%.<p>g`: `p` significant digits, `%e` outside `[1e-4, 10^p)`, trailing
/// zeros and a bare decimal point trimmed.
pub fn format_g(v: f64, p: i32) -> String {
    if !v.is_finite() || v == 0.0 {
        return format!("{v}");
    }
    let trim = |s: String| -> String {
        if !s.contains('.') {
            return s;
        }
        s.trim_end_matches('0').trim_end_matches('.').to_string()
    };
    let (mut exp, mut m) = decimal_exp(v);
    if exp < -4 || exp >= p {
        let mut s = format!("{:.*}", (p - 1) as usize, m);
        // The rounding can carry the mantissa back over ten.
        if s.trim_start_matches('-').starts_with("10") {
            exp += 1;
            m /= 10.0;
            s = format!("{:.*}", (p - 1) as usize, m);
        }
        return format!("{}e{}{:02}", trim(s), if exp < 0 { '-' } else { '+' }, exp.abs());
    }
    trim(format!("{:.*}", (p - 1 - exp).max(0) as usize, v))
}

/// `v`'s decimal exponent and the mantissa in `[1, 10)`. `log10` is not exactly
/// rounded (the `libm` crate's lands an ULP off an exact power of ten, where glibc
/// does not), so the mantissa decides the exponent rather than the other way round —
/// otherwise `1e-06` prints as `10e-07`.
pub(crate) fn decimal_exp(v: f64) -> (i32, f64) {
    let mut exp = libm::floor(libm::log10(libm::fabs(v))) as i32;
    let mut m = v / libm::pow(10.0, exp as f64);
    if libm::fabs(m) >= 10.0 {
        m /= 10.0;
        exp += 1;
    } else if libm::fabs(m) < 1.0 {
        m *= 10.0;
        exp -= 1;
    }
    (exp, m)
}

/// C's `%e`: six decimals on the mantissa, a two-digit exponent.
pub fn format_e(v: f64) -> String {
    if !v.is_finite() {
        return format!("{v}");
    }
    let (mut exp, m) = if v == 0.0 { (0, 0.0) } else { decimal_exp(v) };
    let mut s = format!("{m:.6}");
    if s.trim_start_matches('-').starts_with("10") {
        exp += 1;
        s = format!("{:.6}", m / 10.0);
    }
    format!("{s}e{}{:02}", if exp < 0 { '-' } else { '+' }, exp.abs())
}
