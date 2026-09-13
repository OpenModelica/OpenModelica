// Rust-only declaration for NFTyping; see mmtorust/src/overrides.rs.
encapsulated package NFTyping
  constant Expression WHOLEDIM_CREF = Expression.CREF(Type.UNKNOWN(),
    ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(InstNode.NAME_NODE(":")), {}, Type.UNKNOWN(), NFComponentRef.Origin.CREF, ComponentRef.EMPTY()));
end NFTyping;
