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

import Binding = NFBinding;
import Call = NFCall;
import Class = NFClass;
import Component = NFComponent;
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import Expression = NFExpression;
import NFCeval.EvalTarget;
import NFClassTree.ClassTree;
import NFFunction.Function;
import NFInstNode.InstNode;
import NFInstNode.CachedData;
import Record = NFRecord;
import Sections = NFSections;
import Statement = NFStatement;
import Subscript = NFSubscript;
import Type = NFType;

protected
import Array;
import Autoconf;
import Ceval = NFCeval;
import DAE;
import ElementSource;
import ErrorExt;
import EvalFunctionExt = NFEvalFunctionExt;
import FFI;
import Flags;
import MetaModelica.Dangerous.*;
import NFPrefixes.Variability;
import RangeIterator = NFRangeIterator;
import SCode;
import SCodeUtil;
import Settings;
import System;
import Testsuite;
import UnorderedMap;

type FlowControl = enumeration(NEXT, CONTINUE, BREAK, RETURN, ASSERTION);
type ArgumentMap = UnorderedMap<InstNode, Expression>;

public
function evaluate
  input Function fn;
  input list<Expression> args;
  input EvalTarget target;
  output Expression result;
algorithm
  if Function.isExternal(fn) then
    result := evaluateExternal(fn, args, target);
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
  ArgumentMap arg_map;
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
      {String(limit), AbsynUtil.pathString(Function.name(fn))}, InstNode.info(fn.node));
    fail();
  end if;

  Pointer.update(call_counter, call_count);

  try
    fn_body := Function.getBody(fn);
    arg_map := createArgumentMap(fn.inputs, fn.outputs, fn.locals, args, mutableParams = true);
    // TODO: Also apply replacements to the replacements themselves, i.e. the
    //       bindings of the function parameters. But they probably need to be
    //       sorted by dependencies first.
    fn_body := applyReplacements(arg_map, fn_body);
    fn_body := optimizeBody(fn_body);
    ctrl := evaluateStatements(fn_body);

    if ctrl <> FlowControl.ASSERTION then
      result := createResult(arg_map, fn.outputs);
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
  input EvalTarget target;
  output Expression result;
protected
  String name, lang;
  ComponentRef output_ref;
  Option<SCode.Annotation> ann;
  list<Expression> ext_args;
algorithm
  Sections.EXTERNAL(name = name, args = ext_args, outputRef = output_ref, language = lang, ann = ann) :=
    Class.getSections(InstNode.getClass(fn.node));

  result := matchcontinue lang
    case "builtin"
      // Functions defined as 'external "builtin"', delegate to Ceval.
      then Ceval.evalBuiltinCall(fn, args, EvalTarget.IGNORE_ERRORS());

    case "FORTRAN 77"
      // This had better be a Lapack function.
      then evaluateExternal2(name, fn, args, ext_args);

    case _
      // For anything else, try to call the function via FFI.
      then callExternalFunction(name, fn, args, ext_args, output_ref, ann);

    else
      algorithm
        if EvalTarget.hasInfo(target) then
          Error.addSourceMessage(Error.FAILED_TO_EVALUATE_FUNCTION,
            {AbsynUtil.pathString(fn.path)}, EvalTarget.getInfo(target));
        end if;
      then
        fail();
  end matchcontinue;
end evaluateExternal;

function evaluateRecordConstructor
  "Evaluates a default record constructor call by replacing any field references
   with the given arguments, optionally constant evaluating the resulting expression.

   Example:
     record R
       Real x;
       constant Real y = x / 2.0;
       Real z;
     end R;

     CALL(R, {1.0, 2.0}) => RECORD(R, {1.0, 0.5, 2.0});
   "
  input Function fn;
  input Type ty;
  input list<Expression> args;
  input Boolean evaluate = true;
  output Expression result;
protected
  ArgumentMap arg_map;
  list<Expression> expl = {};
  InstNode node, out_ty;
algorithm
  // Map the record fields to the arguments of the constructor.
  arg_map := createArgumentMap(fn.inputs, {}, fn.locals, args, mutableParams = false);

  // Use the node of the return type to determine the order of the variables,
  // since they might be reordered in the record constructor.
  Type.COMPLEX(cls = out_ty) := fn.returnType;

  // Fetch the new binding expressions for all the variables, both inputs and locals.
  for c in ClassTree.getComponents(Class.classTree(InstNode.getClass(out_ty))) loop
    expl := UnorderedMap.getOrFail(c, arg_map) :: expl;
  end for;

  // Create a new record expression from the mapped arguments.
  result := Expression.makeRecord(Function.name(fn), ty, listReverseInPlace(expl));

  // Constant evaluate the expression if requested.
  if evaluate then
    result := Ceval.evalExp(result);
  end if;
end evaluateRecordConstructor;

protected

function createArgumentMap
  input list<InstNode> inputs;
  input list<InstNode> outputs;
  input list<InstNode> locals;
  input list<Expression> args;
  input Boolean mutableParams;
  input Boolean buildArrayBinding = true;
  output ArgumentMap map;
protected
  Expression arg;
  list<Expression> rest_args = args;
  Function fn;
  CachedData cache;
algorithm
  map := UnorderedMap.new<Expression>(InstNode.hash, InstNode.refEqual);

  // Add inputs to the argument map. Inputs are never mutable.
  for i in inputs loop
    arg :: rest_args := rest_args;
    UnorderedMap.add(i, arg, map);

    // If the argument is a function partial application, also add the function
    // node to the map so we can replace calls to it with the correct function.
    if Expression.isFunctionPointer(arg) then
      for fn in Function.getCachedFuncs(i) loop
        UnorderedMap.add(fn.node, arg, map);
      end for;
    end if;
  end for;

  // Add outputs and local variables to the argument map.
  // They sometimes need to be mutable and sometimes not.
  if mutableParams then
    List.fold(outputs, function addMutableArgument(buildArrayBinding = buildArrayBinding), map);
    List.fold(locals, function addMutableArgument(buildArrayBinding = buildArrayBinding), map);
  else
    List.fold(outputs, function addImmutableArgument(buildArrayBinding = buildArrayBinding), map);
    List.fold(locals, function addImmutableArgument(buildArrayBinding = buildArrayBinding), map);
  end if;

  // Apply the arguments to the arguments themselves. This is done after
  // building the map to make sure all the arguments are available.
  UnorderedMap.apply(map, function applyBindingReplacement(map = map));
end createArgumentMap;

function addMutableArgument
  input InstNode node;
  input output ArgumentMap map;
  input Boolean buildArrayBinding;
protected
  Expression exp;
algorithm
  exp := getBindingExp(node, map, mutableParams = true, buildArrayBinding = buildArrayBinding);
  exp := Expression.makeMutable(exp);
  UnorderedMap.add(node, exp, map);
end addMutableArgument;

function addImmutableArgument
  input InstNode node;
  input output ArgumentMap map;
  input Boolean buildArrayBinding;
protected
  Expression exp;
algorithm
  exp := getBindingExp(node, map, mutableParams = false, buildArrayBinding = buildArrayBinding);
  UnorderedMap.add(node, exp, map);
end addImmutableArgument;

function getBindingExp
  input InstNode node;
  input ArgumentMap map;
  input Boolean mutableParams;
  input Boolean buildArrayBinding;
  output Expression bindingExp;
protected
  Component comp;
  Binding binding;
  Type ty;
algorithm
  comp := InstNode.component(node);
  binding := Component.getBinding(comp);

  if Binding.isBound(binding) then
    bindingExp := Binding.getExp(binding);
  else
    bindingExp := buildBinding(node, map, mutableParams, buildArrayBinding);
  end if;
end getBindingExp;

function buildBinding
  input InstNode node;
  input ArgumentMap map;
  input Boolean mutableParams;
  input Boolean buildArrayBinding;
  output Expression result;
protected
  Type ty;
algorithm
  ty := InstNode.getType(node);
  ty := Type.mapDims(ty, function applyReplacementsDim(map = map));

  result := match ty
    case Type.ARRAY() guard buildArrayBinding and Type.hasKnownSize(ty)
      then Expression.fillType(ty, Expression.EMPTY(Type.arrayElementType(ty)));
    case Type.COMPLEX() then buildRecordBinding(node, map, mutableParams);
    else Expression.EMPTY(ty);
  end match;
end buildBinding;

function applyReplacementsDim
  input ArgumentMap map;
  input output Dimension dim;
algorithm
  dim := match dim
    local
      Expression exp;

    case Dimension.EXP()
      algorithm
        exp := Expression.map(dim.exp, function applyReplacements2(map = map));
        exp := Ceval.evalExp(exp);
      then
        Dimension.fromExp(exp, Variability.CONSTANT);

    else dim;
  end match;
end applyReplacementsDim;

function buildRecordBinding
  "Builds a binding for a record instance that doesn't have an explicit binding.
   Binding expressions will be taken from the record fields when available, and
   filled with empty expressions when not."
  input InstNode recordNode;
  input ArgumentMap map;
  input Boolean mutableParams;
  output Expression result;
protected
  InstNode cls_node = InstNode.classScope(recordNode);
  Class cls = InstNode.getClass(cls_node);
  array<InstNode> comps;
  list<Expression> bindings;
  Expression exp;
  ArgumentMap local_map;
algorithm
  result := match cls
    case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps))
      algorithm
        bindings := {};
        // Create a replacement tree for just the record instance. This is
        // needed for records that contain local references such as:
        //   record R
        //     Real x;
        //     Real y = x;
        //   end R;
        // In that case we need to replace the 'x' in the binding of 'y' with
        // the binding expression of 'x'.
        local_map := UnorderedMap.new<Expression>(InstNode.hash, InstNode.refEqual);

        for comp in comps loop
          exp := getBindingExp(comp, map, mutableParams, buildArrayBinding = true);

          if mutableParams then
            exp := Expression.makeMutable(exp);
          end if;

          UnorderedMap.add(comp, exp, local_map);
        end for;

        // Replace references to record fields with those fields' bindings in the tree.
        UnorderedMap.apply(local_map, function applyBindingReplacement(map = local_map));
        bindings := UnorderedMap.valueList(local_map);
      then
        Expression.makeRecord(InstNode.scopePath(cls_node, includeRoot = true), cls.ty, bindings);

    case Class.TYPED_DERIVED() then buildRecordBinding(cls.baseClass, map, mutableParams);
  end match;
end buildRecordBinding;

function applyBindingReplacement
  input Expression exp;
  input ArgumentMap map;
  output Expression outExp;
algorithm
  outExp := Expression.map(exp, function applyReplacements2(map = map));
end applyBindingReplacement;

function applyReplacements
  input ArgumentMap map;
  input output list<Statement> fnBody;
algorithm
  fnBody := Statement.mapExpList(fnBody,
    function Expression.map(func = function applyReplacements2(map = map)));
end applyReplacements;

function applyReplacements2
  input ArgumentMap map;
  input output Expression exp;
algorithm
  exp := match exp
    case Expression.CREF() then applyReplacementCref(map, exp.cref, exp);
    case Expression.CALL() then applyReplacementCall(map, exp.call, exp);
    case Expression.UNBOX() then exp.exp;
    else exp;
  end match;
end applyReplacements2;

function applyReplacementCref
  input ArgumentMap map;
  input ComponentRef cref;
  input Expression exp;
  output Expression outExp;
protected
  list<ComponentRef> cref_parts;
  Option<Expression> repl_exp;
  InstNode parent, node;
algorithm
  // Explode the cref into a list of parts in reverse order.
  cref_parts := ComponentRef.toListReverse(cref, includeScope = false);

  // If the list is empty it's probably an iterator or _, which shouldn't be replaced.
  if listEmpty(cref_parts) then
    outExp := exp;
  else
    // Look up the replacement for the first part in the replacement tree.
    parent := ComponentRef.node(listHead(cref_parts));
    repl_exp := UnorderedMap.get(parent, map);

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
          outExp := Expression.recordElement(InstNode.name(node), outExp);
          outExp := Expression.applySubscripts(ComponentRef.getSubscripts(cr), outExp);
        end for;
      else
        Error.assertion(false, getInstanceName() + " could not find replacement for " +
          ComponentRef.toString(cref), sourceInfo());
      end try;
    end if;

    outExp := Expression.map(outExp, function applyReplacements2(map = map));
  end if;
end applyReplacementCref;

function applyReplacementCall
  "Checks if a function call refers to a function pointer given as a function
   partial application expression, and if so replaces the call."
  input ArgumentMap map;
  input Call call;
  input Expression exp;
  output Expression outExp;
protected
  InstNode repl_node;
  Option<Expression> repl_oexp;
  Expression repl_exp;
  list<Expression> args;
  list<String> names;
  Function fn;
algorithm
  outExp := match call
    case Call.TYPED_CALL()
      algorithm
        repl_oexp := UnorderedMap.get(call.fn.node, map);

        if isSome(repl_oexp) then
          SOME(repl_exp) := repl_oexp;

          outExp := match repl_exp
            case Expression.CREF(ty = Type.FUNCTION(fn = fn))
              algorithm
                // A function pointer is just a function partial application without any extra arguments.
                call.arguments := mergeFunctionApplicationArgs(call.fn, call.arguments, fn, {}, {});
                call.fn := fn;
              then
                Expression.CALL(call);

            case Expression.PARTIAL_FUNCTION_APPLICATION()
              algorithm
                fn := listHead(Function.getCachedFuncs(ComponentRef.node(repl_exp.fn)));
                // Merge the arguments from the original call with the ones in the function partial application.
                call.arguments := mergeFunctionApplicationArgs(call.fn, call.arguments, fn, repl_exp.args, repl_exp.argNames);
                // Replace the function with the one in the function partial application.
                call.fn := fn;
              then
                Expression.CALL(call);

            else exp;
          end match;
        else
          outExp := exp;
        end if;
      then
        outExp;

    else exp;
  end match;
end applyReplacementCall;

function mergeFunctionApplicationArgs
  input Function oldFn;
  input list<Expression> oldArgs;
  input Function newFn;
  input list<Expression> newArgs;
  input list<String> argNames;
  output list<Expression> outArgs = {};
protected
  UnorderedMap<String, Expression> arg_map;
  list<Expression> args;
algorithm
  arg_map := UnorderedMap.new<Expression>(stringHashDjb2Mod, stringEq);

  // Add default arguments from the slots.
  for s in newFn.slots loop
    if isSome(s.default) then
      UnorderedMap.add(InstNode.name(s.node), Expression.unbox(Util.getOption(s.default)), arg_map);
    end if;
  end for;

  // Add arguments from the function call we're replacing.
  args := oldArgs;
  for i in oldFn.inputs loop
    UnorderedMap.add(InstNode.name(i), Expression.unbox(listHead(args)), arg_map);
    args := listRest(args);
  end for;

  // Add arguments from the function partial application expression.
  args := newArgs;
  for n in argNames loop
    UnorderedMap.add(n, Expression.unbox(listHead(args)), arg_map);
    args := listRest(args);
  end for;

  for i in newFn.inputs loop
    outArgs := UnorderedMap.getOrFail(InstNode.name(i), arg_map) :: outArgs;
  end for;

  outArgs := listReverseInPlace(outArgs);
end mergeFunctionApplicationArgs;

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
        iter_exp := Expression.makeMutable(Expression.EMPTY(InstNode.getType(stmt.iterator)));
        // Replace the iterator with the expression in the body of the for loop.
        stmt.body := Statement.replaceIteratorList(stmt.body, stmt.iterator, iter_exp);
        // Replace the iterator node with the mutable expression too.
        stmt.iterator := InstNode.EXP_NODE(iter_exp);
      then
        ();

    else ();
  end match;
end optimizeStatement;

function createResult
  input ArgumentMap map;
  input list<InstNode> outputs;
  output Expression exp;
protected
  list<Expression> expl;
  list<Type> types;
  Expression e;
algorithm
  if listLength(outputs) == 1 then
    exp := Ceval.evalExp(UnorderedMap.getOrFail(listHead(outputs), map));
    assertAssignedOutput(listHead(outputs), exp);
  else
    expl := {};
    types := {};

    for o in outputs loop
      e := Ceval.evalExp(UnorderedMap.getOrFail(o, map));
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

    // variable := value
    case (Expression.MUTABLE(exp = var_ptr), _)
      algorithm
        Mutable.update(var_ptr, assignExp(Mutable.access(var_ptr), value));
      then
        ();

    // (var1, var2, ...) := (value1, value2, ...)
    case (Expression.TUPLE(), Expression.TUPLE(elements = vals))
      algorithm
        for var in variable.elements loop
          val :: vals := vals;
          assignVariable(var, val);
        end for;
      then
        ();

    // variable[subscript1, subscript2, ...] := value
    case (Expression.SUBSCRIPTED_EXP(exp = Expression.MUTABLE(exp = var_ptr)), _)
      algorithm
        assignSubscriptedVariable(var_ptr, variable.subscripts, value);
      then
        ();

    // _ := value
    case (Expression.CREF(cref = ComponentRef.WILD()), _)
      then ();

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
        if listEmpty(rest_subs) then
          arrayExp.elements := Expression.arrayElements(value);
        else
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
  output FlowControl ctrl = FlowControl.NEXT;
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

function evaluateExternal2
  input String name;
  input Function fn;
  input list<Expression> args;
  input list<Expression> extArgs;
  output Expression result;
protected
  ArgumentMap map;
  list<Expression> ext_args;
algorithm
  map := createArgumentMap(fn.inputs, fn.outputs, fn.locals, args, mutableParams = true);
  ext_args := list(Expression.map(e, function applyReplacements2(map = map)) for e in extArgs);
  evaluateExternal3(name, ext_args);
  result := createResult(map, fn.outputs);
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
    else fail();
  end match;
end evaluateExternal3;

function callExternalFunction
  "Calls an external function using the FFI interface."
  input String extName;
  input Function fn;
  input list<Expression> args;
  input list<Expression> extArgs;
  input ComponentRef outputRef;
  input Option<SCode.Annotation> extAnnotation;
  input Boolean debug = false;
  output Expression result;
protected
  SourceInfo info;
  String pkg_name;
  Integer lib_handle, fn_handle;
  array<Expression> mapped_args;
  array<FFI.ArgSpec> specs;
  Type ret_ty;
  Expression res;
  list<Expression> output_vals;
algorithm
  info := InstNode.info(fn.node);
  checkExtReturnValue(outputRef, info);

  pkg_name := InstNode.name(InstNode.libraryScope(fn.node));
  (lib_handle, fn_handle) := loadLibraryFunction(extName, pkg_name, extAnnotation, debug, info);

  (mapped_args, specs) := mapExternalArgs(fn, args, extArgs);
  ret_ty := if ComponentRef.isCref(outputRef) then ComponentRef.nodeType(outputRef) else Type.NORETCALL();
  (res, output_vals) := FFI.callFunction(fn_handle, mapped_args, specs, ret_ty);

  freeLibraryFunction(lib_handle, fn_handle, debug);

  if listEmpty(output_vals) then
    // No output parameters, just return the return value.
    result := res;
  else
    // Some output parameters, might require constructing a tuple.
    result := makeExternalResult(res :: output_vals, outputRef, extArgs, fn.outputs);
  end if;
end callExternalFunction;

function loadLibraryFunction
  "Tries to load the function with the given function that's either linked into
   the compiler itself or in a shared library provided by the user. Returns
   handles to the shared library and function that should to be freed by
   freeLibraryFunction when no longer needed."
  input String fnName;
  input String libName;
  input Option<SCode.Annotation> extAnnotation;
  input Boolean debug;
  input SourceInfo info;
  output Integer libHandle;
  output Integer fnHandle;
protected
  SCode.Annotation ann;
  list<String> libs = {}, dirs = {}, paths = {};
  Boolean found = false;
  String installLibDir = Settings.getInstallationDirectoryPath()+"/lib/"+Autoconf.triple+"/omc";
algorithm
  // Read libraries and library directories from the annotation if it exists.
  if isSome(extAnnotation) then
    SOME(ann) := extAnnotation;
    libs := parseExternalAnnotation("Library", ann);
    dirs := parseExternalAnnotation("LibraryDirectory", ann);
  end if;

  // Append the default path and remove any duplicates.
  dirs := ("modelica://" + libName + "/Resources/Library") :: dirs;
  libs := List.unique(libs);
  dirs := List.unique(dirs);

  // Create paths for any combination of library and library directory.
  for lib in libs loop
    // For functions that are linked into the compiler itself we pass an empty
    // string to loadLibrary.
    if stringEmpty(lib) then
      paths := "" :: paths;
      continue;
    end if;

    if Autoconf.os == "linux" then
      lib := "lib" + lib;
    end if;

    lib := lib + Autoconf.dllExt;

    for dir in dirs loop
      // Search for both dir/lib and e.g. dir/linux64/lib.
      paths := (dir + "/" + lib) :: paths;
      paths := (dir + "/" + System.modelicaPlatform() + "/" + lib) :: paths;
    end for;
    paths := installLibDir + "/" + lib :: paths;
  end for;

  // If no Library annotation was given, append an empty string to search for
  // functions linked into the compiler itself.
  if listEmpty(libs) then
    paths := "" :: paths;
  end if;

  // Disable error messages, we don't care if some paths can't be found.
  ErrorExt.setCheckpoint(getInstanceName());

  // Go through each path and try to find the function.
  for path in paths loop
    try
      if not stringEmpty(path) then
        path := uriToFilename(path);
      end if;

      libHandle := System.loadLibrary(path, relativePath = false, printDebug = debug);
      fnHandle := System.lookupFunction(libHandle, fnName);
      found := true;
    else
    end try;

    if found then
      break;
    end if;
  end for;

  ErrorExt.rollBack(getInstanceName());

  if not found then
    paths := list("  " + Testsuite.friendly(uriToFilename(p)) for p in paths);
    Error.addSourceMessage(Error.EXTERNAL_FUNCTION_NOT_FOUND,
      {fnName, stringDelimitList(paths, "\n")}, info);
    fail();
  end if;
end loadLibraryFunction;

function parseExternalAnnotation
  input String name;
  input SCode.Annotation ann;
  output list<String> strl = {};
protected
  list<SCode.Mod> mods;
  Absyn.Exp exp;
algorithm
  mods := SCodeUtil.lookupNamedAnnotations(ann, name);

  for m in mods loop
    strl := match m
      case SCode.Mod.MOD(binding = SOME(exp))
        then parseExternalAnnotationExp(exp, strl);
      else strl;
    end match;
  end for;
end parseExternalAnnotation;

function parseExternalAnnotationExp
  input Absyn.Exp exp;
  input output list<String> strl;
algorithm
  strl := match exp
    case Absyn.Exp.STRING() then exp.value :: strl;
    case Absyn.Exp.ARRAY()
      then List.fold(exp.arrayExp, parseExternalAnnotationExp, strl);
    else strl;
  end match;
end parseExternalAnnotationExp;

function freeLibraryFunction
  "Frees the function and shared library loaded by loadLibraryFunction."
  input Integer libHandle;
  input Integer fnHandle;
  input Boolean debug;
algorithm
  System.freeFunction(fnHandle, debug);
  System.freeLibrary(libHandle, debug);
end freeLibraryFunction;

function mapExternalArgs
  "Maps the given input arguments to the arguments in the external function
   call specifier, returning an array of mapped arguments and a corresponding
   array of FFI.ArgSpec:s for use with the FFI interface."
  input Function fn;
  input list<Expression> inputArgs;
  input list<Expression> extArgs;
  output array<Expression> mappedArgs;
  output array<FFI.ArgSpec> argSpecs;
protected
  ArgumentMap arg_map;
  Expression marg;
  FFI.ArgSpec arg_spec;
  Integer args_len, i = 1;
algorithm
  arg_map := createArgumentMap(fn.inputs, fn.outputs, fn.locals, inputArgs,
    mutableParams = false, buildArrayBinding = false);

  args_len := listLength(extArgs);
  mappedArgs := arrayCreateNoInit(args_len, Expression.INTEGER(0));
  argSpecs := arrayCreateNoInit(args_len, FFI.ArgSpec.INPUT);

  for ext_arg in extArgs loop
    (marg, arg_spec) := mapExternalArg(ext_arg, arg_map, fn);
    mappedArgs[i] := marg;
    argSpecs[i] := arg_spec;
    i := i + 1;
  end for;
end mapExternalArgs;

function mapExternalArg
  input Expression extArg;
  input ArgumentMap argMap;
  input Function fn;
  output Expression arg;
  output FFI.ArgSpec spec;
protected
  InstNode cr_node;
algorithm
  arg := applyBindingReplacement(extArg, argMap);
  arg := Ceval.evalExp(arg);

  spec := match extArg
    case Expression.CREF()
      algorithm
        cr_node := ComponentRef.node(ComponentRef.last(extArg.cref));

        if InstNode.isProtected(cr_node) then
          spec := FFI.ArgSpec.LOCAL;
        elseif InstNode.isOutput(cr_node) then
          spec := FFI.ArgSpec.OUTPUT;
        else
          spec := FFI.ArgSpec.INPUT;
        end if;
      then
        spec;

    else FFI.ArgSpec.INPUT;
  end match;
end mapExternalArg;

function makeExternalResult
  "Constructs a tuple with the output values of an external function returning
   multiple values via output parameters. The first value in the list is assumed
   to be the value returned by the function, or Expression.EMPTY if the function
   doesn't return any value."
  input list<Expression> values;
  input ComponentRef outputRef;
  input list<Expression> extArgs;
  input list<InstNode> outputs;
  output Expression outExp;
protected
  ArgumentMap arg_map;
  Expression val;
  list<Expression> vals, ret_vals;
  Option<Expression> ret_val;
  ComponentRef cref;
algorithm
  arg_map := UnorderedMap.new<Expression>(InstNode.hash, InstNode.refEqual);
  val :: vals := values;

  if ComponentRef.isCref(outputRef) then
    UnorderedMap.addUnique(ComponentRef.node(outputRef), val, arg_map);
  end if;

  for ext_arg in extArgs loop
    () := match ext_arg
      case Expression.CREF()
        guard InstNode.isOutput(ComponentRef.node(ComponentRef.last(ext_arg.cref)))
        algorithm
          val :: vals := vals;
          UnorderedMap.addUnique(ComponentRef.node(ext_arg.cref), val, arg_map);
        then
          ();

      else ();
    end match;
  end for;

  ret_vals := list(getExternalOutputResult(o, arg_map) for o in outputs);
  outExp := Expression.makeTuple(ret_vals);
end makeExternalResult;

function getExternalOutputResult
  input InstNode outputNode;
  input ArgumentMap map;
  output Expression exp;
protected
  Option<Expression> oexp;
  array<InstNode> comps;
  list<Expression> expl;
  InstNode cls_node;
algorithm
  oexp := UnorderedMap.get(outputNode, map);

  if isSome(oexp) then
    SOME(exp) := oexp;
  elseif InstNode.isRecord(outputNode) then
    cls_node := InstNode.classScope(outputNode);
    comps := ClassTree.getComponents(Class.classTree(InstNode.getClass(cls_node)));

    expl := {};
    for c in comps loop
      expl := getExternalOutputResult(c, map) :: expl;
    end for;

    exp := Expression.makeRecord(InstNode.scopePath(cls_node, includeRoot = true),
      InstNode.getType(cls_node), listReverseInPlace(expl));
  else
    Error.assertion(false, getInstanceName() +
      " failed to find return value for output " + InstNode.name(outputNode), sourceInfo());
  end if;
end getExternalOutputResult;

function checkExtReturnValue
  "Checks that an external function doesn't return something we don't yet
   support."
  input ComponentRef cref;
  input SourceInfo info;
algorithm
  if ComponentRef.isCref(cref) and Type.isRecord(ComponentRef.nodeType(cref)) then
    Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,
      {"\"record return value in external function\"", "Pass the record as an output parameter"}, info);
    fail();
  end if;
end checkExtReturnValue;

annotation(__OpenModelica_Interface="frontend");
end NFEvalFunction;
