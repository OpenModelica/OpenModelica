// Manually written
#![allow(non_snake_case)]

//! `MutableWeak` — a non-owning reference to a [`crate::Mutable`] cell.
//!
//! This is how an ownership cycle is broken so plain reference counting can
//! reclaim it: the parent owns its children, each child refers back weakly, and
//! the structure hangs off one strong root. No collector is involved.

use std::sync::{Arc, Weak};

use crate::Mutable::{CellInner, Mutable};

pub struct MutableWeak<T: Clone>(Weak<CellInner<T>>);

impl<T: Clone> Clone for MutableWeak<T> {
    fn clone(&self) -> Self {
        MutableWeak(self.0.clone())
    }
}

/// A reference that does not keep the cell alive. Never fails.
pub fn downgrade<T: Clone>(mutable: Mutable<T>) -> MutableWeak<T> {
    MutableWeak(Arc::downgrade(&mutable.0))
}

/// An owning cell again. Fails if the referent is already gone — a weak
/// reference outlived the structure that owned it, so the ownership split is
/// wrong somewhere. Dereferencing a cell never fails; only this conversion does.
pub fn upgrade<T: Clone>(weak: MutableWeak<T>) -> metamodelica::Result<Mutable<T>> {
    match weak.0.upgrade() {
        Some(cell) => Ok(Mutable(cell)),
        None => Err("MutableWeak.upgrade: the referent is gone"),
    }
}

/// Same cell, as `Mutable`'s `referenceEq` is. Two dead references are never
/// equal: neither designates a cell any more.
pub fn referenceEq<T: Clone>(a: &MutableWeak<T>, b: &MutableWeak<T>) -> bool {
    Weak::ptr_eq(&a.0, &b.0) && a.0.strong_count() > 0
}

impl<T: Clone> metamodelica::ReferenceEq for MutableWeak<T> {
    fn reference_eq(&self, other: &Self) -> bool {
        referenceEq(self, other)
    }
}

/// A weak reference owns nothing, so it reports nothing — that is exactly what
/// makes it break the cycle rather than merely hide it.
impl<T: Clone + metamodelica::mmval::MmVal> metamodelica::mmval::MmVal for MutableWeak<T> {
    type Traced = metamodelica::mmval::No;
    fn mm_accept<V: metamodelica::mmval::Visitor>(&self, _: &mut V) -> Result<(), ()> {
        Ok(())
    }
}

impl<T: Clone> metamodelica::gc::MMTrace for MutableWeak<T> {
    fn mm_accept(&self, _: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        Ok(())
    }
}

impl<T: Clone + std::fmt::Debug> std::fmt::Debug for MutableWeak<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self.0.upgrade() {
            Some(_) => write!(f, "MutableWeak(<live>)"),
            None => write!(f, "MutableWeak(<gone>)"),
        }
    }
}

// Identity, like `Pointer`'s: content-based comparison would have to upgrade,
// and a weak reference is a link rather than a value.

fn key<T: Clone>(w: &MutableWeak<T>) -> usize {
    w.0.as_ptr() as usize
}

impl<T: Clone> PartialEq for MutableWeak<T> {
    fn eq(&self, other: &Self) -> bool {
        key(self) == key(other)
    }
}

impl<T: Clone> Eq for MutableWeak<T> {}

impl<T: Clone> PartialOrd for MutableWeak<T> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(key(self).cmp(&key(other)))
    }
}

impl<T: Clone> Ord for MutableWeak<T> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        key(self).cmp(&key(other))
    }
}

impl<T: Clone> std::hash::Hash for MutableWeak<T> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        std::hash::Hash::hash(&key(self), state);
    }
}
