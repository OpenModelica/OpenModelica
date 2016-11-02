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

encapsulated package SynchronousFeatures
" file:        SynchronousFeatures.mo
  package:     SynchronousFeatures
  description: This package contains functions that belong to synchronous features.
               - base-clock partitioning
               - sub-clock partitioning"


public import Absyn;
public import BackendDAE;
public import DAE;

protected import BackendDAEOptimize;
protected import BackendDAEUtil;
protected import BackendDump;
protected import ExpressionDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import DAEUtil;
protected import Error;
protected import Flags;
protected import List;
protected import Util;
protected import Types;
protected import Expression;
protected import HashTable;
protected import MMath;

// =============================================================================
// clock partitioning
//
// =============================================================================

public function clockPartitioning
  "Finds independent partitions of the equation system by base-clock partitioning and TLM."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := match inDAE
    local
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;

    case (BackendDAE.DAE({syst}, shared))
    then clockPartitioning1(syst, shared);

    // TODO: Improve support for partitioned systems of equations
    else equation
      BackendDAE.DAE({syst}, shared) = BackendDAEOptimize.collapseIndependentBlocks(inDAE);
    then clockPartitioning1(syst, shared);
  end match;
end clockPartitioning;

public function contPartitioning
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs, clockedSysts, clockedSysts1;
  BackendDAE.Shared shared;
  BackendDAE.EqSystem syst;
  list<BackendDAE.Equation> unpartRemEqs;
algorithm
  (clockedSysts, systs) := List.splitOnTrue(inDAE.eqs, BackendDAEUtil.isClockedSyst);
  shared := inDAE.shared;

  if listLength(systs) > 0 then
    BackendDAE.DAE({syst}, shared) := BackendDAEOptimize.collapseIndependentBlocks(BackendDAE.DAE(systs, shared));
    (systs, clockedSysts1, unpartRemEqs) := baseClockPartitioning(syst, shared);
    assert(listLength(clockedSysts1) == 0, "Get clocked system in SynchronousFeatures.addContVarsEqs");
    shared.removedEqs := BackendEquation.addEquations(unpartRemEqs, shared.removedEqs);
  end if;

  outDAE := BackendDAE.DAE(listAppend(systs, clockedSysts), shared);
end contPartitioning;

protected function clockPartitioning1
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystem syst;
  list<BackendDAE.EqSystem> contSysts, clockedSysts;
  BackendDAE.Shared shared = inShared;
  list<BackendDAE.EqSystem> systs;
  list<DAE.ComponentRef> holdComps;
  list<BackendDAE.Equation> unpartRemEqs;
algorithm
  syst := substitutePartitionOpExps(inSyst, inShared);
  (contSysts, clockedSysts, unpartRemEqs) := baseClockPartitioning(syst, shared);

  (contSysts, holdComps) := removeHoldExpsSyst(contSysts);

  (clockedSysts, shared) := subClockPartitioning1(clockedSysts, shared, holdComps);

  (clockedSysts, shared) := treatClockedStates(clockedSysts, shared);

  unpartRemEqs := createBoolClockWhenClauses(shared, unpartRemEqs);
  shared.removedEqs := BackendEquation.addEquations(unpartRemEqs, shared.removedEqs);

  systs := listAppend(contSysts, clockedSysts);
  outDAE := BackendDAE.DAE(systs, shared);

  if Flags.isSet(Flags.DUMP_SYNCHRONOUS) then
    BackendDump.dumpEqSystems(systs, "clock partitioning");
    BackendDump.dumpBasePartitions(shared.partitionsInfo.basePartitions, "Base clocks");
    BackendDump.dumpSubPartitions(shared.partitionsInfo.subPartitions, "Sub clocks");
  end if;
end clockPartitioning1;

protected function createBoolClockWhenClauses
  input BackendDAE.Shared inShared;
  input list<BackendDAE.Equation> inRemovedEqs;
  output list<BackendDAE.Equation> outRemovedEqs = inRemovedEqs;
protected
  BackendDAE.BasePartition basePartition;
algorithm
  for i in 1:arrayLength(inShared.partitionsInfo.basePartitions) loop
    basePartition := inShared.partitionsInfo.basePartitions[i];
    outRemovedEqs := match basePartition.clock
      local
        DAE.Exp c, e;
        BackendDAE.WhenEquation whenEq;
        BackendDAE.Equation eq;
      case DAE.BOOLEAN_CLOCK(c, _)
        equation
          e = DAE.CALL(Absyn.IDENT("$_clkfire"), {DAE.ICONST(i)}, DAE.callAttrBuiltinOther);
          whenEq = BackendDAE.WHEN_STMTS(c, {BackendDAE.NORETCALL(e, DAE.emptyElementSource)}, NONE());
          eq = BackendDAE.WHEN_EQUATION(0, whenEq, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        then eq::outRemovedEqs;
      else outRemovedEqs;
    end match;
  end for;
end createBoolClockWhenClauses;

protected function treatClockedStates
"Convert continuous equations in clocked partitions to clocked equations
 and call markClockedStates. author: rfranke"
  input list<BackendDAE.EqSystem> inSysts;
  input BackendDAE.Shared inShared;
  output list<BackendDAE.EqSystem> outSysts = {};
  output BackendDAE.Shared shared = inShared;
algorithm
  for syst1 in inSysts loop
    syst1 := match syst1
      local
        BackendDAE.EquationArray eqs;
        Integer idx;
        BackendDAE.SubPartition subPartition;
        String solverMethod;
        BackendDAE.EqSystem syst;
        list<BackendDAE.Equation> lstEqs;
        BackendDAE.Equation eq;
        list<DAE.ComponentRef> derVars = {};
      case syst as BackendDAE.EQSYSTEM(orderedEqs = eqs)
        algorithm
          BackendDAE.CLOCKED_PARTITION(idx) := syst.partitionKind;
          subPartition := shared.partitionsInfo.subPartitions[idx];
          solverMethod := BackendDump.optionString(subPartition.clock.solver);
          lstEqs := {};
          for i in 1:BackendDAEUtil.equationArraySize(eqs) loop
            eq := BackendEquation.equationNth1(eqs, i);
            (eq, (solverMethod, derVars)) := BackendEquation.traverseExpsOfEquation(eq, applySolverMethod1, (solverMethod, derVars));
            lstEqs := eq::lstEqs;
          end for;
          syst.orderedEqs := BackendEquation.listEquation(listReverse(lstEqs));
          shared := markClockedStates(syst, shared, derVars);
        then syst;
    end match;
    outSysts := BackendDAEUtil.clearEqSyst(syst1) :: outSysts;
  end for;
  outSysts := listReverse(outSysts);
end treatClockedStates;

protected function applySolverMethod1 "helper to applySolverMethod"
  input DAE.Exp inExp;
  input tuple<String, list<DAE.ComponentRef>> inTpl;
  output DAE.Exp outExp;
  output tuple<String, list<DAE.ComponentRef>> outTpl;
algorithm
  (outExp, outTpl) := Expression.traverseExpBottomUp(inExp, applySolverMethod, inTpl);
end applySolverMethod1;

protected function applySolverMethod
"Apply given solverMethod to convert continous-time to clocked expression.
 So far ImplicitEuler, replacing der(x) -> (x - previous(x))/interval().
 author: rfranke"
  input DAE.Exp inExp;
  input tuple<String, list<DAE.ComponentRef>> inTpl;
  output DAE.Exp outExp;
  output tuple<String, list<DAE.ComponentRef>> outTpl;
algorithm
  (outExp, outTpl) := match inExp
    local
      List<DAE.Exp> expLst;
      DAE.CallAttributes attr;
      DAE.ComponentRef x;
      DAE.Type ty;
      DAE.Exp exp;
      String inSolverMethod, outSolverMethod;
      list<DAE.ComponentRef> inDerVars;
    case DAE.CALL(path = Absyn.IDENT(name = "der"),
                  expLst = expLst as {DAE.CREF(componentRef = x)},
                  attr = attr as DAE.CALL_ATTR(ty = ty))
      algorithm
        (inSolverMethod, inDerVars) := inTpl;
        outSolverMethod := "ImplicitEuler";
        exp := DAE.CALL(Absyn.IDENT(name = "previous"), expLst, attr);
        exp := DAE.BINARY(DAE.CREF(x, ty), DAE.SUB(DAE.T_REAL_DEFAULT), exp);
        exp := DAE.BINARY(exp, DAE.DIV(DAE.T_REAL_DEFAULT),
                          DAE.CALL(Absyn.IDENT(name = "interval"), {},
                                   DAE.callAttrBuiltinImpureReal));
        if outSolverMethod <> inSolverMethod then
          Error.addCompilerWarning("Solved clocked continuous equations with " +
                                   outSolverMethod + " instead of specified " +
                                   inSolverMethod + ".");
        end if;
      then (exp, (outSolverMethod, x :: inDerVars));
    else (inExp, inTpl);
  end match;
end applySolverMethod;

protected function markClockedStates
"Collect discrete states and mark them for further processing.
 Use VarKind CLOCKED_STATE. Moreover set the isStartFixed flag,
 the fixed attribute and list the crefs of all discrete states in
 outShared.partitionsInfo.subPartitions[subPartIdx].prevVars."
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  input list<DAE.ComponentRef> derVars;
  output BackendDAE.Shared outShared = inShared;
protected
  BackendDAE.Equation eq;
  list<DAE.ComponentRef> prevVars = {};
  array<Boolean> isPrevVarArr, isDerVarArr;
  list<Integer> varIxs;
  BackendDAE.Var var;
  Integer idx;
  BackendDAE.SubPartition subPartition;
algorithm
  BackendDAE.CLOCKED_PARTITION(idx) := inSyst.partitionKind;
  subPartition := outShared.partitionsInfo.subPartitions[idx];

  isPrevVarArr := arrayCreate(BackendVariable.varsSize(inSyst.orderedVars), false);
  isDerVarArr := arrayCreate(BackendVariable.varsSize(inSyst.orderedVars), false);
  for cr in derVars loop
    varIxs := getVarIxs(cr, inSyst.orderedVars);
    for idx in varIxs loop
      arrayUpdate(isDerVarArr, idx, true);
    end for;
  end for;
  for i in 1:BackendDAEUtil.equationArraySize(inSyst.orderedEqs) loop
    eq := BackendEquation.equationNth1(inSyst.orderedEqs, i);
    (_, prevVars) := BackendEquation.traverseExpsOfEquation(eq, collectPrevVars, prevVars);
  end for;
  for i in 1:BackendDAEUtil.equationArraySize(inSyst.removedEqs) loop
    eq := BackendEquation.equationNth1(inSyst.removedEqs, i);
    (_, prevVars) := BackendEquation.traverseExpsOfEquation(eq, collectPrevVars, prevVars);
  end for;
  for cr in prevVars loop
    varIxs := getVarIxs(cr, inSyst.orderedVars);
    for idx in varIxs loop
      arrayUpdate(isPrevVarArr, idx, true);
    end for;
  end for;
  prevVars := {};
  for i in 1:arrayLength(isPrevVarArr) loop
    if isPrevVarArr[i] then
      var := BackendVariable.getVarAt(inSyst.orderedVars, i);
      var := BackendVariable.setVarKind(var, BackendDAE.CLOCKED_STATE(
               previousName = ComponentReference.crefPrefixPrevious(var.varName),
               isStartFixed = isDerVarArr[i]));
      var := BackendVariable.setVarFixed(var, true);
      BackendVariable.setVarAt(inSyst.orderedVars, i, var);
      prevVars := var.varName::prevVars;
    end if;
  end for;

  subPartition.prevVars := prevVars;
  arrayUpdate(outShared.partitionsInfo.subPartitions, idx, subPartition);
end markClockedStates;

protected function collectPrevVars
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inPrevVars;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outPrevVars;
algorithm
  (outExp, outPrevVars) := Expression.traverseExpBottomUp(inExp, collectPrevVars1, inPrevVars);
end collectPrevVars;

protected function collectPrevVars1
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inPrevCompRefs;
  output DAE.Exp outExp = inExp;
  output list<DAE.ComponentRef> outPrevCompRefs;
algorithm
  outPrevCompRefs := match inExp
    local
      DAE.ComponentRef cr;
    case DAE.CALL(path=Absyn.IDENT("previous"), expLst={DAE.CREF(cr, _)})
      then cr::inPrevCompRefs;
    else inPrevCompRefs;
  end match;
end collectPrevVars1;

protected function subClockPartitioning1
"Do subclock partitioning and inferencing and create clocked partitions and base clocks array."
  input list<BackendDAE.EqSystem> inSysts;
  input BackendDAE.Shared inShared;
  input list<DAE.ComponentRef> inHoldComps;
  output list<BackendDAE.EqSystem> outSysts = {};
  output BackendDAE.Shared outShared = inShared;
protected
  DAE.ClockKind baseClock;
  HashTable.HashTable varsPartition;
  Integer i, j, n, nBaseClocks;
  DAE.ComponentRef cr;
  array<Boolean> hasHoldOperator;
  list<BackendDAE.EqSystem> systs;
  list<BackendDAE.SubClock> lstSubClocks1, lstSubClocks = {};
  BackendDAE.PartitionsInfo partitionsInfo;
  array<BackendDAE.BasePartition> basePartitions;
  array<BackendDAE.SubPartition> subPartitions;
algorithm
  nBaseClocks := listLength(inSysts);
  basePartitions := arrayCreate(nBaseClocks, BackendDAE.BASE_PARTITION(DAE.INFERRED_CLOCK(), 0));
  varsPartition := HashTable.emptyHashTable();

  i := 0; j := 1;
  for syst in inSysts loop
    (systs, baseClock, lstSubClocks1) := subClockPartitioning(syst, outShared, i);
    n := listLength(systs);
    arrayUpdate(basePartitions, j, BackendDAE.BASE_PARTITION(baseClock, n));
    outSysts := listAppend(outSysts, systs);
    lstSubClocks := listAppend(lstSubClocks, lstSubClocks1);
    i := i + n;
    j := j + 1;
  end for;

  hasHoldOperator := arrayCreate(listLength(lstSubClocks), false);
  //Create hash cr -> subpartition index
  i := 1;
  for syst in outSysts loop
    for j in 1:BackendVariable.varsSize(syst.orderedVars) loop
      BackendDAE.VAR(varName=cr) := BackendVariable.getVarAt(syst.orderedVars, j);
      varsPartition := BaseHashTable.add((cr, i), varsPartition);
    end for;
    i := i + 1;
  end for;
  //Detect subpartitions whose variables are used in hold operator
  for cr in inHoldComps loop
    i := BaseHashTable.get(cr, varsPartition);
    arrayUpdate(hasHoldOperator, i, true);
  end for;

  i := 1;
  subPartitions := arrayCreate( listLength(lstSubClocks),
                                   BackendDAE.SUB_PARTITION(BackendDAE.DEFAULT_SUBCLOCK, false, {}) );
  for subclock in lstSubClocks loop
    arrayUpdate(subPartitions, i, BackendDAE.SUB_PARTITION(subclock, hasHoldOperator[i], {}));
    i := i + 1;
  end for;

  partitionsInfo := outShared.partitionsInfo;
  partitionsInfo.basePartitions := basePartitions;
  partitionsInfo.subPartitions := subPartitions;
  outShared.partitionsInfo := partitionsInfo;
end subClockPartitioning1;

protected function removeHoldExpsSyst
"Collect clocked variable, which used in continuous partition.
 Replace expression hold(expr_i) -> $getPart(expr_i)."
  input list<BackendDAE.EqSystem> inSysts;
  output list<BackendDAE.EqSystem> outSysts = {};
  output list<DAE.ComponentRef> outHoldComps = {};
algorithm
  for syst1 in inSysts loop
    syst1 := match syst1
      local
        BackendDAE.EquationArray eqs;
        BackendDAE.Variables vars;
        BackendDAE.EqSystem syst;
        list<BackendDAE.Equation> lstEqs;
        Integer i;
        BackendDAE.Equation eq;
      case syst as BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqs)
        algorithm
          lstEqs := {};
          for i in 1:BackendDAEUtil.equationArraySize(eqs) loop
            eq := BackendEquation.equationNth1(eqs, i);
            (eq, outHoldComps) := BackendEquation.traverseExpsOfEquation(eq, removeHoldExp1, outHoldComps);
            lstEqs := eq::lstEqs;
          end for;
          syst.orderedEqs := BackendEquation.listEquation(listReverse(lstEqs));
        then syst;
    end match;
    outSysts := BackendDAEUtil.clearEqSyst(syst1) :: outSysts;
  end for;
end removeHoldExpsSyst;

protected function removeHoldExp1
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inComps;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outComps;
algorithm
  (outExp, outComps) := Expression.traverseExpBottomUp(inExp, removeHoldExp, inComps);
end removeHoldExp1;

protected function removeHoldExp
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inComps;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outComps;
algorithm
  (outExp, outComps) := match inExp
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
    case DAE.CALL(Absyn.IDENT("hold"), {e}, _)
      equation DAE.CREF(cr, _) = e;
      then (substGetPartition(e), cr::inComps);
    else (inExp, inComps);
  end match;
end removeHoldExp;

protected function subClockPartitioning
"Do sub-partitioning for base partition and get base clock
 and vars, equations and sub-clocks of subpartitions."
  input BackendDAE.EqSystem inEqSystem;
  input BackendDAE.Shared inShared;
  input Integer off;
  output list<BackendDAE.EqSystem> outSysts;
  output DAE.ClockKind outBaseClock;
  output list<BackendDAE.SubClock> outSubClocks;
protected
  DAE.FunctionTree funcs;
  BackendDAE.EquationArray eqs, clockEqs;
  BackendDAE.Variables vars, clockVars;
  BackendDAE.EqSystem clockSyst;
  BackendDAE.IncidenceMatrix m, mT, rm, rmT;
  Integer partitionsCnt;
  array<Integer> partitions, reqsPartitions;
  list<BackendDAE.Equation> newClockEqs;
  list<BackendDAE.Var> newClockVars;
  array<Option<Boolean>> contPartitions;
  array<tuple<BackendDAE.SubClock, Integer>> subclocksTree;
  BackendDAE.StrongComponents clockComps;
  array<Integer> subclksCnt;
  array<Integer> order;
  array<BackendDAE.SubClock> subclocks, subclocksOutArr;
  array<Boolean> clockedEqsMask, clockedVarsMask, usedVars, usedRemovedVars;
algorithm
  funcs := BackendDAEUtil.getFunctions(inShared);
  BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqs) := inEqSystem;

  (clockEqs, clockedEqsMask) := splitClockEqs(eqs);
  (clockVars, clockedVarsMask)  := splitClockVars(vars);

  (m, mT) := BackendDAEUtil.incidenceMatrixMasked(inEqSystem, BackendDAE.SUBCLOCK_IDX(), clockedEqsMask, SOME(funcs));
  (rm, rmT) := BackendDAEUtil.removedIncidenceMatrix(inEqSystem, BackendDAE.SUBCLOCK_IDX(), SOME(funcs));

  reqsPartitions := arrayCreate(arrayLength(rm), 0);
  partitions := arrayCreate(arrayLength(m), 0);
  usedRemovedVars := arrayCreate(arrayLength(rmT), false);
  usedVars := arrayCreate(arrayLength(mT), false);
  partitionsCnt := partitionIndependentBlocksMasked(m, mT, rm, rmT, clockedEqsMask, partitions, reqsPartitions, usedVars, usedRemovedVars);

  //Detect clocked continuous partitions and create new subclock equations
  (newClockEqs, newClockVars, contPartitions, subclksCnt)
      := collectSubclkInfo(eqs, inEqSystem.removedEqs, partitionsCnt, partitions, reqsPartitions, vars, mT);

  clockEqs := BackendEquation.addEquations(newClockEqs, clockEqs);
  clockVars := BackendVariable.addVars(newClockVars, clockVars);
  clockSyst := BackendDAEUtil.createEqSystem(clockVars, clockEqs, {});

  //Solve clock equations
  BackendDAE.DAE({clockSyst}, _) := BackendDAEUtil.transformBackendDAE (
                                      BackendDAE.DAE({clockSyst}, inShared), NONE(), NONE(), NONE() );
  BackendDAE.EQSYSTEM( orderedVars=clockVars, orderedEqs=clockEqs,
                       matching=BackendDAE.MATCHING(_, _, clockComps) ) := clockSyst;

  maskMatrix(mT, clockedVarsMask);
  maskMatrix(rmT, clockedVarsMask);

  outSysts := partitionIndependentBlocksSplitBlocks(partitionsCnt, inEqSystem, partitions, reqsPartitions, mT, rmT, false);

  (subclocksTree, outBaseClock) := resolveClocks(clockVars, clockEqs, clockComps);
  (subclocks, order) := collectSubClocks(clockVars, partitionsCnt, contPartitions, subclksCnt, subclocksTree);

  if arrayLength(subclocks) <> partitionsCnt or arrayLength(order) <> partitionsCnt then
    Error.addInternalError("SynchronousFeatures.subClockPartitioning failed", sourceInfo());
    fail();
  end if;

  (outSysts, _) := List.map2Fold(outSysts, makeClockedSyst, order, off, 1);
  outSubClocks := {};
  subclocksOutArr := arrayCopy(subclocks);
  for i in List.intRange(arrayLength(subclocksOutArr)) loop
    arrayUpdate(subclocksOutArr,order[i],subclocks[i]);
  end for;
    outSubClocks := arrayList(subclocksOutArr);
end subClockPartitioning;

protected function maskMatrix
  input array<list<Integer>> m;
  input array<Boolean> mask;
algorithm
  for i in 1:arrayLength(m) loop
    if not mask[i] then
      arrayUpdate(m, i, {});
    end if;
  end for;
end maskMatrix;

protected function makeClockedSyst
  input BackendDAE.EqSystem inSyst;
  input array<Integer> order;
  input Integer inOff;
  input Integer inIdx;
  output BackendDAE.EqSystem outSyst = inSyst;
  output Integer outIdx = inIdx + 1;
algorithm
  outSyst.partitionKind := BackendDAE.CLOCKED_PARTITION(order[inIdx] + inOff);
end makeClockedSyst;

protected function resolveClocks
"Get array of subClocks[varIdx] and common base from clock equation system."
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqs;
  input BackendDAE.StrongComponents inComps;
  output array<tuple<BackendDAE.SubClock, Integer>> outSubClocks;
  output DAE.ClockKind outClockKind = DAE.INFERRED_CLOCK();
protected
  BackendDAE.Equation eq;
  DAE.Exp exp;
  DAE.ClockKind clockKind;
  BackendDAE.SubClock subClock;
  BackendDAE.StrongComponent comp;
  Integer eqIdx, varIdx, updateIdx, parentIdx;
  MMath.Rational clockFactor;
  DAE.ClockKind branchClockKind;
  array<DAE.ClockKind> clockKinds;
algorithm
  clockFactor := MMath.RAT1;
  clockKinds := arrayCreate(BackendVariable.varsSize(inVars), DAE.INFERRED_CLOCK());
  outSubClocks := arrayCreate(BackendVariable.varsSize(inVars), (BackendDAE.DEFAULT_SUBCLOCK, 0));
  exp := DAE.CLKCONST(DAE.INFERRED_CLOCK());
  for comp in inComps loop
    outClockKind := matchcontinue comp
      case BackendDAE.SINGLEEQUATION(eqIdx, varIdx)
        algorithm
          eq := BackendEquation.equationNth1(inEqs, eqIdx);
          exp := match eq
            local
              DAE.Exp e;
            case BackendDAE.EQUATION(scalar = e) then e;
            case BackendDAE.SOLVED_EQUATION(exp = e) then e;
          end match;
          (clockKind, (subClock, parentIdx)) := getSubClock(exp, inVars, outSubClocks);
          if parentIdx == varIdx then
            // can't determine clock from var itself;
            // use alternative exp of unsolved equation instead
            exp := match eq
              local
                DAE.Exp e;
              case BackendDAE.EQUATION(exp = e) then e;
              else exp;
            end match;
            (clockKind, (subClock, parentIdx)) := getSubClock(exp, inVars, outSubClocks);
          end if;

          if parentIdx == 0 then
            // start clock of new branch
            branchClockKind := DAE.INFERRED_CLOCK();
          else
            // get previously obtained clock
            branchClockKind := arrayGet(clockKinds, parentIdx);
          end if;

          (branchClockKind, _) := setClockKind(branchClockKind, clockKind, clockFactor);
          arrayUpdate(clockKinds, varIdx, branchClockKind);
          (clockKind, clockFactor) := setClockKind(outClockKind, clockKind, clockFactor);
          if parentIdx == 0 then
            // adapt uppermost subClock in a branch to possibly multiple bases
            subClock.factor := MMath.multRational(subClock.factor, clockFactor);
          end if;
          updateIdx := match branchClockKind
            case DAE.INFERRED_CLOCK()
              guard parentIdx <> 0
              algorithm
                // apply inverse clock conversion to a parent without base
                // as the clock propagates backwards
                subClock.factor := MMath.divRational(MMath.RAT1, subClock.factor);
                subClock.shift := MMath.subRational(MMath.RAT0, subClock.shift);
                updateIdx := parentIdx;
                (_, parentIdx) := arrayGet(outSubClocks, updateIdx);
              then
                updateIdx;
            else
              // regular subClock update
              varIdx;
          end match;
          arrayUpdate(outSubClocks, updateIdx, (subClock, parentIdx));
          /*
            print("var " + intString(varIdx) + ": " +
                  BackendDump.equationString(eq) + " ->\n    " +
                  ExpressionDump.printExpStr(exp) + ": " +
                  BackendDump.subClockString(subClock) + "\n    update " +
                  intString(updateIdx) + " parent " + intString(parentIdx) + ".\n");
          */
        then clockKind;
      else
        algorithm
          Error.addInternalError("SynchronousFeatures.resolveClocks failed for " +
                                 ExpressionDump.printExpStr(exp) + ".\n", sourceInfo());
        then fail();
    end matchcontinue;
  end for;
end resolveClocks;

protected function getSubClock
"Get base clock and subclock from expression"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  input array<tuple<BackendDAE.SubClock, Integer>> inSubClocks;
  output DAE.ClockKind outClockKind;
  output tuple<BackendDAE.SubClock, Integer> outSubClock;
algorithm
  (outClockKind, outSubClock) := match inExp
    local
      DAE.Exp e1, e2, e3, solverMethod;
      String solverMethodStr;
      BackendDAE.SubClock subClock;
      DAE.ClockKind clockKind;
      MMath.Rational factor, shift;
      DAE.ComponentRef cr;
      list<Integer> varIxs;
      BackendDAE.Var var;
      Integer i1, i2, parentIdx;

    case DAE.CLKCONST(DAE.SOLVER_CLOCK(e1, solverMethod))
      algorithm
        (clockKind, (subClock, parentIdx)) := getSubClock1(e1, inVars, inSubClocks);
        DAE.SCONST(solverMethodStr) := solverMethod;
        subClock.solver := SOME(solverMethodStr);
      then
        (clockKind, (subClock, parentIdx));

    case DAE.CLKCONST(outClockKind)
      then
        (outClockKind, (BackendDAE.DEFAULT_SUBCLOCK, 0));

    case DAE.CALL(path = Absyn.IDENT("subSample"), expLst = {e1, e2})
      algorithm
        (clockKind, (subClock, parentIdx)) := getSubClock1(e1, inVars, inSubClocks);
        DAE.ICONST(i1) := e2;
        subClock.factor := MMath.multRational(subClock.factor, MMath.RATIONAL(i1, 1));
      then
        (clockKind, (subClock, parentIdx));

    case DAE.CALL(path = Absyn.IDENT("superSample"), expLst = {e1, e2})
      algorithm
        (clockKind, (subClock, parentIdx)) := getSubClock1(e1, inVars, inSubClocks);
        DAE.ICONST(i1) := e2;
        subClock.factor := MMath.multRational(subClock.factor, MMath.RATIONAL(1, i1));
      then
        (clockKind, (subClock, parentIdx));

    case DAE.CALL(path = Absyn.IDENT("shiftSample"), expLst = {e1, e2, e3})
      algorithm
        (clockKind, (subClock, parentIdx)) := getSubClock1(e1, inVars, inSubClocks);
        DAE.ICONST(i1) := e2; DAE.ICONST(i2) := e3;
        subClock.shift := MMath.addRational(subClock.shift, MMath.RATIONAL(i1, i2));
      then
        (clockKind, (subClock, parentIdx));

    case DAE.CALL(path = Absyn.IDENT("backSample"), expLst = {e1, e2, e3})
      algorithm
        (clockKind, (subClock, parentIdx)) := getSubClock1(e1, inVars, inSubClocks);
        DAE.ICONST(i1) := e2; DAE.ICONST(i2) := e3;
        subClock.shift := MMath.subRational(subClock.shift, MMath.RATIONAL(i1, i2));
      then
        (clockKind, (subClock, parentIdx));

    case DAE.CREF(cr, _)
      algorithm
        i1 := getVarIdx(cr, inVars);
        (subClock, _) := arrayGet(inSubClocks, i1);
      then
        (DAE.INFERRED_CLOCK(), (subClock, i1));

    else
      algorithm
        Error.addInternalError("SynchronousFeatures.getSubClock failed for " +
                               ExpressionDump.printExpStr(inExp) + ".\n", sourceInfo());
      then
        fail();
  end match;
end getSubClock;

protected function getSubClock1
"Helper for recursion in getSubClock"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  input array<tuple<BackendDAE.SubClock, Integer>> inSubClocks;
  output DAE.ClockKind outClockKind;
  output tuple<BackendDAE.SubClock, Integer> outSubClock;
protected
  BackendDAE.SubClock subClock;
  Integer parentIdx;
algorithm
  (outClockKind, (subClock, parentIdx)) := getSubClock(inExp, inVars, inSubClocks);
  parentIdx := match inExp
    local
      DAE.ComponentRef cr;
    case DAE.CREF(cr, _)
      then getVarIdx(cr, inVars);
    else parentIdx;
  end match;
  outSubClock := (subClock, parentIdx);
end getSubClock1;

protected function setClockKind
  input DAE.ClockKind inOldClockKind;
  input DAE.ClockKind inClockKind;
  input MMath.Rational inClockFactor;
  output DAE.ClockKind outClockKind;
  output MMath.Rational outClockFactor;
algorithm
  (outClockKind, outClockFactor) := match (inOldClockKind, inClockKind)
    local
      DAE.Exp e1, e2, ei1, ei2, er1, er2, es1, es2;
      Integer i1, i2, ie1, ie2;
      Real r1, r2;
      String s1, s2;
    case (DAE.INFERRED_CLOCK(), _) then (inClockKind, inClockFactor);
    case (_, DAE.INFERRED_CLOCK()) then (inOldClockKind, inClockFactor);
    case (DAE.INTEGER_CLOCK(intervalCounter = e1, resolution = ei1),
          DAE.INTEGER_CLOCK(intervalCounter = e2, resolution = ei2))
      guard
        Expression.expEqual(e1, e2) and Expression.expEqual(ei1, ei2)
      then (inClockKind, inClockFactor);
    case (DAE.INTEGER_CLOCK(intervalCounter = e1, resolution = ei1),
          DAE.INTEGER_CLOCK(intervalCounter = e2, resolution = ei2))
      // stay with old clock and adapt clock factor to new clock
      algorithm
        DAE.ICONST(ie1) := e1;
        DAE.ICONST(ie2) := e2;
        DAE.ICONST(i1) := ei1;
        DAE.ICONST(i2) := ei2;
      then (inOldClockKind, MMath.divRational(MMath.multRational(inClockFactor, MMath.RATIONAL(ie2, i2)), MMath.RATIONAL(ie1, i1)));
    case (DAE.REAL_CLOCK(interval = e1),
          DAE.REAL_CLOCK(interval = e2))
      guard
        Expression.expEqual(e1, e2)
      then (inClockKind, inClockFactor);
    case (DAE.BOOLEAN_CLOCK(condition = e1, startInterval = er1),
          DAE.BOOLEAN_CLOCK(condition = e2, startInterval = er2))
      guard
        Expression.expEqual(e1, e2) and Expression.expEqual(er1, er2)
      then (inClockKind, inClockFactor);
    case (DAE.SOLVER_CLOCK(c = e1, solverMethod = es1),
          DAE.SOLVER_CLOCK(c = e2, solverMethod = es2))
      guard
        Expression.expEqual(e1, e2) and Expression.expEqual(es1, es2)
      then (inClockKind, inClockFactor);
    else
      equation Error.addMessage(Error.CLOCK_CONFLICT, {});
      then fail();
  end match;
end setClockKind;

protected function getSubClkFromVars
  input Integer partitionIdx;
  input Integer clkIdx;
  input BackendDAE.Variables inVars;
  input array<tuple<BackendDAE.SubClock, Integer>> inSubClocks;
  input array<list<Integer>> parents;
  input array<Integer> partitions;
  output BackendDAE.SubClock osubClk;
protected
  String clkName;
  DAE.ComponentRef cr;
  Integer varIdx, parent;
  list<Integer> lstParents;
algorithm
  clkName := "$subclk" + intString(partitionIdx) + "_" + intString(clkIdx);
  cr := DAE.CREF_IDENT(clkName, DAE.T_CLOCK_DEFAULT, {});
  varIdx := getVarIdx(cr, inVars);

  arrayUpdate(partitions, varIdx, partitionIdx);

  lstParents := parents[partitionIdx];
  (osubClk, parent) := arrayGet(inSubClocks, varIdx);
  if parent <> 0 then
    arrayUpdate(parents, partitionIdx, parent::lstParents);
  end if;
end getSubClkFromVars;

protected function getVarIdx
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output Integer idx;
protected
  list<Integer> ixs;
algorithm
  ixs := getVarIxs(cr, vars);
  if listLength(ixs) <> 1 then
    Error.addInternalError("SynchronousFeatures.getVarIdx failed for " +
                           ComponentReference.crefStr(cr) + ".\n", sourceInfo());
    fail();
  end if;
  idx := List.first(ixs);
end getVarIdx;

protected function collectSubClocks
  input BackendDAE.Variables inVars;
  input Integer inPartitionsCnt;
  input array<Option<Boolean>> contPartitions;
  input array<Integer> clocksCnt;
  input array<tuple<BackendDAE.SubClock, Integer>> inSubClocks "idx: var";
  output array<BackendDAE.SubClock> outSubClocks "idx: partition";
  output array<Integer> order;
protected
  Integer i, j, partClocksCnt;
  BackendDAE.SubClock subClk, subClk1;
  Option<Boolean> isCont;
  MMath.Rational factor, shift;
  array<list<Integer>> parents;
  array<Integer> partitions;
algorithm
  parents := arrayCreate(inPartitionsCnt, {});
  partitions := arrayCreate(BackendVariable.varsSize(inVars), 0);
  outSubClocks := arrayCreate(inPartitionsCnt, BackendDAE.DEFAULT_SUBCLOCK);
  for i in 1:inPartitionsCnt loop
    partClocksCnt := arrayGet(clocksCnt, i) - 1;
    assert(partClocksCnt <> 0, "SynchronousFeatures.collectSubClocks failed");
    subClk := getSubClkFromVars(i, 1, inVars, inSubClocks, parents, partitions);
    if partClocksCnt > 1 then
        for j in 2:partClocksCnt loop
          subClk1 := getSubClkFromVars(i, j, inVars, inSubClocks, parents, partitions);
          subClk := setSubClock(SOME(subClk), subClk1);
        end for;
      end if;
    isCont := arrayGet(contPartitions, i);
    subClk := match (isCont, subClk)
      case (SOME(true), BackendDAE.SUBCLOCK(factor, shift, NONE()))
        then BackendDAE.SUBCLOCK(factor, shift, SOME(""));
      else subClk;
    end match;
    arrayUpdate(outSubClocks, i, subClk);
  end for;

  order := arrayCreate(inPartitionsCnt, 0);
  i := 1;
  for j in sortSubPartitions(inPartitionsCnt, parents, partitions) loop
    arrayUpdate(order, j, i);
    i := i + 1;
  end for;
end collectSubClocks;

protected function sortSubPartitions
  input Integer partitionsCnt;
  input array<list<Integer>> parents;
  input array<Integer> partitions;
  output list<Integer> order = {};
protected
  Integer partIdx;
  array<list<Integer>> children = arrayCreate(partitionsCnt, {});
  array<Integer> colors = arrayCreate(partitionsCnt, 0);
algorithm
  /*Build subpartitions dependenct graph*/
  for i in 1:partitionsCnt loop
    for parent in parents[i] loop
      partIdx := partitions[parent];
      if partIdx <> 0 then
        arrayUpdate(children, partIdx, List.unionElt(i, children[partIdx]));
      end if;
    end for;
  end for;
  /*Toposort with loop detection*/
  for i in 1:partitionsCnt loop
    order := dfs(children, i, colors, order);
  end for;
end sortSubPartitions;

protected function dfs
  input array<list<Integer>> children;
  input Integer i;
  input array<Integer> colors;
  input list<Integer> inOrder;
  output list<Integer> outOrder = inOrder;
algorithm
  if colors[i] == 1 then
    Error.addCompilerError("Loop detected in subclock partitioning");
    fail();
  end if;
  if colors[i] == 0 then
    arrayUpdate(colors, i, 1);
    for child in children[i] loop
        outOrder := dfs(children, child, colors, outOrder);
    end for;
    outOrder := i::outOrder;
    arrayUpdate(colors, i, 2);
  end if;
end dfs;

protected function setSolverMethod
  input Option<String> oldSolverMethod;
  input Option<String> newSolverMethod;
  output Option<String> outSolverMethod;
algorithm
  outSolverMethod := match (oldSolverMethod, newSolverMethod)
    local
      String oldMethod, newMethod;
    case (NONE(), _) then newSolverMethod;
    case (_, NONE()) then oldSolverMethod;
    case (SOME(oldMethod), SOME(newMethod))
      guard(oldMethod == newMethod)
      then oldSolverMethod;
    else
      algorithm
        oldMethod := BackendDump.optionString(oldSolverMethod);
        newMethod := BackendDump.optionString(newSolverMethod);
        Error.addMessage(Error.SUBCLOCK_CONFLICT, {"solver", oldMethod, newMethod});
      then fail();
  end match;

end setSolverMethod;

protected function setSubClock
  input Option<BackendDAE.SubClock> oldSubClk;
  input BackendDAE.SubClock newSubClk;
  output BackendDAE.SubClock outSubClk;
algorithm
  outSubClk := match oldSubClk
    local
      MMath.Rational oldFactor, oldShift, newFactor, newShift;
      Option<String> oldSolverMethod, newSolverMethod;
    case NONE() then newSubClk;
    case SOME(BackendDAE.SUBCLOCK(oldFactor, oldShift, oldSolverMethod))
      algorithm
        BackendDAE.SUBCLOCK(newFactor, newShift, newSolverMethod) := newSubClk;
        newFactor := setFactor(oldFactor, newFactor);
        newShift := setShift(oldShift, newShift);
        newSolverMethod := setSolverMethod(oldSolverMethod, newSolverMethod);
      then BackendDAE.SUBCLOCK(newFactor, newShift, newSolverMethod);
  end match;
end setSubClock;

protected function setFactor
  input MMath.Rational oldVal;
  input MMath.Rational newVal;
  output MMath.Rational outVal;
algorithm
  outVal := match (oldVal, newVal)
    case (MMath.RATIONAL(1, 1), _) then newVal;
    case (_, MMath.RATIONAL(1, 1)) then oldVal;
    else
      algorithm
        if not MMath.equals(oldVal, newVal) then
          Error.addMessage(Error.SUBCLOCK_CONFLICT, {"factor", MMath.rationalString(oldVal), MMath.rationalString(newVal)});
          fail();
        end if;
     then newVal;
  end match;
end setFactor;

protected function setShift
  input MMath.Rational oldVal;
  input MMath.Rational newVal;
  output MMath.Rational outVal;
algorithm
  outVal := match (oldVal, newVal)
    case (MMath.RATIONAL(0, _), _) then newVal;
    case (_, MMath.RATIONAL(0, _)) then oldVal;
    else
      algorithm
        if not MMath.equals(oldVal, newVal) then
          Error.addMessage(Error.SUBCLOCK_CONFLICT, {"shift", MMath.rationalString(oldVal), MMath.rationalString(newVal)});
          fail();
        end if;
     then newVal;
  end match;
end setShift;

protected function collectSubclkInfoExp
  input DAE.Exp inExp;
  input tuple< list<BackendDAE.Equation>, list<BackendDAE.Var>, array<Option<Boolean>>, SourceInfo,
               array<Integer>, Integer, array<Integer>, BackendDAE.Variables, BackendDAE.IncidenceMatrix > inTpl;
  output DAE.Exp outExp;
  output tuple< list<BackendDAE.Equation>, list<BackendDAE.Var>, array<Option<Boolean>>, SourceInfo,
               array<Integer>, Integer, array<Integer>, BackendDAE.Variables, BackendDAE.IncidenceMatrix > outTpl;
protected
  list<BackendDAE.Equation> newEqs;
  list<BackendDAE.Var> newVars;
  array<Option<Boolean>> contPartitions;
  Integer partitionIdx;
  array<Integer> partitions;
  BackendDAE.Variables vars;
  BackendDAE.IncidenceMatrix mT;
  Absyn.Path path;
  list<DAE.Exp> expLst;
  DAE.CallAttributes attr;
  array<Integer> clksCnt;
  Integer clkCnt;
  SourceInfo source;
algorithm
  (newEqs, newVars, contPartitions, source, clksCnt, partitionIdx, partitions, vars, mT) := inTpl;
  clkCnt := arrayGet(clksCnt, partitionIdx);
  (outExp, newEqs, newVars, clkCnt) := match inExp
    case DAE.CALL(path, expLst, attr)
      then
        collectSubclkInfoCall( path, expLst, attr, newEqs, newVars, contPartitions, partitionIdx, clkCnt,
                               partitions, vars, mT, source );
    else
      (inExp, newEqs, newVars, clkCnt);
  end match;
  arrayUpdate(clksCnt, partitionIdx, clkCnt);
  outTpl := (newEqs, newVars, contPartitions, source, clksCnt, partitionIdx, partitions, vars, mT);
end collectSubclkInfoExp;

protected function createSubClockVar
  input Integer inPartitionIdx;
  input Integer inClkCnt;
  input Absyn.Path inPath;
  input list<DAE.Exp> inExpLst;
  input DAE.CallAttributes inAttr;
  input array<Integer> inPartitions;
  input BackendDAE.Variables inVars;
  input BackendDAE.IncidenceMatrix mT;
  output BackendDAE.Var outVar;
  output BackendDAE.Equation outEq;
protected
  DAE.ComponentRef cr;
  list<Integer> varIxs;
  Integer i;
  DAE.Exp e, subclk;
algorithm
  DAE.CREF(componentRef = cr) := List.first(inExpLst);
  (_, varIxs) := BackendVariable.getVar(cr, inVars);
  i := List.first(varIxs);
  i := List.first(arrayGet(mT, i)) "Equation idx, containing var";
  i := arrayGet(inPartitions, i) "Partitions, from which var get";
  subclk := DAE.CREF(getSubClkName(i, 1), DAE.T_CLOCK_DEFAULT);
  e := DAE.CALL(inPath, subclk::List.rest(inExpLst), inAttr);
  (outVar, outEq) := createSubClock(inPartitionIdx, inClkCnt, e);
end createSubClockVar;

protected function setContClockedPartition
  input Boolean inIsContClockedPartition;
  input Integer inPartitionIdx;
  input array<Option<Boolean>> inContPartitions;
  input SourceInfo source;
protected
  Option<Boolean> isContClockedPartition;
  Boolean isContClockedPrevPartition;
algorithm
  isContClockedPartition := arrayGet(inContPartitions, inPartitionIdx);
  isContClockedPartition := match isContClockedPartition
    case NONE() then
      SOME(inIsContClockedPartition);
    case SOME(isContClockedPrevPartition) then
      SOME(inIsContClockedPartition or isContClockedPrevPartition);
  end match;
  arrayUpdate(inContPartitions, inPartitionIdx, isContClockedPartition);
end setContClockedPartition;

protected function collectSubclkInfoCall
  input Absyn.Path inPath;
  input list<DAE.Exp> inExpLst;
  input DAE.CallAttributes inAttr;
  input list<BackendDAE.Equation> inNewEqs;
  input list<BackendDAE.Var> inNewVars;
  input array<Option<Boolean>> inContPartitions;
  input Integer inPartitionIdx;
  input Integer inClkCnt;
  input array<Integer> inPartitions;
  input BackendDAE.Variables inVars;
  input BackendDAE.IncidenceMatrix mT;
  input SourceInfo source;
  output DAE.Exp outExp;
  output list<BackendDAE.Equation> outNewEqs;
  output list<BackendDAE.Var> outNewVars;
  output Integer outClkCnt;
algorithm
  (outExp, outNewEqs, outNewVars, outClkCnt) := match (inPath, listLength(inExpLst))
    local
      BackendDAE.Var var;
      BackendDAE.Equation eq;
    case (Absyn.IDENT("der"), _)
      algorithm
        setContClockedPartition(true, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("delay"), _)
      algorithm
        setContClockedPartition(true, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("spatialDistribution"), _)
      algorithm
        setContClockedPartition(true, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("initial"), _)
      algorithm
        setContClockedPartition(true, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("terminal"), _)
      algorithm
        setContClockedPartition(true, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("smooth"), _)
      algorithm
        setContClockedPartition(true, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("sample"), 3)
      algorithm
        setContClockedPartition(true, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("pre"), _)
      algorithm
        setContClockedPartition(true, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("edge"), _)
      algorithm
        setContClockedPartition(true, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("change"), _)
      algorithm
        setContClockedPartition(true, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("reinit"), _)
      algorithm
        setContClockedPartition(true, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);

    case (Absyn.IDENT("previous"), _)
      algorithm
        setContClockedPartition(false, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("firstTick"), _)
      algorithm
        setContClockedPartition(false, inPartitionIdx, inContPartitions, source);
      then
        // Note: remove optional argument (inExpLst) to avoid algebraic loop
        (DAE.CALL(inPath, {}, inAttr), inNewEqs, inNewVars, inClkCnt);
    case (Absyn.IDENT("interval"), _)
      algorithm
        setContClockedPartition(false, inPartitionIdx, inContPartitions, source);
      then
        // Note: remove optional argument (inExpLst) to avoid algebraic loop
        (DAE.CALL(inPath, {}, inAttr), inNewEqs, inNewVars, inClkCnt);

    case (Absyn.IDENT("sample"), 2)
      algorithm
        (var, eq) := createSubClock(inPartitionIdx, inClkCnt, listGet(inExpLst, 2));
      then
        (substGetPartition(listGet(inExpLst, 1)), eq::inNewEqs, var::inNewVars, inClkCnt + 1);
    case (Absyn.IDENT("subSample"), 2)
      then
        createSubClockVarFactor( inPartitionIdx, inClkCnt, inPath, inExpLst, inAttr,
                                 inPartitions, inVars, mT, inNewEqs, inNewVars );
    case (Absyn.IDENT("superSample"), 2)
      then
        createSubClockVarFactor( inPartitionIdx, inClkCnt, inPath, inExpLst, inAttr,
                                 inPartitions, inVars, mT, inNewEqs, inNewVars );
    case (Absyn.IDENT("shiftSample"), 3)
      equation
        (var, eq) = createSubClockVar(inPartitionIdx, inClkCnt, inPath, inExpLst, inAttr, inPartitions, inVars, mT);
      then
        (substGetPartition(listGet(inExpLst, 1)), eq::inNewEqs, var::inNewVars, inClkCnt + 1);
    case (Absyn.IDENT("backSample"), 3)
      equation
        (var, eq) = createSubClockVar(inPartitionIdx, inClkCnt, inPath, inExpLst, inAttr, inPartitions, inVars, mT);
      then
        (substGetPartition(listGet(inExpLst, 1)), eq::inNewEqs, var::inNewVars, inClkCnt + 1);
    case (Absyn.IDENT("noClock"), 1)
      then
        (substGetPartition(listGet(inExpLst, 1)), inNewEqs, inNewVars, inClkCnt);
    else
      (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);
  end match;
end collectSubclkInfoCall;

protected function createSubClockVarFactor
  input Integer inPartitionIdx;
  input Integer inClkCnt;
  input Absyn.Path inPath;
  input list<DAE.Exp> inExpLst;
  input DAE.CallAttributes inAttr;
  input array<Integer> inPartitions;
  input BackendDAE.Variables inVars;
  input BackendDAE.IncidenceMatrix mT;
  input list<BackendDAE.Equation> inNewEqs;
  input list<BackendDAE.Var> inNewVars;
  output DAE.Exp outExp;
  output list<BackendDAE.Equation> outNewEqs;
  output list<BackendDAE.Var> outNewVars;
  output Integer outClkCnt;
protected
  DAE.Exp e;
algorithm
  e := substGetPartition(List.first(inExpLst));
  (outExp, outNewEqs, outNewVars, outClkCnt) := match listGet(inExpLst, 2)
    local
      BackendDAE.Var var;
      BackendDAE.Equation eq;
    case DAE.ICONST(0)
      then (e, inNewEqs, inNewVars, inClkCnt);
    else
      equation
        (var, eq) = createSubClockVar(inPartitionIdx, inClkCnt, inPath, inExpLst, inAttr, inPartitions, inVars, mT);
      then
        (e, eq::inNewEqs, var::inNewVars, inClkCnt + 1);
    end match;
end createSubClockVarFactor;

protected function substGetPartition
  input DAE.Exp inExp;
  output DAE.Exp outExp;
protected
  DAE.CallAttributes attrs;
algorithm
  attrs := DAE.CALL_ATTR(Expression.typeof(inExp), false, true, true, false, DAE.NO_INLINE(), DAE.NO_TAIL());
  outExp := DAE.CALL(Absyn.IDENT("$getPart"), {inExp}, attrs);
end substGetPartition;

protected function getSubClkName
  input Integer inPartitionIdx;
  input Integer inClkIdx;
  input DAE.Type inTy = DAE.T_CLOCK_DEFAULT;
  output DAE.ComponentRef outRef;
protected
  String name;
algorithm
  name := "$subclk" + intString(inPartitionIdx) + "_" + intString(inClkIdx);
  outRef := DAE.CREF_IDENT(name, inTy, {});
end getSubClkName;

protected function createSubClock
  input Integer inPartitionIdx;
  input Integer inCnt;
  input DAE.Exp inExp;
  output BackendDAE.Var outVar;
  output BackendDAE.Equation outEq;
protected
  DAE.Type ty;
  DAE.ComponentRef cr;
algorithm
  ty := DAE.T_CLOCK_DEFAULT;
  cr := getSubClkName(inPartitionIdx, inCnt, ty);
  (outVar, outEq) := createEqVarPair(cr, ty, inExp);
end createSubClock;

protected function collectSubclkInfo
"Create new clock equations and variables from equations:
  - r = sample(e, clk) -- clockVar: $subclki_n; clockEq: $subclki_n = clk; eq: r = $getPart(e);
  - r = subSample(e, e1) -- clockVar: $subclki_n; clockEq: $subclki_n = subSample($subclkj_1, e1); eq: r = $getPart(e);
  - r = shiftSample(e, e1, e2) -- clockVar: $subclki_n; clockEq: $subclki_n = shiftSample($subclkj_1, e1, e2); eq: r = $getPart(e);
  - r = backSample(e, e1, e2) -- clockVar: $subclki_n; clockEq: $subclki_n = backSample($subclkj_1, e1, e2); eq: r = $getPart(e);
  - r = noClock(e) -- eq: r = $getPart(e);
  where subclki_n -- n subclock of partition, which r expression belongs;
        subclkj_n -- n subclock of partition, which e expression belongs;
        clockVar, clockEq -- new clock variables and equations;
        eq -- replaced equation.
 Detect clocked continuous partitions according the rule:
  If equation contains operator der, delay, spatialDistribution, event related operators
  , or when clause, it is a clocked continuous equation.
  If a clocked partition is not a clocked continuous partition and it contains operator previous
  , or interval, it is a clocked discrete equation."
  input BackendDAE.EquationArray inEqs;
  input BackendDAE.EquationArray inRemovedEqs;
  input Integer inPartitionCnt;
  input array<Integer> inPartitions;
  input array<Integer> inReqsPartitions;
  input BackendDAE.Variables inVars;
  input BackendDAE.IncidenceMatrix mT;
  output list<BackendDAE.Equation> outNewEqs;
  output list<BackendDAE.Var> outNewVars;
  output array<Option<Boolean>> outContPartitions;
  output array<Integer> oClksCnt;
protected
  BackendDAE.Equation eq;
  Integer i, j, cnt;
  BackendDAE.Equation eq;
  DAE.ComponentRef cr;
  BackendDAE.Var var;
  array<list<Integer>> partitionsWhenClocks;
algorithm
  outContPartitions := arrayCreate(inPartitionCnt, NONE());
  partitionsWhenClocks := arrayCreate(inPartitionCnt, {});
  oClksCnt := arrayCreate(inPartitionCnt, 1);

  (outNewEqs, outNewVars) := collectEquationArrayClocks (
      inEqs, inPartitionCnt, inPartitions, partitionsWhenClocks, oClksCnt,
      outContPartitions, inVars, mT, {}, {}
  );
  (outNewEqs, outNewVars) := collectEquationArrayClocks (
      inRemovedEqs, inPartitionCnt, inReqsPartitions, partitionsWhenClocks, oClksCnt,
      outContPartitions, inVars, mT, outNewEqs, outNewVars
  );

  for i in 1:inPartitionCnt loop
    for j in arrayGet(partitionsWhenClocks, i) loop
      //For each when clock j in partition i create equation "$subclki_n = $whenclkj"
      cnt := arrayGet(oClksCnt, i);
      cr := DAE.CREF_IDENT(BackendDAE.WHENCLK_PRREFIX + intString(j), DAE.T_CLOCK_DEFAULT, {});
      (var, eq) := createSubClock(i, cnt, DAE.CREF(cr, DAE.T_CLOCK_DEFAULT));
      outNewEqs := eq::outNewEqs;
      outNewVars := var::outNewVars;
      arrayUpdate(oClksCnt, i, cnt + 1);
    end for;
    //If no subclock for partition i is detected, create new one "$subclki_1 = Clock()"
    if arrayGet(oClksCnt, i) == 1 then
      (var, eq) := createSubClock(i, 1, DAE.CLKCONST(DAE.INFERRED_CLOCK()));
      outNewEqs := eq::outNewEqs;
      outNewVars := var::outNewVars;
      arrayUpdate(oClksCnt, i, 2);
    end if;
  end for;
end collectSubclkInfo;

protected function collectEquationArrayClocks
  input BackendDAE.EquationArray eqs;
  input Integer partitionsCnt;
  input array<Integer> partitions;
  input array<list<Integer>> partitionsWhenClocks;
  input array<Integer> clksCnt;
  input array<Option<Boolean>> contPartitions;
  input BackendDAE.Variables inVars;
  input BackendDAE.IncidenceMatrix mT;
  input list<BackendDAE.Equation> inNewEqs;
  input list<BackendDAE.Var> inNewVars;
  output list<BackendDAE.Equation> outNewEqs = inNewEqs;
  output list<BackendDAE.Var> outNewVars = inNewVars;
protected
  BackendDAE.Equation eq;
  BackendDAE.EquationAttributes eqAttr;
  Integer partitionIdx;
  SourceInfo source;
algorithm
  for i in 1:BackendDAEUtil.equationArraySize(eqs) loop
    eq := BackendEquation.equationNth1(eqs, i);
    partitionIdx := arrayGet(partitions, i);
    DAE.SOURCE(info = source) := BackendEquation.equationSource(eq);

    if partitionIdx <>0 then
      eqAttr := BackendEquation.getEquationAttributes(eq);
      eqAttr := match eqAttr
        local
          Integer whenIdx;
          Boolean diff;
          list<Integer> partitionsWhenClocksLst;
        case BackendDAE.EQUATION_ATTRIBUTES(diff, BackendDAE.CLOCKED_EQUATION(whenIdx))
          algorithm
            partitionsWhenClocksLst := partitionsWhenClocks[partitionIdx];
            if whenIdx <> 0 and List.notMember(whenIdx, partitionsWhenClocksLst) then
              arrayUpdate(partitionsWhenClocks, partitionIdx, whenIdx::partitionsWhenClocksLst);
            end if;
          then BackendDAE.EQUATION_ATTRIBUTES(diff, BackendDAE.DYNAMIC_EQUATION());
        else eqAttr;
      end match;
      eq := BackendEquation.setEquationAttributes(eq, eqAttr);

      (eq, (outNewEqs, outNewVars, _, _, _, _, _, _, _))
          := BackendEquation.traverseExpsOfEquation (
              eq, collectSubclkInfoExp1, ( outNewEqs, outNewVars, contPartitions, source,
                                           clksCnt,  partitionIdx, partitions, inVars, mT ) );
      BackendEquation.setAtIndex(eqs, i, eq);
    end if;
  end for;
end collectEquationArrayClocks;

protected function collectSubclkInfoExp1
  input DAE.Exp inExp;
  input tuple< list<BackendDAE.Equation>, list<BackendDAE.Var>, array<Option<Boolean>>, SourceInfo,
               array<Integer>, Integer, array<Integer>, BackendDAE.Variables, BackendDAE.IncidenceMatrix > inTpl;
  output DAE.Exp outExp;
  output tuple< list<BackendDAE.Equation>, list<BackendDAE.Var>, array<Option<Boolean>>, SourceInfo,
               array<Integer>, Integer, array<Integer>, BackendDAE.Variables, BackendDAE.IncidenceMatrix > outTpl;
algorithm
  (outExp, outTpl) := Expression.traverseExpBottomUp(inExp, collectSubclkInfoExp, inTpl);
end collectSubclkInfoExp1;

protected function splitClockEqs
  input BackendDAE.EquationArray inEqs;
  output BackendDAE.EquationArray outClockEqs;
  output array<Boolean> outClockEqsMask;
protected
  list<BackendDAE.Equation> clockEqs = {};
  BackendDAE.Equation eq;
  Integer i;
algorithm
  outClockEqsMask := arrayCreate(BackendDAEUtil.equationArraySize(inEqs), true);
  for i in 1:BackendDAEUtil.equationArraySize(inEqs) loop
    eq := BackendEquation.equationNth1(inEqs, i);
    if isClockEquation(eq) then
      clockEqs := eq::clockEqs;
      arrayUpdate(outClockEqsMask, i, false);
    end if;
  end for;
  outClockEqs := BackendEquation.listEquation(clockEqs);
end splitClockEqs;

protected function splitClockVars
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables outClockVars;
  output array<Boolean> outClockVarsMask;
protected
  list<BackendDAE.Var> clockVars = {};
  BackendDAE.Var var;
algorithm
  outClockVarsMask := arrayCreate(BackendVariable.varsSize(inVars), true);
  for i in 1:BackendVariable.varsSize(inVars) loop
    var := BackendVariable.getVarAt(inVars, i);
    if Types.isClockOrSubTypeClock(var.varType) then
        clockVars := var :: clockVars;
        arrayUpdate(outClockVarsMask, i, false);
    end if;
  end for;
  outClockVars := BackendVariable.listVar(clockVars);
end splitClockVars;

protected function substitutePartitionOpExps
"Each non-trivial expression (non-literal, non-constant, non-parameter, non-variable), expr_i, appearing
 as first argument of any clock conversion operator or in base clock constructor is recursively replaced by a unique variable, $var_i,
 and the equation $var_i = expr_i is added to the equation set.
 Also when clauses are created for boolean clocks."
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outSyst = inSyst;
protected
  list<BackendDAE.Equation> newEqs = {};
  list<BackendDAE.Var> newVars = {};
  Integer cnt = 1;
algorithm
  for eq in BackendEquation.equationList(inSyst.orderedEqs) loop
    (eq, (newEqs, newVars, cnt, _)) := BackendEquation.traverseExpsOfEquation(eq, substitutePartitionOpExp, (newEqs, newVars, cnt, inShared));
    newEqs := eq::newEqs;
  end for;
  outSyst.orderedEqs := BackendEquation.listEquation(listReverse(newEqs));
  outSyst.orderedVars := BackendVariable.addVars(newVars, inSyst.orderedVars);
  outSyst := BackendDAEUtil.clearEqSyst(outSyst);
end substitutePartitionOpExps;

protected function substitutePartitionOpExp
  input DAE.Exp inExp;
  input tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>, Integer, BackendDAE.Shared> inTpl;
  output DAE.Exp outExp;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>, Integer, BackendDAE.Shared> outTpl;
algorithm
  (outExp, outTpl) := Expression.traverseExpBottomUp(inExp, substitutePartitionOpExp1, inTpl);
end substitutePartitionOpExp;

protected function substitutePartitionOpExp1
  input DAE.Exp inExp;
  input tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>, Integer, BackendDAE.Shared> inTpl;
  output DAE.Exp outExp;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>, Integer, BackendDAE.Shared> outTpl;
protected
  Absyn.Path path;
  BackendDAE.Shared shared;
  DAE.CallAttributes attr;
  DAE.ClockKind clk;
  Integer cnt;
  list<BackendDAE.Equation> newEqs;
  list<BackendDAE.Var> newVars;
  list<DAE.Exp> exps;
algorithm
  (newEqs, newVars, cnt, shared) := inTpl;
  (outExp, outTpl) := match inExp
    case DAE.CLKCONST(clk) equation
      (clk, newEqs, newVars, cnt) = substClock(clk, newEqs, newVars, cnt, shared);
    then (DAE.CLKCONST(clk), (newEqs, newVars, cnt, shared));

    case DAE.CALL(path=path, expLst=exps, attr=attr)
    then substituteExpsCall(path, exps, attr, newEqs, newVars, cnt, shared);

    else (inExp, inTpl);
  end match;
end substitutePartitionOpExp1;

protected function substClock
  input DAE.ClockKind inClk;
  input list<BackendDAE.Equation> inNewEqs;
  input list<BackendDAE.Var> inNewVars;
  input Integer inCnt;
  input BackendDAE.Shared inShared;
  output DAE.ClockKind outClk;
  output list<BackendDAE.Equation> outNewEqs;
  output list<BackendDAE.Var> outNewVars;
  output Integer outCnt;
protected
  DAE.Exp e, i, f;
  Integer cnt;
  list<BackendDAE.Equation> eqs;
  list<BackendDAE.Var> vars;
algorithm
  (outClk, outNewEqs, outNewVars, outCnt) := match inClk
    case DAE.BOOLEAN_CLOCK(e, f) equation
      ({e}, eqs, vars, cnt) = substExp({e}, inNewEqs, inNewVars, inCnt);
    then (DAE.BOOLEAN_CLOCK(e, f), eqs, vars, cnt);

    case DAE.REAL_CLOCK(e) equation
      (e, eqs, vars, cnt) = substClockExp(e, inNewEqs, inNewVars, inCnt, inShared);
    then (DAE.REAL_CLOCK(e), eqs, vars, cnt);

    case DAE.INTEGER_CLOCK(e, i) equation
      (e, eqs, vars, cnt) = substClockExp(e, inNewEqs, inNewVars, inCnt, inShared);
    then (DAE.INTEGER_CLOCK(e, i), eqs, vars, cnt);

    else (inClk, inNewEqs, inNewVars, inCnt);
  end match;
end substClock;

protected function isKnownOrConstantExp "author: lochel
  Returns true if the given expression is constant or at least known (parameter dependent)."
  input DAE.Exp inExp;
  input BackendDAE.Variables inKnownVars;
  output Boolean outKnown;
algorithm
  (_, (outKnown, _)) := Expression.traverseExpTopDown(inExp, isKnownOrConstantExp_traverser, (true, inKnownVars));
end isKnownOrConstantExp;

protected function isKnownOrConstantExp_traverser
  input DAE.Exp inExp;
  input tuple<Boolean, BackendDAE.Variables> inTpl;
  output DAE.Exp outExp = inExp;
  output Boolean outContinue;
  output tuple<Boolean, BackendDAE.Variables> outTpl;
protected
  BackendDAE.Variables globalKnownVars;
  Boolean isKnown;
algorithm
  (isKnown, globalKnownVars) := inTpl;
  isKnown := match inExp
    local
      DAE.ComponentRef componentRef;
    case DAE.CALL() then false;
    case DAE.CREF(componentRef=componentRef) then BackendVariable.containsCref(componentRef, globalKnownVars);
    else isKnown;
  end match;

  outTpl := (isKnown, globalKnownVars);
  outContinue := isKnown;
end isKnownOrConstantExp_traverser;

protected function substClockExp
  input DAE.Exp inExp;
  input list<BackendDAE.Equation> inNewEqs;
  input list<BackendDAE.Var> inNewVars;
  input Integer inCnt;
  input BackendDAE.Shared inShared;
  output DAE.Exp outExp;
  output list<BackendDAE.Equation> outNewEqs;
  output list<BackendDAE.Var> outNewVars;
  output Integer outCnt;
protected
  DAE.Type ty;
algorithm
  if isKnownOrConstantExp(inExp, inShared.globalKnownVars) then
    outExp := inExp;
    outNewEqs := inNewEqs;
    outNewVars := inNewVars;
    outCnt := inCnt;
  else
    ({outExp}, outNewEqs, outNewVars, outCnt) := substExp({inExp}, inNewEqs, inNewVars, inCnt);
    outExp := match outExp
      case DAE.CREF(_, ty) then Expression.makePureBuiltinCall("previous", {outExp}, ty);
      else outExp;
    end match;
  end if;
end substClockExp;

protected function substituteExpsCall
  input Absyn.Path inPath;
  input list<DAE.Exp> inExps;
  input DAE.CallAttributes inAttr;
  input list<BackendDAE.Equation> inEqs;
  input list<BackendDAE.Var> inVars;
  input Integer inCnt;
  input BackendDAE.Shared inShared;
  output DAE.Exp outExp;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>, Integer, BackendDAE.Shared> outTpl;
protected
  Boolean replace;
  list<DAE.Exp> exps;
  list<BackendDAE.Equation> eqs;
  list<BackendDAE.Var> vars;
  Integer cnt;
algorithm
  replace := match (inPath, listLength(inExps))
    case (Absyn.IDENT("hold"), 1) then true;
    case (Absyn.IDENT("sample"), 2) then true;
    case (Absyn.IDENT("subSample"), 2) then true;
    case (Absyn.IDENT("superSample"), 2) then true;
    case (Absyn.IDENT("shiftSample"), 3) then true;
    case (Absyn.IDENT("backSample"), 3) then true;
    case (Absyn.IDENT("noClock"), 1) then true;
    else false;
  end match;
  (exps, eqs, vars, cnt) :=
      if replace then substExp(inExps, inEqs, inVars, inCnt)
                 else (inExps, inEqs, inVars, inCnt);
  outExp := DAE.CALL(inPath, exps, inAttr);
  outTpl := (eqs, vars, cnt, inShared);
end substituteExpsCall;

protected function createVar
  input DAE.ComponentRef inComp;
  input DAE.Type inType;
  input Option<Values.Value> inValue = NONE();
  output BackendDAE.Var outVar;
algorithm
  outVar := BackendDAE.VAR (
                  varName = inComp, varKind = BackendDAE.VARIABLE(),
                  varDirection = DAE.BIDIR(), varParallelism = DAE.NON_PARALLEL(),
                  varType = inType, bindExp = NONE(),
                  bindValue = inValue, arryDim = {}, source = DAE.emptyElementSource,
                  values = NONE(), tearingSelectOption = SOME(BackendDAE.DEFAULT()),
                  hideResult = DAE.BCONST(false),
                  comment = NONE(), connectorType = DAE.NON_CONNECTOR(),
                  innerOuter = DAE.NOT_INNER_OUTER(), unreplaceable = false );
end createVar;

protected function createEqVarPair
  input DAE.ComponentRef inComp;
  input DAE.Type inType;
  input DAE.Exp inExp;
  output BackendDAE.Var outVar;
  output BackendDAE.Equation outEq;
algorithm
  outVar := createVar(inComp, inType);
  outEq := BackendDAE.EQUATION( exp = DAE.CREF(componentRef = inComp, ty = inType), scalar = inExp,
                                source = DAE.emptyElementSource, attr = BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC );
end createEqVarPair;

protected function substExp
  input list<DAE.Exp> inExps;
  input list<BackendDAE.Equation> inEqs;
  input list<BackendDAE.Var> inVars;
  input Integer inCnt;
  output tuple<list<DAE.Exp>, list<BackendDAE.Equation>, list<BackendDAE.Var>, Integer> outTpl;
protected
  Boolean create;
  DAE.Exp e;
algorithm
  e := List.first(inExps);
  create := match e
    case DAE.CREF() then false;
    case DAE.RCONST() then false;
    case DAE.SCONST() then false;
    case DAE.BCONST() then false;
    case DAE.ENUM_LITERAL() then false;
    case DAE.CLKCONST() then true;
    else true;
  end match;
  outTpl := match create
    local
        DAE.ComponentRef cr;
        DAE.Type ty;
        BackendDAE.Equation eq;
        BackendDAE.Var var;
    case true
      algorithm
        ty := Expression.typeof(e);
        cr := DAE.CREF_IDENT("$var" + intString(inCnt), ty, {});
        (var, eq) := createEqVarPair(cr, ty, e);
      then (DAE.CREF(cr, ty)::List.rest(inExps), eq::inEqs, var::inVars, inCnt + 1);
    case false
      then (inExps, inEqs, inVars, inCnt);
  end match;
end substExp;

protected function getVarIxs
  input DAE.ComponentRef inComp;
  input BackendDAE.Variables inVariables;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue inComp
    local
      list<Integer> ixs;
    case _
      equation
        (_, ixs) = BackendVariable.getVar(inComp, inVariables);
      then ixs;
    else
      then {};
  end matchcontinue;
end getVarIxs;

protected function baseClockPartitioning
"Do base clock partitioning and detect kind of new partitions(clocked or continuous)."
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  output list<BackendDAE.EqSystem> outContSysts = {};
  output list<BackendDAE.EqSystem> outClockedSysts = {};
  output list<BackendDAE.Equation> outUnpartRemEqs;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs;
  DAE.FunctionTree funcs;
  BackendDAE.IncidenceMatrix m, mT, rm, rmT;
  BackendDAE.EqSystem syst;
  BackendDAE.EqSystems systs;
  Integer partitionCnt, i, j;
  DAE.ComponentRef cr;
  list<Integer> varIxs;
  BackendDAE.EqSystem syst;
  array<Integer> eqsPartition, reqsPartition;
  array<Boolean> varsPartition, rvarsPartition;
  BackendDAE.Equation eq;
  list<tuple<DAE.ComponentRef, Boolean>> refsInfo;
  tuple<DAE.ComponentRef, Boolean> refInfo;
  Option<Boolean> partitionType;
  Boolean isClocked;
  array<Option<Boolean>> clockedEqs, clockedVars, clockedPartitions;
  SourceInfo info;
algorithm
  funcs := BackendDAEUtil.getFunctions(inShared);

  (syst, m, mT) := BackendDAEUtil.getIncidenceMatrixfromOption(inSyst, BackendDAE.BASECLOCK_IDX(), SOME(funcs));
  (rm, rmT) := BackendDAEUtil.removedIncidenceMatrix(inSyst, BackendDAE.BASECLOCK_IDX(), SOME(funcs));

  BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqs) := syst;
  eqsPartition := arrayCreate(arrayLength(m), 0);
  reqsPartition := arrayCreate(arrayLength(rm), 0);
  varsPartition := arrayCreate(arrayLength(mT), false);
  rvarsPartition := arrayCreate(arrayLength(rmT), false);

  partitionCnt := partitionIndependentBlocks0(m, mT, rm, rmT, eqsPartition, reqsPartition, varsPartition, rvarsPartition);

  if partitionCnt > 1 then
    (systs, outUnpartRemEqs) := partitionIndependentBlocksSplitBlocks(partitionCnt, syst, eqsPartition, reqsPartition, mT, rmT, false);
  else
    (systs, outUnpartRemEqs) := ({syst}, {});
  end if;

  //Partitioning finished
  clockedEqs := arrayCreate(BackendDAEUtil.equationArraySize(eqs), NONE());
  clockedVars := arrayCreate(BackendVariable.varsSize(vars), NONE());
  clockedPartitions := arrayCreate(if partitionCnt > 0 then partitionCnt else 1, NONE());
  //Detect clocked equations and variables
  j := 0;
  for eq in BackendEquation.equationList(eqs) loop
    j := j+1;
    (partitionType, refsInfo) := detectEqPartition(eq);
    info := BackendEquation.equationInfo(eq);
    arrayUpdate(clockedEqs, j, setClockedPartition(partitionType, arrayGet(clockedEqs, j), NONE(), info));
    for refInfo in refsInfo loop
      (cr, isClocked) := refInfo;
      varIxs := getVarIxs(cr, vars);
      for i in varIxs loop
        arrayUpdate(clockedVars, i, setClockedPartition(SOME(isClocked), arrayGet(clockedVars, i), SOME(cr), info));
      end for;
    end for;
  end for;
  //Clocked vars should belong to clocked equation
  for i in 1:arrayLength(clockedVars) loop
    partitionType := arrayGet(clockedVars, i);
    cr := BackendVariable.varCref(BackendVariable.getVarAt(vars, i));
    for j in arrayGet(mT, i) loop
      info := BackendEquation.equationInfo(BackendEquation.equationNth1(eqs, j));
      arrayUpdate(clockedEqs, j, setClockedPartition(partitionType, arrayGet(clockedEqs, j), SOME(cr), info));
    end for;
  end for;
  //Detect clocked partitions (clocked equations should belong to clocked partitions)
  for i in 1:arrayLength(clockedEqs) loop
    partitionType := arrayGet(clockedEqs, i);
    info := BackendEquation.equationInfo(BackendEquation.equationNth1(eqs, i));
    j := arrayGet(eqsPartition, i);
    arrayUpdate(clockedPartitions, j, setClockedPartition(partitionType, arrayGet(clockedPartitions, j), NONE(), info));
  end for;

  i := 1;
  for syst in systs loop
    (outContSysts, outClockedSysts) := match arrayGet(clockedPartitions, i)
      case SOME(false)
        then (setSystPartition(syst, BackendDAE.CONTINUOUS_TIME_PARTITION()) :: outContSysts, outClockedSysts);
      /* Other partitions where none of the variables in the partition are associated with any of the operators above have an
       * unspecified partition kind and are considered continuous-time partitions. */
      case NONE()
        then (setSystPartition(syst, BackendDAE.UNSPECIFIED_PARTITION()) :: outContSysts, outClockedSysts);
      case SOME(true) then (outContSysts, syst :: outClockedSysts);
    end match;
    i := i + 1;
  end for;
end baseClockPartitioning;

protected function isClockExp
  input DAE.Exp inExp;
  output Boolean out;
algorithm
  out := Types.isClockOrSubTypeClock(Expression.typeof(inExp));
end isClockExp;

protected function isClockEquation
  input BackendDAE.Equation inEq;
  output Boolean out;
algorithm
  out := match inEq
    local
      DAE.Exp e, message, cond;
      list<list<BackendDAE.Equation>> trueEqs;
      list<BackendDAE.Equation> falseEqs, listEqs;
      BackendDAE.Equation eq;
      SourceInfo info;
    case BackendDAE.EQUATION(scalar = e) then isClockExp(e);
    case BackendDAE.ARRAY_EQUATION(right = e) then isClockExp(e);
    case BackendDAE.SOLVED_EQUATION(exp = e) then isClockExp(e);
    case BackendDAE.RESIDUAL_EQUATION(exp = e) then isClockExp(e);
    case BackendDAE.ALGORITHM() then false;
    case BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_STMTS(whenStmtLst={BackendDAE.ASSIGN(right=e)}))
      algorithm
        if isClockExp(e) then
          DAE.SOURCE(info = info) := BackendEquation.equationSource(inEq);
          Error.addSourceMessageAndFail(Error.INVALID_CLOCK_EQUATION, {}, info);
        end if;
      then false;
    case BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_STMTS(whenStmtLst={BackendDAE.REINIT(value=e)}))
      algorithm
        if isClockExp(e) then
          DAE.SOURCE(info = info) := BackendEquation.equationSource(inEq);
          Error.addSourceMessageAndFail(Error.INVALID_CLOCK_EQUATION, {}, info);
        end if;
      then false;
    case BackendDAE.COMPLEX_EQUATION(right = e) then isClockExp(e);
    case BackendDAE.IF_EQUATION(eqnstrue = trueEqs, eqnsfalse = falseEqs)
      algorithm
        for listEqs in trueEqs loop
          for eq in listEqs loop
            if isClockEquation(eq) then
              DAE.SOURCE(info = info) := BackendEquation.equationSource(eq);
              Error.addSourceMessageAndFail(Error.INVALID_CLOCK_EQUATION, {}, info);
            end if;
          end for;
        end for;
        for eq in falseEqs loop
          if isClockEquation(eq) then
            DAE.SOURCE(info = info) := BackendEquation.equationSource(eq);
            Error.addSourceMessageAndFail(Error.INVALID_CLOCK_EQUATION, {}, info);
          end if;
        end for;
      then false;
    else
      equation
        Error.addInternalError("SynchronousFeatures.isClockEquation failed.\n", sourceInfo());
      then fail();
  end match;
end isClockEquation;

protected function detectEqPartition
"Detect clocked equation and variables according the rule:
 - variable u in sample(u) and a variable y in y = hold(ud) is in a continuous-time partition;
 - variables u and y in y = sample(uc), y = subSample(u), y = superSample(u), y =
   shiftSample(u), y = backSample(u), y = previous(u), are in a clocked partition;
 - equations in a clocked when clause in a clocked partition;"
  input BackendDAE.Equation inEq;
  output Option<Boolean> outPartitionType;
  output list<tuple<DAE.ComponentRef, Boolean>> refsInfo;
protected
  Option<Boolean> partitionType;
  Boolean isClockEq;
  SourceInfo info;
algorithm
  partitionType := match BackendEquation.getEquationAttributes(inEq)
    local
    case BackendDAE.EQUATION_ATTRIBUTES(kind = BackendDAE.CLOCKED_EQUATION())
      then SOME(true);
    else NONE();
  end match;
  info := BackendEquation.equationInfo(inEq);
  (_, (partitionType, refsInfo, _)) :=
      BackendEquation.traverseExpsOfEquation(inEq, detectEqPartitionExp, (partitionType, {}, info));
  isClockEq := isClockEquation(inEq);
  outPartitionType := if isClockEq then setClockedPartition(SOME(true), partitionType, NONE(), info)
                                   else partitionType;
end detectEqPartition;

protected function printPartitionType
  input Option<Boolean> isClockedPartition;
  output String out;
algorithm
  out := match isClockedPartition
    case SOME(false) then "CONT_PARTITION";
    case SOME(true) then "CLOCKED_PARTITION";
    else "UNSPECIFIED_PARTITION";
  end match;
end printPartitionType;

protected function detectEqPartitionExp
  input DAE.Exp inExp;
  input tuple<Option<Boolean>, list<tuple<DAE.ComponentRef, Boolean>>, SourceInfo> inTpl;
  output DAE.Exp outExp;
  output tuple<Option<Boolean>, list<tuple<DAE.ComponentRef, Boolean>>, SourceInfo> outTpl;
algorithm
  (outExp, outTpl) := Expression.traverseExpTopDown(inExp, detectEqPartitionExp1, inTpl);
end detectEqPartitionExp;

protected function detectEqPartitionExp1
  input DAE.Exp inExp;
  input tuple<Option<Boolean>, list<tuple<DAE.ComponentRef, Boolean>>, SourceInfo> inTpl;
  output DAE.Exp outExp = inExp;
  output Boolean cont;
  output tuple<Option<Boolean>, list<tuple<DAE.ComponentRef, Boolean>>, SourceInfo> outTpl;
protected
  list<tuple<DAE.ComponentRef, Boolean>> refs;
  Option<Boolean> partition;
  SourceInfo info;
algorithm
  (partition, refs, info) := inTpl;
  (partition, refs, cont) := match inExp
    local
      Absyn.Path path;
      list<DAE.Exp> exps;
      DAE.Exp e;
      DAE.ComponentRef cr;
    case DAE.CLKCONST(DAE.BOOLEAN_CLOCK(e, _))
      equation
        DAE.CREF(cr, _) = e;
      then (partition, (cr, false)::refs, false);
    case DAE.CALL(path = path, expLst = exps)
      then detectEqPartitionCall(path, exps, refs, partition, info);
    else (partition, refs, true);
  end match;
  outTpl := (partition, refs, info);
end detectEqPartitionExp1;

protected function detectEqPartitionCall
  input Absyn.Path inPath;
  input list<DAE.Exp> inExps;
  input list<tuple<DAE.ComponentRef, Boolean>> inRefs;
  input Option<Boolean> inPartition;
  input SourceInfo info;
  output Option<Boolean> outPartition;
  output list<tuple<DAE.ComponentRef, Boolean>> outRefs;
  output Boolean cont;
algorithm
  (outPartition, outRefs, cont) := match (inPath, inExps)
    local
      DAE.Exp e, e1, e2;
    case (Absyn.IDENT("hold"), {e})
      then detectEqPartitionCall1(false, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("sample"), {e, e1})
      then detectEqPartitionCall1(true, false, inPartition, e, inRefs, info);
    case (Absyn.IDENT("subSample"), {e, e1})
      then detectEqPartitionCall1(true, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("superSample"), {e, e1})
      then detectEqPartitionCall1(true, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("shiftSample"), {e, e1, e2})
      then detectEqPartitionCall1(true, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("backSample"), {e, e1, e2})
      then detectEqPartitionCall1(true, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("noClock"), {e})
      then detectEqPartitionCall1(true, true, inPartition, e, inRefs, info);
    else (inPartition, inRefs, true);
  end match;
end detectEqPartitionCall;

protected function detectEqPartitionCall1
  input Boolean expClocked;
  input Boolean refClocked;
  input Option<Boolean> inPartition;
  input DAE.Exp inExp;
  input list<tuple<DAE.ComponentRef, Boolean>> inRefs;
  input SourceInfo info;
  output Option<Boolean> outPartition;
  output list<tuple<DAE.ComponentRef, Boolean>> outRefs;
  output Boolean cont = false;
algorithm
  (outPartition, outRefs) := match inExp
    local
      DAE.ComponentRef cr;
    case DAE.CREF(cr, _)
      equation
      then (setClockedPartition(SOME(expClocked), inPartition, NONE(), info), (cr, refClocked)::inRefs);
    else
      equation
        Error.addInternalError("SynchronousFeatures.detectEqPartitionCall1 failed\n", sourceInfo());
      then fail();
  end match;
end detectEqPartitionCall1;

protected function setSystPartition
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.BaseClockPartitionKind inPartitionKind;
  output BackendDAE.EqSystem outSyst;
algorithm
  outSyst := match inSyst
    local
      BackendDAE.EqSystem syst;
    case syst as BackendDAE.EQSYSTEM()
      algorithm
        syst.partitionKind := inPartitionKind;
      then syst;
  end match;
end setSystPartition;

protected function getPartitionConflictError
  input Option<DAE.ComponentRef> inComp;
  output Error.Message msg;
  output Error.MessageTokens tokens;
algorithm
  (msg, tokens) := match inComp
    local DAE.ComponentRef cr;
    case SOME(cr) then ( Error.CONT_CLOCKED_PARTITION_CONFLICT_VAR,
                         {ComponentReference.printComponentRefStr(cr)} );
    else (Error.CONT_CLOCKED_PARTITION_CONFLICT_EQ, {});
  end match;
end getPartitionConflictError;

protected function setClockedPartition
  input Option<Boolean> inNewPartitionType;
  input Option<Boolean> inOldPartitionType;
  input Option<DAE.ComponentRef> inComp;
  input SourceInfo info;
  output Option<Boolean> outPartitionType;
algorithm
  outPartitionType := match (inOldPartitionType, inNewPartitionType)
    local
      Boolean newVal, oldVal;
      Error.Message msg;
      Error.MessageTokens tokens;
    case (NONE(), _) then inNewPartitionType;
    case (_, NONE()) then inOldPartitionType;
    case (SOME(oldVal), SOME(newVal)) guard (oldVal == newVal)
      then inNewPartitionType;
    else
      equation
        (msg, tokens) = getPartitionConflictError(inComp);
        Error.addSourceMessage(msg, tokens, info);
      then fail();
  end match;
end setClockedPartition;

public function partitionIndependentBlocks0
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input BackendDAE.IncidenceMatrix rm;
  input BackendDAE.IncidenceMatrixT rmT;
  input array<Integer> ixs, rixs;
  input array<Boolean> vars, rvars;
  output Integer on = 0;
algorithm
  for i in arrayLength(m):-1:1 loop
    on := if partitionIndependentBlocksEq(i, on + 1, m, mT, rm, rmT, ixs, rixs, vars, rvars) then on + 1 else on;
  end for;
  for i in arrayLength(rm):-1:1 loop
    on := if partitionIndependentBlocksReq(i, on + 1, m, mT, rm, rmT, ixs, rixs, vars, rvars) then on + 1 else on;
  end for;
end partitionIndependentBlocks0;

protected function partitionIndependentBlocksMasked
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input BackendDAE.IncidenceMatrix rm;
  input BackendDAE.IncidenceMatrixT rmT;
  input array<Boolean> mask;
  input array<Integer> ixs, rixs;
  input array<Boolean> vars, rvars;
  output Integer on = 0;
algorithm
  for i in arrayLength(m):-1:1 loop
    if mask[i] then
      on := if partitionIndependentBlocksEq(i, on + 1, m, mT, rm, rmT, ixs, rixs, vars, rvars) then on + 1 else on;
    end if;
  end for;
  for i in arrayLength(rm):-1:1 loop
    on := if partitionIndependentBlocksReq(i, on + 1, m, mT, rm, rmT, ixs, rixs, vars, rvars) then on + 1 else on;
  end for;
end partitionIndependentBlocksMasked;

protected function partitionIndependentBlocksEq
  input Integer ix;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input BackendDAE.IncidenceMatrix rm;
  input BackendDAE.IncidenceMatrixT rmT;
  input array<Integer> ixs, rixs;
  input array<Boolean> vars, rvars;
  output Boolean ochange;
algorithm
  ochange := arrayGet(ixs, ix) == 0;

  if ochange then
    arrayUpdate(ixs, ix, n);
    for i in arrayGet(m, ix) loop
      if not arrayGet(vars, intAbs(i)) then
        arrayUpdate(vars, intAbs(i), true);
        for j in arrayGet(mT, intAbs(i)) loop
          partitionIndependentBlocksEq(intAbs(j), n, m, mT, rm, rmT, ixs, rixs, vars, rvars);
        end for;
        for j in arrayGet(rmT, intAbs(i)) loop
          partitionIndependentBlocksReq(intAbs(j), n, m, mT, rm, rmT, ixs, rixs, vars, rvars);
        end for;
      end if;
    end for;
  end if;
end partitionIndependentBlocksEq;

protected function partitionIndependentBlocksReq
  input Integer ix;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input BackendDAE.IncidenceMatrix rm;
  input BackendDAE.IncidenceMatrixT rmT;
  input array<Integer> ixs, rixs;
  input array<Boolean> vars, rvars;
  output Boolean ochange;
algorithm
  ochange := arrayGet(rixs, ix) == 0;

  if ochange then
    arrayUpdate(rixs, ix, n);
    for i in arrayGet(rm, ix) loop
      if not arrayGet(rvars, intAbs(i)) then
        arrayUpdate(rvars, intAbs(i), true);
        for j in arrayGet(mT, intAbs(i)) loop
          partitionIndependentBlocksEq(intAbs(j), n, m, mT, rm, rmT, ixs, rixs, vars, rvars);
        end for;
        for j in arrayGet(rmT, intAbs(i)) loop
          partitionIndependentBlocksReq(intAbs(j), n, m, mT, rm, rmT, ixs, rixs, vars, rvars);
        end for;
      end if;
    end for;
  end if;
end partitionIndependentBlocksReq;

public function partitionIndependentBlocksSplitBlocks
  "Partitions the independent blocks into list<array<...>> by first constructing
  an array<list<...>> structure for the algorithm complexity"
  input Integer n;
  input BackendDAE.EqSystem inSyst;
  input array<Integer> ixs;
  input array<Integer> rixs;
  input BackendDAE.IncidenceMatrix mT;
  input BackendDAE.IncidenceMatrix rmT;
  input Boolean throwNoError;
  output list<BackendDAE.EqSystem> systs = {};
  output list<BackendDAE.Equation> unpartRemovedEqs;
protected
  array<list<BackendDAE.Equation>> ea, rea;
  array<list<BackendDAE.Var>> va;
  Integer i1, i2;
  String s1, s2;
  Boolean b, b1 = true;
  BackendDAE.EqSystem syst;
  array<Integer> varsPartition;
  list<BackendDAE.Var> lstVars;
algorithm
  ea := arrayCreate(n, {});
  rea := arrayCreate(n, {});
  va := arrayCreate(n, {});
  i1 := BackendDAEUtil.equationSize(inSyst.orderedEqs);
  i2 := BackendVariable.varsSize(inSyst.orderedVars);

  if i1 <> i2 and not throwNoError then
  s1 := intString(i1);
  s2 := intString(i2);
  Error.addSourceMessage(if i1 > i2 then Error.OVERDET_EQN_SYSTEM else Error.UNDERDET_EQN_SYSTEM,
    {s1, s2}, Absyn.dummyInfo);
    fail();
  end if;

  partitionEquations(inSyst.orderedEqs, ixs, ea);
  unpartRemovedEqs := partitionEquations(inSyst.removedEqs, rixs, rea);

  varsPartition := arrayCreate(BackendVariable.varsSize(inSyst.orderedVars), 0);
  for i in 1:BackendVariable.varsSize(inSyst.orderedVars) loop
    setVarPartition(varsPartition, i, mT[i], ixs);
    setVarPartition(varsPartition, i, rmT[i], rixs);
  end for;
  for i in arrayLength(varsPartition):-1:1 loop
    if varsPartition[i] <> 0 then
      lstVars := va[varsPartition[i]];
      arrayUpdate(va, varsPartition[i], BackendVariable.getVarAt(inSyst.orderedVars, i)::lstVars);
    end if;
  end for;

  for i in 1:n loop
    (syst, (b, _)) := createEqSystem(ea[i], va[i], rea[i], (true, throwNoError));
    systs := syst :: systs;
    b1 := b1 and b;
  end for;
  true := throwNoError or b1;
  systs := listReverse(systs);
end partitionIndependentBlocksSplitBlocks;

protected function setVarPartition
  input array<Integer> varsPartition;
  input Integer i;
  input list<Integer> eqsIxs;
  input array<Integer> eqsPartitions;
protected
  Integer partitionIdx;
algorithm
  for eq in eqsIxs loop
    partitionIdx := eqsPartitions[eq];
    if partitionIdx <> 0 then
      assert(varsPartition[i] == 0 or varsPartition[i] == partitionIdx, "SynchronousFeatures.setVarPartition failed");
      arrayUpdate(varsPartition, i, partitionIdx);
    end if;
  end for;
end setVarPartition;

protected function createEqSystem
  input list<BackendDAE.Equation> el;
  input list<BackendDAE.Var> vl;
  input list<BackendDAE.Equation> rel;
  input tuple<Boolean, Boolean> iTpl;
  output BackendDAE.EqSystem syst;
  output tuple<Boolean, Boolean> oTpl;
protected
  BackendDAE.EquationArray arr, remArr;
  BackendDAE.Variables vars;
  Integer i1, i2;
  String s1, s2, s3, s4;
  list<String> crs;
  Boolean success, throwNoError;
algorithm
  (success, throwNoError) := iTpl;
  vars := BackendVariable.listVar1(vl);
  arr := BackendEquation.listEquation(el);
  remArr := BackendEquation.listEquation(rel);
  i1 := BackendDAEUtil.equationSize(arr);
  i2 := BackendVariable.varsSize(vars);

  // Can this even be triggered? We check that all variables are defined somewhere, so everything should be balanced already?
  if i1 <> i2 and not throwNoError then
    s1 := intString(i1);
    s2 := intString(i2);
    crs := List.mapMap(vl, BackendVariable.varCref, ComponentReference.printComponentRefStr);
    s3 := stringDelimitList(crs, "\n");
    s4 := BackendDump.dumpEqnsStr(el);
    Error.addSourceMessage(Error.IMBALANCED_EQUATIONS, {s1, s2, s3, s4}, Absyn.dummyInfo);
    fail();
  end if;

  syst := BackendDAEUtil.createEqSystem(vars, arr, {}, BackendDAE.UNKNOWN_PARTITION(), remArr);
  success := success and i1==i2;
  oTpl := (success, throwNoError);
end createEqSystem;

protected function partitionEquations
  input BackendDAE.EquationArray arr;
  input array<Integer> ixs;
  input array<list<BackendDAE.Equation>> ea;
  output list<BackendDAE.Equation> restEqs = {};
protected
  Integer ix;
  list<BackendDAE.Equation> lst;
  BackendDAE.Equation eq;
algorithm
  for i in BackendDAEUtil.equationArraySize(arr):-1:1 loop
    ix := ixs[i];
    eq := BackendEquation.equationNth1(arr, i);
    if ix == 0 then
      restEqs := eq::restEqs;
    else
      lst := ea[ix];
      lst := eq::lst;
      // print("adding eq " + intString(n) + " to group " + intString(ix) + "\n");
      arrayUpdate(ea, ix, lst);
    end if;
  end for;
end partitionEquations;

protected function subClockTreeString
  input array<tuple<BackendDAE.SubClock, Integer>> treeIn;
  output String sOut="";
protected
 tuple<BackendDAE.SubClock, Integer> tpl;
 BackendDAE.SubClock subClock;
 Integer i;
algorithm
  for tpl in treeIn loop
    (subClock,i) := tpl;
    sOut := "["+intString(i)+"]:  "+BackendDump.subClockString(subClock)+"\n"+sOut;
  end for;
end subClockTreeString;

annotation(__OpenModelica_Interface="backend");
end SynchronousFeatures;
