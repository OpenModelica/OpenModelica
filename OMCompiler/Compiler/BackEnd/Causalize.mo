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

encapsulated package Causalize
" file:        Causalize.mo
  package:     Causalize
  description: Causalize contains functions to causalize the equation system.
               This includes algorithms to check if the system is singular,
               match the equations with variables and sorting to BLT-Form."



public import BackendDAE;
public import BackendDAEFunc;
public import DAE;

protected
import AdjacencyMatrix;
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVariable;
import DAEUtil;
import Debug;
import DumpGraphML;
import ElementSource;
import Error;
import Flags;
import List;
import Matching;


protected type DAEHandler = tuple<BackendDAEFunc.StructurallySingularSystemHandlerFunc,String,BackendDAEFunc.stateDeselectionFunc,String>;


/*****************************************
 Singular System check
 *****************************************/

public function singularSystemCheck
"author: Frenkel TUD 2012-06

  Checks that the system is qualified for matching, i.e. that the number of variables
  is the same as the number of equations. If not, the function fails and
  prints an error message.
  If matching options indicate that underconstrained systems are ok, no
  check is performed."
  input Integer nvars;
  input Integer neqns;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input tuple<BackendDAEFunc.matchingAlgorithmFunc,String> matchingAlgorithm;
  input BackendDAE.StructurallySingularSystemHandlerArg arg;
  input BackendDAE.Shared ishared;
  output BackendDAE.EqSystem outSyst;
algorithm
  outSyst := matchcontinue (nvars,neqns,isyst,inMatchingOptions,matchingAlgorithm,arg,ishared)
    local
      String esize_str,vsize_str;

    case (_,_,_,(_,BackendDAE.ALLOW_UNDERCONSTRAINED()),_,_,_)
      then
        singularSystemCheck1(nvars,neqns,isyst,BackendDAE.ALLOW_UNDERCONSTRAINED(),matchingAlgorithm,arg,ishared);

    case (_,_,_,(_,BackendDAE.EXACT()),_,_,_)
      equation
        true = intEq(nvars,neqns);
      then
        singularSystemCheck1(nvars,neqns,isyst,BackendDAE.EXACT(),matchingAlgorithm,arg,ishared);

    case (_,_,_,(_,BackendDAE.EXACT()),_,_,_)
      equation
        true = intGt(nvars,neqns);
        esize_str = intString(neqns);
        vsize_str = intString(nvars);
        Error.addMessage(Error.UNDERDET_EQN_SYSTEM, {esize_str,vsize_str});
        BackendDAEUtil.checkAdjacencyMatrixSolvability(isyst, ishared.functionTree, BackendDAEUtil.isInitializationDAE(ishared));
      then
        fail();

    case (_,_,_,_,_,_,_)
      equation
        true = intLt(nvars,neqns);
        esize_str = intString(neqns) ;
        vsize_str = intString(nvars);
        Error.addMessage(Error.OVERDET_EQN_SYSTEM, {esize_str,vsize_str});
        BackendDAEUtil.checkAdjacencyMatrixSolvability(isyst, ishared.functionTree, BackendDAEUtil.isInitializationDAE(ishared));
      then
        fail();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- Causalize.singularSystemCheck failed\n");
      then
        fail();

  end matchcontinue;
end singularSystemCheck;

//protected import BackendDAETransform;

protected function singularSystemCheck1
"author: Frenkel TUD 2012-12
  check if the system is singular"
  input Integer nVars;
  input Integer nEqns;
  input BackendDAE.EqSystem iSyst;
  input BackendDAE.EquationConstraints eqnConstr;
  input tuple<BackendDAEFunc.matchingAlgorithmFunc,String> matchingAlgorithm;
  input BackendDAE.StructurallySingularSystemHandlerArg arg;
  input BackendDAE.Shared iShared;
  output BackendDAE.EqSystem outSyst = iSyst;
protected
  BackendDAE.AdjacencyMatrix m;
  BackendDAE.AdjacencyMatrixT mT;
  list<list<Integer>> comps;
  array<Integer> ass1,ass2;
  BackendDAEFunc.matchingAlgorithmFunc matchingFunc;
  BackendDAE.EqSystem syst;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  BackendDAE.IndexType indexType;
  Boolean scalar, processed;
algorithm
  BackendDAE.EQSYSTEM(m=SOME(m), mT=SOME(mT), mapping=SOME((mapEqnIncRow, mapIncRowEqn, indexType, scalar, processed))) := iSyst;
  (matchingFunc,_) :=  matchingAlgorithm;
  // get absolute Adjacency Matrix
  m := AdjacencyMatrix.absAdjacencyMatrix(m);
  mT := AdjacencyMatrix.absAdjacencyMatrix(mT);
  // try to match
  syst := BackendDAEUtil.setEqSystMatrices(iSyst, SOME(m), SOME(mT), SOME((mapEqnIncRow, mapIncRowEqn, BackendDAE.ABSOLUTE(), scalar, processed)));
  syst.matching := BackendDAE.NO_MATCHING();
  // do matching
  (syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=ass1, ass2=ass2)), _, _) :=
      matchingFunc(syst, iShared, true, (BackendDAE.INDEX_REDUCTION(), eqnConstr), foundSingularSystem, arg);
  outSyst.matching := BackendDAE.MATCHING(ass1, ass2, {});
  /*
    print("singularSystemCheck:\n");
    BackendDump.printEqSystem(outSyst);
    comps := BackendDAETransform.tarjanAlgorithm(mT,ass2);
    BackendDump.dumpComponentsOLD(comps);
    DumpGraphML.dumpSystem(outSyst,iShared,NONE(),"SingularSystemCheck" + intString(nVars) + ".graphml",false);
  */
  // free states matching information because there it is unkown if the state or the state derivative was matched
  ((_,ass1,ass2)) := BackendVariable.traverseBackendDAEVars(outSyst.orderedVars, freeStateAssignments, (1,ass1,ass2));
end singularSystemCheck1;

protected function freeStateAssignments "unset assignments of statevariables."
  input BackendDAE.Var inVar;
  input tuple<Integer,array<Integer>,array<Integer>> inTpl;
  output BackendDAE.Var outVar;
  output tuple<Integer,array<Integer>,array<Integer>> outTpl;
algorithm
  (outVar,outTpl) := match (inVar,inTpl)
    local
      Integer e,index;
      array<Integer> ass1,ass2;
      BackendDAE.Var var;
    case (var as BackendDAE.VAR(varKind=BackendDAE.STATE()),(index,ass1,ass2))
      equation
        e = ass1[index];
        ass1 = arrayUpdate(ass1,index,-1);
        ass2 = arrayUpdate(ass2,e,-1);
      then (var,(index+1,ass1,ass2));
    case (var,(index,ass1,ass2)) then (var,(index+1,ass1,ass2));
  end match;
end freeStateAssignments;

protected function foundSingularSystem "print error message if the system contains equations"
  input list<list<Integer>> eqns;
  output list<Integer> changedEqns = {};
  input output Integer actualEqn;
  input output BackendDAE.EqSystem isyst;
  input output BackendDAE.Shared ishared;
  input output array<Integer> inAssignments1;
  input output array<Integer> inAssignments2;
  input output BackendDAE.StructurallySingularSystemHandlerArg inArg;
protected
  array<Integer> mapIncRowEqn;
  BackendDAE.EqSystem syst;
  DAE.ElementSource source;
  Integer n;
  list<Integer> unmatched, unmatched1, vars;
  SourceInfo info;
  String eqn_str, var_str;
algorithm
  if not listEmpty(eqns) then
    (_,_,_,mapIncRowEqn,_) := inArg;
    n := BackendDAEUtil.systemSize(isyst);

    // for debugging
    // BackendDump.printEqSystem(isyst);
    // BackendDump.dumpMatching(inAssignments1);
    // BackendDump.dumpMatching(inAssignments2);
    // syst := BackendDAEUtil.setEqSystMatching(isyst, BackendDAE.MATCHING(inAssignments1,inAssignments2,{}));
    // //DumpGraphML.dumpSystem(syst,ishared,NONE(),"SingularSystem" + intString(n) + ".graphml",false);

    // get from scalar eqns indexes the indexes in the equation array
    unmatched := List.flatten(eqns);
    unmatched1 := List.map1r(unmatched,arrayGet,mapIncRowEqn);
    unmatched1 := List.uniqueIntN(unmatched1,arrayLength(mapIncRowEqn));
    eqn_str := BackendDump.dumpMarkedEqns(isyst, List.sort(unmatched1, intGt));
    vars := Matching.getUnassigned(n, inAssignments2, {});
    vars := List.fold1(unmatched,getAssignedVars,inAssignments1,vars);
    var_str := BackendDump.dumpMarkedVars(isyst, List.sort(vars, intGt));
    source := BackendEquation.markedEquationSource(isyst, listHead(unmatched1));
    info := ElementSource.getElementSourceFileInfo(source);

    Error.addSourceMessage(if BackendDAEUtil.isInitializationDAE(ishared) then Error.STRUCTURAL_SINGULAR_INITIAL_SYSTEM else Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,var_str}, info);
    fail();
  end if;
end foundSingularSystem;

protected function getAssignedVars
  input Integer e;
  input array<Integer> ass;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
protected
  Integer i;
  Boolean b;
algorithm
  i := ass[e];
  b := intGt(i,0);
  oAcc := List.consOnTrue(b,i,iAcc);
end getAssignedVars;

annotation(__OpenModelica_Interface="backend");
end Causalize;
