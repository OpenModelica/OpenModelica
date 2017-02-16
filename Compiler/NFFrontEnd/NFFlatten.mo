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


  New instantiation, enable with +d=newInst.
"

import Inst = NFInst;
import Binding = NFBinding;
import NFClass.Class;
import NFComponent.Component;
import NFEquation.Equation;
import NFExpression.Expression;
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

public
partial function ExpandScalarFunc<ElementT>
  input ElementT element;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
end ExpandScalarFunc;

function flatten
  input InstNode classInst;
  output DAE.DAElist dae;
protected
  list<DAE.Element> elems;
  DAE.Element class_elem;
  SourceInfo info = InstNode.info(classInst);
algorithm
  elems := flattenNode(classInst);
  elems := listReverse(elems);
  class_elem := DAE.COMP(InstNode.name(classInst), elems, ElementSource.createElementSource(info), NONE());
  dae := DAE.DAE({class_elem});
end flatten;

function flattenNode
  input InstNode node;
  input ComponentRef prefix = ComponentRef.EMPTY();
  input list<DAE.Element> inElements = {};
  output list<DAE.Element> elements;
algorithm
  elements := flattenClass(InstNode.getClass(node), prefix, inElements);
end flattenNode;

function flattenClass
  input Class instance;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
algorithm
  _ := match instance
    case Class.INSTANCED_CLASS()
      algorithm
        for c in instance.components loop
          if InstNode.isComponent(c) then
            elements := flattenComponent(c, prefix, elements);
          else
            elements := flattenNode(c, prefix, elements);
          end if;
        end for;

        elements := flattenEquations(instance.equations, prefix, elements);
        elements := flattenInitialEquations(instance.initialEquations, prefix, elements);
        elements := flattenAlgorithms(instance.algorithms, elements);
        elements := flattenInitialAlgorithms(instance.initialAlgorithms, elements);
      then
        ();

    else
      algorithm
        print("Got non-instantiated component " + ComponentRef.toString(prefix) + "\n");
      then
        ();

  end match;
end flattenClass;

function flattenComponent
  input InstNode component;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;

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

        elements := match ty
          case Type.ARRAY()
            then flattenArray(Component.unliftType(c), ty.dimensions, new_pre, flattenScalar, elements);
          else flattenScalar(c, new_pre, elements);
        end match;
      then
        ();

    else
      algorithm
        assert(false, "flattenComponent got unknown component");
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
  input list<Subscript> subscripts = {};
protected
  Dimension dim;
  list<Dimension> rest_dims;
  ComponentRef sub_pre;
  Option<Expression> oe;
  Expression e;
  Integer i;
algorithm
  if listEmpty(dimensions) then
    sub_pre := ComponentRef.setSubscripts(listReverse(subscripts), prefix);
    elements := scalarFunc(element, sub_pre, elements);
  else
    dim :: rest_dims := dimensions;

    elements := match dim
      case Dimension.INTEGER()
        then flattenArrayIntDim(element, dim.size, rest_dims, prefix,
          subscripts, scalarFunc, elements);

      case Dimension.BOOLEAN()
        then flattenArrayBoolDim(element, rest_dims, prefix, subscripts,
          scalarFunc, elements);

      case Dimension.ENUM()
        then flattenArrayEnumDim(element, dim.enumType, rest_dims, prefix,
          subscripts, scalarFunc, elements);

      else
        algorithm
          assert(false, getInstanceName() + " got unknown dimension");
        then
          fail();

    end match;
  end if;
end flattenArray;

function flattenArrayIntDim<ElementT>
  input ElementT element;
  input Integer dimSize;
  input list<Dimension> restDims;
  input ComponentRef prefix;
  input list<Subscript> subscripts;
  input ExpandScalarFunc scalarFunc;
  input output list<DAE.Element> elements;
protected
  list<Subscript> subs;
algorithm
  for i in 1:dimSize loop
    subs := Subscript.INDEX(Expression.INTEGER(i)) :: subscripts;
    elements := flattenArray(element, restDims, prefix, scalarFunc, elements, subs);
  end for;
end flattenArrayIntDim;

function flattenArrayBoolDim<ElementT>
  input ElementT element;
  input list<Dimension> restDims;
  input ComponentRef prefix;
  input list<Subscript> subscripts;
  input ExpandScalarFunc scalarFunc;
  input output list<DAE.Element> elements;
protected
  list<Subscript> subs;
algorithm
  subs := Subscript.INDEX(Expression.BOOLEAN(false)) :: subscripts;
  elements := flattenArray(element, restDims, prefix, scalarFunc, elements, subs);
  subs := Subscript.INDEX(Expression.BOOLEAN(true)) :: subscripts;
  elements := flattenArray(element, restDims, prefix, scalarFunc, elements, subs);
end flattenArrayBoolDim;

function flattenArrayEnumDim<ElementT>
  input ElementT element;
  input Type enumType;
  input list<Dimension> restDims;
  input ComponentRef prefix;
  input list<Subscript> subscripts;
  input ExpandScalarFunc scalarFunc;
  input output list<DAE.Element> elements;
protected
  Integer i = 1;
  Expression enum_exp;
  list<String> literals;
  list<Subscript> subs;
algorithm
  literals := match enumType
    case Type.ENUMERATION() then enumType.literals;
    else
      algorithm
        assert(false, getInstanceName() + " got non-enum type");
      then
        fail();
  end match;

  for l in literals loop
    enum_exp := Expression.ENUM_LITERAL(enumType, l, i);
    i := i + 1;

    subs := Subscript.INDEX(enum_exp) :: subscripts;
    elements := flattenArray(element, restDims, prefix, scalarFunc, elements, subs);
  end for;
end flattenArrayEnumDim;

function flattenScalar
  input Component component;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
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

        elements := match i
          case Class.INSTANCED_BUILTIN()
            algorithm
              cref := ComponentRef.toDAE(prefix);
              binding_exp := flattenBinding(component.binding, prefix);
              attr := component.attributes;
              var_attr := makeVarAttributes(i.attributes, component.ty);

              var := DAE.VAR(
                cref,
                attr.variability,
                attr.direction,
                DAE.NON_PARALLEL(),
                attr.visibility,
                Type.toDAE(component.ty),
                binding_exp,
                {},
                attr.connectorType,
                ElementSource.createElementSource(info),
                var_attr,
                NONE(),
                Absyn.NOT_INNER_OUTER());
            then
              var :: elements;

          else flattenClass(i, prefix, elements);
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

function flattenBinding
  input Binding binding;
  input ComponentRef prefix;
  output Option<DAE.Exp> bindingExp;
algorithm
  bindingExp := match binding
    local
      list<Subscript> subs;
      DAE.Exp e;

    case Binding.UNBOUND() then NONE();

    case Binding.TYPED_BINDING()
      algorithm
        if binding.propagatedDims <= 0 then
          bindingExp := SOME(Expression.toDAE(binding.bindingExp));
        else
          subs := List.lastN(List.flatten(ComponentRef.allSubscripts(prefix)), binding.propagatedDims);
          bindingExp := SOME(Expression.toDAE(Expression.subscript(binding.bindingExp, subs)));
        end if;
      then
        bindingExp;

    else
      algorithm
        assert(false, getInstanceName() + " got untyped binding.");
      then
        fail();

  end match;
end flattenBinding;

function flattenEquation
  input Equation eq;
  input ComponentRef prefix;
  input output list<DAE.Element> elements = {};
protected
  list<DAE.Element> els = {}, els1, els2;
  Expression e;
  DAE.Exp de;
  Option<DAE.Exp> oe;
  list<DAE.Exp> range;
algorithm
  elements := match eq
    local
      DAE.Exp lhs, rhs;
      Integer is, ie, step;

    case Equation.EQUALITY()
      algorithm
        lhs := Expression.toDAE(applyExpPrefix(prefix, eq.lhs));
        rhs := Expression.toDAE(applyExpPrefix(prefix, eq.rhs));
      then
        DAE.EQUATION(lhs, rhs, ElementSource.createElementSource(eq.info)) :: elements;

    case Equation.IF()
      then flattenIfEquation(eq.branches, prefix, eq.info, false) :: elements;

    case Equation.FOR()
      algorithm
        // flatten the equations
        els1 := List.fold1(eq.body, flattenEquation, prefix, {});

        // deal with the range
        if isSome(eq.range) then
          SOME(e) := eq.range;
          SOME(de) := DAEUtil.evaluateExp(Expression.toDAE(e), elements);
          range := match (de)
                    case DAE.ARRAY(array = range) then range;
                    case DAE.RANGE(_, DAE.ICONST(is), SOME(DAE.ICONST(step)), DAE.ICONST(ie))
                      then List.map(ExpressionSimplify.simplifyRange(is, step, ie), DAEExpression.makeIntegerExp);
                    case DAE.RANGE(_, DAE.ICONST(is), _, DAE.ICONST(ie))
                      then if is <= ie
                           then List.map(ExpressionSimplify.simplifyRange(is, 1, ie), DAEExpression.makeIntegerExp)
                           else List.map(ExpressionSimplify.simplifyRange(is, -1, ie), DAEExpression.makeIntegerExp);
                  end match;
          // replace index in elements
          for i in range loop
            els := DAEUtil.replaceCrefInDAEElements(els1, DAE.CREF_IDENT(eq.name, Type.toDAE(eq.indexType), {}), i);
            elements := listAppend(els, elements);
          end for;
        end if;
      then
        elements;

    case Equation.WHEN()
      then flattenWhenEquation(eq.branches, prefix, eq.info) :: elements;

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
  input output list<DAE.Element> elements = {};
algorithm
  elements := List.fold1(equations, flattenEquation, prefix, elements);
end flattenEquations;

function flattenInitialEquation
  input Equation eq;
  input ComponentRef prefix;
  input output list<DAE.Element> elements;
algorithm
  elements := match eq
    local
      DAE.Exp lhs, rhs;

    case Equation.EQUALITY()
      algorithm
        lhs := Expression.toDAE(applyExpPrefix(prefix, eq.lhs));
        rhs := Expression.toDAE(applyExpPrefix(prefix, eq.rhs));
      then
        DAE.INITIALEQUATION(lhs, rhs, ElementSource.createElementSource(eq.info)) :: elements;

    case Equation.IF()
      then flattenIfEquation(eq.branches, prefix, eq.info, true) :: elements;

    else elements;
  end match;
end flattenInitialEquation;

function flattenInitialEquations
  input list<Equation> equations;
  input ComponentRef prefix;
  input output list<DAE.Element> elements = {};
algorithm
  elements := List.fold1(equations, flattenInitialEquation, prefix, elements);
end flattenInitialEquations;

function flattenIfEquation
  input list<tuple<Expression, list<Equation>>> ifBranches;
  input ComponentRef prefix;
  input SourceInfo info;
  input Boolean isInitial;
  output DAE.Element ifEquation;
protected
  list<Expression> conditions = {};
  list<DAE.Element> branch, else_branch;
  list<list<DAE.Element>> branches = {};
  list<DAE.Exp> dconds;
algorithm
  for b in ifBranches loop
    conditions := Util.tuple21(b) :: conditions;
    branches := flattenEquations(Util.tuple22(b), prefix) :: branches;
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
protected
  DAE.Exp cond1,cond2;
  list<DAE.Element> els1, els2;
  tuple<Expression, list<Equation>> head;
  list<tuple<Expression, list<Equation>>> rest;
  Option<DAE.Element> owhenEquation = NONE();
algorithm

  head::rest := whenBranches;
  cond1 := Expression.toDAE(Util.tuple21(head));
  els1 := flattenEquations(Util.tuple22(head), prefix);
  rest := listReverse(rest);

  for b in rest loop
    cond2 := Expression.toDAE(Util.tuple21(b));
    els2 := flattenEquations(Util.tuple22(b), prefix);
    whenEquation := DAE.WHEN_EQUATION(cond2, els2, owhenEquation, ElementSource.createElementSource(info));
    owhenEquation := SOME(whenEquation);
  end for;

  whenEquation := DAE.WHEN_EQUATION(cond1, els1, owhenEquation, ElementSource.createElementSource(info));

end flattenWhenEquation;

function flattenStatement
  input Statement alg;
  input output list<DAE.Statement> stmts = {};
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

    case Statement.ASSIGNMENT()
      algorithm
        //lhs := ExpressionSimplify.simplify(alg.lhs);
        //rhs := ExpressionSimplify.simplify(alg.rhs);
        lhs := Expression.toDAE(alg.lhs);
        rhs := Expression.toDAE(alg.rhs);
        ty := DAEExpression.typeof(lhs);
      then
        DAE.STMT_ASSIGN(ty, lhs, rhs, ElementSource.createElementSource(alg.info)) :: stmts;

    case Statement.FUNCTION_ARRAY_INIT()
      then
        DAE.STMT_ARRAY_INIT(alg.name, Type.toDAE(alg.ty), ElementSource.createElementSource(alg.info)) :: stmts;

    case Statement.FOR()
      algorithm
        // flatten the list of statements
        sts := flattenStatements(alg.body);
        if isSome(alg.range) then
          SOME(e) := alg.range;
          de := Expression.toDAE(e);
        else
          de := DAE.SCONST("NO RANGE GIVEN TODO FIXME");
        end if;
      then
        DAE.STMT_FOR(Type.toDAE(alg.indexType), false, alg.name, alg.index, de, sts, ElementSource.createElementSource(alg.info)) :: stmts;

    case Statement.IF()
      then flattenIfStatement(alg.branches, alg.info) :: stmts;

    case Statement.WHEN()
      then flattenWhenStatement(alg.branches, alg.info) :: stmts;

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
        sts := flattenStatements(alg.body);
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
        sts := flattenStatements(alg.body);
      then
        DAE.STMT_FAILURE(sts, ElementSource.createElementSource(alg.info)) :: stmts;

    else stmts;
  end match;
end flattenStatement;

public function flattenStatements
  input list<Statement> algs;
  input output list<DAE.Statement> stmts = {};
algorithm
  stmts := listReverse(List.fold(algs, flattenStatement, stmts));
end flattenStatements;

function flattenAlgorithmStmts
  input list<Statement> algSection;
  input output list<DAE.Element> elements = {};
protected
  DAE.Algorithm alg;
algorithm
  alg := DAE.ALGORITHM_STMTS(flattenStatements(algSection));
  elements := DAE.ALGORITHM(alg, DAE.emptyElementSource) :: elements;
end flattenAlgorithmStmts;

function flattenAlgorithms
  input list<list<Statement>> algorithms;
  input output list<DAE.Element> elements = {};
algorithm
  elements := List.fold(algorithms, flattenAlgorithmStmts, elements);
end flattenAlgorithms;

function flattenInitialAlgorithmStmts
  input list<Statement> algSection;
  input output list<DAE.Element> elements = {};
protected
  DAE.Algorithm alg;
algorithm
  alg := DAE.ALGORITHM_STMTS(flattenStatements(algSection));
  elements := DAE.INITIALALGORITHM(alg, DAE.emptyElementSource) :: elements;
end flattenInitialAlgorithmStmts;

function flattenInitialAlgorithms
  input list<list<Statement>> algorithms;
  input output list<DAE.Element> elements = {};
algorithm
  elements := List.fold(algorithms, flattenInitialAlgorithmStmts, elements);
end flattenInitialAlgorithms;

function flattenIfStatement
  input list<tuple<Expression, list<Statement>>> ifBranches;
  input SourceInfo info;
  output DAE.Statement ifStatement;
protected
  DAE.Exp cond1, cond2;
  list<DAE.Statement> stmts1, stmts2;
  tuple<Expression, list<Statement>> head;
  list<tuple<Expression, list<Statement>>> rest;
  DAE.Else elseStatement = DAE.NOELSE();
algorithm
  head :: rest := ifBranches;
  cond1 := Expression.toDAE(Util.tuple21(head));
  stmts1 := flattenStatements(Util.tuple22(head));
  rest := listReverse(rest);

  for b in rest loop
    cond2 := Expression.toDAE(Util.tuple21(b));
    stmts2 := flattenStatements(Util.tuple22(b));
    elseStatement := DAE.ELSEIF(cond2, stmts2, elseStatement);
  end for;

  ifStatement := DAE.STMT_IF(cond1, stmts1,  elseStatement, ElementSource.createElementSource(info));

end flattenIfStatement;

function flattenWhenStatement
  input list<tuple<Expression, list<Statement>>> whenBranches;
  input SourceInfo info;
  output DAE.Statement whenStatement;
protected
  DAE.Exp cond1,cond2;
  list<DAE.Statement> stmts1, stmts2;
  tuple<Expression, list<Statement>> head;
  list<tuple<Expression, list<Statement>>> rest;
  Option<DAE.Statement> owhenStatement = NONE();
algorithm

  head :: rest := whenBranches;
  cond1 := Expression.toDAE(Util.tuple21(head));
  stmts1 := flattenStatements(Util.tuple22(head));
  rest := listReverse(rest);

  for b in rest loop
  cond2 := Expression.toDAE(Util.tuple21(b));
    stmts2 := flattenStatements(Util.tuple22(b));
    whenStatement := DAE.STMT_WHEN(cond2, {}, false, stmts2, owhenStatement, ElementSource.createElementSource(info));
    owhenStatement := SOME(whenStatement);
  end for;

  whenStatement := DAE.STMT_WHEN(cond1, {}, false, stmts1, owhenStatement, ElementSource.createElementSource(info));

end flattenWhenStatement;

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
