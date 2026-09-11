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

// ── type-level booleans ──────────────────────────────────────────────────────

/// Whether a value can reach a [`Gc`]. See the module docs.
pub trait Traced: 'static {
    /// Disjunction, for types built out of several others (tuples, records).
    type Or<B: Traced>: Traced;
    /// The allocation a container spine uses for this kind of payload.
    type Ptr<U: dumpster::Trace + 'static>: SpinePtr<U>;
}

pub struct No;
pub struct Yes;

impl Traced for No {
    type Or<B: Traced> = B;
    type Ptr<U: dumpster::Trace + 'static> = Arc<U>;
}

impl Traced for Yes {
    type Or<B: Traced> = Yes;
    type Ptr<U: dumpster::Trace + 'static> = Gc<U>;
}

/// Shorthand for the disjunction of two flags.
pub type Or<A, B> = <<A as MmVal>::Traced as Traced>::Or<<B as MmVal>::Traced>;

// ── the two spine allocations ────────────────────────────────────────────────

/// What a shared container allocation must provide. The two implementations
/// differ only in `spine_accept`: the `Gc` arm reports itself to the collector,
/// the `Arc` arm is the barrier.
pub trait SpinePtr<U: ?Sized>: Clone + std::ops::Deref<Target = U> {
    fn alloc(value: U) -> Self
    where
        U: Sized;
    fn spine_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()>;
    fn same(a: &Self, b: &Self) -> bool;
    fn addr(this: &Self) -> *const ();
    /// Unique access, for the in-place list optimisations. The traced arm has
    /// no equivalent and always declines, so those paths fall back to copying.
    fn get_mut(this: &mut Self) -> Option<&mut U>
    where
        U: Sized;
    /// Whether this is the only handle. Same caveat as `get_mut`.
    fn is_unique(this: &Self) -> bool;
}

impl<U: dumpster::Trace + 'static> SpinePtr<U> for Gc<U> {
    fn alloc(value: U) -> Self {
        Gc::new(value)
    }
    fn spine_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        dumpster::TraceWith::accept(self, visitor)
    }
    fn same(a: &Self, b: &Self) -> bool {
        Gc::ptr_eq(a, b)
    }
    fn addr(this: &Self) -> *const () {
        Gc::as_ptr(this) as *const ()
    }
    fn get_mut(_: &mut Self) -> Option<&mut U> {
        None
    }
    fn is_unique(_: &Self) -> bool {
        false
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
    fn get_mut(this: &mut Self) -> Option<&mut U>
    where
        U: Sized,
    {
        Arc::get_mut(this)
    }
    fn is_unique(this: &Self) -> bool {
        Arc::strong_count(this) == 1 && Arc::weak_count(this) == 0
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

impl<T: dumpster::Trace + ?Sized + 'static> MmVal for Gc<T> {
    type Traced = Yes;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        dumpster::TraceWith::accept(self, visitor)
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

/// The persistent list. Its spine is shared, so tracing *through* it would
/// count the handles a shared tail owns once per path that reaches it. That is
/// safe only while the spine cannot hold a traced allocation; when the payload
/// can, the spine itself has to become one (see [`Spine`]).
impl<T: MmVal + Clone> MmVal for crate::List<T> {
    type Traced = T::Traced;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        // Iterative: lists run to tens of thousands of elements.
        let mut cur = self;
        loop {
            let Some(node) = &cur.0 else { return Ok(()) };
            let crate::ListNode::Cons { head, tail } = &**node else { return Ok(()) };
            head.mm_accept(visitor)?;
            cur = tail;
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
        assert!(type_name::<Spine<Gc<i32>, u8>>().contains("Gc"));
        // Tuples and nesting propagate the flag.
        assert!(type_name::<Spine<(Arc<i32>, i32), u8>>().contains("Arc"));
        assert!(type_name::<Spine<(Arc<i32>, Gc<i32>), u8>>().contains("Gc"));
        assert!(type_name::<Spine<Option<Vec<Arc<i32>>>, u8>>().contains("Arc"));
        assert!(type_name::<Spine<Option<Vec<Gc<i32>>>, u8>>().contains("Gc"));
        // A leaf the orphan rule blocks from dumpster's own trait.
        assert!(type_name::<Spine<arcstr::ArcStr, u8>>().contains("Arc"));
    }
}
