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
  i := partitionIndependentBlocks0(arrayLength(m), 0, m, mT, ixs);
  b := i > 1;

  //print("Got partition!\n");
  //print(stringDelimitList(List.map(arrayList(ixs), intString), ","));
  //print("\n");

  outSysts := Debug.bcallret5(b, partitionIndependentBlocksSplitBlocks, i, syst, ixs, mT, false, {syst});

  // analyze partition kind
  outSysts := List.map(outSysts, analyzePartitionKind);

  Debug.fcall2(Flags.DUMP_SYNCHRONOUS, BackendDump.dumpEqSystems, outSysts, "base-clock partitioning");
end clockPartitioning1;

public function partitionIndependentBlocks0
  input Integer n;
  input Integer n2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ixs;
  output Integer on;
algorithm
  on := match (n, n2, m, mT, ixs)
    local
      Boolean b;

    case (0, _, _, _, _) then n2;
    case (_, _, _, _, _) equation
      b = partitionIndependentBlocks1(n, n2+1, m, mT, ixs);
    then partitionIndependentBlocks0(n-1, Util.if_(b, n2+1, n2), m, mT, ixs);
  end match;
end partitionIndependentBlocks0;

protected function partitionIndependentBlocks1
  input Integer ix;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> ixs;
  output Boolean ochange;
algorithm
  ochange := partitionIndependentBlocks2(ixs[ix] == 0, ix, n, m, mT, ixs);
end partitionIndependentBlocks1;

protected function partitionIndependentBlocks2
  input Boolean b;
  input Integer ix;
  input Integer n;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input array<Integer> inIxs;
  output Boolean change;
algorithm
  change := match (b, ix, n, m, mT, inIxs)
    local
      list<Integer> lst;
      list<list<Integer>> lsts;
      array<Integer> ixs;

    case (false, _, _, _, _, _)
    then false;

    case (true, _, _, _, _, ixs) equation
      // i = ixs[ix];
      // print(intString(ix) +& "; update crap\n");
      // print("mark\n");
      ixs = arrayUpdate(ixs, ix, n);
      // print("mark OK\n");
      lst = List.map(m[ix], intAbs);
      // print(stringDelimitList(List.map(lst, intString), ", ") +& "\n");
      // print("len:" +& intString(arrayLength(mT)) +& "\n");
      lsts = List.map1r(lst, arrayGet, mT);
      // print("arrayNth OK\n");
      lst = List.map(List.flatten(lsts), intAbs);
      // print(stringDelimitList(List.map(lst, intString), ", ") +& "\n");
      // print("lst get\n");
      _ = List.map4(lst, partitionIndependentBlocks1, n, m, mT, ixs);
    then true;
  end match;
end partitionIndependentBlocks2;

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
  systs := match (n, syst, ixs, mT, throwNoError)
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

    case (_, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=arr), _, _, _) equation
      ea = arrayCreate(n, {});
      va = arrayCreate(n, {});
      i1 = BackendDAEUtil.equationSize(arr);
      i2 = BackendVariable.numVariables(vars);
      s1 = intString(i1);
      s2 = intString(i2);
      Error.assertionOrAddSourceMessage((i1 == i2) or throwNoError,
        Util.if_(i1 > i2, Error.OVERDET_EQN_SYSTEM, Error.UNDERDET_EQN_SYSTEM),
        {s1, s2}, Absyn.dummyInfo);

      partitionEquations(BackendDAEUtil.equationArraySize(arr), arr, ixs, ea);
      partitionVars(i2, arr, vars, ixs, mT, va);
      el = arrayList(ea);
      vl = arrayList(va);
      (systs, (b, _)) = List.threadMapFold(el, vl, createEqSystem, (true, throwNoError));
      true = throwNoError or b;
    then systs;
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
  s1 := intString(i1);
  s2 := intString(i2);
  crs := Debug.bcallret3(i1<>i2, List.mapMap, vl, BackendVariable.varCref, ComponentReference.printComponentRefStr, {});
  s3 := stringDelimitList(crs, "\n");
  s4 := Debug.bcallret1(i1<>i2, BackendDump.dumpEqnsStr, el, "");
  // Can this even be triggered? We check that all variables are defined somewhere, so everything should be balanced already?
  Debug.bcall3((i1<>i2) and not throwNoError, Error.addSourceMessage, Error.IMBALANCED_EQUATIONS, {s1, s2, s3, s4}, Absyn.dummyInfo);
  syst := BackendDAE.EQSYSTEM(vars, arr, NONE(), NONE(), BackendDAE.NO_MATCHING(), {}, BackendDAE.UNKNOWN_PARTITION());
  success := success and i1==i2;
  oTpl := (success, throwNoError);
end createEqSystem;

protected function partitionEquations
  input Integer n;
  input BackendDAE.EquationArray arr;
  input array<Integer> ixs;
  input array<list<BackendDAE.Equation>> ea;
algorithm
  _ := match (n, arr, ixs, ea)
    local
      Integer ix;
      list<BackendDAE.Equation> lst;
      BackendDAE.Equation eq;

    case (0, _, _, _)
    then ();

    case (_, _, _, _) equation
      ix = ixs[n];
      lst = ea[ix];
      eq = BackendEquation.equationNth1(arr, n);
      lst = eq::lst;
      // print("adding eq " +& intString(n) +& " to group " +& intString(ix) +& "\n");
      _ = arrayUpdate(ea, ix, lst);
      partitionEquations(n-1, arr, ixs, ea);
    then ();
  end match;
end partitionEquations;

protected function partitionVars
  input Integer n;
  input BackendDAE.EquationArray arr;
  input BackendDAE.Variables vars;
  input array<Integer> ixs;
  input BackendDAE.IncidenceMatrix mT;
  input array<list<BackendDAE.Var>> va;
algorithm
  _ := match (n, arr, vars, ixs, mT, va)
    local
      Integer ix, eqix;
      list<BackendDAE.Var> lst;
      BackendDAE.Var v;
      Boolean b;
      DAE.ComponentRef cr;
      String name;
      Absyn.Info info;

    case (0, _, _, _, _, _)
    then ();

    case (_, _, _, _, _, _) equation
      v = BackendVariable.getVarAt(vars, n);
      cr = BackendVariable.varCref(v);
      // Select any equation that could define this variable
      b = not List.isEmpty(mT[n]);
      name = Debug.bcallret1(not b, ComponentReference.printComponentRefStr, cr, "");
      info = DAEUtil.getElementSourceFileInfo(BackendVariable.getVarSource(v));
      Error.assertionOrAddSourceMessage(b, Error.EQUATIONS_VAR_NOT_DEFINED, {name}, info);
      // print("adding var " +& intString(n) +& " to group ???\n");
      eqix::_ = mT[n];
      eqix = intAbs(eqix);
      // print("var " +& intString(n) +& " has eq " +& intString(eqix) +& "\n");
      // That's the index of the indep.system
      ix = ixs[eqix];
      lst = va[ix];
      lst = v::lst;
      // print("adding var " +& intString(n) +& " to group " +& intString(ix) +& " (comes from eq: "+& intString(eqix) +&")\n");
      _ = arrayUpdate(va, ix, lst);
      partitionVars(n-1, arr, vars, ixs, mT, va);
    then ();
  end match;
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

  (continuousTimeVars, clockedVars) := filterVariables(orderedVars, continuousTimeVars, clockedVars);
// print("continuousTimeVars (post):\n");
// BackendDump.debuglst((continuousTimeVars, ComponentReference.printComponentRefStr, "\n", "\n"));
// print("clockedVars (post):\n");
// BackendDump.debuglst((clockedVars, ComponentReference.printComponentRefStr, "\n", "\n"));

  partitionKind := getPartitionKind(continuousTimeVars, clockedVars);
  outEqSystem := BackendDAE.EQSYSTEM(orderedVars, orderedEqs, NONE(), NONE(), BackendDAE.NO_MATCHING(), stateSets, partitionKind);
end analyzePartitionKind;

protected function getVariableLists
  input tuple<DAE.Exp, tuple<list<DAE.ComponentRef>, list<DAE.ComponentRef>>> inTpl;
  output tuple<DAE.Exp, tuple<list<DAE.ComponentRef>, list<DAE.ComponentRef>>> outTpl;
algorithm
  outTpl := match(inTpl)
    local
      DAE.Exp exp;
      list<DAE.ComponentRef> continuousTimeVars, clockedVars;
      DAE.ComponentRef cr;

    case ((exp as DAE.CALL(path=Absyn.IDENT(name="sample"), expLst=_::DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars)))
    then ((exp, (cr::continuousTimeVars, clockedVars)));

    case ((exp as DAE.CALL(path=Absyn.IDENT(name="subSample"), expLst=DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars)))
    then ((exp, (continuousTimeVars, cr::clockedVars)));

    case ((exp as DAE.CALL(path=Absyn.IDENT(name="superSample"), expLst=DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars)))
    then ((exp, (continuousTimeVars, cr::clockedVars)));

    case ((exp as DAE.CALL(path=Absyn.IDENT(name="shiftSample"), expLst=DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars)))
    then ((exp, (continuousTimeVars, cr::clockedVars)));

    case ((exp as DAE.CALL(path=Absyn.IDENT(name="backSample"), expLst=DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars)))
    then ((exp, (continuousTimeVars, cr::clockedVars)));

    case ((exp as DAE.CALL(path=Absyn.IDENT(name="previous"), expLst=DAE.CREF(componentRef=cr)::_), (continuousTimeVars, clockedVars)))
    then ((exp, (continuousTimeVars, cr::clockedVars)));

    else then inTpl;
  end match;
end getVariableLists;

protected function getVariableLists2
  input list<BackendDAE.Equation> inEqnLst;
  output list<DAE.ComponentRef> outContinuousTimeVars;
  output list<DAE.ComponentRef> outClockedVars;
algorithm
  (outContinuousTimeVars, outClockedVars) := match (inEqnLst)
    local
      DAE.Exp exp;
      list<DAE.ComponentRef> continuousTimeVars1, clockedVars1;
      list<DAE.ComponentRef> continuousTimeVars2, clockedVars2;
      DAE.ComponentRef cr;
      DAE.ComponentRef cr1;
      DAE.ComponentRef cr2;
      BackendDAE.Equation curr;
      list<BackendDAE.Equation> rest;

    case ({}) then ({}, {});

    // y = sample(u)
    case (BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr1), scalar=DAE.CALL(path=Absyn.IDENT(name="sample"), expLst=_::DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1};
      continuousTimeVars1 = {cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (listAppend(continuousTimeVars1, continuousTimeVars2), listAppend(clockedVars1, clockedVars2));

    // sample(u) = y
    case (BackendDAE.EQUATION(scalar=DAE.CREF(componentRef=cr1), exp=DAE.CALL(path=Absyn.IDENT(name="sample"), expLst=_::DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1};
      continuousTimeVars1 = {cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (listAppend(continuousTimeVars1, continuousTimeVars2), listAppend(clockedVars1, clockedVars2));

    // y = hold(...)
    case (BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr1), scalar=DAE.CALL(path=Absyn.IDENT(name="hold")))::rest) equation
      continuousTimeVars1 = {cr1};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (listAppend(continuousTimeVars1, continuousTimeVars2), clockedVars2);

    // hold(...) = y
    case (BackendDAE.EQUATION(scalar=DAE.CREF(componentRef=cr1), exp=DAE.CALL(path=Absyn.IDENT(name="hold")))::rest) equation
      continuousTimeVars1 = {cr1};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (listAppend(continuousTimeVars1, continuousTimeVars2), clockedVars2);

    // y = subSample(u)
    case (BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr1), scalar=DAE.CALL(path=Absyn.IDENT(name="subSample"), expLst=DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1, cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (continuousTimeVars2, listAppend(clockedVars1, clockedVars2));

    // subSample(u) = y
    case (BackendDAE.EQUATION(scalar=DAE.CREF(componentRef=cr1), exp=DAE.CALL(path=Absyn.IDENT(name="subSample"), expLst=DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1, cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (continuousTimeVars2, listAppend(clockedVars1, clockedVars2));

    // y = superSample(u)
    case (BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr1), scalar=DAE.CALL(path=Absyn.IDENT(name="superSample"), expLst=DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1, cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (continuousTimeVars2, listAppend(clockedVars1, clockedVars2));

    // superSample(u) = y
    case (BackendDAE.EQUATION(scalar=DAE.CREF(componentRef=cr1), exp=DAE.CALL(path=Absyn.IDENT(name="superSample"), expLst=DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1, cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (continuousTimeVars2, listAppend(clockedVars1, clockedVars2));

    // y = shiftSample(u)
    case (BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr1), scalar=DAE.CALL(path=Absyn.IDENT(name="shiftSample"), expLst=DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1, cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (continuousTimeVars2, listAppend(clockedVars1, clockedVars2));

    // shiftSample(u) = y
    case (BackendDAE.EQUATION(scalar=DAE.CREF(componentRef=cr1), exp=DAE.CALL(path=Absyn.IDENT(name="shiftSample"), expLst=DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1, cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (continuousTimeVars2, listAppend(clockedVars1, clockedVars2));

    // y = backSample(u)
    case (BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr1), scalar=DAE.CALL(path=Absyn.IDENT(name="backSample"), expLst=DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1, cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (continuousTimeVars2, listAppend(clockedVars1, clockedVars2));

    // backSample(u) = y
    case (BackendDAE.EQUATION(scalar=DAE.CREF(componentRef=cr1), exp=DAE.CALL(path=Absyn.IDENT(name="backSample"), expLst=DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1, cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (continuousTimeVars2, listAppend(clockedVars1, clockedVars2));

    // y = previous(u)
    case (BackendDAE.EQUATION(exp=DAE.CREF(componentRef=cr1), scalar=DAE.CALL(path=Absyn.IDENT(name="previous"), expLst=DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1, cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (continuousTimeVars2, listAppend(clockedVars1, clockedVars2));

    // previous(u) = y
    case (BackendDAE.EQUATION(scalar=DAE.CREF(componentRef=cr1), exp=DAE.CALL(path=Absyn.IDENT(name="previous"), expLst=DAE.CREF(componentRef=cr2)::_))::rest) equation
      clockedVars1 = {cr1, cr2};
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (continuousTimeVars2, listAppend(clockedVars1, clockedVars2));

    case (curr::rest) equation
      (_, (continuousTimeVars1, clockedVars1)) = BackendEquation.traverseBackendDAEExpsEqn(curr, getVariableLists, ({}, {}));
      (continuousTimeVars2, clockedVars2) = getVariableLists2(rest);
    then (listAppend(continuousTimeVars1, continuousTimeVars2), listAppend(clockedVars1, clockedVars2));
  end match;
end getVariableLists2;

protected function getPartitionKind
  input list<DAE.ComponentRef> inContinuousTimeVars;
  input list<DAE.ComponentRef> inClockedVars;
  output BackendDAE.BaseClockPartitionKind outPartitionKind;
algorithm
  outPartitionKind := match(inContinuousTimeVars, inClockedVars)
    case ({}, {}) then BackendDAE.UNSPECIFIED_PARTITION();
    case ({}, _) then BackendDAE.CLOCKED_PARTITION();
    case (_, {}) then BackendDAE.CONTINUOUS_TIME_PARTITION();
    case (_, _) then BackendDAE.UNKNOWN_PARTITION();
  end match;
end getPartitionKind;

protected function filterVariables
  input BackendDAE.Variables inVars;
  input list<DAE.ComponentRef> inContinuousTimeVars;
  input list<DAE.ComponentRef> inClockedVars;
  output list<DAE.ComponentRef> outContinuousTimeVars;
  output list<DAE.ComponentRef> outClockedVars;
algorithm
  (outContinuousTimeVars, outClockedVars) := matchcontinue(inVars, inContinuousTimeVars, inClockedVars)
    local
      list<DAE.ComponentRef> continuousTimeVars;
      list<DAE.ComponentRef> clockedVars;
      DAE.ComponentRef curr;
      list<DAE.ComponentRef> rest;
    case (_, {}, {}) then ({}, {});

    case (_, {}, curr::rest) equation
      (_, _) = BackendVariable.getVar(curr, inVars);
      (_, clockedVars) = filterVariables(inVars, {}, rest);
    then ({}, curr::clockedVars);

    case (_, {}, curr::rest) equation
      (_, clockedVars) = filterVariables(inVars, {}, rest);
    then ({}, clockedVars);

    case (_, curr::rest, _) equation
      (_, _) = BackendVariable.getVar(curr, inVars);
      (continuousTimeVars, clockedVars) = filterVariables(inVars, rest, inClockedVars);
    then (curr::continuousTimeVars, clockedVars);

    case (_, curr::rest, _) equation
      (continuousTimeVars, clockedVars) = filterVariables(inVars, rest, inClockedVars);
    then (continuousTimeVars, clockedVars);
  end matchcontinue;
end filterVariables;

end SynchronousFeatures;
