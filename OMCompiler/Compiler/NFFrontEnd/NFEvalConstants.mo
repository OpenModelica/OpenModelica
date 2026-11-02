/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
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
  import NFInstNode;
import NFFunction.Function;
import Sections = NFSections;
import Binding = NFBinding;
import Variable = NFVariable;
import Algorithm = NFAlgorithm;
import NFEquation.Branch;
import Dimension = NFDimension;
import InstContext = NFInstContext;
import Component = NFComponent;
import NFClassTree.ClassTree;

protected
import MetaModelica.Dangerous.*;
import ExecStat.execStat;
import ElementSource;
import Util;
import NFPrefixes.Variability;
import Ceval = NFCeval;
import Package = NFPackage;
import SimplifyExp = NFSimplifyExp;
import ErrorExt;
import Record = NFRecord;
import Flatten = NFFlatten;
import AbsynUtil;
import Error;
import Flags;
import Graph;
import List;
import UnorderedMap;
import UnorderedSet;
import SCodeUtil;
import Structural = NFStructural;

public

uniontype EvalSettings
  record SETTINGS
    Boolean scalarize;
  end SETTINGS;
end EvalSettings;

function evaluate
  input output FlatModel flatModel;
  input InstContext.Type context;
protected
  EvalSettings settings;
  SourceInfo info = ElementSource.getInfo(flatModel.source);
algorithm
  settings := EvalSettings.SETTINGS(
    Flags.isSet(Flags.NF_SCALARIZE)
  );

  flatModel.variables := list(evaluateVariable(v, context, settings) for v in flatModel.variables);
  flatModel.equations := evaluateEquations(flatModel.equations);
  flatModel.initialEquations := evaluateEquations(flatModel.initialEquations);
  flatModel.algorithms := evaluateAlgorithms(flatModel.algorithms);
  flatModel.initialAlgorithms := evaluateAlgorithms(flatModel.initialAlgorithms);
  flatModel.constraints := list(evaluateExp(e, info) for e in flatModel.constraints);
  flatModel.optimizationAttributes := list(Util.applyTuple22(a, function evaluateExp(info = info))
    for a in flatModel.optimizationAttributes);

  execStat(getInstanceName());
end evaluate;

function checkBindingCycles
  "Checks that the bindings of parameters are acyclic, MLS 3.7 section 4.4.4.
   Cycles are first broken where possible by evaluating the conditions of
   if-expressions that only depend on parameters outside the cycle, as the
   specification allows, and any remaining cycle is an error. Must be called
   before evaluate, which then evaluates the parameters that were marked as
   structural to break a cycle, and which reports cycles of constants and
   structural parameters itself."
  input output FlatModel flatModel;
protected
  UnorderedMap<ComponentRef, Variable> vars;
  list<list<ComponentRef>> cycles;
  Boolean changed;
  Variable var;
algorithm
  // Merging puts acyclic bindings of different components into one array
  // binding that refers to its own elements.
  if Flags.isSet(Flags.MERGE_COMPONENTS) then
    return;
  end if;

  vars := UnorderedMap.new<Variable>(ComponentRef.hash, ComponentRef.isEqual);

  for v in flatModel.variables loop
    if Variable.variability(v) >= Variability.PARAMETER and
       Variable.variability(v) <= Variability.NON_STRUCTURAL_PARAMETER and
       Binding.isBound(v.binding) then
      UnorderedMap.add(v.name, v, vars);
    end if;
  end for;

  cycles := findBindingCycles(vars);

  if listEmpty(cycles) then
    return;
  end if;

  changed := breakBindingCycles(cycles, vars);

  if changed then
    flatModel.variables := list(Flatten.updateVariability(UnorderedMap.getOrDefault(v.name, vars, v))
      for v in flatModel.variables);
    cycles := findBindingCycles(vars);
  end if;

  if not listEmpty(cycles) and not Flags.isSet(Flags.IGNORE_CYCLES) then
    var := UnorderedMap.getOrFail(listHead(listHead(cycles)), vars);
    Error.addSourceMessage(Error.CIRCULAR_COMPONENTS,
      {AbsynUtil.pathString(flatModel.name),
       stringDelimitList(list(List.toString(c, ComponentRef.toString) for c in cycles), ", ")},
      var.info);
    fail();
  end if;
end checkBindingCycles;

function findBindingCycles
  input UnorderedMap<ComponentRef, Variable> vars;
  output list<list<ComponentRef>> cycles = {};
protected
  array<ComponentRef> names = listArray(UnorderedMap.keyList(vars));
  Integer n = arrayLength(names), j;
  UnorderedMap<ComponentRef, Integer> index;
  array<list<ComponentRef>> deps;
  array<list<Integer>> dependents;
  array<Integer> counts;
  list<Integer> queue = {};
  list<tuple<ComponentRef, list<ComponentRef>>> remaining = {};
algorithm
  index := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual, n);
  for i in 1:n loop
    UnorderedMap.add(names[i], i, index);
  end for;

  deps := arrayCreate(n, {});
  dependents := arrayCreate(n, {});
  counts := arrayCreate(n, 0);

  for i in 1:n loop
    deps[i] := bindingDependencies(names[i], vars);
    counts[i] := listLength(deps[i]);

    for d in deps[i] loop
      j := UnorderedMap.getOrFail(d, index);
      dependents[j] := i :: dependents[j];
    end for;

    if counts[i] == 0 then
      queue := i :: queue;
    end if;
  end for;

  // Remove the variables that don't depend on any remaining variable until
  // only the cycles, and the variables that depend on them, remain.
  while not listEmpty(queue) loop
    j :: queue := queue;

    for d in dependents[j] loop
      counts[d] := counts[d] - 1;

      if counts[d] == 0 then
        queue := d :: queue;
      end if;
    end for;
  end while;

  for i in 1:n loop
    if counts[i] > 0 then
      remaining := (names[i], list(d for d guard counts[UnorderedMap.getOrFail(d, index)] > 0 in deps[i])) :: remaining;
    end if;
  end for;

  if not listEmpty(remaining) then
    cycles := Graph.findCycles(remaining, ComponentRef.isEqual);
  end if;
end findBindingCycles;

function bindingDependencies
  "Returns the constants and parameters that the binding of a variable depends on."
  input ComponentRef name;
  input UnorderedMap<ComponentRef, Variable> vars;
  output list<ComponentRef> deps;
protected
  UnorderedSet<ComponentRef> dep_set;
  Variable var = UnorderedMap.getOrFail(name, vars);
algorithm
  dep_set := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
  Expression.fold(Binding.getTypedExp(var.binding),
    function collectBindingDependency(vars = vars, deps = dep_set), 0);
  deps := UnorderedSet.toList(dep_set);
end bindingDependencies;

function collectBindingDependency
  input Expression exp;
  input UnorderedMap<ComponentRef, Variable> vars;
  input UnorderedSet<ComponentRef> deps;
  input output Integer dummy;
protected
  ComponentRef cref;
algorithm
  () := match exp
    case Expression.CREF()
      algorithm
        cref := ComponentRef.stripSubscriptsAll(exp.cref);

        if UnorderedMap.contains(cref, vars) then
          UnorderedSet.add(cref, deps);
        end if;
      then
        ();

    else ();
  end match;
end collectBindingDependency;

function breakBindingCycles
  "Selects the branch of if-expressions in the bindings of the variables in the
   given cycles, if the condition only depends on variables outside the cycles
   and can be evaluated. The parameters in such conditions are marked as
   structural, since the cycle would otherwise come back if they were changed.
   Returns true if any binding was changed."
  input list<list<ComponentRef>> cycles;
  input UnorderedMap<ComponentRef, Variable> vars;
  output Boolean changed = false;
protected
  UnorderedSet<ComponentRef> cycle_vars;
  Variable var;
  Expression exp, new_exp;
algorithm
  cycle_vars := UnorderedSet.fromList(List.flatten(cycles), ComponentRef.hash, ComponentRef.isEqual);

  for name in UnorderedSet.toList(cycle_vars) loop
    var := UnorderedMap.getOrFail(name, vars);
    exp := Binding.getTypedExp(var.binding);
    new_exp := Expression.map(exp,
      function selectEvaluableBranch(vars = vars, cycleVars = cycle_vars));

    if not referenceEq(exp, new_exp) then
      var.binding := Binding.setTypedExp(new_exp, var.binding);
      UnorderedMap.add(name, var, vars);
      changed := true;
    end if;
  end for;
end breakBindingCycles;

function selectEvaluableBranch
  input Expression exp;
  input UnorderedMap<ComponentRef, Variable> vars;
  input UnorderedSet<ComponentRef> cycleVars;
  output Expression outExp = exp;
protected
  Expression cond;
algorithm
  () := match exp
    case Expression.IF()
      guard Expression.fold(exp.condition,
              function isEvaluableConditionCref(vars = vars, cycleVars = cycleVars), true)
      algorithm
        // Marked before the evaluation replaces the bindings with their values.
        Structural.markExp(exp.condition);
        cond := Ceval.tryEvalExp(exp.condition);

        if Expression.isBoolean(cond) then
          outExp := if Expression.isTrue(cond) then exp.trueBranch else exp.falseBranch;
        end if;
      then
        ();

    else ();
  end match;
end selectEvaluableBranch;

function isEvaluableConditionCref
  "Only constants and parameters that are or can be structural, outside the
   cycles, may be used to break a cycle. This excludes parameters with
   fixed = false or with an Evaluate = false annotation."
  input Expression exp;
  input UnorderedMap<ComponentRef, Variable> vars;
  input UnorderedSet<ComponentRef> cycleVars;
  input output Boolean evaluable;
protected
  ComponentRef cref;
  Variable var;
algorithm
  if not evaluable then
    return;
  end if;

  () := match exp
    case Expression.CREF()
      algorithm
        cref := ComponentRef.stripSubscriptsAll(exp.cref);

        if UnorderedSet.contains(cref, cycleVars) then
          evaluable := false;
        elseif UnorderedMap.contains(cref, vars) then
          var := UnorderedMap.getOrFail(cref, vars);
          evaluable := Variable.variability(var) <= Variability.PARAMETER and
            Variable.isFixed(var) and
            not valueEq(SCodeUtil.getEvaluateAnnotation(var.comment), SOME(false));
        else
          evaluable := ComponentRef.nodeVariability(exp.cref) <= Variability.STRUCTURAL_PARAMETER;
        end if;
      then
        ();

    else ();
  end match;
end isEvaluableConditionCref;

function evaluateVariable
  input output Variable var;
  input InstContext.Type context;
  input EvalSettings settings;
protected
  Binding binding;
  Boolean structural;
  Variability variability;
algorithm
  variability := Variable.variability(var);
  structural := variability <= Variability.STRUCTURAL_PARAMETER and
                not Type.isExternalObject(var.ty);
  binding := evaluateBinding(var.binding, var.name, structural, variability, context);

  if not referenceEq(binding, var.binding) then
    var.binding := binding;
  end if;

  var.typeAttributes := list(evaluateTypeAttribute(a, var.name, context) for a in var.typeAttributes);
  var.children := list(evaluateVariable(v, context, settings) for v in var.children);
end evaluateVariable;

function evaluateBinding
  input output Binding binding;
  input ComponentRef prefix;
  input Boolean structural;
  input Variability variability;
  input InstContext.Type context;
protected
  Expression exp, eexp;
  SourceInfo info;
algorithm
  if Binding.isBound(binding) then
    exp := Binding.getTypedExp(binding);

    if structural then
      info := Binding.getInfo(binding);
      eexp := evaluateExp(exp, info);
      eexp := SimplifyExp.simplify(eexp);

      if not (Expression.isLiteral(eexp) or Expression.isKnownSizeFill(eexp)) then
        // Any structural parameter that hasn't already been evaluated in earlier stages,
        // such as parameters with Evaluate=true annotations, are probably not critical to evaluate.
        if variability > Variability.CONSTANT or InstContext.inRelaxed(context) then
          eexp := Ceval.tryEvalExp(eexp);
        else
          eexp := Ceval.evalExp(eexp, Ceval.EvalTarget.new(info, context));
        end if;
      end if;

      eexp := Flatten.flattenExp(eexp, Flatten.PREFIX(InstNode.EMPTY_NODE(), prefix), info);
    else
      eexp := evaluateExp(exp, Binding.getInfo(binding));
    end if;

    if not referenceEq(exp, eexp) then
      binding := Binding.setTypedExp(eexp, binding);
    end if;
  end if;
end evaluateBinding;

function evaluateTypeAttribute
  input output tuple<String, Binding> attribute;
  input ComponentRef prefix;
  input InstContext.Type context;
protected
  String name;
  Binding binding, sbinding;
  Boolean structural;
algorithm
  (name, binding) := attribute;
  structural := name == "fixed" or name == "stateSelect";
  sbinding := evaluateBinding(binding, prefix, structural, Variability.PARAMETER, context);

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

function evaluateExpTraverser
  input Expression exp;
  input SourceInfo info;
  input Boolean changed = false;
  output Expression outExp;
  output Boolean outChanged = changed;
protected
  Expression e;
  ComponentRef cref;
  Type ty, ty2;
  Variability var;
algorithm
  (outExp, outChanged) := match exp
    case Expression.CREF()
      algorithm
        (outExp as Expression.CREF(cref = cref, ty = ty), outChanged) :=
          Expression.mapFoldShallow(exp,
            function evaluateExpTraverser(info = info), false);

        var := ComponentRef.nodeVariability(cref);

        if var <= Variability.STRUCTURAL_PARAMETER and not Type.isExternalObject(ty) then
          // Evaluate all constants and structural parameters.
          if var > Variability.CONSTANT then
            ErrorExt.setCheckpoint(getInstanceName());
            try
              e := Ceval.evalCref(cref, outExp, NFCeval.noTarget, evalSubscripts = false);
              e := Flatten.flattenExp(e, Flatten.Prefix.PREFIX(InstNode.EMPTY_NODE(), cref), info);
              outExp := e;
              outChanged := true;
            else
            end try;
            ErrorExt.rollBack(getInstanceName());
          else
            outExp := Ceval.evalCref(cref, outExp, Ceval.EvalTarget.new(info), evalSubscripts = false);
            outExp := Flatten.flattenExp(outExp, Flatten.Prefix.PREFIX(InstNode.EMPTY_NODE(), cref), info);
            outChanged := true;
          end if;
        elseif outChanged then
          ty := ComponentRef.getSubscriptedType(cref);
        end if;

        ty2 := evaluateType(ty, info);
        if not referenceEq(ty, ty2) then
          outExp := Expression.setType(ty2, outExp);
        end if;
      then
        (outExp, outChanged);

    case Expression.ARRAY(literal = true) then (exp, false);
    case Expression.IF() then evaluateIfExp(exp, info);

    // Only evaluate the index for size expressions.
    case Expression.SIZE()
      algorithm
        if isSome(exp.dimIndex) then
          SOME(e) := exp.dimIndex;
          (e, outChanged) := Expression.mapFoldShallow(e,
            function evaluateExpTraverser(info = info), false);

          if outChanged then
            exp.dimIndex := SOME(e);
          end if;
        end if;
      then
        (exp, outChanged);

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
        (outExp, outChanged);

    else
      algorithm
        (outExp, outChanged) := Expression.mapFoldShallow(exp,
          function evaluateExpTraverser(info = info), false);

        ty := Expression.typeOf(outExp);
        ty2 := evaluateType(ty, info);
      then
        (if referenceEq(ty, ty2) then outExp else Expression.setType(ty2, outExp), outChanged);
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
   expected to be discarded."
  input Expression exp;
  input SourceInfo info;
  output Expression outExp;
  output Boolean outChanged;
protected
  Type ty;
  Expression cond, tb, fb;
  Boolean c1, c2;
algorithm
  Expression.IF(ty, cond, tb, fb) := exp;
  (cond, outChanged) := evaluateExpTraverser(cond, info);

  // Simplify the condition in case it can be reduced to a literal value.
  cond := SimplifyExp.simplify(cond);

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
        Equation.EQUALITY(e1, e2, ty, eq.scope, eq.source, eq.scalarizeMode);

    case Equation.FOR()
      algorithm
        eq.range := Util.applyOption(eq.range, function evaluateExp(info = info));
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
        Equation.ASSERT(e1, e2, e3, eq.scope, eq.source);

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
        stmt.range := Util.applyOption(stmt.range, function evaluateExp(info = info));
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

    case Statement.REINIT()
      algorithm
        stmt.reinitExp := evaluateExp(stmt.reinitExp, info);
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
  Boolean is_con;
algorithm
  if not Function.isEvaluated(func) then
    Function.markEvaluated(func);
    is_con := Function.isDefaultRecordConstructor(func);

    func := Function.mapExp(func,
      function evaluateFuncExp(fnNode = InstNode.fromHandle(func.node), evaluateAll = is_con),
      function evaluateFuncExp(fnNode = InstNode.fromHandle(func.node), evaluateAll = true));

    if is_con then
      Record.checkLocalFieldOrder(func.locals, InstNode.fromHandle(func.node), InstNode.info(InstNode.fromHandle(func.node)));
    end if;

    for fn_der in func.derivatives loop
      for der_fn in Function.getCachedFuncs(InstNode.borrow(fn_der.derivativeFn)) loop
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
            outExp := Ceval.evalCref(e.cref, e, NFCeval.noTarget, evalSubscripts = false);
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
        res := InstNode.refEqual(fnNode, InstNode.fromHandle(fn.node));
      end if;
    else
      res := false;
    end if;
  else
    res := true;
  end if;
end isLocalFunctionVariable;

function evaluateRecordDeclaration
  input InstNode recordNode;
algorithm
  ClassTree.applyComponents(Class.classTree(InstNode.getClass(recordNode)),
    function evaluateRecordDeclarationField(recordNode = recordNode));
end evaluateRecordDeclaration;

function evaluateRecordDeclarationField
  input InstNode fieldNode;
  input InstNode recordNode;
protected
  Component comp;
  Binding binding;
  InstNode cls_inst;
algorithm
  comp := InstNode.component(fieldNode);
  binding := Component.getBinding(comp);

  if Binding.isBound(binding) then
    binding := Binding.mapExp(binding, function evaluateFuncExp(fnNode = fieldNode, evaluateAll = false));
    comp := Component.setBinding(binding, comp);
  end if;

  cls_inst := Component.classInstance(comp);
  if not InstNode.isEmpty(cls_inst) then
    ClassTree.applyComponents(Class.classTree(InstNode.getClass(cls_inst)),
      function evaluateRecordDeclarationField(recordNode = recordNode));
  end if;

  InstNode.updateComponent(comp, fieldNode);
end evaluateRecordDeclarationField;

annotation(__OpenModelica_Interface="nf_frontend");
end NFEvalConstants;
