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

encapsulated package NFInline

import Call = NFCall;
import Expression = NFExpression;

protected
import Binding = NFBinding;
import Class = NFClass;
import Component = NFComponent;
import ComponentRef = NFComponentRef;
import DAE.InlineType;
import Dimension = NFDimension;
import Flags;
import NFFunction.Function;
import NFInstNode.InstNode;
import Statement = NFStatement;
import Subscript = NFSubscript;
import Type = NFType;

public
function inlineCallExp
  "Inlines a call if it has an EarlyInline=true annotation, or always if
   forceInline is set to true."
  input Expression callExp;
  input Boolean forceInline = false;
  output Expression result;
algorithm
  result := match callExp
    local
      Call call;
      Boolean shouldInline;

    case Expression.CALL(call = call as Call.TYPED_CALL())
      algorithm
        shouldInline := match Call.inlineType(call)
          case DAE.InlineType.BUILTIN_EARLY_INLINE() then true;
          case DAE.InlineType.EARLY_INLINE()
            guard Flags.isSet(Flags.INLINE_FUNCTIONS) then true;
          case DAE.InlineType.NORM_INLINE() then forceInline or Flags.getConfigBool(Flags.FRONTEND_INLINE);
          else forceInline;
        end match;
      then
        if shouldInline then inlineCall(callExp, forceInline) else callExp;

    else callExp;
  end match;
end inlineCallExp;

function inlineCall
  input Expression callExp;
  input Boolean forceInline = false;
  output Expression exp;
protected
  Call call;
  Function fn;
  Expression arg;
  list<Expression> args;
  list<InstNode> inputs, outputs, locals;
  list<Statement> body;
  Statement stmt;
  Binding binding;
algorithm
  Expression.CALL(call = call) := callExp;

  exp := match call
    // Record constructor
    case Call.TYPED_CALL(fn = fn, arguments = args)
        guard not InstNode.isEmpty(fn.node) and InstNode.isNamed(InstNode.parentScope(fn.node), "'constructor'")
      algorithm
        body := Function.getBody(fn);

        if not (listEmpty(body) and listEmpty(fn.locals)) then
          exp := callExp;
          return;
        end if;

        binding := Component.getBinding(InstNode.component(listHead(fn.outputs)));

        if Binding.hasExp(binding) then
          exp := Binding.getExp(binding);
          true := Expression.isRecord(exp);
        else
          exp := Class.makeRecordExp(listHead(fn.outputs), fn.node, typed = true);
        end if;

        for i in fn.inputs loop
          arg :: args := args;
          arg := inlineCallExp(arg, forceInline);
          exp := Expression.map(exp, func = function replaceCrefNode(node = i, value = arg));
        end for;
      then
        exp;

    // Normal function
    case Call.TYPED_CALL(fn = fn as Function.FUNCTION(inputs = inputs, outputs = outputs, locals = locals),
                         arguments = args)
      guard Function.hasSingleOrEmptyBody(fn)
      algorithm
        body := Function.getBody(fn);
        body := removeDeadCode(body);

        // This function can so far only handle functions with at most one
        // statement and output and no local variables.
        if listLength(body) > 1 or listLength(outputs) <> 1 or not listEmpty(locals) then
          exp := callExp;
          return;
        end if;

        if listEmpty(body) then
          stmt := makeOutputStatement(listHead(outputs));
        else
          stmt := convertToAssignment(listHead(body));
        end if;

        if not Statement.isAssignment(stmt) then
          exp := callExp;
          return;
        end if;

        Error.assertion(listLength(inputs) == listLength(args),
          getInstanceName() + " got wrong number of arguments for " +
          AbsynUtil.pathString(Function.name(fn)), sourceInfo());

        try
          // TODO: Instead of repeating this for each input we should probably
          //       just build a lookup tree or hash table and go through the
          //       statement once.
          for i in inputs loop
            arg :: args := args;
            arg := inlineCallExp(arg, forceInline);
            stmt := Statement.mapExp(stmt,
              function Expression.map(func = function replaceCrefNode(node = i, value = arg)));
          end for;

          exp := getOutputExp(stmt, listHead(outputs), call);
          exp := Expression.map(exp, function inlineCallExp(forceInline = forceInline));
        else
          exp := callExp;
        end try;
      then
        exp;

    else callExp;
  end match;
end inlineCall;

protected
function replaceCrefNode
  input output Expression exp;
  input InstNode node;
  input Expression value;
protected
  InstNode cr_node;
  ComponentRef rest_cr;
  list<Subscript> subs;
  Type ty, repl_ty;
algorithm
  exp := match exp
    case Expression.CREF()
      guard InstNode.refEqual(ComponentRef.node(ComponentRef.firstNonScope(exp.cref)), node)
      then replaceCrefNode2(exp.cref, node, value);

    else exp;
  end match;

  // Replace expressions in dimensions too.
  ty := Expression.typeOf(exp);
  repl_ty := Type.mapDims(ty, function replaceDimExp(node = node, value = value));

  if not referenceEq(ty, repl_ty) then
    exp := Expression.setType(repl_ty, exp);
  end if;
end replaceCrefNode;

function replaceCrefNode2
  input ComponentRef cref;
  input InstNode node;
  input output Expression value;
protected
  list<Subscript> subs;
  ComponentRef rest_cr;
  Type ty;
algorithm
  if not InstNode.refEqual(node, ComponentRef.node(cref)) then
    value := replaceCrefNode2(ComponentRef.rest(cref), node, value);
    value := Expression.recordElement(InstNode.name(ComponentRef.node(cref)), value);
  end if;

  value := Expression.applySubscripts(ComponentRef.getSubscripts(cref), value);
end replaceCrefNode2;

function replaceDimExp
  input output Dimension dim;
  input InstNode node;
  input Expression value;
algorithm
  dim := match dim
    local
      Expression exp;

    case Dimension.EXP()
      algorithm
        exp := Expression.map(dim.exp, function replaceCrefNode(node = node, value = value));
      then
        Dimension.fromExp(exp, dim.var);

    else dim;
  end match;
end replaceDimExp;

function removeDeadCode
  input output list<Statement> body;
algorithm
  // Everything after a 'return' can be removed, but for inlining we only care
  // if we can remove everything after the first statement.
  if listLength(body) > 1 and Statement.isReturn(listGet(body, 2)) then
    body := {listHead(body)};
  end if;
end removeDeadCode;

function convertToAssignment
  "Converts a statement into an assignment statement."
  input Statement stmt;
  output Statement outStmt;
algorithm
  outStmt := match stmt
    case Statement.IF() then convertIfToAssignment(stmt);
    else stmt;
  end match;
end convertToAssignment;

function convertIfToAssignment
  "Converts an if-statement where all branches assign the same variable into an
   assignment with an if-expression. Ex:
     if x > 1 then
       y := 1;
     else
       y := 2;
     end if;
     =>
     y := if x > 1 then 1 else 2;
  "
  input output Statement stmt;
protected
  list<tuple<Expression, list<Statement>>> branches;
  Expression cond, if_exp, output_exp, lhs, rhs;
  Type ty;
  list<Statement> body;
  Statement s;
  DAE.ElementSource source;
algorithm
  Statement.IF(branches = branches, source = source) := stmt;
  (cond, body) :: branches := listReverse(branches);

  // The if-statement must have an else-branch.
  if not listEmpty(branches) and not Expression.isTrue(cond) then
    return;
  end if;

  // The body of the else branch must have exactly one statement.
  if listLength(body) <> 1 then
    return;
  end if;

  // The statement must be, or be convertible to, an assignment.
  s := convertToAssignment(listHead(body));

  if not Statement.isAssignment(s) then
    return;
  end if;

  Statement.ASSIGNMENT(lhs = output_exp, rhs = if_exp) := s;

  for b in branches loop
    (cond, body) :: branches := branches;

    // Each branch must be a single assignment.
    if listLength(body) <> 1 then
      return;
    end if;

    s := convertToAssignment(listHead(body));

    if not Statement.isAssignment(s) then
      return;
    end if;

    Statement.ASSIGNMENT(lhs = lhs, rhs = rhs, ty = ty) := s;

    // Check that all branches have the same lhs.
    if not Expression.isEqual(lhs, output_exp) then
      return;
    end if;

    if_exp := Expression.IF(ty, cond, rhs, if_exp);
  end for;

  stmt := Statement.ASSIGNMENT(output_exp, if_exp, ty, source);
end convertIfToAssignment;

function makeOutputStatement
  input InstNode outputNode;
  output Statement stmt;
protected
  Binding binding;
  Expression cref_exp, binding_exp;
algorithm
  binding := Component.getImplicitBinding(InstNode.component(outputNode), InstNode.instanceParent(outputNode));

  if Binding.isBound(binding) then
    cref_exp := Expression.fromCref(ComponentRef.fromNode(outputNode, Type.UNKNOWN()));
    binding_exp := Binding.getExp(binding);
    stmt := Statement.makeAssignment(cref_exp, binding_exp, Type.UNKNOWN(), DAE.emptyElementSource);
  else
    stmt := Statement.FAILURE({}, DAE.emptyElementSource);
  end if;
end makeOutputStatement;

function getOutputExp
  input Statement stmt;
  input InstNode outputNode;
  input Call call;
  output Expression exp;
algorithm
  exp := match stmt
    local
      InstNode cr_node;
      ComponentRef rest_cr;

    case Statement.ASSIGNMENT(lhs = Expression.CREF(
        cref = ComponentRef.CREF(node = cr_node, subscripts = {}, restCref = rest_cr)))
      guard InstNode.refEqual(outputNode, cr_node) and not ComponentRef.isFromCref(rest_cr)
      then stmt.rhs;

    else Expression.CALL(call);
  end match;
end getOutputExp;

annotation(__OpenModelica_Interface="frontend");
end NFInline;
