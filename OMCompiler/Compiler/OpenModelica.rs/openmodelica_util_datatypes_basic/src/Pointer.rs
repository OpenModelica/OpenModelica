// Manually written
#![allow(non_snake_case)]
use std::sync::Arc;

use metamodelica::gc::{MMTrace, MMVisitor, TraceableCell};

use crate::Mutable::{cell_get, cell_set, new_cell, CellInner};

// Mirrors the MetaModelica/C representation: `Mutable` corresponds to
// `mmc_mk_box1(0, data)` (ctor 0, in-place updatable) and `Immutable`
// corresponds to `mmc_mk_some(data)` (ctor 1, update rejected at runtime).
// The mutable variant shares `CellInner` with `Mutable.Mutable` so both cell
// kinds register with the same cycle-collector machinery.
pub enum Pointer<T> {
    Mutable(Arc<CellInner<T>>),
    Immutable(Arc<T>),
}

impl<T> Clone for Pointer<T> {
    fn clone(&self) -> Self {
        match self {
            Pointer::Mutable(a) => Pointer::Mutable(Arc::clone(a)),
            Pointer::Immutable(a) => Pointer::Immutable(Arc::clone(a)),
        }
    }
}

impl<T> std::fmt::Debug for Pointer<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Pointer::Mutable(a) => write!(f, "Pointer::Mutable({:p})", Arc::as_ptr(a)),
            Pointer::Immutable(a) => write!(f, "Pointer::Immutable({:p})", Arc::as_ptr(a)),
        }
    }
}

impl<T: PartialEq> PartialEq for Pointer<T> {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Pointer::Mutable(a), Pointer::Mutable(b)) => Arc::ptr_eq(a, b),
            (Pointer::Immutable(a), Pointer::Immutable(b)) => Arc::ptr_eq(a, b),
            _ => false,
        }
    }
}

/// `Eq` follows trivially from pointer equality — `Arc::ptr_eq` is
/// reflexive/symmetric/transitive — but we still gate it on `T: Eq` so
/// the bound stays in lockstep with `PartialEq` for callers.
impl<T: Eq> Eq for Pointer<T> {}

/// Total order by ctor tag (`Mutable` < `Immutable`) and then by the
/// pointer's numeric address. Used so types transitively containing a
/// `Pointer` (e.g. anything wrapping an `NFVariable`) can derive `Ord`
/// for hash-free containers like `BTreeMap` and the generated
/// `valueCompare` lowering. The ordering is stable across `clone()` of
/// the same `Pointer` because pointer-equal clones share the same
/// `Arc::as_ptr` address.
fn pointer_key<T>(p: &Pointer<T>) -> (u8, usize) {
    match p {
        Pointer::Mutable(a) => (0, Arc::as_ptr(a) as usize),
        Pointer::Immutable(a) => (1, Arc::as_ptr(a) as usize),
    }
}

impl<T: PartialOrd + PartialEq> PartialOrd for Pointer<T> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(pointer_key(self).cmp(&pointer_key(other)))
    }
}

impl<T: Ord> Ord for Pointer<T> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        pointer_key(self).cmp(&pointer_key(other))
    }
}

/// `Hash` mirrors the pointer-equality semantics: hash the ctor tag plus
/// the pointer address. Two pointers compare equal via [`PartialEq`] iff
/// they have the same tag and the same address, so this satisfies the
/// `k1 == k2 ⇒ hash(k1) == hash(k2)` contract.
impl<T> std::hash::Hash for Pointer<T> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        pointer_key(self).hash(state);
    }
}

/// Both variants are shared allocations and are reported as such; the
/// mutable variant additionally aborts the collection when locked by
/// another thread (`Err` from `trace_content`).
impl<T: MMTrace> MMTrace for Pointer<T> {
    fn mm_accept(&self, visitor: &mut dyn MMVisitor) -> Result<(), ()> {
        match self {
            Pointer::Mutable(a) => {
                if visitor.visit_shared(
                    Arc::as_ptr(a) as *const (),
                    Arc::strong_count(a),
                    std::any::type_name::<CellInner<T>>(),
                ) {
                    let r = a.trace_content(visitor);
                    visitor.leave_shared();
                    r
                } else {
                    Ok(())
                }
            }
            Pointer::Immutable(a) => a.mm_accept(visitor),
        }
    }
}

/// Codegen synthesizes `Default::default()` for record fields whose type
/// transitively involves a `Pointer<...>` (e.g. NFFunction's `status:
/// Pointer<FunctionStatus>`, `callCounter: Pointer<Integer>`). The
/// MetaModelica/C runtime never allocates an "empty" pointer slot — every
/// `Pointer` is materialised by `Mutable.create(value)` or
/// `Pointer.create(value)`. We mirror that by initialising the slot with
/// `T::default()` boxed in a fresh `Mutable` cell, so downstream
/// `Mutable.update` / `Mutable.access` operate against a real cell rather
/// than panicking. The `MMTrace + 'static` bounds come from registering the
/// fresh cell with the cycle collector.
impl<T: Clone + Default + MMTrace + 'static> Default for Pointer<T> {
    fn default() -> Self {
        Pointer::Mutable(new_cell(T::default()))
    }
}

pub fn create<T: Clone + PartialEq + MMTrace + 'static>(data: T) -> Pointer<T> {
    Pointer::Mutable(new_cell(data))
}

pub fn createImmutable<T: Clone + PartialEq>(data: T) -> Pointer<T> {
    Pointer::Immutable(Arc::new(data))
}

// The MetaModelica/C runtime treats `update` as infallible: it writes through
// the box pointer without inspecting the ctor tag. Passing an immutable
// pointer is undefined behaviour at the C level; we surface that as a Rust
// panic rather than a `Result` because every caller would `unwrap`.
pub fn update<T: Clone + PartialEq>(mutable: Pointer<T>, data: T) {
    match mutable {
        Pointer::Mutable(cell) => cell_set(&cell, data),
        Pointer::Immutable(_) => panic!("Pointer.update: tried to update an immutable Pointer"),
    }
}

pub fn access<T: Clone + PartialEq>(mutable: Pointer<T>) -> T {
    match mutable {
        Pointer::Mutable(cell) => cell_get(&cell),
        Pointer::Immutable(a) => (*a).clone(),
    }
}

pub fn clone<T: Clone + PartialEq>(mutable: Pointer<T>) -> Pointer<T> {
    mutable
}

// `func` is a callback. Per the fallibility convention, function-pointer slots
// remain `fn(T) -> Result<T>` so the same slot can carry either fallible or
// infallible callees (codegen wraps infallible ones via `fnptr!`). The body
// itself is infallible — but it has to `?`-propagate failures from the
// callback. We can't, because we now return `T`. Resolve this by `unwrap()`ing
// the callback result: the MM analysis classified `Pointer.apply` infallible
// based on its callees, which is only sound when the callback itself never
// fails. Surface a misuse as a panic, consistent with the C runtime.
pub fn apply<T: Clone + PartialEq + 'static>(mutable: Pointer<T>, func: std::sync::Arc<dyn ::std::ops::Fn(T) -> anyhow::Result<T> + 'static>) -> anyhow::Result<Pointer<T>> {
    let new = func(access(mutable.clone()))?;
    // The MM source skips the write when `func` returned its argument
    // unchanged (`if not referenceEq(newData, data)`). With `T` passed by
    // value there is no identity to observe — a pointer comparison of two
    // locals is always false — so write unconditionally; when the data is
    // unchanged the write is semantically a no-op.
    update(mutable.clone(), new);
    Ok(mutable)
}

/// MetaModelica `referenceEq` on pointer cells: true iff both handles
/// designate the same allocation. A `Mutable` and an `Immutable` cell are
/// never the same allocation (they are distinct boxes in the C runtime too).
/// Contents are irrelevant. Called from generated code (the builtin
/// `referenceEq` lowering dispatches here because the `Arc` payload is not
/// reachable through a `Deref`). Takes references: the call site only needs
/// identity, never ownership.
pub fn referenceEq<T>(a: &Pointer<T>, b: &Pointer<T>) -> bool {
    match (a, b) {
        (Pointer::Mutable(x), Pointer::Mutable(y)) => Arc::ptr_eq(x, y),
        (Pointer::Immutable(x), Pointer::Immutable(y)) => Arc::ptr_eq(x, y),
        _ => false,
    }
}

/// Identity of the underlying cell, same as the free [`referenceEq`] the
/// concrete-typed lowering dispatches to.
impl<T> metamodelica::ReferenceEq for Pointer<T> {
    fn reference_eq(&self, other: &Self) -> bool {
        referenceEq(self, other)
    }
}
