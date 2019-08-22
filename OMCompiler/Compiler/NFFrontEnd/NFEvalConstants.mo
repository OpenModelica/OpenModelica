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

encapsulated package NFEvalConstants

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
import NFCall.Call;
import NFEquation.Branch;
import Dimension = NFDimension;

protected
import MetaModelica.Dangerous.*;
import ExecStat.execStat;
import NFPrefixes.Variability;
import Ceval = NFCeval;
import Package = NFPackage;

public
function evaluate
  input output FlatModel flatModel;
protected
  Variability const_var = Variability.STRUCTURAL_PARAMETER;
algorithm
  flatModel.variables := list(evaluateVariable(v, const_var) for v in flatModel.variables);
  flatModel.equations := evaluateEquations(flatModel.equations, const_var);
  flatModel.initialEquations := evaluateEquations(flatModel.initialEquations, const_var);
  flatModel.algorithms := evaluateAlgorithms(flatModel.algorithms, const_var);
  flatModel.initialAlgorithms := evaluateAlgorithms(flatModel.initialAlgorithms, const_var);

  execStat(getInstanceName());
end evaluate;

function evaluateVariable
  input output Variable var;
  input Variability constVariability;
protected
  Binding binding;
algorithm
  binding := evaluateBinding(var.binding,
    Variable.variability(var) <= constVariability, constVariability);

  if not referenceEq(binding, var.binding) then
    var.binding := binding;
  end if;

  var.typeAttributes := list(evaluateTypeAttribute(a, Variability.STRUCTURAL_PARAMETER) for a in var.typeAttributes);
end evaluateVariable;

function evaluateBinding
  input output Binding binding;
  input Boolean structural;
  input Variability constVariability;
protected
  Expression exp, eexp;
algorithm
  if Binding.isBound(binding) then
    exp := Binding.getTypedExp(binding);

    if structural then
      eexp := Ceval.evalExp(exp, Ceval.EvalTarget.ATTRIBUTE(binding));
    else
      eexp := evaluateExp(exp, constVariability);
    end if;

    if not referenceEq(exp, eexp) then
      binding := Binding.setTypedExp(eexp, binding);
    end if;
  end if;
end evaluateBinding;

function evaluateTypeAttribute
  input output tuple<String, Binding> attribute;
  input Variability constVariability;
protected
  String name;
  Binding binding, sbinding;
  Boolean structural;
algorithm
  (name, binding) := attribute;
  structural := name == "fixed" or name == "stateSelect";
  sbinding := evaluateBinding(binding, structural, constVariability);

  if not referenceEq(binding, sbinding) then
    attribute := (name, sbinding);
  end if;
end evaluateTypeAttribute;

function evaluateExp
  input Expression exp;
  input Variability constVariability;
  output Expression outExp;
algorithm
  outExp := evaluateExpTraverser(exp, constVariability, false);
end evaluateExp;

function evaluateExpTraverser
  input Expression exp;
  input Variability constVariability;
  input Boolean changed;
  output Expression outExp;
  output Boolean outChanged;
protected
  Expression e;
  ComponentRef cref;
  Type ty;
  Variability var;
algorithm
  outExp := match exp
    case Expression.CREF()
      algorithm
        (outExp as Expression.CREF(cref = cref, ty = ty), outChanged) :=
          Expression.mapFoldShallow(exp,
            function evaluateExpTraverser(constVariability = constVariability), false);

        // Evaluate constants and structural parameters.
        if ComponentRef.nodeVariability(cref) <= constVariability then
          // Evaluate all constants and structural parameters.
          outExp := Ceval.evalCref(cref, outExp, Ceval.EvalTarget.IGNORE_ERRORS(), evalSubscripts = false);
          outChanged := true;
        elseif outChanged then
          // If the cref's subscripts changed, recalculate its type.
          outExp := Expression.CREF(ComponentRef.getSubscriptedType(cref), cref);
        end if;
      then
        outExp;

    else
      algorithm
        (outExp, outChanged) := Expression.mapFoldShallow(exp,
          function evaluateExpTraverser(constVariability = constVariability), false);
      then
        if outChanged then Expression.retype(outExp) else outExp;
  end match;

  outChanged := changed or outChanged;
end evaluateExpTraverser;

function evaluateDimension
  input Dimension dim;
  output Dimension outDim;
algorithm
  outDim := match dim
    local
      Expression e;

    case Dimension.EXP()
      algorithm
        e := evaluateExp(dim.exp, constVariability = Variability.STRUCTURAL_PARAMETER);
      then
        if referenceEq(e, dim.exp) then dim else Dimension.fromExp(e, dim.var);

    else dim;
  end match;
end evaluateDimension;

function evaluateEquations
  input list<Equation> eql;
  input Variability constVariability;
  output list<Equation> outEql = list(evaluateEquation(e, constVariability) for e in eql);
end evaluateEquations;

function evaluateEquation
  input output Equation eq;
  input Variability constVariability;
algorithm
  eq := match eq
    local
      Expression e1, e2, e3;
      Type ty;

    case Equation.EQUALITY()
      algorithm
        ty := Type.mapDims(eq.ty, evaluateDimension);
        e1 := evaluateExp(eq.lhs, constVariability);
        e2 := evaluateExp(eq.rhs, constVariability);
      then
        Equation.EQUALITY(e1, e2, ty, eq.source);

    case Equation.ARRAY_EQUALITY()
      algorithm
        ty := Type.mapDims(eq.ty, evaluateDimension);
        e2 := evaluateExp(eq.rhs, constVariability);
      then
        Equation.ARRAY_EQUALITY(eq.lhs, e2, ty, eq.source);

    case Equation.FOR()
      algorithm
        eq.range := Util.applyOption(eq.range,
          function evaluateExp(constVariability = constVariability));
        eq.body := evaluateEquations(eq.body, constVariability);
      then
        eq;

    case Equation.IF()
      algorithm
        eq.branches := list(evaluateEqBranch(b, constVariability) for b in eq.branches);
      then
        eq;

    case Equation.WHEN()
      algorithm
        eq.branches := list(evaluateEqBranch(b, constVariability) for b in eq.branches);
      then
        eq;

    case Equation.ASSERT()
      algorithm
        e1 := evaluateExp(eq.condition, constVariability);
        e2 := evaluateExp(eq.message, constVariability);
        e3 := evaluateExp(eq.level, constVariability);
      then
        Equation.ASSERT(e1, e2, e3, eq.source);

    case Equation.TERMINATE()
      algorithm
        eq.message := evaluateExp(eq.message, constVariability);
      then
        eq;

    case Equation.REINIT()
      algorithm
        eq.reinitExp := evaluateExp(eq.reinitExp, constVariability);
      then
        eq;

    case Equation.NORETCALL()
      algorithm
        eq.exp := evaluateExp(eq.exp, constVariability);
      then
        eq;

    else eq;
  end match;
end evaluateEquation;

function evaluateEqBranch
  input Branch branch;
  input Variability constVariability;
  output Branch outBranch;
algorithm
  outBranch := match branch
    local
      Expression condition;
      list<Equation> body;

    case Branch.BRANCH(condition = condition, body = body)
      algorithm
        condition := evaluateExp(condition, constVariability = Variability.STRUCTURAL_PARAMETER);
        body := evaluateEquations(body, constVariability);
      then
        Branch.BRANCH(condition, branch.conditionVar, body);

    else branch;
  end match;
end evaluateEqBranch;

function evaluateAlgorithms
  input list<Algorithm> algs;
  input Variability constVariability;
  output list<Algorithm> outAlgs = list(evaluateAlgorithm(a, constVariability) for a in algs);
end evaluateAlgorithms;

function evaluateAlgorithm
  input output Algorithm alg;
  input Variability constVariability;
algorithm
  alg.statements := evaluateStatements(alg.statements, constVariability);
end evaluateAlgorithm;

function evaluateStatements
  input list<Statement> stmts;
  input Variability constVariability;
  output list<Statement> outStmts = list(evaluateStatement(s, constVariability) for s in stmts);
end evaluateStatements;

function evaluateStatement
  input output Statement stmt;
  input Variability constVariability;
algorithm
  stmt := match stmt
    local
      Expression e1, e2, e3;
      Type ty;

    case Statement.ASSIGNMENT()
      algorithm
        ty := Type.mapDims(stmt.ty, evaluateDimension);
        e1 := evaluateExp(stmt.lhs, constVariability);
        e2 := evaluateExp(stmt.rhs, constVariability);
      then
        Statement.ASSIGNMENT(e1, e2, ty, stmt.source);

    case Statement.FOR()
      algorithm
        stmt.range := Util.applyOption(stmt.range,
          function evaluateExp(constVariability = constVariability));
        stmt.body := evaluateStatements(stmt.body, constVariability);
      then
        stmt;

    case Statement.IF()
      algorithm
        stmt.branches := list(evaluateStmtBranch(b, constVariability) for b in stmt.branches);
      then
        stmt;

    case Statement.WHEN()
      algorithm
        stmt.branches := list(evaluateStmtBranch(b, constVariability) for b in stmt.branches);
      then
        stmt;

    case Statement.ASSERT()
      algorithm
        e1 := evaluateExp(stmt.condition, constVariability);
        e2 := evaluateExp(stmt.message, constVariability);
        e3 := evaluateExp(stmt.level, constVariability);
      then
        Statement.ASSERT(e1, e2, e3, stmt.source);

    case Statement.TERMINATE()
      algorithm
        stmt.message := evaluateExp(stmt.message, constVariability);
      then
        stmt;

    case Statement.NORETCALL()
      algorithm
        stmt.exp := evaluateExp(stmt.exp, constVariability);
      then
        stmt;

    case Statement.WHILE()
      algorithm
        stmt.condition := evaluateExp(stmt.condition, constVariability);
        stmt.body := evaluateStatements(stmt.body, constVariability);
      then
        stmt;

    else stmt;
  end match;
end evaluateStatement;

function evaluateStmtBranch
  input tuple<Expression, list<Statement>> branch;
  input Variability constVariability;
  output tuple<Expression, list<Statement>> outBranch;
protected
  Expression cond;
  list<Statement> body;
algorithm
  (cond, body) := branch;
  cond := evaluateExp(cond, constVariability = Variability.STRUCTURAL_PARAMETER);
  body := evaluateStatements(body, constVariability);
  outBranch := (cond, body);
end evaluateStmtBranch;

function evaluateFunction
  input output Function func;
protected
  Class cls;
  Algorithm fn_body;
  Sections sections;
algorithm
  if not Function.isEvaluated(func) then
    Function.markEvaluated(func);
    func := Function.mapExp(func, evaluateFuncExp);

    for fn_der in func.derivatives loop
      for der_fn in Function.getCachedFuncs(fn_der.derivativeFn) loop
        evaluateFunction(der_fn);
      end for;
    end for;
  end if;
end evaluateFunction;

function evaluateFuncExp
  input Expression exp;
  output Expression outExp;
algorithm
  outExp := evaluateFuncExpTraverser(exp, false);
end evaluateFuncExp;

function evaluateFuncExpTraverser
  input Expression exp;
  input Boolean changed;
  output Expression outExp;
  output Boolean outChanged;
protected
  Expression e;
algorithm
  (e, outChanged) := Expression.mapFoldShallow(exp, evaluateFuncExpTraverser, false);

  outExp := match e
    case Expression.CREF()
      algorithm
        if ComponentRef.isPackageConstant(e.cref) then
          outExp := Ceval.evalCref(e.cref, e, Ceval.EvalTarget.IGNORE_ERRORS(), evalSubscripts = false);
          outChanged := true;
        elseif outChanged then
          // If the cref's subscripts changed, recalculate its type.
          outExp := Expression.CREF(ComponentRef.getSubscriptedType(e.cref), e.cref);
        else
          outExp := e;
        end if;
      then
        outExp;

    else if outChanged then Expression.retype(e) else e;
  end match;

  outChanged := changed or outChanged;
end evaluateFuncExpTraverser;

annotation(__OpenModelica_Interface="frontend");
end NFEvalConstants;
