// Manually written
#![allow(non_snake_case)]

//! `MutableWeak` — a non-owning reference to a [`crate::Mutable`] cell.
//!
//! This is how an ownership cycle is broken so plain reference counting can
//! reclaim it: the parent owns its children, each child refers back weakly, and
//! the structure hangs off one strong root. No collector is involved.

use std::sync::{Arc, Weak};

use crate::Mutable::{CellInner, Mutable};

pub struct MutableWeak<T: Clone>(Weak<CellInner<T>>);

impl<T: Clone> Clone for MutableWeak<T> {
    fn clone(&self) -> Self {
        MutableWeak(self.0.clone())
    }
}

/// The Rust port has real weak semantics, so a cell needs an owner.
pub const ownership: bool = true;

type CellSet = std::sync::Mutex<Vec<Arc<dyn metamodelica::gc::TraceableCell>>>;

/// A set of cells held alive together. A `Mutable` cell is owned by the node
/// value that carries it, but a node reached weakly can outlive every value
/// that owned it, so the structure the nodes belong to holds their cells here
/// and they die with it.
pub struct Roots(Arc<CellSet>);

impl Clone for Roots {
    fn clone(&self) -> Self {
        Roots(Arc::clone(&self.0))
    }
}

thread_local! {
    /// The set `root` adds to.
    static CURRENT: std::cell::RefCell<Roots> = std::cell::RefCell::new(Roots::new());
}

impl Roots {
    fn new() -> Self {
        Roots(Arc::new(std::sync::Mutex::new(Vec::new())))
    }

    fn stats(&self) -> (usize, usize, usize, usize) {
        let cells = self.0.lock().unwrap();
        let (mut sole, mut sole_weak, mut shared) = (0, 0, 0);
        for c in cells.iter() {
            // This set's own reference is in the strong count, so 1 means
            // dropping the set is what frees the cell.
            if Arc::strong_count(c) == 1 {
                sole += 1;
                if Arc::weak_count(c) > 0 {
                    sole_weak += 1;
                }
            } else {
                shared += 1;
            }
        }
        (cells.len(), sole, sole_weak, shared)
    }
}

impl Default for Roots {
    fn default() -> Self {
        Roots::new()
    }
}

/// `OPENMODELICA_ROOT_STATS=1` reports what a set is holding when it goes: how
/// much of it the owning structure is the last reference to, and how much of
/// that something still names weakly.
fn report(roots: &Roots, what: &str) {
    if std::env::var_os("OPENMODELICA_ROOT_STATS").is_some() {
        let (total, sole, sole_weak, shared) = roots.stats();
        eprintln!(
            "root-stats ({what}): {total} rooted, {sole} held only here ({sole_weak} of them \
             still weakly referenced), {shared} owned elsewhere"
        );
    }
}

/// A fresh set, and the one [`root`] adds to from here on. Held here too, so
/// the owner dropping it is not enough to free the cells.
pub fn newRoots() -> Roots {
    let roots = Roots::new();
    CURRENT.with(|c| {
        report(&c.borrow(), "replaced");
        *c.borrow_mut() = roots.clone();
    });
    roots
}

/// Add to `roots` again, for re-entering a structure built by an earlier run.
pub fn useRoots(roots: Roots) {
    CURRENT.with(|c| *c.borrow_mut() = roots);
}

/// Empty the current set.
///
/// Emptied, not dropped: the tree holds the set back through
/// `TOP_SCOPE.roots`, and the top node lives in one of these cells, so the two
/// keep each other alive and letting go of this handle frees nothing.
///
/// That the set outlives the tree is deliberate -- a `ComponentRef` walks up
/// into nodes after the scope that built them is gone -- so only a caller that
/// knows it is done with a library may call this.
pub fn clearRoots() {
    CURRENT.with(|c| {
        let roots = c.borrow().clone();
        report(&roots, "cleared");
        roots.0.lock().unwrap().clear();
        *c.borrow_mut() = Roots::new();
    });
}

/// Add a cell to the current set. A no-op in the bootstrapped compiler, where
/// a weak reference is the strong one.
pub fn root<T: Clone + metamodelica::gc::MMTrace + 'static>(mutable: Mutable<T>) {
    if crate::Mutable::stats::enabled() {
        crate::Mutable::stats::bump(&crate::Mutable::stats::ROOTED);
    }
    let cell: Arc<dyn metamodelica::gc::TraceableCell> = mutable.0;
    CURRENT.with(|c| c.borrow().0.lock().unwrap().push(cell));
}

// Identity, like `Pointer`'s: a set is a place, not a value.

impl PartialEq for Roots {
    fn eq(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.0, &other.0)
    }
}

impl Eq for Roots {}

impl PartialOrd for Roots {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Roots {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        (Arc::as_ptr(&self.0) as *const ()).cmp(&(Arc::as_ptr(&other.0) as *const ()))
    }
}

impl std::hash::Hash for Roots {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        std::hash::Hash::hash(&(Arc::as_ptr(&self.0) as *const ()), state);
    }
}

impl std::fmt::Debug for Roots {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Roots({})", self.0.lock().map(|c| c.len()).unwrap_or(0))
    }
}

impl metamodelica::ReferenceEq for Roots {
    fn reference_eq(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.0, &other.0)
    }
}

/// The cells are held, not owned in the MetaModelica sense: they are already
/// reachable from the structure this set belongs to.
impl metamodelica::gc::MMTrace for Roots {
    fn mm_accept(&self, _: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        Ok(())
    }
}

/// A dangling reference, for a record field that has not been assigned yet.
/// Upgrading it fails the same way any dead referent does.
impl<T: Clone> Default for MutableWeak<T> {
    fn default() -> Self {
        MutableWeak(Weak::new())
    }
}

/// Only the C compiler stores a value in place of a cell; the Rust port has
/// real weak semantics and always has a cell.
pub fn ofValue<T: Clone>(_val: T) -> MutableWeak<T> {
    unreachable!("MutableWeak.ofValue is for the C compiler only")
}

pub fn value<T: Clone>(_weak: MutableWeak<T>) -> T {
    unreachable!("MutableWeak.value is for the C compiler only")
}

/// A reference that does not keep the cell alive. Never fails.
pub fn downgrade<T: Clone>(mutable: Mutable<T>) -> MutableWeak<T> {
    MutableWeak(Arc::downgrade(&mutable.0))
}

/// An owning cell again. Fails if the referent is already gone — a weak
/// reference outlived the structure that owned it, so the ownership split is
/// wrong somewhere. Dereferencing a cell never fails; only this conversion does.
/// As [`upgrade`], counted separately: only this one is followed by a record
/// copy (`InstNode.fromCell` -> `reown`).
pub fn upgradeOwning<T: Clone>(weak: MutableWeak<T>) -> metamodelica::Result<Mutable<T>> {
    if crate::Mutable::stats::enabled() {
        crate::Mutable::stats::bump(&crate::Mutable::stats::UPGRADED_OWNING);
    }
    upgrade_impl(weak)
}

pub fn upgrade<T: Clone>(weak: MutableWeak<T>) -> metamodelica::Result<Mutable<T>> {
    if crate::Mutable::stats::enabled() {
        crate::Mutable::stats::bump(&crate::Mutable::stats::UPGRADED);
    }
    upgrade_impl(weak)
}

fn upgrade_impl<T: Clone>(weak: MutableWeak<T>) -> metamodelica::Result<Mutable<T>> {
    if crate::Mutable::sample::enabled() {
        crate::Mutable::sample::tick();
    }
    match weak.0.upgrade() {
        Some(cell) => Ok(Mutable(cell)),
        None => {
            if std::env::var_os("OPENMODELICA_WEAK_TRACE").is_some() {
                eprintln!(
                    "MutableWeak.upgrade: dead referent\n{}",
                    std::backtrace::Backtrace::force_capture()
                );
            }
            Err("MutableWeak.upgrade: the referent is gone")
        }
    }
}

/// Same cell, as `Mutable`'s `referenceEq` is. Two dead references are never
/// equal: neither designates a cell any more.
pub fn referenceEq<T: Clone>(a: &MutableWeak<T>, b: &MutableWeak<T>) -> bool {
    Weak::ptr_eq(&a.0, &b.0) && a.0.strong_count() > 0
}

impl<T: Clone> metamodelica::ReferenceEq for MutableWeak<T> {
    fn reference_eq(&self, other: &Self) -> bool {
        referenceEq(self, other)
    }
}

/// A weak reference owns nothing, so it reports nothing — that is exactly what
/// makes it break the cycle rather than merely hide it.
impl<T: Clone> metamodelica::gc::MMTrace for MutableWeak<T> {
    fn mm_accept(&self, _: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        Ok(())
    }
}

impl<T: Clone + std::fmt::Debug> std::fmt::Debug for MutableWeak<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self.0.upgrade() {
            Some(_) => write!(f, "MutableWeak(<live>)"),
            None => write!(f, "MutableWeak(<gone>)"),
        }
    }
}

// Identity, like `Pointer`'s: content-based comparison would have to upgrade,
// and a weak reference is a link rather than a value.

fn key<T: Clone>(w: &MutableWeak<T>) -> usize {
    w.0.as_ptr() as usize
}

impl<T: Clone> PartialEq for MutableWeak<T> {
    fn eq(&self, other: &Self) -> bool {
        key(self) == key(other)
    }
}

impl<T: Clone> Eq for MutableWeak<T> {}

impl<T: Clone> PartialOrd for MutableWeak<T> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(key(self).cmp(&key(other)))
    }
}

impl<T: Clone> Ord for MutableWeak<T> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        key(self).cmp(&key(other))
    }
}

impl<T: Clone> std::hash::Hash for MutableWeak<T> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        std::hash::Hash::hash(&key(self), state);
    }
}
