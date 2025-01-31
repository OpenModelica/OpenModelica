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

import Attributes = NFAttributes;
import Class = NFClass;
import NFClassTree.ClassTree;
import NFFunction.Function;
import NFFunction.Slot;
import NFFunction.SlotType;
import NFFunction.FuncType;
import NFInstNode.CachedData;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import Component = NFComponent;
import NFComponent.ComponentState;
import Type = NFType;
import Expression = NFExpression;
import Absyn;
import AbsynUtil;
import Absyn.{Path, TypeSpec};
import SCode;
import SCode.{Mod, Comment};
import DAE;
import NFBinding;
import Pointer;
import NFPrefixes.Visibility;
import Restriction = NFRestriction;
import ComponentRef = NFComponentRef;
import NFComponentRef.Origin;
import NFModifier.Modifier;
import Sections = NFSections;
import NFFunction.SlotEvalStatus;
import NFFunction.FunctionStatus;

protected
import MetaModelica.Dangerous.*;

public
constant SCode.Element DUMMY_ELEMENT = SCode.CLASS(
  "$DummyFunction",
  SCode.defaultPrefixes,
  SCode.Encapsulated.ENCAPSULATED(),
  SCode.Partial.NOT_PARTIAL(),
  SCode.Restriction.R_FUNCTION(SCode.FunctionRestriction.FR_NORMAL_FUNCTION(Absyn.FunctionPurity.NO_PURITY())),
  SCode.ClassDef.PARTS({}, {}, {}, {}, {}, {}, {}, NONE()),
  SCode.Comment.COMMENT(NONE(), NONE()),
  AbsynUtil.dummyInfo
);

// Default Integer parameter.
constant Component INT_COMPONENT = Component.COMPONENT(NFInstNode.EMPTY_NODE(),
  Type.INTEGER(), NFBinding.EMPTY_BINDING, NFBinding.EMPTY_BINDING,
  NFAttributes.DEFAULT_ATTR, NONE(), ComponentState.TypeChecked, AbsynUtil.dummyInfo);

constant InstNode INT_PARAM = InstNode.COMPONENT_NODE("i",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(INT_COMPONENT), InstNode.EMPTY_NODE(),
  InstNodeType.NORMAL_COMP());

// Default Real parameter.
constant Component REAL_COMPONENT = Component.COMPONENT(NFInstNode.EMPTY_NODE(),
  Type.REAL(), NFBinding.EMPTY_BINDING, NFBinding.EMPTY_BINDING,
  NFAttributes.DEFAULT_ATTR, NONE(), ComponentState.TypeChecked, AbsynUtil.dummyInfo);

constant InstNode REAL_PARAM = InstNode.COMPONENT_NODE("r",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(REAL_COMPONENT), InstNode.EMPTY_NODE(),
  InstNodeType.NORMAL_COMP());

// Default Boolean parameter.
constant Component BOOL_COMPONENT = Component.COMPONENT(NFInstNode.EMPTY_NODE(),
  Type.BOOLEAN(), NFBinding.EMPTY_BINDING, NFBinding.EMPTY_BINDING,
  NFAttributes.DEFAULT_ATTR, NONE(), ComponentState.TypeChecked, AbsynUtil.dummyInfo);

constant InstNode BOOL_PARAM = InstNode.COMPONENT_NODE("b",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(BOOL_COMPONENT), InstNode.EMPTY_NODE(),
  InstNodeType.NORMAL_COMP());

// Default String parameter.
constant Component STRING_COMPONENT = Component.COMPONENT(NFInstNode.EMPTY_NODE(),
  Type.STRING(), NFBinding.EMPTY_BINDING, NFBinding.EMPTY_BINDING,
  NFAttributes.DEFAULT_ATTR, NONE(), ComponentState.TypeChecked, AbsynUtil.dummyInfo);

constant InstNode STRING_PARAM = InstNode.COMPONENT_NODE("s",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(STRING_COMPONENT), InstNode.EMPTY_NODE(),
  InstNodeType.NORMAL_COMP());

// Default enumeration(:) parameter.
constant Component ENUM_COMPONENT = Component.COMPONENT(NFInstNode.EMPTY_NODE(),
  Type.ENUMERATION(Absyn.Path.IDENT(":"), {}), NFBinding.EMPTY_BINDING, NFBinding.EMPTY_BINDING,
  NFAttributes.DEFAULT_ATTR, NONE(), ComponentState.TypeChecked, AbsynUtil.dummyInfo);

constant InstNode ENUM_PARAM = InstNode.COMPONENT_NODE("e",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(ENUM_COMPONENT), InstNode.EMPTY_NODE(),
  InstNodeType.NORMAL_COMP());

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
    Slot.SLOT(ENUM_PARAM, SlotType.POSITIONAL, NONE(), NONE(), 1, SlotEvalStatus.NOT_EVALUATED)
  }, Type.INTEGER(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}), Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant InstNode INTEGER_NODE = InstNode.CLASS_NODE("IntegerFunc",
  DUMMY_ELEMENT, Visibility.PUBLIC,
  Pointer.createImmutable(Class.INSTANCED_CLASS(Type.UNKNOWN(), ClassTree.EMPTY_TREE(),
    Sections.EMPTY(), NFClass.DEFAULT_PREFIXES, Restriction.FUNCTION())),
  listArrayLiteral({NFInstNode.CachedData.FUNCTION({INTEGER_FUNCTION}, true, false),
                    NFInstNode.CachedData.NO_CACHE(),
                    NFInstNode.CachedData.NO_CACHE()}),
  InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant ComponentRef INTEGER_CREF =
  ComponentRef.CREF(INTEGER_NODE, {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

constant InstNode STRING_DUMMY_NODE = NFInstNode.CLASS_NODE("String",
  DUMMY_ELEMENT, Visibility.PUBLIC, Pointer.createImmutable(Class.NOT_INSTANTIATED()),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

constant InstNode R_PARAM = InstNode.COMPONENT_NODE("r", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(REAL_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode I_PARAM = InstNode.COMPONENT_NODE("i", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(INT_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode B_PARAM = InstNode.COMPONENT_NODE("b", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(BOOL_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode E_PARAM = InstNode.COMPONENT_NODE("e", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(ENUM_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode SIGNIFICANT_DIGITS_PARAM = InstNode.COMPONENT_NODE("significantDigits", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(INT_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode MINIMUM_LENGTH_PARAM = InstNode.COMPONENT_NODE("minimumLength", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(INT_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode LEFT_JUSTIFIED_PARAM = InstNode.COMPONENT_NODE("leftJustified", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(BOOL_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode FORMAT_PARAM = InstNode.COMPONENT_NODE("format", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(STRING_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());

// String(r, significantDigits=d, minimumLength=0, leftJustified=true)
constant Function STRING_REAL = Function.FUNCTION(Path.IDENT("String"),
  STRING_DUMMY_NODE, {REAL_PARAM, INT_PARAM, INT_PARAM, BOOL_PARAM}, {STRING_PARAM}, {}, {
    Slot.SLOT(R_PARAM, SlotType.POSITIONAL, NONE(), NONE(), 1, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(SIGNIFICANT_DIGITS_PARAM, SlotType.NAMED, SOME(Expression.INTEGER(6)), NONE(), 2, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(MINIMUM_LENGTH_PARAM, SlotType.NAMED, SOME(Expression.INTEGER(0)), NONE(), 3, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(LEFT_JUSTIFIED_PARAM, SlotType.NAMED, SOME(Expression.BOOLEAN(true)), NONE(), 4, SlotEvalStatus.NOT_EVALUATED)
  }, Type.STRING(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
  Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

// String(r, format="-0.6g")
constant Function STRING_REAL_FORMAT = Function.FUNCTION(Path.IDENT("String"),
  STRING_DUMMY_NODE, {REAL_PARAM, STRING_PARAM}, {STRING_PARAM}, {}, {
    Slot.SLOT(R_PARAM, SlotType.POSITIONAL, NONE(), NONE(), 1, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(FORMAT_PARAM, SlotType.NAMED, NONE(), NONE(), 2, SlotEvalStatus.NOT_EVALUATED)
  }, Type.STRING(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
  Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

// String(i, minimumLength=0, leftJustified=true)
constant Function STRING_INT = Function.FUNCTION(Path.IDENT("String"),
  STRING_DUMMY_NODE, {INT_PARAM, INT_PARAM, BOOL_PARAM}, {STRING_PARAM}, {}, {
    Slot.SLOT(I_PARAM, SlotType.POSITIONAL, NONE(), NONE(), 1, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(MINIMUM_LENGTH_PARAM, SlotType.NAMED, SOME(Expression.INTEGER(0)), NONE(), 2, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(LEFT_JUSTIFIED_PARAM, SlotType.NAMED, SOME(Expression.BOOLEAN(true)), NONE(), 3, SlotEvalStatus.NOT_EVALUATED)
  }, Type.STRING(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
  Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

// String(b, minimumLength=0, leftJustified=true)
constant Function STRING_BOOL = Function.FUNCTION(Path.IDENT("String"),
  STRING_DUMMY_NODE, {BOOL_PARAM, INT_PARAM, BOOL_PARAM}, {STRING_PARAM}, {}, {
    Slot.SLOT(B_PARAM, SlotType.POSITIONAL, NONE(), NONE(), 1, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(MINIMUM_LENGTH_PARAM, SlotType.NAMED, SOME(Expression.INTEGER(0)), NONE(), 2, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(LEFT_JUSTIFIED_PARAM, SlotType.NAMED, SOME(Expression.BOOLEAN(true)), NONE(), 3, SlotEvalStatus.NOT_EVALUATED)
  }, Type.STRING(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
  Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

// String(e, minimumLength=0, leftJustified=true)
constant Function STRING_ENUM = Function.FUNCTION(Path.IDENT("String"),
  STRING_DUMMY_NODE, {ENUM_PARAM, INT_PARAM, BOOL_PARAM}, {STRING_PARAM}, {}, {
    Slot.SLOT(E_PARAM, SlotType.POSITIONAL, NONE(), NONE(), 1, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(MINIMUM_LENGTH_PARAM, SlotType.NAMED, SOME(Expression.INTEGER(0)), NONE(), 2, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(LEFT_JUSTIFIED_PARAM, SlotType.NAMED, SOME(Expression.BOOLEAN(true)), NONE(), 3, SlotEvalStatus.NOT_EVALUATED)
  }, Type.STRING(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
  Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant InstNode STRING_NODE = InstNode.CLASS_NODE("String",
  DUMMY_ELEMENT, Visibility.PUBLIC,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.STRING(), ClassTree.EMPTY_TREE(),
    Modifier.NOMOD(), NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
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

// TODO: Sort these functions ...
constant Function COS_REAL = Function.FUNCTION(Path.IDENT("cos"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function SIN_REAL = Function.FUNCTION(Path.IDENT("sin"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function TAN_REAL = Function.FUNCTION(Path.IDENT("tan"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function ACOS_REAL = Function.FUNCTION(Path.IDENT("acos"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function ASIN_REAL = Function.FUNCTION(Path.IDENT("asin"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function ATAN_REAL = Function.FUNCTION(Path.IDENT("atan"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function COSH_REAL = Function.FUNCTION(Path.IDENT("cosh"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function SINH_REAL = Function.FUNCTION(Path.IDENT("sinh"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function TANH_REAL = Function.FUNCTION(Path.IDENT("tanh"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function ACOSH_REAL = Function.FUNCTION(Path.IDENT("acosh"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function ASINH_REAL = Function.FUNCTION(Path.IDENT("asinh"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function ATANH_REAL = Function.FUNCTION(Path.IDENT("atanh"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));
    
constant Function EXP_REAL = Function.FUNCTION(Path.IDENT("exp"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function LOG_REAL = Function.FUNCTION(Path.IDENT("log"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function LOG10_REAL = Function.FUNCTION(Path.IDENT("log10"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function ABS_REAL = Function.FUNCTION(Path.IDENT("abs"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function SIGN = Function.FUNCTION(Path.IDENT("sign"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.INTEGER(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function MAX_INT = Function.FUNCTION(Path.IDENT("max"),
  InstNode.EMPTY_NODE(), {INT_PARAM, INT_PARAM}, {INT_PARAM}, {}, {},
    Type.INTEGER(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function MAX_REAL = Function.FUNCTION(Path.IDENT("max"),
  InstNode.EMPTY_NODE(), {REAL_PARAM, REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function DIV_INT = Function.FUNCTION(Path.IDENT("div"),
  InstNode.EMPTY_NODE(), {INT_PARAM, INT_PARAM}, {INT_PARAM}, {}, {},
    Type.INTEGER(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function DIV_REAL = Function.FUNCTION(Path.IDENT("div"),
  InstNode.EMPTY_NODE(), {REAL_PARAM, REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function FLOOR = Function.FUNCTION(Path.IDENT("floor"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function INTEGER_REAL = Function.FUNCTION(Path.IDENT("integer"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {INT_PARAM}, {}, {},
    Type.INTEGER(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function INTEGER_ENUM = Function.FUNCTION(Path.IDENT("Integer"),
  InstNode.EMPTY_NODE(), {ENUM_PARAM}, {INT_PARAM}, {}, {},
    Type.INTEGER(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function POSITIVE_MAX_REAL = Function.FUNCTION(Path.IDENT("$OMC$PositiveMax"),
  InstNode.EMPTY_NODE(), {REAL_PARAM, REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function INSTREAM_DIV_REAL = Function.FUNCTION(Path.IDENT("$OMC$inStreamDiv"),
  InstNode.EMPTY_NODE(), {REAL_PARAM, REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function IN_STREAM = Function.FUNCTION(Path.IDENT("inStream"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function PROMOTE = Function.FUNCTION(Path.IDENT("promote"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function CAT = Function.FUNCTION(Path.IDENT("cat"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function ARRAY_FUNC = Function.FUNCTION(Path.IDENT("array"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function FILL_FUNC = Function.FUNCTION(Path.IDENT("fill"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function SMOOTH = Function.FUNCTION(Path.IDENT("smooth"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function NO_EVENT = Function.FUNCTION(Path.IDENT("noEvent"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function PRE = Function.FUNCTION(Path.IDENT("pre"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function SUM = Function.FUNCTION(Path.IDENT("sum"),
  InstNode.EMPTY_NODE(), {}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function SAMPLE = Function.FUNCTION(Path.QUALIFIED("OMC_NO_CLOCK", Path.IDENT("sample")),
  InstNode.EMPTY_NODE(), {REAL_PARAM, REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.BOOLEAN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN_IMPURE, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Component CLOCK_COMPONENT = Component.COMPONENT(NFInstNode.EMPTY_NODE(),
  Type.CLOCK(), NFBinding.EMPTY_BINDING, NFBinding.EMPTY_BINDING,
  NFAttributes.DEFAULT_ATTR, NONE(), ComponentState.TypeChecked, AbsynUtil.dummyInfo);

constant InstNode CLOCK_PARAM = InstNode.COMPONENT_NODE("s",
  NONE(), Visibility.PUBLIC,
  Pointer.createImmutable(CLOCK_COMPONENT), InstNode.EMPTY_NODE(),
  InstNodeType.NORMAL_COMP());

constant InstNode CLOCK_DUMMY_NODE = NFInstNode.CLASS_NODE("Clock",
  DUMMY_ELEMENT, Visibility.PUBLIC, Pointer.createImmutable(Class.NOT_INSTANTIATED()),
  EMPTY_NODE_CACHE, InstNode.EMPTY_NODE(), InstNodeType.NORMAL_CLASS());

// Clock() - inferred clock
constant Function CLOCK_INFERRED = Function.FUNCTION(Path.IDENT("Clock"),
  CLOCK_DUMMY_NODE, {}, {CLOCK_PARAM}, {}, {}, Type.CLOCK(),
  DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
  Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant InstNode INTERVAL_COUNTER_PARAM = InstNode.COMPONENT_NODE("intervalCounter", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(INT_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode RESOLUTION_PARAM = InstNode.COMPONENT_NODE("resolution", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(INT_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode INTERVAL_PARAM = InstNode.COMPONENT_NODE("interval", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(REAL_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode CONDITION_PARAM = InstNode.COMPONENT_NODE("condition", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(BOOL_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode START_INTERVAL_PARAM = InstNode.COMPONENT_NODE("startInterval", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(REAL_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode C_PARAM = InstNode.COMPONENT_NODE("c", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(CLOCK_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());
constant InstNode SOLVER_METHOD_PARAM = InstNode.COMPONENT_NODE("solverMethod", NONE(),
  Visibility.PUBLIC, Pointer.createImmutable(STRING_COMPONENT), InstNode.EMPTY_NODE(), InstNodeType.NORMAL_COMP());

// Clock(intervalCounter, resolution = 1) - clock with Integer interval
constant Function CLOCK_INT = Function.FUNCTION(Path.IDENT("Clock"),
  CLOCK_DUMMY_NODE, {INT_PARAM, INT_PARAM}, {CLOCK_PARAM}, {}, {
    Slot.SLOT(INTERVAL_COUNTER_PARAM, SlotType.GENERIC, NONE(), NONE(), 1, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(RESOLUTION_PARAM, SlotType.GENERIC, SOME(Expression.INTEGER(1)), NONE(), 2, SlotEvalStatus.NOT_EVALUATED)
  }, Type.CLOCK(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
  Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

// Clock(interval) - clock with Real interval
constant Function CLOCK_REAL = Function.FUNCTION(Path.IDENT("Clock"),
  CLOCK_DUMMY_NODE, {REAL_PARAM}, {CLOCK_PARAM}, {}, {
    Slot.SLOT(INTERVAL_PARAM, SlotType.GENERIC, NONE(), NONE(), 1, SlotEvalStatus.NOT_EVALUATED)
  }, Type.CLOCK(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
  Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

// Clock(condition, startInterval = 0.0) - Event clock, triggered by zero-crossing events
constant Function CLOCK_BOOL = Function.FUNCTION(Path.IDENT("Clock"),
  CLOCK_DUMMY_NODE, {BOOL_PARAM, REAL_PARAM}, {CLOCK_PARAM}, {}, {
    Slot.SLOT(CONDITION_PARAM, SlotType.GENERIC, NONE(), NONE(), 1, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(START_INTERVAL_PARAM, SlotType.GENERIC, SOME(Expression.REAL(0.0)), NONE(), 2, SlotEvalStatus.NOT_EVALUATED)
  }, Type.CLOCK(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
  Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

// Clock(c, solverMethod) - Solver clock
constant Function CLOCK_SOLVER = Function.FUNCTION(Path.IDENT("Clock"),
  CLOCK_DUMMY_NODE, {CLOCK_PARAM, STRING_PARAM}, {CLOCK_PARAM}, {}, {
    Slot.SLOT(C_PARAM, SlotType.GENERIC, NONE(), NONE(), 1, SlotEvalStatus.NOT_EVALUATED),
    Slot.SLOT(SOLVER_METHOD_PARAM, SlotType.GENERIC, NONE(), NONE(), 2, SlotEvalStatus.NOT_EVALUATED)
  }, Type.CLOCK(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
  Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));


constant InstNode CLOCK_NODE = InstNode.CLASS_NODE("Clock",
  DUMMY_ELEMENT, Visibility.PUBLIC,
  Pointer.createImmutable(Class.PARTIAL_BUILTIN(Type.CLOCK(), ClassTree.EMPTY_TREE(),
    Modifier.NOMOD(), NFClass.DEFAULT_PREFIXES, Restriction.TYPE())),
  listArrayLiteral({
    NFInstNode.CachedData.FUNCTION({
        CLOCK_INFERRED,
        CLOCK_INT,
        CLOCK_REAL,
        CLOCK_BOOL,
        CLOCK_SOLVER
        },
      true, true),
    NFInstNode.CachedData.NO_CACHE(),
    NFInstNode.CachedData.NO_CACHE()}
  ),
  InstNode.EMPTY_NODE(), InstNodeType.BUILTIN_CLASS());

constant ComponentRef CLOCK_CREF =
  ComponentRef.CREF(CLOCK_NODE, {}, Type.INTEGER(), Origin.CREF, ComponentRef.EMPTY());

constant Function GET_PART_REAL = Function.FUNCTION(Path.IDENT("$getPart"),
  InstNode.EMPTY_NODE(), {REAL_PARAM}, {REAL_PARAM}, {}, {},
    Type.REAL(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function GET_PART_INT = Function.FUNCTION(Path.IDENT("$getPart"),
  InstNode.EMPTY_NODE(), {INT_PARAM}, {INT_PARAM}, {}, {},
    Type.INTEGER(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function GET_PART_BOOL = Function.FUNCTION(Path.IDENT("$getPart"),
  InstNode.EMPTY_NODE(), {BOOL_PARAM}, {BOOL_PARAM}, {}, {},
    Type.BOOLEAN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant Function CLOCK_FIRE = Function.FUNCTION(Path.IDENT("$_clkfire"),
  InstNode.EMPTY_NODE(), {INT_PARAM}, {}, {}, {},
    Type.UNKNOWN(), DAE.FUNCTION_ATTRIBUTES_BUILTIN, {}, {}, listArray({}),
    Pointer.createImmutable(FunctionStatus.BUILTIN), Pointer.createImmutable(0));

constant SCode.Element BASE_MODELICA_POSITIVE_MAX_SIMPLE = SCode.Element.CLASS(
  "$OMC$PositiveMax",
  SCode.defaultPrefixes,
  SCode.Encapsulated.ENCAPSULATED(),
  SCode.Partial.NOT_PARTIAL(),
  SCode.Restriction.R_FUNCTION(SCode.FunctionRestriction.FR_NORMAL_FUNCTION(Absyn.FunctionPurity.NO_PURITY())),
  SCode.ClassDef.PARTS(
    {
      // input Real flowValue;
      SCode.Element.COMPONENT(
        "flowValue",
        SCode.defaultPrefixes,
        SCode.defaultInputAttr,
        Absyn.TPATH(Absyn.IDENT("Real"), NONE()),
        SCode.Mod.NOMOD(),
        SCode.noComment,
        NONE(),
        AbsynUtil.dummyInfo
      ),
      // input Real eps;
      SCode.Element.COMPONENT(
        "eps",
        SCode.defaultPrefixes,
        SCode.defaultInputAttr,
        Absyn.TPATH(Absyn.IDENT("Real"), NONE()),
        SCode.Mod.NOMOD(),
        SCode.noComment,
        NONE(),
        AbsynUtil.dummyInfo
      ),
      // output Real positiveMax;
      SCode.Element.COMPONENT(
        "positiveMax",
        SCode.defaultPrefixes,
        SCode.defaultOutputAttr,
        Absyn.TPATH(Absyn.IDENT("Real"), NONE()),
        SCode.Mod.NOMOD(),
        SCode.noComment,
        NONE(),
        AbsynUtil.dummyInfo
      )
    },
    {}, {},
    // algorithm
    {
      SCode.AlgorithmSection.ALGORITHM({
        // positiveMax := max(flowValue, eps);
        SCode.Statement.ALG_ASSIGN(
          Absyn.Exp.CREF(Absyn.ComponentRef.CREF_IDENT("positiveMax", {})),
          Absyn.Exp.CALL(Absyn.ComponentRef.CREF_IDENT("max", {}),
            Absyn.FunctionArgs.FUNCTIONARGS({
              Absyn.Exp.CREF(Absyn.ComponentRef.CREF_IDENT("flowValue", {})),
              Absyn.Exp.CREF(Absyn.ComponentRef.CREF_IDENT("eps", {}))
            }, {}),
            {}
          ),
          SCode.noComment,
          AbsynUtil.dummyInfo
        )
      })
    },
    {}, {}, {}, NONE()
  ),
  SCode.noComment,
  AbsynUtil.dummyInfo
);

annotation(__OpenModelica_Interface="frontend");
end NFBuiltinFuncs;
