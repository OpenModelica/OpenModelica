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
protected import DAEDump;
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

public function synchronousFeatures
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs, contSysts, clockedSysts;
  BackendDAE.Shared shared;
algorithm
  (clockedSysts, contSysts) := List.splitOnTrue(inDAE.eqs, BackendDAEUtil.isClockedSyst);

  if listLength(clockedSysts) > 0 then
    shared := inDAE.shared;

    (clockedSysts, shared) := treatClockedStates(clockedSysts, shared);

    systs := listAppend(contSysts, clockedSysts);
    outDAE := BackendDAE.DAE(systs, shared);

    if Flags.isSet(Flags.DUMP_SYNCHRONOUS) then
      print("synchronous features post-phase: synchronousFeatures\n\n");
      BackendDump.dumpEqSystems(systs, "clock partitioning");
      BackendDump.dumpBasePartitions(shared.partitionsInfo.basePartitions, "Base clocks");
      BackendDump.dumpSubPartitions(shared.partitionsInfo.subPartitions, "Sub clocks");
    end if;
  else
    outDAE := inDAE;
  end if;
end synchronousFeatures;

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
    shared.removedEqs := BackendEquation.addList(unpartRemEqs, shared.removedEqs);
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

  unpartRemEqs := createBoolClockWhenClauses(shared, unpartRemEqs);
  shared.removedEqs := BackendEquation.addList(unpartRemEqs, shared.removedEqs);

  systs := listAppend(contSysts, clockedSysts);
  outDAE := BackendDAE.DAE(systs, shared);

  if Flags.isSet(Flags.DUMP_SYNCHRONOUS) then
    print("synchronous features pre-phase: synchronousFeatures\n\n");
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
        list<BackendDAE.Equation> lstEqs = {};
        BackendDAE.Equation eq;
        list<DAE.ComponentRef> derVars = {};
        BackendDAE.Var var;
        DAE.Exp exp, exp2;
      case syst as BackendDAE.EQSYSTEM(orderedEqs = eqs)
        algorithm
          BackendDAE.CLOCKED_PARTITION(idx) := syst.partitionKind;
          subPartition := shared.partitionsInfo.subPartitions[idx];
          solverMethod := BackendDump.optionString(getSubClockSolverOpt(subPartition.clock));
          // check solverMethod
          if stringLength(solverMethod) > 7 and substring(solverMethod, 1, 8) == "Explicit" then
            if solverMethod <> "ExplicitEuler" then
              Error.addMessage(Error.CLOCK_SOLVERMETHOD, {"ExplicitEuler", solverMethod});
              solverMethod := "ExplicitEuler";
            end if;
          elseif stringLength(solverMethod) > 0 and solverMethod <> "ImplicitEuler"
              and solverMethod <> "SemiImplicitEuler" and solverMethod <> "ImplicitTrapezoid" then
            Error.addMessage(Error.CLOCK_SOLVERMETHOD, {"ImplicitEuler", solverMethod});
            solverMethod := "ImplicitEuler";
          end if;
          // replace der(x) with $DER.x and collect derVars x
          for i in 1:BackendEquation.getNumberOfEquations(eqs) loop
            eq := BackendEquation.get(eqs, i);
            (eq, derVars) := BackendEquation.traverseExpsOfEquation(eq, getDerVars1, derVars);
            lstEqs := eq :: lstEqs;
          end for;
          // add all $DER.x as additional variables
          for derVar in derVars loop
            var := listGet(BackendVariable.getVar(derVar, syst.orderedVars), 1);
            var := BackendDAE.VAR(ComponentReference.crefPrefixDer(derVar), BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), var.varType, NONE(), NONE(), var.arryDim, DAE.emptyElementSource, NONE(), NONE(), DAE.BCONST(false), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
            syst.orderedVars := BackendVariable.addVar(var, syst.orderedVars);
          end for;
          // add defining equations for $DER.x, depending on solverMethod
          for derVar in derVars loop
            var := listGet(BackendVariable.getVar(derVar, syst.orderedVars), 1);
            exp := DAE.CALL(Absyn.IDENT(name = "der"), {DAE.CREF(derVar, var.varType)}, DAE.callAttrBuiltinImpureReal);
            exp := substituteFiniteDifference(exp);
            exp2 := DAE.CREF(ComponentReference.crefPrefixDer(derVar), var.varType);
            if solverMethod == "ExplicitEuler" then
              // introduce states to delay derivatives; see MLS 3.3, section 16.8.2 Solver Methods
              exp2 := DAE.CALL(Absyn.IDENT(name = "previous"), {exp2}, DAE.callAttrBuiltinImpureReal);
            elseif solverMethod == "ImplicitTrapezoid" then
              // evaluate derivatives at beginning and end of interval; see MLS 3.3, section 16.8.2 Solver Methods
              exp2 := DAE.BINARY(exp2, DAE.ADD(DAE.T_REAL_DEFAULT),
                                 DAE.CALL(Absyn.IDENT(name = "previous"), {exp2}, DAE.callAttrBuiltinImpureReal));
              exp2 := DAE.BINARY(DAE.RCONST(0.5), DAE.MUL(DAE.T_REAL_DEFAULT), exp2);
            end if;
            // clocked continuous states are fixed at first tick
            exp2 := DAE.IFEXP(DAE.CALL(Absyn.IDENT(name = "firstTick"), {}, DAE.callAttrBuiltinImpureBool),
                              DAE.RCONST(0), exp2);
            eq := BackendDAE.EQUATION(exp, exp2, var.source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
            lstEqs := eq :: lstEqs;
          end for;
          syst.orderedEqs := BackendEquation.listEquation(listReverse(lstEqs));
          if solverMethod == "SemiImplicitEuler" then
            // access previous values of clocked continuous states
            for i in 1:BackendEquation.getNumberOfEquations(eqs) loop
              eq := BackendEquation.get(eqs, i);
              (eq, _) := BackendEquation.traverseExpsOfEquation(eq, shiftDerVars1, derVars);
              eqs := BackendEquation.setAtIndex(eqs, i, eq);
            end for;
          end if;
          shared := markClockedStates(syst, shared, derVars);
        then syst;
    end match;
    outSysts := BackendDAEUtil.clearEqSyst(syst1) :: outSysts;
  end for;
  outSysts := listReverse(outSysts);
end treatClockedStates;

protected function getDerVars1 "helper to getDerVars"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inDerVars;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outDerVars;
algorithm
  (outExp, outDerVars) := Expression.traverseExpBottomUp(inExp, getDerVars, inDerVars);
end getDerVars1;

protected function getDerVars
"Get all crefs that appear in a der() operator and replace der(x) with $DER.x.
 author: rfranke"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inDerVars;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outDerVars = inDerVars;
algorithm
  outExp := match inExp
    local
      DAE.ComponentRef x;
      DAE.Type ty;
    case DAE.CALL(path = Absyn.IDENT(name = "der"),
                  expLst = {DAE.CREF(componentRef = x, ty = ty)})
      algorithm
        if not ComponentReference.crefInLst(x, outDerVars) then
          outDerVars := x :: outDerVars;
        end if;
      then DAE.CREF(ComponentReference.crefPrefixDer(x), ty);
    else inExp;
  end match;
end getDerVars;

protected function shiftDerVars1 "helper to shiftDerVars"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inDerVars;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outDerVars;
algorithm
  (outExp, outDerVars) := Expression.traverseExpBottomUp(inExp, shiftDerVars, inDerVars);
end shiftDerVars1;

protected function shiftDerVars
"Apply previous() operator to all inDerVars.
 author: rfranke"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inDerVars;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outDerVars = inDerVars;
algorithm
  outExp := match inExp
    local
      List<DAE.Exp> expLst;
      DAE.CallAttributes attr;
      DAE.ComponentRef x;
      DAE.Type ty;
      DAE.Exp exp;
    // introduce previous()
    case DAE.CREF(componentRef = x)
      guard ComponentReference.crefInLst(x, inDerVars)
      algorithm
        exp := DAE.CALL(Absyn.IDENT(name = "previous"), {inExp}, DAE.callAttrBuiltinImpureReal);
      then exp;
    // check for possibly introduced der(previous())
    case DAE.CALL(path = Absyn.IDENT(name = "der"),
                  expLst = {DAE.CALL(path = Absyn.IDENT(name = "previous"), expLst = expLst)},
                  attr = attr as DAE.CALL_ATTR())
      algorithm
        exp := DAE.CALL(Absyn.IDENT(name = "der"), expLst, attr);
      then exp;
    // check for possibly introduced previous(previous())
    case DAE.CALL(path = Absyn.IDENT(name = "previous"),
                  expLst = {DAE.CALL(path = Absyn.IDENT(name = "previous"), expLst = expLst)},
                  attr = attr as DAE.CALL_ATTR())
      algorithm
        exp := DAE.CALL(Absyn.IDENT(name = "previous"), expLst, attr);
      then exp;
    // do nothing per default
    else inExp;
  end match;
end shiftDerVars;

protected function substituteFiniteDifference1 "helper to substituteFiniteDifference"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inDerVars;
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outDerVars;
algorithm
  (outExp, outDerVars) := Expression.traverseExpBottomUp(inExp, substituteFiniteDifference, inDerVars);
end substituteFiniteDifference1;

protected function substituteFiniteDifference
"Convert continous-time to clocked expression by replacing
 der(x) -> (x - previous(x)) / interval().
 author: rfranke"
  input DAE.Exp inExp;
  input list<DAE.ComponentRef> inDerVars = {};
  output DAE.Exp outExp;
  output list<DAE.ComponentRef> outDerVars;
algorithm
  (outExp, outDerVars) := match inExp
    local
      List<DAE.Exp> expLst;
      DAE.CallAttributes attr;
      DAE.ComponentRef x;
      DAE.Type ty;
      DAE.Exp exp;
    case DAE.CALL(path = Absyn.IDENT(name = "der"),
                  expLst = expLst as {DAE.CREF(componentRef = x)},
                  attr = attr as DAE.CALL_ATTR(ty = ty))
      algorithm
        exp := DAE.CALL(Absyn.IDENT(name = "previous"), expLst, attr);
        exp := DAE.BINARY(DAE.CREF(x, ty), DAE.SUB(DAE.T_REAL_DEFAULT), exp);
        exp := DAE.BINARY(exp, DAE.DIV(DAE.T_REAL_DEFAULT),
                          DAE.CALL(Absyn.IDENT(name = "interval"), {},
                                   DAE.callAttrBuiltinImpureReal));
      then (exp, x :: inDerVars);
    else (inExp, inDerVars);
  end match;
end substituteFiniteDifference;

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
  for i in 1:BackendEquation.getNumberOfEquations(inSyst.orderedEqs) loop
    eq := BackendEquation.get(inSyst.orderedEqs, i);
    (_, prevVars) := BackendEquation.traverseExpsOfEquation(eq, collectPrevVars, prevVars);
  end for;
  for i in 1:BackendEquation.getNumberOfEquations(inSyst.removedEqs) loop
    eq := BackendEquation.get(inSyst.removedEqs, i);
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
      case syst as BackendDAE.EQSYSTEM(orderedEqs = eqs)
        algorithm
          lstEqs := {};
          for i in 1:BackendEquation.getNumberOfEquations(eqs) loop
            eq := BackendEquation.get(eqs, i);
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

protected function getSubPartitionAdjacency
"gets the adjacency matrix for the sub clock partitions and a dependency graph which is used to determine the execution order.
The edge weights are the sub-clocks resulting from the sub clock interfaces.
The sub clock interfaces are both original and inverted to get from one partition to another.
The dependency graph is based on the causality of the sub partition interface functions.
author: vwaurich 2017-06"
  input Integer numPartitions;
  input Integer baseClockEq;
  input list<Integer> subPartitionInterfaceEqs;
  input array<Integer> eqPartMap;
  input array<Integer> varPartMap;
  input array<Boolean> clockedVarsMask;
  input BackendDAE.EquationArray eqs;
  input BackendDAE.Variables vars;
  output array<list<tuple<Integer,BackendDAE.SubClock>>> partAdjacency;//idx: partition, entries: connections to other partitions with subclocks
  output array<Integer> order;
protected
  Boolean infered;
  Integer part, part1, part2, var1, var2;
  list<Integer> partLst,orderLst;
  BackendDAE.SubClock subClk1,subClk2;
  array<Boolean> partIsAssigned;
  list<tuple<Integer,BackendDAE.SubClock>> adjParts;
  array<Integer> partitionParents;
  array<Boolean> partitionParentsVisited;
algorithm
  //build adjacency matrix for subclock partitions and dependency (parent) graph
  partAdjacency := arrayCreate(numPartitions,{});
  partitionParents := arrayCreate(numPartitions,-1);
  for subPartEq in subPartitionInterfaceEqs loop
    //part1,subClk1 is the output of the sub partition interface function calls, this is used for ordering
    (infered,part1,var1,subClk1,part2,var2,subClk2) := getConnectedSubPartitions(BackendEquation.get(eqs,subPartEq),varPartMap,vars);
    //for adjacency relations, check only concrete sub partition interfaces not infered ones
    if not intEq(part1,0) and not intEq(part2,0) then
      addPartAdjacencyEdge(part1,subClk1,part2,subClk2,partAdjacency);
    end if;
    //to get the  parent relations, check only sub partition interfaces which don't interface clock-variables
    if clockedVarsMask[var1] and clockedVarsMask[var2] then
      partitionParents[part1]:= part2;
    end if;
  end for;
  /*
  for i in 1:numPartitions loop
    for j in arrayGet(partAdjacency,i) loop
      print("partition "+intString(i)+" is connected to partition "+intString(Util.tuple21(j))+" with subCLock "+BackendDump.subClockString(Util.tuple22(j))+"\n");
    end for;
  end for;

  for i in 1:numPartitions loop
      print("partition "+intString(i)+" has parent "+intString(partitionParents[i])+"\n");
  end for;
  */

  //get the order
  partLst := List.intRange(numPartitions);
  partitionParentsVisited := arrayCreate(numPartitions,false);
  orderLst := {};
  while not listEmpty(partLst) loop
    part::partLst := partLst;
    if not partitionParentsVisited[part] then
      //partition without parent, not yet visited
      if intEq(partitionParents[part],-1) then
        orderLst := part::orderLst;
        partitionParentsVisited[part] := true;
      //partition with parents, parent not yet visited
      elseif intNe(partitionParents[part],-1)  and intNe(partitionParents[part],part)and not partitionParentsVisited[partitionParents[part]] then
        partLst := part::partLst;
        partLst := partitionParents[part]::partLst;
      //partition with parents, parent visited
      elseif intNe(partitionParents[part],-1) and partitionParentsVisited[partitionParents[part]] then
        orderLst := part::orderLst;
        partitionParentsVisited[part] := true;
      end if;

    end if;
  end while;
  order := listArray(listReverse(orderLst));
end getSubPartitionAdjacency;

protected function getSubClockForClkConstructor
"gets the corresponding subclock between 2 clock constructors
author: vwaurich 2017-06"
  input DAE.ClockKind refClock;
  input DAE.ClockKind clk;
  output BackendDAE.SubClock subClk;
algorithm
  subClk := match(refClock,clk)
    local
      Integer i1,i2,i3,i4;
      Real r1,r2;
  case(DAE.INTEGER_CLOCK(DAE.ICONST(i1),DAE.ICONST(i2)), DAE.INFERRED_CLOCK())
    algorithm
    then BackendDAE.SUBCLOCK(MMath.RATIONAL(i2,i1), MMath.RAT0,NONE());
  case(DAE.INTEGER_CLOCK(DAE.ICONST(i1),DAE.ICONST(i2)), DAE.INTEGER_CLOCK(DAE.ICONST(i3),DAE.ICONST(i4)))
    algorithm
    then BackendDAE.SUBCLOCK(MMath.divRational(MMath.RATIONAL(i2,i1),MMath.RATIONAL(i4,i3)),MMath.RAT0,NONE());
  case(DAE.REAL_CLOCK(DAE.RCONST(r1)), DAE.INFERRED_CLOCK())
    algorithm
    then BackendDAE.SUBCLOCK(MMath.RATIONAL(1, realInt(1.0/r1)), MMath.RAT0, NONE());
  case(DAE.REAL_CLOCK(DAE.RCONST(r1)), DAE.REAL_CLOCK(DAE.RCONST(r2)))
    algorithm
    then BackendDAE.SUBCLOCK(MMath.divRational(MMath.RATIONAL(1, realInt(1.0/r1)),MMath.RATIONAL(1,realInt(1.0/r2))), MMath.RAT0, NONE());
  else
    algorithm
    //Please add the missing cases.
    Error.addMessage(Error.INTERNAL_ERROR, {"SynchrnonousFeatures.getSubClockForClkConstructor failed.\n"});
    then fail();
  end match;
end getSubClockForClkConstructor;

protected function setSolverSubClock
"if the base clock is a solver clock, put the solver in the subclock and clean the base clock from the solver clock
author: vwaurich 2017-06"
  input DAE.ClockKind baseClkIn;
  input BackendDAE.SubClock inSubClock;
  output DAE.ClockKind baseClkOut;
  output BackendDAE.SubClock outSubClock;
algorithm
  (baseClkOut, outSubClock) := match(baseClkIn, inSubClock)
  local
    String solver;
    DAE.ClockKind clk;
    case(DAE.SOLVER_CLOCK(c = DAE.CLKCONST(clk=clk), solverMethod=DAE.SCONST(solver)), _)
      algorithm
        outSubClock := setSubClockSolver(inSubClock, SOME(solver));
      then (clk, outSubClock);
      else
        then (baseClkIn, inSubClock);
  end match;
end setSolverSubClock;

protected function findSubClocks
"gets the sub clocks for each partition by coloring the partition adjacency starting by the real and bool clocks.
author: vwaurich 2017-06"
  input Integer numPartitions;
  input Integer baseClockEq;
  input DAE.ClockKind baseClk;
  input list<Integer> baseClockConstructors;
  input list<Integer> subPartitionInterfaceEqs;
  input array<Integer> eqPartMap;
  input array<Integer> varPartMap;
  input BackendDAE.EquationArray eqs;
  input array<list<tuple<Integer,BackendDAE.SubClock>>> partAdjacency;//idx: partition, entries: connections to other partitions with subclocks
  output DAE.ClockKind baseClkOut;
  output array<BackendDAE.SubClock> outSubClocks;
protected
  Integer part1,part2,ord;
  list<Integer> partLst;
  BackendDAE.SubClock subClk1,subClk2;
  DAE.ClockKind clk;
  array<Boolean> partIsAssigned;
  list<tuple<Integer,BackendDAE.SubClock>> adjParts;
algorithm
  outSubClocks := arrayCreate(numPartitions,BackendDAE.DEFAULT_SUBCLOCK);
  partIsAssigned := arrayCreate(numPartitions, false); //mark which partition is assigned

  //if there are multiple clock constructors in the sub partition, refer them to the base clock, ignore infered clocks
  for clockEq in baseClockConstructors loop
    if not intEq(baseClockEq, clockEq) and not intEq(baseClockEq,-1) then
      part1 := arrayGet(eqPartMap,clockEq);
      clk := getBaseClock(BackendEquation.get(eqs,clockEq));
      if not isInferedBaseClock(clk) then
        subClk1 := getSubClockForClkConstructor(baseClk, clk);
        arrayUpdate(outSubClocks, part1, subClk1);
        arrayUpdate(partIsAssigned, part1, true);
      end if;
    end if;
  end for;

  //assign subclock partitions
  if isInferedBaseClock(baseClk) then
    baseClkOut := baseClk;
    partLst := List.intRange(numPartitions); //traverse all partitions, start with base clock partition
  else
    part1 := arrayGet(eqPartMap,baseClockEq);
    partLst := part1::List.intRange(numPartitions); //traverse all partitions, start with base clock partition
    //if the baseClk is a solver clock, set the corresponding subClock solver
    (baseClkOut, subClk1) := setSolverSubClock(baseClk, outSubClocks[part1]);
    arrayUpdate(outSubClocks, part1, subClk1); //set the solver clock
    arrayUpdate(partIsAssigned, part1, true);
  end if;

  while not listEmpty(partLst) loop
    part1::partLst := partLst;
    adjParts := arrayGet(partAdjacency, part1);
    //check adjacent partitions
    for adjPart in adjParts loop
      part2 := Util.tuple21(adjPart);
      if not arrayGet(partIsAssigned, part2) then
        subClk1 := arrayGet(outSubClocks, part1);
        subClk2 := Util.tuple22(adjPart);
        subClk2 := computeAbsoluteSubClock(subClk1,subClk2);
        if not isInferedSubClock(subClk2) then
          arrayUpdate(outSubClocks, part2, subClk2);
          arrayUpdate(partIsAssigned, part2, true);
          partLst := part2::partLst;
        end if;
      end if;
    end for;
  end while;
end findSubClocks;

protected function computeAbsoluteSubClock
"merges 2 subsequent sub clocks.
author: vwaurich 2017-06"
  input BackendDAE.SubClock preClock;//the known subpartition clock
  input BackendDAE.SubClock subSeqClock; //the sub partitin clock which shall be determined
  output BackendDAE.SubClock subClk = BackendDAE.DEFAULT_SUBCLOCK;
algorithm
  subClk := match(preClock, subSeqClock)
    local
      MMath.Rational f1,f2;
      MMath.Rational s1,s2;
      Option<String> solver1,solver2;
    case(BackendDAE.SUBCLOCK(f1,s1,solver1),BackendDAE.SUBCLOCK(f2,s2,solver2))
      algorithm
        solver1 := mergeSolver(solver1,solver2);
      then BackendDAE.SUBCLOCK(MMath.divRational(f1, f2), MMath.addRational(s1, s2), solver1);
    case(BackendDAE.SUBCLOCK(f1,s1,solver1),BackendDAE.INFERED_SUBCLOCK())
      then subSeqClock;
    else
      algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {"SynchrnonousFeatures.computeAbsoluteSubClock failed\n"});
      then fail();
  end match;
end computeAbsoluteSubClock;

protected function mergeSolver
"merges the solver methods of 2 sub clocks.
author: vwaurich 2017-06"
  input Option<String> solver1;
  input Option<String> solver2;
  output Option<String> sOut;
algorithm
  sOut := match(solver1,solver2)
  local
    String s1,s2;
  case(NONE(),SOME(s2))
    then SOME(s2);
  case(SOME(s1),NONE())
    then SOME(s1);
  case(SOME(s1),SOME(s2))
    algorithm
      if not stringEq(s1,s2) then Error.addCompilerNotification("Infered sub clock partitions have different solvers:"+s1+" <->"+s2+".\n"); end if;
    then SOME(s1);
  else
    then NONE();
  end match;
end mergeSolver;

protected function addPartAdjacencyEdge
"add an edge between 2 partitions in the partition adjacency matrix.
author: vwaurich 2017-06"
  input Integer part1;
  input BackendDAE.SubClock sub1;
  input Integer part2;
  input BackendDAE.SubClock sub2;
  input array<list<tuple<Integer,BackendDAE.SubClock>>> partAdjacency;
protected
  list<tuple<Integer,BackendDAE.SubClock>> partEdges;
algorithm
  if intGt(part1,0) and intGt(part2,0) then
    //from first partition to secod partition
    partEdges := arrayGet(partAdjacency,part1);
    for edge in partEdges loop
      //there is already a connection to this partition
      if intEq(Util.tuple21(edge),part2) then
        //if not subClkEqual(Util.tuple22(edge),sub2) then Error.addCompilerNotification("Multiple subclock-interfaces between sub clock partitions.\n");end if;
      end if;
    end for;
    arrayUpdate(partAdjacency,part1,(part2,sub1)::partEdges);
    //from second partition to first partition
    partEdges := arrayGet(partAdjacency,part2);
    arrayUpdate(partAdjacency,part2,(part1,sub2)::partEdges);
  end if;
end addPartAdjacencyEdge;

protected function setSubClockFactor
"sets the factor of a sub clock
author: vwaurich 2017-06"
  input BackendDAE.SubClock subClk;
  input MMath.Rational factor;
  output BackendDAE.SubClock subClkOut;
algorithm
  subClkOut := match(subClk)
  local
    MMath.Rational shift;
    Option<String> solver;
    case(BackendDAE.SUBCLOCK(_,shift,solver))
      then BackendDAE.SUBCLOCK(factor,shift,solver);
    else
      then subClk;
  end match;
end setSubClockFactor;

protected function getSubClockFactor
"gets the factor of a sub clock
author: vwaurich 2017-06"
  input BackendDAE.SubClock subClk;
  output MMath.Rational factor;
algorithm
  factor := match(subClk)
  local
    MMath.Rational shift;
    Option<String> solver;
    case(BackendDAE.SUBCLOCK(factor,shift,solver))
      then factor;
    else
      then MMath.RAT1;
  end match;
end getSubClockFactor;

protected function getSubClockShift
"gets the shift value of a sub clock
author: vwaurich 2017-06"
  input BackendDAE.SubClock subClk;
  output MMath.Rational shift;
algorithm
  shift := match(subClk)
  local
    MMath.Rational factor;
    Option<String> solver;
    case(BackendDAE.SUBCLOCK(factor,shift,solver))
      then shift;
    else
      then MMath.RAT1;
  end match;
end getSubClockShift;

protected function getSubClockSolverOpt
"gets the solver method option of a sub clock
author: vwaurich 2017-06"
  input BackendDAE.SubClock subClk;
  output Option<String> solver;
algorithm
  solver := match(subClk)
  local
    MMath.Rational factor,shift;
    case(BackendDAE.SUBCLOCK(factor,shift,solver))
      then solver;
    else
      then NONE();
  end match;
end getSubClockSolverOpt;

protected function setSubClockShift
"sets the shift value of a sub clock
author: vwaurich 2017-06"
  input BackendDAE.SubClock subClk;
  input MMath.Rational shift;
  output BackendDAE.SubClock subClkOut;
algorithm
  subClkOut := match(subClk)
  local
    MMath.Rational factor;
    Option<String> solver;
    case(BackendDAE.SUBCLOCK(factor,_,solver))
      then BackendDAE.SUBCLOCK(factor,shift,solver);
    else
      then subClk;
  end match;
end setSubClockShift;

protected function setSubClockSolver
"sets the solver method option of a sub clock
author: vwaurich 2017-06"
  input BackendDAE.SubClock subClk;
  input Option<String> solver;
  output BackendDAE.SubClock subClkOut;
algorithm
  subClkOut := match(subClk)
  local
    MMath.Rational factor,shift;
    case(BackendDAE.SUBCLOCK(factor,shift,_))
      then BackendDAE.SUBCLOCK(factor,shift,solver);
    else
      then subClk;
  end match;
end setSubClockSolver;

protected function getConnectedSubPartitions
"get the connected partitions and the transformating sub clock for a sub partition interface equation.
used to build the sub clock partition adjacency
author: vwaurich 2017-06"
  input BackendDAE.Equation eq;
  input array<Integer> varPartMap;
  input BackendDAE.Variables vars;
  output Boolean infered = false;
  output Integer part1;
  output Integer var1=-1;
  output BackendDAE.SubClock sub1;
  output Integer part2;
  output Integer var2=-1;
  output BackendDAE.SubClock sub2;
algorithm
  sub1 := BackendDAE.DEFAULT_SUBCLOCK;
  sub2 := BackendDAE.DEFAULT_SUBCLOCK;
  (part1, var1, part2, var2) := match(eq)
    local
      Integer v1,v2,p1,p2;
      Integer factor,counter,resolution;
      String solver;
      DAE.ComponentRef cref1,cref2;
  case(BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cref1), scalar=DAE.CALL(path=Absyn.IDENT("superSample"),expLst={DAE.CREF(componentRef=cref2),DAE.ICONST(factor)})))
    algorithm
      infered := intEq(factor,0);//the sub clock has to be infered
      (_,{v1}) := BackendVariable.getVar(cref1,vars);
      p1 := varPartMap[v1];
      (_,{v2}) := BackendVariable.getVar(cref2,vars);
      p2 := varPartMap[v2];
      if infered then
        sub1 := BackendDAE.INFERED_SUBCLOCK();
        sub2 := BackendDAE.INFERED_SUBCLOCK();
      else
        sub1 := setSubClockFactor(sub1, MMath.divRational(MMath.RAT1, MMath.RATIONAL(factor,1)));
        sub2 := setSubClockFactor(sub2,MMath.RATIONAL(factor,1));
      end if;
    then (p1,v1,p2,v2);
  case(BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cref1), scalar=DAE.CALL(path=Absyn.IDENT("subSample"),expLst={DAE.CREF(componentRef=cref2),DAE.ICONST(factor)})))
    algorithm
      infered := intEq(factor,0);//the sub clock has to be infered
      (_,{v1}) := BackendVariable.getVar(cref1,vars);
      p1 := varPartMap[v1];
      (_,{v2}) := BackendVariable.getVar(cref2,vars);
      p2 := varPartMap[v2];
      if infered then
        sub1 := BackendDAE.INFERED_SUBCLOCK();
        sub2 := BackendDAE.INFERED_SUBCLOCK();
      else
        sub1 := setSubClockFactor(sub1, MMath.RATIONAL(factor,1));
        sub2 := setSubClockFactor(sub2, MMath.divRational(MMath.RAT1, MMath.RATIONAL(factor,1)));
      end if;
    then (p1,v1,p2,v2);
  case(BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cref1), scalar=DAE.CALL(path=Absyn.IDENT("shiftSample"),expLst={DAE.CREF(componentRef=cref2),DAE.ICONST(counter),DAE.ICONST(resolution)})))
    algorithm
      (_,{v1}) := BackendVariable.getVar(cref1,vars);
      p1 := varPartMap[v1];
      (_,{v2}) := BackendVariable.getVar(cref2,vars);
      p2 := varPartMap[v2];
      sub1 := setSubClockShift(sub1, MMath.subRational(MMath.RAT0, MMath.RATIONAL(counter, resolution)));
      sub2 := setSubClockShift(sub2,MMath.RATIONAL(counter,resolution));
    then (p1,v1,p2,v2);
  case(BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cref1), scalar=DAE.CALL(path=Absyn.IDENT("backSample"),expLst={DAE.CREF(componentRef=cref2),DAE.ICONST(counter),DAE.ICONST(resolution)})))
    algorithm
      (_,{v1}) := BackendVariable.getVar(cref1,vars);
      p1 := varPartMap[v1];
      (_,{v2}) := BackendVariable.getVar(cref2,vars);
      p2 := varPartMap[v2];
      sub1 := setSubClockShift(sub1, MMath.RATIONAL(counter,resolution));
      sub2 := setSubClockShift(sub2, MMath.subRational(MMath.RAT0, MMath.RATIONAL(counter, resolution)));
    then (p1,v1,p2,v2);
  case(BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cref1), scalar=DAE.CLKCONST(clk= DAE.SOLVER_CLOCK(c=DAE.CREF(componentRef=cref2), solverMethod= DAE.SCONST(solver)))))
    algorithm
      (_,{v1}) := BackendVariable.getVar(cref1,vars);
      p1 := varPartMap[v1];
      (_,{v2}) := BackendVariable.getVar(cref2,vars);
      p2 := varPartMap[v2];
      sub1 := setSubClockSolver(sub1, SOME(solver));
      sub2 := setSubClockSolver(sub2, SOME(solver));
    then (p1,v1,p2,v2);

  else
    then (-1,-1,-1,-1);
  end match;
end getConnectedSubPartitions;

protected function chooseBaseClock
"among all clock constructors, choose one as a base clock. No particular strategy applied.
author: vwaurich 2017-06"
  input list<Integer> clockEqs;
  input Integer numPartitions;
  input array<Integer> eqPartMap;
  input BackendDAE.EquationArray eqs;
  output DAE.ClockKind outBaseClock = DAE.INFERRED_CLOCK();
  output Integer baseClockEqIdx = -1;
protected
  array<BackendDAE.SubClock> subClkPartMap;
  BackendDAE.Equation eq;
algorithm
  //find baseClock, take the last, if there are several
  subClkPartMap := arrayCreate(numPartitions, BackendDAE.DEFAULT_SUBCLOCK);
  for clockEq in clockEqs loop
    eq := BackendEquation.get(eqs,clockEq);
    if isBaseClockEq(eq) then
      outBaseClock := getBaseClock(eq);
      baseClockEqIdx := clockEq;
    end if;
  end for;
end chooseBaseClock;

protected function isBaseClockEq
  input BackendDAE.Equation eq;
  output Boolean isBaseClock;
algorithm
  isBaseClock := match(eq)
    local
      DAE.ClockKind clk;
  case(BackendDAE.EQUATION(exp=DAE.CREF(),scalar=DAE.CLKCONST(clk=DAE.INFERRED_CLOCK())))
    algorithm
      then false;
  case(BackendDAE.EQUATION(exp=DAE.CREF(),scalar=DAE.CLKCONST(clk=clk)))
    algorithm
      then true;
  else
   then false;
  end match;
end isBaseClockEq;

protected function getBaseClock
  input BackendDAE.Equation eq;
  output DAE.ClockKind baseClk;
algorithm
  baseClk := match(eq)
    local
      DAE.ClockKind clk;
  case(BackendDAE.EQUATION(exp=DAE.CREF(),scalar=DAE.CLKCONST(clk=DAE.INFERRED_CLOCK())))
    algorithm
      then DAE.INFERRED_CLOCK();
  case(BackendDAE.EQUATION(exp=DAE.CREF(),scalar=DAE.CLKCONST(clk=clk)))
    algorithm
      then clk;
  else
    algorithm
   then DAE.INFERRED_CLOCK();
  end match;
end getBaseClock;

protected function removeEdge
"removes edges in incidence matrices betwenn equation and variable
author: vwaurich 2017-06"
  input Integer eq;
  input Integer var;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
protected
  list<Integer> row;
algorithm
  row := arrayGet(m,eq);
  row := List.deleteMember(row,var);
  arrayUpdate(m,eq,row);
  row := arrayGet(mT,var);
  row := List.deleteMember(row,eq);
  arrayUpdate(mT,var,row);
end removeEdge;

protected function findBaseClockInterfaces
"gets all equations which define a base clock and all equations which separate sub partitions.
author: vwaurich 2017-06"
  input BackendDAE.EquationArray eqs;
  input BackendDAE.Variables vars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  output list<Integer> clockEqs={};
  output list<Integer> subClockInterfaceEqIdxs={};
  output list<BackendDAE.Equation> subClockInterfaceEqs = {};
protected
  Integer eqIdx;
  BackendDAE.Equation eq;
algorithm
  for eqIdx in 1:BackendEquation.getNumberOfEquations(eqs) loop
    eq := BackendEquation.get(eqs,eqIdx);
    (clockEqs, subClockInterfaceEqIdxs, subClockInterfaceEqs) := findBaseClockInterfaces1(eq, eqIdx, eqs, vars, m, mT, clockEqs, subClockInterfaceEqIdxs, subClockInterfaceEqs);
  end for;
end findBaseClockInterfaces;

protected function findBaseClockInterfaces1
"adds the equation to the lost of base clock defining eqs or to the equations which separate sub partitions
author: vwaurich 2017-06"
  input BackendDAE.Equation eq;
  input Integer eqIdx;
  input BackendDAE.EquationArray eqs;
  input BackendDAE.Variables vars;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input list<Integer> clockEqsIn;
  input list<Integer> subClockInterfaceEqIdxsIn;
  input list<BackendDAE.Equation> subClockInterfaceEqsIn;
  output list<Integer> clockEqsOut;
  output list<Integer> subClockInterfaceEqIdxsOut;
  output list<BackendDAE.Equation> subClockInterfaceEqsOut;
algorithm
  (clockEqsOut, subClockInterfaceEqIdxsOut, subClockInterfaceEqsOut) := match(eq)
  local
    DAE.ComponentRef cref1;
    DAE.Exp exp,e1,e2;
    Integer varIdx;
    list<DAE.Exp> expLst;
   case(BackendDAE.EQUATION(scalar=DAE.CLKCONST(clk=DAE.INFERRED_CLOCK())))
      algorithm
      then (eqIdx::clockEqsIn, subClockInterfaceEqIdxsIn, subClockInterfaceEqsIn);

   case(BackendDAE.EQUATION(scalar=DAE.CLKCONST(clk=DAE.INTEGER_CLOCK(_))))
      algorithm
      then (eqIdx::clockEqsIn, subClockInterfaceEqIdxsIn,subClockInterfaceEqsIn);

   case(BackendDAE.EQUATION(scalar=DAE.CLKCONST(clk=DAE.REAL_CLOCK(_))))
      algorithm
      then (eqIdx::clockEqsIn, subClockInterfaceEqIdxsIn,subClockInterfaceEqsIn);

   case(BackendDAE.EQUATION(scalar=DAE.CLKCONST(clk=DAE.BOOLEAN_CLOCK(_))))
      algorithm
      then (eqIdx::clockEqsIn, subClockInterfaceEqIdxsIn,subClockInterfaceEqsIn);

   //solver clocks can act as subpartitioninterfaces since they assign a solver to another clock
   case(BackendDAE.EQUATION(scalar=DAE.CLKCONST(clk=DAE.SOLVER_CLOCK(DAE.CREF(_),_))))
      algorithm
      then (clockEqsIn, eqIdx::subClockInterfaceEqIdxsIn, eq::subClockInterfaceEqsIn);

   case(BackendDAE.EQUATION(scalar=DAE.CLKCONST(clk=DAE.SOLVER_CLOCK(DAE.CLKCONST(_),_))))
      algorithm
      then (eqIdx::clockEqsIn, subClockInterfaceEqIdxsIn,subClockInterfaceEqsIn);

    case(BackendDAE.EQUATION(scalar=DAE.CALL(path=Absyn.IDENT("superSample"), expLst={DAE.CREF(componentRef=cref1),_})))
      algorithm
        (_,{varIdx}) := BackendVariable.getVar(cref1,vars);
        removeEdge(eqIdx,varIdx,m,mT);
      then (clockEqsIn, eqIdx::subClockInterfaceEqIdxsIn, eq::subClockInterfaceEqsIn);

    case(BackendDAE.EQUATION(scalar=DAE.CALL(path=Absyn.IDENT("subSample"), expLst={DAE.CREF(componentRef=cref1),_})))
      algorithm
        (_,{varIdx}) := BackendVariable.getVar(cref1,vars);
        removeEdge(eqIdx,varIdx,m,mT);
      then (clockEqsIn, eqIdx::subClockInterfaceEqIdxsIn, eq::subClockInterfaceEqsIn);

    //shiftSample with 3 arguments
    case(BackendDAE.EQUATION(scalar=DAE.CALL(path=Absyn.IDENT("shiftSample"), expLst={DAE.CREF(componentRef=cref1),_,_})))
      algorithm
        (_,{varIdx}) := BackendVariable.getVar(cref1,vars);
        removeEdge(eqIdx,varIdx,m,mT);
      then (clockEqsIn, eqIdx::subClockInterfaceEqIdxsIn, eq::subClockInterfaceEqsIn);

    //shiftSample with 2 arguments
    case(BackendDAE.EQUATION(scalar=DAE.CALL(path=Absyn.IDENT("shiftSample"), expLst={DAE.CREF(componentRef=cref1),_})))
      algorithm
        (_,{varIdx}) := BackendVariable.getVar(cref1,vars);
        removeEdge(eqIdx,varIdx,m,mT);
      then (clockEqsIn, eqIdx::subClockInterfaceEqIdxsIn, eq::subClockInterfaceEqsIn);

    //Backsample with 3 arguments
    case(BackendDAE.EQUATION(scalar=DAE.CALL(path=Absyn.IDENT("backSample"), expLst={DAE.CREF(componentRef=cref1),_,_})))
      algorithm
        (_,{varIdx}) := BackendVariable.getVar(cref1,vars);
        removeEdge(eqIdx,varIdx,m,mT);
      then (clockEqsIn, eqIdx::subClockInterfaceEqIdxsIn, eq::subClockInterfaceEqsIn);

    //Backsample with 2 arguments
    case(BackendDAE.EQUATION(scalar=DAE.CALL(path=Absyn.IDENT("backSample"), expLst={DAE.CREF(componentRef=cref1),_})))
      algorithm
        (_,{varIdx}) := BackendVariable.getVar(cref1,vars);
        removeEdge(eqIdx,varIdx,m,mT);
      then (clockEqsIn, eqIdx::subClockInterfaceEqIdxsIn, eq::subClockInterfaceEqsIn);

    case(BackendDAE.EQUATION(scalar=e1, exp=e2))
      algorithm
        //print("Thats also not a base clock "+BackendDump.equationString(eq)+"\n");
      then (clockEqsIn, subClockInterfaceEqIdxsIn, subClockInterfaceEqsIn);
    else
      equation
      then (clockEqsIn, subClockInterfaceEqIdxsIn, subClockInterfaceEqsIn);
  end match;
end findBaseClockInterfaces1;

protected function findHighestWhenPrefixIdx
"since new $whenClk vars are introduced, determine the highest index to avopid duplicates.
author: vwaurich 2017-06"
  input BackendDAE.Var inVar;
  input Integer idxIn;
  output BackendDAE.Var outVar = inVar;
  output Integer idxOut = idxIn;
protected
  DAE.ComponentRef name;
  list<String> chars, chars1, chars2;
algorithm
  name := inVar.varName;
  chars := stringListStringChar(ComponentReference.crefStr(name));
  if intGt(listLength(chars),9) then
    (chars1,chars2) := List.split(chars,8);
    if stringEq(stringDelimitList(chars1,""), BackendDAE.WHENCLK_PRREFIX) then
      idxOut := intMax(idxIn, stringInt(stringDelimitList(chars2,"")));
    end if;
  end if;
end findHighestWhenPrefixIdx;

protected function replaceSampledClocks
"Clock contructors inside samples are added as an additional equation in order to separate clocks and dynamic equations if they are still marked as BackendDAE.DYNAMIC_EQUATION.
author: vwaurich 2017-06"
  input BackendDAE.EquationArray eqsIn;
  input BackendDAE.Variables varsIn;
  output BackendDAE.EquationArray eqsOut;
  output BackendDAE.Variables varsOut;
protected
  Integer prefIdx;
  BackendDAE.EquationArray eqs;
  list<BackendDAE.Equation> newEqs;
  list<BackendDAE.Var> newVars;
algorithm
  //get the max $whenclk-Variable in the system in order to use a higher index
  prefIdx := BackendVariable.traverseBackendDAEVars(varsIn,findHighestWhenPrefixIdx,1);
  (eqs,(_, _,newEqs, newVars)) := BackendEquation.traverseEquationArray_WithUpdate(eqsIn, replaceSampledClocks1, (varsIn,prefIdx+1,{},{}));
  eqsOut := BackendEquation.addList(newEqs, eqs);
  varsOut := BackendVariable.addVars(newVars, varsIn);
end replaceSampledClocks;

protected function replaceSampledClocks1
"author: vwaurich 2017-06"
  input BackendDAE.Equation eqIn;
  input tuple<BackendDAE.Variables, Integer, list<BackendDAE.Equation>, list<BackendDAE.Var>> tplIn;
  output BackendDAE.Equation eqOut;
  output tuple<BackendDAE.Variables, Integer,  list<BackendDAE.Equation>, list<BackendDAE.Var>> tplOut;
algorithm
  (eqOut, tplOut) := match(eqIn,tplIn)
    local
      Integer suffixIdx,suffixIdx0;
      BackendDAE.Equation eqNew;
      BackendDAE.EquationAttributes attr;
      BackendDAE.Variables vars;
      DAE.Exp e1,e2;
      DAE.ElementSource source;
      list<BackendDAE.Equation> newEqs;
      list<BackendDAE.Var> newVars;
    case(BackendDAE.EQUATION(e1, e2, source, attr=BackendDAE.EQUATION_ATTRIBUTES(kind=BackendDAE.DYNAMIC_EQUATION())),(vars, suffixIdx0, newEqs, newVars))
      algorithm
        (e1,(newEqs, newVars, suffixIdx)) := Expression.traverseExpTopDown(e1, replaceSampledClocks2, (newEqs, newVars, suffixIdx0));
        (e2,(newEqs, newVars, suffixIdx)) := Expression.traverseExpTopDown(e2, replaceSampledClocks2, (newEqs, newVars, suffixIdx));
        if intEq(suffixIdx-suffixIdx0, 1) then
          attr := BackendDAE.EQUATION_ATTRIBUTES(false, BackendDAE.CLOCKED_EQUATION(suffixIdx0));
        else
          attr := BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC;
        end if;
      then (BackendDAE.EQUATION(e1,e2,source,attr),(vars, suffixIdx, newEqs, newVars));
    else
      algorithm
      then (eqIn,tplIn);
  end match;
end replaceSampledClocks1;

protected function replaceSampledClocks2
"author: vwaurich 2017-06"
  input DAE.Exp inExp;
  input tuple<list<BackendDAE.Equation>, list<BackendDAE.Var>, Integer> tplIn;//<addEq, addVar, suffixIdx>
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<list<BackendDAE.Equation>, list<BackendDAE.Var>, Integer> tplOut;//<addEq, addVar, suffixIdx>
algorithm
  (outExp,cont, tplOut) := match(inExp,tplIn)
    local
      Integer suffixIdx;
      DAE.ComponentRef cr;
      DAE.Exp varExp, clk, exp;
      BackendDAE.Equation addEq;
      BackendDAE.Var addVar;
      list<BackendDAE.Equation> newEqs;
      list<BackendDAE.Var> newVars;
  case(DAE.CALL(path=Absyn.IDENT("sample"), expLst={varExp as DAE.CREF(_), clk as DAE.CLKCONST(_)}),(newEqs,newVars,suffixIdx))
    algorithm
      cr := DAE.CREF_IDENT(BackendDAE.WHENCLK_PRREFIX + intString(suffixIdx), DAE.T_CLOCK_DEFAULT, {});
      addVar := BackendVariable.makeVar(cr);
      addVar.varType := DAE.T_CLOCK_DEFAULT;
      addEq := BackendDAE.EQUATION(Expression.crefToExp(cr), clk, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
  then(substGetPartition(varExp), false, (addEq::newEqs, addVar::newVars, suffixIdx+1));
  else
    then  (inExp, true, tplIn);
  end match;
end replaceSampledClocks2;

protected function subClockPartitioning
"Does sub-partitioning for base partition and get base clock
 and vars, equations and sub-clocks of subpartitions.
 author: vwaurich 2017-06"
  input BackendDAE.EqSystem inEqSystem;
  input BackendDAE.Shared inShared;
  input Integer off;
  output list<BackendDAE.EqSystem> outSysts;
  output DAE.ClockKind outBaseClock;
  output list<BackendDAE.SubClock> outSubClocks;
protected
  DAE.FunctionTree funcs;
  BackendDAE.EquationArray eqs, remEqs, clockEqs;
  BackendDAE.Variables vars, clockVars;
  BackendDAE.EqSystem clockSyst,outSys;
  BackendDAE.IncidenceMatrix m, mT, rm, rmT;
  MMath.Rational subClkFactor;
  Integer partitionsCnt;
  array<Integer> partitions, remEqPartMap;
  list<BackendDAE.Equation> newClockEqs;
  array<BackendDAE.EqSystem> outSysts_noOrder;
  list<BackendDAE.Var> newClockVars;
  array<Option<Boolean>> contPartitions;
  array<tuple<BackendDAE.SubClock, Integer>> subclocksTree;
  BackendDAE.StrongComponents clockComps, comps;
  array<Integer> subclksCnt;
  array<Integer> order;
  array<BackendDAE.SubClock> subclocks, subclocksOutArr;
  array<Boolean> clockedEqsMask, clockedVarsMask, usedVars, usedRemovedVars;

  Integer baseClockEqIdx,eqIdx,varIdx;
  list<Integer> baseClockEquations, subClockInterfaceEqIdxs;
  list<BackendDAE.Equation> subClockInterfaceEqs;
  array<Integer> varPartMap, eqPartMap;
  array<list<tuple<Integer,BackendDAE.SubClock>>> partAdjacency;//idx: partition, entries: connections to other partitions with subclocks
  BackendDAE.EqSystem sys;
  list<tuple<Boolean,String>> varAtts,eqAtts;
algorithm
  funcs := BackendDAEUtil.getFunctions(inShared);
  BackendDAE.EQSYSTEM(orderedVars = vars, orderedEqs = eqs, removedEqs = remEqs) := inEqSystem;

  //separate clock-constructors from dynamic equations, e.g. x = sample(time, Clock(0.1))  -> x=time [clocked(whenclk1)]; whenclk1=Clock(0.1);
  (eqs,vars) := replaceSampledClocks(eqs,vars);
  sys := BackendDAEUtil.setEqSystVars(inEqSystem, vars);
  sys := BackendDAEUtil.setEqSystEqs(sys, eqs);

  //get incidence matrix
  (sys, m, mT) := BackendDAEUtil.getIncidenceMatrix(sys, BackendDAE.SUBCLOCK_IDX(), SOME(funcs));

  //find baseclocks and sub partition interfaces, remove edges in incidence matrices for sub partition interfaces
  (baseClockEquations, subClockInterfaceEqIdxs, subClockInterfaceEqs) := findBaseClockInterfaces(eqs,vars,m,mT);
    //print("all baseClockEquations "+stringDelimitList(List.map(baseClockEquations,intString),", ")+"\n");
    //print("all subClockInterfaceEqIdxs "+stringDelimitList(List.map(subClockInterfaceEqIdxs,intString),", ")+"\n");
    //BackendDump.dumpBipartiteGraphEqSystem(sys, inShared, "Synchronous_"+intString(off));

  //old implementation, used for partitioning
  (clockEqs, clockedEqsMask) := splitClockEqs(eqs); //masks false  if clock equation
  (clockVars, clockedVarsMask)  := splitClockVars(vars);
  (rm, rmT) := BackendDAEUtil.removedIncidenceMatrix(sys, BackendDAE.SUBCLOCK_IDX(), SOME(funcs));

  //partitioning of equations and variables
  remEqPartMap := arrayCreate(arrayLength(rm), 0);
  eqPartMap := arrayCreate(arrayLength(m), 0);
  varPartMap := arrayCreate(arrayLength(mT), 0);
  usedRemovedVars := arrayCreate(arrayLength(rmT), false);
  usedVars := arrayCreate(arrayLength(mT), false);
  partitionsCnt := partitionIndependentBlocksMasked(m, mT, rm, rmT, arrayCreate(BackendEquation.getNumberOfEquations(eqs), true), eqPartMap, varPartMap,  remEqPartMap, usedVars, usedRemovedVars);
    /*
    print("eqPartMap "+stringDelimitList(List.map(arrayList(eqPartMap),intString)," | ")+"\n");
    print("varPartMap "+stringDelimitList(List.map(arrayList(varPartMap),intString)," | ")+"\n");
    print("partitionsCnt :"+intString(partitionsCnt)+"\n");
    varAtts := {};
    eqAtts := {};
    for i in 1:arrayLength(eqPartMap) loop
      print("eq "+intString(i)+" is partition "+intString(arrayGet(eqPartMap,i))+"\n");
      eqAtts := (false, "p"+intString(arrayGet(eqPartMap,i)))::eqAtts;
    end for;
    for i in 1:arrayLength(varPartMap) loop
      print("var "+intString(i)+" is partition "+intString(arrayGet(varPartMap,i))+"\n");
      varAtts := (false, "p"+intString(arrayGet(varPartMap,i)))::varAtts;
    end for;
    BackendDump.dumpBipartiteGraphStrongComponent2(vars,eqs,m,listReverse(varAtts),listReverse(eqAtts),"BipartiteGraph_SynchronousPart_"+intString(off));
    */

  //find the defining base clock
  (outBaseClock,baseClockEqIdx) := chooseBaseClock(baseClockEquations, partitionsCnt, eqPartMap, eqs);
    //print("base clock equation "+intString(baseClockEqIdx)+"  "+DAEDump.clockKindString(outBaseClock)+"\n");

  // and get adjacency matrix for subpartitions, remove the sample()-vars first since they are not handled as connections (necessary to get the right order)
  (partAdjacency,order) := getSubPartitionAdjacency(partitionsCnt, baseClockEqIdx, subClockInterfaceEqIdxs, eqPartMap, varPartMap, clockedVarsMask, eqs, vars);
    //print("order "+stringDelimitList(List.map(arrayList(order),intString)," | ")+"\n");

  //Detect clocked continuous partitions and create new subclock equations
  (m, mT) := BackendDAEUtil.incidenceMatrixMasked(inEqSystem, BackendDAE.SUBCLOCK_IDX(), clockedEqsMask, SOME(funcs));
  (newClockEqs, newClockVars, contPartitions, subclksCnt)
        := collectSubclkInfo(eqs, inEqSystem.removedEqs, partitionsCnt, eqPartMap, remEqPartMap, vars, mT);

  //propagate subclocks across the system, consider solver clocks
  (outBaseClock, subclocks) := findSubClocks(partitionsCnt, baseClockEqIdx, outBaseClock, baseClockEquations, subClockInterfaceEqIdxs, eqPartMap, varPartMap, eqs, partAdjacency);
    /*
    for i in 1:arrayLength(subclocks) loop
      print("partition "+intString(i)+" has subClock "+BackendDump.subClockString(arrayGet(subclocks,i))+"\n");
    end for;
    */

  //dont consider the clock-contructor calls as equations for the system
  for eqIdx in 1:arrayLength(clockedEqsMask) loop
    if not arrayGet(clockedEqsMask,eqIdx) then arrayUpdate(eqPartMap,eqIdx,0); end if;
  end for;
  for varIdx in 1:arrayLength(clockedVarsMask) loop
    if not arrayGet(clockedVarsMask,varIdx) then arrayUpdate(varPartMap,varIdx,0); end if;
  end for;

  //get the equations and variables for the subpartitions
  (outSysts, outSubClocks) := orderSubPartitions(partitionsCnt, subclocks, order, eqPartMap, varPartMap, remEqPartMap, eqs, vars, remEqs, inShared, off);
    //print("outSubClocks: \n"+stringDelimitList(List.map(outSubClocks,BackendDump.subClockString),"\n")+"\n");
    //BackendDump.dumpEqSystems(outSysts, "outSysts");
    //BackendDump.dumpBipartiteGraphEqSystem(listHead(outSysts), inShared, "SynchronousDone"+intString(off));
end subClockPartitioning;

protected function orderSubPartitions
"collects equations and vars for subpartitions, brings them in the execution order and merges subsequent partitions with the same sub clock.
author: vwaurich 2017-06"
  input Integer numParts;
  input array<BackendDAE.SubClock> subclocks;
  input array<Integer> order;
  input array<Integer> eqPartMap;
  input array<Integer> varPartMap;
  input array<Integer> remEqPartMap;
  input BackendDAE.EquationArray eqs;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray remEqs;
  input BackendDAE.Shared shared;
  input Integer partitionOffset;
  output list<BackendDAE.EqSystem> systs = {};
  output list<BackendDAE.SubClock> subClksOut = {};
protected
  Boolean contMerge, considerRemovedEqs;
  Integer part;
  list<Integer> mergedParts;
  array<list<Integer>> partVarMap,partEqMap,partRemEqMap;
  BackendDAE.EqSystem sys;
  BackendDAE.SubClock clk,clk2;
  list<BackendDAE.Equation> eqLst, remEqLst;
  list<BackendDAE.Var> varLst;
  list<list<Integer>> mergedOrder;
algorithm
  considerRemovedEqs := intGe(arrayLength(remEqPartMap),1);

  //build mapping between partition and variables
  partVarMap := arrayCreate(numParts, {});
  for varIdx in 1:arrayLength(varPartMap) loop
    part := arrayGet(varPartMap,varIdx);
    if part > 0 then
      arrayUpdate(partVarMap, part, listAppend(partVarMap[part], {varIdx}));//array append list at idx
    end if;
  end for;

  //build mapping between partitions and equations
  partEqMap := arrayCreate(numParts, {});
  for eqIdx in 1:arrayLength(eqPartMap) loop
    part := arrayGet(eqPartMap,eqIdx);
    if part > 0 then
      arrayUpdate(partEqMap, part, listAppend(partEqMap[part], {eqIdx}));//array append list at idx
    end if;
  end for;

  //build mapping between partitions and removed equations
  partRemEqMap := arrayCreate(numParts, {});
  if considerRemovedEqs then
    for reqIdx in 1:arrayLength(partRemEqMap) loop
      part := arrayGet(remEqPartMap,reqIdx);
      if part > 0 then
        arrayUpdate(partRemEqMap, part, listAppend(partRemEqMap[part], {reqIdx}));//array append list at idx
      end if;
    end for;
  end if;

  //merge partitions in subsequent order with same subclocks
  mergedOrder := {};
  mergedParts :={};
  clk := arrayGet(subclocks,order[1]);
  for part in arrayList(order) loop
    clk2 := arrayGet(subclocks,part);
    if subClkEqual(clk,clk2) then
      //these 2 partitions have the same subclock, put them in one partition
      mergedParts := part::mergedParts;
    else
      //this partition has a different subclock
      mergedOrder := listReverse(mergedParts)::mergedOrder;
      mergedParts := {part};
      clk := arrayGet(subclocks,part);
    end if;
  end for;
  mergedOrder := listReverse(mergedParts)::mergedOrder;
  mergedOrder := listReverse(mergedOrder);

  part := 1;
  //build equation systems for ordered sub partitions
  for mergedParts in mergedOrder loop
    eqLst := {};
    varLst := {};
    remEqLst := {};
    for partIdx in mergedParts loop
      for e in arrayGet(partEqMap, partIdx) loop
        eqLst := BackendEquation.get(eqs,e)::eqLst;
      end for;
      for v in arrayGet(partVarMap, partIdx) loop
        varLst := BackendVariable.getVarAt(vars,v)::varLst;
      end for;
      for r in arrayGet(partRemEqMap, partIdx) loop
        remEqLst := BackendEquation.get(remEqs,r)::remEqLst;
      end for;
      clk := arrayGet(subclocks,partIdx);
    end for;
    if not listEmpty(eqLst) or not listEmpty(remEqLst) then
      (sys, (_, _)) := createEqSystem(listReverse(eqLst), listReverse(varLst), remEqLst, (true, true));
      //sys := BackendDAEUtil.sortEqnsDAEWork(sys,shared);
      sys.partitionKind := BackendDAE.CLOCKED_PARTITION(partitionOffset+part);
      subClksOut := clk::subClksOut;
      systs := sys::systs;
      part := part+1;
    end if;
  end for;
  //reverse system order due to listappending
  systs := listReverse(systs);
  subClksOut := listReverse(subClksOut);
end orderSubPartitions;

protected function isInferedSubClock
  input BackendDAE.SubClock subClk;
  output Boolean isInfered;
algorithm
  isInfered := match(subClk)
  case(BackendDAE.INFERED_SUBCLOCK())
      then true;
  else
    false;
  end match;
end isInferedSubClock;

protected function isInferedBaseClock
  input DAE.ClockKind subClk;
  output Boolean isInfered;
algorithm
  isInfered := match(subClk)
  case(DAE.INFERRED_CLOCK())
      then true;
  else
    false;
  end match;
end isInferedBaseClock;

//unused function from old implementation
/*
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
  //Build subpartitions dependenct graph
  for i in 1:partitionsCnt loop
    for parent in parents[i] loop
      partIdx := partitions[parent];
      if partIdx <> 0 then
        arrayUpdate(children, partIdx, List.unionElt(i, children[partIdx]));
      end if;
    end for;
  end for;
  //Toposort with loop detection
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
*/

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
        (substGetPartition(listGet(inExpLst, 1)), inNewEqs, inNewVars, inClkCnt + 1);

    case (Absyn.IDENT("superSample"), 2)
      then
        (substGetPartition(listGet(inExpLst, 1)), inNewEqs, inNewVars, inClkCnt + 1);


    case (Absyn.IDENT("shiftSample"), 3)
      then
        (substGetPartition(listGet(inExpLst, 1)), inNewEqs, inNewVars, inClkCnt + 1);

    case (Absyn.IDENT("backSample"), 3)
      then
        (substGetPartition(listGet(inExpLst, 1)), inNewEqs, inNewVars, inClkCnt + 1);

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
  output list<BackendDAE.Equation> outNewEqs = inNewEqs;
  output list<BackendDAE.Var> outNewVars = inNewVars;
  output Integer outClkCnt = inClkCnt;
protected
  DAE.Exp e;
algorithm
  outExp := substGetPartition(List.first(inExpLst));
  //To do this, the eqPartMap has to exclude the subPartition interfaces. Anyway, its not used anymore
  /*
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
   */
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
  for i in 1:BackendEquation.getNumberOfEquations(eqs) loop
    eq := BackendEquation.get(eqs, i);
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
  outClockEqsMask := arrayCreate(BackendEquation.getNumberOfEquations(inEqs), true);
  for i in 1:BackendEquation.getNumberOfEquations(inEqs) loop
    eq := BackendEquation.get(inEqs, i);
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
  output BackendDAE.Var outVar;
algorithm
  outVar := BackendDAE.VAR (
                  varName = inComp, varKind = BackendDAE.VARIABLE(),
                  varDirection = DAE.BIDIR(), varParallelism = DAE.NON_PARALLEL(),
                  varType = inType, bindExp = NONE(), tplExp = NONE(),
                  arryDim = {}, source = DAE.emptyElementSource,
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
  array<Integer> eqPartMap, varPartMap, reqsPartition;
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
  eqPartMap := arrayCreate(arrayLength(m), 0);
  varPartMap := arrayCreate(arrayLength(mT), 0);

  reqsPartition := arrayCreate(arrayLength(rm), 0);
  varsPartition := arrayCreate(arrayLength(mT), false);
  rvarsPartition := arrayCreate(arrayLength(rmT), false);

  partitionCnt := partitionIndependentBlocks0(m, mT, rm, rmT, eqPartMap, varPartMap, reqsPartition, varsPartition, rvarsPartition);

  if partitionCnt > 1 then
    (systs, outUnpartRemEqs) := partitionIndependentBlocksSplitBlocks(partitionCnt, syst, eqPartMap, reqsPartition, mT, rmT, false);
  else
    (systs, outUnpartRemEqs) := ({syst}, {});
  end if;

  //Partitioning finished
  clockedEqs := arrayCreate(BackendEquation.getNumberOfEquations(eqs), NONE());
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
      info := BackendEquation.equationInfo(BackendEquation.get(eqs, j));
      arrayUpdate(clockedEqs, j, setClockedPartition(partitionType, arrayGet(clockedEqs, j), SOME(cr), info));
    end for;
  end for;
  //Detect clocked partitions (clocked equations should belong to clocked partitions)
  for i in 1:arrayLength(clockedEqs) loop
    partitionType := arrayGet(clockedEqs, i);
    info := BackendEquation.equationInfo(BackendEquation.get(eqs, i));
    j := arrayGet(eqPartMap, i);
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
    case (Absyn.IDENT("sample"), {e, _})
      then detectEqPartitionCall1(true, false, inPartition, e, inRefs, info);
    case (Absyn.IDENT("subSample"), {e, _})
      then detectEqPartitionCall1(true, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("superSample"), {e, _})
      then detectEqPartitionCall1(true, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("shiftSample"), {e, _, _})
      then detectEqPartitionCall1(true, true, inPartition, e, inRefs, info);
    case (Absyn.IDENT("backSample"), {e, _, _})
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
  input array<Integer> eqPartMap,varPartMap, rixs;
  input array<Boolean> vars, rvars;
  output Integer on = 0;
algorithm
  for i in arrayLength(m):-1:1 loop
    on := if partitionIndependentBlocksEq(i, on + 1, m, mT, rm, rmT, eqPartMap, varPartMap, rixs, vars, rvars) then on + 1 else on;
  end for;
  for i in arrayLength(rm):-1:1 loop
    on := if partitionIndependentBlocksReq(i, on + 1, m, mT, rm, rmT, eqPartMap, varPartMap, rixs, vars, rvars) then on + 1 else on;
  end for;
end partitionIndependentBlocks0;

protected function partitionIndependentBlocks
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> eqPartMap; //partitions
  input array<Integer> varPartMap; //usedVars, usedRemovedVars
  output Integer on = 0;
algorithm
  for eq in arrayLength(m):-1:1 loop
      print("check eq "+intString(eq)+"\n");
      if not intEq(arrayGet(eqPartMap,eq),-2) then //marked with -2 means that it is a sub partition interface
        on := if partitionIndependentBlocks2(eq, on+1, m, mT, eqPartMap, varPartMap) then on+1 else on;
      end if;
  end for;
end partitionIndependentBlocks;


protected function partitionIndependentBlocks2
  input Integer eqIdx;
  input Integer partIdx;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> eqPartMap;
  input array<Integer> varPartMap;
  output Boolean ochange;
algorithm
  ochange := arrayGet(eqPartMap, eqIdx) == -1;
  if ochange then
    arrayUpdate(eqPartMap, eqIdx, partIdx);
    for var in arrayGet(m, eqIdx) loop
      if not intGt(arrayGet(varPartMap, intAbs(var)),0) then
        arrayUpdate(varPartMap, intAbs(var), partIdx);
        for newEq in arrayGet(mT, intAbs(var)) loop
          partitionIndependentBlocks2(intAbs(newEq), partIdx, m, mT, eqPartMap, varPartMap);
        end for;
      end if;
    end for;
  end if;
end partitionIndependentBlocks2;

protected function partitionIndependentBlocksMasked
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input BackendDAE.IncidenceMatrix rm;
  input BackendDAE.IncidenceMatrixT rmT;
  input array<Boolean> mask; //clockedEqsMask
  input array<Integer> eqPartMap, varPartMap, remEqPartMap; //eqPartMap, varPartMap, remEqPartMap
  input array<Boolean> vars, rvars; //usedVars, usedRemovedVars
  output Integer on = 0;
algorithm
  for i in arrayLength(m):-1:1 loop
    if mask[i] then
      on := if partitionIndependentBlocksEq(i, on + 1, m, mT, rm, rmT, eqPartMap, varPartMap, remEqPartMap, vars, rvars) then on + 1 else on;
    end if;
  end for;
  for i in arrayLength(rm):-1:1 loop
    on := if partitionIndependentBlocksReq(i, on + 1, m, mT, rm, rmT, eqPartMap, varPartMap, remEqPartMap, vars, rvars) then on + 1 else on;
  end for;
  for i in 1:arrayLength(rm) loop
  end for;
end partitionIndependentBlocksMasked;

protected function partitionIndependentBlocksEq
  input Integer eqIdx;
  input Integer partIdx;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input BackendDAE.IncidenceMatrix rm;
  input BackendDAE.IncidenceMatrixT rmT;
  input array<Integer> eqPartMap, varPartMap, rixs;
  input array<Boolean> vars, rvars;
  output Boolean ochange;
algorithm
  ochange := arrayGet(eqPartMap, eqIdx) == 0;

  if ochange then
    arrayUpdate(eqPartMap, eqIdx, partIdx);
    for varIdx in arrayGet(m, eqIdx) loop
      if not arrayGet(vars, intAbs(varIdx)) then
        arrayUpdate(vars, intAbs(varIdx), true);
        arrayUpdate(varPartMap,intAbs(varIdx), partIdx);
        for nextEqIdx in arrayGet(mT, intAbs(varIdx)) loop
          partitionIndependentBlocksEq(intAbs(nextEqIdx), partIdx, m, mT, rm, rmT, eqPartMap,varPartMap, rixs, vars, rvars);
        end for;
        for nextEqIdx in arrayGet(rmT, intAbs(varIdx)) loop
          partitionIndependentBlocksReq(intAbs(nextEqIdx), partIdx, m, mT, rm, rmT, eqPartMap,varPartMap, rixs, vars, rvars);
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
  input array<Integer> eqPartMap, varPartMap, rixs;
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
          partitionIndependentBlocksEq(intAbs(j), n, m, mT, rm, rmT, eqPartMap, varPartMap, rixs, vars, rvars);
        end for;
        for j in arrayGet(rmT, intAbs(i)) loop
          partitionIndependentBlocksReq(intAbs(j), n, m, mT, rm, rmT, eqPartMap, varPartMap, rixs, vars, rvars);
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
  output array<Integer> varPartMap;
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
  varPartMap := arrayCreate(n, -1);
  i1 := BackendEquation.equationArraySize(inSyst.orderedEqs);
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
  i1 := BackendEquation.equationArraySize(arr);
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
  for i in BackendEquation.getNumberOfEquations(arr):-1:1 loop
    ix := ixs[i];
    eq := BackendEquation.get(arr, i);
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

protected function subClkEqual
"outputs true if 2 subclocks are equal
vwaurich 2017-06"
  input BackendDAE.SubClock sc1;
  input BackendDAE.SubClock sc2;
  output Boolean isEqual;
algorithm
  isEqual := match(sc1,sc2)
    local
  case(BackendDAE.INFERED_SUBCLOCK(), BackendDAE.INFERED_SUBCLOCK())
    then true;
  case(BackendDAE.SUBCLOCK(), BackendDAE.SUBCLOCK())
    then MMath.equals(sc1.factor,sc2.factor) and MMath.equals(sc1. shift,sc2. shift) and Util.optionEqual(sc1.solver,sc2.solver,stringEqual);
  else
    then false;
  end match;
end subClkEqual;

protected function subClockTreeString
  input array<tuple<BackendDAE.SubClock, Integer>> treeIn;
  output String sOut="";
protected
 tuple<BackendDAE.SubClock, Integer> tpl;
 BackendDAE.SubClock subClock;
 Integer i,idx=1;
algorithm
  for tpl in treeIn loop
    (subClock,i) := tpl;
    sOut := intString(idx)+": ["+intString(i)+"]:  "+BackendDump.subClockString(subClock)+"\n"+sOut;
    idx:=idx+1;
  end for;
end subClockTreeString;

annotation(__OpenModelica_Interface="backend");
end SynchronousFeatures;
