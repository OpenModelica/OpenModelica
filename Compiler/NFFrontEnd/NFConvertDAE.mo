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

encapsulated package NFConvertDAE

import Binding = NFBinding;
import DAE;
import Equation = NFEquation;
import NFFlatten.Elements;
import NFFlatten.FunctionTree;
import NFInstNode.InstNode;
import Statement = NFStatement;

protected
import ExecStat.execStat;
import ElementSource;
import ComponentRef = NFComponentRef;
import Type = NFType;
import NFModifier.Modifier;
import Expression = NFExpression;
import NFComponent.Component;
import Prefixes = NFPrefixes;
import NFClass.Class;
import RangeIterator = NFRangeIterator;
import DAEUtil;
import Dimension = NFDimension;
import List;
import Util;
import MetaModelica.Dangerous.listReverseInPlace;
import Sections = NFSections;
import Function = NFFunction.Function;
import ClassTree = NFClassTree;
import NFPrefixes.Visibility;
import NFPrefixes.Direction;

public
function convert
  input Elements elements;
  input FunctionTree functions;
  input String name;
  input SourceInfo info;
  output DAE.DAElist dae;
  output DAE.FunctionTree daeFunctions;
protected
  list<DAE.Element> elems;
  DAE.Element class_elem;
algorithm
  elems := convertComponents(elements.components, {});
  elems := convertEquations(elements.equations, elems);
  elems := convertInitialEquations(elements.initialEquations, elems);
  elems := convertAlgorithms(elements.algorithms, elems);
  elems := convertInitialAlgorithms(elements.initialAlgorithms, elems);

  class_elem := DAE.COMP(name, elems, ElementSource.createElementSource(info), NONE());
  dae := DAE.DAE({class_elem});

  daeFunctions := convertFunctionTree(functions);

  execStat(getInstanceName() + "(" + name + ")");
end convert;

protected
function convertComponents
  input list<tuple<ComponentRef, Binding>> components;
  input output list<DAE.Element> elements;
protected
  Boolean localDir = Flags.getConfigBool(Flags.USE_LOCAL_DIRECTION);
algorithm
  for comp in listReverse(components) loop
    elements := convertComponent(comp, localDir) :: elements;
  end for;
end convertComponents;

function convertComponent
  input tuple<ComponentRef, Binding> component;
  input Boolean useLocalDir;
  output DAE.Element daeVar;
protected
  ComponentRef cref;
  Binding binding;
  InstNode comp_node, cls_node;
  Type ty;
  Component comp;
  Class cls;
  SourceInfo info;
  Component.Attributes attr;
  Option<DAE.VariableAttributes> var_attr;
  Option<DAE.Exp> binding_exp;
algorithm
  (cref, binding) := component;
  ComponentRef.CREF(node = comp_node, ty = ty) := cref;
  comp := InstNode.component(comp_node);
  Component.TYPED_COMPONENT(classInst = cls_node, attributes = attr, info = info) := comp;
  cls := InstNode.getClass(cls_node);

  binding_exp := convertBinding(binding);
  var_attr := convertVarAttributes(Class.getTypeAttributes(cls), ty);
  daeVar := makeDAEVar(cref, ty, binding_exp, attr, InstNode.visibility(comp_node), var_attr, useLocalDir, info);
end convertComponent;

function makeDAEVar
  input ComponentRef cref;
  input Type ty;
  input Option<DAE.Exp> binding;
  input Component.Attributes attr;
  input Visibility vis;
  input Option<DAE.VariableAttributes> vattr;
  input Boolean useLocalDir;
  input SourceInfo info;
  output DAE.Element var;
protected
  DAE.ComponentRef dcref;
  DAE.Type dty;
  DAE.ElementSource source;
  Direction dir;
algorithm
  dcref := ComponentRef.toDAE(cref);
  dty := Type.toDAE(ty);
  source := ElementSource.createElementSource(info);

  var := match attr
    case Component.Attributes.ATTRIBUTES()
      algorithm
        // Strip input/output from non top-level components unless
        // --useLocalDirection=true has been set.
        if attr.direction == Direction.NONE or useLocalDir then
          dir := attr.direction;
        else
          dir := getComponentDirection(attr.direction, cref);
        end if;
      then
        DAE.VAR(
          dcref,
          Prefixes.variabilityToDAE(attr.variability),
          Prefixes.directionToDAE(dir),
          Prefixes.parallelismToDAE(attr.parallelism),
          Prefixes.visibilityToDAE(vis),
          dty,
          binding,
          {},
          Prefixes.connectorTypeToDAE(attr.connectorType),
          source,
          vattr,
          NONE(),
          Absyn.NOT_INNER_OUTER()
        );

    else
      DAE.VAR(dcref, DAE.VarKind.VARIABLE(), DAE.VarDirection.BIDIR(),
        DAE.VarParallelism.NON_PARALLEL(), Prefixes.visibilityToDAE(vis), dty,
        binding, {}, DAE.ConnectorType.NON_CONNECTOR(), source, vattr, NONE(),
        Absyn.NOT_INNER_OUTER());

  end match;
end makeDAEVar;

function getComponentDirection
  "Returns the given direction if the cref refers to a top-level component or to
   a component in a top-level connector, otherwise returns Direction.NONE."
  input output Direction dir;
  input ComponentRef cref;
protected
  ComponentRef rest_cref = ComponentRef.rest(cref);
algorithm
  dir := match rest_cref
    case ComponentRef.EMPTY() then dir;
    case ComponentRef.CREF()
      then if InstNode.isConnector(rest_cref.node) then
        getComponentDirection(dir, rest_cref) else Direction.NONE;
  end match;
end getComponentDirection;

function convertBinding
  input Binding binding;
  output Option<DAE.Exp> bindingExp;
algorithm
  bindingExp := match binding
    case Binding.UNBOUND() then NONE();
    case Binding.TYPED_BINDING() then SOME(Expression.toDAE(binding.bindingExp));
    case Binding.FLAT_BINDING() then SOME(Expression.toDAE(binding.bindingExp));
  end match;
end convertBinding;

function convertVarAttributes
  input list<Modifier> mods;
  input Type ty;
  output Option<DAE.VariableAttributes> attributes;
algorithm
  if listEmpty(mods) then
    attributes := NONE();
    return;
  end if;

  attributes := match ty
    case Type.REAL() then convertRealVarAttributes(mods);
    case Type.INTEGER() then convertIntVarAttributes(mods);
    case Type.BOOLEAN() then convertBoolVarAttributes(mods);
    case Type.STRING() then convertStringVarAttributes(mods);
    case Type.ENUMERATION() then convertEnumVarAttributes(mods);
    else NONE();
  end match;
end convertVarAttributes;

function convertRealVarAttributes
  input list<Modifier> mods;
  output Option<DAE.VariableAttributes> attributes;
protected
  Option<DAE.Exp> quantity = NONE(), unit = NONE(), displayUnit = NONE();
  Option<DAE.Exp> min = NONE(), max = NONE(), start = NONE(), fixed = NONE(), nominal = NONE();
  Option<DAE.StateSelect> state_select = NONE();
algorithm
  for m in mods loop
    () := match Modifier.name(m)
      case "displayUnit" algorithm displayUnit := convertVarAttribute(m); then ();
      case "fixed"       algorithm fixed := convertVarAttribute(m); then ();
      case "max"         algorithm max := convertVarAttribute(m); then ();
      case "min"         algorithm min := convertVarAttribute(m); then ();
      case "nominal"     algorithm nominal := convertVarAttribute(m); then ();
      case "quantity"    algorithm quantity := convertVarAttribute(m); then ();
      case "start"       algorithm start := convertVarAttribute(m); then ();
      case "stateSelect" algorithm state_select := convertStateSelectAttribute(m); then ();
      // TODO: VAR_ATTR_REAL has no field for unbounded.
      case "unbounded"   then ();
      case "unit"        algorithm unit := convertVarAttribute(m); then ();

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
end convertRealVarAttributes;

function convertIntVarAttributes
  input list<Modifier> mods;
  output Option<DAE.VariableAttributes> attributes;
protected
  Option<DAE.Exp> quantity = NONE(), min = NONE(), max = NONE();
  Option<DAE.Exp> start = NONE(), fixed = NONE();
algorithm
  for m in mods loop
    () := match Modifier.name(m)
      case "quantity" algorithm quantity := convertVarAttribute(m); then ();
      case "min"      algorithm min := convertVarAttribute(m); then ();
      case "max"      algorithm max := convertVarAttribute(m); then ();
      case "start"    algorithm start := convertVarAttribute(m); then ();
      case "fixed"    algorithm fixed := convertVarAttribute(m); then ();

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
end convertIntVarAttributes;

function convertBoolVarAttributes
  input list<Modifier> mods;
  output Option<DAE.VariableAttributes> attributes;
protected
  Option<DAE.Exp> quantity = NONE(), start = NONE(), fixed = NONE();
algorithm
  for m in mods loop
    () := match Modifier.name(m)
      case "quantity" algorithm quantity := convertVarAttribute(m); then ();
      case "start"    algorithm start := convertVarAttribute(m); then ();
      case "fixed"    algorithm fixed := convertVarAttribute(m); then ();

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
end convertBoolVarAttributes;

function convertStringVarAttributes
  input list<Modifier> mods;
  output Option<DAE.VariableAttributes> attributes;
protected
  Option<DAE.Exp> quantity = NONE(), start = NONE();
algorithm
  for m in mods loop
    () := match Modifier.name(m)
      case "quantity" algorithm quantity := convertVarAttribute(m); then ();
      case "start"    algorithm start := convertVarAttribute(m); then ();
      // TODO: VAR_ATTR_STRING has no field for fixed.
      case "fixed"    then ();

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
end convertStringVarAttributes;

function convertEnumVarAttributes
  input list<Modifier> mods;
  output Option<DAE.VariableAttributes> attributes;
protected
  Option<DAE.Exp> quantity = NONE(), min = NONE(), max = NONE();
  Option<DAE.Exp> start = NONE(), fixed = NONE();
algorithm
  for m in mods loop
    () := match Modifier.name(m)
      case "fixed"       algorithm fixed := convertVarAttribute(m); then ();
      case "max"         algorithm max := convertVarAttribute(m); then ();
      case "min"         algorithm min := convertVarAttribute(m); then ();
      case "quantity"    algorithm quantity := convertVarAttribute(m); then ();
      case "start"       algorithm start := convertVarAttribute(m); then ();

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
end convertEnumVarAttributes;

function convertVarAttribute
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
end convertVarAttribute;

function convertStateSelectAttribute
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
        assert(false, getInstanceName() + " got untyped binding");
      then
        fail();

  end match;
end convertStateSelectAttribute;

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
        assert(false, getInstanceName() + " got unknown StateSelect literal " + name);
      then
        fail();
  end match;
end lookupStateSelectMember;

function convertEquations
  input list<Equation> equations;
  input output list<DAE.Element> elements = {};
algorithm
  for eq in listReverse(equations) loop
    elements := convertEquation(eq, elements);
  end for;
end convertEquations;

function convertEquation
  input Equation eq;
  input output list<DAE.Element> elements;
algorithm
  elements := match eq
    local
      DAE.Exp e1, e2, e3;
      DAE.ComponentRef cr1, cr2;
      DAE.ElementSource src;
      list<DAE.Dimension> dims;
      list<DAE.Element> body;

    case Equation.EQUALITY()
      algorithm
        e1 := Expression.toDAE(eq.lhs);
        e2 := Expression.toDAE(eq.rhs);
        src := ElementSource.createElementSource(eq.info);
      then
        DAE.Element.EQUATION(e1, e2, src) :: elements;

    case Equation.CREF_EQUALITY()
      algorithm
        cr1 := ComponentRef.toDAE(eq.lhs);
        cr2 := ComponentRef.toDAE(eq.rhs);
      then
        DAE.Element.EQUEQUATION(cr1, cr2, eq.source) :: elements;

    case Equation.ARRAY_EQUALITY()
      algorithm
        e1 := Expression.toDAE(eq.lhs);
        e2 := Expression.toDAE(eq.rhs);
        src := ElementSource.createElementSource(eq.info);
        dims := list(Dimension.toDAE(d) for d in Type.arrayDims(eq.ty));
      then
        DAE.Element.ARRAY_EQUATION(dims, e1, e2, src) :: elements;

    // For equations should have been unrolled here.
    case Equation.FOR()
      algorithm
        assert(false, getInstanceName() + " got a for equation");
      then
        fail();

    case Equation.IF()
      then convertIfEquation(eq.branches, eq.info, isInitial = false) :: elements;

    case Equation.WHEN()
      then convertWhenEquation(eq.branches, eq.info) :: elements;

    case Equation.ASSERT()
      algorithm
        e1 := Expression.toDAE(eq.condition);
        e2 := Expression.toDAE(eq.message);
        e3 := Expression.toDAE(eq.level);
        src := ElementSource.createElementSource(eq.info);
      then
        DAE.Element.ASSERT(e1, e2, e3, src) :: elements;

    case Equation.TERMINATE()
      algorithm
        e1 := Expression.toDAE(eq.message);
        src := ElementSource.createElementSource(eq.info);
      then
        DAE.Element.TERMINATE(e1, src) :: elements;

    case Equation.REINIT()
      algorithm
        cr1 := ComponentRef.toDAE(Expression.toCref(eq.cref));
        e1 := Expression.toDAE(eq.reinitExp);
        src := ElementSource.createElementSource(eq.info);
      then
        DAE.Element.REINIT(cr1, e1, src) :: elements;

    case Equation.NORETCALL()
      algorithm
        e1 := Expression.toDAE(eq.exp);
        src := ElementSource.createElementSource(eq.info);
      then
        DAE.Element.NORETCALL(e1, src) :: elements;

    else elements;
  end match;
end convertEquation;

function convertIfEquation
  input list<tuple<Expression, list<Equation>>> ifBranches;
  input SourceInfo info;
  input Boolean isInitial;
  output DAE.Element ifEquation;
protected
  list<Expression> conds;
  list<list<Equation>> branches;
  list<DAE.Exp> dconds;
  list<list<DAE.Element>> dbranches;
  list<DAE.Element> else_branch;
  DAE.ElementSource src = ElementSource.createElementSource(info);
algorithm
  (conds, branches) := List.unzipReverse(ifBranches);
  dbranches := if isInitial then
    listReverse(convertInitialEquations(b) for b in branches) else
    listReverse(convertEquations(b) for b in branches);

  // Transform the last branch to an else-branch if its condition is true.
  if Expression.isTrue(listHead(conds)) then
    else_branch :: dbranches := dbranches;
    conds := listRest(conds);
  else
    else_branch := {};
  end if;

  dconds := listReverse(Expression.toDAE(c) for c in conds);
  ifEquation := if isInitial then
    DAE.Element.INITIAL_IF_EQUATION(dconds, dbranches, else_branch, src) else
    DAE.Element.IF_EQUATION(dconds, dbranches, else_branch, src);
end convertIfEquation;

function convertWhenEquation
  input list<tuple<Expression, list<Equation>>> whenBranches;
  input SourceInfo info;
  output DAE.Element whenEquation;
protected
  DAE.ElementSource src;
  DAE.Exp cond;
  list<DAE.Element> els;
  Option<DAE.Element> when_eq = NONE();
algorithm
  src := ElementSource.createElementSource(info);

  for b in listReverse(whenBranches) loop
    cond := Expression.toDAE(Util.tuple21(b));
    els := convertEquations(Util.tuple22(b));
    when_eq := SOME(DAE.Element.WHEN_EQUATION(cond, els, when_eq, src));
  end for;

  SOME(whenEquation) := when_eq;
end convertWhenEquation;

function convertInitialEquations
  input list<Equation> equations;
  input output list<DAE.Element> elements = {};
algorithm
  for eq in equations loop
    elements := convertInitialEquation(eq, elements);
  end for;
end convertInitialEquations;

function convertInitialEquation
  input Equation eq;
  input output list<DAE.Element> elements;
algorithm
  elements := match eq
    local
      DAE.Exp e1, e2, e3;
      DAE.ComponentRef cref;
      DAE.ElementSource src;
      list<DAE.Dimension> dims;
      list<DAE.Element> body;

    case Equation.EQUALITY()
      algorithm
        e1 := Expression.toDAE(eq.lhs);
        e2 := Expression.toDAE(eq.rhs);
        src := ElementSource.createElementSource(eq.info);
      then
        DAE.Element.INITIALEQUATION(e1, e2, src) :: elements;

    case Equation.ARRAY_EQUALITY()
      algorithm
        e1 := Expression.toDAE(eq.lhs);
        e2 := Expression.toDAE(eq.rhs);
        src := ElementSource.createElementSource(eq.info);
        dims := list(Dimension.toDAE(d) for d in Type.arrayDims(eq.ty));
      then
        DAE.Element.INITIAL_ARRAY_EQUATION(dims, e1, e2, src) :: elements;

    // For equations should have been unrolled here.
    case Equation.FOR()
      algorithm
        assert(false, getInstanceName() + " got a for equation");
      then
        fail();

    case Equation.IF()
      then convertIfEquation(eq.branches, eq.info, isInitial = true) :: elements;

    case Equation.ASSERT()
      algorithm
        e1 := Expression.toDAE(eq.condition);
        e2 := Expression.toDAE(eq.message);
        e3 := Expression.toDAE(eq.level);
        src := ElementSource.createElementSource(eq.info);
      then
        DAE.Element.INITIAL_ASSERT(e1, e2, e3, src) :: elements;

    case Equation.TERMINATE()
      algorithm
        e1 := Expression.toDAE(eq.message);
        src := ElementSource.createElementSource(eq.info);
      then
        DAE.Element.INITIAL_TERMINATE(e1, src) :: elements;

    case Equation.NORETCALL()
      algorithm
        e1 := Expression.toDAE(eq.exp);
        src := ElementSource.createElementSource(eq.info);
      then
        DAE.Element.INITIAL_NORETCALL(e1, src) :: elements;

    else elements;
  end match;
end convertInitialEquation;

function convertAlgorithms
  input list<list<Statement>> algorithms;
  input output list<DAE.Element> elements;
algorithm
  for alg in listReverse(algorithms) loop
    elements := convertAlgorithm(alg, elements);
  end for;
end convertAlgorithms;

function convertAlgorithm
  input list<Statement> statements;
  input output list<DAE.Element> elements;
protected
  list<DAE.Statement> stmts;
  DAE.Algorithm alg;
algorithm
  stmts := convertStatements(statements);
  alg := DAE.ALGORITHM_STMTS(stmts);
  elements := DAE.ALGORITHM(alg, DAE.emptyElementSource) :: elements;
end convertAlgorithm;

function convertStatements
  input list<Statement> statements;
  output list<DAE.Statement> elements;
algorithm
  elements := list(convertStatement(s) for s in statements);
end convertStatements;

function convertStatement
  input Statement stmt;
  output DAE.Statement elem;
algorithm
  elem := match stmt
    local
      DAE.Exp e1, e2, e3;
      DAE.Type ty;
      DAE.ElementSource src;
      list<DAE.Statement> body;

    case Statement.ASSIGNMENT()
      algorithm
        ty := Type.toDAE(Expression.typeOf(stmt.lhs));
        e1 := Expression.toDAE(stmt.lhs);
        e2 := Expression.toDAE(stmt.rhs);
        src := ElementSource.createElementSource(stmt.info);
      then
        DAE.Statement.STMT_ASSIGN(ty, e1, e2, src);

    case Statement.FUNCTION_ARRAY_INIT()
      algorithm
        ty := Type.toDAE(stmt.ty);
        src := ElementSource.createElementSource(stmt.info);
      then
        DAE.Statement.STMT_ARRAY_INIT(stmt.name, ty, src);

    case Statement.FOR() then convertForStatement(stmt);
    case Statement.IF() then convertIfStatement(stmt.branches, stmt.info);
    case Statement.WHEN() then convertWhenStatement(stmt.branches, stmt.info);

    case Statement.ASSERT()
      algorithm
        e1 := Expression.toDAE(stmt.condition);
        e2 := Expression.toDAE(stmt.message);
        e3 := Expression.toDAE(stmt.level);
        src := ElementSource.createElementSource(stmt.info);
      then
        DAE.Statement.STMT_ASSERT(e1, e2, e3, src);

    case Statement.TERMINATE()
      algorithm
        e1 := Expression.toDAE(stmt.message);
        src := ElementSource.createElementSource(stmt.info);
      then
        DAE.Statement.STMT_TERMINATE(e1, src);

    case Statement.NORETCALL()
      algorithm
        e1 := Expression.toDAE(stmt.exp);
        src := ElementSource.createElementSource(stmt.info);
      then
        DAE.Statement.STMT_NORETCALL(e1, src);

    case Statement.WHILE()
      algorithm
        e1 := Expression.toDAE(stmt.condition);
        body := convertStatements(stmt.body);
        src := ElementSource.createElementSource(stmt.info);
      then
        DAE.Statement.STMT_WHILE(e1, body, src);

    case Statement.RETURN()
      then DAE.Statement.STMT_RETURN(ElementSource.createElementSource(stmt.info));

    case Statement.BREAK()
      then DAE.Statement.STMT_BREAK(ElementSource.createElementSource(stmt.info));

    case Statement.FAILURE()
      algorithm
        body := convertStatements(stmt.body);
        src := ElementSource.createElementSource(stmt.info);
      then
        DAE.Statement.STMT_FAILURE(body, src);

  end match;
end convertStatement;

function convertForStatement
  input Statement forStmt;
  output DAE.Statement forDAE;
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
  dbody := convertStatements(body);

  Component.ITERATOR(ty = ty, binding = binding) := InstNode.component(iterator);
  SOME(range) := Binding.typedExp(binding);

  forDAE := DAE.Statement.STMT_FOR(Type.toDAE(ty), Type.isArray(ty),
    InstNode.name(iterator), 0, Expression.toDAE(range), dbody,
    ElementSource.createElementSource(info));
end convertForStatement;

function convertIfStatement
  input list<tuple<Expression, list<Statement>>> ifBranches;
  input SourceInfo info;
  output DAE.Statement ifStatement;
protected
  DAE.Exp cond1, cond2;
  list<DAE.Statement> stmts1, stmts2;
  tuple<Expression, list<Statement>> head;
  list<tuple<Expression, list<Statement>>> rest;
  DAE.Else elseStatement = DAE.Else.NOELSE();
algorithm
  head :: rest := ifBranches;
  cond1 := Expression.toDAE(Util.tuple21(head));
  stmts1 := convertStatements(Util.tuple22(head));

  for b in listReverse(rest) loop
    cond2 := Expression.toDAE(Util.tuple21(b));
    stmts2 := convertStatements(Util.tuple22(b));
    elseStatement := DAE.Else.ELSEIF(cond2, stmts2, elseStatement);
  end for;

  ifStatement := DAE.Statement.STMT_IF(cond1, stmts1,  elseStatement, ElementSource.createElementSource(info));
end convertIfStatement;

function convertWhenStatement
  input list<tuple<Expression, list<Statement>>> whenBranches;
  input SourceInfo info;
  output DAE.Statement whenStatement;
protected
  DAE.ElementSource src;
  DAE.Exp cond;
  list<DAE.Statement> stmts;
  Option<DAE.Statement> when_stmt = NONE();
algorithm
  src := ElementSource.createElementSource(info);

  for b in listReverse(whenBranches) loop
    cond := Expression.toDAE(Util.tuple21(b));
    stmts := convertStatements(Util.tuple22(b));
    when_stmt := SOME(DAE.Statement.STMT_WHEN(cond, {}, false, stmts, when_stmt, src));
  end for;

  SOME(whenStatement) := when_stmt;
end convertWhenStatement;

function convertInitialAlgorithms
  input list<list<Statement>> algorithms;
  input output list<DAE.Element> elements;
algorithm
  for alg in algorithms loop
    elements := convertInitialAlgorithm(alg, elements);
  end for;
end convertInitialAlgorithms;

function convertInitialAlgorithm
  input list<Statement> statements;
  input output list<DAE.Element> elements;
protected
  list<DAE.Statement> stmts;
  DAE.Algorithm alg;
algorithm
  stmts := convertStatements(statements);
  alg := DAE.ALGORITHM_STMTS(stmts);
  elements := DAE.INITIALALGORITHM(alg, DAE.emptyElementSource) :: elements;
end convertInitialAlgorithm;

function convertFunctionTree
  input FunctionTree funcs;
  output DAE.FunctionTree dfuncs;
algorithm
  dfuncs := match funcs
    local
      DAE.FunctionTree left, right;
      DAE.Function fn;

    case FunctionTree.NODE()
      algorithm
        fn := convertFunction(funcs.value);
        left := convertFunctionTree(funcs.left);
        right := convertFunctionTree(funcs.right);
      then
        DAE.FunctionTree.NODE(funcs.key, SOME(fn), funcs.height, left, right);

    case FunctionTree.LEAF()
      algorithm
        fn := convertFunction(funcs.value);
      then
        DAE.FunctionTree.LEAF(funcs.key, SOME(fn));

    case FunctionTree.EMPTY()
      then DAE.FunctionTree.EMPTY();

  end match;
end convertFunctionTree;

function convertFunction
  input Function func;
  output DAE.Function dfunc;
protected
  Class cls;
  list<DAE.Element> elems;
  DAE.FunctionDefinition def;
  Sections sections;
algorithm
  cls := InstNode.getClass(Function.instance(func));

  dfunc := match cls
    case Class.INSTANCED_CLASS(sections = sections)
      algorithm
        elems := convertFunctionParams(func.inputs, {});
        elems := convertFunctionParams(func.outputs, elems);
        elems := convertFunctionParams(func.locals, elems);

        def := match sections
          // A function with an algorithm section.
          case Sections.SECTIONS()
            algorithm
              elems := convertAlgorithms(sections.algorithms, elems);
            then
              DAE.FunctionDefinition.FUNCTION_DEF(listReverse(elems));

          // An external function.
          case Sections.EXTERNAL()
            then convertExternalDecl(sections, listReverse(elems));

          // A function without either algorithm or external section.
          else DAE.FunctionDefinition.FUNCTION_DEF(listReverse(elems));
        end match;
      then
        Function.toDAE(func, {def});

    else
      algorithm
        assert(false, getInstanceName() + " got unknown function");
      then
        fail();

  end match;
end convertFunction;

function convertFunctionParams
  input list<InstNode> params;
  input output list<DAE.Element> elements;
algorithm
  for p in params loop
    elements := convertFunctionParam(p) :: elements;
  end for;
end convertFunctionParams;

function convertFunctionParam
  input InstNode node;
  output DAE.Element element;
protected
  Component comp;
  Class cls;
  SourceInfo info;
  Option<DAE.VariableAttributes> var_attr;
  ComponentRef cref;
  Component.Attributes attr;
  Type ty;
  Option<DAE.Exp> binding;
algorithm
  comp := InstNode.component(node);

  element := match comp
    case Component.TYPED_COMPONENT(ty = ty, info = info)
      algorithm
        cref := ComponentRef.fromNode(node, ty);
        binding := convertBinding(comp.binding);
        cls := InstNode.getClass(comp.classInst);
        var_attr := convertVarAttributes(Class.getTypeAttributes(cls), ty);
        attr := comp.attributes;
      then
        makeDAEVar(cref, ty, binding, attr, InstNode.visibility(node), var_attr, true, info);

    else
      algorithm
        assert(false, getInstanceName() + " got untyped component.");
      then
        fail();

  end match;
end convertFunctionParam;

function convertExternalDecl
  input Sections extDecl;
  input list<DAE.Element> parameters;
  output DAE.FunctionDefinition funcDef;
protected
  DAE.ExternalDecl decl;
  list<DAE.ExtArg> args;
  DAE.ExtArg ret_arg;
algorithm
  funcDef := match extDecl
    case Sections.EXTERNAL()
      algorithm
        args := list(convertExternalDeclArg(e) for e in extDecl.args);
        ret_arg := convertExternalDeclOutput(extDecl.outputRef);
        decl := DAE.ExternalDecl.EXTERNALDECL(extDecl.name, args, ret_arg, extDecl.language, extDecl.ann);
      then
        DAE.FunctionDefinition.FUNCTION_EXT(parameters, decl);
  end match;
end convertExternalDecl;

function convertExternalDeclArg
  input Expression exp;
  output DAE.ExtArg arg;
algorithm
  arg := match exp
    local
      Absyn.Direction dir;
      ComponentRef cref;
      Expression e;

    case Expression.CREF(cref = cref as ComponentRef.CREF())
      algorithm
        dir := Prefixes.directionToAbsyn(Component.direction(InstNode.component(cref.node)));
      then
        DAE.ExtArg.EXTARG(ComponentRef.toDAE(cref), dir, Type.toDAE(exp.ty));

    case Expression.SIZE(exp = Expression.CREF(cref = cref as ComponentRef.CREF()), dimIndex = SOME(e))
      then DAE.ExtArg.EXTARGSIZE(ComponentRef.toDAE(cref), Type.toDAE(cref.ty), Expression.toDAE(e));

    else DAE.ExtArg.EXTARGEXP(Expression.toDAE(exp), Type.toDAE(Expression.typeOf(exp)));

  end match;
end convertExternalDeclArg;

function convertExternalDeclOutput
  input ComponentRef cref;
  output DAE.ExtArg arg;
algorithm
  arg := match cref
    local
      Absyn.Direction dir;

    case ComponentRef.CREF()
      algorithm
        dir := Prefixes.directionToAbsyn(Component.direction(InstNode.component(cref.node)));
      then
        DAE.ExtArg.EXTARG(ComponentRef.toDAE(cref), dir, Type.toDAE(cref.ty));

    else DAE.ExtArg.NOEXTARG();
  end match;
end convertExternalDeclOutput;

annotation(__OpenModelica_Interface="frontend");
end NFConvertDAE;
