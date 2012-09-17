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
public import Connect2;
public import DAE;
public import HashTablePathToFunction;
public import InstSymbolTable;
public import InstTypes;
public import SCode;

protected import BaseHashTable;
protected import ComponentReference;
protected import ConnectCheck;
protected import ConnectUtil2;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import InstUtil;
protected import List;
protected import Types;
protected import Util;

public type Binding = InstTypes.Binding;
public type Class = InstTypes.Class;
public type Component = InstTypes.Component;
public type Connections = Connect2.Connections;
public type Connector = Connect2.Connector;
public type ConnectorType = Connect2.ConnectorType;
public type DaePrefixes = InstTypes.DaePrefixes;
public type Dimension = InstTypes.Dimension;
public type Element = InstTypes.Element;
public type Equation = InstTypes.Equation;
public type Face = Connect2.Face;
public type Function = InstTypes.Function;
public type FunctionTable = HashTablePathToFunction.HashTable;
public type Modifier = InstTypes.Modifier;
public type ParamType = InstTypes.ParamType;
public type Prefixes = InstTypes.Prefixes;
public type Prefix = InstTypes.Prefix;
public type Statement = InstTypes.Statement;
public type SymbolTable = InstSymbolTable.SymbolTable;

public uniontype Context
  record CONTEXT_MODEL end CONTEXT_MODEL;
  record CONTEXT_FUNCTION end CONTEXT_FUNCTION;
end Context;

public uniontype EvalPolicy
  record NO_EVAL end NO_EVAL;
  record EVAL_CONST end EVAL_CONST;
  record EVAL_CONST_PARAM end EVAL_CONST_PARAM;
end EvalPolicy;

public function typeClass
  input Class inClass;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) :=
    typeClass2(inClass, NONE(), inContext, inSymbolTable);
end typeClass;

public function typeClass2
  input Class inClass;
  input Option<Component> inParent;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inParent, inContext, inSymbolTable)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<list<Statement>> al, ial;
      SymbolTable st;

    case (InstTypes.BASIC_TYPE(), _, _, st) then (inClass, st);

    case (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), _, _, st)
      equation
        (comps, st) = List.map2Fold(comps, typeElement, inParent, inContext, st);
      then
        (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st);

  end match;
end typeClass2;

protected function typeElement
  input Element inElement;
  input Option<Component> inParent;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output Element outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) :=
  match(inElement, inParent, inContext, inSymbolTable)
    local
      Component comp;
      Class cls;
      Absyn.Path name;
      SymbolTable st;
      DAE.Type ty;

    case (InstTypes.ELEMENT(comp as InstTypes.UNTYPED_COMPONENT(name = name), cls),
        _, _, st)
      equation
        comp = InstSymbolTable.lookupName(name, st); 
        (comp, st) = typeComponent(comp, inParent, inContext, st);
        (cls, st) = typeClass2(cls, SOME(comp), inContext, st);
        /*-------------------------------------------------------------------*/
        // TODO: Complex components should have their types updated with the
        // typed class, so that the subcomponents types are correct in the
        // complex type. Otherwise the connection checking won't work with
        // nested connectors.
        /*-------------------------------------------------------------------*/
      then
        (InstTypes.ELEMENT(comp, cls), st);

    case (InstTypes.ELEMENT(comp, cls), _, _, st)
      equation
        (cls, st) = typeClass2(cls, SOME(comp), inContext, st);
      then
        (InstTypes.ELEMENT(comp, cls), st);

    case (InstTypes.EXTENDED_ELEMENTS(name, cls, ty), _, _, st)
      equation
        (cls, st) = typeClass2(cls, inParent, inContext, st);
      then
        (InstTypes.EXTENDED_ELEMENTS(name, cls, ty), st);

    else (inElement, inSymbolTable);

  end match;
end typeElement;

protected function typeComponent
  input Component inComponent;
  input Option<Component> inParent;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) :=
  match(inComponent, inParent, inContext, inSymbolTable)
    local
      Absyn.Path name;
      DAE.Type ty;
      Binding binding;
      SymbolTable st;
      Component comp, inner_comp;
      Context c;

    case (InstTypes.UNTYPED_COMPONENT(name = name, baseType = ty, binding = binding),
        _, c, st)
      equation
        (ty, st) = typeComponentDims(inComponent, inContext, st);
        (comp, st) = typeComponentBinding(inComponent, SOME(ty), inParent, c, st);
      then
        (comp, st);

    // A typed component without a parent has been typed due to a dependency
    // such as a binding, when parent information was not available. Update it
    // now if we have that information.
    case (InstTypes.TYPED_COMPONENT(parent = NONE()), SOME(_), _, st)
      equation
        comp = InstUtil.setComponentParent(inComponent, inParent);
        st = InstSymbolTable.updateComponent(comp, st);
      then
        (comp, st);

    case (InstTypes.TYPED_COMPONENT(name = _), _, _, st) then (inComponent, st);

    case (InstTypes.OUTER_COMPONENT(innerName = SOME(name)), _, _, st)
      equation
        comp = InstSymbolTable.lookupName(name, st);
        (comp, st) = typeComponent(comp, inParent, inContext, st);
      then
        (comp, st);

    case (InstTypes.OUTER_COMPONENT(name = name, innerName = NONE()), _, _, st)
      equation
        (_, SOME(inner_comp), st) = InstSymbolTable.updateInnerReference(inComponent, st);
        (inner_comp, st) = typeComponent(inner_comp, inParent, inContext, st);
      then
        (inner_comp, st);

    case (InstTypes.CONDITIONAL_COMPONENT(name = name), _, _, _)
      equation
        print("Trying to type conditional component " +& Absyn.pathString(name) +& "\n");
      then
        fail();

  end match;
end typeComponent;

protected function typeComponentDims
  input Component inComponent;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outType, outSymbolTable) := matchcontinue(inComponent, inContext, inSymbolTable)
    local
      DAE.Type ty;
      SymbolTable st;
      array<Dimension> dims;
      list<DAE.Dimension> typed_dims;
      Absyn.Path name;
      Absyn.Info info;

    case (InstTypes.UNTYPED_COMPONENT(baseType = ty, dimensions = dims, info = info), _, st)
      equation
        true = intEq(0, arrayLength(dims));
      then
        (ty, st);

    case (InstTypes.UNTYPED_COMPONENT(name = name, baseType = ty, dimensions = dims), _, st)
      equation
        (typed_dims, st) = typeDimensions(dims, name, inContext, st);
      then
        (DAE.T_ARRAY(ty, typed_dims, DAE.emptyTypeSource), st);
        
    case (InstTypes.TYPED_COMPONENT(ty = ty), _, st) then (ty, st);
    
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Typing.typeComponentDims failed on component ");
        Debug.traceln(Absyn.pathString(InstUtil.getComponentName(inComponent)));
      then
        fail();

  end matchcontinue;
end typeComponentDims;

protected function typeComponentDim
  input Component inComponent;
  input Integer inIndex;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output DAE.Dimension outDimension;
  output SymbolTable outSymbolTable;
algorithm
  (outDimension, outSymbolTable) := match(inComponent, inIndex, inContext, inSymbolTable)
    local
      list<DAE.Dimension> dims;
      DAE.Dimension typed_dim;
      SymbolTable st;
      array<Dimension> dims_arr;
      Dimension dim;
      Absyn.Path name;

    case (InstTypes.TYPED_COMPONENT(ty = DAE.T_ARRAY(dims = dims)), _, _, st)
      equation
        typed_dim = listGet(dims, inIndex);
      then
        (typed_dim, st);

    case (InstTypes.UNTYPED_COMPONENT(name = name, dimensions = dims_arr), _, _, st)
      equation
        dim = arrayGet(dims_arr, inIndex);
        (typed_dim, st) = typeDimension(dim, name, inContext, st, dims_arr, inIndex);
      then
        (typed_dim, st);

  end match;
end typeComponentDim;
        
protected function typeDimensions
  input array<Dimension> inDimensions;
  input Absyn.Path inComponentName;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output list<DAE.Dimension> outDimensions;
  output SymbolTable outSymbolTable;
protected
  Integer len;
algorithm
  len := arrayLength(inDimensions);
  (outDimensions, outSymbolTable) := 
    typeDimensions2(inDimensions, inComponentName, inContext, inSymbolTable, 1, len, {});
end typeDimensions;

protected function typeDimensions2
  input array<Dimension> inDimensions;
  input Absyn.Path inComponentName;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input Integer inIndex;
  input Integer inLength;
  input list<DAE.Dimension> inAccDims;
  output list<DAE.Dimension> outDimensions;
  output SymbolTable outSymbolTable;
algorithm
  (outDimensions, outSymbolTable) :=
  matchcontinue(inDimensions, inComponentName, inContext, inSymbolTable, inIndex, inLength, inAccDims)
    local
      Dimension dim;
      DAE.Dimension typed_dim;
      SymbolTable st;
      list<DAE.Dimension> dims;

    case (_, _, _, _, _, _, _)
      equation
        true = inIndex > inLength;
      then
        (listReverse(inAccDims), inSymbolTable);

    else
      equation
        dim = arrayGet(inDimensions, inIndex);
        (typed_dim, st) = 
          typeDimension(dim, inComponentName, inContext, inSymbolTable, inDimensions, inIndex);
        (dims, st) = typeDimensions2(inDimensions, inComponentName, inContext, st, inIndex + 1,
          inLength, typed_dim :: inAccDims);
      then
        (dims, st);

  end matchcontinue;
end typeDimensions2;

protected function typeDimension
  input Dimension inDimension;
  input Absyn.Path inComponentName;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input array<Dimension> inDimensions;
  input Integer inIndex;
  output DAE.Dimension outDimension;
  output SymbolTable outSymbolTable;
algorithm
  (outDimension, outSymbolTable) := 
  match(inDimension, inComponentName, inContext, inSymbolTable, inDimensions, inIndex)
    local
      SymbolTable st;
      DAE.Dimension dim;
      DAE.Exp dim_exp;
      Integer  dim_count;
      Dimension typed_dim;
      Component comp;

    case (InstTypes.UNTYPED_DIMENSION(isProcessing = true), _, _, _, _, _)
      equation
        print("Found dimension loop\n");
      then
        fail();

    case (InstTypes.UNTYPED_DIMENSION(dimension = dim as DAE.DIM_EXP(exp = dim_exp)), _, _, st, _, _)
      equation
        _ = arrayUpdate(inDimensions, inIndex, InstTypes.UNTYPED_DIMENSION(dim, true));
        (dim_exp, _, st) = typeExp(dim_exp, EVAL_CONST_PARAM(), inContext, st);
        (dim_exp, _) = ExpressionSimplify.simplify(dim_exp);
        dim = InstUtil.makeDimension(dim_exp);
        typed_dim = InstTypes.TYPED_DIMENSION(dim);
        _ = arrayUpdate(inDimensions, inIndex, typed_dim);
      then
        (dim, st);

    case (InstTypes.UNTYPED_DIMENSION(dimension = dim as DAE.DIM_UNKNOWN()), _, CONTEXT_MODEL(), st, _, _)
      equation
        _ = arrayUpdate(inDimensions, inIndex, InstTypes.UNTYPED_DIMENSION(dim, true));
        comp = InstSymbolTable.lookupName(inComponentName, st);
        (comp, st) = typeComponentBinding(comp, NONE(), NONE(), inContext, st);
        dim_count = arrayLength(inDimensions);
        dim = InstUtil.getComponentBindingDimension(comp, inIndex, dim_count);
        typed_dim = InstTypes.TYPED_DIMENSION(dim);
        _ = arrayUpdate(inDimensions, inIndex, typed_dim);
      then
        (dim, st);

    case (InstTypes.UNTYPED_DIMENSION(dimension = dim as DAE.DIM_UNKNOWN()), _, CONTEXT_FUNCTION(), st, _, _)
      equation
        _ = arrayUpdate(inDimensions, inIndex, InstTypes.TYPED_DIMENSION(dim));
      then
        (dim, st);

    case (InstTypes.UNTYPED_DIMENSION(dimension = dim), _, _, st, _, _)
      equation
        _ = arrayUpdate(inDimensions, inIndex, InstTypes.TYPED_DIMENSION(dim));
      then 
        (dim, st);

    case (InstTypes.TYPED_DIMENSION(dimension = dim), _, _, st, _, _) then (dim, st);

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
  input Option<Component> inParent;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) :=
  match(inComponent, inType, inParent, inContext, inSymbolTable)
    local
      Binding binding;
      SymbolTable st;
      Component comp;
      EvalPolicy ep;

    case (InstTypes.UNTYPED_COMPONENT(binding = binding), _, _, _, st)
      equation
        st = markComponentBindingAsProcessing(inComponent, st);
        ep = getEvalPolicyForBinding(inComponent);
        (binding, st) = typeBinding(binding, ep, inContext, st);
        comp = updateComponentBinding(inComponent, binding, inType, inParent);
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
  input Option<Component> inParent;
  output Component outComponent;
algorithm
  outComponent := match(inComponent, inBinding, inType, inParent)
    local
      Absyn.Path name;
      DAE.Type ty;
      Prefixes pf;
      DaePrefixes dpf;
      ParamType pty;
      array<Dimension> dims;
      Absyn.Info info;
     
    case (InstTypes.UNTYPED_COMPONENT(name = name, prefixes = pf, info = info),
        _, SOME(ty), _)
      equation
        dpf = InstUtil.translatePrefixes(pf);
      then 
        InstTypes.TYPED_COMPONENT(name, ty, inParent, dpf, inBinding, info);

    case (InstTypes.UNTYPED_COMPONENT(name, ty, dims, pf, pty, _, info), _, NONE(), _)
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
      DAE.Type ty;
      array<Dimension> dims;
      Component comp;
      SCode.Variability var;
      DAE.Exp binding_exp;
      Integer pl;
      Prefixes pf;
      ParamType pty;
      Absyn.Info info1, info2;

    case (InstTypes.UNTYPED_COMPONENT(prefixes = InstTypes.PREFIXES(variability = var)), _)
      equation
        false = SCode.isParameterOrConst(var);
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
  input Context inContext;
  input SymbolTable inSymbolTable;
  output Binding outBinding;
  output SymbolTable outSymbolTable;
algorithm
  (outBinding, outSymbolTable) :=
  match(inBinding, inEvalPolicy, inContext, inSymbolTable)
    local
      DAE.Exp binding;
      SymbolTable st;
      DAE.Type ty;
      Integer pd;
      Absyn.Info info;

    case (InstTypes.UNTYPED_BINDING(isProcessing = true), _, _, st)
      equation
        InstSymbolTable.showCyclicDepError(st);
      then
        fail();

    case (InstTypes.UNTYPED_BINDING(bindingExp = binding, propagatedDims = pd,
        info = info), _, _, st)
      equation
        (binding, ty, st) = typeExp(binding, inEvalPolicy, inContext, st);
      then
        (InstTypes.TYPED_BINDING(binding, ty, pd, info), st);

    case (InstTypes.TYPED_BINDING(bindingExp = _), _, _, st)
      then (inBinding, st);

    else (InstTypes.UNBOUND(), inSymbolTable);

  end match;
end typeBinding;

protected function typeExpList
  input list<DAE.Exp> inExpList;
  input EvalPolicy inEvalPolicy;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output list<DAE.Exp> outExpList;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExpList, outType, outSymbolTable) :=
  match(inExpList, inEvalPolicy, inContext, inSymbolTable)
    local
      DAE.Exp exp;
      list<DAE.Exp> rest_expl;
      EvalPolicy ep;
      SymbolTable st;
      DAE.Type ty;
      Context c;

    case ({}, _, _, st) then ({}, DAE.T_UNKNOWN_DEFAULT, st);

    case (exp :: rest_expl, ep, c, st)
      equation
        (exp, ty, st) = typeExp(exp, ep, c, st);
        (rest_expl, _, st) = typeExpList(rest_expl, ep, c, st);
      then
        (exp :: rest_expl, ty, st);

  end match;
end typeExpList;

public function typeExpOpt
  input Option<DAE.Exp> inExp;
  input EvalPolicy inEvalPolicy;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output Option<DAE.Exp> outExp;
  output Option<DAE.Type> outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outSymbolTable) := match(inExp, inEvalPolicy, inContext, inSymbolTable)
    local
      DAE.Exp exp;
      SymbolTable st;
      DAE.Type ty;

    case (SOME(exp), _, _, st)
      equation
        (exp, ty, st) = typeExp(exp, inEvalPolicy, inContext, st);
      then
        (SOME(exp), SOME(ty), st);

    else (NONE(), NONE(), inSymbolTable);

  end match;
end typeExpOpt;

protected function selectType
"@author: adrpo
 select the second type if the first type is T_UNKNOWN"
 input DAE.Type inTy1;
 input DAE.Type inTy2;
 output DAE.Type outTy;
algorithm
  outTy := match(inTy1,inTy2)
    case (DAE.T_UNKNOWN(_), _) then inTy2;
    case (_, _) then inTy1;
  end match;
end selectType;

public function typeExp
  input DAE.Exp inExp;
  input EvalPolicy inEvalPolicy;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outSymbolTable) :=
  match(inExp, inEvalPolicy, inContext, inSymbolTable)
    local
      DAE.Exp e1, e2;
      DAE.ComponentRef cref;
      DAE.Type ty,tyOp;
      SymbolTable st;
      DAE.Operator op;
      Component comp;
      Integer dim_int;
      DAE.Dimension dim;
      list<DAE.Exp> expl;
      EvalPolicy ep;
      Option<DAE.Exp> oe;
      Context c;

    case (DAE.ICONST(integer = _), _, _, st) then (inExp, DAE.T_INTEGER_DEFAULT, st);
    case (DAE.RCONST(real = _), _, _, st) then (inExp, DAE.T_REAL_DEFAULT, st);
    case (DAE.SCONST(string = _), _, _, st) then (inExp, DAE.T_STRING_DEFAULT, st);
    case (DAE.BCONST(bool = _), _, _, st) then (inExp, DAE.T_BOOL_DEFAULT, st);
    case (DAE.CREF(componentRef = cref), ep, _, st)
      equation
        (e1, ty, st) = typeCref(cref, ep, st);
      then
        (e1, ty, st);
        
    case (DAE.ARRAY(array = expl), ep, c, st)
      equation
        (expl, ty, st) = typeExpList(expl, ep, c, st);
        dim_int = listLength(expl);
        ty = DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(dim_int)}, DAE.emptyTypeSource);
      then
        (DAE.ARRAY(ty, true, expl), ty, st);

    case (DAE.BINARY(exp1 = e1, operator = op, exp2 = e2), ep, c, st)
      equation
        (e1, ty, st) = typeExp(e1, ep, c, st);
        (e2, ty, st) = typeExp(e2, ep, c, st);
        // get the type of the operator, not the types of 
        // the last operand as for == it DOES NOT HOLD
        tyOp = Expression.typeofOp(op);
        ty = selectType(tyOp, ty);
      then
        (DAE.BINARY(e1, op, e2), ty, st);

    case (DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2), ep, c, st)
      equation
        (e1, ty, st) = typeExp(e1, ep, c, st);
        (e2, ty, st) = typeExp(e2, ep, c, st);
        tyOp = Expression.typeofOp(op);
        ty = selectType(tyOp, ty);
      then
        (DAE.LBINARY(e1, op, e2), ty, st);

    case (DAE.LUNARY(operator = op, exp = e1), ep, c, st)
      equation
        (e1, ty, st) = typeExp(e1, ep, c, st);
        tyOp = Expression.typeofOp(op);
        ty = selectType(tyOp, ty);
      then
        (DAE.LUNARY(op, e1), ty, st);

    case (DAE.SIZE(exp = e1 as DAE.CREF(componentRef = cref), sz = SOME(e2)), ep, c, st)
      equation
        (e2 as DAE.ICONST(dim_int), _, st) = typeExp(e2, EVAL_CONST_PARAM(), c, st);
        comp = InstSymbolTable.lookupCref(cref, st);
        (dim, st) = typeComponentDim(comp, dim_int, c, st);
        e1 = dimensionExp(dim, e1, e2, c);
      then
        (e1, DAE.T_INTEGER_DEFAULT, st);

    case (DAE.RANGE(start = e1, step = oe, stop = e2), ep, c, st)
      equation
        (e1, ty, st) = typeExp(e1, ep, c, st);
        (oe, _, st) = typeExpOpt(oe, ep, c, st);
        (e2, _, st) = typeExp(e2, ep, c, st);
        ty = Expression.liftArrayLeft(ty, DAE.DIM_UNKNOWN());
      then
        (DAE.RANGE(ty, e1, oe, e2), ty, st);

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
  input DAE.Exp inCref;
  input DAE.Exp inIndex;
  input Context inContext;
  output DAE.Exp outExp;
algorithm
  outExp := match(inDimension, inCref, inIndex, inContext)
    local
      Integer dim_int;
      DAE.Exp dim_exp;

    case (DAE.DIM_INTEGER(dim_int), _, _, _) then DAE.ICONST(dim_int);
    case (DAE.DIM_EXP(dim_exp), _, _, _) then dim_exp;
    case (DAE.DIM_UNKNOWN(), _, _, CONTEXT_FUNCTION())
      then DAE.SIZE(inCref, SOME(inIndex));

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
      SymbolTable st;
      Component comp;
      DAE.Type ty;
      DAE.Exp exp;
      SCode.Variability var;
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
  input SCode.Variability inVarKind;
  input EvalPolicy inEvalPolicy;
  output Boolean outShouldEval;
algorithm
  outShouldEval := match(inVarKind, inEvalPolicy)
    case (SCode.PARAM(), EVAL_CONST_PARAM()) then true;
    case (_, NO_EVAL()) then false;
    case (SCode.CONST(), _) then true;
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
  match(inCref, inComponent, inShouldEvaluate, inEvalPolicy, inSymbolTable)
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
        /* ------------------------------------------------------------------*/
        // TODO: The start value should be used if a parameter or constant has
        // fixed = true, and no binding.
        /* ------------------------------------------------------------------*/
        exp = InstUtil.getBindingExp(binding);
        /* ------------------------------------------------------------------*/
        // TODO: Apply cref subscripts to the expression.
        /* ------------------------------------------------------------------*/
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
          typeComponent(inComponent, NONE(), CONTEXT_MODEL(), st);
        exp = InstUtil.getBindingExp(binding);
        /* ------------------------------------------------------------------*/
        // TODO: Apply cref subscripts to the expression.
        /* ------------------------------------------------------------------*/
      then
        (exp, ty, st);

    case (_, InstTypes.UNTYPED_COMPONENT(name = _), false, _, st)
      equation
        (ty, st) = typeComponentDims(inComponent, CONTEXT_MODEL(), st);
        ty = propagateCrefSubsToType(ty, inCref);
      then
        (DAE.CREF(inCref, ty), ty, st);

    case (_, InstTypes.OUTER_COMPONENT(name = _), se, ep, st)
      equation
        (inner_comp, st) = typeComponent(inComponent, NONE(), CONTEXT_MODEL(), st);
        inner_name = InstUtil.getComponentName(inner_comp);
        inner_cref = InstUtil.removeCrefOuterPrefix(inner_name, inCref);
        (exp, ty, st) = typeCref2(inner_cref, inner_comp, se, ep, st);
      then
        (exp, ty, st);

  end match;
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
  output Connections outConnections;
algorithm
  (outClass, outConnections) := typeSections2(inClass, inSymbolTable,
    Connect2.emptyConnections);
end typeSections;

public function typeSections2
  input Class inClass;
  input SymbolTable inSymbolTable;
  input Connections inConnections;
  output Class outClass;
  output Connections outConnections;
algorithm
  (outClass, outConnections) := match(inClass, inSymbolTable, inConnections)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<list<Statement>> al, ial;
      SymbolTable st;
      Connections conn;

    case (InstTypes.BASIC_TYPE(), _, _) then (inClass, inConnections);

    case (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), st, conn)
      equation
        (comps, conn) = typeSectionsInElements(comps, st, conn);
        (eq, conn) = typeEquations(eq, st, conn);
        // Connections are not allowed in initial equation sections, so we
        // shouldn't get any connections back from typeEquations here.
        (ieq, _) =
          typeEquations(ieq, st, Connect2.emptyConnections);
        al = typeAlgorithms(al, st);
        ial = typeAlgorithms(ial, st);
      then
        (InstTypes.COMPLEX_CLASS(comps, eq, ieq, al, ial), conn);

  end match;
end typeSections2;

protected function typeSectionsInElements
  input list<Element> inElements;
  input SymbolTable inSymbolTable;
  input Connections inConnections;
  output list<Element> outElements;
  output Connections outConnections;
algorithm
  (outElements, outConnections) := List.map1Fold(inElements,
    typeSectionsInElement, inSymbolTable, inConnections);
end typeSectionsInElements;
    
protected function typeSectionsInElement
  input Element inElement;
  input SymbolTable inSymbolTable;
  input Connections inConnections;
  output Element outElement;
  output Connections outConnections;
algorithm
  (outElement, outConnections) := match(inElement, inSymbolTable, inConnections)
    local
      Component comp;
      Class cls;
      Absyn.Path bc;
      DAE.Type ty;
      SymbolTable st;
      Connections conn;

    case (InstTypes.ELEMENT(comp, cls), st, conn)
      equation
        (cls, conn) = typeSections2(cls, st, conn);
      then
        (InstTypes.ELEMENT(comp, cls), conn);

    case (InstTypes.EXTENDED_ELEMENTS(bc, cls, ty), st, conn)
      equation
        (cls, conn) = typeSections2(cls, st, conn);
      then
        (InstTypes.EXTENDED_ELEMENTS(bc, cls, ty), conn);

    case (InstTypes.CONDITIONAL_ELEMENT(_), st, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Typing.typeSectionsInElement got a conditional element!"});
      then
        fail();

  end match;
end typeSectionsInElement;

protected function typeEquations
  input list<Equation> inEquations;
  input SymbolTable inSymbolTable;
  input Connections inConnections;
  output list<Equation> outEquations;
  output Connections outConnections;
algorithm
  (outEquations, outConnections) :=
    typeEquations2(inEquations, inSymbolTable, {}, inConnections);
end typeEquations;

protected function typeEquations2
  input list<Equation> inEquations;
  input SymbolTable inSymbolTable;
  input list<Equation> inAccumEql;
  input Connections inConnections;
  output list<Equation> outEquations;
  output Connections outConnections;
algorithm
  (outEquations, outConnections) :=
  match(inEquations, inSymbolTable, inAccumEql, inConnections)
    local
      Equation eq;
      list<Equation> rest_eq, acc_eq;
      SymbolTable st;
      Connections conn;
      
    case (eq :: rest_eq, st, acc_eq, _)
      equation
        (acc_eq, conn) = typeEquation(eq, st, acc_eq, inConnections);
        (acc_eq, conn) = typeEquations2(rest_eq, st, acc_eq, conn);
      then
        (acc_eq, conn);

    case ({}, _, _, _) then (listReverse(inAccumEql), inConnections);

  end match;
end typeEquations2;

protected function typeEquation
  input Equation inEquation;
  input SymbolTable inSymbolTable;
  input list<Equation> inAccumEql;
  input Connections inConnections;
  output list<Equation> outAccumEql;
  output Connections outConnections;
algorithm
  (outAccumEql, outConnections) :=
  match(inEquation, inSymbolTable, inAccumEql, inConnections)
    local
      DAE.Exp rhs, lhs, exp1, exp2, exp3;
      list<DAE.Exp> args;
      SymbolTable st;
      Absyn.Info info;
      DAE.ComponentRef cref1, cref2;
      Prefix prefix;
      String name;
      Integer index;
      list<Equation> eql;
      DAE.Type ty;
      list<tuple<DAE.Exp, list<Equation>>> branches;
      list<Equation> acc_el;
      Absyn.Path iter_name;
      Component iter;
      Equation eq;
      Connections conn;

    case (InstTypes.EQUALITY_EQUATION(lhs, rhs, info), st, acc_el, _)
      equation
        (rhs, _, _) = typeExp(rhs, EVAL_CONST(), CONTEXT_MODEL(), st);
        (lhs, _, _) = typeExp(lhs, EVAL_CONST(), CONTEXT_MODEL(), st);
        eq = InstTypes.EQUALITY_EQUATION(lhs, rhs, info);
      then
        (eq :: acc_el, inConnections);

    case (InstTypes.CONNECT_EQUATION(cref1, _, _, cref2, _, _, prefix, info),
        st, acc_el, conn)
      equation
        (acc_el, conn) = typeConnection(cref1, cref2, prefix, st, info, acc_el, conn);
      then
        (acc_el, conn);

    case (InstTypes.FOR_EQUATION(name, index, _, SOME(exp1), eql, info), st, acc_el, conn)
      equation
        (exp1, ty, _) = typeExp(exp1, EVAL_CONST_PARAM(), CONTEXT_MODEL(), st);
        ty = rangeToIteratorType(ty, exp1, info);
        iter_name = Absyn.IDENT(name);
        iter = InstUtil.makeIterator(iter_name, ty, info);
        st = InstSymbolTable.addIterator(iter_name, iter, st);
        (eql, conn) = typeEquations(eql, st, conn);
        eq = InstTypes.FOR_EQUATION(name, index, ty, SOME(exp1), eql, info);
      then
        (eq :: acc_el, conn);

    case (InstTypes.FOR_EQUATION(_, _, _, NONE(), eql, info), st, acc_el, _)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR,{"Implicit for ranges are not yet implemented"},info);
      then fail();

    case (InstTypes.IF_EQUATION(branches, info), st, acc_el, _)
      equation
        (branches, conn) = typeBranches(branches, st);
        eq = InstTypes.IF_EQUATION(branches, info);
        /* ------------------------------------------------------------------*/
        // TODO: Check conn here, connections are not allowed inside
        // if-equations with non-parametric conditions.
        /* ------------------------------------------------------------------*/
      then
        (eq :: acc_el, conn);

    case (InstTypes.WHEN_EQUATION(branches, info), st, acc_el, _)
      equation
        (branches, conn) = typeBranches(branches, st);
        /* ------------------------------------------------------------------*/
        // TODO: Check conn here, connections are not allowed inside when.
        /* ------------------------------------------------------------------*/
        // TOOD: Check restrictions on branches, section 8.3.5.2 in specification.
        /* ------------------------------------------------------------------*/
        checkConnectsInWhen(conn, info);
        eq = InstTypes.WHEN_EQUATION(branches, info);
      then
        (eq :: acc_el, Connect2.emptyConnections);

    case (InstTypes.ASSERT_EQUATION(exp1, exp2, exp3, info), st, acc_el, _)
      equation
        (exp1, _, _) = typeExp(exp1, EVAL_CONST(), CONTEXT_MODEL(), st);
        (exp2, _, _) = typeExp(exp2, EVAL_CONST(), CONTEXT_MODEL(), st);
        (exp3, _, _) = typeExp(exp3, EVAL_CONST(), CONTEXT_MODEL(), st);
        eq = InstTypes.ASSERT_EQUATION(exp1, exp2, exp3, info);
      then
        (eq :: acc_el, Connect2.emptyConnections);

    case (InstTypes.TERMINATE_EQUATION(exp1, info), st, acc_el, _)
      equation
        (exp1, _, _) = typeExp(exp1, EVAL_CONST(), CONTEXT_MODEL(), st);
        eq = InstTypes.TERMINATE_EQUATION(exp1, info);
      then
        (eq :: acc_el, Connect2.emptyConnections);

    case (InstTypes.REINIT_EQUATION(cref1, exp1, info), st, acc_el, _)
      equation
        (DAE.CREF(componentRef = cref1), _, _) = typeCref(cref1, NO_EVAL(), st);
        (exp1, _, _) = typeExp(exp1, EVAL_CONST(), CONTEXT_MODEL(), st);
        eq = InstTypes.REINIT_EQUATION(cref1, exp1, info);
      then
        (eq :: acc_el, Connect2.emptyConnections);

    case (InstTypes.NORETCALL_EQUATION(DAE.CALL(path = Absyn.QUALIFIED(name = "Connections",
        path = Absyn.IDENT(name = name)), expLst = args), info), st, acc_el, _)
      equation
        conn = typeConnectionsEquation(name, args, st, info);
      then
        (acc_el, conn);

    case (InstTypes.NORETCALL_EQUATION(exp1, info), st, acc_el, _)
      equation
        (exp1, _, _) = typeExp(exp1, EVAL_CONST(), CONTEXT_MODEL(), st);
        eq = InstTypes.NORETCALL_EQUATION(exp1, info);
      then
        (eq :: acc_el, Connect2.emptyConnections);
        
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"Typing.typeEquation got an unknown equation type!"});
      then
        fail();

  end match;
end typeEquation;

protected function checkConnectsInWhen
  input Connections inConnections;
  input Absyn.Info inInfo;
algorithm
  _ := match(inConnections, inInfo)
    case (Connect2.CONNECTIONS({}, {}, {}), _) then ();

    else
      equation
        print("Connections are not allowed in when equations\n.");
      then
        fail();

  end match;
end checkConnectsInWhen;

protected function typeConnectionsEquation
  "This function types the functions in the builtin Connections package, and
   adds them to the connection graph."
  input String inName;
  input list<DAE.Exp> inArgs;
  input SymbolTable inSymbolTable;
  input Absyn.Info inInfo;
  output Connections outConnections;
algorithm
  outConnections := match(inName, inArgs, inSymbolTable, inInfo)
    local
      DAE.ComponentRef cref1, cref2;
      SymbolTable st;
      DAE.Exp prio;

    case ("branch", {DAE.CREF(componentRef = cref1),
        DAE.CREF(componentRef = cref2)}, st, _)
      equation
        (DAE.CREF(componentRef = cref1), _, _) = typeCref(cref1, NO_EVAL(), st);
        (DAE.CREF(componentRef = cref2), _, _) = typeCref(cref2, NO_EVAL(), st);
      then
        ConnectUtil2.makeBranch(cref1, cref2, inInfo);

    case ("root", {DAE.CREF(componentRef = cref1)}, st, _)
      equation
        (DAE.CREF(componentRef = cref1), _, _) = typeCref(cref1, NO_EVAL(), st);
      then
        ConnectUtil2.makeRoot(cref1, inInfo);

    case ("potentialRoot", {DAE.CREF(componentRef = cref1), prio}, st, _)
      equation
        (prio, _, _) = typeExp(prio, EVAL_CONST_PARAM(), CONTEXT_MODEL(), st);
      then
        ConnectUtil2.makePotentialRoot(cref1, prio, inInfo);

    // Modelica allows you to omit crefs from the lhs, so isRoot may be called
    // as a non-returning call. It won't do anything though. Perhaps we should
    // tell the user that this is stupid?
    case ("isRoot", _, _, _)
      then Connect2.emptyConnections;

  end match;
end typeConnectionsEquation;

protected function typeConnection
  input DAE.ComponentRef inLhs;
  input DAE.ComponentRef inRhs;
  input Prefix inPrefix;
  input SymbolTable inSymbolTable;
  input Absyn.Info inInfo;
  input list<Equation> inEquations;
  input Connections inConnections;
  output list<Equation> outEquations;
  output Connections outConnections;
algorithm
  (outEquations, outConnections) :=
  match(inLhs, inRhs, inPrefix, inSymbolTable, inInfo, inEquations, inConnections)
    local
      DAE.ComponentRef lhs, rhs;
      Face lhs_face, rhs_face;
      DAE.Type lhs_ty, rhs_ty;
      Boolean lhs_id, rhs_id, is_deleted;
      ConnectorType lhs_cty, rhs_cty;
      Option<Component> lhs_comp, rhs_comp;
      DAE.VarKind lhs_var, rhs_var;
      list<Equation> eql;
      Connections conn;
      Connector lhs_conn, rhs_conn;

    case (_, _, _, _, _, eql, conn)
      equation
        (lhs, lhs_face, lhs_comp, lhs_id) =
          typeConnectorCref(inLhs, inPrefix, inSymbolTable, inInfo);
        (rhs, rhs_face, rhs_comp, rhs_id) =
          typeConnectorCref(inRhs, inPrefix, inSymbolTable, inInfo);

        is_deleted = lhs_id or rhs_id;
        /* ------------------------------------------------------------------*/
        // TODO: Typecheck the components to make sure that they have compatible
        // types, i.e. check that lhs_ty and rhs_ty are compatible.
        /* ------------------------------------------------------------------*/

        lhs_conn = ConnectUtil2.makeConnector(lhs, lhs_face, lhs_comp);
        rhs_conn = ConnectUtil2.makeConnector(rhs, rhs_face, rhs_comp);

        (eql, conn) = typeConnection2(is_deleted, lhs_conn, rhs_conn,
          inInfo, eql, conn);
      then
        (eql, conn);

  end match;
end typeConnection;

protected function typeConnection2
  input Boolean inIsDeleted;
  input Connector inLhsConnector;
  input Connector inRhsConnector;
  input Absyn.Info inInfo;
  input list<Equation> inEquations;
  input Connections inConnections;
  output list<Equation> outEquations;
  output Connections outConnections;
algorithm
  (outEquations, outConnections) := match(inIsDeleted, inLhsConnector,
      inRhsConnector, inInfo, inEquations, inConnections)
    local
      list<Equation> eql;
      Connections conn;
      Boolean is_only_const;

    case (true, _, _, _, _, _) then (inEquations, inConnections);

    else
      equation
        ConnectCheck.compatibleConnectors(inLhsConnector, inRhsConnector, inInfo);
        (eql, is_only_const) = ConnectUtil2.generateConnectAssertion(
          inLhsConnector, inRhsConnector, inInfo, inEquations);
        conn = ConnectUtil2.addConnectionCond(not is_only_const, inLhsConnector,
          inRhsConnector, inInfo, inConnections);
      then
        (eql, conn);

  end match;
end typeConnection2;

protected function typeConnectorCref
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input SymbolTable inSymbolTable;
  input Absyn.Info inInfo;
  output DAE.ComponentRef outCref;
  output Face outFace;
  output Option<Component> outComponent;
  output Boolean outIsDeleted;
algorithm
  (outCref, outFace, outComponent, outIsDeleted) :=
  match(inCref, inPrefix, inSymbolTable, inInfo)
    local
      DAE.ComponentRef cref;
      Option<Component> comp, pre_comp;
      Face face;
      Boolean is_deleted;

    case (_, _, _, _)
      equation
        (cref, comp, pre_comp) =
          lookupConnectorCref(inCref, inPrefix, inSymbolTable, inInfo);
        (cref, face, is_deleted) = typeConnectorCref2(cref, comp, pre_comp, inInfo);
      then
        (cref, face, comp, is_deleted);
  
  end match;
end typeConnectorCref;

protected function typeConnectorCref2
  input DAE.ComponentRef inCref;
  input Option<Component> inComponent;
  input Option<Component> inPrefixComponent;
  input Absyn.Info inInfo;
  output DAE.ComponentRef outCref;
  output Face outFace;
  output Boolean outIsDeleted;
algorithm
  (outCref, outFace, outIsDeleted) :=
  match(inCref, inComponent, inPrefixComponent, inInfo)
    local
      Face face;
      Component comp;
      DAE.Type ty;
      DAE.ComponentRef cref;
      DAE.ConnectorType dcty;
      ConnectorType cty;

    // A connector that is part of a deleted conditional component.
    case (_, NONE(), NONE(), _)
      then (inCref, Connect2.NO_FACE(), true);

    // A connector which is itself deleted.
    case (_, SOME(InstTypes.DELETED_COMPONENT(_)), _, _)
      then (inCref, Connect2.NO_FACE(), true);

    // A component that should be added to an expandable connector. It can only
    // be outside, since only connectors on the form m.c are inside.
    case (_, NONE(), SOME(_), _)
      then (inCref, Connect2.OUTSIDE(), false);

    // A normal connector.
    case (cref, SOME(comp), _, _)
      equation
        /* ------------------------------------------------------------------*/
        // TODO: Resolve outer references here?
        /* ------------------------------------------------------------------*/
        ConnectCheck.checkComponentIsConnector(comp, inPrefixComponent, inCref, inInfo);
        face = ConnectUtil2.getConnectorFace(inPrefixComponent);
        cref = InstUtil.typeCrefWithComponent(cref, comp);
      then
        (cref, face, false);

  end match;
end typeConnectorCref2;

protected function lookupConnectorCref
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input SymbolTable inSymbolTable;
  input Absyn.Info inInfo;
  output DAE.ComponentRef outCref;
  output Option<Component> outComponent;
  output Option<Component> outPrefixComponent;
algorithm
  (outCref, outComponent, outPrefixComponent) :=
  matchcontinue(inCref, inPrefix, inSymbolTable, inInfo)
    local
      DAE.ComponentRef cref;
      Option<Component> comp, pre_comp;
      String cref_str; 

    case (_, _, _, _)
      equation
        (cref, comp, pre_comp) = 
          lookupConnectorCref2(inCref, inPrefix, inSymbolTable);
      then
        (cref, comp, pre_comp);

    else
      equation
        cref_str = ComponentReference.printComponentRefStr(inCref);
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR,
          {cref_str, ""}, inInfo);
      then
        fail();

  end matchcontinue;
end lookupConnectorCref;

protected function lookupConnectorCref2
  "Looks up a cref used by a connect equation in the symbol table and returns
   the found component. In the case of a qualified cref it also returns the
   component corresponding to the first identifier in the cref, i.e. for a.b.c it
   returns the component for a, since this is needed to determine the face of the
   connection element."
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input SymbolTable inSymbolTable;
  output DAE.ComponentRef outCref;
  output Option<Component> outComponent;
  output Option<Component> outPrefixComponent;
algorithm
  (outCref, outComponent, outPrefixComponent) :=
  matchcontinue(inCref, inPrefix, inSymbolTable)
    local
      Component comp;
      DAE.ComponentRef cref, cref2;
      Option<Component> opt_comp, opt_pre_comp;
      
    case (DAE.CREF_IDENT(ident = _), _, _)
      equation
        cref = InstUtil.prefixCref(inCref, inPrefix);
        comp = InstSymbolTable.lookupCref(cref, inSymbolTable);
      then
        (cref, SOME(comp), NONE());

    case (DAE.CREF_QUAL(ident = _), _, _)
      equation
        (cref, cref2) = ComponentReference.splitCrefFirst(inCref);
        cref = InstUtil.prefixCref(cref, inPrefix);
        cref = ComponentReference.joinCrefs(cref, cref2);
        comp = InstSymbolTable.lookupCref(cref, inSymbolTable);
        opt_pre_comp = InstUtil.getComponentParent(comp);
      then
        (cref, SOME(comp), opt_pre_comp);

    // If the cref is qualified but we couldn't find it, it might be part of a
    // deleted conditional component (i.e. it hasn't been instantiated). It
    // might also be part of an expandable connector. In that case, strip the
    // last identifier and look again to see if we can find a deleted component
    // that is a prefix of the given cref.
    case (DAE.CREF_QUAL(ident = _), _, _)
      equation
        cref = ComponentReference.crefStripLastIdent(inCref);
        cref = InstUtil.prefixCref(cref, inPrefix);
        (_, opt_comp, opt_pre_comp) =
          lookupConnectorCref2(cref, InstTypes.emptyPrefix, inSymbolTable);
        (opt_comp, opt_pre_comp) = lookupConnectorCref3(opt_comp, opt_pre_comp);
      then
        (cref, opt_comp, opt_pre_comp);

  end matchcontinue;
end lookupConnectorCref2;

protected function lookupConnectorCref3
  input Option<Component> inComponent;
  input Option<Component> inPrefixComponent;
  output Option<Component> outComponent;
  output Option<Component> outPrefixComponent;
algorithm
  (outComponent, outPrefixComponent) := match(inComponent, inPrefixComponent)
    local
      DAE.Type ty;

    // A deleted component, return nothing.
    case (SOME(InstTypes.DELETED_COMPONENT(name = _)), _)
      then (NONE(), NONE());

    // A component that should be added to an expandable connector. The
    // component we get is the expandable connector itself, so we return it as
    // the prefix component here, and return nothing as the component.
    case (SOME(InstTypes.TYPED_COMPONENT(ty = ty)), _)
      equation
        true = Types.isComplexExpandableConnector(ty);
      then
        (NONE(), inComponent);

    case (NONE(), _) then (inComponent, inPrefixComponent);

  end match;
end lookupConnectorCref3;

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

protected function typeBranches
  input list<tuple<DAE.Exp, list<Equation>>> inBranches;
  input SymbolTable inSymbolTable;
  output list<tuple<DAE.Exp, list<Equation>>> outBranches;
  output Connections outConnections;
algorithm
  (outBranches, outConnections) := List.map1Fold(inBranches, typeBranch,
    inSymbolTable, Connect2.emptyConnections); 
end typeBranches;

protected function typeBranch
  input tuple<DAE.Exp, list<Equation>> inBranch;
  input SymbolTable inSymbolTable;
  input Connections inConnections;
  output tuple<DAE.Exp, list<Equation>> outBranch;
  output Connections outConnections;
algorithm
  (outBranch, outConnections) := match(inBranch, inSymbolTable, inConnections)
    local
      DAE.Exp cond_exp;
      list<Equation> branch_body;
      Connections conn;

    case ((cond_exp, branch_body), _, conn)
      equation
        (cond_exp, _, _) = typeExp(cond_exp, EVAL_CONST(), CONTEXT_MODEL(), inSymbolTable);
        (branch_body, conn) = typeEquations(branch_body, inSymbolTable, conn);
      then
        ((cond_exp, branch_body), conn);

  end match;
end typeBranch;

protected function typeAlgorithms
  input list<list<Statement>> inStmts;
  input SymbolTable inSymbolTable;
  output list<list<Statement>> outStmts;
algorithm
  outStmts := List.map2(inStmts,typeStatements,CONTEXT_MODEL(),inSymbolTable);
end typeAlgorithms;

protected function typeStatements
  input list<Statement> inStmts;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output list<Statement> outStmts;
algorithm
  outStmts := listReverse(List.fold2(inStmts, typeStatement, inContext, inSymbolTable, {}));
end typeStatements;

protected function typeStatement
  input Statement inStmt;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input list<Statement> inAcc;
  output list<Statement> outAcc;
algorithm
  outAcc := match (inStmt,inContext,inSymbolTable,inAcc)
    local
      DAE.Exp lhs,rhs,exp;
      Absyn.Info info;
      DAE.Type lty,rty,ty;
      SymbolTable st;
      list<tuple<DAE.Exp,list<Statement>>> branches;
      String name;
      Context c;

    case (InstTypes.ASSIGN_STMT(lhs=lhs,rhs=rhs,info=info),c,st,_)
      equation
        (lhs,lty,_) = typeExp(lhs, NO_EVAL(), c, st);
        (rhs,rty,_) = typeExp(rhs, EVAL_CONST(), c, st);
        // rhs = typeCheck(rhs,lty,rty)
      then typeAssignment(lhs,rhs,info,inAcc);
    case (InstTypes.FUNCTION_ARRAY_INIT(name=name,ty=ty,info=info),c,st,_)
      equation
        InstTypes.TYPED_COMPONENT(ty=ty) = InstSymbolTable.lookupCref(DAE.CREF_IDENT(name,ty,{}),st);
      then InstTypes.FUNCTION_ARRAY_INIT(name,ty,info) :: inAcc;
    case (InstTypes.NORETCALL_STMT(exp=exp, info=info),c,st,_)
      equation
        // Let's try skipping evaluation. Maybe helps some external functions
        (exp,_,_) = typeExp(exp, NO_EVAL(), c, st);
        /* ------------------------------------------------------------------*/
        // TODO: Check variability/etc to potentially reduce the statement?
        /* ------------------------------------------------------------------*/
      then InstTypes.NORETCALL_STMT(exp,info)::inAcc;
    case (InstTypes.IF_STMT(branches=branches, info=info),c,st,_)
      equation
        branches = List.map2(branches, typeBranchStatement, c, st);
      then
        InstTypes.IF_STMT(branches, info) :: inAcc;
    case (InstTypes.FOR_STMT(info=_),c,st,_)
      then
        inStmt :: inAcc;
    else
      equation
        print("Unknown statement in Typing.typeStatement\n");
      then fail();
  end match;
end typeStatement;

protected function typeAssignment
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input Absyn.Info info;
  input list<Statement> inAcc;
  output list<Statement> outAcc;
algorithm
  outAcc := matchcontinue (lhs,rhs,info,inAcc)
    local
      list<DAE.Exp> el;
    case (DAE.TUPLE(PR=el),rhs,info,inAcc)
      equation
        false = List.exist(el,Expression.isNotWild);
      then InstTypes.NORETCALL_STMT(rhs,info)::inAcc;
    case (DAE.TUPLE(PR=el),rhs,info,inAcc)
      equation
        false = List.exist(el,Expression.isNotCref);
      then InstTypes.ASSIGN_STMT(lhs,rhs,info)::inAcc;
    case (lhs as DAE.CREF(componentRef=_),rhs,info,inAcc)
      then InstTypes.ASSIGN_STMT(lhs,rhs,info)::inAcc;
  end matchcontinue;
end typeAssignment;

protected function typeBranchStatement
  input tuple<DAE.Exp, list<Statement>> inBranch;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output tuple<DAE.Exp, list<Statement>> outBranch;
algorithm
  outBranch := match(inBranch, inContext, inSymbolTable)
    local
      DAE.Exp cond_exp;
      list<Statement> branch_body;
      Context c;

    case ((cond_exp, branch_body), c, _)
      equation
        (cond_exp, _, _) = typeExp(cond_exp, EVAL_CONST(), c, inSymbolTable);
        /* ------------------------------------------------------------------*/
        // TODO: Type-check the condition
        /* ------------------------------------------------------------------*/
        branch_body = typeStatements(branch_body, c, inSymbolTable);
      then
        ((cond_exp, branch_body));

  end match;
end typeBranchStatement;

protected function lookupFunction
  input Absyn.Path inPath;
  input HashTablePathToFunction.HashTable inTable;
  output Function outFunction;
algorithm
  outFunction := matchcontinue(inPath, inTable)
    local
      String func_str;

    case (_, _) then BaseHashTable.get(inPath, inTable);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); 
        func_str = Absyn.pathString(inPath);
        Debug.traceln("- Typing.lookupFunction could not find the function " +& func_str);
      then
        fail();

  end matchcontinue;
end lookupFunction;
        
public function typeFunction
  input Absyn.Path inPath;
  input tuple<HashTablePathToFunction.HashTable, SymbolTable> inTpl;
  output tuple<HashTablePathToFunction.HashTable, SymbolTable> outTpl;
protected
  HashTablePathToFunction.HashTable ht;
  SymbolTable st;
  Function func;
algorithm
  (ht, st) := inTpl;
  func := lookupFunction(inPath, ht);
  outTpl := typeFunction2(func, inPath, ht, st);
end typeFunction;
  
public function typeFunction2
  input Function inFunction;
  input Absyn.Path inPath;
  input FunctionTable inFunctionTable;
  input SymbolTable inSymbolTable;
  output tuple<FunctionTable, SymbolTable> outTuple;
algorithm
  outTuple := matchcontinue (inFunction, inPath, inFunctionTable, inSymbolTable)
    local
      list<InstTypes.Element> inputs,outputs,locals;
      list<InstTypes.Statement> al;
      HashTablePathToFunction.HashTable ht;
      SymbolTable st;

    case (InstTypes.FUNCTION(inputs = inputs, outputs = outputs, locals = locals,
        algorithms = al), _, ht, st)
      equation
        st = InstSymbolTable.addFunctionScope(st);
        (_, st) = InstSymbolTable.addElements(inputs, st);
        (_, st) = InstSymbolTable.addElements(outputs, st);
        (_, st) = InstSymbolTable.addElements(locals, st);
        (inputs, st) = List.map2Fold(inputs, typeElement, NONE(), CONTEXT_FUNCTION(), st);
        (outputs, st) = List.map2Fold(outputs, typeElement, NONE(), CONTEXT_FUNCTION(), st);
        (locals, st) = List.map2Fold(locals, typeElement, NONE(), CONTEXT_FUNCTION(), st);
        al = typeStatements(al, CONTEXT_FUNCTION(), st);
        ht = BaseHashTable.add((inPath, InstTypes.FUNCTION(inPath, inputs, outputs, locals, al)), ht);
        _::st = st;
      then
        ((ht, st));

    case (InstTypes.RECORD(path = _), _, ht, st)
      equation
        print("- Typing.typeFunction2: Support for record constructors not yet implemented.\n");
      then
        ((ht, st));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Typing.typeFunction2 failed on function " +&
          Absyn.pathString(inPath));
      then 
        fail();

  end matchcontinue;
end typeFunction2;

end Typing;
