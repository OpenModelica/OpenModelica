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
import FlatModel = NFFlatModel;

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
import ComplexType = NFComplexType;
import NFInstNode.CachedData;
import NFPrefixes.Variability;
import Variable = NFVariable;
import BindingOrigin = NFBindingOrigin;
import ElementSource;

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

function flatten
  input InstNode classInst;
  input String name;
  output FlatModel flatModel;
  output FunctionTree funcs;
protected
  Sections sections;
  list<Variable> vars;
  list<Equation> eql, ieql;
  list<list<Statement>> alg, ialg;
  Option<SCode.Comment> cmt;
algorithm
  sections := Sections.EMPTY();
  cmt := SCode.getElementComment(InstNode.definition(classInst));

  (vars, sections) := flattenClass(InstNode.getClass(classInst), ComponentRef.EMPTY(),
    Visibility.PUBLIC, NONE(), {}, sections);
  vars := listReverseInPlace(vars);

  flatModel := match sections
    case Sections.SECTIONS()
      algorithm
        eql := listReverseInPlace(sections.equations);
        ieql := listReverseInPlace(sections.initialEquations);
        alg := listReverseInPlace(sections.algorithms);
        ialg := listReverseInPlace(sections.initialAlgorithms);
      then
        FlatModel.FLAT_MODEL(vars, eql, ieql, alg, ialg, cmt);

    else FlatModel.FLAT_MODEL(vars, {}, {}, {}, {}, cmt);
  end match;

  execStat(getInstanceName() + "(" + name + ")");
  flatModel := resolveConnections(flatModel, name);
  funcs := flattenFunctions(flatModel, name);
end flatten;

protected
function flattenClass
  input Class cls;
  input ComponentRef prefix;
  input Visibility visibility;
  input Option<Binding> binding;
  input output list<Variable> vars;
  input output Sections sections;
protected
  array<InstNode> comps;
  list<Binding> bindings;
  Binding b;
algorithm
  () := match cls
    case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps))
      algorithm
        if isSome(binding) then
          SOME(b) := binding;

          if Binding.isBound(b) then
            b := flattenBinding(b, ComponentRef.rest(prefix), ComponentRef.node(prefix));
            bindings := getRecordBindings(b);

            Error.assertion(listLength(bindings) == arrayLength(comps),
              getInstanceName() + " got record binding with wrong number of elements for " +
                ComponentRef.toString(prefix),
              sourceInfo());

            for c in comps loop
              (vars, sections) := flattenComponent(c, prefix, visibility, SOME(listHead(bindings)), vars, sections);
              bindings := listRest(bindings);
            end for;
          else
            for c in comps loop
              (vars, sections) := flattenComponent(c, prefix, visibility, binding, vars, sections);
            end for;
          end if;
        else
          for c in comps loop
            (vars, sections) := flattenComponent(c, prefix, visibility, NONE(), vars, sections);
          end for;
        end if;

        sections := flattenSections(cls.sections, prefix, sections);
      then
        ();

    case Class.TYPED_DERIVED()
      algorithm
        (vars, sections) :=
          flattenClass(InstNode.getClass(cls.baseClass), prefix, visibility, binding, vars, sections);
      then
        ();

    case Class.INSTANCED_BUILTIN() then ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got non-instantiated component " + ComponentRef.toString(prefix) + "\n", sourceInfo());
      then
        ();

  end match;
end flattenClass;

function flattenComponent
  input InstNode component;
  input ComponentRef prefix;
  input Visibility visibility;
  input Option<Binding> outerBinding;
  input output list<Variable> vars;
  input output Sections sections;
protected
  InstNode comp_node;
  Component c;
  Type ty;
  Binding condition;
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
    case Component.TYPED_COMPONENT(condition = condition, ty = ty)
      algorithm
        // Don't add the component if it has a condition that's false.
        if Binding.isBound(condition) and Expression.isFalse(Binding.getTypedExp(condition)) then
          return;
        end if;

        cls := InstNode.getClass(c.classInst);
        vis := if InstNode.isProtected(component) then Visibility.PROTECTED else visibility;

        if isComplexComponent(ty) then
          (vars, sections) := flattenComplexComponent(comp_node, c, cls, ty, vis, prefix, vars, sections);
        else
          (vars, sections) := flattenSimpleComponent(comp_node, c, vis, outerBinding,
            Class.getTypeAttributes(cls), prefix, vars, sections);
        end if;
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown component", sourceInfo());
      then
        fail();

  end match;
end flattenComponent;

function isComplexComponent
  input Type ty;
  output Boolean isComplex;
algorithm
  isComplex := match ty
    case Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT()) then false;
    case Type.COMPLEX() then true;
    case Type.ARRAY() then isComplexComponent(ty.elementType);
    else false;
  end match;
end isComplexComponent;

function flattenSimpleComponent
  input InstNode node;
  input Component comp;
  input Visibility visibility;
  input Option<Binding> outerBinding;
  input list<Modifier> typeAttrs;
  input ComponentRef prefix;
  input output list<Variable> vars;
  input output Sections sections;
protected
  InstNode comp_node = node;
  ComponentRef name;
  Binding binding;
  Type ty;
  Option<SCode.Comment> cmt;
  SourceInfo info;
  Component.Attributes comp_attr;
  Visibility vis;
  Equation eq;
  list<tuple<String, Binding>> ty_attrs;
algorithm
  Component.TYPED_COMPONENT(ty = ty, binding = binding, attributes = comp_attr,
    comment = cmt, info = info) := comp;

  if isSome(outerBinding) then
    SOME(binding) := outerBinding;
  else
    binding := flattenBinding(binding, prefix, comp_node);
  end if;

  name := ComponentRef.prefixCref(comp_node, ty, {}, prefix);

  // If the component is an array component with a binding and at least discrete variability,
  // move the binding into an equation. This avoids having to scalarize the binding.
  if Type.isArray(ty) and Binding.isBound(binding) and
     Component.variability(comp) >= Variability.DISCRETE then
    eq := Equation.ARRAY_EQUALITY(Expression.CREF(ty, name), Binding.getTypedExp(binding), ty,
      ElementSource.createElementSource(info));
    sections := Sections.prependEquation(eq, sections);
    binding := Binding.UNBOUND(NONE());
  end if;

  ty_attrs := list(flattenTypeAttribute(m, name, node) for m in typeAttrs);
  vars := Variable.VARIABLE(name, ty, binding, visibility, comp_attr, ty_attrs, cmt, info) :: vars;
end flattenSimpleComponent;

function flattenTypeAttribute
  input Modifier attr;
  input ComponentRef prefix;
  input InstNode component;
  output tuple<String, Binding> outAttr;
protected
  Binding binding;
algorithm
  binding := flattenBinding(Modifier.binding(attr), prefix, component);
  outAttr := (Modifier.name(attr), binding);
end flattenTypeAttribute;

function getRecordBindings
  input Binding binding;
  output list<Binding> recordBindings;
protected
  Expression binding_exp;
  list<Expression> expl;
algorithm
  binding_exp := Binding.getTypedExp(binding);

  recordBindings := match binding_exp
    case Expression.RECORD() then list(Binding.FLAT_BINDING(e) for e in binding_exp.elements);
    else
      algorithm
        Error.assertion(false, getInstanceName() + " got non-record binding " +
          Expression.toString(binding_exp), sourceInfo());
      then
        fail();
  end match;
end getRecordBindings;

function flattenComplexComponent
  input InstNode node;
  input Component comp;
  input Class cls;
  input Type ty;
  input Visibility visibility;
  input ComponentRef prefix;
  input output list<Variable> vars;
  input output Sections sections;
protected
  list<Dimension> dims;
  ComponentRef name;
  Binding binding;
  Option<Binding> opt_binding;
  Expression binding_exp;
  Equation eq;
  list<Expression> bindings;
algorithm
  dims := Type.arrayDims(ty);
  name := ComponentRef.prefixCref(node, ty, {}, prefix);
  binding := Component.getBinding(comp);

  // Create an equation if there's a binding on a complex component.
  if Binding.isBound(binding) then
    binding_exp := Binding.getTypedExp(binding);

    if not Expression.isRecord(binding_exp) then
      eq := Equation.EQUALITY(Expression.CREF(ty, name),  binding_exp, ty,
        ElementSource.createElementSource(InstNode.info(node)));
      sections := Sections.prependEquation(eq, sections);
      opt_binding := SOME(Binding.UNBOUND(NONE()));
    else
      opt_binding := SOME(flattenBinding(binding, prefix, node));
    end if;
  else
    opt_binding := NONE();
  end if;

  // Flatten the class directly if the component is a scalar, otherwise scalarize it.
  if listEmpty(dims) then
    (vars, sections) := flattenClass(cls, name, visibility, opt_binding, vars, sections);
  else
    (vars, sections) := flattenArray(cls, dims, name, visibility, opt_binding, vars, sections);
  end if;
end flattenComplexComponent;

function flattenArray
  input Class cls;
  input list<Dimension> dimensions;
  input ComponentRef prefix;
  input Visibility visibility;
  input Option<Binding> binding;
  input output list<Variable> vars;
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
    (vars, sections) := flattenClass(cls, sub_pre, visibility, binding, vars, sections);
  else
    dim :: rest_dims := dimensions;
    range_iter := RangeIterator.fromDim(dim);

    while RangeIterator.hasNext(range_iter) loop
      (range_iter, sub_exp) := RangeIterator.next(range_iter);
      (vars, sections) := flattenArray(cls, rest_dims, prefix, visibility,
          binding, vars, sections, Subscript.INDEX(sub_exp) :: subscripts);
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
      Integer binding_level;

    case Binding.UNBOUND() then ();

    case Binding.TYPED_BINDING()
      algorithm
        binding_level := BindingOrigin.level(binding.origin);

        if not binding.isEach and binding_level > 0 then
          subs := List.flatten(ComponentRef.subscriptsN(prefix, binding_level));
          binding.bindingExp := Expression.applySubscripts(subs, binding.bindingExp);
        end if;
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got untyped binding.", sourceInfo());
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
        Equation.EQUALITY(e1, e2, eq.ty, eq.source) :: equations;

    case Equation.FOR()
      then unrollForLoop(eq, prefix, equations);

    case Equation.CONNECT()
      algorithm
        e1 := flattenExp(eq.lhs, prefix);
        e2 := flattenExp(eq.rhs, prefix);
      then
        Equation.CONNECT(e1, e2, eq.source) :: equations;

    case Equation.IF()
      then flattenIfEquation(eq.branches, prefix, eq.source, equations);

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
        Equation.ASSERT(e1, e2, e3, eq.source) :: equations;

    case Equation.TERMINATE()
      algorithm
        e1 := flattenExp(eq.message, prefix);
      then
        Equation.TERMINATE(e1, eq.source) :: equations;

    case Equation.REINIT()
      algorithm
        e1 := flattenExp(eq.cref, prefix);
        e2 := flattenExp(eq.reinitExp, prefix);
      then
        Equation.REINIT(e1, e2, eq.source) :: equations;

    case Equation.NORETCALL()
      algorithm
        e1 := flattenExp(eq.exp, prefix);
      then
        Equation.NORETCALL(e1, eq.source) :: equations;

    else eq :: equations;
  end match;
end flattenEquation;

function flattenIfEquation
  input list<tuple<Expression, list<Equation>>> branches;
  input ComponentRef prefix;
  input DAE.ElementSource source;
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
    equations := Equation.IF(listReverseInPlace(bl), source) :: equations;
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
  input ComponentRef prefix;
  input output list<Equation> equations;
protected
  InstNode iter;
  list<Equation> body, unrolled_body;
  Expression range;
  RangeIterator range_iter;
  Expression val;
algorithm
  Equation.FOR(iterator = iter, range = SOME(range), body = body) := forLoop;

  // Unroll the loop by replacing the iterator with each of its values in the for loop body.
  range_iter := RangeIterator.fromExp(range);
  while RangeIterator.hasNext(range_iter) loop
    (range_iter, val) := RangeIterator.next(range_iter);
    unrolled_body := list(Equation.mapExp(eq,
      function Expression.replaceIterator(iterator = iter, iteratorValue = val)) for eq in body);
    unrolled_body := flattenEquations(unrolled_body, prefix);
    equations := listAppend(unrolled_body, equations);
  end while;
end unrollForLoop;

function flattenAlgorithms
  input output list<list<Statement>> algorithms;
  input ComponentRef prefix;
algorithm
  algorithms := listReverse(
    Statement.mapExpList(alg, function flattenExp(prefix = prefix)) for alg in algorithms);
end flattenAlgorithms;

function resolveConnections
  input output FlatModel flatModel;
  input String name;
protected
  Connections conns;
  list<Equation> conn_eql;
  ConnectionSets.Sets csets;
  array<list<Connector>> csets_array;
algorithm
  // Generate the connect equations and add them to the equation list.
  (flatModel, conns) := Connections.collect(flatModel);
  csets := ConnectionSets.fromConnections(conns);
  csets_array := ConnectionSets.extractSets(csets);
  conn_eql := ConnectEquations.generateEquations(csets_array);
  flatModel.equations := listAppend(conn_eql, flatModel.equations);

  // Evaluate any connection operators if they're used.
  if System.getHasStreamConnectors() or System.getUsesCardinality() then
    flatModel := evaluateConnectionOperators(flatModel, csets, csets_array);
  end if;

  execStat(getInstanceName() + "(" + name + ")");
end resolveConnections;

function evaluateConnectionOperators
  input output FlatModel flatModel;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
algorithm
  flatModel.variables := list(evaluateBindingConnOp(c, sets, setsArray) for c in flatModel.variables);
  flatModel.equations := evaluateEquationsConnOp(flatModel.equations, sets, setsArray);
  flatModel.initialEquations := evaluateEquationsConnOp(flatModel.initialEquations, sets, setsArray);
  // TODO: Implement evaluation for algorithm sections.
end evaluateConnectionOperators;

function evaluateBindingConnOp
  input output Variable var;
  input ConnectionSets.Sets sets;
  input array<list<Connector>> setsArray;
protected
  Binding binding;
  Expression exp, eval_exp;
algorithm
  () := match var
    case Variable.VARIABLE(binding = binding as Binding.TYPED_BINDING(bindingExp = exp))
      algorithm
        eval_exp := ConnectEquations.evaluateOperators(exp, sets, setsArray);

        if not referenceEq(exp, eval_exp) then
          binding.bindingExp := eval_exp;
          var.binding := binding;
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
        Equation.EQUALITY(e1, e2, eq.ty, eq.source);

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
  input FlatModel flatModel;
  input String name;
  output FunctionTree funcs;
algorithm
  funcs := FunctionTree.new();
  funcs := List.fold(flatModel.variables, collectComponentFuncs, funcs);
  funcs := List.fold(flatModel.equations, collectEquationFuncs, funcs);
  funcs := List.fold(flatModel.initialEquations, collectEquationFuncs, funcs);
  funcs := List.fold(flatModel.algorithms, collectAlgorithmFuncs, funcs);
  funcs := List.fold(flatModel.initialAlgorithms, collectAlgorithmFuncs, funcs);
  execStat(getInstanceName() + "(" + name + ")");
end flattenFunctions;

function collectComponentFuncs
  input Variable var;
  input output FunctionTree funcs;
protected
  Binding binding;
  ComponentRef cref;
  InstNode node;
  Type ty;
algorithm
  () := match var
    case Variable.VARIABLE(ty = ty, binding = binding)
      algorithm
        // TODO: Collect functions from the component's type attributes.

        funcs := collectTypeFuncs(ty, funcs);

        // Collect functions used in the component's binding, if it has one.
        if Binding.isBound(binding) then
          funcs := collectExpFuncs(Binding.getTypedExp(binding), funcs);
        end if;
      then
        ();

  end match;
end collectComponentFuncs;

function collectTypeFuncs
  input Type ty;
  input output FunctionTree funcs;
algorithm
  () := match ty
    // Collect external object structors.
    case Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT())
      algorithm
        funcs := collectExternalObjectStructors(ty.complexTy, funcs);
      then
        ();

    else ();
  end match;
end collectTypeFuncs;

function collectExternalObjectStructors
  input ComplexType ty;
  input output FunctionTree funcs;
protected
  InstNode constructor, destructor;
  Function fn;
algorithm
  ComplexType.EXTERNAL_OBJECT(constructor, destructor) := ty;
  CachedData.FUNCTION(funcs = {fn}) := InstNode.getFuncCache(constructor);
  funcs := flattenFunction(fn, funcs);
  CachedData.FUNCTION(funcs = {fn}) := InstNode.getFuncCache(destructor);
  funcs := flattenFunction(fn, funcs);
end collectExternalObjectStructors;

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
    funcs := collectClassFunctions(fn.node, funcs);
  end if;
end flattenFunction;

function collectClassFunctions
  input InstNode clsNode;
  input output FunctionTree funcs;
protected
  Class cls;
  ClassTree cls_tree;
  Sections sections;
  Component comp;
  Binding binding;
algorithm
  cls := InstNode.getClass(clsNode);

  () := match cls
    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE(), sections = sections)
      algorithm
        for c in cls_tree.components loop
          comp := InstNode.component(c);
          funcs := collectTypeFuncs(Component.getType(comp), funcs);
          binding := Component.getBinding(comp);

          if Binding.isBound(binding) then
            funcs := collectExpFuncs(Binding.getTypedExp(binding), funcs);
          end if;
        end for;

        () := match sections
          case Sections.SECTIONS()
            algorithm
              funcs := List.fold(sections.algorithms, collectAlgorithmFuncs, funcs);
            then
              ();

          else ();
        end match;
      then
        ();

    case Class.TYPED_DERIVED()
      algorithm
        funcs := collectClassFunctions(cls.baseClass, funcs);
      then
        ();

    else ();
  end match;
end collectClassFunctions;

annotation(__OpenModelica_Interface="frontend");
end NFFlatten;
