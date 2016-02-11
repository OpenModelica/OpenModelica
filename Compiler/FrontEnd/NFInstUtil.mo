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

encapsulated package NFInstUtil
" file:        NFInstUtil.mo
  package:     NFInstUtil
  description: Utility functions for NFInstTypes.


  Utility functions for operating on the types in NFInstTypes.
"

//public import Absyn;
//public import ClassInf;
public import DAE;
//public import NFInstSymbolTable;
//public import NFInstPrefix;
//public import NFInstTypes;
public import SCode;
//public import NFEnv;

//protected import ComponentReference;
//protected import Debug;
//protected import Error;
//protected import Expression;
//protected import Flags;
//protected import NFInstDump;
//protected import List;
//protected import SCodeDump;
//protected import Types;
//protected import Util;
//
//public type Binding = NFInstTypes.Binding;
//public type Class = NFInstTypes.Class;
//public type Component = NFInstTypes.Component;
//public type Condition = NFInstTypes.Condition;
//public type DaePrefixes = NFInstTypes.DaePrefixes;
//public type Dimension = NFInstTypes.Dimension;
//public type Element = NFInstTypes.Element;
//public type Env = NFEnv.Env;
//public type Equation = NFInstTypes.Equation;
//public type Function = NFInstTypes.Function;
//public type Modifier = NFInstTypes.Modifier;
//public type ParamType = NFInstTypes.ParamType;
//public type Prefixes = NFInstTypes.Prefixes;
//public type Prefix = NFInstPrefix.Prefix;
//public type Statement = NFInstTypes.Statement;
//public type SymbolTable = NFInstSymbolTable.SymbolTable;
//
//public function makeClassType
//  input Class inClass;
//  input ClassInf.State inState;
//  input Boolean inContainsSpecialExtends;
//  output Class outClass;
//  output DAE.Type outClassType;
//algorithm
//  (outClass, outClassType) := match(inClass, inState, inContainsSpecialExtends)
//    local
//      list<Element> elems;
//      Class cls;
//      DAE.Type ty;
//      list<DAE.Var> vars;
//
//    case (NFInstTypes.COMPLEX_CLASS(components = elems), _, false)
//      equation
//        vars = List.accumulateMapReverse(elems, makeDaeVarsFromElement);
//        ty = DAE.T_COMPLEX(inState, vars, NONE(), DAE.emptyTypeSource);
//      then
//        (inClass, ty);
//
//    case (NFInstTypes.COMPLEX_CLASS(_, elems, {}, {}, {}, {}), _, true)
//      equation
//        (NFInstTypes.EXTENDED_ELEMENTS(cls = cls, ty = ty), elems) =
//          getSpecialExtends(elems);
//      then
//        (cls, ty);
//
//  end match;
//end makeClassType;
//
//public function makeDaeVarsFromElement
//  input Element inElement;
//  input list<DAE.Var> inAccumVars;
//  output list<DAE.Var> outVars;
//algorithm
//  outVars := match(inElement, inAccumVars)
//    local
//      Component comp;
//      Class cls;
//      list<DAE.Var> vars;
//      DAE.Var var;
//
//    case (NFInstTypes.ELEMENT(component = comp), vars)
//      equation
//        var = componentToDaeVar(comp);
//      then
//        var :: vars;
//
//    case (NFInstTypes.CONDITIONAL_ELEMENT(component = comp), vars)
//      equation
//        var = componentToDaeVar(comp);
//      then
//        var :: vars;
//
//  end match;
//end makeDaeVarsFromElement;
//
//protected function componentToDaeVar
//  input Component inComponent;
//  output DAE.Var outVar;
//algorithm
//  outVar := match(inComponent)
//    local
//      Absyn.Path path;
//      DAE.Type ty;
//      String name;
//      DAE.Attributes attr;
//      Prefixes prefs;
//      DaePrefixes dprefs;
//
//    case NFInstTypes.UNTYPED_COMPONENT(name = path, prefixes = prefs)
//      equation
//        name = Absyn.pathLastIdent(path);
//        attr = prefixesToDaeAttr(prefs);
//      then
//        DAE.TYPES_VAR(name, attr, DAE.T_UNKNOWN_DEFAULT, DAE.UNBOUND(), NONE());
//
//    case NFInstTypes.TYPED_COMPONENT(name = path, ty = ty, prefixes = dprefs)
//      equation
//        name = Absyn.pathLastIdent(path);
//        attr = daePrefixesToDaeAttr(dprefs);
//      then
//        DAE.TYPES_VAR(name, attr, ty, DAE.UNBOUND(), NONE());
//
//    case NFInstTypes.CONDITIONAL_COMPONENT(name = path)
//      equation
//        name = Absyn.pathLastIdent(path);
//      then
//        DAE.TYPES_VAR(name, DAE.dummyAttrVar, DAE.T_UNKNOWN_DEFAULT,
//          DAE.UNBOUND(), NONE());
//
//    case NFInstTypes.OUTER_COMPONENT(name = path)
//      equation
//        name = Absyn.pathLastIdent(path);
//      then
//        DAE.TYPES_VAR(name, DAE.dummyAttrVar, DAE.T_UNKNOWN_DEFAULT,
//          DAE.UNBOUND(), NONE());
//
//    case NFInstTypes.COMPONENT_ALIAS()
//      equation
//        print("Got component alias in componentToDaeVar\n");
//      then
//        fail();
//
//    case NFInstTypes.DELETED_COMPONENT()
//      equation
//        print("Got deleted component\n");
//      then
//        fail();
//
//  end match;
//end componentToDaeVar;
//
//protected function prefixesToDaeAttr
//  input Prefixes inPrefixes;
//  output DAE.Attributes outAttr;
//algorithm
//  outAttr := match(inPrefixes)
//    local
//      SCode.ConnectorType cty;
//      SCode.Variability var;
//      Absyn.Direction dir;
//      Absyn.InnerOuter io;
//      SCode.Visibility vis;
//
//    case NFInstTypes.NO_PREFIXES() then DAE.dummyAttrVar;
//    case NFInstTypes.PREFIXES(vis, var, _, io, (dir, _), (cty, _), _)
//      then DAE.ATTR(cty, SCode.NON_PARALLEL(), var, dir, io, vis);
//
//  end match;
//end prefixesToDaeAttr;
//
//protected function daePrefixesToDaeAttr
//  input DaePrefixes inPrefixes;
//  output DAE.Attributes outAttr;
//algorithm
//  outAttr := match(inPrefixes)
//    local
//      DAE.VarVisibility dvis;
//      DAE.VarKind dvar;
//      DAE.VarDirection ddir;
//      DAE.ConnectorType dcty;
//      SCode.ConnectorType cty;
//      SCode.Variability var;
//      Absyn.Direction dir;
//      Absyn.InnerOuter io;
//      SCode.Visibility vis;
//
//    case NFInstTypes.NO_DAE_PREFIXES() then DAE.dummyAttrVar;
//    case NFInstTypes.DAE_PREFIXES(dvis, dvar, _, io, ddir, dcty)
//      equation
//        vis = daeToSCodeVisibility(dvis);
//        var = daeToSCodeVariability(dvar);
//        dir = daeToAbsynDirection(ddir);
//        cty = daeToSCodeConnectorType(dcty);
//      then
//        DAE.ATTR(cty, SCode.NON_PARALLEL(), var, dir, io, vis);
//
//  end match;
//end daePrefixesToDaeAttr;
//
//public function daeToSCodeVisibility
//  input DAE.VarVisibility inVisibility;
//  output SCode.Visibility outVisibility;
//algorithm
//  outVisibility := match(inVisibility)
//    case DAE.PUBLIC() then SCode.PUBLIC();
//    case DAE.PROTECTED() then SCode.PROTECTED();
//  end match;
//end daeToSCodeVisibility;
//
//public function daeToSCodeVariability
//  input DAE.VarKind inVariability;
//  output SCode.Variability outVariability;
//algorithm
//  outVariability := match(inVariability)
//    case DAE.VARIABLE() then SCode.VAR();
//    case DAE.DISCRETE() then SCode.DISCRETE();
//    case DAE.PARAM() then SCode.PARAM();
//    case DAE.CONST() then SCode.CONST();
//  end match;
//end daeToSCodeVariability;
//
//public function daeToAbsynDirection
//  input DAE.VarDirection inDirection;
//  output Absyn.Direction outDirection;
//algorithm
//  outDirection := match(inDirection)
//    case DAE.BIDIR() then Absyn.BIDIR();
//    case DAE.INPUT() then Absyn.INPUT();
//    case DAE.OUTPUT() then Absyn.OUTPUT();
//  end match;
//end daeToAbsynDirection;
//
//protected function daeToSCodeConnectorType
//  input DAE.ConnectorType inConnectorType;
//  output SCode.ConnectorType outConnectorType;
//algorithm
//  outConnectorType := match(inConnectorType)
//    case DAE.NON_CONNECTOR() then SCode.POTENTIAL();
//    case DAE.POTENTIAL() then SCode.POTENTIAL();
//    case DAE.FLOW() then SCode.FLOW();
//    case DAE.STREAM() then SCode.STREAM();
//  end match;
//end daeToSCodeConnectorType;
//
//public function makeDerivedClassType
//  input DAE.Type inType;
//  input ClassInf.State inState;
//  output DAE.Type outType;
//algorithm
//  outType := match(inType, inState)
//    local
//      list<DAE.Var> vars;
//      DAE.EqualityConstraint ec;
//      DAE.TypeSource src;
//
//    // TODO: Check type restrictions.
//    case (DAE.T_COMPLEX(_, vars, ec, src), _)
//      then DAE.T_COMPLEX(inState, vars, ec, src);
//
//    else DAE.T_SUBTYPE_BASIC(inState, {}, inType, NONE(), DAE.emptyTypeSource);
//
//  end match;
//end makeDerivedClassType;
//
//public function arrayElementType
//  input DAE.Type inType;
//  output DAE.Type outType;
//algorithm
//  outType := match(inType)
//    local
//      DAE.Type ty;
//      ClassInf.State state;
//      DAE.EqualityConstraint ec;
//      DAE.TypeSource src;
//
//    case DAE.T_ARRAY(ty = ty) then arrayElementType(ty);
//    case DAE.T_SUBTYPE_BASIC(state, _, ty, ec, src)
//      equation
//        ty = arrayElementType(ty);
//      then
//        DAE.T_SUBTYPE_BASIC(state, {}, ty, ec, src);
//
//    else inType;
//  end match;
//end arrayElementType;
//
//public function addElementsToClass
//  input list<Element> inElements;
//  input Class inClass;
//  output Class outClass;
//algorithm
//  outClass := match(inElements, inClass)
//    local
//      list<Element> el;
//      list<Equation> eq, ieq;
//      list<list<Statement>> al, ial;
//      Absyn.Path name;
//
//    case ({}, _) then inClass;
//
//    case (_, NFInstTypes.COMPLEX_CLASS(name, el, eq, ieq, al, ial))
//      equation
//        el = listAppend(inElements, el);
//      then
//        NFInstTypes.COMPLEX_CLASS(name, el, eq, ieq, al, ial);
//
//    case (_, NFInstTypes.BASIC_TYPE(_))
//      equation
//        Error.addMessage(Error.INTERNAL_ERROR,
//          {"NFSCodeInst.addElementsToClass: Can't add elements to basic type.\n"});
//      then
//        fail();
//
//  end match;
//end addElementsToClass;
//
//public function getElementComponent
//  input Element inElement;
//  output Component outComponent;
//algorithm
//  outComponent := match(inElement)
//    local
//      Component comp;
//
//    case NFInstTypes.ELEMENT(component = comp) then comp;
//    case NFInstTypes.CONDITIONAL_ELEMENT(component = comp) then comp;
//
//  end match;
//end getElementComponent;
//
//public function getComponentName
//  input Component inComponent;
//  output Absyn.Path outName;
//algorithm
//  outName := match(inComponent)
//    local
//      Absyn.Path name;
//
//    case NFInstTypes.UNTYPED_COMPONENT(name = name) then name;
//    case NFInstTypes.TYPED_COMPONENT(name = name) then name;
//    case NFInstTypes.CONDITIONAL_COMPONENT(name = name) then name;
//    case NFInstTypes.DELETED_COMPONENT(name = name) then name;
//    case NFInstTypes.OUTER_COMPONENT(name = name) then name;
//
//  end match;
//end getComponentName;
//
//public function setComponentName
//  input Component inComponent;
//  input Absyn.Path inName;
//  output Component outComponent;
//algorithm
//  outComponent := match(inComponent, inName)
//    local
//      DAE.Type ty;
//      array<Dimension> dims;
//      Prefixes prefs;
//      DaePrefixes dprefs;
//      ParamType pty;
//      Binding binding;
//      SourceInfo info;
//      SCode.Element elem;
//      Modifier mod;
//      Env env;
//      Prefix prefix;
//      Option<Absyn.Path> inner_name;
//      DAE.Exp cond;
//      Option<Component> p;
//
//    case (NFInstTypes.UNTYPED_COMPONENT(_, ty, dims, prefs, pty, binding, info), _)
//      then NFInstTypes.UNTYPED_COMPONENT(inName, ty, dims, prefs, pty, binding, info);
//
//    case (NFInstTypes.TYPED_COMPONENT(_, ty, p, dprefs, binding, info), _)
//      then NFInstTypes.TYPED_COMPONENT(inName, ty, p, dprefs, binding, info);
//
//    case (NFInstTypes.CONDITIONAL_COMPONENT(_, cond, elem, mod, prefs, env, prefix, info), _)
//      then NFInstTypes.CONDITIONAL_COMPONENT(inName, cond, elem, mod, prefs, env, prefix, info);
//
//    case (NFInstTypes.DELETED_COMPONENT(_), _)
//      then NFInstTypes.DELETED_COMPONENT(inName);
//
//    case (NFInstTypes.OUTER_COMPONENT(_, inner_name), _)
//      then NFInstTypes.OUTER_COMPONENT(inName, inner_name);
//
//  end match;
//end setComponentName;
//
//public function setTypedComponentType
//  input Component inComponent;
//  input DAE.Type inType;
//  output Component outComponent;
//algorithm
//  outComponent := match(inComponent, inType)
//    local
//      Absyn.Path name;
//      DaePrefixes dprefs;
//      Binding binding;
//      SourceInfo info;
//      Option<Component> p;
//
//    case (NFInstTypes.TYPED_COMPONENT(name, _, p, dprefs, binding, info), _)
//      then NFInstTypes.TYPED_COMPONENT(name, inType, p, dprefs, binding, info);
//
//    else inComponent;
//
//  end match;
//end setTypedComponentType;
//
//public function setComponentParamType
//  input Component inComponent;
//  input ParamType inParamType;
//  output Component outComponent;
//algorithm
//  outComponent := match(inComponent, inParamType)
//    local
//      Absyn.Path name;
//      DAE.Type ty;
//      array<Dimension> dims;
//      Prefixes prefs;
//      Binding binding;
//      SourceInfo info;
//
//    case (NFInstTypes.UNTYPED_COMPONENT(name, ty, dims, prefs, _, binding, info), _)
//      then NFInstTypes.UNTYPED_COMPONENT(name, ty, dims, prefs, inParamType, binding, info);
//
//    else inComponent;
//
//  end match;
//end setComponentParamType;
//
//public function getComponentType
//  input Component inComponent;
//  output DAE.Type outType;
//algorithm
//  outType := match(inComponent)
//    local
//      DAE.Type ty;
//
//    case NFInstTypes.UNTYPED_COMPONENT(baseType = ty) then ty;
//    case NFInstTypes.TYPED_COMPONENT(ty = ty) then ty;
//
//  end match;
//end getComponentType;
//
//public function getElementComponentType
//  input Element inElement;
//  output DAE.Type outType;
//algorithm
//  outType := match(inElement)
//    local
//      DAE.Type ty;
//
//    case NFInstTypes.ELEMENT(NFInstTypes.TYPED_COMPONENT(ty = ty),_) then ty;
//    case NFInstTypes.ELEMENT(_, _)
//      equation
//        Error.addMessage(Error.INTERNAL_ERROR,
//          {"NFInstUtil.getElementComponentType: Expected element with TYPED_COMPONENT \n"});
//      then
//        fail();
//    else
//      equation
//        Error.addMessage(Error.INTERNAL_ERROR,
//          {"NFInstUtil.getElementComponentType: Expected ELEMENT. found either conditional or extended element \n"});
//      then
//        fail();
//
//  end match;
//end getElementComponentType;
//
//public function getComponentTypeDimensions
//  input Component inComponent;
//  output DAE.Dimensions outDims;
//algorithm
//  outDims := match(inComponent)
//    local
//      DAE.Type ty;
//      DAE.Dimensions dims;
//
//    case NFInstTypes.TYPED_COMPONENT(ty = ty)
//      equation
//        dims = Types.getDimensions(ty);
//      then dims;
//  end match;
//end getComponentTypeDimensions;
//
//public function getComponentBinding
//  input Component inComponent;
//  output Binding outBinding;
//algorithm
//  outBinding := match(inComponent)
//    local
//      Binding binding;
//
//    case NFInstTypes.UNTYPED_COMPONENT(binding = binding) then binding;
//    case NFInstTypes.TYPED_COMPONENT(binding = binding) then binding;
//
//  end match;
//end getComponentBinding;
//
//public function getComponentBindingExp
//  input Component inComponent;
//  output DAE.Exp outExp;
//algorithm
//  NFInstTypes.TYPED_COMPONENT(binding =
//    NFInstTypes.TYPED_BINDING(bindingExp = outExp)) := inComponent;
//end getComponentBindingExp;
//
//public function getComponentVariability
//  input Component inComponent;
//  output SCode.Variability outVariability;
//algorithm
//  outVariability := match(inComponent)
//    local
//      SCode.Variability var;
//
//    case NFInstTypes.UNTYPED_COMPONENT(prefixes =
//      NFInstTypes.PREFIXES(variability = var)) then var;
//
//    case NFInstTypes.TYPED_COMPONENT(prefixes =
//      NFInstTypes.DAE_PREFIXES(variability = DAE.CONST())) then SCode.CONST();
//
//    case NFInstTypes.TYPED_COMPONENT(prefixes =
//      NFInstTypes.DAE_PREFIXES(variability = DAE.PARAM())) then SCode.PARAM();
//
//    else SCode.VAR();
//
//  end match;
//end getComponentVariability;
//
//public function getEffectiveComponentVariability
//  input Component inComponent;
//  output SCode.Variability outVariability;
//algorithm
//  outVariability := match(inComponent)
//    case NFInstTypes.UNTYPED_COMPONENT(paramType = NFInstTypes.STRUCT_PARAM())
//      then SCode.CONST();
//
//    else getComponentVariability(inComponent);
//
//  end match;
//end getEffectiveComponentVariability;
//
//public function getComponentConnectorType
//  input Component inComponent;
//  output DAE.ConnectorType outConnectorType;
//algorithm
//  outConnectorType := match(inComponent)
//    local
//      DAE.ConnectorType cty;
//
//    case NFInstTypes.TYPED_COMPONENT(prefixes =
//      NFInstTypes.DAE_PREFIXES(connectorType = cty)) then cty;
//
//    else DAE.POTENTIAL();
//
//  end match;
//end getComponentConnectorType;
//
//protected function getSpecialExtends
//  input list<Element> inElements;
//  output Element outSpecialExtends;
//  output list<Element> outRestElements;
//algorithm
//  (outSpecialExtends, outRestElements) := getSpecialExtends2(inElements, {});
//end getSpecialExtends;
//
//protected function getSpecialExtends2
//  input list<Element> inElements;
//  input list<Element> inAccumEl;
//  output Element outSpecialExtends;
//  output list<Element> outRestElements;
//algorithm
//  (outSpecialExtends, outRestElements) := matchcontinue(inElements, inAccumEl)
//    local
//      Element el;
//      list<Element> rest_el;
//      DAE.Type ty;
//
//    case ((el as NFInstTypes.EXTENDED_ELEMENTS(ty = ty)) :: rest_el, _)
//      equation
//        true = isSpecialExtends(ty);
//        rest_el = listAppend(listReverse(inAccumEl), rest_el);
//      then
//        (el, rest_el);
//
//    // TODO: Check for illegal elements here (components, etc.).
//
//    case (el :: rest_el, _)
//      equation
//        (el, rest_el) = getSpecialExtends2(rest_el, el :: inAccumEl);
//      then
//        (el, rest_el);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFSCodeInst.getSpecialExtends2 failed!");
//      then
//        fail();
//
//  end matchcontinue;
//end getSpecialExtends2;
//
//public function isSpecialExtends
//  input DAE.Type inType;
//  output Boolean outResult;
//algorithm
//  outResult := match(inType)
//    case DAE.T_COMPLEX() then false;
//    else true;
//  end match;
//end isSpecialExtends;
//
//public function getComponentBindingDimension
//  input Component inComponent;
//  input Integer inDimension;
//  input Integer inCompDimensions;
//  output DAE.Dimension outDimension;
//protected
//  Binding binding;
//algorithm
//  binding := getComponentBinding(inComponent);
//  outDimension := getBindingDimension(binding, inDimension, inCompDimensions);
//end getComponentBindingDimension;
//
//public function getBindingDimension
//  input Binding inBinding;
//  input Integer inDimension;
//  input Integer inCompDimensions;
//  output DAE.Dimension outDimension;
//algorithm
//  outDimension := match(inBinding, inDimension, inCompDimensions)
//    local
//      DAE.Exp exp;
//      Integer pd, index;
//
//    case (NFInstTypes.TYPED_BINDING(bindingExp = exp, propagatedDims = pd), _, _)
//      equation
//        index = if intEq(pd, -1) then inDimension else (inDimension + pd - inCompDimensions);
//      then
//        getExpDimension(exp, index);
//
//  end match;
//end getBindingDimension;
//
//public function getExpDimension
//  input DAE.Exp inExp;
//  input Integer inDimIndex;
//  output DAE.Dimension outDimension;
//algorithm
//  outDimension := matchcontinue(inExp, inDimIndex)
//    local
//      DAE.Type ty;
//      list<DAE.Dimension> dims;
//      DAE.Dimension dim;
//
//    case (_, _)
//      equation
//        ty = Expression.typeof(inExp);
//        dims = Types.getDimensions(ty);
//        dim = listGet(dims, inDimIndex);
//      then
//        dim;
//
//    // TODO: Error on index out of bounds!
//
//    else DAE.DIM_UNKNOWN();
//
//  end matchcontinue;
//end getExpDimension;
//
//public function getBindingExp
//  input Binding inBinding;
//  output DAE.Exp outExp;
//algorithm
//  outExp := match(inBinding)
//    local
//      DAE.Exp exp;
//
//    case NFInstTypes.TYPED_BINDING(bindingExp = exp) then exp;
//    else DAE.ICONST(0);
//  end match;
//end getBindingExp;
//
//public function getBindingExpOpt
//  input Binding inBinding;
//  output Option<DAE.Exp> outExp;
//algorithm
//  outExp := match(inBinding)
//    local
//      DAE.Exp exp;
//
//    case NFInstTypes.UNTYPED_BINDING(bindingExp = exp) then SOME(exp);
//    case NFInstTypes.TYPED_BINDING(bindingExp = exp) then SOME(exp);
//    else NONE();
//
//  end match;
//end getBindingExpOpt;
//
//public function getBindingTypeOpt
//  input Binding inBinding;
//  output Option<DAE.Type> outTy;
//algorithm
//  outTy := match(inBinding)
//    local
//      DAE.Type ty;
//
//    case NFInstTypes.TYPED_BINDING(bindingType = ty) then SOME(ty);
//    else NONE();
//
//  end match;
//end getBindingTypeOpt;
//
//public function getBindingPropagatedDimsOpt
//  input Binding inBinding;
//  output Option<Integer> outPropagatedDimsOpt;
//algorithm
//  outPropagatedDimsOpt := match(inBinding)
//    local
//      Integer pd;
//
//    case NFInstTypes.TYPED_BINDING(propagatedDims = pd) then SOME(pd);
//    case NFInstTypes.RAW_BINDING(propagatedDims = pd) then SOME(pd);
//    case NFInstTypes.UNTYPED_BINDING(propagatedDims = pd) then SOME(pd);
//    else NONE();
//
//  end match;
//end getBindingPropagatedDimsOpt;
//
//public function makeEnumType
//  input list<SCode.Enum> inEnumLiterals;
//  input Absyn.Path inEnumPath;
//  output DAE.Type outType;
//protected
//  list<String> names;
//algorithm
//  names := List.map(inEnumLiterals, SCode.enumName);
//  outType := DAE.T_ENUMERATION(NONE(), inEnumPath, names, {}, {}, DAE.emptyTypeSource);
//end makeEnumType;
//
//public function makeEnumLiteralComp
//  input Absyn.Path inName;
//  input DAE.Type inType;
//  input Integer inIndex;
//  output Component outComponent;
//protected
//  Binding binding;
//algorithm
//  binding := NFInstTypes.TYPED_BINDING(DAE.ENUM_LITERAL(inName, inIndex), inType,
//    0, Absyn.dummyInfo);
//  outComponent := NFInstTypes.TYPED_COMPONENT(inName, inType, NONE(),
//    NFInstTypes.DEFAULT_CONST_DAE_PREFIXES, binding, Absyn.dummyInfo);
//end makeEnumLiteralComp;
//
//public function makeDimension
//  input DAE.Exp inExp;
//  output DAE.Dimension outDimension;
//algorithm
//  outDimension := matchcontinue(inExp)
//    local
//      Integer idim;
//      DAE.Type ty;
//      Absyn.Path path;
//      list<String> enum_lits;
//      Integer dim_size;
//
//    case DAE.ICONST(idim) then DAE.DIM_INTEGER(idim);
//
//    case DAE.ARRAY(ty = DAE.T_ARRAY(ty =
//        DAE.T_ENUMERATION(index = NONE(), path = path, names = enum_lits),
//        dims = {DAE.DIM_INTEGER(dim_size)}))
//      then
//        DAE.DIM_ENUM(path, enum_lits, dim_size);
//
//    case DAE.CREF(ty = ty)
//      equation
//        DAE.T_ENUMERATION(path = path, names = enum_lits) =
//          Types.derivedBasicType(ty);
//        dim_size = listLength(enum_lits);
//      then
//        DAE.DIM_ENUM(path, enum_lits, dim_size);
//
//    else DAE.DIM_EXP(inExp);
//  end matchcontinue;
//end makeDimension;
//
//public function makeDimensionArray
//  input list<DAE.Dimension> inDimensions;
//  output array<Dimension> outDimensions;
//protected
//  list<Dimension> dims;
//algorithm
//  dims := List.map(inDimensions, wrapDimension);
//  outDimensions := listArray(dims);
//end makeDimensionArray;
//
//public function wrapDimension
//  input DAE.Dimension inDimension;
//  output Dimension outDimension;
//algorithm
//  outDimension := NFInstTypes.UNTYPED_DIMENSION(inDimension, false);
//end wrapDimension;
//
//public function wrapTypedDimension
//  input DAE.Dimension inDimension;
//  output Dimension outDimension;
//algorithm
//  outDimension := NFInstTypes.TYPED_DIMENSION(inDimension);
//end wrapTypedDimension;
//
//public function unwrapDimension
//  input Dimension inDimension;
//  output DAE.Dimension outDimension;
//algorithm
//  outDimension := match inDimension
//    local
//      DAE.Dimension dim;
//    case NFInstTypes.UNTYPED_DIMENSION(dimension=dim) then dim;
//    case NFInstTypes.TYPED_DIMENSION(dimension=dim) then dim;
//  end match;
//end unwrapDimension;
//
//public function makeIterator
//  input Absyn.Path inName;
//  input DAE.Type inType;
//  input SourceInfo inInfo;
//  output Component outIterator;
//algorithm
//  outIterator := NFInstTypes.TYPED_COMPONENT(inName, inType, NONE(),
//    NFInstTypes.NO_DAE_PREFIXES(), NFInstTypes.UNBOUND(), inInfo);
//end makeIterator;
//
//public function mergePrefixesFromComponent
//  "Merges a component's prefixes with the given prefixes, with the component's
//   prefixes having priority."
//  input Absyn.Path inComponentName;
//  input SCode.Element inComponent;
//  input Prefixes inPrefixes;
//  output Prefixes outPrefixes;
//algorithm
//  outPrefixes := match(inComponentName, inComponent, inPrefixes)
//    local
//      SCode.Prefixes pf;
//      SCode.Attributes attr;
//      Prefixes prefs;
//      SourceInfo info;
//      SCode.Comment comment;
//      String err_str;
//
//    case (_, SCode.COMPONENT(prefixes = pf, attributes = attr, comment = comment, info = info), _)
//      equation
//        prefs = makePrefixes(pf, attr, comment, info);
//        prefs = mergePrefixes(prefs, inPrefixes, inComponentName, "variable");
//      then
//        prefs;
//
//    else
//      equation
//        err_str = Absyn.pathString(inComponentName);
//        err_str = "NFInstUtil.mergePrefixesFromComponent got " + err_str +
//          " which is not a component!";
//        Error.addMessage(Error.INTERNAL_ERROR, {err_str});
//      then
//        fail();
//
//  end match;
//end mergePrefixesFromComponent;
//
//protected function makePrefixes
//  "Creates an NFInstTypes.Prefixes record from SCode.Prefixes and SCode.Attributes."
//  input SCode.Prefixes inPrefixes;
//  input SCode.Attributes inAttributes;
//  input SCode.Comment inComment;
//  input SourceInfo inInfo;
//  output Prefixes outPrefixes;
//algorithm
//  outPrefixes := match(inPrefixes, inAttributes, inComment, inInfo)
//    local
//      SCode.Visibility vis;
//      SCode.Variability var;
//      SCode.Final fp;
//      Absyn.InnerOuter io;
//      Absyn.Direction dir;
//      SCode.ConnectorType ct;
//      SourceInfo info;
//      NFInstTypes.VarArgs va;
//
//    // All prefixes are the default ones, same as having no prefixes.
//    case (SCode.PREFIXES(visibility = SCode.PUBLIC(), finalPrefix =
//        SCode.NOT_FINAL(), innerOuter = Absyn.NOT_INNER_OUTER()), SCode.ATTR(
//        connectorType = SCode.POTENTIAL(), variability = SCode.VAR(),
//        direction = Absyn.BIDIR()), _, _)
//      then NFInstTypes.NO_PREFIXES();
//
//    // Otherwise, select the prefixes we are interested in and build a PREFIXES
//    // record.
//    case (SCode.PREFIXES(visibility = vis, finalPrefix = fp, innerOuter = io),
//          SCode.ATTR(connectorType = ct, variability = var, direction = dir), _, info)
//      equation
//        va = makeVarArg(dir,inComment);
//      then NFInstTypes.PREFIXES(vis, var, fp, io, (dir, info), (ct, info), va);
//
//  end match;
//end makePrefixes;
//
//protected function makeVarArg "Checks if the component might be a varargs type of component"
//  input Absyn.Direction inDir;
//  input SCode.Comment inComment;
//  output NFInstTypes.VarArgs varArgs;
//algorithm
//  varArgs := match (inDir,inComment)
//    case (Absyn.INPUT(),_)
//      then
//        if SCode.optCommentHasBooleanNamedAnnotation(SOME(inComment),"__OpenModelica_varArgs") then NFInstTypes.IS_VARARG() else NFInstTypes.NO_VARARG();
//      else NFInstTypes.NO_VARARG();
//  end match;
//end makeVarArg;
//
//public function mergePrefixesWithDerivedClass
//  "Merges the attributes of a derived class with the given prefixes."
//  input Absyn.Path inClassName;
//  input SCode.Element inClass;
//  input Prefixes inPrefixes;
//  output Prefixes outPrefixes;
//algorithm
//  outPrefixes := match(inClassName, inClass, inPrefixes)
//    local
//      SCode.Attributes attr;
//      SourceInfo info;
//      Prefixes prefs;
//
//    case (_, SCode.CLASS(classDef = SCode.DERIVED(attributes = attr), info = info), _)
//      equation
//        prefs = makePrefixesFromAttributes(attr, info);
//        prefs = mergePrefixes(prefs, inPrefixes, inClassName, "class");
//      then
//        prefs;
//
//  end match;
//end mergePrefixesWithDerivedClass;
//
//protected function makePrefixesFromAttributes
//  "Creates an NFInstTypes.Prefixes record from an SCode.Attributes."
//  input SCode.Attributes inAttributes;
//  input SourceInfo inInfo;
//  output Prefixes outPrefixes;
//algorithm
//  outPrefixes := match(inAttributes, inInfo)
//    local
//      SCode.ConnectorType ct;
//      SCode.Variability var;
//      Absyn.Direction dir;
//
//    // All attributes are the default ones, same as having no prefixes.
//    case (SCode.ATTR(connectorType = SCode.POTENTIAL(), variability = SCode.VAR(),
//        direction = Absyn.BIDIR()), _)
//      then NFInstTypes.NO_PREFIXES();
//
//    // Otherwise, select the attributes we are interested in and build a
//    // PREFIXES record with the parts not covered by SCode.Attributes set to the
//    // default values.
//    case (SCode.ATTR(connectorType = ct, variability = var, direction = dir), _)
//      then NFInstTypes.PREFIXES(SCode.PUBLIC(), var, SCode.NOT_FINAL(),
//        Absyn.NOT_INNER_OUTER(), (dir, inInfo), (ct, inInfo), NFInstTypes.NO_VARARG());
//
//  end match;
//end makePrefixesFromAttributes;
//
//public function mergePrefixes
//  "Merges two NFInstTypes.Prefixes records, with the outer having priority over
//   the inner. inElementName and inElementType are used for error reporting, where
//   inElementName is the name of the element that the outer prefixes comes from
//   and inElementType the type of that element as a string (variable or class)."
//  input Prefixes inOuterPrefixes;
//  input Prefixes inInnerPrefixes;
//  input Absyn.Path inElementName;
//  input String inElementType;
//  output Prefixes outPrefixes;
//algorithm
//  outPrefixes :=
//  match(inOuterPrefixes, inInnerPrefixes, inElementName, inElementType)
//    local
//      SCode.Visibility vis1, vis2;
//      SCode.Variability var1, var2;
//      SCode.Final fp1, fp2;
//      Absyn.InnerOuter io1, io2;
//      tuple<Absyn.Direction, SourceInfo> dir1, dir2;
//      tuple<SCode.ConnectorType, SourceInfo> ct1, ct2;
//      NFInstTypes.VarArgs va2;
//
//    // No outer prefixes => no change.
//    case (NFInstTypes.NO_PREFIXES(), _, _, _) then inInnerPrefixes;
//    // No inner prefixes => overwrite with outer prefixes.
//    case (_, NFInstTypes.NO_PREFIXES(), _, _) then inOuterPrefixes;
//
//    // Both outer and inner prefixes => merge them.
//    case (NFInstTypes.PREFIXES(vis1, var1, fp1, io1, dir1, ct1, _),
//          NFInstTypes.PREFIXES(vis2, var2, fp2, _, dir2, ct2, va2), _, _)
//      equation
//        vis2 = mergeVisibility(vis1, vis2);
//        var2 = mergeVariability(var1, var2);
//        fp2 = mergeFinal(fp1, fp2);
//        dir2 = mergeDirection(dir1, dir2, inElementName, inElementType);
//        ct2 = mergeConnectorType(ct1, ct2, inElementName, inElementType);
//      then
//        NFInstTypes.PREFIXES(vis2, var2, fp2, io1, dir2, ct2, va2);
//
//  end match;
//end mergePrefixes;
//
//public function mergePrefixesFromExtends
//  input SCode.Element inExtends;
//  input Prefixes inPrefixes;
//  output Prefixes outPrefixes;
//protected
//  SCode.Visibility vis;
//algorithm
//  SCode.EXTENDS(visibility = vis) := inExtends;
//  outPrefixes := setPrefixVisibility(vis, inPrefixes);
//end mergePrefixesFromExtends;
//
//protected function setPrefixVisibility
//  input SCode.Visibility inVisibility;
//  input Prefixes inPrefixes;
//  output Prefixes outPrefixes;
//algorithm
//  outPrefixes := match(inVisibility, inPrefixes)
//    local
//      SCode.Variability var;
//      SCode.Final fp;
//      Absyn.InnerOuter io;
//      tuple<Absyn.Direction, SourceInfo> dir;
//      tuple<SCode.ConnectorType, SourceInfo> ct;
//      NFInstTypes.VarArgs va;
//
//    case (SCode.PUBLIC(), _) then inPrefixes;
//
//    case (_, NFInstTypes.PREFIXES(_, var, fp, io, dir, ct, va))
//      then NFInstTypes.PREFIXES(inVisibility, var, fp, io, dir, ct, va);
//
//    else NFInstTypes.DEFAULT_PROTECTED_PREFIXES;
//
//  end match;
//end setPrefixVisibility;
//
//protected function mergeVisibility
//  "Merges an outer and inner visibility prefix."
//  input SCode.Visibility inOuterVisibility;
//  input SCode.Visibility inInnerVisibility;
//  output SCode.Visibility outVisibility;
//algorithm
//  outVisibility := match(inOuterVisibility, inInnerVisibility)
//    // If the outer is protected, return protected.
//    case (SCode.PROTECTED(), _) then inOuterVisibility;
//    // Otherwise, no change.
//    else inInnerVisibility;
//  end match;
//end mergeVisibility;
//
//protected function mergeVariability
//  "Merges an outer and inner variability prefix. The most restrictive
//   variability is returned (with constant most restrictive, variable least)."
//  input SCode.Variability inOuterVariability;
//  input SCode.Variability inInnerVariability;
//  output SCode.Variability outVariability;
//algorithm
//  outVariability := match(inOuterVariability, inInnerVariability)
//    case (SCode.CONST(), _) then inOuterVariability;
//    case (_, SCode.CONST()) then inInnerVariability;
//    case (SCode.PARAM(), _) then inOuterVariability;
//    case (_, SCode.PARAM()) then inInnerVariability;
//    case (SCode.DISCRETE(), _) then inOuterVariability;
//    case (_, SCode.DISCRETE()) then inInnerVariability;
//    else inInnerVariability;
//  end match;
//end mergeVariability;
//
//protected function mergeFinal
//  "Merges an outer and inner final prefix."
//  input SCode.Final inOuterFinal;
//  input SCode.Final inInnerFinal;
//  output SCode.Final outFinal;
//algorithm
//  outFinal := match(inOuterFinal, inInnerFinal)
//    // If the outer prefix is final, return final.
//    case (SCode.FINAL(), _) then inOuterFinal;
//    // Otherwise, no change.
//    else inInnerFinal;
//  end match;
//end mergeFinal;
//
//protected function mergeDirection
//  "Merges an outer and inner direction prefix."
//  input tuple<Absyn.Direction, SourceInfo> inOuterDirection;
//  input tuple<Absyn.Direction, SourceInfo> inInnerDirection;
//  input Absyn.Path inElementName;
//  input String inElementType;
//  output tuple<Absyn.Direction, SourceInfo> outDirection;
//algorithm
//  outDirection :=
//  match(inOuterDirection, inInnerDirection, inElementName, inElementType)
//    local
//      Absyn.Direction dir1, dir2;
//      SourceInfo info1, info2;
//      String dir_str1, dir_str2, el_name;
//
//    // If either prefix is unset, return the other.
//    case (_, (Absyn.BIDIR(), _), _, _) then inOuterDirection;
//    case ((Absyn.BIDIR(), _), _, _, _) then inInnerDirection;
//
//    // we need this for now, see i.e. Modelica.Blocks.Math.Add3
//    case ((Absyn.INPUT(), _), (Absyn.INPUT(), _),  _, _) then inInnerDirection;
//    case ((Absyn.OUTPUT(), _), (Absyn.OUTPUT(), _),  _, _) then inInnerDirection;
//
//    // Otherwise we have an error, since it's not allowed to overwrite
//    // input/output prefixes.
//    case ((dir1, info1), (dir2, info2), _, _)
//      equation
//        dir_str1 = directionString(dir1);
//        dir_str2 = directionString(dir2);
//        el_name = Absyn.pathString(inElementName);
//        Error.addMultiSourceMessage(Error.INVALID_TYPE_PREFIX,
//          {dir_str1, inElementType, el_name, dir_str2}, {info2, info1});
//      then
//        fail();
//
//  end match;
//end mergeDirection;
//
//protected function directionString
//  input Absyn.Direction inDirection;
//  output String outString;
//algorithm
//  outString := match(inDirection)
//    case Absyn.INPUT() then "input";
//    case Absyn.OUTPUT() then "output";
//    else "";
//  end match;
//end directionString;
//
//protected function mergeConnectorType
//  "Merges outer and inner connector type prefixes (flow, stream)."
//  input tuple<SCode.ConnectorType, SourceInfo> inOuterConnectorType;
//  input tuple<SCode.ConnectorType, SourceInfo> inInnerConnectorType;
//  input Absyn.Path inElementName;
//  input String inElementType;
//  output tuple<SCode.ConnectorType, SourceInfo> outConnectorType;
//algorithm
//  outConnectorType := matchcontinue(inOuterConnectorType, inInnerConnectorType,
//      inElementName, inElementType)
//    local
//      SCode.ConnectorType ct1, ct2;
//      SourceInfo info1, info2;
//      String ct1_str, ct2_str, el_name;
//
//    // If either of the prefixes are unset, return the others.
//    case ((SCode.POTENTIAL(), _), _, _, _) then inInnerConnectorType;
//    case (_, (SCode.POTENTIAL(), _), _, _) then inOuterConnectorType;
//
//    // Trying to overwrite a flow/stream prefix => show error.
//    case ((ct1, info1), (ct2, info2), _, _)
//      equation
//        ct1_str = SCodeDump.connectorTypeStr(ct1);
//        ct2_str = SCodeDump.connectorTypeStr(ct2);
//        el_name = Absyn.pathString(inElementName);
//        Error.addMultiSourceMessage(Error.INVALID_TYPE_PREFIX,
//          {ct2_str, inElementType, el_name, ct1_str}, {info1, info2});
//      then
//        fail();
//
//  end matchcontinue;
//end mergeConnectorType;
//
//public function prefixElement
//  input Element inElement;
//  input Prefix inPrefix;
//  output Element outElement;
//algorithm
//  outElement := match(inElement, inPrefix)
//    local
//      Component comp;
//      Class cls;
//      Absyn.Path bc;
//      DAE.Type ty;
//
//    case (NFInstTypes.ELEMENT(comp, cls), _)
//      equation
//        comp = prefixComponent(comp, inPrefix);
//        cls = prefixClass(cls, inPrefix);
//      then
//        NFInstTypes.ELEMENT(comp, cls);
//
//    case (NFInstTypes.CONDITIONAL_ELEMENT(comp), _)
//      equation
//        comp = prefixComponent(comp, inPrefix);
//      then
//        NFInstTypes.CONDITIONAL_ELEMENT(comp);
//
//  end match;
//end prefixElement;
//
//public function prefixComponent
//  input Component inComponent;
//  input Prefix inPrefix;
//  output Component outComponent;
//protected
//  Absyn.Path name;
//algorithm
//  name := getComponentName(inComponent);
//  name := NFInstPrefix.prefixPath(name, inPrefix);
//  outComponent := setComponentName(inComponent, name);
//end prefixComponent;
//
//public function prefixClass
//  input Class inClass;
//  input Prefix inPrefix;
//  output Class outClass;
//algorithm
//  outClass := match(inClass, inPrefix)
//    local
//      list<Element> comps;
//      list<Equation> eq, ieq;
//      list<list<Statement>> al, ial;
//      Absyn.Path name;
//
//    case (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), _)
//      equation
//        comps = List.map1(comps, prefixElement, inPrefix);
//      then
//        NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial);
//
//    else inClass;
//
//  end match;
//end prefixClass;
//
//public function countElementsInClass
//  input Class inClass;
//  output Integer outElements;
//algorithm
//  outElements := match(inClass)
//    local
//      list<Element> comps;
//      Integer count;
//
//    case NFInstTypes.BASIC_TYPE(_) then 0;
//
//    case NFInstTypes.COMPLEX_CLASS(components = comps)
//      equation
//        count = List.fold(comps, countElementsInElement, 0);
//      then
//        count;
//
//  end match;
//end countElementsInClass;
//
//public function countElementsInElement
//  input Element inElement;
//  input Integer inCount;
//  output Integer outCount;
//algorithm
//  outCount := match(inElement, inCount)
//    local
//      Class cls;
//
//    case (NFInstTypes.ELEMENT(cls = cls), _)
//      then 1 + countElementsInClass(cls) + inCount;
//
//    case (NFInstTypes.CONDITIONAL_ELEMENT(), _)
//      then 1 + inCount;
//
//  end match;
//end countElementsInElement;
//
//public function removeCrefOuterPrefix
//  input Absyn.Path inInnerPath;
//  input DAE.ComponentRef inOuterCref;
//  output DAE.ComponentRef outInnerCref;
//algorithm
//  outInnerCref := match(inInnerPath, inOuterCref)
//    local
//      Absyn.Path path;
//      DAE.ComponentRef cref;
//      String id, err_msg;
//      DAE.Type ty;
//      list<DAE.Subscript> subs;
//
//    case (Absyn.IDENT(), _)
//      equation
//        cref = ComponentReference.crefLastCref(inOuterCref);
//      then
//        cref;
//
//    case (Absyn.QUALIFIED(path = path), DAE.CREF_QUAL(id, ty, subs, cref))
//      equation
//        cref = removeCrefOuterPrefix(path, cref);
//      then
//        DAE.CREF_QUAL(id, ty, subs, cref);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        err_msg = "NFSCodeInst.removeCrefOuterPrefix failed on inner path " +
//          Absyn.pathString(inInnerPath) + " and outer cref " +
//          ComponentReference.printComponentRefStr(inOuterCref);
//        Debug.traceln(err_msg);
//      then
//        fail();
//
//  end match;
//end removeCrefOuterPrefix;
//
//public function replaceCrefOuterPrefix
//  input DAE.ComponentRef inCref;
//  input SymbolTable inSymbolTable;
//  output DAE.ComponentRef outCref;
//  output SymbolTable outSymbolTable;
//algorithm
//  (outCref, outSymbolTable) := match(inCref, inSymbolTable)
//    local
//      DAE.ComponentRef prefix_cref, rest_cref, cref;
//      SymbolTable st;
//
//    case (_, st)
//      equation
//        (prefix_cref, rest_cref) = ComponentReference.splitCrefLast(inCref);
//        (cref, st) = replaceCrefOuterPrefix2(prefix_cref, rest_cref, st);
//      then
//        (cref, st);
//
//  end match;
//end replaceCrefOuterPrefix;
//
//protected function replaceCrefOuterPrefix2
//  input DAE.ComponentRef inPrefixCref;
//  input DAE.ComponentRef inSuffixCref;
//  input SymbolTable inSymbolTable;
//  output DAE.ComponentRef outNewCref;
//  output SymbolTable outSymbolTable;
//algorithm
//  (outNewCref, outSymbolTable) :=
//  matchcontinue(inPrefixCref, inSuffixCref, inSymbolTable)
//    local
//      Absyn.Path inner_name;
//      Component comp;
//      SymbolTable st;
//      DAE.ComponentRef inner_cref, new_cref, prefix_cref, rest_cref;
//
//    case (_, _, st)
//      equation
//        comp = NFInstSymbolTable.lookupCref(inPrefixCref, st);
//        (inner_name, _, st) = NFInstSymbolTable.updateInnerReference(comp, st);
//        inner_cref = removeCrefOuterPrefix(inner_name, inPrefixCref);
//        new_cref = ComponentReference.joinCrefs(inner_cref, inSuffixCref);
//      then
//        (new_cref, st);
//
//    case (_, _, st)
//      equation
//        (prefix_cref, rest_cref) = ComponentReference.splitCrefLast(inPrefixCref);
//        rest_cref = ComponentReference.joinCrefs(rest_cref, inSuffixCref);
//        (new_cref, st) = replaceCrefOuterPrefix2(prefix_cref, rest_cref, st);
//      then
//        (new_cref, st);
//
//  end matchcontinue;
//end replaceCrefOuterPrefix2;
//
//public function isInnerComponent
//  input Component inComponent;
//  output Boolean outIsInner;
//algorithm
//  outIsInner := match(inComponent)
//    local
//      SCode.Element el;
//      Absyn.InnerOuter io;
//
//    case NFInstTypes.UNTYPED_COMPONENT(prefixes = NFInstTypes.PREFIXES(innerOuter = io))
//      then Absyn.isInner(io);
//
//    case NFInstTypes.TYPED_COMPONENT(prefixes = NFInstTypes.DAE_PREFIXES(innerOuter = io))
//      then Absyn.isInner(io);
//
//    case NFInstTypes.CONDITIONAL_COMPONENT(element = el)
//      then SCode.isInnerComponent(el);
//
//    else false;
//  end match;
//end isInnerComponent;
//
//public function isConnectorComponent
//  input Component inComponent;
//  output Boolean outIsConnector;
//algorithm
//  outIsConnector := match(inComponent)
//    local
//      DAE.Type ty;
//
//    case NFInstTypes.TYPED_COMPONENT(ty = ty)
//      equation
//        ty = arrayElementType(ty);
//      then
//        Types.isConnector(ty);
//
//    case NFInstTypes.UNTYPED_COMPONENT(baseType = ty)
//      then Types.isConnector(ty);
//
//    else
//      equation
//        Error.addMessage(Error.INTERNAL_ERROR,
//          {"NFInstUtil.isConnectorComponent: Unknown component\n"});
//      then
//        fail();
//
//  end match;
//end isConnectorComponent;
//
//replaceable type TraverseArgType subtypeof Any;
//
//partial function TraverseFuncType
//  input Component inComponent;
//  input TraverseArgType inArg;
//  output Component outComponent;
//  output TraverseArgType outArg;
//end TraverseFuncType;
//
//public function traverseClassComponents
//  input Class inClass;
//  input TraverseArgType inArg;
//  input TraverseFuncType inFunc;
//  output Class outClass;
//  output TraverseArgType outArg;
//algorithm
//  (outClass, outArg) := match(inClass, inArg, inFunc)
//    local
//      TraverseArgType arg;
//      list<Element> comps;
//      list<Equation> eq, ieq;
//      list<list<Statement>> al, ial;
//      Absyn.Path name;
//
//    case (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), arg, _)
//      equation
//        (comps, arg) = traverseClassComponents2(comps, arg, inFunc, {});
//      then
//        (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), arg);
//
//    else (inClass, inArg);
//
//  end match;
//end traverseClassComponents;
//
//protected function traverseClassComponents2
//  input list<Element> inElements;
//  input TraverseArgType inArg;
//  input TraverseFuncType inFunc;
//  input list<Element> inAccumEl;
//  output list<Element> outElements;
//  output TraverseArgType outArg;
//algorithm
//  (outElements, outArg) := match(inElements, inArg, inFunc, inAccumEl)
//    local
//      Element el;
//      list<Element> rest_el;
//      TraverseArgType arg;
//
//    case (el :: rest_el, arg, _, _)
//      equation
//        (el, arg) = traverseClassElement(el, inArg, inFunc);
//        (rest_el, arg) = traverseClassComponents2(rest_el, arg, inFunc, el :: inAccumEl);
//      then
//        (rest_el, arg);
//
//    else (listReverse(inAccumEl), inArg);
//
//  end match;
//end traverseClassComponents2;
//
//protected function traverseClassElement
//  input Element inElement;
//  input TraverseArgType inArg;
//  input TraverseFuncType inFunc;
//  output Element outElement;
//  output TraverseArgType outArg;
//algorithm
//  (outElement, outArg) := match(inElement, inArg, inFunc)
//    local
//      Component comp;
//      Class cls;
//      Absyn.Path bc;
//      DAE.Type ty;
//      TraverseArgType arg;
//
//    case (NFInstTypes.ELEMENT(comp, cls), arg, _)
//      equation
//        (comp, arg) = inFunc(comp, arg);
//        (cls, arg) = traverseClassComponents(cls, arg, inFunc);
//      then
//        (NFInstTypes.ELEMENT(comp, cls), arg);
//
//    case (NFInstTypes.CONDITIONAL_ELEMENT(comp), arg, _)
//      equation
//        (comp, arg) = inFunc(comp, arg);
//      then
//        (NFInstTypes.CONDITIONAL_ELEMENT(comp), arg);
//
//    case (NFInstTypes.EXTENDED_ELEMENTS(bc, cls, ty), arg, _)
//      equation
//        (cls, arg) = traverseClassComponents(cls, arg, inFunc);
//      then
//        (NFInstTypes.EXTENDED_ELEMENTS(bc, cls, ty), arg);
//
//  end match;
//end traverseClassElement;
//
//public function paramTypeFromPrefixes
//  input Prefixes inPrefixes;
//  output ParamType outParamType;
//algorithm
//  outParamType := match(inPrefixes)
//    case NFInstTypes.PREFIXES(variability = SCode.PARAM())
//      then NFInstTypes.NON_STRUCT_PARAM();
//
//    else NFInstTypes.NON_PARAM();
//
//  end match;
//end paramTypeFromPrefixes;
//
//public function translatePrefixes
//  input Prefixes inPrefixes;
//  output DaePrefixes outPrefixes;
//algorithm
//  outPrefixes := match(inPrefixes)
//    local
//      SCode.Visibility vis1;
//      DAE.VarVisibility vis2;
//      SCode.Variability var1;
//      DAE.VarKind var2;
//      SCode.Final fp;
//      Absyn.InnerOuter io;
//      Absyn.Direction dir1;
//      DAE.VarDirection dir2;
//      SCode.ConnectorType ct1;
//      DAE.ConnectorType ct2;
//
//    case NFInstTypes.NO_PREFIXES() then NFInstTypes.NO_DAE_PREFIXES();
//    case NFInstTypes.PREFIXES(vis1, var1, fp, io, (dir1, _), (ct1, _), _)
//      equation
//        vis2 = translateVisibility(vis1);
//        var2 = translateVariability(var1);
//        dir2 = translateDirection(dir1);
//        ct2 = translateConnectorType(ct1);
//      then
//        NFInstTypes.DAE_PREFIXES(vis2, var2, fp, io, dir2, ct2);
//
//  end match;
//end translatePrefixes;
//
//public function translateVisibility
//  input SCode.Visibility inVisibility;
//  output DAE.VarVisibility outVisibility;
//algorithm
//  outVisibility := match(inVisibility)
//    case SCode.PUBLIC() then DAE.PUBLIC();
//    else DAE.PROTECTED();
//  end match;
//end translateVisibility;
//
//public function translateVariability
//  input SCode.Variability inVariability;
//  output DAE.VarKind outVariability;
//algorithm
//  outVariability := match(inVariability)
//    case SCode.VAR() then DAE.VARIABLE();
//    case SCode.PARAM() then DAE.PARAM();
//    case SCode.CONST() then DAE.CONST();
//    case SCode.DISCRETE() then DAE.DISCRETE();
//  end match;
//end translateVariability;
//
//public function translateDirection
//  input Absyn.Direction inDirection;
//  output DAE.VarDirection outDirection;
//algorithm
//  outDirection := match(inDirection)
//    case Absyn.BIDIR() then DAE.BIDIR();
//    case Absyn.OUTPUT() then DAE.OUTPUT();
//    case Absyn.INPUT() then DAE.INPUT();
//  end match;
//end translateDirection;
//
//public function translateConnectorType
//  input SCode.ConnectorType inConnectorType;
//  output DAE.ConnectorType outConnectorType;
//algorithm
//  outConnectorType := match(inConnectorType)
//    case SCode.FLOW() then DAE.FLOW();
//    case SCode.STREAM() then DAE.STREAM();
//    else DAE.NON_CONNECTOR();
//  end match;
//end translateConnectorType;
//
//public function conditionTrue
//  input Condition inCondition;
//  output Boolean outCondition;
//algorithm
//  outCondition := matchcontinue(inCondition)
//    local
//      Boolean cond;
//      list<Condition> condl;
//
//    case NFInstTypes.SINGLE_CONDITION(condition = cond) then cond;
//    case NFInstTypes.ARRAY_CONDITION(conditions = condl)
//      equation
//        _ = List.find(condl, conditionFalse);
//      then
//        false;
//
//    else true;
//  end matchcontinue;
//end conditionTrue;
//
//public function conditionFalse
//  input Condition inCondition;
//  output Boolean outCondition;
//algorithm
//  outCondition := matchcontinue(inCondition)
//    local
//      Boolean cond;
//      list<Condition> condl;
//
//    case NFInstTypes.SINGLE_CONDITION(condition = cond) then not cond;
//    case NFInstTypes.ARRAY_CONDITION(conditions = condl)
//      equation
//        _ = List.find(condl, conditionTrue);
//      then
//        false;
//
//    else true;
//  end matchcontinue;
//end conditionFalse;
//
//public function isArrayAllocation
//  input NFInstTypes.Statement stmt;
//  output Boolean b;
//algorithm
//  b := match stmt case NFInstTypes.FUNCTION_ARRAY_INIT() then true; else false; end match;
//end isArrayAllocation;
//
//public function isFlowComponent
//  input Component inComponent;
//  output Boolean outIsFlow;
//algorithm
//  outIsFlow := match(inComponent)
//    case NFInstTypes.UNTYPED_COMPONENT(prefixes =
//      NFInstTypes.PREFIXES(connectorType = (SCode.FLOW(), _))) then true;
//    case NFInstTypes.TYPED_COMPONENT(prefixes =
//      NFInstTypes.DAE_PREFIXES(connectorType = DAE.FLOW())) then true;
//    else false;
//  end match;
//end isFlowComponent;
//
//public function getFunctionInputs
//  input Function inFunction;
//  output list<Element> outInputs;
//algorithm
//  outInputs := match(inFunction)
//    local
//      list<Element> inputs;
//
//    case NFInstTypes.FUNCTION(inputs = inputs) then inputs;
//    case NFInstTypes.RECORD_CONSTRUCTOR(inputs = inputs) then inputs;
//
//  end match;
//end getFunctionInputs;
//
//public function getComponentParent
//  input Component inComponent;
//  output Option<Component> outParent;
//algorithm
//  outParent := match(inComponent)
//    local
//      Option<Component> parent;
//
//    case NFInstTypes.TYPED_COMPONENT(parent = parent) then parent;
//    else NONE();
//
//  end match;
//end getComponentParent;
//
//public function setComponentParent
//  input Component inComponent;
//  input Option<Component> inParent;
//  output Component outComponent;
//algorithm
//  outComponent := match(inComponent, inParent)
//    local
//      Absyn.Path name;
//      DAE.Type ty;
//      DaePrefixes pref;
//      Binding binding;
//      SourceInfo info;
//
//    case (NFInstTypes.TYPED_COMPONENT(name, ty, _, pref, binding, info), SOME(_))
//      then NFInstTypes.TYPED_COMPONENT(name, ty, inParent, pref, binding, info);
//
//    else inComponent;
//
//  end match;
//end setComponentParent;
//
//public function makeTypedComponentCref
//  input Component inComponent;
//  output DAE.ComponentRef outCref;
//algorithm
//  outCref := match(inComponent)
//    local
//      Absyn.Path name;
//      DAE.ComponentRef cref;
//
//    case NFInstTypes.TYPED_COMPONENT(name = name)
//      equation
//        (cref, _) = makeTypedComponentCref2(name, inComponent);
//      then
//        cref;
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.trace("- NFInstUtil.makeTypedComponentCref failed on component ");
//        Debug.traceln(NFInstDump.componentStr(inComponent));
//      then
//        fail();
//
//  end match;
//end makeTypedComponentCref;
//
//protected function makeTypedComponentCref2
//  input Absyn.Path inPath;
//  input Component inComponent;
//  output DAE.ComponentRef outCref;
//  output Option<Component> outParent;
//algorithm
//  (outCref, outParent) := match(inPath, inComponent)
//    local
//      Absyn.Ident id;
//      Absyn.Path rest_path;
//      DAE.ComponentRef cref;
//      DAE.Type ty;
//      Option<Component> parent;
//
//    case (Absyn.QUALIFIED(name = id, path = rest_path), _)
//      equation
//        (cref, SOME(NFInstTypes.TYPED_COMPONENT(ty = ty, parent = parent))) =
//          makeTypedComponentCref2(rest_path, inComponent);
//      then
//        (DAE.CREF_QUAL(id, ty, {}, cref), parent);
//
//    case (Absyn.IDENT(name = id),
//        NFInstTypes.TYPED_COMPONENT(ty = ty, parent = parent))
//      then (DAE.CREF_IDENT(id, ty, {}), parent);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.trace("- NFInstUtil.makeTypedComponentCref2 failed on path ");
//        Debug.traceln(Absyn.pathString(inPath));
//      then
//        fail();
//
//  end match;
//end makeTypedComponentCref2;
//
//public function typeCrefWithComponent
//  input DAE.ComponentRef inCref;
//  input Component inComponent;
//  output DAE.ComponentRef outCref;
//algorithm
//  outCref := match(inCref, inComponent)
//    local
//      DAE.ComponentRef cref;
//
//    case (_, NFInstTypes.TYPED_COMPONENT(parent = NONE())) then inCref;
//
//    else
//      equation
//        (cref, _) = typeCrefWithComponent2(inCref, inComponent);
//      then
//        cref;
//
//  end match;
//end typeCrefWithComponent;
//
//protected function typeCrefWithComponent2
//  input DAE.ComponentRef inCref;
//  input Component inComponent;
//  output DAE.ComponentRef outCref;
//  output Option<Component> outParent;
//algorithm
//  (outCref, outParent) := matchcontinue(inCref, inComponent)
//    local
//      Option<Component> parent;
//      DAE.Ident id;
//      DAE.Type ty;
//      list<DAE.Subscript> subs;
//      DAE.ComponentRef rest_cref;
//
//    case (DAE.CREF_IDENT(id, _, subs),
//        NFInstTypes.TYPED_COMPONENT(ty = ty, parent = parent))
//      then (DAE.CREF_IDENT(id, ty, subs), parent);
//
//    case (DAE.CREF_QUAL(id, _, subs, rest_cref), _)
//      equation
//        (rest_cref, SOME(NFInstTypes.TYPED_COMPONENT(ty = ty, parent = parent))) =
//          typeCrefWithComponent2(rest_cref, inComponent);
//      then
//        (DAE.CREF_QUAL(id, ty, subs, rest_cref), parent);
//
//    else
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.trace("- NFInstUtil.typeCrefWithComponent2 failed on cref ");
//        Debug.trace(ComponentReference.printComponentRefStr(inCref));
//        Debug.trace(" and component ");
//        Debug.traceln(NFInstDump.componentStr(inComponent));
//      then
//        fail();
//
//  end matchcontinue;
//end typeCrefWithComponent2;
//
public function toConst
  "Translates SCode.Variability to DAE.Const"
  input SCode.Variability inVar;
  output DAE.Const outConst;
algorithm
  outConst := match inVar
    case SCode.CONST() then DAE.C_CONST();
    case SCode.PARAM() then DAE.C_PARAM();
    else DAE.C_VAR();
  end match;
end toConst;

//public function setClassName
//  input Class inClass;
//  input Absyn.Path inClassName;
//  output Class outClass;
//algorithm
//  outClass := match(inClass, inClassName)
//    local
//      list<Element> el;
//      list<Equation> eq, ieq;
//      list<list<Statement>> al, ial;
//      Absyn.Path name;
//
//    case (NFInstTypes.COMPLEX_CLASS(_, el, eq, ieq, al, ial), _)
//      then
//        NFInstTypes.COMPLEX_CLASS(inClassName, el, eq, ieq, al, ial);
//
//    case (NFInstTypes.BASIC_TYPE(_), _)
//      then
//        NFInstTypes.BASIC_TYPE(inClassName);
//
//  end match;
//end setClassName;
//
//public function getClassName
//  input Class inClass;
//  output Absyn.Path outClassName;
//algorithm
//  outClassName := match(inClass)
//    local
//      Absyn.Path name;
//
//    case (NFInstTypes.COMPLEX_CLASS(name = name))
//      then
//        name;
//
//    case (NFInstTypes.BASIC_TYPE(name))
//      then
//        name;
//
//  end match;
//end getClassName;
//
//public function isModifiableElement
//  input Element inElement;
//  output Boolean outBool;
//algorithm
//  outBool := match(inElement)
//    local
//      Component comp;
//
//    case(NFInstTypes.ELEMENT(comp, _)) then isModifiableComponent(comp);
//
//  end match;
//end isModifiableElement;
//
//public function isModifiableComponent
//"@mahge:
// Returns true if a component is modifiable from outside of scope.
// Protected, final and constants with bidings can not be modifed.
// Everything else can be.
//"
//  input Component inComponent;
//  output Boolean outBool;
//algorithm
//  outBool := matchcontinue(inComponent)
//    local
//    case(NFInstTypes.UNTYPED_COMPONENT(prefixes = NFInstTypes.PREFIXES(visibility = SCode.PROTECTED()))) then false;
//    case(NFInstTypes.UNTYPED_COMPONENT(prefixes = NFInstTypes.PREFIXES(variability = SCode.CONST()), binding = NFInstTypes.UNBOUND())) then true;
//    case(NFInstTypes.UNTYPED_COMPONENT(prefixes = NFInstTypes.PREFIXES(variability = SCode.CONST()))) then false;
//    case(NFInstTypes.UNTYPED_COMPONENT(prefixes = NFInstTypes.PREFIXES(finalPrefix = SCode.FINAL()))) then false;
//    else true;
//  end matchcontinue;
//end isModifiableComponent;
//
//public function markElementAsInput
//  input Element inElement;
//  output Element outElement;
//algorithm
//  outElement := match(inElement)
//    local
//      Component comp;
//      Class cls;
//
//    case(NFInstTypes.ELEMENT(comp, cls))
//      equation
//        comp = markComponentAsInput(comp);
//      then NFInstTypes.ELEMENT(comp, cls);
//
//  end match;
//end markElementAsInput;
//
//public function markComponentAsInput
//  input Component inComponent;
//  output Component outComponent;
//algorithm
//  outComponent := match(inComponent)
//    local
//      Absyn.Path name;
//      DAE.Type baseType;
//      array<Dimension> dimensions;
//      ParamType paramType;
//      Binding binding;
//      SourceInfo info;
//
//    case(NFInstTypes.UNTYPED_COMPONENT(name, baseType, dimensions, _, paramType, binding, info))
//      then NFInstTypes.UNTYPED_COMPONENT(name, baseType, dimensions, NFInstTypes.DEFAULT_INPUT_PREFIXES, paramType, binding, info);
//
//    else
//      equation
//        Error.addMessage(Error.INTERNAL_ERROR,{"NFInstUtil.markComponentAsInput failed"});
//      then fail();
//  end match;
//end markComponentAsInput;
//
//public function markElementAsProtected
//  input Element inElement;
//  output Element outElement;
//algorithm
//  outElement := match(inElement)
//    local
//      Component comp;
//      Class cls;
//
//    case(NFInstTypes.ELEMENT(comp, cls))
//      equation
//        comp = markComponentAsProtected(comp);
//      then NFInstTypes.ELEMENT(comp, cls);
//
//  end match;
//end markElementAsProtected;
//
//public function markComponentAsProtected
//  input Component inComponent;
//  output Component outComponent;
//algorithm
//  outComponent := match(inComponent)
//    local
//      Absyn.Path name;
//      DAE.Type baseType;
//      array<Dimension> dimensions;
//      ParamType paramType;
//      Binding binding;
//      SourceInfo info;
//
//    case(NFInstTypes.UNTYPED_COMPONENT(name, baseType, dimensions, _, paramType, binding, info))
//      then NFInstTypes.UNTYPED_COMPONENT(name, baseType, dimensions, NFInstTypes.DEFAULT_PROTECTED_PREFIXES, paramType, binding, info);
//
//    else
//      equation
//        Error.addMessage(Error.INTERNAL_ERROR,{"NFInstUtil.markComponentAsProtected failed"});
//      then fail();
//  end match;
//end markComponentAsProtected;
//
annotation(__OpenModelica_Interface="frontend");
end NFInstUtil;
