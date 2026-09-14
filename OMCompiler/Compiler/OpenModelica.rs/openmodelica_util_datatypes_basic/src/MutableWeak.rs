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

thread_local! {
    /// Cells kept alive for the current frontend run. `Mutable` cells are
    /// owned by the node values that carry them, but a node whose value has
    /// died is still reachable weakly, so the run holds those here until
    /// `clearRoots`.
    static ROOTED_CELLS: std::cell::RefCell<Vec<Arc<dyn metamodelica::gc::TraceableCell>>> =
        const { std::cell::RefCell::new(Vec::new()) };
}

/// Keep a cell alive for the current run. A no-op in the bootstrapped
/// compiler, where a weak reference is the strong one.
thread_local! {
    /// See `Mutable::stats`.
    pub static UPGRADED: std::cell::Cell<u64> = const { std::cell::Cell::new(0) };
    pub static UPGRADED_OWNING: std::cell::Cell<u64> = const { std::cell::Cell::new(0) };
    pub static ROOTED: std::cell::Cell<u64> = const { std::cell::Cell::new(0) };
}

pub fn root<T: Clone + metamodelica::gc::MMTrace + 'static>(mutable: Mutable<T>) {
    if crate::Mutable::stats::enabled() {
        crate::Mutable::stats::bump(&ROOTED);
    }
    let cell: Arc<dyn metamodelica::gc::TraceableCell> = mutable.0;
    ROOTED_CELLS.with(|r| r.borrow_mut().push(cell));
}

/// Drop everything [`root`] is holding.
pub fn clearRoots() {
    ROOTED_CELLS.with(|r| {
        let mut cells = r.borrow_mut();
        if std::env::var_os("OPENMODELICA_ROOT_STATS").is_some() {
            let (mut sole, mut sole_weak, mut shared) = (0usize, 0usize, 0usize);
            for c in cells.iter() {
                // The root's own reference is included in the strong count, so
                // 1 means dropping it here is what frees the cell.
                if Arc::strong_count(c) == 1 {
                    sole += 1;
                    if Arc::weak_count(c) > 0 {
                        sole_weak += 1;
                    }
                } else {
                    shared += 1;
                }
            }
            eprintln!(
                "root-stats: {} rooted, {} freed by the clear ({} of them still \
                 weakly referenced), {} owned elsewhere",
                cells.len(),
                sole,
                sole_weak,
                shared
            );
        }
        cells.clear();
    });
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
        crate::Mutable::stats::bump(&UPGRADED_OWNING);
    }
    upgrade_impl(weak)
}

pub fn upgrade<T: Clone>(weak: MutableWeak<T>) -> metamodelica::Result<Mutable<T>> {
    if crate::Mutable::stats::enabled() {
        crate::Mutable::stats::bump(&UPGRADED);
    }
    upgrade_impl(weak)
}

/// `OPENMODELICA_CELL_SAMPLE=N` captures a backtrace every Nth upgrade and
/// aggregates by the innermost frontend frame, so the scope walks doing the
/// ~5M reads can be named rather than guessed at. Sampling, because a capture
/// costs far more than the upgrade it is measuring.
pub mod sample {
    use std::cell::RefCell;
    use std::collections::BTreeMap;
    thread_local! {
        static N: std::cell::Cell<u64> = const { std::cell::Cell::new(0) };
        static SEEN: std::cell::Cell<u64> = const { std::cell::Cell::new(0) };
        static HITS: RefCell<BTreeMap<String, usize>> = RefCell::new(BTreeMap::new());
    }
    fn every() -> u64 {
        static E: std::sync::OnceLock<u64> = std::sync::OnceLock::new();
        *E.get_or_init(|| {
            std::env::var("OPENMODELICA_CELL_SAMPLE")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(0)
        })
    }
    pub fn enabled() -> bool {
        every() > 0
    }
    /// The innermost `openmodelica_*` frame that is not part of the cell
    /// machinery itself -- that is the caller worth naming.
    fn innermost(bt: &str) -> String {
        for line in bt.lines() {
            let l = line.trim();
            let Some(i) = l.find("openmodelica_") else { continue };
            let sym = &l[i..];
            let sym = sym.split(&[' ', '(', ':'][..]).next().unwrap_or(sym);
            // Skip the cell machinery itself: `borrow`/`fromCell` are always
            // the innermost frontend frames, so naming them says nothing.
            const MACHINERY: [&str; 6] = [
                "MutableWeak",
                "::Mutable::",
                "InstNode::borrow",
                "InstNode::fromCell",
                "InstNode::fromHandle",
                "InstNode::fromIdentity",
            ];
            if MACHINERY.iter().any(|m| l.contains(m)) {
                continue;
            }
            let end = l[i..].find(" at ").map(|e| i + e).unwrap_or(l.len());
            let full = l[i..end].trim().to_string();
            if !full.is_empty() {
                return full;
            }
            return sym.to_string();
        }
        "<unattributed>".to_string()
    }
    pub fn tick() {
        let e = every();
        let n = N.with(|c| {
            let v = c.get() + 1;
            c.set(v);
            v
        });
        if n % e != 0 {
            return;
        }
        SEEN.with(|c| c.set(c.get() + 1));
        let bt = std::backtrace::Backtrace::force_capture().to_string();
        let key = innermost(&bt);
        HITS.with(|h| *h.borrow_mut().entry(key).or_insert(0) += 1);
    }
    pub fn report() -> (u64, Vec<(String, usize)>) {
        let mut v: Vec<(String, usize)> =
            HITS.with(|h| h.borrow().iter().map(|(k, n)| (k.clone(), *n)).collect());
        v.sort_by(|a, b| b.1.cmp(&a.1));
        (SEEN.with(|c| c.get()), v)
    }
}

fn upgrade_impl<T: Clone>(weak: MutableWeak<T>) -> metamodelica::Result<Mutable<T>> {
    if sample::enabled() {
        sample::tick();
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
impl<T: Clone + metamodelica::mmval::MmVal> metamodelica::mmval::MmVal for MutableWeak<T> {
    type Traced = metamodelica::mmval::No;
    fn mm_accept<V: metamodelica::mmval::Visitor>(&self, _: &mut V) -> Result<(), ()> {
        Ok(())
    }
}

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
