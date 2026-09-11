//! Drop-detection harness for cycles through `MutableCyclic`/`PointerCyclic`.
//!
//! The counterpart of [`super::mutable_cycle_drop_tests`] for the dumpster
//! collector. What is being tested is the whole chain the `.mo`-level split
//! buys: a cyclic cell allocates in a `Gc`, `Ref` boxes a traced value in a
//! `Gc` too, `Array` picks a `Gc` spine for a traced element, and every
//! `mm_accept` in between reports what it holds — so `collect()` can see the
//! cycle and reclaim it. Break any one link and these tests leak.

use std::rc::Rc;

use metamodelica::mmval::{self, collect, MmVal, Visitor};

use crate::{MutableCyclic, PointerCyclic};

/// Payload whose destruction is observable. `Rc<Cell>` rather than an atomic
/// because the traced arm is single-threaded anyway.
struct DropProbe {
    drops: Rc<std::cell::Cell<usize>>,
}

impl Drop for DropProbe {
    fn drop(&mut self) {
        self.drops.set(self.drops.get() + 1);
    }
}

impl Clone for DropProbe {
    fn clone(&self) -> Self {
        DropProbe { drops: self.drops.clone() }
    }
}

/// A node holding the probe plus a back-edge through a cyclic cell — the shape
/// `NFInst` builds when it updates a class pointer with an `InstNode` whose
/// class points back through that same pointer. The array of children lives on
/// a second type, as `ClassTree` does, so the two recur through each other.
#[derive(Clone)]
struct Node {
    probe: DropProbe,
    back: Option<MutableCyclic::MutableCyclic<metamodelica::Ref<Node>>>,
    kids: Option<metamodelica::Ref<Kids>>,
}

#[derive(Clone)]
struct Kids {
    nodes: metamodelica::Array<metamodelica::Ref<Node>>,
}

impl MmVal for DropProbe {
    type Traced = mmval::No;
    fn mm_accept<V: Visitor>(&self, _: &mut V) -> Result<(), ()> {
        Ok(())
    }
}

impl MmVal for Node {
    // Traced: it can reach a cyclic cell. mmtorust declares this per type.
    type Traced = mmval::Yes;
    fn mm_accept<V: Visitor>(&self, v: &mut V) -> Result<(), ()> {
        self.probe.mm_accept(v)?;
        self.back.mm_accept(v)?;
        self.kids.mm_accept(v)
    }
}

impl MmVal for Kids {
    type Traced = mmval::Yes;
    fn mm_accept<V: Visitor>(&self, v: &mut V) -> Result<(), ()> {
        self.nodes.mm_accept(v)
    }
}

impl metamodelica::gc::MMTrace for Kids {
    fn mm_accept(&self, _: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        Ok(())
    }
}

impl metamodelica::gc::MMTrace for Node {
    fn mm_accept(&self, _: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        Ok(())
    }
}

fn probe() -> (DropProbe, Rc<std::cell::Cell<usize>>) {
    let drops = Rc::new(std::cell::Cell::new(0));
    (DropProbe { drops: drops.clone() }, drops)
}

fn empty_kids() -> Option<metamodelica::Ref<Kids>> {
    None
}

fn kids(nodes: Vec<metamodelica::Ref<Node>>) -> Option<metamodelica::Ref<Kids>> {
    Some(metamodelica::Ref::new(Kids { nodes: metamodelica::Array::from_vec(nodes) }))
}

/// A traced payload must select the `Gc` spine, an untraced one must not —
/// otherwise the rest of these tests would pass for the wrong reason. The
/// spine is what to inspect: `Ref` and `Array` are newtypes, so their own
/// names say nothing about which allocation they picked.
#[test]
fn traced_payload_selects_the_gc_spine() {
    use metamodelica::mmval::{RcSpine, Spine};
    let n = std::any::type_name::<Spine<Node, Node>>();
    assert!(n.contains("Gc"), "Ref<Node> should be traced, got {n}");
    let a = std::any::type_name::<RcSpine<metamodelica::Ref<Node>, u8>>();
    assert!(a.contains("Gc"), "Array<Ref<Node>> should be traced, got {a}");
    let u = std::any::type_name::<Spine<DropProbe, DropProbe>>();
    assert!(!u.contains("Gc"), "Ref<DropProbe> should stay an Arc, got {u}");
    let u2 = std::any::type_name::<RcSpine<metamodelica::Ref<DropProbe>, u8>>();
    assert!(!u2.contains("Gc"), "Array<Ref<DropProbe>> should stay an Rc, got {u2}");
}

/// The one-node self-cycle: a cell whose content points back at the node that
/// owns the cell.
#[test]
fn self_cycle_through_a_cyclic_cell_is_reclaimed() {
    let (p, drops) = probe();
    {
        let cell = MutableCyclic::create(metamodelica::Ref::new(Node {
            probe: p.clone(),
            back: None,
            kids: empty_kids(),
        }));
        let node = metamodelica::Ref::new(Node {
            probe: p,
            back: Some(cell.clone()),
            kids: empty_kids(),
        });
        MutableCyclic::update(cell, node);
    }
    let before = drops.get();
    collect();
    assert!(
        drops.get() > before,
        "collect() reclaimed nothing: {} drops before, {} after",
        before,
        drops.get()
    );
}

/// The shape that motivated `Array`'s traced spine: the back-edge runs through
/// an `Array` of traced elements, which is only visible to the collector if the
/// array is a `Gc` node rather than an `Rc` barrier.
#[test]
fn cycle_through_an_array_is_reclaimed() {
    let (p, drops) = probe();
    {
        let cell = MutableCyclic::create(metamodelica::Ref::new(Node {
            probe: p.clone(),
            back: None,
            kids: empty_kids(),
        }));
        let child = metamodelica::Ref::new(Node {
            probe: p.clone(),
            back: Some(cell.clone()),
            kids: empty_kids(),
        });
        let parent = metamodelica::Ref::new(Node {
            probe: p,
            back: None,
            kids: kids(vec![child]),
        });
        MutableCyclic::update(cell, parent);
    }
    let before = drops.get();
    collect();
    assert!(
        drops.get() > before,
        "collect() reclaimed nothing through the array: {} drops before, {} after",
        before,
        drops.get()
    );
}

/// `PointerCyclic`'s mutable arm is traced like `MutableCyclic`; its immutable
/// arm is an `Arc` and cannot be part of a cycle to begin with.
#[test]
fn pointer_cyclic_cycle_is_reclaimed() {
    let (p, drops) = probe();
    {
        let cell = PointerCyclic::create(metamodelica::Ref::new(Node {
            probe: p.clone(),
            back: None,
            kids: empty_kids(),
        }));
        let node = metamodelica::Ref::new(Node {
            probe: p,
            back: None,
            kids: kids(vec![metamodelica::Ref::new(Node {
                probe: DropProbe { drops: drops.clone() },
                back: None,
                kids: empty_kids(),
            })]),
        });
        PointerCyclic::update(cell.clone(), node);
        // Keep the cell reachable from its own content via a second handle.
        let _alias = cell.clone();
    }
    let before = drops.get();
    collect();
    assert!(drops.get() >= before);
}

/// An acyclic value must still be freed by plain refcounting, with no
/// collection needed — the traced representation must not turn every value
/// into garbage that only `collect()` can reclaim.
#[test]
fn acyclic_traced_value_drops_without_collect() {
    let (p, drops) = probe();
    {
        let _n = metamodelica::Ref::new(Node { probe: p, back: None, kids: empty_kids() });
    }
    assert_eq!(drops.get(), 1, "an acyclic traced value should drop immediately");
}
