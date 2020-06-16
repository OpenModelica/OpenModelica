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

encapsulated package NFCeval

import Binding = NFBinding;
import ComponentRef = NFComponentRef;
import Error;
import Component = NFComponent;
import Expression = NFExpression;
import NFInstNode.InstNode;
import Operator = NFOperator;
import NFOperator.Op;
import Typing = NFTyping;
import Call = NFCall;
import Dimension = NFDimension;
import Type = NFType;
import NFTyping.ExpOrigin;
import ExpressionSimplify;
import NFPrefixes.Variability;
import NFClassTree.ClassTree;
import ComplexType = NFComplexType;
import Subscript = NFSubscript;
import NFTyping.TypingError;
import DAE;
import Record = NFRecord;

protected
import NFFunction.Function;
import EvalFunction = NFEvalFunction;
import List;
import System;
import ExpressionIterator = NFExpressionIterator;
import MetaModelica.Dangerous.*;
import Class = NFClass;
import TypeCheck = NFTypeCheck;
import ExpandExp = NFExpandExp;
import ElementSource;
import Flags;

public
uniontype EvalTarget
  record DIMENSION
    InstNode component;
    Integer index;
    Expression exp;
    SourceInfo info;
  end DIMENSION;

  record ATTRIBUTE
    Binding binding;
  end ATTRIBUTE;

  record RANGE
    SourceInfo info;
  end RANGE;

  record CONDITION
    SourceInfo info;
  end CONDITION;

  record GENERIC
    SourceInfo info;
  end GENERIC;

  record STATEMENT
    DAE.ElementSource source;
  end STATEMENT;

  record IGNORE_ERRORS end IGNORE_ERRORS;

  function isRange
    input EvalTarget target;
    output Boolean isRange;
  algorithm
    isRange := match target
      case RANGE() then true;
      else false;
    end match;
  end isRange;

  function hasInfo
    input EvalTarget target;
    output Boolean hasInfo;
  algorithm
    hasInfo := match target
      case DIMENSION() then true;
      case ATTRIBUTE() then true;
      case RANGE() then true;
      case CONDITION() then true;
      case GENERIC() then true;
      case STATEMENT() then true;
      else false;
    end match;
  end hasInfo;

  function getInfo
    input EvalTarget target;
    output SourceInfo info;
  algorithm
    info := match target
      case DIMENSION() then target.info;
      case ATTRIBUTE() then Binding.getInfo(target.binding);
      case RANGE() then target.info;
      case CONDITION() then target.info;
      case GENERIC() then target.info;
      case STATEMENT() then ElementSource.getInfo(target.source);
      else AbsynUtil.dummyInfo;
    end match;
  end getInfo;
end EvalTarget;

function evalExp
  input output Expression exp;
  input EvalTarget target = EvalTarget.IGNORE_ERRORS();
algorithm
  exp := Expression.getBindingExp(evalExp_impl(exp, target));
end evalExp;

function evalExpBinding
  input output Expression exp;
  input EvalTarget target = EvalTarget.IGNORE_ERRORS();
algorithm
  exp := evalExp_impl(exp, target);
end evalExpBinding;

function evalExp_impl
  input output Expression exp;
  input EvalTarget target;
algorithm
  exp := match exp
    local
      InstNode c;
      Binding binding;
      Expression exp1, exp2, exp3;
      list<Expression> expl = {};
      Call call;
      Component comp;
      Option<Expression> oexp;
      ComponentRef cref;
      Dimension dim;

    case Expression.CREF()
      then evalCref(exp.cref, exp, target);

    case Expression.TYPENAME()
      then evalTypename(exp.ty, exp, target);

    case Expression.ARRAY()
      then if exp.literal then exp
           else
             Expression.makeArray(exp.ty,
               list(evalExp_impl(e, target) for e in exp.elements),
               literal = true);

    case Expression.RANGE() then evalRange(exp, target);

    case Expression.TUPLE()
      algorithm
        exp.elements := list(evalExp_impl(e, target) for e in exp.elements);
      then
        exp;

    case Expression.RECORD()
      algorithm
        exp.elements := list(evalExp_impl(e, target) for e in exp.elements);
      then
        exp;

    case Expression.CALL()
      then evalCall(exp.call, target);

    case Expression.SIZE()
      then evalSize(exp.exp, exp.dimIndex, target);

    case Expression.BINARY()
      algorithm
        exp1 := evalExp_impl(exp.exp1, target);
        exp2 := evalExp_impl(exp.exp2, target);
      then
        evalBinaryOp(exp1, exp.operator, exp2, target);

    case Expression.UNARY()
      algorithm
        exp1 := evalExp_impl(exp.exp, target);
      then
        evalUnaryOp(exp1, exp.operator);

    case Expression.LBINARY()
      algorithm
        exp1 := evalExp_impl(exp.exp1, target);
      then
        evalLogicBinaryOp(exp1, exp.operator, exp.exp2, target);

    case Expression.LUNARY()
      algorithm
        exp1 := evalExp_impl(exp.exp, target);
      then
        evalLogicUnaryOp(exp1, exp.operator);

    case Expression.RELATION()
      algorithm
        exp1 := evalExp_impl(exp.exp1, target);
        exp2 := evalExp_impl(exp.exp2, target);
      then
        evalRelationOp(exp1, exp.operator, exp2);

    case Expression.IF() then evalIfExp(exp, target);

    case Expression.CAST()
      algorithm
        exp1 := evalExp_impl(exp.exp, target);
      then
        evalCast(exp1, exp.ty);

    case Expression.UNBOX()
      algorithm
        exp1 := evalExp_impl(exp.exp, target);
      then Expression.UNBOX(exp1, exp.ty);

    case Expression.SUBSCRIPTED_EXP()
      then evalSubscriptedExp(exp.exp, exp.subscripts, target);

    case Expression.TUPLE_ELEMENT()
      algorithm
        exp1 := evalExp_impl(exp.tupleExp, target);
      then
        Expression.tupleElement(exp1, exp.ty, exp.index);

    case Expression.RECORD_ELEMENT()
      then evalRecordElement(exp, target);

    case Expression.MUTABLE()
      algorithm
        exp1 := evalExp_impl(Mutable.access(exp.exp), target);
      then
        exp1;

    case Expression.BINDING_EXP()
      algorithm
        exp.exp := evalExp_impl(exp.exp, target);
      then
        exp;

    else exp;
  end match;
end evalExp_impl;

function evalExpOpt
  input output Option<Expression> oexp;
  input EvalTarget target = EvalTarget.IGNORE_ERRORS();
algorithm
  oexp := match oexp
    local
      Expression e;

    case SOME(e) then SOME(evalExp_impl(e, target));
    else oexp;
  end match;
end evalExpOpt;

function evalExpPartial
  "Evaluates the parts of an expression that are possible to evaluate. This
   means leaving parts of the expression that contains e.g. iterators or mutable
   expressions. This can be used to optimize an expression that is expected to
   be evaluated many times, for example the expression in an array constructor."
  input Expression exp;
  input EvalTarget target = EvalTarget.IGNORE_ERRORS();
  input Boolean evaluated = true;
  output Expression outExp;
  output Boolean outEvaluated "True if the whole expression is evaluated, otherwise false.";
protected
  Expression e, e1, e2;
  Boolean eval1, eval2;
algorithm
  (e, outEvaluated) :=
    Expression.mapFoldShallow(exp, function evalExpPartial(target = target), true);

  outExp := match e
    case Expression.CREF()
      algorithm
        if ComponentRef.isIterator(e.cref) then
          // Don't evaluate iterators.
          outExp := e;
          outEvaluated := false;
        else
          // Crefs can be evaluated even if they have non-evaluated subscripts.
          outExp := evalCref(e.cref, e, target, evalSubscripts = false);
        end if;
      then
        outExp;

    // Don't evaluate mutable expressions. While they could technically be
    // evaluated they're usually used as mutable iterators.
    case Expression.MUTABLE()
      algorithm
        outEvaluated := false;
      then
        e;

    else if outEvaluated then evalExp(e, target) else e;
  end match;

  outEvaluated := evaluated and outEvaluated;
end evalExpPartial;

function evalCref
  input ComponentRef cref;
  input Expression defaultExp;
  input EvalTarget target;
  input Boolean evalSubscripts = true;
  output Expression exp;
protected
  InstNode c;
  Boolean evaled;
  list<Subscript> subs;
algorithm
  exp := match cref
    case ComponentRef.CREF(node = c as InstNode.COMPONENT_NODE())
      guard not ComponentRef.isIterator(cref)
      then evalComponentBinding(c, cref, defaultExp, target, evalSubscripts);

    else defaultExp;
  end match;
end evalCref;

function evalComponentBinding
  input InstNode node;
  input ComponentRef cref;
  input Expression defaultExp "The expression returned if the binding couldn't be evaluated";
  input EvalTarget target;
  input Boolean evalSubscripts = true;
  output Expression exp;
protected
  ExpOrigin.Type exp_origin;
  Component comp;
  Binding binding;
  Boolean evaluated;
  list<Subscript> subs;
  Variability var;
  Option<Expression> start_exp;
algorithm
  exp_origin := if InstNode.isFunction(InstNode.explicitParent(node))
    then ExpOrigin.FUNCTION else ExpOrigin.CLASS;

  Typing.typeComponentBinding(node, exp_origin, typeChildren = false);
  comp := InstNode.component(node);
  binding := Component.getBinding(comp);

  if Binding.isUnbound(binding) then
    // In some cases we need to construct a binding for the node, for example when
    // a record has bindings on the fields but not on the record instance as a whole.
    binding := makeComponentBinding(comp, node, Expression.toCref(defaultExp), target);

    if Binding.isUnbound(binding) then
      // If we couldn't construct a binding, try to use the start value instead.
      start_exp := evalComponentStartBinding(node, comp, cref, target, evalSubscripts);

      if isSome(start_exp) then
        // The component had a valid start value. The value has already been
        // evaluated by evalComponentStartBinding, so skip the rest of the function.
        SOME(exp) := start_exp;
        return;
      end if;
    end if;
  end if;

  (exp, evaluated) := match binding
    case Binding.TYPED_BINDING()
      algorithm
        if binding.evaluated then
          exp := binding.bindingExp;
        else
          exp := evalExp_impl(binding.bindingExp, target);

          binding.bindingExp := exp;
          binding.evaluated := true;
          comp := Component.setBinding(binding, comp);
          InstNode.updateComponent(comp, node);
        end if;
      then
        (exp, true);

    case Binding.CEVAL_BINDING() then (binding.bindingExp, true);

    case Binding.UNBOUND()
      algorithm
        printUnboundError(comp, target, defaultExp);
      then
        (defaultExp, false);

    else
      algorithm
        Error.addInternalError(getInstanceName() + " failed on untyped binding", sourceInfo());
      then
        fail();

  end match;

  // Apply subscripts from the cref to the binding expression as needed.
  if evaluated then
    exp := subscriptEvaluatedBinding(exp, cref, evalSubscripts);
  end if;
end evalComponentBinding;

function flattenBindingExp
  input Expression exp;
  output Expression outExp;
algorithm
  outExp := match exp
    case Expression.BINDING_EXP(exp = Expression.BINDING_EXP())
      then flattenBindingExp(exp.exp);

    else exp;
  end match;
end flattenBindingExp;

function subscriptEvaluatedBinding
  "Takes subscripts from the given component reference and applies them to an
   evaluated expression."
  input output Expression exp;
  input ComponentRef cref;
  input Boolean evalSubscripts;
protected
  list<Subscript> subs;
  ComponentRef cr;
algorithm
  // The subscripts of the first part of the cref are always applied.
  subs := ComponentRef.getSubscripts(cref);
  cr := ComponentRef.stripSubscripts(cref);

  if evalSubscripts then
    subs := list(Subscript.eval(s) for s in subs);
  end if;

  // The rest of the cref contributes subscripts based on where the expressions
  // comes from in the instance tree.
  exp := subscriptEvaluatedBinding2(exp, cr, evalSubscripts, subs, subs);
end subscriptEvaluatedBinding;

function subscriptEvaluatedBinding2
  input output Expression exp;
  input ComponentRef cref;
  input Boolean evalSubscripts;
  input list<Subscript> subscripts = {};
  input list<Subscript> bindingSubs = {};
algorithm
  exp := match exp
    local
      Expression e;
      Type exp_ty, bind_ty;
      list<InstNode> parents;
      list<Subscript> accum_subs, subs;
      ComponentRef cr;
      InstNode cr_node;

    case Expression.BINDING_EXP(bindingType = bind_ty, parents = parents)
      algorithm
        if exp.isEach then
          parents := {listHead(parents)};
        end if;

        cr := cref;
        accum_subs := subscripts;
        subs := {};

        if not ComponentRef.isEmpty(cr) then
          cr_node := ComponentRef.node(cr);

          // Remove binding parents until we find one referring to the first
          // cref node, or we run out of parents.
          while not (listEmpty(parents) or InstNode.refEqual(listHead(parents), cr_node)) loop
            parents := listRest(parents);
          end while;

          // Collect subscripts from the part of the cref corresponding to the
          // remaining parents.
          while not listEmpty(parents) loop
            if not InstNode.refEqual(listHead(parents), cr_node) then
              break;
            end if;

            subs := listAppend(ComponentRef.getSubscripts(cr), subs);

            parents := listRest(parents);
            cr := ComponentRef.rest(cr);

            if ComponentRef.isEmpty(cr) then
              break;
            end if;

            cr_node := ComponentRef.node(cr);
          end while;

          if evalSubscripts then
            subs := list(Subscript.eval(s) for s in subs);
          end if;

          accum_subs := listAppend(subs, accum_subs);
        end if;

        // Subscript the binding type if bindingSubs was given.
        if not listEmpty(bindingSubs) then
          subs := bindingSubs;
          bind_ty := Type.subscript(bind_ty, subs);
        end if;

        e := subscriptEvaluatedBinding2(exp.exp, cr, evalSubscripts, accum_subs, subs);
        exp_ty := Expression.typeOf(e);
      then
        Expression.BINDING_EXP(e, exp_ty, bind_ty, exp.parents, exp.isEach);

    else Expression.applySubscripts(subscripts, exp);
  end match;
end subscriptEvaluatedBinding2;

function evalComponentStartBinding
  "Tries to evaluate the given component's start value. NONE() is returned if
   the component isn't a fixed parameter or if it doesn't have a start value.
   Otherwise the evaluated binding expression is returned if it could be
   evaluated, or the function will fail if it couldn't be."
  input InstNode node;
  input Component comp;
  input ComponentRef cref;
  input EvalTarget target;
  input Boolean evalSubscripts;
  output Option<Expression> outExp = NONE();
protected
  Variability var;
  InstNode start_node;
  Component start_comp;
  Binding binding;
  Expression exp;
  list<Subscript> subs;
  Integer pcount;
algorithm
  // Only use the start value if the component is a fixed parameter.
  var := Component.variability(comp);
  if (var <> Variability.PARAMETER and var <> Variability.STRUCTURAL_PARAMETER) or
     not Component.getFixedAttribute(comp) then
    return;
  end if;

  // Look up "start" in the class.
  try
    start_node := Class.lookupElement("start", InstNode.getClass(node));
  else
    return;
  end try;

  // Make sure we have an actual start attribute, and didn't just find some
  // other element named start in the class.
  start_comp := InstNode.component(start_node);
  if not Component.isTypeAttribute(start_comp) then
    return;
  end if;

  // Try to evaluate the binding if one exists.
  binding := Component.getBinding(start_comp);

  outExp := match binding
    case Binding.TYPED_BINDING()
      algorithm
        exp := evalExp_impl(binding.bindingExp, target);

        if not referenceEq(exp, binding.bindingExp) then
          binding.bindingExp := exp;
          start_comp := Component.setBinding(binding, start_comp);
          InstNode.updateComponent(start_comp, start_node);
        end if;
      then
        SOME(exp);

    else outExp;
  end match;
end evalComponentStartBinding;

function makeComponentBinding
  input Component component;
  input InstNode node;
  input ComponentRef cref;
  input EvalTarget target;
  output Binding binding;
protected
  ClassTree tree;
  array<InstNode> comps;
  list<Expression> fields;
  Type ty, exp_ty;
  InstNode rec_node;
  Expression exp;
  ComponentRef rest_cr;
algorithm
  binding := matchcontinue (component, cref)
    // A record field without an explicit binding, evaluate the parent's binding
    // if it has one and fetch the binding from it instead.
    case (_, _)
      algorithm
        exp := makeRecordFieldBindingFromParent(cref, target);
      then
        Binding.CEVAL_BINDING(exp);

    // A record component without an explicit binding, create one from its children.
    case (Component.TYPED_COMPONENT(ty = Type.COMPLEX(complexTy = ComplexType.RECORD(rec_node))), _)
      algorithm
        exp := makeRecordBindingExp(component.classInst, rec_node, component.ty, cref);
        exp_ty := Expression.typeOf(exp);
        exp := Expression.BINDING_EXP(exp, exp_ty, exp_ty, {node}, true);
        binding := Binding.CEVAL_BINDING(exp);

        if not ComponentRef.hasSubscripts(cref) then
          InstNode.updateComponent(Component.setBinding(binding, component), node);
        end if;
      then
        binding;

    // A record array component without an explicit binding, create one from its children.
    case (Component.TYPED_COMPONENT(ty = ty as Type.ARRAY(elementType =
            Type.COMPLEX(complexTy = ComplexType.RECORD(rec_node)))), _)
      algorithm
        exp := makeRecordBindingExp(component.classInst, rec_node, component.ty, cref);
        exp := splitRecordArrayExp(exp);
        exp_ty := Expression.typeOf(exp);
        exp := Expression.BINDING_EXP(exp, exp_ty, exp_ty, {node}, true);
        binding := Binding.CEVAL_BINDING(exp);

        if not ComponentRef.hasSubscripts(cref) then
          InstNode.updateComponent(Component.setBinding(binding, component), node);
        end if;
      then
        binding;

    else NFBinding.EMPTY_BINDING;
  end matchcontinue;
end makeComponentBinding;

function makeRecordFieldBindingFromParent
  input ComponentRef cref;
  input EvalTarget target;
  output Expression exp;
protected
  ComponentRef parent_cr;
  Type parent_ty;
algorithm
  parent_cr := ComponentRef.rest(cref);
  parent_ty := ComponentRef.nodeType(parent_cr);
  true := Type.isRecord(Type.arrayElementType(parent_ty));

  try
    // Pass an EMPTY expression here as the default expression instead of the
    // cref. Otherwise evalCref might attempt to make a binding for the parent
    // from its children, which would create an evaluation loop.
    exp := evalCref(parent_cr, Expression.EMPTY(parent_ty), target);
  else
    // If the parent didn't have a binding, try the parent's parent.
    exp := makeRecordFieldBindingFromParent(parent_cr, target);
  end try;

  exp := Expression.recordElement(ComponentRef.firstName(cref), exp);
end makeRecordFieldBindingFromParent;

function makeRecordBindingExp
  input InstNode typeNode;
  input InstNode recordNode;
  input Type recordType;
  input ComponentRef cref;
  output Expression exp;
protected
  ClassTree tree;
  array<InstNode> comps;
  list<Expression> args;
  list<Record.Field> fields;
  Type ty;
  InstNode c;
  ComponentRef cr;
  Expression arg;
algorithm
  tree := Class.classTree(InstNode.getClass(typeNode));
  comps := ClassTree.getComponents(tree);
  args := {};

  for i in arrayLength(comps):-1:1 loop
    c := comps[i];
    ty := InstNode.getType(c);
    cr := ComponentRef.CREF(c, {}, ty, NFComponentRef.Origin.CREF, cref);
    arg := Expression.CREF(ty, cr);

    if Component.variability(InstNode.component(c)) <= Variability.PARAMETER then
      arg := evalExp_impl(arg, EvalTarget.IGNORE_ERRORS());
    end if;

    args := arg :: args;
  end for;

  exp := Expression.makeRecord(InstNode.scopePath(recordNode), recordType, args);
end makeRecordBindingExp;

function splitRecordArrayExp
  input output Expression exp;
protected
  Absyn.Path path;
  Type ty;
  list<Expression> expl;
algorithm
  Expression.RECORD(path, ty, expl) := exp;
  exp := Expression.makeRecord(path, Type.arrayElementType(ty), expl);
  exp := Expression.fillType(ty, exp);
end splitRecordArrayExp;

function evalTypename
  input Type ty;
  input Expression originExp;
  input EvalTarget target;
  output Expression exp;
algorithm
  // Only expand the typename into an array if it's used as a range, and keep
  // them as typenames when used as e.g. dimensions.
  exp := if EvalTarget.isRange(target) then ExpandExp.expandTypename(ty) else originExp;
end evalTypename;

function evalRange
  input Expression rangeExp;
  input EvalTarget target;
  output Expression result;
protected
  Type ty;
  Expression start_exp, stop_exp;
  Option<Expression> step_exp;
  Expression max_prop_exp;
  Integer max_prop_count;
algorithm
  Expression.RANGE(ty = ty, start = start_exp, step = step_exp, stop = stop_exp) := rangeExp;
  start_exp := evalExp_impl(start_exp, target);
  step_exp := evalExpOpt(step_exp, target);
  stop_exp := evalExp_impl(stop_exp, target);

  start_exp := Expression.getScalarBindingExp(start_exp);
  step_exp := Util.applyOption(step_exp, Expression.getScalarBindingExp);
  stop_exp := Expression.getScalarBindingExp(stop_exp);

  if EvalTarget.isRange(target) then
    ty := TypeCheck.getRangeType(start_exp, step_exp, stop_exp,
      Type.arrayElementType(ty), EvalTarget.getInfo(target));
    result := Expression.RANGE(ty, start_exp, step_exp, stop_exp);
  else
    result := Expression.RANGE(ty, start_exp, step_exp, stop_exp);
    result := Expression.bindingExpMap(result, evalRangeExp);
  end if;
end evalRange;

function evalRangeExp
  input Expression rangeExp;
  output Expression exp;
protected
  Expression start, step, stop;
  Option<Expression> opt_step;
  list<Expression> expl;
  Type ty;
  list<String> literals;
  Integer istep;
algorithm
  Expression.RANGE(start = start, step = opt_step, stop = stop) := rangeExp;

  if isSome(opt_step) then
    SOME(step) := opt_step;

    (ty, expl) := match (start, step, stop)
      case (Expression.INTEGER(), Expression.INTEGER(istep), Expression.INTEGER())
        algorithm
          // The compiler decided to randomly dislike using step.value here, hence istep.
          expl := list(Expression.INTEGER(i) for i in start.value:istep:stop.value);
        then
          (Type.INTEGER(), expl);

      case (Expression.REAL(), Expression.REAL(), Expression.REAL())
        algorithm
          expl := evalRangeReal(start.value, step.value, stop.value);
        then
          (Type.REAL(), expl);

      else
        algorithm
          printWrongArgsError(getInstanceName(), {start, step, stop}, sourceInfo());
        then
          fail();
    end match;
  else
    (ty, expl) := match (start, stop)
      case (Expression.INTEGER(), Expression.INTEGER())
        algorithm
          expl := list(Expression.INTEGER(i) for i in start.value:stop.value);
        then
          (Type.INTEGER(), expl);

      case (Expression.REAL(), Expression.REAL())
        algorithm
          expl := evalRangeReal(start.value, 1.0, stop.value);
        then
          (Type.REAL(), expl);

      case (Expression.BOOLEAN(), Expression.BOOLEAN())
        algorithm
          expl := list(Expression.BOOLEAN(b) for b in start.value:stop.value);
        then
          (Type.BOOLEAN(), expl);

      case (Expression.ENUM_LITERAL(ty = ty as Type.ENUMERATION()), Expression.ENUM_LITERAL())
        algorithm
          expl := list(Expression.ENUM_LITERAL(ty, listGet(ty.literals, i), i) for i in start.index:stop.index);
        then
          (ty, expl);

      else
        algorithm
          printWrongArgsError(getInstanceName(), {start, stop}, sourceInfo());
        then
          fail();
    end match;
  end if;

  exp := Expression.makeArray(Type.ARRAY(ty, {Dimension.fromInteger(listLength(expl))}),
                              expl, literal = true);
end evalRangeExp;

function evalRangeReal
  input Real start;
  input Real step;
  input Real stop;
  output list<Expression> result;
protected
  Integer steps;
algorithm
  steps := Util.realRangeSize(start, step, stop);

  // Real ranges are tricky, make sure that start and stop are reproduced
  // exactly if they are part of the range.
  if steps == 0 then
    result := {};
  elseif steps == 1 then
    result := {Expression.REAL(start)};
  else
    result := {Expression.REAL(stop)};
    for i in steps-2:-1:1 loop
      result := Expression.REAL(start + i * step) :: result;
    end for;
    result := Expression.REAL(start) :: result;
  end if;
end evalRangeReal;

function printFailedEvalError
  input String name;
  input Expression exp;
  input SourceInfo info;
algorithm
  Error.addInternalError(name + " failed to evaluate ‘" + Expression.toString(exp) + "‘", info);
end printFailedEvalError;

function evalBinaryOp
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  input EvalTarget target = EvalTarget.IGNORE_ERRORS();
  output Expression exp;
protected
  Expression max_prop_exp;
  Integer max_prop_count;
algorithm
  (max_prop_exp, max_prop_count) := Expression.mostPropagatedSubExpBinary(exp1, exp2);

  if max_prop_count >= 0 then
    exp := Expression.bindingExpMap2(Expression.BINARY(exp1, op, exp2),
      function evalBinaryExp(target = target), max_prop_count, max_prop_exp);
  else
    exp := evalBinaryOp_dispatch(exp1, op, exp2, target);
  end if;
end evalBinaryOp;

function evalBinaryExp
  input Expression binaryExp;
  input EvalTarget target;
  output Expression result;
protected
  Expression e1, e2;
  Operator op;
algorithm
  Expression.BINARY(exp1 = e1, operator = op, exp2 = e2) := binaryExp;
  result := evalBinaryOp_dispatch(e1, op, e2, target);
end evalBinaryExp;

function evalBinaryOp_dispatch
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  input EvalTarget target = EvalTarget.IGNORE_ERRORS();
  output Expression exp;
algorithm
  exp := match op.op
    case Op.ADD then evalBinaryAdd(exp1, exp2);
    case Op.SUB then evalBinarySub(exp1, exp2);
    case Op.MUL then evalBinaryMul(exp1, exp2);
    case Op.DIV then evalBinaryDiv(exp1, exp2, target);
    case Op.POW then evalBinaryPow(exp1, exp2);
    case Op.ADD_SCALAR_ARRAY then evalBinaryScalarArray(exp1, exp2, evalBinaryAdd);
    case Op.ADD_ARRAY_SCALAR then evalBinaryArrayScalar(exp1, exp2, evalBinaryAdd);
    case Op.SUB_SCALAR_ARRAY then evalBinaryScalarArray(exp1, exp2, evalBinarySub);
    case Op.SUB_ARRAY_SCALAR then evalBinaryArrayScalar(exp1, exp2, evalBinarySub);
    case Op.MUL_SCALAR_ARRAY then evalBinaryScalarArray(exp1, exp2, evalBinaryMul);
    case Op.MUL_ARRAY_SCALAR then evalBinaryArrayScalar(exp1, exp2, evalBinaryMul);
    case Op.MUL_VECTOR_MATRIX then evalBinaryMulVectorMatrix(exp1, exp2);
    case Op.MUL_MATRIX_VECTOR then evalBinaryMulMatrixVector(exp1, exp2);
    case Op.SCALAR_PRODUCT then evalBinaryScalarProduct(exp1, exp2);
    case Op.MATRIX_PRODUCT then evalBinaryMatrixProduct(exp1, exp2);
    case Op.DIV_SCALAR_ARRAY
      then evalBinaryScalarArray(exp1, exp2, function evalBinaryDiv(target = target));
    case Op.DIV_ARRAY_SCALAR
      then evalBinaryArrayScalar(exp1, exp2, function evalBinaryDiv(target = target));
    case Op.POW_SCALAR_ARRAY then evalBinaryScalarArray(exp1, exp2, evalBinaryPow);
    case Op.POW_ARRAY_SCALAR then evalBinaryArrayScalar(exp1, exp2, evalBinaryPow);
    case Op.POW_MATRIX then evalBinaryPowMatrix(exp1, exp2);
    else
      algorithm
        Error.addInternalError(getInstanceName() + ": unimplemented case for " +
          Expression.toString(Expression.BINARY(exp1, op, exp2)), sourceInfo());
      then
        fail();
  end match;
end evalBinaryOp_dispatch;

function evalBinaryAdd
  input Expression exp1;
  input Expression exp2;
  output Expression exp;
algorithm
  exp := match (exp1, exp2)
    case (Expression.INTEGER(), Expression.INTEGER())
      then Expression.INTEGER(exp1.value + exp2.value);

    case (Expression.REAL(), Expression.REAL())
      then Expression.REAL(exp1.value + exp2.value);

    case (Expression.STRING(), Expression.STRING())
      then Expression.STRING(exp1.value + exp2.value);

    case (Expression.ARRAY(), Expression.ARRAY())
      guard listLength(exp1.elements) == listLength(exp2.elements)
      then Expression.makeArray(exp1.ty,
        list(evalBinaryAdd(e1, e2) threaded for e1 in exp1.elements, e2 in exp2.elements),
        literal = true);

    else
      algorithm
        exp := Expression.BINARY(exp1, Operator.makeAdd(Type.UNKNOWN()), exp2);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();
  end match;
end evalBinaryAdd;

function evalBinarySub
  input Expression exp1;
  input Expression exp2;
  output Expression exp;
algorithm
  exp := match (exp1, exp2)
    case (Expression.INTEGER(), Expression.INTEGER())
      then Expression.INTEGER(exp1.value - exp2.value);

    case (Expression.REAL(), Expression.REAL())
      then Expression.REAL(exp1.value - exp2.value);

    case (Expression.ARRAY(), Expression.ARRAY())
      guard listLength(exp1.elements) == listLength(exp2.elements)
      then Expression.makeArray(exp1.ty,
        list(evalBinarySub(e1, e2) threaded for e1 in exp1.elements, e2 in exp2.elements),
        literal = true);

    else
      algorithm
        exp := Expression.BINARY(exp1, Operator.makeSub(Type.UNKNOWN()), exp2);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();
  end match;
end evalBinarySub;

function evalBinaryMul
  input Expression exp1;
  input Expression exp2;
  output Expression exp;
algorithm
  exp := match (exp1, exp2)
    case (Expression.INTEGER(), Expression.INTEGER())
      then Expression.INTEGER(exp1.value * exp2.value);

    case (Expression.REAL(), Expression.REAL())
      then Expression.REAL(exp1.value * exp2.value);

    case (Expression.ARRAY(), Expression.ARRAY())
      guard listLength(exp1.elements) == listLength(exp2.elements)
      then Expression.makeArray(exp1.ty,
        list(evalBinaryMul(e1, e2) threaded for e1 in exp1.elements, e2 in exp2.elements),
        literal = true);

    else
      algorithm
        exp := Expression.BINARY(exp1, Operator.makeMul(Type.UNKNOWN()), exp2);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();
  end match;
end evalBinaryMul;

function evalBinaryDiv
  input Expression exp1;
  input Expression exp2;
  input EvalTarget target;
  output Expression exp;
algorithm
  exp := match (exp1, exp2)
    case (_, Expression.REAL(0.0))
      algorithm
        if EvalTarget.hasInfo(target) then
          Error.addSourceMessage(Error.DIVISION_BY_ZERO,
            {Expression.toString(exp1), Expression.toString(exp2)}, EvalTarget.getInfo(target));
          fail();
        else
          exp := Expression.BINARY(exp1, Operator.makeDiv(Type.REAL()), exp2);
        end if;
      then
        exp;

    case (Expression.REAL(), Expression.REAL())
      then Expression.REAL(exp1.value / exp2.value);

    case (Expression.ARRAY(), Expression.ARRAY())
      guard listLength(exp1.elements) == listLength(exp2.elements)
      then Expression.makeArray(exp1.ty,
        list(evalBinaryDiv(e1, e2, target) threaded for e1 in exp1.elements, e2 in exp2.elements),
        literal = true);

    else
      algorithm
        exp := Expression.BINARY(exp1, Operator.makeDiv(Type.UNKNOWN()), exp2);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();
  end match;
end evalBinaryDiv;

function evalBinaryPow
  input Expression exp1;
  input Expression exp2;
  output Expression exp;
algorithm
  exp := match (exp1, exp2)
    case (Expression.REAL(), Expression.REAL())
      then Expression.REAL(exp1.value ^ exp2.value);

    case (Expression.ARRAY(), Expression.ARRAY())
      guard listLength(exp1.elements) == listLength(exp2.elements)
      then Expression.makeArray(exp1.ty,
        list(evalBinaryPow(e1, e2) threaded for e1 in exp1.elements, e2 in exp2.elements),
        literal = true);

    else
      algorithm
        exp := Expression.BINARY(exp1, Operator.makePow(Type.UNKNOWN()), exp2);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();
  end match;
end evalBinaryPow;

function evalBinaryScalarArray
  input Expression scalarExp;
  input Expression arrayExp;
  input FuncT opFunc;
  output Expression exp;

  partial function FuncT
    input Expression exp1;
    input Expression exp2;
    output Expression exp;
  end FuncT;
algorithm
  exp := match arrayExp
    case Expression.ARRAY()
      then Expression.makeArray(arrayExp.ty,
        list(evalBinaryScalarArray(scalarExp, e, opFunc) for e in arrayExp.elements),
        literal = true);

    else opFunc(scalarExp, arrayExp);
  end match;
end evalBinaryScalarArray;

function evalBinaryArrayScalar
  input Expression arrayExp;
  input Expression scalarExp;
  input FuncT opFunc;
  output Expression exp;

  partial function FuncT
    input Expression exp1;
    input Expression exp2;
    output Expression exp;
  end FuncT;
algorithm
  exp := match arrayExp
    case Expression.ARRAY()
      then Expression.ARRAY(arrayExp.ty,
        list(evalBinaryArrayScalar(e, scalarExp, opFunc) for e in arrayExp.elements),
        literal = true);

    else opFunc(arrayExp, scalarExp);
  end match;
end evalBinaryArrayScalar;

function evalBinaryMulVectorMatrix
  input Expression vectorExp;
  input Expression matrixExp;
  output Expression exp;
protected
  list<Expression> expl;
  Dimension m;
  Type ty;
algorithm
  exp := match Expression.transposeArray(matrixExp)
    case Expression.ARRAY(Type.ARRAY(ty, {m, _}), expl)
      algorithm
        expl := list(evalBinaryScalarProduct(vectorExp, e) for e in expl);
      then
        Expression.makeArray(Type.ARRAY(ty, {m}), expl, literal = true);

    else
      algorithm
        exp := Expression.BINARY(vectorExp, Operator.makeMul(Type.UNKNOWN()), matrixExp);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();

  end match;
end evalBinaryMulVectorMatrix;

function evalBinaryMulMatrixVector
  input Expression matrixExp;
  input Expression vectorExp;
  output Expression exp;
protected
  list<Expression> expl;
  Dimension n;
  Type ty;
algorithm
  exp := match matrixExp
    case Expression.ARRAY(Type.ARRAY(ty, {n, _}), expl)
      algorithm
        expl := list(evalBinaryScalarProduct(e, vectorExp) for e in expl);
      then
        Expression.makeArray(Type.ARRAY(ty, {n}), expl, literal = true);

    else
      algorithm
        exp := Expression.BINARY(matrixExp, Operator.makeMul(Type.UNKNOWN()), vectorExp);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();

  end match;
end evalBinaryMulMatrixVector;

function evalBinaryScalarProduct
  input Expression exp1;
  input Expression exp2;
  output Expression exp;
algorithm
  exp := match (exp1, exp2)
    local
      Type elem_ty;
      Expression e2;
      list<Expression> rest_e2;

    case (Expression.ARRAY(ty = Type.ARRAY(elem_ty)), Expression.ARRAY())
      guard listLength(exp1.elements) == listLength(exp2.elements)
      algorithm
        exp := Expression.makeZero(elem_ty);
        rest_e2 := exp2.elements;

        for e1 in exp1.elements loop
          e2 :: rest_e2 := rest_e2;
          exp := evalBinaryAdd(exp, evalBinaryMul(e1, e2));
        end for;
      then
        exp;

    else
      algorithm
        exp := Expression.BINARY(exp1, Operator.makeMul(Type.UNKNOWN()), exp2);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();

  end match;
end evalBinaryScalarProduct;

function evalBinaryMatrixProduct
  input Expression exp1;
  input Expression exp2;
  output Expression exp;
protected
  Expression e2;
  list<Expression> expl1, expl2;
  Type elem_ty, row_ty, mat_ty;
  Dimension n, p;
algorithm
  e2 := Expression.transposeArray(exp2);

  exp := match (exp1, e2)
    case (Expression.ARRAY(Type.ARRAY(elem_ty, {n, _}), expl1),
          Expression.ARRAY(Type.ARRAY(_, {p, _}), expl2))
      algorithm
        mat_ty := Type.ARRAY(elem_ty, {n, p});

        if listEmpty(expl2) then
          exp := Expression.makeZero(mat_ty);
        else
          row_ty := Type.ARRAY(elem_ty, {p});
          expl1 := list(Expression.makeArray(row_ty,
            list(evalBinaryScalarProduct(r, c) for c in expl2), literal = true) for r in expl1);
          exp := Expression.makeArray(mat_ty, expl1, literal = true);
        end if;
      then
        exp;

    else
      algorithm
        exp := Expression.BINARY(exp1, Operator.makeMul(Type.UNKNOWN()), exp2);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();

  end match;
end evalBinaryMatrixProduct;

function evalBinaryPowMatrix
  input Expression matrixExp;
  input Expression nExp;
  output Expression exp;
protected
  Integer n;
algorithm
  exp := match (matrixExp, nExp)
    case (Expression.ARRAY(), Expression.INTEGER(value = 0))
      algorithm
        n := Dimension.size(listHead(Type.arrayDims(matrixExp.ty)));
      then
        Expression.makeIdentityMatrix(n, Type.REAL());

    case (_, Expression.INTEGER(value = n))
      then evalBinaryPowMatrix2(matrixExp, n);

    else
      algorithm
        exp := Expression.BINARY(matrixExp, Operator.makePow(Type.UNKNOWN()), nExp);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();

  end match;
end evalBinaryPowMatrix;

function evalBinaryPowMatrix2
  input Expression matrix;
  input Integer n;
  output Expression exp;
algorithm
  exp := match n
    // A^1 = A
    case 1 then matrix;

    // A^2 = A * A
    case 2 then evalBinaryMatrixProduct(matrix, matrix);

    // A^n = A^m * A^m where n = 2*m
    case _ guard intMod(n, 2) == 0
      algorithm
        exp := evalBinaryPowMatrix2(matrix, intDiv(n, 2));
      then
        evalBinaryMatrixProduct(exp, exp);

    // A^n = A * A^(n-1)
    else
      algorithm
        exp := evalBinaryPowMatrix2(matrix, n - 1);
      then
        evalBinaryMatrixProduct(matrix, exp);

  end match;
end evalBinaryPowMatrix2;

function evalUnaryOp
  input Expression exp1;
  input Operator op;
  output Expression exp;
algorithm
  exp := match op.op
    case Op.UMINUS then Expression.bindingExpMap(exp1, evalUnaryMinus);
    else
      algorithm
        Error.addInternalError(getInstanceName() + ": unimplemented case for " +
          Expression.toString(Expression.UNARY(op, exp1)), sourceInfo());
      then
        fail();
  end match;
end evalUnaryOp;

function evalUnaryMinus
  input Expression exp1;
  output Expression exp;
algorithm
  exp := match exp1
    case Expression.INTEGER() then Expression.INTEGER(-exp1.value);
    case Expression.REAL() then Expression.REAL(-exp1.value);
    case Expression.ARRAY()
      algorithm
        exp1.elements := list(evalUnaryMinus(e) for e in exp1.elements);
      then
        exp1;

    else
      algorithm
        exp := Expression.UNARY(Operator.makeUMinus(Type.UNKNOWN()), exp1);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();
  end match;
end evalUnaryMinus;

function evalLogicBinaryOp
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  input EvalTarget target = EvalTarget.IGNORE_ERRORS();
  output Expression exp;
protected
  Expression e1;
  Expression max_prop_exp;
  Integer max_prop_count;
algorithm
  (max_prop_exp, max_prop_count) := Expression.mostPropagatedSubExpBinary(exp1, exp2);

  if max_prop_count >= 0 then
    exp := Expression.bindingExpMap2(Expression.LBINARY(exp1, op, exp2),
      function evalLogicBinaryExp(target = target), max_prop_count, max_prop_exp);
  else
    exp := evalLogicBinaryOp_dispatch(exp1, op, exp2, target);
  end if;
end evalLogicBinaryOp;

function evalLogicBinaryExp
  input Expression binaryExp;
  input EvalTarget target;
  output Expression result;
protected
  Expression e1, e2;
  Operator op;
algorithm
  Expression.LBINARY(exp1 = e1, operator = op, exp2 = e2) := binaryExp;
  result := evalLogicBinaryOp_dispatch(e1, op, e2, target);
end evalLogicBinaryExp;

function evalLogicBinaryOp_dispatch
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  input EvalTarget target;
  output Expression exp;
algorithm
  exp := match op.op
    case Op.AND then evalLogicBinaryAnd(evalExp(exp1, target), exp2, target);
    case Op.OR then evalLogicBinaryOr(evalExp(exp1, target), exp2, target);
    else
      algorithm
        Error.addInternalError(getInstanceName() + ": unimplemented case for " +
          Expression.toString(Expression.LBINARY(exp1, op, exp2)), sourceInfo());
      then
        fail();
  end match;
end evalLogicBinaryOp_dispatch;

function evalLogicBinaryAnd
  input Expression exp1;
  input Expression exp2;
  input EvalTarget target;
  output Expression exp;
algorithm
  exp := matchcontinue exp1
    local
      list<Expression> expl;

    case Expression.BOOLEAN()
      then if exp1.value then evalExp_impl(exp2, target) else exp1;

    case Expression.ARRAY()
      algorithm
        Expression.ARRAY(elements = expl) := evalExp_impl(exp2, target);
        expl := list(evalLogicBinaryAnd(e1, e2, target)
                     threaded for e1 in exp1.elements, e2 in expl);
      then
        Expression.makeArray(Type.setArrayElementType(exp1.ty, Type.BOOLEAN()), expl, literal = true);

    else
      algorithm
        exp := Expression.LBINARY(exp1, Operator.makeAnd(Type.UNKNOWN()), exp2);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();
  end matchcontinue;
end evalLogicBinaryAnd;

function evalLogicBinaryOr
  input Expression exp1;
  input Expression exp2;
  input EvalTarget target;
  output Expression exp;
algorithm
  exp := match exp1
    local
      list<Expression> expl;

    case Expression.BOOLEAN()
      then if exp1.value then exp1 else evalExp_impl(exp2, target);

    case Expression.ARRAY()
      algorithm
        Expression.ARRAY(elements = expl) := evalExp_impl(exp2, target);
        expl := list(evalLogicBinaryOr(e1, e2, target)
                     threaded for e1 in exp1.elements, e2 in expl);
      then
        Expression.makeArray(Type.setArrayElementType(exp1.ty, Type.BOOLEAN()), expl, literal = true);

    else
      algorithm
        exp := Expression.LBINARY(exp1, Operator.makeOr(Type.UNKNOWN()), exp2);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();
  end match;
end evalLogicBinaryOr;

function evalLogicUnaryOp
  input Expression exp1;
  input Operator op;
  output Expression exp;
algorithm
  exp := match op.op
    case Op.NOT then Expression.bindingExpMap(exp1, evalLogicUnaryNot);
    else
      algorithm
        Error.addInternalError(getInstanceName() + ": unimplemented case for " +
          Expression.toString(Expression.LUNARY(op, exp1)), sourceInfo());
      then
        fail();
  end match;
end evalLogicUnaryOp;

function evalLogicUnaryNot
  input Expression exp1;
  output Expression exp;
algorithm
  exp := match exp1
    case Expression.BOOLEAN() then Expression.BOOLEAN(not exp1.value);
    case Expression.ARRAY() then Expression.mapArrayElements(exp1, evalLogicUnaryNot);

    else
      algorithm
        exp := Expression.LUNARY(Operator.makeNot(Type.UNKNOWN()), exp1);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();
  end match;
end evalLogicUnaryNot;

function evalRelationOp
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  output Expression exp;
protected
  Expression max_prop_exp;
  Integer max_prop_count;
algorithm
  (max_prop_exp, max_prop_count) := Expression.mostPropagatedSubExpBinary(exp1, exp2);

  if max_prop_count >= 0 then
    exp := Expression.bindingExpMap2(Expression.RELATION(exp1, op, exp2),
      evalRelationExp, max_prop_count, max_prop_exp);
  else
    exp := evalRelationOp_dispatch(exp1, op, exp2);
  end if;
end evalRelationOp;

function evalRelationExp
  input Expression relationExp;
  output Expression result;
protected
  Expression e1, e2;
  Operator op;
algorithm
  Expression.RELATION(exp1 = e1, operator = op, exp2 = e2) := relationExp;
  result := evalRelationOp_dispatch(e1, op, e2);
end evalRelationExp;

function evalRelationOp_dispatch
  input Expression exp1;
  input Operator op;
  input Expression exp2;
  output Expression exp;
protected
  Boolean res;
algorithm
  res := match op.op
    case Op.LESS then evalRelationLess(exp1, exp2);
    case Op.LESSEQ then evalRelationLessEq(exp1, exp2);
    case Op.GREATER then evalRelationGreater(exp1, exp2);
    case Op.GREATEREQ then evalRelationGreaterEq(exp1, exp2);
    case Op.EQUAL then evalRelationEqual(exp1, exp2);
    case Op.NEQUAL then evalRelationNotEqual(exp1, exp2);
    else
      algorithm
        Error.addInternalError(getInstanceName() + ": unimplemented case for " +
          Expression.toString(Expression.RELATION(exp1, op, exp2)), sourceInfo());
      then
        fail();
  end match;

  exp := Expression.BOOLEAN(res);
end evalRelationOp_dispatch;

function evalRelationLess
  input Expression exp1;
  input Expression exp2;
  output Boolean res;
algorithm
  res := match (exp1, exp2)
    case (Expression.INTEGER(), Expression.INTEGER())
      then exp1.value < exp2.value;
    case (Expression.REAL(), Expression.REAL())
      then exp1.value < exp2.value;
    case (Expression.BOOLEAN(), Expression.BOOLEAN())
      then exp1.value < exp2.value;
    case (Expression.STRING(), Expression.STRING())
      then stringCompare(exp1.value, exp2.value) < 0;
    case (Expression.ENUM_LITERAL(), Expression.ENUM_LITERAL())
      then exp1.index < exp2.index;

    else
      algorithm
        printFailedEvalError(getInstanceName(),
          Expression.RELATION(exp1, Operator.makeLess(Type.UNKNOWN()), exp2), sourceInfo());
      then
        fail();
  end match;
end evalRelationLess;

function evalRelationLessEq
  input Expression exp1;
  input Expression exp2;
  output Boolean res;
algorithm
  res := match (exp1, exp2)
    case (Expression.INTEGER(), Expression.INTEGER())
      then exp1.value <= exp2.value;
    case (Expression.REAL(), Expression.REAL())
      then exp1.value <= exp2.value;
    case (Expression.BOOLEAN(), Expression.BOOLEAN())
      then exp1.value <= exp2.value;
    case (Expression.STRING(), Expression.STRING())
      then stringCompare(exp1.value, exp2.value) <= 0;
    case (Expression.ENUM_LITERAL(), Expression.ENUM_LITERAL())
      then exp1.index <= exp2.index;

    else
      algorithm
        printFailedEvalError(getInstanceName(),
          Expression.RELATION(exp1, Operator.makeLessEq(Type.UNKNOWN()), exp2), sourceInfo());
      then
        fail();
  end match;
end evalRelationLessEq;

function evalRelationGreater
  input Expression exp1;
  input Expression exp2;
  output Boolean res;
algorithm
  res := match (exp1, exp2)
    case (Expression.INTEGER(), Expression.INTEGER())
      then exp1.value > exp2.value;
    case (Expression.REAL(), Expression.REAL())
      then exp1.value > exp2.value;
    case (Expression.BOOLEAN(), Expression.BOOLEAN())
      then exp1.value > exp2.value;
    case (Expression.STRING(), Expression.STRING())
      then stringCompare(exp1.value, exp2.value) > 0;
    case (Expression.ENUM_LITERAL(), Expression.ENUM_LITERAL())
      then exp1.index > exp2.index;

    else
      algorithm
        printFailedEvalError(getInstanceName(),
          Expression.RELATION(exp1, Operator.makeGreater(Type.UNKNOWN()), exp2), sourceInfo());
      then
        fail();
  end match;
end evalRelationGreater;

function evalRelationGreaterEq
  input Expression exp1;
  input Expression exp2;
  output Boolean res;
algorithm
  res := match (exp1, exp2)
    case (Expression.INTEGER(), Expression.INTEGER())
      then exp1.value >= exp2.value;
    case (Expression.REAL(), Expression.REAL())
      then exp1.value >= exp2.value;
    case (Expression.BOOLEAN(), Expression.BOOLEAN())
      then exp1.value >= exp2.value;
    case (Expression.STRING(), Expression.STRING())
      then stringCompare(exp1.value, exp2.value) >= 0;
    case (Expression.ENUM_LITERAL(), Expression.ENUM_LITERAL())
      then exp1.index >= exp2.index;

    else
      algorithm
        printFailedEvalError(getInstanceName(),
          Expression.RELATION(exp1, Operator.makeGreaterEq(Type.UNKNOWN()), exp2), sourceInfo());
      then
        fail();
  end match;
end evalRelationGreaterEq;

function evalRelationEqual
  input Expression exp1;
  input Expression exp2;
  output Boolean res;
algorithm
  res := match (exp1, exp2)
    case (Expression.INTEGER(), Expression.INTEGER())
      then exp1.value == exp2.value;
    case (Expression.REAL(), Expression.REAL())
      then exp1.value == exp2.value;
    case (Expression.BOOLEAN(), Expression.BOOLEAN())
      then exp1.value == exp2.value;
    case (Expression.STRING(), Expression.STRING())
      then stringCompare(exp1.value, exp2.value) == 0;
    case (Expression.ENUM_LITERAL(), Expression.ENUM_LITERAL())
      then exp1.index == exp2.index;

    else
      algorithm
        printFailedEvalError(getInstanceName(),
          Expression.RELATION(exp1, Operator.makeEqual(Type.UNKNOWN()), exp2), sourceInfo());
      then
        fail();
  end match;
end evalRelationEqual;

function evalRelationNotEqual
  input Expression exp1;
  input Expression exp2;
  output Boolean res;
algorithm
  res := match (exp1, exp2)
    case (Expression.INTEGER(), Expression.INTEGER())
      then exp1.value <> exp2.value;
    case (Expression.REAL(), Expression.REAL())
      then exp1.value <> exp2.value;
    case (Expression.BOOLEAN(), Expression.BOOLEAN())
      then exp1.value <> exp2.value;
    case (Expression.STRING(), Expression.STRING())
      then stringCompare(exp1.value, exp2.value) <> 0;
    case (Expression.ENUM_LITERAL(), Expression.ENUM_LITERAL())
      then exp1.index <> exp2.index;

    else
      algorithm
        printFailedEvalError(getInstanceName(),
          Expression.RELATION(exp1, Operator.makeNotEqual(Type.UNKNOWN()), exp2), sourceInfo());
      then
        fail();
  end match;
end evalRelationNotEqual;

function evalIfExp
  input Expression ifExp;
  input EvalTarget target;
  output Expression result;
protected
  Type ty;
  Expression cond, btrue, bfalse;
algorithm
  Expression.IF(ty, cond, btrue, bfalse) := ifExp;
  result := Expression.IF(ty, evalExp_impl(cond, target), btrue, bfalse);
  result := Expression.bindingExpMap(result, function evalIfExp2(target = target));
end evalIfExp;

function evalIfExp2
  input Expression ifExp;
  input EvalTarget target;
  output Expression result;
protected
  Type ty;
  Expression cond, tb, fb;
algorithm
  Expression.IF(ty = ty, condition = cond, trueBranch = tb, falseBranch = fb) := ifExp;

  result := match cond
    case Expression.BOOLEAN()
      algorithm
        if Type.isConditionalArray(ty) and not Type.isMatchedBranch(cond.value, ty) then
          (tb, fb) := Util.swap(cond.value, fb, tb);
          Error.addSourceMessage(Error.ARRAY_DIMENSION_MISMATCH,
            {Expression.toString(tb), Type.toString(Expression.typeOf(tb)),
             Dimension.toStringList(Type.arrayDims(Expression.typeOf(fb)), brackets = false)},
             EvalTarget.getInfo(target));
          fail();
        end if;
      then
        evalExp_impl(if cond.value then tb else fb, target);

    else
      algorithm
        Error.addInternalError(getInstanceName() + ": unimplemented case for " +
          Expression.toString(ifExp), sourceInfo());
      then
        fail();
  end match;
end evalIfExp2;

function evalCast
  input Expression castExp;
  input Type castTy;
  output Expression exp;
algorithm
  exp := Expression.typeCast(castExp, castTy);

  // Expression.typeCast will just create a CAST if it can't typecast
  // the expression, so make sure we actually got something else back.
  () := match exp
    case Expression.CAST()
      algorithm
        exp := Expression.CAST(castTy, castExp);
        printFailedEvalError(getInstanceName(), exp, sourceInfo());
      then
        fail();

    else ();
  end match;
end evalCast;

function evalCall
  input Call call;
  input EvalTarget target;
  output Expression exp;
protected
  Call c = call;
algorithm
  exp := match c
    local
      list<Expression> args;

    case Call.TYPED_CALL()
      algorithm
        c.arguments := list(evalExp_impl(arg, target) for arg in c.arguments);
      then
        if Function.isBuiltin(c.fn) then
          Expression.bindingExpMap(Expression.CALL(c), function evalBuiltinCallExp(target = target))
        else
          Expression.bindingExpMap(Expression.CALL(c), evalNormalCallExp);

    case Call.TYPED_ARRAY_CONSTRUCTOR()
      algorithm
        c.exp := evalExpPartial(c.exp);
        c.iters := list((Util.tuple21(i), evalExp_impl(Util.tuple22(i), target)) for i in c.iters);
      then
        Expression.bindingExpMap(Expression.CALL(c), evalArrayConstructor);

    case Call.TYPED_REDUCTION()
      algorithm
        c.exp := evalExpPartial(c.exp);
        c.iters := list((Util.tuple21(i), evalExp_impl(Util.tuple22(i), target)) for i in c.iters);
      then
        Expression.bindingExpMap(Expression.CALL(c), evalReduction);

    else
      algorithm
        Error.addInternalError(getInstanceName() + " got untyped call", sourceInfo());
      then
        fail();

  end match;
end evalCall;

function evalBuiltinCallExp
  input Expression callExp;
  input EvalTarget target;
  output Expression result;
protected
  Function fn;
  list<Expression> args;
algorithm
  Expression.CALL(call = Call.TYPED_CALL(fn = fn, arguments = args)) := callExp;
  result := evalBuiltinCall(fn, args, target);
end evalBuiltinCallExp;

function evalBuiltinCall
  input Function fn;
  input list<Expression> args;
  input EvalTarget target;
  output Expression result;
protected
  Absyn.Path fn_path = Function.nameConsiderBuiltin(fn);
algorithm
  result := match AbsynUtil.pathFirstIdent(fn_path)
    case "abs" then evalBuiltinAbs(listHead(args));
    case "acos" then evalBuiltinAcos(listHead(args), target);
    case "array" then evalBuiltinArray(args);
    case "asin" then evalBuiltinAsin(listHead(args), target);
    case "atan2" then evalBuiltinAtan2(args);
    case "atan" then evalBuiltinAtan(listHead(args));
    case "cat" then evalBuiltinCat(listHead(args), listRest(args), target);
    case "ceil" then evalBuiltinCeil(listHead(args));
    case "cosh" then evalBuiltinCosh(listHead(args));
    case "cos" then evalBuiltinCos(listHead(args));
    case "der" then evalBuiltinDer(listHead(args));
    // TODO: Fix typing of diagonal so the argument isn't boxed.
    case "diagonal" then evalBuiltinDiagonal(Expression.unbox(listHead(args)));
    case "div" then evalBuiltinDiv(args, target);
    case "exp" then evalBuiltinExp(listHead(args));
    case "fill" then evalBuiltinFill(args);
    case "floor" then evalBuiltinFloor(listHead(args));
    case "identity" then evalBuiltinIdentity(listHead(args));
    case "integer" then evalBuiltinInteger(listHead(args));
    case "Integer" then evalBuiltinIntegerEnum(listHead(args));
    case "log10" then evalBuiltinLog10(listHead(args), target);
    case "log" then evalBuiltinLog(listHead(args), target);
    case "matrix" then evalBuiltinMatrix(listHead(args));
    case "max" then evalBuiltinMax(args, fn);
    case "min" then evalBuiltinMin(args, fn);
    case "mod" then evalBuiltinMod(args, target);
    case "noEvent" then listHead(args); // No events during ceval, just return the argument.
    case "ones" then evalBuiltinOnes(args);
    case "product" then evalBuiltinProduct(listHead(args));
    case "promote" then evalBuiltinPromote(listGet(args,1),listGet(args,2));
    case "rem" then evalBuiltinRem(args, target);
    case "scalar" then evalBuiltinScalar(args);
    case "sign" then evalBuiltinSign(listHead(args));
    case "sinh" then evalBuiltinSinh(listHead(args));
    case "sin" then evalBuiltinSin(listHead(args));
    case "skew" then evalBuiltinSkew(listHead(args));
    case "smooth" then listGet(args, 2);
    case "sqrt" then evalBuiltinSqrt(listHead(args));
    case "String" then evalBuiltinString(args);
    case "sum" then evalBuiltinSum(listHead(args));
    case "symmetric" then evalBuiltinSymmetric(listHead(args));
    case "tanh" then evalBuiltinTanh(listHead(args));
    case "tan" then evalBuiltinTan(listHead(args));
    case "transpose" then evalBuiltinTranspose(listHead(args));
    case "vector" then evalBuiltinVector(listHead(args));
    case "zeros" then evalBuiltinZeros(args);
    case "OpenModelica_uriToFilename" then evalUriToFilename(fn, args, target);
    case "intBitAnd" then evalIntBitAnd(args);
    case "intBitOr" then evalIntBitOr(args);
    case "intBitXor" then evalIntBitXor(args);
    case "intBitLShift" then evalIntBitLShift(args);
    case "intBitRShift" then evalIntBitRShift(args);
    case "inferredClock" then evalInferredClock(args);
    case "rationalClock" then evalRationalClock(args);
    case "realClock" then evalRealClock(args);
    case "booleanClock" then evalBooleanClock(args);
    case "solverClock" then evalSolverClock(args);
    case "DynamicSelect" then evalBuiltinDynamicSelect(fn, args, target);
    else
      algorithm
        Error.addInternalError(getInstanceName() + ": unimplemented case for " +
          AbsynUtil.pathString(fn_path), sourceInfo());
      then
        fail();
  end match;
end evalBuiltinCall;

function evalNormalCallExp
  input Expression callExp;
  output Expression result;
protected
  Function fn;
  list<Expression> args;
algorithm
  Expression.CALL(call = Call.TYPED_CALL(fn = fn, arguments = args)) := callExp;
  result := evalNormalCall(fn, args);
end evalNormalCallExp;

function evalNormalCall
  input Function fn;
  input list<Expression> args;
  output Expression result = EvalFunction.evaluate(fn, args);
end evalNormalCall;

function evalBuiltinAbs
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.INTEGER() then Expression.INTEGER(abs(arg.value));
    case Expression.REAL() then Expression.REAL(abs(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinAbs;

function evalBuiltinAcos
  input Expression arg;
  input EvalTarget target;
  output Expression result;
protected
  Real x;
algorithm
  result := match arg
    case Expression.REAL(value = x)
      algorithm
        if x < -1.0 or x > 1.0 then
          if EvalTarget.hasInfo(target) then
            Error.addSourceMessage(Error.ARGUMENT_OUT_OF_RANGE,
              {String(x), "acos", "-1 <= x <= 1"}, EvalTarget.getInfo(target));
          end if;

          fail();
        end if;
      then
        Expression.REAL(acos(x));

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinAcos;

function evalBuiltinArray
  input list<Expression> args;
  output Expression result;
protected
  Type ty;
algorithm
  ty := Expression.typeOf(listHead(args));
  ty := Type.liftArrayLeft(ty, Dimension.fromInteger(listLength(args)));
  result := Expression.makeArray(ty, args, literal = true);
end evalBuiltinArray;

function evalBuiltinAsin
  input Expression arg;
  input EvalTarget target;
  output Expression result;
protected
  Real x;
algorithm
  result := match arg
    case Expression.REAL(value = x)
      algorithm
        if x < -1.0 or x > 1.0 then
          if EvalTarget.hasInfo(target) then
            Error.addSourceMessage(Error.ARGUMENT_OUT_OF_RANGE,
              {String(x), "asin", "-1 <= x <= 1"}, EvalTarget.getInfo(target));
          end if;

          fail();
        end if;
      then
        Expression.REAL(asin(x));

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinAsin;

function evalBuiltinAtan2
  input list<Expression> args;
  output Expression result;
protected
  Real y, x;
algorithm
  result := match args
    case {Expression.REAL(value = y), Expression.REAL(value = x)}
      then Expression.REAL(atan2(y, x));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalBuiltinAtan2;

function evalBuiltinAtan
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL() then Expression.REAL(atan(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinAtan;

function evalBuiltinCat
  input Expression argN;
  input list<Expression> args;
  input EvalTarget target;
  output Expression result;
protected
  Integer n, nd, sz;
  Type ty;
  list<Expression> es;
  list<Integer> dims;
algorithm
  Expression.INTEGER(n) := argN;
  ty := Expression.typeOf(listHead(args));
  nd := Type.dimensionCount(ty);

  if n > nd or n < 1 then
    if EvalTarget.hasInfo(target) then
      Error.addSourceMessage(Error.ARGUMENT_OUT_OF_RANGE, {String(n), "cat", "1 <= x <= " + String(nd)}, EvalTarget.getInfo(target));
    end if;
    fail();
  end if;

  es := list(e for e guard not Expression.isEmptyArray(e) in args);
  sz := listLength(es);

  if sz == 0 then
    result := listHead(args);
  elseif sz == 1 then
    result := listHead(es);
  else
    (es,dims) := ExpressionSimplify.evalCat(n, es, getArrayContents=Expression.arrayElements, toString=Expression.toString);
    result := Expression.arrayFromList(es, Expression.typeOf(listHead(es)), list(Dimension.fromInteger(d) for d in dims));
  end if;
end evalBuiltinCat;

function evalBuiltinCeil
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL() then Expression.REAL(ceil(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinCeil;

function evalBuiltinCosh
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL() then Expression.REAL(cosh(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinCosh;

function evalBuiltinCos
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL() then Expression.REAL(cos(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinCos;

function evalBuiltinDer
  input Expression arg;
  output Expression result;
algorithm
  result := Expression.fillType(Expression.typeOf(arg), Expression.REAL(0.0));
end evalBuiltinDer;

function evalBuiltinDiagonal
  input Expression arg;
  output Expression result;
protected
  Type elem_ty, row_ty;
  Expression zero;
  list<Expression> elems, row, rows = {};
  Integer n, i = 1;
  Boolean e_lit, arg_lit = true;
algorithm
  result := match arg
    case Expression.ARRAY(elements = {}) then arg;

    case Expression.ARRAY(elements = elems)
      algorithm
        n := listLength(elems);

        elem_ty := Expression.typeOf(listHead(elems));
        row_ty := Type.liftArrayLeft(elem_ty, Dimension.fromInteger(n));
        zero := Expression.makeZero(elem_ty);

        for e in listReverse(elems) loop
          row := {};

          for j in 2:i loop
            row := zero :: row;
          end for;

          row := e :: row;
          e_lit := Expression.isLiteral(e);
          arg_lit := arg_lit and e_lit;

          for j in i:n-1 loop
            row := zero :: row;
          end for;

          i := i + 1;
          rows := Expression.makeArray(row_ty, row, e_lit) :: rows;
        end for;
      then
        Expression.makeArray(Type.liftArrayLeft(row_ty, Dimension.fromInteger(n)), rows, arg_lit);

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinDiagonal;

function evalBuiltinDiv
  input list<Expression> args;
  input EvalTarget target;
  output Expression result;
protected
  Real rx, ry;
  Integer ix, iy;
algorithm
  result := match args
    case {Expression.INTEGER(ix), Expression.INTEGER(iy)}
      algorithm
        if iy == 0 then
          if EvalTarget.hasInfo(target) then
            Error.addSourceMessage(Error.DIVISION_BY_ZERO,
              {String(ix), String(iy)}, EvalTarget.getInfo(target));
          end if;

          fail();
        end if;
      then
        Expression.INTEGER(intDiv(ix, iy));

    case {Expression.REAL(rx), Expression.REAL(ry)}
      algorithm
        if ry == 0.0 then
          if EvalTarget.hasInfo(target) then
            Error.addSourceMessage(Error.DIVISION_BY_ZERO,
              {String(rx), String(ry)}, EvalTarget.getInfo(target));
          end if;

          fail();
        end if;

        rx := rx / ry;
      then
        Expression.REAL(if rx < 0.0 then ceil(rx) else floor(rx));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalBuiltinDiv;

function evalBuiltinExp
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL() then Expression.REAL(exp(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinExp;

public
function evalBuiltinFill
  input list<Expression> args;
  output Expression result;
algorithm
  result := evalBuiltinFill2(listHead(args), listRest(args));
end evalBuiltinFill;

function evalBuiltinFill2
  input Expression fillValue;
  input list<Expression> dims;
  output Expression result = fillValue;
protected
  Integer dim_size;
  list<Expression> arr;
  Type arr_ty = Expression.typeOf(result);
algorithm
  for d in listReverse(dims) loop
    () := match d
      case Expression.INTEGER(value = dim_size) then ();
      else algorithm printWrongArgsError(getInstanceName(), {d}, sourceInfo()); then fail();
    end match;

    arr := list(result for e in 1:dim_size);
    arr_ty := Type.liftArrayLeft(arr_ty, Dimension.fromInteger(dim_size));
    result := Expression.makeArray(arr_ty, arr, Expression.isLiteral(fillValue));
  end for;
end evalBuiltinFill2;

protected
function evalBuiltinFloor
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL() then Expression.REAL(floor(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinFloor;

function evalBuiltinIdentity
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.INTEGER()
      then Expression.makeIdentityMatrix(arg.value, Type.INTEGER());

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinIdentity;

function evalBuiltinInteger
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.INTEGER() then arg;
    case Expression.REAL() then Expression.INTEGER(realInt(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinInteger;

function evalBuiltinIntegerEnum
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.ENUM_LITERAL() then Expression.INTEGER(arg.index);
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinIntegerEnum;

function evalBuiltinLog10
  input Expression arg;
  input EvalTarget target;
  output Expression result;
protected
  Real x;
algorithm
  result := match arg
    case Expression.REAL(value = x)
      algorithm
        if x <= 0.0 then
          if EvalTarget.hasInfo(target) then
            Error.addSourceMessage(Error.ARGUMENT_OUT_OF_RANGE,
              {String(x), "log10", "x > 0"}, EvalTarget.getInfo(target));
          end if;

          fail();
        end if;
      then
        Expression.REAL(log10(x));

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinLog10;

function evalBuiltinLog
  input Expression arg;
  input EvalTarget target;
  output Expression result;
protected
  Real x;
algorithm
  result := match arg
    case Expression.REAL(value = x)
      algorithm
        if x <= 0.0 then
          if EvalTarget.hasInfo(target) then
            Error.addSourceMessage(Error.ARGUMENT_OUT_OF_RANGE,
              {String(x), "log", "x > 0"}, EvalTarget.getInfo(target));
          end if;

          fail();
        end if;
      then
        Expression.REAL(log(x));

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinLog;

function evalBuiltinMatrix
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    local
      Integer dim_count;
      list<Expression> expl;
      Dimension dim1, dim2;
      Type ty;

    case Expression.ARRAY(ty = ty)
      algorithm
        dim_count := Type.dimensionCount(ty);

        if dim_count < 2 then
          result := Expression.promote(arg, ty, 2);
        elseif dim_count == 2 then
          result := arg;
        else
          dim1 :: dim2 :: _ := Type.arrayDims(ty);
          ty := Type.liftArrayLeft(Type.arrayElementType(ty), dim2);
          expl := list(evalBuiltinMatrix2(e, ty) for e in arg.elements);
          ty := Type.liftArrayLeft(ty, dim1);
          result := Expression.makeArray(ty, expl);
        end if;
      then
        result;

    else
      algorithm
        ty := Expression.typeOf(arg);

        if Type.isScalar(ty) then
          result := Expression.promote(arg, ty, 2);
        else
          printWrongArgsError(getInstanceName(), {arg}, sourceInfo());
          fail();
        end if;
      then
        result;

  end match;
end evalBuiltinMatrix;

function evalBuiltinMatrix2
  input Expression arg;
  input Type ty;
  output Expression result;
algorithm
  result := match arg
    case Expression.ARRAY()
      then Expression.makeArray(ty,
                                list(Expression.toScalar(e) for e in arg.elements),
                                arg.literal);

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinMatrix2;

function evalBuiltinMax
  input list<Expression> args;
  input Function fn;
  output Expression result;
protected
  Expression e1, e2;
  list<Expression> expl;
  Type ty;
algorithm
  result := match args
    case {e1, e2} then evalBuiltinMax2(e1, e2);
    case {e1 as Expression.ARRAY(ty = ty)}
      algorithm
        result := Expression.fold(e1, evalBuiltinMax2, Expression.EMPTY(ty));

        if Expression.isEmpty(result) then
          result := Expression.CALL(Call.makeTypedCall(fn,
            {Expression.makeEmptyArray(ty)}, Variability.CONSTANT, Type.arrayElementType(ty)));
        end if;
      then
        result;

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalBuiltinMax;

function evalBuiltinMax2
  input Expression exp1;
  input Expression exp2;
  output Expression result;
algorithm
  result := match (exp1, exp2)
    case (Expression.INTEGER(), Expression.INTEGER())
      then if exp1.value < exp2.value then exp2 else exp1;
    case (Expression.REAL(), Expression.REAL())
      then if exp1.value < exp2.value then exp2 else exp1;
    case (Expression.BOOLEAN(), Expression.BOOLEAN())
      then if exp1.value < exp2.value then exp2 else exp1;
    case (Expression.ENUM_LITERAL(), Expression.ENUM_LITERAL())
      then if exp1.index < exp2.index then exp2 else exp1;
    case (Expression.ARRAY(), _) then exp2;
    case (_, Expression.EMPTY()) then exp1;
    else algorithm printWrongArgsError(getInstanceName(), {exp1, exp2}, sourceInfo()); then fail();
  end match;
end evalBuiltinMax2;

function evalBuiltinMin
  input list<Expression> args;
  input Function fn;
  output Expression result;
protected
  Expression e1, e2;
  list<Expression> expl;
  Type ty;
algorithm
  result := match args
    case {e1, e2} then evalBuiltinMin2(e1, e2);
    case {e1 as Expression.ARRAY(ty = ty)}
      algorithm
        result := Expression.fold(e1, evalBuiltinMin2, Expression.EMPTY(ty));

        if Expression.isEmpty(result) then
          result := Expression.CALL(Call.makeTypedCall(fn,
            {Expression.makeEmptyArray(ty)}, Variability.CONSTANT, Type.arrayElementType(ty)));
        end if;
      then
        result;

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalBuiltinMin;

function evalBuiltinMin2
  input Expression exp1;
  input Expression exp2;
  output Expression result;
algorithm
  result := match (exp1, exp2)
    case (Expression.INTEGER(), Expression.INTEGER())
      then if exp1.value > exp2.value then exp2 else exp1;
    case (Expression.REAL(), Expression.REAL())
      then if exp1.value > exp2.value then exp2 else exp1;
    case (Expression.BOOLEAN(), Expression.BOOLEAN())
      then if exp1.value > exp2.value then exp2 else exp1;
    case (Expression.ENUM_LITERAL(), Expression.ENUM_LITERAL())
      then if exp1.index > exp2.index then exp2 else exp1;
    case (Expression.ARRAY(), _) then exp2;
    case (_, Expression.EMPTY()) then exp1;
    else algorithm printWrongArgsError(getInstanceName(), {exp1, exp2}, sourceInfo()); then fail();
  end match;
end evalBuiltinMin2;

function evalBuiltinMod
  input list<Expression> args;
  input EvalTarget target;
  output Expression result;
protected
  Expression x, y;
algorithm
  {x, y} := args;

  result := match (x, y)
    case (Expression.INTEGER(), Expression.INTEGER())
      algorithm
        if y.value == 0 then
          if EvalTarget.hasInfo(target) then
            Error.addSourceMessage(Error.MODULO_BY_ZERO,
              {String(x.value), String(y.value)}, EvalTarget.getInfo(target));
          end if;

          fail();
        end if;
      then
        Expression.INTEGER(mod(x.value, y.value));

    case (Expression.REAL(), Expression.REAL())
      algorithm
        if y.value == 0.0 then
          if EvalTarget.hasInfo(target) then
            Error.addSourceMessage(Error.MODULO_BY_ZERO,
              {String(x.value), String(y.value)}, EvalTarget.getInfo(target));
          end if;

          fail();
        end if;
      then
        Expression.REAL(mod(x.value, y.value));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalBuiltinMod;

function evalBuiltinOnes
  input list<Expression> args;
  output Expression result;
algorithm
  result := evalBuiltinFill2(Expression.INTEGER(1), args);
end evalBuiltinOnes;

function evalBuiltinProduct
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.ARRAY()
      then match Type.arrayElementType(Expression.typeOf(arg))
        case Type.INTEGER() then Expression.INTEGER(Expression.fold(arg, evalBuiltinProductInt, 1));
        case Type.REAL() then Expression.REAL(Expression.fold(arg, evalBuiltinProductReal, 1.0));
        else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
      end match;

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinProduct;

function evalBuiltinProductInt
  input Expression exp;
  input output Integer result;
algorithm
  result := match exp
    case Expression.INTEGER() then result * exp.value;
    case Expression.ARRAY() then result;
    else fail();
  end match;
end evalBuiltinProductInt;

function evalBuiltinProductReal
  input Expression exp;
  input output Real result;
algorithm
  result := match exp
    case Expression.REAL() then result * exp.value;
    case Expression.ARRAY() then result;
    else fail();
  end match;
end evalBuiltinProductReal;

function evalBuiltinPromote
  input Expression arg, argN;
  output Expression result;
protected
  Integer n;
algorithm
  if Expression.isInteger(argN) then
    Expression.INTEGER(n) := argN;
    result := Expression.promote(arg, Expression.typeOf(arg), n);
  else
    printWrongArgsError(getInstanceName(), {arg, argN}, sourceInfo());
    fail();
  end if;
end evalBuiltinPromote;

function evalBuiltinRem
  input list<Expression> args;
  input EvalTarget target;
  output Expression result;
protected
  Expression x, y;
algorithm
  {x, y} := args;

  result := match (x, y)
    case (Expression.INTEGER(), Expression.INTEGER())
      algorithm
        if y.value == 0 then
          if EvalTarget.hasInfo(target) then
            Error.addSourceMessage(Error.REM_ARG_ZERO, {String(x.value),
                String(y.value)}, EvalTarget.getInfo(target));
          end if;

          fail();
        end if;
      then
        Expression.INTEGER(x.value - (div(x.value, y.value) * y.value));

    case (Expression.REAL(), Expression.REAL())
      algorithm
        if y.value == 0.0 then
          if EvalTarget.hasInfo(target) then
            Error.addSourceMessage(Error.REM_ARG_ZERO,
              {String(x.value), String(y.value)}, EvalTarget.getInfo(target));
          end if;

          fail();
        end if;
      then
        Expression.REAL(x.value - (div(x.value, y.value) * y.value));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalBuiltinRem;

function evalBuiltinScalar
  input list<Expression> args;
  output Expression result;
protected
  Expression exp = listHead(args);
algorithm
  result := match exp
    case Expression.ARRAY() then evalBuiltinScalar(exp.elements);
    else exp;
  end match;
end evalBuiltinScalar;

function evalBuiltinSign
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL()
      then Expression.INTEGER(if arg.value > 0 then 1 else if arg.value < 0 then -1 else 0);
    case Expression.INTEGER()
      then Expression.INTEGER(if arg.value > 0 then 1 else if arg.value < 0 then -1 else 0);
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinSign;

function evalBuiltinSinh
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL() then Expression.REAL(sinh(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinSinh;

function evalBuiltinSin
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL() then Expression.REAL(sin(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinSin;

function evalBuiltinSkew
  input Expression arg;
  output Expression result;
protected
  Expression x1, x2, x3, y1, y2, y3;
  Type ty;
  Expression zero;
  Boolean literal;
algorithm
  result := match arg
    case Expression.ARRAY(ty = ty, elements = {x1, x2, x3}, literal = literal)
      algorithm
        zero := Expression.makeZero(Type.arrayElementType(ty));
        y1 := Expression.makeArray(ty, {zero, Expression.negate(x3), x2}, literal);
        y2 := Expression.makeArray(ty, {x3, zero, Expression.negate(x1)}, literal);
        y3 := Expression.makeArray(ty, {Expression.negate(x2), x1, zero}, literal);
        ty := Type.liftArrayLeft(ty, Dimension.fromInteger(3));
      then
        Expression.makeArray(ty, {y1, y2, y3}, literal);

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinSkew;

function evalBuiltinSqrt
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL() then Expression.REAL(sqrt(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinSqrt;

function evalBuiltinString
  input list<Expression> args;
  output Expression result;
algorithm
  result := match args
    local
      Expression arg;
      Integer min_len, str_len, significant_digits, idx, c;
      Boolean left_justified;
      String str, format;
      Real r;

    case {arg, Expression.INTEGER(min_len), Expression.BOOLEAN(left_justified)}
      algorithm
        str := match arg
          case Expression.INTEGER() then intString(arg.value);
          case Expression.BOOLEAN() then boolString(arg.value);
          case Expression.ENUM_LITERAL() then arg.name;
          else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
        end match;

        str_len := stringLength(str);
        if str_len < min_len then
          if left_justified then
            str := str + stringAppendList(List.fill(" ", min_len - str_len));
          else
            str := stringAppendList(List.fill(" ", min_len - str_len)) + str;
          end if;
        end if;
      then
        Expression.STRING(str);

    case {Expression.REAL(r), Expression.INTEGER(significant_digits),
          Expression.INTEGER(min_len), Expression.BOOLEAN(left_justified)}
      algorithm
        format := "%" + (if left_justified then "-" else "") +
                  intString(min_len) + "." + intString(significant_digits) + "g";
        str := System.sprintff(format, r);
      then
        Expression.STRING(str);

    case {Expression.REAL(r), Expression.STRING(format)}
      algorithm
        str := System.sprintff(format, r);
      then
        Expression.STRING(str);

  end match;
end evalBuiltinString;

function evalBuiltinSum
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.ARRAY()
      then match Type.arrayElementType(Expression.typeOf(arg))
        case Type.INTEGER() then Expression.INTEGER(Expression.fold(arg, evalBuiltinSumInt, 0));
        case Type.REAL() then Expression.REAL(Expression.fold(arg, evalBuiltinSumReal, 0.0));
        else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
      end match;

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinSum;

function evalBuiltinSumInt
  input Expression exp;
  input output Integer result;
algorithm
  result := match exp
    case Expression.INTEGER() then result + exp.value;
    case Expression.ARRAY() then result;
    else fail();
  end match;
end evalBuiltinSumInt;

function evalBuiltinSumReal
  input Expression exp;
  input output Real result;
algorithm
  result := match exp
    case Expression.REAL() then result + exp.value;
    case Expression.ARRAY() then result;
    else fail();
  end match;
end evalBuiltinSumReal;

function evalBuiltinSymmetric
  input Expression arg;
  output Expression result;
protected
  array<array<Expression>> mat;
  Integer n;
  Type row_ty;
  list<Expression> expl, accum = {};
algorithm
  result := match arg
    case Expression.ARRAY() guard Type.isMatrix(arg.ty)
      algorithm
        mat := listArray(list(listArray(Expression.arrayElements(row))
                           for row in Expression.arrayElements(arg)));
        n := arrayLength(mat);
        row_ty := Type.unliftArray(arg.ty);

        for i in n:-1:1 loop
          expl := {};
          for j in n:-1:1 loop
            expl := (if i > j then arrayGet(mat[j], i) else arrayGet(mat[i], j)) :: expl;
          end for;

          accum := Expression.makeArray(row_ty, expl, literal = true) :: accum;
        end for;
      then
        Expression.makeArray(arg.ty, accum, literal = true);

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinSymmetric;

function evalBuiltinTanh
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL() then Expression.REAL(tanh(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinTanh;

function evalBuiltinTan
  input Expression arg;
  output Expression result;
algorithm
  result := match arg
    case Expression.REAL() then Expression.REAL(tan(arg.value));
    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinTan;

function evalBuiltinTranspose
  input Expression arg;
  output Expression result;
protected
  Dimension dim1, dim2;
  list<Dimension> rest_dims;
  Type ty;
  list<Expression> arr;
  list<list<Expression>> arrl;
  Boolean literal;
algorithm
  result := match arg
    case Expression.ARRAY(ty = Type.ARRAY(elementType = ty,
                                          dimensions = dim1 :: dim2 :: rest_dims),
                          elements = arr,
                          literal = literal)
      algorithm
        arrl := list(Expression.arrayElements(e) for e in arr);
        arrl := List.transposeList(arrl);
        ty := Type.liftArrayLeft(ty, dim1);
        arr := list(Expression.makeArray(ty, expl, literal) for expl in arrl);
        ty := Type.liftArrayLeft(ty, dim2);
      then
        Expression.makeArray(ty, arr, literal);

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalBuiltinTranspose;

function evalBuiltinVector
  input Expression arg;
  output Expression result;
protected
  list<Expression> expl;
  Type ty;
algorithm
  expl := Expression.fold(arg, evalBuiltinVector2, {});
  ty := Type.liftArrayLeft(Type.arrayElementType(Expression.typeOf(arg)),
    Dimension.fromInteger(listLength(expl)));
  result := Expression.makeArray(ty, listReverse(expl), literal = true);
end evalBuiltinVector;

function evalBuiltinVector2
  input Expression exp;
  input output list<Expression> expl;
algorithm
  expl := match exp
    case Expression.ARRAY() then expl;
    else exp :: expl;
  end match;
end evalBuiltinVector2;

function evalBuiltinZeros
  input list<Expression> args;
  output Expression result;
algorithm
  result := evalBuiltinFill2(Expression.INTEGER(0), args);
end evalBuiltinZeros;

function evalUriToFilename
  input Function fn;
  input list<Expression> args;
  input EvalTarget target;
  output Expression result;
protected
  Expression e, arg;
  String s;
  Function f;
algorithm
  arg := listHead(args);
  result := match arg
    case Expression.STRING()
      algorithm
        s := OpenModelica.Scripting.uriToFilename(arg.value);
        e := Expression.STRING(s);
        if Flags.getConfigBool(Flags.BUILDING_FMU) then
          f := Function.setName(Absyn.IDENT("OpenModelica_fmuLoadResource"), fn);
          e := Expression.CALL(Call.makeTypedCall(f, {e}, Variability.PARAMETER, Expression.typeOf(e)));
        end if;
      then e;

    else algorithm printWrongArgsError(getInstanceName(), {arg}, sourceInfo()); then fail();
  end match;
end evalUriToFilename;

function evalIntBitAnd
  input list<Expression> args;
  output Expression result;
protected
  Integer i1, i2;
algorithm
  result := match args
    case {Expression.INTEGER(value = i1), Expression.INTEGER(value = i2)}
      then Expression.INTEGER(intBitAnd(i1, i2));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalIntBitAnd;

function evalIntBitOr
  input list<Expression> args;
  output Expression result;
protected
  Integer i1, i2;
algorithm
  result := match args
    case {Expression.INTEGER(value = i1), Expression.INTEGER(value = i2)}
      then Expression.INTEGER(intBitOr(i1, i2));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalIntBitOr;

function evalIntBitXor
  input list<Expression> args;
  output Expression result;
protected
  Integer i1, i2;
algorithm
  result := match args
    case {Expression.INTEGER(value = i1), Expression.INTEGER(value = i2)}
      then Expression.INTEGER(intBitXor(i1, i2));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalIntBitXor;

function evalIntBitLShift
  input list<Expression> args;
  output Expression result;
protected
  Integer i1, i2;
algorithm
  result := match args
    case {Expression.INTEGER(value = i1), Expression.INTEGER(value = i2)}
      then Expression.INTEGER(intBitLShift(i1, i2));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalIntBitLShift;

function evalIntBitRShift
  input list<Expression> args;
  output Expression result;
protected
  Integer i1, i2;
algorithm
  result := match args
    case {Expression.INTEGER(value = i1), Expression.INTEGER(value = i2)}
      then Expression.INTEGER(intBitRShift(i1, i2));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalIntBitRShift;

function evalInferredClock
  input list<Expression> args;
  output Expression result;
algorithm
  result := match args
    case {}
      then Expression.CLKCONST(Expression.ClockKind.INFERRED_CLOCK());

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalInferredClock;

function evalRationalClock
  input list<Expression> args;
  output Expression result;
algorithm
  result := match args
    local
      Expression interval, resolution;

    case {interval as Expression.INTEGER(), resolution as Expression.INTEGER()}
      then Expression.CLKCONST(Expression.ClockKind.INTEGER_CLOCK(interval, resolution));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalRationalClock;

function evalRealClock
  input list<Expression> args;
  output Expression result;
algorithm
  result := match args
    local
      Expression interval;

    case {interval as Expression.REAL()}
      then Expression.CLKCONST(Expression.ClockKind.REAL_CLOCK(interval));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalRealClock;

function evalBooleanClock
  input list<Expression> args;
  output Expression result;
algorithm
  result := match args
    local
      Expression condition, interval;

    case {condition as Expression.BOOLEAN(), interval as Expression.REAL()}
      then Expression.CLKCONST(Expression.ClockKind.BOOLEAN_CLOCK(condition, interval));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalBooleanClock;

function evalSolverClock
  input list<Expression> args;
  output Expression result;
algorithm
  result := match args
    local
      Expression c, solver;

    case {c as Expression.CLKCONST(), solver as Expression.STRING()}
      then Expression.CLKCONST(Expression.ClockKind.SOLVER_CLOCK(c, solver));

    else algorithm printWrongArgsError(getInstanceName(), args, sourceInfo()); then fail();
  end match;
end evalSolverClock;

function evalBuiltinDynamicSelect
  input Function fn;
  input list<Expression> args;
  input EvalTarget target;
  output Expression result;
protected
  Expression s, d;
algorithm
  {s, d} := list(Expression.unbox(arg) for arg in args);
  s := evalExp(s, target);
  if Flags.isSet(Flags.NF_API_DYNAMIC_SELECT) then
    result := Expression.CALL(Call.makeTypedCall(fn, {s, d}, Variability.CONTINUOUS, Expression.typeOf(s)));
  else
    result := s;
  end if;
end evalBuiltinDynamicSelect;

function evalArrayConstructor
  input Expression callExp;
  output Expression result;
protected
  Expression exp;
  list<tuple<InstNode, Expression>> iters;
  list<Mutable<Expression>> iter_exps;
  list<Expression> ranges;
  Type ty;
  list<Type> types = {};
algorithm
  Expression.CALL(call = Call.TYPED_ARRAY_CONSTRUCTOR(exp = exp, iters = iters)) := callExp;
  (exp, ranges, iter_exps) := createIterationRanges(exp, iters);

  // Precompute all the types we're going to need for the arrays created.
  ty := Expression.typeOf(exp);
  for r in ranges loop
    ty := Type.liftArrayLeftList(ty, Type.arrayDims(Expression.typeOf(r)));
    types := ty :: types;
  end for;

  result := evalArrayConstructor3(exp, ranges, iter_exps, types);
end evalArrayConstructor;

function createIterationRanges
  input output Expression exp;
  input list<tuple<InstNode, Expression>> iterators;
        output list<Expression> ranges = {};
        output list<Mutable<Expression>> iters = {};
protected
  InstNode node;
  Expression range;
  Mutable<Expression> iter;
algorithm
  for i in iterators loop
    (node, range) := i;
    iter := Mutable.create(Expression.INTEGER(0));
    exp := Expression.replaceIterator(exp, node, Expression.MUTABLE(iter));
    iters := iter :: iters;
    ranges := range :: ranges;
  end for;
end createIterationRanges;

function evalArrayConstructor3
  input Expression exp;
  input list<Expression> ranges;
  input list<Mutable<Expression>> iterators;
  input list<Type> types;
  output Expression result;
protected
  Expression range, e;
  list<Expression> ranges_rest, expl = {};
  Mutable<Expression> iter;
  list<Mutable<Expression>> iters_rest;
  ExpressionIterator range_iter;
  Expression value;
  Type ty;
  list<Type> rest_ty;
algorithm
  if listEmpty(ranges) then
    result := evalExp_impl(exp, EvalTarget.IGNORE_ERRORS());
  else
    range :: ranges_rest := ranges;
    iter :: iters_rest := iterators;
    ty :: rest_ty := types;
    range_iter := ExpressionIterator.fromExp(range);

    while ExpressionIterator.hasNext(range_iter) loop
      (range_iter, value) := ExpressionIterator.next(range_iter);
      Mutable.update(iter, value);
      expl := evalArrayConstructor3(exp, ranges_rest, iters_rest, rest_ty) :: expl;
    end while;

    result := Expression.makeArray(ty, listReverseInPlace(expl), literal = true);
  end if;
end evalArrayConstructor3;

partial function ReductionFn
  input Expression exp1;
  input Expression exp2;
  output Expression result;
end ReductionFn;

function evalReduction
  input Expression callExp;
  output Expression result;
protected
  Function fn;
  Expression exp, default_exp;
  list<tuple<InstNode, Expression>> iters;
  list<Mutable<Expression>> iter_exps;
  list<Expression> ranges;
  Type ty;
  ReductionFn red_fn;
algorithm
  Expression.CALL(call = Call.TYPED_REDUCTION(fn = fn, exp = exp, iters = iters)) := callExp;
  (exp, ranges, iter_exps) := createIterationRanges(exp, iters);
  ty := Expression.typeOf(exp);

  (red_fn, default_exp) := match AbsynUtil.pathString(Function.name(fn))
    case "sum" then (evalBinaryAdd, Expression.makeZero(ty));
    case "product" then (evalBinaryMul, Expression.makeOne(ty));
    case "min" then (evalBuiltinMin2, Expression.makeMaxValue(ty));
    case "max" then (evalBuiltinMax2, Expression.makeMinValue(ty));
    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown reduction function " +
          AbsynUtil.pathString(Function.name(fn)), sourceInfo());
      then
        fail();
  end match;

  result := evalReduction2(exp, ranges, iter_exps, default_exp, red_fn);
end evalReduction;

function evalReduction2
  input Expression exp;
  input list<Expression> ranges;
  input list<Mutable<Expression>> iterators;
  input Expression foldExp;
  input ReductionFn fn;
  output Expression result;
protected
  Expression range;
  list<Expression> ranges_rest, expl = {};
  Mutable<Expression> iter;
  list<Mutable<Expression>> iters_rest;
  ExpressionIterator range_iter;
  Expression value;
  Type el_ty;
algorithm
  if listEmpty(ranges) then
    result := fn(foldExp, evalExp_impl(exp, EvalTarget.IGNORE_ERRORS()));
  else
    range :: ranges_rest := ranges;
    iter :: iters_rest := iterators;
    range_iter := ExpressionIterator.fromExp(range);
    result := foldExp;

    while ExpressionIterator.hasNext(range_iter) loop
      (range_iter, value) := ExpressionIterator.next(range_iter);
      Mutable.update(iter, value);
      result := evalReduction2(exp, ranges_rest, iters_rest, result, fn);
    end while;
  end if;
end evalReduction2;

function evalSize
  input Expression exp;
  input Option<Expression> optIndex;
  input EvalTarget target;
  output Expression outExp;
protected
  Expression index_exp;
  Integer index;
  TypingError ty_err;
  Dimension dim;
  Type ty;
  list<Expression> expl;
  SourceInfo info;
algorithm
  info := EvalTarget.getInfo(target);

  if isSome(optIndex) then
    // Evaluate the index.
    index_exp := evalExp_impl(Util.getOption(optIndex), target);
    index := Expression.toInteger(index_exp);

    // Get the index'd dimension of the expression.
    (dim, _, ty_err) := Typing.typeExpDim(exp, index, ExpOrigin.CLASS, info);
    Typing.checkSizeTypingError(ty_err, exp, index, info);

    // Return the size expression for the found dimension.
    outExp := Dimension.sizeExp(dim);
  else
    (outExp, ty) := Typing.typeExp(exp, ExpOrigin.CLASS, info);
    expl := list(Dimension.sizeExp(d) for d in Type.arrayDims(ty));
    dim := Dimension.fromInteger(listLength(expl), Variability.PARAMETER);
    outExp := Expression.makeArray(Type.ARRAY(Type.INTEGER(), {dim}), expl);
  end if;
end evalSize;

function evalSubscriptedExp
  input Expression exp;
  input list<Subscript> subscripts;
  input EvalTarget target;
  output Expression result;
protected
  list<Subscript> subs;
algorithm
  result := match exp
    case Expression.RANGE()
      then Expression.RANGE(exp.ty,
                            evalExp(exp.start, target),
                            evalExpOpt(exp.step, target),
                            evalExp(exp.stop, target));

    else evalExp_impl(exp, target);
  end match;

  subs := list(Subscript.mapShallowExp(s, function evalExp_impl(target = target)) for s in subscripts);
  result := Expression.applySubscripts(subs, result);
end evalSubscriptedExp;

function evalRecordElement
  input Expression exp;
  input EvalTarget target;
  output Expression result;
protected
  Expression e;
  Integer index;
algorithm
  Expression.RECORD_ELEMENT(recordExp = e, index = index) := exp;
  e := evalExp_impl(e, target);

  try
    result := Expression.bindingExpMap(e, function evalRecordElement2(index = index));
  else
    Error.assertion(false, getInstanceName() + " could not evaluate " +
      Expression.toString(exp), sourceInfo());
  end try;
end evalRecordElement;

function evalRecordElement2
  input Expression exp;
  input Integer index;
  output Expression result;
algorithm
  result := match exp
    case Expression.RECORD()
      then listGet(exp.elements, index);
  end match;
end evalRecordElement2;

protected

function printUnboundError
  input Component component;
  input EvalTarget target;
  input Expression exp;
algorithm
  () := match target
    case EvalTarget.IGNORE_ERRORS() then ();

    case EvalTarget.DIMENSION()
      algorithm
        Error.addSourceMessage(Error.STRUCTURAL_PARAMETER_OR_CONSTANT_WITH_NO_BINDING,
          {Expression.toString(exp), InstNode.name(target.component)}, target.info);
      then
        fail();

    case EvalTarget.CONDITION()
      algorithm
        Error.addSourceMessage(Error.CONDITIONAL_EXP_WITHOUT_VALUE,
          {Expression.toString(exp)}, target.info);
      then
        fail();

    else
      algorithm
        // check if we have a parameter with (fixed = true), annotation(Evaluate = true) and no binding
        if listMember(Component.variability(component), {Variability.STRUCTURAL_PARAMETER, Variability.PARAMETER}) and
           Component.getEvaluateAnnotation(component)
        then
          // only add an error if fixed = true
          if Component.getFixedAttribute(component) then
            Error.addMultiSourceMessage(Error.UNBOUND_PARAMETER_EVALUATE_TRUE,
              {Expression.toString(exp) + "(fixed = true)"},
              {InstNode.info(ComponentRef.node(Expression.toCref(exp))), EvalTarget.getInfo(target)});
          end if;
        else // constant with no binding
          Error.addMultiSourceMessage(Error.UNBOUND_CONSTANT,
            {Expression.toString(exp)},
            {InstNode.info(ComponentRef.node(Expression.toCref(exp))), EvalTarget.getInfo(target)});
          fail();
        end if;
      then
        ();

  end match;
end printUnboundError;

function printWrongArgsError
  input String evalFunc;
  input list<Expression> args;
  input SourceInfo info;
algorithm
  Error.addInternalError(evalFunc + " got invalid arguments " +
    List.toString(args, Expression.toString, "", "(", ", ", ")", true), info);
end printWrongArgsError;

annotation(__OpenModelica_Interface="frontend");
end NFCeval;
