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
               - sub-clock partitioning

  RCS: $Id: SynchronousFeatures.mo 21476 2014-07-11 12:08:20Z lochel $"

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
      list<BackendDAE.EqSystem> systs;
      BackendDAE.Shared shared;

    case (BackendDAE.DAE({syst}, shared)) guard(not Flags.isSet(Flags.NO_PARTITIONING))
      then clockPartitioning1(syst, shared);
    // TODO: Improve support for partitioned systems of equations
    case _ guard(not Flags.isSet(Flags.NO_PARTITIONING)) equation
      BackendDAE.DAE({syst}, shared) = BackendDAEOptimize.collapseIndependentBlocks(inDAE);
    then clockPartitioning1(syst, shared);
    else inDAE;
  end match;
end clockPartitioning;

protected function clockPartitioning1
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  output BackendDAE.BackendDAE outDAE;
protected
  Integer i;
  BackendDAE.EqSystem syst;
  list<BackendDAE.EqSystem> contSysts, clockedSysts;
  array<DAE.ClockKind> baseClocks;
  DAE.ClockKind clock;
  BackendDAE.Shared shared = inShared;
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs;
  BackendDAE.BaseClockPartitionKind partitionKind;
  list<DAE.ComponentRef> holdComps;
  array<Integer> varsPartition;
  list<BackendDAE.Equation> unpartRemEqs;
algorithm
  syst := substituteParitionOpExps(inSyst);

  (contSysts, clockedSysts, unpartRemEqs) := baseClockPartitioning(syst, inShared);
  (contSysts, holdComps) := removeHoldExpsSyst(contSysts);

  shared.removedEqs := BackendEquation.addEquations(unpartRemEqs, shared.removedEqs);

  (clockedSysts, baseClocks) := subClockPartitioning1(clockedSysts, inShared, holdComps);
  clockedSysts := List.map(clockedSysts, makePreviousFixed);

  //Continuous systems always first in equation systems list
  systs := listAppend(contSysts, clockedSysts);
  outDAE := BackendDAE.DAE(systs, setClocks(inShared, baseClocks));

  if Flags.isSet(Flags.DUMP_SYNCHRONOUS) then
    BackendDump.dumpEqSystems(systs, "base-clock partitioning");
    BackendDump.dumpClocks(baseClocks, "Base clocks");
  end if;
end clockPartitioning1;

protected function makePreviousFixed
  input BackendDAE.EqSystem inSyst;
  output BackendDAE.EqSystem outSyst = inSyst;
protected
  BackendDAE.Equation eq;
  list<DAE.ComponentRef> fixedComps = {};
  array<Boolean> prevVars;
  Option<String> solverMethod;
  list<Integer> varIxs;
  BackendDAE.Var var;
algorithm
  BackendDAE.CLOCKED_PARTITION(subClock=BackendDAE.SUBCLOCK(solver=solverMethod)) := outSyst.partitionKind;
  if isNone(solverMethod) then
    prevVars := arrayCreate(BackendVariable.varsSize(outSyst.orderedVars), false);
    for i in 1:BackendDAEUtil.equationSize(outSyst.orderedEqs) loop
      eq := BackendEquation.equationNth1(outSyst.orderedEqs, i);
      (_, fixedComps) := BackendEquation.traverseExpsOfEquation(eq, collectPrevVars, fixedComps);
    end for;
    for i in 1:BackendDAEUtil.equationSize(outSyst.removedEqs) loop
      eq := BackendEquation.equationNth1(outSyst.removedEqs, i);
      (_, fixedComps) := BackendEquation.traverseExpsOfEquation(eq, collectPrevVars, fixedComps);
    end for;
    for cr in fixedComps loop
      varIxs := getVarIxs(cr, outSyst.orderedVars);
      for idx in varIxs loop
        arrayUpdate(prevVars, idx, true);
      end for;
    end for;
    for i in 1:arrayLength(prevVars) loop
      if prevVars[i] then
        var := BackendVariable.setVarFixed(BackendVariable.getVarAt(outSyst.orderedVars, i), true);
        BackendVariable.setVarAt(outSyst.orderedVars, i, var);
      end if;
    end for;
  end if;
end makePreviousFixed;

protected function collectPrevVars
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inPrevVars;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outPrevVars;
algorithm
  (outExp, outPrevVars) := Expression.traverseExpBottomUp(inExp, collectPrevVars1, inPrevVars);
end collectPrevVars;

public function collectPrevVars1
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

protected function setClocks
  input BackendDAE.Shared inShared;
  input array<DAE.ClockKind> inClocks;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.EventInfo eventInfo;
  list<BackendDAE.TimeEvent> timeEvents;
  list<BackendDAE.WhenClause> whenClauseLst;
  list<BackendDAE.ZeroCrossing> zeroCrossingLst;
  list<BackendDAE.ZeroCrossing> sampleLst;
  list<BackendDAE.ZeroCrossing> relationsLst;
  Integer numberMathEvents;
algorithm
  outShared := match inShared
    local
      BackendDAE.Shared shared;
    case shared as BackendDAE.SHARED()
      algorithm shared.partitionsInfo := BackendDAE.PARTITIONS_INFO(inClocks);
      then shared;
  end match;
end setClocks;

protected type UnresolvedPartitionData = tuple<BackendDAE.Variables, BackendDAE.EquationArray, BackendDAE.SubClock>;

protected function subClockPartitioning1
"Do subclock partitioning and inferencing and create clocked partitions and base clocks array."
  input list<BackendDAE.EqSystem> inSysts;
  input BackendDAE.Shared inShared;
  input list<DAE.ComponentRef> inHoldComps;
  output list<BackendDAE.EqSystem> outSysts = {};
  output array<DAE.ClockKind> outClocks;
protected
  DAE.ClockKind clock;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs;
  BackendDAE.SubClock subclock;
  list<list<UnresolvedPartitionData>> tpls = {};
  list<UnresolvedPartitionData> tpls1;
  UnresolvedPartitionData tpl;
  HashTable.HashTable varsPartition;
  Integer i, j;
  DAE.ComponentRef cr;
  array<Boolean> hasHoldOperator;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  outClocks := arrayCreate(listLength(inSysts), DAE.INFERRED_CLOCK());
  varsPartition := HashTable.emptyHashTable();
  i := 1;
  for syst in inSysts loop
    (tpls1, clock) := subClockPartitioning(syst, inShared);
    tpls := tpls1 :: tpls;
    arrayUpdate(outClocks, i, clock);
    i := i + 1;
  end for;
  //Get count of subpartitions
  i := 0;
  for tpls1 in tpls loop
    i := i + listLength(tpls1);
  end for;
  hasHoldOperator := arrayCreate(i, false);
  //Create hash cr -> subpartition index
  i := 1;
  for tpls1 in tpls loop
    for tpl in tpls1 loop
      (vars, _, _) := tpl;
      for j in 1:BackendVariable.varsSize(vars) loop
        BackendDAE.VAR(varName=cr) := BackendVariable.getVarAt(vars, j);
        varsPartition := BaseHashTable.add((cr, i), varsPartition);
      end for;
      i := i + 1;
    end for;
  end for;
  //Detect subpartitions whose variables are used in hold operator
  for cr in inHoldComps loop
    i := BaseHashTable.get(cr, varsPartition);
    arrayUpdate(hasHoldOperator, i, true);
  end for;

  i := 1; j := 1;
  for tpls1 in tpls loop
    for tpl in tpls1 loop
      (vars, eqs, subclock) := tpl;
      partitionKind := BackendDAE.CLOCKED_PARTITION(i, subclock, arrayGet(hasHoldOperator, j));
      outSysts := BackendDAEUtil.createEqSystem(vars, eqs, {}, partitionKind)::outSysts;
      j := j + 1;
    end for;
    i := i + 1;
  end for;
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
  output list<UnresolvedPartitionData> outTpl = {};
  output DAE.ClockKind outClock;
protected
  DAE.FunctionTree funcs;
  BackendDAE.EquationArray eqs, clockEqs;
  BackendDAE.Variables vars, clockVars;
  BackendDAE.EqSystem syst, clockSyst;
  BackendDAE.IncidenceMatrix m, mT, rm, rmT;
  Integer i, partitionsCnt;
  array<Integer> partitions, reqsPartitions;
  list<BackendDAE.Equation> newClockEqs;
  list<BackendDAE.Var> newClockVars;
  array<Option<Boolean>> contPartitions;
  array<BackendDAE.SubClock> subclocks;
  BackendDAE.StrongComponents clockComps;
  array<Integer> subclksCnt;
  list<BackendDAE.EqSystem> systs;
algorithm

  funcs := BackendDAEUtil.getFunctions(inShared);
  BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqs) := inEqSystem;

  (clockEqs, eqs) := splitClockEqs(eqs);
  (clockVars, vars) := splitClockVars(vars);

  syst := BackendDAEUtil.createEqSystem(vars, eqs);

  (syst, m, mT) := BackendDAEUtil.getIncidenceMatrixfromOption(syst, BackendDAE.SUBCLOCK_IDX(), SOME(funcs));
  (rm, rmT) := BackendDAEUtil.removedIncidenceMatrix(syst, BackendDAE.SUBCLOCK_IDX(), SOME(funcs));
  partitions := arrayCreate(arrayLength(m), 0);
  reqsPartitions := arrayCreate(arrayLength(rm), 0);
  partitionsCnt := partitionIndependentBlocks0(m, mT, rm, rmT, partitions, reqsPartitions);

  //Detect clocked continuous partitions and create new subclock equations
  (eqs, newClockEqs, newClockVars, contPartitions, subclksCnt)
      := collectSubclkInfo(eqs, partitionsCnt, partitions, vars, mT);

  clockEqs := BackendEquation.addEquations(newClockEqs, clockEqs);
  clockVars := BackendVariable.addVars(newClockVars, clockVars);
  clockSyst := BackendDAEUtil.createEqSystem(clockVars, clockEqs, {});

  //Solve clock equations
  BackendDAE.DAE({clockSyst}, _) := BackendDAEUtil.transformBackendDAE (
                                      BackendDAE.DAE({clockSyst}, inShared), NONE(), NONE(), NONE() );
  BackendDAE.EQSYSTEM( orderedVars=clockVars, orderedEqs=clockEqs,
                       matching=BackendDAE.MATCHING(_, _, clockComps) ) := clockSyst;

  syst :=  BackendDAEUtil.createEqSystem(vars, eqs);
  systs :=
    if partitionsCnt > 1 then
      partitionIndependentBlocksSplitBlocks(partitionsCnt, syst, partitions, reqsPartitions, mT, false)
    else
      {syst};

  (subclocks, outClock) := resolveClocks(clockVars, clockEqs, clockComps);
  subclocks := collectSubClocks(clockVars, partitionsCnt, partitions, contPartitions, subclksCnt, subclocks);

  i := 1;
  for syst in systs loop
    BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqs) := syst;
    outTpl := (vars, eqs, arrayGet(subclocks, i))::outTpl;
    i := i + 1;
  end for;
end subClockPartitioning;

protected function resolveClocks
"Get from clock equation system array sub-clocks[varIdx] and base clock."
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqs;
  input BackendDAE.StrongComponents inComps;
  output array<BackendDAE.SubClock> outSubClocks;
  output DAE.ClockKind outClockKind = DAE.INFERRED_CLOCK();
protected
  Integer i;
  BackendDAE.Equation eq;
  DAE.ComponentRef cr;
  DAE.Exp exp;
  BackendDAE.Var var;
  DAE.ClockKind clockKind;
  BackendDAE.SubClock subClock;
  BackendDAE.StrongComponent comp;
  Integer eqIdx, varIdx;
algorithm
  outSubClocks := arrayCreate(BackendVariable.varsSize(inVars), BackendDAE.SUBCLOCK(rat0, rat0, NONE()));
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
          (clockKind, subClock) := getSubClock(exp, inVars, outSubClocks);
          arrayUpdate(outSubClocks, varIdx, subClock);
        then setClockKind(outClockKind, clockKind);
      else
        algorithm
          print("internal error -- SynchronousFeatures.resolveClocks failure\r\n");
        then fail();
    end matchcontinue;
  end for;
end resolveClocks;

protected constant MMath.Rational rat0 = MMath.RATIONAL(0, 1);
protected constant MMath.Rational rat1 = MMath.RATIONAL(1, 1);

protected function getSubClock
"Get base clock and subclock from expression"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  input array<BackendDAE.SubClock> inSubClocks;
  output DAE.ClockKind outClockKind;
  output BackendDAE.SubClock outSubClock;
protected
  DAE.Exp e1, e2, e3;
  String solverMethodStr;
  Option<String> solverMethod;
  BackendDAE.SubClock subClock;
  DAE.ClockKind clockKind;
  MMath.Rational factor, shift;
  DAE.ComponentRef cr;
  list<Integer> varIxs;
  BackendDAE.Var var;
  Integer i1, i2;
  String err = "Internal error -- Function SynchronousFeatures.getSubClock failed for ";
algorithm
  (outClockKind, outSubClock) := match inExp
    case DAE.CLKCONST(DAE.SOLVER_CLOCK(e1, solverMethodStr))
      algorithm
        (clockKind, BackendDAE.SUBCLOCK(factor, shift, _)) := getSubClock(e1, inVars, inSubClocks);
      then (clockKind, BackendDAE.SUBCLOCK(factor, shift, SOME(solverMethodStr)));
    case DAE.CLKCONST(outClockKind)
      then (outClockKind, BackendDAE.SUBCLOCK(rat1, rat0, NONE()));
    case DAE.CALL(path = Absyn.IDENT("subSample"), expLst = {e1, e2})
      algorithm
        (clockKind, BackendDAE.SUBCLOCK(factor, shift, solverMethod)) := getSubClock(e1, inVars, inSubClocks);
        DAE.ICONST(i1) := e2;
        factor := MMath.multRational(factor, MMath.RATIONAL(1, i1));
      then
        (clockKind, BackendDAE.SUBCLOCK(factor, shift, solverMethod));
    case DAE.CALL(path = Absyn.IDENT("superSample"), expLst = {e1, e2})
      algorithm
        (clockKind, BackendDAE.SUBCLOCK(factor, shift, solverMethod)) := getSubClock(e1, inVars, inSubClocks);
        DAE.ICONST(i1) := e2;
        factor := MMath.multRational(factor, MMath.RATIONAL(i1, 1));
      then
        (clockKind, BackendDAE.SUBCLOCK(factor, shift, solverMethod));
    case DAE.CALL(path = Absyn.IDENT("shiftSample"), expLst = {e1, e2, e3})
      algorithm
        (clockKind, BackendDAE.SUBCLOCK(factor, shift, solverMethod)) := getSubClock(e1, inVars, inSubClocks);
        DAE.ICONST(i1) := e2; DAE.ICONST(i2) := e3;
        shift := MMath.addRational(factor, MMath.RATIONAL(i1, i2));
      then
        (clockKind, BackendDAE.SUBCLOCK(factor, shift, solverMethod));
    case DAE.CALL(path = Absyn.IDENT("backSample"), expLst = {e1, e2, e3})
      algorithm
        (clockKind, BackendDAE.SUBCLOCK(factor, shift, solverMethod)) := getSubClock(e1, inVars, inSubClocks);
        DAE.ICONST(i1) := e2; DAE.ICONST(i2) := e3;
        shift := MMath.subRational(factor, MMath.RATIONAL(i1, i2));
      then
        (clockKind, BackendDAE.SUBCLOCK(factor, shift, solverMethod));
    case DAE.CREF(cr, _)
      algorithm
        varIxs := getVarIxs(cr, inVars);
        assert(listLength(varIxs) == 1, err + ExpressionDump.printExpStr(inExp) + ".\n");
      then
        (DAE.INFERRED_CLOCK(), arrayGet(inSubClocks, List.first(varIxs)));
    else
      algorithm
        print(err + ExpressionDump.printExpStr(inExp) + ".\n");
      then
        fail();
  end match;
end getSubClock;

protected function setClockKind
  input DAE.ClockKind inOldClockKind;
  input DAE.ClockKind inClockKind;
  output DAE.ClockKind outClockKind;
algorithm
  outClockKind := match (inOldClockKind, inClockKind)
    case (DAE.INFERRED_CLOCK(), _) then inClockKind;
    case (_, DAE.INFERRED_CLOCK()) then inOldClockKind;
    else
      equation Error.addMessage(Error.CLOCK_CONFLICT, {});
      then fail();
  end match;
end setClockKind;

protected function getSubClkFromVars
  input Integer partitionIdx;
  input Integer clkIdx;
  input BackendDAE.Variables inVars;
  input array<BackendDAE.SubClock> inSubClocks;
  output BackendDAE.SubClock osubClk;
protected
  String clkName;
  DAE.ComponentRef cr;
  list<Integer> varIxs;
  String err = "Internal error -- Function SynchronousFeatures.getSubClkFromVars failed\n";
algorithm
  clkName := "$subclk" + intString(partitionIdx) + "_" + intString(clkIdx);
  cr := DAE.CREF_IDENT(clkName, DAE.T_CLOCK_DEFAULT, {});
  varIxs := getVarIxs(cr, inVars);

  assert(listLength(varIxs) == 1, err);
  osubClk := arrayGet(inSubClocks, List.first(varIxs));
end getSubClkFromVars;

protected function collectSubClocks
  input BackendDAE.Variables inVars;
  input Integer inPartitionsCnt;
  input array<Integer> inPartitions;
  input array<Option<Boolean>> contPartitions;
  input array<Integer> clocksCnt;
  input array<BackendDAE.SubClock> inSubClocks "idx: var";
  output array<BackendDAE.SubClock> outSubClocks "idx: partition";
protected
  Integer i, j, partClocksCnt;
  BackendDAE.SubClock subClk, subClk1;
  Option<Boolean> isCont;
  MMath.Rational factor, shift;
  array<Option<BackendDAE.SubClock>> subClocks;
algorithm
  subClocks := arrayCreate(inPartitionsCnt, NONE());
  outSubClocks := arrayCreate(inPartitionsCnt, BackendDAE.SUBCLOCK(rat0, rat0, NONE()));
  for i in 1:inPartitionsCnt loop
    partClocksCnt := arrayGet(clocksCnt, i) - 1;
    assert(partClocksCnt > 0, "Internal error -- Function SynchronousFeatures.collectSubClocks failed");
    subClk := getSubClkFromVars(i, 1, inVars, inSubClocks);
    if partClocksCnt > 1 then
        for j in 2:partClocksCnt loop
          subClk1 := getSubClkFromVars(i, j, inVars, inSubClocks);
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
end collectSubClocks;

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
        Error.addMessage(Error.SUBCLOCK_CONFLICT, {});
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
        newFactor := setFactorOrShift(oldFactor, newFactor);
        newShift := setFactorOrShift(oldShift, newShift);
        newSolverMethod := setSolverMethod(oldSolverMethod, newSolverMethod);
      then BackendDAE.SUBCLOCK(newFactor, newShift, newSolverMethod);
  end match;
end setSubClock;

protected function setFactorOrShift
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
          Error.addMessage(Error.SUBCLOCK_CONFLICT, {});
          fail();
        end if;
     then newVal;
  end match;
end setFactorOrShift;

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
    case NONE() then SOME(inIsContClockedPartition);
    case SOME(isContClockedPrevPartition)
      guard(inIsContClockedPartition == isContClockedPrevPartition)
      then isContClockedPartition;
    else
      equation
        Error.addSourceMessage(Error.CLOCKED_DSICRETE_CONT_CONFLICT, {}, source);
      then fail();
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
    case (Absyn.IDENT("interval"), _)
      algorithm
        setContClockedPartition(false, inPartitionIdx, inContPartitions, source);
      then
        (DAE.CALL(inPath, inExpLst, inAttr), inNewEqs, inNewVars, inClkCnt);

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
  input Integer inPartitionCnt;
  input array<Integer> inPartitions;
  input BackendDAE.Variables inVars;
  input BackendDAE.IncidenceMatrix mT;
  output BackendDAE.EquationArray outEqs = inEqs;
  output list<BackendDAE.Equation> outNewEqs = {};
  output list<BackendDAE.Var> outNewVars = {};
  output array<Option<Boolean>> outContPartitions;
  output array<Integer> oClksCnt;
protected
  BackendDAE.Equation eq;
  Integer i, j, eqsSize, partitionIdx, cnt;
  BackendDAE.Equation eq;
  list<Integer> intLst;
  BackendDAE.EquationAttributes eqAttr;
  array<Integer> whenClocks;
  array<list<Integer>> partitionsWhenClocks;
  list<Integer> partitionWhenClocks;
  DAE.ComponentRef cr;
  BackendDAE.Var var;
  SourceInfo source;
algorithm
  eqsSize := BackendDAEUtil.equationArraySize(outEqs);
  outContPartitions := arrayCreate(inPartitionCnt, NONE());
  oClksCnt := arrayCreate(inPartitionCnt, 1);
  whenClocks := arrayCreate(eqsSize, 0);
  for i in 1 : eqsSize loop
    eq := BackendEquation.equationNth1(outEqs, i);
    eqAttr := BackendEquation.getEquationAttributes(eq);
    eqAttr := match eqAttr
      local
        Integer whenIdx;
        Boolean diff;
        BackendDAE.LoopInfo loopInfo;
      case BackendDAE.EQUATION_ATTRIBUTES(diff, BackendDAE.CLOCKED_EQUATION(whenIdx), loopInfo)
        algorithm arrayUpdate(whenClocks, i, whenIdx) "Set when clock no for equation";
        then BackendDAE.EQUATION_ATTRIBUTES(diff, BackendDAE.DYNAMIC_EQUATION(), loopInfo);
      else eqAttr;
    end match;
    eq := BackendEquation.setEquationAttributes(eq, eqAttr);
    partitionIdx := arrayGet(inPartitions, i);
    DAE.SOURCE(info = source) := BackendEquation.equationSource(eq);
    (eq, (outNewEqs, outNewVars, outContPartitions, _, oClksCnt, _, _, _, _))
        := BackendEquation.traverseExpsOfEquation (
            eq, collectSubclkInfoExp1, ( outNewEqs, outNewVars, outContPartitions, source,
                                         oClksCnt,  partitionIdx, inPartitions, inVars, mT ) );
    BackendEquation.setAtIndex(outEqs, i, eq);
    j := arrayGet(whenClocks, i);
    partitionsWhenClocks := arrayCreate(inPartitionCnt, {});
    partitionWhenClocks := arrayGet(partitionsWhenClocks, partitionIdx);
    if j <> 0 and List.notMember(j, partitionWhenClocks) then
      arrayUpdate(partitionsWhenClocks, partitionIdx, j::partitionWhenClocks);
    end if;
  end for;
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
  output BackendDAE.EquationArray outClockedEqs;
protected
  list<BackendDAE.Equation> clockEqs = {}, clockedEqs = {};
  BackendDAE.Equation eq;
  Boolean notClock;
  Integer i;
algorithm
  for i in 1:BackendDAEUtil.equationArraySize(inEqs) loop
    eq := BackendEquation.equationNth1(inEqs, i);
    (clockEqs, clockedEqs) := if isClockEquation(eq)
                              then (eq::clockEqs, clockedEqs) else (clockEqs, eq::clockedEqs);
  end for;
  outClockEqs := BackendEquation.listEquation(clockEqs);
  outClockedEqs := BackendEquation.listEquation(clockedEqs);
end splitClockEqs;

protected function splitClockVars
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables outClockVars;
  output BackendDAE.Variables outClockedVars;
protected
  list<BackendDAE.Var> listVars, clockVars = {}, clockedVars = {};
  BackendDAE.Var var;
  DAE.Type ty;
algorithm
  listVars := BackendVariable.varList(inVars);
  for var in listVars loop
    BackendDAE.VAR(varType = ty) := var;
    if Types.isClockOrSubTypeClock(ty) then
        clockVars := var :: clockVars;
    else
        clockedVars := var :: clockedVars;
    end if;
  end for;
  outClockVars := BackendVariable.listVar(clockVars);
  outClockedVars := BackendVariable.listVar(clockedVars);
end splitClockVars;

protected function substituteParitionOpExps
"Each non-trivial expression (non-literal, non-constant, non-parameter, non-variable), expr_i, appearing
 as first argument of any clock conversion operator or in base clock constructor is recursively replaced by a unique variable, $var_i,
 and the equation $var_i = expr_i is added to the equation set."
  input BackendDAE.EqSystem inSyst;
  output BackendDAE.EqSystem outSyst;
algorithm
  outSyst := match inSyst
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqs;
      BackendDAE.EqSystem syst;
      list<BackendDAE.Equation> newEqs = {};
      list<BackendDAE.Var> newVars = {};
      Integer cnt = 1;
      BackendDAE.Equation eq;
    case syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs)
      algorithm
        for i in 1:BackendDAEUtil.equationArraySize(eqs) loop
          eq := BackendEquation.equationNth1(eqs, i);
          (eq, (newEqs, newVars, cnt)) :=
          BackendEquation.traverseExpsOfEquation(eq, substituteParitionOpExp, (newEqs, newVars, cnt));
          newEqs := eq::newEqs;
        end for;
        syst.orderedEqs := BackendEquation.listEquation(listReverse(newEqs));
        syst.orderedVars := BackendVariable.addVars(newVars, vars);
      then BackendDAEUtil.clearEqSyst(syst);
  end match;
end substituteParitionOpExps;

protected function substituteParitionOpExp
  input DAE.Exp inExp;
  input tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>, Integer> inTpl;
  output DAE.Exp outExp;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>, Integer> outTpl;
algorithm
  (outExp, outTpl) := Expression.traverseExpBottomUp(inExp, substituteParitionOpExp1, inTpl);
end substituteParitionOpExp;

protected function substituteParitionOpExp1
  input DAE.Exp inExp;
  input tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>, Integer> inTpl;
  output DAE.Exp outExp;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>, Integer> outTpl;
protected
  list<BackendDAE.Equation> newEqs;
  list<BackendDAE.Var> newVars;
  Integer cnt;
algorithm
  (newEqs, newVars, cnt) := inTpl;
  (outExp, outTpl) := match inExp
    local
      Absyn.Path path;
      list<DAE.Exp> exps;
      DAE.CallAttributes attr;
      DAE.ClockKind clk;
    case DAE.CLKCONST(clk)
      equation
        (clk, newEqs, newVars, cnt) = substClock(clk, newEqs, newVars, cnt);
      then
        (DAE.CLKCONST(clk), (newEqs, newVars, cnt));
    case DAE.CALL(path = path, expLst = exps, attr = attr)
      then
        substituteExpsCall(path, exps, attr, newEqs, newVars, cnt);
    else
      (inExp, inTpl);
  end match;
end substituteParitionOpExp1;

protected function substClock
  input DAE.ClockKind inClk;
  input list<BackendDAE.Equation> inNewEqs;
  input list<BackendDAE.Var> inNewVars;
  input Integer inCnt;
  output DAE.ClockKind outClk;
  output list<BackendDAE.Equation> outNewEqs;
  output list<BackendDAE.Var> outNewVars;
  output Integer outCnt;
algorithm
  (outClk, outNewEqs, outNewVars, outCnt) := match inClk
    local
      DAE.Exp e;
      Integer i;
      Real f;
      list<BackendDAE.Equation> eqs;
      list<BackendDAE.Var> vars;
      Integer cnt;
    case DAE.BOOLEAN_CLOCK(e, f)
      equation
        (e, eqs, vars, cnt) = substClockExp(e, inNewEqs, inNewVars, inCnt);
      then
        (DAE.BOOLEAN_CLOCK(e, f), eqs, vars, cnt);
    case DAE.REAL_CLOCK(e)
      equation
        (e, eqs, vars, cnt) = substClockExp(e, inNewEqs, inNewVars, inCnt);
      then
        (DAE.REAL_CLOCK(e), eqs, vars, cnt);
    case DAE.INTEGER_CLOCK(e, i)
      equation
        (e, eqs, vars, cnt) = substClockExp(e, inNewEqs, inNewVars, inCnt);
      then
        (DAE.INTEGER_CLOCK(e, i), eqs, vars, cnt);
    else
      (inClk, inNewEqs, inNewVars, inCnt);
  end match;
end substClock;

protected function substClockExp
  input DAE.Exp inExp;
  input list<BackendDAE.Equation> inNewEqs;
  input list<BackendDAE.Var> inNewVars;
  input Integer inCnt;
  output DAE.Exp outExp;
  output list<BackendDAE.Equation> outNewEqs;
  output list<BackendDAE.Var> outNewVars;
  output Integer outCnt;
protected
  DAE.Exp e;
  list<BackendDAE.Equation> eqs;
  list<BackendDAE.Var> vars;
  Integer cnt;
algorithm
  ({outExp}, outNewEqs, outNewVars, outCnt) := substExp({inExp}, inNewEqs, inNewVars, inCnt);
  outExp := match outExp
    local DAE.Type ty;
    case DAE.CREF(_, ty)
      then Expression.makePureBuiltinCall("previous", {outExp}, ty);
    else outExp;
  end match;
end substClockExp;

protected function substituteExpsCall
  input Absyn.Path inPath;
  input list<DAE.Exp> inExps;
  input DAE.CallAttributes inAttr;
  input list<BackendDAE.Equation> inEqs;
  input list<BackendDAE.Var> inVars;
  input Integer inCnt;
  output DAE.Exp outExp;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Var>, Integer> outTpl;
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
    else then false;
  end match;
  (exps, eqs, vars, cnt) :=
      if replace then substExp(inExps, inEqs, inVars, inCnt)
                 else (inExps, inEqs, inVars, inCnt);
  outExp := DAE.CALL(inPath, exps, inAttr);
  outTpl := (eqs, vars, cnt);
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
  list<DAE.Exp> exps;
  list<BackendDAE.Equation> eqs;
  list<BackendDAE.Var> vars;
  Integer cnt;
  Boolean create;
  DAE.Exp e;
algorithm
  e := List.first(inExps);
  create := match e
    case DAE.CREF() then false;
    case DAE.RCONST() then false;
    case DAE.SCONST() then false;
    case DAE.BCONST() then false;
    case DAE.CLKCONST() then false;
    case DAE.ENUM_LITERAL() then false;
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

protected function getVars
  input DAE.ComponentRef inComp;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue inComp
    local
      list<BackendDAE.Var> vars;
    case _
      equation
        (vars, _) = BackendVariable.getVar(inComp, inVariables);
      then vars;
    else
      then {};
  end matchcontinue;
end getVars;

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
  Integer partitionCnt, i, j, eqIdx;
  DAE.ComponentRef cr;
  list<Integer> varIxs;
  BackendDAE.EqSystem syst;
  array<Integer> eqsPartition, reqsPartition;
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
  partitionCnt := partitionIndependentBlocks0(m, mT, rm, rmT, eqsPartition, reqsPartition);
  if partitionCnt > 1 then
    (systs, outUnpartRemEqs) := partitionIndependentBlocksSplitBlocks(partitionCnt, syst, eqsPartition, reqsPartition, mT, false);
  else
    (systs, outUnpartRemEqs) := ({syst}, {});
  end if;

  //Partition finished
  clockedEqs := arrayCreate(BackendDAEUtil.equationArraySize(eqs), NONE());
  clockedVars := arrayCreate(BackendVariable.varsSize(vars), NONE());
  clockedPartitions := arrayCreate(if partitionCnt > 0 then partitionCnt else 1, NONE());
  //Detect clocked equations and variables
  for j in 1:BackendDAEUtil.equationArraySize(eqs) loop
    eq := BackendEquation.equationNth1(eqs, j);
    (partitionType, refsInfo) := detectEqPatition(eq);
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
      DAE.Exp e;
      list<list<BackendDAE.Equation>> trueEqs;
      list<BackendDAE.Equation> falseEqs, listEqs;
      BackendDAE.Equation eq;
      SourceInfo info;
    case BackendDAE.EQUATION(scalar = e) then isClockExp(e);
    case BackendDAE.ARRAY_EQUATION(right = e) then isClockExp(e);
    case BackendDAE.SOLVED_EQUATION(exp = e) then isClockExp(e);
    case BackendDAE.RESIDUAL_EQUATION(exp = e) then isClockExp(e);
    case BackendDAE.ALGORITHM() then false;
    case BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_EQ(right=e)) then isClockExp(e);
    case BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_STMTS()) then false;
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
        print("Internal error -- Function SynchronousFeatures.isClockEquation failed.\n");
      then fail();
  end match;
end isClockEquation;

protected function detectEqPatition
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
      BackendEquation.traverseExpsOfEquation(inEq, detectEqPatitionExp, (partitionType, {}, info));
  isClockEq := isClockEquation(inEq);
  outPartitionType := if isClockEq then setClockedPartition(SOME(true), partitionType, NONE(), info)
                                   else partitionType;
end detectEqPatition;

protected function reverseBoolOption
  input Option<Boolean> inp;
  output Option<Boolean> out;
algorithm
  out := match inp
    local
      Boolean v;
    case SOME(v) then SOME(not v);
    else inp;
  end match;
end reverseBoolOption;

protected function printPartitionType
  input Option<Boolean> isClockedPartition;
  output String out;
algorithm
  out := match isClockedPartition
    case NONE() then "UNSPECIFIED_PARTITION";
    case SOME(false) then "CONT_PARTITION";
    case SOME(true) then "CLOCKED_PARTITION";
  end match;
end printPartitionType;

protected function detectEqPatitionExp
  input DAE.Exp inExp;
  input tuple<Option<Boolean>, list<tuple<DAE.ComponentRef, Boolean>>, SourceInfo> inTpl;
  output DAE.Exp outExp;
  output tuple<Option<Boolean>, list<tuple<DAE.ComponentRef, Boolean>>, SourceInfo> outTpl;
algorithm
  (outExp, outTpl) := Expression.traverseExpTopDown(inExp, detectEqPatitionExp1, inTpl);
end detectEqPatitionExp;

protected function detectEqPatitionExp1
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
      then detectEqPatitionCall(path, exps, refs, partition, info);
    else (partition, refs, true);
  end match;
  outTpl := (partition, refs, info);
end detectEqPatitionExp1;

protected function detectEqPatitionCall
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
      then detectEqPatitionCall1(false, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("sample"), {e, e1})
      then detectEqPatitionCall1(true, false, inPartition, e, inRefs, info);
    case (Absyn.IDENT("subSample"), {e, e1})
      then detectEqPatitionCall1(true, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("superSample"), {e, e1})
      then detectEqPatitionCall1(true, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("shiftSample"), {e, e1, e2})
      then detectEqPatitionCall1(true, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("backSample"), {e, e1, e2})
      then detectEqPatitionCall1(true, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("noClock"), {e})
      then detectEqPatitionCall1(true, true, inPartition, e, inRefs, info);
    else (inPartition, inRefs, true);
  end match;
end detectEqPatitionCall;

protected function detectEqPatitionCall1
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
        print("Internal error -- Function SynchronousFeatures.detectEqPatitionCall1 failed\n");
      then fail();
  end match;
end detectEqPatitionCall1;

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
    case NONE() then (Error.CONT_CLOCKED_PARTITION_CONFLICT_EQ, {});
    case SOME(cr) then ( Error.CONT_CLOCKED_PARTITION_CONFLICT_VAR,
                         {ComponentReference.printComponentRefStr(cr)} );
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
  input array<Integer> ixs;
  input array<Integer> rixs;
  output Integer on = 0;
algorithm
  for i in arrayLength(m):-1:1 loop
    on := if partitionIndependentBlocksEq(i, on + 1, m, mT, rm, rmT, ixs, rixs) then on + 1 else on;
  end for;
  for i in arrayLength(rm):-1:1 loop
    on := if partitionIndependentBlocksReq(i, on + 1, m, mT, rm, rmT, ixs, rixs) then on + 1 else on;
  end for;
end partitionIndependentBlocks0;

protected function partitionIndependentBlocksEq
  input Integer ix;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input BackendDAE.IncidenceMatrix rm;
  input BackendDAE.IncidenceMatrixT rmT;
  input array<Integer> ixs;
  input array<Integer> rixs;
  output Boolean ochange;
algorithm
  ochange := arrayGet(ixs, ix) == 0;

  if ochange then
    arrayUpdate(ixs, ix, n);
    for i in arrayGet(m, ix) loop
      for j in arrayGet(mT, intAbs(i)) loop
        partitionIndependentBlocksEq(intAbs(j), n, m, mT, rm, rmT, ixs, rixs);
      end for;
      for j in arrayGet(rmT, intAbs(i)) loop
        partitionIndependentBlocksReq(intAbs(j), n, m, mT, rm, rmT, ixs, rixs);
      end for;
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
  input array<Integer> ixs;
  input array<Integer> rixs;
  output Boolean ochange;
algorithm
  ochange := arrayGet(rixs, ix) == 0;
  if ochange then
    arrayUpdate(rixs, ix, n);
    for i in arrayGet(rm, ix) loop
      for j in arrayGet(mT, intAbs(i)) loop
        partitionIndependentBlocksEq(intAbs(j), n, m, mT, rm, rmT, ixs, rixs);
      end for;
      for j in arrayGet(rmT, intAbs(i)) loop
        partitionIndependentBlocksReq(intAbs(j), n, m, mT, rm, rmT, ixs, rixs);
      end for;
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
  input Boolean throwNoError;
  output list<BackendDAE.EqSystem> systs = {};
  output list<BackendDAE.Equation> unpartRemovedEqs = {};
protected
  array<list<BackendDAE.Equation>> ea, rea;
  array<list<BackendDAE.Var>> va;
  Integer i1, i2;
  String s1, s2;
  Boolean b, b1 = true;
  BackendDAE.EqSystem syst;
  list<BackendDAE.Equation> rest;
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

  rest := partitionEquations(BackendDAEUtil.equationArraySize(inSyst.orderedEqs), inSyst.orderedEqs, ixs, ea);
  assert(listLength(rest) == 0, "Equations partitioning failure in SynchronousFeatures.partitionIndependentBlocksSplitBlocks");
  unpartRemovedEqs := partitionEquations(BackendDAEUtil.equationArraySize(inSyst.removedEqs), inSyst.removedEqs, rixs, rea);
  partitionVars(i2, inSyst.orderedEqs, inSyst.orderedVars, ixs, mT, va);

  for i in 1:n loop
    (syst, (b, _)) := createEqSystem(ea[i], va[i], rea[i], (true, throwNoError));
    systs := syst :: systs;
    b1 := b1 and b;
  end for;
  true := throwNoError or b1;
  systs := listReverse(systs);

end partitionIndependentBlocksSplitBlocks;

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
  input Integer n;
  input BackendDAE.EquationArray arr;
  input array<Integer> ixs;
  input array<list<BackendDAE.Equation>> ea;
  output list<BackendDAE.Equation> restEqs = {};
protected
  Integer ix;
  list<BackendDAE.Equation> lst;
  BackendDAE.Equation eq;
algorithm
  for i in n:-1:1 loop
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

protected function partitionVars
  input Integer n;
  input BackendDAE.EquationArray arr;
  input BackendDAE.Variables vars;
  input array<Integer> ixs;
  input BackendDAE.IncidenceMatrix mT;
  input array<list<BackendDAE.Var>> va;
protected
  Integer ix, eqix;
  list<BackendDAE.Var> lst;
  BackendDAE.Var v;
  Boolean b;
  DAE.ComponentRef cr;
  String name;
  SourceInfo info;
algorithm
  for i in n:-1:1 loop
    v := BackendVariable.getVarAt(vars, i);
    cr := BackendVariable.varCref(v);

    // Select any equation that could define this variable
    if listEmpty(mT[i]) then
      name := ComponentReference.printComponentRefStr(cr);
      info := DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(v));
      Error.addSourceMessage(Error.EQUATIONS_VAR_NOT_DEFINED, {name}, info);
      fail();
    end if;

    // print("adding var " + intString(i) + " to group ???\n");
    eqix::_ := mT[i];
    eqix := intAbs(eqix);
    // print("var " + intString(i) + " has eq " + intString(eqix) + "\n");
    // That's the index of the indep.system
    ix := ixs[eqix];
    lst := va[ix];
    lst := v::lst;
    // print("adding var " + intString(i) + " to group " + intString(ix) + " (comes from eq: "+ intString(eqix) +")\n");
    arrayUpdate(va, ix, lst);
  end for;
end partitionVars;

protected function setValue
  input BackendDAE.Var inVar;
  input Values.Value inVal;
  output BackendDAE.Var outVar;
protected
  DAE.ComponentRef varName;
  BackendDAE.VarKind varKind;
  DAE.VarDirection varDirection;
  DAE.VarParallelism varParallelism;
  BackendDAE.Type varType;
  Option<DAE.Exp> bindExp;
  DAE.InstDims arryDim;
  DAE.ElementSource source;
  Option<DAE.VariableAttributes> values;
  Option<BackendDAE.TearingSelect> tearingSelectOption;
  Option<SCode.Comment> comment;
  DAE.ConnectorType connectorType;
  DAE.VarInnerOuter innerOuter;
  Boolean unreplaceable;
algorithm
  BackendDAE.VAR( varName = varName, varKind = varKind, varDirection = varDirection,
                  varParallelism = varParallelism, varType = varType, bindExp = bindExp,
                  arryDim = arryDim, source = source, values = values,
                  tearingSelectOption = tearingSelectOption, comment = comment,
                  connectorType = connectorType, innerOuter = innerOuter, unreplaceable = unreplaceable) := inVar;
  outVar := BackendDAE.VAR( varName = varName, varKind = varKind, varDirection = varDirection,
                            varParallelism = varParallelism, varType = varType, bindExp = bindExp,
                            arryDim = arryDim, source = source, values = values, bindValue = SOME(inVal),
                            tearingSelectOption = tearingSelectOption, comment = comment,
                            connectorType = connectorType, innerOuter = innerOuter, unreplaceable = unreplaceable);
end setValue;


annotation(__OpenModelica_Interface="backend");
end SynchronousFeatures;
