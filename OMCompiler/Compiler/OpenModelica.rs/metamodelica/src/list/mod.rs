//! The persistent singly-linked `List<T>` and its builtins.
//! Construction/field macros live in [`macros`].

use std::sync::Arc;
use anyhow::{Result, bail};

#[macro_use]
mod macros;

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
#[derive(Default)]
pub enum List<T: Clone> {
    Cons{head: T, tail: Arc<List<T>>},
    #[default]
    Nil,
}

// Hand-written instead of `#[derive(Default)]`: the derive emits
// `impl<T: Clone + Default> Default for List<T>`, but the empty list is a
// valid default for *any* element type. The spurious `T: Default` bound
// otherwise blocks defaulting containers like `DoubleEnded.MutableList<T>`
// (whose fields are `Mutable<Arc<List<T>>>`) at `T: Clone`.

// Without this, dropping a list is recursive in its length (each node's
// `Arc<List>` field drops the next node from inside its own drop call), so
// releasing a list of a few hundred thousand elements overflows the stack —
// the C runtime never had this problem because its GC frees cells without
// walking the list. Iteratively unlink instead: detach each uniquely-owned
// tail before its node is dropped, so every node drop sees a Nil tail.
impl<T: Clone> Drop for List<T> {
    fn drop(&mut self) {
        // Fast path: Nil, or a node whose tail is already Nil — in
        // particular every node the unlink loop below has detached, so the
        // nested drop it triggers neither allocates nor recurses.
        let List::Cons { tail, .. } = self else { return };
        if matches!(&**tail, List::Nil) {
            return;
        }
        // One shared Nil per unlink walk; replacing a tail with a clone of
        // it is just a refcount increment.
        let nil: Arc<List<T>> = Arc::new(List::Nil);
        let mut cur = std::mem::replace(tail, nil.clone());
        loop {
            match Arc::get_mut(&mut cur) {
                // Sole owner of this node (strong count 1, no weak refs):
                // nothing else can observe the detached tail. Take it, then
                // let the node drop through the fast path above.
                Some(List::Cons { tail, .. }) => {
                    let next = std::mem::replace(tail, nil.clone());
                    cur = next;
                }
                // Nil, or a node shared with another live list: dropping our
                // reference only decrements the refcount and must leave the
                // suffix intact, so stop here.
                _ => break,
            }
        }
    }
}
use List::{Cons, Nil};

pub fn nil<T: Clone>() -> Arc<List<T>> {
    Arc::new(Nil)
}

pub fn cons<T: Clone>(head: T, tail: Arc<List<T>>) -> Arc<List<T>> {
    Arc::new(Cons{head, tail})
}

pub struct ListRefIterator<'a, T: Clone> {
    curr: &'a List<T>,
}

impl<T: Clone> FromIterator<T> for List<T> {
    fn from_iter<I: IntoIterator<Item = T>>(iter: I) -> List<T> {
        let mut buf = nil();
        for item in iter {
            buf = cons(item, buf);
        }
        (*buf.reverse()).clone()
    }
}

impl<'a, T: Clone> IntoIterator for &'a List<T> {
    type Item = &'a T;
    type IntoIter = ListRefIterator<'a, T>;

    // Required method
    fn into_iter(self) -> Self::IntoIter {
       ListRefIterator { curr: self }
    }
}

/*
pub struct ListIterator<T: Clone> {
    curr: Arc<List<T>>,
}

impl<T: Clone> IntoIterator for List<T> {
    type Item = T;
    type IntoIter = ListIterator<T>;

    // Required method
    fn into_iter(self) -> Self::IntoIter {
        ListIterator { curr: Arc::new(self) }
    }
}

impl<T: Clone> Iterator for ListIterator<T> {
    type Item = T; // No Clone needed here!

    fn next(&mut self) -> Option<Self::Item> {
        match *self.curr.clone() {
            // If it's Nil, we are done.
            List::Nil => return None,

            // If it's Cons:
            List::Cons { ref head, ref tail } => {
                self.curr = tail.clone();
                Some(head.clone())
            }
        }
    }
}
*/

impl<'a, T: Clone> Iterator for ListRefIterator<'a, T> {
    type Item = &'a T;

    fn next(&mut self) -> Option<Self::Item> {
        match self.curr {
            Nil => None,
            Cons { head, tail } => {
                self.curr = tail;
                Some(head)
            }
        }
    }
}

impl<T: Clone> List<T> {
    /// Appends lst2 to lst1. O(length(lst1)), O(1) if either list is empty.
    pub fn append(self: &Arc<List<T>>, lst2: &Arc<List<T>>) -> Arc<List<T>> {
        if self.is_empty() {
            return lst2.clone();
        }
        if lst2.is_empty() {
            return self.clone();
        }
        let mut result = lst2.clone();
        for item in &*(self.reverse()) {
            result = cons(item.clone(), result);
        }
        result
    }
    /// Returns the length of a list. O(n).
    pub fn len(&self) -> i32 {
        self.into_iter().count() as i32
    }
    /// Reverses the elements in a list. O(n).
    pub fn reverse(self: &Arc<List<T>>) -> Arc<List<T>> {
        let mut result: Arc<List<T>> = nil();
        for e in &**self {
            result = cons(e.clone(), result);
        }
        result
    }
    /// Gets the element at the given 1-based index. O(index).
    pub fn get(self: &Arc<List<T>>, index: i32) -> Result<T> {
        (&**self).into_iter().nth((index - 1) as usize)
            .cloned()
            .ok_or_else(|| anyhow::anyhow!("Index {} out of bounds for list of length {}", index, self.len()))
    }
    pub fn prepend_reverse(self: &Arc<List<T>>, prefix: &Arc<List<T>>) -> Arc<List<T>> {
        let mut result = self.clone();
        for item in &**prefix {
            result = cons(item.clone(), result);
        }
        result
    }
    /// Deletes the element at the given 1-based index. O(index).
    pub fn delete(self: &Arc<List<T>>, index: i32) -> Result<Arc<List<T>>> {
        if index < 1 {
            bail!("Index must be positive, got {}", index);
        }
        if index == 1 {
            return self.rest();
        }
        let mut result = nil();
        let mut iter = self;
        let mut cur_index = index;
        loop {
            cur_index -= 1;
            let (head,tail) = match &**iter {
                Nil => bail!("Index {} out of bounds for list", index),
                Cons{head, tail} => (head, tail)
            };
            iter = tail;
            if cur_index == 0 {
                return Ok(iter.prepend_reverse(&result));
            }
            result = cons(head.clone(), result);
        }
    }
}

impl<T: Clone> List<T> {
    pub fn new(item: T) -> Arc<List<T>> {
        Arc::new(Cons{head: item, tail: nil()})
    }
    pub fn cons(self: Arc<List<T>>, item: T) -> Arc<List<T>> {
        Arc::new(Cons{head: item, tail: self})
    }
    /// Gets the first element. O(1).
    /// Fails if the list is empty.
    pub fn head(self: &Arc<List<T>>) -> Result<&T> {
        match &**self {
            Nil => bail!("Cannot get head of empty list"),
            Cons{head, ..} => Ok(head),
        }
    }
    /// Returns all elements except the first. O(1).
    /// Fails if the list is empty.
    pub fn rest(self: &Arc<List<T>>) -> Result<Arc<List<T>>> {
        match &**self {
            Nil => bail!("Cannot get rest of empty list"),
            Cons{tail, ..} => Ok(tail.clone()),
        }
    }
    /// Returns true if the list is empty. O(1).
    pub fn is_empty(self: &Arc<List<T>>) -> bool {
        match **self {
            Nil => true,
            _ => false
        }
    }
}



impl<T: PartialEq + Clone> List<T> {
    /// Checks if an element is a member of the list. O(n).
    /// Uses PartialEq for comparison.
    pub fn contains(self: &Arc<List<T>>, element: &T) -> bool {
        for item in &**self {
            if element.eq(item) { return true; }
        }
        false
    }
}

pub fn listAppend<T: Clone>(lst1: Arc<List<T>>, lst2: Arc<List<T>>) -> Arc<List<T>> {
    lst1.append(&lst2)
}

/// Free-function form of the `listReverse` builtin (the `List::reverse` method).
/// Direct calls lower to `x.reverse()`, but when `listReverse` is used as a
/// first-class value (e.g. `Array.map(arr, listReverse)`) there must be a real
/// function path to reference — methods cannot be named as `fn` items. Codegen
/// emits `fnptr!(metamodelica::listReverse, _)` for that case.
pub fn listReverse<T: Clone>(lst: Arc<List<T>>) -> Arc<List<T>> {
    lst.reverse()
}

pub fn listMember<T: Clone+PartialEq>(element: T, lst: Arc<List<T>>) -> bool {
    lst.contains(&element)
}

pub fn listHead<T: Clone>(lst: Arc<List<T>>) -> Result<T> {
    let Cons{head, ..} = &*lst else {bail!("Cannot get head of empty list")};
    Ok(head.clone())
}

pub fn listGet<T: Clone>(lst: Arc<List<T>>, i: i32) -> Result<T> {
    lst.get(i)
}

pub fn listEmpty<T: Clone>(lst: Arc<List<T>>) -> bool {
    lst.is_empty()
}

pub fn listDelete<T: Clone>(lst: Arc<List<T>>, index: i32) -> Result<Arc<List<T>>> {
    lst.delete(index)
}

pub fn listRest<T: Clone>(lst: Arc<List<T>>) -> Result<Arc<List<T>>> {
    match &*lst {
        Nil => bail!("Cannot get rest of empty list"),
        Cons{tail, ..} => Ok(tail.clone()),
    }
}

pub fn listLength<T: Clone>(lst: Arc<List<T>>) -> i32 {
    lst.len()
}

#[cfg(test)]
#[allow(unused_imports)]
mod tests {
    use super::*;
    use crate::*;
    use std::sync::Arc;
    use std::rc::Rc;
    use arcstr::{literal, ArcStr};
    mod list_function_tests {
        use super::*;

        #[test]
        fn test_list_append() {
            let a = list![1, 2, 3];
            let b = list![4, 5];
            let result = a.append(&b);
            assert_eq!(result, list![1, 2, 3, 4, 5]);

            // Empty list cases
            let empty: Arc<List<i32>> = nil();
            assert_eq!(empty.append(&b), b);
            assert_eq!(a.append(&empty), a);
        }

        #[test]
        fn test_list_reverse() {
            let lst = list![1, 2, 3, 4, 5];
            let result = lst.reverse();
            assert_eq!(result, list![5, 4, 3, 2, 1]);

            let empty: Arc<List<i32>> = nil();
            assert_eq!(empty.reverse(), nil());
        }

        #[test]
        fn test_list_length() {
            let lst = list![1, 2, 3];
            assert_eq!(lst.len(), 3);
            let empty: Arc<List<i32>> = nil();
            assert_eq!(empty.len(), 0);
        }

        #[test]
        fn test_list_member() {
            let lst = list![1, 2, 3];
            assert!(lst.contains(&2));
            assert!(!lst.contains(&4));
        }

        #[test]
        fn test_list_get() {
            let lst = list![10, 20, 30];
            assert_eq!(lst.get(1).unwrap(), 10);
            assert_eq!(lst.get(2).unwrap(), 20);
            assert_eq!(lst.get(3).unwrap(), 30);
            assert!(lst.get(0).is_err());
            assert!(lst.get(4).is_err());
        }

        #[test]
        fn test_list_rest() {
            let lst = list![1, 2, 3];
            let result = lst.rest().unwrap().clone();
            assert_eq!(result, list![2, 3]);

            let single = list![1];
            assert!(single.rest().unwrap().is_empty());

            let empty: Arc<List<i32>> = nil();
            assert!(empty.rest().is_err());
        }

        #[test]
        fn test_list_head() {
            let lst = list![1, 2, 3];
            assert_eq!(lst.head().unwrap().clone(), 1);

            let empty: Arc<List<i32>> = nil();
            assert!(empty.head().is_err());
        }

        #[test]
        fn test_list_delete() {
            let lst = list![1, 2, 3, 4];
            assert_eq!(lst.delete(1).unwrap(), list![2, 3, 4]);
            assert_eq!(lst.delete(2).unwrap(), list![1, 3, 4]);
            assert_eq!(lst.delete(4).unwrap(), list![1, 2, 3]);
        }

        #[test]
        fn test_list_empty() {
            let lst = list![1, 2, 3];
            assert!(!lst.is_empty());

            let empty: Arc<List<i32>> = nil();
            assert!(empty.is_empty());
        }

        #[test]
        fn test_cons() {
            let lst = list![2, 3];
            let result = cons(1, lst);
            assert_eq!(result, list![1, 2, 3]);

            let empty: Arc<List<i32>> = nil();
            let result = cons(42, empty);
            assert_eq!(result, List::new(42));
        }

        #[test]
        fn test_list_reverse2() -> () {
            let lst1 = list![1,2,3,4];
            let lst2 = lst1.reverse();
            let lst3 = lst2.reverse();
            assert_eq!(lst1, lst3);
            assert!(lst1 != lst2);
        }
    }
}
