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

encapsulated package Typing
" file:        Typing.mo
  package:     Typing
  description: SCodeInst typing.

  RCS: $Id$

  Functions used by SCodeInst for typing.
"

public import Absyn;
public import DAE;
public import InstSymbolTable;
public import InstTypes;
public import SCode;

protected import ComponentReference;
protected import Connect;
protected import DAEUtil;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import InstUtil;
protected import List;
protected import Types;
protected import Util;

public type Element = InstTypes.Element;
public type Equation = InstTypes.Equation;
public type Class = InstTypes.Class;
public type Dimension = InstTypes.Dimension;
public type Binding = InstTypes.Binding;
public type Component = InstTypes.Component;
public type Modifier = InstTypes.Modifier;
public type ParamType = InstTypes.ParamType;
public type Prefixes = InstTypes.Prefixes;
public type Prefix = InstTypes.Prefix;
public type SymbolTable = InstSymbolTable.SymbolTable;

public uniontype EvalPolicy
  record NO_EVAL end NO_EVAL;
  record EVAL_CONST end EVAL_CONST;
  record EVAL_CONST_PARAM end EVAL_CONST_PARAM;
end EvalPolicy;

public function typeClass
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inSymbolTable)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;
      SymbolTable st;

    case (InstTypes.BASIC_TYPE(), st) then (inClass, st);

    case (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st)
      equation
        (comps, st) = List.mapFold(comps, typeElement, st);
      then
        (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st);

  end match;
end typeClass;

protected function typeElement
  input Element inElement;
  input SymbolTable inSymbolTable;
  output Element outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) := match(inElement, inSymbolTable)
    local
      Component comp;
      Class cls;
      Absyn.Path name;
      SymbolTable st;
      DAE.Type ty;

    case (InstTypes.ELEMENT(comp as InstTypes.UNTYPED_COMPONENT(name = name), cls), st)
      equation
        comp = InstSymbolTable.lookupName(name, st); 
        (comp, st) = typeComponent(comp, st);
        (cls, st) = typeClass(cls, st);
      then
        (InstTypes.ELEMENT(comp, cls), st);

    case (InstTypes.ELEMENT(comp, cls), st)
      equation
        (cls, st) = typeClass(cls, st);
      then
        (InstTypes.ELEMENT(comp, cls), st);

    case (InstTypes.EXTENDED_ELEMENTS(name, cls, ty), st)
      equation
        (cls, st) = typeClass(cls, st);
      then
        (InstTypes.EXTENDED_ELEMENTS(name, cls, ty), st);

    else (inElement, inSymbolTable);

  end match;
end typeElement;

protected function typeComponent
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) := match(inComponent, inSymbolTable)
    local
      Absyn.Path name, inner_name;
      DAE.Type ty;
      Binding binding;
      list<Dimension> dims;
      SymbolTable st;
      Component comp, inner_comp;
      SCode.Variability var;

    case (InstTypes.UNTYPED_COMPONENT(name = name, baseType = ty, binding = binding), st)
      equation
        (ty, st) = typeComponentDims(inComponent, st);
        (comp, st ) = typeComponentBinding(inComponent, SOME(ty), st);
      then
        (comp, st);

    case (InstTypes.TYPED_COMPONENT(name = _), st) then (inComponent, st);

    case (InstTypes.OUTER_COMPONENT(innerName = SOME(name)), st)
      equation
        comp = InstSymbolTable.lookupName(name, st);
        (comp, st) = typeComponent(comp, st);
      then
        (comp, st);

    case (InstTypes.OUTER_COMPONENT(name = name, innerName = NONE()), st)
      equation
        (_, SOME(inner_comp), st) = InstSymbolTable.updateInnerReference(inComponent, st);
        (inner_comp, st) = typeComponent(inner_comp, st);
      then
        (inner_comp, st);

    case (InstTypes.CONDITIONAL_COMPONENT(name = name), _)
      equation
        print("Trying to type conditional component " +& Absyn.pathString(name) +& "\n");
      then
        fail();

  end match;
end typeComponent;

protected function typeComponentDims
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outType, outSymbolTable) := matchcontinue(inComponent, inSymbolTable)
    local
      DAE.Type ty;
      SymbolTable st;
      array<Dimension> dims;
      list<DAE.Dimension> typed_dims;
      Absyn.Path name;

    case (InstTypes.UNTYPED_COMPONENT(baseType = ty, dimensions = dims), st)
      equation
        true = intEq(0, arrayLength(dims));
      then
        (ty, st);

    case (InstTypes.UNTYPED_COMPONENT(name = name, baseType = ty, dimensions = dims), st)
      equation
        (typed_dims, st) = typeDimensions(dims, name, st);
      then
        (DAE.T_ARRAY(ty, typed_dims, DAE.emptyTypeSource), st);
        
    case (InstTypes.TYPED_COMPONENT(ty = ty), st) then (ty, st);

  end matchcontinue;
end typeComponentDims;

protected function typeComponentDim
  input Component inComponent;
  input Integer inIndex;
  input SymbolTable inSymbolTable;
  output DAE.Dimension outDimension;
  output SymbolTable outSymbolTable;
algorithm
  (outDimension, outSymbolTable) := match(inComponent, inIndex, inSymbolTable)
    local
      list<DAE.Dimension> dims;
      DAE.Dimension typed_dim;
      SymbolTable st;
      array<Dimension> dims_arr;
      Dimension dim;
      Absyn.Path name;

    case (InstTypes.TYPED_COMPONENT(ty = DAE.T_ARRAY(dims = dims)), _, st)
      equation
        typed_dim = listGet(dims, inIndex);
      then
        (typed_dim, st);

    case (InstTypes.UNTYPED_COMPONENT(name = name, dimensions = dims_arr), _, st)
      equation
        dim = arrayGet(dims_arr, inIndex);
        (typed_dim, st) = typeDimension(dim, name, st, dims_arr, inIndex);
      then
        (typed_dim, st);

  end match;
end typeComponentDim;
        
protected function typeDimensions
  input array<Dimension> inDimensions;
  input Absyn.Path inComponentName;
  input SymbolTable inSymbolTable;
  output list<DAE.Dimension> outDimensions;
  output SymbolTable outSymbolTable;
protected
  Integer len;
algorithm
  len := arrayLength(inDimensions);
  (outDimensions, outSymbolTable) := 
  typeDimensions2(inDimensions, inComponentName, inSymbolTable, 1, len, {});
end typeDimensions;

protected function typeDimensions2
  input array<Dimension> inDimensions;
  input Absyn.Path inComponentName;
  input SymbolTable inSymbolTable;
  input Integer inIndex;
  input Integer inLength;
  input list<DAE.Dimension> inAccDims;
  output list<DAE.Dimension> outDimensions;
  output SymbolTable outSymbolTable;
algorithm
  (outDimensions, outSymbolTable) :=
  matchcontinue(inDimensions, inComponentName, inSymbolTable, inIndex, inLength, inAccDims)
    local
      Dimension dim;
      DAE.Dimension typed_dim;
      SymbolTable st;
      list<DAE.Dimension> dims;

    case (_, _, _, _, _, _)
      equation
        true = inIndex > inLength;
      then
        (listReverse(inAccDims), inSymbolTable);

    else
      equation
        dim = arrayGet(inDimensions, inIndex);
        (typed_dim, st) = 
          typeDimension(dim, inComponentName, inSymbolTable, inDimensions, inIndex);
        (dims, st) = typeDimensions2(inDimensions, inComponentName, st, inIndex + 1,
          inLength, typed_dim :: inAccDims);
      then
        (dims, st);

  end matchcontinue;
end typeDimensions2;

protected function typeDimension
  input Dimension inDimension;
  input Absyn.Path inComponentName;
  input SymbolTable inSymbolTable;
  input array<Dimension> inDimensions;
  input Integer inIndex;
  output DAE.Dimension outDimension;
  output SymbolTable outSymbolTable;
algorithm
  (outDimension, outSymbolTable) := 
  match(inDimension, inComponentName, inSymbolTable, inDimensions, inIndex)
    local
      SymbolTable st;
      DAE.Dimension dim;
      DAE.Exp dim_exp;
      Integer dim_int, dim_count;
      Dimension typed_dim;
      Component comp;

    case (InstTypes.UNTYPED_DIMENSION(isProcessing = true), _, _, _, _)
      equation
        print("Found dimension loop\n");
      then
        fail();

    case (InstTypes.UNTYPED_DIMENSION(dimension = dim as DAE.DIM_EXP(exp = dim_exp)), _, st, _, _)
      equation
        _ = arrayUpdate(inDimensions, inIndex, InstTypes.UNTYPED_DIMENSION(dim, true));
        (dim_exp, _, st) = typeExp(dim_exp, EVAL_CONST_PARAM(), st);
        dim = InstUtil.makeDimension(dim_exp);
        typed_dim = InstTypes.TYPED_DIMENSION(dim);
        _ = arrayUpdate(inDimensions, inIndex, typed_dim);
      then
        (dim, st);

    case (InstTypes.UNTYPED_DIMENSION(dimension = dim as DAE.DIM_UNKNOWN()), _, st, _, _)
      equation
        _ = arrayUpdate(inDimensions, inIndex, InstTypes.UNTYPED_DIMENSION(dim, true));
        comp = InstSymbolTable.lookupName(inComponentName, st);
        (comp, st) = typeComponentBinding(comp, NONE(), st);
        dim_count = arrayLength(inDimensions);
        dim = InstUtil.getComponentBindingDimension(comp, inIndex, dim_count);
        typed_dim = InstTypes.TYPED_DIMENSION(dim);
        _ = arrayUpdate(inDimensions, inIndex, typed_dim);
      then
        (dim, st);

    case (InstTypes.UNTYPED_DIMENSION(dimension = dim), _, st, _, _)
      equation
        _ = arrayUpdate(inDimensions, inIndex, InstTypes.TYPED_DIMENSION(dim));
      then 
        (dim, st);

    case (InstTypes.TYPED_DIMENSION(dimension = dim), _, st, _, _) then (dim, st);

    else
      equation
        print("typeDimension got unknown dimension\n");
      then
        fail();

  end match;
end typeDimension;
   
protected function typeComponentBinding
  input Component inComponent;
  input Option<DAE.Type> inType;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) := match(inComponent, inType, inSymbolTable)
    local
      Binding binding;
      SymbolTable st;
      Component comp;
      EvalPolicy ep;

    case (InstTypes.UNTYPED_COMPONENT(binding = binding), _, st)
      equation
        st = markComponentBindingAsProcessing(inComponent, st);
        ep = getEvalPolicyForBinding(inComponent);
        (binding, st) = typeBinding(binding, ep, st);
        comp = updateComponentBinding(inComponent, binding, inType);
        st = InstSymbolTable.updateComponent(comp, st);
      then
        (comp, st);

    else (inComponent, inSymbolTable);

  end match;
end typeComponentBinding;

protected function getEvalPolicyForBinding
  input Component inComponent;
  output EvalPolicy outEvalPolicy;
algorithm
  outEvalPolicy := match(inComponent)
    case InstTypes.UNTYPED_COMPONENT(paramType = InstTypes.STRUCT_PARAM())
      then EVAL_CONST_PARAM();

    else EVAL_CONST();
  end match;
end getEvalPolicyForBinding;

protected function updateComponentBinding
  input Component inComponent;
  input Binding inBinding;
  input Option<DAE.Type> inType;
  output Component outComponent;
algorithm
  outComponent := match(inComponent, inBinding, inType)
    local
      Absyn.Path name;
      DAE.Type ty;
      Prefixes pf;
      ParamType pty;
      SCode.Element el;
      array<Dimension> dims;
      Absyn.Info info;
     
    case (InstTypes.UNTYPED_COMPONENT(name = name, prefixes = pf, info = info), _, SOME(ty))
      then InstTypes.TYPED_COMPONENT(name, ty, pf, inBinding, info);

    case (InstTypes.UNTYPED_COMPONENT(name, ty, dims, pf, pty, _, info), _, NONE())
      then InstTypes.UNTYPED_COMPONENT(name, ty, dims, pf, pty, inBinding, info);

  end match;
end updateComponentBinding;

protected function markComponentBindingAsProcessing
  input Component inComponent;
  input SymbolTable inSymbolTable;
  output SymbolTable outSymbolTable;
algorithm
  outSymbolTable := matchcontinue(inComponent, inSymbolTable)
    local
      Absyn.Path name;
      SCode.Element el;
      DAE.Type ty;
      array<Dimension> dims;
      Binding binding;
      Component comp;
      DAE.VarKind var;
      DAE.Exp binding_exp;
      Integer pl;
      Prefixes pf;
      ParamType pty;
      Absyn.Info info1, info2;

    case (InstTypes.UNTYPED_COMPONENT(prefixes = InstTypes.PREFIXES(variability = var)), _)
      equation
        false = DAEUtil.isParamOrConstVarKind(var);
      then
        inSymbolTable;

    case (InstTypes.UNTYPED_COMPONENT(name, ty, dims, pf, pty,
        InstTypes.UNTYPED_BINDING(binding_exp, _, pl, info1), info2), _)
      equation
        comp = InstTypes.UNTYPED_COMPONENT(name, ty, dims, pf, pty,
          InstTypes.UNTYPED_BINDING(binding_exp, true, pl, info1), info2);
      then
        InstSymbolTable.updateComponent(comp, inSymbolTable);

    case (InstTypes.UNTYPED_COMPONENT(binding = _), _) then inSymbolTable;

    else
      equation
        print("markComponentAsProcessing got unknown component\n");
      then
        fail();

  end matchcontinue;
end markComponentBindingAsProcessing;
      
protected function typeBinding
  input Binding inBinding;
  input EvalPolicy inEvalPolicy;
  input SymbolTable inSymbolTable;
  output Binding outBinding;
  output SymbolTable outSymbolTable;
algorithm
  (outBinding, outSymbolTable) := match(inBinding, inEvalPolicy, inSymbolTable)
    local
      DAE.Exp binding;
      SymbolTable st;
      DAE.Type ty;
      Integer pd;
      Absyn.Info info;

    case (InstTypes.UNTYPED_BINDING(isProcessing = true), _, st)
      equation
        InstSymbolTable.showCyclicDepError(st);
      then
        fail();

    case (InstTypes.UNTYPED_BINDING(bindingExp = binding, propagatedDims = pd,
        info = info), _, st)
      equation
        (binding, ty, st) = typeExp(binding, inEvalPolicy, st);
      then
        (InstTypes.TYPED_BINDING(binding, ty, pd, info), st);

    case (InstTypes.TYPED_BINDING(bindingExp = _), _, st)
      then (inBinding, st);

    else (InstTypes.UNBOUND(), inSymbolTable);

  end match;
end typeBinding;

protected function typeExpList
  input list<DAE.Exp> inExpList;
  input EvalPolicy inEvalPolicy;
  input SymbolTable inSymbolTable;
  output list<DAE.Exp> outExpList;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExpList, outType, outSymbolTable) :=
  match(inExpList, inEvalPolicy, inSymbolTable)
    local
      DAE.Exp exp;
      list<DAE.Exp> rest_expl;
      EvalPolicy ep;
      SymbolTable st;
      DAE.Type ty;

    case ({}, _, st) then ({}, DAE.T_UNKNOWN_DEFAULT, st);

    case (exp :: rest_expl, ep, st)
      equation
        (exp, ty, st) = typeExp(exp, ep, st);
        (rest_expl, _, st) = typeExpList(rest_expl, ep, st);
      then
        (exp :: rest_expl, ty, st);

  end match;
end typeExpList;

public function typeExp
  input DAE.Exp inExp;
  input EvalPolicy inEvalPolicy;
  input SymbolTable inSymbolTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outSymbolTable) := match(inExp, inEvalPolicy, inSymbolTable)
    local
      DAE.Exp e1, e2, e3;
      DAE.ComponentRef cref;
      DAE.Type ty;
      SymbolTable st;
      DAE.Operator op;
      Component comp;
      Integer dim_int;
      DAE.Dimension dim;
      list<DAE.Exp> expl;
      EvalPolicy ep;

    case (DAE.ICONST(integer = _), _, st) then (inExp, DAE.T_INTEGER_DEFAULT, st);
    case (DAE.RCONST(real = _), _, st) then (inExp, DAE.T_REAL_DEFAULT, st);
    case (DAE.SCONST(string = _), _, st) then (inExp, DAE.T_STRING_DEFAULT, st);
    case (DAE.BCONST(bool = _), _, st) then (inExp, DAE.T_BOOL_DEFAULT, st);
    case (DAE.CREF(componentRef = cref), ep, st)
      equation
        (e1, ty, st) = typeCref(cref, ep, st);
      then
        (e1, ty, st);
        
    case (DAE.ARRAY(array = expl), ep, st)
      equation
        (expl, ty, st) = typeExpList(expl, ep, st);
        dim_int = listLength(expl);
        ty = DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(dim_int)}, DAE.emptyTypeSource);
      then
        (DAE.ARRAY(ty, true, expl), ty, st);

    case (DAE.BINARY(exp1 = e1, operator = op, exp2 = e2), ep, st)
      equation
        (e1, ty, st) = typeExp(e1, ep, st);
        (e2, ty, st) = typeExp(e2, ep, st);
      then
        (DAE.BINARY(e1, op, e2), ty, st);

    case (DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2), ep, st)
      equation
        (e1, ty, st) = typeExp(e1, ep, st);
        (e2, ty, st) = typeExp(e2, ep, st);
      then
        (DAE.LBINARY(e1, op, e2), ty, st);

    case (DAE.LUNARY(operator = op, exp = e1), ep, st)
      equation
        (e1, ty, st) = typeExp(e1, ep, st);
      then
        (DAE.LUNARY(op, e1), ty, st);

    case (DAE.SIZE(exp = DAE.CREF(componentRef = cref), sz = SOME(e2)), ep, st)
      equation
        (DAE.ICONST(dim_int), _, st) = typeExp(e2, EVAL_CONST_PARAM(), st);
        comp = InstSymbolTable.lookupCref(cref, st);
        (dim, st) = typeComponentDim(comp, dim_int, st);
        e1 = dimensionExp(dim);
      then
        (e1, DAE.T_INTEGER_DEFAULT, st);

    else (inExp, DAE.T_UNKNOWN_DEFAULT, inSymbolTable);
    //else
    //  equation
    //    print("typeExp: unknown expression " +&
    //        ExpressionDump.printExpStr(inExp) +& "\n");
    //  then
    //    fail();

  end match;
end typeExp;
    
protected function dimensionExp
  input DAE.Dimension inDimension;
  output DAE.Exp outExp;
algorithm
  outExp := match(inDimension)
    local
      Integer dim_int;
      DAE.Exp dim_exp;

    case (DAE.DIM_INTEGER(dim_int)) then DAE.ICONST(dim_int);
    case (DAE.DIM_EXP(dim_exp)) then dim_exp;

  end match;
end dimensionExp;
  
protected function typeCref
  input DAE.ComponentRef inCref;
  input EvalPolicy inEvalPolicy;
  input SymbolTable inSymbolTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outSymbolTable) :=
  matchcontinue(inCref, inEvalPolicy, inSymbolTable)
    local
      Absyn.Path path;
      SymbolTable st;
      Component comp;
      DAE.Type ty;
      DAE.Exp exp;
      DAE.VarKind var;
      Boolean eval;
      DAE.ComponentRef cref;
      EvalPolicy ep;

    case (_, ep, st)
      equation
        comp = InstSymbolTable.lookupCref(inCref, st);
        var = InstUtil.getEffectiveComponentVariability(comp);
        eval = shouldEvaluate(var, ep);
        (exp, ty, st) = typeCref2(inCref, comp, eval, ep, st);
      then
        (exp, ty, st);

    case (_, ep, st)
      equation
        (cref, st) = InstUtil.replaceCrefOuterPrefix(inCref, st);
        (exp, ty, st) = typeCref(cref, ep, st);
      then
        (exp, ty, st);

    else
      equation
        print("Failed to type cref " +&
            ComponentReference.printComponentRefStr(inCref) +& "\n");
      then
        fail();

  end matchcontinue;
end typeCref;
       
protected function shouldEvaluate
  input DAE.VarKind inVarKind;
  input EvalPolicy inEvalPolicy;
  output Boolean outShouldEval;
algorithm
  outShouldEval := match(inVarKind, inEvalPolicy)
    case (DAE.PARAM(), EVAL_CONST_PARAM()) then true;
    case (_, NO_EVAL()) then false;
    case (DAE.CONST(), _) then true;
    else false;
  end match;
end shouldEvaluate;

protected function typeCref2
  input DAE.ComponentRef inCref;
  input Component inComponent;
  input Boolean inShouldEvaluate;
  input EvalPolicy inEvalPolicy;
  input SymbolTable inSymbolTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outSymbolTable) :=
  matchcontinue(inCref, inComponent, inShouldEvaluate, inEvalPolicy, inSymbolTable)
    local
      DAE.Type ty;
      Binding binding;
      SymbolTable st;
      DAE.Exp exp;
      Absyn.Path inner_name;
      Component inner_comp;
      DAE.ComponentRef inner_cref;
      EvalPolicy ep;
      Boolean se;

    case (_, InstTypes.TYPED_COMPONENT(ty = ty, binding = binding), true, _, st)
      equation
        exp = InstUtil.getBindingExp(binding);
        // TODO: Apply cref subscripts to the expression.
      then
        (exp, ty, st);

    case (_, InstTypes.TYPED_COMPONENT(ty = ty), false, _, st)
      equation
        ty = propagateCrefSubsToType(ty, inCref);
      then
        (DAE.CREF(inCref, ty), ty, st);

    case (_, InstTypes.UNTYPED_COMPONENT(name = _), true, _, st)
      equation
        (InstTypes.TYPED_COMPONENT(ty = ty, binding = binding), st) =
          typeComponent(inComponent, st);
        exp = InstUtil.getBindingExp(binding);
        // TODO: Apply cref subscripts to the expression.
      then
        (exp, ty, st);

    case (_, InstTypes.UNTYPED_COMPONENT(name = _), false, _, st)
      equation
        (ty, st) = typeComponentDims(inComponent, st);
        ty = propagateCrefSubsToType(ty, inCref);
      then
        (DAE.CREF(inCref, ty), ty, st);

    case (_, InstTypes.OUTER_COMPONENT(name = _), se, ep, st)
      equation
        (inner_comp, st) = typeComponent(inComponent, st);
        inner_name = InstUtil.getComponentName(inner_comp);
        inner_cref = InstUtil.removeCrefOuterPrefix(inner_name, inCref);
        (exp, ty, st) = typeCref2(inner_cref, inner_comp, se, ep, st);
      then
        (exp, ty, st);

  end matchcontinue;
end typeCref2;

protected function propagateCrefSubsToType
  input DAE.Type inType;
  input DAE.ComponentRef inCref;
  output DAE.Type outType;
algorithm
  outType := match(inType, inCref)
    local
      DAE.Type ty;
      DAE.Dimensions dims;
      DAE.TypeSource src;

    case (DAE.T_ARRAY(ty, dims, src), _)
      equation
        ty = propagateCrefSubsToType(ty, inCref);
        dims = List.map1(dims, propagateCrefSubsToDimension, inCref);
      then
        DAE.T_ARRAY(ty, dims, src);

    else inType;

  end match;
end propagateCrefSubsToType;

protected function propagateCrefSubsToDimension
  input DAE.Dimension inDimension;
  input DAE.ComponentRef inCref;
  output DAE.Dimension outDimension;
algorithm
  outDimension := match(inDimension, inCref)
    local
      DAE.Exp exp;
      
    case (DAE.DIM_EXP(exp = exp), _)
      equation
        ((exp, _)) = Expression.traverseExp(exp, 
          propagateCrefSubsToExpTraverser, inCref);
      then
        DAE.DIM_EXP(exp);

    else inDimension;
  end match;
end propagateCrefSubsToDimension;
  
protected function propagateCrefSubsToExpTraverser
  input tuple<DAE.Exp, DAE.ComponentRef> inTuple;
  output tuple<DAE.Exp, DAE.ComponentRef> outTuple;
algorithm
  outTuple := match(inTuple)
    local
      DAE.ComponentRef cref1, cref2;
      DAE.Type ty;

    case ((DAE.CREF(cref1, ty), cref2))
      equation
        cref1 = propagateCrefSubsToCref(cref1, cref2);
        ty = propagateCrefSubsToType(ty, cref2);
      then
        ((DAE.CREF(cref1, ty), cref2));

    else inTuple;
  end match;
end propagateCrefSubsToExpTraverser;

protected function propagateCrefSubsToCref
  input DAE.ComponentRef inDstCref;
  input DAE.ComponentRef inSrcCref;
  output DAE.ComponentRef outDstCref;
algorithm
  outDstCref := matchcontinue(inDstCref, inSrcCref)
    local
      DAE.Ident id1, id2;
      DAE.Type ty;
      list<DAE.Subscript> subs;
      DAE.ComponentRef cref1, cref2;

    case (DAE.CREF_QUAL(id1, ty, {}, cref1), 
          DAE.CREF_QUAL(id2, _, subs, cref2))
      equation
        true = stringEq(id1, id2);
        cref1 = propagateCrefSubsToCref(cref1, cref2);
      then
        DAE.CREF_QUAL(id1, ty, subs, cref1);

    else inDstCref;
  end matchcontinue;
end propagateCrefSubsToCref;

public function typeSections
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Class outClass;
algorithm
  outClass := match(inClass, inSymbolTable)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<SCode.AlgorithmSection> al, ial;
      SymbolTable st;

    case (InstTypes.BASIC_TYPE(), _) then inClass;

    case (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st)
      equation
        comps = List.map1(comps, typeSectionsInElement, st);
        eq = typeEquations(eq, st);
        ieq = typeEquations(ieq, st);
      then
        InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial);

  end match;
end typeSections;

protected function typeSectionsInElement
  input Element inElement;
  input SymbolTable inSymbolTable;
  output Element outElement;
algorithm
  outElement := match(inElement, inSymbolTable)
    local
      Component comp;
      Class cls;
      Absyn.Path bc;
      DAE.Type ty;
      SymbolTable st;

    case (InstTypes.ELEMENT(comp, cls), st)
      equation
        cls = typeSections(cls, st);
      then
        InstTypes.ELEMENT(comp, cls);

    case (InstTypes.EXTENDED_ELEMENTS(bc, cls, ty), st)
      equation
        cls = typeSections(cls, st);
      then
        InstTypes.EXTENDED_ELEMENTS(bc, cls, ty);

    case (InstTypes.CONDITIONAL_ELEMENT(_), st)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Typing.typeSectionsInElement got a conditional element!"});
      then
        fail();

  end match;
end typeSectionsInElement;

protected function typeEquations
  input list<Equation> inEquation;
  input SymbolTable inSymbolTable;
  output list<Equation> outEquation;
algorithm
  outEquation := List.map1(inEquation, typeEquation, inSymbolTable);
end typeEquations;

protected function typeEquation
  input Equation inEquation;
  input SymbolTable inSymbolTable;
  output Equation outEquation;
algorithm
  outEquation := match(inEquation, inSymbolTable)
    local
      DAE.Exp rhs, lhs, exp1, exp2;
      SymbolTable st;
      Absyn.Info info;
      DAE.ComponentRef cref1, cref2;
      Connect.Face face1, face2;
      Prefix prefix;
      String index;
      list<Equation> eql;
      DAE.Type ty;

    case (InstTypes.EQUALITY_EQUATION(lhs, rhs, info), st)
      equation
        (rhs, _, _) = typeExp(rhs, NO_EVAL(), st);
        (lhs, _, _) = typeExp(lhs, NO_EVAL(), st);
      then
        InstTypes.EQUALITY_EQUATION(lhs, rhs, info);

    case (InstTypes.CONNECT_EQUATION(cref1, _, cref2, _, prefix, info), st)
      equation
        (cref1, face1) = lookupConnector(cref1, prefix, st, info);
        (cref2, face2) = lookupConnector(cref2, prefix, st, info);
      then
        InstTypes.CONNECT_EQUATION(cref1, face1, cref2, face2,
          InstTypes.emptyPrefix, info);

    case (InstTypes.FOR_EQUATION(index, _, exp1, eql, info), st)
      equation
        (exp1, ty, _) = typeExp(exp1, EVAL_CONST_PARAM(), st);
        ty = rangeToIteratorType(ty, exp1, info);
        eql = typeEquations(eql, st);
      then
        InstTypes.FOR_EQUATION(index, ty, exp1, eql, info);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Typing.typeEquation got an unknown equation type!"});
      then
        fail();

  end match;
end typeEquation;

protected function lookupConnector
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input SymbolTable inSymbolTable;
  input Absyn.Info inInfo;
  output DAE.ComponentRef outCref;
  output Connect.Face outFace;
algorithm
  (outCref, outFace) := matchcontinue(inCref, inPrefix, inSymbolTable, inInfo)
    local
      DAE.ComponentRef cref, cref2;
      Component comp;
      DAE.Type ty;
      String cref_str;
      Boolean is_conn;
      Connect.Face face;

    // A simple identifier is always outside if it's a valid connector.
    case (DAE.CREF_IDENT(ident = _), _, _, _)
      equation
        cref = InstUtil.prefixCref(inCref, inPrefix);
        comp = lookupConnectorCref(cref, inSymbolTable, inInfo);
        checkComponentIsConnector(comp, cref, inInfo);
      then
        (cref, Connect.OUTSIDE());

    case (DAE.CREF_QUAL(ident = _), _, _, _)
      equation
        (cref, cref2) = ComponentReference.splitCrefFirst(inCref);
        cref = InstUtil.prefixCref(cref, inPrefix);
        comp = lookupConnectorCref(cref, inSymbolTable, inInfo);
        is_conn = InstUtil.isConnectorComponent(comp);
        face = Util.if_(is_conn, Connect.OUTSIDE(), Connect.INSIDE());
        cref = ComponentReference.joinCrefs(cref, cref2);
        comp = lookupConnectorCref(cref, inSymbolTable, inInfo);
        checkComponentIsConnector(comp, cref, inInfo);
      then
        (cref, face);

  end matchcontinue;
end lookupConnector;

protected function lookupConnectorCref
  input DAE.ComponentRef inCref;
  input SymbolTable inSymbolTable;
  input Absyn.Info inInfo;
  output Component outComponent;
algorithm
  outComponent := matchcontinue(inCref, inSymbolTable, inInfo)
    local
      Component comp;
      String cref_str;

    case (inCref, inSymbolTable, inInfo)
      equation
        comp = InstSymbolTable.lookupCref(inCref, inSymbolTable);
      then
        comp;

    else
      equation
        cref_str = ComponentReference.printComponentRefStr(inCref);
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR,
          {cref_str, ""}, inInfo);
      then
        fail();

  end matchcontinue;
end lookupConnectorCref;

protected function checkComponentIsConnector
  input InstTypes.Component inComponent;
  input DAE.ComponentRef inCref;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inComponent, inCref, inInfo)
    local
      String cref_str;

    case (_, _, _)
      equation
        true = InstUtil.isConnectorComponent(inComponent);
      then
        ();

    else
      equation
        cref_str = ComponentReference.printComponentRefStr(inCref);
        Error.addSourceMessage(Error.INVALID_CONNECTOR_TYPE,
          {cref_str}, inInfo);
      then
        fail();

  end matchcontinue;
end checkComponentIsConnector;

protected function rangeToIteratorType
  input DAE.Type inRangeType;
  input DAE.Exp inRangeExp;
  input Absyn.Info inInfo;
  output DAE.Type outIteratorType;
algorithm
  outIteratorType := matchcontinue(inRangeType, inRangeExp, inInfo) 
    local
      String ty_str, exp_str;

    case (_, _, _)
      then Types.unliftArray(inRangeType);

    else
      equation
        ty_str = Types.unparseType(inRangeType);
        exp_str = ExpressionDump.printExpStr(inRangeExp);
        Error.addSourceMessage(Error.FOR_EXPRESSION_TYPE_ERROR,
          {exp_str, ty_str}, inInfo);
      then
        fail();

  end matchcontinue;
end rangeToIteratorType;

end Typing;
