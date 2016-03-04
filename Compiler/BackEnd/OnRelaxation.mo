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

encapsulated package OnRelaxation "
  file:        OnRelaxation.mo
  package:     OnRelaxation
  description: Relaxation for MultiBody Systems"


public import BackendDAE;
public import DAE;

protected import Array;
protected import BackendDAEUtil;
protected import BackendDAEEXT;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendDAETransform;
protected import BaseHashSet;
protected import ComponentReference;
protected import Differentiate;
protected import DumpGraphML;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import HashSet;
protected import HashTable4;
protected import List;
protected import Matching;
protected import Sorting;
protected import SymbolicJacobian;
protected import Util;


/*
 * relaxation from gausian elemination
 *
 */

public function relaxSystem "author: Frenkel TUD 2011-05"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE, _) := BackendDAEUtil.mapEqSystemAndFold(inDAE, relaxSystem0, false);
end relaxSystem;

protected function relaxSystem0 "author: Frenkel TUD 2011-05"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input Boolean inChanged;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared outShared;
  output Boolean outChanged;
protected
  BackendDAE.StrongComponents comps;
  Boolean b, b1, b2;
  BackendDAE.Shared shared;
  BackendDAE.EqSystem syst;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps)) := isyst;
  (osyst, outShared, b2) := relaxSystem1(isyst, inShared, comps);
  outChanged := inChanged or b2;
end relaxSystem0;

protected function relaxSystem1 "author: Frenkel TUD 2011-05"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponents inComps;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output Boolean outRunMatching;
algorithm
  (osyst, oshared, outRunMatching):=
  matchcontinue (isyst, ishared, inComps)
    local
      list<Integer> eindex, vindx, eorphans, vorphans, unassigned, otherorphans, roots, constraints, constraintresidual;
      Boolean b, b1;
      BackendDAE.EqSystem syst, subsyst;
      BackendDAE.Shared shared;
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp, comp1;
      array<Integer> ass1, ass2, vec2, rowmarks, colummarks, mapIncRowEqn, orowmarks, ocolummarks;
      Integer size, mark, esize;
      list<BackendDAE.Equation> eqn_lst;
      list<BackendDAE.Var> var_lst;
      BackendDAE.Variables vars, tvars;
      BackendDAE.EquationArray eqns, teqns;
      BackendDAE.IncidenceMatrix m, m1, mc;
      BackendDAE.IncidenceMatrixT mt, mct;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      list<DAE.Exp> beqs;
      array<list<tuple<Integer, DAE.Exp>>> matrix;
      array<DAE.Exp> crefexps;
      list<DAE.Exp> crefexplst;
      array<list<Integer>> vorphansarray1, mapEqnIncRow, ass22, vec1;
      list<BackendDAE.Equation> neweqns;
      HashTable4.HashTable ht;
      DAE.FunctionTree funcs;

    case (_, _, {})
      then (isyst, ishared, false);
    case (_, shared as BackendDAE.SHARED(functionTree=funcs),
      (BackendDAE.EQUATIONSYSTEM(eqns=eindex, vars=vindx, jac=BackendDAE.FULL_JACOBIAN(SOME(jac)), jacType=BackendDAE.JAC_LINEAR()))::comps)
      equation
        print("try to relax\n");
          BackendDAEUtil.profilerinit();
          BackendDAEUtil.profilerstart2();
          BackendDAEUtil.profilerstart1();
        size = listLength(vindx);
        esize = listLength(eindex);
        ass1 = arrayCreate(size, -1);
        ass2 = arrayCreate(size, -1);
        eqn_lst = BackendEquation.getEqns(eindex, BackendEquation.getEqnsFromEqSystem(isyst));
        eqns = BackendEquation.listEquation(eqn_lst);
        var_lst = List.map1r(vindx, BackendVariable.getVarAt, BackendVariable.daeVars(isyst));
        vars = BackendVariable.listVar1(var_lst);

        subsyst = BackendDAEUtil.createEqSystem(vars, eqns);
        (subsyst, m, mt, mapEqnIncRow, mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(subsyst, BackendDAE.ABSOLUTE(), SOME(funcs));
        //  BackendDump.dumpEqSystem(subsyst);

        // Vector Matching a=f(..), f(..)=a
        ((_, ass1, ass2)) = List.fold1(eqn_lst, vectorMatching, vars, (1, ass1, ass2));
        // Alias Matching only if one side is matched
        ((_, ass1, ass2)) = List.fold1(eqn_lst, aliasMatching, vars, (1, ass1, ass2));
        // Vector matching
        m1 = arrayCreate(size, {});
        transformJacToIncidenceMatrix2(jac, m1, mapIncRowEqn, eqns, ass1, ass2, isConstOneMinusOne);
        Matching.matchingExternalsetIncidenceMatrix(size, size, m1);
        true = BackendDAEEXT.setAssignment(size, size, ass2, ass1);
        BackendDAEEXT.matching(size, size, 5, -1, 1.0, 0);
        BackendDAEEXT.getAssignment(ass2, ass1);

        // Natural Matching - seems not to be good enough
        //((_, ass1, ass2)) = List.fold1(eqn_lst, naturalMatching, vars, (1, ass1, ass2));
        //((_, ass1, ass2)) = List.fold1(eqn_lst, naturalMatching1, vars, (1, ass1, ass2));
        //((_, ass1, ass2)) = List.fold1(eqn_lst, naturalMatching2, vars, (1, ass1, ass2));
        //  subsyst = BackendDAEUtil.setEqSystemMatching(subsyst, BackendDAE.MATCHING(ass1, ass2, {}));
        //  DumpGraphML.dumpSystem(subsyst, shared, NONE(), intString(size) + "SystemVectorMatching.graphml");
        //  BackendDump.dumpMatching(ass1);
        //  BackendDump.dumpMatching(ass2);

        // Boeser hack fuer FourBar
    /*
        (subsyst, m, mt, mapEqnIncRow, mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(subsyst, BackendDAE.ABSOLUTE(), SOME(funcs));
        temp::_ = mapEqnIncRow[72];
        arrayUpdate(ass1, 90, temp);
        arrayUpdate(ass2, temp, 90);

        temp::_ = mapEqnIncRow[97];
        arrayUpdate(ass1, 125, temp);
        arrayUpdate(ass2, temp, 125);

        temp::_ = mapEqnIncRow[99];
        arrayUpdate(ass1, 128, temp);
        arrayUpdate(ass2, temp, 128);
          subsyst = BackendDAEUtil.setEqSystemMatching(subsyst, BackendDAE.MATCHING(ass1, ass2, {}));
          DumpGraphML.dumpSystem(subsyst, shared, NONE(), intString(size) + "SystemHackMatching.graphml");
*/

        // Matching based on Enhanced Adiacency Matrix, take care of the solvability - theems to be good but not good enough
        //  (subsyst, _, _) = BackendDAEUtil.getIncidenceMatrix(subsyst, BackendDAE.ABSOLUTE(), SOME(funcs));
        //   BackendDump.dumpEqSystem(subsyst);
        //   dumpJacMatrix(jac, 1, 1, size, vars);
        m1 = arrayCreate(size, {});
        //mt1 = arrayCreate(size, {});
        transformJacToIncidenceMatrix1(jac, m1, ass1, ass2, isConstOneMinusOne);
        //  BackendDump.dumpIncidenceMatrix(m1);
        //  BackendDump.dumpIncidenceMatrixT(mt1);
        //transformJacToIncidenceMatrix(jac, 1, 1, size, m1, mt1, isConstOneMinusOne);
        Matching.matchingExternalsetIncidenceMatrix(size, size, m1);
        true = BackendDAEEXT.setAssignment(size, size, ass2, ass1);
        BackendDAEEXT.matching(size, size, 1, -1, 1.0, 0);
        BackendDAEEXT.getAssignment(ass2, ass1);

        //  subsyst = BackendDAEUtil.setEqSystemMatching(subsyst, BackendDAE.MATCHING(ass1, ass2, {}));
        //  DumpGraphML.dumpSystem(subsyst, shared, NONE(), intString(size) + "SystemOneMatching.graphml");
        //  BackendDump.dumpMatching(ass1);
        //  BackendDump.dumpMatching(ass2);

        // onefreeMatching
        //  print("mapEqnIncRow:\n");
        //  BackendDump.dumpIncidenceMatrix(mapEqnIncRow);
        unassigned = Matching.getUnassigned(size, ass2, {});
        colummarks = arrayCreate(size, -1);
        onefreeMatchingBFS(unassigned, m, mt, size, ass1, ass2, colummarks, 1, {});

        //  BackendDump.dumpMatching(ass1);
        //  BackendDump.dumpMatching(ass2);
        //  subsyst = BackendDAEUtil.setEqSystemMatching(subsyst, BackendDAE.MATCHING(ass1, ass2, {}));
        //  DumpGraphML.dumpSystem(subsyst, shared, NONE(), intString(size) + "SystemOneFreeMatching.graphml");

        // hier sollte zur vorsicht noch mal ein matching durchgefuehrt werden
          BackendDAEUtil.profilerstop1();
          print("Matching  time: " + realString(BackendDAEUtil.profilertime1()) + "\n");
          BackendDAEUtil.profilerreset1();
          BackendDAEUtil.profilerstart1();
        // collect tearing variables and residual equations
        vorphans = getOrphans(1, size, ass1, {});
        eorphans = getOrphans(1, size, ass2, {});
        //   print("Var Orphans: \n");
        //   BackendDump.debuglst((vorphans, intString, ", ", "\n"));
        //   print("Equation Orphans: \n");
        //   BackendDump.debuglst((eorphans, intString, ", ", "\n"));

        // transform to nonscalar
        ass1 = BackendDAETransform.varAssignmentNonScalar(ass1, mapIncRowEqn);
        ass22 = BackendDAETransform.eqnAssignmentNonScalar(mapEqnIncRow, ass2);
        eorphans = List.uniqueIntN(List.map1r(eorphans, arrayGet, mapIncRowEqn), arrayLength(mapIncRowEqn));
        (subsyst, m, mt) = BackendDAEUtil.getIncidenceMatrix(subsyst, BackendDAE.ABSOLUTE(), SOME(funcs));
        //  BackendDump.dumpIncidenceMatrix(m);
        //  BackendDump.dumpIncidenceMatrixT(mt);

        // genereate cliques
        rowmarks = arrayCreate(size, -1);
        colummarks = arrayCreate(size, -1);
        orowmarks = arrayCreate(size, -1);
        ocolummarks = arrayCreate(size, -1);
        vorphansarray1 = arrayCreate(size, {});
        mc = arrayCreate(esize, {});
        mct = arrayCreate(size, {});
        mc = Array.copy(m, mc);
        mct = Array.copy(mt, mct);
        mark = 1 "init mark value";
        (mark, constraintresidual) = generateCliquesResidual(eorphans, ass1, ass22, mc, mct, mark, rowmarks, colummarks, vars, {}) "generate cliques for residual equations";
        //  print("constraintresidual: \n");
        //   BackendDump.debuglst((constraintresidual, intString, ", ", "\n"));
        (mark, roots, constraints) = prepairOrphansOrder(vorphans, ass1, ass22, mc, mct, mark, rowmarks, colummarks, vorphansarray1, vars, {}, {}) "generate cliques for tearing vars";
        mark = prepairOrphansOrder2(vorphans, ass1, ass22, mc, mct, mark, rowmarks, colummarks, vorphansarray1);
        //  subsyst = BackendDAE.EQSYSTEM(vars, eqns, SOME(mc), SOME(mct), BackendDAE.NO_MATCHING(), {});
        //  DumpGraphML.dumpSystem(subsyst, shared, NONE(), intString(size) + "SystemPreIndex.graphml");
        //  print("roots:\n");
        //  BackendDump.debuglst((roots, intString, ", ", "\n"));
        //  print("constraints:\n");
        //  BackendDump.debuglst((constraints, intString, ", ", "\n"));
          BackendDAEUtil.profilerstop1();
          print("Identifikation  time: " + realString(BackendDAEUtil.profilertime1()) + "\n");
          BackendDAEUtil.profilerreset1();
          BackendDAEUtil.profilerstart1();
        // Order of orphans
        vorphansarray1 = arrayCreate(size, {});
        List.map2_0(roots, doMark, rowmarks, mark);
        List.map2_0(constraints, doMark, rowmarks, mark);
        otherorphans = List.select2(vorphans, unmarked, rowmarks, mark);
        //  print("otherorphans:\n");
        //  BackendDump.debuglst((otherorphans, intString, ", ", "\n"));
        mark = getOrphansOrderEdvanced(otherorphans, ass1, ass22, m, mt, mc, mct, mark, rowmarks, colummarks, vorphansarray1);
        List.map2_0(otherorphans, removeRootConnections, vorphansarray1, roots);
        mark = getConstraintesOrphansOrderEdvanced(constraints, ass1, ass22, m, mt, mc, mct, mark, rowmarks, colummarks, vorphansarray1);
        //  print("getOrphansOrderEdvanced:\n");
        //  BackendDump.dumpIncidenceMatrix(vorphansarray1);

        (vorphans, mark) = getOrphansOrderEdvanced3(roots, otherorphans, constraints, vorphans, vorphansarray1, mark, rowmarks);
          BackendDAEUtil.profilerstop1();
          print("Reihenfolge  time: " + realString(BackendDAEUtil.profilertime1()) + "\n");
          BackendDAEUtil.profilerreset1();
          BackendDAEUtil.profilerstart1();
        List.map2_0(constraints, doMark, rowmarks, mark);
        otherorphans = List.select2(vorphans, unmarked, rowmarks, mark);

        //  print("sorted Var Orphans: \n");
        //   List.map1_0(vorphans, dumpVar, vars);
        //  BackendDump.debuglst((vorphans, intString, ", ", "\n"));
        //  BackendDump.dumpVarsArray(vars);

        // get pairs of orphans
        List.map2_0(constraintresidual, doAssign, ass22, {-1});
        mark = getOrphansPairs(otherorphans, ass1, ass22, m, mt, mark+1, rowmarks, colummarks);
        List.map2_0(constraintresidual, doAssign, ass22, {});
        mark = getOrphansPairsConstraints(constraints, ass1, ass22, mc, mct, mark, rowmarks, colummarks, eqns);
        //  print("Matching with Orphans:\n");
        //  BackendDump.dumpMatching(ass1);
        //  BackendDump.dumpIncidenceMatrix(ass22);
          BackendDAEUtil.profilerstop1();
          print("Paarung  time: " + realString(BackendDAEUtil.profilertime1()) + "\n");
          BackendDAEUtil.profilerreset1();
          BackendDAEUtil.profilerstart1();
        vec1 = arrayCreate(esize, {});
        vec2 = arrayCreate(esize, -1);

        orowmarks = List.fold1(vorphans, markOrphans, 1, orowmarks);
        ocolummarks = List.fold1(eorphans, markOrphans, 1, ocolummarks);
        mark = getIndexesForEqnsAdvanced(vorphans, 1, m, mt, mark, rowmarks, colummarks, orowmarks, ocolummarks, ass1, ass22, vec1, vec2, arrayCreate(esize, false), vars, eqns, shared, size);

        //  BackendDump.dumpIncidenceMatrix(vec1);
        //  BackendDump.dumpMatching(vec2);
        //  vec3 = arrayCreate(size, -1);
        //  _ = List.fold1(arrayList(vec2), transposeOrphanVec, vec3, 1);
        //  DumpGraphML.dumpSystem(subsyst, shared, SOME(vec3), "System.graphml");

        ((_, _, _, eqns, vars)) = Array.fold(vec2, getEqnsinOrder, (eqns, vars, ass22, BackendEquation.listEquation({}), BackendVariable.emptyVars()));
          BackendDAEUtil.profilerstop1();
          print("Indizierung  time: " + realString(BackendDAEUtil.profilertime1()) + "\n");
          BackendDAEUtil.profilerreset1();
          BackendDAEUtil.profilerstart1();
        // replace evaluated parametes
        //_ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(eqns, replaceFinalParameter, BackendVariable.daeKnVars(shared));

        subsyst = BackendDAEUtil.createEqSystem(vars, eqns);
        (subsyst, m, _) = BackendDAEUtil.getIncidenceMatrix(subsyst, BackendDAE.ABSOLUTE(), SOME(funcs));
        //  BackendDump.dumpEqSystem(subsyst);
        //  DumpGraphML.dumpSystem(subsyst, shared, NONE(), intString(size) + "SystemIndexed.graphml");
        (SOME(jac), _) = SymbolicJacobian.calculateJacobian(vars, eqns, m, true, ishared);
        (beqs, _) = BackendDAEUtil.getEqnSysRhs(eqns, vars, SOME(funcs));
        beqs = listReverse(beqs);
        //  print("Jacobian:\n");
        //  print(BackendDump.dumpJacobianStr(SOME(jac)) + "\n");
        // dumpJacMatrix(jac, 1, 1, size, vars);

        matrix = arrayCreate(size, {});
        transformJacToMatrix(jac, 1, 1, size, beqs, matrix);
        //  print("Jacobian as Matrix:\n");
        //  dumpMatrix(1, size, matrix);
        _ = HashTable4.emptyHashTable();
        (tvars, teqns) = gaussElimination(1, size, matrix, BackendVariable.emptyVars(), BackendEquation.listEquation({}), (1, 1));
        //  dumpMatrix(1, size, matrix);
        //  subsyst = BackendDAEUtil.createEqSystem(tvars, teqns);
        //  BackendDump.dumpEqSystem(subsyst);
        eqn_lst = BackendEquation.equationList(teqns);
        var_lst = BackendVariable.varList(tvars);
        syst = List.fold(eqn_lst, BackendEquation.equationAddDAE, isyst);
        syst = List.fold(var_lst, BackendVariable.addVarDAE, syst);
        crefexplst = List.map(BackendVariable.varList(vars), makeCrefExps);
        crefexps = listArray(crefexplst);
        neweqns = makeGausElimination(1, size, matrix, crefexps, {});
          BackendDAEUtil.profilerstop1();
          print("Gaus Elimination time: " + realString(BackendDAEUtil.profilertime1()) + "\n");
          BackendDAEUtil.profilerreset1();
          BackendDAEUtil.profilerstart1();
        syst = replaceEquationsAddNew(eindex, neweqns, syst);
          BackendDAEUtil.profilerstop2();
          print("Gesamt  time: " + realString(BackendDAEUtil.profilertime2()) + "\n");
          BackendDAEUtil.profilerreset1();
          BackendDAEUtil.profilerstart1();
        /*
        vars = BackendVariable.addVars(var_lst, vars);
        eqns = BackendEquation.addEquations(neweqns, teqns);
        subsyst = BackendDAEUtil.createEqSystem(vars, eqns);
          (subsyst, m, mt, mapEqnIncRow, mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(subsyst, BackendDAE.NORMAL(), SOME(funcs));
          print("Relaxed System:\n");
          BackendDump.dumpEqSystem(subsyst);

          size = arrayLength(m);
          Matching.matchingExternalsetIncidenceMatrix(size, size, m);
          ass1 = arrayCreate(size, -1);
          ass2 = arrayCreate(size, -1);
          BackendDAEEXT.matching(size, size, 5, -1, 1.0, 1);
          BackendDAEEXT.getAssignment(ass2, ass1);
          subsyst = BackendDAEUtil.setEqSystemMatching(subsyst, BackendDAE.MATCHING(ass1, ass2, {}));
          (subsyst, othercomps) = BackendDAETransform.strongComponentsScalar(subsyst, shared, mapEqnIncRow, mapIncRowEqn);
          print("Relaxed System:\n");
          BackendDump.dumpEqSystem(subsyst);
        */

        //  (syst, _, _) = BackendDAEUtil.getIncidenceMatrix(syst, BackendDAE.NORMAL(), SOME(funcs));
        //  BackendDump.dumpEqSystem(syst);
        //  (i1, i2, i3) = countOperations1(syst, shared);
        //  print("Add Operations: " + intString(i1) + "\n");
        //  print("Mul Operations: " + intString(i2) + "\n");
        //  print("Oth Operations: " + intString(i3) + "\n");
          print("Ok system relaxed\n");
        (syst, shared, _) = relaxSystem1(syst, shared, comps);
      then
        (syst, shared, true);
    case (_, _, _::comps)
      equation
        (syst, shared, b) = relaxSystem1(isyst, ishared, comps);
      then
        (syst, shared, b);
  end matchcontinue;
end relaxSystem1;

protected function removeRootConnections
  input Integer orphan;
  input array<list<Integer>> orphansarray;
  input list<Integer> roots;
algorithm
  _:= matchcontinue(orphan, orphansarray, roots)
    local
      list<Integer> lst;
    case(_, _, _)
      equation
        lst = orphansarray[orphan];
        true = intGt(listLength(lst), 1);
        lst = List.fold1(roots, List.removeOnTrue, intEq, lst);
        arrayUpdate(orphansarray, orphan, lst);
      then
        ();
    case(_, _, _)
      then
        ();
  end matchcontinue;
end removeRootConnections;

protected function replaceFinalParameter "author: Frenkel TUD 2012-06"
  input tuple<DAE.Exp, BackendDAE.Variables> itpl;
  output tuple<DAE.Exp, BackendDAE.Variables> outTpl;
protected
  DAE.Exp e;
  BackendDAE.Variables knvars;
  Boolean b;
algorithm
  (e, knvars) := itpl;
  (e, (knvars, b)) := Expression.traverseExpBottomUp(e, traverserExpreplaceFinalParameter, (knvars, false));
  (e, _) := ExpressionSimplify.condsimplify(b, e);
  outTpl := (e, knvars);
end replaceFinalParameter;

protected function traverserExpreplaceFinalParameter "author: Frenkel TUD 2012-06"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables, Boolean> tpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables, Boolean> outTpl;
algorithm
  (outExp, outTpl) := matchcontinue (inExp, tpl)
    local
      BackendDAE.Variables knvars;
      DAE.Exp e, e1;
      DAE.ComponentRef cr;
      BackendDAE.Var v;
    case (DAE.CREF(componentRef=cr), (knvars, _))
      equation
        (v::_, _) = BackendVariable.getVar(cr, knvars);
        true = BackendVariable.isFinalVar(v);
        e1 = BackendVariable.varBindExpStartValue(v);
      then
        (e1, (knvars, true));

    else (inExp, tpl);
  end matchcontinue;
end traverserExpreplaceFinalParameter;


protected function replaceEquationsAddNew
  input list<Integer> inEqnIndxes;
  input list<BackendDAE.Equation> inEqns;
  input BackendDAE.EqSystem inEqSystem;
  output BackendDAE.EqSystem outEqSystem;
algorithm
  outEqSystem := match(inEqnIndxes, inEqns, inEqSystem)
    local
      Integer index;
      list<Integer> indices;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      BackendDAE.EqSystem eqSystem;
      BackendDAE.Variables orderedVars;
      BackendDAE.EquationArray orderedEqs;
      Option<BackendDAE.IncidenceMatrix> m, mT;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;

    case ({}, _, _)
    then BackendEquation.equationsAddDAE(inEqns, inEqSystem);

    case (index::indices, eqn::eqns, BackendDAE.EQSYSTEM(orderedEqs=orderedEqs)) equation
      eqSystem = BackendDAEUtil.setEqSystEqs(inEqSystem, BackendEquation.setAtIndex(orderedEqs, index, eqn));
    then replaceEquationsAddNew(indices, eqns, eqSystem);
  end match;
end replaceEquationsAddNew;

protected function dumpVar "author: Frenkel TUD 2012-05"
  input Integer id;
  input BackendDAE.Variables vars;
protected
  BackendDAE.Var v;
algorithm
  v := BackendVariable.getVarAt(vars, id);
  print(ComponentReference.printComponentRefStr(BackendVariable.varCref(v)));
  print("\n");
end dumpVar;

protected function transposeOrphanVec "author: Frenkel TUD 2012-05"
  input Integer c;
  input array<list<Integer>> vec3;
  input Integer inId;
  output Integer outId;
algorithm
  outId := matchcontinue(c, vec3, inId)
    local list<Integer> lst;
    case (_, _, _)
      equation
        true = intGt(c, 0);
        lst = vec3[c];
        arrayUpdate(vec3, c, inId::lst);
      then
        inId + 1;
    else
      inId + 1;
  end matchcontinue;
end transposeOrphanVec;

protected function markOrphans "author: Frenkel TUD 2012-05"
  input Integer o;
  input Integer mark;
  input array<Integer> rowmark;
  output array<Integer> orowmark;
algorithm
  orowmark := arrayUpdate(rowmark, o, mark);
end markOrphans;

protected function generateCliquesResidual "author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input BackendDAE.Variables vars;
  input list<Integer> iconstraints;
  output Integer omark;
  output list<Integer> oconstraints;
algorithm
  (omark, oconstraints) := matchcontinue(inOrphans, ass1, ass2, m, mt, mark, rowmarks, colummarks, vars, iconstraints)
    local
      list<Integer> rest, constraints, rlst, elst, partner;
      Integer o;
      Boolean foundflow;
      list<Boolean> blst;
      list<BackendDAE.Var> vlst;
    case ({}, _, _, _, _, _, _, _, _, _)
      then
       (mark+2, iconstraints);
    case (o::rest, _, _, _, _, _, _, _, _, _)
      equation
        false = intEq(colummarks[o], mark);
        arrayUpdate(colummarks, o, mark);
        //  print("Process Residual " + intString(o) + "\n");
        rlst = m[o];
        // check for partner
        elst = List.select1(List.flatten(List.map1r(rlst, arrayGet, mt)), intGt, 0);
        //  print("Search for " + intString(o) + " Parnters in: " + stringDelimitList(List.map(elst, intString), ", ") + "\n");
        partner = List.select1(elst, isResOrphan, ass2);
        partner = List.uniqueIntN(List.removeOnTrue(o, intEq, partner), arrayLength(colummarks));
        List.map2_0(partner, doMark, colummarks, mark);
        //  print("Found for " + intString(o) + " Parnters: " + stringDelimitList(List.map(partner, intString), ", ") + "\n");
        //  BackendDump.debuglst((rlst, intString, ", ", "\n"));
        vlst = List.map1r(rlst, BackendVariable.getVarAt, vars);
        blst = List.map(vlst, BackendVariable.isFlowVar);
        foundflow = Util.boolOrList(blst);
        rlst = selectNonFlows(rlst, blst);
        foundflow = generateCliquesResidual1(rlst, ass1, ass2, m, mt, mark, rowmarks, colummarks, foundflow, vars);
        generateCliquesResidual2(rlst, ass1, ass2, m, mt, mark+1, rowmarks, colummarks, o::partner);
        constraints = if not foundflow then listAppend(o::partner, iconstraints) else iconstraints;
        (omark, constraints) = generateCliquesResidual(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, vars, constraints);
      then
       (omark, constraints);
    case (_::rest, _, _, _, _, _, _, _, _, _)
      equation
        (omark, constraints) = generateCliquesResidual(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, vars, iconstraints);
      then
        (omark, constraints);
  end matchcontinue;
end generateCliquesResidual;


protected function generateCliquesResidual1 "author: Frenkel TUD 2012-05"
  input list<Integer> rows;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Boolean ifoundFlow;
  input BackendDAE.Variables vars;
  output Boolean ofoundFlow = ifoundFlow;
protected
  Integer e;
  list<Integer> next, rlst;
  Boolean b1;
  list<Boolean> blst;
  list<BackendDAE.Var> vlst;
algorithm
  for r in rows loop
    if not intEq(rowmarks[r], mark) then
      // remove orphans
      next := List.select1(mt[r], isNoResOrphan, ass2);
      // remove visited
      next := List.select2(next, unmarked, colummarks, mark);
      // remove assigned equation of this row
      next := List.removeOnTrue(ass1[r], intEq, next);
      if listEmpty(next) then
        arrayUpdate(rowmarks, r, mark);
        e := ass1[r];
        // print("Go From " + intString(r) + " to " + intString(e) + "\n");
        arrayUpdate(colummarks, e, mark);
        rlst := ass2[e];
        next := List.fold1(rlst, List.removeOnTrue, intEq, m[e]);
        vlst := List.map1r(next, BackendVariable.getVarAt, vars);
        blst := List.map(vlst, BackendVariable.isFlowVar);
        b1 := Util.boolOrList(blst);
        next := selectNonFlows(next, blst);
        ofoundFlow := generateCliquesResidual1(next, ass1, ass2, m, mt, mark, rowmarks, colummarks, b1 or ofoundFlow, vars);
      end if;
    end if;
  end for;
end generateCliquesResidual1;

protected function selectNonFlows
  input list<Integer> rows;
  input list<Boolean> flowFlag;
  output list<Integer> oAcc = {};
protected
  list<Boolean> brest = flowFlag;
  Boolean b;
algorithm
  for r in rows loop
    b::brest := brest;
    if not b then
      oAcc := r::oAcc;
    end if;
  end for;
end selectNonFlows;

protected function generateCliquesResidual2 "author: Frenkel TUD 2012-05"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input list<Integer> orphan;
algorithm
  _ := match(eqns, ass1, ass2, m, mt, mark, rowmarks, colummarks, orphan)
    local
      Integer e, r;
      list<Integer> rest, lst, rlst, lst1;
    case ({}, _, _, _, _, _, _, _, _)
      then
        ();
    case (r::rest, _, _, _, _, _, _, _, _)
      guard
        not intEq(rowmarks[r], mark)
      equation
        // marked?
        e = ass1[r];
        rlst = ass2[e];
        lst = List.fold1(rlst, List.removeOnTrue, intEq, m[e]);
        (lst1 as _::_) = List.select2(lst, unmarked, rowmarks, mark-1);
        // print("generateClique " + intString(eqn) + " to " + stringDelimitList(List.map(lst1, intString), ", ") + "\n");
        List.map4_0(lst1, generateResidualClique, m, mt, orphan, e);
        List.map2_0(rlst, doMark, rowmarks, mark);
        lst = List.select2(lst, marked, rowmarks, mark-1);
        // print("Go From " + intString(e) + " to " + stringDelimitList(List.map(r, intString), ", ") + "\n");
        arrayUpdate(colummarks, e, mark);
        // print("Go From " + intString(e) + " to " + stringDelimitList(List.map(next, intString), ", ") + "\n");
        generateCliquesResidual2(lst, ass1, ass2, m, mt, mark, rowmarks, colummarks, orphan);
        generateCliquesResidual2(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, orphan);
      then
        ();
    case (_::rest, _, _, _, _, _, _, _, _)
      equation
        generateCliquesResidual2(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, orphan);
      then
        ();
  end match;
end generateCliquesResidual2;

protected function prepairOrphansOrder "author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<list<Integer>> orphans;
  input BackendDAE.Variables vars;
  input list<Integer> iroots;
  input list<Integer> iconstraints;
  output Integer omark;
  output list<Integer> oroots;
  output list<Integer> oconstraints;
algorithm
  (omark, oroots, oconstraints) := match(inOrphans, ass1, ass2, m, mt, mark, rowmarks, colummarks, orphans, vars, iroots, iconstraints)
    local
      list<Integer> rest, roots, constraints, elst, rlst;
      Integer o;
      Boolean foundflow, constr;
      list<Boolean> blst;
      list<BackendDAE.Var> vlst;
    case ({}, _, _, _, _, _, _, _, _, _, _, _)
      then
       (mark, iroots, iconstraints);
    case (o::rest, _, _, _, _, _, _, _, _, _, _, _)
      guard
        not intEq(rowmarks[o], mark)
      equation
        arrayUpdate(rowmarks, o, mark);
        elst = mt[o];
        rlst = List.flatten(List.map1r(elst, arrayGet, ass2));
        // check for partner
        //  BackendDump.debuglst((rlst, intString, ", ", "\n"));
        vlst = List.map1r(rlst, BackendVariable.getVarAt, vars);
        blst = List.map(vlst, BackendVariable.isFlowVar);
        constr = Util.boolAndList(blst);
        constraints = List.consOnTrue(constr, o, iconstraints);
        //  print("Process Orphan " + intString(o) + "\n");
        //  BackendDump.debuglst((mt[o], intString, ", ", "\n"));
        foundflow = prepairOrphansOrder1(mt[o], ass1, ass2, m, mt, mark, rowmarks, colummarks, o, orphans, {o}, false, vars);
        roots = List.consOnTrue(foundflow and not constr, o, iroots);
        (omark, roots, constraints) = prepairOrphansOrder(rest, ass1, ass2, m, mt, mark+1, rowmarks, colummarks, orphans, vars, roots, constraints);
      then
       (omark, roots, constraints);
    case (_::rest, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (omark, roots, constraints) = prepairOrphansOrder(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, orphans, vars, iroots, iconstraints);
      then
        (omark, roots, constraints);
  end match;
end prepairOrphansOrder;

protected function prepairOrphansOrder1 "author: Frenkel TUD 2012-05"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer preorphan;
  input array<list<Integer>> orphans;
  input list<Integer> prer;
  input Boolean ifoundFlow;
  input BackendDAE.Variables vars;
  output Boolean ofoundFlow = ifoundFlow;
protected
  list<Integer> next, r, elst;
  Boolean b1;
  list<Boolean> blst;
  list<BackendDAE.Var> vlst;
algorithm
  for e in eqns loop
    if not intEq(colummarks[e], mark) then
      // remove orphans
      next := List.select1(m[e], isNoOrphan, ass1);
      // remove visited
      next := List.select2(next, unmarked, rowmarks, mark);
      // remove assigned
      next := List.fold1(ass2[e], List.removeOnTrue, intEq, next);
      if listEmpty(next) then
        arrayUpdate(colummarks, e, mark);
        r := ass2[e];
        // print("Go From " + intString(e) + " to " + stringDelimitList(List.map(r, intString), ", ") + "\n");
        List.map2_0(r, doMark, rowmarks, mark);
        elst := List.select1(List.map1r(r, arrayGet, ass1), intGt, 0);
        next := List.flatten(List.map1r(r, arrayGet, mt));
        next := List.fold1(elst, List.removeOnTrue, intEq, next);
        List.map2_0(r, addPreOrphan, preorphan, orphans);
        vlst := List.map1r(r, BackendVariable.getVarAt, vars);
        blst := List.map(vlst, BackendVariable.isFlowVar);
        b1 := Util.boolOrList(blst);
        // print("Go From " + intString(e) + " to " + stringDelimitList(List.map(next, intString), ", ") + "\n");
        ofoundFlow := prepairOrphansOrder1(next, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, orphans, r, b1 or ofoundFlow, vars);
      end if;
    end if;
  end for;
end prepairOrphansOrder1;

protected function prepairOrphansOrder2 "author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer imark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<list<Integer>> orphans;
  output Integer omark;
algorithm
  omark := matchcontinue(inOrphans, ass1, ass2, m, mt, imark, rowmarks, colummarks, orphans)
    local
      list<Integer> rest, elst, rlst, partner;
      Integer o;
    case ({}, _, _, _, _, _, _, _, _)
      then
       imark+1;
    case (o::rest, _, _, _, _, _, _, _, _)
      equation
        false = intEq(rowmarks[o], imark);
        arrayUpdate(rowmarks, o, imark);
        //  print("Process Orphan " + intString(o) + "\n");
        //  BackendDump.debuglst((mt[o], intString, ", ", "\n"));
        // check for partner
        elst = List.select1(mt[o], intGt, 0) "eqns of orphan";
        rlst = List.select1(List.flatten(List.map1r(elst, arrayGet, m)), intGt, 0);
        partner = List.select1(rlst, isOrphan, ass1);
        partner = List.unique(partner);
        List.map2_0(partner, doMark, rowmarks, imark);
        //  print("Found for " + intString(o) + " Parnters: " + stringDelimitList(List.map(partner, intString), ", ") + "\n");
        prepairOrphansOrder3(mt[o], ass1, ass2, m, mt, imark, rowmarks, colummarks, o, partner, orphans, {o});
       then
        prepairOrphansOrder2(rest, ass1, ass2, m, mt, imark, rowmarks, colummarks, orphans);
    case (_::rest, _, _, _, _, _, _, _, _)
      then
        prepairOrphansOrder2(rest, ass1, ass2, m, mt, imark, rowmarks, colummarks, orphans);
  end matchcontinue;
end prepairOrphansOrder2;

protected function prepairOrphansOrder3 "author: Frenkel TUD 2012-05"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer preorphan;
  input list<Integer> partner;
  input array<list<Integer>> orphans;
  input list<Integer> prer;
algorithm
  _ := matchcontinue(eqns, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, partner, orphans, prer)
    local
      Integer e;
      list<Integer> rest, next, r, elst, lst;
    case ({}, _, _, _, _, _, _, _, _, _, _, _)
      then
        ();
    case (e::rest, _, _, _, _, _, _, _, _, _, _, _)
      equation
        false = intEq(colummarks[e], mark);
        // marked?
        r = ass2[e];
        lst = List.unique(List.flatten(List.map1r(r, arrayGet, orphans)));
        true = listMember(preorphan, lst);
        arrayUpdate(colummarks, e, mark);
        // print("Go From " + intString(e) + " to " + stringDelimitList(List.map(r, intString), ", ") + "\n");
        List.map2_0(r, doMark, rowmarks, mark);
        elst = List.select1(List.map1r(r, arrayGet, ass1), intGt, 0);
        next = List.flatten(List.map1r(r, arrayGet, mt));
        next = List.fold1(elst, List.removeOnTrue, intEq, next);
        // print("Go From " + intString(e) + " to " + stringDelimitList(List.map(next, intString), ", ") + "\n");
        prepairOrphansOrder3(next, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, partner, orphans, r);
        prepairOrphansOrder3(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, partner, orphans, prer);
      then
        ();
    case (e::rest, _, _, _, _, _, _, _, _, _, _, _)
      equation
        //  print("check Eqn " + intString(e)  + " ass[e]: " + stringDelimitList(List.map(ass2[e], intString), ", ") + "\n");
        false = intEq(colummarks[e], mark);
        // update Incidence Matrix
        List.map4_0(prer, generateClique, m, mt, partner, e);
        prepairOrphansOrder3(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, partner, orphans, prer);
      then
        ();
    case (_::rest, _, _, _, _, _, _, _, _, _, _, _)
      equation
        prepairOrphansOrder3(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, partner, orphans, prer);
      then
        ();
  end matchcontinue;
end prepairOrphansOrder3;

protected function generateClique
  input Integer r;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input list<Integer> orphans;
  input Integer e;
algorithm
  _:= match(r, m, mt, orphans, e)
    local
      Integer orphan;
      list<Integer> lst, rest;
    case (_, _, _, {}, _) then ();
    case (_, _, _, orphan::rest, _)
      equation
        //  print("Replace " + intString(r) + " with " + intString(orphan) + "\n");
        lst = mt[r];
        // mt[r]-e
        lst = List.removeOnTrue(e, intEq, lst);
        //  print("mt[ " + intString(r) + "]= " + stringDelimitList(List.map(lst, intString), ", ") + "\n");
        arrayUpdate(mt, r, lst);
        // mt[preorphan]+e
        lst = mt[orphan];
        lst = List.unique(e::lst);
        //  print("mt[ " + intString(orphan) + "]= " + stringDelimitList(List.map(lst, intString), ", ") + "\n");
        arrayUpdate(mt, orphan, lst);
        // m[e] - r + preorphan
        lst = m[e];
        lst = List.removeOnTrue(r, intEq, lst);
        lst = List.unique(orphan::lst);
        //  print("m[ " + intString(e) + "]= " + stringDelimitList(List.map(lst, intString), ", ") + "\n");
        arrayUpdate(m, e, lst);
        generateClique(r, m, mt, rest, e);
     then
       ();
  end match;
end generateClique;


protected function generateResidualClique
  input Integer r;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input list<Integer> orphans;
  input Integer e;
algorithm
  _:= match(r, m, mt, orphans, e)
    local
      Integer orphan;
      list<Integer> lst, rest;
    case (_, _, _, {}, _) then ();
    case (_, _, _, orphan::rest, _)
      equation
        //  print("Replace " + intString(e) + " with " + intString(orphan) + "\n");
        lst = m[e];
        // mt[e]-r
        lst = List.removeOnTrue(r, intEq, lst);
        //  print("m[ " + intString(e) + "]= " + stringDelimitList(List.map(lst, intString), ", ") + "\n");
        arrayUpdate(m, e, lst);
        // m[orphan]+r
        lst = m[orphan];
        lst = List.unique(r::lst);
        //  print("m[ " + intString(orphan) + "]= " + stringDelimitList(List.map(lst, intString), ", ") + "\n");
        arrayUpdate(m, orphan, lst);
        // mt[r] - e + orphan
        lst = mt[r];
        lst = List.removeOnTrue(e, intEq, lst);
        lst = List.unique(orphan::lst);
        //  print("mt[ " + intString(r) + "]= " + stringDelimitList(List.map(lst, intString), ", ") + "\n");
        arrayUpdate(mt, r, lst);
        generateResidualClique(r, m, mt, rest, e);
     then
       ();
  end match;
end generateResidualClique;

protected function getOrphansOrderEdvanced "author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input BackendDAE.IncidenceMatrix mc;
  input BackendDAE.IncidenceMatrixT mct;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<list<Integer>> orphans;
  output Integer omark;
algorithm
  omark := matchcontinue(inOrphans, ass1, ass2, m, mt, mc, mct, mark, rowmarks, colummarks, orphans)
    local
      list<Integer> rest;
      Integer o;
    case ({}, _, _, _, _, _, _, _, _, _, _)
      then
       mark;
    case (o::rest, _, _, _, _, _, _, _, _, _, _)
      equation
        false = intEq(rowmarks[o], mark);
        arrayUpdate(rowmarks, o, mark);
        //  print("Process Orphan " + intString(o) + "\n");
        getOrphansOrderEdvanced1(mct[o], ass1, ass2, m, mt, mark, rowmarks, colummarks, o, orphans, {});
      then
        getOrphansOrderEdvanced(rest, ass1, ass2, m, mt, mc, mct, mark+1, rowmarks, colummarks, orphans);
    case (_::rest, _, _, _, _, _, _, _, _, _, _)
      then
        getOrphansOrderEdvanced(rest, ass1, ass2, m, mt, mc, mct, mark, rowmarks, colummarks, orphans);
  end matchcontinue;
end getOrphansOrderEdvanced;

protected function hasOrphanAdvanced "author: Frenkel TUD 2012-07"
  input list<Integer> rows;
  input array<Integer> ass1;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := match(rows, ass1, iAcc)
    local
      list<Integer> rest;
      Integer r;
    case ({}, _, _::_)
      then
        iAcc;
    case (r::rest, _, _)
      then
        if not intGt(ass1[r], 0) then
          hasOrphanAdvanced(rest, ass1, r::iAcc)
        else
          hasOrphanAdvanced(rest, ass1, iAcc);
  end match;
end hasOrphanAdvanced;

protected function addPreOrphan
  input Integer orphan;
  input Integer preorphan;
  input array<list<Integer>> arr;
protected
  list<Integer> olst;
algorithm
  //  print("Add orpan[" + intString(orphan) + "] = " + intString(preorphan) + "\n");
  olst := arr[orphan];
  olst := List.union({preorphan}, olst);
  _:=arrayUpdate(arr, orphan, olst);
end addPreOrphan;

protected function addPreOrphans
  input Integer orphan;
  input list<Integer> preorphans;
  input array<list<Integer>> arr;
protected
  list<Integer> olst;
algorithm
  _:=match(orphan, preorphans, arr)
    local
      Integer o;
      list<Integer> rest;
    case(_, {}, _) then ();
    case(_, o::rest, _)
      equation
        addPreOrphan(orphan, o, arr);
        addPreOrphans(orphan, rest, arr);
      then
        ();
  end match;
end addPreOrphans;

protected function getOrphansOrderEdvanced1 "author: Frenkel TUD 2012-07"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer preorphan;
  input array<list<Integer>> orphans;
  input list<Integer> nextQueue;
algorithm
  _ := matchcontinue(eqns, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, orphans, nextQueue)
    local
      Integer e;
      list<Integer> rest, next, r, r1, elst, olst;
    case ({}, _, _, _, _, _, _, _, _, _, {})
      then
        ();
    case ({}, _, _, _, _, _, _, _, _, _, _)
      equation
        getOrphansOrderEdvanced1(nextQueue, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, orphans, {});
      then
        ();
    case (e::_, _, _, _, _, _, _, _, _, _, _)
      equation
        // print("Check Eqn: " + intString(e) + "\n");
        false = intEq(colummarks[e], mark);
        r = List.removeOnTrue(preorphan, intEq, m[e]) "vars of equation without preorphan";
        //  print("search in " + stringDelimitList(List.map(r, intString), ", ") + "\n");
        olst = hasOrphanAdvanced(r, ass1, {});
        arrayUpdate(colummarks, e, mark);
        //  print("Found Orphans " + stringDelimitList(List.map(olst, intString), ", ") + " ChildOrphan is " + intString(preorphan) + "\n");
        addPreOrphans(preorphan, olst, orphans);
      then
        ();
    case (e::rest, _, _, _, _, _, _, _, _, _, _)
      equation
        false = intEq(colummarks[e], mark);
        r = List.removeOnTrue(preorphan, intEq, m[e]) "vars of equation";
        r1 = List.select1(ass2[e], intGt, 0) "vars assignt with equation";
        r = List.fold1(r1, List.removeOnTrue, intEq, r) "needed vars of equation";
        elst = List.select1(List.map1r(r, arrayGet, ass1), intGt, 0) "equations assigned with needed vars";
        next = listAppend(nextQueue, elst);
        arrayUpdate(colummarks, e, mark);
        //  print("goto " + stringDelimitList(List.map(next, intString), ", ") + "\n");
        getOrphansOrderEdvanced1(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, orphans, next);
      then
        ();
    case (_::rest, _, _, _, _, _, _, _, _, _, _)
      equation
        getOrphansOrderEdvanced1(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, orphans, nextQueue);
      then
       ();
  end matchcontinue;
end getOrphansOrderEdvanced1;


protected function getConstraintesOrphansOrderEdvanced "author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input BackendDAE.IncidenceMatrix mc;
  input BackendDAE.IncidenceMatrixT mct;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<list<Integer>> orphans;
  output Integer omark;
algorithm
  omark := matchcontinue(inOrphans, ass1, ass2, m, mt, mc, mct, mark, rowmarks, colummarks, orphans)
    local
      list<Integer> rest;
      Integer o;
    case ({}, _, _, _, _, _, _, _, _, _, _)
      then
       mark;
    case (o::rest, _, _, _, _, _, _, _, _, _, _)
      equation
        false = intEq(rowmarks[o], mark);
        arrayUpdate(rowmarks, o, mark);
        //  print("Process Orphan " + intString(o) + "\n");
        getConstraintesOrphansOrderEdvanced1(mct[o], ass1, ass2, m, mt, mark, rowmarks, colummarks, o, orphans, {});
      then
        getConstraintesOrphansOrderEdvanced(rest, ass1, ass2, m, mt, mc, mct, mark+1, rowmarks, colummarks, orphans);
    case (_::rest, _, _, _, _, _, _, _, _, _, _)
      then
        getConstraintesOrphansOrderEdvanced(rest, ass1, ass2, m, mt, mc, mct, mark, rowmarks, colummarks, orphans);
  end matchcontinue;
end getConstraintesOrphansOrderEdvanced;

protected function getConstraintesOrphansOrderEdvanced1 "author: Frenkel TUD 2012-07"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer preorphan;
  input array<list<Integer>> orphans;
  input list<Integer> nextQueue;
algorithm
  _ := matchcontinue(eqns, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, orphans, nextQueue)
    local
      Integer e;
      list<Integer> rest, next, r, r1, elst, olst;
    case ({}, _, _, _, _, _, _, _, _, _, {})
      then
        ();
    case ({}, _, _, _, _, _, _, _, _, _, _)
      equation
        getConstraintesOrphansOrderEdvanced1(nextQueue, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, orphans, {});
      then
        ();
    case (e::rest, _, _, _, _, _, _, _, _, _, _)
      equation
        // print("Check Eqn: " + intString(e) + "\n");
        false = intEq(colummarks[e], mark);
        r = List.removeOnTrue(preorphan, intEq, m[e]) "vars of equation without preorphan";
        //  print("search in " + stringDelimitList(List.map(r, intString), ", ") + "\n");
        olst = hasOrphanAdvanced(r, ass1, {});
        arrayUpdate(colummarks, e, mark);
        //  print("Found Orphans " + stringDelimitList(List.map(olst, intString), ", ") + " ChildOrphan is " + intString(preorphan) + "\n");
        addPreOrphans(preorphan, olst, orphans);
        r1 = ass2[e] "vars assignt with equation";
        r = List.fold1(r1, List.removeOnTrue, intEq, r) "needed vars of equation";
        elst = List.select1(List.map1r(r, arrayGet, ass1), intGt, 0) "equations assigned with needed vars";
        next = listAppend(nextQueue, elst);
        getConstraintesOrphansOrderEdvanced1(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, orphans, next);
      then
        ();
    case (e::rest, _, _, _, _, _, _, _, _, _, _)
      equation
        false = intEq(colummarks[e], mark);
        r = List.removeOnTrue(preorphan, intEq, m[e]) "vars of equation";
        r1 = ass2[e] "vars assignt with equation";
        r = List.fold1(r1, List.removeOnTrue, intEq, r) "needed vars of equation";
        elst = List.select1(List.map1r(r, arrayGet, ass1), intGt, 0) "equations assigned with needed vars";
        next = listAppend(nextQueue, elst);
        arrayUpdate(colummarks, e, mark);
        //  print("goto " + stringDelimitList(List.map(next, intString), ", ") + "\n");
        getConstraintesOrphansOrderEdvanced1(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, orphans, next);
      then
        ();
    case (_::rest, _, _, _, _, _, _, _, _, _, _)
      equation
        getConstraintesOrphansOrderEdvanced1(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, preorphan, orphans, nextQueue);
      then
       ();
  end matchcontinue;
end getConstraintesOrphansOrderEdvanced1;

protected function mergeOrphanParents
  input list<Integer> links;
  input array<List<Integer>> m;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := matchcontinue(links, m, iAcc)
    local
      Integer l;
      list<Integer> rest, lst;
    case({}, _, _) then iAcc;
    case(l::rest, _, _)
      equation
        {} = m[l];
      then
        mergeOrphanParents(rest, m, iAcc);
    case(l::rest, _, _)
      equation
        lst = m[l];
      then
        mergeOrphanParents(rest, m, listAppend(lst, iAcc));
  end matchcontinue;
end mergeOrphanParents;

protected function getLinkPosition
  input list<Integer> orphans;
  input array<List<Integer>> m;
  input array<List<Integer>> mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input list<Integer> iAcc;
  output list<Integer> ochilds;
algorithm
  ochilds := matchcontinue(orphans, m, mt, mark, rowmarks, iAcc)
    local
      Integer o;
      list<Integer> rest, childs;
    case({}, _, _, _, _, _) then iAcc;
    case(o::rest, _, _, _, _, _)
      equation
        false = intEq(rowmarks[o], mark);
        arrayUpdate(rowmarks, o, mark);
        childs = getLinkPosition1(m[o], m, mt, mark, rowmarks, o, iAcc);
      then
        getLinkPosition(rest, m, mt, mark, rowmarks, childs);
    case(_::rest, _, _, _, _, _)
      then
        getLinkPosition(rest, m, mt, mark, rowmarks, iAcc);
  end matchcontinue;
end getLinkPosition;

protected function getLinkPosition1
  input list<Integer> orphans;
  input array<List<Integer>> m;
  input array<List<Integer>> mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input Integer preorphan;
  input list<Integer> iAcc;
  output list<Integer> childs;
algorithm
  childs := matchcontinue(orphans, m, mt, mark, rowmarks, preorphan, iAcc)
    local
      Integer o;
      list<Integer> lst;
    case({}, _, _, _, _, _, _) then preorphan::iAcc;
    case(o::{}, _, _, _, _, _, _)
      equation
        false = intEq(rowmarks[o], mark);
        arrayUpdate(rowmarks, o, mark);
      then
        getLinkPosition1(m[o], m, mt, mark, rowmarks, o, iAcc);
    case(o::{}, _, _, _, _, _, _)
      equation
        true = intEq(rowmarks[o], mark);
        lst = listAppend(mt[0], iAcc);
      then
        lst;
    case(_, _, _, _, _, _, _)
      equation
        print("Error in getLinkPosition1! Found Orphan with more than one parents " + stringDelimitList(List.map(orphans, intString), ", ") + "\n");
      then
        fail();
  end matchcontinue;
end getLinkPosition1;

protected function getOrphansOrderEdvanced5
  input list<list<Integer>> linklst;
  input array<List<Integer>> m;
  input array<List<Integer>> mt;
  input Integer imark;
  input array<Integer> rowmarks;
  input list<list<Integer>> iAcc;
  output list<list<Integer>> oAcc;
  output Integer omark;
algorithm
  (oAcc, omark) := match(linklst, m, mt, imark, rowmarks, iAcc)
    local
      Integer mark;
      list<Integer> links, lst, childs;
      list<list<Integer>> rest, acc;
    case({}, _, _, _, _, _)
      then
        (listReverse(iAcc), imark);
    case(links::rest, _, _, _, _, _)
      equation
        lst = mergeOrphanParents(links, m, {});
        childs = getLinkPosition(lst, m, mt, imark, rowmarks, {});
        //  print("Found for links " + stringDelimitList(List.map(links, intString), ", ") + " childs " + stringDelimitList(List.map(childs, intString), ", ") + "\n");
        (acc, mark) = getOrphansOrderEdvanced5(rest, m, mt, imark+1, rowmarks, childs::iAcc);
      then
        (acc, mark);
  end match;
end getOrphansOrderEdvanced5;

protected function getOrphansOrderEdvanced6
  input list<list<Integer>> linklst;
  input list<list<Integer>> childslst;
  input array<List<Integer>> m;
algorithm
  _ := match(linklst, childslst, m)
    local
      list<Integer> links, lst, childs;
      list<list<Integer>> rest, acc;
    case({}, _, _)
      then
        ();
    case(links::rest, childs::acc, _)
      equation
        lst = List.unique(List.flatten(List.map1r(childs, arrayGet, m)));
        List.map2_0(links, doAssign, m, lst);
        List.map2_0(childs, doAssign, m, links);
        getOrphansOrderEdvanced6(rest, acc, m);
      then
        ();
  end match;
end getOrphansOrderEdvanced6;

protected function getOrphansOrderEdvanced4
  input list<list<Integer>> linklst;
  input array<List<Integer>> m;
  input array<List<Integer>> mt;
  input Integer imark;
  input array<Integer> rowmarks;
  input list<Integer> iorder;
  input list<Integer> iAcc;
  output Integer omark;
protected
  list<list<Integer>> childs;
algorithm
  (childs, omark) := getOrphansOrderEdvanced5(linklst, m, mt, imark, rowmarks, {});
  getOrphansOrderEdvanced6(linklst, childs, m);
end getOrphansOrderEdvanced4;


protected function getInvMap
  input Integer orphan;
  input array<Integer> invmap;
  input Integer index;
  output Integer oindex;
algorithm
  _:=arrayUpdate(invmap, orphan, index);
  oindex := index+1;
end getInvMap;

protected function getOrphansIncidenceMatrix
  input list<Integer> orphans;
  input array<Integer> invmap;
  input array<list<Integer>> vorphansarray;
  input list<list<Integer>> m;
  input array<list<Integer>> mT;
  input Boolean addself;
  output array<list<Integer>> outM;
  output array<list<Integer>> outMT;
algorithm
  (outM, outMT) := match(orphans, invmap, vorphansarray, m, mT, addself)
    local
      Integer o, i;
      list<Integer> rest, lst;
      array<list<Integer>> am, amT;
    case ({}, _, _, _, _, _)
      then
        (listArray(listReverse(m)), mT);
    case (o::rest, _, _, _, _, _)
      equation
        //  print("getOrphansIncidenceMatrix for " + intString(o) + "\n");
        lst = List.map1r(vorphansarray[o], arrayGet, invmap);
        i = invmap[o];
        lst = List.consOnTrue(addself, i, lst);
        amT = List.fold1(lst, Array.consToElement, i, mT);
        (am, amT) = getOrphansIncidenceMatrix(rest, invmap, vorphansarray, lst::m, amT, addself);
      then
        (am, amT);
  end match;
end getOrphansIncidenceMatrix;

protected function getOrder
  input list<Integer> comp;
  input tuple<list<Integer>, list<list<Integer>>> inorder;
  output tuple<list<Integer>, list<list<Integer>>> outorder;
algorithm
  outorder := match(comp, inorder)
    local
      Integer o;
      list<Integer> order;
      list<list<Integer>> links;
    case (o::{}, (order, links)) then ((o::order, links));
    case (_, (order, links)) then ((order, comp::links));
  end match;
end getOrder;

protected function getOrphansOrderEdvanced3
  input list<Integer> roots;
  input list<Integer> otherorphans;
  input list<Integer> constraints;
  input list<Integer> vorphans;
  input array<list<Integer>> vorphansarray;
  input Integer mark;
  input array<Integer> rowmarks;
  output list<Integer> sortvorphans;
  output Integer omark;
protected
  list<Integer> order, leafs;
  list<tuple<Integer, list<Integer>>> childlist;
  Integer size;
  array<Integer> map, ass, invmap;
  array<List<Integer>> m, mt;
  list<Integer> range, links;
  list<list<Integer>> comps, linkslst;
algorithm
  // get strong connected parts
  map := listArray(vorphans);
  size := arrayLength(map);
  //  print("map\n");
  //  BackendDump.dumpMatching(map);
  invmap := arrayCreate(arrayLength(vorphansarray), 0);
  _ := List.fold1(vorphans, getInvMap, invmap, 1);
  //  print("invmap\n");
  //  BackendDump.dumpMatching(invmap);
  range := List.intRange(size);
  (m, mt) := getOrphansIncidenceMatrix(vorphans, invmap, vorphansarray, {}, arrayCreate(size, {}), true);
  //  BackendDump.dumpIncidenceMatrix(m);
  //  BackendDump.dumpIncidenceMatrixT(mt);
  ass := listArray(range);
  comps := Sorting.TarjanTransposed(mt, ass);
  //  BackendDump.dumpComponentsOLD(comps);
  ((order, linkslst)) := List.fold(comps, getOrder, ({}, {}));
  //  print("order: " + stringDelimitList(List.map(order, intString), ", ") + "\n");
  //  print("Links\n");
  //  BackendDump.dumpComponentsOLD(linkslst);
  (m, mt) := getOrphansIncidenceMatrix(vorphans, invmap, vorphansarray, {}, arrayCreate(size, {}), false);
  //  BackendDump.dumpIncidenceMatrix(m);
  //  BackendDump.dumpIncidenceMatrixT(mt);
  reduceOrphancMatrix(listReverse(comps), m);
  //  BackendDump.dumpIncidenceMatrix(m);
  // add links to the order
  omark := getOrphansOrderEdvanced4(linkslst, m, mt, mark, rowmarks, order, {});
  //  BackendDump.dumpIncidenceMatrix(m);
  mt := BackendDAEUtil.transposeMatrix(m, arrayLength(mt));
  comps := Sorting.TarjanTransposed(mt, ass);
  //  BackendDump.dumpComponentsOLD(comps);
  sortvorphans := List.flatten(listReverse(comps));
  // map back to global indexes
  sortvorphans := List.map1r(sortvorphans, arrayGet, map);
  //  print("sortvorphans: " + stringDelimitList(List.map(sortvorphans, intString), ", ") + "\n");
end getOrphansOrderEdvanced3;

protected function reduceOrphancMatrix
  input list<list<Integer>> comps;
  input array<list<Integer>> m;
algorithm
  _ := match(comps, m)
    local
      Integer c;
      list<Integer> comp;
      list<list<Integer>> rest;
    case({}, _) then ();
    case((_::{})::rest, _)
      equation
        reduceOrphancMatrix(rest, m);
      then
        ();
    case(comp::rest, _)
      equation
        reduceOrphancMatrix1(comp, comp, m);
        reduceOrphancMatrix(rest, m);
      then
        ();
  end match;
end reduceOrphancMatrix;

protected function reduceOrphancMatrix1
  input list<Integer> comps;
  input list<Integer> comps1;
  input array<list<Integer>> m;
algorithm
  _ := match(comps, comps1, m)
    local
      Integer c;
      list<Integer> rest, lst;
    case({}, _, _) then ();
    case(c::rest, _, _)
      equation
        lst = m[c];
        lst = List.setDifference(lst, comps1);
        arrayUpdate(m, c, listReverse(lst)) "reverse the list to traveres from the nearest to the farest orphan";
        reduceOrphancMatrix1(rest, comps1, m);
      then
        ();
  end match;
end reduceOrphancMatrix1;

protected function hasResidualOrphan1 "author: Frenkel TUD 2012-07"
  input list<Integer> eqns;
  input array<list<Integer>> ass;
  input BackendDAE.EquationArray eqnsarr;
  output Integer Orphan;
algorithm
  Orphan := matchcontinue(eqns, ass, eqnsarr)
    local
      list<Integer> rest;
      Integer e, len, size;
    case (e::_, _, _)
      equation
        len = listLength(ass[e]);
        size = BackendEquation.equationSize(BackendEquation.equationNth1(eqnsarr, e));
        true = intLt(len, size);
      then
        e;
    case (_::rest, _, _)
      then
        hasResidualOrphan1(rest, ass, eqnsarr);
  end matchcontinue;
end hasResidualOrphan1;

protected function hasResidualOrphan "author: Frenkel TUD 2012-07"
  input list<Integer> eqns;
  input array<list<Integer>> ass;
  output Integer Orphan;
algorithm
  Orphan := matchcontinue(eqns, ass)
    local
      list<Integer> rest;
      Integer e;
    case (e::_, _)
      equation
        {} = ass[e];
      then
        e;
    case (_::rest, _)
      then
        hasResidualOrphan(rest, ass);
  end matchcontinue;
end hasResidualOrphan;

protected function makeCrefExps "author: Frenkel TUD 2012-05"
  input BackendDAE.Var v;
  output DAE.Exp e;
algorithm
  e := Expression.crefExp(BackendVariable.varCref(v));
end makeCrefExps;

protected function makeGausEliminationRow "author: Frenkel TUD 2012-05"
  input list<tuple<Integer, DAE.Exp>> lst;
  input Integer size;
  input array<DAE.Exp> vars;
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output DAE.Exp outExp1;
algorithm
  (outExp, outExp1) := matchcontinue(lst, size, vars, inExp)
    local
      Integer c;
      DAE.Exp e, e1, b;
      list<tuple<Integer, DAE.Exp>> rest;
    case ({}, _, _, _)
      then
        (inExp, DAE.RCONST(0.0));
    case ((c, e)::_, _, _, _)
      equation
        true = intGt(c, size);
      then
        (inExp, e);
    case ((c, e)::rest, _, _, _)
      equation
        e1 = Expression.expMul(e, vars[c]);
        e1 = Expression.expAdd(e1, inExp);
        //  BackendDump.debugStrExpStrExpStr(("", inExp, " => ", e1, "\n"));
        (e1, b) = makeGausEliminationRow(rest, size, vars, e1);
      then
        (e1, b);
  end matchcontinue;
end makeGausEliminationRow;

protected function makeGausElimination "author: Frenkel TUD 2012-05"
  input Integer row;
  input Integer size;
  input array<list<tuple<Integer, DAE.Exp>>> matrix;
  input array<DAE.Exp> vars;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> oAcc;
algorithm
  oAcc := matchcontinue(row, size, matrix, vars, iAcc)
    local
      DAE.Exp e, b;
      BackendDAE.Equation eqn;
    case (_, _, _, _, _)
      equation
        true = intGt(row, size);
      then
        listReverse(iAcc);
    case (_, _, _, _, _)
      equation
        (e, b) = makeGausEliminationRow(matrix[row], size, vars, DAE.RCONST(0.0));
        //(e, _) = ExpressionSimplify.simplify(e);
        //(b, _) = ExpressionSimplify.simplify(b);
        //  BackendDump.debugStrExpStrExpStr(("", e, " = ", b, "\n"));
        eqn = BackendDAE.EQUATION(e, b, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
      then
        makeGausElimination(row+1, size, matrix, vars, eqn::iAcc);
  end matchcontinue;
end makeGausElimination;

protected function dumpMatrix "author: Frenkel TUD 2012-05"
  input Integer row;
  input Integer size;
  input array<list<tuple<Integer, DAE.Exp>>> matrix;
algorithm
  _ := matchcontinue(row, size, matrix)
    case (_, _, _) equation
      true = intGt(row, size);
    then ();

    case (_, _, _) equation
      print(intString(row) + ": ");
      BackendDump.debuglst(matrix[row], dumpMatrix1, ", ", "\n");
      dumpMatrix(row+1, size, matrix);
    then ();
  end matchcontinue;
end dumpMatrix;

protected function dumpMatrix1 "author: Frenkel TUD 2012-05"
  input tuple<Integer, DAE.Exp> inTpl;
  output String s;
protected
  Integer c;
  DAE.Exp e;
  String cs, es;
algorithm
  (c, e) := inTpl;
  cs := intString(c);
  es := ExpressionDump.printExpStr(e);
  s := stringAppendList({cs, ":", es});
end dumpMatrix1;

protected function addRows "author: Frenkel TUD 2012-05"
  input list<tuple<Integer, DAE.Exp>> inA;
  input list<tuple<Integer, DAE.Exp>> inB;
  input Integer col;
  input BackendDAE.Variables inVars "temporary variables";
  input BackendDAE.EquationArray inEqns "temporary equations";
  input tuple<Integer, Integer> inTpl;
  input list<tuple<Integer, DAE.Exp>> inElst;
  output list<tuple<Integer, DAE.Exp>> outElst;
  output BackendDAE.Variables outVars "temporary variables";
  output BackendDAE.EquationArray outEqns "temporary equations";
  output tuple<Integer, Integer> outTpl;
algorithm
  (outElst, outVars, outEqns, outTpl) := matchcontinue(inA, inB, col, inVars, inEqns, inTpl, inElst)
    local
      Integer ca, cb;
      DAE.Exp ea, eb, e;
      list<tuple<Integer, DAE.Exp>> resta, restb, elst;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      tuple<Integer, Integer> tpl;
    case ({}, {}, _, _, _, _, _)
      then
        (listReverse(inElst), inVars, inEqns, inTpl);
    case ({}, _, _, _, _, _, _)
      then
        (List.append_reverse(inElst, inB), inVars, inEqns, inTpl);
    case (_, {}, _, _, _, _, _)
      then
        (List.append_reverse(inElst, inA), inVars, inEqns, inTpl);
    case ((ca, _)::resta, (cb, _)::restb, _, _, _, _, _)
      equation
        true = intEq(ca, cb);
        true = intEq(ca, col);
        (elst, vars, eqns, tpl) = addRows(resta, restb, col, inVars, inEqns, inTpl, inElst);
      then
        (elst, vars, eqns, tpl);
    case ((ca, ea)::resta, (cb, eb)::restb, _, _, _, _, _)
      equation
        true = intEq(ca, cb);
        e = Expression.expAdd(ea, eb);
        (e, _) = ExpressionSimplify.simplify(e);
        (vars, eqns, e, tpl) = makeDummyVar(inTpl, e, inVars, inEqns);
        (elst, vars, eqns, tpl) = addRows(resta, restb, col, vars, eqns, tpl, (ca, e)::inElst);
      then
        (elst, vars, eqns, tpl);
    case ((ca, _)::_, (cb, _)::restb, _, _, _, _, _)
      equation
        true = intGt(ca, cb);
        true = intEq(cb, col);
        (elst, vars, eqns, tpl) = addRows(inA, restb, col, inVars, inEqns, inTpl, inElst);
      then
        (elst, vars, eqns, tpl);
    case ((ca, _)::_, (cb, eb)::restb, _, _, _, _, _)
      equation
        true = intGt(ca, cb);
        (elst, vars, eqns, tpl) = addRows(inA, restb, col, inVars, inEqns, inTpl, (cb, eb)::inElst);
      then
        (elst, vars, eqns, tpl);
    case ((ca, _)::resta, (cb, _)::_, _, _, _, _, _)
      equation
        true = intLt(ca, cb);
        true = intEq(ca, col);
        (elst, vars, eqns, tpl) = addRows(resta, inB, col, inVars, inEqns, inTpl, inElst);
      then
        (elst, vars, eqns, tpl);
    case ((ca, ea)::resta, (cb, _)::_, _, _, _, _, _)
      equation
        true = intLt(ca, cb);
        (elst, vars, eqns, tpl) = addRows(resta, inB, col, inVars, inEqns, inTpl, (ca, ea)::inElst);
      then
        (elst, vars, eqns, tpl);
  end matchcontinue;
end addRows;

protected function mulRow "author: Frenkel TUD 2012-05"
  input tuple<Integer, DAE.Exp> inTpl;
  input DAE.Exp e1;
  output tuple<Integer, DAE.Exp> outTpl;
protected
  DAE.Exp e;
  Integer c;
algorithm
  (c, e) := inTpl;
  e := Expression.negate(Expression.expMul(e, e1));
  //(e, _) := ExpressionSimplify.simplify(e);
  outTpl := (c, e);
end mulRow;

protected function removeFromCol "author: Frenkel TUD 2012-05"
  input Integer i;
  input list<tuple<Integer, DAE.Exp>> inTpl;
  input list<tuple<Integer, DAE.Exp>> inAcc;
  output list<tuple<Integer, DAE.Exp>> outAcc;
algorithm
  outAcc := match(i, inTpl, inAcc)
    local
      DAE.Exp e;
      Integer c;
      list<tuple<Integer, DAE.Exp>> rest, acc;
      case (_, {}, _)
        then
          listReverse(inAcc);
      case (_, (c, _)::rest, _)
        guard
          intEq(i, c)
        equation
          acc = listReverse(inAcc);
          acc = listAppend(acc, rest);
        then
          acc;
      case (_, (c, e)::rest, _)
        then
          removeFromCol(i, rest, (c, e)::inAcc);
  end match;
end removeFromCol;

protected function makeDummyVar "author: Frenkel TUD 2012-05"
  input tuple<Integer, Integer> inTpl;
  input DAE.Exp e;
  input BackendDAE.Variables inVars "temporary variables";
  input BackendDAE.EquationArray inEqns "temporary equations";
  output BackendDAE.Variables outVars "temporary variables";
  output BackendDAE.EquationArray outEqns "temporary equations";
  output DAE.Exp outExp;
  output tuple<Integer, Integer> outTpl;
algorithm
  (outVars, outEqns, outExp, outTpl) := matchcontinue(inTpl, e, inVars, inEqns)
    local
      DAE.ComponentRef cr;
      BackendDAE.Var v;
      String sa, sb;
      Integer a, b;
      BackendDAE.EquationArray eqns;
      BackendDAE.Variables vars;
      DAE.Exp cexp;
    case (_, DAE.CREF(), _, _)
      then
        (inVars, inEqns, e, inTpl);
    case (_, DAE.UNARY(exp=DAE.CREF()), _, _)
      then
        (inVars, inEqns, e, inTpl);
    case (_, DAE.RCONST(), _, _)
      then
        (inVars, inEqns, e, inTpl);
    case (_, _, _, _)
      equation
        true = Expression.isConst(e);
      then
        (inVars, inEqns, e, inTpl);
    case((a, b), _, _, _)
      equation
      sa = intString(a);
      sb = intString(b);
      cr = ComponentReference.makeCrefIdent(stringAppendList({"$tmp", sa, "_", sb}), DAE.T_REAL_DEFAULT, {});
      cexp = Expression.crefExp(cr);
      eqns = BackendEquation.addEquation(BackendDAE.EQUATION(cexp, e, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN), inEqns);
      v = BackendDAE.VAR(cr, BackendDAE.VARIABLE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), false);
      vars = BackendVariable.addVar(v, inVars);
    then
      (vars, eqns, cexp, (a, b+1));
  end matchcontinue;
end makeDummyVar;

protected function gaussElimination1 "author: Frenkel TUD 2012-05"
  input Integer col;
  input Integer row;
  input Integer size;
  input DAE.Exp ce;
  input array<list<tuple<Integer, DAE.Exp>>> matrix;
  input BackendDAE.Variables inVars "temporary variables";
  input BackendDAE.EquationArray inEqns "temporary equations";
  input tuple<Integer, Integer> inTpl;
  output BackendDAE.Variables outVars "temporary variables";
  output BackendDAE.EquationArray outEqns "temporary equations";
  output tuple<Integer, Integer> outTpl;
algorithm
  (outVars, outEqns, outTpl) := matchcontinue (col, row, size, ce, matrix, inVars, inEqns, inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      DAE.Exp e, e1, cexp;
      list<tuple<Integer, DAE.Exp>> elst;
       tuple<Integer, Integer> tpl;
    case (_, _, _, _, _, _, _, _)
      equation
        true = intGt(row, size);
      then
        (inVars, inEqns, inTpl);
    case(_, _, _, _, _, _, _, _)
      equation
        SOME(e) = diagonalEntry(col, matrix[row]);
        //  print("Found entriy in " + intString(row) + "\n");
        //  BackendDump.debuglst((matrix[row], dumpMatrix1, ", ", "\n"));
        e1 = Expression.expDiv(e, ce);
        (e1, _) = ExpressionSimplify.simplify(e1);
        (vars, eqns, cexp, tpl) = makeDummyVar(inTpl, e1, inVars, inEqns);
        elst = matrix[col];
        elst = List.map1(elst, mulRow, cexp);
        //  print("mulRow " + intString(col) + " with " + ExpressionDump.printExpStr(e1) + "\n");
        //  BackendDump.debuglst((elst, dumpMatrix1, ", ", "\n"));
        (elst, vars, eqns, tpl) = addRows(matrix[row], elst, col, vars, eqns, tpl, {});
        //  print("addRow\n");
        //  BackendDump.debuglst((elst, dumpMatrix1, ", ", "\n"));
        //elst = removeFromCol(col, elst, {});
        arrayUpdate(matrix, row, elst);
        (vars, eqns, tpl) = gaussElimination1(col, row+1, size, ce, matrix, vars, eqns, tpl);
      then
        (vars, eqns, tpl);
    case(_, _, _, _, _, _, _, _)
      equation
        (vars, eqns, tpl) = gaussElimination1(col, row+1, size, ce, matrix, inVars, inEqns, inTpl);
      then
        (vars, eqns, tpl);
  end matchcontinue;
end gaussElimination1;

protected function gaussElimination "author: Frenkel TUD 2012-05"
  input Integer col;
  input Integer size;
  input array<list<tuple<Integer, DAE.Exp>>> matrix;
  input BackendDAE.Variables inVars "temporary variables";
  input BackendDAE.EquationArray inEqns "temporary equations";
  input tuple<Integer, Integer> inTpl;
  output BackendDAE.Variables outVars "temporary variables";
  output BackendDAE.EquationArray outEqns "temporary equations";
algorithm
  (outVars, outEqns) := matchcontinue (col, size, matrix, inVars, inEqns, inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      DAE.Exp e;
      tuple<Integer, Integer> tpl;
    case (_, _, _, _, _, _)
      equation
        true = intGt(col, size);
      then
        (inVars, inEqns);
    case(_, _, _, _, _, _)
      equation
        SOME(e) = diagonalEntry(col, matrix[col]);
        //  print("Jacobian as Matrix " + intString(col) + "\n");
        //  BackendDump.debuglst((matrix[col], dumpMatrix1, ", ", "\n"));
        (vars, eqns, tpl) = gaussElimination1(col, col+1, size, e, matrix, inVars, inEqns, inTpl);
        //  dumpMatrix(1, size, matrix);
        (vars, eqns) = gaussElimination(col+1, size, matrix, vars, eqns, tpl);
      then
        (vars, eqns);
    case(_, _, _, _, _, _)
      equation
        NONE() = diagonalEntry(col, matrix[col]);
        print("gaussElimination failt because of non diagonal Entry for col " + intString(col) + "\n");
      then
        fail();
  end matchcontinue;
end gaussElimination;

protected function diagonalEntry "author: Frenkel TUD
  check if row has an entry col, if not then it fails"
  input Integer col;
  input list<tuple<Integer, DAE.Exp>> row;
  output Option<DAE.Exp> oe;
algorithm
  oe := match(col, row)
    local
      list<tuple<Integer, DAE.Exp>> rest;
      Integer r;
      DAE.Exp e;
    case (_, (r, e)::rest)
      then
        if intEq(r, col) and not Expression.isZero(e) then
          SOME(e)
        else if intGt(r, col) then
          NONE()
        else
          diagonalEntry(col, rest);
  end match;
end diagonalEntry;

protected function isConstOneMinusOne "author: Frenkel TUD
  return true if inExp is 1 or -1"
  input DAE.Exp inExp;
  output Boolean b;
algorithm
  b := Expression.isConstOne(inExp) or Expression.isConstMinusOne(inExp);
end isConstOneMinusOne;


protected function transformJacToIncidenceMatrix2 "author: Frenkel TUD
  transforms only array equations"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> mapIncRowEqn;
  input BackendDAE.EquationArray eqns;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input CompareFunc func;
  partial function CompareFunc
    input DAE.Exp inExp;
    output Boolean outBool;
  end CompareFunc;
algorithm
 _ := match(jac, m, mapIncRowEqn, eqns, ass1, ass2, func)
    local
      Integer c, r, i;
      DAE.Exp e;
      Boolean b, b1;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      list<Integer> lst;
      BackendDAE.Equation eqn;
    case ({}, _, _, _, _, _, _)
      then ();
    case ((r, c, BackendDAE.RESIDUAL_EQUATION(exp = e))::rest, _, _, _, _, _, _)
      equation
        i = mapIncRowEqn[r];
        eqn = BackendEquation.equationNth1(eqns, i);
        b1 = BackendEquation.isArrayEquation(eqn);
        b = func(e);
        lst = List.consOnTrue(b and b1, c, m[r]);
        arrayUpdate(m, r, lst);
        transformJacToIncidenceMatrix2(rest, m, mapIncRowEqn, eqns, ass1, ass2, func);
      then
        ();
   end match;
end transformJacToIncidenceMatrix2;

protected function transformJacToIncidenceMatrix1 "author: Frenkel TUD
  transforms only not assigned equations"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input CompareFunc func;
  partial function CompareFunc
    input DAE.Exp inExp;
    output Boolean outBool;
  end CompareFunc;
algorithm
 _ := match(jac, m, ass1, ass2, func)
    local
      Integer c, r;
      DAE.Exp e;
      Boolean b, b1;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      list<Integer> lst;
    case ({}, _, _, _, _)
      then ();
    case ((r, c, BackendDAE.RESIDUAL_EQUATION(exp=e))::rest, _, _, _, _)
      equation
        b1 = intLt(ass1[c], 1);
        b = func(e);
        lst = List.consOnTrue(b and b1, c, m[r]);
        arrayUpdate(m, r, lst);
        transformJacToIncidenceMatrix1(rest, m, ass1, ass2, func);
      then ();
   end match;
end transformJacToIncidenceMatrix1;

protected function transformJacToIncidenceMatrix "author: Frenkel TUD"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input CompareFunc func;
  partial function CompareFunc
    input DAE.Exp inExp;
    output Boolean outBool;
  end CompareFunc;
algorithm
 _ := match(jac, m, mT, func)
    local
      Integer c, r;
      DAE.Exp e;
      Boolean b;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      list<Integer> lst, lst1;
    case ({}, _, _, _)
      equation
        transformJacToIncidenceMatrix(jac, m, mT, func);
      then ();
    case ((r, c, BackendDAE.RESIDUAL_EQUATION(exp = e))::rest, _, _, _)
      equation
        b = func(e);
        lst = List.consOnTrue(b, c, m[r]);
        lst1 = List.consOnTrue(b, r, mT[c]);
        arrayUpdate(m, r, lst);
        arrayUpdate(mT, c, lst1);
        transformJacToIncidenceMatrix(rest, m, mT, func);
      then
        ();
   end match;
end transformJacToIncidenceMatrix;

protected function transformJacToMatrix
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input Integer row;
  input Integer col;
  input Integer size;
  input list<DAE.Exp> b;
  input array<list<tuple<Integer, DAE.Exp>>> matrix;
algorithm
  _ := matchcontinue(jac, row, col, size, b, matrix)
    local
      Integer c, r;
      DAE.Exp e, be;
      list<DAE.Exp> b1;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      list<tuple<Integer, DAE.Exp>> lst;

    case (_, _, _, _, _, _) equation
      true = intGt(row, size);
    then ();

    case (_, _, _, _, _, _) equation
      true = intGt(col, size);
      be::b1 = b;
      lst = matrix[row];
      lst = List.consOnTrue(not Expression.isZero(be), (col, be), lst);
      lst = listReverse(lst);
      arrayUpdate(matrix, row, lst);
      transformJacToMatrix(jac, row+1, 1, size, b1, matrix);
    then ();

    case ({}, _, _, _, _, _) equation
      transformJacToMatrix(jac, row, col+1, size, b, matrix);
    then ();

    case ((r, c, BackendDAE.RESIDUAL_EQUATION(exp = e))::rest, _, _, _, _, _) equation
      true = intEq(r, row);
      true = intEq(c, col);
      lst = matrix[r];
      lst = (c, e)::lst;
      arrayUpdate(matrix, row, lst);
      transformJacToMatrix(rest, row, col+1, size, b, matrix);
    then ();

    case ((r, c, _)::_, _, _, _, _, _) equation
      true = intEq(r, row);
      true = intLt(col, c);
      transformJacToMatrix(jac, row, col+1, size, b, matrix);
    then ();

    case ((r, _, _)::_, _, _, _, _, _) equation
      true = intGe(r, row);
      transformJacToMatrix(jac, row, col+1, size, b, matrix);
    then ();
  end matchcontinue;
end transformJacToMatrix;

protected function dumpJacMatrix
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input Integer row;
  input Integer col;
  input Integer size;
  input BackendDAE.Variables vars;
algorithm
  _ := matchcontinue(jac, row, col, size, vars)
    local
      String estr;
      Integer c, r;
      DAE.Exp e;
      BackendDAE.Var v;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      DAE.ComponentRef cr;

    case (_, _, _, _, _) equation
      true = intGt(row, size);
    then ();

    case (_, _, _, _, _) equation
      true = intGt(col, size);
      v = BackendVariable.getVarAt(vars, row);
      cr = BackendVariable.varCref(v);
      print(";... % ");
      print(intString(row));
      print(" ");
      print(ComponentReference.printComponentRefStr(cr)); print("\n");
      dumpJacMatrix(jac, row+1, 1, size, vars);
    then ();

    case ({}, _, _, _, _) equation
      print("0, ");
      dumpJacMatrix(jac, row, col+1, size, vars);
    then ();

    case ((r, c, BackendDAE.RESIDUAL_EQUATION(exp = e))::rest, _, _, _, _) equation
      true = intEq(r, row);
      true = intEq(c, col);
      estr = ExpressionDump.printExpStr(e);
      print(estr); print(", ");
      dumpJacMatrix(rest, row, col+1, size, vars);
    then ();

    case ((r, c, _)::_, _, _, _, _) equation
      true = intEq(r, row);
      true = intLt(col, c);
      print("0, ");
      dumpJacMatrix(jac, row, col+1, size, vars);
    then ();

    case ((r, _, _)::_, _, _, _, _) equation
      false = intEq(r, row);
      print("0, ");
      dumpJacMatrix(jac, row, col+1, size, vars);
    then ();
  end matchcontinue;
end dumpJacMatrix;

protected function getEqnsinOrder
  input Integer indx;
  input tuple<BackendDAE.EquationArray, BackendDAE.Variables, array<list<Integer>>, BackendDAE.EquationArray, BackendDAE.Variables> inTpl;
  output tuple<BackendDAE.EquationArray, BackendDAE.Variables, array<list<Integer>>, BackendDAE.EquationArray, BackendDAE.Variables> outTpl;
protected
 BackendDAE.Equation e;
 BackendDAE.EquationArray eqns, eqnssort;
 array<list<Integer>> ass2;
 list<BackendDAE.Var> vlst;
 BackendDAE.Variables vars, varssort;
 list<Integer> vindxs;
algorithm
 (eqns, vars, ass2, eqnssort, varssort) := inTpl;
 // get Eqn
 e := BackendEquation.equationNth1(eqns, indx);
 // add equation
 eqnssort := BackendEquation.addEquation(e, eqnssort);
 // get vars of equations
 vindxs := ass2[indx];
 vlst := List.map1r(vindxs, BackendVariable.getVarAt, vars);
 vlst := sortVarsforOrder(e, vlst, vindxs, vars);
 varssort := BackendVariable.addVars(vlst, varssort);
 outTpl := (eqns, vars, ass2, eqnssort, varssort);
end getEqnsinOrder;

protected function sortVarsforOrder
  input BackendDAE.Equation inEqn;
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> vindxs;
  input BackendDAE.Variables vars;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue(inEqn, inVarLst, vindxs, vars)
    local
      list<BackendDAE.Var> vlst;
      list<DAE.ComponentRef> crlst;
      DAE.Exp e1;
      list<DAE.Exp> elst;
    case(BackendDAE.ARRAY_EQUATION(left=e1), _, _, _)
      equation
        // if array get all elements
        elst = Expression.flattenArrayExpToList(e1);
        // check if all elements crefs
        crlst = List.map(elst, Expression.expCrefNegCref);
        //crlst = List.uniqueOnTrue(crlst, ComponentReference.crefEqualNoStringCompare);
        vlst = sortVarsforOrder1(crlst, 1, inVarLst, vindxs, arrayCreate(listLength(vindxs), NONE()), vars);
      then
        vlst;
    case(BackendDAE.ARRAY_EQUATION(right=e1), _, _, _)
      equation
        // if array get all elements
        elst = Expression.flattenArrayExpToList(e1);
        // check if all elements crefs
        crlst = List.map(elst, Expression.expCrefNegCref);
        //crlst = List.uniqueOnTrue(crlst, ComponentReference.crefEqualNoStringCompare);
        vlst = sortVarsforOrder1(crlst, 1, inVarLst, vindxs, arrayCreate(listLength(vindxs), NONE()), vars);
      then
        vlst;
    case(_, _, _, _)
      equation
         vlst = List.sort(inVarLst, BackendVariable.varSortFunc);
      then
        vlst;
  end matchcontinue;
end sortVarsforOrder;

protected function sortVarsforOrder1
  input list<DAE.ComponentRef> crlst;
  input Integer index;
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> vindxs;
  input array<Option<BackendDAE.Var>> vararray;
  input BackendDAE.Variables vars;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue(crlst, index, inVarLst, vindxs, vararray, vars)
    local
      Integer i, p;
      list<Integer> ilst;
      BackendDAE.Var v;
      list<BackendDAE.Var> vlst;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest;
    case({}, _, _, _, _, _)
      equation
        vlst = List.sort(inVarLst, BackendVariable.varSortFunc);
        vlst = sortVarsforOrder2(1, vlst, vararray, {});
      then
        vlst;
    case(cr::rest, _, _, _, _, _)
      equation
        (v::{}, i::{}) = BackendVariable.getVar(cr, vars);
        p = List.position(i, vindxs);
        ilst = listDelete(vindxs, p);
        vlst = listDelete(inVarLst, p);
        arrayUpdate(vararray, index, SOME(v));
      then
        sortVarsforOrder1(rest, index+1, vlst, ilst, vararray, vars);
    case(_::rest, _, _, _, _, _)
      then
        sortVarsforOrder1(rest, index+1, inVarLst, vindxs, vararray, vars);
  end matchcontinue;
end sortVarsforOrder1;

protected function sortVarsforOrder2
  input Integer index;
  input list<BackendDAE.Var> inVarLst;
  input array<Option<BackendDAE.Var>> vararray;
  input list<BackendDAE.Var> iAcc;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue(index, inVarLst, vararray, iAcc)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> vlst;
    case(_, _, _, _)
      equation
       true = intGt(index, arrayLength(vararray));
      then
        listReverse(iAcc);
    case(_, _, _, _)
      equation
        SOME(v) = vararray[index];
      then
        sortVarsforOrder2(index+1, inVarLst, vararray, v::iAcc);
    case(_, v::vlst, _, _)
      then
        sortVarsforOrder2(index+1, vlst, vararray, v::iAcc);
  end matchcontinue;
end sortVarsforOrder2;

protected function getOrphansPairs
"author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  output Integer omark;
algorithm
  omark := matchcontinue(inOrphans, ass1, ass2, m, mt, mark, rowmarks, colummarks)
    local
      list<Integer> rest;
      Integer o;
    case ({}, _, _, _, _, _, _, _)
      then
       mark;
    case (o::rest, _, _, _, _, _, _, _)
      equation
        false = intEq(rowmarks[o], mark);
        //  print("Process Orphan " + intString(o) + "\n");
        getOrphansPairs1({o}, ass1, ass2, m, mt, mark, rowmarks, colummarks, o, {});
      then
        getOrphansPairs(rest, ass1, ass2, m, mt, mark+1, rowmarks, colummarks);
    case (_::rest, _, _, _, _, _, _, _)
      then
        getOrphansPairs(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks);
  end matchcontinue;
end getOrphansPairs;


protected function getOrphansPairs1 "author: Frenkel TUD 2012-07"
  input list<Integer> rows;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input Integer orphan;
  input list<Integer> nextQueue;
algorithm
  _ := matchcontinue(rows, ass1, ass2, m, mt, mark, rowmarks, colummarks, orphan, nextQueue)
    local
      Integer r, o;
      list<Integer> rest, next, elst;
    case ({}, _, _, _, _, _, _, _, _, {})
      then
        ();
    case ({}, _, _, _, _, _, _, _, _, _)
      equation
        //  print("next queue " + stringDelimitList(List.map(nextQueue, intString), ", ") + "\n");
        getOrphansPairs1(nextQueue, ass1, ass2, m, mt, mark, rowmarks, colummarks, orphan, {});
      then
        ();
    case (r::_, _, _, _, _, _, _, _, _, _)
      equation
        // print("Check Var: " + intString(r) + "\n");
        false = intEq(rowmarks[r], mark);
        elst = List.select1(mt[r], intGt, 0);
        //  print("search in " + stringDelimitList(List.map(elst, intString), ", ") + "\n");
        o = hasResidualOrphan(elst, ass2);
        //  print("Found Orphanpair " + intString(o) + " <-> " + intString(orphan) + "\n");
        arrayUpdate(ass1, orphan, o);
        arrayUpdate(ass2, o, {orphan});
      then
        ();
    case (r::rest, _, _, _, _, _, _, _, _, _)
      equation
        false = intEq(rowmarks[r], mark);
        elst =  List.select1(mt[r], intGt, 0) "equations of var";
        next = List.select1(List.flatten(List.map1r(elst, arrayGet, ass2)), intGt, 0) "vars assignt with equations";
        //  print("add to queue " + stringDelimitList(List.map(next, intString), ", ") + "\n");
        next = listAppend(nextQueue, next);
        arrayUpdate(rowmarks, r, mark);
        //  print("goto " + stringDelimitList(List.map(next, intString), ", ") + "\n");
        getOrphansPairs1(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, orphan, next);
      then
        ();
    case (_::rest, _, _, _, _, _, _, _, _, _)
      equation
        getOrphansPairs1(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, orphan, nextQueue);
      then
       ();
  end matchcontinue;
end getOrphansPairs1;


protected function getOrphansPairsConstraints "author: Frenkel TUD 2012-07"
  input list<Integer> inOrphans;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input BackendDAE.EquationArray eqns;
  output Integer omark;
algorithm
  omark := matchcontinue(inOrphans, ass1, ass2, m, mt, mark, rowmarks, colummarks, eqns)
    local
      list<Integer> rest;
      Integer o;
    case ({}, _, _, _, _, _, _, _, _)
      then
       mark;
    case (o::rest, _, _, _, _, _, _, _, _)
      equation
        false = intEq(colummarks[o], mark);
        arrayUpdate(colummarks, o, mark);
          print("getOrphansPairsConstraints Process Orphan " + intString(o) + "\n");
        getOrphansPairsConstraints1(mt[o], ass1, ass2, m, mt, mark, rowmarks, colummarks, eqns, o, {});
      then
        getOrphansPairsConstraints(rest, ass1, ass2, m, mt, mark+1, rowmarks, colummarks, eqns);
    case (_::rest, _, _, _, _, _, _, _, _)
      then
        getOrphansPairsConstraints(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, eqns);
  end matchcontinue;
end getOrphansPairsConstraints;


protected function getOrphansPairsConstraints1 "author: Frenkel TUD 2012-07"
  input list<Integer> eqns;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input BackendDAE.EquationArray eqnsarr;
  input Integer orphan;
  input list<Integer> nextQueue;
algorithm
  _ := matchcontinue(eqns, ass1, ass2, m, mt, mark, rowmarks, colummarks, eqnsarr, orphan, nextQueue)
    local
      Integer e, o;
      list<Integer> rest, next, rlst, lst, ass2lst;
    case ({}, _, _, _, _, _, _, _, _, _, {})
      then
        ();
    case ({}, _, _, _, _, _, _, _, _, _, _)
      equation
        getOrphansPairsConstraints1(nextQueue, ass1, ass2, m, mt, mark, rowmarks, colummarks, eqnsarr, orphan, {});
      then
        ();
    case (e::_, _, _, _, _, _, _, _, _, _, _)
      equation
        // print("Check Eqn: " + intString(e) + "\n");
        false = intEq(colummarks[e], mark);
        rlst = List.select1(m[e], intGt, 0) "vars of eqns";
        rlst = List.fold1(ass2[e], List.removeOnTrue, intEq, rlst);
        next = List.select1(List.flatten(List.map1r(rlst, arrayGet, mt)), intGt, 0);
        //  print("search in " + stringDelimitList(List.map(next, intString), ", ") + "\n");
        o = hasResidualOrphan1(next, ass2, eqnsarr);
        //  print("Found Orphanpair " + intString(o) + " <-> " + intString(orphan) + "\n");
        arrayUpdate(ass1, orphan, o);
        ass2lst = ass2[o];
        ass2lst = orphan::ass2lst;
        arrayUpdate(ass2, o, ass2lst);

      then
        ();
    case (e::rest, _, _, _, _, _, _, _, _, _, _)
      equation
        false = intEq(colummarks[e], mark);
        rlst = List.select1(m[e], intGt, 0) "vars of eqns";
        lst = List.select1(List.map1r(rlst, arrayGet, ass1), intGt, 0) "assigments of eqns";
        rlst = List.fold1(lst, List.removeOnTrue, intEq, rlst);
        next = List.select1(List.map1r(rlst, arrayGet, ass1), intGt, 0);
        next = listAppend(nextQueue, next);
        arrayUpdate(colummarks, e, mark);
        //  print("goto " + stringDelimitList(List.map(next, intString), ", ") + "\n");
        getOrphansPairsConstraints1(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, eqnsarr, orphan, next);
      then
        ();
    case (_::rest, _, _, _, _, _, _, _, _, _, _)
      equation
        getOrphansPairsConstraints1(rest, ass1, ass2, m, mt, mark, rowmarks, colummarks, eqnsarr, orphan, nextQueue);
      then
       ();
  end matchcontinue;
end getOrphansPairsConstraints1;


protected function getIndexesForEqnsAdvanced "author: Frenkel TUD 2012-07"
  input list<Integer> orphans;
  input Integer index;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer imark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> orowmarks;
  input array<Integer> ocolummarks;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input array<list<Integer>> vec1;
  input array<Integer> vec2;
  input array<Boolean> queuemark;

  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.Shared shared;
  input Integer size;


  output Integer outMark;
algorithm
  outMark := matchcontinue(orphans, index, m, mT, imark, rowmarks, colummarks, orowmarks, ocolummarks, ass1, ass2, vec1, vec2, queuemark, vars, eqns, shared, size)
    local
      Integer vorphan, eorphan, index1, mark;
      list<Integer> rest, rows, queue, rqueue, bvars, beqns, lst, vorphans, vorphanseqns;
      list<list<Integer>> queuelst;

    case ({}, _, _, _, _, _, _, _, _, _, _, _ , _, _, _, _, _, _)
      equation
        //markIndexdColums(1, arrayLength(vec1), mark+1, colummarks, vec2);
        //getIndexesForEqnsRest(1, arrayLength(vec1), index, mark+1, colummarks, ass1, ass2, vec1, vec2);
      then imark;
    case (vorphan::rest, _, _, _, _, _, _, _, _, _, _, _ , _, _, _, _, _, _)
      equation
        true = intEq(orowmarks[vorphan], 1);
        eorphan = ass1[vorphan];
        vorphans = ass2[eorphan];
        //  print("getIndexesForEqnsAdvanced Process Orphans " + stringDelimitList(List.map(vorphans, intString), ", ") + "  " + intString(eorphan) + "\n");
        // generate subgraph from residual equation to tearing variable
        rows = List.select(m[eorphan], Util.intPositive);
        rows = List.fold1(ass2[eorphan], List.removeOnTrue, intEq, rows);
        // BackendDump.debuglst((rows, intString, ", ", "\n"));
        _ = getIndexSubGraph(rows, vorphans, m, mT, imark, rowmarks, colummarks, orowmarks, ocolummarks, ass1, ass2, false);
        // generate queue with BFS from tearing var to residual equation
        // print("getIndex ");
        vorphanseqns = List.unique(List.flatten(List.map1r(vorphans, arrayGet, mT)));
        //  BackendDump.debuglst((vorphanseqns, intString, ", ", "\n"));
        queuelst = getIndexQueque(vorphanseqns, m, mT, imark, rowmarks, colummarks, ass1, ass2, vec2, queuemark, {}, {}, {});
        queue = List.flatten(queuelst);
        // print("final queue ");
        // BackendDump.debuglst((queue, intString, ", ", "\n"));
        // set indexes
        mark = imark+2;
        ((index1, queue, rqueue)) = List.fold1(queue, setIndexQueue, (vec1, vec2, ass2, queuemark, colummarks, mark), (index, {}, {}));
        arrayUpdate(vec1, index1, vorphans);
        arrayUpdate(vec2, index1, eorphan);
        arrayUpdate(queuemark, eorphan, true);
        mark = mark+1;
        // collect all border vars and equations
        // mark all elements of the clique
        //  print("Mark all Index Vars " + stringDelimitList(List.map(rqueue, intString), ", ") + "\n");
        List.map2_0(rqueue, doMark, rowmarks, mark);
        //  print("Mark all Index Eqns " + stringDelimitList(List.map(queue, intString), ", ") + "\n");
        List.map2_0(queue, doMark, colummarks, mark);
        // get all unmarked elements -> boarder elements
        bvars = getBorderElements(queue, m, mark, rowmarks, {});
        bvars = List.fold1(vorphans, List.removeOnTrue, intEq, bvars);
        //  print("Mark all Index BVars " + stringDelimitList(List.map(bvars, intString), ", ") + "\n");
        beqns = getBorderElements(rqueue, mT, mark, colummarks, {});
        beqns = List.removeOnTrue(eorphan, intEq, beqns);
        //  print("Mark all Index BEqns " + stringDelimitList(List.map(beqns, intString), ", ") + "\n");
        lst = List.select2(m[eorphan], unmarked, rowmarks, mark);
        lst = listAppend(vorphans, listAppend(lst, bvars));
        //  print("Set eorphan " + intString(eorphan) + ": " + stringDelimitList(List.map(lst, intString), ", ") + "\n");
        arrayUpdate(m, eorphan, lst);

        lst = List.select2(vorphanseqns, unmarked, colummarks, mark);
        lst = listAppend(eorphan::lst, beqns);
        //  print("Set vorphan " + intString(vorphan) + ": " + stringDelimitList(List.map(lst, intString), ", ") + "\n");
        arrayUpdate(mT, vorphan, lst);

        setBoarderElemts(bvars, mT, mark, colummarks, eorphan);
        setBoarderElemts(beqns, m, mark, rowmarks, vorphan);
        // unset orphanmark so it can passed
        //arrayUpdate(orowmarks, vorphan, -1);
        _ = List.fold1(vorphans, markOrphans, -1, orowmarks);
        arrayUpdate(ocolummarks, eorphan, -1);

       vorphans = List.removeOnTrue(vorphan, intEq, vorphans);
       _ = List.fold1(vorphans, markOrphans, -1, orowmarks);
       _ = List.fold1r(vorphans, arrayUpdate, {}, mT);

       //   syst = BackendDAE.EQSYSTEM(vars, eqns, SOME(m), SOME(mT), BackendDAE.NO_MATCHING(), {});
       //   DumpGraphML.dumpSystem(syst, shared, NONE(), intString(size) + "SystemIndexing" + intString(index) + ".graphml");

      then
       getIndexesForEqnsAdvanced(rest, index1+1, m, mT, mark+2, rowmarks, colummarks, orowmarks, ocolummarks, ass1, ass2, vec1, vec2, queuemark, vars, eqns, shared, size);
    case (_::rest, _, _, _, _, _, _, _, _, _, _, _ , _, _, _, _, _, _)
      then
       getIndexesForEqnsAdvanced(rest, index, m, mT, imark, rowmarks, colummarks, orowmarks, ocolummarks, ass1, ass2, vec1, vec2, queuemark, vars, eqns, shared, size);
  end matchcontinue;
end getIndexesForEqnsAdvanced;



protected function getBorderElements
  input list<Integer> elements;
  input BackendDAE.IncidenceMatrix m;
  input Integer mark;
  input array<Integer> arr;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := match(elements, m, mark, arr, iAcc)
    local
      Integer elem;
      list<Integer> rest, lst, lst1;
    case({}, _, _, _, _) then iAcc;
    case(elem::rest, _, _, _, _)
      equation
        (lst, lst1) = List.split2OnTrue(m[elem], unmarked, arr, mark);
        arrayUpdate(m, elem, lst1);
        lst = List.select2(lst, unmarked, arr, mark+1);
        List.map2_0(lst, doMark, arr, mark+1);
        lst = getBorderElements(rest, m, mark, arr, listAppend(lst, iAcc));
      then
        lst;
  end match;
end getBorderElements;

protected function setBoarderElemts
  input list<Integer> elements;
  input BackendDAE.IncidenceMatrix m;
  input Integer mark;
  input array<Integer> arr;
  input Integer orphan;
algorithm
  _ := match(elements, m, mark, arr, orphan)
    local
      Integer elem;
      list<Integer> rest, lst;
    case({}, _, _, _, _) then ();
    case(elem::rest, _, _, _, _)
      equation
        lst = List.select2(m[elem], unmarked, arr, mark);
        arrayUpdate(m, elem, orphan::lst);
        //  print("Set BElement " + intString(elem) + ": " + stringDelimitList(List.map(orphan::lst, intString), ", ") + "\n");
        setBoarderElemts(rest, m, mark, arr, orphan);
      then
        ();
  end match;
end setBoarderElemts;

protected function setIndexQueue "author: Frenkel TUD 2012-07"
 input Integer col;
 input tuple<array<list<Integer>>, array<Integer>, array<list<Integer>>, array<Boolean>, array<Integer>, Integer> tpl;
 input tuple<Integer, list<Integer>, list<Integer>> itpl;
 output tuple<Integer, list<Integer>, list<Integer>> otpl;
algorithm
  otpl := matchcontinue(col, tpl, itpl)
    local
      array<Integer> vec2, colummark;
      array<List<Integer>> vec1, ass2;
      list<Integer> r, rlst, elst;
      array<Boolean> queuemark;
      Integer index, mark;
    case (_, (vec1, vec2, ass2, queuemark, colummark, mark), (index, elst, rlst))
      equation
        r = ass2[col];
        false = queuemark[col];
        //  print("Index: " + intString(index) + ":" + stringDelimitList(List.map(r, intString), ", ") + "  " + intString(col) + "\n");
        arrayUpdate(vec1, index, r);
        arrayUpdate(vec2, index, col);
        arrayUpdate(queuemark, col, true);
        arrayUpdate(colummark, col, mark);
      then
        ((index+1, col::elst, listAppend(r, rlst)));
    case (_, (_, _, ass2, _, colummark, mark), (index, elst, rlst))
      equation
        r = ass2[col];
        false = intEq(colummark[col], mark);
        arrayUpdate(colummark, col, mark);
      then
        ((index, col::elst, listAppend(r, rlst)));
    else
      then
        itpl;
  end matchcontinue;
end setIndexQueue;

protected function getIndexQueque "author: Frenkel TUD 2012-07"
  input list<Integer> colums;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input array<Integer> vec2;
  input array<Boolean> queuemark;
  input list<Integer> nextqueue;
  input list<Integer> iqueue;
  input list<list<Integer>> iqueue1;
  output list<list<Integer>> oqueue;
algorithm
  oqueue := match(colums, m, mT, mark, rowmarks, colummarks, ass1, ass2, vec2, queuemark, nextqueue, iqueue, iqueue1)
    local
      Integer c;
      list<Integer> rest, queue, r, queue1, colums1;
      Boolean b, b1, b2;
    case ({}, _, _, _, _, _, _, _, _, _, {}, _, _) then iqueue1;
    case ({}, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        queue = List.unique(iqueue);
        // print("append level: "); BackendDump.debuglst((queue, intString, ", ", "\n"));
      then
        getIndexQueque(nextqueue, m, mT, mark, rowmarks, colummarks, ass1, ass2, vec2, queuemark, {}, {}, queue::iqueue1);
    case (c::rest, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        r = ass2[c];
        //  print("Process Colum " + intString(c) + " Rows " + stringDelimitList(List.map(r, intString), ", ") + "  " + boolString(b) +"\n");
        (colums1, b2) = getIndexQueque1(r, c, mT, mark, rowmarks);
        //  BackendDump.debuglst((colums1, intString, ", ", "\n"));
        b1 = not listEmpty(colums);
        // cons next rows in front to jump over marked nodes
        queue = if b1 then List.unionOnTrue(colums1, nextqueue, intEq) else nextqueue;
        //  print("queue: "); BackendDump.debuglst((queue, intString, ", ", "\n"));
        queue1 = List.consOnTrue(b2, c, iqueue);
      then
       getIndexQueque(rest, m, mT, mark, rowmarks, colummarks, ass1, ass2, vec2, queuemark, queue, queue1, iqueue1);
  end match;
end getIndexQueque;

protected function getIndexQueque1
  input list<Integer> rows;
  input Integer c;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> rowmarks;
  output list<Integer> ocolums = {};
  output Boolean ob = false;
protected
  list<Integer> colums;
algorithm
  for r in rows loop
    if intEq(rowmarks[r], mark) then
      //  print("Go from: " + intString(c) + " to " + intString(r) + "\n");
      ob := true;
      colums := List.select(mT[r], Util.intPositive);
      colums := List.removeOnTrue(c, intEq , colums);
      ocolums := listAppend(colums, ocolums);
    end if;
  end for;
  ocolums := List.unique(ocolums);
end getIndexQueque1;

protected function unmarked
  input Integer indx;
  input array<Integer> markarray;
  input Integer mark;
  output Boolean b;
algorithm
  b := intNe(markarray[indx], mark);
end unmarked;

protected function marked
  input Integer indx;
  input array<Integer> markarray;
  input Integer mark;
  output Boolean b;
algorithm
  b := intEq(markarray[indx], mark);
end marked;

protected function isOrphan
  input Integer indx;
  input array<Integer> ass;
  output Boolean b;
algorithm
  b := intLt(ass[indx], 1);
end isOrphan;

protected function isNoOrphan
  input Integer indx;
  input array<Integer> ass;
  output Boolean b;
algorithm
  b := intGt(ass[indx], 0);
end isNoOrphan;

protected function isResOrphan
  input Integer indx;
  input array<list<Integer>> ass;
  output Boolean b;
algorithm
  b := listEmpty(ass[indx]);
end isResOrphan;

protected function isNoResOrphan
  input Integer indx;
  input array<list<Integer>> ass;
  output Boolean b;
algorithm
  b := not listEmpty(ass[indx]);
end isNoResOrphan;

protected function doAssign "author: Frenkel TUD 2012-05"
  input Integer index;
  input array<list<Integer>> arr;
  input list<Integer> assign;
algorithm
  _ := arrayUpdate(arr, index, assign);
end doAssign;

protected function doMark "author: Frenkel TUD 2012-05"
  input Integer index;
  input array<Integer> arr;
  input Integer mark;
algorithm
  _ := arrayUpdate(arr, index, mark);
end doMark;

protected function getIndexSubGraph "author: Frenkel TUD 2012-07"
  input list<Integer> rows;
  input list<Integer> vorphan;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> rowmarks;
  input array<Integer> colummarks;
  input array<Integer> orowmarks;
  input array<Integer> ocolummarks;
  input array<Integer> ass1;
  input array<list<Integer>> ass2;
  input Boolean ifound;
  output Boolean found;
algorithm
  found := matchcontinue(rows, vorphan, m, mT, mark, rowmarks, colummarks, orowmarks, ocolummarks, ass1, ass2, ifound)
    local
      Integer r, e;
      list<Integer> rest, nextrows;
      Boolean b;
    case ({}, _, _, _, _, _, _, _, _, _, _, _) then ifound;
    case (r::rest, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // is my var orphan?
        //true = intEq(r, vorphan);
        true = listMember(r, vorphan);
        // mark all entries in the queue
        // print("Found orphan " + intString(r) + "\n");
         _ = getIndexSubGraph(rest, vorphan, m, mT, mark, rowmarks, colummarks, orowmarks, ocolummarks, ass1, ass2, false);
      then
        true;
    case (r::rest, _, _, _, _, _, _, _, _, _, _, _)
      equation
        //false = intEq(r, vorphan);
        false = listMember(r, vorphan);
        // stop if it is an orphan
        false = intEq(orowmarks[r], 1);
        true = intEq(rowmarks[r], mark);
        e = ass1[r];
        List.map2_0(ass2[e], doMark, rowmarks, mark);
      then
        getIndexSubGraph(rest, vorphan, m, mT, mark, rowmarks, colummarks, orowmarks, ocolummarks, ass1, ass2, true);
    case (r::rest, _, _, _, _, _, _, _, _, _, _, _)
      equation
        //false = intEq(r, vorphan);
        false = listMember(r, vorphan);
        // stop if it is an orphan
        false = intEq(orowmarks[r], 1);
        //false = intEq(rowmarks[r], mark);
        e = ass1[r];
        false = intEq(ocolummarks[e], 1);
        false = intEq(colummarks[e], mark);
        nextrows = List.select(m[e], Util.intPositive);
        nextrows = List.setDifferenceOnTrue(nextrows, ass2[e], intEq);
        //  print("search Subgraph: " + intString(r) + " across " + intString(e) + "\n");
        //arrayUpdate(rowmarks, r, mark);
        arrayUpdate(colummarks, e, mark);
        //  BackendDump.debuglst((nextrows, intString, ", ", "\n"));
        b = getIndexSubGraph(nextrows, vorphan, m, mT, mark, rowmarks, colummarks, orowmarks, ocolummarks, ass1, ass2, false);
        markIndexSubgraph(b, ass2[e], mark, rowmarks);
      then
        getIndexSubGraph(rest, vorphan, m, mT, mark, rowmarks, colummarks, orowmarks, ocolummarks, ass1, ass2, b or ifound);
    case (_::rest, _, _, _, _, _, _, _, _, _, _, _)
      then
        getIndexSubGraph(rest, vorphan, m, mT, mark, rowmarks, colummarks, orowmarks, ocolummarks, ass1, ass2, ifound);
  end matchcontinue;
end getIndexSubGraph;

protected function markIndexSubgraph "author: Frenkel TUD 2012-07"
  input Boolean b;
  input list<Integer> r;
  input Integer mark;
  input array<Integer> rowmarks;
algorithm
  _ := match(b, r, mark, rowmarks)
    case(false, _, _, _) then ();
    case(true, _, _, _)
      equation
        List.map2_0(r, doMark, rowmarks, mark);
      then
        ();
  end match;
end markIndexSubgraph;

protected function getIndexesForEqnsRest
  input Integer i;
  input Integer size;
  input Integer id;
  input Integer mark;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> vec1;
  input array<Integer> vec2;
algorithm
  _ := matchcontinue(i, size, id, mark, colummarks, ass1, ass2, vec1, vec2)
  case(_, _, _, _, _, _, _, _, _)
    equation
      false = intGt(i, size);
      true = intEq(mark, colummarks[i]);
      getIndexesForEqnsRest(i+1, size, id, mark, colummarks, ass1, ass2, vec1, vec2);
    then
      ();
  case(_, _, _, _, _, _, _, _, _)
    equation
      false = intGt(i, size);
      arrayUpdate(vec1, id, ass2[i]);
      arrayUpdate(vec2, id, i);
      getIndexesForEqnsRest(i+1, size, id+1, mark, colummarks, ass1, ass2, vec1, vec2);
    then
      ();
  else
    then
      ();
  end matchcontinue;
end getIndexesForEqnsRest;

protected function markIndexdColums
  input Integer i;
  input Integer size;
  input Integer mark;
  input array<Integer> colummarks;
  input array<Integer> vec2;
algorithm
  _ := matchcontinue(i, size, mark, colummarks, vec2)
  case(_, _, _, _, _)
    equation
      false = intGt(i, size);
      true = intGt(vec2[i], 0);
      arrayUpdate(colummarks, vec2[i], mark);
      markIndexdColums(i+1, size, mark, colummarks, vec2);
    then
      ();
  case(_, _, _, _, _)
    equation
      false = intGt(i, size);
      markIndexdColums(i+1, size, mark, colummarks, vec2);
    then
      ();
  else
    then
      ();
  end matchcontinue;
end markIndexdColums;

protected function getOrphans "author: Frenkel TUD 2011-05"
  input Integer indx;
  input Integer size;
  input array<Integer> ass;
  input list<Integer> inOrphans;
  output list<Integer> outOrphans;
algorithm
  outOrphans := matchcontinue(indx, size, ass, inOrphans)
    local
      list<Integer> orphans;
    case (_, _, _, _)
      equation
        true = intGt(indx, size);
      then
        inOrphans;
    case (_, _, _, _)
      equation
        orphans = List.consOnTrue(intLt(ass[indx], 1), indx, inOrphans);
      then
        getOrphans(indx+1, size, ass, orphans);
  end matchcontinue;
end getOrphans;

protected function expHasCref "author: Frenkel TUD 2012-05
  traverses an expression and check if the cref or parents of them are there"
  input DAE.Exp inExp;
  input DAE.ComponentRef cr;
  output Boolean isthere;
protected
  HashSet.HashSet set;
algorithm
  set := HashSet.emptyHashSet();
  set := addCrefandParentsToSet(cr, set, NONE());
  (_, (_, isthere)) := Expression.traverseExpTopDown(inExp, expHasCreftraverser, (set, false));
end expHasCref;

protected function addCrefandParentsToSet
  input DAE.ComponentRef inCref;
  input HashSet.HashSet ihs;
  input Option<DAE.ComponentRef> oprecr;
  output HashSet.HashSet ohs;
algorithm
  ohs := match(inCref, ihs, oprecr)
    local
      DAE.ComponentRef cr, idcr, precr, subcr;
      list<DAE.ComponentRef> crlst;
      HashSet.HashSet set;
      DAE.Type ty;
      DAE.Ident ident;
      list<DAE.Subscript> subscriptLst;
    case (cr as DAE.CREF_IDENT(), _, NONE())
      equation
        crlst = ComponentReference.expandCref(cr, true);
        set = List.fold(cr::crlst, BaseHashSet.add, ihs);
      then set;
    case (cr as DAE.CREF_IDENT(), _, SOME(precr))
      equation
        crlst = ComponentReference.expandCref(cr, true);
        crlst = List.map1r(cr::crlst, ComponentReference.joinCrefs, precr);
        set = List.fold(crlst, BaseHashSet.add, ihs);
      then set;
    case (DAE.CREF_QUAL(ident=ident, identType=ty, subscriptLst=subscriptLst, componentRef=subcr), _, NONE())
      equation
        idcr = ComponentReference.makeCrefIdent(ident, ty, {});
        set = BaseHashSet.add(idcr, ihs);
        idcr = ComponentReference.makeCrefIdent(ident, ty, subscriptLst);
        set = BaseHashSet.add(idcr, set);
      then
        addCrefandParentsToSet(subcr, set, SOME(idcr));
    case (DAE.CREF_QUAL(ident=ident, identType=ty, subscriptLst=subscriptLst, componentRef=subcr), _, SOME(precr))
      equation
        idcr = ComponentReference.makeCrefIdent(ident, ty, {});
        idcr = ComponentReference.joinCrefs(precr, idcr);
        set = BaseHashSet.add(idcr, ihs);
        idcr = ComponentReference.makeCrefIdent(ident, ty, subscriptLst);
        precr = ComponentReference.joinCrefs(precr, idcr);
        set = BaseHashSet.add(precr, ihs);
      then
        addCrefandParentsToSet(subcr, set, SOME(precr));
  end match;
end addCrefandParentsToSet;

protected function expHasCreftraverser "author: Frenkel TUD 2012-05
  helper for expHasCref"
  input DAE.Exp e;
  input tuple<HashSet.HashSet, Boolean> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<HashSet.HashSet, Boolean> outTpl;
algorithm
  (outExp, cont, outTpl) := matchcontinue(e, inTpl)
    local
      Boolean b;
      DAE.ComponentRef cr;
      HashSet.HashSet set;

    case (DAE.CREF(componentRef = cr), (set, false))
      equation
        b = BaseHashSet.has(cr, set);
      then
        (e, not b, (set, b));

    case (_, (set, b)) then (e, not b, (set, b));

  end matchcontinue;
end expHasCreftraverser;

protected function assignLst
  input list<Integer> vlst;
  input Integer e;
  input array<Integer> ass1;
  input array<Integer> ass2;
algorithm
  _ := match(vlst, e, ass1, ass2)
    local
      Integer v;
      list<Integer> rest;
    case ({}, _, _, _) then ();
    case (v::rest, _, _, _)
      equation
        arrayUpdate(ass1, v, e);
        arrayUpdate(ass2, e, v);
        assignLst(rest, e+1, ass1, ass2);
      then
        ();
  end match;
end assignLst;

protected function unassignedLst
  input list<Integer> vlst;
  input array<Integer> ass1;
algorithm
  _ := match(vlst, ass1)
    local
      Integer v;
      list<Integer> rest;
    case ({}, _) then ();
    case (v::rest, _)
      equation
        false = intGt(ass1[v], 0);
        unassignedLst(rest, ass1);
      then
        ();
  end match;
end unassignedLst;

protected function onefreeMatchingBFS "author: Frenkel TUD 2012-05"
  input BackendDAE.IncidenceMatrixElement queue;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Integer size;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input BackendDAE.IncidenceMatrixElement nextQeue;
algorithm
  _ := match(queue, m, mt, size, ass1, ass2, columark, mark, nextQeue)
    local
      Integer c;
      BackendDAE.IncidenceMatrixElement rest, newqueue, rows;
    case ({}, _, _, _, _, _, _, _, {}) then ();
    case ({}, _, _, _, _, _, _, _, _)
      equation
        //  print("NextQeue\n");
        onefreeMatchingBFS(nextQeue, m, mt, size, ass1, ass2, columark, mark, {});
      then
        ();
    case(c::rest, _, _, _, _, _, _, _, _)
      equation
        //  print("Process Eqn " + intString(c) + "\n");
        rows = List.removeOnTrue(ass1, isAssignedSaveEnhanced, m[c]);
        //arrayUpdate(columark, c, mark);
        newqueue = onefreeMatchingBFS1(rows, c, mt, ass1, ass2, columark, mark, nextQeue);
        onefreeMatchingBFS(rest, m, mt, size, ass1, ass2, columark, mark, newqueue);
      then
        ();
  end match;
end onefreeMatchingBFS;

protected function isAssignedSaveEnhanced "author: Frenkel TUD 2012-05"
  input array<Integer> ass;
  input Integer inTpl;
  output Boolean outB;
algorithm
  outB := if intGt(inTpl, 0) then intGt(ass[inTpl], 0) else true;
end isAssignedSaveEnhanced;

protected function onefreeMatchingBFS1 "author: Frenkel TUD 2012-05"
  input BackendDAE.IncidenceMatrixElement rows;
  input Integer c;
  input BackendDAE.IncidenceMatrix mt;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<Integer> columark;
  input Integer mark;
  input BackendDAE.IncidenceMatrixElement inNextQeue;
  output BackendDAE.IncidenceMatrixElement outNextQeue;
algorithm
  outNextQeue := matchcontinue(rows, c, mt, ass1, ass2, columark, mark, inNextQeue)
    local
      Integer r;
      BackendDAE.IncidenceMatrixElement vareqns;
    case (r::{}, _, _, _, _, _, _, _)
      equation
        //  print("Assign Var" + intString(r) + " with Eqn " + intString(c) + "\n");
        // assigen
        arrayUpdate(ass1, r, c);
        arrayUpdate(ass2, c, r);
        vareqns = List.removeOnTrue(ass2, isAssignedSaveEnhanced, mt[r]);
        //vareqns = List.removeOnTrue((columark, mark), isMarked, vareqns);
        //markEqns(vareqns, columark, mark);
      then
        listAppend(inNextQeue, vareqns);
    else inNextQeue;
  end matchcontinue;
end onefreeMatchingBFS1;

protected function vectorMatching "author: Frenkel TUD 2012-05
  try to match functions like a = f(...), f(..)=a for
  array/complex equations"
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input tuple<Integer, array<Integer>, array<Integer>> inTpl;
  output tuple<Integer, array<Integer>, array<Integer>> outTpl;
algorithm
  outTpl := matchcontinue(eqn, vars, inTpl)
    local
      Integer id, size;
      array<Integer> vec1, vec2;
      DAE.Exp e1, e2;
      list<Integer> ds;

    // array equations
    case (BackendDAE.ARRAY_EQUATION(dimSize=ds, left=e1, right=e2), _, (id, vec1, vec2))
      equation
        size = List.fold(ds, intMul, 1);
        ((id, vec1, vec2)) = vectorMatching1(e1, e2, size, vars, (id, vec1, vec2));
      then ((id, vec1, vec2));
    case (BackendDAE.ARRAY_EQUATION(dimSize=ds, left=e2, right=e1), _, (id, vec1, vec2))
      equation
        size = List.fold(ds, intMul, 1);
        ((id, vec1, vec2)) = vectorMatching1(e2, e1, size, vars, (id, vec1, vec2));
      then ((id, vec1, vec2));
    // complex equations
    case (BackendDAE.COMPLEX_EQUATION(size=size, left=e1, right=e2), _, (id, vec1, vec2))
      equation
        ((id, vec1, vec2)) = vectorMatching1(e1, e2, size, vars, (id, vec1, vec2));
      then ((id, vec1, vec2));
    case (BackendDAE.COMPLEX_EQUATION(size=size, left=e2, right=e1), _, (id, vec1, vec2))
      equation
        ((id, vec1, vec2)) = vectorMatching1(e2, e1, size, vars, (id, vec1, vec2));
      then ((id, vec1, vec2));
    case (_, _, (id, vec1, vec2))
      equation
        size = BackendEquation.equationSize(eqn);
      then ((id+size, vec1, vec2));
  end matchcontinue;
end vectorMatching;

protected function vectorMatching1 "author: Frenkel TUD 2012-05
  try to match functions like a = f(...), f(..)=a for array/complex equations"
  input DAE.Exp e1;
  input DAE.Exp e2;
  input Integer size;
  input BackendDAE.Variables vars;
  input tuple<Integer, array<Integer>, array<Integer>> inTpl;
  output tuple<Integer, array<Integer>, array<Integer>> outTpl;
algorithm
  outTpl := matchcontinue(e1, e2, size, vars, inTpl)
    local
      Integer id;
      array<Integer> vec1, vec2;
      DAE.ComponentRef cr, crnosubs;
      list<DAE.ComponentRef> crlst, crlst1;
      list<DAE.Exp> elst;
      list<Integer> ilst;
      list<Boolean> blst;
      HashSet.HashSet set;

    // a = f(...)
    case (DAE.CREF(componentRef=cr), _, _, _, (id, vec1, vec2))
      equation
        // check if cref is not also at the other side
        false = expHasCref(e2, cr);
        // get Vars
        (_, ilst) = BackendVariable.getVar(cr, vars);
        // size equal
        true = intEq(size, listLength(ilst));
        // unassgned
        unassignedLst(ilst, vec1);
        // assign
        assignLst(ilst, id, vec1, vec2);
      then ((id+size, vec1, vec2));
    // f(...) = a
    case (_, DAE.CREF(componentRef=cr), _, _, (id, vec1, vec2))
      equation
        // check if cref is not also at the other side
        false = expHasCref(e1, cr);
        // get Vars
        (_, ilst) = BackendVariable.getVar(cr, vars);
        // size equal
        true = intEq(size, listLength(ilst));
        // unassgned
        unassignedLst(ilst, vec1);
        // assign
        assignLst(ilst, id, vec1, vec2);
      then ((id+size, vec1, vec2));
    // a = f(...)
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef=cr)), _, _, _, (id, vec1, vec2))
      equation
        // check if cref is not also at the other side
        false = expHasCref(e2, cr);
        // get Vars
        (_, ilst) = BackendVariable.getVar(cr, vars);
        // size equal
        true = intEq(size, listLength(ilst));
        // unassgned
        unassignedLst(ilst, vec1);
        // assign
        assignLst(ilst, id, vec1, vec2);
      then ((id+size, vec1, vec2));
    // f(...) = a
    case (_, DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef=cr)), _, _, (id, vec1, vec2))
      equation
        // check if cref is not also at the other side
        false = expHasCref(e1, cr);
        // get Vars
        (_, ilst) = BackendVariable.getVar(cr, vars);
        // size equal
        true = intEq(size, listLength(ilst));
        // unassgned
        unassignedLst(ilst, vec1);
        // assign
        assignLst(ilst, id, vec1, vec2);
      then ((id+size, vec1, vec2));
    // {a[1], a[2], a[3]} = f(...)
    case (_, _, _, _, (id, vec1, vec2))
      equation
        // if array get all elements
        elst = Expression.flattenArrayExpToList(e1);
        // check if all elements crefs
        crlst = List.map(elst, Expression.expCrefNegCref);
        crlst = List.uniqueOnTrue(crlst, ComponentReference.crefEqualNoStringCompare);
        true = intEq(size, listLength(crlst));
        cr::crlst1 = crlst;
        blst = List.map1(crlst1, ComponentReference.crefEqualWithoutLastSubs, cr);
        true = Util.boolAndList(blst);
        // check if crefs no on other side
        set = HashSet.emptyHashSet();
        crnosubs = ComponentReference.crefStripLastSubs(cr);
        set = addCrefandParentsToSet(crnosubs, set, NONE());
        set = List.fold(crlst, BaseHashSet.add, set);
        (_, (_, false)) = Expression.traverseExpTopDown(e2, expHasCreftraverser, (set, false));
        (_, ilst) = BackendVariable.getVarLst(crlst, vars, {}, {});
        // unassgned
        unassignedLst(ilst, vec1);
        // assign
        assignLst(ilst, id, vec1, vec2);
      then ((id+size, vec1, vec2));
    // f(...) = {a[1], a[2], a[3]}
    case (_, _, _, _, (id, vec1, vec2))
      equation
        // if array get all elements
        elst = Expression.flattenArrayExpToList(e2);
        // check if all elements crefs
        crlst = List.map(elst, Expression.expCrefNegCref);
        crlst = List.uniqueOnTrue(crlst, ComponentReference.crefEqualNoStringCompare);
        true = intEq(size, listLength(crlst));
        cr::crlst1 = crlst;
        blst = List.map1(crlst1, ComponentReference.crefEqualWithoutLastSubs, cr);
        true = Util.boolAndList(blst);
        // check if crefs no on other side
        set = HashSet.emptyHashSet();
        crnosubs = ComponentReference.crefStripLastSubs(cr);
        set = addCrefandParentsToSet(crnosubs, set, NONE());
        set = List.fold(crlst, BaseHashSet.add, set);
        (_, (_, false)) = Expression.traverseExpTopDown(e1, expHasCreftraverser, (set, false));
        (_, ilst) = BackendVariable.getVarLst(crlst, vars, {}, {});
        // unassgned
        unassignedLst(ilst, vec1);
        // assign
        assignLst(ilst, id, vec1, vec2);
      then ((id+size, vec1, vec2));
  end matchcontinue;
end vectorMatching1;

protected function aliasMatching "author: Frenkel TUD 2011-07"
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input tuple<Integer, array<Integer>, array<Integer>> inTpl;
  output tuple<Integer, array<Integer>, array<Integer>> outTpl;
algorithm
  outTpl := matchcontinue(eqn, vars, inTpl)
    local
      Integer id, i, i1, i2, size;
      array<Integer> vec1, vec2;
      DAE.ComponentRef cr1, cr2;

    case (BackendDAE.EQUATION(exp = DAE.CREF(componentRef=cr1), scalar=DAE.CREF(componentRef=cr2)), _, (id, vec1, vec2))
      equation
        false = intGt(vec2[id], 0);
        (_, i1::{}) = BackendVariable.getVar(cr1, vars);
        (_, i2::{}) = BackendVariable.getVar(cr2, vars);
        i = aliasMatching1(i1, i2, intGt(vec1[i1], 0), intGt(vec1[i2], 0));
        vec1 = arrayUpdate(vec1, i, id);
        vec2 = arrayUpdate(vec2, id, i);
      then ((id+1, vec1, vec2));
    case (_, _, (id, vec1, vec2))
      equation
        size = BackendEquation.equationSize(eqn);
      then ((id+size, vec1, vec2));
  end matchcontinue;
end aliasMatching;

protected function aliasMatching1 "author: Frenkel TUD 2011-07"
  input Integer i1;
  input Integer i2;
  input Boolean b1;
  input Boolean b2;
  output Integer i;
algorithm
  i := match(i1, i2, b1, b2)
    case (_, _, false, true) then i1;
    case (_, _, true, false) then i2;
  end match;
end aliasMatching1;

protected function naturalMatching "author: Frenkel TUD 2011-05"
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input tuple<Integer, array<Integer>, array<Integer>> inTpl;
  output tuple<Integer, array<Integer>, array<Integer>> outTpl;
algorithm
  outTpl := matchcontinue(eqn, vars, inTpl)
    local
      Integer id, i;
      array<Integer> vec1, vec2;
      DAE.ComponentRef cr;
      DAE.Exp e, e1, e2;
      list<BackendDAE.Var> vlst;

    case (BackendDAE.EQUATION(exp = DAE.CREF(componentRef=cr)), _, (id, vec1, vec2))
      equation
        false = intGt(vec2[id], 0);
        (_, i::_) = BackendVariable.getVar(cr, vars);
        false = intGt(vec1[i], 0);
        vec1 = arrayUpdate(vec1, i, id);
        vec2 = arrayUpdate(vec2, id, i);
      then ((id+1, vec1, vec2));
    case (_, _, (id, vec1, vec2))
      then ((id+1, vec1, vec2));
  end matchcontinue;
end naturalMatching;

protected function naturalMatching1 "author: Frenkel TUD 2011-05"
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input tuple<Integer, array<Integer>, array<Integer>> inTpl;
  output tuple<Integer, array<Integer>, array<Integer>> outTpl;
algorithm
  outTpl := matchcontinue(eqn, vars, inTpl)
    local
      Integer id, i;
      array<Integer> vec1, vec2;
      DAE.ComponentRef cr;
      DAE.Exp e, e1, e2;
      list<BackendDAE.Var> vlst;

    case (BackendDAE.EQUATION(scalar = DAE.CREF(componentRef=cr)), _, (id, vec1, vec2))
      equation
        false = intGt(vec2[id], 0);
        (_, i::_) = BackendVariable.getVar(cr, vars);
        false = intGt(vec1[i], 0);
        vec1 = arrayUpdate(vec1, i, id);
        vec2 = arrayUpdate(vec2, id, i);
      then ((id+1, vec1, vec2));
    case (_, _, (id, vec1, vec2))
      then ((id+1, vec1, vec2));
  end matchcontinue;
end naturalMatching1;

protected function naturalMatching2 "author: Frenkel TUD 2011-05"
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input tuple<Integer, array<Integer>, array<Integer>> inTpl;
  output tuple<Integer, array<Integer>, array<Integer>> outTpl;
algorithm
  outTpl := matchcontinue(eqn, vars, inTpl)
    local
      Integer id, i;
      array<Integer> vec1, vec2;
      DAE.ComponentRef cr;
      DAE.Exp e, e1, e2;
      list<BackendDAE.Var> vlst;

    case (BackendDAE.EQUATION(exp=e1, scalar = e2), _, (id, vec1, vec2))
      equation
        false = intGt(vec2[id], 0);
        e = Expression.expSub(e1, e2);
        vlst =BackendEquation.equationVars(eqn, vars);
        (_, i) = getConstOneVariable(vlst, e, vec1, vars);
        vec1 = arrayUpdate(vec1, i, id);
        vec2 = arrayUpdate(vec2, id, i);
      then ((id+1, vec1, vec2));
    case (_, _, (id, vec1, vec2))
      then ((id+1, vec1, vec2));
  end matchcontinue;
end naturalMatching2;

protected function getConstOneVariable "author: Frenkel TUD 2011-05"
  input list<BackendDAE.Var> vlst;
  input DAE.Exp e;
  input array<Integer> vec1;
  input BackendDAE.Variables vars;
  output DAE.ComponentRef outCr;
  output Integer i;
algorithm
  (outCr, i) := matchcontinue(vlst, e, vec1, vars)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> rest;
      DAE.ComponentRef cr;
      DAE.Exp e1, e2;
    case (v::_, _, _, _)
      equation
        cr = BackendVariable.varCref(v);
        (_, i::_) = BackendVariable.getVar(cr, vars);
        false = intGt(vec1[i], 0);
        e1 = Differentiate.differentiateExpSolve(e, cr, NONE());
        (e2, _) = ExpressionSimplify.simplify(e1);
        true = Expression.isConstOne(e2) or Expression.isConstMinusOne(e2);
      then
        (cr, i);
    case (_::rest, _, _, _)
      equation
        (cr, i) = getConstOneVariable(rest, e, vec1, vars);
      then
        (cr, i);
  end matchcontinue;
end getConstOneVariable;

annotation(__OpenModelica_Interface="backend");
end OnRelaxation;
