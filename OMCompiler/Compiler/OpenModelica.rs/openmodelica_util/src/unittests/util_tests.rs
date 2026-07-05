// Tests for crate::Util
//
// The Rust source is auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/Util/Util.mo
//
// Tests with correct expectations that WILL FAIL expose implementation bugs.
// Bug summary (known at time of writing):
//   - nextPowerOf2: uses intBitLShift instead of intBitRShift → wrong results for all n>1
//   - realRangeSize: missing parentheses → `inStart/inStep` subtracted from `inStop`
//                    instead of `(inStop-inStart)/inStep`

use anyhow::Result;
use std::sync::Arc;
use metamodelica::*;
use arcstr::{ArcStr, literal};
use crate::Util as U;

// ── boolInt ───────────────────────────────────────────────────────────────────

#[test]
fn test_bool_int_true() {
    assert_eq!(U::boolInt(true), 1);
}

#[test]
fn test_bool_int_false() {
    assert_eq!(U::boolInt(false), 0);
}

// ── intBool ───────────────────────────────────────────────────────────────────

#[test]
fn test_int_bool_zero_is_false() {
    assert!(!U::intBool(0));
}

#[test]
fn test_int_bool_positive_is_true() {
    assert!(U::intBool(1));
    assert!(U::intBool(42));
}

#[test]
fn test_int_bool_negative_is_false() {
    // MetaModelica spec: "Returns true if the given integer is larger than 0"
    // So negative values are false.
    assert!(!U::intBool(-1));
}

// ── boolCompare ───────────────────────────────────────────────────────────────

#[test]
fn test_bool_compare_equal() {
    assert_eq!(U::boolCompare(true, true), 0);
    assert_eq!(U::boolCompare(false, false), 0);
}

#[test]
fn test_bool_compare_true_greater() {
    assert_eq!(U::boolCompare(true, false), 1);
}

#[test]
fn test_bool_compare_false_lesser() {
    assert_eq!(U::boolCompare(false, true), -1);
}

// ── intSign ───────────────────────────────────────────────────────────────────

#[test]
fn test_int_sign_positive() {
    assert_eq!(U::intSign(5), 1);
    assert_eq!(U::intSign(1), 1);
}

#[test]
fn test_int_sign_zero() {
    assert_eq!(U::intSign(0), 0);
}

#[test]
fn test_int_sign_negative() {
    assert_eq!(U::intSign(-3), -1);
    assert_eq!(U::intSign(-1), -1);
}

// ── intCompare ────────────────────────────────────────────────────────────────

#[test]
fn test_int_compare_equal() {
    assert_eq!(U::intCompare(5, 5), 0);
    assert_eq!(U::intCompare(0, 0), 0);
}

#[test]
fn test_int_compare_greater() {
    assert_eq!(U::intCompare(10, 5), 1);
}

#[test]
fn test_int_compare_lesser() {
    assert_eq!(U::intCompare(3, 7), -1);
}

// ── realCompare ───────────────────────────────────────────────────────────────

#[test]
fn test_real_compare_equal() {
    use metamodelica::OrderedFloat;
    assert_eq!(U::realCompare(OrderedFloat(1.0), OrderedFloat(1.0)), 0);
}

#[test]
fn test_real_compare_greater() {
    use metamodelica::OrderedFloat;
    assert_eq!(U::realCompare(OrderedFloat(2.5), OrderedFloat(1.0)), 1);
}

#[test]
fn test_real_compare_lesser() {
    use metamodelica::OrderedFloat;
    assert_eq!(U::realCompare(OrderedFloat(0.5), OrderedFloat(1.0)), -1);
}

// ── isIntGreater / isRealGreater ──────────────────────────────────────────────

#[test]
fn test_is_int_greater() {
    assert!(U::isIntGreater(5, 3));
    assert!(!U::isIntGreater(3, 5));
    assert!(!U::isIntGreater(3, 3));
}

#[test]
fn test_is_real_greater() {
    use metamodelica::OrderedFloat;
    assert!(U::isRealGreater(OrderedFloat(2.0), OrderedFloat(1.0)));
    assert!(!U::isRealGreater(OrderedFloat(1.0), OrderedFloat(2.0)));
    assert!(!U::isRealGreater(OrderedFloat(1.0), OrderedFloat(1.0)));
}

// ── intGreaterZero / intPositive / intNegative ────────────────────────────────

#[test]
fn test_int_greater_zero() {
    assert!(U::intGreaterZero(1));
    assert!(!U::intGreaterZero(0));
    assert!(!U::intGreaterZero(-1));
}

#[test]
fn test_int_positive() {
    assert!(U::intPositive(1));
    // MetaModelica spec: "Returns true if integer value is positive (>= 0)"
    // So 0 IS considered positive (non-negative).
    assert!(U::intPositive(0), "intPositive(0) should be true: spec uses '>= 0'");
    assert!(!U::intPositive(-1));
}

#[test]
fn test_int_negative() {
    assert!(U::intNegative(-1));
    assert!(!U::intNegative(0));
    assert!(!U::intNegative(1));
}

// ── realNegative ──────────────────────────────────────────────────────────────

#[test]
fn test_real_negative() {
    use metamodelica::OrderedFloat;
    assert!(U::realNegative(OrderedFloat(-1.0)));
    assert!(!U::realNegative(OrderedFloat(0.0)));
    assert!(!U::realNegative(OrderedFloat(1.0)));
}

// ── gcd ───────────────────────────────────────────────────────────────────────

#[test]
fn test_gcd_basic() {
    assert_eq!(U::gcd(12, 8), 4);
    assert_eq!(U::gcd(15, 10), 5);
    assert_eq!(U::gcd(7, 3), 1);
}

#[test]
fn test_gcd_with_zero() {
    assert_eq!(U::gcd(0, 5), 5);
    assert_eq!(U::gcd(5, 0), 5);
}

#[test]
fn test_gcd_equal() {
    assert_eq!(U::gcd(6, 6), 6);
}

// ── lcm ───────────────────────────────────────────────────────────────────────

#[test]
fn test_lcm_basic() {
    assert_eq!(U::lcm(4, 6), 12);
    assert_eq!(U::lcm(3, 7), 21);
    assert_eq!(U::lcm(5, 5), 5);
}

#[test]
fn test_lcm_negative_returns_minus_one() {
    // MetaModelica spec: lcm returns -1 when either argument is negative
    assert_eq!(U::lcm(-4, 6), -1);
    assert_eq!(U::lcm(4, -6), -1);
}

// ── nextPrime ─────────────────────────────────────────────────────────────────

#[test]
fn test_next_prime_one() {
    assert_eq!(U::nextPrime(1), 2);
}

#[test]
fn test_next_prime_two() {
    assert_eq!(U::nextPrime(2), 2);
}

#[test]
fn test_next_prime_three() {
    assert_eq!(U::nextPrime(3), 3);
}

#[test]
fn test_next_prime_four() {
    assert_eq!(U::nextPrime(4), 5);
}

#[test]
fn test_next_prime_nine() {
    assert_eq!(U::nextPrime(9), 11);
}

#[test]
fn test_next_prime_ten() {
    assert_eq!(U::nextPrime(10), 11);
}

// ── nextPowerOf2 ──────────────────────────────────────────────────────────────
//
// BUG: The implementation uses intBitLShift (left shift) instead of intBitRShift
// (right shift). The standard "fill bits then add 1" algorithm requires RIGHT
// shifts to propagate the most-significant set bit downward.  With left shifts
// the high bits of v overflow into the sign bit for almost all inputs, producing
// wrong (often negative) results.
//
// MetaModelica source has the same bug; the docstring says "Rounds up to the
// nearest power of 2" but the left-shift algorithm does not do that.
//
// Expected vs actual:
//   nextPowerOf2(1)  -> 1  (correct by coincidence: v=0, all shifts of 0 are 0, 0+1=1)
//   nextPowerOf2(2)  -> should be 2,  actual: 0
//   nextPowerOf2(3)  -> should be 4,  actual: -1
//   nextPowerOf2(4)  -> should be 4,  actual: 0
//   nextPowerOf2(5)  -> should be 8,  actual: -3
//   nextPowerOf2(9)  -> should be 16, actual: wrong

#[test]
fn test_next_power_of_2_one() {
    assert_eq!(U::nextPowerOf2(1), 1);
}

#[test]
fn test_next_power_of_2_two() {
    // BUG: should be 2, actual result is 0 due to left-shift overflow
    assert_eq!(U::nextPowerOf2(2), 2);
}

#[test]
fn test_next_power_of_2_three() {
    // BUG: should be 4, actual result is -1 due to left-shift overflow
    assert_eq!(U::nextPowerOf2(3), 4);
}

#[test]
fn test_next_power_of_2_exact_power() {
    // BUG: should be 4, actual result is 0 due to left-shift overflow
    assert_eq!(U::nextPowerOf2(4), 4);
}

#[test]
fn test_next_power_of_2_five() {
    // BUG: should be 8, actual result is -3 due to left-shift overflow
    assert_eq!(U::nextPowerOf2(5), 8);
}

#[test]
fn test_next_power_of_2_nine() {
    // BUG: should be 16, actual result is wrong due to left-shift overflow
    assert_eq!(U::nextPowerOf2(9), 16);
}

// ── msb ───────────────────────────────────────────────────────────────────────

#[test]
fn test_msb_one() {
    // msb counts right-shifts to reach 0: 1>>1=0 → 1 step
    assert_eq!(U::msb(1), 1);
}

#[test]
fn test_msb_two() {
    // 2>>1=1>>1=0 → 2 steps
    assert_eq!(U::msb(2), 2);
}

#[test]
fn test_msb_four() {
    // 4>>1=2>>1=1>>1=0 → 3 steps
    assert_eq!(U::msb(4), 3);
}

#[test]
fn test_msb_seven() {
    // 7>>1=3>>1=1>>1=0 → 3 steps
    assert_eq!(U::msb(7), 3);
}

#[test]
fn test_msb_eight() {
    // 8>>1=4>>1=2>>1=1>>1=0 → 4 steps
    assert_eq!(U::msb(8), 4);
}

// ── intPow ────────────────────────────────────────────────────────────────────

#[test]
fn test_int_pow_zero_exponent() -> Result<()> {
    assert_eq!(U::intPow(5, 0)?, 1);
    Ok(())
}

#[test]
fn test_int_pow_basic() -> Result<()> {
    assert_eq!(U::intPow(2, 10)?, 1024);
    assert_eq!(U::intPow(3, 3)?, 27);
    Ok(())
}

#[test]
fn test_int_pow_base_one() -> Result<()> {
    assert_eq!(U::intPow(1, 100)?, 1);
    Ok(())
}

#[test]
fn test_int_pow_negative_exponent_errors() {
    assert!(U::intPow(2, -1).is_err(), "negative exponent should be an error");
}

// ── realRangeSize ─────────────────────────────────────────────────────────────
//
// BUG: The formula is:
//   outSize = floor(inStop - inStart / inStep + 5e-15) + 1
// but the correct formula (from MetaModelica source) is:
//   outSize = floor((inStop - inStart) / inStep + 5e-15) + 1
//
// Due to Rust operator precedence, `/` binds tighter than `-`, so the Rust
// translation computes `inStart / inStep` BEFORE subtracting from `inStop`.
// This gives completely wrong results when inStart != 0.
//
// Concrete examples:
//   realRangeSize(1.0, 0.5, 3.0):
//     correct:  floor((3.0 - 1.0) / 0.5 + ε) + 1 = floor(4.0 + ε) + 1 = 5
//     actual:   floor(3.0 - 1.0/0.5 + ε) + 1 = floor(1.0 + ε) + 1 = 2
//
//   realRangeSize(2.0, 0.5, 3.0):
//     correct:  floor((3.0 - 2.0) / 0.5 + ε) + 1 = floor(2.0 + ε) + 1 = 3
//     actual:   floor(3.0 - 2.0/0.5 + ε) + 1 = floor(-1.0 + ε) + 1 = 0 (after max with 0)

#[test]
fn test_real_range_size_unit_step() {
    use metamodelica::OrderedFloat;
    // range 0..=4 step 1.0 → 5 elements
    let n = U::realRangeSize(OrderedFloat(0.0), OrderedFloat(1.0), OrderedFloat(4.0)).unwrap();
    assert_eq!(n, 5, "range 0..=4 step 1.0 should have 5 elements");
}

#[test]
fn test_real_range_size_half_step() {
    use metamodelica::OrderedFloat;
    // range 1..=3 step 0.5 → 1.0, 1.5, 2.0, 2.5, 3.0 → 5 elements
    // BUG: actual returns 2 instead of 5
    let n = U::realRangeSize(OrderedFloat(1.0), OrderedFloat(0.5), OrderedFloat(3.0)).unwrap();
    assert_eq!(n, 5, "range 1..=3 step 0.5 should have 5 elements");
}

#[test]
fn test_real_range_size_step_two() {
    use metamodelica::OrderedFloat;
    // range 1..=5 step 2.0 → 1.0, 3.0, 5.0 → 3 elements
    // BUG: actual returns floor(5.0 - 1.0/2.0 + ε) + 1 = floor(4.5) + 1 = 5 instead of 3
    let n = U::realRangeSize(OrderedFloat(1.0), OrderedFloat(2.0), OrderedFloat(5.0)).unwrap();
    assert_eq!(n, 3, "range 1..=5 step 2.0 should have 3 elements");
}

#[test]
fn test_real_range_size_single_element() {
    use metamodelica::OrderedFloat;
    // range start==stop → always 1 element regardless of step
    let n = U::realRangeSize(OrderedFloat(3.0), OrderedFloat(1.0), OrderedFloat(3.0)).unwrap();
    assert_eq!(n, 1, "range start==stop should have 1 element");
}

// ── isNotEmptyString ──────────────────────────────────────────────────────────

#[test]
fn test_is_not_empty_string() {
    assert!(!U::isNotEmptyString(literal!("")));
    assert!(U::isNotEmptyString(literal!("x")));
    assert!(U::isNotEmptyString(literal!("hello world")));
}

// ── removeLast3Char / removeLast4Char / removeLastNChar ───────────────────────

#[test]
fn test_remove_last_3_char() -> Result<()> {
    assert_eq!(U::removeLast3Char(literal!("hello"))?, literal!("he"));
    Ok(())
}

#[test]
fn test_remove_last_4_char() -> Result<()> {
    assert_eq!(U::removeLast4Char(literal!("hello"))?, literal!("h"));
    Ok(())
}

#[test]
fn test_remove_last_n_char() -> Result<()> {
    assert_eq!(U::removeLastNChar(literal!("hello"), 2)?, literal!("hel"));
    assert_eq!(U::removeLastNChar(literal!("hello"), 0)?, literal!("hello"));
    Ok(())
}

#[test]
fn test_remove_last_3_char_too_short_errors() {
    // substring(s, 1, len-3) with len < 3 → stop < start (or stop < 1) → error
    let result = U::removeLast3Char(literal!("ab"));
    assert!(result.is_err(), "removeLast3Char('ab') should error: substring stop < 1");
}

// ── swap ─────────────────────────────────────────────────────────────────────

#[test]
fn test_swap_true_swaps() {
    assert_eq!(U::swap(true, 1i32, 2i32), (2, 1));
}

#[test]
fn test_swap_false_keeps_order() {
    assert_eq!(U::swap(false, 1i32, 2i32), (1, 2));
}

// ── makeOption / makeOptionOnTrue ─────────────────────────────────────────────

#[test]
fn test_make_option() {
    assert_eq!(U::makeOption(42i32), Some(42));
    assert_eq!(U::makeOption(literal!("hello")), Some(literal!("hello")));
}

#[test]
fn test_make_option_on_true() {
    assert_eq!(U::makeOptionOnTrue(true, 42i32), Some(42));
    assert_eq!(U::makeOptionOnTrue(false, 42i32), None);
}

// ── getOption / getOptionOrDefault ───────────────────────────────────────────

#[test]
fn test_get_option_some() -> Result<()> {
    assert_eq!(U::getOption(Some(42i32))?, 42);
    Ok(())
}

#[test]
fn test_get_option_none_errors() {
    let result = U::getOption::<i32>(None);
    assert!(result.is_err(), "getOption(None) should return an error");
}

#[test]
fn test_get_option_or_default() {
    assert_eq!(U::getOptionOrDefault(Some(42i32), 0), 42);
    assert_eq!(U::getOptionOrDefault(None, 0i32), 0);
}

// ── optionEqual ───────────────────────────────────────────────────────────────

#[test]
fn test_option_equal_both_none() {
    let eq_fn: Arc<dyn Fn(i32, i32) -> Result<bool>> =
        Arc::new(|a, b| Ok(a == b));
    assert!(U::optionEqual(None::<i32>, None::<i32>, eq_fn).unwrap());
}

#[test]
fn test_option_equal_both_some_equal() {
    let eq_fn: Arc<dyn Fn(i32, i32) -> Result<bool>> =
        Arc::new(|a, b| Ok(a == b));
    assert!(U::optionEqual(Some(5i32), Some(5i32), eq_fn).unwrap());
}

#[test]
fn test_option_equal_both_some_not_equal() {
    let eq_fn: Arc<dyn Fn(i32, i32) -> Result<bool>> =
        Arc::new(|a, b| Ok(a == b));
    assert!(!U::optionEqual(Some(5i32), Some(6i32), eq_fn).unwrap());
}

#[test]
fn test_option_equal_one_none() {
    let eq_fn: Arc<dyn Fn(i32, i32) -> Result<bool>> =
        Arc::new(|a, b| Ok(a == b));
    assert!(!U::optionEqual(Some(5i32), None, eq_fn.clone()).unwrap());
    assert!(!U::optionEqual(None, Some(5i32), eq_fn).unwrap());
}

// ── applyOption ───────────────────────────────────────────────────────────────

#[test]
fn test_apply_option_some() {
    let double: Arc<dyn Fn(i32) -> Result<i32>> = Arc::new(|x| Ok(x * 2));
    assert_eq!(U::applyOption(Some(5i32), double).unwrap(), Some(10));
}

#[test]
fn test_apply_option_none() {
    let double: Arc<dyn Fn(i32) -> Result<i32>> = Arc::new(|x| Ok(x * 2));
    assert_eq!(U::applyOption(None::<i32>, double).unwrap(), None);
}

// ── applyOptionOrDefault ──────────────────────────────────────────────────────

#[test]
fn test_apply_option_or_default_some() {
    let double: Arc<dyn Fn(i32) -> Result<i32>> = Arc::new(|x| Ok(x * 2));
    assert_eq!(U::applyOptionOrDefault(Some(5i32), double, -1).unwrap(), 10);
}

#[test]
fn test_apply_option_or_default_none() {
    let double: Arc<dyn Fn(i32) -> Result<i32>> = Arc::new(|x| Ok(x * 2));
    assert_eq!(U::applyOptionOrDefault(None::<i32>, double, -1i32).unwrap(), -1);
}

// ── stringNotEqual ────────────────────────────────────────────────────────────

#[test]
fn test_string_not_equal_same() {
    assert!(!U::stringNotEqual(literal!("hello"), literal!("hello")));
}

#[test]
fn test_string_not_equal_different() {
    assert!(U::stringNotEqual(literal!("hello"), literal!("world")));
}

// ── stringPadLeft / stringPadRight ────────────────────────────────────────────

#[test]
fn test_string_pad_left_basic() {
    let result = U::stringPadLeft(literal!("hi"), 5, literal!(" "));
    assert_eq!(result, literal!("   hi"), "pad 'hi' to width 5 on the left");
}

#[test]
fn test_string_pad_left_no_pad_needed() {
    let result = U::stringPadLeft(literal!("hello"), 3, literal!(" "));
    assert_eq!(result, literal!("hello"), "no padding when string >= width");
}

#[test]
fn test_string_pad_right_basic() {
    let result = U::stringPadRight(literal!("hi"), 5, literal!(" "));
    assert_eq!(result, literal!("hi   "), "pad 'hi' to width 5 on the right");
}

#[test]
fn test_string_pad_right_no_pad_needed() {
    let result = U::stringPadRight(literal!("hello"), 3, literal!(" "));
    assert_eq!(result, literal!("hello"), "no padding when string >= width");
}

// ── selectFirstNonEmptyString ─────────────────────────────────────────────────

#[test]
fn test_select_first_non_empty_string_basic() {
    let lst = list![literal!(""), literal!(""), literal!("found"), literal!("other")];
    assert_eq!(U::selectFirstNonEmptyString(lst), literal!("found"));
}

#[test]
fn test_select_first_non_empty_string_first() {
    let lst = list![literal!("first"), literal!("second")];
    assert_eq!(U::selectFirstNonEmptyString(lst), literal!("first"));
}

#[test]
fn test_select_first_non_empty_string_all_empty() {
    let lst = list![literal!(""), literal!(""), literal!("")];
    assert_eq!(U::selectFirstNonEmptyString(lst), literal!(""));
}

#[test]
fn test_select_first_non_empty_nil() {
    assert_eq!(U::selectFirstNonEmptyString(nil()), literal!(""));
}

// ── flagValue ─────────────────────────────────────────────────────────────────

#[test]
fn test_flag_value_found() -> Result<()> {
    let args = list![
        literal!("-d"), literal!("debug"),
        literal!("-s"), literal!("output.mo")
    ];
    assert_eq!(U::flagValue(literal!("-s"), args)?, literal!("output.mo"));
    Ok(())
}

#[test]
fn test_flag_value_not_found() -> Result<()> {
    let args = list![literal!("-d"), literal!("debug")];
    assert_eq!(U::flagValue(literal!("-s"), args)?, literal!(""));
    Ok(())
}

#[test]
fn test_flag_value_flag_is_last() -> Result<()> {
    // Flag is present but there's no value after it
    let args = list![literal!("-d"), literal!("debug"), literal!("-s")];
    assert_eq!(U::flagValue(literal!("-s"), args)?, literal!(""));
    Ok(())
}

// ── intProduct ────────────────────────────────────────────────────────────────

#[test]
fn test_int_product_basic() {
    let lst = list![2i32, 3i32, 4i32];
    assert_eq!(U::intProduct(lst).unwrap(), 24);
}

#[test]
fn test_int_product_empty() {
    // fold over empty list with identity 1
    assert_eq!(U::intProduct(nil()).unwrap(), 1);
}

#[test]
fn test_int_product_single() {
    assert_eq!(U::intProduct(list![7i32]).unwrap(), 7);
}

// ── mulListIntegerOpt ─────────────────────────────────────────────────────────

#[test]
fn test_mul_list_integer_opt_all_some() -> Result<()> {
    let lst = list![Some(2i32), Some(3i32), Some(4i32)];
    assert_eq!(U::mulListIntegerOpt(lst, 1)?, 24);
    Ok(())
}

#[test]
fn test_mul_list_integer_opt_with_none() -> Result<()> {
    // None values are skipped (don't multiply by zero)
    let lst = list![Some(2i32), None, Some(3i32)];
    assert_eq!(U::mulListIntegerOpt(lst, 1)?, 6);
    Ok(())
}

#[test]
fn test_mul_list_integer_opt_empty() -> Result<()> {
    let lst: Arc<metamodelica::List<Option<i32>>> = nil();
    assert_eq!(U::mulListIntegerOpt(lst, 1)?, 1);
    Ok(())
}

// ── assoc ─────────────────────────────────────────────────────────────────────

#[test]
fn test_assoc_found() -> Result<()> {
    let pairs = list![
        (literal!("a"), 1i32),
        (literal!("b"), 2i32),
        (literal!("c"), 3i32)
    ];
    assert_eq!(U::assoc(literal!("b"), pairs)?, 2);
    Ok(())
}

#[test]
fn test_assoc_first() -> Result<()> {
    let pairs = list![(literal!("a"), 1i32), (literal!("b"), 2i32)];
    assert_eq!(U::assoc(literal!("a"), pairs)?, 1);
    Ok(())
}

#[test]
fn test_assoc_not_found_errors() {
    let pairs = list![(literal!("a"), 1i32)];
    assert!(U::assoc(literal!("z"), pairs).is_err(), "assoc should error when key not found");
}

// ── replace ───────────────────────────────────────────────────────────────────

#[test]
fn test_replace_returns_arg() {
    // replace(replaced, arg) always returns arg
    assert_eq!(U::replace(99i32, 42i32), 42);
    assert_eq!(U::replace(literal!("old"), literal!("new")), literal!("new"));
}

// ── anyReturnTrue / anyToEmptyString ─────────────────────────────────────────

#[test]
fn test_any_return_true() {
    assert!(U::anyReturnTrue(42i32));
    assert!(U::anyReturnTrue(literal!("hello")));
    assert!(U::anyReturnTrue(false));
}

#[test]
fn test_any_to_empty_string() {
    assert_eq!(U::anyToEmptyString(42i32), literal!(""));
    assert_eq!(U::anyToEmptyString(true), literal!(""));
}

// ── makeTuple / makeTupleR ────────────────────────────────────────────────────

#[test]
fn test_make_tuple() {
    assert_eq!(U::makeTuple(1i32, literal!("hello")), (1, literal!("hello")));
}

#[test]
fn test_make_tuple_r() {
    // makeTupleR(a, b) = (b, a)
    assert_eq!(U::makeTupleR(1i32, 2i32), (2, 1));
}

// ── intLstString ─────────────────────────────────────────────────────────────

#[test]
fn test_int_lst_string_basic() {
    let lst = list![1i32, 2i32, 3i32];
    assert_eq!(U::intLstString(lst).unwrap(), literal!("1, 2, 3"));
}

#[test]
fn test_int_lst_string_single() {
    let lst = list![42i32];
    assert_eq!(U::intLstString(lst).unwrap(), literal!("42"));
}

#[test]
fn test_int_lst_string_empty() {
    let lst: Arc<metamodelica::List<i32>> = nil();
    assert_eq!(U::intLstString(lst).unwrap(), literal!(""));
}

// ── stringContainsChar ────────────────────────────────────────────────────────

#[test]
fn test_string_contains_char_found() -> Result<()> {
    assert!(U::stringContainsChar(literal!("hello"), literal!("l"))?); // 'l' is not the last char
    assert!(U::stringContainsChar(literal!("hello"), literal!("h"))?); // 'h' produces ["","ello"]
    Ok(())
}

#[test]
fn test_string_contains_char_at_end_is_buggy() -> Result<()> {
    // BUG: stringContainsChar returns false when the character appears ONLY at the end.
    // Cause: stringSplitAtChar does not produce a trailing empty string when the
    // delimiter is the last char. So stringSplitAtChar("hello", "o") = ["hell"] (1 element).
    // The pattern match requires >=2 elements (_::_::_), so returns false.
    // Expected: true ("o" IS in "hello"). Actual (buggy): false.
    assert!(U::stringContainsChar(literal!("hello"), literal!("o"))?,
        "BUG: 'o' is in 'hello' but stringContainsChar returns false when char is last");
    Ok(())
}

#[test]
fn test_string_contains_char_not_found() -> Result<()> {
    assert!(!U::stringContainsChar(literal!("hello"), literal!("x"))?);
    assert!(!U::stringContainsChar(literal!("hello"), literal!("z"))?);
    Ok(())
}

#[test]
fn test_string_contains_char_dot() -> Result<()> {
    assert!(U::stringContainsChar(literal!("file.mo"), literal!("."))?);
    assert!(!U::stringContainsChar(literal!("file_mo"), literal!("."))?);
    Ok(())
}

// ── stringSplitAtChar ─────────────────────────────────────────────────────────

fn list_to_vec(lst: Arc<metamodelica::List<ArcStr>>) -> Vec<String> {
    let mut v = vec![];
    for s in &*lst { v.push(s.to_string()); }
    v
}

#[test]
fn test_string_split_at_char_basic() -> Result<()> {
    let parts = U::stringSplitAtChar(literal!("a,b,c"), literal!(","))?;
    assert_eq!(list_to_vec(parts), vec!["a", "b", "c"]);
    Ok(())
}

#[test]
fn test_string_split_at_char_no_delimiter() -> Result<()> {
    let parts = U::stringSplitAtChar(literal!("hello"), literal!(","))?;
    assert_eq!(list_to_vec(parts), vec!["hello"]);
    Ok(())
}

#[test]
fn test_string_split_at_char_delimiter_at_ends() -> Result<()> {
    // MetaModelica's stringSplitAtChar does NOT produce a trailing empty string
    // when the delimiter is the last character (unlike Python's str.split).
    // ",a," split at "," → ["", "a"] (no trailing "").
    // Leading delimiter DOES produce a leading empty string.
    let parts = U::stringSplitAtChar(literal!(",a,"), literal!(","))?;
    assert_eq!(list_to_vec(parts), vec!["", "a"]);
    Ok(())
}
