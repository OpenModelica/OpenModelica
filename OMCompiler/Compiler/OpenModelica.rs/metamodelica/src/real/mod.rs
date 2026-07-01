//! Real arithmetic, comparison and conversion builtins.
//! The shortest-round-trip string formatter lives in [`ryu`].

use anyhow::{Result, bail};
use ordered_float::OrderedFloat;
use crate::Real;

pub mod ryu;
pub use ryu::*;

/// Adds two Real values.
#[inline(always)]
pub fn realAdd(r1: Real, r2: Real) -> Real {
    r1 + r2
}

/// Subtracts two Real values.
#[inline(always)]
pub fn realSub(r1: Real, r2: Real) -> Real {
    r1 - r2
}

/// Multiplies two Real values.
#[inline(always)]
pub fn realMul(r1: Real, r2: Real) -> Real {
    r1 * r2
}

/// Divides two Real values.
#[inline(always)]
pub fn realDiv(r1: Real, r2: Real) -> Real {
    r1 / r2
}

/// Real division `/` with MetaModelica failure semantics: dividing by exactly
/// zero is a *recoverable* MetaModelica failure, not `inf`/`nan`. The C runtime
/// generated for every `Real / Real` emits `if (denom == 0) goto fail;` before
/// the division, so a zero divisor fails the enclosing `match`/`matchcontinue`
/// arm rather than producing a non-finite constant. mmtorust lowers the `/`
/// operator (`BinOpKind::Div`) through this helper so the same observable
/// behaviour holds — e.g. `ExpressionSimplify.simplifyBinaryConst` must *fail*
/// on `1.0 / 0.0` (leaving the expression unsimplified) instead of folding it
/// to `RCONST(inf)`.
#[inline(always)]
pub fn real_div_checked(r1: Real, r2: Real) -> Result<Real> {
    if r2.0 == 0.0 {
        bail!("Real division by zero");
    }
    Ok(r1 / r2)
}

/// Calculates remainder of Real division r1/r2.
pub fn realMod(r1: Real, r2: Real) -> Real {
    OrderedFloat(r1.0 - (r1.0/r2.0).floor()*r2.0)
}

/// Raises r1 to the power r2 (r1^r2).
pub fn realPow(r1: Real, r2: Real) -> Real {
    OrderedFloat(r1.0.powf(r2.0))
}

/// Returns the bigger one of two Real values.
#[inline(always)]
pub fn realMax(r1: Real, r2: Real) -> Real {
    OrderedFloat(r1.0.max(r2.0))
}

/// Returns the smaller one of two Real values.
#[inline(always)]
pub fn realMin(r1: Real, r2: Real) -> Real {
    OrderedFloat(r1.0.min(r2.0))
}

/// Returns the absolute value of Real x.
#[inline(always)]
pub fn realAbs(x: Real) -> Real {
    OrderedFloat(x.0.abs())
}

/// Returns whether two Real values are approximately equal within absTol.
pub fn realAlmostEq(a: Real, b: Real, abs_tol: Real) -> bool {
    abs_tol.0 > (a.0 - b.0).abs()
}

/// Returns negative value of Real x.
#[inline(always)]
pub fn realNeg(x: Real) -> Real {
    -x
}

/// Modelica `sign(v)` builtin: the signum of a Real, returning an Integer
/// `-1`, `0`, or `1` (see ModelicaBuiltin.mo `function sign`). Note this is
/// NOT `f64::signum`, which returns `±1.0` for zero/negative-zero; Modelica
/// requires `sign(0) == 0`. Integer arguments are coerced to Real at the call
/// site (the builtin's formal is `Real v`), so a single Real overload suffices.
#[inline(always)]
pub fn sign(v: Real) -> i32 {
    if v.0 > 0.0 { 1 } else if v.0 < 0.0 { -1 } else { 0 }
}

// ============================================================================
// Real comparison functions
// ============================================================================

/// Returns whether Real x1 is smaller than Real x2.
#[inline(always)]
pub fn realLt(x1: Real, x2: Real) -> bool {
    x1 < x2
}

/// Returns whether Real x1 is smaller than or equal to Real x2.
#[inline(always)]
pub fn realLe(x1: Real, x2: Real) -> bool {
    x1 <= x2
}

/// Returns whether Real x1 is equal to Real x2.
#[inline(always)]
pub fn realEq(x1: Real, x2: Real) -> bool {
    x1 == x2
}

/// Returns whether Real x1 is not equal to Real x2.
#[inline(always)]
pub fn realNe(x1: Real, x2: Real) -> bool {
    x1 != x2
}

/// Returns whether Real x1 is greater than or equal to Real x2.
#[inline(always)]
pub fn realGe(x1: Real, x2: Real) -> bool {
    x1 >= x2
}

/// Returns whether Real x1 is greater than Real x2.
#[inline(always)]
pub fn realGt(x1: Real, x2: Real) -> bool {
    x1 > x2
}

// ============================================================================
// Real conversion functions
// ============================================================================

/// Converts Real to Integer (truncates toward zero, matching Modelica integer() function).
pub fn realInt(r: Real) -> i32 {
    r.0 as i32
}

#[cfg(test)]
#[allow(unused_imports)]
mod tests {
    use super::*;
    use crate::*;
    use std::sync::Arc;
    use std::rc::Rc;
    use arcstr::{literal, ArcStr};
    mod real_arithmetic_tests {
        use super::*;
        fn r(x: f64) -> Real { OrderedFloat(x) }

        #[test]
        fn test_real_add() {
            assert_eq!(realAdd(r(1.5), r(2.5)), r(4.0));
            assert_eq!(realAdd(r(-1.0), r(1.0)), r(0.0));
        }

        #[test]
        fn test_real_sub() {
            assert_eq!(realSub(r(5.0), r(3.0)), r(2.0));
            assert_eq!(realSub(r(3.0), r(5.0)), r(-2.0));
        }

        #[test]
        fn test_real_mul() {
            assert_eq!(realMul(r(3.0), r(4.0)), r(12.0));
            assert_eq!(realMul(r(-3.0), r(4.0)), r(-12.0));
        }

        #[test]
        fn test_real_div() {
            assert_eq!(realDiv(r(10.0), r(3.0)), r(10.0 / 3.0));
            assert_eq!(realDiv(r(6.0), r(2.0)), r(3.0));
        }

        #[test]
        fn test_real_mod() {
            assert_eq!(realMod(r(10.0), r(3.0)), r(1.0));
            assert_eq!(realMod(r(10.5), r(3.0)), r(1.5));
        }

        #[test]
        fn test_real_pow() {
            assert_eq!(realPow(r(2.0), r(3.0)), r(8.0));
            assert_eq!(realPow(r(9.0), r(0.5)), r(3.0));
        }

        #[test]
        fn test_real_max() {
            assert_eq!(realMax(r(1.5), r(2.5)), r(2.5));
            assert_eq!(realMax(r(5.0), r(5.0)), r(5.0));
        }

        #[test]
        fn test_real_min() {
            assert_eq!(realMin(r(1.5), r(2.5)), r(1.5));
            assert_eq!(realMin(r(5.0), r(5.0)), r(5.0));
        }

        #[test]
        fn test_real_abs() {
            assert_eq!(realAbs(r(-5.5)), r(5.5));
            assert_eq!(realAbs(r(5.5)), r(5.5));
        }

        #[test]
        fn test_real_almost_eq() {
            assert!(realAlmostEq(r(1.0), r(1.0000001), r(1e-5)));
            assert!(!realAlmostEq(r(1.0), r(1.1), r(1e-5)));
            assert!(realAlmostEq(r(1.0), r(1.0), r(1e-6)));
        }

        #[test]
        fn test_real_neg() {
            assert_eq!(realNeg(r(5.5)), r(-5.5));
            assert_eq!(realNeg(r(-5.5)), r(5.5));
        }
    }

    mod real_comparison_tests {
        use super::*;
        fn r(x: f64) -> Real { OrderedFloat(x) }

        #[test]
        fn test_real_lt() {
            assert!(realLt(r(1.0), r(2.0)));
            assert!(!realLt(r(2.0), r(2.0)));
            assert!(!realLt(r(2.0), r(1.0)));
        }

        #[test]
        fn test_real_le() {
            assert!(realLe(r(1.0), r(2.0)));
            assert!(realLe(r(2.0), r(2.0)));
            assert!(!realLe(r(2.0), r(1.0)));
        }

        #[test]
        fn test_real_eq() {
            assert!(realEq(r(1.0), r(1.0)));
            assert!(!realEq(r(1.0), r(2.0)));
        }

        #[test]
        fn test_real_ne() {
            assert!(realNe(r(1.0), r(2.0)));
            assert!(!realNe(r(1.0), r(1.0)));
        }

        #[test]
        fn test_real_ge() {
            assert!(realGe(r(2.0), r(1.0)));
            assert!(realGe(r(2.0), r(2.0)));
            assert!(!realGe(r(1.0), r(2.0)));
        }

        #[test]
        fn test_real_gt() {
            assert!(realGt(r(2.0), r(1.0)));
            assert!(!realGt(r(2.0), r(2.0)));
            assert!(!realGt(r(1.0), r(2.0)));
        }
    }

    mod real_conversion_tests {
    use super::*;
    fn r(x: f64) -> Real { OrderedFloat(x) }

        #[test]
        fn test_real_int() {
            assert_eq!(realInt(r(3.7)), 3);
            assert_eq!(realInt(r(-3.7)), -3);
            assert_eq!(realInt(r(3.0)), 3);
        }
    }
}
