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

encapsulated package NFEvalFunction

import Expression = NFExpression;
import NFClass.Class;
import NFFunction.Function;
import NFInstNode.InstNode;
import Sections = NFSections;
import Statement = NFStatement;
import ComponentRef = NFComponentRef;
import Binding = NFBinding;
import NFComponent.Component;
import Type = NFType;

protected
import Ceval = NFCeval;
import MetaModelica.Dangerous.*;
import RangeIterator = NFRangeIterator;
import ElementSource;

encapsulated package ReplTree
  import BaseAvlTree;
  import Expression = NFExpression;

  extends BaseAvlTree(redeclare type Key = String,
                      redeclare type Value = Expression);

  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := Expression.toString(inValue);
  end valueStr;

  redeclare function extends keyCompare
  algorithm
    outResult := stringCompare(inKey1, inKey2);
  end keyCompare;

  annotation(__OpenModelica_Interface="util");
end ReplTree;

type FlowControl = enumeration(NEXT, CONTINUE, BREAK, RETURN, FAIL);

public
function evaluate
  input Function fn;
  input list<Expression> args;
  output Expression result;
protected
  list<Statement> fn_body;
  list<Binding> bindings;
  ReplTree.Tree repl;
  Integer call_count, limit;
  Pointer<Integer> call_counter = fn.callCounter;
  FlowControl ctrl;
algorithm
  // Functions contain a mutable call counter that's increased by one at the
  // start of each evaluation, and decreased by one when the evalution is
  // finished. This is used to limit the number of recursive functions calls.
  call_count := Pointer.access(call_counter) + 1;
  limit := Flags.getConfigInt(Flags.EVAL_RECURSION_LIMIT);

  if call_count > limit then
    Pointer.update(call_counter, 0);
    Error.addSourceMessage(Error.EVAL_RECURSION_LIMIT_REACHED,
      {String(limit), Absyn.pathString(Function.name(fn))}, InstNode.info(fn.node));
    fail();
  end if;

  Pointer.update(call_counter, call_count);

  try
    fn_body := getFunctionBody(fn.node);
    repl := createReplacements(fn, args);
    // TODO: Also apply replacements to the replacements themselves, i.e. the
    //       bindings of the function parameters. But the probably need to be
    //       sorted by dependencies first.
    fn_body := applyReplacements(repl, fn_body);
    ctrl := evaluateStatements(fn_body);
    result := createResult(repl, fn.outputs);
  else
    // Make sure we always decrease the call counter even if the evaluation fails.
    Pointer.update(call_counter, call_count - 1);
    fail();
  end try;

  Pointer.update(call_counter, call_count - 1);
end evaluate;

protected

function getFunctionBody
  input InstNode node;
  output list<Statement> body;
protected
  Class cls = InstNode.getClass(node);
algorithm
  body := match cls
    case Class.INSTANCED_CLASS(sections = Sections.SECTIONS(algorithms = {body})) then body;

    case Class.INSTANCED_CLASS(sections = Sections.SECTIONS(algorithms = _ :: _))
      algorithm
        Error.assertion(false, getInstanceName() + " got function with multiple algorithm sections", sourceInfo());
      then
        fail();

    case Class.TYPED_DERIVED() then getFunctionBody(cls.baseClass);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown function", sourceInfo());
      then
        fail();

  end match;
end getFunctionBody;

function createReplacements
  input Function fn;
  input list<Expression> args;
  output ReplTree.Tree repl;
protected
  Expression arg;
  list<Expression> rest_args = args;
algorithm
  repl := ReplTree.new();

  for i in fn.inputs loop
    arg :: rest_args := rest_args;
    repl := addInputReplacement(i, "", arg, repl);
  end for;

  repl := List.fold(fn.outputs, function addMutableReplacement(prefix = ""), repl);
  repl := List.fold(fn.locals, function addMutableReplacement(prefix = ""), repl);
end createReplacements;

function addMutableReplacement
  input InstNode node;
  input String prefix = "";
  input output ReplTree.Tree repl;
protected
  Binding binding;
  Expression repl_exp;
algorithm
  binding := Component.getBinding(InstNode.component(node));

  // TODO: Handle records.
  if Binding.isBound(binding) then
    repl_exp := Binding.getExp(binding);
  else
    // TODO: Replace with something more suitable, Expression.EMPTY?
    repl_exp := Expression.INTEGER(0);
  end if;

  repl_exp := Expression.makeMutable(repl_exp);
  repl := ReplTree.add(repl, prefix + InstNode.name(node), repl_exp);
end addMutableReplacement;

function addInputReplacement
  input InstNode node;
  input String prefix = "";
  input Expression argument;
  input output ReplTree.Tree repl;
algorithm
  repl := ReplTree.add(repl, prefix + InstNode.name(node), argument);
end addInputReplacement;

function applyReplacements
  input ReplTree.Tree repl;
  input output list<Statement> fnBody;
algorithm
  fnBody := Statement.mapExpList(fnBody,
    function Expression.map(func = function applyReplacements2(repl = repl)));
end applyReplacements;

function applyReplacements2
  input ReplTree.Tree repl;
  input output Expression exp;
algorithm
  exp := match exp
    local
      Option<Expression> repl_exp;

    case Expression.CREF(cref = ComponentRef.CREF(subscripts = _ :: _))
      algorithm
        Error.assertion(false, getInstanceName() + ": missing handling of subscripts", sourceInfo());
      then
        fail();

    case Expression.CREF() guard not ComponentRef.isIterator(exp.cref)
      algorithm
        // TODO: Handle subscripting.
        repl_exp := ReplTree.getOpt(repl, ComponentRef.toString(exp.cref));
      then
        if isSome(repl_exp) then Util.getOption(repl_exp) else exp;

    else exp;
  end match;
end applyReplacements2;

function createResult
  input ReplTree.Tree repl;
  input list<InstNode> outputs;
  output Expression exp;
protected
  list<Expression> expl;
  list<Type> types;
algorithm
  if listLength(outputs) == 1 then
    exp := Expression.makeImmutable(ReplTree.get(repl, InstNode.name(listHead(outputs))));
  else
    expl := {};
    types := {};

    for o in outputs loop
      expl := Expression.makeImmutable(ReplTree.get(repl, InstNode.name(o))) :: expl;
    end for;

    expl := listReverseInPlace(expl);
    types := list(Expression.typeOf(e) for e in expl);
    exp := Expression.TUPLE(Type.TUPLE(types, NONE()), expl);
  end if;
end createResult;

function evaluateStatements
  input list<Statement> stmts;
  output FlowControl ctrl = FlowControl.NEXT;
algorithm
  for s in stmts loop
    ctrl := evaluateStatement(s);

    if ctrl <> FlowControl.NEXT then
      if ctrl == FlowControl.CONTINUE then
        ctrl := FlowControl.NEXT;
      end if;

      break;
    end if;
  end for;
end evaluateStatements;

function evaluateStatement
  input Statement stmt;
  output FlowControl ctrl;
algorithm
  ctrl := match stmt
    case Statement.ASSIGNMENT() then evaluateAssignment(stmt.lhs, stmt.rhs);
    case Statement.FOR()        then evaluateFor(stmt.iterator, stmt.range, stmt.body, stmt.source);
    case Statement.IF()         then evaluateIf(stmt.branches);
    case Statement.ASSERT()     then evaluateAssert(stmt.condition, stmt);
    case Statement.TERMINATE()  then evaluateTerminate(stmt.message, stmt.source);
    case Statement.NORETCALL()  then evaluateNoRetCall(stmt.exp);
    case Statement.WHILE()      then evaluateWhile(stmt.condition, stmt.body, stmt.source);
    case Statement.RETURN()     then FlowControl.RETURN;
    case Statement.BREAK()      then FlowControl.BREAK;
    else
      algorithm
        Error.assertion(false, getInstanceName() + " failed on " + anyString(stmt) + "\n", sourceInfo());
      then
        fail();

  end match;
end evaluateStatement;

function evaluateAssignment
  input Expression lhsExp;
  input Expression rhsExp;
  output FlowControl ctrl = FlowControl.NEXT;
protected
  Expression rhs;
algorithm
  rhs := Ceval.evalExp(rhsExp);

  () := match lhsExp
    case Expression.MUTABLE()
      algorithm
        Mutable.update(lhsExp.exp, rhs);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " failed on " +
          Expression.toString(lhsExp) + " := " + Expression.toString(rhsExp), sourceInfo());
      then
        fail();

  end match;
end evaluateAssignment;

function evaluateFor
  input InstNode iterator;
  input Option<Expression> range;
  input list<Statement> forBody;
  input DAE.ElementSource source;
  output FlowControl ctrl;
protected
  RangeIterator range_iter;
  Mutable<Expression> iter_exp;
  Expression range_exp, value;
  list<Statement> body = forBody;
  Integer i = 0, limit = Flags.getConfigInt(Flags.EVAL_LOOP_LIMIT);
algorithm
  range_exp := Ceval.evalExp(Util.getOption(range));
  range_iter := RangeIterator.fromExp(range_exp);

  if RangeIterator.hasNext(range_iter) then
    // Replace the iterator with a mutable expression.
    // TODO: If each iterator contained a mutable binding that we could update
    //       this wouldn't be necessary, but the handling of for loops needs to
    //       be fixed so we don't try to evaluate iterators when we shouldn't.
    iter_exp := Mutable.create(Expression.INTEGER(0));
    value := Expression.MUTABLE(iter_exp);
    body := Statement.mapExpList(forBody,
      function Expression.replaceIterator(iterator = iterator, iteratorValue = value));

    // Loop through each value in the iteration range.
    while RangeIterator.hasNext(range_iter) loop
      (range_iter, value) := RangeIterator.next(range_iter);
      // Update the mutable expression with the iteration value and evaluate the statement.
      Mutable.update(iter_exp, value);
      ctrl := evaluateStatements(body);

      if ctrl <> FlowControl.NEXT then
        if ctrl == FlowControl.BREAK then
          ctrl := FlowControl.NEXT;
        end if;

        break;
      end if;

      i := i + 1;
      if i > limit then
        Error.addSourceMessage(Error.EVAL_LOOP_LIMIT_REACHED, {String(limit)},
          ElementSource.getInfo(source));
        fail();
      end if;
    end while;
  end if;
end evaluateFor;

function evaluateIf
  input list<tuple<Expression, list<Statement>>> branches;
  output FlowControl ctrl;
protected
  Expression cond;
  list<Statement> body;
algorithm
  for branch in branches loop
    (cond, body) := branch;

    if Expression.isTrue(Ceval.evalExp(cond)) then
      ctrl := evaluateStatements(body);
      return;
    end if;
  end for;

  ctrl := FlowControl.NEXT;
end evaluateIf;

function evaluateAssert
  input Expression condition;
  input Statement assertStmt;
  output FlowControl ctrl = FlowControl.NEXT;
protected
  Expression msg, lvl;
  DAE.ElementSource source;
algorithm
  if Expression.isFalse(Ceval.evalExp(condition)) then
    Statement.ASSERT(message = msg, level = lvl, source = source) := assertStmt;
    msg := Ceval.evalExp(msg);
    lvl := Ceval.evalExp(lvl);

    () := match (msg, lvl)
      case (Expression.STRING(), Expression.ENUM_LITERAL(name = "warning"))
        algorithm
          Error.addSourceMessage(Error.ASSERT_TRIGGERED_WARNING, {msg.value}, ElementSource.getInfo(source));
        then
          ();

      case (Expression.STRING(), Expression.ENUM_LITERAL(name = "error"))
        algorithm
          Error.addSourceMessage(Error.ASSERT_TRIGGERED_ERROR, {msg.value}, ElementSource.getInfo(source));
        then
          fail();

      else
        algorithm
          Error.assertion(false, getInstanceName() + " failed to evaluate assert(false, " +
            Expression.toString(msg) + ", " + Expression.toString(lvl) + ")", sourceInfo());
        then
          fail();
    end match;
  end if;
end evaluateAssert;

function evaluateTerminate
  input Expression message;
  input DAE.ElementSource source;
  output FlowControl dummy = FlowControl.NEXT;
protected
  Expression msg;
algorithm
  msg := Ceval.evalExp(message);

  _ := match msg
    case Expression.STRING()
      algorithm
        Error.addSourceMessage(Error.TERMINATE_TRIGGERED, {msg.value}, ElementSource.getInfo(source));
      then
        fail();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " failed to evaluate terminate(" +
          Expression.toString(msg) + ")", sourceInfo());
      then
        fail();

  end match;
end evaluateTerminate;

function evaluateNoRetCall
  input Expression callExp;
  output FlowControl ctrl = FlowControl.NEXT;
algorithm
  Ceval.evalExp(callExp);
end evaluateNoRetCall;

function evaluateWhile
  input Expression condition;
  input list<Statement> body;
  input DAE.ElementSource source;
  output FlowControl ctrl = FlowControl.NEXT;
protected
  Integer i = 0, limit = Flags.getConfigInt(Flags.EVAL_LOOP_LIMIT);
algorithm
  while Expression.isTrue(Ceval.evalExp(condition)) loop
    ctrl := evaluateStatements(body);

    if ctrl <> FlowControl.NEXT then
      if ctrl == FlowControl.BREAK then
        ctrl := FlowControl.NEXT;
      end if;

      break;
    end if;

    i := i + 1;
    if i > limit then
      Error.addSourceMessage(Error.EVAL_LOOP_LIMIT_REACHED, {String(limit)},
        ElementSource.getInfo(source));
      fail();
    end if;
  end while;
end evaluateWhile;

annotation(__OpenModelica_Interface="frontend");
end NFEvalFunction;
