// Manually written
#![allow(non_snake_case)]

//! `MutableCyclic` — see [`crate::PointerCyclic`]. Now exactly a `Mutable`.

pub use crate::Mutable::{access, create, referenceEq, update};

pub type MutableCyclic<T> = crate::Mutable::Mutable<T>;
