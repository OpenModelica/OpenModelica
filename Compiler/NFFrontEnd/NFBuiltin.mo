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
import DAE;
import SCode;
import Binding = NFBinding;
import NFClass.Class;
import NFClass.ClassTree;
import NFComponent.Component;
import Expression = NFExpression;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import NFMod.Modifier;
import Type = NFType;
import BuiltinFuncs = NFBuiltinFuncs;

encapsulated package Elements
  import SCode;
  import Absyn;

  // Default parts of the declarations for builtin elements and types:
  public constant Absyn.TypeSpec ENUMTYPE_SPEC =
    Absyn.TPATH(Absyn.IDENT("$EnumType"), NONE());

  // StateSelect-specific elements:
  constant SCode.Element STATESELECT_NEVER = SCode.COMPONENT(
    "never", SCode.defaultPrefixes, SCode.defaultConstAttr, ENUMTYPE_SPEC,
    SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

  constant SCode.Element STATESELECT_AVOID = SCode.COMPONENT(
    "avoid", SCode.defaultPrefixes, SCode.defaultConstAttr, ENUMTYPE_SPEC,
    SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

  constant SCode.Element STATESELECT_DEFAULT = SCode.COMPONENT(
    "default", SCode.defaultPrefixes, SCode.defaultConstAttr, ENUMTYPE_SPEC,
    SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

  constant SCode.Element STATESELECT_PREFER = SCode.COMPONENT(
    "prefer", SCode.defaultPrefixes, SCode.defaultConstAttr, ENUMTYPE_SPEC,
    SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

  constant SCode.Element STATESELECT_ALWAYS = SCode.COMPONENT(
    "always", SCode.defaultPrefixes, SCode.defaultConstAttr, ENUMTYPE_SPEC,
    SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

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

  // Builtin variable time:
  constant SCode.Element TIME = SCode.COMPONENT("time", SCode.defaultPrefixes,
      SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.VAR(), Absyn.INPUT(), Absyn.NONFIELD()),
      Absyn.TPATH(Absyn.IDENT("Real"), NONE()), SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);

end Elements;

// InstNodes for the builtin types. These have empty class trees to prevent
// access to the attributes via dot notation (which is not needed for
// modifiers and illegal in other cases).
constant InstNode REAL_TYPE = InstNode.CLASS_NODE("Real",
  Elements.REAL,
  listArray({Class.PARTIAL_BUILTIN(Type.REAL(), ClassTree.EMPTY(), listArray({}), Modifier.NOMOD())}),
  listArray({NFInstNode.CachedData.NO_CACHE()}),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant InstNode INT_TYPE = InstNode.CLASS_NODE("Integer",
  Elements.INTEGER,
  listArray({Class.PARTIAL_BUILTIN(Type.INTEGER(), ClassTree.EMPTY(), listArray({}), Modifier.NOMOD())}),
  listArray({NFInstNode.CachedData.FUNCTION({NFBuiltinFuncs.INTEGER}, true)}),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant InstNode BOOLEAN_TYPE = InstNode.CLASS_NODE("Boolean",
  Elements.BOOLEAN,
  listArray({Class.PARTIAL_BUILTIN(Type.BOOLEAN(), ClassTree.EMPTY(), listArray({}), Modifier.NOMOD())}),
  listArray({NFInstNode.CachedData.NO_CACHE()}),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant InstNode STRING_TYPE = InstNode.CLASS_NODE("String",
  Elements.STRING,
  listArray({Class.PARTIAL_BUILTIN(Type.STRING(), ClassTree.EMPTY(), listArray({}), Modifier.NOMOD())}),
  listArray({NFInstNode.CachedData.FUNCTION({
    NFBuiltinFuncs.STRING_ENUM, NFBuiltinFuncs.STRING_INT,
    NFBuiltinFuncs.STRING_BOOL, NFBuiltinFuncs.STRING_REAL,
    NFBuiltinFuncs.STRING_REAL_FORMAT}, true)}),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant InstNode ENUM_TYPE = InstNode.CLASS_NODE("enumeration",
  Elements.ENUMERATION,
  listArray({Class.PARTIAL_BUILTIN(Type.ENUMERATION_ANY(), ClassTree.EMPTY(), listArray({}), Modifier.NOMOD())}),
  listArray({NFInstNode.CachedData.NO_CACHE()}),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant Type STATESELECT_TYPE_TYPE = Type.ENUMERATION(
  Absyn.IDENT("StateSelect"), {"never", "avoid", "default", "prefer", "always"});

constant InstNode STATESELECT_TYPE = InstNode.CLASS_NODE("StateSelect",
  Elements.STATESELECT,
  listArray({Class.PARTIAL_BUILTIN(STATESELECT_TYPE_TYPE, ClassTree.EMPTY(), listArray({}), Modifier.NOMOD())}),
  listArray({NFInstNode.CachedData.NO_CACHE()}),
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant Binding STATESELECT_NEVER_BINDING =
  Binding.TYPED_BINDING(
    Expression.ENUM_LITERAL(STATESELECT_TYPE_TYPE, "never", 1),
    STATESELECT_TYPE_TYPE,
    DAE.C_CONST(),
    -1,
    Absyn.dummyInfo);

constant Binding STATESELECT_AVOID_BINDING =
  Binding.TYPED_BINDING(
    Expression.ENUM_LITERAL(STATESELECT_TYPE_TYPE, "avoid", 2),
    STATESELECT_TYPE_TYPE,
    DAE.C_CONST(),
    -1,
    Absyn.dummyInfo);

constant Binding STATESELECT_DEFAULT_BINDING =
  Binding.TYPED_BINDING(
    Expression.ENUM_LITERAL(STATESELECT_TYPE_TYPE, "default", 3),
    STATESELECT_TYPE_TYPE,
    DAE.C_CONST(),
    -1,
    Absyn.dummyInfo);

constant Binding STATESELECT_PREFER_BINDING =
  Binding.TYPED_BINDING(
    Expression.ENUM_LITERAL(STATESELECT_TYPE_TYPE, "prefer", 4),
    STATESELECT_TYPE_TYPE,
    DAE.C_CONST(),
    -1,
    Absyn.dummyInfo);

constant Binding STATESELECT_ALWAYS_BINDING =
  Binding.TYPED_BINDING(
    Expression.ENUM_LITERAL(STATESELECT_TYPE_TYPE, "always", 5),
    STATESELECT_TYPE_TYPE,
    DAE.C_CONST(),
    -1,
    Absyn.dummyInfo);

constant InstNode STATESELECT_NEVER =
  InstNode.COMPONENT_NODE("never",
    Elements.STATESELECT_NEVER,
    listArray({Component.TYPED_COMPONENT(
      InstNode.EMPTY_NODE(),
      STATESELECT_TYPE_TYPE,
      STATESELECT_NEVER_BINDING,
      NFComponent.CONST_ATTR)}),
    STATESELECT_TYPE);

constant InstNode STATESELECT_AVOID =
  InstNode.COMPONENT_NODE("avoid",
    Elements.STATESELECT_AVOID,
    listArray({Component.TYPED_COMPONENT(
      InstNode.EMPTY_NODE(),
      STATESELECT_TYPE_TYPE,
      STATESELECT_AVOID_BINDING,
      NFComponent.CONST_ATTR)}),
    STATESELECT_TYPE);

constant InstNode STATESELECT_DEFAULT =
  InstNode.COMPONENT_NODE("default",
    Elements.STATESELECT_DEFAULT,
    listArray({Component.TYPED_COMPONENT(
      InstNode.EMPTY_NODE(),
      STATESELECT_TYPE_TYPE,
      STATESELECT_DEFAULT_BINDING,
      NFComponent.CONST_ATTR)}),
    STATESELECT_TYPE);

constant InstNode STATESELECT_PREFER =
  InstNode.COMPONENT_NODE("prefer",
    Elements.STATESELECT_PREFER,
    listArray({Component.TYPED_COMPONENT(
      InstNode.EMPTY_NODE(),
      STATESELECT_TYPE_TYPE,
      STATESELECT_PREFER_BINDING,
      NFComponent.CONST_ATTR)}),
    STATESELECT_TYPE);

constant InstNode STATESELECT_ALWAYS =
InstNode.COMPONENT_NODE("always",
    Elements.STATESELECT_ALWAYS,
    listArray({Component.TYPED_COMPONENT(
      InstNode.EMPTY_NODE(),
      STATESELECT_TYPE_TYPE,
      STATESELECT_ALWAYS_BINDING,
      NFComponent.CONST_ATTR)}),
    STATESELECT_TYPE);

constant InstNode TIME =
  InstNode.COMPONENT_NODE("time",
    Elements.TIME,
    listArray({Component.TYPED_COMPONENT(
      REAL_TYPE,
      Type.REAL(),
      Binding.UNBOUND(),
      NFComponent.INPUT_ATTR)}),
    InstNode.EMPTY_NODE());

annotation(__OpenModelica_Interface="frontend");
end NFBuiltin;
