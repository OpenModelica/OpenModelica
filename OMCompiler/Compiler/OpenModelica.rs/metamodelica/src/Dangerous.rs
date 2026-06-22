//! `MetaModelica.Dangerous` — bounds-check-skipping / destructive variants.

use std::sync::Arc;
use anyhow::{Result, bail};
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
/// Reverses a list in place, destructively.
///
/// Walks the spine and repoints each `Cons` cell's `tail` at the cell that
/// preceded it, mutating the cells through a raw pointer (the same
/// dangerous mechanism as `listSetRest`). No new cells are allocated.
///
/// SAFETY / semantics: this mirrors the MetaModelica runtime's destructive
/// `listReverseInPlace`. Every other holder of a clone of these cons cells
/// observes the reversal, and the input list head no longer denotes the
/// same sequence. Only call on a freshly built list that is not shared and
/// not read concurrently.
pub fn listReverseInPlace<T: Clone>(list: Arc<List<T>>) -> Arc<List<T>> {
    let mut prev: Arc<List<T>> = nil();
    let mut curr: Arc<List<T>> = list;
    while let List::Cons { tail, .. } = &*curr {
        let next = tail.clone();
        // SAFETY: see the method doc — the caller guarantees the cells are
        // uniquely owned (freshly built) and not read concurrently.
        unsafe {
            let p = Arc::as_ptr(&curr) as *mut List<T>;
            if let List::Cons { tail, .. } = &mut *p {
                *tail = prev;
            }
        }
        prev = curr;
        curr = next;
    }
    prev
}
/// Destructively appends `second` onto the end of `first`: walks to the last
/// cons cell of `first` and repoints its `tail` at `second`. Allocates
/// nothing. Mirrors the MetaModelica runtime's `listAppendDestroy`
/// (`SimulationRuntime/c/meta/meta_modelica_builtin.c`).
///
/// SAFETY: mutates `first`'s last cell through a raw pointer (the same
/// mechanism as [`listSetRest`]), so every holder of a clone of that cell
/// observes the splice. The MetaModelica contract is that `first` is
/// "destroyed" — the caller must not keep using it as its original sequence,
/// and the cells must not be read concurrently.
pub fn listAppendDestroy<T: Clone>(first: Arc<List<T>>, second: Arc<List<T>>) -> Arc<List<T>> {
    // An empty first list has no cell to repoint; the result is `second`.
    if matches!(&*first, List::Nil) {
        return second;
    }
    // Walk to the last cons cell (the one whose tail is Nil).
    let mut lst = first.clone();
    loop {
        let next = match &*lst {
            List::Cons { tail, .. } if !matches!(&**tail, List::Nil) => tail.clone(),
            _ => break,
        };
        lst = next;
    }
    // SAFETY: see the doc comment — `first`'s cells are destroyed/uniquely
    // held by the caller and not read concurrently.
    unsafe {
        let p = Arc::as_ptr(&lst) as *mut List<T>;
        if let List::Cons { tail, .. } = &mut *p {
            *tail = second;
        }
    }
    first
}
/// Overwrites the `tail` field of the given Cons cell.
///
/// SAFETY: Mutates the cell behind the `Arc` through a raw pointer, so all
/// other holders of clones of this `Arc` observe the change. Caller must
/// ensure no other thread is reading the cell concurrently. Mirrors the
/// MetaModelica runtime's RML cons-cell mutation.
pub fn listSetRest<T: Clone>(list: Arc<List<T>>, new_tail: Arc<List<T>>) -> Result<()> {
    let ptr = Arc::as_ptr(&list) as *mut List<T>;
    unsafe {
        match &mut *ptr {
            List::Cons { tail, .. } => { *tail = new_tail; Ok(()) }
            List::Nil => bail!("listSetRest: called on Nil"),
        }
    }
}
/// Overwrites the `head` field of the given Cons cell. See `listSetRest`
/// for the safety contract.
pub fn listSetFirst<T: Clone>(list: Arc<List<T>>, new_head: T) -> Result<()> {
    let ptr = Arc::as_ptr(&list) as *mut List<T>;
    unsafe {
        match &mut *ptr {
            List::Cons { head, .. } => { *head = new_head; Ok(()) }
            List::Nil => bail!("listSetFirst: called on Nil"),
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

            // Destructive / zero-alloc: the splice mutates the last cell of
            // `first` in place, so a clone of `first`'s head taken *before* the
            // call observes the appended tail afterwards (the cells are shared,
            // not copied).
            let first = cons(1, cons(2, nil()));
            let alias = first.clone();
            let r = listAppendDestroy(first, cons(3, cons(4, nil())));
            assert_eq!(collect(&r), vec![1, 2, 3, 4]);
            assert_eq!(collect(&alias), vec![1, 2, 3, 4]);
        }
    }
}
