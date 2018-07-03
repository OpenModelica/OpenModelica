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
import NFClass.Class;
import NFInstNode.InstNode;
import NFFunction.Function;
import Sections = NFSections;
import NFBinding.Binding;
import Variable = NFVariable;
import Algorithm = NFAlgorithm;

protected
import MetaModelica.Dangerous.*;
import ExecStat.execStat;
import SimplifyExp = NFSimplifyExp;
import NFPrefixes.Variability;
import Ceval = NFCeval;

public
function simplify
  input output FlatModel flatModel;
  input output FunctionTree functions;
algorithm
  flatModel.variables := list(simplifyVariable(v) for v in flatModel.variables);
  flatModel.equations := simplifyEquations(flatModel.equations);
  flatModel.initialEquations := simplifyEquations(flatModel.initialEquations);
  flatModel.algorithms := list(simplifyAlgorithm(a) for a in flatModel.algorithms);
  flatModel.initialAlgorithms := list(simplifyAlgorithm(a) for a in flatModel.initialAlgorithms);

  functions := FunctionTree.map(functions, simplifyFunction);

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
      Expression e;

    case Equation.EQUALITY()
      algorithm
        eq.lhs := removeEmptyTupleElements(SimplifyExp.simplify(eq.lhs));
        eq.rhs := removeEmptyFunctionArguments(SimplifyExp.simplify(eq.rhs));
      then
        eq :: equations;

    case Equation.ARRAY_EQUALITY()
      algorithm
        if not Type.isEmptyArray(eq.ty) then
          eq.rhs := removeEmptyFunctionArguments(SimplifyExp.simplify(eq.rhs));
          equations := eq :: equations;
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
      Expression e;

    case Statement.ASSIGNMENT()
      algorithm
        stmt.lhs := removeEmptyTupleElements(SimplifyExp.simplify(stmt.lhs));
        stmt.rhs := removeEmptyFunctionArguments(SimplifyExp.simplify(stmt.rhs));
      then
        stmt :: statements;

    case Statement.FOR(range = SOME(e))
      algorithm
        if not Type.isEmptyArray(Expression.typeOf(e)) then
          stmt.range := SimplifyExp.simplifyOpt(stmt.range);
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
          if var <= Variability.STRUCTURAL_PARAMETER then
            cond := Ceval.evalExp(cond);
          else
            cond := SimplifyExp.simplify(cond);
          end if;

          // A branch with condition true will always be selected when encountered.
          if Expression.isTrue(cond) then
            if listEmpty(accum) then
              // If it's the first branch, remove the if and keep only the branch body.
              elements := listAppend(simplifyEquations(body), elements);
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
        elements := listAppend(simplifyFunc(body), elements);
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
  input Absyn.Path name;
  input output Function func;
protected
  Class cls;
  Algorithm fn_body;
  Sections sections;
algorithm
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
end simplifyFunction;

annotation(__OpenModelica_Interface="frontend");
end NFSimplifyModel;
