// Rust-only declarations for NFInstNode; see mmtorust/src/overrides.rs.
//
// A scope owns the nodes in it, so the Rust port stores a reference back to a
// scope as a weak handle to the cell the node publishes itself into. The C
// compiler needs none of that -- a weak reference there is the strong one --
// and the `Option` cost it a box per node, per equation and per complex type,
// so NFInstNode.mo stores the node itself and only these items differ.
encapsulated package NFInstNode

type ScopeRef = Option<MutableWeak<InstNode>>;

constant ScopeRef NO_SCOPE = NONE();

uniontype InstNode
  function identityCell
    "Publishes the node into its cell and returns a weak reference for a child
     to store as its parent. Publishing here rather than on every update gives
     a child the same snapshot of its parent a strong field would have."
    input InstNode node;
    output ScopeRef identity;
  algorithm
    identity := match node
      local Mutable<InstNode> cell;

      case CLASS_NODE(owner = SOME(cell))
        algorithm
          Mutable.update(cell, disown(node));
        then node.identity;

      case COMPONENT_NODE(owner = SOME(cell))
        algorithm
          Mutable.update(cell, disown(node));
        then node.identity;

      // Already a published copy: it cannot publish, but it can be a parent.
      case CLASS_NODE() then node.identity;
      case COMPONENT_NODE() then node.identity;
      else NONE();
    end match;
  end identityCell;

  function borrow
    "The node a cell holds, without taking ownership of it. For an edge that is
     not a parent edge and whose target is owned elsewhere: `fromCell` copies
     the record to re-own it, which is more than a type should pay to name a
     class."
    input ScopeRef cell;
    output InstNode node;
  algorithm
    node := matchcontinue cell
      local MutableWeak<InstNode> w;
      case SOME(w) then Mutable.access(MutableWeak.upgrade(w));
      else EMPTY_NODE();
    end matchcontinue;
  end borrow;

  function fromCell
    "The node a parent cell holds, or an empty node if the parent is gone. The
     result owns the cell, so a node reached through its parent is as usable as
     the original — including as a parent itself."
    input ScopeRef cell;
    output InstNode node;
  algorithm
    node := matchcontinue cell
      local
        MutableWeak<InstNode> w;
        Mutable<InstNode> c;

      case SOME(w)
        algorithm
          c := MutableWeak.upgrade(w);
        then reown(Mutable.access(c), c);

      else EMPTY_NODE();
    end matchcontinue;
  end fromCell;

  function fromHandle
    input NodeHandle hnd;
    output InstNode node;
  algorithm
    node := match hnd
      case NodeHandle.CELL() then borrow(SOME(hnd.cell));
      case NodeHandle.VALUE() then hnd.node;
    end match;
  end fromHandle;
end InstNode;

end NFInstNode;
