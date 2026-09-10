//! The persistent singly-linked `List<T>` and its builtins.
//! Construction/field macros live in [`macros`].

use std::sync::Arc;
use std::hash::{Hash, Hasher};
use std::cmp::Ordering;
use crate::Result;

#[macro_use]
mod macros;

/// Heap cell of a [`List`]. `Nil` is never allocated: the empty list is
/// `List(None)`, and `Deref` hands out a static `Nil` for it.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum ListNode<T: Clone> {
    Cons{head: T, tail: List<T>},
    Nil,
}

pub struct List<T: Clone>(pub(crate) Option<Arc<ListNode<T>>>);

// What the auto traits derive, stated explicitly so the solver need not
// recurse through the cell type (it hit the recursion limit downstream).
unsafe impl<T: Clone + Send + Sync> Send for List<T> {}
unsafe impl<T: Clone + Send + Sync> Sync for List<T> {}

use ListNode::{Cons, Nil};

impl<T: Clone> List<T> {
    #[inline]
    pub fn iter(&self) -> ListRefIterator<'_, T> {
        ListRefIterator { curr: self.0.as_deref() }
    }
    #[inline]
    fn node(&self) -> Option<&ListNode<T>> {
        self.0.as_deref()
    }
}

impl<T: Clone + 'static> List<T> {
    const NIL: &'static ListNode<T> = &Nil;
}

impl<T: Clone + 'static> std::ops::Deref for List<T> {
    type Target = ListNode<T>;
    #[inline]
    fn deref(&self) -> &ListNode<T> {
        match &self.0 {
            Some(a) => a,
            None => Self::NIL,
        }
    }
}

impl<T: Clone + 'static> AsRef<ListNode<T>> for List<T> {
    #[inline]
    fn as_ref(&self) -> &ListNode<T> { self }
}

impl<T: Clone> Clone for List<T> {
    #[inline]
    fn clone(&self) -> Self { List(self.0.clone()) }
}

impl<T: Clone> Default for List<T> {
    #[inline]
    fn default() -> Self { List(None) }
}

impl<T: Clone + std::fmt::Debug> std::fmt::Debug for List<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_list().entries(self).finish()
    }
}

impl<T: Clone + PartialEq> PartialEq for List<T> {
    fn eq(&self, other: &Self) -> bool {
        let (mut a, mut b) = (self, other);
        loop {
            match (&a.0, &b.0) {
                (None, None) => return true,
                (Some(x), Some(y)) => {
                    if Arc::ptr_eq(x, y) { return true; }
                    match (&**x, &**y) {
                        (Cons{head: h1, tail: t1}, Cons{head: h2, tail: t2}) => {
                            if h1 != h2 { return false; }
                            a = t1; b = t2;
                        }
                        _ => return false,
                    }
                }
                _ => return false,
            }
        }
    }
}
impl<T: Clone + Eq> Eq for List<T> {}

// Nil sorts after Cons, as the derived enum ordering did.
impl<T: Clone + Ord> Ord for List<T> {
    fn cmp(&self, other: &Self) -> Ordering {
        let (mut a, mut b) = (self, other);
        loop {
            match (&a.0, &b.0) {
                (None, None) => return Ordering::Equal,
                (None, Some(_)) => return Ordering::Greater,
                (Some(_), None) => return Ordering::Less,
                (Some(x), Some(y)) => {
                    if Arc::ptr_eq(x, y) { return Ordering::Equal; }
                    match (&**x, &**y) {
                        (Cons{head: h1, tail: t1}, Cons{head: h2, tail: t2}) => {
                            match h1.cmp(h2) {
                                Ordering::Equal => { a = t1; b = t2; }
                                o => return o,
                            }
                        }
                        (Cons{..}, Nil) => return Ordering::Less,
                        (Nil, Cons{..}) => return Ordering::Greater,
                        (Nil, Nil) => return Ordering::Equal,
                    }
                }
            }
        }
    }
}
impl<T: Clone + PartialOrd> PartialOrd for List<T> {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        let (mut a, mut b) = (self, other);
        loop {
            match (&a.0, &b.0) {
                (None, None) => return Some(Ordering::Equal),
                (None, Some(_)) => return Some(Ordering::Greater),
                (Some(_), None) => return Some(Ordering::Less),
                (Some(x), Some(y)) => {
                    if Arc::ptr_eq(x, y) { return Some(Ordering::Equal); }
                    match (&**x, &**y) {
                        (Cons{head: h1, tail: t1}, Cons{head: h2, tail: t2}) => {
                            match h1.partial_cmp(h2) {
                                Some(Ordering::Equal) => { a = t1; b = t2; }
                                o => return o,
                            }
                        }
                        (Cons{..}, Nil) => return Some(Ordering::Less),
                        (Nil, Cons{..}) => return Some(Ordering::Greater),
                        (Nil, Nil) => return Some(Ordering::Equal),
                    }
                }
            }
        }
    }
}

impl<T: Clone + Hash> Hash for List<T> {
    fn hash<H: Hasher>(&self, state: &mut H) {
        let mut n = 0usize;
        for e in self {
            e.hash(state);
            n += 1;
        }
        state.write_usize(n);
    }
}

// Iterative: a recursive drop is one stack frame per element. Only the
// uniquely owned prefix is unlinked; a shared suffix just loses a reference.
impl<T: Clone> Drop for List<T> {
    #[inline]
    fn drop(&mut self) {
        if let Some(node) = &self.0 && Arc::strong_count(node) == 1 {
            self.unlink();
        }
    }
}

impl<T: Clone> List<T> {
    #[inline(never)]
    fn unlink(&mut self) {
        let mut cur = self.0.take();
        while let Some(mut node) = cur {
            match Arc::get_mut(&mut node) {
                Some(Cons { tail, .. }) => cur = tail.0.take(),
                _ => break,
            }
        }
    }
}

#[inline]
pub fn nil<T: Clone>() -> List<T> {
    List(None)
}

#[inline]
pub fn cons<T: Clone>(head: T, tail: List<T>) -> List<T> {
    List(Some(Arc::new(Cons{head, tail})))
}

pub struct ListRefIterator<'a, T: Clone> {
    curr: Option<&'a ListNode<T>>,
}

impl<T: Clone> FromIterator<T> for List<T> {
    fn from_iter<I: IntoIterator<Item = T>>(iter: I) -> List<T> {
        let mut buf = nil();
        for item in iter {
            buf = cons(item, buf);
        }
        buf.reverse()
    }
}

impl<'a, T: Clone> IntoIterator for &'a List<T> {
    type Item = &'a T;
    type IntoIter = ListRefIterator<'a, T>;

    #[inline]
    fn into_iter(self) -> Self::IntoIter {
       self.iter()
    }
}

impl<'a, T: Clone> IntoIterator for &'a ListNode<T> {
    type Item = &'a T;
    type IntoIter = ListRefIterator<'a, T>;

    #[inline]
    fn into_iter(self) -> Self::IntoIter {
       ListRefIterator { curr: Some(self) }
    }
}

impl<'a, T: Clone> Iterator for ListRefIterator<'a, T> {
    type Item = &'a T;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        match self.curr? {
            Nil => None,
            Cons { head, tail } => {
                self.curr = tail.node();
                Some(head)
            }
        }
    }
}

impl<T: Clone> List<T> {
    /// Appends lst2 to lst1. O(length(lst1)), O(1) if either list is empty.
    pub fn append(&self, lst2: &List<T>) -> List<T> {
        if self.is_empty() {
            return lst2.clone();
        }
        if lst2.is_empty() {
            return self.clone();
        }
        let items: Vec<&T> = self.into_iter().collect();
        let mut result = lst2.clone();
        for item in items.into_iter().rev() {
            result = cons(item.clone(), result);
        }
        result
    }
    /// Returns the length of a list. O(n).
    pub fn len(&self) -> i32 {
        self.into_iter().count() as i32
    }
    /// Reverses a list. O(n). Relinks the uniquely owned prefix in place
    /// (no allocation) and copies a shared suffix.
    pub fn reverse(mut self) -> List<T> {
        let mut acc = List(None);
        let mut cur = self.0.take();
        while let Some(mut node) = cur {
            match Arc::get_mut(&mut node) {
                Some(Cons { tail, .. }) => {
                    cur = tail.0.take();
                    tail.0 = acc.0.take();
                    acc = List(Some(node));
                }
                _ => {
                    let shared = List(Some(node));
                    for e in &shared {
                        acc = cons(e.clone(), acc);
                    }
                    break;
                }
            }
        }
        acc
    }
    /// Gets the element at the given 1-based index. O(index).
    pub fn get(&self, index: i32) -> Result<T> {
        self.into_iter().nth((index - 1) as usize)
            .cloned()
            .ok_or_else(|| "Index {} out of bounds for list of length {}")
    }
    pub fn prepend_reverse(&self, prefix: &List<T>) -> List<T> {
        let mut result = self.clone();
        for item in prefix {
            result = cons(item.clone(), result);
        }
        result
    }
    /// Deletes the element at the given 1-based index. O(index).
    pub fn delete(&self, index: i32) -> Result<List<T>> {
        if index < 1 {
            return Err("Index must be positive, got {}");
        }
        if index == 1 {
            return self.rest();
        }
        let mut result = nil();
        let mut iter = self;
        let mut cur_index = index;
        loop {
            cur_index -= 1;
            let (head,tail) = match iter.node() {
                Some(Cons{head, tail}) => (head, tail),
                _ => return Err("Index {} out of bounds for list"),
            };
            iter = tail;
            if cur_index == 0 {
                return Ok(iter.prepend_reverse(&result));
            }
            result = cons(head.clone(), result);
        }
    }
    pub fn new(item: T) -> List<T> {
        cons(item, nil())
    }
    pub fn cons(self, item: T) -> List<T> {
        cons(item, self)
    }
    /// Gets the first element. O(1).
    /// Fails if the list is empty.
    pub fn head(&self) -> Result<&T> {
        match self.node() {
            Some(Cons{head, ..}) => Ok(head),
            _ => Err("Cannot get head of empty list"),
        }
    }
    /// Returns all elements except the first. O(1).
    /// Fails if the list is empty.
    pub fn rest(&self) -> Result<List<T>> {
        match self.node() {
            Some(Cons{tail, ..}) => Ok(tail.clone()),
            _ => Err("Cannot get rest of empty list"),
        }
    }
    /// Returns true if the list is empty. O(1).
    #[inline]
    pub fn is_empty(&self) -> bool {
        self.0.is_none()
    }
}

impl<T: PartialEq + Clone> List<T> {
    /// Checks if an element is a member of the list. O(n).
    /// Uses PartialEq for comparison.
    pub fn contains(&self, element: &T) -> bool {
        for item in self {
            if element.eq(item) { return true; }
        }
        false
    }
}

/// Relinks the last node of a uniquely owned `lst1` onto `lst2` without
/// allocating; from the first shared node on, the suffix is copied.
pub fn listAppend<T: Clone>(mut lst1: List<T>, lst2: List<T>) -> List<T> {
    if lst2.is_empty() {
        return lst1;
    }
    let mut cur: &mut List<T> = &mut lst1;
    loop {
        let unique_cons = match cur.0.as_ref() {
            None => {
                *cur = lst2;
                return lst1;
            }
            Some(node) => {
                Arc::strong_count(node) == 1 && Arc::weak_count(node) == 0 && matches!(&**node, Cons { .. })
            }
        };
        if !unique_cons {
            let suffix = cur.clone();
            *cur = suffix.append(&lst2);
            return lst1;
        }
        let Some(Cons { tail, .. }) = cur.0.as_mut().and_then(Arc::get_mut) else { unreachable!() };
        cur = tail;
    }
}

/// Free-function form of the `listReverse` builtin (the `List::reverse` method).
/// Direct calls lower to `x.reverse()`, but when `listReverse` is used as a
/// first-class value (e.g. `Array.map(arr, listReverse)`) there must be a real
/// function path to reference — methods cannot be named as `fn` items. Codegen
/// emits `fnptr!(metamodelica::listReverse, _)` for that case.
pub fn listReverse<T: Clone>(lst: List<T>) -> List<T> {
    lst.reverse()
}

pub fn listMember<T: Clone+PartialEq>(element: T, lst: List<T>) -> bool {
    lst.contains(&element)
}

pub fn listHead<T: Clone>(lst: List<T>) -> Result<T> {
    lst.head().cloned()
}

pub fn listGet<T: Clone>(lst: List<T>, i: i32) -> Result<T> {
    lst.get(i)
}

pub fn listEmpty<T: Clone>(lst: List<T>) -> bool {
    lst.is_empty()
}

pub fn listDelete<T: Clone>(lst: List<T>, index: i32) -> Result<List<T>> {
    lst.delete(index)
}

pub fn listRest<T: Clone>(lst: List<T>) -> Result<List<T>> {
    lst.rest()
}

pub fn listLength<T: Clone>(lst: List<T>) -> i32 {
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

        /// A long list must be released iteratively (see `impl Drop`), and the
        /// unlink walk must leave a shared suffix intact.
        #[test]
        fn test_drop_long_list_is_iterative() {
            let mut l: List<i32> = nil();
            for i in 0..500_000 {
                l = cons(i, l);
            }
            drop(l);

            let mut shared: List<i32> = nil();
            for i in 0..200_000 {
                shared = cons(i, shared);
            }
            let mut prefixed = shared.clone();
            for i in 0..200_000 {
                prefixed = cons(i, prefixed);
            }
            drop(prefixed);
            assert_eq!(shared.len(), 200_000);
            drop(shared);
        }

        #[test]
        fn test_list_append() {
            let a = list![1, 2, 3];
            let b = list![4, 5];
            let result = a.append(&b);
            assert_eq!(result, list![1, 2, 3, 4, 5]);

            // Empty list cases
            let empty: List<i32> = nil();
            assert_eq!(empty.append(&b), b);
            assert_eq!(a.append(&empty), a);
        }

        #[test]
        fn test_list_reverse() {
            let lst = list![1, 2, 3, 4, 5];
            let result = lst.clone().reverse();
            assert_eq!(result, list![5, 4, 3, 2, 1]);
            assert_eq!(lst, list![1, 2, 3, 4, 5]);
            assert_eq!(lst.reverse(), list![5, 4, 3, 2, 1]);

            let empty: List<i32> = nil();
            assert_eq!(empty.reverse(), nil());
        }

        #[test]
        fn test_list_length() {
            let lst = list![1, 2, 3];
            assert_eq!(lst.len(), 3);
            let empty: List<i32> = nil();
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

            let empty: List<i32> = nil();
            assert!(empty.rest().is_err());
        }

        #[test]
        fn test_list_head() {
            let lst = list![1, 2, 3];
            assert_eq!(lst.head().unwrap().clone(), 1);

            let empty: List<i32> = nil();
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

            let empty: List<i32> = nil();
            assert!(empty.is_empty());
        }

        #[test]
        fn test_cons() {
            let lst = list![2, 3];
            let result = cons(1, lst);
            assert_eq!(result, list![1, 2, 3]);

            let empty: List<i32> = nil();
            let result = cons(42, empty);
            assert_eq!(result, List::new(42));
        }

        #[test]
        fn test_list_reverse_shared_suffix() {
            let suffix = list![3, 4];
            let lst = cons(1, cons(2, suffix.clone()));
            assert_eq!(lst.reverse(), list![4, 3, 2, 1]);
            assert_eq!(suffix, list![3, 4]);
            let mut long: List<i32> = nil();
            for i in 0..500_000 {
                long = cons(i, long);
            }
            assert_eq!(long.reverse().head().unwrap(), &0);
            assert!(nil::<i32>().reference_eq(&nil()));
        }

        #[test]
        fn test_list_reverse2() -> () {
            let lst1 = list![1,2,3,4];
            let lst2 = lst1.clone().reverse();
            let lst3 = lst2.clone().reverse();
            assert_eq!(lst1, lst3);
            assert!(lst1 != lst2);
        }
    }
}
