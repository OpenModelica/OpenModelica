// Manually written
#![allow(non_snake_case)]

//! `PointerCyclic` — a `Pointer` whose content may transitively contain the
//! cell itself. See `MutableCyclic` for why the two are separate types.

pub use crate::Pointer::Pointer as PointerCyclic;
pub use crate::Pointer::{access, apply, clone, create, createImmutable, referenceEq, update};
