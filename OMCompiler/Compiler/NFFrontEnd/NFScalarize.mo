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
import BackendInfo = NFBackendExtension.BackendInfo;
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
import Component = NFComponent;
import NFPrefixes.Visibility;
import NFPrefixes.Variability;
import List;
import ElementSource;
import DAE;
import Statement = NFStatement;
import Algorithm = NFAlgorithm;
import ExpandExp = NFExpandExp;

public
function scalarize
  input output FlatModel flatModel;
protected
  list<Variable> vars = {};
  list<Equation> eql = {}, ieql = {};
  list<Algorithm> alg = {}, ialg = {};
algorithm
  for c in flatModel.variables loop
    vars := scalarizeVariable(c, vars);
  end for;

  flatModel.variables := listReverseInPlace(vars);
  flatModel.equations := Equation.mapExpList(flatModel.equations, expandComplexCref);
  flatModel.equations := scalarizeEquations(flatModel.equations);
  flatModel.initialEquations := Equation.mapExpList(flatModel.initialEquations, expandComplexCref);
  flatModel.initialEquations := scalarizeEquations(flatModel.initialEquations);
  flatModel.algorithms := list(scalarizeAlgorithm(a) for a in flatModel.algorithms);
  flatModel.initialAlgorithms := list(scalarizeAlgorithm(a) for a in flatModel.initialAlgorithms);

  execStat(getInstanceName());
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
  Variability bind_var;
  BackendInfo binfo;
algorithm
  if Type.isArray(var.ty) then
    try
      Variable.VARIABLE(name, ty, binding, vis, attr, ty_attr, cmt, info, binfo) := var;
      crefs := ComponentRef.scalarize(name);

      if listEmpty(crefs) then
        return;
      end if;

      ty := Type.arrayElementType(ty);
      (ty_attr_names, ty_attr_iters) := scalarizeTypeAttributes(ty_attr);

      if Binding.isBound(binding) then
        binding_iter := ExpressionIterator.fromExp(expandComplexCref(Binding.getTypedExp(binding)));
        bind_var := Binding.variability(binding);

        for cr in crefs loop
          (binding_iter, exp) := ExpressionIterator.next(binding_iter);
          binding := Binding.FLAT_BINDING(exp, bind_var);
          ty_attr := nextTypeAttributes(ty_attr_names, ty_attr_iters);
          vars := Variable.VARIABLE(cr, ty, binding, vis, attr, ty_attr, cmt, info, binfo) :: vars;
        end for;
      else
        for cr in crefs loop
          ty_attr := nextTypeAttributes(ty_attr_names, ty_attr_iters);
          vars := Variable.VARIABLE(cr, ty, binding, vis, attr, ty_attr, cmt, info, binfo) :: vars;
        end for;
      end if;
    else
      Error.assertion(false, getInstanceName() + " failed on " +
        Variable.toString(var, printBindingType = true), var.info);
    end try;
  else
    var.binding := Binding.mapExp(var.binding, expandComplexCref_traverser);
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
    attrs := (name, Binding.FLAT_BINDING(exp, Variability.PARAMETER)) :: attrs;
  end for;
end nextTypeAttributes;

function expandComplexCref
  input output Expression exp;
algorithm
  exp := Expression.map(exp, expandComplexCref_traverser);
end expandComplexCref;

function expandComplexCref_traverser
  input output Expression exp;
algorithm
  () := match exp
    case Expression.CREF(ty = Type.ARRAY())
      algorithm
        // Expand crefs where any of the prefix nodes are arrays. For example if
        // b in a.b.c is SomeType[2] we expand it into {a.b[1].c, a.b[2].c}.
        // TODO: This is only done due to backend issues and shouldn't be
        //       necessary.
        if ComponentRef.isComplexArray(exp.cref) then
          exp := ExpandExp.expand(exp);
        end if;
      then
        ();

    else ();
  end match;
end expandComplexCref_traverser;

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

    case Equation.EQUALITY(lhs = lhs, rhs = rhs, ty = ty, source = src) guard Type.isArray(ty)
      algorithm
        if Expression.hasArrayCall(lhs) or Expression.hasArrayCall(rhs) then
          equations := Equation.ARRAY_EQUALITY(lhs, rhs, ty, src) :: equations;
        else
          lhs_iter := ExpressionIterator.fromExp(lhs);
          rhs_iter := ExpressionIterator.fromExp(rhs);
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
        end if;
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
  input list<Equation.Branch> branches;
  input DAE.ElementSource source;
  input output list<Equation> equations;
protected
  list<Equation.Branch> bl = {};
  Expression cond;
  list<Equation> body;
  Variability var;
algorithm
  for b in branches loop
    Equation.Branch.BRANCH(cond, var, body) := b;
    body := scalarizeEquations(body);

    // Remove branches with no equations after scalarization.
    if not listEmpty(body) then
      bl := Equation.makeBranch(cond, body, var) :: bl;
    end if;
  end for;

  // Add the scalarized if equation to the list of equations unless we don't
  // have any branches left.
  if not listEmpty(bl) then
    equations := Equation.IF(listReverseInPlace(bl), source) :: equations;
  end if;
end scalarizeIfEquation;

function scalarizeWhenEquation
  input list<Equation.Branch> branches;
  input DAE.ElementSource source;
  input output list<Equation> equations;
protected
  list<Equation.Branch> bl = {};
  Expression cond;
  list<Equation> body;
  Variability var;
algorithm
  for b in branches loop
    Equation.Branch.BRANCH(cond, var, body) := b;
    body := scalarizeEquations(body);

    if Type.isArray(Expression.typeOf(cond)) then
      cond := ExpandExp.expand(cond);
    end if;

    bl := Equation.makeBranch(cond, body, var) :: bl;
  end for;

  equations := Equation.WHEN(listReverseInPlace(bl), source) :: equations;
end scalarizeWhenEquation;

function scalarizeAlgorithm
  input output Algorithm alg;
algorithm
  alg.statements := scalarizeStatements(alg.statements);
end scalarizeAlgorithm;

function scalarizeStatements
  input list<Statement> stmts;
  output list<Statement> statements = {};
algorithm
  for s in stmts loop
    statements := scalarizeStatement(s, statements);
  end for;

  statements := listReverseInPlace(statements);
end scalarizeStatements;

function scalarizeStatement
  input Statement stmt;
  input output list<Statement> statements;
algorithm
  statements := match stmt
    case Statement.FOR()
      then Statement.FOR(stmt.iterator, stmt.range, scalarizeStatements(stmt.body), stmt.source) :: statements;

    case Statement.IF()
      then scalarizeIfStatement(stmt.branches, stmt.source, statements);

    case Statement.WHEN()
      then scalarizeWhenStatement(stmt.branches, stmt.source, statements);

    case Statement.WHILE()
      then Statement.WHILE(stmt.condition, scalarizeStatements(stmt.body), stmt.source) :: statements;

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
    body := scalarizeStatements(body);

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
    body := scalarizeStatements(body);

    if Type.isArray(Expression.typeOf(cond)) then
      cond := ExpandExp.expand(cond);
    end if;

    bl := (cond, body) :: bl;
  end for;

  statements := Statement.WHEN(listReverseInPlace(bl), source) :: statements;
end scalarizeWhenStatement;

annotation(__OpenModelica_Interface="frontend");
end NFScalarize;
