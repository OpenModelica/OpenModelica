//! Option predicates and miscellaneous builtins.

use anyhow::{Result, bail};

/// Returns true if the Option is NONE.
pub fn isNone<A>(opt: Option<A>) -> bool {
    opt.is_none()
}

/// Returns true if the Option is SOME.
pub fn isSome<A>(opt: Option<A>) -> bool {
    opt.is_some()
}

// ============================================================================
// Misc builtin functions
// ============================================================================

/// Sets the stack overflow signal to the given value and returns the old one.
/// In this translation, simply returns the input value. Infallible (see the
/// `Infallible` classification in mmtorust's fallibility analysis), so it
/// returns a bare `bool` — call sites do not add `?`.
pub fn setStackOverflowSignal(in_signal: bool) -> bool {
    in_signal
}

/// Returns true if the formal output argument is present as an actual argument.
/// In MetaModelica this is a compile-time check; in Rust it always returns true
/// because the argument exists at the call site.
pub fn isPresent<T>(_ident: &T) -> Result<bool> {
    Ok(true)
}

/// Fail function - unconditionally raises an error.
pub fn fail() -> Result<()> {
    bail!("fail() was called - unrecoverable error")
}

#[cfg(test)]
#[allow(unused_imports)]
mod tests {
    use super::*;
    use crate::*;
    use std::sync::Arc;
    use std::rc::Rc;
    use arcstr::{literal, ArcStr};
    mod misc_builtin_tests {
        use super::*;

        #[test]
        fn test_set_stack_overflow_signal() {
            assert!(setStackOverflowSignal(true));
            assert!(!setStackOverflowSignal(false));
        }

        #[test]
        fn test_is_present() {
            // Always returns true in Rust translation
            assert!(isPresent(&42).unwrap());
            assert!(isPresent(&"hello").unwrap());
        }

        #[test]
        fn test_fail() {
            assert!(fail().is_err());
        }

        #[test]
        fn test_source_info() {
            let info = SourceInfo {
                fileName: literal!("test.mo"),
                isReadOnly: true,
                lineNumberStart: 1,
                columnNumberStart: 1,
                lineNumberEnd: 10,
                columnNumberEnd: 50,
                lastModification: OrderedFloat(1234567890.0),
            };
            assert_eq!(info.fileName, "test.mo");
            assert!(info.isReadOnly);
            assert_eq!(info.lineNumberStart, 1);
        }
    }
}
