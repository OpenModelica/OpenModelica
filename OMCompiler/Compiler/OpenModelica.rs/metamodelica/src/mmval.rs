//! Which MetaModelica values a cycle collector has to trace.
//!
//! Values are freed by reference counting, which reclaims everything except a
//! cycle, and a cycle can only be closed through a cell declared
//! `MutableCyclic`/`PointerCyclic` (see `Util/MutableCyclic.mo`). Only those,
//! and what can reach them, need a traced allocation; the rest stay `Arc`.
//!
//! [`MmVal::Traced`] is the type-level flag carrying that distinction. mmtorust
//! declares it per generated type, so it is never derived from a type's fields
//! and the solver never recurses through a type cycle — `Arc` is always [`No`]
//! and terminates the walk.
//!
//! The trait is ours rather than dumpster's `Trace` because of the orphan rule:
//! `TraceWith` is foreign and generic over the visitor, so it cannot be
//! implemented for `Arc`, `ArcStr` or `OrderedFloat`. `MmVal` can, which is what
//! lets `Arc` be the barrier and `List<ArcStr>` exist.
//!
//! # Why a barrier is sound
//!
//! An `Arc` reports nothing, so a traced handle inside one is never counted as
//! an internal reference and its target always looks externally rooted — kept,
//! never freed early. The converse does not hold: tracing *through* a shared
//! `Arc` would count the handles it owns once per path reaching it, and an
//! over-count frees live data. Hence the barrier is only sound where the
//! payload provably cannot reach a traced allocation.

use std::cell::RefCell;
use std::rc::Rc;
use std::sync::Arc;

pub use dumpster::unsync::{collect, Gc};
pub use dumpster::Visitor;

/// Turn automatic collection off for this thread when `OPENMODELICA_GC_DISABLE`
/// is set, so the collector's cost can be measured against the same binary
/// rather than against a differently-built one.
pub fn init_collect_condition() {
    if std::env::var_os("OPENMODELICA_GC_DISABLE").is_some() {
        fn never(_: &dumpster::unsync::CollectInfo) -> bool {
            false
        }
        dumpster::unsync::set_collect_condition(never);
    }
}

// ── type-level booleans ──────────────────────────────────────────────────────

/// Whether a value can reach a traced allocation. See the module docs.
pub trait Traced: 'static {
    /// Disjunction, for types built out of several others (tuples, records).
    type Or<B: Traced>: Traced;
    /// The allocation a container spine uses for this kind of payload.
    type Ptr<U: MmVal>: SpinePtr<U> + MmVal;
    /// As [`Self::Ptr`], for a container that is single-threaded by
    /// construction and so pays no atomic refcount when untraced.
    type RcPtr<U: MmVal>: SpinePtr<U> + MmVal;
}

pub struct No;
pub struct Yes;

impl Traced for No {
    type Or<B: Traced> = B;
    type Ptr<U: MmVal> = Arc<U>;
    type RcPtr<U: MmVal> = Rc<U>;
}

impl Traced for Yes {
    type Or<B: Traced> = Yes;
    type Ptr<U: MmVal> = GcRef<U>;
    type RcPtr<U: MmVal> = GcRef<U>;
}

/// Shorthand for the disjunction of two flags.
pub type Or<A, B> = <<A as MmVal>::Traced as Traced>::Or<<B as MmVal>::Traced>;

// ── the two spine allocations ────────────────────────────────────────────────

/// Adapts an [`MmVal`] to dumpster's own trait. `Gc<T>` demands `T: Trace`,
/// which is foreign and cannot be implemented for a generic MetaModelica
/// value; wrapping one local type that forwards to `mm_accept` is what lets any
/// `MmVal` sit inside a `Gc`.
pub struct Cell<T: MmVal>(pub T);

unsafe impl<V: Visitor, T: MmVal> dumpster::TraceWith<V> for Cell<T> {
    fn accept(&self, visitor: &mut V) -> Result<(), ()> {
        self.0.mm_accept(visitor)
    }
}

/// The traced spine. Hides the [`Cell`] hop so both arms deref to the payload.
pub struct GcRef<U: MmVal>(Gc<Cell<U>>);

impl<U: MmVal> Clone for GcRef<U> {
    fn clone(&self) -> Self {
        GcRef(self.0.clone())
    }
}

impl<U: MmVal> std::ops::Deref for GcRef<U> {
    type Target = U;
    fn deref(&self) -> &U {
        &self.0.0
    }
}

// Forwarding impls, so a traced spine is a drop-in for the `Arc`/`Rc` one at
// every derived use site (`#[derive(PartialEq)]` on a record holding one, a
// `BTreeMap` keyed by a list, ...).

impl<U: MmVal + std::fmt::Debug> std::fmt::Debug for GcRef<U> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        (**self).fmt(f)
    }
}

impl<U: MmVal + PartialEq> PartialEq for GcRef<U> {
    fn eq(&self, other: &Self) -> bool {
        **self == **other
    }
}

impl<U: MmVal + Eq> Eq for GcRef<U> {}

impl<U: MmVal + PartialOrd> PartialOrd for GcRef<U> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        (**self).partial_cmp(&**other)
    }
}

impl<U: MmVal + Ord> Ord for GcRef<U> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        (**self).cmp(&**other)
    }
}

impl<U: MmVal + std::hash::Hash> std::hash::Hash for GcRef<U> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        (**self).hash(state)
    }
}

impl<U: MmVal + Default> Default for GcRef<U> {
    fn default() -> Self {
        Self::alloc(U::default())
    }
}

/// What a shared container allocation must provide. The two implementations
/// differ in `spine_accept`: the traced arm reports itself to the collector,
/// the `Arc` arm is the barrier.
pub trait SpinePtr<U: ?Sized>: Clone + std::ops::Deref<Target = U> {
    fn alloc(value: U) -> Self
    where
        U: Sized;
    fn spine_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()>;
    fn same(a: &Self, b: &Self) -> bool;
    fn addr(this: &Self) -> *const ();
    /// The payload itself, for the `Dangerous` in-place cons-cell writes.
    /// Distinct from [`Self::addr`], which is the allocation's identity and on
    /// the traced arm points at the `Gc` box rather than at `U`.
    fn payload_ptr(this: &Self) -> *const U;
    /// Unique access, for the in-place list optimisations. The traced arm has
    /// no equivalent and always declines, so those paths fall back to copying.
    fn get_mut(this: &mut Self) -> Option<&mut U>
    where
        U: Sized;
    /// Whether this is the only handle. Same caveat as `get_mut`.
    fn is_unique(this: &Self) -> bool;
    fn strong_count(this: &Self) -> usize;
}

impl<U: MmVal> SpinePtr<U> for GcRef<U> {
    fn alloc(value: U) -> Self {
        GcRef(Gc::new(Cell(value)))
    }
    fn spine_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        dumpster::TraceWith::accept(&self.0, visitor)
    }
    fn same(a: &Self, b: &Self) -> bool {
        Gc::ptr_eq(&a.0, &b.0)
    }
    fn addr(this: &Self) -> *const () {
        Gc::as_ptr(&this.0) as *const ()
    }
    fn payload_ptr(this: &Self) -> *const U {
        &**this as *const U
    }
    fn get_mut(_: &mut Self) -> Option<&mut U> {
        None
    }
    fn is_unique(_: &Self) -> bool {
        false
    }
    fn strong_count(this: &Self) -> usize {
        Gc::ref_count(&this.0).get()
    }
}

impl<U: ?Sized> SpinePtr<U> for Rc<U> {
    fn alloc(value: U) -> Self
    where
        U: Sized,
    {
        Rc::new(value)
    }
    fn spine_accept<V: Visitor>(&self, _visitor: &mut V) -> Result<(), ()> {
        Ok(())
    }
    fn same(a: &Self, b: &Self) -> bool {
        Rc::ptr_eq(a, b)
    }
    fn addr(this: &Self) -> *const () {
        Rc::as_ptr(this) as *const ()
    }
    fn payload_ptr(this: &Self) -> *const U {
        Rc::as_ptr(this)
    }
    fn get_mut(this: &mut Self) -> Option<&mut U>
    where
        U: Sized,
    {
        Rc::get_mut(this)
    }
    fn is_unique(this: &Self) -> bool {
        Rc::strong_count(this) == 1 && Rc::weak_count(this) == 0
    }
    fn strong_count(this: &Self) -> usize {
        Rc::strong_count(this)
    }
}

impl<U: ?Sized> SpinePtr<U> for Arc<U> {
    fn alloc(value: U) -> Self
    where
        U: Sized,
    {
        Arc::new(value)
    }
    fn spine_accept<V: Visitor>(&self, _visitor: &mut V) -> Result<(), ()> {
        Ok(())
    }
    fn same(a: &Self, b: &Self) -> bool {
        Arc::ptr_eq(a, b)
    }
    fn addr(this: &Self) -> *const () {
        Arc::as_ptr(this) as *const ()
    }
    fn payload_ptr(this: &Self) -> *const U {
        Arc::as_ptr(this)
    }
    fn get_mut(this: &mut Self) -> Option<&mut U>
    where
        U: Sized,
    {
        Arc::get_mut(this)
    }
    fn is_unique(this: &Self) -> bool {
        Arc::strong_count(this) == 1 && Arc::weak_count(this) == 0
    }
    fn strong_count(this: &Self) -> usize {
        Arc::strong_count(this)
    }
}

// ── the value trait ──────────────────────────────────────────────────────────

/// Every MetaModelica value type. mmtorust emits one impl per generated type.
pub trait MmVal: 'static {
    type Traced: Traced;
    /// Report the [`Gc`] handles this value owns. Must visit every field that
    /// can reach one; the rest may be skipped, which is what keeps `ArcStr`,
    /// `Real` and the scalars out of the collector's way entirely.
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()>;
}

/// The spine allocation a container of `T` uses.
pub type Spine<T, N> = <<T as MmVal>::Traced as Traced>::Ptr<N>;

/// [`Spine`] for a single-threaded container; see [`Traced::RcPtr`].
pub type RcSpine<T, N> = <<T as MmVal>::Traced as Traced>::RcPtr<N>;

// ── barriers ─────────────────────────────────────────────────────────────────

impl<T: ?Sized + 'static> MmVal for Arc<T> {
    type Traced = No;
    fn mm_accept<V: Visitor>(&self, _visitor: &mut V) -> Result<(), ()> {
        Ok(())
    }
}

impl<T: ?Sized + 'static> MmVal for Rc<T> {
    type Traced = No;
    fn mm_accept<V: Visitor>(&self, _visitor: &mut V) -> Result<(), ()> {
        Ok(())
    }
}

impl<T: MmVal> MmVal for Gc<Cell<T>> {
    type Traced = Yes;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        dumpster::TraceWith::accept(self, visitor)
    }
}

impl<T: MmVal> MmVal for GcRef<T> {
    type Traced = Yes;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        self.spine_accept(visitor)
    }
}

/// A borrow can only originate on some stack frame, and whatever owns it keeps
/// everything beneath it rooted, so hiding it can only make the collector more
/// conservative.
impl<T: ?Sized + 'static> MmVal for &'static T {
    type Traced = No;
    fn mm_accept<V: Visitor>(&self, _visitor: &mut V) -> Result<(), ()> {
        Ok(())
    }
}

// ── leaves ───────────────────────────────────────────────────────────────────

macro_rules! mm_leaf {
    ($($t:ty),* $(,)?) => {$(
        impl MmVal for $t {
            type Traced = No;
            #[inline]
            fn mm_accept<V: Visitor>(&self, _visitor: &mut V) -> Result<(), ()> { Ok(()) }
        }
    )*};
}

mm_leaf!(
    (), bool, char,
    i8, i16, i32, i64, i128, isize,
    u8, u16, u32, u64, u128, usize,
    f32, f64,
    String,
    arcstr::ArcStr,
    ordered_float::OrderedFloat<f64>,
    crate::SourceInfo,
);

// ── structural combinators ───────────────────────────────────────────────────

impl<T: MmVal> MmVal for Option<T> {
    type Traced = T::Traced;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        match self {
            Some(x) => x.mm_accept(visitor),
            None => Ok(()),
        }
    }
}

impl<T: MmVal> MmVal for Vec<T> {
    type Traced = T::Traced;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        for x in self {
            x.mm_accept(visitor)?;
        }
        Ok(())
    }
}

impl<T: MmVal> MmVal for Box<T> {
    type Traced = T::Traced;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        (**self).mm_accept(visitor)
    }
}

/// A `RefCell` borrowed elsewhere cannot be read; `Err` makes the collector
/// treat the whole traversal as untrustworthy and do nothing.
impl<T: MmVal> MmVal for RefCell<T> {
    type Traced = T::Traced;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        self.try_borrow().map_err(|_| ())?.mm_accept(visitor)
    }
}

/// The persistent list. Its cons cells are shared, so the walk reports the
/// spine and stops: dumpster visits each cell once and counts the sharing
/// itself. Walking *through* the cells instead would report a shared tail's
/// contents once per path reaching it, and an over-count frees live data.
/// On the untraced arm the spine is an `Arc` and reports nothing.
impl<T: MmVal + Clone> MmVal for crate::List<T> {
    type Traced = T::Traced;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        match &self.0 {
            Some(node) => node.spine_accept(visitor),
            None => Ok(()),
        }
    }
}

/// One cons cell: its head and the handle to the next cell. Reached only
/// through the traced arm, where dumpster walks the allocation for us.
impl<T: MmVal + Clone> MmVal for crate::ListNode<T> {
    type Traced = T::Traced;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        match self {
            crate::ListNode::Cons { head, tail } => {
                head.mm_accept(visitor)?;
                tail.mm_accept(visitor)
            }
            crate::ListNode::Nil => Ok(()),
        }
    }
}

macro_rules! mm_tuple {
    ($first:ident $(, $rest:ident)*) => {
        #[allow(non_snake_case)]
        impl<$first: MmVal $(, $rest: MmVal)*> MmVal for ($first, $($rest,)*) {
            type Traced = <$first::Traced as Traced>::Or<<($($rest,)*) as MmVal>::Traced>;
            fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
                let ($first, $($rest,)*) = self;
                $first.mm_accept(visitor)?;
                $( $rest.mm_accept(visitor)?; )*
                Ok(())
            }
        }
        mm_tuple!($($rest),*);
    };
    () => {};
}

mm_tuple!(A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P);

// ── function values ──────────────────────────────────────────────────────────
//
// A closure's captures cannot be traversed, so a function value is a barrier —
// covered by the blanket `Arc<T>` impl above, since `T: ?Sized` already
// includes `dyn Fn(..)`. That is safe by construction (an uncounted handle
// keeps its target alive) but it does mean a cycle closed through a capture
// leaks. See the handoff for the plan to give closures a traceable form.

#[cfg(test)]
mod tests {
    use super::*;
    use std::any::type_name;

    /// The spine follows the payload, from one container type.
    #[test]
    fn spine_is_selected_per_instantiation() {
        assert!(type_name::<Spine<Arc<i32>, u8>>().contains("Arc"));
        assert!(type_name::<Spine<GcRef<i32>, u8>>().contains("Gc"));
        // Tuples and nesting propagate the flag.
        assert!(type_name::<Spine<(Arc<i32>, i32), u8>>().contains("Arc"));
        assert!(type_name::<Spine<(Arc<i32>, GcRef<i32>), u8>>().contains("Gc"));
        assert!(type_name::<Spine<Option<Vec<Arc<i32>>>, u8>>().contains("Arc"));
        assert!(type_name::<Spine<Option<Vec<GcRef<i32>>>, u8>>().contains("Gc"));
        // A leaf the orphan rule blocks from dumpster's own trait.
        assert!(type_name::<Spine<arcstr::ArcStr, u8>>().contains("Arc"));
    }
}
