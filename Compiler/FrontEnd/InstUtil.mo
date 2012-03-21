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
public import DAE;
public import InstSymbolTable;
public import InstTypes;
public import SCode;
public import SCodeEnv;

protected import ComponentReference;
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
public type Dimension = InstTypes.Dimension;
public type Element = InstTypes.Element;
public type Env = SCodeEnv.Env;
public type Equation = InstTypes.Equation;
public type Modifier = InstTypes.Modifier;
public type Prefixes = InstTypes.Prefixes;
public type Prefix = InstTypes.Prefix;
public type SymbolTable = InstSymbolTable.SymbolTable;

public function makeClass
  input list<Element> inElements;
  input list<Equation> inEquations;
  input list<Equation> inInitialEquations;
  input list<SCode.AlgorithmSection> inAlgorithms;
  input list<SCode.AlgorithmSection> inInitialAlgorithms;
  input Boolean inContainsSpecialExtends;
  output Class outClass;
  output DAE.Type outClassType;
algorithm
  (outClass, outClassType) := match(inElements, inEquations, inInitialEquations,
      inAlgorithms, inInitialAlgorithms, inContainsSpecialExtends)
    local
      list<Element> elems;
      list<Equation> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;
      Class cls;
      DAE.Type ty;

    case (elems, eq, ieq, al, ial, false)
      then (InstTypes.COMPLEX_CLASS(elems, eq, ieq, al, ial), DAE.T_COMPLEX_DEFAULT);

    case (_, {}, {}, {}, {}, true)
      equation
        (InstTypes.EXTENDED_ELEMENTS(cls = cls, ty = ty), elems) =
          getSpecialExtends(inElements);
      then
        (cls, ty);

  end match;
end makeClass;

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
      Binding binding;
      Absyn.Info info;
      SCode.Element elem;
      Modifier mod;
      Env env;
      Prefix prefix;
      Option<Absyn.Path> inner_name;

    case (InstTypes.UNTYPED_COMPONENT(_, ty, dims, prefs, binding, info), _)
      then InstTypes.UNTYPED_COMPONENT(inName, ty, dims, prefs, binding, info);

    case (InstTypes.TYPED_COMPONENT(_, ty, prefs, binding, info), _)
      then InstTypes.TYPED_COMPONENT(inName, ty, prefs, binding, info);

    case (InstTypes.CONDITIONAL_COMPONENT(_, elem, mod, prefs, env, prefix), _)
      then InstTypes.CONDITIONAL_COMPONENT(inName, elem, mod, prefs, env, prefix);

    case (InstTypes.OUTER_COMPONENT(_, inner_name), _)
      then InstTypes.OUTER_COMPONENT(inName, inner_name);

    case (InstTypes.PACKAGE(_), _)
      then InstTypes.PACKAGE(inName);

  end match;
end setComponentName;
    
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
 
public function getComponentVariability
  input Component inComponent;
  output DAE.VarKind outVariability;
algorithm
  outVariability := match(inComponent)
    local
      DAE.VarKind var;

    case InstTypes.UNTYPED_COMPONENT(prefixes = InstTypes.PREFIXES(variability = var)) then var;
    case InstTypes.TYPED_COMPONENT(prefixes = InstTypes.PREFIXES(variability = var)) then var;
    else DAE.VARIABLE();

  end match;
end getComponentVariability;

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
    InstTypes.DEFAULT_CONST_PREFIXES, binding, Absyn.dummyInfo);
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
  
public function mergePrefixes
  input Absyn.Path inComponentName;
  input SCode.Prefixes inInnerPrefixes;
  input SCode.Attributes inAttributes;
  input Prefixes inOuterPrefixes;
  input Absyn.Info inInfo;
  output Prefixes outPrefixes;
algorithm
  outPrefixes :=
  match(inComponentName, inInnerPrefixes, inAttributes, inOuterPrefixes, inInfo)
    local
      SCode.Visibility vis1;
      DAE.VarVisibility vis2;
      SCode.Variability var1;
      DAE.VarKind var2;
      SCode.Final fp1, fp2;
      Absyn.InnerOuter io;
      Absyn.Direction dir1;
      tuple<DAE.VarDirection, Absyn.Info> dir2;
      SCode.Flow flp1;
      tuple<DAE.Flow, Absyn.Info> flp2;
      SCode.Stream sp1;
      tuple<DAE.Stream, Absyn.Info> sp2;

    case (_, SCode.PREFIXES(SCode.PUBLIC(), _, SCode.NOT_FINAL(), Absyn.NOT_INNER_OUTER(), _), 
        SCode.ATTR(_, SCode.NOT_FLOW(), SCode.NOT_STREAM(), _, SCode.VAR(), Absyn.BIDIR()), _, _)
      then inOuterPrefixes;

    case (_, _, _, InstTypes.NO_PREFIXES(), _) 
      then makePrefixes(inInnerPrefixes, inAttributes, inInfo);

    case (_, SCode.PREFIXES(vis1, _, fp1, io, _), SCode.ATTR(_, flp1, sp1, _, var1, dir1),
        InstTypes.PREFIXES(vis2, var2, fp2, _, dir2, flp2, sp2), _)
      equation
        vis2 = mergeVisibility(vis1, vis2);
        var2 = mergeVariability(var1, var2);
        fp2 = mergeFinal(fp1, fp2);
        dir2 = mergeDirection(dir1, dir2, inComponentName, inInfo);
        (flp2, sp2) = mergeFlowStream(flp1, sp1, flp2, sp2, inComponentName, inInfo);
      then
        InstTypes.PREFIXES(vis2, var2, fp2, io, dir2, flp2, sp2);

  end match;
end mergePrefixes;

protected function makePrefixes
  input SCode.Prefixes inPrefixes;
  input SCode.Attributes inAttributes;
  input Absyn.Info inInfo;
  output Prefixes outPrefixes;
protected
  SCode.Visibility vis;
  DAE.VarVisibility dvis;
  SCode.Variability var;
  DAE.VarKind vkind;
  SCode.Final fp;
  Absyn.InnerOuter io;
  Absyn.Direction dir;
  DAE.VarDirection ddir;
  SCode.Flow flp;
  DAE.Flow dflp;
  SCode.Stream sp;
  DAE.Stream dsp;
algorithm
  SCode.PREFIXES(visibility = vis, finalPrefix = fp, innerOuter = io) := inPrefixes;
  SCode.ATTR(flowPrefix = flp, streamPrefix = sp, variability = var,
    direction = dir) := inAttributes;
  dvis := makeVarVisibility(vis);
  vkind := makeVarKind(var);
  ddir := makeVarDirection(dir);
  dflp := makeVarFlow(flp);
  dsp := makeVarStream(sp);
  outPrefixes := InstTypes.PREFIXES(dvis, vkind, fp, io, 
    (ddir, inInfo), (dflp, inInfo), (dsp, inInfo));
end makePrefixes;

protected function makeVarVisibility
  input SCode.Visibility inVisibility;
  output DAE.VarVisibility outVisibility;
algorithm
  outVisibility := match(inVisibility)
    case SCode.PUBLIC() then DAE.PUBLIC();
    else DAE.PROTECTED();
  end match;
end makeVarVisibility;

protected function makeVarKind
  input SCode.Variability inVariability;
  output DAE.VarKind outVariability;
algorithm
  outVariability := match(inVariability)
    case SCode.VAR() then DAE.VARIABLE();
    case SCode.PARAM() then DAE.PARAM();
    case SCode.CONST() then DAE.CONST();
    case SCode.DISCRETE() then DAE.DISCRETE();
  end match;
end makeVarKind;

protected function makeVarDirection
  input Absyn.Direction inDirection;
  output DAE.VarDirection outDirection;
algorithm
  outDirection := match(inDirection)
    case Absyn.BIDIR() then DAE.BIDIR();
    case Absyn.OUTPUT() then DAE.OUTPUT();
    case Absyn.INPUT() then DAE.INPUT();
  end match;
end makeVarDirection;

protected function makeVarFlow
  input SCode.Flow inFlow;
  output DAE.Flow outFlow;
algorithm
  outFlow := match(inFlow)
    case SCode.NOT_FLOW() then DAE.NON_CONNECTOR();
    else DAE.FLOW();
  end match;
end makeVarFlow;

protected function makeVarStream
  input SCode.Stream inStream;
  output DAE.Stream outStream;
algorithm
  outStream := match(inStream)
    case SCode.NOT_STREAM() then DAE.NON_STREAM_CONNECTOR();
    else DAE.STREAM();
  end match;
end makeVarStream;

protected function mergeVisibility
  input SCode.Visibility inInnerVisibility;
  input DAE.VarVisibility inOuterVisibility;
  output DAE.VarVisibility outVisibility;
algorithm
  outVisibility := match(inInnerVisibility, inOuterVisibility)
    case (_, DAE.PROTECTED()) then DAE.PROTECTED();
    else makeVarVisibility(inInnerVisibility);
  end match;
end mergeVisibility;

protected function mergeVariability
  input SCode.Variability inInnerVariability;
  input DAE.VarKind inOuterVariability;
  output DAE.VarKind outVariability;
algorithm
  outVariability := match(inInnerVariability, inOuterVariability)
    case (_, DAE.CONST()) then DAE.CONST();
    case (SCode.CONST(), _) then DAE.CONST();
    case (_, DAE.PARAM()) then DAE.PARAM();
    case (SCode.PARAM(), _) then DAE.PARAM();
    case (_, DAE.DISCRETE()) then DAE.DISCRETE();
    case (SCode.DISCRETE(), _) then DAE.DISCRETE();
    else DAE.VARIABLE();
  end match;
end mergeVariability;

protected function mergeFinal
  input SCode.Final inInnerFinal;
  input SCode.Final inOuterFinal;
  output SCode.Final outFinal;
algorithm
  outFinal := match(inInnerFinal, inOuterFinal)
    case (_, SCode.FINAL()) then SCode.FINAL();
    else inInnerFinal;
  end match;
end mergeFinal;

protected function mergeDirection
  input Absyn.Direction inInnerDirection;
  input tuple<DAE.VarDirection, Absyn.Info> inOuterDirection;
  input Absyn.Path inComponentName;
  input Absyn.Info inInfo;
  output tuple<DAE.VarDirection, Absyn.Info> outDirection;
algorithm
  outDirection := match(inInnerDirection, inOuterDirection, inComponentName, inInfo)
    local
      DAE.VarDirection dir;
      Absyn.Info info;
      String dir_str1, dir_str2, comp_name;

    case (Absyn.BIDIR(), _, _, _) then inOuterDirection;

    case (_, (DAE.BIDIR(), _), _, _)
      equation
        dir = makeVarDirection(inInnerDirection);
      then
        ((dir, inInfo));

    case (_, (dir, info), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        dir_str1 = varDirectionString(dir);
        dir_str2 = directionString(inInnerDirection);
        comp_name = Absyn.pathString(inComponentName);
        Error.addSourceMessage(Error.COMPONENT_INPUT_OUTPUT_MISMATCH,
          {dir_str1, comp_name, dir_str2}, info);
      then
        fail();

  end match;
end mergeDirection;

protected function mergeFlowStream
  input SCode.Flow inInnerFlow;
  input SCode.Stream inInnerStream;
  input tuple<DAE.Flow, Absyn.Info> inOuterFlow;
  input tuple<DAE.Stream, Absyn.Info> inOuterStream;
  input Absyn.Path inComponentName;
  input Absyn.Info inInfo;
  output tuple<DAE.Flow, Absyn.Info> outFlow;
  output tuple<DAE.Stream, Absyn.Info> outStream;
algorithm
  (outFlow, outStream) := matchcontinue(inInnerFlow, inInnerStream, inOuterFlow,
      inOuterStream, inComponentName, inInfo)
    local
      DAE.Flow fp;
      DAE.Stream sp;
      Absyn.Info info;
      String fp_str, sp_str, pf_str, comp_name;
      tuple<DAE.Flow, Absyn.Info> new_fp;
      tuple<DAE.Stream, Absyn.Info> new_sp;

    case (SCode.NOT_FLOW(), SCode.NOT_STREAM(), _, _, _, _) 
      then (inOuterFlow, inOuterStream);

    case (_, _, (fp, _), (sp, _), _, _)
      equation
        false = ((SCode.flowBool(inInnerFlow) or SCode.streamBool(inInnerStream)) and
                 (DAEUtil.isFlow(fp) or DAEUtil.isStream(sp)));
        new_fp = mergeFlow(inInnerFlow, inOuterFlow, inInfo);
        new_sp = mergeStream(inInnerStream, inOuterStream, inInfo);
      then
        (new_fp, new_sp);
        
    case (_, _, (DAE.FLOW(), info), _, _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        fp_str = SCodeDump.flowStr(inInnerFlow);
        sp_str = SCodeDump.streamStr(inInnerStream);
        pf_str = fp_str +& sp_str;
        comp_name = Absyn.pathString(inComponentName);
        Error.addSourceMessage(Error.INVALID_TYPE_PREFIX,
          {"flow", comp_name, pf_str}, info);
      then
        fail();

    case (_, _, _, (DAE.STREAM(), info), _, _)
      equation
        Error.addSourceMessage(Error.ERROR_FROM_HERE, {}, inInfo);
        fp_str = SCodeDump.flowStr(inInnerFlow);
        sp_str = SCodeDump.streamStr(inInnerStream);
        pf_str = fp_str +& sp_str;
        comp_name = Absyn.pathString(inComponentName);
        Error.addSourceMessage(Error.INVALID_TYPE_PREFIX,
          {"stream", comp_name, pf_str}, info);
      then
        fail();

  end matchcontinue;
end mergeFlowStream;

protected function mergeFlow
  input SCode.Flow inInnerFlow;
  input tuple<DAE.Flow, Absyn.Info> inOuterFlow;
  input Absyn.Info inInfo;
  output tuple<DAE.Flow, Absyn.Info> outFlow;
algorithm
  outFlow := match(inInnerFlow, inOuterFlow, inInfo)
    case (SCode.NOT_FLOW(), _, _) then inOuterFlow;
    else ((DAE.FLOW(), inInfo));
  end match;
end mergeFlow;

protected function mergeStream
  input SCode.Stream inInnerStream;
  input tuple<DAE.Stream, Absyn.Info> inOuterStream;
  input Absyn.Info inInfo;
  output tuple<DAE.Stream, Absyn.Info> outStream;
algorithm
  outStream := match(inInnerStream, inOuterStream, inInfo)
    case (SCode.NOT_STREAM(), _, _) then inOuterStream;
    else ((DAE.STREAM(), inInfo));
  end match;
end mergeStream;
   
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

protected function varDirectionString
  input DAE.VarDirection inDirection;
  output String outString;
algorithm
  outString := match(inDirection)
    case DAE.INPUT() then "input";
    case DAE.OUTPUT() then "output";
    else "";
  end match;
end varDirectionString;

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

    case InstTypes.TYPED_COMPONENT(prefixes = InstTypes.PREFIXES(innerOuter = io))
      then Absyn.isInner(io);

    case InstTypes.CONDITIONAL_COMPONENT(element = el)
      then SCode.isInnerComponent(el);
        
    else false;
  end match;
end isInnerComponent;

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
      String str1, str2;

    case (InstTypes.EQUALITY_EQUATION(rhs = exp1, lhs = exp2))
      equation
        str1 = ExpressionDump.printExpStr(exp1);
        str2 = ExpressionDump.printExpStr(exp2);
      then
        str1 +& " = " +& str2 +& ";";

    else "UNKNOWN EQUATION";
  end match;
end printEquation;

end InstUtil;
