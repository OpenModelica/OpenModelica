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
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import Util;

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

    case (BackendDAE.DAE({syst}, shared)) equation
      systs = clockPartitioning1(syst, shared);
    then BackendDAE.DAE(systs, shared);

    // TODO: Improve support for partitioned systems of equations
    else equation
      BackendDAE.DAE({syst}, shared) = BackendDAEOptimize.collapseIndependentBlocks(inDAE);
      systs = clockPartitioning1(syst, shared);
    then BackendDAE.DAE(systs, shared);
  end match;
end clockPartitioning;

protected function clockPartitioning1
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  output list<BackendDAE.EqSystem> outSysts;
protected
  BackendDAE.IncidenceMatrix m,mT;
  array<Integer> ixs;
  Boolean b;
  Integer i;
  BackendDAE.Shared shared;
  BackendDAE.EqSystem syst;
  DAE.FunctionTree funcs;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs;
  BackendDAE.StateSets stateSets;
algorithm
  funcs := BackendDAEUtil.getFunctions(inShared);

  BackendDAE.EQSYSTEM(vars, eqs, _, _, _, stateSets, _) := inSyst;
  syst := BackendDAE.EQSYSTEM(vars, eqs, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets, BackendDAE.UNKNOWN_PARTITION());
  (syst, m, mT) := BackendDAEUtil.getIncidenceMatrixfromOption(syst, BackendDAE.BASECLOCK(), SOME(funcs));

  //print("base-clock partitioning\n");
  //print("=======================\n");
  //BackendDump.dumpEqSystem(syst, "System (before base-clock partitioning)");
  //BackendDump.dumpIncidenceMatrix(m);

  ixs := arrayCreate(arrayLength(m), 0);
  i := partitionIndependentBlocks0(m, mT, ixs);

  outSysts := if i > 1 then
      partitionIndependentBlocksSplitBlocks(i, syst, ixs, mT, false) 
    else 
      {syst}; 

  // analyze partition kind
  outSysts := List.map1(outSysts, analyzePartitionKind, inShared);

  Debug.fcall2(Flags.DUMP_SYNCHRONOUS, BackendDump.dumpEqSystems, outSysts, "base-clock partitioning");
end clockPartitioning1;

public function partitionIndependentBlocks0
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ixs;
  output Integer on := 0;
algorithm
  for i in arrayLength(m):-1:1 loop
    on := if partitionIndependentBlocks1(i, on + 1, m, mT, ixs) then on + 1 else on; 
  end for;
end partitionIndependentBlocks0;

protected function partitionIndependentBlocks1
  input Integer ix;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ixs;
  output Boolean ochange;
algorithm
  ochange := arrayGet(ixs, ix) == 0;

  if ochange then
    arrayUpdate(ixs, ix, n);

    for i in arrayGet(m, ix) loop
      for j in arrayGet(mT, intAbs(i)) loop
        partitionIndependentBlocks1(intAbs(j), n, m, mT, ixs);
      end for;
    end for;
  end if;
end partitionIndependentBlocks1;

public function partitionIndependentBlocksSplitBlocks
  "Partitions the independent blocks into list<array<...>> by first constructing
  an array<list<...>> structure for the algorithm complexity"
  input Integer n;
  input BackendDAE.EqSystem syst;
  input array<Integer> ixs;
  input BackendDAE.IncidenceMatrix mT;
  input Boolean throwNoError;
  output list<BackendDAE.EqSystem> systs;
algorithm
  systs := match (syst)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray arr;
      array<list<BackendDAE.Equation>> ea;
      array<list<BackendDAE.Var>> va;
      list<list<BackendDAE.Equation>> el;
      list<list<BackendDAE.Var>> vl;
      Integer i1, i2;
      String s1, s2;
      Boolean b;

    case BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=arr)
      equation
        ea = arrayCreate(n, {});
        va = arrayCreate(n, {});
        i1 = BackendDAEUtil.equationSize(arr);
        i2 = BackendVariable.numVariables(vars);

        if i1 <> i2 and not throwNoError then
          s1 = intString(i1);
          s2 = intString(i2);
          Error.addSourceMessage(if i1 > i2 then Error.OVERDET_EQN_SYSTEM else Error.UNDERDET_EQN_SYSTEM,
            {s1, s2}, Absyn.dummyInfo);
          fail();
        end if;

        partitionEquations(BackendDAEUtil.equationArraySize(arr), arr, ixs, ea);
        partitionVars(i2, arr, vars, ixs, mT, va);
        el = arrayList(ea);
        vl = arrayList(va);
        (systs, (b, _)) = List.threadMapFold(el, vl, createEqSystem, (true, throwNoError));
        true = throwNoError or b;
      then
        systs;
  end match;
end partitionIndependentBlocksSplitBlocks;

protected function createEqSystem
  input list<BackendDAE.Equation> el;
  input list<BackendDAE.Var> vl;
  input tuple<Boolean, Boolean> iTpl;
  output BackendDAE.EqSystem syst;
  output tuple<Boolean, Boolean> oTpl;
protected
  BackendDAE.EquationArray arr;
  BackendDAE.Variables vars;
  Integer i1, i2;
  String s1, s2, s3, s4;
  list<String> crs;
  Boolean success, throwNoError;
algorithm
  (success, throwNoError) := iTpl;
  vars := BackendVariable.listVar1(vl);
  arr := BackendEquation.listEquation(el);
  i1 := BackendDAEUtil.equationSize(arr);
  i2 := BackendVariable.numVariables(vars);

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

  syst := BackendDAE.EQSYSTEM(vars, arr, NONE(), NONE(), BackendDAE.NO_MATCHING(), {}, BackendDAE.UNKNOWN_PARTITION());
  success := success and i1==i2;
  oTpl := (success, throwNoError);
end createEqSystem;

protected function partitionEquations
  input Integer n;
  input BackendDAE.EquationArray arr;
  input array<Integer> ixs;
  input array<list<BackendDAE.Equation>> ea;
protected
  Integer ix;
  list<BackendDAE.Equation> lst;
  BackendDAE.Equation eq;
algorithm
  for i in n:-1:1 loop
    ix := ixs[i];
    lst := ea[ix];
    eq := BackendEquation.equationNth1(arr, i);
    lst := eq::lst;
    // print("adding eq " +& intString(n) +& " to group " +& intString(ix) +& "\n");
    arrayUpdate(ea, ix, lst);
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
  Absyn.Info info;
algorithm
  for i in n:-1:1 loop
    v := BackendVariable.getVarAt(vars, i);
    cr := BackendVariable.varCref(v);

    // Select any equation that could define this variable
    if List.isEmpty(mT[i]) then
      name := ComponentReference.printComponentRefStr(cr);
      info := DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(v));
      Error.addSourceMessage(Error.EQUATIONS_VAR_NOT_DEFINED, {name}, info);
      fail();
    end if;

    // print("adding var " +& intString(i) +& " to group ???\n");
    eqix::_ := mT[i];
    eqix := intAbs(eqix);
    // print("var " +& intString(i) +& " has eq " +& intString(eqix) +& "\n");
    // That's the index of the indep.system
    ix := ixs[eqix];
    lst := va[ix];
    lst := v::lst;
    // print("adding var " +& intString(i) +& " to group " +& intString(ix) +& " (comes from eq: "+& intString(eqix) +&")\n");
    arrayUpdate(va, ix, lst);
  end for;
end partitionVars;

protected function analyzePartitionKind "author: lochel
  A variable u in sample(u) and a variable y in y = hold(ud) is in a
  continuous-time partition.

  Correspondingly, variables u and y in y = sample(uc), y = subSample(u),
  y = superSample(u), y = shiftSample(u), y = backSample(u), y = previous(u),
  are in a clocked partition. Equations in a clocked when clause are also in a
  clocked partition.

  Other partitions where none of the variables in the partition are associated
  with any of the operators above have an unspecified partition kind and are
  considered continuous-time partitions.

  BackendDAE.CONTINUOUS_TIME_PARTITION():
    * sample(u)
    * y = hold(...)

  BackendDAE.CLOCKED_PARTITION():
    * y = sample(...)
    * y = subSample(u)
    * y = superSample(u)
    * y = shiftSample(u)
    * y = backSample(u)
    * y = previous(u)"
  input BackendDAE.EqSystem inEqSystem;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outEqSystem;
protected
  BackendDAE.Variables orderedVars;
  BackendDAE.EquationArray orderedEqs;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
  list<DAE.ComponentRef> continuousTimeVars, clockedVars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs, stateSets=stateSets) := inEqSystem;

  //((continuousTimeVars, clockedVars)) := BackendDAEUtil.traverseBackendDAEExpsEqSystem(inEqSystem, getVariableLists, ({}, {}));
  (continuousTimeVars, clockedVars) := getVariableLists2(BackendEquation.equationList(orderedEqs));

// print("continuousTimeVars (pre):\n");
// BackendDump.debuglst((continuousTimeVars, ComponentReference.printComponentRefStr, "\n", "\n"));
// print("clockedVars (pre):\n");
// BackendDump.debuglst((clockedVars, ComponentReference.printComponentRefStr, "\n", "\n"));

  continuousTimeVars := filterVariables(orderedVars, continuousTimeVars);
  clockedVars := filterVariables(orderedVars, clockedVars);
// print("continuousTimeVars (post):\n");
// BackendDump.debuglst((continuousTimeVars, ComponentReference.printComponentRefStr, "\n", "\n"));
// print("clockedVars (post):\n");
// BackendDump.debuglst((clockedVars, ComponentReference.printComponentRefStr, "\n", "\n"));

  partitionKind := getPartitionKind(continuousTimeVars, clockedVars);
  outEqSystem := BackendDAE.EQSYSTEM(orderedVars, orderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets, partitionKind);

  outEqSystem := subClockPartitioning(outEqSystem, inShared);
end analyzePartitionKind;

protected function subClockPartitioning
  input BackendDAE.EqSystem inEqSystem;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outEqSystem;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.IncidenceMatrix m,mT;
  array<Integer> ixs;
  Boolean b;
  Integer i;
  BackendDAE.Shared shared;
  BackendDAE.EqSystem syst;
  DAE.FunctionTree funcs;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
  list<BackendDAE.Equation> eqLst;
algorithm
  funcs := BackendDAEUtil.getFunctions(inShared);

  BackendDAE.EQSYSTEM(vars, eqs, _, _, _, stateSets, partitionKind) := inEqSystem;
  syst := BackendDAE.EQSYSTEM(vars, eqs, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets, BackendDAE.UNKNOWN_PARTITION());
  (syst, m, mT) := BackendDAEUtil.getIncidenceMatrixfromOption(syst, BackendDAE.SUBCLOCK(), SOME(funcs));

  ixs := arrayCreate(arrayLength(m), 0);
  i := partitionIndependentBlocks0(m, mT, ixs);

  // print("Got sub-partitioning!\n");
  // print(stringDelimitList(List.map(arrayList(ixs), intString), ","));
  // print("\n");

  // TODO: make this better
  eqLst := BackendEquation.equationList(eqs);
  eqLst := setSubClockPartition(eqLst, arrayList(ixs));
  eqs := BackendEquation.listEquation(eqLst);

  outEqSystem := BackendDAE.EQSYSTEM(vars, eqs, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets, partitionKind);
end subClockPartitioning;

protected function setSubClockPartition
  input list<BackendDAE.Equation> inEqnLst;
  input list<Integer> inPartitionIndices;
  output list<BackendDAE.Equation> outEqnLst;
algorithm
  outEqnLst := list(BackendEquation.setSubPartition(eq, index)
    threaded for eq in inEqnLst, index in inPartitionIndices);
end setSubClockPartition;

protected function getVariableLists
  input DAE.Exp inExp;
  input tuple<list<DAE.ComponentRef>, list<DAE.ComponentRef>> inTpl;
  output DAE.Exp outExp;
  output tuple<list<DAE.ComponentRef>, list<DAE.ComponentRef>> outTpl;
algorithm
  (outExp,outTpl) := match(inExp,inTpl)
    local
      list<DAE.ComponentRef> continuousTimeVars, clockedVars;
      DAE.ComponentRef cr;

    case (DAE.CALL(path=Absyn.IDENT(name="sample"), expLst=_::DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars))
      then (inExp, (cr::continuousTimeVars, clockedVars));

    case (DAE.CALL(path=Absyn.IDENT(name="subSample"), expLst=DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars))
      then (inExp, (continuousTimeVars, cr::clockedVars));

    case (DAE.CALL(path=Absyn.IDENT(name="superSample"), expLst=DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars))
      then (inExp, (continuousTimeVars, cr::clockedVars));

    case (DAE.CALL(path=Absyn.IDENT(name="shiftSample"), expLst=DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars))
      then (inExp, (continuousTimeVars, cr::clockedVars));

    case (DAE.CALL(path=Absyn.IDENT(name="backSample"), expLst=DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars))
      then (inExp, (continuousTimeVars, cr::clockedVars));

    case (DAE.CALL(path=Absyn.IDENT(name="previous"), expLst=DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars))
      then (inExp, (continuousTimeVars, cr::clockedVars));

    else (inExp,inTpl);
  end match;
end getVariableLists;

protected function getVariableLists2
  input list<BackendDAE.Equation> inEqnLst;
  output list<DAE.ComponentRef> outContinuousTimeVars := {};
  output list<DAE.ComponentRef> outClockedVars := {};
protected
  DAE.ComponentRef cr;
  String func_id;
  list<DAE.Exp> args;
algorithm
  for eq in inEqnLst loop
    _ := match(eq)
      case BackendDAE.EQUATION(exp = DAE.CREF(componentRef = cr),
          scalar = DAE.CALL(path = Absyn.IDENT(name = func_id), expLst = args))
        algorithm
          (outContinuousTimeVars, outClockedVars) := getVariableLists3(func_id,
            args, cr, outContinuousTimeVars, outClockedVars);
        then ();

      case BackendDAE.EQUATION(scalar = DAE.CREF(componentRef = cr),
          exp = DAE.CALL(path = Absyn.IDENT(name = func_id), expLst = args))
        algorithm
          (outContinuousTimeVars, outClockedVars) := getVariableLists3(func_id,
            args, cr, outContinuousTimeVars, outClockedVars);
        then ();

      else
        algorithm
          (_, (outContinuousTimeVars, outClockedVars)) :=
            BackendEquation.traverseBackendDAEExpsEqn(eq, getVariableLists, 
              (outContinuousTimeVars, outClockedVars));
        then
          ();
    end match;
  end for;
end getVariableLists2;

protected function getVariableLists3
  input String inFunctionName;
  input list<DAE.Exp> inFunctionArgs;
  input DAE.ComponentRef inVarCref;
  input list<DAE.ComponentRef> inContinuousTimeVars;
  input list<DAE.ComponentRef> inClockedVars;
  output list<DAE.ComponentRef> outContinuousTimeVars;
  output list<DAE.ComponentRef> outClockedVars;
algorithm
  (outContinuousTimeVars, outClockedVars) := match(inFunctionName, inFunctionArgs)
    local
      DAE.ComponentRef cr;

    // y = sample(u) or sample(u) = y
    case ("sample", _ :: DAE.CREF(componentRef = cr) :: _) 
      then (cr :: inContinuousTimeVars, inVarCref :: inClockedVars);

    // y = hold(...) or hold(...) = y
    case ("hold", _)
      then (inVarCref :: inContinuousTimeVars, inClockedVars);

    // y = subSample(u) or subSample(u) = y
    case ("subSample", DAE.CREF(componentRef = cr) :: _)
      then (inContinuousTimeVars, inVarCref :: cr :: inClockedVars);

    // y = superSample(u) or superSample(u) = y
    case ("superSample", DAE.CREF(componentRef = cr) :: _)
      then (inContinuousTimeVars, inVarCref :: cr :: inClockedVars);

    // y = shiftSample(u) or shiftSample(u) = y
    case ("shiftSample", DAE.CREF(componentRef = cr) :: _)
      then (inContinuousTimeVars, inVarCref :: cr :: inClockedVars);

    // y = backSample(u) or backSample(u) = y
    case ("backSample", DAE.CREF(componentRef = cr) :: _)
      then (inContinuousTimeVars, inVarCref :: cr :: inClockedVars);

    // y = previous(u) or previous(u) = y
    case ("previous", DAE.CREF(componentRef = cr) :: _)
      then (inContinuousTimeVars, inVarCref :: cr :: inClockedVars);

    else (inContinuousTimeVars, inClockedVars);
  end match;
end getVariableLists3;

protected function getPartitionKind
  input list<DAE.ComponentRef> inContinuousTimeVars;
  input list<DAE.ComponentRef> inClockedVars;
  output BackendDAE.BaseClockPartitionKind outPartitionKind;
algorithm
  outPartitionKind := match(inContinuousTimeVars, inClockedVars)
    case ({}, {}) then BackendDAE.UNSPECIFIED_PARTITION();
    case ({}, _) then BackendDAE.CLOCKED_PARTITION(DAE.INFERRED_CLOCK());
    case (_, {}) then BackendDAE.CONTINUOUS_TIME_PARTITION();
    case (_, _) then BackendDAE.UNKNOWN_PARTITION();
  end match;
end getPartitionKind;

protected function filterVariables
  input BackendDAE.Variables inVars;
  input list<DAE.ComponentRef> inCrefs;
  output list<DAE.ComponentRef> outCrefs := {};
algorithm
  for cr in inCrefs loop
    try
      BackendVariable.getVar(cr, inVars);
      outCrefs := cr :: outCrefs;
    else
    end try;
  end for;

  outCrefs := listReverse(outCrefs);
end filterVariables;

annotation(__OpenModelica_Interface="backend");
end SynchronousFeatures;
