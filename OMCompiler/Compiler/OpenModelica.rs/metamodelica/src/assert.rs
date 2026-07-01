//! Runtime assertion reporting and the `omc_assert!` macro.

/// Host hook invoked by [`omc_assert!`] before the assertion fails. This is
/// the analogue of the C runtime's `omc_assert` function pointer
/// (`SimulationRuntime/c/util/omc_error.c`): the compiler binds it (via
/// `ErrorExt.initAssertionFunctions`) to `omc_assert_compiler`, which appends a
/// `RUNTIME`/`Error` message to the error buffer, while the simulation runtime
/// would bind its own logger. When unbound the message survives only through
/// the returned error, matching a runtime that never installed a reporter.
static ASSERT_HOOK: std::sync::OnceLock<fn(&str)> = std::sync::OnceLock::new();

/// Bind the assertion reporter, mirroring the assignment of the `omc_assert`
/// function pointer in `Error_initAssertionFunctions`. The first binding wins,
/// matching the single init call performed at startup; later calls are ignored.
pub fn setAssertHook(hook: fn(&str)) {
    let _ = ASSERT_HOOK.set(hook);
}

/// Report an assertion message through the bound hook, if any. Called by the
/// [`omc_assert!`] macro immediately before it fails the surrounding
/// computation. Reading the `OnceLock` is lock-free after startup, so this is
/// safe to reach from any thread and adds no contention on the (cold) assert
/// path.
pub fn reportAssert(msg: &str) {
    if let Some(hook) = ASSERT_HOOK.get() {
        hook(msg);
    }
}

/// Runtime assertion mirroring the C `omc_assert(threadData, info, fmt, ...)`.
/// It reports the formatted message to the host error subsystem (see
/// [`setAssertHook`]) and then fails the current computation with that message
/// — the analogue of `omc_assert`'s `MMC_THROW`, which a surrounding
/// matchcontinue catches. Use it wherever a ported runtime function would call
/// `omc_assert`, instead of a bare `bail!`, so the message reaches
/// `getErrorString`.
#[macro_export]
macro_rules! omc_assert {
    ($($arg:tt)*) => {{
        let __msg: ::std::string::String = ::std::format!($($arg)*);
        $crate::reportAssert(&__msg);
        ::anyhow::bail!(__msg)
    }};
}
