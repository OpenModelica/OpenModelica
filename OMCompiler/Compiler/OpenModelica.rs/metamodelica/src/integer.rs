//! Integer arithmetic, comparison, bitwise and conversion builtins.

use arcstr::{ArcStr, format};
use ordered_float::OrderedFloat;
use crate::Real;

/// Adds two Integer values.
#[inline(always)]
pub fn intAdd(i1: i32, i2: i32) -> i32 {
    i1 + i2
}

/// Subtracts two Integer values.
#[inline(always)]
pub fn intSub(i1: i32, i2: i32) -> i32 {
    i1 - i2
}

/// Multiplies two Integer values.
#[inline(always)]
pub fn intMul(i1: i32, i2: i32) -> i32 {
    i1 * i2
}

/// Divides two Integer values (truncated division).
/// Matches Modelica's div() semantics: truncates toward zero.
pub fn intDiv(i1: i32, i2: i32) -> i32 {
    i1 / i2
}

/// Calculates `mod(i1, i2)` with Modelica semantics: the result has the
/// same sign as the divisor (Euclidean-style), not the dividend.
///
/// This mirrors `modelica_mod_integer` in the C runtime:
/// `let tmp = i1 % i2; if (i2>0 && tmp<0) || (i2<0 && tmp>0) { tmp + i2 } else { tmp }`.
/// Rust's `%` (like C's) returns the sign of the dividend, so a plain
/// `i1 % i2` is wrong for negative dividends — callers like the hash-set
/// bucket index `intMod(hash, bsize)` then dereference negative indices.
pub fn intMod(i1: i32, i2: i32) -> i32 {
    let tmp = i1 % i2;
    if (i2 > 0 && tmp < 0) || (i2 < 0 && tmp > 0) {
        tmp + i2
    } else {
        tmp
    }
}

/// Returns the bigger one of two Integer values.
pub fn intMax(i1: i32, i2: i32) -> i32 {
    i1.max(i2)
}

/// Returns the smaller one of two Integer values.
pub fn intMin(i1: i32, i2: i32) -> i32 {
    i1.min(i2)
}

/// Returns the absolute value of Integer i.
pub fn intAbs(i: i32) -> i32 {
    i.abs()
}

/// Returns negative value of Integer i.
#[inline(always)]
pub fn intNeg(i: i32) -> i32 {
    -i
}

// ============================================================================
// Integer comparison functions
// ============================================================================

/// Returns whether Integer i1 is smaller than Integer i2.
#[inline(always)]
pub fn intLt(i1: i32, i2: i32) -> bool {
    i1 < i2
}

/// Returns whether Integer i1 is smaller than or equal to Integer i2.
#[inline(always)]
pub fn intLe(i1: i32, i2: i32) -> bool {
    i1 <= i2
}

/// Returns whether Integer i1 is equal to Integer i2.
#[inline(always)]
pub fn intEq(i1: i32, i2: i32) -> bool {
    i1 == i2
}

/// Returns whether Integer i1 is not equal to Integer i2.
#[inline(always)]
pub fn intNe(i1: i32, i2: i32) -> bool {
    i1 != i2
}

/// Returns whether Integer i1 is greater than or equal to Integer i2.
#[inline(always)]
pub fn intGe(i1: i32, i2: i32) -> bool {
    i1 >= i2
}

/// Returns whether Integer i1 is greater than Integer i2.
#[inline(always)]
pub fn intGt(i1: i32, i2: i32) -> bool {
    i1 > i2
}

// ============================================================================
// Integer bitwise functions
// ============================================================================

/// Returns bitwise inverted Integer number of i (~i in C).
#[inline(always)]
pub const fn intBitNot(i: i32) -> i32 {
    !i
}

/// Returns bitwise 'and' of Integers i1 and i2 (i1 & i2 in C).
#[inline(always)]
pub const fn intBitAnd(i1: i32, i2: i32) -> i32 {
    i1 & i2
}

/// Returns bitwise 'or' of Integers i1 and i2 (i1 | i2 in C).
#[inline(always)]
pub const fn intBitOr(i1: i32, i2: i32) -> i32 {
    i1 | i2
}

/// Returns bitwise 'xor' of Integers i1 and i2 (i1 ^ i2 in C).
#[inline(always)]
pub const fn intBitXor(i1: i32, i2: i32) -> i32 {
    i1 ^ i2
}

/// Returns bitwise left shift of Integer i by s bits (i << s in C).
#[inline(always)]
pub const fn intBitLShift(i: i32, s: i32) -> i32 {
    i << s
}

/// Returns bitwise right shift of Integer i by s bits (i >> s in C).
#[inline(always)]
pub const fn intBitRShift(i: i32, s: i32) -> i32 {
    i >> s
}

// ============================================================================
// Integer conversion functions
// ============================================================================

/// Converts Integer to Real.
#[inline(always)]
pub fn intReal(i: i32) -> Real {
    OrderedFloat(i as f64)
}

/// Converts Integer to String.
pub fn intString(i: i32) -> ArcStr {
    format!("{}", i)
}

#[cfg(test)]
#[allow(unused_imports)]
mod tests {
    use super::*;
    use crate::*;
    use std::sync::Arc;
    use std::rc::Rc;
    use arcstr::{literal, ArcStr};
    mod int_arithmetic_tests {
        use super::*;

        #[test]
        fn test_int_add() {
            assert_eq!(intAdd(1, 2), 3);
            assert_eq!(intAdd(-1, 1), 0);
            assert_eq!(intAdd(-1, -2), -3);
        }

        #[test]
        fn test_int_sub() {
            assert_eq!(intSub(5, 3), 2);
            assert_eq!(intSub(3, 5), -2);
            assert_eq!(intSub(0, 0), 0);
        }

        #[test]
        fn test_int_mul() {
            assert_eq!(intMul(3, 4), 12);
            assert_eq!(intMul(-3, 4), -12);
            assert_eq!(intMul(-3, -4), 12);
            assert_eq!(intMul(0, 100), 0);
        }

        #[test]
        fn test_int_div() {
            assert_eq!(intDiv(10, 3), 3);
            assert_eq!(intDiv(10, -3), -3);
            assert_eq!(intDiv(-10, 3), -3);
            assert_eq!(intDiv(-10, -3), 3);
        }

        #[test]
        fn test_int_mod() {
            // Modelica mod: result has the same sign as the divisor.
            assert_eq!(intMod(10, 3), 1);
            assert_eq!(intMod(10, -3), -2);
            assert_eq!(intMod(-10, 3), 2);
            assert_eq!(intMod(-10, -3), -1);
        }

        #[test]
        fn test_int_max() {
            assert_eq!(intMax(1, 2), 2);
            assert_eq!(intMax(2, 1), 2);
            assert_eq!(intMax(5, 5), 5);
            assert_eq!(intMax(-1, -2), -1);
        }

        #[test]
        fn test_int_min() {
            assert_eq!(intMin(1, 2), 1);
            assert_eq!(intMin(2, 1), 1);
            assert_eq!(intMin(5, 5), 5);
            assert_eq!(intMin(-1, -2), -2);
        }

        #[test]
        fn test_int_abs() {
            assert_eq!(intAbs(-5), 5);
            assert_eq!(intAbs(5), 5);
            assert_eq!(intAbs(0), 0);
        }

        #[test]
        fn test_int_neg() {
            assert_eq!(intNeg(5), -5);
            assert_eq!(intNeg(-5), 5);
            assert_eq!(intNeg(0), 0);
        }
    }

    mod int_comparison_tests {
        use super::*;

        #[test]
        fn test_int_lt() {
            assert!(intLt(1, 2));
            assert!(!intLt(2, 2));
            assert!(!intLt(2, 1));
        }

        #[test]
        fn test_int_le() {
            assert!(intLe(1, 2));
            assert!(intLe(2, 2));
            assert!(!intLe(2, 1));
        }

        #[test]
        fn test_int_eq() {
            assert!(intEq(5, 5));
            assert!(!intEq(5, 6));
        }

        #[test]
        fn test_int_ne() {
            assert!(intNe(5, 6));
            assert!(!intNe(5, 5));
        }

        #[test]
        fn test_int_ge() {
            assert!(intGe(2, 1));
            assert!(intGe(2, 2));
            assert!(!intGe(1, 2));
        }

        #[test]
        fn test_int_gt() {
            assert!(intGt(2, 1));
            assert!(!intGt(2, 2));
            assert!(!intGt(1, 2));
        }
    }

    mod int_bitwise_tests {
        use super::*;

        #[test]
        fn test_int_bit_not() {
            assert_eq!(intBitNot(0i32), -1);
            assert_eq!(intBitNot(-1i32), 0);
            assert_eq!(intBitNot(1), !1);
        }

        #[test]
        fn test_int_bit_and() {
            assert_eq!(intBitAnd(0b1100, 0b1010), 0b1000);
            assert_eq!(intBitAnd(0, 5), 0);
        }

        #[test]
        fn test_int_bit_or() {
            assert_eq!(intBitOr(0b1100, 0b1010), 0b1110);
            assert_eq!(intBitOr(0, 5), 5);
        }

        #[test]
        fn test_int_bit_xor() {
            assert_eq!(intBitXor(0b1100, 0b1010), 0b0110);
            assert_eq!(intBitXor(5, 5), 0);
        }

        #[test]
        fn test_int_bit_l_shift() {
            assert_eq!(intBitLShift(1, 3), 8);
            assert_eq!(intBitLShift(3, 1), 6);
        }

        #[test]
        fn test_int_bit_r_shift() {
            assert_eq!(intBitRShift(8, 3), 1);
            assert_eq!(intBitRShift(6, 1), 3);
        }
    }

    mod int_conversion_tests {
        use super::*;

        #[test]
        fn test_int_real() {
            assert_eq!(intReal(42), OrderedFloat(42.0_f64));
            assert_eq!(intReal(-7), OrderedFloat(-7.0_f64));
        }

        #[test]
        fn test_int_string() {
            assert_eq!(&*intString(42), "42");
            assert_eq!(&*intString(-7), "-7");
            assert_eq!(&*intString(0), "0");
        }
    }
}
