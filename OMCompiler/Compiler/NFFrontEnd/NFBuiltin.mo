/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


encapsulated package NFBuiltin
" file:        NFBuiltin.mo
  package:     NFBuiltin
  description: Builtin definitions.


  Definitions for various builtin Modelica types and variables that can't be
  defined by ModelicaBuiltin.mo.
  "

public
import Absyn;
import AbsynUtil;
import Attributes = NFAttributes;
import SCode;
import NFBinding;
import Class = NFClass;
import NFClassTree.ClassTree;
import Component = NFComponent;
import NFComponent.ComponentState;
import Expression = NFExpression;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import NFModifier.Modifier;
import Type = NFType;
import BuiltinFuncs = NFBuiltinFuncs;
import Pointer;
import NFPrefixes.Variability;
import NFPrefixes.Visibility;
import ComponentRef = NFComponentRef;
import NFComponentRef.Origin;
import Restriction = NFRestriction;
import LookupTree = NFLookupTree;
import NFDuplicateTree;

protected
import MetaModelica.Dangerous.*;

public
encapsulated package Elements
  import SCode;
  import Absyn;
  import AbsynUtil;

  // Default parts of the declarations for builtin elements and types:
  public constant Absyn.TypeSpec ENUMTYPE_SPEC =
    Absyn.TPATH(Absyn.IDENT("$EnumType"), NONE());

  // StateSelect-specific elements:
  constant SCode.Element REAL = SCode.CLASS("Real",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, AbsynUtil.dummyInfo);

  constant SCode.Element INTEGER = SCode.CLASS("Integer",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, AbsynUtil.dummyInfo);

  constant SCode.Element BOOLEAN = SCode.CLASS("Boolean",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, AbsynUtil.dummyInfo);

  constant SCode.Element STRING = SCode.CLASS("String",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, AbsynUtil.dummyInfo);

  constant SCode.Element ENUMERATION = SCode.CLASS("enumeration",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, AbsynUtil.dummyInfo);

  constant SCode.Element ANY = SCode.CLASS("polymorphic",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, AbsynUtil.dummyInfo);

  constant SCode.Element CLOCK = SCode.CLASS("Clock",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_PREDEFINED_CLOCK(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, AbsynUtil.dummyInfo) "the Clock type";

end Elements;

// An empty InstNode cache for the builtin types. This should really be an empty
// array to make sure all attempts at using the cache fails, since trying to
// update the cache of a constant literal would cause a segfault. Creating a
// completely empty array here doesn't work due to compiler bugs though
// (generates invalid C code), but this is probably close enough.
constant array<NFInstNode.CachedData> EMPTY_NODE_CACHE = listArrayLiteral({
  NFInstNode.CachedData.FUNCTION({}, true, true)
});

// InstNodes for the builtin types. These have empty class trees to prevent
// access to the attributes via dot notation (which is not needed for
// modifiers and illegal in other cases).
constant InstNode POLYMORPHIC_NODE = InstNode.CLASS_NODE("polymorphic",
  Elements.ANY, Visibility.PUBLIC,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.POLYMORPHIC(""), ClassTree.EMPTY_TREE(),
    Modifier.NOMOD(), NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

// Lookup tree for Real. Generated by makeBuiltinLookupTree.
constant LookupTree.Tree REAL_LOOKUP_TREE = LookupTree.Tree.NODE(
  key = "quantity", value = LookupTree.Entry.COMPONENT(index = 1), height = 4,
  left = LookupTree.Tree.NODE(
    key = "max", value = LookupTree.Entry.COMPONENT(index = 5), height = 3,
    left = LookupTree.Tree.NODE(
      key = "displayUnit", value = LookupTree.Entry.COMPONENT(index = 3), height = 2,
      left = LookupTree.Tree.EMPTY(),
      right = LookupTree.Tree.LEAF(
        key = "fixed", value = LookupTree.Entry.COMPONENT(index = 7))),
    right = LookupTree.Tree.NODE(
      key = "min", value = LookupTree.Entry.COMPONENT(index = 4), height = 2,
      left = LookupTree.Tree.EMPTY(),
      right = LookupTree.Tree.LEAF(
        key = "nominal", value = LookupTree.Entry.COMPONENT(index = 8)))),
  right = LookupTree.Tree.NODE(
    key = "unbounded", value = LookupTree.Entry.COMPONENT(index = 9), height = 3,
    left = LookupTree.Tree.NODE(
      key = "start", value = LookupTree.Entry.COMPONENT(index = 6), height = 2,
      left = LookupTree.Tree.EMPTY(),
      right = LookupTree.Tree.LEAF(
        key = "stateSelect", value = LookupTree.Entry.COMPONENT(index = 10))),
    right = LookupTree.Tree.NODE(
      key = "unit", value = LookupTree.Entry.COMPONENT(index = 2), height = 2,
      left = LookupTree.Tree.LEAF(
        key = "uncertain", value = LookupTree.Entry.COMPONENT(index = 11)),
      right = LookupTree.Tree.EMPTY())));

constant ClassTree REAL_CLASS_TREE = ClassTree.FLAT_TREE(
  REAL_LOOKUP_TREE,
  listArray({}),
  listArrayLiteral({
    InstNode.COMPONENT_NODE("quantity", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("unit", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("displayUnit", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("min", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.REAL(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("max", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.REAL(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("start", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.REAL(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("fixed", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("nominal", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.REAL(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("unbounded", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("stateSelect", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(STATESELECT_TYPE,
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("uncertain", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(UNCERTAINTY_TYPE,
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP())
  }),
  listArray({}), // TODO: #4895: This should be listArrayLiteral too, but causes compilation issues.
  NFDuplicateTree.EMPTY());

constant InstNode REAL_NODE = InstNode.CLASS_NODE("Real",
  Elements.REAL, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.REAL(), REAL_CLASS_TREE, Modifier.NOMOD(),
      NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

// Lookup tree for Integer. Generated by makeBuiltinLookupTree.
constant LookupTree.Tree INTEGER_LOOKUP_TREE = LookupTree.Tree.NODE(
  key = "min", value = LookupTree.Entry.COMPONENT(index = 2), height = 3,
  left = LookupTree.Tree.NODE(
    key = "max", value = LookupTree.Entry.COMPONENT(index = 3), height = 2,
    left = LookupTree.Tree.LEAF(
      key = "fixed", value = LookupTree.Entry.COMPONENT(index = 5)),
    right = LookupTree.Tree.EMPTY()),
  right = LookupTree.Tree.NODE(
    key = "quantity", value = LookupTree.Entry.COMPONENT(index = 1), height = 2,
    left = LookupTree.Tree.EMPTY(),
    right = LookupTree.Tree.LEAF(
      key = "start", value = LookupTree.Entry.COMPONENT(index = 4))));

constant ClassTree INTEGER_CLASS_TREE = ClassTree.FLAT_TREE(
  INTEGER_LOOKUP_TREE,
  listArray({}),
  listArrayLiteral({
    InstNode.COMPONENT_NODE("quantity", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("min", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.INTEGER(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("max", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.INTEGER(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("start", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.INTEGER(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("fixed", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP())
  }),
  listArray({}), // TODO: #4895: This should be listArrayLiteral too, but causes compilation issues.
  NFDuplicateTree.EMPTY());

constant InstNode INTEGER_NODE = InstNode.CLASS_NODE("Integer",
  Elements.INTEGER, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.INTEGER(), INTEGER_CLASS_TREE, Modifier.NOMOD(),
      NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

// Lookup tree for Boolean. Generated by makeBuiltinLookupTree.
constant LookupTree.Tree BOOLEAN_LOOKUP_TREE = LookupTree.Tree.NODE(
  key = "quantity", value = LookupTree.Entry.COMPONENT(index = 1), height = 2,
  left = LookupTree.Tree.LEAF(
    key = "fixed", value = LookupTree.Entry.COMPONENT(index = 3)),
  right = LookupTree.Tree.LEAF(
    key = "start", value = LookupTree.Entry.COMPONENT(index = 2)));

constant ClassTree BOOLEAN_CLASS_TREE = ClassTree.FLAT_TREE(
  BOOLEAN_LOOKUP_TREE,
  listArray({}),
  listArrayLiteral({
    InstNode.COMPONENT_NODE("quantity", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("start", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("fixed", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP())
  }),
  listArray({}), // TODO: #4895: This should be listArrayLiteral too, but causes compilation issues.
  NFDuplicateTree.EMPTY());

constant InstNode BOOLEAN_NODE = InstNode.CLASS_NODE("Boolean",
  Elements.BOOLEAN, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.BOOLEAN(), BOOLEAN_CLASS_TREE, Modifier.NOMOD(),
      NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant ComponentRef BOOLEAN_CREF =
  ComponentRef.CREF(BOOLEAN_NODE, {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

// Lookup tree for String. Generated by makeBuiltinLookupTree.
constant LookupTree.Tree STRING_LOOKUP_TREE = LookupTree.Tree.NODE(
  key = "quantity", value = LookupTree.Entry.COMPONENT(index = 1), height = 2,
  left = LookupTree.Tree.LEAF(
    key = "fixed", value = LookupTree.Entry.COMPONENT(index = 3)),
  right = LookupTree.Tree.LEAF(
    key = "start", value = LookupTree.Entry.COMPONENT(index = 2)));

constant ClassTree STRING_CLASS_TREE = ClassTree.FLAT_TREE(
  STRING_LOOKUP_TREE,
  listArray({}),
  listArrayLiteral({
    InstNode.COMPONENT_NODE("quantity", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("start", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("fixed", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.BOOLEAN(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP())
  }),
  listArray({}), // TODO: #4895: This should be listArrayLiteral too, but causes compilation issues.
  NFDuplicateTree.EMPTY());

constant InstNode STRING_NODE = InstNode.CLASS_NODE("String",
  Elements.STRING, Visibility.PUBLIC,
  Pointer.createImmutable(
    Class.PARTIAL_BUILTIN(Type.STRING(), STRING_CLASS_TREE, Modifier.NOMOD(),
      NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

// Lookup tree for enumerations. Generated by makeBuiltinLookupTree.
// NOTE: The enumeration attributes themselves are created by ClassTree.fromEnumeration,
//       so any changes to this lookup tree requires fromEnumeration to be updated too.
constant LookupTree.Tree ENUM_LOOKUP_TREE = LookupTree.Tree.NODE(
  key = "min", value = LookupTree.Entry.COMPONENT(index = 2), height = 3,
  left = LookupTree.Tree.NODE(
    key = "max", value = LookupTree.Entry.COMPONENT(index = 3), height = 2,
    left = LookupTree.Tree.LEAF(
      key = "fixed", value = LookupTree.Entry.COMPONENT(index = 5)),
    right = LookupTree.Tree.EMPTY()),
  right = LookupTree.Tree.NODE(
    key = "quantity", value = LookupTree.Entry.COMPONENT(index = 1), height = 2,
    left = LookupTree.Tree.EMPTY(),
    right = LookupTree.Tree.LEAF(
      key = "start", value = LookupTree.Entry.COMPONENT(index = 4))));

constant InstNode ENUM_NODE = InstNode.CLASS_NODE("enumeration",
  Elements.ENUMERATION, Visibility.PUBLIC,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.ENUMERATION(Absyn.Path.IDENT(":"), {}), NFClassTree.EMPTY_TREE(),
    Modifier.NOMOD(), NFClass.DEFAULT_PREFIXES, Restriction.ENUMERATION())),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant Type STATESELECT_TYPE = Type.ENUMERATION(
  Absyn.IDENT("StateSelect"), {"never", "avoid", "default", "prefer", "always"});

constant Type ASSERTIONLEVEL_TYPE = Type.ENUMERATION(
  Absyn.IDENT("AssertionLevel"), {"warning", "error"});

constant Expression ASSERTIONLEVEL_WARNING = Expression.ENUM_LITERAL(
  ASSERTIONLEVEL_TYPE, "error", 1);

constant Expression ASSERTIONLEVEL_ERROR = Expression.ENUM_LITERAL(
  ASSERTIONLEVEL_TYPE, "error", 2);

constant Type UNCERTAINTY_TYPE = Type.ENUMERATION(
  Absyn.IDENT("Uncertainty"), {"given", "sought", "refine", "propagate"});

// Lookup tree for Clock. Generated by makeBuiltinLookupTree.
constant LookupTree.Tree CLOCK_LOOKUP_TREE = LookupTree.Tree.NODE(
  key = "quantity", value = LookupTree.Entry.COMPONENT(index = 1), height = 2,
  left = LookupTree.Tree.LEAF(
    key = "fixed", value = LookupTree.Entry.COMPONENT(index = 3)),
  right = LookupTree.Tree.LEAF(
    key = "start", value = LookupTree.Entry.COMPONENT(index = 2)));

constant ClassTree CLOCK_CLASS_TREE = ClassTree.FLAT_TREE(
  CLOCK_LOOKUP_TREE,
  listArray({}),
  listArrayLiteral({
    InstNode.COMPONENT_NODE("quantity", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.STRING(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("start", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.CLOCK(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP()),
    InstNode.COMPONENT_NODE("fixed", NONE(), Visibility.PUBLIC,
      Pointer.createImmutable(Component.TYPE_ATTRIBUTE(Type.CLOCK(),
      Modifier.NOMOD())), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP())
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
  InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant ComponentRef CLOCK_CREF =
  ComponentRef.CREF(CLOCK_NODE, {}, Type.CLOCK(), Origin.CREF, ComponentRef.EMPTY());

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
      NONE(),
      ComponentState.TypeChecked,
      AbsynUtil.dummyInfo)),
    InstNode.EMPTY_NODE(),
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
      NONE(),
      ComponentState.TypeChecked,
      AbsynUtil.dummyInfo)),
    InstNode.EMPTY_NODE(),
    InstNodeType.NORMAL_COMP());

constant ComponentRef TIME_CREF = ComponentRef.CREF(TIME, {}, Type.REAL(), Origin.CREF, ComponentRef.EMPTY());
constant ComponentRef SUBST_CREF = ComponentRef.CREF(SUBST_NODE, {}, Type.ANY(), Origin.CREF, ComponentRef.EMPTY());


function makeBuiltinLookupTree
  "This function takes lists of component and class names and prints out a lookup tree.
   Useful in case any attributes needs to be added to any of the builtin type."
  input String name "Not used in the tree, only to identify the printout.";
  input list<String> components;
  input list<String> classes = {};
protected
  LookupTree.Tree ltree = LookupTree.new();
  Integer i;
algorithm
  i := 1;
  for comp in components loop
    ltree := LookupTree.add(ltree, comp, LookupTree.Entry.COMPONENT(i));
    i := i + 1;
  end for;

  for cls in classes loop
    ltree := LookupTree.add(ltree, cls, LookupTree.Entry.COMPONENT(i));
    i := i + 1;
  end for;

  print("Lookup tree for " + name + ":\n");
  print(anyString(ltree));
  print("\n");
end makeBuiltinLookupTree;

annotation(__OpenModelica_Interface="frontend");
end NFBuiltin;
