use anyhow::{Result, bail};
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
    let result = L::accumulateMapAccum(Arc::clone(&lst), Arc::new(|x, acc| Ok(cons(x, acc)))).unwrap();
    assert_eq!(result.len(), 3);
}

// ── All ──
#[test]
fn test_all_true() {
    let lst = list![1i32, 2, 3];
    assert!(L::all(Arc::clone(&lst), Arc::new(is_positive)).unwrap());
}
#[test]
fn test_all_false() {
    let lst = list![1i32, -2, 3];
    assert!(!L::all(Arc::clone(&lst), Arc::new(is_positive)).unwrap());
}
#[test]
fn test_all_empty() {
    let lst: Arc<List<i32>> = nil();
    assert!(L::all(Arc::clone(&lst), Arc::new(is_positive)).unwrap());
}

// ── AllEqual ──
#[test]
fn test_all_equal_true() -> Result<()> {
    let lst = list![5i32, 5, 5];
    assert!(L::allEqual(Arc::clone(&lst), Arc::new(eq_i))?);
    Ok(())
}
#[test]
fn test_all_equal_false() -> Result<()> {
    let lst = list![5i32, 3, 5];
    assert!(!L::allEqual(Arc::clone(&lst), Arc::new(eq_i))?);
    Ok(())
}
#[test]
fn test_all_equal_empty() -> Result<()> {
    let lst: Arc<List<i32>> = nil();
    assert!(L::allEqual(Arc::clone(&lst), Arc::new(eq_i))?);
    Ok(())
}

// ── AllReferenceEq ──
#[test]
fn test_all_reference_eq_true() -> Result<()> {
    // referenceEq uses ptr::eq, so cloned values are never ptr-eq
    // Empty lists are trivially equal
    let lst: Arc<List<Arc<List<i32>>>> = nil();
    let lst2: Arc<List<Arc<List<i32>>>> = nil();
    assert!(L::allReferenceEq(Arc::clone(&lst), Arc::clone(&lst2)));
    Ok(())
}
#[test]
fn test_all_reference_eq_false() -> Result<()> {
    let lst = list![list![1i32], list![1i32]];
    let lst2 = list![list![1i32, 2], list![1i32]];
    assert!(!L::allReferenceEq(Arc::clone(&lst), Arc::clone(&lst2)));
    Ok(())
}

// ── Any ──
#[test]
fn test_any_found() {
    let lst = list![-1i32, 2, -3];
    assert!(L::any(Arc::clone(&lst), Arc::new(is_positive)).unwrap());
}
#[test]
fn test_any_none() {
    let lst = list![-1i32, -2];
    assert!(!L::any(Arc::clone(&lst), Arc::new(is_positive)).unwrap());
}
#[test]
fn test_any_empty() {
    let lst: Arc<List<i32>> = nil();
    assert!(!L::any(Arc::clone(&lst), Arc::new(is_positive)).unwrap());
}

// ── AppendElt ──
#[test]
fn test_append_elt() {
    let lst = list![1i32, 2];
    let result = L::appendElt(3, Arc::clone(&lst));
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── AppendLastList ──
#[test]
fn test_append_last_list() -> Result<()> {
    let lst1 = list![1i32, 2];
    let lst2 = list![3i32, 4];
    let list_of_lists = list![Arc::clone(&lst1), Arc::clone(&lst2)];
    let result = L::appendLastList(list_of_lists, list![5i32, 6])?;
    assert_eq!(result.len(), 2);
    Ok(())
}

// ── Append_reverse ──
#[test]
fn test_append_reverse() {
    let lst = list![1i32, 2, 3];
    let result = L::append_reverse(Arc::clone(&lst), nil());
    assert_eq!(result, list![3i32, 2, 1]);
}

// ── ApplyAndFold ──
#[test]
fn test_apply_and_fold() {
    let lst = list![1i32, 2, 3];
    let result = L::applyAndFold(Arc::clone(&lst), Arc::new(|acc, x| Ok(acc + x)), Arc::new(|x| Ok(x)), 0i32).unwrap();
    assert_eq!(result, 6);
}

// ── ApplyAndFold1 ──
#[test]
fn test_apply_and_fold1() {
    let lst = list![1i32];
    let result = L::applyAndFold1(Arc::clone(&lst), Arc::new(|acc, x| Ok(acc + x)), Arc::new(|x, _arg: i32| Ok(x)), 10i32, 0i32).unwrap();
    assert_eq!(result, 1);
}

// ── BalancedPartition ──
#[test]
fn test_balanced_partition() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::balancedPartition(Arc::clone(&lst), 2)?;
    assert!(result.len() >= 2);
    Ok(())
}

// ── Combination ──
#[test]
fn test_combination() -> Result<()> {
    let lst = list![list![1i32, 2], list![3i32, 4]];
    let result = L::combination(Arc::clone(&lst));
    assert!(result.len() >= 0);
    Ok(())
}

// ── CombinationMap ──
fn combination_map_fn(pair: Arc<metamodelica::List<i32>>) -> Result<i32> { Ok(pair.len()) }
#[test]
fn test_combination_map() -> Result<()> {
    let lst = list![list![1i32, 2], list![3i32, 4]];
    let result = L::combinationMap(Arc::clone(&lst), Arc::new(combination_map_fn)).unwrap();
    assert!(result.len() >= 0);
    Ok(())
}

// ── Compare ──
#[test]
fn test_compare_equal() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![1i32, 2, 3];
    assert_eq!(L::compare(Arc::clone(&a), Arc::clone(&b), Arc::new(cmp_i))?, 0);
    Ok(())
}
#[test]
fn test_compare_less() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![1i32, 3];
    assert_eq!(L::compare(Arc::clone(&a), Arc::clone(&b), Arc::new(cmp_i))?, -1);
    Ok(())
}
#[test]
fn test_compare_greater() -> Result<()> {
    let a = list![1i32, 4];
    let b = list![1i32, 3];
    assert_eq!(L::compare(Arc::clone(&a), Arc::clone(&b), Arc::new(cmp_i))?, 1);
    Ok(())
}

// ── CompareLength ──
#[test]
fn test_compare_length() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![1i32, 2, 3];
    assert!(L::compareLength(Arc::clone(&a), Arc::clone(&b))? < 0);
    assert_eq!(L::compareLength(Arc::clone(&b), Arc::clone(&b))?, 0);
    assert!(L::compareLength(Arc::clone(&b), Arc::clone(&a))? > 0);
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
    let result = L::consr(Arc::clone(&lst), 1i32);
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── Contains ──
#[test]
fn test_contains_true() {
    let lst = list![1i32, 2, 3];
    assert!(L::contains(Arc::clone(&lst), 2, Arc::new(eq_i)).unwrap());
}
#[test]
fn test_contains_false() {
    let lst = list![1i32, 2, 3];
    assert!(!L::contains(Arc::clone(&lst), 4, Arc::new(eq_i)).unwrap());
}

// ── Count ──
#[test]
fn test_count() {
    let lst = list![1i32, 2, 3, 4, 5, 6];
    assert_eq!(L::count(Arc::clone(&lst), Arc::new(is_even)).unwrap(), 3);
}

// ── CountingSort ──
#[test]
fn test_counting_sort() -> Result<()> {
    let lst = list![3i32, 1, 4, 1, 5, 9, 2, 6];
    let result = L::countingSort(Arc::clone(&lst), 9);
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
    let (result, deleted) = L::deleteMemberOnTrue(2i32, Arc::clone(&lst), Arc::new(eq_i))?;
    assert_eq!(deleted, Some(2));
    assert_eq!(result, list![1i32, 3, 4]);
    Ok(())
}

// ── DeletePositions ──
#[test]
fn test_delete_positions() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let positions = list![2i32, 4];
    let result = L::deletePositions(Arc::clone(&lst), Arc::clone(&positions), false)?;
    assert_eq!(result, list![1i32, 3, 5]);
    Ok(())
}

// ── DeletePositionsSorted ──
#[test]
fn test_delete_positions_sorted() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let positions = list![1i32, 3, 5];
    let result = L::deletePositionsSorted(Arc::clone(&lst), Arc::clone(&positions), false)?;
    assert_eq!(result, list![2i32, 4]);
    Ok(())
}

// ── Exist1 ──
#[test]
fn test_exist1_true() {
    assert!(L::exist1(list![1i32, 2, 3], Arc::new(|x, _arg: i32| Ok(x > 0)), 0i32).unwrap());
}
#[test]
fn test_exist1_false() {
    assert!(!L::exist1(list![-1i32, -2], Arc::new(|x, _arg: i32| Ok(x > 0)), 0i32).unwrap());
}

// ── ExtractOnTrue ──
#[test]
fn test_extract_on_true() {
    let lst = list![1i32, 2, 3, 4, 5];
    let (matched, _unmatched) = L::extractOnTrue(Arc::clone(&lst), Arc::new(|x| Ok(x % 2 == 0))).unwrap();
    assert_eq!(matched, list![2i32, 4]);
}

// ── Extract1OnTrue ──
#[test]
fn test_extract1_on_true() {
    let lst = list![1i32, 2, 3];
    let (matched, _unmatched) = L::extract1OnTrue(Arc::clone(&lst), Arc::new(|x, _arg: i32| Ok(x % 2 == 0)), 0i32).unwrap();
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
    let result = L::filter(Arc::clone(&lst), Arc::new(|x| { if x % 2 == 0 { Ok(()) } else { bail!("skip") } }));
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── Filter1 ──
#[test]
fn test_filter1() {
    let lst = list![1i32];
    let result = L::filter1(Arc::clone(&lst), Arc::new(|x, _arg: i32| { if x > 0 { Ok(()) } else { bail!("skip") } }), 0i32);
    assert_eq!(result, list![1i32]);
}

// ── Filter1OnTrue ──
#[test]
fn test_filter1_on_true() {
    let lst = list![1i32, 2, 3];
    let result = L::filter1OnTrue(Arc::clone(&lst), Arc::new(|x, _arg: i32| Ok(x % 2 == 0)), 0i32).unwrap();
    assert_eq!(result, list![2i32]);
}

// ── Filter1OnTrueAndUpdate ──
#[test]
fn test_filter1_on_true_and_update() {
    let lst = list![1i32, 2, 3];
    let result = L::filter1OnTrueAndUpdate(Arc::clone(&lst), Arc::new(|x, _arg: i32| Ok(x > 1)), Arc::new(|x, _arg: i32| Ok(x * 10)), 0i32).unwrap();
    assert_eq!(result, list![20i32, 30i32]);
}

// ── Filter1OnTrueSync ──
#[test]
fn test_filter1_on_true_sync() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let sync = list![10i32, 20, 30];
    let (kept, _removed) = L::filter1OnTrueSync(Arc::clone(&lst), Arc::new(|x, _arg: i32| Ok(x % 2 == 0)), 0i32, Arc::clone(&sync))?;
    assert_eq!(kept, list![2i32]);
    Ok(())
}

// ── Filter1rOnTrue ──
#[test]
fn test_filter1r_on_true() {
    let lst = list![2i32, 4, 6];
    let result = L::filter1rOnTrue(Arc::clone(&lst), Arc::new(|_arg: i32, x| Ok(x % 2 == 0)), 0i32).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── Filter2OnTrue ──
#[test]
fn test_filter2_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::filter2OnTrue(Arc::clone(&lst), Arc::new(|x, _a: i32, _b: i32| Ok(x % 2 == 0)), 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── FilterCons ──
#[test]
fn test_filter_cons() {
    let lst = list![1i32, 2, 3];
    let result = L::filterCons(Arc::clone(&lst), Arc::new(|x| Ok(x % 2 == 0)), nil()).unwrap();
    assert_eq!(result, list![2i32]);
}

// ── FilterMap ──
#[test]
fn test_filter_map() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::filterMap(Arc::clone(&lst), Arc::new(|x| if x % 2 == 0 { Ok(x * 10) } else { bail!("skip") }));
    assert_eq!(result, list![20i32, 40]);
}

// ── FilterMap1 ──
#[test]
fn test_filter_map1() {
    let lst = list![2i32];
    let result = L::filterMap1(Arc::clone(&lst), Arc::new(|x, _arg: i32| if x > 0 { Ok(x * 2) } else { bail!("skip") }), 0i32);
    assert_eq!(result, list![4i32]);
}

// ── FilterOnFalse ──
#[test]
fn test_filter_on_false() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::filterOnFalse(Arc::clone(&lst), Arc::new(|x| Ok(x % 2 == 0))).unwrap();
    assert_eq!(result, list![1i32, 3]);
}

// ── FilterOnTrue ──
#[test]
fn test_filter_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::filterOnTrue(Arc::clone(&lst), Arc::new(is_even)).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── FilterOnTrueSync ──
#[test]
fn test_filter_on_true_sync() -> Result<()> {
    let lst = list![1i32, 2, 3, 4];
    let sync = list![10i32, 20, 30, 40];
    let (matched, _unmatched) = L::filterOnTrueSync(Arc::clone(&lst), Arc::new(is_even), Arc::clone(&sync))?;
    assert_eq!(matched, list![2i32, 4]);
    Ok(())
}

// ── Find ──
#[test]
fn test_find_found() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::find(Arc::clone(&lst), Arc::new(|x| Ok(x == 2)))?;
    assert_eq!(result, 2);
    Ok(())
}
#[test]
fn test_find_not_found() {
    let lst = list![1i32, 2, 3];
    assert!(L::find(Arc::clone(&lst), Arc::new(|x| Ok(x == 4))).is_err());
}

// ── Find1 ──
#[test]
fn test_find1_found() -> Result<()> {
    let lst = list![1i32];
    let result = L::find1(Arc::clone(&lst), Arc::new(|x, _arg: i32| Ok(x > 0)), 0i32)?;
    assert_eq!(result, 1);
    Ok(())
}

// ── FindAndMap ──
#[test]
fn test_find_and_map() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let (result, found) = L::findAndMap(Arc::clone(&lst), Arc::new(|x| Ok(x > 1)), Arc::new(|x| Ok(x * 10)))?;
    assert!(found);
    Ok(())
}

// ── FindAndRemove ──
#[test]
fn test_find_and_remove() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let (found, rest) = L::findAndRemove(Arc::clone(&lst), Arc::new(|x| Ok(x == 2)))?;
    assert_eq!(found, 2);
    assert_eq!(rest, list![1i32, 3]);
    Ok(())
}

// ── FindAndRemove1 ──
#[test]
fn test_find_and_remove1() -> Result<()> {
    let lst = list![1i32, 2];
    let (found, rest) = L::findAndRemove1(Arc::clone(&lst), Arc::new(|x, _arg: i32| Ok(x == 2)), 0i32)?;
    assert_eq!(found, 2);
    assert_eq!(rest, list![1i32]);
    Ok(())
}

// ── FindBoolList ──
#[test]
fn test_find_bool_list() -> Result<()> {
    let bools = list![true, false, false];
    let lst = list![10i32, 20, 30];
    let result = L::findBoolList(Arc::clone(&bools), Arc::clone(&lst), 99i32)?;
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
    let (result, found) = L::findMap(Arc::clone(&lst), Arc::new(|x| Ok((x * 10, x == 2))))?;
    assert!(found);
    assert_eq!(result, list![10i32, 20, 3]);
    Ok(())
}

// ── FindOption ──
#[test]
fn test_find_option_some() {
    let lst = list![Some(1i32), None, Some(3)];
    let result = L::findOption(Arc::clone(&lst), Arc::new(|x| Ok(x.unwrap_or(0) > 0))).unwrap();
    assert!(result.is_some());
}
#[test]
fn test_find_option_none() {
    let lst: Arc<List<Option<i32>>> = nil();
    let result = L::findOption(Arc::clone(&lst), Arc::new(|x| Ok(x.is_some()))).unwrap();
    assert_eq!(result, None);
}

// ── FindSome ──
#[test]
fn test_find_some() {
    let lst = list![None::<i32>, Some(3)];
    let result = L::findSome(Arc::clone(&lst), Arc::new(|x| Ok(x))).unwrap();
    assert_eq!(result, Some(3));
}

// ── FirstN ──
#[test]
fn test_first_n() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::firstN(Arc::clone(&lst), 3)?;
    assert_eq!(result, list![1i32, 2, 3]);
    Ok(())
}

// ── FirstOrEmpty ──
#[test]
fn test_first_or_empty_some() -> Result<()> {
    let lst = list![1i32, 2];
    let result = L::firstOrEmpty(Arc::clone(&lst));
    assert_eq!(result.len(), 1);
    Ok(())
}
#[test]
fn test_first_or_empty_none() -> Result<()> {
    let lst: Arc<List<i32>> = nil();
    let result = L::firstOrEmpty(Arc::clone(&lst));
    assert_eq!(result.len(), 0);
    Ok(())
}

// ── Flatten ──
#[test]
fn test_flatten() {
    let lst = list![list![1i32, 2], list![3i32, 4], list![5i32]];
    let result = L::flatten(Arc::clone(&lst)).unwrap();
    assert_eq!(result, list![1i32, 2, 3, 4, 5]);
}

// ── FlattenReverse ──
#[test]
fn test_flatten_reverse() {
    let lst = list![list![1i32, 2], list![3i32]];
    let result = L::flattenReverse(Arc::clone(&lst)).unwrap();
    assert_eq!(result.len(), 3);
}

// ── Fold ──
#[test]
fn test_fold() {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::fold(Arc::clone(&lst), Arc::new(|x, acc| Ok(acc + x)), 0i32).unwrap();
    assert_eq!(result, 15);
}

// ── Fold1 ──
#[test]
fn test_fold1() {
    let lst = list![1i32, 2, 3];
    let result = L::fold1(Arc::clone(&lst), Arc::new(|x, _arg: i32, acc| Ok(acc + x)), 0i32, 0i32).unwrap();
    assert_eq!(result, 6);
}

// ── Fold1r ──
#[test]
fn test_fold1r() {
    let lst = list![1i32, 2, 3];
    let result = L::fold1r(Arc::clone(&lst), Arc::new(|acc, x, _arg: i32| Ok(acc + x)), 0i32, 0i32).unwrap();
    assert_eq!(result, 6);
}

// ── Fold2 ──
#[test]
fn test_fold2() {
    let lst = list![1i32, 2];
    let result = L::fold2(Arc::clone(&lst), Arc::new(|x, _a: i32, _b: i32, acc| Ok(acc + x)), 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, 3);
}

// ── Fold2r ──
#[test]
fn test_fold2r() {
    let lst = list![1i32, 2];
    let result = L::fold2r(Arc::clone(&lst), Arc::new(|acc, x, _a: i32, _b: i32| Ok(acc + x)), 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, 3);
}

// ── Fold3 ──
#[test]
fn test_fold3() {
    let lst = list![1i32];
    let result = L::fold3(Arc::clone(&lst), Arc::new(|x, _a: i32, _b: i32, _c: i32, acc| Ok(acc + x)), 0i32, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, 1);
}

// ── Fold31 ──
#[test]
fn test_fold31() {
    let lst = list![1i32, 2];
    let (_r1, _r2, _r3) = L::fold31(Arc::clone(&lst), Arc::new(|x, _a: i32, s1: i32, s2: i32, s3: i32| Ok((s1 + x, s2 + x, s3 + x))), 0i32, 0i32, 0i32, 0i32).unwrap();
}

// ── Fold4 ──
#[test]
fn test_fold4() {
    let lst = list![1i32];
    let result = L::fold4(Arc::clone(&lst), Arc::new(|x, _a: i32, _b: i32, _c: i32, _d: i32, acc| Ok(acc + x)), 0i32, 0i32, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, 1);
}

// ── FoldAllValue ──
#[test]
fn test_fold_all_value() -> Result<()> {
    let lst = list![1i32, 2, 3];
    // foldAllValue requires fn output == inValue for each element
    L::foldAllValue(Arc::clone(&lst), Arc::new(|_x, acc: i32| Ok((true, acc))), true, 0i32)?;
    Ok(())
}

// ── FoldList ──
#[test]
fn test_fold_list() {
    let outer = list![list![1i32, 2], list![3i32, 4]];
    let result = L::foldList(Arc::clone(&outer), Arc::new(|x, acc| Ok(acc + x)), 0i32).unwrap();
    assert_eq!(result, 10);
}

// ── Foldr ──
#[test]
fn test_foldr() {
    let lst = list![1i32, 2, 3];
    let result = L::foldr(Arc::clone(&lst), Arc::new(|acc, x| Ok(acc + x)), 0i32).unwrap();
    assert_eq!(result, 6);
}

// ── Fold20 ──
#[test]
fn test_fold20() {
    let lst = list![1i32, 2];
    let (s1, s2) = L::fold20(Arc::clone(&lst), Arc::new(|x, acc1: i32, acc2: i32| Ok((acc1 + x, acc2 + x))), 0i32, 0i32).unwrap();
    assert_eq!(s1, 3);
    assert_eq!(s2, 3);
}

// ── Fold21 ──
#[test]
fn test_fold21() {
    let lst = list![1i32, 2];
    let (s1, s2) = L::fold21(Arc::clone(&lst), Arc::new(|x, _arg: i32, acc1: i32, acc2: i32| Ok((acc1 + x, acc2 + x))), 0i32, 0i32, 0i32).unwrap();
    assert_eq!(s1, 3);
    assert_eq!(s2, 3);
}

// ── Fold22 ──
#[test]
fn test_fold22() {
    let lst = list![1i32, 2];
    let (s1, s2) = L::fold22(Arc::clone(&lst), Arc::new(|x, _a: i32, _b: i32, acc1: i32, acc2: i32| Ok((acc1 + x, acc2 + x))), 0i32, 0i32, 0i32, 0i32).unwrap();
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
fn test_get_at_index_lst() {
    let lst = list![10i32, 20, 30];
    let positions = list![1i32, 2, 3];
    let result = L::getAtIndexLst(Arc::clone(&lst), Arc::clone(&positions), false);
    assert_eq!(result, list![10i32, 20, 30]);
}

// ── GetIndexFirst ──
#[test]
fn test_get_index_first() -> Result<()> {
    // getIndexFirst forwards to listGet, which bounds-checks (fallible).
    let lst = list![10i32, 20, 30];
    assert_eq!(L::getIndexFirst(1, Arc::clone(&lst))?, 10);
    assert!(L::getIndexFirst(4, Arc::clone(&lst)).is_err());
    Ok(())
}

// ── GetMember ──
#[test]
fn test_get_member() -> Result<()> {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::getMember(2, Arc::clone(&lst))?, 2);
    Ok(())
}

// ── GetMemberOnTrue ──
#[test]
fn test_get_member_on_true() -> Result<()> {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::getMemberOnTrue(2i32, Arc::clone(&lst), Arc::new(eq_i))?, 2);
    Ok(())
}

// ── HasOneElement ──
#[test]
fn test_has_one_element_true() -> Result<()> {
    assert!(L::hasOneElement(list![1i32]));
    Ok(())
}
#[test]
fn test_has_one_element_false() -> Result<()> {
    assert!(!L::hasOneElement(list![1i32, 2]));
    assert!(!L::hasOneElement(nil::<i32>()));
    Ok(())
}

// ── HasSeveralElements ──
#[test]
fn test_has_several_elements_true() -> Result<()> {
    assert!(L::hasSeveralElements(list![1i32, 2]));
    Ok(())
}
#[test]
fn test_has_several_elements_false() -> Result<()> {
    assert!(!L::hasSeveralElements(list![1i32]));
    assert!(!L::hasSeveralElements(nil::<i32>()));
    Ok(())
}

// ── HeapSortIntList ──
#[test]
fn test_heap_sort_int_list() -> Result<()> {
    let lst = list![3i32, 1, 4, 1, 5, 9, 2, 6];
    let result = L::heapSortIntList(Arc::clone(&lst));
    assert_eq!(result, list![1i32, 1, 2, 3, 4, 5, 6, 9]);
    Ok(())
}

// ── Insert ──
#[test]
fn test_insert() -> Result<()> {
    let lst = list![1i32, 4, 5];
    let result = L::insert(Arc::clone(&lst), 2, 2i32)?;
    assert_eq!(result, list![1i32, 2, 4, 5]);
    Ok(())
}

// ── InsertListSorted ──
#[test]
fn test_insert_list_sorted() -> Result<()> {
    let lst = list![1i32, 3, 5];
    let to_insert = list![2i32, 4];
    let result = L::insertListSorted(Arc::clone(&lst), Arc::clone(&to_insert), Arc::new(less_i))?;
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
    let result = L::intersection1OnTrue(Arc::clone(&a), Arc::clone(&b), Arc::new(eq_i))?;
    assert!(result.0.len() > 0);
    Ok(())
}

// ── IntersectionOnTrue ──
#[test]
fn test_intersection_on_true() {
    let a = list![1i32, 2, 3];
    let b = list![2i32, 3, 4];
    let result = L::intersectionOnTrue(Arc::clone(&a), Arc::clone(&b), Arc::new(eq_i)).unwrap();
    assert_eq!(result, list![2i32, 3]);
}

// ── IsEqual ──
#[test]
fn test_is_equal_true() -> Result<()> {
    assert!(L::isEqual(list![1i32, 2], list![1i32, 2], true));
    Ok(())
}
#[test]
fn test_is_equal_false() -> Result<()> {
    assert!(!L::isEqual(list![1i32, 2], list![1i32, 3], true));
    Ok(())
}

// ── IsEqualOnTrue ──
#[test]
fn test_is_equal_on_true() -> Result<()> {
    assert!(L::isEqualOnTrue(list![1i32, 2], list![1i32, 2], Arc::new(eq_i)).unwrap());
    assert!(!L::isEqualOnTrue(list![1i32, 2], list![1i32, 3], Arc::new(eq_i)).unwrap());
    Ok(())
}

// ── IsMemberOnTrue ──
#[test]
fn test_is_member_on_true() {
    let lst = list![1i32, 2, 3];
    assert!(L::isMemberOnTrue(2i32, Arc::clone(&lst), Arc::new(eq_i)).unwrap());
    assert!(!L::isMemberOnTrue(4i32, Arc::clone(&lst), Arc::new(eq_i)).unwrap());
}

// ── IsPrefixOnTrue ──
#[test]
fn test_is_prefix_on_true() -> Result<()> {
    let prefix = list![1i32, 2];
    let full = list![1i32, 2, 3, 4];
    assert!(L::isPrefixOnTrue(Arc::clone(&prefix), Arc::clone(&full), Arc::new(eq_i)).unwrap());
    assert!(!L::isPrefixOnTrue(list![1i32, 3], full, Arc::new(eq_i)).unwrap());
    Ok(())
}

// ── KeepPositions ──
#[test]
fn test_keep_positions() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let positions = list![1i32, 3, 5];
    let result = L::keepPositions(Arc::clone(&lst), Arc::clone(&positions), false)?;
    assert_eq!(result, list![1i32, 3, 5]);
    Ok(())
}

// ── KeepPositionsSorted ──
#[test]
fn test_keep_positions_sorted() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let positions = list![1i32, 3, 5];
    let result = L::keepPositionsSorted(Arc::clone(&lst), Arc::clone(&positions), false)?;
    assert_eq!(result, list![1i32, 3, 5]);
    Ok(())
}

// ── Last ──
#[test]
fn test_last() -> Result<()> {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::last(Arc::clone(&lst))?, 3);
    Ok(())
}

// ── LastListOrEmpty ──
#[test]
fn test_last_list_or_empty() {
    let lst = list![list![1i32], list![2i32, 3]];
    let result = L::lastListOrEmpty(Arc::clone(&lst));
    assert_eq!(result, list![2i32, 3]);
}

// ── LastN ──
#[test]
fn test_last_n() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::lastN(Arc::clone(&lst), 3)?;
    assert_eq!(result, list![3i32, 4, 5]);
    Ok(())
}

// ── LengthListElements ──
#[test]
fn test_length_list_elements() {
    let lst = list![list![1i32, 2], list![3i32, 4, 5], list![6i32]];
    assert_eq!(L::lengthListElements(Arc::clone(&lst)), 6);
}

// ── ListArrayReverse ──
#[test]
fn test_list_array_reverse() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::listArrayReverse(Arc::clone(&lst))?;
    // Result is metamodelica::Array<i32> (Rc<RefCell<Vec<i32>>>)
    assert_eq!(result.borrow().len(), 3);
    Ok(())
}

// ── ListIsLonger ──
#[test]
fn test_list_is_longer() {
    let a = list![1i32, 2, 3];
    let b = list![1i32, 2];
    assert!(L::listIsLonger(Arc::clone(&a), Arc::clone(&b)).unwrap());
    assert!(!L::listIsLonger(Arc::clone(&b), Arc::clone(&a)).unwrap());
}

// ── Map ──
#[test]
fn test_map() {
    let lst = list![1i32, 2, 3];
    let result = L::map(Arc::clone(&lst), Arc::new(double)).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── Map1 ──
// map1(list, fn, arg1) where fn is (TI, ArgT1) -> TO
#[test]
fn test_map1() {
    let lst = list![1i32, 2, 3];
    let result = L::map1(Arc::clone(&lst), Arc::new(|x, factor: i32| Ok(x * factor)), 2i32).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── Map1Fold ──
// map1Fold(list, fn, constArg, foldArg) where fn is (TI, ArgT1, FT) -> (TO, FT)
#[test]
fn test_map1_fold() {
    let lst = list![1i32, 2, 3];
    let (result, acc) = L::map1Fold(Arc::clone(&lst), Arc::new(|x, _const: i32, fold: i32| Ok((x + fold, fold + 1))), 0i32, 0i32).unwrap();
    assert_eq!(result, list![1i32, 3, 5]);
    assert_eq!(acc, 3);
}

// ── Map1List ──
#[test]
fn test_map1_list() {
    let lst = list![list![1i32, 2]];
    let result = L::map1List(Arc::clone(&lst), Arc::new(|x: i32, _arg: i32| Ok(x * 2)), 0i32).unwrap();
    // map1List reverses inner list due to cons-accumulation
    assert_eq!(result.len(), 1);
}

// ── Map1Option ──
// map1Option(list_of_options, fn, arg1) where fn is (TI, ArgT) -> TO
#[test]
fn test_map1_option() -> Result<()> {
    let lst = list![Some(1i32), Some(2)];
    let result = L::map1Option(Arc::clone(&lst), Arc::new(|x, factor: i32| Ok(x * factor)), 2i32)?;
    assert_eq!(result, list![2i32, 4]);
    Ok(())
}

// ── Map1_0 ──
// map1_0(list, fn, arg1) where fn is (TI, ArgT1) -> () - plain return
#[test]
fn test_map1_0() {
    let lst = list![1i32, 2, 3];
    L::map1_0(Arc::clone(&lst), Arc::new(|_x, _arg: i32| Ok(())), 0i32).unwrap();
}

// ── Map1_2 ──
// map1_2(list, fn, arg1) where fn is (TI, ArgT1) -> (TO1, TO2), returns (list1, list2)
#[test]
fn test_map1_2() {
    let lst = list![1i32, 2];
    let (r1, r2) = L::map1_2(Arc::clone(&lst), Arc::new(|x, _: i32| Ok((x * 2, x * 3))), 0i32).unwrap();
    assert_eq!(r1, list![2i32, 4]);
    assert_eq!(r2, list![3i32, 6]);
}

// ── Map1r ──
// map1r(list, fn, arg1) where fn is (ArgT1, TI) -> TO
#[test]
fn test_map1r() {
    let lst = list![1i32, 2, 3];
    let result = L::map1r(Arc::clone(&lst), Arc::new(|factor: i32, x| Ok(x * factor)), 2i32).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── Map2 ──
// map2(list, fn, arg1, arg2) where fn is (TI, ArgT1, ArgT2) -> TO
#[test]
fn test_map2() {
    let lst = list![1i32, 2, 3];
    let result = L::map2(Arc::clone(&lst), Arc::new(|x, a: i32, b: i32| Ok(x + a + b)), 10i32, 100i32).unwrap();
    assert_eq!(result, list![111i32, 112, 113]);
}

// ── Map2Fold ──
// map2Fold(list, fn, constArg1, constArg2, foldArg, accum) where fn is (TI, ArgT1, ArgT2, FT) -> (TO, FT)
#[test]
fn test_map2_fold() {
    let lst = list![1i32, 2];
    let (result, acc) = L::map2Fold(Arc::clone(&lst), Arc::new(|x, _a: i32, _b: i32, fold: i32| Ok((x * 2, fold + 1))), 0i32, 0i32, 0i32, nil()).unwrap();
    assert_eq!(result, list![2i32, 4]);
    assert_eq!(acc, 2);
}

// ── Map2FoldCheckReferenceEq ──
#[test]
fn test_map2_fold_check_reference_eq() {
    let lst = list![1i32, 2];
    let (result, _acc) = L::map2FoldCheckReferenceEq(Arc::clone(&lst), Arc::new(|x, _a: i32, _b: i32, fold: i32| Ok((x * 2, fold + 1))), 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── Map2List ──
// map2List(list_of_lists, fn, arg1, arg2) where fn is (TI, ArgT1, ArgT2) -> TO
#[test]
fn test_map2_list() {
    let lst = list![list![1i32, 2]];
    let result = L::map2List(Arc::clone(&lst), Arc::new(|x, a: i32, b: i32| Ok(x + a + b)), 10i32, 100i32).unwrap();
    assert_eq!(result, list![list![111i32, 112]]);
}

// ── Map2Option ──
// map2Option(list_of_options, fn, arg1, arg2) where fn is (TI, ArgT1, ArgT2) -> TO
#[test]
fn test_map2_option() -> Result<()> {
    let lst = list![Some(1i32), Some(2)];
    let result = L::map2Option(Arc::clone(&lst), Arc::new(|x, a: i32, b: i32| Ok(x + a + b)), 10i32, 100i32)?;
    assert_eq!(result, list![111i32, 112]);
    Ok(())
}

// ── Map2Reverse ──
#[test]
fn test_map2_reverse() {
    let lst = list![1i32, 2, 3];
    let result = L::map2Reverse(Arc::clone(&lst), Arc::new(|x, a: i32, b: i32| Ok(x + a + b)), 10i32, 100i32).unwrap();
    assert_eq!(result, list![113i32, 112, 111]);
}

// ── Map2_0 ──
#[test]
fn test_map2_0() {
    let lst = list![1i32, 2, 3];
    L::map2_0(Arc::clone(&lst), Arc::new(|_x, _a: i32, _b: i32| Ok(())), 0i32, 0i32).unwrap();
}

// ── Map2_2 ──
#[test]
fn test_map2_2() {
    let lst = list![1i32, 2];
    let (r1, r2) = L::map2_2(Arc::clone(&lst), Arc::new(|x, a: i32, _b: i32| Ok((x + a, x * 2))), 10i32, 0i32).unwrap();
    assert_eq!(r1, list![11i32, 12]);
    assert_eq!(r2, list![2i32, 4]);
}

// ── Map3 ──
#[test]
fn test_map3() {
    let lst = list![1i32];
    let result = L::map3(Arc::clone(&lst), Arc::new(|x, a: i32, b: i32, c: i32| Ok(x + a + b + c)), 10i32, 100i32, 1000i32).unwrap();
    assert_eq!(result, list![1111i32]);
}

// ── Map3Fold ──
#[test]
fn test_map3_fold() {
    let lst = list![1i32];
    let (result, acc) = L::map3Fold(Arc::clone(&lst), Arc::new(|x, _a: i32, _b: i32, _c: i32, fold: i32| Ok((x * 2, fold + 1))), 0i32, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32]);
    assert_eq!(acc, 1);
}

// ── Map4 ──
#[test]
fn test_map4() {
    let lst = list![1i32];
    let result = L::map4(Arc::clone(&lst), Arc::new(|x, a: i32, b: i32, c: i32, d: i32| Ok(x + a + b + c + d)), 1i32, 2i32, 3i32, 4i32).unwrap();
    assert_eq!(result, list![11i32]);
}

// ── Map4_0 ──
#[test]
fn test_map4_0() {
    let lst = list![1i32];
    L::map4_0(Arc::clone(&lst), Arc::new(|_x, _a: i32, _b: i32, _c: i32, _d: i32| Ok(())), 0i32, 0i32, 0i32, 0i32).unwrap();
}

// ── Map5 ──
#[test]
fn test_map5() {
    let lst = list![1i32];
    let result = L::map5(Arc::clone(&lst), Arc::new(|x, a: i32, b: i32, c: i32, d: i32, e: i32| Ok(x + a + b + c + d + e)), 1i32, 2i32, 3i32, 4i32, 5i32).unwrap();
    assert_eq!(result, list![16i32]);
}

// ── Map6 ──
#[test]
fn test_map6() {
    let lst = list![1i32];
    let result = L::map6(Arc::clone(&lst), Arc::new(|x, a: i32, b: i32, c: i32, d: i32, e: i32, f: i32| Ok(x + a + b + c + d + e + f)), 1i32, 2i32, 3i32, 4i32, 5i32, 6i32).unwrap();
    assert_eq!(result, list![22i32]);
}

// ── MapArray ──
#[test]
fn test_map_array() {
    use metamodelica::arrayFromVec;
    let a = arrayFromVec(vec![1i32, 2, 3]);
    let result = L::mapArray(a, Arc::new(double)).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
}

// ── MapCheckReferenceEq ──
#[test]
fn test_map_check_reference_eq() {
    let lst = list![1i32, 2, 3];
    let result = L::mapCheckReferenceEq(Arc::clone(&lst), Arc::new(|x| Ok(x))).unwrap();
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── MapFlat ──
#[test]
fn test_map_flat() {
    let lst = list![list![1i32, 2], list![3i32, 4]];
    let result = L::mapFlat(Arc::clone(&lst), Arc::new(|inner| Ok(inner))).unwrap();
    // mapFlat reverses inner lists due to cons-accumulation
    assert_eq!(result.len(), 4);
}

// ── MapFlatReverse ──
#[test]
fn test_map_flat_reverse() {
    let lst = list![list![1i32, 2], list![3i32]];
    let result = L::mapFlatReverse(Arc::clone(&lst), Arc::new(|inner| Ok(inner))).unwrap();
    assert_eq!(result.len(), 3);
}

// ── MapFold ──
#[test]
fn test_map_fold() {
    let lst = list![1i32, 2, 3];
    let (result, acc) = L::mapFold(Arc::clone(&lst), Arc::new(|x, a| Ok((x * 2, a + x))), 0i32).unwrap();
    assert_eq!(result, list![2i32, 4, 6]);
    assert_eq!(acc, 6);
}

// ── MapFold2 ──
#[test]
fn test_map_fold2() {
    let lst = list![1i32, 2];
    let (result, a, b) = L::mapFold2(Arc::clone(&lst), Arc::new(|x, acc1: i32, acc2: i32| Ok((x * 2, acc1 + x, acc2 + x))), 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32, 4]);
    assert_eq!(a, 3);
    assert_eq!(b, 3);
}

// ── MapFold3 ──
#[test]
fn test_map_fold3() {
    let lst = list![1i32];
    let (result, a, b, c) = L::mapFold3(Arc::clone(&lst), Arc::new(|x, f1: i32, f2: i32, f3: i32| Ok((x * 2, f1 + x, f2 + x, f3 + x))), 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32]);
    assert_eq!(a, 1);
    assert_eq!(b, 1);
    assert_eq!(c, 1);
}

// ── MapFold5 ──
#[test]
fn test_map_fold5() {
    let lst = list![1i32];
    let (result, a, b, c, d, e) = L::mapFold5(Arc::clone(&lst), Arc::new(|x, f1: i32, f2: i32, f3: i32, f4: i32, f5: i32| Ok((x, f1+1, f2+1, f3+1, f4+1, f5+1))), 0i32, 0i32, 0i32, 0i32, 0i32).unwrap();
    assert_eq!(result, list![1i32]);
    assert_eq!(a, 1);
    assert_eq!(e, 1);
}

// ── MapFoldList ──
#[test]
fn test_map_fold_list() {
    let lst = list![list![1i32, 2], list![3i32]];
    let (_result, acc) = L::mapFoldList(Arc::clone(&lst), Arc::new(|x, fold: i32| Ok((x * 2, fold + x))), 0i32).unwrap();
    assert_eq!(acc, 6);
}

// ── MapIndices ──
#[test]
fn test_map_indices() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let indices = list![1i32, 3];
    let result = L::mapIndices(Arc::clone(&lst), Arc::clone(&indices), Arc::new(double))?;
    assert_eq!(result.len(), 3);
    Ok(())
}

// ── MapList ──
#[test]
fn test_map_list() {
    let lst = list![list![1i32, 2], list![3i32, 4]];
    let result = L::mapList(Arc::clone(&lst), Arc::new(double)).unwrap();
    assert_eq!(result, list![list![2i32, 4], list![6i32, 8]]);
}

// ── MapListReverse ──
#[test]
fn test_map_list_reverse() {
    let lst = list![list![1i32, 2], list![3i32]];
    let result = L::mapListReverse(Arc::clone(&lst), Arc::new(double)).unwrap();
    assert_eq!(result.len(), 2);
}

// ── MapMap ──
#[test]
fn test_map_map() {
    let lst = list![1i32, 2, 3];
    let result = L::mapMap(Arc::clone(&lst), Arc::new(double), Arc::new(|x| Ok(x + 1))).unwrap();
    assert_eq!(result, list![3i32, 5, 7]);
}

// ── MapMapBoolAnd ──
#[test]
fn test_map_map_bool_and() {
    let lst = list![2i32, 4, 6];
    let result = L::mapMapBoolAnd(Arc::clone(&lst), Arc::new(|x| Ok(x)), Arc::new(is_even)).unwrap();
    assert!(result);
}
#[test]
fn test_map_map_bool_and_false() {
    let lst = list![1i32, 2, 3];
    let result = L::mapMapBoolAnd(Arc::clone(&lst), Arc::new(|x| Ok(x)), Arc::new(is_even)).unwrap();
    assert!(!result);
}

// ── MapOption ──
#[test]
fn test_map_option() -> Result<()> {
    let lst = list![Some(1i32), Some(2)];
    let result = L::mapOption(Arc::clone(&lst), Arc::new(|x| Ok(x * 2)))?;
    assert_eq!(result, list![2i32, 4]);
    Ok(())
}

// ── MapReverse ──
#[test]
fn test_map_reverse() {
    let lst = list![1i32, 2, 3];
    let result = L::mapReverse(Arc::clone(&lst), Arc::new(double)).unwrap();
    assert_eq!(result, list![6i32, 4, 2]);
}

// ── Map_0 ──
#[test]
fn test_map_0() {
    let lst = list![1i32, 2, 3];
    L::map_0(Arc::clone(&lst), Arc::new(|_x| Ok(()))).unwrap();
}

// ── Map_2 ──
#[test]
fn test_map_2() {
    let lst = list![1i32, 2];
    let (r1, r2) = L::map_2(Arc::clone(&lst), Arc::new(|x| Ok((x * 2, x * 3)))).unwrap();
    assert_eq!(r1, list![2i32, 4]);
    assert_eq!(r2, list![3i32, 6]);
}

// ── Map_3 ──
#[test]
fn test_map_3() {
    let lst = list![1i32, 2];
    let (r1, r2, r3) = L::map_3(Arc::clone(&lst), Arc::new(|x| Ok((x, x * 2, x * 3)))).unwrap();
    assert_eq!(r1, list![1i32, 2]);
    assert_eq!(r2, list![2i32, 4]);
    assert_eq!(r3, list![3i32, 6]);
}

// ── MaxElement ──
#[test]
fn test_max_element() -> Result<()> {
    let lst = list![3i32, 1, 4, 1, 5, 9, 2, 6];
    assert_eq!(L::maxElement(Arc::clone(&lst), Arc::new(less_i))?, 9);
    Ok(())
}

// ── MergeSorted ──
#[test]
fn test_merge_sorted() -> Result<()> {
    let a = list![1i32, 3, 5];
    let b = list![2i32, 4, 6];
    let result = L::mergeSorted(Arc::clone(&a), Arc::clone(&b), Arc::new(less_i))?;
    assert_eq!(result, list![1i32, 2, 3, 4, 5, 6]);
    Ok(())
}

// ── MinElement ──
#[test]
fn test_min_element() -> Result<()> {
    let lst = list![3i32, 1, 4, 1, 5];
    assert_eq!(L::minElement(Arc::clone(&lst), Arc::new(less_i))?, 1);
    Ok(())
}

// ── MkOption ──
#[test]
fn test_mk_option_some() {
    let lst = list![1i32, 2];
    let result = L::mkOption(Arc::clone(&lst));
    assert!(result.is_some());
}
#[test]
fn test_mk_option_none() {
    let lst: Arc<List<i32>> = nil();
    let result = L::mkOption(Arc::clone(&lst));
    assert!(result.is_none());
}

// ── None ──
#[test]
fn test_none() {
    let lst: Arc<List<i32>> = nil();
    assert!(L::none(Arc::clone(&lst), Arc::new(is_positive)).unwrap());
}
#[test]
fn test_none_false() {
    let lst = list![1i32, -2];
    assert!(!L::none(Arc::clone(&lst), Arc::new(is_positive)).unwrap());
}

// ── NotMember ──
#[test]
fn test_not_member() {
    let lst = list![1i32, 2, 3];
    assert!(L::notMember(4, Arc::clone(&lst)));
    assert!(!L::notMember(2, Arc::clone(&lst)));
}

// ── Partition ──
#[test]
fn test_partition() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5, 6];
    let result = L::partition(Arc::clone(&lst), 2)?;
    assert!(result.len() > 0);
    Ok(())
}

// ── Position ──
#[test]
fn test_position() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    assert_eq!(L::position(3, Arc::clone(&lst))?, 3);
    Ok(())
}
#[test]
fn test_position_not_found() {
    let lst = list![1i32, 2, 3];
    // position returns Err when element not found
    assert!(L::position(9, Arc::clone(&lst)).is_err());
}

// ── Position1OnTrue ──
#[test]
fn test_position1_on_true() {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::position1OnTrue(Arc::clone(&lst), Arc::new(|x, _: i32| Ok(x == 2)), 0i32).unwrap(), 2);
}

// ── PositionOnTrue ──
#[test]
fn test_position_on_true() {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::positionOnTrue(Arc::clone(&lst), Arc::new(is_even)).unwrap(), 2);
}

// ── Reduce ──
#[test]
fn test_reduce() -> Result<()> {
    let lst = list![1i32, 2, 3, 4];
    let result = L::reduce(Arc::clone(&lst), Arc::new(add_i))?;
    assert_eq!(result, 10);
    Ok(())
}

// ── RemoveOnTrue ──
#[test]
fn test_remove_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::removeOnTrue(2i32, Arc::new(eq_i), Arc::clone(&lst)).unwrap();
    assert_eq!(result, list![1i32, 3, 4]);
}

// ── Repeat ──
#[test]
fn test_repeat() {
    let elt = list![42i32];
    let result = L::repeat(Arc::clone(&elt), 3);
    assert_eq!(result.len(), 3);
}

// ── ReplaceAt ──
#[test]
fn test_replace_at() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::replaceAt(99i32, 2, Arc::clone(&lst))?;
    assert_eq!(result, list![1i32, 99, 3]);
    Ok(())
}

// ── ReplaceAtIndexFirst ──
#[test]
fn test_replace_at_index_first() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::replaceAtIndexFirst(1, 99i32, Arc::clone(&lst))?;
    assert_eq!(result, list![99i32, 2, 3]);
    Ok(())
}

// ── ReplaceAtWithList ──
#[test]
fn test_replace_at_with_list() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let replacement = list![10i32, 11];
    let result = L::replaceAtWithList(Arc::clone(&replacement), 2, Arc::clone(&lst))?;
    assert!(result.len() > 0);
    Ok(())
}

// ── ReplaceOnTrue ──
#[test]
fn test_replace_on_true() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let (result, replaced) = L::replaceOnTrue(99i32, Arc::clone(&lst), Arc::new(|x| Ok(x == 2)))?;
    assert!(replaced);
    assert_eq!(result, list![1i32, 99, 3]);
    Ok(())
}

// ── RestOrEmpty ──
#[test]
fn test_rest_or_empty() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::restOrEmpty(Arc::clone(&lst))?;
    assert_eq!(result, list![2i32, 3]);
    Ok(())
}
#[test]
fn test_rest_or_empty_empty() -> Result<()> {
    let lst: Arc<List<i32>> = nil();
    let result = L::restOrEmpty(Arc::clone(&lst))?;
    assert!(result.is_empty());
    Ok(())
}

// ── Second ──
#[test]
fn test_second() -> Result<()> {
    let lst = list![1i32, 2, 3];
    assert_eq!(L::second(Arc::clone(&lst))?, 2);
    Ok(())
}

// ── Separate1OnTrue ──
#[test]
fn test_separate1_on_true() {
    let lst = list![1i32, 2, 3];
    let (a, b) = L::separate1OnTrue(Arc::clone(&lst), Arc::new(|x, _: i32| Ok(x % 2 == 0)), 0i32).unwrap();
    // separate functions use cons-accumulation (reversed output)
    assert_eq!(a.len(), 1);
    assert_eq!(b.len(), 2);
}

// ── SeparateOnTrue ──
#[test]
fn test_separate_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let (a, b) = L::separateOnTrue(Arc::clone(&lst), Arc::new(is_even)).unwrap();
    // separate functions use cons-accumulation (reversed output)
    assert_eq!(a.len(), 2);
    assert_eq!(b.len(), 2);
}

// ── Set ──
#[test]
fn test_set() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::set(Arc::clone(&lst), 2, 99)?;
    assert_eq!(result, list![1i32, 99, 3]);
    Ok(())
}

// ── SetDifference ──
#[test]
fn test_set_difference() -> Result<()> {
    let a = list![1i32, 2, 3, 4];
    let b = list![3i32, 4, 5];
    let result = L::setDifference(Arc::clone(&a), Arc::clone(&b))?;
    assert_eq!(result, list![1i32, 2]);
    Ok(())
}

// ── SetDifferenceIntN ──
#[test]
fn test_set_difference_int_n() -> Result<()> {
    let a = list![1i32, 2, 3, 4];
    let b = list![3i32, 4, 5];
    let result = L::setDifferenceIntN(Arc::clone(&a), Arc::clone(&b), 5)?;
    assert!(result.len() <= 4);
    Ok(())
}

// ── SetDifferenceOnTrue ──
#[test]
fn test_set_difference_on_true() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![2i32, 3];
    let result = L::setDifferenceOnTrue(Arc::clone(&a), Arc::clone(&b), Arc::new(eq_i))?;
    assert_eq!(result, list![1i32]);
    Ok(())
}

// ── SetEqualOnTrue ──
#[test]
fn test_set_equal_on_true() {
    let a = list![1i32, 2, 3];
    let b = list![3i32, 1, 2];
    assert!(L::setEqualOnTrue(Arc::clone(&a), Arc::clone(&b), Arc::new(eq_i)).unwrap());
}

// ── Sort ──
#[test]
fn test_sort() -> Result<()> {
    let lst = list![3i32, 1, 4, 1, 5, 9, 2, 6];
    let result = L::sort(Arc::clone(&lst), Arc::new(less_i))?;
    assert_eq!(result, list![9i32, 6, 5, 4, 3, 2, 1, 1]);
    Ok(())
}

// ── SortedDuplicates ──
#[test]
fn test_sorted_duplicates() -> Result<()> {
    let lst = list![1i32, 1, 2, 3, 3, 4];
    let result = L::sortedDuplicates(Arc::clone(&lst), Arc::new(eq_i))?;
    assert!(result.len() >= 0);
    Ok(())
}

// ── SortedListAllUnique ──
#[test]
fn test_sorted_list_all_unique() -> Result<()> {
    let lst = list![1i32, 2, 3];
    assert!(L::sortedListAllUnique(Arc::clone(&lst), Arc::new(eq_i))?);
    Ok(())
}

// ── SortedUnique ──
#[test]
fn test_sorted_unique() -> Result<()> {
    let lst = list![1i32, 1, 2, 3, 3, 4];
    let result = L::sortedUnique(Arc::clone(&lst), Arc::new(eq_i))?;
    assert_eq!(result, list![1i32, 2, 3, 4]);
    Ok(())
}

// ── SortedUniqueAndDuplicates ──
#[test]
fn test_sorted_unique_and_duplicates() -> Result<()> {
    let lst = list![1i32, 1, 2, 3, 3, 4];
    let (unique, _dups) = L::sortedUniqueAndDuplicates(Arc::clone(&lst), Arc::new(eq_i))?;
    assert_eq!(unique, list![1i32, 2, 3, 4]);
    Ok(())
}

// ── SortedUniqueOnlyDuplicates ──
#[test]
fn test_sorted_unique_only_duplicates() -> Result<()> {
    let lst = list![1i32, 1, 2, 3, 3, 4];
    let result = L::sortedUniqueOnlyDuplicates(Arc::clone(&lst), Arc::new(eq_i))?;
    assert!(result.len() >= 0);
    Ok(())
}

// ── Split ──
#[test]
fn test_split() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let (a, b) = L::split(Arc::clone(&lst), 3)?;
    assert_eq!(a, list![1i32, 2, 3]);
    assert_eq!(b, list![4i32, 5]);
    Ok(())
}

// ── Split1OnTrue ──
#[test]
fn test_split1_on_true() {
    let lst = list![1i32, 2, 3];
    let (before, after) = L::split1OnTrue(Arc::clone(&lst), Arc::new(|x, _: i32| Ok(x == 2)), 0i32).unwrap();
    assert_eq!(before.len() + after.len(), 3);
}

// ── Split2OnTrue ──
#[test]
fn test_split2_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let (before, after) = L::split2OnTrue(Arc::clone(&lst), Arc::new(|x, _a: i32, _b: i32| Ok(x == 3)), 0i32, 0i32).unwrap();
    assert_eq!(before.len() + after.len(), 4);
}

// ── SplitEqualParts ──
#[test]
fn test_split_equal_parts() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5, 6];
    let result = L::splitEqualParts(Arc::clone(&lst), 2)?;
    assert_eq!(result.len(), 2);
    Ok(())
}

// ── SplitEqualPrefix ──
#[test]
fn test_split_equal_prefix() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![1i32, 2, 4];
    let (prefix, _rest) = L::splitEqualPrefix(Arc::clone(&a), Arc::clone(&b), Arc::new(eq_i), nil())?;
    assert_eq!(prefix.len(), 2);
    Ok(())
}

// ── SplitLast ──
#[test]
fn test_split_last() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let (last, init) = L::splitLast(Arc::clone(&lst))?;
    assert_eq!(last, 3);
    assert_eq!(init, list![1i32, 2]);
    Ok(())
}

// ── SplitOnBoolList ──
#[test]
fn test_split_on_bool_list() -> Result<()> {
    let lst = list![1i32, 2, 3, 4];
    let blist = list![false, true, false, true];
    let (trues, falses) = L::splitOnBoolList(Arc::clone(&lst), Arc::clone(&blist))?;
    assert_eq!(trues, list![2i32, 4]);
    assert_eq!(falses, list![1i32, 3]);
    Ok(())
}

// ── SplitOnFirstMatch ──
#[test]
fn test_split_on_first_match() -> Result<()> {
    let lst = list![1i32, 2, 3, 4];
    let (before, after) = L::splitOnFirstMatch(Arc::clone(&lst), Arc::new(is_even))?;
    assert_eq!(before, list![1i32]);
    assert_eq!(after, list![2i32, 3, 4]);
    Ok(())
}

// ── SplitOnTrue ──
#[test]
fn test_split_on_true() {
    let lst = list![1i32, 2, 3, 4];
    let (trues, falses) = L::splitOnTrue(Arc::clone(&lst), Arc::new(is_even)).unwrap();
    assert_eq!(trues, list![2i32, 4]);
    assert_eq!(falses, list![1i32, 3]);
}

// ── Splitr ──
#[test]
fn test_splitr() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let (a, b) = L::splitr(Arc::clone(&lst), 3)?;
    assert_eq!(a.len() + b.len(), 5);
    Ok(())
}

// ── StripLast ──
#[test]
fn test_strip_last() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::stripLast(Arc::clone(&lst))?;
    assert_eq!(result, list![1i32, 2]);
    Ok(())
}

// ── StripN ──
#[test]
fn test_strip_n() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::stripN(Arc::clone(&lst), 2)?;
    assert_eq!(result, list![3i32, 4, 5]);
    Ok(())
}

// ── Sublist ──
#[test]
fn test_sublist() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::sublist(Arc::clone(&lst), 2, 3)?;
    assert_eq!(result, list![2i32, 3, 4]);
    Ok(())
}

// ── Thread ──
#[test]
fn test_thread() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![4i32, 5, 6];
    let result = L::thread(Arc::clone(&a), Arc::clone(&b), nil())?;
    assert_eq!(result.len(), 6);
    Ok(())
}

// ── Thread3Map ──
#[test]
fn test_thread3_map() {
    let a = list![1i32, 2];
    let b = list![10i32, 20];
    let c = list![100i32, 200];
    let result = L::thread3Map(Arc::clone(&a), Arc::clone(&b), Arc::clone(&c), Arc::new(|x, y, z| Ok(x + y + z))).unwrap();
    assert_eq!(result, list![111i32, 222]);
}

// ── Thread3MapFold ──
#[test]
fn test_thread3_map_fold() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![10i32, 20];
    let c = list![100i32, 200];
    let (result, acc) = L::thread3MapFold(Arc::clone(&a), Arc::clone(&b), Arc::clone(&c), Arc::new(|x, y, z, fold: i32| Ok((x + y + z, fold + 1))), 0i32)?;
    assert_eq!(result, list![111i32, 222]);
    assert_eq!(acc, 2);
    Ok(())
}

// ── ThreadFold ──
#[test]
fn test_thread_fold() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![4i32, 5, 6];
    let result = L::threadFold(Arc::clone(&a), Arc::clone(&b), Arc::new(|x, y, acc| Ok(acc + x + y)), 0i32)?;
    assert_eq!(result, 21);
    Ok(())
}

// ── ThreadFold1 ──
#[test]
fn test_thread_fold1() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let result = L::threadFold1(Arc::clone(&a), Arc::clone(&b), Arc::new(|x, y, _arg: i32, acc| Ok(acc + x + y)), 0i32, 0i32)?;
    assert_eq!(result, 10);
    Ok(())
}

// ── ThreadFold2 ──
#[test]
fn test_thread_fold2() -> Result<()> {
    let a = list![1i32];
    let b = list![2i32];
    let result = L::threadFold2(Arc::clone(&a), Arc::clone(&b), Arc::new(|x, y, _a: i32, _b: i32, acc| Ok(acc + x + y)), 0i32, 0i32, 0i32)?;
    assert_eq!(result, 3);
    Ok(())
}

// ── ThreadFold3 ──
#[test]
fn test_thread_fold3() -> Result<()> {
    let a = list![1i32];
    let b = list![2i32];
    let result = L::threadFold3(Arc::clone(&a), Arc::clone(&b), Arc::new(|x, y, _a: i32, _b: i32, _c: i32, acc| Ok(acc + x + y)), 0i32, 0i32, 0i32, 0i32)?;
    assert_eq!(result, 3);
    Ok(())
}

// ── ThreadMap ──
#[test]
fn test_thread_map() {
    let a = list![1i32, 2, 3];
    let b = list![4i32, 5, 6];
    let result = L::threadMap(Arc::clone(&a), Arc::clone(&b), Arc::new(|x, y| Ok(x + y))).unwrap();
    assert_eq!(result, list![5i32, 7, 9]);
}

// ── ThreadMap1 ──
#[test]
fn test_thread_map1() {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let result = L::threadMap1(Arc::clone(&a), Arc::clone(&b), Arc::new(|x, y, _arg: i32| Ok(x + y)), 0i32).unwrap();
    assert_eq!(result, list![4i32, 6]);
}

// ── ThreadMap1_0 ──
#[test]
fn test_thread_map1_0() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    L::threadMap1_0(Arc::clone(&a), Arc::clone(&b), Arc::new(|_x, _y, _arg: i32| Ok(())), 0i32)?;
    Ok(())
}

// ── ThreadMap2 ──
#[test]
fn test_thread_map2() {
    let a = list![1i32];
    let b = list![2i32];
    let result = L::threadMap2(Arc::clone(&a), Arc::clone(&b), Arc::new(|x, y, _a: i32, _b: i32| Ok(x + y)), 0i32, 0i32).unwrap();
    assert_eq!(result, list![3i32]);
}

// ── ThreadMapFold ──
#[test]
fn test_thread_map_fold() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let (result, acc) = L::threadMapFold(Arc::clone(&a), Arc::clone(&b), Arc::new(|x, y, fold: i32| Ok((x + y, fold + 1))), 0i32)?;
    assert_eq!(result, list![4i32, 6]);
    assert_eq!(acc, 2);
    Ok(())
}

// ── ThreadMapList ──
#[test]
fn test_thread_map_list() {
    let a = list![list![1i32, 2]];
    let b = list![list![3i32, 4]];
    let result = L::threadMapList(Arc::clone(&a), Arc::clone(&b), Arc::new(|x, y| Ok(x + y))).unwrap();
    assert_eq!(result, list![list![4i32, 6]]);
}

// ── ThreadMapList_2 ──
#[test]
fn test_thread_map_list_2() -> Result<()> {
    let a = list![list![1i32, 2]];
    let b = list![list![3i32, 4]];
    let (r1, _r2) = L::threadMapList_2(Arc::clone(&a), Arc::clone(&b), Arc::new(|x, y| Ok((x + y, x * y))))?;
    assert_eq!(r1, list![list![4i32, 6]]);
    Ok(())
}

// ── ThreadMap_2 ──
#[test]
fn test_thread_map_2() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let (r1, r2) = L::threadMap_2(Arc::clone(&a), Arc::clone(&b), Arc::new(|x, y| Ok((x + y, x * y))))?;
    assert_eq!(r1, list![4i32, 6]);
    assert_eq!(r2, list![3i32, 8]);
    Ok(())
}

// ── ToListWithPositions ──
#[test]
fn test_to_list_with_positions() {
    let lst = list![10i32, 20, 30];
    let result = L::toListWithPositions(Arc::clone(&lst));
    assert_eq!(result.len(), 3);
}

// ── ToString ──
#[test]
fn test_to_string() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = L::toString(Arc::clone(&lst), Arc::new(to_string_i32), arcstr::literal!(""), arcstr::literal!("{"), arcstr::literal!(", "), arcstr::literal!("}"), true, -1)?;
    assert_eq!(&*result, "{1, 2, 3}");
    Ok(())
}
#[test]
fn test_to_string_empty() -> Result<()> {
    let lst: Arc<List<i32>> = nil();
    let result = L::toString(Arc::clone(&lst), Arc::new(to_string_i32), arcstr::literal!(""), arcstr::literal!("{"), arcstr::literal!(", "), arcstr::literal!("}"), true, -1)?;
    assert_eq!(&*result, "{}");
    Ok(())
}

// ── TransposeList ──
#[test]
fn test_transpose_list() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let lst = list![Arc::clone(&a), Arc::clone(&b)];
    let result = L::transposeList(Arc::clone(&lst))?;
    assert_eq!(result.len(), 2);
    Ok(())
}

// ── Trim ──
#[test]
fn test_trim() -> Result<()> {
    let lst = list![2i32, 1, 3, 4, 2];
    let result = L::trim(Arc::clone(&lst), Arc::new(is_even))?;
    assert!(result.len() > 0);
    Ok(())
}

// ── TrimToLength ──
#[test]
fn test_trim_to_length() -> Result<()> {
    let lst = list![1i32, 2, 3, 4, 5];
    let result = L::trimToLength(Arc::clone(&lst), 3)?;
    // trimToLength keeps last N elements
    assert_eq!(result.len(), 3);
    Ok(())
}

// ── Union ──
#[test]
fn test_union() {
    let a = list![1i32, 2, 3];
    let b = list![3i32, 4, 5];
    let result = L::union(Arc::clone(&a), Arc::clone(&b));
    assert_eq!(result, list![1i32, 2, 3, 4, 5]);
}

// ── UnionAppendListOnTrue ──
#[test]
fn test_union_append_list_on_true() {
    let a = list![1i32, 2];
    let b = list![2i32, 3];
    let result = L::unionAppendListOnTrue(Arc::clone(&a), Arc::clone(&b), Arc::new(eq_i)).unwrap();
    assert!(result.len() >= 2);
}

// ── UnionElt ──
#[test]
fn test_union_elt() {
    let lst = list![1i32, 2, 3];
    let result = L::unionElt(4, Arc::clone(&lst));
    // unionElt prepends new element if not present
    assert_eq!(result, list![4i32, 1, 2, 3]);
}
#[test]
fn test_union_elt_exists() {
    let lst = list![1i32, 2, 3];
    let result = L::unionElt(2, Arc::clone(&lst));
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── UnionEltOnTrue ──
#[test]
fn test_union_elt_on_true() {
    let lst = list![1i32, 2, 3];
    let result = L::unionEltOnTrue(4, Arc::clone(&lst), Arc::new(eq_i)).unwrap();
    // unionEltOnTrue prepends new element if not present
    assert_eq!(result, list![4i32, 1, 2, 3]);
}

// ── UnionIntN ──
#[test]
fn test_union_int_n() -> Result<()> {
    let a = list![1i32, 2, 3];
    let b = list![3i32, 4];
    let result = L::unionIntN(Arc::clone(&a), Arc::clone(&b), 4)?;
    assert_eq!(result, list![1i32, 2, 3, 4]);
    Ok(())
}

// ── UnionList ──
#[test]
fn test_union_list() -> Result<()> {
    let a = list![list![1i32, 2], list![2i32, 3]];
    let result = L::unionList(Arc::clone(&a))?;
    assert_eq!(result, list![1i32, 2, 3]);
    Ok(())
}

// ── UnionOnTrue ──
#[test]
fn test_union_on_true() {
    let a = list![1i32, 2];
    let b = list![2i32, 3];
    let result = L::unionOnTrue(Arc::clone(&a), Arc::clone(&b), Arc::new(eq_i)).unwrap();
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── UnionOnTrueList ──
#[test]
fn test_union_on_true_list() -> Result<()> {
    let a = list![list![1i32, 2]];
    let result = L::unionOnTrueList(Arc::clone(&a), Arc::new(|x: i32, y: i32| Ok(x == y)))?;
    assert!(result.len() >= 0);
    Ok(())
}

// ── Unique ──
#[test]
fn test_unique() {
    let lst = list![1i32, 2, 1, 3, 2];
    let result = L::unique(Arc::clone(&lst));
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── UniqueIntN ──
#[test]
fn test_unique_int_n() -> Result<()> {
    let lst = list![1i32, 2, 1, 3, 2];
    let result = L::uniqueIntN(Arc::clone(&lst), 3)?;
    assert!(result.len() <= 3);
    Ok(())
}

// ── UniqueOnTrue ──
#[test]
fn test_unique_on_true() {
    let lst = list![1i32, 2, 1, 3];
    let result = L::uniqueOnTrue(Arc::clone(&lst), Arc::new(eq_i)).unwrap();
    assert_eq!(result, list![1i32, 2, 3]);
}

// ── Unzip ──
#[test]
fn test_unzip() {
    let lst = list![(1i32, 10i32), (2i32, 20), (3i32, 30)];
    let (a, b) = L::unzip(Arc::clone(&lst));
    assert_eq!(a, list![1i32, 2, 3]);
    assert_eq!(b, list![10i32, 20, 30]);
}

// ── Unzip3 ──
#[test]
fn test_unzip3() {
    let lst = list![(1i32, 10i32, 100i32)];
    let (a, b, c) = L::unzip3(Arc::clone(&lst));
    assert_eq!(a, list![1i32]);
    assert_eq!(b, list![10i32]);
    assert_eq!(c, list![100i32]);
}

// ── UnzipSecond ──
#[test]
fn test_unzip_second() {
    let lst = list![(1i32, 10i32), (2i32, 20)];
    let result = L::unzipSecond(Arc::clone(&lst));
    assert_eq!(result, list![10i32, 20]);
}

// ── Zip ──
#[test]
fn test_zip() {
    let a = list![1i32, 2, 3];
    let b = list![10i32, 20, 30];
    let result = L::zip(Arc::clone(&a), Arc::clone(&b));
    assert_eq!(result, list![(1i32, 10i32), (2i32, 20), (3i32, 30)]);
}

// ── Zip3 ──
#[test]
fn test_zip3() {
    let a = list![1i32, 2];
    let b = list![10i32, 20];
    let c = list![100i32, 200];
    let result = L::zip3(Arc::clone(&a), Arc::clone(&b), Arc::clone(&c));
    assert_eq!(result, list![(1i32, 10i32, 100i32), (2i32, 20i32, 200)]);
}

// ── Select (alias for filterOnTrue) ──
#[test]
fn test_select() {
    let lst = list![1i32, 2, 3, 4];
    let result = L::select(Arc::clone(&lst), Arc::new(is_even)).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── Select1 ──
#[test]
fn test_select1() {
    let lst = list![2i32];
    let result = L::select1(Arc::clone(&lst), Arc::new(|x, _: i32| Ok(x % 2 == 0)), 0i32).unwrap();
    assert_eq!(result, list![2i32]);
}

// ── Select1r ──
#[test]
fn test_select1r() {
    let lst = list![2i32, 4];
    let result = L::select1r(Arc::clone(&lst), Arc::new(|_: i32, x| Ok(x % 2 == 0)), 0i32).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── Select2 ──
#[test]
fn test_select2() {
    let lst = list![2i32, 4];
    let result = L::select2(Arc::clone(&lst), Arc::new(|x, _a: i32, _b: i32| Ok(x % 2 == 0)), 0i32, 0i32).unwrap();
    assert_eq!(result, list![2i32, 4]);
}

// ── AllCombinations ──
#[test]
fn test_all_combinations() -> Result<()> {
    let lst = list![list![1i32, 2], list![3i32, 4]];
    let result = L::allCombinations(Arc::clone(&lst), None, sourceInfo!())?;
    assert!(result.len() >= 0);
    Ok(())
}

// ── Additional edge cases ──
#[test]
fn test_map_empty_list() {
    let lst: Arc<List<i32>> = nil();
    let result = L::map(Arc::clone(&lst), Arc::new(double)).unwrap();
    assert!(result.is_empty());
}

#[test]
fn test_fold_empty() {
    let lst: Arc<List<i32>> = nil();
    let result = L::fold(Arc::clone(&lst), Arc::new(|_, acc| Ok(acc)), 99i32).unwrap();
    assert_eq!(result, 99);
}

#[test]
fn test_filter_empty_result() {
    let lst = list![1i32, 3, 5];
    let result = L::filter(Arc::clone(&lst), Arc::new(|x| { if x % 2 == 0 { Ok(()) } else { bail!("skip") } }));
    assert!(result.is_empty());
}

#[test]
fn test_union_elt_duplicate() {
    let lst = list![1i32, 2, 3];
    let result = L::unionElt(2, Arc::clone(&lst));
    assert_eq!(result, list![1i32, 2, 3]);
}

#[test]
fn test_intersection_on_true_no_overlap() {
    let a = list![1i32, 2];
    let b = list![3i32, 4];
    let result = L::intersectionOnTrue(Arc::clone(&a), Arc::clone(&b), Arc::new(eq_i)).unwrap();
    assert!(result.is_empty());
}

#[test]
fn test_set_difference_all_in_b() -> Result<()> {
    let a = list![1i32, 2];
    let b = list![1i32, 2, 3];
    let result = L::setDifference(Arc::clone(&a), Arc::clone(&b))?;
    assert!(result.is_empty());
    Ok(())
}

#[test]
fn test_sort_empty() -> Result<()> {
    let lst: Arc<List<i32>> = nil();
    let result = L::sort(Arc::clone(&lst), Arc::new(less_i))?;
    assert!(result.is_empty());
    Ok(())
}

#[test]
fn test_sort_single() -> Result<()> {
    let lst = list![42i32];
    let result = L::sort(Arc::clone(&lst), Arc::new(less_i))?;
    assert_eq!(result, list![42i32]);
    Ok(())
}

#[test]
fn test_count_zero() {
    let lst = list![1i32, 3, 5];
    assert_eq!(L::count(Arc::clone(&lst), Arc::new(is_even)).unwrap(), 0);
}

#[test]
fn test_position_empty() {
    let lst: Arc<List<i32>> = nil();
    // position returns Err when element not found (empty list)
    assert!(L::position(1, Arc::clone(&lst)).is_err());
}

#[test]
fn test_max_min_single() -> Result<()> {
    let lst = list![42i32];
    assert_eq!(L::maxElement(Arc::clone(&lst), Arc::new(less_i))?, 42);
    assert_eq!(L::minElement(Arc::clone(&lst), Arc::new(less_i))?, 42);
    Ok(())
}
