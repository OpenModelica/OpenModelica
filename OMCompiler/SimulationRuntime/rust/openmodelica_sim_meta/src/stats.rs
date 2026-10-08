//! The `### STATISTICS ###` block a run prints at the end (`solver_main.c`).
//!
//! Logged over [`SolveStats`] by every host that finishes a run: the wasm-jit
//! backend folds it into the simulation log, libSimulationRuntimeRust logs it.

use alloc::string::String;
use alloc::vec::Vec;

use crate::SolveStats;
use crate::driver::format_g;
use crate::omclog::{self, STATS, STATS_V};
use crate::rtclock;

/// C's `SOLVER_METHOD_NAME` names the integrator, not the driver running it:
/// `dassl-events` is `dassl`.
pub fn solver_method_name(label: &str) -> &str {
    label.split('-').next().unwrap_or(label)
}

/// The `-lv=LOG_STATS` block rendered into a string, in the log format the run
/// writes, for a host that folds it into a log it captured.
pub fn log_stats_block(s: &SolveStats) -> String {
    omclog::capture(|| log_stats(s))
}

/// `solver_main.c`'s `### STATISTICS ###`, off the [`rtclock`] snapshot the
/// driver leaves in `SolveStats`. A driver only fills the counters; logging them
/// is the caller's, which is why this is not in the driver.
pub fn log_stats(s: &SolveStats) {
    if !omclog::active(STATS) {
        return;
    }
    let t = |ix: usize| s.timers[ix];
    let total = t(rtclock::TOTAL);
    // C's `total100`; a zero total (clocks off) would make every share NaN.
    let pct = |v: f64| if total > 0.0 { v * 100.0 / total } else { 0.0 };
    // C's "simulation": what none of the other clocks claimed.
    let sim = total
        - t(rtclock::OVERHEAD)
        - t(rtclock::EVENT)
        - t(rtclock::OUTPUT)
        - t(rtclock::STEP)
        - t(rtclock::INIT)
        - t(rtclock::PREINIT)
        - t(rtclock::SOLVER);
    omclog::info(STATS, true, "### STATISTICS ###");
    omclog::info(STATS, true, "timer");
    for (v, what) in [(t(rtclock::INIT_XML), "reading init.xml"), (t(rtclock::INFO_XML), "reading info.xml")] {
        omclog::info!(STATS, false, "{}s          {what}", omclog::g(v, 12, 6));
    }
    for (v, what) in [
        (t(rtclock::PREINIT), "pre-initialization"),
        (t(rtclock::INIT), "initialization"),
        (t(rtclock::STEP), "steps"),
        (t(rtclock::SOLVER), "solver (excl. callbacks)"),
        (t(rtclock::OUTPUT), "creating output-file"),
        (t(rtclock::EVENT), "event-handling"),
        (t(rtclock::OVERHEAD), "overhead"),
        (sim, "simulation"),
    ] {
        omclog::info!(STATS, false, "{}s [{:5.1}%] {what}", omclog::g(v, 12, 6), pct(v));
    }
    omclog::info!(STATS, false, "{}s [100.0%] total", omclog::g(total, 12, 6));
    omclog::close(STATS);
    omclog::info(STATS, true, "events");
    omclog::info!(STATS, false, "{:5} state events", s.state_events);
    omclog::info!(STATS, false, "{:5} time events", s.time_events);
    omclog::close(STATS);
    // C has no solver counters for QSS.
    let method = solver_method_name(s.method);
    if method != "qss" {
        omclog::info!(STATS, true, "solver: {method}");
        omclog::info!(STATS, false, "{:5} steps taken", s.steps);
        omclog::info!(STATS, false, "{:5} calls of functionODE", s.res_evals);
        omclog::info!(STATS, false, "{:5} evaluations of jacobian", s.jac_evals);
        omclog::info!(STATS, false, "{:5} error test failures", s.err_test_fails);
        omclog::info!(STATS, false, "{:5} convergence test failures", s.conv_test_fails);
        omclog::info!(STATS, false, "{}s time of jacobian evaluation", format_g(t(rtclock::JACOBIAN), 6));
        omclog::close(STATS);
    }
    if omclog::active(STATS_V) {
        log_stats_v(s, pct);
    }
    omclog::close(STATS);
}

/// `solver_main.c`'s `LOG_STATS_V` sections: how often each model entry point ran
/// and what share of the run it took, then the systems.
fn log_stats_v(s: &SolveStats, pct: impl Fn(f64) -> f64) {
    omclog::info(STATS_V, true, "function calls");
    let timed = |n: u64, what: &str, v: f64| {
        if n == 0 {
            return;
        }
        omclog::info!(STATS_V, true, "{n:5} {what}");
        omclog::info!(STATS_V, false, "{}s [{:5.1}%]", omclog::g(v, 12, 6), pct(v));
        omclog::close(STATS_V);
    };
    for (ix, what) in [
        (rtclock::DAE, "calls of functionDAE"),
        (rtclock::FUNCTION_ODE, "calls of functionODE"),
        (rtclock::RESIDUALS, "calls of functionODE_residual"),
        (rtclock::ALGEBRAICS, "calls of functionAlgebraics"),
        (rtclock::JACOBIAN, "evaluations of jacobian"),
    ] {
        timed(s.tcalls[ix], what, s.timers[ix]);
    }
    omclog::info!(STATS_V, false, "{:5} calls of updateDiscreteSystem", s.tcalls[rtclock::DISCRETE]);
    omclog::info!(STATS_V, false, "{:5} calls of functionZeroCrossingsEquations", s.tcalls[rtclock::ZC_EQUATIONS]);
    timed(s.tcalls[rtclock::ZC], "calls of functionZeroCrossings", s.timers[rtclock::ZC]);
    omclog::close(STATS_V);
    sys_stats_section(s, false);
    sys_stats_section(s, true);
}

/// `printLinearSystemSolvingStatistics` / `printNonLinearSystemSolvingStatistics`
/// for every system of one kind, in equation-index order as C stores them.
fn sys_stats_section(s: &SolveStats, nonlinear: bool) {
    omclog::info(STATS_V, true, if nonlinear { "non-linear systems" } else { "linear systems" });
    let mut systems: Vec<_> = s.systems.iter().filter(|x| x.nonlinear == nonlinear).collect();
    systems.sort_by_key(|x| x.eq_index);
    for x in systems {
        let calls = x.calls.max(1) as f64;
        if nonlinear {
            omclog::info!(STATS_V, true, "Non-linear system {} of size {} solver statistics:", x.eq_index, x.size);
            omclog::info!(STATS_V, false, " number of calls                : {}", x.calls);
            omclog::info!(STATS_V, false, " number of iterations           : {}", x.iters);
            omclog::info!(STATS_V, false, " number of function evaluations : {}", x.res_evals);
            omclog::info!(STATS_V, false, " number of jacobian evaluations : {}", x.jac_evals);
            omclog::info!(STATS_V, false, " time of jacobian evaluations   : {:.6}", x.jac);
            omclog::info!(STATS_V, false, " average time per call          : {:.6}", x.total / calls);
            omclog::info!(STATS_V, false, " total time                     : {:.6}", x.total);
        } else {
            let density = 100.0 * f64::from(x.nnz) / f64::from(x.size * x.size).max(1.0);
            omclog::info!(
                STATS_V,
                true,
                "Linear system {} with (size = {}, nonZeroElements = {}, density = {:.2} %) solver statistics:",
                x.eq_index, x.size, x.nnz, density,
            );
            omclog::info!(STATS_V, false, " number of calls                : {}", x.calls);
            omclog::info!(STATS_V, false, " average time per call          : {}", format_g(x.total / calls, 6));
            omclog::info!(STATS_V, false, " time of jacobian evaluations   : {}", format_g(x.jac, 6));
            omclog::info!(STATS_V, false, " total time                     : {}", format_g(x.total, 6));
        }
        omclog::close(STATS_V);
    }
    omclog::close(STATS_V);
}
