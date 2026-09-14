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

  function scopeRef
    "As `identityCell`, for a reference to a scope that is not this node's
     parent. Publishes only into a cell nobody has published into yet: naming a
     scope has no business replacing the snapshot its children read, and each
     republish also leaves the previous copy as garbage."
    input InstNode node;
    output ScopeRef scope;
  algorithm
    scope := match node
      local Mutable<InstNode> cell;

      case CLASS_NODE(owner = SOME(cell))
        algorithm
          if isEmpty(Mutable.access(cell)) then
            Mutable.update(cell, disown(node));
          end if;
        then node.identity;

      case COMPONENT_NODE(owner = SOME(cell))
        algorithm
          if isEmpty(Mutable.access(cell)) then
            Mutable.update(cell, disown(node));
          end if;
        then node.identity;

      case CLASS_NODE() then node.identity;
      case COMPONENT_NODE() then node.identity;
      else NONE();
    end match;
  end scopeRef;

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
          c := MutableWeak.upgradeOwning(w);
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

  record CLASS_NODE
    String name;
    SCode.Element definition;
    Visibility visibility;
    Pointer<Class> cls;
    array<CachedData> caches;
    Option<Mutable<InstNode>> owner "The cell this node publishes itself into
      for its children to read back. NONE() in the published copy, which must
      not own the cell it lives in.";
    Option<MutableWeak<InstNode>> identity "The same cell, weakly.";
    ScopeRef parentScope "The enclosing scope's identity.
      Weak: a scope owns the nodes in it.";
    InstNodeType nodeType;
  end CLASS_NODE;

  record COMPONENT_NODE
    String name;
    Option<SCode.Element> definition;
    Visibility visibility;
    Pointer<Component> component;
    Option<Mutable<InstNode>> owner "See CLASS_NODE.owner.";
    Option<MutableWeak<InstNode>> identity "See CLASS_NODE.identity.";
    ScopeRef parent "The instance that this component is
      part of; see CLASS_NODE.parentScope.";
    InstNodeType nodeType;
  end COMPONENT_NODE;

  function newIdentity
    "A fresh cell for a node to publish itself into."
    output Option<Mutable<InstNode>> owner;
    output Option<MutableWeak<InstNode>> identity;
  protected
    Mutable<InstNode> cell;
  algorithm
    cell := Mutable.create(EMPTY_NODE());
    // The run owns the cell. A node value is not a long enough owner: a cref
    // outlives the value it was made from and still walks up through it.
    MutableWeak.root(cell);
    owner := SOME(cell);
    identity := SOME(MutableWeak.downgrade(cell));
  end newIdentity;

  function reidentify
    "A fresh identity, for a node that is a copy of another rather than an
     update of it. Its children must be made after this, or they refer to the
     node it was copied from."
    input output InstNode node;
  protected
    Option<Mutable<InstNode>> owner;
    Option<MutableWeak<InstNode>> identity;
  algorithm
    () := match node
      case CLASS_NODE()
        algorithm
          (owner, identity) := newIdentity();
          node.owner := owner;
          node.identity := identity;
        then ();

      case COMPONENT_NODE()
        algorithm
          (owner, identity) := newIdentity();
          node.owner := owner;
          node.identity := identity;
        then ();

      else ();
    end match;
  end reidentify;

  function setOwner
    input output InstNode node;
    input Option<Mutable<InstNode>> owner;
  algorithm
    () := match node
      case CLASS_NODE() algorithm node.owner := owner; then ();
      case COMPONENT_NODE() algorithm node.owner := owner; then ();
      else ();
    end match;
  end setOwner;

  function disown
    "The copy that goes into the cell must not own the cell back."
    input output InstNode node;
  algorithm
    node := setOwner(node, NONE());
  end disown;

  function reown
    "The counterpart of `disown`, for a node read back out of its cell."
    input InstNode node;
    input Mutable<InstNode> cell;
    output InstNode outNode;
  algorithm
    outNode := setOwner(node, SOME(cell));
  end reown;

  function handle
    "A weak handle for an edge that is not a parent edge. Unlike `identityCell`
     it publishes only into a cell nobody has published into yet: a non-parent
     edge has no business replacing the snapshot the node's children see, and
     overwriting it is how a copied node ends up answering for its original.
     A node with no cell is kept by value, which is also the only form a
     constant can take."
    input InstNode node;
    output NodeHandle hnd;
  algorithm
    hnd := match node
      local Mutable<InstNode> cell;

      case CLASS_NODE(owner = SOME(cell))
        algorithm
          if isEmpty(Mutable.access(cell)) then
            Mutable.update(cell, disown(node));
          end if;
        then fromIdentity(node.identity, node);

      case COMPONENT_NODE(owner = SOME(cell))
        algorithm
          if isEmpty(Mutable.access(cell)) then
            Mutable.update(cell, disown(node));
          end if;
        then fromIdentity(node.identity, node);

      case CLASS_NODE() then fromIdentity(node.identity, node);
      case COMPONENT_NODE() then fromIdentity(node.identity, node);
      else NodeHandle.VALUE(node);
    end match;
  end handle;

  function republish
    "A weak handle that *replaces* the published snapshot. For an update of the
     same entity, where `handle`'s publish-once would hand back the node as it
     was before the update. A copy needs `reidentify`, not this."
    input InstNode node;
    output NodeHandle hnd;
  algorithm
    hnd := match node
      local Mutable<InstNode> cell;

      case CLASS_NODE(owner = SOME(cell))
        algorithm
          Mutable.update(cell, disown(node));
        then fromIdentity(node.identity, node);

      case COMPONENT_NODE(owner = SOME(cell))
        algorithm
          Mutable.update(cell, disown(node));
        then fromIdentity(node.identity, node);

      else handle(node);
    end match;
  end republish;

  function fromIdentity
    input Option<MutableWeak<InstNode>> identity;
    input InstNode node;
    output NodeHandle hnd;
  algorithm
    hnd := match identity
      local MutableWeak<InstNode> w;
      case SOME(w) then NodeHandle.CELL(w);
      else NodeHandle.VALUE(node);
    end match;
  end fromIdentity;

  function newClass
    input SCode.Element definition;
    input InstNode parent;
    input InstNodeType nodeType = NORMAL_CLASS();
    output InstNode node;
  protected
    String name;
    SCode.Visibility vis;
    Option<Mutable<InstNode>> owner;
    Option<MutableWeak<InstNode>> identity;
  algorithm
    SCode.CLASS(name = name, prefixes = SCode.PREFIXES(visibility = vis)) := definition;
    (owner, identity) := newIdentity();
    node := CLASS_NODE(name, definition, Prefixes.visibilityFromSCode(vis),
      Pointer.create(Class.NOT_INSTANTIATED()), CachedData.empty(),
      owner, identity, identityCell(parent), nodeType);
  end newClass;

  function newComponent
    input SCode.Element definition;
    input InstNode parent = EMPTY_NODE();
    output InstNode node;
  protected
    String name;
    SCode.Visibility vis;
    Option<Mutable<InstNode>> owner;
    Option<MutableWeak<InstNode>> identity;
  algorithm
    SCode.COMPONENT(name = name, prefixes = SCode.PREFIXES(visibility = vis)) := definition;
    (owner, identity) := newIdentity();
    node := COMPONENT_NODE(name, SOME(definition), Prefixes.visibilityFromSCode(vis),
      Pointer.create(Component.new(definition)), owner, identity,
      identityCell(parent), InstNodeType.NORMAL_COMP());
  end newComponent;

  function newExtends
    input SCode.Element definition;
    input InstNode parent;
    output InstNode node;
  protected
    Absyn.Path base_path;
    String name;
    SCode.Visibility vis;
    Option<Mutable<InstNode>> owner;
    Option<MutableWeak<InstNode>> identity;
  algorithm
    SCode.Element.EXTENDS(baseClassPath = base_path, visibility = vis) := definition;
    name := AbsynUtil.pathLastIdent(base_path);
    (owner, identity) := newIdentity();
    node := CLASS_NODE(name, definition, Prefixes.visibilityFromSCode(vis),
      Pointer.create(Class.NOT_INSTANTIATED()), CachedData.empty(),
      owner, identity, identityCell(parent),
      InstNodeType.BASE_CLASS(identityCell(parent), definition, nodeType(parent)));
  end newExtends;

  function fromComponent
    input String name;
    input Component component;
    input InstNode parent;
    output InstNode node;
  protected
    Option<Mutable<InstNode>> owner;
    Option<MutableWeak<InstNode>> identity;
  algorithm
    (owner, identity) := newIdentity();
    node := COMPONENT_NODE(name, NONE(), Visibility.PUBLIC, Pointer.create(component),
                           owner, identity, identityCell(parent), InstNodeType.NORMAL_COMP());
  end fromComponent;

  function cloneComponent
    input InstNode component;
    input InstNode newParent;
    output InstNode outComponent;
  algorithm
    outComponent := match component
      local
        Option<Mutable<InstNode>> owner;
        Option<MutableWeak<InstNode>> identity;

      case COMPONENT_NODE()
        algorithm
          (owner, identity) := newIdentity();
        then
          COMPONENT_NODE(component.name, component.definition, component.visibility,
            Pointer.create(Pointer.access(component.component)),
            owner, identity, identityCell(newParent), component.nodeType);
    end match;
  end cloneComponent;
end InstNode;

end NFInstNode;
