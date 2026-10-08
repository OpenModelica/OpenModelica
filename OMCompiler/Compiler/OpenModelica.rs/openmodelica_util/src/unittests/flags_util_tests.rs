// Tests for crate::FlagsUtil
//
// The Rust source is auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/Util/FlagsUtil.mo
//
// `FlagsUtil.new` is the compiler's flag bootstrap: it lazily creates the global
// flags structure (via `loadFlags`) and then parses the command-line arguments.
// `loadFlags` relies on `Flags.getFlags` *failing* when the flags global root has
// never been set, so that the `else` branch runs once to create and store the
// default flags. If `getFlags` instead returns the uninitialised `NO_FLAGS`
// sentinel without failing, the flags are never created and every later
// `FLAGS(...)` pattern match (e.g. `Flags.isSet`) fails with a pattern mismatch.
//
// Each test runs on its own thread, and the global roots are thread-locals, so
// the flags start uninitialised in every test — exactly the first-call state.

use metamodelica::nil;
use arcstr::literal;
use crate::{Flags, FlagsUtil, Global};

/// `loadFlags(true)` on a fresh (never-initialised) flags root must create the
/// flags structure and return a `FLAGS(..)` value, not the `NO_FLAGS` sentinel.
#[test]
fn load_flags_initializes_when_unset() {
    let flags = FlagsUtil::loadFlags(true).expect("loadFlags should not fail");
    assert!(
        matches!(flags, Flags::Flag::FLAGS { .. }),
        "loadFlags(true) must initialise the flags, got {flags:?}",
    );
}

/// After `new`, the flags global root holds an initialised `FLAGS(..)`.
#[test]
fn new_initializes_global_flags() {
    FlagsUtil::new(nil()).expect("FlagsUtil::new should not fail");
    let flags = Flags::getFlags(true);
    assert!(
        matches!(flags, Flags::Flag::FLAGS { .. }),
        "after new(), getFlags must return FLAGS, got {flags:?}",
    );
}

/// With the flags initialised, reading a debug flag must succeed and return its
/// declared default (`failtrace` defaults to false). Before the fix this fails
/// with a `pattern mismatch` because the flags are still `NO_FLAGS`.
#[test]
fn is_set_reads_default_after_new() {
    FlagsUtil::new(nil()).expect("FlagsUtil::new should not fail");
    let failtrace = Flags::isSet(Flags::FAILTRACE.clone()).expect("isSet should not fail");
    assert!(!failtrace, "failtrace defaults to false");
}

/// Non-flag arguments (e.g. a model filename) are passed through unconsumed.
#[test]
fn new_passes_through_non_flag_args() {
    let out = FlagsUtil::new(metamodelica::list![literal!("model.mo")])
        .expect("FlagsUtil::new should not fail");
    let out: Vec<_> = (&*out).into_iter().cloned().collect();
    assert_eq!(out, vec![literal!("model.mo")]);
}

/// Regression test for the real `Main.init` boot sequence: `Global.initialize()`
/// runs *before* `FlagsUtil.new`. `Global.initialize` (Global.mo) deliberately
/// does NOT touch the flags root — but the hand-written Rust port once reset it
/// to `NO_FLAGS`, which undid the eager seed in `Globals::flagsIndex`. Because
/// the Rust `getFlags` is infallible (it returns the slot value rather than
/// throwing on an unset root the way MetaModelica's `getGlobalRoot` does),
/// `loadFlags`'s `try … else (re)initialize` never re-created the defaults, and
/// the next `getConfigValue` pattern-mismatched on `NO_FLAGS`.
///
/// This reproduces `omc --help` crashing in `evaluateConfigFlag →
/// getConfigString → getConfigValue`. The earlier tests miss it because they
/// never call `Global::initialize()`, so the slot keeps its seeded `FLAGS(..)`.
#[test]
fn config_value_usable_after_global_initialize_then_new() {
    Global::initialize();
    FlagsUtil::new(nil()).expect("FlagsUtil::new should not fail after Global::initialize");
    // Reading any config flag exercises `getConfigValue`'s `FLAGS(..)` pattern,
    // which is what crashed when the flags were left as `NO_FLAGS`.
    let mode = Flags::getConfigString(Flags::INTERACTIVE.clone())
        .expect("getConfigString must not fail after initialize + new");
    assert_eq!(mode, literal!("none"), "INTERACTIVE defaults to \"none\"");
}
