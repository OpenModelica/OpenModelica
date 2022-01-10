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

encapsulated package NFSimplifyExp

import Expression = NFExpression;
import Operator = NFOperator;
import Type = NFType;
import Call = NFCall;
import Subscript = NFSubscript;
import NFOperator.Op;
import NFPrefixes.{Variability, Purity};
import NFInstNode.InstNode;

protected

import Dimension = NFDimension;
import Ceval = NFCeval;
import NFCeval.EvalTarget;
import NFFunction.Function;
import ComponentRef = NFComponentRef;
import ExpandExp = NFExpandExp;
import TypeCheck = NFTypeCheck;
import Absyn;
import AbsynUtil;
import ErrorExt;
import Flags;
import Debug;
import MetaModelica.Dangerous.listReverseInPlace;

public

function simplify
  input output Expression exp;
algorithm
  exp := match exp
    case Expression.CREF()
      algorithm
        exp.cref := ComponentRef.simplifySubscripts(exp.cref);
        exp.ty := ComponentRef.getSubscriptedType(exp.cref);
      then
        exp;

    case Expression.ARRAY()
      algorithm
        exp.elements := list(simplify(e) for e in exp.elements);
      then
        exp;

    case Expression.RANGE()
      then simplifyRange(exp);

    case Expression.RECORD()
      algorithm
        exp.elements := list(simplify(e) for e in exp.elements);
      then
        exp;

    case Expression.CALL() then simplifyCall(exp);
    case Expression.SIZE() then simplifySize(exp);
    case Expression.BINARY() then simplifyBinary(exp);
    case Expression.UNARY() then simplifyUnary(exp);
    case Expression.LBINARY() then simplifyLogicBinary(exp);
    case Expression.LUNARY() then simplifyLogicUnary(exp);
    case Expression.RELATION() then simplifyRelation(exp);
    case Expression.IF() then simplifyIf(exp);
    case Expression.CAST() then simplifyCast(simplify(exp.exp), exp.ty);
    case Expression.UNBOX() then Expression.UNBOX(simplify(exp.exp), exp.ty);
    case Expression.SUBSCRIPTED_EXP() then simplifySubscriptedExp(exp);
    case Expression.TUPLE_ELEMENT() then simplifyTupleElement(exp);
    case Expression.RECORD_ELEMENT() then simplifyRecordElement(exp);
    case Expression.BOX() then Expression.BOX(simplify(exp.exp));
    case Expression.MUTABLE() then simplify(Mutable.access(exp.exp));
    else exp;
  end match;
end simplify;

function simplifyOpt
  input output Option<Expression> exp;
protected
  Expression e;
algorithm
  exp := match exp
    case SOME(e) then SOME(simplify(e));
    else exp;
  end match;
end simplifyOpt;

function simplifyRange
  input Expression range;
  output Expression exp;
protected
  Expression start_exp1, stop_exp1, start_exp2, stop_exp2;
  Option<Expression> step_exp1, step_exp2;
  Type ty, ty2;
algorithm
  Expression.RANGE(ty = ty, start = start_exp1, step = step_exp1, stop = stop_exp1) := range;

  start_exp2 := simplify(start_exp1);
  step_exp2 := simplifyOpt(step_exp1);
  stop_exp2 := simplify(stop_exp1);
  ty2 := Type.simplify(ty);

  if referenceEq(start_exp1, start_exp2) and
     referenceEq(step_exp1, step_exp2) and
     referenceEq(stop_exp1, stop_exp2) and
     referenceEq(ty, ty2) then
    exp := range;
  else
    ty := TypeCheck.getRangeType(start_exp2, step_exp2, stop_exp2,
      Type.arrayElementType(ty), AbsynUtil.dummyInfo);
    exp := Expression.RANGE(ty, start_exp2, step_exp2, stop_exp2);
  end if;
end simplifyRange;

function simplifyCall
  input output Expression callExp;
protected
  Call call;
  list<Expression> args;
  Boolean builtin, is_pure;
algorithm
  Expression.CALL(call = call) := callExp;

  callExp := match call
    case Call.TYPED_CALL(arguments = args) guard not Call.isExternal(call)
      algorithm
        if Flags.isSet(Flags.NF_EXPAND_FUNC_ARGS) then
          args := list(if Expression.hasArrayCall(arg) then arg else ExpandExp.expand(arg) for arg in args);
        end if;

        args := list(simplify(arg) for arg in args);
        call.arguments := args;
        builtin := Function.isBuiltin(call.fn);
        is_pure := not Function.isImpure(call.fn);

        // Use Ceval for builtin pure functions with literal arguments.
        if builtin then
          if is_pure and List.all(args, Expression.isLiteral) then
            try
              callExp := Ceval.evalCall(call, EvalTarget.IGNORE_ERRORS());
            else
              callExp := Expression.CALL(call);
            end try;
          else
            // do not expand builtin calls if we should not scalarize
            if Flags.isSet(Flags.NF_SCALARIZE) then
              callExp := simplifyBuiltinCall(Function.nameConsiderBuiltin(call.fn), args, call);
            else
              callExp := Expression.CALL(call);
            end if;
          end if;
        elseif Flags.isSet(Flags.NF_EVAL_CONST_ARG_FUNCS) and is_pure and List.all(args, Expression.isLiteral) then
          callExp := simplifyCall2(call);
        else
          callExp := Expression.CALL(call);
        end if;
      then
        callExp;

    case Call.TYPED_CALL(arguments = args)
      algorithm
        args := list(simplify(arg) for arg in args);
        call.arguments := args;
      then
        Expression.CALL(call);

    case Call.TYPED_ARRAY_CONSTRUCTOR() then simplifyArrayConstructor(call);
    case Call.TYPED_REDUCTION() then simplifyReduction(call);
    else callExp;
  end match;
end simplifyCall;

function simplifyCall2
  input Call call;
  output Expression outExp;
algorithm
  ErrorExt.setCheckpoint(getInstanceName());

  try
    outExp := Ceval.evalCall(call, EvalTarget.IGNORE_ERRORS());
    ErrorExt.delCheckpoint(getInstanceName());
  else
    if Flags.isSet(Flags.FAILTRACE) then
      ErrorExt.delCheckpoint(getInstanceName());
      Debug.traceln("- " + getInstanceName() + " failed to evaluate " + Call.toString(call) + "\n");
    else
      ErrorExt.rollBack(getInstanceName());
    end if;

    outExp := Expression.CALL(call);
  end try;
end simplifyCall2;

function simplifyBuiltinCall
  input Absyn.Path name;
  input list<Expression> args;
  input Call call;
  output Expression exp;
algorithm
  exp := match AbsynUtil.pathFirstIdent(name)
    case "cat"
      algorithm
        exp := ExpandExp.expandBuiltinCat(args, call);
      then
        exp;

    case "fill"      then simplifyFill(listHead(args), listRest(args), call);
    case "homotopy"  then simplifyHomotopy(args, call);
    case "max"       guard listLength(args) == 1 then simplifyReducedArrayConstructor(listHead(args), call);
    case "min"       guard listLength(args) == 1 then simplifyReducedArrayConstructor(listHead(args), call);
    case "ones"      then simplifyFill(Expression.INTEGER(1), args, call);
    case "product"   then simplifySumProduct(listHead(args), call, isSum = false);
    case "sum"       then simplifySumProduct(listHead(args), call, isSum = true);
    case "transpose" then simplifyTranspose(listHead(args), call);
    case "vector"    then simplifyVector(listHead(args), call);
    case "zeros"     then simplifyFill(Expression.INTEGER(0), args, call);

    else Expression.CALL(call);
  end match;
end simplifyBuiltinCall;

function simplifySumProduct
  input Expression arg;
  input Call call;
  input Boolean isSum;
  output Expression exp;
protected
  Boolean expanded;
  list<Expression> args;
  Type ty;
  Operator op;
algorithm
  (exp, expanded) := ExpandExp.expand(arg);

  if expanded then
    args := Expression.arrayScalarElements(exp);
    ty := Type.arrayElementType(Expression.typeOf(arg));

    if listEmpty(args) then
      exp := if isSum then Expression.makeZero(ty) else Expression.makeOne(ty);
    else
      exp :: args := args;
      op := if isSum then Operator.makeAdd(ty) else
                          Operator.makeMul(ty);

      for e in args loop
        exp := Expression.BINARY(exp, op, e);
      end for;
    end if;
  else
    exp := simplifyReducedArrayConstructor(exp, call);
  end if;
end simplifySumProduct;

function simplifyReducedArrayConstructor
  input Expression arg;
  input Call call;
  output Expression exp;
algorithm
  exp := match arg
    local
      Call arr_call;
      Function fn;
      Type ty;
      Variability var;
      Purity purity;

    case Expression.CALL(call = arr_call as Call.TYPED_ARRAY_CONSTRUCTOR())
      guard Type.dimensionCount(arr_call.ty) == 1
      algorithm
        Call.TYPED_CALL(fn = fn, ty = ty, var = var, purity = purity) := call;
      then
        Expression.CALL(Call.makeTypedReduction(fn, ty, var, purity, arr_call.exp, arr_call.iters, AbsynUtil.dummyInfo));

    else Expression.CALL(call);
  end match;
end simplifyReducedArrayConstructor;

function simplifyTranspose
  input Expression arg;
  input Call call;
  output Expression exp;
protected
  Expression e;
algorithm
  e := if Expression.hasArrayCall(arg) then arg else ExpandExp.expand(arg);

  exp := match e
    case Expression.ARRAY()
      guard List.all(e.elements, Expression.isArray)
      then Expression.transposeArray(e);

    else Expression.CALL(call);
  end match;
end simplifyTranspose;

function simplifyVector
  input Expression arg;
  input Call call;
  output Expression exp;
protected
  list<Expression> expl;
  Boolean is_literal;
  Type ty;
algorithm
  expl := Expression.arrayScalarElements(arg);
  is_literal := Expression.isLiteral(arg);

  if is_literal then
    // Ranges count as literals, make sure they're expanded.
    expl := ExpandExp.expandList(expl);
  end if;

  if is_literal or List.all(expl, Expression.isScalar) then
    ty := Type.arrayElementType(Expression.typeOf(arg));
    exp := Expression.makeExpArray(expl, ty);
  else
    exp := Expression.CALL(call);
  end if;
end simplifyVector;

function simplifyFill
  input Expression fillArg;
  input list<Expression> dimArgs;
  input Call call;
  output Expression exp;
algorithm
  if List.all(dimArgs, Expression.isLiteral) then
    exp := Expression.fillArgs(fillArg, dimArgs);
  else
    exp := Expression.CALL(call);
  end if;
end simplifyFill;

function simplifyHomotopy
  input list<Expression> args;
  input Call call;
  output Expression exp;
algorithm
  exp := match Flags.getConfigString(Flags.REPLACE_HOMOTOPY)
    case "actual" then listHead(args);
    case "simplified" then listHead(listRest(args));
    else Expression.CALL(call);
  end match;
end simplifyHomotopy;

function simplifyArrayConstructor
  input Call call;
  output Expression outExp;
protected
  Type ty;
  Variability var;
  Purity pur;
  Expression exp, e;
  list<tuple<InstNode, Expression>> iters;
  InstNode iter;
  Dimension dim;
  Integer dim_size;
  Boolean expanded;
algorithm
  Call.TYPED_ARRAY_CONSTRUCTOR(ty, var, pur, exp, iters) := call;
  iters := list((Util.tuple21(i), simplify(Util.tuple22(i))) for i in iters);

  outExp := matchcontinue (iters)
    case {(iter, e)}
      algorithm
        Type.ARRAY(dimensions = {dim}) := Expression.typeOf(e);
        dim_size := Dimension.size(dim);

        if dim_size == 0 then
          // Result is Array[0], return empty array expression.
          outExp := Expression.makeEmptyArray(ty);
        elseif dim_size == 1 then
          // Result is Array[1], return array with the single element.
          (Expression.ARRAY(elements = {e}), _) := ExpandExp.expand(e);
          exp := Expression.replaceIterator(exp, iter, e);
          exp := Expression.makeArray(ty, {exp});
          outExp := simplify(exp);
        elseif Expression.isLiteral(e) and not Expression.hasNonArrayIteratorSubscript(exp, iter) then
          // If the iterator is only used to subscript array expressions like
          // {{1, 2, 3}[i] in i 1:3}, then we might as well expand it.
          (outExp, expanded) := ExpandExp.expandArrayConstructor(exp, ty, iters);

          if expanded then
            outExp := simplify(outExp);
          end if;
        else
          fail();
        end if;
      then
        outExp;

    else
      algorithm
        exp := simplify(exp);
        ty := Type.simplify(ty);
      then
        Expression.CALL(Call.TYPED_ARRAY_CONSTRUCTOR(ty, var, pur, exp, iters));
  end matchcontinue;
end simplifyArrayConstructor;

function simplifyReduction
  input Call call;
  output Expression outExp;
algorithm
  outExp := match call
    local
      Expression exp, e;
      list<tuple<InstNode, Expression>> iters;
      InstNode iter;
      Dimension dim;
      Integer dim_size;

    case Call.TYPED_REDUCTION()
      algorithm
        iters := list((Util.tuple21(i), simplify(Util.tuple22(i))) for i in call.iters);
      then matchcontinue iters
        case {(iter, e)}
          algorithm
            Type.ARRAY(dimensions = {dim}) := Expression.typeOf(e);
            dim_size := Dimension.size(dim);

            if dim_size == 0 then
              // Iteration range is empty, return default value for reduction.
              SOME(outExp) := call.defaultExp;
            elseif dim_size == 1 then
              // Iteration range is one, return reduction expression with iterator value applied.
              (Expression.ARRAY(elements = {e}), _) := ExpandExp.expand(e);
              outExp := Expression.replaceIterator(call.exp, iter, e);
              outExp := simplify(outExp);
            else
              fail();
            end if;
          then
            outExp;

        case _
          guard call.var <= Variability.STRUCTURAL_PARAMETER
          then Ceval.tryEvalExp(Expression.CALL(call));

        case _
          then simplifyReduction2(AbsynUtil.pathString(Function.name(call.fn)), call.exp, iters);

        else
          algorithm
            call.exp := simplify(call.exp);
            call.iters := iters;
          then
            Expression.CALL(call);

      end matchcontinue;
  end match;
end simplifyReduction;

function simplifyReduction2
  input String name;
  input Expression exp;
  input list<tuple<InstNode, Expression>> iterators;
  output Expression outExp;
protected
  InstNode iter;
  Expression range, default_exp;
  Boolean expanded = true;
  list<tuple<InstNode, Expression>> iters = {};
  Type ty;
  Operator op;
algorithm
  ty := Expression.typeOf(exp);
  // Operator records are problematic since the start value isn't simplified
  // away currently.
  false := Type.isRecord(Type.arrayElementType(ty));

  (default_exp, op) := match name
    case "sum" then (Expression.makeZero(ty), Operator.makeAdd(ty));
    case "product" then (Expression.makeOne(ty), Operator.makeMul(ty));
  end match;

  for i in iterators loop
    (iter, range) := i;
    (range, true) := ExpandExp.expand(range);
    iters := (iter, range) :: iters;
  end for;

  outExp := Expression.foldReduction(simplify(exp), listReverseInPlace(iters),
    default_exp, simplify, function simplifyBinaryOp(op = op));
end simplifyReduction2;

function simplifySize
  input output Expression sizeExp;
algorithm
  sizeExp := match sizeExp
    local
      Expression exp, index;
      Dimension dim;
      list<Dimension> dims;

    case Expression.SIZE(exp, SOME(index))
      algorithm
        index := simplify(index);

        if Expression.isLiteral(index) then
          dim := listGet(Type.arrayDims(Expression.typeOf(exp)), Expression.toInteger(index));

          if Dimension.isKnown(dim) then
            exp := Expression.INTEGER(Dimension.size(dim));
          else
            exp := Expression.SIZE(exp, SOME(index));
          end if;
        else
          exp := Expression.SIZE(exp, SOME(index));
        end if;
      then
        exp;

    case Expression.SIZE()
      algorithm
        dims := Type.arrayDims(Expression.typeOf(sizeExp.exp));

        if List.all(dims, function Dimension.isKnown(allowExp = true)) then
          exp := Expression.makeArray(Type.ARRAY(Type.INTEGER(), {Dimension.fromInteger(listLength(dims))}),
                                      list(Dimension.sizeExp(d) for d in dims));
        else
          exp := sizeExp;
        end if;
      then
        exp;

  end match;
end simplifySize;

function simplifyBinary
  input output Expression binaryExp;
protected
  Expression e1, e2, se1, se2;
  Operator op;
algorithm
  Expression.BINARY(e1, op, e2) := binaryExp;
  se1 := simplify(e1);
  se2 := simplify(e2);

  binaryExp := simplifyBinaryOp(se1, op, se2);

  if Flags.isSet(Flags.NF_EXPAND_OPERATIONS) and not Expression.hasArrayCall(binaryExp) then
    binaryExp := ExpandExp.expand(binaryExp);
  end if;
end simplifyBinary;

function simplifyBinaryOp
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  output Expression outExp;

  import NFOperator.Op;
algorithm
  if Expression.isLiteral(exp1) and Expression.isLiteral(exp2) then
    outExp := Ceval.evalBinaryOp(ExpandExp.expand(exp1), op, ExpandExp.expand(exp2));
  else
    outExp := match op.op
      case Op.ADD then simplifyBinaryAdd(exp1, op, exp2);
      case Op.SUB then simplifyBinarySub(exp1, op, exp2);
      case Op.MUL then simplifyBinaryMul(exp1, op, exp2);
      case Op.DIV then simplifyBinaryDiv(exp1, op, exp2);
      case Op.POW then simplifyBinaryPow(exp1, op, exp2);
      else Expression.BINARY(exp1, op, exp2);
    end match;
  end if;
end simplifyBinaryOp;

function simplifyBinaryAdd
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  output Expression outExp;
algorithm
  if Expression.isZero(exp1) then
    // 0 + e = e
    outExp := exp2;
  elseif Expression.isZero(exp2) then
    // e + 0 = e
    outExp := exp1;
  elseif Expression.isNegated(exp2) then
    // e1 + -(e2) = e1 - e2
    outExp := Expression.BINARY(exp1, Operator.negate(op), Expression.negate(exp2));
  else
    outExp := Expression.BINARY(exp1, op, exp2);
  end if;
end simplifyBinaryAdd;

function simplifyBinarySub
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  output Expression outExp;
algorithm
  if Expression.isZero(exp1) then
    // 0 - e = -e
    outExp := Expression.UNARY(Operator.makeUMinus(Operator.typeOf(op)), exp2);
  elseif Expression.isZero(exp2) then
    // e - 0 = e
    outExp := exp1;
  elseif Expression.isNegated(exp2) then
    // e1 - -(e2) = e1 + e2
    outExp := Expression.BINARY(exp1, Operator.negate(op), Expression.negate(exp2));
  else
    outExp := Expression.BINARY(exp1, op, exp2);
  end if;
end simplifyBinarySub;

function simplifyBinaryMul
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  input Boolean switched = false;
  output Expression outExp;
algorithm
  outExp := match exp1
    // 0 * e = 0
    case Expression.INTEGER(value = 0) then exp1;
    case Expression.REAL(value = 0.0) then exp1;

    // 1 * e = e
    case Expression.INTEGER(value = 1) then exp2;
    case Expression.REAL(value = 1.0) then exp2;

    else
      if switched then
        Expression.BINARY(exp2, op, exp1)
      else
        simplifyBinaryMul(exp2, op, exp1, true);
  end match;
end simplifyBinaryMul;

function simplifyBinaryDiv
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  output Expression outExp;
algorithm
  // e / 1 = e
  if Expression.isOne(exp2) then
    outExp := exp1;
  else
    outExp := Expression.BINARY(exp1, op, exp2);
  end if;
end simplifyBinaryDiv;

function simplifyBinaryPow
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  output Expression outExp;
algorithm
  if Expression.isZero(exp2) then
    outExp := Expression.makeOne(Operator.typeOf(op));
  elseif Expression.isOne(exp2) then
    outExp := exp1;
  else
    outExp := Expression.BINARY(exp1, op, exp2);
  end if;
end simplifyBinaryPow;

function simplifyUnary
  input output Expression unaryExp;
protected
  Expression e, se;
  Operator op;
algorithm
  Expression.UNARY(op, e) := unaryExp;
  se := simplify(e);

  unaryExp := simplifyUnaryOp(se, op);

  if Flags.isSet(Flags.NF_EXPAND_OPERATIONS) and not Expression.hasArrayCall(unaryExp) then
    unaryExp := ExpandExp.expand(unaryExp);
  end if;
end simplifyUnary;

function simplifyUnaryOp
  input Expression exp;
  input Operator op;
  output Expression outExp;
algorithm
  if Expression.isLiteral(exp) then
    outExp := Ceval.evalUnaryOp(exp, op);
  else
    outExp := Expression.UNARY(op, exp);
  end if;
end simplifyUnaryOp;

function simplifyLogicBinary
  input output Expression binaryExp;
protected
  Expression e1, e2, se1, se2;
  Operator op;
algorithm
  Expression.LBINARY(e1, op, e2) := binaryExp;
  se1 := simplify(e1);
  se2 := simplify(e2);

  binaryExp := match op.op
    case Op.AND then simplifyLogicBinaryAnd(se1, op, se2);
    case Op.OR then simplifyLogicBinaryOr(se1, op, se2);
  end match;
end simplifyLogicBinary;

function simplifyLogicBinaryAnd
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  output Expression exp;
algorithm
  exp := match (exp1, exp2)
    local
      list<Expression> expl;
      Operator o;

    // false and e => false
    case (Expression.BOOLEAN(false), _) then exp1;
    // e and false => false
    case (_, Expression.BOOLEAN(false)) then exp2;
    // true and e => e
    case (Expression.BOOLEAN(true), _)  then exp2;
    // e and true => e
    case (_, Expression.BOOLEAN(true))  then exp1;

    case (Expression.ARRAY(), Expression.ARRAY())
      algorithm
        o := Operator.unlift(op);
        expl := list(simplifyLogicBinaryAnd(e1, o, e2)
                     threaded for e1 in exp1.elements, e2 in exp2.elements);
      then
        Expression.makeArray(Operator.typeOf(op), expl);

    else Expression.LBINARY(exp1, op, exp2);
  end match;
end simplifyLogicBinaryAnd;

function simplifyLogicBinaryOr
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  output Expression exp;
algorithm
  exp := match (exp1, exp2)
    local
      list<Expression> expl;
      Operator o;

    // true or e => true
    case (Expression.BOOLEAN(true), _) then exp1;
    // e or true => true
    case (_, Expression.BOOLEAN(true)) then exp2;
    // false or e => e
    case (Expression.BOOLEAN(false), _) then exp2;
    // e or false => e
    case (_, Expression.BOOLEAN(false)) then exp1;

    case (Expression.ARRAY(), Expression.ARRAY())
      algorithm
        o := Operator.unlift(op);
        expl := list(simplifyLogicBinaryAnd(e1, o, e2)
                     threaded for e1 in exp1.elements, e2 in exp2.elements);
      then
        Expression.makeArray(Operator.typeOf(op), expl);

    else Expression.LBINARY(exp1, op, exp2);
  end match;
end simplifyLogicBinaryOr;

function simplifyLogicUnary
  input output Expression unaryExp;
protected
  Expression e, se;
  Operator op;
algorithm
  Expression.LUNARY(op, e) := unaryExp;
  se := simplify(e);

  if Expression.isLiteral(se) then
    unaryExp := Ceval.evalLogicUnaryOp(se, op);
  elseif not referenceEq(e, se) then
    unaryExp := Expression.LUNARY(op, se);
  end if;
end simplifyLogicUnary;

function simplifyRelation
  input output Expression relationExp;
protected
  Expression e1, e2, se1, se2;
  Operator op;
algorithm
  Expression.RELATION(e1, op, e2) := relationExp;
  se1 := simplify(e1);
  se2 := simplify(e2);

  if Expression.isLiteral(se1) and Expression.isLiteral(se2) then
    relationExp := Ceval.evalRelationOp(se1, op, se2);
  elseif not (referenceEq(e1, se1) and referenceEq(e2, se2)) then
    relationExp := Expression.RELATION(se1, op, se2);
  end if;
end simplifyRelation;

function simplifyIf
  input output Expression ifExp;
protected
  Type ty;
  Expression cond, tb, fb;
  Boolean tb_val;
algorithm
  Expression.IF(ty, cond, tb, fb) := ifExp;
  cond := simplify(cond);

  ifExp := match cond
    case Expression.BOOLEAN()
      then simplify(if cond.value then tb else fb);

    else
      algorithm
        tb := simplify(tb);
        fb := simplify(fb);

        if Expression.isEqual(tb, fb) then
          // if cond then x else x => x
          ifExp := tb;
        elseif Expression.isBoolean(tb) and Expression.isBoolean(fb) then
          // if cond then true else false => cond
          // if cond then false else true => not cond
          Expression.BOOLEAN(value = tb_val) := tb;
          ifExp := if tb_val then cond else Expression.logicNegate(cond);
        else
          ifExp := Expression.IF(ty, cond, tb, fb);
        end if;
      then
        ifExp;

  end match;
end simplifyIf;

function simplifyCast
  input Expression exp;
  input Type ty;
  output Expression castExp;
algorithm
  castExp := match (ty, exp)
    local
      Type ety;

    case (Type.REAL(), Expression.INTEGER())
      then Expression.REAL(intReal(exp.value));

    case (Type.ARRAY(elementType = Type.REAL()), Expression.ARRAY())
      algorithm
        ety := Type.unliftArray(ty);
        exp.elements := list(simplifyCast(e, ety) for e in exp.elements);
        exp.ty := Type.setArrayElementType(exp.ty, Type.arrayElementType(ty));
      then
        exp;

    else Expression.CAST(ty, exp);
  end match;
end simplifyCast;

function simplifySubscriptedExp
  input output Expression subscriptedExp;
protected
  Expression e;
  list<Subscript> subs;
  Type ty;
  Boolean split;
algorithm
  Expression.SUBSCRIPTED_EXP(e, subs, ty, split) := subscriptedExp;
  subscriptedExp := simplify(e);
  subs := Subscript.simplifyList(subs, Type.arrayDims(Expression.typeOf(e)));

  if split then
    subscriptedExp := Expression.SUBSCRIPTED_EXP(subscriptedExp, subs, ty, split);
  else
    subscriptedExp := Expression.applySubscripts(subs, subscriptedExp);
  end if;
end simplifySubscriptedExp;

function simplifyTupleElement
  input output Expression tupleExp;
protected
  Expression e;
  Integer index;
  Type ty;
algorithm
  Expression.TUPLE_ELEMENT(e, index, ty) := tupleExp;
  e := simplify(e);
  tupleExp := Expression.tupleElement(e, ty, index);
end simplifyTupleElement;

function simplifyRecordElement
  input output Expression exp;
protected
  Expression e, e2;
  Integer idx;
  Type ty;
algorithm
  Expression.RECORD_ELEMENT(e, idx, _, ty) := exp;
  e2 := simplify(e);

  if not referenceEq(e, e2) then
    exp := Expression.nthRecordElement(idx, e2);
  end if;
end simplifyRecordElement;

annotation(__OpenModelica_Interface="frontend");
end NFSimplifyExp;
