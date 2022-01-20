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
import Class = NFClass;
import NFInstNode.InstNode;
import NFFunction.Function;
import Sections = NFSections;
import Binding = NFBinding;
import Variable = NFVariable;
import Algorithm = NFAlgorithm;
import NFEquation.Branch;
import Dimension = NFDimension;
import InstContext = NFInstContext;

protected
import MetaModelica.Dangerous.*;
import ExecStat.execStat;
import NFPrefixes.Variability;
import Ceval = NFCeval;
import Package = NFPackage;
import SimplifyExp = NFSimplifyExp;
import ErrorExt;
import Record = NFRecord;
import Flatten = NFFlatten;

public
function evaluate
  input output FlatModel flatModel;
algorithm
  flatModel.variables := list(evaluateVariable(v) for v in flatModel.variables);
  flatModel.equations := evaluateEquations(flatModel.equations);
  flatModel.initialEquations := evaluateEquations(flatModel.initialEquations);
  flatModel.algorithms := evaluateAlgorithms(flatModel.algorithms);
  flatModel.initialAlgorithms := evaluateAlgorithms(flatModel.initialAlgorithms);

  execStat(getInstanceName());
end evaluate;

function evaluateVariable
  input output Variable var;
protected
  Binding binding;
algorithm
  binding := evaluateBinding(var.binding, var.name,
    Variable.variability(var) <= Variability.STRUCTURAL_PARAMETER);

  if not referenceEq(binding, var.binding) then
    var.binding := binding;
  end if;

  var.typeAttributes := list(evaluateTypeAttribute(a, var.name) for a in var.typeAttributes);
  var.children := list(evaluateVariable(v) for v in var.children);
end evaluateVariable;

function evaluateBinding
  input output Binding binding;
  input ComponentRef prefix;
  input Boolean structural;
protected
  Expression exp, eexp;
  SourceInfo info;
algorithm
  if Binding.isBound(binding) then
    exp := Binding.getTypedExp(binding);

    if structural then
      eexp := Ceval.evalExp(exp, Ceval.EvalTarget.ATTRIBUTE(binding));
      eexp := Flatten.flattenExp(eexp, prefix);
    else
      info := Binding.getInfo(binding);
      eexp := evaluateExp(exp, info);
    end if;

    if not referenceEq(exp, eexp) then
      binding := Binding.setTypedExp(eexp, binding);
    end if;
  end if;
end evaluateBinding;

function evaluateTypeAttribute
  input output tuple<String, Binding> attribute;
  input ComponentRef prefix;
protected
  String name;
  Binding binding, sbinding;
  Boolean structural;
algorithm
  (name, binding) := attribute;
  structural := name == "fixed" or name == "stateSelect";
  sbinding := evaluateBinding(binding, prefix, structural);

  if not referenceEq(binding, sbinding) then
    attribute := (name, sbinding);
  end if;
end evaluateTypeAttribute;

function evaluateExp
  input Expression exp;
  input SourceInfo info;
  output Expression outExp;
algorithm
  outExp := evaluateExpTraverser(exp, info);
end evaluateExp;

function evaluateExpOpt
  input Option<Expression> exp;
  input SourceInfo info;
  output Option<Expression> outExp;
protected
  Expression e;
algorithm
  outExp := match exp
    case SOME(e) then SOME(evaluateExp(e, info));
    else exp;
  end match;
end evaluateExpOpt;

function evaluateExpTraverser
  input Expression exp;
  input SourceInfo info;
  input Boolean changed = false;
  output Expression outExp;
  output Boolean outChanged;
protected
  Expression e;
  ComponentRef cref;
  Type ty, ty2;
  Variability var;
algorithm
  outExp := match exp
    case Expression.CREF()
      algorithm
        (outExp as Expression.CREF(cref = cref, ty = ty), outChanged) :=
          Expression.mapFoldShallow(exp,
            function evaluateExpTraverser(info = info), false);

        if ComponentRef.nodeVariability(cref) <= Variability.STRUCTURAL_PARAMETER then
          // Evaluate all constants and structural parameters.
          outExp := Ceval.evalCref(cref, outExp, Ceval.EvalTarget.IGNORE_ERRORS(), evalSubscripts = false);
          outExp := Flatten.flattenExp(outExp, cref);
          outChanged := true;
        elseif outChanged then
          ty := ComponentRef.getSubscriptedType(cref);
        end if;

        ty2 := evaluateType(ty, info);
        if not referenceEq(ty, ty2) then
          outExp := Expression.setType(ty2, outExp);
        end if;
      then
        outExp;

    case Expression.IF()
      algorithm
        (outExp, outChanged) := evaluateIfExp(exp, info);
      then
        outExp;

    // TODO: The return type of calls can have dimensions that reference
    //       function parameters, and thus can't be evaluated. This should be
    //       fixed so that the return type reference the input arguments instead.
    case Expression.CALL()
      algorithm
        (outExp, outChanged) := Expression.mapFoldShallow(exp,
          function evaluateExpTraverser(info = info), false);
      then
        outExp;

    case Expression.SIZE()
      then Expression.SIZE(exp.exp, evaluateExpOpt(exp.dimIndex, info));

    case Expression.RANGE()
      algorithm
        (outExp, outChanged) := Expression.mapFoldShallow(exp,
          function evaluateExpTraverser(info = info), false);

        // If anything in a range is evaluated its better to just retype it
        // rather than evaluating the type, since it's usually faster and gives
        // better results in some cases.
        if outChanged then
          outExp := Expression.retype(outExp);
        end if;
      then
        outExp;

    else
      algorithm
        (outExp, outChanged) := Expression.mapFoldShallow(exp,
          function evaluateExpTraverser(info = info), false);

        ty := Expression.typeOf(outExp);
        ty2 := evaluateType(ty, info);
      then
        if referenceEq(ty, ty2) then outExp else Expression.setType(ty2, outExp);
  end match;

  outChanged := changed or outChanged;
end evaluateExpTraverser;

function evaluateType
  input output Type ty;
  input SourceInfo info;
algorithm
  ty := match ty
    case Type.ARRAY()
      algorithm
        ty.dimensions := list(evaluateDimension(d, info) for d in ty.dimensions);
      then
        ty;

    case Type.CONDITIONAL_ARRAY()
      then Type.simplifyConditionalArray(ty);

    else ty;
  end match;
end evaluateType;

function evaluateDimension
  input Dimension dim;
  input SourceInfo info;
  output Dimension outDim;
algorithm
  outDim := match dim
    local
      Expression e;

    case Dimension.EXP()
      algorithm
        e := evaluateExp(dim.exp, info);
      then
        if referenceEq(e, dim.exp) then dim else Dimension.fromExp(e, dim.var);

    else dim;
  end match;
end evaluateDimension;

function evaluateIfExp
  "Evaluates constants in an if-expression. This is done by first checking if
   the condition can be evaluated, in which case branch selection is done to
   avoid issues that can arise when evaluating constants in branches that are
   expected to be discarded. This function also makes sure that if-expressions
   with branches that have different dimensions are resolved to the correct
   branch based on the type matching in earlier stages of the compilation."
  input Expression exp;
  input SourceInfo info;
  output Expression outExp;
  output Boolean outChanged;
protected
  Type ty;
  Expression cond, tb, fb;
  Boolean c1, c2;
  Type.Branch matched_branch;
algorithm
  Expression.IF(ty, cond, tb, fb) := exp;
  (cond, outChanged) := evaluateExpTraverser(cond, info);

  // Simplify the condition in case it can be reduced to a literal value.
  cond := SimplifyExp.simplify(cond);

  if Type.isConditionalArray(ty) then
    (outExp, outChanged) := match cond
      case Expression.BOOLEAN()
        algorithm
          if not Type.isMatchedBranch(cond.value, ty) then
            // The branch with the incompatible dimensions was chosen, print an error and fail.
            (tb, fb) := Util.swap(cond.value, fb, tb);
            Error.addSourceMessage(Error.ARRAY_DIMENSION_MISMATCH,
              {Expression.toString(tb), Type.toString(Expression.typeOf(tb)),
               Dimension.toStringList(Type.arrayDims(Expression.typeOf(fb)), brackets = false)}, info);
            fail();
          end if;

          outExp := evaluateExpTraverser(if cond.value then tb else fb, info);
        then
          (outExp, true);

      else
        algorithm
          // The condition could not be evaluated to a literal. This is required
          // if the branches have different dimensions, so print an error and fail.
          Error.addSourceMessage(Error.TYPE_MISMATCH_IF_EXP,
            {"", Expression.toString(tb), Type.toString(Expression.typeOf(tb)),
                 Expression.toString(fb), Type.toString(Expression.typeOf(fb))}, info);
        then
          fail();
    end match;
  else
    (outExp, outChanged) := match cond
      // Only evaluate constants in and return one of the branches if the
      // condition is a literal boolean value.
      case Expression.BOOLEAN()
        algorithm
          outExp := evaluateExpTraverser(if cond.value then tb else fb, info);
        then
          (outExp, true);

      // Otherwise evaluate constants in both branches and return the whole
      // if-expression.
      else
        algorithm
          (tb, c1) := evaluateExpTraverser(tb, info);
          (fb, c2) := evaluateExpTraverser(fb, info);
        then
          (Expression.IF(ty, cond, tb, fb), outChanged or c1 or c2);

    end match;
  end if;
end evaluateIfExp;

function evaluateEquations
  input list<Equation> eql;
  output list<Equation> outEql = list(evaluateEquation(e) for e in eql);
end evaluateEquations;

function evaluateEquation
  input output Equation eq;
protected
  SourceInfo info = Equation.info(eq);
algorithm
  eq := match eq
    local
      Expression e1, e2, e3;
      Type ty;

    case Equation.EQUALITY()
      algorithm
        ty := Type.mapDims(eq.ty, function evaluateDimension(info = info));
        e1 := evaluateExp(eq.lhs, info);
        e2 := evaluateExp(eq.rhs, info);
      then
        Equation.EQUALITY(e1, e2, ty, eq.source);

    case Equation.ARRAY_EQUALITY()
      algorithm
        ty := Type.mapDims(eq.ty, function evaluateDimension(info = info));
        e2 := evaluateExp(eq.rhs, info);
      then
        Equation.ARRAY_EQUALITY(eq.lhs, e2, ty, eq.source);

    case Equation.FOR()
      algorithm
        eq.range := Util.applyOption(eq.range,
          function evaluateExp(info = info));
        eq.body := evaluateEquations(eq.body);
      then
        eq;

    case Equation.IF()
      algorithm
        eq.branches := list(evaluateEqBranch(b, info) for b in eq.branches);
      then
        eq;

    case Equation.WHEN()
      algorithm
        eq.branches := list(evaluateEqBranch(b, info) for b in eq.branches);
      then
        eq;

    case Equation.ASSERT()
      algorithm
        e1 := evaluateExp(eq.condition, info);
        e2 := evaluateExp(eq.message, info);
        e3 := evaluateExp(eq.level, info);
      then
        Equation.ASSERT(e1, e2, e3, eq.source);

    case Equation.TERMINATE()
      algorithm
        eq.message := evaluateExp(eq.message, info);
      then
        eq;

    case Equation.REINIT()
      algorithm
        eq.reinitExp := evaluateExp(eq.reinitExp, info);
      then
        eq;

    case Equation.NORETCALL()
      algorithm
        eq.exp := evaluateExp(eq.exp, info);
      then
        eq;

    else eq;
  end match;
end evaluateEquation;

function evaluateEqBranch
  input Branch branch;
  input SourceInfo info;
  output Branch outBranch;
algorithm
  outBranch := match branch
    local
      Expression condition;
      list<Equation> body;

    case Branch.BRANCH(condition = condition, body = body)
      algorithm
        condition := evaluateExp(condition, info);
        body := evaluateEquations(body);
      then
        Branch.BRANCH(condition, branch.conditionVar, body);

    else branch;
  end match;
end evaluateEqBranch;

function evaluateAlgorithms
  input list<Algorithm> algs;
  output list<Algorithm> outAlgs = list(evaluateAlgorithm(a) for a in algs);
end evaluateAlgorithms;

function evaluateAlgorithm
  input output Algorithm alg;
algorithm
  alg.statements := evaluateStatements(alg.statements);
end evaluateAlgorithm;

function evaluateStatements
  input list<Statement> stmts;
  output list<Statement> outStmts = list(evaluateStatement(s) for s in stmts);
end evaluateStatements;

function evaluateStatement
  input output Statement stmt;
protected
  SourceInfo info = Statement.info(stmt);
algorithm
  stmt := match stmt
    local
      Expression e1, e2, e3;
      Type ty;

    case Statement.ASSIGNMENT()
      algorithm
        ty := Type.mapDims(stmt.ty, function evaluateDimension(info = info));
        e1 := evaluateExp(stmt.lhs, info);
        e2 := evaluateExp(stmt.rhs, info);
      then
        Statement.ASSIGNMENT(e1, e2, ty, stmt.source);

    case Statement.FOR()
      algorithm
        stmt.range := Util.applyOption(stmt.range,
          function evaluateExp(info = info));
        stmt.body := evaluateStatements(stmt.body);
      then
        stmt;

    case Statement.IF()
      algorithm
        stmt.branches := list(evaluateStmtBranch(b, info) for b in stmt.branches);
      then
        stmt;

    case Statement.WHEN()
      algorithm
        stmt.branches := list(evaluateStmtBranch(b, info) for b in stmt.branches);
      then
        stmt;

    case Statement.ASSERT()
      algorithm
        e1 := evaluateExp(stmt.condition, info);
        e2 := evaluateExp(stmt.message, info);
        e3 := evaluateExp(stmt.level, info);
      then
        Statement.ASSERT(e1, e2, e3, stmt.source);

    case Statement.TERMINATE()
      algorithm
        stmt.message := evaluateExp(stmt.message, info);
      then
        stmt;

    case Statement.NORETCALL()
      algorithm
        stmt.exp := evaluateExp(stmt.exp, info);
      then
        stmt;

    case Statement.WHILE()
      algorithm
        stmt.condition := evaluateExp(stmt.condition, info);
        stmt.body := evaluateStatements(stmt.body);
      then
        stmt;

    else stmt;
  end match;
end evaluateStatement;

function evaluateStmtBranch
  input tuple<Expression, list<Statement>> branch;
  input SourceInfo info;
  output tuple<Expression, list<Statement>> outBranch;
protected
  Expression cond;
  list<Statement> body;
algorithm
  (cond, body) := branch;
  cond := evaluateExp(cond, info);
  body := evaluateStatements(body);
  outBranch := (cond, body);
end evaluateStmtBranch;

function evaluateFunction
  input output Function func;
protected
  Class cls;
  Algorithm fn_body;
  Sections sections;
  Boolean is_con;
algorithm
  if not Function.isEvaluated(func) then
    Function.markEvaluated(func);
    is_con := Function.isDefaultRecordConstructor(func);

    func := Function.mapExp(func,
      function evaluateFuncExp(fnNode = func.node, evaluateAll = is_con),
      function evaluateFuncExp(fnNode = func.node, evaluateAll = true));

    if is_con then
      Record.checkLocalFieldOrder(func.locals, func.node, InstNode.info(func.node));
    end if;

    for fn_der in func.derivatives loop
      for der_fn in Function.getCachedFuncs(fn_der.derivativeFn) loop
        evaluateFunction(der_fn);
      end for;
    end for;
  end if;
end evaluateFunction;

function evaluateFuncExp
  input Expression exp;
  input InstNode fnNode;
  input Boolean evaluateAll;
  output Expression outExp;
algorithm
  outExp := evaluateFuncExpTraverser(exp, fnNode, evaluateAll, false);
end evaluateFuncExp;

function evaluateFuncExpTraverser
  input Expression exp;
  input InstNode fnNode;
  input Boolean evaluateAll;
  input Boolean changed;
  output Expression outExp;
  output Boolean outChanged;
protected
  Expression e;
algorithm
  (e, outChanged) := Expression.mapFoldShallow(exp,
    function evaluateFuncExpTraverser(fnNode = fnNode, evaluateAll = evaluateAll), false);

  outExp := match e
    case Expression.CREF()
      algorithm
        if evaluateAll or not isLocalFunctionVariable(e.cref, fnNode) then
          ErrorExt.setCheckpoint(getInstanceName());
          try
            outExp := Ceval.evalCref(e.cref, e, Ceval.EvalTarget.IGNORE_ERRORS(), evalSubscripts = false);
          else
            outExp := e;
          end try;
          ErrorExt.rollBack(getInstanceName());
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

function isLocalFunctionVariable
  input ComponentRef cref;
  input InstNode fnNode;
  output Boolean res;
protected
  InstNode node;
  list<Function> fnl;
  Function fn;
algorithm
  if ComponentRef.isPackageConstant(cref) then
    res := false;
  elseif ComponentRef.nodeVariability(cref) <= Variability.PARAMETER and ComponentRef.isCref(cref) then
    node := InstNode.instanceParent(ComponentRef.node(ComponentRef.last(cref)));

    if InstNode.isClass(node) then
      fnl := Function.getCachedFuncs(node);

      if listEmpty(fnl) then
        res := false;
      else
        fn := listHead(fnl);
        res := InstNode.refEqual(fnNode, fn.node);
      end if;
    else
      res := false;
    end if;
  else
    res := true;
  end if;
end isLocalFunctionVariable;

annotation(__OpenModelica_Interface="frontend");
end NFEvalConstants;
