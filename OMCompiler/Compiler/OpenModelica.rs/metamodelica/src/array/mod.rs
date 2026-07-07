//! Mutable (aliasing) `Array<T>` builtins. Read-only constant tables
//! use [`static_array::StaticArray`].

use std::sync::Arc;
use std::rc::Rc;
use std::cell::RefCell;
use anyhow::{Result, bail};
use crate::{Array, list::List};

pub mod static_array;
pub use static_array::*;

/// Wraps a `Vec<T>` into a fresh MetaModelica `Array<T>`.
#[inline]
pub fn arrayFromVec<A>(v: Vec<A>) -> Array<A> {
    Rc::new(RefCell::new(v))
}

// All array fns take `Array<A>` by value: cloning an `Rc` is one atomic-free
// refcount bump, so the by-value convention matches how `Arc<List<A>>` is
// handled elsewhere and lets generated call sites pass `arr.clone()` directly
// without needing an explicit `&` prefix.

/// Returns the length of the array. O(1).
pub fn arrayLength<A>(arr: Array<A>) -> i32 {
    arr.borrow().len() as i32
}

/// Returns true if the array is empty. O(1).
pub fn arrayEmpty<A>(arr: Array<A>) -> bool {
    arr.borrow().is_empty()
}

/// Gets the element at the given 1-based index. O(1).
pub fn arrayGet<A: Clone>(arr: Array<A>, index: i32) -> Result<A> {
    let idx = (index - 1) as usize; // 1-based to 0-based
    let v = arr.borrow();
    v.get(idx)
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("Index {} out of bounds for array of length {}", index, v.len()))
}

/// Creates a new array of the given size, initialized with initialValue. O(size).
pub fn arrayCreate<A: Clone>(size: i32, initial_value: A) -> Array<A> {
    if size <= 0 {
        return arrayFromVec(Vec::new());
    }
    arrayFromVec(vec![initial_value; size as usize])
}

/// Creates a new array of the given size, initialized with `A::default()`.
///
/// Used by codegen to lower `arrayCreateNoInit(size, dummy)` when the MM
/// dummy expression is a bare reference to a function-scope variable that
/// is never assigned at the call point (a common MM idiom: declare a
/// `protected SBInterval dummyi;` and pass it as the type witness only).
/// Such a reference cannot be forwarded as a Rust value, so we discard it
/// and rely on the `Default` impl for the element type instead. Types that
/// lack a `Default` impl will fail to compile at the use site — the fix is
/// to add a sensible `Default` for that type (often the "empty" or "first
/// variant" form).
pub fn arrayCreateDefault<A: Clone + Default>(size: i32) -> Array<A> {
    if size <= 0 {
        return arrayFromVec(Vec::new());
    }
    arrayFromVec(vec![A::default(); size as usize])
}

/// Converts an array to a list. O(n).
pub fn arrayList<A: Clone>(arr: Array<A>) -> Arc<List<A>> {
    let mut result = Arc::new(List::Nil);
    for item in arr.borrow().iter().rev().cloned() {
        result = List::cons(result, item);
    }
    result
}

/// Converts a list to an array. O(n).
pub fn listArray<A: Clone>(lst: Arc<List<A>>) -> Array<A> {
    let mut result = Vec::new();
    for item in &*lst {
        result.push(item.clone());
    }
    arrayFromVec(result)
}

/// Updates the value at the given 1-based index. O(1).
/// Mutates the underlying storage; the change is visible through every alias
/// of the same array. Returns the same `Rc` (a cheap clone) so call sites can
/// chain or reassign as the MetaModelica signature suggests.
pub fn arrayUpdate<A: Clone>(arr: Array<A>, index: i32, new_value: A) -> Result<Array<A>> {
    let idx = (index - 1) as usize; // 1-based to 0-based
    {
        let mut v = arr.borrow_mut();
        let len = v.len();
        if idx >= len {
            bail!("Index {} out of bounds for array of length {}", index, len);
        }
        v[idx] = new_value;
    }
    Ok(arr)
}

/// Creates a (deep, by-element) copy of the array. O(n).
/// The returned array does NOT share storage with the input.
pub fn arrayCopy<A: Clone>(arr: Array<A>) -> Array<A> {
    arrayFromVec(arr.borrow().clone())
}

/// Appends arr2 to arr1, creating a new array. O(length(arr1) + length(arr2)).
/// The result does not share storage with either input.
pub fn arrayAppend<A: Clone>(arr1: Array<A>, arr2: Array<A>) -> Array<A> {
    let mut result = arr1.borrow().clone();
    result.extend(arr2.borrow().iter().cloned());
    arrayFromVec(result)
}

#[cfg(test)]
#[allow(unused_imports)]
mod tests {
    use super::*;
    use crate::*;
    use std::sync::Arc;
    use std::rc::Rc;
    use arcstr::{literal, ArcStr};
    mod array_function_tests {
        use super::*;

        fn arr<A>(v: Vec<A>) -> Array<A> { arrayFromVec(v) }

        #[test]
        fn test_array_length() {
            assert_eq!(arrayLength(arr(vec![1, 2, 3])), 3);
            assert_eq!(arrayLength(arr::<i32>(vec![])), 0);
        }

        #[test]
        fn test_array_empty() {
            assert!(!arrayEmpty(arr(vec![1, 2, 3])));
            assert!(arrayEmpty(arr::<i32>(vec![])));
        }

        #[test]
        fn test_array_get() {
            let a = arr(vec![10, 20, 30]);
            assert_eq!(arrayGet(a.clone(), 1).unwrap(), 10);
            assert_eq!(arrayGet(a.clone(), 2).unwrap(), 20);
            assert_eq!(arrayGet(a.clone(), 3).unwrap(), 30);
            assert!(arrayGet(a.clone(), 0).is_err());
            assert!(arrayGet(a, 4).is_err());
        }

        #[test]
        fn test_array_create() {
            let a = arrayCreate(5, 0);
            assert_eq!(*a.borrow(), vec![0, 0, 0, 0, 0]);
            let empty: Array<i32> = arrayCreate(0, 42);
            assert!(empty.borrow().is_empty());
        }

        #[test]
        fn test_array_list() {
            let a = arr(vec![1, 2, 3]);
            let lst = arrayList(a);
            assert_eq!(lst, list![1, 2, 3]);
        }

        #[test]
        fn test_list_array() {
            let lst = list![1, 2, 3];
            let a = listArray(lst);
            assert_eq!(*a.borrow(), vec![1, 2, 3]);
        }

        #[test]
        fn test_array_update() {
            let a = arr(vec![1, 2, 3]);
            arrayUpdate(a.clone(), 2, 99).unwrap();
            assert_eq!(*a.borrow(), vec![1, 99, 3]);
            assert!(arrayUpdate(a.clone(), 0, 99).is_err());
            assert!(arrayUpdate(a.clone(), 4, 99).is_err());

            // Aliasing semantics: updates visible through every clone of the Rc.
            let alias = a.clone();
            arrayUpdate(a.clone(), 1, 100).unwrap();
            assert_eq!(*alias.borrow(), vec![100, 99, 3]);
        }

        #[test]
        fn test_array_copy() {
            let a = arr(vec![1, 2, 3]);
            let copy = arrayCopy(a.clone());
            assert_eq!(*copy.borrow(), vec![1, 2, 3]);
            // arrayCopy must NOT share storage with the source.
            arrayUpdate(a, 1, 99).unwrap();
            assert_eq!(*copy.borrow(), vec![1, 2, 3]);
        }

        #[test]
        fn test_array_append() {
            let a = arr(vec![1, 2]);
            let b = arr(vec![3, 4]);
            assert_eq!(*arrayAppend(a.clone(), b.clone()).borrow(), vec![1, 2, 3, 4]);

            let empty: Array<i32> = arr(vec![]);
            assert_eq!(*arrayAppend(empty.clone(), b).borrow(), vec![3, 4]);
            assert_eq!(*arrayAppend(a, empty).borrow(), vec![1, 2]);
        }
    }
}
