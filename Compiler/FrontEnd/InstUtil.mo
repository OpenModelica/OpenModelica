/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package InstUtil
" file:        InstUtil.mo
  package:     InstUtil
  description: Utility functions for InstTypes.

  RCS: $Id$

  Utility functions for operating on the types in InstTypes.
"

public import Absyn;
public import ClassInf;
public import DAE;
public import InstSymbolTable;
public import InstTypes;
public import SCode;
public import SCodeEnv;

protected import ComponentReference;
protected import Connect;
protected import ConnectUtil;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Dump;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import List;
protected import SCodeDump;
protected import Types;
protected import Util;

public type Binding = InstTypes.Binding;
public type Class = InstTypes.Class;
public type Component = InstTypes.Component;
public type DaePrefixes = InstTypes.DaePrefixes;
public type Dimension = InstTypes.Dimension;
public type Element = InstTypes.Element;
public type Env = SCodeEnv.Env;
public type Equation = InstTypes.Equation;
public type Modifier = InstTypes.Modifier;
public type ParamType = InstTypes.ParamType;
public type Prefixes = InstTypes.Prefixes;
public type Prefix = InstTypes.Prefix;
public type SymbolTable = InstSymbolTable.SymbolTable;

public function makeClass
  input list<Element> inElements;
  input list<Equation> inEquations;
  input list<Equation> inInitialEquations;
  input list<SCode.AlgorithmSection> inAlgorithms;
  input list<SCode.AlgorithmSection> inInitialAlgorithms;
  input ClassInf.State inState;
  input Boolean inContainsSpecialExtends;
  output Class outClass;
  output DAE.Type outClassType;
algorithm
  (outClass, outClassType) := match(inElements, inEquations, inInitialEquations,
      inAlgorithms, inInitialAlgorithms, inState, inContainsSpecialExtends)
    local
      list<Element> elems;
      list<Equation> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;
      Class cls;
      DAE.Type ty;

    case (elems, eq, ieq, al, ial, _, false)
      then (InstTypes.COMPLEX_CLASS(elems, eq, ieq, al, ial), 
        DAE.T_COMPLEX(inState, {}, NONE(), DAE.emptyTypeSource));

    case (_, {}, {}, {}, {}, _, true)
      equation
        (InstTypes.EXTENDED_ELEMENTS(cls = cls, ty = ty), elems) =
          getSpecialExtends(inElements);
      then
        (cls, ty);

  end match;
end makeClass;

public function makeDerivedClassType
  input DAE.Type inType;
  input ClassInf.State inState;
  output DAE.Type outType;
algorithm
  outType := match(inType, inState)
    local
      list<DAE.Var> vars;
      DAE.EqualityConstraint ec;
      DAE.TypeSource src;

    // TODO: Check type restrictions.
    case (DAE.T_COMPLEX(_, vars, ec, src), _)
      then DAE.T_COMPLEX(inState, vars, ec, src);

    else DAE.T_SUBTYPE_BASIC(inState, {}, inType, NONE(), DAE.emptyTypeSource);

  end match;
end makeDerivedClassType;

public function arrayElementType
  input DAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := match(inType)
    local
      DAE.Type ty;
      ClassInf.State state;
      DAE.EqualityConstraint ec;
      DAE.TypeSource src;

    case DAE.T_ARRAY(ty = ty) then arrayElementType(ty);
    case DAE.T_SUBTYPE_BASIC(state, _, ty, ec, src)
      equation
        ty = arrayElementType(ty);
      then
        DAE.T_SUBTYPE_BASIC(state, {}, ty, ec, src);

    else inType;
  end match;
end arrayElementType;

public function addElementsToClass
  input list<Element> inElements;
  input Class inClass;
  output Class outClass;
algorithm
  outClass := match(inElements, inClass)
    local
      list<Element> el;
      list<Equation> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;

    case (_, InstTypes.COMPLEX_CLASS(el, eq, ieq, al, ial))
      equation
        el = listAppend(inElements, el);
      then
        InstTypes.COMPLEX_CLASS(el, eq, ieq, al, ial);

    case (_, InstTypes.BASIC_TYPE())
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"SCodeInst.addElementsToClass: Can't add elements to basic type.\n"});
      then
        fail();

  end match;
end addElementsToClass;   

public function getComponentName
  input Component inComponent;
  output Absyn.Path outName;
algorithm
  outName := match(inComponent)
    local
      Absyn.Path name;

    case InstTypes.UNTYPED_COMPONENT(name = name) then name;
    case InstTypes.TYPED_COMPONENT(name = name) then name;
    case InstTypes.CONDITIONAL_COMPONENT(name = name) then name;
    case InstTypes.DELETED_COMPONENT(name = name) then name;
    case InstTypes.OUTER_COMPONENT(name = name) then name;
    case InstTypes.PACKAGE(name = name) then name;

  end match;
end getComponentName;

public function setComponentName
  input Component inComponent;
  input Absyn.Path inName;
  output Component outComponent;
algorithm
  outComponent := match(inComponent, inName)
    local
      DAE.Type ty;
      array<Dimension> dims;
      Prefixes prefs;
      DaePrefixes dprefs;
      ParamType pty;
      Binding binding;
      Absyn.Info info;
      SCode.Element elem;
      Modifier mod;
      Env env;
      Prefix prefix;
      Option<Absyn.Path> inner_name;
      DAE.Exp cond;

    case (InstTypes.UNTYPED_COMPONENT(_, ty, dims, prefs, pty, binding, info), _)
      then InstTypes.UNTYPED_COMPONENT(inName, ty, dims, prefs, pty, binding, info);

    case (InstTypes.TYPED_COMPONENT(_, ty, dprefs, binding, info), _)
      then InstTypes.TYPED_COMPONENT(inName, ty, dprefs, binding, info);

    case (InstTypes.CONDITIONAL_COMPONENT(_, cond, elem, mod, prefs, env, prefix, info), _)
      then InstTypes.CONDITIONAL_COMPONENT(inName, cond, elem, mod, prefs, env, prefix, info);

    case (InstTypes.DELETED_COMPONENT(_), _)
      then InstTypes.DELETED_COMPONENT(inName);

    case (InstTypes.OUTER_COMPONENT(_, inner_name), _)
      then InstTypes.OUTER_COMPONENT(inName, inner_name);

    case (InstTypes.PACKAGE(_), _)
      then InstTypes.PACKAGE(inName);

  end match;
end setComponentName;
    
public function setComponentParamType
  input Component inComponent;
  input ParamType inParamType;
  output Component outComponent;
algorithm
  outComponent := match(inComponent, inParamType)
    local
      Absyn.Path name;
      DAE.Type ty;
      array<Dimension> dims;
      Prefixes prefs;
      Binding binding;
      Absyn.Info info;

    case (InstTypes.UNTYPED_COMPONENT(name, ty, dims, prefs, _, binding, info), _)
      then InstTypes.UNTYPED_COMPONENT(name, ty, dims, prefs, inParamType, binding, info);

    else inComponent;

  end match;
end setComponentParamType;

public function getComponentType
  input Component inComponent;
  output DAE.Type outType;
algorithm
  outType := match(inComponent)
    local
      DAE.Type ty;

    case InstTypes.UNTYPED_COMPONENT(baseType = ty) then ty;
    case InstTypes.TYPED_COMPONENT(ty = ty) then ty;

  end match;
end getComponentType;

public function getComponentBinding
  input Component inComponent;
  output Binding outBinding;
algorithm
  outBinding := match(inComponent)
    local
      Binding binding;

    case InstTypes.UNTYPED_COMPONENT(binding = binding) then binding;
    case InstTypes.TYPED_COMPONENT(binding = binding) then binding;

  end match;
end getComponentBinding;
 
public function getComponentBindingExp
  input Component inComponent;
  output DAE.Exp outExp;
algorithm
  InstTypes.TYPED_COMPONENT(binding = 
    InstTypes.TYPED_BINDING(bindingExp = outExp)) := inComponent;
end getComponentBindingExp;

public function getComponentVariability
  input Component inComponent;
  output SCode.Variability outVariability;
algorithm
  outVariability := match(inComponent)
    local
      SCode.Variability var;

    case InstTypes.UNTYPED_COMPONENT(prefixes = 
      InstTypes.PREFIXES(variability = var)) then var;

    case InstTypes.TYPED_COMPONENT(prefixes = 
      InstTypes.DAE_PREFIXES(variability = DAE.CONST())) then SCode.CONST();

    case InstTypes.TYPED_COMPONENT(prefixes = 
      InstTypes.DAE_PREFIXES(variability = DAE.PARAM())) then SCode.PARAM();

    else SCode.VAR();

  end match;
end getComponentVariability;

public function getEffectiveComponentVariability
  input Component inComponent;
  output SCode.Variability outVariability;
algorithm
  outVariability := match(inComponent)
    case InstTypes.UNTYPED_COMPONENT(paramType = InstTypes.STRUCT_PARAM())
      then SCode.CONST();

    else getComponentVariability(inComponent);

  end match;
end getEffectiveComponentVariability;

protected function getSpecialExtends
  input list<Element> inElements;
  output Element outSpecialExtends;
  output list<Element> outRestElements;
algorithm
  (outSpecialExtends, outRestElements) := getSpecialExtends2(inElements, {});
end getSpecialExtends;

protected function getSpecialExtends2
  input list<Element> inElements;
  input list<Element> inAccumEl;
  output Element outSpecialExtends;
  output list<Element> outRestElements;
algorithm
  (outSpecialExtends, outRestElements) := matchcontinue(inElements, inAccumEl)
    local
      Element el;
      list<Element> rest_el, accum_el;
      DAE.Type ty;

    case ((el as InstTypes.EXTENDED_ELEMENTS(ty = ty)) :: rest_el, _)
      equation
        true = isSpecialExtends(ty);
        rest_el = listAppend(listReverse(inAccumEl), rest_el);
      then
        (el, rest_el);

    // TODO: Check for illegal elements here (components, etc.).

    case (el :: rest_el, _)
      equation
        (el, rest_el) = getSpecialExtends2(rest_el, el :: inAccumEl);
      then
        (el, rest_el);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- SCodeInst.getSpecialExtends2 failed!");
      then
        fail();

  end matchcontinue;
end getSpecialExtends2;

public function isSpecialExtends
  input DAE.Type inType;
  output Boolean outResult;
algorithm
  outResult := match(inType)
    case DAE.T_COMPLEX(varLst = _) then false;
    else true;
  end match;
end isSpecialExtends;

public function getComponentBindingDimension
  input Component inComponent;
  input Integer inDimension;
  input Integer inCompDimensions;
  output DAE.Dimension outDimension;
protected
  Binding binding;
algorithm
  binding := getComponentBinding(inComponent);
  outDimension := getBindingDimension(binding, inDimension, inCompDimensions);
end getComponentBindingDimension;

public function getBindingDimension
  input Binding inBinding;
  input Integer inDimension;
  input Integer inCompDimensions;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inBinding, inDimension, inCompDimensions)
    local
      DAE.Exp exp;
      Integer pd, index;
      Absyn.Info info;

    case (InstTypes.TYPED_BINDING(bindingExp = exp, propagatedDims = pd), _, _)
      equation
        index = Util.if_(intEq(pd, -1), inDimension,
          inDimension + pd - inCompDimensions);
      then
        getExpDimension(exp, index);

  end match;
end getBindingDimension;
  
public function getExpDimension
  input DAE.Exp inExp;
  input Integer inDimIndex;
  output DAE.Dimension outDimension;
algorithm
  outDimension := matchcontinue(inExp, inDimIndex)
    local
      DAE.Type ty;
      list<DAE.Dimension> dims;
      DAE.Dimension dim;

    case (_, _)
      equation
        ty = Expression.typeof(inExp);
        dims = Types.getDimensions(ty);
        dim = listGet(dims, inDimIndex);
      then
        dim;

    // TODO: Error on index out of bounds!

    else DAE.DIM_UNKNOWN();

  end matchcontinue;
end getExpDimension;
 
public function getBindingExp
  input Binding inBinding;
  output DAE.Exp outExp;
algorithm
  outExp := match(inBinding)
    local
      DAE.Exp exp;

    case InstTypes.TYPED_BINDING(bindingExp = exp) then exp;
    else DAE.ICONST(0);
  end match;
end getBindingExp;

public function makeEnumType
  input list<SCode.Enum> inEnumLiterals;
  input Absyn.Path inEnumPath;
  output DAE.Type outType;
protected
  list<String> names;
algorithm
  names := List.map(inEnumLiterals, SCode.enumName);
  outType := DAE.T_ENUMERATION(NONE(), inEnumPath, names, {}, {}, DAE.emptyTypeSource);
end makeEnumType;

public function makeEnumLiteralComp
  input Absyn.Path inName;
  input DAE.Type inType;
  input Integer inIndex;
  output Component outComponent;
protected
  Binding binding;
algorithm
  binding := InstTypes.TYPED_BINDING(DAE.ENUM_LITERAL(inName, inIndex), inType,
    0, Absyn.dummyInfo);
  outComponent := InstTypes.TYPED_COMPONENT(inName, inType,
    InstTypes.DEFAULT_CONST_DAE_PREFIXES, binding, Absyn.dummyInfo);
end makeEnumLiteralComp;

public function makeDimension
  input DAE.Exp inExp;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inExp)
    local
      Integer idim;

    case DAE.ICONST(idim) then DAE.DIM_INTEGER(idim);
    else DAE.DIM_EXP(inExp);
  end match;
end makeDimension;

public function makeDimensionArray
  input list<DAE.Dimension> inDimensions;
  output array<Dimension> outDimensions;
protected
  list<Dimension> dims;
algorithm
  dims := List.map(inDimensions, wrapDimension);
  outDimensions := listArray(dims);
end makeDimensionArray;

public function wrapDimension
  input DAE.Dimension inDimension;
  output Dimension outDimension;
algorithm
  outDimension := InstTypes.UNTYPED_DIMENSION(inDimension, false);
end wrapDimension;
  
public function mergePrefixesFromComponent
  "Merges a component's prefixes with the given prefixes, with the component's
   prefixes having priority."
  input Absyn.Path inComponentName;
  input SCode.Element inComponent;
  input Prefixes inPrefixes;
  output Prefixes outPrefixes;
algorithm
  outPrefixes := match(inComponentName, inComponent, inPrefixes)
    local
      SCode.Prefixes pf;
      SCode.Attributes attr;
      Prefixes prefs;
      Absyn.Info info;

    case (_, SCode.COMPONENT(prefixes = pf, attributes = attr, info = info), _)
      equation
        prefs = makePrefixes(pf, attr, info);
        prefs = mergePrefixes(prefs, inPrefixes, inComponentName, "variable");
      then
        prefs;

  end match;
end mergePrefixesFromComponent;

protected function makePrefixes
  "Creates an InstTypes.Prefixes record from SCode.Prefixes and SCode.Attributes."
  input SCode.Prefixes inPrefixes;
  input SCode.Attributes inAttributes;
  input Absyn.Info inInfo;
  output Prefixes outPrefixes;
algorithm
  outPrefixes := match(inPrefixes, inAttributes, inInfo)
    local
      SCode.Visibility vis;
      SCode.Variability var;
      SCode.Final fp;
      Absyn.InnerOuter io;
      Absyn.Direction dir;
      SCode.Flow flp;
      SCode.Stream sp;
      Absyn.Info info;

    // All prefixes are the default ones, same as having no prefixes.
    case (SCode.PREFIXES(visibility = SCode.PUBLIC(), finalPrefix =
        SCode.NOT_FINAL(), innerOuter = Absyn.NOT_INNER_OUTER()), SCode.ATTR(
        flowPrefix = SCode.NOT_FLOW(), streamPrefix = SCode.NOT_STREAM(),
        variability = SCode.VAR(), direction = Absyn.BIDIR()), _)
      then InstTypes.NO_PREFIXES();

    // Otherwise, select the prefixes we are interested in and build a PREFIXES
    // record.
    case (SCode.PREFIXES(visibility = vis, finalPrefix = fp, innerOuter = io),
          SCode.ATTR(flowPrefix = flp, streamPrefix = sp, variability = var,
        direction = dir), info)
      then InstTypes.PREFIXES(vis, var, fp, io, (dir, info), (flp, info), (sp, info));

  end match;
end makePrefixes;

public function mergePrefixesWithDerivedClass
  "Merges the attributes of a derived class with the given prefixes."
  input Absyn.Path inClassName;
  input SCode.Element inClass;
  input Prefixes inPrefixes;
  output Prefixes outPrefixes;
algorithm
  outPrefixes := match(inClassName, inClass, inPrefixes)
    local
      SCode.Attributes attr;
      Absyn.Info info;
      Prefixes prefs;

    case (_, SCode.CLASS(classDef = SCode.DERIVED(attributes = attr), info = info), _)
      equation
        prefs = makePrefixesFromAttributes(attr, info);
        prefs = mergePrefixes(prefs, inPrefixes, inClassName, "class");
      then
        prefs;

  end match;
end mergePrefixesWithDerivedClass;

protected function makePrefixesFromAttributes
  "Creates an InstTypes.Prefixes record from an SCode.Attributes."
  input SCode.Attributes inAttributes;
  input Absyn.Info inInfo;
  output Prefixes outPrefixes;
algorithm
  outPrefixes := match(inAttributes, inInfo)
    local
      SCode.Flow flp;
      SCode.Stream sp;
      SCode.Variability var;
      Absyn.Direction dir;
      Absyn.Info info;

    // All attributes are the default ones, same as having no prefixes.
    case (SCode.ATTR(flowPrefix = SCode.NOT_FLOW(), streamPrefix =
        SCode.NOT_STREAM(), variability = SCode.VAR(), direction = Absyn.BIDIR()), _)
      then InstTypes.NO_PREFIXES();

    // Otherwise, select the attributes we are interested in and build a
    // PREFIXES record with the parts not covered by SCode.Attributes set to the
    // default values.
    case (SCode.ATTR(flowPrefix = flp, streamPrefix = sp, variability = var,
        direction = dir), _)
      then InstTypes.PREFIXES(SCode.PUBLIC(), var, SCode.NOT_FINAL(),
        Absyn.NOT_INNER_OUTER(), (dir, inInfo), (flp, inInfo), (sp, inInfo));

  end match;
end makePrefixesFromAttributes;

public function mergePrefixes
  "Merges two InstTypes.Prefixes records, with the outer having priority over
   the inner. inElementName and inElementType are used for error reporting, where
   inElementName is the name of the element that the outer prefixes comes from
   and inElementType the type of that element as a string (variable or class)."
  input Prefixes inOuterPrefixes;
  input Prefixes inInnerPrefixes;
  input Absyn.Path inElementName;
  input String inElementType;
  output Prefixes outPrefixes;
algorithm
  outPrefixes :=
  match(inOuterPrefixes, inInnerPrefixes, inElementName, inElementType)
    local
      SCode.Visibility vis1, vis2;
      SCode.Variability var1, var2;
      SCode.Final fp1, fp2;
      Absyn.InnerOuter io1, io2;
      tuple<Absyn.Direction, Absyn.Info> dir1, dir2;
      tuple<SCode.Flow, Absyn.Info> flp1, flp2;
      tuple<SCode.Stream, Absyn.Info> sp1, sp2;

    // No outer prefixes => no change.
    case (InstTypes.NO_PREFIXES(), _, _, _) then inInnerPrefixes;
    // No inner prefixes => overwrite with outer prefixes.
    case (_, InstTypes.NO_PREFIXES(), _, _) then inOuterPrefixes;

    // Both outer and inner prefixes => merge them.
    case (InstTypes.PREFIXES(vis1, var1, fp1, io1, dir1, flp1, sp1),
          InstTypes.PREFIXES(vis2, var2, fp2, io2, dir2, flp2, sp2), _, _)
      equation
        vis2 = mergeVisibility(vis1, vis2);
        var2 = mergeVariability(var1, var2);
        fp2 = mergeFinal(fp1, fp2);
        dir2 = mergeDirection(dir1, dir2, inElementName, inElementType);
        (flp2, sp2) =
          mergeFlowStream(flp1, sp1, flp2, sp2, inElementName, inElementType);
      then
        InstTypes.PREFIXES(vis2, var2, fp2, io1, dir2, flp2, sp2);

  end match;
end mergePrefixes;

protected function mergeVisibility
  "Merges an outer and inner visibility prefix."
  input SCode.Visibility inOuterVisibility;
  input SCode.Visibility inInnerVisibility;
  output SCode.Visibility outVisibility;
algorithm
  outVisibility := match(inOuterVisibility, inInnerVisibility)
    // If the outer is protected, return protected.
    case (SCode.PROTECTED(), _) then inOuterVisibility;
    // Otherwise, no change.
    else inInnerVisibility;
  end match;
end mergeVisibility;

protected function mergeVariability
  "Merges an outer and inner variability prefix. The most restrictive
   variability is returned (with constant most restrictive, variable least)."
  input SCode.Variability inOuterVariability;
  input SCode.Variability inInnerVariability;
  output SCode.Variability outVariability;
algorithm
  outVariability := match(inOuterVariability, inInnerVariability)
    case (SCode.CONST(), _) then inOuterVariability;
    case (_, SCode.CONST()) then inInnerVariability;
    case (SCode.PARAM(), _) then inOuterVariability;
    case (_, SCode.PARAM()) then inInnerVariability;
    case (SCode.DISCRETE(), _) then inOuterVariability;
    case (_, SCode.DISCRETE()) then inInnerVariability;
    else inInnerVariability;
  end match;
end mergeVariability;

protected function mergeFinal
  "Merges an outer and inner final prefix."
  input SCode.Final inOuterFinal;
  input SCode.Final inInnerFinal;
  output SCode.Final outFinal;
algorithm
  outFinal := match(inOuterFinal, inInnerFinal)
    // If the outer prefix is final, return final.
    case (SCode.FINAL(), _) then inOuterFinal;
    // Otherwise, no change.
    else inInnerFinal;
  end match;
end mergeFinal;

protected function mergeDirection
  "Merges an outer and inner direction prefix."
  input tuple<Absyn.Direction, Absyn.Info> inOuterDirection;
  input tuple<Absyn.Direction, Absyn.Info> inInnerDirection;
  input Absyn.Path inElementName;
  input String inElementType;
  output tuple<Absyn.Direction, Absyn.Info> outDirection;
algorithm
  outDirection :=
  match(inOuterDirection, inInnerDirection, inElementName, inElementType)
    local
      Absyn.Direction dir1, dir2;
      Absyn.Info info1, info2;
      String dir_str1, dir_str2, el_name;

    // If either prefix is unset, return the other.
    case (_, (Absyn.BIDIR(), _), _, _) then inOuterDirection;
    case ((Absyn.BIDIR(), _), _, _, _) then inInnerDirection;

    // Otherwise we have an error, since it's not allowed to overwrite
    // input/output prefixes.
    case ((dir1, info1), (dir2, info2), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, info2);
        dir_str1 = directionString(dir1);
        dir_str2 = directionString(dir2);
        el_name = Absyn.pathString(inElementName);
        Error.addSourceMessage(Error.INVALID_TYPE_PREFIX,
          {dir_str1, inElementType, el_name, dir_str2}, info1);
      then
        fail();

  end match;
end mergeDirection;
   
protected function directionString
  input Absyn.Direction inDirection;
  output String outString;
algorithm
  outString := match(inDirection)
    case Absyn.INPUT() then "input";
    case Absyn.OUTPUT() then "output";
    else "";
  end match;
end directionString;

protected function mergeFlowStream
  "Merges outer and inner flow and stream prefixes."
  input tuple<SCode.Flow, Absyn.Info> inOuterFlow;
  input tuple<SCode.Stream, Absyn.Info> inOuterStream;
  input tuple<SCode.Flow, Absyn.Info> inInnerFlow;
  input tuple<SCode.Stream, Absyn.Info> inInnerStream;
  input Absyn.Path inElementName;
  input String inElementType;
  output tuple<SCode.Flow, Absyn.Info> outFlow;
  output tuple<SCode.Stream, Absyn.Info> outStream;
algorithm
  (outFlow, outStream) := matchcontinue(inOuterFlow, inOuterStream, inInnerFlow,
      inInnerStream, inElementName, inElementType)
    local
      SCode.Flow fp1, fp2;
      SCode.Stream sp1, sp2;
      Absyn.Info info1, info2;
      String fp_str, sp_str, pf_str, el_name;
      tuple<SCode.Flow, Absyn.Info> new_fp;
      tuple<SCode.Stream, Absyn.Info> new_sp;

    // If either of the prefixes are unset, return the others.
    case ((SCode.NOT_FLOW(), _), (SCode.NOT_STREAM(), _), _, _, _, _)
      then (inInnerFlow, inInnerStream);
    case (_, _, (SCode.NOT_FLOW(), _), (SCode.NOT_STREAM(), _), _, _)
      then (inOuterFlow, inOuterStream);

    // Trying to overwrite a flow prefix => show error.
    case ((fp1, info1), (sp1, _), (SCode.FLOW(), info2), _, _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, info1);
        fp_str = SCodeDump.flowStr(fp1);
        sp_str = SCodeDump.streamStr(sp1);
        pf_str = fp_str +& sp_str;
        el_name = Absyn.pathString(inElementName);
        Error.addSourceMessage(Error.INVALID_TYPE_PREFIX,
          {"flow", inElementType, el_name, pf_str}, info2);
      then
        fail();

    // Trying to overwrite a stream prefix => show error.
    case ((fp1, info1), (sp1, _), _, (SCode.STREAM(), info2), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, info1);
        fp_str = SCodeDump.flowStr(fp1);
        sp_str = SCodeDump.streamStr(sp1);
        pf_str = fp_str +& sp_str;
        el_name = Absyn.pathString(inElementName);
        Error.addSourceMessage(Error.INVALID_TYPE_PREFIX,
          {"stream", inElementType, el_name, pf_str}, info2);
      then
        fail();

  end matchcontinue;
end mergeFlowStream;

public function addPrefix
  input String inName;
  input list<DAE.Dimension> inDimensions;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := (inName, inDimensions) :: inPrefix;
end addPrefix;

public function prefixCref
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inCref, inPrefix)
    local
      String name;
      Prefix rest_prefix;
      DAE.ComponentRef cref;

    case (_, {}) then inCref;
    case (_, {(name, _)}) then DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, {}, inCref);
    case (_, (name, _) :: rest_prefix)
      equation
        cref = DAE.CREF_QUAL(name, DAE.T_UNKNOWN_DEFAULT, {}, inCref);
      then
        prefixCref(cref, rest_prefix);

  end match;
end prefixCref;
 
public function prefixToCref
  input Prefix inPrefix;
  output DAE.ComponentRef outCref;
algorithm
  outCref := match(inPrefix)
    local
      String name;
      Prefix rest_prefix;
      DAE.ComponentRef cref;

    case ({(name, _)}) then DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, {});
    case ((name, _) :: rest_prefix)
      equation
        cref = DAE.CREF_IDENT(name, DAE.T_UNKNOWN_DEFAULT, {});
      then
        prefixCref(cref, rest_prefix);

  end match;
end prefixToCref;

public function prefixPath
  input Absyn.Path inPath;
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := match(inPath, inPrefix)
    local
      String name;
      Prefix rest_prefix;
      Absyn.Path path;

    case (_, {}) then inPath;
    case (_, {(name, _)}) then Absyn.QUALIFIED(name, inPath);
    case (_, (name, _) :: rest_prefix)
      equation
        path = Absyn.QUALIFIED(name, inPath);
      then
        prefixPath(path, rest_prefix);

  end match;
end prefixPath;

public function prefixToPath
  input Prefix inPrefix;
  output Absyn.Path outPath;
algorithm
  outPath := match(inPrefix)
    local
      String name;
      Prefix rest_prefix;
      Absyn.Path path;

    case ({(name, _)}) then Absyn.IDENT(name);
    case ((name, _) :: rest_prefix)
      equation
        path = Absyn.IDENT(name);
      then
        prefixPath(path, rest_prefix);

  end match;
end prefixToPath;

public function pathPrefix
  input Absyn.Path inPath;
  output Prefix outPrefix;
algorithm
  outPrefix := pathPrefix2(inPath, {});
end pathPrefix;

protected function pathPrefix2
  input Absyn.Path inPath;
  input Prefix inPrefix;
  output Prefix outPrefix;
algorithm
  outPrefix := match(inPath, inPrefix)
    local
      Absyn.Path path;
      String name;
      Prefix prefix;

    case (Absyn.QUALIFIED(name, path), _)
      then pathPrefix2(path, (name, {}) :: inPrefix);

    case (Absyn.IDENT(name), _)
      then (name, {}) :: inPrefix;

    case (Absyn.FULLYQUALIFIED(path), _)
      then pathPrefix2(path, inPrefix);

  end match;
end pathPrefix2;

public function prefixElement
  input Element inElement;
  input Prefix inPrefix;
  output Element outElement;
algorithm
  outElement := match(inElement, inPrefix)
    local
      Component comp;
      Class cls;
      Absyn.Path bc;
      DAE.Type ty;

    case (InstTypes.ELEMENT(comp, cls), _)
      equation
        comp = prefixComponent(comp, inPrefix);
        cls = prefixClass(cls, inPrefix);
      then
        InstTypes.ELEMENT(comp, cls);

    case (InstTypes.CONDITIONAL_ELEMENT(comp), _)
      equation
        comp = prefixComponent(comp, inPrefix);
      then
        InstTypes.CONDITIONAL_ELEMENT(comp);

    case (InstTypes.EXTENDED_ELEMENTS(bc, cls, ty), _)
      equation
        cls = prefixClass(cls, inPrefix);
      then
        InstTypes.EXTENDED_ELEMENTS(bc, cls, ty);

  end match;
end prefixElement;

public function prefixComponent
  input Component inComponent;
  input Prefix inPrefix;
  output Component outComponent;
protected
  Absyn.Path name;
algorithm
  name := getComponentName(inComponent);
  name := prefixPath(name, inPrefix);
  outComponent := setComponentName(inComponent, name);
end prefixComponent;
        
public function prefixClass
  input Class inClass;
  input Prefix inPrefix;
  output Class outClass;
algorithm
  outClass := match(inClass, inPrefix)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;

    case (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), _)
      equation
        comps = List.map1(comps, prefixElement, inPrefix);
      then
        InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial);

    else inClass;

  end match;
end prefixClass;

public function countElementsInClass
  input Class inClass;
  output Integer outElements;
algorithm
  outElements := match(inClass)
    local
      list<Element> comps;
      Integer count;

    case InstTypes.BASIC_TYPE() then 0;

    case InstTypes.COMPLEX_CLASS(components = comps)
      equation
        count = List.fold(comps, countElementsInElement, 0);
      then
        count;

  end match;
end countElementsInClass;

public function countElementsInElement
  input Element inElement;
  input Integer inCount;
  output Integer outCount;
algorithm
  outCount := match(inElement, inCount)
    local
      Class cls;

    case (InstTypes.ELEMENT(cls = cls), _)
      then 1 + countElementsInClass(cls) + inCount;

    case (InstTypes.CONDITIONAL_ELEMENT(component = _), _)
      then 1 + inCount;

    case (InstTypes.EXTENDED_ELEMENTS(cls = cls), _)
      then countElementsInClass(cls) + inCount;

  end match;
end countElementsInElement;

public function removeCrefOuterPrefix
  input Absyn.Path inInnerPath;
  input DAE.ComponentRef inOuterCref;
  output DAE.ComponentRef outInnerCref;
algorithm
  outInnerCref := match(inInnerPath, inOuterCref)
    local
      Absyn.Path path;
      DAE.ComponentRef cref;
      String id, err_msg;
      DAE.Type ty;
      list<DAE.Subscript> subs;

    case (Absyn.IDENT(name = _), _)
      equation
        cref = ComponentReference.crefLastCref(inOuterCref);
      then
        cref;

    case (Absyn.QUALIFIED(path = path), DAE.CREF_QUAL(id, ty, subs, cref))
      equation
        cref = removeCrefOuterPrefix(path, cref);
      then
        DAE.CREF_QUAL(id, ty, subs, cref);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        err_msg = "SCodeInst.removeCrefOuterPrefix failed on inner path " +&
          Absyn.pathString(inInnerPath) +& " and outer cref " +&
          ComponentReference.printComponentRefStr(inOuterCref);
        Debug.traceln(err_msg);
      then
        fail();

  end match;
end removeCrefOuterPrefix;

public function replaceCrefOuterPrefix
  input DAE.ComponentRef inCref;
  input SymbolTable inSymbolTable;
  output DAE.ComponentRef outCref;
  output SymbolTable outSymbolTable;
algorithm
  (outCref, outSymbolTable) := match(inCref, inSymbolTable)
    local
      DAE.ComponentRef prefix_cref, rest_cref, cref;
      SymbolTable st;
    
    case (_, st)
      equation
        (prefix_cref, rest_cref) = ComponentReference.splitCrefLast(inCref);
        (cref, st) = replaceCrefOuterPrefix2(prefix_cref, rest_cref, st);
      then
        (cref, st);
        
  end match;
end replaceCrefOuterPrefix;

protected function replaceCrefOuterPrefix2
  input DAE.ComponentRef inPrefixCref;
  input DAE.ComponentRef inSuffixCref;
  input SymbolTable inSymbolTable;
  output DAE.ComponentRef outNewCref;
  output SymbolTable outSymbolTable;
algorithm
  (outNewCref, outSymbolTable) :=
  matchcontinue(inPrefixCref, inSuffixCref, inSymbolTable)
    local
      Absyn.Path inner_name;
      Component comp;
      SymbolTable st;
      DAE.ComponentRef inner_cref, new_cref, prefix_cref, rest_cref;

    case (_, _, st)
      equation
        comp = InstSymbolTable.lookupCref(inPrefixCref, st);
        (inner_name, _, st) = InstSymbolTable.updateInnerReference(comp, st);
        inner_cref = removeCrefOuterPrefix(inner_name, inPrefixCref);
        new_cref = ComponentReference.joinCrefs(inner_cref, inSuffixCref);
      then
        (new_cref, st);

    case (_, _, st)
      equation
        (prefix_cref, rest_cref) = ComponentReference.splitCrefLast(inPrefixCref);
        rest_cref = ComponentReference.joinCrefs(rest_cref, inSuffixCref);
        (new_cref, st) = replaceCrefOuterPrefix2(prefix_cref, rest_cref, st);
      then
        (new_cref, st);
         
  end matchcontinue;
end replaceCrefOuterPrefix2;

public function isInnerComponent
  input Component inComponent;
  output Boolean outIsInner;
algorithm
  outIsInner := match(inComponent)
    local
      SCode.Element el;
      Absyn.InnerOuter io;

    case InstTypes.UNTYPED_COMPONENT(prefixes = InstTypes.PREFIXES(innerOuter = io))
      then Absyn.isInner(io);

    case InstTypes.TYPED_COMPONENT(prefixes = InstTypes.DAE_PREFIXES(innerOuter = io))
      then Absyn.isInner(io);

    case InstTypes.CONDITIONAL_COMPONENT(element = el)
      then SCode.isInnerComponent(el);
        
    else false;
  end match;
end isInnerComponent;

public function isConnectorComponent
  input Component inComponent;
  output Boolean outIsConnector;
algorithm
  outIsConnector := match(inComponent)
    local
      DAE.Type ty;
      Absyn.Path name;

    case InstTypes.TYPED_COMPONENT(ty = ty)
      equation
        ty = arrayElementType(ty);
      then
        Types.isComplexConnector(ty);

    case InstTypes.UNTYPED_COMPONENT(baseType = ty)
      then Types.isComplexConnector(ty);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"InstUtil.isConnectorComponent: Unknown component\n"});
      then
        fail();

  end match;
end isConnectorComponent;

replaceable type TraverseArgType subtypeof Any;

partial function TraverseFuncType
  input Component inComponent;
  input TraverseArgType inArg;
  output Component outComponent;
  output TraverseArgType outArg;
end TraverseFuncType;

public function traverseClassComponents
  input Class inClass;
  input TraverseArgType inArg;
  input TraverseFuncType inFunc;
  output Class outClass;
  output TraverseArgType outArg;
algorithm
  (outClass, outArg) := match(inClass, inArg, inFunc)
    local
      TraverseArgType arg;
      list<Element> comps;
      list<Equation> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;

    case (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), arg, _)
      equation
        (comps, arg) = traverseClassComponents2(comps, arg, inFunc, {});
      then
        (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), arg);

    else (inClass, inArg);

  end match;
end traverseClassComponents;

protected function traverseClassComponents2
  input list<Element> inElements;
  input TraverseArgType inArg;
  input TraverseFuncType inFunc;
  input list<Element> inAccumEl;
  output list<Element> outElements;
  output TraverseArgType outArg;
algorithm
  (outElements, outArg) := match(inElements, inArg, inFunc, inAccumEl)
    local
      Element el;
      list<Element> rest_el;
      TraverseArgType arg;

    case (el :: rest_el, arg, _, _)
      equation
        (el, arg) = traverseClassElement(el, inArg, inFunc);
        (rest_el, arg) = traverseClassComponents2(rest_el, arg, inFunc, el :: inAccumEl);
      then
        (rest_el, arg);

    else (listReverse(inAccumEl), inArg);

  end match;
end traverseClassComponents2;
  
protected function traverseClassElement
  input Element inElement;
  input TraverseArgType inArg;
  input TraverseFuncType inFunc;
  output Element outElement;
  output TraverseArgType outArg;
algorithm
  (outElement, outArg) := match(inElement, inArg, inFunc)
    local
      Component comp;
      Class cls;
      Absyn.Path bc;
      DAE.Type ty;
      TraverseArgType arg;

    case (InstTypes.ELEMENT(comp, cls), arg, _)
      equation
        (comp, arg) = inFunc(comp, arg);
        (cls, arg) = traverseClassComponents(cls, arg, inFunc);
      then
        (InstTypes.ELEMENT(comp, cls), arg);

    case (InstTypes.CONDITIONAL_ELEMENT(comp), arg, _)
      equation
        (comp, arg) = inFunc(comp, arg);
      then
        (InstTypes.CONDITIONAL_ELEMENT(comp), arg);

    case (InstTypes.EXTENDED_ELEMENTS(bc, cls, ty), arg, _)
      equation
        (cls, arg) = traverseClassComponents(cls, arg, inFunc);
      then
        (InstTypes.EXTENDED_ELEMENTS(bc, cls, ty), arg);

  end match;
end traverseClassElement;

public function paramTypeFromPrefixes
  input Prefixes inPrefixes;
  output ParamType outParamType;
algorithm
  outParamType := match(inPrefixes)
    case InstTypes.PREFIXES(variability = SCode.PARAM())
      then InstTypes.NON_STRUCT_PARAM();

    else InstTypes.NON_PARAM();

  end match;
end paramTypeFromPrefixes;

public function translatePrefixes
  input Prefixes inPrefixes;
  output DaePrefixes outPrefixes;
algorithm
  outPrefixes := match(inPrefixes)
    local
      SCode.Visibility vis1;
      DAE.VarVisibility vis2;
      SCode.Variability var1;
      DAE.VarKind var2;
      SCode.Final fp;
      Absyn.InnerOuter io;
      Absyn.Direction dir1;
      DAE.VarDirection dir2;
      SCode.Flow flp1;
      DAE.Flow flp2;
      SCode.Stream sp1;
      DAE.Stream sp2;

    case InstTypes.NO_PREFIXES() then InstTypes.NO_DAE_PREFIXES();
    case InstTypes.PREFIXES(vis1, var1, fp, io, (dir1, _), (flp1, _), (sp1, _))
      equation
        vis2 = translateVisibility(vis1);
        var2 = translateVariability(var1);
        dir2 = translateDirection(dir1);
        flp2 = translateFlow(flp1);
        sp2 = translateStream(sp1);
      then
        InstTypes.DAE_PREFIXES(vis2, var2, fp, io, dir2, flp2, sp2);

  end match;
end translatePrefixes;

protected function translateVisibility
  input SCode.Visibility inVisibility;
  output DAE.VarVisibility outVisibility;
algorithm
  outVisibility := match(inVisibility)
    case SCode.PUBLIC() then DAE.PUBLIC();
    else DAE.PROTECTED();
  end match;
end translateVisibility;

protected function translateVariability
  input SCode.Variability inVariability;
  output DAE.VarKind outVariability;
algorithm
  outVariability := match(inVariability)
    case SCode.VAR() then DAE.VARIABLE();
    case SCode.PARAM() then DAE.PARAM();
    case SCode.CONST() then DAE.CONST();
    case SCode.DISCRETE() then DAE.DISCRETE();
  end match;
end translateVariability;

protected function translateDirection
  input Absyn.Direction inDirection;
  output DAE.VarDirection outDirection;
algorithm
  outDirection := match(inDirection)
    case Absyn.BIDIR() then DAE.BIDIR();
    case Absyn.OUTPUT() then DAE.OUTPUT();
    case Absyn.INPUT() then DAE.INPUT();
  end match;
end translateDirection;

protected function translateFlow
  input SCode.Flow inFlow;
  output DAE.Flow outFlow;
algorithm
  outFlow := match(inFlow)
    case SCode.NOT_FLOW() then DAE.NON_CONNECTOR();
    else DAE.FLOW();
  end match;
end translateFlow;

protected function translateStream
  input SCode.Stream inStream;
  output DAE.Stream outStream;
algorithm
  outStream := match(inStream)
    case SCode.NOT_STREAM() then DAE.NON_STREAM_CONNECTOR();
    else DAE.STREAM();
  end match;
end translateStream;

public function printBinding
  input Binding inBinding;
  output String outString;
algorithm
  outString := match(inBinding)
    local
      Absyn.Exp aexp;
      DAE.Exp dexp;
      DAE.Type ty;

    case (InstTypes.RAW_BINDING(bindingExp = aexp))
      then " = " +& Dump.printExpStr(aexp);

    case (InstTypes.UNTYPED_BINDING(bindingExp = dexp))
      then " = " +& ExpressionDump.printExpStr(dexp);

    case (InstTypes.TYPED_BINDING(bindingExp = dexp, bindingType = ty))
      then " = (" +& Types.unparseType(ty) +& ") " +&
        ExpressionDump.printExpStr(dexp);

    else "";
  end match;
end printBinding;

public function printComponent
  input Component inComponent;
  output String outString;
algorithm
  outString := match(inComponent)
    local
      Absyn.Path path, inner_path;
      Binding binding;
      DAE.Type ty;

    case InstTypes.UNTYPED_COMPONENT(name = path, binding = binding)
      then "  " +& Absyn.pathString(path) +& printBinding(binding);

    case InstTypes.TYPED_COMPONENT(name = path, ty = ty, binding = binding)
      then "  " +& Types.unparseType(ty) +& " " +& Absyn.pathString(path) +&
        printBinding(binding);

    case InstTypes.CONDITIONAL_COMPONENT(name = path) 
      then "  conditional " +& Absyn.pathString(path);

    case InstTypes.DELETED_COMPONENT(name = path)
      then "  deleted " +& Absyn.pathString(path);

    case InstTypes.OUTER_COMPONENT(name = path, innerName = SOME(inner_path))
      then "  outer " +& Absyn.pathString(path) +& " -> " +& Absyn.pathString(inner_path);

    case InstTypes.OUTER_COMPONENT(name = path)
      then "  outer " +& Absyn.pathString(path);

    case InstTypes.PACKAGE(name = path)
      then "  package " +& Absyn.pathString(path);

    else "#UNKNOWN COMPONENT#";
  end match;
end printComponent;

public function printPrefix
  input Prefix inPrefix;
  output String outString;
algorithm
  outString := match(inPrefix)
    local
      String id;
      DAE.Dimensions dims;
      Prefix rest_pre;

    case {} then "";
    case {(id, dims)} then id +& 
        List.toString(dims, ExpressionDump.dimensionString, "", "[", ", ", "]", false);
    case ((id, dims) :: rest_pre) then printPrefix(rest_pre) +& "." +& id +&
        List.toString(dims, ExpressionDump.dimensionString, "", "[", ", ", "]", false);

  end match;
end printPrefix;

public function printElement
  input Element inElement;
  output String outString;
algorithm
  outString := match(inElement)
    local
      Component comp;
      list<Element> el;
      Class cls;
      String comp_str, cls_str, delim;

    case InstTypes.ELEMENT(component = comp, cls = cls)
      equation
        comp_str = printComponent(comp);
        cls_str = printClass(cls);
      then
        Util.stringDelimitListNonEmptyElts({comp_str, cls_str}, "\n");

    case InstTypes.CONDITIONAL_ELEMENT(component = comp)
      then printComponent(comp);

    case InstTypes.EXTENDED_ELEMENTS(cls = cls)
      then printClass(cls);

  end match;
end printElement;

public function printClass
  input Class inClass;
  output String outString;
algorithm
  outString := match(inClass)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      String comps_str, eq_str, ieq_str, str;

    case InstTypes.BASIC_TYPE() then "";

    case InstTypes.COMPLEX_CLASS(components = comps, equations = eq, 
        initialEquations = ieq)
      equation
        comps_str = Util.stringDelimitListNonEmptyElts(
          List.map(comps, printElement), "\n");
        ieq_str = stringDelimitList(List.map(ieq, printEquation), "\n  ");
        ieq_str = Util.stringAppendNonEmpty("\ninitial equation\n  ", ieq_str);
        eq_str = stringDelimitList(List.map(eq, printEquation), "\n  ");
        eq_str = Util.stringAppendNonEmpty("\nequation\n  ", eq_str);
        str = comps_str +& ieq_str +& eq_str;
      then
        str;

  end match;
end printClass;

public function printEquation
  input Equation inEquation;
  output String outString;
algorithm
  outString := match(inEquation)
    local
      DAE.Exp exp1, exp2;
      DAE.Type ty1, ty2;
      DAE.ComponentRef cref1, cref2;
      Connect.Face face1, face2;
      String index, res, eql_str;
      String exp_str1, exp_str2, ty_str1, ty_str2, face_str1, face_str2;
      list<Equation> eql;

    case (InstTypes.EQUALITY_EQUATION(lhs = exp1, rhs = exp2))
      equation
        exp_str1 = ExpressionDump.printExpStr(exp1);
        exp_str2 = ExpressionDump.printExpStr(exp2);
        ty_str1 = Types.unparseType(Expression.typeof(exp1));
        ty_str2 = Types.unparseType(Expression.typeof(exp2));
      then
        exp_str1 +& " {" +& ty_str1 +& "} = {" +& ty_str2 +& "} " +& exp_str2 +& ";";

    case (InstTypes.CONNECT_EQUATION(lhs = cref1, lhsFace = face1,
        rhs = cref2, rhsFace = face2))
      equation
        exp_str1 = ComponentReference.printComponentRefStr(cref1);
        exp_str2 = ComponentReference.printComponentRefStr(cref2);
        face_str1 = ConnectUtil.printFaceStr(face1);
        face_str2 = ConnectUtil.printFaceStr(face2);
      then
        "connect(" +& exp_str1 +& " <" +& face_str1 +& ">, " +& exp_str2 +& " <"
          +& face_str2 +& ">);";

    case (InstTypes.FOR_EQUATION(index = index, indexType = ty1, 
        range = exp1, body = eql))
      equation
        ty_str1 = Types.unparseType(ty1);
        res = "for {" +& ty_str1 +& "} " +& index +& " loop\n  ";
        eql_str = stringDelimitList(List.map(eql, printEquation), "\n");
        res = res +& eql_str +& "\n  end for;\n";
      then
        res;

    else "UNKNOWN EQUATION";
  end match;
end printEquation;

end InstUtil;
