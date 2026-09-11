// Manually written
#![allow(non_snake_case)]

//! `MutableCyclic` — a `Mutable` whose content may transitively contain the
//! cell itself. See `Util/MutableCyclic.mo` for why the two are separate types.
//!
//! Still an alias for `Mutable`, so the split is behaviour-neutral: both are
//! the same `Arc`-backed cell. The point of the split is that only these cells
//! can sit on a reference cycle, so only these need the traced representation
//! the collector can reclaim — swapping that in happens here, and nothing
//! outside this file has to change when it does.

pub use crate::Mutable::Mutable as MutableCyclic;
pub use crate::Mutable::{access, create, referenceEq, update};
