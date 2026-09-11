// Manually written
#![allow(non_snake_case)]

//! `PointerCyclic` — a `Pointer` whose content may transitively contain the
//! cell itself. See [`crate::MutableCyclic`] for why the two are separate.

use std::cell::RefCell;
use std::sync::Arc;

use metamodelica::mmval::{self, GcRef, MmVal, SpinePtr, Visitor};

/// Mirrors `Pointer`: `Mutable` is `mmc_mk_box1(0, data)`, `Immutable` is
/// `mmc_mk_some(data)` and rejects updates. Only the mutable arm can close a
/// cycle, so only it is traced.
pub enum PointerCyclic<T: Clone + MmVal> {
    Mutable(GcRef<RefCell<T>>),
    Immutable(Arc<T>),
}

impl<T: Clone + MmVal> Clone for PointerCyclic<T> {
    fn clone(&self) -> Self {
        match self {
            PointerCyclic::Mutable(c) => PointerCyclic::Mutable(c.clone()),
            PointerCyclic::Immutable(a) => PointerCyclic::Immutable(a.clone()),
        }
    }
}

pub fn create<T: Clone + MmVal>(data: T) -> PointerCyclic<T> {
    PointerCyclic::Mutable(SpinePtr::alloc(RefCell::new(data)))
}

pub fn createImmutable<T: Clone + MmVal>(data: T) -> PointerCyclic<T> {
    PointerCyclic::Immutable(Arc::new(data))
}

/// Infallible, as in the C runtime, which writes through the box pointer
/// without inspecting the ctor tag; updating an immutable pointer is undefined
/// there and a panic here.
pub fn update<T: Clone + MmVal>(mutable: PointerCyclic<T>, data: T) {
    match mutable {
        PointerCyclic::Mutable(cell) => *cell.borrow_mut() = data,
        PointerCyclic::Immutable(_) => {
            panic!("PointerCyclic.update: tried to update an immutable PointerCyclic")
        }
    }
}

pub fn access<T: Clone + MmVal>(mutable: PointerCyclic<T>) -> T {
    match mutable {
        PointerCyclic::Mutable(cell) => cell.borrow().clone(),
        PointerCyclic::Immutable(a) => (*a).clone(),
    }
}

pub fn clone<T: Clone + MmVal>(mutable: PointerCyclic<T>) -> PointerCyclic<T> {
    mutable
}

/// See `Pointer::apply` for why the callback's failure is a panic rather than a
/// propagated error.
pub fn apply<T: Clone + MmVal>(
    mutable: PointerCyclic<T>,
    func: Arc<dyn ::std::ops::Fn(T) -> metamodelica::Result<T> + 'static>,
) -> metamodelica::Result<PointerCyclic<T>> {
    let new = func(access(mutable.clone()))?;
    update(mutable.clone(), new);
    Ok(mutable)
}

/// Same allocation, regardless of content. A `Mutable` and an `Immutable` are
/// never the same allocation, as in the C runtime.
pub fn referenceEq<T: Clone + MmVal>(a: &PointerCyclic<T>, b: &PointerCyclic<T>) -> bool {
    match (a, b) {
        (PointerCyclic::Mutable(x), PointerCyclic::Mutable(y)) => SpinePtr::same(x, y),
        (PointerCyclic::Immutable(x), PointerCyclic::Immutable(y)) => Arc::ptr_eq(x, y),
        _ => false,
    }
}

impl<T: Clone + MmVal> metamodelica::ReferenceEq for PointerCyclic<T> {
    fn reference_eq(&self, other: &Self) -> bool {
        referenceEq(self, other)
    }
}

impl<T: Clone + MmVal> MmVal for PointerCyclic<T> {
    type Traced = mmval::Yes;
    fn mm_accept<V: Visitor>(&self, visitor: &mut V) -> Result<(), ()> {
        match self {
            PointerCyclic::Mutable(c) => c.mm_accept(visitor),
            // An `Arc` is a barrier; see the `mmval` module docs.
            PointerCyclic::Immutable(_) => Ok(()),
        }
    }
}

/// Opaque to the old collector; see [`crate::MutableCyclic`].
impl<T: Clone + MmVal> metamodelica::gc::MMTrace for PointerCyclic<T> {
    fn mm_accept(&self, _: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        Ok(())
    }
}

impl<T: Clone + MmVal + std::fmt::Debug> std::fmt::Debug for PointerCyclic<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            PointerCyclic::Mutable(c) => match c.try_borrow() {
                Ok(v) => write!(f, "PointerCyclic({v:?})"),
                Err(_) => write!(f, "PointerCyclic(<borrowed>)"),
            },
            PointerCyclic::Immutable(a) => write!(f, "PointerCyclic({a:?})"),
        }
    }
}

/// Identity, not content — the same semantics `Pointer` has. Ordered by ctor
/// tag (`Mutable` < `Immutable`) then allocation address, so types containing
/// one can derive `Ord` and `Hash`; pointer-equal clones share an address.
fn pointer_key<T: Clone + MmVal>(p: &PointerCyclic<T>) -> (u8, usize) {
    match p {
        PointerCyclic::Mutable(c) => (0, SpinePtr::addr(c) as usize),
        PointerCyclic::Immutable(a) => (1, Arc::as_ptr(a) as usize),
    }
}

impl<T: Clone + MmVal + PartialEq> PartialEq for PointerCyclic<T> {
    fn eq(&self, other: &Self) -> bool {
        referenceEq(self, other)
    }
}

impl<T: Clone + MmVal + Eq> Eq for PointerCyclic<T> {}

impl<T: Clone + MmVal + PartialOrd> PartialOrd for PointerCyclic<T> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(pointer_key(self).cmp(&pointer_key(other)))
    }
}

impl<T: Clone + MmVal + Ord> Ord for PointerCyclic<T> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        pointer_key(self).cmp(&pointer_key(other))
    }
}

impl<T: Clone + MmVal> std::hash::Hash for PointerCyclic<T> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        std::hash::Hash::hash(&pointer_key(self), state);
    }
}

impl<T: Clone + MmVal + Default> Default for PointerCyclic<T> {
    fn default() -> Self {
        create(T::default())
    }
}
