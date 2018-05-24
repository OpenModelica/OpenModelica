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

protected

import Dimension = NFDimension;
import ExpressionSimplify;
import Ceval = NFCeval;
import NFCeval.EvalTarget;
import NFFunction.Function;
import ComponentRef = NFComponentRef;

public

function simplify
  input output Expression exp;
algorithm
  exp := match exp
    case Expression.CREF()
      algorithm
        exp.cref := ComponentRef.simplifySubscripts(exp.cref);
      then
        exp;

    case Expression.ARRAY()
      algorithm
        exp.elements := list(simplify(e) for e in exp.elements);
      then
        exp;

    case Expression.RANGE()
      then Expression.RANGE(exp.ty, simplify(exp.start), simplifyOpt(exp.step), simplify(exp.stop));

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

function simplifyCall
  input output Expression callExp;
protected
  Call call;
  list<Expression> args;
  Boolean builtin;
algorithm
  Expression.CALL(call = call) := callExp;

  callExp := match call
    case Call.TYPED_CALL() guard not Call.isExternal(call)
      algorithm
        args := list(simplify(arg) for arg in call.arguments);
        call.arguments := args;
        builtin := Function.isBuiltin(call.fn);

        // Use Ceval for builtin pure functions with literal arguments.
        if builtin and not Function.isImpure(call.fn) and List.all(args, Expression.isLiteral) then
          callExp := Ceval.evalBuiltinCall(call.fn, args, EvalTarget.IGNORE_ERRORS());
        else
          callExp := Expression.CALL(call);
        end if;
      then
        callExp;

    case Call.TYPED_MAP_CALL()
      algorithm
        call.exp := simplify(call.exp);
        call.iters := list((Util.tuple21(i), simplify(Util.tuple22(i))) for i in call.iters);
      then
        Expression.CALL(call);

    else callExp;
  end match;
end simplifyCall;

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
          exp := Expression.ARRAY(Type.ARRAY(Type.INTEGER(), {Dimension.fromInteger(listLength(dims))}),
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

  if Expression.isLiteral(se1) and Expression.isLiteral(se2) then
    binaryExp := Ceval.evalBinaryOp(se1, op, se2);
  elseif not (referenceEq(e1, se1) and referenceEq(e2, se2)) then
    binaryExp := Expression.BINARY(se1, op, se2);
  end if;
end simplifyBinary;

function simplifyUnary
  input output Expression unaryExp;
protected
  Expression e, se;
  Operator op;
algorithm
  Expression.UNARY(op, e) := unaryExp;
  se := simplify(e);

  if Expression.isLiteral(se) then
    unaryExp := Ceval.evalUnaryOp(se, op);
  elseif not referenceEq(e, se) then
    unaryExp := Expression.UNARY(op, se);
  end if;
end simplifyUnary;

function simplifyLogicBinary
  input output Expression binaryExp;
protected
  Expression e1, e2, se1, se2;
  Operator op;
algorithm
  Expression.LBINARY(e1, op, e2) := binaryExp;
  se1 := simplify(e1);
  se2 := simplify(e2);

  if Expression.isLiteral(se1) and Expression.isLiteral(se2) then
    binaryExp := Ceval.evalLogicBinaryOp(se1, op, se2, EvalTarget.IGNORE_ERRORS());
  elseif not (referenceEq(e1, se1) and referenceEq(e2, se2)) then
    binaryExp := Expression.LBINARY(se1, op, se2);
  end if;
end simplifyLogicBinary;

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

    else Expression.IF(cond, simplify(tb), simplify(fb));
  end match;
end simplifyIf;

function simplifyCast
  input Expression exp;
  input Type ty;
  output Expression castExp;
algorithm
  castExp := match (ty, exp)
    case (Type.REAL(), Expression.INTEGER())
      then Expression.REAL(intReal(exp.value));

    case (Type.ARRAY(elementType = Type.REAL()), Expression.ARRAY())
      then Expression.mapArrayElements(exp, function simplifyCast(ty = Type.REAL()));

    else Expression.CAST(ty, exp);
  end match;
end simplifyCast;

function simplifySubscriptedExp
  input output Expression subscriptedExp;
protected
  Expression e;
  list<Expression> subs;
  Type ty;
algorithm
  Expression.SUBSCRIPTED_EXP(e, subs, ty) := subscriptedExp;
  subscriptedExp := simplify(e);

  for s in subs loop
    subscriptedExp := Expression.applyIndexSubscript(simplify(s), subscriptedExp);
  end for;
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

  tupleExp := match e
    case Expression.TUPLE() then listGet(e.elements, index);
    else Expression.TUPLE_ELEMENT(e, index, ty);
  end match;
end simplifyTupleElement;

annotation(__OpenModelica_Interface="frontend");
end NFSimplifyExp;
