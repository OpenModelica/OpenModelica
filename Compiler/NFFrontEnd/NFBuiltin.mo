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
import SCode;
import Binding = NFBinding;
import NFClass.Class;
import NFClassTree;
import NFComponent.Component;
import Expression = NFExpression;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import NFMod.Modifier;
import Type = NFType;
import BuiltinFuncs = NFBuiltinFuncs;
import Pointer;
import NFPrefixes.Variability;
import ComponentRef = NFComponentRef;
import NFComponentRef.Origin;
import Restriction = NFRestriction;

encapsulated package Elements
  import SCode;
  import Absyn;

  // Default parts of the declarations for builtin elements and types:
  public constant Absyn.TypeSpec ENUMTYPE_SPEC =
    Absyn.TPATH(Absyn.IDENT("$EnumType"), NONE());

  // StateSelect-specific elements:
  constant SCode.Element REAL = SCode.CLASS("Real",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

  constant SCode.Element INTEGER = SCode.CLASS("Integer",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

  constant SCode.Element BOOLEAN = SCode.CLASS("Boolean",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

  constant SCode.Element STRING = SCode.CLASS("String",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

  constant SCode.Element ENUMERATION = SCode.CLASS("enumeration",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

  constant SCode.Element ANY = SCode.CLASS("polymorphic",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.noComment, Absyn.dummyInfo);

  constant SCode.Element STATESELECT = SCode.CLASS("StateSelect",
    SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(), SCode.NOT_PARTIAL(), SCode.R_TYPE(),
    SCode.ENUMERATION({
      SCode.ENUM("never",   SCode.noComment),
      SCode.ENUM("avoid",   SCode.noComment),
      SCode.ENUM("default", SCode.noComment),
      SCode.ENUM("prefer",  SCode.noComment),
      SCode.ENUM("always",  SCode.noComment)
    }),
    SCode.noComment, Absyn.dummyInfo);

end Elements;

// InstNodes for the builtin types. These have empty class trees to prevent
// access to the attributes via dot notation (which is not needed for
// modifiers and illegal in other cases).
constant InstNode ANYTYPE_NODE = InstNode.CLASS_NODE("polymorphic",
  Elements.ANY,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.ANY_TYPE("unknown"), NFClassTree.EMPTY,
    Modifier.NOMOD(), Restriction.TYPE())),
  arrayCreate(NFInstNode.NUMBER_OF_CACHES, NFInstNode.CachedData.NO_CACHE()),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant InstNode REAL_NODE = InstNode.CLASS_NODE("Real",
  Elements.REAL,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.REAL(), NFClassTree.EMPTY,
    Modifier.NOMOD(), Restriction.TYPE())),
  arrayCreate(NFInstNode.NUMBER_OF_CACHES, NFInstNode.CachedData.NO_CACHE()),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant InstNode INTEGER_NODE = InstNode.CLASS_NODE("Integer",
  Elements.INTEGER,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.INTEGER(), NFClassTree.EMPTY,
    Modifier.NOMOD(), Restriction.TYPE())),
  listArray({NFInstNode.CachedData.FUNCTION({NFBuiltinFuncs.INTEGER}, true, false), NFInstNode.CachedData.NO_CACHE(), NFInstNode.CachedData.NO_CACHE()}),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant ComponentRef INTEGER_CREF =
  ComponentRef.CREF(INTEGER_NODE, {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

constant InstNode BOOLEAN_NODE = InstNode.CLASS_NODE("Boolean",
  Elements.BOOLEAN,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.BOOLEAN(), NFClassTree.EMPTY,
    Modifier.NOMOD(), Restriction.TYPE())),
  arrayCreate(NFInstNode.NUMBER_OF_CACHES, NFInstNode.CachedData.NO_CACHE()),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant ComponentRef BOOLEAN_CREF =
  ComponentRef.CREF(BOOLEAN_NODE, {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

constant InstNode STRING_NODE = InstNode.CLASS_NODE("String",
  Elements.STRING,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.STRING(), NFClassTree.EMPTY,
    Modifier.NOMOD(), Restriction.TYPE())),
  listArray({ NFInstNode.CachedData.FUNCTION({
	                                              NFBuiltinFuncs.STRING_ENUM, NFBuiltinFuncs.STRING_INT,
	                                              NFBuiltinFuncs.STRING_BOOL, NFBuiltinFuncs.STRING_REAL,
	                                              NFBuiltinFuncs.STRING_REAL_FORMAT
                                              },
                                              true, false),
              NFInstNode.CachedData.NO_CACHE(),
              NFInstNode.CachedData.NO_CACHE()}
            ),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant ComponentRef STRING_CREF =
  ComponentRef.CREF(STRING_NODE, {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

constant InstNode ENUM_NODE = InstNode.CLASS_NODE("enumeration",
  Elements.ENUMERATION,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.ENUMERATION_ANY(), NFClassTree.EMPTY,
    Modifier.NOMOD(), Restriction.ENUMERATION())),
  arrayCreate(NFInstNode.NUMBER_OF_CACHES, NFInstNode.CachedData.NO_CACHE()),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant Type STATESELECT_TYPE = Type.ENUMERATION(
  Absyn.IDENT("StateSelect"), {"never", "avoid", "default", "prefer", "always"});

constant InstNode STATESELECT_NODE = InstNode.CLASS_NODE("StateSelect",
  Elements.STATESELECT,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(STATESELECT_TYPE, NFClassTree.EMPTY,
    Modifier.NOMOD(), Restriction.ENUMERATION())),
  arrayCreate(NFInstNode.NUMBER_OF_CACHES, NFInstNode.CachedData.NO_CACHE()),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant ComponentRef STATESELECT_CREF =
  ComponentRef.CREF(STATESELECT_NODE, {}, STATESELECT_TYPE, Origin.CREF, ComponentRef.EMPTY());

constant Binding STATESELECT_NEVER_BINDING =
  Binding.TYPED_BINDING(
    Expression.ENUM_LITERAL(STATESELECT_TYPE, "never", 1),
    STATESELECT_TYPE,
    Variability.CONSTANT,
    -1,
    Absyn.dummyInfo);

constant Binding STATESELECT_AVOID_BINDING =
  Binding.TYPED_BINDING(
    Expression.ENUM_LITERAL(STATESELECT_TYPE, "avoid", 2),
    STATESELECT_TYPE,
    Variability.CONSTANT,
    -1,
    Absyn.dummyInfo);

constant Binding STATESELECT_DEFAULT_BINDING =
  Binding.TYPED_BINDING(
    Expression.ENUM_LITERAL(STATESELECT_TYPE, "default", 3),
    STATESELECT_TYPE,
    Variability,
    -1,
    Absyn.dummyInfo);

constant Binding STATESELECT_PREFER_BINDING =
  Binding.TYPED_BINDING(
    Expression.ENUM_LITERAL(STATESELECT_TYPE, "prefer", 4),
    STATESELECT_TYPE,
    Variability.CONSTANT,
    -1,
    Absyn.dummyInfo);

constant Binding STATESELECT_ALWAYS_BINDING =
  Binding.TYPED_BINDING(
    Expression.ENUM_LITERAL(STATESELECT_TYPE, "always", 5),
    STATESELECT_TYPE,
    Variability.CONSTANT,
    -1,
    Absyn.dummyInfo);

constant InstNode STATESELECT_NEVER =
  InstNode.COMPONENT_NODE("never",
    Pointer.createImmutable(Component.TYPED_COMPONENT(
      InstNode.EMPTY_NODE(),
      STATESELECT_TYPE,
      STATESELECT_NEVER_BINDING,
      Component.Attributes.DEFAULT(),
      Absyn.dummyInfo)),
    STATESELECT_NODE);

constant ComponentRef STATESELECT_NEVER_CREF =
  ComponentRef.CREF(STATESELECT_NEVER, {}, STATESELECT_TYPE, Origin.CREF, STATESELECT_CREF);

constant InstNode STATESELECT_AVOID =
  InstNode.COMPONENT_NODE("avoid",
    Pointer.createImmutable(Component.TYPED_COMPONENT(
      InstNode.EMPTY_NODE(),
      STATESELECT_TYPE,
      STATESELECT_AVOID_BINDING,
      Component.Attributes.DEFAULT(),
      Absyn.dummyInfo)),
    STATESELECT_NODE);

constant ComponentRef STATESELECT_AVOID_CREF =
  ComponentRef.CREF(STATESELECT_AVOID, {}, STATESELECT_TYPE, Origin.CREF, STATESELECT_CREF);

constant InstNode STATESELECT_DEFAULT =
  InstNode.COMPONENT_NODE("default",
    Pointer.createImmutable(Component.TYPED_COMPONENT(
      InstNode.EMPTY_NODE(),
      STATESELECT_TYPE,
      STATESELECT_DEFAULT_BINDING,
      Component.Attributes.DEFAULT(),
      Absyn.dummyInfo)),
    STATESELECT_NODE);

constant ComponentRef STATESELECT_DEFAULT_CREF =
  ComponentRef.CREF(STATESELECT_DEFAULT, {}, STATESELECT_TYPE, Origin.CREF, STATESELECT_CREF);

constant InstNode STATESELECT_PREFER =
  InstNode.COMPONENT_NODE("prefer",
    Pointer.createImmutable(Component.TYPED_COMPONENT(
      InstNode.EMPTY_NODE(),
      STATESELECT_TYPE,
      STATESELECT_PREFER_BINDING,
      Component.Attributes.DEFAULT(),
      Absyn.dummyInfo)),
    STATESELECT_NODE);

constant ComponentRef STATESELECT_PREFER_CREF =
  ComponentRef.CREF(STATESELECT_PREFER, {}, STATESELECT_TYPE, Origin.CREF, STATESELECT_CREF);

constant InstNode STATESELECT_ALWAYS =
  InstNode.COMPONENT_NODE("always",
    Pointer.createImmutable(Component.TYPED_COMPONENT(
      InstNode.EMPTY_NODE(),
      STATESELECT_TYPE,
      STATESELECT_ALWAYS_BINDING,
      Component.Attributes.DEFAULT(),
      Absyn.dummyInfo)),
    STATESELECT_NODE);

constant ComponentRef STATESELECT_ALWAYS_CREF =
  ComponentRef.CREF(STATESELECT_ALWAYS, {}, STATESELECT_TYPE, Origin.CREF, STATESELECT_CREF);

constant Type ASSERTIONLEVEL_TYPE = Type.ENUMERATION(
  Absyn.IDENT("AssertionLevel"), {"error", "warning"});

constant Expression ASSERTIONLEVEL_ERROR = Expression.ENUM_LITERAL(
  ASSERTIONLEVEL_TYPE, "error", 1);

constant Expression ASSERTIONLEVEL_WARNING = Expression.ENUM_LITERAL(
  ASSERTIONLEVEL_TYPE, "error", 2);

constant InstNode TIME =
  InstNode.COMPONENT_NODE("time",
    Pointer.createImmutable(Component.TYPED_COMPONENT(
      REAL_NODE,
      Type.REAL(),
      Binding.UNBOUND(),
      NFComponent.INPUT_ATTR,
      Absyn.dummyInfo)),
    InstNode.EMPTY_NODE());

constant ComponentRef TIME_CREF = ComponentRef.CREF(TIME, {}, Type.REAL(), Origin.CREF, ComponentRef.EMPTY());

annotation(__OpenModelica_Interface="frontend");
end NFBuiltin;
