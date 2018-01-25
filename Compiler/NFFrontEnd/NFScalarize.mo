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

public
function scalarize
  input output FlatModel flatModel;
  input String name;
protected
  list<Variable> vars = {};
  list<Equation> eql = {}, ieql = {};
algorithm
  for c in flatModel.variables loop
    vars := scalarizeVariable(c, vars);
  end for;

  for eq in flatModel.equations loop
    eql := scalarizeEquation(eq, eql); end for;

  for eq in flatModel.initialEquations loop
    ieql := scalarizeEquation(eq, ieql);
  end for;

  flatModel.variables := listReverseInPlace(vars);
  flatModel.equations := listReverseInPlace(eql);
  flatModel.initialEquations := listReverseInPlace(ieql);

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
    ty := Type.arrayElementType(ty);
    (ty_attr_names, ty_attr_iters) := scalarizeTypeAttributes(ty_attr);

    if Binding.isBound(binding) and not Binding.isEach(binding) then
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
  Integer i = 1;
  String name;
  Binding binding;
algorithm
  iters := arrayCreateNoInit(listLength(attrs), ExpressionIterator.NONE_ITERATOR());

  for attr in attrs loop
    (name, binding) := attr;
    names := name :: names;
    arrayUpdate(iters, i, ExpressionIterator.fromBinding(binding));
    i := i + 1;
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
      algorithm
        rhs := Expression.expand(eq.rhs);
      then
        Equation.ARRAY_EQUALITY(eq.lhs, rhs, eq.ty, eq.source) :: equations;

    case Equation.CONNECT() then equations;

    case Equation.IF()
      then scalarizeIfEquation(eq.branches, eq.source, equations);

    case Equation.WHEN()
      then Equation.WHEN(list(scalarizeBranch(b) for b in eq.branches), eq.source) :: equations;

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
  list<Equation> eql;
algorithm
  for b in branches loop
    (cond, eql) := b;
    eql := scalarizeEquations(eql);

    // Remove branches with no equations after scalarization.
    if not listEmpty(eql) then
      bl := (cond, eql) :: bl;
    end if;
  end for;

  // Add the scalarized if equation to the list of equations unless we don't
  // have any branches left.
  if not listEmpty(bl) then
    equations := Equation.IF(listReverseInPlace(bl), source) :: equations;
  end if;
end scalarizeIfEquation;

function scalarizeBranch
  input output tuple<Expression, list<Equation>> branch;
protected
  Expression exp;
  list<Equation> eql;
algorithm
  (exp, eql) := branch;
  branch := (exp, scalarizeEquations(eql));
end scalarizeBranch;

annotation(__OpenModelica_Interface="frontend");
end NFScalarize;
