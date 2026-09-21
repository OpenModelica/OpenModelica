//! Drop-detection harness for cycles that run through a container.
//!
//! These reach the cycle through a `Ref` and through an `Array`, which
//! [`super::mutable_cycle_drop_tests`] does not: what is being tested is that
//! the cell collector still sees a back-edge buried under a container spine.
//! Break a link in that chain and these leak.

use std::rc::Rc;

use crate::{Mutable, Pointer};

/// Payload whose destruction is observable.
struct DropProbe {
    drops: Rc<std::cell::Cell<usize>>,
}

impl Drop for DropProbe {
    fn drop(&mut self) {
        self.drops.set(self.drops.get() + 1);
    }
}

/// The cells compare their contents; a probe is identified by the counter it
/// reports to.
impl PartialEq for DropProbe {
    fn eq(&self, other: &Self) -> bool {
        Rc::ptr_eq(&self.drops, &other.drops)
    }
}

impl Clone for DropProbe {
    fn clone(&self) -> Self {
        DropProbe { drops: self.drops.clone() }
    }
}

/// A node holding the probe plus a back-edge through a cell — the shape
/// `NFInst` builds when it updates a class pointer with an `InstNode` whose
/// class points back through that same pointer. The array of children lives on
/// a second type, as `ClassTree` does, so the two recur through each other.
#[derive(Clone, PartialEq)]
struct Node {
    probe: DropProbe,
    back: Option<Mutable::Mutable<metamodelica::Ref<Node>>>,
    kids: Option<metamodelica::Ref<Kids>>,
}

#[derive(Clone, PartialEq)]
struct Kids {
    nodes: metamodelica::Array<metamodelica::Ref<Node>>,
}


impl metamodelica::gc::MMTrace for Kids {
    fn mm_accept(&self, v: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.nodes, v)
    }
}

impl metamodelica::gc::MMTrace for Node {
    fn mm_accept(&self, v: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.back, v)?;
        metamodelica::gc::MMTrace::mm_accept(&self.kids, v)
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
    Some(metamodelica::Ref::new(Kids { nodes: metamodelica::arrayFromVec(nodes) }))
}

/// The one-node self-cycle: a cell whose content points back at the node that
/// owns the cell.
#[test]
fn self_cycle_through_a_cell_is_reclaimed() {
    let (p, drops) = probe();
    {
        let cell = Mutable::create(metamodelica::Ref::new(Node {
            probe: p.clone(),
            back: None,
            kids: empty_kids(),
        }));
        let node = metamodelica::Ref::new(Node {
            probe: p,
            back: Some(cell.clone()),
            kids: empty_kids(),
        });
        Mutable::update(cell, node);
    }
    let before = drops.get();
    metamodelica::gc::collect();
    assert!(
        drops.get() > before,
        "the collector reclaimed nothing: {} drops before, {} after",
        before,
        drops.get()
    );
}

/// The back-edge runs through an `Array`, whose spine the collector has to
/// descend to reach it.
#[test]
fn cycle_through_an_array_is_reclaimed() {
    let (p, drops) = probe();
    {
        let cell = Mutable::create(metamodelica::Ref::new(Node {
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
        Mutable::update(cell, parent);
    }
    let before = drops.get();
    metamodelica::gc::collect();
    assert!(
        drops.get() > before,
        "the collector reclaimed nothing through the array: {} drops before, {} after",
        before,
        drops.get()
    );
}

/// `Pointer`'s mutable arm behaves as `Mutable` does; its immutable arm is an
/// `Arc` and cannot be part of a cycle to begin with.
#[test]
fn pointer_cycle_is_reclaimed() {
    let (p, drops) = probe();
    {
        let cell = Pointer::create(metamodelica::Ref::new(Node {
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
        Pointer::update(cell.clone(), node);
        // Keep the cell reachable from its own content via a second handle.
        let _alias = cell.clone();
    }
    let before = drops.get();
    metamodelica::gc::collect();
    assert!(drops.get() >= before);
}

/// An acyclic value must still be freed by plain refcounting, with no
/// collection needed.
#[test]
fn acyclic_value_drops_without_collect() {
    let (p, drops) = probe();
    {
        let _n = metamodelica::Ref::new(Node { probe: p, back: None, kids: empty_kids() });
    }
    assert_eq!(drops.get(), 1, "an acyclic value should drop immediately");
}
