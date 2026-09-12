// Manually written
#![allow(non_snake_case)]

//! `PointerWeak` — a non-owning reference to a [`crate::Pointer`] cell.
//!
//! The referent has to be owned elsewhere. For `InstNode.VAR_NODE.varPointer`
//! that owner is the backend's `VariablePointers`, which holds every variable;
//! the weak edge is what stops `Var -> cref -> pointer -> Var` from being a
//! cycle, as that record's own comment has always warned it was.

use std::sync::{Arc, Weak};

use crate::Mutable::CellInner;
use crate::Pointer::Pointer;

pub enum PointerWeak<T> {
    /// The only arm that can sit on a cycle, and so the only weak one.
    Mutable(Weak<CellInner<T>>),
    /// An immutable pointer is a plain value; nothing can close a cycle
    /// through it, so it stays strong and `upgrade` never fails for it.
    Immutable(Arc<T>),
}

impl<T> Clone for PointerWeak<T> {
    fn clone(&self) -> Self {
        match self {
            PointerWeak::Mutable(w) => PointerWeak::Mutable(w.clone()),
            PointerWeak::Immutable(a) => PointerWeak::Immutable(Arc::clone(a)),
        }
    }
}

/// A reference that does not keep the cell alive. Never fails.
pub fn downgrade<T>(pointer: Pointer<T>) -> PointerWeak<T> {
    match pointer {
        Pointer::Mutable(cell) => PointerWeak::Mutable(Arc::downgrade(&cell)),
        Pointer::Immutable(a) => PointerWeak::Immutable(a),
    }
}

/// An owning pointer again. Fails if the referent is gone, which means the
/// weak reference outlived whatever was supposed to own it.
pub fn upgrade<T>(weak: PointerWeak<T>) -> metamodelica::Result<Pointer<T>> {
    match weak {
        PointerWeak::Mutable(w) => match w.upgrade() {
            Some(cell) => Ok(Pointer::Mutable(cell)),
            None => {
                if std::env::var_os("OPENMODELICA_WEAK_TRACE").is_some() {
                    eprintln!(
                        "PointerWeak.upgrade: dead referent\n{}",
                        std::backtrace::Backtrace::force_capture()
                    );
                }
                Err("PointerWeak.upgrade: the referent is gone")
            }
        },
        PointerWeak::Immutable(a) => Ok(Pointer::Immutable(a)),
    }
}

/// Same cell, as `Pointer`'s `referenceEq` is. Two dead references are never
/// equal: neither designates a cell any more.
pub fn referenceEq<T>(a: &PointerWeak<T>, b: &PointerWeak<T>) -> bool {
    match (a, b) {
        (PointerWeak::Mutable(x), PointerWeak::Mutable(y)) => {
            Weak::ptr_eq(x, y) && x.strong_count() > 0
        }
        (PointerWeak::Immutable(x), PointerWeak::Immutable(y)) => Arc::ptr_eq(x, y),
        _ => false,
    }
}

impl<T> metamodelica::ReferenceEq for PointerWeak<T> {
    fn reference_eq(&self, other: &Self) -> bool {
        referenceEq(self, other)
    }
}

/// A weak reference owns nothing, so it reports nothing — that is exactly what
/// makes it break the cycle rather than merely hide it.
impl<T: Clone + metamodelica::mmval::MmVal> metamodelica::mmval::MmVal for PointerWeak<T> {
    type Traced = metamodelica::mmval::No;
    fn mm_accept<V: metamodelica::mmval::Visitor>(&self, _: &mut V) -> Result<(), ()> {
        Ok(())
    }
}

impl<T> metamodelica::gc::MMTrace for PointerWeak<T> {
    fn mm_accept(&self, _: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        Ok(())
    }
}

impl<T: std::fmt::Debug> std::fmt::Debug for PointerWeak<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            PointerWeak::Mutable(w) => match w.upgrade() {
                Some(_) => write!(f, "PointerWeak(<live>)"),
                None => write!(f, "PointerWeak(<gone>)"),
            },
            PointerWeak::Immutable(_) => write!(f, "PointerWeak(<immutable>)"),
        }
    }
}

fn key<T>(w: &PointerWeak<T>) -> usize {
    match w {
        PointerWeak::Mutable(x) => x.as_ptr() as *const () as usize,
        PointerWeak::Immutable(a) => Arc::as_ptr(a) as *const () as usize,
    }
}

impl<T> PartialEq for PointerWeak<T> {
    fn eq(&self, other: &Self) -> bool {
        key(self) == key(other)
    }
}

impl<T> Eq for PointerWeak<T> {}

impl<T> PartialOrd for PointerWeak<T> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(key(self).cmp(&key(other)))
    }
}

impl<T> Ord for PointerWeak<T> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        key(self).cmp(&key(other))
    }
}

impl<T> std::hash::Hash for PointerWeak<T> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        std::hash::Hash::hash(&key(self), state);
    }
}
