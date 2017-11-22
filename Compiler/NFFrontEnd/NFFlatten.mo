/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFFlatten
" file:        NFFlatten.mo
  package:     NFFlatten
  description: Flattening


  New instantiation, enable with -d=newInst.
"

import Binding = NFBinding;
import Equation = NFEquation;
import NFFunction.Function;
import NFInstNode.InstNode;
import Statement = NFStatement;

protected
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import ExecStat.execStat;
import ExpressionIterator = NFExpressionIterator;
import Expression = NFExpression;
import Inst = NFInst;
import List;
import NFCall.Call;
import NFClass.Class;
import NFClassTree.ClassTree;
import NFComponent.Component;
import NFModifier.Modifier;
import Sections = NFSections;
import Prefixes = NFPrefixes;
import NFPrefixes.Visibility;
import RangeIterator = NFRangeIterator;
import Subscript = NFSubscript;
import Type = NFType;
import Util;
import MetaModelica.Dangerous.listReverseInPlace;
import ConnectionSets = NFConnectionSets.ConnectionSets;
import Connection = NFConnection;
import Connector = NFConnector;
import ConnectEquations = NFConnectEquations;
import Connections = NFConnections;
import Face = NFConnector.Face;
import System;

public
type FunctionTree = FunctionTreeImpl.Tree;

encapsulated package FunctionTreeImpl
  import Absyn.Path;
  import NFFunction.Function;
  import BaseAvlTree;

  extends BaseAvlTree;
  redeclare type Key = Absyn.Path;
  redeclare type Value = Function;

  redeclare function extends keyStr
  algorithm
    outString := Absyn.pathString(inKey);
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := "";
  end valueStr;

  redeclare function extends keyCompare
  algorithm
    outResult := Absyn.pathCompareNoQual(inKey1, inKey2);
  end keyCompare;

  redeclare function addConflictDefault = addConflictKeep;
end FunctionTreeImpl;

uniontype Elements
  record ELEMENTS
    list<tuple<ComponentRef, Binding>> components;
    list<Equation> equations;
    list<Equation> initialEquations;
    list<list<Statement>> algorithms;
    list<list<Statement>> initialAlgorithms;
  end ELEMENTS;
end Elements;

function flatten
  input InstNode classInst;
  input String name;
  output Elements elems;
  output FunctionTree funcs;
protected
  list<tuple<ComponentRef, Binding>> comps;
  Sections sections;
  list<Equation> eql, ieql;
  list<list<Statement>> alg, ialg;
algorithm
  sections := Sections.EMPTY();

  (comps, sections) :=
    flattenClass(InstNode.getClass(classInst), ComponentRef.EMPTY(), Visibility.PUBLIC, {}, sections);
  comps := listReverseInPlace(comps);

  elems := match sections
    case Sections.SECTIONS()
      algorithm
        eql := listReverseInPlace(sections.equations);
        ieql := listReverseInPlace(sections.initialEquations);
        alg := listReverseInPlace(sections.algorithms);
        ialg := listReverseInPlace(sections.initialAlgorithms);
      then
        ELEMENTS(comps, eql, ieql, alg, ialg);

    else ELEMENTS(comps, {}, {}, {}, {});
  end match;

  execStat(getInstanceName() + "(" + name + ")");
  elems := resolveConnections(elems, name);
  funcs := flattenFunctions(elems, name);
end flatten;

protected
function flattenClass
  input Class cls;
  input ComponentRef prefix;
  input Visibility visibility;
  input output list<tuple<ComponentRef, Binding>> comps;
  input output Sections sections;
protected
  ClassTree cls_tree;
algorithm
  () := match cls
    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          (comps, sections) := flattenComponent(c, prefix, visibility, comps, sections);
        end for;

        sections := flattenSections(cls.sections, prefix, sections);
      then
        ();

    case Class.INSTANCED_BUILTIN() then ();

    else
      algorithm
        assert(false, getInstanceName() + " got non-instantiated component " + ComponentRef.toString(prefix) + "\n");
      then
        ();

  end match;
end flattenClass;

function flattenComponent
  input InstNode component;
  input ComponentRef prefix;
  input Visibility visibility;
  input output list<tuple<ComponentRef, Binding>> comps;
  input output Sections sections;
protected
  InstNode comp_node;
  Component c;
  Type ty;
  ComponentRef new_pre;
  Binding binding, condition;
  list<Dimension> dims;
  Class cls;
  Visibility vis;
algorithm
  // Remove components that are only outer.
  if InstNode.isOnlyOuter(component) or InstNode.isEmpty(component) then
    return;
  end if;

  comp_node := InstNode.resolveOuter(component);
  c := InstNode.component(comp_node);

  () := match c
    case Component.TYPED_COMPONENT(ty = ty, condition = condition)
      algorithm
        // Don't add the component if it has a condition that's false.
        if Binding.isBound(condition) and Expression.isFalse(Binding.getTypedExp(condition)) then
          return;
        end if;

        cls := InstNode.getClass(c.classInst);

        () := match cls
          // If the component is of a builtin type, add it to the component list
          // along with its binding.
          case Class.INSTANCED_BUILTIN()
            algorithm
              if visibility == Visibility.PROTECTED then
                comp_node := InstNode.protectComponent(comp_node);
              end if;

              new_pre := ComponentRef.prefixCref(comp_node, ty, {}, prefix);
              binding := flattenBinding(c.binding, prefix, comp_node);

              if Type.isArray(ty) and Binding.isBound(binding) and Component.isVar(c) then
                comps := (new_pre, Binding.UNBOUND()) :: comps;
                sections := Sections.prependEquation(
                  Equation.ARRAY_EQUALITY(Expression.CREF(ty, new_pre), Binding.getTypedExp(binding), ty, c.info),
                  sections);
              else
                comps := (new_pre, binding) :: comps;
              end if;
            then
              ();

          // If the component is of a complex type, either flatten its class
          // directly if it's a scalar or vectorize it if it's an array.
          else
            algorithm
              vis := if InstNode.isProtected(comp_node) then Visibility.PROTECTED else visibility;
              dims := Type.arrayDims(ty);
              new_pre := ComponentRef.prefixCref(comp_node, ty, {}, prefix);

              if listEmpty(dims) then
                (comps, sections) := flattenClass(cls, new_pre, vis, comps, sections);
              else
                (comps, sections) := flattenArray(cls, dims, new_pre, vis, comps, sections);
              end if;
            then
              ();
        end match;
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got unknown component");
      then
        fail();

  end match;
end flattenComponent;

function flattenArray
  input Class cls;
  input list<Dimension> dimensions;
  input ComponentRef prefix;
  input Visibility visibility;
  input output list<tuple<ComponentRef, Binding>> comps;
  input output Sections sections;
  input list<Subscript> subscripts = {};
protected
  Dimension dim;
  list<Dimension> rest_dims;
  ComponentRef sub_pre;
  RangeIterator range_iter;
  Expression sub_exp;
algorithm
  if listEmpty(dimensions) then
    sub_pre := ComponentRef.setSubscripts(listReverse(subscripts), prefix);
    (comps, sections) := flattenClass(cls, sub_pre, visibility, comps, sections);
  else
    dim :: rest_dims := dimensions;
    range_iter := RangeIterator.fromDim(dim);

    while RangeIterator.hasNext(range_iter) loop
      (range_iter, sub_exp) := RangeIterator.next(range_iter);
      (comps, sections) := flattenArray(cls, rest_dims, prefix, visibility, comps, sections,
        Subscript.INDEX(sub_exp) :: subscripts);
    end while;
  end if;
end flattenArray;

function flattenBinding
  input output Binding binding;
  input ComponentRef prefix;
  input InstNode component;
algorithm
  () := match binding
    local
      list<Subscript> subs;

    case Binding.UNBOUND() then ();

    case Binding.TYPED_BINDING()
      algorithm
        if binding.originLevel > 0 then
          subs := List.flatten(ComponentRef.subscriptsN(prefix, InstNode.level(component) - binding.originLevel));
          binding.bindingExp := Expression.subscript(binding.bindingExp, subs);
        end if;
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got untyped binding.");
      then
        fail();

  end match;
end flattenBinding;

function flattenExp
  input output Expression exp;
  input ComponentRef prefix;
algorithm
  exp := Expression.map(exp, function flattenExp_traverse(prefix = prefix));
end flattenExp;

function flattenExp_traverse
  input output Expression exp;
  input ComponentRef prefix;
algorithm
  exp := match exp
    case Expression.CREF()
      algorithm
        exp.cref := ComponentRef.transferSubscripts(prefix, exp.cref);
      then
        exp;

    else exp;
  end match;
end flattenExp_traverse;

function flattenSections
  input Sections sections;
  input ComponentRef prefix;
  input output Sections accumSections;
algorithm
  () := match sections
    local
      list<Equation> eq, ieq;
      list<list<Statement>> alg, ialg;

    case Sections.SECTIONS()
      algorithm
        eq := flattenEquations(sections.equations, prefix);
        ieq := flattenEquations(sections.initialEquations, prefix);
        alg := flattenAlgorithms(sections.algorithms, prefix);
        ialg := flattenAlgorithms(sections.initialAlgorithms, prefix);
        accumSections := Sections.prepend(eq, ieq, alg, ialg, accumSections);
      then
        ();

    else ();
  end match;
end flattenSections;

function flattenEquations
  input list<Equation> eql;
  input ComponentRef prefix;
  output list<Equation> equations = {};
algorithm
  for eq in eql loop
    equations := flattenEquation(eq, prefix, equations);
  end for;
end flattenEquations;

function flattenEquation
  input Equation eq;
  input ComponentRef prefix;
  input output list<Equation> equations;
algorithm
  equations := match eq
    local
      Expression e1, e2, e3;

    case Equation.EQUALITY()
      algorithm
        e1 := flattenExp(eq.lhs, prefix);
        e2 := flattenExp(eq.rhs, prefix);
      then
        Equation.EQUALITY(e1, e2, eq.ty, eq.info) :: equations;

    case Equation.FOR()
      algorithm
        eq.body := flattenEquations(eq.body, prefix);
      then
        unrollForLoop(eq, equations);

    case Equation.CONNECT()
      algorithm
        e1 := flattenExp(eq.lhs, prefix);
        e2 := flattenExp(eq.rhs, prefix);
      then
        Equation.CONNECT(e1, e2, eq.info) :: equations;

    case Equation.IF()
      then flattenIfEquation(eq.branches, prefix, eq.info, equations);

    case Equation.WHEN()
      algorithm
        eq.branches := list(flattenEqBranch(b, prefix) for b in eq.branches);
      then
        eq :: equations;

    case Equation.ASSERT()
      algorithm
        e1 := flattenExp(eq.condition, prefix);
        e2 := flattenExp(eq.message, prefix);
        e3 := flattenExp(eq.level, prefix);
      then
        Equation.ASSERT(e1, e2, e3, eq.info) :: equations;

    case Equation.TERMINATE()
      algorithm
        e1 := flattenExp(eq.message, prefix);
      then
        Equation.TERMINATE(e1, eq.info) :: equations;

    case Equation.REINIT()
      algorithm
        e1 := flattenExp(eq.cref, prefix);
        e2 := flattenExp(eq.reinitExp, prefix);
      then
        Equation.REINIT(e1, e2, eq.info) :: equations;

    case Equation.NORETCALL()
      algorithm
        e1 := flattenExp(eq.exp, prefix);
      then
        Equation.NORETCALL(e1, eq.info) :: equations;

    else eq :: equations;
  end match;
end flattenEquation;

function flattenIfEquation
  input list<tuple<Expression, list<Equation>>> branches;
  input ComponentRef prefix;
  input SourceInfo info;
  input output list<Equation> equations;
protected
  list<tuple<Expression, list<Equation>>> bl = {};
  Expression cond;
  list<Equation> eql;
algorithm
  for b in branches loop
    (cond, eql) := b;
    eql := flattenEquations(eql, prefix);

    if Expression.isTrue(cond) and listEmpty(bl) then
      // If the condition is literal true and we haven't collected any other
      // branches yet, replace the if equation with this branch.
      equations := listAppend(eql, equations);
      return;
    elseif not Expression.isFalse(cond) then
      // Only add the branch to the list of branches if the condition is not
      // literal false, otherwise just drop it since it will never trigger.
      bl := (cond, eql) :: bl;
    end if;
  end for;

  // Add the flattened if equation to the list of equations if we got this far,
  // and there are any branches still remaining.
  if not listEmpty(bl) then
    equations := Equation.IF(listReverseInPlace(bl), info) :: equations;
  end if;
end flattenIfEquation;

function flattenEqBranch
  input output tuple<Expression, list<Equation>> branch;
  input ComponentRef prefix;
protected
  Expression exp;
  list<Equation> eql;
algorithm
  (exp, eql) := branch;
  exp := flattenExp(exp, prefix);
  eql := flattenEquations(eql, prefix);
  branch := (exp, eql);
end flattenEqBranch;

function unrollForLoop
  input Equation forLoop;
  input output list<Equation> equations;
protected
  InstNode iter;
  String iter_name;
  list<Equation> body, unrolled_body;
  Binding binding;
  Expression range;
  RangeIterator range_iter;
  Expression val;
algorithm
  Equation.FOR(iterator = iter, body = body) := forLoop;

  // Get the range to iterate over.
  Component.ITERATOR(binding = binding) := InstNode.component(iter);
  iter_name := InstNode.name(iter);
  SOME(range) := Binding.typedExp(binding);
  range_iter := RangeIterator.fromExp(range);

  // Unroll the loop by replacing the iterator with each of its values in the for loop body.
  while RangeIterator.hasNext(range_iter) loop
    (range_iter, val) := RangeIterator.next(range_iter);
    unrolled_body := list(Equation.mapExp(eq,
      function replaceForIterator(iteratorName = iter_name, iteratorValue = val)) for eq in body);
    equations := listAppend(unrolled_body, equations);
  end while;
end unrollForLoop;

function replaceForIterator
  input output Expression exp;
  input String iteratorName;
  input Expression iteratorValue;
algorithm
  exp := Expression.map(exp,
    function replaceForIterator2(iteratorName = iteratorName, iteratorValue = iteratorValue));
end replaceForIterator;

function replaceForIterator2
  input output Expression exp;
  input String iteratorName;
  input Expression iteratorValue;

  import Origin = NFComponentRef.Origin;
algorithm
  exp := match exp
    local
      String name;

    case Expression.CREF(cref = ComponentRef.CREF(
        node = InstNode.COMPONENT_NODE(name = name), origin = Origin.ITERATOR))
      then if name == iteratorName then iteratorValue else exp;

    else exp;
  end match;
end replaceForIterator2;

function flattenAlgorithms
  input output list<list<Statement>> algorithms;
  input ComponentRef prefix;
algorithm
  algorithms := listReverse(
    Statement.mapExpList(alg, function flattenExp(prefix = prefix)) for alg in algorithms);
end flattenAlgorithms;

function resolveConnections
  input output Elements elems;
  input String name;
protected
  Connections conns;
  list<Equation> conn_eql;
  ConnectionSets.Sets csets;
  array<list<Connector>> csets_array;
algorithm
  // Generate the connect equations and add them to the equation list.
  (elems, conns) := Connections.collect(elems);
  csets := ConnectionSets.fromConnections(conns);
  csets_array := ConnectionSets.extractSets(csets);
  conn_eql := ConnectEquations.generateEquations(csets_array);
  elems.equations := listAppend(conn_eql, elems.equations);

  // Evaluate any connection operators if they're used.
  if System.getHasStreamConnectors() or System.getUsesCardinality() then
    elems := evaluateConnectionOperators(elems, csets, csets_array);
  end if;

  execStat(getInstanceName() + "(" + name + ")");
end resolveConnections;

function evaluateConnectionOperators
  input output Elements elems;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
algorithm
  elems.components := list(evaluateBindingConnOp(c, sets, setsArray) for c in elems.components);
  elems.equations := evaluateEquationsConnOp(elems.equations, sets, setsArray);
  elems.initialEquations := evaluateEquationsConnOp(elems.initialEquations, sets, setsArray);
  // TODO: Implement evaluation for algorithm sections.
end evaluateConnectionOperators;

function evaluateBindingConnOp
  input output tuple<ComponentRef, Binding> component;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
protected
  ComponentRef cr;
  Binding binding;
  Expression exp, eval_exp;
algorithm
  () := match component
    case (cr, binding as Binding.TYPED_BINDING(bindingExp = exp))
      algorithm
        eval_exp := ConnectEquations.evaluateOperators(exp, sets, setsArray);

        if not referenceEq(exp, eval_exp) then
          binding.bindingExp := eval_exp;
          component := (cr, binding);
        end if;
      then
        ();

    else ();
  end match;
end evaluateBindingConnOp;

function evaluateEquationsConnOp
  input output list<Equation> equations;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
algorithm
  equations := list(evaluateEquationConnOp(eq, sets, setsArray) for eq in equations);
end evaluateEquationsConnOp;

function evaluateEquationConnOp
  input output Equation eq;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
algorithm
  eq := match eq
    local
      Expression e1, e2;

    case Equation.EQUALITY()
      algorithm
        e1 := ConnectEquations.evaluateOperators(eq.lhs, sets, setsArray);
        e2 := ConnectEquations.evaluateOperators(eq.rhs, sets, setsArray);
      then
        Equation.EQUALITY(e1, e2, eq.ty, eq.info);

    case Equation.ARRAY_EQUALITY()
      algorithm
        eq.rhs := ConnectEquations.evaluateOperators(eq.rhs, sets, setsArray);
      then
        eq;

    case Equation.FOR()
      algorithm
        eq.body := evaluateEquationsConnOp(eq.body, sets, setsArray);
      then
        eq;

    case Equation.IF()
      algorithm
        eq.branches := list(evaluateEqBranchConnOp(b, sets, setsArray) for b in eq.branches);
      then
        eq;

    case Equation.WHEN()
      algorithm
        eq.branches := list(evaluateEqBranchConnOp(b, sets, setsArray) for b in eq.branches);
      then
        eq;

    case Equation.REINIT()
      algorithm
        eq.reinitExp := ConnectEquations.evaluateOperators(eq.reinitExp, sets, setsArray);
      then
        eq;

    case Equation.NORETCALL()
      algorithm
        eq.exp := ConnectEquations.evaluateOperators(eq.exp, sets, setsArray);
      then
        eq;

    else eq;
  end match;
end evaluateEquationConnOp;

function evaluateEqBranchConnOp
  input output tuple<Expression, list<Equation>> branch;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
protected
  Expression exp;
  list<Equation> eql;
algorithm
  (exp, eql) := branch;
  eql := evaluateEquationsConnOp(eql, sets, setsArray);
  branch := (exp, eql);
end evaluateEqBranchConnOp;

function flattenFunctions
  input Elements elems;
  input String name;
  output FunctionTree funcs;
algorithm
  funcs := FunctionTree.new();
  funcs := List.fold(elems.components, collectComponentFuncs, funcs);
  funcs := List.fold(elems.equations, collectEquationFuncs, funcs);
  funcs := List.fold(elems.initialEquations, collectEquationFuncs, funcs);
  funcs := List.fold(elems.algorithms, collectAlgorithmFuncs, funcs);
  funcs := List.fold(elems.initialAlgorithms, collectAlgorithmFuncs, funcs);
  execStat(getInstanceName() + "(" + name + ")");
end flattenFunctions;

function collectComponentFuncs
  input tuple<ComponentRef, Binding> component;
  input output FunctionTree funcs;
protected
  Binding binding;
algorithm
  (_, binding) := component;

  if Binding.isBound(binding) then
    funcs := collectExpFuncs(Binding.getTypedExp(binding), funcs);
  end if;
end collectComponentFuncs;

function collectEquationFuncs
  input Equation eq;
  input output FunctionTree funcs;
algorithm
  () := match eq
    case Equation.EQUALITY()
      algorithm
        funcs := collectExpFuncs(eq.lhs, funcs);
        funcs := collectExpFuncs(eq.rhs, funcs);
      then
        ();

    case Equation.ARRAY_EQUALITY()
      algorithm
        // Lhs is always a cref, no need to check it.
        funcs := collectExpFuncs(eq.rhs, funcs);
      then
        ();

    case Equation.FOR()
      algorithm
        funcs := List.fold(eq.body, collectEquationFuncs, funcs);
      then
        ();

    case Equation.IF()
      algorithm
        funcs := List.fold(eq.branches, collectEqBranchFuncs, funcs);
      then
        ();

    case Equation.WHEN()
      algorithm
        funcs := List.fold(eq.branches, collectEqBranchFuncs, funcs);
      then
        ();

    case Equation.ASSERT()
      algorithm
        funcs := collectExpFuncs(eq.condition, funcs);
        funcs := collectExpFuncs(eq.message, funcs);
        funcs := collectExpFuncs(eq.level, funcs);
      then
        ();

    case Equation.TERMINATE()
      algorithm
        funcs := collectExpFuncs(eq.message, funcs);
      then
        ();

    case Equation.REINIT()
      algorithm
        funcs := collectExpFuncs(eq.reinitExp, funcs);
      then
        ();

    case Equation.NORETCALL()
      algorithm
        funcs := collectExpFuncs(eq.exp, funcs);
      then
        ();

    else ();
  end match;
end collectEquationFuncs;

function collectEqBranchFuncs
  input tuple<Expression, list<Equation>> branch;
  input output FunctionTree funcs;
algorithm
  funcs := collectExpFuncs(Util.tuple21(branch), funcs);
  funcs := List.fold(Util.tuple22(branch), collectEquationFuncs, funcs);
end collectEqBranchFuncs;

function collectAlgorithmFuncs
  input list<Statement> alg;
  input output FunctionTree funcs;
algorithm
  funcs := List.fold(alg, collectStatementFuncs, funcs);
end collectAlgorithmFuncs;

function collectStatementFuncs
  input Statement stmt;
  input output FunctionTree funcs;
algorithm
  () := match stmt
    case Statement.ASSIGNMENT()
      algorithm
        funcs := collectExpFuncs(stmt.lhs, funcs);
        funcs := collectExpFuncs(stmt.rhs, funcs);
      then
        ();

    case Statement.FOR()
      algorithm
        funcs := List.fold(stmt.body, collectStatementFuncs, funcs);
      then
        ();

    case Statement.IF()
      algorithm
        funcs := List.fold(stmt.branches, collectStmtBranchFuncs, funcs);
      then
        ();

    case Statement.WHEN()
      algorithm
        funcs := List.fold(stmt.branches, collectStmtBranchFuncs, funcs);
      then
        ();

    case Statement.ASSERT()
      algorithm
        funcs := collectExpFuncs(stmt.condition, funcs);
        funcs := collectExpFuncs(stmt.message, funcs);
        funcs := collectExpFuncs(stmt.level, funcs);
      then
        ();

    case Statement.TERMINATE()
      algorithm
        funcs := collectExpFuncs(stmt.message, funcs);
      then
        ();

    case Statement.NORETCALL()
      algorithm
        funcs := collectExpFuncs(stmt.exp, funcs);
      then
        ();

    case Statement.WHILE()
      algorithm
        funcs := collectExpFuncs(stmt.condition, funcs);
        funcs := List.fold(stmt.body, collectStatementFuncs, funcs);
      then
        ();

    else ();
  end match;
end collectStatementFuncs;

function collectStmtBranchFuncs
  input tuple<Expression, list<Statement>> branch;
  input output FunctionTree funcs;
algorithm
  funcs := collectExpFuncs(Util.tuple21(branch), funcs);
  funcs := List.fold(Util.tuple22(branch), collectStatementFuncs, funcs);
end collectStmtBranchFuncs;

function collectExpFuncs
  input Expression exp;
  input output FunctionTree funcs;
algorithm
  funcs := Expression.fold(exp, collectExpFuncs_traverse, funcs);
end collectExpFuncs;

function collectExpFuncs_traverse
  input Expression exp;
  input output FunctionTree funcs;
algorithm
  () := match exp
    case Expression.CALL()
      algorithm
        funcs := flattenFunction(Call.typedFunction(exp.call), funcs);
      then
        ();

    else ();
  end match;
end collectExpFuncs_traverse;

function flattenFunction
  input Function fn;
  input output FunctionTree funcs;
algorithm
  if not Function.isCollected(fn) then
    Function.collect(fn);
    funcs := FunctionTree.add(funcs, Function.name(fn), fn);
  end if;
end flattenFunction;

annotation(__OpenModelica_Interface="frontend");
end NFFlatten;
