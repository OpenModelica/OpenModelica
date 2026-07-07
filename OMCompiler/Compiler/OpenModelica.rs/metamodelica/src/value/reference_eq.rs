//! `referenceEq` (free fn + trait) and the `ReferenceEq`/`MetaCmp`
//! derive re-exports; plus `reference{Pointer,Debug}String`.

use std::sync::Arc;
use std::rc::Rc;
use anyhow::Result;
use arcstr::{ArcStr, format};
use crate::Real;
use crate::list::List;
use crate::SourceInfo;

/// Reference equality check.
/// In Rust, this checks pointer equality for reference-counted types.
/// For simple types, falls back to structural equality.
///
/// This is a very fast comparison to speed up comparisons.
/// If you know that all occurrences of a value are the same pointer,
/// you can use reference_eq instead of structural equality.
pub fn referenceEq<A: ?Sized>(a1: &A, a2: &A) -> bool {
    // No `A: PartialEq` bound. The body only does pointer comparison, and
    // some MM types — e.g. anything transitively embedding an
    // `Arc<dyn Fn(...) + 'static>` callback (NF Type's
    // EvaluateSingletonType variant, and its containers down to
    // ComponentRef) — can no longer auto-derive `PartialEq`. Requiring
    // the bound here would lock those types out of every
    // `referenceEq(&a, &b)` site even though the bodies don't need it.
    //
    // `A: ?Sized` so the caller can deref through a shared-pointer handle
    // and compare the *pointee* — `referenceEq(&*s1, &*s2)` for `ArcStr`
    // arguments compares the `str` pointees. Two clones of the same handle
    // live at different stack addresses, so comparing the handles would
    // distinguish them even though they designate the same MM object; the
    // code generator therefore passes `&*v` for handle-represented values
    // (see mmtorust's `referenceEq` lowering). For unsized pointees
    // `std::ptr::eq` also compares the metadata (length / vtable), which is
    // identical for clones of the same handle.
    std::ptr::eq(a1 as *const A, a2 as *const A)
}

/// `#[derive(ReferenceEq)]` — emits a shallow field-wise [`ReferenceEq`]
/// impl; mmtorust adds it to every generated MM value type (see
/// `GenCtx::derives_for`).
pub use metamodelica_derive::ReferenceEq;

/// `#[derive(MetaCmp)]` — emits `PartialEq`/`PartialOrd`/`Ord` with an
/// `Arc::ptr_eq` fast path on every `Arc<…>` field, the faithful port of the
/// MMC runtime `valueCompare`'s pointer-identity short-circuit. mmtorust emits
/// it in place of the builtin `PartialEq`/`PartialOrd`/`Ord` derives (see
/// `GenCtx::derives_for`) so comparing the cyclic NF graphs terminates.
pub use metamodelica_derive::MetaCmp;

/// MetaModelica `referenceEq` as a trait, for *generic* contexts where the
/// operands' representation is opaque to the code generator (a bare type
/// parameter, or a type containing one). Concrete-typed sites are lowered
/// structurally instead — see `try_emit_reference_eq` in
/// mmtorust/src/codegen.rs; this trait's impls mirror that lowering exactly:
///
///   * scalars (Integer/Boolean/Real, MMC immediates or boxed-immutable)
///     compare by value;
///   * shared handles (`Arc`, `Rc` — lists, uniontype values, arrays,
///     callbacks) compare by allocation identity;
///   * `String` (`ArcStr`) compares the pointee `str` address, so clones of
///     one handle are identical but equal copies are not;
///   * options/tuples/records/enums compare component-wise (the derive).
///
/// The relation is *observational identity*: true whenever MMC's pointer
/// comparison would be true, and additionally true for distinct copies whose
/// components are pairwise identical — copies which exist only because this
/// port unboxes non-recursive records and clones values where MMC shares
/// pointers, and which no MM program can otherwise distinguish.
pub trait ReferenceEq {
    fn reference_eq(&self, other: &Self) -> bool;
}

impl ReferenceEq for i32 {
    fn reference_eq(&self, other: &Self) -> bool { self == other }
}
impl ReferenceEq for i64 {
    fn reference_eq(&self, other: &Self) -> bool { self == other }
}
impl ReferenceEq for bool {
    fn reference_eq(&self, other: &Self) -> bool { self == other }
}
impl ReferenceEq for () {
    fn reference_eq(&self, _other: &Self) -> bool { true }
}
/// MM `Real`. MMC boxes reals, so its referenceEq can distinguish equal
/// values in distinct boxes; an unboxed `f64` cannot. Value equality is the
/// observational-identity choice (`OrderedFloat` makes NaN equal itself,
/// so the relation stays reflexive like pointer identity is).
impl ReferenceEq for Real {
    fn reference_eq(&self, other: &Self) -> bool { self == other }
}
/// MM `String`: identity of the shared `str` allocation, like the
/// `referenceEq(&*s1, &*s2)` the concrete lowering emits.
impl ReferenceEq for ArcStr {
    fn reference_eq(&self, other: &Self) -> bool {
        std::ptr::eq(self.as_str() as *const str, other.as_str() as *const str)
    }
}
/// Shared handles: allocation identity. Covers lists (`Arc<List<T>>`),
/// Arc-boxed uniontype values, and `Arc<dyn Fn(...)>` callbacks (`?Sized`).
impl<T: ?Sized> ReferenceEq for Arc<T> {
    fn reference_eq(&self, other: &Self) -> bool { Arc::ptr_eq(self, other) }
}
/// `Rc` handles: covers `Array<T>` (= `Rc<RefCell<Vec<T>>>`), whose MM
/// semantics are reference (aliasing) semantics — identity of the storage.
impl<T: ?Sized> ReferenceEq for Rc<T> {
    fn reference_eq(&self, other: &Self) -> bool { Rc::ptr_eq(self, other) }
}
/// `NONE()` is a runtime singleton in MMC, so two NONEs are identical;
/// SOME payloads compare recursively (same shape the concrete lowering
/// emits for `Option`).
impl<T: ReferenceEq> ReferenceEq for Option<T> {
    fn reference_eq(&self, other: &Self) -> bool {
        match (self, other) {
            (None, None) => true,
            (Some(l), Some(r)) => l.reference_eq(r),
            _ => false,
        }
    }
}
/// MM tuples: component-wise.
macro_rules! impl_reference_eq_tuple {
    ($($name:ident : $idx:tt),+) => {
        impl<$($name: ReferenceEq),+> ReferenceEq for ($($name,)+) {
            fn reference_eq(&self, other: &Self) -> bool {
                true $(&& self.$idx.reference_eq(&other.$idx))+
            }
        }
    };
}
impl_reference_eq_tuple!(A: 0);
impl_reference_eq_tuple!(A: 0, B: 1);
impl_reference_eq_tuple!(A: 0, B: 1, C: 2);
impl_reference_eq_tuple!(A: 0, B: 1, C: 2, D: 3);
impl_reference_eq_tuple!(A: 0, B: 1, C: 2, D: 3, E: 4);
impl_reference_eq_tuple!(A: 0, B: 1, C: 2, D: 3, E: 4, F: 5);
impl_reference_eq_tuple!(A: 0, B: 1, C: 2, D: 3, E: 4, F: 5, G: 6);
impl_reference_eq_tuple!(A: 0, B: 1, C: 2, D: 3, E: 4, F: 5, G: 6, H: 7);
impl_reference_eq_tuple!(A: 0, B: 1, C: 2, D: 3, E: 4, F: 5, G: 6, H: 7, I: 8);
impl_reference_eq_tuple!(A: 0, B: 1, C: 2, D: 3, E: 4, F: 5, G: 6, H: 7, I: 8, J: 9);
/// Bare `List<T>` (the usual MM representation is `Arc<List<T>>`, caught by
/// the `Arc` impl): shallow like the derive would emit — heads compare via
/// `ReferenceEq`, tails via `Arc` identity, so the comparison is O(1).
impl<T: Clone + ReferenceEq> ReferenceEq for List<T> {
    fn reference_eq(&self, other: &Self) -> bool {
        match (self, other) {
            (List::Nil, List::Nil) => true,
            (List::Cons { head: lh, tail: lt }, List::Cons { head: rh, tail: rt }) => {
                lh.reference_eq(rh) && Arc::ptr_eq(lt, rt)
            }
            _ => false,
        }
    }
}
impl ReferenceEq for SourceInfo {
    fn reference_eq(&self, other: &Self) -> bool {
        self.fileName.reference_eq(&other.fileName)
            && self.isReadOnly == other.isReadOnly
            && self.lineNumberStart == other.lineNumberStart
            && self.columnNumberStart == other.columnNumberStart
            && self.lineNumberEnd == other.lineNumberEnd
            && self.columnNumberEnd == other.columnNumberEnd
            && self.lastModification == other.lastModification
    }
}

/// Returns the pointer address of a reference as a hexadecimal string for debugging.
pub fn referencePointerString<A>(a: &A) -> Result<ArcStr> {
    Ok(format!("{:p}", a))
}

/// Returns a debug string for a function symbol.
/// In Rust, returns the type name of the value for debugging.
pub fn referenceDebugString<A: std::fmt::Debug>(_a: &A) -> Result<ArcStr> {
    Ok(format!("{:?}", std::any::type_name::<A>()))
}
