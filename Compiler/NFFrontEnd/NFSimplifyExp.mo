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
import NFCall.Call;
import Subscript = NFSubscript;
import NFOperator.Op;
import NFPrefixes.Variability;
import NFInstNode.InstNode;

protected

import Dimension = NFDimension;
import ExpressionSimplify;
import Ceval = NFCeval;
import NFCeval.EvalTarget;
import NFFunction.Function;
import ComponentRef = NFComponentRef;
import ExpandExp = NFExpandExp;
import TypeCheck = NFTypeCheck;
import Absyn;
import ErrorExt;
import Flags;
import Debug;

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
  Type ty;
algorithm
  Expression.RANGE(ty = ty, start = start_exp1, step = step_exp1, stop = stop_exp1) := range;

  start_exp2 := simplify(start_exp1);
  step_exp2 := simplifyOpt(step_exp1);
  stop_exp2 := simplify(stop_exp1);

  if referenceEq(start_exp1, start_exp2) and
     referenceEq(step_exp1, step_exp2) and
     referenceEq(stop_exp1, stop_exp2) then
    exp := range;
  else
    ty := TypeCheck.getRangeType(start_exp2, step_exp2, stop_exp2,
      Type.arrayElementType(ty), Absyn.dummyInfo);
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
            callExp := Ceval.evalCall(call, EvalTarget.IGNORE_ERRORS());
          else
            // do not expand builtin calls if we should not scalarize
            if Flags.isSet(Flags.NF_SCALARIZE) then
              callExp := simplifyBuiltinCall(Function.nameConsiderBuiltin(call.fn), args, call);
            else
              // nothing
            end if;
          end if;
        elseif Flags.isSet(Flags.NF_EVAL_CONST_ARG_FUNCS) and is_pure and List.all(args, Expression.isLiteral) then
          callExp := simplifyCall2(call);
        else
          callExp := Expression.CALL(call);
        end if;
      then
        callExp;

    case Call.TYPED_ARRAY_CONSTRUCTOR() then simplifyArrayConstructor(call);

    case Call.TYPED_REDUCTION()
      algorithm
        call.exp := simplify(call.exp);
        call.iters := list((Util.tuple21(i), simplify(Util.tuple22(i))) for i in call.iters);
      then
        Expression.CALL(call);

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
  exp := match Absyn.pathFirstIdent(name)
    case "cat"
      algorithm
        exp := ExpandExp.expandBuiltinCat(args, call);
      then
        exp;

    case "sum"     then   simplifySumProduct(listHead(args), call, isSum = true);
    case "product" then   simplifySumProduct(listHead(args), call, isSum = false);
    case "transpose" then simplifyTranspose(listHead(args), call);

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
    exp := Expression.CALL(call);
  end if;
end simplifySumProduct;

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

function simplifyArrayConstructor
  input Call call;
  output Expression outExp;
protected
  Type ty;
  Variability var;
  Expression exp, e;
  list<tuple<InstNode, Expression>> iters;
  InstNode iter;
  Dimension dim;
  Integer dim_size;
  Boolean expanded;
algorithm
  Call.TYPED_ARRAY_CONSTRUCTOR(ty, var, exp, iters) := call;
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
        else
          fail();
        end if;
      then
        outExp;

    else
      algorithm
        exp := simplify(exp);
      then
        Expression.CALL(Call.TYPED_ARRAY_CONSTRUCTOR(ty, var, exp, iters));
  end matchcontinue;
end simplifyArrayConstructor;

function simplifySize
  input output Expression sizeExp;
algorithm
  sizeExp := match sizeExp
    local
      Expression exp, index;
      Dimension dim;
      list<Dimension> dims;

    case Expression.SIZE(exp, dimIndex = SOME(index))
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
    outExp := Ceval.evalBinaryOp(exp1, op, exp2);
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
  Expression cond, tb, fb;
algorithm
  Expression.IF(cond, tb, fb) := ifExp;
  cond := simplify(cond);

  ifExp := match cond
    case Expression.BOOLEAN()
      then simplify(if cond.value then tb else fb);

    else
      algorithm
        tb := simplify(tb);
        fb := simplify(fb);
      then
        if Expression.isEqual(tb, fb) then tb else Expression.IF(cond, tb, fb);

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
algorithm
  Expression.SUBSCRIPTED_EXP(e, subs, ty) := subscriptedExp;
  subscriptedExp := simplify(e);
  subscriptedExp := Expression.applySubscripts(list(Subscript.simplify(s) for s in subs), subscriptedExp);
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

annotation(__OpenModelica_Interface="frontend");
end NFSimplifyExp;
