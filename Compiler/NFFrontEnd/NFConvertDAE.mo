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
import FlatModel = NFFlatModel;
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
import Variable = NFVariable;

public
function convert
  input FlatModel flatModel;
  input FunctionTree functions;
  input String name;
  input SourceInfo info;
  output DAE.DAElist dae;
  output DAE.FunctionTree daeFunctions;
protected
  list<DAE.Element> elems;
  DAE.Element class_elem;
algorithm
  elems := convertVariables(flatModel.variables, {});
  elems := convertEquations(flatModel.equations, elems);
  elems := convertInitialEquations(flatModel.initialEquations, elems);
  elems := convertAlgorithms(flatModel.algorithms, elems);
  elems := convertInitialAlgorithms(flatModel.initialAlgorithms, elems);

  class_elem := DAE.COMP(name, elems, ElementSource.createElementSource(info), flatModel.comment);
  dae := DAE.DAE({class_elem});

  daeFunctions := convertFunctionTree(functions);

  execStat(getInstanceName() + "(" + name + ")");
end convert;

protected
function convertVariables
  input list<Variable> variables;
  input output list<DAE.Element> elements;
protected
  Boolean localDir = Flags.getConfigBool(Flags.USE_LOCAL_DIRECTION);
algorithm
  for var in listReverse(variables) loop
    elements := convertVariable(var, localDir) :: elements;
  end for;
end convertVariables;

function convertVariable
  input Variable var;
  input Boolean useLocalDir;
  output DAE.Element daeVar;
protected
  Option<DAE.VariableAttributes> var_attr;
  Option<DAE.Exp> binding_exp;
algorithm
  binding_exp := convertBinding(var.binding);
  var_attr := convertVarAttributes(var.typeAttributes, var.ty);
  daeVar := makeDAEVar(var.name, var.ty, binding_exp, var.attributes,
    var.visibility, var_attr, var.comment, useLocalDir, var.info);
end convertVariable;

function makeDAEVar
  input ComponentRef cref;
  input Type ty;
  input Option<DAE.Exp> binding;
  input Component.Attributes attr;
  input Visibility vis;
  input Option<DAE.VariableAttributes> vattr;
  input Option<SCode.Comment> comment;
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
          Prefixes.variabilityToDAE(attr.variability, ty),
          Prefixes.directionToDAE(dir),
          Prefixes.parallelismToDAE(attr.parallelism),
          Prefixes.visibilityToDAE(vis),
          dty,
          binding,
          {},
          Prefixes.connectorTypeToDAE(attr.connectorType),
          source,
          vattr,
          comment,
          Absyn.NOT_INNER_OUTER()
        );

    else
      DAE.VAR(dcref, DAE.VarKind.VARIABLE(), DAE.VarDirection.BIDIR(),
        DAE.VarParallelism.NON_PARALLEL(), Prefixes.visibilityToDAE(vis), dty,
        binding, {}, DAE.ConnectorType.NON_CONNECTOR(), source, vattr, comment,
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
  input list<tuple<String, Binding>> attrs;
  input Type ty;
  output Option<DAE.VariableAttributes> attributes;
algorithm
  if listEmpty(attrs) then
    attributes := NONE();
    return;
  end if;

  attributes := match ty
    case Type.REAL() then convertRealVarAttributes(attrs);
    case Type.INTEGER() then convertIntVarAttributes(attrs);
    case Type.BOOLEAN() then convertBoolVarAttributes(attrs);
    case Type.STRING() then convertStringVarAttributes(attrs);
    case Type.ENUMERATION() then convertEnumVarAttributes(attrs);
    else NONE();
  end match;
end convertVarAttributes;

function convertRealVarAttributes
  input list<tuple<String, Binding>> attrs;
  output Option<DAE.VariableAttributes> attributes;
protected
  String name;
  Binding b;
  Option<DAE.Exp> quantity = NONE(), unit = NONE(), displayUnit = NONE();
  Option<DAE.Exp> min = NONE(), max = NONE(), start = NONE(), fixed = NONE(), nominal = NONE();
  Option<DAE.StateSelect> state_select = NONE();
algorithm
  for attr in attrs loop
    (name, b) := attr;

    () := match name
      case "displayUnit" algorithm displayUnit := convertVarAttribute(b); then ();
      case "fixed"       algorithm fixed := convertVarAttribute(b); then ();
      case "max"         algorithm max := convertVarAttribute(b); then ();
      case "min"         algorithm min := convertVarAttribute(b); then ();
      case "nominal"     algorithm nominal := convertVarAttribute(b); then ();
      case "quantity"    algorithm quantity := convertVarAttribute(b); then ();
      case "start"       algorithm start := convertVarAttribute(b); then ();
      case "stateSelect" algorithm state_select := convertStateSelectAttribute(b); then ();
      // TODO: VAR_ATTR_REAL has no field for unbounded.
      case "unbounded"   then ();
      case "unit"        algorithm unit := convertVarAttribute(b); then ();

      // The attributes should already be type checked, so we shouldn't get any
      // unknown attributes here.
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type attribute " + name, sourceInfo());
        then
          fail();
    end match;
  end for;

  attributes := SOME(DAE.VariableAttributes.VAR_ATTR_REAL(
    quantity, unit, displayUnit, min, max, start, fixed, nominal,
    state_select, NONE(), NONE(), NONE(), NONE(), NONE(), NONE()));
end convertRealVarAttributes;

function convertIntVarAttributes
  input list<tuple<String, Binding>> attrs;
  output Option<DAE.VariableAttributes> attributes;
protected
  String name;
  Binding b;
  Option<DAE.Exp> quantity = NONE(), min = NONE(), max = NONE();
  Option<DAE.Exp> start = NONE(), fixed = NONE();
algorithm
  for attr in attrs loop
    (name, b) := attr;

    () := match name
      case "quantity" algorithm quantity := convertVarAttribute(b); then ();
      case "min"      algorithm min := convertVarAttribute(b); then ();
      case "max"      algorithm max := convertVarAttribute(b); then ();
      case "start"    algorithm start := convertVarAttribute(b); then ();
      case "fixed"    algorithm fixed := convertVarAttribute(b); then ();

      // The attributes should already be type checked, so we shouldn't get any
      // unknown attributes here.
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type attribute " + name, sourceInfo());
        then
          fail();
    end match;
  end for;

  attributes := SOME(DAE.VariableAttributes.VAR_ATTR_INT(
    quantity, min, max, start, fixed,
    NONE(), NONE(), NONE(), NONE(), NONE(), NONE()));
end convertIntVarAttributes;

function convertBoolVarAttributes
  input list<tuple<String, Binding>> attrs;
  output Option<DAE.VariableAttributes> attributes;
protected
  String name;
  Binding b;
  Option<DAE.Exp> quantity = NONE(), start = NONE(), fixed = NONE();
algorithm
  for attr in attrs loop
    (name, b) := attr;

    () := match name
      case "quantity" algorithm quantity := convertVarAttribute(b); then ();
      case "start"    algorithm start := convertVarAttribute(b); then ();
      case "fixed"    algorithm fixed := convertVarAttribute(b); then ();

      // The attributes should already be type checked, so we shouldn't get any
      // unknown attributes here.
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type attribute " + name, sourceInfo());
        then
          fail();
    end match;
  end for;

  attributes := SOME(DAE.VariableAttributes.VAR_ATTR_BOOL(
    quantity, start, fixed, NONE(), NONE(), NONE(), NONE()));
end convertBoolVarAttributes;

function convertStringVarAttributes
  input list<tuple<String, Binding>> attrs;
  output Option<DAE.VariableAttributes> attributes;
protected
  String name;
  Binding b;
  Option<DAE.Exp> quantity = NONE(), start = NONE(), fixed = NONE();
algorithm
  for attr in attrs loop
    (name, b) := attr;

    () := match name
      case "quantity" algorithm quantity := convertVarAttribute(b); then ();
      case "start"    algorithm start := convertVarAttribute(b); then ();
      case "fixed"    algorithm fixed := convertVarAttribute(b); then ();

      // The attributes should already be type checked, so we shouldn't get any
      // unknown attributes here.
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type attribute " + name, sourceInfo());
        then
          fail();
    end match;
  end for;

  attributes := SOME(DAE.VariableAttributes.VAR_ATTR_STRING(
    quantity, start, fixed, NONE(), NONE(), NONE(), NONE()));
end convertStringVarAttributes;

function convertEnumVarAttributes
  input list<tuple<String, Binding>> attrs;
  output Option<DAE.VariableAttributes> attributes;
protected
  String name;
  Binding b;
  Option<DAE.Exp> quantity = NONE(), min = NONE(), max = NONE();
  Option<DAE.Exp> start = NONE(), fixed = NONE();
algorithm
  for attr in attrs loop
    (name, b) := attr;

    () := match name
      case "fixed"       algorithm fixed := convertVarAttribute(b); then ();
      case "max"         algorithm max := convertVarAttribute(b); then ();
      case "min"         algorithm min := convertVarAttribute(b); then ();
      case "quantity"    algorithm quantity := convertVarAttribute(b); then ();
      case "start"       algorithm start := convertVarAttribute(b); then ();

      // The attributes should already be type checked, so we shouldn't get any
      // unknown attributes here.
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown type attribute " + name, sourceInfo());
        then
          fail();
    end match;
  end for;

  attributes := SOME(DAE.VariableAttributes.VAR_ATTR_ENUMERATION(
    quantity, min, max, start, fixed, NONE(), NONE(), NONE(), NONE()));
end convertEnumVarAttributes;

function convertVarAttribute
  input Binding binding;
  output Option<DAE.Exp> attribute = SOME(Expression.toDAE(Binding.getTypedExp(binding)));
end convertVarAttribute;

function convertStateSelectAttribute
  input Binding binding;
  output Option<DAE.StateSelect> stateSelect;
protected
  InstNode node;
  String name;
  Expression exp = Binding.getTypedExp(binding);
algorithm
  name := match exp
    case Expression.ENUM_LITERAL() then exp.name;
    case Expression.CREF(cref = ComponentRef.CREF(node = node)) then InstNode.name(node);
    else
      algorithm
        Error.assertion(false, getInstanceName() +
          " got invalid StateSelect expression " + Expression.toString(exp), sourceInfo());
      then
        fail();
  end match;

  stateSelect := SOME(lookupStateSelectMember(name));
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
        Error.assertion(false, getInstanceName() + " got unknown StateSelect literal " + name, sourceInfo());
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
      list<DAE.Dimension> dims;
      list<DAE.Element> body;

    case Equation.EQUALITY()
      algorithm
        e1 := Expression.toDAE(eq.lhs);
        e2 := Expression.toDAE(eq.rhs);
      then
        DAE.Element.EQUATION(e1, e2, eq.source) :: elements;

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
        dims := list(Dimension.toDAE(d) for d in Type.arrayDims(eq.ty));
      then
        DAE.Element.ARRAY_EQUATION(dims, e1, e2, eq.source) :: elements;

    // For equations should have been unrolled here.
    case Equation.FOR()
      algorithm
        Error.assertion(false, getInstanceName() + " got a for equation", sourceInfo());
      then
        fail();

    case Equation.IF()
      then convertIfEquation(eq.branches, eq.source, isInitial = false) :: elements;

    case Equation.WHEN()
      then convertWhenEquation(eq.branches, eq.source) :: elements;

    case Equation.ASSERT()
      algorithm
        e1 := Expression.toDAE(eq.condition);
        e2 := Expression.toDAE(eq.message);
        e3 := Expression.toDAE(eq.level);
      then
        DAE.Element.ASSERT(e1, e2, e3, eq.source) :: elements;

    case Equation.TERMINATE()
      then DAE.Element.TERMINATE(Expression.toDAE(eq.message), eq.source) :: elements;

    case Equation.REINIT()
      algorithm
        cr1 := ComponentRef.toDAE(Expression.toCref(eq.cref));
        e1 := Expression.toDAE(eq.reinitExp);
      then
        DAE.Element.REINIT(cr1, e1, eq.source) :: elements;

    case Equation.NORETCALL()
      then DAE.Element.NORETCALL(Expression.toDAE(eq.exp), eq.source) :: elements;

    else elements;
  end match;
end convertEquation;

function convertIfEquation
  input list<tuple<Expression, list<Equation>>> ifBranches;
  input DAE.ElementSource source;
  input Boolean isInitial;
  output DAE.Element ifEquation;
protected
  list<Expression> conds;
  list<list<Equation>> branches;
  list<DAE.Exp> dconds;
  list<list<DAE.Element>> dbranches;
  list<DAE.Element> else_branch;
algorithm
  (conds, branches) := List.unzipReverse(ifBranches);
  dbranches := if isInitial then
    list(convertInitialEquations(b) for b in branches) else
    list(convertEquations(b) for b in branches);

  // Transform the last branch to an else-branch if its condition is true.
  if Expression.isTrue(listHead(conds)) then
    else_branch :: dbranches := dbranches;
    conds := listRest(conds);
  else
    else_branch := {};
  end if;

  dconds := listReverse(Expression.toDAE(c) for c in conds);
  ifEquation := if isInitial then
    DAE.Element.INITIAL_IF_EQUATION(dconds, dbranches, else_branch, source) else
    DAE.Element.IF_EQUATION(dconds, dbranches, else_branch, source);
end convertIfEquation;

function convertWhenEquation
  input list<tuple<Expression, list<Equation>>> whenBranches;
  input DAE.ElementSource source;
  output DAE.Element whenEquation;
protected
  DAE.Exp cond;
  list<DAE.Element> els;
  Option<DAE.Element> when_eq = NONE();
algorithm
  for b in listReverse(whenBranches) loop
    cond := Expression.toDAE(Util.tuple21(b));
    els := convertEquations(Util.tuple22(b));
    when_eq := SOME(DAE.Element.WHEN_EQUATION(cond, els, when_eq, source));
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
      list<DAE.Dimension> dims;
      list<DAE.Element> body;

    case Equation.EQUALITY()
      algorithm
        e1 := Expression.toDAE(eq.lhs);
        e2 := Expression.toDAE(eq.rhs);
      then
        DAE.Element.INITIALEQUATION(e1, e2, eq.source) :: elements;

    case Equation.ARRAY_EQUALITY()
      algorithm
        e1 := Expression.toDAE(eq.lhs);
        e2 := Expression.toDAE(eq.rhs);
        dims := list(Dimension.toDAE(d) for d in Type.arrayDims(eq.ty));
      then
        DAE.Element.INITIAL_ARRAY_EQUATION(dims, e1, e2, eq.source) :: elements;

    // For equations should have been unrolled here.
    case Equation.FOR()
      algorithm
        Error.assertion(false, getInstanceName() + " got a for equation", sourceInfo());
      then
        fail();

    case Equation.IF()
      then convertIfEquation(eq.branches, eq.source, isInitial = true) :: elements;

    case Equation.ASSERT()
      algorithm
        e1 := Expression.toDAE(eq.condition);
        e2 := Expression.toDAE(eq.message);
        e3 := Expression.toDAE(eq.level);
      then
        DAE.Element.INITIAL_ASSERT(e1, e2, e3, eq.source) :: elements;

    case Equation.TERMINATE()
      then DAE.Element.INITIAL_TERMINATE(Expression.toDAE(eq.message), eq.source) :: elements;

    case Equation.NORETCALL()
      then DAE.Element.INITIAL_NORETCALL(Expression.toDAE(eq.exp), eq.source) :: elements;

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
      list<DAE.Statement> body;

    case Statement.ASSIGNMENT() then convertAssignment(stmt);

    case Statement.FUNCTION_ARRAY_INIT()
      algorithm
        ty := Type.toDAE(stmt.ty);
      then
        DAE.Statement.STMT_ARRAY_INIT(stmt.name, ty, stmt.source);

    case Statement.FOR() then convertForStatement(stmt);
    case Statement.IF() then convertIfStatement(stmt.branches, stmt.source);
    case Statement.WHEN() then convertWhenStatement(stmt.branches, stmt.source);

    case Statement.ASSERT()
      algorithm
        e1 := Expression.toDAE(stmt.condition);
        e2 := Expression.toDAE(stmt.message);
        e3 := Expression.toDAE(stmt.level);
      then
        DAE.Statement.STMT_ASSERT(e1, e2, e3, stmt.source);

    case Statement.TERMINATE()
      then DAE.Statement.STMT_TERMINATE(Expression.toDAE(stmt.message), stmt.source);

    case Statement.NORETCALL()
      then DAE.Statement.STMT_NORETCALL(Expression.toDAE(stmt.exp), stmt.source);

    case Statement.WHILE()
      algorithm
        e1 := Expression.toDAE(stmt.condition);
        body := convertStatements(stmt.body);
      then
        DAE.Statement.STMT_WHILE(e1, body, stmt.source);

    case Statement.RETURN()
      then DAE.Statement.STMT_RETURN(stmt.source);

    case Statement.BREAK()
      then DAE.Statement.STMT_BREAK(stmt.source);

    case Statement.FAILURE()
      then DAE.Statement.STMT_FAILURE(convertStatements(stmt.body), stmt.source);

  end match;
end convertStatement;

function convertAssignment
  input Statement stmt;
  output DAE.Statement daeStmt;
protected
  Expression lhs, rhs;
  DAE.ElementSource src;
  Type ty;
  DAE.Type dty;
  DAE.Exp dlhs, drhs;
  list<Expression> expl;
algorithm
  Statement.ASSIGNMENT(lhs, rhs, src) := stmt;
  ty := Expression.typeOf(lhs);

  if Type.isTuple(ty) then
    Expression.TUPLE(elements = expl) := lhs;

    daeStmt := match expl
      // () := call(...) => call(...)
      case {} then DAE.Statement.STMT_NORETCALL(Expression.toDAE(rhs), src);

      // (lhs) := call(...) => lhs := TSUB[call(...), 1]
      case {lhs}
        algorithm
          ty := Expression.typeOf(lhs);
          dty := Type.toDAE(ty);
          dlhs := Expression.toDAE(lhs);
          drhs := DAE.Exp.TSUB(Expression.toDAE(rhs), 1, dty);

          if Type.isArray(ty) then
            daeStmt := DAE.Statement.STMT_ASSIGN_ARR(dty, dlhs, drhs, src);
          else
            daeStmt := DAE.Statement.STMT_ASSIGN(dty, dlhs, drhs, src);
          end if;
        then
          daeStmt;

      else
        algorithm
          dty := Type.toDAE(ty);
          drhs := Expression.toDAE(rhs);
        then
          DAE.Statement.STMT_TUPLE_ASSIGN(dty, list(Expression.toDAE(e) for e in expl), drhs, src);
    end match;
  else
    dty := Type.toDAE(ty);
    dlhs := Expression.toDAE(lhs);
    drhs := Expression.toDAE(rhs);
    daeStmt := DAE.Statement.STMT_ASSIGN(dty, dlhs, drhs, src);
  end if;
end convertAssignment;

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
  DAE.ElementSource source;
algorithm
  Statement.FOR(iterator = iterator, body = body, source = source) := forStmt;
  dbody := convertStatements(body);

  Component.ITERATOR(ty = ty, binding = binding) := InstNode.component(iterator);
  SOME(range) := Binding.typedExp(binding);

  forDAE := DAE.Statement.STMT_FOR(Type.toDAE(ty), Type.isArray(ty),
    InstNode.name(iterator), 0, Expression.toDAE(range), dbody, source);
end convertForStatement;

function convertIfStatement
  input list<tuple<Expression, list<Statement>>> ifBranches;
  input DAE.ElementSource source;
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

  ifStatement := DAE.Statement.STMT_IF(cond1, stmts1,  elseStatement, source);
end convertIfStatement;

function convertWhenStatement
  input list<tuple<Expression, list<Statement>>> whenBranches;
  input DAE.ElementSource source;
  output DAE.Statement whenStatement;
protected
  DAE.Exp cond;
  list<DAE.Statement> stmts;
  Option<DAE.Statement> when_stmt = NONE();
algorithm
  for b in listReverse(whenBranches) loop
    cond := Expression.toDAE(Util.tuple21(b));
    stmts := convertStatements(Util.tuple22(b));
    when_stmt := SOME(DAE.Statement.STMT_WHEN(cond, {}, false, stmts, when_stmt, source));
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
        Error.assertion(false, getInstanceName() + " got unknown function", sourceInfo());
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
  list<tuple<String, Binding>> ty_attr;
algorithm
  comp := InstNode.component(node);

  element := match comp
    case Component.TYPED_COMPONENT(ty = ty, info = info)
      algorithm
        cref := ComponentRef.fromNode(node, ty);
        binding := convertBinding(comp.binding);
        cls := InstNode.getClass(comp.classInst);
        ty_attr := list((Modifier.name(m), Modifier.binding(m)) for m in Class.getTypeAttributes(cls));
        var_attr := convertVarAttributes(ty_attr, ty);
        attr := comp.attributes;
      then
        makeDAEVar(cref, ty, binding, attr, InstNode.visibility(node), var_attr, comp.comment, true, info);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got untyped component.", sourceInfo());
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
