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

import Inst = NFInst;
import Binding = NFBinding;
import NFClass.Class;
import NFComponent.Component;
import NFEquation.Equation;
import Expression = NFExpression;
import NFInstNode.InstNode;
import NFMod.Modifier;
import NFStatement.Statement;

import ComponentReference;
import DAE;
import ExpressionSimplify;
import List;
import Util;
import ElementSource;

import DAEExpression = Expression;
import Dimension = NFDimension;
import Subscript = NFSubscript;
import Type = NFType;
import ComponentRef = NFComponentRef;

protected
import DAEUtil;
import NFCall.Call;
import NFFunction.Function;
import RangeIterator = NFRangeIterator;
import ExecStat.execStat;
import NFClassTree.ClassTree;
import Mutable;
import NFSections.Sections;

public
partial function ExpandScalarFunc<ElementT>
  input ElementT element;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
end ExpandScalarFunc;

function flatten
  input InstNode classInst;
  input String name;
  output DAE.DAElist dae;
  output DAE.FunctionTree funcs;
protected
  list<DAE.Element> elems;
  DAE.Element class_elem;
  SourceInfo info = InstNode.info(classInst);
algorithm
  funcs := DAE.FunctionTree.new();
  (elems, funcs) := flattenNode(classInst, ComponentRef.EMPTY(), {}, funcs);
  elems := listReverse(elems);
  class_elem := DAE.COMP(name, elems, ElementSource.createElementSource(info), NONE());
  dae := DAE.DAE({class_elem});

  execStat(getInstanceName() + "(" + name +")");
end flatten;

function flattenNode
  input InstNode node;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
algorithm
  (elements, funcs) := flattenClass(InstNode.getClass(node), prefix, elements, funcs);
end flattenNode;

function flattenClass
  input Class instance;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
protected
  ClassTree cls_tree;
  Sections sections;
algorithm
  _ := match instance
    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          (elements, funcs) := flattenComponent(c, prefix, elements, funcs);
        end for;

        (elements, funcs) := flattenSections(instance.sections, prefix, elements, funcs);
      then
        ();

    else
      algorithm
        print("Got non-instantiated component " + ComponentRef.toString(prefix) + "\n");
      then
        ();

  end match;
end flattenClass;

function flattenSections
  input Sections sections;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
algorithm
  () := match sections
    case Sections.SECTIONS()
      algorithm
        (elements, funcs) := flattenEquations(sections.equations, prefix, elements, funcs);
        (elements, funcs) := flattenInitialEquations(sections.initialEquations, prefix, elements, funcs);
        (elements, funcs) := flattenAlgorithms(sections.algorithms, elements, funcs);
        (elements, funcs) := flattenInitialAlgorithms(sections.initialAlgorithms, elements, funcs);
      then
        ();

    else ();
  end match;
end flattenSections;

function flattenComponent
  input InstNode component;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;

  import Origin = NFComponentRef.Origin;
protected
  Component c = InstNode.component(component);
  ComponentRef new_pre;
  Type ty;
algorithm
  _ := match c
    case Component.TYPED_COMPONENT()
      algorithm
        ty := Component.getType(c);
        new_pre := ComponentRef.CREF(component, {}, ty, Origin.SCOPE, prefix);

        (elements, funcs) := match ty
          case Type.ARRAY()
            then flattenArray(Component.unliftType(c), ty.dimensions, new_pre, flattenScalar, elements, funcs);
          else flattenScalar(c, new_pre, elements, funcs);
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

function flattenArray<ElementT>
  input ElementT element;
  input list<Dimension> dimensions;
  input ComponentRef prefix;
  input ExpandScalarFunc scalarFunc;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
  input list<Subscript> subscripts = {};
protected
  Dimension dim;
  list<Dimension> rest_dims;
  ComponentRef sub_pre;
  RangeIterator range_iter;
  Expression exp;
algorithm
  if listEmpty(dimensions) then
    sub_pre := ComponentRef.setSubscripts(listReverse(subscripts), prefix);
    (elements, funcs) := scalarFunc(element, sub_pre, elements, funcs);
  else
    dim :: rest_dims := dimensions;

    range_iter := RangeIterator.fromDim(dim);
    while RangeIterator.hasNext(range_iter) loop
      (range_iter, exp) := RangeIterator.next(range_iter);
      (elements, funcs) := flattenArray(element, rest_dims, prefix, scalarFunc,
        elements, funcs, Subscript.INDEX(exp) :: subscripts);
    end while;
  end if;
end flattenArray;

function flattenScalar
  input Component component;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
algorithm
  _ := match component
    local
      Class i;
      DAE.Element var;
      DAE.ComponentRef cref;
      Component.Attributes attr;
      list<DAE.Dimension> dims;
      Option<DAE.Exp> binding_exp;
      SourceInfo info;
      Option<DAE.VariableAttributes> var_attr;

    case Component.TYPED_COMPONENT()
      algorithm
        i := InstNode.getClass(component.classInst);
        info := InstNode.info(component.classInst);

        (elements, funcs) := match i
          case Class.INSTANCED_BUILTIN()
            algorithm
              cref := ComponentRef.toDAE(prefix);
              (binding_exp, funcs) := flattenBinding(component.binding, prefix, funcs);
              attr := component.attributes;
              var_attr := makeVarAttributes(i.attributes, component.ty);

              var := makeDAEVar(cref, Type.toDAE(component.ty), binding_exp, attr, var_attr, info);
            then
              (var :: elements, funcs);

          else flattenClass(i, prefix, elements, funcs);
        end match;
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got untyped component.");
      then
        fail();

  end match;
end flattenScalar;

function flattenFunction
  input Function fn;
  input output DAE.FunctionTree funcs;
protected
  Class cls;
  list<DAE.Element> elems;
  DAE.FunctionDefinition def;
  DAE.Function dfn;
  array<InstNode> comps;
algorithm
  if Function.isCollected(fn) then
    return;
  end if;

  Function.collect(fn);
  cls := InstNode.getClass(Function.instance(fn));

  () := match cls
    case Class.INSTANCED_CLASS(elements = ClassTree.FLAT_TREE(components = comps))
      algorithm
        (elems, funcs) := flattenSections(cls.sections, ComponentRef.EMPTY(), {}, funcs);
        (elems, funcs) := flattenFunctionParams(comps, elems, funcs);

        def := DAE.FunctionDefinition.FUNCTION_DEF(elems);
        dfn := Function.toDAE(fn, {def});
        funcs := DAE.FunctionTree.add(funcs, Function.name(fn), SOME(dfn));
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got unknown function");
      then
       fail();

  end match;
end flattenFunction;

function flattenFunctionParams
  input array<InstNode> components;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
protected
  InstNode node;
  Component comp;
  ComponentRef prefix;
  Type ty;
algorithm
  for i in arrayLength(components):-1:1 loop
    node := components[i];
    comp := InstNode.component(node);
    ty := Component.getType(comp);
    prefix := ComponentRef.fromNode(node, ty, {});

    (elements, funcs) :=
      flattenFunctionParam(comp, InstNode.name(node), prefix, elements, funcs);
  end for;
end flattenFunctionParams;

function flattenFunctionParam
  input Component component;
  input String name;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
algorithm
  () := match component
    local
      Class i;
      SourceInfo info;
      Option<DAE.VariableAttributes> var_attr;
      DAE.ComponentRef cref;
      Component.Attributes attr;
      DAE.Type ty;
      Option<DAE.Exp> binding_exp;
      DAE.Element var;

    case Component.TYPED_COMPONENT()
      algorithm
        i := InstNode.getClass(component.classInst);
        info := InstNode.info(component.classInst);

        ty := Type.toDAE(component.ty);
        cref := DAE.CREF_IDENT(name, ty, {});
        attr := component.attributes;
        (binding_exp, funcs) :=
          flattenBinding(component.binding, prefix, funcs);

        var_attr := match i
          case Class.INSTANCED_BUILTIN()
            then makeVarAttributes(i.attributes, component.ty);
          else NONE();
        end match;

        var := makeDAEVar(cref, ty, binding_exp, attr, var_attr, info);
        elements := var :: elements;
      then
        ();

    else
      algorithm
        assert(false, getInstanceName() + " got untyped component.");
      then
        fail();

  end match;
end flattenFunctionParam;

function makeDAEVar
  input DAE.ComponentRef cref;
  input DAE.Type ty;
  input Option<DAE.Exp> binding;
  input Component.Attributes attr;
  input Option<DAE.VariableAttributes> vattr;
  input SourceInfo info;
  output DAE.Element var;
protected
  DAE.ElementSource source;
algorithm
  source := ElementSource.createElementSource(info);

  var := match attr
    case Component.Attributes.ATTRIBUTES()
      then
        DAE.VAR(cref, attr.variability, attr.direction, attr.parallelism,
          attr.visibility, ty, binding, {}, attr.connectorType,
          source, vattr, NONE(), Absyn.NOT_INNER_OUTER());

    else
      DAE.VAR(cref, DAE.VarKind.VARIABLE(), DAE.VarDirection.BIDIR(),
        DAE.VarParallelism.NON_PARALLEL(), DAE.VarVisibility.PUBLIC(), ty,
        binding, {}, DAE.ConnectorType.NON_CONNECTOR(), source, vattr, NONE(),
        Absyn.NOT_INNER_OUTER());

  end match;
end makeDAEVar;

function flattenBinding
  input Binding binding;
  input ComponentRef prefix;
        output Option<DAE.Exp> bindingExp;
  input output DAE.FunctionTree funcs;
algorithm
  bindingExp := match binding
    local
      list<Subscript> subs;
      Expression e;

    case Binding.UNBOUND() then NONE();

    case Binding.TYPED_BINDING()
      algorithm
        if binding.propagatedLevels < 0 then
          e := binding.bindingExp;
        else
          subs := List.flatten(List.lastN(ComponentRef.allSubscripts(prefix), binding.propagatedLevels + 1));
          e := Expression.subscript(binding.bindingExp, subs);
        end if;

        (e, funcs) := flattenExp(e, funcs);
        bindingExp := SOME(Expression.toDAE(e));
      then
        bindingExp;

    else
      algorithm
        assert(false, getInstanceName() + " got untyped binding.");
      then
        fail();

  end match;
end flattenBinding;

function flattenExp
  input output Expression exp;
  input output DAE.FunctionTree funcs;
algorithm
  () := match exp
    case Expression.CALL()
      algorithm
        funcs := flattenFunction(Call.typedFunction(exp.call), funcs);
      then
        ();

    else ();
  end match;
end flattenExp;

function flattenEquation
  input Equation eq;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
protected
  list<DAE.Element> els = {}, els1, els2;
  Expression e;
  DAE.Exp de;
  Option<DAE.Exp> oe;
  list<DAE.Exp> range;
  DAE.Element el;
algorithm
  elements := match eq
    local
      DAE.Exp lhs, rhs;
      Integer is, ie, step;

    case Equation.EQUALITY()
      algorithm
        (e, funcs) := flattenExp(eq.lhs, funcs);
        lhs := Expression.toDAE(applyExpPrefix(prefix, e));
        (e, funcs) := flattenExp(eq.rhs, funcs);
        rhs := Expression.toDAE(applyExpPrefix(prefix, e));
      then
        DAE.EQUATION(lhs, rhs, ElementSource.createElementSource(eq.info)) :: elements;

    case Equation.IF()
      algorithm
        (el, funcs) := flattenIfEquation(eq.branches, prefix, eq.info, false, funcs);
      then
        el :: elements;

    case Equation.FOR()
      algorithm
        (elements, funcs) := flattenForEquation(eq, prefix, elements, funcs);
      then
        elements;

    case Equation.WHEN()
      algorithm
        (el, funcs) := flattenWhenEquation(eq.branches, prefix, eq.info, funcs);
      then
        el :: elements;

    case Equation.ASSERT()
      then DAE.ASSERT(
        Expression.toDAE(eq.condition),
        Expression.toDAE(eq.message),
        Expression.toDAE(eq.level),
        ElementSource.createElementSource(eq.info)) :: elements;

    case Equation.TERMINATE()
      then
        DAE.TERMINATE(Expression.toDAE(eq.message), ElementSource.createElementSource(eq.info)) :: elements;

    //case Equation.REINIT()
    //  then
    //    DAE.REINIT(eq.cref, eq.reinitExp, ElementSource.createElementSource(eq.info)) :: elements;

    case Equation.NORETCALL()
      then
        DAE.NORETCALL(Expression.toDAE(eq.exp), ElementSource.createElementSource(eq.info)) :: elements;

    case Equation.CONNECT()
      algorithm
        // TODO! FIXME! implement this
      then
        elements;

    else elements;
  end match;
end flattenEquation;

function flattenEquations
  input list<Equation> equations;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
algorithm
  for e in equations loop
    (elements, funcs) := flattenEquation(e, prefix, elements, funcs);
  end for;
end flattenEquations;

function flattenInitialEquation
  input Equation eq;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
algorithm
  elements := match eq
    local
      DAE.Exp lhs, rhs;
      DAE.Element el;

    case Equation.EQUALITY()
      algorithm
        lhs := Expression.toDAE(applyExpPrefix(prefix, eq.lhs));
        rhs := Expression.toDAE(applyExpPrefix(prefix, eq.rhs));
      then
        DAE.INITIALEQUATION(lhs, rhs, ElementSource.createElementSource(eq.info)) :: elements;

    case Equation.IF()
      algorithm
        (el, funcs) := flattenIfEquation(eq.branches, prefix, eq.info, true, funcs);
      then
        el :: elements;

    else elements;
  end match;
end flattenInitialEquation;

function flattenInitialEquations
  input list<Equation> equations;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
algorithm
  for eq in equations loop
    (elements, funcs) := flattenInitialEquation(eq, prefix, elements, funcs);
  end for;
end flattenInitialEquations;

function flattenForEquation
  input Equation forEq;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
protected
  InstNode iterator;
  Binding binding;
  Expression range;
  list<Equation> body;
  list<DAE.Element> dbody, dbody_unrolled;
  SourceInfo info;
  RangeIterator range_iter;
  Expression exp;
  DAE.ComponentRef iter_cr;
  Boolean b;
algorithm
  Equation.FOR(iterator = iterator, body = body, info = info) := forEq;

  // Flatten the body of the for loop.
  (dbody, funcs) := flattenEquations(body, prefix, {}, funcs);

  // Get the range to iterate over.
  Component.ITERATOR(binding = binding) := InstNode.component(iterator);
  SOME(range) := Binding.typedExp(binding);
  range_iter := RangeIterator.fromExp(range);

  // Create a DAE.ComponentRef for the replace function. The type doesn't matter
  // here, only the name is used when replacing.
  iter_cr := DAE.CREF_IDENT(InstNode.name(iterator), DAE.Type.T_UNKNOWN(), {});

  // Unroll the loop by iterating over the body and replacing the iterator with its value.
  while RangeIterator.hasNext(range_iter) loop
    (range_iter, exp) := RangeIterator.next(range_iter);
    dbody_unrolled := DAEUtil.replaceCrefInDAEElements(dbody, iter_cr, Expression.toDAE(exp));
    elements := listAppend(dbody_unrolled, elements);
  end while;
end flattenForEquation;

function flattenIfEquation
  input list<tuple<Expression, list<Equation>>> ifBranches;
  input ComponentRef prefix;
  input SourceInfo info;
  input Boolean isInitial;
        output DAE.Element ifEquation;
  input output DAE.FunctionTree funcs;
protected
  list<Expression> conditions = {};
  list<DAE.Element> branch, else_branch;
  list<list<DAE.Element>> branches = {};
  list<DAE.Exp> dconds;
algorithm
  for b in ifBranches loop
    conditions := Util.tuple21(b) :: conditions;
    (branch, funcs) := flattenEquations(Util.tuple22(b), prefix, {}, funcs);
    branches := branch :: branches;
  end for;

  // Transform the last branch to an else-branch if its condition is true.
  if Expression.isTrue(listHead(conditions)) then
    conditions := listRest(conditions);
    else_branch := listHead(branches);
    branches := listRest(branches);
  else
    else_branch := {};
  end if;

  conditions := listReverse(conditions);
  branches := listReverse(branches);
  dconds := list(Expression.toDAE(c) for c in conditions);

  if isInitial then
    ifEquation := DAE.INITIAL_IF_EQUATION(dconds, branches, else_branch,
      ElementSource.createElementSource(info));
  else
    ifEquation := DAE.IF_EQUATION(dconds, branches, else_branch,
      ElementSource.createElementSource(info));
  end if;
end flattenIfEquation;

function flattenWhenEquation
  input list<tuple<Expression, list<Equation>>> whenBranches;
  input ComponentRef prefix;
  input SourceInfo info;
        output DAE.Element whenEquation;
  input output DAE.FunctionTree funcs;
protected
  DAE.Exp cond1,cond2;
  list<DAE.Element> els1, els2;
  tuple<Expression, list<Equation>> head;
  list<tuple<Expression, list<Equation>>> rest;
  Option<DAE.Element> owhenEquation = NONE();
algorithm

  head::rest := whenBranches;
  cond1 := Expression.toDAE(Util.tuple21(head));
  (els1, funcs) := flattenEquations(Util.tuple22(head), prefix, {}, funcs);
  rest := listReverse(rest);

  for b in rest loop
    cond2 := Expression.toDAE(Util.tuple21(b));
    (els2, funcs) := flattenEquations(Util.tuple22(b), prefix, {}, funcs);
    whenEquation := DAE.WHEN_EQUATION(cond2, els2, owhenEquation, ElementSource.createElementSource(info));
    owhenEquation := SOME(whenEquation);
  end for;

  whenEquation := DAE.WHEN_EQUATION(cond1, els1, owhenEquation, ElementSource.createElementSource(info));

end flattenWhenEquation;

function flattenStatement
  input Statement alg;
  input output list<DAE.Statement> stmts;
  input output DAE.FunctionTree funcs;
protected
  list<DAE.Statement> sts;
  Expression e;
  DAE.Exp de;
  Option<DAE.Exp> oe;
  list<DAE.Exp> range;
algorithm
  stmts := match alg
    local
      DAE.Exp lhs, rhs;
      Integer is, ie, step;
      DAE.Type ty;
      DAE.Statement stmt;

    case Statement.ASSIGNMENT()
      algorithm
        (e, funcs) := flattenExp(alg.lhs, funcs);
        lhs := Expression.toDAE(e);
        (e, funcs) := flattenExp(alg.rhs, funcs);
        rhs := Expression.toDAE(e);
        ty := DAEExpression.typeof(lhs);
      then
        DAE.STMT_ASSIGN(ty, lhs, rhs, ElementSource.createElementSource(alg.info)) :: stmts;

    case Statement.FUNCTION_ARRAY_INIT()
      then
        DAE.STMT_ARRAY_INIT(alg.name, Type.toDAE(alg.ty), ElementSource.createElementSource(alg.info)) :: stmts;

    case Statement.FOR()
      algorithm
        (stmt, funcs) := flattenForStatement(alg, funcs);
      then
        stmt :: stmts;

    case Statement.IF()
      algorithm
        (stmt, funcs) := flattenIfStatement(alg.branches, alg.info, funcs);
      then
        stmt :: stmts;

    case Statement.WHEN()
      algorithm
        (stmt, funcs) := flattenWhenStatement(alg.branches, alg.info, funcs);
      then
        stmt :: stmts;

    case Statement.ASSERT()
      then
        DAE.STMT_ASSERT(
          Expression.toDAE(alg.condition),
          Expression.toDAE(alg.message),
          Expression.toDAE(alg.level),
          ElementSource.createElementSource(alg.info)) :: stmts;

    case Statement.TERMINATE()
      then
        DAE.STMT_TERMINATE(Expression.toDAE(alg.message),
          ElementSource.createElementSource(alg.info)) :: stmts;

    //case Statement.REINIT()
    //  then
    //    DAE.STMT_REINIT(
    //      Expression.toDAE(Expression.makeCrefExp(alg.cref, ComponentReference.crefType(alg.cref))),
    //      Expression.toDAE(alg.reinitExp),
    //      ElementSource.createElementSource(alg.info)) :: stmts;

    case Statement.NORETCALL()
      then
        DAE.STMT_NORETCALL(Expression.toDAE(alg.exp),
          ElementSource.createElementSource(alg.info)) :: stmts;

    case Statement.WHILE()
      algorithm
        // flatten the list of statements
        (sts, funcs) := flattenStatements(alg.body, {}, funcs);
      then
        DAE.STMT_WHILE(Expression.toDAE(alg.condition), sts,
          ElementSource.createElementSource(alg.info)) :: stmts;

    case Statement.RETURN()
      then
        DAE.STMT_RETURN(ElementSource.createElementSource(alg.info)) :: stmts;

    case Statement.BREAK()
      then
        DAE.STMT_BREAK(ElementSource.createElementSource(alg.info)) :: stmts;

    case Statement.FAILURE()
      algorithm
        // flatten the list of statements
        (sts, funcs) := flattenStatements(alg.body, {}, funcs);
      then
        DAE.STMT_FAILURE(sts, ElementSource.createElementSource(alg.info)) :: stmts;

    else stmts;
  end match;
end flattenStatement;

public function flattenStatements
  input list<Statement> algs;
  input output list<DAE.Statement> stmts;
  input output DAE.FunctionTree funcs;
algorithm
  for s in algs loop
    (stmts, funcs) := flattenStatement(s, stmts, funcs);
  end for;

  stmts := listReverse(stmts);
end flattenStatements;

function flattenAlgorithmStmts
  input list<Statement> algSection;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
protected
  DAE.Algorithm alg;
  list<DAE.Statement> stmts;
algorithm
  (stmts, funcs) := flattenStatements(algSection, {}, funcs);
  alg := DAE.ALGORITHM_STMTS(stmts);
  elements := DAE.ALGORITHM(alg, DAE.emptyElementSource) :: elements;
end flattenAlgorithmStmts;

function flattenAlgorithms
  input list<list<Statement>> algorithms;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
algorithm
  for a in algorithms loop
    (elements, funcs) := flattenAlgorithmStmts(a, elements, funcs);
  end for;
end flattenAlgorithms;

function flattenInitialAlgorithmStmts
  input list<Statement> algSection;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
protected
  DAE.Algorithm alg;
  list<DAE.Statement> stmts;
algorithm
  (stmts, funcs) := flattenStatements(algSection, {}, funcs);
  alg := DAE.ALGORITHM_STMTS(stmts);
  elements := DAE.INITIALALGORITHM(alg, DAE.emptyElementSource) :: elements;
end flattenInitialAlgorithmStmts;

function flattenInitialAlgorithms
  input list<list<Statement>> algorithms;
  input output list<DAE.Element> elements;
  input output DAE.FunctionTree funcs;
algorithm
  for a in algorithms loop
    (elements, funcs) := flattenInitialAlgorithmStmts(a, elements, funcs);
  end for;
end flattenInitialAlgorithms;

function flattenIfStatement
  input list<tuple<Expression, list<Statement>>> ifBranches;
  input SourceInfo info;
        output DAE.Statement ifStatement;
  input output DAE.FunctionTree funcs;
protected
  DAE.Exp cond1, cond2;
  list<DAE.Statement> stmts1, stmts2;
  tuple<Expression, list<Statement>> head;
  list<tuple<Expression, list<Statement>>> rest;
  DAE.Else elseStatement = DAE.NOELSE();
algorithm
  head :: rest := ifBranches;
  cond1 := Expression.toDAE(Util.tuple21(head));
  (stmts1, funcs) := flattenStatements(Util.tuple22(head), {}, funcs);
  rest := listReverse(rest);

  for b in rest loop
    cond2 := Expression.toDAE(Util.tuple21(b));
    (stmts2, funcs) := flattenStatements(Util.tuple22(b), {}, funcs);
    elseStatement := DAE.ELSEIF(cond2, stmts2, elseStatement);
  end for;

  ifStatement := DAE.STMT_IF(cond1, stmts1,  elseStatement, ElementSource.createElementSource(info));
end flattenIfStatement;

function flattenWhenStatement
  input list<tuple<Expression, list<Statement>>> whenBranches;
  input SourceInfo info;
        output DAE.Statement whenStatement;
  input output DAE.FunctionTree funcs;
protected
  DAE.Exp cond1,cond2;
  list<DAE.Statement> stmts1, stmts2;
  tuple<Expression, list<Statement>> head;
  list<tuple<Expression, list<Statement>>> rest;
  Option<DAE.Statement> owhenStatement = NONE();
algorithm
  head :: rest := whenBranches;
  cond1 := Expression.toDAE(Util.tuple21(head));
  (stmts1, funcs) := flattenStatements(Util.tuple22(head), {}, funcs);
  rest := listReverse(rest);

  for b in rest loop
    cond2 := Expression.toDAE(Util.tuple21(b));
    (stmts2, funcs) := flattenStatements(Util.tuple22(b), {}, funcs);
    whenStatement := DAE.STMT_WHEN(cond2, {}, false, stmts2, owhenStatement, ElementSource.createElementSource(info));
    owhenStatement := SOME(whenStatement);
  end for;

  whenStatement := DAE.STMT_WHEN(cond1, {}, false, stmts1, owhenStatement, ElementSource.createElementSource(info));
end flattenWhenStatement;

function flattenForStatement
  input Statement forStmt;
        output DAE.Statement forDAE;
  input output DAE.FunctionTree funcs;
protected
  InstNode iterator;
  Type ty;
  Binding binding;
  Expression range;
  list<Statement> body;
  list<DAE.Statement> dbody;
  SourceInfo info;
algorithm
  Statement.FOR(iterator = iterator, body = body, info = info) := forStmt;

  (dbody, funcs) := flattenStatements(body, {}, funcs);

  Component.ITERATOR(ty = ty, binding = binding) := InstNode.component(iterator);
  SOME(range) := Binding.typedExp(binding);

  forDAE := DAE.STMT_FOR(Type.toDAE(ty), Type.isArray(ty),
    InstNode.name(iterator), 0, Expression.toDAE(range), dbody,
    ElementSource.createElementSource(info));
end flattenForStatement;

function applyExpPrefix
  input ComponentRef prefix;
  input output Expression exp;
algorithm
  exp := match exp
    case Expression.CREF()
      algorithm
        exp.cref := ComponentRef.transferSubscripts(prefix, exp.cref);
      then
        exp;

    else exp;
  end match;
end applyExpPrefix;

function makeVarAttributes
  input list<Modifier> mods;
  input Type ty;
  output Option<DAE.VariableAttributes> attributes;
algorithm
  if listEmpty(mods) then
    attributes := NONE();
    return;
  end if;

  attributes := match ty
    case Type.REAL() then makeRealVarAttributes(mods);
    case Type.INTEGER() then makeIntVarAttributes(mods);
    case Type.BOOLEAN() then makeBoolVarAttributes(mods);
    case Type.STRING() then makeStringVarAttributes(mods);
    case Type.ENUMERATION() then makeEnumVarAttributes(mods);
    else NONE();
  end match;
end makeVarAttributes;

function makeRealVarAttributes
  input list<Modifier> mods;
  output Option<DAE.VariableAttributes> attributes;
protected
  Option<DAE.Exp> quantity = NONE(), unit = NONE(), displayUnit = NONE();
  Option<DAE.Exp> min = NONE(), max = NONE(), start = NONE(), fixed = NONE(), nominal = NONE();
  Option<DAE.StateSelect> state_select = NONE();
algorithm
  for m in mods loop
    () := match Modifier.name(m)
      case "displayUnit" algorithm displayUnit := makeVarAttribute(m); then ();
      case "fixed"       algorithm fixed := makeVarAttribute(m); then ();
      case "max"         algorithm max := makeVarAttribute(m); then ();
      case "min"         algorithm min := makeVarAttribute(m); then ();
      case "nominal"     algorithm nominal := makeVarAttribute(m); then ();
      case "quantity"    algorithm quantity := makeVarAttribute(m); then ();
      case "start"       algorithm start := makeVarAttribute(m); then ();
      case "stateSelect" algorithm state_select := makeStateSelectAttribute(m); then ();
      case "unit"        algorithm unit := makeVarAttribute(m); then ();

      // The attributes should already be type checked, so we shouldn't get any
      // unknown attributes here.
      else
        algorithm
          assert(false, getInstanceName() + " got unknown type attribute " +
            Modifier.name(m));
        then
          fail();
    end match;
  end for;

  attributes := SOME(DAE.VariableAttributes.VAR_ATTR_REAL(
    quantity, unit, displayUnit, min, max, start, fixed, nominal,
    state_select, NONE(), NONE(), NONE(), NONE(), NONE(), NONE()));
end makeRealVarAttributes;

function makeIntVarAttributes
  input list<Modifier> mods;
  output Option<DAE.VariableAttributes> attributes;
protected
  Option<DAE.Exp> quantity = NONE(), min = NONE(), max = NONE();
  Option<DAE.Exp> start = NONE(), fixed = NONE();
algorithm
  for m in mods loop
    () := match Modifier.name(m)
      case "quantity" algorithm quantity := makeVarAttribute(m); then ();
      case "min"      algorithm min := makeVarAttribute(m); then ();
      case "max"      algorithm max := makeVarAttribute(m); then ();
      case "start"    algorithm start := makeVarAttribute(m); then ();
      case "fixed"    algorithm fixed := makeVarAttribute(m); then ();

      // The attributes should already be type checked, so we shouldn't get any
      // unknown attributes here.
      else
        algorithm
          assert(false, getInstanceName() + " got unknown type attribute " +
            Modifier.name(m));
        then
          fail();
    end match;
  end for;

  attributes := SOME(DAE.VariableAttributes.VAR_ATTR_INT(
    quantity, min, max, start, fixed,
    NONE(), NONE(), NONE(), NONE(), NONE(), NONE()));
end makeIntVarAttributes;

function makeBoolVarAttributes
  input list<Modifier> mods;
  output Option<DAE.VariableAttributes> attributes;
protected
  Option<DAE.Exp> quantity = NONE(), start = NONE(), fixed = NONE();
algorithm
  for m in mods loop
    () := match Modifier.name(m)
      case "quantity" algorithm quantity := makeVarAttribute(m); then ();
      case "start"    algorithm start := makeVarAttribute(m); then ();
      case "fixed"    algorithm fixed := makeVarAttribute(m); then ();

      // The attributes should already be type checked, so we shouldn't get any
      // unknown attributes here.
      else
        algorithm
          assert(false, getInstanceName() + " got unknown type attribute " +
            Modifier.name(m));
        then
          fail();
    end match;
  end for;

  attributes := SOME(DAE.VariableAttributes.VAR_ATTR_BOOL(
    quantity, start, fixed, NONE(), NONE(), NONE(), NONE()));
end makeBoolVarAttributes;

function makeStringVarAttributes
  input list<Modifier> mods;
  output Option<DAE.VariableAttributes> attributes;
protected
  Option<DAE.Exp> quantity = NONE(), start = NONE();
algorithm
  for m in mods loop
    () := match Modifier.name(m)
      case "quantity" algorithm quantity := makeVarAttribute(m); then ();
      case "start"    algorithm start := makeVarAttribute(m); then ();

      // The attributes should already be type checked, so we shouldn't get any
      // unknown attributes here.
      else
        algorithm
          assert(false, getInstanceName() + " got unknown type attribute " +
            Modifier.name(m));
        then
          fail();
    end match;
  end for;

  attributes := SOME(DAE.VariableAttributes.VAR_ATTR_STRING(
    quantity, start, NONE(), NONE(), NONE(), NONE()));
end makeStringVarAttributes;

function makeEnumVarAttributes
  input list<Modifier> mods;
  output Option<DAE.VariableAttributes> attributes;
protected
  Option<DAE.Exp> quantity = NONE(), min = NONE(), max = NONE();
  Option<DAE.Exp> start = NONE(), fixed = NONE();
algorithm
  for m in mods loop
    () := match Modifier.name(m)
      case "fixed"       algorithm fixed := makeVarAttribute(m); then ();
      case "max"         algorithm max := makeVarAttribute(m); then ();
      case "min"         algorithm min := makeVarAttribute(m); then ();
      case "quantity"    algorithm quantity := makeVarAttribute(m); then ();
      case "start"       algorithm start := makeVarAttribute(m); then ();

      // The attributes should already be type checked, so we shouldn't get any
      // unknown attributes here.
      else
        algorithm
          assert(false, getInstanceName() + " got unknown type attribute " +
            Modifier.name(m));
        then
          fail();
    end match;
  end for;

  attributes := SOME(DAE.VariableAttributes.VAR_ATTR_ENUMERATION(
    quantity, min, max, start, fixed, NONE(), NONE(), NONE(), NONE()));
end makeEnumVarAttributes;

function makeVarAttribute
  input Modifier mod;
  output Option<DAE.Exp> attribute;
algorithm
  attribute := match mod
    local
      Expression exp;

    case Modifier.MODIFIER(binding = Binding.TYPED_BINDING(bindingExp = exp))
      then SOME(Expression.toDAE(exp));

    else
      algorithm
        assert(false, getInstanceName() + " got untyped binding");
      then
        fail();

  end match;
end makeVarAttribute;

function makeStateSelectAttribute
  input Modifier mod;
  output Option<DAE.StateSelect> stateSelect;
algorithm
  stateSelect := match mod
    local
      Expression exp;
      InstNode node;

    case Modifier.MODIFIER(binding = Binding.TYPED_BINDING(
        bindingExp = exp as Expression.ENUM_LITERAL(
          ty = Type.ENUMERATION(typePath = Absyn.IDENT("StateSelect")))))
      then
        SOME(lookupStateSelectMember(exp.name));

    case Modifier.MODIFIER(binding = Binding.TYPED_BINDING(
        bindingExp = Expression.CREF(cref = ComponentRef.CREF(
          ty = Type.ENUMERATION(typePath = Absyn.IDENT("StateSelect")),
          node = node))))
      then
        SOME(lookupStateSelectMember(InstNode.name(node)));

    case Modifier.MODIFIER(binding = Binding.TYPED_BINDING())
      algorithm
        assert(false, getInstanceName() + " got non StateSelect value");
      then
        fail();

    else
      algorithm
        assert(false, getInstanceName() + " git untyped binding");
      then
        fail();

  end match;
end makeStateSelectAttribute;

function lookupStateSelectMember
  input String name;
  output DAE.StateSelect stateSelect;
algorithm
  stateSelect := match name
    case "never" then DAE.StateSelect.NEVER();
    case "avoid" then DAE.StateSelect.AVOID();
    case "default" then DAE.StateSelect.DEFAULT();
    case "prefer" then DAE.StateSelect.PREFER();
    case "always" then DAE.StateSelect.ALWAYS();
    else
      algorithm
        assert(false, getInstanceName() + " got unknown StateSelect literal");
      then
        fail();
  end match;
end lookupStateSelectMember;

annotation(__OpenModelica_Interface="frontend");
end NFFlatten;
