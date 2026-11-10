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

encapsulated package ParamDeps
"Finds the tunable parameters of an FMU 2.0 or 3.0, or of a simulation with
 --tunableParameters, and the dependencies between the parameters, see
 SimCode.ParamDeps."

import SimCode;

protected
import BackendDAE;
import CheckModel;
import ComponentReference;
import ComponentReferenceBasics;
import DAE;
import DAEUtil;
import Expression;
import HashTableCrefSimVar;
import Flags;
import List;
import SimCodeCodegenUtil;
import SimCodeVar;
import SimCodeVar.SimVar;
import UnorderedMap;
import Util;

type IntList = list<Integer>;

constant Integer REAL = 0;
constant Integer INTEGER = 1;
constant Integer BOOLEAN = 2;
constant Integer STRING = 3;
constant Integer EXTOBJ = 4;

uniontype Slots
  record SLOTS
    UnorderedMap<String, list<Integer>> byName "the slots of the elements of a variable";
    UnorderedMap<String, list<Integer>> byPrefix "the slots of all elements and fields of an array or record";
    array<Boolean> isParam;
  end SLOTS;
end Slots;

public

function add
  "Sets SimCode.paramDeps and marks the tunable parameters."
  input SimCode.SimCode simCode;
  output SimCode.SimCode outSimCode = simCode;
protected
  SimCode.ModelInfo modelInfo;
  SimCodeVar.SimVars vars;
  Slots slots;
  list<SimCode.ParamDepEq> eqs;
  array<Boolean> reached;
  list<Integer> paramSlots;
  UnorderedMap<String, Boolean> groups;
algorithm
  modelInfo := simCode.modelInfo;
  vars := modelInfo.vars;
  slots := createSlots(vars);
  paramSlots := list(i - 1 for i guard slots.isParam[i] in 1:arrayLength(slots.isParam));
  try
    true := simCode.scalarized;
    eqs := dependencies(simCode, slots);
    reached := tunableSlots(vars, slots, eqs);
    eqs := list(if isSome(e.eq) and List.exist1(e.uses, isMarked, reached) then e else SimCode.PARAM_DEP_EQ(NONE(), e.uses, e.defines) for e in eqs);
  else
    eqs := {SimCode.PARAM_DEP_EQ(NONE(), paramSlots, paramSlots)};
    reached := arrayCreate(arrayLength(slots.isParam), false);
  end try;

  groups := reachedGroups(List.flatten({vars.paramVars, vars.intParamVars, vars.boolParamVars, vars.stringParamVars,
                                        vars.aliasVars, vars.intAliasVars, vars.boolAliasVars, vars.stringAliasVars}), slots, reached);
  vars.paramVars := list(markTunable(v, groups) for v in vars.paramVars);
  vars.intParamVars := list(markTunable(v, groups) for v in vars.intParamVars);
  vars.boolParamVars := list(markTunable(v, groups) for v in vars.boolParamVars);
  vars.stringParamVars := list(markTunable(v, groups) for v in vars.stringParamVars);
  vars.aliasVars := list(markTunable(v, groups) for v in vars.aliasVars);
  vars.intAliasVars := list(markTunable(v, groups) for v in vars.intAliasVars);
  vars.boolAliasVars := list(markTunable(v, groups) for v in vars.boolAliasVars);
  vars.stringAliasVars := list(markTunable(v, groups) for v in vars.stringAliasVars);
  modelInfo.vars := vars;
  outSimCode.modelInfo := modelInfo;
  for v in List.flatten({vars.paramVars, vars.intParamVars, vars.boolParamVars, vars.stringParamVars,
                         vars.aliasVars, vars.intAliasVars, vars.boolAliasVars, vars.stringAliasVars}) loop
    if isTunable(v) then
      outSimCode.crefToSimVarHT := HashTableCrefSimVar.addSimVarToHashTable(v, outSimCode.crefToSimVarHT);
    end if;
  end for;
  outSimCode.paramDeps := SimCode.PARAM_DEPS(simCode.scalarized, eqs, settable(vars, slots));
end add;

protected

function slot
  input Integer index "0-based";
  input Integer ty;
  output Integer s = 8 * index + ty;
end slot;

function createSlots
  input SimCodeVar.SimVars vars;
  output Slots slots;
protected
  UnorderedMap<String, list<Integer>> byName = UnorderedMap.new<IntList>(stringHashDjb2, stringEq);
  UnorderedMap<String, list<Integer>> byPrefix = UnorderedMap.new<IntList>(stringHashDjb2, stringEq);
  list<tuple<Integer, list<SimVar>, list<SimVar>>> arrays;
  list<SimVar> realVars;
  Integer n, maxCount = 0;
  list<Integer> params = {}, elems;
  array<Boolean> isParam;
algorithm
  realVars := List.flatten({vars.stateVars, vars.derivativeVars, vars.algVars, vars.discreteAlgVars,
                            vars.realOptimizeConstraintsVars, vars.realOptimizeFinalConstraintsVars});
  arrays := {(REAL, realVars, vars.paramVars), (INTEGER, vars.intAlgVars, vars.intParamVars),
             (BOOLEAN, vars.boolAlgVars, vars.boolParamVars), (STRING, vars.stringAlgVars, vars.stringParamVars),
             (EXTOBJ, vars.extObjVars, {})};
  for a in arrays loop
    n := 0;
    for v in Util.tuple32(a) loop
      elems := list(slot(n + i, Util.tuple31(a)) for i in 0:SimCodeCodegenUtil.numScalarElems({v}) - 1);
      register(v.name, elems, byName, byPrefix);
      n := n + listLength(elems);
    end for;
    for v in Util.tuple33(a) loop
      elems := list(slot(n + i, Util.tuple31(a)) for i in 0:SimCodeCodegenUtil.numScalarElems({v}) - 1);
      register(v.name, elems, byName, byPrefix);
      params := listAppend(elems, params);
      n := n + listLength(elems);
    end for;
    maxCount := max(maxCount, n);
  end for;
  for v in List.flatten({vars.aliasVars, vars.intAliasVars, vars.boolAliasVars, vars.stringAliasVars}) loop
    _ := match v.aliasvar
      local
        DAE.ComponentRef target;
        Integer s;
      case SimCodeVar.ALIAS(varName = target)
        guard UnorderedMap.contains(key(target), byName)
        algorithm
          register(v.name, UnorderedMap.getOrFail(key(target), byName), byName, byPrefix);
        then ();
      case SimCodeVar.NEGATEDALIAS(varName = target)
        guard UnorderedMap.contains(key(target), byName)
        algorithm
          register(v.name, UnorderedMap.getOrFail(key(target), byName), byName, byPrefix);
        then ();
      else ();
    end match;
  end for;
  isParam := arrayCreate(8 * maxCount + 8, false);
  for s in params loop
    arrayUpdate(isParam, s + 1, true);
  end for;
  slots := SLOTS(byName, byPrefix, isParam);
end createSlots;

function register
  input DAE.ComponentRef name;
  input list<Integer> elems;
  input UnorderedMap<String, list<Integer>> byName;
  input UnorderedMap<String, list<Integer>> byPrefix;
protected
  DAE.ComponentRef prefix = ComponentReference.crefStripSubs(name);
  String k;
algorithm
  UnorderedMap.add(key(name), elems, byName);
  while true loop
    k := key(prefix);
    UnorderedMap.add(k, listAppend(elems, UnorderedMap.getOrDefault(k, byPrefix, {})), byPrefix);
    if ComponentReference.crefIsIdent(prefix) then
      break;
    end if;
    prefix := ComponentReference.crefStripSubs(ComponentReference.crefStripLastIdent(prefix));
  end while;
end register;

function key
  input DAE.ComponentRef cr;
  output String k = ComponentReferenceBasics.printComponentRefStr(cr);
end key;

function lookup
  "The slots of a variable, or of all elements and fields of an array or record."
  input DAE.ComponentRef cr;
  input Slots slots;
  output list<Integer> result;
algorithm
  result := match UnorderedMap.get(key(cr), slots.byName)
    case SOME(result) then result;
    else UnorderedMap.getOrDefault(key(ComponentReference.crefStripSubs(cr)), slots.byPrefix, {});
  end match;
end lookup;

function lookupAll
  input list<DAE.ComponentRef> crs;
  input Slots slots;
  output list<Integer> result = List.sortedUnique(List.sort(List.flatten(list(lookup(cr, slots) for cr in crs)), intGt), intEq);
end lookupAll;

function dependencies
  "The non-literal parameter equations in evaluation order, the initial
   equations of the time-invariant variables the simulation does not
   calculate, the min, max and nominal attributes bound to parameters, then
   the values that only the initialization calculates (parameters with
   fixed=false, variables of `when initial()`; not the states)."
  input SimCode.SimCode simCode;
  input Slots slots;
  output list<SimCode.ParamDepEq> eqs = {};
protected
  UnorderedMap<Integer, SimCode.SimEqSystem> byIndex = equationsByIndex(simCode);
  list<Integer> uses, defines, initDefined, needed;
  list<tuple<list<Integer>, list<Integer>>> initEqs;
  array<Boolean> mark, simDefined, continuous, invariant;
  SimCode.SimEqSystem e;
algorithm
  for eq in SimCodeCodegenUtil.filterScalarLiteralAssignments(simCode.parameterEquations) loop
    e := resolveAlias(eq, byIndex);
    uses := lookupAll(eqUses(e, {}, byIndex), slots);
    defines := lookupAll(eqDefines(e, {}, byIndex), slots);
    eqs := SimCode.PARAM_DEP_EQ(if List.any(defines, isExtObj) then NONE() else SOME(eq), uses, defines) :: eqs;
  end for;

  simDefined := arrayCreate(arrayLength(slots.isParam), false);
  for s in lookupAll(list(v.name for v in simCode.modelInfo.vars.stateVars), slots) loop
    arrayUpdate(simDefined, s + 1, true);
  end for;
  for s in lookupAll(simulationDefines(simCode, byIndex), slots) loop
    arrayUpdate(simDefined, s + 1, true);
  end for;
  continuous := arrayCreate(arrayLength(slots.isParam), false);
  for s in lookupAll(list(v.name for v in simCode.modelInfo.vars.algVars), slots) loop
    arrayUpdate(continuous, s + 1, not simDefined[s + 1]);
  end for;

  // A continuous variable only the initial system calculates is time-invariant:
  // its equation holds whenever its parameters change.
  invariant := arrayCreate(arrayLength(slots.isParam), false);
  for eq in simCode.initialEquations loop
    e := resolveAlias(eq, byIndex);
    uses := lookupAll(eqUses(e, {}, byIndex), slots);
    defines := lookupAll(eqDefines(e, {}, byIndex), slots);
    if isAssignment(e) and not listEmpty(defines) and List.all(defines, function isMarked(mark = continuous)) and
       List.all(uses, function isInvariantUse(slots = slots, invariant = invariant, defines = defines)) then
      for s in defines loop
        arrayUpdate(invariant, s + 1, true);
      end for;
      eqs := SimCode.PARAM_DEP_EQ(SOME(eq), uses, defines) :: eqs;
    end if;
  end for;

  for eq in List.flatten({simCode.minValueEquations, simCode.maxValueEquations, simCode.nominalValueEquations}) loop
    eqs := match eq
      case SimCode.SES_SIMPLE_ASSIGN() then SimCode.PARAM_DEP_EQ(SOME(eq), lookupAll(Expression.getAllCrefs(eq.exp), slots), {}) :: eqs;
      else eqs;
    end match;
  end for;

  initEqs := list((lookupAll(eqUses(resolveAlias(eq, byIndex), {}, byIndex), slots),
                   lookupAll(eqDefines(resolveAlias(eq, byIndex), {}, byIndex), slots))
                  for eq in listAppend(simCode.initialEquations, simCode.initialEquations_lambda0));
  initDefined := List.unique(list(s for s guard not simDefined[s + 1] and not invariant[s + 1] in
                                  List.flatten(list(Util.tuple22(t) for t in initEqs))));
  if not listEmpty(initDefined) then
    mark := arrayCreate(arrayLength(slots.isParam), false);
    for s in initDefined loop
      arrayUpdate(mark, s + 1, true);
    end for;
    for t in listReverse(initEqs) loop
      if List.exist1(Util.tuple22(t), isMarked, mark) then
        for s in Util.tuple21(t) loop
          arrayUpdate(mark, s + 1, true);
        end for;
      end if;
    end for;
    needed := list(s for s guard mark[s + 1] and slots.isParam[s + 1] in 0:arrayLength(mark) - 1);
    eqs := SimCode.PARAM_DEP_EQ(NONE(), needed, initDefined) :: eqs;
  end if;

  uses := lookupAll(initOnlyCrefs(simCode), slots);
  if not listEmpty(uses) then
    eqs := SimCode.PARAM_DEP_EQ(NONE(), uses, {}) :: eqs;
  end if;
  eqs := listReverse(eqs);
end dependencies;

function isAssignment
  input SimCode.SimEqSystem eq;
  output Boolean b;
algorithm
  b := match eq
    case SimCode.SES_SIMPLE_ASSIGN() then true;
    case SimCode.SES_ARRAY_CALL_ASSIGN() then true;
    else false;
  end match;
end isAssignment;

function isInvariantUse
  input Integer s;
  input Slots slots;
  input array<Boolean> invariant;
  input list<Integer> defines;
  output Boolean b = slots.isParam[s + 1] or invariant[s + 1] or listMember(s, defines);
end isInvariantUse;

function isExtObj
  input Integer s;
  output Boolean b = intMod(s, 8) == EXTOBJ;
end isExtObj;

function isNotMarked
  input Integer s;
  input array<Boolean> mark;
  output Boolean b = not mark[s + 1];
end isNotMarked;

function simulationDefines
  "The variables the simulation calculates, without `when initial()`."
  input SimCode.SimCode simCode;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
  output list<DAE.ComponentRef> crefs = {};
algorithm
  for eq in simCode.allEquations loop
    crefs := simulationEqDefines(resolveAlias(eq, byIndex), crefs, byIndex);
  end for;
  for p in simCode.clockedPartitions loop
    for sub in p.subPartitions loop
      crefs := eqsDefines(sub.equations, crefs, byIndex);
    end for;
  end for;
end simulationDefines;

function simulationEqDefines
  input SimCode.SimEqSystem eq;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  crefs := match eq
    case SimCode.SES_WHEN(conditions = {})
      then if isSome(eq.elseWhen) then simulationEqDefines(Util.getOption(eq.elseWhen), crefs, byIndex) else crefs;
    else eqDefines(eq, crefs, byIndex);
  end match;
end simulationEqDefines;

function isMarked
  input Integer s;
  input array<Boolean> mark;
  output Boolean b = mark[s + 1];
end isMarked;

function initOnlyCrefs
  "Variables the runtime reads only during initialization: sample() start and
   interval, clock intervals, the maximum delay of delay() and the initial
   values of spatialDistribution()."
  input SimCode.SimCode simCode;
  output list<DAE.ComponentRef> crefs = {};
algorithm
  for ev in simCode.timeEvents loop
    crefs := match ev
      case BackendDAE.SAMPLE_TIME_EVENT() then listAppend(Expression.getAllCrefs(ev.startExp), listAppend(Expression.getAllCrefs(ev.intervalExp), crefs));
      else crefs;
    end match;
  end for;
  for p in simCode.clockedPartitions loop
    crefs := listAppend(clockCrefs(p.baseClock), crefs);
  end for;
  for d in simCode.delayedExps.delayedExps loop
    crefs := listAppend(Expression.getAllCrefs(Util.tuple33(Util.tuple22(d))), crefs);
  end for;
  for d in simCode.delayedExps.delayedLoops loop
    crefs := listAppend(Expression.getAllCrefs(Util.tuple33(Util.tuple32(d))), crefs);
  end for;
  for s in simCode.spatialInfo.spatialDistributions loop
    crefs := listAppend(Expression.getAllCrefs(s.initPnts), listAppend(Expression.getAllCrefs(s.initVals), crefs));
  end for;
end initOnlyCrefs;

function clockCrefs
  input DAE.ClockKind clk;
  output list<DAE.ComponentRef> crefs;
algorithm
  crefs := match clk
    case DAE.RATIONAL_CLOCK() then listAppend(Expression.getAllCrefs(clk.intervalCounter), Expression.getAllCrefs(clk.resolution));
    case DAE.REAL_CLOCK() then Expression.getAllCrefs(clk.interval);
    case DAE.EVENT_CLOCK() then listAppend(Expression.getAllCrefs(clk.condition), Expression.getAllCrefs(clk.startInterval));
    case DAE.SOLVER_CLOCK() then Expression.getAllCrefs(clk.c);
    else {};
  end match;
end clockCrefs;

function equationsByIndex
  input SimCode.SimCode simCode;
  output UnorderedMap<Integer, SimCode.SimEqSystem> byIndex = UnorderedMap.new<SimCode.SimEqSystem>(Util.id, intEq);
algorithm
  for eqs in {simCode.allEquations, simCode.initialEquations, simCode.initialEquations_lambda0,
              simCode.removedInitialEquations, simCode.parameterEquations, simCode.removedEquations,
              simCode.algorithmAndEquationAsserts, simCode.equationsForZeroCrossings, simCode.jacobianEquations,
              simCode.startValueEquations, simCode.nominalValueEquations, simCode.minValueEquations,
              simCode.maxValueEquations} loop
    for eq in eqs loop
      _ := match eq
        case SimCode.SES_SIMPLE_ASSIGN() algorithm UnorderedMap.add(eq.index, eq, byIndex); then ();
        case SimCode.SES_ARRAY_CALL_ASSIGN() algorithm UnorderedMap.add(eq.index, eq, byIndex); then ();
        case SimCode.SES_ALGORITHM() algorithm UnorderedMap.add(eq.index, eq, byIndex); then ();
        else ();
      end match;
    end for;
  end for;
end equationsByIndex;

function resolveAlias
  input SimCode.SimEqSystem eq;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
  output SimCode.SimEqSystem result;
algorithm
  result := match eq
    case SimCode.SES_ALIAS() then UnorderedMap.getOrFail(eq.aliasOf, byIndex);
    else eq;
  end match;
end resolveAlias;

function eqUses
  "Every variable an equation refers to."
  input SimCode.SimEqSystem eq;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  crefs := match eq
    local
      SimCode.LinearSystem ls;
      SimCode.NonlinearSystem nls;
    case SimCode.SES_RESIDUAL() then listAppend(Expression.getAllCrefs(eq.exp), crefs);
    case SimCode.SES_FOR_RESIDUAL() then listAppend(Expression.getAllCrefs(eq.exp), crefs);
    case SimCode.SES_GENERIC_RESIDUAL() then listAppend(Expression.getAllCrefs(eq.exp), crefs);
    case SimCode.SES_SIMPLE_ASSIGN() then eq.cref :: listAppend(Expression.getAllCrefs(eq.exp), crefs);
    case SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS() then eq.cref :: listAppend(Expression.getAllCrefs(eq.exp), crefs);
    case SimCode.SES_ARRAY_CALL_ASSIGN() then listAppend(Expression.getAllCrefs(eq.lhs), listAppend(Expression.getAllCrefs(eq.exp), crefs));
    case SimCode.SES_IFEQUATION()
      algorithm
        for b in eq.ifbranches loop
          crefs := listAppend(Expression.getAllCrefs(Util.tuple21(b)), crefs);
          crefs := eqsUses(Util.tuple22(b), crefs, byIndex);
        end for;
      then eqsUses(eq.elsebranch, crefs, byIndex);
    case SimCode.SES_ALGORITHM() then stmtsCrefs(eq.statements, crefs);
    case SimCode.SES_INVERSE_ALGORITHM() then stmtsCrefs(eq.statements, crefs);
    case SimCode.SES_LINEAR() then linearUses(eq.lSystem, linearUsesOpt(eq.alternativeTearing, crefs, byIndex), byIndex);
    case SimCode.SES_NONLINEAR() then nonlinearUses(eq.nlSystem, nonlinearUsesOpt(eq.alternativeTearing, crefs, byIndex), byIndex);
    case SimCode.SES_MIXED()
      algorithm
        crefs := eqUses(eq.cont, crefs, byIndex);
        crefs := eqsUses(eq.discEqs, crefs, byIndex);
      then listAppend(list(v.name for v in eq.discVars), crefs);
    case SimCode.SES_WHEN()
      algorithm
        crefs := listAppend(eq.conditions, crefs);
        for op in eq.whenStmtLst loop
          crefs := whenOperatorCrefs(op, crefs);
        end for;
        if isSome(eq.elseWhen) then
          crefs := eqUses(Util.getOption(eq.elseWhen), crefs, byIndex);
        end if;
      then crefs;
    case SimCode.SES_FOR_LOOP()
      then eq.cref :: listAppend(Expression.getAllCrefs(eq.startIt), listAppend(Expression.getAllCrefs(eq.endIt), listAppend(Expression.getAllCrefs(eq.exp), crefs)));
    case SimCode.SES_FOR_EQUATION()
      algorithm
        crefs := listAppend(Expression.getAllCrefs(eq.startIt), listAppend(Expression.getAllCrefs(eq.endIt), crefs));
      then eqsUses(eq.body, crefs, byIndex);
    case SimCode.SES_ALIAS() then eqUses(UnorderedMap.getOrFail(eq.aliasOf, byIndex), crefs, byIndex);
  end match;
end eqUses;

function eqsUses
  input list<SimCode.SimEqSystem> eqs;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  for eq in eqs loop
    crefs := eqUses(eq, crefs, byIndex);
  end for;
end eqsUses;

function linearUses
  input SimCode.LinearSystem ls;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  crefs := listAppend(list(v.name for v in ls.vars), crefs);
  for e in ls.beqs loop
    crefs := listAppend(Expression.getAllCrefs(e), crefs);
  end for;
  for j in ls.simJac loop
    crefs := eqUses(Util.tuple33(j), crefs, byIndex);
  end for;
  crefs := eqsUses(ls.residual, crefs, byIndex);
end linearUses;

function linearUsesOpt
  input Option<SimCode.LinearSystem> ls;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  if isSome(ls) then
    crefs := linearUses(Util.getOption(ls), crefs, byIndex);
  end if;
end linearUsesOpt;

function nonlinearUses
  input SimCode.NonlinearSystem nls;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  crefs := eqsUses(nls.eqs, listAppend(nls.crefs, crefs), byIndex);
end nonlinearUses;

function nonlinearUsesOpt
  input Option<SimCode.NonlinearSystem> nls;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  if isSome(nls) then
    crefs := nonlinearUses(Util.getOption(nls), crefs, byIndex);
  end if;
end nonlinearUsesOpt;

function whenOperatorCrefs
  input BackendDAE.WhenOperator op;
  input output list<DAE.ComponentRef> crefs;
algorithm
  crefs := match op
    case BackendDAE.ASSIGN() then listAppend(Expression.getAllCrefs(op.left), listAppend(Expression.getAllCrefs(op.right), crefs));
    case BackendDAE.REINIT() then op.stateVar :: listAppend(Expression.getAllCrefs(op.value), crefs);
    case BackendDAE.ASSERT() then listAppend(Expression.getAllCrefs(op.condition), listAppend(Expression.getAllCrefs(op.message), crefs));
    case BackendDAE.TERMINATE() then listAppend(Expression.getAllCrefs(op.message), crefs);
    case BackendDAE.NORETCALL() then listAppend(Expression.getAllCrefs(op.exp), crefs);
    else crefs;
  end match;
end whenOperatorCrefs;

function stmtsCrefs
  input list<DAE.Statement> stmts;
  input output list<DAE.ComponentRef> crefs;
algorithm
  (_, crefs) := DAEUtil.traverseDAEStmts(stmts, stmtExpCrefs, crefs);
end stmtsCrefs;

function stmtExpCrefs
  input DAE.Exp exp;
  input DAE.Statement stmt;
  input list<DAE.ComponentRef> crefs;
  output DAE.Exp outExp = exp;
  output list<DAE.ComponentRef> outCrefs = listAppend(Expression.getAllCrefs(exp), crefs);
end stmtExpCrefs;

function eqDefines
  "The variables an equation assigns. Fails for an equation it does not know."
  input SimCode.SimEqSystem eq;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  crefs := match eq
    case SimCode.SES_RESIDUAL() then crefs;
    case SimCode.SES_FOR_RESIDUAL() then crefs;
    case SimCode.SES_GENERIC_RESIDUAL() then crefs;
    case SimCode.SES_SIMPLE_ASSIGN() then eq.cref :: crefs;
    case SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS() then eq.cref :: crefs;
    case SimCode.SES_ARRAY_CALL_ASSIGN() then listAppend(Expression.getAllCrefs(eq.lhs), crefs);
    case SimCode.SES_IFEQUATION()
      algorithm
        for b in eq.ifbranches loop
          crefs := eqsDefines(Util.tuple22(b), crefs, byIndex);
        end for;
      then eqsDefines(eq.elsebranch, crefs, byIndex);
    case SimCode.SES_ALGORITHM() then listAppend(CheckModel.algorithmStatementListOutputs(eq.statements, DAE.EXPAND()), crefs);
    case SimCode.SES_INVERSE_ALGORITHM() then listAppend(CheckModel.algorithmStatementListOutputs(eq.statements, DAE.EXPAND()), crefs);
    case SimCode.SES_LINEAR() then linearDefines(eq.lSystem, linearDefinesOpt(eq.alternativeTearing, crefs, byIndex), byIndex);
    case SimCode.SES_NONLINEAR() then nonlinearDefines(eq.nlSystem, nonlinearDefinesOpt(eq.alternativeTearing, crefs, byIndex), byIndex);
    case SimCode.SES_MIXED()
      algorithm
        crefs := eqDefines(eq.cont, crefs, byIndex);
        crefs := eqsDefines(eq.discEqs, crefs, byIndex);
      then listAppend(list(v.name for v in eq.discVars), crefs);
    case SimCode.SES_WHEN()
      algorithm
        for op in eq.whenStmtLst loop
          crefs := match op
            case BackendDAE.ASSIGN() then listAppend(Expression.getAllCrefs(op.left), crefs);
            case BackendDAE.REINIT() then op.stateVar :: crefs;
            else crefs;
          end match;
        end for;
        if isSome(eq.elseWhen) then
          crefs := eqDefines(Util.getOption(eq.elseWhen), crefs, byIndex);
        end if;
      then crefs;
    case SimCode.SES_FOR_LOOP() then eq.cref :: crefs;
    case SimCode.SES_FOR_EQUATION() then eqsDefines(eq.body, crefs, byIndex);
    case SimCode.SES_ALIAS() then eqDefines(UnorderedMap.getOrFail(eq.aliasOf, byIndex), crefs, byIndex);
  end match;
end eqDefines;

function eqsDefines
  input list<SimCode.SimEqSystem> eqs;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  for eq in eqs loop
    crefs := eqDefines(eq, crefs, byIndex);
  end for;
end eqsDefines;

function linearDefines
  input SimCode.LinearSystem ls;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  crefs := eqsDefines(ls.residual, listAppend(list(v.name for v in ls.vars), crefs), byIndex);
end linearDefines;

function linearDefinesOpt
  input Option<SimCode.LinearSystem> ls;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  if isSome(ls) then
    crefs := linearDefines(Util.getOption(ls), crefs, byIndex);
  end if;
end linearDefinesOpt;

function nonlinearDefines
  input SimCode.NonlinearSystem nls;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  crefs := eqsDefines(nls.eqs, listAppend(nls.crefs, crefs), byIndex);
end nonlinearDefines;

function nonlinearDefinesOpt
  input Option<SimCode.NonlinearSystem> nls;
  input output list<DAE.ComponentRef> crefs;
  input UnorderedMap<Integer, SimCode.SimEqSystem> byIndex;
algorithm
  if isSome(nls) then
    crefs := nonlinearDefines(Util.getOption(nls), crefs, byIndex);
  end if;
end nonlinearDefinesOpt;

function tunableSlots
  "The slots of the tunable parameters and of everything calculated from them.
   A parameter with a literal binding is tunable unless it reaches an equation
   that is not evaluated again after initialization."
  input SimCodeVar.SimVars vars;
  input Slots slots;
  input list<SimCode.ParamDepEq> eqs;
  output array<Boolean> reached = arrayCreate(arrayLength(slots.isParam), false);
protected
  array<Boolean> tainted = arrayCreate(arrayLength(slots.isParam), false);
  list<SimVar> params;
  UnorderedMap<String, Boolean> fixedArrays = UnorderedMap.new<Boolean>(stringHashDjb2, stringEq);
  String k;
algorithm
  if Flags.getConfigEnum(Flags.FMI_TUNABLE_PARAMETERS) == Flags.FMI_TUNABLE_NONE then
    return;
  end if;
  for eq in listReverse(eqs) loop
    if isNone(eq.eq) or List.exist1(eq.defines, isMarked, tainted) then
      for s in eq.uses loop
        arrayUpdate(tainted, s + 1, true);
      end for;
    end if;
  end for;
  params := list(v for v guard isParameterCausality(v) in
                 List.flatten({vars.paramVars, vars.intParamVars, vars.boolParamVars, vars.stringParamVars}));
  for v in params loop
    k := arrayKey(v);
    UnorderedMap.add(k, UnorderedMap.getOrDefault(k, fixedArrays, false) or List.exist1(lookupVar(v, slots), isMarked, tainted), fixedArrays);
  end for;
  for v in params loop
    if not UnorderedMap.getOrFail(arrayKey(v), fixedArrays) then
      for s in lookupVar(v, slots) loop
        arrayUpdate(reached, s + 1, true);
      end for;
    end if;
  end for;
  for eq in eqs loop
    if List.exist1(eq.uses, isMarked, reached) then
      for s in eq.defines loop
        arrayUpdate(reached, s + 1, true);
      end for;
    end if;
  end for;
end tunableSlots;

function isParameterCausality
  input SimVar v;
  output Boolean b;
algorithm
  b := match v.causality
    case SOME(SimCodeVar.PARAMETER()) then true;
    else false;
  end match;
end isParameterCausality;

function arrayKey
  "Elements of an array share it."
  input SimVar v;
  output String k = key(ComponentReference.crefStripSubs(v.name));
end arrayKey;

function reachedGroups
  "Whether any element of each array (or scalar) parameter is reached."
  input list<SimVar> vars;
  input Slots slots;
  input array<Boolean> reached;
  output UnorderedMap<String, Boolean> groups = UnorderedMap.new<Boolean>(stringHashDjb2, stringEq);
protected
  String k;
algorithm
  for v in vars loop
    if isParamKind(v.varKind) then
      k := arrayKey(v);
      UnorderedMap.add(k, UnorderedMap.getOrDefault(k, groups, false) or List.exist1(lookupVar(v, slots), isMarked, reached), groups);
    end if;
  end for;
end reachedGroups;

function markTunable
  "A whole array is tunable or fixed, as FMI 3.0 exports it as one variable."
  input output SimVar v;
  input UnorderedMap<String, Boolean> groups;
algorithm
  if isParamKind(v.varKind) and UnorderedMap.getOrDefault(arrayKey(v), groups, false) then
    v.variability := SOME(SimCodeVar.TUNABLE());
  end if;
end markTunable;

function isTunable
  input SimVar v;
  output Boolean b;
algorithm
  b := match v.variability
    case SOME(SimCodeVar.TUNABLE()) then true;
    else false;
  end match;
end isTunable;

function isParamKind
  input BackendDAE.VarKind kind;
  output Boolean b;
algorithm
  b := match kind
    case BackendDAE.PARAM() then true;
    else false;
  end match;
end isParamKind;

function lookupVar
  input SimVar v;
  input Slots slots;
  output list<Integer> result;
algorithm
  result := UnorderedMap.getOrDefault(key(v.name), slots.byName, {});
end lookupVar;

function settable
  "The slots an importer may set, with SimCode.PARAM_DEPS_* flags, the union
   over the variables that share a slot."
  input SimCodeVar.SimVars vars;
  input Slots slots;
  output list<tuple<Integer, Integer>> result = {};
protected
  array<Integer> flags = arrayCreate(arrayLength(slots.isParam), 0);
  Integer f;
algorithm
  for v in List.flatten({vars.stateVars, vars.derivativeVars, vars.algVars, vars.discreteAlgVars,
                         vars.paramVars, vars.intAlgVars, vars.intParamVars, vars.boolAlgVars,
                         vars.boolParamVars, vars.stringAlgVars, vars.stringParamVars, vars.aliasVars,
                         vars.intAliasVars, vars.boolAliasVars, vars.stringAliasVars}) loop
    f := varFlags(v);
    if f <> 0 then
      for s in lookupVar(v, slots) loop
        arrayUpdate(flags, s + 1, intBitOr(flags[s + 1], f));
      end for;
    end if;
  end for;
  for s in arrayLength(flags):-1:1 loop
    if flags[s] <> 0 then
      result := (s - 1, flags[s]) :: result;
    end if;
  end for;
end settable;

function varFlags
  input SimVar v;
  output Integer f = 0;
algorithm
  f := match v
    case SimCodeVar.SIMVAR(initial_ = SOME(SimCodeVar.EXACT())) then SimCode.PARAM_DEPS_INITIAL_EXACT;
    case SimCodeVar.SIMVAR(initial_ = SOME(SimCodeVar.APPROX())) then SimCode.PARAM_DEPS_INITIAL_APPROX;
    // As CodegenFMU3.FmiInitialAttribute3 for a state the non-scalarized backend left without one.
    case SimCodeVar.SIMVAR(initial_ = NONE(), varKind = BackendDAE.STATE())
      then if v.isFixed then SimCode.PARAM_DEPS_INITIAL_EXACT else SimCode.PARAM_DEPS_INITIAL_APPROX;
    else 0;
  end match;
  f := match v.causality
    case SOME(SimCodeVar.INPUT())
      then intBitOr(f, SimCode.PARAM_DEPS_INPUT + (match v.variability case SOME(SimCodeVar.CONTINUOUS()) then SimCode.PARAM_DEPS_CONTINUOUS; else 0; end match));
    case SOME(SimCodeVar.PARAMETER())
      then intBitOr(f, match v.variability case SOME(SimCodeVar.TUNABLE()) then SimCode.PARAM_DEPS_TUNABLE; else 0; end match);
    else f;
  end match;
end varFlags;

annotation(__OpenModelica_Interface="backend");
end ParamDeps;
