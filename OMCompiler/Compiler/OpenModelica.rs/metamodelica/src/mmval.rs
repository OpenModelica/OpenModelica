//! Which allocation a MetaModelica value's container spine uses.
//!
//! Values are freed by reference counting, which reclaims everything except a
//! cycle. There used to be a second, traced allocation (dumpster's `Gc`) for
//! values that could sit on one, selected per type by [`MmVal::Traced`].
//!
//! **Nothing is traced any more.** NF holds its upward edges weakly, so the
//! frontend and the new backend are acyclic and every generated type declares
//! `Traced = No`; what cycles remain possible are closed through a `Mutable`
//! cell, which [`crate::gc`] collects over `Arc` without a tracing pointer.
//! The traced arm and the dumpster dependency are gone.
//!
//! What is left is the spine selection itself: [`Spine`] still resolves a
//! payload to its container allocation, and [`MmVal`] is still implemented by
//! every generated type, because both appear in generated code. Both arms now
//! answer `Arc`.

use std::cell::RefCell;
use std::rc::Rc;
use std::sync::Arc;

/// Every generated `mm_accept` is written `fn mm_accept<V: Visitor>(&self, v:
/// &mut V)`, so the parameter has to keep existing. Nothing implements it any
/// more -- NF is acyclic, every type declares `Traced = No`, and the generated
/// bodies are all `Ok(())` -- but it stays so that code compiles unchanged.
pub trait Visitor {}

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

/// Kept so the type-level disjunction still has two inhabitants; it allocates
/// exactly as `No` does now. Nothing declares `Traced = Yes`.
impl Traced for Yes {
    type Or<B: Traced> = Yes;
    type Ptr<U: MmVal> = Arc<U>;
    type RcPtr<U: MmVal> = Rc<U>;
}

/// Shorthand for the disjunction of two flags.
pub type Or<A, B> = <<A as MmVal>::Traced as Traced>::Or<<B as MmVal>::Traced>;

// ── the two spine allocations ────────────────────────────────────────────────

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
/// spine and stops: a collector visits each cell once and counts the sharing
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
/// through the spine, which the collector walks for us.
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

    /// Every spine is an `Arc` now that the traced arm is gone. The selection
    /// machinery is still exercised -- tuples and nesting still compute the
    /// disjunction -- it just has one answer.
    #[test]
    fn spine_is_selected_per_instantiation() {
        assert!(type_name::<Spine<Arc<i32>, u8>>().contains("Arc"));
        assert!(type_name::<Spine<(Arc<i32>, i32), u8>>().contains("Arc"));
        assert!(type_name::<Spine<Option<Vec<Arc<i32>>>, u8>>().contains("Arc"));
        assert!(type_name::<Spine<arcstr::ArcStr, u8>>().contains("Arc"));
    }
}
