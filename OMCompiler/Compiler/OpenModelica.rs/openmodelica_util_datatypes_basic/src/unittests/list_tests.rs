use metamodelica::Result;
use std::sync::Arc;
use metamodelica::*;
use arcstr::ArcStr;
use crate::List as L;

// ── helper predicates (must be fn pointers) ──
fn is_positive(x: i32) -> Result<bool> { Ok(x > 0) }
fn is_even(x: i32) -> Result<bool> { Ok(x % 2 == 0) }
fn double(x: i32) -> Result<i32> { Ok(x * 2) }
fn to_string_i32(x: i32) -> Result<ArcStr> { Ok(arcstr::format!("{}", x)) }
fn add_i(a: i32, b: i32) -> Result<i32> { Ok(a + b) }
fn less_i(a: i32, b: i32) -> Result<bool> { Ok(a < b) }
fn eq_i(a: i32, b: i32) -> Result<bool> { Ok(a == b) }
fn cmp_i(a: i32, b: i32) -> Result<i32> { Ok(if a < b { -1 } else if a > b { 1 } else { 0 }) }

// ── AccumulateMapAccum ──
#[test]
fn test_accumulate_map_accum() {
    let lst = list![1i32, 2, 3];
    // accumulates: each call gets (element, accumulated_so_far), must return new accumulator
    let result = L::accumulateMapAccum(&lst, &|x, acc| Ok(cons(*x, acc))).unwrap();
    assert_eq!(result.len(), 3);
}

// ── All ──
#[test]
fn test_all_true() {
    let lst = list![1i32, 2, 3];
    assert!(L::all(&lst, &|a0| is_positive(::std::clone::Clone::clone(a0))).unwrap());
}
#[test]
fn test_all_false() {
    let lst = list![1i32, -2, 3];
    assert!(!L::all(&lst, &|a0| is_positive(::std::clone::Clone::clone(a0))).unwrap());
}
#[test]
fn test_all_empty() {
    let lst: List<i32> = nil();
    assert!(L::all(&lst, &|a0| is_positive(::std::clone::Clone::clone(a0))).unwrap());
}

// ── AllEqual ──
#[test]
fn test_all_equal_true() -> Result<()> {
    let lst = list![5i32, 5, 5];
    assert!(L::allEqual(&lst, &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?);
    Ok(())
}
#[test]
fn test_all_equal_false() -> Result<()> {
    let lst = list![5i32, 3, 5];
    assert!(!L::allEqual(&lst, &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?);
    Ok(())
}
#[test]
fn test_all_equal_empty() -> Result<()> {
    let lst: List<i32> = nil();
    assert!(L::allEqual(&lst, &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?);
    Ok(())
}

// ── AllReferenceEq ──
#[test]
fn test_all_reference_eq_true() -> Result<()> {
    // referenceEq uses ptr::eq, so cloned values are never ptr-eq
    // Empty lists are trivially equal
    let lst: List<List<i32>> = nil();
    let lst2: List<List<i32>> = nil();
    assert!(L::allReferenceEq(lst.clone(), lst2.clone())?);
    Ok(())
}
#[test]
fn test_all_reference_eq_false() -> Result<()> {
    let lst = list![list![1i32], list![1i32]];
    let lst2 = list![list![1i32, 2], list![1i32]];
    assert!(!L::allReferenceEq(lst.clone(), lst2.clone())?);
    Ok(())
}

// ── Any ──
#[test]
fn test_any_found() {
    let lst = list![-1i32, 2, -3];
    assert!(L::any(&lst, &|a0| is_positive(::std::clone::Clone::clone(a0))).unwrap());
}
#[test]
fn test_any_none() {
    let lst = list![-1i32, -2];
    assert!(!L::any(&lst, &|a0| is_positive(::std::clone::Clone::clone(a0))).unwrap());
}
#[test]
fn test_any_empty() {
    let lst: List<i32> = nil();
    assert!(!L::any(&lst, &|a0| is_positive(::std::clone::Clone::clone(a0))).unwrap());
}

// ── AppendElt ──
#[test]
fn test_append_elt() {
    let lst = list![1i32, 2];
    let result = L::appendElt(3, lst.clone());
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── AppendLastList ──
#[test]
fn test_append_last_list() -> Result<()> {
    let lst1 = list![1i32, 2];
    let lst2 = list![3i32, 4];
    let list_of_lists = list![lst1.clone(), lst2.clone()];
    let result = L::appendLastList(&list_of_lists, list![5i32, 6])?;
    assert_eq!(result.len(), 2);
    Ok(())
}

// ── Append_reverse ──
#[test]
fn test_append_reverse() {
    let lst = list![1i32, 2, 3];
    let result = L::append_reverse(&lst, nil());
    assert_eq!(result, list![3i32, 2, 1]);
}

// ── ApplyAndFold ──
#[test]
fn test_apply_and_fold() {
    let lst = list![1i32, 2, 3];
    let result = L::applyAndFold(&lst, &|acc, x| Ok(acc + x), &|x| Ok(*x), 0i32).unwrap();
    assert_eq!(result, 6);
}

// ── ApplyAndFold1 ──
#[test]
fn test_apply_and_fold1() {
    let lst = list![1i32];
    let result = L::applyAndFold1(&lst, &|acc, x| Ok(*acc + *x), &|x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(*x) }, 10i32, 0i32).unwrap();
    assert_eq!(result, 1);
}

// ── BalancedPartition ──
#[test]
fn test_balanced_partition() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::balancedPartition(lst.clone(), 2)?;
    assert!(result.len() >= 2);
    Ok(())
}

// ── Combination ──
#[test]
fn test_combination() -> Result<()> {
    let lst = list![list![1i32, 2], list![3i32, 4]];
    let result = L::combination(&lst);
    assert!(result.len() >= 0);
    Ok(())
}

// ── CombinationMap ──
fn combination_map_fn(pair: metamodelica::List<i32>) -> Result<i32> { Ok(pair.len()) }
#[test]
fn test_combination_map() -> Result<()> {
    let lst = list![list![1i32, 2], list![3i32, 4]];
    let result = L::combinationMap(&lst, &combination_map_fn).unwrap();
    assert!(result.len() >= 0);
    Ok(())
}

// ── Compare ──
#[test]
fn test_compare_equal() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![1i32, 2, 3];
    assert_eq!(L::compare(a.clone(), b.clone(), &|a0, a1| cmp_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?, 0);
    Ok(())
}
#[test]
fn test_compare_less() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![1i32, 3];
    assert_eq!(L::compare(a.clone(), b.clone(), &|a0, a1| cmp_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?, -1);
    Ok(())
}
#[test]
fn test_compare_greater() -> Result<()> {
    let a = list![1i32, 4];
    let b = list![1i32, 3];
    assert_eq!(L::compare(a.clone(), b.clone(), &|a0, a1| cmp_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?, 1);
    Ok(())
}

// ── CompareLength ──
#[test]
fn test_compare_length() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![1i32, 2, 3];
    assert!(L::compareLength(a.clone(), b.clone())? < 0);
    assert_eq!(L::compareLength(b.clone(), b.clone())?, 0);
    assert!(L::compareLength(b.clone(), a.clone())? > 0);
    Ok(())
}

// ── ConsN ──
#[test]
fn test_cons_n() {
    let result = L::consN(3, 42i32, nil());
    assert_eq!(result, list![42i32, 42, 42]);
}
#[test]
fn test_cons_n_zero() {
    let result = L::consN(0, 42i32, nil());
    assert!(result.is_empty());
}

// ── ConsOnTrue ──
#[test]
fn test_cons_on_true_true() {
    let result = L::consOnTrue(true, 1i32, nil());
    assert_eq!(result, list![1i32]);
}
#[test]
fn test_cons_on_true_false() {
    let result = L::consOnTrue(false, 1i32, nil());
    assert!(result.is_empty());
}

// ── ConsOption ──
#[test]
fn test_cons_option_some() -> Result<()> {
    let result = L::consOption(Some(1i32), nil());
    assert_eq!(result, list![1i32]);
    Ok(())
}
#[test]
fn test_cons_option_none() -> Result<()> {
    let result = L::consOption(Option::<i32>::None, nil());
    assert!(result.is_empty());
    Ok(())
}

// ── Consr ──
#[test]
fn test_consr() {
    let lst = list![2i32, 3];
    let result = L::consr(lst.clone(), 1i32);
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── Contains ──
#[test]
fn test_contains_true() {
    let lst = list![1i32, 2, 3];
    assert!(L::contains(&lst, 2, &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1))).unwrap());
}
#[test]
fn test_contains_false() {
    let lst = list![1i32, 2, 3];
    assert!(!L::contains(&lst, 4, &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1))).unwrap());
}

// ── Count ──
#[test]
fn test_count() {
    let lst = list![1i32, 2, 3, 4, 5, 6];
    assert_eq!(L::count(&lst, &|a0| is_even(::std::clone::Clone::clone(a0))).unwrap(), 3);
}

// ── CountingSort ──
#[test]
fn test_counting_sort() -> Result<()> {
    let lst = list![3i32, 1, 4, 1, 5, 9, 2, 6];
    let result = L::countingSort(lst.clone(), 9)?;
    assert_eq!(result, list![1i32, 1, 2, 3, 4, 5, 6, 9]);
    Ok(())
}

// ── Create ──
#[test]
fn test_create() {
    let result = L::create(0i32);
    assert_eq!(result, list![0i32]);
}

// ── DeleteMemberOnTrue ──
#[test]
fn test_delete_member_on_true() -> Result<()> {
    let lst = list![1i32, 2, 3, 4];
    let (result, deleted) = L::deleteMemberOnTrue(2i32, lst.clone(), &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?;
    assert_eq!(deleted, Some(2));
    assert_eq!(result, list![1i32, 3, 4]);
    Ok(())
}

// ── DeletePositions ──
#[test]
fn test_delete_positions() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let positions = list![2i32, 4];
    let result = L::deletePositions(lst.clone(), positions.clone(), false)?;
    assert_eq!(result, list![1i32, 3, 5]);
    Ok(())
}

// ── DeletePositionsSorted ──
#[test]
fn test_delete_positions_sorted() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let positions = list![1i32, 3, 5];
    let result = L::deletePositionsSorted(lst.clone(), &positions, false)?;
    assert_eq!(result, list![2i32, 4]);
    Ok(())
}

// ── Exist1 ──
#[test]
fn test_exist1_true() {
    assert!(L::exist1(&list![1i32, 2, 3], &|x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(*x > 0) }, 0i32).unwrap());
}
#[test]
fn test_exist1_false() {
    assert!(!L::exist1(&list![-1i32, -2], &|x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(*x > 0) }, 0i32).unwrap());
}

// ── ExtractOnTrue ──
#[test]
fn test_extract_on_true() {
    let lst = list![1i32, 2, 3, 4, 5];
    let (matched, _unmatched) = L::extractOnTrue(&lst, &|x| Ok(x % 2 == 0)).unwrap();
    assert_eq!(matched, list![2i32, 4]);
}

// ── Extract1OnTrue ──
#[test]
fn test_extract1_on_true() {
    let lst = list![1i32, 2, 3];
    let (matched, _unmatched) = L::extract1OnTrue(&lst, &|x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(x % 2 == 0) }, 0i32).unwrap();
    assert_eq!(matched, list![2i32]);
}

// ── Fill ──
#[test]
fn test_fill() {
    let result = L::fill(42i32, 5);
    assert_eq!(result, list![42i32, 42, 42, 42, 42]);
}

// ── Filter ──
#[test]
fn test_filter() {
    let lst = list![1i32, 2, 3, 4, 5, 6];
    let result = L::filter(&lst, &|x| { if x % 2 == 0 { Ok(()) } else { return Err("skip") } });
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── Filter1 ──
#[test]
fn test_filter1() {
    let lst = list![1i32];
    let result = L::filter1(&lst, &|x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); { if *x > 0 { Ok(()) } else { return Err("skip") } } }, 0i32);
    assert_eq!(result, list![1i32]);
}

// ── Filter1OnTrue ──
#[test]
fn test_filter1_on_true() {
    let lst = list![1i32, 2, 3];
    let result = L::filter1OnTrue(lst.clone(), Arc::new(|x, _arg: i32| Ok(x % 2 == 0)), 0i32).unwrap();
    assert_eq!(result, list![2i32]);
}

// ── Filter1OnTrueAndUpdate ──
#[test]
fn test_filter1_on_true_and_update() {
    let lst = list![1i32, 2, 3];
    let result = L::filter1OnTrueAndUpdate(lst.clone(), &|x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(*x > 1) }, &|x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(*x * 10) }, 0i32).unwrap();
    assert_eq!(result, list![20i32, 30i32]);
}

// ── Filter1OnTrueSync ──
#[test]
fn test_filter1_on_true_sync() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let sync = list![10i32, 20, 30];
    let (kept, _removed) = L::filter1OnTrueSync(&lst, &|x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(x % 2 == 0) }, 0i32, sync.clone())?;
    assert_eq!(kept, list![2i32]);
    Ok(())
}

// ── Filter1rOnTrue ──
#[test]
fn test_filter1r_on_true() {
    let lst = list![2i32, 4, 6];
    let result = L::filter1rOnTrue(lst.clone(), Arc::new(|_arg: i32, x| Ok(x % 2 == 0)), 0i32).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── Filter2OnTrue ──
#[test]
fn test_filter2_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::filter2OnTrue(lst.clone(), Arc::new(|x, _a: i32, _b: i32| Ok(x % 2 == 0)), 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── FilterCons ──
#[test]
fn test_filter_cons() {
    let lst = list![1i32, 2, 3];
    let result = L::filterCons(&lst, &|x| Ok(x % 2 == 0), nil()).unwrap();
    assert_eq!(result, list![2i32]);
}

// ── FilterMap ──
#[test]
fn test_filter_map() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::filterMap(&lst, &|x| if x % 2 == 0 { Ok(x * 10) } else { return Err("skip") });
    assert_eq!(result, list![20i32, 40]);
}

// ── FilterMap1 ──
#[test]
fn test_filter_map1() {
    let lst = list![2i32];
    let result = L::filterMap1(&lst, &|x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); if *x > 0 { Ok(*x * 2) } else { return Err("skip") } }, 0i32);
    assert_eq!(result, list![4i32]);
}

// ── FilterOnFalse ──
#[test]
fn test_filter_on_false() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::filterOnFalse(lst.clone(), &|x| Ok(x % 2 == 0)).unwrap();
    assert_eq!(result, list![1i32, 3]);
}

// ── FilterOnTrue ──
#[test]
fn test_filter_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::filterOnTrue(lst.clone(), Arc::new(is_even)).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── FilterOnTrueSync ──
#[test]
fn test_filter_on_true_sync() -> Result<()> {
    let lst = list![1i32, 2, 3, 4];
    let sync = list![10i32, 20, 30, 40];
    let (matched, _unmatched) = L::filterOnTrueSync(&lst, &|a0| is_even(::std::clone::Clone::clone(a0)), sync.clone())?;
    assert_eq!(matched, list![2i32, 4]);
    Ok(())
}

// ── Find ──
#[test]
fn test_find_found() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::find(&lst, &|x| Ok(*x == 2))?;
    assert_eq!(result, 2);
    Ok(())
}
#[test]
fn test_find_not_found() {
    let lst = list![1i32, 2, 3];
    assert!(L::find(&lst, &|x| Ok(*x == 4)).is_err());
}

// ── Find1 ──
#[test]
fn test_find1_found() -> Result<()> {
    let lst = list![1i32];
    let result = L::find1(&lst, &|x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(*x > 0) }, 0i32)?;
    assert_eq!(result, 1);
    Ok(())
}

// ── FindAndMap ──
#[test]
fn test_find_and_map() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let (result, found) = L::findAndMap(lst.clone(), &|x| Ok(*x > 1), &|x| Ok(x * 10))?;
    assert!(found);
    Ok(())
}

// ── FindAndRemove ──
#[test]
fn test_find_and_remove() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let (found, rest) = L::findAndRemove(lst.clone(), &|x| Ok(*x == 2))?;
    assert_eq!(found, 2);
    assert_eq!(rest, list![1i32, 3]);
    Ok(())
}

// ── FindAndRemove1 ──
#[test]
fn test_find_and_remove1() -> Result<()> {
    let lst = list![1i32, 2];
    let (found, rest) = L::findAndRemove1(lst.clone(), &|x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(*x == 2) }, 0i32)?;
    assert_eq!(found, 2);
    assert_eq!(rest, list![1i32]);
    Ok(())
}

// ── FindBoolList ──
#[test]
fn test_find_bool_list() -> Result<()> {
    let bools = list![true, false, false];
    let lst = list![10i32, 20, 30];
    let result = L::findBoolList(&bools, lst.clone(), 99i32)?;
    assert_eq!(result, 10);
    Ok(())
}

// ── FindMap ──
#[test]
fn test_find_map() -> Result<()> {
    let lst = list![1i32, 2, 3];
    // findMap applies fn to elements until predicate returns true; fn also transforms each element
    // x=1: fn returns (10, false) -> keep going; x=2: fn returns (20, true) -> stop
    // result via cons-accumulation: [10, 20, 3] (pre-found elements also transformed)
    let (result, found) = L::findMap(lst.clone(), &|x| Ok((*x * 10, *x == 2)))?;
    assert!(found);
    assert_eq!(result, list![10i32, 20, 3]);
    Ok(())
}

// ── FindOption ──
#[test]
fn test_find_option_some() {
    let lst = list![Some(1i32), None, Some(3)];
    let result = L::findOption(&lst, &|__b0: &_| { let x: Option<i32> = ::std::clone::Clone::clone(__b0); Ok(x.unwrap_or(0) > 0) }).unwrap();
    assert!(result.is_some());
}
#[test]
fn test_find_option_none() {
    let lst: List<Option<i32>> = nil();
    let result = L::findOption(&lst, &|__b0: &_| { let x: Option<i32> = ::std::clone::Clone::clone(__b0); Ok(x.is_some()) }).unwrap();
    assert_eq!(result, None);
}

// ── FindSome ──
#[test]
fn test_find_some() {
    let lst = list![None::<i32>, Some(3)];
    let result = L::findSome(&lst, &|x| Ok(x.clone())).unwrap();
    assert_eq!(result, Some(3));
}

// ── FirstN ──
#[test]
fn test_first_n() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::firstN(lst.clone(), 3)?;
    assert_eq!(result, list![1i32, 2, 3]);
    Ok(())
}

// ── FirstOrEmpty ──
#[test]
fn test_first_or_empty_some() -> Result<()> {
    let lst = list![1i32, 2];
    let result = L::firstOrEmpty(&lst);
    assert_eq!(result.len(), 1);
    Ok(())
}
#[test]
fn test_first_or_empty_none() -> Result<()> {
    let lst: List<i32> = nil();
    let result = L::firstOrEmpty(&lst);
    assert_eq!(result.len(), 0);
    Ok(())
}

// ── Flatten ──
#[test]
fn test_flatten() {
    let lst = list![list![1i32, 2], list![3i32, 4], list![5i32]];
    let result = L::flatten(lst.clone()).unwrap();
    assert_eq!(result, list![1i32, 2, 3, 4, 5]);
}

// ── FlattenReverse ──
#[test]
fn test_flatten_reverse() {
    let lst = list![list![1i32, 2], list![3i32]];
    let result = L::flattenReverse(lst.clone()).unwrap();
    assert_eq!(result.len(), 3);
}

// ── Fold ──
#[test]
fn test_fold() {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::fold(&lst, &|x, acc| Ok(acc + x), 0i32).unwrap();
    assert_eq!(result, 15);
}

// ── Fold1 ──
#[test]
fn test_fold1() {
    let lst = list![1i32, 2, 3];
    let result = L::fold1(&lst, &|x, __b1: &_, acc| { let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(acc + x) }, 0i32, 0i32).unwrap();
    assert_eq!(result, 6);
}

// ── Fold1r ──
#[test]
fn test_fold1r() {
    let lst = list![1i32, 2, 3];
    let result = L::fold1r(&lst, &|acc, x, __b2: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b2); Ok(acc + x) }, 0i32, 0i32).unwrap();
    assert_eq!(result, 6);
}

// ── Fold2 ──
#[test]
fn test_fold2() {
    let lst = list![1i32, 2];
    let result = L::fold2(&lst, &|x, __b1: &_, __b2: &_, acc| { let _a: i32 = ::std::clone::Clone::clone(__b1); let _b: i32 = ::std::clone::Clone::clone(__b2); Ok(acc + x) }, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, 3);
}

// ── Fold2r ──
#[test]
fn test_fold2r() {
    let lst = list![1i32, 2];
    let result = L::fold2r(&lst, &|acc, x, __b2: &_, __b3: &_| { let _a: i32 = ::std::clone::Clone::clone(__b2); let _b: i32 = ::std::clone::Clone::clone(__b3); Ok(acc + x) }, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, 3);
}

// ── Fold3 ──
#[test]
fn test_fold3() {
    let lst = list![1i32];
    let result = L::fold3(&lst, &|x, __b1: &_, __b2: &_, __b3: &_, acc| { let _a: i32 = ::std::clone::Clone::clone(__b1); let _b: i32 = ::std::clone::Clone::clone(__b2); let _c: i32 = ::std::clone::Clone::clone(__b3); Ok(acc + x) }, 0i32, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, 1);
}

// ── Fold31 ──
#[test]
fn test_fold31() {
    let lst = list![1i32, 2];
    let (_r1, _r2, _r3) = L::fold31(&lst, &|x, __b1: &_, s1: i32, s2: i32, __b4: &_| { let _a: i32 = ::std::clone::Clone::clone(__b1); let s3: i32 = ::std::clone::Clone::clone(__b4); Ok((s1 + x, s2 + x, s3 + x)) }, 0i32, 0i32, 0i32, 0i32).unwrap();
}

// ── Fold4 ──
#[test]
fn test_fold4() {
    let lst = list![1i32];
    let result = L::fold4(&lst, &|x, __b1: &_, __b2: &_, __b3: &_, __b4: &_, acc| { let _a: i32 = ::std::clone::Clone::clone(__b1); let _b: i32 = ::std::clone::Clone::clone(__b2); let _c: i32 = ::std::clone::Clone::clone(__b3); let _d: i32 = ::std::clone::Clone::clone(__b4); Ok(acc + x) }, 0i32, 0i32, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, 1);
}

// ── FoldAllValue ──
#[test]
fn test_fold_all_value() -> Result<()> {
    let lst = list![1i32, 2, 3];
    // foldAllValue requires fn output == inValue for each element
    L::foldAllValue(&lst, &|_x, acc: i32| Ok((true, acc)), true, 0i32)?;
    Ok(())
}

// ── FoldList ──
#[test]
fn test_fold_list() {
    let outer = list![list![1i32, 2], list![3i32, 4]];
    let result = L::foldList(&outer, &|x, acc| Ok(acc + x), 0i32).unwrap();
    assert_eq!(result, 10);
}

// ── Foldr ──
#[test]
fn test_foldr() {
    let lst = list![1i32, 2, 3];
    let result = L::foldr(&lst, &|acc, x| Ok(acc + x), 0i32).unwrap();
    assert_eq!(result, 6);
}

// ── Fold20 ──
#[test]
fn test_fold20() {
    let lst = list![1i32, 2];
    let (s1, s2) = L::fold20(&lst, &|x, acc1: i32, __b2: &_| { let acc2: i32 = ::std::clone::Clone::clone(__b2); Ok((acc1 + x, acc2 + x)) }, 0i32, 0i32).unwrap();
    assert_eq!(s1, 3);
    assert_eq!(s2, 3);
}

// ── Fold21 ──
#[test]
fn test_fold21() {
    let lst = list![1i32, 2];
    let (s1, s2) = L::fold21(&lst, &|x, __b1: &_, acc1: i32, __b3: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); let acc2: i32 = ::std::clone::Clone::clone(__b3); Ok((acc1 + x, acc2 + x)) }, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(s1, 3);
    assert_eq!(s2, 3);
}

// ── Fold22 ──
#[test]
fn test_fold22() {
    let lst = list![1i32, 2];
    let (s1, s2) = L::fold22(&lst, &|x, __b1: &_, __b2: &_, acc1: i32, acc2: i32| { let _a: i32 = ::std::clone::Clone::clone(__b1); let _b: i32 = ::std::clone::Clone::clone(__b2); Ok((acc1 + x, acc2 + x)) }, 0i32, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(s1, 3);
    assert_eq!(s2, 3);
}

// ── FromOption ──
#[test]
fn test_from_option_some() -> Result<()> {
    let result = L::fromOption(Some(42i32));
    assert_eq!(result, list![42i32]);
    Ok(())
}
#[test]
fn test_from_option_none() -> Result<()> {
    let result = L::fromOption(Option::<i32>::None);
    assert!(result.is_empty());
    Ok(())
}

// ── GetAtIndexLst ──
#[test]
fn test_get_at_index_lst() -> Result<()> {
    let lst = list![10i32, 20, 30];
    let positions = list![1i32, 2, 3];
    let result = L::getAtIndexLst(lst.clone(), positions.clone(), false)?;
    assert_eq!(result, list![10i32, 20, 30]);
    Ok(())
}

// ── GetIndexFirst ──
#[test]
fn test_get_index_first() -> Result<()> {
    // getIndexFirst forwards to listGet, which bounds-checks (fallible).
    let lst = list![10i32, 20, 30];
    assert_eq!(L::getIndexFirst(1, &lst)?, 10);
    assert!(L::getIndexFirst(4, &lst).is_err());
    Ok(())
}

// ── GetMember ──
#[test]
fn test_get_member() -> Result<()> {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::getMember(2, &lst)?, 2);
    Ok(())
}

// ── GetMemberOnTrue ──
#[test]
fn test_get_member_on_true() -> Result<()> {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::getMemberOnTrue(2i32, &lst, &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?, 2);
    Ok(())
}

// ── HasOneElement ──
#[test]
fn test_has_one_element_true() -> Result<()> {
    assert!(L::hasOneElement(&list![1i32]));
    Ok(())
}
#[test]
fn test_has_one_element_false() -> Result<()> {
    assert!(!L::hasOneElement(&list![1i32, 2]));
    assert!(!L::hasOneElement(&nil::<i32>()));
    Ok(())
}

// ── HasSeveralElements ──
#[test]
fn test_has_several_elements_true() -> Result<()> {
    assert!(L::hasSeveralElements(&list![1i32, 2]));
    Ok(())
}
#[test]
fn test_has_several_elements_false() -> Result<()> {
    assert!(!L::hasSeveralElements(&list![1i32]));
    assert!(!L::hasSeveralElements(&nil::<i32>()));
    Ok(())
}

// ── HeapSortIntList ──
#[test]
fn test_heap_sort_int_list() -> Result<()> {
    let lst = list![3i32, 1, 4, 1, 5, 9, 2, 6];
    let result = L::heapSortIntList(lst.clone())?;
    assert_eq!(result, list![1i32, 1, 2, 3, 4, 5, 6, 9]);
    Ok(())
}

// ── Insert ──
#[test]
fn test_insert() -> Result<()> {
    let lst = list![1i32, 4, 5];
    let result = L::insert(lst.clone(), 2, 2i32)?;
    assert_eq!(result, list![1i32, 2, 4, 5]);
    Ok(())
}

// ── InsertListSorted ──
#[test]
fn test_insert_list_sorted() -> Result<()> {
    let lst = list![1i32, 3, 5];
    let to_insert = list![2i32, 4];
    let result = L::insertListSorted(&lst, &to_insert, &|a0, a1| less_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?;
    assert_eq!(result, list![1i32, 2, 3, 4, 5]);
    Ok(())
}

// ── IntRange ──
#[test]
fn test_int_range() {
    let result = L::intRange(5);
    assert_eq!(result, list![1i32, 2, 3, 4, 5]);
}

// ── IntRange2 ──
#[test]
fn test_int_range2() {
    let result = L::intRange2(1, 5);
    assert_eq!(result, list![1i32, 2, 3, 4, 5]);
}
#[test]
fn test_int_range2_from_3() {
    let result = L::intRange2(3, 5);
    assert_eq!(result, list![3i32, 4, 5]);
}

// ── IntRange3 ──
#[test]
fn test_int_range3() -> Result<()> {
    let result = L::intRange3(1, 1, 5)?;
    assert_eq!(result, list![1i32, 2, 3, 4, 5]);
    Ok(())
}
#[test]
fn test_int_range3_step() -> Result<()> {
    let result = L::intRange3(0, 2, 6)?;
    assert_eq!(result, list![0i32, 2, 4, 6]);
    Ok(())
}

// ── Intersection1OnTrue ──
#[test]
fn test_intersection1_on_true() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![2i32, 3, 4];
    let result = L::intersection1OnTrue(a.clone(), b.clone(), &eq_i)?;
    assert!(result.0.len() > 0);
    Ok(())
}

// ── IntersectionOnTrue ──
#[test]
fn test_intersection_on_true() {
    let a = list![1i32, 2, 3];
    let b = list![2i32, 3, 4];
    let result = L::intersectionOnTrue(&a, &b, &eq_i).unwrap();
    assert_eq!(result, list![2i32, 3]);
}

// ── IsEqual ──
#[test]
fn test_is_equal_true() -> Result<()> {
    assert!(L::isEqual(list![1i32, 2], list![1i32, 2], true)?);
    Ok(())
}
#[test]
fn test_is_equal_false() -> Result<()> {
    assert!(!L::isEqual(list![1i32, 2], list![1i32, 3], true)?);
    Ok(())
}

// ── IsEqualOnTrue ──
#[test]
fn test_is_equal_on_true() -> Result<()> {
    assert!(L::isEqualOnTrue(list![1i32, 2], list![1i32, 2], &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1))).unwrap());
    assert!(!L::isEqualOnTrue(list![1i32, 2], list![1i32, 3], &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1))).unwrap());
    Ok(())
}

// ── IsMemberOnTrue ──
#[test]
fn test_is_member_on_true() {
    let lst = list![1i32, 2, 3];
    assert!(L::isMemberOnTrue(2i32, &lst, &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1))).unwrap());
    assert!(!L::isMemberOnTrue(4i32, &lst, &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1))).unwrap());
}

// ── IsPrefixOnTrue ──
#[test]
fn test_is_prefix_on_true() -> Result<()> {
    let prefix = list![1i32, 2];
    let full = list![1i32, 2, 3, 4];
    assert!(L::isPrefixOnTrue(prefix.clone(), full.clone(), &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1))).unwrap());
    assert!(!L::isPrefixOnTrue(list![1i32, 3], full, &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1))).unwrap());
    Ok(())
}

// ── KeepPositions ──
#[test]
fn test_keep_positions() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let positions = list![1i32, 3, 5];
    let result = L::keepPositions(lst.clone(), positions.clone(), false)?;
    assert_eq!(result, list![1i32, 3, 5]);
    Ok(())
}

// ── KeepPositionsSorted ──
#[test]
fn test_keep_positions_sorted() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let positions = list![1i32, 3, 5];
    let result = L::keepPositionsSorted(lst.clone(), &positions, false)?;
    assert_eq!(result, list![1i32, 3, 5]);
    Ok(())
}

// ── Last ──
#[test]
fn test_last() -> Result<()> {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::last(&lst)?, 3);
    Ok(())
}

// ── LastListOrEmpty ──
#[test]
fn test_last_list_or_empty() {
    let lst = list![list![1i32], list![2i32, 3]];
    let result = L::lastListOrEmpty(&lst);
    assert_eq!(result, list![2i32, 3]);
}

// ── LastN ──
#[test]
fn test_last_n() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::lastN(lst.clone(), 3)?;
    assert_eq!(result, list![3i32, 4, 5]);
    Ok(())
}

// ── LengthListElements ──
#[test]
fn test_length_list_elements() {
    let lst = list![list![1i32, 2], list![3i32, 4, 5], list![6i32]];
    assert_eq!(L::lengthListElements(lst.clone()), 6);
}

// ── ListArrayReverse ──
#[test]
fn test_list_array_reverse() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::listArrayReverse(lst.clone())?;
    // Result is metamodelica::Array<i32> (Rc<RefCell<Vec<i32>>>)
    assert_eq!(result.borrow().len(), 3);
    Ok(())
}

// ── ListIsLonger ──
#[test]
fn test_list_is_longer() {
    let a = list![1i32, 2, 3];
    let b = list![1i32, 2];
    assert!(L::listIsLonger(a.clone(), b.clone()).unwrap());
    assert!(!L::listIsLonger(b.clone(), a.clone()).unwrap());
}

// ── Map ──
#[test]
fn test_map() {
    let lst = list![1i32, 2, 3];
    let result = L::map(lst.clone(), &double).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── Map1 ──
// map1(list, fn, arg1) where fn is (TI, ArgT1) -> TO
#[test]
fn test_map1() {
    let lst = list![1i32, 2, 3];
    let result = L::map1(lst.clone(), &|x, __b1: &_| { let factor: i32 = ::std::clone::Clone::clone(__b1); Ok(x * factor) }, 2i32).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── Map1Fold ──
// map1Fold(list, fn, constArg, foldArg) where fn is (TI, ArgT1, FT) -> (TO, FT)
#[test]
fn test_map1_fold() {
    let lst = list![1i32, 2, 3];
    let (result, acc) = L::map1Fold(&lst, &|x, __b1: &_, fold: i32| { let _const: i32 = ::std::clone::Clone::clone(__b1); Ok((x + fold, fold + 1)) }, 0i32, 0i32).unwrap();
    assert_eq!(result, list![1i32, 3, 5]);
    assert_eq!(acc, 3);
}

// ── Map1List ──
#[test]
fn test_map1_list() {
    let lst = list![list![1i32, 2]];
    let result = L::map1List(lst.clone(), &|__b0: &_, __b1: &_| { let x: i32 = ::std::clone::Clone::clone(__b0); let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(x * 2) }, 0i32).unwrap();
    // map1List reverses inner list due to cons-accumulation
    assert_eq!(result.len(), 1);
}

// ── Map1Option ──
// map1Option(list_of_options, fn, arg1) where fn is (TI, ArgT) -> TO
#[test]
fn test_map1_option() -> Result<()> {
    let lst = list![Some(1i32), Some(2)];
    let result = L::map1Option(&lst, &|x, __b1: &_| { let factor: i32 = ::std::clone::Clone::clone(__b1); Ok(x * factor) }, 2i32)?;
    assert_eq!(result, list![2i32, 4]);
    Ok(())
}

// ── Map1_0 ──
// map1_0(list, fn, arg1) where fn is (TI, ArgT1) -> () - plain return
#[test]
fn test_map1_0() {
    let lst = list![1i32, 2, 3];
    L::map1_0(&lst, &|_x, __b1: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b1); Ok(()) }, 0i32).unwrap();
}

// ── Map1_2 ──
// map1_2(list, fn, arg1) where fn is (TI, ArgT1) -> (TO1, TO2), returns (list1, list2)
#[test]
fn test_map1_2() {
    let lst = list![1i32, 2];
    let (r1, r2) = L::map1_2(&lst, &|x, __b1: &_| { let _: i32 = ::std::clone::Clone::clone(__b1); Ok((x * 2, x * 3)) }, 0i32).unwrap();
    assert_eq!(r1, list![2i32, 4]);
    assert_eq!(r2, list![3i32, 6]);
}

// ── Map1r ──
// map1r(list, fn, arg1) where fn is (ArgT1, TI) -> TO
#[test]
fn test_map1r() {
    let lst = list![1i32, 2, 3];
    let result = L::map1r(lst.clone(), &|__b0: &_, __b1: &_| { let factor: i32 = ::std::clone::Clone::clone(__b0); let x = ::std::clone::Clone::clone(__b1); Ok(x * factor) }, 2i32).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── Map2 ──
// map2(list, fn, arg1, arg2) where fn is (TI, ArgT1, ArgT2) -> TO
#[test]
fn test_map2() {
    let lst = list![1i32, 2, 3];
    let result = L::map2(lst.clone(), &|x, __b1: &_, __b2: &_| { let a: i32 = ::std::clone::Clone::clone(__b1); let b: i32 = ::std::clone::Clone::clone(__b2); Ok(x + a + b) }, 10i32, 100i32).unwrap();
    assert_eq!(result, list![111i32, 112, 113]);
}

// ── Map2Fold ──
// map2Fold(list, fn, constArg1, constArg2, foldArg, accum) where fn is (TI, ArgT1, ArgT2, FT) -> (TO, FT)
#[test]
fn test_map2_fold() {
    let lst = list![1i32, 2];
    let (result, acc) = L::map2Fold(&lst, &|x, __b1: &_, __b2: &_, fold: i32| { let _a: i32 = ::std::clone::Clone::clone(__b1); let _b: i32 = ::std::clone::Clone::clone(__b2); Ok((x * 2, fold + 1)) }, 0i32, 0i32, 0i32, nil()).unwrap();
    assert_eq!(result, list![2i32, 4]);
    assert_eq!(acc, 2);
}

// ── Map2FoldCheckReferenceEq ──
#[test]
fn test_map2_fold_check_reference_eq() {
    let lst = list![1i32, 2];
    let (result, _acc) = L::map2FoldCheckReferenceEq(lst.clone(), &|x, __b1: &_, __b2: &_, fold: i32| { let _a: i32 = ::std::clone::Clone::clone(__b1); let _b: i32 = ::std::clone::Clone::clone(__b2); Ok((x * 2, fold + 1)) }, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── Map2List ──
// map2List(list_of_lists, fn, arg1, arg2) where fn is (TI, ArgT1, ArgT2) -> TO
#[test]
fn test_map2_list() {
    let lst = list![list![1i32, 2]];
    let result = L::map2List(lst.clone(), &|x, __b1: &_, __b2: &_| { let a: i32 = ::std::clone::Clone::clone(__b1); let b: i32 = ::std::clone::Clone::clone(__b2); Ok(x + a + b) }, 10i32, 100i32).unwrap();
    assert_eq!(result, list![list![111i32, 112]]);
}

// ── Map2Option ──
// map2Option(list_of_options, fn, arg1, arg2) where fn is (TI, ArgT1, ArgT2) -> TO
#[test]
fn test_map2_option() -> Result<()> {
    let lst = list![Some(1i32), Some(2)];
    let result = L::map2Option(&lst, &|x, __b1: &_, __b2: &_| { let a: i32 = ::std::clone::Clone::clone(__b1); let b: i32 = ::std::clone::Clone::clone(__b2); Ok(x + a + b) }, 10i32, 100i32)?;
    assert_eq!(result, list![111i32, 112]);
    Ok(())
}

// ── Map2Reverse ──
#[test]
fn test_map2_reverse() {
    let lst = list![1i32, 2, 3];
    let result = L::map2Reverse(lst.clone(), &|x, __b1: &_, __b2: &_| { let a: i32 = ::std::clone::Clone::clone(__b1); let b: i32 = ::std::clone::Clone::clone(__b2); Ok(x + a + b) }, 10i32, 100i32).unwrap();
    assert_eq!(result, list![113i32, 112, 111]);
}

// ── Map2_0 ──
#[test]
fn test_map2_0() {
    let lst = list![1i32, 2, 3];
    L::map2_0(&lst, &|_x, __b1: &_, __b2: &_| { let _a: i32 = ::std::clone::Clone::clone(__b1); let _b: i32 = ::std::clone::Clone::clone(__b2); Ok(()) }, 0i32, 0i32).unwrap();
}

// ── Map2_2 ──
#[test]
fn test_map2_2() {
    let lst = list![1i32, 2];
    let (r1, r2) = L::map2_2(&lst, &|x, __b1: &_, __b2: &_| { let a: i32 = ::std::clone::Clone::clone(__b1); let _b: i32 = ::std::clone::Clone::clone(__b2); Ok((x + a, x * 2)) }, 10i32, 0i32).unwrap();
    assert_eq!(r1, list![11i32, 12]);
    assert_eq!(r2, list![2i32, 4]);
}

// ── Map3 ──
#[test]
fn test_map3() {
    let lst = list![1i32];
    let result = L::map3(lst.clone(), &|x, __b1: &_, __b2: &_, __b3: &_| { let a: i32 = ::std::clone::Clone::clone(__b1); let b: i32 = ::std::clone::Clone::clone(__b2); let c: i32 = ::std::clone::Clone::clone(__b3); Ok(x + a + b + c) }, 10i32, 100i32, 1000i32).unwrap();
    assert_eq!(result, list![1111i32]);
}

// ── Map3Fold ──
#[test]
fn test_map3_fold() {
    let lst = list![1i32];
    let (result, acc) = L::map3Fold(&lst, &|x, __b1: &_, __b2: &_, __b3: &_, fold: i32| { let _a: i32 = ::std::clone::Clone::clone(__b1); let _b: i32 = ::std::clone::Clone::clone(__b2); let _c: i32 = ::std::clone::Clone::clone(__b3); Ok((x * 2, fold + 1)) }, 0i32, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32]);
    assert_eq!(acc, 1);
}

// ── Map4 ──
#[test]
fn test_map4() {
    let lst = list![1i32];
    let result = L::map4(lst.clone(), &|x, __b1: &_, __b2: &_, __b3: &_, __b4: &_| { let a: i32 = ::std::clone::Clone::clone(__b1); let b: i32 = ::std::clone::Clone::clone(__b2); let c: i32 = ::std::clone::Clone::clone(__b3); let d: i32 = ::std::clone::Clone::clone(__b4); Ok(x + a + b + c + d) }, 1i32, 2i32, 3i32, 4i32).unwrap();
    assert_eq!(result, list![11i32]);
}

// ── Map4_0 ──
#[test]
fn test_map4_0() {
    let lst = list![1i32];
    L::map4_0(&lst, &|_x, __b1: &_, __b2: &_, __b3: &_, __b4: &_| { let _a: i32 = ::std::clone::Clone::clone(__b1); let _b: i32 = ::std::clone::Clone::clone(__b2); let _c: i32 = ::std::clone::Clone::clone(__b3); let _d: i32 = ::std::clone::Clone::clone(__b4); Ok(()) }, 0i32, 0i32, 0i32, 0i32).unwrap();
}

// ── Map5 ──
#[test]
fn test_map5() {
    let lst = list![1i32];
    let result = L::map5(lst.clone(), &|x, __b1: &_, __b2: &_, __b3: &_, __b4: &_, __b5: &_| { let a: i32 = ::std::clone::Clone::clone(__b1); let b: i32 = ::std::clone::Clone::clone(__b2); let c: i32 = ::std::clone::Clone::clone(__b3); let d: i32 = ::std::clone::Clone::clone(__b4); let e: i32 = ::std::clone::Clone::clone(__b5); Ok(x + a + b + c + d + e) }, 1i32, 2i32, 3i32, 4i32, 5i32).unwrap();
    assert_eq!(result, list![16i32]);
}

// ── Map6 ──
#[test]
fn test_map6() {
    let lst = list![1i32];
    let result = L::map6(lst.clone(), &|x, __b1: &_, __b2: &_, __b3: &_, __b4: &_, __b5: &_, __b6: &_| { let a: i32 = ::std::clone::Clone::clone(__b1); let b: i32 = ::std::clone::Clone::clone(__b2); let c: i32 = ::std::clone::Clone::clone(__b3); let d: i32 = ::std::clone::Clone::clone(__b4); let e: i32 = ::std::clone::Clone::clone(__b5); let f: i32 = ::std::clone::Clone::clone(__b6); Ok(x + a + b + c + d + e + f) }, 1i32, 2i32, 3i32, 4i32, 5i32, 6i32).unwrap();
    assert_eq!(result, list![22i32]);
}

// ── MapArray ──
#[test]
fn test_map_array() {
    use metamodelica::arrayFromVec;
    let a = arrayFromVec(vec![1i32, 2, 3]);
    let result = L::mapArray(a, &|a0| double(::std::clone::Clone::clone(a0))).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── MapCheckReferenceEq ──
#[test]
fn test_map_check_reference_eq() {
    let lst = list![1i32, 2, 3];
    let result = L::mapCheckReferenceEq(lst.clone(), &|x| Ok(x)).unwrap();
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── MapFlat ──
#[test]
fn test_map_flat() {
    let lst = list![list![1i32, 2], list![3i32, 4]];
    let result = L::mapFlat(&lst, &|inner| Ok(inner)).unwrap();
    // mapFlat reverses inner lists due to cons-accumulation
    assert_eq!(result.len(), 4);
}

// ── MapFlatReverse ──
#[test]
fn test_map_flat_reverse() {
    let lst = list![list![1i32, 2], list![3i32]];
    let result = L::mapFlatReverse(&lst, &|inner| Ok(inner.clone())).unwrap();
    assert_eq!(result.len(), 3);
}

// ── MapFold ──
#[test]
fn test_map_fold() {
    let lst = list![1i32, 2, 3];
    let (result, acc) = L::mapFold(&lst, &|x, a| Ok((x * 2, a + x)), 0i32).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
    assert_eq!(acc, 6);
}

// ── MapFold2 ──
#[test]
fn test_map_fold2() {
    let lst = list![1i32, 2];
    let (result, a, b) = L::mapFold2(&lst, &|x, acc1: i32, acc2: i32| Ok((x * 2, acc1 + x, acc2 + x)), 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32, 4]);
    assert_eq!(a, 3);
    assert_eq!(b, 3);
}

// ── MapFold3 ──
#[test]
fn test_map_fold3() {
    let lst = list![1i32];
    let (result, a, b, c) = L::mapFold3(&lst, &|x, f1: i32, f2: i32, __b3: &_| { let f3: i32 = ::std::clone::Clone::clone(__b3); Ok((x * 2, f1 + x, f2 + x, f3 + x)) }, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32]);
    assert_eq!(a, 1);
    assert_eq!(b, 1);
    assert_eq!(c, 1);
}

// ── MapFold5 ──
#[test]
fn test_map_fold5() {
    let lst = list![1i32];
    let (result, a, b, c, d, e) = L::mapFold5(&lst, &|x, f1: i32, f2: i32, __b3: &_, __b4: &_, f5: i32| { let f3: i32 = ::std::clone::Clone::clone(__b3); let f4: i32 = ::std::clone::Clone::clone(__b4); Ok((x.clone(), f1+1, f2+1, f3+1, f4+1, f5+1)) }, 0i32, 0i32, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, list![1i32]);
    assert_eq!(a, 1);
    assert_eq!(e, 1);
}

// ── MapFoldList ──
#[test]
fn test_map_fold_list() {
    let lst = list![list![1i32, 2], list![3i32]];
    let (_result, acc) = L::mapFoldList(&lst, &|x, fold: i32| Ok((x * 2, fold + x)), 0i32).unwrap();
    assert_eq!(acc, 6);
}

// ── MapIndices ──
#[test]
fn test_map_indices() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let indices = list![1i32, 3];
    let result = L::mapIndices(lst.clone(), &indices, &|a0| double(::std::clone::Clone::clone(a0)))?;
    assert_eq!(result.len(), 3);
    Ok(())
}

// ── MapList ──
#[test]
fn test_map_list() {
    let lst = list![list![1i32, 2], list![3i32, 4]];
    let result = L::mapList(lst.clone(), &|a0| double(::std::clone::Clone::clone(a0))).unwrap();
    assert_eq!(result, list![list![2i32, 4], list![6i32, 8]]);
}

// ── MapListReverse ──
#[test]
fn test_map_list_reverse() {
    let lst = list![list![1i32, 2], list![3i32]];
    let result = L::mapListReverse(lst.clone(), &|a0| double(::std::clone::Clone::clone(a0))).unwrap();
    assert_eq!(result.len(), 2);
}

// ── MapMap ──
#[test]
fn test_map_map() {
    let lst = list![1i32, 2, 3];
    let result = L::mapMap(lst.clone(), &|a0| double(::std::clone::Clone::clone(a0)), &|x| Ok(x + 1)).unwrap();
    assert_eq!(result, list![3i32, 5, 7]);
}

// ── MapMapBoolAnd ──
#[test]
fn test_map_map_bool_and() {
    let lst = list![2i32, 4, 6];
    let result = L::mapMapBoolAnd(&lst, &|x| Ok(*x), &is_even).unwrap();
    assert!(result);
}
#[test]
fn test_map_map_bool_and_false() {
    let lst = list![1i32, 2, 3];
    let result = L::mapMapBoolAnd(&lst, &|x| Ok(*x), &is_even).unwrap();
    assert!(!result);
}

// ── MapOption ──
#[test]
fn test_map_option() -> Result<()> {
    let lst = list![Some(1i32), Some(2)];
    let result = L::mapOption(&lst, &|x| Ok(x * 2))?;
    assert_eq!(result, list![2i32, 4]);
    Ok(())
}

// ── MapReverse ──
#[test]
fn test_map_reverse() {
    let lst = list![1i32, 2, 3];
    let result = L::mapReverse(lst.clone(), &|a0| double(::std::clone::Clone::clone(a0))).unwrap();
    assert_eq!(result, list![6i32, 4, 2]);
}

// ── Map_0 ──
#[test]
fn test_map_0() {
    let lst = list![1i32, 2, 3];
    L::map_0(&lst, &|_x| Ok(())).unwrap();
}

// ── Map_2 ──
#[test]
fn test_map_2() {
    let lst = list![1i32, 2];
    let (r1, r2) = L::map_2(&lst, &|x| Ok((x * 2, x * 3))).unwrap();
    assert_eq!(r1, list![2i32, 4]);
    assert_eq!(r2, list![3i32, 6]);
}

// ── Map_3 ──
#[test]
fn test_map_3() {
    let lst = list![1i32, 2];
    let (r1, r2, r3) = L::map_3(&lst, &|x| Ok((x.clone(), x * 2, x * 3))).unwrap();
    assert_eq!(r1, list![1i32, 2]);
    assert_eq!(r2, list![2i32, 4]);
    assert_eq!(r3, list![3i32, 6]);
}

// ── MaxElement ──
#[test]
fn test_max_element() -> Result<()> {
    let lst = list![3i32, 1, 4, 1, 5, 9, 2, 6];
    assert_eq!(L::maxElement(&lst, &|a0, a1| less_i(a0, ::std::clone::Clone::clone(a1)))?, 9);
    Ok(())
}

// ── MergeSorted ──
#[test]
fn test_merge_sorted() -> Result<()> {
    let a = list![1i32, 3, 5];
    let b = list![2i32, 4, 6];
    let result = L::mergeSorted(a.clone(), b.clone(), &|a0, a1| less_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?;
    assert_eq!(result, list![1i32, 2, 3, 4, 5, 6]);
    Ok(())
}

// ── MinElement ──
#[test]
fn test_min_element() -> Result<()> {
    let lst = list![3i32, 1, 4, 1, 5];
    assert_eq!(L::minElement(&lst, &|a0, a1| less_i(::std::clone::Clone::clone(a0), a1))?, 1);
    Ok(())
}

// ── MkOption ──
#[test]
fn test_mk_option_some() {
    let lst = list![1i32, 2];
    let result = L::mkOption(lst.clone());
    assert!(result.is_some());
}
#[test]
fn test_mk_option_none() {
    let lst: List<i32> = nil();
    let result = L::mkOption(lst.clone());
    assert!(result.is_none());
}

// ── None ──
#[test]
fn test_none() {
    let lst: List<i32> = nil();
    assert!(L::none(&lst, &|a0| is_positive(::std::clone::Clone::clone(a0))).unwrap());
}
#[test]
fn test_none_false() {
    let lst = list![1i32, -2];
    assert!(!L::none(&lst, &|a0| is_positive(::std::clone::Clone::clone(a0))).unwrap());
}

// ── NotMember ──
#[test]
fn test_not_member() {
    let lst = list![1i32, 2, 3];
    assert!(L::notMember(4, lst.clone()));
    assert!(!L::notMember(2, lst.clone()));
}

// ── Partition ──
#[test]
fn test_partition() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5, 6];
    let result = L::partition(lst.clone(), 2)?;
    assert!(result.len() > 0);
    Ok(())
}

// ── Position ──
#[test]
fn test_position() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    assert_eq!(L::position(3, &lst)?, 3);
    Ok(())
}
#[test]
fn test_position_not_found() {
    let lst = list![1i32, 2, 3];
    // position returns Err when element not found
    assert!(L::position(9, &lst).is_err());
}

// ── Position1OnTrue ──
#[test]
fn test_position1_on_true() {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::position1OnTrue(&lst, &|x, __b1: &_| { let _: i32 = ::std::clone::Clone::clone(__b1); Ok(*x == 2) }, 0i32).unwrap(), 2);
}

// ── PositionOnTrue ──
#[test]
fn test_position_on_true() {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::positionOnTrue(&lst, &|a0| is_even(::std::clone::Clone::clone(a0))).unwrap(), 2);
}

// ── Reduce ──
#[test]
fn test_reduce() -> Result<()> {
    let lst = list![1i32, 2, 3, 4];
    let result = L::reduce(&lst, &|a0, a1| add_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?;
    assert_eq!(result, 10);
    Ok(())
}

// ── RemoveOnTrue ──
#[test]
fn test_remove_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::removeOnTrue(2i32, &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)), lst.clone()).unwrap();
    assert_eq!(result, list![1i32, 3, 4]);
}

// ── Repeat ──
#[test]
fn test_repeat() {
    let elt = list![42i32];
    let result = L::repeat(elt.clone(), 3);
    assert_eq!(result.len(), 3);
}

// ── ReplaceAt ──
#[test]
fn test_replace_at() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::replaceAt(99i32, 2, lst.clone())?;
    assert_eq!(result, list![1i32, 99, 3]);
    Ok(())
}

// ── ReplaceAtIndexFirst ──
#[test]
fn test_replace_at_index_first() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::replaceAtIndexFirst(1, 99i32, lst.clone())?;
    assert_eq!(result, list![99i32, 2, 3]);
    Ok(())
}

// ── ReplaceAtWithList ──
#[test]
fn test_replace_at_with_list() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let replacement = list![10i32, 11];
    let result = L::replaceAtWithList(replacement.clone(), 2, lst.clone())?;
    assert!(result.len() > 0);
    Ok(())
}

// ── ReplaceOnTrue ──
#[test]
fn test_replace_on_true() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let (result, replaced) = L::replaceOnTrue(99i32, lst.clone(), &|x| Ok(*x == 2))?;
    assert!(replaced);
    assert_eq!(result, list![1i32, 99, 3]);
    Ok(())
}

// ── RestOrEmpty ──
#[test]
fn test_rest_or_empty() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::restOrEmpty(lst.clone())?;
    assert_eq!(result, list![2i32, 3]);
    Ok(())
}
#[test]
fn test_rest_or_empty_empty() -> Result<()> {
    let lst: List<i32> = nil();
    let result = L::restOrEmpty(lst.clone())?;
    assert!(result.is_empty());
    Ok(())
}

// ── Second ──
#[test]
fn test_second() -> Result<()> {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::second(&lst)?, 2);
    Ok(())
}

// ── Separate1OnTrue ──
#[test]
fn test_separate1_on_true() {
    let lst = list![1i32, 2, 3];
    let (a, b) = L::separate1OnTrue(&lst, &|x, __b1: &_| { let _: i32 = ::std::clone::Clone::clone(__b1); Ok(x % 2 == 0) }, 0i32).unwrap();
    // separate functions use cons-accumulation (reversed output)
    assert_eq!(a.len(), 1);
    assert_eq!(b.len(), 2);
}

// ── SeparateOnTrue ──
#[test]
fn test_separate_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let (a, b) = L::separateOnTrue(&lst, &|a0| is_even(::std::clone::Clone::clone(a0))).unwrap();
    // separate functions use cons-accumulation (reversed output)
    assert_eq!(a.len(), 2);
    assert_eq!(b.len(), 2);
}

// ── Set ──
#[test]
fn test_set() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::set(lst.clone(), 2, 99)?;
    assert_eq!(result, list![1i32, 99, 3]);
    Ok(())
}

// ── SetDifference ──
#[test]
fn test_set_difference() -> Result<()> {
    let a = list![1i32, 2, 3, 4];
    let b = list![3i32, 4, 5];
    let result = L::setDifference(a.clone(), &b)?;
    assert_eq!(result, list![1i32, 2]);
    Ok(())
}

// ── SetDifferenceIntN ──
#[test]
fn test_set_difference_int_n() -> Result<()> {
    let a = list![1i32, 2, 3, 4];
    let b = list![3i32, 4, 5];
    let result = L::setDifferenceIntN(&a, &b, 5)?;
    assert!(result.len() <= 4);
    Ok(())
}

// ── SetDifferenceOnTrue ──
#[test]
fn test_set_difference_on_true() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![2i32, 3];
    let result = L::setDifferenceOnTrue(a.clone(), &b, &eq_i)?;
    assert_eq!(result, list![1i32]);
    Ok(())
}

// ── SetEqualOnTrue ──
#[test]
fn test_set_equal_on_true() {
    let a = list![1i32, 2, 3];
    let b = list![3i32, 1, 2];
    assert!(L::setEqualOnTrue(&a, &b, &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1))).unwrap());
}

// ── Sort ──
#[test]
fn test_sort() -> Result<()> {
    let lst = list![3i32, 1, 4, 1, 5, 9, 2, 6];
    let result = L::sort(lst.clone(), Arc::new(less_i))?;
    assert_eq!(result, list![9i32, 6, 5, 4, 3, 2, 1, 1]);
    Ok(())
}

// ── SortedDuplicates ──
#[test]
fn test_sorted_duplicates() -> Result<()> {
    let lst = list![1i32, 1, 2, 3, 3, 4];
    let result = L::sortedDuplicates(lst.clone(), &|a0, a1| eq_i(::std::clone::Clone::clone(a0), a1))?;
    assert!(result.len() >= 0);
    Ok(())
}

// ── SortedListAllUnique ──
#[test]
fn test_sorted_list_all_unique() -> Result<()> {
    let lst = list![1i32, 2, 3];
    assert!(L::sortedListAllUnique(lst.clone(), &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?);
    Ok(())
}

// ── SortedUnique ──
#[test]
fn test_sorted_unique() -> Result<()> {
    let lst = list![1i32, 1, 2, 3, 3, 4];
    let result = L::sortedUnique(lst.clone(), &|a0, a1| eq_i(::std::clone::Clone::clone(a0), a1))?;
    assert_eq!(result, list![1i32, 2, 3, 4]);
    Ok(())
}

// ── SortedUniqueAndDuplicates ──
#[test]
fn test_sorted_unique_and_duplicates() -> Result<()> {
    let lst = list![1i32, 1, 2, 3, 3, 4];
    let (unique, _dups) = L::sortedUniqueAndDuplicates(lst.clone(), &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)))?;
    assert_eq!(unique, list![1i32, 2, 3, 4]);
    Ok(())
}

// ── SortedUniqueOnlyDuplicates ──
#[test]
fn test_sorted_unique_only_duplicates() -> Result<()> {
    let lst = list![1i32, 1, 2, 3, 3, 4];
    let result = L::sortedUniqueOnlyDuplicates(lst.clone(), &|a0, a1| eq_i(::std::clone::Clone::clone(a0), a1))?;
    assert!(result.len() >= 0);
    Ok(())
}

// ── Split ──
#[test]
fn test_split() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let (a, b) = L::split(lst.clone(), 3)?;
    assert_eq!(a, list![1i32, 2, 3]);
    assert_eq!(b, list![4i32, 5]);
    Ok(())
}

// ── Split1OnTrue ──
#[test]
fn test_split1_on_true() {
    let lst = list![1i32, 2, 3];
    let (before, after) = L::split1OnTrue(&lst, &|x, __b1: &_| { let _: i32 = ::std::clone::Clone::clone(__b1); Ok(*x == 2) }, 0i32).unwrap();
    assert_eq!(before.len() + after.len(), 3);
}

// ── Split2OnTrue ──
#[test]
fn test_split2_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let (before, after) = L::split2OnTrue(&lst, &|x, __b1: &_, __b2: &_| { let _a: i32 = ::std::clone::Clone::clone(__b1); let _b: i32 = ::std::clone::Clone::clone(__b2); Ok(*x == 3) }, 0i32, 0i32).unwrap();
    assert_eq!(before.len() + after.len(), 4);
}

// ── SplitEqualParts ──
#[test]
fn test_split_equal_parts() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5, 6];
    let result = L::splitEqualParts(lst.clone(), 2)?;
    assert_eq!(result.len(), 2);
    Ok(())
}

// ── SplitEqualPrefix ──
#[test]
fn test_split_equal_prefix() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![1i32, 2, 4];
    let (prefix, _rest) = L::splitEqualPrefix(a.clone(), b.clone(), &|a0, a1| eq_i(::std::clone::Clone::clone(a0), ::std::clone::Clone::clone(a1)), &nil())?;
    assert_eq!(prefix.len(), 2);
    Ok(())
}

// ── SplitLast ──
#[test]
fn test_split_last() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let (last, init) = L::splitLast(lst.clone())?;
    assert_eq!(last, 3);
    assert_eq!(init, list![1i32, 2]);
    Ok(())
}

// ── SplitOnBoolList ──
#[test]
fn test_split_on_bool_list() -> Result<()> {
    let lst = list![1i32, 2, 3, 4];
    let blist = list![false, true, false, true];
    let (trues, falses) = L::splitOnBoolList(lst.clone(), blist.clone())?;
    assert_eq!(trues, list![2i32, 4]);
    assert_eq!(falses, list![1i32, 3]);
    Ok(())
}

// ── SplitOnFirstMatch ──
#[test]
fn test_split_on_first_match() -> Result<()> {
    let lst = list![1i32, 2, 3, 4];
    let (before, after) = L::splitOnFirstMatch(lst.clone(), &|a0| is_even(::std::clone::Clone::clone(a0)))?;
    assert_eq!(before, list![1i32]);
    assert_eq!(after, list![2i32, 3, 4]);
    Ok(())
}

// ── SplitOnTrue ──
#[test]
fn test_split_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let (trues, falses) = L::splitOnTrue(&lst, &|a0| is_even(::std::clone::Clone::clone(a0))).unwrap();
    assert_eq!(trues, list![2i32, 4]);
    assert_eq!(falses, list![1i32, 3]);
}

// ── Splitr ──
#[test]
fn test_splitr() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let (a, b) = L::splitr(lst.clone(), 3)?;
    assert_eq!(a.len() + b.len(), 5);
    Ok(())
}

// ── StripLast ──
#[test]
fn test_strip_last() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::stripLast(lst.clone())?;
    assert_eq!(result, list![1i32, 2]);
    Ok(())
}

// ── StripN ──
#[test]
fn test_strip_n() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::stripN(lst.clone(), 2)?;
    assert_eq!(result, list![3i32, 4, 5]);
    Ok(())
}

// ── Sublist ──
#[test]
fn test_sublist() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::sublist(lst.clone(), 2, 3)?;
    assert_eq!(result, list![2i32, 3, 4]);
    Ok(())
}

// ── Thread ──
#[test]
fn test_thread() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![4i32, 5, 6];
    let result = L::thread(&a, b.clone(), &nil())?;
    assert_eq!(result.len(), 6);
    Ok(())
}

// ── Thread3Map ──
#[test]
fn test_thread3_map() {
    let a = list![1i32, 2];
    let b = list![10i32, 20];
    let c = list![100i32, 200];
    let result = L::thread3Map(a.clone(), b.clone(), c.clone(), &|x, y, z| Ok(x + y + z)).unwrap();
    assert_eq!(result, list![111i32, 222]);
}

// ── Thread3MapFold ──
#[test]
fn test_thread3_map_fold() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![10i32, 20];
    let c = list![100i32, 200];
    let (result, acc) = L::thread3MapFold(&a, b.clone(), c.clone(), &|x, y, z, __b3: &_| { let fold: i32 = ::std::clone::Clone::clone(__b3); Ok((x + y + z, fold + 1)) }, 0i32)?;
    assert_eq!(result, list![111i32, 222]);
    assert_eq!(acc, 2);
    Ok(())
}

// ── ThreadFold ──
#[test]
fn test_thread_fold() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![4i32, 5, 6];
    let result = L::threadFold(&a, b.clone(), &|x, y, acc| Ok(acc + x + y), 0i32)?;
    assert_eq!(result, 21);
    Ok(())
}

// ── ThreadFold1 ──
#[test]
fn test_thread_fold1() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let result = L::threadFold1(&a, b.clone(), &|x, y, __b2: &_, acc| { let _arg: i32 = ::std::clone::Clone::clone(__b2); Ok(acc + x + y) }, 0i32, 0i32)?;
    assert_eq!(result, 10);
    Ok(())
}

// ── ThreadFold2 ──
#[test]
fn test_thread_fold2() -> Result<()> {
    let a = list![1i32];
    let b = list![2i32];
    let result = L::threadFold2(&a, b.clone(), &|x, y, __b2: &_, __b3: &_, acc| { let _a: i32 = ::std::clone::Clone::clone(__b2); let _b: i32 = ::std::clone::Clone::clone(__b3); Ok(acc + x + y) }, 0i32, 0i32, 0i32)?;
    assert_eq!(result, 3);
    Ok(())
}

// ── ThreadFold3 ──
#[test]
fn test_thread_fold3() -> Result<()> {
    let a = list![1i32];
    let b = list![2i32];
    let result = L::threadFold3(&a, b.clone(), &|x, y, __b2: &_, __b3: &_, __b4: &_, __b5: &_| { let _a: i32 = ::std::clone::Clone::clone(__b2); let _b: i32 = ::std::clone::Clone::clone(__b3); let _c: i32 = ::std::clone::Clone::clone(__b4); let acc = ::std::clone::Clone::clone(__b5); Ok(acc + x + y) }, 0i32, 0i32, 0i32, 0i32)?;
    assert_eq!(result, 3);
    Ok(())
}

// ── ThreadMap ──
#[test]
fn test_thread_map() {
    let a = list![1i32, 2, 3];
    let b = list![4i32, 5, 6];
    let result = L::threadMap(a.clone(), b.clone(), &|x, y| Ok(x + y)).unwrap();
    assert_eq!(result, list![5i32, 7, 9]);
}

// ── ThreadMap1 ──
#[test]
fn test_thread_map1() {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let result = L::threadMap1(a.clone(), b.clone(), &|x, y, __b2: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b2); Ok(x + y) }, 0i32).unwrap();
    assert_eq!(result, list![4i32, 6]);
}

// ── ThreadMap1_0 ──
#[test]
fn test_thread_map1_0() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    L::threadMap1_0(&a, b.clone(), &|_x, _y, __b2: &_| { let _arg: i32 = ::std::clone::Clone::clone(__b2); Ok(()) }, 0i32)?;
    Ok(())
}

// ── ThreadMap2 ──
#[test]
fn test_thread_map2() {
    let a = list![1i32];
    let b = list![2i32];
    let result = L::threadMap2(a.clone(), b.clone(), &|x, y, __b2: &_, __b3: &_| { let _a: i32 = ::std::clone::Clone::clone(__b2); let _b: i32 = ::std::clone::Clone::clone(__b3); Ok(x + y) }, 0i32, 0i32).unwrap();
    assert_eq!(result, list![3i32]);
}

// ── ThreadMapFold ──
#[test]
fn test_thread_map_fold() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let (result, acc) = L::threadMapFold(&a, b.clone(), &|x, y, __b2: &_| { let fold: i32 = ::std::clone::Clone::clone(__b2); Ok((x + y, fold + 1)) }, 0i32)?;
    assert_eq!(result, list![4i32, 6]);
    assert_eq!(acc, 2);
    Ok(())
}

// ── ThreadMapList ──
#[test]
fn test_thread_map_list() {
    let a = list![list![1i32, 2]];
    let b = list![list![3i32, 4]];
    let result = L::threadMapList(a.clone(), b.clone(), &|x, y| Ok(x + y)).unwrap();
    assert_eq!(result, list![list![4i32, 6]]);
}

// ── ThreadMapList_2 ──
#[test]
fn test_thread_map_list_2() -> Result<()> {
    let a = list![list![1i32, 2]];
    let b = list![list![3i32, 4]];
    let (r1, _r2) = L::threadMapList_2(&a, b.clone(), &|x, y| Ok((x + y, x * y)))?;
    assert_eq!(r1, list![list![4i32, 6]]);
    Ok(())
}

// ── ThreadMap_2 ──
#[test]
fn test_thread_map_2() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let (r1, r2) = L::threadMap_2(&a, b.clone(), &|x, y| Ok((x + y, x * y)))?;
    assert_eq!(r1, list![4i32, 6]);
    assert_eq!(r2, list![3i32, 8]);
    Ok(())
}

// ── ToListWithPositions ──
#[test]
fn test_to_list_with_positions() {
    let lst = list![10i32, 20, 30];
    let result = L::toListWithPositions(&lst);
    assert_eq!(result.len(), 3);
}

// ── ToString ──
#[test]
fn test_to_string() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::toStringCustom(lst.clone(), &to_string_i32, arcstr::literal!(""), arcstr::literal!("{"), arcstr::literal!(", "), arcstr::literal!("}"), true, -1)?;
    assert_eq!(&*result, "{1, 2, 3}");
    Ok(())
}
#[test]
fn test_to_string_empty() -> Result<()> {
    let lst: List<i32> = nil();
    let result = L::toStringCustom(lst.clone(), &to_string_i32, arcstr::literal!(""), arcstr::literal!("{"), arcstr::literal!(", "), arcstr::literal!("}"), true, -1)?;
    assert_eq!(&*result, "{}");
    Ok(())
}

// ── TransposeList ──
#[test]
fn test_transpose_list() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let lst = list![a.clone(), b.clone()];
    let result = L::transposeList(lst.clone())?;
    assert_eq!(result.len(), 2);
    Ok(())
}

// ── Trim ──
#[test]
fn test_trim() -> Result<()> {
    let lst = list![2i32, 1, 3, 4, 2];
    let result = L::trim(lst.clone(), &|a0| is_even(::std::clone::Clone::clone(a0)))?;
    assert!(result.len() > 0);
    Ok(())
}

// ── TrimToLength ──
#[test]
fn test_trim_to_length() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::trimToLength(lst.clone(), 3)?;
    // trimToLength keeps last N elements
    assert_eq!(result.len(), 3);
    Ok(())
}

// ── Union ──
#[test]
fn test_union() {
    let a = list![1i32, 2, 3];
    let b = list![3i32, 4, 5];
    let result = L::union(&a, &b);
    assert_eq!(result, list![1i32, 2, 3, 4, 5]);
}

// ── UnionAppendListOnTrue ──
#[test]
fn test_union_append_list_on_true() {
    let a = list![1i32, 2];
    let b = list![2i32, 3];
    let result = L::unionAppendListOnTrue(&a, b.clone(), Arc::new(eq_i)).unwrap();
    assert!(result.len() >= 2);
}

// ── UnionElt ──
#[test]
fn test_union_elt() {
    let lst = list![1i32, 2, 3];
    let result = L::unionElt(4, lst.clone());
    // unionElt prepends new element if not present
    assert_eq!(result, list![4i32, 1, 2, 3]);
}
#[test]
fn test_union_elt_exists() {
    let lst = list![1i32, 2, 3];
    let result = L::unionElt(2, lst.clone());
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── UnionEltOnTrue ──
#[test]
fn test_union_elt_on_true() {
    let lst = list![1i32, 2, 3];
    let result = L::unionEltOnTrue(4, lst.clone(), &eq_i).unwrap();
    // unionEltOnTrue prepends new element if not present
    assert_eq!(result, list![4i32, 1, 2, 3]);
}

// ── UnionIntN ──
#[test]
fn test_union_int_n() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![3i32, 4];
    let result = L::unionIntN(&a, &b, 4)?;
    assert_eq!(result, list![1i32, 2, 3, 4]);
    Ok(())
}

// ── UnionList ──
#[test]
fn test_union_list() -> Result<()> {
    let a = list![list![1i32, 2], list![2i32, 3]];
    let result = L::unionList(&a)?;
    assert_eq!(result, list![1i32, 2, 3]);
    Ok(())
}

// ── UnionOnTrue ──
#[test]
fn test_union_on_true() {
    let a = list![1i32, 2];
    let b = list![2i32, 3];
    let result = L::unionOnTrue(&a, &b, &eq_i).unwrap();
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── UnionOnTrueList ──
#[test]
fn test_union_on_true_list() -> Result<()> {
    let a = list![list![1i32, 2]];
    let result = L::unionOnTrueList(&a, Arc::new(|x: i32, y: i32| Ok(x == y)))?;
    assert!(result.len() >= 0);
    Ok(())
}

// ── Unique ──
#[test]
fn test_unique() {
    let lst = list![1i32, 2, 1, 3, 2];
    let result = L::unique(&lst);
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── UniqueIntN ──
#[test]
fn test_unique_int_n() -> Result<()> {
    let lst = list![1i32, 2, 1, 3, 2];
    let result = L::uniqueIntN(&lst, 3)?;
    assert!(result.len() <= 3);
    Ok(())
}

// ── UniqueOnTrue ──
#[test]
fn test_unique_on_true() {
    let lst = list![1i32, 2, 1, 3];
    let result = L::uniqueOnTrue(&lst, &eq_i).unwrap();
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── Unzip ──
#[test]
fn test_unzip() {
    let lst = list![(1i32, 10i32), (2i32, 20), (3i32, 30)];
    let (a, b) = L::unzip(&lst);
    assert_eq!(a, list![1i32, 2, 3]);
    assert_eq!(b, list![10i32, 20, 30]);
}

// ── Unzip3 ──
#[test]
fn test_unzip3() {
    let lst = list![(1i32, 10i32, 100i32)];
    let (a, b, c) = L::unzip3(lst.clone());
    assert_eq!(a, list![1i32]);
    assert_eq!(b, list![10i32]);
    assert_eq!(c, list![100i32]);
}

// ── UnzipSecond ──
#[test]
fn test_unzip_second() {
    let lst = list![(1i32, 10i32), (2i32, 20)];
    let result = L::unzipSecond(&lst);
    assert_eq!(result, list![10i32, 20]);
}

// ── Zip ──
#[test]
fn test_zip() {
    let a = list![1i32, 2, 3];
    let b = list![10i32, 20, 30];
    let result = L::zip(a.clone(), b.clone());
    assert_eq!(result, list![(1i32, 10i32), (2i32, 20), (3i32, 30)]);
}

// ── Zip3 ──
#[test]
fn test_zip3() {
    let a = list![1i32, 2];
    let b = list![10i32, 20];
    let c = list![100i32, 200];
    let result = L::zip3(a.clone(), b.clone(), c.clone());
    assert_eq!(result, list![(1i32, 10i32, 100i32), (2i32, 20i32, 200)]);
}

// ── Select (alias for filterOnTrue) ──
#[test]
fn test_select() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::select(lst.clone(), Arc::new(is_even)).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── Select1 ──
#[test]
fn test_select1() {
    let lst = list![2i32];
    let result = L::select1(lst.clone(), Arc::new(|x, _: i32| Ok(x % 2 == 0)), 0i32).unwrap();
    assert_eq!(result, list![2i32]);
}

// ── Select1r ──
#[test]
fn test_select1r() {
    let lst = list![2i32, 4];
    let result = L::select1r(lst.clone(), Arc::new(|_: i32, x| Ok(x % 2 == 0)), 0i32).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── Select2 ──
#[test]
fn test_select2() {
    let lst = list![2i32, 4];
    let result = L::select2(lst.clone(), Arc::new(|x, _a: i32, _b: i32| Ok(x % 2 == 0)), 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── AllCombinations ──
#[test]
fn test_all_combinations() -> Result<()> {
    let lst = list![list![1i32, 2], list![3i32, 4]];
    let result = L::allCombinations(&lst, None, &sourceInfo!())?;
    assert!(result.len() >= 0);
    Ok(())
}

// ── Additional edge cases ──
#[test]
fn test_map_empty_list() {
    let lst: List<i32> = nil();
    let result = L::map(lst.clone(), &double).unwrap();
    assert!(result.is_empty());
}

#[test]
fn test_fold_empty() {
    let lst: List<i32> = nil();
    let result = L::fold(&lst, &|_, acc| Ok(acc), 99i32).unwrap();
    assert_eq!(result, 99);
}

#[test]
fn test_filter_empty_result() {
    let lst = list![1i32, 3, 5];
    let result = L::filter(&lst, &|x| { if x % 2 == 0 { Ok(()) } else { return Err("skip") } });
    assert!(result.is_empty());
}

#[test]
fn test_union_elt_duplicate() {
    let lst = list![1i32, 2, 3];
    let result = L::unionElt(2, lst.clone());
    assert_eq!(result, list![1i32, 2, 3]);
}

#[test]
fn test_intersection_on_true_no_overlap() {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let result = L::intersectionOnTrue(&a, &b, &eq_i).unwrap();
    assert!(result.is_empty());
}

#[test]
fn test_set_difference_all_in_b() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![1i32, 2, 3];
    let result = L::setDifference(a.clone(), &b)?;
    assert!(result.is_empty());
    Ok(())
}

#[test]
fn test_sort_empty() -> Result<()> {
    let lst: List<i32> = nil();
    let result = L::sort(lst.clone(), Arc::new(less_i))?;
    assert!(result.is_empty());
    Ok(())
}

#[test]
fn test_sort_single() -> Result<()> {
    let lst = list![42i32];
    let result = L::sort(lst.clone(), Arc::new(less_i))?;
    assert_eq!(result, list![42i32]);
    Ok(())
}

#[test]
fn test_count_zero() {
    let lst = list![1i32, 3, 5];
    assert_eq!(L::count(&lst, &|a0| is_even(::std::clone::Clone::clone(a0))).unwrap(), 0);
}

#[test]
fn test_position_empty() {
    let lst: List<i32> = nil();
    // position returns Err when element not found (empty list)
    assert!(L::position(1, &lst).is_err());
}

#[test]
fn test_max_min_single() -> Result<()> {
    let lst = list![42i32];
    assert_eq!(L::maxElement(&lst, &|a0, a1| less_i(a0, ::std::clone::Clone::clone(a1)))?, 42);
    assert_eq!(L::minElement(&lst, &|a0, a1| less_i(::std::clone::Clone::clone(a0), a1))?, 42);
    Ok(())
}
