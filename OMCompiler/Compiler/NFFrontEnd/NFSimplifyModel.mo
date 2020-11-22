/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFSimplifyModel

import FlatModel = NFFlatModel;
import Equation = NFEquation;
import Statement = NFStatement;
import Expression = NFExpression;
import Type = NFType;
import ComponentRef = NFComponentRef;
import NFFlatten.FunctionTree;
import Class = NFClass;
import NFInstNode.InstNode;
import NFFunction.Function;
import Sections = NFSections;
import Binding = NFBinding;
import Variable = NFVariable;
import Algorithm = NFAlgorithm;
import Dimension = NFDimension;
import Subscript = NFSubscript;

protected
import MetaModelica.Dangerous.*;
import ExecStat.execStat;
import SimplifyExp = NFSimplifyExp;
import NFPrefixes.Variability;
import Ceval = NFCeval;

public
function simplify
  input output FlatModel flatModel;
algorithm
  flatModel.variables := list(simplifyVariable(v) for v in flatModel.variables);
  flatModel.equations := simplifyEquations(flatModel.equations);
  flatModel.initialEquations := simplifyEquations(flatModel.initialEquations);
  flatModel.algorithms := simplifyAlgorithms(flatModel.algorithms);
  flatModel.initialAlgorithms := simplifyAlgorithms(flatModel.initialAlgorithms);

  execStat(getInstanceName());
end simplify;

function simplifyVariable
  input output Variable var;
algorithm
  var.binding := simplifyBinding(var.binding);
  var.typeAttributes := list(simplifyTypeAttribute(a) for a in var.typeAttributes);
end simplifyVariable;

function simplifyBinding
  input output Binding binding;
protected
  Expression exp, sexp;
algorithm
  if Binding.isBound(binding) then
    exp := Binding.getTypedExp(binding);
    sexp := SimplifyExp.simplify(exp);
    sexp := removeEmptyFunctionArguments(sexp);

    if not referenceEq(exp, sexp) then
      binding := Binding.setTypedExp(sexp, binding);
    end if;
  end if;
end simplifyBinding;

function simplifyTypeAttribute
  input output tuple<String, Binding> attribute;
protected
  String name;
  Binding binding, sbinding;
algorithm
  (name, binding) := attribute;
  sbinding := simplifyBinding(binding);

  if not referenceEq(binding, sbinding) then
    attribute := (name, sbinding);
  end if;
end simplifyTypeAttribute;

function simplifyDimension
  input Dimension dim;
  output Dimension outDim;
algorithm
  outDim := match dim
    local
      Expression e;

    case Dimension.EXP()
      algorithm
        e := SimplifyExp.simplify(dim.exp);
      then
        if referenceEq(e, dim.exp) then dim else Dimension.fromExp(e, dim.var);

    else dim;
  end match;
end simplifyDimension;

function simplifyEquations
  input list<Equation> eql;
  output list<Equation> outEql = {};
algorithm
  for eq in eql loop
    outEql := simplifyEquation(eq, outEql);
  end for;

  outEql := listReverseInPlace(outEql);
end simplifyEquations;

function simplifyEquation
  input Equation eq;
  input output list<Equation> equations;
algorithm
  equations := match eq
    local
      Expression e, lhs, rhs;
      Type ty;
      Dimension dim;
      list<Equation> body;

    case Equation.EQUALITY() then simplifyEqualityEquation(eq, equations);

    case Equation.ARRAY_EQUALITY()
      algorithm
        ty := Type.mapDims(eq.ty, simplifyDimension);

        if not Type.isEmptyArray(ty) then
          rhs := removeEmptyFunctionArguments(SimplifyExp.simplify(eq.rhs));
          equations := Equation.ARRAY_EQUALITY(eq.lhs, rhs, ty, eq.source) :: equations;
        end if;
      then
        equations;

    case Equation.FOR(range = SOME(e))
      algorithm
        body := simplifyEquations(eq.body);

        if not Equation.containsExpList(body, function Expression.containsIterator(iterator = eq.iterator)) then
          equations := List.append_reverse(body, equations);
        else
          // TODO: This causes issues with the -nfScalarize tests for some reason.
          //dim := Type.nthDimension(Expression.typeOf(e), 1);

          //if Dimension.isOne(dim) then
          //  e := Expression.applySubscript(Subscript.INDEX(Expression.INTEGER(1)), e);

          //  body := Equation.mapExpList(body,
          //    function Expression.replaceIterator(iterator = eq.iterator, iteratorValue = e));
          //  body := simplifyEquations(body);
          //  equations := List.append_reverse(body, equations);
          //elseif not Dimension.isZero(dim) then
            eq.range := SimplifyExp.simplifyOpt(eq.range);
            eq.body := body;
            equations := eq :: equations;
          //end if;
        end if;
      then
        equations;

    case Equation.IF()
      then simplifyIfEqBranches(eq.branches, eq.source, equations);

    case Equation.WHEN()
      algorithm
        eq.branches := list(
          match b
            case Equation.Branch.BRANCH()
              algorithm
                b.condition := SimplifyExp.simplify(b.condition);
                b.body := simplifyEquations(b.body);
              then
                b;
          end match
        for b in eq.branches);
      then
        eq :: equations;

    case Equation.ASSERT()
      algorithm
        eq.condition := SimplifyExp.simplify(eq.condition);
      then
        if Expression.isTrue(eq.condition) then equations else eq :: equations;

    case Equation.REINIT()
      algorithm
        eq.reinitExp := SimplifyExp.simplify(eq.reinitExp);
      then
        eq :: equations;

    case Equation.NORETCALL()
      algorithm
        e := SimplifyExp.simplify(eq.exp);

        if Expression.isCall(e) then
          eq.exp := removeEmptyFunctionArguments(e);
          equations := eq :: equations;
        end if;
      then
        equations;

    else eq :: equations;
  end match;
end simplifyEquation;

function simplifyEqualityEquation
  input Equation eq;
  input output list<Equation> equations;
protected
  Expression lhs, rhs;
  Type ty;
  DAE.ElementSource src;
algorithm
  Equation.EQUALITY(lhs = lhs, rhs = rhs, ty = ty, source = src) := eq;
  ty := Type.mapDims(ty, simplifyDimension);

  if Type.isEmptyArray(ty) then
    return;
  end if;

  lhs := SimplifyExp.simplify(lhs);
  lhs := removeEmptyTupleElements(lhs);
  rhs := SimplifyExp.simplify(rhs);
  rhs := removeEmptyFunctionArguments(rhs);

  equations := match (lhs, rhs)
    case (Expression.TUPLE(), Expression.TUPLE())
      then simplifyTupleElement(lhs.elements, rhs.elements, ty, src, Equation.makeEquality, equations);

    else Equation.EQUALITY(lhs, rhs, ty, src) :: equations;
  end match;
end simplifyEqualityEquation;

function simplifyAlgorithms
  input list<Algorithm> algs;
  output list<Algorithm> outAlgs = {};
algorithm
  for alg in algs loop
    alg := simplifyAlgorithm(alg);

    if not listEmpty(alg.statements) then
      outAlgs := alg :: outAlgs;
    end if;
  end for;

  outAlgs := listReverseInPlace(outAlgs);
end simplifyAlgorithms;

function simplifyAlgorithm
  input output Algorithm alg;
algorithm
  alg.statements := simplifyStatements(alg.statements);
end simplifyAlgorithm;

function simplifyStatements
  input list<Statement> stmts;
  output list<Statement> outStmts = {};
algorithm
  for s in stmts loop
    outStmts := simplifyStatement(s, outStmts);
  end for;

  outStmts := listReverseInPlace(outStmts);
end simplifyStatements;

function simplifyStatement
  input Statement stmt;
  input output list<Statement> statements;
algorithm
  statements := match stmt
    local
      Expression e, lhs, rhs;
      Type ty;
      Dimension dim;
      list<Statement> body;

    case Statement.ASSIGNMENT() then simplifyAssignment(stmt, statements);

    case Statement.FOR(range = SOME(e))
      algorithm
        ty := Expression.typeOf(e);
        dim := Type.nthDimension(ty, 1);

        //if Dimension.isOne(dim) then
        //  e := Expression.applySubscript(Subscript.INDEX(Expression.INTEGER(1)), e);
        //  body := Statement.mapExpList(stmt.body,
        //    function Expression.replaceIterator(iterator = stmt.iterator, iteratorValue = e));
        //  body := simplifyStatements(body);
        //  statements := listAppend(listReverse(body), statements);
        //elseif not Dimension.isZero(dim) then
        if not Dimension.isZero(dim) then
          stmt.range := SOME(SimplifyExp.simplify(e));
          stmt.body := simplifyStatements(stmt.body);
          statements := stmt :: statements;
        end if;
      then
        statements;

    case Statement.IF()
      then simplifyIfStmtBranches(stmt.branches, stmt.source, Statement.makeIf, simplifyStatements, statements);

    case Statement.WHEN()
      algorithm
        stmt.branches := list(
          (SimplifyExp.simplify(Util.tuple21(b)), simplifyStatements(Util.tuple22(b)))
          for b in stmt.branches);
      then
        stmt :: statements;

    case Statement.NORETCALL()
      algorithm
        e := SimplifyExp.simplify(stmt.exp);

        if Expression.isCall(e) then
          stmt.exp := removeEmptyFunctionArguments(e);
          statements := stmt :: statements;
        end if;
      then
        statements;

    else stmt :: statements;
  end match;
end simplifyStatement;

function simplifyAssignment
  input Statement stmt;
  input output list<Statement> statements;
protected
  Expression lhs, rhs, rhs_exp;
  list<Expression> rhs_rest;
  Type ty;
  DAE.ElementSource src;
algorithm
  Statement.ASSIGNMENT(lhs = lhs, rhs = rhs, ty = ty, source = src) := stmt;
  ty := Type.mapDims(ty, simplifyDimension);

  if Type.isEmptyArray(ty) then
    return;
  end if;

  lhs := SimplifyExp.simplify(lhs);
  lhs := removeEmptyTupleElements(lhs);
  rhs := SimplifyExp.simplify(rhs);
  rhs := removeEmptyFunctionArguments(rhs);

  statements := match (lhs, rhs)
    case (Expression.TUPLE(), Expression.TUPLE())
      then simplifyTupleElement(lhs.elements, rhs.elements, ty, src, Statement.makeAssignment, statements);

    else Statement.ASSIGNMENT(lhs, rhs, ty, src) :: statements;
  end match;
end simplifyAssignment;

function simplifyTupleElement<ElementT>
  "Helper function to simplifyEqualityEquation/simplifyAssignment.
   Handles Expression.TUPLE() := Expression.TUPLE() assignments by splitting
   them into a separate assignment statement for each pair of tuple elements."
  input list<Expression> lhsTuple;
  input list<Expression> rhsTuple;
  input Type ty;
  input DAE.ElementSource src;
  input MakeElement makeFn;
  input output list<ElementT> statements;

  partial function MakeElement
    input Expression lhs;
    input Expression rhs;
    input Type ty;
    input DAE.ElementSource src;
    output ElementT element;
  end MakeElement;
protected
  Expression rhs;
  list<Expression> rest_rhs = rhsTuple;
  Type ety;
  list<Type> rest_ty;
algorithm
  Type.TUPLE(types = rest_ty) := ty;

  for lhs in lhsTuple loop
    rhs :: rest_rhs := rest_rhs;
    ety :: rest_ty := rest_ty;

    if not Expression.isWildCref(lhs) then
      statements := makeFn(lhs, rhs, ety, src) :: statements;
    end if;
  end for;
end simplifyTupleElement;

function removeEmptyTupleElements
  "Replaces tuple elements that has one or more zero dimension with _."
  input output Expression exp;
algorithm
  () := match exp
    local
      list<Type> tyl;

    case Expression.TUPLE(ty = Type.TUPLE(types = tyl))
      algorithm
        exp.elements := list(
          if Type.isEmptyArray(t) then Expression.CREF(t, ComponentRef.WILD()) else e
          threaded for e in exp.elements, t in tyl);
      then
        ();

    else ();
  end match;
end removeEmptyTupleElements;

function removeEmptyFunctionArguments
  input Expression exp;
  input Boolean isArg = false;
  output Expression outExp;
protected
  Boolean is_arg;
algorithm
  if isArg then
    () := match exp
      case Expression.CREF() guard Type.isEmptyArray(exp.ty)
        algorithm
          outExp := Expression.fillType(exp.ty, Expression.INTEGER(0));
          return;
        then
          ();

      else ();
    end match;
  end if;

  is_arg := isArg or Expression.isCall(exp);
  outExp := Expression.mapShallow(exp, function removeEmptyFunctionArguments(isArg = is_arg));
end removeEmptyFunctionArguments;

function simplifyIfEqBranches
  input list<Equation.Branch> branches;
  input DAE.ElementSource src;
  input output list<Equation> elements;
protected
  Expression cond;
  list<Equation> body;
  Variability var;
  list<Equation.Branch> accum = {};
algorithm
  for branch in branches loop
    accum := match branch
      case Equation.Branch.BRANCH(cond, var, body)
        algorithm
          cond := SimplifyExp.simplify(cond);

          // A branch with condition true will always be selected when encountered.
          if Expression.isTrue(cond) then
            if listEmpty(accum) then
              // If it's the first branch, remove the if and keep only the branch body.
              for eq in body loop
                elements := simplifyEquation(eq, elements);
              end for;
              return;
            else
              // Otherwise just discard the rest of the branches.
              accum := Equation.makeBranch(cond, simplifyEquations(body)) :: accum;
              elements := Equation.makeIf(listReverseInPlace(accum), src) :: elements;
              return;
            end if;
          elseif not Expression.isFalse(cond) then
            // Keep branches that are neither literal true or false.
            accum := Equation.makeBranch(cond, simplifyEquations(body)) :: accum;
          end if;
        then
          accum;

      case Equation.INVALID_BRANCH(branch =
          Equation.Branch.BRANCH(condition = cond, conditionVar = var))
        algorithm
          if var <= Variability.STRUCTURAL_PARAMETER then
            cond := Ceval.evalExp(cond);
          end if;

          // An invalid branch that can't be removed will trigger the errors
          // stored in it.
          if not Expression.isFalse(cond) then
            Equation.Branch.triggerErrors(branch);
          end if;
        then
          accum;

      else branch :: accum;
    end match;
  end for;

  if not listEmpty(accum) then
    elements := Equation.makeIf(listReverseInPlace(accum), src) :: elements;
  end if;
end simplifyIfEqBranches;

function simplifyIfStmtBranches<ElemT>
  input list<tuple<Expression, list<ElemT>>> branches;
  input DAE.ElementSource src;
  input MakeFunc makeFunc;
  input SimplifyFunc simplifyFunc;
  input output list<ElemT> elements;

  partial function MakeFunc
    input list<tuple<Expression, list<ElemT>>> branches;
    input DAE.ElementSource src;
    output ElemT element;
  end MakeFunc;

  partial function SimplifyFunc
    input output list<ElemT> elements;
  end SimplifyFunc;
protected
  Expression cond;
  list<ElemT> body;
  list<tuple<Expression, list<ElemT>>> accum = {};
algorithm
  for branch in branches loop
    (cond, body) := branch;
    cond := SimplifyExp.simplify(cond);

    // A branch with condition true will always be selected when encountered.
    if Expression.isTrue(cond) then
      if listEmpty(accum) then
        // If it's the first branch, remove the if and keep only the branch body.
        elements := listAppend(listReverse(simplifyFunc(body)), elements);
        return;
      else
        // Otherwise just discard the rest of the branches.
        accum := (cond, simplifyFunc(body)) :: accum;
        break;
      end if;
    elseif not Expression.isFalse(cond) then
      // Keep branches that are neither literal true or false.
      accum := (cond, simplifyFunc(body)) :: accum;
    end if;
  end for;

  if not listEmpty(accum) then
    elements := makeFunc(listReverseInPlace(accum), src) :: elements;
  end if;
end simplifyIfStmtBranches;

function simplifyFunction
  input Function func;
protected
  Class cls;
  Algorithm fn_body;
  Sections sections;
algorithm
  if not Function.isSimplified(func) then
    Function.markSimplified(func);
    Function.mapExp(func, SimplifyExp.simplify, mapBody = false);

    cls := InstNode.getClass(func.node);
    () := match cls
      case Class.INSTANCED_CLASS(sections = sections)
        algorithm
          () := match sections
            case Sections.SECTIONS(algorithms = {fn_body})
              algorithm
                fn_body.statements := simplifyStatements(fn_body.statements);
                sections.algorithms := {fn_body};
                cls.sections := sections;
                InstNode.updateClass(cls, func.node);
              then
                ();

            else ();
          end match;
        then
          ();

      else ();
    end match;

    for fn_der in func.derivatives loop
      for der_fn in Function.getCachedFuncs(fn_der.derivativeFn) loop
        simplifyFunction(der_fn);
      end for;
    end for;
  end if;
end simplifyFunction;

function combineBinaries
  "author: kabdelhak 09-2020
  Combines binaries for better handling in the backend.
  NOTE: does not do any other simplification
  e.g. BINARY(BINARY(2, /, y^2), *, BINARY(3, *, x))
   --> MULTARY({2, 3, x}, {y^2}, *)"
  input output FlatModel flatModel;
algorithm
  flatModel.variables := list(combineBinariesVar(var) for var in flatModel.variables);
  flatModel.equations := list(Equation.mapExp(eqn, SimplifyExp.combineBinaries) for eqn in flatModel.equations);
  flatModel.initialEquations := list(Equation.mapExp(eqn, SimplifyExp.combineBinaries) for eqn in flatModel.initialEquations);
  flatModel.algorithms := list(Algorithm.mapExp(alg, SimplifyExp.combineBinaries) for alg in flatModel.algorithms);
  flatModel.initialAlgorithms := list(Algorithm.mapExp(alg, SimplifyExp.combineBinaries) for alg in flatModel.initialAlgorithms);
end combineBinaries;

protected function combineBinariesVar
  input output Variable var;
algorithm
  var := match var
    local
      Binding binding;

    case Variable.VARIABLE(binding = binding as Binding.UNTYPED_BINDING()) algorithm
      binding.bindingExp := SimplifyExp.combineBinaries(binding.bindingExp);
      var.binding := binding;
    then var;

    case Variable.VARIABLE(binding = binding as Binding.TYPED_BINDING()) algorithm
      binding.bindingExp := SimplifyExp.combineBinaries(binding.bindingExp);
      var.binding := binding;
    then var;

    case Variable.VARIABLE(binding = binding as Binding.FLAT_BINDING()) algorithm
      binding.bindingExp := SimplifyExp.combineBinaries(binding.bindingExp);
      var.binding := binding;
    then var;

    case Variable.VARIABLE(binding = binding as Binding.CEVAL_BINDING()) algorithm
      binding.bindingExp := SimplifyExp.combineBinaries(binding.bindingExp);
      var.binding := binding;
    then var;

    else var;
  end match;
end combineBinariesVar;


annotation(__OpenModelica_Interface="frontend");
end NFSimplifyModel;
