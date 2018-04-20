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

encapsulated package NFBuiltinFuncs

import NFClass.Class;
import NFClassTree.ClassTree;
import NFFunction.Function;
import NFFunction.Slot;
import NFFunction.SlotType;
import NFFunction.FuncType;
import NFInstNode.CachedData;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import NFComponent.Component;
import Type = NFType;
import Expression = NFExpression;
import Absyn;
import Absyn.{Path, TypeSpec};
import SCode;
import SCode.{Mod, Comment};
import DAE;
import Builtin = NFBuiltin;
import Binding = NFBinding;
import Pointer;
import NFPrefixes.Visibility;
import Restriction = NFRestriction;
import ComponentRef = NFComponentRef;
import NFComponentRef.Origin;
import NFModifier.Modifier;
import Sections = NFSections;

protected
import MetaModelica.Dangerous.*;

public
constant SCode.Element DUMMY_ELEMENT = SCode.CLASS(
  "$DummyFunction",
  SCode.defaultPrefixes,
  SCode.Encapsulated.ENCAPSULATED(),
  SCode.Partial.NOT_PARTIAL(),
  SCode.Restriction.R_FUNCTION(SCode.FunctionRestriction.FR_NORMAL_FUNCTION(false)),
  SCode.ClassDef.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
  SCode.Comment.COMMENT(NONE(), NONE()),
  Absyn.dummyInfo
);

// Default Integer parameter.
constant Component INT_COMPONENT = Component.TYPED_COMPONENT(NFInstNode.EMPTY_NODE(),
  Type.INTEGER(), Binding.UNBOUND(NONE()), Binding.UNBOUND(NONE()), NFComponent.DEFAULT_ATTR, NONE(), Absyn.dummyInfo);

constant InstNode INT_PARAM = InstNode.COMPONENT_NODE("i",
  Visibility.PUBLIC,
  Pointer.createImmutable(INT_COMPONENT), InstNode.EMPTY_NODE());

// Default Real parameter.
constant Component REAL_COMPONENT = Component.TYPED_COMPONENT(NFInstNode.EMPTY_NODE(),
  Type.REAL(), Binding.UNBOUND(NONE()), Binding.UNBOUND(NONE()), NFComponent.DEFAULT_ATTR, NONE(), Absyn.dummyInfo);

constant InstNode REAL_PARAM = InstNode.COMPONENT_NODE("r",
  Visibility.PUBLIC,
  Pointer.createImmutable(REAL_COMPONENT), InstNode.EMPTY_NODE());

// Default Boolean parameter.
constant Component BOOL_COMPONENT = Component.TYPED_COMPONENT(NFInstNode.EMPTY_NODE(),
  Type.BOOLEAN(), Binding.UNBOUND(NONE()), Binding.UNBOUND(NONE()), NFComponent.DEFAULT_ATTR, NONE(), Absyn.dummyInfo);

constant InstNode BOOL_PARAM = InstNode.COMPONENT_NODE("b",
  Visibility.PUBLIC,
  Pointer.createImmutable(BOOL_COMPONENT), InstNode.EMPTY_NODE());

// Default String parameter.
constant Component STRING_COMPONENT = Component.TYPED_COMPONENT(NFInstNode.EMPTY_NODE(),
  Type.STRING(), Binding.UNBOUND(NONE()), Binding.UNBOUND(NONE()), NFComponent.DEFAULT_ATTR, NONE(), Absyn.dummyInfo);

constant InstNode STRING_PARAM = InstNode.COMPONENT_NODE("s",
  Visibility.PUBLIC,
  Pointer.createImmutable(STRING_COMPONENT), InstNode.EMPTY_NODE());

// Default enumeration(:) parameter.
constant Component ENUM_COMPONENT = Component.TYPED_COMPONENT(NFInstNode.EMPTY_NODE(),
  Type.ENUMERATION_ANY(), Binding.UNBOUND(NONE()), Binding.UNBOUND(NONE()), NFComponent.DEFAULT_ATTR, NONE(), Absyn.dummyInfo);

constant InstNode ENUM_PARAM = InstNode.COMPONENT_NODE("e",
  Visibility.PUBLIC,
  Pointer.createImmutable(ENUM_COMPONENT), InstNode.EMPTY_NODE());

// Integer(e)
constant array<NFInstNode.CachedData> EMPTY_NODE_CACHE = listArrayLiteral({
  NFInstNode.CachedData.NO_CACHE(),
  NFInstNode.CachedData.NO_CACHE(),
  NFInstNode.CachedData.NO_CACHE()
});

constant InstNode INTEGER_DUMMY_NODE = NFInstNode.CLASS_NODE("Integer",
  DUMMY_ELEMENT, Visibility.PUBLIC, Pointer.createImmutable(Class.NOT_INSTANTIATED()),
  EMPTY_NODE_CACHE,
  InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant Function INTEGER_FUNCTION = Function.FUNCTION(Path.IDENT("Integer"),
  INTEGER_DUMMY_NODE, {ENUM_PARAM}, {}, {}, {
    Slot.SLOT("e", SlotType.POSITIONAL, NONE(), NONE())
  }, Type.INTEGER(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

constant InstNode INTEGER_NODE = InstNode.CLASS_NODE("IntegerFunc",
  DUMMY_ELEMENT, Visibility.PUBLIC,
  Pointer.createImmutable(Class.INSTANCED_CLASS(Type.UNKNOWN(), ClassTree.EMPTY_TREE(),
    Sections.EMPTY(), Restriction.FUNCTION())),
  listArrayLiteral({NFInstNode.CachedData.FUNCTION({INTEGER_FUNCTION}, true, false),
                    NFInstNode.CachedData.NO_CACHE(),
                    NFInstNode.CachedData.NO_CACHE()}),
  InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant ComponentRef INTEGER_CREF =
  ComponentRef.CREF(INTEGER_NODE, {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

constant InstNode STRING_DUMMY_NODE = NFInstNode.CLASS_NODE("String",
  DUMMY_ELEMENT, Visibility.PUBLIC, Pointer.createImmutable(Class.NOT_INSTANTIATED()),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

// String(r, significantDigits=d, minimumLength=0, leftJustified=true)
constant Function STRING_REAL = Function.FUNCTION(Path.IDENT("String"),
  STRING_DUMMY_NODE, {REAL_PARAM, INT_PARAM, INT_PARAM, BOOL_PARAM}, {STRING_PARAM}, {}, {
    Slot.SLOT("r", SlotType.POSITIONAL, NONE(), NONE()),
    Slot.SLOT("significantDigits", SlotType.NAMED, SOME(Expression.INTEGER(6)), NONE()),
    Slot.SLOT("minimumLength", SlotType.NAMED, SOME(Expression.INTEGER(0)), NONE()),
    Slot.SLOT("leftJustified", SlotType.NAMED, SOME(Expression.BOOLEAN(true)), NONE())
  }, Type.STRING(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

// String(r, format="-0.6g")
constant Function STRING_REAL_FORMAT = Function.FUNCTION(Path.IDENT("String"),
  STRING_DUMMY_NODE, {REAL_PARAM, STRING_PARAM}, {STRING_PARAM}, {}, {
    Slot.SLOT("r", SlotType.POSITIONAL, NONE(), NONE()),
    Slot.SLOT("format", SlotType.NAMED, NONE(), NONE())
  }, Type.STRING(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

// String(i, minimumLength=0, leftJustified=true)
constant Function STRING_INT = Function.FUNCTION(Path.IDENT("String"),
  STRING_DUMMY_NODE, {INT_PARAM, INT_PARAM, BOOL_PARAM}, {STRING_PARAM}, {}, {
    Slot.SLOT("i", SlotType.POSITIONAL, NONE(), NONE()),
    Slot.SLOT("minimumLength", SlotType.NAMED, SOME(Expression.INTEGER(0)), NONE()),
    Slot.SLOT("leftJustified", SlotType.NAMED, SOME(Expression.BOOLEAN(true)), NONE())
  }, Type.STRING(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

// String(b, minimumLength=0, leftJustified=true)
constant Function STRING_BOOL = Function.FUNCTION(Path.IDENT("String"),
  STRING_DUMMY_NODE, {BOOL_PARAM, INT_PARAM, BOOL_PARAM}, {STRING_PARAM}, {}, {
    Slot.SLOT("b", SlotType.POSITIONAL, NONE(), NONE()),
    Slot.SLOT("minimumLength", SlotType.NAMED, SOME(Expression.INTEGER(0)), NONE()),
    Slot.SLOT("leftJustified", SlotType.NAMED, SOME(Expression.BOOLEAN(true)), NONE())
  }, Type.STRING(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

// String(e, minimumLength=0, leftJustified=true)
constant Function STRING_ENUM = Function.FUNCTION(Path.IDENT("String"),
  STRING_DUMMY_NODE, {ENUM_PARAM, INT_PARAM, BOOL_PARAM}, {STRING_PARAM}, {}, {
    Slot.SLOT("e", SlotType.POSITIONAL, NONE(), NONE()),
    Slot.SLOT("minimumLength", SlotType.NAMED, SOME(Expression.INTEGER(0)), NONE()),
    Slot.SLOT("leftJustified", SlotType.NAMED, SOME(Expression.BOOLEAN(true)), NONE())
  }, Type.STRING(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

constant InstNode STRING_NODE = InstNode.CLASS_NODE("String",
  DUMMY_ELEMENT, Visibility.PUBLIC,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.STRING(), ClassTree.EMPTY_TREE(),
    Modifier.NOMOD(), Restriction.TYPE())),
  listArrayLiteral({
    NFInstNode.CachedData.FUNCTION({
        STRING_ENUM,
        STRING_INT,
        STRING_BOOL,
        STRING_REAL,
        STRING_REAL_FORMAT},
      true, true),
    NFInstNode.CachedData.NO_CACHE(),
    NFInstNode.CachedData.NO_CACHE()}
  ),
  InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant ComponentRef STRING_CREF =
  ComponentRef.CREF(STRING_NODE, {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

constant Function ABS_REAL = Function.FUNCTION(Path.IDENT("abs"),
  InstNode.EMPTY_NODE(), {REAL_PARAM, REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

constant Function MAX_REAL = Function.FUNCTION(Path.IDENT("max"),
  InstNode.EMPTY_NODE(), {REAL_PARAM, REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

constant Function POSITIVE_MAX_REAL = Function.FUNCTION(Path.IDENT("$OMC$PositiveMax"),
  InstNode.EMPTY_NODE(), {REAL_PARAM, REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

constant Function IN_STREAM = Function.FUNCTION(Path.IDENT("inStream"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

constant Function PROMOTE = Function.FUNCTION(Path.IDENT("promote"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

constant Function CAT = Function.FUNCTION(Path.IDENT("cat"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

constant Function ARRAY_FUNC = Function.FUNCTION(Path.IDENT("array"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

constant Function FILL_FUNC = Function.FUNCTION(Path.IDENT("fill"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, Pointer.createImmutable(true));

annotation(__OpenModelica_Interface="frontend");
end NFBuiltinFuncs;
