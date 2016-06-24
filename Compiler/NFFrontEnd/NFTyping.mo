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

encapsulated package NFTyping
" file:        NFTyping.mo
  package:     NFTyping
  description: SCodeInst typing.


  Functions used by SCodeInst for typing.
"

public import Absyn;
public import NFConnect2;
public import DAE;
public import HashTablePathToFunction;
public import NFInstSymbolTable;
public import NFInstPrefix;
public import NFInstTypes;
public import SCode;

protected import BaseHashTable;
protected import ClassInf;
protected import ComponentReference;
protected import NFConnectCheck;
protected import NFConnectEquations;
protected import NFConnectUtil2;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import NFInstUtil;
protected import List;
protected import Types;
protected import NFTypeCheck;

public type Binding = NFInstTypes.Binding;
public type Class = NFInstTypes.Class;
public type Component = NFInstTypes.Component;
public type Connections = NFConnect2.Connections;
public type Connector = NFConnect2.Connector;
public type ConnectorType = NFConnect2.ConnectorType;
public type DaePrefixes = NFInstTypes.DaePrefixes;
public type Dimension = NFInstTypes.Dimension;
public type Element = NFInstTypes.Element;
public type Equation = NFInstTypes.Equation;
public type Face = NFConnect2.Face;
public type Function = NFInstTypes.Function;
public type FunctionTable = HashTablePathToFunction.HashTable;
public type Modifier = NFInstTypes.Modifier;
public type ParamType = NFInstTypes.ParamType;
public type Prefixes = NFInstTypes.Prefixes;
public type Prefix = NFInstPrefix.Prefix;
public type Statement = NFInstTypes.Statement;
public type SymbolTable = NFInstSymbolTable.SymbolTable;
public type FunctionHashTable = HashTablePathToFunction.HashTable;

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
  input FunctionHashTable inFunctionTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) :=
    typeClass2(inClass, NONE(), inContext, inSymbolTable, inFunctionTable);
end typeClass;

public function typeClass2
  input Class inClass;
  input Option<Component> inParent;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inParent, inContext, inSymbolTable, inFunctionTable)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<list<Statement>> al, ial;
      SymbolTable st;
      Absyn.Path name;

    case (NFInstTypes.BASIC_TYPE(_), _, _, st, _) then (inClass, st);

    case (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), _, _, st, _)
      equation
        (comps, st) = List.map3Fold(comps, typeElement, inParent, inContext, inFunctionTable, st);
      then
        (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), st);

  end match;
end typeClass2;

protected function typeElement
  input Element inElement;
  input Option<Component> inParent;
  input Context inContext;
  input FunctionHashTable inFunctionTable;
  input SymbolTable inSymbolTable;
  output Element outElement;
  output SymbolTable outSymbolTable;
algorithm
  (outElement, outSymbolTable) :=
  match(inElement, inParent, inContext, inFunctionTable, inSymbolTable)
    local
      Component comp;
      Class cls;
      Absyn.Path name;
      SymbolTable st;

    case (NFInstTypes.ELEMENT(NFInstTypes.UNTYPED_COMPONENT(name = name), cls),
        _, _, _, st)
      equation
        comp = NFInstSymbolTable.lookupName(name, st);
        (comp, st) = typeComponent(comp, inParent, inContext, st, inFunctionTable);
        (cls, st) = typeClass2(cls, SOME(comp), inContext, st, inFunctionTable);
        (comp, st) = updateComplexComponentType(comp, cls, st);
      then
        (NFInstTypes.ELEMENT(comp, cls), st);

    case (NFInstTypes.ELEMENT(comp, cls), _, _, _, st)
      equation
        comp = NFInstUtil.setComponentParent(comp, inParent);
        (cls, st) = typeClass2(cls, SOME(comp), inContext, st, inFunctionTable);
      then
        (NFInstTypes.ELEMENT(comp, cls), st);

    else (inElement, inSymbolTable);

  end match;
end typeElement;

protected function typeComponent
  input Component inComponent;
  input Option<Component> inParent;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) :=
  match(inComponent, inParent, inContext, inSymbolTable, inFunctionTable)
    local
      Absyn.Path name;
      DAE.Type ty;
      Binding binding;
      SymbolTable st;
      Component comp, inner_comp;
      Context c;

    case (NFInstTypes.UNTYPED_COMPONENT( baseType = ty),
        _, c, st, _)
      equation
        (ty, st) = typeComponentDims(inComponent, inContext, st, inFunctionTable);
        (comp, st) = typeComponentBinding(inComponent, SOME(ty), inParent, c, st, inFunctionTable);
      then
        (comp, st);

    // A typed component without a parent has been typed due to a dependency
    // such as a binding, when parent information was not available. Update it
    // now if we have that information.
    case (NFInstTypes.TYPED_COMPONENT(parent = NONE()), SOME(_), _, st, _)
      equation
        comp = NFInstUtil.setComponentParent(inComponent, inParent);
        st = NFInstSymbolTable.updateComponent(comp, st);
      then
        (comp, st);

    case (NFInstTypes.TYPED_COMPONENT(), _, _, st, _) then (inComponent, st);

    case (NFInstTypes.OUTER_COMPONENT(innerName = SOME(name)), _, _, st, _)
      equation
        comp = NFInstSymbolTable.lookupName(name, st);
        (comp, st) = typeComponent(comp, inParent, inContext, st, inFunctionTable);
      then
        (comp, st);

    case (NFInstTypes.OUTER_COMPONENT( innerName = NONE()), _, _, st, _)
      equation
        (_, SOME(inner_comp), st) = NFInstSymbolTable.updateInnerReference(inComponent, st);
        (inner_comp, st) = typeComponent(inner_comp, inParent, inContext, st, inFunctionTable);
      then
        (inner_comp, st);

    case (NFInstTypes.CONDITIONAL_COMPONENT(name = name), _, _, _, _)
      equation
        print("Trying to type conditional component " + Absyn.pathString(name) + "\n");
      then
        fail();

  end match;
end typeComponent;

protected function typeComponentDims
  input Component inComponent;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outType, outSymbolTable) := matchcontinue(inComponent, inContext, inSymbolTable, inFunctionTable)
    local
      DAE.Type ty;
      SymbolTable st;
      array<Dimension> dims;
      list<DAE.Dimension> typed_dims;
      Absyn.Path name;
      SourceInfo info;

    case (NFInstTypes.UNTYPED_COMPONENT(baseType = ty, dimensions = dims), _, st, _)
      equation
        true = intEq(0, arrayLength(dims));
      then
        (ty, st);

    case (NFInstTypes.UNTYPED_COMPONENT(name = name, baseType = ty, dimensions = dims), _, st, _)
      equation
        (typed_dims, st) = typeDimensions(dims, name, inContext, st, inFunctionTable);
      then
        (DAE.T_ARRAY(ty, typed_dims, DAE.emptyTypeSource), st);

    case (NFInstTypes.TYPED_COMPONENT(ty = ty), _, st, _) then (ty, st);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- NFTyping.typeComponentDims failed on component ");
        Debug.traceln(Absyn.pathString(NFInstUtil.getComponentName(inComponent)));
      then
        fail();

  end matchcontinue;
end typeComponentDims;

protected function typeComponentDim
  input Component inComponent;
  input Integer inIndex;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output DAE.Dimension outDimension;
  output SymbolTable outSymbolTable;
algorithm
  (outDimension, outSymbolTable) := match(inComponent, inIndex, inContext, inSymbolTable, inFunctionTable)
    local
      list<DAE.Dimension> dims;
      DAE.Dimension typed_dim;
      SymbolTable st;
      array<Dimension> dims_arr;
      Dimension dim;
      Absyn.Path name;

    case (NFInstTypes.TYPED_COMPONENT(ty = DAE.T_ARRAY(dims = dims)), _, _, st, _)
      equation
        typed_dim = listGet(dims, inIndex);
      then
        (typed_dim, st);

    case (NFInstTypes.UNTYPED_COMPONENT(name = name, dimensions = dims_arr), _, _, st, _)
      equation
        dim = arrayGet(dims_arr, inIndex);
        (typed_dim, st) = typeDimension(dim, name, inContext, st, inFunctionTable, dims_arr, inIndex);
      then
        (typed_dim, st);

  end match;
end typeComponentDim;

protected function typeDimensions
  input array<Dimension> inDimensions;
  input Absyn.Path inComponentName;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output list<DAE.Dimension> outDimensions;
  output SymbolTable outSymbolTable;
protected
  Integer len;
algorithm
  len := arrayLength(inDimensions);
  (outDimensions, outSymbolTable) :=
    typeDimensions2(inDimensions, inComponentName, inContext, inSymbolTable, inFunctionTable, 1, len, {});
end typeDimensions;

protected function typeDimensions2
  input array<Dimension> inDimensions;
  input Absyn.Path inComponentName;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  input Integer inIndex;
  input Integer inLength;
  input list<DAE.Dimension> inAccDims;
  output list<DAE.Dimension> outDimensions;
  output SymbolTable outSymbolTable;
algorithm
  (outDimensions, outSymbolTable) :=
  matchcontinue(inDimensions, inComponentName, inContext, inSymbolTable, inFunctionTable, inIndex, inLength, inAccDims)
    local
      Dimension dim;
      DAE.Dimension typed_dim;
      SymbolTable st;
      list<DAE.Dimension> dims;

    case (_, _, _, _, _, _, _, _)
      equation
        true = inIndex > inLength;
      then
        (listReverse(inAccDims), inSymbolTable);

    else
      equation
        dim = arrayGet(inDimensions, inIndex);
        (typed_dim, st) =
          typeDimension(dim, inComponentName, inContext, inSymbolTable, inFunctionTable, inDimensions, inIndex);
        (dims, st) = typeDimensions2(inDimensions, inComponentName, inContext, st, inFunctionTable, inIndex + 1,
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
  input FunctionHashTable inFunctionTable;
  input array<Dimension> inDimensions;
  input Integer inIndex;
  output DAE.Dimension outDimension;
  output SymbolTable outSymbolTable;
algorithm
  (outDimension, outSymbolTable) :=
  match(inDimension, inComponentName, inContext, inSymbolTable, inFunctionTable, inDimensions, inIndex)
    local
      SymbolTable st;
      DAE.Dimension inDim,dim;
      DAE.Exp dim_exp;
      Integer  dim_count;
      Dimension typed_dim;
      Component comp;

    case (NFInstTypes.UNTYPED_DIMENSION(isProcessing = true), _, _, _, _, _, _)
      equation
        print("Found dimension loop\n");
      then
        fail();

    case (NFInstTypes.UNTYPED_DIMENSION(dimension = inDim as DAE.DIM_EXP(exp = dim_exp)), _, _, st, _, _, _)
      equation
        arrayUpdate(inDimensions, inIndex, NFInstTypes.UNTYPED_DIMENSION(inDim, true));
        (dim_exp, _, _, st) = typeExp(dim_exp, EVAL_CONST_PARAM(), inContext, st, inFunctionTable);
        (dim_exp, _) = ExpressionSimplify.simplify(dim_exp);
        dim = NFInstUtil.makeDimension(dim_exp);
        typed_dim = NFInstTypes.TYPED_DIMENSION(dim);
        arrayUpdate(inDimensions, inIndex, typed_dim);
      then
        (dim, st);

    case (NFInstTypes.UNTYPED_DIMENSION(dimension = inDim as DAE.DIM_UNKNOWN()), _, CONTEXT_MODEL(), st, _, _, _)
      equation
        arrayUpdate(inDimensions, inIndex, NFInstTypes.UNTYPED_DIMENSION(inDim, true));
        comp = NFInstSymbolTable.lookupName(inComponentName, st);
        (comp, st) = typeComponentBinding(comp, NONE(), NONE(), inContext, st, inFunctionTable);
        dim_count = arrayLength(inDimensions);
        dim = NFInstUtil.getComponentBindingDimension(comp, inIndex, dim_count);
        typed_dim = NFInstTypes.TYPED_DIMENSION(dim);
        arrayUpdate(inDimensions, inIndex, typed_dim);
      then
        (dim, st);

    case (NFInstTypes.UNTYPED_DIMENSION(dimension = dim as DAE.DIM_UNKNOWN()), _, CONTEXT_FUNCTION(), st, _, _, _)
      equation
        arrayUpdate(inDimensions, inIndex, NFInstTypes.TYPED_DIMENSION(dim));
      then
        (dim, st);

    case (NFInstTypes.UNTYPED_DIMENSION(dimension = dim), _, _, st, _, _, _)
      equation
        arrayUpdate(inDimensions, inIndex, NFInstTypes.TYPED_DIMENSION(dim));
      then
        (dim, st);

    case (NFInstTypes.TYPED_DIMENSION(dimension = dim), _, _, st, _, _, _) then (dim, st);

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
  input FunctionHashTable inFunctionTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) :=
  match(inComponent, inType, inParent, inContext, inSymbolTable, inFunctionTable)
    local
      Binding binding;
      SymbolTable st;
      Component comp;
      EvalPolicy ep;

    case (NFInstTypes.UNTYPED_COMPONENT(binding = binding), _, _, _, st, _)
      equation
        st = markComponentBindingAsProcessing(inComponent, st);
        ep = getEvalPolicyForBinding(inComponent);
        (binding, st) = typeBinding(binding, ep, inContext, st, inFunctionTable);
        comp = updateComponentBinding(inComponent, binding, inType, inParent);
        st = NFInstSymbolTable.updateComponent(comp, st);
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
    case NFInstTypes.UNTYPED_COMPONENT(paramType = NFInstTypes.STRUCT_PARAM())
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
      SourceInfo info;

    case (NFInstTypes.UNTYPED_COMPONENT(name = name, prefixes = pf, info = info),
        _, SOME(ty), _)
      equation
        dpf = NFInstUtil.translatePrefixes(pf);
      then
        NFInstTypes.TYPED_COMPONENT(name, ty, inParent, dpf, inBinding, info);

    case (NFInstTypes.UNTYPED_COMPONENT(name, ty, dims, pf, pty, _, info), _, NONE(), _)
      then NFInstTypes.UNTYPED_COMPONENT(name, ty, dims, pf, pty, inBinding, info);

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
      SourceInfo info1, info2;

    case (NFInstTypes.UNTYPED_COMPONENT(prefixes = NFInstTypes.PREFIXES(variability = var)), _)
      equation
        false = SCode.isParameterOrConst(var);
      then
        inSymbolTable;

    case (NFInstTypes.UNTYPED_COMPONENT(name, ty, dims, pf, pty,
        NFInstTypes.UNTYPED_BINDING(binding_exp, _, pl, info1), info2), _)
      equation
        comp = NFInstTypes.UNTYPED_COMPONENT(name, ty, dims, pf, pty,
          NFInstTypes.UNTYPED_BINDING(binding_exp, true, pl, info1), info2);
      then
        NFInstSymbolTable.updateComponent(comp, inSymbolTable);

    case (NFInstTypes.UNTYPED_COMPONENT(), _) then inSymbolTable;

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
  input FunctionHashTable inFunctionTable;
  output Binding outBinding;
  output SymbolTable outSymbolTable;
algorithm
  (outBinding, outSymbolTable) :=
  match(inBinding, inEvalPolicy, inContext, inSymbolTable, inFunctionTable)
    local
      DAE.Exp binding;
      SymbolTable st;
      DAE.Type ty;
      Integer pd;
      SourceInfo info;

    case (NFInstTypes.UNTYPED_BINDING(isProcessing = true), _, _, st, _)
      equation
        NFInstSymbolTable.showCyclicDepError(st);
      then
        fail();

    case (NFInstTypes.UNTYPED_BINDING(bindingExp = binding, propagatedDims = pd,
        info = info), _, _, st, _)
      equation
        (binding, ty, _, st) = typeExp(binding, inEvalPolicy, inContext, st, inFunctionTable);
        checkBindingTypeOk(ty, Expression.typeof(binding), binding, info);
      then
        (NFInstTypes.TYPED_BINDING(binding, ty, pd, info), st);

    case (NFInstTypes.TYPED_BINDING(), _, _, st, _)
      then (inBinding, st);

    else (NFInstTypes.UNBOUND(), inSymbolTable);

  end match;
end typeBinding;

protected function checkBindingTypeOk
  input DAE.Type inTy1;
  input DAE.Type inTy2;
  input DAE.Exp inExp;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inTy1, inTy2, inExp, inInfo)
    local
      DAE.Type t1, t2;
      DAE.Exp e;
      SourceInfo info;
      String str;

    case (t1, t2, e, _)
      equation
        (_, _) = Types.matchType(e, t2, t1, true);
      then
        ();

    case (t1, t2, e, info)
      equation
        str = ExpressionDump.printExpStr(e);
        str = "NFTyping.checkBindingTypeOk: expression: " + str;
        str = str + ", binding type: " + Types.unparseType(t1);
        str = str + " != expression type: " + Types.unparseType(t2);
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
      then
        fail();
  end matchcontinue;
end checkBindingTypeOk;

protected function updateComplexComponentType
  input Component inComponent;
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Component outComponent;
  output SymbolTable outSymbolTable;
algorithm
  (outComponent, outSymbolTable) :=
  match(inComponent, inClass, inSymbolTable)
    local
      ClassInf.State state;
      DAE.EqualityConstraint ec;
      DAE.TypeSource ty_src;
      list<DAE.Var> vars;
      list<Element> elems;
      SymbolTable st;
      DAE.Type base_ty, ty;
      Component comp;

    // Complex base type, update the vars in the type.
    case (NFInstTypes.TYPED_COMPONENT(ty = ty),
        NFInstTypes.COMPLEX_CLASS(components = elems), st)
      equation
        DAE.T_COMPLEX(state, _, ec, ty_src) = Types.arrayElementType(ty);
        vars = List.accumulateMapReverse(elems, NFInstUtil.makeDaeVarsFromElement);
        base_ty = DAE.T_COMPLEX(state, vars, ec, ty_src);
        ty = Types.setArrayElementType(ty, base_ty);
        comp = NFInstUtil.setTypedComponentType(inComponent, ty);
        st = NFInstSymbolTable.updateComponent(comp, st);
      then
        (comp, st);

    else (inComponent, inSymbolTable);

  end match;
end updateComplexComponentType;

protected function typeExpList
  input list<DAE.Exp> inExpList;
  input EvalPolicy inEvalPolicy;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output list<DAE.Exp> outExpList;
  output list<DAE.Type> outTypeList;
  output list<DAE.Const> outConstList;
  output SymbolTable outSymbolTable;
algorithm
  (outExpList, outTypeList, outConstList, outSymbolTable) :=
  match(inExpList, inEvalPolicy, inContext, inSymbolTable, inFunctionTable)
    local
      DAE.Exp exp;
      list<DAE.Exp> rest_expl;
      EvalPolicy ep;
      SymbolTable st;
      DAE.Type ty;
      list<DAE.Type> tyList;
      Context c;
      list<DAE.Const> constList;
      DAE.Const const;

    case ({}, _, _, st, _) then ({}, {}, {}, st);

    case (exp :: rest_expl, ep, c, st, _)
      equation
        (exp, ty, const, st) = typeExp(exp, ep, c, st, inFunctionTable);
        (rest_expl, tyList, constList, st) = typeExpList(rest_expl, ep, c, st, inFunctionTable);
      then
        (exp::rest_expl, ty::tyList, const::constList, st);

  end match;
end typeExpList;

public function typeExpOpt
  input Option<DAE.Exp> inExp;
  input EvalPolicy inEvalPolicy;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output Option<DAE.Exp> outExp;
  output Option<DAE.Type> outType;
  output DAE.Const outConst;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outConst, outSymbolTable) := match(inExp, inEvalPolicy, inContext, inSymbolTable, inFunctionTable)
    local
      DAE.Exp exp;
      SymbolTable st;
      DAE.Type ty;
      DAE.Const const;

    case (SOME(exp), _, _, st, _)
      equation
        (exp, ty, const, st) = typeExp(exp, inEvalPolicy, inContext, st, inFunctionTable);
      then
        (SOME(exp), SOME(ty), const, st);

    else (NONE(), NONE(), DAE.C_CONST(), inSymbolTable);

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
    else inTy1;
  end match;
end selectType;

public function typeExpEmptyFunctionTable
  input DAE.Exp inExp;
  input EvalPolicy inEvalPolicy;
  input Context inContext;
  input SymbolTable inSymbolTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output DAE.Const outConst;
  output SymbolTable outSymbolTable;
protected
  FunctionHashTable functionTable;
algorithm
  functionTable := HashTablePathToFunction.emptyHashTableSized(BaseHashTable.lowBucketSize);
  (outExp, outType, outConst, outSymbolTable) := typeExp(inExp, inEvalPolicy, inContext, inSymbolTable, functionTable);
end typeExpEmptyFunctionTable;


public function typeExp
  input DAE.Exp inExp;
  input EvalPolicy inEvalPolicy;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output DAE.Const outConst;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outConst, outSymbolTable) :=
  match(inExp, inEvalPolicy, inContext, inSymbolTable, inFunctionTable)
    local
      DAE.Exp e1, e2, e3;
      DAE.ComponentRef cref;
      DAE.Type ty,ty1,ty2,tyOp;
      SymbolTable st;
      FunctionHashTable ft;
      DAE.Operator op;
      Component comp;
      Integer dim_int;
      DAE.Dimension dim;
      list<DAE.Exp> expl, args;
      list<DAE.Type> tyList;
      EvalPolicy ep;
      Option<DAE.Exp> oe;
      Context c;
      DAE.Const const,const1,const2,const3;
      list<DAE.Const> constList;
      Absyn.Path fnName, name;
      DAE.CallAttributes attrs;
      Function func;

    case (DAE.ICONST(), _, _, st, _)
      then (inExp, DAE.T_INTEGER_DEFAULT, DAE.C_CONST(), st);

    case (DAE.RCONST(), _, _, st, _)
      then (inExp, DAE.T_REAL_DEFAULT, DAE.C_CONST(), st);

    case (DAE.SCONST(), _, _, st, _)
      then (inExp, DAE.T_STRING_DEFAULT, DAE.C_CONST(), st);

    case (DAE.BCONST(), _, _, st, _)
      then (inExp, DAE.T_BOOL_DEFAULT, DAE.C_CONST(), st);
    // BTH
    case (DAE.CLKCONST(), _, _, st, _)
      then (inExp, DAE.T_CLOCK_DEFAULT, DAE.C_CONST(), st);

    case (DAE.ENUM_LITERAL(name = name), _, _, st, _)
      equation
        NFInstTypes.TYPED_COMPONENT(ty = ty) =
          NFInstSymbolTable.lookupName(name, st);
      then
        (inExp, ty, DAE.C_CONST(), st);

    case (DAE.CREF(componentRef = cref), ep, c, st, _)
      equation
        (e1, ty, const, st) = typeCref(cref, ep, c, st, inFunctionTable);
      then
        (e1, ty, const, st);

    case (DAE.ARRAY(array = expl), ep, c, st, ft)
      equation
        (expl, ty::_ , constList, st) = typeExpList(expl, ep, c, st, ft);
        dim_int = listLength(expl);
        ty = DAE.T_ARRAY(ty, {DAE.DIM_INTEGER(dim_int)}, DAE.emptyTypeSource);
        const = List.fold(constList, Types.constAnd, DAE.C_CONST());
      then
        (DAE.ARRAY(ty, true, expl), ty, const, st);

    case (DAE.BINARY(exp1 = e1, operator = op, exp2 = e2), ep, c, st, ft)
      equation
        (e1, ty1, const1, st) = typeExp(e1, ep, c, st, ft);
        (e2, ty2, const2, st) = typeExp(e2, ep, c, st, ft);

         // Check operands vs operator
        (e3,ty) = NFTypeCheck.checkBinaryOperation(e1,ty1,op,e2,ty2);

        const = Types.constAnd(const1, const2);
      then
        (e3, ty, const, st);

    case (DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2), ep, c, st, ft)
      equation
        (e1, ty1, const1, st) = typeExp(e1, ep, c, st, ft);
        (e2, ty2, const2, st) = typeExp(e2, ep, c, st, ft);

        // Check operands vs operator
        (_,ty) = NFTypeCheck.checkLogicalBinaryOperation(e1,ty1,op,e2,ty2);

        const = Types.constAnd(const1, const2);
      then
        (DAE.LBINARY(e1, op, e2), ty, const, st);

    case (DAE.LUNARY(operator = op, exp = e1), ep, c, st, ft)
      equation
        (e1, ty, const, st) = typeExp(e1, ep, c, st, ft);
        tyOp = Expression.typeofOp(op);
        ty = selectType(tyOp, ty);
      then
        (DAE.LUNARY(op, e1), ty, const, st);

    case (DAE.RELATION(exp1 = e1, operator = op, exp2 = e2), ep, c, st, ft)
      equation
        (e1, ty1, const1, st) = typeExp(e1, ep, c, st, ft);
        (e2, ty2, const2, st) = typeExp(e2, ep, c, st, ft);

         // Check operands vs operator
        (e3,ty) = NFTypeCheck.checkRelationOperation(e1,ty1,op,e2,ty2);

        const = Types.constAnd(const1, const2);
      then
        (e3, ty, const, st);

    case (DAE.SIZE(exp = e1 as DAE.CREF(componentRef = cref), sz = SOME(e2)), _, c, st, ft)
      equation
        (e2 as DAE.ICONST(dim_int), _, _, st) = typeExp(e2, EVAL_CONST_PARAM(), c, st, ft);
        comp = NFInstSymbolTable.lookupCref(cref, st);
        (dim, st) = typeComponentDim(comp, dim_int, c, st, ft);
        e3 = dimensionExp(dim, e1, e2, c);
      then
        (e3, DAE.T_INTEGER_DEFAULT, DAE.C_CONST(), st);

    case (DAE.RANGE(start = e1, step = oe, stop = e2), ep, c, st, ft)
      equation
        (e1, ty, const1, st) = typeExp(e1, ep, c, st, ft);
        (oe, _, const2, st) = typeExpOpt(oe, ep, c, st, ft);
        (e2, _, const3, st) = typeExp(e2, ep, c, st, ft);
        ty = Expression.liftArrayLeft(ty, DAE.DIM_UNKNOWN());
        const = Types.constAnd(const1,Types.constAnd(const2,const3));
      then
        (DAE.RANGE(ty, e1, oe, e2), ty, const, st);

    case (DAE.MATRIX(), _, _, _, _)
      equation
        /* ------------------------------------------------------------------*/
        // TODO: Remove MATRIX from DAE when we remove the old instantiation.
        // For now, print an error in case we get such an expression here.
        /* ------------------------------------------------------------------*/
        Error.addMessage(Error.INTERNAL_ERROR,
          {"NFTyping.typeExp got obsolete MATRIX expression."});
      then
        fail();

    case (DAE.CALL(path = fnName, expLst = args, attr = attrs), ep, c, st, ft)
      equation
        // Make sure that the func is there before typing the arguments
        func = lookupFunction(fnName, inFunctionTable);

        (args, tyList, constList, st) = typeExpList(args, ep, c, st, ft);
        (e1,ty) = typeCall(func, args, tyList, attrs, st);
        const = List.fold(constList, Types.constAnd, DAE.C_CONST());
      then
        (e1, ty, const, st);

    else (inExp, DAE.T_UNKNOWN_DEFAULT, DAE.C_VAR(), inSymbolTable);
    //else
    //  equation
    //    print("typeExp: unknown expression " +
    //        ExpressionDump.printExpStr(inExp) + "\n");
    //  then
    //    fail();

  end match;
end typeExp;


protected function typeCall
"@mahge:
  Handles typing of calls.
  Extracts the input and output types of a function. Matches the given
  call arguments againest the function inputs. constructs the return type
  for the function. Vectorizes if necessary."
  input Function inFunc;
  input list<DAE.Exp> inArgs;
  input list<DAE.Type> inArgTypes;
  input DAE.CallAttributes inAttrs;
  input SymbolTable inSymbolTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
algorithm
  (outExp, outType) := matchcontinue(inFunc, inArgs, inArgTypes, inAttrs, inSymbolTable)
    local
      DAE.Exp outexp;
      DAE.Type retType, outtype;
      list<DAE.Exp> fixedArgs;
      list<Element> inputs, outputs;
      list<DAE.Type> inputTypes, outputTypes;
      Boolean isTuple, isBuiltin, isImpure, isFunctionPointerCall;
      DAE.InlineType inlineType;
      DAE.TailCall tailCall;
      DAE.CallAttributes attrs;
      DAE.Dimensions forEachDim;
      Absyn.Path fnName;

      case(NFInstTypes.FUNCTION(fnName, inputs, outputs, _, _), _, _, _, _)
        equation

          // Match the args of the call exp againest the input/formal types of the function.
          // We get matched args and a 'foreachdim' if vectorization is done
          inputTypes = List.map(inputs, NFInstUtil.getElementComponentType);
          (fixedArgs, forEachDim) = NFTypeCheck.matchCallArgs(inArgs, inArgTypes, inputTypes, {} /*vectorization dim*/);

          // Create the return type for the function
          outputTypes = List.map(outputs, NFInstUtil.getElementComponentType);
          (retType, isTuple) = NFTypeCheck.makeCallReturnType(outputTypes);

          // create the call attributes. retType + isTuple
          DAE.CALL_ATTR( _, _, isBuiltin, isImpure, isFunctionPointerCall, inlineType, tailCall) = inAttrs;
          attrs = DAE.CALL_ATTR(retType, isTuple, isBuiltin, isImpure, isFunctionPointerCall, inlineType, tailCall);

          // See if we need to vectorize the call i.e. if we have 'forEachDim' then
          // we return an array exp other wise a call exp.
          (outexp,outtype) = NFTypeCheck.vectorizeCall(fnName, fixedArgs, attrs, retType, forEachDim);

        then
          (outexp,outtype);

      case(NFInstTypes.RECORD_CONSTRUCTOR(fnName, retType, inputs, _, _), _, _, _, _)
        equation

          // Match the args of the call exp againest the input/formal types of the function.
          // We get matched args and a 'foreachdim' if vectorization is done
          inputTypes = List.map(inputs, NFInstUtil.getElementComponentType);
          (fixedArgs, forEachDim) = NFTypeCheck.matchCallArgs(inArgs, inArgTypes, inputTypes, {} /*vectorization dim*/);

          // retType = DAE.T_COMPLEX(ClassInf.RECORD(fnName), inputs, NONE(), DAE.emptyTypeSource);
          // Create the return type for the record constructor
          // rec = NFInstSymbolTable.lookupName(fnName, inSymbolTable);
          // retType = NFInstUtil.getComponentType(rec);

          // Create the return type for the function
          // outputTypes = List.map(outputs, NFInstUtil.getElementComponentType);
          // (retType, isTuple) = NFTypeCheck.makeCallReturnType(outputTypes);

          // create the call attributes. retType + isTuple
          DAE.CALL_ATTR( _, _, isBuiltin, isImpure, isFunctionPointerCall, inlineType, tailCall) = inAttrs;
          attrs = DAE.CALL_ATTR(retType, false, isBuiltin, isImpure, isFunctionPointerCall, inlineType, tailCall);

          // See if we need to vectorize the call i.e. if we have 'forEachDim' then
          // we return an array exp other wise a call exp.
          (outexp,outtype) = NFTypeCheck.vectorizeCall(fnName, fixedArgs, attrs, retType, forEachDim);

        then
          (outexp,outtype);

      else
        equation
          Error.addMessage(Error.INTERNAL_ERROR,
            {"NFTyping.typeCall Failed."});
        then
          fail();

  end matchcontinue;
end typeCall;


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
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output DAE.Const outConst;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outConst, outSymbolTable) :=
  matchcontinue(inCref, inEvalPolicy, inContext, inSymbolTable, inFunctionTable)
    local
      SymbolTable st;
      Component comp;
      DAE.Type ty;
      DAE.Exp exp;
      SCode.Variability var;
      Boolean eval;
      DAE.ComponentRef cref;
      EvalPolicy ep;
      Context c;
      DAE.Const const;

    case (_, ep, c, st, _)
      equation
        comp = NFInstSymbolTable.lookupCref(inCref, st);
        var = NFInstUtil.getEffectiveComponentVariability(comp);
        const = NFInstUtil.toConst(var);
        eval = shouldEvaluate(var, ep);
        (exp, ty, st) = typeCref2(inCref, comp, eval, ep, c, st, inFunctionTable);
      then
        (exp, ty, const, st);

    case (_, ep, c, st, _)
      equation
        (cref, st) = NFInstUtil.replaceCrefOuterPrefix(inCref, st);
        (exp, ty, const, st) = typeCref(cref, ep, c, st, inFunctionTable);
      then
        (exp, ty, const, st);

    else
      equation
        print("Failed to type cref " +
            ComponentReference.printComponentRefStr(inCref) + "\n");
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
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output DAE.Exp outExp;
  output DAE.Type outType;
  output SymbolTable outSymbolTable;
algorithm
  (outExp, outType, outSymbolTable) :=
  match(inCref, inComponent, inShouldEvaluate, inEvalPolicy, inContext, inSymbolTable, inFunctionTable)
    local
      DAE.Type ty;
      Binding binding;
      SymbolTable st;
      DAE.Exp exp;
      Absyn.Path inner_name;
      Component inner_comp;
      DAE.ComponentRef inner_cref, cref;
      EvalPolicy ep;
      Boolean se;
      Context c;

    case (_, NFInstTypes.TYPED_COMPONENT(ty = ty, binding = binding), true, ep, c, st, _)
      equation
        /* ------------------------------------------------------------------*/
        // TODO: The start value should be used if a parameter or constant has
        // fixed = true, and no binding.
        /* ------------------------------------------------------------------*/
        exp = NFInstUtil.getBindingExp(binding);
        /* ------------------------------------------------------------------*/
        // TODO: Apply cref subscripts to the expression.
        /* ------------------------------------------------------------------*/
        // type the actual expression as the cref might have WRONG TYPE!
        (exp, ty, _, st) = typeExp(exp, ep, c, st, inFunctionTable);
      then
        (exp, ty, st);

    case (_, NFInstTypes.TYPED_COMPONENT(ty = ty), false, _, _, st, _)
      equation
        ty = propagateCrefSubsToType(ty, inCref);
        cref = NFInstUtil.typeCrefWithComponent(inCref, inComponent);
      then
        (DAE.CREF(cref, ty), ty, st);

    case (_, NFInstTypes.UNTYPED_COMPONENT(), true, _, c, st, _)
      equation
        (NFInstTypes.TYPED_COMPONENT(ty = ty, binding = binding), st) =
          typeComponent(inComponent, NONE(), c, st, inFunctionTable);
        exp = NFInstUtil.getBindingExp(binding);
        /* ------------------------------------------------------------------*/
        // TODO: Apply cref subscripts to the expression.
        /* ------------------------------------------------------------------*/
      then
        (exp, ty, st);

    case (_, NFInstTypes.UNTYPED_COMPONENT(), false, _, c, st, _)
      equation
        (ty, st) = typeComponentDims(inComponent, c, st, inFunctionTable);
        ty = propagateCrefSubsToType(ty, inCref);
      then
        (DAE.CREF(inCref, ty), ty, st);

    case (_, NFInstTypes.OUTER_COMPONENT(), se, ep, c, st, _)
      equation
        (inner_comp, st) = typeComponent(inComponent, NONE(), c, st, inFunctionTable);
        inner_name = NFInstUtil.getComponentName(inner_comp);
        inner_cref = NFInstUtil.removeCrefOuterPrefix(inner_name, inCref);
        (exp, ty, st) = typeCref2(inner_cref, inner_comp, se, ep, c, st, inFunctionTable);
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
        (exp, _) = Expression.traverseExp(exp, propagateCrefSubsToExpTraverser, inCref);
      then DAE.DIM_EXP(exp);

    else inDimension;
  end match;
end propagateCrefSubsToDimension;

protected function propagateCrefSubsToExpTraverser
  input DAE.Exp inExp;
  input DAE.ComponentRef inCr;
  output DAE.Exp outExp;
  output DAE.ComponentRef outCref;
algorithm
  (outExp,outCref) := match (inExp,inCr)
    local
      DAE.ComponentRef cref1, cref2;
      DAE.Type ty;

    case (DAE.CREF(cref1, ty), cref2)
      equation
        cref1 = propagateCrefSubsToCref(cref1, cref2);
        ty = propagateCrefSubsToType(ty, cref2);
      then
        (DAE.CREF(cref1, ty), cref2);

    else (inExp,inCr);
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
  input FunctionHashTable inFunctionTable;
  output Class outClass;
  output Connections outConnections;
algorithm
  (outClass, outConnections) := typeSections2(inClass, inSymbolTable,
    inFunctionTable,NFConnect2.emptyConnections);
end typeSections;

public function typeSections2
  input Class inClass;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  input Connections inConnections;
  output Class outClass;
  output Connections outConnections;
algorithm
  (outClass, outConnections) := match(inClass, inSymbolTable, inFunctionTable, inConnections)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<list<Statement>> al, ial;
      SymbolTable st;
      Connections conn;
      Absyn.Path name;

    case (NFInstTypes.BASIC_TYPE(_), _, _, _) then (inClass, inConnections);

    case (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), st, _, conn)
      equation
        (comps, conn) = typeSectionsInElements(comps, st, inFunctionTable, conn);
        (eq, conn) = typeEquations(eq, st, inFunctionTable, conn);
        // Connections are not allowed in initial equation sections, so we
        // shouldn't get any connections back from typeEquations here.
        (ieq, _) =
          typeEquations(ieq, st, inFunctionTable, NFConnect2.emptyConnections);
        al = typeAlgorithms(al, st, inFunctionTable);
        ial = typeAlgorithms(ial, st, inFunctionTable);
      then
        (NFInstTypes.COMPLEX_CLASS(name, comps, eq, ieq, al, ial), conn);

  end match;
end typeSections2;

protected function typeSectionsInElements
  input list<Element> inElements;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  input Connections inConnections;
  output list<Element> outElements;
  output Connections outConnections;
algorithm
  (outElements, outConnections) := List.map2Fold(inElements,
    typeSectionsInElement, inSymbolTable, inFunctionTable, inConnections);
end typeSectionsInElements;

protected function typeSectionsInElement
  input Element inElement;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  input Connections inConnections;
  output Element outElement;
  output Connections outConnections;
algorithm
  (outElement, outConnections) := match(inElement, inSymbolTable, inFunctionTable, inConnections)
    local
      Component comp;
      Class cls;
      SymbolTable st;
      Connections conn;

    case (NFInstTypes.ELEMENT(comp, cls), st, _, conn)
      equation
        (cls, conn) = typeSections2(cls, st, inFunctionTable, conn);
      then
        (NFInstTypes.ELEMENT(comp, cls), conn);

    case (NFInstTypes.CONDITIONAL_ELEMENT(_), _, _, _)
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"NFTyping.typeSectionsInElement got a conditional element!"});
      then
        fail();

  end match;
end typeSectionsInElement;

protected function typeEquations
  input list<Equation> inEquations;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  input Connections inConnections;
  output list<Equation> outEquations;
  output Connections outConnections;
algorithm
  (outEquations, outConnections) :=
    typeEquations2(inEquations, inSymbolTable, inFunctionTable, {}, inConnections);
end typeEquations;

protected function typeEquations2
  input list<Equation> inEquations;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  input list<Equation> inAccumEql;
  input Connections inConnections;
  output list<Equation> outEquations;
  output Connections outConnections;
algorithm
  (outEquations, outConnections) :=
  match(inEquations, inSymbolTable, inFunctionTable, inAccumEql, inConnections)
    local
      Equation eq;
      list<Equation> rest_eq, acc_eq;
      SymbolTable st;
      Connections conn;

    case (eq :: rest_eq, st, _, acc_eq, _)
      equation
        (acc_eq, conn) = typeEquation(eq, st, inFunctionTable, acc_eq, inConnections);
        (acc_eq, conn) = typeEquations2(rest_eq, st, inFunctionTable, acc_eq, conn);
      then
        (acc_eq, conn);

    case ({}, _, _, _, _) then (listReverse(inAccumEql), inConnections);

  end match;
end typeEquations2;

protected function typeEquation
  input Equation inEquation;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  input list<Equation> inAccumEql;
  input Connections inConnections;
  output list<Equation> outAccumEql;
  output Connections outConnections;
algorithm
  (outAccumEql, outConnections) :=
  match(inEquation, inSymbolTable, inFunctionTable, inAccumEql, inConnections)
    local
      DAE.Exp rhs, lhs, exp1, exp2, exp3;
      list<DAE.Exp> args;
      SymbolTable st;
      SourceInfo info;
      DAE.ComponentRef cref1, cref2;
      Prefix prefix;
      String name;
      Integer index;
      list<Equation> eql;
      DAE.Type ty, ty1, ty2, tty1, tty2;
      list<tuple<DAE.Exp, list<Equation>>> branches;
      list<Equation> acc_el;
      Absyn.Path iter_name;
      Component iter;
      Equation eq;
      Connections conn;

    case (NFInstTypes.EQUALITY_EQUATION(lhs, rhs, info), st, _, acc_el, _)
      equation
        (lhs, ty1, _, _) = typeExp(lhs, EVAL_CONST(), CONTEXT_MODEL(), st, inFunctionTable);
        (rhs, ty2, _, _) = typeExp(rhs, EVAL_CONST(), CONTEXT_MODEL(), st, inFunctionTable);

        (lhs,_, rhs,_) = NFTypeCheck.checkExpEquality(lhs, ty1, rhs, ty2, "equ", info);

        eq = NFInstTypes.EQUALITY_EQUATION(lhs, rhs, info);
      then
        (eq :: acc_el, inConnections);

    case (NFInstTypes.CONNECT_EQUATION(cref1, _, _, cref2, _, _, prefix, info),
        st, _, acc_el, conn)
      equation
        (acc_el, conn) = typeConnection(cref1, cref2, prefix, st, info, acc_el, conn);
      then
        (acc_el, conn);

    case (NFInstTypes.FOR_EQUATION(name, index, _, SOME(exp1), eql, info), st, _, acc_el, conn)
      equation
        (exp1, ty, _, _) = typeExp(exp1, EVAL_CONST_PARAM(), CONTEXT_MODEL(), st, inFunctionTable);
        ty = rangeToIteratorType(ty, exp1, info);
        iter_name = Absyn.IDENT(name);
        iter = NFInstUtil.makeIterator(iter_name, ty, info);
        st = NFInstSymbolTable.addIterator(iter_name, iter, st);
        (eql, conn) = typeEquations(eql, st, inFunctionTable, conn);
        eq = NFInstTypes.FOR_EQUATION(name, index, ty, SOME(exp1), eql, info);
      then
        (eq :: acc_el, conn);

    case (NFInstTypes.FOR_EQUATION(_, _, _, NONE(), _, info), _, _, _, _)
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR,{"Implicit for ranges are not yet implemented"},info);
      then fail();

    case (NFInstTypes.IF_EQUATION(branches, info), st, _, acc_el, _)
      equation
        (branches, conn) = typeBranches(branches, st, inFunctionTable);
        eq = NFInstTypes.IF_EQUATION(branches, info);
        /* ------------------------------------------------------------------*/
        // TODO: Check conn here, connections are not allowed inside
        // if-equations with non-parametric conditions.
        /* ------------------------------------------------------------------*/
      then
        (eq :: acc_el, conn);

    case (NFInstTypes.WHEN_EQUATION(branches, info), st, _, acc_el, _)
      equation
        (branches, conn) = typeBranches(branches, st, inFunctionTable);
        /* ------------------------------------------------------------------*/
        // TODO: Check conn here, connections are not allowed inside when.
        /* ------------------------------------------------------------------*/
        // TOOD: Check restrictions on branches, section 8.3.5.2 in specification.
        /* ------------------------------------------------------------------*/
        checkConnectsInWhen(conn, info);
        eq = NFInstTypes.WHEN_EQUATION(branches, info);
      then
        (eq :: acc_el, NFConnect2.emptyConnections);

    case (NFInstTypes.ASSERT_EQUATION(exp1, exp2, exp3, info), st, _, acc_el, _)
      equation
        (exp1, _, _, _) = typeExp(exp1, EVAL_CONST(), CONTEXT_MODEL(), st, inFunctionTable);
        (exp2, _, _, _) = typeExp(exp2, EVAL_CONST(), CONTEXT_MODEL(), st, inFunctionTable);
        (exp3, _, _, _) = typeExp(exp3, EVAL_CONST(), CONTEXT_MODEL(), st, inFunctionTable);
        eq = NFInstTypes.ASSERT_EQUATION(exp1, exp2, exp3, info);
      then
        (eq :: acc_el, NFConnect2.emptyConnections);

    case (NFInstTypes.TERMINATE_EQUATION(exp1, info), st, _, acc_el, _)
      equation
        (exp1, _, _, _) = typeExp(exp1, EVAL_CONST(), CONTEXT_MODEL(), st, inFunctionTable);
        eq = NFInstTypes.TERMINATE_EQUATION(exp1, info);
      then
        (eq :: acc_el, NFConnect2.emptyConnections);

    case (NFInstTypes.REINIT_EQUATION(cref1, exp1, info), st, _, acc_el, _)
      equation
        (DAE.CREF(componentRef = cref1), _, _, _) = typeCref(cref1, NO_EVAL(), CONTEXT_MODEL(), st, inFunctionTable);
        (exp1, _, _, _) = typeExp(exp1, EVAL_CONST(), CONTEXT_MODEL(), st, inFunctionTable);
        eq = NFInstTypes.REINIT_EQUATION(cref1, exp1, info);
      then
        (eq :: acc_el, NFConnect2.emptyConnections);

    case (NFInstTypes.NORETCALL_EQUATION(DAE.CALL(path = Absyn.QUALIFIED(name = "Connections",
        path = Absyn.IDENT(name = name)), expLst = args), info), st, _, acc_el, _)
      equation
        conn = typeConnectionsEquation(name, args, st, inFunctionTable,info);
      then
        (acc_el, conn);

    case (NFInstTypes.NORETCALL_EQUATION(exp1, info), st, _, acc_el, _)
      equation
        (exp1, _, _, _) = typeExp(exp1, EVAL_CONST(), CONTEXT_MODEL(), st, inFunctionTable);
        eq = NFInstTypes.NORETCALL_EQUATION(exp1, info);
      then
        (eq :: acc_el, NFConnect2.emptyConnections);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"NFTyping.typeEquation got an unknown equation type!"});
      then
        fail();

  end match;
end typeEquation;

protected function checkConnectsInWhen
  input Connections inConnections;
  input SourceInfo inInfo;
algorithm
  _ := matchcontinue(inConnections, inInfo)
    case (_, _)
      equation
        true = NFConnectUtil2.isEmptyConnections(inConnections);
      then
        ();

    else
      equation
        print("Connections are not allowed in when equations\n.");
      then
        fail();

  end matchcontinue;
end checkConnectsInWhen;

protected function typeConnectionsEquation
  "This function types the functions in the builtin Connections package, and
   adds them to the connection graph."
  input String inName;
  input list<DAE.Exp> inArgs;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  input SourceInfo inInfo;
  output Connections outConnections;
algorithm
  outConnections := match(inName, inArgs, inSymbolTable, inFunctionTable, inInfo)
    local
      DAE.ComponentRef cref1, cref2;
      SymbolTable st;
      DAE.Exp prio;

    case ("branch", {DAE.CREF(componentRef = cref1),
        DAE.CREF(componentRef = cref2)}, st, _, _)
      equation
        (DAE.CREF(componentRef = cref1), _, _, _) = typeCref(cref1, NO_EVAL(), CONTEXT_MODEL(), st, inFunctionTable);
        (DAE.CREF(componentRef = cref2), _, _, _) = typeCref(cref2, NO_EVAL(), CONTEXT_MODEL(), st, inFunctionTable);
      then
        NFConnectUtil2.makeBranch(cref1, cref2, inInfo);

    case ("root", {DAE.CREF(componentRef = cref1)}, st, _, _)
      equation
        (DAE.CREF(componentRef = cref1), _, _, _) = typeCref(cref1, NO_EVAL(), CONTEXT_MODEL(), st, inFunctionTable);
      then
        NFConnectUtil2.makeRoot(cref1, inInfo);

    case ("potentialRoot", {DAE.CREF(componentRef = cref1), prio}, st, _, _)
      equation
        (prio, _, _, _) = typeExp(prio, EVAL_CONST_PARAM(), CONTEXT_MODEL(), st, inFunctionTable);
      then
        NFConnectUtil2.makePotentialRoot(cref1, prio, inInfo);

    // Modelica allows you to omit crefs from the lhs, so isRoot may be called
    // as a non-returning call. It won't do anything though. Perhaps we should
    // tell the user that this is stupid?
    case ("isRoot", _, _, _, _)
      then NFConnect2.emptyConnections;

  end match;
end typeConnectionsEquation;

protected function typeConnection
  input DAE.ComponentRef inLhs;
  input DAE.ComponentRef inRhs;
  input Prefix inPrefix;
  input SymbolTable inSymbolTable;
  input SourceInfo inInfo;
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
      Boolean lhs_id, rhs_id, is_deleted;
      Option<Component> lhs_comp, rhs_comp;
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

        lhs_conn = NFConnectUtil2.makeConnector(lhs, lhs_face, lhs_comp);
        rhs_conn = NFConnectUtil2.makeConnector(rhs, rhs_face, rhs_comp);

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
  input SourceInfo inInfo;
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
        NFConnectCheck.compatibleConnectors(inLhsConnector, inRhsConnector, inInfo);
        (eql, is_only_const) = NFConnectEquations.generateAssertion(
          inLhsConnector, inRhsConnector, inInfo, inEquations);
        conn = NFConnectUtil2.addConnectionCond(not is_only_const, inLhsConnector,
          inRhsConnector, inInfo, inConnections);
      then
        (eql, conn);

  end match;
end typeConnection2;

protected function typeConnectorCref
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input SymbolTable inSymbolTable;
  input SourceInfo inInfo;
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
        (cref, face, is_deleted) = typeConnectorCref2(cref, inCref, comp, pre_comp, inInfo);
      then
        (cref, face, comp, is_deleted);

  end match;
end typeConnectorCref;

protected function typeConnectorCref2
  input DAE.ComponentRef inCref;
  input DAE.ComponentRef inUnprefixedCref;
  input Option<Component> inComponent;
  input Option<Component> inPrefixComponent;
  input SourceInfo inInfo;
  output DAE.ComponentRef outCref;
  output Face outFace;
  output Boolean outIsDeleted;
algorithm
  (outCref, outFace, outIsDeleted) :=
  match(inCref, inUnprefixedCref, inComponent, inPrefixComponent, inInfo)
    local
      Face face;
      Component comp;
      DAE.ComponentRef cref, last_cref;

    // A connector that is part of a deleted conditional component.
    case (_, _, NONE(), NONE(), _)
      then (inCref, NFConnect2.NO_FACE(), true);

    // A connector which is itself deleted.
    case (_, _, SOME(NFInstTypes.DELETED_COMPONENT(_)), _, _)
      then (inCref, NFConnect2.NO_FACE(), true);

    // A component that should be added to an expandable connector. It can only
    // be outside, since only connectors on the form m.c are inside.
    case (_, _, NONE(), SOME(comp), _)
      equation
        /* ------------------------------------------------------------------*/
        // TODO: This can be made more efficient by just typing everything but
        // the last cref, without splitting and joining.
        /* ------------------------------------------------------------------*/
        (cref, last_cref) = ComponentReference.splitCrefLast(inCref);
        cref = NFInstUtil.typeCrefWithComponent(cref, comp);
        cref = ComponentReference.joinCrefs(cref, last_cref);
      then
        (cref, NFConnect2.OUTSIDE(), false);

    // A normal connector.
    case (cref, _, SOME(comp), _, _)
      equation
        /* ------------------------------------------------------------------*/
        // TODO: Resolve outer references here?
        /* ------------------------------------------------------------------*/
        NFConnectCheck.checkComponentIsConnector(comp, inPrefixComponent, inCref, inInfo);
        face = NFConnectUtil2.getConnectorFace(inUnprefixedCref, comp);
        cref = NFInstUtil.typeCrefWithComponent(cref, comp);
      then
        (cref, face, false);

  end match;
end typeConnectorCref2;

protected function lookupConnectorCref
  input DAE.ComponentRef inCref;
  input Prefix inPrefix;
  input SymbolTable inSymbolTable;
  input SourceInfo inInfo;
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
        cref = NFInstPrefix.prefixCref(inCref, inPrefix);
        (comp, pre_comp) = lookupConnectorCref2(cref, inSymbolTable);
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
  input SymbolTable inSymbolTable;
  output Option<Component> outComponent;
  output Option<Component> outPrefixComponent;
algorithm
  (outComponent, outPrefixComponent) := matchcontinue(inCref, inSymbolTable)
    local
      Component comp;
      DAE.ComponentRef cref;
      Option<Component> opt_comp, opt_pre_comp;

    case (_, _)
      equation
        comp = NFInstSymbolTable.lookupCref(inCref, inSymbolTable);
      then
        (SOME(comp), NONE());

    // If the cref is qualified but we couldn't find it, it might be part of a
    // deleted conditional component (i.e. it hasn't been instantiated). It
    // might also be part of an expandable connector. In that case, strip the
    // last identifier and look again to see if we can find a deleted component
    // that is a prefix of the given cref.
    case (DAE.CREF_QUAL(), _)
      equation
        cref = ComponentReference.crefStripLastIdent(inCref);
        (opt_comp, opt_pre_comp) = lookupConnectorCref2(cref, inSymbolTable);
        (opt_comp, opt_pre_comp) = lookupConnectorCref3(opt_comp, opt_pre_comp);
      then
        (opt_comp, opt_pre_comp);

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
    case (SOME(NFInstTypes.DELETED_COMPONENT()), _)
      then (NONE(), NONE());

    // A component that should be added to an expandable connector. The
    // component we get is the expandable connector itself, so we return it as
    // the prefix component here, and return nothing as the component.
    case (SOME(NFInstTypes.TYPED_COMPONENT(ty = ty)), _)
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
  input SourceInfo inInfo;
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
  input FunctionHashTable inFunctionTable;
  output list<tuple<DAE.Exp, list<Equation>>> outBranches;
  output Connections outConnections;
algorithm
  (outBranches, outConnections) := List.map2Fold(inBranches, typeBranch,
    inSymbolTable, inFunctionTable, NFConnect2.emptyConnections);
end typeBranches;

protected function typeBranch
  input tuple<DAE.Exp, list<Equation>> inBranch;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  input Connections inConnections;
  output tuple<DAE.Exp, list<Equation>> outBranch;
  output Connections outConnections;
algorithm
  (outBranch, outConnections) := match(inBranch, inSymbolTable, inFunctionTable, inConnections)
    local
      DAE.Exp cond_exp;
      list<Equation> branch_body;
      Connections conn;

    case ((cond_exp, branch_body), _, _, conn)
      equation
        (cond_exp, _, _, _) = typeExp(cond_exp, EVAL_CONST(), CONTEXT_MODEL(), inSymbolTable, inFunctionTable);
        (branch_body, conn) = typeEquations(branch_body, inSymbolTable, inFunctionTable, conn);
      then
        ((cond_exp, branch_body), conn);

  end match;
end typeBranch;

protected function typeAlgorithms
  input list<list<Statement>> inStmts;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output list<list<Statement>> outStmts;
algorithm
  outStmts := List.map3(inStmts,typeStatements,CONTEXT_MODEL(),inSymbolTable, inFunctionTable);
end typeAlgorithms;

protected function typeStatements
  input list<Statement> inStmts;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output list<Statement> outStmts;
algorithm
  outStmts := listReverse(List.fold3(inStmts, typeStatement, inContext, inSymbolTable, inFunctionTable, {}));
end typeStatements;

protected function typeStatement
  input Statement inStmt;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  input list<Statement> inAcc;
  output list<Statement> outAcc;
algorithm
  outAcc := match (inStmt,inContext,inSymbolTable,inFunctionTable,inAcc)
    local
      DAE.Exp lhs,rhs,exp;
      SourceInfo info;
      DAE.Type lty,rty,ty;
      SymbolTable st;
      FunctionHashTable ft;
      list<tuple<DAE.Exp,list<Statement>>> branches;
      String name;
      Context c;

    case (NFInstTypes.ASSIGN_STMT(lhs=lhs,rhs=rhs,info=info),c,st,ft,_)
      equation
        (lhs,lty,_,_) = typeExp(lhs, NO_EVAL(), c, st, ft);
        (rhs,rty,_,_) = typeExp(rhs, EVAL_CONST(), c, st, ft);
        (lhs, _, rhs, _) = NFTypeCheck.checkExpEquality(lhs, lty, rhs, rty, "alg", info);
      then typeAssignment(lhs,rhs,info,inAcc);
    case (NFInstTypes.FUNCTION_ARRAY_INIT(name=name,ty=ty,info=info),_,st,_,_)
      equation
        NFInstTypes.TYPED_COMPONENT(ty=ty) = NFInstSymbolTable.lookupCref(DAE.CREF_IDENT(name,ty,{}),st);
      then NFInstTypes.FUNCTION_ARRAY_INIT(name,ty,info) :: inAcc;
    case (NFInstTypes.NORETCALL_STMT(exp=exp, info=info),c,st,ft,_)
      equation
        // Let's try skipping evaluation. Maybe helps some external functions
        (exp,_,_,_) = typeExp(exp, NO_EVAL(), c, st, ft);
        /* ------------------------------------------------------------------*/
        // TODO: Check variability/etc to potentially reduce the statement?
        /* ------------------------------------------------------------------*/
      then NFInstTypes.NORETCALL_STMT(exp,info)::inAcc;
    case (NFInstTypes.IF_STMT(branches=branches, info=info),c,st,ft,_)
      equation
        branches = List.map3(branches, typeBranchStatement, c, st, ft);
      then
        NFInstTypes.IF_STMT(branches, info) :: inAcc;
    case (NFInstTypes.FOR_STMT(),_,_,_,_)
      then
        inStmt :: inAcc;
    else
      equation
        print("Unknown statement in NFTyping.typeStatement\n");
      then fail();
  end match;
end typeStatement;

protected function typeAssignment
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input SourceInfo info;
  input list<Statement> inAcc;
  output list<Statement> outAcc;
algorithm
  outAcc := matchcontinue (lhs,rhs,info,inAcc)
    local
      list<DAE.Exp> el;
    case (DAE.TUPLE(PR=el),_,_,_)
      equation
        false = List.exist(el,Expression.isNotWild);
      then NFInstTypes.NORETCALL_STMT(rhs,info)::inAcc;
    case (DAE.TUPLE(PR=el),_,_,_)
      equation
        false = List.exist(el,Expression.isNotCref);
      then NFInstTypes.ASSIGN_STMT(lhs,rhs,info)::inAcc;
    case (DAE.CREF(),_,_,_)
      then NFInstTypes.ASSIGN_STMT(lhs,rhs,info)::inAcc;
  end matchcontinue;
end typeAssignment;

protected function typeBranchStatement
  input tuple<DAE.Exp, list<Statement>> inBranch;
  input Context inContext;
  input SymbolTable inSymbolTable;
  input FunctionHashTable inFunctionTable;
  output tuple<DAE.Exp, list<Statement>> outBranch;
algorithm
  outBranch := match(inBranch, inContext, inSymbolTable, inFunctionTable)
    local
      DAE.Exp cond_exp;
      list<Statement> branch_body;
      Context c;

    case ((cond_exp, branch_body), c, _, _)
      equation
        (cond_exp, _, _, _) = typeExp(cond_exp, EVAL_CONST(), c, inSymbolTable, inFunctionTable);
        /* ------------------------------------------------------------------*/
        // TODO: Type-check the condition
        /* ------------------------------------------------------------------*/
        branch_body = typeStatements(branch_body, c, inSymbolTable, inFunctionTable);
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
        Debug.traceln("- NFTyping.lookupFunction could not find the function " + func_str);
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
      list<NFInstTypes.Element> inputs,outputs,locals;
      list<NFInstTypes.Statement> al;
      HashTablePathToFunction.HashTable ht;
      SymbolTable st;
      DAE.Type recType;

    case (NFInstTypes.FUNCTION(inputs = inputs, outputs = outputs, locals = locals,
        algorithms = al), _, ht, st)
      equation
        st = NFInstSymbolTable.addFunctionScope(st);
        st = NFInstSymbolTable.addElements(inputs, st);
        st = NFInstSymbolTable.addElements(outputs, st);
        st = NFInstSymbolTable.addElements(locals, st);
        (inputs, st) = List.map3Fold(inputs, typeElement, NONE(), CONTEXT_FUNCTION(), inFunctionTable, st);
        (outputs, st) = List.map3Fold(outputs, typeElement, NONE(), CONTEXT_FUNCTION(), inFunctionTable, st);
        (locals, st) = List.map3Fold(locals, typeElement, NONE(), CONTEXT_FUNCTION(), inFunctionTable, st);
        al = typeStatements(al, CONTEXT_FUNCTION(), st, inFunctionTable);
        ht = BaseHashTable.add((inPath, NFInstTypes.FUNCTION(inPath, inputs, outputs, locals, al)), ht);
        _::st = st;
      then
        ((ht, st));

    case (NFInstTypes.RECORD_CONSTRUCTOR(recType = recType, inputs = inputs, locals = locals, algorithms = al), _, ht, st)
      equation
        st = NFInstSymbolTable.addFunctionScope(st);
        st = NFInstSymbolTable.addElements(inputs, st);
        st = NFInstSymbolTable.addElements(locals, st);
        (inputs, st) = List.map3Fold(inputs, typeElement, NONE(), CONTEXT_FUNCTION(), inFunctionTable, st);
        (locals, st) = List.map3Fold(locals, typeElement, NONE(), CONTEXT_FUNCTION(), inFunctionTable, st);
        al = typeStatements(al, CONTEXT_FUNCTION(), st, inFunctionTable);
        ht = BaseHashTable.add((inPath, NFInstTypes.RECORD_CONSTRUCTOR(inPath, recType, inputs, locals, al)), ht);
        _::st = st;
      then
        ((ht, st));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- NFTyping.typeFunction2 failed on function " +
          Absyn.pathString(inPath));
      then
        fail();

  end matchcontinue;
end typeFunction2;

annotation(__OpenModelica_Interface="frontend");
end NFTyping;
