use anyhow::Result;
use std::sync::Arc;
use metamodelica::*;
use crate::DoubleEnded;

#[test]
fn test_new() {
    let de = DoubleEnded::new(42);
    assert_eq!(DoubleEnded::length(de), 1);
}

#[test]
fn test_empty() {
    let de = DoubleEnded::empty(0i32);
    assert_eq!(DoubleEnded::length(de), 0);
}

#[test]
fn test_push_back() {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2).unwrap();
    DoubleEnded::push_back(de.clone(), 3).unwrap();
    assert_eq!(DoubleEnded::length(de), 3);
}

#[test]
fn test_push_back_empty() -> Result<()> {
    let de = DoubleEnded::empty(0i32);
    DoubleEnded::push_back(de.clone(), 42)?;
    assert_eq!(DoubleEnded::length(de.clone()), 1);
    let val = DoubleEnded::pop_front(de)?;
    assert_eq!(val, 42);
    Ok(())
}

#[test]
fn test_push_front() -> Result<()> {
    let de = DoubleEnded::new(2);
    DoubleEnded::push_front(de.clone(), 1);
    DoubleEnded::push_front(de.clone(), 0);
    assert_eq!(DoubleEnded::length(de.clone()), 3);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 0);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 1);
    assert_eq!(DoubleEnded::pop_front(de)?, 2);
    Ok(())
}

#[test]
fn test_push_front_empty() -> Result<()> {
    let de = DoubleEnded::empty(0i32);
    DoubleEnded::push_front(de.clone(), 42);
    assert_eq!(DoubleEnded::length(de.clone()), 1);
    let val = DoubleEnded::pop_front(de)?;
    assert_eq!(val, 42);
    Ok(())
}

#[test]
fn test_pop_front() -> Result<()> {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2)?;
    DoubleEnded::push_back(de.clone(), 3)?;
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 1);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 2);
    assert_eq!(DoubleEnded::pop_front(de)?, 3);
    Ok(())
}

#[test]
fn test_pop_front_last_element() -> Result<()> {
    let de = DoubleEnded::new(42);
    let val = DoubleEnded::pop_front(de.clone())?;
    assert_eq!(val, 42);
    assert_eq!(DoubleEnded::length(de), 0);
    Ok(())
}

#[test]
fn test_pop_front_empty_fails() {
    let de = DoubleEnded::empty(0i32);
    let result = DoubleEnded::pop_front(de);
    assert!(result.is_err());
}

#[test]
fn test_from_list() -> Result<()> {
    let lst = list![1i32, 2, 3];
    let de = DoubleEnded::fromList(Arc::clone(&lst))?;
    assert_eq!(DoubleEnded::length(de.clone()), 3);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 1);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 2);
    assert_eq!(DoubleEnded::pop_front(de)?, 3);
    Ok(())
}

#[test]
fn test_from_list_empty() -> Result<()> {
    let lst: Arc<List<i32>> = nil();
    let de = DoubleEnded::fromList(lst)?;
    assert_eq!(DoubleEnded::length(de), 0);
    Ok(())
}

#[test]
fn test_length() -> Result<()> {
    let de = DoubleEnded::new(1);
    assert_eq!(DoubleEnded::length(de.clone()), 1);
    DoubleEnded::push_back(de.clone(), 2)?;
    assert_eq!(DoubleEnded::length(de.clone()), 2);
    DoubleEnded::pop_front(de.clone())?;
    assert_eq!(DoubleEnded::length(de), 1);
    Ok(())
}

#[test]
fn test_clear() -> Result<()> {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2)?;
    DoubleEnded::clear(de.clone());
    assert_eq!(DoubleEnded::length(de.clone()), 0);
    let result = DoubleEnded::pop_front(de);
    assert!(result.is_err());
    Ok(())
}

#[test]
fn test_to_list_and_clear() -> Result<()> {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2)?;
    DoubleEnded::push_back(de.clone(), 3)?;
    let prepend: Arc<List<i32>> = list![0i32];
    let result = DoubleEnded::toListAndClear(de.clone(), Arc::clone(&prepend))?;
    assert_eq!(result.get(1)?, 1);
    assert_eq!(result.get(2)?, 2);
    assert_eq!(result.get(3)?, 3);
    assert_eq!(result.get(4)?, 0);
    assert_eq!(DoubleEnded::length(de), 0);
    Ok(())
}

#[test]
fn test_to_list_and_clear_empty() {
    let de = DoubleEnded::empty(0i32);
    let prepend = list![1i32, 2];
    let result = DoubleEnded::toListAndClear(de, Arc::clone(&prepend)).unwrap();
    assert_eq!(result, prepend);
}

#[test]
fn test_to_list_no_copy_no_clear() -> Result<()> {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2)?;
    let result = DoubleEnded::toListNoCopyNoClear(de.clone());
    assert_eq!(result.get(1)?, 1);
    assert_eq!(result.get(2)?, 2);
    assert_eq!(DoubleEnded::length(de), 2);
    Ok(())
}

#[test]
fn test_current_back_cell() -> Result<()> {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2)?;
    let back = DoubleEnded::currentBackCell(de);
    assert_eq!(back.get(1)?, 2);
    Ok(())
}

#[test]
fn test_push_list_back() -> Result<()> {
    let de = DoubleEnded::new(1);
    let lst = list![2i32, 3, 4];
    DoubleEnded::push_list_back(de.clone(), Arc::clone(&lst))?;
    assert_eq!(DoubleEnded::length(de.clone()), 4);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 1);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 2);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 3);
    assert_eq!(DoubleEnded::pop_front(de)?, 4);
    Ok(())
}

#[test]
fn test_push_list_back_empty_de() {
    let de = DoubleEnded::empty(0i32);
    let lst = list![1i32, 2];
    DoubleEnded::push_list_back(de.clone(), Arc::clone(&lst)).unwrap();
    assert_eq!(DoubleEnded::length(de), 2);
}

#[test]
fn test_push_list_back_empty_list() {
    let de = DoubleEnded::new(1);
    let lst: Arc<List<i32>> = nil();
    DoubleEnded::push_list_back(de.clone(), lst).unwrap();
    assert_eq!(DoubleEnded::length(de), 1);
}

#[test]
fn test_push_list_front() -> Result<()> {
    let de = DoubleEnded::new(4);
    let lst = list![1i32, 2, 3];
    DoubleEnded::push_list_front(de.clone(), Arc::clone(&lst))?;
    assert_eq!(DoubleEnded::length(de.clone()), 4);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 1);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 2);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 3);
    assert_eq!(DoubleEnded::pop_front(de)?, 4);
    Ok(())
}

#[test]
fn test_push_list_front_empty_de() -> Result<()> {
    let de = DoubleEnded::empty(0i32);
    let lst = list![1i32, 2];
    DoubleEnded::push_list_front(de.clone(), Arc::clone(&lst))?;
    assert_eq!(DoubleEnded::length(de), 2);
    Ok(())
}

#[test]
fn test_push_list_front_empty_list() -> Result<()> {
    let de = DoubleEnded::new(1);
    let lst: Arc<List<i32>> = nil();
    DoubleEnded::push_list_front(de.clone(), lst)?;
    assert_eq!(DoubleEnded::length(de), 1);
    Ok(())
}

#[test]
fn test_map_fold_no_copy() -> Result<()> {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2)?;
    DoubleEnded::push_back(de.clone(), 3)?;
    let result = DoubleEnded::mapFoldNoCopy(
        de.clone(),
        Arc::new(|x, acc: i32| Ok((x * 10, acc + x))),
        0i32
    )?;
    assert_eq!(result, 6);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 10);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 20);
    assert_eq!(DoubleEnded::pop_front(de)?, 30);
    Ok(())
}

#[test]
fn test_map_no_copy_1() -> Result<()> {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2)?;
    DoubleEnded::push_back(de.clone(), 3)?;
    DoubleEnded::mapNoCopy_1(
        de.clone(),
        Arc::new(|x, _arg: i32| Ok(x * 2)),
        0i32
    )?;
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 2);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 4);
    assert_eq!(DoubleEnded::pop_front(de)?, 6);
    Ok(())
}

// push_front to non-empty must NOT update the back pointer — back still
// points to the original last node, so a subsequent push_back can link to it.
#[test]
fn test_push_front_does_not_change_back() -> Result<()> {
    let de = DoubleEnded::new(2);     // front = back = [2]
    DoubleEnded::push_front(de.clone(), 1); // front = [1,2], back = [2]
    DoubleEnded::push_back(de.clone(), 3);  // back links 2→3; back = [3]
    assert_eq!(DoubleEnded::length(de.clone()), 3);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 1);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 2);
    assert_eq!(DoubleEnded::pop_front(de)?, 3);
    Ok(())
}

// Multiple push_fronts followed by push_back — back must still be reachable.
#[test]
fn test_multiple_push_front_then_push_back() -> Result<()> {
    let de = DoubleEnded::new(3);
    DoubleEnded::push_front(de.clone(), 2);
    DoubleEnded::push_front(de.clone(), 1);
    // front=[1,2,3], back=cons(3,nil) — the node we started with
    DoubleEnded::push_back(de.clone(), 4); // must link correctly through back
    assert_eq!(DoubleEnded::length(de.clone()), 4);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 1);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 2);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 3);
    assert_eq!(DoubleEnded::pop_front(de)?, 4);
    Ok(())
}

// pop_front down to a single element — back must still point to that element.
// A subsequent push_back must therefore succeed without losing elements.
#[test]
fn test_pop_to_one_then_push_back() -> Result<()> {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2)?;
    DoubleEnded::push_back(de.clone(), 3)?;
    // pop two off the front
    DoubleEnded::pop_front(de.clone())?; // pops 1
    DoubleEnded::pop_front(de.clone())?; // pops 2 — length==1, back still points to [3]
    DoubleEnded::push_back(de.clone(), 4); // must link to the remaining [3] node
    assert_eq!(DoubleEnded::length(de.clone()), 2);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 3);
    assert_eq!(DoubleEnded::pop_front(de)?, 4);
    Ok(())
}

// toListAndClear with nil prepend must not call listSetRest on back — the
// back node's rest is already nil, and back must simply remain untouched.
#[test]
fn test_to_list_and_clear_nil_prepend() -> Result<()> {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2)?;
    let result = DoubleEnded::toListAndClear(de.clone(), Arc::clone(&nil()))?;
    assert_eq!(result.get(1)?, 1);
    assert_eq!(result.get(2)?, 2);
    assert_eq!(result.len(), 2);
    assert_eq!(DoubleEnded::length(de), 0);
    Ok(())
}

// toListAndClear after push_front + push_back: back is the original node,
// not the one prepended by push_front.
#[test]
fn test_to_list_and_clear_after_push_front_push_back() -> Result<()> {
    let de = DoubleEnded::new(2);
    DoubleEnded::push_front(de.clone(), 1); // front=[1,2], back=cons(2,nil)
    DoubleEnded::push_back(de.clone(), 3);  // back becomes cons(3,nil)
    let tail: Arc<List<i32>> = list![99i32];
    let result = DoubleEnded::toListAndClear(de.clone(), Arc::clone(&tail))?;
    assert_eq!(result.len(), 4);
    assert_eq!(result.get(1)?, 1);
    assert_eq!(result.get(2)?, 2);
    assert_eq!(result.get(3)?, 3);
    assert_eq!(result.get(4)?, 99);
    assert_eq!(DoubleEnded::length(de), 0);
    Ok(())
}

// clear resets the structure completely; push_back afterwards must work.
#[test]
fn test_clear_then_push_back() -> Result<()> {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2)?;
    DoubleEnded::clear(de.clone());
    assert_eq!(DoubleEnded::length(de.clone()), 0);
    DoubleEnded::push_back(de.clone(), 10)?;
    DoubleEnded::push_back(de.clone(), 20)?;
    assert_eq!(DoubleEnded::length(de.clone()), 2);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 10);
    assert_eq!(DoubleEnded::pop_front(de)?, 20);
    Ok(())
}

// push_list_back to an empty DE: front and back must both be set correctly.
#[test]
fn test_push_list_back_to_empty_then_pop_all() -> Result<()> {
    let de = DoubleEnded::empty(0i32);
    let lst = list![10i32, 20, 30];
    DoubleEnded::push_list_back(de.clone(), Arc::clone(&lst))?;
    assert_eq!(DoubleEnded::length(de.clone()), 3);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 10);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 20);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 30);
    assert!(DoubleEnded::pop_front(de).is_err());
    Ok(())
}

// push_list_front to a non-empty DE: the old front must become the tail of
// the newly prepended nodes.
#[test]
fn test_push_list_front_order() -> Result<()> {
    let de = DoubleEnded::new(4);
    let lst = list![1i32, 2, 3];
    DoubleEnded::push_list_front(de.clone(), Arc::clone(&lst))?;
    assert_eq!(DoubleEnded::length(de.clone()), 4);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 1);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 2);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 3);
    assert_eq!(DoubleEnded::pop_front(de)?, 4);
    Ok(())
}

// push_list_front to non-empty must NOT update back — back pointer stays on
// the original last node, so push_back still works afterwards.
#[test]
fn test_push_list_front_does_not_change_back() -> Result<()> {
    let de = DoubleEnded::new(3);     // back = cons(3,nil)
    let lst = list![1i32, 2];
    DoubleEnded::push_list_front(de.clone(), Arc::clone(&lst))?; // back unchanged
    DoubleEnded::push_back(de.clone(), 4); // must link through back=cons(3,nil)
    assert_eq!(DoubleEnded::length(de.clone()), 4);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 1);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 2);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 3);
    assert_eq!(DoubleEnded::pop_front(de)?, 4);
    Ok(())
}

// mapFoldNoCopy on an empty DE must return the initial accumulator unchanged.
#[test]
fn test_map_fold_no_copy_empty() -> Result<()> {
    let de = DoubleEnded::empty(0i32);
    let result = DoubleEnded::mapFoldNoCopy(
        de.clone(),
        Arc::new(|x: i32, acc: i32| Ok((x * 2, acc + 1))),
        42i32,
    )?;
    assert_eq!(result, 42);
    assert_eq!(DoubleEnded::length(de), 0);
    Ok(())
}

// fromList builds an independent copy; popping all elements leaves the list
// in the correct empty state.
#[test]
fn test_from_list_pop_all() -> Result<()> {
    let lst = list![5i32, 6, 7];
    let de = DoubleEnded::fromList(Arc::clone(&lst))?;
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 5);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 6);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 7);
    assert!(DoubleEnded::pop_front(de.clone()).is_err());
    assert_eq!(DoubleEnded::length(de), 0);
    Ok(())
}

// toListNoCopyNoClear must leave the DE fully operational afterwards.
#[test]
fn test_to_list_no_copy_no_clear_then_pop() -> Result<()> {
    let de = DoubleEnded::new(1);
    DoubleEnded::push_back(de.clone(), 2)?;
    let _snapshot = DoubleEnded::toListNoCopyNoClear(de.clone());
    // DE must still be intact
    assert_eq!(DoubleEnded::length(de.clone()), 2);
    assert_eq!(DoubleEnded::pop_front(de.clone())?, 1);
    assert_eq!(DoubleEnded::pop_front(de)?, 2);
    Ok(())
}
