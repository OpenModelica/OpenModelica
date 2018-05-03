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

encapsulated package NFScalarize

import FlatModel = NFFlatModel;
import NFFlatten.FunctionTree;

protected
import ExecStat.execStat;
import ComponentRef = NFComponentRef;
import Type = NFType;
import Expression = NFExpression;
import Binding = NFBinding;
import Equation = NFEquation;
import ExpressionIterator = NFExpressionIterator;
import Dimension = NFDimension;
import MetaModelica.Dangerous.listReverseInPlace;
import MetaModelica.Dangerous.arrayCreateNoInit;
import Variable = NFVariable;
import NFComponent.Component;
import NFPrefixes.Visibility;
import List;
import ElementSource;
import DAE;
import Statement = NFStatement;

public
function scalarize
  input output FlatModel flatModel;
  input String name;
protected
  list<Variable> vars = {};
  list<Equation> eql = {}, ieql = {};
  list<list<Statement>> alg = {}, ialg = {};
algorithm
  for c in flatModel.variables loop
    vars := scalarizeVariable(c, vars);
  end for;

  flatModel.variables := listReverseInPlace(vars);
  flatModel.equations := scalarizeEquations(flatModel.equations);
  flatModel.initialEquations := scalarizeEquations(flatModel.initialEquations);
  flatModel.algorithms := list(scalarizeAlgorithm(a) for a in flatModel.algorithms);
  flatModel.initialAlgorithms := list(scalarizeAlgorithm(a) for a in flatModel.initialAlgorithms);

  execStat(getInstanceName() + "(" + name + ")");
end scalarize;

protected
function scalarizeVariable
  input Variable var;
  input output list<Variable> vars;
protected
  ComponentRef name;
  Binding binding;
  Type ty;
  Visibility vis;
  Component.Attributes attr;
  list<tuple<String, Binding>> ty_attr;
  Option<SCode.Comment> cmt;
  SourceInfo info;
  ExpressionIterator binding_iter;
  list<ComponentRef> crefs;
  Expression exp;
  Variable v;
  list<String> ty_attr_names;
  array<ExpressionIterator> ty_attr_iters;
algorithm
  if Type.isArray(var.ty) then
    Variable.VARIABLE(name, ty, binding, vis, attr, ty_attr, cmt, info) := var;
    crefs := ComponentRef.scalarize(name);

    if listEmpty(crefs) then
      return;
    end if;

    ty := Type.arrayElementType(ty);
    (ty_attr_names, ty_attr_iters) := scalarizeTypeAttributes(ty_attr);

    if Binding.isBound(binding) then
      binding_iter := ExpressionIterator.fromExp(Binding.getTypedExp(binding));

      for cr in crefs loop
        (binding_iter, exp) := ExpressionIterator.next(binding_iter);
        binding := Binding.FLAT_BINDING(exp);
        ty_attr := nextTypeAttributes(ty_attr_names, ty_attr_iters);
        vars := Variable.VARIABLE(cr, ty, binding, vis, attr, ty_attr, cmt, info) :: vars;
      end for;
    else
      for cr in crefs loop
        ty_attr := nextTypeAttributes(ty_attr_names, ty_attr_iters);
        vars := Variable.VARIABLE(cr, ty, binding, vis, attr, ty_attr, cmt, info) :: vars;
      end for;
    end if;
  else
    vars := var :: vars;
  end if;
end scalarizeVariable;

function scalarizeTypeAttributes
  input list<tuple<String, Binding>> attrs;
  output list<String> names = {};
  output array<ExpressionIterator> iters;
protected
  Integer len, i;
  String name;
  Binding binding;
algorithm
  len := listLength(attrs);
  iters := arrayCreateNoInit(len, ExpressionIterator.NONE_ITERATOR());
  i := len;

  for attr in attrs loop
    (name, binding) := attr;
    names := name :: names;
    arrayUpdate(iters, i, ExpressionIterator.fromBinding(binding));
    i := i - 1;
  end for;
end scalarizeTypeAttributes;

function nextTypeAttributes
  input list<String> names;
  input array<ExpressionIterator> iters;
  output list<tuple<String, Binding>> attrs = {};
protected
  Integer i = 1;
  ExpressionIterator iter;
  Expression exp;
algorithm
  for name in names loop
    (iter, exp) := ExpressionIterator.next(iters[i]);
    arrayUpdate(iters, i, iter);
    i := i + 1;
    attrs := (name, Binding.FLAT_BINDING(exp)) :: attrs;
  end for;
end nextTypeAttributes;

function scalarizeEquations
  input list<Equation> eql;
  output list<Equation> equations = {};
algorithm
  for eq in eql loop
    equations := scalarizeEquation(eq, equations);
  end for;

  equations := listReverseInPlace(equations);
end scalarizeEquations;

function scalarizeEquation
  input Equation eq;
  input output list<Equation> equations;
algorithm
  equations := match eq
    local
      ExpressionIterator lhs_iter, rhs_iter;
      Expression lhs, rhs;
      Type ty;
      DAE.ElementSource src;
      SourceInfo info;
      list<Equation> eql;

    case Equation.EQUALITY(ty = ty, source = src) guard Type.isArray(ty)
      algorithm
        lhs_iter := ExpressionIterator.fromExp(eq.lhs);
        rhs_iter := ExpressionIterator.fromExp(eq.rhs);
        ty := Type.arrayElementType(ty);

        while ExpressionIterator.hasNext(lhs_iter) loop
          if not ExpressionIterator.hasNext(rhs_iter) then
            Error.addInternalError(getInstanceName() + " could not expand rhs " +
              Expression.toString(eq.rhs), ElementSource.getInfo(src));
          end if;

          (lhs_iter, lhs) := ExpressionIterator.next(lhs_iter);
          (rhs_iter, rhs) := ExpressionIterator.next(rhs_iter);
          equations := Equation.EQUALITY(lhs, rhs, ty, src) :: equations;
        end while;
      then
        equations;

    case Equation.ARRAY_EQUALITY()
      then Equation.ARRAY_EQUALITY(eq.lhs, eq.rhs, eq.ty, eq.source) :: equations;

    case Equation.CONNECT() then equations;

    case Equation.IF()
      then scalarizeIfEquation(eq.branches, eq.source, equations);

    case Equation.WHEN()
      then scalarizeWhenEquation(eq.branches, eq.source, equations);

    else eq :: equations;
  end match;
end scalarizeEquation;

function scalarizeIfEquation
  input list<tuple<Expression, list<Equation>>> branches;
  input DAE.ElementSource source;
  input output list<Equation> equations;
protected
  list<tuple<Expression, list<Equation>>> bl = {};
  Expression cond;
  list<Equation> body;
algorithm
  for b in branches loop
    (cond, body) := b;
    body := scalarizeEquations(body);

    // Remove branches with no equations after scalarization.
    if not listEmpty(body) then
      bl := (cond, body) :: bl;
    end if;
  end for;

  // Add the scalarized if equation to the list of equations unless we don't
  // have any branches left.
  if not listEmpty(bl) then
    equations := Equation.IF(listReverseInPlace(bl), source) :: equations;
  end if;
end scalarizeIfEquation;

function scalarizeWhenEquation
  input list<tuple<Expression, list<Equation>>> branches;
  input DAE.ElementSource source;
  input output list<Equation> equations;
protected
  list<tuple<Expression, list<Equation>>> bl = {};
  Expression cond;
  list<Equation> body;
algorithm
  for b in branches loop
    (cond, body) := b;
    body := scalarizeEquations(body);

    if Type.isArray(Expression.typeOf(cond)) then
      cond := Expression.expand(cond);
    end if;

    bl := (cond, body) :: bl;
  end for;

  equations := Equation.WHEN(listReverseInPlace(bl), source) :: equations;
end scalarizeWhenEquation;

function scalarizeAlgorithm
  input list<Statement> stmts;
  output list<Statement> statements = {};
algorithm
  for s in stmts loop
    statements := scalarizeStatement(s, statements);
  end for;

  statements := listReverseInPlace(statements);
end scalarizeAlgorithm;

function scalarizeStatement
  input Statement stmt;
  input output list<Statement> statements;
algorithm
  statements := match stmt
    case Statement.FOR()
      then Statement.FOR(stmt.iterator, stmt.range, scalarizeAlgorithm(stmt.body), stmt.source) :: statements;

    case Statement.IF()
      then scalarizeIfStatement(stmt.branches, stmt.source, statements);

    case Statement.WHEN()
      then scalarizeWhenStatement(stmt.branches, stmt.source, statements);

    case Statement.WHILE()
      then Statement.WHILE(stmt.condition, scalarizeAlgorithm(stmt.body), stmt.source) :: statements;

    else stmt :: statements;
  end match;
end scalarizeStatement;

function scalarizeIfStatement
  input list<tuple<Expression, list<Statement>>> branches;
  input DAE.ElementSource source;
  input output list<Statement> statements;
protected
  list<tuple<Expression, list<Statement>>> bl = {};
  Expression cond;
  list<Statement> body;
algorithm
  for b in branches loop
    (cond, body) := b;
    body := scalarizeAlgorithm(body);

    // Remove branches with no statements after scalarization.
    if not listEmpty(body) then
      bl := (cond, body) :: bl;
    end if;
  end for;

  // Add the scalarized if statement to the list of statements unless we don't
  // have any branches left.
  if not listEmpty(bl) then
    statements := Statement.IF(listReverseInPlace(bl), source) :: statements;
  end if;
end scalarizeIfStatement;

function scalarizeWhenStatement
  input list<tuple<Expression, list<Statement>>> branches;
  input DAE.ElementSource source;
  input output list<Statement> statements;
protected
  list<tuple<Expression, list<Statement>>> bl = {};
  Expression cond;
  list<Statement> body;
algorithm
  for b in branches loop
    (cond, body) := b;
    body := scalarizeAlgorithm(body);

    if Type.isArray(Expression.typeOf(cond)) then
      cond := Expression.expand(cond);
    end if;

    bl := (cond, body) :: bl;
  end for;

  statements := Statement.WHEN(listReverseInPlace(bl), source) :: statements;
end scalarizeWhenStatement;

annotation(__OpenModelica_Interface="frontend");
end NFScalarize;
