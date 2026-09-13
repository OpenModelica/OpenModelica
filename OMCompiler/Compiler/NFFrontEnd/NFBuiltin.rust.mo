// Rust-only declarations for NFBuiltin; see mmtorust/src/overrides.rs.
// These constants build crefs, and `NFComponentRef.CREF.node` is a weak handle
// in the Rust port. A constant cannot call a function, so the handle has to be
// written out here rather than going through `InstNode.handle`.
encapsulated package NFBuiltin
  constant ComponentRef BOOLEAN_CREF =
    ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(BOOLEAN_NODE), {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

  constant ComponentRef CLOCK_CREF =
    ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(CLOCK_NODE), {}, Type.CLOCK(), Origin.CREF, ComponentRef.EMPTY());

  constant ComponentRef TIME_CREF = ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(TIME), {}, Type.REAL(), Origin.CREF, ComponentRef.EMPTY());
  constant ComponentRef SUBST_CREF = ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(SUBST_NODE), {}, Type.ANY(), Origin.CREF, ComponentRef.EMPTY());
end NFBuiltin;
