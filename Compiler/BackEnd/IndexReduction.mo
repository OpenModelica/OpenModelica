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

encapsulated package IndexReduction
" file:        IndexReduction.mo
  package:     IndexReduction
  description: IndexReduction contains functions that are needed to perform
               index reduction


"

public import BackendDAE;
public import DAE;

protected
import Absyn;
import AdjacencyMatrix;
import Array;
import BackendDAEEXT;
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendInline;
import BackendVariable;
import BackendVarTransform;
import BaseHashTable;
import ComponentReference;
import Differentiate;
import ElementSource;
import Error;
import ErrorExt;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import Flags;
import HashTable2;
import HashTable3;
import HashTableCG;
import HashTableCrIntToExp;
import Inline;
import InlineArrayEquations;
import List;
import Matching;
import SCode;
import Sorting;
import SymbolicJacobian;
import System;
import Util;


// =============================================================================
// Pantelides index reduction method .
// see:
// C Pantelides, The Consistent Initialization of Differential-Algebraic Systems, SIAM J. Sci. and Stat. Comput. Volume 9, Issue 2, pp. 213–231 (March 1988)
// Soares, R. de P.; Secchi, A. R.: Direct Initialisation and Solution of High-Index DAESystems. in Proceedings of the European Symbosium on Computer Aided Process Engineering - 15, Barcelona, Spain,
// =============================================================================

public function pantelidesIndexReduction "author: Frenkel TUD 2012-04
  Index Reduction algorithm to get a index 1 or 0 system."
  input list<list<Integer>> inEqns; // the MSSS
  input Integer inActualEqn;
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> changedEqns;
  output Integer continueEqn;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> oass1;
  output array<Integer> oass2;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
protected
  array<Integer> markarr;
  Integer size, newsize;
  list<list<Integer>> eqns_1, unassignedStates, unassignedEqns;
algorithm
  if listEmpty(inEqns) then
    Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReduction called with empty list of equations!"});
    if Flags.isSet(Flags.OPT_DAE_DUMP) then
      print("Index reduction done.\n");
    end if;
    fail();
  end if;

  try
    if Flags.isSet(Flags.OPT_DAE_DUMP) then
      print("\n\nIndex reduction:\n");
    end if;

    //  BackendDump.printEqSystem(inSystem);
    //  BackendDump.dumpMatching(inAssignments1);
    //  BackendDump.dumpMatching(inAssignments2);
    //  syst = BackendDAEUtil.setEqSystMatching(inSystem, BackendDAE.MATCHING(inAssignments1, inAssignments2, {}));
    //  dumpSystemGraphML(syst, inShared, NONE(), "ConstrainRevoluteJoint" + intString(listLength(List.flatten(inEqns))) + ".graphml");
    // check by count vars of equations, if len(inEqns) > len(vars) stop because of structural singular system
    ErrorExt.setCheckpoint("Pantelides");
    (eqns_1, unassignedStates, unassignedEqns, _) := minimalStructurallySingularSystem(inEqns, inSystem, inShared, inAssignments1, inAssignments2, inArg);
    size := BackendDAEUtil.systemSize(inSystem);
    ErrorExt.delCheckpoint("Pantelides");
    ErrorExt.setCheckpoint("Pantelides");
    if Flags.isSet(Flags.BLT_DUMP) then
      print("Reduce Index\n");
    end if;
    markarr := arrayCreate(size, -1);
    (osyst, oshared, oass1, oass2, outArg, _) := pantelidesIndexReduction1(unassignedStates, unassignedEqns, inEqns, eqns_1, inActualEqn, inSystem, inShared, inAssignments1, inAssignments2, 1, markarr, inArg, {});
    ErrorExt.rollBack("Pantelides");
    ErrorExt.setCheckpoint("Pantelides");

    // get from inEqns indexes the scalar indexes
    newsize := BackendDAEUtil.systemSize(osyst);
    changedEqns := if newsize>size then List.intRange2(size+1, newsize) else {};
    (changedEqns, continueEqn) := getChangedEqnsAndLowest(newsize, oass2, changedEqns, size);
    ErrorExt.delCheckpoint("Pantelides");

    if Flags.isSet(Flags.OPT_DAE_DUMP) then
      BackendDump.dumpEqSystemShort(osyst, "pantelidesIndexReduction");
      print("Index reduction done.\n");
    end if;
  else
    ErrorExt.delCheckpoint("Pantelides");
    Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReduction failed!"});
    if Flags.isSet(Flags.OPT_DAE_DUMP) then
      print("Index reduction done.\n");
    end if;
    fail();
  end try;
end pantelidesIndexReduction;

public function failIfIndexReduction "author: lochel
  This function is used as dummy index reduction function if no index reduction
  should be performed.
  This function fails if it is called."
  input list<list<Integer>> inEqns;
  output list<Integer> changedEqns = {};
  input output Integer inActualEqn;
  input output BackendDAE.EqSystem inSystem;
  input output BackendDAE.Shared inShared;
  input output array<Integer> inAssignments1;
  input output array<Integer> inAssignments2;
  input output BackendDAE.StructurallySingularSystemHandlerArg inArg;
algorithm
  Error.addCompilerError("Structural singular system detected, but no index reduction method has been selected.");
  fail();
end failIfIndexReduction;

protected function getChangedEqnsAndLowest
  input Integer index;
  input array<Integer> ass2;
  input list<Integer> iAcc;
  input Integer iLowest;
  output list<Integer> oAcc = iAcc;
  output Integer oLowest = iLowest;
algorithm
  for i in index:-1:1 loop
    oAcc := List.consOnTrue(intLt(ass2[i], 1), i, oAcc);
    oLowest := i;
  end for;
end getChangedEqnsAndLowest;

protected function pantelidesIndexReduction1
"author: Frenkel TUD 2012-04
  Index Reduction algorithm to get a index 1 or 0 system."
  input list<list<Integer>> unassignedStates;
  input list<list<Integer>> unassignedEqns;
  input list<list<Integer>> alleqns;
  input list<list<Integer>> iEqns;
  input Integer actualEqn;
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  input Integer mark;
  input array<Integer> markarr;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  input list<tuple<list<Integer>,list<Integer>,list<Integer>>> iNotDiffableMSS;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
  output list<tuple<list<Integer>,list<Integer>,list<Integer>>> oNotDiffableMSS;
algorithm
  (osyst,oshared,outAssignments1,outAssignments2,outArg,oNotDiffableMSS) :=
  matchcontinue (unassignedStates, unassignedEqns, alleqns, iEqns)
    local
      list<Integer> states,eqns,eqns_1,ueqns;
      list<list<Integer>> statelst,ueqnsrest,eqnsrest,eqnsrest_1;
      array<Integer>  ass1,ass2;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      list<tuple<list<Integer>,list<Integer>,list<Integer>>> notDiffableMSS;
    case (_, _, _, {})
      equation
        (syst,shared,ass1,ass2,arg) = handleundifferntiableMSSLst(iNotDiffableMSS,inSystem,inShared,inAssignments1,inAssignments2,inArg);
      then
        (syst,shared,ass1,ass2,arg,{});
    case (states::statelst, ueqns::ueqnsrest, eqns::eqnsrest, eqns_1::eqnsrest_1)
      equation
        (syst,shared,ass1,ass2,arg,notDiffableMSS) =
         pantelidesIndexReductionMSS(states,ueqns,eqns,eqns_1,actualEqn,inSystem,inShared,inAssignments1,inAssignments2,mark,markarr,inArg,iNotDiffableMSS);
        // next MSS
        (syst,shared,ass1,ass2,arg,notDiffableMSS) =
         pantelidesIndexReduction1(statelst,ueqnsrest,eqnsrest,eqnsrest_1,actualEqn,syst,shared,ass1,ass2,mark,markarr,arg,notDiffableMSS);
      then
       (syst,shared,ass1,ass2,arg,notDiffableMSS);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReduction1 failed! Use -d=bltdump to get more information."});
      then
        fail();
  end matchcontinue;
end pantelidesIndexReduction1;

protected function pantelidesIndexReductionMSS
"author: Frenkel TUD 2012-04
  Index Reduction algorithm to get a index 1 or 0 system."
  input list<Integer> unassignedStates;
  input list<Integer> unassignedEqns;
  input list<Integer> alleqns;
  input list<Integer> MSSSeqs;
  input Integer actualEqn;
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  input Integer mark;
  input array<Integer> markarr;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  input list<tuple<list<Integer>,list<Integer>,list<Integer>>> iNotDiffableMSS;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
  output list<tuple<list<Integer>,list<Integer>,list<Integer>>> oNotDiffableMSS;
algorithm
  (osyst,oshared,outAssignments1,outAssignments2,outArg,oNotDiffableMSS):=
  matchcontinue (unassignedStates,unassignedEqns,alleqns,MSSSeqs,actualEqn,inSystem,inShared,inAssignments1,inAssignments2,mark,markarr,inArg,iNotDiffableMSS)
    local
      list<Integer> MSSSeqs1;
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst,orgEqnsLst1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn,ass1,ass2;
      Integer noofeqns;
      BackendDAE.EquationArray eqnsarray;
      BackendDAE.Variables vars;
      list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> eqnstpl;//<originalIdx, SOME<derivedEq>, OrigEq>
      list<tuple<list<Integer>,list<Integer>,list<Integer>>> notDiffableMSS;

    case (_,_,_,_::_,_,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqnsarray),_,_,_,_,_,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,noofeqns),_)
      equation
        // get from scalar eqns indexes the indexes in the equation array
        MSSSeqs1 = List.map1r(MSSSeqs,arrayGet,mapIncRowEqn);
        MSSSeqs1 = List.uniqueIntN(MSSSeqs1,arrayLength(mapIncRowEqn));

        // do not differentiate self generated equations $_DER.x = der(x)
        MSSSeqs1 = List.select1(MSSSeqs1,intLe,noofeqns);
        if Flags.isSet(Flags.BLT_DUMP) then
          print("Differentiate equations in MSSS("+stringDelimitList(List.map(MSSSeqs,intString),",")+"):");
          BackendDump.debuglst(MSSSeqs1,intString," ","\n");
        end if;

        //try to differentiate all equations from the MSSS, eqnstpl is empty if thats not possible
        (eqnstpl, shared) = differentiateEqnsLst(MSSSeqs1,vars,eqnsarray,inShared);
           //print("\ndifferentiated equations: \n"+stringDelimitList(List.map(eqnstpl,eqnstplDebugString),"\n")+"\n\n");

        //try to assemble a system with these differentiated eqs
        (syst,shared,ass1,ass2,orgEqnsLst1,mapEqnIncRow,mapIncRowEqn,notDiffableMSS) = differentiateEqns(eqnstpl,MSSSeqs1,unassignedStates,unassignedEqns,inSystem, shared,inAssignments1,inAssignments2,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,iNotDiffableMSS);
      then
        (syst,shared,ass1,ass2,(so,orgEqnsLst1,mapEqnIncRow,mapIncRowEqn,noofeqns),notDiffableMSS);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReductionMSS failed! Use -d=bltdump to get more information."});
      then
        fail();
  end matchcontinue;
end pantelidesIndexReductionMSS;

protected function eqnstplDebugString"
prints the eqnstpl that contains the information about derived equations from Index Reduction.
author:Waurich"
  input tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation> tpl;
  output String s;
algorithm
  if Util.isSome(Util.tuple32(tpl)) then
    s := "";
  else
    s := BackendDump.equationString(Util.getOption(Util.tuple32(tpl)));
  end if;
  s := "Original Eq "+intString(Util.tuple31(tpl))+": "+s+"\n\t-->"+BackendDump.equationString(Util.tuple33(tpl))+"";
end eqnstplDebugString;


protected function minimalStructurallySingularSystem "author: Frenkel TUD - 2012-04,
  checks if the subset of equations is minimal structurally singular. The
  check is done for all equations and variables and for each subset.
  The number of states must be larger or equal to the number of unmatched
  equations."
  input list<list<Integer>> inEqnsLst;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<list<Integer>> outEqnsLst "subsets without discrete equations";
  output list<list<Integer>> outStateIndxs "states contained in each subset";
  output list<list<Integer>> outunassignedEqns "the unassigned eqns of each subset";
  output list<Integer> discEqns "discrete equations of all subsets";
protected
  list<Integer> unassignedEqns, eqnslst, stateindxs;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  array<Integer> statemark;
  Integer size;
  Boolean b;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns, m=SOME(m)) := syst;
  size := BackendVariable.varsSize(vars);
  statemark := arrayCreate(size, -1);
  // check over all mss
  unassignedEqns := List.flatten(inEqnsLst);
  stateindxs := List.fold2(unassignedEqns, statesInEquations, (m, statemark, 0), inAssignments1, {});
  ((unassignedEqns, eqnslst, discEqns)) := List.fold3(unassignedEqns, unassignedContinuesEqns, vars, inAssignments2, m, ({}, {}, {}));
  b := intGe(listLength(stateindxs), listLength(unassignedEqns));
  singulareSystemError(b, stateindxs, unassignedEqns, eqnslst, syst, shared, inAssignments1, inAssignments2, inArg);
  // check each mss
  (outEqnsLst, outStateIndxs, outunassignedEqns, discEqns) := minimalStructurallySingularSystemMSS(inEqnsLst, syst, shared, inAssignments1, inAssignments2, inArg, statemark, 1, m, vars, {}, {}, {}, {});
end minimalStructurallySingularSystem;

protected function minimalStructurallySingularSystemMSS
"author: Frenkel TUD - 2012-11,
  helper for minimalStructurallySingularSystem"
  input list<list<Integer>> inEqnsLst;
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  input array<Integer> statemark;
  input Integer mark;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.Variables vars;
  input list<list<Integer>> inEqnsLstAcc;
  input list<list<Integer>> inStateIndxsAcc;
  input list<list<Integer>> inUnassEqnsAcc;
  input list<Integer> inDiscEqnsAcc;
  output list<list<Integer>> outEqnsLst;
  output list<list<Integer>> outStateIndxs;
  output list<list<Integer>> outUnassEqnsAcc;
  output list<Integer> outDiscEqns;
algorithm
  (outEqnsLst, outStateIndxs, outUnassEqnsAcc, outDiscEqns) := match(inEqnsLst)
    local
      list<Integer> ilst, unassignedEqns, eqnsLst, discEqns, stateIndxs;
      list<list<Integer>> rest;
      Boolean b;

    case {}
    then (inEqnsLstAcc, inStateIndxsAcc, inUnassEqnsAcc, inDiscEqnsAcc);

    case ilst::rest equation
      // print("Eqns " + stringDelimitList(List.map(ilst, intString), ", ") + "\n");
      ((unassignedEqns, eqnsLst, discEqns)) = List.fold3(ilst, unassignedContinuesEqns, vars, inAssignments2, m, ({}, {}, inDiscEqnsAcc));
      // print("unassignedEqns " + stringDelimitList(List.map(unassignedEqns, intString), ", ") + "\n");
      stateIndxs = List.fold2(ilst, statesInEquations, (m, statemark, mark), inAssignments1, {});
      // print("stateIndxs " + stringDelimitList(List.map(stateIndxs, intString), ", ") + "\n");
      b = intGe(listLength(stateIndxs), listLength(unassignedEqns));
      singulareSystemError(b, stateIndxs, unassignedEqns, eqnsLst, inSystem, inShared, inAssignments1, inAssignments2, inArg);
      (outEqnsLst, outStateIndxs, outUnassEqnsAcc, outDiscEqns) = minimalStructurallySingularSystemMSS(rest, inSystem, inShared, inAssignments1, inAssignments2, inArg, statemark, mark+1, m, vars, eqnsLst::inEqnsLstAcc, stateIndxs::inStateIndxsAcc, unassignedEqns::inUnassEqnsAcc, discEqns);
    then (outEqnsLst, outStateIndxs, outUnassEqnsAcc, outDiscEqns);
  end match;
end minimalStructurallySingularSystemMSS;

protected function singulareSystemError "author: Frenkel TUD 2012-04
  Index Reduction algorithm to get a index 1 or 0 system."
  input Boolean b;
  input list<Integer> unassignedStates;
  input list<Integer> unassignedEqns;
  input list<Integer> eqns;
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
algorithm
  _ := match(b, eqns, inArg)
    local
      list<BackendDAE.Var> varlst;
      list<Integer> eqns1;
      BackendDAE.EqSystem syst;
      array<Integer> mapIncRowEqn;

    // OK
    case (true, _::_, _) then ();

    // Failure
    case (_, {}, (_, _, _, mapIncRowEqn, _)) equation
      if Flags.isSet(Flags.BLT_DUMP) then
        print("Reduce Index failed! Found empty set of continues equations.\nmarked equations:\n");
      end if;
      // get from scalar eqns indexes the indexes in the equation array
      eqns1 = List.map1r(eqns, arrayGet, mapIncRowEqn);
      eqns1 = List.uniqueIntN(eqns1, arrayLength(mapIncRowEqn));
      if Flags.isSet(Flags.BLT_DUMP) then
        print(BackendDump.dumpMarkedEqns(inSystem, eqns1));
      end if;
      syst = BackendDAEUtil.setEqSystMatching(inSystem, BackendDAE.MATCHING(inAssignments1, inAssignments2, {}));
      if Flags.isSet(Flags.BLT_DUMP) then
        BackendDump.printBackendDAE(BackendDAE.DAE({syst}, inShared));
      end if;
      Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.pantelidesIndexReduction failed! Found empty set of continues equations. Use -d=bltdump to get more information."});
    then fail();

    case (false, _::_, (_, _, _, mapIncRowEqn, _)) equation
      if Flags.isSet(Flags.BLT_DUMP) then
        print("Reduce Index failed! System is structurally singulare and cannot handled because number of unassigned continues equations is larger than number of states.\nmarked equations:\n");
        // get from scalar eqns indexes the indexes in the equation array
        BackendDump.debuglst(eqns, intString, " ", "\n");
      end if;
      eqns1 = List.map1r(eqns, arrayGet, mapIncRowEqn);
      eqns1 = List.uniqueIntN(eqns1, arrayLength(mapIncRowEqn));
      if Flags.isSet(Flags.BLT_DUMP) then
        print(BackendDump.dumpMarkedEqns(inSystem, eqns1));
        print("unassgined states:\n");
      end if;
      varlst = List.map1r(unassignedStates, BackendVariable.getVarAt, BackendVariable.daeVars(inSystem));
      if Flags.isSet(Flags.BLT_DUMP) then
        BackendDump.printVarList(varlst);
      end if;
      syst = BackendDAEUtil.setEqSystMatching(inSystem, BackendDAE.MATCHING(inAssignments1, inAssignments2, {}));
      if Flags.isSet(Flags.BLT_DUMP) then
        BackendDump.printBackendDAE(BackendDAE.DAE({syst}, inShared));
      end if;
      Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.pantelidesIndexReduction failed! System is structurally singulare and cannot handled because number of unassigned equations is larger than number of states. Use -d=bltdump to get more information."});
    then fail();
  end match;
end singulareSystemError;

protected function unassignedContinuesEqns
"author: Frenkel TUD - 2012-11,
  check if it is an discrete equation and extract the
  states of the equation.
  Helper for minimalStructurallySingularSystem."
  input Integer eindx;
  input BackendDAE.Variables vars;
  input array<Integer> ass2;
  input BackendDAE.IncidenceMatrix m;
  input tuple<list<Integer>,list<Integer>,list<Integer>> inFold;
  output tuple<list<Integer>,list<Integer>,list<Integer>> outFold;
algorithm
  outFold := matchcontinue(inFold)
    local
      Integer vindx;
      list<Integer> unassignedEqns,eqnsLst,varlst,discEqns;
      list<BackendDAE.Var> vlst;
      Boolean b,ba;
/*    case((unassignedEqns,eqnsLst))
      equation
        vindx = ass2[eindx];
        true = intGt(vindx,0);
        v = BackendVariable.getVarAt(vars, vindx);
        b = BackendVariable.isVarDiscrete(v);
        eqnsLst = List.consOnTrue(not b, eindx, eqnsLst);
      then
       ((unassignedEqns,eqnsLst));
*/    case((unassignedEqns,eqnsLst,discEqns))
      equation
        vindx = ass2[eindx];
        ba = intLt(vindx,1);
        varlst = m[eindx];
        varlst = List.map(varlst,intAbs);
        vlst = List.map1r(varlst,BackendVariable.getVarAt,vars);
        // if there is a continues variable then b is false
        b = List.mapBoolAnd(vlst,BackendVariable.isVarDiscrete);
        eqnsLst = List.consOnTrue(not b, eindx, eqnsLst);
        unassignedEqns = List.consOnTrue(ba and not b, eindx, unassignedEqns);
        discEqns = List.consOnTrue(b, eindx, discEqns);
      then
       ((unassignedEqns,eqnsLst,discEqns));
    case((unassignedEqns,eqnsLst,discEqns))
      equation
        vindx = ass2[eindx];
        false = intGt(vindx,0);
      then
       ((eindx::unassignedEqns,eindx::eqnsLst,discEqns));
  end matchcontinue;
end unassignedContinuesEqns;

protected function statesInEquations
"author: Frenkel TUD 2012-04"
  input Integer eindx;
  input tuple<BackendDAE.IncidenceMatrix,array<Integer>,Integer> inTpl;
  input array<Integer> ass1;
  input list<Integer> inStateLst;
  output list<Integer> outStateLst;
protected
  list<Integer> vars;
  BackendDAE.IncidenceMatrix m;
  array<Integer> statemark;
  Integer mark;
algorithm
  (m,statemark,mark) := inTpl;
  // get States;
  vars := List.removeOnTrue(0, intLt, m[eindx]);
  // get unassigned
//  vars := List.removeOnTrue(ass1, Matching.isUnAssigned, vars);
  vars := List.map(vars,intAbs);
  vars := List.removeOnTrue((statemark,mark), isMarked, vars);
  _ := List.fold1(vars, markTrue, mark, statemark);
  // add states to list
  outStateLst := listAppend(inStateLst,vars);
end statesInEquations;

protected function isMarked
"author: Frenkel TUD 2012-05"
  input tuple<array<Integer>,Integer> ass;
  input Integer indx;
  output Boolean b;
protected
  array<Integer> arr;
  Integer mark;
algorithm
  (arr,mark) := ass;
  b := intEq(arr[intAbs(indx)],mark);
end isMarked;

protected function markTrue
"author: Frenkel TUD 2012-05"
  input Integer indx;
  input Integer mark;
  input output array<Integer> arr;
algorithm
  _ := arrayUpdate(arr,intAbs(indx),mark);
end markTrue;

protected function differentiateEqns
"author: Frenkel TUD 2011-05
  differentiates the constraint equations for
  Pantelides index reduction method."
  input list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> inEqnsTpl;
  input list<Integer> MSSSeqs;
  input list<Integer> unassignedStates;
  input list<Integer> unassignedEqns;
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  input BackendDAE.ConstraintEquations inOrgEqnsLst;
  input array<list<Integer>> imapEqnIncRow;
  input array<Integer> imapIncRowEqn;
  input list<tuple<list<Integer>,list<Integer>,list<Integer>>> iNotDiffableMSS;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.ConstraintEquations outOrgEqnsLst;
  output array<list<Integer>> omapEqnIncRow;
  output array<Integer> omapIncRowEqn;
  output list<tuple<list<Integer>,list<Integer>,list<Integer>>> oNotDiffableMSS;
protected
  BackendDAE.EqSystem syst;
  BackendDAE.EquationArray eqns_1, eqns;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrix mt;
  BackendDAE.Variables v, v1;
  DAE.FunctionTree funcs;
  Integer numEqs, numEqs1;
  list<Integer> changedVars, eqnslst, eqnslst1, assEqs;
algorithm
  if listEmpty(inEqnsTpl) then
    // not all equations are differentiated
    osyst := inSystem;
    oshared := inShared;
    outAss1 := inAss1;
    outAss2 := inAss2;
    outOrgEqnsLst := inOrgEqnsLst;
    omapEqnIncRow := imapEqnIncRow;
    omapIncRowEqn := imapIncRowEqn;
    oNotDiffableMSS := (MSSSeqs,unassignedStates,unassignedEqns)::iNotDiffableMSS;
  else
    // all equations are differentiated
    syst := inSystem;
    BackendDAE.EQSYSTEM(orderedVars=v, orderedEqs=eqns, m=SOME(m), mT=SOME(mt)) := syst;
    numEqs := BackendEquation.getNumberOfEquations(eqns);
    (v1,eqns_1,changedVars,outOrgEqnsLst) := replaceDifferentiatedEqns(inEqnsTpl,v,eqns,mt,imapIncRowEqn,{},inOrgEqnsLst);
    numEqs1 := BackendEquation.getNumberOfEquations(eqns_1);
    eqnslst := if intGt(numEqs1,numEqs) then List.intRange2(numEqs+1,numEqs1) else {};
    // set the assignments for the changed vars and for the assigned equations to -1
    assEqs := List.map1r(changedVars,arrayGet,inAss1);
    assEqs := List.select1(assEqs,intGt,0);
    outAss2 := List.fold1r(assEqs,arrayUpdate,-1,inAss2);
    outAss1 := List.fold1r(changedVars,arrayUpdate,-1,inAss1);
    //get adjacent equations for the changed vars
    eqnslst1 := collectVarEqns(changedVars,mt,arrayLength(mt),arrayLength(m));
    syst.orderedVars := v1;
    syst.orderedEqs := eqns_1;
    eqnslst1 := List.map1r(eqnslst1,arrayGet,imapIncRowEqn);
    eqnslst1 :=  List.uniqueIntN(listAppend(MSSSeqs,eqnslst1),numEqs1);
    eqnslst1 := listAppend(eqnslst1,eqnslst);
    if Flags.isSet(Flags.BLT_DUMP) then
      print("Update Incidence Matrix: ");
      BackendDump.debuglst(eqnslst1,intString," ","\n");
    end if;
    funcs := BackendDAEUtil.getFunctions(inShared);
    (syst,omapEqnIncRow,omapIncRowEqn) :=
      BackendDAEUtil.updateIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs), eqnslst1, imapEqnIncRow, imapIncRowEqn);
    osyst := syst;
    oshared := inShared;
    oNotDiffableMSS := iNotDiffableMSS;
  end if;
end differentiateEqns;

protected function collectVarEqns
"author: Frenkel TUD 2011-05, waurich 12-15
  collect all equations of a list with var indexes"
  input list<Integer> varIdcsIn;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer numVars;
  input Integer numEqs "size of equations array, maximal entry in inMT";
  output list<Integer> eqIdcsOut = {};
protected
  Integer varIdx;
  list<Integer> eqIdcs;
algorithm
  for varIdx in varIdcsIn loop
    if intLt(varIdx,numVars) then
      eqIdcs := List.map(mT[varIdx],intAbs);
      eqIdcsOut := listAppend(eqIdcs,eqIdcsOut);
    end if;
  end for;
  eqIdcsOut := List.uniqueIntN(eqIdcsOut,numEqs);
end collectVarEqns;

protected function searchDerivativesExp "author: Frenkel TUD 2012-11"
  input DAE.Exp inExp;
  input tuple<list<Integer>,BackendDAE.Variables> tpl;
  output DAE.Exp outExp;
  output tuple<list<Integer>,BackendDAE.Variables> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,tpl)
    local
      BackendDAE.Variables vars;
      list<Integer> ilst,i1lst;
      DAE.Exp e;
      DAE.ComponentRef cr;
    case (e as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr)}),(ilst,vars))
      equation
        (_,i1lst) = BackendVariable.getVar(cr,vars);
        ilst = List.fold1(i1lst,List.removeOnTrue, intEq, ilst);
      then (e,(ilst,vars));
    else (inExp,tpl);
  end matchcontinue;
end searchDerivativesExp;


protected function differentiateEqnsLst
"differentiates the constraint equations for
  Pantelides index reduction method. waurich: if one of these equation cannot be derived, output an empty list -> not differentiable MSS"
  input list<Integer> inEqns;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.Shared inShared;
  output list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> outEqnTpl; //<originalIdx, SOME<derivedEq>, OrigEq>
  output BackendDAE.Shared oShared;
protected
  Integer e;
  list<Integer> eqs;
  Option<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> eqTplOpt;
algorithm
  outEqnTpl := {};
  oShared := inShared;
  eqs := inEqns;
  while not listEmpty(eqs) loop
    e::eqs := eqs;
      (eqTplOpt, oShared) := differentiateEqnsLst1(e,vars,eqns,oShared);
      if Util.isSome(eqTplOpt) then
         outEqnTpl := Util.getOption(eqTplOpt)::outEqnTpl;
      else
        outEqnTpl := {};
        oShared := inShared;
       return;
      end if;
  end while;
end differentiateEqnsLst;

protected function differentiateEqnsLst1
"author: Frenkel TUD 2012-11
  differentiates the constraint equations for
  Pantelides index reduction method."
  input Integer eqIdx;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.Shared inShared;
  output Option<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> oEqTpl;
  output BackendDAE.Shared oshared;
protected
  BackendDAE.Equation eqn;
  Option<BackendDAE.Equation> diffEqn;
algorithm
  eqn := BackendEquation.get(eqns, eqIdx);

  if BackendEquation.isDifferentiated(eqn) then
    if Flags.isSet(Flags.BLT_DUMP) then
      BackendDump.debugStrEqnStr("Skip already differentiated equation\n",eqn,"\n");
    end if;
    oEqTpl := SOME((eqIdx, NONE(), eqn));
    oshared := inShared;
  else
    //if Flags.isSet(Flags.BLT_DUMP) then print("differentiate equation " + intString(eqIdx) + " " + BackendDump.equationString(eqn) + "\n"); end if;
    (diffEqn, oshared) := Differentiate.differentiateEquationTime(eqn, vars, inShared);
    //if Flags.isSet(Flags.BLT_DUMP) then print("differentiated equation " + intString(eqIdx) + " " + BackendDump.equationString(diffEqn) + "\n"); end if;
    eqn := BackendEquation.markDifferentiated(eqn);

    if isSome(diffEqn) then
      oEqTpl := SOME((eqIdx, diffEqn, eqn));
    else
      oEqTpl := NONE();
      oshared := inShared;
    end if;
  end if;
end differentiateEqnsLst1;

protected function replaceDifferentiatedEqns
"author: Frenkel TUD 2012-11, waurich 2015-12
  replace the original equations with the derived, updated var-types, stores all former equations in inOrgEqnsLst"
  input list<tuple<Integer, Option<BackendDAE.Equation>, BackendDAE.Equation>> inEqnTplLst; //<origIdx, SOME<derivedEq>, original Eq>
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.IncidenceMatrix mt;
  input array<Integer> imapIncRowEqn;
  input list<Integer> inChangedVars;
  input BackendDAE.ConstraintEquations inOrgEqns;
  output BackendDAE.Variables outVars;
  output BackendDAE.EquationArray outEqns;
  output list<Integer> outChangedVars;
  output BackendDAE.ConstraintEquations outOrgEqns;
protected
  Integer eqIdx;
  list<Integer> changedVars;
  BackendDAE.Equation eqOrig, eqDiff;
  tuple<Integer, Option<BackendDAE.Equation>, BackendDAE.Equation> eqTpl;
algorithm
  outVars := vars;
  outEqns := eqns;
  outChangedVars := inChangedVars;
  outOrgEqns := inOrgEqns;
  for eqTpl in inEqnTplLst loop
    if Util.isSome(Util.tuple32(eqTpl)) then
      // replace der-calls with the derivatives
      (eqIdx, SOME(eqDiff), eqOrig) := eqTpl;
      (eqDiff, _) := BackendEquation.traverseExpsOfEquation(eqDiff, replaceStateOrderExp, outVars);
      // change the variable types (algebraic -> state, 1.der -> 2.der, ...)
      (eqDiff, (_, (outVars, outEqns, outChangedVars, _, _, _))) := BackendEquation.traverseExpsOfEquation(eqDiff, Expression.traverseSubexpressionsHelper, (changeDerVariablesToStatesFinder, (outVars, outEqns, outChangedVars, eqIdx, imapIncRowEqn, mt)));
        if Flags.isSet(Flags.BLT_DUMP) then
          print("replaced differentiated eqs:");
          debugdifferentiateEqns((eqOrig, eqDiff));
        end if;
      outEqns := BackendEquation.setAtIndex(outEqns, eqIdx, eqDiff);
      //collect original equations
      outOrgEqns := addOrgEqn(eqIdx, eqOrig, outOrgEqns);
    end if;
  end for;
end replaceDifferentiatedEqns;

protected function replaceStateOrderExp
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  output DAE.Exp e;
  output BackendDAE.Variables vars;
algorithm
  (e, vars) := Expression.traverseExpTopDown(inExp, replaceStateOrderExpFinder, inVars);
end replaceStateOrderExp;

protected function replaceStateOrderExpFinder
"author: Frenkel TUD 2011-05 "
  input DAE.Exp inExp;
  input BackendDAE.Variables inVars;
  output DAE.Exp outExp;
  output Boolean cont;
  output BackendDAE.Variables outVars;
algorithm
  (outExp,cont,outVars) := matchcontinue (inExp,inVars)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef dcr,cr;
      DAE.CallAttributes attr;
      Integer index;
      //if der(x) = y, replace all der(x) with y
     case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars)
      equation
        (BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(dcr))),_) = BackendVariable.getVarSingle(cr,vars);
        e = Expression.crefExp(dcr);
      then
        (e,false,vars);
     case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr),DAE.ICONST(index)},attr=attr),vars)
      equation
        true = intEq(index,2);
        (BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(dcr))),_) = BackendVariable.getVarSingle(cr,vars);
        e = Expression.crefExp(dcr);
      then
        (DAE.CALL(Absyn.IDENT("der"),{e},attr),false,vars);
     case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})},attr=attr),vars)
      equation
        (BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(dcr))),_) = BackendVariable.getVarSingle(cr,vars);
        e = Expression.crefExp(dcr);
      then
        (DAE.CALL(Absyn.IDENT("der"),{e},attr),false,vars);
     case (e,vars) then (e,true,vars);
  end matchcontinue;
end replaceStateOrderExpFinder;

protected function statesWithUnusedDerivative
"author Frenkel TUD 2012-11
  add to iAcc all states with no positiv rows in mt"
  input Integer state;
  input BackendDAE.IncidenceMatrix mt;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
algorithm
  oAcc := matchcontinue(state)
    case(_)
      equation
        List.map1AllValue(mt[state], intLt, true, 0);
      then
        state::iAcc;
    else iAcc;
  end matchcontinue;
end statesWithUnusedDerivative;

protected function isStateonIndex
  input Integer index;
  input BackendDAE.Variables vars;
  output Boolean b;
protected
  BackendDAE.Var v;
algorithm
  v := BackendVariable.getVarAt(vars,index);
  b := BackendVariable.isStateVar(v);
end isStateonIndex;

protected function handleundifferntiableMSSLst
"author: Frenkel TUD 2012-12
  handle list of undifferentiatable equations for
  Pantelides index reduction method."
  input list<tuple<list<Integer>,list<Integer>,list<Integer>>> iNotDiffableMSS;
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  input BackendDAE.StructurallySingularSystemHandlerArg iArg;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.StructurallySingularSystemHandlerArg oArg;
algorithm
  (osyst,oshared,outAss1,outAss2,oArg):=
  match (iNotDiffableMSS,inSystem,inShared,inAss1,inAss2,iArg)
    local
      list<tuple<list<Integer>,list<Integer>,list<Integer>>> notDiffableMSS;
      list<Integer> unassignedEqns,unassignedStates,eqns,ilst;
      BackendDAE.Variables v;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;
      Integer noofeqns;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.IncidenceMatrixT mt;
      array<Integer> ass1,ass2;
    case ({},_,_,_,_,_)
      then (inSystem,inShared,inAss1,inAss2,iArg);
    case ((eqns,unassignedStates,unassignedEqns)::notDiffableMSS,BackendDAE.EQSYSTEM(orderedVars=v,mT=SOME(mt)),_,_,_,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,noofeqns))
      equation
        if Flags.isSet(Flags.BLT_DUMP) then
          print("not differentiable minimal singular subset:\n");
          print("unassignedEqns:\n");
          BackendDump.debuglst(unassignedEqns, intString, ", ", "\n");
          print("unassignedStates:\n");
          BackendDump.debuglst(unassignedStates,intString, ", ", "\n");
        end if;
        ilst = List.fold1(unassignedStates, statesWithUnusedDerivative, mt, {});
        ilst = List.select1(ilst, isStateonIndex, v);
        // check also initial equations (this could be done also once before)
        ((_,(ilst,_))) = BackendDAEUtil.traverseBackendDAEExpsEqns(BackendEquation.getInitialEqnsFromShared(inShared),Expression.traverseSubexpressionsHelper,(searchDerivativesExp,(ilst,v)));
        if Flags.isSet(Flags.BLT_DUMP) then
          print("states without used derivative:\n");
          BackendDump.debuglst(ilst,intString,", ","\n");
        end if;
        (syst,shared,ass1,ass2,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn) =
          handleundifferntiableMSS(intLe(listLength(ilst),listLength(unassignedEqns)),ilst,eqns,unassignedStates,unassignedEqns,inSystem,inShared,inAss1,inAss2,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn);
        (syst,shared,ass1,ass2,arg) = handleundifferntiableMSSLst(notDiffableMSS,syst,shared,ass1,ass2,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,noofeqns));
      then
        (syst,shared,ass1,ass2,arg);
  end match;
end handleundifferntiableMSSLst;

protected function handleundifferntiableMSS
"author: Frenkel TUD 2012-11
  try to solve a undifferentiable MSS."
  input Boolean b "true if length(unassignedEqns) == length(statesWithUnusedDerivative)";
  input list<Integer> statesWithUnusedDer;
  input list<Integer> inEqns;
  input list<Integer> unassignedStates;
  input list<Integer> unassignedEqns;
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.ConstraintEquations inOrgEqnsLst;
  input array<list<Integer>> imapEqnIncRow;
  input array<Integer> imapIncRowEqn;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.StateOrder outStateOrd;
  output BackendDAE.ConstraintEquations outOrgEqnsLst;
  output array<list<Integer>> omapEqnIncRow;
  output array<Integer> omapIncRowEqn;
algorithm
  (osyst,oshared,outAss1,outAss2,outStateOrd,outOrgEqnsLst,omapEqnIncRow,omapIncRowEqn):=
  matchcontinue (b,statesWithUnusedDer,inEqns,unassignedStates,unassignedEqns,inSystem)
    local
      Integer i;
      BackendDAE.EquationArray eqns;
      list<Integer> ilst, eqnslst, eqnslst1;
      BackendDAE.Variables v,v1;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
      BackendDAE.EqSystem syst;
      array<Integer> ass1, ass2, mapIncRowEqn;
      array<list<Integer>> mapEqnIncRow;
      list<BackendDAE.Var> varlst;
      BackendDAE.Var var;
      DAE.FunctionTree funcs;
    // 1th try to replace final parameter
    case (_,_,_,_,_,syst as BackendDAE.EQSYSTEM(m=SOME(_), mT=SOME(_)))
      equation
        ((eqns, eqnslst as _::_, _)) = List.fold1( inEqns, replaceFinalVars, BackendVariable.daeGlobalKnownVars(inShared),
                                                   (syst.orderedEqs, {}, BackendVarTransform.emptyReplacements()));
        syst.orderedEqs = eqns;
        // unassign changed equations and assigned vars
        eqnslst1 = List.flatten(List.map1r(eqnslst, arrayGet, imapEqnIncRow));
        ilst = List.map1r(eqnslst1, arrayGet, inAss2);
        ilst = List.select1(ilst, intGt, 0);
        ass2 = List.fold1r(eqnslst1, arrayUpdate, -1, inAss2);
        ass1 = List.fold1r(ilst, arrayUpdate, -1, inAss1);
        // update IncidenceMatrix
        if Flags.isSet(Flags.BLT_DUMP) then
          print("Replaced final Parameter in Eqns\n");
          print("Update Incidence Matrix: ");
          BackendDump.debuglst(eqnslst, intString, " ", "\n");
        end if;
        funcs = BackendDAEUtil.getFunctions(inShared);
        (syst, mapEqnIncRow, mapIncRowEqn) =
            BackendDAEUtil.updateIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs), eqnslst, imapEqnIncRow, imapIncRowEqn);
      then
        (syst, inShared, ass1, ass2, inStateOrd, inOrgEqnsLst, mapEqnIncRow, mapIncRowEqn);

    // if size of unmatched eqns is equal to size of states without used derivative change all to algebraic
    case (true,_::_,_,_,_,syst as BackendDAE.EQSYSTEM(orderedVars=v, m=SOME(m), mT=SOME(mt)))
      equation
        // change varKind
        varlst = List.map1r(statesWithUnusedDer,BackendVariable.getVarAt,v);
        if Flags.isSet(Flags.BLT_DUMP) then
          print("Change varKind to algebraic for\n");
          BackendDump.printVarList(varlst);
        end if;
        varlst = BackendVariable.setVarsKind(varlst, BackendDAE.VARIABLE());
        syst.orderedVars = BackendVariable.addVars(varlst, syst.orderedVars);
        // update IncidenceMatrix
        eqnslst1 = collectVarEqns(statesWithUnusedDer, mt, arrayLength(mt), arrayLength(m));
        eqnslst1 = List.map1r(eqnslst1, arrayGet, imapIncRowEqn);
        if Flags.isSet(Flags.BLT_DUMP) then
          print("Update Incidence Matrix: ");
          BackendDump.debuglst(eqnslst1,intString," ","\n");
        end if;
        funcs = BackendDAEUtil.getFunctions(inShared);
        (syst,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.updateIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs), eqnslst1, imapEqnIncRow, imapIncRowEqn);
      then
        (syst,inShared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,mapEqnIncRow,mapIncRowEqn);

/* Debugging case
    case (false,_,_,_,_,BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching,stateSets))
      equation
        varlst = BackendEquation.equationsLstVars(notDiffedEquations,v);
        varlst = List.select(varlst,BackendVariable.isStateVar);
        fcall(Flags.BLT_DUMP, print, "state vars of undiffed Eqns\n");
        fcall(Flags.BLT_DUMP, BackendDump.printVarList, varlst);

        syst = BackendDAEUtil.setEqSystMatching(inSystem,BackendDAE.MATCHING(inAss1,inAss2,{}));
        dumpSystemGraphML(syst,inShared,NONE(),"test.graphml");
      then
        fail();
*/

    // if size of unmatched eqns is not equal to size of states without used derivative change first to algebraic
    // until I have a better sulution
    case (false,i::ilst,_,_,_,syst as BackendDAE.EQSYSTEM(orderedVars=v, m=SOME(m), mT=SOME(mt)))
      equation
        // change varKind
        var = BackendVariable.getVarAt(v,i);
        varlst = {var};
        if Flags.isSet(Flags.BLT_DUMP) then
          print("Change varKind to algebraic for\n");
          BackendDump.printVarList(varlst);
        end if;
        varlst = BackendVariable.setVarsKind(varlst,BackendDAE.VARIABLE());
        syst.orderedVars = BackendVariable.addVars(varlst, v);
        if Flags.isSet(Flags.BLT_DUMP) then
          varlst = List.map1r(ilst, BackendVariable.getVarAt, v);
          print("Other Candidates are\n");
          BackendDump.printVarList(varlst);
        end if;
        // update IncidenceMatrix
        eqnslst1 = collectVarEqns({i}, mt, arrayLength(mt), arrayLength(m));
        eqnslst1 = List.map1r(eqnslst1, arrayGet, imapIncRowEqn);
        if Flags.isSet(Flags.BLT_DUMP) then
          print("Update Incidence Matrix: ");
          BackendDump.debuglst(eqnslst1,intString," ","\n");
        end if;
        funcs = BackendDAEUtil.getFunctions(inShared);
        (syst,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.updateIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs), eqnslst1, imapEqnIncRow, imapIncRowEqn);
      then
        (syst,inShared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,mapEqnIncRow,mapIncRowEqn);

    // if no state with unused derivative is in the set check global
    case (_,{},_,_,_,BackendDAE.EQSYSTEM(orderedVars=v, m=SOME(_), mT=SOME(mt)))
      equation
        ilst = Matching.getUnassigned(BackendVariable.varsSize(v), inAss1, {});
        ilst = List.fold1(ilst, statesWithUnusedDerivative, mt, {});
        varlst = List.map1r(ilst,BackendVariable.getVarAt,v);
        // check also initial equations (this could be done alse once before
        ((_,(ilst,_))) = BackendDAEUtil.traverseBackendDAEExpsEqns(BackendEquation.getInitialEqnsFromShared(inShared),Expression.traverseSubexpressionsHelper,(searchDerivativesExp,(ilst,v)));
        // check if there are states with unused derivative
        _::_ = ilst;
        if Flags.isSet(Flags.BLT_DUMP) then
          print("All unassignedStates without Derivative: " + stringDelimitList(List.map(ilst,intString),", ")  + "\n");
          BackendDump.printVarList(varlst);
        end if;
        (syst,oshared,outAss1,outAss2,outStateOrd,outOrgEqnsLst,omapEqnIncRow,omapIncRowEqn) = handleundifferntiableMSS(intLe(listLength(ilst),listLength(unassignedEqns)),ilst,inEqns,unassignedStates,unassignedEqns,inSystem,inShared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,imapEqnIncRow,imapIncRowEqn);
      then
        (syst,oshared,outAss1,outAss2,outStateOrd,outOrgEqnsLst,omapEqnIncRow,omapIncRowEqn);

    case (_,_,_,_,_,BackendDAE.EQSYSTEM(orderedVars=v, m=SOME(_), mT=SOME(_)))
      equation
        varlst = List.map1r(unassignedStates,BackendVariable.getVarAt,v);
        if Flags.isSet(Flags.BLT_DUMP) then
          print("unassignedStates\n");
          BackendDump.printVarList(varlst);
        end if;

        //  syst = BackendDAEUtil.setEqSystMatching(inSystem,BackendDAE.MATCHING(inAss1,inAss2,{}));
        //  dumpSystemGraphML(syst,inShared,NONE(),"IndexReductionFailed.graphml");
      then
        fail();
  end matchcontinue;
end handleundifferntiableMSS;

protected function replaceFinalVars
  input Integer e;
  input BackendDAE.Variables vars;
  input tuple<BackendDAE.EquationArray, list<Integer>, BackendVarTransform.VariableReplacements> inTpl;
  output tuple<BackendDAE.EquationArray, list<Integer>, BackendVarTransform.VariableReplacements> outTpl;
protected
  BackendDAE.EquationArray eqns;
  list<Integer> changedEqns;
  BackendDAE.Equation eqn;
  Boolean b;
  BackendVarTransform.VariableReplacements repl;
algorithm
  (eqns, changedEqns, repl) := inTpl;
  // get the equation
  eqn := BackendEquation.get(eqns, e);
  // reaplace final vars
  (eqn, (_, b, repl)) := BackendEquation.traverseExpsOfEquation(eqn, replaceFinalVarsEqn, (vars, false, repl));
  // if replaced set eqn
  eqns := if b then BackendEquation.setAtIndex(eqns, e, eqn) else eqns;
  changedEqns := List.consOnTrue(b, e, changedEqns);
  outTpl := (eqns, changedEqns, repl);
end replaceFinalVars;

protected function replaceFinalVarsEqn
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,Boolean,BackendVarTransform.VariableReplacements> inTpl;
  output DAE.Exp e;
  output tuple<BackendDAE.Variables,Boolean,BackendVarTransform.VariableReplacements> tpl;
protected
  BackendDAE.Variables vars;
  Boolean b;
  BackendVarTransform.VariableReplacements repl;
algorithm
  (e,tpl as (_,b,_)) := Expression.traverseExpBottomUp(inExp,replaceFinalVarsExp,inTpl);
  (e,_) := ExpressionSimplify.condsimplify(b,e);
end replaceFinalVarsEqn;

protected function replaceFinalVarsExp "
Author: Frenkel TUD 2012-11
replace final parameter."
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,Boolean,BackendVarTransform.VariableReplacements> inTpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,Boolean,BackendVarTransform.VariableReplacements> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      list<BackendDAE.Var> vlst;
      DAE.Exp e,e2;
      BackendVarTransform.VariableReplacements repl;

    case (e as DAE.CREF(componentRef=cr), (vars,_,repl))
      equation
        (vlst as _::_,_) = BackendVariable.getVar(cr,vars);
        (repl,true) = List.fold20(vlst,replaceFinalVarsGetExp,repl,false);
        (e2,true) = BackendVarTransform.replaceExp(e,repl,NONE());
      then (e2, (vars,true,repl));
    else (inExp,inTpl);
  end matchcontinue;
end replaceFinalVarsExp;

protected function replaceFinalVarsGetExp
"author: Frenkel TUD 2012-11"
 input BackendDAE.Var inVar;
 input output BackendVarTransform.VariableReplacements repl;
 input output Boolean b;
algorithm
  (repl, b) := matchcontinue (inVar)
    local
      BackendVarTransform.VariableReplacements repl1;
      DAE.ComponentRef cr;
      Option< .DAE.VariableAttributes> values;
      DAE.Exp exp;

    case (BackendDAE.VAR(varName=cr,bindExp=SOME(exp)))
      guard BackendVariable.isFinalVar(inVar)
      equation
        repl1 = BackendVarTransform.addReplacement(repl,cr,exp,NONE());
    then
      (repl1,true);

    case (BackendDAE.VAR(varName=cr,bindExp=NONE(),values=values))
      guard BackendVariable.isFinalVar(inVar)
      equation
        exp = DAEUtil.getStartAttrFail(values);
        repl1 = BackendVarTransform.addReplacement(repl,cr,exp,NONE());
    then
      (repl1,true);

    else (repl, b);
  end matchcontinue;
end replaceFinalVarsGetExp;

public function getStructurallySingularSystemHandlerArg
"author: Frenkel TUD 2012-04
  return initial the StructurallySingularSystemHandlerArg."
  input BackendDAE.EqSystem inSystem "updates the state differentation indexes";
  input BackendDAE.Shared inShared;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
protected
  HashTableCG.HashTable ht;
  HashTable3.HashTable dht;
  BackendDAE.StateOrder so;
  BackendDAE.EquationArray eqns;
  Integer count;
algorithm
  if Config.getIndexReductionMethod()=="uode" then
    // Disabled state selection, so do not allocate expensive tables
    so := BackendDAE.NOSTATEORDER();
  else
    // Get a rough count of number of states before allocating the table
    // TODO: Only allocate the table once and clear it for each new matching. Currently, the same variables are allocated over and over again.
    count := integer(/* 8/3 determined by scientifically guessing */ (8/3)*BackendVariable.getNumStateVarFromVariables(inSystem.orderedVars));
    if count==0 then
      so := BackendDAE.NOSTATEORDER();
    else
      ht := HashTableCG.emptyHashTableSized(count);
      dht := HashTable3.emptyHashTableSized(count);
      so := BackendDAE.STATEORDER(ht,dht);
    end if;
  end if;
  eqns := BackendEquation.getEqnsFromEqSystem(inSystem);
  if Flags.isSet(Flags.BLT_DUMP) then
    BackendDump.dumpStateOrder(so);
  end if;
  outArg := (so,arrayCreate(BackendEquation.getNumberOfEquations(eqns),{}),mapEqnIncRow,mapIncRowEqn,BackendEquation.getNumberOfEquations(eqns));
end getStructurallySingularSystemHandlerArg;

// =============================================================================
// No State deselection Method.
// use the index 1/0 system as it is
// =============================================================================

public function noStateDeselection "author: Frenkel TUD 2012-04
  use the index 1/0 system as it is"
  input BackendDAE.BackendDAE inDAE;
  input list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> inArgs;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := inDAE;
end noStateDeselection;

// =============================================================================
// dynamic state selection method
// see
// - Mattsson, S.E.; Söderlind, G.: A new technique for solving high-index differential-algebraic equations using dummy derivatives, Computer-Aided Control System Design, 1992. (CACSD),1992 IEEE Symposium on , pp.218-224, 17-19 Mar 1992
// - Mattsson, S.E.; Olsson, H; Elmqviste, H. Dynamic Selection of States in Dymola. In: Proceedings of the Modelica Workshop 2000, Lund, Sweden, Modelica Association, 23-24 Oct. 2000.
// - Mattsson, S.; Söderlind, G.: Index reduction in differential-Algebraic equations using dummy derivatives, SIAM J. Sci. Comput. 14, 677-692, 1993.
// =============================================================================

public function dynamicStateSelection
  input BackendDAE.BackendDAE inDAE;
  input list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> inArgs;
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
  HashTableCrIntToExp.HashTable ht;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  // do state selection
  ht := HashTableCrIntToExp.emptyHashTable();
  (systs, shared, ht) := dynamicStateSelection_mapEqsystem(systs, shared, inArgs, 1, ht);
  if intGt(BaseHashTable.hashTableCurrentSize(ht), 0) then
    (systs, shared) :=  List.map1Fold(systs, replaceDummyDerivatives, ht, shared);
  end if;
  outDAE := BackendDAE.DAE(systs, shared);
end dynamicStateSelection;

protected function dynamicStateSelection_mapEqsystem
"Run the state selection Algorithm."
  input list<BackendDAE.EqSystem> isysts;
  input BackendDAE.Shared inShared;
  input list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> iargs;
  input Integer setIndex;
  input HashTableCrIntToExp.HashTable iHt;
  output list<BackendDAE.EqSystem> osysts = {};
  output BackendDAE.Shared oshared = inShared;
  output HashTableCrIntToExp.HashTable oHt = iHt;
protected
  BackendDAE.EqSystem syst_;
  Option<BackendDAE.StructurallySingularSystemHandlerArg> oarg;
  BackendDAE.StructurallySingularSystemHandlerArg arg;
  list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> args = iargs;
  Integer index = setIndex;
algorithm
  for syst in isysts loop
    oarg :: args := args;
    if isSome(oarg) then
       SOME(arg) := oarg;
      (syst_, oshared, oHt, index) := dynamicStateSelectionWork(syst, oshared, arg, oHt, index);
       osysts := syst_ :: osysts;
    else
      osysts := syst :: osysts;
    end if;
  end for;
  osysts := MetaModelica.Dangerous.listReverseInPlace(osysts);
end dynamicStateSelection_mapEqsystem;

protected function dynamicStateSelectionWork
"author: Frenkel TUD 2012-04
  dynamic state deselect of the system."
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  input HashTableCrIntToExp.HashTable iHt;
  input Integer iSetIndex;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output HashTableCrIntToExp.HashTable oHt;
  output Integer oSetIndex=iSetIndex;
protected
  BackendDAE.StateOrder so;
  BackendDAE.ConstraintEquations orgEqnsLst;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  BackendDAE.Variables vars;
  DAE.FunctionTree funcs;
  Integer numFreeStates,numOrgEqs;
algorithm
  (so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,_) := inArg;
  if Array.arrayListsEmpty(orgEqnsLst) then
    // no state selection necessary (OrgEqnsLst is Empty)
    osyst := inSystem;
    oshared := inShared;
    oHt := iHt;
  else
  try
    // do state selection
    BackendDAE.EQSYSTEM(orderedVars=vars) := inSystem;
    BackendDAE.SHARED(functionTree=funcs) := inShared;
    // do late Inline also in orgeqnslst
    orgEqnsLst := inlineOrgEqns(orgEqnsLst,(SOME(funcs),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()}));
    if Flags.isSet(Flags.BLT_DUMP) then
      print("Dynamic State Selection\n");
      BackendDump.dumpEqSystem(inSystem, "Index Reduced System");
    end if;
    // geth the number of states without stateSelect.always (free states), if the number of differentiated equations is equal to the number of free states no selection is necessary
    numFreeStates := BackendVariable.traverseBackendDAEVars(vars,countStateCandidates,0);
    numOrgEqs := countOrgEqns(orgEqnsLst,0);
      //print("got "+intString(numFreeStates)+" free states and "+intString(numOrgEqs)+" orgeqns.\n");

    // select dummy states
    (osyst,oshared,oHt,oSetIndex) := selectStates(numFreeStates,numOrgEqs,inSystem,inShared,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,iHt,iSetIndex);
    if Flags.isSet(Flags.BLT_DUMP) then
      BackendDump.dumpEqSystem(osyst, "Final System with DummyStates");
    end if;
  else
    Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.dynamicStateSelectionWork failed!"});
    fail();
  end try;
  end if;

end dynamicStateSelectionWork;

protected function countStateCandidates
"author Frenkel TUD 2013-01
  count the number of states in variables"
  input BackendDAE.Var inVar;
  input Integer inCount;
  output BackendDAE.Var outVar;
  output Integer outCount;
algorithm
  (outVar,outCount) := match inVar
    local
      Integer diffcount,statecount;
      Boolean b;
    case BackendDAE.VAR(varKind=BackendDAE.STATE(index=1))
      equation
        // do not count states with stateSelect.always
        b = varStateSelectAlways(inVar);
        statecount = if not b then inCount+1 else inCount;
      then (inVar, statecount);

    case BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(_)))
      equation
        // do not count states with stateSelect.always, but ignore only higest state
        b = varStateSelectAlways(inVar);
        statecount = if b then inCount+1 else inCount;
      then (inVar, statecount);

    case BackendDAE.VAR(varKind=BackendDAE.STATE(index=diffcount,derName=NONE()))
      equation
        statecount = diffcount + inCount;
        // do not count states with stateSelect.always, but ignore only higest state
        b = varStateSelectAlways(inVar);
        statecount = if b then statecount-1 else statecount;
      then (inVar, statecount);

    else (inVar,inCount);
  end match;
end countStateCandidates;

protected function countOrgEqns
"author: Frenkel TUD 2012-06
  return the number of orgens."
  input BackendDAE.ConstraintEquations inOrgEqns;
  input Integer iCount;
  output Integer oCount = iCount;
protected
  list<BackendDAE.Equation> orgeqns;
  tuple<Integer,list<BackendDAE.Equation>> orgEqn;
  Integer size, numEqs, e;
algorithm
  numEqs := arrayLength(inOrgEqns);
  for e in 1:numEqs loop
    orgeqns := arrayGet(inOrgEqns,e);
    size := BackendEquation.equationLstSize(orgeqns);
    oCount := oCount + size;
  end for;
end countOrgEqns;

protected function inlineOrgEqns
"author: Frenkel TUD 2012-08
  add an equation to the ConstrainEquations."
  input BackendDAE.ConstraintEquations inOrgEqns;
  input Inline.Functiontuple inA;
  output BackendDAE.ConstraintEquations outOrgEqns;
  replaceable type Type_a subtypeof Any;
protected
  tuple<Integer,list<BackendDAE.Equation>> orgEqn;
  list<BackendDAE.Equation> orgeqns;
  Integer e, numEqs;
algorithm
  outOrgEqns := inOrgEqns;
  numEqs := arrayLength(inOrgEqns);
  for e in 1:numEqs loop
   orgeqns := arrayGet(inOrgEqns,e);
    (orgeqns,_) := BackendInline.inlineEqs(orgeqns, inA,{},false);
     arrayUpdate(outOrgEqns,e,orgeqns);
  end for;
  //outOrgEqns := listReverse(outOrgEqns);
end inlineOrgEqns;

protected function replaceDerStatesStatesExp
"author: Frenkel TUD 2012-06
  helper for replaceDerStatesStates.
  replaces all der(x) with dx"
  input DAE.Exp inExp;
  input BackendDAE.StateOrder inOrder;
  output DAE.Exp outExp;
  output BackendDAE.StateOrder outOrder;
algorithm
  (outExp,outOrder) := matchcontinue (inExp,inOrder)
    local
      BackendDAE.StateOrder so;
      DAE.Exp e;
      DAE.ComponentRef cr,dcr;
    // replace it
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef = cr)}),so)
      equation
        dcr = getStateOrder(cr,so);
        e = Expression.crefExp(dcr);
      then
        (e,so);
    else (inExp,inOrder);
  end matchcontinue;
end replaceDerStatesStatesExp;

protected function highestOrderDerivatives
"author: Frenkel TUD 2012-05
  collect all highest order derivatives from ODE"
  input BackendDAE.Variables v;
  input BackendDAE.StateOrder iSo;
  output list<BackendDAE.Var> outVars;
  output BackendDAE.StateOrder oSo;
algorithm
  ((oSo,_,outVars)) := BackendVariable.traverseBackendDAEVars(v,traversinghighestOrderDerivativesFinder,(iSo,v,{}));
end highestOrderDerivatives;

protected function traversinghighestOrderDerivativesFinder "helper for highestOrderDerivatives"
 input BackendDAE.Var inVar;
 input tuple<BackendDAE.StateOrder,BackendDAE.Variables,list<BackendDAE.Var>> inTpl;
 output BackendDAE.Var outVar;
 output tuple<BackendDAE.StateOrder,BackendDAE.Variables,list<BackendDAE.Var>> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr,dcr;
      BackendDAE.StateOrder so;
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
      Boolean b;
    case (v as BackendDAE.VAR(varKind=BackendDAE.STATE(derName=NONE())),(so,vars,varlst))
      then (v,(so,vars,v::varlst));
     case (v as BackendDAE.VAR(varName=cr,varKind=BackendDAE.STATE(derName=SOME(dcr))),(so,vars,varlst))
      equation
        b = BackendVariable.isState(dcr,vars);
        varlst = List.consOnTrue(not b, v, varlst);
        so = addStateOrder(cr, dcr, so);
      then (v,(so,vars,varlst));
    else (inVar,inTpl);
  end matchcontinue;
end traversinghighestOrderDerivativesFinder;

protected function getVar
"author: Frnekel TUD 2012-05
  helper for traversinglowerOrderDerivativesFinder"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output BackendDAE.Var v;
algorithm
  (v,_) := BackendVariable.getVarSingle(cr,vars);
end getVar;

protected type StateSets = list<tuple<Integer,Integer,Integer,Integer,list<BackendDAE.Var>,list<BackendDAE.Equation>,list<BackendDAE.Var>,list<BackendDAE.Equation>>> "Level,nStates,nStateCandidates,nUnassignedEquations,StateCandidates,ConstraintEqns,OtherVars,OtherEqns";

protected function reduceStateSets
  input StateSets iTplLst;
  input list<BackendDAE.Var> idummyStates;
  output list<BackendDAE.Var> odummyStates;
algorithm
  if not listEmpty(iTplLst) then
    odummyStates := reduceStateSets2(iTplLst);
  else
    odummyStates := idummyStates;
  end if;
end reduceStateSets;

protected function reduceStateSets2
  input StateSets iTplLst;
  output list<BackendDAE.Var> dummyStates = {};
protected
  tuple<Integer,Integer,Integer,Integer,list<BackendDAE.Var>,list<BackendDAE.Equation>,list<BackendDAE.Var>,list<BackendDAE.Equation>> tpl;
  Integer rang, nStateCandidates, nUnassignedEquations;
  list<BackendDAE.Var> stateCandidates;
algorithm
  for tpl in iTplLst loop
    (_,_,nStateCandidates,nUnassignedEquations,stateCandidates,_,_,_) := tpl;
    rang := nStateCandidates - nUnassignedEquations;
    (_,stateCandidates) := List.split(stateCandidates, rang);
    dummyStates := listAppend(stateCandidates, dummyStates);
  end for;
end reduceStateSets2;


protected function addStateSets
"author: Frenkel TUD 2013-01
  add the found state set to the system"
  input StateSets iTplLst;
  input Integer iSetIndex;
  input BackendDAE.EqSystem inSystem;
  output Integer oSetIndex=iSetIndex;
  output BackendDAE.EqSystem oSystem;
algorithm
  (oSetIndex,oSystem) := match(iTplLst,inSystem)
    local
      BackendDAE.EqSystem syst;
      Integer setIndex;
      BackendDAE.EquationArray eqs;
      BackendDAE.Variables vars;
      BackendDAE.StateSets stateSets;
    case ({},_) then (iSetIndex,inSystem);
    case (_::_, syst)
      equation
        (setIndex, vars, eqs, stateSets) =
          generateStateSets(iTplLst, iSetIndex, syst.orderedVars, syst.orderedEqs, syst.stateSets);
        syst.orderedVars = vars;
        syst.orderedEqs = eqs;
        syst.stateSets = stateSets;
      then
        (setIndex, syst);
  end match;
end addStateSets;

protected function generateStateSets
"author: Frenkel TUD 2013-01
  generate the found state sets for the system"
  input StateSets iTplLst "level,nStates,nStateCandidates,nUnassignedEquations,StateCandidates,ConstraintEqns,OtherVars,OtherEqns";
  input Integer iSetIndex;
  input BackendDAE.Variables iVars;
  input BackendDAE.EquationArray iEqns;
  input BackendDAE.StateSets iStateSets;
  output Integer oSetIndex = iSetIndex;
  output BackendDAE.Variables oVars = iVars;
  output BackendDAE.EquationArray oEqns = iEqns;
  output BackendDAE.StateSets oStateSets = iStateSets;
protected
 tuple<Integer,Integer,Integer,Integer,list<BackendDAE.Var>,list<BackendDAE.Equation>,list<BackendDAE.Var>,list<BackendDAE.Equation>> tpl;
 list<BackendDAE.Var> setVars,aVars,varJ,otherVars,stateCandidates;
 list<DAE.ComponentRef> crset;
 DAE.ComponentRef crA,set,crJ;
 DAE.Type tp, tyExpCrStates;
 Integer rang,nStates,nStateCandidates,nUnassignedEquations,setIndex,level;

 DAE.Exp expcrA,mulAstates,mulAdstates,expset,expderset,expsetstart;
 list<DAE.Exp> expcrstates,expcrdstates,expcrset,expcrdset,expcrstatesstart;
 list<DAE.ComponentRef> crstates;
 DAE.Operator op;
 BackendDAE.Equation eqn,deqn;
 list<BackendDAE.Equation> cEqnsLst,oEqnLst;
 BackendDAE.StateSets stateSets;
 DAE.ElementSource source;

 Boolean b;
algorithm

  for tpl in iTplLst loop
    (level,_,nStateCandidates,nUnassignedEquations,stateCandidates,cEqnsLst,otherVars,oEqnLst) := tpl;
    rang := nStateCandidates - nUnassignedEquations;
    b := intGt(rang,1);
    // generate Set Vars
    (_,crset,setVars,crA,aVars,tp,crJ,varJ) := getSetVars(oSetIndex,rang,nStateCandidates,nUnassignedEquations,level);
    // add Equations
    // set.x = set.A*set.statecandidates
    // der(set.x) = set.A*der(set.candidates)
    expcrstates := List.map(stateCandidates, BackendVariable.varExp);
    crstates := List.map(stateCandidates, BackendVariable.varCref);
    expcrstatesstart := List.map(crstates, makeStartExp);
    expcrdstates := List.map(expcrstates,makeder);
    expcrset := List.map(crset,Expression.crefExp);
    expcrdset := List.map(expcrset,makeder);
    expcrA := Expression.crefExp(crA);
    expcrA := DAE.CAST(tp,expcrA);
    tyExpCrStates := DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nStateCandidates)});
    op := if b then DAE.MUL_MATRIX_PRODUCT(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(rang)})) else DAE.MUL_SCALAR_PRODUCT(DAE.T_REAL_DEFAULT);
    mulAstates := DAE.BINARY(expcrA,op,DAE.ARRAY(tyExpCrStates,true,expcrstates));
    (mulAstates,_) := Expression.extendArrExp(mulAstates,false);
    mulAdstates := DAE.BINARY(expcrA,op,DAE.ARRAY(tyExpCrStates,true,expcrdstates));
    (mulAdstates,_) := Expression.extendArrExp(mulAdstates,false);
    expset := if b then DAE.ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(rang)}),true,expcrset) else listHead(expcrset);
    expderset := if b then DAE.ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(rang)}),true,expcrdset) else listHead(expcrdset);
    source := DAE.SOURCE(SOURCEINFO("stateselection",false,0,0,0,0,0.0),{},Prefix.NOCOMPPRE(),{},{},{},{});
    // set.x = set.A*set.statecandidates
    eqn := if b then BackendDAE.ARRAY_EQUATION({rang},expset,mulAstates,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC)
                                else BackendDAE.EQUATION(expset,mulAstates,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
    // der(set.x) = set.A*der(set.candidates)
    deqn := if b then BackendDAE.ARRAY_EQUATION({rang},expderset,mulAdstates,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC)
                                 else BackendDAE.EQUATION(expderset,mulAdstates,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
    // start values for the set
    expsetstart := DAE.BINARY(expcrA,op,DAE.ARRAY(tyExpCrStates,true,expcrstatesstart));
   (expsetstart,_) := Expression.extendArrExp(expsetstart,false);
   (setVars,_) := List.map2Fold(setVars,setStartExp,expsetstart,rang,1);
    // add set states
    oVars := BackendVariable.addVars(setVars,oVars);
    // add equations
    oEqns := BackendEquation.add(eqn, oEqns);
    oEqns := BackendEquation.add(deqn, oEqns);
    // set varkind to dummy_state
    stateCandidates := List.map1(stateCandidates,BackendVariable.setVarKind,BackendDAE.DUMMY_STATE());
    otherVars := List.map1(otherVars,BackendVariable.setVarKind,BackendDAE.DUMMY_STATE());

    oStateSets := BackendDAE.STATESET(oSetIndex,rang,crset,crA,aVars,stateCandidates,otherVars,cEqnsLst,oEqnLst,crJ,varJ,BackendDAE.EMPTY_JACOBIAN())::oStateSets;
    oSetIndex := oSetIndex + 1;
  end for;
end generateStateSets;

public function makeStartExp
"generate the expression: $START.inCref"
  input DAE.ComponentRef inCref;
  output DAE.Exp outExp;
algorithm
  outExp := Expression.crefExp(ComponentReference.crefPrefixStart(inCref));
end makeStartExp;

protected function setStartExp
  input BackendDAE.Var inVar;
  input DAE.Exp startExp;
  input Integer size;
  input Integer iIndex;
  output BackendDAE.Var outVar;
  output Integer oIndex=iIndex;
protected
  DAE.Exp e;
algorithm
  e := if intGt(size,1) then Expression.makeASUB(startExp, {DAE.ICONST(iIndex)}) else startExp;
  (e,_) := ExpressionSimplify.simplify(e);
  outVar := BackendVariable.setVarStartValue(inVar,e);
  oIndex := iIndex + 1;
end setStartExp;

protected function selectStates
"author: Frenkel TUD 2013-01
  check if size of states (without stateSelect.always) is equal to the number of
  differentiated equations, if this is the case no stateselection is neccesary"
  input Integer nfreeStates;
  input Integer nOrgEqns;
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input BackendDAE.StateOrder iSo;
  input BackendDAE.ConstraintEquations orgEqnsLst;
  input array<list<Integer>> iMapEqnIncRow;
  input array<Integer> iMapIncRowEqn;
  input HashTableCrIntToExp.HashTable iHt;
  input Integer iSetIndex;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output HashTableCrIntToExp.HashTable oHt;
  output Integer oSetIndex=iSetIndex;
algorithm
  (osyst,oshared,oHt,oSetIndex) := matchcontinue inSystem
    local
      list<BackendDAE.Equation> eqnslst;
      HashTableCrIntToExp.HashTable ht;
      BackendDAE.EqSystem syst;
      DAE.FunctionTree funcs;
      BackendDAE.IncidenceMatrix m;
      array<Integer> ass1,ass2;
      Integer ne,nv,setIndex;
      BackendDAE.Shared shared;
      list<BackendDAE.Var> hov;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;
      BackendDAE.StateOrder so;
    // number of free states and differentiated equations equal -> no state selection necessary
    case BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2))
      guard intEq(nfreeStates,nOrgEqns)
      equation
        // add the original equations to the systems
        eqnslst = List.flatten(arrayList(orgEqnsLst));
        syst = BackendEquation.equationsAddDAE(eqnslst, inSystem);
        // change dummy states
        (syst,ht) = addAllDummyStates(syst,iSo,iHt);
        // update IncidenceMatrix
        funcs = BackendDAEUtil.getFunctions(inShared);
        (syst,m,_,_,_) = BackendDAEUtil.getIncidenceMatrixScalar(syst,BackendDAE.SOLVABLE(), SOME(funcs));
        // expand the matching
        ass1 = Array.expand(nfreeStates,ass1,-1);
        ass2 = Array.expand(nOrgEqns,ass2,-1);
        nv = BackendVariable.varsSize(BackendVariable.daeVars(syst));
        ne = BackendDAEUtil.systemSize(syst);
        true = BackendDAEEXT.setAssignment(ne,nv,ass2,ass1);
        Matching.matchingExternalsetIncidenceMatrix(nv, ne, m);
        BackendDAEEXT.matching(nv, ne, 5, -1, 0.0, 0);
        BackendDAEEXT.getAssignment(ass2, ass1);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(ass1,ass2,{}));
      then
        (syst,inShared,ht,iSetIndex);
    // select states
    case _
      equation
        ErrorExt.setCheckpoint("DynamicStateSelection");
        // get highest order derivatives
        (hov,so) = highestOrderDerivatives(BackendVariable.daeVars(inSystem),iSo);
        if Flags.isSet(Flags.BLT_DUMP) then
          BackendDump.dumpStateOrder(so);
        end if;
        // get scalar incidence matrix solvable
        funcs = BackendDAEUtil.getFunctions(inShared);
        // replace der(x,n) with DERn.Der(n-1)..DER.x and add variables
        syst = replaceHigherDerivatives(inSystem);
        (syst,_,_,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(syst,BackendDAE.SOLVABLE(), SOME(funcs));
        // do state selection for each level
          //BackendDump.dumpVarList(hov,"HOV");
          //print("ORGEQNS "+BackendDump.constraintEquationString(orgEqnsLst)+"\n");

        (syst,shared,ht,setIndex) = selectStatesWork(1,hov,syst,inShared,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,iHt,iSetIndex);
        ErrorExt.rollBack("DynamicStateSelection");
      then
        (syst,shared,ht,setIndex);
    else
      equation
        ErrorExt.delCheckpoint("DynamicStateSelection");
      then
        fail();
  end matchcontinue;
end selectStates;

protected function selectStatesWork
"author: Frenkel TUD 2013-01
  process differentiated equations of the system and collect the information
  for dummy states"
  input Integer level;
  input list<BackendDAE.Var> iHov "the states candidates of that level";
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input BackendDAE.StateOrder so;
  input BackendDAE.ConstraintEquations iOrgEqnsLst;
  input array<list<Integer>> iMapEqnIncRow;
  input array<Integer> iMapIncRowEqn;
  input HashTableCrIntToExp.HashTable iHt;
  input Integer iSetIndex;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output HashTableCrIntToExp.HashTable oHt;
  output Integer oSetIndex=iSetIndex;
algorithm
  (osyst,oshared,oHt,oSetIndex) :=
  matchcontinue (inSystem, iOrgEqnsLst)
    local
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      list<BackendDAE.Equation> eqnslst,eqnslst1;
      list<Integer> ilst;
      list<BackendDAE.Var> varlst,dummyVars,lov,hov;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn,ass1,ass2;
      Integer nfreeStates,neqns,setIndex,ne,ne1,nv,nv1;
      StateSets stateSets;
      DAE.FunctionTree funcs;
      BackendDAE.Variables vars;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.ConstraintEquations orgEqnsLst;
      HashTableCrIntToExp.HashTable ht;
      HashTable2.HashTable repl;
    case (_,_)
      equation
        true = Array.arrayListsEmpty(iOrgEqnsLst);
      then (inSystem,inShared,iHt,iSetIndex);
    case (BackendDAE.EQSYSTEM(orderedVars=vars,matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2)),_)
      equation
        // get orgequations of that level
        (eqnslst1,orgEqnsLst) = removeFirstOrgEqns(iOrgEqnsLst);
        // replace final parameter
        (eqnslst,_) = BackendEquation.traverseExpsOfEquationList(eqnslst1, replaceFinalVarsEqn,(BackendVariable.daeGlobalKnownVars(inShared),false,BackendVarTransform.emptyReplacements()));
        // replace all der(x) with dx
        (eqnslst,_) = BackendEquation.traverseExpsOfEquationList(eqnslst, Expression.traverseSubexpressionsHelper, (replaceDerStatesStatesExp,so));
        // force inline
        funcs = BackendDAEUtil.getFunctions(inShared);
        (eqnslst,_) = BackendEquation.traverseExpsOfEquationList(eqnslst, forceInlinEqn,funcs);
        // try to make scalar
        (eqnslst,_) = InlineArrayEquations.getScalarArrayEqns(eqnslst);
        // convert x:STATE(n) if n>1 to DER.DER....x
        (hov,ht) = List.map1Fold(iHov,getLevelStates,level,HashTableCrIntToExp.emptyHashTable());
        (eqnslst,_) = BackendEquation.traverseExpsOfEquationList(eqnslst, Expression.traverseSubexpressionsHelper, (replaceDummyDerivativesExp, ht));
        (eqnslst1,_) = BackendEquation.traverseExpsOfEquationList(eqnslst1, Expression.traverseSubexpressionsHelper, (replaceDummyDerivativesExp, ht));
        // remove stateSelect=StateSelect.always vars
        varlst = list(var for var guard notVarStateSelectAlways(var, level) in hov);
        neqns = BackendEquation.equationLstSizeKeepAlgorithmAsOne(eqnslst); //vwaurich: algorithms are handled as single equations, like a function call
        nfreeStates = listLength(varlst);
        // do state selection of that level
        (dummyVars,stateSets) = selectStatesWork1(nfreeStates,varlst,neqns,eqnslst,level,inSystem,inShared,so,iMapEqnIncRow,iMapIncRowEqn,hov,{},{});
        // get derivatives one order less
        lov = List.fold3(iHov, getlowerOrderDerivatives, level, so, vars, {});
        // remove DummyStates DER.x from States with v_d>1 with unkown derivative dummyVars
        repl = HashTable2.emptyHashTable();
        (dummyVars,repl) = removeFirstOrderDerivatives(dummyVars,vars,so,repl);
        nv = BackendVariable.varsSize(vars);
        ne = BackendDAEUtil.systemSize(inSystem);
        // add the original equations to the systems
        syst = BackendEquation.equationsAddDAE(eqnslst1, inSystem);
        // Dummy Derivatives
        if Flags.getConfigString(Flags.INDEX_REDUCTION_METHOD) == "dummyDerivatives" and neqns < nfreeStates then
          //print("BEFORE:\n");
          //BackendDump.printVarList(dummyVars);
          dummyVars = reduceStateSets(stateSets, dummyVars);
          //print("AFTER:\n");
          //BackendDump.printVarList(dummyVars);
          stateSets = {};
        end if;
        // add the found state sets for dynamic state selection to the system
        (setIndex,syst) = addStateSets(stateSets,iSetIndex,syst);
        // change dummy states, update Assignments
        (syst,ht) = addDummyStates(dummyVars,level,repl,syst,iHt);
        // fix derivative indexes
        _ = List.fold1(iHov, fixDerivativeIndex, level, BackendVariable.daeVars(syst));
        // update IncidenceMatrix
        (syst,m,_,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(syst,BackendDAE.SOLVABLE(), SOME(funcs));
        // genereate new Matching
        nv1 = BackendVariable.varsSize(BackendVariable.daeVars(syst));
        ne1 = BackendDAEUtil.systemSize(syst);
        ass1 = Array.expand(nv1-nv,ass1,-1);
        ass2 = Array.expand(ne1-ne,ass2,-1);
        true = BackendDAEEXT.setAssignment(ne1,nv1,ass2,ass1);
        Matching.matchingExternalsetIncidenceMatrix(nv1, ne1, m);
        BackendDAEEXT.matching(nv1, ne1, 5, -1, 0.0, 0);
        BackendDAEEXT.getAssignment(ass2, ass1);
        syst = BackendDAEUtil.setEqSystMatching(syst,BackendDAE.MATCHING(ass1,ass2,{}));
        //  BackendDump.dumpEqSystem(syst,"Next Level");
        // next level
        (syst,shared,ht,setIndex) = selectStatesWork(level+1,lov,syst,inShared,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,ht,setIndex);
      then
        (syst,shared,ht,setIndex);
  end matchcontinue;
end selectStatesWork;

protected function removeFirstOrderDerivatives
"author Frenkel TUD 2013-01
  remove dummy derivatives from states with higher derivatives and no known derivative variable"
  input list<BackendDAE.Var> iDummyVars;
  input BackendDAE.Variables iVars;
  input BackendDAE.StateOrder so;
  input HashTable2.HashTable iRepl;
  output list<BackendDAE.Var> oDummyVars = {};
  output HashTable2.HashTable oRepl = iRepl;
algorithm

  for var in iDummyVars loop
     (oDummyVars, oRepl) := match var
      local
       list<BackendDAE.Var> dummyVars;
       DAE.ComponentRef cr,dcr;
       DAE.Exp exp;
    // dummy derivatives from states with higher derivatives and no known derivative variable
    case BackendDAE.VAR(varName=dcr as DAE.CREF_QUAL(ident="$DER",componentRef=cr),varKind=BackendDAE.STATE(index=1))
    guard not intEq(System.strncmp(ComponentReference.crefFirstIdent(cr),"$DER",4),0)
      equation
        exp = Expression.crefExp(cr);
        exp = Expression.makePureBuiltinCall("der", {exp}, Expression.typeof(exp));
        oRepl = BaseHashTable.add((dcr,exp),oRepl);
      then (oDummyVars,oRepl);
    // keep it
    else (var::oDummyVars,oRepl);
    end match;
  end for;

end removeFirstOrderDerivatives;

protected function getlowerOrderDerivatives
"author Frenkel TUD 2013-01"
  input BackendDAE.Var inVar;
  input Integer level;
  input BackendDAE.StateOrder so;
  input BackendDAE.Variables vars;
  input list<BackendDAE.Var> iVars;
  output list<BackendDAE.Var> oVars;
algorithm
  oVars := matchcontinue inVar
    local
      Integer diffindx;
      DAE.ComponentRef dcr;
      list<DAE.ComponentRef> crlst;
      list<BackendDAE.Var> vlst;
    case BackendDAE.VAR(varName=dcr,varKind=BackendDAE.STATE(index=diffindx))
      guard intEq(diffindx,1)
      equation
        crlst = getDerStateOrder(dcr,so);
        vlst = List.map1(crlst,getVar,vars);
        vlst = listAppend(vlst,iVars);
      then
        vlst;
    case BackendDAE.VAR(varKind=BackendDAE.STATE(index=diffindx))
      then
         List.consOnTrue(intGt(diffindx,level),inVar,iVars);
    else iVars;
  end matchcontinue;
end getlowerOrderDerivatives;

protected function fixDerivativeIndex
"author Frenkel TUD 2013-01"
  input BackendDAE.Var inVar;
  input Integer level;
  input BackendDAE.Variables iVars;
  output BackendDAE.Variables oVars;
algorithm
  oVars := matchcontinue(inVar,level,iVars)
    local
      Integer diffindx;
      BackendDAE.Variables vars;
      BackendDAE.Var v;
      Option<DAE.ComponentRef> derName;
    case(BackendDAE.VAR(varKind=BackendDAE.STATE(index=diffindx,derName=derName)),_,_)
      equation
        true = intGt(diffindx,level);
        diffindx = diffindx-level;
        v = BackendVariable.setVarKind(inVar, BackendDAE.STATE(diffindx,derName));
        vars = BackendVariable.addVar(v, iVars);
      then
         vars;
    else iVars;
  end matchcontinue;
end fixDerivativeIndex;

protected function selectStatesWork1
"author: Frenkel TUD 2013-01
  collect the additional equations of the system for state selection.
  This is neccessary to have the full constrained equations sets"
  input Integer nfreeStates;
  input list<BackendDAE.Var> statecandidates;
  input Integer neqns "scalar length of eqnslst";
  input list<BackendDAE.Equation> eqnslst;
  input Integer level;
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input BackendDAE.StateOrder so;
  input array<list<Integer>> iMapEqnIncRow;
  input array<Integer> iMapIncRowEqn;
  input list<BackendDAE.Var> iHov;
  input list<BackendDAE.Var> inDummyVars;
  input StateSets iStateSets;
  output list<BackendDAE.Var> outDummyVars;
  output StateSets oStateSets;
algorithm
  (outDummyVars,oStateSets) :=
  matchcontinue inSystem
    local
      list<BackendDAE.Var> dummyVars,vlst;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;
      Integer nv,nv1,ne,ne1,neqnarr;
      BackendDAE.Variables vars,hovvars;
      BackendDAE.EquationArray eqns,eqns1;
      BackendDAE.EqSystem syst;
      BackendDAE.AdjacencyMatrixEnhanced me;
      BackendDAE.AdjacencyMatrixTEnhanced meT;
      StateSets stateSets;
      String msg;
      array<Integer> indexmap,invindexmap,vec1,vec2,ass1,ass2;
      list<Integer> ilst,assigned,unassigned;
      BackendDAE.IncidenceMatrix m,m1;
      BackendDAE.IncidenceMatrixT mT,mT1;
      list<list<Integer>> comps;
      list<BackendDAE.Equation> eqnslst1;
      list<tuple<DAE.ComponentRef, Integer>> states,dstates;
      DAE.FunctionTree funcs;

    // number of free states equal to number of differentiated equations -> no state selection necessary, all dummy states
    case _
      guard intEq(nfreeStates,neqns)
      then
        (statecandidates,iStateSets);
    // do state selection
    case BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=SOME(m),mT=SOME(mT),matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2))
      guard intGt(nfreeStates,1) and not intGt(neqns,nfreeStates)
      equation
        // try to select dummy vars
        if Flags.isSet(Flags.BLT_DUMP) then
          print("try to select dummy vars with natural matching(newer)\n");
        end if;
        //  print("nVars " + intString(nfreeStates) + " nEqns " + intString(neqns) + "\n");
        // sort vars with heuristic
        hovvars = BackendVariable.listVar1(statecandidates);
        eqns1 = BackendEquation.listEquation(eqnslst);
        syst = BackendDAEUtil.createEqSystem(hovvars, eqns1);
        (me,meT,_,_) =  BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst,inShared,false);
        m1 = incidenceMatrixfromEnhanced2(me,hovvars);
        mT1 = AdjacencyMatrix.transposeAdjacencyMatrix(m1,nfreeStates);
        //  BackendDump.printEqSystem(syst);
        hovvars = sortStateCandidatesVars(hovvars,BackendVariable.daeVars(inSystem),SOME(mT1));
        if Flags.isSet(Flags.BLT_DUMP) then
          print("highest Order Derivatives:\n");
          BackendDump.printVariables(hovvars);
          BackendDump.printEquationList(eqnslst);
        end if;
        // generate incidence matrix from system and equations of that level and the states of that level
        nv = BackendVariable.varsSize(vars);
        ne = BackendEquation.equationArraySize(eqns);
        neqnarr = BackendEquation.getNumberOfEquations(eqns);
        ne1 = ne + neqns;
        indexmap = arrayCreate(nfreeStates  + nv,-1);
        invindexmap = arrayCreate(nfreeStates,-1);
        // workaround to get state indexes
        nv1 = nv + nfreeStates;
        (vars,(indexmap,invindexmap,_,_,_,_)) = BackendVariable.traverseBackendDAEVarsWithUpdate(vars,getStateIndexes,(indexmap,invindexmap,1,nv,hovvars,{}));
        //  BackendDump.dumpMatching(indexmap);
        m1 = arrayCreate(ne1,{});
        mT1 = arrayCreate(nv1,{});
        mapEqnIncRow = Array.expand(neqns,iMapEqnIncRow,{});
        mapIncRowEqn = Array.expand(neqns,iMapIncRowEqn,-1);
        // replace state indexes in original incidencematrix
        getIncidenceMatrixSelectStates(ne,m1,mT1,m,indexmap);
        // add level equations
        funcs = BackendDAEUtil.getFunctions(inShared);
        getIncidenceMatrixLevelEquations(eqnslst,vars,neqnarr,ne,m1,mT1,m,mapEqnIncRow,mapIncRowEqn,indexmap,funcs);
        // match the variables not the equations, to have prevered states unmatched
        vec1 = Array.expand(nfreeStates,ass1,-1);
        vec2 = Array.expand(neqns,ass2,-1);
        true = BackendDAEEXT.setAssignment(nv1,ne1,vec1,vec2);
        Matching.matchingExternalsetIncidenceMatrix(ne1, nv1, mT1);
        BackendDAEEXT.matching(ne1, nv1, 3, -1, 0.0, 0);
        BackendDAEEXT.getAssignment(vec1, vec2);
        comps = Sorting.TarjanTransposed(mT1, vec2);
        // remove blocks without differentiated equations
        comps = List.select1(comps, selectBlock, ne);
        //  BackendDump.dumpComponentsOLD(comps);
        //  eqns1 = BackendEquation.listEquation(BackendEquation.equationList(eqns));
        //  eqns1 = BackendEquation.addList(eqnslst, eqns1);
        //  List.map3_0(comps, dumpBlock, mapIncRowEqn, nv, BackendDAE.EQSYSTEM(vars,eqns1,SOME(m1),NONE(),BackendDAE.MATCHING(invindexmap,vec2,{}),{}) );
        // traverse the blocks and collect the additional equations and vars
        ilst = List.fold1(comps,getCompsExtraEquations,ne,{});
        ilst = List.map1r(ilst,arrayGet,iMapIncRowEqn);
        ilst = List.uniqueIntN(ilst, ne);
        eqnslst1 = BackendEquation.getList(ilst,eqns);
        ilst = List.fold2(comps,getCompsExtraVars,nv,vec2,{});
        vlst = List.map1r(ilst,BackendVariable.getVarAt,vars);
        // generate system
        eqns = BackendEquation.listEquation(eqnslst);
        eqns = BackendEquation.addList(eqnslst1, eqns);
        vars = BackendVariable.listVar1(vlst);
        vars = BackendVariable.addVars(BackendVariable.varList(hovvars), vars);
        syst = BackendDAEUtil.createEqSystem(vars, eqns);
        // get advanced incidence Matrix
        (me,meT,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst,inShared,false);
        if Flags.isSet(Flags.BLT_DUMP) then
          BackendDump.dumpAdjacencyMatrixEnhanced(me);
          BackendDump.dumpAdjacencyMatrixTEnhanced(meT);
        end if;
        // get indicenceMatrix from Enhanced
        m = incidenceMatrixfromEnhanced2(me,vars);
        nv = BackendVariable.varsSize(vars);
        ne = BackendEquation.equationArraySize(eqns);
        mT = AdjacencyMatrix.transposeAdjacencyMatrix(m,nv);
        // match the variables not the equations, to have prevered states unmatched
        Matching.matchingExternalsetIncidenceMatrix(ne,nv,mT);
        BackendDAEEXT.matching(ne,nv,3,-1,1.0,1);
        vec1 = arrayCreate(nv,-1);
        vec2 = arrayCreate(ne,-1);
        BackendDAEEXT.getAssignment(vec1,vec2);
        if Flags.isSet(Flags.BLT_DUMP) then
          BackendDump.dumpMatching(vec1);
          BackendDump.dumpMatching(vec2);
        end if;
        // get the matched state candidates -> dummyVars
        (dstates,_) = checkAssignment(1,nv,vec1,vars);
        dummyVars = List.map1r(List.map(dstates,Util.tuple22),BackendVariable.getVarAt,vars);
        dummyVars = List.select(dummyVars, BackendVariable.isStateVar);
        if Flags.isSet(Flags.BLT_DUMP) then
          print("select as Dummy States:\n");
          BackendDump.printVarList(dummyVars);
        end if;
        // get assigned and unassigned equations
        unassigned = Matching.getUnassigned(ne, vec2, {});
        _ = Matching.getAssigned(ne, vec2, {});
        if Flags.isSet(Flags.BLT_DUMP) then
          print("Unassigned Eqns:\n");
          BackendDump.debuglst(unassigned,intString," ","\n");
        end if;
        // splitt it into sets
        syst = BackendDAEUtil.setEqSystMatching(syst, BackendDAE.MATCHING(vec1,vec2,{}));
        //  dumpSystemGraphML(syst,inShared,NONE(),"StateSelection" + intString(arrayLength(m)) + ".graphml");
        (syst,m,mT,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(syst,BackendDAE.ABSOLUTE(), SOME(funcs));
        // TODO: partition the system
        comps = partitionSystem(m,mT);
        //  print("Sets:\n");
        //  BackendDump.dumpIncidenceMatrix(listArray(comps));
        //  BackendDump.printEqSystem(syst);
        (vlst,_,stateSets) = processComps4New(comps,nv,ne,vars,eqns,m,mT,mapEqnIncRow,mapIncRowEqn,vec2,vec1,level,inShared,{},{},iStateSets);
        vlst = List.select(vlst, BackendVariable.isStateVar);
        dummyVars = listAppend(dummyVars,vlst);
      then
        (dummyVars,stateSets);
    // to much equations this is an error
    case _
      guard intGt(neqns,nfreeStates)
      equation
        if Flags.isSet(Flags.BLT_DUMP) then
          print("highest Order Derivatives:\n");
          BackendDump.printVarList(statecandidates);
          BackendDump.printEquationList(eqnslst);
        end if;
        // no chance, to much equations
        msg = "It is not possible to select continues time states because Number of Equations " + intString(neqns) + " greater than number of States " + intString(nfreeStates) + " to select from.";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
    // number of differentiated equations exceeds number of free states, add StateSelect.always states and try again
    case _
      guard  intGt(neqns,nfreeStates)
      equation
        // try again and add also stateSelect.always vars.
        nv = listLength(iHov);
        true = intGe(nv,neqns);
        (dummyVars,stateSets) = selectStatesWork1(nv,iHov,neqns,eqnslst,level,inSystem,inShared,so,iMapEqnIncRow,iMapIncRowEqn,iHov,inDummyVars,iStateSets);
      then
        (dummyVars,stateSets);
  end matchcontinue;
end selectStatesWork1;

protected function selectBlock
  input list<Integer> comp;
  input Integer ne;
  output Boolean b;
algorithm
  b := match(comp,ne)
    local
      Integer c;
      list<Integer> rest;
    case ({},_) then false;
    case (c::rest,_)
      equation
        b = if intLe(c,ne) then selectBlock(rest,ne) else true;
      then
        b;
  end match;
end selectBlock;

protected function getCompsExtraEquations
  input list<Integer> comp;
  input Integer neqns;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
protected
  list<Integer> eqns;
algorithm
  eqns := List.select1(comp,intLe,neqns);
  oAcc := listAppend(eqns,iAcc);
end getCompsExtraEquations;

protected function getCompsExtraVars
  input list<Integer> comp;
  input Integer nvars;
  input array<Integer> ass2;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
protected
  list<Integer> vars;
algorithm
  vars := List.map1r(comp,arrayGet,ass2);
  vars := List.select1(vars,intLe,nvars);
  vars := List.select1(vars,intGt,0);
  oAcc := listAppend(vars,iAcc);
end getCompsExtraVars;

protected function dumpBlock
  input list<Integer> comp;
  input array<Integer> iMapIncRowEqn;
  input Integer nvars;
  input BackendDAE.EqSystem syst;
protected
  list<Integer> eqns;
  list<Integer> ilst,ilst1;
  array<Integer> ass2,invindexmap;
  BackendDAE.IncidenceMatrix m;
algorithm
  BackendDAE.EQSYSTEM(m=SOME(m),matching=BackendDAE.MATCHING(ass1=invindexmap,ass2=ass2)) := syst;
  eqns := List.map1r(comp,arrayGet,iMapIncRowEqn);
  eqns := List.uniqueIntN(eqns, BackendDAEUtil.equationArraySizeDAE(syst));
  ilst := List.map1r(comp,arrayGet,ass2);
  (ilst1,ilst) := List.split1OnTrue(ilst,intGt,nvars);
  ilst1 := List.map1(ilst1,intSub,nvars);
  ilst1 := List.map1r(ilst1,arrayGet,invindexmap);
  ilst := listAppend(ilst,ilst1);
  // add states of that level
  //ilst1 := List.flatten(List.map1r(comp,arrayGet,m));
  //(ilst1,_) := List.split1OnTrue(ilst1,intGt,nvars);
  //ilst1 := List.map1(ilst1,intSub,nvars);
  //ilst1 := List.map1r(ilst1,arrayGet,invindexmap);
  //ilst := List.unionIntN(ilst, ilst1, nvars);
  print("##########################\n");
  print(BackendDump.dumpMarkedVars(syst, ilst) + "\n");
  print(BackendDump.dumpMarkedEqns(syst, eqns));
end dumpBlock;

protected function getStateIndexes
  input BackendDAE.Var inVar;
  input tuple<array<Integer>,array<Integer>,Integer,Integer,BackendDAE.Variables,list<Integer>> inTpl;
  output BackendDAE.Var outVar;
  output tuple<array<Integer>,array<Integer>,Integer,Integer,BackendDAE.Variables,list<Integer>> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      DAE.ComponentRef cr;
      array<Integer> stateindexs,invmap;
      Integer indx,s,nv,newindx;
      BackendDAE.Variables hov;
      list<Integer> derstatesindexs;
      Option<DAE.ComponentRef> derName;
    case (BackendDAE.VAR(varName=cr,varKind=BackendDAE.STATE()),(stateindexs,invmap,indx,nv,hov,derstatesindexs))
      equation
        (_,s) = BackendVariable.getVarSingle(cr, hov);
        newindx = nv+s;
        arrayUpdate(stateindexs,indx,newindx);
        arrayUpdate(invmap,s,indx);
      then (inVar,(stateindexs,invmap,indx+1,nv,hov,indx::derstatesindexs));
   case (_,(stateindexs,invmap,indx,nv,hov,derstatesindexs))
      then (inVar,(stateindexs,invmap,indx+1,nv,hov,derstatesindexs));
  end matchcontinue;
end getStateIndexes;

protected function getIncidenceMatrixSelectStates
  input Integer nEqns;
  input BackendDAE.IncidenceMatrix m "input/output";
  input BackendDAE.IncidenceMatrixT mT "input/output";
  input BackendDAE.IncidenceMatrix mo;
  input array<Integer> stateindexs;
protected
  list<Integer> row, negrow;
algorithm
  for i in nEqns:-1:1 loop
    // get row
    row := mo[i];
    // replace negative index with index from stateindexs
    row := List.map1(row,replaceStateIndex,stateindexs);
    // update m
    arrayUpdate(m,i,row);
    // update mT
    (row, negrow) := List.split1OnTrue(row, intGt, 0);
    _ := List.fold1(row,Array.consToElement,i,mT);
    row := List.map(negrow,intAbs);
    _ := List.fold1(row,Array.consToElement,-i,mT);
  end for;
end getIncidenceMatrixSelectStates;

protected function replaceStateIndex
  input Integer iR;
  input array<Integer> stateindexs;
  output Integer oR;
protected
  Integer s,r;
algorithm
  oR := iR;
  if not intGt(iR,0) then
    r := intAbs(iR);
    s := stateindexs[r];
    if intGt(s,0) then
      oR := s;
    end if;
  end if;
end replaceStateIndex;

protected function getIncidenceMatrixLevelEquations
"@author: Frenkel TUD 2013-01
  Calculates the incidence matrix as an array of list of integers"
  input list<BackendDAE.Equation> iEqns;
  input BackendDAE.Variables vars;
  input Integer index "index";
  input Integer sindex "scalar index";
  input BackendDAE.IncidenceMatrix m "input/output";
  input BackendDAE.IncidenceMatrixT mT "input/output";
  input BackendDAE.IncidenceMatrix om;
  input array<list<Integer>> mapEqnIncRow "input/output";
  input array<Integer> mapIncRowEqn "input/output";
  input array<Integer> stateindexs;
  input DAE.FunctionTree functionTree;
algorithm
  _ := match (iEqns)
    local
      list<BackendDAE.Equation> rest;
      AvlSetInt.Tree rowTree;
      list<Integer> row,rowindxs,negrow;
      BackendDAE.Equation e;
      Integer i1,rowSize,size;

    case {} then ();

    // i < n
    case e::rest equation
        // compute the row
        (rowTree,size) = BackendDAEUtil.incidenceRow(e, vars, BackendDAE.SOLVABLE(), SOME(functionTree), AvlSetInt.EMPTY());
        row = AvlSetInt.listKeys(rowTree);
        rowSize = sindex + size;
        i1 = index+1;
        rowindxs = List.intRange2(sindex+1, rowSize);
        _ = List.fold1r(rowindxs,arrayUpdate,i1,mapIncRowEqn);
        arrayUpdate(mapEqnIncRow,i1,rowindxs);
        // replace state indexes
        row = List.map1(row,replaceStateIndex,stateindexs);
        // update m
        _ = List.fold1r(rowindxs,arrayUpdate,row,m);
        // update mT
        (row,negrow) = List.split1OnTrue(row, intGt, 0);
        _ = List.fold1(row,Array.appendToElement,rowindxs,mT);
        row = List.map(negrow,intAbs);
        rowindxs = List.map(rowindxs,intNeg);
        _ = List.fold1(row,Array.appendToElement,rowindxs,mT);
        // next equation
        getIncidenceMatrixLevelEquations(rest, vars, i1, rowSize, m, mT, om, mapEqnIncRow, mapIncRowEqn, stateindexs, functionTree);
      then ();
  end match;
end getIncidenceMatrixLevelEquations;

protected function partitionSystem
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  output list<list<Integer>> systs;
protected
  array<Integer> rowmarkarr,collmarkarr;
  Integer nsystems,neqns;
  array<list<Integer>> systsarr;
algorithm
  neqns := arrayLength(m);
  // array to mark the independent systems
  rowmarkarr := arrayCreate(neqns,0);
  collmarkarr := arrayCreate(arrayLength(mT),0);
  // mark the systems
  nsystems := partitionSystem1(neqns,m,mT,rowmarkarr,collmarkarr,1);
  // splitt it in independen systems
  systsarr := arrayCreate(nsystems,{});
  systsarr := partitionSystemSplitt(neqns,rowmarkarr,systsarr);
  systs := arrayList(systsarr);
end partitionSystem;

protected function partitionSystem1
  input Integer index;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input array<Integer> rowmarkarr;
  input array<Integer> collmarkarr;
  input Integer iNSystems;
  output Integer oNSystems;
algorithm
  oNSystems := matchcontinue(index)
    local
      list<Integer> rows;
      Integer nsystems;
    case 0 then iNSystems-1;
    case _
      equation
        // if unmarked then increse nsystems
        false = intGt(rowmarkarr[index],0);
        arrayUpdate(rowmarkarr,index,iNSystems);
        rows = List.select(m[index], Util.intPositive);
        nsystems = partitionSystemstraverseRows(rows,{},m,mT,rowmarkarr,collmarkarr,iNSystems);
      then
        partitionSystem1(index-1,m,mT,rowmarkarr,collmarkarr,nsystems);
    else equation
      // if marked skip it
      true = intGt(rowmarkarr[index],0);
    then partitionSystem1(index-1,m,mT,rowmarkarr,collmarkarr,iNSystems);
  end matchcontinue;
end partitionSystem1;

protected function partitionSystemstraverseRows
  input list<Integer> iRows;
  input list<Integer> iQueue;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input array<Integer> rowmarkarr;
  input array<Integer> collmarkarr;
  input Integer iNSystems;
  output Integer oNSystems;
algorithm
  oNSystems := matchcontinue(iRows,iQueue)
    local
      list<Integer> rest,colls,rows;
      Integer r;
    case ({},{}) then iNSystems+1;
    case ({},_)
      then
        partitionSystemstraverseRows(iQueue,{},m,mT,rowmarkarr,collmarkarr,iNSystems);
    case (r::rest,_)
      equation
        // if unmarked then add
        false = intGt(collmarkarr[r],0);
        arrayUpdate(collmarkarr,r,iNSystems);
        colls = List.select(mT[r], Util.intPositive);
        colls = List.select1r(colls,Matching.isUnAssigned, rowmarkarr);
        _ = List.fold1(colls, markTrue, iNSystems, rowmarkarr);
        rows = List.flatten(List.map1r(colls,arrayGet,m));
        rows = List.select1r(rows,Matching.isUnAssigned, collmarkarr);
        rows = listAppend(rows,iQueue);
      then
        partitionSystemstraverseRows(rest,rows,m,mT,rowmarkarr,collmarkarr,iNSystems);
    case (r::rest,_)
      equation
        // if marked skipp it
        true = intGt(collmarkarr[r],0);
      then
        partitionSystemstraverseRows(rest,iQueue,m,mT,rowmarkarr,collmarkarr,iNSystems);
  end matchcontinue;
end partitionSystemstraverseRows;

protected function partitionSystemSplitt
  input Integer index;
  input array<Integer> rowmarkarr;
  input array<list<Integer>> systsarr;
  output array<list<Integer>> osystsarr;
algorithm
  osystsarr := match(index)
    local
      Integer i;
      array<list<Integer>> arr;
    case (0) then systsarr;
    case (_)
      equation
        i = rowmarkarr[index];
        arr = Array.consToElement(i, index, systsarr);
      then
        partitionSystemSplitt(index-1,rowmarkarr,arr);
  end match;
end partitionSystemSplitt;

protected function processComps4New
"author: Frenkel TUD 2012-12
  process all strong connected components of the system and collect the
  derived equations for dummy state selection"
  input list<list<Integer>> iSets;
  input Integer inVarSize;
  input Integer inEqnsSize;
  input BackendDAE.Variables iVars;
  input BackendDAE.EquationArray iEqns;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input array<list<Integer>> inMapEqnIncRow;
  input array<Integer> inMapIncRowEqn;
  input array<Integer> vec1;
  input array<Integer> vec2;
  input Integer level;
  input BackendDAE.Shared iShared;
  input list<BackendDAE.Var> inHov;
  input list<DAE.ComponentRef> inDummyStates;
  input StateSets iStateSets;
  output list<BackendDAE.Var> outDummyVars = inHov;
  output list<DAE.ComponentRef> outDummyStates = inDummyStates;
  output StateSets oStateSets = iStateSets;
protected
  array<list<Integer>> mapEqnIncRow1;
  array<Integer> mapIncRowEqn1,ass1arr;
  list<DAE.ComponentRef> dummyStates;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns,eqns1 = iEqns;
  BackendDAE.EqSystem syst;
  list<Integer> seteqns,unassigned,assigned,set,statevars,dstatevars,ass1,ass2,assigend1,range;
  list<BackendDAE.Var> varlst = inHov;
  array<Boolean> flag;
  list<BackendDAE.Equation> eqnlst;
  BackendDAE.AdjacencyMatrixEnhanced me;
  BackendDAE.AdjacencyMatrixTEnhanced meT;
  list<tuple<DAE.ComponentRef, Integer>> states1,dstates1;
  Integer nstatevars,nassigned,nunassigned,nass1arr,n,nv,ne;
  StateSets stateSets;
algorithm
  try
    for seteqns in iSets loop
      if not listEmpty(List.select1r(seteqns,Matching.isUnAssigned,vec1)) then  // ignore sets without unassigned equations, because all assigned states already in dummy states
        //  print("seteqns: " + intString(listLength(seteqns)) + "\n");
        //  print(stringDelimitList(List.map(seteqns,intString),", ") + "\n");
        unassigned := List.select1r(seteqns,Matching.isUnAssigned,vec1);
        n := arrayLength(inM);
        set := getEqnsforDynamicStateSelection(unassigned,n,inM,inMT,vec1,vec2,inMapEqnIncRow,inMapIncRowEqn);
        assigned := List.select1r(set,Matching.isAssigned,vec1);
        //  print("Set: " + intString(listLength(set)) + "\n");
        //  print(stringDelimitList(List.map(set,intString),", ") + "\n");
        //  print("assigned: " + intString(listLength(assigned)) + "\n");
        //  print(stringDelimitList(List.map(assigned,intString),", ") + "\n");
        flag := arrayCreate(inVarSize,true);
        ((statevars,_)) := List.fold3(set,getSetStates,flag,inM,vec2,({},{}));
        //  print("Statevars: " + intString(listLength(statevars)) + "\n");
        //  print(stringDelimitList(List.map(statevars,intString),", ") + "\n");
        //  print("Select " + intString(listLength(unassigned)) + " from " + intString(listLength(statevars)) + "\n");
        nstatevars := listLength(statevars);
        ass1 := List.consN(nstatevars, -1, {});
        nunassigned := listLength(unassigned);
        ass2 := List.consN(nunassigned, -1, {});
        varlst := List.map1r(statevars,BackendVariable.getVarAt,iVars);
        assigend1 := List.map1r(unassigned,arrayGet,inMapIncRowEqn);
        n := arrayLength(inMapIncRowEqn);
        assigend1 := List.uniqueIntN(assigend1,n);
        //  print("BackendEquation.getList " + stringDelimitList(List.map(assigend1,intString),", ") + "\n");
        eqnlst := BackendEquation.getList(assigend1, eqns1);
        //  print("BackendEquation.delete " + stringDelimitList(List.map(assigend1,intString),", ") + "\n");
        eqns1 := List.fold(assigend1,BackendEquation.delete,eqns1);
        nassigned := listLength(assigned);
        flag := arrayCreate(inEqnsSize,true);
        (eqnlst,varlst,ass1,ass2,eqns1) := getSetSystem(assigned,inMapEqnIncRow,inMapIncRowEqn,vec1,iVars,eqns1,flag,nassigned,eqnlst,varlst,ass1,ass2);
        eqns := BackendEquation.listEquation(eqnlst);
        vars := BackendVariable.listVar1(varlst);
        syst := BackendDAEUtil.createEqSystem(vars, eqns);
        //  BackendDump.printEqSystem(syst);
        //  BackendDump.dumpMatching(listArray(ass1));
        //  BackendDump.dumpMatching(listArray(ass2));
        (_,_,_,mapIncRowEqn1) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst,iShared,false);
        ass1arr := listArray(ass1);
        nass1arr := arrayLength(ass1arr);
        (dstates1,states1) := checkAssignment(1,nass1arr,ass1arr,vars);
        assigend1 := if not listEmpty(assigned) then List.intRange2(1,nassigned) else {};
        nunassigned := nassigned+nunassigned;
        nassigned := nassigned+1;
        range := List.intRange2(nassigned,nunassigned);
        nv := BackendVariable.varsSize(vars);
        ne := BackendEquation.equationArraySize(eqns);
        (varlst,oStateSets) := selectDummyDerivatives2new(dstates1,states1,range,assigend1,vars,nv,eqns,ne,mapIncRowEqn1,level,oStateSets);
        dummyStates := List.map(varlst,BackendVariable.varCref);
        outDummyStates := listAppend(outDummyStates,dummyStates);
        outDummyVars := listAppend(varlst, outDummyVars);
      end if;
    end for;
  else
    Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.processComps4New failed!"});
    fail();
  end try;
end processComps4New;

protected function forceInlinEqn
  input DAE.Exp inExp;
  input DAE.FunctionTree inFuncs;
  output DAE.Exp e;
  output DAE.FunctionTree funcs;
algorithm
  funcs := inFuncs;
  (e,_,_) := Inline.forceInlineExp(inExp,(SOME(funcs),{DAE.NORM_INLINE(),DAE.DEFAULT_INLINE()}),DAE.emptyElementSource);
end forceInlinEqn;

protected function getSetSystem
  input list<Integer> iEqns;
  input array<list<Integer>> inMapEqnIncRow;
  input array<Integer> inMapIncRowEqn;
  input array<Integer> vec1;
  input BackendDAE.Variables iVars;
  input BackendDAE.EquationArray iEqnsArr;
  input array<Boolean> flag;
  input Integer n;
  input list<BackendDAE.Equation> iEqnsLst;
  input list<BackendDAE.Var> iVarsLst;
  input list<Integer> iAss1;
  input list<Integer> iAss2;
  output list<BackendDAE.Equation> oEqnsLst;
  output list<BackendDAE.Var> oVarsLst;
  output list<Integer> oAss1;
  output list<Integer> oAss2;
  output BackendDAE.EquationArray oEqnsArr;
algorithm
  (oEqnsLst,oVarsLst,oAss1,oAss2,oEqnsArr) :=
  matchcontinue iEqns
    local
      Integer e,e1;
      list<Integer> rest,eqns,vindx,ass,ass1,ass2;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> varlst;
      BackendDAE.EquationArray eqnarr;
    case {} then (iEqnsLst,iVarsLst,iAss1,iAss2,iEqnsArr);
    case e::rest
      guard flag[e] and intGt(vec1[e],0)
      equation
        e1 = inMapIncRowEqn[e];
        // print("BackendEquation.get " + intString(e1) + "\n");
        eqn = BackendEquation.get(iEqnsArr,e1);
        eqnarr = BackendEquation.delete(e1,iEqnsArr);
        eqns = inMapEqnIncRow[e1];
        _ = List.fold1r(eqns,arrayUpdate,false,flag);
        vindx = List.map1r(eqns,arrayGet,vec1);
        varlst = List.map1r(vindx,BackendVariable.getVarAt,iVars);
        varlst = listAppend(varlst,iVarsLst);
        ass = List.intRange2(n-listLength(eqns)+1, n);
        ass1 = listAppend(ass,iAss1);
        ass2 = listAppend(ass,iAss2);
        (oEqnsLst,oVarsLst,ass1,ass2,eqnarr) = getSetSystem(rest,inMapEqnIncRow,inMapIncRowEqn,vec1,iVars,eqnarr,flag,n-listLength(eqns),eqn::iEqnsLst,varlst,ass1,ass2);
      then
        (oEqnsLst,oVarsLst,ass1,ass2,eqnarr);
    case _::rest
      equation
        (oEqnsLst,oVarsLst,ass1,ass2,eqnarr) = getSetSystem(rest,inMapEqnIncRow,inMapIncRowEqn,vec1,iVars,iEqnsArr,flag,n,iEqnsLst,iVarsLst,iAss1,iAss2);
      then
        (oEqnsLst,oVarsLst,ass1,ass2,eqnarr);
  end matchcontinue;
end getSetSystem;

protected function getSetStates
  input Integer e;
  input array<Boolean> flag;
  input BackendDAE.IncidenceMatrix inM;
  input array<Integer> vec2;
  input tuple<list<Integer>,list<Integer>> iStates;
  output tuple<list<Integer>,list<Integer>> oStates;
algorithm
  oStates := List.fold3(inM[e],getSetEqnStates,flag,inM,vec2,iStates);
end getSetStates;

protected function getSetEqnStates
  input Integer v;
  input array<Boolean> flag;
  input BackendDAE.IncidenceMatrix inM;
  input array<Integer> vec2;
  input tuple<list<Integer>,list<Integer>> iStates;
  output tuple<list<Integer>,list<Integer>> oStates;
protected
 list<Integer> states,dstates;
algorithm
  (states,dstates) := iStates;
  states := List.consOnTrue(intLt(vec2[v],1) and flag[v],v,states);
  dstates := List.consOnTrue(intGt(vec2[v],0) and flag[v],v,dstates);
  _ := arrayUpdate(flag,v,false);
  oStates := (states,dstates);
end getSetEqnStates;

protected function getEqnsforDynamicStateSelection
"function getEqnsforDynamicStateSelection, collect all equations for the dynamic state selection set from the
 unmatched equations
 author: Frenkel TUD 2012-12"
  input list<Integer> U;
  input Integer neqns;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output list<Integer> eqns;
algorithm
  eqns := match(U,neqns,m,mT,ass1,ass2,mapEqnIncRow,mapIncRowEqn)
    local
      array<Integer> colummarks;
    case({},_,_,_,_,_,_,_) then {};
    case(_,_,_,_,_,_,_,_)
      equation
        colummarks = arrayCreate(neqns,0);
      then
        getEqnsforDynamicStateSelection1(U,m,mT,1,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,{});
  end match;
end getEqnsforDynamicStateSelection;

protected function getEqnsforDynamicStateSelection1
"function getEqnsforDynamicStateSelection1, helper for getEqnsforDynamicStateSelection
 author: Frenkel TUD 2012-12"
  input list<Integer> U;
  input BackendDAE.IncidenceMatrix m "m[eqnindx] = list(varindx)";
  input BackendDAE.IncidenceMatrixT mT "mT[varindx] = list(eqnindx)";
  input Integer mark;
  input array<Integer> colummarks;
  input array<Integer> ass1 "ass[eqnindx]=varindx";
  input array<Integer> ass2 "ass[varindx]=eqnindx";
  input array<list<Integer>> mapEqnIncRow "eqn indx -> skalar Eqn indexes";
  input array<Integer> mapIncRowEqn "scalar eqn index -> eqn indx";
  input list<Integer> inSubset;
  output list<Integer> outSubset;
algorithm
  outSubset:= matchcontinue (U,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset)
    local
      list<Integer> rest,eqns,set;
      Integer e,e1;
    case ({},_,_,_,_,_,_,_,_,_) then inSubset;
    case (e::rest,_,_,_,_,_,_,_,_,_)
      equation
        // row is not visited
        true = intEq(colummarks[e],0);
        // if it is a multi dim equation take all scalare equations
        e1 = mapIncRowEqn[e];
        eqns = mapEqnIncRow[e1];
        _ = List.fold1r(eqns,arrayUpdate,mark,colummarks);
        //  print("Seach for unassigned Eqns " + stringDelimitList(List.map(eqns,intString),", ") + "\n");
        (set,_) = getEqnsforDynamicStateSelectionPhase(eqns,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset,false);
      then
        getEqnsforDynamicStateSelection1(rest,m,mT,mark+1,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,set);
    case (_::rest,_,_,_,_,_,_,_,_,_)
      then
        getEqnsforDynamicStateSelection1(rest,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset);
  end matchcontinue;
end getEqnsforDynamicStateSelection1;

protected function getEqnsforDynamicStateSelectionPhase
"author: Frenkel TUD 2012-12"
  input list<Integer> elst;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<list<Integer>> mapEqnIncRow "eqn indx -> skalar Eqn indexes";
  input array<Integer> mapIncRowEqn "scalar eqn index -> eqn indx";
  input list<Integer> inSubset;
  input Boolean iFound;
  output list<Integer> outSubset;
  output Boolean oFound;
algorithm
  (outSubset,oFound) :=
  match (elst,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset,iFound)
    local
      Integer e;
      list<Integer> rows,rest,set;
      Boolean found;
    case ({},_,_,_,_,_,_,_,_,_,_) then (inSubset,iFound);
    case (e::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // traverse all adiacent rows but not the assigned
        rows = List.select(m[e], Util.intPositive);
        rows = List.removeOnTrue(ass1[e], intEq, rows);
        // print("search in Rows " + stringDelimitList(List.map(rows,intString),", ") + " from " + intString(e) + "\n");
        (set,found) = getEqnsforDynamicStateSelectionRows(rows,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset,false);
        // print("add " + boolString(found) + " equation " + intString(e) + "\n");
        set = List.consOnTrue(found, e, set);
        arrayUpdate(colummarks,e,if found then mark else colummarks[e]);
        (set,found) = getEqnsforDynamicStateSelectionPhase(rest,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,set,found or iFound);
      then
        (set,found);
  end match;
end getEqnsforDynamicStateSelectionPhase;

protected function getEqnsforDynamicStateSelectionRows
"author: Frenkel TUD 2012-12"
  input list<Integer> rows;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mT;
  input Integer mark;
  input array<Integer> colummarks;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input array<list<Integer>> mapEqnIncRow "eqn indx -> skalar Eqn indexes";
  input array<Integer> mapIncRowEqn "scalar eqn index -> eqn indx";
  input list<Integer> inSubset;
  input Boolean iFound;
  output list<Integer> outSubset;
  output Boolean oFound;
algorithm
  (outSubset,oFound):=
  matchcontinue (rows,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset,iFound)
    local
      list<Integer> rest,set,eqns;
      Integer rc,r,e;
      Boolean b;
    case ({},_,_,_,_,_,_,_,_,_,_) then (inSubset,iFound);
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is free
        // print("check Row " + intString(r) + "\n");
        rc = ass2[r];
        // print("check Colum " + intString(rc) + "\n");
        false = intGt(rc,0);
        // print("Found free eqn " + intString(rc) + "\n");
        (set,b) = getEqnsforDynamicStateSelectionRows(rest,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset,true);
      then
        (set,b);
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        // print("check Row " + intString(r) + "\n");
        rc = ass2[r];
        // print("check Colum " + intString(rc) + "\n");
        true = intGt(rc,0);
        true = intEq(colummarks[rc],0);
        // if it is a multi dim equation take all scalare equations
        e = mapIncRowEqn[rc];
        eqns = mapEqnIncRow[e];
        List.fold1r(eqns,arrayUpdate,if iFound then mark else -mark,colummarks);
        // print("traverse Eqns " + stringDelimitList(List.map(eqns,intString),", ") + "\n");
        (set,b) = getEqnsforDynamicStateSelectionPhase(eqns,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset,false);
        eqns = if b and not iFound then eqns else {};
        _ = List.fold1r(eqns,arrayUpdate,mark,colummarks);
        (set,b) = getEqnsforDynamicStateSelectionRows(rest,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,set,b or iFound);
      then
        (set,b);
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        // print("check Row " + intString(r) + "\n");
        rc = ass2[r];
        // print("check Colum " + intString(rc) + "\n");
        true = intGt(rc,0);
        b = intGt(colummarks[rc],0);
        // print("Found " + boolString(b) + " equation " + intString(rc) + "\n");
        (set,b) = getEqnsforDynamicStateSelectionRows(rest,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset,b or iFound);
      then
        (set,b);
  end matchcontinue;
end getEqnsforDynamicStateSelectionRows;

protected function removeFirstOrgEqns
"author: Frenkel TUD 2011-11
  removes the first equation of each the orgeqn list."
  input BackendDAE.ConstraintEquations inOrgEqns;
  output list<BackendDAE.Equation> outEqnsLst = {};
  output BackendDAE.ConstraintEquations outOrgEqns;
protected
  tuple<Integer,list<BackendDAE.Equation>> orgEqn;
  list<BackendDAE.Equation> orgeqns;
  Integer e, numEqs;
algorithm
  outOrgEqns := inOrgEqns;
  numEqs := arrayLength(inOrgEqns);
  for e in 1:numEqs loop
    orgeqns := arrayGet(outOrgEqns,e);
    if not listEmpty(orgeqns) then
      (outEqnsLst, orgeqns) := match orgeqns
                               local BackendDAE.Equation eqn; list<BackendDAE.Equation> eqns;
                               case {eqn} then (eqn :: outEqnsLst, {});
                               case eqn::eqns then (eqn :: outEqnsLst, eqns);
                               end match;
      arrayUpdate(outOrgEqns,e,orgeqns);
    end if;
  end for;
end removeFirstOrgEqns;

protected function sortStateCandidatesVars
"author: Frenkel TUD 2012-08
  sort the state candidates"
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables allVars;
  input Option<BackendDAE.IncidenceMatrix> m;
  output BackendDAE.Variables outStates;
protected
  Integer varsize;
  list<Integer> varIndices;
  list<tuple<Integer,Real>> prioTuples;
  BackendDAE.Var v;
  DAE.ComponentRef varCref;
  Real prio1,prio2;
  array<Real> prio;
  array<Integer> index;
  Integer idx;
  list<BackendDAE.Var> vlst;
  list<tuple<Real,Integer>> prio_lst;
algorithm
  varsize := BackendVariable.varsSize(inVars);
  index := arrayCreate(varsize, -1);
  prio := arrayCreate(varsize, -1.0);

  for idx in 1:varsize loop
    v := BackendVariable.getVarAt(inVars,idx);
    (prio1, prio2) := varStateSelectPrio(v,allVars,idx,m);
    prio[idx] := prio1 + prio2;
    index[idx] := idx;
    if Flags.isSet(Flags.DUMMY_SELECT) then
      varCref := BackendVariable.varCref(v);
      BackendDump.debugStrCrefStrRealStrRealStrRealStr("Calc Prio for ",varCref,"\n Prio StateSelect : ",prio1,"\n Prio Heuristik : ",prio2,"\n ### Prio Result : ",prio[idx],"\n");
    end if;
  end for;

  //sort
  prioTuples := list( (index[idx] ,prio[idx]) for idx in varsize:-1:1);
  prioTuples := List.sort(prioTuples,sortprioTuples);
  varIndices := list(Util.tuple21(elem)  for elem in prioTuples);
  vlst := list(BackendVariable.getVarAt(inVars,idx) for idx in varIndices);
  outStates := BackendVariable.listVar1(vlst);

end sortStateCandidatesVars;

protected function sortprioTuples
"author: Frenkel TUD 2011-05
  helper for sortStateCandidates"
  input tuple<Integer,Real> inTpl1;
  input tuple<Integer,Real> inTpl2;
  output Boolean b;
algorithm
  b:=  Util.tuple22(inTpl1) > Util.tuple22(inTpl2);
end sortprioTuples;

protected function varStateSelectPrio
"
Calculates a priority contribution bases on the stateSelect attribute and heuristic.
"
  input BackendDAE.Var v;
  input BackendDAE.Variables vars;
  input Integer index;
  input Option<BackendDAE.IncidenceMatrix> m;
  output Real prio_att;
  output Real prio_heu;
algorithm
  prio_att := varStateSelectPrioAttribute(v);
  prio_heu := varStateSelectHeuristicPrio(v, vars, index, m);
end varStateSelectPrio;

protected function varStateSelectHeuristicPrio
"author: Frenkel TUD 2012-08"
  input BackendDAE.Var v;
  input BackendDAE.Variables vars;
  input Integer index;
  input Option<BackendDAE.IncidenceMatrix> m;
  output Real prio;
protected
  Real prio1,prio2,prio3,prio4,prio5;
  Boolean bstart, bfixed;
algorithm
  // start?
  bstart := isSome(BackendVariable.varStartValueOption(v));
  // fixed?
  bfixed := BackendVariable.varFixed(v);
  if bstart and bfixed then
    prio1 := 0.5;
    prio2 := 0.5;
  elseif bfixed then
    prio1 := 0.1;
    prio2 := 0.5;
  elseif bstart then
    prio1 := 0.1;
    prio2 := 0.0;
  else
    prio1 := 0.0;
    prio2 := 0.0;
  end if;

  prio3 := varStateSelectHeuristicPrio3(v);
  prio4 := varStateSelectHeuristicPrio4(v,vars);
  prio5 := varStateSelectHeuristicPrio5(v,index,m);
  prio := prio1 + prio2 + prio3 + prio4 + prio5;
  printVarListtateSelectHeuristicPrio(prio1,prio2,prio3,prio4,prio5);

end varStateSelectHeuristicPrio;

protected function printVarListtateSelectHeuristicPrio
  input Real Prio1;
  input Real Prio2;
  input Real Prio3;
  input Real Prio4;
  input Real Prio5;
algorithm
  if Flags.isSet(Flags.DUMMY_SELECT) then
    print("Prio 1 : " + realString(Prio1) + "\n");
    print("Prio 2 : " + realString(Prio2) + "\n");
    print("Prio 3 : " + realString(Prio3) + "\n");
    print("Prio 4 : " + realString(Prio4) + "\n");
    print("Prio 5 : " + realString(Prio5) + "\n");
  end if;
end printVarListtateSelectHeuristicPrio;

protected function varStateSelectHeuristicPrio5
"author: Frenkel TUD 2013-01
  Helper function to varStateSelectHeuristicPrio.
  added prio for states/variables, good state have much edges -> brackes loops"
  input BackendDAE.Var v;
  input Integer index;
  input Option<BackendDAE.IncidenceMatrix> om;
  output Real prio;
algorithm
  prio := match(om)
    local
      list<Integer> row;
      BackendDAE.IncidenceMatrix m;
      Real n;
    case(NONE()) then 0.0;
    case(SOME(m))
      equation
        row = m[index];
        n = intReal(arrayLength(m)) + 1.0;
        n = intReal(listLength(row))/n;
      then 0.3*n;
  end match;
end varStateSelectHeuristicPrio5;

protected function varStateSelectHeuristicPrio4
"author: Frenkel TUD 2012-08
  Helper function to varStateSelectHeuristicPrio.
  added prio for states/variables wich are derivatives of deselected states"
  input BackendDAE.Var inVar;
  input BackendDAE.Variables vars;
  output Real prio;
algorithm
  prio := matchcontinue(inVar,vars)
    local
      DAE.ComponentRef cr;
      BackendDAE.Var v;
      Boolean b;
    case(BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(cr))),_)
      equation
        (v,_) = BackendVariable.getVarSingle(cr, vars);
        b = BackendVariable.isDummyStateVar(v);
        prio = if b then 0.0 else 0.55;
      then prio;
    else 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio4;

protected function varStateSelectHeuristicPrio3
"author: Frenkel TUD 2012-04
  Helper function to varStateSelectHeuristicPrio.
  added prio for variables with $DER. name. Thouse are dummy_states
  added by index reduction from normal variables"
  input BackendDAE.Var v;
  output Real prio;
algorithm
  prio := matchcontinue(v)
    local
      DAE.ComponentRef cr;
    case(BackendDAE.VAR(varName=cr))
      guard stringEq( ComponentReference.crefFirstIdent(cr),"$DER")
      then -5.0;
    else 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio3;

protected function varStateSelectPrioAttribute
"Helper function to calculateVarPriorities.
  Calculates a priority contribution bases on the stateSelect attribute."
  input BackendDAE.Var v;
  output Real prio;
  protected
  DAE.StateSelect ss;
algorithm
  ss := BackendVariable.varStateSelect(v);
  prio := match ss
          case DAE.NEVER() then -20.0;
          case DAE.AVOID() then -1.5;
          case DAE.DEFAULT() then 0.0;
          case DAE.PREFER() then 1.5;
          case DAE.ALWAYS() then 20.0;
          end match;
end varStateSelectPrioAttribute;

protected function selectDummyDerivatives2new
"author: Frenkel TUD 2012-05
  select dummy derivatives from strong connected component"
  input list<tuple<DAE.ComponentRef, Integer>> dstates;
  input list<tuple<DAE.ComponentRef, Integer>> states;
  input list<Integer> unassignedEqns;
  input list<Integer> assignedEqns;
  input BackendDAE.Variables vars;
  input Integer varSize;
  input BackendDAE.EquationArray eqns;
  input Integer eqnsSize;
  input array<Integer> mapIncRowEqn;
  input Integer level;
  input StateSets iStateSets;
  output list<BackendDAE.Var> outDummyVars;
  output StateSets oStateSets;
algorithm
  (outDummyVars,oStateSets) :=
  matchcontinue dstates
      local
        list<BackendDAE.Var> varlst,statecandidates,ovarlst;
        Integer unassignedEqnsSize,size,rang;
        list<BackendDAE.Equation> eqnlst,oeqnlst;
        list<Integer> unassignedEqns1,assignedEqns1;
    case _
      guard intEq(listLength(dstates),eqnsSize)
      equation
        if Flags.isSet(Flags.BLT_DUMP) then
          print("Select as States(1):\n");
          BackendDump.debuglst(states,dumpStates,"\n","\n");
          print("Select as dummyStates(1):\n");
          BackendDump.debuglst(dstates,dumpStates,"\n","\n");
        end if;
      then
        ({},iStateSets);
    case _
      equation
        unassignedEqnsSize = listLength(unassignedEqns);
        size = listLength(states);
        rang = size-unassignedEqnsSize;
        true = intGt(rang,0);
        if Flags.isSet(Flags.BLT_DUMP) then
          BackendDump.debugStrIntStrIntStr("Select ",rang," from ",size," States\n");
          BackendDump.debuglst(states,dumpStates,"\n","\n");
          print("Select as dummyStates(2):\n");
          BackendDump.debuglst(dstates,dumpStates,"\n","\n");
        end if;
        // collect information for stateset
        statecandidates = List.map1r(List.map(states,Util.tuple22),BackendVariable.getVarAt,vars);
        unassignedEqns1 = List.uniqueIntN(List.map1r(unassignedEqns,arrayGet,mapIncRowEqn), eqnsSize);
        eqnlst = BackendEquation.getList(unassignedEqns1, eqns);
        ovarlst = List.map1r(List.map(dstates,Util.tuple22),BackendVariable.getVarAt,vars);
        assignedEqns1 = List.uniqueIntN(List.map1r(assignedEqns,arrayGet,mapIncRowEqn), eqnsSize);
        oeqnlst = BackendEquation.getList(assignedEqns1, eqns);
        // add dummy states
        varlst = List.map1r(List.map(states,Util.tuple22),BackendVariable.getVarAt,vars);
      then
        (varlst,(level,rang,size,unassignedEqnsSize,statecandidates,eqnlst,ovarlst,oeqnlst)::iStateSets);
   // dummy derivative case - no dynamic state selection
   case _
      equation
        unassignedEqnsSize = listLength(unassignedEqns);
        size = listLength(states);
        rang = size-unassignedEqnsSize;
        if intLt(rang,0) then
          Error.addMessage(Error.INTERNAL_ERROR, {"Selection of DummyDerivatives failed due to negative system rank of "+intString(rang)+"!
           There are "+intString(unassignedEqnsSize)+" unassigned equations and "+intString(size)+" potential states.\n"}); end if;
        true = intEq(rang,0);
        if Flags.isSet(Flags.BLT_DUMP) then
          print("Select as dummyStates(3):\n");
          BackendDump.debuglst(states,dumpStates,"\n","\n");
        end if;
        // add dummy states
        varlst = List.map1r(List.map(states,Util.tuple22),BackendVariable.getVarAt,vars);
      then
        (varlst,iStateSets);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.selectDummyDerivatives2new failed!"});
      then
        fail();
  end matchcontinue;
end selectDummyDerivatives2new;

public function makeder "Author: Frenkel TUD 2012-09"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
protected
  DAE.Type tp;
algorithm
  tp := Expression.typeof(inExp);
  outExp := DAE.CALL(Absyn.IDENT("der"), {inExp}, DAE.CALL_ATTR(tp, false, true, false, false, DAE.NO_INLINE(),DAE.NO_TAIL()));
end makeder;

protected function notVarStateSelectAlways
"author: Frenkel TUD 2012-06
  true if var is not StateSelect.always"
  input BackendDAE.Var v;
  input Integer level;
  output Boolean b;
algorithm
  b := match v
    local Integer diffcount;
    case BackendDAE.VAR(varKind=BackendDAE.STATE(index=diffcount))
      then not(varStateSelectAlways(v) and (diffcount == level or diffcount == 1));
    else true;
  end match;
end notVarStateSelectAlways;

protected function varStateSelectAlways
"author: Frenkel TUD 2012-06
  return true if var is StateSelect.always else false"
  input BackendDAE.Var v;
  output Boolean b;
algorithm
  b := match(v)
    case BackendDAE.VAR(varKind=BackendDAE.STATE(),values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS())))) then true;
    else false;
  end match;
end varStateSelectAlways;

protected function incidenceMatrixfromEnhanced2
"author: Frenkel TUD 2012-11
  converts an AdjacencyMatrixEnhanced into a IncidenceMatrix"
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.Variables vars;
  output BackendDAE.IncidenceMatrix m;
algorithm
  m := Array.map1(me,incidenceMatrixElementfromEnhanced2,vars);
end incidenceMatrixfromEnhanced2;

protected function incidenceMatrixElementfromEnhanced2
"author: Frenkel TUD 2012-11
  helper for incidenceMatrixfromEnhanced2"
  input BackendDAE.AdjacencyMatrixElementEnhanced iRow;
  input BackendDAE.Variables vars;
  output BackendDAE.IncidenceMatrixElement oRow;
algorithm
  oRow := List.fold1(iRow, incidenceMatrixElementElementfromEnhanced2, vars, {});
  oRow := List.map(oRow,intAbs);
  oRow := listReverse(oRow);
end incidenceMatrixElementfromEnhanced2;

protected function incidenceMatrixElementElementfromEnhanced2
"author: Frenkel TUD 2012-11
  converts an AdjacencyMatrix entry into a IncidenceMatrix entry"
  input tuple<Integer, BackendDAE.Solvability, BackendDAE.Constraints> inTpl;
  input BackendDAE.Variables vars;
  input list<Integer> iRow;
  output list<Integer> oRow;
algorithm
  oRow := match(inTpl,vars,iRow)
    local Integer i;
    case ((i,BackendDAE.SOLVABILITY_SOLVED(),_),_,_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_CONSTONE(),_),_,_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_CONST(),_),_,_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_PARAMETER(b=true),_),_,_) then i::iRow;
//    case ((i,BackendDAE.SOLVABILITY_PARAMETER(b=false)),_,_) then incidenceMatrixElementElementfromEnhanced2_1(i,vars,iRow);
//    case ((i,BackendDAE.SOLVABILITY_LINEAR(b=_)),_,_) then incidenceMatrixElementElementfromEnhanced2_1(i,vars,iRow);
//    case ((i,BackendDAE.SOLVABILITY_NONLINEAR()),_,_) then incidenceMatrixElementElementfromEnhanced2_1(i,vars,iRow);
//    case ((i,BackendDAE.SOLVABILITY_NONLINEAR()),_,_) then iRow;
    else iRow;
  end match;
end incidenceMatrixElementElementfromEnhanced2;

// protected function incidenceMatrixElementElementfromEnhanced2_1
//   input Integer i;
//   input BackendDAE.Variables vars;
//   input list<Integer> iRow;
//   output list<Integer> oRow;
// protected
//   BackendDAE.Var v;
//   DAE.StateSelect s;
//   Integer si;
//   Boolean b;
// algorithm
//   v := BackendVariable.getVarAt(vars,intAbs(i));
//   s := BackendVariable.varStateSelect(v);
//   si := BackendVariable.stateSelectToInteger(s);
// //  oRow := List.consOnTrue(intLt(si,0),i,iRow);
//   b := BackendVariable.isStateVar(v);
//   oRow := List.consOnTrue(intLt(si,0) or not b,i,iRow);
// end incidenceMatrixElementElementfromEnhanced2_1;

protected function checkAssignment
"author: Frenkel TUD 2012-05
  selects the assigned vars"
  input Integer index;
  input Integer len;
  input array<Integer> ass;
  input BackendDAE.Variables vars;
  output list<tuple<DAE.ComponentRef, Integer>> outAssigned = {};
  output list<tuple<DAE.ComponentRef, Integer>> outUnassigned = {};
protected
  DAE.ComponentRef cr;
algorithm
   for indx in index:len loop
     BackendDAE.VAR(varName=cr) := BackendVariable.getVarAt(vars,indx);
     if  intGt(ass[indx],0) then
       outAssigned := (cr,indx) :: outAssigned;
     else
       outUnassigned := (cr,indx) :: outUnassigned;
     end if;
   end for;
end checkAssignment;

protected function getLevelStates
  input BackendDAE.Var inVar;
  input Integer level;
  input HashTableCrIntToExp.HashTable iHt;
  output BackendDAE.Var outVar;
  output HashTableCrIntToExp.HashTable oHt;
algorithm
  (outVar,oHt) := matchcontinue(inVar,level,iHt)
    local
      HashTableCrIntToExp.HashTable ht;
      DAE.ComponentRef name,cr;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      DAE.Type tp;
      DAE.InstDims dim;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> odattr;
      Option<BackendDAE.TearingSelect> ts;
      DAE.Exp hideResult;
      DAE.VariableAttributes dattr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var var;
      DAE.Exp e;
      Integer diffcount,n;
      Option<DAE.ComponentRef> derName;
      DAE.VarInnerOuter io;
   // state no derivative known
    case (BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE(index=diffcount,derName=NONE()),varDirection=dir,varParallelism=prl,varType=tp,arryDim=dim,source=source,tearingSelectOption=ts,hideResult=hideResult,comment=comment,connectorType=ct,innerOuter=io),_,_)
      guard intGt(diffcount,1)
      equation
        n = diffcount-level;
        true = intGt(n,0);
        cr = List.foldcallN(n, ComponentReference.crefPrefixDer, name);
        // generate replacement
        e = Expression.crefExp(cr);
        ht = BaseHashTable.add(((name,n),e),iHt);
        // generate Dummy Var
        /* Dummy variables are algebraic variables without start value, min/max, .., hence fixed = false */
        dattr = BackendVariable.getVariableAttributefromType(tp);
        odattr = DAEUtil.setFixedAttr(SOME(dattr), SOME(DAE.BCONST(false)));
        //kind = if_(intGt(n,1),BackendDAE.DUMMY_DER(),BackendDAE.STATE(1,NONE()));
        var = BackendDAE.VAR(cr,BackendDAE.STATE(1,NONE()),dir,prl,tp,NONE(),NONE(),dim,source,odattr,ts,hideResult,comment,ct,io,false);
      then (var,ht);
   // state
    case (BackendDAE.VAR(varKind=BackendDAE.STATE(index=diffcount,derName=derName)),_,_)
      guard intGt(diffcount,1)
      equation
        var = BackendVariable.setVarKind(inVar, BackendDAE.STATE(1,derName));
      then (var,iHt);
    else (inVar,iHt);
  end matchcontinue;
end getLevelStates;

protected function replaceHigherDerivatives
"author: Frenkel TUD 2013-01
  change for var:STATE(2): der(var,2) to der($DER.var), der(var) -> DER.var, add Var $DER.var:STATE(1)"
  input BackendDAE.EqSystem inSystem;
  output BackendDAE.EqSystem osyst = inSystem;
protected
  BackendDAE.Variables vars;
  HashTableCrIntToExp.HashTable ht;
  list<BackendDAE.Var> dummyvars;
  array<Integer> ass1, ass2;
  list<tuple<Integer,Integer>> addassign;
  Integer nv1, nv;
algorithm
  // traverse vars and generate dummy vars and replacement rules
  ht := HashTableCrIntToExp.emptyHashTable();
  nv := BackendVariable.varsSize(osyst.orderedVars);
  BackendDAE.MATCHING(ass1=ass1, ass2=ass2) := osyst.matching;

  (vars, (_, _, nv1, addassign, dummyvars, ht)) :=
      BackendVariable.traverseBackendDAEVarsWithUpdate( osyst.orderedVars, makeHigherStatesRepl,
                                                        (osyst.orderedVars, 1, nv, {}, {}, ht) );
  // BaseHashTable.dumpHashTable(ht);
  // add dummy Vars;
  dummyvars := listReverse(dummyvars);
  vars := BackendVariable.addVars(dummyvars, vars);
  // perform replacement rules
  (osyst.orderedVars, _) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars, replaceDummyDerivativesVar, ht);
  BackendDAEUtil.traverseBackendDAEExpsEqns( osyst.orderedEqs, Expression.traverseSubexpressionsHelper,
                                                       (replaceDummyDerivativesExp, ht) );
  // extend assignments
  ass1 := Array.expand(nv1-nv, ass1, -1);
  // set the new assignments
  List.map2_0(addassign, setHigerDerivativeAssignment, ass1, ass2);
  osyst.matching := BackendDAE.MATCHING(ass1, ass2, {});
end replaceHigherDerivatives;

protected function setHigerDerivativeAssignment
  input tuple<Integer,Integer> inTpl;
  input array<Integer> ass1;
  input array<Integer> ass2;
protected
  Integer i,j,e;
algorithm
  (i,j) := inTpl;
  e := ass1[i];
  _ := arrayUpdate(ass1,i,-1);
  _ := arrayUpdate(ass1,j,e);
  _ := arrayUpdate(ass2,e,j);
end setHigerDerivativeAssignment;

protected function makeHigherStatesRepl
"author: Frenkel TUD 2013-01
  This function creates a new variable named
  der+<varname> and adds it to the dae. The kind of the
  var with varname is changed to dummy_state"
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables,Integer,Integer,list<tuple<Integer,Integer>>,list<BackendDAE.Var>,HashTableCrIntToExp.HashTable> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendDAE.Variables,Integer,Integer,list<tuple<Integer,Integer>>,list<BackendDAE.Var>,HashTableCrIntToExp.HashTable> oTpl;
algorithm
  (outVar,oTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Variables vars;
      HashTableCrIntToExp.HashTable ht;
      DAE.ComponentRef name,cr;
      BackendDAE.Var var;
      Integer diffcount,i,j;
      list<BackendDAE.Var> varlst;
      list<tuple<Integer,Integer>> addassign;
    // state diffed more than once
    case (var as BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE(index=diffcount,derName=NONE())),(vars,i,j,addassign,varlst,ht))
      equation
        true = intGt(diffcount,1);
        // dummy_der name
        cr = ComponentReference.crefPrefixDer(name);
        // add replacement for each derivative
        (varlst,ht,j) = makeHigherStatesRepl1(diffcount-2,2,name,cr,var,vars,varlst,ht,j);
      then (var,(vars,i+1,j,(i,j)::addassign,varlst,ht));
    case (var,(vars,i,j,addassign,varlst,ht)) then (var,(vars,i+1,j,addassign,varlst,ht));
  end matchcontinue;
end makeHigherStatesRepl;

protected function makeHigherStatesRepl1
"author: Frenkel TUD 2013-01
  This function creates a new variable named
  der+<varname> and adds it to the var list. The kind of the
  var with varname is changed to dummy_state"
  input Integer diffCount;
  input Integer diffedCount;
  input DAE.ComponentRef iOrigName;
  input DAE.ComponentRef iName;
  input BackendDAE.Var inVar;
  input BackendDAE.Variables vars;
  input list<BackendDAE.Var> iVarLst;
  input HashTableCrIntToExp.HashTable iHt;
  input Integer iN;
  output list<BackendDAE.Var> oVarLst;
  output HashTableCrIntToExp.HashTable oHt;
  output Integer oN;
algorithm
  (oVarLst,oHt,oN) := matchcontinue (diffCount,diffedCount,iOrigName,iName,inVar,vars,iVarLst,iHt,iN)
    local
      HashTableCrIntToExp.HashTable ht;
      DAE.ComponentRef name;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      DAE.Type tp;
      DAE.InstDims dim;
      DAE.ElementSource source;
      BackendDAE.VarKind kind;
      Option<DAE.VariableAttributes> odattr;
      Option<BackendDAE.TearingSelect> ts;
      DAE.Exp hideResult;
      DAE.VariableAttributes dattr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var var;
      list<BackendDAE.Var> vlst;
      DAE.Exp e;
      Integer n;
      DAE.VarInnerOuter io;
   // state no derivative known
    case (_,_,_,_,BackendDAE.VAR(varName=name,varDirection=dir,varParallelism=prl,varType=tp,arryDim=dim,source=source,tearingSelectOption=ts,hideResult=hideResult,comment=comment,connectorType=ct,innerOuter=io),_,_,_,_)
      equation
        true = intGt(diffCount,-1);
        name = ComponentReference.crefPrefixDer(iName);
        // generate replacement
        e = Expression.crefExp(name);
        ht = BaseHashTable.add(((iOrigName,diffedCount),e),iHt);
        // generate Dummy Var
        /* Dummy variables are algebraic variables without start value, min/max, .., hence fixed = false */
        dattr = BackendVariable.getVariableAttributefromType(tp);
        odattr = DAEUtil.setFixedAttr(SOME(dattr), SOME(DAE.BCONST(false)));
        kind = if intGt(diffCount,0) then BackendDAE.STATE(diffCount,NONE()) else BackendDAE.DUMMY_DER();
        var = BackendDAE.VAR(name,kind,dir,prl,tp,NONE(),NONE(),dim,source,odattr,ts,hideResult,comment,ct,io,false);
        (vlst,ht,n) = makeHigherStatesRepl1(diffCount-1,diffedCount+1,iOrigName,name,inVar,vars,var::iVarLst,ht,iN+1);
      then (vlst,ht,n);
    // finished
    case (_,_,_,_,_,_,_,_,_) then (iVarLst,iHt,iN);
  end matchcontinue;
end makeHigherStatesRepl1;

protected function addAllDummyStates
"author: Frenkel TUD 2013-01
  change all states not stateSelect.always to dummy states
  and add them to the system and generate replacement rules"
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.StateOrder so;
  input HashTableCrIntToExp.HashTable iHt;
  output BackendDAE.EqSystem osyst = inSystem;
  output HashTableCrIntToExp.HashTable oHt;
protected
  BackendDAE.Variables vars;
  list<BackendDAE.Var> dummvars;
algorithm
  // traverse vars and generate dummy vars and replacement rules
  (vars, (_, _, dummvars, oHt)) :=
      BackendVariable.traverseBackendDAEVarsWithUpdate( osyst.orderedVars, makeAllDummyVarandDummyDerivativeRepl,
                                                        (osyst.orderedVars, so, {}, iHt) );
  // BaseHashTable.dumpHashTable(oHt);
  // add dummy Vars;
  vars := BackendVariable.addVars(dummvars,vars);
  // perform replacement rules
  (osyst.orderedVars, _) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars, replaceDummyDerivativesVar, oHt);
  BackendDAEUtil.traverseBackendDAEExpsEqns( osyst.orderedEqs, Expression.traverseSubexpressionsHelper,
                                                       (replaceDummyDerivativesExp, oHt) );
end addAllDummyStates;

protected function makeAllDummyVarandDummyDerivativeRepl
"author: Frenkel TUD 2013-01
  This function creates a new variable named
  der+<varname> and adds it to the dae. The kind of the
  var with varname is changed to dummy_state"
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.Variables,BackendDAE.StateOrder,list<BackendDAE.Var>,HashTableCrIntToExp.HashTable> inTpl;
  output BackendDAE.Var outVar;
  output tuple<BackendDAE.Variables,BackendDAE.StateOrder,list<BackendDAE.Var>,HashTableCrIntToExp.HashTable> oTpl;
algorithm
  (outVar,oTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.StateOrder so;
      HashTableCrIntToExp.HashTable ht;
      DAE.ComponentRef name,cr;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      DAE.Type tp;
      Option<DAE.Exp> bind;
      Option<DAE.Exp> tplExp;
      DAE.InstDims dim;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> attr;
      Option<BackendDAE.TearingSelect> ts;
      DAE.Exp hideResult;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var var;
      Integer diffcount;
      list<BackendDAE.Var> varlst;
      DAE.VarInnerOuter io;
    // state with stateSelect.always, diffed once
    case (var as BackendDAE.VAR(varKind=BackendDAE.STATE(index=diffcount),values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS())))),_)
      guard intEq(diffcount,1)
      then (var,inTpl);
    // state with stateSelect.always, diffed more than once, known derivative
    case (var as BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(cr)),values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS())))),_)
      equation
        var = BackendVariable.setVarKind(var, BackendDAE.STATE(1,SOME(cr)));
      then (var,inTpl);
    // state with stateSelect.always, diffed more than once, unknown derivative
    case (var as BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE(index=diffcount,derName=NONE()),values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS())))),(vars,so,varlst,ht))
      equation
        // then replace not the highest state but the lower
        cr = ComponentReference.crefPrefixDer(name);
        // add replacement for each derivative
        (varlst,ht) = makeAllDummyVarandDummyDerivativeRepl1(diffcount-1,2,name,cr,var,vars,so,varlst,ht);
        var = BackendVariable.setVarKind(var, BackendDAE.STATE(1,NONE()));
      then (var,(vars,so,varlst,ht));
    // state, replaceable with known derivative
    case (var as BackendDAE.VAR(name,BackendDAE.STATE(derName=SOME(_)),dir,prl,tp,bind,tplExp,dim,source,attr,ts,hideResult,comment,ct,io),(vars,so,varlst,ht))
      equation
        // add replacement for each derivative
        (varlst,ht) = makeAllDummyVarandDummyDerivativeRepl1(1,1,name,name,var,vars,so,varlst,ht);
        cr = ComponentReference.crefPrefixDer(name);
        source = ElementSource.addSymbolicTransformation(source,DAE.NEW_DUMMY_DER(cr,{}));
      then (BackendDAE.VAR(name,BackendDAE.DUMMY_STATE(),dir,prl,tp,bind,tplExp,dim,source,attr,ts,hideResult,comment,ct,io,false),(vars,so,varlst,ht));
    // state replacable without unknown derivative
    case (var as BackendDAE.VAR(name,BackendDAE.STATE(index=diffcount,derName=NONE()),dir,prl,tp,bind,tplExp,dim,source,attr,ts,hideResult,comment,ct,io),(vars,so,varlst,ht))
      equation
        // add replacement for each derivative
        (varlst,ht) = makeAllDummyVarandDummyDerivativeRepl1(diffcount,1,name,name,var,vars,so,varlst,ht);
        // dummy_der name vor Source information
        cr = ComponentReference.crefPrefixDer(name);
        source = ElementSource.addSymbolicTransformation(source,DAE.NEW_DUMMY_DER(cr,{}));
      then (BackendDAE.VAR(name,BackendDAE.DUMMY_STATE(),dir,prl,tp,bind,tplExp,dim,source,attr,ts,hideResult,comment,ct,io,false),(vars,so,varlst,ht));
    else (inVar,inTpl);
  end matchcontinue;
end makeAllDummyVarandDummyDerivativeRepl;

protected function makeAllDummyVarandDummyDerivativeRepl1
"author: Frenkel TUD 2013-01
  This function creates a new variable named
  der+<varname> and adds it to the var list. The kind of the
  var with varname is changed to dummy_state"
  input Integer diffCount;
  input Integer diffedCount;
  input DAE.ComponentRef iOrigName;
  input DAE.ComponentRef iName;
  input BackendDAE.Var inVar;
  input BackendDAE.Variables vars;
  input BackendDAE.StateOrder so;
  input list<BackendDAE.Var> iVarLst;
  input HashTableCrIntToExp.HashTable iHt;
  output list<BackendDAE.Var> oVarLst;
  output HashTableCrIntToExp.HashTable oHt;
algorithm
  (oVarLst,oHt) := matchcontinue (diffCount,diffedCount,iOrigName,iName,inVar,vars,so,iVarLst,iHt)
    local
      HashTableCrIntToExp.HashTable ht;
      DAE.ComponentRef name;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      DAE.Type tp;
      DAE.InstDims dim;
      .DAE.ElementSource source;
      Option<DAE.VariableAttributes> odattr;
      Option<BackendDAE.TearingSelect> ts;
      DAE.Exp hideResult;
      DAE.VariableAttributes dattr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var var;
      list<BackendDAE.Var> vlst;
      DAE.Exp e;
      DAE.VarInnerOuter io;
    // finished
    case (0,_,_,_,_,_,_,_,_) then (iVarLst,iHt);
    // state
/*    case (_,_,_,_,_,_,_,_,_)
      equation
        // check state order and use the derivative
        cr = getStateOrder(iName,so);
        ({var},_) = BackendVariable.getVar(cr,vars);
        // generate replacement
        e = Expression.crefExp(cr);
        ht = BaseHashTable.add(((iOrigName,diffedCount),e),iHt);
        name = ComponentReference.crefPrefixDer(iName);
        (vlst,ht) = makeAllDummyVarandDummyDerivativeRepl1(diffCount-1,diffedCount+1,iOrigName,name,inVar,vars,so,iVarLst,ht);
      then (vlst,ht);
*/  // state no derivative known
    case (_,_,_,_,BackendDAE.VAR(varName=name,varDirection=dir,varParallelism=prl,varType=tp,arryDim=dim,source=source,tearingSelectOption=ts,hideResult=hideResult,comment=comment,connectorType=ct,innerOuter=io),_,_,_,_)
      equation
        name = ComponentReference.crefPrefixDer(iName);
        // generate replacement
        e = Expression.crefExp(name);
        ht = BaseHashTable.add(((iOrigName,diffedCount),e),iHt);
        // generate Dummy Var
        /* Dummy variables are algebraic variables without start value, min/max, .., hence fixed = false */
        dattr = BackendVariable.getVariableAttributefromType(tp);
        odattr = DAEUtil.setFixedAttr(SOME(dattr), SOME(DAE.BCONST(false)));
        var = BackendDAE.VAR(name,BackendDAE.DUMMY_DER(),dir,prl,tp,NONE(),NONE(),dim,source,odattr,ts,hideResult,comment,ct,io, false);
        (vlst,ht) = makeAllDummyVarandDummyDerivativeRepl1(diffCount-1,diffedCount+1,iOrigName,name,inVar,vars,so,var::iVarLst,ht);
      then (vlst,ht);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.makeAllDummyVarandDummyDerivativeRepl1 failed!"});
      then
        fail();
  end matchcontinue;
end makeAllDummyVarandDummyDerivativeRepl1;

protected function addDummyStates
"author: Frenkel TUD 2012-05
  add the dummy states to the system"
  input list<BackendDAE.Var> dummyStates;
  input Integer level;
  input HashTable2.HashTable repl;
  input BackendDAE.EqSystem inSystem;
  input HashTableCrIntToExp.HashTable iHt;
  output BackendDAE.EqSystem osyst;
  output HashTableCrIntToExp.HashTable oHt;
algorithm
  (osyst,oHt) := match (dummyStates, inSystem)
    local
      HashTableCrIntToExp.HashTable ht;
      BackendDAE.Variables vars;
      BackendDAE.EqSystem syst;
    case ({}, _)
      then (inSystem, iHt);
    case (_, syst)
      equation
        // create dummy_der vars and change deselected states to dummy states
        ((vars, ht)) = List.fold1(dummyStates, makeDummyVarandDummyDerivative, level, (syst.orderedVars, iHt));
        (syst.orderedVars, _) = BackendVariable.traverseBackendDAEVarsWithUpdate(vars, replaceDummyDerivativesVar, ht);
        _ = BackendDAEUtil.traverseBackendDAEExpsEqns( syst.orderedEqs, Expression.traverseSubexpressionsHelper,
                                                                 (replaceDummyDerivativesExp, ht) );
        _ = BackendDAEUtil.traverseBackendDAEExpsEqns( syst.orderedEqs, Expression.traverseSubexpressionsHelper,
                                                                 (replaceFirstOrderDerivativesExp, repl) );
      then (syst, ht);
  end match;
end addDummyStates;

protected function makeDummyVarandDummyDerivative
"author: Frenkel TUD
  This function creates a new variable named
  der+<varname> and adds it to the dae. The kind of the
  var with varname is changed to dummy_state"
  input BackendDAE.Var inVar;
  input Integer level;
  input tuple<BackendDAE.Variables,HashTableCrIntToExp.HashTable> inTpl;
  output tuple<BackendDAE.Variables,HashTableCrIntToExp.HashTable> oTpl;
algorithm
  oTpl := matchcontinue (inVar,level,inTpl)
    local
      HashTableCrIntToExp.HashTable ht;
      BackendDAE.Variables vars;
      DAE.ComponentRef name,dummyderName;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      DAE.Type tp;
      DAE.InstDims dim;
      .DAE.ElementSource source,source1;
      Option<DAE.VariableAttributes> odattr;
      Option<BackendDAE.TearingSelect> ts;
      DAE.Exp hideResult;
      DAE.VariableAttributes dattr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var dummy_state,dummy_derstate;
      Integer diffindex,dn;
      BackendDAE.VarKind kind;
      String msg;
      DAE.VarInnerOuter io;
    case (BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE(index=diffindex),varDirection=dir,varParallelism=prl,varType=tp,arryDim=dim,source=source,tearingSelectOption=ts,hideResult=hideResult,comment=comment,connectorType=ct,innerOuter=io),_,(vars,ht))
      equation
        dn = intMax(diffindex-level,0);
        // generate names
        (name,dummyderName) = crefPrefixDerN(dn,name);
        _ = ElementSource.addSymbolicTransformation(source,DAE.NEW_DUMMY_DER(dummyderName,{}));
        /* Dummy variables are algebraic variables, hence fixed = false */
        dattr = BackendVariable.getVariableAttributefromType(tp);
        odattr = DAEUtil.setFixedAttr(SOME(dattr), SOME(DAE.BCONST(false)));
        dummy_derstate = BackendDAE.VAR(dummyderName,BackendDAE.DUMMY_DER(),DAE.BIDIR(),prl,tp,NONE(),NONE(),dim,source,odattr,ts,hideResult,comment,ct,io, false);
        kind = if intEq(dn,0) then BackendDAE.DUMMY_STATE() else BackendDAE.DUMMY_DER();
        dummy_state = BackendDAE.VAR(name,kind,dir,prl,tp,NONE(),NONE(),dim,source,odattr,ts,hideResult,comment,ct,io, false);
        dummy_state = if intEq(dn,0) then inVar else dummy_state;
        dummy_state = BackendVariable.setVarKind(dummy_state, kind);
        vars = BackendVariable.addVar(dummy_derstate, vars);
        vars = BackendVariable.addVar(dummy_state, vars);
        diffindex = dn+1;
        ht = BaseHashTable.add(((name,diffindex),Expression.crefExp(dummyderName)),ht);
      then
        ((vars,ht));
    else
      equation
        msg = "IndexReduction.makeDummyVarandDummyDerivative failed " + BackendDump.varString(inVar) + "!";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
  end matchcontinue;
end makeDummyVarandDummyDerivative;

protected function crefPrefixDerN
"author Frenkel TUD 2013-01
  add n times $DER to name"
  input Integer n;
  input DAE.ComponentRef iName;
  output DAE.ComponentRef oName;
  output DAE.ComponentRef oDerName;
algorithm
  (oName,oDerName) := matchcontinue(n,iName)
    local
      DAE.ComponentRef name,dername;
    case(0,_)
      equation
        false = intGt(n,0);
        dername = ComponentReference.crefPrefixDer(iName);
      then
        (iName,dername);
    else
      equation
        dername = ComponentReference.crefPrefixDer(iName);
        (name,dername) = crefPrefixDerN(n-1,dername);
      then
        (name,dername);
  end matchcontinue;
end crefPrefixDerN;

protected function replaceFirstOrderDerivativesExp "author: Frenkel TUD 2013-01"
  input DAE.Exp inExp;
  input HashTable2.HashTable iht;
  output DAE.Exp outExp;
  output HashTable2.HashTable ht;
algorithm
  (outExp,ht) := matchcontinue (inExp,iht)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
    case (DAE.CREF(componentRef=cr),ht)
      equation
        e = BaseHashTable.get(cr,ht);
      then (e,ht);
    else (inExp,iht);
  end matchcontinue;
end replaceFirstOrderDerivativesExp;

protected function replaceDummyDerivativesExp "author: Frenkel TUD 2012-08"
  input DAE.Exp inExp;
  input HashTableCrIntToExp.HashTable iht;
  output DAE.Exp outExp;
  output HashTableCrIntToExp.HashTable ht;
algorithm
  (outExp,ht) := matchcontinue(inExp,iht)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
      Integer i;
      String msg;
    case (DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr),DAE.ICONST(i)}),ht)
      equation
        e = BaseHashTable.get((cr,i),ht);
      then (e,ht);
    case (DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr)}),ht)
      equation
        e = BaseHashTable.get((cr,1),ht);
      then (e,ht);
    case (e as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst=_::_::_),ht)
      equation
        msg = "IndexReduction.replaceDummyDerivativesExp failed for " + ExpressionDump.printExpStr(e) + "!";
        Error.addMessage(Error.COMPILER_WARNING, {msg});
      then (e,ht);
    else (inExp,iht);
  end matchcontinue;
end replaceDummyDerivativesExp;

protected function replaceDummyDerivatives
"author Frenkel TUD 2012-08"
  input BackendDAE.EqSystem inSyst;
  input HashTableCrIntToExp.HashTable ht;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outSyst = inSyst;
  output BackendDAE.Shared outShared = inShared;
protected
  BackendDAE.EventInfo eventInfo;
algorithm
  BackendVariable.traverseBackendDAEVarsWithUpdate(outShared.aliasVars, replaceDummyDerivativesVar, ht);
  BackendVariable.traverseBackendDAEVarsWithUpdate(outShared.globalKnownVars, replaceDummyDerivativesVar, ht);
  BackendDAEUtil.traverseBackendDAEExpsEqns( outShared.initialEqs, Expression.traverseSubexpressionsHelper,
                                                       (replaceDummyDerivativesExp, ht) );
  BackendDAEUtil.traverseBackendDAEExpsEqns( outSyst.removedEqs, Expression.traverseSubexpressionsHelper,
                                                       (replaceDummyDerivativesExp, ht) );
  BackendDAEUtil.traverseBackendDAEExpsEqns( outShared.removedEqs, Expression.traverseSubexpressionsHelper,
                                                       (replaceDummyDerivativesExp, ht) );
end replaceDummyDerivatives;

protected function replaceDummyDerivativesVar
"author: Frenkel TUD 2012-08"
 input BackendDAE.Var inVar;
 input HashTableCrIntToExp.HashTable inHt;
 output BackendDAE.Var outVar;
 output HashTableCrIntToExp.HashTable outHt;
algorithm
  (outVar,outHt) := matchcontinue (inVar,inHt)
    local
      BackendDAE.Var v,v1;
      HashTableCrIntToExp.HashTable ht;
      DAE.Exp e,e1;
      Option<DAE.VariableAttributes> attr;

    case (v as BackendDAE.VAR(bindExp=SOME(e),values=attr),ht)
      equation
        (e1, _) = Expression.traverseExpBottomUp(e, replaceDummyDerivativesExp, ht);
        v1 = BackendVariable.setBindExp(v, SOME(e1));
        (attr,_) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,Expression.traverseSubexpressionsHelper,(replaceDummyDerivativesExp,ht));
        v1 = BackendVariable.setVarAttributes(v1,attr);
      then (v1,ht);

    case  (v as BackendDAE.VAR(values=attr),ht)
      equation
        (attr,_) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,Expression.traverseSubexpressionsHelper,(replaceDummyDerivativesExp,ht));
        v1 = BackendVariable.setVarAttributes(v,attr);
      then (v1,ht);
  end matchcontinue;
end replaceDummyDerivativesVar;

public function splitEqnsinConstraintAndOther "author: Frenkel TUD 2013-01
  splitt the list of set equations in constrained equations and other equations"
  input list<BackendDAE.Var> inVarLst;
  input list<BackendDAE.Equation> inEqnsLst;
  input BackendDAE.Shared shared;
  output list<BackendDAE.Equation> outCEqnsLst;
  output list<BackendDAE.Equation> outOEqnsLst;
protected
  list<BackendDAE.Equation> eqnslst;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.EqSystem syst;
  BackendDAE.AdjacencyMatrixEnhanced me;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn;
  BackendDAE.IncidenceMatrix m;
  Integer ne,nv;
  array<Integer> vec1,vec2;
  list<Integer> unassigned,assigned;
algorithm
  vars := BackendVariable.listVar1(inVarLst);
  (eqnslst, _) := InlineArrayEquations.getScalarArrayEqns(inEqnsLst);
  eqns := BackendEquation.listEquation(eqnslst);
  syst := BackendDAEUtil.createEqSystem(vars, eqns);
  (me, _, mapEqnIncRow, mapIncRowEqn) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst, shared, false);
  m := incidenceMatrixfromEnhanced2(me, vars);
  // match the equations, umatched are constrained equations
  nv := BackendVariable.varsSize(vars);
  ne := BackendEquation.equationArraySize(eqns);
  vec1 := arrayCreate(nv,-1);
  vec2 := arrayCreate(ne,-1);
  Matching.matchingExternalsetIncidenceMatrix(nv,ne,m);
  BackendDAEEXT.matching(nv,ne,5,-1,1.0,1);
  BackendDAEEXT.getAssignment(vec2,vec1);
  unassigned := Matching.getUnassigned(ne, vec2, {});
  assigned := Matching.getAssigned(ne, vec2, {});
  unassigned := List.map1r(unassigned,arrayGet,mapIncRowEqn);
  unassigned := List.uniqueIntN(unassigned, ne);
  outCEqnsLst := BackendEquation.getList(unassigned, eqns);
  assigned := List.map1r(assigned,arrayGet,mapIncRowEqn);
  assigned := List.uniqueIntN(assigned, ne);
  outOEqnsLst := BackendEquation.getList(assigned, eqns);
end splitEqnsinConstraintAndOther;

protected function changeDerVariablesToStatesFinder
"author: Frenkel TUD 2011-05
  helper for changeDerVariablestoStates"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,BackendDAE.EquationArray,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrix> inTpl;
  output DAE.Exp outExp;
  output tuple<BackendDAE.Variables,BackendDAE.EquationArray,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrixT> outTpl;
algorithm
  (outExp,outTpl) := match (inExp,inTpl)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      list<Integer> ilst,changedVars;
      list<BackendDAE.Var> varlst;
      array<Integer> mapIncRowEqn;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.EquationArray eqns;
      Integer index,eindx;
     /* der(var), change algebraic to states */
     case (e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,ilst,eindx,mapIncRowEqn,mt))
      equation
        (varlst,changedVars) = BackendVariable.getVar(cr,vars);
        (vars,ilst) = algebraicState(varlst,changedVars,vars,ilst);
      then
        (e, (vars,eqns,ilst,eindx,mapIncRowEqn,mt));
    /* der(der(var)), set differentiation counter = 2 */
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {e as DAE.CREF(componentRef = cr)})}),(vars,eqns,ilst,eindx,mapIncRowEqn,mt))
      equation
        (varlst,changedVars) = BackendVariable.getVar(cr,vars);
        (vars,ilst) = increaseDifferentiation(varlst,changedVars,2,vars,ilst);
      then
        (DAE.CALL(Absyn.IDENT("der"),{e,DAE.ICONST(2)},DAE.callAttrBuiltinReal), (vars,eqns,ilst,eindx,mapIncRowEqn,mt));
    /* der(var,index), set differentiation counter = index+1 */
    case (e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr),DAE.ICONST(index)}),(vars,eqns,ilst,eindx,mapIncRowEqn,mt))
      equation
        (varlst,changedVars) = BackendVariable.getVar(cr,vars);
        (vars,ilst) = increaseDifferentiation(varlst,changedVars,index,vars,ilst);
      then
        (e, (vars,eqns,ilst,eindx,mapIncRowEqn,mt));
    else (inExp,inTpl);
  end match;
end changeDerVariablesToStatesFinder;

protected function algebraicState
"author Frenkel TUD 2013-01
  change all algebraic vars to states and add
  them to the list of changed vars and update
  variables"
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> inIndxLst;
  input BackendDAE.Variables inVars;
  input list<Integer> iChangedVars;
  output BackendDAE.Variables oVars;
  output list<Integer> oChangedVars;
algorithm
  (oVars,oChangedVars) := match(inVarLst,inIndxLst,inVars,iChangedVars)
    local
      BackendDAE.Var v;
      Integer index;
      list<BackendDAE.Var> vlst;
      list<Integer> ilst,changedVars;
      BackendDAE.Variables vars;
    case({},{},_,_) then (inVars,iChangedVars);
    case((BackendDAE.VAR(varKind = BackendDAE.STATE()))::vlst,_::ilst,_,_)
      equation
        (vars,changedVars) = algebraicState(vlst,ilst,inVars,iChangedVars);
      then
        (vars,changedVars);
    case(v::vlst,index::ilst,_,_)
      equation
        v = BackendVariable.setVarKind(v, BackendDAE.STATE(1,NONE()));
        vars = BackendVariable.addVar(v, inVars);
        (vars,changedVars) = algebraicState(vlst,ilst,vars,index::iChangedVars);
      then
        (vars,changedVars);
  end match;
end algebraicState;

protected function increaseDifferentiation "author: Frenkel TUD 2013-01
  increase the differentiation counter"
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> iVarIndxs;
  input Integer counter;
  input BackendDAE.Variables inVars;
  input list<Integer> iChangedVars;
  output BackendDAE.Variables oVars;
  output list<Integer> oChangedVars;
algorithm
  (oVars,oChangedVars) := match (inVarLst,iVarIndxs,counter,inVars,iChangedVars)
    local
      DAE.ComponentRef cr;
      Option<DAE.ComponentRef> dcr;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      Option<DAE.Exp> tplExp;
      list<DAE.Dimension> dim;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> attr;
      Option<BackendDAE.TearingSelect> ts;
      DAE.Exp hideResult;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var var;
      BackendDAE.Variables vars;
      Integer diffcounter;
      Boolean b;
      Integer i;
      list<Integer> ilst,changedVars;
      list<BackendDAE.Var> vlst;
      DAE.VarInnerOuter io;
    case ({},_,_,_,_) then (inVars,iChangedVars);
    case (BackendDAE.VAR(varName = cr,
              varKind = BackendDAE.STATE(diffcounter,dcr),
              varDirection = dir,
              varParallelism = prl,
              varType = tp,
              bindExp = bind,
              tplExp = tplExp,
              arryDim = dim,
              source = source,
              values = attr,
              tearingSelectOption = ts,
              hideResult = hideResult,
              comment = comment,
              connectorType = ct,
              innerOuter = io)::vlst,i::ilst,_,_,_)
    equation
      b = intGt(counter,diffcounter);
      diffcounter = if b then counter else diffcounter;
      var = BackendDAE.VAR(cr, BackendDAE.STATE(diffcounter,dcr), dir, prl, tp, bind, tplExp, dim, source, attr, ts, hideResult, comment, ct,io, false);
      vars = if b then BackendVariable.addVar(var, inVars) else inVars;
      changedVars = List.consOnTrue(b,i,iChangedVars);
      (vars,ilst) = increaseDifferentiation(vlst,ilst,counter,vars,changedVars);
    then
      (vars,ilst);
   else
     equation
       print("IndexReduction.setVarKind failt because of wrong input:\n");
       BackendDump.printVar(listHead(inVarLst));
     then
       fail();
  end match;
end increaseDifferentiation;

protected function debugdifferentiateEqns
  input tuple<BackendDAE.Equation,BackendDAE.Equation> inTpl;
protected
  BackendDAE.Equation a,b;
algorithm
  (a,b) := inTpl;
  print("High index problem, differentiated equation:\n" + BackendDump.equationString(a) + "\nto\n" + BackendDump.equationString(b) + "\n");
end debugdifferentiateEqns;

protected function getSetVars
"author: Frenkel TUD 2012-12"
  input Integer index;
  input Integer setsize;
  input Integer nCandidates;
  input Integer nCEqns;
  input Integer level;
  output DAE.ComponentRef crstates;
  output list<DAE.ComponentRef> crset;
  output list<BackendDAE.Var> oSetVars;
  output DAE.ComponentRef ocrA;
  output list<BackendDAE.Var> oAVars;
  output DAE.Type realtp;
  output DAE.ComponentRef ocrJ;
  output list<BackendDAE.Var> oJVars;
protected
  DAE.ComponentRef set;
  DAE.Type tp;
algorithm
//  set := ComponentReference.makeCrefIdent("$STATESET",DAE.T_COMPLEX_DEFAULT,{DAE.INDEX(DAE.ICONST(index))});
  set := ComponentReference.makeCrefIdent("$STATESET" + intString(index),DAE.T_COMPLEX_DEFAULT,{});
  tp := if intGt(setsize,1) then DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(setsize)}) else DAE.T_REAL_DEFAULT;
  crstates := ComponentReference.joinCrefs(set,ComponentReference.makeCrefIdent("x",tp,{}));
  oSetVars := BackendVariable.generateArrayVar(crstates,BackendDAE.STATE(1,NONE()),tp,NONE());
  oSetVars := List.map1(oSetVars,BackendVariable.setVarFixed,false);
  crset := List.map(oSetVars,BackendVariable.varCref);
  tp := if intGt(setsize,1) then DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(setsize),DAE.DIM_INTEGER(nCandidates)})
                            else DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(nCandidates)});
  realtp := if intGt(setsize,1) then DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(setsize),DAE.DIM_INTEGER(nCandidates)})
                                else DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nCandidates)});
  ocrA := ComponentReference.joinCrefs(set,ComponentReference.makeCrefIdent("A",tp,{}));
  oAVars := BackendVariable.generateArrayVar(ocrA,BackendDAE.VARIABLE(),tp,NONE());
  oAVars := List.map1(oAVars,BackendVariable.setVarFixed,true);
  // add start value A[i,j] = if i==j then 1 else 0 via initial equations
  oAVars := List.map1(oAVars,BackendVariable.setVarStartValue,DAE.ICONST(0));
  oAVars := setSetAStart(oAVars,1,1,nCandidates,{});
  tp := if intGt(nCEqns,1) then DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nCEqns)}) else DAE.T_REAL_DEFAULT;
  ocrJ := ComponentReference.joinCrefs(set,ComponentReference.makeCrefIdent("J",tp,{}));
  oJVars := BackendVariable.generateArrayVar(ocrJ,BackendDAE.VARIABLE(),tp,NONE());
  oJVars := List.map1(oJVars,BackendVariable.setVarFixed,false);
end getSetVars;


protected function setSetAStart
  input list<BackendDAE.Var> iVars;
  input Integer n;
  input Integer r;
  input Integer nCandidates;
  input list<BackendDAE.Var> iAcc;
  output list<BackendDAE.Var> oAcc;
algorithm
  oAcc := match(iVars,n,r,nCandidates,iAcc)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> rest;
      Integer n1,r1,start;
    case({},_,_,_,_) then listReverse(iAcc);
    case(v::rest,_,_,_,_)
      equation
        start = if intEq(n,r) then 1 else 0;
        v = BackendVariable.setVarStartValue(v,DAE.ICONST(start));
        n1 = if intEq(n,nCandidates) then 1 else (n+1);
        r1 = if intEq(n,nCandidates) then (r+1) else r;
      then
        setSetAStart(rest,n1,r1,nCandidates,v::iAcc);
  end match;
end setSetAStart;



// =============================================================================
// set the derivative information to the states
// use equations der(s) = v and set s:STATE(derivativeName=v)
// =============================================================================

public function findStateOrder "author Frenkel TUD 2013-01"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  // find der(s) = v
  systs := List.map(systs, findStateOrderWork);
  outDAE := BackendDAE.DAE(systs, shared);
end findStateOrder;

protected function findStateOrderWork "author Frenkel TUD 2013-01"
  input BackendDAE.EqSystem inSystem;
  output BackendDAE.EqSystem outSystem = inSystem;
algorithm
  // find der(s) = v
  outSystem.orderedVars := BackendEquation.traverseEquationArray( inSystem.orderedEqs, traverseFindStateOrder,
                                                                  inSystem.orderedVars );
end findStateOrderWork;

protected function traverseFindStateOrder
"author: Frenkel TUD 2013-01
  collect all states and there derivatives"
 input BackendDAE.Equation inEq;
 input BackendDAE.Variables inVars;
 output BackendDAE.Equation outEq;
 output BackendDAE.Variables outVars;
algorithm
  (outEq,outVars) := matchcontinue (inEq,inVars)
    local
      BackendDAE.Equation e;
      BackendDAE.Variables v;
      DAE.ComponentRef cr,dcr;
      list<BackendDAE.Var> vlst,dvlst;
    case (e,v)
      equation
        (cr,dcr,_,_,false) = BackendEquation.derivativeEquation(e);
        (vlst,_) = BackendVariable.getVar(cr,v);
        (dvlst,_) = BackendVariable.getVar(dcr,v);
        v = addStateOrderFinder(vlst,dvlst,v);
      then (e,v);
    else (inEq,inVars);
  end matchcontinue;
end traverseFindStateOrder;

protected function addStateOrderFinder
  input list<BackendDAE.Var> iVlst;
  input list<BackendDAE.Var> iDerVlst;
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables oVars;
algorithm
  oVars := match(iVlst,iDerVlst,inVars)
    local
      DAE.ComponentRef cr,dcr;
      BackendDAE.Var var,dvar;
      list<BackendDAE.Var> vlst,dvlst;
      BackendDAE.Variables vars;
      String msg;
    case ({},_,_) then inVars;
    case ((var as BackendDAE.VAR(varKind=BackendDAE.STATE(derName=NONE())))::vlst,
          BackendDAE.VAR(varName=dcr)::dvlst,_)
      equation
        var = BackendVariable.setStateDerivative(var,SOME(dcr));
        vars = BackendVariable.addVar(var,inVars);
      then
        addStateOrderFinder(vlst,dvlst,vars);
    case(var::_,dvar::_,_)
      equation
        msg = "IndexReduction.addStateOrderFinder failed for " + BackendDump.varString(var) + " with derivative " + BackendDump.varString(dvar) + "\n";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.addStateOrderFinder failed!"});
      then
        fail();
  end match;
end addStateOrderFinder;

protected function dumpStates
"author: Frenkel TUD"
  input tuple<DAE.ComponentRef,Integer> state;
  output String outStr;
algorithm
  outStr := intString(Util.tuple22(state)) + " " + ComponentReference.printComponentRefStr(Util.tuple21(state));
end dumpStates;

/******************************************
 DAEHandler stuff
 *****************************************/

protected function addStateOrder
"author: Frenkel TUD 2011-05
  add state and state derivative to the
  stateorder."
  input DAE.ComponentRef cr;
  input DAE.ComponentRef dcr;
  input BackendDAE.StateOrder inStateOrder;
  output BackendDAE.StateOrder outStateOrder;
algorithm
 outStateOrder :=
  matchcontinue (cr,dcr,inStateOrder)
    local
        HashTableCG.HashTable ht,ht1;
        HashTable3.HashTable dht,dht1;
        list<DAE.ComponentRef> crlst;
    case (_,_,BackendDAE.STATEORDER(ht,dht))
      equation
        ht1 = BaseHashTable.add((cr, dcr),ht);
        failure(_ = getDerStateOrder(dcr,inStateOrder));
        dht1 = BaseHashTable.add((dcr, {cr}),dht);
      then
       BackendDAE.STATEORDER(ht1,dht1);
    case (_,_,BackendDAE.STATEORDER(ht,dht))
      equation
        ht1 = BaseHashTable.add((cr, dcr),ht);
        crlst = getDerStateOrder(dcr,inStateOrder);
        dht1 = BaseHashTable.add((dcr, cr::crlst),dht);
      then
       BackendDAE.STATEORDER(ht1,dht1);
  end matchcontinue;
end addStateOrder;

protected function getStateOrder
"author: Frenkel TUD 2011-05
  returns the derivative of a state.
  Fails if there is none"
  input DAE.ComponentRef cr;
  input BackendDAE.StateOrder inStateOrder;
  output DAE.ComponentRef dcr;
protected
  HashTableCG.HashTable ht;
algorithm
  BackendDAE.STATEORDER(hashTable=ht) := inStateOrder;
  dcr := BaseHashTable.get(cr,ht);
end getStateOrder;

protected function getDerStateOrder
"author: Frenkel TUD 2011-05
  returns the states of a state derivative.
  Fails if there is none"
  input DAE.ComponentRef dcr;
  input BackendDAE.StateOrder inStateOrder;
  output list<DAE.ComponentRef> crlst;
protected
  HashTable3.HashTable dht;
algorithm
  BackendDAE.STATEORDER(invHashTable=dht) := inStateOrder;
  crlst := BaseHashTable.get(dcr,dht);
end getDerStateOrder;

protected function addOrgEqn
"author: Frenkel TUD 2011-05
  add an equation to the ConstrainEquations."
  input Integer e;
  input BackendDAE.Equation inEqn;
  input BackendDAE.ConstraintEquations inOrgEqns;
  output BackendDAE.ConstraintEquations outOrgEqns;
protected
  list<BackendDAE.Equation> eqs;
algorithm
  outOrgEqns := inOrgEqns;
  eqs := arrayGet(inOrgEqns,e);
  eqs := inEqn::eqs;
  arrayUpdate(outOrgEqns,e,eqs);
  /*
  outOrgEqns :=
  matchcontinue (e,inEqn, inOrgEqns)
    local
      list<BackendDAE.Equation> orgeqns;
      Integer e1;
      BackendDAE.ConstraintEquations rest,orgeqnslst;

    case ({},_,_) then {(e,{inEqn})};
    case ((e1,_)::_,_,_)
      equation
        true = intGt(e1,e);
      then
        (e,{inEqn})::inOrgEqns;
    case ((e1,orgeqns)::rest,_,_)
      equation
        true = intEq(e1,e);
      then
        (e1,inEqn::orgeqns)::rest;
    case ((e1,orgeqns)::rest,_,_)
      equation
        orgeqnslst = addOrgEqn(rest,e,inEqn);
      then
        (e1,orgeqns)::orgeqnslst;
  end matchcontinue;
  */
end addOrgEqn;

annotation(__OpenModelica_Interface="backend");
end IndexReduction;
