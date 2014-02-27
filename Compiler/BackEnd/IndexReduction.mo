/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package IndexReduction
" file:        IndexReduction.mo
  package:     IndexReduction
  description: IndexReduction contains functions that are needed to perform
               index reduction


  RCS: $Id: IndexReduction.mo 11707 2012-04-10 11:25:54Z Frenkel TUD $
"

public import BackendDAE;
public import DAE;

protected import Absyn;
protected import BackendDAEEXT;
protected import BackendDump;
protected import BackendEquation;
protected import BackendDAEOptimize;
protected import BackendDAETransform;
protected import BackendDAEUtil;
protected import BackendVariable;
protected import BackendVarTransform;
protected import BaseHashTable;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Differentiate;
protected import Env;
protected import Error;
protected import ErrorExt;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import GraphML;
protected import HashTable2;
protected import HashTable3;
protected import HashTableCG;
protected import HashTableCrIntToExp;
protected import Inline;
protected import List;
protected import Matching;
protected import SCode;
protected import System;
protected import Util;
protected import Values;
protected import ValuesUtil;


/*****************************************
 Pantelides index reduction method .
 see:
 C Pantelides, The Consistent Initialization of Differential-Algebraic Systems, SIAM J. Sci. and Stat. Comput. Volume 9, Issue 2, pp. 213–231 (March 1988)
 Soares, R. de P.; Secchi, A. R.: Direct Initialisation and Solution of High-Index DAESystems. in Proceedings of the European Symbosium on Computer Aided Process Engineering - 15, Barcelona, Spain,
 *****************************************/

public function pantelidesIndexReduction
"author: Frenkel TUD 2012-04
  Index Reduction algorithm to get a index 1 or 0 system."
  input list<list<Integer>> eqns;
  input Integer actualEqn;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  output list<Integer> changedEqns;
  output Integer continueEqn;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAssignments1;
  output array<Integer> outAssignments2;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
algorithm
  (changedEqns,continueEqn,osyst,oshared,outAssignments1,outAssignments2,outArg):=
  matchcontinue (eqns,actualEqn,isyst,ishared,inAssignments1,inAssignments2,inArg)
    local
      list<Integer> changedeqns,discEqns;
      list<list<Integer>> eqns_1,unassignedStates,unassignedEqns;
      Integer contiEqn,size,newsize;
      array<Integer> ass1,ass2,markarr;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      
    case (_::_,_,_,_,_,_,_)
      equation
        //  BackendDump.printEqSystem(isyst);
        //  BackendDump.dumpMatching(inAssignments1);
        //  BackendDump.dumpMatching(inAssignments2);
        //  syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(inAssignments1,inAssignments2,{}));
        //  dumpSystemGraphML(syst,ishared,NONE(),"ConstrainRevoluteJoint" +& intString(listLength(List.flatten(eqns))) +& ".graphml");
        // check by count vars of equations, if len(eqns) > len(vars) stop because of structural singular system
        ErrorExt.setCheckpoint("Pantelides");
        (eqns_1,unassignedStates,unassignedEqns,discEqns) = minimalStructurallySingularSystem(eqns,isyst,ishared,inAssignments1,inAssignments2,inArg);
        size = BackendDAEUtil.systemSize(isyst);
        ErrorExt.delCheckpoint("Pantelides");
        ErrorExt.setCheckpoint("Pantelides");
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index\n");
        markarr = arrayCreate(size,-1);
        (syst,shared,ass1,ass2,arg,_) =
         pantelidesIndexReduction1(unassignedStates,unassignedEqns,eqns,eqns_1,actualEqn,isyst,ishared,inAssignments1,inAssignments2,1,markarr,inArg,{});      
        ErrorExt.rollBack("Pantelides");
        ErrorExt.setCheckpoint("Pantelides");
        // get from eqns indexes the scalar indexes
        newsize = BackendDAEUtil.systemSize(syst);
        changedeqns = Debug.bcallret2(intGt(newsize,size),List.intRange2,size+1,newsize,{});
        (changedeqns,contiEqn) = getChangedEqnsAndLowest(newsize,ass2,changedeqns,size);
        ErrorExt.delCheckpoint("Pantelides");
      then
       (changedeqns,contiEqn,syst,shared,ass1,ass2,arg);
    case ({},_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReduction called with empty list of equations!"});
      then
        fail();
    case (_::_,_,_,_,_,_,_)
      equation
        ErrorExt.delCheckpoint("Pantelides");
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReduction failed!"});
      then
        fail();
  end matchcontinue;
end pantelidesIndexReduction;

protected function getChangedEqnsAndLowest
  input Integer index;
  input array<Integer> ass2;
  input list<Integer> iAcc;
  input Integer iLowest;
  output list<Integer> oAcc;
  output Integer oLowest;
algorithm
  (oAcc,oLowest) := match (index,ass2,iAcc,iLowest)
    local
      list<Integer> acc;
      Integer l;
    case (0,_,_,_) then (iAcc,iLowest);
    case (_,_,_,_)
      equation
        true = intGt(index,0);
        (acc,l) = getChangedEqnsAndLowest(index-1,ass2,List.consOnTrue(intLt(ass2[index],1),index,iAcc),index);
      then (acc,l);
  end match;
end getChangedEqnsAndLowest;

protected function pantelidesIndexReduction1
"author: Frenkel TUD 2012-04
  Index Reduction algorithm to get a index 1 or 0 system."
  input list<list<Integer>> unassignedStates;
  input list<list<Integer>> unassignedEqns;
  input list<list<Integer>> alleqns;
  input list<list<Integer>> iEqns;
  input Integer actualEqn;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
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
  matchcontinue (unassignedStates,unassignedEqns,alleqns,iEqns,actualEqn,isyst,ishared,inAssignments1,inAssignments2,mark,markarr,inArg,iNotDiffableMSS)
    local
      list<Integer> states,eqns,eqns_1,ueqns;
      list<list<Integer>> statelst,ueqnsrest,eqnsrest,eqnsrest_1;
      array<Integer>  ass1,ass2;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      list<tuple<list<Integer>,list<Integer>,list<Integer>>> notDiffableMSS;
    case (_,_,_,{},_,_,_,_,_,_,_,_,_)
      equation
        (syst,shared,ass1,ass2,arg) = handleundifferntiableMSSLst(iNotDiffableMSS,isyst,ishared,inAssignments1,inAssignments2,inArg);
      then
        (syst,shared,ass1,ass2,arg,{});
    case (states::statelst,ueqns::ueqnsrest,eqns::eqnsrest,eqns_1::eqnsrest_1,_,_,_,_,_,_,_,_,_)
      equation
        (syst,shared,ass1,ass2,arg,notDiffableMSS) =
         pantelidesIndexReductionMSS(states,ueqns,eqns,eqns_1,actualEqn,isyst,ishared,inAssignments1,inAssignments2,mark,markarr,inArg,iNotDiffableMSS);
        // next MSS
        (syst,shared,ass1,ass2,arg,notDiffableMSS) =
         pantelidesIndexReduction1(statelst,ueqnsrest,eqnsrest,eqnsrest_1,actualEqn,syst,shared,ass1,ass2,mark,markarr,arg,notDiffableMSS);
      then
       (syst,shared,ass1,ass2,arg,notDiffableMSS);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReduction1 failed! Use +d=bltdump to get more information."});
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
  input list<Integer> eqns;
  input Integer actualEqn;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
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
  matchcontinue (unassignedStates,unassignedEqns,alleqns,eqns,actualEqn,isyst,ishared,inAssignments1,inAssignments2,mark,markarr,inArg,iNotDiffableMSS)
    local
      list<Integer> eqns1;
      BackendDAE.StateOrder so,so1;
      BackendDAE.ConstraintEquations orgEqnsLst,orgEqnsLst1;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn,ass1,ass2;
      Integer noofeqns;
      BackendDAE.EquationArray eqnsarray;
      BackendDAE.Variables vars;
      list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> eqnstpl;
      list<tuple<list<Integer>,list<Integer>,list<Integer>>> notDiffableMSS;
      
    case (_,_,_,_::_,_,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqnsarray),_,_,_,_,_,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,noofeqns),_)
      equation
        // get from scalar eqns indexes the indexes in the equation array
        eqns1 = List.map1r(eqns,arrayGet,mapIncRowEqn);
        eqns1 = List.uniqueIntN(eqns1,arrayLength(mapIncRowEqn));
        //ueqns1 = List.map1r(unassignedEqns,arrayGet,mapIncRowEqn);
        //ueqns1 = List.uniqueIntN(ueqns1,arrayLength(mapIncRowEqn));
        // do not differentiate self generated equations $_DER.x = der(x)
        eqns1 = List.select1(eqns1,intLe,noofeqns);
        //ueqns1 = List.select1(ueqns1,intLe,noofeqns);
        Debug.fcall(Flags.BLT_DUMP, print, "marked equations: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (eqns1,intString," ","\n"));
        // eqnstr = Debug.bcallret2(Flags.isSet(Flags.BLT_DUMP), BackendDump.dumpMarkedEqns, isyst, ueqns1,"");
        // Debug.fcall(Flags.BLT_DUMP, print, eqnstr);
        // remove allready diffed equations
        //_ = List.fold1r(ueqns1,arrayUpdate,mark,markarr);
        //eqnstpl = differentiateSetEqns(ueqns1,{},vars,eqnsarray,inAssignments1,mapIncRowEqn,mark,markarr,ishared,{});
        (eqnstpl, shared) = differentiateEqnsLst(eqns1,vars,eqnsarray,ishared,{});
        (syst,shared,ass1,ass2,so1,orgEqnsLst1,mapEqnIncRow,mapIncRowEqn,notDiffableMSS) = differentiateEqns(eqnstpl,eqns1,unassignedStates,unassignedEqns,isyst, shared,inAssignments1,inAssignments2,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,iNotDiffableMSS);
      then
        (syst,shared,ass1,ass2,(so1,orgEqnsLst1,mapEqnIncRow,mapIncRowEqn,noofeqns),notDiffableMSS);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.pantelidesIndexReductionMSS failed! Use +d=bltdump to get more information."});
      then
        fail();
  end matchcontinue;
end pantelidesIndexReductionMSS;

protected function minimalStructurallySingularSystem
"author: Frenkel TUD - 2012-04,
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
  list<Integer> unassignedEqns,eqnslst,stateindxs;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  array<Integer> statemark;
  Integer size;
  Boolean b;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=SOME(m)) := syst;
  size := BackendVariable.varsSize(vars);
  statemark := arrayCreate(size,-1);
  // check over all mss
  unassignedEqns := List.flatten(inEqnsLst);
  stateindxs := List.fold2(unassignedEqns,statesInEquations,(m,statemark,0),inAssignments1,{});
  ((unassignedEqns,eqnslst,discEqns)) := List.fold2(unassignedEqns,unassignedContinuesEqns,vars,(inAssignments2,m),({},{},{}));
  b := intGe(listLength(stateindxs),listLength(unassignedEqns));
  singulareSystemError(b,stateindxs,unassignedEqns,eqnslst,syst,shared,inAssignments1,inAssignments2,inArg);
  // check each mss
  (outEqnsLst,outStateIndxs,outunassignedEqns,discEqns) := minimalStructurallySingularSystemMSS(inEqnsLst,syst,shared,inAssignments1,inAssignments2,inArg,statemark,1,m,vars,{},{},{},{});
end minimalStructurallySingularSystem;

protected function minimalStructurallySingularSystemMSS
"author: Frenkel TUD - 2012-11,
  helper for minimalStructurallySingularSystem"
  input list<list<Integer>> inEqnsLst;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
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
  (outEqnsLst,outStateIndxs,outUnassEqnsAcc,outDiscEqns) :=
    match(inEqnsLst,isyst,ishared,inAssignments1,inAssignments2,inArg,statemark,mark,m,vars,inEqnsLstAcc,inStateIndxsAcc,inUnassEqnsAcc,inDiscEqnsAcc)
    local
      list<Integer> ilst,unassignedEqns,eqnsLst,discEqns,stateIndxs;
      list<list<Integer>> rest;
      Boolean b;
    
    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_) then (inEqnsLstAcc,inStateIndxsAcc,inUnassEqnsAcc,inDiscEqnsAcc);
    
    case (ilst::rest,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // print("Eqns " +& stringDelimitList(List.map(ilst,intString),", ") +& "\n");
        ((unassignedEqns,eqnsLst,discEqns)) = List.fold2(ilst,unassignedContinuesEqns,vars,(inAssignments2,m),({},{},inDiscEqnsAcc));
        // print("unassignedEqns " +& stringDelimitList(List.map(unassignedEqns,intString),", ") +& "\n");
        stateIndxs = List.fold2(ilst,statesInEquations,(m,statemark,mark),inAssignments1,{});
        // print("stateIndxs " +& stringDelimitList(List.map(stateIndxs,intString),", ") +& "\n");
        b = intGe(listLength(stateIndxs),listLength(unassignedEqns));
        singulareSystemError(b,stateIndxs,unassignedEqns,eqnsLst,isyst,ishared,inAssignments1,inAssignments2,inArg);
        (outEqnsLst,outStateIndxs,outUnassEqnsAcc,outDiscEqns) =
          minimalStructurallySingularSystemMSS(rest,isyst,ishared,inAssignments1,inAssignments2,inArg,statemark,mark+1,m,vars,eqnsLst::inEqnsLstAcc,stateIndxs::inStateIndxsAcc,unassignedEqns::inUnassEqnsAcc,discEqns);
     then
       (outEqnsLst,outStateIndxs,outUnassEqnsAcc,outDiscEqns);
  
  end match;
end minimalStructurallySingularSystemMSS;

protected function singulareSystemError
"author: Frenkel TUD 2012-04
  Index Reduction algorithm to get a index 1 or 0 system."
  input Boolean b;
  input list<Integer> unassignedStates;
  input list<Integer> unassignedEqns;
  input list<Integer> eqns;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<Integer> inAssignments1;
  input array<Integer> inAssignments2;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
algorithm
  _:=
  match (b,unassignedStates,unassignedEqns,eqns,isyst,ishared,inAssignments1,inAssignments2,inArg)
    local
      list<BackendDAE.Var> varlst;
      list<Integer> eqns1;
      BackendDAE.EqSystem syst;
      array<Integer> mapIncRowEqn;
    
    // OK
    case (true,_,_,_::_,_,_,_,_,_) then ();
    
    // Failure
    case (_,_,_,{},_,_,_,_,(_,_,_,mapIncRowEqn,_))
      equation
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index failed! Found empty set of continues equations.\nmarked equations:\n");
        // get from scalar eqns indexes the indexes in the equation array
        eqns1 = List.map1r(eqns,arrayGet,mapIncRowEqn);
        eqns1 = List.uniqueIntN(eqns1,arrayLength(mapIncRowEqn));
        Debug.fcall(Flags.BLT_DUMP, print, BackendDump.dumpMarkedEqns(isyst, eqns1));
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(inAssignments1,inAssignments2,{}));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printBackendDAE, BackendDAE.DAE({syst},ishared));
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.pantelidesIndexReduction failed! Found empty set of continues equations. Use +d=bltdump to get more information."});
      then
        fail();
    
    case (false,_,_,_::_,_,_,_,_,(_,_,_,mapIncRowEqn,_))
      equation
        Debug.fcall(Flags.BLT_DUMP, print, "Reduce Index failed! System is structurally singulare and cannot handled because number of unassigned continues equations is larger than number of states.\nmarked equations:\n");
        // get from scalar eqns indexes the indexes in the equation array
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (eqns,intString," ","\n"));
        eqns1 = List.map1r(eqns,arrayGet,mapIncRowEqn);
        eqns1 = List.uniqueIntN(eqns1,arrayLength(mapIncRowEqn));
        Debug.fcall(Flags.BLT_DUMP, print, BackendDump.dumpMarkedEqns(isyst, eqns1));
        Debug.fcall(Flags.BLT_DUMP, print, "unassgined states:\n");
        varlst = List.map1r(unassignedStates,BackendVariable.getVarAt,BackendVariable.daeVars(isyst));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList,varlst);
        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(inAssignments1,inAssignments2,{}));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printBackendDAE, BackendDAE.DAE({syst},ishared));
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.pantelidesIndexReduction failed! System is structurally singulare and cannot handled because number of unassigned equations is larger than number of states. Use +d=bltdump to get more information."});
      then
        fail();
  
  end match;
end singulareSystemError;

protected function unassignedContinuesEqns
"author: Frenkel TUD - 2012-11,
  check if it is an discrete equation and extract the
  states of the equation.
  Helper for minimalStructurallySingularSystem."
  input Integer eindx;
  input BackendDAE.Variables vars;
  input tuple<array<Integer>,BackendDAE.IncidenceMatrix> inTpl;
  input tuple<list<Integer>,list<Integer>,list<Integer>> inFold;
  output tuple<list<Integer>,list<Integer>,list<Integer>> outFold;
algorithm
  outFold := matchcontinue(eindx,vars,inTpl,inFold)
    local
      BackendDAE.IncidenceMatrix m;
      array<Integer> ass2;
      Integer vindx;
      list<Integer> unassignedEqns,eqnsLst,varlst,discEqns;
      list<BackendDAE.Var> vlst;
      Boolean b,ba;
      list<Boolean> blst;
/*    case(_,_,(ass2,m),(unassignedEqns,eqnsLst))
      equation
        vindx = ass2[eindx];
        true = intGt(vindx,0);
        v = BackendVariable.getVarAt(vars, vindx);
        b = BackendVariable.isVarDiscrete(v);
        eqnsLst = List.consOnTrue(not b, eindx, eqnsLst);
      then
       ((unassignedEqns,eqnsLst));
*/    case(_,_,(ass2,m),(unassignedEqns,eqnsLst,discEqns))
      equation
        vindx = ass2[eindx];
        ba = intLt(vindx,1);
        varlst = m[eindx];
        varlst = List.map(varlst,intAbs);
        vlst = List.map1r(varlst,BackendVariable.getVarAt,vars);
        blst = List.map(vlst,BackendVariable.isVarDiscrete);
        // if there is a continues variable than b is false
        b = Util.boolAndList(blst);
        eqnsLst = List.consOnTrue(not b, eindx, eqnsLst);
        unassignedEqns = List.consOnTrue(ba and not b, eindx, unassignedEqns);
        discEqns = List.consOnTrue(b, eindx, discEqns);
      then
       ((unassignedEqns,eqnsLst,discEqns));
    case(_,_,(ass2,_),(unassignedEqns,eqnsLst,discEqns))
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
  _ := List.fold(vars, markTrue, (statemark,mark));
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

protected function isUnMarked
"author: Frenkel TUD 2012-05"
  input tuple<array<Integer>,Integer> ass;
  input Integer indx;
  output Boolean b;
protected
  array<Integer> arr;
  Integer mark;
algorithm
  (arr,mark) := ass;
  b := not intEq(arr[intAbs(indx)],mark);
end isUnMarked;

protected function markTrue
"author: Frenkel TUD 2012-05"
  input Integer indx;
  input tuple<array<Integer>,Integer> iMark;
  output tuple<array<Integer>,Integer> oMark;
protected
  array<Integer> arr;
  Integer mark;
algorithm
  (arr,mark) := iMark;
  _ := arrayUpdate(arr,intAbs(indx),mark);
  oMark := iMark;
end markTrue;

protected function differentiateEqns
"author: Frenkel TUD 2011-05
  differentiates the constraint equations for
  Pantelides index reduction method."
  input list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> inEqnsTpl;
  input list<Integer> inEqns;
  input list<Integer> unassignedStates;
  input list<Integer> unassignedEqns;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input array<Integer> inAss1;
  input array<Integer> inAss2;
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.ConstraintEquations inOrgEqnsLst;
  input array<list<Integer>> imapEqnIncRow;
  input array<Integer> imapIncRowEqn;
  input list<tuple<list<Integer>,list<Integer>,list<Integer>>> iNotDiffableMSS;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output array<Integer> outAss1;
  output array<Integer> outAss2;
  output BackendDAE.StateOrder outStateOrd;
  output BackendDAE.ConstraintEquations outOrgEqnsLst;
  output array<list<Integer>> omapEqnIncRow;
  output array<Integer> omapIncRowEqn;
  output list<tuple<list<Integer>,list<Integer>,list<Integer>>> oNotDiffableMSS;
algorithm
  (osyst,oshared,outAss1,outAss2,outStateOrd,outOrgEqnsLst,omapEqnIncRow,omapIncRowEqn,oNotDiffableMSS):=
  match (inEqnsTpl,inEqns,unassignedStates,unassignedEqns,isyst,ishared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,imapEqnIncRow,imapIncRowEqn,iNotDiffableMSS)
    local
      Integer eqnss,eqnss1;
      BackendDAE.EquationArray eqns_1,eqns;
      list<Integer> ilst,eqnslst,eqnslst1,ilst1;
      BackendDAE.Variables v,v1;
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
      BackendDAE.EqSystem syst;
      BackendDAE.Matching matching;
      array<Integer> ass1,ass2,mapIncRowEqn;
      array<list<Integer>> mapEqnIncRow;
      BackendDAE.StateSets stateSets;
      DAE.FunctionTree funcs;
    // all equations are differentiated
    case (_::_,_,_,_,BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching,stateSets),_,_,_,_,_,_,_,_)
      equation
        eqnss = BackendDAEUtil.equationArraySize(eqns);
        (v1,eqns_1,so,ilst,orgEqnsLst) = replaceDifferentiatedEqns(inEqnsTpl,v,eqns,inStateOrd,mt,imapIncRowEqn,{},inOrgEqnsLst);
        eqnss1 = BackendDAEUtil.equationArraySize(eqns_1);
        eqnslst = Debug.bcallret2(intGt(eqnss1,eqnss),List.intRange2,eqnss+1,eqnss1,{});
        // set equation assigned variable assignemts zero
        ilst1 = List.map1r(ilst,arrayGet,inAss1);
        ilst1 = List.select1(ilst1,intGt,0);
        ass2 = List.fold1r(ilst1,arrayUpdate,-1,inAss2);
        // set changed variables assignments to zero
        ass1 = List.fold1r(ilst,arrayUpdate,-1,inAss1);
        eqnslst1 = collectVarEqns(ilst,{},mt,arrayLength(mt),arrayLength(m));
        syst = BackendDAE.EQSYSTEM(v1,eqns_1,SOME(m),SOME(mt),matching,stateSets);
        eqnslst1 = List.map1r(eqnslst1,arrayGet,imapIncRowEqn);
        eqnslst1 =  List.uniqueIntN(listAppend(inEqns,eqnslst1),eqnss1);
        eqnslst1 = listAppend(eqnslst1,eqnslst);
        Debug.fcall(Flags.BLT_DUMP, print, "Update Incidence Matrix: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,(eqnslst1,intString," ","\n"));
        funcs = BackendDAEUtil.getFunctions(ishared);
        (syst,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.updateIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE() , SOME(funcs), eqnslst1, imapEqnIncRow, imapIncRowEqn);
      then
        (syst,ishared,ass1,ass2,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,iNotDiffableMSS);
    // not all equations are differentiated
    case ({},_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (isyst,ishared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,imapEqnIncRow,imapIncRowEqn,(inEqns,unassignedStates,unassignedEqns)::iNotDiffableMSS);
  end match;
end differentiateEqns;

protected function collectVarEqns
"author: Frenkel TUD 2011-05
  collect all equations of a list with var indexes"
  input list<Integer> inIntegerLst1;
  input list<Integer> inIntegerLst2;
  input BackendDAE.IncidenceMatrixT inMT;
  input Integer inArrayLength;
  input Integer inNEquations "size of equations array, maximal entry in inMT";
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst := matchcontinue (inIntegerLst1,inIntegerLst2,inMT,inArrayLength,inNEquations)
    local
      Integer i;
      list<Integer> rest,eqns,ilst,ilst1;
    case ({},_,_,_,_)
      then
        List.uniqueIntN(inIntegerLst2,inNEquations);
    case (i::rest,_,_,_,_)
      equation
        true = intLt(i,inArrayLength);
        eqns = List.map(inMT[i],intAbs);
        ilst = listAppend(eqns,inIntegerLst2);
        ilst1 = collectVarEqns(rest,ilst,inMT,inArrayLength,inNEquations);
      then
        ilst1;
    case (i::rest,_,_,_,_)
      equation
        ilst1 = collectVarEqns(rest,inIntegerLst2,inMT,inArrayLength,inNEquations);
      then
        ilst1;
    case (i::rest,_,_,_,_)
      equation
        print("collectVarEqns failed for eqn " +& intString(i) +& "\n");
      then fail();
  end matchcontinue;
end collectVarEqns;

protected function searchDerivativesEqn "author: Frenkel TUD 2012-11"
  input tuple<DAE.Exp,tuple<list<Integer>,BackendDAE.Variables>> itpl;
  output tuple<DAE.Exp,tuple<list<Integer>,BackendDAE.Variables>> outTpl;
protected
  DAE.Exp e;
  tuple<list<Integer>,BackendDAE.Variables> tpl;
algorithm
  (e,tpl) := itpl;
  outTpl := Expression.traverseExp(e,searchDerivativesExp,tpl);
end searchDerivativesEqn;

protected function searchDerivativesExp "author: Frenkel TUD 2012-11"
  input tuple<DAE.Exp,tuple<list<Integer>,BackendDAE.Variables>> tpl;
  output tuple<DAE.Exp,tuple<list<Integer>,BackendDAE.Variables>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      BackendDAE.Variables vars;
      list<Integer> ilst,i1lst;
      DAE.Exp e;
      DAE.ComponentRef cr;
    case((e as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr)}),(ilst,vars)))
      equation
        (_,i1lst) = BackendVariable.getVar(cr,vars);
        ilst = List.fold1(i1lst,List.removeOnTrue, intEq, ilst);
      then
        ((e,(ilst,vars)));
    case _ then tpl;
  end matchcontinue;
end searchDerivativesExp;

protected function differentiateSetEqns
"author: Frenkel TUD 2012-11
  differentiates the constraint equations for
  Pantelides index reduction method."
  input list<Integer> inEqns;
  input list<Integer> inNextEqns;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input array<Integer> ass1;
  input array<Integer> mapIncRowEqn;
  input Integer mark;
  input array<Integer> markarr;
  input BackendDAE.Shared ishared;
  input list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> inEqnTpl;
  output list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> outEqnTpl;
  output BackendDAE.Shared oshared;
algorithm
  (outEqnTpl, oshared) := matchcontinue (inEqns,inNextEqns,vars,eqns,ass1,mapIncRowEqn,mark,markarr,ishared,inEqnTpl)
    local
      Integer e_1,e;
      BackendDAE.Equation eqn,eqn_1;
      list<Integer> es,elst;
      list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> eqntpl;
      BackendDAE.Shared shared;
    case ({},{},_,_,_,_,_,_,_,_) then (inEqnTpl, ishared);
    case ({},_,_,_,_,_,_,_,_,_)
      equation
      Debug.fcall(Flags.BLT_DUMP, print, "marked equations: ");
      Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (inNextEqns,intString," ","\n"));
      (eqntpl, shared) = differentiateSetEqns(inNextEqns,{},vars,eqns,ass1,mapIncRowEqn,mark,markarr,ishared,inEqnTpl);
      then
        (eqntpl, shared);  
    case (e::es,_,_,_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendEquation.equationNth0(eqns, e_1);
        true = BackendEquation.isDifferentiated(eqn);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrEqnStr,("Skipp allready differentiated equation\n",eqn,"\n"));
        (eqntpl, shared) = differentiateSetEqns(es,inNextEqns,vars,eqns,ass1,mapIncRowEqn,mark,markarr,ishared,(e,NONE(),eqn)::inEqnTpl);
      then
        (eqntpl, shared);
    case (e::es,_,_,_,_,_,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendEquation.equationNth0(eqns, e_1);
        //Debug.fcall(Flags.BLT_DUMP, print, "differentiat equation " +& intString(e) +& " " +& BackendDump.equationString(eqn) +& "\n");
        (eqn_1, shared) = Differentiate.differentiateEquationTime(eqn, vars, ishared);
        //Debug.fcall(Flags.BLT_DUMP, print, "differentiated equation " +& intString(e) +& " " +& BackendDump.equationString(eqn_1) +& "\n");
        eqn = BackendEquation.markDifferentiated(eqn);
        // get needed der(variables) from equation
       (_,(_,_,elst)) = BackendEquation.traverseBackendDAEExpsEqn(eqn_1, getDerVars, (vars,ass1,{}));
       elst = List.map1r(elst,arrayGet,mapIncRowEqn);
       elst = List.fold2(elst, addUnMarked, mark, markarr, inNextEqns);
       (eqntpl, shared) = differentiateSetEqns(es,inNextEqns,vars,eqns,ass1,mapIncRowEqn,mark,markarr,shared,(e,SOME(eqn_1),eqn)::inEqnTpl);
      then
        (eqntpl, shared);
    // failcase return empty list
    case (_,_,_,_,_,_,_,_,_,_) then ({}, ishared);
  end matchcontinue;
end differentiateSetEqns;

protected function addUnMarked
  input Integer e;
  input Integer mark;
  input array<Integer> markarr;
  input list<Integer> iAcc;
  output list<Integer> oAcc;
protected
  Boolean b;
algorithm
  b := intEq(markarr[e],mark);
  _ := arrayUpdate(markarr,e,mark);
  oAcc := List.consOnTrue(not b, e, iAcc);
end  addUnMarked;

protected function getDerVars
"author Frenkel TUD 2013-01
  collect all equations of assigned der(var)"
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,array<Integer>,list<Integer>>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,array<Integer>,list<Integer>>> outTpl;
protected
  DAE.Exp exp;
  tuple<BackendDAE.Variables,array<Integer>,list<Integer>> tpl;
algorithm
  (exp,tpl) := inTpl;
  outTpl := Expression.traverseExp(exp,getDerVarsExp,tpl);
end getDerVars;

protected function getDerVarsExp
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,array<Integer>,list<Integer>>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,array<Integer>,list<Integer>>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
      tuple<BackendDAE.Variables,array<Integer>,list<Integer>> tpl;
      BackendDAE.Variables vars;
      array<Integer> ass1;
      list<Integer> ilst,vlst,elst;

    // special case for time, it is never part of the equation system
    case ((e as DAE.CREF(componentRef = DAE.CREF_IDENT(ident="time")),tpl))
      then ((e, tpl));

    // case for functionpointers
    case ((e as DAE.CREF(ty=DAE.T_FUNCTION_REFERENCE_FUNC(builtin=_)),tpl))
      then
        ((e, tpl));

    // add it
    case ((e as DAE.CREF(componentRef = cr),(vars,ass1,ilst)))
      equation
         (_,vlst) = BackendVariable.getVar(cr, vars);
         vlst = List.select1r(vlst,Matching.isAssigned,ass1);
         elst = List.map1r(vlst,arrayGet,ass1);
         ilst = listAppend(elst,ilst);
      then
        ((e, (vars,ass1,ilst)));

    case _ then inTpl;
  end matchcontinue;
end getDerVarsExp;

protected function differentiateEqnsLst
"author: Frenkel TUD 2012-11
  differentiates the constraint equations for
  Pantelides index reduction method."
  input list<Integer> inEqns;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.Shared ishared;
  input list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> inEqnTpl;
  output list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> outEqnTpl;
  output BackendDAE.Shared oshared;
algorithm
  (outEqnTpl, oshared) := matchcontinue (inEqns,vars,eqns,ishared,inEqnTpl)
    local
      Integer e_1,e;
      BackendDAE.Equation eqn,eqn_1;
      list<Integer> es;
      BackendDAE.Shared shared;
      list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> eqntpl;
    case ({},_,_,_,_) then (inEqnTpl, ishared);
    case (e::es,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendEquation.equationNth0(eqns, e_1);
        true = BackendEquation.isDifferentiated(eqn);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrEqnStr,("Skip already differentiated equation\n",eqn,"\n"));
        (eqntpl, shared) = differentiateEqnsLst(es,vars,eqns,ishared,(e,NONE(),eqn)::inEqnTpl);
      then
        (eqntpl, shared);
    case (e::es,_,_,_,_)
      equation
        e_1 = e - 1;
        eqn = BackendEquation.equationNth0(eqns, e_1);
        // Debug.fcall(Flags.BLT_DUMP, print, "differentiate equation " +& intString(e) +& " " +& BackendDump.equationString(eqn) +& "\n");
        (eqn_1, shared) = Differentiate.differentiateEquationTime(eqn, vars, ishared);
        // Debug.fcall(Flags.BLT_DUMP, print, "differentiated equation " +& intString(e) +& " " +& BackendDump.equationString(eqn_1) +& "\n");
        eqn = BackendEquation.markDifferentiated(eqn);
        (eqntpl, shared) = differentiateEqnsLst(es,vars,eqns,shared,(e,SOME(eqn_1),eqn)::inEqnTpl);
      then
        (eqntpl, shared);
    case (_,_,_,_,_) then ({}, ishared);
  end matchcontinue;
end differentiateEqnsLst;

protected function replaceDifferentiatedEqns
"author: Frenkel TUD 2012-11
  replace the original equations with the derived"
  input list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> inEqnTplLst;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.IncidenceMatrix mt;
  input array<Integer> imapIncRowEqn;
  input list<Integer> inChangedVars;
  input BackendDAE.ConstraintEquations inOrgEqnsLst;
  output BackendDAE.Variables outVars;
  output BackendDAE.EquationArray outEqns;
  output BackendDAE.StateOrder outStateOrd;
  output list<Integer> outChangedVars;
  output BackendDAE.ConstraintEquations outOrgEqnsLst;
algorithm
  (outVars,outEqns,outStateOrd,outChangedVars,outOrgEqnsLst):=
  matchcontinue (inEqnTplLst,vars,eqns,inStateOrd,mt,imapIncRowEqn,inChangedVars,inOrgEqnsLst)
    local
      list<tuple<Integer,Option<BackendDAE.Equation>,BackendDAE.Equation>> rest;
      Integer e_1,e;
      list<Integer> changedVars;
      BackendDAE.Equation eqn,eqn_1;
      BackendDAE.EquationArray eqns1;
      BackendDAE.Variables vars1;
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst;
    case ({},_,_,_,_,_,_,_) then (vars,eqns,inStateOrd,inChangedVars,inOrgEqnsLst);
    case ((e,SOME(eqn_1),eqn)::rest,_,_,_,_,_,_,_)
      equation
        (eqn_1,_) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn_1, replaceStateOrderExp,vars);
        (eqn_1,(vars1,eqns1,so,changedVars,_,_,_)) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn_1,changeDerVariablestoStates,(vars,eqns,inStateOrd,inChangedVars,e,imapIncRowEqn,mt));
        Debug.fcall(Flags.BLT_DUMP, debugdifferentiateEqns,(eqn,eqn_1));
        e_1 = e - 1;
        eqns1 = BackendEquation.equationSetnth(eqns1,e_1,eqn_1);
        orgEqnsLst = addOrgEqn(inOrgEqnsLst,e,eqn);
        (outVars,outEqns,outStateOrd,outChangedVars,outOrgEqnsLst) =
           replaceDifferentiatedEqns(rest,vars1,eqns1,inStateOrd,mt,imapIncRowEqn,changedVars,orgEqnsLst);
      then
        (outVars,outEqns,outStateOrd,outChangedVars,outOrgEqnsLst);
    case ((e,NONE(),eqn)::rest,_,_,_,_,_,_,_)
      equation
        //orgEqnsLst = BackendDAETransform.addOrgEqn(inOrgEqnsLst,e,eqn);
        orgEqnsLst = inOrgEqnsLst;
        (outVars,outEqns,outStateOrd,outChangedVars,outOrgEqnsLst) =
           replaceDifferentiatedEqns(rest,vars,eqns,inStateOrd,mt,imapIncRowEqn,inChangedVars,orgEqnsLst);
      then
        (outVars,outEqns,outStateOrd,outChangedVars,outOrgEqnsLst);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"IndexReduction.replaceDifferentiatedEqns failed!"});
      then
        fail();
  end matchcontinue;
end replaceDifferentiatedEqns;

protected function replaceStateOrderExp
"author: Frenkel TUD 2011-05"
  input tuple<DAE.Exp,BackendDAE.Variables> inTpl;
  output tuple<DAE.Exp,BackendDAE.Variables> outTpl;
protected
  DAE.Exp e;
  BackendDAE.Variables vars;
algorithm
  (e,vars) := inTpl;
  outTpl := Expression.traverseExpTopDown(e,replaceStateOrderExpFinder,vars);
end replaceStateOrderExp;

protected function replaceStateOrderExpFinder
"author: Frenkel TUD 2011-05 "
  input tuple<DAE.Exp,BackendDAE.Variables> inExp;
  output tuple<DAE.Exp, Boolean, BackendDAE.Variables> outExp;
algorithm
  (outExp) := matchcontinue (inExp)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef dcr,cr;
      DAE.CallAttributes attr;
      Integer index;
     case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      equation
        ({BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(dcr)))},_) = BackendVariable.getVar(cr,vars);
        e = Expression.crefExp(dcr);
      then
        ((e,false,vars));
     case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {e as DAE.CREF(componentRef = cr),DAE.ICONST(index)},attr=attr),vars))
      equation
        true = intEq(index,2);
        ({BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(dcr)))},_) = BackendVariable.getVar(cr,vars);
        e = Expression.crefExp(dcr);
      then
        ((DAE.CALL(Absyn.IDENT("der"),{e},attr),false,vars));
     case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})},attr=attr),vars))
      equation
        ({BackendDAE.VAR(varKind=BackendDAE.STATE(derName=SOME(dcr)))},_) = BackendVariable.getVar(cr,vars);
        e = Expression.crefExp(dcr);
      then
        ((DAE.CALL(Absyn.IDENT("der"),{e},attr),false,vars));
     case ((e,vars)) then ((e,true,vars));
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
  oAcc := matchcontinue(state,mt,iAcc)
    case(_,_,_)
      equation
        List.map1AllValue(mt[state],intLt,true,0);
      then
        state::iAcc;
    else
      then
        iAcc;
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
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
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
  match (iNotDiffableMSS,isyst,ishared,inAss1,inAss2,iArg)
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
      then (isyst,ishared,inAss1,inAss2,iArg);
    case ((eqns,unassignedStates,unassignedEqns)::notDiffableMSS,BackendDAE.EQSYSTEM(orderedVars=v,mT=SOME(mt)),_,_,_,(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,noofeqns))
      equation
        Debug.fcall(Flags.BLT_DUMP, print, "not differentiable minimal singular subset:\n");
        Debug.fcall(Flags.BLT_DUMP, print, "unassignedEqns:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (unassignedEqns, intString, ", ", "\n"));
        Debug.fcall(Flags.BLT_DUMP, print, "unassignedStates:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst, (unassignedStates,intString, ", ", "\n"));
        ilst = List.fold1(unassignedStates, statesWithUnusedDerivative, mt, {});
        ilst = List.select1(ilst, isStateonIndex, v);
        // check also initial equations (this could be done alse once before
        ((ilst,_)) = BackendDAEUtil.traverseBackendDAEExpsEqns(BackendEquation.daeInitialEqns(ishared),searchDerivativesEqn,(ilst,v));
        Debug.fcall(Flags.BLT_DUMP,print,"states without used derivative:\n");
        Debug.fcall(Flags.BLT_DUMP,BackendDump.debuglst,(ilst,intString,", ","\n"));
        (syst,shared,ass1,ass2,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn) =
          handleundifferntiableMSS(intLe(listLength(ilst),listLength(unassignedEqns)),ilst,eqns,unassignedStates,unassignedEqns,isyst,ishared,inAss1,inAss2,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn);
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
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
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
  matchcontinue (b,statesWithUnusedDer,inEqns,unassignedStates,unassignedEqns,isyst,ishared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,imapEqnIncRow,imapIncRowEqn)
    local
      Integer i;
      BackendDAE.EquationArray eqns;
      list<Integer> ilst,eqnslst,eqnslst1;
      BackendDAE.Variables v,v1;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
      BackendDAE.EqSystem syst;
      BackendDAE.Matching matching;
      array<Integer> ass1,ass2,mapIncRowEqn;
      array<list<Integer>> mapEqnIncRow;
      list<BackendDAE.Var> varlst;
      BackendDAE.Var var;
      BackendDAE.StateSets stateSets;
      DAE.FunctionTree funcs;
    // 1th try to replace final parameter
    case (_,_,_,_,_,BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching,stateSets),_,_,_,_,_,_,_)
      equation
        ((eqns,eqnslst as _::_,_)) = List.fold1(inEqns,replaceFinalVars,BackendVariable.daeKnVars(ishared),(eqns,{},BackendVarTransform.emptyReplacements()));
        // unassign changed equations and assigned vars
        eqnslst1 = List.flatten(List.map1r(eqnslst,arrayGet,imapEqnIncRow));
        ilst = List.map1r(eqnslst1,arrayGet,inAss2);
        ilst = List.select1(ilst,intGt,0);
        ass2 = List.fold1r(eqnslst1,arrayUpdate,-1,inAss2);
        ass1 = List.fold1r(ilst,arrayUpdate,-1,inAss1);
        // update IncidenceMatrix
        Debug.fcall(Flags.BLT_DUMP, print, "Replaced final Parameter in Eqns\n");
        syst = BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching,stateSets);
        Debug.fcall(Flags.BLT_DUMP, print, "Update Incidence Matrix: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,(eqnslst,intString," ","\n"));
        funcs = BackendDAEUtil.getFunctions(ishared);
        (syst,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.updateIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs), eqnslst, imapEqnIncRow, imapIncRowEqn);
      then
        (syst,ishared,ass1,ass2,inStateOrd,inOrgEqnsLst,mapEqnIncRow,mapIncRowEqn);

    // if size of unmatched eqns is equal to size of states without used derivative change all to algebraic
    case (true,_::_,_,_,_,BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching,stateSets),_,_,_,_,_,_,_)
      equation
        // change varKind
        varlst = List.map1r(statesWithUnusedDer,BackendVariable.getVarAt,v);
        Debug.fcall(Flags.BLT_DUMP, print, "Change varKind to algebraic for\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList, varlst);
        varlst = BackendVariable.setVarsKind(varlst,BackendDAE.VARIABLE());
        v1 = BackendVariable.addVars(varlst,v);
        // update IncidenceMatrix
        eqnslst1 = collectVarEqns(statesWithUnusedDer,{},mt,arrayLength(mt),arrayLength(m));
        eqnslst1 = List.map1r(eqnslst1,arrayGet,imapIncRowEqn);
        syst = BackendDAE.EQSYSTEM(v1,eqns,SOME(m),SOME(mt),matching,stateSets);
        Debug.fcall(Flags.BLT_DUMP, print, "Update Incidence Matrix: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,(eqnslst1,intString," ","\n"));
        funcs = BackendDAEUtil.getFunctions(ishared);
        (syst,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.updateIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs), eqnslst1, imapEqnIncRow, imapIncRowEqn);
      then
        (syst,ishared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,mapEqnIncRow,mapIncRowEqn);

/* Debugging case
    case (false,_,_,_,_,BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching,stateSets),_,_,_,_,_,_,_)
      equation
        varlst = BackendEquation.equationsLstVars(notDiffedEquations,v);
        varlst = List.select(varlst,BackendVariable.isStateVar);
        Debug.fcall(Flags.BLT_DUMP, print, "state vars of undiffed Eqns\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList, varlst);

        syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(inAss1,inAss2,{}));
        dumpSystemGraphML(syst,ishared,NONE(),"test.graphml");
      then
        fail();
*/

    // if size of unmatched eqns is not equal to size of states without used derivative change first to algebraic
    // until I have a better sulution
    case (false,i::ilst,_,_,_,BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching,stateSets),_,_,_,_,_,_,_)
      equation
        // change varKind
        var = BackendVariable.getVarAt(v,i);
        varlst = {var};
        Debug.fcall(Flags.BLT_DUMP, print, "Change varKind to algebraic for\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList, varlst);
        varlst = BackendVariable.setVarsKind(varlst,BackendDAE.VARIABLE());
        v1 = BackendVariable.addVars(varlst,v);
        varlst = List.map1r(ilst,BackendVariable.getVarAt,v);
        Debug.fcall(Flags.BLT_DUMP, print, "Other Candidates are\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList, varlst);
        // update IncidenceMatrix
        eqnslst1 = collectVarEqns({i},{},mt,arrayLength(mt),arrayLength(m));
        eqnslst1 = List.map1r(eqnslst1,arrayGet,imapIncRowEqn);
        syst = BackendDAE.EQSYSTEM(v1,eqns,SOME(m),SOME(mt),matching,stateSets);
        Debug.fcall(Flags.BLT_DUMP, print, "Update Incidence Matrix: ");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,(eqnslst1,intString," ","\n"));
        funcs = BackendDAEUtil.getFunctions(ishared);
        (syst,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.updateIncidenceMatrixScalar(syst, BackendDAE.SOLVABLE(), SOME(funcs), eqnslst1, imapEqnIncRow, imapIncRowEqn);
      then
        (syst,ishared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,mapEqnIncRow,mapIncRowEqn);

    // if no state with unused derivative is in the set check global
    case (_,{},_,_,_,BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching,stateSets),_,_,_,_,_,_,_)
      equation
        ilst = Matching.getUnassigned(BackendVariable.varsSize(v), inAss1, {});
        ilst = List.fold1(ilst, statesWithUnusedDerivative, mt, {});
        varlst = List.map1r(ilst,BackendVariable.getVarAt,v);
        // check also initial equations (this could be done alse once before
        ((ilst,_)) = BackendDAEUtil.traverseBackendDAEExpsEqns(BackendEquation.daeInitialEqns(ishared),searchDerivativesEqn,(ilst,v));
        // check if there are states with unused derivative
        _::_ = ilst;
        Debug.fcall(Flags.BLT_DUMP, print, "All unassignedStates without Derivative: " +& stringDelimitList(List.map(ilst,intString),", ")  +& "\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList, varlst);
        (syst,oshared,outAss1,outAss2,outStateOrd,outOrgEqnsLst,omapEqnIncRow,omapIncRowEqn) = handleundifferntiableMSS(intLe(listLength(ilst),listLength(unassignedEqns)),ilst,inEqns,unassignedStates,unassignedEqns,isyst,ishared,inAss1,inAss2,inStateOrd,inOrgEqnsLst,imapEqnIncRow,imapIncRowEqn);
      then
        (syst,oshared,outAss1,outAss2,outStateOrd,outOrgEqnsLst,omapEqnIncRow,omapIncRowEqn);

    case (_,_,_,_,_,BackendDAE.EQSYSTEM(v,eqns,SOME(m),SOME(mt),matching,stateSets),_,_,_,_,_,_,_)
      equation
        varlst = List.map1r(unassignedStates,BackendVariable.getVarAt,v);
        Debug.fcall(Flags.BLT_DUMP, print, "unassignedStates\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList, varlst);

        //  syst = BackendDAEUtil.setEqSystemMatching(isyst,BackendDAE.MATCHING(inAss1,inAss2,{}));
        //  dumpSystemGraphML(syst,ishared,NONE(),"IndexReductionFailed.graphml");
      then
        fail();
  end matchcontinue;
end handleundifferntiableMSS;

protected function replaceFinalVars
  input Integer e;
  input BackendDAE.Variables vars;
  input tuple<BackendDAE.EquationArray,list<Integer>,BackendVarTransform.VariableReplacements> inTpl;
  output tuple<BackendDAE.EquationArray,list<Integer>,BackendVarTransform.VariableReplacements> outTpl;
protected
  BackendDAE.EquationArray eqns;
  list<Integer> changedEqns;
  BackendDAE.Equation eqn;
  Integer e1;
  Boolean b;
  BackendVarTransform.VariableReplacements repl;
algorithm
  (eqns,changedEqns,repl) := inTpl;
  // get the equation
  e1 := e-1;
  eqn := BackendEquation.equationNth0(eqns, e1);
  // reaplace final vars
  (eqn,(_,b,repl)) := BackendEquation.traverseBackendDAEExpsEqn(eqn,replaceFinalVarsEqn,(vars,false,repl));
  // if replaced set eqn
  eqns := Debug.bcallret3(b,BackendEquation.equationSetnth,eqns,e1,eqn,eqns);
  changedEqns := List.consOnTrue(b,e,changedEqns);
  outTpl := (eqns,changedEqns,repl);
end replaceFinalVars;

protected function replaceFinalVarsEqn
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean,BackendVarTransform.VariableReplacements>> inTpl;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean,BackendVarTransform.VariableReplacements>> outTpl;
protected
  DAE.Exp e;
  tuple<BackendDAE.Variables,Boolean,BackendVarTransform.VariableReplacements> tpl;
  BackendDAE.Variables vars;
  Boolean b;
  BackendVarTransform.VariableReplacements repl;
algorithm
  (e,tpl) := inTpl;
  ((e,(vars,b,repl))) := Expression.traverseExp(e,replaceFinalVarsExp,tpl);
  (e,_) := ExpressionSimplify.condsimplify(b,e);
  outTpl := (e,(vars,b,repl));
end replaceFinalVarsEqn;

protected function replaceFinalVarsExp "
Author: Frenkel TUD 2012-11
replace final parameter."
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean,BackendVarTransform.VariableReplacements>> inExp;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,Boolean,BackendVarTransform.VariableReplacements>> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      list<BackendDAE.Var> vlst;
      DAE.Exp e;
      BackendVarTransform.VariableReplacements repl;

    case((e as DAE.CREF(componentRef=cr), (vars,_,repl)))
      equation
        (vlst as _::_,_) = BackendVariable.getVar(cr,vars);
        ((repl,true)) = List.fold(vlst,replaceFinalVarsGetExp,(repl,false));
        (e,true) = BackendVarTransform.replaceExp(e,repl,NONE());
      then
        ((e, (vars,true,repl) ));
    case _ then inExp;
  end matchcontinue;
end replaceFinalVarsExp;

protected function replaceFinalVarsGetExp
"author: Frenkel TUD 2012-11"
 input BackendDAE.Var inVar;
 input tuple<BackendVarTransform.VariableReplacements,Boolean> iTpl;
 output tuple<BackendVarTransform.VariableReplacements,Boolean> oTpl;
algorithm
  oTpl:=
  matchcontinue (inVar,iTpl)
    local
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cr;
      Option< .DAE.VariableAttributes> values;
      DAE.Exp exp;
      Values.Value bindValue;
    case (BackendDAE.VAR(varName=cr,bindExp=SOME(exp)),(repl,_))
      equation
        true = BackendVariable.isFinalVar(inVar);
        repl = BackendVarTransform.addReplacement(repl,cr,exp,NONE());
    then
      ((repl,true));
    case (BackendDAE.VAR(varName=cr,bindExp=NONE(),bindValue=SOME(bindValue)),(repl,_))
      equation
        true = BackendVariable.isFinalVar(inVar);
        exp = ValuesUtil.valueExp(bindValue);
        repl = BackendVarTransform.addReplacement(repl,cr,exp,NONE());
    then
      ((repl,true));
    case (BackendDAE.VAR(varName=cr,bindExp=NONE(),values=values),(repl,_))
      equation
        true = BackendVariable.isFinalVar(inVar);
        exp = DAEUtil.getStartAttrFail(values);
        repl = BackendVarTransform.addReplacement(repl,cr,exp,NONE());
    then
      ((repl,true));
    else then iTpl;
  end matchcontinue;
end replaceFinalVarsGetExp;

protected function replaceAliasState
"author: Frenkel TUD 2012-06"
  input list<Integer> inEqsLst;
  input DAE.Exp inCrExp;
  input DAE.Exp indCrExp;
  input DAE.ComponentRef inACr;
  input BackendDAE.EquationArray inEqns;
  output BackendDAE.EquationArray outEqns;
algorithm
  outEqns:=
  match (inEqsLst,inCrExp,indCrExp,inACr,inEqns)
    local
      BackendDAE.EquationArray eqns;
      BackendDAE.Equation eqn,eqn1;
      Integer pos,pos_1;
      list<Integer> rest;
    case (pos::rest,_,_,_,_)
      equation
        // replace in eqn
        pos_1 = pos-1;
        eqn = BackendEquation.equationNth0(inEqns,pos_1);
        (eqn1,_) = BackendDAETransform.traverseBackendDAEExpsEqn(eqn, replaceAliasStateExp,(inACr,inCrExp,indCrExp));
        eqns =  BackendEquation.equationSetnth(inEqns,pos_1,eqn1);
        //  print("Replace in Eqn:\n" +& BackendDump.equationString(eqn) +& "\nto\n" +& BackendDump.equationString(eqn1) +& "\n");
      then
        replaceAliasState(rest,inCrExp,indCrExp,inACr,eqns);
    case ({},_,_,_,_) then inEqns;
  end match;
end replaceAliasState;

protected function replaceAliasStateExp
"author: Frenkel TUD 2012-06"
  input tuple<DAE.Exp,tuple<DAE.ComponentRef,DAE.Exp,DAE.Exp>> inTpl;
  output tuple<DAE.Exp,tuple<DAE.ComponentRef,DAE.Exp,DAE.Exp>> outTpl;
protected
  DAE.Exp e;
  tuple<DAE.ComponentRef,DAE.Exp,DAE.Exp> tpl;
algorithm
  (e,tpl) := inTpl;
  outTpl := Expression.traverseExpTopDown(e,replaceAliasStateExp1,tpl);
end replaceAliasStateExp;

protected function replaceAliasStateExp1
"author: Frenkel TUD 2012-06 "
  input tuple<DAE.Exp,tuple<DAE.ComponentRef,DAE.Exp,DAE.Exp>> inExp;
  output tuple<DAE.Exp,Boolean,tuple<DAE.ComponentRef,DAE.Exp,DAE.Exp>> outExp;
algorithm
  (outExp) := matchcontinue (inExp)
    local
      DAE.Exp e,e1,de1;
      DAE.ComponentRef cr,acr;
      tuple<DAE.ComponentRef,DAE.Exp,DAE.Exp> tpl;
     case ((DAE.CREF(componentRef = cr),(acr,e1,de1)))
      equation
        true = ComponentReference.crefEqualNoStringCompare(acr, cr);
      then
        ((e1, false, (acr,e1,de1)));
     case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(acr,e1,de1)))
      equation
        true = ComponentReference.crefEqualNoStringCompare(acr, cr);
      then
        ((de1, false, (acr,e1,de1)));
     case ((e,tpl)) then ((e,true,tpl));
  end matchcontinue;
end replaceAliasStateExp1;

public function getStructurallySingularSystemHandlerArg
"author: Frenkel TUD 2012-04
  return initial the StructurallySingularSystemHandlerArg."
  input BackendDAE.EqSystem isyst "updates the state differentation indexes";
  input BackendDAE.Shared ishared;
  input array<list<Integer>> mapEqnIncRow;
  input array<Integer> mapIncRowEqn;
  output BackendDAE.StructurallySingularSystemHandlerArg outArg;
protected
  HashTableCG.HashTable ht;
  HashTable3.HashTable dht;
  BackendDAE.StateOrder so;
  BackendDAE.EquationArray eqns;
algorithm
  ht := HashTableCG.emptyHashTable();
  dht := HashTable3.emptyHashTable();
  so := BackendDAE.STATEORDER(ht,dht);
  eqns := BackendEquation.daeEqns(isyst);
  Debug.fcall(Flags.BLT_DUMP, dumpStateOrder, so);
  outArg := (so,{},mapEqnIncRow,mapIncRowEqn,BackendDAEUtil.equationArraySize(eqns));
end getStructurallySingularSystemHandlerArg;

/*****************************************
 No State deselection Method.
 use the index 1/0 system as it is
 *****************************************/

public function noStateDeselection
"author: Frenkel TUD 2012-04
  use the index 1/0 system as it is"
  input BackendDAE.BackendDAE inDAE;
  input list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> inArgs;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := inDAE;
end noStateDeselection;

/*****************************************
 dynamic state selection method .
 see
 - Mattsson, S.E.; Söderlind, G.: A new technique for solving high-index differential-algebraic equations using dummy derivatives, Computer-Aided Control System Design, 1992. (CACSD),1992 IEEE Symposium on , pp.218-224, 17-19 Mar 1992
 - Mattsson, S.E.; Olsson, H; Elmqviste, H. Dynamic Selection of States in Dymola. In: Proceedings of the Modelica Workshop 2000, Lund, Sweden, Modelica Association, 23-24 Oct. 2000.
 - Mattsson, S.; Söderlind, G.: Index reduction in differential-Algebraic equations using dummy derivatives, SIAM J. Sci. Comput. 14, 677-692, 1993.
 *****************************************/

public function dynamicStateSelection
  input BackendDAE.BackendDAE inDAE;
  input list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> inArgs;
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
  HashTableCrIntToExp.HashTable ht;
algorithm
  BackendDAE.DAE(systs,shared) := inDAE;
  // do state selection
  ht := HashTableCrIntToExp.emptyHashTable();
  (systs,shared,ht) := mapdynamicStateSelection(systs,shared,inArgs,1,{},ht);
  shared := Debug.bcallret2(intGt(BaseHashTable.hashTableCurrentSize(ht),0),replaceDummyDerivativesShared,shared,ht,shared);
  outDAE := BackendDAE.DAE(systs,shared);
end dynamicStateSelection;

protected function mapdynamicStateSelection
"Run the state selection Algorithm."
  input list<BackendDAE.EqSystem> isysts;
  input BackendDAE.Shared ishared;
  input list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> iargs;
  input Integer setIndex;
  input list<BackendDAE.EqSystem> acc;
  input HashTableCrIntToExp.HashTable iHt;
  output list<BackendDAE.EqSystem> osysts;
  output BackendDAE.Shared oshared;
  output HashTableCrIntToExp.HashTable oHt;
algorithm
  (osysts,oshared,oHt) := match (isysts,ishared,iargs,setIndex,acc,iHt)
    local
      BackendDAE.EqSystem syst;
      list<BackendDAE.EqSystem> systs;
      BackendDAE.Shared shared;
      BackendDAE.StructurallySingularSystemHandlerArg arg;
      list<Option<BackendDAE.StructurallySingularSystemHandlerArg>> args;
      HashTableCrIntToExp.HashTable ht;
      Integer index;
    case ({},_,_,_,_,_) then (listReverse(acc),ishared,iHt);
    case (syst::systs,_,NONE()::args,_,_,_)
      equation
        (systs,shared,ht) = mapdynamicStateSelection(systs,ishared,args,setIndex,syst::acc,iHt);
      then (systs,shared,ht);
    case (syst::systs,_,SOME(arg)::args,_,_,_)
      equation
        (syst,shared,ht,index) = dynamicStateSelectionWork(syst,ishared,arg,iHt,setIndex);
        (systs,shared,ht) = mapdynamicStateSelection(systs,shared,args,index,syst::acc,ht);
      then (systs,shared,ht);
  end match;
end mapdynamicStateSelection;

protected function dynamicStateSelectionWork
"author: Frenkel TUD 2012-04
  dynamic state deselect of the system."
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StructurallySingularSystemHandlerArg inArg;
  input HashTableCrIntToExp.HashTable iHt;
  input Integer iSetIndex;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output HashTableCrIntToExp.HashTable oHt;
  output Integer oSetIndex;
algorithm
  (osyst,oshared,oHt,oSetIndex):=
  matchcontinue (isyst,ishared,inArg,iHt,iSetIndex)
    local
      BackendDAE.Variables v;
      DAE.FunctionTree funcs;
      BackendDAE.StateOrder so;
      BackendDAE.ConstraintEquations orgEqnsLst;
      array<list<Integer>> mapEqnIncRow;
      array<Integer> mapIncRowEqn;
      Integer freestatevars,orgeqnscount,setIndex;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      HashTableCrIntToExp.HashTable ht;
    // no state selection necessary (OrgEqnsLst is Empty)
    case (_,_,(_,{},_,_,_),_,_)
     then
       (isyst,ishared,iHt,iSetIndex);
    // do state selection
    case (BackendDAE.EQSYSTEM(orderedVars=v),BackendDAE.SHARED(functionTree=funcs),(so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,_),_,_)
      equation
        // do late Inline also in orgeqnslst
        orgEqnsLst = inlineOrgEqns(orgEqnsLst,(SOME(funcs),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()}),{});
        Debug.fcall(Flags.BLT_DUMP, print, "Dynamic State Selection\n");
        Debug.fcall2(Flags.BLT_DUMP, BackendDump.dumpEqSystem, isyst, "Index Reduced System");
        // geth the number of states without stateSelect.always (free states), if the number of differentiated equations is equal to the number of free states no selection is necessary
        freestatevars = BackendVariable.traverseBackendDAEVars(v,countStateCandidates,0);
        orgeqnscount = countOrgEqns(orgEqnsLst,0);
        // select dummy states
        (syst,shared,ht,setIndex) = selectStates(freestatevars,orgeqnscount,isyst,ishared,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,iHt,iSetIndex);
        Debug.fcall2(Flags.BLT_DUMP, BackendDump.dumpEqSystem, syst, "Final System with DummyStates");
     then
       (syst,shared,ht,setIndex);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- IndexReduction.dynamicStateSelectionWork failed!"});
      then
        fail();
  end matchcontinue;
end dynamicStateSelectionWork;

protected function countStateCandidates
"author Frenkel TUD 2013-01
  count the number of states in variables"
  input tuple<BackendDAE.Var,Integer> inTpl;
  output tuple<BackendDAE.Var,Integer> oTpl;
algorithm
  oTpl := match inTpl
    local
      BackendDAE.Var var;
      Integer diffcount,statecount;
      Boolean b;
      DAE.ComponentRef cr;
    case ((var as BackendDAE.VAR(varKind=BackendDAE.STATE(index=1)), statecount))
      equation
        // do not count states with stateSelect.always
        b = varStateSelectAlways(var);
        statecount = Debug.bcallret2(not b, intAdd, statecount, 1, statecount);
      then
        ((var, statecount));
    case ((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(index=diffcount,derName=SOME(_))), statecount))
      equation
        // do not count states with stateSelect.always, but ignore only higest state
        b = varStateSelectAlways(var);
        statecount = Debug.bcallret2(b, intAdd, statecount, 1, statecount);
      then
        ((var, statecount));
    case ((var as BackendDAE.VAR(varName=cr, varKind=BackendDAE.STATE(index=diffcount,derName=NONE())), statecount))
      equation
        statecount = diffcount + statecount;
        // do not count states with stateSelect.always, but ignore only higest state
        b = varStateSelectAlways(var);
        statecount = Debug.bcallret2(b, intSub, statecount, 1, statecount);
      then
        ((var, statecount));
    else then inTpl;
  end match;
end countStateCandidates;

protected function countOrgEqns
"author: Frenkel TUD 2012-06
  return the number of orgens."
  input BackendDAE.ConstraintEquations inOrgEqns;
  input Integer iCount;
  output Integer oCount;
algorithm
  oCount :=
  match (inOrgEqns,iCount)
    local
      list<BackendDAE.Equation> orgeqns;
      BackendDAE.ConstraintEquations rest;
      Integer size;
    case ({},_) then iCount;
    case ((_,orgeqns)::rest,_)
      equation
        size = BackendEquation.equationLstSize(orgeqns);
      then
        countOrgEqns(rest,intAdd(size,iCount));
  end match;
end countOrgEqns;

protected function inlineOrgEqns
"author: Frenkel TUD 2012-08
  add an equation to the ConstrainEquations."
  input BackendDAE.ConstraintEquations inOrgEqns;
  input Inline.Functiontuple inA;
  input BackendDAE.ConstraintEquations inAcc;
  output BackendDAE.ConstraintEquations outOrgEqns;
  replaceable type Type_a subtypeof Any;
algorithm
  outOrgEqns :=
  match (inOrgEqns,inA,inAcc)
    local
      Integer e;
      list<BackendDAE.Equation> orgeqns;
      BackendDAE.ConstraintEquations rest;
    case ({},_,_) then listReverse(inAcc);
    case ((e,orgeqns)::rest,_,_)
      equation
        (orgeqns,_) = Inline.inlineEqs(orgeqns, inA,{},false);
      then
        inlineOrgEqns(rest,inA,(e,orgeqns)::inAcc);
  end match;
end inlineOrgEqns;

protected function replaceDerStatesStates
"author: Frenkel TUD 2012-06
  traverse an exp top down and ."
  input tuple<DAE.Exp, BackendDAE.StateOrder> inTpl;
  output tuple<DAE.Exp, BackendDAE.StateOrder> outTpl;
protected
  DAE.Exp exp;
  BackendDAE.StateOrder so;
algorithm
  (exp,so) := inTpl;
  outTpl := Expression.traverseExp(exp,replaceDerStatesStatesExp,so);
end replaceDerStatesStates;

protected function replaceDerStatesStatesExp
"author: Frenkel TUD 2012-06
  helper for replaceDerStatesStates.
  replaces all der(x) with dx"
  input tuple<DAE.Exp, BackendDAE.StateOrder> inTuple;
  output tuple<DAE.Exp, BackendDAE.StateOrder> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      BackendDAE.StateOrder so;
      DAE.Exp e,e1;
      DAE.ComponentRef cr,dcr;
    // replace it
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst={e1 as DAE.CREF(componentRef = cr)}),so))
      equation
        dcr = getStateOrder(cr,so);
        e1 = Expression.crefExp(dcr);
      then
        ((e1,so));
    else then inTuple;
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

protected function traversinghighestOrderDerivativesFinder
"  author: Frenkel TUD 2012-05
  helper for highestOrderDerivatives"
 input tuple<BackendDAE.Var, tuple<BackendDAE.StateOrder,BackendDAE.Variables,list<BackendDAE.Var>>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendDAE.StateOrder,BackendDAE.Variables,list<BackendDAE.Var>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      DAE.ComponentRef cr,dcr;
      BackendDAE.StateOrder so;
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
      Boolean b;
    case ((v as BackendDAE.VAR(varKind=BackendDAE.STATE(derName=NONE())),(so,vars,varlst)))
      then ((v,(so,vars,v::varlst)));
     case ((v as BackendDAE.VAR(varName=cr,varKind=BackendDAE.STATE(derName=SOME(dcr))),(so,vars,varlst)))
      equation
        b = BackendVariable.isState(dcr,vars);
        varlst = List.consOnTrue(not b, v, varlst);
        so = addStateOrder(cr, dcr, so);
      then ((v,(so,vars,varlst)));
    else then inTpl;
  end matchcontinue;
end traversinghighestOrderDerivativesFinder;

protected function lowerOrderDerivatives
"author: Frenkel TUD 2012-05
  collect all derivatives one order less than derivatives from v"
  input BackendDAE.Variables derv;
  input BackendDAE.Variables v;
  input BackendDAE.StateOrder so;
  output BackendDAE.Variables outVars;
algorithm
  ((_,_,outVars)) := BackendVariable.traverseBackendDAEVars(derv,traversinglowerOrderDerivativesFinder,(so,v,BackendVariable.emptyVars()));
end lowerOrderDerivatives;

protected function traversinglowerOrderDerivativesFinder
"  author: Frenkel TUD 2012-05
  helpber for lowerOrderDerivatives"
 input tuple<BackendDAE.Var, tuple<BackendDAE.StateOrder,BackendDAE.Variables,BackendDAE.Variables>> inTpl;
 output tuple<BackendDAE.Var, tuple<BackendDAE.StateOrder,BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> vlst;
      DAE.ComponentRef dcr;
      list<DAE.ComponentRef> crlst;
      BackendDAE.StateOrder so;
      BackendDAE.Variables vars,vars1,vars2;
     case ((v,(so,vars,vars1)))
      equation
        dcr = BackendVariable.varCref(v);
        crlst = getDerStateOrder(dcr,so);
        vlst = List.map1(crlst,getVar,vars);
        vars2 = List.fold(vlst,BackendVariable.addVar,vars1);
      then ((v,(so,vars,vars2)));
    else then inTpl;
  end matchcontinue;
end traversinglowerOrderDerivativesFinder;

protected function getVar
"author: Frnekel TUD 2012-05
  helper for traversinglowerOrderDerivativesFinder"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output BackendDAE.Var v;
algorithm
  ({v},_) := BackendVariable.getVar(cr,vars);
end getVar;

protected type StateSets = list<tuple<Integer,Integer,Integer,Integer,list<BackendDAE.Var>,list<BackendDAE.Equation>,list<BackendDAE.Var>,list<BackendDAE.Equation>>> "Level,nStates,nStateCandidates,nUnassignedEquations,StateCandidates,ConstraintEqns,OtherVars,OtherEqns";

protected function addStateSets
"author: Frenkel TUD 2013-01
  add the found state set to the system"
  input StateSets iTplLst;
  input Integer iSetIndex;
  input BackendDAE.EqSystem iSystem;
  output Integer oSetIndex;
  output BackendDAE.EqSystem oSystem;
algorithm
  (oSetIndex,oSystem) := match(iTplLst,iSetIndex,iSystem)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> om;
      Option<BackendDAE.IncidenceMatrixT> omT;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
      Integer setIndex;
    case ({},_,_) then (iSetIndex,iSystem);
    case (_::_,_,BackendDAE.EQSYSTEM(vars,eqns,om,omT,matching,stateSets))
      equation
        (setIndex,vars,eqns,stateSets) = generateStateSets(iTplLst,iSetIndex,vars,eqns,stateSets);
      then
        (setIndex,BackendDAE.EQSYSTEM(vars,eqns,om,omT,matching,stateSets));
  end match;
end addStateSets;

protected function generateStateSets
"author: Frenkel TUD 2013-01
  generate the found state sets for the system"
  input StateSets iTplLst "nStates,nStateCandidates,nUnassignedEquations,StateCandidates,ConstraintEqns,OtherVars,OtherEqns";
  input Integer iSetIndex;
  input BackendDAE.Variables iVars;
  input BackendDAE.EquationArray iEqns;
  input BackendDAE.StateSets iStateSets;
  output Integer oSetIndex;
  output BackendDAE.Variables oVars;
  output BackendDAE.EquationArray oEqns;
  output BackendDAE.StateSets oStateSets;
algorithm
  (oSetIndex,oVars,oEqns,oStateSets) := match(iTplLst,iSetIndex,iVars,iEqns,iStateSets)
      local
        StateSets rest;
        list<BackendDAE.Var> setVars,aVars,varJ,otherVars,stateCandidates;
        list<DAE.ComponentRef> crstates,crset;
        DAE.ComponentRef crA,set,crJ;
        DAE.Type tp;
        Integer rang,nStates,nStateCandidates,nUnassignedEquations,setIndex,level;
        BackendDAE.Variables vars;

        DAE.Exp expcrA,mulAstates,mulAdstates,expset,expderset,expsetstart;
        list<DAE.Exp> expcrstates,expcrdstates,expcrset,expcrdset,expcrstatesstart;
        DAE.Operator op;
        BackendDAE.Equation eqn,deqn;
        BackendDAE.EquationArray eqns;
        list<BackendDAE.Equation> cEqnsLst,oEqnLst;
        BackendDAE.StateSets stateSets;
        DAE.ElementSource source;
    case ({},_,_,_,_) then (iSetIndex,iVars,iEqns,iStateSets);
    case ((level,nStates,nStateCandidates,nUnassignedEquations,stateCandidates,cEqnsLst,otherVars,oEqnLst)::rest,_,_,_,_)
      equation
        rang = nStateCandidates - nUnassignedEquations;
         // generate Set Vars
        (set,crset,setVars,crA,aVars,tp,crJ,varJ) = getSetVars(iSetIndex,rang,nStateCandidates,nUnassignedEquations,level);
        // add Equations
        // set.x = set.A*set.statecandidates
        // der(set.x) = set.A*der(set.candidates)
        crstates = List.map(stateCandidates,BackendVariable.varCref);
        expcrstates = List.map(crstates,Expression.crefExp);
        expcrstatesstart = List.map(expcrstates,makeStartExp);
        expcrdstates = List.map(expcrstates,makeder);
        expcrset = List.map(crset,Expression.crefExp);
        expcrdset = List.map(expcrset,makeder);
        expcrA = Expression.crefExp(crA);
        expcrA = DAE.CAST(tp,expcrA);
        op = Util.if_(intGt(rang,1),DAE.MUL_MATRIX_PRODUCT(DAE.T_REAL_DEFAULT),DAE.MUL_SCALAR_PRODUCT(DAE.T_REAL_DEFAULT));
        mulAstates = DAE.BINARY(expcrA,op,DAE.ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nStateCandidates)},DAE.emptyTypeSource),true,expcrstates));
        ((mulAstates,(_,_))) = BackendDAEUtil.extendArrExp((mulAstates,(NONE(),false)));
        mulAdstates = DAE.BINARY(expcrA,op,DAE.ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nStateCandidates)},DAE.emptyTypeSource),true,expcrdstates));
        ((mulAdstates,(_,_))) = BackendDAEUtil.extendArrExp((mulAdstates,(NONE(),false)));
        expset = Util.if_(intGt(rang,1),DAE.ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(rang)},DAE.emptyTypeSource),true,expcrset),listGet(expcrset,1));
        expderset = Util.if_(intGt(rang,1),DAE.ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(rang)},DAE.emptyTypeSource),true,expcrdset),listGet(expcrdset,1));
        source = DAE.SOURCE(Absyn.INFO("stateselection",false,0,0,0,0,Absyn.dummyTimeStamp),{},{},{},{},{},{});
        // set.x = set.A*set.statecandidates
        eqn  = Util.if_(intGt(rang,1),BackendDAE.ARRAY_EQUATION({rang},expset,mulAstates,source,false),
                                      BackendDAE.EQUATION(expset,mulAstates,source,false));
        // der(set.x) = set.A*der(set.candidates)
        deqn  = Util.if_(intGt(rang,1),BackendDAE.ARRAY_EQUATION({rang},expderset,mulAdstates,DAE.emptyElementSource,false),
                                      BackendDAE.EQUATION(expderset,mulAdstates,DAE.emptyElementSource,false));
        // start values for the set
        expsetstart = DAE.BINARY(expcrA,op,DAE.ARRAY(DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nStateCandidates)},DAE.emptyTypeSource),true,expcrstatesstart));
        ((expsetstart,(_,_))) = BackendDAEUtil.extendArrExp((expsetstart,(NONE(),false)));
        (setVars,_) = List.map2Fold(setVars,setStartExp,expsetstart,rang,1);
        // add set states
        vars = BackendVariable.addVars(setVars,iVars);
        // add equations
        eqns = BackendEquation.equationAdd(eqn, iEqns);
        eqns = BackendEquation.equationAdd(deqn, eqns);
        // set varkind to dummy_state
        stateCandidates = List.map1(stateCandidates,BackendVariable.setVarKind,BackendDAE.DUMMY_STATE());
        otherVars = List.map1(otherVars,BackendVariable.setVarKind,BackendDAE.DUMMY_STATE());
        // generate state set;
        (setIndex,vars,eqns,stateSets) = generateStateSets(rest,iSetIndex+1,vars,eqns,BackendDAE.STATESET(rang,crset,crA,aVars,stateCandidates,otherVars,cEqnsLst,oEqnLst,crJ,varJ)::iStateSets);
      then
        (setIndex,vars,eqns,stateSets);
  end match;
end generateStateSets;

protected function makeStartExp
"generate the expression: $_start(inExp)"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := Expression.makeBuiltinCall("$_start", {inExp}, Expression.typeof(inExp));
end makeStartExp;

protected function setStartExp
"generate the expression: $_start(inExp)"
  input BackendDAE.Var inVar;
  input DAE.Exp startExp;
  input Integer size;
  input Integer iIndex;
  output BackendDAE.Var outVar;
  output Integer oIndex;
protected
  DAE.Exp e;
algorithm
  e := Debug.bcallret2(intGt(size,1),Expression.makeASUB,startExp, {DAE.ICONST(iIndex)}, startExp);
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
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StateOrder iSo;
  input BackendDAE.ConstraintEquations orgEqnsLst;
  input array<list<Integer>> iMapEqnIncRow;
  input array<Integer> iMapIncRowEqn;
  input HashTableCrIntToExp.HashTable iHt;
  input Integer iSetIndex;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output HashTableCrIntToExp.HashTable oHt;
  output Integer oSetIndex;
algorithm
  (osyst,oshared,oHt,oSetIndex) :=
  matchcontinue(nfreeStates,nOrgEqns,isyst,ishared,iSo,orgEqnsLst,iMapEqnIncRow,iMapIncRowEqn,iHt,iSetIndex)
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
    case (_,_,BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2)),_,_,_,_,_,_,_)
      equation
        true = intEq(nfreeStates,nOrgEqns);
        // add the original equations to the systems
        eqnslst = List.flatten(List.map(orgEqnsLst,Util.tuple22));
        syst = BackendEquation.equationsAddDAE(eqnslst, isyst);
        // change dummy states
        (syst,ht) = addAllDummyStates(syst,iSo,iHt);
        // update IncidenceMatrix
        funcs = BackendDAEUtil.getFunctions(ishared);
        (syst,m,_,_,_) = BackendDAEUtil.getIncidenceMatrixScalar(syst,BackendDAE.SOLVABLE(), SOME(funcs));
        // expand the matching
        ass1 = Util.arrayExpand(nfreeStates,ass1,-1);
        ass2 =Util.arrayExpand(nOrgEqns,ass2,-1);
        nv = BackendVariable.varsSize(BackendVariable.daeVars(syst));
        ne = BackendDAEUtil.systemSize(syst);
        true = BackendDAEEXT.setAssignment(ne,nv,ass2,ass1);
        Matching.matchingExternalsetIncidenceMatrix(nv, ne, m);
        BackendDAEEXT.matching(nv, ne, 5, -1, 0.0, 0);
        BackendDAEEXT.getAssignment(ass2, ass1);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(ass1,ass2,{}));
      then
        (syst,ishared,ht,iSetIndex);
    // select states
    case (_,_,_,_,_,_,_,_,_,_)
      equation
        ErrorExt.setCheckpoint("DynamicStateSelection");
        // get highest order derivatives
        (hov,so) = highestOrderDerivatives(BackendVariable.daeVars(isyst),iSo);
        Debug.fcall(Flags.BLT_DUMP, dumpStateOrder, so);
        // get scalar incidence matrix solvable
        funcs = BackendDAEUtil.getFunctions(ishared);
        // replace der(x,n) with DERn.Der(n-1)..DER.x and add variables
        syst = replaceHigherDerivatives(isyst);
        (syst,_,_,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(syst,BackendDAE.SOLVABLE(), SOME(funcs));
        // do state selection for each level
        (syst,shared,ht,setIndex) = selectStatesWork(1,hov,syst,ishared,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,iHt,iSetIndex);
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
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StateOrder so;
  input BackendDAE.ConstraintEquations iOrgEqnsLst;
  input array<list<Integer>> iMapEqnIncRow;
  input array<Integer> iMapIncRowEqn;
  input HashTableCrIntToExp.HashTable iHt;
  input Integer iSetIndex;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
  output HashTableCrIntToExp.HashTable oHt;
  output Integer oSetIndex;
algorithm
  (osyst,oshared,oHt,oSetIndex) :=
  match(level,iHov,isyst,ishared,so,iOrgEqnsLst,iMapEqnIncRow,iMapIncRowEqn,iHt,iSetIndex)
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
    case (_,_,_,_,_,{},_,_,_,_) then (isyst,ishared,iHt,iSetIndex);
    case (_,_,BackendDAE.EQSYSTEM(orderedVars=vars,matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2)),_,_,_,_,_,_,_)
      equation
        // get orgequations of that level
        (eqnslst1,ilst,orgEqnsLst) = getFirstOrgEqns(iOrgEqnsLst,{},{},{});
        // replace final parameter
        (eqnslst,_) = BackendEquation.traverseBackendDAEExpsEqnList(eqnslst1, replaceFinalVarsEqn,(BackendVariable.daeKnVars(ishared),false,BackendVarTransform.emptyReplacements()));
        // replace all der(x) with dx
        (eqnslst,_) = BackendEquation.traverseBackendDAEExpsEqnList(eqnslst, replaceDerStatesStates,so);
        // force inline
        funcs = BackendDAEUtil.getFunctions(ishared);
        (eqnslst,_) = BackendEquation.traverseBackendDAEExpsEqnList(eqnslst, forceInlinEqn,funcs);
        // try to make scalar
        (eqnslst,_) = BackendDAEOptimize.getScalarArrayEqns(eqnslst,{},false);
        // convert x:STATE(n) if n>1 to DER.DER....x
        (hov,ht) = List.map1Fold(iHov,getLevelStates,level,HashTableCrIntToExp.emptyHashTable());
        (eqnslst,_) = BackendEquation.traverseBackendDAEExpsEqnList(eqnslst, replaceDummyDerivatives, ht);
        (eqnslst1,_) = BackendEquation.traverseBackendDAEExpsEqnList(eqnslst1, replaceDummyDerivatives, ht);
        // remove stateSelect=StateSelect.always vars
        varlst = List.filter1(hov, notVarStateSelectAlways, level);
        neqns = BackendEquation.equationLstSize(eqnslst);
        nfreeStates = listLength(varlst);
        // do state selection of that level
        (dummyVars,stateSets) = selectStatesWork1(nfreeStates,varlst,neqns,eqnslst,level,isyst,ishared,so,iMapEqnIncRow,iMapIncRowEqn,hov,{},{});
        // get derivatives one order less
        lov = List.fold3(iHov, getlowerOrderDerivatives, level, so, vars, {});
        // remove DummyStates DER.x from States with v_d>1 with unkown derivative dummyVars
        repl = HashTable2.emptyHashTable();
        (dummyVars,repl) = removeFirstOrderDerivatives(dummyVars,vars,so,{},repl);
        nv = BackendVariable.varsSize(vars);
        ne = BackendDAEUtil.systemSize(isyst);
        // add the original equations to the systems
        syst = BackendEquation.equationsAddDAE(eqnslst1, isyst);
        // add the found state sets for dynamic state selection to the system
        (setIndex,syst) = addStateSets(stateSets,iSetIndex,syst);
        // change dummy states, update Assignments
        (syst,ht) = addDummyStates(dummyVars,level,repl,syst,iHt);
        // fix derivative indexes
        vars = List.fold1(iHov, fixDerivativeIndex, level, BackendVariable.daeVars(syst));
        // update IncidenceMatrix
        (syst,m,_,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(syst,BackendDAE.SOLVABLE(), SOME(funcs));
        // genereate new Matching
        nv1 = BackendVariable.varsSize(BackendVariable.daeVars(syst));
        ne1 = BackendDAEUtil.systemSize(syst);
        ass1 = Util.arrayExpand(nv1-nv,ass1,-1);
        ass2 =Util.arrayExpand(ne1-ne,ass2,-1);
        true = BackendDAEEXT.setAssignment(nv1,ne1,ass2,ass1);
        Matching.matchingExternalsetIncidenceMatrix(nv1, ne1, m);
        BackendDAEEXT.matching(nv1, ne1, 5, -1, 0.0, 0);
        BackendDAEEXT.getAssignment(ass2, ass1);
        syst = BackendDAEUtil.setEqSystemMatching(syst,BackendDAE.MATCHING(ass1,ass2,{}));
        //  BackendDump.dumpEqSystem(syst,"Next Level");
        // next level
        (syst,shared,ht,setIndex) = selectStatesWork(level+1,lov,syst,ishared,so,orgEqnsLst,mapEqnIncRow,mapIncRowEqn,ht,setIndex);
      then
        (syst,shared,ht,setIndex);
  end match;
end selectStatesWork;

protected function removeFirstOrderDerivatives
"author Frenkel TUD 2013-01
  remove dummy derivatives from states with higher derivatives and no known derivative variable"
  input list<BackendDAE.Var> iDummyVars;
  input BackendDAE.Variables iVars;
  input BackendDAE.StateOrder so;
  input list<BackendDAE.Var> iAcc;
  input HashTable2.HashTable iRepl;
  output list<BackendDAE.Var> oDummyVars;
  output HashTable2.HashTable oRepl;
algorithm
  (oDummyVars,oRepl) := matchcontinue(iDummyVars,iVars,so,iAcc,iRepl)
    local
      list<BackendDAE.Var> dummyVars;
      HashTable2.HashTable repl;
      BackendDAE.Var var;
      DAE.ComponentRef cr,dcr;
      DAE.Exp exp;
    // finished
    case({},_,_,_,_) then (iAcc,iRepl);
    // dummy derivatives from states with higher derivatives and no known derivative variable
    case (BackendDAE.VAR(varName=dcr as DAE.CREF_QUAL(ident="$DER",componentRef=cr),varKind=BackendDAE.STATE(index=1))::dummyVars,_,_,_,_)
      equation
         false = intEq(System.strncmp(ComponentReference.crefFirstIdent(cr),"$DER",4),0);
         exp = Expression.crefExp(cr);
         exp = Expression.makeBuiltinCall("der", {exp}, Expression.typeof(exp));
         repl = BaseHashTable.add((dcr,exp),iRepl);
        (dummyVars,repl) = removeFirstOrderDerivatives(dummyVars,iVars,so,iAcc,repl);
      then
        (dummyVars,repl);
    // keep it
    case (var::dummyVars,_,_,_,_)
      equation
        (dummyVars,repl) = removeFirstOrderDerivatives(dummyVars,iVars,so,var::iAcc,iRepl);
      then
        (dummyVars,repl);
  end matchcontinue;
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
  oVars := matchcontinue(inVar,level,so,vars,iVars)
    local
      Integer diffindx;
      DAE.ComponentRef dcr;
      list<DAE.ComponentRef> crlst;
      list<BackendDAE.Var> vlst;
    case(BackendDAE.VAR(varName=dcr,varKind=BackendDAE.STATE(index=diffindx)),_,_,_,_)
      equation
        true = intEq(diffindx,1);
        crlst = getDerStateOrder(dcr,so);
        vlst = List.map1(crlst,getVar,vars);
        vlst = listAppend(vlst,iVars);
      then
        vlst;
    case(BackendDAE.VAR(varName=dcr,varKind=BackendDAE.STATE(index=diffindx)),_,_,_,_)
      then
         List.consOnTrue(intGt(diffindx,level),inVar,iVars);
    else then iVars;
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
    else then iVars;
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
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
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
  matchcontinue(nfreeStates,statecandidates,neqns,eqnslst,level,isyst,ishared,so,iMapEqnIncRow,iMapIncRowEqn,iHov,inDummyVars,iStateSets)
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
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(nfreeStates,neqns);
      then
        (statecandidates,iStateSets);
    // do state selection
    case (_,_,_,_,_,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=SOME(m),mT=SOME(mT),matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2)),_,_,_,_,_,_,_)
      equation
        // try to select dummy vars
        true = intGt(nfreeStates,1);
        false = intGt(neqns,nfreeStates);
        Debug.fcall(Flags.BLT_DUMP, print, "try to select dummy vars with natural matching(newer)\n");
        //  print("Vars " +& intString(nfreeStates) +& " Eqns " +& intString(neqns) +& "\n");
        // sort vars with heuristic
        hovvars = BackendVariable.listVar1(statecandidates);
        eqns1 = BackendEquation.listEquation(eqnslst);
        syst = BackendDAE.EQSYSTEM(hovvars,eqns1,NONE(),NONE(),BackendDAE.NO_MATCHING(),{});
        (me,meT,_,_) =  BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst,ishared);
        m1 = incidenceMatrixfromEnhanced2(me,hovvars);
        mT1 = BackendDAEUtil.transposeMatrix(m1,nfreeStates);
        //  BackendDump.printEqSystem(syst);
        hovvars = sortStateCandidatesVars(hovvars,BackendVariable.daeVars(isyst),SOME(mT1));
        Debug.fcall(Flags.BLT_DUMP, print, "highest Order Derivatives:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVariables, hovvars);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printEquationList, eqnslst);
        // generate incidence matrix from system and equations of that level and the states of that level
        nv = BackendVariable.varsSize(vars);
        ne = BackendDAEUtil.equationSize(eqns);
        neqnarr = BackendDAEUtil.equationArraySize(eqns);
        ne1 = ne + neqns;
        indexmap = arrayCreate(nfreeStates  + nv,-1);
        invindexmap = arrayCreate(nfreeStates,-1);
        // workaround to get state indexes
        (vars,(indexmap,invindexmap,_,nv1,_,_,_)) = BackendVariable.traverseBackendDAEVarsWithUpdate(vars,getStateIndexes,(indexmap,invindexmap,1,nv,nv,hovvars,{}));
        //  BackendDump.dumpMatching(indexmap);
        m1 = arrayCreate(ne1,{});
        mT1 = arrayCreate(nv1,{});
        mapEqnIncRow = Util.arrayExpand(neqns,iMapEqnIncRow,{});
        mapIncRowEqn = Util.arrayExpand(neqns,iMapIncRowEqn,-1);
        // replace state indexes in original incidencematrix
        getIncidenceMatrixSelectStates(ne,m1,mT1,m,indexmap);
        // add level equations
        funcs = BackendDAEUtil.getFunctions(ishared);
        getIncidenceMatrixLevelEquations(eqnslst,vars,neqnarr,ne,m1,mT1,m,mapEqnIncRow,mapIncRowEqn,indexmap,funcs);
        // match the variables not the equations, to have prevered states unmatched
        vec1 = Util.arrayExpand(nfreeStates,ass1,-1);
        vec2 =Util.arrayExpand(neqns,ass2,-1);
        true = BackendDAEEXT.setAssignment(nv1,ne1,vec1,vec2);
        Matching.matchingExternalsetIncidenceMatrix(ne1, nv1, mT1);
        BackendDAEEXT.matching(ne1, nv1, 3, -1, 0.0, 0);
        BackendDAEEXT.getAssignment(vec1, vec2);
        comps = BackendDAETransform.tarjanAlgorithm(mT1,vec2);
        // remove blocks without differentiated equations
        comps = List.select1(comps, selectBlock, ne);
        //  BackendDump.dumpComponentsOLD(comps);
        //  eqns1 = BackendEquation.listEquation(BackendEquation.equationList(eqns));
        //  eqns1 = BackendEquation.addEquations(eqnslst, eqns1);
        //  List.map3_0(comps, dumpBlock, mapIncRowEqn, nv, BackendDAE.EQSYSTEM(vars,eqns1,SOME(m1),NONE(),BackendDAE.MATCHING(invindexmap,vec2,{}),{}) );
        // traverse the blocks and collect the additional equations and vars
        ilst = List.fold1(comps,getCompsExtraEquations,ne,{});
        ilst = List.map1r(ilst,arrayGet,iMapIncRowEqn);
        ilst = List.uniqueIntN(ilst, ne);
        eqnslst1 = BackendEquation.getEqns(ilst,eqns);
        ilst = List.fold2(comps,getCompsExtraVars,nv,vec2,{});
        vlst = List.map1r(ilst,BackendVariable.getVarAt,vars);
        // generate system
        eqns = BackendEquation.listEquation(eqnslst);
        eqns = BackendEquation.addEquations(eqnslst1, eqns);
        vars = BackendVariable.listVar1(vlst);
        vars = BackendVariable.addVars(BackendVariable.varList(hovvars), vars);
        syst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),{});
        // get advanced incidence Matrix
        (me,meT,mapEqnIncRow,mapIncRowEqn) =  BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst,ishared);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpAdjacencyMatrixEnhanced,me);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpAdjacencyMatrixTEnhanced,meT);
        // get indicenceMatrix from Enhanced
        m = incidenceMatrixfromEnhanced2(me,vars);
        nv = BackendVariable.varsSize(vars);
        ne = BackendDAEUtil.equationSize(eqns);
        mT = BackendDAEUtil.transposeMatrix(m,nv);
        // match the variables not the equations, to have prevered states unmatched
        Matching.matchingExternalsetIncidenceMatrix(ne,nv,mT);
        BackendDAEEXT.matching(ne,nv,3,-1,1.0,1);
        vec1 = arrayCreate(nv,-1);
        vec2 = arrayCreate(ne,-1);
        BackendDAEEXT.getAssignment(vec1,vec2);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching, vec1);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.dumpMatching, vec2);
        // get the matched state candidates -> dummyVars
        (dstates,states) = checkAssignment(1,nv,vec1,vars,{},{});
        dummyVars = List.map1r(List.map(dstates,Util.tuple22),BackendVariable.getVarAt,vars);
        dummyVars = List.select(dummyVars, BackendVariable.isStateVar);
        Debug.fcall(Flags.BLT_DUMP, print, ("select as Dummy States:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList,dummyVars);
        // get assigned and unassigned equations
        unassigned = Matching.getUnassigned(ne, vec2, {});
        assigned = Matching.getAssigned(ne, vec2, {});
        Debug.fcall(Flags.BLT_DUMP, print, ("Unassigned Eqns:\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((unassigned,intString," ","\n")));
        // splitt it into sets
        syst = BackendDAEUtil.setEqSystemMatching(syst, BackendDAE.MATCHING(vec1,vec2,{}));
        //  dumpSystemGraphML(syst,ishared,NONE(),"StateSelection" +& intString(arrayLength(m)) +& ".graphml");
        (syst,m,mT,mapEqnIncRow,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(syst,BackendDAE.ABSOLUTE(), SOME(funcs));
        // TODO: partition the system
        comps = partitionSystem(m,mT);
        //  print("Sets:\n");
        //  BackendDump.dumpIncidenceMatrix(listArray(comps));
        //  BackendDump.printEqSystem(syst);
        (vlst,_,stateSets) = processComps4New(comps,nv,ne,vars,eqns,m,mT,mapEqnIncRow,mapIncRowEqn,vec2,vec1,level,ishared,{},{},iStateSets);
        vlst = List.select(vlst, BackendVariable.isStateVar);
        dummyVars = listAppend(dummyVars,vlst);
      then
        (dummyVars,stateSets);
    // to much equations this is an error
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(neqns,nfreeStates);
        Debug.fcall(Flags.BLT_DUMP, print, "highest Order Derivatives:\n");
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printVarList, statecandidates);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.printEquationList, eqnslst);
        // no chance, to much equations
        msg = "It is not possible to select continues time states because Number of Equations " +& intString(neqns) +& " greater than number of States " +& intString(nfreeStates) +& " to select from.";
        Error.addMessage(Error.INTERNAL_ERROR, {msg});
      then
        fail();
    // number of differentiated equations exceeds number of free states, add StateSelect.always states and try again
    case (_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intGt(neqns,nfreeStates);
        // try again and add also stateSelect.always vars.
        nv = listLength(iHov);
        true = intGe(nv,neqns);
        (dummyVars,stateSets) = selectStatesWork1(nv,iHov,neqns,eqnslst,level,isyst,ishared,so,iMapEqnIncRow,iMapIncRowEqn,iHov,inDummyVars,iStateSets);
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
        b = Debug.bcallret2(intLe(c,ne),selectBlock,rest,ne,true);
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
  print(BackendDump.dumpMarkedVars(syst, ilst) +& "\n");
  print(BackendDump.dumpMarkedEqns(syst, eqns));
end dumpBlock;

protected function getStateIndexes
  input tuple<BackendDAE.Var, tuple<array<Integer>,array<Integer>,Integer,Integer,Integer,BackendDAE.Variables,list<Integer>>> inTpl;
  output tuple<BackendDAE.Var, tuple<array<Integer>,array<Integer>,Integer,Integer,Integer,BackendDAE.Variables,list<Integer>>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      DAE.ComponentRef cr;
      BackendDAE.Var v;
      array<Integer> stateindexs,invmap;
      Integer indx,s,nv;
      BackendDAE.Variables hov;
      list<Integer> derstatesindexs;
      Option<DAE.ComponentRef> derName;
    case ((v as BackendDAE.VAR(varName=cr,varKind=BackendDAE.STATE(derName=derName)),(stateindexs,invmap,indx,s,nv,hov,derstatesindexs)))
      equation
        (_::_,_) = BackendVariable.getVar(cr, hov);
        s = s+1;
        _= arrayUpdate(stateindexs,indx,s);
        _= arrayUpdate(invmap,s-nv,indx);
      then
        ((v,(stateindexs,invmap,indx+1,s,nv,hov,indx::derstatesindexs)));
    case ((v,(stateindexs,invmap,indx,s,nv,hov,derstatesindexs)))
      then
        ((v,(stateindexs,invmap,indx+1,s,nv,hov,derstatesindexs)));
  end matchcontinue;
end getStateIndexes;

protected function getIncidenceMatrixSelectStates
  input Integer nEqns;
  input BackendDAE.IncidenceMatrix m "input/output";
  input BackendDAE.IncidenceMatrixT mT "input/output";
  input BackendDAE.IncidenceMatrix mo;
  input array<Integer> stateindexs;
algorithm
  _ := match(nEqns,m,mT,mo,stateindexs)
    local
      list<Integer> row,negrow;
    case (0,_,_,_,_) then ();
    case (_,_,_,_,_)
      equation
        // get row
        row = mo[nEqns];
        // replace negative index with index from stateindexs
        row = List.map1(row,replaceStateIndex,stateindexs);
        // update m
        _ = arrayUpdate(m,nEqns,row);
        // update mT
        (row,negrow) = List.split1OnTrue(row, intGt, 0);
        _ = List.fold1(row,Util.arrayCons,nEqns,mT);
        row = List.map(negrow,intAbs);
        _ = List.fold1(row,Util.arrayCons,-nEqns,mT);
        // next
        getIncidenceMatrixSelectStates(nEqns-1,m,mT,mo,stateindexs);
      then
        ();
  end match;
end getIncidenceMatrixSelectStates;

protected function replaceStateIndex
  input Integer iR;
  input array<Integer> stateindexs;
  output Integer oR;
algorithm
  oR := matchcontinue(iR,stateindexs)
    local
      Integer s,r;
    case (_,_)
      equation
        false = intGt(iR,0);
        r = intAbs(iR);
        s = stateindexs[r];
        true = intGt(s,0);
      then
        s;
    case (_,_) then iR;
  end matchcontinue;
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
  _ :=
    match (iEqns, vars, index, sindex, m, mT, om, mapEqnIncRow, mapIncRowEqn, stateindexs, functionTree)
    local
      list<BackendDAE.Equation> rest;
      list<Integer> row,rowindxs,negrow;
      BackendDAE.Equation e;
      Integer i1,rowSize,size;

    case ({}, _, _, _, _, _, _, _, _, _, _) then ();

    // i < n
    case (e::rest, _, _, _, _, _, _, _, _, _, _)
      equation
        // compute the row
        (row,size) = BackendDAEUtil.incidenceRow(e, vars, BackendDAE.SOLVABLE(), SOME(functionTree), {});
        rowSize = sindex + size;
        i1 = index+1;
        rowindxs = List.intRange2(sindex+1, rowSize);
        _ = List.fold1r(rowindxs,arrayUpdate,i1,mapIncRowEqn);
        _ = arrayUpdate(mapEqnIncRow,i1,rowindxs);
        // replace state indexes
        row = List.map1(row,replaceStateIndex,stateindexs);
        // update m
        _ = List.fold1r(rowindxs,arrayUpdate,row,m);
        // update mT
        (row,negrow) = List.split1OnTrue(row, intGt, 0);
        _ = List.fold1(row,Util.arrayListAppend,rowindxs,mT);
        row = List.map(negrow,intAbs);
        rowindxs = List.map(rowindxs,intNeg);
        _ = List.fold1(row,Util.arrayListAppend,rowindxs,mT);
        // next equation
        getIncidenceMatrixLevelEquations(rest, vars, i1, rowSize, m, mT, om, mapEqnIncRow, mapIncRowEqn, stateindexs, functionTree);
      then
        ();
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
  oNSystems := matchcontinue(index,m,mT,rowmarkarr,collmarkarr,iNSystems)
    local
      list<Integer> rows;
      Integer nsystems;
    case (0,_,_,_,_,_) then iNSystems-1;
    case (_,_,_,_,_,_)
      equation
        // if unmarked then increse nsystems
        false = intGt(rowmarkarr[index],0);
        _ = arrayUpdate(rowmarkarr,index,iNSystems);
        rows = List.select(m[index], Util.intPositive);
        nsystems = partitionSystemstraverseRows(rows,{},m,mT,rowmarkarr,collmarkarr,iNSystems);
      then
        partitionSystem1(index-1,m,mT,rowmarkarr,collmarkarr,nsystems);
    case (_,_,_,_,_,_)
      equation
        // if marked skipp it
        true = intGt(rowmarkarr[index],0);
      then
        partitionSystem1(index-1,m,mT,rowmarkarr,collmarkarr,iNSystems);
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
  oNSystems := matchcontinue(iRows,iQueue,m,mT,rowmarkarr,collmarkarr,iNSystems)
    local
      list<Integer> rest,colls,rows;
      Integer r;
    case ({},{},_,_,_,_,_) then iNSystems+1;
    case ({},_,_,_,_,_,_)
      then
        partitionSystemstraverseRows(iQueue,{},m,mT,rowmarkarr,collmarkarr,iNSystems);
    case (r::rest,_,_,_,_,_,_)
      equation
        // if unmarked then add
        false = intGt(collmarkarr[r],0);
        _ = arrayUpdate(collmarkarr,r,iNSystems);
        colls = List.select(mT[r], Util.intPositive);
        colls = List.select1r(colls,Matching.isUnAssigned, rowmarkarr);
        _ = List.fold(colls, markTrue, (rowmarkarr,iNSystems));
        rows = List.flatten(List.map1r(colls,arrayGet,m));
        rows = List.select1r(rows,Matching.isUnAssigned, collmarkarr);
        rows = listAppend(rows,iQueue);
      then
        partitionSystemstraverseRows(rest,rows,m,mT,rowmarkarr,collmarkarr,iNSystems);
    case (r::rest,_,_,_,_,_,_)
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
  osystsarr := match(index,rowmarkarr,systsarr)
    local
      Integer i;
      array<list<Integer>> arr;
    case (0,_,_) then systsarr;
    case (_,_,_)
      equation
        i = rowmarkarr[index];
        arr = Util.arrayCons(i, index, systsarr);
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
  output list<BackendDAE.Var> outDummyVars;
  output list<DAE.ComponentRef> outDummyStates;
  output StateSets oStateSets;
algorithm
  (outDummyVars,outDummyStates,oStateSets) :=
  matchcontinue(iSets,inVarSize,inEqnsSize,iVars,iEqns,inM,inMT,inMapEqnIncRow,inMapIncRowEqn,vec1,vec2,level,iShared,inHov,inDummyStates,iStateSets)
    local
      array<list<Integer>> mapEqnIncRow1;
      array<Integer> mapIncRowEqn1,ass1arr;
      list<DAE.ComponentRef> dummyStates;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns,eqns1;
      BackendDAE.EqSystem syst;
      list<Integer> seteqns,unassigned,assigned,set,statevars,dstatevars,ass1,ass2,assigend1,range;
      list<BackendDAE.Var> varlst;
      list<list<Integer>> sets;
      array<Boolean> flag;
      list<BackendDAE.Equation> eqnlst;
      BackendDAE.AdjacencyMatrixEnhanced me;
      BackendDAE.AdjacencyMatrixTEnhanced meT;
      list<tuple<DAE.ComponentRef, Integer>> states1,dstates1;
      Integer nstatevars,nassigned,nunassigned,nass1arr,n,nv,ne;
      StateSets stateSets;

    case ({},_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      then
        (inHov,inDummyStates,iStateSets);
    case (assigned::sets,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // ignore sets without unassigned equations, because all assigned states already in dummy states
        {} = List.select1r(assigned,Matching.isUnAssigned,vec1);
        // next set
        (varlst,dummyStates,stateSets) = processComps4New(sets,inVarSize,inEqnsSize,iVars,iEqns,inM,inMT,inMapEqnIncRow,inMapIncRowEqn,vec1,vec2,level,iShared,inHov,inDummyStates,iStateSets);
     then
        (varlst,dummyStates,stateSets);
    case (seteqns::sets,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        //  print("seteqns: " +& intString(listLength(seteqns)) +& "\n");
        //  print(stringDelimitList(List.map(seteqns,intString),", ") +& "\n");
        unassigned = List.select1r(seteqns,Matching.isUnAssigned,vec1);
        n = arrayLength(inM);
        set = getEqnsforDynamicStateSelection(unassigned,n,inM,inMT,vec1,vec2,inMapEqnIncRow,inMapIncRowEqn);
        assigned = List.select1r(set,Matching.isAssigned,vec1);
        //  print("Set: " +& intString(listLength(set)) +& "\n");
        //  print(stringDelimitList(List.map(set,intString),", ") +& "\n");
        //  print("assigned: " +& intString(listLength(assigned)) +& "\n");
        //  print(stringDelimitList(List.map(assigned,intString),", ") +& "\n");
        flag = arrayCreate(inVarSize,true);
        ((statevars,dstatevars)) = List.fold3(set,getSetStates,flag,inM,vec2,({},{}));
        //  print("Statevars: " +& intString(listLength(statevars)) +& "\n");
        //  print(stringDelimitList(List.map(statevars,intString),", ") +& "\n");
        //  print("Select " +& intString(listLength(unassigned)) +& " from " +& intString(listLength(statevars)) +& "\n");
        nstatevars = listLength(statevars);
        ass1 = List.consN(nstatevars, -1, {});
        nunassigned = listLength(unassigned);
        ass2 = List.consN(nunassigned, -1, {});
        varlst = List.map1r(statevars,BackendVariable.getVarAt,iVars);
        assigend1 = List.map1r(unassigned,arrayGet,inMapIncRowEqn);
        n = arrayLength(inMapIncRowEqn);
        assigend1 = List.uniqueIntN(assigend1,n);
        //  print("BackendEquation.getEqns " +& stringDelimitList(List.map(assigend1,intString),", ") +& "\n");
        eqnlst = BackendEquation.getEqns(assigend1,iEqns);
        //  print("BackendEquation.equationRemove " +& stringDelimitList(List.map(assigend1,intString),", ") +& "\n");
        eqns1 = List.fold(assigend1,BackendEquation.equationRemove,iEqns);
        nassigned = listLength(assigned);
        flag = arrayCreate(inEqnsSize,true);
        (eqnlst,varlst,ass1,ass2,eqns1) = getSetSystem(assigned,inMapEqnIncRow,inMapIncRowEqn,vec1,iVars,eqns1,flag,nassigned,eqnlst,varlst,ass1,ass2);
        eqns = BackendEquation.listEquation(eqnlst);
        vars = BackendVariable.listVar1(varlst);
        syst = BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),{});
        //  BackendDump.printEqSystem(syst);
        //  BackendDump.dumpMatching(listArray(ass1));
        //  BackendDump.dumpMatching(listArray(ass2));
        (me,meT,mapEqnIncRow1,mapIncRowEqn1) = BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst,iShared);
        ass1arr = listArray(ass1);
        nass1arr = arrayLength(ass1arr);
        (dstates1,states1) = checkAssignment(1,nass1arr,ass1arr,vars,{},{});
        assigend1 = Debug.bcallret2(List.isNotEmpty(assigned),List.intRange2,1,nassigned,{});
        nunassigned = nassigned+nunassigned;
        nassigned = nassigned+1;
        range = List.intRange2(nassigned,nunassigned);
        nv = BackendVariable.varsSize(vars);
        ne = BackendDAEUtil.equationSize(eqns);
        (varlst,stateSets) = selectDummyDerivatives2new(dstates1,states1,range,assigend1,vars,nv,eqns,ne,mapIncRowEqn1,level,iStateSets);
        dummyStates = List.map(varlst,BackendVariable.varCref);
        dummyStates = listAppend(inDummyStates,dummyStates);
        varlst = listAppend(varlst,inHov);
        // next set
        (varlst,dummyStates,stateSets) = processComps4New(sets,inVarSize,inEqnsSize,iVars,eqns1,inM,inMT,inMapEqnIncRow,inMapIncRowEqn,vec1,vec2,level,iShared,varlst,dummyStates,stateSets);
     then
        (varlst,dummyStates,stateSets);
  end matchcontinue;
end processComps4New;

protected function forceInlinEqn
  input tuple<DAE.Exp, DAE.FunctionTree> inTpl;
  output tuple<DAE.Exp, DAE.FunctionTree> outTpl;
protected
  DAE.Exp e;
  DAE.FunctionTree funcs;
algorithm
  (e,funcs) := inTpl;
  (e,_,_) := Inline.forceInlineExp(e,(SOME(funcs),{DAE.NORM_INLINE(),DAE.NO_INLINE()}),DAE.emptyElementSource);
  outTpl := (e,funcs);
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
  matchcontinue(iEqns,inMapEqnIncRow,inMapIncRowEqn,vec1,iVars,iEqnsArr,flag,n,iEqnsLst,iVarsLst,iAss1,iAss2)
    local
      Integer e,e1;
      list<Integer> rest,eqns,vindx,ass,ass1,ass2;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> varlst;
      BackendDAE.EquationArray eqnarr;
    case ({},_,_,_,_,_,_,_,_,_,_,_) then (iEqnsLst,iVarsLst,iAss1,iAss2,iEqnsArr);
    case (e::rest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = flag[e];
        true = intGt(vec1[e],0);
        e1 = inMapIncRowEqn[e];
        // print("BackendEquation.equationNth0 " +& intString(e1) +& "\n");
        eqn = BackendEquation.equationNth0(iEqnsArr,e1-1);
        eqnarr = BackendEquation.equationRemove(e1,iEqnsArr);
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
    case (e::rest,_,_,_,_,_,_,_,_,_,_,_)
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
        //  print("Seach for unassigned Eqns " +& stringDelimitList(List.map(eqns,intString),", ") +& "\n");
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
        // print("search in Rows " +& stringDelimitList(List.map(rows,intString),", ") +& " from " +& intString(e) +& "\n");
        (set,found) = getEqnsforDynamicStateSelectionRows(rows,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset,false);
        // print("add " +& boolString(found) +& " equation " +& intString(e) +& "\n");
        set = List.consOnTrue(found, e, set);
        _ = arrayUpdate(colummarks,e,Util.if_(found,mark,colummarks[e]));
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
        // print("check Row " +& intString(r) +& "\n");
        rc = ass2[r];
        // print("check Colum " +& intString(rc) +& "\n");
        false = intGt(rc,0);
        // print("Found free eqn " +& intString(rc) +& "\n");
        (set,b) = getEqnsforDynamicStateSelectionRows(rest,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset,true);
      then
        (set,b);
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        // print("check Row " +& intString(r) +& "\n");
        rc = ass2[r];
        // print("check Colum " +& intString(rc) +& "\n");
        true = intGt(rc,0);
        true = intEq(colummarks[rc],0);
        // if it is a multi dim equation take all scalare equations
        e = mapIncRowEqn[rc];
        eqns = mapEqnIncRow[e];
        _ = List.fold1r(eqns,arrayUpdate,Util.if_(iFound,mark,-mark),colummarks);
        // print("traverse Eqns " +& stringDelimitList(List.map(eqns,intString),", ") +& "\n");
        (set,b) = getEqnsforDynamicStateSelectionPhase(eqns,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset,false);
        eqns = Util.if_(b and not iFound,eqns,{});
        _ = List.fold1r(eqns,arrayUpdate,mark,colummarks);
        (set,b) = getEqnsforDynamicStateSelectionRows(rest,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,set,b or iFound);
      then
        (set,b);
    case (r::rest,_,_,_,_,_,_,_,_,_,_)
      equation
        // row is matched
        // print("check Row " +& intString(r) +& "\n");
        rc = ass2[r];
        // print("check Colum " +& intString(rc) +& "\n");
        true = intGt(rc,0);
        b = intGt(colummarks[rc],0);
        // print("Found " +& boolString(b) +& " equation " +& intString(rc) +& "\n");
        (set,b) = getEqnsforDynamicStateSelectionRows(rest,m,mT,mark,colummarks,ass1,ass2,mapEqnIncRow,mapIncRowEqn,inSubset,b or iFound);
      then
        (set,b);
  end matchcontinue;
end getEqnsforDynamicStateSelectionRows;

protected function setVarKind
  input tuple<BackendDAE.Var, BackendDAE.VarKind> inTpl;
  output tuple<BackendDAE.Var, BackendDAE.VarKind> outTpl;
protected
  BackendDAE.Var v;
  BackendDAE.VarKind kind;
algorithm
  (v,kind) := inTpl;
  v := BackendVariable.setVarKind(v,kind);
  outTpl := (v,kind);
end setVarKind;

protected function getFirstOrgEqns
"author: Frenkel TUD 2011-11
  returns the first equation of each orgeqn list."
  input BackendDAE.ConstraintEquations inOrgEqns;
  input BackendDAE.ConstraintEquations inOrgEqns1;
  input list<BackendDAE.Equation> inEqns;
  input list<Integer> inIndxs;
  output list<BackendDAE.Equation> outEqns;
  output list<Integer> outIndxs;
  output BackendDAE.ConstraintEquations outOrgEqns;
algorithm
  (outEqns,outIndxs,outOrgEqns) :=
  match (inOrgEqns,inOrgEqns1,inEqns,inIndxs)
    local
      BackendDAE.ConstraintEquations rest;
      BackendDAE.Equation eqn;
      Integer e;
      list<BackendDAE.Equation> orgeqn;
    case ({},_,_,_) then (inEqns,inIndxs,inOrgEqns1);
    case ((e,{eqn})::rest,_,_,_)
      equation
        (outEqns,outIndxs,outOrgEqns) = getFirstOrgEqns(rest,inOrgEqns1,eqn::inEqns,e::inIndxs);
      then
        (outEqns,outIndxs,outOrgEqns);
    case ((e,eqn::orgeqn)::rest,_,_,_)
      equation
        (outEqns,outIndxs,outOrgEqns) = getFirstOrgEqns(rest,(e,orgeqn)::inOrgEqns1,eqn::inEqns,e::inIndxs);
      then
        (outEqns,outIndxs,outOrgEqns);
  end match;
end getFirstOrgEqns;

protected function sortStateCandidatesVars
"author: Frenkel TUD 2012-08
  sort the state candidates"
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables allVars;
  input Option<BackendDAE.IncidenceMatrix> m;
  output BackendDAE.Variables outStates;
algorithm
  outStates:=
  matchcontinue (inVars,allVars,m)
    local
      Integer varsize;
      list<Integer> varIndices;
      BackendDAE.Variables vars;
      list<tuple<DAE.ComponentRef,Integer,Real>> prioTuples;
      list<BackendDAE.Var> vlst;

    case (_,_,_)
      equation
        varsize = BackendVariable.varsSize(inVars);
        prioTuples = calculateVarPriorities(1,inVars,varsize,allVars,m,{});
        prioTuples = List.sort(prioTuples,sortprioTuples);
        varIndices = List.map(prioTuples,Util.tuple32);
        vlst = List.map1r(varIndices,BackendVariable.getVarAt,inVars);
        vars = BackendVariable.listVar1(vlst);
      then vars;

    else
      equation
        print("Error, sortStateCandidatesVars failed!\n");
      then
        fail();

  end matchcontinue;
end sortStateCandidatesVars;

protected function sortprioTuples
"author: Frenkel TUD 2011-05
  helper for sortStateCandidates"
  input tuple<DAE.ComponentRef,Integer,Real> inTpl1;
  input tuple<DAE.ComponentRef,Integer,Real> inTpl2;
  output Boolean b;
algorithm
  b:= realGt(Util.tuple33(inTpl1),Util.tuple33(inTpl2));
end sortprioTuples;

protected function calculateVarPriorities
"author: Frenkel TUD 2012-08"
  input Integer index;
  input BackendDAE.Variables vars;
  input Integer varsSize;
  input BackendDAE.Variables allVars;
  input Option<BackendDAE.IncidenceMatrix> m;
  input list<tuple<DAE.ComponentRef,Integer,Real>> iTuples;
  output list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
algorithm
  tuples := matchcontinue(index,vars,varsSize,allVars,m,iTuples)
    local
      DAE.ComponentRef varCref;
      BackendDAE.Var v;
      Real prio,prio1,prio2;

    case (_,_,_,_,_,_)
      equation
        true = intLe(index,varsSize);
        v = BackendVariable.getVarAt(vars,index);
        varCref = BackendVariable.varCref(v);
        prio1 = varStateSelectPrio(v);
        prio2 = varStateSelectHeuristicPrio(v,allVars,index,m);
        prio = prio1 +. prio2;
        Debug.fcall(Flags.DUMMY_SELECT,BackendDump.debugStrCrefStrRealStrRealStrRealStr,("Calc Prio for ",varCref,"\n Prio StateSelect : ",prio1,"\n Prio Heuristik : ",prio2,"\n ### Prio Result : ",prio,"\n"));
      then
        calculateVarPriorities(index+1,vars,varsSize,allVars,m,(varCref,index,prio)::iTuples);
    else
      equation
        false = intLe(index,varsSize);
      then
        iTuples;
  end matchcontinue;
end calculateVarPriorities;

protected function varStateSelectHeuristicPrio
"author: Frenkel TUD 2012-08"
  input BackendDAE.Var v;
  input BackendDAE.Variables vars;
  input Integer index;
  input Option<BackendDAE.IncidenceMatrix> m;
  output Real prio;
protected
  Real prio1,prio2,prio3,prio4,prio5,prio6;
algorithm
  prio1 := varStateSelectHeuristicPrio1(v);
  prio2 := varStateSelectHeuristicPrio2(v);
  prio3 := varStateSelectHeuristicPrio3(v);
  prio4 := varStateSelectHeuristicPrio4(v,vars);
  prio5 := varStateSelectHeuristicPrio5(v);
  prio6 := varStateSelectHeuristicPrio6(v,index,m);
  prio:= prio1 +. prio2 +. prio3 +. prio4 +. prio5 +. prio6;
  printVarListtateSelectHeuristicPrio(prio1,prio2,prio3,prio4,prio5,prio6);
end varStateSelectHeuristicPrio;

protected function printVarListtateSelectHeuristicPrio
  input Real Prio1;
  input Real Prio2;
  input Real Prio3;
  input Real Prio4;
  input Real Prio5;
  input Real Prio6;
algorithm
  _ := matchcontinue(Prio1,Prio2,Prio3,Prio4,Prio5,Prio6)
    case(_,_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.DUMMY_SELECT);
        print("Prio 1 : " +& realString(Prio1) +& "\n");
        print("Prio 2 : " +& realString(Prio2) +& "\n");
        print("Prio 3 : " +& realString(Prio3) +& "\n");
        print("Prio 4 : " +& realString(Prio4) +& "\n");
        print("Prio 5 : " +& realString(Prio5) +& "\n");
        print("Prio 6 : " +& realString(Prio6) +& "\n");
      then
        ();
    else then ();
  end matchcontinue;
end printVarListtateSelectHeuristicPrio;

protected function varStateSelectHeuristicPrio6
"author: Frenkel TUD 2013-01
  Helper function to varStateSelectHeuristicPrio.
  added prio for states/variables, good state have much edges -> brackes loops"
  input BackendDAE.Var v;
  input Integer index;
  input Option<BackendDAE.IncidenceMatrix> om;
  output Real prio;
algorithm
  prio := match(v,index,om)
    local
      list<Integer> row;
      BackendDAE.IncidenceMatrix m;
    case(_,_,NONE()) then 0.0;
    case(_,_,SOME(m))
      equation
        row = m[index];
      then intReal(listLength(row));
  end match;
end varStateSelectHeuristicPrio6;

protected function varStateSelectHeuristicPrio5
"author: Frenkel TUD 2012-10
  Helper function to varStateSelectHeuristicPrio.
  added prio for states/variables, good if name is short"
  input BackendDAE.Var v;
  output Real prio;
protected
  DAE.ComponentRef cr;
  Integer d;
algorithm
  BackendDAE.VAR(varName=cr) := v;
  d := ComponentReference.crefDepth(cr);
  prio := realDiv(intReal(d),-10.0);
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
        ({v},_) = BackendVariable.getVar(cr, vars);
        b = BackendVariable.isDummyStateVar(v);
        prio = Util.if_(b,-1.0,3.0);
      then prio;
    else then 0.0;
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
      DAE.Ident id;
    case(BackendDAE.VAR(varName=cr))
      equation
        id = ComponentReference.crefFirstIdent(cr);
        true = stringEq(id,"$DER");
      then -100.0;
    else then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio3;

protected function varStateSelectHeuristicPrio2
"author: Frenkel TUD 2011-05
  Helper function to varStateSelectHeuristicPrio.
  added prio for variables with fixed = true "
  input BackendDAE.Var v;
  output Real prio;
algorithm
  prio := matchcontinue(v)
    case _
      equation
        true = BackendVariable.varFixed(v);
      then 3.0;
    else then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio2;

protected function varStateSelectHeuristicPrio1
"author: wbraun
  Helper function to varStateSelectHeuristicPrio.
  added prio for variables with a start value "
  input BackendDAE.Var v;
  output Real prio;
algorithm
  prio := matchcontinue(v)
    local
      DAE.Exp e;
    case _
      equation
        e = BackendVariable.varStartValueFail(v);
      then 1.0;
    else then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio1;

protected function varStateSelectPrio
"Helper function to calculateVarPriorities.
  Calculates a priority contribution bases on the stateSelect attribute."
  input BackendDAE.Var v;
  output Real prio;
  protected
  DAE.StateSelect ss;
algorithm
  ss := BackendVariable.varStateSelect(v);
  prio := varStateSelectPrio2(ss);
end varStateSelectPrio;

protected function varStateSelectPrio2
"helper function to varStateSelectPrio"
  input DAE.StateSelect ss;
  output Real prio;
algorithm
  prio := match(ss)
    case (DAE.NEVER()) then -10.0;
    case (DAE.AVOID()) then 0.0;
    case (DAE.DEFAULT()) then 10.0;
    case (DAE.PREFER()) then 50.0;
    case (DAE.ALWAYS()) then 100.0;
  end match;
end varStateSelectPrio2;

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
  matchcontinue(dstates,states,unassignedEqns,assignedEqns,vars,varSize,eqns,eqnsSize,mapIncRowEqn,level,iStateSets)
      local
        list<BackendDAE.Var> varlst,statecandidates,ovarlst;
        Integer unassignedEqnsSize,size,rang;
        list<BackendDAE.Equation> eqnlst,oeqnlst;
        list<Integer> unassignedEqns1,assignedEqns1;
    case(_,_,_,_,_,_,_,_,_,_,_)
      equation
        true = intEq(listLength(dstates),eqnsSize);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as States(1):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,dumpStates,"\n","\n")));
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(1):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,dumpStates,"\n","\n")));
      then
        ({},iStateSets);
    case(_,_,_,_,_,_,_,_,_,_,_)
      equation
        unassignedEqnsSize = listLength(unassignedEqns);
        size = listLength(states);
        rang = size-unassignedEqnsSize;
        true = intGt(rang,0);
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debugStrIntStrIntStr, ("Select ",rang," from ",size," States\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,dumpStates,"\n","\n")));
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(2):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((dstates,dumpStates,"\n","\n")));
        // collect information for stateset
        statecandidates = List.map1r(List.map(states,Util.tuple22),BackendVariable.getVarAt,vars);
        unassignedEqns1 = List.uniqueIntN(List.map1r(unassignedEqns,arrayGet,mapIncRowEqn), eqnsSize);
        eqnlst = BackendEquation.getEqns(unassignedEqns1, eqns);
        ovarlst = List.map1r(List.map(dstates,Util.tuple22),BackendVariable.getVarAt,vars);
        assignedEqns1 = List.uniqueIntN(List.map1r(assignedEqns,arrayGet,mapIncRowEqn), eqnsSize);
        oeqnlst = BackendEquation.getEqns(assignedEqns1, eqns);
        // add dummy states
        varlst = List.map1r(List.map(states,Util.tuple22),BackendVariable.getVarAt,vars);
      then
        (varlst,(level,rang,size,unassignedEqnsSize,statecandidates,eqnlst,ovarlst,oeqnlst)::iStateSets);
   // dummy derivative case - no dynamic state selection
   case(_,_,_,_,_,_,_,_,_,_,_)
      equation
        unassignedEqnsSize = listLength(unassignedEqns);
        size = listLength(states);
        rang = size-unassignedEqnsSize;
        true = intEq(rang,0);
        Debug.fcall(Flags.BLT_DUMP, print, ("Select as dummyStates(3):\n"));
        Debug.fcall(Flags.BLT_DUMP, BackendDump.debuglst,((states,dumpStates,"\n","\n")));
        // add dummy states
        varlst = List.map1r(List.map(states,Util.tuple22),BackendVariable.getVarAt,vars);
      then
        (varlst,iStateSets);
  end matchcontinue;
end selectDummyDerivatives2new;

protected function dumpDeterminants
"author: Frenkel TUD 2012-08"
  input tuple<DAE.Exp,list<Integer>> iTpl;
  output String s;
algorithm
  s := "Determinant: " +& stringDelimitList(List.map(Util.tuple22(iTpl),intString),", ") +& " \n" +& ExpressionDump.printExpStr(Util.tuple21(iTpl)) +& "\n";
end dumpDeterminants;

protected function makeder
"Author: Frenkel TUD 2012-09"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
protected
  DAE.Type tp;
algorithm
  tp := Expression.typeof(inExp);
  outExp := DAE.CALL(Absyn.IDENT("der"),{inExp},DAE.CALL_ATTR(tp,false,true,false,DAE.NO_INLINE(),DAE.NO_TAIL()));
end makeder;

protected function generateVar
"author: Frenkel TUD 2012-08"
  input DAE.ComponentRef cr;
  input BackendDAE.VarKind varKind;
  input DAE.Type varType;
  input DAE.InstDims subs;
  input Option<DAE.VariableAttributes> attr;
  output BackendDAE.Var var;
algorithm
  var := BackendDAE.VAR(cr,varKind,DAE.BIDIR(),DAE.NON_PARALLEL(),varType,NONE(),NONE(),subs,DAE.emptyElementSource,attr,NONE(),DAE.NON_CONNECTOR());
end generateVar;

protected function generateArrayVar
"author: Frenkel TUD 2012-08"
  input DAE.ComponentRef name;
  input BackendDAE.VarKind varKind;
  input DAE.Type varType;
  input Option<DAE.VariableAttributes> attr;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := match(name,varKind,varType,attr)
    local
      list<DAE.ComponentRef> crlst;
      BackendDAE.Var var;
      list<BackendDAE.Var> vars;
      DAE.Dimensions dims;
      list<Integer> ilst;
      DAE.InstDims subs;
      DAE.Type tp;
    case (_,_,DAE.T_ARRAY(ty=tp,dims=dims),_)
      equation
        crlst = ComponentReference.expandCref(name,false);
        ilst = Expression.dimensionsSizes(dims);
        subs = Expression.intSubscripts(ilst);
        // the rest not
        vars = List.map4(crlst,generateVar,varKind,tp,subs,NONE());
      then
        vars;
    case (_,_,_,_)
      equation
        var = BackendDAE.VAR(name,varKind,DAE.BIDIR(),DAE.NON_PARALLEL(),varType,NONE(),NONE(),{},DAE.emptyElementSource,attr,NONE(),DAE.NON_CONNECTOR());
      then
        {var};
  end match;
end generateArrayVar;

protected function getStateSetNames
"author: Frenkel TUD 2012-08"
  input list<DAE.ComponentRef> states;
  input Integer setsize;
  input Integer nUnassigned;
  output list<DAE.ComponentRef> crset;
  output DAE.ComponentRef setcr;
  output DAE.ComponentRef crcont;
  output list<BackendDAE.Var> ovars;
  output DAE.ComponentRef nosetcr;
  output BackendDAE.Var onosetvar;
  output DAE.ComponentRef ocrA;
  output list<BackendDAE.Var> ovarA;
  output DAE.ComponentRef ocrJ;
  output list<BackendDAE.Var> ovarJ;
algorithm
  (crset,setcr,crcont,ovars,nosetcr,onosetvar,ocrA,ovarA,ocrJ,ovarJ)  := matchcontinue(states,setsize,nUnassigned)
      local
        DAE.ComponentRef cr,cr1,set,cont,noset,crA,crJ;
        list<DAE.ComponentRef> crlst,crlst1;
        list<Boolean> blst;
        DAE.Type tp;
        Integer size;
        list<Integer> range;
        list<BackendDAE.Var> vars,varA,varJ;
        BackendDAE.Var vcont,nosetvar;
        DAE.VariableAttributes attr;
      case(_,_,_)
        equation
          cr::crlst1 = List.map(states,ComponentReference.crefStripLastSubs);
          blst = List.map1(crlst1,ComponentReference.crefEqualNoStringCompare,cr);
          true = Util.boolAndList(blst);
          size = listLength(states);
          tp = Util.if_(intEq(setsize,1),DAE.T_REAL_DEFAULT,DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(setsize)}, DAE.emptyTypeSource));
          cr = ComponentReference.crefSetLastType(cr, DAE.T_COMPLEX_DEFAULT);
          cr = ComponentReference.crefStripLastSubs(cr);
          set = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("set",tp,{}));
          cont = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("cond",DAE.T_INTEGER_DEFAULT,{}));
          noset = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("noset",tp,{}));
          range = List.intRange(setsize);
          crlst1 = Debug.bcallret3(intGt(setsize,1),List.map1r,range, ComponentReference.subscriptCrefWithInt, set,{set});
          vars = List.map4(crlst1,generateVar,BackendDAE.STATE(1,NONE()),DAE.T_REAL_DEFAULT,{},NONE());
          vars = List.map1(vars,BackendVariable.setVarFixed,false);
          vcont = generateVar(cont,BackendDAE.DISCRETE(),DAE.T_INTEGER_DEFAULT,{},SOME(DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),SOME(DAE.ICONST(size)),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())));
          nosetvar = generateVar(cont,BackendDAE.DISCRETE(),DAE.T_INTEGER_DEFAULT,{},SOME(DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),SOME(DAE.ICONST(size)),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())));
          tp = Util.if_(intGt(setsize,1),DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(setsize),DAE.DIM_INTEGER(size)}, DAE.emptyTypeSource),
                                         DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(size)}, DAE.emptyTypeSource));
          crA = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("A",tp,{}));
          varA = generateArrayVar(crA,BackendDAE.VARIABLE(),tp,NONE());
          tp = DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nUnassigned),DAE.DIM_INTEGER(size)}, DAE.emptyTypeSource);
          crJ = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("J",tp,{}));
          varJ = generateArrayVar(crJ,BackendDAE.PARAM(),tp,NONE());
        then
          (crlst1,set,cont,vcont::vars,noset,nosetvar,crA,varA,crJ,varJ);
      case(cr::crlst,_,_)
        equation
          cr = List.fold(crlst, ComponentReference.joinCrefs, cr);
          size = listLength(states);
          tp = Util.if_(intEq(setsize,1),DAE.T_REAL_DEFAULT,DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(setsize)}, DAE.emptyTypeSource));
          set = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("set",tp,{}));
          cont = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("cond",DAE.T_INTEGER_DEFAULT,{}));
          noset = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("noset",tp,{}));
          range = List.intRange(setsize);
          crlst1 = Debug.bcallret3(intGt(setsize,1),List.map1r,range,ComponentReference.subscriptCrefWithInt,set,{set});
          vars = List.map4(crlst1,generateVar,BackendDAE.STATE(1,NONE()),DAE.T_REAL_DEFAULT,{},NONE());
          vars = List.map1(vars,BackendVariable.setVarFixed,false);
          vcont = generateVar(cont,BackendDAE.DISCRETE(),DAE.T_INTEGER_DEFAULT,{},SOME(DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),SOME(DAE.ICONST(size)),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())));
          nosetvar = generateVar(cont,BackendDAE.DISCRETE(),DAE.T_INTEGER_DEFAULT,{},SOME(DAE.VAR_ATTR_INT(NONE(),(NONE(),NONE()),SOME(DAE.ICONST(size)),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())));
          tp = Util.if_(intGt(setsize,1),DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(setsize),DAE.DIM_INTEGER(size)}, DAE.emptyTypeSource),
                                         DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(size)}, DAE.emptyTypeSource));
          crA = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("A",tp,{}));
          varA = generateArrayVar(crA,BackendDAE.VARIABLE(),tp,NONE());
          tp = DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nUnassigned),DAE.DIM_INTEGER(size)}, DAE.emptyTypeSource);
          crJ = ComponentReference.joinCrefs(cr,ComponentReference.makeCrefIdent("J",tp,{}));
          varJ = generateArrayVar(crJ,BackendDAE.PARAM(),tp,NONE());
        then
          (crlst1,set,cont,vcont::vars,noset,nosetvar,crA,varA,crJ,varJ);
    end matchcontinue;
end getStateSetNames;

protected function notVarStateSelectAlways
"author: Frenkel TUD 2012-06
  fails if var is StateSelect.always"
  input BackendDAE.Var v;
  input Integer level;
algorithm
  _ := match(v,level)
    local Integer diffcount;
    case (BackendDAE.VAR(varKind=BackendDAE.STATE(index=diffcount),values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS())))),_)
      equation
        false = intEq(diffcount,level) or intEq(diffcount,1);
      then
        ();
    else then ();
  end match;
end notVarStateSelectAlways;

protected function varStateSelectAlways
"author: Frenkel TUD 2012-06
  return true if var is StateSelect.always else false"
  input BackendDAE.Var v;
  output Boolean b;
algorithm
  b := match(v)
    case BackendDAE.VAR(varKind=BackendDAE.STATE(index=_),values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS())))) then true;
    else then false;
  end match;
end varStateSelectAlways;

protected function incidenceMatrixfromEnhanced2
"author: Frenkel TUD 2012-11
  converts an AdjacencyMatrixEnhanced into a IncidenceMatrix"
  input BackendDAE.AdjacencyMatrixEnhanced me;
  input BackendDAE.Variables vars;
  output BackendDAE.IncidenceMatrix m;
algorithm
  m := Util.arrayMap1(me,incidenceMatrixElementfromEnhanced2,vars);
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
  input tuple<Integer, BackendDAE.Solvability> inTpl;
  input BackendDAE.Variables vars;
  input list<Integer> iRow;
  output list<Integer> oRow;
algorithm
  oRow := match(inTpl,vars,iRow)
    local Integer i;
    case ((i,BackendDAE.SOLVABILITY_SOLVED()),_,_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_CONSTONE()),_,_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_CONST()),_,_) then i::iRow;
    case ((i,BackendDAE.SOLVABILITY_PARAMETER(b=true)),_,_) then i::iRow;
//    case ((i,BackendDAE.SOLVABILITY_PARAMETER(b=false)),_,_) then incidenceMatrixElementElementfromEnhanced2_1(i,vars,iRow);
//    case ((i,BackendDAE.SOLVABILITY_TIMEVARYING(b=_)),_,_) then incidenceMatrixElementElementfromEnhanced2_1(i,vars,iRow);
//    case ((i,BackendDAE.SOLVABILITY_NONLINEAR()),_,_) then incidenceMatrixElementElementfromEnhanced2_1(i,vars,iRow);
//    case ((i,BackendDAE.SOLVABILITY_NONLINEAR()),_,_) then iRow;
    else then iRow;
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
  input Integer indx;
  input Integer len;
  input array<Integer> ass;
  input BackendDAE.Variables vars;
  input list<tuple<DAE.ComponentRef, Integer>> inAssigned;
  input list<tuple<DAE.ComponentRef, Integer>> inUnassigned;
  output list<tuple<DAE.ComponentRef, Integer>> outAssigned;
  output list<tuple<DAE.ComponentRef, Integer>> outUnassigned;
algorithm
  (outAssigned,outUnassigned) := matchcontinue(indx,len,ass,vars,inAssigned,inUnassigned)
    local
      Integer r;
      DAE.ComponentRef cr;
      list<tuple<DAE.ComponentRef, Integer>> assigend,unassigned;
    case (_,_,_,_,_,_)
      equation
        true = intGt(indx,len);
      then
        (inAssigned,inUnassigned);
    case (_,_,_,_,_,_)
      equation
        r = ass[indx];
        true = intGt(r,0);
        BackendDAE.VAR(varName=cr) = BackendVariable.getVarAt(vars,indx);
        (assigend,unassigned) =  checkAssignment(indx+1,len,ass,vars,(cr,indx)::inAssigned,inUnassigned);
      then
        (assigend,unassigned);
    case (_,_,_,_,_,_)
      equation
        BackendDAE.VAR(varName=cr) = BackendVariable.getVarAt(vars,indx);
        (assigend,unassigned) =  checkAssignment(indx+1,len,ass,vars,inAssigned,(cr,indx)::inUnassigned);
      then
        (assigend,unassigned);
  end matchcontinue;
end checkAssignment;

protected function selectDummyStates
"author: Frenkel TUD 2012-05
  selects the first nstates from states as dummy states"
  input list<tuple<DAE.ComponentRef, Integer>> states;
  input Integer i;
  input Integer nstates;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables hov;
  input BackendDAE.Variables inLov;
  input list<DAE.ComponentRef> inDummyStates;
  output BackendDAE.Variables outhov;
  output BackendDAE.Variables outlov;
  output list<DAE.ComponentRef> outDummyStates;
algorithm
  (outhov,outlov,outDummyStates) := matchcontinue(states,i,nstates,vars,hov,inLov,inDummyStates)
    local
      DAE.ComponentRef cr;
      Integer s;
      list<tuple<DAE.ComponentRef, Integer>> rest;
      BackendDAE.Variables hov1,lov;
      list<DAE.ComponentRef> dummystates;
      BackendDAE.Var v;
      case (_,_,_,_,_,_,_)
        equation
          true = intGt(i,nstates);
        then
          (hov,inLov,inDummyStates);
      case ((cr,s)::rest,_,_,_,_,_,_)
        equation
          v = BackendVariable.getVarAt(vars,s);
          hov1 = BackendVariable.removeCref(cr,hov);
          lov = BackendVariable.addVar(v,inLov);
         (hov1,lov, dummystates) = selectDummyStates(rest,i+1,nstates,vars,hov1,lov,cr::inDummyStates);
        then
          (hov1,lov, dummystates);
      case ((cr,s)::rest,_,_,_,_,_,_)
        equation
          print("selectDummyStates failed for " +& intString(s) +& " " +& ComponentReference.printComponentRefStr(cr) +& "\n");
          BackendDump.printVariables(vars);
          BackendDump.printVariables(hov);
        then
          fail();
  end matchcontinue;
end selectDummyStates;

protected function selectDummyStateVars
"author: Frenkel TUD 2012-09
  selects the states as dummy states"
  input list<BackendDAE.Var> states;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables hov;
  input BackendDAE.Variables inLov;
  input list<DAE.ComponentRef> inDummyStates;
  output BackendDAE.Variables outhov;
  output BackendDAE.Variables outlov;
  output list<DAE.ComponentRef> outDummyStates;
algorithm
  (outhov,outlov,outDummyStates) := matchcontinue(states,vars,hov,inLov,inDummyStates)
    local
      DAE.ComponentRef cr;
      Integer s;
      list<BackendDAE.Var> rest;
      BackendDAE.Variables hov1,lov;
      list<DAE.ComponentRef> dummystates;
      BackendDAE.Var v;
      case ({},_,_,_,_)
        then
          (hov,inLov,inDummyStates);
      case (v::rest,_,_,_,_)
        equation
          cr = BackendVariable.varCref(v);
          hov1 = BackendVariable.removeCref(cr,hov);
          lov = BackendVariable.addVar(v,inLov);
         (hov1,lov, dummystates) = selectDummyStateVars(rest,vars,hov1,lov,cr::inDummyStates);
        then
          (hov1,lov, dummystates);
  end matchcontinue;
end selectDummyStateVars;

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
      DAE.VariableAttributes dattr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var var;
      DAE.Exp e;
      Integer diffcount,n;
      Option<DAE.ComponentRef> derName;
   // state no derivative known
    case (BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE(index=diffcount,derName=NONE()),varDirection=dir,varParallelism=prl,varType=tp,arryDim=dim,source=source,comment=comment,connectorType=ct),_,_)
      equation
        true = intGt(diffcount,1);
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
        //kind = Util.if_(intGt(n,1),BackendDAE.DUMMY_DER(),BackendDAE.STATE(1,NONE()));
        var = BackendDAE.VAR(cr,BackendDAE.STATE(1,NONE()),dir,prl,tp,NONE(),NONE(),dim,source,odattr,comment,ct);
      then (var,ht);
   // state
    case (BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE(index=diffcount,derName=derName),varDirection=dir,varParallelism=prl,varType=tp,arryDim=dim,source=source,comment=comment,connectorType=ct),_,_)
      equation
        true = intGt(diffcount,1);
        var = BackendVariable.setVarKind(inVar, BackendDAE.STATE(1,derName));
      then (var,iHt);
    else then (inVar,iHt);
  end matchcontinue;
end getLevelStates;

protected function replaceHigherDerivatives
"author: Frenkel TUD 2013-01
  change for var:STATE(2): der(var,2) to der($DER.var), der(var) -> DER.var, add Var $DER.var:STATE(1)"
  input BackendDAE.EqSystem isyst;
  output BackendDAE.EqSystem osyst;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  Option<BackendDAE.IncidenceMatrix> om,omT;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets;
  HashTableCrIntToExp.HashTable ht;
  list<BackendDAE.Var> dummyvars;
  array<Integer> ass1,ass2;
  list<tuple<Integer,Integer>> addassign;
  Integer nv1,nv;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=om,mT=omT,matching=BackendDAE.MATCHING(ass1=ass1,ass2=ass2),stateSets=stateSets) := isyst;
  // traverse vars and generate dummy vars and replacement rules
  ht := HashTableCrIntToExp.emptyHashTable();
  nv := BackendVariable.varsSize(vars);
  (vars,(_,_,nv1,addassign,dummyvars,ht)) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars,makeHigherStatesRepl,(vars,1,nv,{},{},ht));
  // BaseHashTable.dumpHashTable(ht);
  // add dummy Vars;
  dummyvars := listReverse(dummyvars);
  vars := BackendVariable.addVars(dummyvars,vars);
  // perform replacement rules
  (vars,_) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars,replaceDummyDerivativesVar,ht);
  _ := BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(eqns,replaceDummyDerivatives,ht);
  // extend assignments
  ass1 := Util.arrayExpand(nv1-nv, ass1, -1);
  // set the new assignments
  List.map2_0(addassign,setHigerDerivativeAssignment,ass1,ass2);
  osyst := BackendDAE.EQSYSTEM(vars,eqns,om,omT,BackendDAE.MATCHING(ass1,ass2,{}),stateSets);
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
  input tuple<BackendDAE.Var,tuple<BackendDAE.Variables,Integer,Integer,list<tuple<Integer,Integer>>,list<BackendDAE.Var>,HashTableCrIntToExp.HashTable>> inTpl;
  output tuple<BackendDAE.Var,tuple<BackendDAE.Variables,Integer,Integer,list<tuple<Integer,Integer>>,list<BackendDAE.Var>,HashTableCrIntToExp.HashTable>> oTpl;
algorithm
  oTpl := matchcontinue inTpl
    local
      BackendDAE.Variables vars;
      HashTableCrIntToExp.HashTable ht;
      DAE.ComponentRef name,cr;
      BackendDAE.Var var;
      Integer diffcount,i,j;
      list<BackendDAE.Var> varlst;
      list<tuple<Integer,Integer>> addassign;
    // state diffed more than once
    case ((var as BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE(index=diffcount,derName=NONE())),(vars,i,j,addassign,varlst,ht)))
      equation
        true = intGt(diffcount,1);
        // dummy_der name
        cr = ComponentReference.crefPrefixDer(name);
        // add replacement for each derivative
        (varlst,ht,j) = makeHigherStatesRepl1(diffcount-2,2,name,cr,var,vars,varlst,ht,j);
      then
        ((var,(vars,i+1,j,(i,j)::addassign,varlst,ht)));
    case ((var,(vars,i,j,addassign,varlst,ht))) then ((var,(vars,i+1,j,addassign,varlst,ht)));
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
      DAE.VariableAttributes dattr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var var;
      list<BackendDAE.Var> vlst;
      DAE.Exp e;
      Integer n;
   // state no derivative known
    case (_,_,_,_,BackendDAE.VAR(varName=name,varDirection=dir,varParallelism=prl,varType=tp,arryDim=dim,source=source,comment=comment,connectorType=ct),_,_,_,_)
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
        kind = Util.if_(intGt(diffCount,0),BackendDAE.STATE(diffCount,NONE()),BackendDAE.DUMMY_DER());
        var = BackendDAE.VAR(name,kind,dir,prl,tp,NONE(),NONE(),dim,source,odattr,comment,ct);
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
  input BackendDAE.EqSystem isyst;
  input BackendDAE.StateOrder so;
  input HashTableCrIntToExp.HashTable iHt;
  output BackendDAE.EqSystem osyst;
  output HashTableCrIntToExp.HashTable oHt;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  Option<BackendDAE.IncidenceMatrix> om,omT;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets;
  list<BackendDAE.Var> dummvars;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=om,mT=omT,matching=matching,stateSets=stateSets) := isyst;
  // traverse vars and generate dummy vars and replacement rules
  (vars,(_,_,dummvars,oHt)) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars,makeAllDummyVarandDummyDerivativeRepl,(vars,so,{},iHt));
  // BaseHashTable.dumpHashTable(oHt);
  // add dummy Vars;
  vars := BackendVariable.addVars(dummvars,vars);
  // perform replacement rules
  (vars,_) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars,replaceDummyDerivativesVar,oHt);
  _ := BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(eqns,replaceDummyDerivatives,oHt);
  osyst := BackendDAE.EQSYSTEM(vars,eqns,om,omT,matching,stateSets);
end addAllDummyStates;

protected function makeAllDummyVarandDummyDerivativeRepl
"author: Frenkel TUD 2013-01
  This function creates a new variable named
  der+<varname> and adds it to the dae. The kind of the
  var with varname is changed to dummy_state"
  input tuple<BackendDAE.Var,tuple<BackendDAE.Variables,BackendDAE.StateOrder,list<BackendDAE.Var>,HashTableCrIntToExp.HashTable>> inTpl;
  output tuple<BackendDAE.Var,tuple<BackendDAE.Variables,BackendDAE.StateOrder,list<BackendDAE.Var>,HashTableCrIntToExp.HashTable>> oTpl;
algorithm
  oTpl := matchcontinue inTpl
    local
      BackendDAE.Variables vars;
      BackendDAE.StateOrder so;
      HashTableCrIntToExp.HashTable ht;
      DAE.ComponentRef name,cr;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      DAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      DAE.InstDims dim;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var var;
      Integer diffcount;
      list<BackendDAE.Var> varlst;
    // state with stateSelect.always, diffed once
    case ((var as BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE(index=diffcount),values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS())))),(vars,so,varlst,ht)))
      equation
        true = intEq(diffcount,1);
      then
        ((var,(vars,so,varlst,ht)));
    // state with stateSelect.always, diffed more than once, known derivative
    case ((var as BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE(derName=SOME(cr)),values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS())))),(vars,so,varlst,ht)))
      equation
        var = BackendVariable.setVarKind(var, BackendDAE.STATE(1,SOME(cr)));
      then
        ((var,(vars,so,varlst,ht)));
    // state with stateSelect.always, diffed more than once, unknown derivative
    case ((var as BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE(index=diffcount,derName=NONE()),values = SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS())))),(vars,so,varlst,ht)))
      equation
        // then replace not the highest state but the lower
        cr = ComponentReference.crefPrefixDer(name);
        // add replacement for each derivative
        (varlst,ht) = makeAllDummyVarandDummyDerivativeRepl1(diffcount-1,2,name,cr,var,vars,so,varlst,ht);
        var = BackendVariable.setVarKind(var, BackendDAE.STATE(1,NONE()));
      then
        ((var,(vars,so,varlst,ht)));
    // state, replaceable with known derivative
    case ((var as BackendDAE.VAR(name,BackendDAE.STATE(index=diffcount,derName=SOME(_)),dir,prl,tp,bind,value,dim,source,attr,comment,ct),(vars,so,varlst,ht)))
      equation
        // add replacement for each derivative
        (varlst,ht) = makeAllDummyVarandDummyDerivativeRepl1(1,1,name,name,var,vars,so,varlst,ht);
        cr = ComponentReference.crefPrefixDer(name);
        source = DAEUtil.addSymbolicTransformation(source,DAE.NEW_DUMMY_DER(cr,{}));
      then
        ((BackendDAE.VAR(name,BackendDAE.DUMMY_STATE(),dir,prl,tp,bind,value,dim,source,attr,comment,ct),(vars,so,varlst,ht)));
    // state replacable without unknown derivative
    case ((var as BackendDAE.VAR(name,BackendDAE.STATE(index=diffcount,derName=NONE()),dir,prl,tp,bind,value,dim,source,attr,comment,ct),(vars,so,varlst,ht)))
      equation
        // add replacement for each derivative
        (varlst,ht) = makeAllDummyVarandDummyDerivativeRepl1(diffcount,1,name,name,var,vars,so,varlst,ht);
        // dummy_der name vor Source information
        cr = ComponentReference.crefPrefixDer(name);
        source = DAEUtil.addSymbolicTransformation(source,DAE.NEW_DUMMY_DER(cr,{}));
      then
        ((BackendDAE.VAR(name,BackendDAE.DUMMY_STATE(),dir,prl,tp,bind,value,dim,source,attr,comment,ct),(vars,so,varlst,ht)));
    else then inTpl;
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
      DAE.VariableAttributes dattr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var var;
      list<BackendDAE.Var> vlst;
      DAE.Exp e;
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
    case (_,_,_,_,BackendDAE.VAR(varName=name,varDirection=dir,varParallelism=prl,varType=tp,arryDim=dim,source=source,comment=comment,connectorType=ct),_,_,_,_)
      equation
        name = ComponentReference.crefPrefixDer(iName);
        // generate replacement
        e = Expression.crefExp(name);
        ht = BaseHashTable.add(((iOrigName,diffedCount),e),iHt);
        // generate Dummy Var
        /* Dummy variables are algebraic variables without start value, min/max, .., hence fixed = false */
        dattr = BackendVariable.getVariableAttributefromType(tp);
        odattr = DAEUtil.setFixedAttr(SOME(dattr), SOME(DAE.BCONST(false)));
        var = BackendDAE.VAR(name,BackendDAE.DUMMY_DER(),dir,prl,tp,NONE(),NONE(),dim,source,odattr,comment,ct);
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
  input BackendDAE.EqSystem isyst;
  input HashTableCrIntToExp.HashTable iHt;
  output BackendDAE.EqSystem osyst;
  output HashTableCrIntToExp.HashTable oHt;
algorithm
  (osyst,oHt) :=
  match (dummyStates, level, repl, isyst, iHt)
    local
      HashTableCrIntToExp.HashTable ht;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      Option<BackendDAE.IncidenceMatrix> om,omT;
      BackendDAE.Matching matching;
      BackendDAE.StateSets stateSets;
    case ({},_,_,_,_) then (isyst,iHt);
    case (_,_,_,BackendDAE.EQSYSTEM(orderedVars=vars,orderedEqs=eqns,m=om,mT=omT,matching=matching,stateSets=stateSets),_)
      equation
        // create dummy_der vars and change deselected states to dummy states
        ((vars,ht)) = List.fold1(dummyStates,makeDummyVarandDummyDerivative,level,(vars,iHt));
        (vars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(vars,replaceDummyDerivativesVar,ht);
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(eqns,replaceDummyDerivatives,ht);
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(eqns,replaceFirstOrderDerivatives,repl);
      then
        (BackendDAE.EQSYSTEM(vars,eqns,om,omT,matching,stateSets),ht);
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
      DAE.VariableAttributes dattr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var dummy_state,dummy_derstate;
      Integer diffindex,dn;
      BackendDAE.VarKind kind;
      String msg;
    case (BackendDAE.VAR(varName=name,varKind=BackendDAE.STATE(index=diffindex),varDirection=dir,varParallelism=prl,varType=tp,arryDim=dim,source=source,comment=comment,connectorType=ct),_,(vars,ht))
      equation
        dn = intMax(diffindex-level,0);
        // generate names
        (name,dummyderName) = crefPrefixDerN(dn,name);
        source1 = DAEUtil.addSymbolicTransformation(source,DAE.NEW_DUMMY_DER(dummyderName,{}));
        /* Dummy variables are algebraic variables, hence fixed = false */
        dattr = BackendVariable.getVariableAttributefromType(tp);
        odattr = DAEUtil.setFixedAttr(SOME(dattr), SOME(DAE.BCONST(false)));
        dummy_derstate = BackendDAE.VAR(dummyderName,BackendDAE.DUMMY_DER(),dir,prl,tp,NONE(),NONE(),dim,source,odattr,comment,ct);
        kind = Util.if_(intEq(dn,0),BackendDAE.DUMMY_STATE(),BackendDAE.DUMMY_DER());
        dummy_state = BackendDAE.VAR(name,kind,dir,prl,tp,NONE(),NONE(),dim,source,odattr,comment,ct);
        dummy_state = Util.if_(intEq(dn,0),inVar,dummy_state);
        dummy_state = BackendVariable.setVarKind(dummy_state, kind);
        vars = BackendVariable.addVar(dummy_derstate, vars);
        vars = BackendVariable.addVar(dummy_state, vars);
        diffindex = dn+1;
        ht = BaseHashTable.add(((name,diffindex),Expression.crefExp(dummyderName)),ht);
      then
        ((vars,ht));
    else
      equation
        msg = "IndexReduction.makeDummyVarandDummyDerivative failed " +& BackendDump.varString(inVar) +& "!";
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
    case(_,_)
      equation
        dername = ComponentReference.crefPrefixDer(iName);
        (name,dername) = crefPrefixDerN(n-1,dername);
      then
        (name,dername);
  end matchcontinue;
end crefPrefixDerN;

protected function replaceFirstOrderDerivatives "author: Frenkel TUD 2013-01"
  input tuple<DAE.Exp,HashTable2.HashTable> itpl;
  output tuple<DAE.Exp,HashTable2.HashTable> outTpl;
protected
  DAE.Exp e;
  HashTable2.HashTable ht;
algorithm
  (e,ht) := itpl;
  outTpl := Expression.traverseExp(e,replaceFirstOrderDerivativesExp,ht);
end replaceFirstOrderDerivatives;

protected function replaceFirstOrderDerivativesExp "author: Frenkel TUD 2013-01"
  input tuple<DAE.Exp,HashTable2.HashTable> tpl;
  output tuple<DAE.Exp,HashTable2.HashTable> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      HashTable2.HashTable ht;
      DAE.Exp e;
      DAE.ComponentRef cr;
    case((DAE.CREF(componentRef=cr),ht))
      equation
        e = BaseHashTable.get(cr,ht);
      then
        ((e,ht));
    case _ then tpl;
  end matchcontinue;
end replaceFirstOrderDerivativesExp;

protected function replaceDummyDerivatives "author: Frenkel TUD 2012-08"
  input tuple<DAE.Exp,HashTableCrIntToExp.HashTable> itpl;
  output tuple<DAE.Exp,HashTableCrIntToExp.HashTable> outTpl;
protected
  DAE.Exp e;
  HashTableCrIntToExp.HashTable ht;
algorithm
  (e,ht) := itpl;
  outTpl := Expression.traverseExp(e,replaceDummyDerivativesExp,ht);
end replaceDummyDerivatives;

protected function replaceDummyDerivativesExp "author: Frenkel TUD 2012-08"
  input tuple<DAE.Exp,HashTableCrIntToExp.HashTable> tpl;
  output tuple<DAE.Exp,HashTableCrIntToExp.HashTable> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      HashTableCrIntToExp.HashTable ht;
      DAE.Exp e;
      DAE.ComponentRef cr;
      Integer i;
      String msg;
    case((DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr)}),ht))
      equation
        e = BaseHashTable.get((cr,1),ht);
      then
        ((e,ht));
    case((DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr),DAE.ICONST(i)}),ht))
      equation
        e = BaseHashTable.get((cr,i),ht);
      then
        ((e,ht));
    case((e as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst=_::_::_),ht))
      equation
        msg = "IndexReduction.replaceDummyDerivativesExp failed for " +& ExpressionDump.printExpStr(e) +& "!";
        Error.addMessage(Error.COMPILER_WARNING, {msg});
      then
        ((e,ht));
    case _ then tpl;
  end matchcontinue;
end replaceDummyDerivativesExp;

protected function replaceDummyDerivativesShared
"author Frenkel TUD 2012-08"
  input BackendDAE.Shared ishared;
  input HashTableCrIntToExp.HashTable ht;
  output BackendDAE.Shared oshared;
algorithm
  oshared:= match (ishared,ht)
    local
      BackendDAE.Variables knvars,exobj,knvars1;
      BackendDAE.Variables aliasVars;
      BackendDAE.EquationArray remeqns,inieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      Env.Cache cache;
      Env.Env env;
      DAE.FunctionTree funcTree;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.SymbolicJacobians symjacs;
      list<BackendDAE.WhenClause> whenClauseLst,whenClauseLst1;
      list<BackendDAE.ZeroCrossing> zeroCrossingLst, relationsLst, sampleLst;
      Integer numberOfRelations, numberOfMathEventFunctions;
      BackendDAE.BackendDAEType btp;
      list<BackendDAE.TimeEvent> timeEvents;
      BackendDAE.ExtraInfo ei;
      
    case (BackendDAE.SHARED(knvars,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcTree,BackendDAE.EVENT_INFO(timeEvents,whenClauseLst,zeroCrossingLst,sampleLst,relationsLst,numberOfRelations,numberOfMathEventFunctions),eoc,btp,symjacs,ei),_)
      equation
        // replace dummy_derivatives in knvars,aliases,ineqns,remeqns
        (aliasVars,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(aliasVars,replaceDummyDerivativesVar,ht);
        (knvars1,_) = BackendVariable.traverseBackendDAEVarsWithUpdate(knvars,replaceDummyDerivativesVar,ht);
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(inieqns,replaceDummyDerivatives,ht);
        _ = BackendDAEUtil.traverseBackendDAEExpsEqnsWithUpdate(remeqns,replaceDummyDerivatives,ht);
        (whenClauseLst1,_) = BackendDAETransform.traverseBackendDAEExpsWhenClauseLst(whenClauseLst,replaceDummyDerivatives,ht);
      then
        BackendDAE.SHARED(knvars1,exobj,aliasVars,inieqns,remeqns,constrs,clsAttrs,cache,env,funcTree,BackendDAE.EVENT_INFO(timeEvents,whenClauseLst1,zeroCrossingLst,sampleLst,relationsLst,numberOfRelations,numberOfMathEventFunctions),eoc,btp,symjacs,ei);
  
  end match;
end replaceDummyDerivativesShared;

protected function replaceDummyDerivativesVar
"author: Frenkel TUD 2012-08"
 input tuple<BackendDAE.Var, HashTableCrIntToExp.HashTable> inTpl;
 output tuple<BackendDAE.Var, HashTableCrIntToExp.HashTable> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v,v1;
      HashTableCrIntToExp.HashTable ht;
      DAE.Exp e,e1;
      Option<DAE.VariableAttributes> attr;

    case ((v as BackendDAE.VAR(bindExp=SOME(e),values=attr),ht))
      equation
        ((e1, _)) = Expression.traverseExp(e, replaceDummyDerivatives, ht);
        v1 = BackendVariable.setBindExp(v, SOME(e1));
        (attr,_) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,replaceDummyDerivatives,ht);
        v1 = BackendVariable.setVarAttributes(v1,attr);
      then ((v1,ht));

    case  ((v as BackendDAE.VAR(values=attr),ht))
      equation
        (attr,_) = BackendDAEUtil.traverseBackendDAEVarAttr(attr,replaceDummyDerivatives,ht);
        v1 = BackendVariable.setVarAttributes(v,attr);
      then ((v1,ht));
  end matchcontinue;
end replaceDummyDerivativesVar;

// protected function consArrayUpdate
//   input Boolean cond;
//   input array<Type_a> arr;
//   input Integer index;
//   input Type_a newValue;
//   output array<Type_a> oarr;
//   replaceable type Type_a subtypeof Any;
// algorithm
//   oarr := match(cond,arr,index,newValue)
//     case(true,_,_,_)
//       then
//         arrayUpdate(arr,index,newValue);
//     case(false,_,_,_) then arr;
//   end match;
// end consArrayUpdate;



public function splitEqnsinConstraintAndOther
"author: Frenkel TUD 2013-01
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
  (eqnslst,_) := BackendDAEOptimize.getScalarArrayEqns(inEqnsLst,{},false);
  eqns := BackendEquation.listEquation(eqnslst);
  syst := BackendDAE.EQSYSTEM(vars,eqns,NONE(),NONE(),BackendDAE.NO_MATCHING(),{});
  (me,_,mapEqnIncRow,mapIncRowEqn) := BackendDAEUtil.getAdjacencyMatrixEnhancedScalar(syst, shared);
  m := incidenceMatrixfromEnhanced2(me,vars);
  // match the equations, umatched are constrained equations
  nv := BackendVariable.varsSize(vars);
  ne := BackendDAEUtil.equationSize(eqns);
  vec1 := arrayCreate(nv,-1);
  vec2 := arrayCreate(ne,-1);
  Matching.matchingExternalsetIncidenceMatrix(nv,ne,m);
  BackendDAEEXT.matching(nv,ne,5,-1,1.0,1);
  BackendDAEEXT.getAssignment(vec2,vec1);
  unassigned := Matching.getUnassigned(ne, vec2, {});
  assigned := Matching.getAssigned(ne, vec2, {});
  unassigned := List.map1r(unassigned,arrayGet,mapIncRowEqn);
  unassigned := List.uniqueIntN(unassigned, ne);
  outCEqnsLst := BackendEquation.getEqns(unassigned, eqns);
  assigned := List.map1r(assigned,arrayGet,mapIncRowEqn);
  assigned := List.uniqueIntN(assigned, ne);
  outOEqnsLst := BackendEquation.getEqns(assigned, eqns);
end splitEqnsinConstraintAndOther;

/*****************************************
 calculation of the determinant of a square matrix .
 *****************************************/
/*
public function tryDeterminant
"author: Frenkel TUD 2012-06"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  (outDAE,_) := BackendDAEUtil.mapEqSystemAndFold(inDAE,tryDeterminant0,false);
end tryDeterminant;

protected function tryDeterminant0
"author: Frenkel TUD 2012-06"
  input BackendDAE.EqSystem isyst;
  input tuple<BackendDAE.Shared,Boolean> sharedChanged;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared,Boolean> osharedChanged;
algorithm
  (osyst,osharedChanged) :=
    matchcontinue(isyst,sharedChanged)
    local
      BackendDAE.StrongComponents comps;
      Boolean b,b1,b2;
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;

    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),(shared, b1))
      equation
         BackendDump.printEqSystem(syst);
         (m,mt) = BackendDAEUtil.incidenceMatrix(syst,BackendDAE.NORMAL(),NONE());
         BackendDump.dumpIncidenceMatrixT(mt);

         SOME(jac) = BackendDAEUtil.calculateJacobian(vars, eqns, m, true,shared);
         jac = listReverse(jac);
         print("Jac:\n" +& BackendDump.dumpJacobianStr(SOME(jac)) +& "\n");

         // generate Determinant
         // base is jacobian of the system
         determinant(jac,BackendDAEUtil.systemSize(syst));

      then
        (syst,(shared,false));
  end matchcontinue;
end tryDeterminant0;
*/

public function determinant
"author: Frenkel TUD 2012-06"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input Integer size;
protected
  array<list<tuple<Integer,DAE.Exp>>> digraph;
  array<Integer> nodemark;
  array<Integer> visited;
  list<tuple<list<DAE.Exp>,Integer>> zycles;
  DAE.Exp det;
algorithm
  digraph := arrayCreate(size,{});
  digraph := getDeterminantDigraph(jac,digraph);
  dumpDigraph(digraph);
  // for node 1 do
  // traverse all edges
  // count edges, remember last start node, remember visited nodes
  nodemark := arrayCreate(size,-1);
  visited := arrayCreate(size,-1);

  _ := arrayUpdate(visited,1,1);
  print("Starte Determinantenberechnung mit 1. Node\n");
  zycles := determinantEdges(digraph[1],size,1,{1},{},1,1,digraph,{});
  dumpzycles(zycles,size);
  det := determinantfromZycles(zycles,size,DAE.RCONST(0.0));
  print("Determinant: \n" +& ExpressionDump.printExpStr(det) +& "\n");
end determinant;

protected function determinantfromZycles
"author: Frenkel TUD 2012-06"
  input list<tuple<list<DAE.Exp>,Integer>> zycles;
  input Integer size;
  input DAE.Exp iExp;
  output DAE.Exp oExp;
algorithm
  oExp := matchcontinue(zycles,size,iExp)
    local
      Integer d;
      Real sign;
      DAE.Exp e;
      list<DAE.Exp> elst;
      list<tuple<list<DAE.Exp>,Integer>> rest;
    case({},_,_)
      equation
        (e,_) = ExpressionSimplify.simplify(iExp);
      then
        e;
    case((elst,d)::rest,_,_)
      equation
        sign = realPow(-1.0,intReal(size-d));
        e = List.fold(elst, Expression.expMul, DAE.RCONST(sign));
        //(e,_) = ExpressionSimplify.simplify(e);
        e = Expression.expAdd(iExp,e);
      then
        determinantfromZycles(rest,size,e);
  end matchcontinue;
end determinantfromZycles;

protected function dumpDigraph
"author: Frenkel TUD"
  input array<list<tuple<Integer,DAE.Exp>>> digraph;
protected
  Integer len;
  String len_str;
  list<list<tuple<Integer,DAE.Exp>>> g;
algorithm
  print("Digraph\n");
  print("====================================\n");
  len := arrayLength(digraph);
  len_str := intString(len);
  print("number of rows: ");
  print(len_str);
  print("\n");
  g := arrayList(digraph);
  dumpDigraph1(g,1);
end dumpDigraph;

protected function dumpDigraph1
"author: Frenkel TUD 2012-06"
  input list<list<tuple<Integer,DAE.Exp>>> inIntegerLstLst;
  input Integer rowIndex;
algorithm
  _ := match (inIntegerLstLst,rowIndex)
    local
      list<tuple<Integer,DAE.Exp>> row;
      list<list<tuple<Integer,DAE.Exp>>> rows;
    case ({},_) then ();
    case ((row :: rows),_)
      equation
        print(intString(rowIndex));print(":");
        dumpDigraph2(row);
        dumpDigraph1(rows,rowIndex+1);
      then ();
  end match;
end dumpDigraph1;

public function dumpDigraph2
"author: Frenkel TUD 2012-06"
  input list<tuple<Integer,DAE.Exp>> inIntegerLst;
algorithm
  _ := match (inIntegerLst)
    local
      String s;
      Integer x;
      DAE.Exp e;
      list<tuple<Integer,DAE.Exp>> xs;
    case ({})
      equation
        print("\n");
      then
        ();
    case (((x,e) :: xs))
      equation
        s = intString(x);
        print(s);
        print(" ");
        print(ExpressionDump.printExpStr(e));
        print(" ");
        dumpDigraph2(xs);
      then
        ();
  end match;
end dumpDigraph2;

protected function getUnvisitedNode
"author: Frenkel TUD 2012-06
  returns the first unvisited node"
  input Integer index;
  input Integer size;
  input list<Integer> zycle;
  output Integer node;
algorithm
  node := matchcontinue(index,size,zycle)
    case(_,_,_)
      equation
        false = intGt(index,size);
        false = listMember(index,zycle);
      then
        index;
    case(_,_,_)
      equation
        false = intGt(index,size);
      then
        getUnvisitedNode(index+1,size,zycle);
  end matchcontinue;
end getUnvisitedNode;

protected function determinantEdges
"author: Frenkel TUD 2012-06
  traverse each edge and call determinantNode"
  input list<tuple<Integer,DAE.Exp>> edges;
  input Integer size;
  input Integer length;
  input list<Integer> zycle;
  input list<DAE.Exp> ezycle;
  input Integer subzycles;
  input Integer startNode;
  input array<list<tuple<Integer,DAE.Exp>>> digraph;
  input list<tuple<list<DAE.Exp>,Integer>> izycles;
  output list<tuple<list<DAE.Exp>,Integer>> ozycles;
algorithm
  ozycles := matchcontinue(edges,size,length,zycle,ezycle,subzycles,startNode,digraph,izycles)
    local
      Integer edge,nextnode;
      DAE.Exp e;
      list<tuple<Integer,DAE.Exp>> rest;
      list<tuple<list<DAE.Exp>,Integer>> zycles;
    case({},_,_,_,_,_,_,_,_) then izycles;
    case((edge,e)::rest,_,_,_,_,_,_,_,_)
      equation
        //print("Check edge:" +& intString(edge) +& " startNode " +& intString(startNode) +& " length " +& intString(length) +& "\n");
        // back at the start node of the cycle?
        true = intEq(edge,startNode);
        // a full cycle?
        true = intEq(size,length);
        // return zicle
        //print("Voller Zyklus gefunden: d:" +& intString(subzycles) +& "\n");
        //BackendDump.debuglst((e::ezycle,ExpressionDump.printExpStr,", ","\n"));
      then
        (e::ezycle,subzycles)::izycles;
    case((edge,e)::rest,_,_,_,_,_,_,_,_)
      equation
        // back at the start node of the cycle?
        true = intEq(edge,startNode);
        // not a full cycle?
        false = intGt(length,size);
        // get next unvisited node
        nextnode = getUnvisitedNode(1,size,zycle);
        //print("unvollstaendiger Zyklus gefunden: d:" +& intString(subzycles) +& " fahre mit Node " +& intString(nextnode) +& " fort\n");
        zycles = determinantEdges(digraph[nextnode],size,length+1,nextnode::zycle,e::ezycle,subzycles+1,nextnode,digraph,izycles);
      then
        determinantEdges(rest,size,length,zycle,ezycle,subzycles,startNode,digraph,zycles);
    case((edge,e)::rest,_,_,_,_,_,_,_,_)
      equation
        // not a full cycle?
        false = intGt(length,size);
        // not allready visited
        false = listMember(edge,zycle);
        //print("fahre mit Node " +& intString(edge) +& " fort\n");
        zycles = determinantEdges(digraph[edge],size,length+1,edge::zycle,e::ezycle,subzycles,startNode,digraph,izycles);
      then
        determinantEdges(rest,size,length,zycle,ezycle,subzycles,startNode,digraph,zycles);
    case((edge,_)::rest,_,_,_,_,_,_,_,_)
      equation
        // not a full cycle?
        false = intGt(length,size);
      then
        determinantEdges(rest,size,length,zycle,ezycle,subzycles,startNode,digraph,izycles);
  end matchcontinue;
end determinantEdges;


// protected function dumpZycle
//   input tuple<Integer,DAE.Exp> inTpl;
//   output String s;
// algorithm
//   s := intString(Util.tuple21(inTpl)) +& ":" +& ExpressionDump.printExpStr(Util.tuple22(inTpl));
// end dumpZycle;

protected function getDeterminantDigraph
"author: Frenkel TUD 2012-06
  generate the digraph edges by {jac= list of (i,j,Eqn)} directed edge from j to i"
  input list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
  input array<list<tuple<Integer,DAE.Exp>>> iDigraph;
  output array<list<tuple<Integer,DAE.Exp>>> oDigraph;
algorithm
  oDigraph := matchcontinue(jac,iDigraph)
    local
      Integer i,j;
      DAE.Exp e;
      list<tuple<Integer,DAE.Exp>> ilst;
      list<tuple<Integer, Integer, BackendDAE.Equation>> rest;
      array<list<tuple<Integer,DAE.Exp>>> digraph;
    case({},_) then iDigraph;
    case((i,j,BackendDAE.RESIDUAL_EQUATION(exp = e))::rest,_)
      equation
        ilst = iDigraph[j];
        digraph = arrayUpdate(iDigraph,j,(i,e)::ilst);
      then
        getDeterminantDigraph(rest,digraph);
  end matchcontinue;
end getDeterminantDigraph;

protected function dumpzycles
"author: Frenkel TUD 2012-06"
  input list<tuple<list<DAE.Exp>,Integer>> zycles;
  input Integer size;
algorithm
  _ := matchcontinue(zycles,size)
    local
      Integer d;
      Real sign;
      list<DAE.Exp> elst;
      list<tuple<list<DAE.Exp>,Integer>> rest;
    case({},_) then ();
    case((elst,d)::rest,_)
      equation
        sign = realPow(-1.0,intReal(size-d));
        print("d:" +& intString(d) +& " : " +& realString(sign) +& "*");
        BackendDump.debuglst((elst,ExpressionDump.printExpStr,"*","\n"));
        dumpzycles(rest,size);
      then
        ();
  end matchcontinue;
end dumpzycles;

protected function changeDerVariablestoStates
"author: Frenkel TUD 2011-05
  change the kind of all variables in a der to state"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrixT>> inTpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrixT>> outTpl;
protected
  DAE.Exp e;
  tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrixT> vars;
algorithm
  (e,vars) := inTpl;
  outTpl := Expression.traverseExp(e,changeDerVariablestoStatesFinderNew,vars);
end changeDerVariablestoStates;

protected function changeDerVariablestoStatesFinderNew
"author: Frenkel TUD 2011-05
  helper for changeDerVariablestoStates"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrix>> inExp;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrixT>> outExp;
algorithm
  (outExp) := match (inExp)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
      BackendDAE.Variables vars;
      list<Integer> ilst,changedVars;
      list<BackendDAE.Var> varlst;
      array<Integer> mapIncRowEqn;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.EquationArray eqns;
      BackendDAE.StateOrder so;
      Integer index,eindx;
     /* der(var), change algebraic to states */
     case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)))
      equation
        (varlst,changedVars) = BackendVariable.getVar(cr,vars);
        (vars,ilst) = algebraicState(varlst,changedVars,vars,ilst);
      then
        ((e, (vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)));
    /* der(der(var)), set differentiation counter = 2 */
    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {e as DAE.CREF(componentRef = cr)})}),(vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)))
      equation
        (varlst,changedVars) = BackendVariable.getVar(cr,vars);
        (vars,ilst) = increaseDifferentiation(varlst,changedVars,2,vars,ilst);
      then
        ((DAE.CALL(Absyn.IDENT("der"),{e,DAE.ICONST(2)},DAE.callAttrBuiltinReal), (vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)));
    /* der(var,index), set differentiation counter = index+1 */
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr),DAE.ICONST(index)}),(vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)))
      equation
        (varlst,changedVars) = BackendVariable.getVar(cr,vars);
        (vars,ilst) = increaseDifferentiation(varlst,changedVars,index,vars,ilst);
      then
        ((e, (vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)));
    case _ then inExp;
  end match;
end changeDerVariablestoStatesFinderNew;

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
    case((v as BackendDAE.VAR(varKind = BackendDAE.STATE(index=_)))::vlst,index::ilst,_,_)
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
      Option<Values.Value> v;
      list<DAE.Subscript> dim;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      BackendDAE.Var var;
      BackendDAE.Variables vars;
      Integer diffcounter;
      Boolean b;
      Integer i;
      list<Integer> ilst,changedVars;
      list<BackendDAE.Var> vlst;
    case ({},_,_,_,_) then (inVars,iChangedVars);
    case (BackendDAE.VAR(varName = cr,
              varKind = BackendDAE.STATE(diffcounter,dcr),
              varDirection = dir,
              varParallelism = prl,
              varType = tp,
              bindExp = bind,
              bindValue = v,
              arryDim = dim,
              source = source,
              values = attr,
              comment = comment,
              connectorType = ct)::vlst,i::ilst,_,_,_)
    equation
      b = intGt(counter,diffcounter);
      diffcounter = Util.if_(b, counter, diffcounter);
      var = BackendDAE.VAR(cr, BackendDAE.STATE(diffcounter,dcr), dir, prl, tp, bind, v, dim, source, attr, comment, ct);
      vars = Debug.bcallret2(b, BackendVariable.addVar, var, inVars, inVars);
      changedVars = List.consOnTrue(b,i,iChangedVars);
      (vars,ilst) = increaseDifferentiation(vlst,ilst,counter,vars,changedVars);
    then
      (vars,ilst);
   else
     equation
       print("IndexReduction.setVarKind failt because of wrong input:\n");
       BackendDump.printVar(listGet(inVarLst,1));
     then
       fail();
  end match;
end increaseDifferentiation;

protected function changeDerVariablestoStatesFinder
"author: Frenkel TUD 2011-05
  helper for changeDerVariablestoStates"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrix>> inExp;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>,Integer,array<Integer>,BackendDAE.IncidenceMatrixT>> outExp;
algorithm
  (outExp) := matchcontinue (inExp)
    local
      DAE.Exp e;
      BackendDAE.Variables vars,vars_1;
      DAE.VarDirection a;
      DAE.VarParallelism prl;
      BackendDAE.Type b;
      Option<DAE.Exp> c;
      Option<DAE.ComponentRef> dcr;
      Option<Values.Value> d;
      Integer g,si1,si2;
      DAE.ComponentRef dummyder,cr;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      list<DAE.Subscript> lstSubs;
      Integer i,eindx,diffindex;
      list<Integer> ilst,changedVars;
      Option<DAE.Exp> quantity,unit,displayUnit,startOrigin;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> min;
      Option<DAE.Exp> initial_,fixed,nominal,equationBound;
      Option<Boolean> isProtected;
      Option<Boolean> finalPrefix;
      BackendDAE.EquationArray eqns,eqns_1;
      BackendDAE.StateOrder so,so1;
      Option<DAE.Uncertainty> unc;
      Option<DAE.Distribution> distribution;
      BackendDAE.Var v,v1;
      Boolean nostate,lessstateselect;
      array<Integer> mapIncRowEqn;
      BackendDAE.IncidenceMatrixT mt;
      list<BackendDAE.Var> varlst;
      DAE.StateSelect s1,s2;
/*     case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),(vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)))
      equation
        dummyder = getStateOrder(cr,so);
        (v::{},i::_) = BackendVariable.getVar(dummyder,vars);
        nostate = not BackendVariable.isStateVar(v);
        v = Debug.bcallret2(nostate,BackendVariable.setVarKind,v, BackendDAE.STATE(index=_), v);
        vars_1 = Debug.bcallret2(nostate, BackendVariable.addVar,v, vars,vars);
        e = Expression.crefExp(dummyder);
        ilst = List.consOnTrue(nostate, i, ilst);
      then
        ((DAE.CALL(Absyn.IDENT("der"),{e},DAE.callAttrBuiltinReal), (vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)));
*/
    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),(vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)))
      equation
        ((BackendDAE.VAR(cr,BackendDAE.STATE(diffindex,dcr),a,prl,b,c,d,lstSubs,source,dae_var_attr,comment,ct) :: {}),i::_) = BackendVariable.getVar(cr, vars) "der(der(s)) s is state => der_der_s" ;
        // do not use the normal derivative prefix for the name
        //dummyder = ComponentReference.crefPrefixDer(cr);
        dummyder = ComponentReference.makeCrefQual("$_DER",DAE.T_REAL_DEFAULT,{},cr);
        (eqns_1,so1) = addDummyStateEqn(vars,eqns,cr,dummyder,so,i,eindx,mapIncRowEqn,mt);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.STATE(1,dcr), a, prl, b, NONE(), NONE(), lstSubs, source, NONE(), comment, ct), vars);
        e = Expression.makeCrefExp(dummyder,DAE.T_REAL_DEFAULT);
      then
        ((DAE.CALL(Absyn.IDENT("der"),{e},DAE.callAttrBuiltinReal), (vars_1,eqns_1,so1,i::ilst,eindx,mapIncRowEqn,mt)));

    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,changedVars,eindx,mapIncRowEqn,mt)))
      equation
        (varlst as _::_,ilst) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        (vars_1,changedVars) = changeDerVariablestoStates1(varlst,ilst,vars,changedVars);
      then
        ((e, (vars_1,eqns,so,changedVars,eindx,mapIncRowEqn,mt)));
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)))
      equation
        (v::_,i::_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        print("wrong Variable in der: \n");
        BackendDump.debugExpStr((e,"\n"));
      then
        ((e, (vars,eqns,so,ilst,eindx,mapIncRowEqn,mt)));

    case _ then inExp;

  end matchcontinue;
end changeDerVariablestoStatesFinder;

protected function changeDerVariablestoStates1
  input list<BackendDAE.Var> varlst;
  input list<Integer> indxs;
  input BackendDAE.Variables inVars;
  input list<Integer> inChangedVars;
  output BackendDAE.Variables outVars;
  output list<Integer> outChangedVars;
algorithm
  (outVars,outChangedVars) := matchcontinue(varlst,indxs,inVars,inChangedVars)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> rest;
      Integer i;
      list<Integer> ilst;
      BackendDAE.Variables vars;
    case ({},_,_,_) then (inVars,inChangedVars);
    case ((v as BackendDAE.VAR(varKind=BackendDAE.VARIABLE()))::rest,i::ilst,_,_)
      equation
        v = BackendVariable.setVarKind(v,BackendDAE.STATE(1,NONE()));
        // v = BackendVariable.setVarStateSelect(v,DAE.AVOID());
        vars = BackendVariable.addVar(v,inVars);
        (outVars,outChangedVars) = changeDerVariablestoStates1(rest,ilst,vars,i::inChangedVars);
      then
        (outVars,outChangedVars);
    case ((v as BackendDAE.VAR(varKind=BackendDAE.DUMMY_STATE()))::rest,i::ilst,_,_)
      equation
        v = BackendVariable.setVarKind(v,BackendDAE.STATE(1,NONE()));
        vars = BackendVariable.addVar(v,inVars);
        (outVars,outChangedVars) = changeDerVariablestoStates1(rest,ilst,vars,i::inChangedVars);
      then
        (outVars,outChangedVars);
    case ((v as BackendDAE.VAR(varKind=BackendDAE.DUMMY_DER()))::rest,i::ilst,_,_)
      equation
        v = BackendVariable.setVarKind(v,BackendDAE.STATE(1,NONE()));
        vars = BackendVariable.addVar(v,inVars);
        (outVars,outChangedVars) = changeDerVariablestoStates1(rest,ilst,vars,i::inChangedVars);
      then
        (outVars,outChangedVars);
    case (BackendDAE.VAR(varKind=BackendDAE.STATE(index=_))::rest,i::ilst,_,_)
      equation
        (outVars,outChangedVars) = changeDerVariablestoStates1(rest,ilst,inVars,inChangedVars);
      then
        (outVars,outChangedVars);
  end matchcontinue;
end changeDerVariablestoStates1;

protected function addDummyStateEqn
"author: Frenkel TUD 2011-05
  helper for changeDerVariablestoStatesFinder"
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input DAE.ComponentRef inCr;
  input DAE.ComponentRef inDCr;
  input BackendDAE.StateOrder inSo;
  input Integer i;
  input Integer eindx;
  input array<Integer> mapIncRowEqn;
  input BackendDAE.IncidenceMatrixT mt;
  output BackendDAE.EquationArray outEqns;
  output BackendDAE.StateOrder outSo;
algorithm
  (outEqns,outSo) := matchcontinue (inVars,inEqns,inCr,inDCr,inSo,i,eindx,mapIncRowEqn,mt)
    local
      BackendDAE.EquationArray eqns1;
      DAE.Exp ecr,edcr,c;
      BackendDAE.StateOrder so;
      list<Integer> eqnindxs;
    case (_,_,_,_,_,_,_,_,_)
      equation
        (_::_,_::_) = BackendVariable.getVar(inDCr, inVars);
      then
        (inEqns,inSo);
    case (_,_,_,_,_,_,_,_,_)
      equation
        ecr = Expression.makeCrefExp(inCr,DAE.T_REAL_DEFAULT);
        edcr = Expression.makeCrefExp(inDCr,DAE.T_REAL_DEFAULT);
        c = DAE.CALL(Absyn.IDENT("der"),{ecr},DAE.callAttrBuiltinReal);
        eqns1 = BackendEquation.equationAdd(BackendDAE.EQUATION(edcr,c,DAE.emptyElementSource,false),inEqns);
        so = addStateOrder(inCr,inDCr,inSo);
        eqnindxs = List.map(mt[i], intAbs);
        // get from scalar eqns indexes the indexes in the equation array
        eqnindxs = List.map1r(eqnindxs,arrayGet,mapIncRowEqn);
        eqnindxs = List.removeOnTrue(eindx,intEq,List.unique(eqnindxs));
        eqns1 = replaceAliasState(eqnindxs,ecr,edcr,inCr,eqns1);
      then
        (eqns1,so);
  end matchcontinue;
end addDummyStateEqn;

protected function debugdifferentiateEqns
  input tuple<BackendDAE.Equation,BackendDAE.Equation> inTpl;
protected
  BackendDAE.Equation a,b;
algorithm
  (a,b) := inTpl;
  print("High index problem, differentiated equation:\n" +& BackendDump.equationString(a) +& "\nto\n" +& BackendDump.equationString(b) +& "\n");
end debugdifferentiateEqns;

protected function getSetVars
"author: Frenkel TUD 2012-12"
  input Integer index;
  input Integer setsize;
  input Integer nStates;
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
  set := ComponentReference.makeCrefIdent("$STATESET" +& intString(index),DAE.T_COMPLEX_DEFAULT,{});
  tp := Util.if_(intGt(setsize,1),DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(setsize)}, DAE.emptyTypeSource),DAE.T_REAL_DEFAULT);
  crstates := ComponentReference.joinCrefs(set,ComponentReference.makeCrefIdent("x",tp,{}));
  oSetVars := generateArrayVar(crstates,BackendDAE.STATE(1,NONE()),tp,NONE());
  oSetVars := List.map1(oSetVars,BackendVariable.setVarFixed,false);
  crset := List.map(oSetVars,BackendVariable.varCref);
  tp := Util.if_(intGt(setsize,1),DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(setsize),DAE.DIM_INTEGER(nStates)}, DAE.emptyTypeSource),
                                 DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(nStates)}, DAE.emptyTypeSource));
  realtp := Util.if_(intGt(setsize,1),DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(setsize),DAE.DIM_INTEGER(nStates)}, DAE.emptyTypeSource),
                                 DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nStates)}, DAE.emptyTypeSource));
  ocrA := ComponentReference.joinCrefs(set,ComponentReference.makeCrefIdent("A",tp,{}));
  oAVars := generateArrayVar(ocrA,BackendDAE.VARIABLE(),tp,NONE());
  oAVars := List.map1(oAVars,BackendVariable.setVarFixed,true);
  // add start value A[i,j] = if i==j then 1 else 0 via initial equations
  oAVars := List.map1(oAVars,BackendVariable.setVarStartValue,DAE.ICONST(0));
  oAVars := setSetAStart(oAVars,1,1,setsize,{});
  tp := Util.if_(intGt(nCEqns,1),DAE.T_ARRAY(DAE.T_REAL_DEFAULT,{DAE.DIM_INTEGER(nCEqns)}, DAE.emptyTypeSource),DAE.T_REAL_DEFAULT);
  ocrJ := ComponentReference.joinCrefs(set,ComponentReference.makeCrefIdent("J",tp,{}));
  oJVars := generateArrayVar(ocrJ,BackendDAE.VARIABLE(),tp,NONE());
  oJVars := List.map1(oJVars,BackendVariable.setVarFixed,false);
end getSetVars;


protected function setSetAStart
  input list<BackendDAE.Var> iVars;
  input Integer n;
  input Integer r;
  input Integer nStates;
  input list<BackendDAE.Var> iAcc;
  output list<BackendDAE.Var> oAcc;
algorithm
  oAcc := match(iVars,n,r,nStates,iAcc)
    local
      BackendDAE.Var v;
      list<BackendDAE.Var> rest;
      Integer n1,r1,start;
    case({},_,_,_,_) then listReverse(iAcc);
    case(v::rest,_,_,_,_)
      equation
        start = Util.if_(intEq(n,r),1,0);
        v = BackendVariable.setVarStartValue(v,DAE.ICONST(start));
        n1 = Util.if_(intEq(n,nStates),1,n+1);
        r1 = Util.if_(intEq(n,nStates),r+1,r);
      then
        setSetAStart(rest,n1,r1,nStates,v::iAcc);
  end match;
end setSetAStart;
/*
 * dump GraphML stuff
 *
 */

public function dumpSystemGraphML
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Option<array<Integer>> inids;
  input String filename;
  input Boolean numberMode; //If you set this value to true, the node-text will only contain the variable number. The expression will be moved to the description-tag.
algorithm
  _ := match(isyst,ishared,inids,filename,numberMode)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      GraphML.GraphInfo graphInfo;
      Integer graph;
      list<Integer> eqnsids;
      Integer neqns;
      array<Integer> vec1,vec2,vec3,mapIncRowEqn;
      array<Boolean> eqnsflag;
      BackendDAE.EqSystem syst;
      DAE.FunctionTree funcs;
      BackendDAE.StrongComponents comps;
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.NO_MATCHING()),_,NONE(),_,_)
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        funcs = BackendDAEUtil.getFunctions(ishared);
        (_,m,mt) = BackendDAEUtil.getIncidenceMatrix(isyst,BackendDAE.NORMAL(),SOME(funcs));
        mapIncRowEqn = listArray(List.intRange(arrayLength(m)));
        graphInfo = GraphML.createGraphInfo();
        (graphInfo,(_,graph)) = GraphML.addGraph("G",false,graphInfo);
        ((_,_,(graphInfo,graph))) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(numberMode,1,(graphInfo,graph)));
        neqns = BackendDAEUtil.equationArraySize(eqns);
        //neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        ((graphInfo,graph)) = List.fold3(eqnsids,addEqnGraph,eqns,mapIncRowEqn,numberMode,(graphInfo,graph));
        ((_,_,graphInfo)) = List.fold(eqnsids,addEdgesGraph,(1,m,graphInfo));
        GraphML.dumpGraph(graphInfo,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt),matching=BackendDAE.NO_MATCHING()),_,NONE(),_,_)
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        graphInfo = GraphML.createGraphInfo();
        (graphInfo,(_,graph)) = GraphML.addGraph("G",false,graphInfo);
        ((_,_,(graphInfo,graph))) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(numberMode,1,(graphInfo,graph)));
        neqns = BackendDAEUtil.equationArraySize(eqns);
        //neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        mapIncRowEqn = listArray(List.intRange(arrayLength(m)));
        ((graphInfo,graph)) = List.fold3(eqnsids,addEqnGraph,eqns,mapIncRowEqn,numberMode,(graphInfo,graph));
        ((_,_,graphInfo)) = List.fold(eqnsids,addEdgesGraph,(1,m,graphInfo));
        GraphML.dumpGraph(graphInfo,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=vec1,ass2=vec2,comps={})),_,NONE(),_,_)
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        funcs = BackendDAEUtil.getFunctions(ishared);
        //(_,m,mt) = BackendDAEUtil.getIncidenceMatrix(isyst, BackendDAE.NORMAL(), SOME(funcs));
        //mapIncRowEqn = listArray(List.intRange(arrayLength(m)));
        //(_,m,mt,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(isyst,BackendDAE.SOLVABLE(), SOME(funcs)));
        (syst,m,mt,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(isyst,BackendDAE.NORMAL(), SOME(funcs));
        graphInfo = GraphML.createGraphInfo();
        (graphInfo,(_,graph)) = GraphML.addGraph("G",false,graphInfo);
        ((_,_,_,(graphInfo,graph))) = BackendVariable.traverseBackendDAEVars(vars,addVarGraphMatch,(numberMode,1,vec1,(graphInfo,graph)));
        //neqns = BackendDAEUtil.equationArraySize(eqns);
        neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        eqnsflag = arrayCreate(neqns,false);
        ((graphInfo,graph)) = List.fold3(eqnsids,addEqnGraphMatch,eqns,(vec2,mapIncRowEqn,eqnsflag),numberMode,(graphInfo,graph));
        //graph = List.fold3(eqnsids,addEqnGraphMatch,eqns,vec2,mapIncRowEqn,graph);
        ((_,_,_,_,graphInfo)) = List.fold(eqnsids,addDirectedEdgesGraph,(1,m,vec2,mapIncRowEqn,graphInfo));
        GraphML.dumpGraph(graphInfo,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=vec1,ass2=vec2,comps={})),_,SOME(vec3),_,_)
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        funcs = BackendDAEUtil.getFunctions(ishared);
        (_,m,mt,_,mapIncRowEqn) = BackendDAEUtil.getIncidenceMatrixScalar(isyst,BackendDAE.NORMAL(), SOME(funcs));
        graphInfo = GraphML.createGraphInfo();
        (graphInfo,(_,graph)) = GraphML.addGraph("G",false,graphInfo);
        ((_,_,(graphInfo,graph))) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(numberMode,1,(graphInfo,graph)));
        neqns = BackendDAEUtil.equationSize(eqns);
        eqnsids = List.intRange(neqns);
        ((graphInfo,graph)) = List.fold3(eqnsids,addEqnGraph,eqns,mapIncRowEqn,numberMode,(graphInfo,graph));
        ((_,_,_,_,graphInfo)) = List.fold(eqnsids,addDirectedNumEdgesGraph,(1,m,vec2,vec3,graphInfo));
        GraphML.dumpGraph(graphInfo,filename);
     then
       ();
    case (BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(ass1=vec1,ass2=vec2,comps=comps)),_,NONE(),_,_)
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        funcs = BackendDAEUtil.getFunctions(ishared);
        (_,m,mt) = BackendDAEUtil.getIncidenceMatrix(isyst, BackendDAE.NORMAL(), SOME(funcs));
        graphInfo = GraphML.createGraphInfo();
        (graphInfo,(_,graph)) = GraphML.addGraph("G",false,graphInfo);
        // generate a node for each component and get the edges
        vec3 = arrayCreate(arrayLength(mt),-1);
        ((graphInfo,graph)) = addCompsGraph(comps,vars,vec3,1,(graphInfo,graph));
        // generate edges
        mapIncRowEqn = arrayCreate(arrayLength(mt),-1);
        graphInfo = addCompsEdgesGraph(comps,m,vec3,1,1,mapIncRowEqn,1,graphInfo);
        GraphML.dumpGraph(graphInfo,filename);
     then
       ();
  end match;
end dumpSystemGraphML;

protected function addVarGraph
"author: Frenkel TUD 2012-05"
 input tuple<BackendDAE.Var, tuple<Boolean,Integer,tuple<GraphML.GraphInfo,Integer>>> inTpl;
 output tuple<BackendDAE.Var, tuple<Boolean,Integer,tuple<GraphML.GraphInfo,Integer>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      GraphML.GraphInfo graphInfo;
      GraphML.NodeLabel label;
      Integer graph;
      DAE.ComponentRef cr;
      Integer id;
      Boolean b;
      String color,desc,labelText;
    case ((v as BackendDAE.VAR(varName=cr),(true,id,(graphInfo,graph))))
      equation
        true = BackendVariable.isStateVar(v);
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),GraphML.COLOR_BLUE,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),GraphML.COLOR_BLUE,GraphML.ELLIPSE(),g);
        labelText = intString(id);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        desc = ComponentReference.printComponentRefStr(cr);
        (graphInfo,_) = GraphML.addNode("v" +& intString(id),GraphML.COLOR_BLUE, {label}, GraphML.ELLIPSE(),SOME(desc),{}, graph, graphInfo);
      then ((v,(true,id+1,(graphInfo,graph))));
    case ((v as BackendDAE.VAR(varName=cr),(false,id,(graphInfo,graph))))
      equation
        true = BackendVariable.isStateVar(v);
        labelText = intString(id) +& ": " +& ComponentReference.printComponentRefStr(cr);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("v" +& intString(id),GraphML.COLOR_BLUE,{label},GraphML.ELLIPSE(),NONE(),{}, graph, graphInfo);
      then ((v,(false,id+1,(graphInfo,graph))));
    case ((v as BackendDAE.VAR(varName=cr),(true,id,(graphInfo,graph))))
      equation
        b = BackendVariable.isVarDiscrete(v);
        color = Util.if_(b,GraphML.COLOR_PURPLE,GraphML.COLOR_RED);
        labelText = intString(id);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        desc = ComponentReference.printComponentRefStr(cr);
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),GraphML.COLOR_RED,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),GraphML.COLOR_RED,GraphML.ELLIPSE(),g);
        (graphInfo,_) = GraphML.addNode("v" +& intString(id),color,{label},GraphML.ELLIPSE(),SOME(desc),{}, graph, graphInfo);
      then ((v,(true,id+1,(graphInfo,graph))));
    case ((v as BackendDAE.VAR(varName=cr),(false,id,(graphInfo,graph))))
      equation
        b = BackendVariable.isVarDiscrete(v);
        color = Util.if_(b,GraphML.COLOR_PURPLE,GraphML.COLOR_RED);
        labelText = intString(id) +& ": " +& ComponentReference.printComponentRefStr(cr);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("v" +& intString(id),color, {label}, GraphML.ELLIPSE(),NONE(),{},graph, graphInfo);
      then ((v,(false,id+1,(graphInfo,graph))));
    case _ then inTpl;
  end matchcontinue;
end addVarGraph;

protected function addVarGraphMatch
"author: Frenkel TUD 2012-05"
 input tuple<BackendDAE.Var, tuple<Boolean,Integer,array<Integer>,tuple<GraphML.GraphInfo,Integer>>> inTpl;
 output tuple<BackendDAE.Var, tuple<Boolean,Integer,array<Integer>,tuple<GraphML.GraphInfo,Integer>>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      GraphML.GraphInfo graphInfo;
      GraphML.NodeLabel label;
      Integer graph;
      DAE.ComponentRef cr;
      Integer id;
      array<Integer> vec1;
      String color,desc;
      String labelText;
    case ((v as BackendDAE.VAR(varName=cr),(false,id,vec1,(graphInfo,graph))))
      equation
        true = BackendVariable.isStateVar(v);
        color = Util.if_(intGt(vec1[id],0),GraphML.COLOR_BLUE,GraphML.COLOR_YELLOW);
        labelText = intString(id) +& ": " +& ComponentReference.printComponentRefStr(cr);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),color,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),color,GraphML.ELLIPSE(),g);
        (graphInfo,_) = GraphML.addNode("v" +& intString(id),color, {label}, GraphML.ELLIPSE(),NONE(),{},graph, graphInfo);
      then ((v,(false,id+1,vec1,(graphInfo,graph))));
    case ((v as BackendDAE.VAR(varName=cr),(true,id,vec1,(graphInfo,graph))))
      equation
        true = BackendVariable.isStateVar(v);
        color = Util.if_(intGt(vec1[id],0),GraphML.COLOR_BLUE,GraphML.COLOR_YELLOW);
        desc = ComponentReference.printComponentRefStr(cr);
        labelText = intString(id);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("v" +& intString(id),color, {label}, GraphML.ELLIPSE(),SOME(desc),{},graph, graphInfo);
      then ((v,(true,id+1,vec1,(graphInfo,graph))));
    case ((v as BackendDAE.VAR(varName=cr),(false,id,vec1,(graphInfo,graph))))
      equation
        color = Util.if_(intGt(vec1[id],0),GraphML.COLOR_RED,GraphML.COLOR_YELLOW);
        labelText = intString(id) +& ": " +& ComponentReference.printComponentRefStr(cr);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        //g = GraphML.addNode("v" +& intString(id),ComponentReference.printComponentRefStr(cr),color,GraphML.ELLIPSE(),g);
        //g = GraphML.addNode("v" +& intString(id),intString(id),color,GraphML.ELLIPSE(),g);
        (graphInfo,_) = GraphML.addNode("v" +& intString(id),color,{label},GraphML.ELLIPSE(),NONE(),{},graph, graphInfo);
      then ((v,(false,id+1,vec1,(graphInfo,graph))));
    case ((v as BackendDAE.VAR(varName=cr),(true,id,vec1,(graphInfo,graph))))
      equation
        color = Util.if_(intGt(vec1[id],0),GraphML.COLOR_RED,GraphML.COLOR_YELLOW);
        desc = ComponentReference.printComponentRefStr(cr);
        labelText = intString(id);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("v" +& intString(id),color,{label},GraphML.ELLIPSE(),SOME(desc),{},graph, graphInfo);
      then ((v,(true,id+1,vec1,(graphInfo,graph))));
    case _ then inTpl;
  end matchcontinue;
end addVarGraphMatch;

protected function addEqnGraph
  input Integer inNode;
  input BackendDAE.EquationArray eqns;
  input array<Integer> mapIncRowEqn;
  input Boolean numberMode;
  input tuple<GraphML.GraphInfo,Integer> inGraph;
  output tuple<GraphML.GraphInfo,Integer> outGraph;
protected
  BackendDAE.Equation eqn;
  String str;
  GraphML.GraphInfo graphInfo;
  Integer graph;
  GraphML.NodeLabel label;
  String labelText;
algorithm
  outGraph := match(inNode, eqns, mapIncRowEqn, numberMode, inGraph)
    case(_,_,_,false,(graphInfo,graph))
      equation
        eqn = BackendEquation.equationNth0(eqns, mapIncRowEqn[inNode]-1);
        str = BackendDump.equationString(eqn);
        //str := intString(inNode);
        str = intString(inNode) +& ": " +& BackendDump.equationString(eqn);
        str = Util.xmlEscape(str);
        label = GraphML.NODELABEL_INTERNAL(str,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("n" +& intString(inNode),GraphML.COLOR_GREEN,{label},GraphML.RECTANGLE(),NONE(),{},graph,graphInfo);
      then ((graphInfo,graph));
    case(_,_,_,true,(graphInfo,graph))
      equation
        eqn = BackendEquation.equationNth0(eqns, mapIncRowEqn[inNode]-1);
        str = BackendDump.equationString(eqn);
        //str := intString(inNode);
        //str = intString(inNode) +& ": " +& BackendDump.equationString(eqn);
        str = Util.xmlEscape(str);
        labelText = intString(inNode);
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("n" +& intString(inNode),GraphML.COLOR_GREEN, {label},GraphML.RECTANGLE(),SOME(str),{},graph,graphInfo);
      then ((graphInfo,graph));
  end match;
end addEqnGraph;

protected function addEdgesGraph
  input Integer e;
  input tuple<Integer,BackendDAE.IncidenceMatrix,GraphML.GraphInfo> inTpl;
  output tuple<Integer,BackendDAE.IncidenceMatrix,GraphML.GraphInfo> outTpl;
protected
  Integer id;
  GraphML.GraphInfo graph;
  BackendDAE.IncidenceMatrix m;
  list<Integer> vars;
algorithm
  (id,m,graph) := inTpl;
  vars := List.select(m[e], Util.intPositive);
  vars := m[e];
  ((id,graph)) := List.fold1(vars,addEdgeGraph,e,(id,graph));
  outTpl := (id,m,graph);
end addEdgesGraph;

protected function addEqnGraphMatch
  input Integer inNode;
  input BackendDAE.EquationArray eqns;
  input tuple<array<Integer>,array<Integer>,array<Boolean>> atpl;
//  input array<Integer> vec2;
//  input array<Integer> mapIncRowEqn;
  input Boolean numberMode;
  input tuple<GraphML.GraphInfo,Integer> inGraph;
  output tuple<GraphML.GraphInfo,Integer> outGraph;
algorithm
  outGraph := matchcontinue(inNode,eqns,atpl,numberMode,inGraph)
    local
      BackendDAE.Equation eqn;
      String str,color;
      Integer e;
      Integer graph;
      GraphML.GraphInfo graphInfo;
      GraphML.NodeLabel label;
      array<Integer> vec2,mapIncRowEqn;
      array<Boolean> eqnsflag;
      String labelText;
    case(_,_,(vec2,mapIncRowEqn,eqnsflag),false,(graphInfo,graph))
      equation
        e = mapIncRowEqn[inNode];
        false = eqnsflag[e];
       eqn = BackendEquation.equationNth0(eqns, mapIncRowEqn[inNode]-1);
       str = BackendDump.equationString(eqn);
       str = intString(e) +& ": " +&  str;
       //str = intString(inNode);
       str = Util.xmlEscape(str);
       color = Util.if_(intGt(vec2[inNode],0),GraphML.COLOR_GREEN,GraphML.COLOR_PURPLE);
       label = GraphML.NODELABEL_INTERNAL(str,NONE(),GraphML.FONTPLAIN());
       (graphInfo,_) = GraphML.addNode("n" +& intString(e),color, {label}, GraphML.RECTANGLE(),NONE(),{},graph,graphInfo);
     then ((graphInfo,graph));
    case(_,_,(vec2,mapIncRowEqn,eqnsflag),true,(graphInfo,graph))
      equation
        e = mapIncRowEqn[inNode];
        false = eqnsflag[e];
       eqn = BackendEquation.equationNth0(eqns, mapIncRowEqn[inNode]-1);
       str = BackendDump.equationString(eqn);
       //str = intString(e) +& ": " +&  str;
       //str = intString(inNode);
       str = Util.xmlEscape(str);
       color = Util.if_(intGt(vec2[inNode],0),GraphML.COLOR_GREEN,GraphML.COLOR_PURPLE);
       labelText = intString(e);
       label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
       (graphInfo,_) = GraphML.addNode("n" +& intString(e),color, {label}, GraphML.RECTANGLE(),SOME(str),{},graph,graphInfo);
     then ((graphInfo,graph));
    case(_,_,(vec2,mapIncRowEqn,eqnsflag),_,_)
      equation
        e = mapIncRowEqn[inNode];
        true = eqnsflag[e];
     then
        inGraph;
  end matchcontinue;
end addEqnGraphMatch;

protected function addEdgeGraph
  input Integer V;
  input Integer e;
  input tuple<Integer,GraphML.GraphInfo> inTpl;
  output tuple<Integer,GraphML.GraphInfo> outTpl;
protected
  Integer id,v;
  GraphML.GraphInfo graph;
  GraphML.LineType ln;
algorithm
  (id,graph) := inTpl;
  v := intAbs(V);
  ln := Util.if_(intGt(V,0),GraphML.LINE(),GraphML.DASHED());
  (graph,_) := GraphML.addEdge("e" +& intString(id),"n" +& intString(e),"v" +& intString(v),GraphML.COLOR_BLACK,ln,GraphML.LINEWIDTH_STANDARD, false, {},(GraphML.ARROWNONE(),GraphML.ARROWNONE()),{},graph);
  outTpl := ((id+1,graph));
end addEdgeGraph;

protected function addDirectedEdgesGraph
  input Integer e;
  input tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.GraphInfo> inTpl;
  output tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.GraphInfo> outTpl;
protected
  Integer id,v,n;
  GraphML.GraphInfo graph;
  BackendDAE.IncidenceMatrix m;
  list<Integer> vars;
  array<Integer> vec2;
  array<Integer> mapIncRowEqn;
algorithm
  (id,m,vec2,mapIncRowEqn,graph) := inTpl;
  //vars := List.select(m[e], Util.intPositive);
  vars := m[e];
  v := vec2[e];
  ((id,_,graph)) := List.fold1(vars,addDirectedEdgeGraph,mapIncRowEqn[e],(id,v,graph));
  outTpl := (id,m,vec2,mapIncRowEqn,graph);
end addDirectedEdgesGraph;

protected function addDirectedEdgeGraph
  input Integer v;
  input Integer e;
  input tuple<Integer,Integer,GraphML.GraphInfo> inTpl;
  output tuple<Integer,Integer,GraphML.GraphInfo> outTpl;
protected
  Integer id,r,absv;
  GraphML.GraphInfo graph;
  tuple<GraphML.ArrowType,GraphML.ArrowType> arrow;
  GraphML.LineType lt;
algorithm
  (id,r,graph) := inTpl;
  absv := intAbs(v);
  arrow := Util.if_(intEq(r,absv),(GraphML.ARROWSTANDART(),GraphML.ARROWNONE()),(GraphML.ARROWNONE(),GraphML.ARROWSTANDART()));
  lt := Util.if_(intGt(v,0),GraphML.LINE(),GraphML.DASHED());
  (graph,_) := GraphML.addEdge("e" +& intString(id),"n" +& intString(e),"v" +& intString(absv),GraphML.COLOR_BLACK,lt,GraphML.LINEWIDTH_STANDARD, false, {},arrow,{},graph);
  outTpl := ((id+1,r,graph));
end addDirectedEdgeGraph;


protected function addDirectedNumEdgesGraph
  input Integer e;
  input tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.GraphInfo> inTpl;
  output tuple<Integer,BackendDAE.IncidenceMatrix,array<Integer>,array<Integer>,GraphML.GraphInfo> outTpl;
protected
  Integer id,v;
  GraphML.GraphInfo graph;
  BackendDAE.IncidenceMatrix m;
  list<Integer> vars;
  array<Integer> vec2,vec3,mapIncRowEqn;
  String text;
algorithm
  (id,m,vec2,vec3,graph) := inTpl;
  vars := List.select(m[e], Util.intPositive);
  v := vec2[e];
  text := intString(vec3[e]);
  ((id,_,_,graph)) := List.fold1(vars,addDirectedNumEdgeGraph,e,(id,v,text,graph));
  outTpl := (id,m,vec2,vec3,graph);
end addDirectedNumEdgesGraph;

protected function addDirectedNumEdgeGraph
  input Integer v;
  input Integer e;
  input tuple<Integer,Integer,String,GraphML.GraphInfo> inTpl;
  output tuple<Integer,Integer,String,GraphML.GraphInfo> outTpl;
protected
  Integer id,r,n;
  GraphML.GraphInfo graph;
  tuple<GraphML.ArrowType,GraphML.ArrowType> arrow;
  String text;
  List<GraphML.EdgeLabel> labels;
algorithm
  (id,r,text,graph) := inTpl;
  arrow := Util.if_(intEq(r,v),(GraphML.ARROWSTANDART(),GraphML.ARROWNONE()),(GraphML.ARROWNONE(),GraphML.ARROWSTANDART()));
  labels := Util.if_(intEq(r,v),{GraphML.EDGELABEL(text,SOME("#0000FF"),GraphML.FONTSIZE_STANDARD)},{});
  (graph,_) := GraphML.addEdge("e" +& intString(id),"n" +& intString(e),"v" +& intString(v),GraphML.COLOR_BLACK,GraphML.LINE(),GraphML.LINEWIDTH_STANDARD,false,labels,arrow,{},graph);
  outTpl := ((id+1,r,text,graph));
end addDirectedNumEdgeGraph;

public function dumpUnmatched
  input list<Integer> inEqnsLst;
  input BackendDAE.EqSystem isyst;
  input array<Integer> ass1;
  input array<Integer> ass2;
  input String fileName;
protected
  BackendDAE.IncidenceMatrix m;
  list<Integer> states,vars;
  GraphML.GraphInfo graphInfo;
  Integer graph;
  Integer id;
  BackendDAE.Variables varsarray;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=varsarray,m=SOME(m)) := isyst;
  (states,vars) := statesandVarsInEqns(inEqnsLst,m,{},{});
  graphInfo := GraphML.createGraphInfo();
  (graphInfo,(_,graph)) := GraphML.addGraph("G",false,graphInfo);
  ((graphInfo,graph)) := List.fold1(inEqnsLst,addEqnNodes,ass2,(graphInfo,graph));
  ((graphInfo,graph)) := List.fold1(states,addVarNodes,("s",varsarray,ass1,GraphML.COLOR_RED,GraphML.COLOR_DARKRED),(graphInfo,graph));
  ((graphInfo,graph)) := List.fold1(vars,addVarNodes,("v",varsarray,ass1,GraphML.COLOR_YELLOW,GraphML.COLOR_GRAY),(graphInfo,graph));
  ((graphInfo,_)) := List.fold2(inEqnsLst,addEdges,m,ass2,(graphInfo,1));
  GraphML.dumpGraph(graphInfo,fileName);
end dumpUnmatched;

protected function addEdges
  input Integer e;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> ass2;
  input tuple<GraphML.GraphInfo,Integer> inGraph;
  output tuple<GraphML.GraphInfo,Integer> outGraph;
protected
  list<Integer> eqnstates,eqnvars;
algorithm
  (eqnstates,eqnvars) := List.split1OnTrue(m[e],intLt,0);
  eqnstates := List.map(eqnstates,intAbs);
  outGraph := List.fold2(eqnstates,addEdge,(e,"s",ass2),m,inGraph);
  outGraph := List.fold2(eqnvars,addEdge,(e,"v",ass2),m,outGraph);
end addEdges;

protected function addEdge
  input Integer v;
  input tuple<Integer,String,array<Integer>> inTpl;
  input BackendDAE.IncidenceMatrix m;
  input tuple<GraphML.GraphInfo,Integer> inGraph;
  output tuple<GraphML.GraphInfo,Integer> outGraph;
protected
  GraphML.GraphInfo graph;
  Integer id,e,evar;
  String prefix;
  array<Integer> ass2;
  GraphML.ArrowType arrow;
algorithm
  (e,prefix,ass2) := inTpl;
  (graph,id) := inGraph;
  evar :=ass2[e];
  arrow := Util.if_(intGt(evar,0) and intEq(evar,v) ,GraphML.ARROWSTANDART(),GraphML.ARROWNONE());
  (graph,_) := GraphML.addEdge("e" +& intString(id),"n" +& intString(e),prefix +& intString(v),GraphML.COLOR_BLACK,GraphML.LINE(),GraphML.LINEWIDTH_STANDARD, false, {},(GraphML.ARROWNONE(),arrow),{},graph);
  outGraph := (graph,id+1);
end addEdge;

protected function addEqnNodes
  input Integer inNode;
  input array<Integer> ass2;
  input tuple<GraphML.GraphInfo,Integer> inGraph;
  output tuple<GraphML.GraphInfo,Integer> outGraph;
protected
  String color;
  Integer graph;
  GraphML.GraphInfo graphInfo;
  GraphML.NodeLabel label;
  String labelText;
algorithm
  (graphInfo,graph) := inGraph;
  color := Util.if_(intGt(ass2[inNode],0),GraphML.COLOR_GREEN,GraphML.COLOR_BLUE);
  labelText := intString(inNode);
  label := GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
  (graphInfo,_) := GraphML.addNode("n" +& intString(inNode),color,{label},GraphML.RECTANGLE(),NONE(),{},graph,graphInfo);
  outGraph := (graphInfo,graph);
end addEqnNodes;

protected function addVarNodes
  input Integer inNode;
  input tuple<String,BackendDAE.Variables,array<Integer>,String,String> inTpl;
  input tuple<GraphML.GraphInfo,Integer> inGraph;
  output tuple<GraphML.GraphInfo,Integer> outGraph;
protected
  String prefix,color,color1,c;
  BackendDAE.Variables vars;
  BackendDAE.Var var;
  DAE.ComponentRef cr;
  array<Integer> ass1;
  Integer graph;
  GraphML.GraphInfo graphInfo;
  GraphML.NodeLabel label;
  String labelText;
algorithm
  (graphInfo,graph) := inGraph;
  (prefix,vars,ass1,color,color1) := inTpl;
  var := BackendVariable.getVarAt(vars,inNode);
  cr := BackendVariable.varCref(var);
  c := Util.if_(intGt(ass1[inNode],0),color1,color);
  labelText := ComponentReference.printComponentRefStr(cr);
  label := GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
  (graphInfo,_) := GraphML.addNode(prefix +& intString(inNode),c,{label},GraphML.ELLIPSE(),NONE(),{},graph,graphInfo);
  outGraph := (graphInfo,graph);
end addVarNodes;

protected function statesandVarsInEqns
"author: Frenkel TUD - 2012-04"
  input list<Integer> inEqnsLst;
  input BackendDAE.IncidenceMatrix m;
  input list<Integer> inStates;
  input list<Integer> inVars;
  output list<Integer> outStates;
  output list<Integer> outVars;
algorithm
  (outStates,outVars):=
  matchcontinue (inEqnsLst,m,inStates,inVars)
    local
      Integer e;
      list<Integer> rest,eqnstates,eqnvars,states,vars;
    case ({},_,_,_) then (inStates,inVars);
    case ((e :: rest),_,_,_)
      equation
        (eqnstates,eqnvars) = List.split1OnTrue(m[e],intLt,0);
        eqnstates = List.map(eqnstates,intAbs);
        states = List.unionOnTrue(eqnstates,inStates,intEq);
        vars = List.unionOnTrue(eqnvars,inVars,intEq);
        (states,vars) = statesandVarsInEqns(rest,m,states,vars);
      then
        (states,vars);
    case ((_ :: rest),_,_,_)
      equation
       print("IndexReduction.statesandVarsInEqns failed!");
      then
        fail();
  end matchcontinue;
end statesandVarsInEqns;


public function dumpSystemGraphMLEnhanced
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.AdjacencyMatrixEnhanced m;
  input BackendDAE.AdjacencyMatrixTEnhanced mT;
algorithm
  _ := match(isyst,ishared,m,mT)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      GraphML.GraphInfo graphInfo;
      Integer graph;
      list<Integer> eqnsids;
      Integer neqns;
    case (_,_,_,_)
      equation
        vars = BackendVariable.daeVars(isyst);
        eqns = BackendEquation.daeEqns(isyst);
        graphInfo = GraphML.createGraphInfo();
        (graphInfo,(_,graph)) = GraphML.addGraph("G",false,graphInfo);
        ((_,_,(graphInfo,graph))) = BackendVariable.traverseBackendDAEVars(vars,addVarGraph,(false,1,(graphInfo,graph)));
        neqns = BackendDAEUtil.systemSize(isyst);
        eqnsids = List.intRange(neqns);
        ((graphInfo,graph)) = List.fold3(eqnsids,addEqnGraph,eqns,listArray(eqnsids),false,(graphInfo,graph));
        ((_,_,graphInfo)) = List.fold(eqnsids,addDirectedNumEdgesGraphEnhanced,(1,m,graphInfo));
        GraphML.dumpGraph(graphInfo,"");
     then
       ();
  end match;
end dumpSystemGraphMLEnhanced;

protected function addDirectedNumEdgesGraphEnhanced
  input Integer e;
  input tuple<Integer,BackendDAE.AdjacencyMatrixEnhanced,GraphML.GraphInfo> inTpl;
  output tuple<Integer,BackendDAE.AdjacencyMatrixEnhanced,GraphML.GraphInfo> outTpl;
protected
  Integer id;
  GraphML.GraphInfo graph;
  BackendDAE.AdjacencyMatrixEnhanced m;
  BackendDAE.AdjacencyMatrixElementEnhanced vars;
algorithm
  (id,m,graph) := inTpl;
  ((id,graph)) := List.fold1(m[e],addDirectedNumEdgeGraphEnhanced,e,(id,graph));
  outTpl := (id,m,graph);
end addDirectedNumEdgesGraphEnhanced;

protected function addDirectedNumEdgeGraphEnhanced
  input tuple<Integer,BackendDAE.Solvability> vs;
  input Integer e;
  input tuple<Integer,GraphML.GraphInfo> inTpl;
  output tuple<Integer,GraphML.GraphInfo> outTpl;
algorithm
  outTpl := matchcontinue(vs,e,inTpl)
    local
      BackendDAE.Solvability s;
      Integer id,v;
      GraphML.GraphInfo graph;
      String text;
      GraphML.EdgeLabel label;
    case((v,s),_,(id,graph))
      equation
        true = intGt(v,0);
        text = intString(solvabilityWights(s));
        label = GraphML.EDGELABEL(text,SOME("#0000FF"), GraphML.FONTSIZE_STANDARD);
        (graph,_) = GraphML.addEdge("e" +& intString(id),"n" +& intString(e),"v" +& intString(v),GraphML.COLOR_BLACK,GraphML.LINE(),GraphML.LINEWIDTH_STANDARD,false,{label},(GraphML.ARROWNONE(),GraphML.ARROWNONE()),{},graph);
      then
        ((id+1,graph));
    else then inTpl;
  end matchcontinue;
end addDirectedNumEdgeGraphEnhanced;

protected function addCompsGraph "author: Frenkel TUD 2013-02,
  add for each component a node to the graph and strore
  varcomp[var] = comp."
  input BackendDAE.StrongComponents iComps;
  input BackendDAE.Variables vars;
  input array<Integer> varcomp;
  input Integer iN;
  input tuple<GraphML.GraphInfo,Integer> iGraph;
  output tuple<GraphML.GraphInfo,Integer> oGraph;
algorithm
  oGraph := match(iComps,vars,varcomp,iN,iGraph)
    local
      BackendDAE.StrongComponents rest;
      BackendDAE.StrongComponent comp;
      list<Integer> vlst;
      Integer graph;
      GraphML.GraphInfo graphInfo;
      GraphML.NodeLabel label;
      array<Integer> varcomp1;
      String text;
      list<BackendDAE.Var> varlst;
    case ({},_,_,_,_) then iGraph;
    case (comp::rest,_,_,_,(graphInfo,graph))
      equation
        (_,vlst) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
        varcomp1 = List.fold1r(vlst,arrayUpdate,iN,varcomp);
        varlst = List.map1r(vlst,BackendVariable.getVarAt,vars);
        text = intString(iN) +& ":" +& stringDelimitList(List.map(List.map(varlst,BackendVariable.varCref),ComponentReference.printComponentRefStr),"\n");
        label = GraphML.NODELABEL_INTERNAL(text,NONE(),GraphML.FONTPLAIN());
        (graphInfo,_) = GraphML.addNode("n" +& intString(iN),GraphML.COLOR_GREEN,{label},GraphML.RECTANGLE(),NONE(),{},graph,graphInfo);
      then
        addCompsGraph(rest,vars,varcomp1,iN+1,(graphInfo,graph));
  end match;
end addCompsGraph;

protected function addCompsEdgesGraph "author: Frenkel TUD 2013-02,
  add for each component the edges to the graph."
  input BackendDAE.StrongComponents iComps;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> varcomp;
  input Integer iN;
  input Integer id;
  input array<Integer> markarray;
  input Integer mark;
  input GraphML.GraphInfo iGraph;
  output GraphML.GraphInfo oGraph;
algorithm
  oGraph := match(iComps,m,varcomp,iN,id,markarray,mark,iGraph)
    local
      BackendDAE.StrongComponents rest;
      BackendDAE.StrongComponent comp;
      list<Integer> elst,vlst,usedvlst;
      Integer n;
      GraphML.GraphInfo graph;
    case ({},_,_,_,_,_,_,_) then iGraph;
    case (comp::rest,_,_,_,_,_,_,_)
      equation
        // get eqns and vars of comps
        (elst,vlst) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
        // get used vars of comp
        _ = List.fold1r(vlst,arrayUpdate,mark,markarray) "set assigned visited";
        vlst = getUsedVarsComp(elst,m,markarray,mark,{});
        (n,graph) = addCompEdgesGraph(vlst,varcomp,markarray,mark+1,iN,id,iGraph);
      then
        addCompsEdgesGraph(rest,m,varcomp,iN+1,n,markarray,mark+2,graph);
  end match;
end addCompsEdgesGraph;

protected function getUsedVarsComp "author: Frenkel TUD 2013-02,
  get all used var of the comp."
  input list<Integer> iEqns;
  input BackendDAE.IncidenceMatrix m;
  input array<Integer> markarray;
  input Integer mark;
  input list<Integer> iVars;
  output list<Integer> oVars;
algorithm
  oVars := match(iEqns,m,markarray,mark,iVars)
    local
      list<Integer> rest,vlst;
      Integer e;
    case ({},_,_,_,_) then iVars;
    case (e::rest,_,_,_,_)
      equation
        vlst = List.select1(m[e], intGt, 0);
        vlst = List.select1r(vlst, isUnMarked, (markarray,mark));
        _ = List.fold1r(vlst,arrayUpdate,mark,markarray) "set visited";
        vlst = listAppend(vlst,iVars);
      then
        getUsedVarsComp(rest,m,markarray,mark,vlst);
  end match;
end getUsedVarsComp;

protected function addCompEdgesGraph "author: Frenkel TUD 2013-02,
  add for eqach used var of the comp an edge."
  input list<Integer> iVars;
  input array<Integer> varcomp;
  input array<Integer> markarray;
  input Integer mark;
  input Integer iN;
  input Integer id;
  input GraphML.GraphInfo iGraph;
  output Integer oN;
  output GraphML.GraphInfo oGraph;
algorithm
  (oN,oGraph) := matchcontinue(iVars,varcomp,markarray,mark,iN,id,iGraph)
    local
      list<Integer> rest;
      Integer v,n,c;
      GraphML.GraphInfo graph;
      String text;
      GraphML.EdgeLabel label;
    case ({},_,_,_,_,_,_) then (id,iGraph);
    case (v::rest,_,_,_,_,_,_)
      equation
        c = varcomp[v];
        false = intEq(markarray[c],mark);
        _ = arrayUpdate(markarray,c,mark);
        (graph,_) = GraphML.addEdge("e" +& intString(id),"n" +& intString(c),"n" +& intString(iN),GraphML.COLOR_BLACK,GraphML.LINE(),GraphML.LINEWIDTH_STANDARD,false,{},(GraphML.ARROWSTANDART(),GraphML.ARROWNONE()),{},iGraph);
        (n,graph) = addCompEdgesGraph(rest,varcomp,markarray,mark,iN,id+1,graph);
      then
        (n,graph);
    case (v::rest,_,_,_,_,_,_)
      equation
        (n,graph) = addCompEdgesGraph(rest,varcomp,markarray,mark,iN,id,iGraph);
      then
        (n,graph);
  end matchcontinue;
end addCompEdgesGraph;


protected function solvabilityWights "author: Frenkel TUD 2012-05,
  return a integer for the solvability, this function is used
  to calculade wights for variables to select the tearing variable."
  input BackendDAE.Solvability solva;
  output Integer i;
algorithm
  i := match(solva)
    case BackendDAE.SOLVABILITY_SOLVED() then 0;
    case BackendDAE.SOLVABILITY_CONSTONE() then 2;
    case BackendDAE.SOLVABILITY_CONST() then 5;
    case BackendDAE.SOLVABILITY_PARAMETER(b=false) then 0;
    case BackendDAE.SOLVABILITY_PARAMETER(b=true) then 50;
    case BackendDAE.SOLVABILITY_TIMEVARYING(b=false) then 0;
    case BackendDAE.SOLVABILITY_TIMEVARYING(b=true) then 100;
    case BackendDAE.SOLVABILITY_NONLINEAR() then 200;
    case BackendDAE.SOLVABILITY_UNSOLVABLE() then 300;
  end match;
end solvabilityWights;

/*****************************************
 set the derivative information to the states
 use equations der(s) = v and set s:STATE(derivativeName=v)
*****************************************/

public function findStateOrder "author Frenkel TUD 2013-01
  "
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
algorithm
  BackendDAE.DAE(systs,shared) := inDAE;
  // find der(s) = v
  systs := List.map(systs,findStateOrderWork);
  outDAE := BackendDAE.DAE(systs,shared);
end findStateOrder;

protected function findStateOrderWork "author Frenkel TUD 2013-01"
  input BackendDAE.EqSystem isyst;
  output BackendDAE.EqSystem osyst;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrixT> mT;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets;
algorithm
  BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching,stateSets) := isyst;
  // find der(s) = v
  vars := BackendEquation.traverseBackendDAEEqns(eqns,traverseFindStateOrder,vars);
  osyst := BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching,stateSets);
end findStateOrderWork;

protected function traverseFindStateOrder
"author: Frenkel TUD 2013-01
  collect all states and there derivatives"
 input tuple<BackendDAE.Equation, BackendDAE.Variables> inTpl;
 output tuple<BackendDAE.Equation, BackendDAE.Variables> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Equation e;
      BackendDAE.Variables v;
      DAE.ComponentRef cr,dcr;
      list<BackendDAE.Var> vlst,dvlst;
    case ((e,v))
      equation
        (cr,dcr,_,_,false) = BackendEquation.derivativeEquation(e);
        (vlst,_) = BackendVariable.getVar(cr,v);
        (dvlst,_) = BackendVariable.getVar(dcr,v);
        v = addStateOrderFinder(vlst,dvlst,v);
      then ((e,v));
    case _ then inTpl;
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
    case ((var as BackendDAE.VAR(varName=cr,varKind=BackendDAE.STATE(index=_,derName=NONE())))::vlst,
          BackendDAE.VAR(varName=dcr)::dvlst,_)
      equation
        var = BackendVariable.setStateDerivative(var,SOME(dcr));
        vars = BackendVariable.addVar(var,inVars);
      then
        addStateOrderFinder(vlst,dvlst,vars);
    case(var::_,dvar::_,_)
      equation
        msg = "IndexReduction.addStateOrderFinder failed for " +& BackendDump.varString(var) +& " with derivative " +& BackendDump.varString(dvar) +& "\n";
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
  outStr := intString(Util.tuple22(state)) +& " " +& ComponentReference.printComponentRefStr(Util.tuple21(state));
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

// protected function addAliasStateOrder "author: Frenkel TUD 2012-06
//   add state and replace alias state in the
//   stateorder."
//   input DAE.ComponentRef cr;
//   input DAE.ComponentRef acr;
//   input BackendDAE.StateOrder inStateOrder;
//   output BackendDAE.StateOrder outStateOrder;
// algorithm
//  outStateOrder :=
//   matchcontinue (cr,acr,inStateOrder)
//     local
//         HashTableCG.HashTable ht,ht1;
//         HashTable3.HashTable dht,dht1;
//         DAE.ComponentRef dcr,cr1;
//         list<DAE.ComponentRef> crlst;
//         Boolean b;
//     case (_,_,BackendDAE.STATEORDER(ht,dht))
//       equation
//         dcr = BaseHashTable.get(acr,ht);
//         failure(_ = BaseHashTable.get(cr,ht));
//         ht1 = BaseHashTable.add((cr, dcr),ht);
//         {cr1} = BaseHashTable.get(dcr,dht);
//         ht1 = BaseHashTable.delete(acr,ht1);
//         b = ComponentReference.crefEqualNoStringCompare(cr1, acr);
//         crlst = Util.if_(b,{cr},{cr,cr1});
//         dht1 = BaseHashTable.add((dcr, crlst),dht);
//       then
//         BackendDAE.STATEORDER(ht1,dht1);
//         //replaceDerStateOrder(cr,acr,BackendDAE.STATEORDER(ht1,dht1));
//     case (_,_,BackendDAE.STATEORDER(ht,dht))
//       equation
//         dcr = BaseHashTable.get(acr,ht);
//         failure(_ = BaseHashTable.get(cr,ht));
//         ht1 = BaseHashTable.add((cr, dcr),ht);
//         ht1 = BaseHashTable.delete(acr,ht1);
//         crlst = BaseHashTable.get(dcr,dht);
//         crlst = List.removeOnTrue(acr,ComponentReference.crefEqualNoStringCompare,crlst);
//         dht1 = BaseHashTable.add((dcr, cr::crlst),dht);
//       then
//         BackendDAE.STATEORDER(ht1,dht1);
//         //replaceDerStateOrder(cr,acr,BackendDAE.STATEORDER(ht1,dht1));
//     case (_,_,BackendDAE.STATEORDER(ht,dht))
//       equation
//         dcr = BaseHashTable.get(acr,ht);
//         _ = BaseHashTable.get(cr,ht);
//         {cr1} = BaseHashTable.get(dcr,dht);
//         ht1 = BaseHashTable.delete(acr,ht);
//         b = ComponentReference.crefEqualNoStringCompare(cr1, acr);
//         crlst = Util.if_(b,{cr},{cr,cr1});
//         dht1 = BaseHashTable.add((dcr, crlst),dht);
//       then
//         BackendDAE.STATEORDER(ht1,dht1);
//         //replaceDerStateOrder(cr,acr,BackendDAE.STATEORDER(ht1,dht1));
//     case (_,_,BackendDAE.STATEORDER(ht,dht))
//       equation
//         dcr = BaseHashTable.get(acr,ht);
//         _ = BaseHashTable.get(cr,ht);
//         ht1 = BaseHashTable.delete(acr,ht);
//         crlst = BaseHashTable.get(dcr,dht);
//         crlst = List.removeOnTrue(acr,ComponentReference.crefEqualNoStringCompare,crlst);
//         dht1 = BaseHashTable.add((dcr, cr::crlst),dht);
//       then
//         BackendDAE.STATEORDER(ht1,dht1);
//         //replaceDerStateOrder(cr,acr,BackendDAE.STATEORDER(ht1,dht1));
//     case (_,_,BackendDAE.STATEORDER(hashTable=ht))
//       equation
//         failure(_ = BaseHashTable.get(acr,ht));
//       then
//         inStateOrder;
//         //replaceDerStateOrder(cr,acr,inStateOrder);
//   end matchcontinue;
// end addAliasStateOrder;

// protected function replaceDerStateOrder "author: Frenkel TUD 2012-06
//   replace a state  in the
//   stateorder."
//   input DAE.ComponentRef cr;
//   input DAE.ComponentRef acr;
//   input BackendDAE.StateOrder inStateOrder;
//   output BackendDAE.StateOrder outStateOrder;
// algorithm
//  outStateOrder :=
//   matchcontinue (cr,acr,inStateOrder)
//     local
//         HashTableCG.HashTable ht,ht1;
//         HashTable3.HashTable dht,dht1;
//         DAE.ComponentRef cr1;
//         list<DAE.ComponentRef> crlst;
//         list<tuple<DAE.ComponentRef,DAE.ComponentRef>> crcrlst;
//         Boolean b;
//     case (_,_,BackendDAE.STATEORDER(ht,dht))
//       equation
//         {cr1} = BaseHashTable.get(acr,dht);
//         ht1 = BaseHashTable.add((cr1, cr),ht);
//         BackendDump.debugStrCrefStrCrefStr(("replac der Alias State ",cr1," -> ",cr,"\n"));
//       then
//        BackendDAE.STATEORDER(ht1,dht);
//     case (_,_,BackendDAE.STATEORDER(ht,dht))
//       equation
//         crlst = BaseHashTable.get(acr,dht);
//         crcrlst = List.map1(crlst,Util.makeTuple,cr);
//         ht1 = List.fold(crcrlst,BaseHashTable.add,ht);
//         BackendDump.debugStrCrefStrCrefStr(("replac der Alias State ",acr," -> ",cr,"\n"));
//       then
//        BackendDAE.STATEORDER(ht1,dht);
//     case (_,_,BackendDAE.STATEORDER(invHashTable=dht))
//       equation
//         failure(_ = BaseHashTable.get(acr,dht));
//       then
//        inStateOrder;
//   end matchcontinue;
// end replaceDerStateOrder;

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
  input BackendDAE.ConstraintEquations inOrgEqns;
  input Integer e;
  input BackendDAE.Equation inEqn;
  output BackendDAE.ConstraintEquations outOrgEqns;
algorithm
  outOrgEqns :=
  matchcontinue (inOrgEqns,e,inEqn)
    local
      list<BackendDAE.Equation> orgeqns;
      Integer e1;
      BackendDAE.ConstraintEquations rest,orgeqnslst;

    case ({},_,_) then {(e,{inEqn})};
    case ((e1,orgeqns)::rest,_,_)
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
end addOrgEqn;

protected function dumpStateOrder
"author: Frenkel TUD 2011-05
  Prints the state order"
  input BackendDAE.StateOrder inStateOrder;
algorithm
  _:=
  match (inStateOrder)
    local
      String str,len_str;
      Integer len;
      HashTableCG.HashTable ht;
      HashTable3.HashTable dht;
      list<tuple<DAE.ComponentRef,DAE.ComponentRef>> tplLst;
    case (BackendDAE.STATEORDER(ht,dht))
      equation
        print("State Order: (");
        (tplLst) = BaseHashTable.hashTableList(ht);
        str = stringDelimitList(List.map(tplLst,printStateOrderStr),"\n");
        len = listLength(tplLst);
        len_str = intString(len);
        print(len_str);
        print(")\n");
        print("=============\n");
        print(str);
        print("\n");
      then
        ();
  end match;
end dumpStateOrder;

protected function printStateOrderStr "help function to dumpStateOrder"
  input tuple<DAE.ComponentRef,DAE.ComponentRef> tpl;
  output String str;
algorithm
  str := ComponentReference.printComponentRefStr(Util.tuple21(tpl)) +& " -> " +& ComponentReference.printComponentRefStr(Util.tuple22(tpl));
end printStateOrderStr;

end IndexReduction;
