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

encapsulated package NFTypeCheck
" file:        NFTypeCheck.mo
  package:     NFTypeCheck
  description: SCodeInst type checking.


  Functions used by SCodeInst for type checking and type conversion where needed.
"

import DAE;
import Dimension = NFDimension;
import Expression = NFExpression;
import NFInstNode.InstNode;
import NFBinding.Binding;
import NFPrefixes.Variability;

protected
import Debug;
import DAEExpression = Expression;
import Error;
import ExpressionDump;
import List;
import Types;
import Operator = NFOperator;
import Type = NFType;
import Class = NFClass.Class;
import ClassTree = NFClassTree;
import InstUtil = NFInstUtil;
import DAEUtil;
import Prefixes = NFPrefixes;
import Restriction = NFRestriction;
import ComplexType = NFComplexType;
import NFOperator.Op;
import NFTyping.ExpOrigin;
import NFFunction.Function;
import NFFunction.TypedArg;
import NFFunction.FunctionMatchKind;
import NFFunction.MatchedFunction;
import NFCall.Call;
import BuiltinCall = NFBuiltinCall;
import NFCall.CallAttributes;
import ComponentRef = NFComponentRef;
import ErrorExt;
import NFBuiltin;
import SimplifyExp = NFSimplifyExp;
import MetaModelica.Dangerous.*;
import OperatorOverloading = NFOperatorOverloading;
import ExpandExp = NFExpandExp;
import NFFunction.Slot;
import Util;
import System;

public
type MatchKind = enumeration(
  EXACT "Exact match",
  CAST  "Matched by casting, e.g. Integer to real",
  UNKNOWN_EXPECTED "The expected type was unknown",
  UNKNOWN_ACTUAL   "The actual type was unknown",
  GENERIC "Matched with a generic type e.g. function F<T> input T i; end F; F(1)",
  PLUG_COMPATIBLE "Component by component matching, e.g. class A R r; end A; is plug compatible with class B R r; end B;",
  NOT_COMPATIBLE
);

function isCompatibleMatch
  input MatchKind kind;
  output Boolean isCompatible = kind <> MatchKind.NOT_COMPATIBLE;
end isCompatibleMatch;

function isIncompatibleMatch
  input MatchKind kind;
  output Boolean isIncompatible = kind == MatchKind.NOT_COMPATIBLE;
end isIncompatibleMatch;

function isExactMatch
  input MatchKind kind;
  output Boolean isCompatible = kind == MatchKind.EXACT;
end isExactMatch;

function isCastMatch
  input MatchKind kind;
  output Boolean isCast = kind == MatchKind.CAST;
end isCastMatch;

function isGenericMatch
  input MatchKind kind;
  output Boolean isCast = kind == MatchKind.GENERIC;
end isGenericMatch;

function isValidAssignmentMatch
  input MatchKind kind;
  output Boolean v = kind == MatchKind.EXACT
                     or kind == MatchKind.CAST
                     or kind == MatchKind.PLUG_COMPATIBLE;
end isValidAssignmentMatch;

function isValidArgumentMatch
  input MatchKind kind;
  output Boolean v = kind == MatchKind.EXACT
                     or kind == MatchKind.CAST
                     or kind == MatchKind.GENERIC
                     or kind == MatchKind.PLUG_COMPATIBLE;
end isValidArgumentMatch;

function isValidPlugCompatibleMatch
  input MatchKind kind;
  output Boolean v = kind == MatchKind.EXACT
                     or kind == MatchKind.PLUG_COMPATIBLE
                     ;
end isValidPlugCompatibleMatch;


function checkBinaryOperation
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator operator;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
algorithm
  if Type.isComplex(Type.arrayElementType(type1)) or
     Type.isComplex(Type.arrayElementType(type2)) then
    (binaryExp,resultType) := checkOverloadedBinaryOperator(exp1, type1, var1, operator, exp2, type2, var2, info);
  else
    (binaryExp, resultType) := match operator.op
      case Op.ADD then checkBinaryOperationAdd(exp1, type1, exp2, type2, info);
      case Op.SUB then checkBinaryOperationSub(exp1, type1, exp2, type2, info);
      case Op.MUL then checkBinaryOperationMul(exp1, type1, exp2, type2, info);
      case Op.DIV then checkBinaryOperationDiv(exp1, type1, exp2, type2, info, isElementWise = false);
      case Op.POW then checkBinaryOperationPow(exp1, type1, exp2, type2, info);
      case Op.ADD_EW then checkBinaryOperationEW(exp1, type1, exp2, type2, Op.ADD, info);
      case Op.SUB_EW then checkBinaryOperationEW(exp1, type1, exp2, type2, Op.SUB, info);
      case Op.MUL_EW then checkBinaryOperationEW(exp1, type1, exp2, type2, Op.MUL, info);
      case Op.DIV_EW then checkBinaryOperationDiv(exp1, type1, exp2, type2, info, isElementWise = true);
      case Op.POW_EW then checkBinaryOperationPowEW(exp1, type1, exp2, type2, info);
    end match;
  end if;
end checkBinaryOperation;

public function checkOverloadedBinaryOperator
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
protected
  String op_str;
  list<Function> candidates;
  Type ety1, ety2;
algorithm
  op_str := Operator.symbol(Operator.stripEW(op), "'");
  ety1 := Type.arrayElementType(type1);
  ety2 := Type.arrayElementType(type2);

  candidates := OperatorOverloading.lookupOperatorFunctionsInType(op_str, ety1);

  // Only collect operators from both types if they're not the same type.
  if not Type.isEqual(ety1, ety2) then
    candidates := listAppend(OperatorOverloading.lookupOperatorFunctionsInType(op_str, ety2), candidates);
  end if;

  // Give up if no operator functions could be found.
  if listEmpty(candidates) then
    printUnresolvableTypeError(Expression.BINARY(exp1, op, exp2), {type1, type2}, info);
  end if;

  if Operator.isElementWise(op) then
    (outExp, outType) := checkOverloadedBinaryArrayEW(
      exp1, type1, var1, Operator.stripEW(op), exp2, type2, var2, candidates, info);
  else
    (outExp, outType) := matchOverloadedBinaryOperator(
      exp1, type1, var1, op, exp2, type2, var2, candidates, info);
  end if;
end checkOverloadedBinaryOperator;

function matchOverloadedBinaryOperator
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input list<Function> candidates;
  input SourceInfo info;
  input Boolean showErrors = true;
  output Expression outExp;
  output Type outType;
protected
  list<TypedArg> args;
  FunctionMatchKind matchKind;
  MatchedFunction matchedFunc;
  list<MatchedFunction> matchedFunctions, exactMatches;
  Function fn;
  Operator.Op oop;
algorithm
  args := {(exp1, type1, var1), (exp2, type2, var2)};
  matchedFunctions := Function.matchFunctionsSilent(candidates, args, {}, info);
  // We only allow exact matches for operator overloading. e.g. no casting or generic matches.
  exactMatches := MatchedFunction.getExactMatches(matchedFunctions);

  if listEmpty(exactMatches) then
    // TODO: new error mentioning overloaded operators.
    ErrorExt.setCheckpoint("NFTypeCheck:implicitConstruction");
    try
      (outExp, outType) := implicitConstructAndMatch(candidates, exp1, type1, op, exp2, type2, info);

      if showErrors then
        ErrorExt.delCheckpoint("NFTypeCheck:implicitConstruction");
      else
        ErrorExt.rollBack("NFTypeCheck:implicitConstruction");
      end if;
    else
      ErrorExt.rollBack("NFTypeCheck:implicitConstruction");

      if Type.isArray(type1) or Type.isArray(type2) then
        (outExp, outType) := match op.op
          case Op.ADD then checkOverloadedBinaryArrayAddSub(exp1, type1, var1, op, exp2, type2, var2, candidates, info);
          case Op.SUB then checkOverloadedBinaryArrayAddSub(exp1, type1, var1, op, exp2, type2, var2, candidates, info);
          case Op.MUL then checkOverloadedBinaryArrayMul(exp1, type1, var1, op, exp2, type2, var2, candidates, info);
          case Op.DIV then checkOverloadedBinaryArrayDiv(exp1, type1, var1, op, exp2, type2, var2, candidates, info);
          else
            algorithm
              printUnresolvableTypeError(Expression.BINARY(exp1, op, exp2), {type1, type2}, info, showErrors);
            then
              fail();
        end match;
      else
        printUnresolvableTypeError(Expression.BINARY(exp1, op, exp2), {type1, type2}, info, showErrors);
      end if;
    end try;
  elseif listLength(exactMatches) == 1 then
    matchedFunc ::_ := exactMatches;
    fn := matchedFunc.func;
    outType := Function.returnType(fn);
    outExp := Expression.CALL(
      Call.makeTypedCall(
        matchedFunc.func,
        list(Util.tuple31(a) for a in matchedFunc.args),
        Prefixes.variabilityMax(var1, var2),
        outType));
  else
    if showErrors then
      Error.addSourceMessage(Error.AMBIGUOUS_MATCHING_OPERATOR_FUNCTIONS_NFINST,
        {Expression.toString(Expression.BINARY(exp1, op, exp2)),
         Function.candidateFuncListString(list(mfn.func for mfn in matchedFunctions))}, info);
    end if;
    fail();
  end if;
end matchOverloadedBinaryOperator;

function checkOverloadedBinaryArrayAddSub
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input list<Function> candidates;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
protected
  Expression e1, e2;
  MatchKind mk;
algorithm
  // For addition or subtraction both sides must have the same type.
  (e1, e2, _, mk) := matchExpressions(exp1, type1, exp2, type2, true);

  if not isCompatibleMatch(mk) then
    printUnresolvableTypeError(Expression.BINARY(e1, op, e2), {type1, type2}, info);
  end if;

  e1 := ExpandExp.expand(e1);
  e2 := ExpandExp.expand(e2);

  (outExp, outType) :=
    checkOverloadedBinaryArrayAddSub2(e1, type1, var1, op, e2, type2, var2, candidates, info);
end checkOverloadedBinaryArrayAddSub;

function checkOverloadedBinaryArrayAddSub2
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input list<Function> candidates;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
algorithm
  (outExp, outType) := match (exp1, exp2)
    local
      Type ty, ty1, ty2;
      Expression e, e2;
      list<Expression> expl, expl1, expl2;

    case (Expression.ARRAY(elements = expl1), Expression.ARRAY(elements = expl2))
      algorithm
        expl := {};

        if listEmpty(expl1) then
          // If the arrays are empty, match against the element types to get the expected return type.
          ty1 := Type.arrayElementType(type1);
          ty2 := Type.arrayElementType(type2);

          try
            (_, ty) := matchOverloadedBinaryOperator(
              Expression.EMPTY(ty1), ty1, var1, op, Expression.EMPTY(ty2), ty2, var2, candidates, info, showErrors = false);
          else
            printUnresolvableTypeError(Expression.BINARY(exp1, op, exp2), {type1, type2}, info);
          end try;
        else
          ty1 := Type.unliftArray(type1);
          ty2 := Type.unliftArray(type2);

          for e1 in expl1 loop
            e2 :: expl2 := expl2;
            (e, ty) := checkOverloadedBinaryArrayAddSub2(e1, ty1, var1, op, e2, ty2, var2, candidates, info);
            expl := e :: expl;
          end for;

          expl := listReverseInPlace(expl);
        end if;

        outType := Type.setArrayElementType(type1, ty);
        outExp := Expression.makeArray(outType, expl);
      then
        (outExp, outType);

    else matchOverloadedBinaryOperator(exp1, type1, var1, op, exp2, type2, var2, candidates, info);
  end match;
end checkOverloadedBinaryArrayAddSub2;

function checkOverloadedBinaryArrayMul
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input list<Function> candidates;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
protected
  Boolean valid;
  list<Dimension> dims1, dims2;
  Dimension dim11, dim12, dim21, dim22;
algorithm
  dims1 := Type.arrayDims(type1);
  dims2 := Type.arrayDims(type2);

  (valid, outExp) := match (dims1, dims2)
    // scalar * array = array
    case ({}, {_})
      algorithm
        outExp := checkOverloadedBinaryScalarArray(exp1, type1, var1, op, exp2, type2, var2, candidates, info);
      then
        (true, outExp);
    // array * scalar = array
    case ({_}, {})
      algorithm
        outExp := checkOverloadedBinaryArrayScalar(exp1, type1, var1, op, exp2, type2, var2, candidates, info);
      then
        (true, outExp);
    // matrix[n, m] * vector[m] = vector[n]
    case ({dim11, dim12}, {dim21})
      algorithm
        valid := Dimension.isEqual(dim12, dim21);
        // TODO: Implement me!
        outExp := Expression.BINARY(exp1, op, exp2);
        valid := false;
      then
        (valid, outExp);
    // matrix[n, m] * matrix[m, p] = vector[n, p]
    case ({dim11, dim12}, {dim21, dim22})
      algorithm
        valid := Dimension.isEqual(dim12, dim21);
        // TODO: Implement me!
        outExp := Expression.BINARY(exp1, op, exp2);
        valid := false;
      then
        (valid, outExp);
    // scalar * scalar should never get here.
    // vector * vector and vector * matrix are undefined for overloaded operators.
    else (false, Expression.BINARY(exp1, op, exp2));
  end match;

  if not valid then
    printUnresolvableTypeError(outExp, {type1, type2}, info);
  end if;

  outType := Expression.typeOf(outExp);
end checkOverloadedBinaryArrayMul;

function checkOverloadedBinaryScalarArray
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input list<Function> candidates;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
algorithm
  (outExp, outType) := checkOverloadedBinaryScalarArray2(
    exp1, type1, var1, op, ExpandExp.expand(exp2), type2, var2, candidates, info);
end checkOverloadedBinaryScalarArray;

function checkOverloadedBinaryScalarArray2
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input list<Function> candidates;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
protected
  list<Expression> expl;
  Type ty;
algorithm
  (outExp, outType) := match exp2
    case Expression.ARRAY(elements = {})
      algorithm
        try
          ty := Type.unliftArray(type2);
          (_, outType) := matchOverloadedBinaryOperator(
            exp1, type1, var1, op, Expression.EMPTY(type2), ty, var2, candidates, info, showErrors = false);
        else
          printUnresolvableTypeError(Expression.BINARY(exp1, op, exp2), {type1, exp2.ty}, info);
        end try;

        outType := Type.setArrayElementType(exp2.ty, outType);
      then
        (Expression.makeArray(outType, {}), outType);

    case Expression.ARRAY(elements = expl)
      algorithm
        ty := Type.unliftArray(type2);
        expl := list(checkOverloadedBinaryScalarArray2(exp1, type1, var1, op, e, ty, var2, candidates, info) for e in expl);
        outType := Type.setArrayElementType(exp2.ty, Expression.typeOf(listHead(expl)));
      then
        (Expression.makeArray(outType, expl), outType);

    else matchOverloadedBinaryOperator(exp1, type1, var1, op, exp2, type2, var2, candidates, info);
  end match;
end checkOverloadedBinaryScalarArray2;

function checkOverloadedBinaryArrayScalar
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input list<Function> candidates;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
algorithm
  (outExp, outType) := checkOverloadedBinaryArrayScalar2(
    ExpandExp.expand(exp1), type1, var1, op, exp2, type2, var2, candidates, info);
end checkOverloadedBinaryArrayScalar;

function checkOverloadedBinaryArrayScalar2
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input list<Function> candidates;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
protected
  Expression e1;
  list<Expression> expl;
  Type ty;
algorithm
  (outExp, outType) := match exp1
    case Expression.ARRAY(elements = {})
      algorithm
        try
          ty := Type.unliftArray(type1);
          (_, outType) := matchOverloadedBinaryOperator(
            Expression.EMPTY(type1), ty, var1, op, exp2, type2, var2, candidates, info, showErrors = false);
        else
          printUnresolvableTypeError(Expression.BINARY(exp1, op, exp2), {type1, exp1.ty}, info);
        end try;

        outType := Type.setArrayElementType(exp1.ty, outType);
      then
        (Expression.makeArray(outType, {}), outType);

    case Expression.ARRAY(elements = expl)
      algorithm
        ty := Type.unliftArray(type1);
        expl := list(checkOverloadedBinaryArrayScalar2(e, ty, var1, op, exp2, type2, var2, candidates, info) for e in expl);
        outType := Type.setArrayElementType(exp1.ty, Expression.typeOf(listHead(expl)));
      then
        (Expression.makeArray(outType, expl), outType);

    else matchOverloadedBinaryOperator(exp1, type1, var1, op, exp2, type2, var2, candidates, info);
  end match;
end checkOverloadedBinaryArrayScalar2;

function checkOverloadedBinaryArrayDiv
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input list<Function> candidates;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
algorithm
  if Type.isArray(type1) and Type.isScalar(type2) then
    (outExp, outType) := checkOverloadedBinaryArrayScalar(exp1, type1, var1, op, exp2, type2, var2, candidates, info);
  else
    printUnresolvableTypeError(Expression.BINARY(exp1, op, exp2), {type1, type2}, info);
  end if;
end checkOverloadedBinaryArrayDiv;

function checkOverloadedBinaryArrayEW
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input list<Function> candidates;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
protected
  Expression e1, e2;
  MatchKind mk;
  list<Expression> expl1, expl2;
  Type ty;
algorithm
  if Type.isArray(type1) and Type.isArray(type2) then
    (e1, e2, _, mk) := matchExpressions(exp1, type1, exp2, type2, true);
  else
    (e1, e2, _, mk) := matchExpressions(exp1, Type.arrayElementType(type1),
                                        exp2, Type.arrayElementType(type2), true);
  end if;

  if not isCompatibleMatch(mk) then
    printUnresolvableTypeError(Expression.BINARY(e1, op, e2), {type1, type2}, info);
  end if;

  e1 := ExpandExp.expand(exp1);
  e2 := ExpandExp.expand(exp2);

  (outExp, outType) := checkOverloadedBinaryArrayEW2(
    e1, type1, var1, op, e2, type2, var2, candidates, info);
end checkOverloadedBinaryArrayEW;

function checkOverloadedBinaryArrayEW2
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator op;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input list<Function> candidates;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
protected
  Expression e2;
  list<Expression> expl, expl1, expl2;
  Type ty, ty1, ty2;
  Boolean is_array1, is_array2;
algorithm
  is_array1 := Type.isArray(type1);
  is_array2 := Type.isArray(type2);

  if is_array1 or is_array2 then
    expl := {};

    if Expression.isEmptyArray(exp1) or Expression.isEmptyArray(exp2) then
      ty1 := Type.arrayElementType(type1);
      ty2 := Type.arrayElementType(type2);

      try
        (_, ty) := matchOverloadedBinaryOperator(
          Expression.EMPTY(ty1), ty1, var1, op,
          Expression.EMPTY(ty2), ty2, var2, candidates, info);
      else
        printUnresolvableTypeError(Expression.BINARY(exp1, op, exp2), {type1, type2}, info);
      end try;
    elseif is_array1 and is_array2 then
      ty1 := Type.unliftArray(type1);
      ty2 := Type.unliftArray(type2);
      expl1 := Expression.arrayElements(exp1);
      expl2 := Expression.arrayElements(exp2);

      for e in expl1 loop
        e2 :: expl2 := expl2;
        (e, ty) := checkOverloadedBinaryArrayEW2(e, ty1, var1, op, e2, ty2, var2, candidates, info);
        expl := e :: expl;
      end for;
    elseif is_array1 then
      ty1 := Type.unliftArray(type1);
      expl1 := Expression.arrayElements(exp1);

      for e in expl1 loop
        (e, ty) := checkOverloadedBinaryArrayEW2(e, ty1, var1, op, exp2, type2, var2, candidates, info);
        expl := e :: expl;
      end for;
    elseif is_array2 then
      ty2 := Type.unliftArray(type2);
      expl2 := Expression.arrayElements(exp2);

      for e in expl2 loop
        (e, ty) := checkOverloadedBinaryArrayEW2(exp1, type1, var1, op, e, ty2, var2, candidates, info);
        expl := e :: expl;
      end for;
    end if;

    outType := Type.setArrayElementType(type1, ty);
    outExp := Expression.makeArray(outType, listReverseInPlace(expl));
  else
    (outExp, outType) := matchOverloadedBinaryOperator(
      exp1, type1, var1, op,
      exp2, type2, var2, candidates, info);
  end if;
end checkOverloadedBinaryArrayEW2;

function implicitConstructAndMatch
  input list<Function> candidates;
  input Expression inExp1;
  input Type inType1;
  input Operator op;
  input Expression inExp2;
  input Type inType2;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
protected
  list<InstNode> inputs;
  InstNode in1, in2, scope;
  MatchKind mk1,mk2;
  ComponentRef fn_ref;
  Function operfn;
  list<tuple<Function, list<Expression>, Variability>> matchedfuncs = {};
  Expression exp1,exp2;
  Type ty, arg1_ty, arg2_ty;
  Variability var;
  Boolean matched;
  SourceInfo arg1_info, arg2_info;
algorithm
  exp1 := inExp1; exp2 := inExp2;
  for fn in candidates loop
    if listLength(fn.inputs) <> 2 then
      continue;
    end if;

    in1 :: in2 :: _ := fn.inputs;
    arg1_ty := InstNode.getType(in1);
    arg2_ty := InstNode.getType(in2);
    arg1_info := InstNode.info(in1);
    arg2_info := InstNode.info(in2);

    // Try to implicitly construct a matching record from the first argument.
    (matchedfuncs, matched) :=
      implicitConstructAndMatch2(inExp1, inType1, inExp2, arg1_ty,
          arg1_info, arg2_ty, arg2_info, InstNode.classScope(in2), fn, false, matchedfuncs);

    if matched then
      continue;
    end if;

    // Try to implicitly construct a matching record from the second argument.
    (matchedfuncs, matched) :=
      implicitConstructAndMatch2(inExp2, inType2, inExp1, arg2_ty,
          arg2_info, arg1_ty, arg1_info, InstNode.classScope(in1), fn, true, matchedfuncs);
  end for;

  if listLength(matchedfuncs) == 1 then
    (operfn, {exp1,exp2}, var)::_ := matchedfuncs;
    outType := Function.returnType(operfn);
    outExp := Expression.CALL(Call.makeTypedCall(operfn, {exp1, exp2}, var, outType));
  else
    Error.addSourceMessage(Error.AMBIGUOUS_MATCHING_OPERATOR_FUNCTIONS_NFINST,
      {Expression.toString(Expression.BINARY(exp1, op, exp2)),
       Function.candidateFuncListString(list(Util.tuple31(fn) for fn in matchedfuncs))}, info);
    fail();
  end if;
end implicitConstructAndMatch;

function implicitConstructAndMatch2
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type paramType1;
  input SourceInfo paramInfo1;
  input Type paramType2;
  input SourceInfo paramInfo2;
  input InstNode scope;
  input Function fn;
  input Boolean reverseArgs;
  input output list<tuple<Function, list<Expression>, Variability>> matchedFns;
        output Boolean matched;
protected
  ComponentRef fn_ref;
  Expression e1, e2;
  MatchKind mk;
  Variability var;
  Type ty;
algorithm
  (e1, _, mk) := matchTypes(paramType1, type1, exp1, false);

  // We only want overloaded constructors when trying to implicitly construct.
  // Default constructors are not considered.
  if mk == MatchKind.EXACT then
    fn_ref := Function.instFunction(Absyn.CREF_IDENT("'constructor'", {}), scope, paramInfo2);
    e2 := Expression.CALL(NFCall.UNTYPED_CALL(fn_ref, {exp2}, {}, scope));
    (e2, ty, var) := Call.typeCall(e2, 0, paramInfo1);
    (_, _, mk) := matchTypes(paramType2, ty, e2, false);

    if mk == MatchKind.EXACT then
      matchedFns := (fn, if reverseArgs then {e2, e1} else {e1, e2}, var) :: matchedFns;
      matched := true;
    else
      matched := false;
    end if;
  else
    matched := false;
  end if;
end implicitConstructAndMatch2;

//function checkValidBinaryOperatorOverload
//  input String oper_name;
//  input Function oper_func;
//  input InstNode rec_node;
//protected
//  SourceInfo info;
//algorithm
//  info := InstNode.info(oper_func.node);
//  checkOneOutput(oper_name, oper_func.outputs, rec_node, info);
//  checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, info);
//  checkTwoInputs(oper_name, oper_func.inputs, rec_node, info);
//end checkValidBinaryOperatorOverload;

//function checkValidOperatorOverload
//  input String oper_name;
//  input Function oper_func;
//  input InstNode rec_node;
//protected
//  Type ty1, ty2;
//  InstNode out_class;
//algorithm
//  () := match oper_name
//    case "'constructor'" algorithm
//      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
//      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
//    then ();
//    case "'0'" algorithm
//      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
//      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
//    then ();
//    case "'+'" algorithm
//      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
//      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
//    then ();
//    case "'-'" algorithm
//      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
//      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
//    then ();
//    case "'*'" algorithm
//      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
//      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
//    then ();
//    case "'/'" algorithm
//      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
//      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
//    then ();
//    case "'^'" algorithm
//      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
//      checkOutputType(oper_name, List.first(oper_func.outputs), rec_node, InstNode.info(oper_func.node));
//    then ();
//    case "'and'" algorithm
//      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
//      checkOutputType(oper_name, List.first(oper_func.outputs), NFBuiltin.BOOLEAN_NODE, InstNode.info(oper_func.node));
//    then ();
//    case "'or'" algorithm
//      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
//      checkOutputType(oper_name, List.first(oper_func.outputs), NFBuiltin.BOOLEAN_NODE, InstNode.info(oper_func.node));
//    then ();
//    case "'not'" algorithm
//      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
//      checkOutputType(oper_name, List.first(oper_func.outputs), NFBuiltin.BOOLEAN_NODE, InstNode.info(oper_func.node));
//    then ();
//    case "'String'" algorithm
//      checkOneOutput(oper_name, oper_func.outputs, rec_node, InstNode.info(oper_func.node));
//      checkOutputType(oper_name, List.first(oper_func.outputs), NFBuiltin.STRING_NODE, InstNode.info(oper_func.node));
//    then ();
//
//    else ();
//
//  end match;
//end checkValidOperatorOverload;

//public
//function checkOneOutput
//  input String oper_name;
//  input list<InstNode> outputs;
//  input InstNode rec_node;
//  input SourceInfo info;
//protected
//  InstNode out_class;
//algorithm
//  if listLength(outputs) <> 1 then
//      Error.addSourceMessage(Error.OPERATOR_OVERLOADING_WARNING,
//          {"Overloaded " + oper_name + " operator functions are required to have exactly one output. Found "
//          + intString(listLength(outputs))}, info);
//  end if;
//end checkOneOutput;
//
//public
//function checkTwoInputs
//  input String oper_name;
//  input list<InstNode> inputs;
//  input InstNode rec_node;
//  input SourceInfo info;
//protected
//  InstNode out_class;
//algorithm
//  if listLength(inputs) < 2 then
//      Error.addSourceMessage(Error.OPERATOR_OVERLOADING_WARNING,
//          {"Binary overloaded " + oper_name + " operator functions are required to have at least two inputs. Found "
//          + intString(listLength(inputs))}, info);
//  end if;
//end checkTwoInputs;
//
//function checkOutputType
//  input String oper_name;
//  input InstNode outc;
//  input InstNode expected;
//  input SourceInfo info;
//protected
//  InstNode out_class;
//algorithm
//  out_class := InstNode.classScope(outc);
//  if not InstNode.isSame(out_class, expected) then
//    Error.addSourceMessage(Error.OPERATOR_OVERLOADING_WARNING,
//      {"Wrong type for output of overloaded operator function '"+ oper_name +
//        "'. Expected '" + InstNode.scopeName(expected) + "' Found '" + InstNode.scopeName(outc) + "'"}, info);
//  end if;
//end checkOutputType;

function checkBinaryOperationAdd
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  MatchKind mk;
  Boolean valid;
algorithm
  (e1, e2, resultType, mk) := matchExpressions(exp1, type1, exp2, type2, true);
  valid := isCompatibleMatch(mk);

  valid := match Type.arrayElementType(resultType)
    case Type.INTEGER() then valid;
    case Type.REAL() then valid;
    case Type.STRING() then valid;
    else false;
  end match;

  binaryExp := Expression.BINARY(e1, Operator.makeAdd(resultType), e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationAdd;

function checkBinaryOperationSub
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  MatchKind mk;
  Boolean valid;
algorithm
  (e1, e2, resultType, mk) := matchExpressions(exp1, type1, exp2, type2, true);
  valid := isCompatibleMatch(mk);

  valid := match Type.arrayElementType(resultType)
    case Type.INTEGER() then valid;
    case Type.REAL() then valid;
    else false;
  end match;

  binaryExp := Expression.BINARY(e1, Operator.makeSub(resultType), e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationSub;

function checkBinaryOperationMul
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  Type ty1, ty2;
  list<Dimension> dims1, dims2;
  Dimension dim11, dim12, dim21, dim22;
  MatchKind mk;
  Op op;
  Boolean valid;
algorithm
  ty1 := Type.arrayElementType(type1);
  ty2 := Type.arrayElementType(type2);
  (e1, e2, resultType, mk) := matchExpressions(exp1, ty1, exp2, ty2, true);
  valid := isCompatibleMatch(mk);

  valid := match resultType
    case Type.INTEGER() then valid;
    case Type.REAL() then valid;
    else false;
  end match;

  dims1 := Type.arrayDims(type1);
  dims2 := Type.arrayDims(type2);

  (resultType, op) := match (dims1, dims2)
    // scalar * scalar = scalar
    case ({}, {}) then (resultType, Op.MUL);
    // scalar * array = array
    case ({}, _) then (Type.ARRAY(resultType, dims2), Op.MUL_SCALAR_ARRAY);
    // array * scalar = array
    case (_, {}) then (Type.ARRAY(resultType, dims1), Op.MUL_ARRAY_SCALAR);
    // vector[n] * vector[n] = scalar
    case ({dim11}, {dim21})
      algorithm
        valid := Dimension.isEqual(dim11, dim21);
      then
        (resultType, Op.SCALAR_PRODUCT);

    // vector[n] * matrix[n, m] = vector[m]
    case ({dim11}, {dim21, dim22})
      algorithm
        valid := Dimension.isEqual(dim11, dim21);
      then
        (Type.ARRAY(resultType, {dim22}), Op.MUL_VECTOR_MATRIX);

    // matrix[n, m] * vector[m] = vector[n]
    case ({dim11, dim12}, {dim21})
      algorithm
        valid := Dimension.isEqual(dim12, dim21);
      then
        (Type.ARRAY(resultType, {dim11}), Op.MUL_MATRIX_VECTOR);

    // matrix[n, m] * matrix[m, p] = vector[n, p]
    case ({dim11, dim12}, {dim21, dim22})
      algorithm
        valid := Dimension.isEqual(dim12, dim21);
      then
        (Type.ARRAY(resultType, {dim11, dim22}), Op.MATRIX_PRODUCT);

    else
      algorithm
        valid := false;
      then
        (resultType, Op.MUL);
  end match;

  binaryExp := Expression.BINARY(e1, Operator.OPERATOR(resultType, op), e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationMul;

function checkBinaryOperationDiv
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  input Boolean isElementWise;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  Type ty1, ty2;
  MatchKind mk;
  Boolean valid;
  Operator op;
algorithm
  // Division always returns a Real value, so instead of checking if the types
  // are compatible with each other we check if each type is compatible with Real.
  (e1, ty1, mk) := matchTypes(type1, Type.setArrayElementType(type1, Type.REAL()), exp1, true);
  valid := isCompatibleMatch(mk);
  (e2, ty2, mk) := matchTypes(type2, Type.setArrayElementType(type2, Type.REAL()), exp2, true);
  valid := valid and isCompatibleMatch(mk);

  // Division is always element-wise, the only difference between / and ./ is
  // which operands they accept.
  (resultType, op) := match (Type.isArray(ty1), Type.isArray(ty2), isElementWise)
    // scalar / scalar or scalar ./ scalar
    case (false, false, _   ) then (ty1, Operator.makeDiv(ty1));
    // array / scalar or array ./ scalar
    case (_    , false, _   ) then (ty1, Operator.OPERATOR(ty1, Op.DIV_ARRAY_SCALAR));
    // scalar ./ array
    case (false, _    , true) then (ty2, Operator.OPERATOR(ty2, Op.DIV_SCALAR_ARRAY));

    // array ./ array
    case (true , _    , true)
      algorithm
        // If both operands are arrays, check that their dimensions are compatible.
        (_, _, mk) := matchArrayTypes(ty1, ty2, e1, true);
        valid := valid and isCompatibleMatch(mk);
      then
        (ty1, Operator.makeDiv(ty1));

    // Anything else is an error.
    else
      algorithm
        valid := false;
      then
        (ty1, Operator.makeDiv(ty1));
  end match;

  binaryExp := Expression.BINARY(e1, op, e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationDiv;

function checkBinaryOperationPow
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  MatchKind mk;
  Boolean valid;
  Operator op;
algorithm
  // The first operand of ^ should be Real.
  (e1, resultType, mk) := matchTypes(type1, Type.setArrayElementType(type1, Type.REAL()), exp1, true);
  valid := isCompatibleMatch(mk);

  if Type.isArray(resultType) then
    // Real[n, n] ^ Integer
    valid := valid and Type.isSquareMatrix(resultType);
    valid := valid and Type.isInteger(type2);
    op := Operator.OPERATOR(resultType, Op.POW_MATRIX);
    e2 := exp2;
  else
    // Real ^ Real
    (e2, _, mk) := matchTypes(type2, Type.REAL(), exp2, true);
    valid := valid and isCompatibleMatch(mk);
    op := Operator.OPERATOR(resultType, Op.POW);
  end if;

  binaryExp := Expression.BINARY(e1, op, e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationPow;

function checkBinaryOperationPowEW
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  Type ty1, ty2;
  MatchKind mk;
  Boolean valid;
  Operator op;
algorithm
  // Exponentiation always returns a Real value, so instead of checking if the types
  // are compatible with ecah other we check if each type is compatible with Real.
  (e1, ty1, mk) := matchTypes(type1, Type.setArrayElementType(type1, Type.REAL()), exp1, true);
  valid := isCompatibleMatch(mk);
  (e2, ty2, mk) := matchTypes(type2, Type.setArrayElementType(type2, Type.REAL()), exp2, true);
  valid := valid and isCompatibleMatch(mk);

  (resultType, op) := match (Type.isArray(ty1), Type.isArray(ty2))
    // scalar .^ scalar
    case (false, false) then (ty1, Operator.makePow(ty1));
    // array .^ scalar
    case (_    , false) then (ty1, Operator.OPERATOR(ty1, Op.POW_ARRAY_SCALAR));
    // scalar .^ array
    case (false, _    ) then (ty2, Operator.OPERATOR(ty2, Op.POW_SCALAR_ARRAY));
    // array .^ array
    else
      algorithm
        // If both operands are arrays, check that their dimensions are compatible.
        (_, _, mk) := matchArrayTypes(ty1, ty2, e1, true);
        valid := valid and isCompatibleMatch(mk);
      then
        (ty1, Operator.makePow(ty1));
  end match;

  binaryExp := Expression.BINARY(e1, op, e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationPowEW;

function checkBinaryOperationEW
  input Expression exp1;
  input Type type1;
  input Expression exp2;
  input Type type2;
  input Op elemOp;
  input SourceInfo info;
  output Expression binaryExp;
  output Type resultType;
protected
  Expression e1, e2;
  Type ty1, ty2;
  MatchKind mk;
  Boolean valid, is_arr1, is_arr2;
  Operator op;
algorithm
  is_arr1 := Type.isArray(type1);
  is_arr2 := Type.isArray(type2);

  if is_arr1 and is_arr2 then
    // The expressions must be type compatible if they are both arrays.
    (e1, e2, resultType, mk) := matchExpressions(exp1, type1, exp2, type2, true);
  else
    // Otherwise it's enough if their element types are compatible.
    ty1 := Type.arrayElementType(type1);
    ty2 := Type.arrayElementType(type2);
    (e1, e2, resultType, mk) := matchExpressions(exp1, ty1, exp2, ty2, true);
  end if;

  valid := isCompatibleMatch(mk);

  // Check that the type is valid for the operation.
  valid := match (Type.arrayElementType(resultType), elemOp)
    case (Type.INTEGER(), _) then valid;
    case (Type.REAL(), _) then valid;
    case (Type.STRING(), Op.ADD) then valid;
    else false;
  end match;

  (resultType, op) := match (is_arr1, is_arr2)
    // array * scalar => Op.{elemOp}_ARRAY_SCALAR.
    case (true, false)
      algorithm
        resultType := Type.copyDims(type1, resultType);
        op := Operator.makeArrayScalar(resultType, elemOp);
      then
        (resultType, op);

    // scalar * array => Op.{elemOp}_SCALAR_ARRAY;
    case (false, true)
      algorithm
        resultType := Type.copyDims(type2, resultType);
        op := Operator.makeScalarArray(resultType, elemOp);
      then
        (resultType, op);

    // scalar * scalar and array * array => elemOp.
    else (resultType, Operator.OPERATOR(resultType, elemOp));
  end match;

  binaryExp := Expression.BINARY(e1, op, e2);

  if not valid then
    printUnresolvableTypeError(binaryExp, {type1, type2}, info);
  end if;
end checkBinaryOperationEW;

public function checkUnaryOperation
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator operator;
  input SourceInfo info;
  output Expression unaryExp;
  output Type unaryType;
protected
  Boolean valid = true;
  Operator op;
algorithm
  if Type.isComplex(Type.arrayElementType(type1)) then
  (unaryExp,unaryType) := checkOverloadedUnaryOperator(exp1, type1, var1, operator, info);
    return;
  end if;

  unaryType := type1;
  op := Operator.setType(unaryType, operator);

  unaryExp := match operator.op
    case Op.ADD then exp1; // + is a no-op for arithmetic unary operations.
    else Expression.UNARY(op, exp1);
  end match;

  if not Type.isNumeric(type1) then
    printUnresolvableTypeError(unaryExp, {type1}, info);
  end if;
end checkUnaryOperation;

public function checkOverloadedUnaryOperator
  input Expression inExp1;
  input Type inType1;
  input Variability var;
  input Operator inOp;
  input SourceInfo info;
  output Expression outExp;
  output Type outType;
protected
  String opstr;
  Function operfn;
  InstNode node1, fn_node;
  ComponentRef fn_ref;
  list<Function> candidates;
  Boolean matched;
  list<TypedArg> args;
  FunctionMatchKind matchKind;
  MatchedFunction matchedFunc;
  list<MatchedFunction> matchedFunctions = {}, exactMatches;
algorithm
  opstr := Operator.symbol(inOp,"'");
  candidates := OperatorOverloading.lookupOperatorFunctionsInType(opstr, inType1);

  //for fn in candidates loop
  //  checkValidOperatorOverload(opstr, fn, node1);
  //end for;

  args := {(inExp1,inType1,var)};
  matchedFunctions := Function.matchFunctionsSilent(candidates, args, {}, info, vectorize = false);

  // We only allow exact matches for operator overloading. e.g. no casting or generic matches.
  exactMatches := MatchedFunction.getExactMatches(matchedFunctions);
  if listEmpty(exactMatches) then
    printUnresolvableTypeError(Expression.UNARY(inOp, inExp1), {inType1}, info);
    fail();
  end if;

  if listLength(exactMatches) == 1 then
    matchedFunc ::_ := exactMatches;
    outType := Function.returnType(matchedFunc.func);
    outExp := Expression.CALL(
      Call.makeTypedCall(
        matchedFunc.func,
        list(Util.tuple31(a) for a in matchedFunc.args),
        var,
        outType));
  else
    Error.addSourceMessage(Error.AMBIGUOUS_MATCHING_OPERATOR_FUNCTIONS_NFINST,
      {Expression.toString(Expression.UNARY(inOp, inExp1)),
       Function.candidateFuncListString(list(mfn.func for mfn in matchedFunctions))}, info);
    fail();
  end if;
end checkOverloadedUnaryOperator;

function checkLogicalBinaryOperation
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator operator;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input SourceInfo info;
  output Expression outExp;
  output Type resultType;
protected
  Expression e1, e2;
  MatchKind mk;
algorithm
  if Type.isComplex(Type.arrayElementType(type1)) or
     Type.isComplex(Type.arrayElementType(type2)) then
    (outExp,resultType) := checkOverloadedBinaryOperator(exp1, type1, var1, operator, exp2, type2, var2, info);
    return;
  end if;


  (e1, e2, resultType, mk) := matchExpressions(exp1, type1, exp2, type2, true);
  outExp := Expression.LBINARY(e1, Operator.setType(resultType, operator), e2);

  if not isCompatibleMatch(mk) or
     not Type.isBoolean(Type.arrayElementType(resultType)) then
    printUnresolvableTypeError(outExp, {type1, type2}, info);
  end if;
end checkLogicalBinaryOperation;

function checkLogicalUnaryOperation
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator operator;
  input SourceInfo info;
  output Expression outExp;
  output Type resultType = type1;
protected
  Expression e1, e2;
  MatchKind mk;
algorithm
  if Type.isComplex(Type.arrayElementType(type1)) then
    (outExp,resultType) := checkOverloadedUnaryOperator(exp1, type1, var1, operator, info);
    return;
  end if;

  outExp := Expression.LUNARY(Operator.setType(type1, operator), exp1);

  if not Type.isBoolean(Type.arrayElementType(type1)) then
    printUnresolvableTypeError(outExp, {type1}, info);
  end if;
end checkLogicalUnaryOperation;

function checkRelationOperation
  input Expression exp1;
  input Type type1;
  input Variability var1;
  input Operator operator;
  input Expression exp2;
  input Type type2;
  input Variability var2;
  input ExpOrigin.Type origin;
  input SourceInfo info;
  output Expression outExp;
  output Type resultType;
protected
  Expression e1, e2;
  Type ty;
  MatchKind mk;
  Boolean valid;
  Op o;
algorithm

  if Type.isComplex(Type.arrayElementType(type1)) or
     Type.isComplex(Type.arrayElementType(type2)) then
    (outExp,resultType) := checkOverloadedBinaryOperator(exp1, type1, var1, operator, exp2, type2, var2, info);
    return;
  end if;

  (e1, e2, ty, mk) := matchExpressions(exp1, type1, exp2, type2);
  valid := isCompatibleMatch(mk);

  resultType := Type.BOOLEAN();
  outExp := Expression.RELATION(e1, Operator.setType(ty, operator), e2);

  valid := match ty
    case Type.INTEGER() then valid;
    case Type.REAL()
      algorithm
        // Print a warning for == or <> with Real operands in a model.
        o := operator.op;
        if ExpOrigin.flagNotSet(origin, ExpOrigin.FUNCTION) and (o == Op.EQUAL or o == Op.NEQUAL) then
          Error.addSourceMessage(Error.WARNING_RELATION_ON_REAL,
            {Expression.toString(outExp), Operator.symbol(operator, "")}, info);
        end if;
      then
        valid;
    case Type.STRING() then valid;
    case Type.BOOLEAN() then valid;
    case Type.ENUMERATION() then valid;
    else false;
  end match;

  if not valid then
    printUnresolvableTypeError(outExp, {type1, type2}, info);
  end if;
end checkRelationOperation;

function printUnresolvableTypeError
  input Expression exp;
  input list<Type> types;
  input SourceInfo info;
  input Boolean printError = true;
protected
  String exp_str, ty_str;
algorithm
  if printError then
    exp_str := Expression.toString(exp);
    ty_str := List.toString(types, Type.toString, "", "", ", ", "", false);
    Error.addSourceMessage(Error.UNRESOLVABLE_TYPE, {exp_str, ty_str, "<NO_COMPONENT>"}, info);
  end if;

  fail();
end printUnresolvableTypeError;

//
//public function matchCallArgs
//"@mahge:
//  matches given call args with the expected or formal arguments for a function.
//  if vectorization dimension (inVectDims) is given (is not empty) then the function
//  works with vectorization mode.
//  otherwise no vectorization will be done.
//
//  However if matching fails in no vect. mode due to dim mismatch then
//  a vect dim will be returned from  NFTypeCheck.matchCallArgs and this
//  function will start all over again with the new vect dimension."
//
//  input list<Expression> inArgs;
//  input list<Type> inArgTypes;
//  input list<Type> inExpectedTypes;
//  input DAE.Dimensions inVectDims;
//  output list<Expression> outFixedArgs;
//  output DAE.Dimensions outVectDims;
//algorithm
//  (outFixedArgs, outVectDims):=
//  matchcontinue (inArgs,inArgTypes,inExpectedTypes, inVectDims)
//    local
//      Expression e,e_1;
//      list<Expression> restargs, fixedArgs;
//      Type t1,t2;
//      list<Type> restinty,restexpcty;
//      DAE.Dimensions dims1, dims2;
//      String e1Str, t1Str, t2Str, s1;
//
//    case ({},{},{},_) then ({}, inVectDims);
//
//    // No vectorization mode.
//    // If things continue to match with no vect.
//    // Then all is good.
//    case (e::restargs, (t1 :: restinty), (t2 :: restexpcty), {})
//      equation
//        (e_1, {}) = matchCallArg(e,t1,t2,{});
//
//        (fixedArgs, {}) = matchCallArgs(restargs, restinty, restexpcty, {});
//      then
//        (e_1::fixedArgs, {});
//
//    // No vectorization mode.
//    // If argument failed to match not because of dim mismatch
//    // but due to actuall type mismatch then it is an invalid call and we fail here.
//    case (e::_, (t1 :: _), (t2 :: _), {})
//      equation
//        failure((_,_) = matchCallArg(e,t1,t2,{}));
//
//        e1Str = ExpressionDump.printExpStr(e);
//        t1Str = Types.unparseType(t1);
//        t2Str = Types.unparseType(t2);
//        s1 = "Failed to match or convert '" + e1Str + "' of type '" + t1Str +
//             "' to type '" + t2Str + "'";
//        Error.addSourceMessage(Error.INTERNAL_ERROR, {s1}, Absyn.dummyInfo);
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFTypeCheck.matchCallArgs failed with type mismatch: " + t1Str + " tys: " + t2Str);
//      then
//        fail();
//
//    // No -> Yes vectorization mode.
//    // If argument fails to match due to dim mistmatch. then we
//    // have our vect. dim and we start from the begining.
//    case (e::_, (t1 :: _), (t2 :: _), {})
//      equation
//        (_, dims1) = matchCallArg(e,t1,t2,{});
//
//        // This is just to be realllly sure. The cases above actually make sure of it.
//        false = Expression.dimsEqual(dims1, {});
//
//        // Start from the first arg. This time with Vectorization.
//        (fixedArgs, dims2) = matchCallArgs(inArgs,inArgTypes,inExpectedTypes, dims1);
//      then
//        (fixedArgs, dims2);
//
//    // Vectorization mode.
//    case (e::restargs, (t1 :: restinty), (t2 :: restexpcty), dims1)
//      equation
//        false = Expression.dimsEqual(dims1, {});
//        (e_1, dims1) = matchCallArg(e,t1,t2,dims1);
//        (fixedArgs, dims1) = matchCallArgs(restargs, restinty, restexpcty, dims1);
//      then
//        (e_1::fixedArgs, dims1);
//
//
//
//    case (_::_,(_ :: _),(_ :: _), _)
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.trace("- NFTypeCheck.matchCallArgs failed\n");
//      then
//        fail();
//  end matchcontinue;
//end matchCallArgs;
//
//
//public function matchCallArg
//"@mahge:
//  matches a given call arg with the expected or formal argument for a function.
//  if vectorization dimension (inVectDims) is given (is not empty) then the function
//  works with vectorization mode.
//  otherwise no vectorization will be done.
//
//  However if matching fails in no vect. mode due to dim mismatch then
//  it will try to see if vectoriztion is possible. If so the vectorization dim is
//  returned to NFTypeCheck.matchCallArg so that it can start matching from the begining
//  with the new vect dim."
//
//  input Expression inArg;
//  input Type inArgType;
//  input Type inExpectedType;
//  input DAE.Dimensions inVectDims;
//  output Expression outArg;
//  output DAE.Dimensions outVectDims;
//algorithm
//  (outArg, outVectDims) := matchcontinue (inArg,inArgType,inExpectedType,inVectDims)
//    local
//      Expression e,e_1;
//      Type e_type,expected_type;
//      String e1Str, t1Str, t2Str, s1;
//      DAE.Dimensions dims1, dims2, foreachdim;
//
//
//    // No vectorization mode.
//    // Types match (i.e. dims match exactly). Then all is good
//    case (e,e_type,expected_type, {})
//      equation
//        // Of course matchtype will make sure of this
//        // but this is faster.
//        dims1 = Types.getDimensions(e_type);
//        dims2 = Types.getDimensions(expected_type);
//        true = Expression.dimsEqual(dims1, dims2);
//
//        (e_1,_) = Types.matchType(e, e_type, expected_type, true);
//      then
//        (e_1, {});
//
//
//    // No vectorization mode.
//    // If it failed NOT because of dim mismatch but because
//    // of actuall type mismatch then fail here.
//    case (_,e_type,expected_type, {})
//      equation
//        dims1 = Types.getDimensions(e_type);
//        dims2 = Types.getDimensions(expected_type);
//        true = Expression.dimsEqual(dims1, dims2);
//      then
//        fail();
//
//    // No Vect. -> Vectorization mode.
//    // We found a dim mistmatch. Try vectorizing. If vectorizing
//    // matches, then this is our vectoriztion dimension.
//    // N.B. We still have to start matching again from the first arg
//    // with the new vectorization dimension.
//    case (e,e_type,expected_type, {})
//      equation
//        dims1 = Types.getDimensions(e_type);
//        dims2 = Types.getDimensions(expected_type);
//
//        false = Expression.dimsEqual(dims1, dims2);
//
//        foreachdim = findVectorizationDim(dims1,dims2);
//
//      then
//        (e, foreachdim);
//
//
//    // IN Vectorization mode!!!.
//    case (e,e_type,expected_type, foreachdim)
//      equation
//        e_1 = checkVectorization(e,e_type,expected_type,foreachdim);
//      then
//        (e_1, foreachdim);
//
//
//    case (e,e_type,expected_type, _)
//      equation
//        e1Str = ExpressionDump.printExpStr(e);
//        t1Str = Types.unparseType(e_type);
//        t2Str = Types.unparseType(expected_type);
//        s1 = "Failed to match or convert '" + e1Str + "' of type '" + t1Str +
//             "' to type '" + t2Str + "'";
//        Error.addSourceMessage(Error.INTERNAL_ERROR, {s1}, Absyn.dummyInfo);
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFTypeCheck.matchCallArg failed with type mismatch: " + t1Str + " tys: " + t2Str);
//      then
//        fail();
//  end matchcontinue;
//end matchCallArg;
//
//
//protected function checkVectorization
//"@mahge:
//  checks if it is possible to vectorize a given argument to the
//  expected or formal argument with the given vectorization dim.
//  e.g. inForeachDim=[3,2]
//       function F(input Integer[2]);
//
//       Integer a[2,3,2], b[2,2,2],s;
//
//       a is vectorizable with [3,2] => a[1]), a[2]
//       b is not vectorizable with [3,2]
//       s is vectorizable with [3,2] => {{s,s},{s,s},{s,s}}
//
//  N.B. The vectoriztion dim came from the first arg mismatch in
//  NFTypeCheck.matchCallArg and all susequent args shoudl be vectorizable
//  with that dim. This function checks that.
//  "
//  input Expression inArg;
//  input Type inArgType;
//  input Type inExpectedType;
//  input DAE.Dimensions inForeachDim;
//  output Expression outArg;
//algorithm
//  outArg := matchcontinue (inArg,inArgType,inExpectedType,inForeachDim)
//    local
//      Expression outExp;
//      DAE.Dimensions expectedDims, argDims;
//      String e1Str, t1Str, t2Str, s1;
//      Type expcType;
//
//    // if types match (which also means dims match exactly).
//    // Then we have to change the given argument to an array of
//    // the vect. dim to have a 'foreach' argument
//    case(_,_,_,_)
//      equation
//        // Of course matchtype will make sure of this
//        // but this is faster.
//        argDims = Types.getDimensions(inArgType);
//        expectedDims = Types.getDimensions(inExpectedType);
//        true = Expression.dimsEqual(argDims, expectedDims);
//
//        (outExp,_) = Types.matchType(inArg, inArgType, inExpectedType, false);
//
//        // create the array from the given arg to match the vectorization
//        outExp = Expression.arrayFill(inForeachDim,outExp);
//      then
//        outExp;
//
//    // if dims don't match exactly. Then the given argument
//    // must have the same dimension as our vecorization or 'foreach' dimension.
//    // And the expected type will be lifeted to the 'foreach' dim and then
//    // matched with the given argument
//    case(_,_,_,_)
//      equation
//
//        argDims = Types.getDimensions(inArgType);
//
//        // lift the expected type by 'foreach' dims
//        expcType = Types.liftArrayListDims(inExpectedType,inForeachDim);
//
//        // Now the given type and the expected type must have the
//        // same dimesions. Otherwise vectorization is not possible.
//        expectedDims = Types.getDimensions(expcType);
//        true = Expression.dimsEqual(argDims, expectedDims);
//
//        (outExp,_) = Types.matchType(inArg, inArgType, expcType, false);
//      then
//        outExp;
//
//    else
//      equation
//        argDims = Types.getDimensions(inArgType);
//        expectedDims = Types.getDimensions(inExpectedType);
//
//        expectedDims = listAppend(inForeachDim,expectedDims);
//
//        e1Str = ExpressionDump.printExpStr(inArg);
//        t1Str = Types.unparseType(inArgType);
//        t2Str = Types.unparseType(inExpectedType);
//        s1 = "Vectorization can not continue matching '" + e1Str + "' of type '" + t1Str +
//             "' to type '" + t2Str + "'. Expected dimensions [" +
//             ExpressionDump.printListStr(expectedDims,ExpressionDump.dimensionString,",") + "], found [" +
//             ExpressionDump.printListStr(argDims,ExpressionDump.dimensionString,",") + "]";
//
//        Error.addSourceMessage(Error.INTERNAL_ERROR, {s1}, Absyn.dummyInfo);
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFTypeCheck.checkVectorization failed ");
//      then
//        fail();
//
//   end matchcontinue;
//
//end checkVectorization;
//
//
//public function findVectorizationDim
//"@mahge:
// This function basically finds the diff between two dims. The resulting dimension
// is used for vectorizing calls.
//
// e.g. dim1=[2,3,4,2]  dim2=[4,2], findVectorizationDim(dim1,dim2) => [2,3]
//      dim1=[2,3,4,2]  dim2=[3,4,2], findVectorizationDim(dim1,dim2) => [2]
//      dim1=[2,3,4,2]  dim2=[4,3], fail
// "
//  input DAE.Dimensions inGivenDims;
//  input DAE.Dimensions inExpectedDims;
//  output DAE.Dimensions outVectDims;
//algorithm
//  outVectDims := matchcontinue(inGivenDims, inExpectedDims)
//    local
//      DAE.Dimensions dims1;
//      DAE.Dimension dim1;
//
//    case(_, {}) then inGivenDims;
//
//    case(_, _)
//      equation
//        true = Expression.dimsEqual(inGivenDims, inExpectedDims);
//      then
//        {};
//
//    case(dim1::dims1, _)
//      equation
//        true = listLength(inGivenDims) > listLength(inExpectedDims);
//        dims1 = findVectorizationDim(dims1,inExpectedDims);
//      then
//        dim1::dims1;
//
//    case(_::_, _)
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFTypeCheck.findVectorizationDim failed with dimensions: [" +
//         ExpressionDump.printListStr(inGivenDims,ExpressionDump.dimensionString,",") + "] vs [" +
//         ExpressionDump.printListStr(inExpectedDims,ExpressionDump.dimensionString,",") + "].");
//      then
//        fail();
//
//  end matchcontinue;
//
//end findVectorizationDim;
//
//
//public function makeCallReturnType
//"@mahge:
//   makes the return type for function.
//   i.e if a list of types is given then it is a tuple ret function.
// "
//  input list<Type> inTypeLst;
//  output Type outType;
//  output Boolean outBoolean;
//algorithm
//  (outType,outBoolean) := match (inTypeLst)
//    local
//      Type ty;
//
//    case {} then (DAE.T_NORETCALL(DAE.emptyTypeSource), false);
//
//    case {ty} then (ty, false);
//
//    else  (DAE.T_TUPLE(inTypeLst,NONE(),DAE.emptyTypeSource), true);
//
//  end match;
//end makeCallReturnType;
//
//
//
//public function vectorizeCall
//"@mahge:
//   Vectorizes calls. Most of the work is done
//   vectorizeCall2.
//   This function get a list of functions with each arg
//   subscripted from vectorizeCall2. e.g. {F(a[1,1]),F(a[1,2]),F(a[2,1]),F(a[2,2])}
//   The it converts the list to an array of 'inForEachdim' dims using
//   Expression.listToArray. i.e.
//   {F(a[1,1]),F(a[1,2]),F(a[2,1]),F(a[2,2])} with vec. dim [2,2] will be
//   {{F(a[1,1]),F(a[1,2])}, {F(a[2,1])F(a[2,2])}}
//
// "
//  input Absyn.Path inFnName;
//  input list<Expression> inArgs;
//  input DAE.CallAttributes inAttrs;
//  input Type inRetType;
//  input DAE.Dimensions inForEachdim;
//  output Expression outExp;
//  output Type outType;
//algorithm
//  (outExp,outType) := matchcontinue (inFnName,inArgs,inAttrs,inRetType,inForEachdim)
//    local
//      list<Expression> callLst;
//      Expression callArr;
//      Type outtype;
//
//
//    // If no 'forEachdim' then no vectorization
//    case(_, _, _, _, {}) then (DAE.CALL(inFnName, inArgs, inAttrs), inRetType);
//
//
//    case(_, _::_, _, _, _)
//      equation
//        // Get the call list with args subscripted for each value in 'foreaach' dim.
//        callLst = vectorizeCall2(inFnName, inArgs, inAttrs, inForEachdim, {});
//
//        // Create the array of calls from the list
//        callArr = Expression.listToArray(callLst,inForEachdim);
//
//        // lift the retType to 'forEachDim' dims
//        outtype = Types.liftArrayListDims(inRetType, inForEachdim);
//      then
//        (callArr, outtype);
//
//    else
//      equation
//        Error.addMessage(Error.INTERNAL_ERROR, {"NFTypeCheck.vectorizeCall failed."});
//      then
//        fail();
//
//  end matchcontinue;
//end vectorizeCall;
//
//
//public function vectorizeCall2
//"@mahge:
//   Vectorizes calls. This function takes a list of args for a function
//   and a vectorization dim. then it subscripts the args for each idex
//   of the vec. dim and creates a function call for each subscripted
//   arg list. Then retuns the list of functions.
//   e.g.
//   for argLst ( a, {{b,b,b},{c,c,c}} ) and functionname F with vect. dim of [2,3]
//   this function creates the list
//
//   {F(a[1,1],b), F(a[1,2],b), F(a[1,3],b), F(a[2,1],c), F(a[2,2],c), F(a[2,3],c)}
// "
//  input Absyn.Path inFnName;
//  input list<Expression> inArgs;
//  input DAE.CallAttributes inAttrs;
//  input DAE.Dimensions inDims;
//  input list<Expression> inAccumCalls;
//  output list<Expression> outAccumCalls;
//algorithm
//  outAccumCalls := matchcontinue(inFnName, inArgs, inAttrs, inDims, inAccumCalls)
//    local
//      DAE.Dimension dim;
//      DAE.Dimensions dims;
//      Expression idx;
//      list<Expression> calls, subedargs;
//
//    case (_, _, _, {}, _) then DAE.CALL(inFnName, inArgs, inAttrs) :: inAccumCalls;
//
//    case (_, _, _, dim :: dims, _)
//      equation
//        (idx, dim) = getNextIndex(dim);
//
//        subedargs = List.map1(inArgs, Expression.subscriptExp, {DAE.INDEX(idx)});
//
//        calls = vectorizeCall2(inFnName, subedargs, inAttrs, dims, inAccumCalls);
//        calls = vectorizeCall2(inFnName, inArgs, inAttrs, dim :: dims, calls);
//      then
//        calls;
//
//    else inAccumCalls;
//
//  end matchcontinue;
//end vectorizeCall2;
//
//protected function getNextIndex
//  "Returns the next index given a dimension, and updates the dimension. Fails
//  when there are no indices left."
//  input DAE.Dimension inDim;
//  output Expression outNextIndex;
//  output DAE.Dimension outDim;
//algorithm
//  (outNextIndex, outDim) := match(inDim)
//    local
//      Integer new_idx, dim_size;
//      Absyn.Path p, ep;
//      String l;
//      list<String> l_rest;
//
//    case DAE.DIM_INTEGER(integer = 0) then fail();
//    case DAE.DIM_ENUM(size = 0) then fail();
//
//    case DAE.DIM_INTEGER(integer = new_idx)
//      equation
//        dim_size = new_idx - 1;
//      then
//        (DAE.ICONST(new_idx), DAE.DIM_INTEGER(dim_size));
//
//    // Assumes that the enum has been reversed with reverseEnumType.
//    case DAE.DIM_ENUM(p, l :: l_rest, new_idx)
//      equation
//        ep = Absyn.joinPaths(p, Absyn.IDENT(l));
//        dim_size = new_idx - 1;
//      then
//        (DAE.ENUM_LITERAL(ep, new_idx), DAE.DIM_ENUM(p, l_rest, dim_size));
//  end match;
//end getNextIndex;


// ************************************************************** //
//   END: TypeCall helper functions
// ************************************************************** //

function matchExpressions
  input output Expression exp1;
  input Type type1;
  input output Expression exp2;
  input Type type2;
  input Boolean allowUnknown = false;
        output Type compatibleType;
        output MatchKind matchKind;
algorithm
  // Return true if the references are the same.
  if referenceEq(type1, type2) then
    compatibleType := type1;
    matchKind := MatchKind.EXACT;
    return;
  end if;

  // Check if the types are different kinds of types.
  if valueConstructor(type1) <> valueConstructor(type2) then
    // If the types are not of the same kind we might need to type cast one of
    // the expressions to make them compatible.
    (exp1, exp2, compatibleType, matchKind) :=
      matchExpressions_cast(exp1, type1, exp2, type2, allowUnknown);
    return;
  end if;

  // The types are of the same kind, so we only need to match on one of them.
  matchKind := MatchKind.EXACT;
  compatibleType := match type1
    case Type.INTEGER() then type1;
    case Type.REAL() then type1;
    case Type.STRING() then type1;
    case Type.BOOLEAN() then type1;
    case Type.CLOCK() then type1;

    case Type.ENUMERATION()
      algorithm
        matchKind := matchEnumerationTypes(type1, type2);
      then
        type1;

    case Type.ENUMERATION_ANY() then type1;

    case Type.ARRAY()
      algorithm
        (exp1, exp2, compatibleType, matchKind) :=
          matchArrayExpressions(exp1, type1, exp2, type2, allowUnknown);
      then
        compatibleType;

    case Type.TUPLE()
      algorithm
        (exp2, compatibleType, matchKind) :=
          matchTupleTypes(type2, type1, exp2, allowUnknown);
      then
        compatibleType;

    case Type.UNKNOWN()
      algorithm
        matchKind := if allowUnknown then MatchKind.EXACT else MatchKind.NOT_COMPATIBLE;
      then
        type1;

    case Type.COMPLEX()
      algorithm
        // TODO: This needs more work to handle e.g. type casting of complex expressions.
        (exp1, compatibleType, matchKind) :=
          matchComplexTypes(type1, type2, exp1, allowUnknown);
      then
        compatibleType;

    case Type.METABOXED()
      algorithm
        (exp1, exp2, compatibleType, matchKind) :=
          matchBoxedExpressions(exp1, type1, exp2, type2, allowUnknown);
      then
        compatibleType;

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown type.", sourceInfo());
      then
        fail();

  end match;
end matchExpressions;

function matchTypes
  input Type actualType;
  input Type expectedType;
  input output Expression expression;
  input Boolean allowUnknown = false; // TODO: This allowUnknown is currently used for two different things.
                                      // Allowing matches againest unknown types AND also allowing matching
                                      // when dim sizes are unknown. These should be separated.
        output Type compatibleType;
        output MatchKind matchKind;
algorithm
  // Return true if the references are the same.
  if referenceEq(actualType, expectedType) then
    compatibleType := actualType;
    matchKind := MatchKind.EXACT;
    return;
  end if;

  // Check if the types are different kinds of types.
  if valueConstructor(actualType) <> valueConstructor(expectedType) then
    // If the types are not of the same kind we might need to type cast the
    // expression to make it compatible.
    (expression, compatibleType, matchKind) :=
      matchTypes_cast(actualType, expectedType, expression, allowUnknown);
    return;
  end if;

  // The types are of the same kind, so we only need to match on one of them.
  matchKind := MatchKind.EXACT;
  compatibleType := match actualType
    case Type.INTEGER() then actualType;
    case Type.REAL() then actualType;
    case Type.STRING() then actualType;
    case Type.BOOLEAN() then actualType;
    case Type.CLOCK() then actualType;

    case Type.ENUMERATION()
      algorithm
        matchKind := matchEnumerationTypes(actualType, expectedType);
      then
        actualType;

    case Type.ENUMERATION_ANY() then actualType;

    case Type.ARRAY()
      algorithm
        (expression, compatibleType, matchKind) :=
          matchArrayTypes(actualType, expectedType, expression, allowUnknown);
      then
        compatibleType;

    case Type.TUPLE()
      algorithm
        (expression, compatibleType, matchKind) :=
          matchTupleTypes(actualType, expectedType, expression, allowUnknown);
      then
        compatibleType;

    case Type.UNKNOWN()
      algorithm
        matchKind := if allowUnknown then MatchKind.EXACT else MatchKind.NOT_COMPATIBLE;
      then
        actualType;

    case Type.COMPLEX()
      algorithm
        (expression, compatibleType, matchKind) :=
          matchComplexTypes(actualType, expectedType, expression, allowUnknown);
      then
        compatibleType;

    case Type.FUNCTION()
      algorithm
        (expression, compatibleType, matchKind) :=
          matchFunctionTypes(actualType, expectedType, expression, allowUnknown);
      then
        compatibleType;

    case Type.METABOXED()
      algorithm
        (expression, compatibleType, matchKind) :=
          matchTypes(actualType.ty, Type.unbox(expectedType), Expression.unbox(expression), allowUnknown);
        expression := Expression.box(expression);
        compatibleType := Type.box(compatibleType);
      then
        compatibleType;

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown type.", sourceInfo());
      then
        fail();

  end match;
end matchTypes;

function matchExpressions_cast
  input output Expression exp1;
  input Type type1;
  input output Expression exp2;
  input Type type2;
  input Boolean allowUnknown;
        output Type compatibleType;
        output MatchKind matchKind;
algorithm
  (compatibleType, matchKind) := match (type1, type2)
    // Integer can be cast to Real.
    case (Type.INTEGER(), Type.REAL())
      algorithm
        exp1 := Expression.typeCast(exp1, type2);
      then
        (type2, MatchKind.CAST);

    case (Type.REAL(), Type.INTEGER())
      algorithm
        exp2 := Expression.typeCast(exp2, type1);
      then
        (type1, MatchKind.CAST);

    // This case takes care of equations where the lhs is a non-tuple and the rhs a
    // function call returning a tuple, in which case only the first element of the
    // tuple is used. exp1 should never be a tuple here, since any tuple expression
    // not alone on the rhs of an equation is "tuple subscripted" by Typing.typeExp.
    case (_, Type.TUPLE(types = compatibleType :: _))
      algorithm
        exp2 := Expression.tupleElement(exp2, compatibleType, 1);
        (exp2, compatibleType, matchKind) :=
          matchTypes(compatibleType, type1, exp2, allowUnknown);

        if isCompatibleMatch(matchKind) then
          matchKind := MatchKind.CAST;
        end if;
      then
        (compatibleType, matchKind);

    case (Type.UNKNOWN(), _)
      then (type2, if allowUnknown then MatchKind.EXACT else MatchKind.NOT_COMPATIBLE);

    case (_, Type.UNKNOWN())
      then (type1, if allowUnknown then MatchKind.EXACT else MatchKind.NOT_COMPATIBLE);

    case (Type.METABOXED(), _)
      algorithm
        (exp1, exp2, compatibleType, matchKind) :=
          matchExpressions(Expression.unbox(exp1), type1.ty, exp2, type2, allowUnknown);
      then
        (compatibleType, matchKind);

    case (_, Type.METABOXED())
      algorithm
        (exp1, exp2, compatibleType, matchKind) :=
          matchExpressions(exp1, type1, Expression.unbox(exp2), type2.ty, allowUnknown);
      then
        (compatibleType, matchKind);

    case (_, Type.POLYMORPHIC())
      algorithm
        exp1 := Expression.box(exp1);
      then
        (Type.box(type1), MatchKind.GENERIC);

    case (Type.POLYMORPHIC(), _)
      algorithm
        exp2 := Expression.box(exp2);
      then
        (Type.box(type2), MatchKind.GENERIC);

    else (Type.UNKNOWN(), MatchKind.NOT_COMPATIBLE);
  end match;
end matchExpressions_cast;

function matchComplexTypes
  input Type actualType;
  input Type expectedType;
  input output Expression expression;
  input Boolean allowUnknown;
        output Type compatibleType = actualType;
        output MatchKind matchKind = MatchKind.NOT_COMPATIBLE;
protected
  Class cls1, cls2;
  InstNode anode, enode;
  array<InstNode> comps1, comps2;
  Absyn.Path path;
  Type ty;
  ComplexType cty1, cty2;
  Expression e;
  list<Expression> elements, matched_elements = {};
  MatchKind mk;
algorithm
  Type.COMPLEX(cls = anode) := actualType;
  Type.COMPLEX(cls = enode) := expectedType;

  // TODO: revise this.
  if InstNode.isSame(anode, enode) then
    matchKind := MatchKind.EXACT;
    return;
  end if;

  cls1 := InstNode.getClass(anode);
  cls2 := InstNode.getClass(enode);

  () := match (cls1, cls2, expression)

    case (Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps1)),
          Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps2)),
          Expression.RECORD(elements = elements))
      algorithm
        matchKind := MatchKind.PLUG_COMPATIBLE;

        if arrayLength(comps1) <> arrayLength(comps2) or
           arrayLength(comps1) <> listLength(elements) then
          matchKind := MatchKind.NOT_COMPATIBLE;
        else
          for i in 1:arrayLength(comps1) loop
            e :: elements := elements;
            (e, _, mk) := matchTypes(InstNode.getType(comps1[i]), InstNode.getType(comps2[i]), e, allowUnknown);
            matched_elements := e :: matched_elements;

            if mk == MatchKind.CAST then
              matchKind := mk;
            elseif not isValidPlugCompatibleMatch(mk) then
              matchKind := MatchKind.NOT_COMPATIBLE;
              break;
            end if;
          end for;

          if matchKind == MatchKind.CAST then
            expression.elements := listReverse(matched_elements);
          end if;
        end if;

        if matchKind <> MatchKind.NOT_COMPATIBLE then
          matchKind := MatchKind.PLUG_COMPATIBLE;
        end if;

      then
        ();

    case (Class.INSTANCED_CLASS(ty = Type.COMPLEX(complexTy = cty1 as ComplexType.CONNECTOR())),
          Class.INSTANCED_CLASS(ty = Type.COMPLEX(complexTy = cty2 as ComplexType.CONNECTOR())), _)
      algorithm
        matchKind := matchComponentList(cty1.potentials, cty2.potentials, allowUnknown);
        if matchKind <> MatchKind.NOT_COMPATIBLE then
          matchKind := matchComponentList(cty1.flows, cty2.flows, allowUnknown);
          if matchKind <> MatchKind.NOT_COMPATIBLE then
            matchKind := matchComponentList(cty1.streams, cty2.streams, allowUnknown);
          end if;
        end if;

        if matchKind <> MatchKind.NOT_COMPATIBLE then
          matchKind := MatchKind.PLUG_COMPATIBLE;
        end if;
      then
        ();

    case (Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps1)),
          Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps2)), _)
      algorithm
        matchKind := MatchKind.PLUG_COMPATIBLE;

        if arrayLength(comps1) <> arrayLength(comps2) then
          matchKind := MatchKind.NOT_COMPATIBLE;
        else
          for i in 1:arrayLength(comps1) loop
            (_, _, mk) := matchTypes(InstNode.getType(comps1[i]), InstNode.getType(comps2[i]), expression, allowUnknown);

            if not isValidPlugCompatibleMatch(mk) then
              matchKind := MatchKind.NOT_COMPATIBLE;
              break;
            end if;
          end for;
        end if;
      then
        ();

    else
      algorithm
        matchKind := MatchKind.NOT_COMPATIBLE;
      then
        ();

  end match;
end matchComplexTypes;

function matchComponentList
  input list<InstNode> comps1;
  input list<InstNode> comps2;
  input Boolean allowUnknown;
  output MatchKind matchKind;
protected
  InstNode c2;
  list<InstNode> rest_c2 = comps2;
  Expression dummy = Expression.INTEGER(0);
algorithm
  if listLength(comps1) <> listLength(comps2) then
    matchKind := MatchKind.NOT_COMPATIBLE;
  else
    for c1 in comps1 loop
      c2 :: rest_c2 := rest_c2;
      (_, _, matchKind) := matchTypes(InstNode.getType(c1), InstNode.getType(c2), dummy, allowUnknown);

      if matchKind == MatchKind.NOT_COMPATIBLE then
        return;
      end if;
    end for;
  end if;

  matchKind := MatchKind.PLUG_COMPATIBLE;
end matchComponentList;

function matchFunctionTypes
  input Type actualType;
  input Type expectedType;
  input output Expression expression;
  input Boolean allowUnknown;
        output Type compatibleType = actualType;
        output MatchKind matchKind = MatchKind.EXACT;
protected
  list<InstNode> inputs1, inputs2, remaining_inputs, outputs1, outputs2;
  list<Slot> slots1, slots2;
  InstNode input2, output2;
  Slot slot1, slot2;
  Boolean matching;
algorithm
  Type.FUNCTION(fn =
    Function.FUNCTION(inputs = inputs1, outputs = outputs1, slots = slots1)) := actualType;
  Type.FUNCTION(fn =
    Function.FUNCTION(inputs = inputs2, outputs = outputs2, slots = slots2)) := expectedType;

  // The functions must have the same number of outputs.
  if listLength(outputs1) <> listLength(outputs2) then
    matchKind := MatchKind.NOT_COMPATIBLE;
    return;
  end if;

  if not matchFunctionParameters(outputs1, outputs2, allowUnknown) then
    matchKind := MatchKind.NOT_COMPATIBLE;
    return;
  end if;

  if not matchFunctionParameters(inputs1, inputs2, allowUnknown) then
    matchKind := MatchKind.NOT_COMPATIBLE;
    return;
  end if;

  // An input in the actual type must have a default argument if the
  // corresponding input in the expected type has one.
  for i in inputs2 loop
    slot1 :: slots1 := slots1;
    slot2 :: slots2 := slots2;

    if isSome(slot2.default) and not isSome(slot1.default) then
      matchKind := MatchKind.NOT_COMPATIBLE;
      return;
    end if;
  end for;

  // The actual type can have more inputs than expected if the extra inputs have
  // default arguments.
  for slot in slots1 loop
    if not isSome(slot.default) then
      matchKind := MatchKind.NOT_COMPATIBLE;
      return;
    end if;
  end for;
end matchFunctionTypes;

function matchFunctionParameters
  input list<InstNode> params1;
  input list<InstNode> params2;
  input Boolean allowUnknown;
  output Boolean matching = true;
protected
  list<InstNode> pl1 = params1, pl2 = params2;
  InstNode p1;
  Expression dummy = Expression.INTEGER(0);
  MatchKind mk;
algorithm
  for p2 in pl2 loop
    if listEmpty(pl1) then
      matching := false;
      break;
    end if;

    p1 :: pl1 := pl1;

    if InstNode.name(p1) <> InstNode.name(p2) then
      matching := false;
      break;
    end if;

    (_, _, mk) := matchTypes(Type.unbox(InstNode.getType(p1)),
      Type.unbox(InstNode.getType(p2)), dummy, allowUnknown);

    if mk <> MatchKind.EXACT then
      matching := false;
      break;
    end if;
  end for;
end matchFunctionParameters;

function matchEnumerationTypes
  input Type type1;
  input Type type2;
  output MatchKind matchKind;
protected
  list<String> lits1, lits2;
algorithm
  Type.ENUMERATION(literals = lits1) := type1;
  Type.ENUMERATION(literals = lits2) := type2;

  matchKind := if List.isEqualOnTrue(lits1, lits2, stringEqual)
    then MatchKind.EXACT else MatchKind.NOT_COMPATIBLE;
end matchEnumerationTypes;

function matchArrayExpressions
  input output Expression exp1;
  input Type type1;
  input output Expression exp2;
  input Type type2;
  input Boolean allowUnknown;
        output Type compatibleType;
        output MatchKind matchKind;
protected
  Type ety1, ety2;
  list<Dimension> dims1, dims2;
algorithm
  Type.ARRAY(elementType = ety1, dimensions = dims1) := type1;
  Type.ARRAY(elementType = ety2, dimensions = dims2) := type2;

  // Check that the element types are compatible.
  (exp1, exp2, compatibleType, matchKind) :=
    matchExpressions(exp1, ety1, exp2, ety2, allowUnknown);

  // If the element types are compatible, check the dimensions too.
  (compatibleType, matchKind) :=
    matchArrayDims(dims1, dims2, compatibleType, matchKind, allowUnknown);
end matchArrayExpressions;

function matchArrayTypes
  input Type arrayType1;
  input Type arrayType2;
  input output Expression expression;
  input Boolean allowUnknown;
        output Type compatibleType;
        output MatchKind matchKind;
protected
  Type ety1, ety2;
  list<Dimension> dims1, dims2;
algorithm
  Type.ARRAY(elementType = ety1, dimensions = dims1) := arrayType1;
  Type.ARRAY(elementType = ety2, dimensions = dims2) := arrayType2;

  // Check that the element types are compatible.
  (expression, compatibleType, matchKind) :=
    matchTypes(ety1, ety2, expression, allowUnknown);

  // If the element types are compatible, check the dimensions too.
  (compatibleType, matchKind) :=
    matchArrayDims(dims1, dims2, compatibleType, matchKind, allowUnknown);
end matchArrayTypes;

function matchArrayDims
  input list<Dimension> dims1;
  input list<Dimension> dims2;
  input output Type ty;
  input output MatchKind matchKind;
  input Boolean allowUnknown;
protected
  list<Dimension> rest_dims2 = dims2, cdims = {};
  Dimension dim2;
  Boolean compat;
algorithm
  if not isCompatibleMatch(matchKind) then
    return;
  end if;

  // The array types must have the same number of dimensions.
  if listLength(dims1) <> listLength(dims2) then
    matchKind := MatchKind.NOT_COMPATIBLE;
    return;
  end if;

  // The dimensions of both array types must be compatible.
  for dim1 in dims1 loop
    dim2 :: rest_dims2 := rest_dims2;
    (dim1, compat) := matchDimensions(dim1, dim2, allowUnknown);

    if not compat then
      matchKind := MatchKind.NOT_COMPATIBLE;
      break;
    end if;

    cdims := dim1 :: cdims;
  end for;

  ty := Type.ARRAY(ty, listReverseInPlace(cdims));
end matchArrayDims;

function matchDimensions
  input Dimension dim1;
  input Dimension dim2;
  input Boolean allowUnknown;
  output Dimension compatibleDim;
  output Boolean compatible;
algorithm
  if Dimension.isEqual(dim1, dim2) then
    compatibleDim := dim1;
    compatible := true;
  else
    if not Dimension.isKnown(dim1) then
      compatibleDim := dim2;
      compatible := true;
    elseif not Dimension.isKnown(dim2) then
      compatibleDim := dim1;
      compatible := true;
    else
      compatibleDim := dim1;
      compatible := false;
    end if;
  end if;
end matchDimensions;

function matchTupleTypes
  input Type tupleType1;
  input Type tupleType2;
  input output Expression expression;
  input Boolean allowUnknown;
        output Type compatibleType = tupleType1;
        output MatchKind matchKind = MatchKind.EXACT;
protected
  list<Type> tyl1, tyl2;
  Type ty1;
algorithm
  Type.TUPLE(types = tyl1) := tupleType1;
  Type.TUPLE(types = tyl2) := tupleType2;

  if listLength(tyl1) < listLength(tyl2) then
    matchKind := MatchKind.NOT_COMPATIBLE;
    return;
  end if;

  for ty2 in tyl2 loop
    // Skip matching if the rhs is _.
    if Type.isUnknown(ty2) then
      continue;
    end if;

    ty1 :: tyl1 := tyl1;

    (_, _, matchKind) := matchTypes(ty1, ty2, expression, allowUnknown);

    if matchKind <> MatchKind.EXACT then
      break;
    end if;
  end for;
end matchTupleTypes;

function matchBoxedExpressions
  input output Expression exp1;
  input Type type1;
  input output Expression exp2;
  input Type type2;
  input Boolean allowUnknown;
        output Type compatibleType;
        output MatchKind matchKind;
protected
  Expression e1, e2;
algorithm
  e1 := Expression.unbox(exp1);
  e2 := Expression.unbox(exp2);

  (e1, e2, compatibleType, matchKind) :=
    matchExpressions(e1, Type.unbox(type1), e2, Type.unbox(type2), allowUnknown);

  if isCastMatch(matchKind) then
    exp1 := Expression.box(e1);
    exp2 := Expression.box(e2);
  end if;

  compatibleType := Type.box(compatibleType);
end matchBoxedExpressions;

function matchTypes_cast
  input Type actualType;
  input Type expectedType;
  input output Expression expression;
  input Boolean allowUnknown = false;
        output Type compatibleType;
        output MatchKind matchKind;
algorithm
  (compatibleType, matchKind) := match(actualType, expectedType)
    // Integer can be cast to Real.
    case (Type.INTEGER(), Type.REAL())
      algorithm
        expression := Expression.typeCast(expression, expectedType);
      then
        (expectedType, MatchKind.CAST);

    // Any enumeration is compatible with enumeration(:).
    case (Type.ENUMERATION(), Type.ENUMERATION_ANY())
      algorithm
        // TODO: FIXME: Maybe this should be generic match
      then
        (actualType, MatchKind.CAST);

    // If the actual type is a tuple but the expected type isn't,
    // try to use the first type in the tuple.
    case (Type.TUPLE(types = _ :: _), _)
      algorithm
        (expression, compatibleType, matchKind) :=
          matchTypes(listHead(actualType.types), expectedType, expression, allowUnknown);

        if isCompatibleMatch(matchKind) then
          expression := match expression
            case Expression.TUPLE() then listHead(expression.elements);
            else Expression.TUPLE_ELEMENT(expression, 1,
              Type.setArrayElementType(Expression.typeOf(expression), compatibleType));
          end match;

          matchKind := MatchKind.CAST;
        end if;
      then
        (compatibleType, matchKind);

    // Allow unknown types in some cases, e.g. () has type METALIST(UNKNOWN)
    case (Type.UNKNOWN(), _)
      then (expectedType,
        if allowUnknown then MatchKind.UNKNOWN_ACTUAL else MatchKind.NOT_COMPATIBLE);

    case (_, Type.UNKNOWN())
      then (actualType,
        if allowUnknown then MatchKind.UNKNOWN_EXPECTED else MatchKind.NOT_COMPATIBLE);

    case (Type.METABOXED(), _)
      algorithm
        expression := Expression.unbox(expression);
        (expression, compatibleType, matchKind) :=
          matchTypes(actualType.ty, expectedType, expression, allowUnknown);
      then
        (compatibleType, if isCompatibleMatch(matchKind) then MatchKind.CAST else matchKind);

    case (_, Type.METABOXED())
      algorithm
        (expression, compatibleType, matchKind) :=
          matchTypes(actualType, expectedType.ty, expression, allowUnknown);
        expression := Expression.box(expression);
        compatibleType := Type.box(compatibleType);
      then
        (compatibleType, if isCompatibleMatch(matchKind) then MatchKind.CAST else matchKind);

    case (_, Type.POLYMORPHIC())
      algorithm
        expression := Expression.BOX(expression);
        // matchKind := MatchKind.GENERIC(expectedType.b,actualType);
      then
        (Type.METABOXED(actualType), MatchKind.GENERIC);

    case (Type.POLYMORPHIC(), _)
      algorithm
        // expression := Expression.UNBOX(expression, Expression.typeOf(expression));
        // matchKind := MatchKind.GENERIC(expectedType.b,actualType);
      then
        (expectedType, MatchKind.GENERIC);

    // Expected type is any, any actual type matches.
    case (_, Type.ANY()) then (expectedType, MatchKind.EXACT);

    // Anything else is not compatible.
    else (Type.UNKNOWN(), MatchKind.NOT_COMPATIBLE);
  end match;
end matchTypes_cast;

function getRangeType
  input Expression startExp;
  input Option<Expression> stepExp;
  input Expression stopExp;
  input Type rangeElemType;
  input SourceInfo info;
  output Type rangeType;
protected
  Expression step_exp;
  Dimension dim;
algorithm
  dim := match rangeElemType
    case Type.INTEGER() then getRangeTypeInt(startExp, stepExp, stopExp, info);
    case Type.REAL() then getRangeTypeReal(startExp, stepExp, stopExp, info);

    case Type.BOOLEAN()
      algorithm
        if isSome(stepExp) then
          Error.addSourceMessageAndFail(Error.RANGE_INVALID_STEP,
            {Type.toString(rangeElemType)}, info);
        end if;
      then
        getRangeTypeBool(startExp, stopExp);

    case Type.ENUMERATION()
      algorithm
        if isSome(stepExp) then
          Error.addSourceMessageAndFail(Error.RANGE_INVALID_STEP,
            {Type.toString(rangeElemType)}, info);
        end if;
      then
        getRangeTypeEnum(startExp, stopExp);

    else
      algorithm
        Error.addSourceMessage(Error.RANGE_INVALID_TYPE,
          {Type.toString(rangeElemType)}, info);
      then
        fail();
  end match;

  rangeType := Type.ARRAY(rangeElemType, {dim});
end getRangeType;

function getRangeTypeInt
  input Expression startExp;
  input Option<Expression> stepExp;
  input Expression stopExp;
  input SourceInfo info;
  output Dimension dim;
algorithm
  dim := match (startExp, stepExp, stopExp)
    local
      Integer step;
      Expression step_exp, dim_exp;
      Variability var;

    case (Expression.INTEGER(), NONE(), Expression.INTEGER())
      then Dimension.fromInteger(max(stopExp.value - startExp.value + 1, 0));

    case (Expression.INTEGER(), SOME(Expression.INTEGER(value = step)), Expression.INTEGER())
      algorithm
        // Don't allow infinite ranges.
        if step == 0 then
          Error.addSourceMessageAndFail(Error.RANGE_TOO_SMALL_STEP, {String(step)}, info);
        end if;
      then
        Dimension.fromInteger(max(intDiv(stopExp.value - startExp.value, step) + 1, 0));

    // Ranges like 1:n have size n.
    case (Expression.INTEGER(1), NONE(), _)
      algorithm
        dim_exp := SimplifyExp.simplify(stopExp);
      then
        Dimension.fromExp(dim_exp, Expression.variability(dim_exp));

    // Ranges like n:n have size 1.
    case (_, NONE(), _)
      guard Expression.isEqual(startExp, stopExp)
      then Dimension.fromInteger(1);

    // For other ranges, create the appropriate expression as dimension.
    // max(stop - start + 1, 0) or max(((stop - start) / step) + 1, 0)
    else
      algorithm
        dim_exp := Expression.BINARY(stopExp, Operator.makeSub(Type.INTEGER()), startExp);
        var := Prefixes.variabilityMax(Expression.variability(stopExp),
                                       Expression.variability(startExp));

        if isSome(stepExp) then
          SOME(step_exp) := stepExp;
          var := Prefixes.variabilityMax(var, Expression.variability(step_exp));
          dim_exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.DIV_INT, {dim_exp, step_exp}, var));
        end if;

        dim_exp := Expression.BINARY(dim_exp, Operator.makeAdd(Type.INTEGER()), Expression.INTEGER(1));
        dim_exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.MAX_INT, {dim_exp, Expression.INTEGER(0)}, var));
        dim_exp := SimplifyExp.simplify(dim_exp);
      then
        Dimension.fromExp(dim_exp, var);

  end match;
end getRangeTypeInt;

function getRangeTypeReal
  input Expression startExp;
  input Option<Expression> stepExp;
  input Expression stopExp;
  input SourceInfo info;
  output Dimension dim;
algorithm
  dim := match (startExp, stepExp, stopExp)
    local
      Real start, step;
      Expression dim_exp, step_exp;
      Variability var;

    case (Expression.REAL(), NONE(), Expression.REAL())
      then Dimension.fromInteger(Util.realRangeSize(startExp.value, 1.0, stopExp.value));

    case (Expression.REAL(value = start), SOME(Expression.REAL(value = step)), Expression.REAL())
      algorithm
        // Check that adding step to start actually produces a different value,
        // otherwise the step size is too small.
        if start == start + step then
          Error.addSourceMessageAndFail(Error.RANGE_TOO_SMALL_STEP, {String(step)}, info);
        end if;
      then
        Dimension.fromInteger(Util.realRangeSize(startExp.value, step, stopExp.value));

    case (_, NONE(), _)
      guard Expression.isEqual(startExp, stopExp)
      then Dimension.fromInteger(1);

    else
      algorithm
        dim_exp := Expression.BINARY(stopExp, Operator.makeSub(Type.REAL()), startExp);
        var := Prefixes.variabilityMax(Expression.variability(stopExp),
                                       Expression.variability(startExp));

        if isSome(stepExp) then
          SOME(step_exp) := stepExp;
          var := Prefixes.variabilityMax(var, Expression.variability(step_exp));
          dim_exp := Expression.BINARY(dim_exp, Operator.makeDiv(Type.REAL()), step_exp);
          dim_exp := Expression.BINARY(dim_exp, Operator.makeAdd(Type.REAL()), Expression.REAL(5e-15));
        end if;

        dim_exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.FLOOR, {dim_exp}, var));
        dim_exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.INTEGER_REAL, {dim_exp}, var));
        dim_exp := Expression.BINARY(dim_exp, Operator.makeAdd(Type.INTEGER()), Expression.INTEGER(1));
        dim_exp := SimplifyExp.simplify(dim_exp);
      then
        Dimension.fromExp(dim_exp, var);

  end match;
end getRangeTypeReal;

function getRangeTypeBool
  input Expression startExp;
  input Expression stopExp;
  output Dimension dim;
algorithm
  dim := match (startExp, stopExp)
    local
      Integer sz;
      Expression dim_exp;
      Variability var;

    case (Expression.BOOLEAN(), Expression.BOOLEAN())
      algorithm
        sz := if startExp.value == stopExp.value then 1
              elseif startExp.value < stopExp.value then 2
              else 0;
      then
        Dimension.fromInteger(sz);

    else
      algorithm
        if Expression.isEqual(startExp, stopExp) then
          dim := Dimension.fromInteger(1);
        else
          var := Prefixes.variabilityMax(Expression.variability(startExp),
                                         Expression.variability(stopExp));
          dim_exp := Expression.IF(
            Expression.RELATION(startExp, Operator.makeEqual(Type.BOOLEAN()), stopExp),
            Expression.INTEGER(1),
            Expression.IF(
              Expression.RELATION(startExp, Operator.makeLess(Type.BOOLEAN()), stopExp),
              Expression.INTEGER(2),
              Expression.INTEGER(0)));

          dim_exp := SimplifyExp.simplify(dim_exp);
          dim := Dimension.fromExp(dim_exp, var);
        end if;
      then
        dim;

  end match;
end getRangeTypeBool;

function getRangeTypeEnum
  input Expression startExp;
  input Expression stopExp;
  output Dimension dim;
algorithm
  dim := match (startExp, stopExp)
    local
      Expression dim_exp;
      Variability var;

    case (Expression.ENUM_LITERAL(), Expression.ENUM_LITERAL())
      then Dimension.fromInteger(max(stopExp.index - startExp.index + 1, 0));

    case (Expression.ENUM_LITERAL(index = 1), _)
      then Dimension.fromExp(stopExp, Expression.variability(stopExp));

    else
      algorithm
        if Expression.isEqual(startExp, stopExp) then
          dim := Dimension.fromInteger(1);
        else
          var := Prefixes.variabilityMax(Expression.variability(startExp),
                                         Expression.variability(stopExp));

          dim_exp := Expression.BINARY(
            Expression.enumIndexExp(startExp),
            Operator.makeSub(Type.INTEGER()),
            Expression.enumIndexExp(stopExp));

          dim_exp := Expression.BINARY(
            dim_exp,
            Operator.makeAdd( Type.INTEGER()),
            Expression.INTEGER(1));

          dim_exp := SimplifyExp.simplify(dim_exp);
          dim := Dimension.fromExp(dim_exp, var);
        end if;
      then
        dim;

  end match;
end getRangeTypeEnum;

function matchBinding
  input output Binding binding;
  input Type componentType;
  input String name;
  input InstNode component;
algorithm
  () := match binding
    local
      MatchKind ty_match;
      Expression exp;
      Type ty, comp_ty;
      list<list<Dimension>> dims;

    case Binding.TYPED_BINDING()
      algorithm
        comp_ty := componentType;
        if not binding.isEach then
          dims := list(Type.arrayDims(InstNode.getType(p)) for p in listRest(binding.parents));
          comp_ty := Type.liftArrayLeftList(comp_ty, List.flattenReverse(dims));
        end if;

        (exp, ty, ty_match) := matchTypes(binding.bindingType, comp_ty, binding.bindingExp, true);

        if not isValidAssignmentMatch(ty_match) then
          printBindingTypeError(name, binding, comp_ty, binding.bindingType, component);
          fail();
        elseif isCastMatch(ty_match) then
          binding := Binding.TYPED_BINDING(exp, ty, binding.variability, binding.parents, binding.isEach, binding.evaluated, binding.isFlattened, binding.info);
        end if;
      then
        ();

    case Binding.UNBOUND() then ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got untyped binding " + Binding.toString(binding), sourceInfo());
      then
        fail();
  end match;
end matchBinding;

function printBindingTypeError
  input String name;
  input Binding binding;
  input Type componentType;
  input Type bindingType;
  input InstNode component;
protected
  SourceInfo binding_info, comp_info;
  String bind_ty_str, comp_ty_str;
  MatchKind mk;
algorithm
  binding_info := Binding.getInfo(binding);
  comp_info := InstNode.info(component);

  if Type.isScalar(bindingType) and Type.isArray(componentType) then
    Error.addMultiSourceMessage(Error.MODIFIER_NON_ARRAY_TYPE_ERROR,
      {Binding.toString(binding), name}, {binding_info, comp_info});
  else
    (_, _, mk) := matchTypes(Type.arrayElementType(bindingType),
                             Type.arrayElementType(componentType),
                             Expression.EMPTY(bindingType), true);

    if isValidAssignmentMatch(mk) then
      Error.addMultiSourceMessage(Error.VARIABLE_BINDING_DIMS_MISMATCH,
        {name, Binding.toString(binding),
         Dimension.toStringList(Type.arrayDims(componentType)),
         Dimension.toStringList(Type.arrayDims(bindingType))},
        {binding_info, comp_info});
    else
      Error.addMultiSourceMessage(Error.VARIABLE_BINDING_TYPE_MISMATCH,
        {name, Binding.toString(binding), Type.toString(componentType),
         Type.toString(bindingType)}, {binding_info, comp_info});
    end if;
  end if;
end printBindingTypeError;

function checkDimensionType
  "Checks that an expression used as a dimension has a valid type for a
   dimension, otherwise prints an error and fails."
  input Expression exp;
  input Type ty;
  input SourceInfo info;
algorithm
  if not Type.isInteger(ty) then
    () := match exp
      case Expression.TYPENAME(ty = Type.ARRAY(elementType = Type.BOOLEAN())) then ();
      case Expression.TYPENAME(ty = Type.ARRAY(elementType = Type.ENUMERATION())) then ();
      else
        algorithm
          Error.addSourceMessage(Error.INVALID_DIMENSION_TYPE,
            {Expression.toString(exp), Type.toString(ty)}, info);
        then
          fail();
    end match;
  end if;
end checkDimensionType;

function checkReductionType
  input Type ty;
  input Absyn.Path name;
  input Expression exp;
  input SourceInfo info;
protected
  Type ety;
  String err;
algorithm
  err := match name
    case Absyn.Path.IDENT("sum")
      then
        match Type.arrayElementType(ty)
          case Type.INTEGER() then "";
          case Type.REAL() then "";
          else "Integer or Real";
        end match;

    case Absyn.Path.IDENT("product")
      then
        match ty
          case Type.INTEGER() then "";
          case Type.REAL() then "";
          else "scalar Integer or Real";
        end match;

    case Absyn.Path.IDENT("min")
      then
        match ty
          case Type.INTEGER() then "";
          case Type.REAL() then "";
          case Type.BOOLEAN() then "";
          case Type.ENUMERATION() then "";
          else "scalar enumeration, Boolean, Integer or Real";
        end match;

    case Absyn.Path.IDENT("max")
      then
        match ty
          case Type.INTEGER() then "";
          case Type.REAL() then "";
          case Type.BOOLEAN() then "";
          case Type.ENUMERATION() then "";
          else "scalar enumeration, Boolean, Integer or Real";
        end match;

    else "";
  end match;

  if not stringEmpty(err) then
    Error.addSourceMessageAndFail(Error.INVALID_REDUCTION_TYPE,
      {Expression.toString(exp), Type.toString(ty), Absyn.pathString(name), err}, info);
  end if;
end checkReductionType;

annotation(__OpenModelica_Interface="frontend");
end NFTypeCheck;
