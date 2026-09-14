//! The box a recursive MetaModelica value lives in.

use crate::mmval::{MmVal, Spine, SpinePtr, Visitor};

/// A shared handle to a MetaModelica value, as codegen emits around every
/// recursive uniontype.
///
/// The allocation follows the payload: `Arc` for a value that cannot reach a
/// traced allocation — keeping the untraced compiler `Send + Sync` and its
/// interning statics possible — and `Gc` for one that can. Without the second
/// arm the [`MmVal::Traced`] flag would be inert: everything is held through
/// one of these, and an `Arc` reports nothing, so a cycle through a cell would
/// never be found however the cell itself was allocated.
pub struct Ref<T: MmVal>(Spine<T, T>);

impl<T: MmVal> Ref<T> {
    pub fn new(value: T) -> Self {
        Ref(SpinePtr::alloc(value))
    }

    pub fn ptr_eq(a: &Self, b: &Self) -> bool {
        SpinePtr::same(&a.0, &b.0)
    }

    pub fn as_ptr(this: &Self) -> *const () {
        SpinePtr::addr(&this.0)
    }

    pub fn strong_count(this: &Self) -> usize {
        SpinePtr::strong_count(&this.0)
    }

    /// `None` unless this is the only handle. The traced arm always declines;
    /// callers fall back to rebuilding the value.
    pub fn get_mut(this: &mut Self) -> Option<&mut T> {
        SpinePtr::get_mut(&mut this.0)
    }
}

impl<T: MmVal> std::ops::Deref for Ref<T> {
    type Target = T;
    fn deref(&self) -> &T {
        &self.0
    }
}

impl<T: MmVal> AsRef<T> for Ref<T> {
    fn as_ref(&self) -> &T {
        self
    }
}

impl<T: MmVal> std::borrow::Borrow<T> for Ref<T> {
    fn borrow(&self) -> &T {
        self
    }
}

impl<T: MmVal> Clone for Ref<T> {
    fn clone(&self) -> Self {
        Ref(self.0.clone())
    }
}

impl<T: MmVal> From<T> for Ref<T> {
    fn from(value: T) -> Self {
        Ref::new(value)
    }
}

impl<T: MmVal> MmVal for Ref<T> {
    type Traced = T::Traced;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        self.0.mm_accept(visitor)
    }
}

impl<T: MmVal + crate::gc::MMTrace> crate::gc::MMTrace for Ref<T> {
    fn mm_accept(&self, visitor: &mut dyn crate::gc::MMVisitor) -> Result<(), ()> {
        if visitor.visit_shared(
            Ref::as_ptr(self),
            Ref::strong_count(self),
            std::any::type_name::<T>(),
        ) {
            let r = crate::gc::MMTrace::mm_accept(&**self, visitor);
            visitor.leave_shared();
            r
        } else {
            Ok(())
        }
    }
}

impl<T: MmVal> crate::value::ReferenceEq for Ref<T> {
    fn reference_eq(&self, other: &Self) -> bool {
        Ref::ptr_eq(self, other)
    }
}

// Structural, as `Arc` was.

impl<T: MmVal + std::fmt::Debug> std::fmt::Debug for Ref<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        (**self).fmt(f)
    }
}

impl<T: MmVal + PartialEq> PartialEq for Ref<T> {
    fn eq(&self, other: &Self) -> bool {
        **self == **other
    }
}

impl<T: MmVal + Eq> Eq for Ref<T> {}

impl<T: MmVal + PartialOrd> PartialOrd for Ref<T> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        (**self).partial_cmp(&**other)
    }
}

impl<T: MmVal + Ord> Ord for Ref<T> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        (**self).cmp(&**other)
    }
}

impl<T: MmVal + std::hash::Hash> std::hash::Hash for Ref<T> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        (**self).hash(state)
    }
}

impl<T: MmVal + Default> Default for Ref<T> {
    fn default() -> Self {
        Ref::new(T::default())
    }
}
