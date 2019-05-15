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
import NFBinding.Binding;
import NFComponent.Component;
import Type = NFType;
import Dimension = NFDimension;
import NFClassTree.ClassTree;
import Subscript = NFSubscript;

protected
import Ceval = NFCeval;
import MetaModelica.Dangerous.*;
import RangeIterator = NFRangeIterator;
import ElementSource;
import ModelicaExternalC;
import System;
import NFTyping.ExpOrigin;
import SCode;
import NFPrefixes.Variability;
import EvalFunctionExt = NFEvalFunctionExt;
import NFCeval.EvalTarget;

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

type FlowControl = enumeration(NEXT, CONTINUE, BREAK, RETURN, ASSERTION);

public
function evaluate
  input Function fn;
  input list<Expression> args;
  output Expression result;
algorithm
  if Function.isExternal(fn) then
    result := evaluateExternal(fn, args);
  else
    result := evaluateNormal(fn, args);
  end if;
end evaluate;

function evaluateNormal
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
    fn_body := Function.getBody(fn);
    repl := createReplacements(fn, args);
    // TODO: Also apply replacements to the replacements themselves, i.e. the
    //       bindings of the function parameters. But they probably need to be
    //       sorted by dependencies first.
    fn_body := applyReplacements(repl, fn_body);
    fn_body := optimizeBody(fn_body);
    ctrl := evaluateStatements(fn_body);

    if ctrl <> FlowControl.ASSERTION then
      result := createResult(repl, fn.outputs);
    else
      fail();
    end if;
  else
    // Make sure we always decrease the call counter even if the evaluation fails.
    Pointer.update(call_counter, call_count - 1);
    fail();
  end try;

  Pointer.update(call_counter, call_count - 1);
end evaluateNormal;

function evaluateExternal
  input Function fn;
  input list<Expression> args;
  output Expression result;
protected
  String name, lang;
  ComponentRef output_ref;
  Option<SCode.Annotation> ann;
  list<Expression> ext_args;
algorithm
  Sections.EXTERNAL(name = name, args = ext_args, outputRef = output_ref, language = lang, ann = ann) :=
    Class.getSections(InstNode.getClass(fn.node));

  if lang == "builtin" then
    // Functions defined as 'external "builtin"', delegate to Ceval.
    result := Ceval.evalBuiltinCall(fn, args, EvalTarget.IGNORE_ERRORS());
  elseif isKnownExternalFunc(name, ann) then
    // External functions that we know how to evaluate without generating code.
    // TODO: Move this to EvalFunctionExt and unify evaluateKnownExternal and
    //       evaluateExternal2. This requires handling of outputRef though.
    result := evaluateKnownExternal(name, args);
  else
    try
      result := evaluateExternal2(name, fn, args, ext_args);
    else
      // External functions that we would need to generate code for and execute.
      Error.assertion(false, getInstanceName() +
        " failed on " + Absyn.pathString(fn.path) +
        ", evaluation of userdefined external functions not yet implemented", sourceInfo());
      fail();
    end try;
  end if;
end evaluateExternal;

protected

function createReplacements
  input Function fn;
  input list<Expression> args;
  output ReplTree.Tree repl;
protected
  Expression arg;
  list<Expression> rest_args = args;
algorithm
  repl := ReplTree.new();

  // Add inputs to the replacement tree. Since they can't be assigned to the
  // replacements don't need to be mutable.
  for i in fn.inputs loop
    arg :: rest_args := rest_args;
    repl := addInputReplacement(i, "", arg, repl);
  end for;

  // Add outputs and local variables to the replacement tree. These do need to
  // be mutable to allow assigning to them.
  repl := List.fold(fn.outputs, function addMutableReplacement(prefix = ""), repl);
  repl := List.fold(fn.locals, function addMutableReplacement(prefix = ""), repl);

  // Apply the replacements to the replacements themselves. This is done after
  // building the tree to make sure all the replacements are available.
  repl := ReplTree.map(repl, function applyBindingReplacement(repl = repl));
end createReplacements;

function addMutableReplacement
  input InstNode node;
  input String prefix = "";
  input output ReplTree.Tree repl;
protected
  Binding binding;
  Expression repl_exp;
algorithm
  repl_exp := getBindingExp(node, repl);
  repl_exp := Expression.makeMutable(repl_exp);
  repl := ReplTree.add(repl, prefix + InstNode.name(node), repl_exp);
end addMutableReplacement;

function getBindingExp
  input InstNode node;
  input ReplTree.Tree repl;
  output Expression bindingExp;
protected
  Binding binding;
algorithm
  binding := Component.getBinding(InstNode.component(node));

  if Binding.isBound(binding) then
    bindingExp := Binding.getExp(binding);
  else
    bindingExp := buildBinding(node, repl);
  end if;
end getBindingExp;

function buildBinding
  input InstNode node;
  input ReplTree.Tree repl;
  output Expression result;
protected
  Type ty;
algorithm
  ty := InstNode.getType(node);
  ty := Type.mapDims(ty, function applyReplacementsDim(repl = repl));

  result := match ty
    case Type.ARRAY() guard Type.hasKnownSize(ty)
      then Expression.fillType(ty, Expression.EMPTY(Type.arrayElementType(ty)));
    case Type.COMPLEX() then buildRecordBinding(ty.cls, repl);
    else Expression.EMPTY(ty);
  end match;
end buildBinding;

function applyReplacementsDim
  input ReplTree.Tree repl;
  input output Dimension dim;
algorithm
  dim := match dim
    local
      Expression exp;

    case Dimension.EXP()
      algorithm
        exp := Expression.map(dim.exp, function applyReplacements2(repl = repl));
        exp := Ceval.evalExp(exp);
      then
        Dimension.fromExp(exp, Variability.CONSTANT);

    else dim;
  end match;
end applyReplacementsDim;

function buildRecordBinding
  input InstNode recordNode;
  input ReplTree.Tree repl;
  output Expression result;
protected
  Class cls = InstNode.getClass(recordNode);
  array<InstNode> comps;
  list<Expression> bindings;
  Expression exp;
algorithm
  result := match cls
    case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps))
      algorithm
        bindings := {};

        for i in arrayLength(comps):-1:1 loop
          bindings := Expression.makeMutable(getBindingExp(comps[i], repl)) :: bindings;
        end for;
      then
        Expression.RECORD(InstNode.scopePath(recordNode), cls.ty, bindings);

    case Class.TYPED_DERIVED() then buildRecordBinding(cls.baseClass, repl);
  end match;
end buildRecordBinding;

function addInputReplacement
  input InstNode node;
  input String prefix = "";
  input Expression argument;
  input output ReplTree.Tree repl;
algorithm
  repl := ReplTree.add(repl, prefix + InstNode.name(node), argument);
end addInputReplacement;

function applyBindingReplacement
  input String name;
  input Expression exp;
  input ReplTree.Tree repl;
  output Expression outExp;
algorithm
  outExp := Expression.map(exp, function applyReplacements2(repl = repl));
end applyBindingReplacement;

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

    case Expression.CREF() then applyReplacementCref(repl, exp.cref, exp);
    else exp;
  end match;
end applyReplacements2;

function applyReplacementCref
  input ReplTree.Tree repl;
  input ComponentRef cref;
  input Expression exp;
  output Expression outExp;
protected
  list<ComponentRef> cref_parts;
  Option<Expression> repl_exp;
  InstNode parent, node;
algorithm
  // Explode the cref into a list of parts in reverse order.
  cref_parts := ComponentRef.toListReverse(cref);

  // If the list is empty it's probably an iterator or _, which shouldn't be replaced.
  if listEmpty(cref_parts) then
    outExp := exp;
  else
    // Look up the replacement for the first part in the replacement tree.
    parent := ComponentRef.node(listHead(cref_parts));
    repl_exp := ReplTree.getOpt(repl, InstNode.name(parent));

    if isSome(repl_exp) then
      SOME(outExp) := repl_exp;
    else
      outExp := exp;
      return;
    end if;

    outExp := Expression.applySubscripts(ComponentRef.getSubscripts(listHead(cref_parts)), outExp);
    cref_parts := listRest(cref_parts);

    if not listEmpty(cref_parts) then
      try
        // If the cref consists of more than one identifier we need to look up
        // the corresponding record field in the expression.
        for cr in cref_parts loop
          node := ComponentRef.node(cr);
          outExp := Expression.makeImmutable(outExp);
          outExp := Expression.lookupRecordField(InstNode.name(node), outExp);
          outExp := Expression.applySubscripts(ComponentRef.getSubscripts(cr), outExp);
        end for;
      else
        Error.assertion(false, getInstanceName() + " could not find replacement for " +
          ComponentRef.toString(cref), sourceInfo());
      end try;
    end if;
  end if;
end applyReplacementCref;

function optimizeBody
  input output list<Statement> body;
algorithm
  body := list(Statement.map(s, optimizeStatement) for s in body);
end optimizeBody;

function optimizeStatement
  input output Statement stmt;
algorithm
  () := match stmt
    local
      Expression iter_exp;

    // Replace iterators in for loops with mutable expressions, so we don't need
    // to do it each time we enter a for loop during evaluation.
    case Statement.FOR()
      algorithm
        // Make a mutable expression with a placeholder value.
        iter_exp := Expression.makeMutable(Expression.EMPTY(Type.UNKNOWN()));
        // Replace the iterator with the expression in the body of the for loop.
        stmt.body := list(
          Statement.mapExp(s, function Expression.replaceIterator(
            iterator = stmt.iterator, iteratorValue = iter_exp))
          for s in stmt.body);
        // Replace the iterator node with the mutable expression too.
        stmt.iterator := InstNode.EXP_NODE(iter_exp);
      then
        ();

    else ();
  end match;
end optimizeStatement;

function createResult
  input ReplTree.Tree repl;
  input list<InstNode> outputs;
  output Expression exp;
protected
  list<Expression> expl;
  list<Type> types;
  Expression e;
algorithm
  if listLength(outputs) == 1 then
    exp := Ceval.evalExp(ReplTree.get(repl, InstNode.name(listHead(outputs))));
    assertAssignedOutput(listHead(outputs), exp);
  else
    expl := {};
    types := {};

    for o in outputs loop
      e := Ceval.evalExp(ReplTree.get(repl, InstNode.name(o)));
      assertAssignedOutput(o, e);
      expl := e :: expl;
    end for;

    expl := listReverseInPlace(expl);
    types := list(Expression.typeOf(e) for e in expl);
    exp := Expression.TUPLE(Type.TUPLE(types, NONE()), expl);
  end if;
end createResult;

function assertAssignedOutput
  input InstNode outputNode;
  input Expression value;
algorithm
  () := match value
    case Expression.EMPTY()
      algorithm
        Error.addSourceMessage(Error.UNASSIGNED_FUNCTION_OUTPUT,
          {InstNode.name(outputNode)}, InstNode.info(outputNode));
      then
        fail();

    else ();
  end match;
end assertAssignedOutput;

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
  // adrpo: we really need some error handling here to detect which statement cannot be evaluated
  // try
  ctrl := match stmt
    case Statement.ASSIGNMENT() then evaluateAssignment(stmt.lhs, stmt.rhs, stmt.source);
    case Statement.FOR()        then evaluateFor(stmt.iterator, stmt.range, stmt.body, stmt.source);
    case Statement.IF()         then evaluateIf(stmt.branches, stmt.source);
    case Statement.ASSERT()     then evaluateAssert(stmt.condition, stmt);
    case Statement.NORETCALL()  then evaluateNoRetCall(stmt.exp, stmt.source);
    case Statement.WHILE()      then evaluateWhile(stmt.condition, stmt.body, stmt.source);
    case Statement.RETURN()     then FlowControl.RETURN;
    case Statement.BREAK()      then FlowControl.BREAK;
    else
      algorithm
        Error.assertion(false, getInstanceName() + " failed on " + anyString(stmt) + "\n", sourceInfo());
      then
        fail();

  end match;
  //else
  //   Error.assertion(false, getInstanceName() + " failed to evaluate statement " + Statement.toString(stmt) + "\n", sourceInfo());
  //   fail();
  //end try;
end evaluateStatement;

function evaluateAssignment
  input Expression lhsExp;
  input Expression rhsExp;
  input DAE.ElementSource source;
  output FlowControl ctrl = FlowControl.NEXT;
algorithm
  assignVariable(lhsExp, Ceval.evalExp(rhsExp, EvalTarget.STATEMENT(source)));
end evaluateAssignment;

public
function assignVariable
  input Expression variable;
  input Expression value;
algorithm
  () := match (variable, value)
    local
      Expression var, val;
      list<Expression> vals;
      Mutable<Expression> var_ptr;

    case (Expression.MUTABLE(exp = var_ptr), _)
      algorithm
        Mutable.update(var_ptr, assignExp(Mutable.access(var_ptr), value));
      then
        ();

    case (Expression.TUPLE(), Expression.TUPLE(elements = vals))
      algorithm
        for var in variable.elements loop
          val :: vals := vals;
          assignVariable(var, val);
        end for;
      then
        ();

    case (Expression.SUBSCRIPTED_EXP(exp = Expression.MUTABLE(exp = var_ptr)), _)
      algorithm
        assignSubscriptedVariable(var_ptr, variable.subscripts, value);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " failed on " +
          Expression.toString(variable) + " := " + Expression.toString(value), sourceInfo());
      then
        fail();

  end match;
end assignVariable;

protected
function assignSubscriptedVariable
  input Mutable<Expression> variable;
  input list<Subscript> subscripts;
  input Expression value;
protected
  list<Subscript> subs;
algorithm
  subs := list(Subscript.eval(s) for s in subscripts);
  Mutable.update(variable, assignArrayElement(Mutable.access(variable), subs, value));
end assignSubscriptedVariable;

function assignArrayElement
  input Expression arrayExp;
  input list<Subscript> subscripts;
  input Expression value;
  output Expression result;
protected
  Expression sub, val;
  list<Subscript> rest_subs;
  Integer idx;
  list<Expression> subs, vals;
algorithm
  result := match (arrayExp, subscripts)
    case (Expression.ARRAY(), Subscript.INDEX(sub) :: rest_subs) guard Expression.isScalarLiteral(sub)
      algorithm
        idx := Expression.toInteger(sub);

        if listEmpty(rest_subs) then
          arrayExp.elements := List.set(arrayExp.elements, idx, value);
        else
          arrayExp.elements := List.set(arrayExp.elements, idx,
            assignArrayElement(listGet(arrayExp.elements, idx), rest_subs, value));
        end if;
      then
        arrayExp;

    case (Expression.ARRAY(), Subscript.SLICE(sub) :: rest_subs)
      algorithm
        subs := Expression.arrayElements(sub);
        vals := Expression.arrayElements(value);

        if listEmpty(rest_subs) then
          for s in subs loop
            val :: vals := vals;
            idx := Expression.toInteger(s);
            arrayExp.elements := List.set(arrayExp.elements, idx, val);
          end for;
        else
          for s in subs loop
            val :: vals := vals;
            idx := Expression.toInteger(s);
            arrayExp.elements := List.set(arrayExp.elements, idx,
              assignArrayElement(listGet(arrayExp.elements, idx), rest_subs, val));
          end for;
        end if;
      then
        arrayExp;

    case (Expression.ARRAY(), Subscript.WHOLE() :: rest_subs)
      algorithm
        if not listEmpty(rest_subs) then
          arrayExp.elements := list(assignArrayElement(e, rest_subs, v) threaded for
            e in arrayExp.elements, v in Expression.arrayElements(value));
        end if;
      then
        arrayExp;

    else
      algorithm
        Error.assertion(false, getInstanceName() + ": unimplemented case for " +
          Expression.toString(arrayExp) +
          Subscript.toStringList(subscripts) + " = " +
          Expression.toString(value), sourceInfo());
      then
        fail();

  end match;
end assignArrayElement;

function assignExp
  input Expression lhs;
  input Expression rhs;
  output Expression result;
algorithm
  result := match lhs
    case Expression.RECORD()
      then assignRecord(lhs, rhs);

    // TODO: Handle arrays.

    else rhs;
  end match;
end assignExp;

function assignRecord
  input Expression lhs;
  input Expression rhs;
  output Expression result;
algorithm
  result := match rhs
    local
      list<Expression> elems;
      Expression e, val;
      ClassTree cls_tree;
      array<InstNode> comps;
      Option<Expression> binding_exp;
      Type ty;

    case Expression.RECORD()
      algorithm
        Expression.RECORD(elements = elems) := lhs;

        for v in rhs.elements loop
          e :: elems := elems;
          assignVariable(e, v);
        end for;
      then
        lhs;

    case Expression.CREF()
      algorithm
        Expression.RECORD(elements = elems) := lhs;
        cls_tree := Class.classTree(InstNode.getClass(ComponentRef.node(rhs.cref)));
        comps := ClassTree.getComponents(cls_tree);

        for c in comps loop
          e :: elems := elems;
          ty := InstNode.getType(c);
          val := Expression.CREF(Type.liftArrayLeftList(ty, Type.arrayDims(rhs.ty)),
                                 ComponentRef.prefixCref(c, ty, {}, rhs.cref));
          assignVariable(e, val);
        end for;
      then
        lhs;

    else rhs;
  end match;
end assignRecord;

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
  range_exp := Ceval.evalExp(Util.getOption(range), EvalTarget.STATEMENT(source));
  range_iter := RangeIterator.fromExp(range_exp);

  if RangeIterator.hasNext(range_iter) then
    InstNode.EXP_NODE(exp = Expression.MUTABLE(exp = iter_exp)) := iterator;

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
  input DAE.ElementSource source;
  output FlowControl ctrl;
protected
  Expression cond;
  list<Statement> body;
algorithm
  for branch in branches loop
    (cond, body) := branch;

    if Expression.isTrue(Ceval.evalExp(cond, EvalTarget.STATEMENT(source))) then
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
  Expression cond, msg, lvl;
  DAE.ElementSource source;
  EvalTarget target = EvalTarget.STATEMENT(Statement.source(assertStmt));
algorithm
  if Expression.isFalse(Ceval.evalExp(condition, target)) then
    Statement.ASSERT(message = msg, level = lvl, source = source) := assertStmt;
    msg := Ceval.evalExp(msg, target);
    lvl := Ceval.evalExp(lvl, target);

    () := match (msg, lvl)
      case (Expression.STRING(), Expression.ENUM_LITERAL(name = "warning"))
        algorithm
          Error.addSourceMessage(Error.ASSERT_TRIGGERED_WARNING, {msg.value}, ElementSource.getInfo(source));
        then
          ();

      case (Expression.STRING(), Expression.ENUM_LITERAL(name = "error"))
        algorithm
          Error.addSourceMessage(Error.ASSERT_TRIGGERED_ERROR, {msg.value}, ElementSource.getInfo(source));
          ctrl := FlowControl.ASSERTION;
        then
          ();

      else
        algorithm
          Error.assertion(false, getInstanceName() + " failed to evaluate assert(false, " +
            Expression.toString(msg) + ", " + Expression.toString(lvl) + ")", sourceInfo());
        then
          fail();
    end match;
  end if;
end evaluateAssert;

function evaluateNoRetCall
  input Expression callExp;
  input DAE.ElementSource source;
  output FlowControl ctrl = FlowControl.NEXT;
algorithm
  Ceval.evalExp(callExp, EvalTarget.STATEMENT(source));
end evaluateNoRetCall;

function evaluateWhile
  input Expression condition;
  input list<Statement> body;
  input DAE.ElementSource source;
  output FlowControl ctrl = FlowControl.NEXT;
protected
  Integer i = 0, limit = Flags.getConfigInt(Flags.EVAL_LOOP_LIMIT);
  EvalTarget target = EvalTarget.STATEMENT(source);
algorithm
  while Expression.isTrue(Ceval.evalExp(condition, target)) loop
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

function isKnownExternalFunc
  input String name;
  input Option<SCode.Annotation> ann;
  output Boolean isKnown;
algorithm
  if isKnownLibrary(ann) then
    isKnown := true;
  else
    isKnown := match name
      case "OpenModelica_regex" then true;
      else false;
    end match;
  end if;
end isKnownExternalFunc;

function isKnownLibrary
  input Option<SCode.Annotation> extAnnotation;
  output Boolean isKnown = false;
protected
  SCode.Annotation ann;
  Option<Absyn.Exp> oexp;
algorithm
  if isSome(extAnnotation) then
    SOME(ann) := extAnnotation;
    oexp := SCode.getModifierBinding(SCode.lookupNamedAnnotation(ann, "Library"));

    if isSome(oexp) then
      isKnown := isKnownLibraryExp(Util.getOption(oexp));
    end if;
  end if;
end isKnownLibrary;

function isKnownLibraryExp
  input Absyn.Exp exp;
  output Boolean isKnown;
algorithm
  isKnown := match exp
    case Absyn.STRING("ModelicaExternalC") then true;
    case Absyn.STRING("ModelicaIO") then true;
    case Absyn.ARRAY() then List.exist(exp.arrayExp, isKnownLibraryExp);
    else false;
  end match;
end isKnownLibraryExp;

constant list<String> FILE_TYPE_NAMES = {"NoFile", "RegularFile", "Directory", "SpecialFile"};
constant Absyn.Path FILE_TYPE_PATH = Absyn.Path.QUALIFIED("Modelica",
  Absyn.Path.QUALIFIED("Utilities", Absyn.Path.QUALIFIED("Types", Absyn.Path.IDENT("FileType"))));
constant Type FILE_TYPE_TYPE = Type.ENUMERATION(FILE_TYPE_PATH, FILE_TYPE_NAMES);

constant list<Expression> FILE_TYPE_LITERALS = {
  Expression.ENUM_LITERAL(FILE_TYPE_TYPE, "NoFile", 1),
  Expression.ENUM_LITERAL(FILE_TYPE_TYPE, "RegularFile", 2),
  Expression.ENUM_LITERAL(FILE_TYPE_TYPE, "Directory", 3),
  Expression.ENUM_LITERAL(FILE_TYPE_TYPE, "SpecialFile", 4)
};

constant list<String> COMPARE_NAMES = {"Less", "Equal", "Greater"};
constant Absyn.Path COMPARE_PATH = Absyn.Path.QUALIFIED("Modelica",
  Absyn.Path.QUALIFIED("Utilities", Absyn.Path.QUALIFIED("Types", Absyn.Path.IDENT("Compare"))));
constant Type COMPARE_TYPE = Type.ENUMERATION(COMPARE_PATH, COMPARE_NAMES);

constant list<Expression> COMPARE_LITERALS = {
  Expression.ENUM_LITERAL(COMPARE_TYPE, "Less", 1),
  Expression.ENUM_LITERAL(COMPARE_TYPE, "Equal", 2),
  Expression.ENUM_LITERAL(COMPARE_TYPE, "Greater", 3)
};

function evaluateKnownExternal
  input String name;
  input list<Expression> args;
  output Expression result;
algorithm
  result := match (name, args)
    local
      String s1, s2;
      Integer i, i2;
      Boolean b;
      Real r;
      Integer dims[2];

    case ("ModelicaInternal_countLines", {Expression.STRING(s1)})
      then Expression.INTEGER(ModelicaExternalC.Streams_countLines(s1));

    case ("ModelicaInternal_fullPathName", {Expression.STRING(s1)})
      then Expression.STRING(ModelicaExternalC.File_fullPathName(s1));

    case ("ModelicaInternal_print", {Expression.STRING(s1), Expression.STRING(s2)})
      algorithm
        ModelicaExternalC.Streams_print(s1, s2);
      then
        Expression.INTEGER(0);

    case ("ModelicaInternal_readLine", {Expression.STRING(s1), Expression.INTEGER(i)})
      algorithm
        (s1, b) := ModelicaExternalC.Streams_readLine(s1, i);
      then
        Expression.TUPLE(Type.TUPLE({Type.STRING(), Type.BOOLEAN()}, NONE()),
                        {Expression.STRING(s1), Expression.BOOLEAN(b)});

    case ("ModelicaInternal_stat", {Expression.STRING(s1)})
      algorithm
        i := ModelicaExternalC.File_stat(s1);
      then
        listGet(FILE_TYPE_LITERALS, i);

    case ("ModelicaStreams_closeFile", {Expression.STRING(s1)})
      algorithm
        ModelicaExternalC.Streams_close(s1);
      then
        Expression.INTEGER(0);

    case ("ModelicaStrings_compare", {Expression.STRING(s1), Expression.STRING(s2), Expression.BOOLEAN(b)})
      algorithm
        i := ModelicaExternalC.Strings_compare(s1, s2, b);
      then
        listGet(COMPARE_LITERALS, i);

    case ("ModelicaStrings_length", {Expression.STRING(s1)})
      then Expression.INTEGER(stringLength(s1));

    case ("ModelicaStrings_scanReal", {Expression.STRING(s1), Expression.INTEGER(i), Expression.BOOLEAN(b)})
      algorithm
        (i, r) := ModelicaExternalC.Strings_advanced_scanReal(s1, i, b);
      then
        Expression.TUPLE(Type.TUPLE({Type.INTEGER(), Type.BOOLEAN()}, NONE()),
                         {Expression.INTEGER(i), Expression.REAL(r)});

    case ("ModelicaStrings_skipWhiteSpace", {Expression.STRING(s1), Expression.INTEGER(i)})
      then Expression.INTEGER(ModelicaExternalC.Strings_advanced_skipWhiteSpace(s1, i));

    case ("ModelicaStrings_substring", {Expression.STRING(s1), Expression.INTEGER(i), Expression.INTEGER(i2)})
      then Expression.STRING(System.substring(s1, i, i2));

    case ("OpenModelica_regex", _) then evaluateOpenModelicaRegex(args);

    case ("ModelicaIO_readMatrixSizes", {Expression.STRING(s1), Expression.STRING(s2)})
      algorithm
        dims := ModelicaExternalC.ModelicaIO_readMatrixSizes(s1, s2);
      then
        Expression.ARRAY(Type.INTEGER(), {Expression.INTEGER(dims[1]), Expression.INTEGER(dims[2])}, true);

    case ("ModelicaIO_readRealMatrix",
        {Expression.STRING(s1), Expression.STRING(s2), Expression.INTEGER(i), Expression.INTEGER(i2), Expression.BOOLEAN(b)})
      then evaluateModelicaIO_readRealMatrix(s1, s2, i, i2, b);

    else
      algorithm
        Error.assertion(false, getInstanceName() + ": failed to evaluate " + name, sourceInfo());
      then
        fail();
  end match;
end evaluateKnownExternal;

function evaluateOpenModelicaRegex
  input list<Expression> args;
  output Expression result;
protected
  Integer n, i;
  String str, re;
  Boolean extended, insensitive;
  list<String> strs;
  list<Expression> expl;
  Type strs_ty;
  Expression strs_exp;
algorithm
  result := match args
    case {Expression.STRING(str), Expression.STRING(re), Expression.INTEGER(i),
          Expression.BOOLEAN(extended), Expression.BOOLEAN(insensitive)}
      algorithm
        (n, strs) := System.regex(str, re, i, extended, insensitive);
        expl := list(Expression.STRING(s) for s in strs);
        strs_ty := Type.ARRAY(Type.STRING(), {Dimension.fromInteger(i)});
        strs_exp := Expression.makeArray(strs_ty, expl, true);
      then
        Expression.TUPLE(Type.TUPLE({Type.INTEGER(), strs_ty}, NONE()),
                         {Expression.INTEGER(n), strs_exp});

    else
      algorithm
        Error.assertion(false, getInstanceName() + " failed on OpenModelica_regex" +
          List.toString(args, Expression.toString, "", "(", ", ", ")", true), sourceInfo());
      then
        fail();
  end match;
end evaluateOpenModelicaRegex;

function evaluateModelicaIO_readRealMatrix
  input String fileName;
  input String matrixName;
  input Integer nrow;
  input Integer ncol;
  input Boolean verboseRead;
  output Expression result;
protected
  Real[nrow, ncol] matrix;
  list<Expression> row, rows = {};
  Type ty;
algorithm
  matrix := ModelicaExternalC.ModelicaIO_readRealMatrix(fileName, matrixName, nrow, ncol, verboseRead);
  ty := Type.ARRAY(Type.REAL(), {Dimension.fromInteger(ncol)});

  for r in 1:nrow loop
    row := {};
    for c in 1:ncol loop
      row := Expression.REAL(matrix[r, c]) :: row;
    end for;
    rows := Expression.ARRAY(ty, row, literal = true) :: rows;
  end for;

  ty := Type.liftArrayLeft(ty, Dimension.fromInteger(nrow));
  result := Expression.ARRAY(ty, rows, literal = true);
end evaluateModelicaIO_readRealMatrix;

function evaluateExternal2
  input String name;
  input Function fn;
  input list<Expression> args;
  input list<Expression> extArgs;
  output Expression result;
protected
  ReplTree.Tree repl;
  list<Expression> ext_args;
algorithm
  repl := createReplacements(fn, args);
  ext_args := list(Expression.map(e, function applyReplacements2(repl = repl)) for e in extArgs);
  evaluateExternal3(name, ext_args);
  result := createResult(repl, fn.outputs);
end evaluateExternal2;

function evaluateExternal3
  input String name;
  input list<Expression> args;
algorithm
  () := match name
    case "dgeev"  algorithm EvalFunctionExt.Lapack_dgeev(args);  then ();
    case "dgegv"  algorithm EvalFunctionExt.Lapack_dgegv(args);  then ();
    case "dgels"  algorithm EvalFunctionExt.Lapack_dgels(args);  then ();
    case "dgelsx" algorithm EvalFunctionExt.Lapack_dgelsx(args); then ();
    case "dgelsy" algorithm EvalFunctionExt.Lapack_dgelsy(args); then ();
    case "dgesv"  algorithm EvalFunctionExt.Lapack_dgesv(args);  then ();
    case "dgglse" algorithm EvalFunctionExt.Lapack_dgglse(args); then ();
    case "dgtsv"  algorithm EvalFunctionExt.Lapack_dgtsv(args);  then ();
    case "dgbsv"  algorithm EvalFunctionExt.Lapack_dgtsv(args);  then ();
    case "dgesvd" algorithm EvalFunctionExt.Lapack_dgesvd(args); then ();
    case "dgetrf" algorithm EvalFunctionExt.Lapack_dgetrf(args); then ();
    case "dgetrs" algorithm EvalFunctionExt.Lapack_dgetrs(args); then ();
    case "dgetri" algorithm EvalFunctionExt.Lapack_dgetri(args); then ();
    case "dgeqpf" algorithm EvalFunctionExt.Lapack_dgeqpf(args); then ();
    case "dorgqr" algorithm EvalFunctionExt.Lapack_dorgqr(args); then ();
  end match;
end evaluateExternal3;

annotation(__OpenModelica_Interface="frontend");
end NFEvalFunction;
