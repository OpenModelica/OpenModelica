//! The MetaModelica `array<T>` handle. Operations live in [`crate::array`].

use std::cell::RefCell;

use crate::mmval::{MmVal, RcSpine, SpinePtr, Visitor};

/// MetaModelica `array<T>`: shared, interior-mutable storage with aliasing
/// semantics (see the crate docs).
///
/// The spine follows the element type: `Rc` for elements that cannot reach a
/// traced allocation, `Gc` for those that can. Cycles are closed by cells, not
/// by `arrayUpdate`, but an array *on* such a cycle still has to be a node the
/// collector knows about: an `Rc` is a barrier, and making it descend instead
/// would report a shared array's contents once per path that reaches it.
///
/// A newtype rather than an alias so that `A` stays inferable from `Array<A>` —
/// the spine is a projection of `A`, and projections are not injective.
pub struct Array<A: MmVal>(RcSpine<A, RefCell<Vec<A>>>);

impl<A: MmVal> Array<A> {
    pub fn from_vec(v: Vec<A>) -> Self {
        Array(SpinePtr::alloc(RefCell::new(v)))
    }

    /// Allocation identity, for `referenceEq` and cycle diagnostics.
    pub fn addr(&self) -> *const () {
        SpinePtr::addr(&self.0)
    }

    pub fn ptr_eq(a: &Self, b: &Self) -> bool {
        SpinePtr::same(&a.0, &b.0)
    }

    pub fn strong_count(&self) -> usize {
        SpinePtr::strong_count(&self.0)
    }
}

impl<A: MmVal> std::ops::Deref for Array<A> {
    type Target = RefCell<Vec<A>>;
    fn deref(&self) -> &RefCell<Vec<A>> {
        &self.0
    }
}

impl<A: MmVal> Clone for Array<A> {
    fn clone(&self) -> Self {
        Array(self.0.clone())
    }
}

impl<A: MmVal> MmVal for Array<A> {
    type Traced = <RcSpine<A, RefCell<Vec<A>>> as MmVal>::Traced;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        self.0.mm_accept(visitor)
    }
}

impl<A: MmVal + crate::gc::MMTrace> crate::gc::MMTrace for Array<A> {
    fn mm_accept(&self, visitor: &mut dyn crate::gc::MMVisitor) -> Result<(), ()> {
        if visitor.visit_shared(self.addr(), self.strong_count(), std::any::type_name::<A>()) {
            let r = crate::gc::MMTrace::mm_accept(&**self, visitor);
            visitor.leave_shared();
            r
        } else {
            Ok(())
        }
    }
}

// Element-wise, as `Rc<RefCell<Vec<A>>>` was.

impl<A: MmVal + std::fmt::Debug> std::fmt::Debug for Array<A> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        (**self).fmt(f)
    }
}

impl<A: MmVal + PartialEq> PartialEq for Array<A> {
    fn eq(&self, other: &Self) -> bool {
        **self == **other
    }
}

impl<A: MmVal + Eq> Eq for Array<A> {}

impl<A: MmVal + PartialOrd> PartialOrd for Array<A> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        self.borrow().partial_cmp(&other.borrow())
    }
}

impl<A: MmVal + Ord> Ord for Array<A> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.borrow().cmp(&other.borrow())
    }
}

impl<A: MmVal + std::hash::Hash> std::hash::Hash for Array<A> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.borrow().hash(state)
    }
}

impl<A: MmVal> Default for Array<A> {
    fn default() -> Self {
        Array::from_vec(Vec::new())
    }
}

impl<A: MmVal> crate::value::ReferenceEq for Array<A> {
    fn reference_eq(&self, other: &Self) -> bool {
        Array::ptr_eq(self, other)
    }
}
