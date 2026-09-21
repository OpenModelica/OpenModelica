//! Boolean builtins.

use arcstr::{ArcStr, literal};

/// Logically combine two Booleans with 'and' operator.
#[inline(always)]
pub fn boolAnd(b1: bool, b2: bool) -> bool {
    b1 && b2
}

/// Logically combine two Booleans with 'or' operator.
#[inline(always)]
pub fn boolOr(b1: bool, b2: bool) -> bool {
    b1 || b2
}

/// Logically invert Boolean value using 'not' operator.
#[inline(always)]
pub fn boolNot(b: bool) -> bool {
    !b
}

/// Compares two Booleans for equality.
#[inline(always)]
pub fn boolEq(b1: bool, b2: bool) -> bool {
    b1 == b2
}

/// Returns "true" or "false" string from a boolean.
pub fn boolString(b: bool) -> ArcStr {
    if b { literal!("true") } else { literal!("false") }
}

#[cfg(test)]
#[allow(unused_imports)]
mod tests {
    use super::*;
    use crate::*;
    use std::sync::Arc;
    use std::rc::Rc;
    use arcstr::{literal, ArcStr};
    mod boolean_tests {
        use super::*;

        #[test]
        fn test_bool_and() {
            assert!(boolAnd(true, true));
            assert!(!boolAnd(true, false));
            assert!(!boolAnd(false, true));
            assert!(!boolAnd(false, false));
        }

        #[test]
        fn test_bool_or() {
            assert!(boolOr(true, false));
            assert!(boolOr(false, true));
            assert!(boolOr(true, true));
            assert!(!boolOr(false, false));
        }

        #[test]
        fn test_bool_not() {
            assert!(boolNot(false));
            assert!(!boolNot(true));
        }

        #[test]
        fn test_bool_eq() {
            assert!(boolEq(true, true));
            assert!(boolEq(false, false));
            assert!(!boolEq(true, false));
            assert!(!boolEq(false, true));
        }

        #[test]
        fn test_bool_string() {
            assert_eq!(&*boolString(true), "true");
            assert_eq!(&*boolString(false), "false");
        }
    }
}
