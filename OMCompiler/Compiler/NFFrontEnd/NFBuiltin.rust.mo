// Rust-only declarations for NFBuiltin; see mmtorust/src/overrides.rs.
//
// A constant has to spell out every field, and it may only call an
// `external "C"` function, so anything the Rust port represents differently
// has to be restated here rather than shared: the weak handle in a cref (see
// NFComponentRef.rust.mo) and the two identity cells on a node (see
// NFInstNode.rust.mo).
encapsulated package NFBuiltin
  constant ComponentRef BOOLEAN_CREF =
    ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(BOOLEAN_NODE), {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

  constant ComponentRef CLOCK_CREF =
    ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(CLOCK_NODE), {}, Type.CLOCK(), Origin.CREF, ComponentRef.EMPTY());

  constant ComponentRef TIME_CREF = ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(TIME), {}, Type.REAL(), Origin.CREF, ComponentRef.EMPTY());
  constant ComponentRef SUBST_CREF = ComponentRef.CREF(NFInstNode.NodeHandle.VALUE(SUBST_NODE), {}, Type.ANY(), Origin.CREF, ComponentRef.EMPTY());

constant InstNode POLYMORPHIC_NODE = InstNode.CLASS_NODE("polymorphic",
  Elements.ANY, Visibility.PUBLIC,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.POLYMORPHIC(""), ClassTree.EMPTY_TREE(),
    Modifier.NOMOD(), NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  EMPTY_NODE_CACHE, NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.BUILTIN_CLASS());

constant ClassTree REAL_CLASS_TREE = ClassTree.FLAT_TREE(
  REAL_LOOKUP_TREE,
  listArray({}),
  listArrayLiteral({
    InstNode.COMPONENT_NODE("quantity", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("unit", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("displayUnit", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("min", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.REAL(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("max", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.REAL(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("start", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.REAL(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("fixed", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("nominal", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.REAL(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("unbounded", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("stateSelect", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(STATESELECT_TYPE,
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("uncertain", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(UNCERTAINTY_TYPE,
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP())
  }),
  listArray({}), // TODO: #4895: This should be listArrayLiteral too, but causes compilation issues.
  NFDuplicateTree.EMPTY());

constant InstNode REAL_NODE = InstNode.CLASS_NODE("Real",
  Elements.REAL, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.REAL(), REAL_CLASS_TREE, Modifier.NOMOD(),
      NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  EMPTY_NODE_CACHE, NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.BUILTIN_CLASS());

constant ClassTree INTEGER_CLASS_TREE = ClassTree.FLAT_TREE(
  INTEGER_LOOKUP_TREE,
  listArray({}),
  listArrayLiteral({
    InstNode.COMPONENT_NODE("quantity", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("min", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.INTEGER(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("max", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.INTEGER(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("start", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.INTEGER(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("fixed", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP())
  }),
  listArray({}), // TODO: #4895: This should be listArrayLiteral too, but causes compilation issues.
  NFDuplicateTree.EMPTY());

constant InstNode INTEGER_NODE = InstNode.CLASS_NODE("Integer",
  Elements.INTEGER, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.INTEGER(), INTEGER_CLASS_TREE, Modifier.NOMOD(),
      NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  EMPTY_NODE_CACHE, NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.BUILTIN_CLASS());

constant ClassTree BOOLEAN_CLASS_TREE = ClassTree.FLAT_TREE(
  BOOLEAN_LOOKUP_TREE,
  listArray({}),
  listArrayLiteral({
    InstNode.COMPONENT_NODE("quantity", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("start", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("fixed", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP())
  }),
  listArray({}), // TODO: #4895: This should be listArrayLiteral too, but causes compilation issues.
  NFDuplicateTree.EMPTY());

constant InstNode BOOLEAN_NODE = InstNode.CLASS_NODE("Boolean",
  Elements.BOOLEAN, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.BOOLEAN(), BOOLEAN_CLASS_TREE, Modifier.NOMOD(),
      NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  EMPTY_NODE_CACHE, NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.BUILTIN_CLASS());

constant ClassTree STRING_CLASS_TREE = ClassTree.FLAT_TREE(
  STRING_LOOKUP_TREE,
  listArray({}),
  listArrayLiteral({
    InstNode.COMPONENT_NODE("quantity", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("start", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("fixed", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP())
  }),
  listArray({}), // TODO: #4895: This should be listArrayLiteral too, but causes compilation issues.
  NFDuplicateTree.EMPTY());

constant InstNode STRING_NODE = InstNode.CLASS_NODE("String",
  Elements.STRING, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.STRING(), STRING_CLASS_TREE, Modifier.NOMOD(),
      NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  EMPTY_NODE_CACHE, NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.BUILTIN_CLASS());

constant InstNode ENUM_NODE = InstNode.CLASS_NODE("enumeration",
  Elements.ENUMERATION, Visibility.PUBLIC,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.ENUMERATION(Absyn.Path.IDENT(":"), {}), NFClassTree.EMPTY_TREE(),
    Modifier.NOMOD(), NFClass.DEFAULT_PREFIXES, Restriction.ENUMERATION())),
  EMPTY_NODE_CACHE, NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.BUILTIN_CLASS());

constant ClassTree CLOCK_CLASS_TREE = ClassTree.FLAT_TREE(
  CLOCK_LOOKUP_TREE,
  listArray({}),
  listArrayLiteral({
    InstNode.COMPONENT_NODE("quantity", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("start", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.CLOCK(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("fixed", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.CLOCK(),
      Modifier.NOMOD())), NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.NORMAL_COMP())
  }),
  listArray({}), // TODO: #4895: This should be listArrayLiteral too, but causes compilation issues.
  NFDuplicateTree.EMPTY());

constant InstNode CLOCK_NODE = InstNode.CLASS_NODE("Clock",
  Elements.CLOCK, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.CLOCK(), CLOCK_CLASS_TREE, Modifier.NOMOD(),
      NFClass.DEFAULT_PREFIXES, Restriction.CLOCK())),
  listArrayLiteral({
    NFInstNode.CachedData.FUNCTION({
        NFBuiltinFuncs.CLOCK_INFERRED,
        NFBuiltinFuncs.CLOCK_INT,
        NFBuiltinFuncs.CLOCK_REAL,
        NFBuiltinFuncs.CLOCK_BOOL,
        NFBuiltinFuncs.CLOCK_SOLVER
        },
      true, true),
    NFInstNode.CachedData.NO_CACHE(),
    NFInstNode.CachedData.NO_CACHE()}
  ),
  NONE(), NONE(), NFInstNode.NO_SCOPE, InstNodeType.BUILTIN_CLASS());

constant InstNode TIME =
  InstNode.COMPONENT_NODE("time",
    NONE(),
    Visibility.PUBLIC,
    Pointer.createImmutable(Component.COMPONENT(
      REAL_NODE,
      Type.REAL(),
      NFBinding.EMPTY_BINDING,
      NFBinding.EMPTY_BINDING,
      NFAttributes.INPUT_ATTR,
      SCode.noComment,
      ComponentState.TypeChecked,
      Absyn.dummyInfo)),
    NONE(), NONE(), NFInstNode.NO_SCOPE,
    InstNodeType.NORMAL_COMP());

constant InstNode SUBST_NODE =
  InstNode.COMPONENT_NODE("$SUBST_CREF",
    NONE(),
    Visibility.PUBLIC,
    Pointer.createImmutable(Component.COMPONENT(
      REAL_NODE, // TODO: make this generic integer / real
      Type.ANY(),
      NFBinding.EMPTY_BINDING,
      NFBinding.EMPTY_BINDING,
      NFAttributes.DEFAULT_ATTR,
      SCode.noComment,
      ComponentState.TypeChecked,
      Absyn.dummyInfo)),
    NONE(), NONE(), NFInstNode.NO_SCOPE,
    InstNodeType.NORMAL_COMP());

end NFBuiltin;
