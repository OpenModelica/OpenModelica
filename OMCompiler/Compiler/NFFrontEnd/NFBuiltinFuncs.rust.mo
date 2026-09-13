// Rust-only declarations for NFBuiltinFuncs; see mmtorust/src/overrides.rs.
// `NFComponentRef.CREF.node` is a weak handle in the Rust port, and a constant
// cannot call `InstNode.handle`, so these three are written out.
encapsulated package NFBuiltinFuncs
  constant ComponentRef INTEGER_CREF =
    ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(INTEGER_NODE), {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

  constant ComponentRef STRING_CREF =
    ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(STRING_NODE), {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

  constant ComponentRef CLOCK_CREF =
    ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(CLOCK_NODE), {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());
end NFBuiltinFuncs;
