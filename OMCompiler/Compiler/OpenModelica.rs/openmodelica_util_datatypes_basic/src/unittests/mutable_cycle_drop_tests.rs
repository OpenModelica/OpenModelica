//! Drop-detection harness for reference cycles built through `Mutable`.
//!
//! The MetaModelica frontend frequently creates a mutable cell with a
//! placeholder and then `Mutable.update`s it with a value that (transitively)
//! contains the cell itself — e.g. `NFInst.mo` updating `cls_ptr` with an
//! `InstNode` whose class points back through that same pointer. In the Rust
//! port both the cell and uniontype values (`Arc<enum>`) are strong
//! references, so such cycles are never freed by refcounting alone; the
//! trial-deletion collector in `metamodelica::gc` reclaims them at explicit
//! `collect()` points (the generated compiler's `GCExt.gcollect`).
//!
//! These tests make collection *observable*: a payload with a `Drop` impl
//! that increments a shared counter, plus a `Weak` handle to the payload.

use metamodelica::gc::{collect, MMTrace, MMVisitor};
use crate::Mutable;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, Weak};

/// Payload whose destruction is observable from the outside.
#[derive(Debug)]
struct DropProbe {
    drops: Arc<AtomicUsize>,
}

impl Drop for DropProbe {
    fn drop(&mut self) {
        self.drops.fetch_add(1, Ordering::SeqCst);
    }
}

/// Leaf payload: a probe can never contain a cell handle.
impl MMTrace for DropProbe {
    fn mm_accept(&self, _visitor: &mut dyn MMVisitor) -> Result<(), ()> {
        Ok(())
    }
}

/// Creates a probe plus the two observation handles: the drop counter and a
/// `Weak` to the probe allocation itself.
fn probe() -> (Arc<DropProbe>, Weak<DropProbe>, Arc<AtomicUsize>) {
    let drops = Arc::new(AtomicUsize::new(0));
    let p = Arc::new(DropProbe { drops: drops.clone() });
    let weak = Arc::downgrade(&p);
    (p, weak, drops)
}

/// Minimal stand-in for a generated uniontype that stores a `Mutable` cell,
/// shaped like `InstNode.CLASS_NODE { cls: Mutable<Arc<...>>, ... }`.
/// Generated uniontypes are `Arc<enum>`, so the cell holds `Arc<Node>`.
#[derive(Clone, Debug)]
enum Node {
    Empty,
    // The fields are only ever constructed and dropped, never read — that is
    // the point of a drop-observation test.
    #[allow(dead_code)]
    Link {
        probe: Arc<DropProbe>,
        next: Mutable::Mutable<Arc<Node>>,
    },
}

/// The shape of the impl mmtorust emits for generated uniontypes: structural
/// delegation into every field (`probe` reports its `Arc`; `next` reports
/// the cell and traces its content once).
impl MMTrace for Node {
    fn mm_accept(&self, visitor: &mut dyn MMVisitor) -> Result<(), ()> {
        match self {
            Node::Empty => Ok(()),
            Node::Link { probe, next } => {
                probe.mm_accept(visitor)?;
                next.mm_accept(visitor)
            }
        }
    }
}

// ── harness sanity: refcounting alone frees acyclic structure ───────────

// No cycle: a cell points at a Link whose `next` is a *different* cell
// holding Empty. Dropping the outer cell must free the payload without any
// collect() — this validates that the probe/Weak machinery can actually
// observe a drop, and that registration does not keep cells alive.
#[test]
fn acyclic_mutable_chain_is_dropped() {
    let (p, weak, drops) = probe();
    let tail = Mutable::create(Arc::new(Node::Empty));
    let head = Mutable::create(Arc::new(Node::Link { probe: p, next: tail }));
    assert_eq!(drops.load(Ordering::SeqCst), 0);
    assert!(weak.upgrade().is_some());
    drop(head);
    assert_eq!(drops.load(Ordering::SeqCst), 1);
    assert!(weak.upgrade().is_none());
}

// ── the cyclic cases ────────────────────────────────────────────────────

/// Builds the create-then-update self-cycle used throughout the frontend:
/// `cell := Mutable.create(placeholder); Mutable.update(cell, value(cell))`.
/// Returns only the observation handles; every strong reference except the
/// in-cycle one has been dropped by the time this returns.
fn build_self_cycle() -> (Weak<DropProbe>, Arc<AtomicUsize>) {
    let (p, weak, drops) = probe();
    let cell = Mutable::create(Arc::new(Node::Empty));
    Mutable::update(
        cell.clone(),
        Arc::new(Node::Link { probe: p, next: cell.clone() }),
    );
    // `cell` (the last external handle) is dropped here.
    (weak, drops)
}

/// Two-cell cycle: a → b → a, mirroring parent/child node pairs that point
/// at each other's cells.
fn build_two_cell_cycle() -> (Weak<DropProbe>, Arc<AtomicUsize>) {
    let (p, weak, drops) = probe();
    let a = Mutable::create(Arc::new(Node::Empty));
    let b = Mutable::create(Arc::new(Node::Link { probe: p, next: a.clone() }));
    Mutable::update(a.clone(), Arc::new(Node::Empty)); // exercise update on a too
    Mutable::update(
        a,
        Arc::new(Node::Link {
            probe: Arc::new(DropProbe { drops: drops.clone() }),
            next: b,
        }),
    );
    (weak, drops)
}

#[test]
fn self_cycle_through_mutable_update_is_dropped() {
    let (weak, drops) = build_self_cycle();
    let stats = collect();
    assert!(!stats.aborted);
    assert_eq!(drops.load(Ordering::SeqCst), 1, "cycle payload was not dropped");
    assert!(weak.upgrade().is_none(), "cycle payload is still alive");
}

#[test]
fn two_cell_cycle_through_mutable_update_is_dropped() {
    let (weak, drops) = build_two_cell_cycle();
    collect();
    // Both Links (one probe each) must be freed.
    assert_eq!(drops.load(Ordering::SeqCst), 2, "cycle payloads were not dropped");
    assert!(weak.upgrade().is_none(), "cycle payload is still alive");
}

// A live cycle must NOT be collected while a handle still roots it.
#[test]
fn live_cycle_survives_collect() {
    let (p, weak, drops) = probe();
    let cell = Mutable::create(Arc::new(Node::Empty));
    Mutable::update(
        cell.clone(),
        Arc::new(Node::Link { probe: p, next: cell.clone() }),
    );
    collect();
    assert_eq!(drops.load(Ordering::SeqCst), 0, "live cycle was freed");
    assert!(weak.upgrade().is_some());
    // ... and once the root goes away, it is collectable.
    drop(cell);
    collect();
    assert_eq!(drops.load(Ordering::SeqCst), 1);
    assert!(weak.upgrade().is_none());
}

// The regression that ruled out tracing-pointer libraries (dumpster freed
// this case): the cycle-closing value is *shared* — the same `Arc<Node>`
// that contains the in-cycle handle is also held on the stack. The cell has
// no external handle of its own, but it is reachable through the shared
// content, so it must survive.
#[test]
fn content_shared_with_stack_survives_collect() {
    let (p, weak, drops) = probe();
    let cell = Mutable::create(Arc::new(Node::Empty));
    let link = Arc::new(Node::Link { probe: p, next: cell.clone() });
    Mutable::update(cell.clone(), link.clone());
    drop(cell);
    collect();
    assert_eq!(drops.load(Ordering::SeqCst), 0, "live payload was freed");
    assert!(weak.upgrade().is_some(), "live payload was freed");
    let Node::Link { next, .. } = &*link else { unreachable!() };
    // Accessing the still-live cell must not panic on a poisoned cell.
    let _ = Mutable::access(next.clone());
    // Dropping the last shared handle makes the cycle garbage.
    drop(link);
    collect();
    assert_eq!(drops.load(Ordering::SeqCst), 1, "dead cycle was not collected");
    assert!(weak.upgrade().is_none());
}

// Cycle through a shared list spine: `cell → Arc<List<cell>> → cell`, with
// the spine also referenced from the stack. Exercises the per-spine-cell
// reporting in `List`'s MMTrace impl.
#[test]
fn cycle_through_shared_list_spine() {
    use metamodelica::{cons, nil, List};

    #[derive(Clone, Debug)]
    enum ListNode {
        Empty,
        #[allow(dead_code)]
        Many {
            probe: Arc<DropProbe>,
            nodes: Arc<List<Mutable::Mutable<Arc<ListNode>>>>,
        },
    }
    impl MMTrace for ListNode {
        fn mm_accept(&self, visitor: &mut dyn MMVisitor) -> Result<(), ()> {
            match self {
                ListNode::Empty => Ok(()),
                ListNode::Many { probe, nodes } => {
                    probe.mm_accept(visitor)?;
                    nodes.mm_accept(visitor)
                }
            }
        }
    }

    let (p, weak, drops) = probe();
    let cell = Mutable::create(Arc::new(ListNode::Empty));
    let spine = cons(cell.clone(), nil());
    Mutable::update(cell.clone(), Arc::new(ListNode::Many { probe: p, nodes: spine.clone() }));
    drop(cell);
    // The spine is still on the stack: everything must survive.
    collect();
    assert_eq!(drops.load(Ordering::SeqCst), 0, "live payload was freed");
    assert!(weak.upgrade().is_some());
    drop(spine);
    // Now the cycle (cell → Many → spine → cell) is unreachable.
    collect();
    assert_eq!(drops.load(Ordering::SeqCst), 1, "list-spine cycle was not collected");
    assert!(weak.upgrade().is_none());
}
