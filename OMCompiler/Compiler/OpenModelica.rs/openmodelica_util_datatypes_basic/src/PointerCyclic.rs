// Manually written
#![allow(non_snake_case)]

//! `PointerCyclic` — a `Pointer` whose content could transitively contain the
//! cell itself, which is why it used to be allocated in a tracing `Gc`.
//!
//! Nothing closes such a cycle any more, so it is exactly a `Pointer`: an `Arc`
//! cell that reference counting reclaims on its own, registered with the cell
//! collector so `GCExt.gcollect` still reports anything that does. The name is
//! kept so the MetaModelica sources need not change in the same commit.

pub use crate::Pointer::{access, apply, clone, create, createImmutable, referenceEq, update};

pub type PointerCyclic<T> = crate::Pointer::Pointer<T>;
