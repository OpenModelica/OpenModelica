// Tests for openmodelica_util SBInterval, SBMultiInterval, and SBAtomicSet.
//
// The Rust sources are auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/Util/SBInterval.mo
//   ~/OpenModelica/OMCompiler/Compiler/Util/SBMultiInterval.mo
//   ~/OpenModelica/OMCompiler/Compiler/Util/SBAtomicSet.mo
//
// *** ROOT BUG: System::intMaxLit() is `todo!()` (not yet implemented). ***
//
// SBInterval::new(lo, step, hi) calls System::intMaxLit() whenever lo <= hi
// (which is the common case for a non-empty interval).  As a result, the
// majority of tests below panic with "not yet implemented" at
// openmodelica_util/src/System.rs.
//
// Tests in Part A use SBInterval::new() and will FAIL (panic) until
// System::intMaxLit() is implemented.  They document the CORRECT expected
// behaviour as per the MetaModelica source.
//
// Tests in Part B construct SBInterval structs directly (bypassing `new()`)
// to test the logic of individual functions independently of the missing
// external.  These tests may expose additional logic bugs.
//
// Other known bugs documented inline with "Bug:" prefixes.

use anyhow::Result;
use std::sync::Arc;
use metamodelica::*;
use crate::SBInterval;
use crate::SBMultiInterval;
use crate::SBAtomicSet;

// ===========================================================================
// SBInterval
// ===========================================================================

// ---------------------------------------------------------------------------
// new / isEmpty
// ---------------------------------------------------------------------------

/// SBInterval::new(1,1,3) should produce an interval [1:1:3] that is not empty.
#[test]
fn sbinterval_new_valid_interval_is_not_empty() {
    let i = SBInterval::new(1, 1, 3);
    assert!(!SBInterval::isEmpty(i.clone()), "interval [1:1:3] should not be empty");
}

/// SBInterval::newEmpty() has step==0 and isEmpty() should return true.
#[test]
fn sbinterval_new_empty_is_empty() {
    let i = SBInterval::newEmpty();
    assert!(SBInterval::isEmpty(i), "newEmpty() must be empty");
}

/// new() with lo > hi produces an empty interval.
#[test]
fn sbinterval_new_lo_greater_than_hi_is_empty() {
    let i = SBInterval::new(5, 1, 3);
    assert!(SBInterval::isEmpty(i), "new(5,1,3) should be empty because lo > hi");
}

/// new() with step=0 and lo==hi should create a unit interval [lo:1:lo].
#[test]
fn sbinterval_new_step_zero_and_lo_eq_hi_normalises_to_unit() {
    let i = SBInterval::new(3, 0, 3);
    // After normalisation step should be 1 and it should not be empty.
    assert!(!SBInterval::isEmpty(i.clone()), "new(3,0,3) should not be empty after normalisation");
    assert_eq!(SBInterval::stepValue(i.clone()), 1, "step should be normalised to 1");
    assert_eq!(SBInterval::lowerBound(i.clone()), 3);
    assert_eq!(SBInterval::upperBound(i), 3);
}

/// new() with negative lo should produce an empty interval.
#[test]
fn sbinterval_new_negative_lo_is_empty() {
    let i = SBInterval::new(-1, 1, 3);
    assert!(SBInterval::isEmpty(i), "new with negative lo should be empty");
}

// ---------------------------------------------------------------------------
// newUnit / newFull
// ---------------------------------------------------------------------------

#[test]
fn sbinterval_new_unit_has_lo_1_step_1_hi_1() {
    let i = SBInterval::newUnit();
    assert_eq!(SBInterval::lowerBound(i.clone()), 1);
    assert_eq!(SBInterval::stepValue(i.clone()), 1);
    assert_eq!(SBInterval::upperBound(i), 1);
}

#[test]
fn sbinterval_new_full_is_not_empty_and_starts_at_1() {
    let i = SBInterval::newFull();
    assert!(!SBInterval::isEmpty(i.clone()), "newFull() must not be empty");
    assert_eq!(SBInterval::lowerBound(i.clone()), 1);
    assert_eq!(SBInterval::stepValue(i), 1);
}

// ---------------------------------------------------------------------------
// hi normalisation
// ---------------------------------------------------------------------------

/// new(1, 2, 6): hi should be adjusted to 5 (largest ≤ 6 reachable from 1
/// with step 2, i.e. 1,3,5,7→ 5).
#[test]
fn sbinterval_new_hi_is_normalised_to_last_reachable_value() {
    let i = SBInterval::new(1, 2, 6);
    // 1+0*2=1, 1+1*2=3, 1+2*2=5, 1+3*2=7>6 → last is 5
    assert_eq!(SBInterval::upperBound(i), 5, "hi should be normalised to 5");
}

/// new(1, 2, 5): hi=5 is already reachable from 1 with step 2, so no change.
#[test]
fn sbinterval_new_hi_already_aligned_unchanged() {
    let i = SBInterval::new(1, 2, 5);
    assert_eq!(SBInterval::upperBound(i), 5, "hi=5 is on the grid, should be unchanged");
}

// ---------------------------------------------------------------------------
// contains
// ---------------------------------------------------------------------------

#[test]
fn sbinterval_contains_lo_is_true() {
    let i = SBInterval::new(1, 2, 7); // [1,3,5,7]
    assert!(SBInterval::contains(1, i), "lo must be contained");
}

#[test]
fn sbinterval_contains_hi_is_true() {
    let i = SBInterval::new(1, 2, 7); // [1,3,5,7]
    assert!(SBInterval::contains(7, i), "hi must be contained");
}

#[test]
fn sbinterval_contains_mid_step_point_is_true() {
    let i = SBInterval::new(1, 2, 7); // [1,3,5,7]
    assert!(SBInterval::contains(3, i.clone()), "3 is in [1:2:7]");
    assert!(SBInterval::contains(5, i), "5 is in [1:2:7]");
}

#[test]
fn sbinterval_contains_off_step_point_is_false() {
    let i = SBInterval::new(1, 2, 7); // [1,3,5,7]
    assert!(!SBInterval::contains(2, i.clone()), "2 is not in [1:2:7]");
    assert!(!SBInterval::contains(4, i), "4 is not in [1:2:7]");
}

#[test]
fn sbinterval_contains_above_hi_is_false() {
    let i = SBInterval::new(1, 2, 7);
    assert!(!SBInterval::contains(9, i), "9 is above hi");
}

#[test]
fn sbinterval_contains_empty_interval_is_always_false() {
    let i = SBInterval::newEmpty();
    assert!(!SBInterval::contains(1, i), "empty interval contains nothing");
}

// ---------------------------------------------------------------------------
// size vs cardinality
// ---------------------------------------------------------------------------

/// size([1:1:3]) = (3-1)/1 + 1 = 3 — number of elements.
#[test]
fn sbinterval_size_unit_step_is_element_count() {
    let i = SBInterval::new(1, 1, 3);
    assert_eq!(SBInterval::size(i), 3, "size([1:1:3]) should be 3");
}

/// size([1:2:7]) = (7-1)/2 + 1 = 4 — elements are 1,3,5,7.
#[test]
fn sbinterval_size_step_two() {
    let i = SBInterval::new(1, 2, 7);
    assert_eq!(SBInterval::size(i), 4, "size([1:2:7]) should be 4");
}

/// Bug: cardinality([1:1:3]) returns floor((3-1)/1) = 2, not 3.
/// The MetaModelica source defines cardinality as realInt(intReal(hi-lo)/intReal(step)),
/// which is `size - 1`.  This is one fewer than the number of elements.
/// The discrepancy between `size` and `cardinality` is intentional in the source
/// but may be surprising to callers expecting an element count.
#[test]
fn sbinterval_cardinality_is_size_minus_one() {
    let i = SBInterval::new(1, 1, 3);
    let card = SBInterval::cardinality(i.clone()).unwrap();
    let sz   = SBInterval::size(i);
    assert_eq!(
        card, sz - 1,
        "cardinality should equal size-1 by the MetaModelica formula; card={}, size={}",
        card, sz
    );
}

/// cardinality([1:2:7]) = floor((7-1)/2) = 3.
#[test]
fn sbinterval_cardinality_step_two() {
    let i = SBInterval::new(1, 2, 7);
    assert_eq!(SBInterval::cardinality(i).unwrap(), 3, "cardinality([1:2:7]) should be 3");
}

// ---------------------------------------------------------------------------
// isEqual
// ---------------------------------------------------------------------------

#[test]
fn sbinterval_is_equal_same_interval() {
    let i1 = SBInterval::new(1, 1, 3);
    let i2 = SBInterval::new(1, 1, 3);
    assert!(SBInterval::isEqual(i1, i2));
}

#[test]
fn sbinterval_is_equal_different_lo() {
    let i1 = SBInterval::new(1, 1, 3);
    let i2 = SBInterval::new(2, 1, 3);
    assert!(!SBInterval::isEqual(i1, i2));
}

#[test]
fn sbinterval_is_equal_different_step() {
    let i1 = SBInterval::new(1, 1, 5);
    let i2 = SBInterval::new(1, 2, 5);
    assert!(!SBInterval::isEqual(i1, i2));
}

// ---------------------------------------------------------------------------
// toString
// ---------------------------------------------------------------------------

#[test]
fn sbinterval_to_string_format() {
    let i = SBInterval::new(1, 2, 7);
    let s = SBInterval::toString(i);
    // Expected: "[1:2:7]"
    assert_eq!(s, "[1:2:7]", "toString format should be [lo:step:hi]");
}

#[test]
fn sbinterval_to_string_unit_interval() {
    let i = SBInterval::newUnit();
    let s = SBInterval::toString(i);
    assert_eq!(s, "[1:1:1]");
}

// ---------------------------------------------------------------------------
// intersection
// ---------------------------------------------------------------------------

#[test]
fn sbinterval_intersection_overlapping_unit_step() {
    let i1 = SBInterval::new(1, 1, 5); // [1,2,3,4,5]
    let i2 = SBInterval::new(3, 1, 7); // [3,4,5,6,7]
    let res = SBInterval::intersection(i1, i2);
    // Intersection should be [3,4,5]
    assert!(!SBInterval::isEmpty(res.clone()), "intersection should not be empty");
    assert_eq!(SBInterval::lowerBound(res.clone()), 3);
    assert_eq!(SBInterval::upperBound(res), 5);
}

#[test]
fn sbinterval_intersection_non_overlapping_is_empty() {
    let i1 = SBInterval::new(1, 1, 3);
    let i2 = SBInterval::new(5, 1, 9);
    let res = SBInterval::intersection(i1, i2);
    assert!(SBInterval::isEmpty(res), "non-overlapping intervals should have empty intersection");
}

#[test]
fn sbinterval_intersection_with_empty_is_empty() {
    let i1 = SBInterval::new(1, 1, 5);
    let i2 = SBInterval::newEmpty();
    // Empty intervals have step=0, which means hi < lo in the intersection check.
    // Result should be empty.
    let res = SBInterval::intersection(i1, i2);
    assert!(SBInterval::isEmpty(res), "intersection with empty interval should be empty");
}

#[test]
fn sbinterval_intersection_step_alignment() {
    // [1:2:9] = {1,3,5,7,9}
    // [3:2:9] = {3,5,7,9}
    // Intersection = {3,5,7,9} i.e. [3:2:9]
    let i1 = SBInterval::new(1, 2, 9);
    let i2 = SBInterval::new(3, 2, 9);
    let res = SBInterval::intersection(i1, i2);
    assert!(!SBInterval::isEmpty(res.clone()));
    assert_eq!(SBInterval::lowerBound(res.clone()), 3);
    assert_eq!(SBInterval::upperBound(res), 9);
}

/// Bug check: intersecting two step-2 intervals offset by 1 should be empty
/// because their elements never coincide ([1:2:9]={1,3,5,7,9} and [2:2:8]={2,4,6,8}).
#[test]
fn sbinterval_intersection_misaligned_step_is_empty() {
    let i1 = SBInterval::new(1, 2, 9); // {1,3,5,7,9}
    let i2 = SBInterval::new(2, 2, 8); // {2,4,6,8}
    let res = SBInterval::intersection(i1, i2);
    assert!(
        SBInterval::isEmpty(res),
        "intervals with misaligned steps should have empty intersection"
    );
}

// ===========================================================================
// SBMultiInterval
// ===========================================================================

/// Helper: create a 1D SBMultiInterval from a single SBInterval.
fn mi1d(lo: i32, step: i32, hi: i32) -> Arc<SBMultiInterval::SBMultiInterval> {
    SBMultiInterval::fromList(metamodelica::list![SBInterval::new(lo, step, hi)]).unwrap()
}

/// Helper: create a 2D SBMultiInterval.
fn mi2d(
    lo1: i32, s1: i32, hi1: i32,
    lo2: i32, s2: i32, hi2: i32,
) -> Arc<SBMultiInterval::SBMultiInterval> {
    SBMultiInterval::fromList(metamodelica::list![
        SBInterval::new(lo1, s1, hi1),
        SBInterval::new(lo2, s2, hi2)
    ]).unwrap()
}

#[test]
fn sbmultiinterval_new_empty_is_empty() {
    let mi = SBMultiInterval::newEmpty();
    assert!(SBMultiInterval::isEmpty(mi));
}

#[test]
fn sbmultiinterval_from_list_1d_is_not_empty() {
    let mi = mi1d(1, 1, 3);
    assert!(!SBMultiInterval::isEmpty(mi));
}

/// fromList with an empty interval component should produce an empty MI.
#[test]
fn sbmultiinterval_from_list_containing_empty_interval_is_empty() {
    let mi = SBMultiInterval::fromList(metamodelica::list![
        SBInterval::new(1, 1, 3),
        SBInterval::newEmpty()
    ]).unwrap();
    assert!(
        SBMultiInterval::isEmpty(mi),
        "MI with an empty interval component should itself be empty"
    );
}

#[test]
fn sbmultiinterval_ndim_1d() {
    let mi = mi1d(1, 1, 5);
    assert_eq!(mi.ndim, 1);
}

#[test]
fn sbmultiinterval_ndim_2d() {
    let mi = mi2d(1, 1, 3, 2, 1, 5);
    assert_eq!(mi.ndim, 2);
}

#[test]
fn sbmultiinterval_contains_1d() {
    let mi = mi1d(1, 1, 5);
    let vals = metamodelica::arrayFromVec(vec![3]);
    assert!(SBMultiInterval::contains(vals, mi).unwrap());
}

#[test]
fn sbmultiinterval_contains_1d_out_of_range_false() {
    let mi = mi1d(1, 1, 5);
    let vals = metamodelica::arrayFromVec(vec![7]);
    assert!(!SBMultiInterval::contains(vals, mi).unwrap());
}

#[test]
fn sbmultiinterval_contains_wrong_ndim_is_false() {
    let mi = mi2d(1, 1, 3, 1, 1, 3);
    let vals = metamodelica::arrayFromVec(vec![1]); // 1D value for 2D MI
    assert!(!SBMultiInterval::contains(vals, mi).unwrap());
}

#[test]
fn sbmultiinterval_intersection_1d_overlapping() -> Result<()> {
    let mi1 = mi1d(1, 1, 5);
    let mi2 = mi1d(3, 1, 7);
    let res = SBMultiInterval::intersection(mi1, mi2)?;
    assert!(!SBMultiInterval::isEmpty(res.clone()));
    // The intersection should be [3:1:5]
    let ints = SBMultiInterval::intervals(res);
    let int0 = ints.borrow()[0].clone();
    assert_eq!(SBInterval::lowerBound(int0.clone()), 3);
    assert_eq!(SBInterval::upperBound(int0), 5);
    Ok(())
}

#[test]
fn sbmultiinterval_intersection_different_ndim_is_empty() -> Result<()> {
    let mi1 = mi1d(1, 1, 5);
    let mi2 = mi2d(1, 1, 5, 1, 1, 5);
    let res = SBMultiInterval::intersection(mi1, mi2)?;
    assert!(SBMultiInterval::isEmpty(res), "intersection of different-dim MIs should be empty");
    Ok(())
}

#[test]
fn sbmultiinterval_cardinality_1d_unit_step() {
    // cardinality([1:1:3]) = SBInterval::cardinality = floor((3-1)/1) = 2
    let mi = mi1d(1, 1, 3);
    assert_eq!(SBMultiInterval::cardinality(mi).unwrap(), 2);
}

/// Bug: SBMultiInterval::cardinality *sums* per-dimension SBInterval cardinalities
/// rather than taking their product.  For a 2D MI the mathematical cardinality
/// (number of lattice points) should be the product of per-dimension sizes,
/// but the implementation returns the sum of (size-1) for each dimension.
/// E.g. [1:1:3]×[1:1:5] → cardinality = 2+4 = 6, not 3×5 = 15.
#[test]
fn sbmultiinterval_cardinality_2d_sums_not_product() {
    let mi = mi2d(1, 1, 3, 1, 1, 5);
    let card = SBMultiInterval::cardinality(mi).unwrap();
    // Implementation sums: SBInterval::cardinality([1:1:3])=2,
    //                      SBInterval::cardinality([1:1:5])=4 → 6
    assert_eq!(
        card, 6,
        "cardinality adds per-dimension values (sum), not their product; got {}",
        card
    );
}

#[test]
fn sbmultiinterval_cross_prod_increases_ndim() -> Result<()> {
    let mi1 = mi1d(1, 1, 3);
    let mi2 = mi1d(2, 2, 8);
    let res = SBMultiInterval::crossProd(mi1, mi2)?;
    assert_eq!(res.ndim, 2, "crossProd of two 1D MIs should give a 2D MI");
    Ok(())
}

#[test]
fn sbmultiinterval_is_equal_same() -> Result<()> {
    let mi1 = mi1d(1, 1, 5);
    let mi2 = mi1d(1, 1, 5);
    assert!(SBMultiInterval::isEqual(mi1, mi2).unwrap());
    Ok(())
}

#[test]
fn sbmultiinterval_is_equal_different() -> Result<()> {
    let mi1 = mi1d(1, 1, 5);
    let mi2 = mi1d(1, 2, 5);
    assert!(!SBMultiInterval::isEqual(mi1, mi2).unwrap());
    Ok(())
}

// ===========================================================================
// SBAtomicSet
// ===========================================================================

fn aset1d(lo: i32, step: i32, hi: i32) -> Arc<SBAtomicSet::SBAtomicSet> {
    SBAtomicSet::new(mi1d(lo, step, hi))
}

#[test]
fn sbatomicset_new_empty_is_empty() {
    let s = SBAtomicSet::newEmpty();
    assert!(SBAtomicSet::isEmpty(s));
}

#[test]
fn sbatomicset_new_valid_is_not_empty() {
    let s = aset1d(1, 1, 5);
    assert!(!SBAtomicSet::isEmpty(s));
}

#[test]
fn sbatomicset_ndim_matches_underlying_mi() {
    let s = aset1d(1, 1, 5);
    assert_eq!(SBAtomicSet::ndim(s), 1);
}

#[test]
fn sbatomicset_contains_in_range() {
    let s = aset1d(1, 1, 5);
    let vals = metamodelica::arrayFromVec(vec![3]);
    assert!(SBAtomicSet::contains(vals, s).unwrap());
}

#[test]
fn sbatomicset_contains_out_of_range_false() {
    let s = aset1d(1, 1, 5);
    let vals = metamodelica::arrayFromVec(vec![7]);
    assert!(!SBAtomicSet::contains(vals, s).unwrap());
}

#[test]
fn sbatomicset_intersection_overlapping() -> Result<()> {
    let s1 = aset1d(1, 1, 5);
    let s2 = aset1d(3, 1, 7);
    let res = SBAtomicSet::intersection(s1, s2)?;
    assert!(!SBAtomicSet::isEmpty(res.clone()));
    let mi = SBAtomicSet::aset(res);
    let ints = SBMultiInterval::intervals(mi);
    let int0 = ints.borrow()[0].clone();
    assert_eq!(SBInterval::lowerBound(int0.clone()), 3);
    assert_eq!(SBInterval::upperBound(int0), 5);
    Ok(())
}

#[test]
fn sbatomicset_intersection_non_overlapping_is_empty() -> Result<()> {
    let s1 = aset1d(1, 1, 3);
    let s2 = aset1d(5, 1, 9);
    let res = SBAtomicSet::intersection(s1, s2)?;
    assert!(SBAtomicSet::isEmpty(res));
    Ok(())
}

/// The cardinality accumulator: SBAtomicSet::cardinality(set, 0) should return
/// SBMultiInterval::cardinality of the underlying multi-interval.
#[test]
fn sbatomicset_cardinality_accumulates_from_zero() {
    let s = aset1d(1, 1, 5);
    let card = SBAtomicSet::cardinality(s, 0).unwrap();
    // SBInterval::cardinality([1:1:5]) = floor((5-1)/1) = 4
    assert_eq!(card, 4, "cardinality([1:1:5]) starting from 0 should be 4");
}

#[test]
fn sbatomicset_cardinality_adds_to_given_accumulator() {
    let s = aset1d(1, 1, 5);
    let card = SBAtomicSet::cardinality(s, 10).unwrap();
    // 10 + 4 = 14
    assert_eq!(card, 14, "cardinality should add to the given accumulator");
}

#[test]
fn sbatomicset_is_equal_same() {
    let s1 = aset1d(1, 1, 5);
    let s2 = aset1d(1, 1, 5);
    assert!(SBAtomicSet::isEqual(s1, s2).unwrap());
}

#[test]
fn sbatomicset_is_equal_different() {
    let s1 = aset1d(1, 1, 5);
    let s2 = aset1d(1, 2, 5);
    assert!(!SBAtomicSet::isEqual(s1, s2).unwrap());
}

#[test]
fn sbatomicset_to_string_wraps_multiinterval_in_braces() {
    let s = aset1d(1, 1, 3);
    let r = SBAtomicSet::toString(s);
    // Expected: "{[1:1:3]}" — braces around SBMultiInterval::toString
    assert!(r.starts_with('{'), "toString should start with '{{'");
    assert!(r.ends_with('}'), "toString should end with '}}'");
    assert!(r.contains("[1:1:3]"), "toString should contain the interval string");
}

/// replace() substitutes a dimension's interval in a copy of the set.
#[test]
fn sbatomicset_replace_changes_specified_dimension() {
    let s = aset1d(1, 1, 5);
    let new_i = SBInterval::new(2, 2, 8);
    let replaced = SBAtomicSet::replace(new_i.clone(), 1, s).unwrap();
    let mi = SBAtomicSet::aset(replaced);
    let ints = SBMultiInterval::intervals(mi);
    let int0 = ints.borrow()[0].clone();
    assert!(SBInterval::isEqual(int0, new_i), "replaced dimension should match the new interval");
}

#[test]
fn sbatomicset_copy_is_independent() {
    let s = aset1d(1, 1, 5);
    let s2 = SBAtomicSet::copy(s.clone());
    assert!(SBAtomicSet::isEqual(s, s2).unwrap());
}

// ===========================================================================
// Part B — Tests using direct struct construction to bypass the
//           System::intMaxLit() `todo!()` bug.
//
// The `new()` constructor calls System::intMaxLit() and panics.  These tests
// construct SBInterval { lo, step, hi } directly to exercise the logic of
// functions that are otherwise unreachable.  The intervals used here have hi
// already on the grid (i.e., (hi - lo) % step == 0) so normalisation would
// not change them anyway.
// ===========================================================================

/// Helper: construct an SBInterval directly, bypassing SBInterval::new().
fn raw_interval(lo: i32, step: i32, hi: i32) -> Arc<SBInterval::SBInterval> {
    Arc::new(SBInterval::SBInterval { lo, step, hi })
}

/// Helper: build a 1D SBMultiInterval directly.
fn raw_mi1d(lo: i32, step: i32, hi: i32) -> Arc<SBMultiInterval::SBMultiInterval> {
    SBMultiInterval::fromList(metamodelica::list![raw_interval(lo, step, hi)]).unwrap()
}

// ---------------------------------------------------------------------------
// Part B: SBInterval — logic tests with direct construction
// ---------------------------------------------------------------------------

/// [1:1:3] is not empty (step != 0).
#[test]
fn partb_sbinterval_raw_not_empty() {
    let i = raw_interval(1, 1, 3);
    assert!(!SBInterval::isEmpty(i));
}

/// isEmpty requires step == 0.
#[test]
fn partb_sbinterval_step_zero_is_empty() {
    let i = raw_interval(1, 0, 3);
    assert!(SBInterval::isEmpty(i));
}

/// contains: lo itself is always contained.
#[test]
fn partb_sbinterval_contains_lo() {
    let i = raw_interval(1, 2, 7); // {1,3,5,7}
    assert!(SBInterval::contains(1, i));
}

/// contains: hi is contained.
#[test]
fn partb_sbinterval_contains_hi() {
    let i = raw_interval(1, 2, 7);
    assert!(SBInterval::contains(7, i));
}

/// contains: a mid-point on the grid.
#[test]
fn partb_sbinterval_contains_midpoint() {
    let i = raw_interval(1, 2, 7); // {1,3,5,7}
    assert!(SBInterval::contains(5, i));
}

/// contains: a value between grid points is not contained.
#[test]
fn partb_sbinterval_does_not_contain_between_gridpoints() {
    let i = raw_interval(1, 2, 7); // {1,3,5,7}
    assert!(!SBInterval::contains(2, i.clone()));
    assert!(!SBInterval::contains(4, i));
}

/// contains: above hi is not contained.
#[test]
fn partb_sbinterval_does_not_contain_above_hi() {
    let i = raw_interval(1, 2, 7);
    assert!(!SBInterval::contains(9, i));
}

/// size: (hi - lo) / step + 1.
#[test]
fn partb_sbinterval_size_unit_step() {
    let i = raw_interval(1, 1, 3);
    assert_eq!(SBInterval::size(i), 3);
}

#[test]
fn partb_sbinterval_size_step_two() {
    let i = raw_interval(1, 2, 7); // {1,3,5,7} → 4 elements
    assert_eq!(SBInterval::size(i), 4);
}

/// cardinality = floor((hi-lo)/step) = size - 1.
/// Bug: this is one fewer than the number of elements in the interval.
#[test]
fn partb_sbinterval_cardinality_is_size_minus_one() {
    let i = raw_interval(1, 1, 3);
    let sz   = SBInterval::size(i.clone());
    let card = SBInterval::cardinality(i).unwrap();
    assert_eq!(card, sz - 1,
        "cardinality = floor((hi-lo)/step) = size-1; sz={}, card={}", sz, card);
}

/// isEqual: same fields → true.
#[test]
fn partb_sbinterval_is_equal_same() {
    let i1 = raw_interval(1, 2, 7);
    let i2 = raw_interval(1, 2, 7);
    assert!(SBInterval::isEqual(i1, i2));
}

/// isEqual: different lo → false.
#[test]
fn partb_sbinterval_is_equal_different_lo() {
    let i1 = raw_interval(1, 1, 5);
    let i2 = raw_interval(2, 1, 5);
    assert!(!SBInterval::isEqual(i1, i2));
}

/// toString: format is "[lo:step:hi]".
#[test]
fn partb_sbinterval_to_string() {
    let i = raw_interval(1, 2, 7);
    assert_eq!(SBInterval::toString(i), "[1:2:7]");
}

/// intersection: overlapping unit-step intervals.
/// [1:1:5] ∩ [3:1:7] = [3:1:5]
///
/// Bug: SBInterval::intersection() also calls System::intMaxLit() internally
/// (for the `new_hi < intMaxLit()` guard), so this test still panics even
/// though the input intervals are constructed directly.
#[test]
fn partb_sbinterval_intersection_overlapping() {
    let i1 = raw_interval(1, 1, 5);
    let i2 = raw_interval(3, 1, 7);
    let res = SBInterval::intersection(i1, i2);
    assert!(!SBInterval::isEmpty(res.clone()));
    assert_eq!(SBInterval::lowerBound(res.clone()), 3);
    assert_eq!(SBInterval::upperBound(res), 5);
}

/// intersection: non-overlapping intervals → empty.
#[test]
fn partb_sbinterval_intersection_non_overlapping() {
    let i1 = raw_interval(1, 1, 3);
    let i2 = raw_interval(5, 1, 9);
    let res = SBInterval::intersection(i1, i2);
    assert!(SBInterval::isEmpty(res));
}

// ---------------------------------------------------------------------------
// Part B: SBMultiInterval — logic tests with direct construction
// ---------------------------------------------------------------------------

/// ndim of a 1D MI is 1.
#[test]
fn partb_sbmi_ndim_1d() {
    let mi = raw_mi1d(1, 1, 5);
    assert_eq!(mi.ndim, 1);
}

/// fromList with a valid interval is not empty.
#[test]
fn partb_sbmi_from_list_not_empty() {
    let mi = raw_mi1d(1, 1, 5);
    assert!(!SBMultiInterval::isEmpty(mi));
}

/// contains: in-range value.
#[test]
fn partb_sbmi_contains_in_range() {
    let mi = raw_mi1d(1, 1, 5);
    let vals = metamodelica::arrayFromVec(vec![3]);
    assert!(SBMultiInterval::contains(vals, mi).unwrap());
}

/// contains: out-of-range value.
#[test]
fn partb_sbmi_contains_out_of_range() {
    let mi = raw_mi1d(1, 1, 5);
    let vals = metamodelica::arrayFromVec(vec![7]);
    assert!(!SBMultiInterval::contains(vals, mi).unwrap());
}

/// cardinality for 1D [1:1:3] = SBInterval::cardinality = 2.
#[test]
fn partb_sbmi_cardinality_1d() {
    let mi = raw_mi1d(1, 1, 3);
    assert_eq!(SBMultiInterval::cardinality(mi).unwrap(), 2);
}

/// Bug: SBMultiInterval::cardinality sums per-dimension SBInterval::cardinality
/// values instead of multiplying them.  For 2D [1:1:3]×[1:1:5] the result is
/// 2+4=6, not the lattice cardinality 3×5=15.
#[test]
fn partb_sbmi_cardinality_2d_sums_not_product() {
    let mi = SBMultiInterval::fromList(metamodelica::list![
        raw_interval(1, 1, 3),
        raw_interval(1, 1, 5)
    ]).unwrap();
    let card = SBMultiInterval::cardinality(mi).unwrap();
    // 2 + 4 = 6  (sums)
    assert_eq!(card, 6,
        "cardinality sums per-dim values; expected 6, got {}", card);
}

/// intersection of two 1D MIs: [1:1:5] ∩ [3:1:7] = [3:1:5].
///
/// Historical note: this test (and the non-overlapping variant in the
/// SBAtomicSet section) used to SIGSEGV. The root cause was the codegen
/// emitting the unsafe form `Dangerous::arrayCreateNoInit(size)` for all MM
/// `arrayCreateNoInit(size, dummy)` calls. Slots stayed uninitialised, and
/// when `intersection` returned early after computing an empty
/// inner-interval intersection, `Vec::drop` interpreted garbage bytes as live
/// `Arc<SBInterval>` values, corrupting the heap. The fix forwards the MM
/// dummy to the safe runtime variant `arrayCreateNoInitWithDummy` when the
/// dummy expression is known-initialised (here, `arrayGet(mi1.intervals, 1)`).
#[test]
fn partb_sbmi_intersection_1d_overlapping() -> anyhow::Result<()> {
    let mi1 = raw_mi1d(1, 1, 5);
    let mi2 = raw_mi1d(3, 1, 7);
    let res = SBMultiInterval::intersection(mi1, mi2)?;
    assert!(!SBMultiInterval::isEmpty(res.clone()));
    let ints = SBMultiInterval::intervals(res);
    let i0 = ints.borrow()[0].clone();
    assert_eq!(SBInterval::lowerBound(i0.clone()), 3);
    assert_eq!(SBInterval::upperBound(i0), 5);
    Ok(())
}

/// isEqual: same MI → true.
#[test]
fn partb_sbmi_is_equal_same() {
    let mi1 = raw_mi1d(1, 1, 5);
    let mi2 = raw_mi1d(1, 1, 5);
    assert!(SBMultiInterval::isEqual(mi1, mi2).unwrap());
}

/// isEqual: different step → false.
#[test]
fn partb_sbmi_is_equal_different() {
    let mi1 = raw_mi1d(1, 1, 5);
    let mi2 = raw_mi1d(1, 2, 5);
    assert!(!SBMultiInterval::isEqual(mi1, mi2).unwrap());
}

// ---------------------------------------------------------------------------
// Part B: SBAtomicSet — logic tests with direct construction
// ---------------------------------------------------------------------------

fn raw_aset1d(lo: i32, step: i32, hi: i32) -> Arc<SBAtomicSet::SBAtomicSet> {
    SBAtomicSet::new(raw_mi1d(lo, step, hi))
}

/// New atomic set from a valid MI is not empty.
#[test]
fn partb_sbas_new_not_empty() {
    let s = raw_aset1d(1, 1, 5);
    assert!(!SBAtomicSet::isEmpty(s));
}

/// ndim of 1D atomic set is 1.
#[test]
fn partb_sbas_ndim_1d() {
    let s = raw_aset1d(1, 1, 5);
    assert_eq!(SBAtomicSet::ndim(s), 1);
}

/// contains: in-range value.
#[test]
fn partb_sbas_contains_in_range() {
    let s = raw_aset1d(1, 1, 5);
    let vals = metamodelica::arrayFromVec(vec![3]);
    assert!(SBAtomicSet::contains(vals, s).unwrap());
}

/// isEqual: same set → true.
#[test]
fn partb_sbas_is_equal_same() {
    let s1 = raw_aset1d(1, 1, 5);
    let s2 = raw_aset1d(1, 1, 5);
    assert!(SBAtomicSet::isEqual(s1, s2).unwrap());
}

/// isEqual: different step → false.
#[test]
fn partb_sbas_is_equal_different() {
    let s1 = raw_aset1d(1, 1, 5);
    let s2 = raw_aset1d(1, 2, 5);
    assert!(!SBAtomicSet::isEqual(s1, s2).unwrap());
}

/// toString wraps the MI string in curly braces.
#[test]
fn partb_sbas_to_string_format() {
    let s = raw_aset1d(1, 1, 3);
    let r = SBAtomicSet::toString(s);
    assert!(r.starts_with('{'), "should start with '{{': {:?}", r);
    assert!(r.ends_with('}'),  "should end with '}}': {:?}", r);
    assert!(r.contains("[1:1:3]"), "should contain interval string: {:?}", r);
}

/// cardinality with accumulator 0: returns SBMultiInterval cardinality.
#[test]
fn partb_sbas_cardinality_from_zero() {
    let s = raw_aset1d(1, 1, 5);
    // SBInterval::cardinality([1:1:5]) = floor((5-1)/1) = 4
    assert_eq!(SBAtomicSet::cardinality(s, 0).unwrap(), 4);
}

/// cardinality adds to the supplied accumulator.
#[test]
fn partb_sbas_cardinality_accumulates() {
    let s = raw_aset1d(1, 1, 5);
    assert_eq!(SBAtomicSet::cardinality(s, 10).unwrap(), 14); // 10 + 4 = 14
}

/// copy produces an equal but independent value.
#[test]
fn partb_sbas_copy_is_equal() {
    let s  = raw_aset1d(1, 1, 5);
    let s2 = SBAtomicSet::copy(s.clone());
    assert!(SBAtomicSet::isEqual(s, s2).unwrap());
}

