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
import Attributes = NFAttributes;
import NFBackendExtension.{BackendInfo, VariableAttributes};
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
import NFInstNode.InstNode;

public
function scalarize
  input output FlatModel flatModel;
algorithm
  flatModel.variables := scalarizeVariables(flatModel.variables);
  flatModel.equations := Equation.mapExpList(flatModel.equations, expandComplexCref);
  flatModel.equations := scalarizeEquations(flatModel.equations);
  flatModel.initialEquations := Equation.mapExpList(flatModel.initialEquations, expandComplexCref);
  flatModel.initialEquations := scalarizeEquations(flatModel.initialEquations);
  flatModel.algorithms := list(scalarizeAlgorithm(a) for a in flatModel.algorithms);
  flatModel.initialAlgorithms := list(scalarizeAlgorithm(a) for a in flatModel.initialAlgorithms);

  execStat(getInstanceName());
end scalarize;

function scalarizeVariables
  input list<Variable> vars;
  input Boolean forceScalarize = false;
  output list<Variable> outVars = {};
algorithm
  for v in vars loop
    outVars := scalarizeVariable(v, outVars, forceScalarize);
  end for;

  outVars := listReverseInPlace(outVars);
end scalarizeVariables;

function scalarizeVariable
  input Variable var;
  input output list<Variable> vars = {};
  input Boolean forceScalarize = false;
protected
  ComponentRef name;
  Binding binding;
  Type ty, elem_ty;
  Visibility vis;
  Attributes attr;
  list<tuple<String, Binding>> ty_attr;
  Option<SCode.Comment> cmt;
  SourceInfo info;
  ExpressionIterator binding_iter;
  list<ComponentRef> crefs;
  Expression exp;
  list<String> ty_attr_names;
  array<ExpressionIterator> ty_attr_iters;
  list<BackendInfo> backend_attributes;
  Variability bind_var;
  BackendInfo binfo;
  Binding.Source bind_src;
  Boolean has_binding;
algorithm
  var.binding := Binding.mapExp(var.binding, expandComplexCref_traverser);

  if Type.isArray(var.ty) and Type.hasKnownSize(var.ty) then
    try
      Variable.VARIABLE(name, ty, binding, vis, attr, ty_attr, _, cmt, info, binfo) := var;
      crefs := ComponentRef.scalarize(name, false);

      if listEmpty(crefs) then
        return;
      end if;

      has_binding := Binding.isBound(binding);
      bind_src := Binding.source(binding);

      if has_binding then
        binding_iter := ExpressionIterator.fromExp(Binding.getTypedExp(binding));
        bind_var := Binding.variability(binding);

        // Avoid scalarizing the variable if it would result in indexing a
        // function call (#6267), unless we're building an FMU or the variable
        // has attributes that must be scalarized (#7485).
        if not forceScalarize and
           ExpressionIterator.isSubscriptedArrayCall(binding_iter) and
           not Flags.getConfigBool(Flags.BUILDING_FMU) and
           not variableHasForcedScalarAttribute(var) then
          vars := var :: vars;
          return;
        end if;
      else
        bind_var := Variability.CONSTANT; // Not used
      end if;

      elem_ty := Type.arrayElementType(ty);
      (ty_attr_names, ty_attr_iters) := scalarizeTypeAttributes(ty_attr);
      backend_attributes := BackendInfo.scalarize(binfo, listLength(crefs));

      for cr in crefs loop
        if has_binding then
          (binding_iter, exp) := ExpressionIterator.next(binding_iter);
          binding := Binding.makeFlat(exp, bind_var, bind_src);
        end if;

        ty_attr := nextTypeAttributes(ty_attr_names, ty_attr_iters);
        binfo :: backend_attributes := backend_attributes;
        vars := Variable.VARIABLE(cr, elem_ty, binding, vis, attr, ty_attr, {}, cmt, info, binfo) :: vars;
      end for;
    else
      Error.assertion(false, getInstanceName() + " failed on " +
        Variable.toString(var, printBindingType = true), var.info);
    end try;
  else
    vars := var :: vars;
  end if;
end scalarizeVariable;

function scalarizeBackendVariable
  input Variable var;
  input List<Integer> indices = {};
  input output list<Variable> vars = {};
protected
  list<ComponentRef> crefs;
  ExpressionIterator binding_iter;
  Binding binding;
  Variability bind_var;
  Binding.Source bind_src;
  Expression exp;
  Type elem_ty;
  BackendInfo binfo;
  list<BackendInfo> backend_attributes;
algorithm
  try
    vars := listReverse(vars);
    crefs               := ComponentRef.scalarizeAll(ComponentRef.stripSubscriptsAll(var.name), false);
    elem_ty             := Type.arrayElementType(var.ty);
    backend_attributes  := BackendInfo.scalarize(var.backendinfo, listLength(crefs));
    if Binding.isBound(var.binding) then
      binding_iter      := ExpressionIterator.fromExp(Binding.getTypedExp(var.binding), true);
      bind_var          := Binding.variability(var.binding);
      bind_src          := Binding.source(var.binding);
      for cr in listReverse(crefs) loop
        (binding_iter, exp) := ExpressionIterator.next(binding_iter);
        binding := Binding.makeFlat(exp, bind_var, bind_src);
        binfo :: backend_attributes := backend_attributes;
        vars := Variable.VARIABLE(cr, elem_ty, binding, var.visibility, var.attributes, {}, {}, var.comment, var.info, binfo) :: vars;
      end for;
    else
      for cr in listReverse(crefs) loop
        binfo :: backend_attributes := backend_attributes;
        vars := Variable.VARIABLE(cr, elem_ty, var.binding, var.visibility, var.attributes, {}, {}, var.comment, var.info, binfo) :: vars;
      end for;
    end if;
    // filter sliced variables
    // ToDo: do this more efficiently and not create them in the first place
    if not (listEmpty(indices) or listLength(indices) == listLength(vars)) then
      vars := List.keepPositions(vars, indices);
    end if;
  else
    Error.assertion(false, getInstanceName() + " failed for: " + Variable.toString(var), sourceInfo());
  end try;
  vars := listReverse(vars);
end scalarizeBackendVariable;

function scalarizeComplexVariable
  "Scalarizes a complex variable to its elements. Assumes potential arrays
  have already been resolved with scalarizeVariable()."
  input Variable var;
  input output list<Variable> vars = {};
algorithm
  vars := match var.backendinfo.attributes
      local
        VariableAttributes attr;
        String name;
        Integer index;
        Variable elem_var;

    case attr as VariableAttributes.VAR_ATTR_RECORD() algorithm
      for tpl in UnorderedMap.toList(attr.indexMap) loop
        (name, index) := tpl;
        elem_var := var;
        elem_var.name := ComponentRef.prepend(elem_var.name, ComponentRef.rename(name, elem_var.name));
        elem_var.backendinfo := BackendInfo.setAttributes(elem_var.backendinfo, attr.childrenAttr[index], var.backendinfo.annotations);
        // update the types accordingly
        elem_var.ty := VariableAttributes.elemType(attr.childrenAttr[index]);
        elem_var.name := ComponentRef.setNodeType(elem_var.ty, elem_var.name);
        vars := elem_var :: vars;
      end for;
    then listReverse(vars);

    else {var};
  end match;
end scalarizeComplexVariable;

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
    attrs := (name, Binding.makeFlat(exp, Variability.PARAMETER, NFBinding.Source.BINDING)) :: attrs;
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
  input Boolean forceScalarize = false;
  output list<Equation> equations = {};
algorithm
  for eq in eql loop
    equations := scalarizeEquation(eq, equations, forceScalarize);
  end for;

  equations := listReverseInPlace(equations);
end scalarizeEquations;

function scalarizeEquation
  input Equation eq;
  input output list<Equation> equations;
  input Boolean forceScalarize = false;
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
        if not forceScalarize and (Expression.hasArrayCall(lhs) or Expression.hasArrayCall(rhs)) then
          equations := Equation.ARRAY_EQUALITY(lhs, rhs, ty, eq.scope, src) :: equations;
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
            equations := Equation.EQUALITY(lhs, rhs, ty, eq.scope, src) :: equations;
          end while;
        end if;
      then
        equations;

    case Equation.ARRAY_EQUALITY() guard forceScalarize
      then scalarizeEquation(Equation.EQUALITY(eq.lhs, eq.rhs, eq.ty, eq.scope, eq.source), equations, true);

    case Equation.CONNECT() then equations;

    case Equation.IF()
      then scalarizeIfEquation(eq.branches, eq.scope, eq.source, equations);

    case Equation.WHEN()
      then scalarizeWhenEquation(eq.branches, eq.scope, eq.source, equations);

    else eq :: equations;
  end match;
end scalarizeEquation;

function scalarizeIfEquation
  input list<Equation.Branch> branches;
  input InstNode scope;
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
    equations := Equation.IF(listReverseInPlace(bl), scope, source) :: equations;
  end if;
end scalarizeIfEquation;

function scalarizeWhenEquation
  input list<Equation.Branch> branches;
  input InstNode scope;
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

  equations := Equation.WHEN(listReverseInPlace(bl), scope, source) :: equations;
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
      then Statement.FOR(stmt.iterator, stmt.range, scalarizeStatements(stmt.body), stmt.forType, stmt.source) :: statements;

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

function variableHasForcedScalarAttribute
  input Variable var;
  output Boolean res;
algorithm
  for attribute in {"min", "max", "nominal"} loop
    if Binding.isBound(Variable.lookupTypeAttribute(attribute, var)) then
      res := true;
      return;
    end if;
  end for;

  res := false;
end variableHasForcedScalarAttribute;

annotation(__OpenModelica_Interface="frontend");
end NFScalarize;
