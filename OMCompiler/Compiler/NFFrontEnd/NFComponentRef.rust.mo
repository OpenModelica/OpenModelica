// Rust-only declarations for NFComponentRef; see mmtorust/src/overrides.rs.
//
// A cref names nodes the class tree owns, and their class holds the equation
// the cref sits in, so the Rust port has to hold them weakly or the graph is
// cyclic. The C compiler needs none of that -- a weak reference there is the
// strong one -- and paying for a handle per cref cost it ~16 bytes each, so
// NFComponentRef.mo stores the node itself and only these items differ.
encapsulated uniontype NFComponentRef
  record CREF
    NFInstNode.NodeHandle node "Weakly: the class tree owns the node.";
    list<NFSubscript> subscripts;
    NFType ty;
    Origin origin;
    NFComponentRef restCref;
  end CREF;

  function node
    input ComponentRef cref;
    output InstNode node;
  protected
    NFInstNode.NodeHandle hnd;
  algorithm
    CREF(node = hnd) := cref;
    node := InstNode.fromHandle(hnd);
  end node;

  function fromNode
    input InstNode node;
    input Type ty;
    input list<Subscript> subs = {};
    input Origin origin = Origin.CREF;
    output ComponentRef cref = CREF(InstNode.handle(node), subs, ty, origin, EMPTY());
  end fromNode;

  function fromOwnedNode
    "For a synthetic node the cref itself owns. A backend `$fDER` node is in no
     class tree, so a weak handle would have no other owner and the cref would
     read back whatever was published for the node it was copied from."
    input InstNode node;
    input Type ty;
    output ComponentRef cref = CREF(NFInstNode.NodeHandle.VALUE(node), {}, ty, Origin.CREF, EMPTY());
  end fromOwnedNode;

  function prefixCref
    input InstNode node;
    input Type ty;
    input list<Subscript> subs;
    input ComponentRef restCref;
    output ComponentRef cref = CREF(InstNode.handle(node), subs, ty, Origin.CREF, restCref);
  end prefixCref;

  function prefixScope
    input InstNode node;
    input Type ty;
    input list<Subscript> subs;
    input ComponentRef restCref;
    output ComponentRef cref = CREF(InstNode.handle(node), subs, ty, Origin.SCOPE, restCref);
  end prefixScope;

  function fromBuiltin
    input InstNode node;
    input Type ty;
    output ComponentRef cref = CREF(InstNode.handle(node), {}, ty, Origin.SCOPE, EMPTY());
  end fromBuiltin;

  function makeIterator
    input InstNode node;
    input Type ty = InstNode.getType(node);
    output ComponentRef cref = CREF(InstNode.handle(node), {}, ty, Origin.ITERATOR, EMPTY());
  end makeIterator;

  function fromAbsyn
    input InstNode node;
    input list<Absyn.Subscript> subs;
    input ComponentRef restCref = EMPTY();
    input Boolean isIterator = false;
    output ComponentRef cref;
  protected
    list<Subscript> sl;
  algorithm
    sl := list(Subscript.RAW_SUBSCRIPT(s) for s in subs);
    cref := CREF(InstNode.handle(node), sl, Type.UNKNOWN(), if isIterator then Origin.ITERATOR else Origin.CREF, restCref);
  end fromAbsyn;

  function fromNodeList
    input list<InstNode> nodes;
    output ComponentRef cref = ComponentRef.EMPTY();
  algorithm
    for n in nodes loop
      cref := CREF(InstNode.handle(n), {}, InstNode.getType(n), Origin.SCOPE, cref);
    end for;
  end fromNodeList;

  function rename
    input String name;
    input output ComponentRef cref;
  algorithm
    cref := match cref
      case CREF()
        algorithm
          // A rename makes a copy, not an update: it needs its own identity,
          // or it publishes nothing and reads back under the old name.
          cref.node := InstNode.handle(InstNode.reidentify(InstNode.rename(name, node(cref))));
        then
          cref;

      else cref;
    end match;
  end rename;

  function mapNodes
    input ComponentRef cref;
    input MapFunc func;
    output ComponentRef outCref;

    partial function MapFunc
      input output InstNode n;
    end MapFunc;
  algorithm
    outCref := match cref
      local
        ComponentRef rest;
        InstNode node;

      case CREF()
        algorithm
          node := func(node(cref));
          rest := mapNodes(cref.restCref, func);
        then
          CREF(InstNode.handle(node), cref.subscripts, cref.ty, cref.origin, rest);

      else cref;
    end match;
  end mapNodes;

  function storeNode
    "`handle` publishes only into a cell nobody has published into yet, so an
     update of the same node has to replace the snapshot instead."
    input InstNode node;
    input Boolean update = false;
    output NFInstNode.NodeHandle stored =
      if update then InstNode.republish(node) else InstNode.handle(node);
  end storeNode;
end NFComponentRef;
