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
import Binding = NFBinding;
import NFPrefixes.{Variability, Purity};
import Subscript = NFSubscript;

protected
import Config;
import DAEExpression = Expression;
import Error;
import Flags;
import List;
import Types;
import Operator = NFOperator;
import Type = NFType;
import Class = NFClass;
import ClassTree = NFClassTree;
import Prefixes = NFPrefixes;
import Restriction = NFRestriction;
import ComplexType = NFComplexType;
import NFOperator.Op;
import NFFunction.Function;
import NFFunction.TypedArg;
import NFFunction.FunctionMatchKind;
import NFFunction.MatchedFunction;
import Call = NFCall;
import BuiltinCall = NFBuiltinCall;
import ComponentRef = NFComponentRef;
import ErrorExt;
import NFBuiltin;
import SimplifyExp = NFSimplifyExp;
import MetaModelica.Dangerous.*;
import OperatorOverloading = NFOperatorOverloading;
import ExpandExp = NFExpandExp;
import NFFunction.Slot;
import Util;
import Component = NFComponent;
import InstContext = NFInstContext;
import NFInstNode.InstNodeType;

public
type MatchKind = enumeration(
  EXACT "Exact match",
  CAST  "Matched by casting, e.g. Integer to Real",
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
  if Type.isConditionalArray(type1) or Type.isConditionalArray(type2) then
    (binaryExp, resultType) := checkConditionalBinaryOperator(exp1, type1, var1, operator, exp2, type2, var2, info);
  elseif Type.isComplex(Type.arrayElementType(type1)) or
     Type.isComplex(Type.arrayElementType(type2)) then
    (binaryExp, resultType) := checkOverloadedBinaryOperator(exp1, type1, var1, operator, exp2, type2, var2, info);
  elseif Type.isBoxed(type1) and Type.isBoxed(type2) then
    (binaryExp, resultType) := checkBinaryOperationBoxed(exp1, type1, var1, operator, exp2, type2, var2, info);
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
      // These operators should not occur in untyped expressions, but sometimes
      // we want to retype already typed expressions due to changes in them.
      case Op.ADD_SCALAR_ARRAY then checkBinaryOperationAdd(exp1, type1, exp2, type2, info);
      case Op.ADD_ARRAY_SCALAR then checkBinaryOperationAdd(exp1, type1, exp2, type2, info);
      case Op.SUB_SCALAR_ARRAY then checkBinaryOperationSub(exp1, type1, exp2, type2, info);
      case Op.SUB_ARRAY_SCALAR then checkBinaryOperationSub(exp1, type1, exp2, type2, info);
      case Op.MUL_SCALAR_ARRAY  then checkBinaryOperationMul(exp1, type1, exp2, type2, info);
      case Op.MUL_ARRAY_SCALAR  then checkBinaryOperationMul(exp1, type1, exp2, type2, info);
      case Op.MUL_VECTOR_MATRIX then checkBinaryOperationMul(exp1, type1, exp2, type2, info);
      case Op.MUL_MATRIX_VECTOR then checkBinaryOperationMul(exp1, type1, exp2, type2, info);
      case Op.SCALAR_PRODUCT    then checkBinaryOperationMul(exp1, type1, exp2, type2, info);
      case Op.MATRIX_PRODUCT    then checkBinaryOperationMul(exp1, type1, exp2, type2, info);
      case Op.DIV_SCALAR_ARRAY  then checkBinaryOperationDiv(exp1, type1, exp2, type2, info, isElementWise = false);
      case Op.DIV_ARRAY_SCALAR  then checkBinaryOperationDiv(exp1, type1, exp2, type2, info, isElementWise = false);
      case Op.POW_SCALAR_ARRAY  then checkBinaryOperationPowEW(exp1, type1, exp2, type2, info);
      case Op.POW_ARRAY_SCALAR  then checkBinaryOperationPowEW(exp1, type1, exp2, type2, info);
      case Op.POW_MATRIX        then checkBinaryOperationPow(exp1, type1, exp2, type2, info);
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
  args := {
    TypedArg.TYPED_ARG(NONE(), exp1, type1, var1, Purity.PURE),
    TypedArg.TYPED_ARG(NONE(), exp2, type2, var2, Purity.PURE)
  };
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
        list(a.value for a in matchedFunc.args),
        Prefixes.variabilityMax(var1, var2),
        Purity.PURE,
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

public function checkBinaryOperationBoxed
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
  Expression e1, e2;
  Type ty1, ty2;
algorithm
  (e1, ty1) := matchTypes(type1, Type.unbox(type1), exp1);
  (e2, ty2) := matchTypes(type2, Type.unbox(type2), exp2);
  (outExp, outType) := checkBinaryOperation(e1, ty1, var1, op, e2, ty2, var2, info);
end checkBinaryOperationBoxed;

protected
function checkConditionalBinaryOperator
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
  Type tty1, fty1, tty2, fty2, ty1, ty2;
  Expression e1, e2;
  Boolean valid1, valid2;
  NFType.Branch branch;
algorithm
  (tty1, fty1, tty2, fty2, branch) := match (type1, type2)
    case (Type.CONDITIONAL_ARRAY(), _)
      then (type1.trueType, type1.falseType, type2, type2, type1.matchedBranch);
    case (_, Type.CONDITIONAL_ARRAY())
      then (type1, type1, type2.trueType, type2.falseType, type2.matchedBranch);
  end match;

  ErrorExt.setCheckpoint(getInstanceName());
  try
    (e1, ty1) := checkBinaryOperation(exp1, tty1, var1, op, exp2, tty2, var2, info);
    valid1 := true;
  else
    valid1 := false;
  end try;

  try
    (e2, ty2) := checkBinaryOperation(exp1, fty1, var1, op, exp2, fty2, var2, info);
    valid2 := true;
  else
    valid2 := false;
  end try;
  ErrorExt.rollBack(getInstanceName());

  if valid1 and valid2 then
    outType := Type.CONDITIONAL_ARRAY(ty1, ty2, branch);
    outExp := e1;
  elseif valid1 then
    outType := Type.CONDITIONAL_ARRAY(ty1, Type.UNKNOWN(), NFType.Branch.TRUE);
    outExp := e1;
  elseif valid2 then
    outType := Type.CONDITIONAL_ARRAY(Type.UNKNOWN(), ty2, NFType.Branch.FALSE);
    outExp := e2;
  else
    printUnresolvableTypeError(exp1, {type1, type2}, info);
  end if;

  outExp := Expression.setType(outType, outExp);
end checkConditionalBinaryOperator;

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
    outExp := Expression.CALL(Call.makeTypedCall(operfn, {exp1, exp2}, var, Purity.PURE, outType));
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
    fn_ref := Function.instFunction(Absyn.CREF_IDENT("'constructor'", {}),
      scope, NFInstContext.NO_CONTEXT, paramInfo2);
    e2 := Expression.CALL(Call.UNTYPED_CALL(fn_ref, {exp2}, {}, scope));
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
  // are compatible with each other we check if each type is compatible with Real.
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

  args := {TypedArg.TYPED_ARG(NONE(), inExp1, inType1, var, Purity.PURE)};
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
        list(a.value for a in matchedFunc.args),
        var,
        Purity.PURE,
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
  input InstContext.Type context;
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
        if not InstContext.inFunction(context) and (o == Op.EQUAL or o == Op.NEQUAL) then
          Error.addStrictMessage(Error.WARNING_RELATION_ON_REAL,
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

    case Type.CONDITIONAL_ARRAY()
      algorithm
        (expression, compatibleType, matchKind) :=
          matchConditionalArrayTypes(actualType, expectedType, expression, allowUnknown);
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

    // Boolean can be cast to Real (only if -d=nfAPI is on)
    // as there are annotations having expressions such as Boolean x > 0.5
    case (Type.BOOLEAN(), Type.REAL()) guard Flags.isSet(Flags.NF_API)
      algorithm
        Error.addCompilerWarning("Allowing casting of boolean expression: " + Expression.toString(exp1) + " to Real.");
        exp1 := Expression.typeCast(exp1, type2);
      then
        (type2, MatchKind.CAST);

    case (Type.REAL(), Type.BOOLEAN()) guard Flags.isSet(Flags.NF_API)
      algorithm
        Error.addCompilerWarning("Allowing casting of boolean expression: " + Expression.toString(exp2) + " to Real.");
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

    case (Type.CONDITIONAL_ARRAY(), _)
      algorithm
        (exp1, exp2, compatibleType, matchKind) :=
          matchConditionalArrayExp(exp1, type1, exp2, type2, allowUnknown);
      then
        (compatibleType, matchKind);

    case (_, Type.CONDITIONAL_ARRAY())
      algorithm
        (exp2, exp1, compatibleType, matchKind) :=
          matchConditionalArrayExp(exp2, type2, exp1, type1, allowUnknown);
      then
        (compatibleType, matchKind);

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
  Component comp1, comp2;
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
            comp2 := InstNode.component(comps2[i]);

            if Component.isTyped(comp2) then
              e :: elements := elements;
              comp1 := InstNode.component(comps1[i]);
              (e, _, mk) := matchTypes(Component.getType(comp1), Component.getType(comp2), e, allowUnknown);
              matched_elements := e :: matched_elements;

              if mk == MatchKind.CAST then
                matchKind := mk;
              elseif not isValidPlugCompatibleMatch(mk) then
                matchKind := MatchKind.NOT_COMPATIBLE;
                break;
              end if;
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
            comp2 := InstNode.component(comps2[i]);

            if Component.isTyped(comp2) then
              comp1 := InstNode.component(comps1[i]);
              (_, _, mk) := matchTypes(Component.getType(comp1), Component.getType(comp2), expression, allowUnknown);

              if not isValidPlugCompatibleMatch(mk) then
                matchKind := MatchKind.NOT_COMPATIBLE;
                break;
              end if;
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

      if InstNode.name(c1) <> InstNode.name(c2) then
        matchKind := MatchKind.NOT_COMPATIBLE;
        return;
      end if;

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
    ty1 :: tyl1 := tyl1;

    // Skip matching if the rhs is _.
    if Type.isUnknown(ty2) then
      continue;
    end if;

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

function matchConditionalArrayExp
  input output Expression condExp;
  input Type condType;
  input output Expression otherExp;
  input Type otherType;
  input Boolean allowUnknown;
        output Type compatibleType;
        output MatchKind matchKind;
protected
  Type true_ty, false_ty, cond_ty, comp_ty1, comp_ty2;
  Expression e1_1, e2_1, e1_2, e2_2;
  NFType.Branch branch;
  MatchKind mk1, mk2;
  Boolean compat1, compat2;
algorithm
  Type.CONDITIONAL_ARRAY(trueType = true_ty, falseType = false_ty, matchedBranch = branch) := condType;

  if branch == NFType.Branch.NONE then
    // If no branch has already been selected as the correct branch, check both of them.
    (e1_1, e2_1, comp_ty1, mk1) :=
      matchExpressions(condExp, true_ty, otherExp, otherType, allowUnknown);

    (e1_2, e2_2, comp_ty2, mk2) :=
      matchExpressions(condExp, false_ty, otherExp, otherType, allowUnknown);

    compat1 := isCompatibleMatch(mk1);
    compat2 := isCompatibleMatch(mk2);

    (compatibleType, otherExp, matchKind) := match (isCompatibleMatch(mk1), isCompatibleMatch(mk2))
      // Both branches matched, one of them is probably itself of a conditional
      // array type since the types should otherwise have different dimensions.
      case (true, true)
        algorithm
          cond_ty := Type.CONDITIONAL_ARRAY(comp_ty1, comp_ty2, NFType.Branch.NONE);
          condExp := Expression.typeCast(condExp, cond_ty);
        then
          (comp_ty1, otherExp, mk1);

      // Only the first branch matches, mark it as the correct branch.
      case (true, _)
        algorithm
          cond_ty := Type.CONDITIONAL_ARRAY(comp_ty1, comp_ty2, NFType.Branch.TRUE);
          condExp := Expression.typeCast(e1_1, cond_ty);
        then
          (comp_ty1, e2_1, mk1);

      // Only the second branch matches, mark it as the correct branch.
      case (_, true)
        algorithm
          cond_ty := Type.CONDITIONAL_ARRAY(comp_ty1, comp_ty2, NFType.Branch.FALSE);
          condExp := Expression.typeCast(e1_2, cond_ty);
        then
          (comp_ty2, e2_2, mk2);

      else (condType, condExp, mk1);
    end match;
  else
    if branch == NFType.Branch.TRUE then
      (condExp, otherExp, compatibleType, matchKind) :=
        matchExpressions(condExp, true_ty, otherExp, otherType, allowUnknown);
      cond_ty := Type.CONDITIONAL_ARRAY(compatibleType, false_ty, branch);
    else
      (condExp, otherExp, compatibleType, matchKind) :=
        matchExpressions(condExp, false_ty, otherExp, otherType, allowUnknown);
      cond_ty := Type.CONDITIONAL_ARRAY(true_ty, compatibleType, branch);
    end if;

    if isCompatibleMatch(matchKind) then
      condExp := Expression.typeCast(condExp, cond_ty);
    end if;
  end if;
end matchConditionalArrayExp;

function matchConditionalArrayTypes
  input Type actualType;
  input Type expectedType;
  input output Expression exp;
  input Boolean allowUnknown;
        output Type compatibleType;
        output MatchKind matchKind;
protected
  Type actual_true_ty, actual_false_ty;
  Type expected_true_ty, expected_false_ty;
  Type true_ty, false_ty;
  Expression true_exp, false_exp;
algorithm
  Type.CONDITIONAL_ARRAY(trueType = actual_true_ty, falseType = actual_false_ty) := actualType;
  Type.CONDITIONAL_ARRAY(trueType = expected_true_ty, falseType = expected_false_ty) := expectedType;

  () := match exp
    case Expression.IF()
      algorithm
        (true_exp, true_ty, matchKind) :=
          matchTypes(actual_true_ty, expected_true_ty, exp.trueBranch, allowUnknown);

        if not isCompatibleMatch(matchKind) then
          compatibleType := actualType;
          return;
        end if;

        (false_exp, false_ty, matchKind) :=
          matchTypes(actual_false_ty, expected_false_ty, exp.falseBranch, allowUnknown);

        if not isCompatibleMatch(matchKind) then
          compatibleType := actualType;
          return;
        end if;

        compatibleType := Type.CONDITIONAL_ARRAY(true_ty, false_ty, NFType.Branch.NONE);
        exp := Expression.IF(compatibleType, exp.condition, true_exp, false_exp);
      then
        ();
  end match;
end matchConditionalArrayTypes;

function matchConditionalArrayTypes_cast
  input Type condType;
  input Type expectedType;
  input output Expression exp;
  input Boolean allowUnknown;
        output Type compatibleType;
        output MatchKind matchKind;
protected
  Type true_ty, false_ty, cond_ty, comp_ty1, comp_ty2;
  Expression e1, e2;
  NFType.Branch branch;
  MatchKind mk1, mk2;
algorithm
  Type.CONDITIONAL_ARRAY(trueType = true_ty, falseType = false_ty, matchedBranch = branch) := condType;

  if branch == NFType.Branch.NONE then
    // If no branch has already been selected as the correct branch, check both of them.
    (e1, comp_ty1, mk1) := matchTypes(true_ty, expectedType, exp, allowUnknown);
    (e2, comp_ty2, mk2) := matchTypes(false_ty, expectedType, exp, allowUnknown);

    (compatibleType, matchKind) := match (isCompatibleMatch(mk1), isCompatibleMatch(mk2))
      // Both branches matched, one of them is probably itself of a conditional
      // array type since the types should otherwise have different dimensions.
      case (true, true)
        algorithm
          cond_ty := Type.CONDITIONAL_ARRAY(comp_ty1, comp_ty2, NFType.Branch.NONE);
          exp := Expression.typeCast(exp, cond_ty);
        then
          (comp_ty1, mk1);

      // Only the first branch matches, mark it as the correct branch.
      case (true, _)
        algorithm
          cond_ty := Type.CONDITIONAL_ARRAY(comp_ty1, false_ty, NFType.Branch.TRUE);
          exp := Expression.typeCast(e1, cond_ty);
        then
          (comp_ty1, mk1);

      // Only the second branch matches, mark it as the correct branch.
      case (_, true)
        algorithm
          cond_ty := Type.CONDITIONAL_ARRAY(true_ty, comp_ty2, NFType.Branch.FALSE);
          exp := Expression.typeCast(e2, cond_ty);
        then
          (comp_ty2, mk2);

      else (condType, mk1);
    end match;
  else
    if branch == NFType.Branch.TRUE then
      (exp, compatibleType, matchKind) := matchTypes(true_ty, expectedType, exp, allowUnknown);
      cond_ty := Type.CONDITIONAL_ARRAY(compatibleType, false_ty, branch);
    else
      (exp, compatibleType, matchKind) := matchTypes(false_ty, expectedType, exp, allowUnknown);
      cond_ty := Type.CONDITIONAL_ARRAY(true_ty, compatibleType, branch);
    end if;

    if isCompatibleMatch(matchKind) then
      exp := Expression.typeCast(exp, cond_ty);
    end if;
  end if;
end matchConditionalArrayTypes_cast;

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
        (expression, compatibleType, matchKind) :=
          matchPolymorphic(expectedType.name, actualType, expression);
      then
        (compatibleType, matchKind);

    case (Type.POLYMORPHIC(), _)
      algorithm
        // expression := Expression.unbox(expression);
        // matchKind := MatchKind.GENERIC(expectedType.b,actualType);
      then
        (expectedType, MatchKind.GENERIC);

    // Expected type is any, any actual type matches.
    case (_, Type.ANY()) then (expectedType, MatchKind.EXACT);

    case (Type.CONDITIONAL_ARRAY(), _)
      algorithm
        (expression, compatibleType, matchKind) :=
          matchConditionalArrayTypes_cast(actualType, expectedType, expression, allowUnknown);
      then
        (compatibleType, matchKind);

    // Anything else is not compatible.
    else (Type.UNKNOWN(), MatchKind.NOT_COMPATIBLE);
  end match;
end matchTypes_cast;

function matchPolymorphic
  input String polymorphicName;
  input Type actualType;
  input output Expression exp;
        output Type compatibleType;
        output MatchKind matchKind;
algorithm
  (compatibleType, matchKind) := match polymorphicName
    // Any type, used when we don't want the expression to be boxed.
    case "__Any" then (actualType, MatchKind.GENERIC);

    // Any scalar type.
    case "__Scalar"
      algorithm
        matchKind := if Type.isScalar(actualType) then MatchKind.GENERIC else MatchKind.NOT_COMPATIBLE;
      then
        (actualType, matchKind);

    // Any array type.
    case "__Array"
      algorithm
        matchKind := if Type.isArray(actualType) then MatchKind.GENERIC else MatchKind.NOT_COMPATIBLE;
      then
        (actualType, matchKind);

    case "__Connector"
      algorithm
        matchKind := if Type.isScalar(actualType) and Expression.isConnector(exp) then
          MatchKind.GENERIC else MatchKind.NOT_COMPATIBLE;
      then
        (actualType, matchKind);

    case "__ComponentExpression"
      algorithm
        matchKind := if Type.isScalar(actualType) and Expression.isComponentExpression(exp) then
          MatchKind.GENERIC else MatchKind.NOT_COMPATIBLE;
      then
        (actualType, matchKind);

    else
      algorithm
        exp := Expression.box(exp);
      then
        (Type.METABOXED(actualType), MatchKind.GENERIC);

  end match;
end matchPolymorphic;

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
      Purity pur;

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
        pur := Prefixes.purityMin(Expression.purity(stopExp),
                                  Expression.purity(startExp));

        if isSome(stepExp) then
          SOME(step_exp) := stepExp;
          var := Prefixes.variabilityMax(var, Expression.variability(step_exp));
          pur := Prefixes.purityMin(pur, Expression.purity(step_exp));
          dim_exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.DIV_INT, {dim_exp, step_exp}, var, pur));
        end if;

        dim_exp := Expression.BINARY(dim_exp, Operator.makeAdd(Type.INTEGER()), Expression.INTEGER(1));
        dim_exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.MAX_INT, {dim_exp, Expression.INTEGER(0)}, var, pur));
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
      Purity pur;

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
        pur := Prefixes.purityMin(Expression.purity(stopExp), Expression.purity(startExp));

        if isSome(stepExp) then
          SOME(step_exp) := stepExp;
          var := Prefixes.variabilityMax(var, Expression.variability(step_exp));
          pur := Prefixes.purityMin(pur, Expression.purity(step_exp));
          dim_exp := Expression.BINARY(dim_exp, Operator.makeDiv(Type.REAL()), step_exp);
          dim_exp := Expression.BINARY(dim_exp, Operator.makeAdd(Type.REAL()), Expression.REAL(5e-15));
        end if;

        dim_exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.FLOOR, {dim_exp}, var, pur));
        dim_exp := Expression.CALL(Call.makeTypedCall(NFBuiltinFuncs.INTEGER_REAL, {dim_exp}, var, pur));
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
          // [if start == stop then 1 else if start < stop then 2 else 0]
          dim_exp := Expression.IF(
            Type.INTEGER(),
            Expression.RELATION(startExp, Operator.makeEqual(Type.BOOLEAN()), stopExp),
            Expression.INTEGER(1),
            Expression.IF(
              Type.INTEGER(),
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
      Type ty, bind_ty, comp_ty;
      list<list<Dimension>> dims;

    case Binding.TYPED_BINDING(bindingExp = exp)
      algorithm
        (bind_ty, comp_ty) := elaborateBindingType(exp, component, binding.bindingType, componentType);
        (exp, ty, ty_match) := matchTypes(bind_ty, comp_ty, exp, true);

        if not isValidAssignmentMatch(ty_match) then
          binding.bindingExp := Expression.expandSplitIndices(exp);
          printBindingTypeError(name, binding, comp_ty, bind_ty, component);
          fail();
        elseif isCastMatch(ty_match) then
          binding := Binding.TYPED_BINDING(exp, ty, binding.variability, binding.eachType,
            binding.evalState, binding.isFlattened, binding.source, binding.info);
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

function elaborateBindingType
  "If the binding expression comes from a modifier, returns the type of the
   actual binding expression and adds dimensions to the component type to match.
   This is done so that modifiers are type checked properly, i.e.:

    model A
      Real x;
    end A;

    model B
      A a[3](x = {1, 2});
    end B;

   means the bindingExp will be {1, 2}[<x, 1>] and result in [2] being added to
   the binding type and [3] to the component type such that the type mismatch is
   detected."
  input Expression bindingExp;
  input InstNode component;
  input output Type bindingType;
  input output Type componentType;
protected
  list<Dimension> dims;

  function isParent
    input InstNode parent;
    input InstNode node;
    output Boolean res;
  protected
    InstNode n = InstNode.getDerivedNode(node);
    InstNode p;
  algorithm
    res := match n
      case InstNode.COMPONENT_NODE(nodeType = InstNodeType.REDECLARED_COMP(parent = p))
        then InstNode.refEqual(parent, n) or isParent(parent, p);
      case InstNode.COMPONENT_NODE()
        then InstNode.refEqual(parent, n) or isParent(parent, n.parent);
      else false;
    end match;
  end isParent;

algorithm
  () := match bindingExp
    case Expression.SUBSCRIPTED_EXP()
      algorithm
        bindingType := Expression.typeOf(bindingExp.exp);

        dims := {};
        for s in bindingExp.subscripts loop
          dims := match s
            case Subscript.SPLIT_INDEX()
              algorithm
                if isParent(s.node, component) then
                  dims := Type.nthDimension(InstNode.getType(s.node), s.dimIndex) :: dims;
                end if;
              then
                dims;

            else Dimension.UNKNOWN() :: dims;
          end match;
        end for;

        dims := listReverseInPlace(dims);
        componentType := Type.liftArrayLeftList(componentType, dims);
      then
        ();

    else ();
  end match;
end elaborateBindingType;

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

    if not Config.getGraphicsExpMode() then // forget errors when handling annotations
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
          case Type.COMPLEX() guard checkSumComplexType(ty, exp, info) then "";
          else "Integer or Real, or operator record";
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
          else "scalar enumeration, Boolean, Integer, or Real";
        end match;

    case Absyn.Path.IDENT("max")
      then
        match ty
          case Type.INTEGER() then "";
          case Type.REAL() then "";
          case Type.BOOLEAN() then "";
          case Type.ENUMERATION() then "";
          else "scalar enumeration, Boolean, Integer, or Real";
        end match;

    else "";
  end match;

  if not stringEmpty(err) then
    Error.addSourceMessageAndFail(Error.INVALID_REDUCTION_TYPE,
      {Expression.toString(exp), Type.toString(ty), AbsynUtil.pathString(name), err}, info);
  end if;
end checkReductionType;

function checkSumComplexType
  input Type ty;
  input Expression exp;
  input SourceInfo info;
  output Boolean valid = true;
protected
  InstNode cls_node, op_node;
  Class cls;
algorithm
  Type.COMPLEX(cls = cls_node) := ty;
  cls := InstNode.getClass(cls_node);

  for op in {"'+'", "'0'"} loop
    if not Class.hasOperator(op, cls) then
      Error.addSourceMessage(Error.OPERATOR_RECORD_MISSING_OPERATOR,
        {Type.toString(ty), Expression.toString(exp), "sum", op}, info);
      valid := false;
    end if;
  end for;
end checkSumComplexType;

function matchIfBranches
  "Matches the types of the branches of an if-expression. The branches must have
   the same element type and number of dimensions, but might have different
   dimensions as long as the condition can be evaluated later to select one of
   the branches."
  input output Expression trueBranch;
  input Type trueType;
  input output Expression falseBranch;
  input Type falseType;
  input Boolean allowUnknown = false;
        output Type compatibleType;
        output MatchKind matchKind;
algorithm
  (compatibleType, matchKind) := match (trueType, falseType)
    local
      MatchKind mk1, mk2;
      Type cty1, cty2;

    case (Type.ARRAY(), Type.ARRAY())
      algorithm
        // Check that both branches have the same element type.
        (trueBranch, falseBranch, compatibleType, matchKind) :=
          matchExpressions(trueBranch, trueType.elementType,
                           falseBranch, falseType.elementType, allowUnknown);

        if isIncompatibleMatch(matchKind) then
          return;
        end if;

        // Check that both branches have the same dimensions.
        (compatibleType, matchKind) :=
          matchArrayDims(trueType.dimensions, falseType.dimensions,
                         compatibleType, matchKind, allowUnknown);

        if isIncompatibleMatch(matchKind) and
           listLength(trueType.dimensions) == listLength(falseType.dimensions) then
          // If the branches have the same element type and number of dimensions
          // but the dimensions aren't the same, create a conditional array type.
          compatibleType := Type.CONDITIONAL_ARRAY(Type.copyElementType(trueType, compatibleType),
                                                   Type.copyElementType(falseType, compatibleType),
                                                   NFType.Branch.NONE);
          matchKind := MatchKind.EXACT;
        end if;
      then
        (compatibleType, matchKind);

    case (_, _)
      guard Type.isConditionalArray(trueType) or Type.isConditionalArray(falseType)
      algorithm
        (trueBranch, falseBranch, compatibleType, matchKind) :=
          matchExpressions(trueBranch, Type.arrayElementType(trueType),
                           falseBranch, Type.arrayElementType(falseType), allowUnknown);

        if isIncompatibleMatch(matchKind) then
          return;
        end if;

        compatibleType := Type.CONDITIONAL_ARRAY(Type.copyElementType(trueType, compatibleType),
                                                 Type.copyElementType(falseType, compatibleType),
                                                 NFType.Branch.NONE);
      then
        (compatibleType, matchKind);

    else
      algorithm
        (trueBranch, falseBranch, compatibleType, matchKind) :=
          matchExpressions(trueBranch, trueType, falseBranch, falseType, allowUnknown);
      then
        (compatibleType, matchKind);

  end match;
end matchIfBranches;

annotation(__OpenModelica_Interface="frontend");
end NFTypeCheck;
