// Manually written
#![allow(non_snake_case)]

//! `MutableCyclic` — a `Mutable` whose content may transitively contain the
//! cell itself. See `Util/MutableCyclic.mo` for why the two are separate types.
//!
//! This is the only cell kind a reference cycle is allowed to close, so it is
//! the one that carries the traced allocation: the content lives in a `Gc`, and
//! [`MmVal::mm_accept`] reports it. Plain `Mutable` stays an `Arc` barrier —
//! cheaper, and sound because a cycle through one would be a violation of the
//! `.mo`-level split rather than something the collector must handle.

use std::cell::RefCell;

use metamodelica::mmval::{self, GcRef, MmVal, SpinePtr, Visitor};

pub struct MutableCyclic<T: Clone + MmVal>(GcRef<RefCell<T>>);

impl<T: Clone + MmVal> Clone for MutableCyclic<T> {
    fn clone(&self) -> Self {
        MutableCyclic(self.0.clone())
    }
}

pub fn create<T: Clone + MmVal>(data: T) -> MutableCyclic<T> {
    MutableCyclic(SpinePtr::alloc(RefCell::new(data)))
}

pub fn update<T: Clone + MmVal>(mutable: MutableCyclic<T>, data: T) {
    *mutable.0.borrow_mut() = data;
}

pub fn access<T: Clone + MmVal>(mutable: MutableCyclic<T>) -> T {
    mutable.0.borrow().clone()
}

/// MetaModelica `referenceEq`: same cell, regardless of content.
pub fn referenceEq<T: Clone + MmVal>(a: &MutableCyclic<T>, b: &MutableCyclic<T>) -> bool {
    SpinePtr::same(&a.0, &b.0)
}

impl<T: Clone + MmVal> metamodelica::ReferenceEq for MutableCyclic<T> {
    fn reference_eq(&self, other: &Self) -> bool {
        referenceEq(self, other)
    }
}

/// Report the allocation. This is the edge that lets the collector see a cycle
/// at all: everything else on one is a `Ref`, and a `Ref` only reports when its
/// payload is traced.
impl<T: Clone + MmVal> MmVal for MutableCyclic<T> {
    type Traced = mmval::Yes;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        self.0.mm_accept(visitor)
    }
}

/// Opaque to the old collector, which knows nothing about `Gc` allocations.
/// Hiding a handle only ever makes that collector more conservative.
impl<T: Clone + MmVal> metamodelica::gc::MMTrace for MutableCyclic<T> {
    fn mm_accept(&self, _: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        Ok(())
    }
}

impl<T: Clone + MmVal + std::fmt::Debug> std::fmt::Debug for MutableCyclic<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self.0.try_borrow() {
            Ok(v) => write!(f, "MutableCyclic({v:?})"),
            Err(_) => write!(f, "MutableCyclic(<borrowed>)"),
        }
    }
}

// Content-based comparison, as `Mutable`'s is, with an identity short-circuit
// so a self-comparison does not need two borrows. `Hash` is deliberately absent
// for the same reason it is on `Mutable`: the content can change under a
// computed hash.

impl<T: Clone + MmVal + PartialEq> PartialEq for MutableCyclic<T> {
    fn eq(&self, other: &Self) -> bool {
        referenceEq(self, other) || *self.0.borrow() == *other.0.borrow()
    }
}

impl<T: Clone + MmVal + Eq> Eq for MutableCyclic<T> {}

impl<T: Clone + MmVal + PartialOrd> PartialOrd for MutableCyclic<T> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        if referenceEq(self, other) {
            return Some(std::cmp::Ordering::Equal);
        }
        (*self.0.borrow()).partial_cmp(&*other.0.borrow())
    }
}

impl<T: Clone + MmVal + Ord> Ord for MutableCyclic<T> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        if referenceEq(self, other) {
            return std::cmp::Ordering::Equal;
        }
        (*self.0.borrow()).cmp(&*other.0.borrow())
    }
}

impl<T: Clone + MmVal + Default> Default for MutableCyclic<T> {
    fn default() -> Self {
        create(T::default())
    }
}
