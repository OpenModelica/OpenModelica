//! `MetaModelica.Dangerous` — bounds-check-skipping / destructive variants.

use std::sync::Arc;
use arcstr::ArcStr;
pub use crate::*;

/// Unsafe array get without bounds checking.
/// Panics in debug mode if index is out of bounds due to Rust's bounds checking on indexing.
pub fn arrayGetNoBoundsChecking<A: Clone>(arr: Array<A>, index: i32) -> A {
    let idx = (index - 1) as usize; // 1-based to 0-based
    let v = arr.borrow();
    // SAFETY: Caller must ensure index is in bounds.
    unsafe { v.get_unchecked(idx).clone() }
}

/// Unsafe array update without bounds checking.
/// Mutates the underlying storage in place; visible through every alias.
pub fn arrayUpdateNoBoundsChecking<A: Clone>(arr: Array<A>, index: i32, new_value: A) -> Array<A> {
    let idx = (index - 1) as usize; // 1-based to 0-based
    {
        let mut v = arr.borrow_mut();
        // SAFETY: Caller must ensure index is in bounds.
        unsafe { *v.get_unchecked_mut(idx) = new_value; }
    }
    arr
}

/// Unsafe array clearing without bounds checking.
/// Mutates the underlying storage in place; visible through every alias.
///
/// This is intentionally a **no-op** in the Rust translation.
///
/// In the original MetaModelica C/GC runtime the function nulled out the
/// slot to release the GC reference early.  In Rust we rely on `Arc<T>`
/// for lifetime management: the slot holds a valid, live `Arc<T>`, and it
/// will be properly decremented when the slot is overwritten or when the
/// backing `Vec<T>` is freed.  Calling `drop_in_place` here and then
/// writing zero bytes would leave an invalid (null) `Arc<T>` in the slot;
/// `Vec::drop` would later try to drop that zeroed value, which dereferences
/// a null pointer → SIGSEGV.
#[inline(always)]
pub fn arrayClearIndex<A: Clone>(_arr: Array<A>, _index: i32) {}

/// Write `val` into an uninitialised slot created by `arrayCreateNoInit`.
///
/// Uses `std::ptr::write` so the garbage bytes that occupy the slot are
/// **not** interpreted as a live `A` value (no drop is called on them).
/// Returns the array so the call can be used as an expression, matching
/// the shape of the regular `arrayUpdate` codegen.
///
/// # Safety
/// * `index` is 1-based and must be in bounds.
/// * The slot at `index - 1` must be genuinely uninitialised — it must
///   never have been written via this function or via a regular assignment.
///   Writing into an already-initialised slot leaks the old value.
pub unsafe fn arrayInitSlot<A>(arr: Array<A>, index: i32, val: A) -> Array<A> {
    {
        let mut borrow = arr.borrow_mut();
        // SAFETY: contract requires index to be in-bounds and the slot uninitialised.
        #[allow(unsafe_op_in_unsafe_fn)]
        let p = unsafe { borrow.get_unchecked_mut((index - 1) as usize) as *mut A };
        #[allow(unsafe_op_in_unsafe_fn)]
        unsafe { std::ptr::write(p, val) };
    }
    arr
}

/// [`arrayInitSlot`] with `arrayUpdate`'s bounds check.
///
/// # Safety
/// As [`arrayInitSlot`], minus the in-bounds requirement.
pub unsafe fn arrayInitSlotChecked<A>(arr: Array<A>, index: i32, val: A) -> Result<Array<A>> {
    if index < 1 || index as usize > arr.borrow().len() {
        return Err("array index out of bounds");
    }
    #[allow(unsafe_op_in_unsafe_fn)]
    Ok(unsafe { arrayInitSlot(arr, index, val) })
}

/// Creates a new array with uninitialized elements.
/// The MetaModelica signature takes a `dummy` argument purely as a type witness;
/// the codegen drops it because Rust generics already carry the element type.
pub fn arrayCreateNoInit<A: Clone>(size: i32) -> Array<A> {
    let mut v = Vec::with_capacity(size as usize);
    // SAFETY:
    // 1. We allocated capacity for `size` elements.
    // 2. Caller guarantees every element is initialized before being read.
    unsafe {
        v.set_len(size as usize);
    }
    arrayFromVec(v)
}
/// Unsafe string get without bounds checking.
///
/// Mirrors `stringGet`'s `ArcStr` parameter (MetaModelica `String` values
/// are `ArcStr` in the translation); `ArcStr` derefs to `str` so
/// `as_bytes()` works directly. This is the *dangerous*, no-bounds-checking
/// variant: it performs an unchecked read and therefore returns the raw
/// `i32` byte value, never a `Result`. The caller is responsible for
/// supplying an in-bounds index — matching the MetaModelica
/// `MetaModelica.Dangerous.stringGetNoBoundsChecking` contract.
pub fn stringGetNoBoundsChecking(str: ArcStr, index: i32) -> i32 {
    let idx = (index - 1) as usize; // 1-based to 0-based
    // SAFETY: Caller must ensure index is in bounds.
    unsafe { (*str.as_bytes().get_unchecked(idx)) as i32 }
}
/// `listReverse`: the uniquely owned prefix is already relinked in place.
pub fn listReverseInPlace<T: Clone>(list: List<T>) -> List<T> {
    list.reverse()
}
/// Appends `second` onto the end of `first` by repointing the last cell when
/// every cell of `first` is uniquely owned; copies `first` otherwise.
pub fn listAppendDestroy<T: Clone>(mut first: List<T>, second: List<T>) -> List<T> {
    let mut p = &first;
    while let Some(cell) = &p.0 {
        if Arc::strong_count(cell) != 1 || Arc::weak_count(cell) != 0 {
            return first.append(&second);
        }
        let ListNode::Cons { tail, .. } = &**cell else { break };
        p = tail;
    }
    let mut cur = &mut first;
    while cur.0.as_ref().is_some_and(|c| matches!(&**c, ListNode::Cons { tail, .. } if tail.0.is_some())) {
        let Some(ListNode::Cons { tail, .. }) = cur.0.as_mut().and_then(Arc::get_mut) else { unreachable!() };
        cur = tail;
    }
    match cur.0.as_mut().and_then(Arc::get_mut) {
        Some(ListNode::Cons { tail, .. }) => *tail = second,
        _ => return second,
    }
    first
}
/// Overwrites the `tail` field of the given Cons cell.
///
/// SAFETY: Mutates the cell behind the `Arc` through a raw pointer, so all
/// other holders of clones of this `Arc` observe the change. Caller must
/// ensure no other thread is reading the cell concurrently. Mirrors the
/// MetaModelica runtime's RML cons-cell mutation.
pub fn listSetRest<T: Clone>(list: List<T>, new_tail: List<T>) -> Result<()> {
    let Some(cell) = &list.0 else { return Err("listSetRest: called on Nil") };
    let ptr = Arc::as_ptr(cell) as *mut ListNode<T>;
    unsafe {
        match &mut *ptr {
            ListNode::Cons { tail, .. } => { *tail = new_tail; Ok(()) }
            ListNode::Nil => Err("listSetRest: called on Nil"),
        }
    }
}
/// Overwrites the `head` field of the given Cons cell. See `listSetRest`
/// for the safety contract.
pub fn listSetFirst<T: Clone>(list: List<T>, new_head: T) -> Result<()> {
    let Some(cell) = &list.0 else { return Err("listSetFirst: called on Nil") };
    let ptr = Arc::as_ptr(cell) as *mut ListNode<T>;
    unsafe {
        match &mut *ptr {
            ListNode::Cons { head, .. } => { *head = new_head; Ok(()) }
            ListNode::Nil => Err("listSetFirst: called on Nil"),
        }
    }
}

#[cfg(test)]
#[allow(unused_imports)]
mod tests {
    use super::*;
    mod dangerous_tests {
        use super::*;

        #[test]
        fn test_array_get_no_bounds_checking() {
            let arr = arrayFromVec(vec![10, 20, 30]);
            // Valid 1-based indices
            assert_eq!(arrayGetNoBoundsChecking(arr.clone(), 1), 10);
            assert_eq!(arrayGetNoBoundsChecking(arr.clone(), 2), 20);
            assert_eq!(arrayGetNoBoundsChecking(arr, 3), 30);
        }

        #[test]
        fn test_array_update_no_bounds_checking() {
            let arr = arrayFromVec(vec![1, 2, 3]);
            arrayUpdateNoBoundsChecking(arr.clone(), 2, 99);
            assert_eq!(*arr.borrow(), vec![1, 99, 3]);
        }

        #[test]
        fn test_array_create_no_init() {
            let arr: Array<i32> = arrayCreateNoInit(5);
            assert_eq!(arr.borrow().len(), 5);
        }

        #[test]
        fn test_string_get_no_bounds_checking() {
            let s = arcstr::literal!("hello");
            assert_eq!(stringGetNoBoundsChecking(s.clone(), 1), b'h' as i32);
            assert_eq!(stringGetNoBoundsChecking(s, 5), b'o' as i32);
        }

        #[test]
        fn test_list_reverse_in_place() {
            use crate::{cons, nil};
            let l = cons(1, cons(2, cons(3, nil())));
            let r = listReverseInPlace(l);
            assert_eq!((&*r).into_iter().cloned().collect::<Vec<_>>(), vec![3, 2, 1]);
            // Empty and singleton edge cases.
            assert_eq!((&*listReverseInPlace(nil::<i32>())).into_iter().count(), 0);
            let single = listReverseInPlace(cons(42, nil()));
            assert_eq!((&*single).into_iter().cloned().collect::<Vec<_>>(), vec![42]);
        }

        #[test]
        fn test_list_append_destroy() {
            use crate::{cons, nil};
            let collect = |l: &crate::List<i32>| (&*l).into_iter().cloned().collect::<Vec<_>>();

            // Normal append: first ++ second.
            let first = cons(1, cons(2, cons(3, nil())));
            let second = cons(4, cons(5, nil()));
            let r = listAppendDestroy(first, second);
            assert_eq!(collect(&r), vec![1, 2, 3, 4, 5]);

            // Empty first → result is second (no cell to repoint).
            let r = listAppendDestroy(nil::<i32>(), cons(7, cons(8, nil())));
            assert_eq!(collect(&r), vec![7, 8]);

            // Empty second → first unchanged.
            let r = listAppendDestroy(cons(1, cons(2, nil())), nil::<i32>());
            assert_eq!(collect(&r), vec![1, 2]);

            // Both empty.
            assert_eq!((&*listAppendDestroy(nil::<i32>(), nil::<i32>())).into_iter().count(), 0);

            // Singleton first.
            let r = listAppendDestroy(cons(1, nil()), cons(2, cons(3, nil())));
            assert_eq!(collect(&r), vec![1, 2, 3]);

            // A shared `first` is copied, not spliced.
            let first = cons(1, cons(2, nil()));
            let alias = first.clone();
            let r = listAppendDestroy(first, cons(3, cons(4, nil())));
            assert_eq!(collect(&r), vec![1, 2, 3, 4]);
            assert_eq!(collect(&alias), vec![1, 2]);
        }
    }
}
