//! The `### STATISTICS ###` block a run prints at the end (`solver_main.c`).
//!
//! Pure formatting over [`SolveStats`], shared by every host that finishes a run:
//! the wasm-jit backend, which folds it into the simulation log, and the C+Rust
//! simulation runtime, which writes it to the executable's stdout.

use alloc::format;
use alloc::string::String;
use alloc::vec::Vec;

use crate::SolveStats;
use crate::driver::format_g;
use crate::rtclock;

/// C's `SOLVER_METHOD_NAME` names the integrator, not the driver running it:
/// `dassl-events` is `dassl`.
pub fn solver_method_name(label: &str) -> &str {
    label.split('-').next().unwrap_or(label)
}

/// The `-lv=LOG_STATS` block: same lines, order and quantities as
/// `solver_main.c`'s `### STATISTICS ###`, off the [`rtclock`] snapshot the
/// driver leaves in `SolveStats`. A driver only fills the counters; rendering
/// them is the caller's, which is why this is not in the driver.
pub fn log_stats_block(s: &SolveStats) -> String {
    let t = |ix: usize| s.timers[ix];
    let total = t(rtclock::TOTAL);
    // C's `total100`; a zero total (clocks off) would make every share NaN.
    let pct = |v: f64| if total > 0.0 { v * 100.0 / total } else { 0.0 };
    let line = |v: f64, what: &str| {
        format!("LOG_STATS         | info    | | {:>12}s [{:5.1}%] {what}\n", format_g(v, 6), pct(v))
    };
    // C's "simulation": what none of the other clocks claimed.
    let sim = total
        - t(rtclock::OVERHEAD)
        - t(rtclock::EVENT)
        - t(rtclock::OUTPUT)
        - t(rtclock::STEP)
        - t(rtclock::INIT)
        - t(rtclock::PREINIT)
        - t(rtclock::SOLVER);
    let mut out = String::from("LOG_STATS         | info    | ### STATISTICS ###\n");
    out.push_str("LOG_STATS         | info    | timer\n");
    for (v, what) in [(t(rtclock::INIT_XML), "reading init.xml"), (t(rtclock::INFO_XML), "reading info.xml")] {
        out.push_str(&format!("LOG_STATS         | info    | | {:>12}s          {what}\n", format_g(v, 6)));
    }
    out.push_str(&line(t(rtclock::PREINIT), "pre-initialization"));
    out.push_str(&line(t(rtclock::INIT), "initialization"));
    out.push_str(&line(t(rtclock::STEP), "steps"));
    out.push_str(&line(t(rtclock::SOLVER), "solver (excl. callbacks)"));
    out.push_str(&line(t(rtclock::OUTPUT), "creating output-file"));
    out.push_str(&line(t(rtclock::EVENT), "event-handling"));
    out.push_str(&line(t(rtclock::OVERHEAD), "overhead"));
    out.push_str(&line(sim, "simulation"));
    out.push_str(&format!(
        "LOG_STATS         | info    | | {:>12}s [100.0%] total\n",
        format_g(total, 6)
    ));
    out.push_str(&format!(
        "LOG_STATS         | info    | events\n\
         LOG_STATS         | info    | |   {:5} state events\n\
         LOG_STATS         | info    | |   {:5} time events\n\
         LOG_STATS         | info    | solver: {}\n\
         LOG_STATS         | info    | |   {:5} steps taken\n\
         LOG_STATS         | info    | |   {:5} calls of functionODE\n\
         LOG_STATS         | info    | |   {:5} evaluations of jacobian\n\
         LOG_STATS         | info    | |   {:5} error test failures\n\
         LOG_STATS         | info    | |   {:5} convergence test failures\n\
         LOG_STATS         | info    | | {}s time of jacobian evaluation\n",
        s.state_events, s.time_events, solver_method_name(s.method), s.steps,
        s.res_evals, s.jac_evals, s.err_test_fails, s.conv_test_fails,
        format_g(t(rtclock::JACOBIAN), 6),
    ));
    if crate::omclog::active(crate::omclog::STATS_V) {
        out.push_str(&log_stats_v_block(s));
    }
    out
}

/// `solver_main.c`'s `LOG_STATS_V` sections: how often each model entry point ran
/// and what share of the run it took, then the systems.
fn log_stats_v_block(s: &SolveStats) -> String {
    let total = s.timers[rtclock::TOTAL];
    let pct = |v: f64| if total > 0.0 { v * 100.0 / total } else { 0.0 };
    let mut out = String::from("LOG_STATS_V       | info    | function calls\n");
    let timed = |n: u64, what: &str, v: f64, out: &mut String| {
        if n == 0 {
            return;
        }
        out.push_str(&format!("LOG_STATS_V       | info    | | {n:5} {what}\n"));
        out.push_str(&format!(
            "LOG_STATS_V       | info    | | | {:>12}s [{:5.1}%]\n",
            format_g(v, 6),
            pct(v)
        ));
    };
    for (ix, what) in [
        (rtclock::DAE, "calls of functionDAE"),
        (rtclock::FUNCTION_ODE, "calls of functionODE"),
        (rtclock::RESIDUALS, "calls of functionODE_residual"),
        (rtclock::ALGEBRAICS, "calls of functionAlgebraics"),
        (rtclock::JACOBIAN, "evaluations of jacobian"),
    ] {
        timed(s.tcalls[ix], what, s.timers[ix], &mut out);
    }
    out.push_str(&format!(
        "LOG_STATS_V       | info    | | {:5} calls of updateDiscreteSystem\n\
         LOG_STATS_V       | info    | | {:5} calls of functionZeroCrossingsEquations\n",
        s.tcalls[rtclock::DISCRETE], s.tcalls[rtclock::ZC_EQUATIONS],
    ));
    timed(s.tcalls[rtclock::ZC], "calls of functionZeroCrossings", s.timers[rtclock::ZC], &mut out);
    out.push_str(&sys_stats_section(s, false));
    out.push_str(&sys_stats_section(s, true));
    out
}

/// `printLinearSystemSolvingStatistics` / `printNonLinearSystemSolvingStatistics`
/// for every system of one kind, in equation-index order as C stores them.
fn sys_stats_section(s: &SolveStats, nonlinear: bool) -> String {
    let head = if nonlinear { "non-linear systems" } else { "linear systems" };
    let mut out = format!("LOG_STATS_V       | info    | {head}\n");
    let mut systems: Vec<_> = s.systems.iter().filter(|x| x.nonlinear == nonlinear).collect();
    systems.sort_by_key(|x| x.eq_index);
    for x in systems {
        let calls = x.calls.max(1) as f64;
        if nonlinear {
            out.push_str(&format!(
                "LOG_STATS_V       | info    | | Non-linear system {} of size {} solver statistics:\n\
                 LOG_STATS_V       | info    | | |  number of calls                : {}\n\
                 LOG_STATS_V       | info    | | |  number of iterations           : {}\n\
                 LOG_STATS_V       | info    | | |  number of function evaluations : {}\n\
                 LOG_STATS_V       | info    | | |  number of jacobian evaluations : {}\n\
                 LOG_STATS_V       | info    | | |  time of jacobian evaluations   : {:.6}\n\
                 LOG_STATS_V       | info    | | |  average time per call          : {:.6}\n\
                 LOG_STATS_V       | info    | | |  total time                     : {:.6}\n",
                x.eq_index, x.size, x.calls, x.iters, x.res_evals, x.jac_evals,
                x.jac, x.total / calls, x.total,
            ));
        } else {
            let density = 100.0 * f64::from(x.nnz) / f64::from(x.size * x.size).max(1.0);
            out.push_str(&format!(
                "LOG_STATS_V       | info    | | Linear system {} with (size = {}, nonZeroElements = {}, density = {:.2} %) solver statistics:\n\
                 LOG_STATS_V       | info    | | |  number of calls                : {}\n\
                 LOG_STATS_V       | info    | | |  average time per call          : {}\n\
                 LOG_STATS_V       | info    | | |  time of jacobian evaluations   : {}\n\
                 LOG_STATS_V       | info    | | |  total time                     : {}\n",
                x.eq_index, x.size, x.nnz, density, x.calls,
                format_g(x.total / calls, 6), format_g(x.jac, 6), format_g(x.total, 6),
            ));
        }
    }
    out
}
