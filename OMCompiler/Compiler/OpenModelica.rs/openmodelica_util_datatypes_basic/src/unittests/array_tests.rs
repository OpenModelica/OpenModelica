use anyhow::Result;
use std::sync::Arc;
use metamodelica::*;
use arcstr::{ArcStr, literal};
use crate::Array;

// ── helper predicates ──

fn is_positive(x: i32) -> Result<bool> { Ok(x > 0) }
fn is_even(x: i32) -> Result<bool> { Ok(x % 2 == 0) }
fn always_true(_: i32) -> Result<bool> { Ok(true) }
fn always_false(_: i32) -> Result<bool> { Ok(false) }
fn double(x: i32) -> Result<i32> { Ok(x * 2) }
fn square(x: i32) -> Result<i32> { Ok(x * x) }
fn add(x: i32, y: i32) -> Result<i32> { Ok(x + y) }
fn int_less(a: i32, b: i32) -> Result<bool> { Ok(a < b) }
fn int_cmp(a: i32, b: i32) -> Result<i32> { Ok(if a < b { -1 } else if a > b { 1 } else { 0 }) }
fn fold_add(a: i32, acc: i32) -> Result<i32> { Ok(acc + a) }
fn fold_mul(a: i32, acc: i32) -> Result<i32> { Ok(acc * a) }
fn fold_index_add(a: i32, idx: i32, acc: i32) -> Result<i32> { Ok(acc + a + idx) }
fn print_i32(x: i32) -> Result<ArcStr> { Ok(arcstr::format!("{}", x)) }
fn is_greater_than_5(x: i32) -> Result<bool> { Ok(x > 5) }
fn int_to_string(x: i32) -> Result<ArcStr> { Ok(arcstr::format!("{}", x)) }
fn thread_add(a: i32, b: i32) -> Result<i32> { Ok(a + b) }
fn fold_tuple(a: i32, acc: i32) -> Result<(i32, i32)> { Ok((a * 2, acc + a)) }
fn mapnocopy_fn(x: i32) -> Result<i32> { Ok(x + 1) }

fn arr(v: Vec<i32>) -> metamodelica::Array<i32> { arrayFromVec(v) }

// ── Tests ──

// all returns bool, not Result
#[test]
fn test_all_true() {
    let a = arr(vec![1, 2, 3]);
    assert!(Array::all(a, Arc::new(is_positive)).unwrap());
}

#[test]
fn test_all_false() {
    let a = arr(vec![1, -2, 3]);
    assert!(!Array::all(a, Arc::new(is_positive)).unwrap());
}

#[test]
fn test_all_empty() {
    let a: metamodelica::Array<i32> = arrayFromVec(vec![]);
    assert!(Array::all(a, Arc::new(is_positive)).unwrap());
}

// allEqual returns bool, not Result
#[test]
fn test_all_equal_true() {
    let a = arr(vec![5, 5, 5]);
    assert!(Array::allEqual(a, Arc::new(|a, b| Ok(a == b))).unwrap());
}

#[test]
fn test_all_equal_false() {
    let a = arr(vec![5, 3, 5]);
    assert!(!Array::allEqual(a, Arc::new(|a, b| Ok(a == b))).unwrap());
}

#[test]
fn test_all_equal_empty() {
    let a: metamodelica::Array<i32> = arrayFromVec(vec![]);
    assert!(Array::allEqual(a, Arc::new(|a, b| Ok(a == b))).unwrap());
}

// any returns bool, not Result
#[test]
fn test_any_found() {
    let a = arr(vec![-1, 2, -3]);
    assert!(Array::any(a, Arc::new(is_positive)).unwrap());
}

#[test]
fn test_any_none() {
    let a = arr(vec![-1, -2, -3]);
    assert!(!Array::any(a, Arc::new(is_positive)).unwrap());
}

#[test]
fn test_any_empty() {
    let a: metamodelica::Array<i32> = arrayFromVec(vec![]);
    assert!(!Array::any(a, Arc::new(is_positive)).unwrap());
}

#[test]
fn test_append_list() -> Result<()> {
    let a = arr(vec![1, 2]);
    let lst = list![3i32, 4];
    let result = Array::appendList(a, Arc::clone(&lst))?;
    assert_eq!(*result.borrow(), vec![1, 2, 3, 4]);
    Ok(())
}

#[test]
fn test_append_list_empty_arr() -> Result<()> {
    let a: metamodelica::Array<i32> = arrayFromVec(vec![]);
    let lst = list![1i32, 2];
    let result = Array::appendList(a, Arc::clone(&lst))?;
    assert_eq!(*result.borrow(), vec![1, 2]);
    Ok(())
}

#[test]
fn test_append_list_empty_lst() -> Result<()> {
    let a = arr(vec![1, 2]);
    let lst: Arc<List<i32>> = nil();
    let result = Array::appendList(a, lst)?;
    assert_eq!(*result.borrow(), vec![1, 2]);
    Ok(())
}

// compare returns i32, not Result
#[test]
fn test_compare_equal() {
    let a = arr(vec![1, 2, 3]);
    let b = arr(vec![1, 2, 3]);
    assert_eq!(Array::compare(a, b, Arc::new(int_cmp)).unwrap(), 0);
}

#[test]
fn test_compare_less() {
    let a = arr(vec![1, 2]);
    let b = arr(vec![1, 3]);
    assert_eq!(Array::compare(a, b, Arc::new(int_cmp)).unwrap(), -1);
}

#[test]
fn test_compare_greater() {
    let a = arr(vec![1, 4]);
    let b = arr(vec![1, 3]);
    assert_eq!(Array::compare(a, b, Arc::new(int_cmp)).unwrap(), 1);
}

#[test]
fn test_compare_length_diff() {
    let a = arr(vec![1, 2, 3]);
    let b = arr(vec![1, 2]);
    assert_eq!(Array::compare(a, b, Arc::new(int_cmp)).unwrap(), 1);
}

#[test]
fn test_copy() -> Result<()> {
    let src = arr(vec![1, 2, 3]);
    let dest = arr(vec![0, 0, 0, 0]);
    let result = Array::copy(src, dest)?;
    assert_eq!(*result.borrow(), vec![1, 2, 3, 0]);
    Ok(())
}

#[test]
fn test_copy_n() -> Result<()> {
    let src = arr(vec![10, 20, 30, 40]);
    let dest = arr(vec![0, 0, 0, 0, 0]);
    // Copy 2 elements from src offset 1 to dest offset 2
    // MM: dest[i+dstOffset] := src[i+srcOffset] for i in 1..=N
    //   i=1: dest[3] := src[2] = 20
    //   i=2: dest[4] := src[3] = 30
    let result = Array::copyN(src, dest, 2, 1, 2)?;
    assert_eq!(*result.borrow(), vec![0, 0, 20, 30, 0]);
    Ok(())
}

#[test]
fn test_copy_range() -> Result<()> {
    let src = arr(vec![1, 2, 3, 4, 5]);
    let dest = arr(vec![0, 0, 0, 0, 0]);
    // Copy range [2,4] to position 3
    Array::copyRange(src, dest.clone(), 2, 4, 3)?;
    assert_eq!(*dest.borrow(), vec![0, 0, 2, 3, 4]);
    Ok(())
}

// createIntRange returns Array<i32>, not Result
#[test]
fn test_create_int_range() {
    let result = Array::createIntRange(5);
    assert_eq!(*result.borrow(), vec![1, 2, 3, 4, 5]);
}

#[test]
fn test_expand() -> Result<()> {
    let a = arr(vec![1, 2]);
    let result = Array::expand(3, a, 0)?;
    assert_eq!(*result.borrow(), vec![1, 2, 0, 0, 0]);
    Ok(())
}

#[test]
fn test_expand_negative() -> Result<()> {
    let a = arr(vec![1, 2]);
    let result = Array::expand(-1, a, 0)?;
    assert_eq!(*result.borrow(), vec![1, 2]);
    Ok(())
}

#[test]
fn test_expand_on_demand_grow() -> Result<()> {
    let a = arr(vec![1, 2, 3]);
    // MM: new_size = realInt(len * factor) = realInt(3 * 2.0) = 6 (not inNewSize)
    let result = Array::expandOnDemand(5, a, metamodelica::Real::from(2.0_f64), 0)?;
    assert_eq!(*result.borrow(), vec![1, 2, 3, 0, 0, 0]);
    Ok(())
}

#[test]
fn test_expand_on_demand_no_grow() -> Result<()> {
    let a = arr(vec![1, 2, 3]);
    let result = Array::expandOnDemand(2, a, metamodelica::Real::from(2.0_f64), 0)?;
    assert_eq!(*result.borrow(), vec![1, 2, 3]);
    Ok(())
}

#[test]
fn test_expand_to_size_grow() -> Result<()> {
    let a = arr(vec![1, 2]);
    let result = Array::expandToSize(5, a, -1)?;
    assert_eq!(*result.borrow(), vec![1, 2, -1, -1, -1]);
    Ok(())
}

#[test]
fn test_expand_to_size_no_grow() -> Result<()> {
    let a = arr(vec![1, 2, 3]);
    let result = Array::expandToSize(2, a, 0)?;
    assert_eq!(*result.borrow(), vec![1, 2, 3]);
    Ok(())
}

// filter returns Array<T>, not Result
// NOTE: filter keeps elements where predicate returns FALSE (filter-out semantics)
#[test]
fn test_filter() {
    let a = arr(vec![1, 2, 3, 4, 5, 6]);
    let result = Array::filter(a, Arc::new(is_even)).unwrap();
    assert_eq!(*result.borrow(), vec![1, 3, 5]);
}

#[test]
fn test_filter_none() {
    let a = arr(vec![1, 3, 5]);
    let result = Array::filter(a, Arc::new(is_even)).unwrap();
    assert_eq!(*result.borrow(), vec![1, 3, 5]);
}

// findFirstOnTrue returns Option<T>, not Result
#[test]
fn test_find_first_on_true_found() {
    let a = arr(vec![1, 3, 5, 7, 2]);
    let result = Array::findFirstOnTrue(a, Arc::new(is_greater_than_5)).unwrap();
    assert_eq!(result, Some(7));
}

#[test]
fn test_find_first_on_true_not_found() {
    let a = arr(vec![1, 2, 3]);
    let result = Array::findFirstOnTrue(a, Arc::new(is_greater_than_5)).unwrap();
    assert_eq!(result, None);
}

// findFirstOnTrueWithIdx returns (Option<T>, i32), not Result
#[test]
fn test_find_first_on_true_with_idx_found() {
    let a = arr(vec![1, 3, 5, 7]);
    let (val, idx) = Array::findFirstOnTrueWithIdx(a, Arc::new(is_greater_than_5)).unwrap();
    assert_eq!(val, Some(7));
    assert_eq!(idx, 4);
}

#[test]
fn test_find_first_on_true_with_idx_not_found() {
    let a = arr(vec![1, 2, 3]);
    let (val, idx) = Array::findFirstOnTrueWithIdx(a, Arc::new(is_greater_than_5)).unwrap();
    assert_eq!(val, None);
    assert_eq!(idx, -1);
}

// fold returns FoldT, not Result
#[test]
fn test_fold() {
    let a = arr(vec![1, 2, 3, 4, 5]);
    let result = Array::fold(a, Arc::new(fold_add), 0).unwrap();
    assert_eq!(result, 15);
}

#[test]
fn test_fold_index() -> Result<()> {
    let a = arr(vec![10, 20]);
    // fold_index_add(10, 1, 0) = 11, fold_index_add(20, 2, 11) = 33
    let result = Array::foldIndex(a, Arc::new(fold_index_add), 0)?;
    assert_eq!(result, 33);
    Ok(())
}

// generate returns Array<T>, not Result
#[test]
fn test_generate() {
    let result = Array::generate(3, Arc::new(|| Ok(42))).unwrap();
    assert_eq!(*result.borrow(), vec![42, 42, 42]);
}

#[test]
fn test_generate_zero() {
    let result = Array::generate(0, Arc::new(|| Ok(42i32))).unwrap();
    assert!(result.borrow().is_empty());
}

// getIndexFirst is fallible: its `output T outElement = arrayGet(inArray, inIndex)`
// binding calls the bounds-checked `arrayGet`.
#[test]
fn test_get_index_first() -> Result<()> {
    let a = arr(vec![10, 20, 30]);
    assert_eq!(Array::getIndexFirst(1, a.clone())?, 10);
    assert_eq!(Array::getIndexFirst(2, a.clone())?, 20);
    assert_eq!(Array::getIndexFirst(3, a)?, 30);
    Ok(())
}

#[test]
fn test_get_member_on_true() -> Result<()> {
    let a = arr(vec![1, 2, 3]);
    let (val, idx) = Array::getMemberOnTrue(2, a.clone(), Arc::new(|v, e| Ok(v == e)))?;
    assert_eq!(val, 2);
    assert_eq!(idx, 2);
    Ok(())
}

#[test]
fn test_get_range() -> Result<()> {
    let a = arr(vec![1, 2, 3, 4, 5]);
    let result = Array::getRange(2, 4, a)?;
    // Returns list in reverse order (cons'd onto front)
    assert_eq!(result, list![4i32, 3, 2]);
    Ok(())
}

// heapSort returns Array<i32>, not Result
#[test]
fn test_heap_sort() {
    let a = arr(vec![3, 1, 4, 1, 5, 9, 2, 6]);
    let result = Array::heapSort(a);
    assert_eq!(*result.borrow(), vec![1, 1, 2, 3, 4, 5, 6, 9]);
}

#[test]
fn test_heap_sort_empty() {
    let a: metamodelica::Array<i32> = arrayFromVec(vec![]);
    let result = Array::heapSort(a);
    assert!(result.borrow().is_empty());
}

// insertList returns Array<T>, not Result
#[test]
fn test_insert_list() {
    let a = arr(vec![0, 0, 0, 0, 0]);
    let lst = list![1i32, 2, 3];
    let result = Array::insertList(a, Arc::clone(&lst), 2);
    assert_eq!(*result.borrow(), vec![0, 1, 2, 3, 0]);
}

#[test]
fn test_is_equal_true() -> Result<()> {
    assert!(Array::isEqual(arr(vec![1, 2, 3]), arr(vec![1, 2, 3]))?);
    Ok(())
}

#[test]
fn test_is_equal_false() -> Result<()> {
    assert!(!Array::isEqual(arr(vec![1, 2, 3]), arr(vec![1, 2, 4]))?);
    Ok(())
}

#[test]
fn test_is_equal_length_diff_fails() -> Result<()> {
    let result = Array::isEqual(arr(vec![1, 2]), arr(vec![1, 2, 3]));
    assert!(result.is_err());
    Ok(())
}

// isEqualOnTrue returns bool, not Result
#[test]
fn test_is_equal_on_true_custom_pred() {
    // predicate x*2==y: pairs must be (2,4), (3,6), (4,8) — fixed from (2,4,6)/(4,6,8) which fails at 4*2=8≠6
    let a = arr(vec![2, 3, 4]);
    let b = arr(vec![4, 6, 8]);
    assert!(Array::isEqualOnTrue(a, b, Arc::new(|x, y| Ok(x * 2 == y))).unwrap());
}

// isLess returns bool, not Result
#[test]
fn test_is_less_true() {
    assert!(Array::isLess(arr(vec![1, 2]), arr(vec![1, 3]), Arc::new(int_less)).unwrap());
}

#[test]
fn test_is_less_false() {
    assert!(!Array::isLess(arr(vec![1, 4]), arr(vec![1, 3]), Arc::new(int_less)).unwrap());
}

#[test]
fn test_is_less_equal() {
    assert!(!Array::isLess(arr(vec![1, 2, 3]), arr(vec![1, 2, 3]), Arc::new(int_less)).unwrap());
}

#[test]
fn test_join() -> Result<()> {
    let a = arr(vec![1, 2]);
    let b = arr(vec![3, 4]);
    let result = Array::join(a, b)?;
    assert_eq!(*result.borrow(), vec![1, 2, 3, 4]);
    Ok(())
}

#[test]
fn test_join_empty_first() -> Result<()> {
    let a: metamodelica::Array<i32> = arrayFromVec(vec![]);
    let b = arr(vec![1, 2]);
    let result = Array::join(a, b)?;
    assert_eq!(*result.borrow(), vec![1, 2]);
    Ok(())
}

#[test]
fn test_join_empty_second() -> Result<()> {
    let a = arr(vec![1, 2]);
    let b: metamodelica::Array<i32> = arrayFromVec(vec![]);
    let result = Array::join(a, b)?;
    assert_eq!(*result.borrow(), vec![1, 2]);
    Ok(())
}

// map returns Array<TO>, not Result
#[test]
fn test_map() {
    let a = arr(vec![1, 2, 3]);
    let result = Array::map(a, Arc::new(double)).unwrap();
    assert_eq!(*result.borrow(), vec![2, 4, 6]);
}

#[test]
fn test_map_empty() {
    let a: metamodelica::Array<i32> = arrayFromVec(vec![]);
    let result = Array::map(a, Arc::new(double)).unwrap();
    assert!(result.borrow().is_empty());
}

#[test]
fn test_map1() -> Result<()> {
    let a = arr(vec![1, 2, 3]);
    let result = Array::map1(a, Arc::new(|x, arg| Ok(x + arg)), 10)?;
    assert_eq!(*result.borrow(), vec![11, 12, 13]);
    Ok(())
}

#[test]
fn test_map1_ind() -> Result<()> {
    let a = arr(vec![1, 2, 3]);
    let result = Array::map1Ind(a, Arc::new(|x, idx, arg| Ok(x + idx + arg)), 0)?;
    assert_eq!(*result.borrow(), vec![2, 4, 6]);
    Ok(())
}

// mapFold returns (Array<TO>, ArgT), not Result
#[test]
fn test_map_fold() {
    let a = arr(vec![1, 2, 3]);
    let (result_arr, result_arg) = Array::mapFold(a, Arc::new(fold_tuple), 0).unwrap();
    assert_eq!(*result_arr.borrow(), vec![2, 4, 6]);
    assert_eq!(result_arg, 6);
}

#[test]
fn test_map_list() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let result = Array::mapList(Arc::clone(&lst), Arc::new(double))?;
    assert_eq!(*result.borrow(), vec![2, 4, 6]);
    Ok(())
}

// mapNoCopy returns Array<T>, not Result
#[test]
fn test_map_no_copy() {
    let a = arr(vec![1, 2, 3]);
    let result = Array::mapNoCopy(a, Arc::new(mapnocopy_fn)).unwrap();
    assert_eq!(*result.borrow(), vec![2, 3, 4]);
}

// maxElement returns T, not Result
#[test]
fn test_max_element() {
    let a = arr(vec![3, 1, 4, 1, 5, 9]);
    let result = Array::maxElement(a, Arc::new(int_less)).unwrap();
    assert_eq!(result, 9);
}

// minElement returns T, not Result
#[test]
fn test_min_element() {
    let a = arr(vec![3, 1, 4, 1, 5, 9]);
    let result = Array::minElement(a, Arc::new(int_less)).unwrap();
    assert_eq!(result, 1);
}

// position returns i32, not Result
#[test]
fn test_position_found() {
    let a = arr(vec![1, 2, 3, 4, 5]);
    assert_eq!(Array::position(a, 3, 5), 3);
}

#[test]
fn test_position_not_found() {
    let a = arr(vec![1, 2, 3]);
    assert_eq!(Array::position(a, 99, 3), 0);
}

#[test]
fn test_reduce() -> Result<()> {
    let a = arr(vec![1, 2, 3, 4]);
    let result = Array::reduce(a, Arc::new(add))?;
    assert_eq!(result, 10);
    Ok(())
}

// remove is fail-able because Array.mo asserts `true := index <= len and index >= 1`.
#[test]
fn test_remove() -> Result<()> {
    let a = arr(vec![1, 2, 3, 4]);
    let result = Array::remove(a, 2)?;
    assert_eq!(*result.borrow(), vec![1, 3, 4]);
    Ok(())
}

#[test]
fn test_remove_single_element() -> Result<()> {
    let a = arr(vec![1]);
    let result = Array::remove(a, 1)?;
    assert!(result.borrow().is_empty());
    Ok(())
}

#[test]
fn test_replace_at_with_fill() -> Result<()> {
    let a = arr(vec![1, 2]);
    let result = Array::replaceAtWithFill(4, 99, 0, a)?;
    assert_eq!(*result.borrow(), vec![1, 2, 0, 99]);
    Ok(())
}

#[test]
fn test_reverse() -> Result<()> {
    let a = arr(vec![1, 2, 3, 4]);
    let result = Array::reverse(a)?;
    assert_eq!(*result.borrow(), vec![4, 3, 2, 1]);
    Ok(())
}

#[test]
fn test_select() -> Result<()> {
    let a = arr(vec![10, 20, 30, 40]);
    let indices = list![3i32, 1];
    let result = Array::select(a, Arc::clone(&indices))?;
    assert_eq!(*result.borrow(), vec![30, 10]);
    Ok(())
}

#[test]
fn test_set_range() -> Result<()> {
    let a = arr(vec![1, 2, 3, 4, 5]);
    let result = Array::setRange(2, 4, a, 0)?;
    assert_eq!(*result.borrow(), vec![1, 0, 0, 0, 5]);
    Ok(())
}

#[test]
fn test_thread_map() -> Result<()> {
    let a = arr(vec![1, 2, 3]);
    let b = arr(vec![10, 20, 30]);
    let result = Array::threadMap(a, b, Arc::new(thread_add))?;
    assert_eq!(*result.borrow(), vec![11, 22, 33]);
    Ok(())
}

#[test]
fn test_thread_map_empty() -> Result<()> {
    let a: metamodelica::Array<i32> = arrayFromVec(vec![]);
    let b: metamodelica::Array<i32> = arrayFromVec(vec![]);
    let result = Array::threadMap(a, b, Arc::new(thread_add))?;
    assert!(result.borrow().is_empty());
    Ok(())
}

#[test]
fn test_thread_map_length_mismatch() -> Result<()> {
    let a = arr(vec![1, 2]);
    let b = arr(vec![1, 2, 3]);
    let result = Array::threadMap(a, b, Arc::new(thread_add));
    assert!(result.is_err());
    Ok(())
}

#[test]
fn test_to_string() -> Result<()> {
    let a = arr(vec![1, 2, 3]);
    let result = Array::toString(
        a, Arc::new(int_to_string),
        literal!("array"),
        literal!("["),
        literal!(", "),
        literal!("]"),
        true, 0
    )?;
    assert_eq!(&*result, "array[1, 2, 3]");
    Ok(())
}

#[test]
fn test_to_string_empty() -> Result<()> {
    let a: metamodelica::Array<i32> = arrayFromVec(vec![]);
    let result = Array::toString(
        a, Arc::new(int_to_string),
        literal!("array"),
        literal!("["),
        literal!(", "),
        literal!("]"),
        true, 0
    )?;
    assert_eq!(&*result, "array[]");
    Ok(())
}

#[test]
fn test_to_string_max_length() -> Result<()> {
    let a = arr(vec![1, 2, 3, 4, 5]);
    let result = Array::toString(
        a, Arc::new(int_to_string),
        literal!("array"),
        literal!("["),
        literal!(", "),
        literal!("]"),
        true, 3
    )?;
    assert_eq!(&*result, "array[1, 2, 3, ...]");
    Ok(())
}

#[test]
fn test_to_string_print_empty_false() -> Result<()> {
    let a: metamodelica::Array<i32> = arrayFromVec(vec![]);
    let result = Array::toString(
        a, Arc::new(int_to_string),
        literal!("array"),
        literal!("["),
        literal!(", "),
        literal!("]"),
        false, 0
    )?;
    assert_eq!(&*result, "array");
    Ok(())
}

// transpose returns Array<Array<T>>, not Result
#[test]
fn test_transpose() {
    // 2x3 matrix: [[1,2,3],[4,5,6]] -> transpose is [[1,4],[2,5],[3,6]]
    let row1 = arrayFromVec(vec![1i32, 2, 3]);
    let row2 = arrayFromVec(vec![4i32, 5, 6]);
    let a = arrayFromVec(vec![row1, row2]);
    let result = Array::transpose(a);
    assert_eq!(*result.borrow()[0].borrow(), vec![1, 4]);
    assert_eq!(*result.borrow()[1].borrow(), vec![2, 5]);
    assert_eq!(*result.borrow()[2].borrow(), vec![3, 6]);
}

#[test]
fn test_transpose_empty() {
    let a: metamodelica::Array<metamodelica::Array<i32>> = arrayFromVec(vec![]);
    let result = Array::transpose(a);
    assert!(result.borrow().is_empty());
}

#[test]
fn test_update_index_first() -> Result<()> {
    let a = arr(vec![1, 2, 3]);
    Array::updateIndexFirst(2, 99, a.clone())?;
    assert_eq!(*a.borrow(), vec![1, 99, 3]);
    Ok(())
}

#[test]
fn test_append_to_element() -> Result<()> {
    let lst1 = list![1i32, 2];
    let lst2 = list![3i32];
    let a = arrayFromVec(vec![Arc::clone(&lst1), Arc::clone(&lst2)]);
    let elements = list![4i32, 5];
    let result = Array::appendToElement(1, Arc::clone(&elements), a)?;
    assert_eq!(Arc::clone(&result.borrow()[0]), list![1i32, 2, 4, 5]);
    assert_eq!(Arc::clone(&result.borrow()[1]), list![3i32]);
    Ok(())
}

#[test]
fn test_cons_to_element() -> Result<()> {
    let lst = list![2i32, 3];
    let a = arrayFromVec(vec![Arc::clone(&lst)]);
    let result = Array::consToElement(1, 1i32, a)?;
    assert_eq!(Arc::clone(&result.borrow()[0]), list![1i32, 2, 3]);
    Ok(())
}

// mapNoCopy_1 returns (Array<T>, ArgT), not Result
#[test]
fn test_map_no_copy_1() {
    let a = arr(vec![1, 2, 3]);
    let (result_arr, result_arg) = Array::mapNoCopy_1(
        a,
        Arc::new(|(x, acc): (i32, i32)| Ok((x + 1, acc + 1))),
        0i32
    ).unwrap();
    assert_eq!(*result_arr.borrow(), vec![2, 3, 4]);
    assert_eq!(result_arg, 3);
}

