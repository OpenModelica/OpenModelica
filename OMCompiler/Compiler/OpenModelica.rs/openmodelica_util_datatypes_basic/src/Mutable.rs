// Manually written
#![allow(non_snake_case)]
use std::sync::{Arc, Mutex, Weak};

use metamodelica::gc::{MMTrace, MMVisitor, TraceableCell};

/// The shared allocation behind both [`Mutable`] and `Pointer::Mutable`
/// cells. The content lives in an `Option` so the cycle collector can
/// *poison* a cell proven unreachable — dropping the content (which breaks
/// the cycle and lets ordinary `Arc` drops cascade) while leaving the
/// allocation itself intact for any in-cycle handles still being torn down.
/// `None` is only ever observed by a collector bug; accessors panic on it
/// rather than inventing a value.
pub struct CellInner<T> {
    content: Mutex<Option<T>>,
}

impl<T: MMTrace> TraceableCell for CellInner<T> {
    fn trace_content(&self, visitor: &mut dyn MMVisitor) -> Result<(), ()> {
        match self.content.try_lock().map_err(|_| ())?.as_ref() {
            Some(x) => x.mm_accept(visitor),
            None => Ok(()), // already poisoned: nothing to trace
        }
    }

    fn poison(&self) {
        let mut guard = self
            .content
            .lock()
            .expect("Mutable cell poisoned (a thread panicked while updating it)");
        *guard = None;
    }
}

/// Allocate a cell and register it with the cycle collector. Every cell —
/// `Mutable` or `Pointer::Mutable`, explicit or `Default`-synthesized — must
/// go through here: an unregistered cell is never a collection candidate, so
/// cycles through it would silently leak.
pub(crate) fn new_cell<T: Clone + MMTrace + 'static>(data: T) -> Arc<CellInner<T>> {
    let inner = Arc::new(CellInner { content: Mutex::new(Some(data)) });
    let weak: Weak<dyn TraceableCell> = Arc::downgrade(&inner) as _;
    metamodelica::gc::register_cell(weak);
    inner
}

/// Read access for the cell-based types in this crate (`Pointer` shares
/// `CellInner`). Panics if the cell was reclaimed by the cycle collector —
/// reaching such a cell means the collector freed live data, which is a bug
/// in the collector, not in the caller.
pub(crate) fn cell_get<T: Clone>(cell: &CellInner<T>) -> T {
    cell.content
        .lock()
        .expect("Mutable cell poisoned (a thread panicked while updating it)")
        .as_ref()
        .expect("accessed a cycle-collected mutable cell")
        .clone()
}

pub(crate) fn cell_set<T>(cell: &CellInner<T>, data: T) {
    let mut guard = cell
        .content
        .lock()
        .expect("Mutable cell poisoned (a thread panicked while updating it)");
    *guard = Some(data);
}

pub struct Mutable<T: Clone>(pub(crate) Arc<CellInner<T>>);

impl<T: Clone> Clone for Mutable<T> {
    fn clone(&self) -> Self {
        Mutable(Arc::clone(&self.0))
    }
}

impl<T: Clone + std::fmt::Debug> std::fmt::Debug for Mutable<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self.0.content.try_lock() {
            Ok(guard) => match guard.as_ref() {
                Some(v) => write!(f, "Mutable({v:?})"),
                None => write!(f, "Mutable(<collected>)"),
            },
            Err(_) => write!(f, "Mutable(<locked>)"),
        }
    }
}

// `PartialEq` is a conditional impl rather than a struct-level bound so
// that `Mutable<T>` can store values whose `T` does not implement
// `PartialEq` (notably callbacks: `&impl Fn(...)` and similar). MM-level
// code only invokes structural equality on `Mutable<T>` when `T` itself
// is comparable.
impl<T: Clone + PartialEq> PartialEq for Mutable<T> {
    fn eq(&self, other: &Self) -> bool {
        // Identity first: also keeps a self-comparison from deadlocking on
        // the second lock below.
        if Arc::ptr_eq(&self.0, &other.0) {
            return true;
        }
        let self_guard = self.0.content.lock().unwrap();
        let other_guard = other.0.content.lock().unwrap();
        *self_guard == *other_guard
    }
}

/// `Eq` mirrors `PartialEq` (both are content-based). Implemented as a
/// conditional impl on `T: Eq` so wrappers around non-`Eq` types still
/// compile; only callers that demand `Eq` on the wrapper pay the bound.
impl<T: Clone + Eq> Eq for Mutable<T> {}

/// Content-based ordering. Mirrors `PartialEq`'s "lock both, compare
/// inner values" pattern (with the same identity short-circuit so a
/// self-comparison cannot self-deadlock). Locks are always acquired
/// self-then-other in declaration order so the routine is deadlock-free
/// against itself (cross-thread Mutable comparisons assume no concurrent
/// reordering of the same pair of cells in opposite order, which the
/// codegen never generates).
impl<T: Clone + PartialOrd> PartialOrd for Mutable<T> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        if Arc::ptr_eq(&self.0, &other.0) {
            return Some(std::cmp::Ordering::Equal);
        }
        let self_guard = self.0.content.lock().unwrap();
        let other_guard = other.0.content.lock().unwrap();
        (*self_guard).partial_cmp(&*other_guard)
    }
}

impl<T: Clone + Ord> Ord for Mutable<T> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        if Arc::ptr_eq(&self.0, &other.0) {
            return std::cmp::Ordering::Equal;
        }
        let self_guard = self.0.content.lock().unwrap();
        let other_guard = other.0.content.lock().unwrap();
        (*self_guard).cmp(&*other_guard)
    }
}

// `Hash` is deliberately NOT implemented. Like `std::cell::RefCell`, the
// interior value can change after a hash has been computed but before the
// hash is consumed; a hashable cell would silently corrupt hash containers
// when the contents mutated. Codegen excludes `Hash` from the derive set
// for any type that transitively contains a `Mutable` (in fact such types
// only carry `PartialEq` — see `derives_for` in `mmtorust/src/codegen.rs`).

/// `Default` is exposed so records containing a `Mutable<T>` can themselves
/// derive `Default` (used by the codegen lowering of `arrayCreateNoInit`
/// when the type-witness dummy is unassigned). The default `Mutable` holds a
/// fresh `T::default()` and is registered with the collector like any other
/// cell (the `MMTrace + 'static` bounds come from that registration).
impl<T: Clone + Default + MMTrace + 'static> Default for Mutable<T> {
    fn default() -> Self {
        Mutable(new_cell(T::default()))
    }
}

pub fn create<T: Clone + MMTrace + 'static>(data: T) -> Mutable<T> {
    Mutable(new_cell(data))
}

pub fn update<T: Clone>(mutable: Mutable<T>, data: T) {
    cell_set(&mutable.0, data);
}

pub fn access<T: Clone>(mutable: Mutable<T>) -> T {
    cell_get(&mutable.0)
}

/// MetaModelica `referenceEq` on mutable cells: true iff both handles
/// designate the same cell (same `Arc` allocation). Contents are irrelevant —
/// two distinct cells holding equal values are not reference-equal. Called
/// from generated code (the builtin `referenceEq` lowering dispatches here
/// because the `Arc` field is private). Takes references: the call site only
/// needs identity, never ownership.
pub fn referenceEq<T: Clone>(a: &Mutable<T>, b: &Mutable<T>) -> bool {
    Arc::ptr_eq(&a.0, &b.0)
}

/// Identity of the underlying cell, same as the free [`referenceEq`] the
/// concrete-typed lowering dispatches to.
impl<T: Clone> metamodelica::ReferenceEq for Mutable<T> {
    fn reference_eq(&self, other: &Self) -> bool {
        referenceEq(self, other)
    }
}

/// The cell is a shared allocation: report it, then trace the content once.
/// A cell locked by another thread aborts the collection (`Err`).
impl<T: Clone + MMTrace> MMTrace for Mutable<T> {
    fn mm_accept(&self, visitor: &mut dyn MMVisitor) -> Result<(), ()> {
        if visitor.visit_shared(
            Arc::as_ptr(&self.0) as *const (),
            Arc::strong_count(&self.0),
            std::any::type_name::<CellInner<T>>(),
        ) {
            let r = self.0.trace_content(visitor);
            visitor.leave_shared();
            r
        } else {
            Ok(())
        }
    }
}
